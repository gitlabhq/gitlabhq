---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 규정 준수 및 거버넌스 목적으로 GitLab Duo AI 에이전트 활동의 통합 기록을 찾아보고 필터링합니다.
title: AI 감사 이벤트
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.1에서 `agent_artifacts_page` [기능 플래그](../../administration/feature_flags/_index.md)의 [베타](../../policy/development_stages_support.md)로 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/20237)되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 19.2에서 기본적으로 활성화되었습니다.

{{< /history >}}

> [!warning]
> 이 기능은 [베타](../../policy/development_stages_support.md) 상태입니다. 예고 없이 변경될 수 있습니다. 자세한 내용은 [GitLab 테스팅 계약](https://handbook.gitlab.com/handbook/legal/testing-agreement/)을 참조하세요.

AI 감사 이벤트 보고서를 사용하여 GitLab Duo 에이전트 활동의 통합되고 검색 가능한 기록을 확인합니다. 각 에이전트 세션은 검사할 수 있는 포괄적인 감사 아티팩트를 생성합니다.

AI 감사 이벤트는 [GitLab AI Gateway](../../administration/gitlab_duo/gateway.md)에서 생성됩니다. 에이전트 세션:

- GitLab.com의 세션은 GitLab.com에서 호스팅하는 AI Gateway를 통해 라우팅되며, AI 감사 이벤트를 GitLab.com으로 전달합니다.
- GitLab Self-Managed의 세션은 GitLab.com에서 호스팅하는 AI Gateway 또는 자체 관리되는 [AI Gateway](../../install/install_ai_gateway.md)를 통해 라우팅될 수 있습니다. 자신의 AI Gateway를 관리하는 경우 AI 감사 이벤트를 GitLab 인스턴스로 전달하도록 구성해야 합니다. 그렇지 않으면 대시보드에 이벤트가 기록되지 않습니다.

## AI 감사 이벤트 보기 {#view-ai-audit-events}

AI 감사 이벤트는 **거버넌스** 페이지의 **감사 이벤트** 탭에서 확인할 수 있습니다.

전제 조건:

- 당신은 최상위 그룹에 대한 Owner 역할을 가집니다.

그룹의 AI 감사 이벤트를 보려면 다음 단계를 따릅니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **거버넌스 변경**을 선택합니다.
1. **에이전트 아티팩트** 탭을 선택합니다.

탭에는 에이전트 세션 목록이 표시됩니다. 각 행에는 다음 정보가 표시됩니다.

- 에이전트 유형(워크플로 정의).
- 세션이 실행된 프로젝트.
- 세션의 감사 이벤트 수.
- 세션 시작 시간.

## 세션 필터링 {#filter-sessions}

세션 목록을 필터링하여 결과를 좁힐 수 있습니다.

- **프로젝트**: 프로젝트 경로를 기준으로 필터링하거나 특정 프로젝트를 제외합니다.
- **날짜 범위**: 특정 날짜 이후 또는 이전에 생성된 세션을 필터링합니다.
- **트리거 됨**: 세션을 트리거한 사용자로 필터링하거나 특정 사용자를 제외합니다.

## 세션 세부 정보 보기 {#view-session-details}

세션 내의 이벤트를 검사하려면 다음 단계를 따릅니다.

1. 세션 행을 선택하여 세션 세부 정보 패널을 엽니다. 패널에는 세션 메타데이터와 감사 이벤트의 시간순 목록이 표시됩니다.
1. 개별 이벤트를 선택하여 엔터티 및 대상 정보를 포함한 전체 세부 정보를 봅니다.

## AI 감사 이벤트 저장소 활성화 {#enable-ai-audit-event-storage}

{{< history >}}

- GitLab 19.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/603892)되었습니다.

{{< /history >}}

AI 감사 이벤트 저장소는 기본적으로 비활성화됩니다. 에이전트 세션 데이터가 데이터베이스 또는 ClickHouse에 기록되기 전에 저장소를 명시적으로 활성화해야 합니다. 저장소를 비활성화해도 AI 감사 이벤트의 실시간 스트리밍에는 영향을 주지 않습니다.

설정은 인스턴스에서 그룹으로, 그룹에서 프로젝트로 계단식으로 적용됩니다.

- 그룹 수준에서 비활성화되고 잠긴 경우, 해당 그룹의 프로젝트는 이를 재정의할 수 없습니다.
- 그룹 수준에서 활성화되고 잠긴 경우, 해당 그룹의 모든 프로젝트는 저장소가 활성화되어 있으며 비활성화할 수 없습니다.

전제 조건:

- 그룹 또는 프로젝트에 대해 Owner 역할 또는 Security Manager 역할이 있어야 합니다.

### 그룹의 저장소 활성화 {#enable-storage-for-a-group}

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **데이터와 개인정보 보호** 섹션에서 **AI 감사 이벤트**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 프로젝트의 저장소 활성화 {#enable-storage-for-a-project}

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **설정** > **일반**을 선택합니다.
1. **GitLab Duo** 섹션을 확장합니다.
1. **AI 감사 이벤트** 토글을 켭니다.
1. **변경 사항 저장**을 선택합니다.

상위 그룹에서 설정이 잠겨있는 경우 컨트롤이 비활성화되고 프로젝트 수준에서 변경할 수 없습니다.

## 복합 ID를 사용한 이벤트 귀속 {#event-attribution-with-composite-identity}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247149)되었습니다.

{{< /history >}}

에이전트 세션이 [복합 ID](../duo_agent_platform/composite_identity.md)로 실행될 때(에이전트 세션의 기본 ID), 세션의 AI 감사 이벤트는 서비스 계정에 귀속됩니다. `author_id` 필드는 서비스 계정의 사용자 ID를 포함하며, 서비스 계정은 이벤트 작성자로 표시됩니다.

이벤트 `details` 필드는 세션을 시작한 실제 사용자를 기록합니다:

| 필드                   | 설명                |
|-------------------------|----------------------------|
| `human_author_id`       | 실제 사용자의 사용자 ID  |
| `human_author_name`     | 실제 사용자의 이름     |
| `human_author_username` | 실제 사용자의 사용자 이름 |

세션이 실제 사용자 자신의 토큰으로 인증될 때 실제 사용자는 이벤트 작성자이며 `human_author_*` 필드는 추가되지 않습니다.

## 관련 항목 {#related-topics}

- [AI Governance](_index.md)
- [AI Governance Dashboard](governance-dashboard.md)
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
- [감사 이벤트](../compliance/audit_events.md)
- [감사 이벤트 유형](../compliance/audit_event_types.md)
- [감사 이벤트 보고서](../../administration/compliance/audit_event_reports.md)
