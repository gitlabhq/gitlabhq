---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure a faster SSH authorization method for GitLab instances with many users."
title: Fast lookup of SSH keys
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

NOTE:
For standard (non-deploy key) users, you can also use [SSH certificates](ssh_certificates.md).
They are faster than database lookups but are not a drop-in replacement for the `authorized_keys` file.

When the number of users grows, SSH operations become slow because OpenSSH performs a
linear search through the `authorized_keys` file to authenticate users.
This process requires significant time and disk I/O, which delays users attempting to
push or pull to a repository.
If users add or remove keys frequently, the operating system may not cache the
`authorized_keys` file, which causes repeated disk reads.

Instead of using the `authorized_keys` file, you can configure GitLab Shell to look up
SSH keys. It is faster because the lookup is indexed in the GitLab database.

## Fast lookup is required for Geo

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Unlike [Cloud Native GitLab](https://docs.gitlab.com/charts/), by default Linux package installations
manage an `authorized_keys` file that is located in the
`git` user's home directory. For most installations, this file is located under
`/var/opt/gitlab/.ssh/authorized_keys`, but you can use the following command to
locate the `authorized_keys` on your system:

```shell
getent passwd git | cut -d: -f6 | awk '{print $1"/.ssh/authorized_keys"}'
```

The `authorized_keys` file contains all the public SSH keys for users allowed to access GitLab. However, to maintain a
single source of truth, [Geo](../geo/_index.md) must be configured to perform SSH fingerprint
lookups with database lookup.

When you [set up Geo](../geo/setup/_index.md), you must follow the steps below
for both the primary and secondary nodes. Do not select **Write to `authorized keys` file** on the
primary node, because it is reflected automatically on the secondary if database replication is working.

## Set up fast lookup

GitLab Shell provides a way to authorize SSH users with a fast, indexed lookup
to the GitLab database. GitLab Shell uses the fingerprint of the SSH key to
check whether the user is authorized to access GitLab.

Fast lookup can be enabled with the following SSH servers:

- [`gitlab-sshd`](gitlab_sshd.md)
- OpenSSH

You can run both services simultaneously by using separate ports for each service.

### With `gitlab-sshd`

To set up `gitlab-sshd`, see [the `gitlab-sshd` documentation](gitlab_sshd.md).
After `gitlab-sshd` is enabled, GitLab Shell and `gitlab-sshd` are configured
to use fast lookup automatically.

### With OpenSSH

Prerequisites:

- OpenSSH 6.9 or later is required because `AuthorizedKeysCommand` must
  accept a fingerprint. To check your version, run `sshd -V`.

To set up fast lookup with OpenSSH:

1. Add the following to your `sshd_config` file:

   ```plaintext
   Match User git    # Apply the AuthorizedKeysCommands to the git user only
     AuthorizedKeysCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check git %u %k
     AuthorizedKeysCommandUser git
   Match all    # End match, settings apply to all users again
   ```

   This file is usually located in:

   - Linux package installations: `/etc/ssh/sshd_config`
   - Docker installations: `/assets/sshd_config`
   - Self-compiled installations: If you followed the instructions for
   [installing GitLab Shell from source](../../install/installation.md#install-gitlab-shell), the command should be
   located at `/home/git/gitlab-shell/bin/gitlab-shell-authorized-keys-check`.
   Consider creating a wrapper script somewhere else, as this command must be owned by `root`,
   and not be writable by a group or others.
   Also consider changing the ownership of this command as needed, but this might require temporary
   ownership changes during `gitlab-shell` upgrades.

1. Reload OpenSSH:

   ```shell
   # Debian or Ubuntu installations
   sudo service ssh reload

   # CentOS installations
   sudo service sshd reload
   ```

1. Confirm that SSH is working:

   1. Comment out your user's key in the `authorized_keys` file. To do this, start the line with `#`.
   1. From your local machine, attempt to pull a repository or run:

      ```shell
      ssh -T git@gitlab.example.com
      ```

      A successful pull or [welcome message](../../user/ssh.md#verify-that-you-can-connect)
      means that GitLab found the key in the database, as the key is not present in the file.

If there are lookup failures, the `authorized_keys` file is still scanned.
Git SSH performance might still be slow for many users, as long as the large file exists.

To resolve this, you can disable writes to the `authorized_keys` file:

1. Confirm SSH works. This step is important because otherwise the file quickly becomes out-of-date.
1. Disable writes to the `authorized_keys` file:

   1. On the left sidebar, at the bottom, select **Admin**.
   1. Select **Settings > Network**.
   1. Expand **Performance optimization**.
   1. Clear the **Use `authorized_keys` file to authenticate SSH keys** checkbox.
   1. Select **Save changes**.

1. Verify the change:

   1. Remove your SSH key in the UI.
   1. Add a new key.
   1. Try to pull a repository.

1. Back up and delete your `authorized_keys` file.
The current users' keys are already present in the database, so there is no need for migration
or for users to re-add their keys.

### How to go back to using the `authorized_keys` file

This overview is brief. Refer to the above instructions for more context.

1. [Rebuild the `authorized_keys` file](../raketasks/maintenance.md#rebuild-authorized_keys-file).
1. Enable writes to the `authorized_keys` file.
   1. On the left sidebar, at the bottom, select **Admin**.
   1. On the left sidebar, select **Settings > Network**.
   1. Expand **Performance optimization**.
   1. Select the **Use `authorized_keys` file to authenticate SSH keys** checkbox.
1. Remove the `AuthorizedKeysCommand` lines from `/etc/ssh/sshd_config` or from `/assets/sshd_config` if you are using Docker
   from a Linux package installation.
1. Reload `sshd`: `sudo service sshd reload`.

## SELinux support

GitLab supports `authorized_keys` database lookups with [SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux).

Because the SELinux policy is static, GitLab doesn't support changing
internal web server ports. Administrators would have to create a special `.te`
file for the environment, as it isn't generated dynamically.

### Additional documentation

Additional technical documentation for `gitlab-sshd` may be found in the
[GitLab Shell documentation](../../development/gitlab_shell/_index.md).

## Troubleshooting

### SSH traffic slow or high CPU load

If your SSH traffic is [slow](https://github.com/linux-pam/linux-pam/issues/270)
or causing high CPU load:

- Check the size of `/var/log/btmp`.
- Ensure it is rotated on a regular basis, or after reaching a certain size.

If this file is very large, GitLab SSH fast lookup can cause the bottleneck to be hit more frequently,
thus decreasing performance even further. Consider disabling
[`UsePAM` in your `sshd_config`](https://linux.die.net/man/5/sshd_config) to avoid reading `/var/log/btmp` altogether.

Running `strace` and `lsof` on a running `sshd: git` process returns debugging information.
To get an `strace` on an in-progress Git over SSH connection for IP `x.x.x.x`, run:

```plaintext
sudo strace -s 10000 -p $(sudo netstat -tp | grep x.x.x.x | egrep 'ssh.*: git' | sed -e 's/.*ESTABLISHED *//' -e 's#/.*##')
```

Or get an `lsof` for a running Git over SSH process:

```plaintext
sudo lsof -p $(sudo netstat -tp | egrep 'ssh.*: git' | head -1 | sed -e 's/.*ESTABLISHED *//' -e 's#/.*##')
```
