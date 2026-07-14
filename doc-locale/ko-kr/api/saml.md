---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SAML API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 15.5에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/227841).

{{< /history >}}

이 API를 사용하여 SAML 기능과 상호작용합니다.

## GitLab.com 엔드포인트 {#gitlabcom-endpoints}

### 그룹의 모든 SAML 아이덴티티 나열 {#list-all-saml-identities-for-a-group}

```plaintext
GET /groups/:id/saml/identities
```

그룹의 모든 SAML 아이덴티티를 나열합니다.

지원되는 속성:

| 속성         | 유형    | 필수 | 설명           |
|:------------------|:--------|:---------|:----------------------|
| `id`              | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성    | 유형   | 설명               |
| ------------ | ------ | ------------------------- |
| `extern_uid` | 문자열 | 사용자의 외부 UID |
| `user_id`    | 문자열 | 사용자의 ID           |

요청 예시:

```shell
curl --location --request GET \
  --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/identities"
```

응답 예시:

```json
[
    {
        "extern_uid": "yrnZW46BrtBFqM7xDzE7dddd",
        "user_id": 48
    }
]
```

### 단일 SAML 아이덴티티 검색 {#retrieve-a-single-saml-identity}

{{< history >}}

- [GitLab 16.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591).

{{< /history >}}

단일 SAML 아이덴티티를 검색합니다.

```plaintext
GET /groups/:id/saml/:uid
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명               |
| --------- | -------------- | -------- | ------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `uid`     | 문자열         | 예      | 사용자의 외부 UID. |

요청 예시:

```shell
curl --location --request GET \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd"
```

응답 예시:

```json
{
    "extern_uid": "yrnZW46BrtBFqM7xDzE7dddd",
    "user_id": 48
}
```

### `extern_uid` 필드를 SAML 아이덴티티로 업데이트 {#update-extern_uid-field-for-a-saml-identity}

SAML 아이덴티티에 대해 `extern_uid` 필드를 업데이트합니다:

| SAML IdP 속성 | GitLab 필드 |
| ------------------ | ------------ |
| `id/externalId`    | `extern_uid` |

```plaintext
PATCH /groups/:id/saml/:uid
```

지원되는 속성:

| 속성 | 유형   | 필수 | 설명               |
| --------- | ------ | -------- | ------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `uid`     | 문자열 | 예      | 사용자의 외부 UID. |

요청 예시:

```shell
curl --request PATCH \
  --location \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd" \
  --form "extern_uid=be20d8dcc028677c931e04f387"
