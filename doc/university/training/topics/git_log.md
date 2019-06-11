---
comments: false
---

# Git Log

Git log lists commit history. It allows searching and filtering.

- Initiate log:

    ```sh
    git log
    ```

- Retrieve set number of records:

    ```sh
    git log -n 2
    ```

- Search commits by author. Allows user name or a regular expression.

    ```sh
    git log --author="user_name"
    ```

- Search by comment message:

    ```sh
    git log --grep="<pattern>"
    ```

- Search by date:

    ```sh
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

```sh
cd ~/workspace
git clone git@gitlab.com:gitlab-org/gitlab-runner.git
cd gitlab-runner
git log --author="Travis"
git log --since=1.month.ago --until=3.weeks.ago
git log --since=1.month.ago --until=1.day.ago --author="Travis"
```
