---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab MCP 서버를 통해 GitLab과 상호작용할 수 있는 도구들을 사용합니다.
title: GitLab MCP 서버 도구
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

> [!warning]
> 이 기능에 대한 피드백을 제공하려면 [이슈 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)에 댓글을 남기세요.

GitLab MCP 서버는 기존 GitLab 워크플로우와 통합되는 도구 모음을 제공합니다. 이 도구들을 사용하여 GitLab과 직접 상호작용하고 일반적인 GitLab 작업을 수행할 수 있습니다.

## `get_mcp_server_version` {#get_mcp_server_version}

{{< history >}}

- [GitLab 18.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200105).

{{< /history >}}

현재 GitLab MCP 서버의 버전을 반환합니다.

예:

```plaintext
What version of the GitLab MCP server am I connected to?
```

## `create_issue` {#create_issue}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)되었습니다.

{{< /history >}}

GitLab 프로젝트에서 새 이슈를 생성합니다.

| 매개변수      | 형식              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `id`           | 문자열            | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `title`        | 문자열            | 예      | 이슈의 제목입니다. |
| `description`  | 문자열            | 아니요       | 이슈의 설명입니다. |
| `assignee_ids` | 정수 배열 | 아니요       | 할당된 사용자의 ID 배열입니다. |
| `milestone_id` | 정수           | 아니요       | 마일스톤의 ID입니다. |
| `labels`       | 문자열 배열  | 아니요       | 레이블 이름 배열입니다. |
| `confidential` | 부울           | 아니요       | 이슈를 기밀로 설정합니다. 기본값은 `false`입니다. |
| `epic_id`      | 정수           | 아니요       | 연결된 에픽의 ID입니다. |

예:

```plaintext
Create a new issue titled "Fix login bug" in project 123 with description
"Users cannot log in with special characters in password"
```

## `get_issue` {#get_issue}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838)되었습니다.

{{< /history >}}

특정 GitLab 이슈에 대한 자세한 정보를 검색합니다.

| 매개변수   | 형식    | 필수 | 설명 |
|-------------|---------|----------|-------------|
| `id`        | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `issue_iid` | 정수 | 예      | 이슈의 내부 ID입니다. |

예:

```plaintext
Get details for issue 42 in project 123
```

## `create_merge_request` {#create_merge_request}

{{< history >}}

- GitLab 18.5에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/571243).
- `assignee_ids`, `reviewer_ids`, `description`, `labels`, 그리고 `milestone_id` [추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217458) (GitLab 18.8).

{{< /history >}}

GitLab 프로젝트에서 머지 리퀘스트를 생성합니다.

| 매개변수           | 형식              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 문자열            | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `title`             | 문자열            | 예      | 머지 리퀘스트의 제목입니다. |
| `source_branch`     | 문자열            | 예      | 소스 브랜치의 이름입니다. |
| `target_branch`     | 문자열            | 예      | 대상 브랜치의 이름입니다. |
| `target_project_id` | 정수           | 아니요       | 대상 프로젝트의 ID입니다. |
| `assignee_ids`      | 정수 배열 | 아니요       | 머지 리퀘스트 담당자의 ID 배열입니다. `0` 또는 빈 값으로 설정하여 모든 담당자를 할당 해제합니다. |
| `reviewer_ids`      | 정수 배열 | 아니요       | 머지 리퀘스트 검토자의 ID 배열입니다. `0` 또는 빈 값으로 설정하여 모든 검토자를 할당 해제합니다. |
| `description`       | 문자열            | 아니요       | 머지 리퀘스트의 설명입니다. |
| `labels`            | 문자열 배열  | 아니요       | 레이블 이름 배열입니다. 빈 문자열로 설정하여 모든 레이블을 할당 해제합니다. |
| `milestone_id`      | 정수           | 아니요       | 마일스톤의 ID입니다. |

예:

```plaintext
Create a merge request in project gitlab-org/gitlab titled "Bug fix broken specs"
from branch "fix/specs-broken" into "master" and enable squash
```

## `get_merge_request` {#get_merge_request}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838)되었습니다.

{{< /history >}}

