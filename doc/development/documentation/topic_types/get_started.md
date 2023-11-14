---
stage: none
group: Style Guide
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
---

# Get started page type

A **Get started** page is meant to introduce high-level concepts for a broad feature area.
While a specific feature might be defined in the feature documentation,
a **Get started** page is meant to give an introduction to a set of concepts.
When you group the concepts together, you help the user see how they fit together.

A **Get started** page should familiarize the reader with terms and then quickly
point them to actions they can take to get started. Hopefully the actions are
task-based, but the next step can also be to learn more.

## When to use a Get started page

A **Get started** page should be used only for a larger concept,
like CI/CD or security. In general, we describe features in concept topics.
However, if you find you want to explain how multiple concepts fit together,
then a **Get started** page might be what you need.

To determine if a **Get started** page makes sense, make a list
of the common terms you expect to include. If you have more than four or five,
then this page type might make sense.

A **Get started** page is different from a tutorial. It's conceptual, while
a tutorial helps the user achieve a task. A **Get started** page should point
to tutorials, however, because tutorials are a great way for a user to get started.

## Format

Get started pages should be in this format:

```markdown
# Get started with abc

Abc is a thing you use to do xyz. You might use it when you need to blah,
and it can be helpful for etc.

## Common terms

If you're new to abc, start by reviewing some of the most commonly used terms.

### First term

This thing is this. Describe what it is, not how to do it.

**Get started:**

- [Create your first abc](LINK).
- [Learn more about abc](LINK).

### Second term

This thing is this. Describe what it is, not how to do it.

**Get started:**

- [Create your first abc](LINK).
- [Learn more about abc](LINK).

## Videos

- [Video 1](LINK).
- [Video 2](LINK).

## Related topics

- [Link 1](LINK).
- [Link 2](LINK).
```

- Follow [the video guidance](../styleguide/index.md#link-to-video)
  for the links in the Video topic.
- Do not use links inline with content (as part of sentences).
  Use them where links are specified only.
- The terms described on this page can exist elsewhere in the docs.
  However, the term descriptions on this page should be relatively brief.

## Get started page titles

For the title, use `Get started with topic_name`.

For the left nav, use `Getting started`.

## Example

For an example of the Get started page type,
see [Get started with GitLab CI/CD](../../../ci/index.md).
