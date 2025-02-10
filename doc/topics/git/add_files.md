---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Add, commit, and push a file to your Git repository using the command line."
title: Add files to your branch
---

You can use Git to add files to a Git repository.

## Add files to a Git repository

To add a new file from the command line:

1. Open a terminal.
1. Change directories until you are in your project's folder.

   ```shell
   cd my-project
   ```

1. Choose a Git branch to work in.
   - To create a branch: `git checkout -b <branchname>`
   - To switch to an existing branch: `git checkout <branchname>`

1. Copy the file you want to add into the directory where you want to add it.
1. Confirm that your file is in the directory:
   - Windows: `dir`
   - All other operating systems: `ls`

   The filename should be displayed.
1. Check the status of the file:

   ```shell
   git status
   ```

   The filename should be in red. The file is in your file system, but Git isn't tracking it yet.
1. Tell Git to track the file:

   ```shell
   git add <filename>
   ```

1. Check the status of the file again:

   ```shell
   git status
   ```

   The filename should be green. The file is staged (tracked locally) by Git, but
   has not been [committed and pushed](commit.md).

## Add a file to the last commit

To add changes to a file to the last commit, instead of to a new commit, amend the existing commit:

```shell
git add <filename>
git commit --amend
```

If you do not want to edit the commit message, append `--no-edit` to the `commit` command.

## Related topics

- [Add file from the UI](../../user/project/repository/_index.md#add-a-file-from-the-ui)
- [Add file from the Web IDE](../../user/project/repository/web_editor.md#upload-a-file)
- [Sign commits](../../user/project/repository/signed_commits/gpg.md)
