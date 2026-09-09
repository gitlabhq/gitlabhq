---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab MCP 서버를 통해 GitLab과 상호작용할 수 있는 도구들을 사용합니다.
title: GitLab MCP 서버 도구
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

> [!warning]
> 이 기능에 대한 피드백을 제공하려면 [이슈 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)에 댓글을 남기세요.

GitLab MCP 서버는 기존 GitLab 워크플로우와 통합되는 도구 모음을 제공합니다. 이 도구들을 사용하여 GitLab과 직접 상호작용하고 일반적인 GitLab 작업을 수행할 수 있습니다.

## `get_mcp_server_version` {#get_mcp_server_version}

{{< history >}}

- GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200105)되었습니다.

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

GitLab 프로젝트에서 새 이슈를 만듭니다.

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

- GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/571243)되었습니다.
- `assignee_ids`, `reviewer_ids`, `description`, `labels`, 그리고 `milestone_id` [추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217458)(GitLab 18.8).

{{< /history >}}

GitLab 프로젝트에서 병합 요청을 만듭니다.

| 매개변수           | 형식              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 문자열            | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `title`             | 문자열            | 예      | 병합 요청의 제목입니다. |
| `source_branch`     | 문자열            | 예      | 소스 브랜치의 이름입니다. |
| `target_branch`     | 문자열            | 예      | 대상 브랜치의 이름입니다. |
| `target_project_id` | 정수           | 아니요       | 대상 프로젝트의 ID입니다. |
| `assignee_ids`      | 정수 배열 | 아니요       | 병합 요청 담당자의 ID 배열입니다. `0` 또는 빈 값으로 설정하여 모든 담당자를 할당 해제합니다. |
| `reviewer_ids`      | 정수 배열 | 아니요       | 병합 요청 검토자의 ID 배열입니다. `0` 또는 빈 값으로 설정하여 모든 검토자를 할당 해제합니다. |
| `description`       | 문자열            | 아니요       | 병합 요청의 설명입니다. |
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
- [GitLab 19.3에서](https://gitlab.com/gitlab-org/gitlab/-/issues/605878) `url`을 수락하고 관련 데이터 패싯을 반환하도록 변경되었습니다.

{{< /history >}}

병합 요청을 검색하고 선택 사항으로 diff, 커밋, 메모, 파이프라인 또는 토론을 검색합니다. `include` 매개변수로 관련 데이터를 요청하지 않으면 기본 병합 요청만 반환됩니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `url`               | 문자열  | 아니요       | 병합 요청의 GitLab URL입니다. 이를 제공하거나 `project_id` 및 `merge_request_iid`을 제공합니다. |
| `project_id`        | 문자열  | 아니요       | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. `url`이 누락된 경우 필수입니다. |
| `merge_request_iid` | 정수 | 아니요       | 병합 요청의 내부 ID입니다. `url`이 누락된 경우 필수입니다. |
| `include`           | 배열   | 아니요       | 병합 요청과 함께 반환할 관련 패싯입니다. `diffs`, `commits`, `notes`, `pipelines`, 또는 `discussions` 중 하나입니다. 호출당 하나의 패싯으로 제한됩니다. |
| `notes_after`       | 문자열  | 아니요       | notes에 대한 forward pagination 커서입니다. `include`이 `["notes"]`일 때만 적용됩니다. |
| `notes_first`       | 정수 | 아니요       | 커서 뒤에 반환할 notes 수, 최대 100개입니다. `include`이 `["notes"]`일 때만 적용됩니다. |

`diffs` 패싯은 변경 통계만 반환합니다. 전체 합계 및 파일별 추가 및 삭제 항목입니다. 패치 텍스트를 가져오려면 `get_merge_request_diffs`을 사용합니다.

예:

```plaintext
Get merge request 15 in project gitlab-org/gitlab with its commits
```

## `list_duo_sessions` {#list_duo_sessions}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248587)되었습니다.

{{< /history >}}

Duo Chat 세션을 제외한 GitLab Duo Agent Platform 세션을 나열합니다. 각 세션에는 개별 상태, 목표 미리 보기, 플로우 정의 및 만들기 타임스탬프가 포함됩니다. 프로젝트 세션에는 세션 URL도 포함됩니다. 목표 미리보기가 잘릴 수 있습니다.

| 매개변수      | 형식    | 필수 | 설명 |
|----------------|---------|----------|-------------|
| `url`          | 문자열  | 아니요       | 세션을 필터링할 프로젝트의 GitLab URL입니다. `project_id`과 함께 사용하지 마십시오. |
| `project_id`   | 문자열  | 아니요       | 세션을 필터링할 프로젝트의 숫자 ID 또는 전체 경로입니다. `url`과 함께 사용하지 마십시오. |
| `status_group` | 문자열  | 아니요       | 세션 상태 그룹입니다. `active`, `paused`, `awaiting_input`, `completed`, `failed`, 또는 `canceled` 중 하나입니다. |
| `after`        | 문자열  | 아니요       | 정방향 페이지 매김을 위한 커서입니다. |
| `first`        | 정수 | 아니요       | forward pagination을 위해 반환할 세션 수입니다. 기본값은 20, 최대값은 100입니다. |

`status_group` 필터는 여러 개별 상태를 가진 세션을 반환할 수 있습니다. 각 호출은 결과의 단일 페이지를 반환합니다. 더 많은 페이지가 있으면 응답에 `pageInfo.endCursor`이 포함되며 이를 `after`으로 전달할 수 있습니다.

예:

```plaintext
List my active Duo Agent Platform sessions in gitlab-org/gitlab
```

## `list_merge_requests` {#list_merge_requests}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246413)되었습니다.

{{< /history >}}

GitLab 프로젝트에서 병합 요청을 나열하거나 검색하여 컴팩트 병합 요청 메타데이터를 반환합니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `url`               | 문자열  | 아니요       | 프로젝트의 URL입니다. `url` 또는 `project_id` 중 정확히 하나를 제공합니다. |
| `project_id`        | 문자열  | 아니요       | 프로젝트의 ID 또는 전체 경로입니다. `url` 또는 `project_id` 중 정확히 하나를 제공합니다. |
| `author_username`   | 문자열  | 아니요       | 병합 요청 작성자의 사용자명으로 필터링합니다. |
| `assignee_username` | 문자열  | 아니요       | 담당자의 사용자명으로 필터링합니다. |
| `reviewer_username` | 문자열  | 아니요       | 검토자의 사용자명으로 필터링합니다. |
| `state`             | 문자열  | 아니요       | 상태로 필터링합니다. `opened`, `closed`, `merged`, `locked`, 또는 `all` 중 하나입니다. 모든 상태를 포함하려면 생략합니다. |
| `scope`             | 문자열  | 아니요       | 인증된 사용자를 기준으로 필터링합니다. `created_by_me`, `assigned_to_me` 또는 `review_requested` 중 하나입니다. 명시적 사용자명이 해당 필드에서 우선합니다. |
| `milestone`         | 문자열  | 아니요       | 마일스톤 제목으로 필터링합니다. |
| `labels`            | 문자열  | 아니요       | 쉼표로 구분된 레이블 이름 목록입니다. 이러한 모든 레이블을 가진 병합 요청만 반환됩니다. |
| `search`            | 문자열  | 아니요       | 병합 요청 제목 및 설명과 비교되는 검색 쿼리입니다. |
| `after`             | 문자열  | 아니요       | 정방향 페이지 매김을 위한 커서입니다. |
| `first`             | 정수 | 아니요       | forward pagination을 위해 반환할 병합 요청 수입니다. 기본값은 20, 최대값은 100입니다. |

단일 병합 요청을 완전히 세부적으로 검색하려면 `get_merge_request`을 사용합니다. 이 diffs, 커밋, notes는 `get_merge_request_diffs`, `get_merge_request_commits`, `get_merge_request_notes`에서 사용할 수 있습니다. 리소스 유형 전체에 대한 전체 텍스트 검색을 위해 `search`을 사용합니다.

예:

```plaintext
List my open merge requests in gitlab-org/gitlab
```

## `get_merge_request_commits` {#get_merge_request_commits}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)되었습니다.

{{< /history >}}

특정 GitLab 병합 요청의 커밋 목록을 검색합니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `id`                | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `merge_request_iid` | 정수 | 예      | 병합 요청의 내부 ID입니다. |
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

특정 GitLab 병합 요청의 diff를 검색합니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `id`                | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `merge_request_iid` | 정수 | 예      | 병합 요청의 내부 ID입니다. |
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

특정 GitLab 병합 요청의 파이프라인을 검색합니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `id`                | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `merge_request_iid` | 정수 | 예      | 병합 요청의 내부 ID입니다. |

예:

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

## `create_merge_request_note` {#create_merge_request_note}

{{< history >}}

- GitLab 19.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/597494)되었습니다.

