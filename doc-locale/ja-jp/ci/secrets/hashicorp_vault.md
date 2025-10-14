---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDでHashiCorp Vaultシークレットを使用する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

`CI_JOB_JWT`を使用した認証は、[GitLab 15.9で非推奨となり、GitLab 17.0で削除されました](../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)。代わりに、[IDトークンを使用してHashiCorp Vaultで認証してください](hashicorp_vault.md#example)。このページで実例を紹介しています。

{{< /alert >}}

{{< alert type="note" >}}

Vault 1.17以降、JWTに`aud`クレームが含まれている場合、[JWT認証ログインにはロールにbound_audiencesの設定が必要です](https://developer.hashicorp.com/vault/docs/upgrading/upgrade-to-1.17.x#jwt-auth-login-requires-bound-audiences-on-the-role)。`aud`クレームには、単一の文字列または文字列のリストを指定できます。

{{< /alert >}}

このチュートリアルでは、GitLab CI/CDからHashiCorp Vaultを使用して、認証、設定、およびシークレットを読み取る方法を説明します。

## 前提要件 {#prerequisites}

このチュートリアルでは、GitLab CI/CDとVaultについて理解していることを前提としています。

次に進むには、以下が必要です。

- GitLabのアカウントを持っている。
- 実行中のVaultサーバー（少なくともv1.2.0）へのアクセス権があり、認証を設定し、ロールとポリシーを作成できる。HashiCorp Vaultの場合、これはオープンソースまたはEnterpriseバージョンにすることができます。

{{< alert type="note" >}}

以下の例の`vault.example.com` URLをVaultサーバーのURLに、`gitlab.example.com`をGitLabインスタンスのURLに置き換える必要があります。

{{< /alert >}}

## HashiCorp Vaultのシークレットインテグレーション {#hashicorp-vault-secrets-integration}

IDトークンは、サードパーティサービスとのOIDC認証に使用されるJSON Webトークン（JWT）です。ジョブに少なくとも1つのIDトークンが定義されている場合、`secrets`キーワードは、そのトークンを自動的に使用してVaultで認証します。

JWTには次のフィールドが含まれています。

| フィールド                   | 使用するとき                                       | 説明 |
|-------------------------|--------------------------------------------|-------------|
| `jti`                   | 常時                                     | このトークンの固有識別子 |
| `iss`                   | 常時                                     | 発行者、GitLabインスタンスのドメイン |
| `iat`                   | 常時                                     | 発行日時   |
| `nbf`                   | 常時                                     | 有効になる日時 |
| `exp`                   | 常時                                     | 失効日時  |
| `sub`                   | 常時                                     | サブジェクト（ジョブID） |
| `namespace_id`          | 常時                                     | IDでグループまたはユーザーレベルのネームスペースにスコープを設定するために使用します |
| `namespace_path`        | 常時                                     | パスでグループまたはユーザーレベルのネームスペースにスコープを設定するために使用します |
| `project_id`            | 常時                                     | IDでプロジェクトにスコープを設定するために使用します |
| `project_path`          | 常時                                     | パスでプロジェクトにスコープを設定するために使用します |
| `user_id`               | 常時                                     | ジョブを実行しているユーザーのID |
| `user_login`            | 常時                                     | ジョブを実行しているユーザーのユーザー名 |
| `user_email`            | 常時                                     | ジョブを実行しているユーザーのメール |
| `pipeline_id`           | 常時                                     | このパイプラインのID |
| `pipeline_source`       | 常時                                     | [パイプラインソース](../jobs/job_rules.md#common-if-clauses-with-predefined-variables) |
| `job_id`                | 常時                                     | このジョブのID |
| `ref`                   | 常時                                     | このジョブのGit ref |
| `ref_type`              | 常時                                     | Git refタイプ（`branch`または`tag`） |
| `ref_path`              | 常時                                     | ジョブの完全修飾参照。たとえば、`refs/heads/main`です。GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119075)されました。 |
| `ref_protected`         | 常時                                     | Git refが保護されている場合は`true`、それ以外の場合は`false` |
| `environment`           | ジョブが環境を指定するとき               | このジョブが指定する環境 |
| `groups_direct`         | ユーザーが0 - 200のグループの直接メンバーであるとき | ユーザーの直接メンバーシップグループのパス。ユーザーが200を超えるグループの直接のメンバーである場合は省略されます。（GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/435848)されました）。 |
| `environment_protected` | ジョブが環境を指定するとき               | 指定された環境が保護されている場合は`true`、それ以外の場合は`false` |
| `deployment_tier`       | ジョブが環境を指定するとき               | このジョブが指定する環境の[デプロイ層](../environments/_index.md#deployment-tier-of-environments)（GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/363590)されました） |
| `environment_action`    | ジョブが環境を指定するとき               | ジョブで指定された[環境アクション（`environment:action`）](../environments/_index.md)。（GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/)されました） |

JWTペイロードの例:

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

JWTはRS256を使用してエンコードされ、専用の秘密キーで署名されます。トークンの有効期限は、ジョブのタイムアウト（指定されている場合）または5分（指定されていない場合）に設定されます。このトークンの署名に使用されるキーは、予告なく変更される場合があります。そのような場合、ジョブを再試行すると、現在の署名キーを使用して新しいJWTが生成されます。

JWT認証方法を許可するように設定されたVaultサーバーとの認証に、このJWTを使用できます。GitLabインスタンスのベースURL（`https://gitlab.example.com`など）を`oidc_discovery_url`としてVaultサーバーに提供します。サーバーはその後、インスタンスからトークンを検証するためのキーを取得できます。

Vaultでロールを設定するときに、[bound_claims](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims)を使用してJWTクレームと照合し、各CI/CDジョブがアクセスできるシークレットを制限できます。

Vaultと通信するには、CLIクライアントを使用するか、APIリクエストを実行できます（`curl`または別のクライアントを使用して）。

## 例 {#example}

{{< alert type="warning" >}}

JWTは、リソースへのアクセスを許可できる認証情報です。貼り付ける場所には注意してください。

{{< /alert >}}

ステージングと本番環境のデータベースのパスワードをVaultサーバーに保存するシナリオを考えてみましょう。このシナリオでは、[KV v2](https://developer.hashicorp.com/vault/docs/secrets/kv#kv-version-2)シークレットエンジンを使用することを前提としています。[KV v1](https://developer.hashicorp.com/vault/docs/secrets/kv#version-comparison)を使用している場合は、以下のポリシーパスから`/data/`を削除し、[CI/CDジョブを設定する方法](convert-to-id-tokens.md#kv-secrets-engine-v1)を参照してください。

`vault kv get`コマンドを使用してパスワードを取得できます。

```shell
$ vault kv get -field=password secret/myproject/staging/db
pa$$w0rd

$ vault kv get -field=password secret/myproject/production/db
real-pa$$w0rd
```

ステージングのパスワードは`pa$$w0rd`で、本番環境のパスワードは`real-pa$$w0rd`です。

Vaultサーバーを設定するには、まず[JWT認証](https://developer.hashicorp.com/vault/docs/auth/jwt)方法を有効にします。

```shell
$ vault auth enable jwt
Success! Enabled jwt auth method at: jwt/
```

次に、これらのシークレットの読み取りを許可するポリシーを作成します（シークレットごとに1つ）。

```shell
$ vault policy write myproject-staging - <<EOF
# Policy name: myproject-staging
#
# Read-only permission on 'secret/data/myproject/staging/*' path
path "secret/data/myproject/staging/*" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: myproject-staging

$ vault policy write myproject-production - <<EOF
# Policy name: myproject-production
#
# Read-only permission on 'secret/data/myproject/production/*' path
path "secret/data/myproject/production/*" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: myproject-production
```

JWTをこれらのポリシーにリンクするロールも必要です。

たとえば、`myproject-staging`という名前のステージング用のロールが1つあります。[bound_claims](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims)は、ID `22`のプロジェクトの`main`ブランチでのみポリシーを使用できるように設定されています。

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

そして、`myproject-production`という名前の本番環境用のロールが1つあります。このロールの`bound_claims`セクションでは、`auto-deploy-*`パターンに一致する保護ブランチのみがシークレットにアクセスできます。

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

[JWTに含まれる](#hashicorp-vault-secrets-integration)クレームは、bound_claimsの値のリストと照合することもできます。次に例を示します。

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

- `namespace_id`のみが使用されている場合、ネームスペース内のすべてのプロジェクトが許可されます。ネストされたプロジェクトは含まれていないため、必要に応じて、そのネームスペースIDもリストに追加する必要があります。
- `namespace_id`と`project_id`の両方が使用されている場合、Vaultは最初にプロジェクトのネームスペースが`namespace_id`にあるかどうかを確認し、次にプロジェクトが`project_id`にあるかどうかを確認します。

[`token_explicit_max_ttl`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#token_explicit_max_ttl)は、認証に成功すると、Vaultによって発行されたトークンに60秒のハードライフタイム制限があることを指定します。

[`user_claim`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#user_claim)は、ログインが成功したときにVaultによって作成されたアイデンティティエイリアスの名前を指定します。

[`bound_claims_type`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims_type)は、`bound_claims`値の解釈を設定します。`glob`に設定すると、値はglobとして解釈され、`*`は任意の数の文字に一致します。

[前述の表](#hashicorp-vault-secrets-integration)にリストされているクレームフィールドには、VaultのJWT認証のアクセサー名を使用することにより、[Vaultのポリシーパスのテンプレートを作成](https://developer.hashicorp.com/vault/tutorials/policies/policy-templating?in=vault%2Fpolicies)する目的でアクセスすることもできます。[マウントアクセサー名](https://developer.hashicorp.com/vault/tutorials/auth-methods/identity#step-1-create-an-entity-with-alias)（以下の例では`ACCESSOR_NAME`）は、`vault auth list`を実行することで取得できます。

`project_path`という名前の指定されたメタデータフィールドを利用するポリシーテンプレートの例:

```plaintext
path "secret/data/{{identity.entity.aliases.ACCESSOR_NAME.metadata.project_path}}/staging/*" {
  capabilities = [ "read" ]
}
```

前述のテンプレートポリシーをサポートするロールの例。[`claim_mappings`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#claim_mappings)設定を使用して、クレームフィールド`project_path`をメタデータフィールドとしてマップします。

```plaintext
{
  "role_type": "jwt",
  ...
  "claim_mappings": {
    "project_path": "project_path"
  }
}
```

オプションの完全なリストについては、Vaultの[ロール作成に関するドキュメント](https://developer.hashicorp.com/vault/api-docs/auth/jwt#create-role)を参照してください。

{{< alert type="warning" >}}

提供されたクレーム（`project_id`や`namespace_id`など）のいずれかを使用して、常にロールをプロジェクトまたはネームスペースに制限してください。そうしないと、このインスタンスによって生成されたJWTは、このロールを使用して認証できる可能性があります。

{{< /alert >}}

次に、JWT認証方法を設定します。

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer="https://gitlab.example.com"
```

[`bound_issuer`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_issuer)は、`gitlab.example.com`に設定された発行者（つまり、`iss`クレーム）を持つJWTのみがこの方法を使用して認証でき、トークンの検証には`oidc_discovery_url`（`https://gitlab.example.com`）を使用する必要があることを指定します。

使用可能な設定オプションの完全なリストについては、Vaultの[APIドキュメント](https://developer.hashicorp.com/vault/api-docs/auth/jwt#configure)を参照してください。

GitLabで、Vaultサーバーに関する詳細を提供するために、次の[CI/CD変数](../variables/_index.md#for-a-project)を作成します。

- `VAULT_SERVER_URL` - VaultサーバーのURL（`https://vault.example.com:8200`など）。
- `VAULT_AUTH_ROLE` - オプション。認証を試行するときに使用するVault JWT認証ロールの名前。このチュートリアルでは、`myproject-staging`および`myproject-production`という名前の2つのロールをすでに作成しました。ロールが指定されていない場合、Vaultは、認証方法の設定時に指定された[デフォルトロール](https://developer.hashicorp.com/vault/api-docs/auth/jwt#default_role)を使用します。
- `VAULT_AUTH_PATH` - オプション。認証方法がマウントされているパス。デフォルトは`jwt`です。
- `VAULT_NAMESPACE` - オプション。シークレットの読み取りと認証に使用する[Vault Enterpriseネームスペース](https://developer.hashicorp.com/vault/docs/enterprise/namespaces)。ネームスペースが指定されていない場合、Vaultはルート（`/`）ネームスペースを使用します。この設定はVault Open Sourceでは無視されます。

### HashiCorp Vaultを使用した自動IDトークン認証 {#automatic-id-token-authentication-with-hashicorp-vault}

次のジョブは、デフォルトブランチに対して実行される場合、`secret/myproject/staging/`にあるシークレットを読み取ることができますが、`secret/myproject/production/`にあるシークレットは読み取ることができません。

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

この例では、次のようになります。

- `id_tokens` - OIDC認証に使用されるJSON Webトークン（JWT）。`aud`クレームは、Vault JWT認証方法に使用される`role`の`bound_audiences`パラメータと一致するように設定されています。
- `@secret` - シークレットエンジンが有効になっているVault名。
- `myproject/staging/db` - Vault内のシークレットのパスの場所。
- `password` - 参照されているシークレットでフェッチするフィールド。

複数のIDトークンが定義されている場合は、`token`キーワードを使用して、使用するトークンを指定します。次に例を示します。

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

### 手動IDトークン認証 {#manual-id-token-authentication}

IDトークンを使用して手動でHashiCorp Vaultで認証できます。次に例を示します。

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

### Vaultシークレットへのトークンアクセスを制限する {#limit-token-access-to-vault-secrets}

Vaultの保護機能とGitLab機能を使用することで、VaultシークレットへのIDトークンアクセスを制御できます。たとえば、次のようにトークンを制限します。

- 特定のIDトークンの`aud`クレームに対して、Vaultの[bound_audiences](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-audiences)を使用する。
- `group_claim`を使用して、特定のグループに対してVaultの[bound_claims](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims)を使用する。
- 特定のユーザーの`user_login`と`user_email`に基づいて、Vaultのbound_claimsの値をハードコードする。
- [`token_explicit_max_ttl`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#token_explicit_max_ttl)で指定されているように、トークンのTTLのVaultタイム制限を設定する。この場合、トークンは認証後に失効します。
- プロジェクトユーザーのサブセットに制限されている[GitLabの保護ブランチ](../../user/project/repository/branches/protected.md)にJWTをスコープする。
- プロジェクトユーザーのサブセットに制限されている[GitLabの保護タグ](../../user/project/protected_tags.md)にJWTをスコープする。

## トラブルシューティング {#troubleshooting}

### `The secrets provider can not be found. Check your CI/CD variables and try again.`メッセージ {#the-secrets-provider-can-not-be-found-check-your-cicd-variables-and-try-again-message}

HashiCorp Vaultにアクセスするように設定されたジョブを開始しようとすると、このエラーが表示される場合があります。

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

必要な変数が定義されていないため、ジョブを作成できません。

- `VAULT_SERVER_URL`

### `api error: status code 400: missing role`エラー {#api-error-status-code-400-missing-role-error}

HashiCorp Vaultにアクセスするように設定されたジョブを開始しようとすると、`missing role`エラーが発生する場合があります。このエラーは、`VAULT_AUTH_ROLE`変数が定義されていないため、ジョブがVaultサーバーで認証できないことが原因で発生する可能性があります。

### `audience claim does not match any expected audience`エラー {#audience-claim-does-not-match-any-expected-audience-error}

YAMLファイルで指定されたIDトークンの`aud:`クレームの値と、JWT認証に使用される`role`の`bound_audiences`パラメータの値が一致しない場合、次のエラーが発生する可能性があります。

`invalid audience (aud) claim: audience claim does not match any expected audience`

これらの値が同じであることを確認してください。
