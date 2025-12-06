---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 並行処理の制限
---

Gitalyを実行しているサーバーへの負荷を回避するために、並行処理を制限できます:

- RPC。
- パックオブジェクト。

これらの制限は、固定することも、アダプティブとして設定することもできます。

{{< alert type="warning" >}}

環境に対する制限の有効化は、予期しないトラフィックから保護するなど、特定の状況下でのみ、慎重に行う必要があります。制限に達すると、ユーザーに悪影響を与える切断が発生します。一貫性のある安定したパフォーマンスを得るには、まず、ノードの仕様の調整、[大規模リポジトリのレビュー](../../user/project/repository/monorepos/_index.md)、ワークロードなど、他のオプションを調査する必要があります。

{{< /alert >}}

## RPC並行処理の制限 {#limit-rpc-concurrency}

リポジトリのクローンまたはプル時に、さまざまなRPCがバックグラウンドで実行されます。特に、GitパックRPCは次のとおりです:

- `SSHUploadPackWithSidechannel`（Git SSHの場合）。
- `PostUploadPackWithSidechannel`（Git HTTPの場合）。

これらのRPCは大量のリソースを消費する可能性があり、次のような状況で大きな影響を与える可能性があります:

- 予期しない高トラフィック。
- ベストプラクティスに従わない[大規模リポジトリ](../../user/project/repository/monorepos/_index.md)に対して実行する。

これらのシナリオでGitalyサーバーが過負荷になるのを防ぐために、Gitalyの設定ファイルで並行処理制限を使用します。次に例を示します:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
      },
      {
         rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
      },
   ],
}
```

- `rpc`は、リポジトリごとに並行処理制限を設定するRPCの名前です。
- `max_per_repo`は、特定されたリポジトリごとの、特定のRPCに対するインフライトRPC呼び出しの最大数です。
- `max_queue_wait`は、Gitalyによってフェッチされるために、リクエストが並行処理キューで待機できる最大時間です。
- `max_queue_size`は、リクエストがGitalyによって拒否される前に、並行処理キュー（RPCメソッドごと）が拡張できる最大サイズです。

これにより、特定のRPCに対するインフライトRPC呼び出しの数が制限されます。制限はリポジトリごとに適用されます。前の例では:

- Gitalyサーバーによって提供される各リポジトリは、最大20個の同時`PostUploadPackWithSidechannel`および`SSHUploadPackWithSidechannel`インフライトRPC呼び出しを実行できます。
- 20個のスロットを使い果たしたリポジトリに対して別のリクエストが届いた場合、そのリクエストはキューに入れられます。
- リクエストがキューで1秒以上待機すると、エラーで拒否されます。
- キューが10を超えて増加すると、後続のリクエストはエラーで拒否されます。

{{< alert type="note" >}}

これらの制限に達すると、ユーザーは切断されます。

{{< /alert >}}

GitalyログとPrometheusを使用して、このキューの動作を監視できます。詳細については、[関連ドキュメント](monitoring.md#monitor-gitaly-concurrency-limiting)を参照してください。

## パックオブジェクトの並行処理制限 {#limit-pack-objects-concurrency}

Gitalyは、リポジトリを複製またはプルするために、SSHとHTTPSトラフィックの両方を処理するときに`git-pack-objects`プロセスをトリガーします。これらのプロセスは`pack-file`を生成し、予期しない高トラフィックや大規模なリポジトリからの同時プルなど、特に大量のリソースを消費する可能性があります。GitLab.comでは、インターネット接続が遅いクライアントでも問題が発生しています。

これらのプロセスがGitalyサーバーを圧倒しないように、Gitalyの設定ファイルでパックオブジェクトの並行処理制限を設定して制限できます。この設定は、リモートIPアドレスごとのインフライトパックオブジェクトプロセスの数を制限します。

{{< alert type="warning" >}}

環境に対するこれらの制限の有効化は、予期しないトラフィックから保護するなど、特定の状況下でのみ、慎重に行う必要があります。これらの制限に達すると、ユーザーは切断されます。一貫性のある安定したパフォーマンスを得るには、まず、ノードの仕様の調整、[大規模リポジトリのレビュー](../../user/project/repository/monorepos/_index.md)、ワークロードなど、他のオプションを調査する必要があります。

{{< /alert >}}

設定例: 

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['pack_objects_limiting'] = {
   'max_concurrency' => 15,
   'max_queue_length' => 200,
   'max_queue_wait' => '60s',
}
```

