---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Roll back commits **(FREE ALL)**

In Git, if you make a mistake, you can undo or roll back your changes.
For more details, see [Undo options](numerous_undo_possibilities_in_git/index.md).

## Undo commits by removing them

- Undo your last commit and put everything back in the staging area:

  ```shell
  git reset --soft HEAD^
  ```

- Add files and change the commit message:

  ```shell
  git commit --amend -m "New Message"
  ```

- Undo the last change and remove all other changes,
  if you did not push yet:

  ```shell
  git reset --hard HEAD^
  ```

- Undo the last change and remove the last two commits,
  if you did not push yet:

  ```shell
  git reset --hard HEAD^^
  ```

### Git reset sample workflow

The following is a common Git reset workflow:

1. Edit a file.
1. Check the status of the branch:

   ```shell
   git status
   ```

1. Commit the changes to the branch with a wrong commit message:

   ```shell
   git commit -am "kjkfjkg"
   ```

1. Check the Git log:

   ```shell
   git log
   ```

1. Amend the commit with the correct commit message:

   ```shell
   git commit --amend -m "New comment added"
   ```

1. Check the Git log again:

   ```shell
   git log
   ```

1. Soft reset the branch:

   ```shell
   git reset --soft HEAD^
   ```

1. Check the Git log again:

   ```shell
   git log
   ```

1. Pull updates for the branch from the remote:

   ```shell
   git pull origin <branch>
   ```

1. Push changes for the branch to the remote:

   ```shell
   git push origin <branch>
   ```

## Undo commits with a new replacement commit

```shell
git revert <commit-sha>
```

## The difference between `git revert` and `git reset`

- The `git reset` command removes the commit. The `git revert` command removes the changes but leaves the commit.
- The `git revert` command is safer, because you can revert a revert.

```shell
# Changed file
git commit -am "bug introduced"
git revert HEAD
# New commit created reverting changes
# Now we want to re apply the reverted commit
git log # take hash from the revert commit
git revert <rev commit hash>
# reverted commit is back (new commit created again)
```
