---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 스니펫 리포지토리 저장소 이동 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [스니펫 리포지토리 저장소 이동](../administration/operations/moving_repositories.md)을 관리합니다. 예를 들어 이 API는 [Gitaly Cluster(Praefect)로 마이그레이션](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect)하는 데 도움이 될 수 있습니다.

스니펫 리포지토리 저장소 이동이 처리되면 다양한 상태를 거치게 됩니다. `state`의 값은 다음과 같습니다:

- `initial`:  레코드가 생성되었지만 백그라운드 작업이 아직 예약되지 않았습니다.
- `scheduled`:  백그라운드 작업이 예약되었습니다.
- `started`:  스니펫 리포지토리이 대상 저장소로 복사 중입니다.
- `replicated`:  스니펫이 이동되었습니다.
- `failed`:  스니펫 리포지토리 복사에 실패했거나 체크섬이 일치하지 않았습니다.
- `finished`:  스니펫이 이동되었고 원본 저장소의 리포지토리이 삭제되었습니다.
- `cleanup failed`:  스니펫이 이동되었지만 원본 저장소의 리포지토리을 삭제할 수 없었습니다.

데이터 무결성을 보장하기 위해 스니펫은 이동 기간 동안 임시 읽기 전용 상태로 전환됩니다. 이 시간 동안 사용자가 새 커밋을 푸시하려고 하면 `The repository is temporarily read-only. Please try again later.` 메시지를 받습니다.

이 API를 사용하려면 관리자로 [인증](rest/authentication.md)해야 합니다.

다른 리포지토리 유형은 다음을 참조하십시오:

- [프로젝트 리포지토리 저장소 이동 API](project_repository_storage_moves.md)
- [그룹 리포지토리 저장소 이동 API](group_repository_storage_moves.md)

## 모든 스니펫 리포지토리 저장소 이동 나열 {#list-all-snippet-repository-storage-moves}

모든 스니펫 리포지토리 저장소 이동을 나열합니다.

```plaintext
GET /snippet_repository_storage_moves
```

기본적으로 `GET` 요청은 API 결과가 [페이지가 매겨진](rest/_index.md#pagination) 경우 한 번에 20개의 결과를 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
```

예제 응답:

```json
[
  {
    "id": 1,
    "created_at": "2020-05-07T04:27:17.234Z",
    "state": "scheduled",
    "source_storage_name": "default",
    "destination_storage_name": "storage2",
    "snippet": {
      "id": 65,
      "title": "Test Snippet",
      "description": null,
      "visibility": "internal",
      "updated_at": "2020-12-01T11:15:50.385Z",
      "created_at": "2020-12-01T11:15:50.385Z",
      "project_id": null,
      "web_url": "https://gitlab.example.com/-/snippets/65",
      "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
      "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
      "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
    }
  }
]
```

## 스니펫의 모든 리포지토리 저장소 이동 나열 {#list-all-repository-storage-moves-for-a-snippet}

지정된 스니펫에 대한 모든 리포지토리 저장소 이동을 나열합니다.

```plaintext
GET /snippets/:snippet_id/repository_storage_moves
```

기본적으로 `GET` 요청은 API 결과가 [페이지가 매겨진](rest/_index.md#pagination) 경우 한 번에 20개의 결과를 반환합니다.

지원되는 속성:

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | 정수 | 예 | 스니펫의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves"
```

예제 응답:

```json
[
  {
    "id": 1,
    "created_at": "2020-05-07T04:27:17.234Z",
    "state": "scheduled",
    "source_storage_name": "default",
    "destination_storage_name": "storage2",
    "snippet": {
      "id": 65,
      "title": "Test Snippet",
      "description": null,
      "visibility": "internal",
      "updated_at": "2020-12-01T11:15:50.385Z",
      "created_at": "2020-12-01T11:15:50.385Z",
      "project_id": null,
      "web_url": "https://gitlab.example.com/-/snippets/65",
      "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
      "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
      "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
    }
  }
]
```

## 스니펫 리포지토리 저장소 이동 검색 {#retrieve-a-snippet-repository-storage-move}

지정된 스니펫 리포지토리 저장소 이동을 검색합니다.

```plaintext
GET /snippet_repository_storage_moves/:repository_storage_id
```

지원되는 속성:

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | 정수 | 예 | 스니펫 리포지토리 저장소 이동의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves/1"
```

예제 응답:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## 스니펫에 대한 리포지토리 저장소 이동 검색 {#retrieve-a-repository-storage-move-for-a-snippet}

지정된 스니펫에 대한 리포지토리 저장소 이동을 검색합니다.

```plaintext
GET /snippets/:snippet_id/repository_storage_moves/:repository_storage_id
```

지원되는 속성:

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | 정수 | 예 | 스니펫의 ID입니다. |
| `repository_storage_id` | 정수 | 예 | 스니펫 리포지토리 저장소 이동의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves/1"
```

예제 응답:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## 스니펫에 대한 리포지토리 저장소 이동 예약 {#schedule-a-repository-storage-move-for-a-snippet}

지정된 스니펫에 대한 리포지토리 저장소 이동을 예약합니다.

```plaintext
POST /snippets/:snippet_id/repository_storage_moves
```

지원되는 속성:

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | 정수 | 예 | 스니펫의 ID입니다. |
| `destination_storage_name` | 문자열 | 아니오 | 대상 저장소 샤드의 이름입니다. 제공되지 않은 경우 저장소는 [가중치에 따라 자동으로 선택](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)됩니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"destination_storage_name":"storage2"}' \
  --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves"
```

예제 응답:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## 저장소 샤드의 모든 스니펫에 대한 리포지토리 저장소 이동 예약 {#schedule-repository-storage-moves-for-all-snippets-on-a-storage-shard}

원본 저장소 샤드에 저장된 각 스니펫 리포지토리에 대한 저장소 이동을 예약합니다. 이 엔드포인트는 모든 스니펫을 한 번에 마이그레이션합니다.

```plaintext
POST /snippet_repository_storage_moves
```

지원되는 속성:

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | 문자열 | 예 | 원본 저장소 샤드의 이름입니다. |
| `destination_storage_name` | 문자열 | 아니오 | 대상 저장소 샤드의 이름입니다. 제공되지 않은 경우 저장소는 [가중치에 따라 자동으로 선택](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)됩니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"source_storage_name":"default"}' \
  --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
```

예제 응답:

```json
{
  "message": "202 Accepted"
}
```

## 관련 항목 {#related-topics}

- [GitLab에서 관리하는 리포지토리 이동](../administration/operations/moving_repositories.md)
