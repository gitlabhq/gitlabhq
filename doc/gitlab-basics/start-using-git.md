# Start using Git on the command line

If you want to start using Git and GitLab, make sure that you have created and/or signed into an account on GitLab.

## Open a shell

Depending on your operating system, you will need to use a shell of your preference. Here are some suggestions:

- [Terminal](http://blog.teamtreehouse.com/introduction-to-the-mac-os-x-command-line) on  Mac OSX

- [GitBash](https://msysgit.github.io) on Windows

- [Linux Terminal](http://www.howtogeek.com/140679/beginner-geek-how-to-start-using-the-linux-terminal/) on Linux

## Check if Git has already been installed

Git is usually preinstalled on Mac and Linux.

Type the following command and then press enter:

```bash
git --version
```

You should receive a message that tells you which Git version you have on your computer. If you don’t receive a "Git version" message, it means that you need to [download Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

If Git doesn't automatically download, there's an option on the website to [download manually](https://git-scm.com/downloads). Then follow the steps on the installation window.

After you are finished installing Git, open a new shell and type `git --version` again to verify that it was correctly installed.

## Add your Git username and set your email

It is important to configure your Git username and email address, since every Git commit will use this information to identify you as the author.

On your shell, type the following command to add your username:

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

You'll need to do this only once, since you are using the `--global` option. It tells Git to always use this information for anything you do on that system. If you want to override this with a different username or email address for specific projects, you can run the command without the `--global` option when you’re in that project.

## Check your information

To view the information that you entered, along with other global options, type:

```bash
git config --global --list
```

## Basic Git commands

Start using Git via the command line with the most basic
commands as described below.

## Initialize a local directory for Git version control

If you have an existing local directory that you want to *initialize* for version control, use the `init` command to instruct Git to begin tracking the directory:

```bash
git init
```

This creates a `.git` directory that contains the Git configuration files.

Once the directory has been initialized, you can [add a remote repository](#add-a-remote-repository) and [send changes to GitLab.com](#send-changes-to-gitlabcom). View the instructions on [Create a project](../gitlab-basics/create-project.html#push-to-create-a-new-project) to create a new project on GitLab with your changes.

### Clone a repository

To start working locally on an existing remote repository,
clone it with the command `git clone <repository path>`.
By cloning a repository, you'll download a copy of its
files into your local computer, preserving the Git
connection with the remote repository.

You can either clone it via HTTPS or [SSH](../ssh/README.md).
If you chose to clone it via HTTPS, you'll have to enter your
credentials every time you pull and push. With SSH, you enter
your credentials once and can pull and push straightaway.

You can find both paths (HTTPS and SSH) by navigating to
your project's landing page and clicking **Clone**. GitLab
will prompt you with both paths, from which you can copy
and paste in your command line.

As an example, consider a repository path:

- HTTPS: `https://gitlab.com/gitlab-org/gitlab-ce.git`
- SSH: `` git@gitlab.com:gitlab-org/gitlab-ce.git ``

To get started, open a terminal window in the directory
you wish to clone the repository files into, and run one
of the following commands.

Clone via HTTPS:

```bash
git clone https://gitlab.com/gitlab-org/gitlab-ce.git
```

Clone via SSH:

```bash
git clone git@gitlab.com:gitlab-org/gitlab-ce.git
```

Both commands will download a copy of the files in a
folder named after the project's name.

You can then navigate to the directory and start working
on it locally.

### Go to the master branch to pull the latest changes from there

```bash
git checkout master
```

### Download the latest changes in the project

This is for you to work on an up-to-date copy (it is important to do this every time you start working on a project), while you set up tracking branches. You pull from remote repositories to get all the changes made by users since the last time you cloned or pulled the project. Later, you can push your local commits to the remote repositories.

```bash
git pull REMOTE NAME-OF-BRANCH
```

When you first clone a repository, REMOTE is typically "origin". This is where the repository came from, and it indicates the SSH or HTTPS URL of the repository on the remote server. NAME-OF-BRANCH is usually "master", but it may be any existing branch.

### View your remote repositories

To view your remote repositories, type:

```bash
git remote -v
```

### Add a remote repository

To add a link to a remote repository:

```bash
git remote add SOURCE-NAME REPOSITORY-PATH
```

You'll use this source name every time you [push changes to GitLab.com](#send-changes-to-gitlabcom), so use something easy to remember and type.

### Create a branch

To create a branch, type the following (spaces won't be recognized in the branch name, so you will need to use a hyphen or underscore):

```bash
git checkout -b NAME-OF-BRANCH
```

### Work on an existing branch

To switch to an existing branch, so you can work on it:

```bash
git checkout NAME-OF-BRANCH
```

### View the changes you've made

It's important to be aware of what's happening and the status of your changes. When you add, change, or delete files/folders, Git knows about it. To check the status of your changes:

```bash
git status
```

### View differences

To view the differences between your local, unstaged changes and the repository versions that you cloned or pulled, type:

```bash
git diff
```

### Add and commit local changes

You'll see your local changes in red when you type `git status`. These changes may be new, modified, or deleted files/folders. Use `git add` to stage a local file/folder for committing. Then use `git commit` to commit the staged files:

```bash
git add FILE OR FOLDER
git commit -m "COMMENT TO DESCRIBE THE INTENTION OF THE COMMIT"
```

### Add all changes to commit

To add and commit all local changes in one command:

```bash
git add .
git commit -m "COMMENT TO DESCRIBE THE INTENTION OF THE COMMIT"
```

NOTE: **Note:**
The `.` character typically means _all_ in Git.

### Send changes to GitLab.com

To push all local commits to the remote repository:

```bash
git push REMOTE NAME-OF-BRANCH
```

For example, to push your local commits to the _master_ branch of the _origin_ remote:

```bash
git push origin master
```

### Delete all changes in the Git repository

To delete all local changes in the repository that have not been added to the staging area, and leave unstaged files/folders, type:

```bash
git checkout .
```

### Delete all untracked changes in the Git repository

```bash
git clean -f
```

### Unstage all changes that have been added to the staging area

To undo the most recent add, but not committed, files/folders:

```bash
git reset .
```

### Undo most recent commit

To undo the most recent commit, type:

```bash
git reset HEAD~1
```

This leaves the files and folders unstaged in your local repository.

CAUTION: **Warning:**
A Git commit is mostly irreversible, particularly if you already pushed it to the remote repository. Although you can undo a commit, the best option is to avoid the situation altogether.

### Merge created branch with master branch

You need to be in the created branch.

```bash
git checkout NAME-OF-BRANCH
git merge master
```

### Merge master branch with created branch

You need to be in the master branch.

```bash
git checkout master
git merge NAME-OF-BRANCH
```
