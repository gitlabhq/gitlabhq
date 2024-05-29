---
stage: AI-Powered
group: Custom Models
description: Configure your GitLab instance with Switchboard.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure your GitLab Duo features

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

To configure your GitLab instance to access the available large language models (LLMs) in your infrastructure:

1. Configure the self-hosted model.
1. Configure the AI-powered features to use specific self-hosted models.

## Configure the self-hosted model

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **AI-Powered Features**.
   - If the **AI-Powered Features** menu item is not available, synchronize your subscription after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select synchronize subscription (**{retry}**).
1. Select **Models**.
1. Set your model details by selecting **New Self-Hosted Model**. Complete the fields:
   - **Name the deployment (must be unique):** Enter the model name, for example, Mistral.
   - **Choose the model from the Model dropdown list:** Only GitLab-approved models are listed here.
   - **Endpoint:** The self-hosted model endpoint, for example, the server hosting the model.
   - **API token (if needed):** Optional. Complete if you need an API key to access the model.
   - Select **Create Self-Hosted Model** to save the model details.

## Configure the features to use specific models

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **AI-Powered Features**.
   - If the **AI-Powered Features** menu item is not available, synchronize your subscription after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select synchronize subscription (**{retry}**).
1. Select **Features**.
1. Set your feature model by selecting **Edit** for the feature you want to set. For example, **Code Generation**.
1. Select the Model Provider for the feature:
   - Select **Self-Hosted Model** in the list.
   - Choose the self-hosted model you would like to use, for example, Mistral.
   - Select **Save Changes** to set the feature to use this specific model.
