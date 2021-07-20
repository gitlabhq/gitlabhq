---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto, tutorial
description: "Introduction to using Git through the command line."
---

# Start using Git on the command line **(FREE)**

[Git](https://git-scm.com/) is an open-source distributed version control system. GitLab is built
on top of Git.

You can do many Git operations directly in GitLab. However, the command line is required for advanced tasks,
like fixing complex merge conflicts or rolling back commits.

For a quick reference of Git commands, download a [Git Cheat Sheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf).

For more information about the advantages of working with Git and GitLab:

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>&nbsp;Watch the [GitLab Source Code Management Walkthrough](https://www.youtube.com/watch?v=wTQ3aXJswtM) video.
- Learn how [GitLab became the backbone of the Worldline](https://about.gitlab.com/customers/worldline/) development environment.

To help you visualize what you're doing locally, you can install a
[Git GUI app](https://git-scm.com/download/gui/).

## Git terminology

If you're familiar with Git terminology, you might want to skip this section and
go directly to [prerequisites](#prerequisites).

### Repository

In GitLab, files are stored in a **repository**. A repository is similar to how you
store files in a folder or directory on your computer.

- A **remote repository** refers to the files in GitLab.
- A **local copy** refers to the files on your computer.

<!-- vale gitlab.Spelling = NO -->
<!-- vale gitlab.SubstitutionWarning = NO -->
Often, the word "repository" is shortened to "repo".
<!-- vale gitlab.Spelling = YES -->
<!-- vale gitlab.SubstitutionWarning = YES -->

In GitLab, a repository is contained in a **project**.

### Fork

When you want to contribute to someone else's repository, you make a copy of it.
This copy is called a [**fork**](../user/project/repository/forking_workflow.md#creating-a-fork).
The process is called "creating a fork."

When you fork a repo, you create a copy of the project in your own
[namespace](../user/group/#namespaces). You then have write permissions to modify the project files
and settings.

For example, you can fork this project, <https://gitlab.com/gitlab-tests/sample-project/>, into your namespace.
You now have your own copy of the repository. You can view the namespace in the URL, for example
`https://gitlab.com/your-namespace/sample-project/`.
Then you can clone the repository to your local machine, work on the files, and submit changes back to the
original repository.

### Difference between download and clone

To create a copy of a remote repository's files on your computer, you can either
**download** or **clone** the repository. If you download it, you cannot sync the repository with the
remote repository on GitLab.

[Cloning](#clone-a-repository) a repository is the same as downloading, except it preserves the Git connection
with the remote repository. You can then modify the files locally and
upload the changes to the remote repository on GitLab.

### Pull and push

After you save a local copy of a repository and modify the files on your computer, you can upload the
changes to GitLab. This is referred to as **pushing** to the remote, because you use the command
[`git push`](#send-changes-to-gitlabcom).

When the remote repository changes, your local copy is behind. You can update your local copy with the new
changes in the remote repository.
This is referred to as **pulling** from the remote, because you use the command
[`git pull`](#download-the-latest-changes-in-the-project).

## Prerequisites

To start using GitLab with Git, complete the following tasks:

- Create and sign in to a GitLab account.
- [Open a terminal](#open-a-terminal).
- [Install Git](#install-git) on your computer.
- [Configure Git](#configure-git).
- [Choose a repository](#choose-a-repository).

### Open a terminal

To execute Git commands on your computer, you must open a terminal (also known as command
prompt, command shell, and command line). Here are some options:

- For macOS users:
  - Built-in [Terminal](https://blog.teamtreehouse.com/introduction-to-the-mac-os-x-command-line). Press <kbd>⌘ command</kbd> + <kbd>space</kbd> and type `terminal`.
  - [iTerm2](https://iterm2.com/). You can integrate it with [zsh](https://git-scm.com/book/id/v2/Appendix-A%3A-Git-in-Other-Environments-Git-in-Zsh) and [oh my zsh](https://ohmyz.sh/) for color highlighting and other advanced features.
- For Windows users:
  - Built-in command line. On the Windows taskbar, select the search icon and type `cmd`.
  - [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-7).
  - Git Bash. It is built into [Git for Windows](https://gitforwindows.org/).
- For Linux users:
  - Built-in [Linux Terminal](https://ubuntu.com/tutorials/command-line-for-beginners#3-opening-a-terminal).

### Install Git

Determine if Git is already installed on your computer by opening a terminal
and running this command:

```shell
git --version
```

If Git is installed, the output is:

```shell
git version X.Y.Z
```

If your computer doesn't recognize `git` as a command, you must [install Git](../topics/git/how_to_install_git/index.md).
After you install Git, run `git --version` to confirm that it installed correctly.

### Configure Git

To start using Git from your computer, you must enter your credentials
to identify yourself as the author of your work. The username and email address
should match the ones you use in GitLab.

1. In your shell, add your user name:

   ```shell
   git config --global user.name "your_username"
   ```

1. Add your email address:

   ```shell
   git config --global user.email "your_email_address@example.com"
   ```

1. To check the configuration, run:

   ```shell
   git config --global --list
   ```

   The `--global` option tells Git to always use this information for anything you do on your system.
   If you omit `--global` or use `--local`, the configuration applies only to the current
   repository.

You can read more on how Git manages configurations in the
[Git configuration documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration).

### Choose a repository

Before you begin, choose the repository you want to work in. You can use any project you have permission to
access on GitLab.com or any other GitLab instance.

To use the repository in the examples on this page:

1. Go to [https://gitlab.com/gitlab-tests/sample-project/](https://gitlab.com/gitlab-tests/sample-project/).
1. In the top right, select **Fork**.
1. Choose a namespace for your fork.

The project becomes available at `https://gitlab.com/<your-namespace>/sample-project/`.

You can [fork](../user/project/repository/forking_workflow.md#creating-a-fork) any project you have access to.

## Clone a repository

When you clone a repository, the files from the remote repository are downloaded to your computer,
and a connection is created.

This connection requires you to add credentials. You can either use SSH or HTTPS. SSH is recommended.

### Clone with SSH

Clone with SSH when you want to authenticate only one time.

1. Authenticate with GitLab by following the instructions in the [SSH documentation](../ssh/index.md).
1. Go to your project's landing page and select **Clone**. Copy the URL for **Clone with SSH**.
1. Open a terminal and go to the directory where you want to clone the files. Git automatically creates a folder with the repository name and downloads the files there.
1. Run this command:

   ```shell
   git clone git@gitlab.com:gitlab-tests/sample-project.git
   ```

1. To view the files, go to the new directory:

   ```shell
   cd sample-project
   ```

You can also
[clone a repository and open it directly in Visual Studio Code](../user/project/repository/index.md#clone-and-open-in-visual-studio-code).

### Clone with HTTPS

Clone with HTTPS when you want to authenticate each time you perform an operation
between your computer and GitLab.

1. Go to your project's landing page and select **Clone**. Copy the URL for **Clone with HTTPS**.
1. Open a terminal and go to the directory where you want to clone the files.
1. Run the following command. Git automatically creates a folder with the repository name and downloads the files there.

   ```shell
   git clone https://gitlab.com/gitlab-tests/sample-project.git
   ```

1. GitLab requests your username and password:
   - If you have 2FA enabled for your account, you must use a [Personal Access Token](../user/profile/personal_access_tokens.md)
     with **read_repository** or **write_repository** permissions instead of your account's password.
   - If you don't have 2FA enabled, use your account's password.

1. To view the files, go to the new directory:

   ```shell
   cd sample-project
   ```

NOTE:
On Windows, if you enter your password incorrectly multiple times and an `Access denied` message appears,
add your namespace (username or group) to the path:
`git clone https://namespace@gitlab.com/gitlab-org/gitlab.git`.

### Convert a local directory into a repository

You can initialize a local folder so Git tracks it as a repository.

1. Open the terminal in the directory you'd like to convert.
1. Run this command:

   ```shell
   git init
   ```

   A `.git` folder is created in your directory. This folder contains Git
   records and configuration files. You should not edit these files
   directly.

1. Add the [path to your remote repository](#add-a-remote)
   so Git can upload your files into the correct project.

#### Add a remote

You add a "remote" to tell Git which remote repository in GitLab is tied
to the specific local folder on your computer.
The remote tells Git where to push or pull from.

To add a remote to your local copy:

1. In GitLab, [create a project](../user/project/working_with_projects.md#create-a-project) to hold your files.
1. Visit this project's homepage, scroll down to **Push an existing folder**, and copy the command that starts with `git remote add`.
1. On your computer, open the terminal in the directory you've initialized, paste the command you copied, and press <kbd>enter</kbd>:

   ```shell
   git remote add origin git@gitlab.com:username/projectpath.git
   ```

After you've done that, you can [stage your files](#add-and-commit-local-changes) and [upload them to GitLab](#send-changes-to-gitlabcom).

#### View your remote repositories

To view your remote repositories, type:

```shell
git remote -v
```

The `-v` flag stands for verbose.

### Download the latest changes in the project

To work on an up-to-date copy of the project, you `pull` to get all the changes made by users
since the last time you cloned or pulled the project. Replace `<name-of-branch>`
with the name of your [default branch](../user/project/repository/branches/default.md)
to get the main branch code, or replace it with the branch name of the branch
you are currently working in.

```shell
git pull <REMOTE> <name-of-branch>
```

When you clone a repository, `REMOTE` is typically `origin`. This is where the
repository was cloned from, and it indicates the SSH or HTTPS URL of the repository
on the remote server. `<name-of-branch>` is usually the name of your
[default branch](../user/project/repository/branches/default.md), but it may be any
existing branch. You can create additional named remotes and branches as necessary.

You can learn more on how Git manages remote repositories in the
[Git Remote documentation](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes).

## Branches

A **branch** is a copy of the files in the repository at the time you create the branch.
You can work in your branch without affecting other branches. When
you're ready to add your changes to the main codebase, you can merge your branch into
the default branch, for example, `main`.

Use branches when you:

- Want to add code to a project but you're not sure if it works properly.
- Are collaborating on the project with others, and don't want your work to get mixed up.

A new branch is often called **feature branch** to differentiate from the
[default branch](../user/project/repository/branches/default.md).

### Create a branch

To create a feature branch:

```shell
git checkout -b <name-of-branch>
```

Branch names cannot contain empty spaces and special characters. Use only lowercase letters, numbers,
hyphens (`-`), and underscores (`_`).

### Switch to a branch

All work in Git is done in a branch.
You can switch between branches to see the state of the files and work in that branch.

To switch to an existing branch:

```shell
git checkout <name-of-branch>
```

For example, to change to the `main` branch:

```shell
git checkout main
```

### View differences

To view the differences between your local unstaged changes and the latest version
that you cloned or pulled:

```shell
git diff
```

### View the files that have changes

When you add, change, or delete files or folders, Git knows about the changes.
To check which files have been changed:

```shell
git status
```

### Add and commit local changes

When you type `git status`, locally changed files are shown in red. These changes may
be new, modified, or deleted files or folders.

1. To stage a file for commit:

   ```shell
   git add <file-name OR folder-name>
   ```

1. Repeat step 1 for each file or folder you want to add.
   Or, to stage all files in the current directory and subdirectory, type `git add .`.

1. Confirm that the files have been added to staging:

   ```shell
   git status
   ```

   The files should be displayed in green text.

1. To commit the staged files:

   ```shell
   git commit -m "COMMENT TO DESCRIBE THE INTENTION OF THE COMMIT"
   ```

#### Stage and commit all changes

As a shortcut, you can add all local changes to staging and commit them with one command:

```shell
git commit -a -m "COMMENT TO DESCRIBE THE INTENTION OF THE COMMIT"
```

### Send changes to GitLab.com

To push all local changes to the remote repository:

```shell
git push <remote> <name-of-branch>
```

For example, to push your local commits to the `main` branch of the `origin` remote:

```shell
git push origin main
```

Sometimes Git does not allow you to push to a repository. Instead,
you must [force an update](../topics/git/git_rebase.md#force-push).

### Delete all changes in the branch

To discard all changes to tracked files:

```shell
git checkout .
```

This action removes *changes* to files, not the files themselves.
Untracked (new) files do not change.

### Unstage all changes that have been added to the staging area

To unstage (remove) all files that have not been committed:

```shell
git reset
```

### Undo most recent commit

To undo the most recent commit:

```shell
git reset HEAD~1
```

This action leaves the changed files and folders unstaged in your local repository.

WARNING:
A Git commit should not be reversed if you already pushed it
to the remote repository. Although you can undo a commit, the best option is to avoid
the situation altogether by working carefully.

You can learn more about the different ways Git can undo changes in the
[Git Undoing Things documentation](https://git-scm.com/book/en/v2/Git-Basics-Undoing-Things).

### Merge a branch with default branch

When you are ready to add your changes to
the default branch, you `merge` the two together:

```shell
git checkout <feature-branch>
git merge <default-branch>
```

In GitLab, you typically use a [merge request](../user/project/merge_requests/) to merge your changes, instead of using the command line.

To create a merge request from a fork to an upstream repository, see the
[forking workflow](../user/project/repository/forking_workflow.md).

## Advanced use of Git through the command line

For an introduction of more advanced Git techniques, see [Git rebase, force-push, and merge conflicts](../topics/git/git_rebase.md).

## Synchronize changes in a forked repository with the upstream

To create a copy of a repository in your namespace, you [fork it](../user/project/repository/forking_workflow.md).
Changes made to your copy of the repository are not automatically synchronized with the original.
To keep the project in sync with the original project, you need to `pull` from the original repository.

You must [create a link to the remote repository](#add-a-remote) to pull
changes from the original repository. It is common to call this remote repository the `upstream`.

You can now use the `upstream` as a [`<remote>` to `pull` new updates](#download-the-latest-changes-in-the-project)
from the original repository, and use the `origin`
to [push local changes](#send-changes-to-gitlabcom) and create merge requests.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
