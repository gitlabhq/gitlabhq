---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
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

1. Edit file again `edit_this_file.rb`.
1. Check status.
1. Add and commit with wrong message.
1. Check log.
1. Amend commit.
1. Check log.
1. Soft reset.
1. Check log.
1. Pull for updates.
1. Push changes.

```shell
# Change file edit_this_file.rb
git status
git commit -am "kjkfjkg"
git log
git commit --amend -m "New comment added"
git log
git reset --soft HEAD^
git log
git pull origin master
git push origin master
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
