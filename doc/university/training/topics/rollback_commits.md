---
comments: false
---

# Rollback Commits

## Undo Commits

- Undo last commit putting everything back into the staging area:

  ```sh
  git reset --soft HEAD^
  ```

- Add files and change message with:

  ```sh
  git commit --amend -m "New Message"
  ```

- Undo last and remove changes:

  ```sh
  git reset --hard HEAD^
  ```

- Same as last one but for two commits back:

  ```sh
  git reset --hard HEAD^^
  ```

**Don't reset after pushing**

## Reset Workflow

1. Edit file again 'edit_this_file.rb'
1. Check status
1. Add and commit with wrong message
1. Check log
1. Amend commit
1. Check log
1. Soft reset
1. Check log
1. Pull for updates
1. Push changes

## Commands

```sh
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

## Note

- git revert vs git reset
- Reset removes the commit while revert removes the changes but leaves the commit
- Revert is safer considering we can revert a revert

```sh
# Changed file
git commit -am "bug introduced"
git revert HEAD
# New commit created reverting changes
# Now we want to re apply the reverted commit
git log # take hash from the revert commit
git revert <rev commit hash>
# reverted commit is back (new commit created again)
```
