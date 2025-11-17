---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスター管理プロジェクトでVaultをインストール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[HashiCorp Vault](https://www.vaultproject.io/)は、パスワード、認証情報、証明書などを安全に管理および保存するために使用できるシークレット管理ソリューションです。Vaultをインストールすると、アプリケーション、GitLab CI/CDジョブなどで使用される認証情報の一元化された安全なデータストアを提供するために活用できます。また、SSL/TLS証明書をインフラストラクチャ内のシステムとデプロイに提供する方法としても役立ちます。これらのすべての認証情報に対して単一のソースとしてVaultを活用することで、機密性の高い認証情報と証明書に対するアクセス、制御、および可監査性の単一ソースを持つことで、セキュリティが向上します。この機能を使用するには、GitLabに最高レベルのアクセスと制御を許可する必要があります。したがって、GitLabが侵害された場合、このVaultインスタンスのセキュリティも同様に侵害されます。このセキュリティリスクを回避するために、GitLabでは、独自のHashiCorp Vaultを使用して、[外部シークレットとCI](../../../../../ci/secrets/_index.md)を活用することをお勧めします。

[管理プロジェクトテンプレート](../../../../clusters/management_project_template.md)から作成されたプロジェクトが既にあると仮定して、Vaultをインストールするには、`helmfile.yaml`から次の行のコメントを外します:

```yaml
  - path: applications/vault/helmfile.yaml
```

デフォルトでは、スケーラブルなストレージバックエンドがない基本的なVaultセットアップが提供されます。これは、簡単なテストや小規模のデプロイには十分ですが、スケールできる量に制限があり、単一のインスタンスデプロイであるため、Vaultアプリケーションをアップグレードするとダウンタイムが発生します。

本番環境でVaultを最適に使用するには、Vaultの内部構造と設定方法をよく理解しておくことが理想的です。これを行うには、[Vault設定ガイド](../../../../../ci/secrets/hashicorp_vault.md#configure-your-vault-server) 、[Vaultドキュメント](https://developer.hashicorp.com/vault/docs/internals) 、およびVault Helmチャートの[`values.yaml`ファイル](https://github.com/hashicorp/vault-helm/blob/v0.3.3/values.yaml)をお読みください。

少なくとも、ほとんどのユーザーは以下をセットアップします:

- メインキーをさらに暗号化するための[seal](https://developer.hashicorp.com/vault/docs/configuration/seal)。
- 環境およびストレージセキュリティ要件に適した[ストレージバックエンド](https://developer.hashicorp.com/vault/docs/configuration/storage)。
- [HAモード](https://developer.hashicorp.com/vault/docs/concepts/ha)。
- [Vault UI](https://developer.hashicorp.com/vault/docs/configuration/ui)。

次に、Google Cloud Storageバックエンドを使用して自動アンシール用にGoogleキーManagement Serviceを設定し、Vault UIを有効にし、3つのポッドレプリカでHAを有効にする値ファイルの例（`applications/vault/values.yaml`）を示します。以下の`storage`および`seal`スタンザは例であり、環境に固有の設定に置き換える必要があります。

```yaml
# Enable the Vault WebUI
ui:
  enabled: true
server:
  # Disable the built in data storage volume as it's not safe for High Availability mode
  dataStorage:
    enabled: false
  # Enable High Availability Mode
  ha:
    enabled: true
    # Configure Vault to listen on port 8200 for normal traffic and port 8201 for inter-cluster traffic
    config: |
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      # Configure Vault to store its data in a GCS Bucket backend
      storage "gcs" {
        path = "gcs://my-vault-storage/vault-bucket"
        ha_enabled = "true"
      }
      # Configure Vault to unseal storage using a GKMS key
      seal "gcpckms" {
         project     = "vault-helm-dev-246514"
         region      = "global"
         key_ring    = "vault-helm-unseal-kr"
         crypto_key  = "vault-helm-unseal-key"
      }
```

Vaultを正常にインストールしたら、[Vaultを初期化](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-deploy#initializing-the-vault)して、初期ルートトークンを取得する必要があります。これを行うには、VaultがデプロイされたKubernetesクラスターへのアクセスが必要です。Vaultを初期化するには、Kubernetes内で実行されているVaultポッドのいずれかのシェルを取得します（通常、これは`kubectl`コマンドラインツールを使用して行われます）。シェルをポッドに入れたら、`vault operator init`コマンドラインを実行します:

```shell
kubectl -n gitlab-managed-apps exec -it vault-0 sh
/ $ vault operator init
```

これにより、アンシールキーと初期ルートトークンが提供されます。これらを書き留めて安全に保管してください。これらは、ライフサイクル全体を通してVaultをアンシールするために必要です。
