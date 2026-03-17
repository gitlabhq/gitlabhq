---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: ClickHouse
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版（GitLab Self-ManagedとGitLab Dedicated）。

{{< /details >}}

[ClickHouse](https://clickhouse.com)は、オープンソースのカラム指向データベース管理システムです。大規模なデータセットに対して、効率的にフィルタリング、集計、クエリを実行できます。

GitLabは、GitLab Duo、SDLCトレンド、CI分析などの高度な分析機能を有効にするために、ClickHouseをセカンダリデータストアとして使用します。GitLabは、これらの機能をサポートするデータのみをClickHouseに保存します。

ClickHouseをGitLabに接続するには、[ClickHouse Cloud](https://clickhouse.com/cloud)を使用する必要があります。

または、[独自のClickHouse環境](https://clickhouse.com/docs/en/install)を使用することもできます。詳細については、[GitLab Self-Managed用ClickHouseの推奨事項](https://clickhouse.com/docs/guides/sizing-and-hardware-recommendations)を参照してください。

## ClickHouseで利用可能な分析 {#analytics-available-with-clickhouse}

ClickHouseを設定すると、次の分析機能を使用できます:

| 機能 | 説明 |
|----------------------|---------------------|
| [Runnerフリートダッシュボード](../ci/runners/runner_fleet_dashboard.md#dashboard-metrics)  | Runnerの使用状況メトリクスとジョブの待機時間を表示します。各プロジェクトのRunnerのタイプとジョブステータスごとのジョブ数と実行されたRunnerの時間（分）を含むCSVファイルのエクスポートを提供します。   |
| [コントリビュート分析](../user/group/contribution_analytics/_index.md)  | グループメンバーのコントリビュート（プッシュイベント、イシュー、マージリクエストなど）を時系列で分析します。ClickHouseを使用すると、大規模なインスタンスでのタイムアウトの問題が発生しにくくなります。 |
| [GitLab DuoとSDLCのトレンド](../user/analytics/duo_and_sdlc_trends.md)  | GitLab Duoがソフトウェア開発のパフォーマンスに与える影響を測定します。AI固有の指標（GitLab Duoのシート導入、コード提案の受け入れ率、GitLab Duo Chatの使用状況）と並行して、開発メトリクス（デプロイ頻度、リードタイム、変更失敗率、復元時間）を追跡します。 |
| [AIメトリクスのGraphQL API](../api/graphql/duo_and_sdlc_trends.md) | `AiMetrics`、`AiUserMetrics`、`AiUsageData`エンドポイントを介して、プログラムによるGitLab DuoおよびSDLCトレンドデータへのアクセスを提供します。BIツールおよびカスタム分析とのインテグレーションのために、事前集計されたメトリクスおよびrawイベントのエクスポートを提供します。 |

## サポートされているClickHouseのバージョン {#supported-clickhouse-versions}

サポートされているClickHouseのバージョンは、GitLabのバージョンによって異なります:

- GitLab 17.7以降は、ClickHouse 23.xをサポートしています。ClickHouse 24.xまたは25.xのいずれかを使用するには、[回避策](#database-schema-migrations-on-gitlab-1800-and-earlier)を使用してください。
- GitLab 18.1以降は、ClickHouse 23.x、24.x、および25.xをサポートしています。
- GitLab 18.8以降は、ClickHouse 23.x、24.x、25.x、およびレプリケートされたデータベースエンジンをサポートしています。
  - 古いクラスターでは、追加の権限（`dictGet`）が必要になります。[スニペット](#database-dictionary-read-support)を参照してください。

ClickHouse Cloudは、常に最新の安定したGitLabリリースと互換性があります。

> [!warning]
> ClickHouse 25.12を使用している場合、[backward-incompatible change](https://clickhouse.com/docs/whats-new/changelog#backward-incompatible-change)が`ALTER MODIFY COLUMN`に導入されたことに注意してください。これにより、バージョン18.8より前のGitLabにおけるClickHouseインテグレーションの移行処理が失敗します。GitLabをバージョン18.8以降にアップグレードする必要があります。

## ClickHouseの設定 {#set-up-clickhouse}

運用要件に基づいて、デプロイタイプを選択します:

- **[ClickHouse Cloud](#set-up-clickhouse-cloud)（推奨）**: 自動アップグレード、バックアップ、およびスケールを備えたフルマネージドサービス。
- **[GitLab Self-Managed用ClickHouse（BYOC）](#set-up-clickhouse-for-gitlab-self-managed-byoc)**: インフラストラクチャと設定を完全に制御できます。

ClickHouseインスタンスを設定した後、次を行います:

1. [GitLabデータベースとユーザーを作成します](#create-database-and-user)。
1. [GitLab接続を構成します](#configure-the-gitlab-connection)。
1. [接続を検証します](#verify-the-connection)。
1. [ClickHouseの移行を実行します](#run-clickhouse-migrations)。
1. [ClickHouse for Analyticsを有効にします](#enable-clickhouse-for-analytics)。

### ClickHouse Cloudの設定 {#set-up-clickhouse-cloud}

前提条件: 

- ClickHouse Cloudアカウントを持っている。
- GitLabインスタンスからClickHouse Cloudへのネットワーク接続が有効である。
- GitLabインスタンスの管理者である。

ClickHouse Cloudを設定するには、以下を実行します:

1. [ClickHouse Cloud](https://clickhouse.cloud)にサインインします。
1. **New Service**を選択します。
1. サービス階層を選択します:
   - **Development**: テストおよび開発環境向け。
   - **Production**: 高可用性を備えた本番環境のワークロード向け。
1. クラウドプロバイダーとリージョンを選択します。最適なパフォーマンスを得るには、GitLabインスタンスに近いリージョンを選択してください。
1. サービス名と設定を設定します。
1. **Create Service**を選択します。
1. プロビジョニングされたら、サービスダッシュボードから接続の詳細をメモしておきます:
   - ホスト
   - ポート（通常、安全な接続の場合は`9440`）
   - ユーザー名
   - パスワード

> [!note]
> ClickHouse Cloudは、バージョンアップグレードとセキュリティパッチを自動的に処理します。Enterprise Edition（EE）のお客様は、ビジネス時間中の予期しないサービス中断を回避し、発生時期を制御するためにアップグレードをスケジュールできます。詳細については、[ClickHouseのアップグレード](#upgrade-clickhouse)を参照してください。

ClickHouse Cloudサービスを作成したら、[GitLabデータベースとユーザーを作成します](#create-database-and-user)。

### GitLab Self-Managed用ClickHouse（BYOC）を設定する {#set-up-clickhouse-for-gitlab-self-managed-byoc}

前提条件: 

- ClickHouseインスタンスがインストールされ、実行されていることを確認する。ClickHouseがインストールされていない場合は、以下を参照してください:
  - [ClickHouseの公式インストールガイド](https://clickhouse.com/docs/en/install)。
  - [GitLab Self-Managed用ClickHouseに関する推奨事項。](https://clickhouse.com/docs/guides/sizing-and-hardware-recommendations)
- [サポートされているClickHouseのバージョン](#supported-clickhouse-versions)がある。
- GitLabインスタンスからClickHouseへのネットワーク接続を有効である。
- ClickHouseとGitLabインスタンスの両方の管理者である。

> [!warning]
> ClickHouse for GitLab Self-Managedの場合、バージョンアップグレード、セキュリティパッチ、およびバックアップの計画と実行はお客様の責任となります。詳細については、[ClickHouseのアップグレード](#upgrade-clickhouse)を参照してください。

#### 高可用性の設定 {#configure-high-availability}

マルチノードの高可用性（HA）の設定の場合、GitLabはClickHouseのレプリケートされたテーブルエンジンをサポートします。

前提条件: 

- マルチノードを持つClickHouseクラスターがある。最小3つのノードをお勧めします。
- `remote_servers`設定セクションでクラスターを定義している。
- ClickHouse設定で次のマクロを設定している:
  - `cluster`
  - `shard`
  - `replica`

HA用にデータベースを設定するときは、`ON CLUSTER`句を使用してステートメントを実行する必要があります。

詳細については、[ClickHouseのレプリケートされたデータベースエンジンのドキュメント](https://clickhouse.com/docs/en/engines/database-engines/replicated)を参照してください。

#### ロードバランサーの設定 {#configure-load-balancer}

GitLabアプリケーションは、HTTP / HTTPSインターフェースを介してClickHouseクラスターと通信します。HAデプロイの場合は、HTTPプロキシまたはロードバランサーを使用して、ClickHouseクラスターノード全体にリクエストを分散させます。

推奨されるロードバランサーのオプション:

- [chproxy](https://www.chproxy.org/) \- 組み込みのキャッシュとルーティングを備えたClickHouse固有のHTTPプロキシ。
- HAProxy - 汎用TCP / HTTPロードバランサー。
- NGINX - ロードバランシング機能を備えたWebサーバー。
- クラウドプロバイダーロードバランサー（AWS Application Load Balancer、GCP Load Balancer、Azure Load Balancer）。

基本的なchproxy設定例:

```yaml
server:
  http:
    listen_addr: ":8080"

clusters:
  - name: "clickhouse_cluster"
    nodes: [
      "http://ch-node1:8123",
      "http://ch-node2:8123",
      "http://ch-node3:8123"
    ]

users:
  - name: "gitlab"
    password: "your_secure_password"
    to_cluster: "clickhouse_cluster"
    to_user: "gitlab"
```

ロードバランサーを使用する場合は、個々のClickHouseノードの代わりに、ロードバランサーURLに接続するようにGitLabを設定します。

詳細については、[chproxyのドキュメント](https://www.chproxy.org/)を参照してください。

GitLab Self-Managedインスタンス用ClickHouseを設定したら、[GitLabデータベースとユーザーを作成します](#create-database-and-user)。

### ClickHouseインストールの検証 {#verify-clickhouse-installation}

データベースを設定する前に、ClickHouseがインストールされ、アクセス可能であることを確認します:

1. ClickHouseが実行されていることを確認します:

   ```shell
   clickhouse-client --query "SELECT version()"
   ```

   ClickHouseが実行されている場合は、バージョン番号が表示されます（たとえば、`24.3.1.12`）。

1. 認証情報で接続できることを確認します:

   ```shell
   clickhouse-client --host your-clickhouse-host --port 9440 --secure --user default --password 'your-password'
   ```

   > [!note] TLSをまだ設定していない場合は、初期テストのために`--secure`フラグなしでポート`9000`を使用してください。

### データベースとユーザーを作成 {#create-database-and-user}

必要なユーザーとデータベースオブジェクトを作成するには以下の手順に従います:

1. 安全なパスワードを生成して保存します。
1. サインインします:
   - ClickHouse Cloudの場合は、ClickHouse SQLコンソールにサインインします。
   - GitLab Self-Managed用ClickHouseの場合は、`clickhouse-client`にサインインします。
1. 次のコマンドを実行し、`PASSWORD_HERE`を生成されたパスワードに置き換えます。

{{< tabs >}}

{{< tab title="単一ノードまたはClickHouse Cloud" >}}

```sql
CREATE DATABASE gitlab_clickhouse_main_production;
CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE';
CREATE ROLE gitlab_app;
GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE, dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app;
GRANT SELECT ON information_schema.* TO gitlab_app;
GRANT gitlab_app TO gitlab;
```

{{< /tab >}}

{{< tab title="HA GitLab Self-Managed用ClickHouse" >}}

`CLUSTER_NAME_HERE`をクラスターの名前に置き換えます:

```sql
CREATE DATABASE gitlab_clickhouse_main_production ON CLUSTER CLUSTER_NAME_HERE ENGINE = Replicated('/clickhouse/databases/{cluster}/gitlab_clickhouse_main_production', '{shard}', '{replica}');
CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE' ON CLUSTER CLUSTER_NAME_HERE;
CREATE ROLE gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE, dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT SELECT ON information_schema.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT gitlab_app TO gitlab ON CLUSTER CLUSTER_NAME_HERE;
```

{{< /tab >}}

{{< /tabs >}}

### GitLab接続を設定する {#configure-the-gitlab-connection}

{{< tabs >}}

{{< tab title="Linuxパッケージ" >}}

GitLabにClickHouseの認証情報を提供するには、以下を実行します:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['clickhouse_databases']['main']['database'] = 'gitlab_clickhouse_main_production'
   gitlab_rails['clickhouse_databases']['main']['url'] = 'https://your-clickhouse-host:port'
   gitlab_rails['clickhouse_databases']['main']['username'] = 'gitlab'
   gitlab_rails['clickhouse_databases']['main']['password'] = 'PASSWORD_HERE' # replace with the actual password
   ```

   URLを以下に置き換えます:
   - ClickHouse Cloudの場合: `https://your-service.clickhouse.cloud:9440`
   - GitLab Self-Managed用ClickHouseの場合: `https://your-clickhouse-host:8443`
   - ロードバランサーを備えたGitLab Self-Managed HA用ClickHouseの場合: `https://your-load-balancer:8080`（またはロードバランサーURL）

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm Chart（Kubernetes）" >}}

1. ClickHouseパスワードをKubernetesシークレットとして保存します:

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
         username: gitlab
         password:
           secret: gitlab-clickhouse-password
           key: main_password
         database: gitlab_clickhouse_main_production
         url: 'https://your-clickhouse-host:port'
   ```

   URLを以下に置き換えます:
   - ClickHouse Cloudの場合: `https://your-service.clickhouse.cloud:9440`
   - GitLab Self-Managed用ClickHouseの単一ノード用の場合: `https://your-clickhouse-host:8443`
   - ロードバランサーを備えたGitLab Self-Managed HA用ClickHouseの場合: `https://your-load-balancer:8080`（またはロードバランサーURL）

1. ファイルを保存して、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

> [!note]本番環境デプロイの場合、ClickHouseインスタンスでTLS/SSLを設定し、`https://` URLを使用してください。GitLab Self-Managedインストールの場合は、[ネットワークセキュリティ](#network-security)のドキュメントを参照してください。

### 接続の確認 {#verify-the-connection}

接続が正常に設定されたことを確認するには、以下を実行します:

1. [Railsコンソール](../administration/operations/rails_console.md#starting-a-rails-console-session)にサインインします。
1. 次のコマンドを実行します:

   ```ruby
   ClickHouse::Client.select('SELECT 1', :main)
   ```

   成功した場合、コマンドは`[{"1"=>1}]`を返します。

接続に失敗した場合は、以下を確認してください:

- ClickHouseサービスが実行中でアクセス可能であること。
- GitLabからClickHouseへのネットワーク接続があること。ファイアウォールとセキュリティグループが接続を許可していることを確認してください。
- 接続URLが正しい（ホスト、ポート、プロトコル）。
- 認証情報が正しい。
- HAクラスターデプロイの場合: ロードバランサーが正しく設定され、リクエストをルーティングしていること。

### ClickHouse移行の実行 {#run-clickhouse-migrations}

{{< tabs >}}

{{< tab title="Linuxパッケージ" >}}

必要なデータベースオブジェクトを作成するには、以下を実行します:

```shell
sudo gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< tab title="Helm Chart（Kubernetes）" >}}

移行は、[GitLab-Migrationsチャート](https://docs.gitlab.com/charts/charts/gitlab/migrations/)で自動的に実行されます。

または、Toolboxポッドで次のコマンドを実行して、移行を実行することもできます:

```shell
gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< /tabs >}}

### 分析用ClickHouseの有効化 {#enable-clickhouse-for-analytics}

GitLabインスタンスがClickHouseに接続されたら、ClickHouseを使用する機能を有効にできます:

前提条件: 

- インスタンスへの管理者アクセス権が必要です。
- ClickHouse接続が設定され、検証されている。
- 移行が正常に完了している。

分析用ClickHouseを有効にするには、以下の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **ClickHouse**を展開します。
1. **分析用ClickHouseの有効化**を選択します。
1. **変更を保存**を選択します。

### 分析用ClickHouseの無効化 {#disable-clickhouse-for-analytics}

分析用ClickHouseを無効にするには、以下の手順に従います:

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

無効にするには、以下の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **ClickHouse**を展開します。
1. **分析用ClickHouseの有効化**チェックボックスをオフにします。
1. **変更を保存**を選択します。

> [!note] AnalyticsにClickHouseを無効にすると、GitLabはClickHouseのクエリを停止しますが、ClickHouseインスタンスからデータは削除されません。ClickHouseに依存する分析機能は、代替データストアにフォールバックするか、使用できなくなります。

## ClickHouseのアップグレード {#upgrade-clickhouse}

### ClickHouse Cloud {#clickhouse-cloud}

ClickHouse Cloudは、バージョンのアップグレードとセキュリティパッチを自動的に処理します。手動による操作は不要です。

アップグレードのスケジュールとメンテナンス期間については、[ClickHouse Cloudのドキュメント](https://clickhouse.com/docs/cloud/manage/updates)を参照してください。

> [!note] ClickHouse Cloudは、今後のアップグレードについて事前にお知らせします。[ClickHouse Cloud変更履歴](https://clickhouse.com/docs/cloud/changes)を確認して、新機能と変更点について常に最新情報を入手してください。

### GitLab Self-Managed用ClickHouse（BYOC） {#clickhouse-for-gitlab-self-managed-byoc}

GitLab Self-Managed用ClickHouseの場合、バージョンアップグレードの計画と実行はお客様の責任となります。

前提条件: 

- ClickHouseインスタンスへの管理者アクセス権が必要です。
- アップグレードする前に、データをバックアップしてください。[ディザスターリカバリー](#disaster-recovery)を参照してください。

アップグレードする前に下記をご確認ください:

1. 破壊的な変更については、[ClickHouseのリリースノート](https://clickhouse.com/docs/category/release-notes)をご確認ください。
1. GitLabのバージョンとの[互換性](#supported-clickhouse-versions)を確認してください。
1. 非本番環境でアップグレードをテストしてください。
1. 想定されるダウンタイムに備えるか、HAクラスターではローリングアップグレード戦略を採用してください。

ClickHouseをアップグレードするには、以下の手順に従います:

1. 単一ノードデプロイの場合は、[ClickHouseのアップグレードドキュメント](https://clickhouse.com/docs/manage/updates)に従ってください。
1. HAクラスター環境でデプロイを行う場合は、ダウンタイムを最小限に抑えるためにローリングアップグレードを実施してください:
   - ノードを1台ずつ順にアップグレードします。
   - ノードがクラスターに再結合するまで待ちます。
   - 次のノードに進む前に、クラスターのヘルスを検証します。

> [!warning] 
> ClickHouseのバージョンがGitLabのバージョンと互換性があることを常に確認してください。互換性のないバージョンを使用すると、インデックス作成処理が一時停止したり、機能が動作しなくなったりする可能性があります。詳細については、[サポートされているClickHouseのバージョン](#supported-clickhouse-versions)を参照してください

詳細なアップグレード手順については、[アップデートに関するClickHouseのドキュメント](https://clickhouse.com/docs/manage/updates)を参照してください。

## 操作 {#operations}

### 移行ステータスの確認 {#check-migration-status}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

ClickHouseの移行ステータスを確認するには、以下の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **ClickHouse**を展開します。
1. 利用可能な場合は、**移行ステータス**セクションを確認します。

または、Railsコンソールを使用して、保留中の移行を確認します:

```ruby
# Sign in to Rails console
# Run this to check migrations
ClickHouse::MigrationSupport::Migrator.new(:main).pending_migrations
```

### 失敗した移行の再試行 {#retry-failed-migrations}

ClickHouseの移行が失敗した場合:

1. エラーの詳細についてログを確認します。ClickHouse関連のエラーは、GitLabアプリケーションログに記録されます。
1. 根本的な問題（例: メモリ不足、接続の問題など）に対処します。
1. 移行を再試行します:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:clickhouse:migrate

   # For self-compiled installations
   bundle exec rake gitlab:clickhouse:migrate RAILS_ENV=production
   ```

> [!note]移行は、べき等になるように設計されており、安全に再試行できます。移行が途中で失敗した場合、再度実行すると、中断したところから再開するか、すでに完了した手順をスキップします。

## ClickHouse Rakeタスク {#clickhouse-rake-tasks}

GitLabには、ClickHouseデータベースを管理するためのいくつかのRakeタスクが用意されています。

次のRakeタスクが利用可能です:

| タスク | 説明 |
|------|-------------|
| [`sudo gitlab-rake gitlab:clickhouse:migrate`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | 保留中のすべてのClickHouse移行を実行して、データベーススキーマを作成または更新します。 |
| [`sudo gitlab-rake gitlab:clickhouse:drop`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | すべてのClickHouseデータベースをドロップします。これはすべてのデータを削除するため、細心の注意を払って使用してください。 |
| [`sudo gitlab-rake gitlab:clickhouse:create`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | ClickHouseデータベースが存在しない場合は作成します。 |
| [`sudo gitlab-rake gitlab:clickhouse:setup`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | データベースを作成し、すべての移行を実行します。`create`タスクと`migrate`タスクの実行と同じです。 |
| [`sudo gitlab-rake gitlab:clickhouse:schema:dump`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | バックアップまたはバージョン管理のために、現在のデータベーススキーマをファイルにダンプします。 |
| [`sudo gitlab-rake gitlab:clickhouse:schema:load`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | ダンプファイルからデータベーススキーマを読み込みます。 |

> [!note]セルフコンパイルインストールの場合、`sudo gitlab-rake`の代わりに`bundle exec rake`を使用し、コマンドの最後に`RAILS_ENV=production`を追加します。

### 一般的なタスクの例 {#common-task-examples}

#### ClickHouseの接続とスキーマの検証 {#verify-clickhouse-connection-and-schema}

ClickHouseの接続が動作していることを検証するには、以下を実行します:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:info

# For self-compiled installations
bundle exec rake gitlab:clickhouse:info RAILS_ENV=production
```

このタスクは、ClickHouseの接続と設定に関するデバッグ情報を出力します。

#### すべての移行を再実行 {#re-run-all-migrations}

保留中のすべての移行を実行するには、以下を実行します:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:migrate

# For self-compiled installations
bundle exec rake gitlab:clickhouse:migrate RAILS_ENV=production
```

#### データベースのリセット {#reset-the-database}

> [!warning]
> これにより、ClickHouseデータベース内のすべてのデータが削除されます。開発環境でのみ、またはトラブルシューティング時に使用してください。

データベースをドロップして再作成するには、以下を実行します:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:drop
sudo gitlab-rake gitlab:clickhouse:setup

# For self-compiled installations
bundle exec rake gitlab:clickhouse:drop RAILS_ENV=production
bundle exec rake gitlab:clickhouse:setup RAILS_ENV=production
```

### 環境変数 {#environment-variables}

環境変数を使用して、Rakeタスクの動作を制御できます:

| 環境変数 | データ型 | 説明 |
|---------------------|-----------|-------------|
| `VERBOSE` | ブール値 | 移行中に詳細な出力を表示するには、`true`に設定します。例: `VERBOSE=true sudo gitlab-rake gitlab:clickhouse:migrate` |

## パフォーマンスチューニング {#performance-tuning}

> [!note]ユーザー数に基づいたリソースサイジングとデプロイの推奨事項については、[システム要件](#system-requirements)を参照してください。

ClickHouseのアーキテクチャとパフォーマンスチューニングについては、[アーキテクチャに関するClickHouseのドキュメント](https://clickhouse.com/docs/architecture/introduction)を参照してください。

## ディザスターリカバリー {#disaster-recovery}

### バックアップと復元 {#backup-and-restore}

GitLabアプリケーションをアップグレードする前に、完全なバックアップを実行する必要があります。ClickHouseのデータは、GitLabのバックアップツールには含まれていません。

バックアップと復元の戦略は、デプロイの選択によって異なります。

#### ClickHouse Cloud {#clickhouse-cloud-1}

ClickHouse Cloudは自動的に以下を行います:

- バックアップと復元を管理します。
- 毎日のバックアップを作成して保持します。

追加の設定を行う必要はありません。

詳細については、[ClickHouse Cloudのバックアップ](https://clickhouse.com/docs/cloud/manage/backups)を参照してください。

#### GitLab Self-Managed用ClickHouse {#clickhouse-for-gitlab-self-managed}

独自のClickHouseインスタンスを運用している場合は、データの安全性を確保するために定期的にバックアップを取得することを推奨します:

- [オブジェクトストレージバケット（例: AWS S3）](https://clickhouse.com/docs/en/operations/backup#configuring-backuprestore-to-use-an-s3-endpoint)に、（`metrics`や`logs`のようなシステムテーブルを除く）テーブルの最初の完全バックアップを実行します。
- この最初の完全バックアップの後に、[増分バックアップ](https://clickhouse.com/docs/en/operations/backup#take-an-incremental-backup)を実行します。

この方法では完全バックアップのたびにデータが重複してしまいますが、[最も簡単にデータを復元できます。](https://clickhouse.com/docs/en/operations/backup#restore-from-the-incremental-backup)

または、[`clickhouse-backup`](https://github.com/Altinity/clickhouse-backup)を使用することもできます。これはサードパーティ製のツールで、同様の機能に加えてスケジューリングやリモートストレージ管理などの追加機能を提供します。

## モニタリング {#monitoring}

GitLabインテグレーションの安定性を確保するには、ClickHouseクラスターのヘルスとパフォーマンスを監視する必要があります。

### ClickHouse Cloud {#clickhouse-cloud-2}

ClickHouse Cloudには、セキュアなAPIエンドポイントを介してメトリクスを公開するネイティブの[Prometheusインテグレーション](https://clickhouse.com/docs/integrations/prometheus)が用意されています。

APIの認証情報を生成したら、コレクターを設定して、ClickHouse Cloudからメトリクスをスクレイプできます。たとえば、[Prometheusデプロイ](https://clickhouse.com/docs/integrations/prometheus#configuring-prometheus)などです。

### GitLab Self-Managed用ClickHouse {#clickhouse-for-gitlab-self-managed-1}

ClickHouseは、[Prometheus形式でメトリクス](https://clickhouse.com/docs/operations/server-configuration-parameters/settings#prometheus)を公開できます。これを有効にするには、以下を実行します:

1. `config.xml`の`prometheus`セクションを設定して、専用ポート（デフォルトは`9363`）でメトリクスを公開します。

   ```xml
   <prometheus>
       <endpoint>/metrics</endpoint>
       <port>9363</port>
       <metrics>true</metrics>
       <events>true</events>
       <asynchronous_metrics>true</asynchronous_metrics>
   </prometheus>
   ```

1. Prometheusまたは同等の互換サーバーを構成し、`http://<clickhouse-host>:9363/metrics`からメトリクスをスクレイプするように設定してください。

### 監視するメトリクス {#metrics-to-monitor}

GitLabの機能に影響を与える可能性のある問題を検出するために、次のメトリクスのアラートを設定する必要があります:

| メトリクス名 | 説明 | アラートのしきい値（推奨） |
| :--- | :--- | :--- |
| `ClickHouse_Metrics_Query` | 現在実行中のクエリの数。急激なスパイクは、パフォーマンスのボトルネックを示している可能性があります。 | ベースラインからの偏差（例: `> 100`） |
| `ClickHouseProfileEvents_FailedSelectQuery` | 失敗した選択クエリの数 | ベースラインからの偏差（例: `> 50`） |
| `ClickHouseProfileEvents_FailedInsertQuery` | 失敗した挿入クエリの数 | ベースラインからの偏差（例: `> 10`） |
| `ClickHouse_AsyncMetrics_ReadonlyReplica` | レプリカが読み取り専用モードになっているかどうかを示します（多くの場合、ZooKeeper接続の損失が原因です）。 | `> 0`（直ちに対処してください） |
| `ClickHouse_ProfileEvents_NetworkErrors` | ネットワークエラー（接続のリセット/タイムアウト）。エラーが頻繁に発生すると、GitLabのバックグラウンドジョブが失敗する可能性があります。 | 割合 `> 0` |

### 稼働状況チェック {#liveness-check}

ClickHouseがロードバランサーの背後で稼働している場合、HTTPの`/ping`エンドポイントを使用して稼働状況を確認できます。期待されるレスポンスはHTTPコード200の`Ok`です。

## セキュリティと監査ログ {#security-and-auditing}

データのセキュリティを確保し、監査証跡機能を確保するには、次のセキュリティ対策を実施します。

### ネットワークセキュリティ {#network-security}

- TLS暗号化: ClickHouseサーバーを構成し、[TLS暗号化](#network-security)を使用して接続を検証するように設定してください。

  GitLabで接続URLを設定する場合は、これを指定するために`https://`プロトコル（たとえば、`https://clickhouse.example.com:8443`）を使用する必要があります。

- IP許可リスト: ClickHouseポート（デフォルト`8443`または`9440`）へのアクセスを、GitLabアプリケーションノードおよびその他の承認されたネットワークのみに制限します。

### 監査ログ {#audit-logging}

GitLabアプリケーションは、個々のClickHouseクエリに関する個別の監査ログを保持しません。データアクセス（誰がいつ何をクエリしたか）に関する特定の要件を満たすために、ClickHouse側でログ記録を有効にすることができます。

#### ClickHouse Cloud {#clickhouse-cloud-3}

ClickHouse Cloudでは、クエリのログ記録はデフォルトで有効になっています。`system.query_log`テーブルにクエリを実行して、これらのログにアクセスできます。

#### GitLab Self-Managed用ClickHouse {#clickhouse-for-gitlab-self-managed-2}

Self-Managedインスタンスの場合、サーバー設定で`query_log`設定パラメータが有効になっていることを確認してください:

1. `query_log`セクションが`config.xml`または`users.xml`に存在することを確認します:

   ```xml
   <query_log>
       <database>system</database>
       <table>query_log</table>
       <partition_by>toYYYYMM(event_date)</partition_by>
       <flush_interval_milliseconds>7500</flush_interval_milliseconds>
       <ttl>event_date + INTERVAL 30 DAY</ttl>  <!-- Keep only 30 days -->
   </query_log>
   ```

1. 有効にすると、実行されたすべてのクエリが`system.query_log`テーブルに記録され、監査証跡が可能になります。

## システム要件 {#system-requirements}

推奨されるシステム要件は、ユーザー数によって異なります。

### デプロイの意思決定マトリックスのクイックリファレンス {#deployment-decision-matrix-quick-reference}

| ユーザー | 主な推奨事項 | 同等のAWS ARMインスタンス | 同等のGCP ARMインスタンス | 同等のAzure ARMインスタンス | デプロイタイプ |
|---|---|---|---|---|---|
| 1,000 | ClickHouse Cloud Basic | - | - | - | 管理 |
| 2,000 | ClickHouse Cloud Basic | `m8g.xlarge` | `c4a-standard-4` |  `Standard_D4ps_v6` | 管理または単一ノード |
| 3,000 | ClickHouse Cloud Scale | `m8g.2xlarge` | `c4a-standard-8` | `Standard_D8ps_v6` | 管理または単一ノード |
| 5,000 | ClickHouse Cloud Scale | `m8g.4xlarge` | `c4a-standard-16` | `Standard_D16ps_v6` | 管理または単一ノード |
| 10,000 | ClickHouse Cloud Scale | `m8g.4xlarge` | `c4a-standard-16` | `Standard_D16ps_v6` | 管理または単一ノード/HA |
| 25,000 | GitLab Self-Managed版ClickHouseまたはClickHouse Cloud Scale | `m8g.8xlarge`または3×`m8g.4xlarge` | `c4a-standard-32`または3×`c4a-standard-16` | `Standard_D32ps_v6`または3x`Standard_D16ps_v6` | 管理または単一ノード/HA |
| 50,000 | GitLab Self-Managed高可用性（HA）用ClickHouseまたはClickHouse Cloud Scale | 3×`m8g.4xlarge` | 3×`c4a-standard-16` | 3x`Standard_D16ps_v6` | 管理またはHAクラスター |

### 1,000ユーザー {#1k-users}

推奨: ClickHouse Cloud Basicは、運用の複雑さがなく、コスト効率にも優れています。

### 2,000ユーザー {#2k-users}

推奨: ClickHouse Cloud Basicは、運用の複雑さがなく、コスト効率が最も優れています。

GitLab Self-Managed用ClickHouseのデプロイの代替推奨構成:

- AWS: m8g.xlarge（4 vCPU、16 GB）
- GCP: c4a-standard-4またはn4-standard-4（4 vCPU、16 GB）
- Azure: Standard_D4ps_v6（4 vCPU、16 GB）
- ストレージ: 低～中程度のパフォーマンス層で20 GB

### 3,000ユーザー {#3k-users}

推奨: ClickHouse Cloud Scale

GitLab Self-Managed用ClickHouseのデプロイの代替推奨構成:

- AWS: m8g.2xlarge（8 vCPU、32 GB)
- GCP: c4a-standard-8またはn4-standard-8（8 vCPU、32 GB）
- Azure: Standard_D8ps_v6（8 vCPU、32 GB）
- ストレージ: 中程度のパフォーマンス層で100 GB

注: この規模では、HAデプロイは費用対効果が高くありません。

### 5,000ユーザー {#5k-users}

推奨: ClickHouse Cloud Scale

GitLab Self-Managed用ClickHouseのデプロイの代替推奨構成:

- AWS: m8g.4xlarge（16 vCPU、64 GB）
- GCP: c4a-standard-16またはn4-standard-16（16 vCPU、64 GB）
- Azure: Standard_D16ps_v6（16 vCPU、64 GB）
- ストレージ: 高パフォーマンス層で100 GB
- デプロイ: 単一ノードを推奨

### 10,000ユーザー {#10k-users}

推奨: ClickHouse Cloud Scale

GitLab Self-Managed用ClickHouseのデプロイの代替推奨構成:

- AWS: m8g.4xlarge（16 vCPU、64 GB）
- GCP: c4a-standard-16またはn4-standard-16（16 vCPU、64 GB）
- Azure: Standard_D16ps_v6（16 vCPU、64 GB）
- ストレージ: 高パフォーマンス層で200 GB
- HAオプション: 3ノードクラスターは、重要なワークロードに対して実行可能になります

### 25,000ユーザー {#25k-users}

推奨: GitLab Self-Managed用ClickHouseまたはClickHouse Cloud Scale。いずれの選択肢も、この規模では経済的に実現可能です。

GitLab Self-Managed用ClickHouseのデプロイに関する推奨事項:

- 単一ノード:

  - AWS: m8g.8xlarge（32 vCPU、128 GB）
  - GCP: c4a-standard-32またはn4-standard-32（32 vCPU、128 GB）
  - Azure: Standard_D32ps_v6（32 vCPU、128 GB）

- HAデプロイ:

  - AWS: 3 × m8g.4xlarge（各16 vCPU、64 GB）
  - GCP: 3 × c4a-standard-16または3 × n4-standard-16（各16 vCPU、64 GB）
  - Azure: 3 x Standard_D16ps_v6（16 vCPU、64 GB）

- ストレージ: 高パフォーマンス層でノードあたり400 GB。

### 50,000ユーザー {#50k-users}

推奨: GitLab Self-Managed HA用ClickHouseまたはClickHouse Cloud Scale。この規模では、セルフマネージド構成の方がわずかにコスト効率に優れています。

GitLab Self-Managed用ClickHouseのデプロイに関する推奨事項:

- 単一ノード:

  - AWS: m8g.8xlarge（32 vCPU、128 GB）
  - GCP: c4a-standard-32またはn4-standard-32（32 vCPU、128 GB）
  - Azure: Standard_D32ps_v6（32 vCPU、128 GB）

- HAデプロイ（推奨）:

  - AWS: 3 × m8g.4xlarge（各16 vCPU、64 GB）
  - GCP: 3 × c4a-standard-16または3 × n4-standard-16（各16 vCPU、64 GB）
  - Azure: 3 x Standard_D16ps_v6（16 vCPU、64 GB）

- ストレージ: 高パフォーマンス層でノードあたり1000 GB。

#### GitLab Self-Managed用ClickHouseのデプロイに関するHAの考慮事項 {#ha-considerations-for-clickhouse-for-gitlab-self-managed-deployment}

HAセットアップは、10,000ユーザー以上でのみ費用対効果が高くなります。

- 最小: クォーラム用の3つのClickHouseノード。
- [ClickHouse Keeper](https://clickhouse.com/clickhouse/keeper): 連携用の3つのノード（同じ場所に配置することも、別々に配置することも可能）。
- ロードバランサー: クエリを分散させるために使用することを推奨します。
- ネットワーク: ノード間の低レイテンシー接続は極めて重要です。

## 用語集 {#glossary}

- クラスター: データを保存および処理するために連携するノード（サーバー）の集合。
- MergeTree: [`MergeTree`は、ClickHouseにおいて、高速なデータのインジェストと大規模データ処理のために設計されたテーブルエンジンです。](https://clickhouse.com/docs/engines/table-engines/mergetree-family/mergetree)これはClickHouseの中核的なストレージエンジンであり、カラム型ストレージ、カスタムパーティション、まばらなプライマリインデックス、バックグラウンドでのデータマージ機能などを提供します。
- パーツ: テーブルのデータの一部を格納するディスク上の物理ファイル。パーツは、パーティションキーを使用して作成されるテーブルのデータの論理的な区分であるパーティションとは異なります。
- レプリカ: ClickHouseデータベースに保存されているデータのコピー。冗長性と信頼性を高めるために、同じデータのレプリカをいくつでも持つことができます。レプリカは、ClickHouseが異なるサーバー間でデータの複数のコピーを同期させることができるReplicatedMergeTreeテーブルエンジンと組み合わせて使用されます。
- シャード: データのサブセット。ClickHouseには、常にデータのシャードが少なくとも1つあります。複数のサーバー間でデータを分割しない場合、データは1つのシャードに保存されます。複数のサーバー間でシャーディングデータを使用すると、単一サーバーの容量を超える場合に、ロードを分散できます。
- TTL（Time To Live）: Time To Live（TTL）は、特定の期間が経過すると、カラム/行を自動的に移動、削除、またはロールアップするClickHouseの機能です。これにより、アクセス頻度が低いデータを削除、移動、またはアーカイブできるため、ストレージをより効率的に管理できます。

## トラブルシューティング {#troubleshooting}

### GitLab 18.0.0以前のデータベーススキーマの移行 {#database-schema-migrations-on-gitlab-1800-and-earlier}

> [!warning]
> GitLab 18.0.0および以前では、ClickHouseのデータベーススキーマ移行をClickHouse 24.xおよび25.xに対して実行すると、次のエラーメッセージで失敗する可能性があります:
>
> ```plaintext
> Code: 344. DB::Exception: Projection is fully supported in ReplacingMergeTree with deduplicate_merge_projection_mode = throw. Use 'drop' or 'rebuild' option of deduplicate_merge_projection_mode
> ```
>
> すべての移行を実行しないと、ClickHouseインテグレーションは機能しません。

この問題を回避して移行を実行するには、以下の手順に従います:

1. [Railsコンソール](../administration/operations/rails_console.md#starting-a-rails-console-session)にサインインします。
1. 次のコマンドを実行します:

   ```ruby
   ClickHouse::Client.execute("INSERT INTO schema_migrations (version) VALUES ('20231114142100'), ('20240115162101')", :main)
   ```

1. データベースを再度移行します:

   ```shell
   sudo gitlab-rake gitlab:clickhouse:migrate
   ```

今回は、データベースの移行が正常に終了するはずです。

### データベースディクショナリの読み取りサポート {#database-dictionary-read-support}

GitLab 18.8以降、GitLabはデータ非正規化のために[ClickHouse Dictionary](https://clickhouse.com/docs/dictionary)の使用を開始しました。18.8より前の`GRANT`ステートメントは、ディクショナリをクエリするための`gitlab`ユーザーへの許可を与えなかったため、手動による変更手順が必要です:

1. サインインします:
   - ClickHouse Cloudの場合は、ClickHouse SQLコンソールにサインインします。
   - GitLab Self-Managed用ClickHouseの場合は、`clickhouse-client`にサインインします。
1. 次のコマンドを実行し、`PASSWORD_HERE`を生成されたパスワードに置き換えます。

{{< tabs >}}

{{< tab title="単一ノードまたはClickHouse Cloud" >}}

```sql
GRANT dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app;
```

{{< /tab >}}

{{< tab title="HA GitLab Self-Managed用ClickHouse" >}}

`CLUSTER_NAME_HERE`をクラスターの名前に置き換えます:

```sql
GRANT dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
```

{{< /tab >}}

{{< /tabs >}}

権限を付与しないと、ClickHouse移行（`CreateNamespaceTraversalPathsDict`）は次のエラーで失敗します:

```plaintext
DB::Exception: gitlab: Not enough privileges.
```

権限を付与した後は、マイグレーションを安全に再試行できます（1〜2時間待って分散マイグレーションロックが解除されるのを確認してから実行するのが理想です）。

### ClickHouse CIジョブデータマテリアライズドビューのデータの不整合 {#clickhouse-ci-job-data-materialized-view-data-inconsistencies}

GitLab 18.5および以前のバージョンでは、ネットワークタイムアウト後にSidekiqワーカーが再試行すると、重複データがClickHouseテーブル（`ci_finished_pipelines`や`ci_finished_builds`など）に挿入される可能性がありました。この問題により、マテリアライズドビューに、Runnerフリートダッシュボードを含む分析ダッシュボードに誤った集計メトリクスが表示されるようになりました。

この問題はGitLab 18.9で修正され、18.6、18.7、および18.8にバックポートされました。この問題を解決するには、GitLab 18.6以降にアップグレードしてください。

既存の重複データがある場合、影響を受けるマテリアライズドビューをリビルドするための修正は、[イシュー586319](https://gitlab.com/gitlab-org/gitlab/-/issues/586319)でGitLab 18.10で計画されています。支援が必要な場合は、GitLabサポートにお問い合わせください。
