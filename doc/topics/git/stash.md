---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
---

# Git Stash **(FREE)**

We use `git stash` to store our changes when they are not ready to be committed
and we need to change to a different branch.

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

- Every time we save a stash it gets stacked so by using `list` we can see all our
  stashes.

  ```shell
  git stash list
  # or for more information (log methods)
  git stash list --stat
  ```

- To clean our stack we need to manually remove them:

  ```shell
  # drop top stash
  git stash drop
  # or
  git stash drop <name>
  # to clear all history we can use
  git stash clear
  ```

- Apply and drop on one command:

  ```shell
  git stash pop
  ```

- If we meet conflicts we need to either reset or commit our changes.
- Conflicts through `pop` doesn't drop a stash afterwards.

## Git Stash sample workflow

1. Modify a file
1. Stage file
1. Stash it
1. View our stash list
1. Confirm no pending changes through status
1. Apply with pop
1. View list to confirm changes

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
