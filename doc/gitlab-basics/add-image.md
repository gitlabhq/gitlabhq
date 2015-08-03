# How to add an image

The following are the steps to add images to your repository in
GitLab:

Find the image that you’d like to add.

In your computer files, find the GitLab project to which you'd like to add the image
(you'll find it as a regular file). Click on every file until you find exactly where you'd
like to add the image. There, paste the image.

Go to your [shell](command-line-commands.md), and add the following commands:

To find the correct file, add this command for every file that you'd like to open until
you reach the file where you added your image:
```
cd NAME-OF-FILE-YOU'D-LIKE-TO-OPEN
```

Create a new branch:
```
git checkout -b NAME-OF-BRANCH
```

Check if your image was correctly added to the file:
```
ls
```

You should see the name of the image in the list shown.

Go back one file:
```
cd ../
```

Check the status and you should see your image’s name in red:
```
git status
```

Add your changes:
```
git add NAME-OF-YOUR-IMAGE
```

Check the status and you should see your image’s name in green:
```
git status
```

Add the commit:
```
git commit -m “DESCRIBE COMMIT IN A FEW WORDS”
```

Now you can push (send) your changes (in the branch NAME-OF-BRANCH) to GitLab (the git remote named 'origin'):
```
git push origin NAME-OF-BRANCH
```

Your image should've been added to your repository in GitLab.