특정 GitLab 머지 리퀘스트에 대한 자세한 정보를 검색합니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `id`                | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `merge_request_iid` | 정수 | 예      | 머지 리퀘스트의 내부 ID입니다. |

예:

```plaintext
Get details for merge request 15 in project gitlab-org/gitlab
```

## `get_merge_request_commits` {#get_merge_request_commits}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)되었습니다.

{{< /history >}}

특정 GitLab 머지 리퀘스트의 커밋 목록을 검색합니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `id`                | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `merge_request_iid` | 정수 | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `per_page`          | 정수 | 아니요       | 페이지당 커밋 수입니다. |
| `page`              | 정수 | 아니요       | 현재 페이지 번호입니다. |

예:

```plaintext
Show me all commits in merge request 42 from project 123
```

## `get_merge_request_diffs` {#get_merge_request_diffs}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)되었습니다.

{{< /history >}}

특정 GitLab 머지 리퀘스트의 diff를 검색합니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `id`                | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `merge_request_iid` | 정수 | 예      | 머지 리퀘스트의 내부 ID입니다. |
| `per_page`          | 정수 | 아니요       | 페이지당 diff 수입니다. |
| `page`              | 정수 | 아니요       | 현재 페이지 번호입니다. |

예:

```plaintext
What files were changed in merge request 25 in the gitlab project?
```

## `get_merge_request_pipelines` {#get_merge_request_pipelines}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)되었습니다.

{{< /history >}}

특정 GitLab 머지 리퀘스트의 파이프라인을 검색합니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `id`                | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `merge_request_iid` | 정수 | 예      | 머지 리퀘스트의 내부 ID입니다. |

예:

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

## `create_merge_request_note` {#create_merge_request_note}

{{< history >}}

- [GitLab 19.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/597494).

{{< /history >}}

인증된 사용자로서 GitLab 머지 리퀘스트의 토론에 댓글이나 답글을 추가합니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `url`               | 문자열  | 아니요       | GitLab 머지 리퀘스트의 URL입니다. `project_id` 및 `merge_request_iid`가 누락된 경우 필수입니다. |
| `project_id`        | 문자열  | 아니요       | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. `url`이 누락된 경우 필수입니다. |
| `merge_request_iid` | 정수 | 아니요       | 머지 리퀘스트의 내부 ID입니다. `url`이 누락된 경우 필수입니다. |
| `body`              | 문자열  | 예      | 노트의 내용입니다. 줄이 `/`로 시작할 수 없습니다. 빠른 작업 실행을 피하기 위함입니다 (예: `/merge`). |
| `discussion_id`     | 문자열  | 아니요       | 답글할 토론의 글로벌 ID입니다 (`gid://gitlab/Discussion/<id>` 형식). 누락된 경우 새 최상위 노트를 생성합니다. |

예:

```plaintext
Reply "Thanks, fixed in the latest push" to merge request 42 in project gitlab-org/gitlab
```

## `get_merge_request_notes` {#get_merge_request_notes}

{{< history >}}

- [GitLab 19.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/597494).

{{< /history >}}

특정 GitLab 머지 리퀘스트의 노트(댓글 및 시스템 노트)를 검색합니다.

| 매개변수           | 형식    | 필수 | 설명                                                                                    |
|---------------------|---------|----------|--------------------------------------------------------------------------------------------------|
| `url`               | 문자열  | 아니요       | GitLab 머지 리퀘스트의 URL입니다. `project_id` 및 `merge_request_iid`가 누락된 경우 필수입니다.   |
| `project_id`        | 문자열  | 아니요       | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. `url`이 누락된 경우 필수입니다.                           |
| `merge_request_iid` | 정수 | 아니요       | 머지 리퀘스트의 내부 ID입니다. `url`이 누락된 경우 필수입니다.                                |
| `after`             | 문자열  | 아니요       | 정방향 페이지 매김을 위한 커서입니다.                                                                 |
| `before`            | 문자열  | 아니요       | 역방향 페이지 매김을 위한 커서입니다.                                                                |
| `first`             | 정수 | 아니요       | 정방향 페이지 매김을 위해 반환할 노트 수입니다.                                              |
| `last`              | 정수 | 아니요       | 역방향 페이지 매김을 위해 반환할 노트 수입니다.                                             |

