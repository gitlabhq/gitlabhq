---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 멤버 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 엔드포인트를 사용하여 그룹 멤버와 상호 작용합니다.

프로젝트 멤버에 대한 정보는 [프로젝트 멤버 API](project_members.md)를 참조하세요.

## 알려진 이슈 {#known-issues}

- `group_saml_identity` 및 `group_scim_identity` 속성은 [SSO 지원 그룹](../user/group/saml_sso/_index.md)의 그룹 소유자에게만 표시됩니다.
- `email` 속성은 API 요청이 그룹 자체 또는 해당 그룹의 하위 그룹 또는 프로젝트로 전송될 때 그룹의 [엔터프라이즈 사용자](../user/enterprise_user/_index.md)에 대해서만 그룹 소유자에게 표시됩니다.

## 모든 그룹 멤버 나열 {#list-all-group-members}

지정된 그룹의 모든 직접 멤버를 나열합니다. 상위 그룹을 통해 상속된 멤버나 초대된 그룹의 멤버가 아닌 직접 멤버만 반환합니다.

이 함수는 범위를 제한하기 위해 `page` 및 `per_page` 페이지 분할 매개변수를 사용합니다.

```plaintext
GET /groups/:id/members
```

| 속성        | 유형              | 필수 | 설명 |
|------------------|-------------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `query`          | 문자열            | 아니요       | 지정된 이름, 이메일 또는 사용자 이름을 기준으로 결과를 필터링합니다. 부분 값을 사용하여 쿼리의 범위를 확대하세요. |
| `user_ids`       | 정수 배열 | 아니요       | 지정된 사용자 ID의 결과를 필터링합니다. |
| `skip_users`     | 정수 배열 | 아니요       | 결과에서 건너뛴 사용자를 필터링합니다. |
| `show_seat_info` | 부울           | 아니요       | 사용자의 사용자 정보를 표시합니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members"
```

응답 예시:

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "group_saml_identity": null,
    "is_using_seat": true
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 1,
      "username": "raymond_smith",
      "name": "Raymond Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "email": "john@example.com",
    "group_saml_identity": {
      "extern_uid":"ABC-1234567890",
      "provider": "group_saml",
      "saml_provider_id": 10
    }
  }
]
```

## 상속된 및 초대된 멤버를 포함한 모든 그룹 멤버 나열 {#list-all-group-members-including-inherited-and-invited-members}

{{< history >}}

- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) \- 현재 사용자가 GitLab 16.10의 공유 그룹 또는 프로젝트의 멤버인 경우 초대된 비공개 그룹의 멤버를 반환하도록 [플래그](../administration/feature_flags/_index.md) `webui_members_inherited_users` 포함 기본적으로 비활성화됨.
- 기능 플래그 `webui_members_inherited_users`는 GitLab 17.0에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)되었습니다.
- 기능 플래그 `webui_members_inherited_users`는 GitLab 17.4에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627)되었습니다. 초대된 그룹의 멤버는 기본적으로 표시됩니다.

{{< /history >}}

상속된 멤버, 초대된 사용자, 상위 그룹을 통한 권한을 포함하여 지정된 그룹의 모든 멤버를 나열합니다.

사용자가 이 그룹과 하나 이상의 상위 그룹의 멤버인 경우 가장 높은 `access_level`를 가진 멤버십만 반환됩니다. 이것은 사용자의 유효한 권한을 나타냅니다.

초대된 그룹의 멤버는 다음 중 하나인 경우 반환됩니다:

- 초대된 그룹은 공개입니다.
- 요청자가 초대된 그룹의 멤버이기도 합니다.
- 요청자가 공유 그룹의 멤버입니다.

> [!note]
> 초대된 그룹 멤버는 공유 그룹에서 공유 멤버십을 갖습니다. 이는 요청자가 공유 그룹의 멤버이지만 초대된 비공개 그룹의 멤버가 아닌 경우 이 엔드포인트를 사용하면 요청자는 초대된 비공개 그룹 멤버를 포함한 모든 공유 그룹 멤버를 얻을 수 있다는 의미입니다.

이 함수는 범위를 제한하기 위해 `page` 및 `per_page` 페이지 분할 매개변수를 사용합니다.

```plaintext
GET /groups/:id/members/all
```

