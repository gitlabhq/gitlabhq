---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---
# Issuable-like Rails models utilities

GitLab Rails codebase contains several models that hold common functionality and behave similarly to
[Issues](../user/project/issues/index.md). Other examples of "issuables"
are [Merge Requests](../user/project/merge_requests/index.md) and
[Epics](../user/group/epics/index.md).

This guide accumulates guidelines on working with such Rails models.

## Important text fields

There are maximum length constraints for the most important text fields for issuables:

- `title`: 255 characters
- `title_html`: 800 characters
- `description`: 1 megabyte
- `description_html`: 5 megabytes
