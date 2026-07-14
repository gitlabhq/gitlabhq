---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 SSH 및 GPG 키 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 사용자의 [SSH 키](../user/ssh.md) 및 [GPG 키](../user/project/repository/signed_commits/gpg.md)와 상호작용합니다.

## 모든 SSH 키 나열 {#list-all-ssh-keys}

사용자 계정의 모든 SSH 키를 나열합니다.

`page` 및 `per_page` [페이지 매김 매개변수](rest/_index.md#offset-based-pagination)를 사용하여 결과를 필터링합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
GET /user/keys
```

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/keys"
```

응답 예시:

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z",
    "usage_type": "auth"
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z",
    "usage_type": "signing"
  }
]
```

## 사용자의 모든 SSH 키 나열 {#list-all-ssh-keys-for-a-user}

지정된 사용자 계정의 모든 SSH 키를 나열합니다. 이 엔드포인트는 인증이 필요하지 않습니다.

```plaintext
GET /users/:id_or_username/keys
```

지원되는 속성:

| 속성        | 유형   | 필수 | 설명 |
|:-----------------|:-------|:---------|:------------|
| `id_or_username` | 문자열 | 예      | 사용자 계정의 ID 또는 사용자 이름 |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1/keys"
```

## SSH 키 검색 {#retrieve-an-ssh-key}

사용자 계정의 SSH 키를 검색합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
GET /user/keys/:key_id
```

지원되는 속성:

| 속성 | 유형   | 필수 | 설명 |
|:----------|:-------|:---------|:------------|
| `key_id`  | 문자열 | 예      | 기존 키의 ID |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/keys/1"
```

응답 예시:

```json
{
  "id": 1,
  "title": "Public key",
  "key": "<SSH_KEY>",
  "created_at": "2014-08-01T14:47:39.080Z",
  "usage_type": "auth"
}
```

## 사용자의 SSH 키 검색 {#retrieve-an-ssh-key-for-a-user}

지정된 사용자 계정의 SSH 키를 검색합니다. 이 엔드포인트는 인증이 필요하지 않습니다.

```plaintext
GET /users/:id/keys/:key_id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID 또는 사용자 이름 |
| `key_id`  | 정수 | 예      | 기존 키의 ID  |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/1/keys/1"
```

응답 예시:

```json
{
  "id": 1,
  "title": "Public key",
  "key": "<SSH_KEY>",
  "created_at": "2014-08-01T14:47:39.080Z",
  "usage_type": "auth"
}
```

## SSH 키 추가 {#add-an-ssh-key}

{{< history >}}

- `usage_type` 매개변수는 GitLab 15.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105551)되었습니다.

{{< /history >}}

사용자 계정에 SSH 키를 추가합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
POST /user/keys
```

지원되는 속성:

| 속성    | 유형   | 필수 | 설명 |
|:-------------|:-------|:---------|:------------|
| `title`      | 문자열 | 예      | 키의 제목 |
| `key`        | 문자열 | 예      | 공개 키 값 |
| `expires_at` | 문자열 | 아니요       | ISO 형식의 키 만료 날짜(`YYYY-MM-DD`). |
| `usage_type` | 문자열 | 아니요       | 키의 사용 범위. 가능한 값: `auth`, `signing` 또는 `auth_and_signing`. 기본값: `auth_and_signing` |

다음 중 하나를 반환합니다:

- 생성된 키가 `201 Created` 상태로 반환됩니다.
- `400 Bad Request` 오류가 발생하고 오류를 설명하는 메시지를 포함합니다:

  ```json
  {
    "message": {
      "fingerprint": [
        "has already been taken"
      ],
      "key": [
        "has already been taken"
      ]
    }
  }
  ```

응답 예시:

```json
{
  "title": "ABC",
  "key": "<SSH_KEY>",
  "expires_at": "2016-01-21T00:00:00.000Z",
  "usage_type": "auth"
}
```

## 사용자의 SSH 키 추가 {#add-an-ssh-key-for-a-user}

{{< history >}}

- `usage_type` 매개변수는 GitLab 15.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105551)되었습니다.

{{< /history >}}

지정된 사용자 계정에 SSH 키를 추가합니다.

> [!note]
> 이것은 또한 감사 이벤트를 추가합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/keys
```

지원되는 속성:

| 속성    | 유형    | 필수 | 설명 |
|:-------------|:--------|:---------|:------------|
| `id`         | 정수 | 예      | 사용자 계정의 ID |
| `title`      | 문자열  | 예      | 키의 제목 |
| `key`        | 문자열  | 예      | 공개 키 값  |
| `expires_at` | 문자열  | 아니요       | ISO 형식의 키 만료 날짜(`YYYY-MM-DD`). |
| `usage_type` | 문자열  | 아니요       | 키의 사용 범위. 가능한 값: `auth`, `signing` 또는 `auth_and_signing`. 기본값: `auth_and_signing` |

