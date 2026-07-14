---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 보안 설정 API
description: 보안 푸시 보호와 같은 프로젝트 보안 옵션을 나열하고 업데이트하는 API 엔드포인트입니다.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

프로젝트 보안 설정에 대한 모든 API 호출은 [인증](rest/authentication.md)되어야 합니다.

프로젝트가 비공개이고 사용자가 보안 설정이 속한 프로젝트의 멤버가 아닌 경우, 해당 프로젝트에 대한 요청은 `404 Not Found` 상태 코드를 반환합니다.

## 모든 프로젝트 보안 설정 나열 {#list-all-project-security-settings}

프로젝트의 모든 보안 설정을 나열합니다.

전제 조건:

- 프로젝트에 대해 보안 관리자, Developer, Maintainer 또는 Owner 역할이 필요합니다.

```plaintext
GET /projects/:id/security_settings
```

| 속성     | 유형           | 필수 | 설명                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.                                                            |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/security_settings"
```

응답 예시:

```json
{
    "project_id": 7,
    "created_at": "2024-08-27T15:30:33.075Z",
    "updated_at": "2024-10-16T05:09:22.233Z",
    "auto_fix_container_scanning": true,
    "auto_fix_dast": true,
    "auto_fix_dependency_scanning": true,
    "auto_fix_sast": true,
    "continuous_vulnerability_scans_enabled": true,
    "container_scanning_for_registry_enabled": false,
    "secret_push_protection_enabled": true
}
```

## `secret_push_protection_enabled` 설정 업데이트 {#update-the-secret_push_protection_enabled-setting}

{{< history >}}

- GitLab 17.11에서 [이름 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185310)되었습니다 `pre_receive_secret_detection_enabled`

{{< /history >}}

지정된 프로젝트에 대해 `secret_push_protection_enabled` 설정을 업데이트합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
PUT /projects/:id/security_settings
```

| 속성                        | 유형              | 필수 | 설명 |
| -------------------------------- | ----------------- | -------- | ----------- |
| `id`                             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `secret_push_protection_enabled` | 부울           | 예      | 프로젝트에 대해 보안 푸시 보호를 활성화합니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "secret_push_protection_enabled=false" \
  --url "https://gitlab.example.com/api/v4/projects/7/security_settings"
```

응답 예시:

```json
{
    "project_id": 7,
    "created_at": "2024-08-27T15:30:33.075Z",
    "updated_at": "2024-10-16T05:09:22.233Z",
    "auto_fix_container_scanning": true,
    "auto_fix_dast": true,
    "auto_fix_dependency_scanning": true,
    "auto_fix_sast": true,
    "continuous_vulnerability_scans_enabled": true,
    "container_scanning_for_registry_enabled": false,
    "secret_push_protection_enabled": false
}
```