{{< /history >}}

인증된 사용자로서 GitLab 병합 요청의 토론에 댓글이나 답글을 추가합니다.

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `url`               | 문자열  | 아니요       | GitLab 병합 요청의 URL입니다. `project_id` 및 `merge_request_iid`가 누락된 경우 필수입니다. |
| `project_id`        | 문자열  | 아니요       | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. `url`이 누락된 경우 필수입니다. |
| `merge_request_iid` | 정수 | 아니요       | 병합 요청의 내부 ID입니다. `url`이 누락된 경우 필수입니다. |
| `body`              | 문자열  | 예      | 노트의 내용입니다. 줄이 `/`로 시작할 수 없습니다. 빠른 작업 실행을 피하기 위함입니다(예: `/merge`). |
| `discussion_id`     | 문자열  | 아니요       | 회신할 토론의 전역 ID입니다(`gid://gitlab/Discussion/<id>` 형식). 누락된 경우 새 최상위 수준 메모를 만듭니다. |

예:

```plaintext
Reply "Thanks, fixed in the latest push" to merge request 42 in project gitlab-org/gitlab
```

## `get_merge_request_notes` {#get_merge_request_notes}

{{< history >}}

- GitLab 19.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/597494)되었습니다.

{{< /history >}}

특정 GitLab 병합 요청의 노트(댓글 및 시스템 노트)를 검색합니다.

| 매개변수           | 형식    | 필수 | 설명                                                                                    |
|---------------------|---------|----------|--------------------------------------------------------------------------------------------------|
| `url`               | 문자열  | 아니요       | GitLab 병합 요청의 URL입니다. `project_id` 및 `merge_request_iid`가 누락된 경우 필수입니다.   |
| `project_id`        | 문자열  | 아니요       | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. `url`이 누락된 경우 필수입니다.                           |
| `merge_request_iid` | 정수 | 아니요       | 병합 요청의 내부 ID입니다. `url`이 누락된 경우 필수입니다.                                |
| `after`             | 문자열  | 아니요       | 정방향 페이지 매김을 위한 커서입니다.                                                                 |
| `before`            | 문자열  | 아니요       | 역방향 페이지 매김을 위한 커서입니다.                                                                |
| `first`             | 정수 | 아니요       | 정방향 페이지 매김을 위해 반환할 노트 수입니다.                                              |
| `last`              | 정수 | 아니요       | 역방향 페이지 매김을 위해 반환할 노트 수입니다.                                             |

각 반환된 노트는 토론 ID를 포함하므로 관련된 노트를 스레드로 그룹화할 수 있습니다.

예:

```plaintext
Show me all comments on merge request 5 in project gitlab-org/gitlab
```

## `save_merge_request_review` {#save_merge_request_review}

{{< history >}}

- GitLab 19.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/605881)되었습니다.

{{< /history >}}