각 반환된 노트는 토론 ID를 포함하므로 관련된 노트를 스레드로 그룹화할 수 있습니다.

예:

```plaintext
Show me all comments on merge request 5 in project gitlab-org/gitlab
```

## `get_pipeline_jobs` {#get_pipeline_jobs}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)되었습니다.

{{< /history >}}

특정 GitLab CI/CD 파이프라인의 작업을 검색합니다.

| 매개변수     | 형식    | 필수 | 설명 |
|---------------|---------|----------|-------------|
| `id`          | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `pipeline_id` | 정수 | 예      | 파이프라인의 ID입니다. |
| `per_page`    | 정수 | 아니요       | 페이지당 작업 수입니다. |
| `page`        | 정수 | 아니요       | 현재 페이지 번호입니다. |

예:

```plaintext
Show me all jobs in pipeline 12345 for project gitlab-org/gitlab
```

## `get_job_log` {#get_job_log}

특정 CI/CD 작업의 추적(로그 출력)을 검색합니다.

| 매개변수 | 형식    | 필수 | 설명 |
|-----------|---------|----------|-------------|
| `id`      | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `job_id`  | 정수 | 예      | 작업의 ID입니다. |

예:

```plaintext
Show me the log output for job 88 in project gitlab-org/gitlab
```

## `manage_pipeline` {#manage_pipeline}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826)되었습니다.

{{< /history >}}

GitLab 프로젝트에서 CI/CD 파이프라인을 관리합니다.

| 매개변수     | 형식    | 필수    | 설명 |
|---------------|---------|-------------|-------------|
| `id`          | 문자열  | 예         | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `list`        | 부울 | 아니요          | `true`인 경우 프로젝트의 모든 파이프라인을 나열합니다. |
| `ref`         | 문자열  | 아니요          | 브랜치 또는 태그 이름입니다. 설정된 경우 브랜치 또는 태그에 새 파이프라인을 생성합니다. 목록 필터링 선택 사항입니다. |
| `pipeline_id` | 정수 | 아니요          | 파이프라인의 ID입니다. 이 매개변수만 설정된 경우 파이프라인 및 모든 관련 데이터를 삭제합니다. |
| `retry`       | 부울 | 아니요          | `true` 및 `pipeline_id`가 설정된 경우 실패하거나 취소된 파이프라인 작업을 재시도합니다. |
| `cancel`      | 부울 | 아니요          | `true` 및 `pipeline_id`가 설정된 경우 실행 중인 파이프라인의 모든 작업을 취소합니다. |
| `name`        | 문자열  | 아니요          | 파이프라인의 이름입니다. 이 매개변수와 `pipeline_id`이 설정된 경우 파이프라인 메타데이터를 업데이트합니다. |
| `variables`   | 배열   | 아니요          | 배열 형식 (`[{key, value, variable_type}]`)의 파이프라인 변수입니다. |
| `inputs`      | 해시    | 아니요          | 키-값 쌍으로 된 파이프라인 입력 매개변수입니다. |
| `page`        | 정수 | 아니요          | 현재 페이지 번호입니다. 기본값은 `1`입니다. |
| `per_page`    | 정수 | 아니요          | 페이지당 항목 수입니다. 기본값은 `20`입니다. |

예:

- 파이프라인 나열:

  ```plaintext
  List all pipelines for project gitlab-org/gitlab
  ```

- 파이프라인 생성:

  ```plaintext
  Create a pipeline on the main branch for project gitlab-org/gitlab
  ```

- 파이프라인 업데이트:

  ```plaintext
  Rename pipeline 12345 to "My deploy pipeline" in project gitlab-org/gitlab
  ```

