---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 이슈 통계를 위한 REST API 설명서입니다.
title: 이슈 통계 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [이슈](../user/project/issues/_index.md)에 대한 통계를 검색합니다. 이 API에 대한 모든 호출에는 인증이 필요합니다.

사용자가 프로젝트의 멤버가 아니고 프로젝트가 비공개인 경우, 해당 프로젝트에 대한 `GET` 요청 결과는 `404` 상태 코드입니다.

## 사용자에 대한 이슈 통계 검색 {#retrieve-issues-statistics-for-a-user}

현재 사용자가 액세스할 수 있는 이슈의 통계를 검색합니다. 기본적으로 현재 사용자가 작성한 이슈만 반환합니다. 모든 이슈를 가져오려면 `scope` 속성을 `all`(으)로 설정합니다.

```plaintext
GET /issues_statistics
GET /issues_statistics?labels=foo
GET /issues_statistics?labels=foo,bar
GET /issues_statistics?labels=foo,bar&state=opened
GET /issues_statistics?milestone=1.0.0
GET /issues_statistics?milestone=1.0.0&state=opened
GET /issues_statistics?iids[]=42&iids[]=43
GET /issues_statistics?author_id=5
GET /issues_statistics?assignee_id=5
GET /issues_statistics?my_reaction_emoji=star
GET /issues_statistics?search=foo&in=title
GET /issues_statistics?confidential=true
```

| 속성           | 유형             | 필수   | 설명                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `labels`            | 문자열           | 아니요         | 쉼표로 구분된 레이블 이름 목록입니다. 이슈는 반환되려면 모든 레이블을 가져야 합니다. `None`은 레이블이 없는 모든 이슈를 나열합니다. `Any`는 하나 이상의 레이블이 있는 모든 이슈를 나열합니다. |
| `milestone`         | 문자열           | 아니요         | 마일스톤 제목입니다. `None`은 마일스톤이 없는 모든 이슈를 나열합니다. `Any`는 할당된 마일스톤이 있는 모든 이슈를 나열합니다.                             |
| `scope`             | 문자열           | 아니요         | 주어진 범위에 대한 이슈를 반환합니다: `created_by_me`, `assigned_to_me` 또는 `all`. 기본값은 `created_by_me`입니다. |
| `author_id`         | 정수          | 아니요         | 주어진 사용자 `id`이 작성한 이슈를 반환합니다. `author_username`과 상호 배타적입니다. `scope=all` 또는 `scope=assigned_to_me`과 결합합니다. |
| `author_username`   | 문자열           | 아니요         | 주어진 `username`이 작성한 이슈를 반환합니다. `author_id`과 유사하며 `author_id`(과)와 상호 배타적입니다. |
| `assignee_id`       | 정수          | 아니요         | 주어진 사용자 `id`에게 할당된 이슈를 반환합니다. `assignee_username`(과)와 상호 배타적입니다. `None`은 할당되지 않은 이슈를 반환합니다. `Any`는 담당자가 있는 이슈를 반환합니다. |
| `assignee_username` | 문자열 배열     | 아니요         | 주어진 `username`에게 할당된 이슈를 반환합니다. `assignee_id`과 유사하며 `assignee_id`(과)와 상호 배타적입니다. GitLab CE에서 `assignee_username` 배열은 단일 값만 포함하거나 그렇지 않으면 유효하지 않은 매개변수 오류가 반환됩니다. |
| `epic_id`           | 정수      | 아니요         | 주어진 에픽 ID와 연관된 이슈를 반환합니다. `None`은 에픽과 연관되지 않은 이슈를 반환합니다. `Any`는 에픽과 연관된 이슈를 반환합니다. Premium 및 Ultimate만 해당합니다. |
| `my_reaction_emoji` | 문자열           | 아니요         | 인증된 사용자가 주어진 `emoji`에 반응한 이슈를 반환합니다. `None`는 반응이 없는 이슈를 반환합니다. `Any`는 하나 이상의 반응이 있는 이슈를 반환합니다. |
| `iids[]`            | 정수 배열    | 아니요         | 주어진 `iid`을 가진 이슈만 반환합니다.                                                                                                       |
| `search`            | 문자열           | 아니요         | 이슈의 `title` 및 `description`을 기준으로 검색합니다.                                                                                               |
| `in`                | 문자열           | 아니요         | `search` 속성의 범위를 수정합니다. `title`, `description` 또는 쉼표로 결합한 문자열입니다. 기본값은 `title,description`입니다             |
| `created_after`     | 날짜/시간         | 아니요         | 주어진 시간 이후에 작성된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `created_before`    | 날짜/시간         | 아니요         | 주어진 시간 이전에 작성된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `updated_after`     | 날짜/시간         | 아니요         | 주어진 시간 이후에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `updated_before`    | 날짜/시간         | 아니요         | 주어진 시간 이전에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `confidential`      | 부울          | 아니요         | 기밀 또는 공개 이슈를 필터링합니다.                                                                                                               |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues_statistics"
```

응답 예시:

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```

