---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 API
description: "GitLab 사용자 API는 사용자 계정을 생성, 수정, 검색 및 삭제할 수 있습니다. 또한 관리자 작업 및 SCIM 프로비저닝을 지원합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab의 사용자 계정과 상호작용합니다. 이 엔드포인트는 [사용자 계정](../user/profile/_index.md) 또는 [다른 사용자의 계정](../administration/administer_users.md)을 관리하는 데 도움이 됩니다.

## 모든 사용자 나열 {#list-all-users}

모든 사용자를 나열합니다.

[페이지 매김 매개변수](rest/_index.md#offset-based-pagination) `page` 및 `per_page`를 사용하여 사용자 목록을 제한합니다.

### 일반 사용자로서 {#as-a-regular-user}

{{< history >}}

- 키셋 페이지 매김이 GitLab 16.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/419556)되었습니다.
- `saml_provider_id` 속성이 GitLab 18.2에서 제거되었습니다.

{{< /history >}}

```plaintext
GET /users
```

지원되는 속성:

| 속성              | 유형     | 필수 | 설명 |
|:-----------------------|:---------|:---------|:------------|
| `username`             | 문자열   | 아니요       | 특정 사용자명을 가진 단일 사용자를 가져옵니다. |
| `public_email`         | 문자열   | 아니요       | 특정 공개 이메일을 가진 단일 사용자를 가져옵니다. |
| `search`               | 문자열   | 아니요       | 이름, 사용자명 또는 공개 이메일로 사용자를 검색합니다. |
| `active`               | 부울  | 아니요       | 활성 사용자만 필터링합니다. 기본값은 `false`입니다. |
| `external`             | 부울  | 아니요       | 외부 사용자만 필터링합니다. 기본값은 `false`입니다. |
| `blocked`              | 부울  | 아니요       | 차단된 사용자만 필터링합니다. 기본값은 `false`입니다. |
| `humans`               | 부울  | 아니요       | 봇 또는 내부 사용자가 아닌 일반 사용자만 필터링합니다. 기본값은 `false`입니다. |
| `created_after`        | DateTime | 아니요       | 지정된 시간 이후에 생성된 사용자를 반환합니다. |
| `created_before`       | DateTime | 아니요       | 지정된 시간 이전에 생성된 사용자를 반환합니다. |
| `exclude_active`       | 부울  | 아니요       | 활성이 아닌 사용자만 필터링합니다. 기본값은 `false`입니다. |
| `exclude_external`     | 부울  | 아니요       | 외부가 아닌 사용자만 필터링합니다. 기본값은 `false`입니다. |
| `exclude_humans`       | 부울  | 아니요       | 봇 또는 내부 사용자만 필터링합니다. 기본값은 `false`입니다. |
| `exclude_internal`     | 부울  | 아니요       | 내부가 아닌 사용자만 필터링합니다. 기본값은 `false`입니다. |
| `without_project_bots` | 부울  | 아니요       | 프로젝트 봇이 없는 사용자를 필터링합니다. 기본값은 `false`입니다. |

응답 예시:

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "locked": false,
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

이 엔드포인트는 [키셋 페이지 매김](rest/_index.md#keyset-based-pagination)을 지원합니다. GitLab 17.0 이상에서는 50,000 개 이상의 응답에 대해 키셋 페이지 매김이 필요합니다.

`?search=`을 사용하여 이름, 사용자명 또는 공개 이메일로 사용자를 검색할 수 있습니다. 예를 들어, `/users?search=John`입니다. 다음을 검색할 때:

- 공개 이메일의 경우 정확히 일치하려면 전체 이메일 주소를 사용해야 합니다.
- 이름 또는 사용자명의 경우 이것이 퍼지 검색이므로 정확히 일치할 필요가 없습니다.

또한 사용자명으로 사용자를 조회할 수 있습니다:

```plaintext
GET /users?username=:username
```

예를 들어:

```plaintext
GET /users?username=jack_smith
```

> [!note]
> 사용자명 검색은 대소문자를 구분하지 않습니다.

또한 `blocked` 및 `active` 상태를 기반으로 사용자를 필터링할 수 있습니다. `active=false` 또는 `blocked=false`를 지원하지 않습니다.

```plaintext
GET /users?active=true
```

```plaintext
GET /users?blocked=true
```

`external=true`을 사용하여 외부 사용자만 검색할 수 있습니다. `external=false`를 지원하지 않습니다.

```plaintext
GET /users?external=true
```

GitLab은 [알림 봇](../operations/incident_management/integrations.md) 또는 [지원 봇](../user/project/service_desk/configure.md#support-bot-user)과 같은 봇 사용자를 지원합니다. 다음 유형의 [내부 사용자](../administration/internal_users.md)를 `exclude_internal=true` 매개변수로 사용자 목록에서 제외할 수 있습니다:

- 알림 봇
- 지원 봇

그러나 이 작업은 [프로젝트용 봇 사용자](../user/project/settings/project_access_tokens.md#bot-users-for-projects) 또는 [그룹용 봇 사용자](../user/group/settings/group_access_tokens.md#bot-users-for-groups)를 제외하지 않습니다.

```plaintext
GET /users?exclude_internal=true
```

또한 사용자 목록에서 외부 사용자를 제외하려면 `exclude_external=true` 매개변수를 사용할 수 있습니다.

```plaintext
GET /users?exclude_external=true
```

[프로젝트용 봇 사용자](../user/project/settings/project_access_tokens.md#bot-users-for-projects) 및 [그룹용 봇 사용자](../user/group/settings/group_access_tokens.md#bot-users-for-groups)를 제외하려면 `without_project_bots=true` 매개변수를 사용할 수 있습니다.

```plaintext
GET /users?without_project_bots=true
```

### 관리자로서 {#as-an-administrator}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `created_by` 필드는 GitLab 15.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092)되었습니다.
- `scim_identities` 필드는 GitLab 16.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/324247)되었습니다.
- `auditors` 필드는 GitLab 16.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418023)되었습니다.
- `email_reset_offered_at` 필드는 GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610)되었습니다.
- `email_reset_offered_at` 필드는 GitLab 18.3에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197491)되었습니다.

