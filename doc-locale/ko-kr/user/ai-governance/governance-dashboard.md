---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "조직 전체에서 AI 에이전트 세션, 감사 로그 및 개발자 노출 현황을 중앙 대시보드에서 모니터링합니다."
title: AI Governance Dashboard
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com
- 상태:  제한적 출시

{{< /details >}}

{{< history >}}

- [GitLab 19.4에서 소개](https://gitlab.com/gitlab-org/gitlab/-/work_items/603776)되었으며, [베타](../../policy/development_stages_support.md) 버전으로 [기능 플래그](../../administration/feature_flags/_index.md) `ai_governance_dashboard`를 포함합니다. 기본적으로 사용으로 설정됩니다.

{{< /history >}}

> [!warning]
> 이 기능은 [베타](../../policy/development_stages_support.md) 상태입니다. 예고 없이 변경될 수 있습니다. 자세한 내용은 [GitLab 테스팅 계약](https://handbook.gitlab.com/handbook/legal/testing-agreement/)을 참조하세요.

보안 및 규정 준수 팀은 AI 거버넌스 대시보드를 사용하여 그룹 전체에서 AI 에이전트 활동을 모니터링할 수 있습니다. AI 거버넌스 대시보드는 다음을 시각화하는 핵심 성과 지표 및 데이터 카드를 표시합니다:

- AI 에이전트의 사용 방식
- 가장 활동적인 개발자
- 노출 현황이 가장 높은 프로젝트

대시보드는 GitLab Duo Agent Platform(DAP) 에이전트의 데이터만 표시하며, 지난 7일로 범위가 제한됩니다.

## 사전 요구 사항 {#prerequisites}

- 최상위 그룹의 소유자 역할이 있거나 `read_agent_artifacts` 기능을 가진 사용자 지정 역할이 있어야 합니다.
- `ai_governance_dashboard` 기능 플래그가 그룹에 대해 활성화되어 있어야 합니다.

## 대시보드 보기 {#view-the-dashboard}

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **거버넌스 변경**을 선택합니다.
1. **대시보드** 탭을 선택합니다.

## 핵심 성과 지표(KPI) 타일 {#key-performance-indicator-kpi-tiles}

대시보드 헤더는 두 개의 KPI 타일을 표시합니다. 각 타일은 지난 7일 동안의 개수와 해당 기간의 일일 추이를 보여주는 스파크라인을 표시합니다.

### AI 에이전트 {#ai-agents}

**AI 에이전트** 타일은 지난 7일 동안의 고유한 활성 에이전트 인스턴스의 수를 표시합니다. 에이전트 인스턴스는 사용자, 프로젝트, 네임스페이스, 에이전트 유형 및 환경별로 고유합니다. Duo Chat 대화는 이 개수에서 제외됩니다.

### AI 세션 {#ai-sessions}

**AI 세션** 타일은 지난 7일 동안의 에이전트 워크플로우 세션의 총 수를 표시합니다. 여기에는 모든 DAP 워크플로우 유형이 포함됩니다: IDE, 웹, 채팅 및 앰비언트 세션 Duo Chat이 포함됩니다.

## 데이터 카드 {#data-cards}

KPI 타일 아래의 데이터 카드는 에이전트 활동의 분석을 제공합니다.

### 감사 로그 {#audit-logs}

**감사 로그** 카드는 [AI 감사 이벤트 보고서](ai-audit-events.md)로 연결되며, 여기서 에이전트 세션 이벤트의 전체 기록을 검색, 필터링 및 다운로드할 수 있습니다. 대시보드에서 적용된 필터는 감사 이벤트 탭으로 전달됩니다.

### AI 에이전트 인벤토리 {#ai-agent-inventory}

**AI 에이전트 인벤토리** 카드는 그룹에서 활성 상태인 DAP 에이전트를 프로젝트별로 분류하여 나열합니다. 사용 현황별로 에이전트를 정렬하여 가장 자주 호출되는 에이전트를 확인할 수 있습니다.

### 개발자 활동 {#developer-activity}

**개발자 활동** 카드는 지난 7일 동안 에이전트 세션 수로 상위 사용자를 표시합니다. 이를 사용하여 AI 에이전트를 가장 적극적으로 사용하는 개발자를 파악할 수 있습니다.

### 프로젝트 노출 {#project-exposure}

**프로젝트 노출** 카드는 지난 7일 동안 에이전트 세션 수로 상위 프로젝트를 표시합니다. 이를 사용하여 AI 에이전트 활동 볼륨이 가장 높은 프로젝트를 확인할 수 있습니다.

### MCP 서버 {#mcp-servers}

**MCP 서버** 카드는 그룹에 등록된 Model Context Protocol(MCP) 서버의 상태를 함께 나열합니다. 이를 사용하여 에이전트가 도달할 수 있는 외부 MCP 서버를 확인할 수 있습니다.

서버의 전체 설명을 읽으려면 잘린 설명 텍스트에 마우스를 올리거나 포커스를 맞춥니다.

카드는 등록된 서버만 나열합니다. 각 서버 사용 빈도는 표시하지 않습니다.

## 관련 항목 {#related-topics}

- [AI Governance](_index.md)
- [Tool governance](tool-governance.md)
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
