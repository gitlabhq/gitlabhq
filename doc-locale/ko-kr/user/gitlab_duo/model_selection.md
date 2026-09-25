---
stage: AI Platform
group: AI Model Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo 기능을 위한 대규모 언어 모델(LLM)을 구성합니다.
title: GitLab Duo AI 모델
---

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

모든 GitLab Duo 기능은 기본 모델을 사용합니다. GitLab은 성능 최적화를 위해 기본 모델을 업데이트할 수 있습니다. 모델 변경은 GitLab AI 게이트웨이에서 발생하며 GitLab 버전과 관계없이 적용됩니다.

기능에 대해 다른 모델을 선택할 수 있으며, 변경할 때까지 유지됩니다.

## 기본 모델 {#default-models}

{{< history >}}

- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/614057) \- GitLab 19.4에서 GitLab Duo 코드 검토의 모델 설정이 **Non-Agentic Code Review**로 변경되었습니다.

{{< /history >}}

다음 표는 각 GitLab Duo 기능의 기본 모델을 나열합니다.

| 기능 | 모델 |
|---------|---------------|
| **Code Suggestions** | |
| 코드 생성 | Claude Sonnet 4.6 Vertex |
| 코드 완성 | Codestral 25.08 Fireworks |
| **GitLab Duo Chat** | |
| 일반 대화 | Claude Sonnet 4.6 Vertex |
| 코드 설명 | Claude Sonnet 4.6 Vertex |
| 테스트 생성 | Claude Sonnet 4.6 Vertex |
| 코드 리팩토링 | Claude Sonnet 4.6 Vertex |
| 코드 수정 | Claude Sonnet 4.6 Vertex |
| 근본 원인 분석 | Claude Sonnet 4.6 Vertex |
| **머지 리퀘스트에 대한 GitLab Duo** | |
| 머지 커밋 메시지 생성 | Claude Sonnet 4.6 Vertex|
| 머지 리퀘스트 요약 | Claude Sonnet 4.6 Vertex |
| 코드 검토 요약 | Claude Sonnet 4.6 Vertex |
| Non-Agentic Code Review | Claude Sonnet 4.5 Vertex |
| **기타 GitLab Duo 기능** | |
| 취약성 설명 | Claude Sonnet 4.6 Vertex |
| 취약성 해결 | Claude Sonnet 4.6 Vertex |
| 토론 요약 | Claude Sonnet 4.6 Vertex |
| CLI용 GitLab Duo | Claude Sonnet 4.6 Vertex |

## 지원 모델 {#supported-models}

{{< history >}}

- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/614057) \- GitLab 19.4에서 GitLab Duo 코드 검토의 모델 설정이 **Non-Agentic Code Review**로 변경되었습니다.

{{< /history >}}

다음 표는 각 기능에 대해 선택할 수 있는 모델을 나열합니다.

### 코드 제안 {#code-suggestions}

| 모델 | 코드 생성 | 코드 완성 |
|------------|-----------------|-----------------|
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} |
| Codestral 25.01 Fireworks | {{< no >}} | {{< yes >}} |
| Codestral 25.08 Fireworks | {{< no >}} | {{< yes >}} |
| Codestral 25.08 Vertex | {{< no >}} | {{< yes >}} |
| Gemini 2.5 Flash Vertex | {{< yes >}} | {{< no >}} |

### GitLab Duo Non-Agentic Chat {#gitlab-duo-non-agentic-chat}

| 모델 | 일반 대화 | 코드 설명 | 테스트 생성 | 코드 리팩토링 | 코드 수정 | 근본 원인 분석 |
|------------|--------------|------------------|-----------------|---------------|----------|---------------------|
| Claude Haiku 4.5 | {{< yes >}} | {{< no >}} | | | {{< no >}} | |
| Claude Sonnet 3 | {{< no >}} | | | {{< no >}} | | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |  |
| Claude Sonnet 4.6 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.6 Vertex | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |  |

### 머지 리퀘스트에 대한 GitLab Duo {#gitlab-duo-for-merge-requests}

| 모델 | 머지 커밋 메시지 생성 | 머지 리퀘스트 요약 | 코드 검토 요약 | Non-Agentic Code Review |
|------------|--------------------------------|------------------------|---------------------|-------------|
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< no >}} | {{< no >}} | {{< no >}} | {{< yes >}} |
| Claude Sonnet 4.6 | {{< no >}} | {{< no >}} | {{< no >}} | {{< yes >}} |
| Claude Sonnet 4.6 Vertex | {{< no >}} | {{< no >}} | {{< no >}} | {{< yes >}} |

### 기타 GitLab Duo 기능 {#other-gitlab-duo-features}

