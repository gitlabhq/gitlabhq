# GitLab To-Do List

> [Introduced][ce-2817] in GitLab 8.5.

When you log into GitLab, you normally want to see where you should spend your
time, take some action, or know what you need to keep an eye on without
a huge pile of e-mail notifications. GitLab is where you do your work,
so being able to get started quickly is important.

Your To-Do List offers a chronological list of items that are waiting for your input, all
in a simple dashboard.

![To Do screenshot showing a list of items to check on](img/todos_index.png)

You can quickly access your To-Do List by clicking the checkmark icon next to the
search bar in the top navigation. If the count is:

- Less than 100, the number in blue is the number of To-Do items.
- 100 or more, the number displays as 99+. The exact number displays
  on the To-Do List.
you still have open. Otherwise, the number displays as 99+. The exact number
displays on the To-Do List.

![To Do icon](img/todos_icon.png)

## What triggers a To Do

A To Do displays on your To-Do List when:

- An issue or merge request is assigned to you
- You are `@mentioned` in the description or comment of an:
  - Issue
  - Merge Request
  - Epic **(ULTIMATE)**
- You are `@mentioned` in a comment on a commit
- A job in the CI pipeline running for your merge request failed, but this
  job is not allowed to fail
- An open merge request becomes unmergeable due to conflict, and you are either: 
  - The author 
  - Have set it to automatically merge once the pipeline succeeds

To-do triggers are not affected by [GitLab Notification Email settings](notifications.md).

NOTE: **Note:**
When a user no longer has access to a resource related to a To Do (like an issue, merge request, project, or group) the related To-Do items are deleted within the next hour for security reasons. The delete is delayed to prevent data loss, in case the user's access was revoked by mistake.

### Directly addressing a To Do

> [Introduced][ce-7926] in GitLab 9.0.

If you are mentioned at the start of a line, the To Do you receive will be listed
as 'directly addressed'. For example, in this comment:

```markdown
@alice What do you think? cc: @bob

- @carol can you please have a look?

>>>
@dan what do you think?
>>>

@erin @frank thank you!
```

The people receiving directly addressed To-Do items are `@alice`, `@erin`, and
`@frank`. Directly addressed To-Do items only differ from mentions in their type
for filtering purposes; otherwise, they appear as normal.

### Manually creating a To Do

You can also add the following to your To-Do List by clicking the **Add a To Do** button on an:

- Issue
- Merge Request
- Epic **(ULTIMATE)**

![Adding a To Do from the issuable sidebar](img/todos_add_todo_sidebar.png)

## Marking a To Do as done

Any action to the following will mark the corresponding To Do as done:

- Issue
- Merge Request
- Epic **(ULTIMATE)**

Actions that dismiss To-Do items include:

- Changing the assignee
- Changing the milestone
- Adding/removing a label
- Commenting on the issue

Your To-Do List is personal, and items are only marked as done if the action comes from
you. If you close the issue or merge request, your To Do is automatically
marked as done.

To prevent other users from closing issues without you being notified, if someone else closes, merges, or takes action on the any of the following, your To Do will remain pending:

- Issue
- Merge request
- Epic **(ULTIMATE)**

There is just one To Do for each of these, so mentioning a user a hundred times in an issue will only trigger one To Do.

If no action is needed, you can manually mark the To Do as done by clicking the
corresponding **Done** button, and it will disappear from your To-Do List.

![A To Do in the To-Do List](img/todo_list_item.png)

You can also mark a To Do as done by clicking the **Mark as done** button in the sidebar of the following:

- Issue
- Merge Request
- Epic **(ULTIMATE)**

![Mark as done from the issuable sidebar](img/todos_mark_done_sidebar.png)

You can mark all your To-Do items as done at once by clicking the **Mark all as
done** button.

## Filtering your To-Do List

There are four kinds of filters you can use on your To-Do List.

| Filter  | Description |
| ------- | ----------- |
| Project | Filter by project |
| Group   | Filter by group |
| Author  | Filter by the author that triggered the To Do |
| Type    | Filter by issue, merge request, or epic **(ULTIMATE)** |
| Action  | Filter by the action that triggered the To Do |

You can also filter by more than one of these at the same time. The possible Actions are `Any Action`, `Assigned`, `Mentioned`, `Added`, `Pipelines`, and `Directly Addressed`, [as described above](#what-triggers-a-to-do).

[ce-2817]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2817
[ce-7926]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/7926
