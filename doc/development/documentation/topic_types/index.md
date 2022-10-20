---
stage: none
group: Style Guide
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Documentation topic types (CTRT)

At GitLab, we have not traditionally used types for our content. However, we are starting to
move in this direction, and we now use four primary topic types:

- [Concept](concept.md)
- [Task](task.md)
- [Reference](reference.md)
- [Troubleshooting](troubleshooting.md)

The tech writing team sometimes uses the acronym `CTRT` to refer to our topic types.
The acronym refers to the first letter of each topic type.

In general, each page in the GitLab documentation contains multiple topics.
Each topic on a page should be recognizable as a specific topic type.

## Other topic types

In addition to the four primary topic types, we have a few other types.

### Related topics

If inline links are not sufficient, you can create a topic called **Related topics**
and include an unordered list of related topics. This topic should be above the Troubleshooting section.

```markdown
# Related topics

- [Configure your pipeline](link-to-topic).
- [Trigger a pipeline manually](link-to-topic).
```

### Tutorials

A tutorial is page that contains an end-to-end walkthrough of a complex workflow or scenario.
In general, you might consider using a tutorial when:

- The workflow requires a number of sequential steps where each step consists
  of sub-steps.
- The steps cover a variety of GitLab features or third-party tools.

Tutorials are learning aids that complement our core documentation.
They do not introduce new features.
Always use the primary [topic types](#documentation-topic-types-ctrt) to document new features.

Tutorials should be in this format:

```markdown
# Title (starts with "Tutorial:" followed by an active verb, like "Tutorial: Create a website")

A paragraph that explains what the tutorial does, and the expected outcome.

To create a website:

1. [Do the first task](#do-the-first-task)
1. [Do the second task](#do-the-second-task)

Prerequisites (optional):

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

### Get started

A get started page is a set of steps to help a user get set up
quickly to use a single GitLab feature or tool.
It consists of more than one task.

Get started pages should be in this format:

```markdown
# Title ("Get started with <feature>")

Complete the following steps to ... .

1. First step.
1. Another step.
1. Another step.

If you need to add more than one task,
consider using subsections for each distinct task.
```

In the left nav, use `Get started` as the text. On the page itself, spell out
the full name. For example, `Get started with application security`.

### Topics and resources

Some pages are solely a list of links to other documentation.

We do not encourage this page type. Lists of links can get out-of-date quickly
and offer little value to users, who prefer to search to find information.

## Heading text guidelines

In general, for heading text:

- Be clear and direct. Make every word count.
- Use articles and prepositions.
- Follow [capitalization](../styleguide/index.md#capitalization) guidelines.
- Do not repeat text from earlier headings. For example, if the page is about merge requests,
  instead of `Troubleshooting merge requests`, use only `Troubleshooting`.

See also [guidelines for headings in Markdown](../styleguide/index.md#headings-in-markdown).
