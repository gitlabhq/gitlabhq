# Issue board

> [Introduced][ce-5554] in GitLab 8.11.

The GitLab Issue Board is a software project management tool used to plan,
organize, and visualize a workflow for a feature or product release.

It allows you to create lists, which are based on the [labels] that already
exist in the issue tracker. Issues can be seen as cards and they can easily be
moved between the lists, as to create workflows.

The starting point is two lists: **Backlog** and **Done**. Under the **Backlog**
list, all the issues that are not assigned to a list will appear. Drag a card
to the **Done** list and the relevant issue will be closed.

## Creating workflows

By adding new lists, you can create workflows. For instance you can create a
list based on the label of `Design` and one for `Backend`. A designer can start
working on an issue by dragging it to `Design`. That way, everyone knows, this
issue is now being worked on by the designers. Then, once they’re done, all
they have to do is drag it over to the next list, Backend, where a Backend
developer can eventually pick it up. Once they’re done, they move it to closed,
to close the issue.

As lists in Issue Boards are based on labels, it works out of the box with your
existing issues. So if you've already labeled things with `Backend` and `Frontend`,
the issue will appear in the lists as you create them. In addition, this means
you can easily move something between lists by changing a label.

If you move an issue from one list to the next, it removes the label from the
list it comes from and adds the label from the list it moves towards.

## Pro-tips

- Issue boards can have between 2-10 lists which display as columns.
- Creating a new list is easy! Simply click the **Create new list** button in
  the upper right corner and select the labels from your GitLab issue tracker
  to populate the list.
- If you need to create a list based on a label that doesn't exist yet, just
  click **Create new list** and then "Create new**.
- All issues can be dragged and dropped into lists.

[ce-5554]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5554
[labels]: ./labels.md
