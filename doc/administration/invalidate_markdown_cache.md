---
stage: Plan
group: Project Management
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Markdown cache **(FREE SELF)**

For performance reasons, GitLab caches the HTML version of Markdown text in fields such as:

- Comments.
- Issue descriptions.
- Merge request descriptions.

These cached versions can become outdated, such as when the `external_url` configuration option is changed. Links
in the cached text would still refer to the old URL.

## Invalidate the cache

Pre-requisite:

- You must be an administrator.

To avoid problems caused by cached HTML versions, invalidate the existing cache by increasing the `local_markdown_version`
setting in application settings [using the API](../api/settings.md#change-application-settings):

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings?local_markdown_version=<increased_number>"
```
