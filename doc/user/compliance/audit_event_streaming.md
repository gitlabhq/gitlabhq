---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Learn how to configure and manage audit event streaming in GitLab to export audit logs to external destinations for compliance monitoring.
title: Audit event streaming for top-level groups
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

With audit event streaming for top-level groups, group owners can:

- Set a streaming destination for a top-level group to receive all audit events about the group, subgroups, and projects
  as structured JSON.
- Manage their audit logs in third-party systems. Any service that can receive structured JSON data can be used as the
  streaming destination.

Each streaming destination:

- Can have up to 20 custom HTTP headers included with each streamed event.
- For GitLab.com, must allow traffic from the [GitLab.com IP address range](../gitlab_com/_index.md#ip-range).

GitLab can stream a single event more than once to the same destination. Use the `id` key in the payload to deduplicate
incoming data.

Audit events are sent using the POST request method protocol supported by HTTP.

> [!warning]
> Streaming destinations receive all audit event data, which could include sensitive information. Make sure you trust
> the streaming destination.

## Batched event delivery

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249354) in GitLab 19.3 [with a feature flag](../../administration/feature_flags/_index.md) named `audit_event_streaming_via_nats`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

By default, GitLab sends each audit event to a streaming destination in its own request.
When the `audit_event_streaming_via_nats` feature flag is enabled for a top-level group,
GitLab sends the audit events of the group in batches instead.
A batch can contain events of different types, and can contain a single event.
The batch format applies to every delivery to the destinations of the group.

If a destination is briefly unavailable, GitLab retries the whole batch,
which can duplicate every event in it.
Deduplicate events by `id`, as described earlier on this page.

The batch format depends on the destination type.

### Batched HTTP requests

