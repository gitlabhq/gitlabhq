---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 검색 관리자 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [GitLab 16.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120751)

{{< /history >}}

이 API를 사용하여 [고급 검색 마이그레이션](../integration/advanced_search/elasticsearch.md#advanced-search-migrations)에 대한 정보를 검색합니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

## 모든 고급 검색 마이그레이션 나열 {#list-all-advanced-search-migrations}

GitLab 인스턴스에 대한 모든 고급 검색 마이그레이션을 나열합니다.

```plaintext
GET /admin/search/migrations
```

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/admin/search/migrations"
```

응답 예시:

```json
[
  {
    "version": 20230427555555,
    "name": "BackfillHiddenOnMergeRequests",
    "started_at": "2023-05-12T01:35:05.469+00:00",
    "completed_at": "2023-05-12T01:36:06.432+00:00",
    "completed": true,
    "obsolete": false,
    "migration_state": {}
  },
  {
    "version": 20230428500000,
    "name": "AddSuffixProjectInWikiRid",
    "started_at": "2023-05-04T18:59:43.542+00:00",
    "completed_at": "2023-05-04T18:59:43.542+00:00",
    "completed": false,
    "obsolete": false,
    "migration_state": {
      "pause_indexing": true,
      "slice": 1,
      "task_id": null,
      "max_slices": 5,
      "retry_attempt": 0
    }
  },
  {
    "version": 20230503064300,
    "name": "BackfillProjectPermissionsInBlobsUsingPermutations",
    "started_at": "2023-05-03T16:04:44.074+00:00",
    "completed_at": "2023-05-03T16:04:44.074+00:00",
    "completed": true,
    "obsolete": false,
    "migration_state": {
      "permutation_idx": 8,
      "documents_remaining": 5,
      "task_id": "I2_LXc-xQlOeu-KmjYpM8g:172820",
      "documents_remaining_for_permutation": 0
    }
  }
]
```

## 고급 검색 마이그레이션 검색 {#retrieve-an-advanced-search-migration}

마이그레이션 버전 또는 이름으로 지정된 고급 검색 마이그레이션을 검색합니다.

```plaintext
GET /admin/search/migrations/:version_or_name
```

매개 변수:

| 속성         | 유형           | 필수 | 설명                          |
|-------------------|----------------|----------|--------------------------------------|
| `version_or_name` | 정수 또는 문자열 | 예      | 마이그레이션의 버전 또는 이름입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/admin/search/migrations/20230503064300"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/admin/search/migrations/BackfillProjectPermissionsInBlobsUsingPermutations"
```

성공하면 [`200`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 표시합니다:

| 속성         | 유형     | 설명                                           |
|:------------------|:---------|:------------------------------------------------------|
| `version`         | 정수  | 마이그레이션의 버전입니다.                             |
| `name`            | 문자열   | 마이그레이션의 이름입니다.                                |
| `started_at`      | 날짜 시간 | 마이그레이션의 시작 날짜입니다.                         |
| `completed_at`    | 날짜 시간 | 마이그레이션의 완료 날짜입니다.                    |
| `completed`       | 부울  | `true`인 경우 마이그레이션이 완료됩니다.                |
| `obsolete`        | 부울  | `true`인 경우 마이그레이션이 사용 중단됨으로 표시되었습니다. |
| `migration_state` | 객체   | 저장된 마이그레이션 상태입니다.                               |

응답 예시:

```json
{
  "version": 20230503064300,
  "name": "BackfillProjectPermissionsInBlobsUsingPermutations",
  "started_at": "2023-05-03T16:04:44.074+00:00",
  "completed_at": "2023-05-03T16:04:44.074+00:00",
  "completed": true,
  "obsolete": false,
  "migration_state": {
    "permutation_idx": 8,
    "documents_remaining": 5,
    "task_id": "I2_LXc-xQlOeu-KmjYpM8g:172820",
    "documents_remaining_for_permutation": 0
  }
}
```
