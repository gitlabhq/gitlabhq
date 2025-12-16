---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'GitLab CI/CDでHashiCorp Vaultシークレットを使用する'
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab CI/CDでHashiCorp Vaultのシークレットを使用できます。[IDトークン](id_token_authentication.md)を使用して、[HashiCorp Vaultで認証する](https://developer.hashicorp.com/vault/docs/auth/jwt#jwt-authentication)。

CIジョブでVaultのシークレットを使用する前に、Vaultサーバーを設定する必要があります。HashiCorp Vaultを使用した[認証とシークレットの読み取り](hashicorp_vault_tutorial.md)のチュートリアルには、IDトークンを使用した認証に関する詳細が記載されています。

以下の例では、`vault.example.com`のURLをVaultサーバーのURLに、`gitlab.example.com`をGitLabインスタンスのURLに置き換えてください。

## Vaultサーバーを設定する {#configure-your-vault-server}

Vaultサーバーを設定するには:

1. 次のコマンドを実行して認証方法を有効にします。これらは、GitLabインスタンスの[OIDC Discovery URL](https://openid.net/specs/openid-connect-discovery-1_0.html)をVaultサーバーに提供するため、Vaultは公開署名キーをフェッチし、認証時にJSON Webトークン（JWT）を検証できます:

   ```shell
   $ vault auth enable jwt

   $ vault write auth/jwt/config \
     oidc_discovery_url="https://gitlab.example.com" \
     bound_issuer="gitlab.example.com"
   ```

1. 特定のパスおよびオペレーションへのアクセスを許可または禁止するようにVaultサーバーでポリシーを設定します。この例では、本番環境に必要なシークレットのセットへの読み取りアクセスを許可します:

   ```shell
   vault policy write myproject-production - <<EOF
   # Read-only permission on 'ops/data/production/*' path

   path "ops/data/production/*" {
     capabilities = [ "read" ]
   }
   EOF
   ```

1. プロジェクトまたはネームスペースに制限して、[Vaultサーバーのロール](#configure-server-roles)を設定します。
1. Vaultサーバーの詳細を提供するには、次の[CI/CD変数](../variables/_index.md#for-a-project)を作成します:
   - `VAULT_SERVER_URL`: ：VaultサーバーのURL。例：`https://vault.example.com:8200`。
   - `VAULT_AUTH_ROLE`: オプション。認証を試行するときに使用するロール。ロールが指定されていない場合、Vaultは、認証方法の設定時に指定された[デフォルトロール](https://developer.hashicorp.com/vault/api-docs/auth/jwt#default_role)を使用します。
   - `VAULT_AUTH_PATH`: オプション。認証方法がマウントされているパス。デフォルトは`jwt`です。
   - `VAULT_NAMESPACE`: オプション。シークレットの読み取りと認証に使用する[Vault Enterpriseネームスペース](https://developer.hashicorp.com/vault/docs/enterprise/namespaces)。以下のとおりになります:
     - Vaultでは、ネームスペースが指定されていない場合は`root`（「`/`」）ネームスペースが使用されます。
     - Vaultオープンソースでは、この設定は無視されます。
     - [HashiCorp Cloud Platform（HCP）](https://www.hashicorp.com/cloud)Vaultでは、ネームスペースが必要です。HCP Vaultは、デフォルトで`admin`ネームスペースをルートネームスペースとして使用します。たとえば`VAULT_NAMESPACE=admin`などです。

### サーバーロールを構成する {#configure-server-roles}

CIジョブは、認証を試行するときにロールを指定します。ロールを使用して、さまざまなポリシーをグループ化できます。認証が成功すると、これらのポリシーが結果のVaultトークンにアタッチされます。

[バインドされたクレーム](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims)は、JWTクレームに一致する定義済みの値です。バインドされたクレームを使用すると、特定のGitLabユーザー、特定のプロジェクト、または特定のGit参照に対して実行されているジョブへのアクセスを制限できます。バインドされたクレームは、必要に応じていくつでも持つことができますが、認証を成功させるには、すべてが一致する必要があります。

バインドされたクレームを[ユーザーロール](../../user/permissions.md)や[保護ブランチ](../../user/project/repository/branches/protected.md)などのGitLab機能と組み合わせることで、これらのルールを調整して、特定のユースケースに適合させることができます。この例では、認証が許可されるのは、本番環境リリースに使用されるパターンに一致する名前の保護されたタグに対して実行されているジョブのみです:

```json
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

提供されたクレーム（`project_id`や`namespace_id`など）のいずれかを使用して、常にロールをプロジェクトまたはネームスペースに制限してください。このように制限しないと、このGitLabインスタンスによって生成されたJWTは、このロールを使用して認証できる可能性があります。

{{< /alert >}}

IDトークンJWTクレームの完全なリストについては、[GitLab CI/CDでHashiCorp Vaultのシークレットを使用する](hashicorp_vault_tutorial.md)チュートリアルをレビューしてください。

有効期限、IPアドレス範囲、使用回数など、結果のVaultトークンにいくつかの属性を指定することもできます。オプションの完全なリストは、JSON Webトークンメソッドの[ロールの作成に関するVaultのドキュメント](https://developer.hashicorp.com/vault/api-docs/auth/jwt#create-role)に記載されています。

## CIジョブでVaultのシークレットを使用する {#use-vault-secrets-in-a-cicd-job}

ジョブに少なくとも1つのIDトークンが定義されている場合、[`secrets`](../yaml/_index.md#secrets)キーワードは、そのトークンを自動的に使用してVaultで認証します。

[Vaultサーバーの構成](#configure-your-vault-server)後、Vaultに保存されているシークレットを使用するには、[`secrets:vault`](../yaml/_index.md#secretsvault)キーワードを使用します:

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

この例では: 

- `production/db`は、シークレットのパスです。
- `password`は、フィールドです。
- `ops`は、シークレットエンジンがマウントされているパスです。
- `production/db/password@ops`は、`ops/data/production/db`のパスに変換されます。
- 認証は`$VAULT_ID_TOKEN`を使用します。

GitLabがVaultからシークレットをフェッチした後、値は一時ファイルに保存されます。このファイルのパスは、[`file`タイプの変数](../variables/_index.md#use-file-type-cicd-variables)と同様に、`DATABASE_PASSWORD`という名前のCI/CD変数に保存されます。

デフォルトの動作を上書きするには、`file`オプションを明示的に設定します:

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

## シークレットエンジン {#secrets-engines}

{{< history >}}

- `generic`オプションは、GitLab Runner 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)されました。

{{< /history >}}

GitLab Runnerは、[`secrets:engine:name`](../yaml/_index.md#secretsvault)キーワードで異なるシークレットエンジンをサポートしています:

| シークレットエンジン                                                                                                                                     | `secrets:engine:name`の値 | Runnerバージョン | 詳細 |
|----------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|----------------|---------|
| [KVシークレットエンジン - バージョン2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)                                                       | `kv-v2`                     | 13.4           | `kv-v2`は、エンジンタイプが明示的に指定されていない場合にGitLab Runnerが使用するデフォルトのエンジンです。 |
| [KVシークレットエンジン - バージョン1](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v1)                                                       | `kv-v1`または`generic`        | 13.4           | `generic`キーワードのサポートは、GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)されました。 |
| [<AWSシークレットエンジン](https://developer.hashicorp.com/vault/docs/secrets/aws)                                                                       | `generic`                   | 16.11          |         |
| [HashiCorp Vault Artifactory Secrets Plugin](https://jfrog.com/help/r/jfrog-integrations-documentation/hashicorp-vault-artifactory-secrets-plugin) | `generic`                   | 16.11          | このシークレットバックエンドは、JFrog Artifactoryサーバー（5.0.0以降）と通信し、指定されたスコープでアクセストークンを動的にプロビジョニングします。 |

### 別のシークレットエンジンを使用する {#use-a-different-secrets-engine}

デフォルトでは、`kv-v2`シークレットエンジンが使用されます。別のエンジンを使用するには、設定の`vault`の下に`engine`セクションを追加します。

たとえば、Artifactoryのシークレットエンジンとパスを設定するには、次のようにします:

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

この例では、シークレット値は`artifactory/production/jfrog`からフィールド`access_token`で取得されます。

## トラブルシューティング {#troubleshooting}

### 自己署名証明書エラー: `certificate signed by unknown authority` {#self-signed-certificate-error-certificate-signed-by-unknown-authority}

Vaultサーバーが自己署名証明書を使用している場合、ジョブログに次のエラーが出力されます:

```plaintext
ERROR: Job failed (system failure): resolving secrets: initializing Vault service: preparing authenticated client: checking Vault server health: Get https://vault.example.com:8000/v1/sys/health?drsecondarycode=299&performancestandbycode=299&sealedcode=299&standbycode=299&uninitcode=299: x509: certificate signed by unknown authority
```

このエラーを解決するには、2つのオプションがあります:

- 自己署名証明書をGitLab RunnerサーバーのCAストアに追加します。[Helmチャート](https://docs.gitlab.com/runner/install/kubernetes.html)を使用してGitLab Runnerをデプロイした場合は、独自のGitLab Runnerイメージを作成する必要があります。
- `VAULT_CACERT`環境変数を使用して、証明書を信頼するようにGitLab Runnerを設定します:
  - systemdを使用してGitLab Runnerを管理している場合は、[GitLab Runnerの環境変数を追加する方法](https://docs.gitlab.com/runner/configuration/init.html#setting-custom-environment-variables)を参照してください。
  - [Helmチャート](https://docs.gitlab.com/runner/install/kubernetes.html)を使用してGitLab Runnerをデプロイした場合は、次のようにします:
    1. [GitLabにアクセスするためのカスタム証明書を提供](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration.html#access-gitlab-with-a-custom-certificate)し、GitLabの証明書の代わりに、Vaultサーバーの証明書を必ず追加してください。GitLabインスタンスも自己署名証明書を使用している場合は、同じ`Secret`に両方を追加できるはずです。
    1. `values.yaml`ファイルに次の行を追加します:

       ```yaml
       ## Replace both the <SECRET_NAME> and the <VAULT_CERTIFICATE>
       ## with the actual values you used to create the secret

       certsSecretName: <SECRET_NAME>

       envVars:
         - name: VAULT_CACERT
           value: "/home/gitlab-runner/.gitlab-runner/certs/<VAULT_CERTIFICATE>"
       ```

[GitLab Development Kit（GDK）](https://gitlab.com/gitlab-org/gitlab-development-kit)を使用して、開発モードでVaultサーバーをローカルで実行している場合も、このエラーが発生する可能性があります。Vaultサーバーの自己署名証明書を信頼するように手動でシステムに指示できます。この[サンプルチュートリアル](https://iboysoft.com/tips/how-to-trust-a-certificate-on-mac.html)では、macOSで同じことを行う方法について説明しています。

### `resolving secrets: secret not found: MY_SECRET`エラー {#resolving-secrets-secret-not-found-my_secret-error}

GitLabがVaultでシークレットを見つけられない場合、次のエラーが表示されることがあります:

```plaintext
ERROR: Job failed (system failure): resolving secrets: secret not found: MY_SECRET
```

`vault`値が[CI/CDジョブで正しく設定されている](#use-vault-secrets-in-a-cicd-job)ことを確認します。

[Vault CLIで`kv`コマンド](https://developer.hashicorp.com/vault/docs/commands/kv)を使用して、シークレットを取得できるかどうかを確認し、CI/CD設定の`vault`値の構文決定に役立てることができます。たとえば、シークレットを取得するには、次のようにします:

```shell
$ vault kv get -field=password -namespace=admin -mount=ops "production/db"
this-is-a-password
```
