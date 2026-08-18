---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo 기능을 위한 대규모 언어 모델(LLM)을 구성합니다.
title: Agent Platform AI 모델
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

모든 GitLab Duo 기능은 기본 모델을 사용합니다. GitLab은 성능 최적화를 위해 기본 모델을 업데이트할 수 있습니다. 일부 기능의 경우 다른 모델을 선택할 수 있으며, 이는 변경하기 전까지 유지됩니다.

## 기본 모델 {#default-models}

이 표는 Agent Platform의 각 기능에 대한 기본 모델을 나열합니다.

| 기능 | 모델 |
|-------|--------------|
| GitLab Duo Agentic Chat | Claude Sonnet 4.6 Vertex |
| Code Review 플로우 | Claude Sonnet 4.6 Vertex |
| 기타 모든 에이전트 | Claude Sonnet 4.6 Vertex |

## 지원 모델 {#supported-models}

이 표는 Agent Platform의 기능에 대해 선택 가능한 모델을 나열합니다.

| 모델                | GitLab Duo Agentic Chat | Code Review 플로우 | 기타 모든 에이전트 |
|----------------------|-------------------------|------------------|------------------|
| Claude Fable 5 <sup>1</sup>      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Sonnet 4.5    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Sonnet 4.6    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Haiku 4.5     | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.5      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.6      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.7      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.8      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Gemini 3.5 Flash     | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5                | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.1              | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2              | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| GPT-5.5 <sup>1</sup> | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5 Codex          | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2 Codex        | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.3 Codex        | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| GPT-5 Mini           | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Mini         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Nano         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |

**각주**:

1. 이 모델은 [제한된 공급업체 측 데이터 보존](../gitlab_duo/data_usage.md#data-retention)의 적용을 받습니다.

## 기능을 위한 모델 선택 {#select-a-model-for-a-feature}

{{< details >}}

- 제공 서비스: GitLab.com

{{< /details >}}

{{< history >}}

- `ai_model_switching`이라는 이름의 [플래그](../../administration/feature_flags/_index.md)와 함께 GitLab 18.1에서 최상위 그룹을 대상으로 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/17570). 기본적으로 비활성화됨.
- GitLab 18.4에서 베타로 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/526307).
- GitLab 18.4에서 [활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/526307).
- `duo_agent_platform_model_selection`라는 이름의 [플래그](../../administration/feature_flags/_index.md)와 함께 GitLab 18.4에서 GitLab Duo Agent Platform용 모델 선택 기능이 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/568112). 기본적으로 비활성화됨.
- GitLab 18.5에서 [정식 출시(GA)](https://gitlab.com/groups/gitlab-org/-/epics/18818). 기능 플래그 `ai_model_switching`이 활성화됨.
- GitLab 18.6에서 기능 플래그 `duo_agent_platform_model_selection`이 [활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212051).
- GitLab 18.7에서 기능 플래그 `ai_model_switching`가 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/526307).
- GitLab 18.9에서 기능 플래그 `duo_agent_platform_model_selection`이 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/218591).
- GitLab 19.1에서 Code Review 플로우용 LLM이 Claude Sonnet 4.6 Vertex로 [업데이트됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876).
- GitLab 19.1에서 **Agentic Code Review** 설정을 통해 Code Review 플로우를 위한 [별도 모델 선택 기능이 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876).
- GPT-5.2 및 GPT-5.3 Codex가 GitLab 19.1에서 [Code Review 플로우](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/5652)의 선택 가능한 모델로 추가되었습니다.
- [GitLab Duo 에이전트 채팅](https://gitlab.com/groups/gitlab-org/-/work_items/22028)을 특정 모델로 제한하는 기능이 GitLab 19.1에 추가되었습니다.

{{< /history >}}

최상위 그룹에서 기능의 기본 모델로 사용할 모델을 선택할 수 있습니다. 선택한 모델은 모든 하위 그룹 및 프로젝트의 해당 기능에 적용됩니다.

전제 조건:

- 해당 그룹에 대해 Owner 역할이 있어야 합니다.
- 모델을 선택하려는 그룹이 최상위 그룹이어야 합니다.
- GitLab 18.3 이상 버전에서 여러 GitLab Duo 네임스페이스에 속해 있는 경우, 반드시 [기본 네임스페이스를 할당](../profile/preferences.md#set-a-default-gitlab-duo-namespace)해야 합니다.

### 에이전트 채팅을 위한 모델 선택 {#select-a-model-for-agentic-chat}

에이전트 채팅을 위한 모델을 선택하려면:

1. 상단 바에서 **Search or go to**를 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **Settings** > **GitLab Duo**를 선택합니다.
1. **Configure features**를 선택합니다.
1. **GitLab Duo 에이전트 채팅** 섹션으로 이동합니다.
1. 드롭다운 목록에서 기본 모델로 설정할 모델을 선택합니다.
1. 선택 사항. 사용자가 에이전트 채팅을 위해 선택할 수 있는 다른 모델을 제한하려면:

   1. **Available models** 아래에서 **구성**을 선택합니다.
   1. **사용 가능한 모델: 에이전트 채팅** 대화상자에서 **Restrict to specific models** 확인란을 선택합니다.
   1. 에이전트 채팅을 사용할 수 있도록 하려는 모델을 선택합니다.
   1. **Save**를 선택합니다.

   > [!note]
   > 에이전트 채팅을 특정 모델로 제한하지 않으면 사용자는 모든 GitLab 관리 모델 중에서 선택할 수 있습니다.

### 에이전트 채팅이 아닌 기능을 위한 모델 선택 {#select-a-model-for-a-non-agentic-chat-feature}

에이전트 채팅이 아닌 기능을 위한 모델을 선택하려면:

1. 상단 바에서 **Search or go to**를 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **Settings** > **GitLab Duo**를 선택합니다.
1. **Configure features**를 선택합니다.
1. **GitLab Duo Agent Platform** 섹션으로 이동합니다.
1. 드롭다운 목록에서 기본 모델로 설정할 모델을 선택합니다.
1. 선택 사항. 해당 섹션의 모든 기능에 모델을 적용하려면 **Apply to all**을 선택합니다.

GitLab Duo CLI용 모델을 지정하려면 [모델 선택](../gitlab_duo_cli/_index.md#select-a-model)을 참조하세요.

### 올바른 모델 선택 {#selecting-the-right-model}

많은 사용 사례의 경우 Claude Haiku 4.5 또는 GPT-5.4 Mini와 같은 더 빠르고 비용 효율적인 모델로 시작하는 것이 최적의 접근 방식입니다. 이 접근 방식의 경우:

1. Claude Haiku 4.5 또는 GPT-5.4 Mini를 선택합니다.
1. 사용 사례를 철저히 테스트합니다.
1. 성능이 요구 사항을 충족하는지 평가합니다.
1. 특정 기능 격차가 있는 경우에만 업그레이드합니다.

다음과 같은 경우에 이 접근 방식을 사용할 수 있습니다:

- 탐색적 또는 대량 작업
- 엄격한 지연 시간 요구 사항이 있는 애플리케이션
- 비용에 민감한 구현

## 문제 해결 {#troubleshooting}

기본값 이외의 모델을 선택할 때 다음과 같은 이슈가 발생할 수 있습니다.

### 모델을 사용할 수 없음 {#model-is-not-available}

GitLab Duo AI 네이티브 기능에 기본 GitLab 모델을 사용하는 경우, GitLab은 최적의 성능과 안정성을 유지하기 위해 사용자에게 별도 통지 없이 기본 모델을 변경할 수 있습니다.

GitLab Duo AI 네이티브 기능에 특정 모델을 직접 선택한 경우, 해당 모델을 사용할 수 없게 되어도 자동 폴백이 이루어지지 않습니다. 이 모델을 사용하는 기능을 사용할 수 없게 됩니다.

### 기본 GitLab Duo 네임스페이스 없음 {#no-default-gitlab-duo-namespace}

선택한 모델로 GitLab Duo 기능을 사용할 때, 기본 GitLab Duo 네임스페이스를 설정해야 한다는 오류가 발생할 수 있습니다.

이 이슈는 여러 GitLab Duo 네임스페이스에 속해 있거나, GitLab 원격이 구성되지 않은 프로젝트에서 로컬로 작업할 때 발생합니다.

이 문제를 해결하려면 [기본 GitLab Duo 네임스페이스를 설정](../profile/preferences.md#set-a-default-gitlab-duo-namespace)하세요.

### IDE의 에이전트 채팅에 대한 모델 선택이 작동하지 않음 {#model-selection-for-agentic-chat-in-ides-does-not-work}

IDE에서 에이전트 채팅을 위한 모델을 선택할 때 모델 선택이 작동하지 않을 수 있습니다.

이 문제를 해결하려면:

1. IDE의 연결 유형이 WebSocket으로 설정되어 있는지 확인합니다.
1. 네트워크 관리자에게 [GitLab 인스턴스로의 WebSocket 트래픽이 허용되는지](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance) 확인하도록 요청합니다.
