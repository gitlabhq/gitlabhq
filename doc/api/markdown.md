# Markdown API

> [Introduced][ce-18926] in GitLab 11.0.

Available only in APIv4.

## Render an arbitrary Markdown document

```
POST /api/v4/markdown
```

| Attribute | Type    | Required      | Description                                |
| --------- | ------- | ------------- | ------------------------------------------ |
| `text`    | string  | yes           | The Markdown text to render                |
| `gfm`     | boolean | no (optional) | Render text using GitLab Flavored Markdown. Default is `false` |
| `project` | string  | no (optional) | Use `project` as a context when creating references using GitLab Flavored Markdown. [Authentication](README.html#authentication) is required if a project is not public.  |

```bash
curl --header Content-Type:application/json --data '{"text":"Hello world! :tada:", "gfm":true, "project":"group_example/project_example"}' https://gitlab.example.com/api/v4/markdown
```

Response example:

```json
{ "html": "<p dir=\"auto\">Hello world! <gl-emoji title=\"party popper\" data-name=\"tada\" data-unicode-version=\"6.0\">🎉</gl-emoji></p>" }
```

[ce-18926]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/18926
