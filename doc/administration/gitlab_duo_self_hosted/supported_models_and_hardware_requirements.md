---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Supported models and hardware requirements.
title: Models and hardware requirements
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../feature_flags/_index.md) named `ai_custom_model`. Disabled by default.
- [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.
- Feature flag `ai_custom_model` removed in GitLab 17.8.
- Generally available in GitLab 17.9.
- Changed to include Premium in GitLab 18.0.

{{< /history >}}

GitLab Duo Self-Hosted supports integration with industry-leading models from Mistral, Meta, Anthropic, and OpenAI through your preferred serving platform.

You can use:

- Supported models to match your specific performance needs and use cases.
- In GitLab 18.3 and later, your own compatible model to experiment with models beyond the officially supported options.
- GitLab AI vendor models to connect to AI models without the need to host your own infrastructure. These models are managed entirely by GitLab.

## Supported models

GitLab-supported models offer different levels of functionality for GitLab Duo features,
depending on the specific model and feature combination.

- Full functionality: The model can likely handle the feature without any loss of quality.
- Partial functionality: The model supports the feature, but there might be compromises or limitations.
- Limited functionality: The model is unsuitable for the feature, likely resulting in significant quality loss or performance issues.
Models that have limited functionality for a feature will not receive GitLab support for that specific feature.

<!-- vale gitlab_base.Spelling = NO -->

| Model family | Model | Supported platforms | Code completion | Code generation | GitLab Duo Chat | GitLab Duo Agent Platform |
|-------------|-------|---------------------|-----------------|-----------------|-----------------|-----------------|
| Mistral Codestral | [Codestral 22B v0.1](https://huggingface.co/mistralai/Codestral-22B-v0.1) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-dashed" >}} Partial functionality |  Limited functionality |
| Mistral | [Mistral Small 24B Instruct 2506](https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | Limited functionality |
| Claude 3 |  [Claude 3.5 Sonnet](https://www.anthropic.com/news/claude-3-5-sonnet) | [AWS Bedrock](https://aws.amazon.com/bedrock/claude/) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-dashed" >}} Partial functionality |
| Claude 3 |  [Claude 3.7 Sonnet](https://www.anthropic.com/news/claude-3-7-sonnet) | [AWS Bedrock](https://aws.amazon.com/bedrock/claude/) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality |  {{< icon name="check-circle-dashed" >}} Partial functionality |
| Claude 4 | [Claude 4 Sonnet](https://www.anthropic.com/news/claude-4)                                                                          | [AWS Bedrock](https://aws.amazon.com/bedrock/claude/) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality |
| GPT | [GPT-4 Turbo](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-dashed" >}} Partial functionality | Limited functionality |
| GPT | [GPT-4o](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | Limited functionality |
| GPT | [GPT-4o-mini](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-dashed" >}} Partial functionality | Limited functionality |
| GPT | [GPT-5](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?pivots=azure-openai&tabs=global-standard%2Cstandard-chat-completions#gpt-5)) | [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | Limited functionality |
| GPT | [GPT-oss-120B](https://huggingface.co/openai/gpt-oss-120b) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | Limited functionality |
| GPT | [GPT-oss-20B](https://huggingface.co/openai/gpt-oss-20b) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-dashed" >}} Partial functionality | {{< icon name="check-circle-dashed" >}} Partial functionality | {{< icon name="check-circle-dashed" >}} Partial functionality | Limited functionality |
| Llama | [Llama 3 8B](https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-dashed" >}} Partial functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="dash-circle" >}} Limited functionality | Limited functionality |
| Llama | [Llama 3.1 8B](https://huggingface.co/meta-llama/Llama-3.1-8B-Instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-dashed" >}} Partial functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-dashed" >}} Partial functionality | Limited functionality |
| Llama | [Llama 3 70B](https://huggingface.co/meta-llama/Meta-Llama-3-70B-Instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-dashed" >}} Partial functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="dash-circle" >}} Limited functionality | Limited functionality |
| Llama | [Llama 3.1 70B](https://huggingface.co/meta-llama/Llama-3.1-70B-Instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | Limited functionality |
| Llama | [Llama 3.3 70B](https://huggingface.co/meta-llama/Llama-3.3-70B-Instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | {{< icon name="check-circle-filled" >}} Full functionality | Limited functionality |

### Compatible models

{{< details >}}

- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/18556) in GitLab 18.3 as a [beta](../../policy/development_stages_support.md#beta).

{{< /history >}}

You can use your own compatible models and platform with GitLab Duo features. For compatible models not included in supported model families, use the general model family.

Compatible models are excluded from the definition of Customer Integrated Models in the [AI Functionality Terms](https://handbook.gitlab.com/handbook/legal/ai-functionality-terms/). Compatible models and platforms must adhere to the OpenAI API specification. Models and platforms that have
previously been marked as experimental or beta are now considered compatible models.

This feature is in beta and is therefore subject to change as we gather feedback and improve the integration:

- GitLab does not provide technical support for issues specific to your chosen model or platform.
- Not all GitLab Duo features are guaranteed to work optimally with every compatible model.
- Response quality, speed, and performance overall might vary significantly based on your model choice.

| Model family | Model requirements | Supported platforms |
|-------------|-------|---------------------|
| General | Any model compatible with the [OpenAI API specification](https://platform.openai.com/docs/api-reference) | Any platform that provides OpenAI-compatible API endpoints |
| CodeGemma      | [CodeGemma 2b](https://huggingface.co/google/codegemma-2b) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| CodeGemma      | [CodeGemma 7b-it](https://huggingface.co/google/codegemma-7b-it) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| CodeGemma      | [CodeGemma 7b-code](https://huggingface.co/google/codegemma-7b) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| Code Llama     | [Code-Llama 13b](https://huggingface.co/meta-llama/CodeLlama-13b-Instruct-hf) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| DeepSeek Coder | [DeepSeek Coder 33b Instruct](https://huggingface.co/deepseek-ai/deepseek-coder-33b-instruct) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| DeepSeek Coder | [DeepSeek Coder 33b Base](https://huggingface.co/deepseek-ai/deepseek-coder-33b-base) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| Mistral        | [Mistral 7B-it v0.2](https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.2) | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) <br> [AWS Bedrock](https://aws.amazon.com/bedrock/mistral/) |
| Mistral | [Mistral 7B-it v0.3](https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.3) <sup>1</sup> | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |
| Mistral | [Mixtral 8x7B-it v0.1](https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1) <sup>1</sup> | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments), [AWS Bedrock](https://aws.amazon.com/bedrock/mistral/) |
| Mistral | [Mixtral 8x22B-it v0.1](https://huggingface.co/mistralai/Mixtral-8x22B-Instruct-v0.1) <sup>1</sup> | [vLLM](supported_llm_serving_platforms.md#for-self-hosted-model-deployments) |

**Footnotes**:

1. Support for this model was removed in GitLab 18.5. You should use Mistral Small 24B Instruct 2506 instead.

<!-- vale gitlab_base.Spelling = YES -->

## GitLab AI vendor models

{{< details >}}

- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17192) in GitLab 18.3, with a [feature flag](../feature_flags/_index.md) named `ai_self_hosted_vendored_features`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

GitLab AI vendor models integrate with GitLab-hosted AI gateway infrastructure to provide access to AI models curated and made available by GitLab. Instead of using your own self-hosted models, you can choose to use GitLab AI vendor models for specific GitLab Duo features.

To choose which features use GitLab AI vendor models, see [Configure GitLab AI vendor models](configure_duo_features.md#configure-a-feature-to-use-a-gitlab-ai-vendor-model).

When enabled for a specific feature:

- All calls to those features configured with a GitLab AI vendor model use the GitLab-hosted AI gateway, not the self-hosted AI gateway.
- No detailed logs are generated in the GitLab-hosted AI gateway, even when [AI logs are enabled](logging.md#enable-logging). This prevents unintended leaks of sensitive information.

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
| 7B models<br>(for example, Mistral 7B)     | 1x NVIDIA A100 (40 GB)    | 35 GB                 |
| 22B models<br>(for example, Codestral 22B) | 2x NVIDIA A100 (80 GB)    | 110 GB                |
| Mixtral 8x7B                               | 2x NVIDIA A100 (80 GB)    | 220 GB                |
| Mixtral 8x22B                              | 8x NVIDIA A100 (80 GB)    | 526 GB                |

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
