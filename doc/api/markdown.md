---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Markdown API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to render [Markdown](../user/markdown.md) content as HTML.

## Required authentication

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93727) in GitLab 15.3 [with a flag](../administration/feature_flags/_index.md) named `authenticate_markdown_api`. Enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

All API calls to the Markdown API must be [authenticated](rest/authentication.md).

## Render an arbitrary Markdown document

```plaintext
POST /markdown
```

| Attribute | Type    | Required      | Description                                |
| --------- | ------- | ------------- | ------------------------------------------ |
| `text`    | string  | yes           | The Markdown text to render                |
| `gfm`     | boolean | no            | Render text using GitLab Flavored Markdown. Default is `false` |
| `project` | string  | no            | Use `project` as a context when creating references using GitLab Flavored Markdown  |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type:application/json" \
  --data '{"text":"Hello world! :tada:", "gfm":true, "project":"group_example/project_example"}' "https://gitlab.example.com/api/v4/markdown"
```

Response example:

```json
{ "html": "<p dir=\"auto\">Hello world! <gl-emoji title=\"party popper\" data-name=\"tada\" data-unicode-version=\"6.0\">🎉</gl-emoji></p>" }
```
