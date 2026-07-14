---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 중재 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 사용자 계정을 중재합니다. 자세한 내용은 [사용자 중재](../administration/moderate_users.md)를 참조하세요.

## 사용자 접근 승인 {#approve-access-to-a-user}

승인 대기 중인 지정된 사용자 계정에 대한 접근을 승인합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/approve
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명        |
|------------|---------|----------|--------------------|
| `id`       | 정수 | 예      | 사용자 계정의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/approve"
```

반환:

- `201 Created` 성공 시.
- 사용자를 찾을 수 없는 경우 `404 User Not Found`.
- `403 Forbidden` 관리자 또는 LDAP 동기화로 인해 사용자를 승인할 수 없으면.
- `409 Conflict` 사용자가 비활성화된 경우.

응답 예시:

```json
{ "message": "Success" }
```

```json
{ "message": "404 User Not Found" }
```

```json
{ "message": "The user you are trying to approve is not pending approval" }
```

## 사용자 접근 거부 {#reject-access-to-a-user}

승인 대기 중인 지정된 사용자 계정에 대한 접근을 거부합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/reject
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명        |
|------------|---------|----------|--------------------|
| `id`       | 정수 | 예      | 사용자 계정의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/reject"
```

반환:

- `200 OK` 성공 시.
- 관리자로 인증되지 않은 경우 `403 Forbidden`.
- 사용자를 찾을 수 없는 경우 `404 User Not Found`.
- `409 Conflict` 사용자가 승인 대기 중이 아니면.

응답 예시:

```json
{ "message": "Success" }
```

```json
{ "message": "404 User Not Found" }
```

```json
{ "message": "User does not have a pending request" }
```

## 사용자 비활성화 {#deactivate-a-user}

지정된 사용자 계정을 비활성화합니다. 차단된 사용자에 대한 자세한 내용은 [사용자 활성화 및 비활성화](../administration/moderate_users.md#deactivate-and-reactivate-users)를 참조하세요.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/deactivate
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명        |
|------------|---------|----------|--------------------|
| `id`       | 정수 | 예      | 사용자 계정의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/deactivate"
```

반환:

- `201 OK` 성공 시.
- 사용자를 찾을 수 없는 경우 `404 User Not Found`.
- `403 Forbidden` 사용자를 비활성화하려고 시도할 때:
  - 관리자 또는 LDAP 동기화로 인해 차단됨.
  - [휴면](../administration/moderate_users.md#automatically-deactivate-dormant-users) 상태가 아님.
  - 내부.

## 사용자 재활성화 {#reactivate-a-user}

이전에 비활성화된 지정된 사용자 계정을 재활성화합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/activate
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명        |
|------------|---------|----------|--------------------|
| `id`       | 정수 | 예      | 사용자 계정의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/activate"
```

반환:

- `201 OK` 성공 시.
- `404 User Not Found` 사용자를 찾을 수 없으면.
- `403 Forbidden` 관리자 또는 LDAP 동기화로 인해 사용자를 활성화할 수 없으면.

## 사용자 접근 차단 {#block-access-to-a-user}

지정된 사용자 계정을 차단합니다. 차단된 사용자에 대한 자세한 내용은 [사용자 차단 및 차단 해제](../administration/moderate_users.md#block-and-unblock-users)를 참조하세요.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/block
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명        |
|------------|---------|----------|--------------------|
| `id`       | 정수 | 예      | 사용자 계정의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/block"
```

반환:

- `201 OK` 성공 시.
- 사용자를 찾을 수 없는 경우 `404 User Not Found`.
- `403 Forbidden` 차단을 시도할 때:
  - LDAP를 통해 차단된 사용자.
  - 내부 사용자.

## 사용자 차단 해제 {#unblock-access-to-a-user}

이전에 차단된 지정된 사용자 계정을 차단 해제합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/unblock
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명        |
|------------|---------|----------|--------------------|
| `id`       | 정수 | 예      | 사용자 계정의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/unblock"
```

반환:

- `201 OK` 성공 시.
- 사용자를 찾을 수 없는 경우 `404 User Not Found`.
- `403 Forbidden` LDAP 동기화로 인해 차단된 사용자를 차단 해제하려고 시도할 때.

## 사용자 차단 {#ban-a-user}

지정된 사용자 계정을 차단합니다. 차단된 사용자에 대한 자세한 내용은 [사용자 차단 및 차단 해제](../administration/moderate_users.md#ban-and-unban-users)를 참조하세요.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/ban
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명        |
|------------|---------|----------|--------------------|
| `id`       | 정수 | 예      | 사용자 계정의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/ban"
```

반환:

- `201 OK` 성공 시.
- 사용자를 찾을 수 없는 경우 `404 User Not Found`.
- `403 Forbidden` 활성화되지 않은 사용자를 차단하려고 시도할 때.

## 사용자 차단 해제 {#unban-a-user}

이전에 차단된 지정된 사용자 계정을 차단 해제합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/unban
```

지원되는 속성:

| 속성  | 유형    | 필수 | 설명        |
|------------|---------|----------|--------------------|
| `id`       | 정수 | 예      | 사용자 계정의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/unban"
```

반환:

- `201 OK` 성공 시.
- `404 User Not Found` 사용자를 찾을 수 없으면.
- `403 Forbidden` 차단되지 않은 사용자를 차단 해제하려고 시도할 때.

## 관련 항목 {#related-topics}

- [남용 보고서 검토](../administration/review_abuse_reports.md)
- [스팸 로그 검토](../administration/review_spam_logs.md)
