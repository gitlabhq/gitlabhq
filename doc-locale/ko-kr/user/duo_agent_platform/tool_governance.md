---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo 에이전트를 위한 도구 수준 승인 정책을 구성하여 실행 시간에 인적 승인으로 민감한 작업을 제어합니다.
title: 에이전트 도구 거버넌스
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 19.1에서 도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/20466)(괄호 안: [베타](../../policy/development_stages_support.md)), [기능 플래그](../../administration/feature_flags/_index.md) `gitlab_duo_governance_settings`로 명명됨. 기본적으로 비활성화되어 있습니다.

{{< /history >}}

> [!warning]
> 이 기능은 [베타](../../policy/development_stages_support.md) 버전입니다. 통지 없이 변경될 수 있습니다. 자세한 내용은 [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/)을 참조하세요.

도구 거버넌스는 실행 경계에 위치합니다. 에이전트가 프로젝트에 승인된 후 도구가 호출되기 전에 거버넌스 레이어는 사용자의 역할과 도구의 작업 카테고리에 대해 구성된 규칙을 확인한 다음 결과 모드를 적용합니다.

도구는 세 가지 작업 카테고리로 분류됩니다:

- **읽기**: 정보만 검색하거나 표시하는 도구입니다.
- **작성**: 리소스를 생성하거나 수정하는 도구입니다.
- **삭제**: 리소스를 삭제하거나 돌이킬 수 없게 제거하는 도구입니다.

에이전트 도구 거버넌스(인적 개입 가능 보안장치)를 사용하면 관리자가 실행 시점에 각 에이전트 도구를 어떻게 적용할지 정의할 수 있습니다. 에이전트가 검토 없이 모든 도구를 호출하도록 허용하는 대신 각 도구를 세 가지 모드 중 하나로 구성할 수 있습니다:

- **Always Allow**: 도구가 사용자에게 메시지를 표시하지 않고 자동으로 실행됩니다.
- **Always Ask**: 사용자에게 인라인 승인 카드가 표시되고 작업을 진행하기 전에 승인하거나 거부해야 합니다.
- **Always Deny**: 도구가 완전히 차단되며 에이전트에게 보이지 않습니다. 에이전트는 도구를 볼 수 없으며 사용자에게 메시지가 표시되지 않습니다.

이 기능은 Agentic Chat, IDE 확장 프로그램 및 플로우에 전체 적용됩니다.

## 기본 거버넌스 행렬 {#default-governance-matrix}

| 분류 | 모드 |
|------|------|
| 읽기 | 항상 허용 |
| 작성 | 항상 확인 |
| 삭제 | 항상 확인 |

### 승인 프롬프트 (항상 확인) {#approval-prompt-always-ask}

에이전트가 **Always Ask**으로 구성된 도구를 호출하면 실행이 일시 중지되고 인라인 승인 카드가 표시됩니다. 카드에는 다음이 표시됩니다:

- 호출 중인 도구의 이름입니다.
- 도구가 수행할 작업에 대한 설명입니다.
- **승인** 및 **거부** 버튼입니다.

승인하면 도구가 실행되고 에이전트는 계속됩니다. 거부하면 도구가 실행되지 않습니다. 에이전트는 거부 신호를 받으며 대체 방식을 시도하거나 중지할 수 있습니다.

### 거부 메시지 (항상 거부) {#denial-message-always-deny}

에이전트가 사용자 역할에 대해 **Always Deny**로 구성된 도구를 호출하려고 하면 도구가 에이전트에게 표시되지 않습니다. 에이전트의 계획이 거부된 도구를 필요로 하는 경우 거버넌스 정책으로 인해 도구를 사용할 수 없음을 나타내는 오류가 표시됩니다.

## 규칙 해석 및 계단식 처리 {#rule-resolution-and-cascading}

규칙은 가장 구체적인 것부터 가장 구체적이지 않은 순서로 해석됩니다:

1. 프로젝트 수준의 규칙 (구성된 경우).
1. 그룹 수준의 규칙 (구성된 경우).
1. 기본 행렬 값입니다.

프로젝트 수준의 규칙은 동일한 도구에 대한 그룹 수준의 규칙을 재정의하지만 그룹 수준의 규칙과 동일하거나 더 엄격해야 합니다. 그룹 수준의 규칙은 기본값을 재정의합니다. 어느 수준에서도 규칙이 구성되지 않은 경우 도구는 기본적으로 항상 허용으로 설정됩니다.

fail-closed 원칙이 적용됩니다. 거버넌스 서비스가 규칙을 해석할 때 지속적인 오류를 만나면 에이전트는 자동으로 실행을 허용하지 않고 도구를 받지 않습니다.

## 그룹의 도구 거버넌스 구성 {#configure-tool-governance-for-a-group}

그룹 수준의 규칙은 프로젝트 수준에서 재정의되지 않는 한 그룹의 모든 프로젝트에 적용됩니다.

전제 조건:

- 최상위 그룹에 대한 소유자 역할이 있습니다.

그룹의 도구 거버넌스 규칙을 구성하려면:

1. 상단 바에서 **Search or go to**를 선택하고 최상위 그룹을 찾습니다.
1. **Settings** > **GitLab Duo**를 선택합니다.
1. **거버넌스 변경**을 선택합니다.
1. 각 도구에 대해 **모드** 드롭다운 목록에서 모드를 선택합니다: **Always Allow**, **Always Ask**, 또는 **Always Deny**.
1. **변경사항 저장**을 선택합니다.

변경 사항은 프로젝트 수준의 재정의가 없는 모든 하위 그룹 및 프로젝트에 적용됩니다.

## 프로젝트의 도구 거버넌스 구성 {#configure-tool-governance-for-a-project}

프로젝트 수준의 규칙은 그 프로젝트 내의 동일한 도구에 대한 그룹 수준의 규칙을 재정의합니다.

전제 조건:

- 프로젝트의 Maintainer 또는 Owner 역할이 있습니다.

프로젝트의 도구 거버넌스 규칙을 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **Settings** > **GitLab Duo**를 선택합니다.
1. **거버넌스 변경**을 선택합니다.
1. 각 도구에 대해 드롭다운에서 모드를 선택합니다: **Always Allow**, **Always Ask**, 또는 **Always Deny**.
1. **변경사항 저장**을 선택합니다.

## 관련 항목 {#related-topics}

- [GitLab Duo Agent Platform 가용성 제어](turn_on_off.md)
- [GitLab Duo Agent Platform](_index.md)
- [감사 이벤트](../../administration/compliance/audit_event_reports.md)
