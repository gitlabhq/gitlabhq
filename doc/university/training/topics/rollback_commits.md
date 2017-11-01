---
comments: false
---

# Rollback Commits

----------

## Undo Commits

* Undo last commit putting everything back into the staging area.
```
git reset --soft HEAD^
```

* Add files and change message with:
```
git commit --amend -m "New Message"
```

----------

* Undo last and remove changes
```
git reset --hard HEAD^
```

* Same as last one but for two commits back
```
git reset --hard HEAD^^
```

** Don't reset after pushing **

----------

## Reset Workflow

1. Edit file again 'edit_this_file.rb'
2. Check status
3. Add and commit with wrong message
4. Check log
5. Amend commit
6. Check log
7. Soft reset
8. Check log
9. Pull for updates
10. Push changes


----------

## Commands

```
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

----------

## Note

* git revert vs git reset
* Reset removes the commit while revert removes the changes but leaves the commit
* Revert is safer considering we can revert a revert

```
# Changed file
git commit -am "bug introduced"
git revert HEAD
# New commit created reverting changes
# Now we want to re apply the reverted commit
git log # take hash from the revert commit
git revert <rev commit hash>
# reverted commit is back (new commit created again)
```