| 속성        | 유형              | 필수 | 설명 |
|------------------|-------------------|----------|-------------|
| `id`             | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `query`          | 문자열            | 아니요       | 지정된 이름, 이메일 또는 사용자 이름을 기준으로 결과를 필터링합니다. 부분 값을 사용하여 쿼리의 범위를 확대하세요. |
| `user_ids`       | 정수 배열 | 아니요       | 지정된 사용자 ID의 결과를 필터링합니다. |
| `show_seat_info` | 부울           | 아니요       | 사용자의 사용자 정보를 표시합니다. |
| `state`          | 문자열            | 아니요       | `awaiting` 또는 `active` 중 하나인 멤버 상태로 결과를 필터링합니다. Premium 및 Ultimate만 해당합니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/all"
```

응답 예시:

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "group_saml_identity": null
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 1,
      "username": "raymond_smith",
      "name": "Raymond Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "email": "john@example.com",
    "group_saml_identity": {
      "extern_uid":"ABC-1234567890",
      "provider": "group_saml",
      "saml_provider_id": 10
    }
  },
  {
    "id": 3,
    "username": "foo_bar",
    "name": "Foo bar",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-10-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-11-22",
    "access_level": 30,
    "group_saml_identity": null
  }
]
```

## 그룹 멤버 검색 {#retrieve-a-group-member}

그룹의 지정된 멤버를 검색합니다. 상위 그룹을 통해 상속된 멤버가 아닌 직접 멤버만 반환합니다.

```plaintext
GET /groups/:id/members/:user_id
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id` | 정수           | 예      | 멤버의 사용자 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"
```

사용자 지정 역할을 그룹 멤버에서 제거하려면 빈 `member_role_id` 값을 전달합니다:

```shell
# Updates a group membership
curl --request PUT --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"member_role_id": null, "access_level": 10}' "https://gitlab.example.com/api/v4/groups/<group_id>/members/<user_id>"
```

응답 예시:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "access_level": 30,
  "email": "john@example.com",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": null,
  "group_saml_identity": null
}
```

## 상속된 및 초대된 멤버를 포함한 그룹 멤버 검색 {#retrieve-a-group-member-including-inherited-and-invited-members}

{{< history >}}

- GitLab 12.4에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17744).
- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) \- 현재 사용자가 GitLab 16.10의 공유 그룹 또는 프로젝트의 멤버인 경우 초대된 비공개 그룹의 멤버를 반환하도록 [플래그](../administration/feature_flags/_index.md) `webui_members_inherited_users` 포함 기본적으로 비활성화됨.
- GitLab 17.0에서 [GitLab.com 및 GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/219230).
- 기능 플래그 `webui_members_inherited_users`는 GitLab 17.4에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627)되었습니다. 초대된 그룹의 멤버는 기본적으로 표시됩니다.

{{< /history >}}

