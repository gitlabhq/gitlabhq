---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 네임스페이스 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3에서 청구 관련 필드의 가시성이 [플래그](../administration/feature_flags/_index.md)와 함께 변경되었습니다. `restrict_namespace_api_billing_fields`라는 이름입니다. 기본적으로 비활성화됨.
- 청구 관련 필드의 가시성이 GitLab 18.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/565598)합니다. 기능 플래그 `restrict_namespace_api_billing_fields` 제거됨.

{{< /history >}}

이 API를 사용하여 네임스페이스와 상호 작용합니다. 네임스페이스는 사용자와 그룹을 구성하는 데 사용되는 특수한 리소스 범주입니다. 자세한 내용은 [네임스페이스](../user/namespace/_index.md)를 참조하세요.

이 API는 [Pagination](rest/_index.md#pagination)을 사용하여 결과를 필터링합니다.

## 모든 네임스페이스 나열 {#list-all-namespaces}

{{< history >}}

- `top_level_only` [GitLab 16.8에서 도입](https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/7600)되었습니다.

{{< /history >}}

현재 사용자가 사용할 수 있는 모든 네임스페이스를 나열합니다. 사용자가 관리자인 경우 이 엔드포인트는 인스턴스의 모든 네임스페이스를 반환합니다.

```plaintext
GET /namespaces
```

| 속성          | 유형    | 필수 | 설명                                                                             |
|--------------------|---------|----------|-----------------------------------------------------------------------------------------|
| `search`           | 문자열  | 아니요       | 지정된 값을 이름이나 경로에 포함하는 네임스페이스만 반환합니다.         |
| `owned_only`       | 부울 | 아니요       | `true`인 경우 현재 사용자가 소유한 네임스페이스만 반환합니다.                                 |
| `top_level_only`   | 부울 | 아니요       | GitLab 16.8 이상에서 `true`인 경우 최상위 네임스페이스만 반환합니다.                 |
| `full_path_search` | 부울 | 아니요       | `true`인 경우 `search` 매개변수는 네임스페이스의 전체 경로와 일치합니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "user1",
    "path": "user1",
    "kind": "user",
    "full_path": "user1",
    "parent_id": null,
    "avatar_url": "https://secure.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/user1",
    "billable_members_count": 1,
    "plan": "ultimate",
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  },
  {
    "id": 2,
    "name": "group1",
    "path": "group1",
    "kind": "group",
    "full_path": "group1",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/group1",
    "members_count_with_descendants": 2,
    "billable_members_count": 2,
    "plan": "ultimate",
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  },
  {
    "id": 3,
    "name": "bar",
    "path": "bar",
    "kind": "group",
    "full_path": "foo/bar",
    "parent_id": 9,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/foo/bar",
    "members_count_with_descendants": 5,
    "billable_members_count": 5,
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  }
]
```

추가 속성은 그룹 소유자 또는 GitLab.com에서 반환될 수 있습니다:

```json
[
  {
    ...
    "max_seats_used": 3,
    "max_seats_used_changed_at":"2025-05-15T12:00:02.000Z",
    "seats_in_use": 2,
    "projects_count": 1,
    "root_repository_size":0,
    "members_count_with_descendants":26,
    "plan": "free",
    ...
  }
]
```

## 네임스페이스 세부 정보 검색 {#retrieve-namespace-details}

지정된 네임스페이스의 세부 정보를 검색합니다.

```plaintext
GET /namespaces/:id
```

| 속성 | 유형           | 필수 | 설명 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 네임스페이스의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces/2"
```

응답 예시:

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100,
  "projects_count": 3
}
```

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/namespaces/group1"
```

응답 예시:

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100
}
```

## 네임스페이스 가용성 확인 {#verify-namespace-availability}

지정된 네임스페이스가 존재하는지 확인합니다. 네임스페이스가 존재하면 엔드포인트는 대체 이름을 제안합니다.

```plaintext
GET /namespaces/:namespace/exists
```

| 속성   | 유형    | 필수 | 설명 |
| ----------- | ------- | -------- | ----------- |
| `namespace` | 문자열  | 예      | 네임스페이스의 경로입니다. |
| `parent_id` | 정수 | 아니요       | 상위 네임스페이스의 ID입니다. 지정되지 않으면 최상위 네임스페이스만 반환합니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces/my-group/exists?parent_id=1"
```

응답 예시:

```json
{
    "exists": true,
    "suggests": [
        "my-group1"
    ]
}
```
