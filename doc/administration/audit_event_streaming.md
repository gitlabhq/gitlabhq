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
Event streaming destinations will receive **all** audit event data, which could include sensitive information. Make sure you trust the destination endpoint.

To enable event streaming, a group owner must add a new event streaming destination using the `externalAuditEventDestinationCreate` mutation
in the GraphQL API.

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", groupPath: "my-group" } ) {
    errors
    externalAuditEventDestination {
      destinationUrl
      group {
      verificationToken
        name
      }
    }
  }
}
```

Event streaming is enabled if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

## List currently enabled streaming destinations

Group owners can view a list of event streaming destinations at any time using the `externalAuditEventDesinations` query type.

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

## Verify event authenticity

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345424) in GitLab 14.8.

Each streaming destination has a unique verification token (`verificationToken`) that can be used to verify the authenticity of the event. This
token is generated when the event destination is created and cannot be changed.

Each streamed event contains a random alphanumeric identifier for the `X-Gitlab-Event-Streaming-Token` HTTP header that can be verified against
the destination's value when [listing streaming destinations](#list-currently-enabled-streaming-destinations).

## Audit event streaming on Git operations

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.9 [with a flag](../administration/feature_flags.md) named `audit_event_streaming_git_operations`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](feature_flags.md) named `audit_event_streaming_git_operations`. On GitLab.com, this feature is not available.

Streaming audit events can be sent when signed-in users push or pull a project's remote Git repositories:

- [Using SSH](../ssh/index.md).
- Using HTTP or HTTPS.
- Using the **Download** button (**{download}**) in GitLab UI.

Audit events are not captured for users that are not signed in. For example, when downloading a public project.

To configure streaming audit events for Git operations, see [Add a new event streaming destination](#add-a-new-event-streaming-destination).

### Request headers

Request headers are formatted as follows:

```plaintext
POST /logs HTTP/1.1
Host: <DESTINATION_HOST>
Content-Type: application/x-www-form-urlencoded
X-Gitlab-Event-Streaming-Token: <DESTINATION_TOKEN>
```

### Example responses for SSH events

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
  "target_id": 29
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
  "target_id": 29
}
```

### Example responses for HTTP and HTTPS events

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
  "target_id": 29
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
  "target_id": 29
}
```

### Example responses for events from GitLab UI download button

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
  "target_id": 29
}
```
