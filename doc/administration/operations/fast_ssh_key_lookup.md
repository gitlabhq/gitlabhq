---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Fast lookup of authorized SSH keys in the database **(FREE SELF)**

NOTE:
This document describes a drop-in replacement for the
`authorized_keys` file. For standard (non-deploy key) users, consider using
[SSH certificates](ssh_certificates.md). They are even faster, but are not a
drop-in replacement.

Regular SSH operations become slow as the number of users grows because OpenSSH
searches for a key to authorize a user via a linear search. In the worst case,
such as when the user is not authorized to access GitLab, OpenSSH scans the
entire file to search for a key. This can take significant time and disk I/O,
which delays users attempting to push or pull to a repository. Making
matters worse, if users add or remove keys frequently, the operating system may
not be able to cache the `authorized_keys` file, which causes the disk to be
accessed repeatedly.

GitLab Shell solves this by providing a way to authorize SSH users via a fast,
indexed lookup in the GitLab database. This page describes how to enable the fast
lookup of authorized SSH keys.

WARNING:
OpenSSH version 6.9+ is required because `AuthorizedKeysCommand` must be
able to accept a fingerprint. Check the version of OpenSSH on your server with `sshd -V`.

## Fast lookup is required for Geo **(PREMIUM)**

Unlike [Cloud Native GitLab](https://docs.gitlab.com/charts/), Omnibus GitLab by default
manages an `authorized_keys` file that is located in the
`git` user's home directory. For most installations, this file is located under
`/var/opt/gitlab/.ssh/authorized_keys`, but you can use the following command to
locate the `authorized_keys` on your system:

```shell
getent passwd git | cut -d: -f6 | awk '{print $1"/.ssh/authorized_keys"}'
```

The `authorized_keys` file contains all the public SSH keys for users allowed to access GitLab. However, to maintain a
single source of truth, [Geo](../geo/index.md) must be configured to perform SSH fingerprint
lookups via database lookup.

As part of [setting up Geo](../geo/index.md#setup-instructions),
you are required to follow the steps outlined below for both the primary and
secondary nodes, but **Write to "authorized keys" file**
must be unchecked only on the primary node, because it is reflected
automatically on the secondary if database replication is working.

## Setting up fast lookup via GitLab Shell

GitLab Shell provides a way to authorize SSH users via a fast, indexed lookup
to the GitLab database. GitLab Shell uses the fingerprint of the SSH key to
check whether the user is authorized to access GitLab.

Add the following to your `sshd_config` file. This file is usually located at
`/etc/ssh/sshd_config`, but it is at `/assets/sshd_config` if you're using
Omnibus Docker:

```plaintext
Match User git    # Apply the AuthorizedKeysCommands to the git user only
  AuthorizedKeysCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check git %u %k
  AuthorizedKeysCommandUser git
Match all    # End match, settings apply to all users again
```

Reload OpenSSH:

```shell
# Debian or Ubuntu installations
sudo service ssh reload

# CentOS installations
sudo service sshd reload
```

Confirm that SSH is working by commenting out your user's key in the `authorized_keys`
file (start the line with a `#` to comment it), and from your local machine, attempt to pull a repository or run:

```shell
ssh -T git@gitlab.example.com
```

A successful pull or [welcome message](../../user/ssh.md#verify-that-you-can-connect)
means that GitLab was able to find the key in the database,
as it is not present in the file.

NOTE:
For Installations from source, the command would be located at
`/home/git/gitlab-shell/bin/gitlab-shell-authorized-keys-check` if [the install from source](../../install/installation.md#install-gitlab-shell) instructions were followed.
You might want to consider creating a wrapper script somewhere else, as this command must be
owned by `root` and not be writable by group or others. You could also consider changing the ownership of this command
as required, but that might require temporary ownership changes during `gitlab-shell` upgrades.

WARNING:
Do not disable writes until SSH is confirmed to be working
perfectly; otherwise, the file quickly becomes out-of-date.

In the case of lookup failures (which are common), the `authorized_keys`
file is still scanned. So Git SSH performance would still be slow for many
users as long as a large file exists.

To disable writes to the `authorized_keys` file:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Network**.
1. Expand **Performance optimization**.
1. Clear the **Use authorized_keys file to authenticate SSH keys** checkbox.
1. Select **Save changes**.

Again, confirm that SSH is working by removing your user's SSH key in the UI,
adding a new one, and attempting to pull a repository.

Then you can backup and delete your `authorized_keys` file for best performance.
The current users' keys are already present in the database, so there is no need for migration
or for users to re-add their keys.

## How to go back to using the `authorized_keys` file

This overview is brief. Refer to the above instructions for more context.

1. [Rebuild the `authorized_keys` file](../raketasks/maintenance.md#rebuild-authorized_keys-file).
1. Enable writes to the `authorized_keys` file.
   1. On the top bar, select **Main menu > Admin**.
   1. On the left sidebar, select **Settings > Network**.
   1. Expand **Performance optimization**.
   1. Select the **Use authorized_keys file to authenticate SSH keys** checkbox.
1. Remove the `AuthorizedKeysCommand` lines from `/etc/ssh/sshd_config` or from `/assets/sshd_config` if you are using Omnibus Docker.
1. Reload `sshd`: `sudo service sshd reload`.

## Use `gitlab-sshd` instead of OpenSSH

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299109) in GitLab 14.5 as an **Alpha** release for self-managed customers.
> - Ready for production use with [Cloud Native GitLab in GitLab 15.1](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2540) and [Omnibus GitLab in GitLab 15.9](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5937).

`gitlab-sshd` is [a standalone SSH server](https://gitlab.com/gitlab-org/gitlab-shell/-/tree/main/internal/sshd)
written in Go. It is provided as a part of the `gitlab-shell` package. It has a lower memory
use as a OpenSSH alternative, and supports
[group access restriction by IP address](../../user/group/index.md) for applications
running behind the proxy.

`gitlab-sshd` is a lightweight alternative to OpenSSH for providing
[SSH operations](https://gitlab.com/gitlab-org/gitlab-shell/-/blob/71a7f34a476f778e62f8fe7a453d632d395eaf8f/doc/features.md).
While OpenSSH uses a restricted shell approach, `gitlab-sshd` behaves more like a
modern multi-threaded server application, responding to incoming requests. The major
difference is that OpenSSH uses SSH as a transport protocol while `gitlab-sshd` uses Remote Procedure Calls (RPCs). See [the blog post](https://about.gitlab.com/blog/2022/08/17/why-we-have-implemented-our-own-sshd-solution-on-gitlab-sass/) for more details.

The capabilities of GitLab Shell are not limited to Git operations.

If you are considering switching from OpenSSH to `gitlab-sshd`, consider these concerns:

- `gitlab-sshd` supports the PROXY protocol. It can run behind proxy servers that rely
  on it, such as HAProxy. The PROXY protocol is not enabled by default, but [it can be enabled](#proxy-protocol-support).
- `gitlab-sshd` **does not** support SSH certificates. For more details, read
  [issue #495](https://gitlab.com/gitlab-org/gitlab-shell/-/issues/495).

To use `gitlab-sshd`:

::Tabs

:::TabTitle Linux package (Omnibus)

The following instructions enable `gitlab-sshd` on a different port than OpenSSH:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_sshd['enable'] = true
   gitlab_sshd['listen_address'] = '[::]:2222' # Adjust the port accordingly
   ```

1. Optional. By default, Omnibus GitLab generates SSH host keys for `gitlab-sshd` if
they do not exist in `/var/opt/gitlab/gitlab-sshd`. If you wish to disable this automatic generation, add this line:

   ```ruby
   gitlab_sshd['generate_host_keys'] = false
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

By default, `gitlab-sshd` runs as the `git` user. As a result, `gitlab-sshd` cannot
run on privileged port numbers lower than 1024. This means users must
access Git with the `gitlab-sshd` port, or use a load balancer that
directs SSH traffic to the `gitlab-sshd` port to hide this.

Users may see host key warnings because the newly-generated host keys
differ from the OpenSSH host keys. Consider disabling host key
generation and copy the existing OpenSSH host keys into
`/var/opt/gitlab/gitlab-sshd` if this is an issue.

:::TabTitle Helm chart (Kubernetes)

The following instructions switch OpenSSH in favor of `gitlab-sshd`:

1. Set the `gitlab-shell` charts `sshDaemon` option to
   [`gitlab-sshd`](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/index.html#installation-command-line-options).
   For example:

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
   ```

1. Perform a Helm upgrade.

By default, `gitlab-sshd` listens for:

- External requests on port 22 (`global.shell.port`).
- Internal requests on port 2222 (`gitlab.gitlab-shell.service.internalPort`).

You can [configure different ports in the Helm chart](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#configuration).

::EndTabs

### PROXY protocol support

When a load balancer is used in front of `gitlab-sshd`, GitLab reports the IP
address of the proxy instead of the actual IP address of the client. `gitlab-sshd`
supports the [PROXY protocol](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt) to
obtain the real IP address.

::Tabs

:::TabTitle Linux package (Omnibus)

To enable the PROXY protocol:

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    gitlab_sshd['proxy_protocol'] = true
    # # Proxy protocol policy ("use", "require", "reject", "ignore"), "use" is the default value
    gitlab_sshd['proxy_policy'] = "use"
    ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Set the [`gitlab.gitlab-shell.config` options](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/index.html#installation-command-line-options). For example:

   ```yaml
   gitlab:
     gitlab-shell:
       config:
         proxyProtocol: true
         proxyPolicy: "use"
   ```

1. Perform a Helm upgrade.

::EndTabs

## SELinux support and limitations

GitLab supports `authorized_keys` database lookups with [SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux).

Because the SELinux policy is static, GitLab doesn't support the ability to change
internal webserver ports at the moment. Administrators would have to create a special `.te`
file for the environment, as it isn't generated dynamically.

### Additional documentation

Additional technical documentation for `gitlab-sshd` may be found in the
[GitLab Shell documentation](../../development/gitlab_shell/index.md).

## Troubleshooting

If your SSH traffic is [slow](https://github.com/linux-pam/linux-pam/issues/270)
or causing high CPU load, be sure to check the size of `/var/log/btmp`, and ensure it is rotated on a regular basis or after reaching a certain size.
If this file is very large, GitLab SSH fast lookup can cause the bottleneck to be hit more frequently, thus decreasing performance even further.
If you are able to, you may consider disabling [`UsePAM` in your `sshd_config`](https://linux.die.net/man/5/sshd_config) to avoid reading `/var/log/btmp` altogether.

Running `strace` and `lsof` on a running `sshd: git` process returns debugging information.
To get an `strace` on an in-progress Git over SSH connection for IP `x.x.x.x`, run:

```plaintext
sudo strace -s 10000 -p $(sudo netstat -tp | grep x.x.x.x | egrep 'ssh.*: git' | sed -e 's/.*ESTABLISHED *//' -e 's#/.*##')
```

Or get an `lsof` for a running Git over SSH process:

```plaintext
sudo lsof -p $(sudo netstat -tp | egrep 'ssh.*: git' | head -1 | sed -e 's/.*ESTABLISHED *//' -e 's#/.*##')
```
