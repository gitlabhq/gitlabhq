---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AI 에이전트를 위한 도구 수준 승인 정책을 구성하여 실행 시 민감한 작업을 인간 승인으로 제어합니다.
title: 에이전트 도구 거버넌스
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.1에서 `gitlab_duo_governance_settings` [기능 플래그](../../administration/feature_flags/_index.md)의 [베타](../../policy/development_stages_support.md)로 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/20466)되었습니다. 기본적으로 사용으로 설정됩니다.
- Duo Developer 기본 플로우와 같은 백그라운드 플로우에 대한 적용이 GitLab 19.3에서 [기능 플래그](../../administration/feature_flags/_index.md) `duo_workflow_background_tool_governance`로 추가되었습니다. 기본적으로 사용 중지됩니다.
- 기능 플래그 `gitlab_duo_governance_settings`이(가) GitLab 19.4에서 제거되었습니다.

{{< /history >}}

> [!warning]
> 이 기능은 [베타](../../policy/development_stages_support.md) 상태입니다. 예고 없이 변경될 수 있습니다. 자세한 내용은 [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/)를 참조하세요.

도구 거버넌스는 실행 경계에 있습니다. 에이전트가 프로젝트에 허용된 후 도구가 호출되기 전에 거버넌스 계층은 사용자의 역할과 도구의 작업 범주에 대해 구성된 규칙을 확인한 다음 결과 모드를 적용합니다.

> [!flag]
> 백그라운드 플로우에 대한 적용은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

도구는 세 가지 작업 범주로 분류됩니다.

- **읽기**: 정보만 검색하거나 표시하는 도구입니다.
- **작성**: 리소스를 생성하거나 수정하는 도구입니다.
- **삭제**: 리소스를 삭제하거나 되돌릴 수 없게 제거하는 도구입니다.

에이전트 도구 거버넌스(인간 개입 보호장치)를 사용하면 관리자는 실행 시점에 각 에이전트 도구를 어떻게 적용할 것인지 정의할 수 있습니다. 검토 없이 에이전트가 도구를 호출하도록 허용하는 대신 각 도구를 세 가지 모드 중 하나로 구성할 수 있습니다.

- **항상 허용**: 도구가 사용자에게 메시지를 표시하지 않고 조용히 실행됩니다.
- **항상 묻기**: 사용자에게 인라인 승인 카드가 표시되고 작업이 진행되기 전에 승인하거나 거부해야 합니다.
- **항상 거부**: 도구는 완전히 차단되며 에이전트에 표시되지 않습니다. 에이전트는 도구를 보지 못하고 사용자도 메시지를 받지 않습니다.

이 기능은 에이전틱 채팅 및 IDE 확장에 적용됩니다. 플로우의 경우 거버넌스 적용은 플로우가 실행되는 위치에 따라 달라집니다:

- IDE 확장에서 실행되는 플로우의 경우 GitLab이 거버넌스 규칙을 적용합니다.
- Duo Developer 기본 플로우와 같은 백그라운드 플로우의 경우 GitLab이 거버넌스 규칙을 적용합니다.

## 기본 거버넌스 매트릭스 {#default-governance-matrix}

| 분류 | 모드 |
|------|------|
| 읽기(GitLab 리소스) | 항상 허용 |
| 읽기(로컬 파일) | 항상 요청 |
| 작성 | 항상 요청 |
| 삭제 | 항상 요청 |

### GitLab MCP 서버 도구 {#gitlab-mcp-server-tools}

{{< history >}}

- GitLab 19.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/606073)되었으며 [기능 플래그](../../administration/feature_flags/_index.md) `duo_mcp_tool_governance`로 제공됩니다. 기본적으로 사용 중지됩니다.
- [GitLab.com, GitLab Self-Managed, GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/work_items/607499)되었으며 GitLab 19.4입니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능성은 기능 플래그로 제어합니다. 자세한 내용은 기록을 참조하세요.

