---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Audit event streaming **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.5 [with a flag](../administration/feature_flags.md) named `ff_external_audit_events_namespace`. Disabled by default.
> - [Enabled on GitLab.com and by default on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/338939) in GitLab 14.7.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature per group, ask an administrator to [disable the feature flag](../administration/feature_flags.md) named `ff_external_audit_events_namespace`. On GitLab.com, this feature is available.

Event streaming allows owners of top-level groups to set an HTTP endpoint to receive **all** audit events about the group, and its
subgroups and projects.

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
        id
      }
    }
  }
}
```

If the resulting list is empty, then audit event streaming is not enabled for that group.
