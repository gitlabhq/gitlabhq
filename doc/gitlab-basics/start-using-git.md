---
type: howto, tutorial
---

# Start using Git on the command line

While GitLab has a powerful user interface, if you want to use Git itself, you will
have to do so from the command line. If you want to start using Git and GitLab together,
make sure that you have created and/or signed into an account on GitLab.

## Open a shell

Depending on your operating system, you will need to use a shell of your preference.
Here are some suggestions:

- [Terminal](https://blog.teamtreehouse.com/introduction-to-the-mac-os-x-command-line) on macOS
- [GitBash](https://msysgit.github.io) on Windows
- [Linux Terminal](https://www.howtogeek.com/140679/beginner-geek-how-to-start-using-the-linux-terminal/) on Linux

## Check if Git has already been installed

Git is usually preinstalled on Mac and Linux, so run the following command:

```bash
git --version
```

You should receive a message that tells you which Git version you have on your computer.
If you don’t receive a "Git version" message, it means that you need to
[download Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

After you are finished installing Git, open a new shell and type `git --version` again
to verify that it was correctly installed.

## Add your Git username and set your email

It is important to configure your Git username and email address, since every Git
commit will use this information to identify you as the author.

In your shell, type the following command to add your username:

```bash
git config --global user.name "YOUR_USERNAME"
```

Then verify that you have the correct username:

```bash
git config --global user.name
```

To set your email address, type the following command:

```bash
git config --global user.email "your_email_address@example.com"
```

To verify that you entered your email correctly, type:

```bash
git config --global user.email
```

You'll need to do this only once, since you are using the `--global` option. It
tells Git to always use this information for anything you do on that system. If
you want to override this with a different username or email address for specific
projects or repositories, you can run the command without the `--global` option
when you’re in that project, and that will default to `--local`. You can read more
on how Git manages configurations in the [Git Config](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration) documentation.

## Check your information

To view the information that you entered, along with other global options, type:

```bash
git config --global --list
```

## Basic Git commands

Start using Git via the command line with the most basic commands as described below.

### Initialize a local directory for Git version control

If you have an existing local directory that you want to *initialize* for version
control, use the `init` command to instruct Git to begin tracking the directory:

```bash
git init
```

This creates a `.git` directory that contains the Git configuration files.

Once the directory has been initialized, you can [add a remote repository](#add-a-remote-repository)
and [send changes to GitLab.com](#send-changes-to-gitlabcom). You will also need to
[create a new project in GitLab](../gitlab-basics/create-project.html#push-to-create-a-new-project)
for your Git repository.

### Clone a repository

To start working locally on an existing remote repository, clone it with the command
`git clone <repository path>`. By cloning a repository, you'll download a copy of its
files to your local computer, automatically preserving the Git connection with the
remote repository.

You can either clone it via HTTPS or [SSH](../ssh/README.md). If you chose to clone
it via HTTPS, you'll have to enter your credentials every time you pull and push.
You can read more about credential storage in the
[Git Credentials documentation](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).
With SSH, you enter your credentials only once.

You can find both paths (HTTPS and SSH) by navigating to your project's landing page
and clicking **Clone**. GitLab will prompt you with both paths, from which you can copy
and paste in your command line.

As an example, consider this repository path:

- HTTPS: `https://gitlab.com/gitlab-org/gitlab.git`
- SSH: `git@gitlab.com:gitlab-org/gitlab.git`

To get started, open a terminal window in the directory you wish to clone the
repository files into, and run one of the following commands.

Clone via HTTPS:

```bash
git clone https://gitlab.com/gitlab-org/gitlab.git
```

Clone via SSH:

```bash
git clone git@gitlab.com:gitlab-org/gitlab.git
```

Both commands will download a copy of the files in a folder named after the project's
name. You can then navigate to the directory and start working
on it locally.

### Switch to the master branch

You are always in a branch when working with Git. The main branch is the master
branch, but you can use the same command to switch to a different branch by
changing `master` to the branch name.

```bash
git checkout master
```

### Download the latest changes in the project

To work on an up-to-date copy of the project (it is important to do this every time
you start working on a project), you `pull` to get all the changes made by users
since the last time you cloned or pulled the project. Use `master` for the
`<name-of-branch>` to get the main branch code, or the branch name of the branch
you are currently working in.

```bash
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

```bash
git remote -v
```

The `-v` flag stands for verbose.

### Add a remote repository

To add a link to a remote repository:

```bash
git remote add <source-name> <repository-path>
```

You'll use this source name every time you [push changes to GitLab.com](#send-changes-to-gitlabcom),
so use something easy to remember and type.

### Create a branch

To create a new branch, to work from without affecting the `master` branch, type
the following (spaces won't be recognized in the branch name, so you will need to
use a hyphen or underscore):

```bash
git checkout -b <name-of-branch>
```

### Work on an existing branch

To switch to an existing branch, so you can work on it:

```bash
git checkout <name-of-branch>
```

### View the changes you've made

It's important to be aware of what's happening and the status of your changes. When
you add, change, or delete files/folders, Git knows about it. To check the status of
your changes:

```bash
git status
```

### View differences

To view the differences between your local, unstaged changes and the repository versions
that you cloned or pulled, type:

```bash
git diff
```

### Add and commit local changes

You'll see any local changes in red when you type `git status`. These changes may
be new, modified, or deleted files/folders. Use `git add` to first stage (prepare)
a local file/folder for committing. Then use `git commit` to commit (save) the staged
files:

```bash
git add <file-name OR folder-name>
git commit -m "COMMENT TO DESCRIBE THE INTENTION OF THE COMMIT"
```

### Add all changes to commit

To add and commit (save) all local changes quickly:

```bash
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

```bash
git push <remote> <name-of-branch>
```

For example, to push your local commits to the _`master`_ branch of the _`origin`_ remote:

```bash
git push origin master
```

### Delete all changes in the branch

To delete all local changes in the branch that have not been added to the staging
area, and leave unstaged files/folders, type:

```bash
git checkout .
```

Note that this removes *changes* to files, not the files themselves.

### Unstage all changes that have been added to the staging area

To undo the most recently added, but not committed, changes to files/folders:

```bash
git reset .
```

### Undo most recent commit

To undo the most recent commit, type:

```bash
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

```bash
git checkout <name-of-branch>
git merge master
```

### Synchronize changes in a forked repository with the upstream

[Forking a repository](../user/project/repository/forking_workflow.md lets you create
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
