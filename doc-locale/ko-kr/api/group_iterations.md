---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 반복 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [그룹 반복](../user/group/iterations/_index.md)에 액세스합니다.

프로젝트 반복의 경우 [프로젝트 반복 API](iterations.md)를 사용합니다.

## 모든 그룹 반복 나열 {#list-all-group-iterations}

지정된 그룹의 모든 반복을 나열합니다.

**자동 스케줄링 활성화**로 생성된 반복은 [반복 주기](../user/group/iterations/_index.md#iteration-cadences)에서 `null`을(를) `title` 및 `description` 필드에 대해 반환합니다.

```plaintext
GET /groups/:id/iterations
GET /groups/:id/iterations?state=opened
GET /groups/:id/iterations?state=closed
GET /groups/:id/iterations?search=version
GET /groups/:id/iterations?include_ancestors=false
GET /groups/:id/iterations?include_descendants=true
GET /groups/:id/iterations?updated_before=2013-10-02T09%3A24%3A18Z
GET /groups/:id/iterations?updated_after=2013-10-02T09%3A24%3A18Z
```

| 속성             | 유형     | 필수 | 설명 |
| --------------------- | -------- | -------- | ----------- |
| `state`               | 문자열   | 아니요       | '`opened`, `upcoming`, `current`, `closed`, 또는 `all` 반복을 반환합니다.' |
| `search`              | 문자열   | 아니요       | 제공된 문자열과 제목이 일치하는 반복만 반환합니다.                              |
| `in`                  | 문자열 배열 | 아니요 | `search` 인수에 지정된 쿼리로 유사 검색을 수행할 필드입니다. 사용 가능한 옵션은 `title` 및 `cadence_title`입니다. 기본값은 `[title]`입니다. [GitLab 16.2에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/350991) |
| `include_ancestors`   | 부울  | 아니요       | 그룹 및 해당 상위 그룹의 반복을 포함합니다. 기본값은 `true`입니다.                    |
| `include_descendants` | 부울  | 아니요       | 그룹 및 해당 하위 그룹의 반복을 포함합니다. 기본값은 `false`입니다. [GitLab 16.7에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135764) |
| `updated_before`      | 날짜/시간 | 아니요       | 지정된 날짜/시간 이전에 업데이트된 반복만 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. [GitLab 15.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/378662) |
| `updated_after`       | 날짜/시간 | 아니요       | 지정된 날짜/시간 이후에 업데이트된 반복만 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. [GitLab 15.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/378662) |

예제 요청:

```shell
  curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/iterations"
```

응답 예시:

```json
[
  {
    "id": 53,
    "iid": 13,
    "sequence": 1,
    "group_id": 5,
    "title": "Iteration II",
    "description": "Ipsum Lorem ipsum",
    "state": 2,
    "created_at": "2020-01-27T05:07:12.573Z",
    "updated_at": "2020-01-27T05:07:12.573Z",
    "due_date": "2020-02-01",
    "start_date": "2020-02-14",
    "web_url": "http://gitlab.example.com/groups/my-group/-/iterations/13"
  }
]
```
