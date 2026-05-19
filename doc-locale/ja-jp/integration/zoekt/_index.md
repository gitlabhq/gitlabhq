---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Zoekt
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 利用制限

{{< /details >}}

{{< history >}}

- GitLab 15.9で`index_code_with_zoekt`および`search_code_with_zoekt`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049)されました。デフォルトでは無効になっています。
- GitLab 16.6で[GitLab.comとGitLabセルフマネージドで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/388519)。
- GitLab 16.11でグローバルコード検索が[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077)、`zoekt_cross_namespace_search`という名前の[フラグ](../../administration/feature_flags/_index.md)が追加されました。デフォルトでは無効になっています。
- 機能フラグ`index_code_with_zoekt`および`search_code_with_zoekt`は、GitLab 17.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378)されました。
- GitLab 17.9で機能フラグ`zoekt_rollout_worker`が[追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175666)。デフォルトでは無効になっています。
- GitLab 18.6でベータ版から[制限付き提供](https://gitlab.com/groups/gitlab-org/-/epics/17918)に変わりました。
- GitLab 18.7で機能フラグ[`zoekt_cross_namespace_search`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213413)と[`zoekt_rollout_worker`](https://gitlab.com/gitlab-org/gitlab/-/issues/519660)が削除されました。

{{< /history >}}

> [!warning]
> この機能は[限定的な利用](../../policy/development_stages_support.md#limited-availability)です。詳細については、[エピック9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)を参照してください。[イシュー420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)でフィードバックを提供してください。

Zoektは、コード検索に特化して設計されたオープンソースの検索エンジンです。

このインテグレーションを使用すると、GitLabでコードを検索するために、[完全一致コードの検索](../../user/search/exact_code_search.md)を、[高度な検索](../../user/search/advanced_search.md)の代わりに使用できます。グループまたはリポジトリ内でコードを検索するには、完全一致と正規表現モードを使用できます。

> [!note]
> Zoektはコード検索のみを処理し、[ElasticsearchまたはOpenSearch](../advanced_search/elasticsearch.md)を置き換えるものではありません。コメント、コミット、エピック、イシュー、マージリクエスト、マイルストーン、プロジェクト、ユーザー、Wikiを含む他のすべての検索スコープでは、ElasticsearchまたはOpenSearchが依然として必要です。

## Zoektをインストールする {#install-zoekt}

前提条件: 

- インスタンスの管理者であること。

GitLabで[完全一致コードの検索](#enable-exact-code-search)を有効にするには、少なくとも1つのZoektノードがインスタンスに接続されている必要があります。Zoektでは次のインストール方法がサポートされています:

- [Zoektチャート](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/)（スタンドアロンチャートとして、またはGitLab Helmチャートのサブチャートとして）
- [GitLab Operator](https://docs.gitlab.com/operator/)（`gitlab-zoekt.install=true`を使用）

次のインストール方法は、テスト用であり、本番環境での使用は推奨されません:

- [Docker Compose](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/tree/main/example/docker-compose)
- [Ansibleプレイブック](https://gitlab.com/gitlab-org/search-team/code-search/ansible-gitlab-zoekt)

## 完全一致コードの検索を有効にする {#enable-exact-code-search}

### GitLab UIから {#from-the-gitlab-ui}

前提条件: 

- インスタンスの管理者であること。
- Zoektが[インストールされている](#install-zoekt)こと。

GitLab UIから[完全一致コードの検索](../../user/search/exact_code_search.md)を有効にするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **インデックス作成を有効にする**と**検索を有効にする**のチェックボックスを選択します。
1. **変更を保存**を選択します。

### Rakeタスクを使用する {#with-rake-tasks}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/580121)されました。

{{< /history >}}

前提条件: 

- インスタンスの管理者であること。
- Zoektが[インストールされている](#install-zoekt)こと。

[完全一致コードの検索](../../user/search/exact_code_search.md)をRakeタスクで管理できます。

#### インデックス作成と検索を有効にする {#enable-indexing-and-search}

インデックス作成と検索を有効にするには、このタスクを実行します:

```shell
gitlab-rake gitlab:zoekt:index
```

このタスクは`zoekt_indexing_enabled`、`zoekt_search_enabled`、および`zoekt_auto_index_root_namespace`を有効にします。`RolloutWorker`はすべてのルートネームスペースを自動的にインデックス作成し、インデックスの準備が整うと検索が可能になります。

#### インデックス作成と検索を無効にする {#disable-indexing-and-search}

インデックス作成と検索を無効にするには、このタスクを実行します:

```shell
gitlab-rake gitlab:zoekt:disable
```

このタスクは`zoekt_indexing_enabled`と`zoekt_search_enabled`の両方を無効にします。

#### インデックス作成を一時停止および再開する {#pause-and-resume-indexing}

インデックス作成を一時停止するには（例えば、メンテナンス中）、このタスクを実行します:

```shell
gitlab-rake gitlab:zoekt:pause_indexing
```

インデックス作成を再開するには、このタスクを実行します:

```shell
gitlab-rake gitlab:zoekt:resume_indexing
```

#### ストレージ要件を推定する {#estimate-storage-requirements}

Zoektノードに必要なストレージを推定するには、このタスクを実行します:

```shell
sudo gitlab-rake gitlab:zoekt:estimate_storage
```

詳細については、[ストレージの見積もり](#estimate-storage)を参照してください。

## インデックス作成状態を確認する {#check-indexing-status}

{{< history >}}

- Zoektノードのストレージがクリティカルなウォーターマークを超えた場合のインデックス作成の停止は、GitLab 17.7で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/504945)、`zoekt_critical_watermark_stop_indexing`という名前の[フラグ](../../administration/feature_flags/_index.md)が追加されました。デフォルトでは無効になっています。
- GitLab 18.0 [でGitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/505334)で有効になりました。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/505334)になりました。機能フラグ`zoekt_critical_watermark_stop_indexing`は削除されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

インデックス作成のパフォーマンスは、ZoektインデクサーノードのCPUとメモリ制限に依存します。インデックス作成状態を確認するには、次の手順に従います。

{{< tabs >}}

{{< tab title="GitLab 17.10以降" >}}

このRakeタスクを実行します:

```shell
gitlab-rake gitlab:zoekt:info
```

データを10秒ごとに自動的に更新するには、代わりにこのタスクを実行します:

```shell
gitlab-rake "gitlab:zoekt:info[10]"
```

{{< /tab >}}

{{< tab title="GitLab 17.9以前" >}}

[Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)で、次のコマンドを実行します:

```ruby
Search::Zoekt::Index.group(:state).count
Search::Zoekt::Repository.group(:state).count
Search::Zoekt::Task.group(:state).count
```

{{< /tab >}}

{{< /tabs >}}

### サンプル出力 {#sample-output}

`gitlab:zoekt:info` Rakeタスクは、次のような出力を返します:

```console
Exact Code Search
GitLab version:                                      18.9.0
Enable indexing:                                     yes
Enable searching:                                    yes
Pause indexing:                                      no
Index root namespaces automatically:                 yes
Cache search results for five minutes:               yes
Indexing CPU to tasks multiplier:                    1.0
Probability of random force reindexing (percentage): 0.25
Number of parallel processes per indexing task:      1
Number of namespaces per indexing rollout:           32
Offline nodes automatically deleted after:           20m
Indexing timeout per project:                        30m
Maximum number of files per project to be indexed:   500000
Maximum file size for indexing:                      1MB
Maximum trigrams per file:                           20000
Retry interval for failed namespaces:                1d
Number of replicas per namespace:                    1

Nodes
# Number of Zoekt nodes and their status
Node count:                   2 (online: 2, offline: 0)
Last seen at:                 2025-11-21 22:58:09 UTC (less than a minute ago)
Max schema_version:           2531
Storage reserved / usable:    71.1 MiB / 124 GiB (0.06%)
Storage indexed / reserved:   42.7 MiB / 71.1 MiB (60.0%)
Storage used / total:         797 GiB / 921 GiB (86.54%)
Online node watermark levels: 2
  - low: 2

Indexing status
Group count:                      8
# Number of enabled namespaces and their status
EnabledNamespace count:           8 (without indices: 0, rollout blocked: 0, with search disabled: 0)
Replicas count:                   8
  - ready: 8
Indices count:                    8
  - ready: 8
Indices watermark levels:         8
  - healthy: 8
Repositories count:               10
  - ready: 10
Tasks count:                      10
  - done: 10
Tasks pending/processing by type: (none)
Storage buffer factor:            0.831× [static fallback (FF disabled)]

Feature Flags (Default Values)
- zoekt_too_many_replicas_event: disabled

Node Details
Node 1 - test-zoekt-hostname-1:
  Status:                       Online
  Last seen at:                 2025-11-21 22:58:09 UTC (less than a minute ago)
  Disk utilization:             86.54%
  Unclaimed storage:            62 GiB
  # Zoekt build version on the node. Must match GitLab version.
  Zoekt version:                2025.11.20-v1.7.6-28-gb9a0fd8
  Schema version:               2531
Node 2 - test-zoekt-hostname-2:
  Status:                       Online
  Last seen at:                 2025-11-21 22:58:09 UTC (less than a minute ago)
  Disk utilization:             86.54%
  Unclaimed storage:            62 GiB
  Zoekt version:                2025.11.20-v1.7.6-28-gb9a0fd8
  Schema version:               2531
```

## ヘルスチェックを実行する {#run-a-health-check}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203671)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

Zoektインフラストラクチャのステータスを理解するためにヘルスチェックを実行します。これには次のものが含まれます:

- オンラインノードとオフラインノード
- インデックス作成と検索設定
- 検索APIエンドポイント
- JSON Webトークン生成

ヘルスチェックを実行するには、次のタスクを実行します:

```shell
gitlab-rake gitlab:zoekt:health
```

このタスクは以下を提供します:

- 全体的なステータス: `HEALTHY`、`DEGRADED`、または`UNHEALTHY`
- 検出されたイシューを解決するための推奨事項
- 自動化およびモニタリングインテグレーションの終了コード: `0=healthy`、`1=degraded`、または`2=unhealthy`

### チェックを自動的に実行する {#run-checks-automatically}

10秒ごとに自動的にヘルスチェックを実行するには、次のタスクを実行します:

```shell
gitlab-rake "gitlab:zoekt:health[10]"
```

出力には、色付きのステータスインジケーターが含まれており、次のものが表示されます:

- オンラインおよびオフラインノード数、ストレージ使用量の警告、および接続イシュー
- コア設定検証とネームスペースおよびリポジトリのインデックス作成ステータス
- 組み合わせたヘルス評価を含む全体的なステータス: `HEALTHY`、`DEGRADED`、または`UNHEALTHY`
- イシューを解決するための推奨事項

## 強制再インデックス作成を実行する {#perform-force-reindexing}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/478814)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

プロジェクトの範囲で強制再インデックス作成を実行します。

このRakeタスクを実行します:

```shell
gitlab-rake gitlab:zoekt:reindex_projects ID_FROM=10 ID_TO=20
```

`ID_FROM`と`ID_TO`の環境変数を使用すると、限られた数のプロジェクトを強制的に再インデックス作成できます。1つのプロジェクトだけを再インデックス作成するには、`ID_FROM`と`ID_TO`を再インデックス作成するプロジェクトIDと同じ値にしてください。すべてのプロジェクトを再インデックス作成するには、環境変数を省略します。

## インデックス作成の一時停止 {#pause-indexing}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

[完全一致コードの検索](../../user/search/exact_code_search.md)のインデックス作成を一時停止するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **インデックス作成を一時停止**のチェックボックスを選択します。
1. **変更を保存**を選択します。

完全一致コードの検索のインデックス作成を一時停止すると、リポジトリ内のすべての変更がキューに追加されます。インデックス作成を再開するには、**Pause indexing for exact code search**チェックボックスをオフにします。

## ルートネームスペースを自動的にインデックス作成する {#index-root-namespaces-automatically}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/455533)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

既存および新規のルートネームスペースの両方を自動的にインデックス作成できます。すべてのルートネームスペースを自動的にインデックス作成するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **ルートネームスペースを自動的にインデックス化する**のチェックボックスを選択します。
1. **変更を保存**を選択します。

この設定を有効にすると、GitLabは次のすべてのプロジェクトのインデックス作成タスクを作成します:

- すべてのグループとサブグループ
- 新しいルートネームスペース

プロジェクトがインデックス作成されると、GitLabはリポジトリの変更が検出された場合にのみ増分インデックス作成を作成します。

この設定を無効にすると:

- 既存のルートネームスペースはインデックス作成されたままです。
- 新しいルートネームスペースはインデックス作成されなくなります。

## 検索結果をキャッシュする {#cache-search-results}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/523213)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

パフォーマンス向上のため、検索結果をキャッシュできます。この機能はデフォルトで有効になっており、結果を5分間キャッシュします。

検索結果をキャッシュするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **Cache search results for five minutes**チェックボックスを選択します。
1. **変更を保存**を選択します。

## 同時インデックス作成タスクを設定する {#set-concurrent-indexing-tasks}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481725)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

ZoektノードのCPU容量に対して、同時インデックス作成タスクの数を設定できます。

乗算が高いほど、より多くのタスクを同時に実行でき、CPU使用量が増加する代償としてインデックス作成スループットが向上します。デフォルト値は`1.0`（CPUコアあたり1タスク）です。

ノードのパフォーマンスとワークロードに基づいて、この値を調整できます。同時インデックス作成タスクの数を設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **CPUをタスク乗算にインデックスする**テキストボックスに値を入力します。

   例えば、Zoektノードに`4`個のCPUコアがあり、乗算が`1.5`の場合、そのノードの同時タスク数は`6`になります。
1. **変更を保存**を選択します。

## ランダムな強制再インデックス作成の確率を定義する {#define-the-probability-of-random-force-reindexing}

{{< history >}}

- GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/222273)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

プロジェクトが段階的にインデックス作成されるのではなく、強制的に再インデックス作成される確率を定義できます。デフォルト値は`0.25`（0.25%）です。

強制再インデックス作成は、インデックスを定期的にゼロから再構築することで、メモリマップ（mmap）ハンドラーが枯渇するのを防ぐのに役立ちます。割合が高いほど、特に非常に大規模なリポジトリでは、インデックス作成の負荷が増加します。

ランダムな強制再インデックス作成の確率を定義するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **ランダムな強制再インデックスの確率(パーセンテージ)** テキストボックスに、`0`から`100`までの数値を入力します。
1. **変更を保存**を選択します。

## インデックス作成タスクあたりの並列プロセス数を設定する {#set-the-number-of-parallel-processes-per-indexing-task}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/539526)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

インデックス作成タスクあたりの並列プロセス数を設定できます。

数値が高いほど、CPUとメモリ使用量が増加する代償として、インデックス作成時間が短縮されます。デフォルト値は`1`（インデックス作成タスクあたり1プロセス）です。

ノードのパフォーマンスとワークロードに基づいて、この値を調整できます。インデックス作成タスクあたりの並列プロセス数を設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **インデックスタスクごとの並列プロセス数**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

## インデックス作成ロールアウトあたりのネームスペース数を設定する {#set-the-number-of-namespaces-per-indexing-rollout}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/536175)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

最初のインデックス作成のために、`RolloutWorker`ジョブあたりのネームスペース数を設定できます。デフォルト値は`32`です。ノードのパフォーマンスとワークロードに基づいて、この値を調整できます。

インデックス作成ロールアウトあたりのネームスペース数を設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **インデックスロールアウトごとのネームスペースの数**テキストボックスに、ゼロより大きい数値を入力します。
1. **変更を保存**を選択します。

## オフラインノードが自動的に削除されるタイミングを定義する {#define-when-offline-nodes-are-automatically-deleted}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/487162)されました。
- **Delete offline nodes after 12 hours**チェックボックスが、GitLab 18.1で[更新](https://gitlab.com/gitlab-org/gitlab/-/issues/536178)され、**オフラインノードを削除するまでの時間**テキストボックスになりました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

オフラインのZoektノードは、関連するインデックス、リポジトリ、およびタスクとともに、特定の期間後に自動的に削除できます。デフォルト値は`12h`（12時間）です。

この設定を使用して、Zoektインフラストラクチャを管理し、孤立したリソースを防ぎます。オフラインノードが自動的に削除されるタイミングを定義するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **オフラインノードを削除するまでの時間**テキストボックスに値を入力します（例: `30m`（30分）、`2h`（2時間）、または`1d`（1日））。自動削除を無効にするには、`0`に設定します。
1. **変更を保存**を選択します。

## プロジェクトのインデックス作成タイムアウトを定義する {#define-the-indexing-timeout-for-a-project}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182581)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

プロジェクトのインデックス作成タイムアウトを定義できます。デフォルト値は`30m`（30分）です。

プロジェクトのインデックス作成タイムアウトを定義するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **プロジェクトごとのインデックス作成タイムアウト**テキストボックスに値を入力します（例: `30m`（30分）、`2h`（2時間）、または`1d`（1日））。
1. **変更を保存**を選択します。

## プロジェクトでインデックス作成するファイルの最大数を設定する {#set-the-maximum-number-of-files-in-a-project-to-be-indexed}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/539526)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

プロジェクトでインデックス作成できるファイルの最大数を設定できます。デフォルトブランチでこの制限を超えるファイルを持つプロジェクトは、インデックス作成されません。

デフォルト値は`500,000`です。

ノードのパフォーマンスとワークロードに基づいて、この値を調整できます。プロジェクトでインデックス作成するファイルの最大数を設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **プロジェクトごとにインデックス化されるファイルの最大数**テキストボックスに、ゼロより大きい数値を入力します。
1. **変更を保存**を選択します。

## インデックス作成の最大ファイルサイズを設定する {#set-maximum-file-size-for-indexing}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/581176)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

インデックス作成するファイルの最大サイズを設定できます。デフォルト値は`1MB`です。

指定されたサイズを超えるファイルでは、ファイル名のみがインデックス作成されます。これらのファイルはファイル名でのみ検索できます。インデックス作成の最大ファイルサイズを設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **インデックス化のための最大ファイルサイズ**テキストボックスに値を入力します（例: `512B`、`50KB`、`2MB`、または`1GB`）。値は小文字でも指定できます。
1. **変更を保存**を選択します。

## インデックス作成の最大トライグラム数を設定する {#set-the-maximum-trigram-count-for-indexing}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/584506)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

インデックス作成するファイルの最大トライグラム数を設定できます。デフォルト値は`20,000`です。

トライグラムは、Zoektが効率的なコード検索に使用する3文字のシーケンスです。このトライグラム制限を超えるファイルの場合、ファイル名のみがインデックス作成されます。制限が高いほど、インデックス作成と検索のパフォーマンスの両方に影響します。

インデックス作成の最大トライグラム数を設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **ファイルあたりの最大トライグラム数**テキストボックスに、ゼロより大きい数値を入力します。
1. **変更を保存**を選択します。

## 失敗したネームスペースの再試行間隔を定義する {#define-the-retry-interval-for-failed-namespaces}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182581)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

以前に失敗したネームスペースの再試行間隔を定義できます。デフォルト値は`1d`（1日）です。`0`の値は、失敗したネームスペースは決して再試行されないことを意味します。

失敗したネームスペースの再試行間隔を定義するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **失敗したネームスペースを再試行する間隔**テキストボックスに値を入力します（例: `30m`（30分）、`2h`（2時間）、または`1d`（1日））。
1. **変更を保存**を選択します。

## ネームスペースあたりのレプリカ数を設定する {#set-the-number-of-replicas-per-namespace}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214067)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

ネームスペースあたりのレプリカ数を設定できます。デフォルト値は`1`（ネームスペースあたり1レプリカ）です。

ネームスペースあたりのレプリカ数を増やすと、複数のZoektノードに負荷が分散され、検索の可用性が向上します。レプリカが増えると、ストレージ要件が増加します。

ネームスペースあたりのレプリカ数を設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. 展開する**完全一致コードの検索**。
1. **ネームスペースごとのレプリカの数**テキストボックスに、ゼロより大きい数値を入力します。
1. **変更を保存**を選択します。

## Zoektを別のサーバーで実行する {#run-zoekt-on-a-separate-server}

{{< history >}}

- Zoektの認証は、GitLab 16.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/389749)。

{{< /history >}}

前提条件: 

- インスタンスの管理者であること。

GitLabとは異なるサーバーでZoektを実行するには:

1. [Gitalyリスニングインターフェースを変更](../../administration/gitaly/configure_gitaly.md#change-the-gitaly-listening-interface)します。
1. [Zoektをインストール](#install-zoekt)します。

## サイジングに関する推奨事項 {#sizing-recommendations}

以下の推奨事項は、一部のデプロイでは過剰なプロビジョニングとなる可能性があります。デプロイを監視して、次のことを確認する必要があります:

- メモリ不足イベントが発生しないこと。
- CPUスロットリングが過度ではないこと。
- インデックス作成パフォーマンスが要件を満たしていること。

リソースは、以下を含む特定のワークロード特性に基づいて調整します:

- リポジトリのサイズと複雑さ
- アクティブなデベロッパーの数
- コード変更の頻度
- インデックス作成パターン

### メモリアーキテクチャ {#memory-architecture}

ウェブサーバーとインデクサーは異なるメモリ使用量パターンを持っています。

ウェブサーバーは、ディスクから仮想メモリにインデックスシャードをメモリマップします。オペレーティングシステムは、検索が処理される際に、シャードデータを物理メモリにページインおよびページアウトします。常駐メモリ使用量は、アクティブなワーキングセットとともに増加します。より大きなインデックスまたはより高いクエリボリュームを持つノードは、ページスラッシングやメモリ不足状態を回避するためにより多くのウェブサーバーメモリを必要とします。

インデクサーは、インデックスを構築または再構築する際に、Gitオブジェクトデータをメモリ内で処理します。大規模なリポジトリをインデックス作成しているときや、複数のタスクが並行して実行されているときに、メモリ使用量が急増します。[インデックス作成タスクあたりの並列プロセス数](#set-the-number-of-parallel-processes-per-indexing-task)と[インデックス作成CPU-タスク乗算](#set-concurrent-indexing-tasks)を調整することで、インデクサーのピークメモリを制御できます。

VMおよびベアメタルデプロイでは、ウェブサーバーとインデクサーが同じシステムメモリを共有します。

### ノード {#nodes}

最適なパフォーマンスのためには、Zoektノードの適切なサイジングが重要です。KubernetesとVMのデプロイでは、リソースの割り当てと管理方法が異なるため、サイジングに関する推奨事項も異なります。

#### Kubernetesデプロイ {#kubernetes-deployments}

以下の表は、インデックスストレージ要件に基づいたKubernetesデプロイにおけるノード（StatefulSetポッドあたり）ごとの推奨リソースを示しています。StatefulSet内の各ポッドは、独立したリソース割り当てと、インデックスストレージ用の独自の永続ボリュームを持つ独自のウェブサーバーとインデクサーコンテナを実行します。複数のノードを実行している場合、これらのリソースをノードの数で乗算して、合計クラスターリソースを計算します。

| ディスク   | ウェブサーバーCPU | ウェブサーバーメモリ  | インデクサーCPU | インデクサーメモリ |
|--------|---------------|-------------------|-------------|----------------|
| 128 GB | 1             | 16 GiB            | 1           | 6 GiB  |
| 256 GB | 1.5           | 32 GiB            | 1           | 8 GiB  |
| 512 GB | 2             | 64 GiB            | 1           | 12 GiB |
| 1 TB   | 3             | 128 GiB           | 1.5         | 24 GiB |
| 2 TB   | 4             | 256 GiB           | 2           | 32 GiB |

リソースをより細かく管理するために、CPUとメモリを異なるコンテナに個別に割り当てることができます。

Kubernetesデプロイの場合:

- ZoektコンテナのCPU制限を設定しないでください。CPU制限は、インデックス作成のバースト中に不要なスロットリングを引き起こし、パフォーマンスに重大な影響を与える可能性があります。代わりに、リソースリクエストに依存して、最小限のCPU可用性を保証し、利用可能で必要な場合にコンテナが追加のCPUを使用するようにしてください。
- リソース競合やメモリ不足の状態を防ぐために、適切なメモリ制限を設定してください。
- より良いインデックス作成パフォーマンスのために、高性能ストレージクラスを使用してください。GitLab.comではGCPで`pd-balanced`を使用しており、パフォーマンスとコストのバランスが取れています。同等のオプションには、AWSの`gp3`とAzureの`Premium_LRS`が含まれます。

#### VMとベアメタルデプロイ {#vm-and-bare-metal-deployments}

以下の表は、インデックスストレージ要件に基づいたVMおよびベアメタルデプロイにおけるノードごとの推奨リソースを示しています。複数のノードを実行している場合、これらのリソースをノードの数で乗算して、合計クラスターリソースを計算します。

| ディスク   | VMサイズ  | 合計CPU | 合計メモリ | AWS          | GCP             | Azure |
|--------|----------|-----------|--------------|--------------|-----------------|-------|
| 128 GB | S    | 2コア   | 16 GB        | `r5.large`   | `n1-highmem-2`  | `Standard_E2s_v3`  |
| 256 GB | 中程度   | 4コア   | 32 GB        | `r5.xlarge`  | `n1-highmem-4`  | `Standard_E4s_v3`  |
| 512 GB | L    | 4コア   | 64 GB        | `r5.2xlarge` | `n1-highmem-8`  | `Standard_E8s_v3`  |
| 1 TB   | Xラージ  | 8コア   | 128 GB       | `r5.4xlarge` | `n1-highmem-16` | `Standard_E16s_v3` |
| 2 TB   | 2Xラージ | 16コア  | 256 GB       | `r5.8xlarge` | `n1-highmem-32` | `Standard_E32s_v3` |

これらのリソースは、ノード全体にのみ割り当てることができます。

VMおよびベアメタルデプロイの場合:

- CPU、メモリ、ディスク使用量を監視してボトルネックを特定してください。
- より良いインデックス作成パフォーマンスのために、SSDストレージの使用を検討してください。
- GitLabとZoektノード間のデータ転送に十分なネットワーク帯域幅があることを確認してください。

### ストレージ {#storage}

Zoektのストレージ要件は、Gitリポジトリのサイズとレプリカ設定によって異なります。ZoektはGitオブジェクトデータ（ソースコードとコミット履歴）のみをインデックスします。LFSオブジェクト、Wiki、アーティファクト、パッケージ、またはその他のストレージコンポーネントはインデックスしません。

#### ストレージを見積もる {#estimate-storage}

ストレージ要件を見積もるには、Rakeタスクを実行します:

```shell
sudo gitlab-rake gitlab:zoekt:estimate_storage
```

このタスクはGitLabデータベースをクエリし、現在のリポジトリサイズとレプリカ設定に基づいたストレージ見積もりを出力します。

手動で計算したい場合は、以下を使用します:

```plaintext
storage_per_replica = sum(repository_git_size) × buffer_factor
total_cluster_storage = storage_per_replica × number_of_replicas
```

ここで`repository_git_size`は、各リポジトリのGitオブジェクトサイズです。この値には、LFSオブジェクト、Wiki、アーティファクト、またはパッケージは含まれません。また`buffer_factor`は、最初のインデックス作成中のヘッドルームです。これは`Search::Zoekt::Index.global_buffer_factor`として計算できますが、デフォルトではほとんど`3`です。

`repository_git_size`を表示するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **プロジェクト**を選択します。
1. **リポジトリ**列で、Gitオブジェクトサイズを表示します。

最初のプロビジョニングターゲットでは、合計`repository_git_size`の3倍にレプリカ数を乗じた値から開始します。例: 

- 100 GBのGitリポジトリデータと1つのレプリカ: 300 GBのZoektストレージ。
- 100 GBのGitリポジトリデータと2つのレプリカ: 600 GBのZoektストレージ。

GitLabは、インデックス作成中にZoektがヘッドルームを持つことを保証するために、このバッファを内部的に予約します。最初のインデックス作成が完了すると、実際のディスク使用量は、観察されたGitLab.comのデータに基づいて、`repository_git_size`の半分に近くなります。必要な場合にのみ、垂直または水平にスケールする。

実行することで、現在使用中のバッファ係数を表示できます:

```shell
sudo gitlab-rake gitlab:zoekt:info
```

出力には、`Storage buffer factor`行が含まれており、プランナーが現在使用している値と、それが動的であるか静的フォールバックであるかが示されます。

Zoektノードのストレージを監視するには、[インデックス作成ステータスの確認](#check-indexing-status)を参照してください。ディスク容量不足のためネームスペースがインデックス作成されない場合は、ノードを追加するか、ディスク容量を増やしてください。

## セキュリティと認証 {#security-and-authentication}

Zoektは、GitLab、Zoektインデクサー、Zoektウェブサーバーコンポーネント間の通信を保護するために、多層認証システムを実装しています。すべての通信チャンネルで認証が強制されます。

すべての認証方法は、GitLab Shellシークレットを使用します。失敗した認証試行は`401 Unauthorized`応答を返します。

### ZoektインデクサーからGitLabへ {#zoekt-indexer-to-gitlab}

Zoektインデクサーは、GitLabにJSON Webトークン（JWT）で認証することで、インデックス作成タスクを取得するし、完了コールバックを送信します。

このメソッドは、署名と検証に`.gitlab_shell_secret`を使用します。トークンは`Gitlab-Shell-Api-Request`ヘッダーで送信されます。エンドポイントには以下が含まれます:

- タスクの取得のための`GET /internal/search/zoekt/:uuid/heartbeat`
- ステータス更新のための`POST /internal/search/zoekt/:uuid/callback`

このメソッドは、ZoektインデクサーノードとGitLab間のタスク配布とステータスレポートのための安全なポーリングを保証します。

### GitLabからZoektウェブサーバーへ {#gitlab-to-the-zoekt-webserver}

#### JWT認証 {#jwt-authentication}

{{< history >}}

- JWT認証はGitLab Zoekt 1.0.0で[導入されました](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/releases/v1.0.0)。

{{< /history >}}

GitLabは、JSON Webトークン（JWT）を使用してZoektウェブサーバーに認証することで、検索クエリを実行します。JWTトークンは、他のGitLab認証パターンと一貫した、時間制限付きの暗号学的署名付き認証を提供します。

このメソッドは`Gitlab::Shell.secret_token`とHS256アルゴリズム（HMAC with SHA-256）を使用します。トークンは`Authorization: Bearer <jwt_token>`ヘッダーで送信され、露出を制限するために5分で有効期限が切れます。

エンドポイントには`/webserver/api/search`と`/webserver/api/v2/search`が含まれます。JWTクレームは、発行者（`gitlab`）と対象（`gitlab-zoekt`）です。
