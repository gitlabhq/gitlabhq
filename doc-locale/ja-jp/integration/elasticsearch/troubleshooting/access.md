---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Elasticsearchアクセストラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Elasticsearchアクセスを操作する際、以下の問題が発生する可能性があります。

## Railsコンソールで設定を割り当てます {#set-configurations-in-the-rails-console}

[Railsコンソール](../../../administration/operations/rails_console.md#starting-a-rails-console-session)セッションを開始するを参照してください。

### 属性のリストを取得する {#list-attributes}

利用可能な属性をすべてリスト表示するには:

1. Railsコンソールを開きます（`sudo gitlab-rails console`）。
1. 次のコマンドを実行します:

```ruby
ApplicationSetting.last.attributes
```

この出力には、[Elasticsearchインテグレーション](../../advanced_search/elasticsearch.md)で利用可能なすべての設定（`elasticsearch_indexing`、`elasticsearch_url`、`elasticsearch_replicas`、`elasticsearch_pause_indexing`など）が含まれています。

### 属性を設定 {#set-attributes}

Elasticsearchインテグレーションの設定を割り当てるには、次のようなコマンドを実行します:

```ruby
ApplicationSetting.last.update(elasticsearch_url: '<your ES URL and port>')

#or

ApplicationSetting.last.update(elasticsearch_indexing: false)
```

### 属性を取得 {#get-attributes}

[Elasticsearchインテグレーション](../../advanced_search/elasticsearch.md)またはRailsコンソールで設定が割り当てられているかを確認するには、次のようなコマンドを実行します:

```ruby
Gitlab::CurrentSettings.elasticsearch_url

#or

Gitlab::CurrentSettings.elasticsearch_indexing
```

### キーの変更 {#change-the-password}

Elasticsearchのパスワードを変更するには、次のコマンドを実行します:

```ruby
es_url = Gitlab::CurrentSettings.current_application_settings

# Confirm the current Elasticsearch URL
es_url.elasticsearch_url

# Set the Elasticsearch URL
es_url.elasticsearch_url = "http://<username>:<password>@your.es.host:<port>"

# Save the change
es_url.save!
```

## ログを表示 {#view-logs}

Elasticsearchインテグレーションの問題を特定するための最も価値のあるツールの1つは、ログです。このインテグレーションに最も関連性の高いログは次のとおりです:

1. [`sidekiq.log`](../../../administration/logs/_index.md#sidekiqlog) - すべてのインデックス作成はSidekiqで行われるため、Elasticsearchインテグレーションに関連するログの多くは、このファイルにあります。
1. [`elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog) - Elasticsearchに固有の追加ログがあり、このファイルに送信されます。これには、検索、インデックス作成、または移行に関する診断情報が含まれている可能性があります。

一般的な落とし穴と、その克服方法を以下に示します。

## GitLabインスタンスがElasticsearchを使用していることを確認します {#verify-that-your-gitlab-instance-is-using-elasticsearch}

GitLabインスタンスがElasticsearchを使用していることを確認するには:

- 検索を実行するときは、検索結果ページの右上隅に**Advanced search is enabled**（高度な検索が有効になっている） ことが表示されていることを確認してください。

- **管理者**エリアの**設定** > **検索**で、高度な検索設定が選択されていることを確認します。

  これらの同じ設定は、必要に応じてRailsコンソールから取得できます:

  ```ruby
  ::Gitlab::CurrentSettings.elasticsearch_search?         # Whether or not searches will use Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_indexing?       # Whether or not content will be indexed in Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_limit_indexing? # Whether or not Elasticsearch is limited only to certain projects/namespaces
  ```

- 検索がElasticsearchを使用していることを確認するには、[Railsコンソール](../../../administration/operations/rails_console.md)にアクセスし、次のコマンドを実行します:

  ```rails
  u = User.find_by_email('email_of_user_doing_search')
  s = SearchService.new(u, {:search => 'search_term'})
  pp s.search_objects.class
  ```

  最後のコマンドからの出力がここでのキーです。次のように表示される場合:

  - `ActiveRecord::Relation`の場合、Elasticsearchを使用**it is not**（していません）。
  - `Kaminari::PaginatableArray`の場合、Elasticsearchを**it is**（使用しています）。

- Elasticsearchが特定のネームスペースに制限されていて、Elasticsearchが特定のプロジェクトまたはネームスペースに使用されているかどうかを知る必要がある場合は、Railsコンソールを使用できます:

  ```ruby
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Namespace.find_by_full_path("/my-namespace"))
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Project.find_by_full_path("/my-namespace/my-project"))
  ```

## エラー: `User: anonymous is not authorized to perform: es:ESHttpGet` {#error-user-anonymous-is-not-authorized-to-perform-eseshttpget}

AWS OpenSearchまたはElasticsearchでドメインレベルのアクセス制御ポリシーを使用する場合、AWSロールは正しいGitLabノードに割り当てられません。GitLab RailsとSidekiqのノードは、検索クラスターと通信するための権限を必要とします。

```plaintext
User: anonymous is not authorized to perform: es:ESHttpGet because no resource-based policy allows the es:ESHttpGet
action
```

これを修正するには、AWSロールが正しいGitLabノードに割り当てられていることを確認してください。

## 有効なリージョンが指定されていません {#no-valid-region-specified}

高度な検索でAWS認証を使用する場合、指定するリージョンは有効である必要があります。

## エラー: `no permissions for [indices:data/write/bulk]` {#error-no-permissions-for-indicesdatawritebulk}

IAMロールまたはAWS OpenSearch Dashboardsを使用して作成されたロールで、きめ細かいアクセス制御を使用する場合、次のエラーが発生する可能性があります:

```json
{
  "error": {
    "root_cause": [
      {
        "type": "security_exception",
        "reason": "no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"
      }
    ],
    "type": "security_exception",
    "reason": "no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"
  },
  "status": 403
}
```

これを修正するには、AWS OpenSearch Dashboardsで[ロールをユーザーにマップする](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-mapping)必要があります。

## AWS OpenSearch Serviceで追加のマスターユーザーを作成します {#create-additional-master-users-in-aws-opensearch-service}

ドメインを作成するときに、マスターユーザーを設定できます。このユーザーを使用すると、追加のマスターユーザーを作成できます。詳細については、[AWSドキュメント](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-more-masters)を参照してください。

権限を持つユーザーとロールを作成し、ユーザーをロールにマップするには、[OpenSearchドキュメント](https://opensearch.org/docs/latest/security/access-control/users-roles/)を参照してください。ロールに次の権限を含める必要があります:

```json
{
  "cluster_permissions": [
    "cluster_composite_ops",
    "cluster_monitor"
  ],
  "index_permissions": [
    {
      "index_patterns": [
        "gitlab*"
      ],
      "allowed_actions": [
        "data_access",
        "manage_aliases",
        "search",
        "create_index",
        "delete",
        "manage"
      ]
    },
    {
      "index_patterns": [
        "*"
      ],
      "allowed_actions": [
        "indices:admin/aliases/get",
        "indices:monitor/stats"
      ]
    }
  ]
}
```

## 開いているTCP接続プールの蓄積 {#accumulation-of-open-tcp-connections}

GitLab 17.11以降では、GitLabプロセスから外部サービスへの開いているTCP接続プールの増加に気付く場合があります。これらの接続プールは時間の経過とともに蓄積され、適切に閉じられません。

この問題は、GitLabでの接続プールのために、Faradayアダプターが`net_http`から`typhoeus`に切り替わることに関連しています。詳細については、[issue 550805](https://gitlab.com/gitlab-org/gitlab/-/issues/550805)を参照してください。

この問題を解決するには、[`elasticsearch_client_adapter`](../../../api/settings.md#available-settings)を`net_http`に設定します。
