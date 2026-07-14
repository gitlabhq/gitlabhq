---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 기능 플래그 사용자 목록 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/205409) [GitLab Premium](https://about.gitlab.com/pricing/) 12.10
- [이동됨](https://gitlab.com/gitlab-org/gitlab/-/issues/212318) GitLab Free 13.5

{{< /history >}}

이 API를 사용하여 GitLab 기능 플래그에 대한 [사용자 목록](../operations/feature_flags.md#user-list)과 상호 작용합니다.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

> [!note]
> 모든 사용자의 기능 플래그와 상호 작용하려면 [Feature flag API](feature_flags.md)를 참조하세요.

## 프로젝트의 모든 기능 플래그 사용자 목록 나열 {#list-all-feature-flag-user-lists-for-a-project}

지정된 프로젝트의 모든 기능 플래그 사용자 목록을 나열합니다.

```plaintext
GET /projects/:id/feature_flags_user_lists
```

`page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개 변수를 사용하여 결과의 페이지 매김을 제어합니다.

| 속성 | 유형           | 필수 | 설명                                                                      |
| --------- | -------------- | -------- | -------------------------------------------------------------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `search`  | 문자열         | 아니요       | 검색 기준과 일치하는 사용자 목록을 반환합니다.                                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists"
```

예시 응답:

```json
[
   {
      "name": "user_list",
      "user_xids": "user1,user2",
      "id": 1,
      "iid": 1,
      "project_id": 1,
      "created_at": "2020-02-04T08:13:51.423Z",
      "updated_at": "2020-02-04T08:13:51.423Z"
   },
   {
      "name": "test_users",
      "user_xids": "user3,user4,user5",
      "id": 2,
      "iid": 2,
      "project_id": 1,
      "created_at": "2020-02-04T08:13:10.507Z",
      "updated_at": "2020-02-04T08:13:10.507Z"
   }
]
```

## 기능 플래그 사용자 목록 생성 {#create-a-feature-flag-user-list}

지정된 프로젝트에서 기능 플래그 사용자 목록을 생성합니다.

```plaintext
POST /projects/:id/feature_flags_user_lists
```

| 속성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.       |
| `name`              | 문자열           | 예        | 목록의 이름입니다. |
| `user_xids`         | 문자열           | 예        | 쉼표로 구분된 외부 사용자 ID 목록입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists" \
  --data @- << EOF
{
    "name": "my_user_list",
    "user_xids": "user1,user2,user3"
}
EOF
```

예시 응답:

```json
{
   "name": "my_user_list",
   "user_xids": "user1,user2,user3",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:32:27.288Z",
   "updated_at": "2020-02-04T08:32:27.288Z"
}
```

## 기능 플래그 사용자 목록 검색 {#retrieve-a-feature-flag-user-list}

지정된 기능 플래그 사용자 목록을 검색합니다.

```plaintext
GET /projects/:id/feature_flags_user_lists/:iid
```

`page` 및 `per_page` [페이지 매김](rest/_index.md#offset-based-pagination) 매개 변수를 사용하여 결과의 페이지 매김을 제어합니다.

| 속성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.       |
| `iid`               | 정수 또는 문자열   | 예        | 프로젝트의 기능 플래그 사용자 목록의 내부 ID입니다.                               |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1"
```

예시 응답:

```json
{
   "name": "my_user_list",
   "user_xids": "123,456",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:13:10.507Z",
   "updated_at": "2020-02-04T08:13:10.507Z"
}
```

## 기능 플래그 사용자 목록 업데이트 {#update-a-feature-flag-user-list}

지정된 기능 플래그 사용자 목록을 업데이트합니다.

```plaintext
PUT /projects/:id/feature_flags_user_lists/:iid
```

| 속성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.       |
| `iid`               | 정수 또는 문자열   | 예        | 프로젝트의 기능 플래그 사용자 목록의 내부 ID입니다.                               |
| `name`              | 문자열           | 아니요         | 목록의 이름입니다.                                                          |
| `user_xids`         | 문자열           | 아니요         | 쉼표로 구분된 외부 사용자 ID 목록입니다.                                                    |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1" \
  --data @- << EOF
{
    "user_xids": "user2,user3,user4"
}
EOF
```

예시 응답:

```json
{
   "name": "my_user_list",
   "user_xids": "user2,user3,user4",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:32:27.288Z",
   "updated_at": "2020-02-05T09:33:17.179Z"
}
```

## 기능 플래그 사용자 목록 삭제 {#delete-feature-flag-user-list}

지정된 기능 플래그 사용자 목록을 삭제합니다.

```plaintext
DELETE /projects/:id/feature_flags_user_lists/:iid
```

| 속성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.       |
| `iid`               | 정수 또는 문자열   | 예        | 프로젝트의 기능 플래그 사용자 목록의 내부 ID                                |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1"
```
