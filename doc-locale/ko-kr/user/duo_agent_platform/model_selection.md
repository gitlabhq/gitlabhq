---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo 기능을 위한 대규모 언어 모델을 구성합니다.
title: 에이전트 플랫폼 AI 모델
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

모든 GitLab Duo 기능은 기본 모델을 사용합니다. GitLab은 성능을 최적화하기 위해 기본 모델을 업데이트할 수 있습니다. 일부 기능의 경우, 다른 모델을 선택할 수 있으며, 변경할 때까지 유지됩니다.

## 기본 모델 {#default-models}

이 표는 에이전트 플랫폼의 각 기능에 대한 기본 모델을 나열합니다.

| 기능 | 모델 |
|-------|--------------|
| GitLab Duo 에이전트 모드 채팅 | Claude Sonnet 4.6 Vertex |
| Code Review 플로우 | Claude Sonnet 4.6 Vertex |
| 기타 모든 에이전트 | Claude Sonnet 4.5 Vertex |

## 지원되는 모델 {#supported-models}

이 표는 에이전트 플랫폼의 기능에 대해 선택할 수 있는 모델을 나열합니다.

| 모델                | GitLab Duo 에이전트 모드 채팅 | Code Review 플로우 | 기타 모든 에이전트 |
|----------------------|-------------------------|------------------|------------------|
| Claude Sonnet 4      | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Sonnet 4.5    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Sonnet 4.6    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Haiku 4.5     | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.5      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.6      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.7      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5                | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.1              | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2              | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.5 <sup>1</sup> | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5 Codex          | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2 Codex        | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.3 Codex        | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5 Mini           | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Mini         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Nano         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |

**각주**:

1. 이 모델은 [제한된 공급업체 측 데이터 보존](../gitlab_duo/data_usage.md#data-retention)의 적용을 받습니다.

## 기능을 위한 모델 선택 {#select-a-model-for-a-feature}

{{< details >}}

- 제공:  GitLab.com

{{< /details >}}

{{< history >}}

- [GitLab 18.1에서 최상위 그룹을 위해 도입되었습니다](https://gitlab.com/groups/gitlab-org/-/epics/17570) . [플래그](../../administration/feature_flags/_index.md) `ai_model_switching`를 사용합니다. 기본적으로 비활성화됨.
- GitLab 18.4에서 베타로 [변경되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/526307).
- [활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)은 GitLab 18.4입니다.
- [GitLab 18.4에서 GitLab Duo 에이전트 플랫폼을 위한 모델 선택이 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/568112) . [플래그](../../administration/feature_flags/_index.md) `duo_agent_platform_model_selection`를 사용합니다. 기본적으로 비활성화됨.
- GitLab 18.5에서 [일반적으로 사용 가능합니다](https://gitlab.com/groups/gitlab-org/-/epics/18818). 기능 플래그 `ai_model_switching`가 활성화되었습니다.
- 기능 플래그 `duo_agent_platform_model_selection`가 GitLab 18.6에서 [활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212051).
- 기능 플래그 `ai_model_switching` [제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) GitLab 18.7에서.
- 기능 플래그 `duo_agent_platform_model_selection`이 GitLab 18.9에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/218591)되었습니다.
- LLM이 GitLab 19.1에서 Code Review 플로우를 위해 Claude Sonnet 4.6 Vertex로 [업데이트되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876).
- [GitLab Duo 코드 검토에서 모델 선택을 분리](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876)하여 GitLab 19.1에서 Code Review 플로우를 위해 도입되었습니다. **Agentic Code Review** 설정을 사용합니다.

{{< /history >}}

최상위 그룹의 기능에 대한 모델을 선택할 수 있습니다. 선택한 모델은 모든 하위 그룹 및 프로젝트의 해당 기능에 적용됩니다.

전제 조건:

- 그룹에 대한 소유자 역할을 가지고 있습니다.
- 모델을 선택하는 그룹은 최상위 그룹입니다.
- GitLab 18.3 이상인 경우, 여러 GitLab Duo 네임스페이스에 속하면 [기본 네임스페이스를 할당](../profile/preferences.md#set-a-default-gitlab-duo-namespace)해야 합니다.

기능에 대한 모델을 선택하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **기능 구성**을 선택합니다.
1. **GitLab Duo 에이전트 플랫폼** 섹션으로 이동합니다.
1. 드롭다운 목록에서 모델을 선택합니다.
1. 선택사항. 섹션의 모든 기능에 모델을 적용하려면 **모두에 적용**을 선택합니다.

IDE에서 GitLab Duo 에이전트 채팅을 위한 모델 선택은 연결 유형이 WebSocket으로 설정된 경우에만 적용됩니다.

GitLab Duo CLI를 위한 모델을 지정하려면 [모델 선택](../gitlab_duo_cli/_index.md#select-a-model)을 참조하세요.

## 문제 해결 {#troubleshooting}

기본값 이외의 모델을 선택할 때 다음 이슈가 발생할 수 있습니다.

### 모델을 사용할 수 없음 {#model-is-not-available}

GitLab Duo AI 기반 기능에 대해 기본 GitLab 모델을 사용 중이면 GitLab은 최적 성능 및 안정성을 유지하기 위해 사용자에게 알리지 않고 기본 모델을 변경할 수 있습니다.

GitLab Duo AI 기반 기능에 대해 특정 모델을 선택했으며 해당 모델을 사용할 수 없으면 자동 폴백이 없습니다. 이 모델을 사용하는 기능을 사용할 수 없습니다.

### 기본 GitLab Duo 네임스페이스 없음 {#no-default-gitlab-duo-namespace}

선택한 모델을 사용하여 GitLab Duo 기능을 사용할 때 기본 GitLab Duo 네임스페이스를 설정해야 함을 나타내는 오류가 발생할 수 있습니다.

이 이슈는 여러 GitLab Duo 네임스페이스에 속하거나 GitLab 원격이 구성되지 않은 프로젝트에서 로컬로 작업할 때 발생합니다.

이를 해결하려면 [기본 GitLab Duo 네임스페이스 설정](../profile/preferences.md#set-a-default-gitlab-duo-namespace)을 하세요.
