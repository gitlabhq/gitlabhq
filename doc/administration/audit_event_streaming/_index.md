---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Audit event streaming for instances
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/398107) in GitLab 16.1 [with a flag](../feature_flags.md) named `ff_external_audit_events`. Disabled by default.
> - [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) enabled by default in GitLab 16.2.
> - Instance streaming destinations [made generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) in GitLab 16.4. [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708) removed.
> - Custom HTTP headers UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/361630) in GitLab 15.2 [with a flag](../feature_flags.md) named `custom_headers_streaming_audit_events_ui`. Disabled by default.
> - Custom HTTP headers UI [made generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/365259) in GitLab 15.3. [Feature flag `custom_headers_streaming_audit_events_ui`](https://gitlab.com/gitlab-org/gitlab/-/issues/365259) removed.
> - [Improved user experience](https://gitlab.com/gitlab-org/gitlab/-/issues/367963) in GitLab 15.3.
> - HTTP destination **Name** field [added](https://gitlab.com/gitlab-org/gitlab/-/issues/411357) in GitLab 16.3.
> - Functionality for the **Active** checkbox [added](https://gitlab.com/gitlab-org/gitlab/-/issues/415268) in GitLab 16.5.

Audit event streaming for instances, administrators can:

- Set a streaming destination for an entire instance to receive all audit events about that instance as structured JSON.
- Manage their audit logs in third-party systems. Any service that can receive structured JSON data can be used as the
  streaming destination.

Each streaming destination can have up to 20 custom HTTP headers included with each streamed event.

GitLab can stream a single event more than once to the same destination. Use the `id` key in the payload to deduplicate
incoming data.

Audit events are sent using the POST request method protocol supported by HTTP.

WARNING:
Streaming destinations receive **all** audit event data, which could include sensitive information. Make sure you trust
the streaming destination.

Manage streaming destinations for an entire instance.

## HTTP destinations

Prerequisites:

- For better security, you should use an SSL certificate on the destination URL.

Manage HTTP streaming destinations for an entire instance.

### Add a new HTTP destination

Add a new HTTP streaming destination to an instance.

Prerequisites:

- Administrator access on the instance.

To add a streaming destination for an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select **Add streaming destination** and select **HTTP endpoint** to show the section for adding destinations.
1. In the **Name** and **Destination URL** fields, add a destination name and URL.
1. Optional. To add custom HTTP headers, select **Add header** to create a new name and value pair, and input their values. Repeat this step for as many name and value pairs are required. You can add up to 20 headers per streaming destination.
1. To make the header active, select the **Active** checkbox. The header will be sent with the audit event.
1. Select **Add header** to create a new name and value pair. Repeat this step for as many name and value pairs are required. You can add up to
   20 headers per streaming destination.
1. After all headers have been filled out, select **Add** to add the new streaming destination.

### List HTTP destinations

Prerequisites:

- Administrator access on the instance.

To list the streaming destinations for an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand it and see all the custom HTTP headers.

### Update an HTTP destination

Prerequisites:

- Administrator access on the instance.

To update a instance streaming destination's name:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. In the **Name** fields, add a destination name to update.
1. Select **Save** to update the streaming destination.

To update a instance streaming destination's custom HTTP headers:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Custom HTTP headers** table.
1. Locate the header that you wish to update.
1. To make the header active, select the **Active** checkbox. The header will be sent with the audit event.
1. Select **Add header** to create a new name and value pair. Enter as many name and value pairs as required. You can add up to
   20 headers per streaming destination.
1. Select **Save** to update the streaming destination.

### Delete an HTTP destination

Delete streaming destinations for an entire instance. When the last destination is successfully deleted, streaming is
disabled for the instance.

Prerequisites:

- Administrator access on the instance.

To delete the streaming destinations for an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Select **Delete destination**.
1. Confirm by selecting **Delete destination** in the dialog.

To delete only the custom HTTP headers for a streaming destination:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. To the right of the item, select **Edit** (**{pencil}**).
1. Locate the **Custom HTTP headers** table.
1. Locate the header that you wish to remove.
1. To the right of the header, select **Delete** (**{remove}**).
1. Select **Save** to update the streaming destination.

### Verify event authenticity

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/398107) in GitLab 16.1 [with a flag](../feature_flags.md) named `ff_external_audit_events`. Disabled by default.
> - [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) enabled by default in GitLab 16.2.
> - Instance streaming destinations [made generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) in GitLab 16.4. [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708) removed.

Each streaming destination has a unique verification token (`verificationToken`) that can be used to verify the authenticity of the event. This
token is either specified by the Owner or generated automatically when the event destination is created and cannot be changed.

Each streamed event contains the verification token in the `X-Gitlab-Event-Streaming-Token` HTTP header that can be verified against
the destination's value when listing streaming destinations.

Prerequisites:

- Administrator access on the instance.

To list streaming destinations for an instance and see the verification tokens:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. View the verification token on the right side of each item.

### Update event filters

> - Event type filtering in the UI with a defined list of audit event types [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/415013) in GitLab 16.3.

When this feature is enabled, you can permit users to filter streamed audit events per destination.
If the feature is enabled with no filters, the destination receives all audit events.

A streaming destination that has an event type filter set has a **filtered** (**{filter}**) label.

To update a streaming destination's event filters:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Filter by audit event type** dropdown list.
1. Select the dropdown list and select or clear the required event types.
1. Select **Save** to update the event filters.

### Override default content type header

By default, streaming destinations use a `content-type` header of `application/x-www-form-urlencoded`. However, you
might want to set the `content-type` header to something else. For example ,`application/json`.

To override the `content-type` header default value for an instance streaming destination, use either:

- The [GitLab UI](#update-an-http-destination).
- The [GraphQL API](../../api/graphql/audit_event_streaming_instances.md#update-streaming-destinations).

## Google Cloud Logging destinations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131851) in GitLab 16.5.

Manage Google Cloud Logging destinations for an entire instance.

### Prerequisites

Before setting up Google Cloud Logging streaming audit events, you must:

1. Enable [Cloud Logging API](https://console.cloud.google.com/marketplace/product/google/logging.googleapis.com) on your Google Cloud project.
1. Create a service account for Google Cloud with the appropriate credentials and permissions. This account is used to configure audit log streaming authentication.
   For more information, see [Creating and managing service accounts in the Google Cloud documentation](https://cloud.google.com/iam/docs/service-accounts-create#creating).
1. Enable the **Logs Writer** role for the service account to enable logging on Google Cloud. For more information, see [Access control with IAM](https://cloud.google.com/logging/docs/access-control#logging.logWriter).
1. Create a JSON key for the service account. For more information, see [Creating a service account key](https://cloud.google.com/iam/docs/keys-create-delete#creating).

### Add a new Google Cloud Logging destination

Prerequisites:

- Administrator access on the instance.

To add Google Cloud Logging streaming destinations to an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select **Add streaming destination** and select **Google Cloud Logging** to show the section for adding destinations.
1. Enter a random string to use as a name for the new destination.
1. Enter the Google project ID, Google client email, and Google private key from previously-created Google Cloud service account key to add to the new destination.
1. Enter a random string to use as a log ID for the new destination. You can use this later to filter log results in Google Cloud.
1. Select **Add** to add the new streaming destination.

### List Google Cloud Logging destinations

Prerequisites:

- Administrator access on the instance.

To list Google Cloud Logging streaming destinations for an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the Google Cloud Logging stream to expand and see all the fields.

### Update a Google Cloud Logging destination

Prerequisites:

- Administrator access on the instance.

To update Google Cloud Logging streaming destinations to an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the Google Cloud Logging stream to expand.
1. Enter a random string to use as a name for the destination.
1. Enter the Google project ID and Google client email from previously-created Google Cloud service account key to update the destination.
1. Enter a random string to update the log ID for the destination. You can use this later to filter log results in Google Cloud.
1. Select **Add a new private key** and enter a Google private key to update the private key.
1. Select **Save** to update the streaming destination.

### Delete a Google Cloud Logging streaming destination

Prerequisites:

- Administrator access on the instance.

To delete Google Cloud Logging streaming destinations to an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the Google Cloud Logging stream to expand.
1. Select **Delete destination**.
1. Confirm by selecting **Delete destination** in the dialog.

## AWS S3 destinations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138245) in GitLab 16.7 [with a flag](../feature_flags.md) named `allow_streaming_instance_audit_events_to_amazon_s3`. Disabled by default.
> - [Feature flag `allow_streaming_instance_audit_events_to_amazon_s3`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137391) removed in GitLab 16.8.

Manage AWS S3 destinations for entire instance.

### Prerequisites

Before setting up AWS S3 streaming audit events, you must:

1. Create a access key for AWS with the appropriate credentials and permissions. This account is used to configure audit log streaming authentication.
   For more information, see [Managing access keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html?icmpid=docs_iam_console#Using_CreateAccessKey).
1. Create a AWS S3 bucket. This bucket is used to store audit log streaming data. For more information, see [Creating a bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)

### Add a new AWS S3 destination

Prerequisites:

- Administrator access on the instance.

To add AWS S3 streaming destinations to an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select **Add streaming destination** and select **AWS S3** to show the section for adding destinations.
1. Enter a random string to use as a name for the new destination.
1. Enter the Access Key ID, Secret Access Key, Bucket Name, and AWS Region from previously-created AWS access key and bucket to add to the new destination.
1. Select **Add** to add the new streaming destination.

### List AWS S3 destinations

Prerequisites:

- Administrator access on the instance.

To list AWS S3 streaming destinations for an instance.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the AWS S3 stream to expand and see all the fields.

### Update an AWS S3 destination

Prerequisites:

- Administrator access on the instance.

To update AWS S3 streaming destinations to an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the AWS S3 stream to expand.
1. Enter a random string to use as a name for the destination.
1. Enter the Access Key ID, Secret Access Key, Bucket Name, and AWS Region from previously-created AWS access key and bucket to update the destination.
1. Select **Add a new Secret Access Key** and enter a AWS Secret Access Key to update the Secret Access Key.
1. Select **Save** to update the streaming destination.

### Delete an AWS S3 streaming destination

Prerequisites:

- Administrator access on the instance.

To delete AWS S3 streaming destinations on an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the AWS S3 stream to expand.
1. Select **Delete destination**.
1. Confirm by selecting **Delete destination** in the dialog.

## Related topics

- [Audit event streaming for top-level groups](../../user/compliance/audit_event_streaming.md)
