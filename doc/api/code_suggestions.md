---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions API

Use the Code Suggestions API to access the Code Suggestions feature.

## Create an access token

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404427) in GitLab 16.1.

Creates an access token to access Code Suggestions.

```plaintext
POST /code_suggestions/tokens
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/code_suggestions/tokens"
```

Example response:

```json
{
    "access_token": "secret-access-token",
    "expires_in": 3600,
    "created_at": 1687865199
}
```

## Generate code completions **(EXPERIMENT)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/415581) in GitLab 16.2 [with a flag](../administration/feature_flags.md) named `code_suggestions_completion_api`. Disabled by default. This feature is an Experiment.
> - Requirement to generate a JWT before calling this endpoint was [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127863) in GitLab 16.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/416371) in GitLab 16.8. [Feature flag `code_suggestions_completion_api`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138174) removed.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../administration/feature_flags.md) named `code_suggestions_completion_api`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

NOTE:
This endpoint rate-limits each user to 60 requests per 1-minute window.

Use the AI abstraction layer to generate code completions.

```plaintext
POST /code_suggestions/completions
```

Requests to this endpoint are proxied directly to the [model gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#completions). The documentation for the endpoint is currently the SSoT for named parameters.

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --data "<JSON_BODY>" \
  --url "https://gitlab.example.com/api/v4/code_suggestions/completions"
```

Example body:

The [model gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#completions) is the SSoT for parameters.

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
