---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
---

# Top-level page type

The top-level page is at the highest level of each section in **Use GitLab** in the global navigation.
This page type:

- Introduces the workflow briefly.
- Lists features in the workflow, in the order they appear in the global navigation.

## Format

The top-level navigation should be in this format:

```markdown
# Title (The name of the top-level page, like "Manage your organization")

Briefly describe the workflow's key features. Use the active voice, for example, "Manage projects to track issues, plan work, and collaborate on code."

- [Title of first page]()
- [Title of second page]()
- [Title of third page]()
```

Update the list of pages when a new page is added, or if the pages are reordered.

## Top-level page titles

The title must be an active verb that describes the workflow, like **Manage your infrastructure** or **Organize work with projects**.

## Metadata

The `description` metadata on the top-level page determines the text that appears on the
GitLab docs home page.

Use the following metadata format:

```plaintext
stage: Name
group: Name
description: List 3 to 4 features linked from the page.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
```
