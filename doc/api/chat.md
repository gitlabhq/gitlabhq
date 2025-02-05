---
stage: AI-Powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Documentation for the REST API for Duo Chat."
title: GitLab Duo Chat Completions API
---

The GitLab Duo Chat Completions API generates Chat responses. This API is for internal use only.

## Generate Chat responses

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133015) in GitLab 16.7 [with a flag](../administration/feature_flags.md) named `access_rest_chat`. Disabled by default. This feature is internal-only.
> - [Added additional_context parameter](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162650) in GitLab 17.4 [with a flag](../administration/feature_flags.md) named `duo_additional_context`. Disabled by default. This feature is internal-only.

```plaintext
POST /chat/completions
```

NOTE:
Requests to this endpoint are proxied to the
[AI gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md).

Supported attributes:

| Attribute                | Type            | Required | Description                                                             |
|--------------------------|-----------------|----------|-------------------------------------------------------------------------|
| `content`                | string          | Yes      | Question sent to Chat.                                                  |
| `resource_type`          | string          | No       | Type of resource that is sent with Chat question.                       |
| `resource_id`            | string, integer | No       | ID of the resource. Can be a resource ID (integer) or a commit hash (string).                                                 |
| `referer_url`            | string          | No       | Referer URL.                                                            |
| `client_subscription_id` | string          | No       | Client Subscription ID.                                                 |
| `with_clean_history`     | boolean         | No       | Indicates if we need to reset the history before and after the request. |
| `project_id`             | integer         | No       | Project ID. Required if `resource_type` is a commit.                    |
| `additional_context`     | hash            | No       | Additional context for this chat request. See [Context attributes](#context-attributes) for a list of parameters this attribute accepts. |

### Context attributes

The `context` attribute accepts a list of elements with the following attributes:

- `category` - The category of the context element. Valid values are `file`, `merge_request`, `issue`, or `snippet`.
- `id` - The ID of the context element.
- `content` - The content of the context element. The value depends on the category of the context element.
- `metadata` - The optional additional metadata for this context element. The value depends on the category of the context element.

Example request:

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --header "Content-Type: application/json" \
  --data '{
      "content": "how to define class in ruby"
    }' \
  --url "https://gitlab.example.com/api/v4/chat/completions"
```

Example response:

```json
"To define class in ruby..."
```
