---
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/todos.html'
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# To-Do List **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/2817) in GitLab 8.5.

Your *To-Do List* is a chronological list of items waiting for your input.
The items are known as *to-do items*.

You can use the To-Do List to track [actions](#actions-that-create-to-do-items) related to:

- [Issues](project/issues/index.md)
- [Merge requests](project/merge_requests/index.md)
- [Epics](group/epics/index.md)
- [Designs](project/issues/design_management.md)

## Access the To-Do List

To access your To-Do List:

On the top bar, in the top right, select To-Do List (**{task-done}**).

## Actions that create to-do items

Many to-do items are created automatically.
A to-do item is added to your To-Do List when:

- An issue or merge request is assigned to you.
- You're [mentioned](project/issues/issue_data_and_actions.md#mentions) in the description or
  comment of an issue, merge request, or epic.
- You are mentioned in a comment on a commit or design.
- The CI/CD pipeline for your merge request fails.
- An open merge request cannot be merged due to conflict, and one of the
  following is true:
  - You're the author.
  - You're the user that set the merge request to automatically merge after a
    pipeline succeeds.
- [In GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/issues/12136) and later, a
  merge request is removed from a
  [merge train](../ci/pipelines/merge_trains.md),
  and you're the user that added it.

When several actions occur for the same user on the same object,
GitLab displays the first action as a single to-do item.

To-do items aren't affected by [GitLab notification email settings](profile/notifications.md).

## Create a to-do item

You can manually add an item to your To-Do List.

1. Go to your:

   - [Issue](project/issues/index.md)
   - [Merge request](project/merge_requests/index.md)
   - [Epic](group/epics/index.md)
   - [Design](project/issues/design_management.md)

1. On the right sidebar, at the top, select **Add a to do**.

   ![Adding a to-do item from the issuable sidebar](img/todos_add_todo_sidebar_v14_1.png)

## Create a to-do item by directly addressing someone

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/7926) in GitLab 9.0.

You can create a to-do item by directly addressing someone at the start of a line.
For example, in the following comment:

```markdown
@alice What do you think? cc: @bob

- @carol can you please have a look?

>>>
@dan what do you think?
>>>

@erin @frank thank you!
```

The people who receive to-do items are `@alice`, `@erin`, and
`@frank`.

To view to-do items where a user was directly addressed, go to the To-Do List and
from the **Action** filter, select **Directly addressed**.

Mentioning a user many times only creates one to-do item.

## Actions that mark a to-do item as done

Any action to an issue, merge request, or epic marks its
corresponding to-do item as done.

Actions that dismiss to-do items include:

- Changing the assignee
- Changing the milestone
- Closing the issue or merge request
- Adding or removing a label
- Commenting on the issue
- Resolving a [design discussion thread](project/issues/design_management.md#resolve-design-threads)

If someone else closes, merges, or takes action on an issue, merge request, or
epic, your to-do item remains pending.

## Mark a to-do item as done

You can manually mark a to-do item as done.

There are two ways to do this:

- In the To-Do List, to the right of the to-do item, select **Done**.
- In the sidebar of an issue, merge request, or epic, select **Mark as done**.

  ![Mark as done from the sidebar](img/todos_mark_done_sidebar_v14_1.png)

## Mark all to-do items as done

You can mark all your to-do items as done at the same time.

In the To-Do List, in the top right, select **Mark all as done**.

## How a user's To-Do List is affected when their access changes

For security reasons, GitLab deletes to-do items when a user no longer has access to a related resource.
For example, if the user no longer has access to an issue, merge request, epic, project, or group,
GitLab deletes the related to-do items.

This process occurs in the hour after their access changes. Deletion is delayed to
prevent data loss, in case the user's access was accidentally revoked.
