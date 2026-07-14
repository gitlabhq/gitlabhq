---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 기능 플래그 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab Premium 12.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/9566)
- [GitLab Free 13.5로 이동함](https://gitlab.com/gitlab-org/gitlab/-/issues/212318)

{{< /history >}}

이 API를 사용하여 GitLab [기능 플래그](../operations/feature_flags.md)와 상호작용할 수 있습니다.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

## 프로젝트의 기능 플래그 나열 {#list-feature-flags-for-a-project}

요청한 프로젝트의 모든 기능 플래그를 가져옵니다.

```plaintext
GET /projects/:id/feature_flags
```

`page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 매김을 제어합니다.

| 특성           | 유형             | 필수   | 설명                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.                                            |
| `scope`             | 문자열           | 아니오         | 기능 플래그의 조건입니다. 다음 중 하나: `enabled`, `disabled`                                                              |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags"
```

응답 예시:

```json
[
   {
      "name":"merge_train",
      "description":"This feature is about merge train",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:51.423Z",
      "updated_at":"2019-11-04T08:13:51.423Z",
      "scopes":[],
      "strategies": [
        {
          "id": 1,
          "name": "userWithId",
          "parameters": {
            "userIds": "user1"
          },
          "scopes": [
            {
              "id": 1,
              "environment_scope": "production"
            }
          ],
          "user_list": null
        }
      ]
   },
   {
      "name":"new_live_trace",
      "description":"This is a new live trace feature",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:10.507Z",
      "updated_at":"2019-11-04T08:13:10.507Z",
      "scopes":[],
      "strategies": [
        {
          "id": 2,
          "name": "default",
          "parameters": {},
          "scopes": [
            {
              "id": 2,
              "environment_scope": "staging"
            }
          ],
          "user_list": null
        }
      ]
   },
   {
      "name":"user_list",
      "description":"This feature is about user list",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:10.507Z",
      "updated_at":"2019-11-04T08:13:10.507Z",
      "scopes":[],
      "strategies": [
        {
          "id": 2,
          "name": "gitlabUserList",
          "parameters": {},
          "scopes": [
            {
              "id": 2,
              "environment_scope": "staging"
            }
          ],
          "user_list": {
            "id": 1,
            "iid": 1,
            "name": "My user list",
            "user_xids": "user1,user2,user3"
          }
        }
      ]
   }
]
```

## 기능 플래그 검색 {#retrieve-a-feature-flag}

지정된 기능 플래그를 검색합니다.

```plaintext
GET /projects/:id/feature_flags/:feature_flag_name
```

`page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 결과의 페이지 매김을 제어합니다.

| 특성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.       |
| `feature_flag_name` | 문자열           | 예        | 기능 플래그의 이름입니다.                                                          |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature"
```

응답 예시:

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T19:56:33.119Z",
  "updated_at": "2020-05-13T19:56:33.119Z",
  "scopes": [],
  "strategies": [
    {
      "id": 36,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 37,
          "environment_scope": "production"
        }
      ],
      "user_list": null
    }
  ]
}
```

## 기능 플래그 생성 {#create-a-feature-flag}

지정된 프로젝트의 기능 플래그를 생성합니다.

```plaintext
POST /projects/:id/feature_flags
```

| 특성           | 유형             | 필수   | 설명                                                                                                                                                                                                                                                                              |
| ------------------- | ---------------- | ---------- |------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.                                                                                                                                                                                                     |
| `name`              | 문자열           | 예        | 기능 플래그의 이름입니다.                                                                                                                                                                                                                                                            |
| `version`           | 문자열           | 예        | **더 이상 사용되지 않음** 기능 플래그의 버전입니다. `new_version_flag`이어야 합니다. 레거시 기능 플래그를 생성하려면 생략합니다.                                                                                                                                                                        |
| `description`       | 문자열           | 아니오         | 기능 플래그의 설명입니다.                                                                                                                                                                                                                                                     |
| `active`            | 부울          | 아니오         | 플래그의 활성 상태입니다. 기본값은 true입니다.                                                                                                                                                                                                                                          |
| `strategies`        | 전략 JSON 객체 배열 | 아니오         | 기능 플래그 [전략](../operations/feature_flags.md#feature-flag-strategies)                                                                                                                                                                                     |
| `strategies:name`   | JSON             | 아니오         | 전략 이름입니다. 다음 중 하나가 될 수 있습니다: `default`, `gradualRolloutUserId`, `userWithId`, 또는 `gitlabUserList` [GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/36380) 이상에서는 [`flexibleRollout`](https://docs.getunleash.io/user_guide/activation_strategy/#gradual-rollout)가 될 수 있습니다. |
| `strategies:parameters` | JSON         | 아니오         | 전략 매개변수입니다.                                                                                                                                                                                                                                                                 |
| `strategies:scopes` | JSON             | 아니오         | 전략의 범위입니다.                                                                                                                                                                                                                                                             |
| `strategies:scopes:environment_scope` | 문자열 | 아니오 | 범위의 환경 범위입니다.                                                                                                                                                                                                                                                      |
| `strategies:user_list_id` | 정수 또는 문자열 | 아니오     | 기능 플래그 사용자 목록의 ID입니다. 전략이 `gitlabUserList`인 경우입니다.                                                                                                                                                                                                                   |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
  "name": "awesome_feature",
  "version": "new_version_flag",
  "strategies": [{ "name": "default", "parameters": {}, "scopes": [{ "environment_scope": "production" }] }]
}
EOF
```

