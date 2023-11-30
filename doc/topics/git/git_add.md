---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Git add **(FREE ALL)**

Before you commit content, add it to the staging area.

- Add a list of files:

  ```shell
  git add <files>
  ```

- Add all files, including deleted ones:

  ```shell
  git add -A
  ```

- Add all text files in current directory:

  ```shell
  git add *.txt
  ```

- Add all text files in the project:

  ```shell
  git add "*.txt*"
  ```

- Add all files in a directory called `views/layouts`:

  ```shell
  git add views/layouts/
  ```
