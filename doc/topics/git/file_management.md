---
stage: Create
group: Source Code
description: Common commands and workflows.
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: File management
---

Git provides file management capabilities that help you to track changes,
collaborate with others, and manage large files efficiently.

## File history

Use `git log` to view a file's complete history and understand how it has changed over time.
The file history shows you:

- The author of each change.
- The date and time of each modification.
- The specific changes made in each commit.

For example, to view `history` information about the `CONTRIBUTING.md` file in the root
of the `gitlab` repository, run:

```shell
git log CONTRIBUTING.md
```

Example output:

```shell
commit b350bf041666964c27834885e4590d90ad0bfe90
Author: Nick Malcolm <nmalcolm@gitlab.com>
Date:   Fri Dec 8 13:43:07 2023 +1300

    Update security contact and vulnerability disclosure info

commit 8e4c7f26317ff4689610bf9d031b4931aef54086
Author: Brett Walker <bwalker@gitlab.com>
Date:   Fri Oct 20 17:53:25 2023 +0000

    Fix link to Code of Conduct

    and condense some of the verbiage
```

## Check previous changes to a file

Use `git blame` to see who made the last change to a file and when.
This helps to understand the context of a file's content,
resolve conflicts, and identify the person responsible for a specific change.

If you want to find `blame` information about a `README.md` file in the local directory:

1. Open a terminal or command prompt.
1. Go to your Git repository.
1. Run the following command:

   ```shell
   git blame README.md
   ```

1. To navigate the results page, press <kbd>Space</kbd>.
1. To exit out of the results, press <kbd>Q</kbd>.

This output displays the file content with annotations showing the commit SHA, author,
and date for each line. For example:

```shell
58233c4f1054c (Dan Rhodes           2022-05-13 07:02:20 +0000  1) ## Contributor License Agreement
b87768f435185 (Jamie Hurewitz       2017-10-31 18:09:23 +0000  2)
8e4c7f26317ff (Brett Walker         2023-10-20 17:53:25 +0000  3) Contributions to this repository are subject to the
58233c4f1054c (Dan Rhodes           2022-05-13 07:02:20 +0000  4)
```

## Git LFS

Git Large File Storage (LFS) is an extension that helps you manage large files in Git repositories.
It replaces large files with text pointers in Git, and stores the file contents on a remote server.

Prerequisites:

