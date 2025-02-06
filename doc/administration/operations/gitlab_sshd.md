---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure `gitlab-sshd`, a lightweight alternative to OpenSSH, for your GitLab instance."
title: '`gitlab-sshd`'
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - Ready for production use with [Cloud Native GitLab in GitLab 15.1](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2540) and [Linux packages in GitLab 15.9](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5937).

`gitlab-sshd` is [a standalone SSH server](https://gitlab.com/gitlab-org/gitlab-shell/-/tree/main/internal/sshd)
written in Go. It is provided as a part of the `gitlab-shell` package. It has a lower memory
use as a OpenSSH alternative, and supports
[group access restriction by IP address](../../user/group/access_and_permissions.md#restrict-group-access-by-ip-address) for applications
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
- `gitlab-sshd` does not support SSH certificates. For discussion about adding them,
  see [issue 655](https://gitlab.com/gitlab-org/gitlab-shell/-/issues/655).
- `gitlab-sshd` does not support 2FA recovery code regeneration. Attempting to run `2fa_recovery_codes`
  results in the following error: `remote: ERROR: Unknown command: 2fa_recovery_codes`.
  See [the discussion](https://gitlab.com/gitlab-org/gitlab-shell/-/issues/766#note_1906707753) for more information.

## Enable `gitlab-sshd`

To use `gitlab-sshd`:

::Tabs

:::TabTitle Linux package (Omnibus)

The following instructions enable `gitlab-sshd` on a different port than OpenSSH:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_sshd['enable'] = true
   gitlab_sshd['listen_address'] = '[::]:2222' # Adjust the port accordingly
   ```

1. Optional. By default, Linux package installations generate SSH host keys for `gitlab-sshd` if
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

## PROXY protocol support

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
   # Proxy protocol policy ("use", "require", "reject", "ignore"), "use" is the default value
   gitlab_sshd['proxy_policy'] = "use"
   ```

   For more information about the `gitlab_sshd['proxy_policy']` options, see the
   [`go-proxyproto` library](https://github.com/pires/go-proxyproto/blob/4ba2eb817d7a57a4aafdbd3b82ef0410806b533d/policy.go#L20-L35).

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
