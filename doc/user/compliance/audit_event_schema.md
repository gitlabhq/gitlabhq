---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Audit event schema and examples
---

## Audit event schema

> - Documentation for an audit event streaming schema was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358149) in GitLab 15.3.

Audit events have a predictable schema in the body of the response.

| Field            | Description                                                | Notes                                                                             | Streaming Only Field                                                                             |
|------------------|------------------------------------------------------------|-----------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| `author_id`      | User ID of the user who triggered the event                |                                                                                   | **{dotted-circle}** No    |
| `author_name`    | Human-readable name of the author that triggered the event | Helpful when the author no longer exists                                          | **{check-circle}** Yes      |
| `created_at`     | Timestamp when event was triggered                         |                                                                                   | **{dotted-circle}** No     |
| `details`        | JSON object containing additional metadata                 | Has no defined schema but often contains additional information about an event    | **{dotted-circle}** No     |
| `entity_id`      | ID of the audit event's entity                             |                                                                                   | **{dotted-circle}** No     |
| `entity_path`    | Full path of the entity affected by the auditable event    |                                                                                   | **{check-circle}** Yes      |
| `entity_type`    | String representation of the type of entity                | Acceptable values include `User`, `Group`, and `Key`. This list is not exhaustive | **{dotted-circle}** No      |
| `event_type`     | String representation of the type of audit event           |                                                                                   | **{check-circle}** Yes      |
| `id`             | Unique identifier for the audit event                      | Can be used for deduplication if required                                         | **{dotted-circle}** No     |
| `ip_address`     | IP address of the host used to trigger the event           |                                                                                   | **{check-circle}** Yes      |
| `target_details` | Additional details about the target                        |                                                                                   | **{check-circle}** Yes      |
| `target_id`      | ID of the audit event's target                             |                                                                                   | **{check-circle}** Yes      |
| `target_type`    | String representation of the target's type                 |                                                                                   | **{check-circle}** Yes      |

### Audit event JSON schema

```json
{
  "properties": {
    "id": {
      "type": "string"
    },
    "author_id": {
      "type": "integer"
    },
    "author_name": {
      "type": "string"
    },
    "details": {},
    "ip_address": {
      "type": "string"
    },
    "entity_id": {
      "type": "integer"
    },
    "entity_path": {
      "type": "string"
    },
    "entity_type": {
      "type": "string"
    },
    "event_type": {
      "type": "string"
    },
    "target_id": {
      "type": "integer"
    },
    "target_type": {
      "type": "string"
    },
    "target_details": {
      "type": "string"
    },
  },
  "type": "object"
}
```

### Headers

> - `X-Gitlab-Audit-Event-Type` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86881) in GitLab 15.0.

Headers are formatted as follows:

```plaintext
POST /logs HTTP/1.1
Host: <DESTINATION_HOST>
Content-Type: application/x-www-form-urlencoded
X-Gitlab-Event-Streaming-Token: <DESTINATION_TOKEN>
X-Gitlab-Audit-Event-Type: repository_git_operation
```

## Example: audit event streaming on Git operations

Streaming audit events can be sent when authenticated users push, pull, or clone a project's remote Git repositories:

- [Using SSH](../ssh.md).
- Using HTTP or HTTPS.
- Using **Download** (**{download}**) in GitLab UI.

Audit events are not captured for users that are not signed in. For example, when downloading a public project.

### Example: audit event payloads for Git over SSH events with deploy key

Fetch:

```json
{
  "id": "1",
  "author_id": -3,
  "entity_id": 29,
  "entity_type": "Project",
  "details": {
    "author_name": "deploy-key-name",
    "author_class": "DeployKey",
    "target_id": 29,
    "target_type": "Project",
    "target_details": "example-project",
    "custom_message": {
      "protocol": "ssh",
      "action": "git-upload-pack"
    },
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "deploy-key-name",
  "entity_path": "example-group/example-project",
  "target_details": "example-project",
  "created_at": "2022-07-26T05:43:53.662Z",
  "target_type": "Project",
  "target_id": 29,
  "event_type": "repository_git_operation"
}
```
