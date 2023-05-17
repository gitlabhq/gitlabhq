---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Unstage a file in Git **(FREE)**

When you _stage_ a file in Git, you instruct Git to track changes to the file in
preparation for a commit. To instruct Git to disregard changes to a file, and not
include it in your next commit, _unstage_ the file.

- To remove files from stage use `reset HEAD`, where HEAD is the last commit of
  the current branch. This unstages the file but maintains the modifications.

  ```shell
  git reset HEAD <file>
  ```

- To revert the file back to the state it was in before the changes:

  ```shell
  git checkout -- <file>
  ```

- To remove a file from disk and repository, use `git rm`. To remove a directory, use the `-r` flag:

  ```shell
  git rm '*.txt'
  git rm -r <dirname>
  ```

- To keep a file on disk but remove it from the repository (such as a file you want
  to add to `.gitignore`), use the `rm` command with the `--cache` flag:

  ```shell
  git rm <filename> --cache
  ```
