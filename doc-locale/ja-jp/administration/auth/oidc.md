---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 認証プロバイダーとしてOpenID Connectを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

[OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html)をOmniAuthプロバイダーとして利用するクライアントアプリケーションとして、GitLabを設定できます。

OpenID Connect OmniAuthプロバイダーを有効にするには、OpenID Connectプロバイダーにアプリケーションを登録する必要があります。OpenID Connectプロバイダーは、使用するクライアントの詳細とシークレットを提供します。

1. GitLabサーバーで、設定ファイルを開きます。

   Linuxパッケージインストールの場合:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   自己コンパイルインストールの場合:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. [共通設定](../../integration/omniauth.md#configure-common-settings)で、`openid_connect`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。

1. プロバイダー設定を追加します。

   Linuxパッケージインストールの場合:

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

   Linuxパッケージインストールで複数のIdentity Providerを使用する場合:

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

   {{< alert type="note" >}}

   OIDCでの複数のIdentity Providerを使用する場合の詳細については、[イシュー5992](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5992)を参照してください。

   {{< /alert >}}

   自己コンパイルインストールの場合:

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

   {{< alert type="note" >}}

   各設定オプションの詳細については、[OmniAuth OpenID Connectの使用方法に関するドキュメント](https://github.com/omniauth/omniauth_openid_connect#usage)および[OpenID Connect Core 1.0の仕様](https://openid.net/specs/openid-connect-core-1_0.html)を参照してください。

   {{< /alert >}}

1. プロバイダーを設定する際は、ご利用のOpenID Connectクライアントの設定に合わせてプロバイダーの値を変更する必要があります。次の情報を参考にしてください。

   - `<your_oidc_label>`は、ログインページに表示されるラベルです。
   - `<custom_provider_icon>`（オプション）は、ログインページに表示されるアイコンです。主要なソーシャルログインプラットフォームのアイコンはGitLabに組み込まれていますが、このパラメーターを指定することで、これらのアイコンを上書きできます。GitLabは、ローカルパスと絶対URLの両方を受け入れます。GitLabには、主要なソーシャルログインプラットフォームのほとんどのアイコンが組み込まれていますが、外部URL、または独自のアイコンファイルの絶対パスまたは相対パスを指定することで、これらのアイコンを上書きできます。
     - ローカルの絶対パスを使用する場合は、プロバイダーの設定で`icon: <path>/<to>/<your-icon>`と指定します。
       - アイコンファイルは`/opt/gitlab/embedded/service/gitlab-rails/public/<path>/<to>/<your-icon>`に保存します。
       - アイコンファイルには`https://gitlab.example/<path>/<to>/<your-icon>`でアクセスできます。
     - ローカルの相対パスを使用する場合は、プロバイダーの設定で`icon: <your-icon>`と指定します。
       - アイコンファイルは`/opt/gitlab/embedded/service/gitlab-rails/public/images/<your-icon>`に保存します。
       - アイコンファイルには`https://gitlab.example.com/images/<your-icon>`でアクセスできます。
   - `<your_oidc_url>`（オプション）は、OpenID Connectプロバイダーを指すURLです（例: `https://example.com/auth/realms/your-realm`）。この値を指定しない場合、URLは`client_options`に基づき次の形式で構築されます。`<client_options.scheme>://<client_options.host>:<client_options.port>`
   - `discovery`が`true`に設定されている場合、OpenID Connectプロバイダーは`<your_oidc_url>/.well-known/openid-configuration`を使用してクライアントオプションを自動的に検出しようとします。デフォルトは`false`です。
   - `client_auth_method`（オプション）は、OpenID Connectプロバイダーに対してクライアントを認証する際に使用する方法を指定します。
     - サポートされている値は次のとおりです。
       - `basic` - HTTP基本認証。
       - `jwt_bearer` - JWTベースの認証（秘密キーとクライアントシークレットによる署名）。
       - `mtls` - 相互TLSまたはX.509証明書による検証。
       - その他の値はすべて、リクエスト本文にクライアントIDとシークレットを含めてポストします。
     - この値を指定しない場合、デフォルトは`basic`です。
   - `<uid_field>`（オプション）は、`user_info.raw_attributes`に含まれるフィールド名で、`uid`の値を定義します（例: `preferred_username`）。この値を指定しない場合、または設定した値を持つフィールドが`user_info.raw_attributes`の詳細に存在しない場合、`uid`には`sub`フィールドを使用します。
   - `send_scope_to_token_endpoint`はデフォルトで`true`であるため、`scope`パラメーターは通常、トークンエンドポイントへのリクエストに含まれます。ただし、OpenID Connectプロバイダーがこのようなリクエストで`scope`パラメーターを受け入れない場合は、これを`false`に設定します。
   - `pkce`（オプション）: [Proof Key for Code Exchange](https://www.rfc-editor.org/rfc/rfc7636)（PKCE）を有効にします。[GitLab 15.9](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/109557)で利用可能です。
   - `client_options`は、OpenID Connectクライアント固有のオプションです。具体的には次のとおりです。
     - `identifier`は、OpenID Connectサービスプロバイダーで設定されているクライアント識別子です。
     - `secret`は、OpenID Connectサービスプロバイダーで設定されているクライアントシークレットです。たとえば、[OmniAuth OpenID Connect](https://github.com/omniauth/omniauth_openid_connect)ではこれが必要です。サービスプロバイダーがシークレットを必要としない場合は、任意の値を指定します。その値は無視されます。
     - `redirect_uri`は、ログインに成功した後、ユーザーをリダイレクトするGitLabのURLです（例: `http://example.com/users/auth/openid_connect/callback`）。
     - `end_session_endpoint`（オプション）は、セッションを終了するエンドポイントのURLです。自動検出が無効になっているか失敗した場合は、このURLを指定できます。
     - 次の`client_options`は、自動検出が無効になっているか失敗した場合を除き、オプションです。
       - `authorization_endpoint`: エンドユーザーを認可するエンドポイントのURL
       - `token_endpoint`: アクセストークンを提供するエンドポイントのURL
       - `userinfo_endpoint`: ユーザー情報を提供するエンドポイントのURL
       - `jwks_uri`: トークン署名者がキーを公開するエンドポイントのURL

1. 設定ファイルを保存します。
1. 変更を有効にするには、次の手順に従います。

   - Linuxパッケージを使用してGitLabをインストールした場合は、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
   - GitLabインストールを自分でコンパイルした場合は、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

サインインページで、標準のサインインフォームの下にOpenID Connectオプションが表示されます。このオプションを選択すると、認証プロセスが開始されます。クライアントによる確認が必要な場合、OpenID Connectプロバイダーは、サインインとGitLabアプリケーションの認可を求めます。その後、GitLabにリダイレクトされ、サインインが完了します。

## 設定例

次の設定は、Linuxパッケージインストールを使用している場合に、さまざまなプロバイダーでOpenIDをセットアップする方法を示しています。

### Googleを設定する

詳細については、[Googleのドキュメント](https://developers.google.com/identity/openid-connect/openid-connect)を参照してください。

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

### Microsoft Azureを設定する

Microsoft AzureにおけるOpenID Connect（OIDC）プロトコルは、[Microsoft IDプラットフォーム（v2）エンドポイント](https://learn.microsoft.com/en-us/previous-versions/azure/active-directory/azuread-dev/azure-ad-endpoint-comparison)を使用します。開始するには、[Azureポータル](https://portal.azure.com)にサインインします。アプリには、次の情報が必要です。

- テナントID。すでにお持ちの場合があります。詳細については、[Microsoft Azureのテナント](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant)に関するドキュメントを参照してください。
- クライアントIDとクライアントシークレット。[Microsoftのアプリケーション登録に関するクイックスタート](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)ドキュメントの手順に従って、アプリ用のテナントID、クライアントID、クライアントシークレットを取得します。

{{< alert type="note" >}}

Azureによってプロビジョニングされるすべてのアカウントに、メールアドレスが定義されている必要があります。メールアドレスが定義されていない場合、Azureはランダムに生成されたアドレスを割り当てます。[ドメインのサインアップ制限](../settings/sign_up_restrictions.md#allow-or-deny-sign-ups-using-specific-email-domains)を設定している場合、このランダムなアドレスが原因でアカウントが作成できない可能性があります。

{{< /alert >}}

Linuxパッケージインストールにおける設定ブロックの例:

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

Microsoftは、自社のプラットフォームが[OIDCプロトコル](https://learn.microsoft.com/en-us/entra/identity-platform/v2-protocols-oidc)でどのように動作するのかを文書化しています。

#### Microsoft Entraのカスタム署名キー

[SAMLクレームマッピング機能](https://learn.microsoft.com/en-us/entra/identity-platform/saml-claims-customization)を使用しているためにアプリケーションでカスタム署名キーを使用している場合は、OpenIDプロバイダーを次のように設定する必要があります。

- `args.discovery`を省略するか、`false`に設定して、OpenID Connectのディスカバリを無効にします。
- `client_options`で、次のように指定します。
  - `appid`クエリパラメーターを含めた`jwks_uri`を指定する: `https://login.microsoftonline.com/<YOUR-TENANT-ID>/discovery/v2.0/keys?appid=<YOUR APP CLIENT ID>`
  - `end_session_endpoint`
  - `authorization_endpoint`
  - `userinfo_endpoint`

Linuxパッケージインストールにおける設定例:

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

`KidNotFound`メッセージが表示されて認証エラーが発生した場合、原因はおそらく、`appid`クエリパラメーターがないか、間違っています。Microsoftから返されたIDトークンを、`jwks_uri`エンドポイントで提供されるキーで検証できない場合、GitLabはこのエラーを発生させます。

詳細については、[Microsoft Entraのトークンの検証に関するドキュメント](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens#validate-tokens)を参照してください。

#### 汎用OpenID Connect設定に移行する

`azure_activedirectory_v2`と`azure_oauth2`のどちらからでも、汎用OpenID Connect設定に移行できます。

まず、`uid_field`を設定します。`uid_field`、および`uid_field`として設定できる`sub`クレームは、プロバイダーによって異なります。`uid_field`を設定せずにサインインすると、GitLab内に追加のアイデンティティが作成され、手動で修正する必要があります。

| プロバイダー                                                                                                        | `uid_field` | サポート情報  |
|-----------------------------------------------------------------------------------------------------------------|-------|-----------------------------------------------------------------------|
| [`omniauth-azure-oauth2`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/omniauth-azure-oauth2) | `sub` | `info`オブジェクト内で追加の属性`oid`と`tid`が提供されます。 |
| [`omniauth-azure-activedirectory-v2`](https://github.com/RIPAGlobal/omniauth-azure-activedirectory-v2/)         | `oid` | 移行する際は、`uid_field`として`oid`を設定する必要があります。 |
| [`omniauth_openid_connect`](https://github.com/omniauth/omniauth_openid_connect/)                               | `sub` | 別のフィールドを使用するには、`uid_field`を指定します。 |

汎用OpenID Connect設定に移行するには、設定を更新する必要があります。

Linuxパッケージインストールの場合、次のように設定を更新します。

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

Helmインストールの場合:

YAMLファイル（例: `provider.yaml`）に[プロバイダーの設定](https://docs.gitlab.com/charts/charts/globals.html#providers)を追加します。

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

GitLab 17.0以降へのアップグレードに伴い、`azure_oauth2`から`omniauth_openid_connect`に移行する際、組織に設定される`sub`クレームの値が異なる場合があります。`azure_oauth2`はMicrosoft V1エンドポイントを使用しますが、`azure_activedirectory_v2`および`omniauth_openid_connect`はどちらも、共通の`sub`値を持つMicrosoft V2エンドポイントを使用します。

- **Entra IDにメールアドレスを登録しているユーザーに対して**、メールアドレスへのフォールバックを許可してユーザーのアイデンティティを更新するには、次のように設定します。
  - Linuxパッケージインストールの場合: [`omniauth_auto_link_user`](../../integration/omniauth.md#link-existing-users-to-omniauth-users)
  - Helmインストールの場合: [`autoLinkUser`](https://docs.gitlab.com/charts/charts/globals.html#omniauth)

- **メールアドレスを持たないユーザーに対して**、管理者は次のいずれかの操作を行う必要があります。

  - 別の認証方法を設定するか、GitLabのユーザー名とパスワードによるサインインを有効にします。ユーザーはその後サインインして、自分のプロファイルを使用してAzureのアイデンティティを手動でリンクできます。
  - 既存の`azure_oauth2`に加えて、OpenID Connectを新しいプロバイダーとして実装します。これにより、ユーザーがOAuth2を通じてサインインし、OpenID Connectのアイデンティティをリンクできるようになります（前述の方法と同様）。この方法は、`auto_link_user`が有効になっている限り、メールアドレスを持つユーザーにも有効です。
  - `extern_uid`を手動で更新します。これを行うには、[APIまたはRailsコンソール](../../integration/omniauth.md#change-apps-or-configuration)を使用して、各ユーザーの`extern_uid`を更新します。この方法は、インスタンスがすでに17.0以降にアップグレードされており、ユーザーがサインインを試みた場合に必要になることがあります。

{{< alert type="note" >}}

GitLabアカウントのプロビジョニング時に`email`クレームが存在しない、または空白だった場合、`azure_oauth2`はEntra IDの`upn`クレームをメールアドレスとして使用した可能性があります。

{{< /alert >}}

### Microsoft Azure Active Directory B2Cを設定する

GitLabを[Azure Active Directory B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/overview)と連携させるには、特別な設定が必要です。開始するには、[Azureポータル](https://portal.azure.com)にサインインします。アプリには、Azureからの次の情報が必要です。

- テナントID。すでにお持ちの場合があります。詳細については、[Microsoft Azureのテナント](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant)に関するドキュメントを参照してください。
- クライアントIDとクライアントシークレット。[Microsoftのチュートリアル](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga)ドキュメントの手順に従って、アプリ用のクライアントIDとクライアントシークレットを取得します。
- ユーザーフローまたはポリシー名。[Microsoftのチュートリアル](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-user-flow)の手順に従います。

アプリを設定します。

1. アプリの`Redirect URI`を設定します。たとえば、GitLabドメインが`gitlab.example.com`の場合、アプリの`Redirect URI`を、`https://gitlab.example.com/users/auth/openid_connect/callback`に設定します。

1. [IDトークンを有効にします](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga#enable-id-token-implicit-grant)。

1. アプリに次のAPI権限を追加します。

   - `openid`
   - `offline_access`

#### カスタムポリシーを設定する

Azure B2Cは、[ユーザーのログインに関するビジネスロジックを定義する方法を2つ提供しています](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview)。

- [ユーザーフロー](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview#user-flows)
- [カスタムポリシー](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview#custom-policies)

標準のAzure B2Cユーザーフローは[OpenIDの`email`クレームを送信しない](https://github.com/MicrosoftDocs/azure-docs/issues/16566)ため、カスタムポリシーが必要です。そのため、標準のユーザーフローは[`allow_single_sign_on`または`auto_link_user`パラメーター](../../integration/omniauth.md#configure-common-settings)では機能しません。標準のAzure B2Cポリシーでは、GitLabは新しいアカウントを作成したり、メールアドレスを持つ既存のアカウントにリンクしたりできません。

まず、[カスタムポリシーを作成します](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy)。

Microsoftの手順では、[カスタムポリシースターターパック](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#custom-policy-starter-pack)において`SocialAndLocalAccounts`を使用していますが、`LocalAccounts`はローカルActive Directoryアカウントに対して認証を行います。[ポリシーをアップロード](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#upload-the-policies)する前に、次の操作を行います。

1. `email`クレームをエクスポートするには、`SignUpOrSignin.xml`を変更します。次の行を置き換えます。

   ```xml
   <OutputClaim ClaimTypeReferenceId="email" />
   ```

   変更後は次のようになります。

   ```xml
   <OutputClaim ClaimTypeReferenceId="signInNames.emailAddress" PartnerClaimType="email" />
   ```

1. B2CでOIDCディスカバリを機能させるには、[OIDC仕様](https://openid.net/specs/openid-connect-discovery-1_0.html#rfc.section.4.3)と互換性のある発行者をポリシーに設定します。[トークンの互換性設定](https://learn.microsoft.com/en-us/azure/active-directory-b2c/configure-tokens?pivots=b2c-custom-policy#token-compatibility-settings)を参照してください。`TrustFrameworkBase.xml`の`JwtIssuer`で、`IssuanceClaimPattern`を`AuthorityWithTfp`に設定します。

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

1. [ポリシーをアップロードします](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#upload-the-policies)。既存のポリシーを更新する場合は、既存のファイルを上書きします。

1. 発行者URLを指定する際は、サインインポリシーを使用します。発行者URLの形式は次のとおりです。

   ```markdown
   https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/<YOUR-SIGN-IN-POLICY-NAME>/v2.0/
   ```

   ポリシー名はURL内では小文字になります。たとえば、`B2C_1A_signup_signin`ポリシーの場合は、`b2c_1a_signup_sigin`と小文字で指定します。

   末尾にスラッシュを付加してください。

1. OIDCディスカバリURLと発行者URLの動作を確認し、`.well-known/openid-configuration`を発行者URLに付加します。

   ```markdown
   https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/<YOUR-SIGN-IN-POLICY-NAME>/v2.0/.well-known/openid-configuration
   ```

   たとえば、`domain`が`example.b2clogin.com`で、テナントIDが`fc40c736-476c-4da1-b489-ee48cee84386`の場合、`curl`と`jq`を使用して発行者を抽出できます。

   ```shell
   $ curl --silent "https://example.b2clogin.com/tfp/fc40c736-476c-4da1-b489-ee48cee84386/b2c_1a_signup_signin/v2.0/.well-known/openid-configuration" | jq .issuer
   "https://example.b2clogin.com/tfp/fc40c736-476c-4da1-b489-ee48cee84386/b2c_1a_signup_signin/v2.0/"
   ```

1. `signup_signin`に使用するカスタムポリシーで、発行者URLを設定します。たとえば、Linuxパッケージインストールにおいて、`b2c_1a_signup_signin`のカスタムポリシーを使用した場合の設定は次のとおりです。

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

#### Azure B2Cの問題を解決する

- `yourtenant.onmicrosoft.com`、`ProxyIdentityExperienceFrameworkAppId`、`IdentityExperienceFrameworkAppId`のすべての箇所が、B2Cテナントのホスト名およびXMLポリシーファイル内の対応するクライアントIDと一致していることを確認します。
- アプリのリダイレクトURIとして`https://jwt.ms`を追加し、[カスタムポリシーテスター](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#test-the-custom-policy)を使用します。ペイロードに、ユーザーのメールアクセスと一致する`email`が含まれていることを確認します。
- カスタムポリシーを有効にした後、ユーザーがサインインしようとすると、`Invalid username or password`と表示される場合があります。これは、`IdentityExperienceFramework`アプリの設定に問題がある可能性があります。[こちらのMicrosoftのコメント](https://learn.microsoft.com/en-us/answers/questions/50355/unable-to-sign-on-using-custom-policy?childtoview=122370#comment-122370)を参照してください。このコメントでは、アプリのmanifestに次の設定が含まれているかを確認することが推奨されています。

  - `"accessTokenAcceptedVersion": null`
  - `"signInAudience": "AzureADMyOrg"`

この設定は、`IdentityExperienceFramework`アプリの作成時に使用した`Supported account types`の設定に対応しています。

### Keycloakを設定する

GitLabは、HTTPSを使用するOpenIDプロバイダーと連携します。HTTPを使用するKeycloakサーバーをセットアップすることもできますが、GitLabが通信できるのはHTTPSを使用するKeycloakサーバーのみです。

トークンの署名には、対称キー暗号化アルゴリズム（例: HS256やHS358）ではなく、公開キー暗号化アルゴリズム（例: RSA256やRSA512）を使用するようにKeycloakを設定してください。公開キー暗号化アルゴリズムには次の利点があります。

- 簡単に設定できる。
- 秘密キーが漏えいした場合はセキュリティ上重大な結果を招く可能性があるため、公開キー暗号化アルゴリズムのほうが安全性が高い。

1. Keycloak管理コンソールを開きます。
1. **Realm Settings（レルム設定） > Tokens（トークン） > Default Signature Algorithm（デフォルト署名アルゴリズム）**を選択します。
1. 署名アルゴリズムを設定します。

Linuxパッケージインストールにおける設定ブロックの例:

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

#### 対称キーアルゴリズムでKeycloakを設定する

{{< alert type="warning" >}}

以下の手順は情報の完全性を保つために記載されていますが、対称キー暗号化はどうしても必要な場合にのみ使用してください。

{{< /alert >}}

対称キー暗号化を使用するには、次の手順に従います。

1. Keycloakデータベースからシークレットキーを抽出します。Keycloakでは、この値をWebインターフェースでは公開していません。Webインターフェースに表示されるクライアントシークレットはOAuth 2.0クライアントシークレットであり、JSON Webトークンの署名に使用されるシークレットとは異なります。

   たとえば、PostgreSQLをKeycloakのバックエンドデータベースとして使用する場合:

   - データベースコンソールにサインインします。
   - 次のSQLクエリを実行して、キーを抽出します。

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

     この例では、2つの秘密キーがあります。1つはHS256用（`hmac-generated`）、もう1つはHS384用（`fallback-HS384`）です。GitLabの設定には、最初の`value`を使用します。

1. `value`を標準のbase64に変換します。[**Invalid signature with HS256 token**（HS256トークンでの無効な署名）という投稿](https://keycloak.discourse.group/t/invalid-signature-with-hs256-token/3228/9)で説明されているように、`value`は、RFC 4648の[**Base 64 Encoding with URL and Filename Safe Alphabet**（URLおよびファイル名に安全なアルファベットによるBase64エンコーディング）セクション](https://datatracker.ietf.org/doc/html/rfc4648#section-5)の形式でエンコードされています。これは、[RFC 2045で定義されている標準のbase64に変換](https://datatracker.ietf.org/doc/html/rfc2045)する必要があります。次のRubyスクリプトはその変換を行います。

   ```ruby
   require 'base64'

   value = "lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62-sqGc8drp3XW-wr93zru8PFsQokHZZuJJbaUXvmiOftCZM3C4KW3-g"
   Base64.encode64(Base64.urlsafe_decode64(value))
   ```

   これにより、次のような値が得られます。

   ```markdown
   lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62+sqGc8drp3XW+wr93zru8PFsQokH\nZZuJJbaUXvmiOftCZM3C4KW3+g==\n
   ```

1. このbase64エンコードされたシークレットを`jwt_secret_base64`に指定します。次に例を示します。

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

`JSON::JWS::VerificationFailed`エラーが表示された場合は、間違ったシークレットを指定しています。

### Casdoor

GitLabは、HTTPSを使用するOpenIDプロバイダーと連携します。Casdoorを使用してOpenID経由でGitLabに接続するには、HTTPSを使用してください。

アプリに対して、Casdoorで次の手順を実行します。

1. クライアントIDとクライアントシークレットを取得します。
1. GitLabのリダイレクトURLを追加します。たとえば、GitLabドメインが`gitlab.example.com`の場合、Casdoorアプリに次の`Redirect URI`が設定されていることを確認してください。`https://gitlab.example.com/users/auth/openid_connect/callback`

詳細については、[Casdoorのドキュメント](https://casdoor.org/docs/integration/ruby/gitlab/)を参照してください。

Linuxパッケージインストールにおける設定例（ファイルパス: `/etc/gitlab/gitlab.rb`）:

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

自己コンパイルインストールにおける設定例（ファイルパス: `config/gitlab.yml`）:

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

## 複数のOpenID Connectプロバイダーを設定する

複数のOpenID Connect（OIDC）プロバイダーを使用するようにアプリケーションを設定できます。そのためには、設定ファイルで`strategy_class`を明示的に指定します。

これは、次のいずれかのシナリオで行う必要があります。

- [OpenID Connectプロトコルに移行する](#migrate-to-generic-openid-connect-configuration)。
- 異なるレベルの認証を提供する。

次の設定例は、2FAがある場合と2FAがない場合という、異なるレベルの認証を提供する方法を示しています。

Linuxパッケージインストールの場合:

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

自己コンパイルインストールの場合:

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

このユースケースでは、社内ディレクトリ内の既知の識別子に基づいて、異なるプロバイダー間で`extern_uid`を同期させたい場合があります。

これを行うには、`uid_field`を設定します。次のコード例は、その設定方法を示しています。

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

詳細については、[GitLab APIのユーザーメソッドに関するドキュメント](https://python-gitlab.readthedocs.io/en/stable/gl_objects/users.html#examples)を参照してください。

## OIDCグループメンバーシップに基づいてユーザーを設定する

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/209898)されました。

{{< /history >}}

OIDCグループメンバーシップを設定して、次のことを行えます。

- ユーザーが特定のグループのメンバーであることを必須にする。
- グループメンバーシップに基づいて、ユーザーに[外部](../external_users.md)、管理者、[監査担当者](../auditor_users.md)のいずれかのロールを割り当てる。

GitLabは、サインインのたびにこれらのグループをチェックし、必要に応じてユーザー属性を更新します。ただし、この機能では、GitLab[グループ](../../user/group/_index.md)にユーザーを自動的に追加することは**できません**。

### 必須グループ

Identity Provider（IdP）は、OIDC応答でグループ情報をGitLabに渡す必要があります。この応答を使用して、ユーザーが特定のグループのメンバーであることを必須とするには、次を情報を特定できるようにGitLabを設定します。

- OIDC応答内でグループがある場所（`groups_attribute`設定を使用）
- サインインに必要なグループメンバーシップ（`required_groups`設定を使用）

`required_groups`を設定しない場合、または設定を空のままにしている場合は、IdPによってOIDC経由で認証されたユーザーであれば誰でもGitLabを使用できます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

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

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

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

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

### 外部グループ

IdPは、OIDC応答でグループ情報をGitLabに渡す必要があります。この応答を使用して、グループメンバーシップに基づいてユーザーを[外部ユーザー](../external_users.md)として識別するには、次の情報を特定できるようにGitLabを設定します。

- OIDC応答内でグループがある場所（`groups_attribute`設定を使用）
- どのグループメンバーシップに基づきユーザーを[外部ユーザー](../external_users.md)として識別するか（`external_groups`設定を使用）

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

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

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

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

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

### 監査担当者グループ

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

IdPは、OIDC応答でグループ情報をGitLabに渡す必要があります。この応答を使用して、グループメンバーシップに基づいてユーザーに監査担当者を割り当てるには、次の情報を特定できるようにGitLabを設定します。

- OIDC応答内でグループがある場所（`groups_attribute`設定を使用）
- どのグループメンバーシップに基づきユーザーに監査担当者アクセス権を付与するか（`auditor_groups`設定を使用）

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

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

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

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

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

### 管理者グループ

IdPは、OIDC応答でグループ情報をGitLabに渡す必要があります。この応答を使用して、グループメンバーシップに基づいてユーザーに管理者を割り当てるには、次の情報を特定できるようにGitLabを設定します。

- OIDC応答内でグループがある場所（`groups_attribute`設定を使用）
- どのグループメンバーシップに基づきユーザーに管理者アクセス権を付与するか（`admin_groups`設定を使用）

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

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

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

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

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

### IDトークンのカスタム有効期間を設定する

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/377654)されました。

{{< /history >}}

デフォルトでは、GitLabのIDトークンは120秒で有効期限が切れます。

IDトークンのカスタム有効期間を設定するには、次の手順に従います。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['oidc_provider_openid_id_token_expire_in_seconds'] = 3600
   ```

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     oidc_provider:
      openid_id_token_expire_in_seconds: 3600
   ```

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング

1. `discovery`が`true`に設定されていることを確認してください。`false`に設定すると、OpenIDを機能させるために必要なすべてのURLとキーを指定する必要があります。

1. システムクロックをチェックして、時刻が正しく同期されていることを確認してください。

1. [OmniAuth OpenID Connectのドキュメント](https://github.com/omniauth/omniauth_openid_connect)で説明されているように、`issuer`がディスカバリURLのベースURLに対応していることを確認してください。たとえば、URLが`https://accounts.google.com/.well-known/openid-configuration`の場合、`https://accounts.google.com`が使用されます。

1. `client_auth_method`が未定義の場合、または`basic`に設定されている場合、OpenID ConnectクライアントはHTTP基本認証を使用してOAuth 2.0アクセストークンを送信します。`userinfo`エンドポイントの取得時に401エラーが表示される場合は、OpenID Webサーバーの設定を確認してください。たとえば、[`oauth2-server-php`](https://github.com/bshaffer/oauth2-server-php)の場合、[Apacheに設定パラメーターを追加](https://github.com/bshaffer/oauth2-server-php/issues/926#issuecomment-387502778)する必要がある場合があります。
