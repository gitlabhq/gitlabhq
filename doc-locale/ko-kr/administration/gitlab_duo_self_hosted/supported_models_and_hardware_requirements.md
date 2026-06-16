---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 지원되는 모델 및 하드웨어 요구 사항입니다.
title: 모델 및 하드웨어 요구 사항
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/12972) [플래그 포함](../feature_flags/_index.md) `ai_custom_model`. 기본적으로 비활성화됨.
- GitLab 17.6에서 [GitLab Self-Managed에서 활성화됨](https://gitlab.com/groups/gitlab-org/-/epics/15176).
- GitLab 17.6 이상에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- `ai_custom_model` 기능 플래그가 GitLab 17.8에서 제거되었습니다.
- GitLab 17.9에서 일반적으로 사용 가능합니다.
- GitLab 18.0에서 Premium을 포함하도록 변경되었습니다.

{{< /history >}}

Mistral, Meta, Anthropic 및 OpenAI의 업계 선도 모델과 선호하는 제공 플랫폼을 통해 통합할 수 있습니다.

다음을 사용할 수 있습니다:

- 특정 성능 요구 사항과 사용 사례에 맞게 지원되는 모델입니다.
- GitLab 18.3 이상에서 공식적으로 지원되는 옵션을 초과하는 모델을 실험하기 위해 자신의 호환 가능한 모델을 사용합니다.
- 자체 인프라를 호스팅할 필요 없이 AI 모델에 연결하기 위한 GitLab 관리 모델입니다. 이러한 모델은 완전히 GitLab에서 관리됩니다.

## 지원되는 모델 {#supported-models}

GitLab 지원 모델은 특정 모델 및 기능 조합에 따라 GitLab Duo 기능에 대해 다양한 수준의 기능을 제공합니다.

- {{< icon name="check-circle-filled" >}} 전체 기능:  모델은 품질 손실 없이 기능을 처리할 수 있습니다.
- {{< icon name="check-circle-dashed" >}} 부분 기능:  모델은 기능을 지원하지만 절충이나 제한이 있을 수 있습니다.
- {{< icon name="dash-circle" >}} 제한된 기능:  모델은 기능에 부적합하며 상당한 품질 손실 또는 성능 이슈가 발생할 수 있습니다. 기능에 대해 제한된 기능을 가진 모델은 해당 특정 기능에 대해 GitLab 지원을 받지 않습니다.

<!-- vale gitlab_base.Spelling = NO -->

| 모델 제품군 | 모델 | 코드 완료 | 코드 생성 | GitLab Duo 비에이전트 모드 Chat | GitLab Duo AI 에이전트 플랫폼 |
|--------------|-------|-----------------|-----------------|---------------------------|---------------------------|
| Claude 4 | [Claude 4 Sonnet](https://www.anthropic.com/news/claude-4) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 |
| Claude 4 | [Claude 4.5 Sonnet](https://www.anthropic.com/news/claude-sonnet-4-5) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 |
| Claude 4 | [Claude 4.5 Haiku](https://www.anthropic.com/news/claude-haiku-4-5) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 |
| Claude 4 | [Claude 4.5 Opus](https://www.anthropic.com/news/claude-opus-4-5) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 |
| GPT | [GPT-4 Turbo](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |
| GPT | [GPT-4o](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |
| GPT | [GPT-4o-mini](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |
| GPT | [GPT-5](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-5) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 |
| GPT | [GPT-5 Mini](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-5) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 |
| GPT | [GPT-5 Codex](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-5) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 |
| GPT | [GPT-5.1](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-51) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 |
| GPT | [GPT-5.2](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-52) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 |
| GPT | [GPT-oss-120B](https://huggingface.co/openai/gpt-oss-120b) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |
| Mistral Devstral | [Devstral 2 123B](https://huggingface.co/mistralai/Devstral-2-123B-Instruct-2512) | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 |
| Mistral Codestral | [Codestral 22B v0.1](https://huggingface.co/mistralai/Codestral-22B-v0.1) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |
| Mistral | [Mistral Small 24B Instruct 2506](https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |
| GLM | [GLM-5.1-FP8](https://huggingface.co/zai-org/GLM-5.1-FP8) | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 |
| Kimi | [Kimi-K2.5](https://huggingface.co/moonshotai/Kimi-K2.5) | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 |
| Kimi | [Kimi-K2.6](https://huggingface.co/moonshotai/Kimi-K2.6) | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 |
| MiniMax | [MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 |
| Llama | [Llama 3 8B](https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct) | {{< icon name="check-circle-dashed" >}} 부분 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |
| Llama | [Llama 3.1 8B](https://huggingface.co/meta-llama/Llama-3.1-8B-Instruct) | {{< icon name="check-circle-dashed" >}} 부분 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-dashed" >}} 부분 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |
| Llama | [Llama 3 70B](https://huggingface.co/meta-llama/Meta-Llama-3-70B-Instruct) | {{< icon name="check-circle-dashed" >}} 부분 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="dash-circle" >}} 제한된 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |
| Llama | [Llama 3.1 70B](https://huggingface.co/meta-llama/Llama-3.1-70B-Instruct) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |
| Llama | [Llama 3.3 70B](https://huggingface.co/meta-llama/Llama-3.3-70B-Instruct) | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="check-circle-filled" >}} 전체 기능 | {{< icon name="dash-circle" >}} 제한된 기능 |

### 호환 가능한 모델 {#compatible-models}

{{< details >}}

- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 18.3에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/18556) [베타](../../policy/development_stages_support.md#beta).

{{< /history >}}

GitLab Duo Agent Platform 및 GitLab Duo 기능과 함께 자신의 호환 가능한 모델 및 플랫폼을 사용할 수 있습니다. 지원되는 모델 제품군에 포함되지 않은 호환 가능한 모델의 경우 일반 모델 제품군을 사용합니다. 여기에는 자신이 호스팅하는 모델(예: vLLM 또는 LiteLLM을 통해 제공)이 포함되며, OpenAI API 호환 `/v1` 엔드포인트를 통해 노출되어야 한다는 요구 사항이 있습니다.

호환 가능한 모델은 [AI 기능 약관](https://handbook.gitlab.com/handbook/legal/ai-functionality-terms/)의 고객 통합 모델 정의에서 제외됩니다. 호환 가능한 모델 및 플랫폼은 OpenAI API 사양을 준수해야 합니다. 이전에 실험적 또는 베타로 표시된 모델 및 플랫폼은 이제 호환 가능한 모델로 간주됩니다.

이 기능은 베타 상태이므로 피드백을 수집하고 통합을 개선함에 따라 변경될 수 있습니다:

- GitLab은 선택한 모델 또는 플랫폼에 특정한 이슈에 대해 기술 지원을 제공하지 않습니다.
- 모든 Agent Platform 또는 GitLab Duo 기능이 모든 호환 가능한 모델에서 최적으로 작동하도록 보장되지는 않습니다.
- 응답 품질, 속도 및 전반적인 성능은 선택한 모델에 따라 크게 달라질 수 있습니다.

#### GitLab Duo {#gitlab-duo}

| 모델 제품군   | 모델 |
|----------------|-------|
| 일반        | [OpenAI API 사양](https://platform.openai.com/docs/api-reference)과 호환되는 모든 모델 |
| CodeGemma      | [CodeGemma 2b](https://huggingface.co/google/codegemma-2b) |
| CodeGemma      | [CodeGemma 7b-it](https://huggingface.co/google/codegemma-7b-it) |
| CodeGemma      | [CodeGemma 7b-code](https://huggingface.co/google/codegemma-7b) |
| Code Llama     | [Code-Llama 13b](https://huggingface.co/meta-llama/CodeLlama-13b-Instruct-hf) |
| DeepSeek Coder | [DeepSeek Coder 33b Instruct](https://huggingface.co/deepseek-ai/deepseek-coder-33b-instruct) |
| DeepSeek Coder | [DeepSeek Coder 33b Base](https://huggingface.co/deepseek-ai/deepseek-coder-33b-base) |

<!-- vale gitlab_base.Spelling = YES -->

#### GitLab Duo Agent Platform {#gitlab-duo-agent-platform}

| 모델 제품군   | 모델 |
|----------------|-------|
| 일반        | [OpenAI API 사양](https://platform.openai.com/docs/api-reference)과 호환되는 모든 모델 |
| Gemini         | [Gemini 3.1 Pro](https://deepmind.google/models/gemini/pro/) |
| Gemini         | [Gemini 3.0 Flash](https://deepmind.google/models/gemini/flash/) |
| Gemma 4        | [Gemma-4-31B-IT](https://huggingface.co/google/gemma-4-31B-it) |
| Qwen 3.6       | [Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B) |

<!-- vale gitlab_base.Spelling = YES -->

## GitLab 관리 모델 {#gitlab-managed-models}

{{< history >}}

- GitLab 18.3에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/17192) [베타](../../policy/development_stages_support.md#beta) 기능, [기능 플래그](../feature_flags/_index.md) `ai_self_hosted_vendored_features` 포함. 기본적으로 비활성화됨.
- GitLab 18.7에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030)
- 기능 플래그 `ai_self_hosted_vendored_features`이 GitLab 18.9에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218595)되었습니다.

{{< /history >}}

GitLab 관리 모델은 GitLab 호스팅 AI Gateway 인프라와 통합되어 GitLab에서 선별하고 제공하는 AI 모델에 대한 액세스를 제공합니다. 자신의 자체 호스팅 모델을 사용하는 대신 특정 GitLab Duo 기능에 대해 GitLab 관리 모델을 사용하도록 선택할 수 있습니다.

어떤 기능이 GitLab 관리 모델을 사용하는지 선택하려면 [기능에 대한 GitLab 관리 모델 선택](configure_duo_features.md#select-a-gitlab-managed-model-for-a-feature)을 참조하세요.

특정 기능에 대해 활성화된 경우:

- GitLab 관리 모델로 구성된 해당 기능에 대한 모든 호출은 자체 호스팅 AI Gateway가 아닌 GitLab 호스팅 AI Gateway를 사용합니다.
- [AI 로그가 활성화된](logging.md#turn-on-data-collection-for-gitlab-duo) 경우에도 GitLab 호스팅 AI Gateway에서 세부 로그가 생성되지 않습니다. 이는 민감한 정보의 의도하지 않은 유출을 방지합니다.

## 하드웨어 요구 사항 {#hardware-requirements}

다음 하드웨어 사양은 온프레미스에서 GitLab Duo Self-Hosted를 실행하기 위한 최소 요구 사항입니다. 요구 사항은 모델 크기 및 의도된 사용에 따라 크게 달라집니다:

### 기본 시스템 요구 사항 {#base-system-requirements}

- **CPU**:
  - 최소:  8개 코어(16개 스레드)
  - 권장:  프로덕션 환경용 16개 이상의 코어
- **RAM**:
  - 최소:  32GB
  - 권장:  대부분의 모델의 경우 64GB
- **스토리지**:
  - 모델 가중치 및 데이터를 위한 충분한 공간이 있는 SSD입니다.

### 모델 크기별 GPU 요구 사항 {#gpu-requirements-by-model-size}

| 모델 크기                                 | 최소 GPU 구성 | 필요한 최소 VRAM |
|--------------------------------------------|---------------------------|-----------------------|
| 7B 모델<br>(예: Mistral 7B)     | 1x NVIDIA A100(40GB)    | 35GB                 |
| 22B 모델<br>(예: Codestral 22B) | 2x NVIDIA A100(80GB)    | 110GB                |
| Mixtral 8x7B                               | 2x NVIDIA A100(80GB)    | 220GB                |
| Mixtral 8x22B                              | 8x NVIDIA A100(80GB)    | 526GB                |

[Hugging Face의 메모리 유틸리티](https://huggingface.co/spaces/hf-accelerate/model-memory-usage)를 사용하여 메모리 요구 사항을 확인합니다.

### 모델 크기 및 GPU별 응답 시간 {#response-time-by-model-size-and-gpu}

#### 소규모 머신 {#small-machine}

`a2-highgpu-2g`(2x NVIDIA A100 40GB - 150GB vRAM) 또는 동등한 구성:

| 모델 이름               | 요청 수 | 요청당 평균 시간(초) | 응답의 평균 토큰 | 요청당 초당 평균 토큰 | 요청의 총 시간 | 총 TPS |
|--------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-------------------------|-----------|
| Mistral-7B-Instruct-v0.3 | 1                  | 7.09                         | 717.0                      | 101.19                                | 7.09                    | 101.17    |
| Mistral-7B-Instruct-v0.3 | 10                 | 8.41                         | 764.2                      | 90.35                                 | 13.70                   | 557.80    |
| Mistral-7B-Instruct-v0.3 | 100                | 13.97                        | 693.23                     | 49.17                                 | 20.81                   | 3331.59   |

#### 중규모 머신 {#medium-machine}

`a2-ultragpu-4g`(4x NVIDIA A100 40GB - 340GB vRAM) GCP 머신 또는 동등한 구성:

| 모델 이름                 | 요청 수 | 요청당 평균 시간(초) | 응답의 평균 토큰 | 요청당 초당 평균 토큰 | 요청의 총 시간 | 총 TPS |
|----------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-------------------------|-----------|
| Mistral-7B-Instruct-v0.3   | 1                  | 3.80                         | 499.0                      | 131.25                                | 3.80                    | 131.23    |
| Mistral-7B-Instruct-v0.3   | 10                 | 6.00                         | 740.6                      | 122.85                                | 8.19                    | 904.22    |
| Mistral-7B-Instruct-v0.3   | 100                | 11.71                        | 695.71                     | 59.06                                 | 15.54                   | 4477.34   |
| Mixtral-8x7B-Instruct-v0.1 | 1                  | 6.50                         | 400.0                      | 61.55                                 | 6.50                    | 61.53     |
| Mixtral-8x7B-Instruct-v0.1 | 10                 | 16.58                        | 768.9                      | 40.33                                 | 32.56                   | 236.13    |
| Mixtral-8x7B-Instruct-v0.1 | 100                | 25.90                        | 767.38                     | 26.87                                 | 55.57                   | 1380.68   |

#### 대규모 머신 {#large-machine}

`a2-ultragpu-8g`(8 x NVIDIA A100 80GB - 1360GB vRAM) GCP 머신 또는 동등한 구성:

| 모델 이름                  | 요청 수 | 요청당 평균 시간(초) | 응답의 평균 토큰 | 요청당 초당 평균 토큰 | 요청의 총 시간(초) | 총 TPS |
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

### AI Gateway 하드웨어 요구 사항 {#ai-gateway-hardware-requirements}

AI Gateway 하드웨어에 대한 권장 사항은 [AI Gateway 확장 권장 사항](../../install/install_ai_gateway.md#scaling-recommendations)을 참조하세요.
