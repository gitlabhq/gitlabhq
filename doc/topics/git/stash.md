---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Stash changes
---

Use `git stash` when you want to change to a different branch but you have
uncommitted changes that are not ready to be committed.

## Create stash entries

By default, `git stash` stores tracked changes in your working directory and any staged changes.
You can use options to control which changes are included.

- To stash tracked changes:

  ```shell
  git stash
  ```

- To stash changes with a message:

  ```shell
  git stash push -m "describe your changes here"
  ```

- To stash changes but keep staged changes in your working directory:

  ```shell
  git stash push -k
  ```

  The `-k` (`--keep-index`) option stashes your changes but also keeps them in the working directory.
  Use this option when you want to temporarily save changes but keep working on them.

- To stash changes and include untracked files:

  ```shell
  git stash push -u
  ```

  The `-u` (`--include-untracked`) option also stashes files that Git is not yet tracking.
  Without this option, new files that have not been committed remain in your working directory.

- To stash only staged changes:

  ```shell
  git stash push -S
  ```

  The `-S` (`--staged`) option stashes only changes that are staged.
  Use this option when you want to save staged changes while you keep working on unstaged changes.

## Apply stash entries

If you make many changes after you stash your work, conflicts might
occur when you apply the stash. You must resolve these conflicts
before the changes can be applied.

- To apply the most recent stash entry and keep it in the stash:

  ```shell
  git stash apply
  ```

- To apply a specific stash entry:

  ```shell
  git stash apply stash@{3}
  ```

- To apply the most recent stash entry and remove it from the stash:

  ```shell
  git stash pop
  ```

## View stash entries

- To see all stash entries:

  ```shell
  git stash list
  ```

- To see stash entries with more detail:

  ```shell
  git stash list --stat
  ```

## Delete stash entries

- To delete the most recent stash entry:

  ```shell
  git stash drop
  ```

- To delete a specific stash entry:

  ```shell
  git stash drop <name>
  ```

- To delete all stash entries:

  ```shell
  git stash clear
  ```

## Example: Create and apply a stash entry

To try using Git stashing:

1. Modify a file in a Git repository.
1. Stash the modification:

   ```shell
   git stash push -m "Saving changes from edit"
   ```

1. View the stash list:

   ```shell
   git stash list
   ```

1. Confirm there are no pending changes:

   ```shell
   git status
   ```

1. Apply the stashed changes and remove the entry from the stash:

   ```shell
   git stash pop
   ```

1. View the stash list to confirm the entry was removed:

   ```shell
   git stash list
   ```

## Related topics

- [Official Git stash documentation](https://git-scm.com/docs/git-stash)
