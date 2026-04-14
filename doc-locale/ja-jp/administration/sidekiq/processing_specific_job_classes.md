---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 特定のジョブクラスの処理
---

> [!warning]
> 
> これらは高度な設定です。GitLab.comで使用されていますが、ほとんどのGitLabインスタンスでは、すべてのキューをリッスンするプロセスを追加するだけで十分です。これは、[リファレンスアーキテクチャ](../reference_architectures/_index.md)で説明されているのと同じアプローチです。

ほとんどのGitLabインスタンスは、[すべてのキューをリッスンするすべてのプロセス](extra_sidekiq_processes.md#start-multiple-processes)を持つ必要があります。

別の方法として、[ルーティングルール](#routing-rules)を使用して、アプリケーション内の特定のジョブクラスを設定済みのキュー名に転送することができます。そうすると、Sidekiqプロセスは設定済みの少数のキューのみをリッスンすればよくなります。そうすることで、Redisへの負荷が軽減され、これは大規模なデプロイにおいて重要です。

## ルーティングルール {#routing-rules}

{{< history >}}

- [デフォルトルーティングルールの値](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97908)はGitLab 15.4で導入されました。
- キューセレクタはGitLab 17.0で[ルーティングルールに置き換えられました](https://gitlab.com/gitlab-org/gitlab/-/issues/390787)。

{{< /history >}}

> [!note]
> 
> メーラーのジョブはルーティングルールではルーティングできず、常に`mailers`キューに送られます。ルーティングルールを使用する場合、少なくとも1つのプロセスが`mailers`キューをリッスンしていることを確認してください。通常、これは`default`キューと並べて配置できます。

ほとんどのGitLabインスタンスでは、Sidekiqキューを管理するためにルーティングルールを使用することをお勧めします。これにより、管理者は、ジョブクラスのグループの属性に基づいて単一のキュー名を選択できます。この構文は、`[query, queue]`のペアの順序付き配列です:

1. このクエリは[ワーカーマッチングクエリ](#worker-matching-query)です。
1. キュー名は有効なSidekiqキュー名である必要があります。キュー名（queue_name）が`nil`または空の文字列の場合、ワーカーはワーカー名から生成されるキューにルーティングされます。詳細については、[利用可能なジョブクラスのリスト](#list-of-available-job-classes)を参照してください）。キュー名は、利用可能なジョブクラスのリストにある既存のキュー名と一致する必要はありません。
1. 最初にワーカーに一致するクエリがそのワーカーに対して選択され、それ以降のルールは無視されます。

### ルーティングルール移行 {#routing-rules-migration}

Sidekiqルーティングルールが変更された後、特に長いキューを持つシステムでは、移行の際にジョブが完全に失われないように注意する必要があります。移行は、[Sidekiqジョブ移行](sidekiq_job_migration.md)で述べられている移行手順に従って実行できます。

### スケールされたアーキテクチャでのルーティングルール {#routing-rules-in-a-scaled-architecture}

ルーティングルールは、アプリケーションの設定の一部であるため、すべてのGitLabノード（特にGitLab RailsおよびSidekiqノード）で同じである必要があります。

### 詳細な例 {#detailed-example}

これは、さまざまな可能性を示すことを目的とした包括的な例です。A [Helmチャートの例も利用できます](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/#queues)。これらは推奨事項ではありません。

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   sidekiq['routing_rules'] = [
     # Route all non-CPU-bound workers that are high urgency to `high-urgency` queue
     ['resource_boundary!=cpu&urgency=high', 'high-urgency'],
     # Route all database, gitaly and global search workers that are throttled to `throttled` queue
     ['feature_category=database,gitaly,global_search&urgency=throttled', 'throttled'],
     # Route all workers having contact with outside world to a `network-intensive` queue
     ['has_external_dependencies=true|feature_category=hooks|tags=network', 'network-intensive'],
     # Wildcard matching, route the rest to `default` queue
     ['*', 'default']
   ]
   ```

   `queue_groups`は、これらの生成されたキュー名と一致するように設定できます。例:

   ```ruby
   sidekiq['queue_groups'] = [
     # Run two high-urgency processes
     'high-urgency',
     'high-urgency',
     # Run one process for throttled, network-intensive
     'throttled,network-intensive',
     # Run one 'catchall' process on the default and mailers queues
     'default,mailers'
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## ワーカーマッチングクエリ {#worker-matching-query}

GitLabは、ルーティングルールによって使用されるワーカーの属性に基づいてワーカーを照合するためのクエリ構文を提供します。1つのクエリには2つのコンポーネントが含まれます:

- 選択できる属性。
- クエリの構築に使用される演算子。

### 利用可能な属性 {#available-attributes}

キューマッチングクエリは、GitLab開発ドキュメントのSidekiqスタイルガイドで説明されているワーカーの属性に基づいて機能します。私たちは、ワーカーの属性のサブセットに基づいたクエリをサポートしています:

- `feature_category` - キューが属するGitLabの機能カテゴリ。たとえば、`merge`キューは`source_code_management`カテゴリに属します。
- `has_external_dependencies` - キューが外部サービスに接続するかどうか。たとえば、すべてのインポーターでこれは`true`に設定されています。
- `urgency` - このキューのジョブが迅速に実行されることの重要度。`high`、`low`、`throttled`のいずれかです。たとえば、`authorized_projects`キューはユーザー権限を更新するために使用され、`high`の緊急度です。
- `worker_name` - ワーカー名。この属性を使用して特定のワーカーを選択します。利用可能なすべての名前は、以下の[ジョブクラスのリスト](#list-of-available-job-classes)で確認できます。
- `name` - ワーカー名から生成されるキュー名。この属性を使用して特定のキューを選択します。これはワーカー名から生成されるため、他のルーティングルールの結果に基づいて変更されることはありません。
- `resource_boundary` - キューが`cpu`、`memory`、または`unknown`によって制限されているかどうか。たとえば、`ProjectExportWorker`は、エクスポートのためにデータを保存する前にメモリに読み込む必要があるため、メモリに制約されます。
- `tags` - キューの短命な注釈。これらはリリースごとに頻繁に変更されることが予想され、完全に削除される可能性もあります。
- `queue_namespace` - 一部のワーカーはネームスペースでグループ化されており、`name`は`<queue_namespace>:`をプレフィックスとしています。たとえば、`cronjob:admin_email`のキュー`name`の場合、`queue_namespace`は`cronjob`です。この属性を使用してワーカーのグループを選択します。

`has_external_dependencies`はブール型の属性です。厳密に`true`という文字列のみがtrueと見なされ、それ以外はすべてfalseと見なされます。

`tags`はセットであり、これは`=`が交差するセットをチェックし、`!=`が互いに素なセットをチェックすることを意味します。たとえば、`tags=a,b`は`a`、`b`、またはその両方のタグを持つキューを選択します。`tags!=a,b`はそれらのどちらのタグも持たないキューを選択します。

### 利用可能な演算子 {#available-operators}

ルーティングルールは、優先順位が高い順から低い順に、次の演算子をサポートしています:

- `|` - 論理`OR`演算子。たとえば、`query_a|query_b`（ここで`query_a`と`query_b`は他の演算子で構成されるクエリです）は、いずれかのクエリに一致するキューを含みます。
- `&` - 論理`AND`演算子。たとえば、`query_a&query_b`（ここで`query_a`と`query_b`は他の演算子で構成されるクエリです）は、両方のクエリに一致するキューのみを含みます。
- `!=` - `NOT IN`演算子。たとえば、`feature_category!=issue_tracking`は`issue_tracking`機能カテゴリのすべてのキューを除外するします。
- `=` - `IN`演算子。たとえば、`resource_boundary=cpu`はCPUバウンドのすべてのキューを含みます。
- `,` - 連結セット演算子。たとえば、`feature_category=continuous_integration,pages`は`continuous_integration`カテゴリまたは`pages`カテゴリのいずれかのすべてのキューを含みます。この例はOR演算子を使用しても可能ですが、簡潔になり、優先順位も低くなります。

この構文の演算子の優先順位は固定されており、`AND`を`OR`よりも高い優先順位にすることはできません。

以前にドキュメント化された標準キューグループ構文と同様に、キューグループ全体としての単一の`*`はすべてのキューを選択します。

### 利用可能なジョブクラスのリスト {#list-of-available-job-classes}

既存のSidekiqジョブクラスとキューのリストについては、以下のファイルを確認してください:

- [すべてのGitLabエディションのキュー](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/all_queues.yml)
- [GitLab Enterprise Editions専用のキュー](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/all_queues.yml)
