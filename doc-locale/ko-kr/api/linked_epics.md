---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 연결된 에픽 API (더 이상 사용되지 않음)
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 14.9에서 [기능 플래그](../administration/feature_flags/_index.md) 와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/352493)되었습니다(`related_epics_widget`). 기본적으로 활성화됨.
- [기능 플래그 `related_epics_widget`](https://gitlab.com/gitlab-org/gitlab/-/issues/357089)는 GitLab 15.0에서 제거되었습니다.

{{< /history >}}

> [!warning]
> Epics REST API는 GitLab 17.0에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) API의 v5에서 제거될 예정입니다. GitLab 17.4~18.0에서 [에픽의 새로운 모양](../user/group/epics/_index.md#epics-as-work-items)이 활성화된 경우 및 GitLab 18.1 이상에서는 대신 Work Items API를 사용하세요. 자세한 내용은 [에픽 API를 작업 항목으로 마이그레이션](graphql/epic_work_items_api_migration_guide.md)을 참조하세요. 이 변경 사항은 주요 변경 사항입니다.

Related Epics 기능이 GitLab 플랜에서 사용할 수 없으면 `403` 상태 코드가 반환됩니다.

## 그룹의 모든 관련 에픽 링크 나열 {#list-all-related-epic-links-for-a-group}

지정된 그룹 및 하위 그룹의 모든 관련 에픽 링크를 나열합니다. 사용자는 관련 에픽 링크를 보기 위해 `source_epic`과 `target_epic` 모두에 액세스 권한이 있어야 합니다.

```plaintext
GET /groups/:id/related_epic_links
```

지원되는 속성:

| 속성  | 유형           | 필수               | 설명                                                               |
| ---------- | -------------- | ---------------------- | ------------------------------------------------------------------------- |
| `id`       | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `created_after` | 문자열 | 아니요 | 지정된 시간 이상으로 생성된 관련 에픽 링크를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)  |
| `created_before` | 문자열 | 아니요 | 지정된 시간 이하로 생성된 관련 에픽 링크를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `updated_after` | 문자열 | 아니요 | 지정된 시간 이상으로 업데이트된 관련 에픽 링크를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)  |
| `updated_before` | 문자열 | 아니요 | 지정된 시간 이하로 업데이트된 관련 에픽 링크를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/related_epic_links"
```

응답 예시:

```json
[
  {
    "id": 1,
    "created_at": "2022-01-31T15:10:44.988Z",
    "updated_at": "2022-01-31T15:10:44.988Z",
    "link_type": "relates_to",
    "source_epic": {
      "id": 21,
      "iid": 1,
      "color": "#1068bf",
      "text_color": "#FFFFFF",
      "group_id": 26,
      "parent_id": null,
      "parent_iid": null,
      "title": "Aspernatur recusandae distinctio omnis et qui est iste.",
      "description": "some description",
      "confidential": false,
      "author": {
        "id": 15,
        "username": "trina",
        "name": "Theresia Robel",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/085e28df717e16484cbf6ceca75e9a93?s=80&d=identicon",
        "web_url": "http://gitlab.example.com/trina"
      },
      "start_date": null,
      "end_date": null,
      "due_date": null,
      "state": "opened",
      "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/1",
      "references": {
        "short": "&1",
        "relative": "&1",
        "full": "flightjs&1"
      },
      "created_at": "2022-01-31T15:10:44.988Z",
      "updated_at": "2022-03-16T09:32:35.712Z",
      "closed_at": null,
      "labels": [],
      "upvotes": 0,
      "downvotes": 0,
      "_links": {
        "self": "http://gitlab.example.com/api/v4/groups/26/epics/1",
        "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/1/issues",
        "group": "http://gitlab.example.com/api/v4/groups/26",
        "parent": null
      }
    },
    "target_epic": {
      "id": 25,
      "iid": 5,
      "color": "#1068bf",
      "text_color": "#FFFFFF",
      "group_id": 26,
      "parent_id": null,
      "parent_iid": null,
      "title": "Aut assumenda id nihil distinctio fugiat vel numquam est.",
      "description": "some description",
      "confidential": false,
      "author": {
        "id": 3,
        "username": "valerie",
        "name": "Erika Wolf",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/9ef7666abb101418a4716a8ed4dded80?s=80&d=identicon",
        "web_url": "http://gitlab.example.com/valerie"
      },
      "start_date": null,
      "end_date": null,
      "due_date": null,
      "state": "opened",
      "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/5",
      "references": {
        "short": "&5",
        "relative": "&5",
        "full": "flightjs&5"
      },
      "created_at": "2022-01-31T15:10:45.080Z",
      "updated_at": "2022-03-16T09:32:35.842Z",
      "closed_at": null,
      "labels": [],
      "upvotes": 0,
      "downvotes": 0,
      "_links": {
        "self": "http://gitlab.example.com/api/v4/groups/26/epics/5",
        "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/5/issues",
        "group": "http://gitlab.example.com/api/v4/groups/26",
        "parent": null
      }
    },
  }
]
```

## 에픽의 모든 연결된 에픽 나열 {#list-all-linked-epics-for-an-epic}

지정된 에픽의 모든 연결된 에픽을 나열합니다.

```plaintext
GET /groups/:id/epics/:epic_iid/related_epics
```

지원되는 속성:

| 속성  | 유형           | 필수               | 설명                                                               |
| ---------- | -------------- | ---------------------- | ------------------------------------------------------------------------- |
| `epic_iid` | 정수        | 예 | 그룹의 에픽 내부 ID                                             |
| `id`       | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request GET \
 --header "PRIVATE-TOKEN: <your_access_token>" \
 --url "https://gitlab.example.com/api/v4/groups/:id/epics/:epic_iid/related_epics"
```

