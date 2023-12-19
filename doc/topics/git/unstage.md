---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Unstage a file in Git **(FREE ALL)**

When you _stage_ a file in Git, you instruct Git to track changes to the file in
preparation for a commit. To disregard changes to a file, and not
include it in your next commit, _unstage_ the file.

## Unstage a file

- To remove files from staging, but keep your changes:

  ```shell
  git reset HEAD <file>
  ```

- To unstage the last three commits:

  ```shell
  git reset HEAD^3
  ```

- To unstage changes to a certain file from HEAD:

  ```shell
  git reset <filename>
  ```

After you unstage the file, to revert the file back to the state it was in before the changes:

```shell
git checkout -- <file>
```

## Remove a file

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
