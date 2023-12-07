---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Audit event streaming examples

The following sections provide examples of audit event streaming.

## Audit event streaming on Git operations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.9 [with a flag](../feature_flags.md) named `audit_event_streaming_git_operations`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/357211) in GitLab 15.0.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/357211) in GitLab 15.1 by default.
> - `details.author_class` field [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363876) in GitLab 15.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101583) in GitLab 15.6. Feature flag `audit_event_streaming_git_operations` removed.

Streaming audit events can be sent when authenticated users push, pull, or clone a project's remote Git repositories:

- [Using SSH](../../user/ssh.md).
- Using HTTP or HTTPS.
- Using **Download** (**{download}**) in GitLab UI.

Audit events are not captured for users that are not signed in. For example, when downloading a public project.

To configure streaming audit events for Git operations, see [Add a new HTTP destination](index.md#add-a-new-http-destination).

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

### Example payloads for SSH events

Fetch:

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 29,
  "entity_type": "Project",
  "details": {
    "author_name": "Administrator",
    "author_class": "User",
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
  "author_name": "Administrator",
  "entity_path": "example-group/example-project",
  "target_details": "example-project",
  "created_at": "2022-02-23T06:21:05.283Z",
  "target_type": "Project",
  "target_id": 29,
  "event_type": "repository_git_operation"
}
```

Push:

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 29,
  "entity_type": "Project",
  "details": {
    "author_name": "Administrator",
    "author_class": "User",
    "target_id": 29,
    "target_type": "Project",
    "target_details": "example-project",
    "custom_message": {
      "protocol": "ssh",
      "action": "git-receive-pack"
    },
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "Administrator",
  "entity_path": "example-group/example-project",
  "target_details": "example-project",
  "created_at": "2022-02-23T06:23:08.746Z",
  "target_type": "Project",
  "target_id": 29,
  "event_type": "repository_git_operation"
}
```

### Example payloads for SSH events with Deploy Key

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363876) in GitLab 15.3.

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

### Example payloads for HTTP and HTTPS events

Fetch:

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 29,
  "entity_type": "Project",
  "details": {
    "author_name": "Administrator",
    "author_class": "User",
    "target_id": 29,
    "target_type": "Project",
    "target_details": "example-project",
    "custom_message": {
      "protocol": "http",
      "action": "git-upload-pack"
    },
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "Administrator",
  "entity_path": "example-group/example-project",
  "target_details": "example-project",
  "created_at": "2022-02-23T06:25:43.938Z",
  "target_type": "Project",
  "target_id": 29,
  "event_type": "repository_git_operation"
}
```

Push:

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 29,
  "entity_type": "Project",
  "details": {
    "author_name": "Administrator",
    "author_class": "User",
    "target_id": 29,
    "target_type": "Project",
    "target_details": "example-project",
    "custom_message": {
      "protocol": "http",
      "action": "git-receive-pack"
    },
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "Administrator",
  "entity_path": "example-group/example-project",
  "target_details": "example-project",
  "created_at": "2022-02-23T06:26:29.294Z",
  "target_type": "Project",
  "target_id": 29,
  "event_type": "repository_git_operation"
}
```

### Example payloads for HTTP and HTTPS events with Deploy Token

Fetch:

```json
{
  "id": 1,
  "author_id": -2,
  "entity_id": 22,
  "entity_type": "Project",
  "details": {
    "author_name": "deploy-token-name",
    "author_class": "DeployToken",
    "target_id": 22,
    "target_type": "Project",
    "target_details": "example-project",
    "custom_message": {
      "protocol": "http",
      "action": "git-upload-pack"
    },
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "deploy-token-name",
  "entity_path": "example-group/example-project",
  "target_details": "example-project",
  "created_at": "2022-07-26T05:46:25.850Z",
  "target_type": "Project",
  "target_id": 22,
  "event_type": "repository_git_operation"
}
```

### Example payloads for events from GitLab UI download button

Fetch:

```json
{
  "id": 1,
  "author_id": 99,
  "entity_id": 29,
  "entity_type": "Project",
  "details": {
    "custom_message": "Repository Download Started",
    "author_name": "example_username",
    "author_class": "User",
    "target_id": 29,
    "target_type": "Project",
    "target_details": "example-group/example-project",
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "example_username",
  "entity_path": "example-group/example-project",
  "target_details": "example-group/example-project",
  "created_at": "2022-02-23T06:27:17.873Z",
  "target_type": "Project",
  "target_id": 29,
  "event_type": "repository_git_operation"
}
```

## Audit event streaming on merge request approval actions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/271162) in GitLab 14.9.

Stream audit events that relate to merge approval actions performed in a project.

### Headers

Headers are formatted as follows:

```plaintext
POST /logs HTTP/1.1
Host: <DESTINATION_HOST>
Content-Type: application/x-www-form-urlencoded
X-Gitlab-Event-Streaming-Token: <DESTINATION_TOKEN>
X-Gitlab-Audit-Event-Type: audit_operation
```

