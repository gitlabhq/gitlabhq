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
directly in the browser, you'll eventually need to use Git through the command line for advanced
tasks.

For example, if you need to fix complex merge conflicts, rebase branches,
merge manually, or undo and roll back commits, you must use Git from
the command line and then push your changes to the remote server.

This guide helps you get started with Git through the command line and can be your reference
for Git commands in the future. If you're only looking for a quick reference of Git commands, you
can download the GitLab [Git Cheat Sheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf).

> For more information about the advantages of working with Git and GitLab:
>
> - <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>&nbsp;Watch the [GitLab Source Code Management Walkthrough](https://www.youtube.com/watch?v=wTQ3aXJswtM) video.
> - Learn how GitLab became the backbone of [Worldline](https://about.gitlab.com/customers/worldline/)'s development environment.

NOTE:
To help you visualize what you're doing locally, there are
[Git GUI apps](https://git-scm.com/download/gui/) you can install.

## Requirements

You don't need a GitLab account to use Git locally, but for the purpose of this guide we
recommend registering and signing into your account before starting. Some commands need a
connection between the files in your computer and their version on a remote server.

You must also open a [command shell](#command-shell) and have
[Git installed](#install-git) in your computer.

### Command shell

To execute Git commands in your computer, you must open a command shell (also known as command
prompt, terminal, and command line) of your preference. Here are some suggestions:

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

Open a command shell and run the following command to check if Git is already installed in your
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
- Authenticate through SSH once and GitLab no longer requests your credentials every time you pull, push,
  and clone.

To start the authentication process, we'll [clone](#clone-a-repository) an existing repository
to our computer:

- If you want to use **SSH** to authenticate, follow the instructions on the [SSH documentation](../ssh/README.md)
  to set it up before cloning.
- If you want to use **HTTPS**, GitLab requests your user name and password:
  - If you have 2FA enabled for your account, you must use a [Personal Access Token](../user/profile/personal_access_tokens.md)
    with **read_repository** or **write_repository** permissions instead of your account's password.
    Create one before cloning.
  - If you don't have 2FA enabled, use your account's password.

NOTE:
Authenticating via SSH is the GitLab recommended method. You can read more about credential storage
in the [Git Credentials documentation](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).

## Git terminology

If you're familiar with the Git terminology, you may want to jump directly
into the [basic commands](#basic-git-commands).

### Namespace

A **namespace** is either a **user name** or a **group name**.

For example, suppose Jo is a GitLab.com user and they chose their user name as
`jo`. You can see Jo's profile at `https://gitlab.com/jo`. `jo` is a namespace.

Jo also created a group in GitLab, and chose the path `test-group` for their
group. The group can be accessed under `https://gitlab.com/test-group`. `test-group` is a namespace.

### Repository

Your files in GitLab live in a **repository**, similar to how you have them in a folder or
directory in your computer. **Remote** repository refers to the files in
GitLab and the copy in your computer is called **local** copy.
A **project** in GitLab is what holds a repository, which holds your files.

<!-- vale gitlab.Spelling = NO -->
<!-- vale gitlab.SubstitutionWarning = NO -->
Often, the word "repository" is shortened to "repo".
<!-- vale gitlab.Spelling = YES -->
<!-- vale gitlab.SubstitutionWarning = YES -->

### Fork

When you want to copy someone else's repository, you [**fork**](../user/project/repository/forking_workflow.md#creating-a-fork)
the project. By forking it, you create a copy of the project into your own
namespace to have read and write permissions to modify the project files
and settings.

For example, if you fork this project, <https://gitlab.com/gitlab-tests/sample-project/> into your namespace, you create your own copy of the repository in your namespace (`https://gitlab.com/your-namespace/sample-project/`). From there, you can clone it into your computer,
work on its files, and (optionally) submit proposed changes back to the
original repository if you'd like.

### Download vs clone

To create a copy of a remote repository's files on your computer, you can either
**download** or **clone**. If you download, you cannot sync it with the
remote repository on GitLab.

[Cloning](#clone-a-repository) a repository is the same as downloading, except it preserves the Git connection
with the remote repository. This allows you to modify the files locally and
upload the changes to the remote repository on GitLab.

### Pull and push

After you saved a local copy of a repository and modified its files on your computer, you can upload the
changes to GitLab. This is referred to as **pushing** to GitLab, as this is achieved by the command
[`git push`](#send-changes-to-gitlabcom).

When the remote repository changes, your local copy is behind it. You can update it with the new
changes in the remote repository.
This is referred to as **pulling** from GitLab, as this is achieved by the command
[`git pull`](#download-the-latest-changes-in-the-project).

## Basic Git commands

For the purposes of this guide, we use this example project on GitLab.com:
[https://gitlab.com/gitlab-tests/sample-project/](https://gitlab.com/gitlab-tests/sample-project/).

To use it, log into GitLab.com and fork the example project into your
namespace to have your own copy to playing with. Your sample
project is available under `https://gitlab.com/<your-namespace>/sample-project/`.

You can also choose any other project to follow this guide. Then, replace the
example URLs with your own project's.

If you want to start by copying an existing GitLab repository onto your
computer, see how to [clone a repository](#clone-a-repository). On the other
hand, if you want to start by uploading an existing folder from your computer
to GitLab, see how to [convert a local folder into a Git repository](#convert-a-local-directory-into-a-repository).

### Clone a repository

To start working locally on an existing remote repository, clone it with the
command `git clone <repository path>`. You can either clone it via [HTTPS](#clone-via-https)
or [SSH](#clone-via-ssh), according to your preferred [authentication method](#git-authentication-methods).

You can find both paths (HTTPS and SSH) by navigating to your project's landing page
and clicking **Clone**. GitLab prompts you with both paths, from which you can copy
and paste in your command line. You can also
[clone and open directly in Visual Studio Code](../user/project/repository/index.md#clone-and-open-in-apple-xcode).

For example, considering our [sample project](https://gitlab.com/gitlab-tests/sample-project/):

- To clone through HTTPS, use `https://gitlab.com/gitlab-tests/sample-project.git`.
- To clone through SSH, use `git@gitlab.com:gitlab-tests/sample-project.git`.

To get started, open a terminal window in the directory you wish to add the
repository files into, and run one of the `git clone` commands as described below.

Both commands download a copy of the files in a folder named after the project's
name and preserve the connection with the remote repository.
You can then navigate to the new directory with `cd sample-project` and start working on it
locally.

#### Clone via HTTPS

To clone `https://gitlab.com/gitlab-tests/sample-project/` via HTTPS:

```shell
git clone https://gitlab.com/gitlab-tests/sample-project.git
```

NOTE:
On Windows, if you entered incorrect passwords multiple times and GitLab is responding `Access denied`,
you may have to add your namespace (user name or group name) to clone through HTTPS:
`git clone https://namespace@gitlab.com/gitlab-org/gitlab.git`.

#### Clone via SSH

To clone `git@gitlab.com:gitlab-org/gitlab.git` via SSH:

```shell
git clone git@gitlab.com:gitlab-org/gitlab.git
```

### Convert a local directory into a repository

When you have your files in a local folder and want to convert it into
a repository, you must _initialize_ the folder through the `git init`
command. This instructs Git to begin to track that directory as a
repository. To do so, open the terminal on the directory you'd like to convert
and run:

```shell
git init
```

This command creates a `.git` folder in your directory that contains Git
records and configuration files. We advise against editing these files
directly.

Then, on the next step, add the [path to your remote repository](#add-a-remote-repository)
so that Git can upload your files into the correct project.

#### Add a remote repository

By "adding a remote repository" to your local directory you tell Git that
the path to that specific project in GitLab corresponds to that specific
folder you have in your computer. This way, your local folder is
identified by Git as the local content for that specific remote project.

To add a remote repository to your local copy:

1. In GitLab, [create a new project](../user/project/working_with_projects.md#create-a-project) to hold your files.
1. Visit this project's homepage, scroll down to **Push an existing folder**, and copy the command that starts with `git remote add`.
1. On your computer, open the terminal in the directory you've initialized, paste the command you copied, and press <kbd>enter</kbd>:

   ```shell
   git remote add origin git@gitlab.com:username/projectpath.git
   ```

After you've done that, you can [stage your files](#add-and-commit-local-changes) and [upload them to GitLab](#send-changes-to-gitlabcom).

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

## Branching

If you want to add code to a project but you're not sure if it works properly, or you're
collaborating on the project with others, and don't want your work to get mixed up, it's a good idea
to work on a different **branch**.

When you create a branch in a Git repository, you make a copy of its files at the time of branching. You're free
to do whatever you want with the code in your branch without impacting the main branch or other branches. And when
you're ready to bring your changes to the main codebase, you can merge your branch into the default branch
used in your project (such as `master`).

A new branch is often called **feature branch** to differentiate from the
**default branch**.

### Create a branch

To create a new feature branch and work from without affecting the `master`
branch:

```shell
git checkout -b <name-of-branch>
```

Note that Git does **not** accept empty spaces and special characters in branch
names, so use only lowercase letters, numbers, hyphens (`-`), and underscores
(`_`). Do not use capital letters, as it may cause duplications.

### Switch to the master branch

You are always in a branch when working with Git. The main branch is the master
branch, but you can use the same command to switch to a different branch by
changing `master` to the branch name.

```shell
git checkout master
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

Local changes are shown in red when you type `git status`. These changes may
be new, modified, or deleted files/folders. Use `git add` to first stage (prepare)
a local file/folder for committing. Then use `git commit` to commit (save) the staged
files:

```shell
git add <file-name OR folder-name>
git commit -m "COMMENT TO DESCRIBE THE INTENTION OF THE COMMIT"
```

#### Add all changes to commit

To add and commit (save) all local changes quickly:

```shell
git add .
git commit -m "COMMENT TO DESCRIBE THE INTENTION OF THE COMMIT"
```

NOTE:
The `.` character means _all file changes in the current directory and all subdirectories_.

### Send changes to GitLab.com

To push all local commits (saved changes) to the remote repository:

```shell
git push <remote> <name-of-branch>
```

For example, to push your local commits to the _`master`_ branch of the _`origin`_ remote:

```shell
git push origin master
```

On certain occasions, Git disallows pushes to your repository, and then
you must [force an update](../topics/git/git_rebase.md#force-push).

NOTE:
To create a merge request from a fork to an upstream repository, see the
[forking workflow](../user/project/repository/forking_workflow.md).

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

WARNING:
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

## Advanced use of Git through the command line

For an introduction of more advanced Git techniques, see [Git rebase, force-push, and merge conflicts](../topics/git/git_rebase.md).

## Synchronize changes in a forked repository with the upstream

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
