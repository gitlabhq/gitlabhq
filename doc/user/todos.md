---
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/todos.html'
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# To-Do List **(FREE)**

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

## Search the To-Do List

You can search your To-Do List by `to do` and `done`.

You can filter to-do items per project, author, type, and action.
Also, you can sort them by [**Label priority**](project/labels.md#set-label-priority),
**Last created**, and **Oldest created**.

## Actions that create to-do items

Many to-do items are created automatically.
A to-do item is added to your To-Do List when:

- An issue or merge request is assigned to you.
- You're [mentioned](discussions/index.md#mentions) in the description or
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
- [In GitLab 15.8](https://gitlab.com/gitlab-org/gitlab/-/issues/374725) and later,
  a member access request is raised for a group or project you're an owner of.

When several actions occur for the same user on the same object,
GitLab displays the first action as a single to-do item.
To change this behavior, enable
[multiple to-do items per object](#multiple-to-do-items-per-object).

To-do items aren't affected by [GitLab notification email settings](profile/notifications.md).

### Multiple to-do items per object **(FREE SELF)**

<!-- When the feature flag is removed, integrate this topic into the one above. -->

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/28355) in GitLab 13.8 [with a flag](../administration/feature_flags.md) named `multiple_todos`. Disabled by default.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82470) in GitLab 14.9: only mentions create multiple to-do items.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per user,
ask an administrator to [enable the feature flag](../administration/feature_flags.md) named `multiple_todos`.
On GitLab.com, this feature is not available.
The feature is not ready for production use.

When you enable this feature:

- Every time you're mentioned, GitLab creates a new to-do item for you.
- Other [actions that create to-do items](#actions-that-create-to-do-items)
  create one to-do item per action type on the issue, MR, and so on.

## Create a to-do item

You can manually add an item to your To-Do List.

1. Go to your:

   - [Issue](project/issues/index.md)
   - [Merge request](project/merge_requests/index.md)
   - [Epic](group/epics/index.md)
   - [Design](project/issues/design_management.md)
   - [Incident](../operations/incident_management/incidents.md)

1. On the right sidebar, at the top, select **Add a to do**.

   ![Adding a to-do item from the issuable sidebar](img/todos_add_todo_sidebar_v14_1.png)

## Create a to-do item by mentioning someone

You can create a to-do item by mentioning someone anywhere except for a code block. Mentioning a user many times in one message only creates one to-do item.

For example, from the following comment, everyone except `frank` gets a to-do item created for them:

````markdown
@alice What do you think? cc: @bob

- @carol can you please have a look?

> @dan what do you think?

Hey @erin, this is what they said:

```
Hi, please message @frank :incoming_envelope:
```
````

## Actions that mark a to-do item as done

Any action to an issue, merge request, or epic marks its
corresponding to-do item as done.

Actions that dismiss to-do items include:

- Changing the assignee
- Changing the milestone
- Closing the issue or merge request
- Adding or removing a label
- Commenting on the issue
- Resolving a [design discussion thread](project/issues/design_management.md#resolve-a-discussion-thread-on-a-design)

If someone else closes, merges, or takes action on an issue, merge request, or
epic, your to-do item remains pending.

## Mark a to-do item as done

You can manually mark a to-do item as done.

There are two ways to do this:

- In the To-Do List, to the right of the to-do item, select **Mark as done** (**{check}**).
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
