# Due dates

> [Introduced][ce-3614] in GitLab 8.7.

Due dates can be used in issues to keep track of deadlines and make sure
features are shipped on time. Due dates require at least [Reporter permissions][permissions]
to be able to edit them. On the contrary, they can be seen by everybody.

## Setting a due date

When creating or editing an issue, you can see the due date field from where
a calendar will appear to help you choose the date you want. To remove it,
select the date text and delete it.

![Create a due date](img/due_dates_create.png)

A quicker way to set a due date is via the issue sidebar. Simply expand the
sidebar and select **Edit** to pick a due date or remove the existing one.
Changes are saved immediately.

![Edit a due date via the sidebar](img/due_dates_edit_sidebar.png)

## Making use of due dates

Issues that have a due date can be distinctively seen in the issues index page
with a calendar icon next to them. Issues where the date is past due will have
the icon and the date colored red. You can sort issues by those that are
_Due soon_ or _Due later_ from the dropdown menu in the right.

![Issues with due dates in the issues index page](img/due_dates_issues_index_page.png)

Due dates also appear in your [todos list](../../../workflow/todos.md).

![Issues with due dates in the todos](img/due_dates_todos.png)

[ce-3614]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3614
[permissions]: ../../permissions.md#project
