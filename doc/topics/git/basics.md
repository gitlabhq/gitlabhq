---
stage: Create
group: Source Code
description: Common Git commands and workflows.
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Basic Git operations
---

Basic Git operations help you to manage your Git repositories and to make changes to your code.
They provide you with the following benefits:

- Version control: Maintain a history of your project to track changes and revert to previous versions if needed.
- Collaboration: Enable collaboration and makes it easier to share code and work simultaneously.
- Organization: Use branches and merge requests to organize and manage your work.
- Code quality: Facilitates code reviews through merge requests, and helps to maintain code quality and consistency.
- Backup and recovery: Push changes to remote repositories to ensure your work is backed up and recoverable.

To use Git operations effectively, it's important to understand key concepts such as repositories, branches,
commits, and merge requests. For more information, see [Get started learning Git](get_started.md).

To learn more about commonly used Git commands, see [Git commands](commands.md).

## Create a project

The `git push` command sends your local repository changes to a remote repository.
You can create a project from a local repository or import an existing repository.
After you add a repository, GitLab creates a project in your chosen namespace.
For more information, see [Create a project](project.md).

## Clone a repository

The `git clone` command creates a copy of a remote repository on your computer.
You can work on the code locally and push changes back to the remote repository.
For more information, see [Clone a Git repository](clone.md).

## Create a branch

The `git checkout -b <name-of-branch>` command creates a new branch in your repository.
A branch is a copy of the files in your repository that you can modify without affecting the default branch.
For more information, see [Create a branch](branch.md).

## Stage, commit, and push changes

The `git add`, `git commit`, and `git push` commands update your remote repository with your changes.
Git tracks the changes against the most recent version of the checked out branch.
For more information, see [Stage, commit, and push changes](commit.md).

## Stash changes

The `git stash` command temporarily saves changes that you don't want to commit immediately.
You can switch branches or perform other operations without committing incomplete changes.
For more information, see [Stash changes](stash.md).

## Add files to a branch

The `git add <filename>` command adds files to a Git repository or a branch.
You an add new files, modify existing files, or delete files.
For more information, see [Add files to a branch](add_files.md).

## Merge requests

A merge request is a request to merge changes from one branch into another branch.
Merge requests provide a way to collaborate and review code changes.
For more information, see [Merge requests](../../user/project/merge_requests/_index.md)
and [Merge your branch](merge.md).

## Update your fork

A fork is a personal copy of the repository and all its branches, which you create in a
namespace of your choice. You can make changes in your own fork and submit them using `git push`.
For more information, see [Update a fork](forks.md).

## Related topics

- [Get started learning Git](get_started.md)
  - [Install Git](how_to_install_git/_index.md)
  - [Common Git commands](commands.md)
- [Advanced operations](advanced.md)
- [Troubleshooting Git](troubleshooting_git.md)
- [Git cheat sheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf)
