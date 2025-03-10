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

## Mark for deletion

You should avoid direct calls to hard delete classes, as this can lead to unintended data loss.

{{< tabs >}}

{{< tab title="Projects" >}}

```ruby
Projects::MarkForDeletionService.new(project, current_user).execute
```

{{< /tab >}}

{{< tab title="Groups" >}}

```ruby
Groups::MarkForDeletionService.new(group, current_user).execute
```

{{< /tab >}}

{{< /tabs >}}

## Hard deletion

If you must delete data, use the following classes to hard delete from the codebase.

{{< tabs >}}

{{< tab title="Projects" >}}

```ruby
Projects::DestroyService.new(project, user, {}).execute

ProjectDestroyWorker.perform_async(project_id, user_id, params)
```

{{< /tab >}}

{{< tab title="Groups" >}}

```ruby
Groups::MarkForDeletionService.new(group, current_user).execute

GroupDestroyWorker.new.perform(group_id, user_id)
```

{{< /tab >}}

{{< /tabs >}}
