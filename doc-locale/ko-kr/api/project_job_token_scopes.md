---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 작업 토큰 범위 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [CI/CD 작업 토큰](../ci/jobs/ci_job_token.md) 범위와 상호 작용합니다.

> [!note]
> CI/CD 작업 토큰 범위 API 엔드포인트에 대한 모든 요청은 [인증](rest/authentication.md)되어야 합니다. 인증된 사용자는 프로젝트에 대한 유지 관리자 또는 소유자 역할이 있어야 합니다.

## 프로젝트의 CI/CD 작업 토큰 액세스 설정 검색 {#retrieve-the-cicd-job-token-access-settings-for-a-project}

지정된 프로젝트의 [CI/CD 작업 토큰 액세스 설정](../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project) (작업 토큰 범위)을 검색합니다.

```plaintext
GET /projects/:id/job_token_scope
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성          | 유형    | 설명 |
|--------------------|---------|-------------|
| `inbound_enabled`  | 부울 | [**승인된 그룹 및 프로젝트**](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) 설정이 허용 목록에 대해 활성화되어 있는지를 나타냅니다. 비활성화되면 [모든 프로젝트가 액세스할 수 있습니다](../ci/jobs/ci_job_token.md#allow-any-project-to-access-your-project). 이 값은 허용 목록이 현재 활성 상태인지 여부를 표시하며, [**Enforce job token allowlist**](../administration/settings/continuous_integration.md#enforce-job-token-allowlist) 인스턴스 설정으로 인해 `true`일 수 있습니다. |
| `outbound_enabled` | 부울 | 이 프로젝트에서 생성된 CI/CD 작업 토큰이 다른 프로젝트에 액세스할 수 있는지 여부를 나타냅니다. [지원 중단되었으며 GitLab 18.0에서 제거될 예정](../update/deprecations.md#cicd-job-token---limit-access-from-your-project-setting-removal)입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope"
```

응답 예시:

```json
{
  "inbound_enabled": true,
  "outbound_enabled": false
}
```

## 프로젝트의 CI/CD 작업 토큰 액세스 설정 업데이트 {#update-the-cicd-job-token-access-settings-for-a-project}

{{< history >}}

- [이름이 변경](https://gitlab.com/gitlab-org/gitlab/-/issues/411406)되었습니다. **Allow access to this project with a CI_JOB_TOKEN**에서 **Limit access to this project**으로 GitLab 16.3에서 변경되었습니다.
- [이름이 변경](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)되었습니다. **Limit access to this project**에서 **승인된 그룹 및 프로젝트**로 GitLab 17.2에서 변경되었습니다.

{{< /history >}}

지정된 프로젝트의 [**승인된 그룹 및 프로젝트** 설정](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) (작업 토큰 범위)을 업데이트합니다.

```plaintext
PATCH /projects/:id/job_token_scope
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `enabled` | 부울           | 예      | 작업 토큰 액세스를 허용 목록에 있는 프로젝트로만 제한합니다. `false`로 설정하여 모든 프로젝트의 액세스를 허용합니다. 이 매개변수는 [**Enforce job token allowlist**](../administration/settings/continuous_integration.md#enforce-job-token-allowlist) 인스턴스 설정으로 재정의될 수 있습니다. |

성공하면 [`204`](rest/troubleshooting.md#status-codes)를 반환하고 응답 본문이 없습니다.

**Enforce job token allowlist** 인스턴스 설정이 활성화되었으며 `enabled`을(를) `false`로 설정하려고 시도하면 [`400`](rest/troubleshooting.md#status-codes)를 반환하고 오류 메시지가 표시됩니다.

요청 예시:

```shell
curl --request PATCH \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "enabled": false }'
```

## CI/CD 작업 토큰 허용 목록의 모든 프로젝트 나열 {#list-all-projects-in-a-cicd-job-token-allowlist}

지정된 프로젝트의 [CI/CD 작업 토큰 허용 목록](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)에 있는 모든 프로젝트를 나열합니다.

```plaintext
GET /projects/:id/job_token_scope/allowlist
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

