---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 엔터프라이즈 사용자 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

이 API 엔드포인트를 사용하여 엔터프라이즈 사용자와 상호작용합니다. 자세한 내용은 [엔터프라이즈 사용자](../user/enterprise_user/_index.md)를 참조하세요.

이 API 엔드포인트는 최상위 그룹에만 작동합니다. 사용자는 그룹의 멤버일 필요가 없습니다.

전제 조건:

- 최상위 그룹에서 소유자 역할을 보유해야 합니다.

## 모든 엔터프라이즈 사용자 나열 {#list-all-enterprise-users}

{{< history >}}

- [GitLab 17.7에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/438366).

{{< /history >}}

지정된 최상위 그룹의 모든 엔터프라이즈 사용자를 나열합니다.

`page` 및 `per_page` [페이지 매김 매개변수](rest/_index.md#offset-based-pagination)를 사용하여 결과를 필터링합니다.

```plaintext
GET /groups/:id/enterprise_users
```

지원되는 속성:

| 속성        | 유형           | 필수 | 설명 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 정수 또는 문자열 | 예      | 최상위 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `username`       | 문자열         | 아니요       | 지정된 사용자명을 가진 사용자를 반환합니다. |
| `search`         | 문자열         | 아니요       | 일치하는 이름, 이메일 또는 사용자명을 가진 사용자를 반환합니다. 결과를 늘리려면 부분 값을 사용합니다. |
| `active`         | 부울        | 아니요       | 활성 사용자만 반환합니다. |
| `blocked`        | 부울        | 아니요       | 차단된 사용자만 반환합니다. |
| `created_after`  | 날짜/시간       | 아니요       | 지정된 시간 이후에 생성된 사용자를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `created_before` | 날짜/시간       | 아니요       | 지정된 시간 이전에 생성된 사용자를 반환합니다. 형식:  ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `two_factor`     | 문자열         | 아니요       | 2단계 인증 (2FA) 등록 상태에 따라 사용자를 반환합니다. 가능한 값: `enabled`, `disabled`. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/enterprise_users"
```

응답 예시:

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "Sidney Jones22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [
      {
        "provider": "group_saml",
        "extern_uid": "2435223452345",
        "saml_provider_id": 1
      }
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null,
    "scim_identities": [
      {
        "extern_uid": "2435223452345",
        "group_id": 1,
        "active": true
      }
    ]
  },
  ...
]
```

## 엔터프라이즈 사용자 검색 {#retrieve-an-enterprise-user}

{{< history >}}

- [GitLab 17.9에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176328).

{{< /history >}}

지정된 엔터프라이즈 사용자를 검색합니다.

```plaintext
GET /groups/:id/enterprise_users/:user_id
```

지원되는 속성:

| 속성        | 유형           | 필수 | 설명 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 정수 또는 문자열 | 예      | 최상위 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `user_id`        | 정수        | 예      | 사용자 계정의 ID. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id"
```

응답 예시:

```json
{
  "id": 66,
  "username": "user22",
  "name": "Sidney Jones22",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
  "web_url": "http://my.gitlab.com/user22",
  "created_at": "2021-09-10T12:48:22.381Z",
  "bio": "",
  "location": null,
  "public_email": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": null,
  "job_title": "",
  "pronouns": null,
  "bot": false,
  "work_information": null,
  "followers": 0,
  "following": 0,
  "local_time": null,
  "last_sign_in_at": null,
  "confirmed_at": "2021-09-10T12:48:22.330Z",
  "last_activity_on": null,
  "email": "user22@example.org",
  "theme_id": 1,
  "color_scheme_id": 1,
  "projects_limit": 100000,
  "current_sign_in_at": null,
  "identities": [
    {
      "provider": "group_saml",
      "extern_uid": "2435223452345",
      "saml_provider_id": 1
    }
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": false,
  "external": false,
  "private_profile": false,
  "commit_email": "user22@example.org",
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "scim_identities": [
    {
      "extern_uid": "2435223452345",
      "group_id": 1,
      "active": true
    }
  ]
}
```

## 엔터프라이즈 사용자 업데이트 {#update-an-enterprise-user}

{{< history >}}

- [GitLab 18.6에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199248).

{{< /history >}}

지정된 엔터프라이즈 사용자를 업데이트합니다.

```plaintext
PATCH /groups/:id/enterprise_users/:user_id
```

지원되는 속성:

| 속성        | 유형           | 필수 | 설명 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 정수 또는 문자열 | 예      | 최상위 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `user_id`        | 정수        | 예      | 사용자 계정의 ID. |
| `name`           | 문자열         | 아니요       | 사용자 계정의 이름. |
| `email`          | 문자열         | 아니요       | 사용자 계정의 이메일 주소. 검증된 [그룹 도메인](../user/enterprise_user/_index.md#manage-group-domains)에서만 사용해야 합니다. |

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "email=new-email@example.com" \
  --data "name=New name" \
  --url "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id"
```

성공하면 `200 OK`을 반환합니다.

성공한 응답 예:

```json
{
  "id": 66,
  "username": "user22",
  "name": "New name",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
  "web_url": "http://my.gitlab.com/user22",
  "created_at": "2021-09-10T12:48:22.381Z",
  "bio": "",
  "location": null,
  "public_email": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": null,
  "job_title": "",
  "pronouns": null,
  "bot": false,
  "work_information": null,
  "followers": 0,
  "following": 0,
  "local_time": null,
  "last_sign_in_at": null,
  "confirmed_at": "2021-09-10T12:48:22.330Z",
  "last_activity_on": null,
  "email": "new-email@example.com",
  "theme_id": 1,
  "color_scheme_id": 1,
  "projects_limit": 100000,
  "current_sign_in_at": null,
  "identities": [
    {
      "provider": "group_saml",
      "extern_uid": "2435223452345",
      "saml_provider_id": 1
    }
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": false,
  "external": false,
  "private_profile": false,
  "commit_email": "user22@example.org",
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "scim_identities": [
    {
      "extern_uid": "2435223452345",
      "group_id": 1,
      "active": true
    }
  ]
}
```

가능한 다른 응답:

- `400 Bad Request`:  유효성 검사 오류.
- `403 Forbidden`:  인증된 사용자가 소유자가 아닙니다.
- `404 Not found`:  사용자를 찾을 수 없습니다.

## 엔터프라이즈 사용자 삭제 {#delete-an-enterprise-user}

{{< history >}}

- [GitLab 18.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199646).

{{< /history >}}

지정된 엔터프라이즈 사용자를 삭제합니다.

```plaintext
DELETE /groups/:id/enterprise_users/:user_id
```

지원되는 속성:

| 속성     | 유형           | 필수 | 설명                                                                                                                                                                                                                                                                              |
|:--------------|:---------------|:---------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | 정수 또는 문자열 | 예      | 최상위 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths).                                                                                                                                                                                                          |
| `user_id`     | 정수        | 예      | 사용자 계정의 ID.                                                                                                                                                                                                                                                                      |
| `hard_delete` | 부울        | 아니요       | `false`이면 사용자를 삭제하고 그들의 기여도를 [유령 사용자로 이동](../user/profile/account/delete_account.md#associated-records)합니다. `true`이면 사용자, 관련 기여도 및 사용자가 단독으로 소유한 그룹을 삭제합니다. 기본값: `false`.  |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id"
```

성공하면 `204 No content`을 반환합니다.

가능한 다른 응답:

- `403 Forbidden`:  인증된 사용자가 소유자가 아닙니다.
- `404 Not found`:  사용자를 찾을 수 없습니다.
- `409 Conflict`:  그룹의 유일한 소유자인 사용자를 제거할 수 없습니다.

## 엔터프라이즈 사용자의 2단계 인증 비활성화 {#disable-two-factor-authentication-for-an-enterprise-user}

{{< history >}}

- [GitLab 17.9에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177943).

{{< /history >}}

지정된 엔터프라이즈 사용자의 2단계 인증 (2FA)를 비활성화합니다.

```plaintext
PATCH /groups/:id/enterprise_users/:user_id/disable_two_factor
```

지원되는 속성:

| 속성        | 유형           | 필수 | 설명 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 정수 또는 문자열 | 예      | 최상위 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `user_id`        | 정수        | 예      | 사용자 계정의 ID. |

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/enterprise_users/:user_id/disable_two_factor"
```

성공하면 `204 No content`을 반환합니다.

가능한 다른 응답:

- `400 Bad request`:  지정된 사용자에게 2FA가 활성화되지 않았습니다.
- `403 Forbidden`:  인증된 사용자가 소유자가 아닙니다.
- `404 Not found`:  사용자를 찾을 수 없습니다.
