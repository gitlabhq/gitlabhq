---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Repository storage **(FREE SELF)**

GitLab stores [repositories](../user/project/repository/index.md) on repository storage. Repository
storage is either:

- Physical storage configured with a `gitaly_address` that points to a [Gitaly node](gitaly/index.md).
- [Virtual storage](gitaly/index.md#virtual-storage) that stores repositories on a Gitaly Cluster.

WARNING:
Repository storage could be configured as a `path` that points directly to the directory where the repositories are
stored. GitLab directly accessing a directory containing repositories is deprecated. You should configure GitLab to
access repositories through a physical or virtual storage.

For more information on:

- Configuring Gitaly, see [Configure Gitaly](gitaly/configure_gitaly.md).
- Configuring Gitaly Cluster, see [Configure Gitaly Cluster](gitaly/praefect.md).

## Configure where new repositories are stored

After you configure multiple repository storages, you can choose where new repositories are stored:

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. On the left sidebar, select **Settings > Repository** and expand the **Repository storage**
   section.
1. Enter values in the **Storage nodes for new repositories** fields.
1. Select **Save changes**.

Each repository storage path can be assigned a weight from 0-100. When a new project is created,
these weights are used to determine the storage location the repository is created on.

The higher the weight of a given repository storage path relative to other repository storages
paths, the more often it is chosen (`(storage weight) / (sum of all weights) * 100 = chance %`).

By default, if repository weights have not been configured earlier:

- `default` is weighted `100`.
- All other storages are weighted `0`.

NOTE:
If all storage weights are `0` (for example, when `default` does not exist), GitLab attempts to
create new repositories on `default`, regardless of the configuration or if `default` exists.
See [the tracking issue](https://gitlab.com/gitlab-org/gitlab/-/issues/36175) for more information.

## Move repositories

To move a repository to a different repository storage (for example, from `default` to `storage2`), use the
same process as [migrating to Gitaly Cluster](gitaly/index.md#migrate-to-gitaly-cluster).
