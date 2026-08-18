---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 서비스 계정 API
description: "GitLab 서비스 계정 API는 인스턴스 또는 그룹 수준에서 서비스 계정을 관리하며, 강력한 토큰 및 계정 관리 제어 기능을 제공합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 18.10의 Free 티어에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225913) [기능 플래그](../administration/feature_flags/_index.md) `service_accounts_available_on_free_or_unlicensed`를 사용합니다. 기본적으로 비활성화됨.
- [GitLab 18.11의 Free 티어에서 일반 제공](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227910)됩니다. 기능 플래그 `service_accounts_available_on_free_or_unlicensed` 제거됨.

{{< /history >}}

이 API를 사용하여 [서비스 계정](../user/profile/service_accounts.md)과 상호작용합니다.

생성할 수 있는 서비스 계정의 수는 구독 및 제공 서비스에 따라 다릅니다:

- GitLab Premium 및 Ultimate에서는 모든 제공 서비스에 대해 무제한의 서비스 계정을 생성할 수 있습니다.
- GitLab Free에서 한도는 제공 서비스에 따라 다릅니다:
  - GitLab.com의 경우 각 최상위 그룹에 대해 최대 100개의 서비스 계정을 생성할 수 있습니다. 여기에는 하위 그룹 또는 프로젝트에서 생성된 서비스 계정이 포함됩니다.
  - GitLab Self-Managed의 경우 인스턴스당 최대 100개의 서비스 계정을 생성할 수 있습니다. 여기에는 프로비저닝 방식(인스턴스, 그룹 또는 프로젝트 수준)에 관계없이 모든 서비스 계정이 포함됩니다.

[사용자 API](users.md)를 통해 서비스 계정과도 상호작용할 수 있습니다. 서비스 계정의 SSH 키를 관리하려면 [사용자 SSH 및 GPG 키 API](user_keys.md)를 사용하세요.

## 인스턴스 서비스 계정 {#instance-service-accounts}

{{< details >}}

- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

인스턴스 서비스 계정은 전체 GitLab 인스턴스에서 사용할 수 있지만 사용자와 마찬가지로 그룹 및 프로젝트에 추가되어야 합니다.

인스턴스 서비스 계정의 개인 액세스 토큰을 관리하려면 [개인 액세스 토큰 API](personal_access_tokens.md)를 사용하세요.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

### 모든 인스턴스 서비스 계정 나열 {#list-all-instance-service-accounts}

{{< history >}}

- 모든 서비스 계정 나열 [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/416729)됨.

{{< /history >}}

모든 인스턴스 서비스 계정을 나열합니다.