상위 그룹을 통해 상속되거나 초대된 멤버를 포함하여 그룹의 지정된 멤버를 검색합니다. 자세한 내용은 [모든 상속된 멤버 나열](#list-all-group-members-including-inherited-and-invited-members)을 참조하세요.

> [!note]
> 초대된 그룹 멤버는 공유 그룹에서 공유 멤버십을 갖습니다. 이는 요청자가 공유 그룹의 멤버이지만 초대된 비공개 그룹의 멤버가 아닌 경우 이 엔드포인트를 사용하면 요청자는 초대된 비공개 그룹 멤버를 포함한 모든 공유 그룹 멤버를 얻을 수 있다는 의미입니다.

```plaintext
GET /groups/:id/members/all/:user_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id` | 정수 | 예   | 멤버의 사용자 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/all/:user_id"
```

응답 예시:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "access_level": 30,
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "email": "john@example.com",
  "expires_at": null,
  "group_saml_identity": null
}
```

## 모든 청구 가능한 그룹 멤버 나열 {#list-all-billable-group-members}

지정된 그룹의 모든 청구 가능한 멤버를 나열합니다. 이 목록에는 하위 그룹 및 프로젝트의 멤버가 포함됩니다.

전제 조건:

- 청구 권한에 대한 API 엔드포인트에 액세스하려면 소유자 역할이 있어야 하며, [청구 권한](../user/free_user_limit.md)에 표시됩니다.
- 이 API 엔드포인트는 최상위 그룹에서만 작동합니다. 하위 그룹에서는 작동하지 않습니다.

이 함수는 [페이지 분할](rest/_index.md#pagination) `page` 및 `per_page` 매개변수를 사용하여 사용자 목록을 제한합니다.

`search` 매개변수를 사용하여 이름으로 청구 가능한 그룹 멤버를 검색하고 `sort`를 사용하여 결과를 정렬합니다.

```plaintext
GET /groups/:id/billable_members
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `search`  | 문자열            | 아니요       | 이름, 사용자 이름 또는 공개 이메일로 그룹 멤버를 검색할 쿼리 문자열입니다. |
| `sort`    | 문자열            | 아니요       | 정렬 속성과 순서를 지정하는 매개변수를 포함하는 쿼리 문자열입니다. 아래에서 지원되는 값을 참조하세요. |

`sort` 속성에 대해 지원되는 값은 다음과 같습니다:

| 값                   | 설명                  |
| ----------------------- | ---------------------------- |
| `access_level_asc`      | 액세스 수준, 오름차순      |
| `access_level_desc`     | 액세스 수준, 내림차순     |
| `last_joined`           | 마지막 가입                  |
| `name_asc`              | 이름, 오름차순              |
| `name_desc`             | 이름, 내림차순             |
| `oldest_joined`         | 가장 오래 가입                |
| `oldest_sign_in`        | 가장 오래 전 로그인               |
| `recent_sign_in`        | 최근 로그인               |
| `last_activity_on_asc`  | 마지막 활동 날짜, 오름차순  |
| `last_activity_on_desc` | 마지막 활동 날짜, 내림차순 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members"
```

응답 예시:

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "last_activity_on": "2021-01-27",
    "membership_type": "group_member",
    "removable": true,
    "created_at": "2021-01-03T12:16:02.000Z",
    "last_login_at": "2022-10-09T01:33:06.000Z"
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "email": "john@example.com",
    "last_activity_on": "2021-01-25",
    "membership_type": "group_member",
    "removable": true,
    "created_at": "2021-01-04T18:46:42.000Z",
    "last_login_at": "2022-09-29T22:18:46.000Z"
  },
  {
    "id": 3,
    "username": "foo_bar",
    "name": "Foo bar",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "last_activity_on": "2021-01-20",
    "membership_type": "group_invite",
    "removable": false,
    "created_at": "2021-01-09T07:12:31.000Z",
    "last_login_at": "2022-10-10T07:28:56.000Z"
  }
]
```

## 청구 가능한 그룹 멤버에 대한 모든 멤버십 나열 {#list-all-memberships-for-a-billable-group-member}

그룹의 지정된 청구 가능한 멤버에 대한 모든 멤버십을 나열합니다.

전제 조건:

- 응답은 직접 구성원만을 나타냅니다. 상속된 멤버십은 포함되지 않습니다.
- 이 API 엔드포인트는 최상위 그룹에서만 작동합니다. 하위 그룹에서는 작동하지 않습니다.
- 이 API 엔드포인트는 그룹의 멤버십을 관리할 수 있는 권한이 필요합니다.

사용자가 구성원인 모든 프로젝트 및 그룹을 나열합니다. 그룹 계층 구조의 프로젝트 및 그룹만 포함됩니다. 예를 들어 요청된 그룹이 `Top-Level Group`이고 요청된 사용자가 `Top-Level Group / Subgroup One` 및 `Other Group / Subgroup Two`의 직접 멤버인 경우 `Other Group / Subgroup Two`는 `Top-Level Group` 계층 구조에 없기 때문에 `Top-Level Group / Subgroup One`만 반환됩니다.

이 API 엔드포인트는 [페이지 분할](rest/_index.md#pagination) `page` 및 `per_page` 매개변수를 사용하여 멤버십 목록을 제한합니다.

```plaintext
GET /groups/:id/billable_members/:user_id/memberships
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id` | 정수           | 예      | 청구 가능한 멤버의 사용자 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id/memberships"
```

응답 예시:

```json
[
  {
    "id": 168,
    "source_id": 131,
    "source_full_name": "Top-Level Group / Subgroup One",
    "source_members_url": "https://gitlab.example.com/groups/root-group/sub-group-one/-/group_members",
    "created_at": "2021-03-31T17:28:44.812Z",
    "expires_at": "2022-03-21",
    "access_level": {
      "string_value": "Developer",
      "integer_value": 30
    }
  },
  {
    "id": 169,
    "source_id": 63,
    "source_full_name": "Top-Level Group / Subgroup One / My Project",
    "source_members_url": "https://gitlab.example.com/root-group/sub-group-one/my-project/-/project_members",
    "created_at": "2021-03-31T17:29:14.934Z",
    "expires_at": null,
    "access_level": {
      "string_value": "Maintainer",
      "integer_value": 40
    }
  }
]
```

## 청구 가능한 그룹 멤버에 대한 모든 간접 멤버십 나열 {#list-all-indirect-memberships-for-a-billable-group-member}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- [GitLab 16.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/386583)됨.

{{< /history >}}

그룹의 청구 가능한 멤버에 대한 간접 멤버십 목록을 가져옵니다.

전제 조건:

- 이 API 엔드포인트는 최상위 그룹에서만 작동합니다. 하위 그룹에서는 작동하지 않습니다.
- 이 API 엔드포인트는 그룹의 멤버십을 관리할 수 있는 권한이 필요합니다.

요청된 최상위 그룹에 초대된 사용자가 멤버인 모든 프로젝트 및 그룹을 나열합니다. 예를 들어 요청된 그룹이 `Top-Level Group`이고 요청된 사용자가 `Top-Level Group`에 초대된 `Other Group / Subgroup Two`의 직접 멤버인 경우 `Other Group / Subgroup Two`만 반환됩니다.

응답은 간접 멤버십만 나열합니다. 직접 멤버십은 포함되지 않습니다.

