---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab DedicatedのOpenID Connectシングルサインオン（SSO）認証を設定します。
title: GitLab DedicatedのOpenID Connectシングルサインオン
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

Identity Providerでユーザーを認証するために、GitLab DedicatedインスタンスのOpenID Connect（OIDC）シングルサインオンを設定します。

OIDC SSOは、次のような場合に使用します:

- 既存のIdentity Providerを介してユーザー認証を一元化します。
- ユーザーのパスワード管理のオーバーヘッドを削減します。
- 組織のアプリケーション全体で一貫したアクセス制御を実装します。
- 業界で幅広くサポートされている最新の認証プロトコルを使用します。

{{< alert type="note" >}}

これは、GitLab Dedicatedインスタンスのエンドユーザー向けにOIDCを設定します。スイッチボードの管理者向けにSSOを設定するには、[スイッチボードのSSOを設定する](_index.md#configure-switchboard-sso)を参照してください。

{{< /alert >}}

## OpenID Connectを設定する {#configure-openid-connect}

前提要件: 

- あなたのIdentity Providerを設定します。GitLabが設定後にコールバックURLを提供するため、一時的なコールバックURLを使用できます。
- Identity ProviderがOpenID Connectの仕様をサポートしていることを確認してください。

GitLab DedicatedインスタンスのOIDCを設定するには、次の手順に従います:

1. [サポートチケットを作成](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)します。
1. サポートチケットで、次の設定を指定します:

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://accounts.example.com",
     "discovery": true
   }
   ```

1. サポートチームがアクセスできるシークレットマネージャーへの一時的なリンクを使用して、クライアントシークレットとクライアントIDを安全に提供します。
1. Identity Providerが自動検出をサポートしていない場合は、クライアントエンドポイントオプションを含めます。例: 

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://example.com/accounts",
     "discovery": false,
     "client_options": {
       "end_session_endpoint": "https://example.com/logout",
       "authorization_endpoint": "https://example.com/authorize",
       "token_endpoint": "https://example.com/token",
       "userinfo_endpoint": "https://example.com/userinfo",
       "jwks_uri": "https://example.com/jwks"
     }
   }
   ```

GitLabがインスタンスのOIDCを設定した後:

1. サポートチケットでコールバックURLを受信します。
1. このコールバックURLでIdentity Providerを更新します。
1. インスタンスのサインインページでSSOログインボタンを確認して、設定を確認します。

## OIDCグループメンバーシップに基づいてユーザーを設定する {#configure-users-based-on-oidc-group-membership}

OIDCグループメンバーシップに基づいてユーザーのロールとアクセス権を割り当てるようにGitLabを設定できます。

前提要件: 

- Identity Providerは、`ID token`または`userinfo`エンドポイントにグループ情報を含める必要があります。
- 基本的なOIDC認証をすでに設定している必要があります。

OIDCのグループメンバーシップに基づいてユーザーを設定するには、次のようにします:

1. GitLabがグループ情報を検索する場所を指定するには、`groups_attribute`パラメータを追加します。
1. 必要に応じて、適切なグループ配列を設定します。
1. サポートチケットで、OIDCブロックにグループの設定を含めます。例: 

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://accounts.example.com",
     "discovery": true,
     "groups_attribute": "groups",
     "required_groups": [
       "gitlab-users"
     ],
     "external_groups": [
       "external-contractors"
     ],
     "auditor_groups": [
       "auditors"
     ],
     "admin_groups": [
       "gitlab-admins"
     ]
   }
   ```

## 設定パラメータ {#configuration-parameters}

次のパラメータを使用して、GitLab DedicatedインスタンスのOIDCを設定できます。詳細については、[OpenID Connectを認証プロバイダーとして使用](../../../../administration/auth/oidc.md)を参照してください。

### 必須パラメータ {#required-parameters}

| パラメータ | 説明 |
|-----------|-------------|
| `issuer` | Identity ProviderのOpenID Connect発行者URL。 |
| `label` | ログインボタンの表示名。 |
| `discovery` | OpenID Connectディスカバリーを使用するかどうか（推奨: `true`）。 |

### オプションのパラメータ {#optional-parameters}

| パラメータ | 説明 | デフォルト |
|-----------|-------------|---------|
| `admin_groups` | 管理者アクセス権を持つグループ。 | `[]` |
| `auditor_groups` | 監査担当者アクセス権を持つグループ。 | `[]` |
| `client_auth_method` | クライアント認証方法: | `"basic"` |
| `external_groups` | 外部ユーザーとしてマークされたグループ。 | `[]` |
| `groups_attribute` | OIDCレスポンスでグループを検索する場所。 | なし |
| `pkce` | Proof Key for Code Exchangeを有効にします。 | `false` |
| `required_groups` | アクセスに必要なグループ。 | `[]` |
| `response_mode` | 認可レスポンスの配信方法。 | なし |
| `response_type` | OAuth 2.0レスポンスの種類。 | `"code"` |
| `scope` | リクエストするOpenID Connectのスコープ。 | `["openid"]` |
| `send_scope_to_token_endpoint` | トークンエンドポイントリクエストにスコープパラメータを含めます。 | `true` |
| `uid_field` | 固有識別子として使用するフィールド。 | `"sub"` |

### プロバイダー固有の例 {#provider-specific-examples}

#### Google {#google}

```json
{
  "label": "Google",
  "scope": ["openid", "profile", "email"],
  "response_type": "code",
  "issuer": "https://accounts.google.com",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

#### Microsoft Azure AD {#microsoft-azure-ad}

```json
{
  "label": "Azure AD",
  "scope": ["openid", "profile", "email"],
  "response_type": "code",
  "issuer": "https://login.microsoftonline.com/your-tenant-id/v2.0",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

#### Okta {#okta}

```json
{
  "label": "Okta",
  "scope": ["openid", "profile", "email", "groups"],
  "response_type": "code",
  "issuer": "https://your-domain.okta.com/oauth2/default",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

## トラブルシューティング {#troubleshooting}

OpenID Connectの設定で問題が発生した場合:

- Identity Providerが正しく設定され、アクセス可能であることを確認します。
- サポートに提供されたクライアントIDとシークレットが正しいことを確認します。
- Identity ProviderのリダイレクトURIが、サポートチケットで提供されているものと一致していることを確認します。
- 発行者URLが正しく、アクセス可能であることを確認します。
