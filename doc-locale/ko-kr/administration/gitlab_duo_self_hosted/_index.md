---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 자체 AI Gateway 및 언어 모델을 호스팅합니다.
title: 자체 호스팅 모델
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [GitLab 17.1](https://gitlab.com/groups/gitlab-org/-/epics/12972) 에서 [플래그](../feature_flags/_index.md)를 사용하여 `ai_custom_model`로 도입되었습니다. 기본적으로 비활성화됨.
- GitLab 17.6에서 [GitLab Self-Managed에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/epics/15176).
- GitLab 17.6 이상에서 GitLab Duo 애드온이 필요하도록 변경되었습니다.
- 기능 플래그 `ai_custom_model`는 GitLab 17.8에서 제거되었습니다.
- GitLab 17.9에서 정식 버전(GA)으로 제공됩니다.
- GitLab 18.0에서 Premium을 포함하도록 변경되었습니다.
- GitLab 18.8에서 오프라인 라이선스에 대해 GitLab Duo Agent Platform Self-Hosted 애드온이 필요하도록 변경되었습니다.
- GitLab 18.9에서 온라인 라이선스에 대해 GitLab Duo Agent Platform의 기능 사용 청구로 변경되었습니다.

{{< /history >}}

원하는 LLM으로 GitLab Duo 기능을 사용하기 위해 자신의 AI 인프라를 호스팅합니다. 자체 호스팅 AI Gateway를 사용하여 모든 요청 및 응답 데이터를 자신의 환경에 유지하고, 외부 API 호출을 피하고, LLM 백엔드에 대한 요청의 전체 수명 주기를 관리합니다.

## 배포 옵션 {#deployment-options}

다양한 배포 옵션으로 자체 호스팅 모델을 사용할 수 있습니다.

### GitLab Duo Agent Platform {#gitlab-duo-agent-platform}

온프레미스 모델 또는 프라이빗 클라우드 호스팅 모델을 위해 GitLab Duo Agent Platform Self-Hosted를 사용합니다.

오프라인 라이선스가 있는 고객의 경우 GitLab Duo에 대한 엔터프라이즈 라이선스 계약을 사용하는 청구이며, [GitLab Duo Agent Platform Self-Hosted](../../subscriptions/subscription-add-ons.md#gitlab-duo-agent-platform-self-hosted) 애드온이 있어야 합니다.

온라인 라이선스가 있는 고객의 경우 청구는 [사용량 기반](../../subscriptions/gitlab_credits.md)입니다. 하이브리드 배포에서 GitLab 관리 모델을 사용할 수도 있습니다.

### GitLab Duo {#gitlab-duo}

GitLab Duo Self-Hosted는 GitLab Duo 기능을 사용하는 GitLab Duo Enterprise 고객을 위한 것입니다. 다음을 사용할 수 있습니다:

- 온프레미스 모델 또는 프라이빗 클라우드 호스팅 모델
- 하이브리드 배포에서 GitLab 관리 모델

이 옵션은 사용자 기반 가격 책정을 사용합니다.

### 기능 버전 및 상태 {#feature-versions-and-status}

다음 표는 다음 항목을 나열합니다:

- 기능을 사용하는 데 필요한 GitLab 버전입니다.
- 기능 상태입니다. 배포의 기능 상태는 기능에 나열된 상태와 다를 수 있습니다.

GitLab Duo Self-Hosted와 함께 GitLab Duo 기능을 사용하려면 GitLab Duo Enterprise 애드온이 있어야 합니다. 이는 GitLab이 클라우드 기반 [AI Gateway](../gitlab_duo/gateway.md)를 통해 해당 모델을 호스팅하고 연결할 때 GitLab Duo Core 또는 GitLab Duo Pro를 사용하여 이러한 기능을 사용할 수 있는 경우에도 적용됩니다.

| 기능                                                                                                                                | GitLab 버전          | 상태              |
|----------------------------------------------------------------------------------------------------------------------------------------|-------------------------|---------------------|
| [GitLab Duo AI 에이전트 플랫폼](../../user/duo_agent_platform/_index.md)                                                                   | GitLab 18.8 이상   | 정식 버전(GA) |
| **GitLab Duo** | | |
| [Code Suggestions](../../user/project/repository/code_suggestions/_index.md)                                                 | GitLab 17.9 이상   | 정식 버전(GA) |
| [GitLab Duo Non-Agentic Chat](../../user/gitlab_duo_chat/_index.md)                                                                      | GitLab 17.9 이상   | 정식 버전(GA) |
| [코드 설명](../../user/gitlab_duo_chat/examples.md#explain-selected-code)                                                       | GitLab 17.9 이상   | 정식 버전(GA) |
| [테스트 생성](../../user/gitlab_duo_chat/examples.md#write-tests-in-the-ide)                                                       | GitLab 17.9 이상   | 정식 버전(GA) |
| [코드 리팩터링](../../user/gitlab_duo_chat/examples.md#refactor-code-in-the-ide)                                                       | GitLab 17.9 이상   | 정식 버전(GA) |
| [코드 수정](../../user/gitlab_duo_chat/examples.md#fix-code-in-the-ide)                                                                 | GitLab 17.9 이상   | 정식 버전(GA) |
| [코드 검토](../../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)                           | GitLab 18.3 이상   | 정식 버전(GA) |
| [근본 원인 분석](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)                   | GitLab 17.10 이상  | 베타                |
| [취약성 설명](../../user/application_security/analyze/duo.md)                                                            | GitLab 18.1.2 이상 | 베타                |
| [머지 리퀘스트 커밋 메시지 생성](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)          | GitLab 18.1.2 이상 | 베타                |
| [머지 리퀘스트 요약](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | GitLab 18.1.2 이상 | 베타                |
| [토론 요약](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)                                | GitLab 18.1.2 이상 | 베타                |
| [CLI용 GitLab Duo](https://docs.gitlab.com/cli/)                                                                                 | GitLab 18.1.2 이상 | 베타                |
| [취약성 해결](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution)                         | GitLab 18.1.2 이상 | 베타                |
| [GitLab Duo 및 SDLC 추세 대시보드](../../user/analytics/duo_and_sdlc_trends.md)                                                    | GitLab 17.9 이상   | 베타                |
| [코드 검토 요약](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review)                              | GitLab 18.1.2 이상 | 실험          |

## 데이터 전송 {#data-transmission}

다음 청구 메타데이터는 사용량 청구를 위해 JSON 객체로 GitLab에 전송됩니다:

- 인스턴스 ID
- 사용자 ID
- 호출 수
- 타임스탬프

예를 들어:

```json
{
  "InstanceId": "ccbb3949-9836-471c-b2nb-32a38e8cca99",
  "GlobalUserId": "KWDTe17sGSADiAzEGJ6IuL1D7RAzsXqa2wun3aX1YuA=",
  "Quantity": 1,
  "Timestamp": "2026-05-04 18:04:30.969000000"
}
```

코드 입력, 모델 프롬프트, 모델 응답을 포함한 추론 데이터는 고객 네트워크를 벗어나지 않습니다.

GitLab은 고객이 사용하는 모델 또는 모델 제공자를 캡처하지 않습니다.

## AI Gateway 구성 {#ai-gateway-configurations}

제품 옵션을 선택한 후 AI Gateway를 LLM에 연결하는 방법을 구성합니다:

- **Self-hosted AI Gateway and LLMs**:  자신의 AI 인프라를 완전히 제어하기 위해 자신의 AI Gateway 및 모델을 사용합니다.
- **Hybrid AI Gateway and model configuration**:  각 기능에 대해 자체 호스팅 AI Gateway와 자체 호스팅 모델을 사용하거나 GitLab.com AI Gateway와 GitLab 관리 모델을 사용합니다.
- **GitLab.com AI Gateway with default GitLab external vendor LLMs**:  GitLab 관리 AI 인프라를 사용합니다.

| 구성               | 자체 호스팅 AI Gateway                                                                    | 하이브리드 AI Gateway 및 모델 구성                                                                                                        | GitLab.com AI Gateway                    |
|-----------------------------|-------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| 인프라 요구 사항 | 자신의 AI Gateway 및 모델을 호스팅해야 합니다.                                           | 자신의 AI Gateway 및 모델을 호스팅해야 합니다.                                                                                                  | 추가 인프라가 필요하지 않습니다.      |
| 모델 옵션               | [지원되는 자체 호스팅 모델](supported_models_and_hardware_requirements.md)에서 선택합니다. | [지원되는 자체 호스팅 모델](supported_models_and_hardware_requirements.md) 또는 각 GitLab Duo 기능에 대해 GitLab 관리 모델에서 선택합니다. | 기본 GitLab 관리 모델을 사용합니다. |
| 네트워크 요구 사항        | 완전히 격리된 네트워크에서 작동할 수 있습니다.                                                    | GitLab 관리 모델을 사용하는 GitLab Duo 기능에 대해 인터넷 연결이 필요합니다.                                                          | 인터넷 연결이 필요합니다.           |
| 책임            | 인프라를 설정하고 유지 관리를 직접 수행합니다.                               | 인프라를 설정하고 유지 관리를 직접 수행하며, GitLab 관리 모델과 AI Gateway를 사용하는 기능을 선택합니다.                    | GitLab이 설정과 유지 관리를 수행합니다.   |

### 자체 호스팅 AI Gateway 및 LLM {#self-hosted-ai-gateway-and-llms}

완전히 자체 호스팅 구성에서는 자신의 AI Gateway를 배포하고 GitLab 인프라 또는 AI 벤더 모델을 사용하지 않고 인프라에서만 [지원되는 LLM](supported_models_and_hardware_requirements.md)을 사용합니다. 이를 통해 데이터와 보안을 완전히 제어할 수 있습니다.

> [!note]
> 이 구성에는 자체 호스팅 AI Gateway를 통해 구성된 모델만 포함됩니다. 모든 기능에 대해 [GitLab 관리 모델](configure_duo_features.md#select-a-gitlab-managed-model-for-a-feature)을 사용하는 경우 해당 기능은 자체 호스팅 게이트웨이 대신 GitLab 호스팅 AI Gateway에 연결되어 완전히 자체 호스팅되지 않는 하이브리드 구성이 됩니다.

자신의 AI Gateway를 배포하는 동안 [AWS Bedrock](https://aws.amazon.com/bedrock/) 또는 [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service)와 같은 클라우드 기반 LLM 서비스를 모델 백엔드로 사용할 수 있으며, 자체 호스팅 AI Gateway를 통해 계속 연결됩니다.

인터넷 액세스를 방지하거나 제한하는 물리적 장벽 또는 보안 정책이 있는 오프라인 환경과 포괄적인 LLM 제어가 있는 경우 이 완전히 자체 호스팅 구성을 사용해야 합니다.

자세한 정보는 다음을 참조하세요:

- [자체 호스팅 AI Gateway 구성 다이어그램](configuration_types.md#self-hosted-ai-gateway)입니다.

### 하이브리드 AI Gateway 및 모델 구성 {#hybrid-ai-gateway-and-model-configuration}

{{< history >}}

- GitLab 18.3에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/17192) 되었으며 [베타](../../policy/development_stages_support.md#beta) 로 [기능 플래그](../feature_flags/_index.md) `ai_self_hosted_vendored_features`를 사용합니다. 기본적으로 비활성화됨.
- GitLab 18.7에서 [기본적으로 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030).
- GitLab 18.9에서 일반적으로 사용 가능합니다. 기능 플래그 `ai_self_hosted_vendored_features` [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218595)되었습니다.

{{< /history >}}

이 하이브리드 구성에서는 자신의 AI Gateway 및 자체 호스팅 모델을 대부분의 기능에 배포하지만 특정 기능을 GitLab 관리 모델을 사용하도록 구성합니다. 기능이 GitLab 관리 모델을 사용하도록 구성된 경우 해당 기능에 대한 요청은 자체 호스팅 AI Gateway 대신 GitLab 호스팅 AI Gateway로 전송됩니다.

이 옵션은 다음을 수행할 수 있도록 하여 유연성을 제공합니다:

- 완전한 제어를 원하는 기능에 대해 자신의 자체 호스팅 모델을 사용합니다.
- GitLab이 큐레이팅한 모델을 선호하는 특정 기능에 대해 GitLab 관리 벤더 모델을 사용합니다.

> [!note]
> 기능이 GitLab 관리 모델을 사용하도록 구성된 경우:
>
> - 해당 기능에 대한 모든 호출은 자체 호스팅 AI Gateway가 아닌 GitLab 호스팅 AI Gateway를 사용합니다.
> - 이러한 기능에 대해 인터넷 연결이 필요합니다.
> - 이는 완전히 자체 호스팅되거나 격리된 구성이 아닙니다.

#### GitLab 관리 모델 {#gitlab-managed-models}

GitLab 관리 모델을 사용하여 인프라를 자체 호스팅할 필요 없이 AI 모델에 연결합니다. 이러한 모델은 완전히 GitLab으로 관리됩니다.

AI 네이티브 기능에 사용할 기본 GitLab 모델을 선택할 수 있습니다. 기본 모델의 경우 GitLab은 가용성, 품질, 안정성에 따라 최고의 모델을 사용합니다. 기능에 사용되는 모델은 예고 없이 변경될 수 있습니다.

특정 GitLab 관리 모델을 선택하면 해당 기능에 대한 모든 요청이 해당 모델을 독점적으로 사용합니다. 모델을 사용할 수 없게 되면 AI Gateway에 대한 요청이 실패하고 사용자는 다른 모델을 선택할 때까지 해당 기능을 사용할 수 없습니다.

> [!note]
> 기능을 GitLab 관리 모델을 사용하도록 구성할 때:
>
> - 해당 기능에 대한 호출은 자체 호스팅 AI Gateway가 아닌 GitLab 호스팅 AI Gateway를 사용합니다.
> - 이러한 기능에 대해 인터넷 연결이 필요합니다.
> - 구성이 완전히 자체 호스팅되거나 격리되지 않습니다.

### GitLab.com AI Gateway 및 기본 GitLab 외부 벤더 LLM {#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms}

{{< details >}}

- 추가 기능:  GitLab Duo Core, Pro 또는 Enterprise

{{< /details >}}

GitLab Duo Self-Hosted에 대한 사용 사례 기준을 충족하지 않는 경우 GitLab.com AI Gateway와 기본 GitLab 외부 벤더 LLM을 사용할 수 있습니다.

GitLab.com AI Gateway는 기본 엔터프라이즈 제공이며 자체 호스팅되지 않습니다. 이 구성에서는 인스턴스를 GitLab 호스팅 AI Gateway에 연결하고, 이는 다음을 포함한 외부 벤더 LLM 제공자와 통합됩니다:

- [Anthropic](https://www.anthropic.com/)
- [Fireworks AI](https://fireworks.ai/)
- [Google Vertex](https://cloud.google.com/vertex-ai/)

이러한 LLM은 GitLab Cloud Connector를 통해 통신하며, 온프레미스 인프라가 필요 없는 즉시 사용 가능한 AI 솔루션을 제공합니다.

더 많은 정보를 보려면 [GitLab.com AI Gateway 구성 다이어그램](configuration_types.md#gitlabcom-ai-gateway)을 참조하세요.

이 인프라를 설정하려면 [GitLab Self-Managed 인스턴스에서 GitLab Duo를 구성하는 방법](../gitlab_duo/configure/gitlab_self_managed.md)을 참조하세요.

## 프라이빗 인프라 설정 {#set-up-a-private-infrastructure}

오프라인 라이선스가 있는 경우 완전히 프라이빗 인프라를 설정할 수 있습니다:

1. 대규모 언어 모델(LLM) 서빙 인프라를 설치합니다.

   - GitLab은 vLLM, AWS Bedrock, Azure OpenAI와 같은 LLM을 서빙하고 호스팅하기 위한 다양한 플랫폼을 지원합니다. 각 플랫폼에 대한 자세한 정보는 [지원되는 LLM 플랫폼 설명서](supported_llm_serving_platforms.md)를 참조하세요.

   - GitLab은 특정 기능 및 하드웨어 요구 사항과 함께 지원되는 모델의 매트릭스를 제공합니다. 더 많은 정보를 보려면 [지원되는 모델 및 하드웨어 요구 사항 설명서](supported_models_and_hardware_requirements.md)를 참조하세요.

1. [AI Gateway 설치](../../install/install_ai_gateway.md)하여 GitLab Duo 기능에 액세스합니다.
1. [GitLab 인스턴스 구성](configure_duo_features.md)하여 기능이 자체 호스팅 모델을 사용하도록 합니다.
1. [로깅 활성화](logging.md)하여 시스템의 성능을 추적하고 관리합니다.

## 관련 항목 {#related-topics}

- [문제 해결](troubleshooting.md)
- [GitLab AI Gateway 설치](../../install/install_ai_gateway.md)
- [지원되는 모델](supported_models_and_hardware_requirements.md)
- [지원되는 플랫폼](supported_llm_serving_platforms.md)
- [튜토리얼: AWS Bedrock BYOM 배포 가이드](../../solutions/integrations/aws_bedrock_byom.md)