인증된 사용자로서 병합 요청 검토 아티팩트를 작성합니다. 각 호출은 `method` 매개변수로 선택된 정확히 하나의 작업을 수행합니다.

| 메서드               | 작업 |
|----------------------|--------|
| `create_note`        | 최상위 수준 댓글을 추가합니다. |
| `reply_discussion`   | 기존 discussion에 회신합니다. |
| `create_diff_note`   | 특정 diff 라인에 댓글을 답니다. |
| `resolve_discussion` | Discussion을 해결하거나 해제합니다. |
| `submit_review`      | 여러 diff 댓글 및 선택적 요약을 한 번의 호출로 게시합니다. |
| `post_duo_review`    | GitLab Duo에 병합 요청을 검토하도록 요청합니다. GitLab Duo Code Review가 필요합니다. |

| 매개변수           | 형식    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `url`               | 문자열  | 아니요       | GitLab 병합 요청의 URL입니다. `project_id` 및 `merge_request_iid`가 누락된 경우 필수입니다. |
| `project_id`        | 문자열  | 아니요       | 프로젝트의 ID 또는 경로입니다. `url`이 누락된 경우 필수입니다. |
| `merge_request_iid` | 정수 | 아니요       | 병합 요청의 내부 ID입니다. `url`이 누락된 경우 필수입니다. |
| `method`            | 문자열  | 예      | 수행할 작업입니다. 다른 메서드에 속하는 매개변수는 거부됩니다. |
| `body`              | 문자열  | 아니요       | 참고 텍스트입니다. `create_note`, `reply_discussion`, `create_diff_note`에 필수입니다. 빠른 작업을 트리거하는 것을 피하기 위해(예: `/merge`) 줄은 `/`로 시작할 수 없습니다. |
| `discussion_id`     | 문자열  | 아니요       | 작업할 discussion입니다. `reply_discussion` 및 `resolve_discussion`에 필수입니다. 전역 ID 또는 베어 discussion ID를 수락합니다. |
| `internal`          | 부울 | 아니요       | `create_note`의 경우 참고를 내부로 표시합니다. |
| `resolved`          | 부울 | 아니요       | `resolve_discussion`의 경우 `true`은 해결하고 `false`은 해제합니다. 해당 메서드에 필수입니다. |
| `old_path`          | 문자열  | 아니요       | `create_diff_note`의 경우 변경 전 파일 경로입니다. `old_path` 또는 `new_path` 중 하나 또는 둘 다를 제공합니다. |
| `new_path`          | 문자열  | 아니요       | `create_diff_note`의 경우 변경 후 파일 경로입니다. |
| `old_line`          | 정수 | 아니요       | `create_diff_note`의 경우 이전 버전의 라인 번호입니다. `old_line` 또는 `new_line` 중 하나 또는 둘 다를 제공합니다. |
| `new_line`          | 정수 | 아니요       | `create_diff_note`의 경우 새 버전의 라인 번호입니다. |
| `comments`          | 배열   | 아니요       | `submit_review`의 경우 1-20개의 diff 댓글입니다. 각 항목은 `file` 및 `body`(필수)과 `old_line`, `new_line`, `suggestion`(선택사항)을 사용합니다. 해당 메서드에 필수입니다. `file`은 변경 후 경로입니다. 이름이 바뀐 파일의 경우 대신 `create_diff_note`을 사용합니다. |
| `verdict`           | 문자열  | 아니요       | `submit_review`의 경우 요약 참고에 앞서는 전체적인 판정입니다. |
| `summary`           | 문자열  | 아니요       | `submit_review`의 경우 diff 댓글 후에 게시된 요약 참고입니다. |
| `summary_internal`  | 부울 | 아니요       | `submit_review`의 경우 요약 참고를 내부로 표시합니다. |

예:

```plaintext
Review merge request 42 in project gitlab-org/gitlab and leave your findings as diff comments with a summary
```

## `add_branch` {#add_branch}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/605877)되었습니다. `create_branch`은 별칭으로도 허용됩니다.

{{< /history >}}

원본 ref에서 GitLab 프로젝트에 브랜치를 추가합니다.

| 매개변수    | 형식   | 필수 | 설명 |
|--------------|--------|----------|-------------|
| `url`        | 문자열 | 아니요       | 프로젝트의 GitLab URL입니다. 이를 제공하거나 `project_id`을 제공합니다. |
| `project_id` | 문자열 | 아니요       | 프로젝트의 ID 또는 경로입니다. `url`이 제공되지 않으면 필수입니다. |
| `branch`     | 문자열 | 예      | 새 브랜치의 이름입니다. |
| `ref`        | 문자열 | 예      | 새 브랜치를 만들 브랜치 이름 또는 커밋 SHA입니다. |

예:

```plaintext
Create a branch named feature/x from main in project gitlab-org/gitlab
```

## `get_repository_file` {#get_repository_file}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248744)되었습니다.

{{< /history >}}

특정 ref에서 리포지토리의 단일 파일 내용을 검색합니다.

내용은 로컬 파일 시스템이 아닌 리포지토리에서 제공됩니다. 파일은 `ref`에서 커밋된 것으로 반환되므로 로컬 체크아웃의 커밋되지 않은 변경 사항은 포함되지 않습니다.

| 매개변수    | 형식    | 필수 | 설명 |
|--------------|---------|----------|-------------|
| `url`        | 문자열  | 아니요       | 파일의 URL(예: `https://gitlab.example.com/my-group/my-project/-/blob/main/app/models/user.rb`)입니다. 이를 제공하거나 `project_id`, `file_path`, `ref`을 제공합니다. |
| `project_id` | 문자열  | 아니요       | 프로젝트의 ID 또는 전체 경로입니다. `url`이 제공되지 않으면 필수입니다. |
| `file_path`  | 문자열  | 아니요       | 리포지토리 루트 기준 파일의 경로입니다. `url`이 제공되지 않으면 필수입니다. |
| `ref`        | 문자열  | 아니요       | 브랜치 이름, 태그 이름 또는 커밋 SHA입니다. 기본 브랜치에 `HEAD`을 사용합니다. `url`이 제공되지 않으면 필수입니다. |
| `offset`     | 정수 | 아니요       | 읽기를 시작할 0부터 시작하는 라인입니다. 기본값은 `0`입니다. |
| `limit`      | 정수 | 아니요       | 반환할 최대 라인 수입니다. 기본값 및 최대값은 `2000`입니다. |

