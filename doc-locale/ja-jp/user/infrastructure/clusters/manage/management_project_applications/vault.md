---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: クラスター管理プロジェクトでVaultをインストール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[HashiCorp Vault](https://www.vaultproject.io/)は、パスワード、認証情報、証明書などを安全に管理および保存するために使用できるシークレット管理ソリューションです。Vaultをインストールすることで、アプリケーション、GitLab CI/CDのジョブなどで使用される認証情報に対して、単一の安全なデータストアを提供できます。また、インフラストラクチャ内のシステムやデプロイにSSL/TLS証明書を提供する手段としても利用できます。Vaultをこれらのすべての認証情報の単一ソースとして活用することで、すべての機密性の高い認証情報と証明書に関するアクセス、制御、および可監査性の単一ソースを持つことで、より高いセキュリティを実現できます。この機能を使用するには、GitLabに最高レベルのアクセスと制御を付与する必要があります。そのため、GitLabが侵害された場合、このVaultのインスタンスのセキュリティも同様に侵害されます。このセキュリティリスクを回避するため、GitLabは独自のHashiCorp Vaultを使用して[外部シークレットをCIで](../../../../../ci/secrets/_index.md)活用することをお勧めします。

すでに[管理プロジェクトテンプレート](../../../../clusters/management_project_template.md)から作成されたプロジェクトがある場合、Vaultをインストールするには、`helmfile.yaml`のこの行をアンコメントしてください:

```yaml
  - path: applications/vault/helmfile.yaml
```

デフォルトでは、スケール可能なストレージバックエンドなしの基本的なVaultセットアップが提供されます。これは単純なテストと小規模なデプロイには十分ですが、スケールする方法には制限があり、単一のインスタンスデプロイであるため、Vaultアプリケーションをアップグレードするとダウンタイムが発生します。

本番環境でVaultを最適に使用するには、Vaultの内部とそれを設定する方法を十分に理解していることが理想的です。これは、[Vaultの設定ガイド](../../../../../ci/secrets/hashicorp_vault.md#configure-your-vault-server)、[Vaultのドキュメント](https://developer.hashicorp.com/vault/docs/internals)、およびVaultHelmチャートの[`values.yaml`ファイル](https://github.com/hashicorp/vault-helm/blob/v0.3.3/values.yaml)を読むことで行えます。

最低限、ほとんどのユーザーは以下を設定します:

- メインキーの追加の暗号化のための[シール](https://developer.hashicorp.com/vault/docs/configuration/seal)。
- 環境とストレージのセキュリティ要件に適した[ストレージバックエンド](https://developer.hashicorp.com/vault/docs/configuration/storage)。
- [HAモード](https://developer.hashicorp.com/vault/docs/concepts/ha)。
- Vaultの[UI](https://developer.hashicorp.com/vault/docs/configuration/ui)。

以下は、自動アンシール用にGoogleキーManagement Serviceを構成し、Google Cloud Storageバックエンドを使用し、Vault UIを有効にし、3つのポッドレプリカでHAを有効にする値ファイルの例 (`applications/vault/values.yaml`) です。以下の`storage`および`seal`スタンザは例であり、環境に固有の設定に置き換える必要があります。

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

Vaultを正常にインストールした後、[Vaultを初期化](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-deploy#initializing-the-vault)し、初期のルートトークンを取得する必要があります。これを行うには、VaultがデプロイされているKubernetesクラスターへのアクセスが必要です。Vaultを初期化するには、Kubernetes内で実行されているVaultのいずれかのポッドにShellを取得します（通常、これは`kubectl`コマンドラインツールを使用して行われます）。ポッドにShellに入った後、`vault operator init`コマンドを実行します:

```shell
kubectl -n gitlab-managed-apps exec -it vault-0 sh
/ $ vault operator init
```

これにより、アンシールキーと初期ルートトークンが提供されます。これらはVaultのライフサイクル全体でアンシールするために必要となるため、必ずメモを取り、安全に保管してください。
