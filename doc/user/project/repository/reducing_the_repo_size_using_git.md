---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "To remove unwanted large files from a Git repository and reduce its storage size, use the filter-repo command."
---

# Reduce repository size

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Git repositories become larger over time. When large files are added to a Git repository:

- Fetching the repository becomes slower because everyone must download the files.
- They take up a large amount of storage space on the server.
- Git repository storage limits [can be reached](#storage-limits).

Rewriting a repository can remove unwanted history to make the repository smaller.
We **recommend [`git filter-repo`](https://github.com/newren/git-filter-repo/blob/main/README.md)**
over [`git filter-branch`](https://git-scm.com/docs/git-filter-branch) and
[BFG](https://rtyley.github.io/bfg-repo-cleaner/).

WARNING:
Rewriting repository history is a destructive operation. Make sure to back up your repository before
you begin. The best way to back up a repository is to
[export the project](../settings/import_export.md#export-a-project-and-its-data).

## Calculate repository size

The size of a repository is determined by computing the accumulated size of all files in the repository.
It is similar to executing `du --summarize --bytes` on your repository's
[hashed storage path](../../../administration/repository_storage_paths.md).

## Purge files from repository history

GitLab [prunes unreachable objects](../../../administration/housekeeping.md#prune-unreachable-objects)
as part of housekeeping. In GitLab, to reduce the disk size of your repository manually, you must
first remove references to large files from branches, tags, *and* other internal references (refs)
created by GitLab. These refs include:

- `refs/merge-requests/*`
- `refs/pipelines/*`
- `refs/environments/*`
- `refs/keep-around/*`

NOTE:
For details on each of these references, see
[GitLab-specific references](../../../development/gitaly.md#gitlab-specific-references).

These refs are not automatically downloaded and hidden refs are not advertised, but we can remove these refs using a project export.

WARNING:
This process is not suitable for removing sensitive data like password or keys from your repository.
Information about commits, including file content, is cached in the database, and remain
visible even after they have been removed from the repository.

To purge files from a GitLab repository:

1. Install [`git filter-repo`](https://github.com/newren/git-filter-repo/blob/main/INSTALL.md) and optionally
   [`git-sizer`](https://github.com/github/git-sizer#getting-started)
   using a supported package manager or from source.

1. Generate a fresh
   [export from the project](../settings/import_export.md#export-a-project-and-its-data) and download it.
   This project export contains a backup copy of your repository *and* refs
   we can use to purge files from your repository.

1. Decompress the backup using `tar`:

   ```shell
   tar xzf project-backup.tar.gz
   ```

   This contains a `project.bundle` file, which was created by
   [`git bundle`](https://git-scm.com/docs/git-bundle).

1. Clone a fresh copy of the repository from the bundle using `--bare` and `--mirror` options:

   ```shell
   git clone --bare --mirror /path/to/project.bundle
   ```

1. Go to the `project.git` directory:

   ```shell
   cd project.git
   ```

1. Because cloning from a bundle file sets the `origin` remote to the local bundle file, change it to the URL of your repository:

   ```shell
   git remote set-url origin https://gitlab.example.com/<namespace>/<project_name>.git
   ```

1. Using either `git filter-repo` or `git-sizer`, analyze your repository
   and review the results to determine which items you want to purge:

   ```shell
   # Using git filter-repo
   git filter-repo --analyze
   head filter-repo/analysis/*-{all,deleted}-sizes.txt

   # Using git-sizer
   git-sizer
   ```

1. Purge the history of your repository using relevant `git filter-repo` options.
   Two common options are:

   - `--path` and `--invert-paths` to purge specific files:

     ```shell
     git filter-repo --path path/to/file.ext --invert-paths
     ```

   - `--strip-blobs-bigger-than` to purge all files larger than for example 10M:

     ```shell
     git filter-repo --strip-blobs-bigger-than 10M
     ```

   See the
   [`git filter-repo` documentation](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#EXAMPLES)
   for more examples and the complete documentation.

1. Because you are trying to remove internal refs,
   you need the `commit-map` files produced by each run
   to tell you which internal refs to remove.
   Every `git filter-repo` run creates a new `commit-map`,
   and overwrites the `commit-map` from the previous run.
   You can use the following command to back up each `commit-map` file:

   ```shell
   cp filter-repo/commit-map ./_filter_repo_commit_map_$(date +%s)
   ```

   Repeat this step and all following steps (including the [repository cleanup](#repository-cleanup) step)
   every time you run any `git filter-repo` command.

1. To allow you to force push the changes you need to unset the mirror flag:

   ```shell
    git config --unset remote.origin.mirror
   ```

1. Force push your changes to overwrite all branches on GitLab:

   ```shell
   git push origin --force 'refs/heads/*'
   ```

   [Protected branches](../protected_branches.md) cause this to fail. To proceed, you must
   remove branch protection, push, and then re-enable protected branches.

1. To remove large files from tagged releases, force push your changes to all tags on GitLab:

   ```shell
   git push origin --force 'refs/tags/*'
   ```

   [Protected tags](../protected_tags.md) cause this to fail. To proceed, you must remove tag
   protection, push, and then re-enable protected tags.

1. To prevent dead links to commits that no longer exist, push the `refs/replace` created by `git filter-repo`.

   ```shell
   git push origin --force 'refs/replace/*'
   ```

   Refer to the Git [`replace`](https://git-scm.com/book/en/v2/Git-Tools-Replace) documentation for information on how this works.

1. Wait at least 30 minutes before attempting the next step.
1. Run [repository cleanup](#repository-cleanup). This process only cleans up objects
   that are more than 30 minutes old. See [Space not being freed](#space-not-being-freed)
   for more information.

## Repository cleanup

Repository cleanup allows you to upload a text file of objects and GitLab removes internal Git
references to these objects. You can use
[`git filter-repo`](https://github.com/newren/git-filter-repo) to produce a list of objects (in a
`commit-map` file) that can be used with repository cleanup.

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45058) in GitLab 13.6,
safely cleaning the repository requires it to be made read-only for the duration
of the operation. This happens automatically, but submitting the cleanup request
fails if any writes are ongoing, so cancel any outstanding `git push`
operations before continuing.

WARNING:
Removing internal Git references results in associated merge request commits, pipelines, and changes details
no longer being available.

To clean up a repository:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to **Settings > Repository**.
1. Upload a list of objects. For example, a `commit-map` file created by `git filter-repo` which is located in the
   `filter-repo` directory.

   If your `commit-map` file is larger than about 250 KB or 3000 lines, the file can be split and uploaded piece by piece:

   ```shell
   split -l 3000 filter-repo/commit-map filter-repo/commit-map-
   ```

1. Select **Start cleanup**.

This:

- Removes any internal Git references to old commits.
- Runs `git gc --prune=30.minutes.ago` against the repository to remove unreferenced objects. Repacking your repository temporarily
  causes the size of your repository to increase significantly, because the old packfiles are not removed until the
  new packfiles have been created.
- Unlinks any unused LFS objects attached to your project, freeing up storage space.
- Recalculates the size of your repository on disk.

GitLab sends an email notification with the recalculated repository size after the cleanup has completed.

If the repository size does not decrease, this may be caused by loose objects
being kept around because they were referenced in a Git operation that happened
in the last 30 minutes. Try re-running these steps after the repository has been
dormant for at least 30 minutes.

When using repository cleanup, note:

- Project statistics are cached. You may need to wait 5-10 minutes to see a reduction in storage utilization.
- The cleanup prunes loose objects older than 30 minutes. This means objects added or referenced in the last 30 minutes
  are not removed immediately. If you have access to the
  [Gitaly](../../../administration/gitaly/index.md) server, you may skip that delay and run `git gc --prune=now` to
  prune all loose objects immediately.
- This process removes some copies of the rewritten commits from the GitLab cache and database,
  but there are still numerous gaps in coverage and some of the copies may persist indefinitely.
  [Clearing the instance cache](../../../administration/raketasks/maintenance.md#clear-redis-cache)
  may help to remove some of them, but it should not be depended on for security purposes!

## Storage limits

Repository size limits:

- Can [be set by an administrator](../../../administration/settings/account_and_limit_settings.md#account-and-limit-settings).
- Can [be set by an administrator](../../../administration/settings/account_and_limit_settings.md) on self-managed instances.
- Are [set for GitLab.com](../../gitlab_com/index.md#account-and-limit-settings).

When a project has reached its size limit, you cannot:

- Push to the project.
- Create a new merge request.
- Merge existing merge requests.
- Upload LFS objects.

You can still:

- Create new issues.
- Clone the project.

If you exceed the repository size limit, you can:

1. Remove some data.
1. Make a new commit.
1. Push back to the repository.

If these actions are insufficient, you can also:

- Move some blobs to LFS.
- Remove some old dependency updates from history.

Unfortunately, this workflow doesn't work. Deleting files in a commit doesn't actually reduce the
size of the repository, because the earlier commits and blobs still exist. Instead, you must rewrite
history. We recommend the open-source community-maintained tool
[`git filter-repo`](https://github.com/newren/git-filter-repo).

NOTE:
Until `git gc` runs on the GitLab side, the "removed" commits and blobs still exist. You also
must be able to push the rewritten history to GitLab, which may be impossible if you've already
exceeded the maximum size limit.

To lift these restrictions, the Administrator of the self-managed GitLab instance must
increase the limit on the particular project that exceeded it. Therefore, it's always better to
proactively stay underneath the limit. If you hit the limit, and can't have it temporarily
increased, your only option is to:

1. Prune all the unneeded stuff locally.
1. Create a new project on GitLab and start using that instead.

## Troubleshooting

### Incorrect repository statistics shown in the GUI

If the displayed size or commit number is different from the exported `.tar.gz` or local repository,
you can ask a GitLab administrator to force an update.

Using [the rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
p = Project.find_by_full_path('<namespace>/<project>')
pp p.statistics
p.statistics.refresh!
pp p.statistics
# compare with earlier values

# An alternate method to clear project statistics
p.repository.expire_all_method_caches
UpdateProjectStatisticsWorker.perform_async(p.id, ["commit_count","repository_size","storage_size","lfs_objects_size"])

# check the total artifact storage space separately
builds_with_artifacts = p.builds.with_downloadable_artifacts.all

artifact_storage = 0
builds_with_artifacts.find_each do |build|
  artifact_storage += build.artifacts_size
end

puts "#{artifact_storage} bytes"
```

### Space not being freed

The process defined on this page can decrease the size of repository exports
decreasing, but the usage in the file system appearing unchanged in both the Web UI and terminal.

The process leaves many unreachable objects remaining in the repository.
Because they are unreachable, they are not included in the export, but they are
still stored in the file system. These files are pruned after a grace period of
two weeks. Pruning deletes these files and ensures your storage usage statistics
are accurate.

To expedite this process, see the
['Prune Unreachable Objects' housekeeping task](../../../administration/housekeeping.md).

### Sidekiq process fails to export a project

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

Occasionally the Sidekiq process can fail to export a project, for example if
it is terminated during execution.

GitLab.com users should [contact Support](https://about.gitlab.com/support/#contact-support) to resolve this issue.

Self-managed users can use the Rails console to bypass the Sidekiq process and
manually trigger the project export:

```ruby
project = Project.find(1)
current_user = User.find_by(username: 'my-user-name')
RequestStore.begin!
ActiveRecord::Base.logger = Logger.new(STDOUT)
params = {}

::Projects::ImportExport::ExportService.new(project, current_user, params).execute(nil)
```

This makes the export available through the UI, but does not trigger an email to the user.
To manually trigger the project export and send an email:

```ruby
project = Project.find(1)
current_user = User.find_by(username: 'my-user-name')
RequestStore.begin!
ActiveRecord::Base.logger = Logger.new(STDOUT)
params = {}

ProjectExportWorker.new.perform(current_user.id, project.id)
```
