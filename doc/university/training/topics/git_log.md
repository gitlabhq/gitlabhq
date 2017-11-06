---
comments: false
---

# Git Log

----------

Git log lists commit history. It allows searching and filtering.

* Initiate log
```
git log
```

* Retrieve set number of records:
```
git log -n 2
```

* Search commits by author. Allows user name or a regular expression.
```
git log --author="user_name"
```

----------

* Search by comment message.
```
git log --grep="<pattern>"
```

* Search by date
```
git log --since=1.month.ago --until=3.weeks.ago
```


----------

## Git Log Workflow

1. Change to workspace directory
2. Clone the multi runner projects
3. Change to project dir
4. Search by author
5. Search by date
6. Combine

----------

## Commands

```
cd ~/workspace
git clone git@gitlab.com:gitlab-org/gitlab-runner.git
cd gitlab-runner
git log --author="Travis"
git log --since=1.month.ago --until=3.weeks.ago
git log --since=1.month.ago --until=1.day.ago --author="Travis"
```
