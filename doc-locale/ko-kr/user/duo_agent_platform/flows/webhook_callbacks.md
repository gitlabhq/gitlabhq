---
stage: Agent Foundations
group: Agent Developer
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 프로젝트 또는 그룹 웹후크에서 GitLab Duo 플로우 수명 주기 이벤트를 받습니다.
title: 웹후크 콜백
---

{{< details >}}

- 티어:  [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 19.4에서 [기능 플래그](../../../administration/feature_flags/_index.md) `duo_flow_callback_hooks`와 함께 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249145). 기본적으로 사용 중지됩니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능성은 기능 플래그로 제어합니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용은 준비되지 않았습니다.

[Flows API](../../../api/duo_agent_platform_flows.md)로 플로우를 트리거하면 GitLab에서 지정한 웹후크로 플로우 수명 주기 이벤트를 보낼 수 있습니다. 플로우 상태를 위해 API를 폴링하는 대신 플로우가 시작, 완료 또는 실패할 때 반응할 수 있습니다.

프로젝트 또는 그룹에서 웹후크를 사용할 수 있습니다. 자식 프로젝트는 웹후크를 상속합니다. 이는 최상위 그룹의 웹후크가 해당 그룹의 모든 프로젝트의 플로우를 제공한다는 의미입니다.

## 사전 요구 사항 {#prerequisites}

웹후크가 플로우 이벤트를 수신하려면 다음 필수 조건을 충족하는지 확인합니다:

- 웹후크가 프로젝트 또는 그룹에 대해 [생성](../../project/integrations/webhooks.md#create-a-webhook)되었고 [콜백이 활성화](#turn-on-callbacks-for-a-webhook)되어 있습니다.
- 웹후크는 플로우가 실행되는 프로젝트 또는 그룹이거나 해당 프로젝트 또는 그룹의 상위 그룹 중 하나에 속합니다.
- 웹후크는 [시스템 웹후크](../../../administration/system_hooks.md)가 아닙니다.

## 웹후크에 대한 콜백 활성화 {#turn-on-callbacks-for-a-webhook}

사전 요구 사항:

- 프로젝트 웹후크의 경우 프로젝트에 대한 Maintainer 또는 Owner 역할이 있어야 합니다.
- 그룹 웹후크의 경우 그룹에 대한 Owner 역할이 있어야 합니다.

웹후크에 대한 콜백을 활성화하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **웹후크**를 선택합니다.
1. **새 webhook 추가**를 선택하거나 기존 웹후크에 대해 **편집**을 선택합니다.
1. **GitLab Duo 에이전트 플랫폼**에서 **이 웹후크로 Duo 플로우 이벤트 전송** 체크박스를 선택합니다.
1. **webhook 추가** 또는 **변경사항 저장**을 선택합니다.

[프로젝트 웹후크 API](../../../api/project_webhooks.md) 또는 [그룹 웹후크 API](../../../api/group_webhooks.md)로 `duo_flow_callback_enabled` 속성을 설정할 수도 있습니다. 두 API 중 하나를 사용하여 웹후크를 나열하고 콜백을 활성화한 웹후크의 ID를 찾습니다.

콜백을 활성화하는 데 필요한 역할은 웹후크에만 적용됩니다. 웹후크를 참조하는 플로우를 트리거하는 사용자는 이러한 역할이 필요하지 않습니다.

## 플로우에 대한 콜백 수신 {#receive-callbacks-for-a-flow}

사전 요구 사항:

- [플로우에 대한 필수 조건](_index.md#prerequisites)을 충족해야 합니다.

콜백을 수신하려면 [플로우를 트리거](../../../api/duo_agent_platform_flows.md#trigger-a-flow)할 때 `callback_hook_id` 속성으로 웹후크 ID를 전달합니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "workflow_definition": "developer/v1",
    "start_workflow": true,
    "callback_hook_id": 42,
    "client_reference": "run-abc123"
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

GitLab에서 보내는 이벤트와 각 페이로드의 구조는 [GitLab Duo 플로우 이벤트](../../project/integrations/webhook_events.md#gitlab-duo-flow-events)를 참조합니다.

### 요청과 콜백 상호 연관 {#correlate-callbacks-with-a-request}

플로우를 트리거한 요청과 콜백을 상호 연관하려면 선택적 `client_reference` 속성을 사용합니다. GitLab은 해당 플로우에 대한 모든 콜백에서 값을 다시 반향하며 해석하지 않습니다.

## 엔드포인트에서 콜백 처리 {#handling-callbacks-in-your-endpoint}

콜백이 GitLab에서 온 것인지 확인한 후 조치를 취합니다. 콜백은 다른 모든 웹후크 이벤트와 동일한 헤더를 포함하므로 웹후크에서 서명 토큰을 구성하고 [서명을 검증](../../project/integrations/webhooks.md#verify-the-signature)합니다.

GitLab은 동일한 이벤트를 두 번 이상 전달할 수 있으므로 엔드포인트를 멱등성으로 만듭니다. 엔드포인트가 성공 또는 리다이렉트 응답을 반환하지 않으면 GitLab은 백오프를 사용하여 최대 5회까지 전달을 다시 시도합니다. 재시도는 원본 페이로드에서 `event_id`를 반복하므로 처리한 `event_id` 값을 저장하고 이미 본 이벤트는 무시합니다. 재시도가 소진되면 GitLab은 해당 이벤트 전달을 중지합니다.

반복적인 전달 실패는 웹후크 실패 제한에 포함되며 GitLab은 [웹후크를 자동으로 비활성화](../../project/integrations/webhooks.md#auto-disabled-webhooks)할 수 있습니다. 웹후크가 [일시적으로 비활성화](../../project/integrations/webhooks.md#temporarily-disabled-webhooks)되면 GitLab은 해당 웹후크의 플로우 이벤트를 보류하고 비활성화 기간이 끝난 후 전달합니다. GitLab은 이벤트를 최대 3회까지 보류합니다. 웹후크가 여전히 비활성화되어 있으면 GitLab은 이벤트를 전달하지 않습니다. GitLab은 [영구적으로 비활성화된](../../project/integrations/webhooks.md#permanently-disabled-webhooks) 웹후크에 플로우 이벤트를 보내지 않습니다. 다시 플로우 이벤트를 수신하려면 [웹후크를 다시 활성화](../../project/integrations/webhooks.md#re-enable-disabled-webhooks)합니다.

모든 전달 시도 전에 GitLab은 [콜백이 여전히 활성화](#turn-on-callbacks-for-a-webhook)되었는지 웹후크에 대해 확인합니다. 플로우가 실행 중일 때 콜백을 비활성화하면 GitLab은 대기 중인 이벤트 및 보류 중인 재시도를 포함하여 해당 플로우에 대한 이벤트 전송을 중지합니다.

GitLab에서 보낸 내용과 엔드포인트에서 반환한 내용을 확인하려면 [웹후크 요청 기록](../../project/integrations/webhooks.md#view-webhook-request-history)을 봅니다. **최근 이벤트** 섹션은 지난 2일 동안 웹후크에 대한 모든 요청을 표시합니다. 이 섹션은 전달 시도만 표시하므로 웹후크가 비활성화된 동안 GitLab이 보류했거나 전달하지 않은 이벤트는 포함하지 않습니다.

## 관련 항목 {#related-topics}

- [GitLab Duo 플로우 이벤트](../../project/integrations/webhook_events.md#gitlab-duo-flow-events)
- [Flows API](../../../api/duo_agent_platform_flows.md)
- [웹후크](../../project/integrations/webhooks.md)
