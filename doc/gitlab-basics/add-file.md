---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Add, commit, and push a file to your Git repository using the command line."
---

# Add files and make changes by using Git

You can use the Git command line to add files, make changes to existing files, and stash changes you don't need yet.

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

   The filename should be green. The file is tracked locally by Git, but
   has not been committed and pushed.
1. Commit the file to your local copy of the project's Git repository:

   ```shell
   git commit -m "Describe the reason for your commit here"
   ```

1. Push your changes from your copy of the repository to GitLab.
   In this command, `origin` refers to the remote copy of the repository.
   Replace `<branchname>` with the name of your branch:

   ```shell
   git push origin <branchname>
   ```

1. Git prepares, compresses, and sends the data. Lines from the remote repository
   start with `remote:`:

   ```plaintext
   Enumerating objects: 9, done.
   Counting objects: 100% (9/9), done.
   Delta compression using up to 10 threads
   Compressing objects: 100% (5/5), done.
   Writing objects: 100% (5/5), 1.84 KiB | 1.84 MiB/s, done.
   Total 5 (delta 3), reused 0 (delta 0), pack-reused 0
   remote:
   remote: To create a merge request for <branchname>, visit:
   remote:   https://gitlab.com/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=<branchname>
   remote:
   To https://gitlab.com/gitlab-org/gitlab.git
    * [new branch]                <branchname> -> <branchname>
   branch '<branchname>' set up to track 'origin/<branchname>'.
   ```

Your file is copied from your local copy of the repository to the remote
repository.

To create a merge request, copy the link sent back from the remote
repository and paste it into a browser window.

### Add a file to the last commit

```shell
git add <filename>
git commit --amend
```

Append `--no-edit` to the `commit` command if you do not want to edit the commit
message.

## Make changes to existing files

When you make changes to files in a repository, Git tracks the changes
against the most recent version of the checked out branch. You can use
Git commands to review and commit your changes to the branch, and push
your work to GitLab.

### View repository status

When you add, change, or delete files or folders, Git knows about the
changes. To check which files have been changed:

- From your repository, run `git status`.

The branch name, most recent commit, and any new or changed files are displayed.
New files are displayed in green. Changed files are displayed in red.

### View differences

You can display the difference (or diff) between your local
changes and the most recent version of a branch. View a diff to
understand your local changes before you commit them to the branch.

To view the differences between your local unstaged changes and the
latest version that you cloned or pulled:

- From your repository, run `git diff`.

  To compare your changes against a specific branch, run
  `git diff <branch>`.

The diff is displayed:

- Lines with additions begin with a plus (`+`) and are displayed in green.
- Lines with removals or changes begin with a minus (`-`) and are displayed in red.

If the diff is large, by default only a portion of the diff is
displayed. You can advance the diff with <kbd>Enter</kbd>, and quit
back to your terminal with <kbd>Q</kbd>.

### Add and commit local changes

When you're ready to write your changes to the branch, you can commit
them. A commit includes a comment that records information about the
changes, and usually becomes the new tip of the branch.

Git doesn't automatically include any files you move, change, or
delete in a commit. This prevents you from accidentally including a
change or file, like a temporary directory. To include changes in a
commit, stage them with `git add`.

To stage and commit your changes:

1. From your repository, for each file or directory you want to add, run `git add <file name or path>`.

   To stage all files in the current working directory, run `git add .`.

1. Confirm that the files have been added to staging:

   ```shell
   git status
   ```

   The files are displayed in green.

1. To commit the staged files:

   ```shell
   git commit -m "<comment that describes the changes>"
   ```

The changes are committed to the branch.

### Commit all changes

You can stage all your changes and commit them with one command:

```shell
git commit -a -m "<comment that describes the changes>"
```

Be careful your commit doesn't include files you don't want to record
to the remote repository. As a rule, always check the status of your
local repository before you commit changes.

### Send changes to GitLab

To push all local changes to the remote repository:

```shell
git push <remote> <name-of-branch>
```

For example, to push your local commits to the `main` branch of the `origin` remote:

```shell
git push origin main
```

Sometimes Git does not allow you to push to a repository. Instead,
you must [force an update](../topics/git/git_rebase.md#force-pushing).

## Stash changes

Use `git stash` when you want to change to a different branch, and you
want to store changes that are not ready to be committed.

- Stash:

  ```shell
  git stash save
  # or
  git stash
  # or with a message
  git stash save "this is a message to display on the list"
  ```

- Apply stash to keep working on it:

  ```shell
  git stash apply
  # or apply a specific one from out stack
  git stash apply stash@{3}
  ```

- Every time you save a stash, it gets stacked. Use `list` to see all of the
  stashes.

  ```shell
  git stash list
  # or for more information (log methods)
  git stash list --stat
  ```

- To clean the stack, manually remove them:

  ```shell
  # drop top stash
  git stash drop
  # or
  git stash drop <name>
  # to clear all history we can use
  git stash clear
  ```

- Use one command to apply and drop:

  ```shell
  git stash pop
  ```

- If you have conflicts, either reset or commit your changes.
- Conflicts through `pop` don't drop a stash afterwards.

### Git stash sample workflow

1. Modify a file.
1. Stage file.
1. Stash it.
1. View the stash list.
1. Confirm no pending changes through `git status`.
1. Apply with `git stash pop`.
1. View list to confirm changes.

```shell
# Modify edit_this_file.rb file
git add .

git stash save "Saving changes from edit this file"

git stash list
git status

git stash pop
git stash list
git status
```

## Related topics

- [Add file from the UI](../user/project/repository/index.md#add-a-file-from-the-ui)
- [Add file from the Web IDE](../user/project/repository/web_editor.md#upload-a-file)