GitLab MCP 서버에서 노출된 도구는 **도구 관리** 탭에 `mcp` 소스로 표시되며, GitLab Duo 에이전트 플랫폼 도구와 함께 표시됩니다. [그룹에 대한 도구 거버넌스 구성](#configure-tool-governance-for-a-group)에 설명된 대로 동일한 방식으로 이들에 대한 모드를 설정합니다.

각 도구는 선언한 주석을 기반으로 작업 범주로 분류됩니다. 업데이트할 유지 관리 목록이 없으므로 새로 추가된 MCP 도구는 자동으로 제어됩니다:

| 도구 선언 | 범주 |
|---|---|
| `destructiveHint: true` | 삭제 |
| `readOnlyHint: true` | 읽기 |
| `readOnlyHint: false` | 작성 |
| 주석 없음 | 삭제 |

`destructiveHint: true`과 `readOnlyHint: true`을(를) 모두 선언하는 도구는 삭제로 분류됩니다. 범주는 표시된 순서대로 해결되므로 가장 제한적인 선언이 우선됩니다. 탭의 도구는 GitLab 버전, 라이선스 및 활성화된 기능에 따라 다르므로 MCP 서버가 노출하는 도구를 결정합니다.

많은 기능이 GitLab Duo 에이전트 플랫폼 도구 및 MCP 서버 도구로 존재합니다. 두 도구의 이름이 다르더라도 하나의 모드가 둘 다 제어합니다. 예를 들어 `create_merge_request`에 대한 모드를 설정하면 MCP 서버 도구 `save_merge_request`에도 적용됩니다. GitLab Duo 에이전트 플랫폼 도구에서 모드를 설정합니다. MCP 서버 도구를 별도로 찾아 설정할 필요는 없습니다.

모드를 설정하지 않으면 동작은 변경되지 않습니다. 읽기 전용 MCP 도구는 사전 승인 상태로 유지됩니다. 쓰기 및 삭제 MCP 도구는 여전히 승인을 위한 프롬프트를 표시합니다.

### 승인 프롬프트(항상 묻기) {#approval-prompt-always-ask}

에이전트가 **항상 묻기**로 구성된 도구를 호출하면 실행이 일시 중지되고 인라인 승인 카드가 표시됩니다. 카드에는 다음이 표시됩니다.

- 호출되는 도구의 이름입니다.
- 도구가 수행할 작업에 대한 설명입니다.
- **승인** 및 **거부** 버튼입니다.

승인하면 도구가 실행되고 에이전트가 계속됩니다. 거부하면 도구가 실행되지 않습니다. 에이전트는 거부 신호를 받고 다른 방법을 시도하거나 중지할 수 있습니다.

### 거부 메시지(항상 거부) {#denial-message-always-deny}

에이전트가 당신의 역할에 대해 **항상 거부**로 구성된 도구를 호출하려고 하면 도구는 에이전트에 표시되지 않습니다. 에이전트의 계획에 거부된 도구가 필요한 경우 거버넌스 정책으로 인해 도구를 사용할 수 없다는 오류를 받습니다.

## 규칙 해결 및 계단식 {#rule-resolution-and-cascading}

규칙은 가장 구체적인 것부터 가장 일반적인 것 순서로 해결됩니다.

1. 프로젝트 수준 규칙(구성된 경우)입니다.
1. 그룹 수준 규칙(구성된 경우)입니다.
1. 기본 매트릭스 값입니다.

프로젝트 수준 규칙은 동일한 도구에 대한 그룹 수준 규칙을 재정의하지만 그룹 수준 규칙과 같거나 더 엄격할 수만 있습니다. 그룹 수준 규칙은 기본값을 재정의합니다. 어떤 수준에서도 규칙이 구성되지 않으면 도구는 기본 거버넌스 매트릭스 값을 사용합니다.

실패 폐쇄 원칙이 적용됩니다. 거버넌스 서비스가 규칙을 해결할 때 지속적 오류가 발생하면 에이전트는 조용히 실행을 허용하는 것보다는 도구를 받지 않습니다.

## 그룹에 대한 도구 거버넌스 구성 {#configure-tool-governance-for-a-group}

그룹 수준 규칙은 프로젝트 수준에서 재정의되지 않는 한 그룹의 모든 프로젝트에 적용됩니다.

사전 요구 사항:

- 당신은 최상위 그룹에 대한 Owner 역할을 가집니다.

그룹에 대한 도구 거버넌스 규칙을 구성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **거버넌스 변경**을 선택합니다.
1. 각 도구에 대해 **모드** 드롭다운 목록에서 모드를 선택합니다. **항상 허용**, **항상 묻기** 또는 **항상 거부**.
1. **변경 사항 저장**을 선택합니다.

변경 사항은 프로젝트 수준 재정의가 없는 모든 하위 그룹 및 프로젝트에 적용됩니다.

## 프로젝트에 대한 도구 거버넌스 구성 {#configure-tool-governance-for-a-project}

프로젝트 수준 규칙은 해당 프로젝트 내에서 동일한 도구에 대한 그룹 수준 규칙을 재정의합니다.

사전 요구 사항:

- 당신은 프로젝트에 대한 Maintainer 또는 Owner 역할을 가집니다.

프로젝트에 대한 도구 거버넌스 규칙을 구성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **거버넌스 변경**을 선택합니다.
1. 각 도구에 대해 드롭다운에서 모드를 선택합니다. **항상 허용**, **항상 묻기** 또는 **항상 거부**.
1. **변경 사항 저장**을 선택합니다.

## Model Context Protocol(MCP) 서버 차단 {#block-model-context-protocol-mcp-servers}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/601159)되었으며 [베타](../../policy/development_stages_support.md)로 [기능 플래그](../../administration/feature_flags/_index.md) `mcp_server_block_enforcement`로 제공됩니다. 기본적으로 사용 중지됩니다.
- GitLab 19.4에서 GitLab Self-Managed 및 GitLab Dedicated에 대해 적용이 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251329)되었으며, 세션의 도구 구성이 구축될 때 적용됩니다. 기본적으로 사용으로 설정됩니다.
- GitLab.com, GitLab Self-Managed, GitLab Dedicated에서 GitLab 19.4에 활성화되었습니다.