다음 중 하나를 반환합니다:

- 생성된 키가 `201 Created` 상태로 반환됩니다.
- `400 Bad Request` 오류가 발생하고 오류를 설명하는 메시지를 포함합니다:

  ```json
  {
    "message": {
      "fingerprint": [
        "has already been taken"
      ],
      "key": [
        "has already been taken"
      ]
    }
  }
  ```

응답 예시:

```json
{
  "title": "ABC",
  "key": "<SSH_KEY>",
  "expires_at": "2016-01-21T00:00:00.000Z",
  "usage_type": "auth"
}
```

## SSH 키 삭제 {#delete-an-ssh-key}

사용자 계정에서 SSH 키를 삭제합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
DELETE /user/keys/:key_id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `key_id`  | 정수 | 예      | 기존 키의 ID  |

다음 중 하나를 반환합니다:

- 작업이 성공한 경우 `204 No Content` 상태 코드를 반환합니다.
- 리소스를 찾을 수 없는 경우 `404` 상태 코드를 반환합니다.

## 사용자의 SSH 키 삭제 {#delete-an-ssh-key-for-a-user}

지정된 사용자 계정에서 SSH 키를 삭제합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
DELETE /users/:id/keys/:key_id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |
| `key_id`  | 정수 | 예      | 기존 키의 ID  |

## 모든 GPG 키 나열 {#list-all-gpg-keys}

사용자 계정의 모든 GPG 키를 나열합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
GET /user/gpg_keys
```

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/gpg_keys"
```

응답 예시:

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## 사용자의 모든 GPG 키 나열 {#list-all-gpg-keys-for-a-user}

지정된 사용자 계정의 모든 GPG 키를 나열합니다. 이 엔드포인트는 인증이 필요하지 않습니다.

```plaintext
GET /users/:id/gpg_keys
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/2/gpg_keys"
```

응답 예시:

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## GPG 키 검색 {#retrieve-a-gpg-key}

사용자 계정의 GPG 키를 검색합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
GET /user/gpg_keys/:key_id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `key_id`  | 정수 | 예      | 기존 키의 ID |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/gpg_keys/1"
```

응답 예시:

```json
{
  "id": 1,
  "key": "<PGP_PUBLIC_KEY_BLOCK>",
  "created_at": "2017-09-05T09:17:46.264Z"
}
```

## 사용자의 GPG 키 검색 {#retrieve-a-gpg-key-for-a-user}

지정된 사용자 계정의 GPG 키를 검색합니다. 이 엔드포인트는 인증이 필요하지 않습니다.

```plaintext
GET /users/:id/gpg_keys/:key_id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |
| `key_id`  | 정수 | 예      | 기존 키의 ID |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/2/gpg_keys/1"
```

응답 예시:

```json
{
  "id": 1,
  "key": "<PGP_PUBLIC_KEY_BLOCK>",
  "created_at": "2017-09-05T09:17:46.264Z"
}
```

## GPG 키 추가 {#add-a-gpg-key}

사용자 계정에 GPG 키를 추가합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
POST /user/gpg_keys
```

지원되는 속성:

| 속성 | 유형   | 필수 | 설명 |
|:----------|:-------|:---------|:------------|
| `key`     | 문자열 | 예      | 공개 키 값 |

요청 예시:

```shell
export KEY="$(gpg --armor --export <your_gpg_key_id>)"

curl --data-urlencode "key=<PGP_PUBLIC_KEY_BLOCK>" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/user/gpg_keys"
```

응답 예시:

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## 사용자의 GPG 키 추가 {#add-a-gpg-key-for-a-user}

지정된 사용자 계정에 GPG 키를 추가합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:id/gpg_keys
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |
| `key`     | 정수 | 예      | 공개 키 값 |

요청 예시:

```shell
curl --data-urlencode "key=<PGP_PUBLIC_KEY_BLOCK>" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/2/gpg_keys"
```

응답 예시:

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## GPG 키 삭제 {#delete-a-gpg-key}

사용자 계정에서 GPG 키를 삭제합니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
DELETE /user/gpg_keys/:key_id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `key_id`  | 정수 | 예      | 기존 키의 ID |

다음 중 하나를 반환합니다:

- `204 No Content` 성공 시.
- 키를 찾을 수 없는 경우 `404 Not Found`.

## 사용자의 GPG 키 삭제 {#delete-a-gpg-key-for-a-user}

지정된 사용자 계정에서 GPG 키를 삭제합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
DELETE /users/:id/gpg_keys/:key_id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |
| `key_id`  | 정수 | 예      | 기존 키의 ID |
