---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 에픽 API (지원 중단됨)
description: "에픽의 공식 GitLab API 문서를 검토하세요. 그룹 내에서 에픽을 프로그래밍 방식으로 나열, 생성, 업데이트 및 삭제하는 방법을 알아보세요."
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> 에픽 REST API는 GitLab 17.0에서 [지원 중단](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)되었으며 API의 v5에서 제거될 예정입니다. GitLab 17.4부터 18.0까지, [에픽의 새로운 모양](../user/group/epics/_index.md#epics-as-work-items)이 활성화되어 있고 GitLab 18.1 이상에서는 대신 Work Items API를 사용하세요. 자세한 정보는 [에픽 API를 작업 항목으로 마이그레이션](graphql/epic_work_items_api_migration_guide.md)을 참조하세요. 이 변경 사항은 주요 변경 사항입니다.

에픽에 대한 모든 API 호출은 인증되어야 합니다.

사용자가 비공개 그룹의 구성원이 아닌 경우, 해당 그룹에 대한 `GET` 요청의 결과는 `404` 상태 코드입니다.

에픽 기능을 사용할 수 없는 경우 `403` 상태 코드가 반환됩니다.

## 레거시 에픽 ID 및 WorkItem ID {#legacy-epic-ids-and-workitem-ids}

레거시 에픽 ID는 WorkItem ID와 동일하지 않습니다. `iid`만 일치합니다. 하지만 에픽에 해당하는 WorkItem ID를 검색하려면 응답에 `work_item_id`가 포함됩니다.

이 ID는 WorkItem GraphQL API에 사용할 수 있습니다(예: `work_item_id`는 WorkItem GraphQL API에서 Global ID `gid://gitlab/WorkItem/123`입니다).

## 에픽 이슈 API {#epic-issues-api}

[에픽 이슈 API](epic_issues.md)를 사용하면 에픽과 연관된 이슈와 상호 작용할 수 있습니다.

## 마일스톤 날짜 통합 {#milestone-dates-integration}

시작 날짜 및 마감 날짜는 관련 이슈 마일스톤에서 동적으로 가져올 수 있으므로 사용자가 편집 권한을 가지고 있을 때 추가 필드가 표시됩니다. 여기에는 두 개의 부울 필드 `start_date_is_fixed` 및 `due_date_is_fixed`, 그리고 네 개의 날짜 필드 `start_date_fixed`, `start_date_from_inherited_source`, `due_date_fixed` 및 `due_date_from_inherited_source`이 포함됩니다.

- `end_date`은 `due_date`을 대신하여 지원 중단되었습니다.
- `start_date_from_milestones`은 `start_date_from_inherited_source`을 대신하여 지원 중단되었습니다
- `due_date_from_milestones`은 `due_date_from_inherited_source`을 대신하여 지원 중단되었습니다

## 모든 그룹 에픽 나열 {#list-all-group-epics}

지정된 그룹 및 해당 하위 그룹의 모든 에픽을 나열합니다.

응답은 [페이지 매김](rest/_index.md#pagination)되며 기본적으로 20개의 결과를 반환합니다.

> [!note]
> `references.relative`는 에픽이 요청되는 그룹에 상대적입니다. 에픽이 원래 그룹에서 가져온 경우, `relative` 형식은 `short` 형식과 동일합니다. 에픽이 그룹 간에 요청되는 경우, `relative` 형식은 `full` 형식과 동일할 것으로 예상됩니다.

```plaintext
GET /groups/:id/epics
GET /groups/:id/epics?author_id=5
GET /groups/:id/epics?labels=bug,reproduced
GET /groups/:id/epics?state=opened
```

| 속성           | 유형             | 필수   | 설명                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)               |
| `author_id`         | 정수          | 아니요         | 주어진 사용자 `id`이 생성한 에픽을 반환합니다                                                                                 |
| `author_username`   | 문자열           | 아니요         | 주어진 `username`이 있는 사용자가 생성한 에픽을 반환합니다. |
| `labels`            | 문자열           | 아니요         | 레이블 이름의 쉼표로 구분된 목록과 일치하는 에픽을 반환합니다. 에픽 그룹 또는 상위 그룹의 레이블 이름을 사용할 수 있습니다 |
| `with_labels_details` | 부울        | 아니요         | `true`인 경우, 응답은 레이블 필드의 각 레이블에 대한 자세한 정보를 반환합니다: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. 기본값은 `false`입니다. |
| `order_by`          | 문자열           | 아니요         | 에픽을 `created_at`, `updated_at` 또는 `title` 필드로 정렬하여 반환합니다. 기본값은 `created_at`입니다                              |
| `sort`              | 문자열           | 아니요         | 에픽을 `asc` 또는 `desc` 순서로 정렬하여 반환합니다. 기본값은 `desc`입니다                                                             |
| `search`            | 문자열           | 아니요         | 에픽을 해당 `title` 및 `description`에 대해 검색합니다                                                                        |
| `state`             | 문자열           | 아니요         | 에픽을 해당 `state`에 대해 검색합니다. 가능한 필터: `opened`, `closed` 및 `all`, 기본값: `all`                          |
| `created_after`     | 날짜/시간         | 아니요         | 주어진 시간 이후에 생성된 에픽을 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `created_before`    | 날짜/시간         | 아니요         | 주어진 시간 이전 또는 정확히 그때 생성된 에픽을 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `updated_after`     | 날짜/시간         | 아니요         | 주어진 시간 이후 업데이트된 에픽을 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `updated_before`    | 날짜/시간         | 아니요         | 주어진 시간 이전 또는 정확히 그때 업데이트된 에픽을 반환합니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `include_ancestor_groups` | 부울    | 아니요         | 요청된 그룹의 상위 항목에서 에픽을 포함합니다. 기본값은 `false`입니다                                                      |
| `include_descendant_groups` | 부울  | 아니요         | 요청된 그룹의 하위 항목에서 에픽을 포함합니다. 기본값은 `true`입니다                                                     |
| `my_reaction_emoji` | 문자열           | 아니요         | 인증된 사용자가 주어진 이모지로 반응한 에픽을 반환합니다. `None`는 반응하지 않은 에픽을 반환합니다. `Any`는 최소 하나의 반응을 받은 에픽을 반환합니다. |
| `not` | 해시 | 아니요 | 제공된 매개변수와 일치하지 않는 에픽을 반환합니다. 허용: `author_id`, `author_username` 및 `labels`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics"
```

응답 예시:

```json
[
  {
  "id": 29,
  "work_item_id": 1032,
  "iid": 4,
  "group_id": 7,
  "parent_id": 23,
  "parent_iid": 3,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/4",
  "reference": "&4",
  "references": {
    "short": "&4",
    "relative": "&4",
    "full": "test&4"
  },
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/kam"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/7/epics/4",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/4/issues",
      "group":"http://gitlab.example.com/api/v4/groups/7",
      "parent":"http://gitlab.example.com/api/v4/groups/7/epics/3"
  }
  },
  {
  "id": 50,
  "work_item_id": 1035,
  "iid": 35,
  "group_id": 17,
  "parent_id": 19,
  "parent_iid": 1,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "web_url": "http://gitlab.example.com/groups/test/sample/-/epics/35",
  "reference": "&4",
  "references": {
    "short": "&4",
    "relative": "sample&4",
    "full": "test/sample&4"
  },
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/kam"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "imported": false,
  "imported_from": "none",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/17/epics/35",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/17/epics/35/issues",
      "group":"http://gitlab.example.com/api/v4/groups/17",
      "parent":"http://gitlab.example.com/api/v4/groups/17/epics/1"
  }
  }
]
```

## 에픽 검색 {#retrieve-an-epic}

그룹의 지정된 에픽을 검색합니다.

```plaintext
GET /groups/:id/epics/:epic_iid
```

| 속성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 정수 또는 문자열   | 예        | 에픽의 내부 ID입니다.  |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5"
```

