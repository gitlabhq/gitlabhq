---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenID Connect를 인증 공급자로 사용
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab을 [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html)를 OmniAuth 공급자로 사용하는 클라이언트 애플리케이션으로 사용할 수 있습니다.

OpenID Connect OmniAuth 공급자를 활성화하려면 OpenID Connect 공급자에 애플리케이션을 등록해야 합니다. OpenID Connect 공급자는 클라이언트의 세부 정보 및 비밀을 제공합니다.

1. GitLab 서버에서 구성 파일을 엽니다.

   Linux 패키지 설치의 경우:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. [공통 설정](../../integration/omniauth.md#configure-common-settings)을 구성하여 `openid_connect`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.

1. 공급자 구성을 추가합니다.

   Linux 패키지 설치의 경우:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect", # do not change this parameter
       label: "Provider name", # optional label for login button, defaults to "Openid Connect"
       icon: "<custom_provider_icon>",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         send_scope_to_token_endpoint: "false",
         pkce: true,
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback"
         }
       }
     }
   ]
   ```

   여러 ID 공급자가 있는 Linux 패키지 설치의 경우:

   ```ruby
   { 'name' => 'openid_connect',
     'label' => '...',
     'icon' => '...',
     'args' => {
       'name' => 'openid_connect',
       'strategy_class': 'OmniAuth::Strategies::OpenIDConnect',
       'scope' => ['openid', 'profile', 'email'],
       'discovery' => true,
       'response_type' => 'code',
       'issuer' => 'https://...',
       'client_auth_method' => 'query',
       'uid_field' => '...',
       'client_options' => {
         `identifier`: "<your_oidc_client_id>",
         `secret`: "<your_oidc_client_secret>",
         'redirect_uri' => 'https://.../users/auth/openid_connect/callback'
      }
    }
   },
   { 'name' => 'openid_connect_2fa',
     'label' => '...',
     'icon' => '...',
     'args' => {
       'name' => 'openid_connect_2fa',
       'strategy_class': 'OmniAuth::Strategies::OpenIDConnect',
       'scope' => ['openid', 'profile', 'email'],
       'discovery' => true,
       'response_type' => 'code',
       'issuer' => 'https://...',
       'client_auth_method' => 'query',
       'uid_field' => '...',
       'client_options' => {
        ...
        'redirect_uri' => 'https://.../users/auth/openid_connect_2fa/callback'
      }
    }
   }
   ```

   자체 컴파일된 설치의 경우:

   ```yaml
     - { name: 'openid_connect', # do not change this parameter
         label: 'Provider name', # optional label for login button, defaults to "Openid Connect"
         icon: '<custom_provider_icon>',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           send_scope_to_token_endpoint: false,
           pkce: true,
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback'
           }
         }
       }
   ```

   > [!note]
   > 각 구성 옵션에 대한 자세한 내용은 [OmniAuth OpenID Connect 사용 설명서](https://github.com/omniauth/omniauth_openid_connect#usage) 및 [OpenID Connect Core 1.0 사양](https://openid.net/specs/openid-connect-core-1_0.html)을 참조하세요.

1. 공급자 구성의 경우 공급자의 값을 OpenID Connect 클라이언트 설정과 일치하도록 변경합니다. 다음을 참고 자료로 사용하세요:

   - `<your_oidc_label>`은 로그인 페이지에 표시되는 레이블입니다.
   - `<custom_provider_icon>`(선택 사항)은 로그인 페이지에 표시되는 아이콘입니다. 주요 소셜 로그인 플랫폼의 아이콘은 GitLab에 내장되어 있지만 이 매개변수를 지정하여 이러한 아이콘을 재정의할 수 있습니다. GitLab은 로컬 경로와 절대 URL을 모두 허용합니다. GitLab은 대부분의 주요 소셜 로그인 플랫폼의 아이콘을 포함하고 있지만 외부 URL 또는 자신의 아이콘 파일에 대한 절대 또는 상대 경로를 지정하여 이러한 아이콘을 재정의할 수 있습니다.
     - 로컬 절대 경로의 경우 공급자 설정을 `icon: <path>/<to>/<your-icon>`로 구성합니다.
       - 아이콘 파일을 `/opt/gitlab/embedded/service/gitlab-rails/public/<path>/<to>/<your-icon>`에 저장합니다.
       - `https://gitlab.example/<path>/<to>/<your-icon>`에서 아이콘 파일에 액세스합니다.
     - 로컬 상대 경로의 경우 공급자 설정을 `icon: <your-icon>`로 구성합니다.
       - 아이콘 파일을 `/opt/gitlab/embedded/service/gitlab-rails/public/images/<your-icon>`에 저장합니다.
       - `https://gitlab.example.com/images/<your-icon>`에서 아이콘 파일에 액세스합니다.
   - `<your_oidc_url>`(선택 사항)은 OpenID Connect 공급자를 가리키는 URL입니다(예: `https://example.com/auth/realms/your-realm`). 이 값을 제공하지 않으면 URL이 `client_options`에서 다음 형식으로 구성됩니다: `<client_options.scheme>://<client_options.host>:<client_options.port>`.
   - `discovery`이 `true`로 설정되면 OpenID Connect 공급자는 `<your_oidc_url>/.well-known/openid-configuration`를 사용하여 클라이언트 옵션을 자동으로 검색하려고 합니다. `false`로 기본값 설정됩니다.
   - `client_auth_method`(선택 사항)은 OpenID Connect 공급자로 클라이언트를 인증하는 데 사용되는 방법을 지정합니다.
     - 지원되는 값은:
       - `basic` - HTTP 기본 인증.
       - `jwt_bearer` - JWT 기반 인증(개인 키 및 클라이언트 비밀 서명).
       - `mtls` - 상호 TLS 또는 X.509 인증서 유효성 검사.
       - 다른 값은 요청 본문에 클라이언트 ID와 비밀을 게시합니다.
     - 지정하지 않으면 이 값의 기본값은 `basic`입니다.
   - `<uid_field>`(선택 사항)은 `user_info.raw_attributes`의 필드 이름으로 `uid`의 값을 정의합니다(예: `preferred_username`). 이 값을 제공하지 않거나 구성된 값의 필드가 `user_info.raw_attributes` 세부 정보에 없으면 `uid`은 `sub` 필드를 사용합니다.
   - `send_scope_to_token_endpoint`은 기본적으로 `true`이므로 `scope` 매개변수는 일반적으로 토큰 엔드포인트에 대한 요청에 포함됩니다. 그러나 OpenID Connect 공급자가 이러한 요청에서 `scope` 매개변수를 허용하지 않으면 이를 `false`로 설정합니다.
   - `pkce`(선택 사항):  [코드 교환 증명 키](https://www.rfc-editor.org/rfc/rfc7636)를 활성화합니다.
   - `client_options`은 OpenID Connect 클라이언트 관련 옵션입니다. 구체적으로:
     - `identifier`은 OpenID Connect 서비스 공급자에서 구성한 클라이언트 식별자입니다.
     - `secret`은 OpenID Connect 서비스 공급자에서 구성한 클라이언트 비밀입니다. 예를 들어 [OmniAuth OpenID Connect](https://github.com/omniauth/omniauth_openid_connect)가 필요합니다. 서비스 공급자가 비밀을 요구하지 않으면 모든 값을 제공하면 무시됩니다.
     - `redirect_uri`은 성공적으로 로그인한 후 사용자를 리디렉션할 GitLab URL입니다(예: `http://example.com/users/auth/openid_connect/callback`).
     - 다음 `client_options`은 자동 검색이 비활성화되거나 실패하지 않는 한 선택 사항입니다:
       - `authorization_endpoint`은 최종 사용자에게 권한을 부여하는 엔드포인트에 대한 URL입니다.
       - `token_endpoint`은 액세스 토큰을 제공하는 엔드포인트에 대한 URL입니다.
       - `userinfo_endpoint`은 사용자 정보를 제공하는 엔드포인트에 대한 URL입니다.
       - `jwks_uri`은 토큰 서명자가 해당 키를 게시하는 엔드포인트에 대한 URL입니다.

1. 구성 파일을 저장합니다.
1. 변경 사항을 적용하려면 다음을 수행하세요:

   - Linux 패키지를 사용하여 GitLab을 설치했으면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
   - GitLab을 자체 컴파일로 설치했으면 [GitLab 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

로그인 페이지에서 일반 로그인 양식 아래에 OpenID Connect 옵션이 있습니다. 이 옵션을 선택하여 인증 프로세스를 시작합니다. OpenID Connect 공급자가 로그인하고 클라이언트에서 확인이 필요한 경우 GitLab 애플리케이션에 권한을 부여하도록 요청합니다. GitLab으로 리디렉션되고 로그인됩니다.

## 예시 구성 {#example-configurations}

다음 구성은 Linux 패키지 설치를 사용할 때 다양한 공급자를 사용하여 OpenID를 설정하는 방법을 보여줍니다.

### Google 구성 {#configure-google}

[Google 설명서](https://developers.google.com/identity/openid-connect/openid-connect)를 참조하세요:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect", # do not change this parameter
    label: "Google OpenID", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer: "https://accounts.google.com",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR PROJECT CLIENT ID>",
        secret: "<YOUR PROJECT CLIENT SECRET>",
        redirect_uri: "https://example.com/users/auth/openid_connect/callback",
       }
     }
  }
]
```

### Microsoft Azure 구성 {#configure-microsoft-azure}

Microsoft Azure용 OpenID Connect(OIDC) 프로토콜은 [Microsoft ID 플랫폼(v2) 엔드포인트](https://learn.microsoft.com/en-us/previous-versions/azure/active-directory/azuread-dev/azure-ad-endpoint-comparison)를 사용합니다. 시작하려면 [Azure Portal](https://portal.azure.com)에 로그인합니다. 앱의 경우 다음 정보가 필요합니다:

- 테넌트 ID입니다. 이미 있을 수도 있습니다. 자세한 내용은 [Microsoft Azure 테넌트](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant) 설명서를 참조하세요.
- 클라이언트 ID 및 클라이언트 비밀입니다. [Microsoft 빠른 시작 애플리케이션 등록](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) 설명서의 지침에 따라 앱의 테넌트 ID, 클라이언트 ID 및 클라이언트 비밀을 확인합니다.

Microsoft Azure 애플리케이션을 등록할 때 GitLab이 필요한 세부 정보를 검색할 수 있도록 API 권한을 부여해야 합니다. 최소한 `openid`, `profile` 및 `email` 권한을 제공해야 합니다. 자세한 내용은 [웹 API의 앱 권한을 구성하기 위한 Microsoft 설명서](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-access-web-apis#add-permissions-to-access-microsoft-graph)를 참조하세요.

> [!note]
> Azure가 프로비저닝한 모든 계정에는 정의된 이메일 주소가 있어야 합니다. 이메일 주소를 정의하지 않으면 Azure가 무작위로 생성된 주소를 할당합니다. [새 사용자를 위한 도메인 제한](../settings/sign_up_restrictions.md#allow-or-deny-account-creation-by-using-specific-email-domains)을 구성했으면 이 무작위 주소로 인해 계정이 생성되지 않을 수 있습니다.

Linux 패키지 설치의 예시 구성 블록:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect", # do not change this parameter
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
      }
    }
  }
]
```