응답에는 `metadata` 개체가 포함되어 있으며 `total_lines`, `returned_lines`, `truncated`, `size_bytes`가 있습니다. 응답이 파일의 일부만 다루는 경우 `system_instruction`는 다음 호출에서 사용할 `offset`을 설명합니다.

이 도구는 텍스트만 반환합니다. 바이너리 파일 및 Git LFS에 저장된 파일은 오류를 반환합니다. 프로젝트가 GitLab Duo 컨텍스트에서 제외하는 파일도 오류를 반환합니다.

예:

```plaintext
Show me app/models/user.rb from the main branch of my-group/my-project
```

## `get_commit` {#get_commit}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/605874)되었습니다.

{{< /history >}}

단일 커밋의 메타데이터 및 선택적으로 해당 diff 또는 notes를 검색합니다.

| 매개변수     | 형식    | 필수 | 설명 |
|---------------|---------|----------|-------------|
| `url`         | 문자열  | 아니요       | GitLab 커밋의 URL입니다. `project_id` 및 `commit_sha`이 제공되지 않으면 필수입니다. |
| `project_id`  | 문자열  | 아니요       | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. `url`이 제공되지 않으면 필수입니다. |
| `commit_sha`  | 문자열  | 아니요       | 조회할 커밋입니다. 전체 또는 짧은 SHA, 브랜치 이름 또는 태그 이름을 수락합니다. `url`이 제공되지 않으면 필수입니다. |
| `include`     | 배열   | 아니요       | 인라인으로 가져올 관련 패싯, 호출당 하나(`diff` 또는 `notes`)입니다. 기본 메타데이터는 항상 반환됩니다. |
| `diff_detail` | 문자열  | 아니요       | 커밋 diff의 세부 정보 수준입니다. `include`에 `diff`이 포함될 때만 적용됩니다. `stats` 또는 `full_patch` 중 하나입니다. 기본값은 `stats`입니다. |
| `notes_after` | 문자열  | 아니요       | notes의 다음 페이지를 가져올 토큰입니다. `include`에 `notes`이 포함될 때만 적용됩니다. |
| `notes_first` | 정수 | 아니요       | 페이지당 반환할 notes 수(최대 100)입니다. `include`에 `notes`이 포함될 때만 적용됩니다. |

`diff_detail`이 `stats`로 설정된 경우 diff 패싯은 파일별 및 요약 라인 수를 반환합니다. `full_patch`의 경우 패치 텍스트를 반환합니다.

예:

```plaintext
Show me commit abc123 in gitlab-org/gitlab with its diff stats
```

## `get_pipeline` {#get_pipeline}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/605853)되었습니다.

{{< /history >}}

파이프라인 및 선택적으로 작업, 다운스트림 파이프라인 또는 bridge(작업) 작업을 검색합니다.

| 매개변수     | 형식    | 필수 | 설명 |
|---------------|---------|----------|-------------|
| `id`          | 문자열  | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `pipeline_id` | 정수 | 예      | 파이프라인의 ID입니다. |
| `include`     | 배열   | 아니요       | 파이프라인과 함께 포함할 패싯, 호출당 하나: `jobs`, `downstream_pipelines`, `bridge_jobs`입니다. |
| `job_status`  | 문자열  | 아니요       | `jobs` 패싯을 상태로 필터링합니다(예: `failed`). `include`이 `jobs`일 때만 적용됩니다. |
| `first`       | 정수 | 아니요       | 선택한 `include` 패싯에 대해 반환할 항목 수입니다. 기본값은 `20`, 최대값은 `100`입니다. |
| `after`       | 문자열  | 아니요       | 선택한 `include` 패싯의 forward pagination 커서입니다. 이전 응답의 `page_info.end_cursor`을 사용합니다. |

bridge 작업의 `downstream_pipeline`은 `null`으로 생략됩니다. 이는 trigger 작업이 다운스트림 파이프라인을 아직 trigger하지 않았을 때와 해당 파이프라인에 액세스 권한이 없을 때 모두 해당합니다.

각 다운스트림 파이프라인에는 `project_full_path`이 포함됩니다. 이는 다운스트림 파이프라인이 다른 프로젝트에 속할 수 있기 때문입니다. 해당 값을 후속 호출의 `id`으로 사용합니다.

예:

- 파이프라인 가져오기:

  ```plaintext
  Get the status of pipeline 12345 in project gitlab-org/gitlab
  ```