{{< /history >}}

```plaintext
GET /users
```

[모든 사용자가 사용 가능한 매개변수](#as-a-regular-user)와 관리자만 사용 가능한 이러한 추가 속성을 사용할 수 있습니다.

지원되는 속성:

| 속성          | 유형    | 필수 | 설명 |
|:-------------------|:--------|:---------|:------------|
| `search`           | 문자열  | 아니요       | 이름, 사용자명, 공개 이메일 또는 비공개 이메일로 사용자를 검색합니다. |
| `extern_uid`       | 문자열  | 아니요       | 특정 외부 인증 공급자 UID를 가진 단일 사용자를 가져옵니다. |
| `provider`         | 문자열  | 아니요       | 외부 공급자입니다. |
| `order_by`         | 문자열  | 아니요       | `id`, `name`, `username`, `created_at` 또는 `updated_at` 필드로 정렬된 사용자를 반환합니다. 기본값은 `id`입니다 |
| `sort`             | 문자열  | 아니요       | `asc` 또는 `desc` 순서로 정렬된 사용자를 반환합니다. 기본값은 `desc`입니다 |
| `two_factor`       | 문자열  | 아니요       | 2단계 인증으로 사용자를 필터링합니다. 필터 값은 `enabled` 또는 `disabled`입니다. 기본적으로 모든 사용자를 반환합니다 |
| `without_projects` | 부울 | 아니요       | 프로젝트가 없는 사용자를 필터링합니다. 기본값은 `false`이며, 이는 프로젝트가 있거나 없는 모든 사용자가 반환됨을 의미합니다. |
| `admins`           | 부울 | 아니요       | 관리자만 반환합니다. 기본값은 `false`입니다 |
| `auditors`         | 부울 | 아니요       | 감사 사용자만 반환합니다. 기본값은 `false`입니다. 포함되지 않은 경우 모든 사용자를 반환합니다. Premium 및 Ultimate만 해당합니다. |
| `skip_ldap`        | 부울 | 아니요       | LDAP 사용자를 건너뜁니다. Premium 및 Ultimate만 해당합니다. |

응답 예시:

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
    "web_url": "http://localhost:3000/john_smith",
    "created_at": "2012-05-23T08:00:58Z",
    "is_admin": false,
    "bio": "",
    "location": null,
    "linkedin": "",
    "twitter": "",
    "discord": "",
    "github": "",
    "website_url": "",
    "organization": "",
    "job_title": "",
    "last_sign_in_at": "2012-06-01T11:41:01Z",
    "confirmed_at": "2012-05-23T09:05:22Z",
    "theme_id": 1,
    "last_activity_on": "2012-05-23",
    "color_scheme_id": 2,
    "projects_limit": 100,
    "current_sign_in_at": "2012-06-02T06:36:55Z",
    "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
    "identities": [
      {"provider": "github", "extern_uid": "2435223452345"},
      {"provider": "bitbucket", "extern_uid": "john.smith"},
      {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": true,
    "external": false,
    "private_profile": false,
    "current_sign_in_ip": "196.165.1.102",
    "last_sign_in_ip": "172.127.2.22",
    "namespace_id": 1,
    "created_by": null
  },
  {
    "id": 2,
    "username": "jack_smith",
    "email": "jack@example.com",
    "name": "Jack Smith",
    "state": "blocked",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/2/index.jpg",
    "web_url": "http://localhost:3000/jack_smith",
    "created_at": "2012-05-23T08:01:01Z",
    "is_admin": false,
    "bio": "",
    "location": null,
    "linkedin": "",
    "twitter": "",
    "discord": "",
    "github": "",
    "website_url": "",
    "organization": "",
    "job_title": "",
    "last_sign_in_at": null,
    "confirmed_at": "2012-05-30T16:53:06.148Z",
    "theme_id": 1,
    "last_activity_on": "2012-05-23",
    "color_scheme_id": 3,
    "projects_limit": 100,
    "current_sign_in_at": "2014-03-19T17:54:13Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": true,
    "external": false,
    "private_profile": false,
    "current_sign_in_ip": "10.165.1.102",
    "last_sign_in_ip": "172.127.2.22",
    "namespace_id": 2,
    "created_by": null
  }
]
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/)의 사용자도 `shared_runners_minutes_limit`, `extra_shared_runners_minutes_limit`, `is_auditor` 및 `using_license_seat` 매개변수를 봅니다.

```json
[
  {
    "id": 1,
    ...
    "shared_runners_minutes_limit": 133,
    "extra_shared_runners_minutes_limit": 133,
    "is_auditor": false,
    "using_license_seat": true
    ...
  }
]
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/)의 사용자도 `group_saml` 공급자 옵션 및 `provisioned_by_group_id` 매개변수를 봅니다:

```json
[
  {
    "id": 1,
    ...
    "identities": [
      {"provider": "github", "extern_uid": "2435223452345"},
      {"provider": "bitbucket", "extern_uid": "john.smith"},
      {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"},
      {"provider": "group_saml", "extern_uid": "123789", "saml_provider_id": 10}
    ],
    "provisioned_by_group_id": 123789
    ...
  }
]
```

`?search=`을 사용하여 이름, 사용자명 또는 이메일로 사용자를 검색할 수 있습니다. 예를 들어, `/users?search=John`입니다. 다음을 검색할 때:

- 이메일의 경우 정확히 일치하려면 전체 이메일 주소를 사용해야 합니다. 관리자는 공개 및 비공개 이메일 주소를 모두 검색할 수 있습니다.
- 이름 또는 사용자명의 경우 이것이 퍼지 검색이므로 정확히 일치할 필요가 없습니다.

외부 UID 및 공급자로 사용자를 조회할 수 있습니다:

```plaintext
GET /users?extern_uid=:extern_uid&provider=:provider
```

예를 들어:

```plaintext
GET /users?extern_uid=1234567&provider=github
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/)의 사용자는 `scim` 공급자를 사용할 수 있습니다:

```plaintext
GET /users?extern_uid=1234567&provider=scim
```