- 파이프라인 재시도:

  ```plaintext
  Retry failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- 파이프라인 취소:

  ```plaintext
  Cancel pipeline 12345 in project gitlab-org/gitlab
  ```

- 파이프라인 삭제:

  ```plaintext
  Delete pipeline 12345 in project gitlab-org/gitlab
  ```

## `create_workitem_note` {#create_workitem_note}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/581890)되었습니다.

{{< /history >}}

GitLab 작업 항목에 새 노트(댓글)를 생성합니다.

| 매개변수       | 형식    | 필수 | 설명 |
|-----------------|---------|----------|-------------|
| `body`          | 문자열  | 예      | 노트의 내용입니다. |
| `url`           | 문자열  | 아니요       | 작업 항목의 URL입니다. `group_id` 또는 `project_id` 및 `work_item_iid`이 누락된 경우 필수입니다. |
| `group_id`      | 문자열  | 아니요       | 그룹의 ID 또는 경로입니다. `url` 및 `project_id`가 누락된 경우 필수입니다. |
| `project_id`    | 문자열  | 아니요       | 프로젝트의 ID 또는 경로입니다. `url` 및 `group_id`가 누락된 경우 필수입니다. |
| `work_item_iid` | 정수 | 아니요       | 작업 항목의 내부 ID입니다. `url`이 누락된 경우 필수입니다. |
| `internal`      | 부울 | 아니요       | 노트를 내부로 표시합니다(프로젝트의 Reporter, Developer, Maintainer 또는 Owner 역할이 있는 사용자에게만 표시됨). 기본값은 `false`입니다. |
| `discussion_id` | 문자열  | 아니요       | 답글할 토론의 글로벌 ID입니다 (`gid://gitlab/Discussion/<id>` 형식). |

예:

```plaintext
Add a comment "This looks good to me" to work item 42 in project gitlab-org/gitlab
```

## `get_workitem_notes` {#get_workitem_notes}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/581892)되었습니다.

{{< /history >}}

특정 GitLab 작업 항목의 모든 노트(댓글)를 검색합니다.

| 매개변수       | 형식    | 필수 | 설명 |
|-----------------|---------|----------|-------------|
| `url`           | 문자열  | 아니요       | 작업 항목의 URL입니다. `group_id` 또는 `project_id` 및 `work_item_iid`이 누락된 경우 필수입니다. |
| `group_id`      | 문자열  | 아니요       | 그룹의 ID 또는 경로입니다. `url` 및 `project_id`가 누락된 경우 필수입니다. |
| `project_id`    | 문자열  | 아니요       | 프로젝트의 ID 또는 경로입니다. `url` 및 `group_id`가 누락된 경우 필수입니다. |
| `work_item_iid` | 정수 | 아니요       | 작업 항목의 내부 ID입니다. `url`이 누락된 경우 필수입니다. |
| `after`         | 문자열  | 아니요       | 정방향 페이지 매김을 위한 커서입니다. |
| `before`        | 문자열  | 아니요       | 역방향 페이지 매김을 위한 커서입니다. |
| `first`         | 정수 | 아니요       | 정방향 페이지 매김을 위해 반환할 노트 수입니다. |
| `last`          | 정수 | 아니요       | 역방향 페이지 매김을 위해 반환할 노트 수입니다. |

예:

```plaintext
Show me all comments on work item 42 in project gitlab-org/gitlab
```

## `link_work_items` {#link_work_items}

{{< history >}}

- GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230221)되었습니다.

{{< /history >}}

작업 항목을 하나 이상의 다른 작업 항목과 관계 유형으로 연결합니다.

| 매개변수        | 형식             | 필수 | 설명 |
|------------------|------------------|----------|-------------|
| `work_items_ids` | 문자열 배열 | 예      | 연결할 작업 항목의 글로벌 ID입니다 (`gid://gitlab/WorkItem/<id>` 형식). 최대 10개 항목입니다. |
| `url`            | 문자열           | 아니요       | 소스 작업 항목의 URL입니다. `group_id` 또는 `project_id` 및 `work_item_iid`이 누락된 경우 필수입니다. |
| `group_id`       | 문자열           | 아니요       | 그룹의 ID 또는 경로입니다. `url` 및 `project_id`가 누락된 경우 필수입니다. |
| `project_id`     | 문자열           | 아니요       | 프로젝트의 ID 또는 경로입니다. `url` 및 `group_id`가 누락된 경우 필수입니다. |
| `work_item_iid`  | 정수          | 아니요       | 소스 작업 항목의 내부 ID입니다. `url`이 누락된 경우 필수입니다. |
| `link_type`      | 문자열           | 아니요       | 관계 유형입니다. `relates_to`, `blocks`, 또는 `blocked_by` 중 하나입니다. 기본값은 `relates_to`입니다. `blocks` 및 `blocked_by` 유형은 GitLab Premium 또는 Ultimate이 필요합니다. |