- 파이프라인의 실패한 작업 가져오기:

  ```plaintext
  Show me the failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- 파이프라인의 다운스트림 파이프라인 가져오기:

  ```plaintext
  Show me the downstream pipelines triggered by pipeline 12345 in project gitlab-org/gitlab
  ```

## `get_pipeline_jobs` {#get_pipeline_jobs}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055)되었습니다.

{{< /history >}}

특정 GitLab CI/CD 파이프라인의 작업을 검색합니다. 파이프라인의 나병합 데이터와 함께 작업을 한 번의 호출로 가져오려면 `get_pipeline` 도구를 `include: jobs`와 함께 사용합니다.

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

## `get_job` {#get_job}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/605856)되었습니다.
- GitLab 19.3에서 `get_job_log`에서 [이름이 바뀌었습니다](https://gitlab.com/gitlab-org/gitlab/-/work_items/605856). `get_job_log`은 별칭으로 계속 작동하며 항상 `log` 패싯을 반환하며 `byte_limit`로 제한됩니다.

{{< /history >}}

CI/CD 작업의 메타데이터 및 선택적으로 해당 trace/log를 가져옵니다.

| 매개변수     | 형식    | 필수 | 설명 |
|---------------|---------|----------|-------------|
| `id`          | 문자열  | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `job_id`      | 정수 | 예      | 작업의 ID입니다. |
| `include`     | 배열   | 아니요       | 작업과 함께 포함할 패싯, 호출당 하나: `log`입니다. |
| `byte_offset` | 정수 | 아니요       | 작업의 log를 읽기 시작할 바이트 오프셋입니다. `include`이 `log`일 때만 적용됩니다. 기본값은 `0`입니다. |
| `byte_limit`  | 정수 | 아니요       | 반환할 작업의 log의 최대 바이트 수입니다. `include`이 `log`일 때만 적용됩니다. 기본값 및 최대값은 `512000`입니다. |

log가 `byte_limit`보다 길면 응답은 전체 크기를 보고하고 다음 윈도우에 사용할 `byte_offset`을 알려줍니다.

예:

- 작업의 메타데이터 가져오기:

  ```plaintext
  Get the status of job 88 in project gitlab-org/gitlab
  ```

- 작업의 log 가져오기:

  ```plaintext
  Show me the log output for job 88 in project gitlab-org/gitlab
  ```

## `list_pipelines` {#list_pipelines}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/605854)되었습니다.

{{< /history >}}

GitLab 프로젝트의 파이프라인을 선택적 필터와 함께 나열합니다.

| 매개변수        | 형식    | 필수 | 설명 |
|------------------|---------|----------|-------------|
| `id`             | 문자열  | 예      | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `ref`            | 문자열  | 아니요       | 브랜치 또는 태그 이름입니다. 파이프라인을 ref별로 필터링합니다. |
| `status`         | 문자열  | 아니요       | 파이프라인을 상태로 필터링합니다(예: `running`, `success`, `failed`). |
| `source`         | 문자열  | 아니요       | 파이프라인을 source별로 필터링합니다(예: `push`, `web`, `schedule`). |
| `created_after`  | 문자열  | 아니요       | 지정된 datetime(ISO 8601 형식) 이후에 만들어진 파이프라인을 반환합니다. |
| `created_before` | 문자열  | 아니요       | 지정된 datetime(ISO 8601 형식) 이전에 만들어진 파이프라인을 반환합니다. |
| `order_by`       | 문자열  | 아니요       | 파이프라인을 `id`, `status`, `ref`, `updated_at`, `user_id`별로 정렬합니다. 기본값은 `id`입니다. |
| `sort`           | 문자열  | 아니요       | 정렬 방향, `asc` 또는 `desc`입니다. 기본값은 `desc`입니다. |
| `page`           | 정수 | 아니요       | 현재 페이지 번호입니다. 기본값은 `1`입니다. |
| `per_page`       | 정수 | 아니요       | 페이지당 항목 수입니다. 기본값은 `20`입니다. |

Child 파이프라인은 기본적으로 결과에서 제외됩니다. child 파이프라인만 반환하려면 `source`을 `parent_pipeline`으로 설정합니다.

기본 순서(`id`, `desc`)는 가장 높은 ID를 가진 파이프라인을 먼저 반환합니다. ID 순서는 보통 만든 순서와 일치하지만 두 항목이 일치한다고 보장할 수 없습니다. `created_after` 또는 `created_before`을 사용하여 명시적 시간 경계별로 필터링합니다. 호출자는 결과를 페이징하고 대상 범위 외의 첫 파이프라인에서 중지할 수 있습니다.

예:

```plaintext
List all failed pipelines on the main branch for project gitlab-org/gitlab
```

## `save_pipeline` {#save_pipeline}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/605855)되었습니다.

{{< /history >}}

GitLab 프로젝트에서 CI/CD 파이프라인을 실행하거나, 다시 시도하거나, 취소합니다. 파이프라인 메타데이터를 업데이트하거나 파이프라인을 삭제하려면 `manage_pipeline` 도구를 대신 사용합니다. 파이프라인을 나열하려면 `list_pipelines` 도구를 대신 사용합니다.

| 매개변수     | 형식    | 필수    | 설명 |
|---------------|---------|-------------|-------------|
| `url`         | 문자열  | 아니요          | 프로젝트의 GitLab URL입니다. 파이프라인을 만들 때만 사용됩니다. 이를 제공하거나 `project_id`을 제공합니다. |
| `project_id`  | 문자열  | 아니요          | 프로젝트의 ID 또는 전체 경로입니다. 파이프라인을 만들 때만 사용됩니다. 이를 제공하거나 `url`을 제공합니다. |
| `pipeline_id` | 정수 | 아니요          | 대상으로 할 기존 파이프라인의 ID입니다. 설정된 경우 `action`이 필요합니다. 새 파이프라인을 만들려면 생략합니다. |
| `action`      | 문자열  | 아니요          | `pipeline_id`에서 수행할 수명 주기 작업: `retry` 또는 `cancel`입니다. `pipeline_id`이 설정된 경우 필수입니다. |
| `ref`         | 문자열  | 아니요          | 브랜치 또는 태그 이름입니다. 파이프라인을 만들려면 필수입니다(`pipeline_id`가 없는 경우). |
| `variables`   | 배열   | 아니요          | 배열 형식(`[{key, value, variable_type}]`)의 파이프라인 변수입니다. |
| `inputs`      | 해시    | 아니요          | 키-값 쌍으로 된 파이프라인 입력 매개변수입니다. |

예:

- 파이프라인 만들기:

  ```plaintext
  Create a pipeline on the main branch for project gitlab-org/gitlab
  ```

- 파이프라인 재시도:

  ```plaintext
  Retry failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- 파이프라인 취소:

  ```plaintext
  Cancel pipeline 12345 in project gitlab-org/gitlab
  ```

