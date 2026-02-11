---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Task topic type
---

A task gives instructions for how to complete a procedure.

## Format

Tasks should be in this format:

```markdown
title: Title (starts with an active verb, like "Create a widget" or "Delete a widget")
---

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
title: Create an issue
---

Create an issue when you want to track bugs or future work.

Prerequisites:

- The Developer, Maintainer, or Owner role for the project.

To create an issue:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Plan** > **Issues**.
1. In the upper-right corner, select **New issue**.
1. Complete the fields. (If you have reference content that lists each field, link to it here.)
1. Select **Create issue**.

The issue is created. You can view it by going to **Plan** > **Issues**.
```

## Task topic titles

For the title text, use the structure `active verb` + `noun`.
For example, `Create an issue`.

## When a task has only one step

If you need to write a task that has only one step, make that step an unordered list item.
This format helps the step stand out, while keeping it consistent with the rules
for lists.

For example:

```markdown
title: Create a merge request
---

To create a merge request:

- In the upper-right corner, select **New merge request**.
```

### When more than one way exists to perform a task

If more than one way exists to perform a task in the UI, you should
document the primary way only.

However, sometimes you must document multiple ways to perform a task.
When this situation occurs:

- Introduce the task as usual. Then, for each way of performing the task, add a topic title.
- Nest the topic titles one level below the task topic title.
- List the tasks in descending order, with the most likely method first.
- Make the task titles as brief as possible. When possible,
  use `infinitive` + `noun`.

Here is an example.

```markdown
title: Change the default branch name
---

You can change the default branch name for the instance or group.
If the name is set for the instance, you can override it for a group.

## For the instance

Prerequisites:

- Administrator access.

To change the default branch name for an instance:

1. Step.
1. Step.

## For the group

Prerequisites:

- The Developer, Maintainer, or Owner role for the group.

To change the default branch name for a group:

1. Step.
1. Step.
```

### To perform the task in the UI and API

Usually an API exists to perform the same task that you perform in the UI.

When this situation occurs:

- Do not use a separate heading for a one-sentence link to the API.
- Do not include API examples in the **Use GitLab** documentation. API examples
  belong in the API documentation. If you have GraphQL examples, put them on
  their own page, because the API documentation might move some day.
- Do not mention the API if you do not need to. Users can search for
  the API documentation, and extra linking adds clutter.
- If someone feels strongly that you mention the API, at the end
  of the UI task, add this sentence:

  `To create an issue, you can also [use the API](link.md).`

## Task introductions

To start the task topic, use the structure `active verb` + `noun`, and
provide context about the action.
For example, `Create an issue when you want to track bugs or future work`.

To start the task steps, use a succinct action followed by a colon.
For example, `To create an issue:`

## Task prerequisites

If the task requires the user to have a role other than Guest,
list all applicable roles in the prerequisites. See [the Word list](../styleguide/word_list.md) for
how to write the phrase for each role. List the applicable roles first.

If the task can only be performed by an administrator, put `Administrator access.` in the prerequisites.

`Prerequisites` must always be plural, even if the list includes only one item.

Do not list subscriptions or add-ons in the prerequisites. These should only be included
in the [product availability details](../styleguide/availability_details.md).

If several tasks on a page share prerequisites, you can create a separate
topic with the title `Prerequisites`.

### Writing prerequisite statements

As much as possible, follow these patterns when writing prerequisites.

- Use a list of nouns, assuming an unspoken `You must have:` as the introduction.
- Use a list of verbs, assuming an unspoken `You must:` as the introduction.

For example, for a list of nouns:

```markdown
Prerequisites:

- The Maintainer or Owner role for the project.
- A project access token.
- Docker installed locally.
```

For a list of verbs:

```markdown
Prerequisites:

- Enable Cloud Logging API on your Google Cloud project.
- Configure dependency scanning on your target projects.
- Create a service account with appropriate permissions.
```

Try to avoid phrases like `Ensure that` or `You must have`.

## Related topics

- [How to write task steps](../styleguide/_index.md#navigation)
- [Before and after example](concept.md#example)
