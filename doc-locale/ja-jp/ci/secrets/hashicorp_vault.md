---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CD で HashiCorp Vault シークレットを使用する
---

{{< details >}}

- プラン:Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

`CI_JOB_JWT`を使用した認証は、[GitLab 15.9 で非推奨となり、GitLab 17.0 で削除されました](../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)。代わりに、[IDトークンを使用してHashiCorp Vaultで認証してください](hashicorp_vault.md#example)。このページで実例を紹介しています。

{{< /alert >}}

{{< alert type="note" >}}

Vault 1.17 以降、JWT に`aud`クレームが含まれている場合、[JWT 認証ログインにはロールに対するバインドされたオーディエンスが必要です](https://developer.hashicorp.com/vault/docs/upgrading/upgrade-to-1.17.x#jwt-auth-login-requires-bound-audiences-on-the-role)。`aud`クレームには、単一の文字列または文字列のリストを指定できます。

{{< /alert >}}

このチュートリアルでは、GitLab CI/CD から HashiCorp Vault を使用して認証、Configure、およびシークレットを読み取る方法を説明します。

## 前提要件

このチュートリアルでは、GitLab CI/CD と Vault について理解していることを前提としています。

次に進むには、以下が必要です:

- GitLab のアカウント。
- 認証をConfigureし、ロールとポリシーを作成するために、実行中の Vault サーバー（少なくとも v1.2.0）へのアクセス。HashiCorp Vault の場合、これはオープンソースまたはEnterpriseバージョンにすることができます。

{{< alert type="note" >}}

以下の`vault.example.com` URL を Vault サーバーの URL に、`gitlab.example.com`を GitLab インスタンスの URL に置き換える必要があります。

{{< /alert >}}

## 仕組み

IDトークンは、サードパーティサービスとの OIDC 認証に使用される JSON Web Token（JWT）です。ジョブに少なくとも 1 つの ID トークンが定義されている場合、`secrets` キーワードは、そのトークンを自動的に使用して Vault で認証します。

次のフィールドがJWTに含まれています:

| フィールド                   | 時期                                       | 説明 |
|-------------------------|--------------------------------------------|-------------|
| `jti`                   | 常に                                     | このトークンの固有識別子 |
| `iss`                   | 常に                                     | 発行者、GitLabインスタンスのドメイン |
| `iat`                   | 常に                                     | 発行日時   |
| `nbf`                   | 常に                                     | 以下より前は無効 |
| `exp`                   | 常に                                     | 失効日時  |
| `sub`                   | 常に                                     | サブジェクト（ジョブID） |
| `namespace_id`          | 常に                                     | これを使用して、IDでグループまたはユーザーレベルのネームスペースにスコープします |
| `namespace_path`        | 常に                                     | これを使用して、パスでグループまたはユーザーレベルのネームスペースにスコープします |
| `project_id`            | 常に                                     | これを使用して、IDでプロジェクトにスコープします |
| `project_path`          | 常に                                     | これを使用して、パスでプロジェクトにスコープします |
| `user_id`               | 常に                                     | ジョブを実行するユーザーのID |
| `user_login`            | 常に                                     | ジョブを実行するユーザーのユーザー名 |
| `user_email`            | 常に                                     | ジョブを実行するユーザーのメール |
| `pipeline_id`           | 常に                                     | このパイプラインのID |
| `pipeline_source`       | 常に                                     | [パイプラインソース](../jobs/job_rules.md#common-if-clauses-with-predefined-variables) |
| `job_id`                | 常に                                     | このジョブのID |
| `ref`                   | 常に                                     | このジョブのGit refs |
| `ref_type`              | 常に                                     | Git refsタイプ（`branch` または `tag`） |
| `ref_path`              | 常に                                     | ジョブの完全修飾refs。たとえば、`refs/heads/main` などです。GitLab 16.0 で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119075)されました。 |
| `ref_protected`         | 常に                                     | この Git refs が保護されている場合は `true`、それ以外の場合は `false` |
| `environment`           | ジョブは環境を指定します               | このジョブが指定する環境 |
| `groups_direct`         | ユーザーは0〜200のグループの直接のメンバーです | ユーザーの直接所属グループのパス。ユーザーが200を超えるグループの直接のメンバーである場合は省略されます。（GitLab 16.11 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/435848)）。 |
| `environment_protected` | ジョブは環境を指定します               | 指定された環境が保護されている場合は `true`、それ以外の場合は`false` |
| `deployment_tier`       | ジョブは環境を指定します               | このジョブが指定する環境の[デプロイプラン](../environments/_index.md#deployment-tier-of-environments) ( GitLab 15.2 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/363590)) |
| `environment_action`    | ジョブは環境を指定します               | ジョブで指定された[環境アクション（`environment:action`）](../environments/_index.md)。（GitLab 16.5 で[導入](https://gitlab.com/gitlab-org/gitlab/-/)） |

JWT ペイロードの例:

```json
{
  "jti": "c82eeb0c-5c6f-4a33-abf5-4c474b92b558",
  "iss": "gitlab.example.com",
  "iat": 1585710286,
  "nbf": 1585798372,
  "exp": 1585713886,
  "sub": "job_1212",
  "namespace_id": "1",
  "namespace_path": "mygroup",
  "project_id": "22",
  "project_path": "mygroup/myproject",
  "user_id": "42",
  "user_login": "myuser",
  "user_email": "myuser@example.com",
  "pipeline_id": "1212",
  "pipeline_source": "web",
  "job_id": "1212",
  "ref": "auto-deploy-2020-04-01",
  "ref_type": "branch",
  "ref_path": "refs/heads/auto-deploy-2020-04-01",
  "ref_protected": "true",
  "groups_direct": ["mygroup/mysubgroup", "myothergroup/myothersubgroup"],
  "environment": "production",
  "environment_protected": "true",
  "environment_action": "start"
}
```

JWT は RS256 を使用してエンコードされ、専用のプライベートキーで署名されます。トークンの有効期限は、ジョブのタイムアウト（指定されている場合）または指定されていない場合は 5 分に設定されます。このトークンの署名に使用されるキーは、予告なく変更される場合があります。そのような場合は、ジョブを再試行すると、現在の署名キーを使用して新しい JWT が生成されます。

JWT 認証方法を許可するようにConfigureされた Vault サーバーとの認証に、この JWT を使用できます。GitLab インスタンスのベース URL（`https://gitlab.example.com`など）を`oidc_discovery_url`として Vault サーバーに提供します。サーバーは、インスタンスからトークンを検証するためのキーを取得できます。

Vault でロールを設定するときに、[バインドされたクレーム](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims)を使用して JWT クレームと照合し、各 CI/CD ジョブがアクセスできるシークレットを制限できます。

Vault と通信するには、CLI クライアントを使用するか、APIリクエストを実行できます（`curl`または別のクライアントを使用）。

## 例

{{< alert type="warning" >}}

JWT はリソースへのアクセスを許可できる認証情報です。貼り付ける場所には注意してください。

{{< /alert >}}

`http://vault.example.com:8200`で実行されている Vault サーバーに、ステージングデータベースと本番環境データベースのパスワードが格納されているとします。ステージングパスワードは`pa$$w0rd`で、本番環境パスワードは`real-pa$$w0rd`です。

```shell
$ vault kv get -field=password secret/myproject/staging/db
pa$$w0rd

$ vault kv get -field=password secret/myproject/production/db
real-pa$$w0rd
```

Vault サーバーをConfigureするには、まず[JWT 認証](https://developer.hashicorp.com/vault/docs/auth/jwt)方法を有効にします。

```shell
$ vault auth enable jwt
Success! Enabled jwt auth method at: jwt/
```

次に、これらのシークレットの読み取りを許可するポリシーを作成します（シークレットごとに1つ）。

```shell
$ vault policy write myproject-staging - <<EOF
# Policy name: myproject-staging
#
# Read-only permission on 'secret/myproject/staging/*' path
path "secret/myproject/staging/*" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: myproject-staging

$ vault policy write myproject-production - <<EOF
# Policy name: myproject-production
#
# Read-only permission on 'secret/myproject/production/*' path
path "secret/myproject/production/*" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: myproject-production
```

JWT をこれらのポリシーにリンクするロールも必要です。

たとえば、`myproject-staging`という名前のステージング用のロールが1つあります。[バインドされたクレーム](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims)は、ID `22`のプロジェクトの`main`ブランチでのみポリシーを使用できるようにConfigureされています。

```shell
$ vault write auth/jwt/role/myproject-staging - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-staging"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": "https://vault.example.com",
  "bound_claims": {
    "project_id": "22",
    "ref": "main",
    "ref_type": "branch"
  }
}
EOF
```

そして、`myproject-production` という名前の本番環境用のロールが1つあります。このロールの`bound_claims`セクションでは、`auto-deploy-*`パターンに一致する保護ブランチのみがシークレットにアクセスできます。

```shell
$ vault write auth/jwt/role/myproject-production - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-production"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": "https://vault.example.com",
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

[保護ブランチ](../../user/project/repository/branches/protected.md)と組み合わせることで、誰が認証してシークレットを読み取ることができるかを制限できます。

[JWT に含まれる](#how-it-works)クレームは、バインドされたクレームの値のリストと照合することもできます。次に例を示します:

```json
"bound_claims": {
  "user_login": ["alice", "bob", "mallory"]
}

"bound_claims": {
  "ref": ["main", "develop", "test"]
}

"bound_claims": {
  "namespace_id": ["10", "20", "30"]
}

"bound_claims": {
  "project_id": ["12", "22", "37"]
}
```

- `namespace_id`のみが使用されている場合、ネームスペース内のすべてのプロジェクトが許可されます。ネストされたプロジェクトは含まれていないため、必要に応じて、そのネームスペース ID もリストに追加する必要があります。
- `namespace_id`と`project_id`の両方が使用されている場合、Vault は最初にプロジェクトのネームスペースが`namespace_id`にあるかどうかを確認し、次にプロジェクトが`project_id`にあるかどうかを確認します。

[`token_explicit_max_ttl`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#token_explicit_max_ttl)は、認証に成功すると、Vault によって発行されたトークンに 60 秒のハードライフタイム制限があることを指定します。

[`user_claim`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#user_claim)は、ログインが成功したときに Vault によって作成されたIdentityエイリアスの名前を指定します。

[`bound_claims_type`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims_type)は、`bound_claims`値の解釈をConfigureします。`glob`に設定すると、値は glob として解釈され、`*`は任意の数の文字に一致します。

[上記の表](#how-it-works)にリストされているクレームフィールドには、Vault の JWT 認証のアクセサー名を使用することにより、[Vault のポリシーパスのテンプレート作成](https://developer.hashicorp.com/vault/tutorials/policies/policy-templating?in=vault%2Fpolicies)の目的でアクセスすることもできます。[マウントアクセサー名](https://developer.hashicorp.com/vault/tutorials/auth-methods/identity#step-1-create-an-entity-with-alias)（以下の例では`ACCESSOR_NAME`）は、`vault auth list`を実行することで取得できます。

`project_path`という名前の指定されたメタデータフィールドを利用するポリシーテンプレートの例:

```plaintext
path "secret/data/{{identity.entity.aliases.ACCESSOR_NAME.metadata.project_path}}/staging/*" {
  capabilities = [ "read" ]
}
```

上記のテンプレートポリシーをサポートするロールの例。[`claim_mappings`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#claim_mappings)設定を使用して、クレームフィールド`project_path`をメタデータフィールドとしてマップします。

```plaintext
{
  "role_type": "jwt",
  ...
  "claim_mappings": {
    "project_path": "project_path"
  }
}
```

オプションの完全なリストについては、Vault の[ロール作成に関するドキュメント](https://developer.hashicorp.com/vault/api-docs/auth/jwt#create-role)を参照してください。

{{< alert type="warning" >}}

提供されているクレーム（`project_id`や`namespace_id`など）のいずれかを使用して、ロールをプロジェクトまたはネームスペースに常に制限してください。そうしないと、このインスタンスによって生成された JWT は、このロールを使用して認証することを許可される可能性があります。

{{< /alert >}}

次に、JWT 認証方法をConfigureします。

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer="https://gitlab.example.com"
```

[`bound_issuer`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_issuer)は、`gitlab.example.com`に設定された発行者（つまり、`iss`クレーム）を持つ JWT のみ、このメソッドを使用して認証でき、トークンの検証には`oidc_discovery_url`（`https://gitlab.example.com`）を使用する必要があることを指定します。

使用可能な設定オプションの完全なリストについては、Vault の[API ドキュメント](https://developer.hashicorp.com/vault/api-docs/auth/jwt#configure)を参照してください。

GitLab で、Vault サーバーに関する詳細を提供するために、次の[CI/CD変数](../variables/_index.md#for-a-project)を作成します。

- `VAULT_SERVER_URL` - Vault サーバーの URL（`https://vault.example.com:8200` など）。
- `VAULT_AUTH_ROLE` - オプション。認証を試行するときに使用する Vault JWT 認証ロールの名前。このチュートリアルでは、`myproject-staging`および`myproject-production`という名前の2つのロールをすでに作成しました。ロールが指定されていない場合、Vault は認証方法のConfigure時に指定された[デフォルトロール](https://developer.hashicorp.com/vault/api-docs/auth/jwt#default_role)を使用します。
- `VAULT_AUTH_PATH` - オプション。認証方法がマウントされているパス。デフォルトは `jwt` です。
- `VAULT_NAMESPACE` - オプション。シークレットの読み取りと認証に使用する[Vault Enterprise ネームスペース](https://developer.hashicorp.com/vault/docs/enterprise/namespaces)。ネームスペースが指定されていない場合、Vault はルート（`/`）ネームスペースを使用します。この設定は Vault オープンソースでは無視されます。

### Hashicorp Vault を使用した自動IDトークン認証

次のジョブは、デフォルトブランチに対して実行される場合、`secret/myproject/staging/`の下のシークレットを読み取ることができますが、`secret/myproject/production/`の下のシークレットは読み取ることができません。

```yaml
job_with_secrets:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    STAGING_DB_PASSWORD:
      vault: myproject/staging/db/password@secret  # translates to a path of 'secret/myproject/staging/db' and field 'password'. Authenticates using $VAULT_ID_TOKEN.
  script:
    - access-staging-db.sh --token $STAGING_DB_PASSWORD
```

この例では:

- `id_tokens` - OIDC 認証に使用される JSON Web Token (JWT)。`aud`クレームは、Vault JWT 認証メソッドに使用される`role`の`bound_audiences`パラメータと一致するように設定されています。
- `@secret` - シークレットエンジンが有効になっている Vault 名。
- `myproject/staging/db` - Vault 内のシークレットのパスの場所。
- `password`参照されているシークレットでフェッチするフィールド。

複数の ID トークンが定義されている場合は、`token`キーワードを使用して、使用するトークンを指定します。次に例を示します:

```yaml
job_with_secrets:
  id_tokens:
    FIRST_ID_TOKEN:
      aud: https://first.service.com
    SECOND_ID_TOKEN:
      aud: https://second.service.com
  secrets:
    FIRST_DB_PASSWORD:
      vault: first/db/password
      token: $FIRST_ID_TOKEN
    SECOND_DB_PASSWORD:
      vault: second/db/password
      token: $SECOND_ID_TOKEN
  script:
    - access-first-db.sh --token $FIRST_DB_PASSWORD
    - access-second-db.sh --token $SECOND_DB_PASSWORD
```

### 手動 ID トークン認証

ID トークンを使用してHashiCorp Vaultで手動で認証できます。次に例を示します:

```yaml
manual_authentication:
  variables:
    VAULT_ADDR: http://vault.example.com:8200
  image: vault:latest
  id_tokens:
    VAULT_ID_TOKEN:
      aud: http://vault.example.com
  script:
    - export VAULT_TOKEN="$(vault write -field=token auth/jwt/login role=myproject-example jwt=$VAULT_ID_TOKEN)"
    - export PASSWORD="$(vault kv get -field=password secret/myproject/example/db)"
    - my-authentication-script.sh $VAULT_TOKEN $PASSWORD
```

### Vault シークレットへのトークンアクセスを制限する

Vault の保護機能と GitLab 機能を使用することで、Vault シークレットへの ID トークンアクセスを制御できます。たとえば、次のようにトークンを制限します:

- 特定の ID トークンの`aud`クレームに対して、Vault の[バインドされたオーディエンス](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-audiences)を使用する。
- `group_claim`を使用して、特定のグループに対して Vault の[バインドされたクレーム](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims)を使用する。
- 特定のユーザーの`user_login`と`user_email`に基づいて、Vault のバインドされたクレームの値をハードコーディングする。
- [`token_explicit_max_ttl`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#token_explicit_max_ttl)で指定されているように、トークンの TTL の Vault タイム制限を設定する。この場合、トークンは認証後に失効します。
- プロジェクトユーザーのサブセットに制限されている[GitLab 保護ブランチ](../../user/project/repository/branches/protected.md)に JWT をスコープする。
- プロジェクトユーザーのサブセットに制限されている[GitLabの保護タグ](../../user/project/protected_tags.md)に JWT をスコープする。

## トラブルシューティング

### `The secrets provider can not be found. Check your CI/CD variables and try again.` メッセージ

HashiCorp Vault にアクセスするようにConfigureされたジョブを開始しようとすると、このエラーが表示される場合があります。

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

必要な変数が定義されていないため、ジョブを作成できません:

- `VAULT_SERVER_URL`

### `api error: status code 400: missing role` エラー

HashiCorp Vault にアクセスするようにConfigureされたジョブを開始しようとすると、`missing role` エラーが発生する場合があります。`VAULT_AUTH_ROLE` このエラーは変数が定義されていないため、ジョブが Vault サーバーで認証できないことが原因である可能性があります。

### `audience claim does not match any expected audience` エラー

YAML ファイルで指定された ID トークンの`aud:`クレームの値と、JWT 認証に使用される`role`の`bound_audiences`パラメータの値にマッピングがない場合、次のエラーが発生する可能性があります:

`invalid audience (aud) claim: audience claim does not match any expected audience`

これらの値が同じであることを確認してください。
