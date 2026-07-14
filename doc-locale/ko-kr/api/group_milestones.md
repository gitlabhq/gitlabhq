---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 마일스톤 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [그룹 마일스톤](../user/project/milestones/_index.md)을 관리합니다.

프로젝트 마일스톤의 경우 [프로젝트 마일스톤 API](milestones.md)를 사용합니다.

## 그룹 마일스톤 나열 {#list-group-milestones}

그룹 마일스톤 목록을 반환합니다.

```plaintext
GET /groups/:id/milestones
GET /groups/:id/milestones?iids[]=42
GET /groups/:id/milestones?iids[]=42&iids[]=43
GET /groups/:id/milestones?state=active
GET /groups/:id/milestones?state=closed
GET /groups/:id/milestones?title=1.0
GET /groups/:id/milestones?search=version
GET /groups/:id/milestones?search_title=17.3+17.4
GET /groups/:id/milestones?search_title=17.3%2017.4
GET /groups/:id/milestones?updated_before=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?updated_after=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?containing_date=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?start_date=2013-10-02T09%3A24%3A18Z&end_date=2013-11-02T09%3A24%3A18Z
```

매개변수:

| 속성                   | 유형   | 필수 | 설명 |
| ---------                   | ------ | -------- | ----------- |
| `id`                        | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `iids[]`                    | 정수 배열 | 아니요 | 주어진 `iid`을(를) 갖는 마일스톤만 반환합니다. `include_ancestors`이(가) `true`인 경우 무시됩니다. |
| `state`                     | 문자열 | 아니요 | `active` 또는 `closed` 마일스톤만 반환합니다. |
| `title`                     | 문자열 | 아니요 | 주어진 `title`(대소문자 구분)을(를) 갖는 마일스톤만 반환합니다. |
| `search`                    | 문자열 | 아니요 | 제목 또는 설명이 제공된 문자열과 일치하는 마일스톤만 반환합니다(대소문자 구분 안 함). |
| `search_title`              | 문자열 | 아니요 | 제목이 제공된 문자열과 일치하는 마일스톤만 반환합니다(대소문자 구분 안 함). 여러 용어를 이스케이프 공백(`+`) 또는 `%20`으로 구분하여 제공할 수 있으며 함께 AND 처리됩니다. 예: `17.4+17.5`은(는) 부분 문자열 `17.4` 및 `17.5`(순서는 상관없음)와 일치합니다. GitLab 11.8에서 도입되었습니다. |
| `include_parent_milestones` | 부울 | 아니요 | GitLab 16.7에서 [지원이 중단되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/433298). 대신 `include_ancestors`를 사용합니다. |
| `include_ancestors`         | 부울 | 아니요 | 모든 상위 그룹의 마일스톤을 포함합니다. |
| `include_descendants`       | 부울 | 아니요 | 그룹 및 해당 하위 그룹의 마일스톤을 포함합니다. GitLab 16.7에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/421030). |
| `updated_before`            | 날짜/시간 | 아니요 | 지정된 날짜/시간 이전에 업데이트된 마일스톤만 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. GitLab 15.10에서 도입되었습니다. |
| `updated_after`             | 날짜/시간 | 아니요 | 지정된 날짜/시간 이후에 업데이트된 마일스톤만 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. GitLab 15.10에서 도입되었습니다. |
| `containing_date`           | 날짜/시간 | 아니요 | `start_date <= containing_date <= due_date`인 마일스톤만 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. GitLab 13.5에서 도입되었습니다. |
| `start_date`                | 날짜/시간 | 아니요 | `due_date >=` 제공된 `start_date`인 마일스톤만 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. 참고: `end_date`도 제공된 경우에만 유효합니다. GitLab 12.8에서 도입되었습니다. |
| `end_date`                  | 날짜/시간 | 아니요 | `start_date <=` 제공된 `end_date`인 마일스톤만 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. 참고: `start_date`도 제공된 경우에만 유효합니다. GitLab 12.8에서 도입되었습니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/milestones"
```

응답 예시:

```json
[
  {
    "id": 12,
    "iid": 3,
    "group_id": 16,
    "title": "10.0",
    "description": "Version",
    "due_date": "2013-11-29",
    "start_date": "2013-11-10",
    "state": "active",
    "updated_at": "2013-10-02T09:24:18Z",
    "created_at": "2013-10-02T09:24:18Z",
    "expired": false,
    "web_url": "https://gitlab.com/groups/gitlab-org/-/milestones/42"
  }
]
```

## 단일 마일스톤 가져오기 {#get-single-milestone}

단일 그룹 마일스톤을 가져옵니다.

```plaintext
GET /groups/:id/milestones/:milestone_id
```

매개변수:

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수 | 예 | 그룹 마일스톤의 ID |

## 새 마일스톤 생성 {#create-new-milestone}

새 그룹 마일스톤을 생성합니다.

```plaintext
POST /groups/:id/milestones
```

매개변수:

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `title` | 문자열 | 예 | 마일스톤의 제목 |
| `description` | 문자열 | 아니요 | 마일스톤의 설명 |
| `due_date` | 날짜 | 아니요 | 마일스톤의 마감일(ISO 8601 형식(`YYYY-MM-DD`)) |
| `start_date` | 날짜 | 아니요 | 마일스톤의 시작일(ISO 8601 형식(`YYYY-MM-DD`)) |

## 마일스톤 편집 {#edit-milestone}

기존 그룹 마일스톤을 업데이트합니다.

```plaintext
PUT /groups/:id/milestones/:milestone_id
```

매개변수:

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수 | 예 | 그룹 마일스톤의 ID |
| `title` | 문자열 | 아니요 | 마일스톤의 제목 |
| `description` | 문자열 | 아니요 | 마일스톤의 설명 |
| `due_date` | 날짜 | 아니요 | 마일스톤의 마감일(ISO 8601 형식(`YYYY-MM-DD`)) |
| `start_date` | 날짜 | 아니요 | 마일스톤의 시작일(ISO 8601 형식(`YYYY-MM-DD`)) |
| `state_event` | 문자열 | 아니요 | 마일스톤의 상태 이벤트 _(`close` 또는 `activate`)_ |

## 그룹 마일스톤 삭제 {#delete-group-milestone}

그룹의 Developer 역할을 가진 사용자만 가능합니다.

```plaintext
DELETE /groups/:id/milestones/:milestone_id
```

매개변수:

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수 | 예 | 그룹 마일스톤의 ID |

## 단일 마일스톤에 할당된 모든 이슈 가져오기 {#get-all-issues-assigned-to-a-single-milestone}

단일 그룹 마일스톤에 할당된 모든 이슈를 가져옵니다.

```plaintext
GET /groups/:id/milestones/:milestone_id/issues
```

매개변수:

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수 | 예 | 그룹 마일스톤의 ID |

현재 이 API 엔드포인트는 하위 그룹의 이슈를 반환하지 않습니다. 모든 마일스톤의 이슈를 가져오려면 [이슈 목록 API](issues.md#list-all-issues)를 사용하고 특정 마일스톤을 필터링할 수 있습니다(예: `GET /issues?milestone=1.0.0&state=opened`).

## 단일 마일스톤에 할당된 모든 머지 리퀘스트 가져오기 {#get-all-merge-requests-assigned-to-a-single-milestone}

단일 그룹 마일스톤에 할당된 모든 머지 리퀘스트를 가져옵니다.

```plaintext
GET /groups/:id/milestones/:milestone_id/merge_requests
```

매개변수:

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수 | 예 | 그룹 마일스톤의 ID |

## 단일 마일스톤에 대한 모든 번다운 차트 이벤트 가져오기 {#get-all-burndown-chart-events-for-a-single-milestone}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

단일 마일스톤에 대한 모든 번다운 차트 이벤트를 가져옵니다.

```plaintext
GET /groups/:id/milestones/:milestone_id/burndown_events
```

매개변수:

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `milestone_id` | 정수 | 예 | 그룹 마일스톤의 ID |
