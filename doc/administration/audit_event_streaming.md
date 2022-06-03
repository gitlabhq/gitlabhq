---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Audit event streaming **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.5 [with a flag](../administration/feature_flags.md) named `ff_external_audit_events_namespace`. Disabled by default.
> - [Enabled on GitLab.com and by default on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/338939) in GitLab 14.7.
> - [Feature flag `ff_external_audit_events_namespace`](https://gitlab.com/gitlab-org/gitlab/-/issues/349588) removed in GitLab 14.8.

Event streaming allows owners of top-level groups to set an HTTP endpoint to receive **all** audit events about the group, and its
subgroups and projects as structured JSON.

Top-level group owners can manage their audit logs in third-party systems such as Splunk, using the Splunk
[HTTP Event Collector](https://docs.splunk.com/Documentation/Splunk/8.2.2/Data/UsetheHTTPEventCollector). Any service that can receive
structured JSON data can be used as the endpoint.

NOTE:
GitLab can stream a single event more than once to the same destination. Use the `id` key in the payload to deduplicate incoming data.

## Add a new event streaming destination

WARNING:
Event streaming destinations receive **all** audit event data, which could include sensitive information. Make sure you trust the destination endpoint.

### Use the GitLab UI

Users with at least the Owner role for a group can add event streaming destinations for it:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Audit events**
1. On the main area, select **Streams** tab.
    - When the destination list is empty, select **Add stream** activate edit mode and add a new destination.
    - When the destination list is not empty, select **{plus}** under the **Streams** tab to activate edit mode.
1. Enter the endpoint you wish to add and select **Add**.

Event streaming is enabled if:

- No warning is shown.
- The added endpoint is displayed in the UI.

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
1. On the left sidebar, select **Security & Compliance > Audit events**
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

Users with at least the Owner role for a group can delete event streaming destinations.

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Audit events**
1. On the main area, select **Streams** tab.
1. Select **{remove}** at the right side of each item.

The external streaming destination is deleted when:

- No warning is shown.
- The deleted endpoint is not displayed in the UI.

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

## Verify event authenticity

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345424) in GitLab 14.8.

Each streaming destination has a unique verification token (`verificationToken`) that can be used to verify the authenticity of the event. This
token is generated when the event destination is created and cannot be changed.

Each streamed event contains a random alphanumeric identifier for the `X-Gitlab-Event-Streaming-Token` HTTP header that can be verified against
the destination's value when [listing streaming destinations](#list-streaming-destinations).

## Audit event streaming on Git operations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.9 [with a flag](../administration/feature_flags.md) named `audit_event_streaming_git_operations`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/357211) in GitLab 15.0.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](feature_flags.md) named `audit_event_streaming_git_operations`. On GitLab.com, this feature is available.

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
