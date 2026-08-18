---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 규정 준수 및 거버넌스 목적으로 GitLab Duo AI 에이전트 활동의 통합 기록을 찾아보고 필터링합니다.
title: AI 감사 이벤트 보고서
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.1에서 `agent_artifacts_page` [기능 플래그](../../administration/feature_flags/_index.md)의 [베타](../../policy/development_stages_support.md)로 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/20237)되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 19.2에서 기본적으로 활성화됩니다.

{{< /history >}}

> [!warning]
> 이 기능은 [베타](../../policy/development_stages_support.md) 상태입니다. 예고 없이 변경될 수 있습니다. 자세한 내용은 [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/)를 참조하세요.

AI 감사 이벤트 보고서는 보안 및 규정 준수 팀이 GitLab Duo 에이전트 활동을 통합된 검색 가능한 기록으로 볼 수 있게 합니다. 각 에이전트 세션은 검사할 수 있는 포괄적인 감사 아티팩트를 생성합니다.

## AI 감사 이벤트 보기 {#view-ai-audit-events}

AI 감사 이벤트는 **거버넌스** 페이지의 **감사 이벤트** 탭에서 확인할 수 있습니다.

전제 조건:

- 당신은 최상위 그룹에 대한 Owner 역할을 가집니다.

그룹의 AI 감사 이벤트를 보려면 다음 단계를 따릅니다:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **거버넌스 변경**을 선택합니다.
1. **에이전트 아티팩트** 탭을 선택합니다.

탭에는 에이전트 세션 목록이 표시됩니다. 각 행에는 다음 정보가 표시됩니다:

- 에이전트 유형(워크플로 정의).
- 세션이 실행된 프로젝트.
- 세션의 감사 이벤트 수.
- 세션 시작 시간.

## 세션 필터링 {#filter-sessions}

세션 목록을 필터링하여 결과를 좁힐 수 있습니다:

- **프로젝트**: 프로젝트 경로를 기준으로 필터링하거나 특정 프로젝트를 제외합니다.
- **날짜 범위**: 특정 날짜 이후 또는 이전에 생성된 세션을 필터링합니다.

## 세션 세부 정보 보기 {#view-session-details}

세션 내의 이벤트를 검사하려면 다음 단계를 따릅니다:

1. 세션 행을 선택하여 세션 세부 정보 패널을 엽니다. 패널에는 세션 메타데이터와 감사 이벤트의 시간순 목록이 표시됩니다.
1. 개별 이벤트를 선택하여 엔터티 및 대상 정보를 포함한 전체 세부 정보를 봅니다.

## AI 감사 이벤트 저장소 활성화 {#enable-ai-audit-event-storage}

{{< history >}}

- [GitLab 19.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/603892).

{{< /history >}}

AI 감사 이벤트 저장소는 기본적으로 비활성화됩니다. 에이전트 세션 데이터가 데이터베이스 또는 ClickHouse에 기록되기 전에 저장소를 명시적으로 활성화해야 합니다. 저장소를 비활성화해도 AI 감사 이벤트의 실시간 스트리밍에는 영향을 주지 않습니다.

설정은 인스턴스에서 그룹으로, 그룹에서 프로젝트로 계단식으로 적용됩니다:

- 그룹 수준에서 비활성화되고 잠긴 경우, 해당 그룹의 프로젝트는 이를 재정의할 수 없습니다.
- 그룹 수준에서 활성화되고 잠긴 경우, 해당 그룹의 모든 프로젝트는 저장소가 활성화되어 있으며 비활성화할 수 없습니다.

전제 조건:

- 그룹 또는 프로젝트에 대해 소유자 역할 또는 보안 관리자 역할이 있어야 합니다.

### 그룹의 저장소 활성화 {#enable-storage-for-a-group}

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **Data privacy** 섹션에서 **Enable AI audit event storage**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 프로젝트의 저장소 활성화 {#enable-storage-for-a-project}

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **Data privacy** 섹션에서 **Enable AI audit event storage**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

상위 그룹에서 설정이 잠긴 경우, 확인란이 비활성화되어 있으며 프로젝트 수준에서 변경할 수 없습니다.

## 관련 항목 {#related-topics}

- [GitLab Duo Agent Platform](_index.md)
- [감사 이벤트](../../user/compliance/audit_events.md)
- [감사 이벤트 유형](../../user/compliance/audit_event_types.md)
- [감사 이벤트 보고서](../../administration/compliance/audit_event_reports.md)