- `max_concurrency`は、キーごとのインフライトパックオブジェクトプロセスの最大数です。
- `max_queue_length`は、リクエストがGitalyによって拒否される前に、並行処理キュー（キーごと）が拡張できる最大サイズです。
- `max_queue_wait`は、Gitalyによってフェッチされるために、リクエストが並行処理キューで待機できる最大時間です。

前の例では:

- 各リモートIPは、Gitalyノードで最大15個の同時パックオブジェクトプロセスをインフライトで実行できます。
- 15個のスロットを使い果たしたIPから別のリクエストが届いた場合、そのリクエストはキューに入れられます。
- リクエストがキューで1分以上待機すると、エラーで拒否されます。
- キューが200を超えて増加すると、後続のリクエストはエラーで拒否されます。

パックオブジェクトのキャッシュが有効になっている場合、パックオブジェクトの制限は、キャッシュがミスした場合にのみ有効になります。詳細については、[パックオブジェクトのキャッシュ](configure_gitaly.md#pack-objects-cache)を参照してください。

GitalyログとPrometheusを使用して、このキューの動作を監視できます。詳細については、[Gitalyパックオブジェクトの並行処理制限のモニタリング](monitoring.md#monitor-gitaly-pack-objects-concurrency-limiting)を参照してください。

## 並行処理制限の調整 {#calibrating-concurrency-limits}

並行処理制限を設定するときは、特定のワークロードパターンに基づいて適切な値を選択する必要があります。このセクションでは、これらの制限を効果的に調整する方法について説明します。

### Prometheusのメトリクスとログを使用した調整 {#using-prometheus-metrics-and-logs-for-calibration}

Prometheusのメトリクスは、使用パターンと、各タイプのRPCがGitalyノードリソースに与える影響に関する定量的なインサイトを提供します。この分析では、いくつかのキーメトリクスが特に役立ちます:

- RPCごとのリソース消費メトリクス。Gitalyは、ほとんどの重いオペレーションを`git`プロセスにオフロードするため、通常Shellに渡されるコマンドはGitバイナリです。Gitalyは、これらのコマンドから収集されたメトリクスをログおよびPrometheusのメトリクスとして公開します。
  - `gitaly_command_cpu_seconds_total` - `grpc_service`、`grpc_method`、`cmd`、および`subcmd`のラベルが付いた、Shellの実行によって費やされたCPU時間の合計。
  - `gitaly_command_real_seconds_total` - 同様のラベルが付いた、Shellの実行によって費やされた実時間の合計。
- RPCごとの最近の制限メトリクス:
  - `gitaly_concurrency_limiting_in_progress` - 処理されている同時リクエストの数。
  - `gitaly_concurrency_limiting_queued` - 待機状態の特定のリポジトリに対するRPCのリクエストの数。
  - `gitaly_concurrency_limiting_acquiring_seconds` - 処理前の並行処理制限によりリクエストが待機する期間。

これらのメトリクスは、特定時点でのリソース使用率の概要を示します。`gitaly_command_cpu_seconds_total`メトリクスは、実質的なCPUリソースを消費する特定のRPCを特定するのに特に効果的です。詳細な分析に使用できる追加のメトリクスについては、[Gitalyのモニタリング](monitoring.md)の説明を参照してください。

メトリクスはリソース使用パターンの全体像を把握できますが、通常はリポジトリごとの内訳は提供されません。したがって、ログは補完的なデータソースとして機能します。ログを分析するには:

1. 特定された影響の大きいRPCでログをフィルタリングします。
1. フィルタリングされたログをリポジトリまたはプロジェクトで集計します。
1. 時系列グラフで集計された結果を視覚化します。

メトリクスとログの両方を使用するこの組み合わせられたアプローチは、システム全体のリソース使用率とリポジトリ固有のパターンの両方を包括的に可視化します。Kibanaのような分析ツールまたは同様のログ集計プラットフォームは、このプロセスを促進できます。

### 制限の調整 {#adjusting-limits}

初期制限が十分に効率的でないことが判明した場合は、調整が必要になる場合があります。アダプティブ制限を使用すると、リソース使用量に基づいてシステムが自動的に調整されるため、正確な制限はそれほど重要ではありません。

並行処理制限はリポジトリによってスコープされることに注意してください。制限30とは、リポジトリごとに最大30の同時インフライトリクエストを許可することを意味します。制限に達すると、リクエストはキューに入れられ、キューがいっぱいであるか、最大待機時間に達した場合にのみ拒否されます。

## アダプティブ並行処理制限 {#adaptive-concurrency-limiting}

{{< history >}}

- GitLab 16.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/10734)されました。

{{< /history >}}

Gitalyは、2つの並行処理制限をサポートしています:

- [RPC並行処理制限](#limit-rpc-concurrency)。これにより、Gitaly RPCごとに同時インフライトリクエストの最大数を設定できます。制限は、RPCとリポジトリによってスコープされます。
- [パックオブジェクトの並行処理制限](#limit-pack-objects-concurrency)。これにより、IPごとの同時Gitデータ転送リクエスト数が制限されます。

この制限を超えると、次のいずれかになります:

- リクエストはキューに入れられます。
- キューがいっぱいであるか、リクエストがキューに長くとどまっている場合、リクエストは拒否されます。

これらの並行処理制限は両方とも、静的に設定できます。静的な制限は優れた保護結果をもたらす可能性がありますが、いくつかの欠点があります:

- 静的な制限は、すべての使用パターンに適しているわけではありません。すべてに適合する単一の値はありません。制限が低すぎると、大規模なリポジトリに悪影響が及びます。制限が高すぎると、保護は本質的に失われます。
- 特に各リポジトリのワークロードが時間の経過とともに変化する場合、並行処理制限の健全な値を維持するのは面倒です。
- サーバーの負荷が考慮されないため、サーバーがアイドル状態であっても、リクエストが拒否される可能性があります。

これらの欠点をすべて克服し、アダプティブ並行処理制限を設定することにより、並行処理制限の利点を維持できます。アダプティブ並行処理制限はオプションであり、2つの並行処理制限タイプに基づいて構築されます。Additive Increase/Multiplicative Decrease（AIMD）アルゴリズムを使用します。各アダプティブ制限:

- 通常のプロセス機能中、特定の上限まで徐々に増加します。
- ホストマシンにリソースの問題が発生した場合、すばやく減少します。

このメカニズムにより、マシンが「呼吸」するためのヘッドルームが確保され、現在のインフライトリクエストが高速化されます。

![AIMDアルゴリズムに従ってシステムリソースの使用量に基づいて調整されるGitalyアダプティブ並行処理制限を示すグラフ](img/gitaly_adaptive_concurrency_limit_v16_6.png)

アダプティブリミッターは30秒ごとに制限を調整し、次のようになります:

- 上限に達するまで、制限を1つずつ増やします。
- 最上位のcgroupのメモリ使用量が、高度に削除可能なページキャッシュを除外して90％を超えるか、CPUが観測時間の50％以上スロットリングされると、制限が半分に減少します。

それ以外の場合、制限は上限に達するまで1つずつ増加します。

アダプティブ制限は、RPCまたはパックオブジェクトのキャッシュごとに個別に有効になります。ただし、制限は同時に調整されます。アダプティブ制限には、次の設定があります:

- `adaptive`は、アダプティブネスを有効にするかどうかを設定します。
- `max_limit`は、最大の並行処理制限です。Gitalyは、現在の制限がこの数に達するまで増加させます。これは、システムが通常の条件下で完全にサポートできる寛大な値である必要があります。
- `min_limit`は、設定されたRPCの最小並行処理制限です。ホストマシンにリソースの問題がある場合、Gitalyはこの値に達するまで制限をすばやく削減します。`min_limit`を0に設定すると、処理が完全にシャットダウンされる可能性があり、これは通常望ましくありません。
- `initial_limit`は、これらの極端な状況の間で適切な開始ポイントを提供します。

### RPC並行処理のアダプティブネスの有効化 {#enable-adaptiveness-for-rpc-concurrency}

前提要件: 

- アダプティブ制限は[コントロールグループ](configure_gitaly.md#control-groups)に依存するため、アダプティブ制限を使用する前にコントロールグループを有効にする必要があります。

以下は、RPC並行処理のアダプティブ制限を設定する例です:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
    # ...
    cgroups: {
        # Minimum required configuration to enable cgroups support.
        repositories: {
            count: 1
        },
    },
    concurrency: [
        {
            rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
            max_queue_wait: '1s',
            max_queue_size: 10,
            adaptive: true,
            min_limit: 10,
            initial_limit: 20,
            max_limit: 40
        },
        {
            rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
            max_queue_wait: '10s',
            max_queue_size: 20,
            adaptive: true,
            min_limit: 10,
            initial_limit: 50,
            max_limit: 100
        },
   ],
}
```

詳細については、[RPC並行処理](#limit-rpc-concurrency)を参照してください。

### パックオブジェクトの並行処理のアダプティブネスの有効化 {#enable-adaptiveness-for-pack-objects-concurrency}

前提要件: 

- アダプティブ制限は[コントロールグループ](configure_gitaly.md#control-groups)に依存するため、アダプティブ制限を使用する前にコントロールグループを有効にする必要があります。

以下は、パックオブジェクトの並行処理のアダプティブ制限を設定する例です:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['pack_objects_limiting'] = {
   'max_queue_length' => 200,
   'max_queue_wait' => '60s',
   'adaptive' => true,
   'min_limit' => 10,
   'initial_limit' => 20,
   'max_limit' => 40
}
```

詳細については、[パックオブジェクトの並行処理](#limit-pack-objects-concurrency)を参照してください。

### アダプティブ並行処理制限の調整 {#calibrating-adaptive-concurrency-limits}

アダプティブ並行処理制限は、GitLabがGitalyリソースを保護する通常の方法とは大きく異なります。制限が厳しすぎるか寛容すぎる可能性のある静的なしきい値に依存するのではなく、アダプティブ制限は実際のリソース状態にリアルタイムでインテリジェントに応答します。

このアプローチにより、[並行処理制限の調整](#calibrating-concurrency-limits)で説明されているように、広範な調整を通じて「完璧な」しきい値を見つける必要がなくなります。障害シナリオでは、アダプティブリミッターは制限を指数関数的に削減し（たとえば、60 → 30 → 15 → 10）、システムが安定すると制限を段階的に上げて自動的に回復します。

アダプティブ制限を調整するときは、精度よりも柔軟性を優先できます。

#### RPCカテゴリと設定例 {#rpc-categories-and-configuration-examples}

保護する必要がある高価なGitaly RPCは、2つの一般的なタイプに分類できます:

- 純粋なGitデータ操作。
- 時間の影響を受けやすいRPC。

各タイプには、並行処理制限を設定する方法に影響を与える明確な特性があります。次の例は、制限設定の背後にある理由を示しています。開始ポイントとして使用することもできます。

##### 純粋なGitデータ操作 {#pure-git-data-operations}

これらのRPCには、Gitプル、プッシュ、およびフェッチ操作が含まれ、次の特性があります:

- 長時間実行されるプロセス。
- 重要なリソース使用率。
- 計算コストが高い。
- 時間の影響を受けない。追加のレイテンシーは一般に許容されます。

`SmartHTTPService`および`SSHService`のRPCは、純粋なGitデータ操作カテゴリに分類されます。設定例:

```ruby
{
  rpc: "/gitaly.SmartHTTPService/PostUploadPackWithSidechannel", # or `/gitaly.SmartHTTPService/SSHUploadPackWithSidechannel`
  adaptive: true,
  min_limit: 10,  # Minimum concurrency to maintain even under extreme load
  initial_limit: 40,  # Starting concurrency when service initializes
  max_limit: 60,  # Maximum concurrency under ideal conditions
  max_queue_wait: "60s",
  max_queue_size: 300
}
```

##### 時間の影響を受けやすいRPC {#time-sensitive-rpcs}

これらのRPCは、GitLab自体と、特性が異なる他のクライアントにサービスを提供します:

- 通常、オンラインHTTPリクエストまたはSidekiqバックグラウンドジョブの一部です。
- 短いレイテンシープロファイル。
- 一般に、リソースの負荷が少なくなります。

これらのRPCの場合、GitLabのタイムアウト設定は、`max_queue_wait`パラメータに通知する必要があります。たとえば、`get_tree_entries`は通常、GitLabで30秒の中程度のタイムアウトがあります:

```ruby
{
  rpc: "/gitaly.CommitService/GetTreeEntries",
  adaptive: true,
  min_limit: 5,  # Minimum throughput maintained under resource pressure
  initial_limit: 10,  # Initial concurrency setting
  max_limit: 20,  # Maximum concurrency under optimal conditions
  max_queue_size: 50,
  max_queue_wait: "30s"
}
```

### モニタリングによる適応制限 {#monitoring-adaptive-limiting}

本番環境で適応制限がどのように動作しているかを確認するには、[Gitaly適応並行処理制限のモニタリング](monitoring.md#monitor-gitaly-adaptive-concurrency-limiting)で説明されているモニタリングツールとメトリクスを参照してください。適応制限の動作をモニタリングすることで、制限がリソース負荷に適切に対応し、期待どおりに調整されていることを確認できます。
