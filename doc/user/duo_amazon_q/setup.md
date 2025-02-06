---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Set up GitLab Duo with Amazon Q
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed
**Status:** Preview/Beta

> - Introduced as an [experiment](../../policy/development_stages_support.md#experiment) in GitLab 17.7 [with a flag](../../administration/feature_flags.md) named `amazon_q_integration`. Disabled by default.
> - Feature flag `amazon_q_integration` removed in GitLab 17.8.

NOTE:
If you have a Duo Pro or Duo Enterprise add-on, this feature is not available.

To use GitLab Duo with Amazon Q, you can [request access to a lab environment](https://about.gitlab.com/partners/technology-partners/aws/#interest).

If you'd prefer to set up GitLab Duo with Amazon Q on GitLab Self-Managed,
complete the following steps.

## Set up GitLab Duo with Amazon Q

To set up GitLab Duo with Amazon Q, you must:

- [Complete the prerequisites](#prerequisites)
- [Create an identity provider](#create-an-iam-identity-provider)
- [Create an IAM role](#create-an-iam-role)
- [Enter the ARN in GitLab and enable Amazon Q](#enter-the-arn-in-gitlab-and-enable-amazon-q)
- [Add the Amazon Q user to your project](#add-the-amazon-q-user-to-your-project)

### Prerequisites

- You must have GitLab Self-Managed:
  - On GitLab 17.8 or later.
  - On an instance in AWS.
  - With an HTTPS URL that can be accessed by Amazon Q (the SSL certificate must not be self-signed).
    For more details about SSL, see [Configure SSL for a Linux package installation](https://docs.gitlab.com/omnibus/settings/ssl/).
  - With an Ultimate subscription that is synchronized with GitLab. (No trial access.)
- GitLab Duo features [must be turned on](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
  (Experimental and beta features are off by default.)

### Create an IAM identity provider

Start by creating an IAM identity provider.

First, you need the some values from GitLab:

1. Sign in to GitLab.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Configure GitLab Duo with Amazon Q**.
1. Under step 1, copy the provider URL and audience. You will need them in the next step.

Now, create an AWS identity provider:

1. Sign in to the [AWS IAM console](https://console.aws.amazon.com/iam).
1. Select **Access Management > Identity providers**.
1. Select **Add provider**.
1. For **Provider type**, select **OpenID Connect**.
1. For **Provider URL**, enter the value from GitLab.
1. For **Audience**, enter the value from GitLab.
1. Select **Add provider**.

### Create an IAM role

Next, you must create an IAM role that trusts the IAM identity provider and can
access Amazon Q.

NOTE:
After you set up the IAM role, you cannot change the AWS account that's associated with the role.

1. In the AWS IAM console, select **Access Management > Roles > Create role**.
1. Select **Web identity**.
1. For **Web identity**, select the provider URL you entered earlier.
1. For **Audience**, select the audience value you entered earlier.
1. Skip **Permissions policies** by selecting **Next**. You will create an inline policy later.
1. Ensure the trust policy is correct. It should look like this:

   ```plaintext
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
                    "auth.token.gitlab.com/cc/oidc/<Instance_ID>": "gitlab-cc-<Instance_ID>"
                },

            }
         }
      ]
   }
   ```

1. Name the role, for example `QDeveloperAccess`, and select **Create role**.

Now edit the role and add the policy:

1. Find the role that you just created and select it.
1. Change the session time to 12 hours. The `AssumeRoleWithWebIdentity` will fail
   in the AI Gateway if the session is not set to 12 hours or more.

   1. In the **Roles search** field, enter the name of your IAM role and then choose the role name.
   1. In **Summary**, choose **Edit** to edit the session duration.
   1. Choose the **Maximum session duration** dropdown menu, and then choose **12 hours**.
   1. Choose **Save changes**.

1. Select **Permissions > Add permissions > Create inline policy**.
1. Select **JSON** and paste the following in the editor:

   ```json
   {
      "Version": "2012-10-17",
      "Statement": [
         {
            "Sid": "GitLabDuoPermissions",
            "Effect": "Allow",
            "Action": [
               "q:SendEvent",
               "q:CreateOAuthAppConnection",
               "q:CreateAuthGrant",
               "q:UpdateAuthGrant",
               "q:UpdateOAuthAppConnection"
            ],
            "Resource": "*"
         }
      ]
   }
   ```

1. Select **Actions > Optimize for readability** to make AWS format and parse the JSON.
1. Select **Next**.
1. Name the policy `gitlab-duo-amazon-q-policy` and select **Create policy**.
1. Copy the ARN listed on the page. It will look similar to this:

   ```plaintext
   arn:aws:iam::123456789:role/QDeveloperAccess
   ```

### Enter the ARN in GitLab and enable Amazon Q

Now, enter the ARN into GitLab and determine which groups and projects can access the feature.

Prerequisites:

- You must be a GitLab administrator.

1. Sign in to GitLab.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Configure GitLab Duo with Amazon Q**.
1. Select **View configuration setup**.
1. Under **IAM role's ARN**, paste the ARN.
1. To determine which groups and projects can use GitLab Duo with Amazon Q, choose an option:
   - To turn it on for the instance, but let groups and projects turn it off, select **On by default**.
   - To turn it off for the instance, but let groups and projects turn it on, select **Off by default**.
   - To turn it off for the instance, and to prevent groups or projects from ever turning it on, select **Always off**.

1. Select **Save changes**.

When you save, an API should contact the AI Gateway to create an OAuth application on Amazon Q.

To confirm that it was successful:

- In the Amazon CloudWatch console log, check for a `204` status code. For more information, see
  [What is Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)?
- In GitLab, a notification that says `Amazon Q settings have been saved` is displayed.
- In GitLab, on the left sidebar, select **Applications**. The Amazon Q OAuth application is displayed.

## Add the Amazon Q user to your project

Now add the Amazon Q service account user as a member of your project.

1. In GitLab, on the left sidebar, select **Search or go to** and find your project.
1. Select **Manage > Members**.
1. In the upper-right corner, select **Invite members**.
1. For **Username, name, or email address**, select **Amazon Q Service**.
1. For **Select a role**, select **Developer**.
1. Select **Invite**.

### Configure the AI gateway

Now configure your AI gateway.

1. On your GitLab instance, in `/etc/gitlab/gitlab.rb`, in production mode, your `gitlab_rails['env']` configuration should look like:

   ```ruby
   gitlab_rails['env'] = {
     "AI_GATEWAY_URL" => "https://ai-gateway-panda.runway.gitlab.net"
   }
   ```

   Be sure that `GITLAB_LICENSE_MODE`, `CUSTOMER_PORTAL_URL`, and `CLOUD_CONNECTOR_SELF_SIGN_TOKENS` are NOT set.

   For staging, your `/etc/gitlab/gitlab.rb` should have:

   ```ruby
   gitlab_rails['env'] = {
     "GITLAB_LICENSE_MODE" => "test",
     "CUSTOMER_PORTAL_URL" => "https://customers.staging.gitlab.com",
     "AI_GATEWAY_URL" => "https://ai-gateway-panda.staging.runway.gitlab.net"
   }
   ```

1. Run `gitlab-ctl reconfigure` for these changes to take effect.

## Turn off GitLab Duo with Amazon Q

You can turn off GitLab Duo with Amazon Q for the instance, group, or project.

### Turn off for the instance

Prerequisites:

- You must be an administrator.

To turn off GitLab Duo with Amazon Q for the instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Amazon Q**.
1. Select **View configuration setup**.
1. Select **Always off**.
1. Select **Save changes**.

### Turn off for a group

Prerequisites:

- You must have the Owner role for a group.

To turn off GitLab Duo with Amazon Q for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Amazon Q**.
1. Choose an option:
   - To turn it off for the group, but let other groups or projects turn it on, select **Off by default**.
   - To turn if off for the group, and to prevent other groups or projects from turning it on, select **Always off**.
1. Select **Save changes**.

### Turn off for a project

Prerequisites:

- You must have the Owner role for a project.

To turn off GitLab Duo with Amazon Q for a project:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Under **Amazon Q**, turn the toggle off.
1. Select **Save changes**.
