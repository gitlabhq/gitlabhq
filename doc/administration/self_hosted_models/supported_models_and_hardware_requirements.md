---
stage: AI-Powered
group: Custom Models
description: Supported Models and Hardware Requirements.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Supported self-hosted models and hardware requirements

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab Self-Managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.
> - Feature flag `ai_custom_model` removed in GitLab 17.8

The following table shows the supported models along with their specific features and hardware requirements to help you select the model that best fits your infrastructure needs for optimal performance.

## Approved LLMs

Install one of the following GitLab-approved LLM models:

<!-- vale gitlab_base.Spelling = NO -->

| Model family | Model                                                                              | Code completion | Code generation | GitLab Duo Chat |
|--------------|------------------------------------------------------------------------------------|-----------------|-----------------|---------|
| Mistral Codestral   | [Codestral 22B v0.1](https://huggingface.co/mistralai/Codestral-22B-v0.1)                                        | **{check-circle}** Yes               | **{check-circle}** Yes               | **{dotted-circle}** No        |
| Mistral      | [Mistral 7B-it v0.3](https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.3)                     | **{check-circle}** Yes                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| Mistral      | [Mixtral 8x7B-it v0.1](https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1)        | **{check-circle}** Yes                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| Mistral      | [Mixtral 8x22B-it v0.1](https://huggingface.co/mistralai/Mixtral-8x22B-Instruct-v0.1)       |  **{check-circle}** Yes                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| Claude 3     | [Claude 3.5 Sonnet](https://www.anthropic.com/news/claude-3-5-sonnet)        | **{check-circle}** Yes                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| GPT  | [GPT-4 Turbo](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4)        | **{check-circle}** Yes                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| GPT  | [GPT-4o](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo)        | **{check-circle}** Yes                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| GPT  | [GPT-4o-mini](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo)        | **{check-circle}** Yes                | **{check-circle}** Yes               | **{check-circle}** Yes        |

The following models are under evaluation, and support is limited:

| Model family   | Model                                                                              | Code completion | Code generation | GitLab Duo Chat |
|--------------- |---------------------------------------------------------------------|-----------------|-----------------|---------|
| CodeGemma      | [CodeGemma 2b](https://huggingface.co/google/codegemma-2b)                         | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| CodeGemma      | [CodeGemma 7b-it](https://huggingface.co/google/codegemma-7b-it)                   | **{dotted-circle}** No                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| CodeGemma      | [CodeGemma 7b-code](https://huggingface.co/google/codegemma-7b)                    | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| Code Llama     | [Code-Llama 13b-code](https://huggingface.co/meta-llama/CodeLlama-13b-hf)          | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| Code Llama     | [Code-Llama 13b](https://huggingface.co/meta-llama/CodeLlama-13b-Instruct-hf)      | **{dotted-circle}** No                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| DeepSeek Coder | [DeepSeek Coder 33b Instruct](https://huggingface.co/deepseek-ai/deepseek-coder-33b-instruct)        | **{check-circle}** Yes                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| DeepSeek Coder | [DeepSeek Coder 33b Base](https://huggingface.co/deepseek-ai/deepseek-coder-33b-base)        | **{check-circle}** Yes                | **{dotted-circle}** No               | **{dotted-circle}** No        |
| Mistral        | [Mistral 7B-it v0.2](https://huggingface.co/mistralai/Mistral-7B-Instruct-v0.2)                     | **{check-circle}** Yes                | **{check-circle}** Yes               | **{check-circle}** Yes        |

<!-- vale gitlab_base.Spelling = YES -->

## Hardware requirements

The following hardware specifications are the minimum requirements for running self-hosted models on-premise. Requirements vary significantly based on the model size and intended usage:

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

| Model size | Minimum GPU configuration | Minimum VRAM required |
|------------|------------------------------|---------------------|
| 7B models<br>(for example, Mistral 7B) | 1x NVIDIA A100 (40GB) | 24 GB |
| 22B models<br>(for example, Codestral 22B) | 2x NVIDIA A100 (80GB) | 90 GB |
| Mixtral 8x7B | 2x NVIDIA A100 (80GB) | 100 GB |
| Mixtral 8x22B | 8x NVIDIA A100 (80GB) | 300 GB |

### AI Gateway Hardware Requirements

For recommendations on AI gateway hardware, see the [AI gateway scaling recommendations](../../install/install_ai_gateway.md#scaling-recommendations).
