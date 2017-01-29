# Gitaly

> [Introduced][ce-8440] in GitLab 8.16.


[Gitaly][gitaly] is a Git RPC service for handling git calls made by GitLab. You
can configure the path where Gitaly is located in GitLab's configuration. This
configuration will be shared with all other components that make use of Gitaly.
If you don't this configuration option, Gitaly features will be disabled.

## Configure GitLab

**For installations from source**

1. Edit `gitlab.yml` and add the Gitaly path:

  ```yaml
  # Gitaly settings
  gitaly:
    socket_path: /home/git/gitaly/gitaly.socket
  ```


**For Omnibus installations**

???


[ce-8440]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8440
[gitaly]: https://gitlab.com/gitlab-org/gitaly/
