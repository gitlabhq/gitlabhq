---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External pipeline validation
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can use an external service to validate a pipeline before it's created.

GitLab sends a POST request to the external service URL with the pipeline
data as payload. The response code from the external service determines if GitLab
should accept or reject the pipeline. If the response is:

- `200`, the pipeline is accepted.
- `406`, the pipeline is rejected.
- Other codes, the pipeline is accepted and logged.

If there's an error or the request times out, the pipeline is accepted.

Pipelines rejected by the external validation service aren't created, and don't
appear in pipeline lists in the GitLab UI or API. If you create a pipeline in the
UI that is rejected, `Pipeline cannot be run. External validation failed` is displayed.

## Configure external pipeline validation

To configure external pipeline validation, add the
[`EXTERNAL_VALIDATION_SERVICE_URL` environment variable](../environment_variables.md)
and set it to the external service URL.

By default, requests to the external service time out after five seconds. To override
the default, set the `EXTERNAL_VALIDATION_SERVICE_TIMEOUT` environment variable to the
required number of seconds.

## Payload schema

> - `tag_list` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/335904) in GitLab 16.11.

```json
{
  "type": "object",
  "required" : [
    "project",
    "user",
    "credit_card",
    "pipeline",
    "builds",
    "total_builds_count",
    "namespace"
  ],
  "properties" : {
    "project": {
      "type": "object",
      "required": [
        "id",
        "path",
        "created_at",
        "shared_runners_enabled",
        "group_runners_enabled"
      ],
      "properties": {
        "id": { "type": "integer" },
        "path": { "type": "string" },
        "created_at": { "type": ["string", "null"], "format": "date-time" },
        "shared_runners_enabled": { "type": "boolean" },
        "group_runners_enabled": { "type": "boolean" }
      }
    },
    "user": {
      "type": "object",
      "required": [
        "id",
        "username",
        "email",
        "created_at"
      ],
      "properties": {
        "id": { "type": "integer" },
        "username": { "type": "string" },
        "email": { "type": "string" },
        "created_at": { "type": ["string", "null"], "format": "date-time" },
        "current_sign_in_ip": { "type": ["string", "null"] },
        "last_sign_in_ip": { "type": ["string", "null"] },
        "sign_in_count": { "type": "integer" }
      }
    },
    "credit_card": {
      "type": "object",
      "required": [
        "similar_cards_count",
        "similar_holder_names_count"
      ],
      "properties": {
        "similar_cards_count": { "type": "integer" },
        "similar_holder_names_count": { "type": "integer" }
      }
    },
    "pipeline": {
      "type": "object",
      "required": [
        "sha",
        "ref",
        "type"
      ],
      "properties": {
        "sha": { "type": "string" },
        "ref": { "type": "string" },
        "type": { "type": "string" }
      }
    },
    "builds": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "name",
          "stage",
          "image",
          "tag_list",
          "services",
          "script"
        ],
        "properties": {
          "name": { "type": "string" },
          "stage": { "type": "string" },
          "image": { "type": ["string", "null"] },
          "tag_list": { "type": ["array", "null"] },
          "services": {
            "type": ["array", "null"],
            "items": { "type": "string" }
          },
          "script": {
            "type": "array",
            "items": { "type": "string" }
          }
        }
      }
    },
    "total_builds_count": { "type": "integer" },
    "namespace": {
      "type": "object",
      "required": [
        "plan",
        "trial"
      ],
      "properties": {
        "plan": { "type": "string" },
        "trial": { "type": "boolean" }
      }
    },
    "provisioning_group": {
      "type": "object",
      "required": [
        "plan",
        "trial"
      ],
      "properties": {
        "plan": { "type": "string" },
        "trial": { "type": "boolean" }
      }
    }
  }
}
```

The `namespace` field is only available in [GitLab Premium and Ultimate](https://about.gitlab.com/pricing/).
