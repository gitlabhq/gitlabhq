---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 원격 미러 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [원격 미러](../user/project/repository/mirror/push.md)를 관리합니다. 원격 미러 API를 사용하여 이러한 미러의 상태를 쿼리하고 수정할 수 있습니다.

보안상의 이유로 API 응답의 `url` 속성에서 사용자 이름과 비밀번호 정보가 항상 제거됩니다.

> [!note]
> [풀 미러](../user/project/repository/mirror/pull.md) 는 이들을 표시하고 업데이트하기 위해 [다른 API 엔드포인트](project_pull_mirroring.md#update-project-pull-mirroring-settings)를 사용합니다.

## 프로젝트의 모든 원격 미러 나열 {#list-all-remote-mirrors-for-a-project}

{{< history >}}

- 속성 `host_keys` [GitLab 18.4에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435).

{{< /history >}}

지정된 프로젝트의 모든 원격 미러를 나열합니다.

```plaintext
GET /projects/:id/remote_mirrors
```

지원되는 속성:

| 특성 | 유형              | 필수 | 설명                                                                      |
|-----------|-------------------|----------|----------------------------------------------------------------------------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.       |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 특성                   | 유형    | 설명 |
|-----------------------------|---------|-------------|
| `auth_method`               | 문자열  | 미러에 사용된 인증 방법입니다. |
| `enabled`                   | 부울 | `true`이면 미러가 활성화됩니다. |
| `host_keys`                 | 배열   | 원격 미러의 SSH 호스트 키 지문 배열입니다. |
| `id`                        | 정수 | 원격 미러의 ID입니다. |
| `keep_divergent_refs`       | 부울 | `true`이면 미러링할 때 발산된 참조가 유지됩니다. |
| `last_error`                | 문자열  | 마지막 미러 시도의 오류 메시지입니다. 성공한 경우 `null`입니다. |
| `last_successful_update_at` | 문자열  | 마지막 성공한 미러 업데이트의 타임스탬프입니다. ISO 8601 형식입니다. |
| `last_update_at`            | 문자열  | 마지막 미러 시도의 타임스탬프입니다. ISO 8601 형식입니다. |
| `last_update_started_at`    | 문자열  | 마지막 미러 시도가 시작된 타임스탬프입니다. ISO 8601 형식입니다. |
| `only_protected_branches`   | 부울 | `true`이면 보호된 브랜치만 미러링됩니다. |
| `update_status`             | 문자열  | 미러 업데이트의 상태입니다. 가능한 값: `none`, `scheduled`, `started`, `finished`, `failed`입니다. |
| `url`                       | 문자열  | 보안을 위해 자격 증명이 제거된 미러 URL입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors"
```

예제 응답:

```json
[
  {
    "enabled": true,
    "id": 101486,
    "auth_method": "ssh_public_key",
    "last_error": null,
    "last_successful_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_started_at": "2020-01-06T17:31:55.864Z",
    "only_protected_branches": true,
    "keep_divergent_refs": true,
    "update_status": "finished",
    "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
  }
]
```

## 프로젝트의 원격 미러 검색 {#retrieve-a-remote-mirror-for-a-project}

{{< history >}}

- 속성 `host_keys` [GitLab 18.4에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435).

{{< /history >}}

프로젝트의 지정된 원격 미러를 검색합니다.

```plaintext
GET /projects/:id/remote_mirrors/:mirror_id
```

지원되는 속성:

| 특성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `mirror_id` | 정수           | 예      | 원격 미러의 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 특성                   | 유형    | 설명 |
|-----------------------------|---------|-------------|
| `enabled`                   | 부울 | `true`이면 미러가 활성화됩니다. |
| `id`                        | 정수 | 원격 미러의 ID입니다. |
| `host_keys`                 | 배열   | 원격 미러의 SSH 호스트 키 지문 배열입니다. |
| `keep_divergent_refs`       | 부울 | `true`이면 미러링할 때 발산된 참조가 유지됩니다. |
| `last_error`                | 문자열  | 마지막 미러 시도의 오류 메시지입니다. 성공한 경우 `null`입니다. |
| `last_successful_update_at` | 문자열  | 마지막 성공한 미러 업데이트의 타임스탬프입니다. ISO 8601 형식입니다. |
| `last_update_at`            | 문자열  | 마지막 미러 시도의 타임스탬프입니다. ISO 8601 형식입니다. |
| `last_update_started_at`    | 문자열  | 마지막 미러 시도가 시작된 타임스탬프입니다. ISO 8601 형식입니다. |
| `only_protected_branches`   | 부울 | `true`이면 보호된 브랜치만 미러링됩니다. |
| `update_status`             | 문자열  | 미러 업데이트의 상태입니다. 가능한 값: `none`, `scheduled`, `started`, `finished`, `failed`입니다. |
| `url`                       | 문자열  | 보안을 위해 자격 증명이 제거된 미러 URL입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

예제 응답:

```json
{
  "enabled": true,
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "only_protected_branches": true,
  "keep_divergent_refs": true,
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
  "host_keys": [
    {
      "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
    }
  ]
}
```

## 원격 미러의 공개 키 검색 {#retrieve-a-public-key-for-a-remote-mirror}

{{< history >}}

- [GitLab 17.9에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180291).

{{< /history >}}

SSH 인증을 사용하는 지정된 원격 미러의 공개 키를 검색합니다.

```plaintext
GET /projects/:id/remote_mirrors/:mirror_id/public_key
```

지원되는 속성:

| 특성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `mirror_id` | 정수           | 예      | 원격 미러의 ID입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 특성   | 유형   | 설명                        |
|-------------|--------|------------------------------------|
| `public_key`| 문자열 | 원격 미러의 공개 키입니다.  |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486/public_key"
```

예제 응답:

```json
{
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EA..."
}
```

## 풀 미러 생성 {#create-a-pull-mirror}

프로젝트 풀 미러링 API를 사용하여 [풀 미러 구성](project_pull_mirroring.md#update-project-pull-mirroring-settings) 방법을 알아봅니다.

## 푸시 미러 생성 {#create-a-push-mirror}

{{< history >}}

- GitLab 16.0에서 [기본적으로 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/381667).
- GitLab 16.2에서 [일반적으로 사용 가능합니다](https://gitlab.com/gitlab-org/gitlab/-/issues/410354). 기능 플래그 `mirror_only_branches_match_regex` 제거됨.
- 필드 `auth_method` [GitLab 16.10에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75155).
- 속성 `host_keys` [GitLab 18.4에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435).

{{< /history >}}

> [!note]
> 각 프로젝트는 최대 10개의 활성화된 푸시 미러를 가질 수 있습니다. 자세한 내용은 [프로젝트 푸시 미러의 최대 개수](../administration/instance_limits.md#maximum-number-of-project-push-mirrors)를 참조하세요.

프로젝트의 푸시 미러를 생성합니다. 푸시 미러링은 기본적으로 비활성화됩니다. 활성화하려면 미러를 생성할 때 선택적 매개변수 `enabled`을 포함합니다.

```plaintext
POST /projects/:id/remote_mirrors
```

지원되는 속성:

| 특성                 | 유형              | 필수 | 설명 |
|---------------------------|-------------------|----------|-------------|
| `id`                      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `url`                     | 문자열            | 예      | 리포지토리가 미러링되는 대상 URL입니다. |
| `auth_method`             | 문자열            | 아니요       | 미러 인증 방법입니다. 허용되는 값: `ssh_public_key`, `password`입니다. |
| `enabled`                 | 부울           | 아니요       | `true`이면 미러가 활성화됩니다. |
| `host_keys`               | 문자열 배열  | 아니요       | 베어 형식의 SSH 호스트 키(`ssh-ed25519 AAAA...`) 또는 전체 `known_hosts` 형식(`hostname ssh-ed25519 AAAA...`)입니다. 베어 키는 미러 URL의 호스트 이름을 사용합니다. |
| `keep_divergent_refs`     | 부울           | 아니요       | `true`이면 미러링할 때 발산된 참조가 유지됩니다. |
| `mirror_branch_regex`     | 문자열            | 아니요       | 미러링할 브랜치 이름의 정규 표현식입니다. 정규식과 일치하는 이름의 브랜치만 미러링됩니다. `only_protected_branches`을 비활성화해야 합니다. Premium 및 Ultimate만 해당입니다. |
| `only_protected_branches` | 부울           | 아니요       | `true`이면 보호된 브랜치만 미러링됩니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 특성                   | 유형    | 설명 |
|-----------------------------|---------|-------------|
| `auth_method`               | 문자열  | 미러에 사용된 인증 방법입니다. |
| `enabled`                   | 부울 | `true`이면 미러가 활성화됩니다. |
| `host_keys`                 | 배열   | 원격 미러의 SSH 호스트 키 지문 배열입니다. |
| `id`                        | 정수 | 원격 미러의 ID입니다. |
| `keep_divergent_refs`       | 부울 | `true`이면 미러링할 때 발산된 참조가 유지됩니다. |
| `last_error`                | 문자열  | 마지막 미러 시도의 오류 메시지입니다. 성공한 경우 `null`입니다. |
| `last_successful_update_at` | 문자열  | 마지막 성공한 미러 업데이트의 타임스탬프입니다. ISO 8601 형식입니다. |
| `last_update_at`            | 문자열  | 마지막 미러 시도의 타임스탬프입니다. ISO 8601 형식입니다. |
| `last_update_started_at`    | 문자열  | 마지막 미러 시도가 시작된 타임스탬프입니다. ISO 8601 형식입니다. |
| `only_protected_branches`   | 부울 | `true`이면 보호된 브랜치만 미러링됩니다. |
| `update_status`             | 문자열  | 미러 업데이트의 상태입니다. 가능한 값: `none`, `scheduled`, `started`, `finished`, `failed`입니다. |
| `url`                       | 문자열  | 보안을 위해 자격 증명이 제거된 미러 URL입니다. |

요청 예시:

```shell
curl --request POST \
  --data "url=https://username:token@example.com/gitlab/example.git" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors"
```

예제 응답:

```json
{
    "enabled": false,
    "id": 101486,
    "auth_method": "password",
    "last_error": null,
    "last_successful_update_at": null,
    "last_update_at": null,
    "last_update_started_at": null,
    "only_protected_branches": false,
    "keep_divergent_refs": false,
    "update_status": "none",
    "url": "https://*****:*****@example.com/gitlab/example.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
}
```

## 프로젝트에서 원격 미러 업데이트 {#update-a-remote-mirror-in-a-project}

{{< history >}}

- 필드 `auth_method` [GitLab 16.10에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75155).
- 속성 `host_keys` [GitLab 18.4에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435).

{{< /history >}}

지정된 원격 미러의 구성 또는 운영 상태를 업데이트합니다.

```plaintext
PUT /projects/:id/remote_mirrors/:mirror_id
```

지원되는 속성:

| 특성                 | 유형              | 필수 | 설명 |
|---------------------------|-------------------|----------|-------------|
| `id`                      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `mirror_id`               | 정수           | 예      | 원격 미러의 ID입니다. |
| `auth_method`             | 문자열            | 아니요       | 미러 인증 방법입니다. 허용되는 값: `ssh_public_key`, `password`입니다. |
| `enabled`                 | 부울           | 아니요       | `true`이면 미러가 활성화됩니다. |
| `host_keys`               | 문자열 배열  | 아니요       | 베어 형식의 SSH 호스트 키(`ssh-ed25519 AAAA...`) 또는 전체 `known_hosts` 형식(`hostname ssh-ed25519 AAAA...`)입니다. 베어 키는 미러 URL의 호스트 이름을 사용합니다. |
| `keep_divergent_refs`     | 부울           | 아니요       | `true`이면 미러링할 때 발산된 참조가 유지됩니다. |
| `mirror_branch_regex`     | 문자열            | 아니요       | 미러링할 브랜치 이름의 정규 표현식입니다. 정규식과 일치하는 이름의 브랜치만 미러링됩니다. `only_protected_branches`이 활성화되어 있으면 작동하지 않습니다. Premium 및 Ultimate만 해당입니다. |
| `only_protected_branches` | 부울           | 아니요       | `true`이면 보호된 브랜치만 미러링됩니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 특성                   | 유형    | 설명 |
|-----------------------------|---------|-------------|
| `auth_method`               | 문자열  | 미러에 사용된 인증 방법입니다. |
| `enabled`                   | 부울 | `true`이면 미러가 활성화됩니다. |
| `host_keys`                 | 배열   | 원격 미러의 SSH 호스트 키 지문 배열입니다. |
| `id`                        | 정수 | 원격 미러의 ID입니다. |
| `keep_divergent_refs`       | 부울 | `true`이면 미러링할 때 발산된 참조가 유지됩니다. |
| `last_error`                | 문자열  | 마지막 미러 시도의 오류 메시지입니다. 성공한 경우 `null`입니다. |
| `last_successful_update_at` | 문자열  | 마지막 성공한 미러 업데이트의 타임스탬프입니다. ISO 8601 형식입니다. |
| `last_update_at`            | 문자열  | 마지막 미러 시도의 타임스탬프입니다. ISO 8601 형식입니다. |
| `last_update_started_at`    | 문자열  | 마지막 미러 시도가 시작된 타임스탬프입니다. ISO 8601 형식입니다. |
| `only_protected_branches`   | 부울 | `true`이면 보호된 브랜치만 미러링됩니다. |
| `update_status`             | 문자열  | 미러 업데이트의 상태입니다. 가능한 값: `none`, `scheduled`, `started`, `finished`, `failed`입니다. |
| `url`                       | 문자열  | 보안을 위해 자격 증명이 제거된 미러 URL입니다. |

요청 예시:

```shell
curl --request PUT \
  --data "enabled=false" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

예제 응답:

```json
{
    "enabled": false,
    "id": 101486,
    "auth_method": "password",
    "last_error": null,
    "last_successful_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_started_at": "2020-01-06T17:31:55.864Z",
    "only_protected_branches": true,
    "keep_divergent_refs": true,
    "update_status": "finished",
    "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
}
```

## 푸시 미러 업데이트 강제 {#force-push-mirror-update}

{{< history >}}

- [GitLab 16.11에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/388907).

{{< /history >}}

푸시 미러에 대해 [업데이트를 강제](../user/project/repository/mirror/_index.md#force-an-update)합니다.

```plaintext
POST /projects/:id/remote_mirrors/:mirror_id/sync
```

지원되는 속성:

| 특성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `mirror_id` | 정수           | 예      | 원격 미러의 ID입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486/sync"
```

## 프로젝트에서 원격 미러 삭제 {#delete-a-remote-mirror-from-a-project}

프로젝트에서 지정된 원격 미러를 삭제합니다.

```plaintext
DELETE /projects/:id/remote_mirrors/:mirror_id
```

지원되는 속성:

| 특성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `mirror_id` | 정수           | 예      | 원격 미러의 ID입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```