예:

```plaintext
Mark work item 42 in project gitlab-org/gitlab as blocked by work item 40
```

## `get_saved_view_work_items` {#get_saved_view_work_items}

{{< history >}}

- GitLab 18.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227911)되었습니다.

{{< /history >}}

네임스페이스에서 저장된 보기와 작업 항목 목록을 검색합니다. 도구는 저장된 보기의 필터와 정렬 순서를 반환된 작업 항목에 적용합니다.

| 매개변수       | 형식    | 필수 | 설명 |
|-----------------|---------|----------|-------------|
| `saved_view_id` | 문자열  | 예      | 저장된 보기의 글로벌 ID입니다 (`gid://gitlab/WorkItems::SavedViews::SavedView/<id>` 형식). |
| `url`           | 문자열  | 아니요       | 네임스페이스(프로젝트 또는 그룹)의 URL입니다. `group_id` 또는 `project_id`이 누락된 경우 필수입니다. |
| `group_id`      | 문자열  | 아니요       | 그룹의 ID 또는 경로입니다. `url` 및 `project_id`가 누락된 경우 필수입니다. |
| `project_id`    | 문자열  | 아니요       | 프로젝트의 ID 또는 경로입니다. `url` 및 `group_id`가 누락된 경우 필수입니다. |
| `after`         | 문자열  | 아니요       | 정방향 페이지 매김을 위한 커서입니다. |
| `first`         | 정수 | 아니요       | 반환할 작업 항목 수입니다. 최대 100입니다. |

예:

```plaintext
Show me the work items in this saved view: <URL>
```

## `search` {#search}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/566143)되었습니다.
- 그룹 및 프로젝트 검색 및 결과 정렬 및 [추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/571132) (GitLab 18.6).
- `gitlab_search`에서 `search`으로 [이름 변경됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214734) (GitLab 18.8).

{{< /history >}}

검색 API를 사용하여 전체 GitLab 인스턴스에서 용어를 검색합니다. 이 도구는 전역, 그룹 및 프로젝트 검색에 사용할 수 있습니다. 사용 가능한 범위는 [검색 유형](../search/_index.md)에 따라 다릅니다.

| 매개변수      | 형식             | 필수 | 설명 |
|----------------|------------------|----------|-------------|
| `scope`        | 문자열           | 예      | 검색 범위 (예: `issues`, `merge_requests`, 또는 `projects`). |
| `search`       | 문자열           | 예      | 검색 용어입니다. |
| `group_id`     | 문자열           | 아니요       | 검색하려는 그룹의 ID 또는 URL 인코딩된 경로입니다. |
| `project_id`   | 문자열           | 아니요       | 검색하려는 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `state`        | 문자열           | 아니요       | 검색 결과의 상태 (`issues` 및 `merge_requests`의 경우). |
| `confidential` | 부울          | 아니요       | 기밀성에 따라 결과를 필터링합니다 (`issues`의 경우). 기본값은 `false`입니다. |
| `fields`       | 문자열 배열 | 아니요       | 검색하려는 필드 배열 (`issues` 및 `merge_requests`의 경우). |
| `order_by`     | 문자열           | 아니요       | 결과를 정렬할 속성입니다. 기본값은 기본 검색의 경우 `created_at`, 고급 검색의 경우 관련성입니다. |
| `sort`         | 문자열           | 아니요       | 결과의 정렬 방향입니다. 기본값은 `desc`입니다. |
| `per_page`     | 정수          | 아니요       | 페이지당 결과 수입니다. 기본값은 `20`입니다. |
| `page`         | 정수          | 아니요       | 현재 페이지 번호입니다. 기본값은 `1`입니다. |

예:

```plaintext
Search issues for "flaky test" across GitLab
```

## `search_labels` {#search_labels}

{{< history >}}

- GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218121)되었습니다.

{{< /history >}}

GitLab 프로젝트 또는 그룹에서 레이블을 검색합니다.

