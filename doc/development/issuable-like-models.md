# Issuable-like Rails models utilities

GitLab Rails codebase contains several models that hold common functionality and behave similarly to
[Issues](../user/project/issues/index.md). Other examples of "issuables"
are [Merge Requests](../user/project/merge_requests/index.md) and
[Epics](../user/group/epics/index.md).

This guide accumulates guidelines on working with such Rails models.

## Important text fields

There are max length constraints for the most important text fields for `Issuable`s:

- `title`: 255 chars
- `title_html`: 800 chars
- `description`: 1 megabyte
- `description_html`: 5 megabytes
