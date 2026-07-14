---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 그룹의 리포지토리 스토리지 이동을 위한 REST API에 대한 설명서입니다.
title: 그룹 리포지토리 스토리지 이동 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [그룹 리포지토리 스토리지 이동](../administration/operations/moving_repositories.md)을 관리할 수 있습니다. 이 API는 예를 들어 [Gitaly Cluster(Praefect)로 마이그레이션](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect) 하거나 [그룹 위키](../user/project/wiki/group.md)를 마이그레이션하는 데 도움이 될 수 있습니다. 이 API는 그룹의 프로젝트 리포지토리를 관리하지 않습니다. 프로젝트 이동을 예약하려면 [프로젝트 리포지토리 스토리지 이동 API](project_repository_storage_moves.md)를 사용합니다.

GitLab이 그룹 리포지토리 스토리지 이동을 처리할 때 다양한 상태를 거칩니다. `state`의 값은 다음과 같습니다:

- `initial`:  레코드가 생성되었지만 백그라운드 작업이 아직 예약되지 않았습니다.
- `scheduled`:  백그라운드 작업이 예약되었습니다.
- `started`:  그룹 리포지토리가 대상 스토리지로 복사되고 있습니다.
- `replicated`:  그룹이 이동되었습니다.
- `failed`:  그룹 리포지토리 복사가 실패했거나 체크섬이 일치하지 않습니다.
- `finished`:  그룹이 이동되었고 소스 스토리지의 리포지토리가 삭제되었습니다.
- `cleanup failed`:  그룹이 이동되었지만 소스 스토리지의 리포지토리를 삭제할 수 없습니다.

데이터 무결성을 보장하기 위해 GitLab은 이동 기간 동안 그룹을 임시 읽기 전용 상태로 설정합니다. 이 시간에 사용자가 새 커밋을 푸시하려고 하면 이 메시지를 받습니다:

```plaintext
The repository is temporarily read-only. Please try again later.
```

이 API를 사용하려면 관리자 권한으로 [인증](rest/authentication.md)해야 합니다.

다른 유형의 리포지토리 이동을 위한 API도 사용할 수 있습니다:

- [프로젝트 리포지토리 스토리지 이동 API](project_repository_storage_moves.md).
- [스니펫 리포지토리 스토리지 이동 API](snippet_repository_storage_moves.md).

## 모든 그룹 리포지토리 스토리지 이동 나열 {#list-all-group-repository-storage-moves}

인스턴스의 모든 그룹 리포지토리 스토리지 이동을 나열합니다.

```plaintext
GET /group_repository_storage_moves
```

기본적으로 `GET` 요청은 한 번에 20개의 결과를 반환합니다. API 결과는 [페이지로 나뉘어](rest/_index.md#pagination) 있기 때문입니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/group_repository_storage_moves"
```

응답 예시:

```json
[
  {
    "id": 1,
    "created_at": "2020-05-07T04:27:17.234Z",
    "state": "scheduled",
    "source_storage_name": "default",
    "destination_storage_name": "storage2",
    "group": {
      "id": 283,
      "web_url": "https://gitlab.example.com/groups/testgroup",
      "name": "testgroup"
    }
  }
]
```

## 그룹의 모든 리포지토리 스토리지 이동 나열 {#list-all-repository-storage-moves-for-a-group}

지정된 그룹의 모든 리포지토리 스토리지 이동을 나열합니다.

```plaintext
GET /groups/:group_id/repository_storage_moves
```

기본적으로 `GET` 요청은 한 번에 20개의 결과를 반환합니다. API 결과는 [페이지로 나뉘어](rest/_index.md#pagination) 있기 때문입니다.

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `group_id` | 정수 | 예 | 그룹의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves"
```

응답 예시:

```json
[
  {
    "id": 1,
    "created_at": "2020-05-07T04:27:17.234Z",
    "state": "scheduled",
    "source_storage_name": "default",
    "destination_storage_name": "storage2",
    "group": {
      "id": 283,
      "web_url": "https://gitlab.example.com/groups/testgroup",
      "name": "testgroup"
    }
  }
]
```

## 그룹 리포지토리 스토리지 이동 검색 {#retrieve-a-group-repository-storage-move}

지정된 그룹 리포지토리 스토리지 이동을 검색합니다.

```plaintext
GET /group_repository_storage_moves/:repository_storage_id
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | 정수 | 예 | 그룹 리포지토리 스토리지 이동의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/group_repository_storage_moves/1"
```

응답 예시:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## 그룹의 리포지토리 스토리지 이동 검색 {#retrieve-a-repository-storage-move-for-a-group}

그룹의 지정된 리포지토리 스토리지 이동을 검색합니다.

```plaintext
GET /groups/:group_id/repository_storage_moves/:repository_storage_id
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `group_id` | 정수 | 예 | 그룹의 ID입니다. |
| `repository_storage_id` | 정수 | 예 | 그룹 리포지토리 스토리지 이동의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves/1"
```

응답 예시:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## 그룹 리포지토리 스토리지 이동 생성 {#create-a-group-repository-storage-move}

지정된 그룹의 그룹 리포지토리 스토리지 이동을 생성합니다. 이 엔드포인트:

- 그룹 위키 리포지토리만 이동합니다.
- 그룹의 프로젝트에 대한 리포지토리를 이동하지 않습니다. 프로젝트 이동을 예약하려면 [프로젝트 리포지토리 스토리지 이동](project_repository_storage_moves.md) API를 사용합니다.

```plaintext
POST /groups/:group_id/repository_storage_moves
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `group_id` | 정수 | 예 | 그룹의 ID입니다. |
| `destination_storage_name` | 문자열 | 아니요 | 대상 스토리지 샤드의 이름입니다. 스토리지는 제공되지 않은 경우 [가중치 기반으로 선택](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)됩니다. |

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"destination_storage_name":"storage2"}' \
     --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves"
```

응답 예시:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## 스토리지 샤드에 대한 그룹 리포지토리 스토리지 이동 생성 {#create-group-repository-storage-moves-for-a-storage-shard}

지정된 스토리지 샤드의 모든 그룹에 대한 리포지토리 스토리지 이동을 생성합니다.

```plaintext
POST /group_repository_storage_moves
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | 문자열 | 예 | 소스 스토리지 샤드의 이름입니다. |
| `destination_storage_name` | 문자열 | 아니요 | 대상 스토리지 샤드의 이름입니다. 스토리지는 제공되지 않은 경우 [가중치 기반으로 선택](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)됩니다. |

요청 예시:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"source_storage_name":"default"}' \
     --url "https://gitlab.example.com/api/v4/group_repository_storage_moves"
```

응답 예시:

```json
{
  "message": "202 Accepted"
}
```

## 관련 항목 {#related-topics}

- [GitLab에서 관리하는 리포지토리 이동](../administration/operations/moving_repositories.md)
