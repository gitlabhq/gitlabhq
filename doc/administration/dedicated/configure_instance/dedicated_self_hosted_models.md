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
