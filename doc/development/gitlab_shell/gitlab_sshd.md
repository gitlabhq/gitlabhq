---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: '`gitlab-sshd` in GitLab Shell'
---

`gitlab-sshd` is a binary in [`gitlab-shell`](https://gitlab.com/gitlab-org/gitlab-shell)
which runs as a persistent SSH daemon. It is intended to replace `OpenSSH` on GitLab SaaS,
and eventually other cloud-native environments. Instead of running an `sshd` process,
we run a `gitlab-sshd` process that does the same job, in a more focused manner:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
sequenceDiagram
    participant Git on client
    participant GitLab SSHD
    participant Rails
    participant Gitaly
    participant Git on server

    Note left of Git on client: git fetch
    Git on client->>+GitLab SSHD: ssh git fetch-pack request
    GitLab SSHD->>+Rails: GET /internal/api/authorized_keys?key=AAAA...
    Note right of Rails: Lookup key ID
    Rails-->>-GitLab SSHD: 200 OK, command="gitlab-shell upload-pack key_id=1"
    GitLab SSHD->>+Rails: GET /internal/api/allowed?action=upload_pack&key_id=1
    Note right of Rails: Auth check
    Rails-->>-GitLab SSHD: 200 OK, { gitaly: ... }
    GitLab SSHD->>+Gitaly: SSHService.SSHUploadPack request
    Gitaly->>+Git on server: git upload-pack request
    Note over Git on client,Git on server: Bidirectional communication between Git client and server
    Git on server-->>-Gitaly: git upload-pack response
    Gitaly -->>-GitLab SSHD: SSHService.SSHUploadPack response
    GitLab SSHD-->>-Git on client: ssh git fetch-pack response
```
