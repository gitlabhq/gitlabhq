# Issuable-like Rails models utilities

GitLab Rails codebase contains several models that hold common functionality and behave similarly to
[Issues](https://docs.gitlab.com/ee/user/project/issues/). Other examples of "issuables"
are [Merge Requests](https://docs.gitlab.com/ee/user/project/merge_requests/) and
[Epics](https://docs.gitlab.com/ee/user/group/epics/).

This guide accumulates guidelines on working with such Rails models.

## Important text fields

There are max length constraints for the most important text fields for `Issuable`s:

- `title`: 255 chars
- `title_html`: 800 chars
- `description`: 1 megabyte
- `description_html`: 5 megabytes
