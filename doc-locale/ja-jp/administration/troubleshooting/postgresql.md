---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページには、GitLab Supportチームがトラブルシューティング時に使用するPostgreSQLに関する情報が含まれています。GitLabは、Supportチームが収集した知識を誰もが利用できるように、この情報を公開しています。

> [!warning]
> ここに記載されているいくつかの手順は、お使いのGitLabインスタンスを破損させる可能性があります。ご自身の責任においてご利用ください。

[有料ティア](https://about.gitlab.com/pricing/)をご利用中で、これらのコマンドの使用方法が不明な場合は、お困りの問題について[サポート](https://support.gitlab.com/)にお問い合わせください。

## データベースコンソールを起動する {#start-a-database-console}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

推奨事項:

- 単一ノードインスタンス。
- スケールアウトまたはハイブリッド環境で、Patroniノード（通常はリーダー）上。
- スケールアウトまたはハイブリッド環境で、PostgreSQLサービスを実行しているサーバー上。

```shell
sudo gitlab-psql
```

単一ノードインスタンス、またはWebノードやSidekiqノードでは、Railsコンソールも使用できますが、初期化に時間がかかります:

```shell
sudo gitlab-rails dbconsole --database main
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
docker exec -it <container-id> gitlab-psql
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

[PostgreSQLインストール](../../install/self_compiled/_index.md#7-database)の一部である`psql`コマンドを使用します。

```shell
sudo -u git -H psql -d gitlabhq_production
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

- ハイブリッド環境を実行しており、PostgreSQLがLinuxパッケージインストール（Omnibus）で実行されている場合、推奨されるアプローチは、それらのサーバーでローカルにデータベースコンソールを使用することです。Linuxパッケージの詳細を参照してください。
- 外部のサードパーティPostgreSQLサービスの一部であるコンソールを使用してください。
- ツールボックスポッドで`gitlab-rails dbconsole`を実行します。
  - 詳細については、[Kubernetesチートシート](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/#gitlab-specific-kubernetes-information)を参照してください。

> [!note]
> マネージドPostgreSQLサービス（AWS RDSなど）を使用するクラウドネイティブデプロイの場合、データベース設定ファイルを直接変更することはできません。代わりに、クラウドサービスのパラメータグループまたは設定インターフェースを介してPostgreSQLパラメータを設定します。

{{< /tab >}}

{{< /tabs >}}

コンソールを終了するには、`quit`と入力します。

## その他のGitLab PostgreSQLドキュメント {#other-gitlab-postgresql-documentation}

このセクションは、GitLabドキュメントの他の場所にある情報へのリンクです。

### 手順 {#procedures}

- [Linuxパッケージインストール用のデータベース手順](https://docs.gitlab.com/omnibus/settings/database/)。以下を含みます:
  - SSL: 有効化、無効化、検証。
  - ライトアヘッドログ（WAL）アーカイブの有効化。
  - 外部（Omnibus以外）のPostgreSQLインストールを使用し、それをバックアップする。
  - ソケットだけでなくTCP/IPでもリッスンする、またはソケットの代わりにTCP/IPでリッスンする。
  - データを別の場所に保存する。
  - GitLabデータベースを破壊的に再シードする。
  - パッケージ化されたPostgreSQLの更新に関するガイダンス。自動的に更新されないようにする方法を含みます。
- [外部PostgreSQLに関する情報](../postgresql/external.md)。
- [外部PostgreSQLでGeoを実行する](../geo/setup/external_database.md)。
- [HA用に設定されたPostgreSQLを実行している場合のアップグレード](https://docs.gitlab.com/omnibus/settings/database/#upgrading-a-gitlab-ha-cluster)。
- [CI Runner内](../../ci/services/postgres.md)からPostgreSQLを使用する。
- Linuxパッケージ開発ドキュメントからのLinuxパッケージインストールにおけるPostgreSQLバージョンの管理。
- [PostgreSQLのスケーリング](../postgresql/replication_and_failover.md)
  - これには[トラブルシューティング](../postgresql/replication_and_failover_troubleshooting.md) `gitlab-ctl patroni check-leader`とPgBouncerエラーが含まれます。
- デベロッパーデータベースドキュメント。その一部は、決して本番環境で使用してはなりません。以下を含む:
  - EXPLAINプランの理解。

## Supportトピック {#support-topics}

### データベースデッドロック {#database-deadlocks}

参照: 

- [インスタンスがプッシュで溢れると、デッドロックが発生する可能性があります](https://gitlab.com/gitlab-org/gitlab/-/issues/33650)。GitLabのコードが、異常な状況でこのような予期せぬ影響をどのように与えるかについて、コンテキストを提供します。

```plaintext
ERROR: deadlock detected
```

[\#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)のイシューで3つの適用可能なタイムアウトが特定されています。推奨される設定は次のとおりです:

```ini
deadlock_timeout = 5s
statement_timeout = 15s
idle_in_transaction_session_timeout = 60s
```

イシュー[\#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)からの引用:

<!-- vale gitlab_base.FutureTense = NO -->

> 「デッドロックが発生し、短い期間でトランザクションを中断して解決する場合、既存の再試行メカニズムによりデッドロックした作業が再度試行され、連続して複数回デッドロックが発生する可能性は低くなります。」

<!-- vale gitlab_base.FutureTense = YES -->

> [!note]
> Supportでは、タイムアウトを再構成する（HTTPスタックにも適用されます）一般的なアプローチとして、一時的に回避策として実行することは許容できると考えています。顧客にとってGitLabが使用可能になる場合、それは問題をより完全に理解し、ホット修正を実装し、または根本原因に対処する他の変更を行うための時間を稼ぎます。一般的に、根本原因が解決する後、タイムアウトは合理的なデフォルトに戻されるべきです。

この場合、開発からのガイダンスは`deadlock_timeout`または`statement_timeout`を削除し、3番目の設定を60秒のままにすることでした。`idle_in_transaction`を設定すると、データベースを何日もハングアップする可能性のあるセッションから保護します。[GitLab.comでこのタイムアウトを導入することに関連するイシュー](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1053)には、さらにディスカッションがあります。

PostgreSQLのデフォルト:

- `statement_timeout = 0`（なし）
- `idle_in_transaction_session_timeout = 0`（なし）

イシュー[\#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)のコメントは、これら両方をすべてのLinuxパッケージインストールで少なくとも数分に設定する必要があることを示しています（無期限にハングしないようにするため）。ただし、`statement_timeout`の15秒は非常に短く、基盤となるインフラストラクチャが非常に高性能である場合にのみ有効です。

現在の設定を確認する:

```shell
sudo gitlab-rails runner "c = ApplicationRecord.connection ; puts c.execute('SHOW statement_timeout').to_a ;
puts c.execute('SHOW deadlock_timeout').to_a ;
puts c.execute('SHOW idle_in_transaction_session_timeout').to_a ;"
```

応答に少し時間がかかる場合があります。

```ruby
{"statement_timeout"=>"1min"}
{"deadlock_timeout"=>"0"}
{"idle_in_transaction_session_timeout"=>"1min"}
```

これらの設定は、`/etc/gitlab/gitlab.rb`で更新できます:

```ruby
postgresql['deadlock_timeout'] = '5s'
postgresql['statement_timeout'] = '15s'
postgresql['idle_in_transaction_session_timeout'] = '60s'
```

保存したら、変更を有効にするために[GitLabを再構成](../restart_gitlab.md#reconfigure-a-linux-package-installation)してください。

> [!note]
> これらはLinuxパッケージの設定です。顧客のPostgreSQLインストールまたはAmazon RDSなどの外部データベースが使用されている場合、これらの値は設定されず、外部で設定する必要があります。

### ステートメントタイムアウトの一時的な変更 {#temporarily-changing-the-statement-timeout}

> [!warning]
> [PgBouncer](../postgresql/pgbouncer.md)が有効な場合、変更されたタイムアウトが意図したよりも多くのトランザクションに影響を与える可能性があるため、以下の助言は適用されません。

特定の状況では、[GitLabを再構成](../restart_gitlab.md#reconfigure-a-linux-package-installation)することなく、異なるステートメントタイムアウトを設定することが望ましい場合があります。この場合、PumaとSidekiqが再起動します。

例えば、ステートメントタイムアウトが短すぎたため、[バックアップコマンド](../backup_restore/_index.md#back-up-gitlab)の出力で以下のエラーが発生し、バックアップが失敗する場合があります:

```plaintext
pg_dump: error: Error message from server: server closed the connection unexpectedly
```

[PostgreSQLログ](../logs/_index.md#postgresql-logs)にもエラーが表示される場合があります:

```plaintext
canceling statement due to statement timeout
```

#### Linuxパッケージインストールの場合 {#for-linux-package-installations}

ステートメントタイムアウトを一時的に変更するには:

1. `/var/opt/gitlab/gitlab-rails/etc/database.yml`をエディタで開きます
1. `statement_timeout`の値を`0`に設定します。これにより、無制限のステートメントタイムアウトが設定されます。
1. この値が使用されていることを[新しいRailsコンソールセッションで確認](../operations/rails_console.md#using-the-rails-runner)します:

   ```shell
   sudo gitlab-rails runner "ActiveRecord::Base.connection_db_config[:variables]"
   ```

1. 異なるタイムアウトが必要なアクション（例えばバックアップやRailsコマンド）を実行します。
1. `/var/opt/gitlab/gitlab-rails/etc/database.yml`の編集を元に戻します。

#### クラウドネイティブデプロイの場合 {#for-cloud-native-deployments}

マネージドPostgreSQLサービス（AWS RDS、Azure Database for PostgreSQL、Google Cloud SQLなど）を使用するクラウドネイティブデプロイの場合、データベース設定ファイルを直接変更することはできません。代わりに、クラウドサービスのパラメータグループまたは設定インターフェースを介して`statement_timeout`パラメータを設定します:

- **AWS RDS**: データベースインスタンスに関連付けられたパラメータグループを変更し、`statement_timeout`を`0`（無制限）に設定します。
- **Azure Database for PostgreSQL**: Azureポータルでサーバーパラメータを更新し、`statement_timeout`を`0`に設定します。
- **Google Cloud SQL**: データベースフラグを変更し、`statement_timeout`を`0`に設定します。

パラメータグループまたは設定に変更を加えた後、変更を有効にするためにデータベースインスタンスを再起動する必要がある場合があります。特定の指示については、クラウドプロバイダーのドキュメントを参照してください。

### （再）インデックス進捗レポートの監視 {#observe-reindex-progress-report}

特定の状況では、`CREATE INDEX`または`REINDEX`操作の進捗状況を監視したい場合があります。例えば、`CREATE INDEX`または`REINDEX`操作がアクティブであるか、または操作がどのフェーズにあるかを確認するためにこれを行うことができます。

前提条件: 

- PostgreSQLバージョン12以降を使用する必要があります。

`CREATE INDEX`または`REINDEX`操作を監視するには:

- 組み込みの[`pg_stat_progress_create_index`ビュー](https://www.postgresql.org/docs/16/progress-reporting.html#CREATE-INDEX-PROGRESS-REPORTING)を使用します。

例えば、データベースコンソールセッションから、次のコマンドを実行します:

```sql
SELECT * FROM  pg_stat_progress_create_index \watch 0.2
```

人間が判読しやすい出力の生成とログファイルへのデータ書き込みの詳細については、[このスニペット](https://gitlab.com/-/snippets/3750940)を参照してください。

## トラブルシューティング {#troubleshooting}

### データベース接続が拒否されました {#database-connection-is-refused}

次のエラーが発生した場合、安定した接続を確保するのに`max_connections`が十分な高さであるかを確認してください。

```shell
connection to server at "xxx.xxx.xxx.xxx", port 5432 failed: Connection refused
      Is the server running on that host and accepting TCP/IP connections?
```

```shell
psql: error: connection to server on socket "/var/opt/gitlab/postgresql/.s.PGSQL.5432" failed:
FATAL:  sorry, too many clients already
```

`max_connections`を調整するには、[複数のデータベース接続の設定](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections)を参照してください。

### データベースがラップアラウンドによるデータ損失を回避するためにコマンドを受け付けていません {#database-is-not-accepting-commands-to-avoid-wraparound-data-loss}

このエラーは、`autovacuum`が実行を失敗していることを意味している可能性があります:

```plaintext
ERROR:  database is not accepting commands to avoid wraparound data loss in database "gitlabhq_production"
```

または

```plaintext
 ERROR:  failed to re-find parent key in index "XXX" for deletion target page XXX
```

エラーを解決するには、`VACUUM`を手動で実行します:

1. コマンド`gitlab-ctl stop`でGitLabを停止します。
1. 次のコマンドでデータベースをシングルユーザーモードにします:

   ```shell
   /opt/gitlab/embedded/bin/postgres --single -D /var/opt/gitlab/postgresql/data gitlabhq_production
   ```

1. `backend>`プロンプトで、`VACUUM;`を実行します。このコマンドの完了には数分かかる場合があります。
1. コマンドが完了するのを待ってから、<kbd>Control</kbd> + <kbd>D</kbd>を押して終了します。
1. コマンド`gitlab-ctl start`でGitLabを起動します。

### GitLabデータベースの要件 {#gitlab-database-requirements}

[データベース要件](../../install/requirements.md#postgresql)を参照し、[必要な拡張機能リスト](../../install/requirements.md#extensions)を確認してインストールしてください。

### `production/sidekiq`ログでのシリアライズエラー {#serialization-errors-in-the-productionsidekiq-log}

お使いの`production/sidekiq`ログでこの例のようなエラーが発生した場合、問題を修正するために[`default_transaction_isolation`を読み込みコミットに設定する](https://docs.gitlab.com/omnibus/settings/database/#set-default_transaction_isolation-into-read-committed)方法について読んでください:

```plaintext
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

### PostgreSQLレプリケーションスロットエラー {#postgresql-replication-slot-errors}

この例のようなエラーが発生した場合、PostgreSQL HAの[レプリケーションスロットエラー](https://docs.gitlab.com/omnibus/settings/database/#troubleshooting-upgrades-in-an-ha-cluster)を解決する方法について読んでください:

```plaintext
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.
```

### Geoレプリケーションエラー {#geo-replication-errors}

この例のようなエラーが発生した場合、[Geoレプリケーションエラー](../geo/replication/troubleshooting/postgresql_replication.md)を解決する方法について読んでください:

```plaintext
ERROR: replication slots can only be used if max_replication_slots > 0

FATAL: could not start WAL streaming: ERROR: replication slot "geo_secondary_my_domain_com" does not exist

Command exceeded allowed execution time

PANIC: could not write to file 'pg_xlog/xlogtemp.123': No space left on device
```

### Geo設定と一般的なエラーのレビュー {#review-geo-configuration-and-common-errors}

Geoに関する問題をトラブルシューティングする際には、次のようにします:

- 一般的な[Geoエラー](../geo/replication/troubleshooting/common.md#fixing-common-errors)を確認してください。
- [お使いのGeo設定を確認](../geo/replication/troubleshooting/_index.md)してください。以下を含みます:
  - ホストとポートの再設定。
  - ユーザーとパスワードのマッピングを確認し、修正する。

### `pg_dump`と`psql`バージョンの不一致 {#mismatch-in-pg_dump-and-psql-versions}

この例のようなエラーが発生した場合、[パッケージ化されていないPostgreSQLデータベースをバックアップして復元する](https://docs.gitlab.com/omnibus/settings/database/#backup-and-restore-a-non-packaged-postgresql-database)方法について読んでください:

```plaintext
Dumping PostgreSQL database gitlabhq_production ... pg_dump: error: server version: 13.3; pg_dump version: 14.2
pg_dump: error: aborting because of server version mismatch
```

### 拡張機能`btree_gist`は許可リストにありません {#extension-btree_gist-is-not-allow-listed}

Azure Database for PostgreSQL - Flexible ServerにPostgreSQLをデプロイすると、このエラーが発生する可能性があります:

```plaintext
extension "btree_gist" is not allow-listed for "azure_pg_admin" users in Azure Database for PostgreSQL
```

このエラーを解決するには、インストール前に[拡張機能を許可リストに追加](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions)してください。
