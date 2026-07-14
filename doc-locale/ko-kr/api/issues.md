---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 이슈 REST API에 대한 설명서입니다.
title: 이슈 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [이슈](../user/project/issues/_index.md)를 관리합니다. 다음을 수행할 수 있습니다.

- 이슈를 만들고, 업데이트하고, 삭제합니다.
- 담당자, 레이블, 마일스톤, 시간 추적과 같은 이슈 메타데이터를 관리합니다.
- 이슈와 머지 리퀘스트를 상호 참조합니다.
- 프로젝트와 에픽 간 이슈 이동 및 승격을 추적합니다.
- 권한 부여 검사로 액세스 및 표시 가능성을 제어합니다.

사용자가 비공개 프로젝트의 멤버가 아닌 경우, `GET` 요청은 해당 프로젝트에서 `404` 상태 코드를 반환합니다.

이 API의 응답은 [페이지로 나뉘어](rest/_index.md#pagination) 있으며 기본적으로 20개의 결과를 반환합니다.

> [!note]
> `references.relative` 속성은 요청한 이슈의 그룹 또는 프로젝트에 상대적입니다. 프로젝트에서 이슈를 가져올 때, `relative` 형식은 `short` 형식과 같습니다. 그룹 또는 프로젝트 전체에서 요청할 때는 `full` 형식과 같아야 합니다.

## 모든 이슈 나열 {#list-all-issues}

인증된 사용자가 액세스할 수 있는 모든 이슈를 나열합니다. 기본적으로 현재 사용자가 만든 이슈만 반환합니다. 모든 이슈를 나열하려면 `scope=all` 매개변수를 사용합니다.

```plaintext
GET /issues
GET /issues?assignee_id=5
GET /issues?author_id=5
GET /issues?confidential=true
GET /issues?iids[]=42&iids[]=43
GET /issues?labels=foo
GET /issues?labels=foo,bar
GET /issues?labels=foo,bar&state=opened
GET /issues?milestone=1.0.0
GET /issues?milestone=1.0.0&state=opened
GET /issues?my_reaction_emoji=star
GET /issues?search=foo&in=title
GET /issues?state=closed
GET /issues?state=opened
```

지원되는 속성:

| 속성                       | 유형          | 필수   | 설명                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|---------------------------------|---------------| ---------- |------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `assignee_id`                   | 정수       | 아니요         | 지정된 사용자 `id`에 할당된 이슈를 반환합니다. `assignee_username`과(와) 상호 배타적입니다. `None`은(는) 할당되지 않은 이슈를 반환합니다. `Any`은(는) 담당자가 있는 이슈를 반환합니다.                                                                                                                                                                                                                                                                                                                                                                                                   |
| `assignee_username`             | 문자열 배열  | 아니요         | 지정된 `username`에 할당된 이슈를 반환합니다. `assignee_id`과(와) 유사하며 `assignee_id`과(와) 상호 배타적입니다. GitLab CE에서 `assignee_username` 배열은 단일 값만 포함해야 합니다. 그렇지 않으면 잘못된 매개변수 오류가 반환됩니다. 모든 전달된 사용자에 할당된 이슈만 반환됩니다. |
| `author_id`                     | 정수       | 아니요         | 지정된 사용자 `id`이(가) 만든 이슈를 반환합니다. `author_username`과(와) 상호 배타적입니다. `scope=all` 또는 `scope=assigned_to_me`과(와) 결합합니다.                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `author_username`               | 문자열        | 아니요         | 지정된 `username`이(가) 만든 이슈를 반환합니다. `author_id`과(와) 유사하며 `author_id`과(와) 상호 배타적입니다.                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `confidential`                  | 부울       | 아니요         | 기밀 또는 공개 이슈를 필터링합니다.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `created_after`                 | 날짜/시간      | 아니요         | 지정된 시간 이후에 생성된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `created_before`                | 날짜/시간      | 아니요         | 지정된 시간 이전 또는 그 시간에 생성된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `due_date`                      | 문자열        | 아니요         | 기한이 없거나 기한이 지났거나, 기한이 이번 주, 이번 달, 또는 2주 전에서 다음 달 사이인 이슈를 반환합니다. 허용: `0`(기한 없음), `any`, `today`, `tomorrow`, `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`.                                                                                                                                                                                                                                                                                                        |
| `epic_id`        | 정수       | 아니요         | 지정된 에픽 ID와 연결된 이슈를 반환합니다. `None`은(는) 에픽과 연결되지 않은 이슈를 반환합니다. `Any`은(는) 에픽과 연결된 이슈를 반환합니다. Premium 및 Ultimate 전용입니다.                                                                                                                                                                                                                                                                                                                                                                         |
| `health_status`  | 문자열        | 아니요         | 지정된 `health_status`을(를) 가진 이슈를 반환합니다. _([GitLab 15.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/370721))._ [GitLab 15.5 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/370721)에서 `None`은(는) 상태가 지정되지 않은 이슈를 반환하고, `Any`은(는) 상태가 지정된 이슈를 반환합니다. Ultimate 전용입니다.                                                                                                                                                                                                                |
| `iids[]`                        | 정수 배열 | 아니요         | 지정된 `iid`을(를) 가진 이슈만 반환합니다.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `in`                            | 문자열        | 아니요         | `search` 속성의 범위를 수정합니다. `title`, `description`, 또는 쉼표로 이들을 결합한 문자열입니다. 기본값은 `title,description`입니다.                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `issue_type`                    | 문자열        | 아니요         | 특정 이슈 유형으로 필터링합니다. `issue`, `incident`, `test_case` 또는 `task` 중 하나입니다.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `iteration_id`                  | 정수       | 아니요         | 지정된 반복에 할당된 이슈를 반환합니다. `None`은(는) 반복에 속하지 않은 이슈를 반환합니다. `Any`은(는) 반복에 속한 이슈를 반환합니다. `iteration_title`과(와) 상호 배타적입니다. Premium 및 Ultimate 전용입니다.                                                                                                                                                                                                                                                                                                                                    |
| `iteration_title`               | 문자열        | 아니요       | 지정된 제목의 반복에 할당된 이슈를 반환합니다. `iteration_id`과(와) 유사하며 `iteration_id`과(와) 상호 배타적입니다. Premium 및 Ultimate 전용입니다.                                                                                                                                                                                                                                                                                                                                                                                                         |
| `labels`                        | 문자열        | 아니요         | 쉼표로 구분된 레이블 이름 목록이며, 이슈는 반환되기 위해 모든 레이블을 가져야 합니다. `None`은(는) 레이블이 없는 모든 이슈를 나열합니다. `Any`은(는) 최소 1개의 레이블을 가진 모든 이슈를 나열합니다. `No+Label`(더 이상 사용 안 함)은(는) 레이블이 없는 모든 이슈를 나열합니다. 미리 정의된 이름은 대소문자를 구분하지 않습니다.                                                                                                                                                                                                                                                                                               |
| `milestone_id`                  | 문자열        | 아니요         | 지정된 타임박스 값(`None`, `Any`, `Upcoming`, `Started`)의 마일스톤에 할당된 이슈를 반환합니다. `None`은(는) 마일스톤이 없는 모든 이슈를 나열합니다. `Any`은(는) 할당된 마일스톤이 있는 모든 이슈를 나열합니다. `Upcoming`은(는) 향후에 기한이 있는 마일스톤에 할당된 모든 이슈를 나열합니다. `Started`은(는) 열려 있거나 시작된 마일스톤에 할당된 모든 이슈를 나열합니다. `Upcoming` 및 `Started`의 논리는 [GraphQL API](../user/project/milestones/_index.md#special-milestone-filters)에서 사용된 논리와 다릅니다. `milestone` 및 `milestone_id`은(는) 상호 배타적입니다. |
| `milestone`                     | 문자열        | 아니요         | 마일스톤 제목입니다. `None`은(는) 마일스톤이 없는 모든 이슈를 나열합니다. `Any`은(는) 할당된 마일스톤이 있는 모든 이슈를 나열합니다. `None` 또는 `Any`을(를) 사용하면 [향후 더 이상 사용할 수 없습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/336044). 대신 `milestone_id` 속성을 사용합니다. `milestone` 및 `milestone_id`은(는) 상호 배타적입니다.                                                                                                                                                                                                                                   |
| `my_reaction_emoji`             | 문자열        | 아니요         | 인증된 사용자가 지정된 `emoji`에 반응한 이슈를 반환합니다. `None`은(는) 반응이 없는 이슈를 반환합니다. `Any`은(는) 최소 1개의 반응이 있는 이슈를 반환합니다.                                                                                                                                                                                                                                                                                                                                                                                                    |
| `non_archived`                  | 부울       | 아니요         | 보관되지 않은 프로젝트의 이슈만 반환합니다. `false`인 경우 응답은 보관 및 보관되지 않은 프로젝트의 이슈를 모두 반환합니다. 기본값은 `true`입니다.                                                                                                                                                                                                                                                                                                                                                                                                                |
| `not`                           | 해시          | 아니요         | 제공된 매개변수와 일치하지 않는 이슈를 반환합니다. 허용: `assignee_id`, `assignee_username`, `author_id`, `author_username`, `iids`, `iteration_id`, `iteration_title`, `labels`, `milestone`, `milestone_id` 및 `weight`.                                                                                                                                                                                                                                                                                                                                   |
| `order_by`                      | 문자열        | 아니요         | `created_at`, `due_date`, `label_priority`, `milestone_due`, `popularity`, `priority`, `relative_position`, `title`, `updated_at` 또는 `weight` 필드로 정렬된 이슈를 반환합니다. 기본값은 `created_at`입니다.                                                                                                                                                                                                                                                                                                                                                               |
| `scope`                         | 문자열        | 아니요         | 지정된 범위에 대한 이슈를 반환합니다: `created_by_me`, `assigned_to_me` 또는 `all`. `created_by_me`을(를) 기본값으로 합니다.                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `search`                        | 문자열        | 아니요         | `title` 및 `description` 이슈를 검색합니다.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `sort`                          | 문자열        | 아니요         | `asc` 또는 `desc` 순서로 정렬된 이슈를 반환합니다. 기본값은 `desc`입니다.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `state`                         | 문자열        | 아니요         | `all` 이슈 또는 `opened` 또는 `closed`인 이슈만 반환합니다.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `updated_after`                 | 날짜/시간      | 아니요         | 지정된 시간 이후에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `updated_before`                | 날짜/시간      | 아니요         | 지정된 시간 이전 또는 그 시간에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `weight`                        | 정수       | 아니요         | 지정된 `weight`을(를) 가진 이슈를 반환합니다. `None`은(는) 가중치가 지정되지 않은 이슈를 반환합니다. `Any`은(는) 가중치가 지정된 이슈를 반환합니다. Premium 및 Ultimate 전용입니다.                                                                                                                                                                                                                                                                                                                                                                                                      |
| `with_labels_details`           | 부울       | 아니요         | `true`인 경우 응답은 labels 필드의 각 레이블에 대한 자세한 정보를 반환합니다: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. 기본값은 `false`입니다.                                                                                                                                                                                                                                                                                                                                                                                                |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues"
```

예제 응답:

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "author" : {
         "state" : "active",
         "id" : 18,
         "web_url" : "https://gitlab.example.com/eileen.lowe",
         "name" : "Alexandra Bashirian",
         "avatar_url" : null,
         "username" : "eileen.lowe"
      },
      "milestone" : {
         "project_id" : 1,
         "description" : "Ducimus nam enim ex consequatur cumque ratione.",
         "state" : "closed",
         "due_date" : null,
         "iid" : 2,
         "created_at" : "2016-01-04T15:31:39.996Z",
         "title" : "v4.0",
         "id" : 17,
         "updated_at" : "2016-01-04T15:31:39.996Z"
      },
      "project_id" : 1,
      "assignees" : [{
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      }],
      "assignee" : {
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      },
      "type" : "ISSUE",
      "updated_at" : "2016-01-04T15:31:51.081Z",
      "closed_at" : null,
      "closed_by" : null,
      "id" : 76,
      "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
      "created_at" : "2016-01-04T15:31:51.081Z",
      "moved_to_id" : null,
      "iid" : 6,
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "user_notes_count": 1,
      "start_date": null,
      "due_date": "2016-07-22",
      "imported":false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/6",
      "references": {
        "short": "#6",
        "relative": "my-group/my-project#6",
        "full": "my-group/my-project#6"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/1/issues/76",
         "notes":"http://gitlab.example.com/api/v4/projects/1/issues/76/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/1/issues/76/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/1",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `weight` 속성이 포함됩니다:

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "weight": null,
      ...
   }
]
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `epic` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `iteration` 속성이 포함됩니다:

```json
{
   "iteration": {
      "id":90,
      "iid":4,
      "sequence":2,
      "group_id":162,
      "title":null,
      "description":null,
      "state":2,
      "created_at":"2022-03-14T05:21:11.929Z",
      "updated_at":"2022-03-14T05:21:11.929Z",
      "start_date":"2022-03-08",
      "due_date":"2022-03-14",
      "web_url":"https://gitlab.com/groups/my-group/-/iterations/90"
   }
   ...
}
```

GitLab Ultimate 사용자가 만든 이슈에는 `health_status` 속성이 포함됩니다:

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> `assignee` 열은 더 이상 사용되지 않습니다. 이를 GitLab EE API에 맞추기 위해 단일 크기의 배열 `assignees`로 표시합니다.
>
> `epic_iid` 속성은 더 이상 사용되지 않으며 API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)입니다. `iid` of the `epic` 속성을 대신 사용합니다.

## 모든 그룹 이슈 나열 {#list-all-group-issues}

지정된 그룹의 모든 이슈를 나열합니다.

그룹이 비공개인 경우 권한을 부여하기 위해 자격 증명을 제공해야 합니다. 이 작업을 수행하는 선호되는 방법은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을(를) 사용하는 것입니다.

```plaintext
GET /groups/:id/issues
GET /groups/:id/issues?assignee_id=5
GET /groups/:id/issues?author_id=5
GET /groups/:id/issues?confidential=true
GET /groups/:id/issues?iids[]=42&iids[]=43
GET /groups/:id/issues?labels=foo
GET /groups/:id/issues?labels=foo,bar
GET /groups/:id/issues?labels=foo,bar&state=opened
GET /groups/:id/issues?milestone=1.0.0
GET /groups/:id/issues?milestone=1.0.0&state=opened
GET /groups/:id/issues?my_reaction_emoji=star
GET /groups/:id/issues?search=issue+title+or+description
GET /groups/:id/issues?state=closed
GET /groups/:id/issues?state=opened
```

지원되는 속성:

| 속성           | 유형             | 필수   | 설명                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 정수 또는 문자열   | 예        | 그룹의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.                 |
| `assignee_id`       | 정수          | 아니요         | 지정된 사용자 `id`에 할당된 이슈를 반환합니다. `assignee_username`과(와) 상호 배타적입니다. `None`은(는) 할당되지 않은 이슈를 반환합니다. `Any`은(는) 담당자가 있는 이슈를 반환합니다. |
| `assignee_username` | 문자열 배열     | 아니요         | 지정된 `username`에 할당된 이슈를 반환합니다. `assignee_id`과(와) 유사하며 `assignee_id`과(와) 상호 배타적입니다. GitLab CE에서 `assignee_username` 배열은 단일 값만 포함해야 합니다. 그렇지 않으면 잘못된 매개변수 오류가 반환됩니다. 모든 전달된 사용자에 할당된 이슈만 반환됩니다. |
| `author_id`         | 정수          | 아니요         | 지정된 사용자 `id`이(가) 만든 이슈를 반환합니다. `author_username`과(와) 상호 배타적입니다. `scope=all` 또는 `scope=assigned_to_me`과(와) 결합합니다. |
| `author_username`   | 문자열           | 아니요         | 지정된 `username`이(가) 만든 이슈를 반환합니다. `author_id`과(와) 유사하며 `author_id`과(와) 상호 배타적입니다. |
| `confidential`     | 부울          | 아니요         | 기밀 또는 공개 이슈를 필터링합니다.                                                                                         |
| `created_after`     | 날짜/시간         | 아니요         | 지정된 시간 이후에 생성된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`). |
| `created_before`    | 날짜/시간         | 아니요         | 지정된 시간 이전 또는 그 시간에 생성된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`). |
| `due_date`          | 문자열           | 아니요         | 기한이 없거나 기한이 지났거나, 기한이 이번 주, 이번 달, 또는 2주 전에서 다음 달 사이인 이슈를 반환합니다. 허용: `0`(기한 없음), `any`, `today`, `tomorrow`, `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`. |
| `epic_id`           | 정수      | 아니요         | 지정된 에픽 ID와 연결된 이슈를 반환합니다. `None`은(는) 에픽과 연결되지 않은 이슈를 반환합니다. `Any`은(는) 에픽과 연결된 이슈를 반환합니다. Premium 및 Ultimate 전용입니다. |
| `iids[]`            | 정수 배열    | 아니요         | 지정된 `iid`을(를) 가진 이슈만 반환합니다.                                                                                 |
| `issue_type`        | 문자열           | 아니요         | 특정 이슈 유형으로 필터링합니다. `issue`, `incident`, `test_case` 또는 `task` 중 하나입니다. |
| `iteration_id`      | 정수 | 아니요         | 지정된 반복에 할당된 이슈를 반환합니다. `None`은(는) 반복에 속하지 않은 이슈를 반환합니다. `Any`은(는) 반복에 속한 이슈를 반환합니다. `iteration_title`과(와) 상호 배타적입니다. Premium 및 Ultimate 전용입니다. |
| `iteration_title`   | 문자열 | 아니요       | 지정된 제목의 반복에 할당된 이슈를 반환합니다. `iteration_id`과(와) 유사하며 `iteration_id`과(와) 상호 배타적입니다. Premium 및 Ultimate 전용입니다.|
| `labels`            | 문자열           | 아니요         | 쉼표로 구분된 레이블 이름 목록이며, 이슈는 반환되기 위해 모든 레이블을 가져야 합니다. `None`은(는) 레이블이 없는 모든 이슈를 나열합니다. `Any`은(는) 최소 1개의 레이블을 가진 모든 이슈를 나열합니다. `No+Label`(더 이상 사용 안 함)은(는) 레이블이 없는 모든 이슈를 나열합니다. 미리 정의된 이름은 대소문자를 구분하지 않습니다. |
| `milestone`         | 문자열           | 아니요         | 마일스톤 제목입니다. `None`은(는) 마일스톤이 없는 모든 이슈를 나열합니다. `Any`은(는) 할당된 마일스톤이 있는 모든 이슈를 나열합니다.       |
| `my_reaction_emoji` | 문자열           | 아니요         | 인증된 사용자가 지정된 `emoji`에 반응한 이슈를 반환합니다. `None`은(는) 반응이 없는 이슈를 반환합니다. `Any`은(는) 최소 1개의 반응이 있는 이슈를 반환합니다. |
| `non_archived`      | 부울          | 아니요         | 보관되지 않은 프로젝트의 이슈를 반환합니다. 기본값은 true입니다. |
| `not`               | 해시             | 아니요         | 제공된 매개변수와 일치하지 않는 이슈를 반환합니다. 허용: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in`. |
| `order_by`          | 문자열           | 아니요         | `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` 필드로 정렬된 이슈를 반환합니다. 기본값은 `created_at`                                                               |
| `scope`             | 문자열           | 아니요         | 지정된 범위에 대한 이슈를 반환합니다: `created_by_me`, `assigned_to_me` 또는 `all`. `all`을(를) 기본값으로 합니다. |
| `search`            | 문자열           | 아니요         | 그룹 이슈를 `title` 및 `description`에 대해 검색합니다.                                                                   |
| `sort`              | 문자열           | 아니요         | `asc` 또는 `desc` 순서로 정렬된 이슈를 반환합니다. 기본값은 `desc`입니다.                                                              |
| `state`             | 문자열           | 아니요         | 모든 이슈 또는 `opened` 또는 `closed`인 이슈만 반환합니다.                                                                 |
| `updated_after`     | 날짜/시간         | 아니요         | 지정된 시간 이후에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`). |
| `updated_before`    | 날짜/시간         | 아니요         | 지정된 시간 이전 또는 그 시간에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`). |
| `weight` | 정수       | 아니요         | 지정된 `weight`을(를) 가진 이슈를 반환합니다. `None`은(는) 가중치가 지정되지 않은 이슈를 반환합니다. `Any`은(는) 가중치가 지정된 이슈를 반환합니다. Premium 및 Ultimate 전용입니다. |
| `with_labels_details` | 부울        | 아니요         | `true`인 경우 응답은 labels 필드의 각 레이블에 대한 자세한 정보를 반환합니다: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. 기본값은 `false`입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/issues"
```

예제 응답:

```json
[
   {
      "project_id" : 4,
      "milestone" : {
         "due_date" : null,
         "project_id" : 4,
         "state" : "closed",
         "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
         "iid" : 3,
         "id" : 11,
         "title" : "v3.0",
         "created_at" : "2016-01-04T15:31:39.788Z",
         "updated_at" : "2016-01-04T15:31:39.788Z"
      },
      "author" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "state" : "closed",
      "iid" : 1,
      "assignees" : [{
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      }],
      "assignee" : {
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      },
      "type" : "ISSUE",
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "id" : 41,
      "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
      "updated_at" : "2016-01-04T15:31:46.176Z",
      "created_at" : "2016-01-04T15:31:46.176Z",
      "closed_at" : null,
      "closed_by" : null,
      "user_notes_count": 1,
      "due_date": null,
      "imported": false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
      "references": {
        "short": "#1",
        "relative": "my-project#1",
        "full": "my-group/my-project#1"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/4/issues/41",
         "notes":"http://gitlab.example.com/api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/4",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `weight` 속성이 포함됩니다:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "weight": null,
      ...
   }
]
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `epic` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimate 사용자가 만든 이슈에는 `health_status` 속성이 포함됩니다:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "at_risk",
      ...
   }
]
```

> [!warning]
> `assignee` 열은 더 이상 사용되지 않습니다. 이를 GitLab EE API에 맞추기 위해 단일 크기의 배열 `assignees`로 표시합니다.
>
> `epic_iid` 속성은 더 이상 사용되지 않으며 API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)입니다. `iid` of the `epic` 속성을 대신 사용합니다.

## 모든 프로젝트 이슈 나열 {#list-all-project-issues}

{{< history >}}

- GitLab 18.3에서 도입된 키셋 페이지 나누기 지원.

{{< /history >}}

지정된 프로젝트의 모든 이슈를 나열합니다.

프로젝트가 비공개인 경우 권한을 부여하기 위해 자격 증명을 제공해야 합니다. 이 작업을 수행하는 선호되는 방법은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을(를) 사용하는 것입니다.

```plaintext
GET /projects/:id/issues
GET /projects/:id/issues?assignee_id=5
GET /projects/:id/issues?author_id=5
GET /projects/:id/issues?confidential=true
GET /projects/:id/issues?iids[]=42&iids[]=43
GET /projects/:id/issues?labels=foo
GET /projects/:id/issues?labels=foo,bar
GET /projects/:id/issues?labels=foo,bar&state=opened
GET /projects/:id/issues?milestone=1.0.0
GET /projects/:id/issues?milestone=1.0.0&state=opened
GET /projects/:id/issues?my_reaction_emoji=star
GET /projects/:id/issues?search=issue+title+or+description
GET /projects/:id/issues?state=closed
GET /projects/:id/issues?state=opened
```

지원되는 속성:

| 속성             | 유형           | 필수 | 설명 |
| --------------------- | -------------- | -------- | ----------- |
| `id`                  | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `assignee_id`         | 정수        | 아니요       | 지정된 사용자 `id`에 할당된 이슈를 반환합니다. `assignee_username`과(와) 상호 배타적입니다. `None`은(는) 할당되지 않은 이슈를 반환합니다. `Any`은(는) 담당자가 있는 이슈를 반환합니다. |
| `assignee_username`   | 문자열 배열   | 아니요       | 지정된 `username`에 할당된 이슈를 반환합니다. `assignee_id`과(와) 유사하며 `assignee_id`과(와) 상호 배타적입니다. GitLab CE에서 `assignee_username` 배열은 단일 값만 포함해야 합니다. 그렇지 않으면 잘못된 매개변수 오류가 반환됩니다. 모든 전달된 사용자에 할당된 이슈만 반환됩니다. |
| `author_id`           | 정수        | 아니요       | 지정된 사용자 `id`이(가) 만든 이슈를 반환합니다. `author_username`과(와) 상호 배타적입니다. `scope=all` 또는 `scope=assigned_to_me`과(와) 결합합니다. |
| `author_username`     | 문자열         | 아니요       | 지정된 `username`이(가) 만든 이슈를 반환합니다. `author_id`과(와) 유사하며 `author_id`과(와) 상호 배타적입니다. |
| `confidential`        | 부울        | 아니요       | 기밀 또는 공개 이슈를 필터링합니다. |
| `created_after`       | 날짜/시간       | 아니요       | 지정된 시간 이후에 생성된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`). |
| `created_before`      | 날짜/시간       | 아니요       | 지정된 시간 이전 또는 그 시간에 생성된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`). |
| `due_date`            | 문자열         | 아니요       | 기한이 없거나 기한이 지났거나, 기한이 이번 주, 이번 달, 또는 2주 전에서 다음 달 사이인 이슈를 반환합니다. 허용: `0`(기한 없음), `any`, `today`, `tomorrow`, `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`. |
| `epic_id`             | 정수        | 아니요       | 지정된 에픽 ID와 연결된 이슈를 반환합니다. `None`은(는) 에픽과 연결되지 않은 이슈를 반환합니다. `Any`은(는) 에픽과 연결된 이슈를 반환합니다. Premium 및 Ultimate 전용입니다. |
| `iids[]`              | 정수 배열  | 아니요       | 지정된 `iid`을(를) 가진 이슈만 반환합니다. |
| `issue_type`          | 문자열         | 아니요       | 특정 이슈 유형으로 필터링합니다. `issue`, `incident`, `test_case` 또는 `task` 중 하나입니다. |
| `iteration_id`        | 정수        | 아니요       | 지정된 반복에 할당된 이슈를 반환합니다. `None`은(는) 반복에 속하지 않은 이슈를 반환합니다. `Any`은(는) 반복에 속한 이슈를 반환합니다. `iteration_title`과(와) 상호 배타적입니다. Premium 및 Ultimate 전용입니다. |
| `iteration_title`     | 문자열         | 아니요       | 지정된 제목의 반복에 할당된 이슈를 반환합니다. `iteration_id`과(와) 유사하며 `iteration_id`과(와) 상호 배타적입니다. Premium 및 Ultimate 전용입니다. |
| `labels`              | 문자열         | 아니요       | 쉼표로 구분된 레이블 이름 목록이며, 이슈는 반환되기 위해 모든 레이블을 가져야 합니다. `None`은(는) 레이블이 없는 모든 이슈를 나열합니다. `Any`은(는) 최소 1개의 레이블을 가진 모든 이슈를 나열합니다. `No+Label`(더 이상 사용 안 함)은(는) 레이블이 없는 모든 이슈를 나열합니다. 미리 정의된 이름은 대소문자를 구분하지 않습니다. |
| `milestone`           | 문자열         | 아니요       | 마일스톤 제목입니다. `None`은(는) 마일스톤이 없는 모든 이슈를 나열합니다. `Any`은(는) 할당된 마일스톤이 있는 모든 이슈를 나열합니다. |
| `my_reaction_emoji`   | 문자열         | 아니요       | 인증된 사용자가 지정된 `emoji`에 반응한 이슈를 반환합니다. `None`은(는) 반응이 없는 이슈를 반환합니다. `Any`은(는) 최소 1개의 반응이 있는 이슈를 반환합니다. |
| `not`                 | 해시           | 아니요       | 제공된 매개변수와 일치하지 않는 이슈를 반환합니다. 허용: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in`. |
| `order_by`            | 문자열         | 아니요       | `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight` 필드로 정렬된 이슈를 반환합니다. 기본값은 `created_at`입니다. |
| `scope`               | 문자열         | 아니요       | 지정된 범위에 대한 이슈를 반환합니다: `created_by_me`, `assigned_to_me` 또는 `all`. `all`을(를) 기본값으로 합니다. |
| `search`              | 문자열         | 아니요       | 프로젝트 이슈를 `title` 및 `description`에 대해 검색합니다. |
| `sort`                | 문자열         | 아니요       | `asc` 또는 `desc` 순서로 정렬된 이슈를 반환합니다. 기본값은 `desc`입니다. |
| `state`               | 문자열         | 아니요       | 모든 이슈 또는 `opened` 또는 `closed`인 이슈만 반환합니다. |
| `updated_after`       | 날짜/시간       | 아니요       | 지정된 시간 이후에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`). |
| `updated_before`      | 날짜/시간       | 아니요       | 지정된 시간 이전 또는 그 시간에 업데이트된 이슈를 반환합니다. ISO 8601 형식으로 예상됨(`2019-03-15T08:00:00Z`). |
| `weight`              | 정수        | 아니요       | 지정된 `weight`을(를) 가진 이슈를 반환합니다. `None`은(는) 가중치가 지정되지 않은 이슈를 반환합니다. `Any`은(는) 가중치가 지정된 이슈를 반환합니다. Premium 및 Ultimate 전용입니다. |
| `with_labels_details` | 부울        | 아니요       | `true`인 경우 응답은 labels 필드의 각 레이블에 대한 자세한 정보를 반환합니다: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. 기본값은 `false`입니다. |
| `cursor`              | 문자열         | 아니요       | 키셋 페이지 나누기에서 사용되는 매개변수입니다. |

이 엔드포인트는 오프셋 기반 및 [키셋 기반](rest/_index.md#keyset-based-pagination) 페이지 나누기를 모두 지원합니다. 연속적인 결과 페이지를 요청할 때는 키셋 기반 페이지 나누기를 사용해야 합니다.

[페이지 나누기](rest/_index.md#pagination)에 대해 자세히 읽어보세요.

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues"
```

