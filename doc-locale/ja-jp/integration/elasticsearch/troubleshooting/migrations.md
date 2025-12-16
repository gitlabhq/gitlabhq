---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Elasticsearchの移行のトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Elasticsearchの移行の作業時に、以下のイシューが発生する可能性があります。

[`elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog)にエラーが含まれており、失敗した移行を再試行しても機能しない場合は、GitLabサポートにお問い合わせください。詳細については、[高度な検索の移行](../../advanced_search/elasticsearch.md#advanced-search-migrations)を参照してください。

## エラー: `Elasticsearch::Transport::Transport::Errors::BadRequest` {#error-elasticsearchtransporttransporterrorsbadrequest}

同様の例外が発生した場合は、正しいElasticsearchのバージョンがあり、[システム要件](../../advanced_search/elasticsearch.md#system-requirements)を満たしていることを確認してください。`sudo gitlab-rake gitlab:check`コマンドを使用して、バージョンを自動的に確認することもできます。

## エラー: `Faraday::TimeoutError (execution expired)` {#error-faradaytimeouterror-execution-expired}

プロキシを使用する場合は、ElasticsearchホストのIPアドレスを使用して、`gitlab_rails['env']`環境変数[`no_proxy`](https://docs.gitlab.com/omnibus/settings/environment-variables.html)という名前のカスタムを設定します。

## シングルノードElasticsearchクラスターのステータスが黄色から緑に変わらない {#single-node-elasticsearch-cluster-status-never-goes-from-yellow-to-green}

シングルノードElasticsearchクラスターの場合、機能クラスターのヘルスステータスは黄色です（緑にはなりません）。その理由は、プライマリシャードが割り当てられていますが、Elasticsearchがレプリカを割り当てることができる他のノードが存在しないため、レプリカを割り当てることができないためです。これは、[Amazon OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/aes-handling-errors.html#aes-handling-errors-yellow-cluster-status)サービスを使用している場合にも当てはまります。

{{< alert type="warning" >}}

レプリカの数を`0`に設定することはお勧めしません（これはGitLab Elasticsearchインテグレーションメニューでは許可されていません）。Elasticsearchノードをさらに追加する予定がある場合（合計1つ以上のElasticsearchの場合）、レプリカの数を`0`より大きい整数値に設定する必要があります。そうしないと、冗長性が不足します（1つのノードを失うと、インデックスが破損します）。

{{< /alert >}}

シングルノードElasticsearchクラスターのステータスを緑にする場合は、リスクを理解し、次のクエリを実行して、レプリカの数を`0`に設定します。クラスターは、シャードレプリカを作成しようとしなくなります。

```shell
curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
     --data '{
       "index" : {
         "number_of_replicas" : 0
       }
     }'
```

## エラー: `health check timeout: no Elasticsearch node available` {#error-health-check-timeout-no-elasticsearch-node-available}

インデックス作成プロセス中にSidekiqで`health check timeout: no Elasticsearch node available`エラーが発生した場合:

```plaintext
Gitlab::Elastic::Indexer::Error: time="2020-01-23T09:13:00Z" level=fatal msg="health check timeout: no Elasticsearch node available"
```

Elasticsearchインテグレーションメニューの**「URL」**フィールドの値の一部として、`http://`または`https://`を使用していない可能性があります。使用している[Go用Elasticsearchクライアント](https://github.com/olivere/elastic)が[URLのプレフィックスが有効として受け入れられる必要がある](https://github.com/olivere/elastic/commit/a80af35aa41856dc2c986204e2b64eab81ccac3a)ため、このフィールドで`http://`または`https://`のいずれかを使用していることを確認してください。URLの書式を修正したら、[インデックスを削除](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)して、[インスタンス](../../advanced_search/elasticsearch.md#enable-advanced-search)のコンテンツをインデックス作成し直してください。

## Elasticsearchは一部のサードパーティ製プラグインでは機能しません {#elasticsearch-does-not-work-with-some-third-party-plugins}

特定のサードパーティ製プラグインは、クラスターにバグを導入したり、インテグレーションと互換性がない可能性があります。

Elasticsearchクラスターにサードパーティ製プラグインがあり、インテグレーションが機能しない場合は、プラグインを無効にしてみてください。

## ElasticsearchワーカーがSidekiqをオーバーロードする {#elasticsearch-workers-overload-sidekiq}

場合によっては、ElasticsearchがGitLabに接続できなくなることがあります:

- Elasticsearchのパスワードが片側でのみ更新された(`Unauthorized [401] ... unable to authenticate user`エラー)。
- ファイアウォールまたはネットワーキングの問題により、接続が損なわれる(`Failed to open TCP connection to <ip>:9200`エラー)。