The request body is a JSON array.
Each element is an audit event that follows the [audit event schema](audit_event_schema.md),
including an `event_type` field that identifies the type of that event.
For an example, see [Batched HTTP request body](audit_event_schema.md#batched-http-request-body).

Batched requests differ from single-event requests in these ways:

- The request body is an array of events instead of a single event object.
- The `X-Gitlab-Audit-Event-Type` header is not sent. Use the `event_type` field of each event instead.

The `X-Gitlab-Event-Streaming-Token` header and custom HTTP headers are unchanged.
Batched requests use the `content-type` header of the destination.
To receive `application/json`, see [Override default content type header](#override-default-content-type-header).

### Batched AWS S3 objects

Each object contains a JSON array of events instead of a single event.
Object keys have the format `YYYY/MM/DD/<timestamp>_<id>.json`, where:

- `<timestamp>` is the time the object was written, in milliseconds since the Unix epoch.
- `<id>` is the `id` of the first event in the batch.

Without batched delivery, each event is written to its own object,
with a key in the format `<entity_type>/YYYY/MM/<event_type>_<id>_<timestamp>.json`.
Batched keys do not include the entity type or event type, because a batch can contain events of different types.

### Batched Google Cloud Logging entries

GitLab writes a batch as multiple log entries in a single request.
Each log entry contains one event, in the same format as without batched delivery.

## HTTP destinations

Prerequisites:

- For better security, you should use an SSL certificate on the destination URL.

Manage HTTP streaming destinations for top-level groups.

### Add a new HTTP destination

Add a new HTTP streaming destination to a top-level group.

Prerequisites:

- Owner role for a top-level group.

To add streaming destinations to a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select **Add streaming destination** and select **HTTP endpoint** to show the section for adding destinations.
1. In the **Name** and **Destination URL** fields, add a destination name and URL.
1. Optional. Locate the **Custom HTTP headers** table.
1. To make the header active, select the **Active** checkbox. The header will be sent with the audit event.
1. Select **Add header** to create a new name and value pair. Enter as many name and value pairs as required. You can add up to
   20 headers per streaming destination.
1. After all headers have been filled out, select **Add** to add the new streaming destination.

### Update an HTTP destination

Prerequisites:

- Owner role for a group.

To update a streaming destination's name:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. In the **Name** fields, add a destination name to update.
1. Select **Save** to update the streaming destination.

To update a streaming destination's custom HTTP headers:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Custom HTTP headers** table.
1. Locate the header that you wish to update.
1. To make the header active, select the **Active** checkbox. The header will be sent with the audit event.
1. Select **Add header** to create a new name and value pair. Enter as many name and value pairs as required. You can add up to
   20 headers per streaming destination.
1. Select **Save** to update the streaming destination.

### Verify event authenticity

Each streaming destination has a unique verification token (`verificationToken`) that can be used to verify the authenticity of the event. This
token is either specified by the Owner or generated automatically when the event destination is created and cannot be changed.

The `verificationToken` parameter can only be set by using the [GraphQL API](../../api/graphql/audit_event_streaming_groups.md#add-a-new-streaming-destination).

Each streamed event contains the verification token in the `X-Gitlab-Event-Streaming-Token` HTTP header that can be verified against
the destination's value when listing streaming destinations.

Prerequisites:

- Owner role for a group.

To list streaming destinations and see the verification tokens:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Verification token** input.

### Update event filters

When this feature is enabled for a group, you can permit users to filter streamed audit events per destination.
If the feature is enabled with no filters, the destination receives all audit events.

A streaming destination that has an event type filter set has a **filtered** ({{< icon name="filter" >}}) label.

To update a streaming destination's event filters:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Filter by audit event type** dropdown list.
1. Select the dropdown list and select or clear the required event types.
1. Select **Save** to update the event filters.

### Update namespace filters

When this feature is enabled for a group, you can permit users to filter streamed audit events per destination.
If the feature is enabled with no filters, the destination receives all audit events.

A streaming destination that has a namespace filter set has a **filtered** ({{< icon name="filter" >}}) label.

To update a streaming destination's namespace filters:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Filter by groups or projects** dropdown list.
1. Select the dropdown list and select or clear the required namespaces.
1. Select **Save** to update the namespace filter.

### Override default content type header

By default, streaming destinations use a `content-type` header of `application/x-www-form-urlencoded`. However, you
might want to set the `content-type` header to something else. For example, `application/json`.

To override the `content-type` header default value for a top-level group streaming destination, use either:

- The [GitLab UI](#update-an-http-destination).
- The [GraphQL API](../../api/graphql/audit_event_streaming_groups.md#update-streaming-destinations).

## Google Cloud Logging destinations

Manage Google Cloud Logging destinations for top-level groups.

### Prerequisites

Before setting up Google Cloud Logging streaming audit events, you must:

1. Enable [Cloud Logging API](https://console.cloud.google.com/marketplace/product/google/logging.googleapis.com) on your Google Cloud project.
1. Create a service account for Google Cloud with the appropriate credentials and permissions. This account is used to configure audit log streaming authentication.
   For more information, see [Creating and managing service accounts in the Google Cloud documentation](https://cloud.google.com/iam/docs/service-accounts-create#creating).
1. Enable the **Logs Writer** role for the service account to enable logging on Google Cloud. For more information, see [Access control with IAM](https://cloud.google.com/logging/docs/access-control#logging.logWriter).
1. Create a JSON key for the service account. For more information, see [Creating a service account key](https://cloud.google.com/iam/docs/keys-create-delete#creating).

### Add a new Google Cloud Logging destination

Prerequisites:

- Owner role for a top-level group.

To add Google Cloud Logging streaming destinations to a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select **Add streaming destination** and select **Google Cloud Logging** to show the section for adding destinations.
1. Enter a random string to use as a name for the new destination.
1. Enter the Google project ID, Google client email, and Google private key from previously-created Google Cloud service account key to add to the new destination.
1. Enter a random string to use as a log ID for the new destination. You can use this later to filter log results in Google Cloud.
1. Select **Add** to add the new streaming destination.

### Update a Google Cloud Logging destination

Prerequisites:

- Owner role for a top-level group.

To update Google Cloud Logging streaming destinations to a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the Google Cloud Logging stream to expand.
1. Enter a random string to use as a name for the destination.
1. Enter the Google project ID and Google client email from previously-created Google Cloud service account key to update the destination.
1. Enter a random string to update the log ID for the destination. You can use this later to filter log results in Google Cloud.
1. Select **Add a new private key** and enter a Google private key to update the private key.
1. Select **Save** to update the streaming destination.

## AWS S3 destinations

Manage AWS S3 destinations for top-level groups.

### Prerequisites

Before setting up AWS S3 streaming audit events, you must:

1. Create an access key for AWS with the appropriate credentials and permissions. This account is used to configure audit log streaming authentication.
   For more information, see [Managing access keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html?icmpid=docs_iam_console#Using_CreateAccessKey).
1. Create an AWS S3 bucket. This bucket is used to store audit log streaming data. For more information, see [Creating a bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)

### Add a new AWS S3 destination

Prerequisites:

- Owner role for a top-level group.

To add AWS S3 streaming destinations to a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select **Add streaming destination** and select **AWS S3** to show the section for adding destinations.
1. Enter a random string to use as a name for the new destination.
1. Enter the **Access Key ID**, **Secret Access Key**, **Bucket Name**, and **AWS Region** from previously-created AWS
   access key and bucket to add to the new destination.
1. Select **Add** to add the new streaming destination.

### Update an AWS S3 destination

Prerequisites:

- Owner role for a top-level group.

To update an AWS S3 streaming destination to a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the AWS S3 stream to expand.
1. Enter a random string to use as a name for the destination.
1. To update the destination, enter the **Access Key ID**, **Secret Access Key**, **Bucket Name**, and **AWS Region**
   from previously-created AWS access key and bucket.
1. To update the Secret Access Key, select **Add a new Secret Access Key** and enter an AWS Secret Access Key.
1. Select **Save**.

## List streaming destinations

Prerequisites:

- Owner role for a top-level group.

To list streaming destinations for a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.

## Activate or deactivate streaming destinations

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/537096) in GitLab 18.2.

{{< /history >}}

You can temporarily deactivate audit event streaming to a destination without deleting the destination configuration. When a streaming destination is deactivated:

- Audit events stop streaming to that destination immediately.
- The destination configuration is preserved.
- You can reactivate the destination at any time.
- Other active destinations continue to receive events.

### Deactivate a streaming destination

Prerequisites:

- Owner role for a top-level group.

To deactivate a streaming destination:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Clear the **Active** checkbox.
1. Select **Save**.

The destination stops receiving audit events.

### Activate a streaming destination

To reactivate a previously deactivated streaming destination:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Select the **Active** checkbox.
1. Select **Save**.

The destination resumes receiving audit events immediately.

## Delete streaming destinations

Delete streaming destinations for a top-level group. When the last destination is successfully deleted, streaming is
disabled for the top-level group.

Prerequisites:

- Owner role for a top-level group.

To delete streaming destinations to a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Select **Delete destination**.
1. To confirm, select **Delete destination**.

### Delete only custom HTTP headers

Prerequisites:

- Owner role for a top-level group.

To delete only the custom HTTP headers for a streaming destination:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Custom HTTP headers** table.
1. Locate the header that you wish to remove.
1. To the right of the header, select **Delete** ({{< icon name="remove" >}}).
1. Select **Save**.

## Related topics

- [Audit event streaming for instances](../../administration/compliance/audit_event_streaming.md)