| 매개변수    | 형식    | 필수 | 설명 |
|--------------|---------|----------|-------------|
| `full_path`  | 문자열  | 예      | 프로젝트 또는 그룹의 전체 경로 (예: `group/project`). |
| `is_project` | 부울 | 예      | 프로젝트(`true`) 또는 그룹(`false`)에서 검색할지 여부입니다. |
| `search`     | 문자열  | 아니요       | 제목으로 레이블을 필터링할 검색 용어입니다. |

그룹 레이블을 검색할 때 결과에는 상위 그룹 및 하위 그룹의 레이블이 포함됩니다.

예:

```plaintext
Show me all labels in project gitlab-org/gitlab
```

## `semantic_code_search` {#semantic_code_search}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.5에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/569624) ([실험](../../policy/development_stages_support.md#experiment)으로) [기능 플래그](../../administration/feature_flags/_index.md) `code_snippet_search_graphqlapi` 포함. 기본적으로 비활성화되었습니다.
- 프로젝트 경로로 검색 [추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/575234) (GitLab 18.6).
- 실험에서 [베타](../../policy/development_stages_support.md#beta)로 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/568359) (GitLab 18.7). `code_snippet_search_graphqlapi` 기능 플래그가 제거되었습니다.
- GitLab 18.7에서 GitLab UI에 [추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/581105) [기능 플래그](../../administration/feature_flags/_index.md) `mcp_client` 포함. 기본적으로 비활성화되었습니다.
- GitLab 18.11에서 [REST API](../../api/search.md#semantic-search)를 사용하도록 [업데이트됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228569) [기능 플래그](../../administration/feature_flags/_index.md) `mcp_semantic_code_search_use_rest_api` 포함. 기본적으로 비활성화되었습니다.
- REST API 사용 GitLab 19.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239364). `mcp_semantic_code_search_use_rest_api` 기능 플래그가 제거되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능 여부는 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

GitLab 프로젝트에서 관련 코드 스니펫을 검색합니다. 자세한 내용은 설정 및 활성화를 포함하여 [의미론적 코드 검색](../gitlab_duo/semantic_code_search.md)을 참조하세요.

| 매개변수        | 형식    | 필수 | 설명 |
|------------------|---------|----------|-------------|
| `semantic_query` | 문자열  | 예      | 코드의 검색 쿼리입니다. |
| `project_id`     | 문자열  | 예      | 프로젝트의 ID 또는 경로입니다. |
| `directory_path` | 문자열  | 아니요       | 디렉터리 경로 (예: `app/services/`). |
| `knn`            | 정수 | 아니요       | 유사한 코드 스니펫을 찾기 위해 사용되는 최근방 이웃 수입니다. 기본값은 `64`입니다. |
| `limit`          | 정수 | 아니요       | 반환할 최대 결과 수입니다. 기본값은 `20`입니다. |

최선의 결과를 위해 일반적인 키워드나 특정 함수 또는 변수 이름을 사용하는 것보다 관심 있는 기능이나 동작을 설명합니다.

예:

```plaintext
How are authorizations managed in this project?
```

## `attach_scan_profile` {#attach_scan_profile}

{{< history >}}

- [GitLab 19.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240685).

{{< /history >}}

지정된 보안 검사 프로필을 지정된 프로젝트에 또는 지정된 그룹 아래의 모든 프로젝트에 연결합니다.

| 매개변수                  | 형식             | 필수 | 설명 |
|----------------------------|------------------|----------|-------------|
| `security_scan_profile_id` | 문자열           | 예      | 보안 검사 프로필의 글로벌 ID (예: `gid://gitlab/Security::ScanProfile/1`). |
| `project_ids`              | 문자열 배열 | 아니요       | 프로젝트의 글로벌 ID 배열 (예: `[gid://gitlab/Project/1]`). `group_ids`가 제공되지 않으면 필수입니다. |
| `group_ids`                | 문자열 배열 | 아니요       | 그룹의 글로벌 ID 배열 (예: `[gid://gitlab/Group/1]`). `project_ids`가 제공되지 않으면 필수입니다. |

예:

```plaintext
Attach `gid://gitlab/Security::ScanProfile/1` to all projects under `gid://gitlab/Group/1`.
```
