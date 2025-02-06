---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Stash changes for later
---

Use `git stash` when you want to change to a different branch, and you want to store changes that are not ready to be
committed.

- To stash uncommitted changes without a message:

  ```shell
  git stash
  ```

- To stash uncommitted changes with a message:

  ```shell
  git stash save "this is a message to display on the list"
  ```

- To retrieve changes from the stash and apply them to your branch:

  ```shell
  git stash apply
  ```

- To apply a specific change from the stash to your branch:

  ```shell
  git stash apply stash@{3}
  ```

- To see all of the changes in the stash:

  ```shell
  git stash list
  ```

- To see a list of changes in that stash with more information:

  ```shell
  git stash list --stat
  ```

- To delete the most recently stashed change from the stash:

  ```shell
  git stash drop
  ```

- To delete a specific change from the stash:

  ```shell
  git stash drop <name>
  ```

- To delete all changes from the stash:

  ```shell
  git stash clear
  ```

- To apply the most recently stashed change and delete it from the stash:

  ```shell
  git stash pop
  ```

If you make a lot of changes after stashing your changes, conflicts might occur when you apply
these previous changes back to your branch. You must resolve these conflicts before the changes can be applied
from the stash.

## Git stash sample workflow

To try using Git stashing yourself:

1. Modify a file in a Git repository.
1. Stash the modification:

   ```shell
   git stash save "Saving changes from edit this file"
   ```

1. View the stash list:

   ```shell
   git stash list
   ```

1. Confirm there are no pending changes:

   ```shell
   git status
   ```

1. Apply the stashed changes and drop the change from the stash:

   ```shell
   git stash pop
   ```

1. View stash list to confirm that the change was removed:

   ```shell
   git stash list
   ```
