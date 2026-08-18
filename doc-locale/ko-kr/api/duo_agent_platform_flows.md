---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo Agent Platform 플로우를 생성하고 시작하며 관리하는 REST API입니다.
title: 플로우 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [플로우](../user/duo_agent_platform/flows/_index.md)를 [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md)에서 생성하고 관리합니다. 플로우는 버그 수정, 코드 작성 또는 취약점 해결과 같은 개발자 작업을 완료하기 위해 함께 작동하는 AI 에이전트의 조합입니다.

## 플로우 생성 {#create-a-flow}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

새로운 플로우를 생성하고 시작합니다.

```plaintext
POST /ai/duo_workflows/workflows
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|-----------|------|----------|-------------|
| `additional_context` | 객체 배열 | 아니요 | 플로우에 대한 추가 컨텍스트입니다. 각 요소는 최소한 `Category`(문자열) 및 `Content`(문자열, 직렬화된 JSON) 키를 포함하는 객체여야 합니다. |
| `agent_privileges` | 정수 배열 | 아니요 | 에이전트가 사용할 수 있는 권한 ID입니다. 모든 권한으로 기본 설정됩니다. [모든 에이전트 권한 나열](#list-all-agent-privileges)을 참조하세요. |
| `ai_catalog_item_consumer_id` | 정수 | 아니요 | 실행할 카탈로그 항목을 구성하는 AI 카탈로그 항목 소비자의 ID입니다. `project_id`을(를) 필요로 합니다. `workflow_definition`과 함께 사용할 수 없습니다. 둘 다 제공되는 경우 `ai_catalog_item_consumer_id`이 우선합니다. [소비자 ID 조회](#look-up-the-consumer-id)를 참조하세요. |
| `ai_catalog_item_version_id` | 정수 | 아니요 | 플로우 구성의 출처인 AI 카탈로그 항목 버전의 ID입니다. |
| `allow_agent_to_request_user` | 부울 | 아니요 | `true`(기본값)일 때 에이전트가 진행하기 전에 사용자에게 질문을 할 수 있습니다. `false`일 때 에이전트는 사용자 입력 없이 완료까지 실행됩니다. |
| `environment` | 문자열 | 아니요 | 실행 환경입니다. 다음 중 하나입니다: `ide`, `web`, `chat_partial`, `chat`, `ambient`. |
| `goal` | 문자열 | 아니요 | 에이전트가 완료해야 할 작업에 대한 설명입니다. 예: `Fix the failing pipeline`. |
| `image` | 문자열 | 아니요 | CI 파이프라인에서 플로우를 실행할 때 사용할 컨테이너 이미지입니다. [사용자 지정 이미지 요구 사항](../user/duo_agent_platform/flows/execution.md#custom-image-requirements)을 충족해야 합니다. 예: `registry.gitlab.com/gitlab-org/duo-workflow/custom-image:latest`. |
| `issue_id` | 정수 | 아니요 | 플로우와 연결할 이슈의 IID입니다. `project_id`을(를) 필요로 합니다. |
| `merge_request_id` | 정수 | 아니요 | 플로우와 연결할 머지 리퀘스트의 IID입니다. `project_id`을(를) 필요로 합니다. |
| `namespace_id` | 문자열 | 아니요 | 플로우와 연결할 네임스페이스의 ID 또는 경로입니다. |
| `pre_approved_agent_privileges` | 정수 배열 | 아니요 | 사용자 승인을 요청하지 않고 에이전트가 사용할 수 있는 권한 ID입니다. `agent_privileges`의 부분 집합이어야 합니다. |
| `project_id` | 문자열 | 아니요 | 플로우와 연결할 프로젝트의 ID 또는 경로입니다. |
| `shallow_clone` | 부울 | 아니요 | 실행 중에 리포지토리의 얕은 복제를 사용할지 여부입니다. 기본값: `true`. |
| `source_branch` | 문자열 | 아니요 | CI 파이프라인의 소스 브랜치입니다. 프로젝트의 기본 브랜치로 기본값이 설정됩니다. |
| `start_workflow` | 부울 | 아니요 | `true`일 때 생성 후 즉시 플로우를 시작합니다. |
| `workflow_definition` | 문자열 | 아니요 | 플로우 유형 식별자입니다. 예: `developer/v1`. `ai_catalog_item_consumer_id`과 함께 사용할 수 없습니다. 둘 다 제공되는 경우 `ai_catalog_item_consumer_id`이 우선합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|-----------|------|-------------|
| `agent_privileges` | 정수 배열 | 에이전트에 할당된 권한 ID입니다. |
| `agent_privileges_names` | 문자열 배열 | `agent_privileges`에 해당하는 이름입니다. |
| `ai_catalog_item_version_id` | 정수 | AI 카탈로그 항목 버전의 ID입니다. 설정되지 않으면 `null`입니다. |
| `allow_agent_to_request_user` | 부울 | `true`일 때 에이전트가 사용자 입력을 위해 일시 중지할 수 있습니다. |
| `environment` | 문자열 | 실행 환경입니다. 설정되지 않으면 `null`입니다. |
| `gitlab_url` | 문자열 | GitLab 인스턴스의 기본 URL입니다. |
| `id` | 정수 | 플로우의 ID입니다. |
| `image` | 문자열 | CI 파이프라인 실행을 위한 컨테이너 이미지입니다. 설정되지 않으면 `null`입니다. |
| `mcp_enabled` | 부울 | `MCP` (Model Context Protocol) 도구가 이 플로우에 대해 활성화되어 있는지 여부입니다. |
| `namespace_id` | 정수 | 연결된 네임스페이스의 ID입니다. 설정되지 않으면 `null`입니다. |
| `pre_approved_agent_privileges` | 정수 배열 | 승인을 요청하지 않고 에이전트가 사용할 수 있는 권한 ID입니다. |
| `pre_approved_agent_privileges_names` | 문자열 배열 | `pre_approved_agent_privileges`에 해당하는 이름입니다. |
| `project_id` | 정수 | 연결된 프로젝트의 ID입니다. 설정되지 않으면 `null`입니다. |
| `status` | 문자열 | 현재 플로우 상태입니다. 다음 중 하나입니다: `created`, `running`, `paused`, `finished`, `failed`, `stopped`, `input_required`, `plan_approval_required`, 또는 `tool_call_approval_required`. |
| `summary` | 문자열 | workflow의 간단한 텍스트 요약입니다. |
| `title` | 문자열 | 세션의 제목입니다. |
| `workflow_definition` | 문자열 | 플로우 유형 식별자입니다. |
| `workload` | 객체 | 워크로드에 대한 정보입니다. |
| `workload.id` | 문자열 | 워크로드의 ID입니다. |
| `workload.message` | 문자열 | 워크로드에 대한 상태 메시지입니다. |

### 소비자 ID 조회 {#look-up-the-consumer-id}

`ai_catalog_item_consumer_id`을 사용하기 전에 GraphQL API를 사용하여 [AI 카탈로그](../user/duo_agent_platform/ai_catalog.md)에서 ID를 검색해야 합니다. 항목이 프로젝트에 대해 이미 활성화되어 있어야 합니다.

```graphql
query {
  aiCatalogConfiguredItems(projectId: "gid://gitlab/Project/<project_id>") {
    nodes {
      id
      item { name }
    }
  }
}
```

`id` 필드는 `gid://gitlab/AiCatalogItemConsumer/<numeric_id>` 형식의 전역 ID입니다. 숫자 접미사를 `ai_catalog_item_consumer_id` 값으로 사용합니다.

