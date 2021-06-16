---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
---

# Unstage **(FREE)**

- To remove files from stage use reset HEAD where HEAD is the last commit of the current branch. This unstages the file but maintain the modifications.

  ```shell
  git reset HEAD <file>
  ```

- To revert the file back to the state it was in before the changes we can use:

  ```shell
  git checkout -- <file>
  ```

- To remove a file from disk and repository, use `git rm`. To remove a directory, use the `-r` flag:

  ```shell
  git rm '*.txt'
  git rm -r <dirname>
  ```

- If we want to remove a file from the repository but keep it on disk, say we forgot to add it to our `.gitignore` file then use `--cache`:

  ```shell
  git rm <filename> --cache
  ```
