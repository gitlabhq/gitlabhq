---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Audit event streaming **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.5 [with a flag](../administration/feature_flags.md) named `ff_external_audit_events_namespace`. Disabled by default.
> - [Enabled on GitLab.com and by default on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/338939) in GitLab 14.7.
> - [Feature flag `ff_external_audit_events_namespace`](https://gitlab.com/gitlab-org/gitlab/-/issues/349588) removed in GitLab 14.8.
> - [Subgroup events recording](https://gitlab.com/gitlab-org/gitlab/-/issues/366878) fixed in GitLab 15.2.

Users can set an HTTP endpoint for a top-level group to receive all audit events about the group, its subgroups, and
projects as structured JSON.

Top-level group owners can manage their audit logs in third-party systems. Any service that can receive
structured JSON data can be used as the endpoint.

NOTE:
GitLab can stream a single event more than once to the same destination. Use the `id` key in the payload to deduplicate incoming data.

## Add a new event streaming destination

WARNING:
Event streaming destinations receive **all** audit event data, which could include sensitive information. Make sure you trust the destination endpoint.

### Use the GitLab UI

Users with at least the Owner role for a group can add event streaming destinations for it:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Audit events**.
1. On the main area, select **Streams** tab.
    - When the destination list is empty, select **Add stream** to show the section for adding destinations.
    - When the destination list is not empty, select **{plus}** to show the section for adding destinations.
1. Enter the destination URL to add and select **Add**.

### Use the API

To enable event streaming and add a destination, users with at least the Owner role for a group must use the
`externalAuditEventDestinationCreate` mutation in the GraphQL API.

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", groupPath: "my-group" } ) {
    errors
    externalAuditEventDestination {
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

Event streaming is enabled if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

## List streaming destinations

Users with at least the Owner role for a group can list event streaming destinations.

### Use the GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336411) in GitLab 14.9.

Users with at least the Owner role for a group can list event streaming destinations:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Audit events**.
1. On the main area, select **Streams** tab.

### Use the API

Users with at least the Owner role for a group can view a list of event streaming destinations at any time using the
`externalAuditEventDestinations` query type.

```graphql
query {
  group(fullPath: "my-group") {
    id
    externalAuditEventDestinations {
      nodes {
        destinationUrl
        verificationToken
        id
      }
    }
  }
}
```

If the resulting list is empty, then audit event streaming is not enabled for that group.

## Delete streaming destinations

Users with at least the Owner role for a group can delete event streaming destinations using the
`deleteAuditEventDestinations` mutation type.

When the last destination is successfully deleted, event streaming is disabled for the group.

### Use the GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336411) in GitLab 14.9.

Users with at least the Owner role for a group can delete event streaming destinations:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Audit events**.
1. On the main area, select **Streams** tab.
1. Select **{remove}** at the right side of each item.

### Use the API

Delete an event streaming destination by specifying an ID. Get the required ID by
[listing the details](audit_event_streaming.md#use-the-api-1) of event
streaming destinations.

```graphql
mutation {
  externalAuditEventDestinationDestroy(input: { id: destination }) {
    errors
  }
}
```

Destination is deleted if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

## Custom HTTP headers

> - API [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/361216) in GitLab 15.1 [with a flag](feature_flags.md) named `streaming_audit_event_headers`. Disabled by default.
> - API [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/362941) in GitLab 15.2.
> - UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/361630) in GitLab 15.2 [with a flag](feature_flags.md) named `custom_headers_streaming_audit_events_ui`. Disabled by default.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/366524) in GitLab 15.3.

Each streaming destination can have up to 20 custom HTTP headers included with each streamed event.

### Adding custom HTTP headers

Add custom HTTP headers with the API or GitLab UI.

#### Use the API

Group owners can add a HTTP header using the GraphQL `auditEventsStreamingHeadersCreate` mutation. You can retrieve the destination ID
by [listing the external audit destinations](#list-streaming-destinations) on the group.

```graphql
mutation {
  auditEventsStreamingHeadersCreate(input: { destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/24601", key: "foo", value: "bar" }) {
    errors
  }
}
```

The header is created if the returned `errors` object is empty.

#### Use the GitLab UI

FLAG:
On self-managed GitLab, by default the UI for this feature is not available. To make it available per group, ask an administrator to
[enable the feature flag](../administration/feature_flags.md) named `custom_headers_streaming_audit_events_ui`. On GitLab.com, the UI for this feature is
not available. The UI for this feature is not ready for production use.

Users with at least the Owner role for a group can add event streaming destinations and custom HTTP headers for it:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Audit events**.
1. On the main area, select **Streams** tab.
    - When the destination list is empty, select **Add stream** to show the section for adding destinations.
    - When the destination list is not empty, select **{plus}** to show the section for adding destinations.
1. Enter the destination URL to add.
1. Locate the **Custom HTTP headers** table.
1. In the **Header** column, add the header's name.
1. In the **Value** column, add the header's value.
1. Ignore the **Active** checkbox because it isn't functional. To track progress on adding functionality to the **Active** checkbox, see the
   [relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/361925).
1. Enter as many name and value pairs as required. When you enter a unique name and a value for a header, a new row in the table automatically appears. You can add up to
   20 headers per endpoint.
1. After all headers have been filled out, select **Add** to add the new endpoint.

### Updating custom HTTP headers

Add custom HTTP headers with the API or GitLab UI.

#### Use the API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/361964) in GitLab 15.2.

Group owners can update a HTTP header using the GraphQL `auditEventsStreamingHeadersCreate` mutation.

```graphql
mutation {
  auditEventsStreamingHeadersUpdate(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/24255", key: "new-foo", value: "new-bar" }) {
    errors
  }
}
```

#### Use the GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91986) in GitLab 15.3 [with a flag](feature_flags.md) named `custom_headers_streaming_audit_events_ui`. Disabled by default.

FLAG:
On self-managed GitLab, by default the UI for this feature is not available. To make it available per group, ask an administrator to
[enable the feature flag](../administration/feature_flags.md) named `custom_headers_streaming_audit_events_ui`. On GitLab.com, the UI for this feature is
not available. The UI for this feature is not ready for production use.

Users with at least the Owner role for a group can add event streaming destinations and custom HTTP headers for it:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Audit events**.
1. On the main area, select **Streams** tab.
1. Select **{pencil}** at the right side of an item.
1. Locate the **Custom HTTP headers** table.
1. Locate the header that you wish to update.
1. In the **Header** column, you can change the header's name.
1. In the **Value** column, you can change the header's value.
1. Ignore the **Active** checkbox because it isn't functional. To track progress on adding functionality to the **Active** checkbox, see the
   [relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/361925).
1. Select **Save** to update the endpoint.

### Deleting custom HTTP headers

Deleting custom HTTP headers with the API or GitLab UI.

#### Use the API

Group owners can remove a HTTP header using the GraphQL `auditEventsStreamingHeadersDestroy` mutation. You can retrieve the header ID
by [listing all the custom headers](#list-all-custom-headers) on the group.

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

The header is deleted if the returned `errors` object is empty.

#### Use the GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91986) in GitLab 15.3 [with a flag](feature_flags.md) named `custom_headers_streaming_audit_events_ui`. Disabled by default.

FLAG:
On self-managed GitLab, by default the UI for this feature is not available. To make it available per group, ask an administrator to
[enable the feature flag](../administration/feature_flags.md) named `custom_headers_streaming_audit_events_ui`. On GitLab.com, the UI for this feature is
not available. The UI for this feature is not ready for production use.

Users with at least the Owner role for a group can delete event streaming destinations:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Audit events**.
1. On the main area, select **Streams** tab.
1. Select **{pencil}** at the right side of an item.
1. Locate the **Custom HTTP headers** table.
1. Locate the header that you wish to remove.
1. Select **{remove}** at the right side of the header.
1. Select **Save** to update the endpoint.

### List all custom headers

List all custom HTTP headers with the API or GitLab UI.

#### Use the API

You can list all custom headers for a top-level group as well as their value and ID using the GraphQL `externalAuditEventDestinations` query. The ID
value returned by this query is what you need to pass to the `deletion` mutation.

```graphql
query {
  group(fullPath: "your-group") {
    id
    externalAuditEventDestinations {
      nodes {
        destinationUrl
        id
        headers {
          nodes {
            key
            value
            id
          }
        }
      }
    }
  }
}
```

#### Use the GitLab UI

FLAG:
On self-managed GitLab, by default the UI for this feature is not available. To make it available per group, ask an administrator to
[enable the feature flag](../administration/feature_flags.md) named `custom_headers_streaming_audit_events_ui`. On GitLab.com, the UI for this feature is
not available. The UI for this feature is not ready for production use.

Users with at least the Owner role for a group can add event streaming destinations and custom HTTP headers for it:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Audit events**.
1. On the main area, select **Streams** tab.
1. Select **{pencil}** at the right side of an item.

## Verify event authenticity

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345424) in GitLab 14.8.

Each streaming destination has a unique verification token (`verificationToken`) that can be used to verify the authenticity of the event. This
token is generated when the event destination is created and cannot be changed.

Each streamed event contains a random alphanumeric identifier for the `X-Gitlab-Event-Streaming-Token` HTTP header that can be verified against
the destination's value when [listing streaming destinations](#list-streaming-destinations).

### Use the GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360814) in GitLab 15.2.

Users with at least the Owner role for a group can list event streaming destinations and see the verification tokens:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Audit events**.
1. On the main area, select **Streams**.
1. View the verification token on the right side of each item.

## Audit event streaming on Git operations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.9 [with a flag](../administration/feature_flags.md) named `audit_event_streaming_git_operations`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/357211) in GitLab 15.0.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/357211) in GitLab 15.1 by default.
> - [Added `details.author_class` field](https://gitlab.com/gitlab-org/gitlab/-/issues/363876) in GitLab 15.3.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the
feature, ask an administrator to [disable the feature flag](feature_flags.md) named `audit_event_streaming_git_operations`.

Streaming audit events can be sent when signed-in users push or pull a project's remote Git repositories:

- [Using SSH](../user/ssh.md).
- Using HTTP or HTTPS.
- Using the **Download** button (**{download}**) in GitLab UI.

Audit events are not captured for users that are not signed in. For example, when downloading a public project.

To configure streaming audit events for Git operations, see [Add a new event streaming destination](#add-a-new-event-streaming-destination).

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

#### Example payloads for SSH events with Deploy Key

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363876) in GitLab 15.3 [with a flag](../administration/feature_flags.md) named `audit_event_streaming_git_operations_deploy_key_event`. Disabled by default.

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

#### Example payloads for HTTP and HTTPS events with Deploy Token

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

Stream audit events that relate to merge approval actions performed within a project.

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
