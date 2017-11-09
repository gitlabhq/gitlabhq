---
comments: false
---

# Git Stash

----------

We use git stash to store our changes when they are not ready to be committed
and we need to change to a different branch.

* Stash
```
git stash save
# or
git stash
# or with a message
git stash save "this is a message to display on the list"
```

* Apply stash to keep working on it
```
git stash apply
# or apply a specific one from out stack
git stash apply stash@{3}
```

----------

* Every time we save a stash it gets stacked so by using list we can see all our
stashes.

```
git stash list
# or for more information (log methods)
git stash list --stat
```

* To clean our stack we need to manually remove them.

```
# drop top stash
git stash drop
# or
git stash drop <name>
# to clear all history we can use
git stash clear
```

----------

* Apply and drop on one command

```
  git stash pop
```

* If we meet conflicts we need to either reset or commit our changes.

* Conflicts through `pop` will not drop a stash afterwards.

----------

## Git Stash

1. Modify a file
2. Stage file
3. Stash it
4. View our stash list
5. Confirm no pending changes through status
5. Apply with pop
6. View list to confirm changes

----------

## Commands

```
# Modify edit_this_file.rb file
git add .

git stash save "Saving changes from edit this file"

git stash list
git status

git stash pop
git stash list
git status
```
