---
stage: Plan
group: Project Management
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Invalidate Markdown Cache **(FREE)**

For performance reasons, GitLab caches the HTML version of Markdown text
in fields like comments, issue descriptions, and merge request descriptions. These
cached versions can become outdated, such as
when the `external_url` configuration option is changed. Links
in the cached text would still refer to the old URL.

To avoid this problem, the administrator can invalidate the existing cache by
increasing the `local_markdown_version` setting in application settings. This can
be done by [changing the application settings through
the API](../api/settings.md#change-application-settings):

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings?local_markdown_version=<increased_number>"
```
