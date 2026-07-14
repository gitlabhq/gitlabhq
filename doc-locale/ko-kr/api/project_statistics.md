---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 통계 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [프로젝트](../user/project/_index.md)에 대한 통계를 검색합니다. 모든 엔드포인트는 인증이 필요합니다.

리포지토리에 대한 읽기 액세스 권한이 있어야 합니다. [개인 액세스 토큰](../user/profile/personal_access_tokens.md)은 `read_api` 범위를 가져야 합니다. [그룹 액세스 토큰](../user/group/settings/group_access_tokens.md)은 Reporter 역할 및 `read_api` 범위를 사용할 수 있습니다.

이 API는 프로젝트가 HTTP 메서드로 클론되거나 풀되는 횟수를 검색합니다. SSH fetch는 포함되지 않습니다.

## 지난 30일의 통계 검색 {#retrieve-the-statistics-of-the-last-30-days}

지정된 프로젝트에서 지난 30일 동안의 클론 및 풀 통계를 검색합니다.

```plaintext
GET /projects/:id/statistics
```

지원되는 속성:

| 특성 | 유형              | 필수 | 설명                                                                    |
|-----------|-------------------|----------|--------------------------------------------------------------------------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.     |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 특성              | 유형    | 설명 |
|------------------------|---------|-------------|
| `fetches`              | 객체  | 프로젝트의 fetch 통계입니다. |
| `fetches.days`         | 배열   | 일일 fetch 통계의 배열입니다. |
| `fetches.days[].count` | 정수 | 특정 날짜의 fetch 수입니다. |
| `fetches.days[].date`  | 문자열  | ISO 형식의 날짜(`YYYY-MM-DD`)입니다. |
| `fetches.total`        | 정수 | 지난 30일 동안의 총 fetch 수입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/statistics"
```

예제 응답:

```json
{
  "fetches": {
    "total": 50,
    "days": [
      {
        "count": 10,
        "date": "2018-01-10"
      },
      {
        "count": 10,
        "date": "2018-01-09"
      },
      {
        "count": 10,
        "date": "2018-01-08"
      },
      {
        "count": 10,
        "date": "2018-01-07"
      },
      {
        "count": 10,
        "date": "2018-01-06"
      }
    ]
  }
}
```
