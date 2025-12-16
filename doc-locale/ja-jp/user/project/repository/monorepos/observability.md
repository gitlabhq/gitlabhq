---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: モノレポのパフォーマンスを測定するためのメトリクス
---

ご使用のモノレポのサーバー側のパフォーマンスを測定するには、これらのメトリクスを使用します。これらはGitalyのパフォーマンスを測定するための一般的なメトリクスですが、大規模なリポジトリに特に関連します。

クローンとフェッチは、最も頻繁に行われる負荷の高い操作です。システムリソースの消費量に対する割合として見ると、これらの操作はGitalyノード上のシステムリソースの90%以上にコントリビュートすることがよくあります。ログとメトリクスは、リポジトリのヘルス状態の手がかりとなります。

## CPUとメモリ {#cpu-and-memory}

2つの主要なRPCs（リモートプロシージャコール）が、クローンとフェッチを処理します。これらのフィールドをGitalyログで使用して、リポジトリのクローンとフェッチがシステムリソースをどれだけ消費しているかを確認します。これらのフィールドでGitalyログをフィルタリングすると、詳細を確認できます:

| ログフィールド                         | フィルタリングする値                                                                          | 説明 |
|:----------------------------------|:---------------------------------------------------------------------------------------------|:------------|
| `json.grpc.method`                | `PostReceivePack`                                                                            | HTTPクローンとフェッチを処理するRPCs。 |
| `json.grpc.method`                | `SSHReceivePack`                                                                             | SSHクローンとフェッチを処理するRPCs。 |
| `json.grpc.code`                  | `OK`                                                                                         | RPCsがリクエストを正常に処理したかどうか。 |
| `json.grpc.code`                  | `Canceled`                                                                                   | クライアントが接続を強制終了した場合に表示されることがあります。多くの場合、タイムアウトが原因です。 |
| `json.grpc.code`                  | `ResourceExhausted`                                                                          | マシンがGitプロセスを同時に多数起動しているかどうかを示します。 |
| `json.user_id`                    | クローンまたはフェッチを開始する`user_id`。`user-<user_id>`の形式（例：`user-22345`） | 単一のユーザー名によって起動された過剰なクローンまたはフェッチ操作を検索します。 |
| `json.username`                   | クローンまたはフェッチを開始したユーザー名。                                               | 単一のユーザー名によって起動された過剰なクローンまたはフェッチ操作を検索します。 |
| `json.grpc.request.glRepository`  | `project-<project_id>`の形式のリポジトリ（例：`project-214`）                      | 単一のリポジトリのクローンとフェッチの合計を検索します。 |
| `json.grpc.request.glProjectPath` | `my-org/coolproject`のような、プロジェクトパス形式のリポジトリ                       | 特定のリポジトリのクローンとフェッチの合計を検索します。 |

これらのログエントリフィールドは、CPUとメモリに関する情報を提供します:

| 確認するログフィールド       | 説明 |
|:---------------------------|:------------|
| `json.command.cpu_time_ms` | このRPCsから起動されたサブプロセスで使用されるCPU時間。 |
| `json.command.maxrss`      | このRPCsから起動されたサブプロセスのメモリ消費量。 |

この例では、ログメッセージ`json.command.cpu_time_ms`は`420`、`json.command.maxrss`は`3342152`でした:

```json
{
    "command.count":2,
    "command.cpu_time_ms":420,
    "command.inblock":0,
    "command.majflt":0,
    "command.maxrss":3342152,
    "command.minflt":24316,
    "command.oublock":56,
    "command.real_time_ms":626,
    "command.spawn_token_fork_ms":4,
    "command.spawn_token_wait_ms":0,
    "command.system_time_ms":172,
    "command.user_time_ms":248,
    "component":"gitaly.StreamServerInterceptor",
    "correlation_id":"20HCB3DAEPLV08UGNIYT9HJ4JW",
    "environment":"gprd",
    "feature_flags":"",
    "fqdn":"file-99-stor-gprd.c.gitlab-production.internal",
    "grpc.code":"OK",
    "grpc.meta.auth_version":"v2",
    "grpc.meta.client_name":"gitlab-workhorse",
    "grpc.meta.deadline_type":"none",
    "grpc.meta.method_operation":"mutator",
    "grpc.meta.method_scope":"repository",
    "grpc.meta.method_type":"bidi_stream",
    "grpc.method":"PostReceivePack",
    "grpc.request.fullMethod":"/gitaly.SmartHTTPService/PostReceivePack",
    "grpc.request.glProjectPath":"r2414/revenir/development/machinelearning/protein-ddg",
    "grpc.request.glRepository":"project-47506374",
    "grpc.request.payload_bytes":911,
    "grpc.request.repoPath":"@hashed/db/ab/dbabf83f57affedc9a001dc6c6f6b47bb431bd47d7254edd1daf24f0c38793a9.git",
    "grpc.request.repoStorage":"nfs-file99",
    "grpc.response.payload_bytes":54,
    "grpc.service":"gitaly.SmartHTTPService",
    "grpc.start_time":"2023-10-16T20:40:08.836",
    "grpc.time_ms":631.486,
    "hostname":"file-99-stor-gprd",
    "level":"info",
    "msg":"finished streaming call with code OK",
    "pid":1741362,
    "remote_ip":"108.163.136.48",
    "shard":"default",
    "span.kind":"server",
    "stage":"main",
    "system":"grpc",
    "tag":"gitaly",
    "tier":"stor",
    "time":"2023-10-16T20:40:09.467Z",
    "trace.traceid":"AAB3QAeD8G+H9VNmzOi2CztMAcJv1+g4+l1cAgA=",
    "type":"gitaly",
    "user_id":"user-14857500",
    "username":"ctx_ckottke",
  }
```