예제 응답:

```json
[
   {
      "project_id" : 4,
      "milestone" : {
         "due_date" : null,
         "project_id" : 4,
         "state" : "closed",
         "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
         "iid" : 3,
         "id" : 11,
         "title" : "v3.0",
         "created_at" : "2016-01-04T15:31:39.788Z",
         "updated_at" : "2016-01-04T15:31:39.788Z"
      },
      "author" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "state" : "closed",
      "iid" : 1,
      "assignees" : [{
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      }],
      "assignee" : {
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      },
      "type" : "ISSUE",
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "id" : 41,
      "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
      "updated_at" : "2016-01-04T15:31:46.176Z",
      "created_at" : "2016-01-04T15:31:46.176Z",
      "closed_at" : "2016-01-05T15:31:46.176Z",
      "closed_by" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "user_notes_count": 1,
      "due_date": "2016-07-22",
      "imported": false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
      "references": {
        "short": "#1",
        "relative": "#1",
        "full": "my-group/my-project#1"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/4/issues/41",
         "notes":"http://gitlab.example.com/api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/4",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `weight` 속성이 포함됩니다:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "weight": null,
      ...
   }
]
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `epic` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimate 사용자가 만든 이슈에는 `health_status` 속성이 포함됩니다:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "at_risk",
      ...
   }
]
```

