---
type: tutorial, concepts
description: "How to migrate an existing Git repository to Git LFS with BFG."
last_updated: 2019-07-11
---

# Migrate a Git repo into Git LFS with BFG

Using Git LFS can help you to reduce the size of your Git
repository and improve its performance.

However, simply adding the
large files that are already in your repository to Git LFS,
will not actually reduce the size of your repository because
the files are still referenced by previous commits.

Through the method described on this document, first migrate
to Git LFS with [BFG](https://rtyley.github.io/bfg-repo-cleaner/)
through a mirror repo, then clean up the repository's history,
and lastly create LFS tracking rules to prevent new binary files
from being added.

This tutorial was inspired by the guide
[Use BFG to migrate a repo to Git LFS](https://confluence.atlassian.com/bitbucket/use-bfg-to-migrate-a-repo-to-git-lfs-834233484.html).
For more information on Git LFS, see the [references](#references)
below.

CAUTION: **Warning:**
The method described on this guide rewrites Git history. Make
sure to back up your repo before beginning and use it at your
own risk.

## Requirements

Before beginning, make sure:

- You have enough LFS storage for the files you want to convert.
  Storage is required for the entire history of all files.
- All the team members you share the repository with have pushed all changes.
  Branches based on the repository before applying this method cannot be merged.
  Branches based on the repo before applying this method cannot be merged.

To follow this tutorial, you'll need:

- Maintainer permissions to the existing Git repository
  you'd like to migrate to LFS with access through the command line.
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  and [Java Runtime Environment](https://www.java.com/en/download/manual.jsp)
  (Java 7 or above) installed locally.
- BFG installed locally:

   ```bash
   brew install bfg
   ```

- Git LFS installed locally:

   ```bash
   brew install git-lfs
   ```

NOTE: **Note:**
This guide was tested on macOS Mojave.

## Steps

Consider an example upstream project, `git@gitlab.com:gitlab-tests/test-git-lfs-repo-migration.git`.

1. Back up your repository:

   Create a copy of your repository so that you can
   recover it in case something goes wrong.

1. Clone `--mirror` the repo:

   Cloning with the mirror flag will create a bare repository.
   This ensures you get all the branches within the repo.

   It creates a directory called `<repo-name>.git`
   (in our example, `test-git-lfs-repo-migration.git`),
   mirroring the upstream project:

   ```bash
   git clone --mirror git@gitlab.com:gitlab-tests/test-git-lfs-repo-migration.git
   ```

1. Convert the Git history with BFG:

   ```bash
   bfg --convert-to-git-lfs "*.{png,mp4,jpg,gif}" --no-blob-protection test-git-lfs-repo-migration.git
   ```

   It is scanning all the history, and looking for any files with
   that extension, and then converting them to an LFS pointer.

1. Clean up the repository:

   ```bash
   # cd path/to/mirror/repo:
   cd test-git-lfs-repo-migration.git
   # clean up the repo:
   git reflog expire --expire=now --all && git gc --prune=now --aggressive
   ```

   You can also take a look on how to further [clean the repo](../../../user/project/repository/reducing_the_repo_size_using_git.md),
   but it's not necessary for the purposes of this guide.

1. Install Git LFS in the mirror repository:

   ```bash
   git lfs install
   ```

1. [Unprotect the default branch](../../../user/project/protected_branches.md),
   so that we can force-push the rewritten repository:

   1. Navigate to your project's **Settings > Repository** and
   expand **Protected Branches**.
   1. Scroll down to locate the protected branches and click
   **Unprotect** the default branch.

1. Force-push to GitLab:

   ```bash
   git push --force
   ```

1. Track the files you want with LFS:

   ```bash
   # cd path/to/upstream/repo:
   cd test-git-lfs-repo-migration
   # You may need to reset your local copy with upstream's `master` after force-pushing from the mirror:
   git reset --hard origin/master
   # Track the files with LFS:
   git lfs track "*.gif" "*.png" "*.jpg" "*.psd" "*.mp4" ".gitattributes" "img/"
   ```

   Now all existing the files you converted, as well as the new
   ones you add, will be properly tracked with LFS.

1. [Re-protect the default branch](../../../user/project/protected_branches.md):

   1. Navigate to your project's **Settings > Repository** and
   expand **Protected Branches**.
   1. Select the default branch from the **Branch** dropdown menu,
   and set up the
   **Allowed to push** and **Allowed to merge** rules.
   1. Click **Protect**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

## References

- [Getting Started with Git LFS](https://about.gitlab.com/2017/01/30/getting-started-with-git-lfs-tutorial/)
- [Migrate from Git Annex to Git LFS](../../../workflow/lfs/migrate_from_git_annex_to_git_lfs.md)
- [GitLab's Git LFS user documentation](../../../workflow/lfs/manage_large_binaries_with_git_lfs.md)
- [GitLab's Git LFS administrator documentation](../../../workflow/lfs/lfs_administration.md)
- Alternative method to [migrate an existing repo to Git LFS](https://github.com/git-lfs/git-lfs/wiki/Tutorial#migrating-existing-repository-data-to-lfs)

<!--
Test project:
https://gitlab.com/gitlab-tests/test-git-lfs-repo-migration
-->