기본 제공 플로우 유형을 사용한 예 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "workflow_definition": "developer/v1",
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

카탈로그로 구성된 플로우를 사용한 예 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "ai_catalog_item_consumer_id": 12,
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

응답 예시:

```json
{
  "id": 1,
  "project_id": 5,
  "namespace_id": null,
  "agent_privileges": [1, 2, 3, 4, 5, 6],
  "agent_privileges_names": [
    "read_write_files",
    "read_only_gitlab",
    "read_write_gitlab",
    "run_commands",
    "use_git",
    "run_mcp_tools"
  ],
  "pre_approved_agent_privileges": [],
  "pre_approved_agent_privileges_names": [],
  "workflow_definition": "developer/v1",
  "status": "running",
  "allow_agent_to_request_user": true,
  "image": null,
  "environment": null,
  "ai_catalog_item_version_id": null,
  "workload": {
    "id": "abc-123",
    "message": "Workflow started"
  },
  "mcp_enabled": false,
  "gitlab_url": "https://gitlab.example.com"
}
```

## 모든 에이전트 권한 나열 {#list-all-agent-privileges}

모든 사용 가능한 에이전트 권한을 ID, 이름, 설명 및 각 권한이 기본적으로 활성화되어 있는지 여부를 나열합니다.

```plaintext
GET /ai/duo_workflows/workflows/agent_privileges
```

이 엔드포인트는 지원되는 특성이 없습니다.

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|-----------|------|-------------|
| `all_privileges` | 객체 배열 | 사용 가능한 모든 에이전트 권한입니다. |
| `all_privileges[].default_enabled` | 부울 | 권한이 기본적으로 활성화되어 있는지 여부입니다. |
| `all_privileges[].description` | 문자열 | 권한이 허용하는 작업에 대한 사람이 읽을 수 있는 설명입니다. |
| `all_privileges[].id` | 정수 | 권한 ID입니다. |
| `all_privileges[].name` | 문자열 | 기계가 읽을 수 있는 권한 이름입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows/agent_privileges"
```

응답 예시:

```json
{
  "all_privileges": [
    {
      "id": 1,
      "name": "read_write_files",
      "description": "Allow local filesystem read/write access",
      "default_enabled": true
    },
    {
      "id": 2,
      "name": "read_only_gitlab",
      "description": "Allow read only access to GitLab APIs",
      "default_enabled": true
    },
    {
      "id": 3,
      "name": "read_write_gitlab",
      "description": "Allow write access to GitLab APIs",
      "default_enabled": true
    },
    {
      "id": 4,
      "name": "run_commands",
      "description": "Allow running any commands",
      "default_enabled": true
    },
    {
      "id": 5,
      "name": "use_git",
      "description": "Allow git commits, push and other git commands",
      "default_enabled": true
    },
    {
      "id": 6,
      "name": "run_mcp_tools",
      "description": "Allow running MCP tools",
      "default_enabled": true
    }
  ]
}
```
