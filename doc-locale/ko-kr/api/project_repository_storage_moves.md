---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 리포지토리 스토리지 이동 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

위키 및 디자인 리포지토리를 포함한 프로젝트 리포지토리를 스토리지 간에 이동할 수 있습니다. 예를 들어, [Gitaly Cluster(Praefect)로 마이그레이션](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect)할 때 이 API가 도움이 될 수 있습니다.

프로젝트 리포지토리 스토리지 이동이 처리되면 다양한 상태를 거칩니다. `state`의 값은 다음과 같습니다:

- `initial`:  레코드가 생성되었지만 백그라운드 작업이 아직 예약되지 않았습니다.
- `scheduled`:  백그라운드 작업이 예약되었습니다.
- `started`:  프로젝트 리포지토리가 대상 스토리지로 복사되고 있습니다.
- `replicated`:  프로젝트가 이동되었습니다.
- `failed`:  프로젝트 리포지토리 복사에 실패했거나 체크섬이 일치하지 않습니다.
- `finished`:  프로젝트가 이동되었고 소스 스토리지의 리포지토리가 삭제되었습니다.
- `cleanup failed`:  프로젝트가 이동되었지만 소스 스토리지의 리포지토리를 삭제할 수 없습니다.

데이터 무결성을 보장하기 위해 이동하는 동안 프로젝트는 임시 읽기 전용 상태로 설정됩니다. 이 시간 동안 사용자가 새 커밋을 푸시하려고 하면 `The repository is temporarily read-only. Please try again later.` 메시지를 받습니다.

이 API를 사용하려면 관리자로 [인증](rest/authentication.md)해야 합니다.

다른 리포지토리 유형은 다음을 참조하십시오:

- [스니펫 리포지토리 스토리지 이동 API](snippet_repository_storage_moves.md).
- [그룹 리포지토리 저장소 이동 API](group_repository_storage_moves.md)

## 모든 프로젝트 리포지토리 스토리지 이동 나열 {#list-all-project-repository-storage-moves}

```plaintext
GET /project_repository_storage_moves
```

기본적으로 `GET` 요청은 API 결과가 [페이지가 매겨진](rest/_index.md#pagination) 경우 한 번에 20개의 결과를 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_repository_storage_moves"
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
    "project": {
      "id": 1,
      "description": null,
      "name": "project1",
      "name_with_namespace": "John Doe2 / project1",
      "path": "project1",
      "path_with_namespace": "namespace1/project1",
      "created_at": "2020-05-07T04:27:17.016Z"
    }
  }
]
```

## 프로젝트의 모든 리포지토리 스토리지 이동 나열 {#list-all-repository-storage-moves-for-a-project}

```plaintext
GET /projects/:project_id/repository_storage_moves
```

기본적으로 `GET` 요청은 API 결과가 [페이지가 매겨진](rest/_index.md#pagination) 경우 한 번에 20개의 결과를 반환합니다.

매개 변수:

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `project_id` | 정수 | 예 | 프로젝트의 ID |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository_storage_moves"
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
    "project": {
      "id": 1,
      "description": null,
      "name": "project1",
      "name_with_namespace": "John Doe2 / project1",
      "path": "project1",
      "path_with_namespace": "namespace1/project1",
      "created_at": "2020-05-07T04:27:17.016Z"
    }
  }
]
```

## 프로젝트 리포지토리 스토리지 이동 검색 {#retrieve-a-project-repository-storage-move}

```plaintext
GET /project_repository_storage_moves/:repository_storage_id
```

매개 변수:

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | 정수 | 예 | 프로젝트 리포지토리 스토리지 이동의 ID |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_repository_storage_moves/1"
```

예제 응답:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2020-05-07T04:27:17.016Z"
  }
}
```

## 프로젝트의 리포지토리 스토리지 이동 검색 {#retrieve-a-repository-storage-move-for-a-project}

```plaintext
GET /projects/:project_id/repository_storage_moves/:repository_storage_id
```

매개 변수:

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `project_id` | 정수 | 예 | 프로젝트의 ID |
| `repository_storage_id` | 정수 | 예 | 프로젝트 리포지토리 스토리지 이동의 ID |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository_storage_moves/1"
```

예제 응답:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2020-05-07T04:27:17.016Z"
  }
}
```

## 프로젝트의 리포지토리 스토리지 이동 생성 {#create-a-repository-storage-move-for-a-project}

```plaintext
POST /projects/:project_id/repository_storage_moves
```

매개 변수:

| 특성 | 유형 | 필수 | 설명                                                                                                                                                                                                        |
| --------- | ---- | -------- |--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `project_id` | 정수 | 예 | 프로젝트의 ID                                                                                                                                                                                                  |
| `destination_storage_name` | 문자열 | 아니오 | 대상 저장소 샤드의 이름입니다. 스토리지가 [스토리지 가중치를 기반으로 자동으로 선택](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)됩니다(제공되지 않는 경우) |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"destination_storage_name":"storage2"}' \
  --url "https://gitlab.example.com/api/v4/projects/1/repository_storage_moves"
```

예제 응답:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2020-05-07T04:27:17.016Z"
  }
}
```

## 스토리지 샤드의 모든 프로젝트에 대한 리포지토리 스토리지 이동 생성 {#create-repository-storage-moves-for-all-projects-on-a-storage-shard}

소스 스토리지 샤드에 저장된 각 프로젝트 리포지토리에 대한 리포지토리 스토리지 이동을 생성합니다. 이 엔드포인트는 모든 프로젝트를 한 번에 마이그레이션합니다.

```plaintext
POST /project_repository_storage_moves
```

매개 변수:

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
  --url "https://gitlab.example.com/api/v4/project_repository_storage_moves"
```

예제 응답:

```json
{
  "message": "202 Accepted"
}
```

## 관련 항목 {#related-topics}

- [GitLab에서 관리하는 리포지토리 이동](../administration/operations/moving_repositories.md)
