---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: howto
---

# Add a file to a repository **(FREE)**

Adding files to a repository is a small, but key task. Bringing files in to a repository,
such as code, images, or documents, allows them to be tracked by Git, even though they
may have been created elsewhere.

You can add a file to a repository in your [terminal](#add-a-file-using-the-command-line), and
then push to GitLab. You can also use the [web interface](../user/project/repository/web_editor.md#upload-a-file),
which may be a simpler solution.

If you need to create a file first, for example a `README.md` text file, that can
also be done from the [terminal](command-line-commands.md#create-a-text-file-in-the-current-directory) or
[web interface](../user/project/repository/web_editor.md#create-a-file).

## Add a file using the command line

Open a [terminal/shell](command-line-commands.md), and change into the folder of your
GitLab project. This usually means running the following command until you get
to the desired destination:

```shell
cd <destination folder>
```

[Create a new branch](create-branch.md) to add your file into. Submitting changes directly
to the default branch should be avoided unless your project is very small and you're the
only person working on it.

You can also [switch to an existing branch](start-using-git.md#switch-to-a-branch)
if you have one already.

Using your standard tool for copying files (for example, Finder in macOS, or File Explorer
on Windows), put the file into a directory within the GitLab project.

Check if your file is actually present in the directory (if you're on Windows,
use `dir` instead):

```shell
ls
```

You should see the name of the file in the list shown.

Check the status:

```shell
git status
```

Your file's name should appear in red, so `git` took notice of it! Now add it
to the repository:

```shell
git add <name of file>
```

Check the status again, your file's name should have turned green:

```shell
git status
```

Commit (save) your file to the repository:

```shell
git commit -m "DESCRIBE COMMIT IN A FEW WORDS"
```

Now you can push (send) your changes (in the branch `<branch-name>`) to GitLab
(the Git remote named 'origin'):

```shell
git push origin <branch-name>
```

Your image is added to your branch in your repository in GitLab.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
