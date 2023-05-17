---
stage: none
group: Style Guide
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Documentation topic types (CTRT)

Each topic on a page should be one of the following topic types:

- [Concept](concept.md)
- [Task](task.md)
- [Reference](reference.md)
- [Troubleshooting](troubleshooting.md)

Even if a page is short, the page usually starts with a concept and then
includes a task or reference topic.

The tech writing team sometimes uses the acronym `CTRT` to refer to the topic types.
The acronym refers to the first letter of each topic type.

## Other page and topic types

In addition to the four primary topic types, you can use the following:

- Page types: [Tutorials](tutorial.md) and [Get started](#get-started)
- Topic type: [Related topics](#related-topics)
- Page or topic type: [Glossaries](glossary.md)

## Pages and topics to avoid

You should avoid:

- Pages that are exclusively links to other pages. The only exception are
  top-level pages that aid with navigation.
- Topics that have one or two sentences only. In these cases:
  - Incorporate the information in another topic.
  - If the sentence links to another page, use a [Related topics](#related-topics) link instead.

## Topic title guidelines

In general, for topic titles:

- Be clear and direct. Make every word count.
- Use articles and prepositions.
- Follow [capitalization](../styleguide/index.md#capitalization) guidelines.
- Do not repeat text from earlier topic titles. For example, if the page is about merge requests,
  instead of `Troubleshooting merge requests`, use only `Troubleshooting`.

See also [guidelines for heading levels in Markdown](../styleguide/index.md#heading-levels-in-markdown).

## Related topics

If inline links are not sufficient, you can create a topic called **Related topics**
and include an unordered list of related topics. This topic should be above the Troubleshooting section.

Links in this section should be brief and scannable. They are usually not
full sentences, and so should not end in a period.

```markdown
## Related topics

- [CI/CD variables](link-to-topic)
- [Environment variables](link-to-topic)
```

## Get started

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
