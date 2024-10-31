---
stage: AI-Powered
group: Custom Models
description: Configure your GitLab instance to use self-hosted models.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure GitLab to access self-hosted models

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.

To configure your GitLab instance to access the available self-hosted models in your infrastructure:

1. Use a [locally hosted or GitLab.com AI Gateway](index.md#choose-a-configuration-type).
1. Configure your GitLab instance.
1. Configure the self-hosted model.
1. Configure the GitLab Duo features to use your self-hosted model.

## Configure your GitLab instance

Prerequisites:

- [Upgrade to the latest version of GitLab](../../update/index.md).

To configure your GitLab instance to access the AI Gateway:

1. Where your GitLab instance is installed, update the `/etc/gitlab/gitlab.rb` file:

   ```shell
   sudo vim /etc/gitlab/gitlab.rb
   ```

1. Add and save the following environment variables:

   ```ruby
   gitlab_rails['env'] = {
   'GITLAB_LICENSE_MODE' => 'production',
   'CUSTOMER_PORTAL_URL' => 'https://customers.gitlab.com',
   'AI_GATEWAY_URL' => '<path_to_your_ai_gateway>:<port>'
   }
   ```

1. Run reconfigure:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configure the self-hosted model

Prerequisites:

- You must be an administrator.

To configure a self-hosted model:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **AI-powered features**.
   - If the **AI-powered features** menu item is not available, synchronize your
     subscription after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
        synchronize subscription (**{retry}**).
1. Select **Models**.
1. Select **New self-hosted model**.
1. Complete the fields:
   - Enter the model name, for example, `Mistral`.
   - From the **Model family** dropdown list, select the model. Only GitLab-approved models
     are in this list.
   - For **Endpoint**, select the self-hosted model endpoint. For example, the
     server hosting the model.
   - Optional. For **API token**, add an API key if you need one to access the model.
   - Optional. For **Model identifier**, enter the cloud provider where the model is hosted, and the name the cloud provider uses for that model (for example: `anthropic/claude-3-5-sonnet-20240620`).
1. Select **Create model**.

## Configure GitLab Duo features to use self-hosted models

Prerequisites:

- You must be an administrator.

### View configured features

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **AI-powered features**.
   - If the **AI-powered features** menu item is not available, synchronize your
     subscription after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
        synchronize subscription (**{retry}**).
1. Select **Features**.

### Configure the feature to use a self-hosted model

Configure the GitLab Duo feature to send queries to the configured self-hosted model:

1. In **Features**, for the feature you want to set, select **Edit**.
   For example, **Code Generation**.
1. Select the model provider for the feature:
   - From the list, select **Self-Hosted Model**.
   - Choose the self-hosted model you want to use, for example, `Mistral`.
1. Select **Save Changes**.

### Configure the features to use GitLab AI vendor models

You can choose a GitLab AI vendor to be the GitLab Duo feature's model provider. The
feature then uses the GitLab-hosted model through the GitLab Cloud Connector:

1. In **Features**, for the feature you want to set, select **Edit**.
1. In the list of model providers for the feature, select **AI Vendor**.
1. Select **Save Changes**.
