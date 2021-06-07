---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto, tutorial
description: "Introduction to using Git through the command line."
---

# Start using Git on the command line **(FREE)**

[Git](https://git-scm.com/) is an open-source distributed version control system designed to
handle everything from small to very large projects with speed and efficiency. GitLab is built
on top of Git.

While GitLab has a powerful user interface from which you can do a great amount of Git operations
directly in the browser, the command line is required for advanced tasks.

For example, if you need to fix complex merge conflicts, rebase branches,
or undo and roll back commits, you must use Git from
the command line and then push your changes to the remote server.

This guide helps you get started with Git through the command line and can be a reference
for Git commands in the future. If you're only looking for a quick reference of Git commands, you
can download the GitLab [Git Cheat Sheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf).

For more information about the advantages of working with Git and GitLab:

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>&nbsp;Watch the [GitLab Source Code Management Walkthrough](https://www.youtube.com/watch?v=wTQ3aXJswtM) video.
- Learn how [GitLab became the backbone of Worldline](https://about.gitlab.com/customers/worldline/)'s development environment.

NOTE:
To help you visualize what you're doing locally, there are
[Git GUI apps](https://git-scm.com/download/gui/) you can install.

## Prerequisites

You don't need a GitLab account to use Git locally, but for the purpose of this guide we
recommend registering and signing into your account before starting. Some commands need a
connection between the files on your computer and their version on a remote server.

You must also open a [terminal](#open-a-terminal) and have
[Git installed](#install-git) on your computer.

### Open a terminal

To execute Git commands on your computer, you must open a terminal (also known as command
prompt, command shell, and command line) of your preference. Here are some suggestions:

- For macOS users:
  - Built-in: [Terminal](https://blog.teamtreehouse.com/introduction-to-the-mac-os-x-command-line). Press <kbd>⌘ command</kbd> + <kbd>space</kbd> and type "terminal" to find it.
  - [iTerm2](https://iterm2.com/), which you can integrate with [zsh](https://git-scm.com/book/id/v2/Appendix-A%3A-Git-in-Other-Environments-Git-in-Zsh) and [oh my zsh](https://ohmyz.sh/) for color highlighting, among other handy features for Git users.
- For Windows users:
  - Built-in: `cmd`. Click the search icon on the bottom navigation bar on Windows and type `cmd` to find it.
  - [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-7): a Windows "powered up" shell, from which you can execute a greater number of commands.
  - Git Bash: it comes built into [Git for Windows](https://gitforwindows.org/).
- For Linux users:
  - Built-in: [Linux Terminal](https://www.howtogeek.com/140679/beginner-geek-how-to-start-using-the-linux-terminal/).

### Install Git

Open a terminal and run the following command to check if Git is already installed in your
computer:

```shell
git --version
```

If you have Git installed, the output is:

```shell
git version X.Y.Z
```

If your computer doesn't recognize `git` as a command, you must [install Git](../topics/git/how_to_install_git/index.md).
After that, run `git --version` again to verify whether it was correctly installed.

## Configure Git

To start using Git from your computer, you must enter your credentials (user name and email)
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
If you omit `--global` or use `--local`, the configuration is applied only to the current
repository.

You can read more on how Git manages configurations in the
[Git configuration documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration).

## Git authentication methods

To connect your computer with GitLab, you need to add your credentials to identify yourself.
You have two options:

- Authenticate on a project-by-project basis through HTTPS, and enter your credentials every time
  you perform an operation between your computer and GitLab.
- Authenticate through SSH once and GitLab no longer requests your credentials every time you
  perform an operation between your computer and GitLab.

To start the authentication process, we'll [clone](#clone-a-repository) an existing repository
to our computer:

- If you want to use **SSH** to authenticate, follow the instructions on the [SSH documentation](../ssh/README.md)
  to set it up before cloning.
- If you want to use **HTTPS**, GitLab requests your username and password:
  - If you have 2FA enabled for your account, you must use a [Personal Access Token](../user/profile/personal_access_tokens.md)
    with **read_repository** or **write_repository** permissions instead of your account's password.
  - If you don't have 2FA enabled, use your account's password.

NOTE:
Authenticating through SSH is the GitLab recommended method. You can read more about credential storage
in the [Git Credentials documentation](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).

## Git terminology

If you're familiar with Git terminology, you may want to jump directly
into [setting up a repository](#set-up-a-repository).

### Repository

Your files in GitLab live in a **repository**, similar to how you have them in a folder or
directory on your computer.

- **Remote** repository refers to the files in GitLab.
- A **local** copy refers to the files on your computer.

<!-- vale gitlab.Spelling = NO -->
<!-- vale gitlab.SubstitutionWarning = NO -->
Often, the word "repository" is shortened to "repo".
<!-- vale gitlab.Spelling = YES -->
<!-- vale gitlab.SubstitutionWarning = YES -->

A **project** in GitLab is what holds a repository.

### Fork

When you want to copy someone else's repository, you [**fork**](../user/project/repository/forking_workflow.md#creating-a-fork)
the project. By forking it, you create a copy of the project into your own
[namespace](../user/group/#namespaces) to have read and write permissions to modify the project files
and settings.

For example, if you fork this project, <https://gitlab.com/gitlab-tests/sample-project/> into your namespace,
you create your own copy of the repository in your namespace (`https://gitlab.com/your-namespace/sample-project/`).
From there, you can clone the repository, work on the files, and (optionally) submit proposed changes back to the
original repository.

### Difference between download and clone

To create a copy of a remote repository's files on your computer, you can either
**download** or **clone** the repository. If you download it, you cannot sync the repository with the
remote version on GitLab.

[Cloning](#clone-a-repository) a repository is the same as downloading, except it preserves the Git connection
with the remote repository. This allows you to modify the files locally and
upload the changes to the remote repository on GitLab.

### Pull and push

After you save a local copy of a repository and modify the files on your computer, you can upload the
changes to GitLab. This is referred to as **pushing** to the remote, as this is achieved by the command
[`git push`](#send-changes-to-gitlabcom).

When the remote repository changes, your local copy is behind. You can update your local copy with the new
changes in the remote repository.
This is referred to as **pulling** from the remote, as this is achieved by the command
[`git pull`](#download-the-latest-changes-in-the-project).

## Set up a repository

Git commands will work with any Git repository.

For the purposes of this guide, we refer to this example project on GitLab.com:
[https://gitlab.com/gitlab-tests/sample-project/](https://gitlab.com/gitlab-tests/sample-project/).
Remember to replace the example URLs with the relevant path of your project.

To get started, choose one of the following:

- Use the example project by signing into GitLab.com and [forking](../user/project/repository/forking_workflow.md#creating-a-fork)
it into your namespace to make it available under `https://gitlab.com/<your-namespace>/sample-project/`.
- Copy an existing GitLab repository onto your computer by [cloning a repository](#clone-a-repository).
- Upload an existing folder from your computer to GitLab by [converting a local folder into a Git repository](#convert-a-local-directory-into-a-repository).

### Clone a repository

To start working locally on an existing remote repository, clone it with the
command `git clone <repository path>`. You can either clone it using [HTTPS](#clone-using-https)
or [SSH](#clone-using-ssh), according to your preferred [authentication method](#git-authentication-methods).

You can find both paths (HTTPS and SSH) by navigating to your project's landing page
and clicking **Clone**. GitLab prompts you with both paths, from which you can copy
and paste in your command line. You can also
[clone and open directly in Visual Studio Code](../user/project/repository/index.md#clone-and-open-in-apple-xcode).

For example, with our [sample project](https://gitlab.com/gitlab-tests/sample-project/):

- To clone through HTTPS, use `https://gitlab.com/gitlab-tests/sample-project.git`.
- To clone through SSH, use `git@gitlab.com:gitlab-tests/sample-project.git`.

To get started, open a terminal window in the directory you wish to add the
repository files into, and run one of the `git clone` commands as described below.

Both commands download a copy of the files in a folder named after the project's
name and preserve the connection with the remote repository.
You can then navigate to the new directory with `cd sample-project` and start working on it
locally.

#### Clone using HTTPS

To clone `https://gitlab.com/gitlab-tests/sample-project/` using HTTPS:

```shell
git clone https://gitlab.com/gitlab-tests/sample-project.git
```

NOTE:
On Windows, if you enter your password incorrectly multiple times and GitLab is responding `Access denied`,
add your namespace (username or group):
`git clone https://namespace@gitlab.com/gitlab-org/gitlab.git`.

#### Clone using SSH

To clone `git@gitlab.com:gitlab-org/gitlab.git` using SSH:

```shell
git clone git@gitlab.com:gitlab-org/gitlab.git
```

### Convert a local directory into a repository

When you have your files in a local folder and want to convert it into
a repository, you must _initialize_ the folder through the `git init`
command. This command instructs Git to track that directory as a
repository. Open the terminal in the directory you'd like to convert
and run:

```shell
git init
```

This command creates a `.git` folder in your directory that contains Git
records and configuration files. We advise against editing these files
directly.

Following the steps in the next section, add the [path to your remote repository](#add-a-remote-repository)
so that Git can upload your files into the correct project.

#### Add a remote repository

You add a remote repository to tell Git which remote project in GitLab is tied
to the specific local folder on your computer.
The remote tells Git where to push or pull from.

To add a remote repository to your local copy:

1. In GitLab, [create a new project](../user/project/working_with_projects.md#create-a-project) to hold your files.
1. Visit this project's homepage, scroll down to **Push an existing folder**, and copy the command that starts with `git remote add`.
1. On your computer, open the terminal in the directory you've initialized, paste the command you copied, and press <kbd>enter</kbd>:

   ```shell
   git remote add origin git@gitlab.com:username/projectpath.git
   ```

After you've done that, you can [stage your files](#add-and-commit-local-changes) and [upload them to GitLab](#send-changes-to-gitlabcom).

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

### View your remote repositories

To view your remote repositories, type:

```shell
git remote -v
```

The `-v` flag stands for verbose.

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

In this case, you [create a link to the remote repository](#add-a-remote-repository).
This remote is commonly called the `upstream`.

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
