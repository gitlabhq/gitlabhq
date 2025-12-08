---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: IDトークンを使用するようにHashiCorp Vault設定を更新する'
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

Vault 1.17以降、JWTに`aud`クレームが含まれている場合、[JWT認証ログインにはロールにbound_audiencesの設定が必要です](https://developer.hashicorp.com/vault/docs/upgrading/upgrade-to-1.17.x#jwt-auth-login-requires-bound-audiences-on-the-role)。`aud`クレームには、単一の文字列または文字列のリストを指定できます。

{{< /alert >}}

このチュートリアルでは、既存のCI/CDシークレット設定を[ID Tokens](id_token_authentication.md)を使用するように変換する方法を説明します。

`CI_JOB_JWT`変数は非推奨ですが、IDトークンに更新するには、Vaultと連携するための重要な設定変更が必要です。ジョブが少数にとどまらない場合、すべてを一度に変換するのは困難なタスクです。

[IDトークン](id_token_authentication.md)に移行するための標準的な方法は1つではありません。そのため、このチュートリアルでは、既存のCI/CDシークレットを変換する2つのバリエーションを紹介します。お客様のユースケースに最適な方法を選択してください:

1. Vaultの設定を更新します:
   - 方法A: JWTロールを新しいVault認証方式に移行します
     1. [Vaultに2つ目のJWT認証パスを作成する](#create-a-second-jwt-authentication-path-in-vault)
     1. [新しい認証パスを使用するようにロールを再作成する](#recreate-roles-to-use-the-new-authentication-path)
   - 方法B: 移行ウィンドウのロールに`iss`クレームを移動します
     1. [各ロールに`bound_issuers`クレームマップを追加する](#add-bound_issuers-claim-map-to-each-role)
     1. [認証方式から`bound_issuers`クレームを削除する](#remove-bound_issuers-claim-from-auth-method)
1. [CI/CDのジョブを更新する](#update-your-cicd-jobs)

## 前提要件 {#prerequisites}

このチュートリアルでは、GitLab CI/CDとVaultについて理解していることを前提としています。

次に進むには、以下が必要です:

- GitLab 16.0以降を実行しているインスタンス、またはGitLab.com上に存在すること。
- 既に使用しているVaultサーバー。
- `CI_JOB_JWT`を使用して、Vaultからシークレットを取得するCI/CDジョブ。

以下の例では、以下を置き換えてください:

- `vault.example.com`に、あなたのVaultサーバーのURLを指定します。
- `gitlab.example.com`をGitLabインスタンスのURLに置き換えます。
- `jwt`または`jwt_v2`を認証方式の名前に置き換えます。

## 方法A: JWTロールを新しいVault認証方式に移行します {#method-a-migrate-jwt-roles-to-the-new-vault-auth-method}

この方法では、使用中の既存のものと並行して、2番目のJWT認証方式を作成します。その後、GitLabインテグレーションに使用されるすべてのVaultロールは、この新しい認証方式で再作成されます。

### Vaultに2つ目のJWT認証パスを作成します {#create-a-second-jwt-authentication-path-in-vault}

`CI_JOB_JWT`からIDトークンへの移行の一環として、Vaultの`bound_issuer`を更新して`https://`を含める必要があります:

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer="https://gitlab.example.com"
```

この変更を行うと、`CI_JOB_JWT`を使用するジョブは失敗し始めます。

Vaultに複数の認証パスを作成できます。これにより、中断することなく、ジョブベースでプロジェクトのIDトークンに移行できます。

1. 名前`jwt_v2`の新しい認証パスを設定するには、以下を実行します:

   ```shell
   vault auth enable -path jwt_v2 jwt
   ```

   別の名前を選択できますが、これらの例の残りの部分では`jwt_v2`を使用していることを前提としているため、必要に応じて例を更新してください。

1. インスタンスの新しい認証パスを設定します:

   ```shell
   $ vault write auth/jwt_v2/config \
       oidc_discovery_url="https://gitlab.example.com" \
       bound_issuer="https://gitlab.example.com"
   ```

### 新しい認証パスを使用するようにロールを再作成します {#recreate-roles-to-use-the-new-authentication-path}

ロールは特定の認証パスにバインドされているため、各ジョブに新しいロールを追加する必要があります。JWTにオーディエンスが含まれている場合、ロールの`bound_audiences`パラメータは必須であり、関連付けられている`aud`クレームの少なくとも1つと一致する必要があります。

1. ステージング用のロールを再作成します（名前：`myproject-staging`）:

   ```shell
   $ vault write auth/jwt_v2/role/myproject-staging - <<EOF
   {
     "role_type": "jwt",
     "policies": ["myproject-staging"],
     "token_explicit_max_ttl": 60,
     "user_claim": "user_email",
     "bound_audiences": ["https://vault.example.com"],
     "bound_claims": {
       "project_id": "22",
       "ref": "master",
       "ref_type": "branch"
     }
   }
   EOF
   ```

1. 本番環境用のロールを再作成します（名前：`myproject-production`）:

   ```shell
   $ vault write auth/jwt_v2/role/myproject-production - <<EOF
   {
     "role_type": "jwt",
     "policies": ["myproject-production"],
     "token_explicit_max_ttl": 60,
     "user_claim": "user_email",
     "bound_audiences": ["https://vault.example.com"],
     "bound_claims_type": "glob",
     "bound_claims": {
       "project_id": "22",
       "ref_protected": "true",
       "ref_type": "branch",
       "ref": "auto-deploy-*"
     }
   }
   EOF
   ```

`vault`コマンドで`jwt`を`jwt_v2`に更新するだけで済みます。ロール内の`role_type`は変更しないでください。

## 方法B: 移行ウィンドウのロールに`iss`クレームを移動します {#method-b-move-iss-claim-to-roles-for-migration-window}

この方法では、Vault管理者が2番目のJWT認証方式を作成し、GitLabに関連するすべてのロールを再作成する必要はありません。

### 各ロールに`bound_issuers`クレームマップを追加します {#add-bound_issuers-claim-map-to-each-role}

Vaultでは、JWT認証方式レベルで複数の`iss`クレームは許可されていません。このレベルの[`bound_issuer`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_issuer)ディレクティブは、単一の値のみを受け入れるためです。ただし、[`bound_claims`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims)マップ設定ディレクティブを使用すると、ロールレベルで複数のクレームを設定できます。

この方法を使用すると、Vaultに`iss`クレーム検証の複数のオプションを提供できます。これにより、`https://`のプレフィックスが付いたGitLabインスタンスホスト名クレームがサポートされます。これは、古いプレフィックスなしのクレームと同様に、`id_tokens`に付属しています。

必要なロールに[`bound_claims`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims)設定を追加するには、以下を実行します:

```shell
$ vault write auth/jwt/role/myproject-staging - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-staging"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": ["https://vault.example.com"],
  "bound_claims": {
    "iss": [
      "https://gitlab.example.com",
      "gitlab.example.com"
    ],
    "project_id": "22",
    "ref": "master",
    "ref_type": "branch"
  }
}
EOF
```

`bound_claims`セクションを除き、既存のロール設定を変更する必要はありません。前に示したように`iss`設定を追加して、Vaultがこのロールのプレフィックス付きおよびプレフィックスなしの`iss`クレームを受け入れるようにしてください。

次のステップに進む前に、GitLabインテグレーションに使用されるすべてのJWTロールにこの変更を適用する必要があります。

すべてのプロジェクトが移行され、`CI_JOB_JWT`とIDトークンの並列サポートが不要になった場合は、必要に応じて、`iss`クレーム検証の移行を認証方法からロールにレビューできます。

### 認証方式から`bound_issuers`クレームを削除します {#remove-bound_issuers-claim-from-auth-method}

すべてのロールが`bound_claims.iss`クレームで更新されたら、この検証の認証方式レベルの設定を削除できます:

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer=""
```

`bound_issuer`ディレクティブを空の文字列に設定すると、認証方式レベルで発行者検証が削除されます。ただし、この検証はロールレベルで行われるようになったため、設定は依然として安全です。

## CI/CDジョブを更新します {#update-your-cicd-jobs}

Vaultには2つの異なる[KVシークレットエンジン](https://developer.hashicorp.com/vault/docs/secrets/kv)があり、使用しているバージョンはCI/CDでシークレットを定義する方法に影響します。

Vaultサーバーを確認するには、HashiCorpのサポートポータルにある[どのバージョンが自分のVault KVマウントか？](https://support.hashicorp.com/hc/en-us/articles/4404288741139-Which-Version-is-my-Vault-KV-Mount)という記事を確認してください。

また、必要に応じて、CI/CDドキュメントで以下をレビューできます:

- [`secrets:`](../yaml/_index.md#secrets)
- [`id_tokens:`](../yaml/_index.md#id_tokens)

次の例は、`secret/myproject/staging/db`の`password`フィールドに書き込まれたステージングデータベースのパスワードを取得する方法を示しています。

`VAULT_AUTH_PATH`変数の値は、使用した移行方法によって異なります:

- 方法A (Vault認証の新しいJWTロールへの移行方法): `jwt_v2`を使用してください。
- 方法B (`iss`クレームを移行ウィンドウのロールに移動する): `jwt`を使用してください。

### KVシークレットエンジンv1 {#kv-secrets-engine-v1}

[`secrets:vault`](../yaml/_index.md#secretsvault)キーワードはKVマウントのv2にデフォルト設定されているため、v1エンジンを使用するようにジョブを明示的に設定する必要があります:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    PASSWORD:
      vault:
        engine:
          name: kv-v1
          path: secret
        field: password
        path: myproject/staging/db
      file: false
```

`VAULT_SERVER_URL`と`VAULT_AUTH_PATH`の両方を、必要に応じて[プロジェクトまたはグループのCI/CD変数として定義](../variables/_index.md#define-a-cicd-variable-in-the-ui)できます。

[`secrets:file`](../yaml/_index.md#secretsfile)は`false`に設定されています。これは、IDトークンがシークレットをデフォルトでファイルに配置し、古い動作と一致するように、通常の変数として動作する必要があるためです。

### KVシークレットエンジンv2 {#kv-secrets-engine-v2}

v2エンジンに使用できる形式は2つあります。

長い形式:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    PASSWORD:
      vault:
        engine:
          name: kv-v2
          path: secret
        field: password
        path: myproject/staging/db
      file: false
```

これはv1エンジンの例と同じですが、`secrets:vault:engine:name:`がエンジンと一致するように`kv-v2`に設定されています。

短い形式も使用できます:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
      PASSWORD:
        vault: myproject/staging/db/password@secret
        file: false
```

更新されたCI/CD設定をコミットすると、ジョブはIDトークンでシークレットをフェッチします。おめでとうございます。

すべてのプロジェクトを移行してIDトークンでシークレットをフェッチし、移行に方法Bを使用した場合は、必要に応じて、`iss`クレーム検証を認証方法の設定に戻すことができます。
