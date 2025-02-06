---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "To remove unwanted large files from a Git repository and reduce its storage size, use the filter-repo command."
title: Reduce repository size
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The size of a Git repository can significantly impact performance and storage costs.
It can differ slightly from one instance to another due to compression, housekeeping, and other factors.

This page explains how to remove large files from your Git repository.

For more information about repository size, see:

- [Repository size](../../user/project/repository/repository_size.md)
  - [How repository size is calculated](../../user/project/repository/repository_size.md#size-calculation)
  - [Size and storage limits](../../user/project/repository/repository_size.md#size-and-storage-limits)
  - [GitLab UI methods to reduce repository size](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)

## Purge files from repository history

Use this method to remove large files from the entire Git history.

It is not suitable for removing sensitive data like passwords or keys from your repository.
Information about commits, including file content, is cached in the database, and remain visible
even after they have been removed from the repository. To remove sensitive data, use the method
described in [Remove blobs](../../user/project/repository/repository_size.md#remove-blobs).

Prerequisites:

- You must install [`git filter-repo`](https://github.com/newren/git-filter-repo/blob/main/INSTALL.md).
- Optional. Install [`git-sizer`](https://github.com/github/git-sizer#getting-started).

WARNING:
Purging files is a destructive operation. Before proceeding, ensure you have a backup of the repository.

To purge files from a GitLab repository:

1. [Export the project](../../user/project/settings/import_export.md#export-a-project-and-its-data) that contains
a copy of your repository, and download it.

   - For large projects, you can use the [Project relations export API](../../api/project_relations_export.md).

1. Decompress and extract the backup:

   ```shell
   tar xzf project-backup.tar.gz
   ```

1. Clone the repository using `--bare` and `--mirror` options:

   ```shell
   git clone --bare --mirror /path/to/project.bundle
   ```

1. Go to the `project.git` directory:

   ```shell
   cd project.git
   ```

1. Update the remote URL:

   ```shell
   git remote set-url origin https://gitlab.example.com/<namespace>/<project_name>.git
   ```

1. Analyze the repository using `git filter-repo` or `git-sizer`:

   - `git filter-repo`:

      ```shell
      git filter-repo --analyze
      head filter-repo/analysis/*-{all,deleted}-sizes.txt
      ```

   - `git-sizer`:

      ```shell
      git-sizer
      ```

1. Purge the history of your repository using one of the following `git filter-repo` options:

   - `--path` and `--invert-paths` to purge specific files:

     ```shell
     git filter-repo --path path/to/file.ext --invert-paths
     ```

   - `--strip-blobs-bigger-than` to purge all files larger than for example 10M:

     ```shell
     git filter-repo --strip-blobs-bigger-than 10M
     ```

   For more examples, see the
   [`git filter-repo` documentation](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#EXAMPLES).

1. Back up the `commit-map`:

   ```shell
   cp filter-repo/commit-map ./_filter_repo_commit_map_$(date +%s)
   ```

1. Unset the mirror flag:

   ```shell
    git config --unset remote.origin.mirror
   ```

1. Force push the changes:

   ```shell
   git push origin --force 'refs/heads/*'
   git push origin --force 'refs/tags/*'
   git push origin --force 'refs/replace/*'
   ```

   For more information about references, see
   [Git references used by Gitaly](../../development/gitaly.md#git-references-used-by-gitaly).

   NOTE:
   This step fails for [protected branches](../../user/project/repository/branches/protected.md) and
   [protected tags](../../user/project/protected_tags.md). To proceed, temporarily remove protections.

1. Wait at least 30 minutes before the next step.
1. Run the [clean up repository](../../user/project/repository/repository_size.md#clean-up-repository) process.
   This process only cleans up objects that are more than 30 minutes old.
   For more information, see [space not being freed after cleanup](../../user/project/repository/repository_size.md#space-not-being-freed-after-cleanup).
