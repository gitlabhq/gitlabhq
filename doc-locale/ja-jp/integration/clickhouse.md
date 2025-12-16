---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: ClickHouseインテグレーションガイドライン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版（Beta）は、GitLab Self-ManagedとGitLab Dedicatedで利用可能です

{{< /details >}}

{{< alert type="note" >}}

[このエピック](https://gitlab.com/groups/gitlab-com/gl-infra/data-access/dbo/-/epics/29)で、GitLab Self-ManagedのClickHouseサポートに関する計画の詳細をご覧ください。

{{< /alert >}}

{{< alert type="note" >}}

GitLab DedicatedのClickHouseサポートに関する詳細は、[GitLab DedicatedのClickHouse](../subscriptions/gitlab_dedicated/_index.md#clickhouse)を参照してください。

{{< /alert >}}

[ClickHouse](https://clickhouse.com)は、オープンソースのカラム型データベース管理システムです。大規模なデータセット全体で、効率的にフィルタリング、集計、クエリを実行できます。

ClickHouseは、GitLabのセカンダリデータストアです。特定のデータのみがClickHouseに保存され、[GitLab DuoとSDLCトレンド](../user/analytics/duo_and_sdlc_trends.md)や[CI分析](../ci/runners/runner_fleet_dashboard.md#enable-more-ci-analytics-features-with-clickhouse)などの高度な分析機能に使用されます。

ClickHouseをGitLabに接続する方法は2つあります:

- 推奨。[ClickHouse Cloud](https://clickhouse.com/cloud)を使用する。
- [独自のClickHouseを持ち込む](https://clickhouse.com/docs/en/install)。詳細については、[GitLab Self-Managedに関するClickHouseの推奨事項](https://clickhouse.com/docs/en/install#recommendations-for-self-managed-clickhouse)を参照してください。

## サポートされているClickHouseバージョン {#supported-clickhouse-versions}

| 最初のGitLabバージョン | ClickHouseバージョン | コメント |
|----------------------|---------------------|---------|
| 17.7.0               | 23.x（24.x、25.x）   | ClickHouse 24.xおよび25.xを使用するには、[回避策セクション](#database-schema-migrations-on-gitlab-1800-and-earlier)を参照してください。 |
| 18.1.0               | 23.x、24.x、25.x    |         |
| 18.5.0               | 23.x、24.x、25.x    | `Replicated`データベースエンジンに対する試験的なサポート。 |

{{< alert type="note" >}}

[ClickHouse Cloud](https://clickhouse.com/cloud)がサポートされています。互換性は通常、最新の主要なGitLabリリースおよび新しいバージョンで保証されています。

{{< /alert >}}

## ClickHouseの設定 {#set-up-clickhouse}

ClickHouseをGitLabと組み合わせて設定するには、次の手順を実行します:

1. [ClickHouseクラスターを実行してデータベースを構成する](#run-and-configure-clickhouse)。
1. [ClickHouseへのGitLab接続を構成する](#configure-the-gitlab-connection-to-clickhouse)。
1. [ClickHouse移行を実行する](#run-clickhouse-migrations)。

### ClickHouseを実行および構成する {#run-and-configure-clickhouse}

ホストされているサーバーでClickHouseを実行すると、インスタンスで毎月実行されるビルドの数、選択したハードウェア、ClickHouseをホストするデータセンターの選択など、さまざまなデータポイントがリソース消費に影響を与える可能性があります。いずれにせよ、コストはそれほど大きくならないはずです。

必要なユーザーとデータベースオブジェクトを作成するには:

1. 安全なパスワードを生成して保存します。
1. ClickHouse SQLコンソールにサインインします。
1. 次のコマンドを実行します。`PASSWORD_HERE`を生成されたパスワードに置き換えます。

   ```sql
   CREATE DATABASE gitlab_clickhouse_main_production;
   CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE';
   CREATE ROLE gitlab_app;
   GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE ON gitlab_clickhouse_main_production.* TO gitlab_app;
   GRANT SELECT ON information_schema.* TO gitlab_app;
   GRANT gitlab_app TO gitlab;
   ```

### ClickHouseへのGitLab接続を構成する {#configure-the-gitlab-connection-to-clickhouse}

{{< tabs >}}

{{< tab title="Linuxパッケージ" >}}

ClickHouse認証情報をGitLabに提供するには:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['clickhouse_databases']['main']['database'] = 'gitlab_clickhouse_main_production'
   gitlab_rails['clickhouse_databases']['main']['url'] = 'https://example.com/path'
   gitlab_rails['clickhouse_databases']['main']['username'] = 'gitlab'
   gitlab_rails['clickhouse_databases']['main']['password'] = 'PASSWORD_HERE' # replace with the actual password
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. ClickHouseのパスワードをKubernetesシークレットとして保存します:

   ```shell
   kubectl create secret generic gitlab-clickhouse-password --from-literal="main_password=PASSWORD_HERE"
   ```

1. Helmの値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     clickhouse:
       enabled: true
       main:
         username: default
         password:
           secret: gitlab-clickhouse-password
           key: main_password
         database: gitlab_clickhouse_main_production
         url: 'http://example.com'
   ```

1. ファイルを保存して、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

接続が正常に設定されたことを確認するには:

1. [Railsコンソール](../administration/operations/rails_console.md#starting-a-rails-console-session)にサインインします
1. 次のコマンドを実行します:

   ```ruby
   ClickHouse::Client.select('SELECT 1', :main)
   ```

   成功した場合、コマンドは`[{"1"=>1}]`を返します

### ClickHouse移行の実行 {#run-clickhouse-migrations}

{{< tabs >}}

{{< tab title="Linuxパッケージ" >}}

必要なデータベースオブジェクトを作成するには、次を実行します:

```shell
sudo gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

移行は、[GitLab-移行チャート](https://docs.gitlab.com/charts/charts/gitlab/migrations/#clickhouse-optional)を使用して自動的に実行されます。

または、[Toolboxポッド](https://docs.gitlab.com/charts/charts/gitlab/toolbox/)で次のコマンドを実行して、移行を実行することもできます:

```shell
gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< /tabs >}}

### 分析にClickHouseを有効にする {#enable-clickhouse-for-analytics}

GitLabインスタンスがClickHouseに接続されたので、[ClickHouseを分析用に有効にする](../administration/analytics.md)ことで、ClickHouseを使用する機能を有効にできます。

## `Replicated`データベースエンジン {#replicated-database-engine}

{{< history >}}

- GitLab 18.5の実験として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/560927)されました。

{{< /history >}}

マルチノード、高可用性設定の場合、GitLabはClickHouseの`Replicated`テーブルエンジンをサポートします。

前提要件: 

- クラスターは、`remote_servers`[構成セクション](https://clickhouse.com/docs/architecture/cluster-deployment#configure-clickhouse-servers)で定義する必要があります。
- 次の[マクロ](https://clickhouse.com/docs/architecture/cluster-deployment#macros-config-explanation)を構成する必要があります:
  - `cluster`
  - `shard`
  - `replica`

データベースを構成する際は、`ON CLUSTER`句でステートメントを実行する必要があります。次の例では、`CLUSTER_NAME_HERE`をクラスターの名前に置き換えます:

 ```sql
 CREATE DATABASE gitlab_clickhouse_main_production ON CLUSTER CLUSTER_NAME_HERE ENGINE = Replicated('/clickhouse/databases/{cluster}/gitlab_clickhouse_main_production', '{shard}', '{replica}')
 CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE' ON CLUSTER CLUSTER_NAME_HERE;
 CREATE ROLE gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
 GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE ON gitlab_clickhouse_main_production.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
 GRANT SELECT ON information_schema.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
 GRANT gitlab_app TO gitlab ON CLUSTER CLUSTER_NAME_HERE;
 ```

### ロードバランサーの考慮事項 {#load-balancer-considerations}

GitLabアプリケーションは、HTTP/HTTPSインターフェースを介してClickHouseクラスターと通信します。[`chproxy`](https://www.chproxy.org/)など、ClickHouseクラスターへのリクエストのロードバランシングにHTTPプロキシを使用することを検討してください。

## トラブルシューティング {#troubleshooting}

### GitLab 18.0.0以前のデータベーススキーマ移行 {#database-schema-migrations-on-gitlab-1800-and-earlier}

GitLab 18.0.0以前では、ClickHouseのデータベーススキーマ移行を実行すると、次のエラーメッセージが表示されてClickHouse 24.xおよび25.xで失敗する場合があります:

```plaintext
Code: 344. DB::Exception: Projection is fully supported in ReplacingMergeTree with deduplicate_merge_projection_mode = throw. Use 'drop' or 'rebuild' option of deduplicate_merge_projection_mode
```

すべての移行を実行しないと、ClickHouseインテグレーションは機能しません。

このイシューを回避策し、移行を実行するには:

1. [Railsコンソール](../administration/operations/rails_console.md#starting-a-rails-console-session)にサインインします
1. 次のコマンドを実行します:

   ```ruby
   ClickHouse::Client.execute("INSERT INTO schema_migrations (version) VALUES ('20231114142100'), ('20240115162101')", :main)
   ```

1. データベースを再度移行します:

   ```shell
   sudo gitlab-rake gitlab:clickhouse:migrate
   ```

今回は、データベースの移行が正常に完了するはずです。
