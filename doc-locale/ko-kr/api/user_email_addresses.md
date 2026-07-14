---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 이메일 주소 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 사용자 계정의 이메일 주소와 상호 작용합니다. 자세한 내용은 [사용자 계정](../user/profile/_index.md)을 참조하세요.

## 모든 이메일 주소 나열 {#list-all-email-addresses}

사용자 계정의 모든 이메일 주소를 나열합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
GET /user/emails
```

응답 예시:

```json
[
  {
    "id": 1,
    "email": "email@example.com",
    "confirmed_at": "2021-03-26T19:07:56.248Z"
  },
  {
    "id": 3,
    "email": "email2@example.com",
    "confirmed_at": null
  }
]
```

## 사용자의 모든 이메일 주소 나열 {#list-all-email-addresses-for-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

지정된 사용자 계정의 모든 이메일 주소를 나열합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
GET /users/:id/emails
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |

## 이메일 주소의 세부 정보 검색 {#retrieve-details-on-an-email-address}

사용자 계정의 지정된 이메일 주소에 대한 세부 정보를 검색합니다.

```plaintext
GET /user/emails/:email_id
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명 |
|:-----------|:--------|:---------|:------------|
| `email_id` | 정수 | 예      | 이메일 주소의 ID |

응답 예시:

```json
{
  "id": 1,
  "email": "email@example.com",
  "confirmed_at": "2021-03-26T19:07:56.248Z"
}
```

## 이메일 주소 추가 {#add-an-email-address}

사용자 계정에 이메일 주소를 추가합니다.

```plaintext
POST /user/emails
```

지원되는 속성:

| 속성 | 유형   | 필수 | 설명 |
|:----------|:-------|:---------|:------------|
| `email`   | 문자열 | 예      | 이메일 주소 |

```json
{
  "id": 4,
  "email": "email@example.com",
  "confirmed_at": "2021-03-26T19:07:56.248Z"
}
```

생성된 이메일을 `201 Created` 상태로 반환합니다(성공한 경우). 오류가 발생하면 `400 Bad Request`가 오류를 설명하는 메시지와 함께 반환됩니다:

```json
{
  "message": {
    "email": [
      "has already been taken"
    ]
  }
}
```

## 사용자의 이메일 주소 추가 {#add-an-email-address-for-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

지정된 사용자 계정에 이메일 주소를 추가합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/emails
```

지원되는 속성:

| 속성           | 유형    | 필수 | 설명 |
|:--------------------|:--------|:---------|:------------|
| `id`                | 문자열  | 예      | 사용자 계정의 ID|
| `email`             | 문자열  | 예      | 이메일 주소 |
| `skip_confirmation` | 부울 | 아니요       | 확인을 건너뛰고 이메일이 확인됨을 가정합니다. 가능한 값: `true`, `false`. 기본값: `false`. |

## 이메일 주소 삭제 {#delete-an-email-address}

사용자 계정의 이메일 주소를 삭제합니다. 기본 이메일 주소는 삭제할 수 없습니다.

삭제된 이메일 주소로 전송되는 모든 향후 이메일은 대신 기본 이메일 주소로 전송됩니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
DELETE /user/emails/:email_id
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명 |
|:-----------|:--------|:---------|:------------|
| `email_id` | 정수 | 예      | 이메일 주소의 ID |

반환값:

- `204 No Content` 작업이 성공한 경우.
- `404` 리소스를 찾을 수 없는 경우.

## 사용자의 이메일 주소 삭제 {#delete-an-email-address-for-a-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

지정된 사용자 계정의 이메일 주소를 삭제합니다. 기본 이메일 주소는 삭제할 수 없습니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
DELETE /users/:id/emails/:email_id
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명 |
|:-----------|:--------|:---------|:------------|
| `id`       | 정수 | 예      | 사용자 계정의 ID |
| `email_id` | 정수 | 예      | 이메일 주소의 ID |
