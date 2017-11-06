---
comments: false
---

# Cherry Pick

----------

## Cherry Pick

- Given an existing commit on one branch, apply the change to another branch
- Useful for backporting bug fixes to previous release branches
- Make the commit on the master branch and pick in to stable

----------

## Cherry Pick

1. Check out a new 'stable' branch from 'master'
1. Change back to 'master'
1. Edit '`cherry_pick.rb`' and commit the changes.
1. Check commit log to get the commit SHA
1. Check out the 'stable' branch
1. Cherry pick the commit using the SHA obtained earlier

----------

## Commands

```bash
git checkout master
git checkout -b stable
git checkout master

# Edit `cherry_pick.rb`
git add cherry_pick.rb
git commit -m 'Fix bugs in cherry_pick.rb'
git log
# Copy commit SHA
git checkout stable

git cherry-pick <commit SHA>
```
