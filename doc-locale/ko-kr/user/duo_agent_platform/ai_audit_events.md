---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Duo 에이전트 활동의 통합 기록을 검색, 필터링 및 다운로드하여 규정 준수 및 거버넌스 목적으로 사용합니다."
title: AI 감사 이벤트 보고서
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 19.1에서 도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/20237)(괄호 안: [베타](../../policy/development_stages_support.md)), [기능 플래그](../../administration/feature_flags/_index.md) `agent_artifacts_page`로 명명됨. 기본적으로 비활성화되어 있습니다.

{{< /history >}}

> [!warning]
> 이 기능은 [베타](../../policy/development_stages_support.md) 버전입니다. 통지 없이 변경될 수 있습니다. 자세한 내용은 [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/)을 참조하세요.

AI 감사 이벤트 보고서는 보안 및 규정 준수 팀에 GitLab Duo 에이전트 활동의 통합되고 검색 가능한 기록을 제공합니다. 각 에이전트 세션은 검사하고 다운로드할 수 있는 포괄적인 감사 아티팩트를 생성합니다.

## AI 감사 이벤트 보기 {#view-ai-audit-events}

AI 감사 이벤트는 **거버넌스** 페이지의 **에이전트 아티팩트** 탭에서 사용할 수 있습니다.

전제 조건:

- 최상위 그룹에 대한 소유자 역할이 있습니다.

그룹의 AI 감사 이벤트를 보려면:

1. 상단 바에서 **Search or go to**를 선택하고 최상위 그룹을 찾습니다.
1. **Settings** > **GitLab Duo**를 선택합니다.
1. **거버넌스 변경**을 선택합니다.
1. **에이전트 아티팩트** 탭을 선택합니다.

탭은 에이전트 세션의 목록을 표시합니다. 각 행에는 다음이 표시됩니다:

- 에이전트 유형(워크플로 정의).
- 세션이 실행된 프로젝트.
- 세션의 감사 이벤트 수.
- 세션 시작 시간.

## 세션 필터링 {#filter-sessions}

세션 목록을 필터링하여 결과를 좁힐 수 있습니다:

- **에이전트**: 워크플로 정의 이름별로 필터링하거나 특정 에이전트를 제외합니다.
- **프로젝트**: 프로젝트 경로별로 필터링하거나 특정 프로젝트를 제외합니다.
- **날짜 범위**: 특정 날짜 이후 또는 이전에 생성된 세션을 필터링합니다.

## 세션 세부 정보 보기 {#view-session-details}

세션 내의 이벤트를 검사하려면:

1. 세션 행을 선택하여 세션 세부 정보 패널을 엽니다. 패널은 세션 메타데이터와 감사 이벤트의 시간순 목록을 표시합니다.
1. 개별 이벤트를 선택하여 엔티티 및 대상 정보를 포함한 전체 세부 정보를 봅니다.

## 세션 아티팩트 다운로드 {#download-a-session-artifact}

각 세션에는 해당 세션의 완전한 감사 기록을 포함하는 다운로드 가능한 JSON 아티팩트가 있습니다.

세션 아티팩트를 다운로드하려면 다운로드할 세션의 세션 세부 정보 패널을 엽니다.

아티팩트는 JSON 문서입니다. 오프라인 분석, 장기 보존 또는 외부 규정 준수 도구와의 통합에 사용할 수 있습니다.

## 관련 항목 {#related-topics}

- [GitLab Duo Agent Platform](_index.md)
- [감사 이벤트](../../administration/compliance/audit_event_reports.md)
