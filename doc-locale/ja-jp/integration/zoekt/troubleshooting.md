---
stage: Analytics
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Zoektのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 限定提供

{{< /details >}}

Zoektを使用する際に、以下の問題が発生する可能性があります。予備的なデバッグのため:

- Zoektインフラストラクチャの[ヘルスチェックを実行](_index.md#run-a-health-check)して、ステータスを把握します。
- [インデックス作成ステータスを確認](_index.md#check-indexing-status)するには、`gitlab-rake gitlab:zoekt:info` Rakeタスクを使用します。

## ネームスペースがインデックスされていません {#namespace-is-not-indexed}

[設定を有効にする](_index.md#index-root-namespaces-automatically)と、新しいネームスペースが自動的にインデックスされます。もしネームスペースが自動的にインデックスされない場合、Sidekiqログを検査してジョブが処理されているかを確認してください。`Search::Zoekt::SchedulingWorker`がネームスペースのインデックス作成を担当します。

[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)で、以下を確認できます:

- Zoektが有効になっていないネームスペース:

  ```ruby
  Namespace.group_namespaces.root_namespaces_without_zoekt_enabled_namespace
  ```

- Zoektインデックスのステータス:

  ```ruby
  Search::Zoekt::Index.all.pluck(:state, :namespace_id)
  ```

ネームスペースを手動でインデックスするには、[インデックス作成を設定](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/#configure-zoekt-in-gitlab)を参照してください。

## エラー: `SilentModeBlockedError` {#error-silentmodeblockederror}

`SilentModeBlockedError`は、完全一致コードの検索を実行しようとしたときに表示される可能性があります。この問題は、GitLabインスタンスで[Silent Mode](../../administration/silent_mode)が有効になっている場合に発生します。

この問題を解決するには、Silent Modeが無効になっていることを確認してください。

## エラー: `connections to all backends failing` {#error-connections-to-all-backends-failing}

`application_json.log`で、以下のエラーが表示されることがあります:

```plaintext
connections to all backends failing; last error: UNKNOWN: ipv4:1.2.3.4:5678: Trying to connect an http1.x server
```

この問題を解決するには、プロキシを使用しているかどうかを確認してください。使用している場合は、GitLabサーバーのIPアドレスを`no_proxy`に設定してください:

```ruby
gitlab_rails['env'] = {
  "http_proxy" => "http://proxy.domain.com:1234",
  "https_proxy" => "http://proxy.domain.com:1234",
  "no_proxy" => ".domain.com,IP_OF_GITLAB_INSTANCE,127.0.0.1,localhost"
}
```

`proxy.domain.com:1234`はプロキシインスタンスのドメインとポートです。`IP_OF_GITLAB_INSTANCE`はGitLabインスタンスのパブリックIPアドレスを指します。

`ip a`を実行して、以下のいずれかを確認することで、この情報を取得できます:

- 適切なネットワークインターフェースのIPアドレス
- 使用しているロードバランサーのパブリックIPアドレス

## メモリ不足エラー {#out-of-memory-errors}

Zoektノードは、検索またはインデックス作成中にメモリ不足になる可能性があります。メモリ不足（OOM）エラーは、Webサーバーで発生する可能性が高くなります。Webサーバーは、検索が提供される際にインデックスのシャードを物理メモリにメモリマップするため、常駐メモリはインデックスサイズとクエリ量とともに増加します。OOMエラーの症状と、必要なリカバリー手順は、2つのコンポーネント間で異なります。詳細については、[メモリアーキテクチャ](_index.md#memory-architecture)を参照してください。

### メモリ不足イベントの検出 {#detect-an-out-of-memory-event}

Kubernetesデプロイメントの場合、コンテナがOOMエラーにより強制終了されたかどうかを確認してください:

```shell
kubectl describe pod <your_pod_name> -n <your_namespace>
```

`Last State`セクションで`OOMKilled`を探し、ゼロ以外の`Exit Code`（通常は`137`）を確認します:

```plaintext
Last State: Terminated
  Reason: OOMKilled
  Exit Code: 137
```

すべてのZoektポッドの再起動数を確認することもできます:

```shell
kubectl get pods -n <your_namespace> -l app=gitlab-zoekt
```

高い`RESTARTS`数値のポッドは、繰り返しOOMキルが発生していることを示します。ラベルセレクター`app=gitlab-zoekt`は、チャートバージョンまたはオペレーター設定によって異なる場合があります。

もし[kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)がインストールされている場合、これらのメトリクスをPrometheusまたはGrafanaで監視することもできます:

- `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}`: OOMのため終了したポッド。
- `kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"}`: クラッシュループ状態のポッド。
- `kube_pod_container_status_restarts_total`: コンテナごとの累積再起動数。急激な増加は、繰り返しのクラッシュを示します。

Webサーバーは`process_resident_memory_bytes`をポート`6070`の`/metrics`で公開しています。PrometheusをWebサーバーポッドに直接スクレイプするように設定している場合、このメトリクスを使用してWebサーバーの常駐メモリ使用量を経時的に監視できます。

VMおよびベアメタルデプロイメントの場合、システムジャーナルでOOMイベントを確認してください:

```shell
sudo journalctl -k | grep -i "oom\|killed process"
```

### メモリ不足イベントからリカバリーする {#recover-from-an-out-of-memory-event}

リカバリー手順は、OOMエラーが発生しているコンポーネントによって異なります。

#### インデクサーのメモリ不足エラー {#indexer-out-of-memory-errors}

もしインデクサーがOOMエラーにより繰り返し強制終了される場合、調査中にすべてのノードで新しいインデックス作成作業をすべて停止するために、インデックス作成をグローバルに一時停止してください:

```shell
gitlab-rake gitlab:zoekt:pause_indexing
```

または、UIからインデックス作成を一時停止します:

前提条件: 

- 管理者アクセス権。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **検索**を選択します。
1. **完全一致コードの検索**を展開する。
1. **インデックス作成を一時停止**チェックボックスを選択します。
1. **変更を保存**を選択します。

ノードが安定したら、インデックス作成を再開します:

```shell
gitlab-rake gitlab:zoekt:resume_indexing
```

#### Webサーバーのメモリ不足エラー {#webserver-out-of-memory-errors}

もしWebサーバーがOOMエラーにより繰り返し強制終了される場合、調査中にZoekt検索を無効にしてください。これにより、クラッシュしているノードへの検索トラフィックが停止し、インデックス作成に影響を与えません。

> [!note]
> Zoekt検索が無効になっている場合、codeコード検索は基本検索モードにフォールバックします。もしElasticsearchが利用できない場合、基本検索モードではプロジェクトスコープのcodeコード検索のみが可能であり、Gitalyへの負荷が増加します。

前提条件: 

- 管理者アクセス権。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **検索**を選択します。
1. **完全一致コードの検索**を展開する。
1. **検索を有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

ノードが安定したら、検索を再度有効にします:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **検索**を選択します。
1. **完全一致コードの検索**を展開する。
1. **検索を有効にする**チェックボックスを選択します。
1. **変更を保存**を選択します。

### メモリ負荷を軽減する {#reduce-memory-pressure}

もしノードのサイズが正しく設定されていてもメモリ負荷が発生する場合は、以下の設定を調整してメモリ使用量を減らしてください。

#### 並列インデックス作成プロセスを減らす {#reduce-parallel-indexing-processes}

前提条件: 

- 管理者アクセス権。

ピークインデクサーメモリを減らすには、インデックス作成タスクあたりの並列プロセスの数を減らします:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **検索**を選択します。
1. **完全一致コードの検索**を展開する。
1. **インデックスタスクごとの並列プロセス数**を`1`に設定します。
1. **変更を保存**を選択します。

#### 同時実行インデックス作成タスクを減らす {#reduce-concurrent-indexing-tasks}

前提条件: 

- 管理者アクセス権。

同時に実行されるインデックス作成タスクの数を減らすには、**CPUをタスク乗算にインデックスする**の値を下げてください:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **検索**を選択します。
1. **完全一致コードの検索**を展開する。
1. **CPUをタスク乗算にインデックスする**の値を下げます（例えば、`0.5`）。
1. **変更を保存**を選択します。

#### 強制再インデックス作成の確率を上げる {#increase-force-reindexing-probability}

Zoekt Webサーバーはインデックスのシャードをメモリマップします。時間の経過とともに、増分インデックス作成により多くの小さなシャードが蓄積され、開いているmmapハンドルの数が増加します。強制再インデックス作成は、インデックスを完全に再構築し、シャードをより少ない大きなファイルに統合することで、メモリオーバーヘッドを削減します。

前提条件: 

- 管理者アクセス権。

シャードの蓄積を減らすには、強制再インデックス作成の確率を上げてください:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **検索**を選択します。
1. **完全一致コードの検索**を展開する。
1. **ランダム強制再インデックスの確率(パーセンテージ)** の値を増やします。デフォルトは`0.25`（0.25％）です。例えば、`1`に設定すると、約100件の増分インデックス作成タスクのうち1件で強制再インデックス作成が行われます。
1. **変更を保存**を選択します。

### ノードの適切なサイズ設定 {#right-size-the-node}

もし設定の調整で繰り返されるOOMイベントが解決しない場合、ノードにはより多くのメモリが必要です。インデックスサイズに基づいたメモリ割り当てのガイダンスについては、[サイズ設定の推奨事項](_index.md#sizing-recommendations)を参照してください。

Kubernetesデプロイメントの場合、Helmチャート`values.yaml`でメモリリクエストと制限を増やします。メモリ制限が、ディスクプランのサイズ設定表の値以上であることを確認してください。

VMおよびベアメタルデプロイメントの場合、サイズ設定表からより大きなインスタンスタイプに移動するか、追加のノードを追加して、より多くのマシンにインデックスを分散します。

サイズ変更後、ヘルスチェックを実行して、ノードがリカバリーすることを確認します:

```shell
gitlab-rake gitlab:zoekt:health
```

## Zoektノード接続の確認 {#verify-zoekt-node-connections}

Zoektノードが適切に設定され、接続されていることを確認するには、[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)で:

- 設定されたZoektノードの総数を確認します:

  ```ruby
  Search::Zoekt::Node.count
  ```

- オンラインのノード数を確認します:

  ```ruby
  Search::Zoekt::Node.online.count
  ```

または、`gitlab:zoekt:info` Rakeタスクを使用できます。

もしオンラインのノード数が設定されたノード数より少ない場合、またはノードが設定されているのにゼロである場合、GitLabとZoektノード間に接続の問題がある可能性があります。

## Zoekt接続エラーのデバッグ {#debug-zoekt-connection-errors}

Zoektとの接続の問題が発生した場合、リクエストフローを理解し、アーキテクチャ内の各コンポーネントを体系的に確認することが重要です。

### Zoektアーキテクチャ {#zoekt-architecture}

Zoektは、2つのモードで動作できる統合バイナリ（`gitlab-zoekt`）を使用します:

- Gitalyからリポジトリをインデックス作成するためのインデクサーモード
- 検索リクエストを処理するためのWebサーバーモード

基本的な検索フローは次のとおりです:

```plaintext
GitLab Rails → Zoekt webserver
```

Helmチャート（Kubernetes）デプロイメントの場合、アーキテクチャにはロードバランシングのための追加のゲートウェイコンポーネントが含まれます:

```plaintext
GitLab Rails → external gateway (NGINX) → internal gateway (NGINX) → Zoekt webserver
```

これらのゲートウェイコンポーネントはHelmチャートのデプロイメントの一部であり、Zoektの内部コンポーネントではありません。これらは、複数のZoekt Webサーバーインスタンス間でリクエストを分散し、ルーティング、ロードバランシング、およびオプションのTLS終端を処理するNGINXプロキシです。

Zoektアーキテクチャの設計の詳細については、[コード検索にZoektを使用する](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/code_search_with_zoekt/)を参照してください。

### ネットワーク到達性の確認 {#verify-network-reachability}

ZoektゲートウェイがGitLab Railsポッドから到達可能であることを確認するには、[ヘルスチェックを実行](_index.md#run-a-health-check)します:

```shell
gitlab-rake gitlab:zoekt:health
```

このタスクは、RailsからZoektへの接続を検証し、全体的なステータスを`HEALTHY`、`DEGRADED`、または`UNHEALTHY`としてレポートします。もしヘルスチェックが失敗した場合、GitLabとZoektインフラストラクチャ間にネットワーク接続の問題が存在する可能性があります。

ノードのステータスと設定を確認するには、以下のRakeタスクを実行します:

```shell
gitlab-rake gitlab:zoekt:info
```

URLを含む詳細なノード情報を表示するには、[Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)で以下のコマンドを実行します:

```ruby
# View all node attributes including URLs
Search::Zoekt::Node.all.map(&:attributes)
```

- `search_base_url`はZoekt Webサーバー、またはKubernetesの外部ゲートウェイ（例: `http://gitlab-zoekt:8080/`）を指している必要があります。
- `index_base_url`はZoektインデクサーを指している必要があります。

検索時に`404`レスポンスを受け取った場合、リクエストが適切にルーティングされていない可能性があります。このエラーは、問題がネットワーク接続ではなく、ゲートウェイ設定にある可能性が高いことを示しています。

### Zoektログの監視 {#monitor-zoekt-logs}

Helmチャート（Kubernetes）デプロイメントの場合、Zoektコンポーネントログを監視して接続の問題を特定します。

`StatefulSet`には3つのコンテナが含まれています:

```shell
# Monitor webserver logs (search requests from Rails)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-webserver -n <your_namespace>

# Monitor indexer logs (repository indexing)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-indexer -n <your_namespace>

# Monitor internal gateway logs (NGINX proxy between the external gateway and webserver)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-internal-gateway -n <your_namespace>
```

もし外部ゲートウェイデプロイメントを使用している場合、外部ゲートウェイログも監視できます:

```shell
# Monitor external gateway logs (NGINX proxy for incoming requests from Rails)
kubectl logs -f deployment/gitlab-zoekt-gateway -c zoekt-external-gateway -n <your_namespace>
```

これらのログを監視しながら、GitLab UIからテスト検索を実行します。ログには、リクエストが処理されていることが表示されるはずです。もしリクエストがログに表示されない場合、RailsとZoekt間にネットワークルーティングの問題が存在する可能性があります。

### UIからテスト検索を実行する {#run-test-searches-from-the-ui}

Zoektログを監視しながら、GitLab UIからテスト検索を実行できます:

- 特定のノードのプロジェクトを検索します。
- グループ内で検索して、複数のノードをクエリする。
- グローバルに検索して、すべてのノードをクエリする。

もし検索が失敗した場合は、Railsアプリケーションログで詳細なエラーメッセージを確認してください:

```shell
# For installations that use the Linux package
tail -f /var/log/gitlab/gitlab-rails/application_json.log | grep -i zoekt

# For self-compiled installations
tail -f log/application_json.log | grep -i zoekt
```

接続エラー、タイムアウト、または認証の失敗を探して、GitLabとZoektインフラストラクチャ間のネットワークの問題を示す可能性があります。

### ポッドとサービスのステータスを確認する {#verify-pod-and-service-status}

Helmチャート（Kubernetes）デプロイメントの場合、Zoektポッドとサービスのステータスを確認してください:

```shell
# Check pod status
kubectl get pods -n <your_namespace> -l app=gitlab-zoekt

# Check `StatefulSet` status
kubectl get statefulset gitlab-zoekt -n <your_namespace>

# Check service endpoints
kubectl get endpoints gitlab-zoekt -n <your_namespace>

# Describe the service to see the configuration
kubectl describe service gitlab-zoekt -n <your_namespace>
```

すべてのポッドが実行状態であり、サービスに有効なエンドポイントがあることを確認してください。もしポッドが実行されていない、またはエンドポイントが見つからない場合、Zoektデプロイメントに設定の問題がある可能性があります。

デプロイメントアーキテクチャの詳細については、以下を参照してください:

- [外部ゲートウェイデプロイメント設定](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/main/templates/deployment.yaml)
- [`StatefulSet`設定（インデクサー、Webサーバー、および内部ゲートウェイ）](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/main/templates/stateful_sets.yaml)

## エラー: `TaskRequest responded with [401]` {#error-taskrequest-responded-with-401}

Zoektインデクサーログに、`TaskRequest responded with [401]`が表示される場合があります。このエラーは、ZoektインデクサーがGitLabへの認証に失敗していることを示しています。

この問題を解決するには、`gitlab-shell-secret`が適切に設定され、GitLabインスタンスとZoektインデクサー間で一致していることを確認してください。例えば、以下のコマンドの出力は、`gitlab.rb`内の`gitlab-shell-secret`と一致する必要があります:

```shell
kubectl get secret gitlab-shell-secret -o jsonpath='{.data.secret}' -n your_zoekt_namespace | base64 -d
```

## エラー: `missing selected ALPN property` {#error-missing-selected-alpn-property}

Zoektゲートウェイの前に外部ロードバランサーを使用すると、GitLabログに以下のエラーが表示されることがあります:

```plaintext
rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: credentials: cannot check peer: missing selected ALPN property"
```

このエラーは、ロードバランサーがHTTP/2でALPN（Application-Layer Protocol Negotiation）をサポートまたはアドバタイズしない場合に発生します。Zoektはノード間の通信にgRPCを利用しており、これにはHTTP/2のサポートが必要です。

この問題を解決するには、次のいずれかを実行します。

- ロードバランサーでHTTP/2サポートを有効にする（推奨）:

  1. ロードバランサーを設定して、ALPNを介したHTTP/2をサポートおよびアドバタイズするようにしてください:
     - HAProxyの場合、バックエンドで`alpn h2,http/1.1`が設定されていることを確認してください。
     - NGINXの場合、サーバーブロックで以下を使用します:
       - NGINX 1.25.1以降では、`http2 on;`。
       - NGINX 1.25.0以前では、`listen 443 ssl http2;`。
  1. HTTP/2サポートを確認します:

     ```shell
     curl --verbose --http2 "https://your-zoekt-gateway-url/health" 2>&1 | grep ALPN
     ```

     以下のような出力が表示されるはずです:

     ```plaintext
     * ALPN, server accepted to use h2
     ```

- TLSパススルーを使用する:

  もしロードバランサーがHTTP/2をサポートできない場合、ロードバランサーをTLSパススルー用に設定します。ZoektゲートウェイはTLS終端を直接処理できるようになり、適切なALPNネゴシエーションが保証されます。TLSパススルーを使用するには、Zoektゲートウェイで有効なTLS証明書を設定します:

  1. Helmチャートデプロイメントの場合、`values.yaml`で証明書を設定します:

     ```yaml
     gateway:
       tls:
         certificate:
           enabled: true
           secretName: zoekt-gateway-cert
     ```

  1. ロードバランサーを設定して、TLSを終端せずに暗号化されたトラフィックをパススルーするようにしてください。
