---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Moving repositories managed by GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can move all repositories managed by GitLab to another file system or another server.

## Moving data in a GitLab instance

The GitLab API is the recommended way to move Git repositories:

- Between servers.
- Between different storage.
- From single-node Gitaly to Gitaly Cluster.

For more information, see:

- [Configuring additional storage for Gitaly](../gitaly/configure_gitaly.md#network-architecture). This
  example configures additional storage called `storage1` and `storage2`.
- [The API documentation](../../api/project_repository_storage_moves.md) details the endpoints for
  querying and scheduling project repository moves.
- [The API documentation](../../api/snippet_repository_storage_moves.md) details the endpoints for
  querying and scheduling snippet repository moves.
- [The API documentation](../../api/group_repository_storage_moves.md) details the endpoints for
  querying and scheduling group repository moves.
- [Migrate to Gitaly Cluster](../gitaly/_index.md#migrate-to-gitaly-cluster).

### Moving Repositories

GitLab repositories can be associated with projects, groups, and snippets. Each of these types
has a separate API to schedule the respective repositories to move. To move all repositories
on a GitLab instance, each of these types must be scheduled to move for each storage.

Each repository is made read-only for the duration of the move. The repository is not writable
until the move has completed.

To move repositories:

1. Ensure all [local and cluster storages](../gitaly/configure_gitaly.md#mixed-configuration) are accessible to the GitLab instance. In
   this example, these are `<original_storage_name>` and `<cluster_storage_name>`.
1. [Configure repository storage weights](../repository_storage_paths.md#configure-where-new-repositories-are-stored)
   so that the new storages receives all new projects. This stops new projects from being created
   on existing storages while the migration is in progress.
1. Schedule repository moves for:
   - [All projects](#move-all-projects) or
     [individual projects](../../api/project_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-project).
   - [All snippets](#move-all-snippets) or
     [individual snippets](../../api/snippet_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-snippet).
   - [All groups](#move-all-groups) or
     [individual groups](../../api/group_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-group).
1. If [Geo](../geo/_index.md) is enabled,
   [resync all repositories](../geo/replication/troubleshooting/synchronization_verification.md#queue-up-all-repositories-for-resync).

#### Move all projects

To move all projects by using the API:

1. [Schedule repository storage moves for all projects on a storage shard](../../api/project_repository_storage_moves.md#schedule-repository-storage-moves-for-all-projects-on-a-storage-shard)
   using the API. For example:

   ```shell
   curl --request POST --header "Private-Token: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/project_repository_storage_moves"
   ```

1. [Query the most recent repository moves](../../api/project_repository_storage_moves.md#retrieve-all-project-repository-storage-moves)
   using the API. The response indicates either:
   - The moves have completed successfully. The `state` field is `finished`.
   - The moves are in progress. Re-query the repository move until it completes successfully.
   - The moves have failed. Most failures are temporary and are solved by rescheduling the move.

1. After the moves are complete, use the API to [query projects](../../api/projects.md#list-all-projects) and confirm that all projects have moved. None of the projects should be returned with the
   `repository_storage` field set to the old storage. For example:

   ```shell
   curl --header "Private-Token: <your_access_token>" --header "Content-Type: application/json" \
   "https://gitlab.example.com/api/v4/projects?repository_storage=<original_storage_name>"
   ```

   Alternatively use [the rails console](../operations/rails_console.md) to confirm that all
   projects have moved. Run the following in the rails console:

   ```ruby
   ProjectRepository.for_repository_storage('<original_storage_name>')
   ```

1. Repeat for each storage as required.

#### Move all snippets

To move all snippets by using the API:

1. [Schedule repository storage moves for all snippets on a storage shard](../../api/snippet_repository_storage_moves.md#schedule-repository-storage-moves-for-all-snippets-on-a-storage-shard). For example:

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
   ```

1. [Query the most recent repository moves](../../api/snippet_repository_storage_moves.md#retrieve-all-snippet-repository-storage-moves).
   The response indicates either:
   - The moves have completed successfully. The `state` field is `finished`.
   - The moves are in progress. Re-query the repository move until it completes successfully.
   - The moves have failed. Most failures are temporary and are solved by rescheduling the move.

1. After the moves are complete, use [the rails console](../operations/rails_console.md) to confirm
   that all snippets have moved. No snippets should be returned for the original storage. Run the
   following in the rails console:

   ```ruby
   SnippetRepository.for_repository_storage('<original_storage_name>')
   ```

1. Repeat for each storage as required.

#### Move all groups

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

To move all groups by using the API:

1. [Schedule repository storage moves for all groups on a storage shard](../../api/group_repository_storage_moves.md#schedule-repository-storage-moves-for-all-groups-on-a-storage-shard).
   For example:

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/group_repository_storage_moves"
   ```

1. [Query the most recent repository moves](../../api/group_repository_storage_moves.md#retrieve-all-group-repository-storage-moves).
   The response indicates either:
   - The moves have completed successfully. The `state` field is `finished`.
   - The moves are in progress. Re-query the repository move until it completes successfully.
   - The moves have failed. Most failures are temporary and are solved by rescheduling the move.

1. After the moves are complete, use [the rails console](../operations/rails_console.md) to confirm
   that all groups have moved. No groups should be returned for the original storage. Run the
   following in the rails console:

   ```ruby
   GroupWikiRepository.for_repository_storage('<original_storage_name>')
   ```

1. Repeat for each storage as required.

## Migrating to another GitLab instance

[Using the API](#moving-data-in-a-gitlab-instance) isn't an option if you are migrating to a new
GitLab environment, for example:

- From a single-node GitLab to a scaled-out architecture.
- From a GitLab instance in your private data center to a cloud provider.

The rest of the document looks
at some of the ways you can copy all your repositories from
`/var/opt/gitlab/git-data/repositories` to `/mnt/gitlab/repositories`.

We look at three scenarios:

- The target directory is empty.
- The target directory contains an outdated copy of the repositories.
- How to deal with thousands of repositories.

WARNING:
Each of the approaches we list can or does overwrite data in the target directory
`/mnt/gitlab/repositories`. Do not mix up the source and the target.

### Recommended approach in all cases

For either Gitaly or Gitaly Cluster targets, the GitLab [backup and restore capability](../backup_restore/_index.md)
should be used. Git repositories are accessed, managed, and stored on GitLab servers by Gitaly as a database. Data loss
can result from directly accessing and copying Gitaly files using tools like `rsync`.

- Backup performance can be improved by
  [processing multiple repositories concurrently](../backup_restore/backup_gitlab.md#back-up-git-repositories-concurrently).
- Backups can be created of just the repositories using the
  [skip feature](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup).

No other method works for Gitaly Cluster targets.

### Target directory is empty: use a `tar` pipe

For Gitaly targets (use [recommended approach](#recommended-approach-in-all-cases) for Gitaly Cluster targets), if the
target directory `/mnt/gitlab/repositories` is empty the simplest thing to do is to use a `tar` pipe. This method has
low overhead and `tar` is almost always already installed on your system.

However, it is not possible to resume an interrupted `tar` pipe; if that happens then all data must be copied again.

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  tar -C /mnt/gitlab/repositories -xf -'
```

If you want to see progress, replace `-xf` with `-xvf`.

#### `tar` pipe to another server

For Gitaly targets (use [recommended approach](#recommended-approach-in-all-cases) for Gitaly Cluster targets), you can
also use a `tar` pipe to copy data to another server. If your `git` user has SSH access to the new server as
`git@newserver`, you can pipe the data through SSH.

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  ssh git@newserver tar -C /mnt/gitlab/repositories -xf -'
```

If you want to compress the data before it goes over the network
(which costs you CPU cycles) you can replace `ssh` with `ssh -C`.

### The target directory contains an outdated copy of the repositories: use `rsync`

WARNING:
Using `rsync` to migrate Git data can cause data loss and repository corruption.
[These instructions are being reviewed](https://gitlab.com/gitlab-org/gitlab/-/issues/270422).

If the target directory already contains a partial or outdated copy of the repositories it may be wasteful to copy all
the data again with `tar`. In this scenario it is better to use `rsync` for Gitaly targets (use
[recommended approach](#recommended-approach-in-all-cases) for Gitaly Cluster targets).

This utility is either already installed on your system, or installable using `apt` or `yum`.

```shell
sudo -u git  sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  /mnt/gitlab/repositories'
```

The `/.` in the command above is very important, without it you can
get the wrong directory structure in the target directory.
If you want to see progress, replace `-a` with `-av`.

#### Single `rsync` to another server

WARNING:
Using `rsync` to migrate Git data can cause data loss and repository corruption.
[These instructions are being reviewed](https://gitlab.com/gitlab-org/gitlab/-/issues/270422).

For Gitaly targets (use [recommended approach](#recommended-approach-in-all-cases) for Gitaly Cluster targets), if the
`git` user on your source system has SSH access to the target server you can send the repositories over the network with
`rsync`.

```shell
sudo -u git sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  git@newserver:/mnt/gitlab/repositories'
```
