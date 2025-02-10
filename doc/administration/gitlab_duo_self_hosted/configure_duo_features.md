---
stage: AI-Powered
group: Custom Models
description: Configure your GitLab instance to use GitLab Duo Self-Hosted.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure GitLab to access GitLab Duo Self-Hosted
---

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab Self-Managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.
> - Feature flag `ai_custom_model` removed in GitLab 17.8
> - Ability to set AI gateway URL using UI [added](https://gitlab.com/gitlab-org/gitlab/-/issues/473143) in GitLab 17.9.

Prerequisites:

- [Upgrade GitLab to version 17.9 or later](../../update/_index.md).

To configure your GitLab instance to access the available self-hosted models in your infrastructure:

1. [Confirm that a fully self-hosted configuration is appropriate for your use case](_index.md#decide-on-your-configuration-type).
1. Configure your GitLab instance to access the AI gateway.
1. Configure the self-hosted model.
1. Configure the GitLab Duo features to use your self-hosted model.

## Configure your GitLab instance to access the AI gateway

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Duo**.
1. In the **GitLab Duo** section, select **Change configuration**.
1. Under **Local AI Gateway URL**, enter your AI Gateway URL.
1. Select **Save changes**.

## Configure the self-hosted model

Prerequisites:

- You must be an administrator.
- You must have an Ultimate license.
- You must have a Duo Enterprise license add-on.

To configure a self-hosted model:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Self-hosted models**.
   - If the **Self-hosted models** menu item is not available, synchronize your
     subscription after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
        synchronize subscription (**{retry}**).
1. Select **Add self-hosted model**.
1. Complete the fields:
   - **Deployment name**: Enter a name to uniquely identify the model deployment, for example, `Mixtral-8x7B-it-v0.1 on GCP`.
   - **Model family**: Select the model family the deployment belongs to. Only GitLab-approved models
     are in this list.
   - **Endpoint**: Enter the URL where the model is hosted.
     - For models hosted through vLLM, you must suffix the URL with `/v1`. The default port is `8000`, so the default endpoint URL is `https://<hostname>:8000/v1`.
   - **API key**: Optional. Add an API key if you need one to access the model.
   - **Model identifier**: This is a required field if your deployment method is vLLM, Bedrock or Azure. The value of this field is based on your deployment method, and should match the following structure:

     | Deployment method | Format | Example |
     |-------------|---------|---------|
     | vLLM | `custom_openai/<name of the model served through vLLM>` | `custom_openai/Mixtral-8x7B-Instruct-v0.1` |
     | Bedrock | `bedrock/<model ID of the model>` | `bedrock/mistral.mixtral-8x7b-instruct-v0:1` |
     | Azure OpenAI | `azure/<model ID of the model>` | `azure/gpt-35-turbo` |
     | Others | The field is optional |  |

1. Select **Create self-hosted model**.

## Configure self-hosted beta models

Prerequisites:

- You must be an administrator.
- You must have an Ultimate license.
- You must have a Duo Enterprise license add-on.

To enable self-hosted [beta](../../policy/development_stages_support.md#beta) models:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Duo**.
1. In the **GitLab Duo** section, select **Change configuration**.
1. Under **Self-hosted AI models**, select **Use beta self-hosted models features**.
1. Select **Save changes**.

NOTE:
Turning on beta self-hosted models features also accepts the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

For more information, see the [list of available beta models](supported_models_and_hardware_requirements.md) under evaluation.

## Configure GitLab Duo features to use self-hosted models

Prerequisites:

- You must be an administrator.
- You must have an Ultimate license.
- You must have a Duo Enterprise license add-on.

### View configured features

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Self-hosted models**.
   - If the **Self-hosted models** menu item is not available, synchronize your
     subscription after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
        synchronize subscription (**{retry}**).
1. Select the **AI-powered features** tab.

### Configure the feature to use a self-hosted model

Configure the GitLab Duo feature to send queries to the configured self-hosted model:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Self-hosted models**.
1. Select the **AI-powered features** tab.
1. For the feature you want to configure, from the dropdown list, choose the self-hosted model you want to use. For example, `Mistral`.