- Download and install the appropriate version of the [CLI extension for Git LFS](https://git-lfs.com) for your operating system.
- [Configure your project to use Git LFS](lfs/_index.md).
- Install the Git LFS pre-push hook. To do this, run `git lfs install` in the root directory of your repository.

### Add and track files

To add a large file into your Git repository and track it with Git LFS:

1. Configure tracking for all files of a certain type. Replace `iso` with your desired file type:

   ```shell
   git lfs track "*.iso"
   ```

   This command creates a `.gitattributes` file with instructions to handle all
   ISO files with Git LFS. The following line is added to your `.gitattributes` file:

   ```plaintext
   *.iso filter=lfs -text
   ```

1. Add a file of that type, `.iso`, to your repository.
1. Track the changes to both the `.gitattributes` file and the `.iso` file:

   ```shell
   git add .
   ```

1. Ensure you've added both files:

   ```shell
   git status
   ```

   The `.gitattributes` file must be included in your commit.
   It if isn't included, Git does not track the ISO file with Git LFS.

   NOTE:
   Ensure the files you're changing are not listed in a `.gitignore` file.
   If they are, Git commits the change locally but doesn't push it to your upstream repository.

1. Commit both files to your local copy of the repository:

   ```shell
   git commit -m "Add an ISO file and .gitattributes"
   ```

1. Push your changes upstream. Replace `main` with the name of your branch:

   ```shell
   git push origin main
   ```

1. Create a merge request.

NOTE:
When you add a new file type to Git LFS tracking, existing files of this type
are not converted to Git LFS. Only files of this type, added after you begin tracking, are added to Git LFS. Use `git lfs migrate` to convert existing files to use Git LFS.

### Stop tracking a file

When you stop tracking a file with Git LFS, the file remains on disk because it's still
part of your repository's history.

To stop tracking a file with Git LFS:

1. Run the `git lfs untrack` command and provide the path to the file:

   ```shell
   git lfs untrack doc/example.iso
   ```

1. Use the `touch` command to convert it back to a standard file:

   ```shell
   touch doc/example.iso
   ```

1. Track the changes to the file:

   ```shell
   git add .
   ```

1. Commit and push your changes.
1. Create a merge request and request a review.
1. Merge the request into the target branch.

NOTE:
If you delete an object tracked by Git LFS, without tracking it with `git lfs untrack`,
the object shows as `modified` in `git status`.

### Stop tracking all files of a single type

To stop tracking all files of a particular type in Git LFS:

1. Run the `git lfs untrack` command and provide the file type to stop tracking:

   ```shell
   git lfs untrack "*.iso"
   ```

1. Use the `touch` command to convert the files back to standard files:

   ```shell
   touch *.iso
   ```

1. Track the changes to the files:

   ```shell
   git add .
   ```

1. Commit and push your changes.
1. Create a merge request and request a review.
1. Merge the request into the target branch.

## File locks

File locks help prevent conflicts and ensure that only one person can edit a file at a time.
It's a good option for:

- Binary files that can't be merged. For example, design files and videos.
- Files that require exclusive access during editing.

Prerequisites:

- You must have [Git LFS installed](../git/lfs/_index.md).
- You must have the Maintainer role for the project.

### Configure file locks

To configure file locks for a specific file type:

1. Use the `git lfs track` command with the `--lockable` option. For example, to configure PNG files:

   ```shell
   git lfs track "*.png" --lockable
   ```

   This command creates or updates your `.gitattributes` file with the following content:

    ```plaintext
    *.png filter=lfs diff=lfs merge=lfs -text lockable
    ```

1. Push the `.gitattributes` file to the remote repository for the changes to take effect.

   NOTE:
   After a file type is registered as lockable, it is automatically marked as read-only.

#### Configure file locks without LFS

To register a file type as lockable without using Git LFS:

1. Edit the `.gitattributes` file manually:

   ```shell
   *.pdf lockable
   ```

1. Push the `.gitattributes` file to the remote repository.

### Lock and unlock files

To lock or unlock a file with exclusive file locking:

1. Open a terminal window in your repository directory.
1. Run one of the following commands:

   ::Tabs

   :::TabTitle Lock a file

   ```shell
   git lfs lock path/to/file.png
   ```

   :::TabTitle Unlock a file

   ```shell
   git lfs unlock path/to/file.png
   ```

   :::TabTitle Unlock a file by ID

   ```shell
   git lfs unlock --id=123
   ```

   :::TabTitle Force unlock a file

   ```shell
   git lfs unlock --id=123 --force
   ```

   ::EndTabs

### View locked files

To view locked files:

1. Open a terminal window in your repository.
1. Run the following command:

   ```shell
   git lfs locks
   ```

   The output lists the locked files, the users who locked them, and the file IDs.

In the GitLab UI:

- The repository file tree displays an LFS badge for files tracked by Git LFS.
- Exclusively-locked files show a padlock icon.
LFS-Locked files

You can also [view and remove existing locks](../../user/project/file_lock.md) from the GitLab UI.

NOTE:
When you rename an exclusively-locked file, the lock is lost. You must lock it again to keep it locked.

### Lock and edit a file

To lock a file, edit it, and optionally unlock it:

1. Lock the file:

   ```shell
   git lfs lock <file_path>
   ```

1. Edit the file.
1. Optional. Unlock the file when you're done:

   ```shell
   git lfs unlock <file_path>
   ```

## Related topics

- [File management with the GitLab UI](../../user/project/repository/files/_index.md)
- [Git Large File Storage (LFS) documentation](lfs/_index.md)
- [File locking](../../user/project/file_lock.md)
