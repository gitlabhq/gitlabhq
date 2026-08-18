---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 직접 전송 API를 사용한 그룹 및 프로젝트 마이그레이션
description: "REST API로 그룹 및 프로젝트 마이그레이션을 시작하고 확인합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [직접 전송](../user/group/import/direct_transfer_migrations.md)으로 그룹 및 프로젝트를 마이그레이션합니다.

전제 조건:

- [직접 전송으로 그룹을 마이그레이션하기 위한 필수 조건](../user/group/import/direct_transfer_migrations.md#prerequisites)을 확인합니다.

## 그룹 또는 프로젝트 마이그레이션 시작 {#start-a-group-or-project-migration}

새로운 그룹 또는 프로젝트 마이그레이션을 시작합니다. 프로젝트를 마이그레이션하려면 `entities[project_entity]`을 지정합니다.

```plaintext
POST /bulk_imports
```

| 속성                         | 유형    | 필수 | 설명 |
| --------------------------------- | ------- | -------- | ----------- |
| `configuration`                   | 해시    | 예      | 소스 GitLab 인스턴스 구성입니다. |
| `configuration[url]`              | 문자열  | 예      | 소스 GitLab 인스턴스 URL입니다. |
| `configuration[access_token]`     | 문자열  | 예      | 소스 GitLab 인스턴스에 대한 액세스 토큰입니다. |
| `entities`                        | 배열   | 예      | 가져올 엔티티 목록입니다. |
| `entities[source_type]`           | 문자열  | 예      | 소스 엔티티 유형입니다. 유효한 값은 `group_entity`과 `project_entity`입니다. |
| `entities[source_full_path]`      | 문자열  | 예      | 가져올 엔티티의 소스 전체 경로입니다. 예를 들어, `gitlab-org/gitlab`입니다. |
| `entities[destination_slug]`      | 문자열  | 예      | 엔티티의 대상 슬러그입니다. GitLab은 슬러그를 엔티티의 URL 경로로 사용합니다. 가져온 엔티티의 이름은 슬러그가 아닌 소스 엔티티의 이름에서 복사됩니다. |
| `entities[destination_namespace]` | 문자열  | 예      | 엔티티에 대한 대상 그룹 [네임스페이스](../user/namespace/_index.md)의 전체 경로입니다. `project_entity`의 경우, 이 값은 대상 인스턴스의 기존 그룹이어야 합니다. `group_entity`의 경우, 이 값은 대상 인스턴스의 기존 그룹이거나 대상 인스턴스에 최상위 그룹을 만들기 위한 빈 문자열 `""`이 될 수 있습니다 (GitLab Self-Managed 및 GitLab Dedicated의 경우). 개인 네임스페이스는 지원되지 않습니다. |
| `entities[destination_name]`      | 문자열  | 아니요       | 지원 중단됨:  `destination_slug` 대신 사용합니다. 엔티티의 대상 슬러그입니다. |
| `entities[migrate_memberships]`   | 부울 | 아니요       | 사용자 멤버십을 가져옵니다. `true`로 기본값이 설정됩니다. |
| `entities[migrate_projects]`      | 부울 | 아니요       | `source_type`이 `group_entity`인 경우, 그룹의 모든 중첩 프로젝트도 가져옵니다. `true`로 기본값이 설정됩니다. |

```shell
curl --request POST \
  --url "https://destination-gitlab-instance.example.com/api/v4/bulk_imports" \
  --header "PRIVATE-TOKEN: <your_access_token_for_destination_gitlab_instance>" \
  --header "Content-Type: application/json" \
  --data '{
    "configuration": {
      "url": "https://source-gitlab-instance.example.com",
      "access_token": "<your_access_token_for_source_gitlab_instance>"
    },
    "entities": [
      {
        "source_full_path": "source/full/path",
        "source_type": "group_entity",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination/namespace/path"
      }
    ]
  }'
```

```json
{
  "id": 1,
  "status": "created",
  "source_type": "gitlab",
  "source_url": "https://gitlab.example.com",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z",
  "has_failures": false
}
```

## 모든 그룹 또는 프로젝트 마이그레이션 나열 {#list-all-group-or-project-migrations}

모든 그룹 또는 프로젝트 마이그레이션을 나열합니다.

```plaintext
GET /bulk_imports
```

| 속성  | 유형    | 필수 | 설명                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | 정수 | 아니요       | 페이지당 반환할 레코드 수입니다.                                              |
| `page`     | 정수 | 아니요       | 검색할 페이지입니다.                                                                  |
| `sort`     | 문자열  | 아니요       | 생성 날짜순으로 `asc` 또는 `desc` 순서로 정렬된 레코드를 반환합니다. 기본값은 `desc`입니다 |
| `status`   | 문자열  | 아니요       | 가져오기 상태입니다.                                                                     |

상태는 다음 중 하나일 수 있습니다:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports?per_page=2&page=1"
```

```json
[
    {
        "id": 1,
        "status": "finished",
        "source_type": "gitlab",
        "source_url": "https://gitlab.example.com",
        "created_at": "2021-06-18T09:45:55.358Z",
        "updated_at": "2021-06-18T09:46:27.003Z",
        "has_failures": false
    },
    {
        "id": 2,
        "status": "started",
        "source_type": "gitlab",
        "source_url": "https://gitlab.example.com",
        "created_at": "2021-06-18T09:47:36.581Z",
        "updated_at": "2021-06-18T09:47:58.286Z",
        "has_failures": false
    }
]
```

## 모든 그룹 또는 프로젝트 마이그레이션 엔티티 나열 {#list-all-group-or-project-migration-entities}

모든 그룹 또는 프로젝트 마이그레이션 엔티티를 나열합니다.

```plaintext
GET /bulk_imports/entities
```

| 속성  | 유형    | 필수 | 설명                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | 정수 | 아니요       | 페이지당 반환할 레코드 수입니다.                                              |
| `page`     | 정수 | 아니요       | 검색할 페이지입니다.                                                                  |
| `sort`     | 문자열  | 아니요       | 생성 날짜순으로 `asc` 또는 `desc` 순서로 정렬된 레코드를 반환합니다. 기본값은 `desc`입니다 |
| `status`   | 문자열  | 아니요       | 가져오기 상태입니다.                                                                     |

상태는 다음 중 하나일 수 있습니다:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/entities?per_page=2&page=1&status=started"
```

```json
[
    {
        "id": 1,
        "bulk_import_id": 1,
        "status": "finished",
        "entity_type": "group",
        "source_full_path": "source_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination_path",
        "parent_id": null,
        "namespace_id": 1,
        "project_id": null,
        "created_at": "2021-06-18T09:47:37.390Z",
        "updated_at": "2021-06-18T09:47:51.867Z",
        "failures": [],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": false,
        "stats": {
            "labels": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            },
            "milestones": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            }
        }
    },
    {
        "id": 2,
        "bulk_import_id": 2,
        "status": "failed",
        "entity_type": "group",
        "source_full_path": "another_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "another_slug",
        "destination_namespace": "another_namespace",
        "parent_id": null,
        "namespace_id": null,
        "project_id": null,
        "created_at": "2021-06-24T10:40:20.110Z",
        "updated_at": "2021-06-24T10:40:46.590Z",
        "failures": [
            {
                "relation": "group",
                "step": "extractor",
                "exception_message": "Error!",
                "exception_class": "Exception",
                "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
                "created_at": "2021-06-24T10:40:46.495Z",
                "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
                "pipeline_step": "extractor"
            }
        ],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": false,
        "stats": { }
    }
]
```

## 그룹 또는 프로젝트 마이그레이션 검색 {#retrieve-a-group-or-project-migration}

그룹 또는 프로젝트 마이그레이션의 세부 정보를 검색합니다.

```plaintext
GET /bulk_imports/:id
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1"
```

```json
{
  "id": 1,
  "status": "finished",
  "source_type": "gitlab",
  "source_url": "https://gitlab.example.com",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z"
}
```

## 그룹 또는 프로젝트 마이그레이션 엔티티 나열 {#list-group-or-project-migration-entities}

특정 마이그레이션에 대한 그룹 또는 프로젝트 마이그레이션 엔티티를 나열합니다.

```plaintext
GET /bulk_imports/:id/entities
```

| 속성  | 유형    | 필수 | 설명                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | 정수 | 아니요       | 페이지당 반환할 레코드 수입니다.                                              |
| `page`     | 정수 | 아니요       | 검색할 페이지입니다.                                                                  |
| `sort`     | 문자열  | 아니요       | 생성 날짜순으로 `asc` 또는 `desc` 순서로 정렬된 레코드를 반환합니다. 기본값은 `desc`입니다 |
| `status`   | 문자열  | 아니요       | 가져오기 상태입니다.                                                                     |

상태는 다음 중 하나일 수 있습니다:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities?per_page=2&page=1&status=finished"
```

```json
[
    {
        "id": 1,
        "bulk_import_id": 1,
        "status": "finished",
        "entity_type": "group",
        "source_full_path": "source_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination_path",
        "parent_id": null,
        "namespace_id": 1,
        "project_id": null,
        "created_at": "2021-06-18T09:47:37.390Z",
        "updated_at": "2021-06-18T09:47:51.867Z",
        "failures": [
            {
                "relation": "group",
                "step": "extractor",
                "exception_message": "Error!",
                "exception_class": "Exception",
                "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
                "created_at": "2021-06-24T10:40:46.495Z",
                "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
                "pipeline_step": "extractor"
            }
        ],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": true,
        "stats": {
            "labels": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            },
            "milestones": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            }
        }
    }
]
```

## 그룹 또는 프로젝트 마이그레이션 엔티티 검색 {#retrieve-a-group-or-project-migration-entity}

그룹 또는 프로젝트 마이그레이션 엔티티의 세부 정보를 검색합니다.

```plaintext
GET /bulk_imports/:id/entities/:entity_id
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities/2"
```

```json
{
    "id": 1,
    "bulk_import_id": 1,
    "status": "finished",
    "entity_type": "group",
    "source_full_path": "source_group",
    "destination_full_path": "destination/full_path",
    "destination_name": "destination_slug",
    "destination_slug": "destination_slug",
    "destination_namespace": "destination_path",
    "parent_id": null,
    "namespace_id": 1,
    "project_id": null,
    "created_at": "2021-06-18T09:47:37.390Z",
    "updated_at": "2021-06-18T09:47:51.867Z",
    "failures": [
        {
            "relation": "group",
            "step": "extractor",
            "exception_message": "Error!",
            "exception_class": "Exception",
            "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
            "created_at": "2021-06-24T10:40:46.495Z",
            "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
            "pipeline_step": "extractor"
        }
    ],
    "migrate_projects": true,
    "migrate_memberships": true,
    "has_failures": true,
    "stats": {
        "labels": {
            "source": 10,
            "fetched": 10,
            "imported": 10
        },
        "milestones": {
            "source": 10,
            "fetched": 10,
            "imported": 10
        }
    }
}
```

## 마이그레이션 엔티티에 대한 실패한 가져오기 레코드 나열 {#list-failed-import-records-for-a-migration-entity}

{{< history >}}

- [GitLab 16.6에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/428016)

{{< /history >}}

그룹 또는 프로젝트 마이그레이션 엔티티에 대해 실패한 가져오기 레코드를 나열합니다.

```plaintext
GET /bulk_imports/:id/entities/:entity_id/failures
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities/2/failures"
```

```json
{
  "relation": "issues",
  "exception_message": "Error!",
  "exception_class": "StandardError",
  "correlation_id_value": "06289e4b064329a69de7bb2d7a1b5a97",
  "source_url": "https://gitlab.example/project/full/path/-/issues/1",
  "source_title": "Issue title"
}
```

## 마이그레이션 취소 {#cancel-a-migration}

{{< history >}}

- [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/438281)됨.

{{< /history >}}

직접 전송 마이그레이션을 취소합니다.

```plaintext
POST /bulk_imports/:id/cancel
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/cancel"
```

```json
{
  "id": 1,
  "status": "canceled",
  "source_type": "gitlab",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z",
  "has_failures": false
}
```

가능한 응답 상태 코드:

| 상태 | 설명                     |
|--------|---------------------------------|
| 200    | 마이그레이션이 성공적으로 취소되었습니다 |
| 401    | 권한 없음                    |
| 403    | 금지됨                       |
| 404    | 마이그레이션을 찾을 수 없습니다             |
| 503    | 서비스를 사용할 수 없습니다             |
