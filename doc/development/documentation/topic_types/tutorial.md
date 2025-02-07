---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Tutorial page type
---

A tutorial is page that contains an end-to-end walkthrough of a complex workflow or scenario.
In general, you might consider using a tutorial when:

- The workflow requires a number of sequential steps where each step consists
  of sub-steps.
- The steps cover a variety of GitLab features or third-party tools.

## Tutorial guidance

- Tutorials are not [tasks](task.md). A task gives instructions for one procedure.
  A tutorial combines multiple tasks to achieve a specific goal.
- Tutorials provide a working example. Ideally the reader can create the example the
  tutorial describes. If they can't replicate it exactly, they should be able
  to replicate something similar.
- Tutorials do not introduce new features.
- Tutorials do not need to adhere to the Single Source of Truth tenet. While it's not
  ideal to duplicate content that is available elsewhere, it's worse to force the reader to
  leave the page to find what they need.

## Tutorial filename and location

For tutorial Markdown files, you can either:

- Save the file in a directory with the product documentation.
- Create a subfolder under `doc/tutorials` and name the file `index.md`.

In the left nav, add the tutorial near the relevant feature documentation.

Add a link to the tutorial on one of the [tutorial pages](../../../tutorials/_index.md).

## Tutorial format

Tutorials should be in this format:

```markdown
# Title (starts with "Tutorial:" followed by an active verb, like "Tutorial: Create a website")

A paragraph that explains what the tutorial does, and the expected outcome.

To create a website:

1. [Do the first task](#do-the-first-task)
1. [Do the second task](#do-the-second-task)

## Before you begin

This section is optional.

- Thing 1
- Thing 2
- Thing 3

## Do the first task

To do step 1:

1. First step.
1. Another step.
1. Another step.

## Do the second task

Before you begin, make sure you have [done the first task](#do-the-first-task).

To do step 2:

1. First step.
1. Another step.
1. Another step.
```

An example of a tutorial that follows this format is
[Tutorial: Make your first Git commit](../../../tutorials/make_first_git_commit/_index.md).

## Tutorial page title

Start the page title with `Tutorial:` followed by an active verb, like `Tutorial: Create a website`.

In the left nav, use the full page title. Do not abbreviate it.
Put the text in quotes so the pipeline succeeds. For example,
`"Tutorial: Make your first Git commit"`.

On [the **Learn GitLab with tutorials** page](../../../tutorials/_index.md),
do not use `Tutorial` in the title.

## Screenshots

You can include screenshots in a tutorial to illustrate important steps in the process.
In the core product documentation, you should [use illustrations sparingly](../styleguide/_index.md#illustrations).
However, in tutorials, screenshots can help users understand where they are in a complex process.

Try to balance the number of screenshots in the tutorial so they don't disrupt
the narrative flow. For example, do not put one large screenshot in the middle of the tutorial.
Instead, put multiple, smaller screenshots throughout.

## Tutorial voice

Use a friendlier tone than you would for other topic types. For example,
you can:

- Add encouraging or congratulatory phrases after tasks.
- Use future tense from time to time, especially when you're introducing
  steps. For example, `Next, you will associate your issues with your epics`.
- Be more conversational. For example, `This task might take a while to complete`.

## Metadata

On pages that are tutorials, add the most appropriate `stage:` and `group:` metadata at the top of the file.
If the majority of the content does not align with a single group, specify `none` for the stage
and `Tutorials` for the group:

```plaintext
stage: none
group: Tutorials
```
