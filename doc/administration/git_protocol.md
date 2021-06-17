---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
description: "Set and configure Git protocol v2"
---

# Configuring Git Protocol v2 **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/46555) in GitLab 11.4.
> - [Temporarily disabled](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/55769) in GitLab 11.5.8, 11.6.6, 11.7.1, and 11.8+.
> - [Re-enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/27828) in GitLab 12.8.

Git protocol v2 improves the v1 wire protocol in several ways and is
enabled by default in GitLab for HTTP requests. In order to enable SSH,
further configuration is needed by the administrator.

More details about the new features and improvements are available in
the [Google Open Source Blog](https://opensource.googleblog.com/2018/05/introducing-git-protocol-version-2.html)
and the [protocol documentation](https://github.com/git/git/blob/master/Documentation/technical/protocol-v2.txt).

## Requirements

From the client side, `git` `v2.18.0` or newer must be installed.

From the server side, if we want to configure SSH we need to set the `sshd`
server to accept the `GIT_PROTOCOL` environment.

In installations using [GitLab Helm Charts](https://docs.gitlab.com/charts/)
and [All-in-one Docker image](https://docs.gitlab.com/omnibus/docker/), the SSH
service is already configured to accept the `GIT_PROTOCOL` environment. Users
need not do anything more.

For Omnibus GitLab and installations from source, update
the SSH configuration of your server manually by adding this line to the `/etc/ssh/sshd_config` file:

```plaintext
AcceptEnv GIT_PROTOCOL
```

Once configured, restart the SSH daemon for the change to take effect:

```shell
# CentOS 6 / RHEL 6
sudo service sshd restart

# All other supported distributions
sudo systemctl restart ssh
```

## Instructions

In order to use the new protocol, clients need to either pass the configuration
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
GIT_SSH_COMMAND="ssh -v" git -c protocol.version=2 ls-remote ssh://git@your-gitlab-instance.com/group/repo.git 2>&1 |grep GIT_PROTOCOL
```

You should see that the `GIT_PROTOCOL` environment variable is sent:

```plaintext
debug1: Sending env GIT_PROTOCOL = version=2
```

For the server side, you can use the [same examples from HTTP](#http-connections), changing the
URL to use SSH.

### Observe Git protocol version of connections

To observe what Git protocol versions are being used in a
production environment, you can use the following Prometheus query:

```prometheus
sum(rate(gitaly_git_protocol_requests_total[1m])) by (grpc_method,git_protocol,grpc_service)
```

<!-- This link sporadically returns a 503 during automated link checking but is correct -->

You can view what Git protocol versions are being used on GitLab.com at
<https://dashboards.gitlab.com/d/pqlQq0xik/git-protocol-versions>.