이 API 엔드포인트는 [페이지 분할](rest/_index.md#pagination) `page` 및 `per_page` 매개변수를 사용하여 멤버십 목록을 제한합니다.

```plaintext
GET /groups/:id/billable_members/:user_id/indirect
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id` | 정수           | 예      | 청구 가능한 멤버의 사용자 ID입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id/indirect"
```

응답 예시:

```json
[
  {
    "id": 168,
    "source_id": 132,
    "source_full_name": "Invited Group / Subgroup One",
    "source_members_url": "https://gitlab.example.com/groups/invited-group/sub-group-one/-/group_members",
    "created_at": "2021-03-31T17:28:44.812Z",
    "expires_at": "2022-03-21",
    "access_level": {
      "string_value": "Developer",
      "integer_value": 30
    }
  }
]
```

## 청구 가능한 그룹 멤버 제거 {#remove-a-billable-group-member}

지정된 청구 가능한 멤버를 그룹 및 해당 하위 그룹 및 프로젝트에서 제거합니다.

사용자가 제거 대상이 되려면 그룹 멤버가 아니어도 됩니다. 예를 들어 사용자가 그룹의 프로젝트에 직접 추가되었으면 이 API 엔드포인트를 사용하여 제거할 수 있습니다.

> [!note]
> 멤버 제거는 비동기적으로 처리되므로 변경 사항이 몇 분 안에 완료됩니다.

```plaintext
DELETE /groups/:id/billable_members/:user_id
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id` | 정수           | 예      | 멤버의 사용자 ID입니다. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id"
```

## 사용자의 그룹 멤버십 상태 변경 {#change-group-membership-state-for-a-user}

그룹의 지정된 사용자에 대한 멤버십 상태를 변경합니다.

사용자가 [무료 사용자 제한](../user/free_user_limit.md)을 초과한 경우 그룹 또는 프로젝트에 대한 멤버십 상태를 `awaiting` 또는 `active`로 변경하면 해당 그룹 또는 프로젝트에 액세스할 수 있습니다. 변경 사항은 모든 하위 그룹 및 프로젝트에 적용됩니다.

```plaintext
PUT /groups/:id/members/:user_id/state
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id` | 정수           | 예      | 멤버의 사용자 ID입니다. |
| `state`   | 문자열            | 예      | 사용자의 새로운 상태입니다. 상태는 `awaiting` 또는 `active` 중 하나입니다. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/state?state=active"
```

응답 예시:

```json
{
  "success":true
}
```

## 그룹 멤버 추가 {#add-a-group-member}

지정된 그룹에 멤버를 추가합니다.

```plaintext
POST /groups/:id/members
```

| 속성        | 유형              | 필수                           | 설명 |
| ---------------- | ----------------- | ---------------------------------- | ----------- |
| `id`             | 정수 또는 문자열 | 예                                | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id`        | 정수 또는 문자열 | `username`이 제공되지 않은 경우 예 | 새 멤버의 사용자 ID 또는 쉼표로 구분된 여러 ID입니다. |
| `username`       | 문자열            | `user_id`이 제공되지 않은 경우 예  | 새 멤버의 사용자 이름 또는 쉼표로 구분된 여러 사용자 이름입니다. |
| `access_level`   | 정수           | 예                                | 유효한 [액세스 수준](../user/permissions.md#default-roles) 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자), `50` (소유자). 기본값: `30`. |
| `expires_at`     | 문자열            | 아니요                                 | `YEAR-MONTH-DAY` 형식의 날짜 문자열입니다. |
| `invite_source`  | 문자열            | 아니요                                 | 멤버 생성 프로세스를 시작하는 초대의 출처입니다. GitLab 팀 멤버는 이 기밀 이슈에서 자세한 정보를 볼 수 있습니다: `https://gitlab.com/gitlab-org/gitlab/-/issues/327120>`. |
| `member_role_id` | 정수           | 아니요                                 | Ultimate만 해당. 사용자 지정 역할의 ID입니다. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
```

응답 예시:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 30,
  "email": "john@example.com",
  "group_saml_identity": null
}
```

> [!note]
> [역할 승격을 위한 관리자 승인](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)이 활성화된 경우 기존 사용자를 청구 가능 역할로 승격하는 멤버십 요청에는 관리자 승인이 필요합니다.

**Manage Non-Billable Promotions**를 활성화하려면 먼저 `enable_member_promotion_management` 애플리케이션 설정을 활성화해야 합니다.

단일 사용자를 대기 중으로 설정하는 예:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
```

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

여러 사용자를 대기 중으로 설정하는 예:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1,2&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1,2&access_level=30" "https://gitlab.example.com/api/v4/projects/:id/members"
```

```json
{
  "queued_users": {
    "username_1": "Request queued for administrator approval.",
    "username_2": "Request queued for administrator approval."
  },
  "status": "success"
}
```

## 그룹 멤버 업데이트 {#update-a-group-member}

그룹의 지정된 멤버를 업데이트합니다.

```plaintext
PUT /groups/:id/members/:user_id
```

| 속성        | 유형              | 필수 | 설명 |
| ---------------- | ----------------- | -------- | ----------- |
| `id`             | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id`        | 정수           | 예      | 멤버의 사용자 ID입니다. |
| `access_level`   | 정수           | 예       | 유효한 [액세스 수준](../user/permissions.md#default-roles) 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자), `50` (소유자), `60` (관리자). 기본값: `30`. |
| `expires_at`     | 문자열            | 아니요       | `YEAR-MONTH-DAY` 형식의 날짜 문자열입니다. |
| `member_role_id` | 정수           | 아니요       | Ultimate만 해당. 사용자 지정 역할의 ID입니다. 값을 지정하지 않으면 모든 역할이 제거됩니다. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id?access_level=40"
```

응답 예시:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "group_saml_identity": null
}
```

> [!note]
> [역할 승격을 위한 관리자 승인](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)이 활성화된 경우 기존 사용자를 청구 가능 역할로 승격하는 멤버십 요청에는 관리자 승인이 필요합니다.

**Manage non-billable promotions**를 활성화하려면 먼저 `enable_member_promotion_management` 애플리케이션 설정을 활성화해야 합니다.

응답 예시:

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

### 그룹 멤버에 대한 재정의 플래그 설정 {#set-override-flag-for-a-member-of-a-group}

기본적으로 LDAP 그룹 멤버의 액세스 수준은 LDAP을 통해 지정된 값으로 설정됩니다. 이 엔드포인트를 호출하여 액세스 수준 재정의를 허용할 수 있습니다.

```plaintext
POST /groups/:id/members/:user_id/override
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id` | 정수           | 예      | 멤버의 사용자 ID입니다. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
```

응답 예시:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "override": true
}
```

### 그룹 멤버에 대한 재정의 제거 {#remove-override-for-a-member-of-a-group}

재정의 플래그를 거짓으로 설정하고 LDAP 그룹 동기화가 액세스 수준을 LDAP에서 규정한 값으로 재설정하도록 허용합니다.

```plaintext
DELETE /groups/:id/members/:user_id/override
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id` | 정수           | 예      | 멤버의 사용자 ID입니다. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
```