응답 예시:

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T19:56:33.119Z",
  "updated_at": "2020-05-13T19:56:33.119Z",
  "scopes": [],
  "strategies": [
    {
      "id": 36,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 37,
          "environment_scope": "production"
        }
      ]
    }
  ]
}
```

## 기능 플래그 업데이트 {#update-a-feature-flag}

지정된 기능 플래그를 업데이트합니다.

```plaintext
PUT /projects/:id/feature_flags/:feature_flag_name
```

| 특성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.   |
| `feature_flag_name` | 문자열           | 예        | 기능 플래그의 현재 이름입니다.                                                  |
| `description`       | 문자열           | 아니오         | 기능 플래그의 설명입니다.                                                   |
| `active`            | 부울          | 아니오         | 플래그의 활성 상태입니다.                                                          |
| `name`              | 문자열           | 아니오         | 기능 플래그의 새로운 이름입니다.                                                      |
| `strategies`        | 전략 JSON 객체 배열 | 아니오         | 기능 플래그 [전략](../operations/feature_flags.md#feature-flag-strategies) |
| `strategies:id`     | JSON             | 아니오         | 기능 플래그 전략 ID입니다.                                                          |
| `strategies:name`   | JSON             | 아니오         | 전략 이름입니다.                                                                     |
| `strategies:_destroy` | 부울         | 아니오         | true인 경우 전략을 삭제합니다.                                                        |
| `strategies:parameters` | JSON         | 아니오         | 전략 매개변수입니다.                                                               |
| `strategies:scopes` | JSON             | 아니오         | 전략의 범위입니다.                                                           |
| `strategies:scopes:id` | JSON          | 아니오         | 환경 범위 ID입니다.                                                              |
| `strategies:scopes:environment_scope` | 문자열 | 아니오 | 범위의 환경 범위입니다.                                                    |
| `strategies:scopes:_destroy` | 부울 | 아니오 | true인 경우 범위를 삭제합니다.                                                                    |
| `strategies:user_list_id` | 정수 또는 문자열 | 아니오     | 기능 플래그 사용자 목록의 ID입니다. 전략이 `gitlabUserList`인 경우입니다.                 |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
  "strategies": [{ "name": "gradualRolloutUserId", "parameters": { "groupId": "default", "percentage": "25" }, "scopes": [{ "environment_scope": "staging" }] }]
}
EOF
```

응답 예시:

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T20:10:32.891Z",
  "updated_at": "2020-05-13T20:10:32.891Z",
  "scopes": [],
  "strategies": [
    {
      "id": 38,
      "name": "gradualRolloutUserId",
      "parameters": {
        "groupId": "default",
        "percentage": "25"
      },
      "scopes": [
        {
          "id": 40,
          "environment_scope": "staging"
        }
      ]
    },
    {
      "id": 37,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 39,
          "environment_scope": "production"
        }
      ]
    }
  ]
}
```

## 기능 플래그 삭제 {#delete-a-feature-flag}

지정된 기능 플래그를 삭제합니다.

```plaintext
DELETE /projects/:id/feature_flags/:feature_flag_name
```

| 특성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.       |
| `feature_flag_name` | 문자열           | 예        | 기능 플래그의 이름입니다.                                                          |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature"
```
