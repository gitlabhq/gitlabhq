---
description: "Set and configure Git protocol v2"
---

# Configuring Git Protocol v2

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/46555) in GitLab 11.4.
> Temporarily disabled (see [confidential issue](../user/project/issues/confidential_issues.md)
> `https://gitlab.com/gitlab-org/gitlab-ce/issues/55769`) in GitLab 11.5.8, 11.6.6, 11.7.1, and 11.8+.

NOTE: **Note:**
Git protocol v2 support has been temporarily disabled
because a feature used to hide certain internal references does not function when it
is enabled, and this has a security impact. Once this problem has been resolved,
protocol v2 support will be re-enabled. For more information, see the
[confidential issue](../user/project/issues/confidential_issues.md)
`https://gitlab.com/gitlab-org/gitlab-ce/issues/55769`.

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
and [All-in-one docker image](https://docs.gitlab.com/omnibus/docker/), the SSH
service is already configured to accept the `GIT_PROTOCOL` environment and users
need not do anything more.

For Omnibus GitLab and installations from source, you have to manually update
the SSH configuration of your server:

```
# /etc/ssh/sshd_config
AcceptEnv GIT_PROTOCOL
```

Once configured, restart the SSH daemon. In Ubuntu, run:

```sh
sudo service ssh restart
```

## Instructions

In order to use the new protocol, clients need to either pass the configuration
`-c protocol.version=2` to the Git command, or set it globally:

```sh
git config --global protocol.version 2
```

### HTTP connections

Verify Git v2 is used by the client:

```sh
GIT_TRACE_CURL=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | grep Git-Protocol
```

You should see that the `Git-Protocol` header is sent:

```
16:29:44.577888 http.c:657              => Send header: Git-Protocol: version=2
```

Verify Git v2 is used by the server:

```sh
GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | head
```

Example response using Git protocol v2:

```sh
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

```sh
GIT_SSH_COMMAND="ssh -v" git -c protocol.version=2 ls-remote ssh://your-gitlab-instance.com:group/repo.git 2>&1 |grep GIT_PROTOCOL
```

You should see that the `GIT_PROTOCOL` environment variable is sent:

```
debug1: Sending env GIT_PROTOCOL = version=2
```

For the server side, you can use the [same examples from HTTP](#http-connections), changing the
URL to use SSH.
