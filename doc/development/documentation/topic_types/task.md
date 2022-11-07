---
stage: none
group: Style Guide
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Task topic type

A task gives instructions for how to complete a procedure.

Tasks should be in this format:

```markdown
# Title (starts with an active verb, like "Create a widget" or "Delete a widget")

Do this task when you want to...

Prerequisites (optional):

- Thing 1
- Thing 2
- Thing 3

To do this task:

1. Location then action. (Go to this menu, then select this item.)
1. Another step.
1. Another step.

Task result (optional). Next steps (optional).
```

Here is an example.

```markdown
# Create an issue

Create an issue when you want to track bugs or future work.

Prerequisites:

- You must have at least the Developer role for the project.

To create an issue:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Issues > List**.
1. In the top right corner, select **New issue**.
1. Complete the fields. (If you have reference content that lists each field, link to it here.)
1. Select **Create issue**.

The issue is created. You can view it by going to **Issues > List**.
```

## Task topic titles

For the title text, use the structure `active verb` + `noun`.
For example, `Create an issue`.

If you have several tasks on a page that share prerequisites, you can use the title
`Prerequisites` and link to it.

## Task introductions

To start the task topic, use the structure `active verb` + `noun`, and
provide context about the action.
For example, `Create an issue when you want to track bugs or future work`.

To start the task steps, use a succinct action followed by a colon.
For example, `To create an issue:`

## Related topics

- [View the format for writing task steps](../styleguide/index.md#navigation).
