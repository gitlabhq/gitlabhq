---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Git stash **(FREE ALL)**

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

## Git stash sample workflow

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
