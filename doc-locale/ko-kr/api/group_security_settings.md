---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab에서 그룹 보안 설정을 업데이트합니다. 그룹 내의 모든 프로젝트에 대해 비밀 푸시 보호 및 기타 보안 정책을 구성합니다.
title: 그룹 보안 설정 API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.7에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/502827)

{{< /history >}}

그룹 보안 설정에 대한 모든 API 호출은 [인증](rest/authentication.md)되어야 합니다.

사용자가 프라이빗 그룹의 멤버가 아닌 경우, 프라이빗 그룹에 대한 요청은 `404 Not Found` 상태 코드를 반환합니다.

## 그룹 보안 설정 업데이트 {#update-group-security-settings}

지정된 그룹의 그룹 보안 설정을 업데이트합니다.

전제 조건:

- 그룹에 대해 보안 관리자, Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
PUT /groups/:id/security_settings
```

| 속성                        | 유형              | 필수 | 설명 |
| -------------------------------- | ----------------- | -------- | ----------- |
| `id`                             | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `secret_push_protection_enabled` | 부울           | 예      | 그룹의 프로젝트에 대해 비밀 푸시 보호를 활성화합니다. |
| `projects_to_exclude`            | 정수 배열 | 아니요       | 비밀 푸시 보호에서 제외할 프로젝트의 ID입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/7/security_settings?secret_push_protection_enabled=true&projects_to_exclude[]=1&projects_to_exclude[]=2"
```

응답 예시:

```json
{
  "secret_push_protection_enabled": true,
  "errors": []
}
```