생성 날짜 시간 범위로 사용자를 검색할 수 있습니다:

```plaintext
GET /users?created_before=2001-01-02T00:00:00.060Z&created_after=1999-01-02T00:00:00.060
```

프로젝트가 없는 사용자를 검색할 수 있습니다: `/users?without_projects=true`

[사용자 정의 속성](custom_attributes.md)으로 필터링할 수 있습니다:

```plaintext
GET /users?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

응답에 사용자의 [사용자 정의 속성](custom_attributes.md)을 포함할 수 있습니다:

```plaintext
GET /users?with_custom_attributes=true
```

`created_by` 매개변수를 사용하여 사용자 계정이 생성되었는지 확인할 수 있습니다:

- [관리자가 수동으로](../user/profile/account/create_accounts.md#create-a-user-in-the-admin-area) 생성했습니다.
- [프로젝트 봇 사용자](../user/project/settings/project_access_tokens.md#bot-users-for-projects)로 생성했습니다.

반환된 값이 `null`이면 계정은 자신을 등록한 사용자가 생성했습니다.

## 단일 사용자 검색 {#retrieve-a-single-user}

단일 사용자를 검색합니다.

### 일반 사용자로서 단일 사용자 검색 {#retrieve-a-single-user-as-a-regular-user}

일반 사용자로서 단일 사용자를 검색합니다.

전제 조건:

- 이 엔드포인트를 사용하려면 로그인해야 합니다.

```plaintext
GET /users/:id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자의 ID |

응답 예시:

```json
{
  "id": 1,
  "username": "john_smith",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "bio": "",
  "bot": false,
  "location": null,
  "public_email": "john@example.com",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "github": "",
  "website_url": "",
  "organization": "",
  "job_title": "Operations Specialist",
  "pronouns": "he/him",
  "work_information": null,
  "followers": 1,
  "following": 1,
  "local_time": "3:38 PM",
  "is_followed": false
}
```

### 관리자로서 {#as-an-administrator-1}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `created_by` 필드는 GitLab 15.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092)되었습니다.
- `email_reset_offered_at` 필드는 GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610)되었습니다.
- `email_reset_offered_at` 필드는 GitLab 18.3에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197491)되었습니다.

{{< /history >}}

관리자로서 단일 사용자를 검색합니다.

```plaintext
GET /users/:id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자의 ID |

응답 예시:

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": false,
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "github": "",
  "website_url": "",
  "organization": "",
  "job_title": "Operations Specialist",
  "pronouns": "he/him",
  "work_information": null,
  "followers": 1,
  "following": 1,
  "local_time": "3:38 PM",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "last_activity_on": "2012-05-23",
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john.smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false,
  "private_profile": false,
  "commit_email": "john-codes@example.com",
  "current_sign_in_ip": "196.165.1.102",
  "last_sign_in_ip": "172.127.2.22",
  "plan": "gold",
  "trial": true,
  "sign_in_count": 1337,
  "namespace_id": 1,
  "created_by": null
}
```

> [!note]
> `plan` 및 `trial` 매개변수는 GitLab Enterprise Edition에서만 사용할 수 있습니다.

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/)의 사용자도 `shared_runners_minutes_limit`, `is_auditor` 및 `extra_shared_runners_minutes_limit` 매개변수를 봅니다.

```json
{
  "id": 1,
  "username": "john_smith",
  "is_auditor": false,
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  ...
}
```

[GitLab.com Premium 또는 Ultimate](https://about.gitlab.com/pricing/)의 사용자도 `group_saml` 옵션 및 `provisioned_by_group_id` 매개변수를 봅니다:

```json
{
  "id": 1,
  "username": "john_smith",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john.smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"},
    {"provider": "group_saml", "extern_uid": "123789", "saml_provider_id": 10}
  ],
  "provisioned_by_group_id": 123789
  ...
}
```

[GitLab.com Premium 또는 Ultimate](https://about.gitlab.com/pricing/)의 사용자도 `scim_identities` 매개변수를 봅니다:

```json
{
  ...
  "extra_shared_runners_minutes_limit": null,
  "scim_identities": [
      {"extern_uid": "2435223452345", "group_id": "3", "active": true},
      {"extern_uid": "john.smith", "group_id": "42", "active": false}
    ]
  ...
}
```

관리자는 `created_by` 매개변수를 사용하여 사용자 계정이 생성되었는지 확인할 수 있습니다:

- [관리자가 수동으로](../user/profile/account/create_accounts.md#create-a-user-in-the-admin-area) 생성했습니다.
- [프로젝트 봇 사용자](../user/project/settings/project_access_tokens.md#bot-users-for-projects)로 생성했습니다.

반환된 값이 `null`이면 계정은 자신을 등록한 사용자가 생성했습니다.

응답에 사용자의 [사용자 정의 속성](custom_attributes.md)을 포함할 수 있습니다:

```plaintext
GET /users/:id?with_custom_attributes=true
```

## 현재 사용자 검색 {#retrieve-the-current-user}

현재 사용자를 검색합니다.

### 일반 사용자로서 {#as-a-regular-user-1}

사용자의 세부 정보를 검색합니다.

```plaintext
GET /user
```

응답 예시:

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "github": "",
  "website_url": "",
  "organization": "",
  "job_title": "",
  "pronouns": "he/him",
  "bot": false,
  "work_information": null,
  "followers": 0,
  "following": 0,
  "local_time": "3:38 PM",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "last_activity_on": "2012-05-23",
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john_smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false,
  "private_profile": false,
  "commit_email": "admin@example.com",
  "preferred_language": "en",
}
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/)의 사용자도 `shared_runners_minutes_limit`, `extra_shared_runners_minutes_limit` 매개변수를 봅니다.

### 관리자로서 {#as-an-administrator-2}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `created_by` 필드는 GitLab 15.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092)되었습니다.
- `email_reset_offered_at` 필드는 GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610)되었습니다.
- `email_reset_offered_at` 필드는 GitLab 18.3에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197491)되었습니다.

{{< /history >}}

사용자의 세부 정보를 검색하거나 다른 사용자의 세부 정보를 검색합니다.

