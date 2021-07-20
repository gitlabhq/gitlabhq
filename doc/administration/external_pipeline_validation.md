---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# External pipeline validation **(FREE SELF)**

You can use an external service to validate a pipeline before it's created.

WARNING:
This is an experimental feature and subject to change without notice.

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
[`EXTERNAL_VALIDATION_SERVICE_URL` environment variable](environment_variables.md)
and set it to the external service URL.

By default, requests to the external service time out after five seconds. To override
the default, set the `EXTERNAL_VALIDATION_SERVICE_TIMEOUT` environment variable to the
required number of seconds.

## Payload schema

```json
{
  "type": "object",
  "required" : [
    "project",
    "user",
    "pipeline",
    "builds",
    "namespace"
  ],
  "properties" : {
    "project": {
      "type": "object",
      "required": [
        "id",
        "path",
        "created_at"
      ],
      "properties": {
        "id": { "type": "integer" },
        "path": { "type": "string" },
        "created_at": { "type": ["string", "null"], "format": "date-time" }
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
        "last_sign_in_ip": { "type": ["string", "null"] }
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
          "services",
          "script"
        ],
        "properties": {
          "name": { "type": "string" },
          "stage": { "type": "string" },
          "image": { "type": ["string", "null"] },
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

The `namespace` field is only available in [GitLab Premium](https://about.gitlab.com/pricing/)
and higher.
