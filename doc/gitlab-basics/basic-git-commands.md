# Basic Git commands

It's important to know some basic commands to work on your shell

* Go into a project, directory or file to work in it
```
cd NAME-OF-PROJECT-OR-FILE
```

* Go back one directory or file
```
cd ../
```

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

* To see what’s in the directory that you are in
```
ls
```

* Create a directory
```
mkdir NAME-OF-YOUR-DIRECTORY
```

* Create a README.md or file in directory
```
touch README.md
nano README.md
#### ADD YOUR INFORMATION
#### Press: control + X
#### Type: Y
#### Press: enter
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

* Remove a file
```
rm NAME-OF-FILE
```

* Remove a directory and all of its contents
```
rm -rf NAME-OF-DIRECTORY
```

* Throw away all changes in the Git repository, but leave unstaged things
```
git checkout .
```

* Delete all changes in the Git repository, including untracked files
```
git clean -f
```

* View history in terminal
```
history
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

* Carry out commands for which the account you are using lacks authority. (You will be asked for an administrator’s password)
```
sudo
```
