# Markdown API

> [Introduced][ce-18926] in GitLab 11.0.

Available only in APIv4.

## Render an arbitrary Markdown document

```
POST /api/v4/markdown
```

| Attribute | Type    | Required      | Description                                |
| --------- | ------- | ------------- | ------------------------------------------ |
| `text`    | string  | yes           | The markdown text to render                |
| `gfm`     | boolean | no (optional) | Render text using GitLab Flavored Markdown (default: `false`) |
| `project` | string  | no if `gfm` is false<br>yes if `gfm` is true | The full path of a project to use as the context when creating references using GitLab Flavored Markdown |

```bash
curl -H Content-Type:application/json -d '{"text":"Hello world! :tada:", "gfm":true, "project":"group_example/project_example"}' https://gitlab.example.com/api/v4/markdown
```

Response example:

```
<p dir="auto">Hello world! <gl-emoji title="party popper" data-name="tada" data-unicode-version="6.0">🎉</gl-emoji></p>
```

[ce-18926]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18926
