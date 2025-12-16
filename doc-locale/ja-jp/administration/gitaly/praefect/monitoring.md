---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitaly Cluster (Praefect)のモニタリング
---

Gitaly Cluster (Praefect)をモニタリングするには、Prometheusのメトリクスを使用できます。2つの別々のメトリクスエンドポイントからメトリクスをスクレイプできます:

- デフォルトの`/metrics`エンドポイント。
- `/db_metrics`。データベースクエリを必要とするメトリクスが含まれています。

## デフォルトのPrometheus `/metrics`エンドポイント {#default-prometheus-metrics-endpoint}

次のメトリクスが`/metrics`エンドポイントから利用可能です:

- `gitaly_praefect_read_distribution`。[読み取りの分散](_index.md#distributed-reads)を追跡するカウンター。これには2つのラベルがあります:

  - `virtual_storage`。
  - `storage`。

  これらは、このインスタンスのPraefectに定義された設定を反映しています。

- `gitaly_praefect_replication_latency_bucket`。レプリケーションジョブの開始後、レプリケーションが完了するまでの時間を測定するヒストグラム。
- `gitaly_praefect_replication_delay_bucket`。レプリケーションジョブの作成から開始までの経過時間を測定するヒストグラム。
- `gitaly_praefect_connections_total`。Praefectへの接続の合計数。
- `gitaly_praefect_method_types`。ノードごとのアクセサーおよびmutator RPCの数。

[ストロング・コンシステンシー](_index.md#strong-consistency)をモニタリングするには、次のPrometheusのメトリクスを使用できます:

- `gitaly_praefect_transactions_total`。作成および投票されたトランザクションの数。
- `gitaly_praefect_subtransactions_per_transaction_total`。単一のトランザクションに対してノードが投票する回数。これは、単一のトランザクションで複数の参照が更新される場合に複数回発生する可能性があります。
- `gitaly_praefect_voters_per_transaction_total`。トランザクションに参加しているGitalyノードの数。
- `gitaly_praefect_transactions_delay_seconds`。トランザクションがコミットされるのを待つことによって発生するサーバー側の遅延。
- `gitaly_hook_transaction_voting_delay_seconds`。トランザクションがコミットされるのを待つことによって発生するクライアント側の遅延。

[リポジトリ検証](configure.md#repository-verification)をモニタリングするには、次のPrometheusのメトリクスを使用します:

- `gitaly_praefect_verification_jobs_dequeued_total`。ワーカーによって選択された検証ジョブの数。
- `gitaly_praefect_verification_jobs_completed_total`。ワーカーによって完了した検証ジョブの数。`result`ラベルは、ジョブの最終結果を示します:
  - `valid`は、予期されるレプリカがストレージに存在していたことを示します。
  - `invalid`は、存在するはずのレプリカがストレージに存在しなかったことを示します。
  - `error`は、ジョブが失敗し、再試行する必要があることを示します。
- `gitaly_praefect_stale_verification_leases_released_total`。解放された古い検証リースの数。

[Praefectログ](../../logs/_index.md#praefect-logs)もモニタリングできます。

## データベースのメトリクス`/db_metrics`エンドポイント {#database-metrics-db_metrics-endpoint}

次のメトリクスが`/db_metrics`エンドポイントから利用可能です:

- `gitaly_praefect_unavailable_repositories`。正常で最新のレプリカがないリポジトリの数。
- `gitaly_praefect_replication_queue_depth`。レプリケーションキュー内のジョブの数。
- `gitaly_praefect_verification_queue_depth`。検証保留中のレプリカの総数。
