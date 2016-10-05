
# Git Commit

The Git commit command stores staged work to the history with a timestamp, author and log message.

## Make changes

The first thing you need in order to commit work is some changes to files in a Git repository.

These are some of the changes you can commit:
- Adding a file or directory
- Deleting a file of directory
- Modifying a file or directory path (treated as a delete and an add)
- Modifying the contents of a file

Git is great for working with text files like source code and can track the individual lines that have changed in a file. If you would like to track large or frequently changing binary files use Git Large File Storage (LFS).

## Stage work

Once you have changes that you would like to commit to the history you need to tell Git which changes you want to track or stage for the next commit. You don't have to stage all the changes at once, to stage individual files use the `git add` command and list the files and directories afterwards like this:

```bash
git add filename1 filename2
```

You can use operating system wildcards to make your job easier for example:

```bash
git add src/*.txt
```

If you want to add all file or folder additions and modifications you can run the following command (note this will not add any deleted files):

```bash
git add .
```

git add -A
git add filename filename

git rm --cached filename

## Reset staged work

git reset all

git reset filename filename

## Commit staged work

git commit

git commit -m

## View the commit log
