---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Documentation topic types (CTRT)
---

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

- Page type: [Tutorials](tutorial.md)
- Page type: [Get started](get_started.md)
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
- Use fewer than 70 characters when possible. The [markdownlint](../testing/markdownlint.md) rule:
  [`line-length` (MD013)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.markdownlint-cli2.yaml)
- Use articles and prepositions.
- Follow [capitalization](../styleguide/_index.md#topic-titles) guidelines.
- Do not repeat text from earlier topic titles. For example, if the page is about merge requests,
  instead of `Troubleshooting merge requests`, use only `Troubleshooting`.
- Avoid using hyphens to separate information.
  For example, instead of `Internal analytics - Architecture`, use `Internal analytics architecture` or `Architecture of internal analytics`.

See also [guidelines for heading levels in Markdown](../styleguide/_index.md#heading-levels-in-markdown).

## Related topics

If inline links are not sufficient, you can create a topic called **Related topics**
and include an unordered list of related topics. This topic should be above the Troubleshooting section.

Links in this section should be brief and scannable. They are usually not
full sentences, and so should not end in a period.

```markdown
## Related topics

- [CI/CD variables](link-to-topic.md)
- [Environment variables](link-to-topic.md)
```
