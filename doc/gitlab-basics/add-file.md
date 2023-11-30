---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: howto
---

# Use Git to add a file to a repository **(FREE ALL)**

To add a new file from the command line:

1. Open a terminal.
1. Change directories until you are in your project's folder.

   ```shell
   cd my-project
   ```

1. Choose a Git branch to work in.
   - To create a branch: `git checkout -b <branchname>`
   - To switch to an existing branch: `git checkout <branchname>`

1. Copy the file you want to add into the directory where you want to add it.
1. Confirm that your file is in the directory:
   - Windows: `dir`
   - All other operating systems: `ls`

   The filename should be displayed.
1. Check the status of the file:

   ```shell
   git status
   ```

   The filename should be in red. The file is in your file system, but Git isn't tracking it yet.
1. Tell Git to track the file:

   ```shell
   git add <filename>
   ```

1. Check the status of the file again:

   ```shell
   git status
   ```

   The filename should be green. The file is tracked locally by Git, but
   has not been committed and pushed.
1. Commit the file to your local copy of the project's Git repository:

   ```shell
   git commit -m "Describe the reason for your commit here"
   ```

1. Push your changes from your copy of the repository to GitLab.
   In this command, `origin` refers to the remote copy of the repository.
   Replace `<branchname>` with the name of your branch:

   ```shell
   git push origin <branchname>
   ```

1. Git prepares, compresses, and sends the data. Lines from the remote repository
   start with `remote:`:

   ```plaintext
   Enumerating objects: 9, done.
   Counting objects: 100% (9/9), done.
   Delta compression using up to 10 threads
   Compressing objects: 100% (5/5), done.
   Writing objects: 100% (5/5), 1.84 KiB | 1.84 MiB/s, done.
   Total 5 (delta 3), reused 0 (delta 0), pack-reused 0
   remote:
   remote: To create a merge request for <branchname>, visit:
   remote:   https://gitlab.com/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=<branchname>
   remote:
   To https://gitlab.com/gitlab-org/gitlab.git
    * [new branch]                <branchname> -> <branchname>
   branch '<branchname>' set up to track 'origin/<branchname>'.
   ```

Your file is copied from your local copy of the repository to the remote
repository.

To create a merge request, copy the link sent back from the remote
repository and paste it into a browser window.

## Related topics

- [Add file from the UI](../user/project/repository/index.md#add-a-file-from-the-ui)
- [Add file from the Web IDE](../user/project/repository/web_editor.md#upload-a-file)
- [`git add` options](../topics/git/git_add.md)
