---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 에픽 링크 API(더 이상 사용되지 않음)
description: "에픽 링크에 대한 GitLab API 문서를 검토하세요. 부모 및 자식 에픽 관계를 프로그래밍 방식으로 관리, 생성 및 제거하는 방법을 알아보세요."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Epics REST API는 GitLab 17.0에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) API v5에서 제거될 예정입니다. GitLab 17.4에서 18.0까지 [에픽의 새로운 모양](../user/group/epics/_index.md#epics-as-work-items)이 활성화되어 있거나 GitLab 18.1 이상에서는 대신 Work Items API를 사용하세요. 자세한 내용은 [에픽 API를 작업 항목으로 마이그레이션](graphql/epic_work_items_api_migration_guide.md)을 참조하세요. 이는 주요 변경 사항입니다.

부모-자식 [에픽 관계](../user/work_items/child_items.md#work-with-multi-level-hierarchies)를 관리합니다.

`epic_links`에 대한 모든 API 호출은 인증되어야 합니다.

사용자가 개인 그룹의 구성원이 아닌 경우 해당 그룹에 대한 `GET` 요청은 `404` 상태 코드를 반환합니다.

다중 수준 에픽은 [GitLab Ultimate](https://about.gitlab.com/pricing/)에서만 사용할 수 있습니다. 다중 수준 에픽 기능을 사용할 수 없는 경우 `403` 상태 코드가 반환됩니다.

## 에픽의 모든 자식 에픽 나열 {#list-all-child-epics-of-an-epic}

에픽의 모든 자식 에픽을 나열합니다.

```plaintext
GET /groups/:id/epics/:epic_iid/epics
```

| 속성  | 유형           | 필수 | 설명                                                                                                   |
| ---------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------- |
| `id`       | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `epic_iid` | 정수        | 예      | 에픽의 내부 ID입니다.                                                                                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/epics"
```

응답 예시:

```json
[
  {
    "id": 29,
    "iid": 6,
    "group_id": 1,
    "parent_id": 5,
    "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
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
    "labels": []
  }
]
```

## 자식 에픽 할당 {#assign-a-child-epic}

두 에픽 간의 연결을 생성하여 하나를 부모 에픽으로, 다른 하나를 자식 에픽으로 지정합니다. 부모 에픽은 여러 자식 에픽을 가질 수 있습니다. 새 자식 에픽이 이미 다른 에픽에 속해 있는 경우 이전 부모에서 할당이 해제됩니다.

```plaintext
POST /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| 속성       | 유형           | 필수 | 설명                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)      |
| `epic_iid`      | 정수        | 예      | 에픽의 내부 ID입니다.                                                                                       |
| `child_epic_id` | 정수        | 예      | 자식 에픽의 전역 ID입니다. 다른 그룹의 에픽과 충돌할 수 있으므로 내부 ID는 사용할 수 없습니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/epics/6"

```

응답 예시:

```json
{
  "id": 6,
  "iid": 38,
  "group_id": 1,
  "parent_id": 5,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://localhost:3001/kam"
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
  "labels": []
}
```

## 자식 에픽 생성 및 할당 {#create-and-assign-a-child-epic}

새 에픽을 생성하고 제공된 부모 에픽과 연결합니다. 응답은 `LinkedEpic` 객체입니다.

```plaintext
POST /groups/:id/epics/:epic_iid/epics
```

| 속성       | 유형           | 필수 | 설명                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)      |
| `epic_iid`      | 정수        | 예      | (향후 부모) 에픽의 내부 ID입니다.                                                                       |
| `title`         | 문자열         | 예      | 새로 생성된 에픽의 제목입니다.                                                                                 |
| `confidential`  | 부울        | 아니요       | 에픽이 기밀인지 여부입니다. `confidential_epics` 기능 플래그가 비활성화되면 매개변수는 무시됩니다. 부모 에픽의 기밀성 상태로 기본 설정됩니다.  |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/epics?title=Newpic"
```

응답 예시:

```json
{
  "id": 24,
  "iid": 2,
  "title": "child epic",
  "group_id": 49,
  "parent_id": 23,
  "has_children": false,
  "has_issues": false,
  "reference":  "&2",
  "url": "http://localhost/groups/group16/-/epics/2",
  "relation_url": "http://localhost/groups/group16/-/epics/1/links/24"
}
```

## 자식 에픽 순서 변경 {#re-order-a-child-epic}

```plaintext
PUT /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| 속성        | 유형           | 필수 | 설명                                                                                                        |
| ---------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`             | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다.     |
| `epic_iid`       | 정수        | 예      | 에픽의 내부 ID입니다.                                                                                       |
| `child_epic_id`  | 정수        | 예      | 자식 에픽의 전역 ID입니다. 다른 그룹의 에픽과 충돌할 수 있으므로 내부 ID는 사용할 수 없습니다. |
| `move_before_id` | 정수        | 아니요       | 자식 에픽 앞에 배치해야 하는 형제 에픽의 전역 ID입니다.                                       |
| `move_after_id`  | 정수        | 아니요       | 자식 에픽 뒤에 배치해야 하는 형제 에픽의 전역 ID입니다.                                        |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/4/epics/5"
```

응답 예시:

```json
[
  {
    "id": 29,
    "iid": 6,
    "group_id": 1,
    "parent_id": 5,
    "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
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
    "labels": []
  }
]
```

## 자식 에픽 할당 해제 {#unassign-a-child-epic}

자식 에픽을 부모 에픽에서 할당 해제합니다.

```plaintext
DELETE /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| 속성       | 유형           | 필수 | 설명                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다.     |
| `epic_iid`      | 정수        | 예      | 에픽의 내부 ID입니다.                                                                                       |
| `child_epic_id` | 정수        | 예      | 자식 에픽의 전역 ID입니다. 다른 그룹의 에픽과 충돌할 수 있으므로 내부 ID는 사용할 수 없습니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/4/epics/5"
```

응답 예시:

```json
{
  "id": 5,
  "iid": 38,
  "group_id": 1,
  "parent_id": null,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://localhost:3001/kam"
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
  "labels": []
}
```
