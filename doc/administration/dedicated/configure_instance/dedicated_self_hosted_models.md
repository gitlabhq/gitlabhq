---
stage: GitLab Dedicated
group: AI Model Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Host your own AI models for GitLab Dedicated.
title: Configure self-hosted models for GitLab Dedicated
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Use the AI Gateway for GitLab Dedicated to connect your self-hosted models.
With the GitLab Duo Agent Platform, you can connect the AI Gateway to
Amazon Bedrock to maintain inference in your AWS region.
Alternatively, you can use your preferred provider.

## Hybrid AI Gateway and model configuration

The AI Gateway for GitLab Dedicated runs in the same AWS environment and region as
your GitLab Dedicated instance. GitLab hosts and configures the gateway for you.
You do not need to install an AI Gateway or enter a local AI Gateway URL in the
**Admin** area.

With the AI Gateway for GitLab Dedicated, your instance uses a
[hybrid AI Gateway and model configuration](../../gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration).
For each GitLab Duo feature, you can use either:

- Self-hosted model: The feature sends requests through the AI Gateway for
  GitLab Dedicated to the model endpoint that you configure.
- GitLab-managed model: The feature sends requests to the GitLab.com AI Gateway.
  The AI Gateway for GitLab Dedicated cannot route to GitLab-managed models.

The AI Gateway for GitLab Dedicated does not change the default behavior of your instance.
By default, all GitLab Duo features use GitLab-managed models through the GitLab.com AI Gateway.
Your instance sends requests through the AI Gateway for GitLab Dedicated only for the
features that you configure to use a self-hosted model.

## Add a self-hosted model

You can add a self-hosted model to use on your GitLab instance.

To add a self-hosted model:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Manage models**.
1. Select **Add self-hosted model**.
1. Complete the fields:
   - **Deployment name**: Enter a name to uniquely identify the model deployment
     (for example, `Mixtral-8x7B-it-v0.1 on GCP`).
   - **Model family**: Select the model family the deployment belongs to.
     You can select a supported or compatible model.
   - **Endpoint**: Enter the URL where the model is hosted.
   - **API key**: Optional. Add an API key to access the model.
   - **Model identifier**: Enter the model ID based on your deployment method.
     The model ID must match the following format:

     | Deployment method | Format | Example |
     |-------------------|--------|---------|
     | Amazon Bedrock (model ID) | `bedrock/<model ID>` | `bedrock/mistral.mixtral-8x7b-instruct-v0:1` |
     | Amazon Bedrock (application inference profile ARN) | `bedrock/converse/<application inference profile ARN>` | `bedrock/converse/arn:aws:bedrock:us-east-1:123456789012:application-inference-profile/abcd1234efgh` |
     | Gemini Enterprise Agent Platform | `vertex_ai/<model ID>` | `vertex_ai/claude-sonnet-4-6@default` |
     | Anthropic                                                            | `anthropic/<model ID>`                     | `anthropic/claude-opus-4-6` |
     | OpenAI                                                              | `openai/<model ID>`                        | `openai/gpt-5` |
     | Azure OpenAI                                                          | `azure/<model ID>`                         | `azure/gpt-35-turbo` |

1. Select **Add self-hosted model**.

Adding a self-hosted model makes it available to use, but does not assign it to any
GitLab Duo feature. To use it, you must
[select a self-hosted model for the feature](../../gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature). Features for which you do not select a self-hosted model continue to use
GitLab-managed models through the GitLab.com AI Gateway.
