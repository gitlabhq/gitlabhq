---
stage: AI-Powered
group: Custom Models
description: Supported LLM Serving Platforms.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Self-Hosted supported platforms
---

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab Self-Managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.
> - Feature flag `ai_custom_model` removed in GitLab 17.8

There are multiple platforms available to host your self-hosted Large Language Models (LLMs). Each platform has unique features and benefits that can cater to different needs. The following documentation summarises the currently supported options:

## For self-hosted model deployments

### vLLM

[vLLM](https://docs.vllm.ai/en/latest/index.html) is a high-performance inference server optimized for serving LLMs with memory efficiency. It supports model parallelism and integrates easily with existing workflows.

To install vLLM, see the [vLLM Installation Guide](https://docs.vllm.ai/en/latest/getting_started/installation.html). You should install [version v0.6.4.post1](https://github.com/vllm-project/vllm/releases/tag/v0.6.4.post1) or later.

For more information on:

- vLLM supported models, see the [vLLM Supported Models documentation](https://docs.vllm.ai/en/latest/models/supported_models.html).
- Available options when using vLLM to run a model, see the [vLLM documentation on engine arguments](https://docs.vllm.ai/en/stable/usage/engine_args.html).
- The hardware needed for the models, see the [Supported models and Hardware requirements documentation](../gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md).

Examples:

#### Mistral-7B-Instruct-v0.2

1. Download the model from HuggingFace:

   ```shell
   git clone https://<your-hugging-face-username>:<your-hugging-face-token>@huggingface.co/mistralai/Mistral-7B-Instruct-v0.3
   ```

1. Run the server:

   ```shell
   vllm serve <path-to-model>/Mistral-7B-Instruct-v0.3 \
      --served_model_name <choose-a-name-for-the-model>  \
      --tokenizer_mode mistral \
      --tensor_parallel_size <number-of-gpus> \
      --load_format mistral \
      --config_format mistral \
      --tokenizer <path-to-model>/Mistral-7B-Instruct-v0.3
   ```

#### Mixtral-8x7B-Instruct-v0.1

1. Download the model from HuggingFace:

   ```shell
   git clone https://<your-hugging-face-username>:<your-hugging-face-token>@huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1
   ```

1. Rename the token config:

   ```shell
   cd <path-to-model>/Mixtral-8x7B-Instruct-v0.1
   cp tokenizer.model tokenizer.model.v3
   ```

1. Run the model:

   ```shell
   vllm serve <path-to-model>/Mixtral-8x7B-Instruct-v0.1 \
     --tensor_parallel_size 4 \
     --served_model_name <choose-a-name-for-the-model> \
     --tokenizer_mode mistral \
     --load_format safetensors \
     --tokenizer <path-to-model>/Mixtral-8x7B-Instruct-v0.1/
   ```

## For cloud-hosted model deployments

1. [AWS Bedrock](https://aws.amazon.com/bedrock/).
   A fully managed service that allows developers to build and scale generative AI applications using pre-trained models from leading AI companies. It seamlessly integrates with other AWS services and offers a pay-as-you-go pricing model.

   You must configure the GitLab instance with your appropriate AWS IAM permissions before accessing Bedrock models. You cannot do this in the GitLab Duo Self-Hosted UI. For example, you can authenticate the AI Gateway instance by defining the [`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_REGION_NAME`](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) when starting the Docker image. For more information, see the [AWS Identity and Access Management (IAM) Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/security-iam.html).

   - [Supported foundation models in Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)

1. [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/).
   Provides access to OpenAI's powerful models, enabling developers to integrate advanced AI capabilities into their applications with robust security and scalable infrastructure.
   - [Working with Azure OpenAI models](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/working-with-models?tabs=powershell)
   - [Azure OpenAI Service models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure%2Cglobal-standard%2Cstandard-chat-completions)