> [!warning]
> `assignee` 열은 더 이상 사용되지 않습니다. 이를 GitLab EE API에 맞추기 위해 단일 크기의 배열 `assignees`로 표시합니다.
>
> `epic_iid` 속성은 더 이상 사용되지 않으며 API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)입니다. `iid` of the `epic` 속성을 대신 사용합니다.

## 이슈 검색 {#retrieve-an-issue}

관리자 전용입니다.

지정된 이슈를 검색합니다.

이 작업을 수행하는 선호되는 방법은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을(를) 사용하는 것입니다.

```plaintext
GET /issues/:id
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 | 예      | 이슈의 ID입니다.                 |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues/41"
```

예제 응답:

```json
{
  "id": 1,
  "milestone": {
    "due_date": null,
    "project_id": 4,
    "state": "closed",
    "description": "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
    "iid": 3,
    "id": 11,
    "title": "v3.0",
    "created_at": "2016-01-04T15:31:39.788Z",
    "updated_at": "2016-01-04T15:31:39.788Z",
    "closed_at": "2016-01-05T15:31:46.176Z"
  },
  "author": {
    "state": "active",
    "web_url": "https://gitlab.example.com/root",
    "avatar_url": null,
    "username": "root",
    "id": 1,
    "name": "Administrator"
  },
  "description": "Omnis vero earum sunt corporis dolor et placeat.",
  "state": "closed",
  "iid": 1,
  "assignees": [
    {
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/lennie",
      "state": "active",
      "username": "lennie",
      "id": 9,
      "name": "Dr. Luella Kovacek"
    }
  ],
  "assignee": {
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/lennie",
    "state": "active",
    "username": "lennie",
    "id": 9,
    "name": "Dr. Luella Kovacek"
  },
  "type": "ISSUE",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "title": "Ut commodi ullam eos dolores perferendis nihil sunt.",
  "updated_at": "2016-01-04T15:31:46.176Z",
  "created_at": "2016-01-04T15:31:46.176Z",
  "closed_at": null,
  "closed_by": null,
  "subscribed": false,
  "user_notes_count": 1,
  "due_date": null,
  "imported": false,
  "imported_from": "none",
  "web_url": "http://example.com/my-group/my-project/issues/1",
  "references": {
    "short": "#1",
    "relative": "#1",
    "full": "my-group/my-project#1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "task_completion_status": {
    "count": 0,
    "completed_count": 0
  },
  "weight": null,
  "has_tasks": false,
  "_links": {
    "self": "http://gitlab.example:3000/api/v4/projects/1/issues/1",
    "notes": "http://gitlab.example:3000/api/v4/projects/1/issues/1/notes",
    "award_emoji": "http://gitlab.example:3000/api/v4/projects/1/issues/1/award_emoji",
    "project": "http://gitlab.example:3000/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "moved_to_id": null,
  "service_desk_reply_to": "service.desk@gitlab.com"
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `weight` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `epic` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic": {
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

[GitLab Ultimate](https://about.gitlab.com/pricing/) 사용자도 `health_status` 속성을 볼 수 있습니다:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> `assignee` 열은 더 이상 사용되지 않습니다. 이를 GitLab EE API에 맞추기 위해 단일 크기의 배열 `assignees`로 표시합니다.
>
> `epic_iid` 속성은 더 이상 사용되지 않으며 API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)입니다. `iid` of the `epic` 속성을 대신 사용합니다.

## 프로젝트 이슈 검색 {#retrieve-a-project-issue}

프로젝트의 지정된 이슈를 검색합니다.

프로젝트가 비공개이거나 이슈가 기밀인 경우 권한을 부여하기 위해 자격 증명을 제공해야 합니다. 이 작업을 수행하는 선호되는 방법은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을(를) 사용하는 것입니다.

```plaintext
GET /projects/:id/issues/:issue_iid
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/41"
```

예제 응답:

```json
{
   "project_id" : 4,
   "milestone" : {
      "due_date" : null,
      "project_id" : 4,
      "state" : "closed",
      "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
      "iid" : 3,
      "id" : 11,
      "title" : "v3.0",
      "created_at" : "2016-01-04T15:31:39.788Z",
      "updated_at" : "2016-01-04T15:31:39.788Z",
      "closed_at" : "2016-01-05T15:31:46.176Z"
   },
   "author" : {
      "state" : "active",
      "web_url" : "https://gitlab.example.com/root",
      "avatar_url" : null,
      "username" : "root",
      "id" : 1,
      "name" : "Administrator"
   },
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "state" : "closed",
   "iid" : 1,
   "assignees" : [{
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/lennie",
      "state" : "active",
      "username" : "lennie",
      "id" : 9,
      "name" : "Dr. Luella Kovacek"
   }],
   "assignee" : {
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/lennie",
      "state" : "active",
      "username" : "lennie",
      "id" : 9,
      "name" : "Dr. Luella Kovacek"
   },
   "type" : "ISSUE",
   "labels" : [],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "id" : 41,
   "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
   "updated_at" : "2016-01-04T15:31:46.176Z",
   "created_at" : "2016-01-04T15:31:46.176Z",
   "closed_at" : null,
   "closed_by" : null,
   "subscribed": false,
   "user_notes_count": 1,
   "due_date": null,
   "imported": false,
   "imported_from": "none",
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
   "references": {
     "short": "#1",
     "relative": "#1",
     "full": "my-group/my-project#1"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `weight` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `epic` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

[GitLab Ultimate](https://about.gitlab.com/pricing/) 사용자도 `health_status` 속성을 볼 수 있습니다:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> `assignee` 열은 더 이상 사용되지 않습니다. 이를 GitLab EE API에 맞추기 위해 단일 크기의 배열 `assignees`로 표시합니다.
>
> `epic_iid` 속성은 더 이상 사용되지 않으며 API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)입니다. `iid` of the `epic` 속성을 대신 사용합니다.

## 이슈 생성 {#create-an-issue}

지정된 프로젝트에 대한 이슈를 생성합니다.

```plaintext
POST /projects/:id/issues
```

지원되는 속성:

| 속성                                 | 유형           | 필수 | 설명  |
|-------------------------------------------|----------------|----------|--------------|
| `id`                                      | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `assignee_id`                             | 정수        | 아니요       | 이슈를 할당할 사용자의 ID입니다. GitLab Free에서만 나타납니다. |
| `assignee_ids`                            | 정수 배열  | 아니요       | 이슈를 할당할 사용자의 ID입니다. Premium 및 Ultimate 전용입니다.|
| `confidential`                            | 부울        | 아니요       | 이슈를 기밀로 설정합니다. 기본값은 `false`입니다.  |
| `created_at`                              | 문자열         | 아니요       | 이슈가 생성된 시간입니다. 날짜 시간 문자열, ISO 8601 형식(예: `2016-03-11T03:45:40Z`). 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |
| `description`                             | 문자열         | 아니요       | 이슈의 설명입니다. 1,048,576자로 제한됩니다. |
| `discussion_to_resolve`                   | 문자열         | 아니요       | 해결할 토론의 ID입니다. 이것은 이슈를 기본 설명으로 채우고 토론을 해결됨으로 표시합니다. `merge_request_to_resolve_discussions_of`과(와) 결합하여 사용합니다. |
| `due_date`                                | 문자열         | 아니요       | 기한 날짜입니다. `YYYY-MM-DD` 형식의 날짜 시간 문자열(예: `2016-03-11`). |
| `epic_id`                                 | 정수 | 아니요 | 이슈를 추가할 에픽의 ID입니다. 유효한 값은 0 이상입니다. Premium 및 Ultimate 전용입니다. |
| `epic_iid`                                | 정수 | 아니요 | 이슈를 추가할 에픽의 IID입니다. 유효한 값은 0 이상입니다. (더 이상 사용 안 함, API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)). Premium 및 Ultimate 전용입니다. |
| `iid`                                     | 정수 또는 문자열 | 아니요       | 프로젝트의 이슈의 내부 ID입니다(관리자 또는 프로젝트 소유자 권한 필요). |
| `issue_type`                              | 문자열         | 아니요       | 이슈의 유형입니다. `issue`, `incident`, `test_case` 또는 `task` 중 하나입니다. 기본값은 `issue`입니다. |
| `labels`                                  | 문자열         | 아니요       | 새 이슈에 할당할 쉼표로 구분된 레이블 이름 목록입니다. 레이블이 아직 존재하지 않으면 새 프로젝트 레이블을 만들고 이슈에 할당합니다.  |
| `merge_request_to_resolve_discussions_of` | 정수        | 아니요       | 모든 이슈를 해결할 머지 리퀘스트의 IID입니다. 이것은 이슈를 기본 설명으로 채우고 모든 토론을 해결됨으로 표시합니다. 설명 또는 제목을 전달할 때 이 값들이 기본값보다 우선합니다.|
| `milestone_id`                            | 정수        | 아니요       | 이슈를 할당할 마일스톤의 전역 ID입니다. 마일스톤과 연결된 `milestone_id`을(를) 찾으려면 마일스톤이 할당된 이슈를 보고 [API를 사용](#retrieve-a-project-issue)하여 이슈의 세부 정보를 검색합니다. `milestone`과(와) 상호 배타적입니다. |
| `milestone`                               | 문자열         | 아니요       | 이슈를 할당할 프로젝트 또는 상위 그룹 마일스톤의 제목입니다. 정확히 일치합니다(대소문자 구분). `milestone_id`과(와) 상호 배타적입니다. |
| `title`                                   | 문자열         | 예      | 이슈의 제목입니다. |
| `weight`                                  | 정수        | 아니요       | 이슈의 가중치입니다. 유효한 값은 0 이상입니다. Premium 및 Ultimate 전용입니다. |

예제 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues?title=Issues%20with%20auth&labels=bug"
```

예제 응답:

```json
{
   "project_id" : 4,
   "id" : 84,
   "created_at" : "2016-01-07T12:44:33.959Z",
   "iid" : 14,
   "title" : "Issues with auth",
   "state" : "opened",
   "assignees" : [],
   "assignee" : null,
   "type" : "ISSUE",
   "labels" : [
      "bug"
   ],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
   },
   "description" : null,
   "updated_at" : "2016-01-07T12:44:33.959Z",
   "closed_at" : null,
   "closed_by" : null,
   "milestone" : null,
   "subscribed" : true,
   "user_notes_count": 0,
   "due_date": null,
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/14",
   "references": {
     "short": "#14",
     "relative": "#14",
     "full": "my-group/my-project#14"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

대상 프로젝트에 **이슈**가 [꺼져](../user/project/settings/_index.md#toggle-project-features) 있으면 `403` 응답을 받으며 다음과 같은 메시지가 표시됩니다:

```json
{
   "message": "403 Forbidden"
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `weight` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `epic` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimate 사용자가 만든 이슈에는 `health_status` 속성이 포함됩니다:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> `assignee` 열은 더 이상 사용되지 않습니다. 이를 GitLab EE API에 맞추기 위해 단일 크기의 배열 `assignees`로 표시합니다.
>
> `epic_iid` 속성은 더 이상 사용되지 않으며 API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)입니다. `iid` of the `epic` 속성을 대신 사용합니다.

### 속도 제한 {#rate-limits}

학대를 피하기 위해 사용자는 분당 특정 수의 `Create` 요청으로 제한될 수 있습니다. 자세한 내용은 [이슈 및 에픽 생성에 대한 속도 제한](../administration/settings/rate_limit_on_issues_creation.md)을(를) 참조하세요.

## 이슈 업데이트 {#update-an-issue}

프로젝트의 지정된 이슈를 업데이트합니다. 이 요청은 `state_event` 매개변수를 사용하여 이슈를 닫거나 다시 열 때도 사용됩니다

요청이 성공하려면 다음 매개변수 중 최소 하나가 필요합니다:

- `:assignee_id`
- `:assignee_ids`
- `:confidential`
- `:created_at`
- `:description`
- `:discussion_locked`
- `:due_date`
- `:issue_type`
- `:labels`
- `:milestone_id`
- `:state_event`
- `:title`

```plaintext
PUT /projects/:id/issues/:issue_iid
```

지원되는 속성:

| 속성      | 유형    | 필수 | 설명                                                                                                |
|----------------|---------|----------|------------------------------------------------------------------------------------------------------------|
| `id`           | 정수 또는 문자열 | 예 | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `issue_iid`    | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다.                                                                       |
| `add_labels`   | 문자열  | 아니요       | 이슈에 추가할 쉼표로 구분된 레이블 이름 목록입니다. 레이블이 아직 존재하지 않으면 새 프로젝트 레이블을 만들고 이슈에 할당합니다. |
| `assignee_ids` | 정수 배열 | 아니요 | 이슈를 할당할 사용자의 ID입니다. `0`로 설정하거나 모든 담당자를 할당 해제하려면 빈 값을 제공합니다. |
| `confidential` | 부울 | 아니요       | 이슈를 기밀로 업데이트합니다.                                                                        |
| `description`  | 문자열  | 아니요       | 이슈의 설명입니다. 1,048,576자로 제한됩니다.        |
| `discussion_locked` | 부울 | 아니요  | 이슈의 토론이 잠겨 있는지 여부를 나타내는 플래그입니다. 토론이 잠겨 있으면 프로젝트 멤버만 의견을 추가하거나 수정할 수 있습니다. |
| `due_date`     | 문자열  | 아니요       | 기한 날짜입니다. `YYYY-MM-DD` 형식의 날짜 시간 문자열(예: `2016-03-11`).                                           |
| `epic_id`      | 정수 | 아니요 | 이슈를 추가할 에픽의 ID입니다. 유효한 값은 0 이상입니다. Premium 및 Ultimate 전용입니다. |
| `epic_iid`     | 정수 | 아니요 | 이슈를 추가할 에픽의 IID입니다. 유효한 값은 0 이상입니다. (더 이상 사용 안 함, API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)). Premium 및 Ultimate 전용입니다. |
| `issue_type`   | 문자열  | 아니요       | 이슈의 유형을 업데이트합니다. `issue`, `incident`, 또는 `test_case` 중 하나입니다. |
| `labels`       | 문자열  | 아니요       | 이슈에 대한 쉼표로 구분된 레이블 이름 목록입니다. 모든 레이블을 할당 해제하려면 빈 문자열로 설정합니다. 레이블이 아직 존재하지 않으면 새 프로젝트 레이블을 만들고 이슈에 할당합니다. |
| `milestone_id` | 정수 | 아니요       | 이슈를 할당할 마일스톤의 전역 ID입니다. `0`로 설정하거나 마일스톤을 할당 해제하려면 빈 값을 제공합니다. `milestone`과(와) 상호 배타적입니다.|
| `milestone`    | 문자열  | 아니요       | 이슈를 할당할 프로젝트 또는 상위 그룹 마일스톤의 제목입니다. 정확히 일치합니다(대소문자 구분). `milestone_id`과(와) 상호 배타적입니다. |
| `remove_labels`| 문자열  | 아니요       | 이슈에서 제거할 쉼표로 구분된 레이블 이름 목록입니다.                                                       |
| `state_event`  | 문자열  | 아니요       | 이슈의 상태 이벤트입니다. 이슈를 닫으려면 `close`을(를) 사용하고, 다시 열려면 `reopen`을(를) 사용합니다.                      |
| `title`        | 문자열  | 아니요       | 이슈의 제목입니다.                                                                                      |
| `updated_at`   | 문자열  | 아니요       | 이슈가 업데이트된 시간입니다. 날짜 시간 문자열, ISO 8601 형식(예: `2016-03-11T03:45:40Z`)(관리자 또는 프로젝트 소유자 권한 필요). 빈 문자열 또는 null 값은 허용되지 않습니다.|
| `weight`       | 정수 | 아니요       | 이슈의 가중치입니다. 유효한 값은 0 이상입니다. Premium 및 Ultimate 전용입니다.           |

예제 요청:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85?state_event=close"
```

예제 응답:

```json
{
   "created_at" : "2016-01-07T12:46:01.410Z",
   "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "username" : "eileen.lowe",
      "id" : 18,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe"
   },
   "state" : "closed",
   "title" : "Issues with auth",
   "project_id" : 4,
   "description" : null,
   "updated_at" : "2016-01-07T12:55:16.213Z",
   "closed_at" : "2016-01-08T12:55:16.213Z",
   "closed_by" : {
      "state" : "active",
      "web_url" : "https://gitlab.example.com/root",
      "avatar_url" : null,
      "username" : "root",
      "id" : 1,
      "name" : "Administrator"
    },
   "iid" : 15,
   "labels" : [
      "bug"
   ],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "id" : 85,
   "assignees" : [],
   "assignee" : null,
   "milestone" : null,
   "subscribed" : true,
   "user_notes_count": 0,
   "due_date": "2016-07-22",
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/15",
   "references": {
     "short": "#15",
     "relative": "#15",
     "full": "my-group/my-project#15"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"

   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `weight` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `epic` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimate 사용자가 만든 이슈에는 `health_status` 속성이 포함됩니다:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> 더 이상 사용되지 않음:
>
> - `epic_iid` 속성은 더 이상 사용되지 않으며 API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)입니다. `iid` of the `epic` 속성을 대신 사용합니다.
> - `assignee` 열은 더 이상 사용되지 않습니다. 이를 GitLab EE API에 맞추기 위해 단일 크기의 배열 `assignees`로 표시합니다.

## 이슈 삭제 {#delete-an-issue}

{{< history >}}

- 사용자는 GitLab 18.10에서 [도입된](https://gitlab.com/gitlab-org/gitlab/-/issues/371104) 자신이 만든 이슈를 삭제할 수 있습니다.

{{< /history >}}

플래너 또는 소유자 역할을 가진 사용자는 모든 이슈를 삭제할 수 있습니다. 다른 프로젝트 멤버는 자신이 만든 이슈를 삭제할 수 있습니다.

프로젝트에서 지정된 이슈를 삭제합니다.

```plaintext
DELETE /projects/:id/issues/:issue_iid
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85"
```

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

## 이슈 순서 변경 {#reorder-an-issue}

프로젝트 내에서 지정된 이슈를 순서 변경합니다. [이슈를 수동으로 정렬](../user/project/issues/sorting_issue_lists.md#manual-sorting)할 때 결과를 볼 수 있습니다.

```plaintext
PUT /projects/:id/issues/:issue_iid/reorder
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |
| `move_after_id` | 정수 | 아니요 | 이 이슈 뒤에 배치해야 할 프로젝트의 이슈의 전역 ID입니다. |
| `move_before_id` | 정수 | 아니요 | 이 이슈 앞에 배치해야 할 프로젝트의 이슈의 전역 ID입니다. |

예제 요청:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85/reorder?move_after_id=51&move_before_id=92"
```

## 이슈 이동 {#move-an-issue}

지정된 이슈를 다른 프로젝트로 이동합니다. 대상 프로젝트가 소스 프로젝트이거나 사용자의 권한이 부족한 경우 `400` 상태 코드의 오류 메시지가 반환됩니다.

대상 프로젝트에도 동일한 이름의 레이블 또는 마일스톤이 있으면 이동되는 이슈에 할당됩니다.

```plaintext
POST /projects/:id/issues/:issue_iid/move
```

지원되는 속성:

| 속성       | 유형    | 필수 | 설명                          |
|-----------------|---------|----------|--------------------------------------|
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid`     | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |
| `to_project_id` | 정수 | 예      | 새 프로젝트의 ID입니다.            |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --form to_project_id=5 \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85/move"
```

예제 응답:

```json
{
  "id": 92,
  "iid": 11,
  "project_id": 5,
  "title": "Sit voluptas tempora quisquam aut doloribus et.",
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.652Z",
  "updated_at": "2016-04-07T12:20:17.596Z",
  "closed_at": null,
  "closed_by": null,
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "assignee": {
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  },
  "type" : "ISSUE",
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/solon.cremin"
  },
  "due_date": null,
  "imported": false,
  "imported_from": "none",
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/11",
  "references": {
    "short": "#11",
    "relative": "#11",
    "full": "my-group/my-project#11"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "_links": {
    "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
    "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://gitlab.example.com/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `weight` 속성이 포함됩니다:

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `epic` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimate 사용자가 만든 이슈에는 `health_status` 속성이 포함됩니다:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> `assignee` 열은 더 이상 사용되지 않습니다. 이를 GitLab EE API에 맞추기 위해 단일 크기의 배열 `assignees`로 표시합니다.
>
> `epic_iid` 속성은 더 이상 사용되지 않으며 API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)입니다. `iid` of the `epic` 속성을 대신 사용합니다.

## 이슈 복제 {#clone-an-issue}

지정된 이슈를 주어진 프로젝트에 복제합니다. 대상 프로젝트에 레이블 또는 마일스톤과 같은 동등한 기준이 포함되어 있는 한 가능한 한 많은 데이터를 복사합니다.

권한이 부족한 경우 `400` 상태 코드의 오류 메시지가 반환됩니다.

```plaintext
POST /projects/:id/issues/:issue_iid/clone
```

지원되는 속성:

| 속성       | 유형           | 필수               | 설명                       |
| --------------- | -------------- | ---------------------- | --------------------------------- |
| `id`            | 정수 또는 문자열 | 예 | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `issue_iid`     | 정수        | 예 | 프로젝트 이슈의 내부 ID입니다. |
| `to_project_id` | 정수        | 예 | 새 프로젝트의 ID입니다.            |
| `with_notes`    | 부울        | 아니요 | [노트](notes.md)와 함께 이슈를 복제합니다. 기본값은 `false`입니다. |

예제 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/1/clone?with_notes=true&to_project_id=6"
```

예제 응답:

```json
{
  "id":290,
  "iid":1,
  "project_id":143,
  "title":"foo",
  "description":"closed",
  "state":"opened",
  "created_at":"2021-09-14T22:24:11.696Z",
  "updated_at":"2021-09-14T22:24:11.696Z",
  "closed_at":null,
  "closed_by":null,
  "labels":[

  ],
  "milestone":null,
  "assignees":[
    {
      "id":179,
      "name":"John Doe2",
      "username":"john",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/john"
    }
  ],
  "author":{
    "id":179,
    "name":"John Doe2",
    "username":"john",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
    "web_url":"https://gitlab.example.com/john"
  },
  "type":"ISSUE",
  "assignee":{
    "id":179,
    "name":"John Doe2",
    "username":"john",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
    "web_url":"https://gitlab.example.com/john"
  },
  "user_notes_count":1,
  "merge_requests_count":0,
  "upvotes":0,
  "downvotes":0,
  "due_date":null,
  "imported":false,
  "imported_from": "none",
  "confidential":false,
  "discussion_locked":null,
  "issue_type":"issue",
  "severity": "UNKNOWN",
  "web_url":"https://gitlab.example.com/namespace1/project2/-/issues/1",
  "time_stats":{
    "time_estimate":0,
    "total_time_spent":0,
    "human_time_estimate":null,
    "human_total_time_spent":null
  },
  "task_completion_status":{
    "count":0,
    "completed_count":0
  },
  "blocking_issues_count":0,
  "has_tasks":false,
  "_links":{
    "self":"https://gitlab.example.com/api/v4/projects/143/issues/1",
    "notes":"https://gitlab.example.com/api/v4/projects/143/issues/1/notes",
    "award_emoji":"https://gitlab.example.com/api/v4/projects/143/issues/1/award_emoji",
    "project":"https://gitlab.example.com/api/v4/projects/143",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "references":{
    "short":"#1",
    "relative":"#1",
    "full":"namespace1/project2#1"
  },
  "subscribed":true,
  "moved_to_id":null,
  "service_desk_reply_to":null
}
```

## 알림 {#notifications}

다음 요청들은 이슈에 대한 [이메일 알림](../user/profile/notifications.md)과 관련이 있습니다.

### 이슈 구독하기 {#subscribe-to-an-issue}

인증된 사용자를 지정된 이슈에 구독시켜 알림을 받습니다. 사용자가 이미 이슈를 구독 중이면 상태 코드 `304`이 반환됩니다.

```plaintext
POST /projects/:id/issues/:issue_iid/subscribe
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/subscribe"
```

예제 응답:

```json
{
  "id": 92,
  "iid": 11,
  "project_id": 5,
  "title": "Sit voluptas tempora quisquam aut doloribus et.",
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.652Z",
  "updated_at": "2016-04-07T12:20:17.596Z",
  "closed_at": null,
  "closed_by": null,
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "assignee": {
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  },
  "type" : "ISSUE",
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/solon.cremin"
  },
  "due_date": null,
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/11",
  "references": {
    "short": "#11",
    "relative": "#11",
    "full": "my-group/my-project#11"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "_links": {
    "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
    "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://gitlab.example.com/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `weight` 속성이 포함됩니다:

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

GitLab Premium 또는 Ultimate 사용자가 만든 이슈에는 `epic` 속성이 포함됩니다:

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

GitLab Ultimate 사용자가 만든 이슈에는 `health_status` 속성이 포함됩니다:

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> `assignee` 열은 더 이상 사용되지 않습니다. 이를 GitLab EE API에 맞추기 위해 단일 크기의 배열 `assignees`로 표시합니다.
>
> `epic_iid` 속성은 더 이상 사용되지 않으며 API 버전 5에서 [제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/35157)입니다. `iid` of the `epic` 속성을 대신 사용합니다.

### 이슈 구독 취소하기 {#unsubscribe-from-an-issue}

인증된 사용자를 지정된 이슈에서 구독 취소하여 알림 수신을 중지합니다. 사용자가 이슈를 구독하지 않으면 상태 코드 `304`이 반환됩니다.

```plaintext
POST /projects/:id/issues/:issue_iid/unsubscribe
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/unsubscribe"
```

예제 응답:

```json
{
  "id": 93,
  "iid": 12,
  "project_id": 5,
  "title": "Incidunt et rerum ea expedita iure quibusdam.",
  "description": "Et cumque architecto sed aut ipsam.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.217Z",
  "updated_at": "2016-04-07T13:02:37.905Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignee": {
    "name": "Edwardo Grady",
    "username": "keyon",
    "id": 21,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/3e6f06a86cf27fa8b56f3f74f7615987?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/keyon"
  },
  "type" : "ISSUE",
  "closed_at": null,
  "closed_by": null,
  "author": {
    "name": "Vivian Hermann",
    "username": "orville",
    "id": 11,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/5224fd70153710e92fb8bcf79ac29d67?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/orville"
  },
  "subscribed": false,
  "due_date": null,
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/12",
  "references": {
    "short": "#12",
    "relative": "#12",
    "full": "my-group/my-project#12"
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

## 이슈에 대한 할 일 항목 만들기 {#create-a-to-do-item-for-an-issue}

현재 사용자에 대해 지정된 이슈에 대한 할 일 항목을 만듭니다. 사용자에 대해 해당 이슈에 대한 할 일 항목이 이미 존재하면 상태 코드 `304`이 반환됩니다.

```plaintext
POST /projects/:id/issues/:issue_iid/todo
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/todo"
```

예제 응답:

```json
{
  "id": 112,
  "project": {
    "id": 5,
    "name": "GitLab CI/CD",
    "name_with_namespace": "GitLab Org / GitLab CI/CD",
    "path": "gitlab-ci",
    "path_with_namespace": "gitlab-org/gitlab-ci"
  },
  "author": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/root"
  },
  "action_name": "marked",
  "target_type": "Issue",
  "target": {
    "id": 93,
    "iid": 10,
    "project_id": 5,
    "title": "Vel voluptas atque dicta mollitia adipisci qui at.",
    "description": "Tempora laboriosam sint magni sed voluptas similique.",
    "state": "closed",
    "created_at": "2016-06-17T07:47:39.486Z",
    "updated_at": "2016-07-01T11:09:13.998Z",
    "labels": [],
    "milestone": {
      "id": 26,
      "iid": 1,
      "project_id": 5,
      "title": "v0.0",
      "description": "Accusantium nostrum rerum quae quia quis nesciunt suscipit id.",
      "state": "closed",
      "created_at": "2016-06-17T07:47:33.832Z",
      "updated_at": "2016-06-17T07:47:33.832Z",
      "due_date": null
    },
    "assignees": [{
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca"
    }],
    "assignee": {
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca"
    },
    "type" : "ISSUE",
    "author": {
      "name": "Maxie Medhurst",
      "username": "craig_rutherford",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/craig_rutherford"
    },
    "subscribed": true,
    "user_notes_count": 7,
    "upvotes": 0,
    "downvotes": 0,
    "merge_requests_count": 0,
    "due_date": null,
    "web_url": "http://gitlab.example.com/my-group/my-project/issues/10",
    "references": {
      "short": "#10",
      "relative": "#10",
      "full": "my-group/my-project#10"
    },
    "confidential": false,
    "discussion_locked": false,
    "issue_type": "issue",
    "severity": "UNKNOWN",
    "task_completion_status":{
       "count":0,
       "completed_count":0
    }
  },
  "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ci/issues/10",
  "body": "Vel voluptas atque dicta mollitia adipisci qui at.",
  "state": "pending",
  "created_at": "2016-07-01T11:09:13.992Z"
}
```

> [!warning]
> `assignee` 열은 더 이상 사용되지 않습니다. 이를 GitLab EE API에 맞추기 위해 단일 크기의 배열 `assignees`로 표시합니다.

## 이슈를 에픽으로 승격하기 {#promote-an-issue-to-an-epic}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

지정된 이슈를 [`/promote_to`](../user/project/quick_actions.md#promote_to) 빠른 작업이 포함된 댓글을 추가하여 에픽으로 승격합니다.

자세한 내용은 [이슈를 에픽으로 승격하기](../user/project/issues/managing_issues.md#promote-an-issue-to-an-epic)를 참조하세요.

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

지원되는 속성:

| 속성   | 유형           | 필수 | 설명 |
| :---------- | :------------- | :------- | :---------- |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `issue_iid` | 정수        | 예      | 프로젝트의 이슈의 내부 ID입니다. |
| `body`      | 문자열         | 예      | 노트의 콘텐츠입니다. 새 줄의 시작 부분에 `/promote`이 포함되어야 합니다. 노트에 `/promote`만 포함된 경우 이슈를 승격하지만 댓글을 추가하지 않습니다. 그렇지 않으면 다른 줄들이 댓글을 형성합니다.|

예제 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=Lets%20promote%20this%20to%20an%20epic%0A%0A%2Fpromote"
```

예제 응답:

```json
{
   "id":699,
   "type":null,
   "body":"Lets promote this to an epic",
   "attachment":null,
   "author": {
      "id":1,
      "name":"Alexandra Bashirian",
      "username":"eileen.lowe",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url":"https://gitlab.example.com/eileen.lowe"
   },
   "created_at":"2020-12-03T12:27:17.844Z",
   "updated_at":"2020-12-03T12:27:17.844Z",
   "system":false,
   "noteable_id":461,
   "noteable_type":"Issue",
   "resolvable":false,
   "confidential":false,
   "noteable_iid":33,
   "commands_changes": {
      "promote_to_epic":true
   }
}
```

## 시간 추적 {#time-tracking}

다음 요청들은 이슈에 대한 [시간 추적](../user/project/time_tracking.md)과 관련이 있습니다.

### 이슈에 대한 시간 예상 설정하기 {#set-a-time-estimate-for-an-issue}

지정된 이슈에 대한 예상 작업 시간을 설정합니다.

```plaintext
POST /projects/:id/issues/:issue_iid/time_estimate
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                              |
|-------------|---------|----------|------------------------------------------|
| `duration`  | 문자열  | 예      | 사람이 읽을 수 있는 형식의 기간입니다. 예: `3h30m`. |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.      |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다.     |

예제 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/time_estimate?duration=3h30m"
```

예제 응답:

```json
{
  "human_time_estimate": "3h 30m",
  "human_total_time_spent": null,
  "time_estimate": 12600,
  "total_time_spent": 0
}
```

### 이슈에 대한 시간 예상 초기화하기 {#reset-the-time-estimate-for-an-issue}

지정된 이슈의 예상 시간을 0초로 초기화합니다.

```plaintext
POST /projects/:id/issues/:issue_iid/reset_time_estimate
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/reset_time_estimate"
```

예제 응답:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

### 이슈에 대한 소요 시간 추가하기 {#add-spent-time-for-an-issue}

지정된 이슈에 대해 소요한 시간을 추가합니다.

```plaintext
POST /projects/:id/issues/:issue_iid/add_spent_time
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                              |
|-------------|---------|----------|------------------------------------------|
| `duration`  | 문자열  | 예      | 사람이 읽을 수 있는 형식의 기간입니다. 예를 들어: `3h30m` |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다.    |
| `summary`   | 문자열  | 아니요       | 시간이 어떻게 소요되었는지에 대한 요약입니다.  |

예제 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/add_spent_time?duration=1h"
```

예제 응답:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": "1h",
  "time_estimate": 0,
  "total_time_spent": 3600
}
```

### 이슈에 대한 소요 시간 초기화하기 {#reset-spent-time-for-an-issue}

지정된 이슈의 총 소요 시간을 0초로 초기화합니다.

```plaintext
POST /projects/:id/issues/:issue_iid/reset_spent_time
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/reset_spent_time"
```

예제 응답:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

### 이슈에 대한 시간 추적 통계 조회하기 {#retrieve-time-tracking-stats-for-an-issue}

지정된 이슈에 대한 시간 추적 통계를 사람이 읽을 수 있는 형식(예: `1h30m`)과 초 단위로 조회합니다.

프로젝트가 비공개이거나 이슈가 기밀인 경우 인증 자격 증명을 제공해야 합니다. 이 작업을 수행하는 선호되는 방법은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을(를) 사용하는 것입니다.

```plaintext
GET /projects/:id/issues/:issue_iid/time_stats
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/time_stats"
```

예제 응답:

```json
{
  "human_time_estimate": "2h",
  "human_total_time_spent": "1h",
  "time_estimate": 7200,
  "total_time_spent": 3600
}
```

## 머지 리퀘스트 {#merge-requests}

다음 요청들은 이슈와 머지 리퀘스트 간의 관계와 관련이 있습니다.

### 이슈와 관련된 모든 머지 리퀘스트 나열하기 {#list-all-merge-requests-related-to-an-issue}

지정된 이슈와 관련된 모든 머지 리퀘스트를 나열합니다.

프로젝트가 비공개이거나 이슈가 기밀인 경우 권한을 부여하기 위해 자격 증명을 제공해야 합니다. 이 작업을 수행하는 선호되는 방법은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을(를) 사용하는 것입니다.

```plaintext
GET /projects/:id/issues/:issue_iid/related_merge_requests
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/11/related_merge_requests"
```

예제 응답:

```json
[
  {
    "id": 29,
    "iid": 11,
    "project_id": 1,
    "title": "Provident eius eos blanditiis consequatur neque odit.",
    "description": "Ut consequatur ipsa aspernatur quisquam voluptatum fugit. Qui harum corporis quo fuga ut incidunt veritatis. Autem necessitatibus et harum occaecati nihil ea.\r\n\r\ntwitter/flight#8",
    "state": "opened",
    "created_at": "2018-09-18T14:36:15.510Z",
    "updated_at": "2018-09-19T07:45:13.089Z",
    "closed_by": null,
    "closed_at": null,
    "target_branch": "v2.x",
    "source_branch": "so_long_jquery",
    "user_notes_count": 9,
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 14,
      "name": "Verna Hills",
      "username": "lawanda_reinger",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/de68a91aeab1cff563795fb98a0c2cc0?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/lawanda_reinger"
    },
    "assignee": {
      "id": 19,
      "name": "Jody Baumbach",
      "username": "felipa.kuvalis",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6541fc75fc4e87e203529bd275fafd07?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/felipa.kuvalis"
    },
    "source_project_id": 1,
    "target_project_id": 1,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 27,
      "iid": 2,
      "project_id": 1,
      "title": "v1.0",
      "description": "Et tenetur voluptatem minima doloribus vero dignissimos vitae.",
      "state": "active",
      "created_at": "2018-09-18T14:35:44.353Z",
      "updated_at": "2018-09-18T14:35:44.353Z",
      "due_date": null,
      "start_date": null,
      "web_url": "https://gitlab.example.com/twitter/flight/milestones/2"
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "cannot_be_merged",
    "sha": "3b7b528e9353295c1c125dad281ac5b5deae5f12",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "reference": "!11",
    "web_url": "https://gitlab.example.com/twitter/flight/merge_requests/4",
    "references": {
      "short": "!4",
      "relative": "!4",
      "full": "twitter/flight!4"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status": {
      "count": 0,
      "completed_count": 0
    },
    "changes_count": "10",
    "latest_build_started_at": "2018-12-05T01:16:41.723Z",
    "latest_build_finished_at": "2018-12-05T02:35:54.046Z",
    "first_deployed_to_production_at": null,
    "pipeline": {
      "id": 38980952,
      "sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "ref": "test-branch",
      "status": "success",
      "web_url": "https://gitlab.com/gitlab-org/gitlab/pipelines/38980952"
    },
    "head_pipeline": {
      "id": 38980952,
      "sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "ref": "test-branch",
      "status": "success",
      "web_url": "https://gitlab.example.com/twitter/flight/pipelines/38980952",
      "before_sha": "3c738a37eb23cf4c0ed0d45d6ddde8aad4a8da51",
      "tag": false,
      "yaml_errors": null,
      "user": {
        "id": 19,
        "name": "Jody Baumbach",
        "username": "felipa.kuvalis",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/6541fc75fc4e87e203529bd275fafd07?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/felipa.kuvalis"
      },
      "created_at": "2018-12-05T01:16:13.342Z",
      "updated_at": "2018-12-05T02:35:54.086Z",
      "started_at": "2018-12-05T01:16:41.723Z",
      "finished_at": "2018-12-05T02:35:54.046Z",
      "committed_at": null,
      "duration": 4436,
      "coverage": "46.68",
      "detailed_status": {
        "icon": "status_warning",
        "text": "passed",
        "label": "passed with warnings",
        "group": "success-with-warnings",
        "tooltip": "passed",
        "has_details": true,
        "details_path": "/twitter/flight/pipelines/38",
        "illustration": null,
        "favicon": "https://gitlab.example.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
      },
      "archived": false
    },
    "diff_refs": {
      "base_sha": "d052d768f0126e8cddf80afd8b1eb07f406a3fcb",
      "head_sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "start_sha": "d052d768f0126e8cddf80afd8b1eb07f406a3fcb"
    },
    "merge_error": null,
    "user": {
      "can_merge": true
    }
  }
]
```

### 병합 시 이슈를 종료하는 모든 머지 리퀘스트 나열하기 {#list-all-merge-requests-that-close-an-issue-on-merge}

병합할 때 지정된 이슈를 종료하는 모든 머지 리퀘스트를 나열합니다.

프로젝트가 비공개이거나 이슈가 기밀인 경우 권한을 부여하기 위해 자격 증명을 제공해야 합니다. 이 작업을 수행하는 선호되는 방법은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을(를) 사용하는 것입니다.

```plaintext
GET /projects/:id/issues/:issue_iid/closed_by
```

지원되는 속성:

| 속성   | 유형           | 필수 | 설명                        |
| ----------- | ---------------| -------- | ---------------------------------- |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `issue_iid` | 정수        | 예      | 프로젝트 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/11/closed_by"
```

예제 응답:

```json
[
  {
    "id": 6471,
    "iid": 6432,
    "project_id": 1,
    "title": "add a test for cgi lexer options",
    "description": "closes #11",
    "state": "opened",
    "created_at": "2017-04-06T18:33:34.168Z",
    "updated_at": "2017-04-09T20:10:24.983Z",
    "target_branch": "main",
    "source_branch": "feature.custom-highlighting",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/root"
    },
    "assignee": null,
    "source_project_id": 1,
    "target_project_id": 1,
    "closed_at": null,
    "closed_by": null,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": null,
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "sha": "5a62481d563af92b8e32d735f2fa63b94e806835",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/merge_requests/6432",
    "reference": "!6432",
    "references": {
      "short": "!6432",
      "relative": "!6432",
      "full": "gitlab-org/gitlab-test!6432"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

## 이슈의 모든 참여자 나열하기 {#list-all-participants-in-an-issue}

지정된 이슈의 모든 참여자인 사용자를 나열합니다.

프로젝트가 비공개이거나 이슈가 기밀인 경우 권한을 부여하기 위해 자격 증명을 제공해야 합니다. 이 작업을 수행하는 선호되는 방법은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을(를) 사용하는 것입니다.

```plaintext
GET /projects/:id/issues/:issue_iid/participants
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  -url "https://gitlab.example.com/api/v4/projects/5/issues/93/participants"
```

예제 응답:

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user1"
  },
  {
    "id": 5,
    "name": "John Doe5",
    "username": "user5",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/4aea8cf834ed91844a2da4ff7ae6b491?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user5"
  }
]
```

## 이슈에 대한 댓글 {#comments-on-issues}

[노트 API](notes.md)를 사용하여 댓글과 상호 작용합니다.

## 이슈에 대한 사용자 에이전트 세부 정보 조회하기 {#retrieve-user-agent-details-for-an-issue}

관리자만 사용할 수 있습니다.

지정된 이슈를 만든 사용자의 사용자 에이전트 문자열과 IP 주소를 조회합니다. 스팸 추적에 사용됩니다.

```plaintext
GET /projects/:id/issues/:issue_iid/user_agent_detail
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/user_agent_detail"
```

예제 응답:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

## 이슈 상태 이벤트 나열하기 {#list-issue-state-events}

어떤 상태가 설정되었는지, 누가 설정했는지, 언제 설정되었는지 추적하려면 [리소스 상태 이벤트 API](resource_state_events.md#issues)를 사용합니다.

## 인시던트 {#incidents}

다음 요청들은 [인시던트](../operations/incident_management/incidents.md)에만 사용할 수 있습니다.

### 인시던트에 대한 측정항목 이미지 업로드하기 {#upload-a-metric-image-for-an-incident}

[인시던트](../operations/incident_management/incidents.md)에만 사용할 수 있습니다.

지정된 인시던트의 **측정항목** 탭에 표시할 측정항목 차트의 스크린샷을 업로드합니다. 이미지를 업로드할 때 이미지를 텍스트 또는 원본 그래프 링크와 연결할 수 있습니다. URL을 추가하면 업로드된 이미지 위의 하이퍼링크를 선택하여 원본 그래프에 액세스할 수 있습니다.

```plaintext
POST /projects/:id/issues/:issue_iid/metric_images
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |
| `file` | 파일 | 예      | 업로드할 이미지 파일입니다. |
| `url` | 문자열 | 아니요      | 더 많은 측정항목 정보를 보기 위한 URL입니다. |
| `url_text` | 문자열 | 아니요      | 이미지 또는 URL에 대한 설명입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --form 'file=@/path/to/file.png' \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images"
```

예제 응답:

```json
{
    "id": 23,
    "created_at": "2020-11-13T00:06:18.084Z",
    "filename": "file.png",
    "file_path": "/uploads/-/system/issuable_metric_image/file/23/file.png",
    "url": "http://example.com",
    "url_text": "Example website"
}
```

### 인시던트에 대한 모든 측정항목 이미지 나열하기 {#list-all-metric-images-for-an-incident}

[인시던트](../operations/incident_management/incidents.md)에만 사용할 수 있습니다.

지정된 인시던트의 **측정항목** 탭에 표시된 모든 측정항목 차트 스크린샷을 나열합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/metric_images
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  -url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images"
```

예제 응답:

```json
[
    {
        "id": 17,
        "created_at": "2020-11-12T20:07:58.156Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/issuable_metric_image/file/17/sample_2054.png",
        "url": "example.com/metric"
    },
    {
        "id": 18,
        "created_at": "2020-11-12T20:14:26.441Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/issuable_metric_image/file/18/sample_2054.png",
        "url": "example.com/metric"
    }
]
```

### 인시던트에 대한 측정항목 이미지 업데이트하기 {#update-a-metric-image-for-an-incident}

[인시던트](../operations/incident_management/incidents.md)에만 사용할 수 있습니다.

인시던트의 **측정항목** 탭에 표시된 지정된 측정항목 이미지의 속성을 업데이트합니다.

```plaintext
PUT /projects/:id/issues/:issue_iid/metric_images/:image_id
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |
| `image_id` | 정수 | 예      | 이미지의 ID입니다. |
| `url` | 문자열 | 아니요      | 더 많은 측정항목 정보를 보기 위한 URL입니다. |
| `url_text` | 문자열 | 아니요      | 이미지 또는 URL에 대한 설명입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request PUT \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images/1"
```

예제 응답:

```json
{
    "id": 23,
    "created_at": "2020-11-13T00:06:18.084Z",
    "filename": "file.png",
    "file_path": "/uploads/-/system/issuable_metric_image/file/23/file.png",
    "url": "http://example.com",
    "url_text": "Example website"
}
```

### 인시던트에서 측정항목 이미지 삭제하기 {#delete-a-metric-image-from-an-incident}

[인시던트](../operations/incident_management/incidents.md)에만 사용할 수 있습니다.

인시던트의 **측정항목** 탭에서 지정된 측정항목 이미지를 삭제합니다.

```plaintext
DELETE /projects/:id/issues/:issue_iid/metric_images/:image_id
```

지원되는 속성:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 전역 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈의 내부 ID입니다. |
| `image_id` | 정수 | 예      | 이미지의 ID입니다. |

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images/1"
```

다음 상태 코드를 반환할 수 있습니다:

- `204 No Content`(이미지가 성공적으로 삭제된 경우).
- `400 Bad Request`(이미지를 삭제할 수 없는 경우).
