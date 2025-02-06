---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Set and configure Git protocol v2 for GitLab Self-Managed."
title: Configuring Git Protocol v2
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Git protocol v2 improves the v1 wire protocol in several ways and is
enabled by default in GitLab for HTTP requests. To enable SSH, additional
configuration is required by an administrator.

More details about the new features and improvements are available in
the [Google Open Source Blog](https://opensource.googleblog.com/2018/05/introducing-git-protocol-version-2.html)
and the [protocol documentation](https://github.com/git/git/blob/master/Documentation/gitprotocol-v2.txt).

## Prerequisites

From the client side, `git` `v2.18.0` or newer must be installed.

From the server side, if we want to configure SSH we need to set the `sshd`
server to accept the `GIT_PROTOCOL` environment.

In installations using [GitLab Helm Charts](https://docs.gitlab.com/charts/)
and [All-in-one Docker image](../install/docker/_index.md), the SSH
service is already configured to accept the `GIT_PROTOCOL` environment. Users
need not do anything more.

For installations from the Linux package or self-compiled installations, update
the SSH configuration of your server manually by adding this line to the `/etc/ssh/sshd_config` file:

```plaintext
AcceptEnv GIT_PROTOCOL
```

When you have configured the SSH daemon, restart it for the change to take effect:

```shell
# CentOS 6 / RHEL 6
sudo service sshd restart

# All other supported distributions
sudo systemctl restart ssh
```

## Instructions

To use the new protocol, clients need to either pass the configuration
`-c protocol.version=2` to the Git command, or set it globally:

```shell
git config --global protocol.version 2
```

### HTTP connections

Verify Git v2 is used by the client:

```shell
GIT_TRACE_CURL=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | grep Git-Protocol
```

You should see that the `Git-Protocol` header is sent:

```plaintext
16:29:44.577888 http.c:657              => Send header: Git-Protocol: version=2
```

Verify Git v2 is used by the server:

```shell
GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | head
```

Example response using Git protocol v2:

```shell
$ GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | head
10:42:50.574485 pkt-line.c:80           packet:          git< # service=git-upload-pack
10:42:50.574653 pkt-line.c:80           packet:          git< 0000
10:42:50.574673 pkt-line.c:80           packet:          git< version 2
10:42:50.574679 pkt-line.c:80           packet:          git< agent=git/2.18.1
10:42:50.574684 pkt-line.c:80           packet:          git< ls-refs
10:42:50.574688 pkt-line.c:80           packet:          git< fetch=shallow
10:42:50.574693 pkt-line.c:80           packet:          git< server-option
10:42:50.574697 pkt-line.c:80           packet:          git< 0000
10:42:50.574817 pkt-line.c:80           packet:          git< version 2
10:42:50.575308 pkt-line.c:80           packet:          git< agent=git/2.18.1
```

### SSH Connections

Verify Git v2 is used by the client:

```shell
GIT_SSH_COMMAND="ssh -v" git -c protocol.version=2 ls-remote ssh://git@your-gitlab-instance.com/group/repo.git 2>&1 | grep GIT_PROTOCOL
```

You should see that the `GIT_PROTOCOL` environment variable is sent:

```plaintext
debug1: Sending env GIT_PROTOCOL = version=2
```

For the server side, you can use the [same examples from HTTP](#http-connections), changing the
URL to use SSH.

### Observe Git protocol version of connections

For information on observing the Git protocol versions are being used in a production environment,
see the [relevant documentation](gitaly/monitoring.md#queries).
