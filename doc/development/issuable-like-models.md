---
stage: Plan
group: Project Management
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Issuable-like Rails models utilities
---

GitLab Rails codebase contains several models that hold common functionality and behave similarly to
[Issues](../user/project/issues/_index.md). Other examples of "issuables"
are [merge requests](../user/project/merge_requests/_index.md) and
[Epics](../user/group/epics/_index.md).

This guide accumulates guidelines on working with such Rails models.

## Important text fields

There are maximum length constraints for the most important text fields for issuables:

- `title`: 255 characters
- `description`: 1 megabyte
