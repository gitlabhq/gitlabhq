---
description: "Set and configure Git protocol v2"
---

# Git Protocol configuration

> [Introduced][ce-46555] in GitLab 11.4.

---

Git protocol v2 improves the wire protocol v1 in several ways and is
enabled by default in GitLab for HTTP requests. In order to enable SSH
further configuration needs to be set by the administrator.

More details about the new features and improvements are available in
the ([protocol documentation][protocol-doc]).

## Requirements

From the client side, `git` `v2.18.0` or recent needs to be installed.

From the server side, if we want to configure SSH we need to set the SSHD
server to accept the `GIT_PROTOCOL` environment.

```
# /etc/ssh/sshd_config
AcceptEnv GIT_PROTOCOL
```

then restart the SSHD daemon. In Ubuntu, this is done like:

```
sudo service ssh restart
```

## Instructions

In order to use the new protocol, clients need to either pass the configuration
`-c protocol.version=2` to the git command, or set it globally:

```
git config --global protocol.version 2
```

Verify Git v2 is used by running:

```
GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | head
```

Example response using Git protocol v2:

```
s$ GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://gitlab.com/gitlab-org/gitlab-ce.git 2>&1 | head
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

[ce-46555]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/46555 "Git protocol v2 merge request"
[protocol-doc]: https://github.com/git/git/blob/master/Documentation/technical/protocol-v2.txt "Git protocol v2"
