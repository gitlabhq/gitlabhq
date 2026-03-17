---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Elasticsearchのインデックス作成と検索のトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Elasticsearchのインデックス作成または検索を行う際に、以下の問題に遭遇することがあります。

## 空のインデックスを作成する {#create-an-empty-index}

インデックス作成に関する問題については、まず空のインデックスを作成してみてください。Elasticsearchインスタンスで`gitlab-production`インデックスが存在するかどうかを確認してください。存在する場合は、Elasticsearchインスタンス上のインデックスを手動で削除し、[`recreate_index`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) Rakeタスクから再作成を試みてください。

それでも問題が発生する場合は、Elasticsearchインスタンス上に手動でインデックスを作成してみてください。次の場合:

- インデックスを作成できない場合は、Elasticsearch管理者に問い合わせてください。
- インデックスを作成できる場合は、GitLabサポートに問い合わせてください。

## インデックス化されたプロジェクトのステータスをチェックする {#check-the-status-of-indexed-projects}

プロジェクトのインデックス作成中にエラーがないか確認できます。エラーは以下で発生する可能性があります:

- GitLabインスタンス: ご自身で修正できない場合は、GitLabサポートにガイダンスを求めてください。
- Elasticsearchインスタンス: [エラーがリストにない場合](../../elasticsearch/troubleshooting/_index.md)は、Elasticsearch管理者に問い合わせてください。

インデックス作成でエラーが返されない場合は、以下のRakeタスクでインデックス化されたプロジェクトのステータスを確認してください:

