---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab for Jira Cloud 앱 관리 문제 해결
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab for Jira Cloud 앱을 관리할 때 다음 이슈가 발생할 수 있습니다.

사용자 문제 해결은 [GitLab for Jira Cloud app](../../integration/jira/connect-app.md#troubleshooting)을 참조하세요.

## 이미 로그인했을 때 표시되는 로그인 메시지 {#sign-in-message-displayed-when-already-signed-in}

이미 로그인했을 때 GitLab.com에 로그인하도록 요청하는 다음 메시지를 받을 수 있습니다:

```plaintext
Sign in or sign up before continuing.
```

GitLab for Jira Cloud 앱은 iframe을 사용하여 설정 페이지에 그룹을 추가합니다. 일부 브라우저는 교차 사이트 쿠키를 차단하므로 이 이슈가 발생할 수 있습니다.

이 이슈를 해결하려면 [OAuth authentication](jira_cloud_app.md#set-up-oauth-authentication)을 설정하세요.

## 수동 설치 실패 {#manual-installation-fails}

공식 마켓플레이스 목록에서 GitLab for Jira Cloud 앱을 설치한 후 [manual installation](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)으로 바꾼 경우 다음 오류 중 하나를 받을 수 있습니다:

```plaintext
The app "gitlab-jira-connect-gitlab.com" could not be installed as a local app as it has previously been installed from Atlassian Marketplace
```

```plaintext
The app host returned HTTP response code 401 when we tried to contact it during installation. Please try again later or contact the app vendor.
```

이 이슈를 해결하려면 **Jira Connect 프록시 URL** 설정을 비활성화하세요.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

**Jira Connect 프록시 URL** 설정을 비활성화하려면:

- GitLab 15.7에서:
  1. [Rails console](../operations/rails_console.md#starting-a-rails-console-session)을 엽니다.
  1. `ApplicationSetting.current_without_cache.update(jira_connect_proxy_url: nil)`을 실행합니다.
- GitLab 15.8 이상:
  1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
  1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
  1. **Jira 앱용 GitLab**을 확장합니다.
  1. **Jira Connect 프록시 URL** 텍스트 상자를 지웁니다.
  1. **변경 사항 저장**을 선택합니다.

이슈가 계속되면 인스턴스가 `connect-install-keys.atlassian.com`에 연결되어 Atlassian에서 공개 키를 가져올 수 있는지 확인하세요. 연결을 테스트하려면 다음 명령을 실행하세요:

```shell
# A `404 Not Found` is expected because you're not passing a token
curl --head "https://connect-install-keys.atlassian.com"
```

## GitLab for Jira Cloud 앱 설치 변경 사항 검토 {#review-installation-changes-to-the-gitlab-for-jira-cloud-app}

GitLab for Jira Cloud 앱의 설치 변경 사항을 검토하는 여러 방법이 있습니다. 자세한 내용은 공식 [Jira documentation](https://support.atlassian.com/jira/kb/how-to-check-who-installed-enabled-disabled-uninstalled-plugin-in-jira/)을 참조하세요.

## 데이터 동기화가 `Invalid JWT` 실패 {#data-sync-fails-with-invalid-jwt}

GitLab for Jira Cloud 앱이 인스턴스에서 데이터 동기화를 계속 실패하면 비밀 토큰이 오래되었을 수 있습니다. Atlassian은 새로운 비밀 토큰을 GitLab에 보낼 수 있습니다. GitLab이 이 토큰을 처리하거나 저장하지 못하면 `Invalid JWT` 오류가 발생합니다.

이 이슈를 해결하려면:

- 인스턴스가 다음에 공개적으로 액세스할 수 있는지 확인하세요:
  - GitLab.com (지만 [installed the app from the official Atlassian Marketplace listing](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace)한 경우).
  - Jira Cloud (지만 [installed the app manually](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)한 경우).
- 앱을 설치할 때 `/-/jira_connect/events/installed` 엔드포인트로 전송된 토큰 요청이 Jira에서 액세스할 수 있는지 확인하세요. 다음 명령은 `401 Unauthorized`을 반환해야 합니다:

  ```shell
  curl --include --request POST "https://gitlab.example.com/-/jira_connect/events/installed"
  ```

- 인스턴스에 [SSL configured](https://docs.gitlab.com/omnibus/settings/ssl/) 가 있으면 [certificates are valid and publicly trusted](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting/#useful-openssl-debugging-commands)인지 확인하세요.

앱을 설치한 방법에 따라 다음을 확인할 수도 있습니다:

- 지만 [installed the app from the official Atlassian Marketplace listing](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace)한 경우 GitLab for Jira Cloud 앱에서 GitLab 버전을 전환하세요:

  <!-- markdownlint-disable MD044 -->

  1. Jira에서 **Apps** 옆의 가로 줄임표({{< icon name="ellipsis_h" >}})를 선택하고 **Manage your apps**를 선택합니다.

  1. 다음 방법 중 하나를 사용하여 앱으로 이동합니다:

     **For instances with centralized app management:**

     1. "App management has moved to Administration"이 표시되면 **Take me there**를 선택합니다. 그렇지 않으면 아래의 **For instances with legacy app management** 지침을 따릅니다.
     1. **Installed apps** 탭에서 **GitLab for Jira (gitlab.com)** 앱을 찾은 다음 가로 줄임표({{< icon name="ellipsis_h" >}})를 선택하고 **시작하기**를 선택합니다.

     **For instances with legacy app management:**

     1. **GitLab for Jira (gitlab.com)** 앱을 찾은 다음 chevron({{< icon name="chevron-right" >}})을 선택하고 **시작하기**를 선택합니다.

  1. **GitLab 버전 변경**를 선택합니다.
  1. **GitLab.com (SaaS)**를 선택한 후 **저장**를 선택합니다.
  1. **GitLab 버전 변경**을 다시 선택합니다.
  1. **GitLab (Self-Managed)**를 선택한 후 **다음**를 선택합니다.
  1. 모든 체크박스를 선택한 다음 **다음**를 선택합니다.
  1. **GitLab 인스턴스 URL**을 입력한 다음 **저장**를 선택합니다.

  <!-- markdownlint-enable MD044 -->

  이 방법이 작동하지 않으면 Premium 또는 Ultimate 고객인 경우 [submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new)을 합니다. GitLab 인스턴스 URL 및 Jira URL을 제공합니다. GitLab Support는 다음 스크립트를 실행하여 이슈를 해결할 수 있습니다:

  ```ruby
  # Check if GitLab.com can connect to the GitLab Self-Managed instance
  checker = Gitlab::TcpChecker.new("gitlab.example.com", 443)

  # Returns `true` if successful
  checker.check

  # Returns an error if the check fails
  checker.error
  ```

  ```ruby
  # Locate the installation record for the GitLab Self-Managed instance
  installation = JiraConnectInstallation.find_by_instance_url("https://gitlab.example.com")

  # Try to send the token again from GitLab.com to the GitLab Self-Managed instance
  ProxyLifecycleEventService.execute(installation, :installed, installation.instance_url)
  ```

- 지만 [installed the app manually](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)한 경우:
  - [Jira Cloud Support](https://support.atlassian.com/jira-software-cloud/)에 Jira가 인스턴스에 연결할 수 있는지 확인하도록 요청합니다.
  - [Reinstall the app](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)합니다. 이 방법은 [synced data](../../integration/jira/connect-app.md#gitlab-data-synced-to-jira) 를 모두 [Jira development panel](../../integration/jira/development_panel.md)에서 제거할 수 있습니다.

## 오류: `Failed to update the GitLab instance` {#error-failed-to-update-the-gitlab-instance}

GitLab for Jira Cloud 앱을 설정할 때 GitLab Self-Managed 인스턴스 URL을 입력한 후 `Failed to update the GitLab instance` 오류가 발생할 수 있습니다.

이 이슈를 해결하려면 설치 방법에 대한 모든 전제 조건이 충족되었는지 확인하세요:

- [Prerequisites for connecting the GitLab for Jira Cloud app](jira_cloud_app.md#prerequisites)
- [Prerequisites for installing the GitLab for Jira Cloud app manually](jira_cloud_app.md#prerequisites-1)

Jira Connect Proxy URL을 구성했고 전제 조건을 확인한 후에도 이슈가 계속되면 [Debugging Jira Connect Proxy issues](#debugging-jira-connect-proxy-issues)를 검토하세요.

GitLab 15.8 이하를 사용 중이고 이전에 `jira_connect_oauth_self_managed` 및 `jira_connect_oauth` 기능 플래그를 모두 활성화한 경우 [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388943) 때문에 `jira_connect_oauth_self_managed` 플래그를 비활성화해야 합니다. 이 플래그를 확인하려면:

1. [Rails console](../operations/rails_console.md#starting-a-rails-console-session)을 엽니다.
1. 다음 코드를 실행합니다:

   ```ruby
   # Check if both feature flags are enabled.
   # If the flags are enabled, these commands return `true`.
   Feature.enabled?(:jira_connect_oauth)
   Feature.enabled?(:jira_connect_oauth_self_managed)

   # If both flags are enabled, disable the `jira_connect_oauth_self_managed` flag.
   Feature.disable(:jira_connect_oauth_self_managed)
   ```

### 오류: `Invalid audience` {#error-invalid-audience}

[reverse proxy](jira_cloud_app.md#using-a-reverse-proxy) 를 사용 중인 경우 [`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog)에 다음과 같은 메시지가 포함될 수 있습니다:

```plaintext
Invalid audience. Expected https://proxy.example.com/-/jira_connect, received https://gitlab.example.com/-/jira_connect
```

이 이슈를 해결하려면 역방향 프록시 FQDN을 [additional JWT audience](jira_cloud_app.md#set-an-additional-jwt-audience)로 설정하세요.

### Jira Connect 프록시 이슈 디버깅 {#debugging-jira-connect-proxy-issues}

**Jira Connect 프록시 URL**을 `https://gitlab.com`으로 설정하면 [set up your instance](jira_cloud_app.md#set-up-your-instance-for-atlassian-marketplace-installation)할 때 다음을 수행할 수 있습니다:

- 브라우저의 개발자 도구에서 네트워크 트래픽을 검사합니다.
- `Failed to update the GitLab instance` 오류를 재현하여 자세한 정보를 얻습니다.

`GET` 요청을 `https://gitlab.com/-/jira_connect/installations`로 봐야 합니다.

이 요청은 `200 OK`을 반환해야 하지만 문제가 있으면 `422 Unprocessable Entity`을 반환할 수 있습니다. 응답 본문에서 오류를 확인할 수 있습니다.

이슈를 해결할 수 없고 GitLab 고객인 경우 [GitLab Support](https://about.gitlab.com/support/)에 문의하세요. GitLab Support에 다음을 제공합니다:

- GitLab Self-Managed 인스턴스 URL입니다.
- GitLab.com 사용자 이름입니다.
- 선택사항. 실패한 `GET` 요청에 대한 `X-Request-Id` 응답 헤더를 `https://gitlab.com/-/jira_connect/installations`으로 봅니다.
- 선택사항. [A HAR file](https://support.zendesk.com/hc/en-us/articles/4408828867098-Generating-a-HAR-file-for-troubleshooting) 을 [`harcleaner`](https://gitlab.com/gitlab-com/support/toolbox/harcleaner)으로 처리하여 이슈를 캡처합니다.

GitLab Support는 GitLab.com 서버 로그에서 이슈를 조사할 수 있습니다.

#### GitLab Support {#gitlab-support}

> [!note]
> 이 단계는 GitLab Support에서만 완료할 수 있습니다.

Jira Connect 프록시 URL `https://gitlab.com/-/jira_connect/installations`로 만든 각 `GET` 요청은 두 개의 로그 항목을 생성합니다.

Kibana에서 관련 로그 항목을 찾으려면 다음 중 하나를 수행합니다:

- `X-Request-Id` 값 또는 `GET` 요청에 대한 연관 ID가 `https://gitlab.com/-/jira_connect/installations`인 경우 [Kibana](https://log.gprd.gitlab.net/app/r/s/0FdPP) 로그를 `json.meta.caller_id: JiraConnect::InstallationsController#update`, `NOT json.status: 200` 및 `json.correlation_id: <X-Request-Id>`로 필터링해야 합니다. 이렇게 하면 두 개의 로그 항목이 반환됩니다.

- 고객의 자체 관리 URL이 있으면:
  1. [Kibana](https://log.gprd.gitlab.net/app/r/s/QVsD4) 로그를 `json.meta.caller_id: JiraConnect::InstallationsController#update`, `NOT json.status: 200` 및 `json.params.value: {"instance_url"=>"https://gitlab.example.com"}`로 필터링해야 합니다. 자체 관리 URL에는 선행 슬래시가 없어야 합니다. 이렇게 하면 로그 항목 중 하나가 반환됩니다.
  1. `json.correlation_id`을 필터에 추가합니다.
  1. `json.params.value` 필터를 제거합니다. 이렇게 하면 다른 로그 항목이 반환됩니다.

첫 번째 로그의 경우:

- `json.status`은 `422 Unprocessable Entity`입니다.
- `json.params.value`은 GitLab Self-Managed URL `[[FILTERED], {"instance_url"=>"https://gitlab.example.com"}]`과 일치해야 합니다.

두 번째 로그의 경우 다음 시나리오 중 하나가 있을 수 있습니다:

- 시나리오 1:
  - `json.message`, `json.jira_status_code` 및 `json.jira_body`이 있습니다.
  - `json.message`은 `Proxy lifecycle event received error response` 또는 유사합니다.
  - `json.jira_status_code` 및 `json.jira_body`에는 GitLab Self-Managed 인스턴스 또는 인스턴스 앞의 프록시에서 수신한 응답이 포함될 수 있습니다.
  - `json.jira_status_code`이 `401 Unauthorized`이고 `json.jira_body`이 `(empty)`인 경우:
    - [**Jira Connect 프록시 URL**](jira_cloud_app.md#set-up-your-instance-for-atlassian-marketplace-installation)이 `https://gitlab.com`으로 설정되지 않았을 수 있습니다.
    - GitLab Self-Managed 인스턴스가 발신 연결을 차단할 수 있습니다. GitLab Self-Managed 인스턴스가 `connect-install-keys.atlassian.com` 및 `gitlab.com` 모두에 연결할 수 있는지 확인합니다.
    - GitLab Self-Managed 인스턴스는 Jira의 JWT 토큰을 해독할 수 없습니다. [From GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147234) 에서 [`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog)에는 오류에 대한 자세한 정보가 포함됩니다.
    - GitLab Self-Managed 인스턴스 앞에 [reverse proxy](jira_cloud_app.md#using-a-reverse-proxy)가 있으면 GitLab Self-Managed 인스턴스로 전송된 `Host` 헤더가 역방향 프록시 FQDN과 일치하지 않을 수 있습니다. GitLab Self-Managed 인스턴스의 [Workhorse logs](../logs/_index.md#workhorse-logs)를 확인합니다:

      ```shell
      grep /-/jira_connect/events/installed /var/log/gitlab/gitlab-workhorse/current
      ```

      출력에는 다음이 포함될 수 있습니다:

      ```json
      {
        "host":"gitlab.mycompany.com:443", // The host should match the reverse proxy FQDN entered into the GitLab for Jira Cloud app
        "remote_ip":"34.74.226.3", // This IP should be within the GitLab.com IP range https://docs.gitlab.com/user/gitlab_com/#ip-range
        "status":401,
        "uri":"/-/jira_connect/events/installed"
      }
      ```

  - `json.jira_status_code`이 `404 Not Found`이고 `json.jira_body`에 일반적인 GitLab 404 페이지의 HTML이 포함된 경우 자체 관리 인스턴스의 [integration allowlist](project_integration_management.md#integration-allowlist)가 GitLab for Jira Cloud 앱을 허용하는지 확인합니다.

- 시나리오 2:
  - `json.exception.class` 및 `json.exception.message`이 있습니다.
  - `json.exception.class` 및 `json.exception.message`에는 GitLab Self-Managed 인스턴스에 연결하는 동안 이슈가 발생했는지 여부가 포함됩니다.

## 오류: `The Jira user is not a site or organization administrator` {#error-the-jira-user-is-not-a-site-or-organization-administrator}

GitLab 그룹을 연결하려고 하면 다음 오류 중 하나를 받을 수 있습니다:

```plaintext
The Jira user is not a site or organization administrator. Check the permissions in Jira and try again.
```

```plaintext
Failed to link group. Please try again.
```

Jira 사용자가 `site-admins` 또는 `org-admins` 그룹의 멤버가 아니면 이 이슈가 발생합니다. GitLab은 Jira API 엔드포인트 `/rest/api/3/user?expand=groups`을 호출하여 그룹 멤버십을 확인하고 사용자가 이 두 그룹 중 하나에 속하는지 확인합니다.

사용자는 [Atlassian organization](https://admin.atlassian.com)에서 사이트 관리자로 나타날 수 있고 전체 관리자 권한을 가질 수 있지만 `site-admins` 또는 `org-admins` 그룹에 명시적으로 추가되지 않으면 GitLab 권한 확인이 실패합니다. 또한 사용자 정의 그룹 또는 제품별 역할을 통해 할당된 관리자 권한은 GitLab에서 감지되지 않습니다.

이 이슈를 해결하려면 Jira 사용자를 `org-admins` 또는 `site-admins` 그룹에 추가하세요:

1. [Atlassian organization](https://admin.atlassian.com)에 로그인합니다.
1. **디렉토리** > **그룹**로 이동합니다.
1. `org-admins` 그룹 (권장) 또는 `site-admins` 그룹을 선택합니다. 그룹이 없으면 [create it](https://support.atlassian.com/user-management/docs/create-groups/)합니다.
1. Jira 사용자를 그룹에 추가합니다.

Jira 사용자 요구 사항에 대한 자세한 내용은 [Jira user requirements](jira_cloud_app.md#jira-user-requirements)를 참조하세요.

GitLab은 OAuth 범위 제한으로 인해 Jira의 권한 API를 사용하여 관리자 상태를 직접 확인할 수 없습니다. 자세한 내용은 [issue #420687](https://gitlab.com/gitlab-org/gitlab/-/issues/420687) 및 [merge request !135771](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135771)을 참조하세요.

## 오류: `Failed to link group` {#error-failed-to-link-group}

그룹을 연결할 때 다음 오류를 받을 수 있습니다:

```plaintext
Failed to link group. Please try again.
```

이 오류는 여러 이유로 반환될 수 있습니다.

- 권한 부족으로 인해 Jira에서 사용자 정보를 가져올 수 없으면 `403 Forbidden`을 반환할 수 있습니다. 이 이슈를 해결하려면 앱을 설치하고 구성하는 Jira 사용자가 특정 [requirements](jira_cloud_app.md#jira-user-requirements)를 충족하는지 확인합니다.

- [reverse proxy](jira_cloud_app.md#using-a-reverse-proxy)가 있는 다시 쓰기 또는 하위 필터를 사용하면 이 오류가 발생할 수도 있습니다. 요청에 사용된 앱 키에는 서버 호스트 이름의 일부가 포함되어 있으며 일부 역방향 프록시 필터가 캡처할 수 있습니다. Atlassian 및 GitLab의 앱 키가 일치해야 인증이 제대로 작동합니다.

- GitLab for Jira Cloud 앱을 처음 설치했을 때 GitLab 인스턴스가 초기에 잘못 구성된 경우 이 오류가 발생할 수 있습니다. 이 경우 `jira_connect_installation` 테이블의 데이터를 삭제해야 할 수도 있습니다. 기존 GitLab for Jira 앱 설치를 유지할 필요가 없다고 확신하는 경우에만 이 데이터를 삭제합니다.

  1. GitLab for Jira Cloud 앱을 모든 Jira 프로젝트에서 제거합니다.
  1. 레코드를 삭제하려면 [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session)에서 이 명령을 실행합니다:

     ```ruby
     JiraConnectInstallation.delete_all
     ```

## 오류: `Failed to load Jira Connect Application ID` {#error-failed-to-load-jira-connect-application-id}

GitLab for Jira Cloud 앱에 로그인한 후 앱을 GitLab Self-Managed 인스턴스로 지정하면 다음 오류를 받을 수 있습니다:

```plaintext
Failed to load Jira Connect Application ID. Please try again.
```

브라우저 콘솔을 확인하면 다음 메시지도 볼 수 있습니다:

```plaintext
Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at https://gitlab.example.com/-/jira_connect/oauth_application_id. (Reason: CORS header 'Access-Control-Allow-Origin' missing). Status code: 403.
```

이 이슈를 해결하려면:

1. `/-/jira_connect/oauth_application_id`이 공개적으로 액세스 가능하고 JSON 응답을 반환하는지 확인합니다:

   ```shell
   curl --include "https://gitlab.example.com/-/jira_connect/oauth_application_id"
   ```

1. [installed the app from the official Atlassian Marketplace listing](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace) 인 경우 [**Jira Connect 프록시 URL**](jira_cloud_app.md#set-up-your-instance-for-atlassian-marketplace-installation)이 후행 슬래시 없이 `https://gitlab.com`으로 설정되어 있는지 확인합니다.

## 오류: `Missing required parameter: client_id` {#error-missing-required-parameter-client_id}

GitLab for Jira Cloud 앱에 로그인한 후 앱을 GitLab Self-Managed 인스턴스로 지정하면 다음 오류를 받을 수 있습니다:

```plaintext
Missing required parameter: client_id
```

이 이슈를 해결하려면 설치 방법에 대한 모든 전제 조건이 충족되었는지 확인하세요:

- [Prerequisites for connecting the GitLab for Jira Cloud app](jira_cloud_app.md#prerequisites)
- [Prerequisites for installing the GitLab for Jira Cloud app manually](jira_cloud_app.md#prerequisites-1)

## 오류: `Failed to sign in to GitLab` {#error-failed-to-sign-in-to-gitlab}

GitLab for Jira Cloud 앱에 로그인한 후 앱을 GitLab Self-Managed 인스턴스로 지정하면 다음 오류를 받을 수 있습니다:

```plaintext
Failed to sign in to GitLab
```

이 이슈를 해결하려면 앱용으로 작성한 [OAuth application](jira_cloud_app.md#set-up-oauth-authentication)에서 **신뢰함** 및 **비공개** 확인란이 선택 해제되었는지 확인합니다. 오류가 계속되면 [issue 581765](https://gitlab.com/gitlab-org/gitlab/-/work_items/581765)를 참조하세요.

앱에 Google Chrome을 사용하면 다른 브라우저를 사용해 보세요.
