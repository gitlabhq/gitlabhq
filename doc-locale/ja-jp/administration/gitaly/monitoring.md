---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitalyのモニタリング
---

Gitalyをモニタリングするには、利用可能なログと[Prometheusメトリクス](../monitoring/prometheus/_index.md)を使用します。

メトリクスの定義は以下で可能です:

- Gitaly用に設定されたPrometheus `/metrics`エンドポイントから直接。
- Prometheusに対して設定されたGrafanaインスタンスで[Grafana調査する](https://grafana.com/docs/grafana/latest/explore/)を使用。

Gitalyは、（アダプティブまたは非アダプティブ）リクエストの並行処理に基づいてリクエストを制限するように設定できます。

## Gitalyの並行処理制限をモニタリング {#monitor-gitaly-concurrency-limiting}

GitalyのログとPrometheusを使用して、[並行処理待ちリクエスト](concurrency_limiting.md#limit-rpc-concurrency)の特定の動作を観察できます。

[Gitalyログ](../logs/_index.md#gitaly-logs)では、次のようなエントリを使用して、pack-objectsの並行処理制限に関連するログを識別できます:

| ログフィールド | 説明 |
| --- | --- |
| `limit.concurrency_queue_length` | 進行中の呼び出しのRPCタイプに固有のキューの現在の長さを示します。これにより、並行処理制限のために処理を待機しているリクエストの数を把握できます。                                       |
| `limit.concurrency_queue_ms`     | リクエストが並行処理RPCの制限によりキューで待機している時間（ミリ秒単位）を表します。このフィールドは、リクエスト処理時間に対する並行処理制限の影響を理解するのに役立ちます。           |
| `limit.concurrency_dropped`      | リクエストが制限に達したためにドロップされた場合、このフィールドは理由を指定します。理由は、`max_time`（リクエストが許可された最大時間よりも長くキューで待機した）または`max_size`（キューが最大サイズに達した）のいずれかです。 |
| `limit.limiting_key`             | 制限に使用されるキーを識別します。  |
| `limit.limiting_type`            | 制限されている処理のタイプを指定します。このコンテキストでは、`per-rpc`であり、並行処理制限がRPCごとに適用されることを示します。                                                                            |

例: 

```json
{
  "limit .concurrency_queue_length": 1,
  "limit .concurrency_queue_ms": 0,
  "limit.limiting_key": "@hashed/79/02/7902699be42c8a8e46fbbb450172651786b22c56a189f7625a6da49081b2451.git",
  "limit.limiting_type": "per-rpc"
}
```

Prometheusで、次のメトリクスを探します:

- `gitaly_concurrency_limiting_in_progress`は、並行処理リクエストがいくつ処理されているかを示します。
- `gitaly_concurrency_limiting_queued`は、特定のリポジトリのRPCに対するリクエストが、並行処理制限に達したためにいくつ待機しているかを示します。
- `gitaly_concurrency_limiting_acquiring_seconds`は、リクエストが処理される前に並行処理制限のためにどれくらいの時間待機する必要があるかを示します。
- `gitaly_requests_dropped_total`は、リクエスト制限のためにドロップされたリクエストの合計数を提供します。`reason`ラベルは、リクエストがドロップされた理由を示します:
  - `max_size`。これは、並行処理キューサイズに達したためです。
  - `max_time`。これは、Gitalyで設定されているように、リクエストが最大キュー待機時間を超えたためです。

## Gitalyのpack-objects並行処理制限をモニタリング {#monitor-gitaly-pack-objects-concurrency-limiting}

GitalyログとPrometheusを使用して、[pack-objects制限](concurrency_limiting.md#limit-pack-objects-concurrency)の特定の動作を観察できます。

[Gitalyログ](../logs/_index.md#gitaly-logs)では、次のようなエントリを使用して、pack-objectsの並行処理制限に関連するログを識別できます:

| ログフィールド | 説明 |
|:---|:---|
| `limit.concurrency_queue_length` | pack-objects処理のキューの現在の長さ。これは、並行処理処理の制限に達したために、処理を待機しているリクエストの数を示します。 |
| `limit.concurrency_queue_ms` | リクエストがキューで待機した時間（ミリ秒単位）。これは、並行処理の制限のために、リクエストがどれくらいの時間待機する必要があったかを示します。 |
| `limit.limiting_key` | 送信元のリモートIP。 |
| `limit.limiting_type` | 制限されている処理のタイプ。この場合、`pack-objects`。 |

設定例: 

```json
{
  "limit .concurrency_queue_length": 1,
  "limit .concurrency_queue_ms": 0,
  "limit.limiting_key": "1.2.3.4",
  "limit.limiting_type": "pack-objects"
}
```

Prometheusで、次のメトリクスを探します:

- `gitaly_pack_objects_in_progress`は、いくつのpack-objects処理が並行処理で処理されているかを示します。
- `gitaly_pack_objects_queued`は、並行処理制限に達したために、いくつのpack-objects処理に対するリクエストが待機しているかを示します。
- `gitaly_pack_objects_acquiring_seconds`は、pack-object処理に対するリクエストが処理される前に並行処理制限のためにどれくらいの時間待機する必要があるかを示します。

## Gitalyのアダプティブ並行処理制限をモニタリング {#monitor-gitaly-adaptive-concurrency-limiting}

{{< history >}}

- GitLab 16.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/10734)されました。

{{< /history >}}

GitalyログとPrometheusを使用して、[アダプティブ並行処理制限](concurrency_limiting.md#adaptive-concurrency-limiting)の特定の動作を観察できます。

アダプティブ並行処理制限は静的な並行処理制限の拡張であるため、[静的な並行処理制限](#monitor-gitaly-concurrency-limiting)に適用可能なすべてのメトリクスとログは、アダプティブ制限をモニタリングする場合にも関連します。さらに、アダプティブ制限は、制限の動的な調整をモニタリングするのに役立ついくつかの特定のメトリクスを導入します。

### アダプティブ制限ログ {#adaptive-limiting-logs}

[Gitalyログ](../logs/_index.md#gitaly-logs)では、現在の制限が調整されたときに、アダプティブ並行処理制限に関連するログを識別できます。「Multiplicative decrease」メッセージと「Additive increase」メッセージについて、ログの内容（`msg`）をフィルタリングできます。

これらのデバッグログはデバッグ重大度レベルでのみ使用可能であり、詳細になる可能性がありますが、アダプティブ制限の調整に関する詳細なインサイトを提供します。

| ログフィールド | 説明 |
|:---|:---|
| `limit` | 調整されている制限の名前。 |
| `previous_limit` | 増加または減少する前の以前の制限。 |
| `new_limit` | 増加または減少した後の新しい制限。 |
| `watcher` | ノードに負荷がかかっていると判断したリソースウォッチャー。例: `CgroupCpu`または`CgroupMemory`。 |
| `reason` | 制限調整の背後にある理由。 |
| `stats.*` | 調整の決定の背後にあるいくつかの統計。これらはデバッグを目的としています。 |

ログの例:

```json
{
  "msg": "Multiplicative decrease",
  "limit": "pack-objects",
  "new_limit": 14,
  "previous_limit": 29,
  "reason": "cgroup CPU throttled too much",
  "watcher": "CgroupCpu",
  "stats.time_diff": 15.0,
  "stats.throttled_duration": 13.0,
  "stat.sthrottled_threshold": 0.5
}
```

### アダプティブ制限メトリクス {#adaptive-limiting-metrics}

Prometheusで、次のメトリクスを探します:

静的制限とアダプティブ制限の両方に適用可能な一般的な並行処理制限メトリクス:

- `gitaly_concurrency_limiting_in_progress` - 処理されているリクエストの数。
- `gitaly_concurrency_limiting_queued` - 並行処理制限のためにキューで待機しているリクエストの数。
- `gitaly_concurrency_limiting_acquiring_seconds` - 処理が開始される前に、並行処理制限のために待機しているリクエストによって費やされた時間。

アダプティブ並行処理制限固有のメトリクス:

- `gitaly_concurrency_limiting_current_limit` - 各RPCタイプのアダプティブ並行処理制限の現在の制限値を示すゲージ。このメトリクスには、アダプティブ制限のみが含まれています。
- `gitaly_concurrency_limiting_backoff_events_total` - リソースの負荷により制限が軽減される時期と理由を表す、バックオフイベントの総数を示すカウンター。
- `gitaly_concurrency_limiting_watcher_errors_total` - Gitalyがリソースデータを取得できなかった場合に発生するエラーを追跡するカウンター。これにより、Gitalyが現在のリソース状況を評価する能力に影響を与える可能性があります。

アダプティブ制限に関する問題を調査する場合は、これらのメトリクスを一般的な並行処理制限メトリクスおよびログと関連付けて、システム動作の全体像を把握します。

## Gitaly cgroupsをモニタリング {#monitor-gitaly-cgroups}

Prometheusを使用して、[コントロールグループ（cgroups）](configure_gitaly.md#control-groups)のステータスを観察できます:

- `gitaly_cgroups_reclaim_attempts_total`。これは、メモリー再利用が試行された合計回数を示すゲージです。この数値は、サーバーが再起動されるたびにリセットされます。
- `gitaly_cgroups_cpu_usage`。これは、cgroupごとのCPU使用率を測定するゲージです。
- `gitaly_cgroup_procs_total`。これは、Gitalyがcgroupの制御下で起動した処理の合計数を測定するゲージです。
- `gitaly_cgroup_cpu_cfs_periods_total`。[`nr_periods`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics)の値のカウンター。
- `gitaly_cgroup_cpu_cfs_throttled_periods_total`。[`nr_throttled`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics)の値のカウンター。
- `gitaly_cgroup_cpu_cfs_throttled_seconds_total`。秒単位の[`throttled_time`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics)の値のカウンター。

## `pack-objects`キャッシュ {#pack-objects-cache}

次の[`pack-objects`キャッシュ](configure_gitaly.md#pack-objects-cache)メトリクスが利用可能です:

- `gitaly_pack_objects_cache_enabled`。キャッシュが有効になっている場合は、`1`に設定されるゲージ。利用可能なラベル: `dir`と`max_age`。
- `gitaly_pack_objects_cache_lookups_total`。キャッシュルックアップのカウンター。利用可能なラベル: `result`。
- `gitaly_pack_objects_generated_bytes_total`。キャッシュに書き込まれたバイト数のカウンター。
- `gitaly_pack_objects_served_bytes_total`。キャッシュから読み取りられたバイト数のカウンター。
- `gitaly_streamcache_filestore_disk_usage_bytes`。キャッシュファイルの合計サイズのゲージ。利用可能なラベル: `dir`。
- `gitaly_streamcache_index_entries`。キャッシュ内のエントリ数のゲージ。利用可能なラベル: `dir`。

これらのメトリクスの一部は、Gitalyの`streamcache`内部ライブラリパッケージで生成されるため、`gitaly_streamcache`で始まります。

例: 

```plaintext
gitaly_pack_objects_cache_enabled{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache",max_age="300"} 1
gitaly_pack_objects_cache_lookups_total{result="hit"} 2
gitaly_pack_objects_cache_lookups_total{result="miss"} 1
gitaly_pack_objects_generated_bytes_total 2.618649e+07
gitaly_pack_objects_served_bytes_total 7.855947e+07
gitaly_streamcache_filestore_disk_usage_bytes{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 2.6200152e+07
gitaly_streamcache_filestore_removed_total{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 1
gitaly_streamcache_index_entries{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 1
```

## Gitalyサーバーサイドバックアップをモニタリング {#monitor-gitaly-server-side-backups}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/5358)されました。

{{< /history >}}

次のメトリクスを使用して[サーバー側のリポジトリバックアップ](configure_gitaly.md#configure-server-side-backups)をモニタリングします:

- `gitaly_backup_latency_seconds`。これは、サーバー側のバックアップの各フェーズにかかる時間（秒単位）を測定するヒストグラムです。さまざまな段階は`refs`、`bundle`、および`custom_hooks`であり、各ステージで処理されるデータのタイプを表します。
- `gitaly_backup_bundle_bytes`。これは、GitalyバックアップサービスによってオブジェクトストレージにプッシュされるGitバンドルのアップロードデータレートを測定するヒストグラムです。

これらのメトリクスは、GitLabインスタンスに大きなリポジトリが含まれている場合に特に役立ちます。

## クエリ {#queries}

以下は、Gitalyをモニタリングするためのいくつかのクエリです:

- 次のPrometheusクエリを使用して、Gitalyが本番環境に提供している[接続のタイプ](tls_support.md)を観察します:

  ```prometheus
  sum(rate(gitaly_connections_total[5m])) by (type)
  ```

- 次のPrometheusクエリを使用して、GitLab構成の[認証動作](tls_support.md#observe-type-of-gitaly-connections)をモニタリングします:

  ```prometheus
  sum(rate(gitaly_authentications_total[5m])) by (enforced, status)
  ```

  認証が正しく設定され、ライブトラフィックがあるシステムでは、次のように表示されます:

  ```prometheus
  {enforced="true",status="ok"}  4424.985419441742
  ```

  レート0の他の数値も存在する可能性がありますが、ゼロ以外の数値にのみ注意する必要があります。

  ゼロ以外の数値のみに`enforced="true",status="ok"`が必要です。他のゼロ以外の数値がある場合は、構成に問題があります。

  `status="ok"`の数値は、現在のリクエストレートを反映しています。前の例では、Gitalyは1秒あたり約4000リクエストを処理しています。

- 次のPrometheusクエリを使用して、本番環境で使用されている[Gitプロトコルバージョン](../git_protocol.md)を観察します:

  ```prometheus
  sum(rate(gitaly_git_protocol_requests_total[1m])) by (grpc_method,git_protocol,grpc_service)
  ```
