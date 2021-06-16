---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
---

# Git Log **(FREE)**

Git log lists commit history. It allows searching and filtering.

- Initiate log:

  ```shell
  git log
  ```

- Retrieve set number of records:

  ```shell
  git log -n 2
  ```

- Search commits by author. Allows user name or a regular expression.

  ```shell
  git log --author="user_name"
  ```

- Search by comment message:

  ```shell
  git log --grep="<pattern>"
  ```

- Search by date:

  ```shell
  git log --since=1.month.ago --until=3.weeks.ago
  ```

## Git Log Workflow

1. Change to workspace directory
1. Clone the multi runner projects
1. Change to project dir
1. Search by author
1. Search by date
1. Combine

## Commands

```shell
cd ~/workspace
git clone git@gitlab.com:gitlab-org/gitlab-runner.git
cd gitlab-runner
git log --author="Travis"
git log --since=1.month.ago --until=3.weeks.ago
git log --since=1.month.ago --until=1.day.ago --author="Travis"
```
