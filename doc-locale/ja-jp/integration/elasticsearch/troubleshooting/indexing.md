---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Elasticsearchのインデックス作成と検索のトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Elasticsearchのインデックス作成または検索を使用しているときに、次の問題が発生する可能性があります。

## 空のインデックスを作成する {#create-an-empty-index}

インデックス作成の問題については、まず空のインデックスを作成してみてください。Elasticsearchインスタンスを調べて、`gitlab-production`インデックスが存在するかどうかを確認します。存在する場合は、Elasticsearchインスタンスのインデックスを手動で削除し、[`recreate_index`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) Rakeタスクから再作成してみてください。

それでも問題が発生する場合は、Elasticsearchインスタンスにインデックスを手動で作成してみてください。次の場合:

- インデックスを作成できない場合は、Elasticsearch管理者にお問い合わせください。
- インデックスを作成できる場合は、GitLabサポートにお問い合わせください。

## インデックス作成されたプロジェクトのステータスを確認する {#check-the-status-of-indexed-projects}

プロジェクトのインデックス作成中にエラーがないか確認できます。エラーは次で発生する可能性があります:

- GitLabインスタンス: 自分で修正できない場合は、GitLabサポートにガイダンスを求めてください。
- Elasticsearchインスタンス: [エラーがリストされていない場合](../../elasticsearch/troubleshooting/_index.md)は、Elasticsearch管理者にお問い合わせください。

インデックス作成でエラーが返されない場合は、次のRakeタスクを使用して、インデックス作成されたプロジェクトのステータスを確認してください:

- [`sudo gitlab-rake gitlab:elastic:index_projects_status`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)全体的なステータス
- [`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)インデックス作成されていない特定のプロジェクトの場合

インデックス作成が次のようになっている場合:

- 完了したら、GitLabサポートにお問い合わせください。
- 完了していない場合は、`sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=<project ID> ID_TO=<project ID>`を実行して、そのプロジェクトの再インデックスを作成してみてください。

再インデックスプロジェクトで次のエラーが表示される場合:

- GitLabインスタンス: GitLabサポートにお問い合わせください。
- Elasticsearchインスタンス、またはまったくエラーがない場合: Elasticsearch管理者に連絡して、インスタンスを確認してもらってください。

## GitLabの更新後に検索結果が表示されない {#no-search-results-after-updating-gitlab}

GitLabでは、インデックス作成戦略を継続的に更新し、新しいバージョンのElasticsearchをサポートすることを目指しています。インデックス作成の変更が行われた場合は、GitLabの更新後に[reindex](../../advanced_search/elasticsearch.md#zero-downtime-reindexing)が必要になる場合があります。

## すべてのリポジトリのインデックス作成後に検索結果が表示されない {#no-search-results-after-indexing-all-repositories}

{{< alert type="note" >}}

[ネームスペースのサブセット](../../advanced_search/elasticsearch.md#limit-the-amount-of-namespace-and-project-data-to-index)のみをインデックス作成するシナリオでは、これらの手順を使用しないでください。

{{< /alert >}}

[すべてのデータベースデータにインデックス作成されている](../../advanced_search/elasticsearch.md#enable-advanced-search)ことを確認してください。

UI検索で結果(ヒット)がない場合は、Railsコンソール(`sudo gitlab-rails console`)で同じ結果が表示されるかどうかを確認します:

```ruby
u = User.find_by_username('your-username')
s = SearchService.new(u, {:search => 'search_term', :scope => 'blobs'})
pp s.search_objects.to_a
```

それを超えて、[Elasticsearch Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html)を介して、データがElasticsearch側に表示されるかどうかを確認します:

```shell
curl --request GET <elasticsearch_server_ip>:9200/gitlab-production/_search?q=<search_term>
```

より[複雑なElasticsearch APIコール](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html)も可能です。

結果が次の場合は:

- 同期している場合は、[サポートされている構文](../../../user/search/advanced_search.md#syntax)を使用していることを確認してください。高度な検索では、[完全なサブストリング一致](https://gitlab.com/gitlab-org/gitlab/-/issues/325234)はサポートされていません。
- 一致しない場合、これはプロジェクトから生成されたドキュメントに問題があることを示しています。[そのプロジェクトを再インデックスする](../../advanced_search/elasticsearch.md#indexing-a-range-of-projects-or-a-specific-project)のが最善です。

特定の種類のデータの検索の詳細については、[Elasticsearch Index Scopes](../../advanced_search/elasticsearch.md#advanced-search-index-scopes)を参照してください。

## Elasticsearchサーバーの切り替え後に検索結果が表示されない {#no-search-results-after-switching-elasticsearch-servers}

データベース、リポジトリ、およびウィキを再インデックスするには、[インスタンスにインデックス作成します](../../advanced_search/elasticsearch.md#index-the-instance)。

## インデックス作成が`error: elastic: Error 429 (Too Many Requests)`で失敗する {#indexing-fails-with-error-elastic-error-429-too-many-requests}

`Search::Elastic::CommitIndexerWorker` Sidekiqワーカーがインデックス作成中にこのエラーで失敗する場合、通常は、Elasticsearchがインデックス作成リクエストの並行処理に追いつくことができないことを意味します。対処するには、次の設定を変更します:

- インデックス作成スループットを低下させるには、`Bulk request concurrency`を減らすことができます([高度な検索設定](../../advanced_search/elasticsearch.md#advanced-search-configuration)を参照)。これはデフォルトで`10`に設定されていますが、並行処理インデックス作成操作の数を減らすために、1まで下げることができます。
- `Bulk request concurrency`を変更しても効果がない場合は、[ルーティングルール](../../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)オプションを使用して、[特定のSidekiqノードにのみインデックス作成ジョブを制限](../../advanced_search/elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes)できます。これにより、インデックス作成リクエストの数を減らす必要があります。

## エラー: `Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge` {#error-elasticsearchtransporttransporterrorsrequestentitytoolarge}

```plaintext
[413] {"Message":"Request size exceeded 10485760 bytes"}
```

この例外は、Elasticsearchクラスターが特定のサイズ(この場合は10 MiB)を超えるリクエストを拒否するように構成されている場合に表示されます。これは、`http.max_content_length`の`elasticsearch.yml`設定に対応しています。サイズを大きくして、Elasticsearchクラスターを再起動します。

Amazon Web Servicesには、基盤となるインスタンスのサイズに基づいて、HTTPリクエストペイロードの最大サイズに関する[ネットワーク制限](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/limits.html#network-limits)があります。最大一括リクエストサイズを10 MiB未満の値に設定します。

## インデックス作成が非常に遅いか、`rejected execution of coordinating operation`で失敗する {#indexing-is-very-slow-or-fails-with-rejected-execution-of-coordinating-operation}

Elasticsearchノードによって拒否される一括リクエストは、負荷と利用可能なメモリの不足が原因である可能性があります。Elasticsearchクラスターが[システムの要件](../../advanced_search/elasticsearch.md#system-requirements)を満たし、一括操作を実行するのに十分なリソースがあることを確認してください。エラー[「429 (Too Many Requests)」](#indexing-fails-with-error-elastic-error-429-too-many-requests)も参照してください。

## インデックス作成が`strict_dynamic_mapping_exception`で失敗する {#indexing-fails-with-strict_dynamic_mapping_exception}

すべての[高度な検索移行が主要なアップグレードを行う前に完了していなかった](../../advanced_search/elasticsearch.md#all-migrations-must-be-finished-before-doing-a-major-upgrade)場合、インデックス作成が失敗する可能性があります。大規模なSidekiqバックログがこのエラーに伴う場合があります。インデックス作成の失敗を修正するには、データベース、リポジトリ、およびウィキを再インデックスする必要があります。

1. Sidekiqが追いつくことができるように、インデックス作成を一時停止します:

   ```shell
   sudo gitlab-rake gitlab:elastic:pause_indexing
   ```

1. [インデックスを最初から再作成する](#last-resort-to-recreate-an-index)。
1. インデックス作成を再開します:

   ```shell
   sudo gitlab-rake gitlab:elastic:resume_indexing
   ```

## インデックス作成が`elasticsearch_pause_indexing setting is enabled`で一時停止し続ける {#indexing-keeps-pausing-with-elasticsearch_pause_indexing-setting-is-enabled}

検索を実行しても、新しいデータが検出されないことに気付くかもしれません。

このエラーは、その新しいデータが適切にインデックス作成されていない場合に発生します。

このエラーを解決するには、[データを再インデックスします](../../advanced_search/elasticsearch.md#zero-downtime-reindexing)。

ただし、再インデックス時に、インデックス作成プロセスが一時停止し続け、Elasticsearchログに次のように表示されるエラーが発生する場合があります:

```shell
"message":"elasticsearch_pause_indexing setting is enabled. Job was added to the waiting queue"
```

再インデックスでこの問題を解決できず、インデックス作成プロセスを手動で一時停止しなかった場合、2つのGitLabインスタンスが1つのElasticsearchクラスターを共有しているために、このエラーが発生している可能性があります。

このエラーを解決するには、いずれかのGitLabインスタンスをElasticsearchクラスターの使用から切断します。

詳細については、[issue 3421](https://gitlab.com/gitlab-org/gitlab/-/issues/3421)を参照してください。

## 検索が`too_many_clauses: maxClauseCount is set to 1024`で失敗する {#search-fails-with-too_many_clauses-maxclausecount-is-set-to-1024}

このエラーは、クエリに`indices.query.bool.max_clause_count`設定で定義されているよりも多くの句がある場合に発生します:

- [Elasticsearch 7.17以前の場合](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/search-settings.html)、デフォルト値は`1024`です。
- [Elasticsearch 8.0以降の場合](https://www.elastic.co/guide/en/elasticsearch/reference/8.0/search-settings.html)、デフォルト値は`4096`です。
- [Elasticsearch 8.1以降の場合](https://www.elastic.co/guide/en/elasticsearch/reference/8.1/search-settings.html)、設定は非推奨となり、値は動的に決定されます。

この問題を解決するには、値を大きくするか、Elasticsearch 8.1以降にアップグレードします。値を大きくすると、パフォーマンスが低下する可能性があります。

## インデックスを再作成する最後の手段 {#last-resort-to-recreate-an-index}

何らかの理由でデータがインデックス作成されず、キューにない場合や、インデックスが移行を続行できない状態になっている場合があります。[ログを表示する](access.md#view-logs)ことで、問題の根本原因のトラブルシューティングを試みるのが常に最善です。

最後の手段として、インデックスを最初から再作成できます。小規模なGitLabインストールの場合は、インデックスを再作成すると、いくつかの問題を迅速に解決できます。ただし、大規模なGitLabインストールの場合は、この方法に非常に時間がかかる可能性があります。インデックス作成が完了するまで、インデックスに正しい検索結果は表示されません。インデックス作成の実行中に、**高度な検索で検索**チェックボックスをオフにすることをお勧めします。

前の注意をお読みになり、続行する場合は、次のRakeタスクを実行して、インデックス全体を最初から再作成する必要があります。

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

## Elasticsearchのパフォーマンスを向上させる {#improve-elasticsearch-performance}

パフォーマンスを向上させるには、以下を確認してください:

- ElasticsearchサーバーがGitLabと同じノードで実行**等しくない**。
- Elasticsearchサーバーに十分なRAMとCPUコアがある。
- シャーディングが使用**等しい**。

詳細については、ElasticsearchがGitLabと同じサーバーで実行されている場合、リソースの競合が発生する可能性が**very**（非常に）高くなります。理想的には、豊富なリソースを必要とするElasticsearchは、独自のサーバー(LogstashとKibanaと組み合わせることも可能)で実行する必要があります。

Elasticsearchに関しては、RAMがキーリソースです。Elasticsearch自体は次のように推奨しています:

- 非本番環境インスタンスの場合は、**At least**（少なくとも） 8 GBのRAM。
- 本番環境インスタンスの場合は、**At least**（少なくとも） 16 GBのRAM。
- 理想的には、64 GBのRAM。

CPUの場合、Elasticsearchは少なくとも2つのCPUコアを推奨していますが、Elasticsearchは一般的な設定では最大8つのコアを使用すると述べています。サーバーの仕様の詳細については、[Elasticsearchハードウェアガイド](https://www.elastic.co/guide/en/elasticsearch/guide/current/hardware.html)を確認してください。

明白なこと以外に、シャーディングが関係してきます。シャーディングはElasticsearchの中核となる部分です。これにより、インデックスの水平スケールが可能になり、大量のデータを処理する場合に役立ちます。

GitLabがインデックス作成を行う方法では、**huge**（大量の）ドキュメントがインデックス作成されています。シャーディングを使用すると、各シャードがLuceneインデックスであるため、Elasticsearchがデータを検索する能力を高速化できます。

シャーディングを使用していない場合、本番環境でElasticsearchの使用を開始すると、問題が発生する可能性があります。

1つのシャードしかないインデックスには、**no scale factor**（スケールファクターはありません）。また、ある程度の頻度で呼び出すと問題が発生する可能性があります。[容量計画に関するElasticsearchドキュメント](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/capacity-planning.html)を参照してください。

シャーディングが使用されているかどうかを判断する最も簡単な方法は、[Elasticsearch Health API](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-health.html)の出力を確認することです:

- 赤は、クラスターがダウンしていることを意味します。
- 黄色は、シャーディング/レプリケーションなしで起動していることを意味します。
- 緑は、正常(シャーディング、レプリケーション)であることを意味します。

本番環境で使用する場合は、常に緑色にする必要があります。

これらの手順以外にも、マージやキャッシュなど、確認するべきより複雑なことがいくつかあります。これらは複雑になる可能性があり、学習には時間がかかるため、これらをさらに深く掘り下げる必要がある場合は、Elasticsearchのエキスパートにエスカレート/ペアリングするのが最善です。

GitLabサポートにお問い合わせください。ただし、これは熟練したElasticsearch管理者の方がより多くの経験を持っている可能性があります。

## 初期インデックス作成が遅い {#slow-initial-indexing}

GitLabインスタンスのデータが多いほど、インデックス作成にかかる時間が長くなります。Rakeタスク`sudo gitlab-rake gitlab:elastic:estimate_cluster_size`を使用して、クラスターサイズを見積もることができます。

### コードドキュメントの場合 {#for-code-documents}

コード、コミット、およびウィキを効率的にインデックス作成するために、十分なSidekiqノードとプロセスがあることを確認してください。初期インデックス作成が遅い場合は、[専用のSidekiqノードまたはプロセス](../../advanced_search/elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes)を検討してください。

### コード以外のドキュメントの場合 {#for-non-code-documents}

初期インデックス作成が遅いものの、Sidekiqに十分なノードとプロセスがある場合は、GitLabで高度な検索ワーカー設定を調整できます。**インデックス作成ワーカーをキューに再度追加**の場合、デフォルト値は`false`です。**非コードインデックス作成のシャード数**の場合、デフォルト値は`2`です。これらの設定により、インデックス作成は1分あたり2000ドキュメントに制限されます。

ワーカー設定を調整するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **検索**を選択します。
1. **高度な検索**を展開します。
1. **インデックス作成ワーカーをキューに再度追加**チェックボックスを選択します。
1. **非コードインデックス作成のシャード数**テキストボックスに、`2`より大きい値を入力します。
1. **変更を保存**を選択します。
