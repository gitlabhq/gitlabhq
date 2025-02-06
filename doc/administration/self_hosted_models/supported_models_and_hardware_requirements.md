---
stage: AI-Powered
group: Custom Models
description: Supported Models and Hardware Requirements.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Supported GitLab Duo Self-Hosted models and hardware requirements
---

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab Self-Managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.
> - Feature flag `ai_custom_model` removed in GitLab 17.8

The following table shows the supported models along with their specific features and hardware requirements to help you select the model that best fits your infrastructure needs for optimal performance.

## Supported LLMs

Install one of the following GitLab-supported large language models (LLMs):

<!-- vale gitlab_base.Spelling = NO -->

| Model family | Model | Supported platforms | Status | Code completion | Code generation | GitLab Duo Chat |
|--------------|-------|---------------------|--------|-----------------|-----------------|-----------------|
|Mistral Codestral   | [Codestral 22B v0.1](https://huggingface.co/mistralai/Codestral-22B-v0.1) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | Generally available | 🟢 Green | 🟢 Green | N/A |
| Mistral | [Mistral 7B-it v0.3](https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.3) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | Generally available | 🟢 Green | 🟢 Green | 🔴 Red |
| Mistral | [Mixtral 8x7B-it v0.1](https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) <br> [AWS Bedrock](https://aws.amazon.com/bedrock/mistral/) | Generally available | 🟢 Green | 🟢 Green | 🟡 Amber |
| Mistral | [Mixtral 8x22B-it v0.1](https://huggingface.co/mistralai/Mixtral-8x22B-Instruct-v0.1) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | Generally available | 🟢 Green | 🟢 Green | 🟢 Green |
| Claude 3 | [Claude 3.5 Sonnet](https://www.anthropic.com/news/claude-3-5-sonnet) | [AWS Bedrock](https://aws.amazon.com/bedrock/claude/) | Generally available | 🟢 Green | 🟢 Green | 🟢 Green |
| GPT | [GPT-4 Turbo](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | Generally available | 🟢 Green | 🟢 Green | 🟡 Amber |
| GPT | [GPT-4o](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | Generally available | 🟢 Green | 🟢 Green | 🟢 Green |
| GPT | [GPT-4o-mini](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | Generally available | 🟢 Green | 🟢 Green | 🟡 Amber |

Legend:

- 🟢 Green - Fully compatible. The model can likely handle the feature without any loss of quality.
- 🟡 Amber - Largely compatible. The model supports the feature, but there might be compromises or limitations.
- 🔴 Red - Not compatible. The model is unsuitable for the feature, likely resulting in significant quality loss or performance issues.

The following models are configurable for the functionalities marked below, but are currently in experimental or beta status, under evaluation, and are excluded from the "Customer Integrated Models" definition in the [AI Functionality Terms](https://handbook.gitlab.com/handbook/legal/ai-functionality-terms/):

| Model family   | Model | Supported platforms | Status | Code completion | Code generation | GitLab Duo Chat |
|--------------- |-------|---------------------|--------|-----------------|-----------------|-----------------|
| CodeGemma      | [CodeGemma 2b](https://huggingface.co/google/codegemma-2b) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | Beta | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| CodeGemma      | [CodeGemma 7b-it](https://huggingface.co/google/codegemma-7b-it) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | Beta | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No |
| CodeGemma      | [CodeGemma 7b-code](https://huggingface.co/google/codegemma-7b) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | Beta | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| Code Llama     | [Code-Llama 13b](https://huggingface.co/meta-llama/CodeLlama-13b-Instruct-hf) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | Beta | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No |
| DeepSeek Coder | [DeepSeek Coder 33b Instruct](https://huggingface.co/deepseek-ai/deepseek-coder-33b-instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | Beta | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| DeepSeek Coder | [DeepSeek Coder 33b Base](https://huggingface.co/deepseek-ai/deepseek-coder-33b-base) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | Beta | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| Mistral        | [Mistral 7B-it v0.2](https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.2) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) <br> [AWS Bedrock](https://aws.amazon.com/bedrock/mistral/) | Beta | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |

<!-- vale gitlab_base.Spelling = YES -->

## Hardware requirements

The following hardware specifications are the minimum requirements for running GitLab Duo Self-Hosted on-premise. Requirements vary significantly based on the model size and intended usage:

### Base system requirements

- **CPU**:
  - Minimum: 8 cores (16 threads)
  - Recommended: 16+ cores for production environments
- **RAM**:
  - Minimum: 32 GB
  - Recommended: 64 GB for most models
- **Storage**:
  - SSD with sufficient space for model weights and data.

### GPU requirements by model size

| Model size                                 | Minimum GPU configuration | Minimum VRAM required |
|--------------------------------------------|---------------------------|-----------------------|
| 7B models<br>(for example, Mistral 7B)     | 1x NVIDIA A100 (40GB)     | 35 GB                 |
| 22B models<br>(for example, Codestral 22B) | 2x NVIDIA A100 (80GB)     | 110 GB                |
| Mixtral 8x7B                               | 2x NVIDIA A100 (80GB)     | 220 GB                |
| Mixtral 8x22B                              | 8x NVIDIA A100 (80GB)     | 526 GB                |

Use [Hugging Face's memory utility](https://huggingface.co/spaces/hf-accelerate/model-memory-usage) to verify memory requirements.

### Response time by model size and GPU

#### Small machine

With a `a2-highgpu-2g` (2x Nvidia A100 40 GB - 150 GB vRAM) or equivalent:

| Model name               | Number of requests | Average time per request (sec) | Average tokens in response | Average tokens per second per request | Total time for requests | Total TPS |
|--------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-------------------------|-----------|
| Mistral-7B-Instruct-v0.3 | 1                  | 7.09                         | 717.0                      | 101.19                                | 7.09                    | 101.17    |
| Mistral-7B-Instruct-v0.3 | 10                 | 8.41                         | 764.2                      | 90.35                                 | 13.70                   | 557.80    |
| Mistral-7B-Instruct-v0.3 | 100                | 13.97                        | 693.23                     | 49.17                                 | 20.81                   | 3331.59   |

#### Medium machine

With a `a2-ultragpu-4g` (4x Nvidia A100 40 GB - 340 GB vRAM) machine on GCP or equivalent:

| Model name                 | Number of requests | Average time per request (sec) | Average tokens in response | Average tokens per second per request | Total time for requests | Total TPS |
|----------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-------------------------|-----------|
| Mistral-7B-Instruct-v0.3   | 1                  | 3.80                         | 499.0                      | 131.25                                | 3.80                    | 131.23    |
| Mistral-7B-Instruct-v0.3   | 10                 | 6.00                         | 740.6                      | 122.85                                | 8.19                    | 904.22    |
| Mistral-7B-Instruct-v0.3   | 100                | 11.71                        | 695.71                     | 59.06                                 | 15.54                   | 4477.34   |
| Mixtral-8x7B-Instruct-v0.1 | 1                  | 6.50                         | 400.0                      | 61.55                                 | 6.50                    | 61.53     |
| Mixtral-8x7B-Instruct-v0.1 | 10                 | 16.58                        | 768.9                      | 40.33                                 | 32.56                   | 236.13    |
| Mixtral-8x7B-Instruct-v0.1 | 100                | 25.90                        | 767.38                     | 26.87                                 | 55.57                   | 1380.68   |

#### Large machine

With a `a2-ultragpu-8g` (8 x NVIDIA A100 80 GB - 1360 GB vRAM) machine on GCP or equivalent:

| Model name                  | Number of requests | Average time per request (sec) | Average tokens in response | Average tokens per second per request | Total time for requests (sec) | Total TPS |
|-----------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-----------------------------|-----------|
| Mistral-7B-Instruct-v0.3    | 1                  | 3.23                         | 479.0                      | 148.41                                | 3.22                        | 148.36    |
| Mistral-7B-Instruct-v0.3    | 10                 | 4.95                         | 678.3                      | 135.98                                | 6.85                        | 989.11    |
| Mistral-7B-Instruct-v0.3    | 100                | 10.14                        | 713.27                     | 69.63                                 | 13.96                       | 5108.75   |
| Mixtral-8x7B-Instruct-v0.1  | 1                  | 6.08                         | 709.0                      | 116.69                                | 6.07                        | 116.64    |
| Mixtral-8x7B-Instruct-v0.1  | 10                 | 9.95                         | 645.0                      | 63.68                                 | 13.40                       | 481.06    |
| Mixtral-8x7B-Instruct-v0.1  | 100                | 13.83                        | 585.01                     | 41.80                                 | 20.38                       | 2869.12   |
| Mixtral-8x22B-Instruct-v0.1 | 1                  | 14.39                        | 828.0                      | 57.56                                 | 14.38                       | 57.55     |
| Mixtral-8x22B-Instruct-v0.1 | 10                 | 20.57                        | 629.7                      | 30.24                                 | 28.02                       | 224.71    |
| Mixtral-8x22B-Instruct-v0.1 | 100                | 27.58                        | 592.49                     | 21.34                                 | 36.80                       | 1609.85   |

### AI Gateway Hardware Requirements

For recommendations on AI gateway hardware, see the [AI gateway scaling recommendations](../../install/install_ai_gateway.md#scaling-recommendations).