```plaintext
GET /user
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `sudo`    | 정수 | 아니요       | 대신 호출하려는 사용자의 ID |

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": true,
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "github": "",
  "website_url": "",
  "organization": "",
  "job_title": "",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "last_activity_on": "2012-05-23",
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john_smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false,
  "private_profile": false,
  "commit_email": "john-codes@example.com",
  "current_sign_in_ip": "196.165.1.102",
  "last_sign_in_ip": "172.127.2.22",
  "namespace_id": 1,
  "created_by": null,
  "note": null
}
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/)의 사용자도 다음 매개변수를 봅니다:

- `shared_runners_minutes_limit`
- `extra_shared_runners_minutes_limit`
- `is_auditor`
- `provisioned_by_group_id`
- `using_license_seat`

## 사용자 생성 {#create-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 감사 사용자를 생성할 수 있는 기능이 GitLab 15.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/366404)되었습니다.

{{< /history >}}

사용자를 생성합니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

> [!note]
> `private_profile`는 [새 사용자의 프로필을 기본적으로 비공개로 설정](../administration/settings/account_and_limit_settings.md#set-profiles-of-new-users-to-private-by-default) 설정의 값으로 기본값이 설정됩니다. `bio`는 `""` 대신 `null`으로 기본값이 설정됩니다.

```plaintext
POST /users
```

지원되는 속성:

| 속성                            | 필수 | 설명 |
|:-------------------------------------|:---------|:------------|
| `username`                           | 예      | 사용자의 사용자명    |
| `name`                               | 예      | 사용자의 이름        |
| `email`                              | 예      | 사용자의 이메일       |
| `password`                           | 조건부 | 사용자의 암호입니다. `force_random_password` 또는 `reset_password`이 정의되지 않은 경우 필수입니다. `force_random_password` 또는 `reset_password` 중 하나가 정의된 경우 해당 설정이 우선합니다. |
| `admin`                              | 아니요       | 사용자가 관리자입니다. 유효한 값은 `true` 또는 `false`입니다. 기본값은 false입니다. |
| `auditor`                            | 아니요       | 사용자가 감사자입니다. 유효한 값은 `true` 또는 `false`입니다. 기본값은 false입니다. GitLab 15.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/366404)되었습니다. Premium 및 Ultimate만 해당합니다. |
| `avatar`                             | 아니요       | 사용자 아바타용 이미지 파일 |
| `bio`                                | 아니요       | 사용자의 생활 정보 |
| `can_create_group`                   | 아니요       | 사용자가 최상위 그룹을 생성할 수 있습니다 - true 또는 false |
| `color_scheme_id`                    | 아니요       | 파일 뷰어의 사용자 색상 체계(자세한 내용은 [사용자 선호도 설명서](../user/profile/preferences.md#change-the-syntax-highlighting-theme) 참조) |
| `commit_email`                       | 아니요       | 사용자의 커밋 이메일 주소 |
| `extern_uid`                         | 아니요       | 외부 UID |
| `external`                           | 아니요       | 사용자를 외부로 표시합니다 - true 또는 false (기본값) |
| `extra_shared_runners_minutes_limit` | 아니요       | 관리자만 설정할 수 있습니다. 이 사용자를 위한 추가 컴퓨팅 분입니다. Premium 및 Ultimate만 해당합니다. |
| `force_random_password`              | 아니요       | `true`인 경우 사용자 암호를 임의의 값으로 설정합니다. `reset_password`와 함께 사용할 수 있습니다. `password`보다 우선합니다. |
| `group_id_for_saml`                  | 아니요       | SAML이 구성된 그룹의 ID |
| `linkedin`                           | 아니요       | LinkedIn    |
| `location`                           | 아니요       | 사용자의 위치 |
| `note`                               | 아니요       | 이 사용자에 대한 관리자 메모 |
| `organization`                       | 아니요       | 조직 이름 |
| `private_profile`                    | 아니요       | 사용자의 프로필이 비공개입니다 - true 또는 false입니다. 기본값은 [설정](../administration/settings/account_and_limit_settings.md#set-profiles-of-new-users-to-private-by-default)에 의해 결정됩니다. |
| `projects_limit`                     | 아니요       | 사용자가 생성할 수 있는 프로젝트 수 |
| `pronouns`                           | 아니요       | 사용자의 대명사 |
| `provider`                           | 아니요       | 외부 공급자 이름 |
| `public_email`                       | 아니요       | 사용자의 공개 이메일 주소 |
| `reset_password`                     | 아니요       | `true`인 경우 사용자에게 암호를 재설정할 수 있는 링크를 보냅니다. `force_random_password`와 함께 사용할 수 있습니다. `password`보다 우선합니다. |
| `shared_runners_minutes_limit`       | 아니요       | 관리자만 설정할 수 있습니다. 이 사용자의 월간 최대 컴퓨팅 분입니다. `nil`(기본값; 시스템 기본값 상속), `0`(무제한) 또는 `> 0`일 수 있습니다. Premium 및 Ultimate만 해당합니다. |
| `skip_confirmation`                  | 아니요       | 확인 건너뛰기 - true 또는 false (기본값) |
| `theme_id`                           | 아니요       | 사용자의 GitLab 테마(자세한 내용은 [사용자 선호도 설명서](../user/profile/preferences.md#change-the-navigation-theme)를 참조하세요) |
| `twitter`                            | 아니요       | X (이전 명칭: Twitter) 계정 |
| `discord`                            | 아니요       | Discord 계정 |
| `github`                             | 아니요       | GitHub 사용자명 |
| `view_diffs_file_by_file`            | 아니요       | 사용자가 페이지당 하나의 파일 diff만 보는 것을 나타내는 플래그 |
| `website_url`                        | 아니요       | 웹사이트 URL |

## 사용자 수정 {#modify-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 감사 사용자를 수정할 수 있는 기능이 GitLab 15.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/366404)되었습니다.

{{< /history >}}

기존 사용자를 수정합니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

`email` 필드는 사용자의 기본 이메일 주소입니다. 이 필드는 해당 사용자를 위해 이미 추가된 보조 이메일 주소로만 변경할 수 있습니다. 동일한 사용자에게 더 많은 이메일 주소를 추가하려면 [이메일 추가 엔드포인트](user_email_addresses.md#add-an-email-address)를 사용하세요.

```plaintext
PUT /users/:id
```

지원되는 속성:

| 속성                            | 필수 | 설명 |
|:-------------------------------------|:---------|:------------|
| `admin`                              | 아니요       | 사용자가 관리자입니다. 유효한 값은 `true` 또는 `false`입니다. 기본값은 false입니다. |
| `auditor`                            | 아니요       | 사용자가 감사자입니다. 유효한 값은 `true` 또는 `false`입니다. 기본값은 false입니다. GitLab 15.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/366404)되었습니다.(기본값) Premium 및 Ultimate만 해당합니다. |
| `avatar`                             | 아니요       | 사용자 아바타용 이미지 파일 |
| `bio`                                | 아니요       | 사용자의 생활 정보 |
| `can_create_group`                   | 아니요       | 사용자가 그룹을 생성할 수 있습니다 - true 또는 false |
| `color_scheme_id`                    | 아니요       | 파일 뷰어의 사용자 색상 체계(자세한 내용은 [사용자 선호도 설명서](../user/profile/preferences.md#change-the-syntax-highlighting-theme)를 참조하세요) |
| `commit_email`                       | 아니요       | 사용자의 커밋 이메일입니다. `_private`로 설정하여 비공개 커밋 이메일을 사용합니다. [GitLab 15.5에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/375148). |
| `email`                              | 아니요       | 사용자의 이메일 |
| `extern_uid`                         | 아니요       | 외부 UID |
| `external`                           | 아니요       | 사용자를 외부로 표시합니다 - true 또는 false (기본값) |
| `extra_shared_runners_minutes_limit` | 아니요       | 관리자만 설정할 수 있습니다. 이 사용자를 위한 추가 컴퓨팅 분입니다. Premium 및 Ultimate만 해당합니다. |
| `group_id_for_saml`                  | 아니요       | SAML이 구성된 그룹의 ID |
| `id`                                 | 예      | 사용자의 ID |
| `linkedin`                           | 아니요       | LinkedIn    |
| `location`                           | 아니요       | 사용자의 위치 |
| `name`                               | 아니요       | 사용자의 이름 |
| `note`                               | 아니요       | 이 사용자에 대한 관리 메모 |
| `organization`                       | 아니요       | 조직 이름 |
| `password`                           | 아니요       | 사용자의 암호 |
| `private_profile`                    | 아니요       | 사용자의 프로필이 비공개입니다 - true 또는 false입니다. |
| `projects_limit`                     | 아니요       | 각 사용자가 생성할 수 있는 프로젝트 제한 |
| `pronouns`                           | 아니요       | 대명사    |
| `provider`                           | 아니요       | 외부 공급자 이름 |
| `public_email`                       | 아니요       | 사용자의 공개 이메일(이미 확인된 상태여야 함) |
| `shared_runners_minutes_limit`       | 아니요       | 관리자만 설정할 수 있습니다. 이 사용자의 월간 최대 컴퓨팅 분입니다. `nil` (기본값; 시스템 기본값 상속), `0` (무제한) 또는 `> 0`일 수 있습니다. Premium 및 Ultimate만 해당합니다. |
| `skip_reconfirmation`                | 아니요       | 재확인 건너뛰기 - true 또는 false (기본값) |
| `theme_id`                           | 아니요       | 사용자의 GitLab 테마(자세한 내용은 [사용자 선호도 설명서](../user/profile/preferences.md#change-the-navigation-theme)를 참조하세요) |
| `twitter`                            | 아니요       | X (이전 명칭: Twitter) 계정 |
| `discord`                            | 아니요       | Discord 계정 |
| `github`                             | 아니요       | GitHub 사용자명 |
| `username`                           | 아니요       | 사용자의 사용자명 |
| `view_diffs_file_by_file`            | 아니요       | 사용자가 페이지당 하나의 파일 diff만 보는 것을 나타내는 플래그 |
| `website_url`                        | 아니요       | 웹사이트 URL |

사용자의 암호를 업데이트하면 다음에 로그인할 때 변경해야 합니다.

`404` 오류를 반환합니다. `409` (충돌)이 더 적절한 경우도 있습니다. 예를 들어 이메일 주소를 기존 주소로 이름을 바꿀 때입니다.

## 사용자 삭제 {#delete-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사용자를 삭제합니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

반환:

- `204 No Content` 상태 코드(작업이 성공한 경우).
- `404`(리소스를 찾을 수 없는 경우).
- `409`(사용자를 소프트 삭제할 수 없는 경우).

```plaintext
DELETE /users/:id
```

지원되는 속성:

| 속성     | 유형    | 필수 | 설명 |
|:--------------|:--------|:---------|:------------|
| `id`          | 정수 | 예      | 사용자의 ID |
| `hard_delete` | 부울 | 아니요       | true인 경우 일반적으로 [Ghost User로 이동](../user/profile/account/delete_account.md#associated-records)되는 기여도가 대신 삭제되며, 이 사용자가 유일하게 소유한 그룹도 삭제됩니다. |

## 사용자 상태 검색 {#retrieve-your-user-status}

사용자 상태를 검색합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
GET /user/status
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/status"
```