## 読み取りの分散 {#read-distribution}

各Gitalyノードへの読み取りの数を確認するには、`gitaly_praefect_read_distribution`を確認してください。このPrometheusのメトリクスは[カウンター](https://prometheus.io/docs/concepts/metric_types/#counter)であり、2つのベクターがあります:

| メトリクス名                         | ベクター            | 説明 |
|-------------------------------------|-------------------|-------------|
| `gitaly_praefect_read_distribution` | `virtual_storage` | [仮想ストレージ](../../../../administration/gitaly/praefect/_index.md)名。 |
| `gitaly_praefect_read_distribution` | `storage`         | Gitalyストレージ名。 |

## パックオブジェクトキャッシュ {#pack-objects-cache}

[パックオブジェクトキャッシュ](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)を確認するには、ログとPrometheusのメトリクスを確認してください:

| ログフィールド名                        | 説明 |
|:--------------------------------------|:------------|
| `pack_objects_cache.hit`              | 現在のパックオブジェクトキャッシュがヒットしたかどうか（`true`または`false`）。 |
| `pack_objects_cache.key`              | パックオブジェクトキャッシュに使用されるキャッシュキー。 |
| `pack_objects_cache.generated_bytes`  | 書き込まれる新しいキャッシュのサイズ（バイト単位）。 |
| `pack_objects_cache.served_bytes`     | 提供されるキャッシュのサイズ（バイト単位）。 |
| `pack_objects.compression_statistics` | パックオブジェクト生成の統計。 |
| `pack_objects.enumerate_objects_ms`   | クライアントから送信されたオブジェクトの列挙に費やされた合計時間（ミリ秒）。 |
| `pack_objects.prepare_pack_ms`        | パックファイルをクライアントに送り返す前に、その準備に費やされた合計時間（ミリ秒） |
| `pack_objects.write_pack_file_ms`     | パックファイルをクライアントに送り返すのに費やされた合計時間（ミリ秒）。クライアントのインターネット接続に大きく依存します。 |
| `pack_objects.written_object_count`   | Gitalyがクライアントに送り返したオブジェクトの合計数。 |

ログメッセージの例:

```json
{
"bytes":26186490,
"correlation_id":"01F1MY8JXC3FZN14JBG1H42G9F",
"grpc.meta.deadline_type":"none",
"grpc.method":"PackObjectsHook",
"grpc.request.fullMethod":"/gitaly.HookService/PackObjectsHook",
"grpc.request.glProjectPath":"root/gitlab-workhorse",
"grpc.request.glRepository":"project-2",
"grpc.request.repoPath":"@hashed/d4/73/d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35.git",
"grpc.request.repoStorage":"default",
"grpc.request.topLevelGroup":"@hashed",
"grpc.service":"gitaly.HookService",
"grpc.start_time":"2021-03-25T14:57:52.747Z",
"level":"info",
"msg":"finished unary call with code OK",
"peer.address":"@",
"pid":20961,
"span.kind":"server",
"system":"grpc",
"time":"2021-03-25T14:57:53.543Z",
"pack_objects.compression_statistics": "Total 145991 (delta 68), reused 6 (delta 2), pack-reused 145911",
"pack_objects.enumerate_objects_ms": 170,
"pack_objects.prepare_pack_ms": 7,
"pack_objects.write_pack_file_ms": 786,
"pack_objects.written_object_count": 145991,
"pack_objects_cache.generated_bytes": 49533030,
"pack_objects_cache.hit": "false",
"pack_objects_cache.key": "123456789",
"pack_objects_cache.served_bytes": 49533030,
"peer.address": "127.0.0.1",
"pid": 8813,
}
```

| Prometheusのメトリクス名                    | ベクター   | 説明 |
|:------------------------------------------|:---------|:------------|
| `gitaly_pack_objects_served_bytes_total`  |          | 提供されるキャッシュのサイズ（バイト単位）。 |
| `gitaly_pack_objects_cache_lookups_total` | `result` | キャッシュルックアップの結果が`hit`または`miss`のいずれになったか。 |
