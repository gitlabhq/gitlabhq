---
type: howto, tutorial
description: "Introduction to using Git through the command line."
last_updated: 2020-04-22
---

# Start using Git on the command line

[Git](https://git-scm.com/) is an open-source distributed version control system designed to
handle everything from small to very large projects with speed and efficiency. GitLab is built
on top of Git.

While GitLab has a powerful user interface from which you can do a great amount of Git operations
directly in the browser, you’ll eventually need to use Git through the command line for advanced
tasks.

For example, if you need to fix complex merge conflicts, rebase branches,
merge manually, or undo and roll back commits, you'll need to use Git from
the command line and then push your changes to the remote server.

This guide will help you get started with Git through the command line and can be your reference
for Git commands in the future. If you're only looking for a quick reference of Git commands, you
can download GitLab's [Git Cheat Sheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf).

TIP: **Tip:**
To help you visualize what you're doing locally, there are
[Git GUI apps](https://git-scm.com/download/gui/) you can install.

## Requirements

You don't need a GitLab account to use Git locally, but for the purpose of this guide we
recommend registering and signing into your account before starting. Some commands need a
connection between the files in your computer and their version on a remote server.

You'll also need to open a [command shell](#command-shell) and have
[Git installed](#install-git) in your computer.

### Command shell

To execute Git commands in your computer, you'll need to open a command shell (also known as command
prompt, terminal, and command line) of your preference. Here are some suggestions:

- For macOS users:
  - Built-in: [Terminal](https://blog.teamtreehouse.com/introduction-to-the-mac-os-x-command-line). Press <kbd>⌘ command</kbd> + <kbd>space</kbd> and type "terminal" to find it.
  - [iTerm2](https://www.iterm2.com/), which you can integrate with [zsh](https://git-scm.com/book/id/v2/Appendix-A%3A-Git-in-Other-Environments-Git-in-Zsh) and [oh my zsh](https://ohmyz.sh/) for color highlighting, among other handy features for Git users.
- For Windows users:
  - Built-in: **cmd**. Click the search icon on the bottom navbar on Windows and type "cmd" to find it.
  - [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-windows-powershell?view=powershell-7): a Windows "powered up" shell, from which you can execute a greater number of commands.
  - Git Bash: it comes built into [Git for Windows](https://gitforwindows.org/).
- For Linux users:
  - Built-in: [Linux Terminal](https://www.howtogeek.com/140679/beginner-geek-how-to-start-using-the-linux-terminal/).

### Install Git

Open a command shell and run the following command to check if Git is already installed in your
computer:

```shell
git --version
```

If you have Git installed, the output will be:

```shell
git version X.Y.Z
```

If your computer doesn't recognize `git` as a command, you'll need to [install Git](../topics/git/how_to_install_git/index.md).
After that, run `git --version` again to verify whether it was correctly installed.

## Configure Git

To start using Git from your computer, you'll need to enter your credentials (user name and email)
to identify you as the author of your work. The user name and email should match the ones you're
using on GitLab.

In your shell, add your user name:

```shell
git config --global user.name "your_username"
```

And your email address:

```shell
git config --global user.email "your_email_address@example.com"
```

To check the configuration, run:

```shell
git config --global --list
```

The `--global` option tells Git to always use this information for anything you do on your system.
If you omit `--global` or use `--local`, the configuration will be applied only to the current
repository.

You can read more on how Git manages configurations in the
[Git Config](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration) documentation.

## Basic Git commands

Start using Git via the command line with the most basic commands as described below.

### Initialize a local directory for Git version control

If you have an existing local directory that you want to *initialize* for version
control, use the `init` command to instruct Git to begin tracking the directory:

```shell
git init
```

This creates a `.git` directory that contains the Git configuration files.

Once the directory has been initialized, you can [add a remote repository](#add-a-remote-repository)
and [send changes to GitLab.com](#send-changes-to-gitlabcom). You will also need to
[create a new project in GitLab](../gitlab-basics/create-project.md#push-to-create-a-new-project)
for your Git repository.

### Clone a repository

To start working locally on an existing remote repository, clone it with the command
`git clone <repository path>`. By cloning a repository, you'll download a copy of its
files to your local computer, automatically preserving the Git connection with the
remote repository.

You can either clone it via [HTTPS](#clone-via-https) or [SSH](#clone-via-ssh). If you chose to
clone it via HTTPS, you'll have to enter your credentials every time you pull and push.
You can read more about credential storage in the
[Git Credentials documentation](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).
With [SSH](../ssh/README.md), you enter your credentials only once.

You can find both paths (HTTPS and SSH) by navigating to your project's landing page
and clicking **Clone**. GitLab will prompt you with both paths, from which you can copy
and paste in your command line.

As an example, consider this repository path:

- HTTPS: `https://gitlab.com/gitlab-org/gitlab.git`
- SSH: `git@gitlab.com:gitlab-org/gitlab.git`

To get started, open a terminal window in the directory you wish to clone the
repository files into, and run one of the `git clone` commands as described below.

Both commands will download a copy of the files in a folder named after the project's
name. You can then navigate to the new directory and start working on it locally.

#### Clone via HTTPS

To clone `https://gitlab.com/gitlab-org/gitlab.git` via HTTPS:

```shell
git clone https://gitlab.com/gitlab-org/gitlab.git
```

You'll have to add your password every time you clone through HTTPS. If you have 2FA enabled
for your account, you'll have to use a [Personal Access Token](../user/profile/personal_access_tokens.md)
with **read_repository** or **write_repository** permissions instead of your account's password.

If you don't have 2FA enabled, use your account's password.

TIP: **Troubleshooting:**
On Windows, if you entered incorrect passwords multiple times and GitLab is responding `Access denied`,
you may have to add your namespace (user name or group name) to clone through HTTPS:
`git clone https://namespace@gitlab.com/gitlab-org/gitlab.git`.

#### Clone via SSH

To clone `git@gitlab.com:gitlab-org/gitlab.git` via SSH:

```shell
git clone git@gitlab.com:gitlab-org/gitlab.git
```

### Switch to the master branch

You are always in a branch when working with Git. The main branch is the master
branch, but you can use the same command to switch to a different branch by
changing `master` to the branch name.

```shell
git checkout master
```

### Download the latest changes in the project

To work on an up-to-date copy of the project (it is important to do this every time
you start working on a project), you `pull` to get all the changes made by users
since the last time you cloned or pulled the project. Use `master` for the
`<name-of-branch>` to get the main branch code, or the branch name of the branch
you are currently working in.

```shell
git pull <REMOTE> <name-of-branch>
```

When you clone a repository, `REMOTE` is typically `origin`. This is where the
repository was cloned from, and it indicates the SSH or HTTPS URL of the repository
on the remote server. `<name-of-branch>` is usually `master`, but it may be any
existing branch. You can create additional named remotes and branches as necessary.

You can learn more on how Git manages remote repositories in the
[Git Remote documentation](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes).

### View your remote repositories

To view your remote repositories, type:

```shell
git remote -v
```

The `-v` flag stands for verbose.

### Add a remote repository

To add a link to a remote repository:

```shell
git remote add <source-name> <repository-path>
```

You'll use this source name every time you [push changes to GitLab.com](#send-changes-to-gitlabcom),
so use something easy to remember and type.

### Create a branch

To create a new branch, to work from without affecting the `master` branch, type
the following (spaces won't be recognized in the branch name, so you will need to
use a hyphen or underscore):

```shell
git checkout -b <name-of-branch>
```

### Work on an existing branch

To switch to an existing branch, so you can work on it:

```shell
git checkout <name-of-branch>
```

### View the changes you've made

It's important to be aware of what's happening and the status of your changes. When
you add, change, or delete files/folders, Git knows about it. To check the status of
your changes:

```shell
git status
```

### View differences

To view the differences between your local, unstaged changes and the repository versions
that you cloned or pulled, type:

```shell
git diff
```

### Add and commit local changes

You'll see any local changes in red when you type `git status`. These changes may
be new, modified, or deleted files/folders. Use `git add` to first stage (prepare)
a local file/folder for committing. Then use `git commit` to commit (save) the staged
files:

```shell
git add <file-name OR folder-name>
git commit -m "COMMENT TO DESCRIBE THE INTENTION OF THE COMMIT"
```

### Add all changes to commit

To add and commit (save) all local changes quickly:

```shell
git add .
git commit -m "COMMENT TO DESCRIBE THE INTENTION OF THE COMMIT"
```

NOTE: **Note:**
The `.` character means _all file changes in the current directory and all subdirectories_.

### Send changes to GitLab.com

NOTE: **Note:**
To create a merge request from a fork to an upstream repository, see the
[forking workflow](../user/project/repository/forking_workflow.md)

To push all local commits (saved changes) to the remote repository:

```shell
git push <remote> <name-of-branch>
```

For example, to push your local commits to the _`master`_ branch of the _`origin`_ remote:

```shell
git push origin master
```

### Delete all changes in the branch

To delete all local changes in the branch that have not been added to the staging
area, and leave unstaged files/folders, type:

```shell
git checkout .
```

Note that this removes *changes* to files, not the files themselves.

### Unstage all changes that have been added to the staging area

To undo the most recently added, but not committed, changes to files/folders:

```shell
git reset .
```

### Undo most recent commit

To undo the most recent commit, type:

```shell
git reset HEAD~1
```

This leaves the changed files and folders unstaged in your local repository.

CAUTION: **Warning:**
A Git commit should not usually be reversed, particularly if you already pushed it
to the remote repository. Although you can undo a commit, the best option is to avoid
the situation altogether by working carefully.

### Merge a branch with master branch

When you are ready to make all the changes in a branch a permanent addition to
the master branch, you `merge` the two together:

```shell
git checkout <name-of-branch>
git merge master
```

### Synchronize changes in a forked repository with the upstream

[Forking a repository](../user/project/repository/forking_workflow.md) lets you create
a copy of a repository in your namespace. Changes made to your copy of the repository
are not synchronized automatically with the original.
Your local fork (copy) contains changes made by you only, so to keep the project
in sync with the original project, you need to `pull` from the original repository.

You must [create a link to the remote repository](#add-a-remote-repository) to pull
changes from the original repository. It is common to call this remote the `upstream`.

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
