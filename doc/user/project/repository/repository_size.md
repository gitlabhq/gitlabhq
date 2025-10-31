---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Understand repository size calculation, limits, and methods to reduce Git repository storage.
title: Repository size
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The size of a Git repository can significantly impact performance and storage costs.
It can differ slightly from one instance to another due to compression, housekeeping, and other factors.

## Size calculation

The project overview page shows the size of all files in the repository, including repository files,
artifacts, and LFS. This size is updated every 15 minutes.

The size of a repository is determined by computing the accumulated size of all files in the repository.
This calculation is similar to executing `du --summarize --bytes` on your repository's
[hashed storage path](../../../administration/repository_storage_paths.md).

## Size and storage limits

Administrators can set a [repository size limit](../../../administration/settings/account_and_limit_settings.md#repository-size-limit)
for GitLab Self-Managed. For GitLab SaaS, size limits are [pre-defined](../../gitlab_com/_index.md#account-and-limit-settings).

When a project reaches its size limit, certain operations like pushing, creating merge requests,
and uploading LFS objects are restricted.

## Before you rewrite Git history

Before you rewrite the Git history and remove data from a repository, you must take into account the information in the following sections.

### Local clones must be changed

Everyone who has a clone of the repository must either:

- Delete their local copy and clone a new copy of the repository.
- Fetch all remote changes and ensure all ongoing work is rebased on top of that.

When not done properly, users pushing local changes can revive files that were supposed to be deleted.

### Running pipelines can cause cleanup to fail

When there are still pipelines running during a cleanup, they can interact with the repository and can cause the cleanup to not work properly.

### Garbage collection grace period

GitLab runs Git garbage collection with a grace period of 30 minutes. This
process cleans up objects that are both:

- Not reachable from any reference.
- At least 30 minutes old.

If the data you wanted to remove is reachable from any commit or is less than
30 minutes old, Git garbage collection will not remove it.

As a result, you must wait at least 30 minutes before selecting **Prune unreachable objects** after running housekeeping.

### History cannot be rewritten on forked project

The builtin methods cannot be used on repositories that are forked. The way
GitLab objects are stored across forks makes it impossible for Git to garbage
collect objects that are shared between forks.

### Workaround: Archive the project

If you [archive](../working_with_projects.md#archive-a-project) before doing the
cleanup, the repository will be read-only. This will ensure no one will make
changes while the cleanup is in progress.

Archiving a repository will also remove the fork relation. This would allow you
the clean up data. But if the data was pulled up into a fork, cleanup would need
to happen there as well.

## Methods to reduce repository size

The following methods are available to reduce the size of a repository:

- [Purge files from history](#purge-files-from-repository-history): Remove large files from the entire Git history.
- [Clean up repository](#clean-up-repository): Remove internal Git references and unreferenced objects.
- [Remove blobs](#remove-blobs): Permanently delete blobs containing sensitive or confidential information.

Before you reduce your repository size, you should [create a full backup of your repository](../../../administration/backup_restore/_index.md).
These methods are irreversible and can potentially affect your project's history and data.

When you reduce your repository size with any of the available methods, you don't need to block
access to your project. You can perform these operations while your project remains accessible to
users. These methods don't have any known performance implications and don't cause downtime.
However, you should perform these actions during periods of low activity to minimize
the potential impact on users.

### Purge files from repository history

You can [purge files with `git filter-repo`](../../../topics/git/repository.md#purge-files-from-repository-history)
to remove large files from Git history. Do not use this method to remove sensitive data like passwords or keys.
Instead use [remove blobs](#remove-blobs) or [redact text](#redact-text-from-repository).

This process:

- Modifies the entire Git history.
- Might affect open merge requests.
- Might affect existing pipelines.
- Requires re-cloning of local repositories.
- Does not affect LFS objects.
- Does not specify commit signatures.
- Is irreversible.

{{< alert type="note" >}}

Information about commits, including file content, is cached in the database, and remains visible
even after they have been removed from the repository.

{{< /alert >}}

### Clean up repository

Use this method to remove internal Git references and unreferenced objects from your repository.
Do not use this method to remove sensitive data.
Instead use [Remove blobs](#remove-blobs).

This process:

- Runs `git gc --prune=30.minutes.ago` to remove unreferenced objects.
- Unlinks unused LFS objects, freeing storage space.
- Recalculates repository size on disk.
- Is irreversible.

{{< alert type="warning" >}}

Removing internal Git references causes associated merge request commits, pipelines, and change
details to become unavailable.

{{< /alert >}}

Prerequisites:

- The list of objects to remove. Use the [`git filter-repo`](https://github.com/newren/git-filter-repo)
to produce a list of objects in a`commit-map` file.

To clean up a repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to **Settings** > **Repository**.
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

## Remove data from a repository

To remove sensitive or confidential data from a repository, use one of these methods:

- To remove the files completely, [remove blobs](#remove-blobs).
- To keep the files, but replace confidential text with the replacement text `***REMOVED***`, [redact text](#redact-text-from-repository).

### Remove blobs

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/450701) in GitLab 17.1 [with a flag](../../../administration/feature_flags/_index.md) named `rewrite_history_ui`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/462999) in GitLab 17.2.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/462999) in GitLab 17.3.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/472018) in GitLab 17.9. Feature flag `rewrite_history_ui` removed.

{{< /history >}}

A Git binary large object (blob) stores file contents without metadata.
Each blob has a unique SHA hash that represents a specific version of a file in the repository.

Use this method to permanently delete blobs that contain sensitive or confidential information.

This process:

- Rewrites Git history.
- Drops commit signatures.
- Might cause open merge requests to fail to merge, requiring a manual rebase.
- Might cause pipelines referencing old commit SHAs to break.
- Might affect historical tags and branches based on old commit history.
- Requires re-cloning of local repositories.
- Is irreversible.

{{< alert type="note" >}}

You can also replace strings with the replacement string `***REMOVED***`. For more information, see
[redact text from repository](#redact-text-from-repository).

{{< /alert >}}

Prerequisites:

- You must have the Owner role for the project
- [A list of object IDs](#get-a-list-of-object-ids) to remove.
- Your project must not be:
  - A fork of a public upstream project.
  - A public upstream project with downstream forks.

{{< alert type="note" >}}

To ensure successful blob removal, consider temporarily restricting repository access during the
process. New commits pushed during blob removal can cause the operation to fail.

{{< /alert >}}

To remove blobs from your repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **Repository**.
1. Expand **Repository maintenance**.
1. Select **Remove blobs**.
1. Enter a list of blob IDs to remove, each ID on its own line.
1. Select **Remove blobs**.
1. On the confirmation dialog, enter your project path.
1. Select **Yes, remove blobs**.
1. On the left sidebar, select **Settings** > **General**.
1. Expand the section labeled **Advanced**.
1. Select **Run housekeeping**. Wait at least 30 minutes for the operation to complete.
1. In the same **Settings** > **General** > **Advanced** section, select **Prune unreachable objects**.
   This operation takes approximately 5-10 minutes to complete.

{{< alert type="note" >}}

If the project containing the sensitive information has been forked, the housekeeping task might
succeed without completing this process. Housekeeping must maintain the integrity of the
[special object pool repository](../../../administration/housekeeping.md#object-pool-repositories),
which contains the forked data.
For help, contact GitLab Support.

{{< /alert >}}

#### Get a list of object IDs

To remove blobs, you need a list of objects to remove.
To get these IDs, use the `ls-tree` command or use the [Repositories API list repository tree](../../../api/repositories.md#list-repository-tree) endpoint.
The following instructions use the `ls-tree` command.

Prerequisites:

- The repository must be cloned to your local machine.

To get a list of blobs at a given commit or branch sorted by size:

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

### Redact text from repository

{{< history >}}

- Introduced in GitLab 17.1 [with a flag](../../../administration/feature_flags/_index.md) named `rewrite_history_ui`. Disabled by default. GitLab team members can view more information in this confidential issue: `https://gitlab.com/gitlab-org/gitlab/-/issues/450701`.
- Enabled on GitLab.com in confidential issue `https://gitlab.com/gitlab-org/gitlab/-/issues/462999` in GitLab 17.2.
- Enabled on GitLab Self-Managed and GitLab Dedicated in confidential issue `https://gitlab.com/gitlab-org/gitlab/-/issues/462999` in GitLab 17.3.
- Generally available in confidential issue `https://gitlab.com/gitlab-org/gitlab/-/issues/472018` in GitLab 17.9. Feature flag `rewrite_history_ui` removed.

{{< /history >}}

Permanently delete sensitive or confidential information that was accidentally committed, ensuring
it's no longer accessible in your repository's history.
Replaces a list of strings with `***REMOVED***`.

{{< alert type="warning" >}}

This action is irreversible. After rewriting history and running housekeeping, the changes are permanent.

{{< /alert >}}

While redacting files in GitLab removes exposed secrets, it also:

- Rewrites Git history. Historical tags and branches based on the old commit history might not function correctly.
- Is destructive. Existing local clones are incompatible with the updated repository and must be re-cloned.
- Updates commit hashes because the redaction updates their content.
- Drops commit signatures during the rewrite process.
- Breaks features that depend on commit hashes, including:
  - Open merge requests. Open merge requests might fail to merge, and require a manual rebase.
  - Links to previous commits, which results in 404 errors.
- Might break pipelines that reference old commit SHAs and require reconfiguration.

For better repository integrity, you should instead:

- Revoke or rotate exposed secrets.
- Implement [the secret detection capabilities of GitLab](../../application_security/secret_detection/_index.md).

This approach:

- Proactively prevents future secret leaks.
- Maintains Git history while ensuring security compliance.

For more information, see [secret push protection](../../application_security/secret_detection/secret_push_protection/_index.md).

Alternatively, to completely delete specific files from a repository, see
[Remove blobs](#remove-blobs).

Prerequisites:

- You must have the Owner role for the project.

To redact text from your repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **Repository**.
1. Expand **Repository maintenance**.
1. Select **Redact text**.
1. On the drawer, enter the text to redact. Regexes and glob patterns are accepted.
1. Select **Redact matching strings**.
1. On the confirmation dialog, enter your project path.
1. Select **Yes, redact matching strings**.
1. On the left sidebar, select **Settings** > **General**.
1. Expand **Advanced**.
1. Select **Run housekeeping**. Wait at least 30 minutes for the operation to complete.
1. In the same **Settings** > **General** > **Advanced** section, select **Prune unreachable objects**.
   This operation takes approximately 5-10 minutes to complete.

{{< alert type="note" >}}

If the project containing the sensitive information has been forked, the housekeeping task might fail to
complete this redaction process to maintain the integrity of the special object pool repository
[which contains the forked data](../../../administration/housekeeping.md#object-pool-repositories).
For help, contact GitLab Support.

{{< /alert >}}

## Troubleshooting

These sections have solutions for issues you might encounter.

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
   UpdateProjectStatisticsWorker.perform_async(p.id, ["commit_count","repository_size","storage_size","lfs_objects_size","container_registry_size"])
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

### Blobs are not removed

When blobs are successfully removed, GitLab adds an entry in the project audit logs and sends an
email notification to the person who initiated the action.

If the blob removal fails, GitLab sends an email notification to the initiator with the subject
`<project_name> | Project history rewrite failure`. The email body contains the full error message.

Possible errors and solutions:

- `validating object ID: invalid object ID`:

  The object ID list contains a syntax error or an incorrect object ID. To resolve this:

    1. Regenerate the [object IDs list](#get-a-list-of-object-ids).
    1. Re-run the [blob removal steps](#remove-blobs).

- `source repository checksum altered`:

  This occurs when someone pushes a commit during the blob removal process. To resolve this:

    1. Temporarily block all pushes to the repository.
    1. Re-run the [blob removal steps](#remove-blobs).
    1. Re-enable pushes after the process completes successfully.

### Repository size limit reached

If you've reached the repository size limit:

- Try removing some data and making a new commit.
- If unsuccessful, consider moving some blobs to [Git LFS](../../../topics/git/lfs/_index.md) or removing old dependency updates from history.
- If you still can't push changes, contact your GitLab administrator to temporarily [increase the limit for your project](../../../administration/settings/account_and_limit_settings.md#repository-size-limit).
- As a last resort, create a new project and migrate your data.

{{< alert type="note" >}}

Deleting files in a new commit doesn't reduce repository size immediately, as earlier commits and blobs still exist.
To effectively reduce size, you must rewrite history using a tool like [`git filter-repo`](https://github.com/newren/git-filter-repo).

{{< /alert >}}
