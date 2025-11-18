---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Microsoft AzureをOAuth 2.0認証プロバイダーとして使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Microsoft Azure OAuth 2.0 OmniAuthプロバイダーを有効にして、Microsoft Azure認証情報でGitLabにサインインできます。

{{< alert type="note" >}}

GitLabをAzure/Entra IDと初めて統合する場合は、Microsoft identity platform (v2.0) エンドポイントを使用する[OpenID Connect protocol](../administration/auth/oidc.md#configure-microsoft-azure)（OIDC）を設定してください。

{{< /alert >}}

## 汎用OpenID Connect設定に移行する {#migrate-to-generic-openid-connect-configuration}

GitLab 17.0以降、`azure_oauth2`を使用するインスタンスは、汎用OpenID Connect設定に移行する必要があります。詳細については、[Migrating to the OpenID Connect protocol](../administration/auth/oidc.md#migrate-to-generic-openid-connect-configuration)を参照してください。

## Azureアプリケーションを登録する {#register-an-azure-application}

Microsoft Azure OAuth 2.0 OmniAuthプロバイダーを有効にするには、Azureアプリケーションを登録し、クライアントIDとシークレットキーを取得する必要があります。

1. [Azure portal](https://portal.azure.com)にサインインします。
1. 複数のAzure Active Directoryテナントをお持ちの場合は、目的のテナントに切り替えてください。テナントIDをメモしてください。
1. [Register an application](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)登録し、次の情報を提供します。
   - Azure OAuthコールバックのGitLabインストールのURLを必要とするリダイレクトURI。`https://gitlab.example.com/users/auth/azure_activedirectory_v2/callback`。
   - アプリケーションの種類。必ず**Web**に設定してください。
1. クライアントIDとクライアントシークレットを保存します。クライアントシークレットは一度しか表示されません。

   必要に応じて、[create a new application secret](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal#option-3-create-a-new-client-secret)できます。

`client ID`と`client secret`はOAuth 2.0に関連する用語です。Microsoftのドキュメントによっては、`Application ID`と`Application Secret`という用語が使用されています。

## API権限（スコープ）を追加する {#add-api-permissions-scopes}

アプリケーションを作成したら、[configure it to expose a web API](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-expose-web-apis) (API)するように設定します。Microsoft Graph APIで、委任された次の権限を追加します。

- `email`
- `openid`
- `profile`

または、`User.Read.All`アプリケーション権限を追加します。

## GitLabでMicrosoft OAuthを有効にする {#enable-microsoft-oauth-in-gitlab}

{{< alert type="note" >}}

新しいプロジェクトでは、Microsoft identity platform (v2.0) エンドポイントを使用する[OpenID Connect protocol](../administration/auth/oidc.md#configure-microsoft-azure)（OIDC）を使用する必要があります。

{{< /alert >}}

1. GitLabサーバーで、設定ファイルを開きます。

   - Linuxパッケージインストールの場合:

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

   - 自己コンパイルによるインストールの場合:

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

1. [共通設定](omniauth.md#configure-common-settings)で、`azure_activedirectory_v2`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。

1. プロバイダー設定を追加します。Azureアプリケーションを登録したときに取得した`<client_id>`、`<client_secret>`、`<tenant_id>`に置き換えます。

   - Linuxパッケージインストールの場合:

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

   - [alternative Azure clouds](https://learn.microsoft.com/en-us/entra/identity-platform/authentication-national-cloud)の場合は、`base_azure_url`を`args`セクションの下に設定します。たとえば、Azure Government Community Cloud（GCC）の場合:

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

   - 自己コンパイルによるインストールの場合:

     v2.0エンドポイントの場合:

     ```yaml
     - { name: 'azure_activedirectory_v2',
         label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
         args: { client_id: "<client_id>",
                 client_secret: "<client_secret>",
                 tenant_id: "<tenant_id>" } }
     ```

     [alternative Azure clouds](https://learn.microsoft.com/en-us/entra/identity-platform/authentication-national-cloud)の場合は、`base_azure_url`を`args`セクションの下に設定します。たとえば、Azure Government Community Cloud（GCC）の場合:

     ```yaml
     - { name: 'azure_activedirectory_v2',
         label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
         args: { client_id: "<client_id>",
                 client_secret: "<client_secret>",
                 tenant_id: "<tenant_id>",
                 base_azure_url: "https://login.microsoftonline.us" } }
     ```

   オプションで、[OAuth 2.0 scopes](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow)パラメータの`scope`を`args`セクションに追加することもできます。デフォルトは`openid profile email`です。

1. 設定ファイルを保存します。

1. Linuxパッケージを使用してインストールした場合は、[Reconfigure GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)を更新するか、インストールを自己コンパイルした場合は、[restart GitLab](../administration/restart_gitlab.md#self-compiled-installations)を更新します。

1. GitLabサインインページを更新します。Microsoftのアイコンがサインインフォームの下に表示されます。

1. アイコンを選択します。Microsoftにサインインし、GitLabアプリケーションを承認します。

既存のGitLabユーザーが新しいAzure ADアカウントに接続する方法については、[Enable OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user)を参照してください。

## トラブルシューティング {#troubleshooting}

### ユーザーサインインバナーメッセージ: Extern UIDは既に使用されています {#user-sign-in-banner-message-extern-uid-has-already-been-taken}

サインイン時に、`Extern UID has already been taken`というエラーが表示されることがあります。

これを解決するには、[Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session)を使用して、アカウントに接続中の既存のユーザーがいるかどうかを確認します。

1. `extern_uid`を見つけます:

   ```ruby
   id = Identity.where(extern_uid: '<extern_uid>')
   ```

1. コンテンツを印刷して、その`extern_uid`に添付されているユーザー名を見つけます:

   ```ruby
   pp id
   ```

`extern_uid`がアカウントに添付されている場合は、ユーザー名を使用してサインインできます。

`extern_uid`がどのユーザー名にも添付されていない場合、ゴーストレコードになる削除エラーが原因である可能性があります。

次のコマンドを実行して、IDを削除して`extern uid`をリリースします:

```ruby
 Identity.find('<id>').delete
```
