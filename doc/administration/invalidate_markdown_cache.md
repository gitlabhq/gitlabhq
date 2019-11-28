# Invalidate Markdown Cache

For performance reasons, GitLab caches the HTML version of Markdown text
(e.g. issue and merge request descriptions, comments). It's possible
that these cached versions become outdated, for example
when the `external_url` configuration option is changed - causing links
in the cached text to refer to the old URL.

To avoid this problem, the administrator can invalidate the existing cache by
increasing the `local_markdown_version` setting in application settings.  This can
be done by [changing the application settings through
the API](../api/settings.md#change-application-settings):

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/application/settings?local_markdown_version=<increased_number>
```
