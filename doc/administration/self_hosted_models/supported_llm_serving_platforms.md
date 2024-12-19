---
stage: AI-Powered
group: Custom Models
description: Supported LLM Serving Platforms.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Self-hosted models supported platforms

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.
> - Feature flag `ai_custom_model` removed in GitLab 17.8

There are multiple platforms available to host your self-hosted Large Language Models (LLMs). Each platform has unique features and benefits that can cater to different needs. The following documentation summarises the currently supported options:

## For self-hosted model deployments

1. [vLLM](https://docs.vllm.ai/en/latest/index.html).
   A high-performance inference server optimized for serving LLMs with memory efficiency. It supports model parallelism and integrates easily with existing workflows.
   - [vLLM Installation Guide](https://docs.vllm.ai/en/latest/getting_started/installation.html). We recommend installing version [v0.6.4.post1](https://github.com/vllm-project/vllm/releases/tag/v0.6.4.post1) or later.
   - [vLLM Supported Models](https://docs.vllm.ai/en/latest/models/supported_models.html)

   For information on available options when using vLLM to run a model, see the [vLLM documentation on engine arguments](https://docs.vllm.ai/en/stable/usage/engine_args.html).

   For example, to set up and run the Mistral model, run the following command:

   ```shell
   HF_TOKEN=HUGGING_FACE_TOKEN python -m vllm.entrypoints.openai.api_server \
      --model mistralai/Mistral-7B-Instruct-v0.3 \
      --served-model-name Mistral-7B-Instruct-v0.3 \
      --tensor-parallel-size 8 \
      --tokenizer_mode mistral \
      --load_format mistral \
      --config_format mistral \
      --tokenizer mistralai/Mistral-7B-Instruct-v0.3
   ```

## For cloud-hosted model deployments

1. [AWS Bedrock](https://aws.amazon.com/bedrock/).
   A fully managed service that allows developers to build and scale generative AI applications using pre-trained models from leading AI companies. It seamlessly integrates with other AWS services and offers a pay-as-you-go pricing model.
   - [AWS Bedrock Model Deployment Guide](https://docs.epam-rail.com/Deployment/Bedrock%20Model%20Deployment)
   - [Supported foundation models in Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)

1. [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/).
   Provides access to OpenAI's powerful models, enabling developers to integrate advanced AI capabilities into their applications with robust security and scalable infrastructure.
   - [Working with Azure OpenAI models](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/working-with-models?tabs=powershell)
   - [Azure OpenAI Service models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure%2Cglobal-standard%2Cstandard-chat-completions)
