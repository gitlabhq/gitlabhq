---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User lookup via OpenSSH's AuthorizedPrincipalsCommand
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The default SSH authentication for GitLab requires users to upload their SSH
public keys before they can use the SSH transport.

In centralized (for example, corporate) environments this can be a hassle
operationally, particularly if the SSH keys are temporary keys issued to the
user, including ones that expire 24 hours after issuing.

In such setups some external automated process is needed to constantly
upload the new keys to GitLab.

WARNING:
OpenSSH version 6.9+ is required because `AuthorizedKeysCommand` must be
able to accept a fingerprint. Check the version of OpenSSH on your server.

## Why use OpenSSH certificates?

By using OpenSSH certificates all the information about what user on
GitLab owns the key is encoded in the key itself, and OpenSSH itself
guarantees that users can't fake this, since they'd need to have
access to the private CA signing key.

When correctly set up, this does away with the requirement of
uploading user SSH keys to GitLab entirely.

## Setting up SSH certificate lookup via GitLab Shell

How to fully set up SSH certificates is outside the scope of this
document. See
[OpenSSH's`PROTOCOL.certkeys`](https://cvsweb.openbsd.org/cgi-bin/cvsweb/src/usr.bin/ssh/PROTOCOL.certkeys?annotate=HEAD)
for how it works, for example
[RedHat's documentation about it](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-using_openssh_certificate_authentication).

We assume that you already have SSH certificates set up, and have
added the `TrustedUserCAKeys` of your CA to your `sshd_config`, for example:

```plaintext
TrustedUserCAKeys /etc/security/mycompany_user_ca.pub
```

Usually `TrustedUserCAKeys` would not be scoped under a `Match User git`
in such a setup, since it would also be used for system logins to
the GitLab server itself, but your setup may vary. If the CA is only
used for GitLab consider putting this in the `Match User git` section
(described below).

The SSH certificates being issued by that CA **must** have a "key ID"
corresponding to that user's username on GitLab, for example (some output
omitted for brevity):

```shell
$ ssh-add -L | grep cert | ssh-keygen -L -f -

(stdin):1:
        Type: ssh-rsa-cert-v01@openssh.com user certificate
        Public key: RSA-CERT SHA256:[...]
        Signing CA: RSA SHA256:[...]
        Key ID: "aearnfjord"
        Serial: 8289829611021396489
        Valid: from 2018-07-18T09:49:00 to 2018-07-19T09:50:34
        Principals:
                sshUsers
                [...]
        [...]
```

Technically that's not strictly true, for example, it could be
`prod-aearnfjord` if it's a SSH certificate you'd usually sign in to
servers as the `prod-aearnfjord` user, but then you must specify your
own `AuthorizedPrincipalsCommand` to do that mapping instead of using
our provided default.

The important part is that the `AuthorizedPrincipalsCommand` must be
able to map from the "key ID" to a GitLab username in some way, the
default command we ship assumes there's a 1=1 mapping between the two,
since the whole point of this is to allow us to extract a GitLab
username from the key itself, instead of relying on something like the
default public key to username mapping.

Then, in your `sshd_config` set up `AuthorizedPrincipalsCommand` for
the `git` user. Hopefully you can use the default one shipped with
GitLab:

```plaintext
Match User git
    AuthorizedPrincipalsCommandUser root
    AuthorizedPrincipalsCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-principals-check %i sshUsers
```

This command emits output that looks something like:

```shell
command="/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell username-{KEY_ID}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty {PRINCIPAL}
```

Where `{KEY_ID}` is the `%i` argument passed to the script
(for example, `aeanfjord`), and `{PRINCIPAL}` is the principal passed to it
(for example, `sshUsers`).

You need to customize the `sshUsers` part of that. It should be
some principal that's guaranteed to be part of the key for all users
who can sign in to GitLab, or you must provide a list of principals,
one of which is present for the user, for example:

```plaintext
    [...]
    AuthorizedPrincipalsCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-principals-check %i sshUsers windowsUsers
```

## Principals and security

You can supply as many principals as you want, these are turned
into multiple lines of `authorized_keys` output, as described in the
`AuthorizedPrincipalsFile` documentation in `sshd_config(5)`.

Usually when using the `AuthorizedKeysCommand` with OpenSSH the
principal is some "group" that's allowed to sign in to that
server. However with GitLab it's only used to appease OpenSSH's
requirement for it, we effectively only care about the "key ID" being
correct. Once that's extracted GitLab enforces its own ACLs for
that user (for example, what projects the user can access).

It's therefore fine to be overly generous in what you accept. For example, if the user has no access
to GitLab, an error is produced with a message about an invalid user.
message about this being an invalid user.

## Interaction with the `authorized_keys` file

If SSH certificates are set up as described above, they can be used with the `authorized_keys` file so that the `authorized_keys` file serves as a fallback.

When the `AuthorizedPrincipalsCommand` is unable to authenticate a user, OpenSSH reverts to checking the `~/.ssh/authorized_keys` file or using the `AuthorizedKeysCommand`.
Therefore, you might still need to use [Fast lookup of authorized SSH keys in the database](fast_ssh_key_lookup.md) with SSH certificates.

For most users, SSH certificates handle authentication by using the `AuthorizedPrincipalsCommand`, with the `~/.ssh/authorized_keys` file primarily serving as a fallback for
specific cases such as deploy keys. However, depending on your setup, you might find that using the `AuthorizedPrincipalsCommand` exclusively for typical users is sufficient.
In such cases, the `authorized_keys` file is only necessary for automated deployment key access or other specific scenarios.

Consider the balance between the number of keys for typical users (especially if they are frequently renewed) and deploy keys to help you determine whether maintaining the
`authorized_keys` fallback is necessary for your environment.

## Other security caveats

Users can still bypass SSH certificate authentication by manually
uploading an SSH public key to their profile, relying on the
`~/.ssh/authorized_keys` fallback to authenticate it.

There's an [open issue](https://gitlab.com/gitlab-org/gitlab/-/issues/23260)
to add a setting that prevents users from uploading SSH keys that are not deploy keys.

You can build a check to enforce this restriction yourself.
For example, provide a custom `AuthorizedKeysCommand` which checks
if the discovered key-ID returned from `gitlab-shell-authorized-keys-check`
is a deploy key or not (all non-deploy keys should be refused).

## Disabling the global warning about users lacking SSH keys

By default GitLab shows a "You won't be able to pull or push
project code via SSH" warning to users who have not uploaded an SSH
key to their profile.

This is counterproductive when using SSH certificates, since users
aren't expected to upload their own keys.

To disable this warning globally, go to "Application settings ->
Account and limit settings" and disable the "Show user add SSH key
message" setting.

This setting was added specifically for use with SSH certificates, but
can be turned off without using them if you'd like to hide the warning
for some other reason.
