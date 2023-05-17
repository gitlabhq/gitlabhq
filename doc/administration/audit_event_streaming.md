---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Audit event streaming **(ULTIMATE)**

> - API [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.5 [with a flag](../administration/feature_flags.md) named `ff_external_audit_events_namespace`. Disabled by default.
> - API [Enabled on GitLab.com and by default on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/338939) in GitLab 14.7.
> - API [Feature flag `ff_external_audit_events_namespace`](https://gitlab.com/gitlab-org/gitlab/-/issues/349588) removed in GitLab 14.8.
> - UI [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336411) in GitLab 14.9.
> - [Subgroup events recording](https://gitlab.com/gitlab-org/gitlab/-/issues/366878) fixed in GitLab 15.2.
> - Custom HTTP headers API [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/361216) in GitLab 15.1 [with a flag](feature_flags.md) named `streaming_audit_event_headers`. Disabled by default.
> - Custom HTTP headers API [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/362941) in GitLab 15.2.
> - Custom HTTP headers API [made generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/366524) in GitLab 15.3. [Feature flag `streaming_audit_event_headers`](https://gitlab.com/gitlab-org/gitlab/-/issues/362941) removed.
> - Custom HTTP headers UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/361630) in GitLab 15.2 [with a flag](feature_flags.md) named `custom_headers_streaming_audit_events_ui`. Disabled by default.
> - Custom HTTP headers UI [made generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/365259) in GitLab 15.3. [Feature flag `custom_headers_streaming_audit_events_ui`](https://gitlab.com/gitlab-org/gitlab/-/issues/365259) removed.
> - [Improved user experience](https://gitlab.com/gitlab-org/gitlab/-/issues/367963) in GitLab 15.3.
> - User-specified verification token API support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360813) in GitLab 15.4.
> - Event type filters API [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/344845) in GitLab 15.7.

Users can set a streaming destination for a top-level group to receive all audit events about the group, its subgroups, and
projects as structured JSON.

Top-level group owners can manage their audit logs in third-party systems. Any service that can receive
structured JSON data can be used as the streaming destination.

Each streaming destination can have up to 20 custom HTTP headers included with each streamed event.

NOTE:
GitLab can stream a single event more than once to the same destination. Use the `id` key in the payload to deduplicate incoming data.

## Add a new streaming destination

WARNING:
Streaming destinations receive **all** audit event data, which could include sensitive information. Make sure you trust the streaming destination.

### Use the GitLab UI

Users with the Owner role for a group can add streaming destinations for it:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Security and Compliance > Audit events**.
1. On the main area, select **Streams** tab.
1. Select **Add streaming destination** to show the section for adding destinations.
1. Enter the destination URL to add.
1. Optional. Locate the **Custom HTTP headers** table.
1. Ignore the **Active** checkbox because it isn't functional. To track progress on adding functionality to the
   **Active** checkbox, see [issue 367509](https://gitlab.com/gitlab-org/gitlab/-/issues/367509).
1. Select **Add header** to create a new name and value pair. Enter as many name and value pairs as required. You can add up to
   20 headers per streaming destination.
1. After all headers have been filled out, select **Add** to add the new streaming destination.

### Use the API

To enable streaming and add a destination, users with the Owner role for a group must use the
`externalAuditEventDestinationCreate` mutation in the GraphQL API.

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", groupPath: "my-group" } ) {
    errors
    externalAuditEventDestination {
      id
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

Group owners can also optionally specify their own verification token (instead of the default GitLab-generated one) using the GraphQL `auditEventsStreamingHeadersCreate`
mutation. Verification token length must be within 16 to 24 characters and trailing whitespace are not trimmed. GitLab recommends setting a cryptographically random and unique value. For example:

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", groupPath: "my-group", verificationToken: "unique-random-verification-token-here" } ) {
    errors
    externalAuditEventDestination {
      id
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

Group owners can add an HTTP header using the GraphQL `auditEventsStreamingHeadersCreate` mutation. You can retrieve the destination ID
by [listing all the streaming destinations](#use-the-api-1) for the group or from the mutation above.

```graphql
mutation {
  auditEventsStreamingHeadersCreate(input: { destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/24601", key: "foo", value: "bar" }) {
    errors
  }
}
```

The header is created if the returned `errors` object is empty.

## List streaming destinations

Users with the Owner role for a group can list streaming destinations.

### Use the GitLab UI

To list the streaming destinations:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Security and Compliance > Audit events**.
1. On the main area, select **Streams** tab.
1. To the right of the item, select **Edit** (**{pencil}**) to see all the custom HTTP headers.

### Use the API

Users with the Owner role for a group can view a list of streaming destinations at any time using the
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
        headers {
          nodes {
            key
            value
            id
          }
        }
        eventTypeFilters
      }
    }
  }
}
```

If the resulting list is empty, then audit streaming is not enabled for that group.

You need the ID values returned by this query for the update and delete mutations.

## Update streaming destinations

Users with the Owner role for a group can update streaming destinations.

### Use the GitLab UI

To update a streaming destinations custom HTTP headers:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Security and Compliance > Audit events**.
1. On the main area, select **Streams** tab.
1. To the right of the item, select **Edit** (**{pencil}**).
1. Locate the **Custom HTTP headers** table.
1. Locate the header that you wish to update.
1. Ignore the **Active** checkbox because it isn't functional. To track progress on adding functionality to the
   **Active** checkbox, see [issue 367509](https://gitlab.com/gitlab-org/gitlab/-/issues/367509).
1. Select **Add header** to create a new name and value pair. Enter as many name and value pairs as required. You can add up to
   20 headers per streaming destination.
1. Select **Save** to update the streaming destination.

### Use the API

Users with the Owner role for a group can update streaming destinations custom HTTP headers using the
`auditEventsStreamingHeadersUpdate` mutation type. You can retrieve the custom HTTP headers ID
by [listing all the custom HTTP headers](#use-the-api-1) for the group.

```graphql
mutation {
  externalAuditEventDestinationDestroy(input: { id: destination }) {
    errors
  }
}
```

Streaming destination is updated if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

Group owners can remove an HTTP header using the GraphQL `auditEventsStreamingHeadersDestroy` mutation. You can retrieve the header ID
by [listing all the custom HTTP headers](#use-the-api-1) for the group.

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

The header is deleted if the returned `errors` object is empty.

## Delete streaming destinations

Users with the Owner role for a group can delete streaming destinations.

When the last destination is successfully deleted, streaming is disabled for the group.

### Use the GitLab UI

To delete a streaming destination:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Security and Compliance > Audit events**.
1. On the main area, select the **Streams** tab.
1. To the right of the item, select **Delete** (**{remove}**).

To delete only the custom HTTP headers for a streaming destination:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Security and Compliance > Audit events**.
1. On the main area, select the **Streams** tab.
1. To the right of the item, **Edit** (**{pencil}**).
1. Locate the **Custom HTTP headers** table.
1. Locate the header that you wish to remove.
1. To the right of the header, select **Delete** (**{remove}**).
1. Select **Save** to update the streaming destination.

### Use the API

Users with the Owner role for a group can delete streaming destinations using the
`externalAuditEventDestinationDestroy` mutation type. You can retrieve the destinations ID
by [listing all the streaming destinations](#use-the-api-1) for the group.

```graphql
mutation {
  externalAuditEventDestinationDestroy(input: { id: destination }) {
    errors
  }
}
```

Streaming destination is deleted if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

Group owners can remove an HTTP header using the GraphQL `auditEventsStreamingHeadersDestroy` mutation. You can retrieve the header ID
by [listing all the custom HTTP headers](#use-the-api-1) for the group.

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

The header is deleted if the returned `errors` object is empty.

## Verify event authenticity

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345424) in GitLab 14.8.

Each streaming destination has a unique verification token (`verificationToken`) that can be used to verify the authenticity of the event. This
token is either specified by the Owner or generated automatically when the event destination is created and cannot be changed.

Each streamed event contains the verification token in the `X-Gitlab-Event-Streaming-Token` HTTP header that can be verified against
the destination's value when [listing streaming destinations](#list-streaming-destinations).

### Use the GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360814) in GitLab 15.2.

Users with the Owner role for a group can list streaming destinations and see the verification tokens:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Security and Compliance > Audit events**.
1. On the main area, select the **Streams**.
1. View the verification token on the right side of each item.

## Event type filters

> Event type filters API [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/344845) in GitLab 15.7.

When this feature is enabled for a group, you can use an API to permit users to filter streamed audit events per destination.
If the feature is enabled with no filters, the destination receives all audit events.

A streaming destination that has an event type filter set has a **filtered** (**{filter}**) label.

### Use the API to add an event type filter

Prerequisites:

- You must have the Owner role for the group.

You can add a list of event type filters using the `auditEventsStreamingDestinationEventsAdd` query type:

```graphql
mutation {
    auditEventsStreamingDestinationEventsAdd(input: {
        destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
        eventTypeFilters: ["list of event type filters"]}){
        errors
        eventTypeFilters
    }
}
```

Event type filters are added if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

### Use the API to remove an event type filter

Prerequisites:

- You must have the Owner role for the group.

You can remove a list of event type filters using the `auditEventsStreamingDestinationEventsRemove` query type:

```graphql
mutation {
    auditEventsStreamingDestinationEventsRemove(input: {
    destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
    eventTypeFilters: ["list of event type filters"]
  }){
    errors
  }
}
```

Event type filters are removed if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

## Payload schema

> Documentation for an audit event streaming schema was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358149) in GitLab 15.3.

Streamed audit events have a predictable schema in the body of the response.

| Field            | Description                                                | Notes                                                                             |
|------------------|------------------------------------------------------------|-----------------------------------------------------------------------------------|
| `author_id`      | User ID of the user who triggered the event                |                                                                                   |
| `author_name`    | Human-readable name of the author that triggered the event | Helpful when the author no longer exists                                          |
| `created_at`     | Timestamp when event was triggered                         |                                                                                   |
| `details`        | JSON object containing additional metadata                 | Has no defined schema but often contains additional information about an event    |
| `entity_id`      | ID of the audit event's entity                             |                                                                                   |
| `entity_path`    | Full path of the entity affected by the auditable event    |                                                                                   |
| `entity_type`    | String representation of the type of entity                | Acceptable values include `User`, `Group`, and `Key`. This list is not exhaustive |
| `event_type`     | String representation of the type of audit event           |                                                                                   |
| `id`             | Unique identifier for the audit event                      | Can be used for deduplication if required                                         |
| `ip_address`     | IP address of the host used to trigger the event           |                                                                                   |
| `target_details` | Additional details about the target                        |                                                                                   |
| `target_id`      | ID of the audit event's target                             |                                                                                   |
| `target_type`    | String representation of the target's type                 |                                                                                   |

### JSON payload schema

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

## Audit event streaming on Git operations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.9 [with a flag](../administration/feature_flags.md) named `audit_event_streaming_git_operations`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/357211) in GitLab 15.0.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/357211) in GitLab 15.1 by default.
> - [Added `details.author_class` field](https://gitlab.com/gitlab-org/gitlab/-/issues/363876) in GitLab 15.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101583) in GitLab 15.6. Feature flag `audit_event_streaming_git_operations` removed.

Streaming audit events can be sent when authenticated users push, pull, or clone a project's remote Git repositories:

- [Using SSH](../user/ssh.md).
- Using HTTP or HTTPS.
- Using the **Download** button (**{download}**) in GitLab UI.

Audit events are not captured for users that are not signed in. For example, when downloading a public project.

To configure streaming audit events for Git operations, see [Add a new streaming destination](#add-a-new-streaming-destination).

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

## Audit event streaming on invalid merge request approver state

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/374566) in GitLab 15.5.

Stream audit events that relate to invalid merge request approver states within a project.

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
