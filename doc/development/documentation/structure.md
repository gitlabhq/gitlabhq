---
stage: none
group: Style Guide
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: What to include in GitLab documentation pages.
---

# Documentation topic types

At GitLab, we have not traditionally used topic types. However, we are starting to
move in this direction, and we now use four topic types:

- [Concept](#concept)
- [Task](#task)
- [Reference](#reference)
- [Troubleshooting](#troubleshooting)

Each page contains multiple topic types. For example,
a page with the title `Pipelines`, which is generated from a file called `index.md`,
can include a concept and multiple task and reference topics.

GitLab also uses high-level landing pages.

## Landing pages

Landing pages are topics that group other topics and help a user to navigate a section.

Users who are using the in-product help do not have a left nav,
and need these topics to navigate the documentation.

These topics can also help other users find the most important topics
in a section.

Landing page topics should be in this format:

```markdown
# Title (a noun, like "CI/CD or "Analytics")

Brief introduction to the concept or product area.
Include the reason why someone would use this thing.

- Bulleted list of important related topics.
- These links are needed because users of in-product help do not have left navigation.
```

## Concept

A concept topic introduces a single feature or concept.

A concept should answer the questions:

- What is this?
- Why would I use it?

Think of everything someone might want to know if they've never heard of this topic before.

Don't tell them **how** to do this thing. Tell them **what it is**.

If you start describing another topic, start a new concept and link to it.

Also, do not use "Overview" or "Introduction" for the topic title. Instead,
use a noun or phrase that someone would search for.

Concept topics should be in this format:

```markdown
# Title (a noun, like "Widgets")

A paragraph that explains what this thing is.

Another paragraph that explains what this thing is.

Remember, if you start to describe about another concept, stop yourself.
Each concept topic should be about one concept only.
```

## Task

A task topic gives instructions for how to complete a procedure.

Task topics should be in this format:

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

- A minimum of Contributor access to a project in GitLab.

To create an issue:

1. Go to **Issues > List**.
1. In the top right, select **New issue**.
1. Complete the fields. (If you have a reference topic that lists each field, link to it here.)
1. Select **Create issue**.

The issue is created. You can view it by going to **Issues > List**.
```

If you have several tasks on a page that share prerequisites, you can make a
reference topic with the title **Prerequisites**, and link to it.

## Reference

A reference topic provides information in an easily-scannable format,
like a table or list. It's similar to a dictionary or encyclopedia entry.

```markdown
# Title (a noun, like "Pipeline settings" or "Administrator options")

Introductory sentence.

| Setting | Description |
|---------|-------------|
| **Name** | Descriptive sentence about the setting. |
```

If a feature or concept has its own prerequisites, you can use the reference
topic type to create a **Prerequisites** header for the information.

## Troubleshooting

Troubleshooting topics can be one of two categories:

- **Troubleshooting task.** This topic is written the same as a [standard task topic](#task).
  For example, "Run debug tools" or "Verify syntax."
- **Troubleshooting reference.** This topic has a specific format.

Troubleshooting reference topics should be in this format:

```markdown
# Title (the error message or a description of it)

You might get an error that states <error message>.

This issue occurs when...

The workaround is...
```

For the topic title:

- Consider including at least a partial error message in the title.
- Use fewer than 70 characters.

Remember to include the complete error message in the topics content if it is
not complete in the title.

## Other information on a topic

Topics include other information.

For example:

- Each topic must have a [tier badge](styleguide/index.md#product-tier-badges).
- New topics must have information about the
  [GitLab version where the feature was introduced](styleguide/index.md#where-to-put-version-text).

### Help and feedback section

This section ([introduced](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/319) in GitLab 11.4)
is displayed at the end of each document and can be omitted by adding a key into
the front matter:

```yaml
---
feedback: false
---
```

The default is to leave it there. If you want to omit it from a document, you
must check with a technical writer before doing so.

#### Disqus

We also have integrated the docs site with Disqus (introduced by
[!151](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/151)),
allowing our users to post comments.

To omit only the comments from the feedback section, use the following key in
the front matter:

```yaml
---
comments: false
---
```

We're hiding comments only in main index pages, such as [the main documentation index](../../README.md),
since its content is too broad to comment on. Before omitting Disqus, you must
check with a technical writer.

Note that after adding `feedback: false` to the front matter, it will omit
Disqus, therefore, don't add both keys to the same document.

The click events in the feedback section are tracked with Google Tag Manager.
The conversions can be viewed on Google Analytics by navigating to
**Behavior > Events > Top events > docs**.

### Guidelines for good practices

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36576/) in GitLab 13.2 as GitLab Development documentation.

*Good practice* examples demonstrate encouraged ways of writing code while
comparing with examples of practices to avoid. These examples are labeled as
*Bad* or *Good*. In GitLab development guidelines, when presenting the cases,
it's recommended to follow a *first-bad-then-good* strategy. First demonstrate
the *Bad* practice (how things *could* be done, which is often still working
code), and then how things *should* be done better, using a *Good* example. This
is typically an improved example of the same code.

Consider the following guidelines when offering examples:

- First, offer the *Bad* example, and then the *Good* one.
- When only one bad case and one good case is given, use the same code block.
- When more than one bad case or one good case is offered, use separated code
  blocks for each. With many examples being presented, a clear separation helps
  the reader to go directly to the good part. Consider offering an explanation
  (for example, a comment, or a link to a resource) on why something is bad
  practice.
- Better and best cases can be considered part of the good case(s) code block.
  In the same code block, precede each with comments: `# Better` and `# Best`.

Although the bad-then-good approach is acceptable for the GitLab development
guidelines, do not use it for user documentation. For user documentation, use
*Do* and *Don't*. For examples, see the [Pajamas Design System](https://design.gitlab.com/content/punctuation/).
