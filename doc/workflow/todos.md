# GitLab ToDos

>**Note:** This feature was [introduced][ce-2817] in GitLab 8.5.

When you log into GitLab, you normally want to see where you should spend your
time and take some action, or what you need to keep an eye on. All without the
mess of a huge pile of e-mail notifications. GitLab is where you do your work,
so being able to get started quickly is very important.

Todos is a chronological list of to-dos that are waiting for your input, all
in a simple dashboard.

![Todos screenshot showing a list of items to check on](img/todos_index.png)

---

You can access quickly your Todos dashboard by clicking the round gray icon
next to the search bar in the upper right corner.

![Todos icon](img/todos_icon.png)

## What triggers a Todo

A Todo appears in your Todos dashboard when:

- an issue or merge request is assigned to you
- you are `@mentioned` in an issue or merge request, be it the description of
  the issue/merge request or in a comment

>**Note:** Commenting on a commit will _not_ trigger a Todo.

## How a Todo is marked as Done

Any action to the corresponding issue or merge request will mark your Todo as
**Done**. This action can include:

- changing the assignee
- changing the milestone
- adding/removing a label
- commenting on the issue

In case where you think no action is needed, you can manually mark the todo as
done by clicking the corresponding **Done** button, and it will disappear from
your Todos list. If you want to mark all your Todos as done, just click on the
**Mark all as done** button.

---

In order for a Todo to be marked as done, the action must be coming from you.
So, if you close the related issue or merge the merge request yourself, and you
had a Todo for that, it will automatically get marked as done. On the other
hand, if someone else closes, merges or takes action on the issue or merge
request, your Todo will remain pending. This makes sense because you may need
to give attention to an issue even if it has been resolved.

There is just one Todo per issue or merge request, so mentioning a user a
hundred times in an issue will only trigger one Todo.

## Filtering your Todos

In general, there are four kinds of filters you can use on your Todos
dashboard:

| Filter | Description |
| ------ | ----------- |
| Project | Filter by project |
| Author  | Filter by the author that triggered the Todo |
| Type    | Filter by issue or merge request |
| Action  | Filter by the action that triggered the Todo (Assigned or Mentioned)|

You can choose more than one filters at the same time.

[ce-2817]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2817