응답 예시:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "override": false
}
```

## 그룹 멤버 제거 {#remove-a-group-member}

역할이 명시적으로 할당된 그룹에서 지정된 사용자를 제거합니다.

사용자가 제거 대상이 되려면 그룹 멤버가 되어야 합니다. 예를 들어 사용자가 그룹의 프로젝트에 직접 추가되었지만 이 그룹에 명시적으로 추가되지 않은 경우 이 API 엔드포인트를 사용하여 제거할 수 없습니다. 대안은 [그룹에서 청구 가능한 멤버 제거](#remove-a-billable-group-member)를 참조하세요.

```plaintext
DELETE /groups/:id/members/:user_id
```

| 속성            | 유형              | 필수 | 설명 |
|----------------------|-------------------|----------|-------------|
| `id`                 | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id`            | 정수           | 예      | 멤버의 사용자 ID입니다. |
| `skip_subresources`  | 부울           | 거짓    | 하위 그룹 및 프로젝트에서 제거된 멤버의 직접 멤버십 삭제를 건너뛸지 여부입니다. 기본값은 `false`입니다. |
| `unassign_issuables` | 부울           | 거짓    | 제거된 멤버를 특정 그룹 또는 프로젝트 내의 이슈 또는 머지 리퀘스트에서 할당 해제할지 여부입니다. 기본값은 `false`입니다. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

## 그룹 멤버 승인 {#approve-a-group-member}

그룹 및 해당 하위 그룹 및 프로젝트에 대해 지정된 보류 중인 사용자를 승인합니다.

```plaintext
PUT /groups/:id/members/:member_id/approve
```

| 속성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 최상위 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `member_id` | 정수           | 예      | 멤버의 ID입니다. |

요청 예시:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:member_id/approve"
```

## 모든 보류 중인 그룹 멤버 승인 {#approve-all-pending-group-members}

그룹 및 해당 하위 그룹 및 프로젝트에 대해 모든 보류 중인 사용자를 승인합니다.

```plaintext
POST /groups/:id/members/approve_all
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 최상위 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/approve_all"
```

## 그룹 및 해당 하위 그룹 및 프로젝트의 모든 보류 중인 그룹 멤버 나열 {#list-all-pending-group-members-in-a-group-and-its-subgroups-and-projects}

지정된 그룹 및 해당 하위 그룹 및 프로젝트에 대해 `awaiting` 상태의 모든 멤버 및 GitLab 계정이 없지만 초대된 사용자를 나열합니다.

전제 조건:

- 이 API 엔드포인트는 최상위 그룹에서만 작동합니다. 하위 그룹에서는 작동하지 않습니다.
- 이 API 엔드포인트는 그룹의 멤버를 관리할 수 있는 권한이 필요합니다.

이 요청은 최상위 그룹의 계층 구조에 있는 모든 그룹 및 프로젝트의 일치하는 모든 그룹 및 프로젝트 멤버를 반환합니다.

멤버가 아직 GitLab 계정에 가입하지 않은 초대된 사용자인 경우 초대된 이메일 주소가 반환됩니다.

이 API 엔드포인트는 [페이지 분할](rest/_index.md#pagination) `page` 및 `per_page` 매개변수를 사용하여 멤버 목록을 제한합니다.

```plaintext
GET /groups/:id/pending_members
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/pending_members"
```

응답 예시:

```json
[
  {
    "id": 168,
    "name": "Alex Garcia",
    "username": "alex_garcia",
    "email": "alex@example.com",
    "avatar_url": "http://example.com/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://example.com/alex_garcia",
    "approved": false,
    "invited": false
  },
  {
    "id": 169,
    "email": "sidney@example.com",
    "avatar_url": "http://gravatar.com/../e346561cd8.jpeg",
    "approved": false,
    "invited": true
  },
  {
    "id": 170,
    "email": "zhang@example.com",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "approved": true,
    "invited": true
  }
]
```
