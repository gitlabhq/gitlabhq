---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 배포 토큰 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [배포 토큰](../user/project/deploy_tokens/_index.md)과 상호 작용합니다.

## 모든 배포 토큰 나열 {#list-all-deploy-tokens}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 인스턴스 전체의 모든 배포 토큰을 나열합니다. 이 엔드포인트는 관리자 액세스가 필요합니다.

```plaintext
GET /deploy_tokens
```

매개변수:

| 속성 | 유형     | 필수               | 설명 |
|-----------|----------|------------------------|-------------|
| `active`  | 부울  | 아니요 | 활성 상태로 제한합니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/deploy_tokens"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

## 프로젝트 배포 토큰 {#project-deploy-tokens}

프로젝트 배포 토큰 API 엔드포인트를 사용하려면 프로젝트의 Maintainer 또는 Owner 역할이 필요합니다.

### 프로젝트 배포 토큰 나열 {#list-project-deploy-tokens}

프로젝트의 배포 토큰을 나열합니다.

```plaintext
GET /projects/:id/deploy_tokens
```

매개변수:

| 속성      | 유형           | 필수               | 설명 |
|:---------------|:---------------|:-----------------------|:------------|
| `id`           | 정수 또는 문자열 | 예 | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `active`       | 부울        | 아니요 | 활성 상태로 제한합니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deploy_tokens"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

### 프로젝트 배포 토큰 검색 {#retrieve-a-project-deploy-token}

ID별로 단일 프로젝트의 배포 토큰을 검색합니다.

```plaintext
GET /projects/:id/deploy_tokens/:token_id
```

매개변수:

| 속성  | 유형           | 필수               | 설명 |
| ---------- | -------------- | ---------------------- | ----------- |
| `id`       | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `token_id` | 정수        | 예 | 배포 토큰의 ID |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deploy_tokens/1"
```

응답 예시:

```json
{
  "id": 1,
  "name": "MyToken",
  "username": "gitlab+deploy-token-1",
  "expires_at": "2020-02-14T00:00:00.000Z",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository",
    "read_registry"
  ]
}
```

### 프로젝트 배포 토큰 생성 {#create-a-project-deploy-token}

프로젝트 배포 토큰을 생성합니다.

```plaintext
POST /projects/:id/deploy_tokens
```

매개변수:

| 속성    | 유형             | 필수               | 설명 |
| ------------ | ---------------- | ---------------------- | ----------- |
| `id`         | 정수 또는 문자열   | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `name`       | 문자열           | 예 | 새 배포 토큰의 이름 |
| `scopes`     | 문자열 배열 | 예 | 배포 토큰 범위를 나타냅니다. `read_repository`, `read_registry`, `write_registry`, `read_package_registry`, `write_package_registry`, `read_virtual_registry` 또는 `write_virtual_registry` 중 최소 하나 이상이어야 합니다. |
| `expires_at` | 날짜/시간         | 아니요 | 배포 토큰의 만료 날짜입니다. 값이 제공되지 않으면 만료되지 않습니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `username`   | 문자열           | 아니요 | 배포 토큰의 사용자 이름입니다. 기본값은 `gitlab+deploy-token-{n}`입니다 |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"name": "My deploy token", "expires_at": "2021-01-01", "username": "custom-user", "scopes": ["read_repository"]}' \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_tokens/"
```

응답 예시:

```json
{
  "id": 1,
  "name": "My deploy token",
  "username": "custom-user",
  "expires_at": "2021-01-01T00:00:00.000Z",
  "token": "jMRvtPNxrn3crTAGukpZ",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository"
  ]
}
```

### 프로젝트 배포 토큰 삭제 {#delete-a-project-deploy-token}

프로젝트에서 배포 토큰을 삭제합니다.

```plaintext
DELETE /projects/:id/deploy_tokens/:token_id
```

매개변수:

| 속성  | 유형           | 필수               | 설명 |
| ---------- | -------------- | ---------------------- | ----------- |
| `id`       | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `token_id` | 정수        | 예 | 배포 토큰의 ID |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_tokens/13"
```

## 그룹 배포 토큰 {#group-deploy-tokens}

그룹의 Maintainer 또는 Owner 역할이 있는 사용자는 그룹 배포 토큰을 나열할 수 있습니다. 그룹 Owner만 그룹 배포 토큰을 생성하고 삭제할 수 있습니다.

### 그룹 배포 토큰 나열 {#list-group-deploy-tokens}

그룹의 배포 토큰을 나열합니다

```plaintext
GET /groups/:id/deploy_tokens
```

매개변수:

| 속성      | 유형           | 필수               | 설명 |
|:---------------|:---------------|:-----------------------|:------------|
| `id`           | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `active`       | 부울        | 아니요 | 활성 상태로 제한합니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url"https://gitlab.example.com/api/v4/groups/1/deploy_tokens"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

### 그룹 배포 토큰 검색 {#retrieve-a-group-deploy-token}

ID별로 단일 그룹의 배포 토큰을 검색합니다.

```plaintext
GET /groups/:id/deploy_tokens/:token_id
```

매개변수:

| 속성   | 유형           | 필수               | 설명 |
| ----------- | -------------- | ---------------------- | ----------- |
| `id`        | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `token_id`  | 정수        | 예 | 배포 토큰의 ID |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/deploy_tokens/1"
```

응답 예시:

```json
{
  "id": 1,
  "name": "MyToken",
  "username": "gitlab+deploy-token-1",
  "expires_at": "2020-02-14T00:00:00.000Z",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository",
    "read_registry"
  ]
}
```

### 그룹 배포 토큰 생성 {#create-a-group-deploy-token}

그룹 배포 토큰을 생성합니다.

```plaintext
POST /groups/:id/deploy_tokens
```

매개변수:

| 속성    | 유형 | 필수  | 설명 |
| ------------ | ---- | --------- | ----------- |
| `id`         | 정수 또는 문자열   | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `name`       | 문자열           | 예 | 새 배포 토큰의 이름 |
| `scopes`     | 문자열 배열 | 예 | 배포 토큰 범위를 나타냅니다. `read_repository`, `read_registry`, `write_registry`, `read_package_registry` 또는 `write_package_registry` 중 최소 하나 이상이어야 합니다. |
| `expires_at` | 날짜/시간         | 아니요 | 배포 토큰의 만료 날짜입니다. 값이 제공되지 않으면 만료되지 않습니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `username`   | 문자열           | 아니요 | 배포 토큰의 사용자 이름입니다. 기본값은 `gitlab+deploy-token-{n}`입니다 |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"name": "My deploy token", "expires_at": "2021-01-01", "username": "custom-user", "scopes": ["read_repository"]}' \
  --url "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/"
```

응답 예시:

```json
{
  "id": 1,
  "name": "My deploy token",
  "username": "custom-user",
  "expires_at": "2021-01-01T00:00:00.000Z",
  "token": "jMRvtPNxrn3crTAGukpZ",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_registry"
  ]
}
```

### 그룹 배포 토큰 삭제 {#delete-a-group-deploy-token}

그룹에서 배포 토큰을 삭제합니다.

```plaintext
DELETE /groups/:id/deploy_tokens/:token_id
```

매개변수:

| 속성   | 유형           | 필수               | 설명 |
| ----------- | -------------- | ---------------------- | ----------- |
| `id`        | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `token_id`  | 정수        | 예 | 배포 토큰의 ID |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/13"
```
