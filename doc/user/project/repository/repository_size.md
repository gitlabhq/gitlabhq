---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "To remove unwanted large files from a Git repository and reduce its storage size, use the filter-repo command."
---

# Repository size

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The size of a Git repository can significantly impact performance and storage costs.
It can differ slightly from one instance to another due to compression, housekeeping, and other factors.

This page explains:

- [How repository size is calculated](#size-calculation).
- [Size and storage limits](#size-and-storage-limits).
- [Methods to reduce repository size](#methods-to-reduce-repository-size).

## Size calculation

The **Project overview** page shows the size of all files in the repository, including repository files,
artifacts, and LFS. This size is updated every 15 minutes.

The size of a repository is determined by computing the accumulated size of all files in the repository.
This calculation is similar to executing `du --summarize --bytes` on your repository's
[hashed storage path](../../../administration/repository_storage_paths.md).

## Size and storage limits

Administrators can set a [repository size limit](../../../administration/settings/account_and_limit_settings.md#repository-size-limit)
for self-managed instances. For GitLab.com, size limits are [pre-defined](../../gitlab_com/index.md#account-and-limit-settings).

When a project reaches its size limit, certain operations like pushing, creating merge requests,
and uploading LFS objects are restricted.

## Methods to reduce repository size

The following methods are available to reduce the size of a repository:

- [Purge files from history](#purge-files-from-repository-history)
- [Clean up repository](#clean-up-repository)
- [Remove blobs](#remove-files)

### Purge files from repository history

Use this method to remove large files from the entire Git history.

It is not suitable for removing sensitive data like passwords or keys from your repository.
Information about commits, including file content, is cached in the database, and remain visible
even after they have been removed from the repository. To remove sensitive data, use the method
described in [Remove blobs](#remove-files).

For more information, see [use Git to purge files from repository history](../../../topics/git/repository.md#purge-files-from-repository-history).

### Clean up repository

Use this method to remove internal Git references and unreferenced objects.

This process:

- Removes any internal Git references to old commits.
- Runs `git gc --prune=30.minutes.ago` against the repository to remove unreferenced objects.
- Unlinks any unused LFS objects attached to your project, freeing up storage space.
- Recalculates the size of your repository on disk.

WARNING:
Removing internal Git references causes associated merge request commits, pipelines, and change
details to become unavailable.

Prerequisites:

- The list of objects to remove. Use the [`git filter-repo`](https://github.com/newren/git-filter-repo)
to produce a list of objects in a`commit-map` file.

To clean up a repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to **Settings > Repository**.
1. Expand **Repository maintenance**.
1. Upload the list of objects to remove. For example, the `commit-map` file in the `filter-repo` directory.

   If your `commit-map` file is too large, the background cleanup process might time out and fail.
   As a result, the repository size isn't reduced as expected. To address this, split the file and
   upload it in parts. Start with `20000` and reduce as needed. For example:

   ```shell
   split -l 20000 filter-repo/commit-map filter-repo/commit-map-
   ```

1. Select **Start cleanup**.

GitLab sends an email notification with the recalculated repository size after the cleanup completes.

### Remove files

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/450701) in GitLab 17.1 [with a flag](../../../administration/feature_flags.md) named `rewrite_history_ui`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/462999) in GitLab 17.2.
> - [Enabled on self-managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/462999) in GitLab 17.3.

Use this method to permanently delete files containing sensitive or confidential information from your repository.

WARNING:
**This action is irreversible.**
After rewriting history and running housekeeping, the changes are permanent.
Be aware of the following impacts when removing blobs from your repository:

- Open merge requests might fail to merge and require manual rebasing.
- Existing local clones are incompatible with the updated repository and must be re-cloned.
- Pipelines referencing old commit SHAs might break and require reconfiguration.
- Historical tags and branches based on the old commit history might not function correctly.
- Commit signatures are dropped during the rewrite process.

NOTE:
To replace strings with `***REMOVED***`, see [Redact information](../../../topics/git/undo.md#redact-information).

Prerequisites:

- You must have the Owner role for the project
- [A list of object IDs](#get-a-list-of-object-ids) to remove.

To remove blobs from your repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Repository**.
1. Expand **Repository maintenance**.
1. Select **Remove blobs**.
1. Enter a list of blob IDs to remove, each ID on its own line.
1. Select **Remove blobs**.
1. On the confirmation dialog, enter your project path.
1. Select **Yes, remove blobs**.
1. On the left sidebar, select **Settings > General**.
1. Expand the section labeled **Advanced**.
1. Select **Run housekeeping**.

#### Get a list of object IDs

To remove blobs, you need a list of objects to remove.
To get these IDs, use the `ls-tree` command or use the [Repositories API list repository tree](../../../api/repositories.md#list-repository-tree) endpoint.
The following instructions use the `ls-tree` command.

Prerequisites:

- The repository must be cloned to your local machine.

To get a list of files at a given commit or branch sorted by size:

1. Open a terminal and go to your repository directory.
1. Run the following command:

   ```shell
   git ls-tree -r -t --long --full-name <COMMIT/BRANCH> | sort -nk 4
   ```

   Example output:

   ```plaintext
   100644 blob 8150ee86f923548d376459b29afecbe8495514e9  133508 doc/howto/img/remote-development-new-workspace-button.png
   100644 blob cde4360b3d3ee4f4c04c998d43cfaaf586f09740  214231 doc/howto/img/dependency_proxy_macos_config_new.png
   100644 blob 2ad0e839a709e73a6174e78321e87021b20be445  216452 doc/howto/img/gdk-in-gitpod.jpg
   100644 blob 115dd03fc0828a9011f012abbc58746f7c587a05  242304 doc/howto/img/gitpod-button-repository.jpg
   100644 blob c41ebb321a6a99f68ee6c353dd0ed29f52c1dc80  491158 doc/howto/img/dependency_proxy_macos_config.png
   ```

   The third column in the output is the object ID of the blob. For example: `8150ee86f923548d376459b29afecbe8495514e9`.

## Troubleshooting

### Incorrect repository statistics shown in the GUI

If the repository size or commit number displayed in the GitLab interface differs from the
exported `.tar.gz` or local repository:

1. Ask a GitLab administrator to force an update using the Rails console.
1. The administrator should run the following commands:

   ```ruby
   p = Project.find_by_full_path('<namespace>/<project>')
   p.statistics.refresh!
   ```

1. To clear project statistics and trigger a recalculation:

   ```ruby
   p.repository.expire_all_method_caches
   UpdateProjectStatisticsWorker.perform_async(p.id, ["commit_count","repository_size","storage_size","lfs_objects_size"])
   ```

1. To check the total artifact storage space:

   ```ruby
   builds_with_artifacts = p.builds.with_downloadable_artifacts.all

   artifact_storage = 0
   builds_with_artifacts.find_each do |build|
     artifact_storage += build.artifacts_size
   end

   puts "#{artifact_storage} bytes"
   ```

### Space not being freed after cleanup

If you've completed a repository cleanup process but the storage usage remains unchanged:

- Be aware that unreachable objects remain in the repository for a two-week grace period.
- These objects are not included in exports but still occupy file system space.
- After two weeks, these objects are automatically pruned, which updates storage usage statistics.
- To expedite this process, ask an administrator to run the ['Prune Unreachable Objects' housekeeping task](../../../administration/housekeeping.md).

### Repository size limit reached

If you've reached the repository size limit:

- Try removing some data and making a new commit.
- If unsuccessful, consider moving some blobs to [Git LFS](../../../topics/git/lfs/index.md) or removing old dependency updates from history.
- If you still can't push changes, contact your GitLab administrator to temporarily [increase the limit for your project](../../../administration/settings/account_and_limit_settings.md#repository-size-limit).
- As a last resort, create a new project and migrate your data.

NOTE:
Deleting files in a new commit doesn't reduce repository size immediately, as earlier commits and blobs still exist.
To effectively reduce size, you must rewrite history using a tool like [`git filter-repo`](https://github.com/newren/git-filter-repo).
