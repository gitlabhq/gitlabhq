---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# External Pipeline Validation

You can use an external service for validating a pipeline before it's created.

WARNING:
This is an experimental feature and subject to change without notice.

## Usage

GitLab sends a POST request to the external service URL with the pipeline
data as payload. GitLab then invalidates the pipeline based on the response
code. If there's an error or the request times out, the pipeline is not
invalidated.

Response Code Legend:

- `200` - Accepted
- `406` - Not Accepted
- Other Codes - Accepted and Logged

## Configuration

To configure external pipeline validation:

1. Set the `EXTERNAL_VALIDATION_SERVICE_URL` environment variable to the external
   service URL.
1. Enable the `ci_external_validation_service` feature flag.

By default, requests to the external service time out after five seconds. To override
the default, set the `EXTERNAL_VALIDATION_SERVICE_TIMEOUT` environment variable to the
required number of seconds.

## Payload Schema

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
        "created_at": { "type": ["string", "null"], "format": "date-time" }
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
    }
  }
}
```
