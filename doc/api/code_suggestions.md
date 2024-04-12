---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions API

Use the Code Suggestions API to access the Code Suggestions feature.

## Generate code completions

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/415581) in GitLab 16.2 [with a flag](../administration/feature_flags.md) named `code_suggestions_completion_api`. Disabled by default. This feature is an Experiment.
> - Requirement to generate a JWT before calling this endpoint was [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127863) in GitLab 16.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/416371) in GitLab 16.8. [Feature flag `code_suggestions_completion_api`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138174) removed.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../administration/feature_flags.md) named `code_suggestions_completion_api`.
On GitLab.com and GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

```plaintext
POST /code_suggestions/completions
```

NOTE:
This endpoint rate-limits each user to 60 requests per 1-minute window.

Use the AI abstraction layer to generate code completions.

Requests to this endpoint are proxied to the
[AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md).

Parameters:

| Attribute      | Type    | Required | Description |
|----------------|---------|----------|-------------|
| `current_file` | hash    | yes      | Attributes of file for which code suggestions are being generated. See [File attributes](#file-attributes) for a list of strings this attribute accepts. |
| `intent`       | string  | no       | The intent of the completion request. Options: `completion` or `generation`. |
| `stream`       | boolean | no       | Whether to stream the response as smaller chunks as they are ready (if applicable). Default: `false`. |
| `project_path` | string  | no       | The path of the project. |

### File attributes

The `current_file` attribute accepts the following strings:

- `file_name` - The name of the file. Required.
- `content_above_cursor` - The content of the file above the current cursor position. Required.
- `content_below_cursor` - The content of the file below the current cursor position. Optional.

Example request:

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --data '{
      "current_file": {
        "file_name": "car.py",
        "content_above_cursor": "class Car:\n    def __init__(self):\n        self.is_running = False\n        self.speed = 0\n    def increase_speed(self, increment):",
        "content_below_cursor": ""
      },
      "intent": "completion"
    }' \
  --url "https://gitlab.example.com/api/v4/code_suggestions/completions"
```

Example response:

```json
{
  "id": "id",
  "model": {
    "engine": "vertex-ai",
    "name": "code-gecko"
  },
  "object": "text_completion",
  "created": 1688557841,
  "choices": [
    {
      "text": "\n        if self.is_running:\n            self.speed += increment\n            print(\"The car's speed is now",
      "index": 0,
      "finish_reason": "length"
    }
  ]
}
```

## Validate that Code Suggestions is enabled

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138814) in GitLab 16.7.

Use this endpoint to validate if either:

- A project has `code_suggestions` enabled.
- A project's group has `code_suggestions` enabled in its namespace settings.

```plaintext
POST code_suggestions/enabled
```

Supported attributes:

| Attribute         | Type    | Required | Description |
| ----------------- | ------- | -------- | ----------- |
| `project_path`    | string  | yes      | The path of the project to be validated. |

If successful, returns:

- [`200`](rest/index.md#status-codes) if the feature is enabled.
- [`403`](rest/index.md#status-codes) if the feature is disabled.

Additionally, returns a [`404`](rest/index.md#status-codes) if the path is empty or the project does not exist.

Example request:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/code_suggestions/enabled"
  --header "Private-Token: <YOUR_ACCESS_TOKEN>" \
  --header "Content-Type: application/json" \
  --data '{
      "project_path": "group/project_name"
    }' \

```
