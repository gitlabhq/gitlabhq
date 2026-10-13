---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 지정 플로우 YAML 스키마
---

{{< details >}}

- 티어:  [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated {{< /details >}}

{{< history >}}

- GitLab 19.2에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/602415)으로 변경되었습니다.

{{< /history >}}

사용자 지정 플로우는 [플로우 레지스트리 v1 사양](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/flow_registry/v1.md) 구문을 사용합니다. v1 사양은 `version`, `environment`, `components`, `prompts`, `routers`, `flow`과 같은 필드를 포함하여 전체 YAML 구조를 정의합니다.

v1 사양의 일부 필드는 사용자 지정 플로우에서 제한됩니다. 자세한 내용은 [제한된 필드](#restricted-fields)를 참조하세요.

YAML 구성에도 최대 크기가 있습니다. 자세한 내용은 [구성 크기 제한](../ai_catalog.md#configuration-size-limits)을 참조하세요.

## 트리거 유형별 목표 값 {#goal-values-by-trigger-type}

사용자 지정 플로우를 설계할 때, 목표 값은 플로우를 시작하는 트리거 유형에 따라 다릅니다. 플로우는 여러 트리거 유형이 구성될 수 있으며, 각 트리거 유형은 `context:goal`로 다른 값을 전달합니다. 플로우는 구성된 각 트리거 유형에 대한 목표 형식을 처리해야 합니다.

트리거 유형에 대한 자세한 내용은 [트리거](../triggers/_index.md)를 참조하세요.

구성 요소는 `inputs` 필드를 통해 목표에 액세스합니다:

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - "context:goal"
```

### 언급 이벤트 {#mention-events}

사용자가 댓글에서 플로우 서비스 계정을 언급하면, 전체 댓글 텍스트와 리소스 컨텍스트가 목표로 전달됩니다.

목표는 다음 형식을 사용합니다:

```plaintext
Input: <comment_text>
Context: {<resource_type> IID: <iid>}
```

예를 들어, 사용자가 이슈 `#2`에서 `@ai-my-flow Can you work on this?`을 작성하면, 목표는 다음과 같습니다:

```plaintext
Input: @ai-my-flow Can you work on this?
Context: {Issue IID: 2}
```

### 할당 및 검토자 할당 이벤트 {#assign-and-assign-reviewer-events}

플로우 서비스 계정이 이슈나 머지 리퀘스트에 할당되거나 검토자로 할당되면, 리소스의 IID가 목표로 전달됩니다.

예를 들어, 플로우 서비스 계정이 머지 리퀘스트 `!10`에서 검토자로 할당되면, `context:goal`의 값은 `10`입니다.

IID를 `context:project_id`과(와) 함께 사용하여 리소스를 읽습니다:

```yaml
components:
  - name: "review_mr"
    type: AgentComponent
    prompt_id: "review_mr_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_iid"
```

### 파이프라인 이벤트 {#pipeline-events}

파이프라인 이벤트가 플로우를 트리거할 때, 전체 [파이프라인 이벤트 웹후크 페이로드](../../project/integrations/webhook_events.md#pipeline-events)가 목표로 전달됩니다.

## 선택적 최상위 속성 {#optional-top-level-properties}

### `coding_environment` {#coding_environment}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/606480)되었습니다.

{{< /history >}}

선택적 `coding_environment` 속성은 워크로드가 시작될 때 플로우에 필요한 코딩 환경의 종류를 선언합니다.

| 값 | 설명 |
|-------|-------------|
| `full` | 제공되지 않을 때 기본값입니다. 리포지토리 복제, 설정 스크립트, Git 훅, 및 종속성 캐시입니다. 리포지토리 파일을 읽거나 쓰는 플로우에 이를 사용합니다. |
| `none` | 리포지토리 복제가 없습니다. 설정 스크립트와 종속성 캐시가 건너뜁니다. Duo 세션 Git 훅은 여전히 설치되어 있으므로, 리포지토리를 직접 복제하는 플로우는 커밋이 Duo에 귀속됩니다. GitLab API와만 상호작용하고 로컬 리포지토리가 필요 없는 API 전용 플로우에 이를 사용합니다. 에이전트 도구가 리포지토리 파일을 읽거나 쓰면 작동할 것이 없습니다. `none` 값은 리포지토리 액세스를 차단하지 않습니다. `run_command` 도구를 가진 플로우는 여전히 리포지토리를 직접 복제할 수 있습니다. 속성은 플로우가 시작되기 전에 GitLab이 준비하는 것만 제어합니다. |

플로우가 체크아웃이 필요할 때 `full` 값을 사용하면, 실행 중에 대신 한 번에 미리 복제가 발생합니다.

`full` 또는 `none` 이외의 값을 추가하면 스키마 유효성 검사가 실패하고 플로우가 실행되지 않습니다.

`coding_environment` 속성을 추가하지 않으면, 플로우는 전체 환경을 받고 여전히 리포지토리 액세스를 유지합니다.

예제:

```yaml
version: v1
environment: ambient
coding_environment: none
components:
  - name: "api_agent"
    type: AgentComponent
    prompt_id: "my_api_prompt"
    inputs:
      - "context:goal"
routers:
  - from: "api_agent"
    to: end
flow:
  entry_point: "api_agent"
```

## 제한된 필드 {#restricted-fields}

v1 사양의 일부 필드와 기능은 사용자 지정 플로우가 GitLab에서 일관되게 작동하도록 제한됩니다.

### `environment` {#environment}

`environment` 필드는 사용자 지정 플로우에서 `ambient` 값만 지원합니다.

`chat` 및 `chat-partial` 값은 지원되지 않습니다.

### 프롬프트에서 `model` {#model-in-prompts}

`prompts` 항목 내 `model` 필드는 지원되지 않습니다.

모델은 그룹 또는 인스턴스 설정에서 구성된 모델 제공자에 의해 결정됩니다.

### `AgentComponent` 필드 {#agentcomponent-fields}

`response_schema_id` 및 `response_schema_version` 필드는 지원되지 않습니다.

### `OneOffComponent` 필드 {#oneoffcomponent-fields}

`ui_role_as` 필드는 지원되지 않습니다.

### 프롬프트 매개변수에서 `stop` {#stop-in-prompt-parameters}

`params` 항목 내 `stop` 필드는 지원되지 않습니다.

### 최상위 필드 {#top-level-fields}

v1 사양의 `name`, `description`, 및 `product_group` 필드는 지원되지 않습니다. 사용자 지정 플로우는 이러한 필드를 거부합니다.