## `manage_pipeline` {#manage_pipeline}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826)되었습니다.
- GitLab 19.3에서 `list_pipelines` 도구를 위해 `list` 작업을 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247806)했습니다.
- GitLab 19.3에서 `save_pipeline` 도구를 위해 `create`, `retry`, `cancel` 작업을 [제거](https://gitlab.com/gitlab-org/gitlab/-/work_items/605855)했습니다.

{{< /history >}}

GitLab 프로젝트에서 파이프라인 메타데이터를 업데이트하거나 파이프라인을 삭제합니다. 파이프라인을 만들거나 다시 시도하거나 취소하려면 대신 `save_pipeline` 도구를 사용합니다. 파이프라인을 나열하려면 `list_pipelines` 도구를 대신 사용합니다.

| 매개변수     | 형식    | 필수    | 설명 |
|---------------|---------|-------------|-------------|
| `id`          | 문자열  | 예         | 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `pipeline_id` | 정수 | 예         | 파이프라인의 ID입니다. 이 매개변수만 설정된 경우 파이프라인 및 모든 관련 데이터를 삭제합니다. |
| `name`        | 문자열  | 아니요          | 파이프라인의 이름입니다. 이 매개변수와 `pipeline_id`이 설정된 경우 파이프라인 메타데이터를 업데이트합니다. |

예:

- 파이프라인 업데이트:

  ```plaintext
  Rename pipeline 12345 to "My deploy pipeline" in project gitlab-org/gitlab
  ```

- 파이프라인 삭제:

  ```plaintext
  Delete pipeline 12345 in project gitlab-org/gitlab
  ```

## `create_workitem_note` {#create_workitem_note}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/581890)되었습니다.

{{< /history >}}

GitLab 작업 항목에 새 메모(댓글)를 만듭니다.

| 매개변수       | 형식    | 필수 | 설명 |
|-----------------|---------|----------|-------------|
| `body`          | 문자열  | 예      | 노트의 내용입니다. |
| `url`           | 문자열  | 아니요       | 작업 항목의 URL입니다. `group_id` 또는 `project_id` 및 `work_item_iid`이 누락된 경우 필수입니다. |
| `group_id`      | 문자열  | 아니요       | 그룹의 ID 또는 경로입니다. `url` 및 `project_id`가 누락된 경우 필수입니다. |
| `project_id`    | 문자열  | 아니요       | 프로젝트의 ID 또는 경로입니다. `url` 및 `group_id`가 누락된 경우 필수입니다. |
| `work_item_iid` | 정수 | 아니요       | 작업 항목의 내부 ID입니다. `url`이 누락된 경우 필수입니다. |
| `internal`      | 부울 | 아니요       | 노트를 내부로 표시합니다(프로젝트의 보고자, 개발자, 유지 관리자 또는 소유자 역할이 있는 사용자에게만 표시됨). 기본값은 `false`입니다. |
| `discussion_id` | 문자열  | 아니요       | 회신할 토론의 전역 ID입니다(`gid://gitlab/Discussion/<id>` 형식). |

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
| `work_items_ids` | 문자열 배열 | 예      | 연결할 작업 항목의 전역 ID입니다(`gid://gitlab/WorkItem/<id>` 형식). 최대 10개 항목입니다. |
| `url`            | 문자열           | 아니요       | 소스 작업 항목의 URL입니다. `group_id` 또는 `project_id` 및 `work_item_iid`이 누락된 경우 필수입니다. |
| `group_id`       | 문자열           | 아니요       | 그룹의 ID 또는 경로입니다. `url` 및 `project_id`가 누락된 경우 필수입니다. |
| `project_id`     | 문자열           | 아니요       | 프로젝트의 ID 또는 경로입니다. `url` 및 `group_id`가 누락된 경우 필수입니다. |
| `work_item_iid`  | 정수          | 아니요       | 소스 작업 항목의 내부 ID입니다. `url`이 누락된 경우 필수입니다. |
| `link_type`      | 문자열           | 아니요       | 관계 유형입니다. `relates_to`, `blocks` 또는 `blocked_by` 중 하나입니다. 기본값은 `relates_to`입니다. `blocks` 및 `blocked_by` 유형은 GitLab Premium 또는 Ultimate이 필요합니다. |

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
| `saved_view_id` | 문자열  | 예      | 저장된 보기의 전역 ID입니다(`gid://gitlab/WorkItems::SavedViews::SavedView/<id>` 형식). |
| `url`           | 문자열  | 아니요       | 네임스페이스(프로젝트 또는 그룹)의 URL입니다. `group_id` 또는 `project_id`이 누락된 경우 필수입니다. |
| `group_id`      | 문자열  | 아니요       | 그룹의 ID 또는 경로입니다. `url` 및 `project_id`가 누락된 경우 필수입니다. |
| `project_id`    | 문자열  | 아니요       | 프로젝트의 ID 또는 경로입니다. `url` 및 `group_id`가 누락된 경우 필수입니다. |
| `after`         | 문자열  | 아니요       | 정방향 페이지 매김을 위한 커서입니다. |
| `first`         | 정수 | 아니요       | 반환할 작업 항목 수입니다. 최대 100입니다. |

예:

```plaintext
Show me the work items in this saved view: <URL>
```

## `save_work_item` {#save_work_item}

{{< history >}}

- GitLab 19.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/605852)되었습니다.

{{< /history >}}

이슈, 작업 또는 에픽 같은 GitLab 작업 항목을 만들거나 업데이트합니다. 새 작업 항목을 만들려면 `work_item_iid`를 생략합니다. 기존 항목을 업데이트하려면 `work_item_iid` 또는 work item URL을 제공합니다. 도구 이름 `create_work_item` 및 `update_work_item`는 이 도구의 별칭입니다.