`page` 및 `per_page` [페이지 매김 매개변수](rest/_index.md#offset-based-pagination)를 사용하여 결과를 필터링합니다.

```plaintext
GET /service_accounts
```

지원되는 속성:

| 속성  | 유형   | 필수 | 설명 |
| ---------- | ------ | -------- | ----------- |
| `order_by` | 문자열 | 아니요       | 결과를 정렬할 특성입니다. 가능한 값: `id` 또는 `username`. 기본값: `id`. |
| `sort`     | 문자열 | 아니요       | 결과를 정렬할 방향입니다. 가능한 값: `desc` 또는 `asc`. 기본값: `desc`. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/service_accounts"
```

응답 예시:

```json
[
  {
    "id": 114,
    "username": "service_account_33",
    "name": "Service account user"
  },
  {
    "id": 137,
    "username": "service_account_34",
    "name": "john doe"
  }
]
```

### 인스턴스 서비스 계정 생성 {#create-an-instance-service-account}

{{< history >}}

- [GitLab 16.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/406782)됨.
- `username` 및 `name` 특성이 GitLab 16.10에 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841)됨.
- `email` 특성이 GitLab 17.9에 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178689)됨.

{{< /history >}}

인스턴스 서비스 계정을 생성합니다.

```plaintext
POST /service_accounts
POST /service_accounts?email=custom_email@gitlab.example.com
```

지원되는 속성:

| 속성  | 유형   | 필수 | 설명 |
| ---------- | ------ | -------- | ----------- |
| `name`     | 문자열 | 아니요       | 사용자의 이름입니다. 설정하지 않으면 `Service account user`을 사용합니다. |
| `username` | 문자열 | 아니요       | 사용자 계정의 사용자 이름입니다. 정의하지 않으면 `service_account_`이 앞에 붙은 이름을 생성합니다. |
| `email`    | 문자열 | 아니요       | 사용자 계정의 이메일입니다. 정의하지 않으면 답장 없음 이메일 주소를 생성합니다. 사용자 지정 이메일 주소는 이메일 확인 설정이 [비활성화](../administration/settings/sign_up_restrictions.md#confirm-user-email)되지 않으면 확인이 필요합니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/service_accounts"
```

응답 예시:

```json
{
  "id": 57,
  "username": "service_account_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "service_account_6018816a18e515214e0c34c2b33523fc@noreply.gitlab.example.com"
}
```

`email` 특성으로 정의된 이메일 주소가 이미 다른 사용자가 사용 중이면 `400 Bad request` 오류를 반환합니다.

### 인스턴스 서비스 계정 업데이트 {#update-an-instance-service-account}

{{< history >}}

- [GitLab 18.2에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196309/)됨.

{{< /history >}}

지정된 인스턴스 서비스 계정을 업데이트합니다.

```plaintext
PATCH /service_accounts/:id
```

매개변수:

| 속성  | 유형           | 필수 | 설명                                                                                                                                                                                                               |
|:-----------|:---------------|:---------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`       | 정수        | 예      | 서비스 계정의 ID입니다.  |
| `name`     | 문자열         | 아니요       | 사용자의 이름입니다.  |
| `username` | 문자열         | 아니요       | 사용자 계정의 사용자 이름입니다. |
| `email`    | 문자열         | 아니요       | 사용자 계정의 이메일입니다. 사용자 지정 이메일 주소는 이메일 확인 설정이 [비활성화](../administration/settings/sign_up_restrictions.md#confirm-user-email)되지 않으면 확인이 필요합니다. |

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/service_accounts/57" \
  --data "name=Updated Service Account&email=updated_email@example.com"
```

응답 예시:

```json
{
  "id": 57,
  "username": "service_account_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_<random_hash>@noreply.gitlab.example.com",
  "unconfirmed_email": "custom_email@example.com"
}
```

## 그룹 서비스 계정 {#group-service-accounts}

{{< history >}}

- 하위 그룹 서비스 계정 [GitLab 18.10에서 도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/585513) [기능 플래그](../administration/feature_flags/_index.md) `allow_subgroups_to_create_service_accounts`를 사용합니다. 기본적으로 비활성화됨.
- 하위 그룹 서비스 계정 [GitLab 18.11에서 일반 제공](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225485/). 기능 플래그 `allow_subgroups_to_create_service_accounts` 제거됨.

{{< /history >}}

그룹 서비스 계정은 특정 그룹이 소유하며, 생성된 그룹이나 모든 하위 그룹 또는 프로젝트에 초대할 수 있습니다. 상위 그룹에는 초대할 수 없습니다.

전제 조건:

- GitLab.com에서 그룹의 소유자 역할이 필요합니다.
- GitLab Self-Managed 또는 GitLab Dedicated에서는 다음 중 하나를 수행해야 합니다:
  - 인스턴스의 관리자여야 합니다.
  - 그룹의 소유자 역할이 있어야 하며 [서비스 계정 생성이 허용](../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)되어야 합니다.

### 모든 그룹 서비스 계정 나열 {#list-all-group-service-accounts}

{{< history >}}

- [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/416729)됨.

{{< /history >}}

지정된 그룹의 모든 서비스 계정을 나열합니다.

`page` 및 `per_page` [페이지 매김 매개변수](rest/_index.md#offset-based-pagination)를 사용하여 결과를 필터링합니다.

```plaintext
GET /groups/:id/service_accounts
```

매개변수:

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 대상 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `order_by` | 문자열         | 아니요       | 사용자 목록을 `username` 또는 `id`로 정렬합니다. 기본값은 `id`입니다. |
| `sort`     | 문자열         | 아니요       | `asc` 또는 `desc`로 정렬을 지정합니다. 기본값은 `desc`입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/345/service_accounts"
```

응답 예시:

```json
[

  {
    "id": 57,
    "username": "service_account_group_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com"
  },
  {
    "id": 58,
    "username": "service_account_group_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com",
    "unconfirmed_email": "custom_email@example.com"
  }
]
```

### 그룹 서비스 계정 생성 {#create-a-group-service-account}

{{< history >}}

- [GitLab 16.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/407775).
- `username` 및 `name` 특성이 GitLab 16.10에 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841)됨.
- `email` 특성이 GitLab 17.9에 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181456) 됨 [기능 플래그](../administration/feature_flags/_index.md) `group_service_account_custom_email`를 사용합니다.
- `email` 특성이 GitLab 17.11에서 [일반 제공](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186476)됨. 기능 플래그 `group_service_account_custom_email` 제거됨.

{{< /history >}}

지정된 그룹의 서비스 계정을 생성합니다.

```plaintext
POST /groups/:id/service_accounts
```

지원되는 속성:

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`     | 문자열         | 아니요       | 사용자 계정 이름입니다. 지정하지 않으면 `Service account user`을 사용합니다. |
| `username` | 문자열         | 아니요       | 사용자 계정 사용자 이름입니다. 지정하지 않으면 `service_account_group_`이 앞에 붙은 이름을 생성합니다. |
| `email`    | 문자열         | 아니요       | 사용자 계정의 이메일입니다. 지정하지 않으면 `service_account_group_`이 앞에 붙은 이메일을 생성합니다. 사용자 지정 이메일 주소는 그룹이 일치하는 [검증된 도메인](../user/enterprise_user/_index.md#manage-group-domains) 을 가지고 있거나 이메일 확인 설정이 [비활성화](../administration/settings/sign_up_restrictions.md#confirm-user-email)되지 않으면 확인이 필요합니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/345/service_accounts" \
  --data "email=custom_email@example.com"
```

응답 예시:

```json
{
  "id": 57,
  "username": "service_account_group_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "custom_email@example.com"
}
```

### 그룹 서비스 계정 업데이트 {#update-a-group-service-account}

{{< history >}}

- [GitLab 17.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182607/).
- 사용자 지정 이메일 주소 추가 [GitLab 18.2에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196309)됨.
- [GitLab 18.9의 복합 ID와 연관된 서비스 계정에 사용자 이름 제한이 추가](https://gitlab.com/gitlab-org/gitlab/-/work_items/581050)됨.

{{< /history >}}

지정된 그룹의 서비스 계정을 업데이트합니다.

> [!note]
>
> - [복합 ID](../user/duo_agent_platform/composite_identity.md)와 연관된 서비스 계정의 사용자 이름을 업데이트할 수 없습니다.

```plaintext
PATCH /groups/:id/service_accounts/:user_id
```

매개변수:

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 대상 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `user_id`  | 정수        | 예      | 서비스 계정의 ID입니다. |
| `name`     | 문자열         | 아니요       | 사용자의 이름입니다. |
| `username` | 문자열         | 아니요       | 사용자의 사용자 이름입니다. |
| `email`    | 문자열         | 아니요       | 사용자 계정의 이메일입니다. 사용자 지정 이메일 주소는 그룹이 일치하는 [검증된 도메인](../user/enterprise_user/_index.md#manage-group-domains) 을 가지고 있거나 이메일 확인 설정이 [비활성화](../administration/settings/sign_up_restrictions.md#confirm-user-email)되지 않으면 확인이 필요합니다. |

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/345/service_accounts/57" \
  --data "name=Updated Service Account&email=updated_email@example.com"
```

응답 예시:

```json
{
  "id": 57,
  "username": "service_account_group_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_group_345_<random_hash>@noreply.gitlab.example.com",
  "unconfirmed_email": "custom_email@example.com"
}
```

### 그룹 서비스 계정 삭제 {#delete-a-group-service-account}

{{< history >}}

- [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/416729)됨.

{{< /history >}}

지정된 그룹에서 서비스 계정을 삭제합니다.

```plaintext
DELETE /groups/:id/service_accounts/:user_id
```

매개변수:

| 속성     | 유형           | 필수 | 설명 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 정수 또는 문자열 | 예      | 대상 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `user_id`     | 정수        | 예      | 서비스 계정의 ID입니다. |
| `hard_delete` | 부울        | 아니요       | 참이면 일반적으로 [유령 사용자로 이동](../user/profile/account/delete_account.md#associated-records)되는 기여도는 대신 삭제되며, 이 서비스 계정이 유일하게 소유한 그룹도 삭제됩니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/345/service_accounts/181"
```

### 그룹 서비스 계정의 모든 개인 액세스 토큰 나열 {#list-all-personal-access-tokens-for-a-group-service-account}

{{< history >}}

- GitLab 17.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/526924).

{{< /history >}}

지정된 그룹의 서비스 계정에 대한 모든 개인 액세스 토큰을 나열합니다.

```plaintext
GET /groups/:id/service_accounts/:user_id/personal_access_tokens
```

지원되는 속성:

| 속성          | 유형                | 필수 | 설명 |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | 정수 또는 문자열      | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id`          | 정수             | 예      | 서비스 계정의 ID입니다. |
| `created_after`    | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 생성된 토큰을 반환합니다. |
| `created_before`   | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 생성된 토큰을 반환합니다. |
| `expires_after`    | 날짜 (ISO 8601)     | 아니요       | 정의된 경우, 지정된 시간 이후에 만료되는 토큰을 반환합니다. |
| `expires_before`   | 날짜 (ISO 8601)     | 아니요       | 정의된 경우, 지정된 시간 이전에 만료되는 토큰을 반환합니다. |
| `last_used_after`  | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 마지막으로 사용된 토큰을 반환합니다. |
| `last_used_before` | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 마지막으로 사용된 토큰을 반환합니다. |
| `revoked`          | 부울             | 아니요       | `true`인 경우 취소된 토큰만 반환합니다. |
| `search`           | 문자열              | 아니요       | 정의된 경우 이름에 지정된 값을 포함하는 토큰을 반환합니다. |
| `sort`             | 문자열              | 아니요       | 정의된 경우 지정된 값으로 결과를 정렬합니다. 가능한 값: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |
| `state`            | 문자열              | 아니요       | 정의된 경우 지정된 상태의 토큰을 반환합니다. 가능한 값: `active` 및 `inactive`. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/187/service_accounts/195/personal_access_tokens?sort=id_desc&search=token2b&created_before=2025-03-27"
```

응답 예시:

```json
[
    {
        "id": 187,
        "name": "service_accounts_token2b",
        "revoked": false,
        "created_at": "2025-03-26T14:42:51.084Z",
        "description": null,
        "scopes": [
            "api"
        ],
        "user_id": 195,
        "last_used_at": null,
        "active": true,
        "expires_at": null
    }
]
```

실패한 응답의 예시:

- `401: Unauthorized`
- `404 Group Not Found`

### 그룹 서비스 계정의 개인 액세스 토큰 생성 {#create-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- [GitLab 16.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/406781).

{{< /history >}}

지정된 그룹의 기존 서비스 계정에 대한 개인 액세스 토큰을 생성합니다.

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens
```

매개변수:

| 속성     | 유형           | 필수 | 설명 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id`     | 정수        | 예      | 서비스 계정의 ID입니다. |
| `name`        | 문자열         | 예      | 개인 액세스 토큰의 이름입니다. |
| `description` | 문자열         | 아니요       | 개인 액세스 토큰의 설명입니다. |
| `scopes`      | 배열          | 예      | 승인된 범위의 배열입니다. 가능한 값의 목록은 [개인 액세스 토큰 범위](../user/profile/personal_access_tokens.md#personal-access-token-scopes)를 참조하세요. |
| `expires_at`  | 날짜           | 아니요       | ISO 형식(`YYYY-MM-DD`)의 액세스 토큰 만료 날짜입니다. 지정하지 않으면 날짜는 [최대 허용 수명 제한](../user/profile/personal_access_tokens.md#access-token-expiration)으로 설정됩니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens" \
  --data "scopes[]=api,read_user,read_repository" \
  --data "name=service_accounts_token"
```

응답 예시:

```json
{
  "id":6,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:47:13.900Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2024-06-12",
  "token":"<token_value>"
}
```

### 그룹 서비스 계정의 개인 액세스 토큰 취소 {#revoke-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- [GitLab 17.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184287)됨

{{< /history >}}

그룹의 기존 서비스 계정에 대해 지정된 개인 액세스 토큰을 취소합니다.

```plaintext
DELETE /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id
```

매개변수:

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 대상 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `user_id`  | 정수        | 예      | 서비스 계정의 ID입니다. |
| `token_id` | 정수        | 예      | 토큰의 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens/6"
```

성공하면 `204: No Content`을(를) 반환합니다.

기타 가능한 응답:

- 취소되지 않으면 `400: Bad Request`.
- 요청이 인증되지 않으면 `401: Unauthorized`입니다.
- 요청이 허용되지 않으면 `403: Forbidden`입니다.
- 액세스 토큰이 존재하지 않는 경우 `404: Not Found`.

### 그룹 서비스 계정의 개인 액세스 토큰 회전 {#rotate-a-personal-access-token-for-a-group-service-account}

{{< history >}}

- [GitLab 16.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/406781).

{{< /history >}}

지정된 그룹의 기존 서비스 계정에 대해 지정된 개인 액세스 토큰을 회전합니다. 이는 기존 토큰을 취소하고 동일한 이름, 설명 및 범위로 새 토큰을 생성합니다.

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate
```

매개변수:

| 속성    | 유형           | 필수 | 설명 |
| ------------ | -------------- | -------- | ----------- |
| `id`         | 정수 또는 문자열 | 예      | 대상 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `user_id`    | 정수        | 예      | 서비스 계정의 ID입니다. |
| `token_id`   | 정수        | 예      | 토큰의 ID입니다. |
| `expires_at` | 날짜           | 아니요       | ISO 형식(`YYYY-MM-DD`)의 액세스 토큰 만료 날짜입니다. [GitLab 17.9에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/505671)됨. 토큰에 만료 날짜가 필요한 경우 기본값은 1주일입니다. 필수가 아닌 경우 [최대 허용 수명 제한](../user/profile/personal_access_tokens.md#access-token-expiration)으로 기본값이 설정됩니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens/6/rotate"
```

응답 예시:

```json
{
  "id":7,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:54:49.962Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2023-06-20",
  "token":"<token_value>"
}
```

## 프로젝트 서비스 계정 {#project-service-accounts}

{{< history >}}

- GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/585509) 되었으며 [플래그](../administration/feature_flags/_index.md) `allow_projects_to_create_service_accounts`로 명명됩니다. 기본적으로 비활성화됨.
- 프로젝트 서비스 계정 [GitLab 18.11에서 일반 제공](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225485/). 기능 플래그 `allow_projects_to_create_service_accounts` 제거됨.

{{< /history >}}

프로젝트 서비스 계정은 특정 프로젝트가 소유하며 관련된 프로젝트에만 사용할 수 있습니다.

전제 조건:

- GitLab.com에서 프로젝트의 유지관리자 또는 소유자 역할이 필요합니다.
- GitLab Self-Managed 또는 GitLab Dedicated에서는 다음 중 하나를 수행해야 합니다:
  - 인스턴스의 관리자여야 합니다.
  - 프로젝트의 유지관리자 또는 소유자 역할이 있어야 합니다.

### 모든 프로젝트 서비스 계정 나열 {#list-all-project-service-accounts}

지정된 프로젝트의 모든 서비스 계정을 나열합니다.

`page` 및 `per_page` [페이지 매김 매개변수](rest/_index.md#offset-based-pagination)를 사용하여 결과를 필터링합니다.

```plaintext
GET /projects/:id/service_accounts
```

매개변수:

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | [대상 프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)를 나타내는 ID입니다. |
| `order_by` | 문자열         | 아니요       | 사용자 목록을 `username` 또는 `id`로 정렬합니다. 기본값은 `id`입니다. |
| `sort`     | 문자열         | 아니요       | `asc` 또는 `desc`로 정렬을 지정합니다. 기본값은 `desc`입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/345/service_accounts"
```

응답 예시:

```json
[

  {
    "id": 57,
    "username": "service_account_project_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_project_345_<random_hash>@noreply.gitlab.example.com"
  },
  {
    "id": 58,
    "username": "service_account_project_345_<random_hash>",
    "name": "Service account user",
    "email": "service_account_project_345_<random_hash>@noreply.gitlab.example.com",
    "unconfirmed_email": "custom_email@example.com"
  }
]
```

### 프로젝트 서비스 계정 생성 {#create-a-project-service-account}

지정된 프로젝트의 서비스 계정을 생성합니다.

```plaintext
POST /projects/:id/service_accounts
```

지원되는 속성:

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `name`     | 문자열         | 아니요       | 사용자 계정 이름입니다. 지정하지 않으면 `Service account user`을 사용합니다. |
| `username` | 문자열         | 아니요       | 사용자 계정 사용자 이름입니다. 지정하지 않으면 `service_account_project_`이 앞에 붙은 이름을 생성합니다. |
| `email`    | 문자열         | 아니요       | 사용자 계정의 이메일입니다. 지정하지 않으면 `service_account_project_`이 앞에 붙은 이메일을 생성합니다. 사용자 지정 이메일 주소는 그룹이 일치하는 [검증된 도메인](../user/enterprise_user/_index.md#manage-group-domains) 을 가지고 있거나 이메일 확인 설정이 [비활성화](../administration/settings/sign_up_restrictions.md#confirm-user-email)되지 않으면 확인이 필요합니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/345/service_accounts" \
  --data "email=custom_email@example.com"
```

응답 예시:

```json
{
  "id": 57,
  "username": "service_account_project_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "custom_email@example.com"
}
```

### 프로젝트 서비스 계정 업데이트 {#update-a-project-service-account}

지정된 프로젝트의 서비스 계정을 업데이트합니다.

```plaintext
PATCH /projects/:id/service_accounts/:user_id
```

매개변수:

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | [대상 프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)를 나타내는 ID입니다. |
| `user_id`  | 정수        | 예      | 서비스 계정의 ID입니다. |
| `name`     | 문자열         | 아니요       | 사용자의 이름입니다. |
| `username` | 문자열         | 아니요       | 사용자의 사용자 이름입니다. |
| `email`    | 문자열         | 아니요       | 사용자 계정의 이메일입니다. 사용자 지정 이메일 주소는 그룹이 일치하는 [검증된 도메인](../user/enterprise_user/_index.md#manage-group-domains) 을 가지고 있거나 이메일 확인 설정이 [비활성화](../administration/settings/sign_up_restrictions.md#confirm-user-email)되지 않으면 확인이 필요합니다. |

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/345/service_accounts/57" \
  --data "name=Updated Service Account&email=updated_email@example.com"
```

응답 예시:

```json
{
  "id": 57,
  "username": "service_account_project_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_project_345_<random_hash>@noreply.gitlab.example.com",
  "unconfirmed_email": "custom_email@example.com"
}
```

### 프로젝트 서비스 계정 삭제 {#delete-a-project-service-account}

지정된 프로젝트에서 서비스 계정을 삭제합니다.

```plaintext
DELETE /projects/:id/service_accounts/:user_id
```

매개변수:

| 속성     | 유형           | 필수 | 설명 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 정수 또는 문자열 | 예      | [대상 프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)를 나타내는 ID입니다. |
| `user_id`     | 정수        | 예      | 서비스 계정의 ID입니다. |
| `hard_delete` | 부울        | 아니요       | 참이면 일반적으로 [유령 사용자로 이동](../user/profile/account/delete_account.md#associated-records)되는 기여도는 대신 삭제되며, 이 서비스 계정이 유일하게 소유한 그룹도 삭제됩니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/345/service_accounts/181"
```

### 프로젝트 서비스 계정의 모든 개인 액세스 토큰 나열 {#list-all-personal-access-tokens-for-a-project-service-account}

프로젝트의 서비스 계정에 대한 모든 개인 액세스 토큰을 나열합니다.

```plaintext
GET /projects/:id/service_accounts/:user_id/personal_access_tokens
```

지원되는 속성:

| 속성          | 유형                | 필수 | 설명 |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | 정수 또는 문자열      | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id`          | 정수             | 예      | 서비스 계정의 ID입니다. |
| `created_after`    | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 생성된 토큰을 반환합니다. |
| `created_before`   | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 생성된 토큰을 반환합니다. |
| `expires_after`    | 날짜 (ISO 8601)     | 아니요       | 정의된 경우, 지정된 시간 이후에 만료되는 토큰을 반환합니다. |
| `expires_before`   | 날짜 (ISO 8601)     | 아니요       | 정의된 경우, 지정된 시간 이전에 만료되는 토큰을 반환합니다. |
| `last_used_after`  | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 마지막으로 사용된 토큰을 반환합니다. |
| `last_used_before` | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 마지막으로 사용된 토큰을 반환합니다. |
| `revoked`          | 부울             | 아니요       | `true`인 경우 취소된 토큰만 반환합니다. |
| `search`           | 문자열              | 아니요       | 정의된 경우 이름에 지정된 값을 포함하는 토큰을 반환합니다. |
| `sort`             | 문자열              | 아니요       | 정의된 경우 지정된 값으로 결과를 정렬합니다. 가능한 값: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |
| `state`            | 문자열              | 아니요       | 정의된 경우 지정된 상태의 토큰을 반환합니다. 가능한 값: `active` 및 `inactive`. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/187/service_accounts/195/personal_access_tokens?sort=id_desc&search=token2b&created_before=2025-03-27"
```

응답 예시:

```json
[
    {
        "id": 187,
        "name": "service_accounts_token2b",
        "revoked": false,
        "created_at": "2025-03-26T14:42:51.084Z",
        "description": null,
        "scopes": [
            "api"
        ],
        "user_id": 195,
        "last_used_at": null,
        "active": true,
        "expires_at": null
    }
]
```

실패한 응답의 예시:

- `401: Unauthorized`
- `404 Project Not Found`

### 프로젝트 서비스 계정의 개인 액세스 토큰 생성 {#create-a-personal-access-token-for-a-project-service-account}

지정된 프로젝트의 기존 서비스 계정에 대한 개인 액세스 토큰을 생성합니다.

```plaintext
POST /projects/:id/service_accounts/:user_id/personal_access_tokens
```

매개변수:

| 속성     | 유형           | 필수 | 설명 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `user_id`     | 정수        | 예      | 서비스 계정의 ID입니다. |
| `name`        | 문자열         | 예      | 개인 액세스 토큰의 이름입니다. |
| `description` | 문자열         | 아니요       | 개인 액세스 토큰의 설명입니다. |
| `scopes`      | 배열          | 예      | 승인된 범위의 배열입니다. 가능한 값의 목록은 [개인 액세스 토큰 범위](../user/profile/personal_access_tokens.md#personal-access-token-scopes)를 참조하세요. |
| `expires_at`  | 날짜           | 아니요       | ISO 형식(`YYYY-MM-DD`)의 액세스 토큰 만료 날짜입니다. 지정하지 않으면 날짜는 [최대 허용 수명 제한](../user/profile/personal_access_tokens.md#access-token-expiration)으로 설정됩니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/35/service_accounts/71/personal_access_tokens" \
  --data "scopes[]=api,read_user,read_repository" \
  --data "name=service_accounts_token"
```

응답 예시:

```json
{
  "id":6,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:47:13.900Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2024-06-12",
  "token":"<token_value>"
}
```

### 프로젝트 서비스 계정의 개인 액세스 토큰 취소 {#revoke-a-personal-access-token-for-a-project-service-account}

지정된 프로젝트의 기존 서비스 계정에 대해 개인 액세스 토큰을 취소합니다.

```plaintext
DELETE /projects/:id/service_accounts/:user_id/personal_access_tokens/:token_id
```

매개변수:

| 속성  | 유형           | 필수 | 설명 |
| ---------- | -------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | [대상 프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)를 나타내는 ID입니다. |
| `user_id`  | 정수        | 예      | 서비스 계정의 ID입니다. |
| `token_id` | 정수        | 예      | 토큰의 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/35/service_accounts/71/personal_access_tokens/6"
```

성공하면 `204: No Content`을(를) 반환합니다.

기타 가능한 응답:

- 취소되지 않으면 `400: Bad Request`.
- 요청이 인증되지 않으면 `401: Unauthorized`입니다.
- 요청이 허용되지 않으면 `403: Forbidden`입니다.
- 액세스 토큰이 존재하지 않는 경우 `404: Not Found`.

### 프로젝트 서비스 계정의 개인 액세스 토큰 회전 {#rotate-a-personal-access-token-for-a-project-service-account}

지정된 프로젝트의 기존 서비스 계정에 대해 개인 액세스 토큰을 회전합니다. 이는 1주일 동안 유효한 새 토큰을 생성하고 기존 토큰을 취소합니다.

```plaintext
POST /projects/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate
```

매개변수:

| 속성    | 유형           | 필수 | 설명 |
| ------------ | -------------- | -------- | ----------- |
| `id`         | 정수 또는 문자열 | 예      | [대상 프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)를 나타내는 ID입니다. |
| `user_id`    | 정수        | 예      | 서비스 계정의 ID입니다. |
| `token_id`   | 정수        | 예      | 토큰의 ID입니다. |
| `expires_at` | 날짜           | 아니요       | ISO 형식(`YYYY-MM-DD`)의 액세스 토큰 만료 날짜입니다. [GitLab 17.9에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/505671)됨. 토큰에 만료 날짜가 필요한 경우 기본값은 1주일입니다. 필수가 아닌 경우 [최대 허용 수명 제한](../user/profile/personal_access_tokens.md#access-token-expiration)으로 기본값이 설정됩니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/35/service_accounts/71/personal_access_tokens/6/rotate"
```

응답 예시:

```json
{
  "id":7,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:54:49.962Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2023-06-20",
  "token":"<token_value>"
}
```
