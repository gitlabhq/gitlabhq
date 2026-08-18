---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Microsoft Azure를 OAuth 2.0 인증 제공자로 사용
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Microsoft Azure OAuth 2.0 OmniAuth 제공자를 활성화하고 Microsoft Azure 자격 증명으로 GitLab에 로그인할 수 있습니다.

> [!note]
> GitLab을 Azure/Entra ID와 처음으로 통합하는 경우 Microsoft Identity Platform (v2.0) 엔드포인트를 사용하는 [OpenID Connect 프로토콜](../administration/auth/oidc.md#configure-microsoft-azure)을 구성하세요.

## Generic OpenID Connect 구성으로 마이그레이션 {#migrate-to-generic-openid-connect-configuration}

GitLab 17.0 이상에서 `azure_oauth2`를 사용하는 인스턴스는 Generic OpenID Connect 구성으로 마이그레이션해야 합니다. 자세한 내용은 [OpenID Connect 프로토콜로 마이그레이션](../administration/auth/oidc.md#migrate-to-generic-openid-connect-configuration)을 참조하세요.

## Azure 애플리케이션 등록 {#register-an-azure-application}

Microsoft Azure OAuth 2.0 OmniAuth 제공자를 활성화하려면 Azure 애플리케이션을 등록하고 클라이언트 ID 및 비밀 키를 획득해야 합니다.

1. [Azure 포털](https://portal.azure.com)에 로그인하세요.
1. 여러 Azure Active Directory 테넌트가 있으면 원하는 테넌트로 전환하세요. 테넌트 ID를 기록하세요.
1. [애플리케이션을 등록](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)하고 다음 정보를 제공하세요:
   - 리다이렉트 URI는 GitLab 설치의 Azure OAuth 콜백 URL이 필요합니다. `https://gitlab.example.com/users/auth/azure_activedirectory_v2/callback`.
   - 애플리케이션 유형은 **웹**으로 설정되어야 합니다.
1. 클라이언트 ID와 클라이언트 비밀을 저장하세요. 클라이언트 비밀은 한 번만 표시됩니다.

   필요한 경우 [새 애플리케이션 비밀을 생성](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal#option-3-create-a-new-client-secret)할 수 있습니다.

`client ID`과 `client secret`는 OAuth 2.0과 관련된 용어입니다. 일부 Microsoft 설명서에서는 이 용어를 `Application ID`과 `Application Secret`로 명명합니다.

## API 권한(범위) 추가 {#add-api-permissions-scopes}

애플리케이션을 만든 후 [웹 API를 노출하도록 구성](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-expose-web-apis)하세요. Microsoft Graph API에서 다음 위임된 권한을 추가하세요:

- `email`
- `openid`
- `profile`

또는 `User.Read.All` 애플리케이션 권한을 추가하세요.

## GitLab에서 Microsoft OAuth 활성화 {#enable-microsoft-oauth-in-gitlab}

> [!note]
> 새 프로젝트의 경우 Microsoft Identity Platform (v2.0) 엔드포인트를 사용하는 [OpenID Connect 프로토콜](../administration/auth/oidc.md#configure-microsoft-azure)을 사용해야 합니다.

1. GitLab 서버에서 구성 파일을 엽니다.

   - Linux 패키지 설치의 경우:

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

   - 자체 컴파일된 설치의 경우:

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `azure_activedirectory_v2`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 제공자 구성을 추가합니다. `<client_id>`, `<client_secret>`, 및 `<tenant_id>`을 Azure 애플리케이션을 등록할 때 얻은 값으로 바꾸세요.

   - Linux 패키지 설치의 경우:

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         "name" => "azure_activedirectory_v2",
         "label" => "Provider name", # optional label for login button, defaults to "Azure AD v2"
         "args" => {
           "client_id" => "<client_id>",
           "client_secret" => "<client_secret>",
           "tenant_id" => "<tenant_id>",
         }
       }
     ]

     ```

   - [다른 Azure 클라우드](https://learn.microsoft.com/en-us/entra/identity-platform/authentication-national-cloud)의 경우 `args` 섹션 아래에 `base_azure_url`을 구성하세요. 예를 들어 Azure Government Community Cloud (GCC)의 경우:

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         "name" => "azure_activedirectory_v2",
         "label" => "Provider name", # optional label for login button, defaults to "Azure AD v2"
         "args" => {
           "client_id" => "<client_id>",
           "client_secret" => "<client_secret>",
           "tenant_id" => "<tenant_id>",
           "base_azure_url" => "https://login.microsoftonline.us"
         }
       }
     ]
     ```

   - 자체 컴파일된 설치의 경우:

     v2.0 엔드포인트의 경우:

     ```yaml
     - { name: 'azure_activedirectory_v2',
         label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
         args: { client_id: "<client_id>",
                 client_secret: "<client_secret>",
                 tenant_id: "<tenant_id>" } }
     ```

     [다른 Azure 클라우드](https://learn.microsoft.com/en-us/entra/identity-platform/authentication-national-cloud)의 경우 `args` 섹션 아래에 `base_azure_url`을 구성하세요. 예를 들어 Azure Government Community Cloud (GCC)의 경우:

     ```yaml
     - { name: 'azure_activedirectory_v2',
         label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
         args: { client_id: "<client_id>",
                 client_secret: "<client_secret>",
                 tenant_id: "<tenant_id>",
                 base_azure_url: "https://login.microsoftonline.us" } }
     ```

   `args` 섹션에 [OAuth 2.0 범위](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow)를 위한 `scope`을 선택적으로 추가할 수 있습니다. 기본값은 `openid profile email`입니다.

1. 구성 파일을 저장합니다.
1. Linux 패키지를 사용하여 설치한 경우 [GitLab 재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)을 하거나, 자체 컴파일된 설치인 경우 [GitLab 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)을 하세요.
1. GitLab 로그인 페이지를 새로 고치세요. Microsoft 아이콘이 로그인 양식 아래에 표시되어야 합니다.
1. 아이콘을 선택하세요. Microsoft에 로그인하고 GitLab 애플리케이션을 승인하세요.

기존 GitLab 사용자가 새로운 Azure AD 계정에 연결하는 방법에 대한 정보는 [기존 사용자에 대해 OmniAuth 활성화](omniauth.md#enable-omniauth-for-an-existing-user)를 참조하세요.

## 문제 해결 {#troubleshooting}

### 사용자 로그인 배너 메시지: Extern UID가 이미 사용되었습니다 {#user-sign-in-banner-message-extern-uid-has-already-been-taken}

로그인할 때 `Extern UID has already been taken`라는 오류가 표시될 수 있습니다.

이를 해결하려면 [Rails 콘솔](../administration/operations/rails_console.md#starting-a-rails-console-session)을 사용하여 계정에 연결된 기존 사용자가 있는지 확인하세요:

1. `extern_uid`을 찾으세요:

   ```ruby
   id = Identity.where(extern_uid: '<extern_uid>')
   ```

1. 콘텐츠를 인쇄하여 `extern_uid`에 연결된 사용자 이름을 찾으세요:

   ```ruby
   pp id
   ```

`extern_uid`이 계정에 연결되어 있으면 사용자 이름을 사용하여 로그인할 수 있습니다.

`extern_uid`이 어떤 사용자 이름에도 연결되지 않은 경우, 이는 삭제 오류로 인한 고스트 레코드 때문일 수 있습니다.

다음 명령을 실행하여 ID를 삭제하고 `extern uid`을 해제하세요:

```ruby
 Identity.find('<id>').delete
```