これらのエラーは、[`gitlab-rails/elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog)に記録されます。エラーを取得するには、[`jq`](../../../administration/logs/log_parsing.md)を使用します:

```shell
$ jq --raw-output 'select(.severity == "ERROR") | [.error_class, .error_message] | @tsv' \
    gitlab-rails/elasticsearch.log |
  sort | uniq -c
```

`Elastic`ワーカーと[Sidekiqジョブ](../../../administration/admin_area.md#background-jobs)も、以前のジョブが失敗した場合、Elasticsearchが頻繁にインデックス作成を再試行するため、はるかに頻繁に表示される可能性があります。[`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#usage)または`jq`を使用して、[Sidekiqログ](../../../administration/logs/_index.md#sidekiq-logs)のワーカーをカウントできます:

```shell
$ fast-stats --print-fields=count,score sidekiq/current
WORKER                            COUNT   SCORE
ElasticIndexBulkCronWorker          234  123456
ElasticIndexInitialBulkCronWorker   345   12345
Some::OtherWorker                    12     123
...

$ jq '.class' sidekiq/current | sort | uniq -c | sort -nr
 234 "ElasticIndexInitialBulkCronWorker"
 345 "ElasticIndexBulkCronWorker"
  12 "Some::OtherWorker"
...
```

この場合、オーバーロードされたGitLabノードの`free -m`も、予想外に高い`buff/cache`使用量を示します。

## エラー: `Couldn't load task status` {#error-couldnt-load-task-status}

インデックス作成し直すと、`Couldn't load task status`エラーが発生する可能性があります。`sliceId must be greater than 0 but was [-1]`エラーもElasticsearchホストに表示される場合があります。回避策として、[インデックスをゼロから再作成する](indexing.md#last-resort-to-recreate-an-index)か、GitLab 16.3にアップグレードすることを検討してください。

詳細については、[issue 422938](https://gitlab.com/gitlab-org/gitlab/-/issues/422938)を参照してください。

## エラー: `migration has failed with NoMethodError:undefined method` {#error-migration-has-failed-with-nomethoderrorundefined-method}

GitLab 15.11では、`BackfillProjectPermissionsInBlobs`移行が`elasticsearch.log`に次のエラーメッセージで失敗する可能性があります:

```shell
migration has failed with NoMethodError:undefined method `<<' for nil:NilClass, no retries left
```

`BackfillProjectPermissionsInBlobs`が唯一の失敗した移行である場合は、[修正](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118494)が含まれているGitLab 16.0の最新パッチバージョンにアップグレードできます。それ以外の場合は、高度な検索の機能には影響しないため、エラーを無視できます。

## `ElasticIndexInitialBulkCronWorker`および`ElasticIndexBulkCronWorker`ジョブが重複排除で停止している {#elasticindexinitialbulkcronworker-and-elasticindexbulkcronworker-jobs-stuck-in-deduplication}

GitLab 16.5以前、`ElasticIndexInitialBulkCronWorker`および`ElasticIndexBulkCronWorker`ジョブが重複排除で停止する可能性があります。このイシューにより、新しいインデックスを作成した後でも、高度な検索でドキュメントを適切にインデックス作成できなくなる可能性があります。GitLab 16.6では、インデックス作成を実行するバルクcronワーカーに対して`idempotent!`が[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135817)されました。

Sidekiqログには、次のエントリが含まれている可能性があります:

```shell
{"severity":"INFO","time":"2023-10-31T10:33:06.998Z","retry":0,"queue":"default","version":0,"queue_namespace":"cronjob","args":[],"class":"ElasticIndexInitialBulkCronWorker",
...
"idempotency_key":"resque:gitlab:duplicate:default:<value>","duplicate-of":"91e8673347d4dc84fbad5319","job_size_bytes":2,"pid":12047,"job_status":"deduplicated","message":"ElasticIndexInitialBulkCronWorker JID-5e1af9180d6e8f991fc773c6: deduplicated: until executing","deduplication.type":"until executing"}
```

この問題を解決するには、以下を実行します:

1. [Railsコンソール](../../../administration/operations/rails_console.md#starting-a-rails-console-session)セッションで、次のコマンドを実行します:

   ```shell
   idempotency_key = "<idempotency_key_from_log_entry>"
   duplicate_key = "resque:gitlab:#{idempotency_key}:cookie:v2"
   Gitlab::Redis::Queues.with { |c| c.del(duplicate_key) }
   ```

1. `<idempotency_key_from_log_entry>`をログの実際のエントリに置き換えます。
