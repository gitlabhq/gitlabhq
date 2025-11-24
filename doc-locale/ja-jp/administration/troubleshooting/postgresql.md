---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: PostgreSQL
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、GitLabサポートチームがトラブルシューティング時に使用するPostgreSQLに関する情報を提供しています。GitLabはこの情報を公開しているため、誰でもサポートチームが集めた知識を利用できます。

{{< alert type="warning" >}}

ここにドキュメント化されている一部の手順は、GitLabインスタンスを破損させる可能性があります。ご自身の責任においてご利用ください。

{{< /alert >}}

[有料プラン](https://about.gitlab.com/pricing/)をご利用で、これらのコマンドの使用方法が不明な場合は、発生している問題について[サポートにお問い合わせ](https://about.gitlab.com/support/)ください。

## データベースコンソールを起動します {#start-a-database-console}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

推奨される利用環境:

- シングルノードインスタンス。
- 通常リーダーであるPatroniノード上の、スケールアウトされた環境またはハイブリッド環境。
- スケールアウトされた環境またはハイブリッド環境（PostgreSQLサービスを実行しているサーバー上）。

```shell
sudo gitlab-psql
```

シングルノードインスタンス、またはWebもしくはSidekiqノードでは、Railsコンソールを使用することもできますが、初期化に時間がかかります:

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

[PostgreSQLのインストール](../../install/self_compiled/_index.md#7-database)に含まれる`psql`コマンドを使用します。

```shell
sudo -u git -H psql -d gitlabhq_production
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

- ハイブリッド環境で、PostgreSQLがLinuxパッケージインストール（Omnibus）で実行されている場合は、これらのサーバーでローカルにデータベースコンソールを使用することをお勧めします。Linuxパッケージの詳細を参照してください。
- 外部のサードパーティPostgreSQLサービスの一部であるコンソールを使用します。
- toolboxポッドで`gitlab-rails dbconsole`を実行します。
  - 詳細については、[Kubernetesチートシート](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html#gitlab-specific-kubernetes-information)を参照してください。

{{< /tab >}}

{{< /tabs >}}

コンソールを終了するには、`quit`と入力します。

## その他のGitLab PostgreSQLドキュメント {#other-gitlab-postgresql-documentation}

このセクションは、GitLabドキュメント内の他の場所へのリンク用です。

### 手順 {#procedures}

- 以下を含む[Linuxパッケージインストールのためのデータベース手順](https://docs.gitlab.com/omnibus/settings/database.html):
  - SSL：有効化、無効化、および検証。
  - Write Ahead Log（WAL）のアーカイブの有効化。
  - 外部（非Omnibus）PostgreSQLインストールの使用、およびそのバックアップ。
  - ソケットに加えて、またはソケットの代わりに、TCP/IPでリッスン。
  - 別の場所にデータを保存。
  - GitLabデータベースの破壊的な再シード。
  - パッケージ化されたPostgreSQLの更新に関するガイダンス（自動的に更新されないようにする方法を含む）。

- [外部PostgreSQLに関する情報](../postgresql/external.md)。

- [外部PostgreSQLでGeo](../geo/setup/external_database.md)を実行しています。

- [HA用に構成されたPostgreSQLを実行している場合のアップグレード](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-gitlab-ha-cluster)。

- [CI Runner内](../../ci/services/postgres.md)からPostgreSQLを使用します。

- Linuxパッケージ開発ドキュメントから、LinuxパッケージインストールでのPostgreSQLバージョンの管理。

- [PostgreSQLのスケール](../postgresql/replication_and_failover.md)
  - `gitlab-ctl patroni check-leader`およびPgBouncerエラーの[トラブルシューティング](../postgresql/replication_and_failover_troubleshooting.md)を含みます。

- デベロッパーデータベースドキュメント。一部は本番環境用ではありません。以下を含みます:
  - EXPLAINプランについて理解する

## サポートトピック {#support-topics}

### データベースのデッドロック {#database-deadlocks}

参照:

- [インスタンスがプッシュでいっぱいになると、デッドロックが発生する可能性があります](https://gitlab.com/gitlab-org/gitlab/-/issues/33650)。GitLabコードが異常な状況でこの種の予期しない影響を与える可能性がある方法に関するコンテキストを提供しました。

```plaintext
ERROR: deadlock detected
```

3つの適用可能なタイムアウトが[イシュー#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)で特定されています。推奨設定は次のとおりです:

```ini
deadlock_timeout = 5s
statement_timeout = 15s
idle_in_transaction_session_timeout = 60s
```

[イシュー#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)から引用:

<!-- vale gitlab_base.FutureTense = NO -->

> 「デッドロックが発生し、短期間でトランザクションを中断することでそれを解決する場合、すでに持っている再試行メカニズムにより、デッドロックした作業が再度試行され、連続して複数回デッドロックが発生する可能性は低くなります。」

<!-- vale gitlab_base.FutureTense = YES -->

{{< alert type="note" >}}

サポートでは、タイムアウトの再構成（HTTPスタックにも適用されます）に対する一般的なアプローチは、回避策として一時的に行うのが許容されるということです。これにより、GitLabを顧客が使用できるようになる場合は、問題をより完全に理解し、ホット修正を実装するか、根本原因に対処する他の変更を行うための時間を稼ぐことができます。一般に、根本原因が解決されたら、タイムアウトを適切なデフォルトに戻す必要があります。

{{< /alert >}}

この場合、開発からのガイダンスは、`deadlock_timeout`または`statement_timeout`を削除することでしたが、3番目の設定は60秒のままにすることでした。`idle_in_transaction`を設定すると、データベースが数日間ハングする可能性のあるセッションから保護されます。[GitLab.comでこのタイムアウトの導入に関連するイシュー](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1053)で、さらにディスカッションが行われています。

PostgreSQLのデフォルト:

- `statement_timeout = 0`（設定なし）
- `idle_in_transaction_session_timeout = 0`（設定なし）

[イシュー#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)のコメントでは、これらは両方とも、すべてのLinuxパッケージインストールで少なくとも数分に設定する必要があることを示しています（したがって、無期限にハングしません）。ただし、`statement_timeout`の15秒は非常に短く、基盤となるインフラストラクチャのパフォーマンスが非常に高い場合にのみ有効です。

現在の設定を以下で確認します:

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

保存したら、変更を反映するために[GitLabを再構成](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< alert type="note" >}}

これらは、Linuxパッケージの設定です。顧客のPostgreSQLインストールやAmazon RDSなどの外部データベースが使用されている場合、これらの値は設定されず、外部で設定する必要があります。

{{< /alert >}}

### タイムアウトステートメントの一時的な変更 {#temporarily-changing-the-statement-timeout}

{{< alert type="warning" >}}

[PgBouncer](../postgresql/pgbouncer.md)が有効になっている場合、変更されたタイムアウトが意図したよりも多くのトランザクションに影響を与える可能性があるため、以下のアドバイスは適用されません。

{{< /alert >}}

[GitLabを再構成](../restart_gitlab.md#reconfigure-a-linux-package-installation)せずに、別のタイムアウトステートメントを設定することが望ましい場合があります。この場合、PumaとSidekiqが再起動されます。

たとえば、ステートメントのタイムアウトが短すぎるため、[バックアップコマンド](../backup_restore/_index.md#back-up-gitlab)の出力で次のエラーが発生して、バックアップが失敗する可能性があります:

```plaintext
pg_dump: error: Error message from server: server closed the connection unexpectedly
```

[PostgreSQLログファイル](../logs/_index.md#postgresql-logs)にエラーが表示されることもあります:

```plaintext
canceling statement due to statement timeout
```

タイムアウトステートメントを一時的に変更するには:

1. `/var/opt/gitlab/gitlab-rails/etc/database.yml`をエディタで開きます。
1. `statement_timeout`の値を`0`に設定します。これにより、無制限のステートメントタイムアウトが設定されます。
1. この値が使用されていることを[新しいRailsコンソールセッションで確認](../operations/rails_console.md#using-the-rails-runner)します:

   ```shell
   sudo gitlab-rails runner "ActiveRecord::Base.connection_db_config[:variables]"
   ```

1. 別のタイムアウトが必要なアクション（たとえば、バックアップまたはRailsコンソールコマンド）を実行します。
1. `/var/opt/gitlab/gitlab-rails/etc/database.yml`の編集を元に戻します。

### (RE)INDEXの進捗レポートを監視する {#observe-reindex-progress-report}

状況によっては、`CREATE INDEX`または`REINDEX`操作の進捗状況を監視したい場合があります。たとえば、`CREATE INDEX`または`REINDEX`操作がアクティブであるかどうかを確認したり、操作がどのフェーズにあるかを確認したりするために、これを行うことができます。

前提要件: 

- PostgreSQLバージョン12以降を使用する必要があります。

`CREATE INDEX`または`REINDEX`操作を監視するには:

- 組み込みの[`pg_stat_progress_create_index`ビュー](https://www.postgresql.org/docs/16/progress-reporting.html#CREATE-INDEX-PROGRESS-REPORTING)を使用します。

たとえば、データベースコンソールセッションから、次のコマンドを実行します:

```sql
SELECT * FROM  pg_stat_progress_create_index \watch 0.2
```

人間にとってわかりやすい出力の作成とデータをログファイルに書き込む方法の詳細については、[このスニペット](https://gitlab.com/-/snippets/3750940)を参照してください。

## トラブルシューティング {#troubleshooting}

### データベース接続が拒否されました {#database-connection-is-refused}

次のエラーが発生した場合は、安定した接続を確保するために`max_connections`が十分に高いかどうかを確認してください。

```shell
connection to server at "xxx.xxx.xxx.xxx", port 5432 failed: Connection refused
      Is the server running on that host and accepting TCP/IP connections?
```

```shell
psql: error: connection to server on socket "/var/opt/gitlab/postgresql/.s.PGSQL.5432" failed:
FATAL:  sorry, too many clients already
```

`max_connections`を調整するには、[複数のデータベース接続の構成](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections)を参照してください。

### データベースは、データ損失のラップアラウンドを回避するためにコマンドを受け入れていません {#database-is-not-accepting-commands-to-avoid-wraparound-data-loss}

このエラーは、`autovacuum`の実行が完了しなかったことを意味する可能性があります:

```plaintext
ERROR:  database is not accepting commands to avoid wraparound data loss in database "gitlabhq_production"
```

または

```plaintext
 ERROR:  failed to re-find parent key in index "XXX" for deletion target page XXX
```

エラーを解決するには、`VACUUM`を手動で実行します:

1. コマンド`gitlab-ctl stop`でGitLabを停止します。
1. 次のコマンドを使用して、データベースをシングルユーザーモードにします:

   ```shell
   /opt/gitlab/embedded/bin/postgres --single -D /var/opt/gitlab/postgresql/data gitlabhq_production
   ```

1. `backend>`プロンプトで、`VACUUM;`を実行します。このコマンドが完了するまでに数分かかる場合があります。
1. コマンドが完了するのを待ってから、<kbd>Control</kbd> + <kbd>D</kbd>を押して終了します。
1. コマンド`gitlab-ctl start`でGitLabを起動します。

### GitLabデータベース要件 {#gitlab-database-requirements}

[データベース要件](../../install/requirements.md#postgresql)を参照して、[必要な拡張機能リスト](../../install/postgresql_extensions.md)を確認してインストールします。

### `production/sidekiq`ログファイルのシリアライズエラー {#serialization-errors-in-the-productionsidekiq-log}

`production/sidekiq`ログファイルにこの例のようなエラーが表示される場合は、問題を修正するために[`default_transaction_isolation`を読み取りコミット済みに設定する](https://docs.gitlab.com/omnibus/settings/database.html#set-default_transaction_isolation-into-read-committed)方法をお読みください:

```plaintext
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

### PostgreSQLレプリケーションスロットエラー {#postgresql-replication-slot-errors}

この例のようなエラーが表示された場合は、PostgreSQL HA [レプリケーションスロットエラー](https://docs.gitlab.com/omnibus/settings/database.html#troubleshooting-upgrades-in-an-ha-cluster)を解決する方法をお読みください:

```plaintext
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.
```

### Geoレプリケーションエラー {#geo-replication-errors}

この例のようなエラーが表示された場合は、[Geoレプリケーションエラー](../geo/replication/troubleshooting/postgresql_replication.md)を解決する方法をお読みください:

```plaintext
ERROR: replication slots can only be used if max_replication_slots > 0

FATAL: could not start WAL streaming: ERROR: replication slot "geo_secondary_my_domain_com" does not exist

Command exceeded allowed execution time

PANIC: could not write to file 'pg_xlog/xlogtemp.123': No space left on device
```

### Geo設定と一般的なエラーの確認 {#review-geo-configuration-and-common-errors}

Geoに関する問題をトラブルシューティングする場合は、次のようにする必要があります:

- [一般的なGeoエラー](../geo/replication/troubleshooting/common.md#fixing-common-errors)を確認します。
- 次を含む[Geo設定を確認](../geo/replication/troubleshooting/_index.md)します:
  - ホストとポートの再設定。
  - ユーザーとパスワードのマッピングを確認して修正します。

### `pg_dump`と`psql`のバージョンの不一致 {#mismatch-in-pg_dump-and-psql-versions}

この例のようなエラーが表示された場合は、[パッケージ化されていないPostgreSQLデータベースをバックアップおよび復元する方法](https://docs.gitlab.com/omnibus/settings/database.html#backup-and-restore-a-non-packaged-postgresql-database)をお読みください:

```plaintext
Dumping PostgreSQL database gitlabhq_production ... pg_dump: error: server version: 13.3; pg_dump version: 14.2
pg_dump: error: aborting because of server version mismatch
```

### 拡張機能`btree_gist`が許可リストに登録されていません {#extension-btree_gist-is-not-allow-listed}

PostgreSQL用Azureデータベース-フレキシブルサーバーにPostgreSQLをデプロイすると、次のエラーが発生する可能性があります:

```plaintext
extension "btree_gist" is not allow-listed for "azure_pg_admin" users in Azure Database for PostgreSQL
```

このエラーを解決するには、インストールする前に[拡張機能を許可リストに登録](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions)します。