응답 예시:

```json
{
  "id": 30,
  "work_item_id": 1099,
  "iid": 5,
  "group_id": 7,
  "parent_id": null,
  "parent_iid": null,
  "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/5",
  "reference": "&5",
  "references": {
    "short": "&5",
    "relative": "&5",
    "full": "test&5"
  },
  "author":{
    "id": 7,
    "name": "Pamella Huel",
    "username": "arnita",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/arnita"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "subscribed": true,
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/7/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/5/issues",
      "group":"http://gitlab.example.com/api/v4/groups/7",
      "parent": null
  }
}
```

## 에픽 생성 {#create-an-epic}

지정된 그룹에 대해 에픽을 생성합니다.

> [!note]
> GitLab [11.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6448)부터 `start_date` 및 `end_date`은 더 이상 직접 할당되어서는 안 되며, 이제 복합 값을 나타냅니다. 대신 `*_is_fixed` 및 `*_fixed` 필드를 통해 이를 구성할 수 있습니다.

```plaintext
POST /groups/:id/epics
```

| 속성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)                |
| `title`             | 문자열           | 예        | 에픽의 제목 |
| `labels`            | 문자열           | 아니요         | 쉼표로 구분된 레이블 목록 |
| `description`       | 문자열           | 아니요         | 에픽의 설명입니다. 1,048,576자로 제한됩니다.  |
| `color`             | 문자열           | 아니요         | 에픽의 색상입니다. `epic_highlight_color` 기능 플래그 뒤에 있습니다(기본적으로 비활성화됨) |
| `confidential`      | 부울          | 아니요         | 에픽이 기밀이어야 하는지 여부 |
| `created_at`        | 문자열           | 아니요         | 에픽이 생성된 시점입니다. 날짜/시간 문자열, ISO 8601 형식으로, 예를 들어 `2016-03-11T03:45:40Z` . 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다 |
| `start_date_is_fixed` | 부울        | 아니요         | 시작 날짜를 `start_date_fixed` 또는 마일스톤에서 가져올지 여부 |
| `start_date_fixed`  | 문자열           | 아니요         | 에픽의 고정된 시작 날짜 |
| `due_date_is_fixed` | 부울          | 아니요         | 마감 날짜를 `due_date_fixed` 또는 마일스톤에서 가져올지 여부 |
| `due_date_fixed`    | 문자열           | 아니요         | 에픽의 고정된 마감 날짜 |
| `parent_id`         | 정수 또는 문자열   | 아니요         | 상위 에픽의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics?title=Epic&description=Epic%20description&parent_id=29"
```

응답 예시:

```json
{
  "id": 33,
  "work_item_id": 1020,
  "iid": 6,
  "group_id": 7,
  "parent_id": 29,
  "parent_iid": 4,
  "title": "Epic",
  "description": "Epic description",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/6",
  "reference": "&6",
  "references": {
    "short": "&6",
    "relative": "&6",
    "full": "test&6"
  },
  "author": {
    "name" : "Alexandra Bashirian",
    "avatar_url" : null,
    "state" : "active",
    "web_url" : "https://gitlab.example.com/eileen.lowe",
    "id" : 18,
    "username" : "eileen.lowe"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
    "self": "http://gitlab.example.com/api/v4/groups/7/epics/6",
    "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/6/issues",
    "group":"http://gitlab.example.com/api/v4/groups/7",
    "parent": "http://gitlab.example.com/api/v4/groups/7/epics/4"
  }
}
```

## 에픽 업데이트 {#update-an-epic}

그룹의 지정된 에픽을 업데이트합니다.

```plaintext
PUT /groups/:id/epics/:epic_iid
```

| 속성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 정수 또는 문자열   | 예        | 에픽의 내부 ID  |
| `add_labels`        | 문자열           | 아니요         | 이슈에 추가할 쉼표로 구분된 레이블 이름. |
| `confidential`      | 부울          | 아니요         | 에픽이 기밀이어야 하는지 여부 |
| `description`       | 문자열           | 아니요         | 에픽의 설명입니다. 1,048,576자로 제한됩니다.  |
| `due_date_fixed`    | 문자열           | 아니요         | 에픽의 고정된 마감 날짜 |
| `due_date_is_fixed` | 부울          | 아니요         | 마감 날짜를 `due_date_fixed` 또는 마일스톤에서 가져올지 여부 |
| `labels`            | 문자열           | 아니요         | 이슈에 대한 쉼표로 구분된 레이블 이름. 모든 레이블을 할당 해제하려면 빈 문자열로 설정하세요. |
| `parent_id`         | 정수 또는 문자열   | 아니요         | 상위 에픽의 ID. |
| `remove_labels`     | 문자열           | 아니요         | 이슈에서 제거할 쉼표로 구분된 레이블 이름. |
| `start_date_fixed`  | 문자열           | 아니요         | 에픽의 고정된 시작 날짜 |
| `start_date_is_fixed` | 부울        | 아니요         | 시작 날짜를 `start_date_fixed` 또는 마일스톤에서 가져올지 여부 |
| `state_event`       | 문자열           | 아니요         | 에픽에 대한 상태 이벤트입니다. 에픽을 닫으려면 `close`을 설정하고 다시 열려면 `reopen`을 설정하세요 |
| `title`             | 문자열           | 아니요         | 에픽의 제목 |
| `updated_at`        | 문자열           | 아니요         | 에픽이 업데이트된 시점입니다. 날짜/시간 문자열, ISO 8601 형식으로, 예를 들어 `2016-03-11T03:45:40Z` . 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다 |
| `color`             | 문자열           | 아니요         | 에픽의 색상입니다. `epic_highlight_color` 기능 플래그 뒤에 있습니다(기본적으로 비활성화됨) |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5?title=New%20Title&parent_id=29"
```

