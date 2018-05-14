# GitLab Todos

> [Introduced][ce-2817] in GitLab 8.5.

When you log into GitLab, you normally want to see where you should spend your
time and take some action, or what you need to keep an eye on. All without the
mess of a huge pile of e-mail notifications. GitLab is where you do your work,
so being able to get started quickly is very important.

Todos is a chronological list of to-dos that are waiting for your input, all
in a simple dashboard.

![Todos screenshot showing a list of items to check on](img/todos_index.png)

---

You can quickly access the Todos dashboard using the bell icon next to the
search bar in the upper right corner. The number in blue is the number of Todos
you still have open if the count is < 100, else it's 99+. The exact number
will still be shown in the body of the _To do_ tab.

![Todos icon](img/todos_icon.png)

## What triggers a Todo

A Todo appears in your Todos dashboard when:

- an issue or merge request is assigned to you,
- you are `@mentioned` in an issue or merge request, be it the description of
  the issue/merge request or in a comment,
- you are `@mentioned` in a comment on a commit,
- a job in the CI pipeline running for your merge request failed, but this
  job is not allowed to fail.

### Directly addressed Todos

> [Introduced][ce-7926] in GitLab 9.0.

If you are mentioned at the start of a line, the todo you receive will be listed
as 'directly addressed'. For instance, in this comment:

```markdown
@alice What do you think? cc: @bob

- @carol can you please have a look?

>>>
@dan what do you think?
>>>

@erin @frank thank you!
```

The people receiving directly addressed todos are `@alice`, `@erin`, and
`@frank`. Directly addressed todos only differ from mention todos in their type,
for filtering; otherwise, they appear as normal.

### Manually creating a Todo

You can also add an issue or merge request to your Todos dashboard by clicking
the "Add todo" button in the issue or merge request sidebar.

![Adding a Todo from the issuable sidebar](img/todos_add_todo_sidebar.png)

## Marking a Todo as done

Any action to the corresponding issue or merge request will mark your Todo as
**Done**. Actions that dismiss Todos include:

- changing the assignee
- changing the milestone
- adding/removing a label
- commenting on the issue

---

Todos are personal, and they're only marked as done if the action is coming from
you. If you close the issue or merge request, your Todo will automatically
be marked as done.

If someone else closes, merges, or takes action on the issue or merge
request, your Todo will remain pending. This prevents other users from closing issues without you being notified.

There is just one Todo per issue or merge request, so mentioning a user a
hundred times in an issue will only trigger one Todo.

---

If no action is needed, you can manually mark the Todo as done by clicking the
corresponding **Done** button, and it will disappear from your Todo list.

![A Todo in the Todos dashboard](img/todo_list_item.png)

A Todo can also be marked as done from the issue or merge request sidebar using
the "Mark todo as done" button.

![Mark todo as done from the issuable sidebar](img/todos_mark_done_sidebar.png)

You can mark all your Todos as done at once by clicking on the **Mark all as
done** button.

## Filtering your Todos

There are four kinds of filters you can use on your Todos dashboard.

| Filter  | Description |
| ------- | ----------- |
| Project | Filter by project |
| Author  | Filter by the author that triggered the Todo |
| Type    | Filter by issue or merge request |
| Action  | Filter by the action that triggered the Todo |

You can also filter by more than one of these at the same time. The possible Actions are `Any Action`, `Assigned`, `Mentioned`, `Added`, `Pipelines`, and `Directly Addressed`, [as described above](#what-triggers-a-todo).

[ce-2817]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2817
[ce-7926]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/7926
