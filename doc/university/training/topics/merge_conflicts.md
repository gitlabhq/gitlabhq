---
comments: false
---

# Merge conflicts

----------

- Happen often
- Learning to fix conflicts is hard
- Practice makes perfect
- Force push after fixing conflicts. Be careful!

----------

## Merge conflicts

1. Checkout a new branch and edit `conflicts.rb`. Add 'Line4' and 'Line5'.
2. Commit and push
3. Checkout master and edit `conflicts.rb`. Add 'Line6' and 'Line7' below 'Line3'.
4. Commit and push to master
5. Create a merge request and watch it fail
6. Rebase our new branch with master
7. Fix conflicts on the `conflicts.rb` file.
8. Stage the file and continue rebasing
9. Force push the changes
10. Finally continue with the Merge Request

----------

## Commands

```
git checkout -b conflicts_branch

# vi conflicts.rb
# Add 'Line4' and 'Line5'

git commit -am "add line4 and line5"
git push origin conflicts_branch

git checkout master

# vi conflicts.rb
# Add 'Line6' and 'Line7'
git commit -am "add line6 and line7"
git push origin master
```

Create a merge request on the GitLab web UI. You'll see a conflict warning.

```
git checkout conflicts_branch
git fetch
git rebase master

# Fix conflicts by editing the files.

git add conflicts.rb
# No need to commit this file

git rebase --continue

# Remember that we have rewritten our commit history so we
# need to force push so that our remote branch is restructured
git push origin conflicts_branch -f
```
----------

## Note
* When to use 'git merge' and when to use 'git rebase'
* Rebase when updating your branch with master
* Merge when bringing changes from feature to master
* Reference: https://www.atlassian.com/git/tutorials/merging-vs-rebasing/