Microsoft는 [OIDC 프로토콜](https://learn.microsoft.com/en-us/entra/identity-platform/v2-protocols-oidc)을 사용하여 플랫폼이 어떻게 작동하는지 설명했습니다.

#### Microsoft Entra 사용자 지정 서명 키 {#microsoft-entra-custom-signing-keys}

[SAML 클레임 매핑 기능](https://learn.microsoft.com/en-us/entra/identity-platform/saml-claims-customization)을 사용하기 때문에 애플리케이션에 사용자 지정 서명 키가 있으면 다음과 같은 방식으로 OpenID 공급자를 구성해야 합니다:

- `args.discovery`을 생략하거나 `false`로 설정하여 OpenID Connect 검색을 비활성화합니다.
- `client_options`에서 다음을 지정합니다:
  - `appid` 쿼리 매개변수가 있는 `jwks_uri`: `https://login.microsoftonline.com/<YOUR-TENANT-ID>/discovery/v2.0/keys?appid=<YOUR APP CLIENT ID>`.
  - `end_session_endpoint`.
  - `authorization_endpoint`.
  - `userinfo_endpoint`.

Linux 패키지 설치의 예시 구성:

```ruby
gitlab_rails['omniauth_providers'] = [
 {
    name: "openid_connect", # do not change this parameter
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "basic",
      discovery: false,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback",
        end_session_endpoint: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/oauth2/v2.0/logout",
        authorization_endpoint: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/oauth2/v2.0/authorize",
        token_endpoint: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/oauth2/v2.0/token",
        userinfo_endpoint: "https://graph.microsoft.com/oidc/userinfo",
        jwks_uri: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/discovery/v2.0/keys?appid=<YOUR APP CLIENT ID>"
      }
    }
  }
]
```

`KidNotFound` 메시지와 함께 인증 실패가 표시되면 `appid` 쿼리 매개변수가 누락되었거나 잘못되었을 가능성이 높습니다. Microsoft에서 반환한 ID 토큰을 `jwks_uri` 엔드포인트에서 제공한 키로 유효성 검사할 수 없으면 GitLab이 오류를 발생시킵니다.

자세한 내용은 [토큰 유효성 검사에 대한 Microsoft Entra 설명서](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens#validate-tokens)를 참조하세요.

#### Generic OpenID Connect 구성으로 마이그레이션 {#migrate-to-generic-openid-connect-configuration}

`azure_activedirectory_v2` 및 `azure_oauth2` 모두에서 Generic OpenID Connect 구성으로 마이그레이션할 수 있습니다.

먼저 `uid_field`을 설정합니다. `uid_field` 및 `sub` 클레임은 `uid_field`로 선택할 수 있으며 공급자에 따라 다릅니다. `uid_field`을 설정하지 않고 로그인하면 GitLab에서 수동으로 수정해야 하는 추가 ID가 생성됩니다:

| 공급자                                                                                                        | `uid_field` | 지원 정보  |
|-----------------------------------------------------------------------------------------------------------------|-------|-----------------------------------------------------------------------|
| [`omniauth-azure-oauth2`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/omniauth-azure-oauth2) | `sub` | 추가 속성 `oid` 및 `tid`는 `info` 객체에서 제공됩니다. |
| [`omniauth-azure-activedirectory-v2`](https://github.com/RIPAGlobal/omniauth-azure-activedirectory-v2/)         | `oid` | `oid`을 마이그레이션할 때 `uid_field`로 구성해야 합니다. |
| [`omniauth_openid_connect`](https://github.com/omniauth/omniauth_openid_connect/)                               | `sub` | `uid_field`을 지정하여 다른 필드를 사용합니다. |

Generic OpenID Connect 구성으로 마이그레이션하려면 구성을 업데이트해야 합니다.

Linux 패키지 설치의 경우 다음과 같이 구성을 업데이트합니다:

{{< tabs >}}

{{< tab title="Azure OAuth 2.0" >}}

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "azure_oauth2",
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "azure_oauth2", # this matches the existing azure_oauth2 provider name, and only the strategy_class immediately below configures OpenID Connect
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "sub",
      send_scope_to_token_endpoint: "false",
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/azure_oauth2/callback"
      }
    }
  }
]
```

{{< /tab >}}

{{< tab title="Azure Active Directory v2" >}}

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "azure_activedirectory_v2",
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "azure_activedirectory_v2",
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "oid",
      send_scope_to_token_endpoint: "false",
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/azure_activedirectory_v2/callback"
      }
    }
  }
]
```

{{< /tab >}}

{{< /tabs >}}

Helm 설치의 경우:

[공급자의 구성](https://docs.gitlab.com/charts/charts/globals/#providers)을 YAML 파일에 추가합니다(예: `provider.yaml`):

{{< tabs >}}

{{< tab title="Azure OAuth 2.0" >}}

```ruby
{
  "name": "azure_oauth2",
  "args": {
    "name": "azure_oauth2",
    "strategy_class": "OmniAuth::Strategies::OpenIDConnect",
    "scope": [
      "openid",
      "profile",
      "email"
    ],
    "response_type": "code",
    "issuer": "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
    "client_auth_method": "query",
    "discovery": true,
    "uid_field": "sub",
    "send_scope_to_token_endpoint": false,
    "client_options": {
      "identifier": "<YOUR APP CLIENT ID>",
      "secret": "<YOUR APP CLIENT SECRET>",
      "redirect_uri": "https://gitlab.example.com/users/auth/azure_oauth2/callback"
    }
  }
}
```

{{< /tab >}}

{{< tab title="Azure Active Directory v2" >}}

```ruby
{
  "name": "azure_activedirectory_v2",
  "args": {
    "name": "azure_activedirectory_v2",
    "strategy_class": "OmniAuth::Strategies::OpenIDConnect",
    "scope": [
      "openid",
      "profile",
      "email"
    ],
    "response_type": "code",
    "issuer": "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
    "client_auth_method": "query",
    "discovery": true,
    "uid_field": "sub",
    "send_scope_to_token_endpoint": false,
    "client_options": {
      "identifier": "<YOUR APP CLIENT ID>",
      "secret": "<YOUR APP CLIENT SECRET>",
      "redirect_uri": "https://gitlab.example.com/users/auth/activedirectory_v2/callback"
    }
  }
}
```

{{< /tab >}}

{{< /tabs >}}

`azure_oauth2`에서 `omniauth_openid_connect`로 마이그레이션할 때 GitLab 17.0 이상으로 업그레이드하는 것의 일부로 조직에 설정된 `sub` 클레임 값이 다를 수 있습니다. `azure_oauth2`은 Microsoft V1 엔드포인트를 사용하는 반면 `azure_activedirectory_v2` 및 `omniauth_openid_connect`은 모두 Microsoft V2 엔드포인트를 사용하며 공통 `sub` 값을 사용합니다.

- **For users with an email address in Entra ID** 이메일 주소로 폴백하고 사용자 ID를 업데이트하도록 하려면 다음을 구성합니다:
  - Linux 패키지 설치에서는 [`omniauth_auto_link_user`](../../integration/omniauth.md#link-existing-users-to-omniauth-users)입니다.
  - Helm 설치에서는 [`autoLinkUser`](https://docs.gitlab.com/charts/charts/globals/#omniauth)입니다.
- **For users with no email address** 관리자는 다음 작업 중 하나를 수행해야 합니다:
  - 다른 인증 방법을 설정하거나 GitLab 사용자 이름 및 암호를 사용하여 로그인을 활성화합니다. 그러면 사용자가 로그인하고 프로필을 사용하여 Azure ID를 수동으로 연결할 수 있습니다.
  - 기존 `azure_oauth2` 옆에 OpenID Connect를 새 공급자로 구현하여 사용자가 OAuth 2.0을 통해 로그인하고 OpenID Connect ID를 연결할 수 있도록 합니다(이전 방법과 유사). 이 방법은 `auto_link_user`이 활성화되어 있는 한 이메일 주소가 있는 사용자에게도 작동합니다.
  - `extern_uid`을 수동으로 업데이트합니다. 이를 수행하려면 [API 또는 Rails 콘솔](../../integration/omniauth.md#change-apps-or-configuration)을 사용하여 각 사용자의 `extern_uid`을 업데이트합니다. 인스턴스가 이미 17.0 이상으로 업그레이드되었고 사용자가 로그인을 시도한 경우 이 방법이 필요할 수 있습니다.

> [!note]
> `azure_oauth2`는 GitLab 계정을 프로비저닝할 때 `email` 클레임이 누락되거나 비어 있었으면 Entra ID의 `upn` 클레임을 이메일 주소로 사용했을 수 있습니다.

### Microsoft Azure Active Directory B2C 구성 {#configure-microsoft-azure-active-directory-b2c}

GitLab은 [Azure Active Directory B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/overview)에서 작동하도록 특별한 구성이 필요합니다. 시작하려면 [Azure Portal](https://portal.azure.com)에 로그인합니다. 앱의 경우 Azure에서 다음 정보가 필요합니다:

- 테넌트 ID입니다. 이미 있을 수도 있습니다. 자세한 내용은 [Microsoft Azure 테넌트](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant) 설명서를 검토하세요.
- 클라이언트 ID 및 클라이언트 비밀입니다. [Microsoft 자습서](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga) 설명서의 지침을 따라 앱의 클라이언트 ID 및 클라이언트 비밀을 확인합니다.
- 사용자 플로우 또는 정책 이름입니다. [Microsoft 자습서](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-user-flow)의 지침을 따릅니다.

앱을 구성합니다:

1. 앱 `Redirect URI`을 설정합니다. 예를 들어 GitLab 도메인이 `gitlab.example.com`이면 앱 `Redirect URI`을 `https://gitlab.example.com/users/auth/openid_connect/callback`로 설정합니다.
1. [ID 토큰 활성화](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga#enable-id-token-implicit-grant)합니다.
1. 앱에 다음 API 권한을 추가합니다:

   - `openid`
   - `offline_access`

#### 사용자 지정 정책 구성 {#configure-custom-policies}

Azure B2C는 [사용자 로그인을 위한 비즈니스 로직을 정의하는 두 가지 방법을 제공합니다](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview):

- [사용자 플로우](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview#user-flows)
- [사용자 지정 정책](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview#custom-policies)

표준 Azure B2C 사용자 플로우는 GitLab이 사용자를 생성하거나 연결하는 데 필요한 OpenID `email` 클레임을 전송하지 않기 때문에 사용자 지정 정책이 필요합니다. 따라서 표준 사용자 플로우는 [`allow_single_sign_on` 또는 `auto_link_user` 매개변수](../../integration/omniauth.md#configure-common-settings)에서 작동하지 않습니다. 표준 Azure B2C 정책을 사용하면 GitLab은 새 계정을 생성하거나 이메일 주소로 기존 계정에 연결할 수 없습니다.

Azure AD B2C가 사용자 플로우 및 사용자 지정 정책에서 토큰 및 클레임을 발급하는 방법에 대한 자세한 내용은 [사용자 플로우 및 사용자 지정 정책](https://learn.microsoft.com/azure/active-directory-b2c/user-flow-overview) 및 [클레임 스키마 구성](https://learn.microsoft.com/azure/active-directory-b2c/claimsschema)에 대한 Microsoft 설명서를 참조하세요.

먼저 [사용자 지정 정책을 생성합니다](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy).

Microsoft 지침은 [사용자 지정 정책 스타터 팩](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#custom-policy-starter-pack)에서 `SocialAndLocalAccounts`을 사용하지만 `LocalAccounts`은 로컬 Active Directory 계정에 대해 인증합니다. [정책을 업로드](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#upload-the-policies)하기 전에 다음을 수행합니다:

1. `email` 클레임을 내보내려면 `SignUpOrSignin.xml`을 수정합니다. 다음 줄을 바꿉니다:

   ```xml
   <OutputClaim ClaimTypeReferenceId="email" />
   ```

   다음으로:

   ```xml
   <OutputClaim ClaimTypeReferenceId="signInNames.emailAddress" PartnerClaimType="email" />
   ```

1. OIDC 검색이 B2C에서 작동하려면 [OIDC 사양](https://openid.net/specs/openid-connect-discovery-1_0.html#rfc.section.4.3)과 호환되는 발급자를 사용하여 정책을 구성합니다. [토큰 호환성 설정](https://learn.microsoft.com/en-us/azure/active-directory-b2c/configure-tokens?pivots=b2c-custom-policy#token-compatibility-settings)을 참조하세요. `TrustFrameworkBase.xml` 아래 `JwtIssuer`에서 `IssuanceClaimPattern`을 `AuthorityWithTfp`으로 설정합니다:

   ```xml
   <ClaimsProvider>
     <DisplayName>Token Issuer</DisplayName>
     <TechnicalProfiles>
       <TechnicalProfile Id="JwtIssuer">
         <DisplayName>JWT Issuer</DisplayName>
         <Protocol Name="None" />
         <OutputTokenFormat>JWT</OutputTokenFormat>
         <Metadata>
           <Item Key="IssuanceClaimPattern">AuthorityWithTfp</Item>
           ...
   ```

1. [정책 업로드](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#upload-the-policies)합니다. 기존 정책을 업데이트하는 경우 기존 파일을 덮어씁니다.

1. 발급자 URL을 확인하려면 로그인 정책을 사용합니다. 발급자 URL의 형식은:

   ```markdown
   https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/<YOUR-SIGN-IN-POLICY-NAME>/v2.0/
   ```

   정책 이름은 URL에서 소문자입니다. 예를 들어 `B2C_1A_signup_signin` 정책은 `b2c_1a_signup_sigin`로 표시됩니다.

   뒤에 오는 슬래시를 포함해야 합니다.

1. OIDC 검색 URL 및 발급자 URL의 작동을 확인하고 발급자 URL에 `.well-known/openid-configuration`을 추가합니다:

   ```markdown
   https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/<YOUR-SIGN-IN-POLICY-NAME>/v2.0/.well-known/openid-configuration
   ```

   예를 들어 `domain`이 `example.b2clogin.com`이고 테넌트 ID가 `fc40c736-476c-4da1-b489-ee48cee84386`이면 `curl` 및 `jq`을 사용하여 발급자를 추출할 수 있습니다:

   ```shell
   $ curl --silent "https://example.b2clogin.com/tfp/fc40c736-476c-4da1-b489-ee48cee84386/b2c_1a_signup_signin/v2.0/.well-known/openid-configuration" | jq .issuer
   "https://example.b2clogin.com/tfp/fc40c736-476c-4da1-b489-ee48cee84386/b2c_1a_signup_signin/v2.0/"
   ```

1. `signup_signin`에 사용할 사용자 지정 정책을 사용하여 발급자 URL을 구성합니다. 예를 들어 이것은 Linux 패키지 설치의 `b2c_1a_signup_signin`에 대한 사용자 지정 정책을 사용한 구성입니다:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
   {
     name: "openid_connect", # do not change this parameter
     label: "Azure B2C OIDC", # optional label for login button, defaults to "Openid Connect"
     args: {
       name: "openid_connect",
       scope: ["openid"],
       response_mode: "query",
       response_type: "id_token",
       issuer:  "https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/b2c_1a_signup_signin/v2.0/",
       client_auth_method: "query",
       discovery: true,
       send_scope_to_token_endpoint: true,
       pkce: true,
       client_options: {
         identifier: "<YOUR APP CLIENT ID>",
         secret: "<YOUR APP CLIENT SECRET>",
         redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
       }
     }
   }]
   ```

#### Azure B2C 문제 해결 {#troubleshooting-azure-b2c}

- `yourtenant.onmicrosoft.com`, `ProxyIdentityExperienceFrameworkAppId` 및 `IdentityExperienceFrameworkAppId`의 모든 발생이 B2C 테넌트 호스트 이름 및 XML 정책 파일의 각 클라이언트 ID와 일치하는지 확인합니다.
- `https://jwt.ms`을 앱에 리디렉션 URI로 추가하고 [사용자 지정 정책 테스터](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#test-the-custom-policy)를 사용합니다. 페이로드에 사용자의 이메일 액세스와 일치하는 `email`이 포함되어 있는지 확인합니다.
- 사용자 지정 정책을 활성화한 후 사용자가 로그인을 시도하면 `Invalid username or password`이 표시될 수 있습니다. 이것은 `IdentityExperienceFramework` 앱의 구성 이슈일 수 있습니다. [이 Microsoft 댓글](https://learn.microsoft.com/en-us/answers/questions/50355/unable-to-sign-on-using-custom-policy?childtoview=122370#comment-122370)을 참조하면 앱 매니페스트에 다음 설정이 포함되어 있는지 확인하는 것을 제안합니다:

  - `"accessTokenAcceptedVersion": null`
  - `"signInAudience": "AzureADMyOrg"`

이 구성은 `IdentityExperienceFramework` 앱을 생성할 때 사용되는 `Supported account types` 설정과 일치합니다.

### Keycloak 구성 {#configure-keycloak}

GitLab은 HTTPS를 사용하는 OpenID 공급자와 함께 작동합니다. HTTP를 사용하는 Keycloak 서버를 설정할 수 있지만 GitLab은 HTTPS를 사용하는 Keycloak 서버하고만 통신할 수 있습니다.

토큰에 서명하기 위해 공개 키 알고리즘을 사용하도록 Keycloak을 구성합니다. 예를 들어 HS256 또는 HS358 대신 RSA256 또는 RSA512를 사용합니다. 공개 키 암호화 알고리즘은:

- 구성하기가 더 쉽습니다.
- 개인 키 유출이 심각한 보안 결과를 초래하기 때문에 더 안전합니다.

1. Keycloak 관리 콘솔을 엽니다.
1. **Realm Settings** > **Tokens** > **Default Signature Algorithm**을 선택합니다.
1. 서명 알고리즘을 구성합니다.

Linux 패키지 설치의 예시 구성 블록:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect", # do not change this parameter
    label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://keycloak.example.com/realms/myrealm",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR CLIENT ID>",
        secret: "<YOUR CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
      }
    }
  }
]
```

#### 대칭 키 알고리즘을 사용한 Keycloak 구성 {#configure-keycloak-with-a-symmetric-key-algorithm}

> [!warning]
> 다음 지침은 완전성을 위해 포함되지만 절대 필요한 경우에만 대칭 키 암호화를 사용합니다.

대칭 키 암호화를 사용하려면:

1. Keycloak 데이터베이스에서 비밀 키를 추출합니다. Keycloak은 웹 인터페이스에서 이 값을 노출하지 않습니다. 웹 인터페이스에 표시되는 클라이언트 비밀은 JSON 웹 토큰에 서명하는 데 사용되는 비밀과 다른 OAuth 2.0 클라이언트 비밀입니다.

   예를 들어 PostgreSQL을 Keycloak의 백엔드 데이터베이스로 사용하는 경우:

   - 데이터베이스 콘솔에 로그인합니다.
   - 다음 SQL 쿼리를 실행하여 키를 추출합니다:

     ```sql
     $ psql -U keycloak
     psql (13.3 (Debian 13.3-1.pgdg100+1))
     Type "help" for help.

     keycloak=# SELECT c.name, value FROM component_config CC INNER JOIN component C ON(CC.component_id = C.id) WHERE C.realm_id = 'master' and provider_id = 'hmac-generated' AND CC.name = 'secret';
     -[ RECORD 1 ]---------------------------------------------------------------------------------
     name  | hmac-generated
     value | lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62-sqGc8drp3XW-wr93zru8PFsQokHZZuJJbaUXvmiOftCZM3C4KW3-g
     -[ RECORD 2 ]---------------------------------------------------------------------------------
     name  | fallback-HS384
     value | UfVqmIs--U61UYsRH-NYBH3_mlluLONpg_zN7CXEwkJcO9xdRNlzZfmfDLPtf2xSTMvqu08R2VhLr-8G-oZ47A
     ```

     이 예제에는 두 개의 개인 키가 있습니다: HS256의 경우 하나 (`hmac-generated`), HS384의 경우 다른 하나 (`fallback-HS384`). 첫 번째 `value`을 사용하여 GitLab을 구성합니다.

1. `value`을 표준 base64로 변환합니다. ["Invalid signature with HS256 token" 게시물](https://keycloak.discourse.group/t/invalid-signature-with-hs256-token/3228/9)에서 논의한 것처럼 `value`은 RFC 4648의 ["URL 및 파일 이름 안전 알파벳이 있는 Base 64 인코딩 섹션](https://datatracker.ietf.org/doc/html/rfc4648#section-5)에 인코딩됩니다. 이를 [RFC 2045에 정의된 표준 base64](https://datatracker.ietf.org/doc/html/rfc2045)로 변환해야 합니다. 다음 Ruby 스크립트가 이를 수행합니다:

   ```ruby
   require 'base64'

   value = "lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62-sqGc8drp3XW-wr93zru8PFsQokHZZuJJbaUXvmiOftCZM3C4KW3-g"
   Base64.encode64(Base64.urlsafe_decode64(value))
   ```

   이로 인해 다음 값이 발생합니다:

   ```markdown
   lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62+sqGc8drp3XW+wr93zru8PFsQokH\nZZuJJbaUXvmiOftCZM3C4KW3+g==\n
   ```

1. 이 base64로 인코딩된 비밀을 `jwt_secret_base64`에 지정합니다. 예를 들어:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect", # do not change this parameter
       label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
       args: {
         name: "openid_connect",
         scope: ["openid", "profile", "email"],
         response_type: "code",
         issuer:  "https://keycloak.example.com/auth/realms/myrealm",
         client_auth_method: "query",
         discovery: true,
         uid_field: "preferred_username",
         jwt_secret_base64: "<YOUR BASE64-ENCODED SECRET>",
         pkce: true,
         client_options: {
           identifier: "<YOUR CLIENT ID>",
           secret: "<YOUR CLIENT SECRET>",
           redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
         }
       }
     }
   ]
   ```

`JSON::JWS::VerificationFailed` 오류가 표시되면 잘못된 비밀을 지정했습니다.

### Casdoor {#casdoor}

GitLab은 HTTPS를 사용하는 OpenID 공급자와 함께 작동합니다. HTTPS를 사용하여 Casdoor를 통해 OpenID를 통해 GitLab에 연결합니다.

앱의 경우 Casdoor에서 다음 단계를 완료하세요:

1. 클라이언트 ID 및 클라이언트 비밀을 확인합니다.
1. GitLab 리디렉션 URL을 추가합니다. 예를 들어 GitLab 도메인이 `gitlab.example.com`이면 Casdoor 앱에 다음 `Redirect URI`이 있는지 확인합니다: `https://gitlab.example.com/users/auth/openid_connect/callback`.

자세한 내용은 [Casdoor 설명서](https://casdoor.org/docs/integration/ruby/gitlab/)를 참조하세요.

Linux 패키지 설치의 예시 구성(파일 경로: `/etc/gitlab/gitlab.rb`):

```ruby
gitlab_rails['omniauth_providers'] = [
    {
        name: "openid_connect", # do not change this parameter
        label: "Casdoor", # optional label for login button, defaults to "Openid Connect"
        args: {
            name: "openid_connect",
            scope: ["openid", "profile", "email"],
            response_type: "code",
            issuer:  "https://<CASDOOR_HOSTNAME>",
            client_auth_method: "query",
            discovery: true,
            uid_field: "sub",
            client_options: {
                identifier: "<YOUR CLIENT ID>",
                secret: "<YOUR CLIENT SECRET>",
                redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
            }
        }
    }
]
```

자체 컴파일 설치의 예시 구성(파일 경로: `config/gitlab.yml`):

```yaml
  - { name: 'openid_connect', # do not change this parameter
      label: 'Casdoor', # optional label for login button, defaults to "Openid Connect"
      args: {
        name: 'openid_connect',
        scope: ['openid', 'profile', 'email'],
        response_type: 'code',
        issuer: 'https://<CASDOOR_HOSTNAME>',
        discovery: true,
        client_auth_method: 'query',
        uid_field: 'sub',
        client_options: {
          identifier: '<YOUR CLIENT ID>',
          secret: '<YOUR CLIENT SECRET>',
          redirect_uri: 'https://gitlab.example.com/users/auth/openid_connect/callback'
        }
      }
    }
```

## 여러 OpenID Connect 공급자 구성 {#configure-multiple-openid-connect-providers}

여러 OpenID Connect(OIDC) 공급자를 사용하도록 애플리케이션을 구성할 수 있습니다. 구성 파일에서 `strategy_class`을 명시적으로 설정하여 이를 수행합니다.

다음 시나리오 중 하나에서 이를 수행해야 합니다:

- [OpenID Connect 프로토콜로 마이그레이션](#migrate-to-generic-openid-connect-configuration)합니다.
- 다양한 수준의 인증을 제공합니다.

다음 예시 구성은 다양한 수준의 인증을 제공하는 방법을 보여줍니다. 하나는 2FA 옵션이고 하나는 2FA 옵션이 없습니다.

Linux 패키지 설치의 경우:

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect",
    label: "Provider name", # optional label for login button, defaults to "Openid Connect"
    icon: "<custom_provider_icon>",
    args: {
      name: "openid_connect",
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid","profile","email"],
      response_type: "code",
      issuer: "<your_oidc_url>",
      discovery: true,
      client_auth_method: "query",
      uid_field: "<uid_field>",
      send_scope_to_token_endpoint: "false",
      pkce: true,
      client_options: {
        identifier: "<your_oidc_client_id>",
        secret: "<your_oidc_client_secret>",
        redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback"
      }
    }
  },
  {
    name: "openid_connect_2fa",
    label: "Provider name 2FA", # optional label for login button, defaults to "Openid Connect"
    icon: "<custom_provider_icon>",
    args: {
      name: "openid_connect_2fa",
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid","profile","email"],
      response_type: "code",
      issuer: "<your_oidc_url>",
      discovery: true,
      client_auth_method: "query",
      uid_field: "<uid_field>",
      send_scope_to_token_endpoint: "false",
      pkce: true,
      client_options: {
        identifier: "<your_oidc_client_id>",
        secret: "<your_oidc_client_secret>",
        redirect_uri: "<your_gitlab_url>/users/auth/openid_connect_2fa/callback"
      }
    }
  }
]
```

자체 컴파일된 설치의 경우:

```yaml
  - { name: 'openid_connect',
      label: 'Provider name', # optional label for login button, defaults to "Openid Connect"
      icon: '<custom_provider_icon>',
      args: {
        name: 'openid_connect',
        strategy_class: "OmniAuth::Strategies::OpenIDConnect",
        scope: ['openid', 'profile', 'email'],
        response_type: 'code',
        issuer: '<your_oidc_url>',
        discovery: true,
        client_auth_method: 'query',
        uid_field: '<uid_field>',
        send_scope_to_token_endpoint: false,
        pkce: true,
        client_options: {
          identifier: '<your_oidc_client_id>',
          secret: '<your_oidc_client_secret>',
          redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback'
        }
      }
    }
  - { name: 'openid_connect_2fa',
      label: 'Provider name 2FA', # optional label for login button, defaults to "Openid Connect"
      icon: '<custom_provider_icon>',
      args: {
        name: 'openid_connect_2fa',
        strategy_class: "OmniAuth::Strategies::OpenIDConnect",
        scope: ['openid', 'profile', 'email'],
        response_type: 'code',
        issuer: '<your_oidc_url>',
        discovery: true,
        client_auth_method: 'query',
        uid_field: '<uid_field>',
        send_scope_to_token_endpoint: false,
        pkce: true,
        client_options: {
          identifier: '<your_oidc_client_id>',
          secret: '<your_oidc_client_secret>',
          redirect_uri: '<your_gitlab_url>/users/auth/openid_connect_2fa/callback'
        }
      }
    }
```

이 사용 사례에서는 회사 디렉터리의 기존 알려진 식별자를 기반으로 다양한 공급자 전체에서 `extern_uid`을 동기화할 수 있습니다.

이를 수행하려면 `uid_field`을 설정합니다. 다음 예시 코드는 이를 수행하는 방법을 보여줍니다:

```python
def sync_missing_provider(self, user: User, extern_uid: str)
  existing_identities = []
  for identity in user.identities:
      existing_identities.append(identity.get("provider"))

  local_extern_uid = extern_uid.lower()
  for provider in ("openid_connect_2fa", "openid_connect"):
      identity = [
          identity
          for identity in user.identities
          if identity.get("provider") == provider
          and identity.get("extern_uid").lower() != local_extern_uid
      ]
      if provider not in existing_identities or identity:
          if identity and identity[0].get("extern_uid") != "":
              logger.error(f"Found different identity for provider {provider} for user {user.id}")
              continue
          else:
              logger.info(f"Add identity 'provider': {provider}, 'extern_uid': {extern_uid} for user {user.id}")
              user.provider = provider
              user.extern_uid = extern_uid
              user = self.save_user(user)
  return user
```

자세한 내용은 [GitLab API 사용자 메서드 설명서](https://python-gitlab.readthedocs.io/en/stable/gl_objects/users.html#examples)를 참조하세요.

## OIDC 그룹 멤버십에 따라 사용자 구성 {#configure-users-based-on-oidc-group-membership}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

OIDC 그룹 멤버십을 구성하여 다음을 수행할 수 있습니다:

- 사용자가 특정 그룹의 멤버여야 합니다.
- 사용자를 [외부](../external_users.md) , 관리자 또는 [감사자](../auditor_users.md) 역할을 그룹 멤버십에 따라 할당합니다.

GitLab은 각 로그인 시 이러한 그룹을 확인하고 필요에 따라 사용자 속성을 업데이트합니다. 이 기능은 사용자를 GitLab [그룹](../../user/group/_index.md)에 자동으로 추가할 수 없습니다.

특정 그룹에 대해 정의된 값은 ID 공급자에서 반환된 값을 반영해야 합니다. 예를 들어 Microsoft Entra OIDC는 GroupID를 반환하므로 `required_groups` 구성은 `required_groups: ["55db8574-c392-4e8b-892d-1e086394be9c"]`와 같습니다.

### 필수 그룹 {#required-groups}

ID 공급자(IdP)는 OIDC 응답에서 GitLab으로 그룹 정보를 전달해야 합니다. 이 응답을 사용하여 사용자가 특정 그룹의 멤버여야 하도록 하려면 GitLab을 구성하여 다음을 식별합니다:

- `groups_attribute` 설정을 사용하여 OIDC 응답에서 그룹을 찾을 위치입니다.
- `required_groups` 설정을 사용하여 로그인하는 데 필요한 그룹 멤버십입니다.

`required_groups`을 설정하지 않거나 설정을 비워두면 IdP를 통해 OIDC로 인증된 모든 사용자가 GitLab을 사용할 수 있습니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             required_groups: ["Developer"]
           }
         }
       }
     }
   ]
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               required_groups: ["Developer"]
             }
           }
         }
       }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#self-compiled-installations)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

### 외부 그룹 {#external-groups}

IdP는 OIDC 응답에서 GitLab으로 그룹 정보를 전달해야 합니다. 이 응답을 사용하여 사용자를 [외부 사용자](../external_users.md)로 식별하려면 그룹 멤버십에 따라 GitLab을 구성하여 다음을 식별합니다:

- `groups_attribute` 설정을 사용하여 OIDC 응답에서 그룹을 찾을 위치입니다.
- 어느 그룹 멤버십이 사용자를 [외부 사용자](../external_users.md)로 식별해야 하는지 `external_groups` 설정을 사용합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             external_groups: ["Freelancer"]
           }
         }
       }
     }
   ]
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               external_groups: ["Freelancer"]
             }
           }
         }
       }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#self-compiled-installations)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

### 감사자 그룹 {#auditor-groups}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

IdP는 OIDC 응답에서 GitLab으로 그룹 정보를 전달해야 합니다. 이 응답을 사용하여 사용자를 그룹 멤버십에 따라 감사자로 할당하려면 GitLab을 구성하여 다음을 식별합니다:

- `groups_attribute` 설정을 사용하여 OIDC 응답에서 그룹을 찾을 위치입니다.
- 어느 그룹 멤버십이 사용자 감사자 액세스를 부여하는지 `auditor_groups` 설정을 사용합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email","groups"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             auditor_groups: ["Auditor"]
           }
         }
       }
     }
   ]
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email','groups'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               auditor_groups: ["Auditor"]
             }
           }
         }
       }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#self-compiled-installations)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

### 관리자 그룹 {#administrator-groups}

IdP는 OIDC 응답에서 GitLab으로 그룹 정보를 전달해야 합니다. 이 응답을 사용하여 사용자를 그룹 멤버십에 따라 관리자로 할당하려면 GitLab을 구성하여 다음을 식별합니다:

- `groups_attribute` 설정을 사용하여 OIDC 응답에서 그룹을 찾을 위치입니다.
- 어느 그룹 멤버십이 사용자 관리자 액세스를 부여하는지 `admin_groups` 설정을 사용합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             admin_groups: ["Admin"]
           }
         }
       }
     }
   ]
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               admin_groups: ["Admin"]
             }
           }
         }
       }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#self-compiled-installations)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

### ID 토큰의 사용자 지정 기간 구성 {#configure-a-custom-duration-for-id-tokens}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.8에 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/377654).

{{< /history >}}

기본적으로 GitLab ID 토큰은 120초 후에 만료됩니다.

ID 토큰의 사용자 지정 기간을 구성하려면:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['oidc_provider_openid_id_token_expire_in_seconds'] = 3600
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     oidc_provider:
      openid_id_token_expire_in_seconds: 3600
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#self-compiled-installations)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

## 단계별 인증 {#step-up-authentication}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed
- 상태:  실험

{{< /details >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용을 위해 준비되지 않았습니다.

경우에 따라 기본 인증 방법이 중요한 리소스나 위험도가 높은 작업을 보호하지 못합니다. 단계별 인증은 권한 있는 작업 또는 민감한 작업에 추가 계층을 추가합니다. 예를 들어 관리 영역에 액세스합니다.

단계별 인증을 사용하면 사용자가 특정 기능에 액세스할 수 있기 전에 등록된 [2단계 인증 방법](../../user/profile/account/two_factor_authentication.md)을 사용하여 추가 인증을 완료해야 합니다.

OIDC 표준에는 인증 컨텍스트 클래스 참조(`ACR`)가 포함됩니다. `ACR` 개념은 관리 모드와 같은 다양한 시나리오에서 단계별 인증을 구성하고 구현하는 데 도움이 됩니다.

이 기능은 [실험](../../policy/development_stages_support.md)이며 통지 없이 변경될 수 있습니다. 이 기능은 프로덕션 사용을 위해 준비되지 않았습니다. 이 기능을 사용하려면 프로덕션 외부에서 먼저 테스트해야 합니다.

### 관리 모드에 대한 단계별 인증 활성화 {#enable-step-up-authentication-for-admin-mode}

{{< history >}}

- GitLab 17.11에 [도입되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/474650) [플래그](../feature_flags/_index.md) 이름이 `omniauth_step_up_auth_for_admin_mode`입니다. 기본적으로 비활성화됨.

{{< /history >}} 관리 모드에 대한 단계별 인증을 활성화하려면:

1. GitLab 구성 파일(`gitlab.yml` 또는 `/etc/gitlab/gitlab.rb`)을 편집하여 특정 OmniAuth 공급자에 대한 단계별 인증을 활성화합니다.

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
           label: 'Provider name',
           args: {
             name: 'openid_connect',
             # ...
             allow_authorize_params: ["claims"], # Match this to the parameters defined in `step_up_auth => admin_mode => params`
           },
           step_up_auth: {
             admin_mode: {
               # The `id_token` field defines the claims that must be included with the token.
               # You can specify claims in one or both of the `required` or `included` fields.
               # The token must include matching values for every claim you define in these fields.
               id_token: {
                 # The `required` field defines key-value pairs that must be included with the ID token.
                 # The values must match exactly what is defined.
                 # In this example, the 'acr' (Authentication Context Class Reference) claim
                 # must have the value 'gold' to pass the step-up authentication challenge.
                 # This ensures a specific level of authentication assurance.
                 required: {
                   acr: 'gold'
                 },
                 # The `included` field also defines key-value pairs that must be included with the ID token.
                 # Multiple accepted values can be defined in an array. If an array is not used, the value must match exactly.
                 # In this example, the 'amr' (Authentication Method References) claim
                 # must have a value of either 'mfa' or 'fpt' to pass the step-up authentication challenge.
                 # This is useful for scenarios where the user must provide additional authentication factors.
                 included: {
                   amr: ['mfa', 'fpt']
                 },
               },
               # The `params` field defines any additional parameters that are sent during the authentication process.
               # In this example, the `claims` parameter is added to the authorization request and instructs the
               # identity provider to include an 'acr' claim with the value 'gold' in the ID token.
               # The 'essential: true' indicates that this claim is required for successful authentication.
               params: {
                 claims: {
                   id_token: {
                     acr: {
                       essential: true,
                       values: ['gold']
                     }
                   }
                 }
               },
               # Optional: Provide a custom documentation link for users who fail step-up authentication
               # This link is displayed when step-up authentication fails, directing users to
               # organization-specific authentication documentation.
               documentation_link: 'https://internal.example.com/path/to/documentation'
             },
           }
         }
   ```

1. 구성 파일을 저장하고 변경 사항을 적용하려면 GitLab을 다시 시작합니다.

> [!note]
> OIDC는 표준화되어 있지만 다양한 ID 공급자(IdP)는 고유한 요구 사항이 있을 수 있습니다. `params` 설정을 통해 단계별 인증에 필요한 매개변수를 정의할 수 있는 유연한 해시를 사용할 수 있습니다. 이러한 값은 각 IdP의 요구 사항에 따라 달라질 수 있습니다.

### Keycloak을 사용하는 단계별 인증 요구 {#require-step-up-authentication-with-keycloak}

Keycloak은 인증 수준을 정의하고 사용자 지정 브라우저 로그인 플로우를 사용하여 단계별 인증을 지원합니다.

Keycloak을 사용하여 관리 모드에 대한 단계별 인증을 요구하려면:

1. GitLab에서 [Keycloak 구성](#configure-keycloak)합니다.
1. Keycloak 설명서의 단계에 따라 [Keycloak에서 단계별 인증을 사용하여 브라우저 로그인 플로우 생성](https://www.keycloak.org/docs/latest/server_admin/#_step-up-flow)합니다.
1. GitLab 구성 파일(`gitlab.yml` 또는 `/etc/gitlab/gitlab.rb`)을 편집하여 Keycloak OIDC 공급자 구성에서 단계별 인증을 활성화합니다.

   Keycloak은 두 가지 다른 인증 수준을 정의합니다: `silver` 및 `gold`. 다음 예제는 `gold`을 사용하여 향상된 보안 수준을 나타냅니다.

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
           label: 'Keycloak',
           args: {
             name: 'openid_connect',
             # ...
             allow_authorize_params: ["claims"] # Match this to the parameters defined in `step_up_auth => admin_mode => params`
           },
           step_up_auth: {
             admin_mode: {
               id_token: {
                 # In this example, the 'acr' claim must have the value 'gold' that is also defined in the Keycloak documentation.
                 required: {
                   acr: 'gold'
                 }
               },
               params: {
                 claims: {
                   id_token: {
                     acr: { essential: true, values: ['gold'] }
                   }
                 },
               },
               # Optional: Add a custom documentation link for Keycloak-specific step-up authentication help
               documentation_link: 'https://internal.example.com/path/to/documentation'
             },
           }
         }
   ```

1. 구성 파일을 저장하고 변경 사항을 적용하려면 GitLab을 다시 시작합니다.

### Microsoft Entra ID를 사용하는 단계별 인증 요구 {#require-step-up-authentication-with-microsoft-entra-id}

Microsoft Entra ID(이전의 Azure Active Directory)는 [조건부 액세스 인증 컨텍스트](https://learn.microsoft.com/en-us/entra/identity-platform/developer-guide-conditional-access-authentication-context)를 통해 단계별 인증을 지원합니다. 올바른 구성을 정의하기 위해 Microsoft Entra ID 관리자와 함께 작업해야 합니다.

다음 양상을 고려합니다:

- 인증 컨텍스트 ID는 `acrs` 클레임을 통해서만 요청되며 다른 ID 공급자에 사용되는 ID 토큰 클레임 `acr`를 통해서는 요청되지 않습니다.
- 인증 컨텍스트 ID는 `c1`에서 `c99`까지의 고정 값을 사용하며 각각 조건부 액세스 정책이 있는 특정 인증 컨텍스트를 나타냅니다.
- 기본적으로 Microsoft Entra ID는 ID 토큰에 `acrs` 클레임을 포함하지 않습니다. 이를 활성화하려면 [선택적 클레임을 구성](https://learn.microsoft.com/en-us/entra/identity-platform/optional-claims?tabs=appui#configure-optional-claims-in-your-application)해야 합니다.
- 단계별 인증이 성공하면 응답이 JSON 문자열 배열로 [`acrs` 클레임](https://learn.microsoft.com/en-us/entra/identity-platform/access-token-claims-reference#payload-claims)을 반환합니다. 예: `acrs: ["c1", "c2", "c3"]`.

Microsoft Entra ID를 사용하여 관리 모드에 대한 단계별 인증을 요구하려면:

1. GitLab에서 [Microsoft Entra ID 구성](#configure-microsoft-azure)합니다.
1. Microsoft Entra ID 설명서의 단계에 따라 [Microsoft Entra ID에서 조건부 액세스 인증 컨텍스트 정의](https://learn.microsoft.com/en-us/entra/identity-platform/developer-guide-conditional-access-authentication-context)합니다.
1. Microsoft Entra ID에서 [ID 토큰에 포함할 선택적 클레임 `acrs` 정의](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)합니다.
1. GitLab 구성 파일(`gitlab.yml` 또는 `/etc/gitlab/gitlab.rb`)을 편집하여 Microsoft Entra ID 공급자 구성에서 단계별 인증을 활성화합니다:

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
         label: 'Azure OIDC',
         args: {
           name: 'openid_connect',
           # ...
           allow_authorize_params: ["claims"] # Match this to the parameters defined in `step_up_auth => admin_mode => params`
         },
         step_up_auth: {
           admin_mode: {
             id_token: {
               # In this example, the Microsoft Entra ID administrators have defined `c20`
               # as the authentication context ID with the desired security level and
               # an optional claim `acrs` to be included in the ID token.
               # The `included` field declares that the id token claim `acrs` must include the value `c20`.
               included: {
                 acrs: ["c20"],
               },
             },
             params: {
               claims: {
                 id_token: {
                   acrs: { essential: true, value: 'c20' }
                 }
               },
             },
             # Optional: Add a custom documentation link for Microsoft Entra ID step-up authentication
             documentation_link: 'https://internal.example.com/path/to/documentation'
           },
         }
       }
   ```

1. 구성 파일을 저장하고 변경 사항을 적용하려면 GitLab을 다시 시작합니다.

### 그룹에 대한 단계별 인증 공급자 추가 {#add-a-step-up-authentication-provider-for-groups}

{{< history >}}

- GitLab 18.4에 [도입되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/556943) [플래그](../feature_flags/_index.md) 이름이 `omniauth_step_up_auth_for_namespace`입니다. 기본적으로 비활성화됨.

{{< /history >}}

인스턴스의 모든 그룹에서 사용 가능한 단계별 인증 공급자를 추가할 수도 있습니다. 이것은 그룹이 단계별 인증을 사용하도록 강제하지 않으며 각 그룹은 여전히 개별적으로 [설정](#force-step-up-authentication-for-a-group)해야 합니다.

그룹에 대한 단계별 인증 공급자를 추가하려면:

1. GitLab 구성 파일(`gitlab.yml` 또는 `/etc/gitlab/gitlab.rb`)을 편집하여 특정 OmniAuth 공급자에 대한 단계별 인증을 활성화합니다.

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
           label: 'Provider name',
           args: {
             name: 'openid_connect',
             # ...
             allow_authorize_params: ["claims"], # Match this to the parameters defined in `step_up_auth => admin_mode => params`
           },
           step_up_auth: {
             # Unlike step-up authentication configuration for Admin Mode, you use the `namespace`
             # object. This is because you're adding step-up authentication to access the entire
             # group, not just Admin Mode.
             namespace : {
               # The `id_token` field defines the claims that must be included with the token.
               # You can specify claims in one or both of the `required` or `included` fields.
               # The token must include matching values for every claim you define in these fields.
               id_token: {
                 # The `required` field defines key-value pairs that must be included with the ID token.
                 # The values must match exactly what is defined.
                 # In this example, the 'acr' (Authentication Context Class Reference) claim
                 # must have the value 'gold' to pass the step-up authentication challenge.
                 # This ensures a specific level of authentication assurance.
                 required: {
                   acr: 'gold'
                 },
                 # The `included` field also defines key-value pairs that must be included with the ID token.
                 # Multiple accepted values can be defined in an array. If an array is not used, the value must match exactly.
                 # In this example, the 'amr' (Authentication Method References) claim
                 # must have a value of either 'mfa' or 'fpt' to pass the step-up authentication challenge.
                 # This is useful for scenarios where the user must provide additional authentication factors.
                 included: {
                   amr: ['mfa', 'fpt']
                 },
               },
               # The `params` field defines any additional parameters that are sent during the authentication process.
               # In this example, the `claims` parameter is added to the authorization request and instructs the
               # identity provider to include an 'acr' claim with the value 'gold' in the ID token.
               # The 'essential: true' indicates that this claim is required for successful authentication.
               params: {
                 claims: {
                   id_token: {
                     acr: {
                       essential: true,
                       values: ['gold']
                     }
                   }
                 }
               }
             },
           }
         }
   ```

1. 구성 파일을 저장하고 변경 사항을 적용하려면 GitLab을 다시 시작합니다.

### 그룹에 대한 단계별 인증 강제 {#force-step-up-authentication-for-a-group}

사용자가 그룹에 액세스하기 전에 단계별 인증을 완료하도록 강제할 수 있습니다. 이 설정은 각 그룹에 대해 개별적으로 관리되지만 전체 인스턴스에 대해 이전에 추가된 단계별 인증 공급자가 필요합니다.

전제 조건:

- [인스턴스의 그룹에 대한 단계별 인증 공급자](#add-a-step-up-authentication-provider-for-groups).
- 소유자 역할이 있어야 합니다.

그룹에 대한 단계별 인증을 강제하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **권한 및 그룹 기능** 섹션을 펼칩니다.
1. 단계별 인증에서 사용 가능한 인증 공급자를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 단계별 인증에 대한 사용자 지정 설명서 링크 추가 {#add-custom-documentation-links-for-step-up-authentication}

단계별 인증이 실패하면 GitLab은 사용자가 조직의 인증 요구 사항을 이해하는 데 도움이 되는 사용자 지정 설명서 링크를 표시할 수 있습니다. 이 기능을 통해 관리자는 사용자를 내부 설명서 또는 도움말 리소스로 보내는 조직별 지침을 제공할 수 있습니다.

사용자 지정 설명서 링크를 추가하려면:

1. GitLab 구성 파일(`gitlab.yml` 또는 `/etc/gitlab/gitlab.rb`)을 편집하여 `documentation_link` 필드를 `step_up_auth => admin_mode`에 추가합니다

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
           label: 'Corporate SSO',
           # ... other provider configuration ...
           step_up_auth: {
             admin_mode: {
               # ... id_token and params configuration ...
               documentation_link: 'https://internal.example.com/path/to/documentation'
             }
           }
         }
   ```

1. 구성 파일을 저장하고 변경 사항을 적용하려면 GitLab을 다시 시작합니다.

사용자가 단계별 인증에 실패하면 실패한 공급자와 관련된 설명서로 연결되는 유용한 오류 메시지가 표시됩니다. 링크는 단계별 인증이 실패한 공급자에 대해서만 표시되므로 지침이 더 관련성 있고 실행 가능합니다.

> [!note]
> 설명서 링크의 모범 사례:
>
> - 보안을 위해 HTTPS URL을 사용합니다.
> - 조직의 특정 인증 요구 사항을 설명하는 내부 설명서로 연결합니다.
> - `MFA` 또는 기타 필수 인증 방법을 활성화하는 방법에 대한 정보를 포함합니다.

### 세션 만료 비활성화 {#disable-session-expiration}

기본적으로 단계별 인증 세션은 ID 공급자(IdP) 토큰 만료 시간에 따라 만료되며, 일반적으로 약 10분입니다.

`session_expiration_enabled` 설정으로 세션 만료를 제어할 수 있습니다:

| 설정                                      | 동작 |
| -------------------------------------------- | -------- |
| `session_expiration_enabled: true`(기본값) | 단계별 인증이 IdP 토큰 `exp` 클레임에 따라 만료됩니다. 이것은 일반적으로 약 10분입니다. |
| `session_expiration_enabled: false`          | 단계별 인증은 사용자가 로그아웃할 때까지 전체 사용자 세션 동안 유효하게 유지됩니다. |

> [!warning]
> 세션 만료를 비활성화하면 사용자가 정기적으로 ID를 재확인하기보다는 세션당 한 번만 인증합니다. 보안 요구 사항이 세션 수명 단계별 인증을 허용하는 경우에만 이 설정을 비활성화합니다.

세션 만료를 비활성화하려면:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         # ... other args ...
       },
       step_up_auth: {
         session_expiration_enabled: false,  # Disable session expiration
         admin_mode: {
           # ... admin_mode config ...
         },
         namespace: {
           # ... namespace config ...
         }
       }
     }
   ]
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'openid_connect',
             label: 'Provider name',
             args: {
               name: 'openid_connect',
               # ... other args ...
             },
             step_up_auth: {
               session_expiration_enabled: false,
               admin_mode: {
                 # ... admin_mode config ...
               },
               namespace: {
                 # ... namespace config ...
               }
             }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 문제 해결 {#troubleshooting}

1. `discovery`이 `true`로 설정되어 있는지 확인합니다. 이를 `false`으로 설정하면 OpenID가 작동하는 데 필요한 모든 URL과 키를 지정해야 합니다.
1. 시스템 시계를 확인하여 시간이 제대로 동기화되어 있는지 확인합니다.
1. [OmniAuth OpenID Connect 설명서](https://github.com/omniauth/omniauth_openid_connect)에서 언급한 대로 `issuer`이 Discovery URL의 기본 URL과 일치하는지 확인합니다. 예를 들어 `https://accounts.google.com`은 URL `https://accounts.google.com/.well-known/openid-configuration`에 사용됩니다.
1. OpenID Connect 클라이언트는 `client_auth_method`이 정의되지 않았거나 `basic`로 설정된 경우 HTTP 기본 인증을 사용하여 OAuth 2.0 액세스 토큰을 전송합니다. `userinfo` 엔드포인트를 검색할 때 401 오류가 표시되면 OpenID 웹 서버 구성을 확인합니다. 예를 들어 [`oauth2-server-php`](https://github.com/bshaffer/oauth2-server-php) 의 경우 [Apache에 구성 매개변수를 추가](https://github.com/bshaffer/oauth2-server-php/issues/926#issuecomment-387502778)해야 할 수 있습니다.
1. **Step-up authentication only**:  `step_up_auth => admin_mode => params`에 정의된 모든 매개변수가 `args => allow_authorize_params`에도 정의되어 있는지 확인합니다. 여기에는 IdP 권한 부여 엔드포인트로 리디렉션하는 데 사용되는 요청 쿼리 매개변수의 매개변수가 포함됩니다.