응답 예시:

```json
[
   {
      "id":2,
      "iid":2,
      "color":"#1068bf",
      "text_color":"#FFFFFF",
      "group_id":2,
      "parent_id":null,
      "parent_iid":null,
      "title":"My title 2",
      "description":null,
      "confidential":false,
      "author":{
         "id":3,
         "username":"user3",
         "name":"Sidney Jones4",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/82797019f038ab535a84c6591e7bc936?s=80u0026d=identicon",
         "web_url":"http://localhost/user3"
      },
      "start_date":null,
      "end_date":null,
      "due_date":null,
      "state":"opened",
      "web_url":"http://localhost/groups/group1/-/epics/2",
      "references":{
         "short":"u00262",
         "relative":"u00262",
         "full":"group1u00262"
      },
      "created_at":"2022-03-10T18:35:24.479Z",
      "updated_at":"2022-03-10T18:35:24.479Z",
      "closed_at":null,
      "labels":[

      ],
      "upvotes":0,
      "downvotes":0,
      "_links":{
         "self":"http://localhost/api/v4/groups/2/epics/2",
         "epic_issues":"http://localhost/api/v4/groups/2/epics/2/issues",
         "group":"http://localhost/api/v4/groups/2",
         "parent":null
      },
      "related_epic_link_id":1,
      "link_type":"relates_to",
      "link_created_at":"2022-03-10T18:35:24.496+00:00",
      "link_updated_at":"2022-03-10T18:35:24.496+00:00"
   }
]
```

## 관련 에픽 링크 생성 {#create-a-related-epic-link}

{{< history >}}

