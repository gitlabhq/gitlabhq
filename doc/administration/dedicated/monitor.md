---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Access application logs and S3 bucket data to monitor your GitLab Dedicated instance.
title: Monitor your GitLab Dedicated instance
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab delivers [application logs](../logs/_index.md) to an Amazon S3 bucket in the GitLab
tenant account, which can be shared with you.
To access these logs, you must provide AWS Identity and Access Management (IAM) Amazon Resource
Names (ARNs) that uniquely identify your AWS users or roles.

Logs stored in the S3 bucket are retained indefinitely.

GitLab team members can view more information about the proposed retention policy in
this confidential issue: `https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/483`.

## Request access to application logs

To gain read-only access to the S3 bucket with your application logs:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)
   with the title `Customer Log Access`.
1. In the body of the ticket, include a list of IAM ARNs for the users or roles that require
   access to the logs. Specify the full ARN path without wildcards (`*`). For example:

   - User: `arn:aws:iam::123456789012:user/username`
   - Role: `arn:aws:iam::123456789012:role/rolename`

{{< alert type="note" >}}

Only IAM user and role ARNs are supported.
Security Token Service (STS) ARNs (`arn:aws:sts::...`) cannot be used.

{{< /alert >}}

GitLab provides the name of the S3 bucket. Your authorized users or roles can then access all objects in the bucket.
To verify access, you can use the [AWS CLI](https://aws.amazon.com/cli/).

GitLab team members can view more information about the proposed feature to add wildcard support in this
confidential issue: `https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/7010`.

## Find your S3 bucket name

To find your S3 bucket name:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. In the **Tenant details** section, locate the **AWS S3 bucket for tenant logs** field.

For information about how to access S3 buckets after you have the name, see the [AWS documentation about accessing S3 buckets](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-bucket-intro.html).

## S3 bucket contents and structure

The Amazon S3 bucket contains a combination of infrastructure logs and application logs from the GitLab [log system](../logs/_index.md).

The logs in the bucket are encrypted using an AWS KMS key managed by GitLab. If you choose to enable [BYOK](encryption.md#bring-your-own-key-byok), the application logs are not encrypted with the key you provide.

<!-- vale gitlab_base.Spelling = NO -->

The logs in the S3 bucket are organized by date in `YYYY/MM/DD/HH` format. For example, a directory named `2023/10/12/13` contains logs from October 12, 2023 at 13:00 UTC. The logs are streamed into the bucket with [Amazon Kinesis Data Firehose](https://aws.amazon.com/firehose/).

<!-- vale gitlab_base.Spelling = YES -->