```

### 단일 SAML 아이덴티티 삭제 {#delete-a-single-saml-identity}

{{< history >}}

- [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/423592).

{{< /history >}}

```plaintext
DELETE /groups/:id/saml/:uid
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | 정수 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `uid`     | 문자열  | 예      | 사용자의 외부 UID. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.com/api/v4/groups/33/saml/be20d8dcc028677c931e04f387"
```

응답 예시:

```json
{
    "message" : "204 No Content"
}
```

## GitLab Self-Managed 엔드포인트 {#gitlab-self-managed-endpoints}

### 단일 SAML 아이덴티티 검색 {#retrieve-a-single-saml-identity-1}

Users API를 사용하여 [단일 SAML 아이덴티티를 가져옵니다](users.md#as-an-administrator).

### `extern_uid` 필드를 SAML 아이덴티티로 업데이트 {#update-extern_uid-field-for-a-saml-identity-1}

Users API를 사용하여 [사용자의 `extern_uid` 필드를 업데이트합니다](users.md#modify-a-user).

### 단일 SAML 아이덴티티 삭제 {#delete-a-single-saml-identity-1}

Users API를 사용하여 [사용자의 단일 아이덴티티를 삭제합니다](users.md#delete-authentication-identity-from-a-user).

## SAML 그룹 링크 {#saml-group-links}

{{< history >}}

- [GitLab 15.3.0에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/290367).
- `access_level` 유형이 `string`에서 `integer`로 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95607) (GitLab 15.3.3).
- `member_role_id` 유형을 GitLab 16.7에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/417201) [플래그](../administration/feature_flags/_index.md) `custom_roles_for_saml_group_links`로. 기본적으로 비활성화됨.
- `member_role_id` 유형을 GitLab 16.8에서 [일반 공급 중](https://gitlab.com/gitlab-org/gitlab/-/issues/417201). 기능 플래그 `custom_roles_for_saml_group_links` 제거됨.
- `provider` 매개변수를 GitLab 18.2에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/548725).

{{< /history >}}

[SAML 그룹 링크](../user/group/saml_sso/group_sync.md#configure-saml-group-links)를 나열, 가져오기, 추가 및 삭제할 수 있으며 REST API를 사용합니다.

### 모든 SAML 그룹 링크 나열 {#list-all-saml-group-links}

그룹의 모든 SAML 그룹 링크를 나열합니다.

```plaintext
GET /groups/:id/saml_group_links
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
|:----------|:---------------|:---------|:------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형    | 설명 |
|:--------------------|:--------|:------------|
| `[].name`           | 문자열  | SAML 그룹의 이름. |
| `[].access_level`   | 정수 | SAML 그룹의 멤버에 대한 기본 액세스 수준. 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (관리자) 또는 `50` (소유자). |
| `[].member_role_id` | 정수 | [멤버 역할 ID (`member_role_id`)](member_roles.md) (SAML 그룹의 멤버용). |
| `[].provider`       | 문자열  | 고유한 [공급자 이름](../integration/saml.md#configure-saml-support-in-gitlab) (이 그룹 링크를 적용하려면 일치해야 함). |

요청 예시:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links"
```

응답 예시:

```json
[
  {
    "name": "saml-group-1",
    "access_level": 10,
    "member_role_id": 12,
    "provider": null
  },
  {
    "name": "saml-group-2",
    "access_level": 40,
    "member_role_id": 99,
    "provider": "saml_provider_1"
  }
]
```

### SAML 그룹 링크 검색 {#retrieve-a-saml-group-link}

그룹의 SAML 그룹 링크를 검색합니다.

```plaintext
GET /groups/:id/saml_group_links/:saml_group_name
```

지원되는 속성:

| 속성         | 유형           | 필수 | 설명 |
|:------------------|:---------------|:---------|:------------|
| `id`              | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `saml_group_name` | 문자열         | 예      | SAML 그룹의 이름. |
| `provider`        | 문자열         | 아니요       | 고유한 [공급자 이름](../integration/saml.md#configure-saml-support-in-gitlab) (같은 이름으로 여러 링크가 있을 때 구분하기 위함). 같은 `saml_group_name`으로 여러 링크가 있을 때 필수. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성        | 유형    | 설명 |
|:-----------------|:--------|:------------|
| `name`           | 문자열  | SAML 그룹의 이름. |
| `access_level`   | 정수 | SAML 그룹의 멤버에 대한 기본 액세스 수준. 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (관리자) 또는 `50` (소유자). |
| `member_role_id` | 정수 | [멤버 역할 ID (`member_role_id`)](member_roles.md) (SAML 그룹의 멤버용). |
| `provider`       | 문자열  | 고유한 [공급자 이름](../integration/saml.md#configure-saml-support-in-gitlab) (이 그룹 링크를 적용하려면 일치해야 함). |

같은 이름이지만 다른 공급자를 가진 여러 SAML 그룹 링크가 있고 `provider` 매개변수를 지정하지 않으면, [`422`](rest/troubleshooting.md#status-codes)를 반환하고 `provider` 매개변수가 구분에 필수임을 나타내는 오류 메시지를 표시합니다.

요청 예시:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

공급자 매개변수를 포함한 요청 예시:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1?provider=saml_provider_1"
```

응답 예시:

```json
{
"name": "saml-group-1",
"access_level": 10,
"member_role_id": 12,
"provider": "saml_provider_1"
}
```

### SAML 그룹 링크 추가 {#add-a-saml-group-link}

그룹에 대한 SAML 그룹 링크를 추가합니다.

```plaintext
POST /groups/:id/saml_group_links
```

지원되는 속성:

| 속성         | 유형              | 필수 | 설명 |
|:------------------|:------------------|:---------|:------------|
| `id`              | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `saml_group_name` | 문자열            | 예      | SAML 그룹의 이름. |
| `access_level`    | 정수           | 예      | SAML 그룹의 멤버에 대한 기본 액세스 수준. 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (관리자) 또는 `50` (소유자). |
| `member_role_id`  | 정수           | 아니요       | [멤버 역할 ID (`member_role_id`)](member_roles.md) (SAML 그룹의 멤버용). |
| `provider`        | 문자열            | 아니요       | 고유한 [공급자 이름](../integration/saml.md#configure-saml-support-in-gitlab) (이 그룹 링크를 적용하려면 일치해야 함). |

성공하면 [`201`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성        | 유형    | 설명 |
|:-----------------|:--------|:------------|
| `name`           | 문자열  | SAML 그룹의 이름. |
| `access_level`   | 정수 | SAML 그룹의 멤버에 대한 기본 액세스 수준. 가능한 값:  `0` (액세스 없음), `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (관리자) 또는 `50` (소유자). |
| `member_role_id` | 정수 | [멤버 역할 ID (`member_role_id`)](member_roles.md) (SAML 그룹의 멤버용). |
| `provider`       | 문자열  | 고유한 [공급자 이름](../integration/saml.md#configure-saml-support-in-gitlab) (이 그룹 링크를 적용하려면 일치해야 함). |

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" --data '{ "saml_group_name": "<your_saml_group_name`>", "access_level": <chosen_access_level>, "member_role_id": <chosen_member_role_id>, "provider": "<your_provider>" }' --url  "https://gitlab.example.com/api/v4/groups/1/saml_group_links"
```

응답 예시:

```json
{
"name": "saml-group-1",
"access_level": 10,
"member_role_id": 12,
"provider": "saml_provider_1"
}
```

### SAML 그룹 링크 삭제 {#delete-a-saml-group-link}

그룹의 SAML 그룹 링크를 삭제합니다.

```plaintext
DELETE /groups/:id/saml_group_links/:saml_group_name
```

지원되는 속성:

| 속성         | 유형           | 필수 | 설명 |
|:------------------|:---------------|:---------|:------------|
| `id`              | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `saml_group_name` | 문자열         | 예      | SAML 그룹의 이름. |
| `provider`        | 문자열         | 아니요       | 고유한 [공급자 이름](../integration/saml.md#configure-saml-support-in-gitlab) (같은 이름으로 여러 링크가 있을 때 구분하기 위함). 같은 `saml_group_name`으로 여러 링크가 있을 때 필수. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

공급자 매개변수를 포함한 요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1?provider=saml_provider_1"
```

성공하면 응답 본문 없이 [`204`](rest/troubleshooting.md#status-codes) 상태 코드를 반환합니다.

같은 이름이지만 다른 공급자를 가진 여러 SAML 그룹 링크가 있고 `provider` 매개변수를 지정하지 않으면, [`422`](rest/troubleshooting.md#status-codes)를 반환하고 `provider` 매개변수가 구분에 필수임을 나타내는 오류 메시지를 표시합니다.