| 매개변수          | 형식              | 필수 | 설명 |
|--------------------|-------------------|----------|-------------|
| `url`              | 문자열            | 아니요       | 프로젝트, 그룹 또는 work item의 GitLab URL입니다. `url`, `project_id`, `group_id` 중 정확히 하나를 제공합니다. |
| `group_id`         | 문자열            | 아니요       | 그룹의 ID 또는 경로입니다. `url` 및 `project_id`가 누락된 경우 필수입니다. |
| `project_id`       | 문자열            | 아니요       | 프로젝트의 ID 또는 경로입니다. `url` 및 `group_id`가 누락된 경우 필수입니다. |
| `work_item_iid`    | 정수           | 아니요       | 업데이트할 work item의 내부 ID입니다. 새 작업 항목을 만들려면 생략합니다. |
| `title`            | 문자열            | 아니요       | Work item의 제목입니다. 작업 항목을 만드는 경우 필수입니다. |
| `type_name`        | 문자열            | 아니요       | Work item 유형 이름(예: `Issue`, `Task`, `Epic`)입니다. 작업 항목을 만드는 경우 필수입니다. 유효한 유형은 네임스페이스 및 라이선스에 따라 다릅니다. |
| `description`      | 문자열            | 아니요       | GitLab Flavored Markdown의 설명입니다. 최대 1,048,576자입니다. |
| `assignee_ids`     | 정수 배열 | 아니요       | Work item에 할당할 사용자 ID입니다. 최대 100개 항목입니다. |
| `label_ids`        | 문자열 배열  | 아니요       | 레이블 ID 또는 전역 ID입니다. 만들기 전용입니다. 업데이트에서는 `add_label_ids` 또는 `remove_label_ids`를 사용합니다. 최대 100개 항목입니다. |
| `add_label_ids`    | 문자열 배열  | 아니요       | 업데이트 전용입니다. 추가할 레이블 ID 또는 전역 ID입니다. 최대 100개 항목입니다. |
| `remove_label_ids` | 문자열 배열  | 아니요       | 업데이트 전용입니다. 제거할 레이블 ID 또는 전역 ID입니다. 최대 100개 항목입니다. |
| `confidential`     | 부울           | 아니요       | Work item 기밀성을 설정합니다. |
| `start_date`       | 문자열            | 아니요       | 시작 날짜, `YYYY-MM-DD` 형식입니다. |
| `due_date`         | 문자열            | 아니요       | 완료 날짜, `YYYY-MM-DD` 형식입니다. |
| `state`            | 문자열            | 아니요       | 업데이트 전용입니다. `closed`은 work item을 닫고 `opened`은 다시 열습니다. |
| `parent_id`        | 문자열            | 아니요       | 상위 work item의 전역 ID 또는 숫자 ID입니다. |
| `todo_action`      | 문자열            | 아니요       | 업데이트 전용입니다. `add`은 현재 사용자를 위해 to-do를 추가하고 `mark_as_done`은 to-do를 완료로 표시합니다. |
| `todo_id`          | 문자열            | 아니요       | 업데이트 전용입니다. To-do의 전역 ID 또는 숫자 ID입니다. Work item의 모든 to-do를 업데이트하려면 생략합니다. |
| `health_status`    | 문자열            | 아니요       | 건강 상태입니다. `onTrack`, `needsAttention` 또는 `atRisk` 중 하나입니다. Ultimate만 해당입니다. |
| `weight`           | 정수           | 아니요       | Work item의 가중치입니다. 0 이상이어야 합니다. Premium 및 Ultimate만 해당입니다. |
| `clear_weight`     | 부울           | 아니요       | 업데이트 전용입니다. 가중치를 제거합니다. `weight`보다 우선합니다. Premium 및 Ultimate만 해당입니다. |
| `status_id`        | 문자열            | 아니요       | 설정할 상태의 전역 ID입니다. Premium 및 Ultimate만 해당입니다. |
| `is_fixed`         | 부울           | 아니요       | 시작 및 완료 날짜가 고정되어 있는지 여부입니다. `false`인 경우 날짜는 자식 항목에서 롤업되고 `start_date` 및 `due_date`은 무시됩니다. Premium 및 Ultimate만 해당입니다. |
| `agent_plan`       | 문자열            | 아니요       | 에이전트 플랜의 Markdown 내용입니다. Ultimate만 해당입니다. Workplan 기능이 필요합니다. |

예:

```plaintext
Create a task "Update the onboarding guide" in project gitlab-org/gitlab and assign it to me
```

## `search` {#search}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/566143)되었습니다.
- 그룹 및 프로젝트 검색 및 결과 정렬 및 [추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/571132)(GitLab 18.6).
- GitLab 18.8에서 `gitlab_search`에서 `search`로 [이름이 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214734)되었습니다.

{{< /history >}}

검색 API를 사용하여 전체 GitLab 인스턴스에서 용어를 검색합니다. 이 도구는 전역, 그룹 및 프로젝트 검색에 사용할 수 있습니다. 사용 가능한 범위는 [검색 유형](../search/_index.md)에 따라 다릅니다.

| 매개변수      | 형식             | 필수 | 설명 |
|----------------|------------------|----------|-------------|
| `scope`        | 문자열           | 예      | 검색 범위(예: `work_items`, `merge_requests`, 또는 `projects`). |
| `search`       | 문자열           | 예      | 검색 용어입니다. |
| `group_id`     | 문자열           | 아니요       | 검색하려는 그룹의 ID 또는 URL 인코딩된 경로입니다. |
| `project_id`   | 문자열           | 아니요       | 검색하려는 프로젝트의 ID 또는 URL 인코딩된 경로입니다. |
| `state`        | 문자열           | 아니요       | 검색 결과의 상태(`work_items` 및 `merge_requests`의 경우). |
| `confidential` | 부울          | 아니요       | 기밀성에 따라 결과를 필터링(`work_items`의 경우). 기본값은 `false`입니다. |
| `fields`       | 문자열 배열 | 아니요       | 검색하려는 필드의 배열(`work_items` 및 `merge_requests`의 경우). |
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

