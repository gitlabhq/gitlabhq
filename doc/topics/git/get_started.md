---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Get started learning Git

Git is a version control system you use to track changes to your code
and collaborate with others. GitLab is a web-based Git repository manager
that provides CI/CD and other features to help you manage your software development lifecycle.

To use GitLab, you don't need to know how to use Git. However, if you
use GitLab for source control, it's beneficial to understand it.

Learning Git is part of a larger workflow:

![Workflow](img/get_started_git_v16_11.png)

## Step 1: Understand repositories and working directories

A Git repository is essentially a directory that contains all the files,
folders, and version history of a project.
It serves as a central hub where you can store, manage, and share your code or content.

When you initialize a Git repository or clone an existing one, Git
creates a hidden directory called `.git` in the project directory.
This hidden directory contains all the necessary metadata and objects
that Git uses to manage the repository, including the complete history
of changes made to the files. Git tracks changes at the file level, so you can
view the modifications made to individual files over time.

To create and change code, you clone a Git repository and work in the local copy,
in your working directory. Then, to collaborate, you push your changes to a remote
Git repository, which is hosted on GitLab. Then the changes are available
to other team members. And you can pull changes made by others, so that your local repository
stays up to date.

For more information, see:

- [Repositories](../../user/project/repository/index.md)

## Step 2: Learn about branching and merging

In Git, you use branches so that you and your team can work on different features,
bug fixes, or experiments simultaneously, without interfering with each other's work.
You can then make changes, commit them, and test them in isolation without impacting
the stability of the default branch. Branches can be created, merged, and deleted.

The default branch is usually called `main` or `master`.
After a feature is complete or a bug is fixed, you can merge the changes from your branch
into the default branch. Merging combines the changes from one branch into another.

If conflicts arise during the merge process (for example, if the same lines of code have been
modified in both branches), the conflicts must be resolved manually. After a successful merge,
the branch can be deleted if it is no longer needed. Deleting the branch helps keep the repository
organized and maintainable.

For more information, see:

- [Branches](../../user/project/repository/branches/index.md)

## Step 3: Understand the Git workflow

A typical Git workflow involves the following steps:

1. Cloning a repository to your local machine.
1. Creating a new branch for your changes.
1. Making changes to files in your working directory.
1. Staging the changes you want to commit.
1. Committing the changes to your local repository.
1. Pushing the changes to the remote repository.
1. Merging your branch into the default branch.

Your organization might use a slightly different workflow,
including using forks. A fork is a personal copy of the repository
and all its branches, which you create in a namespace of your choice.
You might work on your changes in a fork before merging them to
the default branch of the source project.

For more information, see:

- [Tutorial: Make your first Git commit](../../tutorials/make_first_git_commit/index.md)
- [Forks](../../user/project/repository/forking_workflow.md)

## Step 4: Familiarize yourself with Git commands

To work with Git from the command line, you need to use various Git commands.
Some of the most commonly used commands include:

- `git clone`: Clone a repository to your local machine
- `git branch`: List, create, or delete branches
- `git checkout`: Switch between branches
- `git add`: Stage changes for commit
- `git commit`: Commit staged changes to your local repository
- `git push`: Push local commits to the remote repository
- `git pull`: Fetch changes from the remote repository and merge them into your local branch

For more information, see:

- [Command line Git](../../gitlab-basics/start-using-git.md)

## Step 5: Practice using Git

The best way to learn Git is by using it in practice. Create a test project,
experiment with different commands, and try out various workflows.
GitLab provides a web-based interface for many Git operations,
but it's also useful to understand how to use Git from the command line.
