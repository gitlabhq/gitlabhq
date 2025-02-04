---
stage: none
group: Style Guide
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Get started page type
---

A **Get started** page introduces high-level concepts for a broad feature area.
While a specific feature might be defined in the feature documentation,
a **Get started** page gives an introduction to a set of concepts.
The content should help the user understand how multiple features fit together
as part of the larger GitLab workflow.

## When to use a Get started page

For now, a **Get started** page should be used only at the highest level of the left navigation.
For example, you might have a **Get started** page under **Manage your organization** or **Extend GitLab**.

A **Get started** page is different from a tutorial. A **Get started** page focuses on high-level
concepts that are part of a workflow, while a tutorial helps the user achieve a task.
A **Get started** page should point to tutorials, however, because tutorials are a great way for a user to get started.

## Format

Get started pages should be in this format:

```markdown
# Get started with abc

These features work together in this way. You can use them to achieve these goals.
Include a paragraph that ties together the features without describing what
each individual feature does.

Then add this sentence and a diagram. Details about the diagram
file are below.

The process of <abc> is part of a larger workflow:

![Workflow](img/workflow diagram.png)

## Step 1: Do this thing

Each step should group features by workflow. For example, step 1 might be:

`## Step 1: Determine your release cadence`

Then the content can explain milestones, iterations, labels, etc.
The terms can exist elsewhere in the docs, but the descriptions
on this page should be relatively brief.

Finally, add links, in this format:

For more information, see:

- [Create your first abc](link.md).
- [Learn more about abc](link.md).

## Step 2: The next thing

Don't link in the body content. Save links for the `for more information` area.

For more information, see:

- [Create your first abc](link.md).
- [Learn more about abc](link.md).
```

## Get started page titles

For the title, use `Get started with topic_name`.

For the left nav, use `Getting started`.

## Get started file location

All **Getting started** files should be in the folder `doc/user/get_started/`.
You do not need to create a subfolder for each file.

## Diagram files

The diagram files are [in this Google Slides doc](https://docs.google.com/presentation/d/19spBwRAb4QNoTdZofR37TkBBFBPcmh4196ae3lX1ngQ/edit?usp=sharing).

## Example

For an example of the Get started page type,
see [Get started learning Git](../../../topics/git/get_started.md).
