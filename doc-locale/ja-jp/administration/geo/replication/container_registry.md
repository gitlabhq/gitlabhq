---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セカンダリサイトのコンテナレジストリ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

**セカンダリ** Geoサイトでコンテナレジストリをセットアップして、**プライマリ** Geoサイト上のコンテナレジストリをミラーリングできます。このコンテナレジストリのレプリケーションは、ディザスターリカバリーのみを目的として使用されます。

**セカンダリ** Geoサイトのコンテナレジストリにはプッシュしないでください。データが**プライマリ**サイトにレプリケートされないためです。

**セカンダリ**サイトからコンテナレジストリデータをプルすることはお勧めしません。データが古くなっている可能性があるためです。この問題は、[イシュー365864](https://gitlab.com/gitlab-org/gitlab/-/issues/365864)で解決される可能性があります。関心を示すために、イシューに同意することをお勧めします。

## サポートされているコンテナレジストリ {#supported-container-registries}

Geoは、次のタイプのコンテナレジストリをサポートしています:

- [Docker](https://distribution.github.io/distribution/)
- [OCI](https://github.com/opencontainers/distribution-spec/blob/main/spec.md)

## サポートされているイメージ形式 {#supported-image-formats}

Geoでは、次のコンテナイメージ形式がサポートされています:

- [Docker V2, スキーマ1](https://distribution.github.io/distribution/spec/deprecated-schema-v1/)
- [Docker V2, スキーマ2](https://distribution.github.io/distribution/spec/manifest-v2-2/)
- [OCI](https://github.com/opencontainers/image-spec)（OpenコンテナInitiative）

また、Geoは[BuildKitキャッシュイメージ](https://github.com/moby/buildkit)もサポートしています。

## サポートされているストレージ {#supported-storage}

### Docker {#docker}

サポートされているレジストリストレージドライバーの詳細については、[Dockerレジストリストレージドライバー](https://distribution.github.io/distribution/storage-drivers/)を参照してください

レジストリのデプロイ時に[ロードバランシングに関する考慮事項](https://distribution.github.io/distribution/about/deploying/#load-balancing-considerations)を読み取り、GitLabに統合された[container registry](../../packages/container_registry.md#use-object-storage)のストレージドライバーを設定する方法を読み取ります。

### OCIアーティファクトをサポートするレジストリ {#registries-that-support-oci-artifacts}

次のレジストリは、OCIアーティファクトをサポートしています:

- CNCF Distribution - ローカル/オフライン検証
- Azureコンテナレジストリ（ACR）
- Amazon Elasticコンテナリポジトリ（ECR）
- Googleアーティファクトレジストリ（GAR）
- GitHub Packagesコンテナレジストリ（GHCR）
- Bundle Bar

詳細については、[OCI Distribution仕様](https://github.com/opencontainers/distribution-spec)を参照してください。

## コンテナレジストリのレプリケーションを設定する {#configure-container-registry-replication}

ストレージ非依存のレプリケーションを有効にして、クラウドまたはローカルストレージに使用できるようにします。新しいイメージが**プライマリ**サイトにプッシュされるたびに、各**セカンダリ**サイトはそれを独自のコンテナリポジトリにプルします。

コンテナレジストリのレプリケーションを設定するには、次の手順を実行します:

1. [**プライマリ**サイト](#configure-primary-site)を設定します。
1. [**セカンダリ**サイト](#configure-secondary-site)を設定します。
1. コンテナレジストリの[レプリケーション](#verify-replication)を検証します。

### プライマリサイトを設定する {#configure-primary-site}

次の手順を実行する前に、コンテナレジストリが**プライマリ**サイトでセットアップされ、動作していることを確認してください。

新しいコンテナイメージをレプリケートできるようにするには、コンテナレジストリがすべてのプッシュに対して**プライマリ**サイトに通知イベントを送信する必要があります。コンテナレジストリと**プライマリ**上のWebノードの間で共有されるトークンは、通信をより安全にするために使用されます。

1. GitLabの**プライマリ**サーバーにSSHで接続し、rootとしてサインインします（GitLab HAの場合、レジストリノードのみが必要です）:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # Configure the registry to listen on the public/internal interface
   # Replace with the appropriate interface (for example, '0.0.0.0' for all interfaces)
   registry['registry_http_addr'] = '0.0.0.0:5000'
   registry['notifications'] = [
     {
       'name' => 'geo_event',
       'url' => 'https://<example.com>/api/v4/container_registry_event/events',
       'timeout' => '500ms',
       'threshold' => 5,
       'backoff' => '1s',
       'headers' => {
         'Authorization' => ['<replace_with_a_secret_token>']
       }
     }
   ]
   ```

   {{< alert type="note" >}}

   `<example.com>`をプライマリサイトの`/etc/gitlab/gitlab.rb`ファイルで定義されている`external_url`に置き換え、`<replace_with_a_secret_token>`を文字で始まる大文字と小文字を区別する英数字文字列に置き換えます。`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c 32 | sed "s/^[0-9]*//"; echo`を使用して、この英数字文字列を生成できます

   {{< /alert >}}

   {{< alert type="note" >}}

   外部レジストリ（GitLabと統合されていないもの）を使用する場合は、`/etc/gitlab/gitlab.rb`ファイルで通知シークレット（`registry['notification_secret']`）のみを指定する必要があります。

   {{< /alert >}}

1. GitLab HAのみ。すべてのWebノードで`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   registry['notification_secret'] = '<replace_with_a_secret_token_generated_above>'
   ```

1. 更新した各ノードを再構成します:

   ```shell
   gitlab-ctl reconfigure
   ```

### セカンダリサイトを設定する {#configure-secondary-site}

次の手順を実行する前に、コンテナレジストリが**セカンダリ**サイトでセットアップされ、動作していることを確認してください。

次の手順は、コンテナイメージがレプリケートされることを期待する各**セカンダリ**サイトで実行する必要があります。

**セカンダリ**サイトが**プライマリ**サイトのコンテナレジストリと安全に通信できるようにする必要があるため、すべてのサイトに単一のキーペアが必要です。**セカンダリ**サイトは、このキーを使用して、**プライマリ**サイトのコンテナレジストリにアクセスするためのプル専用の短寿命のJSON Webトークンを生成します。

**セカンダリ**サイトの各アプリケーションおよびSidekiqノードの場合:

1. ノードにSSHで接続し、`root`ユーザーとしてサインインします:

   ```shell
   sudo -i
   ```

1. **プライマリ**からノードに`/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key`をコピーします。

1. `/etc/gitlab/gitlab.rb`を編集して、以下を追加します:

   ```ruby
   gitlab_rails['geo_registry_replication_enabled'] = true

   # Primary registry's hostname and port, it will be used by
   # the secondary node to directly communicate to primary registry
   gitlab_rails['geo_registry_replication_primary_api_url'] = 'https://primary.example.com:5050/'
   ```

1. 変更を有効にするには、ノードを再構成します:

   ```shell
   gitlab-ctl reconfigure
   ```

### レプリケーションを検証する {#verify-replication}

コンテナレジストリのレプリケーションが機能していることを確認するには、**セカンダリ**サイトで次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**Geo** > **ノード**を選択します。初期レプリケーション、または「バックフィル」は、おそらくまだ進行中です。

ブラウザで、**プライマリ**サイトの**Geo Nodes**（Geoノード）ダッシュボードから、各Geoサイトの同期プロセスをモニタリングできます。

## トラブルシューティング {#troubleshooting}

### コンテナレジストリのレプリケーションが有効になっていることを確認する {#confirm-that-container-registry-replication-is-enabled}

これは、[Railsコンソール](../../operations/rails_console.md#starting-a-rails-console-session)を使用して確認できます:

```ruby
Geo::ContainerRepositoryRegistry.replication_enabled?
```

### コンテナレジストリの通知イベントが見つからない {#missing-container-registry-notification-event}

1. イメージがプライマリサイトのコンテナレジストリにプッシュされると、[コンテナリポジトリの通知](../../packages/container_registry.md#configure-container-registry-notifications)がトリガーされます
1. プライマリサイトのコンテナレジストリは、`https://<example.com>/api/v4/container_registry_event/events`でプライマリサイトのAPIを呼び出します
1. プライマリサイトは、`replicable_name: 'container_repository', model_record_id: <ID of the container repository>`を使用して、`geo_events`テーブルにレコードを挿入します。
1. レコードは、PostgreSQLによってセカンダリサイトのデータベースにレプリケートされます。
1. Geoログカーソルサービスは、新しいイベントを処理し、Sidekiqジョブ`Geo::EventWorker`をエンキューします

これが正しく機能していることを確認するには、イメージをプライマリサイトのレジストリにプッシュし、次のコマンドをRailsコンソールで実行して、通知が受信され、イベントに処理されたことを確認します:

```ruby
Geo::Event.where(replicable_name: 'container_repository')
```

`Geo::ContainerRepositorySyncService`からのエントリについて`geo.log`を確認することで、これをさらに検証できます。

### レジストリイベントログの応答ステータス401未承認は許可されていません {#registry-events-logs-response-status-401-unauthorized-unaccepted}

`401 Unauthorized`エラーは、プライマリサイトのコンテナレジストリの通知がRailsアプリケーションによって承認されず、何かがプッシュされたことをGitLabに通知できないことを示します。

これを修正するには、レジストリの通知とともに送信される認可ヘッダーが、手順[プライマリサイトを設定する](#configure-primary-site)で実行する必要があるように、プライマリサイトで設定されているものと一致していることを確認します。

#### レジストリエラー：`token from untrusted issuer: "<token>"` {#registry-error-token-from-untrusted-issuer-token}

Geoでコンテナイメージをレプリケートすると、`token from untrusted issuer: "<token>"`というエラーが表示される場合があります。

この問題は、コンテナレジストリの設定が正しくない場合に発生し、SidekiqのJSON Webトークン認証が失敗します。

この問題を解決するには、以下を実行します:

1. [セカンダリサイトの設定する](#configure-secondary-site)で説明されているように、両方のサイトが単一の署名キーペアを共有していることを確認します。
1. 両方のコンテナレジストリとプライマリサイトとセカンダリサイトの両方が、同じトークン発行者を使用するように設定されていることを確認します。詳細については、[GitLabとレジストリを個別のノードに設定する](../../packages/container_registry.md#configure-gitlab-and-registry-on-separate-nodes-linux-package-installations)を参照してください。
1. マルチノードデプロイでは、Sidekiqノードで設定された発行者が、レジストリで設定された値と一致することを確認します。

### コンテナレジストリの同期イベントをトラブルシューティングする {#manually-trigger-a-container-registry-sync-event}

トラブルシューティングを支援するために、コンテナレジストリのレプリケーションプロセスを手動でトリガーできます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. **Secondary Site**（セカンダリサイト）の**レプリケーションの詳細**で、**コンテナリポジトリ**を選択します。
1. 1つの行に対して**再同期**を選択するか、**すべて再同期**を選択します。

次のコマンドをセカンダリのRailsコンソールで実行して、再同期を手動でトリガーすることもできます:

```ruby
registry = Geo::ContainerRepositoryRegistry.first # Choose a Geo registry entry
registry.replicator.sync # Resync the container repository
pp registry.reload # Look at replication state fields

#<Geo::ContainerRepositoryRegistry:0x00007f54c2a36060
 id: 1,
 container_repository_id: 1,
 state: "2",
 retry_count: 0,
 last_sync_failure: nil,
 retry_at: nil,
 last_synced_at: Thu, 28 Sep 2023 19:38:05.823680000 UTC +00:00,
 created_at: Mon, 11 Sep 2023 15:38:06.262490000 UTC +00:00>
```

`state`フィールドは、同期状態を表します:

- `"0"`：同期保留中（通常、同期されていないことを意味します）
- `"1"`：同期が開始されました（同期ジョブが現在実行中です）
- `"2"`：正常に同期されました
- `"3"`：同期に失敗しました
