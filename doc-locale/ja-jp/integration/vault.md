---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab OpenID ConnectでのVault認証
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Vault](https://www.vaultproject.io/)は、HashiCorpが提供するシークレット管理アプリケーションです。これにより、シークレット環境変数、暗号化キー、認証トークンなどの機密情報を保存および管理できます。

VaultはIDベースのアクセスを提供します。つまり、Vaultユーザーは、優先するいくつかのクラウドプロバイダーを介して認証できます。

次のコンテンツでは、VaultユーザーがOpenID Connect認証機能を使用して、GitLabを介して自身を認証する方法について説明します。

## 前提要件 {#prerequisites}

1. [Vaultをインストールする](https://developer.hashicorp.com/vault/install)。
1. Vaultを実行します。

## GitLabからOpenID ConnectクライアントID</IDとシークレットを取得します {#get-the-openid-connect-client-id-and-secret-from-gitlab}

Vaultに認証するためのアプリケーションIDとシークレットを取得するには、まず、GitLabアプリケーションを作成する必要があります。これを行うには、GitLabにサインインして、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アプリケーション**を選択します。
1. アプリケーションの**名前**と[**Redirect URI**（リダイレクト）](https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris)に入力します。
1. **OpenID**スコープを選択します。
1. **アプリケーションを保存**を選択します。
1. **Client ID**（クライアントID）と**Client Secret**（クライアントシークレット）をコピーするか、参照できるようにページを開いたままにしておきます。

![OAuthプロバイダーとしてのGitLab](img/gitlab_oauth_vault_v12_6.png)

## VaultでOpenID Connectを有効にします {#enable-openid-connect-on-vault}

OpenID Connect（OIDC）は、Vaultではデフォルトで有効になっていません。

VaultでOIDC認証プロバイダーを有効にするには、ターミナルセッションを開き、次のコマンドを実行します:

```shell
vault auth enable oidc
```

ターミナルに次の出力が表示されます:

```plaintext
Success! Enabled oidc auth method at: oidc/
```

## OIDC設定を書き込みます {#write-the-oidc-configuration}

GitLabによって生成されたアプリケーションIDとシークレットをVaultに渡し、VaultがGitLabを通じて認証できるようにするには、ターミナルで次のコマンドを実行します:

```shell
vault write auth/oidc/config \
  oidc_discovery_url="https://gitlab.com" \
  oidc_client_id="<your_application_id>" \
  oidc_client_secret="<your_secret>" \
  default_role="demo" \
  bound_issuer="localhost"
```

`<your_application_id>`と`<your_secret>`を、アプリ用に生成されたアプリケーションIDとシークレットに置き換えます。

ターミナルに次の出力が表示されます:

```shell
Success! Data written to: auth/oidc/config
```

## OIDCロール設定を書き込みます {#write-the-oidc-role-configuration}

アプリケーションの作成時にGitLabに指定した[**Redirect URIs**（リダイレクトURI）](https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris)とスコープをVaultに伝える必要があります。

ターミナルで次のコマンドを実行します:

```shell
vault write auth/oidc/role/demo - <<EOF
{
   "user_claim": "sub",
   "allowed_redirect_uris": "<your_vault_instance_redirect_uris>",
   "bound_audiences": "<your_application_id>",
   "oidc_scopes": "<openid>",
   "role_type": "oidc",
   "policies": "demo",
   "ttl": "1h",
   "bound_claims": { "groups": ["<yourGroup/yourSubgrup>"] }
}
EOF
```

以下の値を置き換えます:

- `<your_vault_instance_redirect_uris>`を実行中のVaultインスタンスと一致するリダイレクトを使用します。
- `<your_application_id>`を、アプリ用に生成されたアプリケーションIDに置き換えます。

`oidc_scopes`フィールドには、`openid`を含める必要があります。

この設定は、作成するロールの名前で保存されます。この例では、`demo`ロールを作成しています。

{{< alert type="warning" >}}

GitLab.comなどのパブリックGitLabインスタンスを使用している場合は、グループまたはプロジェクトのメンバーのみがアクセスできるように、`bound_claims`を指定する必要があります。そうしないと、パブリックアカウントを持つすべてのユーザーがVaultインスタンスにアクセスできてしまいます。

{{< /alert >}}

## Vaultにサインインします {#sign-in-to-vault}

1. Vault UIに移動します。例: [http://127.0.0.1:8200/ui/vault/auth?with=oidc](http://127.0.0.1:8200/ui/vault/auth?with=oidc)。
1. `OIDC`メソッドが選択されていない場合は、ドロップダウンリストを開いて選択します。
1. **Sign in With GitLab**（GitLabでサインイン）を選択します。これにより、モーダルウィンドウが開きます:

   ![GitLabでVaultにサインイン](img/sign_into_vault_with_gitlab_v12_6.png)

1. VaultがGitLab経由でサインインできるようにするには、**許可する**を選択します。これにより、認証済みユーザーとしてVault UIにリダイレクトされます。

   ![GitLabと接続するためにVaultを許可する](img/authorize_vault_with_gitlab_v12_6.png)

## Vault CLIを使用してサインインします（オプション） {#sign-in-using-the-vault-cli-optional}

[Vault CLI](https://developer.hashicorp.com/vault/docs/commands)を使用してVaultにサインインすることもできます。

1. 前の例で作成したロール設定を使用してサインインするには、ターミナルで次のコマンドを実行します:

   ```shell
   vault login -method=oidc port=8250 role=demo
   ```

   このコマンドは次を設定します:

   - `role=demo` Vaultがサインインに使用する設定を認識できるようにします。
   - `-method=oidc` Vaultが`OIDC`認証方法を使用するように設定します。
   - `port=8250` GitLabのリダイレクト先のポートを設定します。このポート番号は、[リダイレクト](https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris)をリストするときにGitLabに指定されたポートと一致する必要があります。

   このコマンドを実行すると、ターミナルにリンクが表示されます。

1. このリンクをWebブラウザで開きます:

   ![OIDC経由でVaultにサインイン](img/signed_into_vault_via_oidc_v12_6.png)

   ターミナルに次のように表示されます:

   ```plaintext
   Success! You are now authenticated. The token information displayed below
   is already stored in the token helper. You do NOT need to run "vault login"
   again. Future Vault requests will automatically use this token.
   ```
