---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "OAuth 2.0, 액세스 및 작업 토큰을 사용하여 GitLab REST API로 인증합니다."
title: REST API 인증
---

대부분의 API 요청에는 인증이 필요하거나 인증이 제공되지 않을 때만 공개 데이터를 반환합니다. 인증이 필요하지 않은 경우 각 엔드포인트의 설명서에서 이를 지정합니다. 예를 들어 [`/projects/:id` 엔드포인트](../projects.md#retrieve-a-project)는 인증이 필요하지 않습니다.

GitLab REST API로 여러 가지 방법으로 인증할 수 있습니다:

- [OAuth 2.0 토큰](#oauth-20-tokens)
- [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)
- [프로젝트 액세스 토큰](../../user/project/settings/project_access_tokens.md)
- [그룹 액세스 토큰](../../user/group/settings/group_access_tokens.md)
- [세션 쿠키](#session-cookie)
- [CI/CD 작업 토큰](#job-tokens) (특정 엔드포인트만)

프로젝트 액세스 토큰은(는) 다음에서 지원합니다:

- GitLab Self-Managed:  Free, Premium, Ultimate.
- GitLab.com:  Premium, Ultimate.

관리자인 경우 다음 중 하나를 사용하여 특정 사용자로 인증할 수 있습니다:

- [가장 토큰](#impersonation-tokens)
- [Sudo](#sudo)

인증 정보가 유효하지 않거나 누락된 경우 GitLab은 상태 코드 `401`로 오류 메시지를 반환합니다:

```json
{
  "message": "401 Unauthorized"
}
```

> [!note]
> 배포 토큰은(는) GitLab 공개 API에서 사용할 수 없습니다. 자세한 내용은 [배포 토큰](../../user/project/deploy_tokens/_index.md)을(를) 참조하세요.

## OAuth 2.0 토큰 {#oauth-20-tokens}

[OAuth 2.0 토큰](../oauth2.md)을(를) 사용하여 `access_token` 매개변수 또는 `Authorization` 헤더를 통해 API로 인증할 수 있습니다.

매개변수에서 OAuth 2.0 토큰을 사용하는 예:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects?access_token=OAUTH-TOKEN"
```

헤더에서 OAuth 2.0 토큰을 사용하는 예:

```shell
curl --request GET \
  --header "Authorization: Bearer OAUTH-TOKEN" \
  --url "https://gitlab.example.com/api/v4/projects"
```

[OAuth 2.0 공급자로서의 GitLab](../oauth2.md)에 대해 자세히 알아보세요.

> [!note]
> 모든 OAuth 액세스 토큰은 생성된 후 2시간 동안 유효합니다. `refresh_token` 매개변수를 사용하여 토큰을 새로 고칠 수 있습니다. 새로 고침 토큰을 사용하여 새 액세스 토큰을 요청하는 방법은 [OAuth 2.0 토큰](../oauth2.md) 설명서를 참조하세요.

## 개인, 프로젝트 및 그룹 액세스 토큰 {#personal-project-and-group-access-tokens}

액세스 토큰을 사용하여 API로 인증할 수 있습니다. `PRIVATE-TOKEN` 헤더(권장) 또는 다른 방법을 사용하여 토큰을 전달합니다.

예를 들어 권장되는 헤더 방법을 사용합니다:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects"
```

OAuth 호환 헤더를 사용하여 개인, 프로젝트 또는 그룹 액세스 토큰을 사용할 수도 있습니다. 예를 들어:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects"
```

## 작업 토큰 {#job-tokens}

작업 토큰을 사용하여 [특정 API 엔드포인트](../../ci/jobs/ci_job_token.md#job-token-access)로 인증할 수 있습니다. GitLab CI/CD 작업에서 토큰은 `CI_JOB_TOKEN` 변수로 제공됩니다.

`JOB-TOKEN` 헤더(권장) 또는 다른 방법을 사용하여 토큰을 전달합니다. 모든 인증 방법은 [CI/CD 작업 토큰 인증](../../ci/jobs/ci_job_token.md#rest-api-authentication)을(를) 참조하세요.

예를 들어 헤더 방법을 사용합니다:

```shell
curl --request GET \
  --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --url "https://gitlab.example.com/api/v4/projects/1/releases"
```

## 세션 쿠키 {#session-cookie}

GitLab 메인 애플리케이션에 로그인하면 `_gitlab_session` 쿠키가 설정됩니다. API는 이 쿠키가 있으면 인증에 사용합니다. API를 사용하여 새 세션 쿠키를 생성하는 것은 지원되지 않습니다.

이 인증 방법의 주요 사용자는 GitLab 자체의 웹 프론트엔드입니다. 웹 프론트엔드는 인증된 사용자로 API를 사용하여 액세스 토큰을 명시적으로 전달하지 않고 프로젝트 목록을 가져올 수 있습니다.

## 가장 토큰 {#impersonation-tokens}

가장 토큰은 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)의 한 종류입니다. 관리자만 만들 수 있으며 특정 사용자로 API로 인증하는 데 사용됩니다.

가장 토큰을 다음의 대안으로 사용합니다:

- 사용자의 비밀번호 또는 개인 액세스 토큰 중 하나입니다.
- [Sudo](#sudo) 기능입니다. 사용자의 또는 관리자의 비밀번호 또는 토큰을 모를 수 있으며 시간이 지남에 따라 변경될 수 있습니다.

자세한 내용은 [사용자 토큰 API](../user_tokens.md#create-an-impersonation-token) 설명서를 참조하세요.

가장 토큰은 일반 개인 액세스 토큰과 정확히 같은 방식으로 사용되며 `private_token` 매개변수 또는 `PRIVATE-TOKEN` 헤더를 통해 전달할 수 있습니다.

### 가장 비활성화 {#disable-impersonation}

기본적으로 가장은 활성화되어 있습니다. 가장을 비활성화하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb` 파일을 편집합니다:

   ```ruby
   gitlab_rails['impersonation_enabled'] = false
   ```

1. 파일을 저장한 후 GitLab의 변경 사항을 적용하려면 [재구성](../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `config/gitlab.yml` 파일을 편집합니다:

   ```yaml
   gitlab:
     impersonation_enabled: false
   ```

1. 파일을 저장한 후 GitLab을(를) [다시 시작](../../administration/restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

가장을 다시 활성화하려면 이 구성을 제거하고 GitLab을 재구성(Linux 패키지 설치)하거나 GitLab을 다시 시작(자체 컴파일 설치)합니다.

## Sudo {#sudo}

모든 API 요청은 `sudo` 범위가 있는 OAuth 또는 개인 액세스 토큰으로 관리자로 인증된 경우 다른 사용자인 것처럼 API 요청을 수행하도록 지원합니다. API 요청은 가장된 사용자의 권한으로 실행됩니다.

[관리자](../../user/permissions.md)로서 쿼리 문자열을 사용하거나 `sudo` 매개변수를 사용하여 수행하려는 작업의 사용자 ID 또는 사용자 이름(대소문자 구분 안 함)이 있는 헤더로 전달합니다. 헤더로 전달되는 경우 헤더 이름은 `Sudo`이어야 합니다.

관리자가 아닌 액세스 토큰이 제공되면 GitLab은 상태 코드 `403`로 오류 메시지를 반환합니다:

```json
{
  "message": "403 Forbidden - Must be admin to use sudo"
}
```

`sudo` 범위 없는 액세스 토큰이 제공되면 상태 코드 `403`로 오류 메시지가 반환됩니다:

```json
{
  "error": "insufficient_scope",
  "error_description": "The request requires higher privileges than provided by the access token.",
  "scope": "sudo"
}
```

sudo 사용자 ID 또는 사용자 이름을 찾을 수 없으면 상태 코드 `404`로 오류 메시지가 반환됩니다:

```json
{
  "message": "404 User with ID or username '123' Not Found"
}
```

유효한 API 요청과 sudo 요청을 사용한 cURL 요청의 예, 사용자 이름 제공:

```plaintext
GET /projects?private_token=<your_access_token>&sudo=username
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Sudo: username" \
  --url "https://gitlab.example.com/api/v4/projects"
```

유효한 API 요청과 sudo 요청을 사용한 cURL 요청의 예, ID 제공:

```plaintext
GET /projects?private_token=<your_access_token>&sudo=23
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Sudo: 23" \
  --url "https://gitlab.example.com/api/v4/projects"
```
