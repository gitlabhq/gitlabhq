---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Top-level page type
---

The top-level page is at the highest level of each section in **Use GitLab** in the global navigation.
This page type:

- Introduces the workflow briefly.
- Lists only the pages that are one level below the top-level page.

## Format

The top-level page should be in this format. Use [cards](../styleguide/_index.md#cards) to list the pages.

```markdown
title: Title (The name of the top-level page, like "Manage your organization")
---

List features in the workflow, in the order they appear in the global navigation.

{{</* cards */>}}

- [The first page](first_page.md)
- [Another page](another/page.md)
- [One more page](one_more.md)

{{</* /cards */>}}
```

## Top-level page titles

The title must be an active verb that describes the workflow, like **Manage your infrastructure** or **Organize work with projects**.

## Metadata

The `description` metadata on the top-level page determines the text that appears on the
GitLab documentation home page.

Use the following metadata format:

```plaintext
stage: Name
group: Name
description: List 3 to 4 features linked from the page.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
```
