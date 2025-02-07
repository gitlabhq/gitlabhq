---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Audit event streaming for top-level groups
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Subgroup events recording](https://gitlab.com/gitlab-org/gitlab/-/issues/366878) fixed in GitLab 15.2.
> - Custom HTTP headers UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/361630) in GitLab 15.2 [with a flag](../feature_flags.md) named `custom_headers_streaming_audit_events_ui`. Disabled by default.
> - Custom HTTP headers UI [made generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/365259) in GitLab 15.3. [Feature flag `custom_headers_streaming_audit_events_ui`](https://gitlab.com/gitlab-org/gitlab/-/issues/365259) removed.
> - [Improved user experience](https://gitlab.com/gitlab-org/gitlab/-/issues/367963) in GitLab 15.3.
> - HTTP destination **Name** field [added](https://gitlab.com/gitlab-org/gitlab/-/issues/411357) in GitLab 16.3.
> - Functionality for the **Active** checkbox [added](https://gitlab.com/gitlab-org/gitlab/-/issues/415268) in GitLab 16.5.

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

WARNING:
Streaming destinations receive **all** audit event data, which could include sensitive information. Make sure you trust
the streaming destination.

## HTTP destinations

Prerequisites:

- For better security, you should use an SSL certificate on the destination URL.

Manage HTTP streaming destinations for top-level groups.

### Add a new HTTP destination

Add a new HTTP streaming destination to a top-level group.

Prerequisites:

- Owner role for a top-level group.

To add streaming destinations to a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select **Add streaming destination** and select **HTTP endpoint** to show the section for adding destinations.
1. In the **Name** and **Destination URL** fields, add a destination name and URL.
1. Optional. Locate the **Custom HTTP headers** table.
1. To make the header active, select the **Active** checkbox. The header will be sent with the audit event.
1. Select **Add header** to create a new name and value pair. Enter as many name and value pairs as required. You can add up to
   20 headers per streaming destination.
1. After all headers have been filled out, select **Add** to add the new streaming destination.

### List HTTP destinations

Prerequisites:

- Owner role for a group.

To list the streaming destinations for a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand it and see all the custom HTTP headers.

### Update an HTTP destination

Prerequisites:

- Owner role for a group.

To update a streaming destination's name:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. In the **Name** fields, add a destination name to update.
1. Select **Save** to update the streaming destination.

To update a streaming destination's custom HTTP headers:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Custom HTTP headers** table.
1. Locate the header that you wish to update.
1. To make the header active, select the **Active** checkbox. The header will be sent with the audit event.
1. Select **Add header** to create a new name and value pair. Enter as many name and value pairs as required. You can add up to
   20 headers per streaming destination.
1. Select **Save** to update the streaming destination.

### Delete an HTTP destination

Delete streaming destinations for a top-level group. When the last destination is successfully deleted, streaming is
disabled for the top-level group.

Prerequisites:

- Owner role for a group.

To delete a streaming destination:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Select **Delete destination**.
1. Confirm by selecting **Delete destination** in the dialog.

To delete only the custom HTTP headers for a streaming destination:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Custom HTTP headers** table.
1. Locate the header that you wish to remove.
1. To the right of the header, select **Delete** (**{remove}**).
1. Select **Save** to update the streaming destination.

### Verify event authenticity

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360814) in GitLab 15.2.

Each streaming destination has a unique verification token (`verificationToken`) that can be used to verify the authenticity of the event. This
token is either specified by the Owner or generated automatically when the event destination is created and cannot be changed.

Each streamed event contains the verification token in the `X-Gitlab-Event-Streaming-Token` HTTP header that can be verified against
the destination's value when listing streaming destinations.

Prerequisites:

- Owner role for a group.

To list streaming destinations and see the verification tokens:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Verification token** input.

### Update event filters

> - Event type filtering in the UI with a defined list of audit event types [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/413581) in GitLab 16.1.

When this feature is enabled for a group, you can permit users to filter streamed audit events per destination.
If the feature is enabled with no filters, the destination receives all audit events.

A streaming destination that has an event type filter set has a **filtered** (**{filter}**) label.

To update a streaming destination's event filters:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Filter by audit event type** dropdown list.
1. Select the dropdown list and select or clear the required event types.
1. Select **Save** to update the event filters.

### Update namespace filters

> - Namespace filtering in the UI [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390133) in GitLab 16.7.

When this feature is enabled for a group, you can permit users to filter streamed audit events per destination.
If the feature is enabled with no filters, the destination receives all audit events.

A streaming destination that has a namespace filter set has a **filtered** (**{filter}**) label.

To update a streaming destination's namespace filters:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the stream to expand.
1. Locate the **Filter by groups or projects** dropdown list.
1. Select the dropdown list and select or clear the required namespaces.
1. Select **Save** to update the namespace filter.

### Override default content type header

By default, streaming destinations use a `content-type` header of `application/x-www-form-urlencoded`. However, you
might want to set the `content-type` header to something else. For example ,`application/json`.

To override the `content-type` header default value for a top-level group streaming destination, use either:

- The [GitLab UI](#update-an-http-destination).
- The [GraphQL API](../../api/graphql/audit_event_streaming_groups.md#update-streaming-destinations).

## Google Cloud Logging destinations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124384) in GitLab 16.2.

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

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select **Add streaming destination** and select **Google Cloud Logging** to show the section for adding destinations.
1. Enter a random string to use as a name for the new destination.
1. Enter the Google project ID, Google client email, and Google private key from previously-created Google Cloud service account key to add to the new destination.
1. Enter a random string to use as a log ID for the new destination. You can use this later to filter log results in Google Cloud.
1. Select **Add** to add the new streaming destination.

### List Google Cloud Logging destinations

Prerequisites:

- Owner role for a top-level group.

To list Google Cloud Logging streaming destinations for a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the Google Cloud Logging stream to expand and see all the fields.

### Update a Google Cloud Logging destination

> - Button to add private key [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419675) in GitLab 16.3.

Prerequisites:

- Owner role for a top-level group.

To update Google Cloud Logging streaming destinations to a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the Google Cloud Logging stream to expand.
1. Enter a random string to use as a name for the destination.
1. Enter the Google project ID and Google client email from previously-created Google Cloud service account key to update the destination.
1. Enter a random string to update the log ID for the destination. You can use this later to filter log results in Google Cloud.
1. Select **Add a new private key** and enter a Google private key to update the private key.
1. Select **Save** to update the streaming destination.

### Delete a Google Cloud Logging streaming destination

Prerequisites:

- Owner role for a top-level group.

To delete Google Cloud Logging streaming destinations to a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the Google Cloud Logging stream to expand.
1. Select **Delete destination**.
1. Confirm by selecting **Delete destination** in the dialog.

## AWS S3 destinations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132603) in GitLab 16.6 [with a flag](../feature_flags.md) named `allow_streaming_audit_events_to_amazon_s3`. Enabled by default.
> - [Feature flag `allow_streaming_audit_events_to_amazon_s3`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137391) removed in GitLab 16.7.

Manage AWS S3 destinations for top-level groups.

### Prerequisites

Before setting up AWS S3 streaming audit events, you must:

1. Create a access key for AWS with the appropriate credentials and permissions. This account is used to configure audit log streaming authentication.
   For more information, see [Managing access keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html?icmpid=docs_iam_console#Using_CreateAccessKey).
1. Create a AWS S3 bucket. This bucket is used to store audit log streaming data. For more information, see [Creating a bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)

### Add a new AWS S3 destination

Prerequisites:

- Owner role for a top-level group.

To add AWS S3 streaming destinations to a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select **Add streaming destination** and select **AWS S3** to show the section for adding destinations.
1. Enter a random string to use as a name for the new destination.
1. Enter the Access Key ID, Secret Access Key, Bucket Name, and AWS Region from previously-created AWS access key and bucket to add to the new destination.
1. Select **Add** to add the new streaming destination.

### List AWS S3 destinations

Prerequisites:

- Owner role for a top-level group.

To list AWS S3 streaming destinations for a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the AWS S3 stream to expand and see all the fields.

### Update a AWS S3 destination

Prerequisites:

- Owner role for a top-level group.

To update AWS S3 streaming destinations to a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the AWS S3 stream to expand.
1. Enter a random string to use as a name for the destination.
1. Enter the Access Key ID, Secret Access Key, Bucket Name, and AWS Region from previously-created AWS access key and bucket to update the destination.
1. Select **Add a new Secret Access Key** and enter a AWS Secret Access Key to update the Secret Access Key.
1. Select **Save** to update the streaming destination.

### Delete a AWS S3 streaming destination

Prerequisites:

- Owner role for a top-level group.

To delete AWS S3 streaming destinations to a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. On the main area, select the **Streams** tab.
1. Select the AWS S3 stream to expand.
1. Select **Delete destination**.
1. Confirm by selecting **Delete destination** in the dialog.

## Related topics

- [Audit event streaming for instances](../../administration/audit_event_streaming/_index.md)
