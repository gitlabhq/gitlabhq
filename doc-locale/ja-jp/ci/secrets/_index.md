---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI での外部シークレットの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

シークレットは、CI ジョブが作業を完了するために必要な機密情報を表します。この機密情報には、API トークン、データベース認証情報、秘密キーなどのアイテムがあります。シークレットは、シークレットプロバイダーから提供されます。

ジョブに常に提示される CI/CD変数とは異なり、シークレットはジョブによって明示的に要求される必要があります。構文の詳細については、[GitLab CI/CD パイプライン設定リファレンス](../yaml/_index.md#secrets)をお読みください。

GitLab は、次のシークレット管理プロバイダーをサポートしています。

1. [HashiCorp の Vault](#use-vault-secrets-in-a-ci-job)
1. [Google Cloud Secret Manager](gcp_secret_manager.md)
1. [Azure Key Vault](azure_key_vault.md)

GitLab は、最初にサポートされるプロバイダーとして[HashiCorp の Vault](https://www.vaultproject.io) を、最初にサポートされるシークレットエンジンとして[KV-V2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) を選択しました。

[ID トークン](../yaml/_index.md#id_tokens)を使用して[Vault で認証](https://developer.hashicorp.com/vault/docs/auth/jwt#jwt-authentication)します。[HashiCorp Vault を使用した認証とシークレットの読み取り](hashicorp_vault.md)のチュートリアルには、ID トークンを使用した認証に関する詳細が記載されています。

[Vault サーバーをConfigure](#configure-your-vault-server)してから、[CI ジョブで Vault シークレットを使用](#use-vault-secrets-in-a-ci-job)する必要があります。

HashiCorp Vault で GitLab を使用するフローを次の図にまとめます。

![GitLab と HashiCorp の間のフロー](../img/gitlab_vault_workflow_v13_4.png "GitLab が HashiCorp Vault で認証する方法")

1. Vault とシークレットをConfigureします。
1. JWT を生成し、CI ジョブに提供します。
1. Runner は HashiCorp Vault に接続し、JWT を使用して認証します。
1. HashiCorp Vault は JWT を検証します。
1. HashiCorp Vault は、バインドされたクレームを確認し、ポリシーをアタッチします。
1. HashiCorp Vault はトークンを返します。
1. Runner は HashiCorp Vault からシークレットを読み取ります。

{{< alert type="note" >}}

この機能のバージョンについては、[HashiCorp Vault を使用した認証とシークレットの読み取り](hashicorp_vault.md)のチュートリアルをお読みください。すべてのサブスクリプションレベルで利用でき、Vault との間でシークレットの書き込みと削除をサポートし、複数のシークレットエンジンをサポートします。

{{< /alert >}}

以下の `vault.example.com` URL を Vault サーバーの URL に、`gitlab.example.com` を GitLab インスタンスの URL に置き換える必要があります。

## Vault シークレットエンジン

{{< history >}}

- `generic` オプションは GitLab Runner 16.11 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)されました。

{{< /history >}}

GitLab Runner でサポートされている Vault シークレットエンジンは次のとおりです:

| シークレットエンジン                                                                                                                                     | [`secrets:engine:name`](../yaml/_index.md#secretsvault)値 | Runner バージョン | 詳細 |
|----------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|----------------|---------|
| [KV シークレットエンジン - バージョン 2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)                                                       | `kv-v2`                                                      | 13.4           | `kv-v2`は、エンジンタイプが明示的に指定されていない場合に GitLab Runner が使用するデフォルトのエンジンです。 |
| [KV シークレットエンジン - バージョン 1](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v1)                                                       | `kv-v1`または`generic`                                         | 13.4           | `generic`キーワードのサポートは、GitLab 15.11 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)されました。 |
| [AWS シークレットエンジン](https://developer.hashicorp.com/vault/docs/secrets/aws)                                                                   | `generic`                                                    | 16.11          |         |
| [Hashicorp Vault Artifactory Secrets Plugin](https://jfrog.com/help/r/jfrog-integrations-documentation/hashicorp-vault-artifactory-secrets-plugin) | `generic`                                                    | 16.11          | このシークレットバックエンドは、JFrog Artifactory サーバー (5.0.0 以降) と通信し、指定されたスコープでアクセストークンを動的にプロビジョニングします。 |

## Vault サーバーをConfigureする

Vault サーバーをConfigureするには:

1. Vault サーバーがバージョン 1.2.0 以降で実行されていることを確認します。
1. 次のコマンドを実行して認証方法を有効にします。これらは、GitLab インスタンスの[OIDC 調査 URL](https://openid.net/specs/openid-connect-discovery-1_0.html)を Vault サーバーに提供するため、Vault は公開署名キーをフェッチし、認証時に JSON Web トークン (JWT) を検証できます。

   ```shell
   $ vault auth enable jwt

   $ vault write auth/jwt/config \
     oidc_discovery_url="https://gitlab.example.com" \
     bound_issuer="gitlab.example.com"
   ```

1. Vault サーバーでポリシーをConfigureし、特定のパスおよびオペレーションへのアクセスを許可または禁止します。この例では、本番環境に必要なシークレットのセットへの読み取りアクセスを許可します。

   ```shell
   vault policy write myproject-production - <<EOF
   # Read-only permission on 'ops/data/production/*' path

   path "ops/data/production/*" {
     capabilities = [ "read" ]
   }
   EOF
   ```

1. このページの[Vault サーバーロールのConfigure](#configure-vault-server-roles)で説明されているように、Vault サーバーでロールをConfigureし、ロールをプロジェクトまたはネームスペースに制限します。
1. [次の CI/CD変数を作成](../variables/_index.md#for-a-project)して、Vault サーバーに関する詳細を提供します。
   - `VAULT_SERVER_URL` - Vault サーバーの URL (例: `https://vault.example.com:8200`)。必須。
   - `VAULT_AUTH_ROLE` - オプション。認証を試行するときに使用するロール。ロールが指定されていない場合、Vault は認証方法のConfigure時に指定された[デフォルトロール](https://developer.hashicorp.com/vault/api-docs/auth/jwt#default_role)を使用します。
   - `VAULT_AUTH_PATH` - オプション。認証方法がマウントされているパス。デフォルトは`jwt`です。
   - `VAULT_NAMESPACE` - オプション。シークレットの読み取りと認証に使用する[Vault Enterprise ネームスペース](https://developer.hashicorp.com/vault/docs/enterprise/namespaces)。次の場合:
     - Vault の場合、ネームスペースが指定されていない場合は、`root`（「`/`」）ネームスペースが使用されます。
     - Vault オープンソースの場合、設定は無視されます。
     - [HashiCorp Cloud Platform（HCP）](https://www.hashicorp.com/cloud) Vault の場合、ネームスペースが必要です。HCP Vault は、デフォルトで`admin`ネームスペースをルートネームスペースとして使用します。たとえば、`VAULT_NAMESPACE=admin`。

   {{< alert type="note" >}}

   ユーザーインターフェースでこれらの値を提供するサポートは、[このイシューで追跡](https://gitlab.com/gitlab-org/gitlab/-/issues/218677)されます。

   {{< /alert >}}

## CI ジョブで Vault シークレットを使用する

{{< details >}}

- プラン:Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Vault サーバーをConfigure](#configure-your-vault-server)した後、[`vault` キーワード](../yaml/_index.md#secretsvault)で定義することにより、Vault に保存されているシークレットを使用できます。

```yaml
job_using_vault:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops
      token: $VAULT_ID_TOKEN
```

この例:

- `production/db` は、シークレットへのパスです。
- `password` はフィールドです。
- `ops` は、シークレットエンジンがマウントされているパスです。
- `production/db/password@ops` は、`ops/data/production/db`のパスに変換されます。
- 認証は`$VAULT_ID_TOKEN`を使用します。

GitLab が Vault からシークレットをフェッチした後、値は一時ファイルに保存されます。このファイルへのパスは、[`file`タイプの変数](../variables/_index.md#use-file-type-cicd-variables)と同様に、`DATABASE_PASSWORD`という名前の CI/CD変数に保存されます。

デフォルトの動作を上書きするには、`file`オプションを明示的に設定します。

```yaml
secrets:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  DATABASE_PASSWORD:
    vault: production/db/password@ops
    file: false
    token: $VAULT_ID_TOKEN
```

この例では、シークレット値は、それを保持するファイルを指すのではなく、`DATABASE_PASSWORD`変数に直接配置されます。

## 別のシークレットエンジンを使用する

デフォルトでは、`kv-v2`シークレットエンジンが使用されます。[別のエンジン](#vault-secrets-engines)を使用するには、設定の`vault`の下に`engine`セクションを追加します。

たとえば、Artifactory のシークレットエンジンとパスを設定するには:

```yaml
job_using_vault:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    JFROG_TOKEN:
      vault:
        engine:
          name: generic
          path: artifactory
        path: production/jfrog
        field: access_token
      file: false
```

この例では、シークレット値は`artifactory/production/jfrog`からフィールド`access_token`で取得されます。`generic`シークレットエンジンは、[`kv-v1`、AWS、Artifactory、およびその他の同様の Vault シークレットエンジン](#vault-secrets-engines)に使用できます。

## Vault サーバーロールをConfigureする

CI ジョブが認証を試行すると、ロールが指定されます。ロールを使用して、さまざまなポリシーをグループ化できます。認証が成功すると、これらのポリシーが結果の Vault トークンにアタッチされます。

[バインドされたクレーム](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims)は、JWT クレームに一致する定義済みの値です。バインドされたクレームを使用すると、特定の GitLab ユーザー、特定のプロジェクト、または特定の Git 参照に対して実行されているジョブへのアクセスを制限できます。必要なバインドされたクレームをいくつでも持つことができますが、認証を成功させるには、*すべて*が一致する必要があります。

バインドされたクレームを[ユーザーロール](../../user/permissions.md)や[保護ブランチ](../../user/project/repository/branches/protected.md)などの GitLab 機能と組み合わせることで、これらのルールを特定のユースケースに合わせて調整できます。この例では、認証は、本番環境リリースに使用されるパターンに一致する名前の保護タグに対して実行されているジョブに対してのみ許可されます:

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
    "project_id": "42",
    "ref_protected": "true",
    "ref_type": "tag",
    "ref": "auto-deploy-*"
  }
}
EOF
```

{{< alert type="warning" >}}

`project_id`や`namespace_id`などの提供されたクレームのいずれかを使用して、ロールをプロジェクトまたはネームスペースに常に制限してください。これらの制限がない場合、この GitLab インスタンスによって生成された JWT は、このロールを使用して認証できる可能性があります。

{{< /alert >}}

ID トークン JWT クレームの完全なリストについては、[HashiCorp Vault を使用した認証とシークレットの読み取り](hashicorp_vault.md)のチュートリアルの[仕組み](hashicorp_vault.md)セクションをお読みください。

時間単位、IP アドレス範囲、使用回数など、結果の Vault トークンにいくつかの属性を指定することもできます。オプションの完全なリストは、JSON Web トークンメソッドの[ロールの作成に関する Vault のドキュメント](https://developer.hashicorp.com/vault/api-docs/auth/jwt#create-role)で入手できます。

## トラブルシューティング

### 自己署名証明書エラー: `certificate signed by unknown authority`

Vault サーバーが自己署名証明書を使用している場合、ジョブログに次のエラーが表示されます:

```plaintext
ERROR: Job failed (system failure): resolving secrets: initializing Vault service: preparing authenticated client: checking Vault server health: Get https://vault.example.com:8000/v1/sys/health?drsecondarycode=299&performancestandbycode=299&sealedcode=299&standbycode=299&uninitcode=299: x509: certificate signed by unknown authority
```

このエラーを解決するには、2 つのオプションがあります。

- 自己署名証明書を GitLab Runner サーバーの CA ストアに追加します。[Helmチャート](https://docs.gitlab.com/runner/install/kubernetes.html)を使用して GitLab Runner をデプロイした場合は、独自の GitLab Runner イメージを作成する必要があります。
- `VAULT_CACERT`環境変数を使用して、証明書を信頼するように GitLab Runner をConfigureします。
  - systemd を使用して GitLab Runner を管理している場合は、[GitLab Runner の環境変数を追加する方法](https://docs.gitlab.com/runner/configuration/init.html#setting-custom-environment-variables)を参照してください。
  - [Helmチャート](https://docs.gitlab.com/runner/install/kubernetes.html)を使用して GitLab Runner をデプロイした場合:
    1. [GitLab にアクセスするためのカスタム証明書を提供](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration.html#access-gitlab-with-a-custom-certificate)し、GitLab の証明書の代わりに Vault サーバーの証明書を必ず追加してください。GitLab インスタンスも自己署名証明書を使用している場合は、同じ`Secret`に両方を追加できるはずです。
    1. `values.yaml`ファイルに次の行を追加します:

       ```yaml
       ## Replace both the <SECRET_NAME> and the <VAULT_CERTIFICATE>
       ## with the actual values you used to create the secret

       certsSecretName: <SECRET_NAME>

       envVars:
         - name: VAULT_CACERT
           value: "/home/gitlab-runner/.gitlab-runner/certs/<VAULT_CERTIFICATE>"
       ```

[GitLab Development Kit（GDK）](https://gitlab.com/gitlab-org/gitlab-development-kit)を使用してローカルで開発モードで Vault サーバーを実行している場合も、このエラーが発生する可能性があります。Vault サーバーの自己署名証明書を信頼するようにシステムに手動で依頼できます。この[サンプルチュートリアル](https://iboysoft.com/tips/how-to-trust-a-certificate-on-mac.html)では、macOS でこれを行う方法について説明します。

### `resolving secrets: secret not found: MY_SECRET` エラー

GitLab が Vault でシークレットを見つけられない場合、次のエラーが表示されることがあります。

```plaintext
ERROR: Job failed (system failure): resolving secrets: secret not found: MY_SECRET
```

`vault`値が[CI/CD ジョブで正しくConfigureされている](#use-vault-secrets-in-a-ci-job)ことを確認します。

[Vault CLI で`kv`コマンド](https://developer.hashicorp.com/vault/docs/commands/kv)を使用して、シークレットを取得できるかどうかを確認し、CI/CD設定の`vault`値の構文を判断できます。たとえば、シークレットを取得するには:

```shell
$ vault kv get -field=password -namespace=admin -mount=ops "production/db"
this-is-a-password
```