응답 예시:

```json
{
  "id": 33,
  "work_item_id": 1019,
  "iid": 6,
  "group_id": 7,
  "parent_id": 29,
  "parent_iid": 4,
  "title": "New Title",
  "description": "Epic description",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/6",
  "reference": "&6",
  "references": {
    "short": "&6",
    "relative": "&6",
    "full": "test&6"
  },
  "author": {
    "name" : "Alexandra Bashirian",
    "avatar_url" : null,
    "state" : "active",
    "web_url" : "https://gitlab.example.com/eileen.lowe",
    "id" : 18,
    "username" : "eileen.lowe"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf"
}
```

## 에픽 삭제 {#delete-an-epic}

{{< history >}}

- GitLab 16.11에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/452189)되었습니다. GitLab 16.10 이상에서는 에픽을 삭제하면 모든 하위 에픽과 그 하위 항목도 함께 삭제됩니다. 필요한 경우 삭제하기 전에 상위 에픽에서 하위 에픽을 제거할 수 있습니다.

{{< /history >}}

그룹에서 지정된 에픽을 삭제합니다.

```plaintext
DELETE /groups/:id/epics/:epic_iid
```

| 속성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 정수 또는 문자열   | 예        | 에픽의 내부 ID입니다.  |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5"
```

## 에픽에 대한 할 일 항목 생성 {#create-a-to-do-item-for-an-epic}

지정된 에픽에 대해 현재 사용자를 위한 할 일 항목을 생성합니다. 해당 에픽에 대해 사용자를 위한 할 일 항목이 이미 존재하면 상태 코드 304가 반환됩니다.

```plaintext
POST /groups/:id/epics/:epic_iid/todo
```

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예   | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)  |
| `epic_iid` | 정수 | 예          | 그룹의 에픽의 내부 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/todo"
```

응답 예시:

```json
{
  "id": 112,
  "group": {
    "id": 1,
    "name": "Gitlab",
    "path": "gitlab",
    "kind": "group",
    "full_path": "base/gitlab",
    "parent_id": null
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
  "target_type": "epic",
  "target": {
    "id": 30,
    "iid": 5,
    "group_id": 1,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author":{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/arnita"
    },
    "web_url": "http://gitlab.example.com/groups/test/-/epics/5",
    "reference": "&5",
    "references": {
      "short": "&5",
      "relative": "&5",
      "full": "test&5"
    },
    "start_date": null,
    "end_date": null,
    "created_at": "2018-01-21T06:21:13.165Z",
    "updated_at": "2018-01-22T12:41:41.166Z",
    "closed_at": "2018-08-18T12:22:05.239Z"
  },
  "target_url": "https://gitlab.example.com/groups/epics/5",
  "body": "Vel voluptas atque dicta mollitia adipisci qui at.",
  "state": "pending",
  "created_at": "2016-07-01T11:09:13.992Z"
}
```
