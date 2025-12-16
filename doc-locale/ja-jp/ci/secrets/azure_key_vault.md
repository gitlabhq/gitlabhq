---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDでAzure Key Vaultシークレットを使用する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/271271)されたのはGitLabおよびGitLab Runner 16.3です。[イシュー424746](https://gitlab.com/gitlab-org/gitlab/-/issues/424746)により、この機能は期待どおりに動作しませんでした。
- [イシュー424746](https://gitlab.com/gitlab-org/gitlab/-/issues/424746)が解決され、この機能はGitLab Runner 16.6で一般的に利用可能になりました。

{{< /history >}}

[Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/)に保存されているシークレットをGitLab CI/CDパイプラインで使用できます。

前提要件: 

- Azureで[Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal)を用意します。
  - IAMユーザーは、Key Vaultに割り当てられた**resource group**（リソースグループ）の[**Key Vault Administrator**（Key Vault管理者）ロールの割り当てを許可](https://learn.microsoft.com/en-us/azure/role-based-access-control/quickstart-assign-role-user-portal#grant-access)されている必要があります。そうでないと、Key Vault内にシークレットを作成できません。
- 一時的な認証情報を取得するために、Azureで[OpenID Connectを設定](../cloud_services/azure/_index.md)します。これらの手順には、Key Vaultアクセス用のAzure ADアプリケーションを作成する方法が含まれています。
- Vaultサーバーの詳細を提供するために、[CI/CD変数をプロジェクトに追加](../variables/_index.md#for-a-project)します:
  - `AZURE_KEY_VAULT_SERVER_URL`: `https://vault.example.com`のようなAzure Key VaultサーバーのURL。
  - `AZURE_CLIENT_ID`: AzureアプリケーションのクライアントID。
  - `AZURE_TENANT_ID`: AzureアプリケーションのテナントID。

## CI/CDジョブでAzure Key Vaultシークレットを使用する {#use-azure-key-vault-secrets-in-a-cicd-job}

[`azure_key_vault`](../yaml/_index.md#secretsazure_key_vault)キーワードで定義することにより、ジョブでAzure Key Vaultに保存されているシークレットを使用できます:

```yaml
job:
  id_tokens:
    AZURE_JWT:
      aud: 'https://gitlab.com'
  secrets:
    DATABASE_PASSWORD:
      token: $AZURE_JWT
      azure_key_vault:
        name: 'DATABASE-PASSWORD'
        version: '00000000000000000000000000000000'
```

同じジョブでAzure Key Vaultから複数のシークレットを使用するには、`secrets`キーワードの下に各シークレットを定義します:

```yaml
job:
  id_tokens:
    AZURE_JWT:
      aud: 'https://gitlab.com'
  secrets:
    REDIS_PASSWORD:
      token: $AZURE_JWT
      azure_key_vault:
        name: 'REDIS-PASSWORD'
        version: '00000000000000000000000000000000'
    DATABASE_PASSWORD:
      token: $AZURE_JWT
      azure_key_vault:
        name: 'DATABASE-PASSWORD'
        version: '00000000000000000000000000000000'
```

これらの例では、次のようになります:

- `aud`はオーディエンスであり、[フェデレーションIAM認証情報を作成](../cloud_services/azure/_index.md#create-azure-ad-federated-identity-credentials)するときに使用するオーディエンスと一致する必要があります
- `name`は、Azure Key Vault内のシークレットの名前です。
- `version`は、Azure Key Vault内のシークレットのバージョンです。バージョンは、ダッシュなしで生成されたGUIDであり、Azure Key Vaultシークレットページにあります。
- GitLabはAzure Key Vaultからシークレットをフェッチし、値を一時ファイルに格納します。このファイルへのパスは、[ファイルタイプのCI/CD変数](../variables/_index.md#use-file-type-cicd-variables)と同様に、シークレット（`DATABASE_PASSWORD`や`REDIS_PASSWORD`など）で定義した名前のCI/CD変数に格納されます。

## トラブルシューティング {#troubleshooting}

AzureでOIDCを設定する際の一般的な問題については、[AzureのOIDCトラブルシューティング](../cloud_services/azure/_index.md#troubleshooting)を参照してください。

### `JWT token is invalid or malformed`メッセージ {#jwt-token-is-invalid-or-malformed-message}

Azure Key Vaultからシークレットをフェッチすると、次のエラーが表示されることがあります:

```plaintext
RESPONSE 400 Bad Request
AADSTS50027: JWT token is invalid or malformed.
```

これは、[既知のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/424746)が原因で、JWTトークンが正しく解析されないGitLab Runnerで発生します。これを解決するには、GitLab Runner 16.6以降にアップグレードしてください。

### `Caller is not authorized to perform action on resource`メッセージ {#caller-is-not-authorized-to-perform-action-on-resource-message}

Azure Key Vaultからシークレットをフェッチすると、次のエラーが表示されることがあります:

```plaintext
RESPONSE 403: 403 Forbidden
ERROR CODE: Forbidden
Caller is not authorized to perform action on resource.\r\nIf role assignments, deny assignments or role definitions were changed recently, please observe propagation time.
ForbiddenByRbac
```

Azure Key Vaultがロールベースのアクセス制御を使用している場合は、Azure ADアプリケーションに**Key Vault Secrets User**ロール割り当てを追加する必要があります。

次に例を示します:

```shell
appId=$(az ad app list --display-name gitlab-oidc --query '[0].appId' -otsv)
az role assignment create --assignee $appId --role "Key Vault Secrets User" --scope /subscriptions/<subscription-id>
```

サブスクリプションIDは、以下にあります:

- [Azure Portal](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id#find-your-azure-subscription)。
- [Azureコマンドラインインターフェース](https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#get-the-active-subscription)。

### `The secrets provider can not be found. Check your CI/CD variables and try again.`メッセージ {#the-secrets-provider-can-not-be-found-check-your-cicd-variables-and-try-again-message}

Azure Key Vaultにアクセスするように構成されたジョブの開始を試みると、このエラーが表示されることがあります:

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

必要な変数の1つ以上が定義されていないため、ジョブを作成できません:

- `AZURE_KEY_VAULT_SERVER_URL`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