- 全体的なステータスを確認するには[`sudo gitlab-rake gitlab:elastic:index_projects_status`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)
- インデックス化されていない特定のプロジェクトについては[`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)

インデックス作成が以下の場合:

- 完了した場合は、GitLabサポートに問い合わせてください。
- 完了していない場合は、`sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=<project ID> ID_TO=<project ID>`を実行してそのプロジェクトを再インデックスしてみてください。

プロジェクトの再インデックス作成でエラーが表示される場合:

- GitLabインスタンス: GitLabサポートに問い合わせてください。
- Elasticsearchインスタンス、またはエラーが全くない場合: Elasticsearch管理者に連絡して、インスタンスを確認してもらってください。

## GitLabを更新した後に検索結果が表示されない {#no-search-results-after-updating-gitlab}

私たちはインデックス作成戦略を継続的に更新し、より新しいバージョンのElasticsearchをサポートすることを目指しています。インデックス作成に変更があった場合、GitLabを更新した後に[再インデックス作成](../../advanced_search/elasticsearch.md#zero-downtime-reindexing)が必要になる場合があります。

## すべてのリポジトリをインデックス化した後に検索結果が表示されない {#no-search-results-after-indexing-all-repositories}

> [!note] [ネームスペースのサブセット](../../advanced_search/elasticsearch.md#limit-the-amount-of-namespace-and-project-data-to-index)のみをインデックス作成するシナリオでは、これらの手順を使用しないでください。

すべてのデータベースデータを[インデックス化した](../../advanced_search/elasticsearch.md#enable-advanced-search)ことを確認してください。

UI検索で結果（ヒット）がない場合は、Railsコンソール（`sudo gitlab-rails console`）経由で同じ結果が表示されるか確認してください:

```ruby
u = User.find_by_username('your-username')
s = SearchService.new(u, {:search => 'search_term', :scope => 'blobs'})
pp s.search_objects.to_a
```

それに加えて、[Elasticsearch Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html)を介して、Elasticsearch側でデータが表示されるか確認してください:

```shell
curl --request GET <elasticsearch_server_ip>:9200/gitlab-production/_search?q=<search_term>
```

より複雑な[Elasticsearch APIコール](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html)も可能です。

結果が以下の場合:

- 同期する場合は、[サポートされている構文](../../../user/search/advanced_search.md#syntax)を使用していることを確認してください。高度な検索は厳密な部分文字列マッチングをサポートしていません[厳密な部分文字列マッチング](https://gitlab.com/gitlab-org/gitlab/-/issues/325234)。
- 一致しない場合、これはプロジェクトから生成されたドキュメントに問題があることを示します。そのプロジェクトを[再インデックス作成する](../../advanced_search/elasticsearch.md#indexing-a-range-of-projects-or-a-specific-project)のが最善です。

特定の種類のデータを検索する方法の詳細については、[Elasticsearchインデックススコープ](../../advanced_search/elasticsearch.md#advanced-search-index-scopes)を参照してください。

## 低い並行処理で高度な検索を有効にした後に検索結果がない {#no-search-results-after-enabling-advanced-search-with-low-concurrency}

高度な検索を有効にした後、ドキュメントがインデックス化されず、コードが検索できないことに気付くかもしれません。Sidekiqログに次のようなメッセージが表示されることがあります:

```json
"job_status":"concurrency_limit","message":"Search::Elastic::CommitIndexerWorker JID-352e0b9ee88af9f455c69b81: concurrency_limit: paused"
```

この問題を解決するには:

1. Rakeタスク`gitlab-rake gitlab:elastic:info`を使用して、**Indexing queues**のステータスを確認します。
1. **Concurrency limit code queue**がゼロでない場合は、**コードインデックスの並行処理**の値を確認してください。低すぎる値はインデックス作成の進行を妨げる可能性があります。この値を増やし、Rakeタスクで進行状況を確認することを検討してください。

## Elasticsearchサーバーを切り替えた後に検索結果がない {#no-search-results-after-switching-elasticsearch-servers}

データベース、リポジトリ、およびWikiを再インデックス作成するには、[インスタンスをインデックス作成](../../advanced_search/elasticsearch.md#index-the-instance)します。

## `error: elastic: Error 429 (Too Many Requests)`でインデックス作成が失敗する {#indexing-fails-with-error-elastic-error-429-too-many-requests}

`Search::Elastic::CommitIndexerWorker` Sidekiqワーカーがインデックス作成中にこのエラーで失敗する場合、通常、Elasticsearchがインデックス作成リクエストの並行処理に追いついていないことを意味します。対処するには、以下の設定を変更してください:

- インデックス作成のスループットを減らすには、`Bulk request concurrency`を減らすことができます（[高度な検索設定](../../advanced_search/elasticsearch.md#advanced-search-configuration)を参照）。これはデフォルトで`10`に設定されていますが、同時インデックス作成操作の数を減らすために1まで低く変更することができます。
- `Bulk request concurrency`の変更が役立たなかった場合、[ルーティングルール](../../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)オプションを使用して[インデックス作成ジョブを特定のSidekiqノードのみに制限](../../advanced_search/elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes)し、それによってインデックス作成リクエストの数を減らすことができます。

## エラー: `Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge` {#error-elasticsearchtransporttransporterrorsrequestentitytoolarge}

```plaintext
[413] {"Message":"Request size exceeded 10485760 bytes"}
```

この例外は、Elasticsearchクラスターが特定のサイズ（この場合は10 MiB）を超えるリクエストを拒否するように構成されている場合に発生します。これは`http.max_content_length`設定と`elasticsearch.yml`の対応です。それをより大きなサイズに増やし、Elasticsearchクラスターを再起動してください。

AWSには、基盤となるインスタンスのサイズに基づいてHTTPリクエストペイロードの最大サイズに関する[ネットワーク制限](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/limits.html#network-limits)があります。最大バルクリクエストサイズを10 MiBよりも低い値に設定してください。

## インデックス作成が非常に遅い、または`rejected execution of coordinating operation`で失敗する {#indexing-is-very-slow-or-fails-with-rejected-execution-of-coordinating-operation}

Elasticsearchノードによって拒否されるバルクリクエストは、負荷と利用可能なメモリの不足が原因である可能性があります。Elasticsearchクラスターが[システム要件](../../advanced_search/elasticsearch.md#system-requirements)を満たしており、バルク操作を実行するのに十分なリソースがあることを確認してください。エラー[「429 (Too Many Requests)」](#indexing-fails-with-error-elastic-error-429-too-many-requests)も参照してください。

## `strict_dynamic_mapping_exception`でインデックス作成が失敗する {#indexing-fails-with-strict_dynamic_mapping_exception}

メジャーアップグレードを行う前にすべての[高度な検索移行が完了していなかった](../../advanced_search/elasticsearch.md#all-migrations-must-be-finished-before-doing-a-major-upgrade)場合、インデックス作成が失敗する可能性があります。このエラーには、大規模なSidekiqバックログが伴う場合があります。インデックス作成の失敗を修正するには、データベース、リポジトリ、およびWikiを再インデックス作成する必要があります。

1. Sidekiqが追いつくようにインデックス作成を一時停止します:

   ```shell
   sudo gitlab-rake gitlab:elastic:pause_indexing
   ```

1. [インデックスをゼロから再作成する](#last-resort-to-recreate-an-index)。
1. インデックス作成を再開します:

   ```shell
   sudo gitlab-rake gitlab:elastic:resume_indexing
   ```

## `elasticsearch_pause_indexing setting is enabled`でインデックス作成が一時停止し続ける {#indexing-keeps-pausing-with-elasticsearch_pause_indexing-setting-is-enabled}

検索を実行しても新しいデータが検出されないことに気づくかもしれません。

このエラーは、新しいデータが適切にインデックス化されていない場合に発生します。

このエラーを解決するには、[データを再インデックス作成](../../advanced_search/elasticsearch.md#zero-downtime-reindexing)してください。

ただし、再インデックス作成時に、インデックス作成プロセスが一時停止し続けるというエラーが発生し、Elasticsearchログに以下の表示がされることがあります:

```shell
"message":"elasticsearch_pause_indexing setting is enabled. Job was added to the waiting queue"
```

再インデックス作成でこの問題が解決せず、手動でインデックス作成プロセスを一時停止しなかった場合、このエラーは2つのGitLabインスタンスが1つのElasticsearchクラスターを共有しているために発生している可能性があります。

このエラーを解決するには、GitLabインスタンスの1つをElasticsearchクラスターの使用から切断してください。

詳細については、[イシュー3421](https://gitlab.com/gitlab-org/gitlab/-/issues/3421)を参照してください。

## `too_many_clauses: maxClauseCount is set to 1024`で検索が失敗する {#search-fails-with-too_many_clauses-maxclausecount-is-set-to-1024}

このエラーは、クエリの句が`indices.query.bool.max_clause_count`設定で定義されている数よりも多い場合に発生します:

- [Elasticsearch 7.17以前](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/search-settings.html)では、デフォルト値は`1024`です。
- [Elasticsearch 8.0](https://www.elastic.co/guide/en/elasticsearch/reference/8.0/search-settings.html)では、デフォルト値は`4096`です。
- [Elasticsearch 8.1以降](https://www.elastic.co/guide/en/elasticsearch/reference/8.1/search-settings.html)では、設定は非推奨であり、値は動的に決定されます。

この問題を解決するには、値を増やすか、Elasticsearch 8.1以降にアップグレードしてください。値を増やすと、パフォーマンスの低下につながる可能性があります。

## エラー: `disk usage exceeded flood-stage watermark, index has read-only-allow-delete block` {#error-disk-usage-exceeded-flood-stage-watermark-index-has-read-only-allow-delete-block}

このエラーは、Elasticsearchクラスターにディスク容量が危機的に低いノードが少なくとも1つある場合に発生します。デフォルトの透かししきい値である95%を超えるクラスターは、その後のすべての書き込み操作を防止する読み取り専用ブロックを強制します。このブロックにより、新しいインデックス操作が失敗し、古い検索結果が生じる可能性があります。

以下のRakeタスクでクラスターが読み取り専用モードかどうかを確認できます:

```shell
sudo gitlab-rake gitlab:elastic:info
```

`blocks.write`または`blocks.read_only_allow_delete`が`true`であることを示す出力を探してください。

Elasticsearchクラスターのディスク使用量を確認するには、以下のコマンドを実行してください:

```shell
curl --request GET '<your_ES_cluster>:9200/_cat/allocation?v&pretty'
```

この問題を解決するには、フルノードのディスクボリュームを増やしてください。以下のRakeタスクでクラスターサイズを見積もることができます:

```shell
sudo gitlab-rake gitlab:elastic:estimate_cluster_size
```

## インデックスを再作成する最後の手段 {#last-resort-to-recreate-an-index}

何らかの理由でデータがインデックス化されずキューに入っていない場合、またはインデックスが何らかの状態で移行を進めることができない場合があります。[ログを確認する](access.md#view-logs)ことで、問題の根本原因をトラブルシューティングするのが常に最善です。

最後の手段として、インデックスをゼロから再作成することができます。小規模なGitLabインストールの場合、インデックスの再作成は一部の問題を解決する迅速な方法となり得ます。しかし、大規模なGitLabインストールの場合、この方法は非常に長い時間がかかる可能性があります。インデックス作成が完了するまで、インデックスは正しい検索結果を表示しません。インデックス作成の実行中に、**高度な検索による検索**チェックボックスをクリアすることができます。

以前の警告を読み、続行したい場合は、以下のRakeタスクを実行して全体のインデックスをゼロから再作成する必要があります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
sudo gitlab-rake gitlab:elastic:index
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:elastic:index
```

{{< /tab >}}

{{< /tabs >}}

## デッドキュー {#dead-queue}

項目は、1回再試行された後に失敗するとデッドキューに入ります。デッドキューの項目は手動による調査が必要であり、自動的に再試行されることはありません。

### ステータスの確認 {#check-the-status}

デッドキューのサイズと詳細を確認するには:

1. Railsコンソールを開始します:

   ```shell
   sudo gitlab-rails console
   ```

1. 失敗した項目の数を確認します:

   ```ruby
   Search::Elastic::DeadQueue.queue_size
   ```

1. 失敗した項目の詳細を検査します:

   ```ruby
   Search::Elastic::DeadQueue.queued_items
   ```

   このコマンドは、各キーがシャード番号であり、各値が`[spec, score]`ペアの配列であるハッシュを返します。仕様には、失敗した項目に関する情報が含まれています。

### 項目の再試行 {#retry-items}

再試行したい項目をキューに入れます。これらの項目が再び失敗した場合、それらはデッドキューに戻されます。

デッドキュー内の項目を再試行するには:

1. Railsコンソールを開始します:

   ```shell
   sudo gitlab-rails console
   ```

1. デッドキューから再試行キューに項目を移動します:

   ```ruby
   specs = Search::Elastic::DeadQueue.queued_items.flat_map { |_, items| items.map { |spec, _| spec } }

   Search::Elastic::DeadQueue.clear_tracking!
   Search::Elastic::RetryQueue.track!(*specs)
   ```

1. （オプション）[インデックス作成状態を確認します](../../advanced_search/elasticsearch.md#check-indexing-status)。

デッドキュー内の項目を再試行せずに破棄するには、以下のコマンドを実行します:

```ruby
Search::Elastic::DeadQueue.clear_tracking!
```

### GitLabサポートに連絡する {#contact-gitlab-support}

デッドキューの項目についてヘルプが必要な場合は、以下の情報をGitLabサポートと共有してください:

- `Search::Elastic::DeadQueue.queue_size`の出力
- 使用しているElasticsearchおよびGitLabのバージョン
- インデックス作成の失敗がいつ始まったか
- 関連するアプリケーションログまたはエラーメッセージ

## Elasticsearchのパフォーマンスを向上させる {#improve-elasticsearch-performance}

パフォーマンスを向上させるには、次のことを確認してください:

- ElasticsearchサーバーはGitLabと同じノードで実行されて**等しくない**ことを確認してください。
- Elasticsearchサーバーに十分なRAMとCPUコアがあること。
- シャーディングが使用されていることに**等しい**。

ここでさらに詳しく説明すると、ElasticsearchがGitLabと同じサーバーで実行されている場合、リソース競合が発生する可能性が**very**高いです。理想的には、十分なリソースを必要とするElasticsearchは、独自のサーバー（LogstashおよびKibanaと組み合わせることも可能）で実行されるべきです。

Elasticsearchに関しては、RAMが重要なリソースです。Elasticsearch自身が推奨しています:

- 非本番環境インスタンスの場合、**At least**8 GBのRAM。
- 本番環境インスタンスの場合、**At least**16 GBのRAM。
- 理想的には、64 GBのRAM。

CPUに関しては、Elasticsearchは少なくとも2つのCPUコアを推奨していますが、一般的なセットアップでは最大8コアを使用すると述べています。サーバー仕様の詳細については、[Elasticsearchハードウェアガイド](https://www.elastic.co/guide/en/elasticsearch/guide/current/hardware.html)を確認してください。

明白なこと以外に、シャーディングが関係してきます。シャーディングはElasticsearchのコアな部分です。これにより、インデックスの水平スケーリングが可能になり、大量のデータを扱う場合に役立ちます。

GitLabがインデックス作成を行う方法では、インデックス化されるドキュメントの**huge**量があります。シャーディングを使用することで、各シャードがLuceneインデックスであるため、Elasticsearchがデータを特定する能力を高速化できます。

シャーディングを使用していない場合、本番環境でElasticsearchの使用を開始すると問題が発生する可能性があります。

1つのシャードのみを持つインデックスには**no scale factor**、ある程度の頻度で呼び出されると問題が発生する可能性があります。[Elasticsearchのキャパシティプランニングに関するドキュメント](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/capacity-planning.html)を参照してください。

シャーディングが使用されているかどうかを判断する最も簡単な方法は、[Elasticsearch Health API](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-health.html)の出力を確認することです:

- 赤はクラスターがダウンしていることを意味します。
- 黄はシャーディング/レプリケーションなしで稼働していることを意味します。
- 緑は正常であること（稼働中、シャーディング中、レプリケーション中）を意味します。

本番用途では、常に緑である必要があります。

これらの手順を超えて、マージやキャッシュなど、より複雑な確認事項に入ります。これらは複雑になる可能性があり、習得には時間がかかるため、さらに深く掘り下げる必要がある場合はElasticsearchの専門家とエスカレート/ペアを組むのが最善です。

GitLabサポートに問い合わせてください。ただし、これは熟練したElasticsearch管理者がより多くの経験を持っている可能性が高い問題です。

## 遅い初期インデックス作成 {#slow-initial-indexing}

GitLabインスタンスのデータが多いほど、インデックス作成にかかる時間は長くなります。Rakeタスク`sudo gitlab-rake gitlab:elastic:estimate_cluster_size`でクラスターサイズを見積もることができます。

### コードドキュメントの場合 {#for-code-documents}

コード、コミット、およびWikiを効率的にインデックス作成するために、十分なSidekiqノードとプロセスがあることを確認してください。初期インデックス作成が遅い場合は、[専用のSidekiqノードまたはプロセス](../../advanced_search/elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes)を検討してください。

### 非コードドキュメントの場合 {#for-non-code-documents}

初期インデックス作成が遅いものの、Sidekiqに十分なノードとプロセスがある場合は、GitLabで高度な検索ワーカー設定を調整できます。**インデックス作成ワーカーをキューに再度追加**の場合、デフォルト値は`false`です。**非コードインデックス作成のシャード数**の場合、デフォルト値は`2`です。これらの設定により、インデックス作成は1分あたり2000ドキュメントに制限されます。

前提条件: 

- 管理者アクセス権が必要です。

ワーカー設定を調整するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **高度な検索**を展開します。
1. **インデックス作成ワーカーをキューに再度追加**チェックボックスを選択します。
1. **非コードインデックス作成のシャード数**テキストボックスに、`2`よりも大きい値を入力します。
1. **変更を保存**を選択します。
