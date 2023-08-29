---
stage: Manage
group: AI assisted
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
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
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/code_suggestions/tokens"
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

FLAG:
On self-managed GitLab, by default this feature is not available.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

Use the AI abstraction layer to generate code completions.

```plaintext
POST /code_suggestions/completions
```

Requests to this endpoint are proxied directly to the [model gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#completions). The documentation for the endpoint is currently the SSoT for named parameters.

```shell
curl --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" --data "<JSON_BODY>" https://gitlab.example.com/api/v4/code_suggestions/completions
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
