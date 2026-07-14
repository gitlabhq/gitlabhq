---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 토큰 정보를 노출하는 REST API에 대한 문서입니다.
title: 토큰 정보 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 상태:  실험적 기능

{{< /details >}}

이 API를 사용하여 임의의 토큰에 대한 세부 정보를 검색하고 해지합니다. 토큰 정보를 노출하는 다른 API와 달리, 이 API를 사용하면 특정 토큰 유형을 알지 못해도 토큰의 세부 정보를 검색하거나 해지할 수 있습니다.

## 토큰 접두사 {#token-prefixes}

요청할 때 `personal`, `project` 또는 `group access` 토큰은 `glpat` 또는 현재 [사용자 지정 접두사](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)로 시작해야 합니다. 토큰이 이전 사용자 지정 접두사로 시작하면 작업이 실패합니다. 이전 사용자 지정 접두사 지원에 대한 관심은 [이슈 165663](https://gitlab.com/gitlab-org/gitlab/-/issues/165663)에서 추적됩니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

## 토큰 정보 검색 {#retrieve-token-information}

{{< history >}}

- GitLab 17.5에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165157) [기능 플래그](../../administration/feature_flags/_index.md) `admin_agnostic_token_finder`. 기본적으로 비활성화됨.
- GitLab 17.8에 [일반적으로 제공됨](https://gitlab.com/gitlab-org/gitlab/-/issues/490572). 기능 플래그 `admin_agnostic_token_finder` 제거됨.
- GitLab 17.6에 [피드 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169821).
- GitLab 17.7에 [OAuth 애플리케이션 시크릿 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172985).
- GitLab 17.7에 [클러스터 에이전트 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172932).
- GitLab 17.7에 [러너 인증 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173987).
- GitLab 17.7에 [파이프라인 트리거 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174030).
- GitLab 17.9에 [CI/CD 작업 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175234).
- GitLab 17.9에 [기능 플래그 클라이언트 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177431).
- GitLab 17.9에 [GitLab 세션 쿠키 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178022).
- GitLab 17.9에 [수신 이메일 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177077).

{{< /history >}}

지정된 토큰에 대한 정보를 검색합니다. 이 엔드포인트는 다음 토큰을 지원합니다:

- [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)
- [가장 토큰](../rest/authentication.md#impersonation-tokens)
- [배포 토큰](../../user/project/deploy_tokens/_index.md)
- [피드 토큰](../../security/tokens/_index.md#feed-token)
- [OAuth 애플리케이션 시크릿](../../integration/oauth_provider.md)
- [클러스터 에이전트 토큰](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)
- [러너 인증 토큰](../../security/tokens/_index.md#runner-authentication-tokens)
- [파이프라인 트리거 토큰](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)
- [CI/CD 작업 토큰](../../security/tokens/_index.md#cicd-job-tokens)
- [기능 플래그 클라이언트 토큰](../../operations/feature_flags.md#get-access-credentials)
- [GitLab 세션 쿠키](../../user/profile/active_sessions.md)
- [수신 이메일 토큰](../../security/tokens/_index.md#incoming-email-token)

```plaintext
POST /api/v4/admin/token
```

지원되는 속성:

| 속성    | 유형    | 필수 | 설명                |
|--------------|---------|----------|----------------------------|
| `token`      | 문자열  | 예      | 식별할 기존 토큰입니다. `Personal`, `project` 또는 `group access` 토큰은 `glpat` 또는 현재 [사용자 지정 접두사](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)로 시작해야 합니다. |

성공하면 [`200`](../rest/troubleshooting.md#status-codes)과 토큰에 대한 정보를 반환합니다.

다음 상태 코드를 반환할 수 있습니다:

- `200 OK`:  토큰에 대한 정보입니다.
- `401 Unauthorized`:  사용자가 권한을 부여받지 않았습니다.
- `403 Forbidden`:  사용자가 관리자가 아닙니다.
- `404 Not Found`:  토큰을 찾을 수 없습니다.
- `422 Unprocessable`:  토큰 유형은 지원되지 않습니다.

요청 예:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/admin/token" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"token": "glpat-<example-token>"}'
```

응답 예:

```json
{
 "id": 1,
 "user_id": 70,
 "name": "project-access-token",
 "revoked": false,
 "expires_at": "2024-10-04",
 "created_at": "2024-09-04T07:19:18.652Z",
 "updated_at": "2024-09-04T07:19:18.652Z",
 "scopes": [
  "api",
  "read_api"
 ],
 "impersonation": false,
 "expire_notification_delivered": false,
 "last_used_at": null,
 "after_expiry_notification_delivered": false,
 "previous_personal_access_token_id": null,
 "advanced_scopes": null,
 "organization_id": 1
}
```

## 토큰 해지 {#revoke-a-token}

{{< history >}}

- GitLab 17.9에 [클러스터 에이전트 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178211).
- GitLab 17.9에 [러너 인증 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179066).
- GitLab 17.9에 [OAuth 애플리케이션 시크릿 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179035).
- GitLab 17.9에 [수신 이메일 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180763).
- GitLab 17.9에 [기능 플래그 클라이언트 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181096).
- GitLab 17.10에 [파이프라인 트리거 토큰 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181598) [기능 플래그](../../administration/feature_flags/_index.md) `token_api_expire_pipeline_triggers`. 기본적으로 비활성화됨.
- GitLab 17.11에 [GitLab 세션 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184047).

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 이 기능은 테스트용으로 사용할 수 있지만, 프로덕션 환경에서 사용할 준비가 되지 않았습니다.

토큰 유형에 따라 지정된 토큰을 해지, 재설정 또는 삭제합니다. 이 엔드포인트는 다음 토큰 유형을 지원합니다:

| 토큰 유형                                                                                   | 지원되는 작업   |
|----------------------------------------------------------------------------------------------|--------------------|
| [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)                       | 해지             |
| [가장 토큰](../../user/profile/personal_access_tokens.md)                         | 해지             |
| [프로젝트 액세스 토큰](../../security/tokens/_index.md#project-access-tokens)               | 해지             |
| [그룹 액세스 토큰](../../security/tokens/_index.md#group-access-tokens)                   | 해지             |
| [배포 토큰](../../user/project/deploy_tokens/_index.md)                                   | 해지             |
| [클러스터 에이전트 토큰](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)          | 해지             |
| [파이프라인 트리거 토큰](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)       | 해지             |
| [피드 토큰](../../security/tokens/_index.md#feed-token)                                    | 재설정              |
| [러너 인증 토큰](../../security/tokens/_index.md#runner-authentication-tokens) | 재설정              |
| [OAuth 애플리케이션 시크릿](../../integration/oauth_provider.md)                             | 재설정              |
| [수신 이메일 토큰](../../security/tokens/_index.md#incoming-email-token)                | 재설정              |
| [기능 플래그 클라이언트 토큰](../../operations/feature_flags.md#get-access-credentials)      | 재설정              |
| [GitLab 세션 쿠키](../../user/profile/active_sessions.md)                              | 삭제             |

```plaintext
DELETE /api/v4/admin/token
```

지원되는 속성:

| 속성    | 유형    | 필수 | 설명              |
|--------------|---------|----------|--------------------------|
| `token`      | 문자열  | 예      | 해지할 기존 토큰입니다. `Personal`, `project` 또는 `group access` 토큰은 `glpat` 또는 현재 [사용자 지정 접두사](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)로 시작해야 합니다. |

성공하면 [`204`](../rest/troubleshooting.md#status-codes)을 콘텐츠 없이 반환합니다.

다음 상태 코드를 반환할 수 있습니다:

- `204 No content`:  토큰이 해지되었습니다.
- `401 Unauthorized`:  사용자가 권한을 부여받지 않았습니다.
- `403 Forbidden`:  사용자가 관리자가 아닙니다.
- `404 Not Found`:  토큰을 찾을 수 없습니다.
- `422 Unprocessable`:  토큰 유형은 지원되지 않습니다.

요청 예:

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/admin/token" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"token": "glpat-<example-token>"}'
```
