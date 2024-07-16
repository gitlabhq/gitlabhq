---
stage: AI-Powered
group: Custom Models
description: Configure your GitLab instance with Switchboard.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure GitLab to access self-hosted models

DETAILS:
**Tier:** For a limited time, Premium and Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** Self-managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

WARNING:
This feature is considered [experimental](../../policy/experiment-beta-support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
The development, release, and timing of any products, features, or functionality may be subject to change or delay and remain at the
sole discretion of GitLab Inc.

To configure your GitLab instance to access the available self-hosted large language
models (LLMs) in your infrastructure:

1. Configure the self-hosted model.
1. Configure the GitLab Duo AI-powered features to use your self-hosted models.

## Configure the self-hosted model

Prerequisites:

- You must be an administrator.

To configure a self-hosted model:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **AI-powered features**.
   - If the **AI-powered features** menu item is not available, synchronize your
     subscription after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
        synchronize subscription (**{retry}**).
1. Select **Models**.
1. Set your model details by selecting **New self-hosted model**.
1. Complete the fields:
   - Enter the model name, for example, Mistral.
   - From the **Model** dropdown list, select the model. Only GitLab-approved models are listed here.
   - For **Endpoint**, select the self-hosted model endpoint, for example, the server hosting the model.
   - Optional. For **API token**, add an API key if you need one to access the model.

1. Select **Create model**.

## Configure the features to your models

Prerequisites:

- You must be an administrator.

To configure the AI-powered features to use your model:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **AI-powered features**.
   - If the **AI-powered features** menu item is not available, synchronize your
     subscription after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
        synchronize subscription (**{retry}**).
1. Select **Features**.
1. For the feature you want to set, select **Edit**.
   For example, **Code Generation**.
1. Select the model provider for the feature:
   - From the list, select **Self-Hosted Model**.
   - Choose the self-hosted model you would like to use, for example, Mistral.

1. Select **Save Changes**.
