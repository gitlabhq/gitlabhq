# How to add an image

The following are the steps to add images to your repository in
GitLab:

Find the image that you’d like to add.

In your computer files, find the GitLab project to which you'd like to add the image
(you'll find it as a regular file). Click on every file until you find exactly where you'd
like to add the image. There, paste the image.

Go to your [shell](command-line-commands.md), and add the following commands:

Add this command for every directory that you'd like to open:
```
cd NAME-OF-FILE-YOU'D-LIKE-TO-OPEN
```

Create a new branch:
```
git checkout -b NAME-OF-BRANCH
```

Check if your image was correctly added to the directory:
```
ls
```

You should see the name of the image in the list shown.

Move up the hierarchy through directories:
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

Your image will be added to your branch in your repository in GitLab. Create a [Merge Request](add-merge-request.md)
to integrate your changes to your project.