## 그룹에 대한 이슈 통계 검색 {#retrieve-issues-statistics-for-a-group}

지정된 그룹의 이슈 통계를 검색합니다.

```plaintext
GET /groups/:id/issues_statistics
GET /groups/:id/issues_statistics?labels=foo
GET /groups/:id/issues_statistics?labels=foo,bar
GET /groups/:id/issues_statistics?labels=foo,bar&state=opened
GET /groups/:id/issues_statistics?milestone=1.0.0
GET /groups/:id/issues_statistics?milestone=1.0.0&state=opened
GET /groups/:id/issues_statistics?iids[]=42&iids[]=43
GET /groups/:id/issues_statistics?search=issue+title+or+description
GET /groups/:id/issues_statistics?author_id=5
GET /groups/:id/issues_statistics?assignee_id=5
GET /groups/:id/issues_statistics?my_reaction_emoji=star
GET /groups/:id/issues_statistics?confidential=true
```

| 속성           | 유형             | 필수   | 설명                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)                 |
| `labels`            | 문자열           | 아니요         | 쉼표로 구분된 레이블 이름 목록입니다. 이슈는 반환되려면 모든 레이블을 가져야 합니다. `None`은 레이블이 없는 모든 이슈를 나열합니다. `Any`는 하나 이상의 레이블이 있는 모든 이슈를 나열합니다. |
| `iids[]`            | 정수 배열    | 아니요         | 주어진 `iid`을 가진 이슈만 반환합니다.                                                                                 |
| `milestone`         | 문자열           | 아니요         | 마일스톤 제목입니다. `None`은 마일스톤이 없는 모든 이슈를 나열합니다. `Any`는 할당된 마일스톤이 있는 모든 이슈를 나열합니다.       |
| `scope`             | 문자열           | 아니요         | 주어진 범위에 대한 이슈를 반환합니다: `created_by_me`, `assigned_to_me` 또는 `all`. |
| `author_id`         | 정수          | 아니요         | 주어진 사용자 `id`이 작성한 이슈를 반환합니다. `author_username`과 상호 배타적입니다. `scope=all` 또는 `scope=assigned_to_me`과 결합합니다. |
| `author_username`   | 문자열           | 아니요         | 주어진 `username`이 작성한 이슈를 반환합니다. `author_id`과 유사하며 `author_id`(과)와 상호 배타적입니다. |
| `assignee_id`       | 정수          | 아니요         | 주어진 사용자 `id`에게 할당된 이슈를 반환합니다. `assignee_username`(과)와 상호 배타적입니다. `None`은 할당되지 않은 이슈를 반환합니다. `Any`는 담당자가 있는 이슈를 반환합니다. |
| `assignee_username` | 문자열 배열     | 아니요         | 주어진 `username`에게 할당된 이슈를 반환합니다. `assignee_id`과 유사하며 `assignee_id`(과)와 상호 배타적입니다. GitLab CE에서 `assignee_username` 배열은 단일 값만 포함하거나 그렇지 않으면 유효하지 않은 매개변수 오류가 반환됩니다. |
| `my_reaction_emoji` | 문자열           | 아니요         | 인증된 사용자가 주어진 `emoji`에 반응한 이슈를 반환합니다. `None`는 반응이 없는 이슈를 반환합니다. `Any`는 하나 이상의 반응이 있는 이슈를 반환합니다. |
| `search`            | 문자열           | 아니요         | 그룹 이슈의 `title` 및 `description`을 기준으로 검색합니다.                                                                   |
| `created_after`     | 날짜/시간         | 아니요         | 주어진 시간 이후에 작성된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `created_before`    | 날짜/시간         | 아니요         | 주어진 시간 이전에 작성된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `updated_after`     | 날짜/시간         | 아니요         | 주어진 시간 이후에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `updated_before`    | 날짜/시간         | 아니요         | 주어진 시간 이전에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `confidential`      | 부울          | 아니요         | 기밀 또는 공개 이슈를 필터링합니다.                                                                                         |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/issues_statistics"
```

응답 예시:

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```

