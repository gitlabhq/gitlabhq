---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: howto
---

# Add a file to a repository **(FREE)**

Adding files to a repository is a small, but key, task. No matter where the code,
images, or documents were created, Git tracks them after you add them to your repository.

## Add an existing file

To add an existing file to your repository, either:

- Upload the file from the GitLab UI.
- Add a file to your repository from the command line, then push the file up to GitLab.

### From the UI

If you are unfamiliar with the command line, use the
[Web Editor](../user/project/repository/web_editor.md) to upload a file from the GitLab UI:

<!-- Original source for this list: doc/user/project/repository/web_editor.md#upload-a-file -->
<!-- For why we duplicated the info, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111072#note_1267429478 -->

1. On the top bar, select **Main menu > Projects** and find your project.
1. From the project dashboard or repository, next to the branch name, select the plus icon (**{plus}**).
1. From the dropdown list, select **Upload file**.
1. Complete the fields. To create a merge request with the uploaded file, ensure the **Start a new merge request with these changes** toggle is turned on.
1. Select **Upload file**.

### From the command line

To add a new file from the command line:

1. Open a terminal (or shell) window.
1. Use the "change directory" (`cd`) command to go to your GitLab project's folder.
   Run the `cd DESTINATION` command, changing `DESTINATION` to the location of your folder.
1. Choose a Git branch to work in. You can either:
   - [Create a new branch](../tutorials/make_first_git_commit/index.md#create-a-branch-and-make-changes)
     to add your file into. Don't submit changes directly to the default branch of your
     repository unless your project is very small and you're the only person working on it.
   - [Switch to an existing branch](start-using-git.md#switch-to-a-branch).
1. Copy the file into the appropriate directory in your project. Use your standard tool
   for copying files, such as Finder in macOS, or File Explorer in Windows.
1. In your terminal window, confirm that your file is present in the directory:
   - Windows: Use the `dir` command.
   - All other operating systems: Use the `ls` command.
   You should see the name of the file in the list shown.
1. Check the status of your file with the `git status` command. Your file's name
   should be red. Files listed in red are in your file system, but Git isn't tracking them yet.
1. Tell Git to track this file with the `git add FILENAME` command, replacing `FILENAME`
   with the name of your file.
1. Check the status of your file again with the `git status` command. Your file's name
   should be green. Files listed in green are tracked locally by Git, but still
   need to be committed and pushed.
1. Commit (save) your file to your local copy of your project's Git repository:

   ```shell
   git commit -m "DESCRIBE COMMIT IN A FEW WORDS"
   ```

1. Push (send) your changes from your copy of the repository, up to GitLab.
   In this command, `origin` refers to the copy of the repository stored at GitLab.
   Replace `BRANCHNAME` with the name of your branch:

   ```shell
   git push origin BRANCHNAME
   ```

1. Git prepares, compresses, and sends the data. Lines from the remote repository
   (here, GitLab) are prefixed with `remote:` like this:

   ```plaintext
   Enumerating objects: 9, done.
   Counting objects: 100% (9/9), done.
   Delta compression using up to 10 threads
   Compressing objects: 100% (5/5), done.
   Writing objects: 100% (5/5), 1.84 KiB | 1.84 MiB/s, done.
   Total 5 (delta 3), reused 0 (delta 0), pack-reused 0
   remote:
   remote: To create a merge request for BRANCHNAME, visit:
   remote:   https://gitlab.com/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=BRANCHNAME
   remote:
   To https://gitlab.com/gitlab-org/gitlab.git
    * [new branch]                BRANCHNAME -> BRANCHNAME
   branch 'BRANCHNAME' set up to track 'origin/BRANCHNAME'.
   ```

Your file is now copied from your local copy of the repository, up to the remote
repository at GitLab. To create a merge request, copy the link sent back from the remote
repository and paste it into a browser window.

## Add a new file

To create a new file (like a `README.md` text file) in your repository, either:

- [Create the file](../user/project/repository/web_editor.md#create-a-file) from the GitLab UI.
- Create the file from the terminal.
