---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
---

# Git Add **(FREE)**

Adds content to the index or staging area.

- Adds a list of file:

  ```shell
  git add <files>
  ```

- Adds all files including deleted ones:

  ```shell
  git add -A
  ```

- Add all text files in current dir:

  ```shell
  git add *.txt
  ```

- Add all text file in the project:

  ```shell
  git add "*.txt*"
  ```

- Adds all files in directory:

  ```shell
  git add views/layouts/
  ```