{{< /history >}}

> [!warning]
> 이 기능은 [베타](../../policy/development_stages_support.md) 상태입니다. 예고 없이 변경될 수 있습니다. 자세한 내용은 [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/)를 참조하세요.

[도구별 거버넌스](#default-governance-matrix)에 추가로 그룹 소유자는 특정 외부 MCP 서버의 모든 도구를 차단할 수 있습니다. MCP 서버가 차단되면 개별 도구 거버넌스 설정이나 사용자 승인에 관계없이 해당 서버의 도구를 호출할 수 없습니다.

> [!flag]
> MCP 서버 차단의 적용은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

인스턴스에서 적용이 활성화되지 않으면 MCP 레지스트리는 여전히 서버가 차단된 것으로 표시합니다. 차단 자체는 적용되지 않으므로 서버의 도구는 GitLab Duo 에이전틱 채팅에서 계속 사용 가능합니다.

차단은 채팅 세션의 도구가 어셈블될 때 적용되며, 이는 모든 사용자 메시지, 도구 승인 및 새 세션에서 발생합니다. 실제로는 차단이 사용자의 다음 작업에서 적용됩니다. 차단이 도착할 때 승인 대기 중인 도구 호출은 실행되지 않으며, 다음 메시지부터는 차단된 서버의 도구가 에이전트에 제공되지 않습니다. 이미 실행 중인 도구 호출은 완료됩니다.

도구가 거부되지 않고 자동으로 제거되므로 에이전트는 정책 메시지를 받지 않습니다. 에이전트는 누락된 도구를 자신의 말로 설명하며, 서버가 다시 허용된 후 기존 대화의 에이전트는 이전 대화를 기반으로 서버가 여전히 차단되었다고 주장할 수 있습니다. 새 대화를 시작하거나 에이전트에 도구를 다시 시도하도록 요청합니다.

차단은 UI의 GitLab Duo 에이전틱 채팅에 적용됩니다. IDE 및 CLI 클라이언트는 로컬 구성 파일을 통해 MCP 서버를 구성하며, 이 설정은 제어하지 않습니다.

이는 **항상 거부** 도구 거버넌스 모드와 다릅니다:

- **항상 거부**는 개별 도구에 적용되며 프로젝트 또는 그룹별로 구성됩니다.
- MCP 서버를 차단하면 해당 서버의 모든 도구에 적용되며 MCP 레지스트리에서 구성됩니다. 모든 사용자 승인 또는 도구 거버넌스 설정을 재정의합니다.

### MCP 서버 차단 {#block-an-mcp-server}

MCP 서버를 그룹 또는 프로젝트 수준에서 차단할 수 있습니다:

- **그룹 수준**: 그룹의 모든 프로젝트 및 해당 하위 그룹에 대해 서버를 차단합니다. 그룹 수준에서 서버가 차단되면 프로젝트 수준 설정으로 차단을 해제할 수 없습니다.
- **프로젝트 수준**: 해당 프로젝트에 대해서만 서버를 차단합니다.

#### 그룹에 대해 MCP 서버 차단 {#block-an-mcp-server-for-a-group}

사전 요구 사항:

- 당신은 최상위 그룹에 대한 Owner 역할을 가집니다.

그룹에 대해 MCP 서버를 차단하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **거버넌스 변경**을 선택합니다.
1. **MCP 레지스트리** 탭을 선택합니다.
1. 차단하려는 MCP 서버를 찾아 **차단**을 선택합니다.

차단은 각 사용자의 다음 메시지 또는 새 채팅 세션부터 적용됩니다. 차단된 서버의 도구는 그룹 및 해당 하위 그룹과 프로젝트의 모든 사용자에 대해 제거됩니다.

#### 프로젝트에 대해 MCP 서버 차단 {#block-an-mcp-server-for-a-project}

사전 요구 사항:

- 프로젝트에 대한 소유자 역할을 가지고 있습니다.

프로젝트에 대해 MCP 서버를 차단하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반** > **GitLab Duo**를 선택합니다.
1. **거버넌스 변경**을 선택합니다.
1. **MCP 레지스트리** 탭을 선택합니다.
1. 차단하려는 MCP 서버를 찾아 **차단**을 선택합니다.

차단은 각 사용자의 다음 메시지 또는 새 채팅 세션부터 적용됩니다. 차단된 서버의 도구는 프로젝트의 모든 사용자에 대해 제거됩니다. 동일한 서버가 상위 그룹에서도 차단되면 그룹 차단이 제거될 때까지 프로젝트에서 허용하는 것은 영향을 주지 않습니다. MCP 레지스트리는 이러한 서버를 상위 항목에 의해 차단된 것으로 표시합니다.

## 알려진 이슈 {#known-issues}

- 거버넌스 UI는 세 가지 액세스 범주를 포함합니다: 웹(브라우저 기반 세션), 로컬(IDE 및 CLI), 러너(CI/CD 러너에서 실행되는 백그라운드 플로우). 러너 액세스는 항상 허용 및 항상 거부만 지원합니다. 항상 요청은 적용되지 않습니다. 백그라운드 플로우의 승인 프롬프트에 응답할 사용자가 없기 때문입니다. 구성된 러너 규칙이 없는 도구는 기본적으로 항상 허용입니다.
- GitLab MCP 서버에서 제공되는 `search` 도구는 GitLab Duo 에이전트 플랫폼이 별개의 좁은 검색 도구로 노출하는 것을 집계합니다. 이러한 좁은 도구에 구성된 규칙은 `search`로 확장되지 않습니다. MCP 검색을 제한하려면 `search`에 직접 규칙을 구성합니다.

## 관련 항목 {#related-topics}

- [AI 거버넌스](_index.md)
- [AI 거버넌스 대시보드](governance-dashboard.md)
- [GitLab Duo Agent Platform 가용성 제어](../duo_agent_platform/turn_on_off.md)
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
- [감사 이벤트](../../administration/compliance/audit_event_reports.md)
