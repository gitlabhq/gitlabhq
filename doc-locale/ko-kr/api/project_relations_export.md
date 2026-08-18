---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 관계 내보내기 API
description: "REST API를 사용하여 프로젝트 관계를 내보냅니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API는 [직접 전송으로 그룹 마이그레이션](../user/group/import/_index.md) 중에 대상 인스턴스에서 프로젝트 구조를 마이그레이션하는 데 사용됩니다. 일반적으로 이 API를 직접 사용할 필요는 없습니다.

이 문맥에서 {{< glossary-tooltip text="관계" >}}는 머지 리퀘스트와 같은 내보낼 수 있는 항목입니다. 내보낼 때 관계는 레이블과 같은 관계와 관련된 모든 항목을 포함합니다.

이 API를 사용하려면 GitLab 인스턴스가 특정 [전제 조건](../user/group/import/direct_transfer_migrations.md#prerequisites)을 충족해야 합니다.

> [!note]
> 이 API는 파일 기반 마이그레이션을 위한 [그룹 가져오기 및 내보내기 API](group_import_export.md)와 함께 사용할 수 없습니다.

## 프로젝트에 대한 새 내보내기 예약 {#schedule-a-new-export-for-a-project}

지정된 프로젝트에 대한 관계 내보내기를 예약합니다.

```plaintext
POST /projects/:id/export_relations
```

| 속성 | 유형              | 필수 | 설명                                        |
|-----------|-------------------|----------|----------------------------------------------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID입니다.                                 |
| `batched` | 부울           | 아니요       | 배치로 내보낼지 여부입니다.                      |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations"
```

```json
{
  "message": "202 Accepted"
}
```

## 내보내기 상태 검색 {#retrieve-the-status-of-an-export}

관계 내보내기의 상태를 검색합니다.

```plaintext
GET /projects/:id/export_relations/status
```

| 속성  | 유형              | 필수 | 설명                                        |
|------------|-------------------|----------|----------------------------------------------------|
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID입니다.                                 |
| `relation` | 문자열            | 아니요       | 보려는 프로젝트 최상위 관계의 이름입니다.    |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations/status"
```

상태는 다음 중 하나일 수 있습니다:

- `0`: `started`
- `1`: `finished`
- `-1`: `failed`

```json
[
  {
    "relation": "project_badges",
    "status": 1,
    "error": null,
    "updated_at": "2021-05-04T11:25:20.423Z",
    "batched": true,
    "batches_count": 1,
    "batches": [
      {
        "status": 1,
        "batch_number": 1,
        "objects_count": 1,
        "error": null,
        "updated_at": "2021-05-04T11:25:20.423Z"
      }
    ]
  },
  {
    "relation": "boards",
    "status": 1,
    "error": null,
    "updated_at": "2021-05-04T11:25:20.085Z",
    "batched": false,
    "batches_count": 0
  }
]
```

## 내보내기 다운로드 {#download-an-export}

완료된 관계 내보내기를 다운로드합니다.

```plaintext
GET /projects/:id/export_relations/download
```

| 속성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID입니다. |
| `relation`     | 문자열            | 예      | 다운로드하려는 프로젝트 최상위 관계의 이름입니다. |
| `batched`      | 부울           | 아니요       | 내보내기가 배치로 처리되었는지 여부입니다. |
| `batch_number` | 정수           | 아니요       | 다운로드할 내보내기 배치의 번호입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --remote-header-name \
  --remote-name \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations/download?relation=labels"
```

```shell
ls labels.ndjson.gz
labels.ndjson.gz
```

## 관련 항목 {#related-topics}

- [그룹 관계 내보내기 API](group_relations_export.md)
