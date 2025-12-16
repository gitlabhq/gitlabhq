---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Zoekt
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 15.9で`index_code_with_zoekt`および`search_code_with_zoekt`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049)されました。デフォルトでは無効になっています。
- GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/388519)になりました。
- 機能フラグ`index_code_with_zoekt`および`search_code_with_zoekt`は、GitLab 17.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378)されました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は[ベータ](../../policy/development_stages_support.md#beta)版であり、予告なく変更される場合があります。詳細については、[エピック9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)を参照してください。この機能に関するフィードバックを提供するには、[イシュー420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)にコメントを残してください。

{{< /alert >}}

Zoektは、コード検索に特化して設計されたオープンソースの検索エンジンです。

このインテグレーションにより、GitLabでコードを検索するために、[高度な検索](../../user/search/advanced_search.md)の代わりに[完全一致コードの検索](../../user/search/exact_code_search.md)を使用できます。完全一致と正規表現モードを使用して、グループまたはリポジトリ内のコードを検索できます。

## Zoektのインストール {#install-zoekt}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

GitLabで[完全一致コードの検索を有効にする](#enable-exact-code-search)には、少なくとも1つのZoektノードがインスタンスに接続されている必要があります。Zoektでは、以下のインストール方法がサポートされています:

- [Zoektチャート](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/)
- [GitLab Operator](https://docs.gitlab.com/operator/)（`gitlab-zoekt.install=true`を使用）。

以下のインストール方法はテスト用であり、本番環境での使用は想定されていません:

- [Docker Compose](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/tree/main/example/docker-compose)
- [Ansibleプレイブック](https://gitlab.com/gitlab-org/search-team/code-search/ansible-gitlab-zoekt)

## 完全一致コードの検索を有効にする {#enable-exact-code-search}

前提要件:

- インスタンスへの管理者アクセス権が必要です。
- [Zoektをインストール](#install-zoekt)する必要があります。

GitLabで[完全一致コードの検索](../../user/search/exact_code_search.md)を有効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **インデックス作成を有効にする**チェックボックスと**検索を有効にする**チェックボックスを選択します。
1. **変更を保存**を選択します。

## インデックス作成状態を確認する {#check-indexing-status}

{{< history >}}

- Zoektノードのストレージがクリティカルウォーターマークを超えた場合にインデックス作成を停止する機能が、`zoekt_critical_watermark_stop_indexing`という[フラグ付き](../../administration/feature_flags/_index.md)でGitLab 17.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/504945)。デフォルトでは無効になっています。デフォルトでは無効になっています。
- GitLab 18.0 [でGitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/505334)で有効になりました。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/505334)になりました。機能フラグ`zoekt_critical_watermark_stop_indexing`は削除されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

インデックス作成のパフォーマンスは、ZoektインデクサーノードのCPUとメモリの制限に左右されます。インデックス作成状態を確認するには、次の手順に従います:

{{< tabs >}}

{{< tab title="GitLab 17.10以降" >}}

このRakeタスクを実行します:

```shell
gitlab-rake gitlab:zoekt:info
```

データが10秒ごとに自動的に更新されるようにするには、代わりにこのタスクを実行します:

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

### 出力例 {#sample-output}

`gitlab:zoekt:info` Rakeタスクは、次のような出力を返します:

```console
Exact Code Search
GitLab version:                           18.4.0
Enable indexing:                          yes
Enable searching:                         yes
Pause indexing:                           no
Index root namespaces automatically:      yes
Cache search results for five minutes:    yes
Indexing CPU to tasks multiplier:         1.0
Number of parallel processes per indexing task: 1
Number of namespaces per indexing rollout: 32
Offline nodes automatically deleted after: 20m
Indexing timeout per project:             30m
Maximum number of files per project to be indexed: 500000
Retry interval for failed namespaces:    1d

Nodes
# Number of Zoekt nodes and their status
Node count:                               2 (online: 2, offline: 0)
Last seen at:                             2025-09-15 22:58:09 UTC (less than a minute ago)
Max schema_version:                       2531
Storage reserved / usable:                71.1 MiB / 124 GiB (0.06%)
Storage indexed / reserved:               42.7 MiB / 71.1 MiB (60.0%)
Storage used / total:                     797 GiB / 921 GiB (86.54%)
Online node watermark levels:            2
  - low: 2

Indexing status
Group count:                              8
# Number of enabled namespaces and their status
EnabledNamespace count:                   8 (without indices: 0, rollout blocked: 0, with search disabled: 0)
Replicas count:                           8
  - ready: 8
Indices count:                            8
  - ready: 8
Indices watermark levels:                 8
  - healthy: 8
Repositories count:                       10
  - ready: 10
Tasks count:                              10
  - done: 10
Tasks pending/processing by type:         (none)

Feature Flags (Non-Default Values)
Feature flags:                            none

Feature Flags (Default Values)
- zoekt_cross_namespace_search:           disabled
- zoekt_debug_delete_repo_logging:        disabled
- zoekt_load_balancer:                    disabled
- zoekt_rollout_worker:                   enabled
- zoekt_search_meta_project_ids:          disabled
- zoekt_traversal_id_queries:             disabled

Node Details
Node 1 - test-zoekt-hostname-1:
  Status:                                 Online
  Last seen at:                           2025-09-15 22:58:09 UTC (less than a minute ago)
  Disk utilization:                       86.54%
  Unclaimed storage:                      62 GiB
  # Zoekt build version on the node. Must match GitLab version.
  Zoekt version:                          2025.09.14-v1.4.4-30-g0e7414a
  Schema version:                         2531
Node 2 - test-zoekt-hostname-2:
  Status:                                 Online
  Last seen at:                           2025-09-15 22:58:09 UTC (less than a minute ago)
  Disk utilization:                       86.54%
  Unclaimed storage:                      62 GiB
  Zoekt version:                          2025.09.14-v1.4.4-30-g0e7414a
  Schema version:                         2531
```

## ヘルスチェックの実行 {#run-a-health-check}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203671)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

ヘルスチェックを実行して、以下を含むZoektインフラストラクチャの状態を把握します:

- オンラインおよびオフラインノード
- インデックス作成と検索の設定
- 検索APIエンドポイント
- JSON Webトークンの生成

ヘルスチェックを実行するには、次のタスクを実行します:

```shell
gitlab-rake gitlab:zoekt:health
```

このタスクは以下を提供します:

- 全体的なステータス: `HEALTHY`、`DEGRADED`、または`UNHEALTHY`
- 検出された問題を解決するための推奨事項
- 自動化とモニタリングインテグレーションの終了コード: `0=healthy`、`1=degraded`、または`2=unhealthy`

### チェックの自動実行 {#run-checks-automatically}

10秒ごとに自動的にヘルスチェックを実行するには、次のタスクを実行します:

```shell
gitlab-rake "gitlab:zoekt:health[10]"
```

出力には色分けされたステータスインジケーターが含まれており、以下が表示されます:

- オンラインおよびオフラインノード数、ストレージ使用量の警告、および接続の問題
- コア設定の検証、ネームスペースとリポジトリのインデックス作成ステータス
- 組み合わせたヘルスチェック評価を含む全体的なステータス: `HEALTHY`、`DEGRADED`、または`UNHEALTHY`
- 問題を解決するための推奨事項

## インデックス作成の一時停止 {#pause-indexing}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

[完全一致コード検索](../../user/search/exact_code_search.md)のインデックス作成を一時停止するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **インデックス作成を一時停止**チェックボックスを選択します。
1. **変更を保存**を選択します。

完全一致コード検索のインデックス作成を一時停止すると、リポジトリ内のすべての変更がキューに登録されます。インデックス作成を再開するには、**完全一致コード検索のインデックス作成を一時停止**チェックボックスをオフにします。

## ルートネームスペースを自動的にインデックス作成する {#index-root-namespaces-automatically}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/455533)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

既存および新規のルートネームスペースの両方を自動的にインデックス作成できます。すべてのルートネームスペースを自動的にインデックス作成するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **ルートネームスペースを自動的にインデックス化する**チェックボックスを選択します。
1. **変更を保存**を選択します。

この設定を有効にすると、GitLabは次のすべてのプロジェクトのインデックス作成タスクを作成します:

- すべてのグループとサブグループ
- 新しいルートネームスペース

プロジェクトがインデックス作成されると、リポジトリの変更が検出された場合にのみ、GitLabは増分インデックス作成を作成します。

この設定を無効にすると:

- 既存のルートネームスペースはインデックス作成されたままになります。
- 新しいルートネームスペースはインデックス作成されなくなります。

## 検索結果のキャッシュ {#cache-search-results}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/523213)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

パフォーマンスを向上させるために、検索結果をキャッシュできます。この機能はデフォルトで有効になっており、結果を5分間キャッシュします。

検索結果をキャッシュするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **Cache search results for five minutes**（検索結果を5分間キャッシュする）チェックボックスを選択します。
1. **変更を保存**を選択します。

## 同時インデックス作成タスクの設定 {#set-concurrent-indexing-tasks}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481725)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

Zoektノードの同時インデックス作成タスクの数を、そのCPU容量を基準にして設定できます。

乗算が大きいほど、より多くのタスクを同時に実行でき、CPU使用率の増加と引き換えにインデックス作成のスループットが向上します。デフォルト値は`1.0`（CPUコアあたり1つのタスク）です。

この値は、ノードのパフォーマンスとワークロードに基づいて調整できます。同時インデックス作成タスクの数を設定するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **CPUをタスク乗算にインデックスする**テキストボックスに値を入力します。

   たとえば、Zoektノードに`4`個のCPUコアがあり、乗算が`1.5`の場合、ノードの同時実行タスク数は`6`です。

1. **変更を保存**を選択します。

## インデックス作成タスクあたりの並列プロセス数を設定する {#set-the-number-of-parallel-processes-per-indexing-task}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/539526)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

インデックス作成タスクあたりの並列プロセス数を設定できます。

数値を大きくすると、CPUとメモリの使用量が増加する代わりに、インデックス作成時間が短縮されます。デフォルト値は`1`（インデックス作成タスクあたり1つのプロセス）です。

この値は、ノードのパフォーマンスとワークロードに基づいて調整できます。インデックス作成タスクあたりの並列プロセス数を設定するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **インデックスタスク毎の並列プロセス数**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

## インデックス作成ロールアウトあたりのネームスペース数を設定する {#set-the-number-of-namespaces-per-indexing-rollout}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/536175)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

最初のインデックス作成のために、`RolloutWorker`ジョブあたりのネームスペースの数を設定できます。デフォルト値は`32`です。この値は、ノードのパフォーマンスとワークロードに基づいて調整できます。

インデックス作成ロールアウトあたりのネームスペース数を設定するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **インデックスロールアウト毎のネームスペースの数**テキストボックスに、ゼロより大きい数値を入力します。
1. **変更を保存**を選択します。

## オフラインノードを自動的に削除するタイミングを定義する {#define-when-offline-nodes-are-automatically-deleted}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/487162)されました。
- **Delete offline nodes after 12 hours**（オフラインノードを12時間後に削除する）チェックボックスが、GitLab 18.1の**オフラインノードを削除するまでの時間**テキストボックスに[更新されました](https://gitlab.com/gitlab-org/gitlab/-/issues/536178)。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

オフラインのZoektノードを、関連するインデックス、リポジトリ、およびタスクとともに、特定の時間が経過した後で自動的に削除できます。デフォルト値は`12h`（12時間）です。

この設定を使用して、Zoektインフラストラクチャを管理し、孤立したリソースを防止します。オフラインノードを自動的に削除するタイミングを定義するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **オフラインノードを削除するまでの時間**テキストボックスに値を入力します（例: `30m`（30分）、`2h`（2時間）、`1d`（1日））。自動削除を無効にするには、`0`に設定します。
1. **変更を保存**を選択します。

## プロジェクトのインデックス作成タイムアウトを定義する {#define-the-indexing-timeout-for-a-project}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182581)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

プロジェクトのインデックス作成タイムアウトを定義できます。デフォルト値は`30m`（30分）です。

プロジェクトのインデックス作成タイムアウトを定義するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **プロジェクトごとのインデックス作成タイムアウト**テキストボックスに値を入力します（例: `30m`（30分）、`2h`（2時間）、`1d`（1日））。
1. **変更を保存**を選択します。

## インデックス作成されるプロジェクト内のファイルの最大数を設定する {#set-the-maximum-number-of-files-in-a-project-to-be-indexed}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/539526)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

インデックス作成できるプロジェクト内のファイルの最大数を設定できます。デフォルトのブランチにこの制限を超えるファイルがあるプロジェクトは、インデックス作成されません。

デフォルト値は`500,000`です。

この値は、ノードのパフォーマンスとワークロードに基づいて調整できます。インデックス作成されるプロジェクト内のファイルの最大数を設定するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **プロジェクトごとにインデックス化されるファイルの最大数**テキストボックスに、ゼロより大きい数値を入力します。
1. **変更を保存**を選択します。

## 失敗したネームスペースの再試行間隔を定義する {#define-the-retry-interval-for-failed-namespaces}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182581)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

以前に失敗したネームスペースの再試行間隔を定義できます。デフォルト値は`1d`（1日）です。`0`の値は、失敗したネームスペースが再試行されないことを意味します。

失敗したネームスペースの再試行間隔を定義するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **完全一致コードの検索の設定**を展開します。
1. **失敗したネームスペースを再試行する間隔**テキストボックスに値を入力します（例: `30m`（30分）、`2h`（2時間）、`1d`（1日））。
1. **変更を保存**を選択します。

## 別のサーバーでZoektを実行する {#run-zoekt-on-a-separate-server}

{{< history >}}

- Zoektの認証がGitLab 16.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/389749)。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

GitLabとは異なるサーバーでZoektを実行するには:

1. [Gitalyリスニングインターフェースを変更する](../../administration/gitaly/configure_gitaly.md#change-the-gitaly-listening-interface)。
1. [Zoektをインストール](#install-zoekt)します。

## サイジングの推奨事項 {#sizing-recommendations}

一部のデプロイでは、以下の推奨事項が過剰にプロビジョニングされている可能性があります。次のことを確認するために、デプロイをモニタリングする必要があります:

- メモリ使用量不足イベントが発生しない。
- CPUスロットリングが過度でない。
- インデックス作成のパフォーマンスが要件を満たしている。

次のような特定のワークロード特性に基づいてリソースを調整します:

- リポジトリのサイズと複雑さ
- アクティブなデベロッパーの数
- コード変更の頻度
- インデックス作成パターン

### ノード {#nodes}

最適なパフォーマンスを得るには、Zoektノードの適切なサイジングが不可欠です。リソースの割り当て方法と管理方法が異なるため、サイジングの推奨事項はKubernetesとVMデプロイで異なります。

#### Kubernetesのデプロイ {#kubernetes-deployments}

次の表に、インデックスストレージ要件に基づくKubernetesデプロイの推奨リソースを示します:

| ディスク   | ウェブサーバーCPU | ウェブサーバーメモリ  | インデクサーCPU | インデクサーメモリ |
|--------|---------------|-------------------|-------------|----------------|
| 128 GB | 1             | 16 GiB            | 1           | 6 GiB  |
| 256 GB | 1.5           | 32 GiB            | 1           | 8 GiB  |
| 512 GB | 2             | 64 GiB            | 1           | 12 GiB |
| 1 TB   | 3             | 128 GiB           | 1.5         | 24 GiB |
| 2 TB   | 4             | 256 GiB           | 2           | 32 GiB |

リソースをより細かく管理するには、CPUとメモリを別々のコンテナに割り当てることができます。

Kubernetesデプロイの場合:

- ZoektコンテナのCPU制限を設定しないでください。CPU制限により、インデックス作成の急増時に不要なスロットリングが発生し、パフォーマンスに大きな影響を与える可能性があります。代わりに、リソースリクエストに依存して、最小CPU可用性を保証し、利用可能で必要な場合に追加のCPUをコンテナが使用できるようにします。
- 適切なメモリ制限を設定して、リソースの競合とメモリ使用量不足状態を防ぎます。
- より優れたインデックス作成パフォーマンスを得るには、高性能ストレージクラスを使用します。GitLab.comはGCPで`pd-balanced`を使用しており、パフォーマンスとコストのバランスが取れています。同等のオプションには、AWSの`gp3`、Azureの`Premium_LRS`などがあります。

#### VMとベアメタルデプロイ {#vm-and-bare-metal-deployments}

次の表に、インデックスストレージ要件に基づくVMとベアメタルデプロイの推奨リソースを示します:

| ディスク   | VMサイズ  | 合計CPU | 合計メモリ | AWS          | GCP             | Azure |
|--------|----------|-----------|--------------|--------------|-----------------|-------|
| 128 GB | S    | 2コア   | 16 GB        | `r5.large`   | `n1-highmem-2`  | `Standard_E2s_v3`  |
| 256 GB | 中程度   | 4コア   | 32 GB        | `r5.xlarge`  | `n1-highmem-4`  | `Standard_E4s_v3`  |
| 512 GB | L    | 4コア   | 64 GB        | `r5.2xlarge` | `n1-highmem-8`  | `Standard_E8s_v3`  |
| 1 TB   | X-Large  | 8コア   | 128 GB       | `r5.4xlarge` | `n1-highmem-16` | `Standard_E16s_v3` |
| 2 TB   | 2X-Large | 16コア  | 256 GB       | `r5.8xlarge` | `n1-highmem-32` | `Standard_E32s_v3` |

これらのリソースは、ノード全体にのみ割り当てることができます。

VMおよびベアメタルデプロイの場合:

- CPU、メモリ、およびディスクの使用量をモニタリングして、ボトルネックを特定します。ウェブサーバーとインデクサーのプロセスの両方が、同じCPUとメモリのリソースを共有します。
- より優れたインデックス作成パフォーマンスを得るには、SSDストレージの使用を検討してください。
- GitLabとZoektノード間のデータ転送に十分なネットワーク帯域幅を確保します。

### ストレージ {#storage}

Zoektのストレージ要件は、大規模なバイナリファイル数を含む、リポジトリの特性によって大きく異なります。

開始点として、ZoektストレージがGitalyストレージの半分になると見積もることができます。たとえば、Gitalyストレージが1 TBの場合、Zoektストレージは約500 GB必要になる場合があります。

Zoektノードの使用状況をモニタリングするには、[インデックス作成ステータスの確認](#check-indexing-status)を参照してください。ディスク容量の不足によりネームスペースがインデックス作成されない場合は、ノードの追加またはスケールアップを検討してください。

## セキュリティと認証 {#security-and-authentication}

Zoektは、GitLab、Zoekt Indexer、Zoekt Webサーバーコンポーネント間の通信を保護するために、多層認証システムを実装しています。認証は、すべての通信チャンネルにわたって適用されます。

すべての認証方式は、GitLab Shellシークレットを使用します。失敗した認証試行は、`401 Unauthorized`レスポンスを返します。

### Zoekt IndexerからGitLabへ {#zoekt-indexer-to-gitlab}

Zoekt Indexerは、JSON Webトークン（JWT）でGitLabに認証し、インデックス作成タスクを取得し、完了コールバックを送信します。

このメソッドは、署名と検証に`.gitlab_shell_secret`を使用します。トークンは、`Gitlab-Shell-Api-Request`ヘッダーで送信されます。エンドポイントは次のとおりです:

- タスクの取得には`GET /internal/search/zoekt/:uuid/heartbeat`
- ステータスの更新には`POST /internal/search/zoekt/:uuid/callback`

このメソッドは、Zoekt IndexerノードとGitLab間のタスク配信とステータスレポートの安全なポーリングを保証します。

### GitLabからZoekt Webサーバーへ {#gitlab-to-the-zoekt-webserver}

#### JWT認証 {#jwt-authentication}

{{< history >}}

- JWT認証は、GitLab Zoekt 1.0.0で[導入](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/releases/v1.0.0)されました。

{{< /history >}}

GitLabは、検索クエリを実行するために、JSON Webトークン（JWT）を使用してZoekt Webサーバーに認証します。JWTトークンは、他のGitLabの認証パターンと一致する、時間制限付きの暗号署名付き認証を提供します。

このメソッドは、`Gitlab::Shell.secret_token`とHS256アルゴリズム（SHA-256を使用したHMAC）を使用します。トークンは、`Authorization: Bearer <jwt_token>`ヘッダーで送信され、公開を制限するために5分で期限切れになります。

エンドポイントには、`/webserver/api/search`と`/webserver/api/v2/search`が含まれます。JWTクレームは、発行者（`gitlab`）と対象者（`gitlab-zoekt`）です。

#### 基本認証 {#basic-authentication}

GitLabは、検索クエリを実行するために、NGINXを介したHTTP基本認証を使用してZoekt Webサーバーに認証します。基本認証は、主にGitLab HelmチャートおよびKubernetesデプロイで使用されます。

この方法では、Kubernetes Secretsで構成されたユーザー名とパスワードを使用します。エンドポイントには、Zoekt Webサーバーの`/webserver/api/search`と`/webserver/api/v2/search`が含まれます。
