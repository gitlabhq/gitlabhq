---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SCIM API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 15.5에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98354).

{{< /history >}}

이 API를 사용하여 그룹에서 SCIM 정체성을 관리합니다.

전제 조건:

- [그룹 SSO](../user/group/saml_sso/_index.md)를 활성화해야 합니다.
- [그룹 SSO용 SCIM](../user/group/saml_sso/scim_setup.md)을 활성화해야 합니다.
- 올바른 범위를 가진 [개인 액세스 토큰](../user/profile/personal_access_tokens.md) 또는 [그룹 액세스 토큰](../user/group/settings/group_access_tokens.md)으로 인증해야 합니다.

이 API는 SCIM 토큰이 필요한 [내부 그룹 SCIM API](../development/internal_api/_index.md#group-scim-api) 와 [내부 인스턴스 SCIM API](../development/internal_api/_index.md#instance-scim-api)와 다릅니다.

- 이 API:
  - [RFC7644 프로토콜](https://www.rfc-editor.org/rfc/rfc7644)을 구현하지 않습니다.
  - 그룹 내에서 SCIM 정체성을 가져오고, 확인하고, 업데이트하고, 삭제합니다.
- 내부 그룹 및 인스턴스 SCIM API:
  - SCIM 제공자 통합을 위한 시스템 사용입니다.
  - [RFC7644 프로토콜](https://www.rfc-editor.org/rfc/rfc7644)을 구현합니다.
  - 그룹 또는 인스턴스에 대해 SCIM으로 프로비저닝된 사용자 목록을 가져옵니다.
  - 그룹 또는 인스턴스에 대해 SCIM으로 프로비저닝된 사용자를 생성, 삭제, 업데이트합니다.

## 그룹의 SCIM 정체성 검색 {#retrieve-scim-identities-for-a-group}

{{< history >}}

- [GitLab 15.5에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/227841).

{{< /history >}}

그룹의 SCIM 정체성을 검색합니다.

```plaintext
GET /groups/:id/scim/identities
```

지원되는 속성:

| 속성         | 유형    | 필수 | 설명           |
|:------------------|:--------|:---------|:----------------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성    | 유형    | 설명               |
| ------------ | ------- | ------------------------- |
| `extern_uid` | 문자열  | 사용자의 외부 UID |
| `user_id`    | 정수 | 사용자의 ID           |
| `active`     | 부울 | 정체성의 상태    |

응답 예시:

```json
[
    {
        "extern_uid": "be20d8dcc028677c931e04f387",
        "user_id": 48,
        "active": true
    }
]
```

요청 예시:

```shell
curl --location --request GET \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/identities" \
  --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>"
```

## 단일 SCIM 정체성 검색 {#retrieve-a-single-scim-identity}

{{< history >}}

- [GitLab 16.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591).

{{< /history >}}

단일 SCIM 정체성을 검색합니다.

```plaintext
GET /groups/:id/scim/:uid
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | 정수 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `uid`     | 문자열  | 예      | 사용자의 외부 UID. |

요청 예시:

```shell
curl --location --request GET \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/be20d8dcc028677c931e04f387" \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>"
```

응답 예시:

```json
{
    "extern_uid": "be20d8dcc028677c931e04f387",
    "user_id": 48,
    "active": true
}
```

## `extern_uid` 필드를 SCIM 정체성으로 업데이트 {#update-extern_uid-field-for-a-scim-identity}

{{< history >}}

- [GitLab 15.5에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/227841).

{{< /history >}}

SCIM 정체성을 위해 `extern_uid` 필드를 업데이트합니다.

업데이트할 수 있는 필드:

| SCIM/IdP 필드  | GitLab 필드 |
| --------------- | ------------ |
| `id/externalId` | `extern_uid` |

```plaintext
PATCH /groups/:groups_id/scim/:uid
```

매개변수:

| 속성 | 유형   | 필수 | 설명               |
| --------- | ------ | -------- | ------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `uid`     | 문자열 | 예      | 사용자의 외부 UID. |

요청 예시:

```shell
curl --location --request PATCH \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/be20d8dcc028677c931e04f387" \
  --header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
  --form "extern_uid=yrnZW46BrtBFqM7xDzE7dddd"
```

## 단일 SCIM 정체성 삭제 {#delete-a-single-scim-identity}

{{< history >}}

- [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/423592).

{{< /history >}}

단일 SCIM 정체성을 삭제합니다.

```plaintext
DELETE /groups/:id/scim/:uid
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | 정수 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `uid`     | 문자열  | 예      | 사용자의 외부 UID. |

요청 예시:

```shell
curl --location --request DELETE \
  --url "https://gitlab.example.com/api/v4/groups/33/scim/yrnZW46BrtBFqM7xDzE7dddd" \
  --header "PRIVATE-TOKEN: <your_access_token>"
```

응답 예시:

```json
{
    "message" : "204 No Content"
}
```
