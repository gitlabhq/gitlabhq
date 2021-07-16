---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# User lookup via OpenSSH's AuthorizedPrincipalsCommand **(FREE SELF)**

> [Available in](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/19911) GitLab
> Community Edition 11.2.

The default SSH authentication for GitLab requires users to upload their SSH
public keys before they can use the SSH transport.

In centralized (for example, corporate) environments this can be a hassle
operationally, particularly if the SSH keys are temporary keys issued to the
user, including ones that expire 24 hours after issuing.

In such setups some external automated process is needed to constantly
upload the new keys to GitLab.

WARNING:
OpenSSH version 6.9+ is required because that version
introduced the `AuthorizedPrincipalsCommand` configuration option. If
using CentOS 6, you can [follow these
instructions](fast_ssh_key_lookup.html#compiling-a-custom-version-of-openssh-for-centos-6)
to compile an up-to-date version.

## Why use OpenSSH certificates?

By using OpenSSH certificates all the information about what user on
GitLab owns the key is encoded in the key itself, and OpenSSH itself
guarantees that users can't fake this, since they'd need to have
access to the private CA signing key.

When correctly set up, this does away with the requirement of
uploading user SSH keys to GitLab entirely.

## Setting up SSH certificate lookup via GitLab Shell

How to fully set up SSH certificates is outside the scope of this
document. See [OpenSSH's
`PROTOCOL.certkeys`](https://cvsweb.openbsd.org/cgi-bin/cvsweb/src/usr.bin/ssh/PROTOCOL.certkeys?annotate=HEAD)
for how it works, for example [RedHat's documentation about
it](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-using_openssh_certificate_authentication).

We assume that you already have SSH certificates set up, and have
added the `TrustedUserCAKeys` of your CA to your `sshd_config`, for example:

```plaintext
TrustedUserCAKeys /etc/security/mycompany_user_ca.pub
```

Usually `TrustedUserCAKeys` would not be scoped under a `Match User
git` in such a setup, since it would also be used for system logins to
the GitLab server itself, but your setup may vary. If the CA is only
used for GitLab consider putting this in the `Match User git` section
(described below).

The SSH certificates being issued by that CA **MUST** have a "key ID"
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
`prod-aearnfjord` if it's a SSH certificate you'd normally log in to
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

This command will emit output that looks something like:

```shell
command="/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell username-{KEY_ID}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty {PRINCIPAL}
```

Where `{KEY_ID}` is the `%i` argument passed to the script
(for example, `aeanfjord`), and `{PRINCIPAL}` is the principal passed to it
(for example, `sshUsers`).

You need to customize the `sshUsers` part of that. It should be
some principal that's guaranteed to be part of the key for all users
who can log in to GitLab, or you must provide a list of principals,
one of which is present for the user, for example:

```plaintext
    [...]
    AuthorizedPrincipalsCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-principals-check %i sshUsers windowsUsers
```

## Principals and security

You can supply as many principals as you want, these are turned
into multiple lines of `authorized_keys` output, as described in the
`AuthorizedPrincipalsFile` documentation in `sshd_config(5)`.

Normally when using the `AuthorizedKeysCommand` with OpenSSH the
principal is some "group" that's allowed to log into that
server. However with GitLab it's only used to appease OpenSSH's
requirement for it, we effectively only care about the "key ID" being
correct. Once that's extracted GitLab enforces its own ACLs for
that user (for example, what projects the user can access).

So it's OK to e.g. be overly generous in what you accept, since if the
user e.g. has no access to GitLab at all it just errors out with a
message about this being an invalid user.

## Interaction with the `authorized_keys` file

SSH certificates can be used in conjunction with the `authorized_keys`
file, and if set up as configured above the `authorized_keys` file
still serves as a fallback.

This is because if the `AuthorizedPrincipalsCommand` can't
authenticate the user, OpenSSH falls back on
`~/.ssh/authorized_keys` (or the `AuthorizedKeysCommand`).

Therefore there may still be a reason to use the ["Fast lookup of
authorized SSH keys in the database"](fast_ssh_key_lookup.html) method
in conjunction with this. Since you are using SSH certificates for
all your normal users, and relying on the `~/.ssh/authorized_keys`
fallback for deploy keys, if you make use of those.

But you may find that there's no reason to do that, since all your
normal users use the fast `AuthorizedPrincipalsCommand` path, and
only automated deployment key access falls back on
`~/.ssh/authorized_keys`, or that you have a lot more keys for normal
users (especially if they're renewed) than you have deploy keys.

## Other security caveats

Users can still bypass SSH certificate authentication by manually
uploading an SSH public key to their profile, relying on the
`~/.ssh/authorized_keys` fallback to authenticate it. There's
currently no feature to prevent this, [but there's an open request for
adding it](https://gitlab.com/gitlab-org/gitlab/-/issues/23260).

Such a restriction can currently be hacked in by, for example, providing a
custom `AuthorizedKeysCommand` which checks if the discovered key-ID
returned from `gitlab-shell-authorized-keys-check` is a deploy key or
not (all non-deploy keys should be refused).

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
