---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Audit Event schema and examples

## Audit Event schema

> - Documentation for an audit event streaming schema was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358149) in GitLab 15.3.

Audit events have a predictable schema in the body of the response.

| Field            | Description                                                | Notes                                                                             |
Streaming Only Field                                                                             |
|------------------|------------------------------------------------------------|-----------------------------------------------------------------------------------|
-----------------------------------------------------------------------------------|
| `author_id`      | User ID of the user who triggered the event                |                                                                                   |      |
| `author_name`    | Human-readable name of the author that triggered the event | Helpful when the author no longer exists                                          | :white_check_mark:      |
| `created_at`     | Timestamp when event was triggered                         |                                                                                   |       |
| `details`        | JSON object containing additional metadata                 | Has no defined schema but often contains additional information about an event    |       |
| `entity_id`      | ID of the audit event's entity                             |                                                                                   |       |
| `entity_path`    | Full path of the entity affected by the auditable event    |                                                                                   | :white_check_mark:      |
| `entity_type`    | String representation of the type of entity                | Acceptable values include `User`, `Group`, and `Key`. This list is not exhaustive |       |
| `event_type`     | String representation of the type of audit event           |                                                                                   | :white_check_mark:      |
| `id`             | Unique identifier for the audit event                      | Can be used for deduplication if required                                         |       |
| `ip_address`     | IP address of the host used to trigger the event           |                                                                                   | :white_check_mark:      |
| `target_details` | Additional details about the target                        |                                                                                   | :white_check_mark:      |
| `target_id`      | ID of the audit event's target                             |                                                                                   | :white_check_mark:      |
| `target_type`    | String representation of the target's type                 |                                                                                   | :white_check_mark:      |

### Audit Event JSON schema

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

## Example: audit event streaming on Git operations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.9 [with a flag](feature_flags.md) named `audit_event_streaming_git_operations`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/357211) in GitLab 15.0.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/357211) in GitLab 15.1 by default.
> - `details.author_class` field [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363876) in GitLab 15.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101583) in GitLab 15.6. Feature flag `audit_event_streaming_git_operations` removed.

Streaming audit events can be sent when authenticated users push, pull, or clone a project's remote Git repositories:

- [Using SSH](../user/ssh.md).
- Using HTTP or HTTPS.
- Using **Download** (**{download}**) in GitLab UI.

Audit events are not captured for users that are not signed in. For example, when downloading a public project.

### Headers

> `X-Gitlab-Audit-Event-Type` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86881) in GitLab 15.0.

Headers are formatted as follows:

```plaintext
POST /logs HTTP/1.1
Host: <DESTINATION_HOST>
Content-Type: application/x-www-form-urlencoded
X-Gitlab-Event-Streaming-Token: <DESTINATION_TOKEN>
X-Gitlab-Audit-Event-Type: repository_git_operation
```

### Example payloads for Git over SSH events with Deploy Key

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363876) in GitLab 15.3.

Fetch:

```json
{
  "id": 1,
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
