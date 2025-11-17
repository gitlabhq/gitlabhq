---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Moving repositories managed by GitLab
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Move all repositories managed by GitLab to another file system or another server.

## Move data in a GitLab instance

Use the GitLab API to move Git repositories:

- Between servers.
- Between different storages.
- From single-node Gitaly to Gitaly Cluster (Praefect).

GitLab repositories can be associated with projects, groups, and snippets. Each of these types has a separate API for
moving the repositories. To move all repositories on a GitLab instance, each of type of repository must be moved for
each storage.

Each repository is made read-only for the duration of the move and is not writable until the move is finished.

To move repositories:

1. Ensure all [local and cluster storages](../gitaly/configure_gitaly.md#mixed-configuration) are accessible to the GitLab instance. In
   this example, these are `<original_storage_name>` and `<cluster_storage_name>`.
1. [Configure repository storage weights](../repository_storage_paths.md#configure-where-new-repositories-are-stored)
   so that the new storages receives all new projects. This stops new projects from being created on existing storages
   while the migration is in progress.
1. Schedule repository moves for projects, snippets, and group.
1. If you use [Geo](../geo/_index.md),
   [resync all repositories](../geo/replication/troubleshooting/synchronization_verification.md#resync-all-resources-of-one-component).

### Move projects

You can move all projects or individual projects.

To move all projects by using the API:

1. [Schedule repository storage moves for all projects on a storage shard](../../api/project_repository_storage_moves.md#schedule-repository-storage-moves-for-all-projects-on-a-storage-shard)
   using the API. For example:

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/project_repository_storage_moves"
   ```

1. [Query the most recent repository moves](../../api/project_repository_storage_moves.md#retrieve-all-project-repository-storage-moves)
   using the API. The response indicates either:
   - The moves have completed successfully. The `state` field is `finished`.
   - The moves are in progress. Re-query the repository move until it completes successfully.
   - The moves have failed. Most failures are temporary and are solved by rescheduling the move.

1. After the moves are complete, use the API to [query projects](../../api/projects.md#list-all-projects) and confirm
   that all projects have moved. None of the projects should be returned with the `repository_storage` field set to the
   old storage. For example:

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
   "https://gitlab.example.com/api/v4/projects?repository_storage=<original_storage_name>"
   ```

   Alternatively, use the Rails console to confirm that all projects have moved:

   ```ruby
   ProjectRepository.for_repository_storage('<original_storage_name>')
   ```

1. Repeat for each storage as required.

If you don't want to move all projects, follow the instructions for
[moving individual projects](../../api/project_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-project).

### Move snippets

You can move all snippets or individual snippets.

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

1. After the moves are complete, use the Rails console to confirm that all snippets have moved:

   ```ruby
   SnippetRepository.for_repository_storage('<original_storage_name>')
   ```

   The command should not return snippets for the original storage.

1. Repeat for each storage as required.

If you don't want to move all snippets, follow the instructions for
[individual snippets](../../api/snippet_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-snippet).

### Move groups

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can move all groups or individual groups.

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

1. After the moves are complete, use the Rails console to confirm that all groups have moved:

   ```ruby
   GroupWikiRepository.for_repository_storage('<original_storage_name>')
   ```

   The command should not return groups for the original storage.

1. Repeat for each storage as required.

If you don't want to move all groups, follow the instructions for
[individual groups](../../api/group_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-group).

## Migrate to another GitLab instance

You can't [move data by using the API](#move-data-in-a-gitlab-instance) if you are migrating to a new GitLab
environment. For example:

- From a single-node GitLab to a scaled-out architecture.
- From a GitLab instance in your private data center to a cloud provider.

In this case, there are ways you can copy all your repositories from `/var/opt/gitlab/git-data/repositories` to
`/mnt/gitlab/repositories` depending on the scenario:

- The target directory is empty.
- The target directory contains an outdated copy of the repositories.
- When you have thousands of repositories.

{{< alert type="warning" >}}

Each of the approaches can or does overwrite data in the target directory `/mnt/gitlab/repositories`. You must correctly
specify the source and the target.

{{< /alert >}}

### Use backup and restore (recommended)

For either Gitaly or Gitaly Cluster (Praefect) targets, you should use the GitLab
[backup and restore capability](../backup_restore/_index.md). Git repositories are accessed, managed, and stored on
GitLab servers by Gitaly as a database. You can experience data loss if you directly access and copy Gitaly files using
tools like `rsync`. You can:

- Improve backup performance by
  [processing multiple repositories concurrently](../backup_restore/backup_gitlab.md#back-up-git-repositories-concurrently).
- Create backups of just the repositories by using the
  [skip feature](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup).

You must use the back up and restore method for Gitaly Cluster (Praefect) targets.

### Use `tar`

You can use a `tar` pipe to move repositories if:

- You specify Gitaly targets and not Gitaly Cluster targets.
- The target directory `/mnt/gitlab/repositories` is empty.

This method has low overhead and `tar` is usually pre-installed on your system. However, you cannot resume an
interrupted `tar` pipe. If `tar` is interrupted, you must empty the target directory and copy all the data again.

To see progress of the `tar` process, replace `-xf` with `-xvf`.

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  tar -C /mnt/gitlab/repositories -xf -'
```

#### Use a `tar` pipe to another server

For Gitaly targets, you can use a `tar` pipe to copy data to another server. If your `git` user has SSH access to the
new server as `git@<newserver>`, you can pipe the data through SSH.

If you want to compress the data before it goes over the network (which increases CPU usage) you can replace
`ssh` with `ssh -C`.

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  ssh git@newserver tar -C /mnt/gitlab/repositories -xf -'
```

### Use `rsync`

You can use a `rsync` to move repositories if:

- You specify Gitaly targets and not Gitaly Cluster targets.
- The target directory already contains a partial or outdated copy of the repositories, which means copying all the data
  again with `tar` is inefficient.

{{< alert type="warning" >}}

You must use the `--delete` option when using `rsync`. Using `rsync` without `--delete` can cause data loss and
repository corruption. For more information, see [issue 270422](https://gitlab.com/gitlab-org/gitlab/-/issues/270422).

{{< /alert >}}

The `/.` in the following command is very important, otherwise you can get the wrong directory structure in the target
directory. If you want to see progress, replace `-a` with `-av`.

```shell
sudo -u git  sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  /mnt/gitlab/repositories'
```

#### Use `rsync` to another server

For Gitaly targets, you can send the repositories over the network with `rsync` if the `git` user on your source system
has SSH access to the target server.

```shell
sudo -u git sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  git@newserver:/mnt/gitlab/repositories'
```

## Related topics

- [Configure Gitaly](../gitaly/configure_gitaly.md)
- [Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md)
- [Project repository storage moves API](../../api/project_repository_storage_moves.md)
- [Group repository storage moves API](../../api/group_repository_storage_moves.md)
- [Snippet repository storage moves API](../../api/snippet_repository_storage_moves.md)
