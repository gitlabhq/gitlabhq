---
stage: AI-powered features
group: Workflow Catalog
title: Flow Registry Framework v1
ignore_in_report: true
---

{{< details >}}

- 티어:  [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

GitLab Duo Agent Platform에서 Flow Registry Framework v1을 사용하여 단일 YAML 파일에 컴포넌트, 도구 및 라우팅 로직을 정의하여 사용자 지정 AI 기반 플로우를 구축할 수 있습니다.

## YAML 구성 구조 {#yaml-configuration-structure}

모든 플로우는 단일 YAML 파일입니다. 최상위 구조는 다음과 같습니다:

```yaml
version: "v1"
environment: ambient

components:
  # List of components (see Component types)

routers:
  # Routing rules between components (see Routers)

flow:
  entry_point: "component_name"   # First component to run

prompts:                           # Optional - inline prompt definitions
  # Locally defined prompts (see Prompts)
```

### 필수 필드 {#required-fields}

| 필드 | 설명 |
|---|---|
| `version` | 항상 `"v1"` |
| `environment` | 플로우 상호작용 스타일 - [환경](#environment) 참고 |
| `components` | 플로우를 구성하는 컴포넌트 목록 - [컴포넌트 유형](#component-types) 참고|
| `routers` | 컴포넌트 간 라우팅 규칙 - [라우터](#routers) 참고 |
| `flow` | 진입점 및 선택적 컨텍스트 입력 - [플로우 섹션](#flow-section) 참고 |

### 선택적 필드 {#optional-fields}

| 필드 | 설명 |
|---|---|
| `name` | 사용자가 읽을 수 있는 플로우 이름 |
| `description` | 플로우에 대한 설명 |
| `product_group` | 팀 소유권 (예: `agent_foundations`) |
| `prompts` | 인라인 프롬프트 정의 - [로컬로 정의된 프롬프트](#locally-defined-prompts) 참고 |
| `response_schemas` | 인라인 응답 스키마 정의 - [응답 스키마](#response-schemas) 참고 |

### 환경 {#environment}

`environment` 필드는 예상되는 인간-AI 상호작용 수준을 선언합니다.

| 값 | 설명 |
|---|---|
| `ambient` | 자동으로 실행되는 백그라운드 실행입니다. 사용자가 작업을 위임하면 에이전트가 자율적으로 실행됩니다. 인간 참여를 최소화합니다. 대부분의 사용자 지정 플로우에 이를 사용하세요. |
| `chat` | 채팅과 같은 인터페이스를 통한 대화형 상호작용입니다. |
| `chat-partial` | 단일 에이전트 플로우를 위한 단순화된 `chat` 변형입니다. 보일러플레이트를 건너뜁니다. 정확히 하나의 `AgentComponent`을 필요로 합니다. |

## 빠른 시작 {#quick-start}

플로우를 호출하려면 플로우 구성을 `StartWorkflowRequest`에 전달합니다:

```plaintext
flowConfigId: "<your_flow_id>"
flowConfigSchemaVersion: "v1"
flowVersion: "1.0.0"
```

이 페이지의 나머지 부분은 플로우 구성의 YAML 구조를 설명합니다. 코드베이스에 새로운 기본 플로우를 등록하는 방법에 대한 지시사항은 [기본 플로우 개발자 가이드](foundational_flows/developer.md)를 참고하세요.

## 세션 컨텍스트 변수 {#session-context-variables}

모든 컴포넌트 `inputs` 블록은 `from: "context:<key>"`을 사용하여 세션 컨텍스트에서 값을 가져옵니다. 프레임워크는 항상 사용 가능한 변수 집합을 자동으로 채웁니다. 이 변수들을 선언할 필요는 없지만 각 컴포넌트의 `inputs` 블록에서 명시적으로 참조해야 합니다.

### 항상 사용 가능한 변수 {#always-available-variables}

| 변수 | 형식 | 설명 |
|---|---|---|
| `context:goal` | 문자열 | 워크플로우를 트리거한 사용자의 목표 또는 메시지 |
| `context:project_id` | 문자열 | GitLab 프로젝트 ID (숫자, 문자열로) |
| `context:project_http_url_to_repo` | 문자열 | 리포지토리의 전체 HTTPS 클론 URL |

> [!note]
> `context:project_id`은 프롬프트 템플릿에 자동으로 주입되지 않습니다. 에이전트가 GitLab API 도구 (예: `get_merge_request`, `list_issues` 또는 `create_merge_request`)를 호출하는 경우 컴포넌트의 `inputs`에 추가하고 프롬프트 `user:` 블록에 `Project ID: {{ project_id }}`을 포함해야 합니다. 이를 생략하는 것이 플로우 실패의 가장 일반적인 원인입니다.

### 에이전트 플랫폼 표준 컨텍스트 변수 {#agent-platform-standard-context-variables}

이 변수들은 `flow.inputs` 스탠자를 선언할 때만 사용 가능합니다. CI 러너에서 주입한 브랜치 및 세션 메타데이터를 수행합니다.

| 변수 | 형식 | 설명 |
|---|---|---|
| `context:inputs.agent_platform_standard_context.primary_branch` | 문자열 | 리포지토리의 기본 브랜치 (예: `main`) |
| `context:inputs.agent_platform_standard_context.workload_branch` | 문자열 | CI 워크로드 러너에서 사용하는 Git 참조 |
| `context:inputs.agent_platform_standard_context.session_owner_id` | 문자열 | 플로우를 트리거한 사람의 GitLab 사용자 ID |

플로우에서 브랜치를 생성하거나, 머지 리퀘스트를 열거나, 기본 브랜치를 알아야 할 때 이를 선언합니다. 자세한 내용은 [플로우 섹션](#flow-section)을 참고하세요.

## 플로우 섹션 {#flow-section}

`flow` 섹션은 진입점과 선택적으로 주입할 외부 컨텍스트 카테고리를 정의합니다.

### 최소 {#minimal}

```yaml
flow:
  entry_point: "my_first_component"
```

### 에이전트 플랫폼 표준 컨텍스트 포함 {#with-agent-platform-standard-context}

플로우에서 `primary_branch`, `workload_branch` 또는 `session_owner_id`이 필요할 때 필수입니다:

```yaml
flow:
  entry_point: "create_feature_branch"
  inputs:
    - category: agent_platform_standard_context
      input_schema:
        primary_branch:
          type: string
          description: The default/primary branch of the repository (for example, 'main', 'master')
        workload_branch:
          type: string
          description: git ref to workload branch
        session_owner_id:
          type: string
          description: Human user's ID that initiated the flow
```

## 컴포넌트 유형 {#component-types}

| 구성 요소 | 목적 | AI 관련 | 언제 사용할지 |
|---|---|:---:|---|
| [AgentComponent](#agentcomponent) | 다중 턴 AI 추론 (도구 포함) | 예 | 반복적인 의사 결정, 대화 또는 다중 단계 도구 사용이 필요한 복잡한 작업입니다. |
| [OneOffComponent](#oneoffcomponent) | 단일 라운드 AI 도구 실행 | 예 | 기본 재시도 로직이 포함된 한 번의 LLM 호출로 완료 가능한 제한된 작업입니다. |
| [DeterministicStepComponent](#deterministicstepcomponent) | 고정된 인수로 단일 도구 실행 | 아니요 | 도구 인수가 상태에서 직접 제공되는 예측 가능하고 반복 가능한 작업입니다. |
| [HumanInputComponent](#humaninputcomponent) | 사용자 입력 요청 및 처리 | 아니요 | 승인 게이트, 대화형 채팅 또는 인간 피드백이 필요한 모든 지점입니다. |
| [EndComponent / AbortComponent](#endcomponent-and-abortcomponent) | 워크플로우 종료 | 아니요 | 모든 플로우는 `"end"` (성공) 또는 `"abort"` (오류)로 종료해야 합니다. |

## AgentComponent {#agentcomponent}

AgentComponent는 AI 기반 플로우의 기본 구성 요소입니다. LLM을 사용하여:

- 입력값을 처리합니다.
- 프롬프트를 기반으로 의사 결정을 합니다.
- 도구를 호출합니다.
- 대화 기록을 유지합니다.
- 다운스트림 컴포넌트를 위한 출력을 생성합니다.

### 필수 매개변수 {#required-parameters}

| 매개 변수 | 설명 |
|---|---|
| `name` | 고유 식별자입니다. `:` 또는 `.` 문자를 포함할 수 없습니다. |
| `type` | `"AgentComponent"`이어야 합니다. |
| `prompt_id` | 프롬프트 템플릿의 ID (로컬 또는 레지스트리 기반)입니다. |

### 선택적 매개변수 {#optional-parameters}

| 매개 변수 | 기본값 | 설명 |
|---|---|---|
| `prompt_version` | 생략됨 | Semver 제약 조건 (예: `"^1.0.0"`)입니다. 로컬로 정의된 프롬프트를 사용하려면 생략합니다. |
| `inputs` | `["context:goal"]` | 입력 데이터 소스 목록입니다. |
| `toolset` | `[]` | 에이전트가 사용할 수 있는 도구입니다. [사용 가능한 도구](#available-tools)를 참고하세요. |
| `description` | 없음 | 감독자 아래의 하위 에이전트로 사용될 때 필수입니다. |
| `subagents` | 없음 | 하위 에이전트 이름 목록입니다. [감독자 모드](#supervisor-mode)를 활성화합니다. |
| `max_delegations` | 무제한 | 감독자 모드에서 `delegate_task` 호출의 최대값입니다. |
| `response_schema_id` | 없음 | 구조화된 출력 스키마의 ID입니다. |
| `response_schema_version` | 없음 | 레지스트리 기반 스키마의 Semver입니다. |
| `model_size_preference` | `null` | `"small"` 또는 `"large"`입니다. |
| `require_tool_approval` | `false` | 각 도구 호출 전에 인간의 승인을 기다립니다. |
| `pre_approved_tools` | `[]` | 승인 단계를 건너뛰는 도구입니다. |
| `compaction` | 없음 | 대화 압축 구성입니다. |
| `ui_log_events` | `[]` | UI에 표시할 이벤트입니다. [UI 로그 이벤트](#agentcomponent-ui-log-events)를 참고하세요. |
| `ui_role_as` | `"agent"` | UI에서 역할 표시 (`"agent"` 또는 `"tool"`)입니다. |

### 출력 {#outputs}

| 출력 키 | 설명 |
|---|---|
| `context:{name}.final_answer` | 에이전트의 최종 응답 (문자열 또는 사용자 지정 스키마가 포함된 딕셔너리)입니다. |
| `context:{name}.final_answer.{field}` | 사용자 지정 응답 스키마를 사용할 때의 개별 필드입니다. |
| `conversation_history:{name}` | 전체 메시지 기록입니다. |

### 입력 {#inputs}

컴포넌트 입력은 세션 컨텍스트에서 값을 가져오고 이를 프롬프트의 템플릿 변수로 사용할 수 있도록 합니다. `as:` 별칭은 프롬프트 템플릿의 `{{ variable }}` 플레이스홀더와 정확히 일치해야 합니다.

```yaml
# In the component inputs:
inputs:
  - from: "context:goal"
    as: "goal"
  - from: "context:project_id"
    as: "project_id"
  - from: "context:previous_agent.final_answer"
    as: "previous_result"
  - from: "some constant value"
    as: "my_constant"
    literal: true

# In the prompt user block:
user: |
  Project ID: {{ project_id }}
  Goal: {{ goal }}
  Previous result: {{ previous_result }}
```

### 프롬프트 {#prompts}

모든 AgentComponent에는 프롬프트가 필요합니다. 플로우 YAML에 인라인으로 정의하거나 (사용자 지정 플로우 권장) AI Gateway 프롬프트 레지스트리에서 참조합니다.

#### 로컬로 정의된 프롬프트 {#locally-defined-prompts}

`prompt_version`을 생략하여 최상위 `prompts` 블록에서 정의한 인라인 프롬프트를 사용합니다:

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_prompt"
    # prompt_version omitted - uses local prompt

prompts:
  - prompt_id: "my_prompt"
    name: "My Prompt"
    unit_primitives: []           # always include, even if empty
    prompt_template:
      system: |
        You are a helpful assistant.

        When your task is complete, your final answer is a plain text summary
        of what you did. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
      placeholder: history        # include explicitly
    params:
      timeout: 180
```

#### 레지스트리 프롬프트 {#registry-prompts}

`prompt_version`을 지정하여 `ai_gateway/prompts/definitions/`의 AI Gateway 프롬프트 레지스트리에서 로드합니다:

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_flow/my_prompt"
    prompt_version: "^1.0.0"
```

#### 프롬프트 작성 모범 사례 {#prompt-writing-best-practices}

- 에이전트에 작업이 완료되었을 때를 항상 알립니다. 명시적인 중단 지시 없이 에이전트는 계속 반복합니다. 모든 `system:` 프롬프트를 다음과 같은 문장으로 종료합니다: `"When [condition], your final answer is [what to say]. No further steps are needed after that."`
- GitLab API 도구를 호출하는 모든 에이전트에 대해 `user:` 블록에 `project_id`을 항상 전달합니다. 에이전트는 자체적으로 이를 검색할 수 없습니다.
- 변수 이름을 정확히 일치시킵니다. `inputs`의 `as:` 별칭은 프롬프트 템플릿의 `{{ variable }}` 플레이스홀더와 일치해야 합니다.
- 비어 있는 경우에도 인라인 프롬프트에 `unit_primitives: []`을 항상 포함합니다.
- 인라인 프롬프트 템플릿에 `placeholder: history`을 항상 포함합니다.

### 사용 가능한 도구 {#available-tools}

`toolset`에서 snake_case 이름을 전달하여 도구를 구성합니다. 전체 목록은 `duo_workflow_service/components/tools_registry.py`에 있습니다. 일반적인 예:

- 파일 작업: `read_file`, `create_file_with_contents`, `edit_file`, `list_dir`, `find_files`, `grep`
- Git 작업: `run_command`, `create_merge_request`, `create_branch`
- GitLab API: `get_issue`, `list_issues`, `get_merge_request`, `gitlab_merge_request_search`, `get_work_item`, `get_repository_file`, `list_repository_tree`, `create_issue_note`, `create_merge_request_note`, `create_commit`, `gitlab_api_get`, `get_project`

### 도구 옵션 {#tool-options}

LLM이 도구의 매개변수를 변경할 수 없도록 컴포넌트 수준에서 도구의 매개변수를 재정의합니다:

```yaml
toolset:
  - "get_merge_request"                    # simple string - no overrides
  - "create_merge_request_note":           # object form - override a parameter
      "internal": true
```

옵션은 초기화 시간에 도구의 Pydantic 입력 스키마에 대해 검증됩니다. 옵션 키가 유효한 매개변수와 일치하지 않으면 `ValueError`이 발생합니다. 실행 시간에 도구 옵션은 LLM 제공 값보다 우선합니다.

### AgentComponent UI 로그 이벤트 {#agentcomponent-ui-log-events}

| 이벤트 | 설명 |
|---|---|
| `on_agent_final_answer` | 에이전트가 최종 응답을 호출합니다. 이를 통해 세션 UI 및 CI 로그에서 전체 최종 답변의 표시를 활성화할 수 있습니다. 출력에 민감한 데이터가 포함된 경우 비활성화합니다. |
| `on_tool_execution_success` | 도구 호출이 성공적으로 완료되었습니다. |
| `on_tool_execution_failed` | 도구 호출이 실패했습니다. |
| `on_tool_approval_request` | 도구 승인이 사용자 결정 대기 중입니다. UI에서 승인 요청을 표시하려면 포함해야 합니다. |

### 도구 승인 {#tool-approval}

`require_tool_approval: true`일 때 워크플로우는 에이전트가 도구 호출을 생성한 후 일시 중지되고 진행하기 전에 사용자의 결정을 기다립니다.

다음과 같은 결정 유형이 지원됩니다:

| 결정 | 동작 |
|---|---|
| `APPROVE` | 도구가 정상적으로 실행됩니다. |
| `REJECT` | 거부 메시지가 기록에 추가되고 에이전트가 다른 접근 방식을 시도합니다. |
| `MODIFY` | 거부와 사용자 피드백이 기록에 추가되고 에이전트가 그에 따라 조정합니다. |

도구는 다음 중 하나에 나타나면 사전 승인되고 승인 단계를 건너뜁니다:

- 컴포넌트 수준: 컴포넌트의 `pre_approved_tools` 매개변수에 나열됩니다. YAML의 플로우 작성자가 제어합니다.
- 워크플로우 수준: 워크플로우 `startRequest`에서 `pre_approved_agent_privileges`을 통해 지정됩니다. 워크플로우 호출자가 호출 시간에 제어합니다.

모든 도구 호출이 한 가지 소스에서 사전 승인되면 승인 플로우가 완전히 건너뛰어지고 도구가 즉시 실행됩니다.

```yaml
components:
  - name: "code_editor"
    type: AgentComponent
    prompt_id: "code_assistant"
    prompt_version: "^1.0.0"
    require_tool_approval: true
    pre_approved_tools: ["read_file", "list_dir", "find_files"]
    toolset: ["read_file", "list_dir", "find_files", "edit_file", "run_command"]
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_tool_approval_request"
    inputs: ["context:goal"]
```

### 사용 모드 {#usage-modes}

| 모드 | 언제 | `description` 필수 |
|---|---|---|
| 독립 실행형 | 플로우의 정규 컴포넌트입니다. | 아니요 |
| 관리 | 감독자에게 위임된 하위 에이전트입니다. | 예 |
| 감독자 | `delegate_task`을 통해 하위 에이전트를 조율합니다. | 아니요 (감독자 자체에는 필요 없음) |

### 감독자 모드 {#supervisor-mode}

`subagents`을 제공하면 에이전트는 `delegate_task`과 `final_response_tool`에 자동으로 액세스할 수 있는 감독자가 됩니다. LLM이 `delegate_task`을 호출하면 프레임워크는:

1. 명명된 하위 에이전트에 대해 번호가 지정된 하위 세션을 할당하거나 다시 시작합니다.
1. 위임 프롬프트를 사용하여 하위 에이전트의 대화 기록을 시드합니다.
1. 하위 에이전트의 ReAct 루프로 실행을 라우팅합니다.
1. 하위 에이전트 완료 시 결과를 감독자의 기록에 다시 주입하고 감독자에게 제어를 반환합니다.

#### 제약 조건 {#constraints}

- `subagents`은 최소 하나의 항목을 포함해야 합니다.
- 나열된 모든 하위 에이전트는 `description` 필드를 가져야 합니다.
- `AgentComponent`은 최대 하나의 감독자가 소유할 수 있습니다.
- 감독자 프롬프트는 `delegate_task`과 `final_response_tool`를 사용할 때를 LLM에 지시해야 합니다.

#### 감독자 출력 {#supervisor-outputs}

| 출력 키 | 설명 |
|---|---|
| `context:{supervisor_name}.final_answer` | 감독자의 최종 응답입니다. |
| `conversation_history:{supervisor_name}` | 감독자 자신의 메시지 기록입니다. |

### 응답 스키마 {#response-schemas}

응답 스키마는 AgentComponent의 출력을 구조화된 형식으로 제한합니다. 하나 없이는 에이전트가 `final_answer`에 일반 텍스트를 반환합니다. 하나와 함께 `final_answer`는 딕셔너리이며 각 필드는 `context:{name}.final_answer.{field}`로도 액세스할 수 있습니다.

#### 인라인 스키마 (사용자 지정 플로우 권장) {#inline-schema-recommended-for-custom-flows}

```yaml
components:
  - name: "code_reviewer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    response_schema_id: "code_review"   # no response_schema_version = inline lookup
    toolset: ["read_file"]

response_schemas:
  - schema_id: "code_review"
    definition:
      "$schema": "http://json-schema.org/draft-07/schema#"
      title: "code_review_response"
      type: object
      properties:
        summary:
          type: string
          description: "Brief summary of findings"
        overall_score:
          type: integer
          minimum: 1
          maximum: 10
      required: [summary, overall_score]
```

#### 레지스트리 스키마 {#registry-schema}

`response_schema_id`과 `response_schema_version`를 모두 제공하여 `ai_gateway/response_schemas/definitions/`의 서버 측 레지스트리에서 로드합니다:

```yaml
components:
  - name: "code_reviewer"
    type: AgentComponent
    prompt_id: "code_review/detailed_analysis"
    prompt_version: "^1.0.0"
    response_schema_id: "analysis/code_review"
    response_schema_version: "^1.0.0"
```

다운스트림 컴포넌트는 개별 스키마 필드를 참조할 수 있습니다:

```yaml
inputs:
  - from: "context:code_reviewer.final_answer.overall_score"
    as: "score"
```

#### 스키마 정의 참조 {#schema-definition-reference}

응답 스키마는 [JSON Schema](https://json-schema.org/) 형식을 사용합니다. 중요한 최상위 필드:

| 필드 | 설명 |
|---|---|
| `$schema` | 스키마 방언입니다. 제공되지 않으면 `draft-07`로 기본값입니다. |
| `title` | 에이전트가 최종 응답을 호출하는 도구 이름으로 매핑합니다. 기존 도구 이름과 일치해서는 안 됩니다. 충돌하면 `ValueError`을 발생시킵니다. |
| `type` | `"object"`이어야 합니다. |
| `properties` | 스키마 필드를 정의하는 중첩 JSON 객체입니다. 중첩된 구조를 위해 `"object"` 유형을 지원합니다. |
| `required` | 출력에 있어야 하는 필드 이름 목록입니다. |

다음 JSON Schema 검증 제약 조건이 AgentComponent 응답 스키마에서 지원됩니다.

##### 숫자 제약 조건 (정수/숫자) {#numeric-constraints-integernumber}

| JSON Schema 제약 조건 | Pydantic 필드 매개변수 | 설명 |
|---|---|---|
| `minimum` | `ge=` | 최소값 (포함) - 보다 크거나 같음입니다. |
| `maximum` | `le=` | 최대값 (포함) - 보다 작거나 같음입니다. |
| `exclusiveMinimum` | `gt=` | 최소값 (제외) - 보다 큼입니다. |
| `exclusiveMaximum` | `lt=` | 최대값 (제외) - 보다 작음입니다. |
| `multipleOf` | `multiple_of=` | 이 숫자의 배수여야 합니다. |

##### 문자열 제약 조건 {#string-constraints}

| JSON Schema 제약 조건 | Pydantic 필드 매개변수 | 설명 |
|---|---|---|
| `minLength` | `min_length=` | 문자 단위 최소 문자열 길이입니다. |
| `maxLength` | `max_length=` | 문자 단위 최대 문자열 길이입니다. |
| `pattern` | `pattern=` | 문자열이 일치해야 하는 정규식 패턴입니다. |

##### 배열 제약 조건 {#array-constraints}

| JSON Schema 제약 조건 | Pydantic 필드 매개변수 | 설명 |
|---|---|---|
| `minItems` | `min_length=` | 배열의 최소 항목 수입니다. |
| `maxItems` | `max_length=` | 배열의 최대 항목 수입니다. |

##### 열거형 및 상수 {#enumeration-and-constants}

| JSON Schema 제약 조건 | Python 유형 | 설명 |
|---|---|---|
| `enum` | `Literal[val1, val2, ...]` | 필드는 지정된 값 중 하나여야 합니다. |
| `const` | `Literal[value]` | 필드는 정확히 이 값이어야 합니다. |

##### 메타데이터 {#metadata}

| JSON Schema 필드 | Pydantic 필드 매개변수 | 설명 |
|---|---|---|
| `default` | `default=` | 선택적 필드의 기본값입니다. |
| `examples` | `examples=` | 에이전트에 지침으로 표시되는 예제 값입니다. |

##### 전체 스키마 예 {#full-schema-example}

```json
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "code_review_response_tool",
    "type": "object",
    "properties": {
        "summary": {
            "type": "string",
            "description": "Brief summary of the code review findings"
        },
        "issues_found": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "severity": {
                        "type": "string",
                        "enum": ["low", "medium", "high", "critical"]
                    },
                    "description": { "type": "string" },
                    "file_path": { "type": "string" },
                    "line_number": { "type": "integer" }
                },
                "required": ["severity", "description"]
            }
        },
        "recommendations": {
            "type": "array",
            "items": { "type": "string" }
        },
        "overall_score": {
            "type": "integer",
            "minimum": 1,
            "maximum": 10
        }
    },
    "required": ["summary", "issues_found", "overall_score"]
}
```

### AgentComponent 예 {#agentcomponent-example}

```yaml
components:
  - name: "code_assistant"
    type: AgentComponent
    prompt_id: "code_review_helper"
    prompt_version: "^1.0.0"
    inputs: ["context:goal"]
    require_tool_approval: true
    pre_approved_tools: ["read_file", "list_dir", "find_files"]
    toolset:
      - "read_file"
      - "list_dir"
      - "find_files"
      - "create_file_with_contents"
      - "create_merge_request_note":
          "internal": true
      - "edit_file"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
    ui_role_as: "agent"
```

## HumanInputComponent {#humaninputcomponent}

HumanInputComponent:

- 워크플로우 실행을 일시 중지합니다.
- 인간에게 프롬프트를 제시합니다.
- 인간이 응답할 때 다시 시작됩니다.

검토 게이트, 승인 및 피드백 루프에 사용합니다.

### 필수 매개변수 {#required-parameters-1}

| 매개 변수 | 설명 |
|---|---|
| `name` | 고유 식별자입니다. `:` 또는 `.` 문자를 포함할 수 없습니다. |
| `type` | `"HumanInputComponent"`이어야 합니다. |
| `sends_response_to` | 인간의 응답을 대화 기록에서 수신하는 AgentComponent의 이름입니다. [이는 이미 실행된 컴포넌트여야 합니다](#critical-constraint-sends_response_to-must-point-to-an-already-run-component). |
| `message_template` | 인간에게 표시되는 Jinja2 템플릿입니다. `inputs`을 통해 변수를 참조할 수 있습니다. |

### 선택적 매개변수 {#optional-parameters-1}

| 매개 변수 | 기본값 | 설명 |
|---|---|---|
| `interaction_type` | `"approval"` | `"approval"`은 승인/거부/수정 버튼을 렌더링합니다. `"input"`는 텍스트 입력을 렌더링합니다. 이를 명시적으로 설정하세요. 기본값에 의존하지 마세요. |
| `inputs` | `[]` | `message_template`으로 렌더링할 변수입니다. |
| `ui_log_events` | `[]` | 항상 두 [UI 로그 이벤트](#ui-log-events)를 포함해야 합니다. |

### 중요 제약 조건: `sends_response_to`은 이미 실행된 컴포넌트를 가리켜야 함 {#critical-constraint-sends_response_to-must-point-to-an-already-run-component}

> [!note]
> `HumanInputComponent`에서 가장 일반적으로 오해되는 필드입니다.

프레임워크는 인간의 피드백을 대상 컴포넌트의 기존 대화 기록에 주입합니다. 해당 컴포넌트가 아직 실행되지 않았으면 대화 기록 항목이 없으며 프레임워크는 `KeyError('<component_name>')`로 중단됩니다.

> [!note]
> `sends_response_to`은 게이트가 실행되기 전에 이미 실행을 완료한 컴포넌트를 명명해야 합니다.

실제로 이는 거의 항상 게이트 직전에 실행된 에이전트를 가리키는 것을 의미합니다.

`modify` 라우트 대상이 아직 실행되지 않았으면 대신 `inputs`을 통해 피드백을 전달합니다:

```yaml
# Correct pattern - sends_response_to points to the already-run agent
- name: "review_gate"
  type: HumanInputComponent
  sends_response_to: "suggester_agent"    # suggester already ran ✅
  interaction_type: "approval"
  ...

# The modify handler gets feedback through inputs instead:
- name: "modify_handler"
  type: AgentComponent
  inputs:
    - from: "context:review_gate.approval"
      as: "human_feedback"               # feedback passed explicitly ✅
```

```yaml
# Wrong pattern - crashes with KeyError
- name: "review_gate"
  sends_response_to: "modify_handler"    # has not run yet → KeyError ❌
```

### UI 로그 이벤트 {#ui-log-events}

두 이벤트 모두 포함해야 합니다. 이것들 없이는 게이트가 세션 UI에서 보이지 않습니다:

| 이벤트 | 설명 |
|---|---|
| `on_user_input_prompt` | 프롬프트를 표시하고 올바른 입력 컨트롤 (버튼 또는 텍스트 상자)을 렌더링합니다. |
| `on_user_response` | 인간의 응답을 UI 채팅 로그에서 캡처합니다. |

### 출력 {#outputs-1}

| 출력 키 | 설명 |
|---|---|
| `context:{name}.approval` | 인간의 결정: `"approve"`, `"reject"` 또는 `"modify"`입니다. |
| `conversation_history:{sends_response_to}` | 인간의 메시지가 대상 에이전트의 기록에 주입됩니다. |

### 승인 라우터 - 두 개가 아닌 세 개의 값 {#approval-router---three-values-not-two}

`interaction_type: "approval"`일 때 인간은 세 가지 값으로 응답할 수 있습니다. 라우터는 세 개 모두를 처리해야 하거나 `modify` 경로가 자동으로 `default_route`으로 제거됩니다:

| 값 | 의미 |
|---|---|
| `"approve"` | 인간이 수락함 - 다음 단계로 진행합니다. |
| `"reject"` | 인간이 거부함 - 종료 또는 오류 처리로 라우팅합니다. |
| `"modify"` | 인간이 피드백 제공함 - 수정을 위해 이전 에이전트로 다시 라우팅합니다. |

```yaml
routers:
  - from: "review_gate"
    condition:
      input: "context:review_gate.approval"
      routes:
        "approve": "next_step"
        "modify": "prior_agent"      # loop back - feedback available in history or inputs
        "reject": "end"
        "default_route": "end"       # always include a fallback
```

### HumanInputComponent 체크리스트 {#humaninputcomponent-checklist}

YAML을 저장하기 전에 확인하세요:

- `interaction_type`이 명시적으로 설정됨 (`"approval"` 또는 `"input"`).
- `ui_log_events`에 `"on_user_input_prompt"`와 `"on_user_response"`이 포함됨.
- 다운스트림 라우터가 `condition:`을 사용함 (`to:` 아님).
- 라우터가 `"approve"`, `"modify"` 및 `"reject"`을 명시적으로 처리함.
- `"default_route"`이 라우터에 있음.
- `sends_response_to`이 게이트가 실행되기 전에 이미 실행된 컴포넌트를 가리킴.
- `modify` 대상이 아직 실행되지 않았으면 해당 `inputs`에 `from: "context:{gate_name}.approval" as: "human_feedback"`이 포함됨.

### 사용 패턴 {#usage-patterns}

#### 승인 워크플로우 {#approval-workflow}

```yaml
components:
  - name: "user_approval"
    type: HumanInputComponent
    sends_response_to: "proposal_agent"   # proposal_agent already ran
    interaction_type: "approval"
    message_template: |
      Please review the proposed changes and choose an action:
      - ✅ Approve: Proceed
      - ✏️ Modify: Provide feedback for revision
      - ❌ Reject: Discard
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

routers:
  - from: "user_approval"
    condition:
      input: "context:user_approval.approval"
      routes:
        "approve": "executor"
        "modify": "proposal_agent"
        "reject": "end"
        "default_route": "end"
```

#### 대화형 채팅 {#interactive-chat}

```yaml
components:
  - name: "user_input"
    type: HumanInputComponent
    sends_response_to: "chat_agent"
    interaction_type: "input"
    message_template: "How can I help you today?"
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

routers:
  - from: "user_input"
    to: "chat_agent"
  - from: "chat_agent"
    to: "user_input"  # loop back for continued interaction
```

## DeterministicStepComponent {#deterministicstepcomponent}

LLM 관여 없이 단일 도구를 직접 실행합니다. 매개변수는 플로우 상태에서 추출됩니다. 여러 인스턴스를 연결하여 순차적 도구 작업을 실행합니다.

### 필수 매개변수 {#required-parameters-2}

| 매개 변수 | 설명 |
|---|---|
| `name` | 고유 식별자입니다. `:` 또는 `.` 문자를 포함할 수 없습니다. |
| `type` | `"DeterministicStepComponent"`이어야 합니다. |
| `tool_name` | 실행할 단일 도구의 이름입니다. |

### 선택적 매개변수 {#optional-parameters-2}

| 매개 변수 | 기본값 | 설명 |
|---|---|---|
| `toolset` | 자동 | 도구를 포함하는 도구 세트 (생략하면 자동 생성됨). |
| `inputs` | `[]` | 도구 매개변수로 매핑되는 입력 소스입니다. |
| `ui_log_events` | `[]` | UI에 표시할 이벤트입니다. |
| `ui_role_as` | `"tool"` | UI에서 역할 표시입니다. |

### 출력 {#outputs-2}

| 출력 키 | 설명 |
|---|---|
| `context:{name}.tool_responses` | 도구 실행의 결과입니다. |
| `context:{name}.error` | 발생한 모든 오류입니다. |
| `context:{name}.execution_result` | `"success"` 또는 `"failed"`입니다. |

### 검증 {#validation}

컴포넌트는 초기화 시간에 도구 인수를 검증합니다:

- 지정된 도구가 도구 세트에 있는지 확인합니다.
- 모든 필수 도구 매개변수가 `inputs`에서 구성되었는지 확인합니다.
- 매개변수가 도구의 예상 스키마와 일치하는지 확인합니다.

오류는 런타임이 아닌 구성 시간에 감지됩니다.

### 예: 여러 도구 연결 {#example-chain-multiple-tools}

```yaml
components:
  - name: "read_config"
    type: DeterministicStepComponent
    inputs:
      - from: "context:goal"
        as: "config_path"
    tool_name: "read_file"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

  - name: "backup_config"
    type: DeterministicStepComponent
    inputs:
      - from: "context:read_config.tool_responses"
        as: "contents"
      - from: "config_backup.txt"
        as: "file_path"
        literal: true
    tool_name: "create_file_with_contents"
```

## OneOffComponent {#oneoffcomponent}

`AgentComponent`과 `DeterministicStepComponent` 사이에 있습니다. LLM을 사용하여 단일 라운드에서 도구 호출을 생성한 후 성공 시 종료합니다. 실패한 실행을 위한 기본 제공 재시도 로직을 포함합니다.

작업을 한 번의 LLM 호출로 완료할 수 있지만 도구 매개변수를 결정하기 위해 LLM 추론의 이점을 얻을 수 있을 때 사용합니다.

### 필수 매개변수 {#required-parameters-3}

| 매개 변수 | 설명 |
|---|---|
| `name` | 고유 식별자입니다. `:` 또는 `.` 문자를 포함할 수 없습니다. |
| `type` | `"OneOffComponent"`이어야 합니다. |
| `prompt_id` | 도구 호출을 지시하는 프롬프트입니다. |
| `toolset` | 단일 라운드에서 사용 가능한 도구입니다. |

### 선택적 매개변수 {#optional-parameters-3}

| 매개 변수 | 기본값 | 설명 |
|---|---|---|
| `prompt_version` | 생략됨 | 로컬로 정의된 프롬프트를 사용하려면 생략합니다. |
| `inputs` | `["context:goal"]` | 입력 데이터 소스입니다. |
| `max_correction_attempts` | `3` | 실패한 도구 실행의 재시도 한계입니다. |
| `model_size_preference` | `null` | `"small"` 또는 `"large"`입니다. |
| `compaction` | 없음 | 대화 압축 구성입니다. |
| `ui_log_events` | `[]` | UI에 표시할 이벤트입니다. |

### 출력 {#outputs-3}

| 출력 키 | 설명 |
|---|---|
| `context:{name}.tool_responses` | 도구 실행 결과입니다. |
| `context:{name}.tool_calls` | 만들어진 도구 호출 기록입니다. |
| `context:{name}.execution_result` | `"success"` 또는 `"failed"`입니다. |

### UI 로그 이벤트 {#ui-log-events-1}

| 이벤트 | 설명 |
|---|---|
| `on_tool_call_input` | 도구가 인수와 함께 호출될 예정입니다. |
| `on_tool_execution_success` | 도구가 성공적으로 완료되었습니다. |
| `on_tool_execution_failed` | 도구 실행이 실패했습니다. |
| `on_agent_reasoning` | 에이전트가 제한으로 인해 도구 호출을 생성할 수 없습니다. |

### 내부 아키텍처 {#internal-architecture}

OneOffComponent는 세 개의 내부 노드로 구성됩니다:

- LLM 노드 (`{name}#llm`): `AgentNode`를 사용하여 하나 이상의 도구 호출을 생성합니다.
- 도구 노드 (`{name}#tools`): `ToolNodeWithErrorCorrection`를 통해 오류 수정으로 도구 호출을 실행합니다.
- 종료 노드 (`{name}#exit`): 완료 및 상태 로깅을 처리합니다.

### 예 {#example}

```yaml
components:
  - name: "file_reader"
    type: OneOffComponent
    prompt_id: "read_specific_file"
    prompt_version: "^1.0.0"
    inputs:
      - from: "context:goal"
        as: "target_file"
    toolset:
      - "read_file"
    max_correction_attempts: 2
    ui_log_events:
      - "on_tool_call_input"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
```

## EndComponent 및 AbortComponent {#endcomponent-and-abortcomponent}

둘 다 모든 플로우에서 자동으로 사용 가능합니다. 정의가 필요 없습니다.

| 이름 | 라우터 키 | 상태 설정 | 언제 사용할지 |
|---|---|---|---|
| EndComponent | `"end"` | `COMPLETED` | 워크플로우가 성공적으로 완료되었습니다. |
| AbortComponent | `"abort"` | `ERROR` | 복구할 수 없는 오류, 재시도 소진됨 |

```yaml
routers:
  - from: "my_component"
    to: "end"    # successful completion

  - from: "my_component"
    to: "abort"  # error termination
```

## 라우터 {#routers}

라우터는 각 컴포넌트 완료 후 실행이 컴포넌트 간에 이동하는 방식을 정의합니다.

### 단순 라우터 {#simple-router}

다음 컴포넌트로 조건 없이 라우팅합니다:

```yaml
routers:
  - from: "component_a"
    to: "component_b"
```

### 조건부 라우터 {#conditional-router}

컨텍스트 변수의 값을 기반으로 라우팅합니다:

```yaml
routers:
  - from: "component_a"
    condition:
      input: "context:component_a.final_answer"
      routes:
        "approved": "component_b"
        "rejected": "end"
        "default_route": "end"   # fallback if value matches nothing
```

무음 종료를 방지하기 위해 항상 `"default_route"`을 포함합니다.

## 일반적인 함정 {#common-pitfalls}

| 증상 | 근본 원인 | 해결 |
|---|---|---|
| 에이전트가 프로젝트를 찾을 수 없거나 프로젝트 컨텍스트가 없다고 말합니다 | `project_id`이 컴포넌트 `inputs`에 없습니다 | GitLab API 도구를 호출하는 모든 컴포넌트에 `- from: "context:project_id" as: "project_id"`을 추가하고 `user:` 블록에 `Project ID: {{ project_id }}`을 포함합니다. |
| `primary_branch`이 정의되지 않음 | `flow.inputs` 스탠자가 없습니다 | `agent_platform_standard_context` 스키마와 함께 전체 `flow.inputs` 블록을 추가합니다. |
| HITL 게이트가 UI에 아무것도 표시하지 않음 | `HumanInputComponent`의 `ui_log_events`이 누락됨 | `on_user_input_prompt`과 `on_user_response`를 `ui_log_events`에 추가합니다. |
| 수정에서 `KeyError('<component_name>')` | `sends_response_to`이 아직 실행되지 않은 컴포넌트를 가리킵니다. | `sends_response_to`을 가장 최근에 완료된 에이전트를 가리키도록 합니다. `inputs`을 통해 수정 대상에 피드백을 전달합니다. |
| `modify` 응답이 예기치 않게 `default_route`으로 라우팅됨 | 라우터에 `"modify"` 경로가 누락됨 | `HumanInputComponent` 후 모든 조건부 라우터에 `"modify": "<target_component>"`을 추가합니다. |
| 에이전트가 무한정 반복됨 | 프롬프트에 중단 지시가 없음 | 모든 `system:` 프롬프트를 명시적 완료 지시로 종료합니다. |
| 세션 시작 시 `NoneType: None` 중단 | 에이전트 시스템 프롬프트의 `{{ }}` Jinja2 구문 | 플랫폼은 모델로 전달하기 전에 Jinja2를 통해 시스템 프롬프트를 렌더링합니다. 프롬프트 텍스트의 모든 `{{ variable }}`은 템플릿 변수로 처리됩니다. 문서에서 `<<variable>>` 표기법을 사용하거나 `{% raw %}{{ }}{% endraw %}`으로 이스케이프합니다. |
| 로드 시간에 YAML 구문 분석 오류 | 인라인 프롬프트에서 `unit_primitives: []` 누락 | 비어 있어도 `unit_primitives: []`을 항상 포함합니다. |
| 에이전트가 빈 변수를 수신함 | `as:` 별칭이 `{{ }}` 플레이스홀더와 일치하지 않음 | `inputs`의 `as:` 값이 플레이스홀더 이름과 정확히 일치하는지 확인합니다. |

## 플로우 예 {#flow-examples}

### 로컬 프롬프트가 있는 간단한 ambient 플로우 {#simple-ambient-flow-with-local-prompt}

```yaml
version: "v1"
environment: ambient

components:
  - name: "code_analyzer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    inputs:
      - from: "context:goal"
        as: "mr_link"
    toolset: ["read_file", "list_dir"]
    ui_log_events:
      - "on_agent_final_answer"

prompts:
  - prompt_id: "code_review_prompt"
    name: "Code Review"
    unit_primitives: []
    prompt_template:
      system: |
        You are an experienced software developer. Conduct a thorough code review
        and provide actionable feedback. When complete, your final answer is a
        summary of your findings. No further steps are needed after that.
      user: |
        Please conduct a code review for the merge request at: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "code_analyzer"
    to: "end"

flow:
  entry_point: "code_analyzer"
```

### 제어된 도구 동작을 위한 도구 옵션이 있는 ambient 플로우 {#ambient-flow-with-tool-options-for-controlled-tool-behavior}

```yaml
version: "v1"
environment: ambient

components:
  - name: "security_agent"
    type: AgentComponent
    prompt_id: "security_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_link"
    toolset:
      - "create_merge_request_note":
          "internal": true
      - "get_merge_request"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_agent_final_answer"

  - name: "general_agent"
    type: AgentComponent
    prompt_id: "general_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_link"
    toolset:
      - "create_merge_request_note"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_agent_final_answer"

prompts:
  - prompt_id: "security_prompt"
    name: "Security Analysis Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are a security analyst. Review the MR and leave an internal note
        summarizing any security concerns. When complete, your final answer is
        a confirmation that the note was posted. No further steps are needed.
      user: |
        Project ID: {{ project_id }}
        Merge Request: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

  - prompt_id: "general_prompt"
    name: "General Summary Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are a helpful assistant. Leave a public note on the MR summarizing
        the changes. When complete, your final answer is a confirmation that
        the note was posted. No further steps are needed.
      user: |
        Project ID: {{ project_id }}
        Merge Request: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "security_agent"
    to: "general_agent"
  - from: "general_agent"
    to: "end"

flow:
  entry_point: "security_agent"
```

### HITL 승인 플로우 {#hitl-approval-flow}

이 플로우는 작업을 제안하고 인간 검토를 위해 제시한 다음 승인 시 실행합니다. 올바른 `sends_response_to` 패턴과 세 개의 라우터 경로를 모두 시연합니다.

```yaml
version: "v1"
environment: ambient

components:
  - name: "proposal_agent"
    type: AgentComponent
    prompt_id: "proposal_prompt"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:project_id"
        as: "project_id"
    toolset:
      - "get_issue"
      - "list_issues"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

  - name: "review_gate"
    type: HumanInputComponent
    sends_response_to: "proposal_agent"     # proposal_agent has already run ✅
    interaction_type: "approval"
    message_template: |
      The agent has proposed an action. Please review and choose:
      - ✅ Approve: Proceed with the proposed action
      - ✏️ Modify: Provide feedback - the agent will revise
      - ❌ Reject: Discard
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

  - name: "executor_agent"
    type: AgentComponent
    prompt_id: "executor_prompt"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:project_id"
        as: "project_id"
      - from: "context:proposal_agent.final_answer"
        as: "approved_proposal"
    toolset:
      - "update_issue"
      - "create_issue_note"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

prompts:
  - prompt_id: "proposal_prompt"
    name: "Proposal Agent"
    unit_primitives: []
    prompt_template:
      system: |
        Review the goal and propose a concrete action. Do not execute anything yet.
        When you have formed your proposal, your final answer is a clear description
        of the proposed action. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
      placeholder: history
    params:
      timeout: 180

  - prompt_id: "executor_prompt"
    name: "Executor Agent"
    unit_primitives: []
    prompt_template:
      system: |
        Execute the approved proposal. If the human provided modification feedback,
        it is in your conversation history - incorporate it before executing.
        When execution is complete, your final answer is a confirmation of what
        was done. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
        Approved proposal: {{ approved_proposal }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "proposal_agent"
    to: "review_gate"
  - from: "review_gate"
    condition:
      input: "context:review_gate.approval"
      routes:
        "approve": "executor_agent"
        "modify": "proposal_agent"    # loops back - feedback in proposal_agent history
        "reject": "end"
        "default_route": "end"
  - from: "executor_agent"
    to: "end"

flow:
  entry_point: "proposal_agent"
```

### 모델 크기 기본 설정이 있는 플로우 {#flow-with-model-size-preference}

경량 작업을 더 작은 모델로, 복잡한 작업을 더 큰 모델로 라우팅합니다:

```yaml
version: "v1"
environment: ambient

components:
  - name: "explorer"
    type: AgentComponent
    prompt_id: "explorer_agent"
    prompt_version: "^1.0.0"
    model_size_preference: "small"
    inputs: ["context:goal"]
    toolset:
      - "read_file"
      - "list_dir"
      - "find_files"
    ui_log_events:
      - "on_tool_execution_success"

  - name: "implementer"
    type: AgentComponent
    prompt_id: "implementer_agent"
    prompt_version: "^1.0.0"
    model_size_preference: "large"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:explorer.final_answer"
        as: "codebase_context"
    toolset:
      - "read_file"
      - "edit_file"
      - "create_file_with_contents"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

routers:
  - from: "explorer"
    to: "implementer"
  - from: "implementer"
    to: "end"

flow:
  entry_point: "explorer"
```

### 다중 에이전트 감독자 플로우 {#multi-agent-supervisor-flow}

```yaml
version: "v1"
environment: ambient

components:
  - name: "developer"
    type: AgentComponent
    description: "Implements code changes, creates and edits files based on requirements."
    prompt_id: "developer_agent"
    prompt_version: "^1.0.0"
    toolset:
      - "read_file"
      - "edit_file"
      - "create_file_with_contents"
      - "list_dir"
      - "find_files"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"

  - name: "tester"
    type: AgentComponent
    description: "Writes and runs automated tests to verify code correctness."
    prompt_id: "tester_agent"
    prompt_version: "^1.0.0"
    toolset:
      - "read_file"
      - "create_file_with_contents"
      - "run_command"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"

  - name: "supervisor"
    type: AgentComponent
    prompt_id: "supervisor_agent"
    prompt_version: "^1.0.0"
    inputs: ["context:goal"]
    subagents:
      - name: "developer"
      - name: "tester"
    max_delegations: 20
    toolset:
      - "get_issue"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

routers:
  - from: "supervisor"
    to: "end"

flow:
  entry_point: "supervisor"
```

### 대화형 코드 검토를 위한 Chat-partial 플로우 {#chat-partial-flow-for-conversational-code-review}

```yaml
version: "v1"
environment: chat-partial

components:  # exactly one AgentComponent when using chat-partial
  - name: "code_analyzer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    ui_log_events: ["on_agent_final_answer"]
    inputs:
      - from: "context:goal"
        as: "mr_link"
    toolset: ["read_file", "list_dir"]

prompts:
  - prompt_id: "code_review_prompt"
    name: "Code Review Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are an experienced software developer. Conduct a thorough code review
        and mentor engineers on best practices.
      user: |
        Please conduct a code review for the merge request at: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers: []
flow: {}
```
