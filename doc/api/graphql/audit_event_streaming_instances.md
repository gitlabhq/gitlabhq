---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Audit event streaming GraphQL API for instances
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/335175) in GitLab 16.0 [with a flag](../feature_flags.md) named `ff_external_audit_events`. Disabled by default.
> - APIs for custom HTTP headers for instance level streaming destinations [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404560) in GitLab 16.1 [with a flag](../feature_flags.md) named `ff_external_audit_events`. Disabled by default.
> - [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) enabled by default in GitLab 16.2.
> - User-specified destination name API support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/413894) in GitLab 16.2.
> - Instance streaming destinations [made generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) in GitLab 16.4. [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708) removed.

Manage audit event streaming destinations for instances by using a GraphQL API.

## HTTP destinations

Manage HTTP streaming destinations for an entire instance.

### Add a new HTTP destination

Add a new HTTP streaming destination to an instance.

Prerequisites:

- Administrator access on the instance.

To enable streaming and add a destination, use the
`instanceExternalAuditEventDestinationCreate` mutation in the GraphQL API.

```graphql
mutation {
  instanceExternalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

Event streaming is enabled if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

You can optionally specify your own destination name (instead of the default GitLab-generated one) using the GraphQL
`instanceExternalAuditEventDestinationCreate`
mutation. Name length must not exceed 72 characters and trailing whitespace are not trimmed. This value should be unique. For example:

```graphql
mutation {
  instanceExternalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", name: "destination-name-here"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

Instance administrators can add an HTTP header using the GraphQL `auditEventsStreamingInstanceHeadersCreate` mutation. You can retrieve the destination ID
by [listing all the streaming destinations](#list-streaming-destinations) for the instance or from the mutation above.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersCreate(input:
    {
      destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/42",
      key: "foo",
      value: "bar",
      active: true
    }) {
    errors
    header {
      id
      key
      value
      active
    }
  }
}
```

The header is created if the returned `errors` object is empty.

### List streaming destinations

List all HTTP streaming destinations for an instance.

Prerequisites:

- Administrator access on the instance.

To view a list of streaming destinations for an instance, use the
`instanceExternalAuditEventDestinations` query type.

```graphql
query {
  instanceExternalAuditEventDestinations {
    nodes {
      id
      name
      destinationUrl
      verificationToken
      headers {
        nodes {
          id
          key
          value
          active
        }
      }
      eventTypeFilters
    }
  }
}
```

If the resulting list is empty, then audit streaming is not enabled for the instance.

You need the ID values returned by this query for the update and delete mutations.

### Update streaming destinations

Update a HTTP streaming destination for an instance.

Prerequisites:

- Administrator access on the instance.

To update streaming destinations for an instance, use the
`instanceExternalAuditEventDestinationUpdate` mutation type. You can retrieve the destination ID
by [listing all the external destinations](#list-streaming-destinations) for the instance.

```graphql
mutation {
  instanceExternalAuditEventDestinationUpdate(input: {
    id: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1",
    destinationUrl: "https://www.new-domain.com/webhook",
    name: "destination-name"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

Streaming destination is updated if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

Instance administrators can update streaming destinations custom HTTP headers using the
`auditEventsStreamingInstanceHeadersUpdate` mutation type. You can retrieve the custom HTTP headers ID
by [listing all the custom HTTP headers](#list-streaming-destinations) for the instance.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersUpdate(input: { headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/2", key: "new-key", value: "new-value", active: false }) {
    errors
    header {
      id
      key
      value
      active
    }
  }
}
```

The header is updated if the returned `errors` object is empty.

### Delete streaming destinations

Delete streaming destinations for an entire instance.

When the last destination is successfully deleted, streaming is disabled for the instance.

Prerequisites:

- Administrator access on the instance.

To delete streaming destinations, use the
`instanceExternalAuditEventDestinationDestroy` mutation type. You can retrieve the destinations ID
by [listing all the streaming destinations](#list-streaming-destinations) for the instance.

```graphql
mutation {
  instanceExternalAuditEventDestinationDestroy(input: { id: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1" }) {
    errors
  }
}
```

Streaming destination is deleted if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

To remove an HTTP header, use the GraphQL `auditEventsStreamingInstanceHeadersDestroy` mutation.
To retrieve the header ID,
[list all the custom HTTP headers](#list-streaming-destinations) for the instance.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/<id>" }) {
    errors
  }
}
```

The header is deleted if the returned `errors` object is empty.

### Event type filters

> - Event type filters API [introduced](https://gitlab.com/groups/gitlab-org/-/epics/10868) in GitLab 16.2.

When this feature is enabled for an instance, you can use an API to permit users to filter streamed audit events per destination.
If the feature is enabled with no filters, the destination receives all audit events.

A streaming destination that has an event type filter set has a **filtered** (**{filter}**) label.

#### Use the API to add an event type filter

Prerequisites:

- You must have the Administrator access for the instance.

You can add a list of event type filters using the `auditEventsStreamingDestinationInstanceEventsAdd` mutation:

```graphql
mutation {
    auditEventsStreamingDestinationInstanceEventsAdd(input: {
        destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1",
        eventTypeFilters: ["list of event type filters"]}){
        errors
        eventTypeFilters
    }
}
```

Event type filters are added if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

#### Use the API to remove an event type filter

Prerequisites:

- You must have the Administrator access for the instance.

You can remove a list of event type filters using the `auditEventsStreamingDestinationInstanceEventsRemove` mutation:

```graphql
mutation {
    auditEventsStreamingDestinationInstanceEventsRemove(input: {
    destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1",
    eventTypeFilters: ["list of event type filters"]
  }){
    errors
  }
}
```

Event type filters are removed if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

## Google Cloud Logging destinations

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11303) in GitLab 16.5.

Manage Google Cloud Logging destinations for an entire instance.

Before setting up Google Cloud Logging streaming audit events, you must satisfy [the prerequisites](../../administration/audit_event_streaming/_index.md#prerequisites).

### Add a new Google Cloud Logging destination

Add a new Google Cloud Logging configuration destination to an instance.

Prerequisites:

- You have administrator access to the instance.
- You have a Google Cloud project with the necessary permissions to create service accounts and enable Google Cloud Logging.

To enable streaming and add a configuration, use the
`instanceGoogleCloudLoggingConfigurationCreate` mutation in the GraphQL API.

```graphql
mutation {
  instanceGoogleCloudLoggingConfigurationCreate(input: { googleProjectIdName: "my-google-project", clientEmail: "my-email@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events", name: "destination-name" } ) {
    errors
    googleCloudLoggingConfiguration {
      id
      googleProjectIdName
      logIdName
      clientEmail
      name
    }
    errors
  }
}
```

Event streaming is enabled if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

### List Google Cloud Logging configurations

List all Google Cloud Logging configuration destinations for an instance.

Prerequisites:

- You have administrator access to the instance.

You can view a list of streaming configurations for an instance using the `instanceGoogleCloudLoggingConfigurations` query
type.

```graphql
query {
  instanceGoogleCloudLoggingConfigurations {
    nodes {
      id
      logIdName
      googleProjectIdName
      clientEmail
      name
    }
  }
}
```

If the resulting list is empty, audit streaming is not enabled for the instance.

You need the ID values returned by this query for the update and delete mutations.

### Update Google Cloud Logging configurations

Update the Google Cloud Logging configuration destinations for an instance.

Prerequisites:

- You have administrator access to the instance.

To update streaming configuration for an instance, use the
`instanceGoogleCloudLoggingConfigurationUpdate` mutation type. You can retrieve the configuration ID
by [listing all the external destinations](#list-google-cloud-logging-configurations).

```graphql
mutation {
  instanceGoogleCloudLoggingConfigurationUpdate(
    input: {id: "gid://gitlab/AuditEvents::Instance::GoogleCloudLoggingConfiguration/1", googleProjectIdName: "updated-google-id", clientEmail: "updated@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events", name: "updated name"}
  ) {
    errors
    instanceGoogleCloudLoggingConfiguration {
      id
      logIdName
      googleProjectIdName
      clientEmail
      name
    }
  }
}
```

Streaming configuration is updated if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

### Delete Google Cloud Logging configurations

Delete streaming destinations for an instance.

When the last destination is successfully deleted, streaming is disabled for the instance.

Prerequisites:

- You have administrator access to the instance.

To delete streaming configurations, use the
`instanceGoogleCloudLoggingConfigurationDestroy` mutation type. You can retrieve the configurations ID
by [listing all the streaming destinations](#list-google-cloud-logging-configurations) for the instance.

```graphql
mutation {
  instanceGoogleCloudLoggingConfigurationDestroy(input: { id: "gid://gitlab/AuditEvents::Instance::GoogleCloudLoggingConfiguration/1" }) {
    errors
  }
}
```

Streaming configuration is deleted if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.