- GitLab 18.9에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218121)되었습니다.

{{< /history >}}

GitLab 프로젝트 또는 그룹에서 레이블을 검색합니다.

| 매개변수    | 형식    | 필수 | 설명 |
|--------------|---------|----------|-------------|
| `full_path`  | 문자열  | 예      | 프로젝트 또는 그룹의 전체 경로(예: `group/project`). |
| `is_project` | 부울 | 예      | 프로젝트(`true`) 또는 그룹(`false`)에서 검색할지 여부입니다. |
| `search`     | 문자열  | 아니요       | 제목으로 레이블을 필터링할 검색 용어입니다. |

그룹 레이블을 검색할 때 결과에는 상위 그룹 및 하위 그룹의 레이블이 포함됩니다.

예:

```plaintext
Show me all labels in project gitlab-org/gitlab
```

## `list_wiki_pages` {#list_wiki_pages}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240973)되었습니다.

{{< /history >}}

GitLab 프로젝트 또는 그룹의 wiki 페이지를 나열합니다.

| 매개변수    | 형식    | 필수 | 설명 |
|--------------|---------|----------|-------------|
| `project_id` | 문자열  | 아니요       | 프로젝트의 전체 경로 또는 숫자 ID(예: `gitlab-org/gitlab` 또는 `278964`)입니다. |
| `group_id`   | 문자열  | 아니요       | 그룹의 전체 경로 또는 숫자 ID(예: `gitlab-org` 또는 `9970`)입니다. |
| `first`      | 정수 | 아니요       | Forward pagination에 대해 반환할 wiki 페이지 수(최대 100)입니다. |
| `after`      | 문자열  | 아니요       | 정방향 페이지 매김을 위한 커서입니다. |

`project_id` 또는 `group_id` 중 하나만 제공합니다. 각 호출은 결과의 단일 페이지를 반환합니다. 더 많은 페이지가 있으면 응답에 `end_cursor`이 포함되며 이를 `after`으로 전달하여 다음 페이지를 가져올 수 있습니다.

예:

```plaintext
List the wiki pages in gitlab-org/gitlab
```

## `semantic_code_search` {#semantic_code_search}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.5에서 `code_snippet_search_graphqlapi` [기능 플래그](../../administration/feature_flags/_index.md)의 [실험적 기능](../../policy/development_stages_support.md#experiment)으로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/569624)되었습니다. 기본적으로 사용 중지되어 있습니다.
- 프로젝트 경로로 검색 [추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/575234)(GitLab 18.6).
- GitLab 18.7에서 실험적 기능에서 [베타](../../policy/development_stages_support.md#beta)로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/568359)되었습니다. `code_snippet_search_graphqlapi` 기능 플래그가 제거되었습니다.
- GitLab 18.7에서 GitLab UI에 `mcp_client` [기능 플래그](../../administration/feature_flags/_index.md)로 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/581105)되었습니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 18.11에서 [REST API](../../api/search.md#semantic-search)를 사용하도록 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228569)되었으며 [기능 플래그](../../administration/feature_flags/_index.md)는 `mcp_semantic_code_search_use_rest_api`입니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 19.1에서 REST API 사용이 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239364)되었습니다. `mcp_semantic_code_search_use_rest_api` 기능 플래그가 제거되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능성은 기능 플래그로 제어합니다. 자세한 내용은 기록을 참조하세요.

GitLab 프로젝트에서 관련 코드 스니펫을 검색합니다. 설정 및 활성화를 포함한 자세한 내용은 [의미론적 코드 검색](../gitlab_duo/semantic_code_search.md)을 참조하세요.

| 매개변수        | 형식    | 필수 | 설명 |
|------------------|---------|----------|-------------|
| `semantic_query` | 문자열  | 예      | 코드의 검색 쿼리입니다. |
| `project_id`     | 문자열  | 예      | 프로젝트의 ID 또는 경로입니다. |
| `directory_path` | 문자열  | 아니요       | 디렉터리 경로(예: `app/services/`). |
| `knn`            | 정수 | 아니요       | 유사한 코드 스니펫을 찾기 위해 사용되는 최근방 이웃 수입니다. 기본값은 `64`입니다. |
| `limit`          | 정수 | 아니요       | 반환할 최대 결과 수입니다. 기본값은 `20`입니다. |

최선의 결과를 위해 일반적인 키워드나 특정 함수 또는 변수 이름을 사용하는 것보다 관심 있는 기능이나 동작을 설명합니다.

예:

```plaintext
How are authorizations managed in this project?
```

## `attach_scan_profile` {#attach_scan_profile}

{{< history >}}

- GitLab 19.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240685)되었습니다.

{{< /history >}}

지정된 보안 검사 프로필을 지정된 프로젝트에 또는 지정된 그룹 아래의 모든 프로젝트에 연결합니다.

| 매개변수                  | 형식             | 필수 | 설명 |
|----------------------------|------------------|----------|-------------|
| `security_scan_profile_id` | 문자열           | 예      | 보안 검사 프로필의 전역 ID입니다(예: `gid://gitlab/Security::ScanProfile/1`). |
| `project_ids`              | 문자열 배열 | 아니요       | 프로젝트의 전역 ID의 배열입니다(예: `[gid://gitlab/Project/1]`). `group_ids`가 제공되지 않으면 필수입니다. |
| `group_ids`                | 문자열 배열 | 아니요       | 그룹의 전역의 ID 배열입니다(예: `[gid://gitlab/Group/1]`). `project_ids`가 제공되지 않으면 필수입니다. |

예:

```plaintext
Attach `gid://gitlab/Security::ScanProfile/1` to all projects under `gid://gitlab/Group/1`.
```