### Example payload

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 6,
  "entity_type": "Project",
  "details": {
    "author_name": "example_username",
    "target_id": 20,
    "target_type": "MergeRequest",
    "target_details": "merge request title",
    "custom_message": "Approved merge request",
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "example_username",
  "entity_path": "example-group/example-project",
  "target_details": "merge request title",
  "created_at": "2022-03-09T06:53:11.181Z",
  "target_type": "MergeRequest",
  "target_id": 20,
  "event_type": "audit_operation"
}
```

## Audit event streaming on merge request create actions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90911) in GitLab 15.2.

Stream audit events that relate to merge request create actions using the `/logs` endpoint.

Send API requests that contain the `X-Gitlab-Audit-Event-Type` header with value `merge_request_create`. GitLab responds with JSON payloads with an
`event_type` field set to `merge_request_create`.

### Headers

Headers are formatted as follows:

```plaintext
POST /logs HTTP/1.1
Host: <DESTINATION_HOST>
Content-Type: application/x-www-form-urlencoded
X-Gitlab-Audit-Event-Type: merge_request_create
X-Gitlab-Event-Streaming-Token: <DESTINATION_TOKEN>
```

### Example payload

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 24,
  "entity_type": "Project",
  "details": {
    "author_name": "example_user",
    "target_id": 132,
    "target_type": "MergeRequest",
    "target_details": "Update test.md",
    "custom_message": "Added merge request",
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "Administrator",
  "entity_path": "example-group/example-project",
  "target_details": "Update test.md",
  "created_at": "2022-07-04T00:19:22.675Z",
  "target_type": "MergeRequest",
  "target_id": 132,
  "event_type": "merge_request_create"
}
```

## Audit event streaming on project fork actions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90916) in GitLab 15.2.

Stream audit events that relate to project fork actions using the `/logs` endpoint.

Send API requests that contain the `X-Gitlab-Audit-Event-Type` header with value `project_fork_operation`. GitLab responds with JSON payloads with an
`event_type` field set to `project_fork_operation`.

### Headers

Headers are formatted as follows:

```plaintext
POST /logs HTTP/1.1
Host: <DESTINATION_HOST>
Content-Type: application/x-www-form-urlencoded
X-Gitlab-Audit-Event-Type: project_fork_operation
X-Gitlab-Event-Streaming-Token: <DESTINATION_TOKEN>
```

### Example payload

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 24,
  "entity_type": "Project",
  "details": {
    "author_name": "example_username",
    "target_id": 24,
    "target_type": "Project",
    "target_details": "example-project",
    "custom_message": "Forked project to another-group/example-project-forked",
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "example_username",
  "entity_path": "example-group/example-project",
  "target_details": "example-project",
  "created_at": "2022-06-30T03:43:35.384Z",
  "target_type": "Project",
  "target_id": 24,
  "event_type": "project_fork_operation"
}
```

## Audit event streaming on project group link actions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90955) in GitLab 15.2.

Stream audit events that relate to project group link creation, updates, and deletion using the `/logs` endpoint.

Send API requests that contain the `X-Gitlab-Audit-Event-Type` header with value of either:

- `project_group_link_create`.
- `project_group_link_update`.
- `project_group_link_destroy`.

GitLab responds with JSON payloads with an `event_type` field set to either:

- `project_group_link_create`.
- `project_group_link_update`.
- `project_group_link_destroy`.

### Example Headers

Headers are formatted as follows:

```plaintext
POST /logs HTTP/1.1
Host: <DESTINATION_HOST>
Content-Type: application/x-www-form-urlencoded
X-Gitlab-Audit-Event-Type: project_group_link_create
X-Gitlab-Event-Streaming-Token: <DESTINATION_TOKEN>
```

### Example payload for project group link create

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 24,
  "entity_type": "Project",
  "details": {
    "author_name": "example-user",
    "target_id": 31,
    "target_type": "Group",
    "target_details": "another-group",
    "custom_message": "Added project group link",
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "example-user",
  "entity_path": "example-group/example-project",
  "target_details": "another-group",
  "created_at": "2022-07-04T00:43:09.318Z",
  "target_type": "Group",
  "target_id": 31,
  "event_type": "project_group_link_create"
}
```

### Example payload for project group link update

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 24,
  "entity_type": "Project",
  "details": {
    "author_name": "example-user",
    "target_id": 31,
    "target_type": "Group",
    "target_details": "another-group",
    "custom_message": "Changed project group link profile group_access from Developer to Guest",
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "example-user",
  "entity_path": "example-group/example-project",
  "target_details": "another-group",
  "created_at": "2022-07-04T00:43:28.328Z",
  "target_type": "Group",
  "target_id": 31,
  "event_type": "project_group_link_update"
}
```

### Example payload for project group link delete

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 24,
  "entity_type": "Project",
  "details": {
    "author_name": "example-user",
    "target_id": 31,
    "target_type": "Group",
    "target_details": "another-group",
    "custom_message": "Removed project group link",
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "example-user",
  "entity_path": "example-group/example-project",
  "target_details": "another-group",
  "created_at": "2022-07-04T00:42:56.279Z",
  "target_type": "Group",
  "target_id": 31,
  "event_type": "project_group_link_destroy"
}
```

## Audit event streaming on invalid merge request approver state

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/374566) in GitLab 15.5.

Stream audit events that relate to invalid merge request approver states in a project.

### Headers

Headers are formatted as follows:

```plaintext
POST /logs HTTP/1.1
Host: <DESTINATION_HOST>
Content-Type: application/x-www-form-urlencoded
X-Gitlab-Event-Streaming-Token: <DESTINATION_TOKEN>
X-Gitlab-Audit-Event-Type: audit_operation
```

### Example payload

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 6,
  "entity_type": "Project",
  "details": {
    "author_name": "example_username",
    "target_id": 20,
    "target_type": "MergeRequest",
    "target_details": { title: "Merge request title", iid: "Merge request iid", id: "Merge request id" },
    "custom_message": "Invalid merge request approver rules",
    "ip_address": "127.0.0.1",
    "entity_path": "example-group/example-project"
  },
  "ip_address": "127.0.0.1",
  "author_name": "example_username",
  "entity_path": "example-group/example-project",
  "target_details": "merge request title",
  "created_at": "2022-03-09T06:53:11.181Z",
  "target_type": "MergeRequest",
  "target_id": 20,
  "event_type": "audit_operation"
}
```
