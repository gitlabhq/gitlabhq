---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for Code Suggestions.
title: Code Suggestions API
---

Use this API to access the [Code Suggestions](../user/project/repository/code_suggestions/_index.md) feature.

## Generate code completions

{{< details >}}

- Status: Experiment

{{< /details >}}

{{< history >}}

- Introduced in GitLab 16.2 [with a flag](../administration/feature_flags/_index.md) named `code_suggestions_completion_api`. Disabled by default. This feature is an experiment.
- Requirement to generate a JWT before calling this endpoint was [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127863) in GitLab 16.3.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/416371) in GitLab 16.8. [Feature flag `code_suggestions_completion_api`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138174) removed.
- `context` and `user_instruction` attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) in GitLab 17.1 [with a flag](../administration/feature_flags/_index.md) named `code_suggestions_context`. Disabled by default.
- `context` and `user_instruction` attributes [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) in GitLab 18.6. Feature flag `code_suggestions_context` removed.

{{< /history >}}

```plaintext
POST /code_suggestions/completions
```

{{< alert type="note" >}}

This endpoint rate-limits each user to 60 requests per 1-minute window.

{{< /alert >}}

Use the AI abstraction layer to generate code completions.

Requests to this endpoint are proxied to the
[AI gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md).

Parameters:

| Attribute          | Type    | Required | Description |
|--------------------|---------|----------|-------------|
| `current_file`     | hash    | yes      | Attributes of file that suggestions are being generated for. See [File attributes](#file-attributes) for a list of strings this attribute accepts. |
| `intent`           | string  | no       | The intent of the completion request. This can be either `completion` or `generation`. |
| `stream`           | boolean | no       | Whether to stream the response as smaller chunks as they are ready (if applicable). Default: `false`. |
| `project_path`     | string  | no       | The path of the project. |
| `generation_type`  | string  | no       | The type of event for generation requests. This can be `comment`, `empty_function`, or `small_file`. |
| `context`          | array   | no       | Additional context to be used for Code Suggestions. See [Context attributes](#context-attributes) for a list of parameters this attribute accepts. |
| `user_instruction` | string  | no       | A user's instructions for Code Suggestions. |

### File attributes

The `current_file` attribute accepts the following strings:

- `file_name` - The name of the file. Required.
- `content_above_cursor` - The content of the file above the current cursor position. Required.
- `content_below_cursor` - The content of the file below the current cursor position. Optional.

### Context attributes

The `context` attribute accepts a list of elements with the following attributes:

- `type` - The type of the context element. This can be either `file` or `snippet`.
- `name` - The name of the context element. A name of the file or a code snippet.
- `content` - The content of the context element. The body of the file or a function.

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138814) in GitLab 16.7.

{{< /history >}}

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

- [`200`](rest/troubleshooting.md#status-codes) if the feature is enabled.
- [`403`](rest/troubleshooting.md#status-codes) if the feature is disabled.

Additionally, returns a [`404`](rest/troubleshooting.md#status-codes) if the path is empty or the project does not exist.

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

## Fetch direct connection details for the AI gateway

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/452044) in GitLab 17.0 [with a flag](../administration/feature_flags/_index.md) named `code_suggestions_direct_completions`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/456443) in GitLab 17.2. Feature flag `code_suggestions_direct_completions` removed.

{{< /history >}}

```plaintext
POST /code_suggestions/direct_access
```

{{< alert type="note" >}}

This endpoint rate-limits each user to 10 requests per 5-minute window.

{{< /alert >}}

Returns user-specific connection details which can be used by IDEs/clients to send `completion` requests directly to
AI gateway, including headers that must be proxied to the AI gateway as well as the required authentication token.

Example request:

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/code_suggestions/direct_access"
```

Example response:

```json
{
  "base_url": "http://0.0.0.0:5052",
  "token": "a valid token",
  "expires_at": 1713343569,
  "headers": {
    "X-Gitlab-Instance-Id": "292c3c7c-c5d5-48ec-b4bf-f00b724ce560",
    "X-Gitlab-Realm": "saas",
    "X-Gitlab-Global-User-Id": "Df0Jhs9xlbetQR8YoZCKDZJflhxO0ZBI8uoRzmpnd1w=",
    "X-Gitlab-Host-Name": "gitlab.example.com"
  }
}
```

## Fetch connection details

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/555060) in GitLab 18.3.

{{< /history >}}

```plaintext
POST /code_suggestions/connection_details
```

{{< alert type="note" >}}

This endpoint rate-limits each user to 10 requests per 1-minute window.

{{< /alert >}}

Returns user-specific connection details which can be used by IDEs/clients for telemetry, including metadata about
the GitLab instance the user is connected to.

Example request:

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/code_suggestions/connection_details"
```

Example response:

```json
{
  "instance_id": "292c3c7c-c5d5-48ec-b4bf-f00b724ce560",
  "instance_version": "18.2",
  "realm": "saas",
  "global_user_id": "Df0Jhs9xlbetQR8YoZCKDZJflhxO0ZBI8uoRzmpnd1w=",
  "host_name": "gitlab.example.com",
  "feature_enablement_type": "duo_pro",
  "saas_duo_pro_namespace_ids": "1000000"
}
```
