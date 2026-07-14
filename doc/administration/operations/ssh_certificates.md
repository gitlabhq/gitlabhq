---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: User lookup with the OpenSSH AuthorizedPrincipalsCommand
description: Configure authorized principals for SSH certificate authentication.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The default SSH authentication for GitLab Self-Managed instances requires users to upload their SSH
public keys before they can use the SSH transport.

In centralized environments, such as corporate environments, this requirement can create
operational overhead. This is particularly true when SSH keys are temporary, such as keys
that expire 24 hours after they are issued.

In these setups, an external automated process must constantly upload new keys to GitLab.

> [!warning]
> OpenSSH version 6.9+ is required because `AuthorizedKeysCommand` must be
> able to accept a fingerprint. Check the version of OpenSSH on your server.

If you use `gitlab-sshd` instead of OpenSSH, you can configure instance-level SSH
certificate authentication directly in the `gitlab-sshd` configuration file without
requiring OpenSSH. For more information, see
[Instance-level SSH certificates with `gitlab-sshd`](gitlab_sshd_ssh_certificates.md).

If you are a GitLab.com group owner, you should instead use a group-scoped SSH certificate feature that uses the GitLab SSH server instead and doesn't require OpenSSH
configuration. For more information, see [manage group SSH certificates](../../user/group/ssh_certificates.md).

## Why use OpenSSH certificates?

With OpenSSH certificates, the information about which GitLab user owns the key is encoded in the key itself.
Users cannot fake this information because they need access to the private CA signing key.

When set up correctly, OpenSSH certificates remove the requirement to upload user SSH keys to GitLab.

## Set up SSH certificate lookup with GitLab Shell

A full SSH certificate setup is outside the scope of this page.
For how SSH certificates work, see the OpenSSH
[`PROTOCOL.certkeys` specification](https://cvsweb.openbsd.org/cgi-bin/cvsweb/src/usr.bin/ssh/PROTOCOL.certkeys?annotate=HEAD)
and the
[Red Hat documentation on OpenSSH certificate authentication](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-using_openssh_certificate_authentication).

Before you begin, ensure you have already set up SSH certificates and added the `TrustedUserCAKeys` of your CA
to your `sshd_config`, for example:

```plaintext
TrustedUserCAKeys /etc/security/mycompany_user_ca.pub
```

Usually `TrustedUserCAKeys` would not be scoped under a `Match User git`
in such a setup because it would also be used for system logins to
the GitLab server itself, but your setup may vary. If the CA is only
used for GitLab consider putting this in the `Match User git` section
(described below).

Each SSH certificate issued by that CA must have a "key ID" that corresponds to the user's GitLab
username.
The `AuthorizedPrincipalsCommand` maps this key ID to a GitLab username, so that GitLab extracts the
username from the certificate instead of relying on a public key to username mapping.
The default command shipped with GitLab assumes a 1:1 mapping between the key ID and the GitLab username.

The following example shows a certificate with the key ID `aearnfjord` (some output omitted for brevity):

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

Key IDs do not have to match GitLab usernames directly.
For example, a user who signs in to servers as `prod-aearnfjord` might have a `prod-aearnfjord` key ID.
In that case, you must supply your own `AuthorizedPrincipalsCommand` to perform the mapping instead of
using the default.

Next, set up `AuthorizedPrincipalsCommand` for the `git` user in your `sshd_config`.
In most cases, you can use the default command shipped with GitLab:

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

You can supply as many principals as you want.
Each principal becomes a separate line of `authorized_keys` output, as described for
`AuthorizedPrincipalsFile` in `sshd_config(5)`.

With OpenSSH, the principal in an `AuthorizedKeysCommand` is typically a "group" that's allowed to sign
in to a server.
GitLab uses the principal only to satisfy this OpenSSH requirement, and what matters is that the key ID
is correct.
After GitLab extracts the key ID, it enforces its own access controls for the user, such as which
projects the user can access.

You can be generous in the principals you accept.
For example, if a user has no access to GitLab, authentication fails with an invalid user error.

## Interaction with the `authorized_keys` file

SSH certificates work alongside the `authorized_keys` file, which acts as a fallback.
When the `AuthorizedPrincipalsCommand` cannot authenticate a user, OpenSSH falls back to the
`~/.ssh/authorized_keys` file or the `AuthorizedKeysCommand`.
For this reason, you might still need
[fast lookup of authorized SSH keys in the database](fast_ssh_key_lookup.md) with SSH certificates.

For most users, the `AuthorizedPrincipalsCommand` handles authentication, and the `authorized_keys`
file serves only specific cases such as deploy keys.
Depending on your setup, the `AuthorizedPrincipalsCommand` alone might be sufficient for typical users,
which leaves the `authorized_keys` file for automated deploy key access.

To decide whether to maintain the `authorized_keys` fallback, weigh the number of keys for typical
users, especially frequently renewed keys, against the number of deploy keys.

## Other security caveats

Users can still bypass SSH certificate authentication by manually uploading an SSH public key to their
profile and relying on the `~/.ssh/authorized_keys` fallback.
A setting to prevent users from uploading SSH keys that are not deploy keys is proposed in
[issue 23260](https://gitlab.com/gitlab-org/gitlab/-/issues/23260).

To enforce this restriction yourself, provide a custom `AuthorizedKeysCommand`.
The command checks whether the key ID returned from `gitlab-shell-authorized-keys-check` is a deploy key,
and refuses all non-deploy keys.

## Disable the global warning about users lacking SSH keys

By default, GitLab shows a "You won't be able to pull or push repositories via SSH until you add an SSH key to your profile" warning to users who
have not uploaded an SSH key to their profile.
This warning is counterproductive with SSH certificates because users are not expected to upload their
own keys.

To disable this warning globally:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. In the **Account and limit** section, clear the **Inform users without uploaded SSH keys that they can't push over SSH until one is added** checkbox.

This setting was added specifically for use with SSH certificates.
You can also turn it off without SSH certificates, to hide the warning for other reasons.
