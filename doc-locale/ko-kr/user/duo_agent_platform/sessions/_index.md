---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 실행한 에이전트 및 플로우의 상태와 실행 데이터를 확인하고 관리합니다.
title: 세션
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

세션은 실행한 에이전트 및 플로우의 상태와 실행 데이터를 표시합니다.

세션은 GitLab Duo Agentic Chat 및 IDE 또는 UI의 기본 플로우로 만듭니다. 다음은 예시입니다.

- 러너에서 실행되는 플로우(예: [Fix CI/CD Pipeline 플로우](../flows/foundational_flows/fix_pipeline.md)). 이러한 세션은 **AI** > **세션** 아래의 UI에서 볼 수 있습니다.
- IDE에서 실행되는 플로우(예: [Software Development 플로우](../flows/foundational_flows/software_development.md)). 이러한 세션은 IDE의 **플로우** 탭 아래의 **세션**에서 볼 수 있습니다.
- GitLab Duo Chat으로 만든 세션입니다. 이러한 세션은 **GitLab Duo 채팅 기록**을 선택하여 오른쪽 사이드바에서 볼 수 있습니다.
- 트리거로 호출되는 플로우. 이러한 세션은 **AI** > **세션** 아래의 UI에서 볼 수 있습니다.

## 프로젝트의 세션 보기 {#view-sessions-for-your-project}

사전 요구 사항:

- 프로젝트에 대해 개발자, 유지 관리자 또는 소유자 역할이 있어야 합니다.

프로젝트의 세션을 보려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **AI** > **세션**을 선택합니다.
1. 모든 세션을 선택하여 더 많은 세부 정보를 봅니다.

## 트리거한 세션 보기 {#view-sessions-youve-triggered}

트리거한 세션을 보려면 다음을 수행합니다.

1. 오른쪽 사이드바에서 **Gitlab Duo 세션**을 선택합니다.
1. 모든 세션을 선택하여 더 많은 세부 정보를 봅니다.
1. 선택 사항입니다. 모든 로그 또는 간결한 부분 집합만 표시하도록 세부 정보를 필터링합니다.

## GitLab Duo Agentic Chat 세션 {#gitlab-duo-agentic-chat-sessions}

채팅은 대화형이므로 UI에서 더 명확한 분리가 필요합니다. 채팅 기록을 채팅 전용으로 존재하는 세션의 필터링된 보기로 생각할 수 있습니다.

GitLab Duo CLI에서 세션을 찾아보고 전환하려면 [세션 전환](../../gitlab_duo_cli/use.md#switch-sessions)을 참조합니다.

## 실행 중인 세션 취소 {#cancel-a-running-session}

실행 중이거나 입력을 기다리는 세션을 취소할 수 있습니다. 세션을 취소하려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **AI** > **세션**을 선택합니다.
1. **상세정보** 탭에서 아래로 스크롤합니다.
1. **세션 취소**를 선택합니다.
1. 확인 대화에서 **세션 취소**를 선택하여 확인합니다.

취소 후:

- 세션 상태가 **중지됨**으로 변경됩니다.
- 세션은 다시 시작하거나 재개할 수 없습니다.

## 에이전트 작업 검토 및 제어 {#review-and-control-agent-actions}

{{< details >}}

- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사전 요구 사항:

- 사용자 지정 플로우의 플로우 정의 YAML에 [`HumanInputComponent`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/flow_registry/v1.md#humaninputcomponent)를 포함해야 합니다.

플로우가 사용자 상호작용 체크포인트에 도달하면 실행이 일시 중지되고 세션은 입력을 기다립니다.

### 승인 알림 {#approval-notifications}

플로우가 체크포인트에서 일시 중지되면 GitLab은 두 가지 방식으로 알립니다.

- **To-Do item**: 레이블이 **Duo Workflow approval required**인 할 일 항목이 **귀하의 작업** > **할 일 목록**에 추가됩니다. 항목이 작업할 수 있는 세션에 직접 연결됩니다. 승인, 거부 또는 요청을 수정하거나 워크플로우를 취소 또는 중지할 때 GitLab은 할 일 항목을 자동으로 완료로 표시합니다.
- **이메일**: 워크플로우 이름, 속한 프로젝트, 완료된 작업과 보류 중인 요청의 요약, 승인 UI로의 직접 링크와 함께 이메일 알림이 전송됩니다.

### 에이전트 체크포인트에 응답 {#respond-to-an-agent-checkpoint}

에이전트 체크포인트를 검토하고 응답하려면 다음을 수행합니다.

1. GitLab Duo 사이드바에서 **세션**을 선택합니다.
1. 검토를 기다리는 세션을 선택합니다.
1. 에이전트의 완료된 작업과 제안된 다음 단계를 검토합니다.
1. 다음 중 하나를 선택합니다.
   - **승인**: 에이전트가 계획된 작업을 계속하도록 허용합니다.
   - **거부**: 플로우 실행을 즉시 중지합니다.
   - **수정**: 에이전트에 피드백 또는 제안을 보냅니다. 에이전트는 다른 검토를 위해 체크포인트로 돌아갑니다.

## 세션 보관 {#session-retention}

세션은 마지막 작업 후 30일 후에 자동으로 삭제됩니다. 보관 기간은 세션과 상호작용할 때마다 재설정됩니다. 예를 들어 20일마다 세션과 상호작용하면 자동으로 삭제되지 않습니다.

IDE에서 30일 보관 기간이 만료되기 전에 세션을 수동으로 삭제할 수 있습니다.