응답 예시:

```json
{
  "emoji":"coffee",
  "availability":"busy",
  "message":"I crave coffee :coffee:",
  "message_html": "I crave coffee <gl-emoji title=\"hot beverage\" data-name=\"coffee\" data-unicode-version=\"4.0\">☕</gl-emoji>",
  "clear_status_at": null
}
```

## 사용자의 상태 검색 {#retrieve-the-status-of-a-user}

사용자의 상태를 검색합니다. 인증 없이 이 엔드포인트에 액세스할 수 있습니다.

```plaintext
GET /users/:id_or_username/status
```

지원되는 속성:

| 속성        | 유형   | 필수 | 설명 |
|:-----------------|:-------|:---------|:------------|
| `id_or_username` | 문자열 | 예      | 상태를 가져올 사용자의 ID 또는 사용자명 |

요청 예시:

```shell
curl --request GET \
  --url "https://gitlab.example.com/users/<username>/status"
```

응답 예시:

```json
{
  "emoji":"coffee",
  "availability":"busy",
  "message":"I crave coffee :coffee:",
  "message_html": "I crave coffee <gl-emoji title=\"hot beverage\" data-name=\"coffee\" data-unicode-version=\"4.0\">☕</gl-emoji>",
  "clear_status_at": null
}
```

