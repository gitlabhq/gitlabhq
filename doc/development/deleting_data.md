---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Data deletion guidelines
---

In order to minimize the risk of accidental data loss, GitLab provides guidelines for how to safely use deletion operations in the codebase.

Generally, there are two ways to delete data:

- Mark for deletion: Identifies data for removal at a future date. This is the preferred approach.
- Hard deletion: Immediately and permanently removes data.

## Avoid direct hard deletion

Direct calls to hard delete classes should be avoided because it can lead to unintended data loss.
Specifically, avoid invoking the following classes:

- `Projects::DestroyService`
- `ProjectDestroyWorker`
- `Groups::DestroyService`
- `GroupDestroyWorker`

## Recommended approach

### For projects

Instead of using `Projects::DestroyService`, use `Projects::MarkForDeletionService`. 

```ruby
Projects::MarkForDeletionService.new(project, current_user).execute
```

### For groups

Instead of using `Groups::DestroyService`, use `Groups::MarkForDeletionService`. 

```ruby
Groups::MarkForDeletionService.new(group, current_user).execute
```
