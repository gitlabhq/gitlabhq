---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Set up and manage GitLab Duo with Amazon Q on a Self-Managed instance using AWS integration.
title: Set up GitLab Duo with Amazon Q
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo with Amazon Q
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Introduced as an [experiment](../../policy/development_stages_support.md#experiment) in GitLab 17.7 [with a flag](../../administration/feature_flags/_index.md) named `amazon_q_integration`. Disabled by default.
- Feature flag `amazon_q_integration` removed in GitLab 17.8.
- Generally available in GitLab 17.11.

{{< /history >}}

{{< alert type="note" >}}

GitLab Duo with Amazon Q cannot be combined with other GitLab Duo add-ons.

{{< /alert >}}

To get a subscription for GitLab Duo with Amazon Q, contact your Account Executive.

To request a trial, [fill out this form](https://about.gitlab.com/partners/technology-partners/aws/#form).

To set up GitLab Duo with Amazon Q on GitLab Self-Managed, complete the following steps.

## Set up GitLab Duo with Amazon Q

To set up GitLab Duo with Amazon Q, you must:

- [Complete the prerequisites](#prerequisites)
- [Create a profile in the Amazon Q Developer console](#create-a-profile-in-the-amazon-q-developer-console)
- [Create an identity provider](#create-an-iam-identity-provider)
- [Create an IAM role](#create-an-iam-role)
- [Edit the role](#edit-the-role)
- [Enter the ARN in GitLab and enable Amazon Q](#enter-the-arn-in-gitlab-and-enable-amazon-q)
- [Allow administrators to use customer managed keys](#allow-administrators-to-use-customer-managed-keys)

### Prerequisites

- You must have GitLab Self-Managed:
  - On GitLab 17.11 or later.
  - Amazon Q uses the GitLab instance's REST APIs to read and write data when performing requested actions and must be able to access your HTTPS URL ([the SSL certificate must not be self-signed](https://docs.gitlab.com/omnibus/settings/ssl/)).
  - The instance must allow inbound network access from Amazon Q services that originate from the following IP addresses, by using TCP/TLS on
    the port your instance is configured to use. This is [port 443 by default](../../administration/package_information/defaults.md#ports).
    - `34.228.181.128`
    - `44.219.176.187`
    - `54.226.244.221`
  - With an Ultimate subscription that is synchronized with GitLab, and
    the GitLab Duo with Amazon Q add-on.

### Create a profile in the Amazon Q Developer console

Create an Amazon Q Developer profile.

1. Open the [Amazon Q Developer console](https://us-east-1.console.aws.amazon.com/amazonq/developer/home#/gitlab).
1. Select **Amazon Q Developer in GitLab**.
1. Select **Get Started**.
1. For **Profile name**, enter a unique profile name for your region. For example, `QDevProfile-us-east-1`.
1. Optional. For **Profile description - optional**, enter a description.
1. Select **Create**.

### Create an IAM identity provider

Next, create an IAM identity provider.

First, you need the some values from GitLab:

Prerequisites:

- You must be an administrator.

1. Sign in to GitLab.
1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo with Amazon Q**.
1. Select **View configuration setup**.
1. Under step 1, copy the provider URL and audience. You will need them in the next step.

Now, create an AWS identity provider:

1. Sign in to the [AWS IAM console](https://console.aws.amazon.com/iam).
1. Select **Access Management** > **Identity providers**.
1. Select **Add provider**.
1. For **Provider type**, select **OpenID Connect**.
1. For **Provider URL**, enter the value from GitLab.
1. For **Audience**, enter the value from GitLab.
1. Select **Add provider**.

### Create an IAM role

Next, you must create an IAM role that trusts the IAM identity provider and can
access Amazon Q.

{{< alert type="note" >}}

After you set up the IAM role, you cannot change the AWS account that's associated with the role.

{{< /alert >}}

1. In the AWS IAM console, select **Access Management** > **Roles** > **Create role**.
1. Select **Web identity**.
1. For **Web identity**, select the provider URL you entered earlier.
1. For **Audience**, select the audience value you entered earlier.
1. Select **Next**.
1. On the **Add permissions** page:
   - To use a managed policy, for **Permissions policies**, search for and
     select `GitLabDuoWithAmazonQPermissionsPolicy`.
   - To create an inline policy, skip **Permissions policies** by selecting **Next**.
     You will create a policy later.
1. Select **Next**.
1. Name the role, for example `QDeveloperAccess`.
1. Ensure the trust policy is correct. It should look like this:

   ```json
   {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Principal": {
                "Federated": "arn:aws:iam::<AWS_Account_ID>:oidc-provider/auth.token.gitlab.com/cc/oidc/<Instance_ID>"
            },
            "Condition": {
                "StringEquals": {
                    "auth.token.gitlab.com/cc/oidc/<Instance_ID>:aud": "gitlab-cc-<Instance_ID>"
                },

            }
         }
      ]
   }
   ```

1. Select **Create role**.

### Create an inline policy (optional)

To create an inline policy, rather than using a managed policy:

1. Select **Permissions** > **Add permissions** > **Create inline policy**.
1. Select **JSON** and paste the following in the editor:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "GitLabDuoUsagePermissions",
         "Effect": "Allow",
         "Action": [
           "q:SendEvent",
           "q:CreateAuthGrant",
           "q:UpdateAuthGrant",
           "q:GenerateCodeRecommendations",
           "q:SendMessage",
           "q:ListPlugins",
           "q:VerifyOAuthAppConnection"
         ],
         "Resource": "*"
       },
       {
         "Sid": "GitLabDuoManagementPermissions",
         "Effect": "Allow",
         "Action": [
           "q:CreateOAuthAppConnection",
           "q:DeleteOAuthAppConnection"
         ],
         "Resource": "*"
       },
       {
         "Sid": "GitLabDuoPluginPermissions",
         "Effect": "Allow",
         "Action": [
           "q:CreatePlugin",
           "q:DeletePlugin",
           "q:GetPlugin"
         ],
         "Resource": "arn:aws:qdeveloper:*:*:plugin/GitLabDuoWithAmazonQ/*"
       }
     ]
   }
   ```

1. Select **Actions** > **Optimize for readability** to make AWS format and parse the JSON.
1. Select **Next**.
1. Name the policy `gitlab-duo-amazon-q-policy` and select **Create policy**.

### Edit the role

Now edit the role:

1. Find the role that you just created and select it.
1. Change the session time to 12 hours. The `AssumeRoleWithWebIdentity` will fail
   in the AI Gateway if the session is not set to 12 hours or more.

   1. In the **Roles search** field, enter the name of your IAM role and then choose the role name.
   1. In **Summary**, choose **Edit** to edit the session duration.
   1. Choose the **Maximum session duration** dropdown list, and then choose **12 hours**.
   1. Choose **Save changes**.

1. Copy the ARN listed on the page. It will look similar to this:

   ```plaintext
   arn:aws:iam::123456789:role/QDeveloperAccess
   ```

### Enter the ARN in GitLab and enable Amazon Q

Now, enter the ARN into GitLab and determine which groups and projects can access the feature.

Prerequisites:

- You must be a GitLab administrator.

To finish setting up GitLab Duo with Amazon Q:

1. Sign in to GitLab.
1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo with Amazon Q**.
1. Select **View configuration setup**.
1. Under **IAM role's ARN**, paste the ARN.
1. To determine which groups and projects can use GitLab Duo with Amazon Q, choose an option:
   - To turn it on for the instance, but let groups and projects turn it off, select **On by default**.
     - Optional. To configure Amazon Q to automatically review code in merge requests, select **Have Amazon Q review code in merge requests automatically**.
   - To turn it off for the instance, but let groups and projects turn it on, select **Off by default**.
   - To turn it off for the instance, and to prevent groups or projects from ever turning it on, select **Always off**.

1. Select **Save changes**.

When you save, an API should contact the AI Gateway to create an OAuth application on Amazon Q.

To confirm that it was successful:

- In the Amazon CloudWatch console log, check for a `204` status code. For more information, see
  [What is Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)?
- In GitLab, a notification that says `Amazon Q settings have been saved` is displayed.
- In GitLab, on the left sidebar, select **Applications**. The Amazon Q OAuth application is displayed.

## Allow administrators to use customer managed keys

If you are an administrator, you can use AWS Key Management Service (AWS KMS)
customer managed keys (CMKs) to encrypt customer data.

Update the role policy to grant permission to use CMKs when you create your key policy on a configured role in the KMS console.

The `kms:ViaService` condition key limits the use of a KMS key to requests from specified AWS services.
Additionally, it's used to deny permission to use a KMS key when the request comes from particular services.
With the condition key, you can limit who can use CMK for encrypting or decrypting content.

```json
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Sid": "Sid0",
         "Effect": "Allow",
         "Principal": {
            "AWS": "arn:aws:iam::<awsAccountId>:role/<rolename>"
         },
         "Action": [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:GenerateDataKey",
            "kms:GenerateDataKeyWithoutPlaintext",
            "kms:ReEncryptFrom",
            "kms:ReEncryptTo"
         ],
         "Resource": "*",
         "Condition": {
            "StringEquals": {
                "kms:ViaService": [
                    "q.<region>.amazonaws.com"
                ]
            }
        }
      }
   ]
}
```

For more information, see
[`kms:ViaService` in the AWS KMS Developer Guide](https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-via-service).

## Configure GitLab to use AWS hosted AI gateway

You can configure GitLab to use the hosted AI gateway on AWS.

1. Start a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session). For example, for installations that use the Linux package, run:

   ```shell
   sudo gitlab-rails console
   ```

1.To view the currently assigned service URL, run:

   ```ruby
   Ai::Setting.instance.ai_gateway_url
   ```

1. To update the service URL, run:

   ```ruby
   Ai::Setting.instance.update!(ai_gateway_url: "https://cloud.gitlab.com/aws/ai")
   ```

## Turn off GitLab Duo with Amazon Q

You can turn off GitLab Duo with Amazon Q for the instance, group, or project.

### Turn off for the instance

Prerequisites:

- You must be an administrator.

To turn off GitLab Duo with Amazon Q for the instance:

1. Sign in to GitLab.
1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo with Amazon Q**.
1. Select **View configuration setup**.
1. Select **Always off**.
1. Select **Save changes**.

### Turn off for a group

Prerequisites:

- You must have the Owner role for a group.

To turn off GitLab Duo with Amazon Q for a group:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand **Amazon Q**.
1. Choose an option:
   - To turn it off for the group, but let other groups or projects turn it on, select **Off by default**.
   - To turn if off for the group, and to prevent other groups or projects from turning it on, select **Always off**.
1. Select **Save changes**.

### Turn off for a project

Prerequisites:

- You must have the Owner role for a project.

To turn off GitLab Duo with Amazon Q for a project:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Expand **Visibility, project features, permissions**.
1. Under **Amazon Q**, turn the toggle off.
1. Select **Save changes**.

## Troubleshooting

If you experience issues connecting GitLab to Amazon Q,
ensure your GitLab installation meets [all the prerequisites](#prerequisites).

You might also encounter the following issue.

### GitLab instance UUID mismatch

You might encounter a `GitLab instance UUID mismatch` error when disconnecting Amazon Q. This issue typically occurs when:

- The GitLab instance has been restored from a backup.
- The GitLab instance has been migrated to new infrastructure.
- The GitLab instance UUID has changed for any other reason.

To confirm that a mismatched UUID is the root cause, proceed with the following validation steps.

#### Validate

1. Sign in to the EC2 instance where GitLab is hosted.
1. Access the Rails console.
1. Get the current UUID: `Gitlab::CurrentSettings.current_application_settings.uuid`
1. Get the JWT token:

   ```ruby
   token = CloudConnector::Tokens.get(unit_primitive: :agent_quick_actions, resource: :instance)
   JWT.decode(token, false, nil)
   ```

The issue is apparent when a mismatch in the UUID exists between the `sub` field in step 3 and the `gitlab_instance_uuid` from step 4.

To resolve this issue, complete the following steps.

1. Remove all active licenses.
1. Delete all subscription add-on purchases:

   Open the Rails console and execute:

   ```ruby
   GitlabSubscriptions::AddOnPurchase.all.destroy_all
   ```

1. Execute instance UUID reset.
   In the Rails console, execute:

   ```ruby
   ApplicationSetting.update!(uuid: SecureRandom.uuid)
   ```

1. Apply the active license.
1. Wait a minute or so and synchronize the license. This action forces the cloud connector token to regenerate. (Without this step, a header mismatch occurs.)
1. Update the IdP and IAM role with the new UUID.
1. Choose a next step:
   - Continue using the existing setup by updating the existing IdP and IAM role with the new UUID and continue using GitLab Duo with Amazon Q.
   - Off-board:
     1. Off-board from GitLab Duo with Amazon Q.
     1. Set up a new connection if desired.

When you are done, the UUID mismatch issue should be resolved and GitLab Duo with Amazon Q should function properly with the new configuration.
