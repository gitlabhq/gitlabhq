---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: howto
---

# Reduce repository size

Git repositories become larger over time. When large files are added to a Git repository:

- Fetching the repository becomes slower because everyone must download the files.
- They take up a large amount of storage space on the server.
- Git repository storage limits [can be reached](#storage-limits).

Rewriting a repository can remove unwanted history to make the repository smaller.
[`git filter-repo`](https://github.com/newren/git-filter-repo) is a tool for quickly rewriting Git
repository history, and is recommended over both:

- [`git filter-branch`](https://git-scm.com/docs/git-filter-branch).
- [BFG](https://rtyley.github.io/bfg-repo-cleaner/).

DANGER: **Danger:**
Rewriting repository history is a destructive operation. Make sure to backup your repository before
you begin. The best way back up a repository is to
[export the project](../settings/import_export.md#exporting-a-project-and-its-data).

NOTE: **Note:**
Git LFS files can only be removed by an Administrator using a
[Rake task](../../../raketasks/cleanup.md). Removal of this limitation
[is planned](https://gitlab.com/gitlab-org/gitlab/-/issues/223621).

## Purge files from repository history

To make cloning your project faster, rewrite branches and tags to remove unwanted files.

1. [Install `git filter-repo`](https://github.com/newren/git-filter-repo/blob/main/INSTALL.md)
   using a supported package manager or from source.

1. Clone a fresh copy of the repository using `--bare`:

   ```shell
   git clone --bare https://example.gitlab.com/my/project.git
   ```

1. Using `git filter-repo`, purge any files from the history of your repository.

   To purge large files, the `--strip-blobs-bigger-than` option can be used:

   ```shell
   git filter-repo --strip-blobs-bigger-than 10M
   ```

   To purge large files stored using Git LFS, the `--blob--callback` option can
   be used. The example below, uses the callback to read the file size from the
   Git LFS pointer, and removes files larger than 10MB.

   ```shell
   git filter-repo --blob-callback '
     if blob.data.startswith(b"version https://git-lfs.github.com/spec/v1"):
       size_in_bytes = int.from_bytes(blob.data[124:], byteorder="big")
       if size_in_bytes > 10*1000:
         blob.skip()
     '
   ```

   To purge specific large files by path, the `--path` and `--invert-paths` options can be combined:

   ```shell
   git filter-repo --path path/to/big/file.m4v --invert-paths
   ```

   See the
   [`git filter-repo` documentation](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#EXAMPLES)
   for more examples and the complete documentation.

1. Running `git filter-repo` removes all remotes. To restore the remote for your project, run:

   ```shell
   git remote add origin https://example.gitlab.com/<namespace>/<project_name>.git
   ```

1. Force push your changes to overwrite all branches on GitLab:

   ```shell
   git push origin --force --all
   ```

   [Protected branches](../protected_branches.md) will cause this to fail. To proceed, you must
   remove branch protection, push, and then re-enable protected branches.

1. To remove large files from tagged releases, force push your changes to all tags on GitLab:

   ```shell
   git push origin --force --tags
   ```

   [Protected tags](../protected_tags.md) will cause this to fail. To proceed, you must remove tag
   protection, push, and then re-enable protected tags.

1. Manually run [project housekeeping](../../../administration/housekeeping.md#manual-housekeeping)

NOTE: **Note**
Project statistics are cached for performance. You may need to wait 5-10 minutes
to see a reduction in storage utilization.

## Purge files from GitLab storage

To reduce the size of your repository in GitLab, you must remove GitLab internal references to
commits that contain large files. Before completing these steps,
[purge files from your repository history](#purge-files-from-repository-history).

As well as [branches](branches/index.md) and tags, which are a type of Git ref, GitLab automatically
creates other refs. These refs prevent dead links to commits, or missing diffs when viewing merge
requests. [Repository cleanup](#repository-cleanup) can be used to remove these from GitLab.

The following internal refs are not advertised:

- `refs/merge-requests/*` for merge requests.
- `refs/pipelines/*` for
  [pipelines](../../../ci/pipelines/index.md#troubleshooting-fatal-reference-is-not-a-tree).
- `refs/environments/*` for environments.

This means they are not usually included when fetching, which makes fetching faster. In addition,
`refs/keep-around/*` are hidden refs to prevent commits with discussion from being deleted and
cannot be fetched at all.

However, these refs can be accessed from the Git bundle inside a project export.

1. [Install `git filter-repo`](https://github.com/newren/git-filter-repo/blob/main/INSTALL.md)
   using a supported package manager or from source.

1. Generate a fresh [export from the
   project](../settings/import_export.html#exporting-a-project-and-its-data) and download it.

1. Decompress the backup using `tar`:

   ```shell
   tar xzf project-backup.tar.gz
   ```

   This will contain a `project.bundle` file, which was created by
   [`git bundle`](https://git-scm.com/docs/git-bundle).

1. Clone a fresh copy of the repository from the bundle:

   ```shell
   git clone --bare --mirror /path/to/project.bundle
   ```

1. Using `git filter-repo`, purge any files from the history of your repository. Because we are
   trying to remove internal refs, we will rely on the `commit-map` produced by each run to tell us
   which internal refs to remove.

   NOTE: **Note:**
   `git filter-repo` creates a new `commit-map` file every run, and overwrite the `commit-map` from
   the previous run. You will need this file from **every** run. Do the next step every time you run
   `git filter-repo`.

   To purge all large files, the `--strip-blobs-bigger-than` option can be used:

   ```shell
   git filter-repo --strip-blobs-bigger-than 10M
   ```

   To purge specific large files by path, the `--path` and `--invert-paths` options can be combined.

   ```shell
   git filter-repo --path path/to/big/file.m4v --invert-paths
   ```

   See the
   [`git filter-repo` documentation](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#EXAMPLES)
   for more examples and the complete documentation.

1. Run a [repository cleanup](#repository-cleanup).

## Repository cleanup

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/19376) in GitLab 11.6.

Repository cleanup allows you to upload a text file of objects and GitLab will remove internal Git
references to these objects. You can use
[`git filter-repo`](https://github.com/newren/git-filter-repo) to produce a list of objects (in a
`commit-map` file) that can be used with repository cleanup.

To clean up a repository:

1. Go to the project for the repository.
1. Navigate to **{settings}** **Settings > Repository**.
1. Upload a list of objects. For example, a `commit-map` file.
1. Click **Start cleanup**.

This will:

- Remove any internal Git references to old commits.
- Run `git gc` against the repository.

You will receive an email once it has completed.

When using repository cleanup, note:

- Project statistics are cached. You may need to wait 5-10 minutes to see a reduction in storage utilization.
- Housekeeping prunes loose objects older than 2 weeks. This means objects added in the last 2 weeks
  will not be removed immediately. If you have access to the
  [Gitaly](../../../administration/gitaly/index.md) server, you may run `git gc --prune=now` to
  prune all loose objects immediately.
- This process will remove some copies of the rewritten commits from GitLab's cache and database,
  but there are still numerous gaps in coverage and some of the copies may persist indefinitely.
  [Clearing the instance cache](../../../administration/raketasks/maintenance.md#clear-redis-cache)
  may help to remove some of them, but it should not be depended on for security purposes!

## Storage limits

Repository size limits:

- Can [be set by an administrator](../../admin_area/settings/account_and_limit_settings.md#repository-size-limit-starter-only)
  on self-managed instances. **(STARTER ONLY)**
- Are [set for GitLab.com](../../gitlab_com/index.md#repository-size-limit).

When a project has reached its size limit, you cannot:

- Push to the project.
- Create a new merge request.
- Merge existing merge requests.
- Upload LFS objects.

You can still:

- Create new issues.
- Clone the project.

If you exceed the repository size limit, you might try to:

1. Remove some data.
1. Make a new commit.
1. Push back to the repository.

Perhaps you might also:

- Move some blobs to LFS.
- Remove some old dependency updates from history.

Unfortunately, this workflow won't work. Deleting files in a commit doesn't actually reduce the size
of the repository because the earlier commits and blobs still exist.

What you need to do is rewrite history. We recommend the open-source community-maintained tool
[`git filter-repo`](https://github.com/newren/git-filter-repo).

NOTE: **Note:**
Until `git gc` runs on the GitLab side, the "removed" commits and blobs will still exist. You also
must be able to push the rewritten history to GitLab, which may be impossible if you've already
exceeded the maximum size limit.

In order to lift these restrictions, the administrator of the self-managed GitLab instance must
increase the limit on the particular project that exceeded it. Therefore, it's always better to
proactively stay underneath the limit. If you hit the limit, and can't have it temporarily
increased, your only option is to:

1. Prune all the unneeded stuff locally.
1. Create a new project on GitLab and start using that instead.

CAUTION: **Caution:**
This process is not suitable for removing sensitive data like password or keys from your repository.
Information about commits, including file content, is cached in the database, and will remain
visible even after they have been removed from the repository.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
