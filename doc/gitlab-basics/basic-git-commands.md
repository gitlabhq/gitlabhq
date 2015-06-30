# Basic Git commands

* Go to the master branch to pull the latest changes from there
```
git checkout master
```

* Download the latest changes in the project, so that you work on an up-to-date copy (this is important to do every time you work on a project), while you setup tracking branches
```
git pull REMOTE NAME-OF-BRANCH -u
```
(REMOTE: origin) (NAME-OF-BRANCH: could be "master" or an existing branch)

* Create a branch (remember that spaces won't be recognized, you need to use a hyphen or underscore)
```
git checkout -b NAME-OF-BRANCH
```

* Work on a branch that has already been created
```
git checkout NAME-OF-BRANCH
```

* To see the changes you've made (it's important to be aware of what's happening and what's the status of your changes)
```
git status
```

* Add changes to commit (you'll be able to see your changes in red when you type "git status")
```
git add CHANGES IN RED
git commit -m "DESCRIBE THE INTENTION OF THE COMMIT"
```

* Send changes to gitlab.com
```
git push origin NAME-OF-BRANCH
```

* Throw away all changes in the Git repository, but leave unstaged things
```
git checkout .
```

* Delete all changes in the Git repository, including untracked files
```
git clean -f
```

* Remove all the changes that you don't want to send to gitlab.com
```
git add NAME-OF-FILE -all
```

* Merge created branch with master branch. You need to be in the created branch
```
git checkout NAME-OF-BRANCH
git merge master
```