- 그룹의 필수 최소 역할이 GitLab 15.8에서 Reporter에서 [Guest로 변경](https://gitlab.com/gitlab-org/gitlab/-/issues/381308)되었습니다.

{{< /history >}}

두 에픽 간의 양방향 관계를 생성합니다. 사용자는 두 그룹 모두에 대해 Guest, 플래너, Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
POST /groups/:id/epics/:epic_iid/related_epics
```

지원되는 속성:

| 속성           | 유형           | 필수                    | 설명                           |
|---------------------|----------------|-----------------------------|---------------------------------------|
| `epic_iid`          | 정수        | 예      | 그룹의 에픽 내부 ID입니다.        |
| `id`                | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `target_epic_iid`   | 정수 또는 문자열 | 예      | 대상 그룹의 에픽 내부 ID입니다. |
| `target_group_id`   | 정수 또는 문자열 | 예      | 대상 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `link_type`         | 문자열         | 아니요      | 관계 유형(`relates_to`, `blocks`, `is_blocked_by`)이며 기본값은 `relates_to`입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/epics/1/related_epics?target_group_id=26&target_epic_iid=5"
```

응답 예시:

```json
{
  "id": 1,
  "created_at": "2022-01-31T15:10:44.988Z",
  "updated_at": "2022-01-31T15:10:44.988Z",
  "link_type": "relates_to",
  "source_epic": {
    "id": 21,
    "iid": 1,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aspernatur recusandae distinctio omnis et qui est iste.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 15,
      "username": "trina",
      "name": "Theresia Robel",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/085e28df717e16484cbf6ceca75e9a93?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/trina"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/1",
    "references": {
      "short": "&1",
      "relative": "&1",
      "full": "flightjs&1"
    },
    "created_at": "2022-01-31T15:10:44.988Z",
    "updated_at": "2022-03-16T09:32:35.712Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/1",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/1/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
  "target_epic": {
    "id": 25,
    "iid": 5,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aut assumenda id nihil distinctio fugiat vel numquam est.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 3,
      "username": "valerie",
      "name": "Erika Wolf",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/9ef7666abb101418a4716a8ed4dded80?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/valerie"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/5",
    "references": {
      "short": "&5",
      "relative": "&5",
      "full": "flightjs&5"
    },
    "created_at": "2022-01-31T15:10:45.080Z",
    "updated_at": "2022-03-16T09:32:35.842Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/5/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
}
```

## 관련 에픽 링크 삭제 {#delete-a-related-epic-link}

{{< history >}}

- 그룹의 필수 최소 역할이 GitLab 15.8에서 Reporter에서 [Guest로 변경](https://gitlab.com/gitlab-org/gitlab/-/issues/381308)되었습니다.

{{< /history >}}

두 개의 지정된 에픽 간의 양방향 관계를 삭제합니다. 사용자는 두 그룹 모두에 대해 Guest, 플래너, Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
DELETE /groups/:id/epics/:epic_iid/related_epics/:related_epic_link_id
```

지원되는 속성:

| 속성                | 유형           | 필수                    | 설명                           |
|--------------------------|----------------|-----------------------------|---------------------------------------|
| `epic_iid`               | 정수        | 예      | 그룹의 에픽 내부 ID입니다.        |
| `id`                     | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `related_epic_link_id`   | 정수 또는 문자열 | 예      | 관련 에픽 링크의 내부 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/epics/1/related_epics/1"
```

응답 예시:

```json
{
  "id": 1,
  "created_at": "2022-01-31T15:10:44.988Z",
  "updated_at": "2022-01-31T15:10:44.988Z",
  "link_type": "relates_to",
  "source_epic": {
    "id": 21,
    "iid": 1,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aspernatur recusandae distinctio omnis et qui est iste.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 15,
      "username": "trina",
      "name": "Theresia Robel",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/085e28df717e16484cbf6ceca75e9a93?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/trina"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/1",
    "references": {
      "short": "&1",
      "relative": "&1",
      "full": "flightjs&1"
    },
    "created_at": "2022-01-31T15:10:44.988Z",
    "updated_at": "2022-03-16T09:32:35.712Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/1",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/1/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
  "target_epic": {
    "id": 25,
    "iid": 5,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aut assumenda id nihil distinctio fugiat vel numquam est.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 3,
      "username": "valerie",
      "name": "Erika Wolf",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/9ef7666abb101418a4716a8ed4dded80?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/valerie"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/5",
    "references": {
      "short": "&5",
      "relative": "&5",
      "full": "flightjs&5"
    },
    "created_at": "2022-01-31T15:10:45.080Z",
    "updated_at": "2022-03-16T09:32:35.842Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/5/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
}
```