| 모델 | 취약성 설명 | 취약성 해결 | CLI용 GitLab Duo | 토론 요약 |
|------------|----------------------------|--------------------------|-------------------|---------------------|
| Claude Haiku 3 | {{< yes >}} | {{< no >}} | {{< yes >}} | {{< no >}} |
| Claude Haiku 4.5 | {{< no >}} | | {{< yes >}} | {{< no >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< yes >}} |  |  | {{< yes >}} |
| Claude Sonnet 4.6 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.6 Vertex | {{< yes >}} |  |  | {{< yes >}} |

## 기능을 위한 모델 선택 {#select-a-model-for-a-feature}

{{< details >}}

- 제공 서비스: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 18.1에서 `ai_model_switching` [플래그](../../administration/feature_flags/_index.md)로 최상위 그룹을 대상으로 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/17570)되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 18.4에서 베타로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)되었습니다.
- GitLab 18.4에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)되었습니다.
- GitLab 18.5에서 [일반적으로 사용 가능](https://gitlab.com/groups/gitlab-org/-/work_items/18818)합니다. 기능 플래그 `ai_model_switching`이 활성화되었습니다.
- GitLab 18.7에서 `ai_model_switching` 기능 플래그가 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)되었습니다.

{{< /history >}}

최상위 그룹에서 각 기능에 사용할 모델을 선택할 수 있습니다. 선택한 모델은 모든 하위 그룹 및 프로젝트의 해당 기능에 적용됩니다.

GitLab Self-Managed 또는 GitLab Dedicated의 인스턴스에 대한 모델을 설정하려면 [모델 선택](../../administration/gitlab_duo/model_selection.md)을 참조하세요.

사전 요구 사항:

- 해당 그룹에 대해 Owner 역할이 있어야 합니다.
- 모델을 선택하려는 그룹이 최상위 그룹이어야 합니다.
- GitLab 18.3 이상 버전에서 여러 GitLab Duo 네임스페이스에 속해 있는 경우, 반드시 [기본 네임스페이스를 할당](../profile/preferences.md#set-a-default-gitlab-duo-namespace)해야 합니다.

기능에 대한 모델을 선택하려면:

1. 상단 바에서 **Search or go to**를 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **모델 선택** 아래에서 **모델 관리**를 선택합니다.
1. 구성할 기능을 찾고 드롭다운 목록에서 모델을 선택합니다.
1. 선택 사항입니다. 섹션의 모든 기능에 모델을 적용하려면 **모두에 적용**을 선택합니다.

### 올바른 모델 선택 {#selecting-the-right-model}

많은 사용 사례의 경우 Claude Haiku 4.5 또는 GPT-5.4 Mini와 같은 더 빠르고 비용 효율적인 모델로 시작하는 것이 최적의 접근 방식입니다. 이 접근 방식의 경우:

1. Claude Haiku 4.5 또는 GPT-5.4 Mini를 선택합니다.
1. 사용 사례를 철저히 테스트합니다.
1. 성능이 요구 사항을 충족하는지 평가합니다.
1. 특정 기능 격차가 있는 경우에만 업그레이드합니다.

다음과 같은 경우에 이 접근 방식을 사용할 수 있습니다.

- 탐색적 또는 대량 작업
- 엄격한 지연 시간 요구 사항이 있는 애플리케이션
- 비용에 민감한 구현

## 문제 해결 {#troubleshooting}

기본값 이외의 모델을 선택할 때 다음과 같은 이슈가 발생할 수 있습니다.

### 모델을 사용할 수 없음 {#model-is-not-available}

GitLab Duo AI 기반 기능에 기본 GitLab 모델을 사용하는 경우, GitLab은 알림 없이 최적 성능과 안정성을 유지하기 위해 기본 모델을 변경할 수 있습니다.

GitLab Duo AI 네이티브 기능에 특정 모델을 직접 선택한 경우, 해당 모델을 사용할 수 없게 되어도 자동 폴백이 이루어지지 않습니다. 이 모델을 사용하는 기능을 사용할 수 없게 됩니다.

### 기본 GitLab Duo 네임스페이스 없음 {#no-default-gitlab-duo-namespace}

선택한 모델로 GitLab Duo 기능을 사용할 때, 기본 GitLab Duo 네임스페이스를 설정해야 한다는 오류가 발생할 수 있습니다.

이 이슈는 여러 GitLab Duo 네임스페이스에 속해 있거나, GitLab 원격이 구성되지 않은 프로젝트에서 로컬로 작업할 때 발생합니다.

이 문제를 해결하려면 [기본 GitLab Duo 네임스페이스를 설정](../profile/preferences.md#set-a-default-gitlab-duo-namespace)하세요.