이 엔드포인트는 [오프셋 기반 페이지 표시](rest/_index.md#offset-based-pagination)를 지원합니다.

성공하면 [`200`](rest/troubleshooting.md#status-codes)를 반환하고 각 프로젝트에 대해 제한된 필드가 있는 프로젝트 목록을 반환합니다.

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist"
```

응답 예시:

```json
[
  {
    "id": 4,
    "description": null,
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "star_count": 0,
    "last_activity_at": "2013-09-30T13:46:02Z",
    "namespace": {
      "id": 2,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/diaspora"
    }
  },
  {
    ...
  }
```

## CI/CD 작업 토큰 허용 목록에 프로젝트 추가 {#add-a-project-to-a-cicd-job-token-allowlist}

지정된 프로젝트의 [CI/CD 작업 토큰 허용 목록](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)에 프로젝트를 추가합니다.

```plaintext
POST /projects/:id/job_token_scope/allowlist
```

지원되는 속성:

| 속성           | 유형           | 필수 | 설명 |
|---------------------|----------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `target_project_id` | 정수        | 예      | CI/CD 작업 토큰 인바운드 허용 목록에 추가되는 프로젝트의 ID입니다. |

성공하면 [`201`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형    | 설명 |
|---------------------|---------|-------------|
| `source_project_id` | 정수 | CI/CD 작업 토큰 인바운드 허용 목록을 업데이트할 프로젝트의 ID입니다. |
| `target_project_id` | 정수 | 소스 프로젝트의 인바운드 허용 목록에 추가되는 프로젝트의 ID입니다. |

요청 예시:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "target_project_id": 2 }'
```

응답 예시:

```json
{
  "source_project_id": 1,
  "target_project_id": 2
}
```

## CI/CD 작업 토큰 허용 목록에서 프로젝트 삭제 {#delete-a-project-from-a-cicd-job-token-allowlist}

지정된 프로젝트의 [CI/CD 작업 토큰 허용 목록](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)에서 프로젝트를 삭제합니다.

```plaintext
DELETE /projects/:id/job_token_scope/allowlist/:target_project_id
```

지원되는 속성:

| 속성           | 유형           | 필수 | 설명 |
|---------------------|----------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `target_project_id` | 정수        | 예      | CI/CD 작업 토큰 인바운드 허용 목록에서 제거되는 프로젝트의 ID입니다. |

성공하면 [`204`](rest/troubleshooting.md#status-codes)를 반환하고 응답 본문이 없습니다.

요청 예시:

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist/2" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json'
```

## CI/CD 작업 토큰 허용 목록의 모든 그룹 나열 {#list-all-groups-in-a-cicd-job-token-allowlist}

지정된 프로젝트의 [CI/CD 작업 토큰 허용 목록](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)에 있는 모든 그룹을 나열합니다.

```plaintext
GET /projects/:id/job_token_scope/groups_allowlist
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

이 엔드포인트는 [오프셋 기반 페이지 표시](rest/_index.md#offset-based-pagination)를 지원합니다.

성공하면 [`200`](rest/troubleshooting.md#status-codes)를 반환하고 각 프로젝트에 대해 제한된 필드가 있는 그룹 목록을 반환합니다.

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist"
```

응답 예시:

```json
[
  {
    "id": 4,
    "web_url": "https://gitlab.example.com/groups/diaspora/diaspora-group",
    "name": "namegroup"
  },
  {
    ...
  }
]
```

## CI/CD 작업 토큰 허용 목록에 그룹 추가 {#add-a-group-to-a-cicd-job-token-allowlist}

지정된 프로젝트의 [CI/CD 작업 토큰 허용 목록](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)에 그룹을 추가합니다.

```plaintext
POST /projects/:id/job_token_scope/groups_allowlist
```

지원되는 속성:

| 속성         | 유형           | 필수 | 설명 |
|-------------------|----------------|----------|-------------|
| `id`              | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `target_group_id` | 정수        | 예      | CI/CD 작업 토큰 그룹 허용 목록에 추가되는 그룹의 ID입니다. |

성공하면 [`201`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형    | 설명 |
|---------------------|---------|-------------|
| `source_project_id` | 정수 | CI/CD 작업 토큰 인바운드 허용 목록을 업데이트할 프로젝트의 ID입니다. |
| `target_group_id`   | 정수 | 소스 프로젝트의 그룹 허용 목록에 추가되는 그룹의 ID입니다. |

요청 예시:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "target_group_id": 2 }'
```

응답 예시:

```json
{
  "source_project_id": 1,
  "target_group_id": 2
}
```

## CI/CD 작업 토큰 허용 목록에서 그룹 삭제 {#delete-a-group-from-a-cicd-job-token-allowlist}

지정된 프로젝트의 [CI/CD 작업 토큰 허용 목록](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)에서 그룹을 삭제합니다.

```plaintext
DELETE /projects/:id/job_token_scope/groups_allowlist/:target_group_id
```

지원되는 속성:

| 속성         | 유형           | 필수 | 설명 |
|-------------------|----------------|----------|-------------|
| `id`              | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `target_group_id` | 정수        | 예      | CI/CD 작업 토큰 그룹 허용 목록에서 제거되는 그룹의 ID입니다. |

성공하면 [`204`](rest/troubleshooting.md#status-codes)를 반환하고 응답 본문이 없습니다.

요청 예시:

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist/2" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json'
```
