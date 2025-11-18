---
stage: Runtime
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: セル
description: セルの機能をテストします。
---

{{< details >}}

- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

{{< alert type="note" >}}

この機能は、GitLab.comの管理者のみが使用できます。この機能は、GitLabセルフマネージドまたはGitLab Dedicatedインスタンスでは使用できません。

{{< /alert >}}

{{< alert type="disclaimer" />}}

{{< alert type="note" >}}

Cells 1.0は開発中です。セル開発の状況の詳細については、[エピック12383](https://gitlab.com/groups/gitlab-org/-/epics/12383)を参照してください。

{{< /alert >}}

セルの機能をテストするには、GitLab Railsコンソールを設定します。

## 設定 {#configuration}

GitLabインスタンスをCellインスタンスとして構成するには:

{{< tabs >}}

{{< tab title="自己コンパイル（ソース）" >}}

`config/gitlab.yml`のセル関連の設定は、次の形式です:

```yaml
  cell:
    enabled: true
    id: 1
    database:
      skip_sequence_alteration: false
    topology_service_client:
      address: topology-service.gitlab.example.com:443
      ca_file: /home/git/gitlab/config/topology-service-ca.pem
      certificate_file: /home/git/gitlab/config/topology-service-cert.pem
      private_key_file: /home/git/gitlab/config/topology-service-key.pem
```

{{< /tab >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_rails['cell'] = {
     enabled: true,
     id: 1,
     database: {
       skip_sequence_alteration: false
     },
     topology_service_client: {
       enabled: true,
       address: 'topology-service.gitlab.example.com:443',
       ca_file: 'path/to/your/ca/.pem',
       certificate_file: 'path/to/your/cert/.pem',
       private_key_file: 'path/to/your/key/.pem'
     }
   }
   ```

1. GitLabを再設定して再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Helm Chart" >}}

1. `gitlab_values.yaml`を編集します:

   ```yaml
   global:
     appConfig:
       cell:
         enabled: true
         id: 1
         database:
           skipSequenceAlteration: false
         topologyServiceClient:
           address: "topology-service.gitlab.example.com:443"
           tls:
             enabled: true
   ```

1. ファイルを保存して、新しい値を適用します:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

| 設定                                   | デフォルト値                                         | 説明                                                                                                                                                                                                                                                                                                                    |
|-------------------------------------------------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `cell.enabled`                                  | `false`                                               | インスタンスがセルかどうかを構成するかどうか。`false`は、すべてのセル機能が無効になっていることを意味します。`session_cookie_prefix_token`は影響を受けず、個別に設定できます。                                                                                                                                                    |
| `cell.id`                                       | `nil`                                                 | `cell.enabled`が`true`の場合、正の整数である必要があります。それ以外の場合は、`nil`である必要があります。これは、クラスタリング内のセルの一意の整数IDです。このIDは、ルーティング可能なトークン内で使用されます。`cell.id`が`nil`の場合、`organization_id`のようなルーティング可能なトークン内の他の属性は引き続き使用されます |
| `cell.database.skip_sequence_alteration`        | `false`                                               | `true`の場合、セルのデータベースシーケンス改変をスキップします。モノリスセルが使用可能になる前に、レガシーセル（`cell-1`）に対して有効にします。このエピックで追跡されています: [フェーズ6: モノリスセル](https://gitlab.com/groups/gitlab-org/-/epics/14513)。                                                                   |
| `cell.topology_service_client.address`          | `"topology-service.gitlab.example.com:443"`           | `cell.enabled`が`true`の場合に必要です。トポロジサービスサーバーのアドレスとポート。                                                                                                                                                                                                                                       |
| `cell.topology_service_client.tls.enabled`      | `true`                                                | `true`の場合、トポロジサービスとの通信にmTLSを有効にします。これには、`cell.topology_service_client.tls.secret`が適切に設定されている必要があります。`false`に設定すると、TLS暗号化なしで接続が確立されます。                                                                                           |
| `cell.topology_service_client.tls.secret`       | `nil`                                                 | mTLS認証情報を含む[Kubernetes TLSシークレット](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_secret_tls/)名。TLSが有効な場合に必要です。シークレットには、`tls.crt`と`tls.key`キーを含める必要があります。明示的に設定されていない場合は、`<release.name>-topology-tls`にデフォルト設定されます。このシークレットは**手動で作成する必要があります**。Helm Chartは自動的に作成しません。                |

## 関連する設定 {#related-configuration}

セルアーキテクチャの他のコンポーネントを構成する方法については、以下を参照してください:

1. [トポロジサービスの設定](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/main/docs/config.md?ref_type=heads)
1. [HTTPルーターの設定](https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/docs/config.md?ref_type=heads)
