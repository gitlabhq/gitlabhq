---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Manage access to application logs for your GitLab Dedicated instance.
title: Access application logs for GitLab Dedicated
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated automatically delivers your instance's application logs to a private Amazon S3 bucket.
These logs contain both infrastructure and application data for monitoring, troubleshooting, and compliance purposes.

The S3 bucket contains logs that are:

- Stored indefinitely and encrypted using AWS KMS keys managed by GitLab.
- Organized by date in `YYYY/MM/DD/HH` format.
- Streamed in real-time using [Amazon Kinesis Data Firehose](https://aws.amazon.com/firehose/).

If you use [BYOK](encryption.md#bring-your-own-key-byok), application logs use GitLab-managed keys, not your provided key.

## Manage access to application logs

You can add, edit, or remove AWS IAM users and roles that have read-only access to your application logs.

Prerequisites:

- You must have the full ARN path for each AWS user or role that needs access.

> [!note]
> You can only use IAM user and role ARNs. Security Token Service (STS) ARNs and wildcards are not supported.

To manage log access:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Resource access**.
1. Under **Application logs**, in the **Log access ARNs** section:

   - To add access: Select **Add ARN**, enter the full ARN path, then select **Save**. For example:
     - User: `arn:aws:iam::123456789012:user/username`
     - Role: `arn:aws:iam::123456789012:role/rolename`
   - To edit access: Next to an ARN, select the pencil icon ({{< icon name="pencil" >}}),
     update the ARN, then select **Save**.
   - To remove access: Next to an ARN, select the trash icon ({{< icon name="remove" >}}),
     then select **Delete**.

1. Copy the **Logs S3 bucket name**. Your authorized users or roles use this bucket name to access the logs.

After you configure ARN permissions and provide the bucket name to your users,
they can access all objects in the S3 bucket.
To verify access, use the [AWS CLI](https://aws.amazon.com/cli/).

For information about how to access S3 buckets in AWS,
see [Accessing an Amazon S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-bucket-intro.html).
