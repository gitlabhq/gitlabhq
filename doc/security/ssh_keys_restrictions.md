---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Configure SSH key restrictions
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

`ssh-keygen` allows users to create RSA keys with as few as 768 bits, which
falls well below recommended key sizes from standards groups such as the US
NIST, and is not secure. Some organizations deploying GitLab need to enforce minimum key
strength, either to satisfy internal security policy or for regulatory
compliance.

Similarly, GitLab strongly recommends using ED25519, ED25519_SK, ECDSA,
ECDSA_SK, or RSA over the older DSA. Administrators should strongly consider
limiting the allowed SSH key algorithms to maintain security.

GitLab allows you to restrict the allowed SSH key technology as well as specify
the minimum key length for each technology.

Prerequisites:

- Administrator access.

To configure SSH key restrictions:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **General** .
1. Expand **Visibility and access controls** and set your desired values for each key type:
   - **RSA SSH keys**.
   - **DSA SSH keys**.
   - **ECDSA SSH keys**.
   - **ED25519 SSH keys**.
   - **ECDSA_SK SSH keys**.
   - **ED25519_SK SSH keys**.
1. Select **Save changes**.

If a restriction is imposed on any key type, users cannot upload new SSH keys that don't meet the
requirement. Any existing keys that don't meet it are disabled but not removed and users cannot
pull or push code using them.

If you have a restricted key, a warning icon ({{< icon name="warning" >}}) is visible to you in the **SSH keys** section of your profile.
To learn why that key is restricted, hover over the icon.

## Default settings

By default, the GitLab.com and GitLab Self-Managed settings for the
[supported key types](../user/ssh.md#supported-ssh-key-types) are:

- DSA SSH keys are forbidden.
- RSA SSH keys are allowed.
- ECDSA SSH keys are allowed.
- ED25519 SSH keys are allowed.
- ECDSA_SK SSH keys are allowed.
- ED25519_SK SSH keys are allowed.

## Override SSH settings on the GitLab server

GitLab integrates with the system-installed SSH daemon and designates a user
(typically named `git`) through which all access requests are handled. Users
who connect to the GitLab server over SSH are identified by their SSH key instead
of their username.

SSH client operations performed on the GitLab server are executed as this
user. You can modify this SSH configuration. For example, you can specify
a private SSH key for this user to use for authentication requests. However, this practice
is not supported and is strongly discouraged as it presents significant
security risks.

GitLab checks for this condition, and directs you
to this section if your server is configured this way. For example:

```shell
$ gitlab-rake gitlab:check

Git user has default SSH configuration? ... no
  Try fixing it:
  mkdir ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa.pub ~/gitlab-check-backup-1504540051
  For more information see:
  doc/user/ssh.md#overriding-ssh-settings-on-the-gitlab-server
  Please fix the error above and rerun the checks.
```

> [!warning]
> Remove the custom configuration as soon as you can. These customizations
> are explicitly not supported and may stop working at any time.

## Verify GitLab SSH ownership and permissions

The GitLab SSH folder and files must have the following permissions:

- The folder `/var/opt/gitlab/.ssh/` must be owned by the `git` group and the `git` user, with permissions set to `700`.
- The `authorized_keys` file must have permissions set to `600`.
- The `authorized_keys.lock` file must have permissions set to `644`.

To verify that these permissions are correct, run the following:

```shell
stat -c "%a %n" /var/opt/gitlab/.ssh/.
```

### Set permissions

If the permissions are wrong, sign in to the application server and run:

```shell
cd /var/opt/gitlab/
chown git:git /var/opt/gitlab/.ssh/
chmod 700  /var/opt/gitlab/.ssh/
chmod 600  /var/opt/gitlab/.ssh/authorized_keys
chmod 644  /var/opt/gitlab/.ssh/authorized_keys.lock
```