## 사용자 상태 설정 {#set-your-user-status}

사용자 상태를 설정합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
PUT /user/status
PATCH /user/status
```

지원되는 속성:

| 속성            | 유형   | 필수 | 설명 |
|:---------------------|:-------|:---------|:------------|
| `emoji`              | 문자열 | 아니요       | 상태로 사용할 이모지의 이름입니다. 생략되면 `speech_balloon`을 사용합니다. 이모지 이름은 [Gemojione 인덱스](https://github.com/bonusly/gemojione/blob/master/config/index.json)의 지정된 이름 중 하나일 수 있습니다. |
| `message`            | 문자열 | 아니요       | 상태로 설정할 메시지입니다. 이모지 코드도 포함할 수 있습니다. 100자를 초과할 수 없습니다. |
| `availability`       | 문자열 | 아니요       | 사용자의 가용성입니다. 가능한 값: `busy` 및 `not_set`. |
| `clear_status_after` | 문자열 | 아니요       | 주어진 시간 간격 후에 상태를 자동으로 정리하며, 허용되는 값: `30_minutes`, `3_hours`, `8_hours`, `1_day`, `3_days`, `7_days`, `30_days` |

`PUT` 및 `PATCH` 간의 차이:

- `PUT`을 사용할 때 전달되지 않은 모든 매개변수는 `null`로 설정되어 지워집니다.
- `PATCH`을 사용할 때 전달되지 않은 모든 매개변수는 무시됩니다. 필드를 지우려면 명시적으로 `null`를 전달합니다.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/status" \
  --data "clear_status_after=1_day" \
  --data "emoji=coffee" \
  --data "message=I crave coffee" \
  --data "availability=busy"
```

응답 예시:

```json
{
  "emoji":"coffee",
  "availability":"busy",
  "message":"I crave coffee",
  "message_html": "I crave coffee",
  "clear_status_at":"2021-02-15T10:49:01.311Z"
}
```

## 사용자 선호도 검색 {#retrieve-your-user-preferences}

사용자 선호도를 검색합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
GET /user/preferences
```

응답 예시:

```json
{
  "id": 1,
  "user_id": 1,
  "view_diffs_file_by_file": true,
  "show_whitespace_in_diffs": false,
  "pass_user_identities_to_ci_jwt": false
}
```

## 사용자 선호도 업데이트 {#update-your-user-preferences}

사용자 선호도를 업데이트합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
PUT /user/preferences
```

```json
{
  "id": 1,
  "user_id": 1,
  "view_diffs_file_by_file": true,
  "show_whitespace_in_diffs": false,
  "pass_user_identities_to_ci_jwt": false
}
```

지원되는 속성:

| 속성                        | 필수 | 설명 |
|:---------------------------------|:---------|:------------|
| `view_diffs_file_by_file`        | 예      | 사용자가 페이지당 하나의 파일 diff만 보는 것을 나타내는 플래그입니다. |
| `show_whitespace_in_diffs`       | 예      | 사용자가 diff의 공백 변경을 보는 것을 나타내는 플래그입니다. |
| `pass_user_identities_to_ci_jwt` | 예      | 사용자가 외부 ID를 CI 정보로 전달하는 것을 나타내는 플래그입니다. 이 속성은 외부 시스템에서 사용자를 식별하거나 권한을 부여하기에 충분한 정보가 포함되어 있지 않습니다. 속성은 GitLab 내부이며 제3자 서비스로 전달되어서는 안 됩니다. 자세한 내용과 예시는 [토큰 페이로드](../ci/secrets/id_token_authentication.md#token-payload)를 참조하세요. |

## 자신을 위한 아바타 업로드 {#upload-an-avatar-for-yourself}

{{< history >}}

- [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148130).

{{< /history >}}

자신을 위한 아바타를 업로드합니다.

전제 조건:

- 인증을 받아야 합니다.
- 파일은 200 KB 이하여야 합니다. 이상적인 이미지 크기는 192 x 192 픽셀입니다.
- 이미지는 다음 파일 유형 중 하나여야 합니다:
  - `.bmp`
  - `.gif`
  - `.ico`
  - `.jpeg`
  - `.png`
  - `.tiff`

```plaintext
PUT /user/avatar
```

지원되는 속성:

| 속성 | 유형   | 필수 | 설명 |
|:----------|:-------|:---------|:------------|
| `avatar`  | 문자열 | 예      | 업로드할 파일입니다. |

파일 시스템에서 아바타를 업로드하려면 `--form` 인수를 사용하세요. 이로 인해 cURL이 `Content-Type: multipart/form-data` 헤더를 사용하여 데이터를 게시합니다. `avatar=` 매개변수는 파일 시스템의 이미지 파일을 가리키고 `@`가 앞에 있어야 합니다.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/avatar" \
  --form "avatar=@/path/to/your/avatar.png"
```

응답 예시:

```json
{
  "avatar_url": "http://gitlab.example.com/uploads/-/system/user/avatar/76/avatar.png",
}
```

반환:

- 성공한 경우 `200`.
- 200 KiB보다 큰 파일 크기의 경우 `400 Bad Request`.

## 할당된 이슈, 머지 리퀘스트 및 검토의 수 검색 {#retrieve-a-count-of-your-assigned-issues-merge-requests-and-reviews}

할당된 이슈, 머지 리퀘스트 및 검토의 수를 검색합니다.

전제 조건:

- 인증을 받아야 합니다.

지원되는 속성:

| 속성                         | 유형   | 설명 |
|:----------------------------------|:-------|:------------|
| `assigned_issues`                 | 숫자 | 현재 사용자에게 할당되고 열려 있는 이슈의 수입니다. |
| `assigned_merge_requests`         | 숫자 | 현재 사용자에게 할당되고 활성 상태인 머지 리퀘스트의 수입니다. |
| `merge_requests`                  | 숫자 | GitLab 13.8에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50026). `assigned_merge_requests`과(와) 동등하며 교체되었습니다. |
| `review_requested_merge_requests` | 숫자 | 현재 사용자가 검토를 요청받은 머지 리퀘스트의 수입니다. |
| `todos`                           | 숫자 | 현재 사용자의 할 일 항목의 수입니다. |

```plaintext
GET /user_counts
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user_counts"
```

응답 예시:

```json
{
  "merge_requests": 4,
  "assigned_issues": 15,
  "assigned_merge_requests": 11,
  "review_requested_merge_requests": 0,
  "todos": 1
}
```

## 사용자의 프로젝트, 그룹, 이슈 및 머지 리퀘스트 수 검색 {#retrieve-a-count-of-a-users-projects-groups-issues-and-merge-requests}

사용자의 다음 개수 목록을 검색합니다:

- 프로젝트입니다.
- 그룹입니다.
- 이슈입니다.
- 머지 리퀘스트입니다.

관리자는 모든 사용자를 쿼리할 수 있지만 관리자가 아닌 경우는 자신만 쿼리할 수 있습니다.

```plaintext
GET /users/:id/associations_count
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자의 ID |

응답 예시:

```json
{
  "groups_count": 2,
  "projects_count": 3,
  "issues_count": 8,
  "merge_requests_count": 5
}
```

## 사용자의 활동 나열 {#list-a-users-activity}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- 비공개 프로필을 가진 사용자의 활동을 보려면 관리자여야 합니다.

공개 프로필을 가진 사용자의 마지막 활동 날짜를 가장 오래된 것부터 최신 것 순서로 정렬하여 가져옵니다.

사용자 이벤트 타임스탬프(`last_activity_on` 및 `current_sign_in_at`)를 업데이트하는 활동은 다음과 같습니다:

- Git HTTP/SSH 활동(clone, push 등)
- 사용자가 GitLab에 로그인합니다
- 사용자가 대시보드, 프로젝트, 이슈 및 머지 리퀘스트와 관련된 페이지를 방문합니다
- 사용자가 API를 사용합니다
- 사용자가 GraphQL API를 사용합니다

기본적으로 지난 6개월 동안 공개 프로필을 가진 사용자의 활동을 표시하지만 `from` 매개변수를 사용하여 수정할 수 있습니다.

```plaintext
GET /user/activities
```

지원되는 속성:

| 속성 | 유형   | 필수 | 설명 |
|:----------|:-------|:---------|:------------|
| `from`    | 문자열 | 아니요       | `YEAR-MM-DD` 형식의 날짜 문자열입니다. 예를 들어, `2016-03-11`입니다. 기본값은 6개월 전입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/activities"
```

응답 예시:

```json
[
  {
    "username": "user1",
    "last_activity_on": "2015-12-14",
    "last_activity_at": "2015-12-14"
  },
  {
    "username": "user2",
    "last_activity_on": "2015-12-15",
    "last_activity_at": "2015-12-15"
  },
  {
    "username": "user3",
    "last_activity_on": "2015-12-16",
    "last_activity_at": "2015-12-16"
  }
]
```

`last_activity_at`는 더 이상 사용되지 않습니다. `last_activity_on` 대신 사용합니다.

## 사용자가 구성원인 프로젝트 및 그룹 나열 {#list-projects-and-groups-that-a-user-is-a-member-of}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

사용자가 구성원인 모든 프로젝트 및 그룹을 나열합니다.

구성원 관계의 `source_id`, `source_name`, `source_type` 및 `access_level`을 반환합니다. 원본은 `Namespace` (그룹을 나타냄) 또는 `Project` 유형일 수 있습니다. 응답은 직접 구성원만을 나타냅니다. 예를 들어 하위 그룹의 상속된 구성원은 포함되지 않습니다. 액세스 수준은 정수 값으로 표시됩니다:

- `0`:  액세스 권한 없음
- `5`:  최소 액세스
- `10`:  게스트
- `15`:  플래너
- `20`:  리포터
- `30`:  개발자
- `40`:  유지관리자
- `50`:  소유자

```plaintext
GET /users/:id/memberships
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 지정된 사용자의 ID |
| `type`    | 문자열  | 아니요       | 유형별로 구성원을 필터링합니다. `Project` 또는 `Namespace`일 수 있습니다 |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/:user_id/memberships"
```

응답 예시:

```json
[
  {
    "source_id": 1,
    "source_name": "Project one",
    "source_type": "Project",
    "access_level": "20"
  },
  {
    "source_id": 3,
    "source_name": "Group three",
    "source_type": "Namespace",
    "access_level": "20"
  }
]
```

반환:

- `200 OK` 성공 시.
- 사용자를 찾을 수 없는 경우 `404 User Not Found`.
- 관리자가 요청하지 않은 경우 `403 Forbidden`.
- 요청된 유형이 지원되지 않는 경우 `400 Bad Request`.

## 사용자를 위한 2단계 인증 비활성화 {#disable-two-factor-authentication-for-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/295260)되었습니다.

{{< /history >}}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

지정된 사용자에 대해 2단계 인증(2FA)을 비활성화합니다.

관리자는 API를 사용하여 자신의 사용자 계정 또는 다른 관리자를 위한 2FA을 비활성화할 수 없습니다. 대신 관리자는 [Rails 콘솔을 사용하여](../security/two_factor_authentication.md#for-a-single-user) 관리자의 2FA을 비활성화할 수 있습니다.

```plaintext
PATCH /users/:id/disable_two_factor
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자의 ID |

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1/disable_two_factor"
```

반환:

- `204 No content` 성공 시.
- 지정된 사용자에 대해 2단계 인증이 활성화되지 않은 경우 `400 Bad request`.
- 관리자로 인증되지 않은 경우 `403 Forbidden`.
- 사용자를 찾을 수 없는 경우 `404 User Not Found`.

## 사용자와 연결된 러너 생성 {#create-a-runner-linked-to-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

현재 사용자와 연결된 러너를 생성합니다. 사용자는 감사 목적으로 소유자로 나열되지만 러너 가용성은 `runner_type`을 기반으로 합니다. 자세한 내용은 [러너 관리](../ci/runners/runners_scope.md)를 참조하세요.

전제 조건:

- 관리자이거나 대상 네임스페이스 또는 리포지토리에 대한 소유자 역할이 있어야 합니다.
- `instance_type`의 경우 GitLab 인스턴스의 관리자여야 합니다.
- `group_type` 또는 `project_type`과(와) 소유자 역할의 경우 [러너 등록](../administration/settings/continuous_integration.md#control-runner-registration)을 허용해야 합니다.
- `create_runner` 범위가 있는 액세스 토큰입니다.

응답에서 `token`을 복사하거나 저장해야 합니다. 값을 다시 검색할 수 없습니다.

```plaintext
POST /user/runners
```

지원되는 속성:

| 속성          | 유형         | 필수 | 설명 |
|:-------------------|:-------------|:---------|:------------|
| `runner_type`      | 문자열       | 예      | 러너의 범위를 지정합니다. `instance_type`, `group_type` 또는 `project_type`. |
| `group_id`         | 정수      | 아니요       | 러너가 생성되는 그룹의 ID입니다. `runner_type`이(가) `group_type`인 경우 필수입니다. |
| `project_id`       | 정수      | 아니요       | 러너가 생성되는 프로젝트의 ID입니다. `runner_type`이(가) `project_type`인 경우 필수입니다. |
| `description`      | 문자열       | 아니요       | 러너에 대한 설명입니다. |
| `paused`           | 부울      | 아니요       | 러너가 새 작업을 무시해야 하는지 지정합니다. |
| `locked`           | 부울      | 아니요       | 러너가 현재 프로젝트에 대해 잠금되어야 하는지 지정합니다. |
| `run_untagged`     | 부울      | 아니요       | 러너가 태그되지 않은 작업을 처리해야 하는지 지정합니다. |
| `tag_list`         | 문자열 | 아니요       | 러너 태그의 쉼표로 구분된 목록입니다. |
| `access_level`     | 문자열       | 아니요       | 러너의 액세스 레벨은 `not_protected` 또는 `ref_protected`입니다. |
| `maximum_timeout`  | 정수      | 아니요       | 러너가 작업을 실행할 수 있는 시간(초)의 양을 제한하는 최대 시간 제한입니다. |
| `maintenance_note` | 문자열       | 아니요       | 러너에 대한 자유 형식의 유지 관리 참고 사항(1024자)입니다. |
| `token_expires_at` | 날짜/시간     | 아니요       | ISO 8601 형식의 러너 인증 토큰 만료 시간입니다. 향후 5분에서 15일 사이여야 합니다. 구성된 경우 인스턴스, 그룹 또는 프로젝트 수준 제한을 초과할 수 없습니다. 초기 토큰에만 적용됩니다. 회전된 토큰은 설정에서 계산된 만료를 사용합니다. **(PREMIUM ALL)** |
| `token_rotation_deadline` | 날짜/시간 | 아니요 | 토큰 회전 요청이 거부되는 기한입니다. `token_expires_at`을(를) 필요로 합니다. `token_expires_at` 이하여야 합니다. 둘 다 같은 값으로 설정하면 토큰 회전이 비활성화됩니다. 성공적인 회전 시 지워집니다. **(PREMIUM ALL)** |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/runners" \
  --data "runner_type=instance_type"
```

응답 예시:

```json
{
    "id": 9171,
    "token": "<access-token>",
    "token_expires_at": null
}
```

## 사용자의 인증 ID 삭제 {#delete-authentication-identity-from-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

해당 ID와 연결된 제공자 이름을 사용하여 사용자의 인증 ID를 삭제합니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

```plaintext
DELETE /users/:id/identities/:provider
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명 |
|:-----------|:--------|:---------|:------------|
| `id`       | 정수 | 예      | 사용자의 ID |
| `provider` | 문자열  | 예      | 외부 공급자 이름 |

## 지원 PIN 생성 {#create-a-support-pin}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175040)되었습니다.

{{< /history >}}

사용자 계정에 대한 지원 PIN을 생성합니다. PIN은 생성 후 7일이 지나면 만료됩니다. GitLab 지원 팀이 신원을 확인하기 위해 이 PIN을 요청할 수 있습니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
POST /user/support_pin
```

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/support_pin"
```

응답 예시:

```json
{
  "pin":"123456",
  "expires_at":"2025-02-27T22:06:57Z"
}
```

## 지원 PIN에 대한 세부 정보 확인 {#get-details-on-a-support-pin}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175040)되었습니다.

{{< /history >}}

계정의 지원 PIN에 대한 세부 정보를 확인합니다. GitLab 지원 팀이 신원을 확인하기 위해 이 PIN을 요청할 수 있습니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
GET /user/support_pin
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/support_pin"
```

응답 예시:

```json
{
  "pin":"123456",
  "expires_at":"2025-02-27T22:06:57Z"
}
```

## 사용자의 지원 PIN 확인 {#get-a-support-pin-for-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175040)되었습니다.

{{< /history >}}

지정된 사용자의 지원 PIN에 대한 세부 정보를 확인합니다. GitLab 지원 팀이 신원을 확인하기 위해 이 PIN을 요청할 수 있습니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

```plaintext
GET /users/:id/support_pin
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1234/support_pin"
```

응답 예시:

```json
{
  "pin":"123456",
  "expires_at":"2025-02-27T22:06:57Z"
}
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |

## 사용자의 지원 PIN 취소 {#revoke-a-support-pin-for-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187657).

{{< /history >}}

지정된 사용자의 지원 PIN을 자동 만료 전에 취소합니다. 이는 PIN을 즉시 만료시키고 제거합니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

```plaintext
POST /users/:id/support_pin/revoke
```

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1234/support_pin/revoke"
```

응답 예시:

성공하면 `202 Accepted`을(를) 반환합니다.

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자의 ID |
