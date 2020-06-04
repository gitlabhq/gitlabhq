---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: howto
---

# Reducing the repository size using Git

When large files are added to a Git repository this makes fetching the
repository slower, because everyone will need to download the file. These files
can also take up a large amount of storage space on the server over time.

Rewriting a repository can remove unwanted history to make the repository
smaller. [`git filter-repo`](https://github.com/newren/git-filter-repo) is a
tool for quickly rewriting Git repository history, and is recommended over [`git
filter-branch`](https://git-scm.com/docs/git-filter-branch) and
[BFG](https://rtyley.github.io/bfg-repo-cleaner/).

DANGER: **Danger:**
Rewriting repository history is a destructive operation. Make sure to backup
your repository before you begin. The best way is to [export the
project](../settings/import_export.html#exporting-a-project-and-its-data).

## Purging files from your repository history

To make cloning your project faster, rewrite branches and tags to remove
unwanted files.

1. [Install `git
   filter-repo`](https://github.com/newren/git-filter-repo/blob/master/INSTALL.md)
   using a supported package manager, or from source.

1. Clone a fresh copy of the repository using `--bare`.

   ```shell
   git clone --bare https://example.gitlab.com/my/project.git
   ```

1. Using `git filter-repo`, purge any files from the history of your repository.

   To purge all large files, the `--strip-blobs-bigger-than` option can be used:

   ```shell
   git filter-repo --strip-blobs-bigger-than 10M
   ```

   To purge specific large files by path, the `--path` and `--invert-paths`
   options can be combined.

   ```shell
   git filter-repo --path path/to/big/file.m4v --invert-paths
   ```

   See the [`git filter-repo`
   documentation](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#EXAMPLES)
   for more examples, and the complete documentation.

1. Force push your changes to overwrite all branches on GitLab.

   ```shell
   git push origin --force --all
   ```

   [Protected Branches](../protected_branches.md) will cause this to fail. To
   proceed you will need to remove branch protection, push, and then
   reconfigure protected branches.

1. To remove large files from tagged releases, force push your changes to all
   tags on GitLab.

   ```shell
   git push origin --force --tags
   ```

   [Protected Tags](../protected_tags.md) will cause this to
   fail. To proceed you will need to remove tag protection, push, and then
   reconfigure protected tags.

## Purging files from GitLab storage

To reduce the size of your repository in GitLab you will need to remove GitLab
internal refs that reference commits contain large files. Before completing
these steps, first [purged files from your repository
history](#purging-files-from-your-repository-history).

As well as branches and tags, which are a type of Git ref, GitLab automatically
creates other refs. These refs prevent dead links to commits, or missing diffs
when viewing merge requests. [Repository cleanup](#repository-cleanup) can be
used to remove these from GitLab.

The internal refs for merge requests (`refs/merge-requests/*`),
[pipelines](../../../ci/pipelines/index.md#troubleshooting-fatal-reference-is-not-a-tree)
(`refs/pipelines/*`), and environments (`refs/environments/*`) are not
advertised, which means they are not included when fetching, which makes
fetching faster. The hidden refs to prevent commits with discussion from being
deleted (`refs/keep-around/*`) cannot be fetched at all. These refs can,
however, be accessed from the Git bundle inside the project export.

1. [Install `git
   filter-repo`](https://github.com/newren/git-filter-repo/blob/master/INSTALL.md)
   using a supported package manager, or from source.

1. Generate a fresh [export the
   project](../settings/import_export.html#exporting-a-project-and-its-data) and
   download to your computer.

1. Decompress the backup using `tar`

   ```shell
   tar xzf project-backup.tar.gz
   ```

   This will contain a `project.bundle` file, which was created by [`git
   bundle`](https://git-scm.com/docs/git-bundle)

1. Clone a fresh copy of the repository from the bundle.

   ```shell
   git clone --bare --mirror /path/to/project.bundle
   ```

1. Using `git filter-repo`, purge any files from the history of your repository.
   Because we are trying to remove internal refs, we will rely on the
   `commit-map` produced by each run to tell us which internal refs to remove.

   NOTE:**Note:**
   `git filter-repo` creates a new `commit-map` file every run, and overwrite the
   `commit-map` from the previous run. You will need this file from **every**
   run. Do the next step every time you run `git filter-repo`.

   To purge all large files, the `--strip-blobs-bigger-than` option can be used:

   ```shell
   git filter-repo --strip-blobs-bigger-than 10M
   ```

   To purge specific large files by path, the `--path` and `--invert-paths`
   options can be combined.

   ```shell
   git filter-repo --path path/to/big/file.m4v --invert-paths
   ```

   See the [`git filter-repo`
   documentation](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#EXAMPLES)
   for more examples, and the complete documentation.

1. After running `git filter-repo`, the header and unchanged commits need to be
   removed from the `commit-map` before uploading to GitLab.

   ```shell
   tail -n +2 filter-repo/commit-map | grep -E -v '^(\w+) \1$' >> commit-map.txt
   ```

   This command can be run after each run of `git filter-repo` to append the
   output of the run to `commit-map.txt`

1. Navigate to **Project > Settings > Repository > Repository Cleanup**.

   Upload the `commit-map.txt` file and press **Start cleanup**. This will
   remove any internal Git references to the old commits, and run `git gc`
   against the repository. You will receive an email once it has completed.

## Repository cleanup

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/19376) in GitLab 11.6.

Repository cleanup allows you to upload a text file of objects and GitLab will remove
internal Git references to these objects.

To clean up a repository:

1. Go to the project for the repository.
1. Navigate to **{settings}** **Settings > Repository**.
1. Upload a list of objects.
1. Click **Start cleanup**.

This will remove any internal Git references to old commits, and run `git gc`
against the repository. You will receive an email once it has completed.

These tools produce suitable output for purging history on the server:

- [`git filter-repo`](https://github.com/newren/git-filter-repo): use the
  `commit-map` file.

- [BFG](https://rtyley.github.io/bfg-repo-cleaner/): use the
  `object-id-map.old-new.txt` file.

NOTE: **Note:**
Housekeeping prunes loose objects older than 2 weeks. This means objects added
in the last 2 weeks will not be removed immediately. If you have access to the
Gitaly server, you may run `git gc --prune=now` to prune all loose object
immediately.

NOTE: **Note:**
This process will remove some copies of the rewritten commits from GitLab's
cache and database, but there are still numerous gaps in coverage - at present,
some of the copies may persist indefinitely. [Clearing the instance
cache](../../../administration/raketasks/maintenance.md#clear-redis-cache) may
help to remove some of them, but it should not be depended on for security
purposes!

## Exceeding storage limit

A GitLab Enterprise Edition administrator can set a [repository size
limit](../../admin_area/settings/account_and_limit_settings.md) which will
prevent you from exceeding it.

When a project has reached its size limit, you will not be able to push to it,
create a new merge request, or merge existing ones. You will still be able to
create new issues, and clone the project though. Uploading LFS objects will
also be denied.

If you exceed the repository size limit, your first thought might be to remove
some data, make a new commit and push back to the repository. Perhaps you can
move some blobs to LFS, or remove some old dependency updates from history.
Unfortunately, it's not so easy and that workflow won't work. Deleting files in
a commit doesn't actually reduce the size of the repo since the earlier commits
and blobs are still around. What you need to do is rewrite history with Git's
[`filter-branch` option](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History#The-Nuclear-Option:-filter-branch),
or an open source community-maintained tool like the
[`git filter-repo`](https://github.com/newren/git-filter-repo).

Note that even with that method, until `git gc` runs on the GitLab side, the
"removed" commits and blobs will still be around. You also need to be able to
push the rewritten history to GitLab, which may be impossible if you've already
exceeded the maximum size limit.

In order to lift these restrictions, the administrator of the GitLab instance
needs to increase the limit on the particular project that exceeded it, so it's
always better to spot that you're approaching the limit and act proactively to
stay underneath it. If you hit the limit, and your admin can't - or won't -
temporarily increase it for you, your only option is to prune all the unneeded
stuff locally, and then create a new project on GitLab and start using that
instead.

CAUTION: **Caution:**
This process is not suitable for removing sensitive data like password or keys
from your repository. Information about commits, including file content, is
cached in the database, and will remain visible even after they have been
removed from the repository.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