## 프로젝트에 대한 이슈 통계 검색 {#retrieve-issues-statistics-for-a-project}

지정된 프로젝트의 이슈 통계를 검색합니다.

```plaintext
GET /projects/:id/issues_statistics
GET /projects/:id/issues_statistics?labels=foo
GET /projects/:id/issues_statistics?labels=foo,bar
GET /projects/:id/issues_statistics?labels=foo,bar&state=opened
GET /projects/:id/issues_statistics?milestone=1.0.0
GET /projects/:id/issues_statistics?milestone=1.0.0&state=opened
GET /projects/:id/issues_statistics?iids[]=42&iids[]=43
GET /projects/:id/issues_statistics?search=issue+title+or+description
GET /projects/:id/issues_statistics?author_id=5
GET /projects/:id/issues_statistics?assignee_id=5
GET /projects/:id/issues_statistics?my_reaction_emoji=star
GET /projects/:id/issues_statistics?confidential=true
```

| 속성           | 유형             | 필수   | 설명                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)               |
| `iids[]`            | 정수 배열    | 아니요         | 주어진 `iid`을 가진 이슈만 반환합니다.                                                                              |
| `labels`            | 문자열           | 아니요         | 쉼표로 구분된 레이블 이름 목록입니다. 이슈는 반환되려면 모든 레이블을 가져야 합니다. `None`은 레이블이 없는 모든 이슈를 나열합니다. `Any`는 하나 이상의 레이블이 있는 모든 이슈를 나열합니다. |
| `milestone`         | 문자열           | 아니요         | 마일스톤 제목입니다. `None`은 마일스톤이 없는 모든 이슈를 나열합니다. `Any`는 할당된 마일스톤이 있는 모든 이슈를 나열합니다.       |
| `scope`             | 문자열           | 아니요         | 주어진 범위에 대한 이슈를 반환합니다: `created_by_me`, `assigned_to_me` 또는 `all`. |
| `author_id`         | 정수          | 아니요         | 주어진 사용자 `id`이 작성한 이슈를 반환합니다. `author_username`과 상호 배타적입니다. `scope=all` 또는 `scope=assigned_to_me`과 결합합니다. |
| `author_username`   | 문자열           | 아니요         | 주어진 `username`이 작성한 이슈를 반환합니다. `author_id`과 유사하며 `author_id`(과)와 상호 배타적입니다. |
| `assignee_id`       | 정수          | 아니요         | 주어진 사용자 `id`에게 할당된 이슈를 반환합니다. `assignee_username`(과)와 상호 배타적입니다. `None`은 할당되지 않은 이슈를 반환합니다. `Any`는 담당자가 있는 이슈를 반환합니다. |
| `assignee_username` | 문자열 배열     | 아니요         | 주어진 `username`에게 할당된 이슈를 반환합니다. `assignee_id`과 유사하며 `assignee_id`(과)와 상호 배타적입니다. GitLab CE에서 `assignee_username` 배열은 단일 값만 포함하거나 그렇지 않으면 유효하지 않은 매개변수 오류가 반환됩니다. |
| `my_reaction_emoji` | 문자열           | 아니요         | 인증된 사용자가 주어진 `emoji`에 반응한 이슈를 반환합니다. `None`는 반응이 없는 이슈를 반환합니다. `Any`는 하나 이상의 반응이 있는 이슈를 반환합니다. |
| `search`            | 문자열           | 아니요         | 프로젝트 이슈의 `title` 및 `description`을 기준으로 검색합니다.                                                                 |
| `created_after`     | 날짜/시간         | 아니요         | 주어진 시간 이후에 작성된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `created_before`    | 날짜/시간         | 아니요         | 주어진 시간 이전에 작성된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `updated_after`     | 날짜/시간         | 아니요         | 주어진 시간 이후에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `updated_before`    | 날짜/시간         | 아니요         | 주어진 시간 이전에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `confidential`      | 부울          | 아니요         | 기밀 또는 공개 이슈를 필터링합니다.                                                                                         |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues_statistics"
```

응답 예시:

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```
