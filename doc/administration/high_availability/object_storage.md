---
type: reference
---

# Cloud Object Storage

GitLab supports utilizing a Cloud Object Storage service over [NFS](nfs.md) for holding
numerous types of data. This is recommended in larger setups as object storage is
typically much more performant and reliable.

For configuring GitLab to use Object Storage refer to the following guides:

1. Make sure the [`git` user home directory](https://docs.gitlab.com/omnibus/settings/configuration.html#moving-the-home-directory-for-a-user) is on local disk.
1. Configure [database lookup of SSH keys](../operations/fast_ssh_key_lookup.md)
   to eliminate the need for a shared `authorized_keys` file.
1. Configure [object storage for job artifacts](../job_artifacts.md#using-object-storage)
   including [incremental logging](../job_logs.md#new-incremental-logging-architecture).
1. Configure [object storage for LFS objects](../lfs/lfs_administration.md#storing-lfs-objects-in-remote-object-storage).
1. Configure [object storage for uploads](../uploads.md#using-object-storage-core-only).
1. Configure [object storage for merge request diffs](../merge_request_diffs.md#using-object-storage).
1. Configure [object storage for packages](../packages/index.md#using-object-storage) (optional feature).
1. Configure [object storage for dependency proxy](../packages/dependency_proxy.md#using-object-storage) (optional feature).

NOTE: **Note:**
One current feature of GitLab that still requires a shared directory (NFS) is
[GitLab Pages](../../user/project/pages/index.md).
There is [work in progress](https://gitlab.com/gitlab-org/gitlab-pages/issues/196)
to eliminate the need for NFS to support GitLab Pages.
