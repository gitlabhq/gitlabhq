# How to add an image

Using your standard tool for copying files (e.g. Finder in Mac OS, or Explorer
in Windows, or...), put the image file into the GitLab project. You can find the
project as a regular folder in your files.

Go to your [shell](command-line-commands.md), and move into the folder of your
Gitlab project. This usually means running the following command until you get
to the desired destination:

```
cd NAME-OF-FOLDER-YOU'D-LIKE-TO-OPEN
```

Check if your image is actually present in the directory (if you are in Windows,
use `dir` instead):

```
ls
```

You should see the name of the image in the list shown.

Check the status:

```
git status
```

Your image's name should appear in red, so `git` took notice of it! Now add it
to the repository:

```
git add NAME-OF-YOUR-IMAGE
```

Check the status again, your image's name should have turned green:

```
git status
```

Commit:

```
git commit -m "DESCRIBE COMMIT IN A FEW WORDS"
```

Now you can push (send) your changes (in the branch NAME-OF-BRANCH) to GitLab
(the git remote named 'origin'):

```
git push origin NAME-OF-BRANCH
```

Your image will be added to your branch in your repository in GitLab.
