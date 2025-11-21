---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo PostgreSQLレプリケーションのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

次のセクションでは、レプリケーションエラーメッセージ（[`geo:check`の出力](common.md#health-check-rake-task)で`Database replication working? ... no`で示されます）を修正するためのトラブルシューティング手順の概要を説明します。ここに記載されている手順は、ほとんどの場合、シングルノードのGeo Linuxパッケージのデプロイを前提としており、異なる環境に合わせて調整する必要がある場合があります。

## 非アクティブなレプリケーションスロットの削除 {#removing-an-inactive-replication-slot}

レプリケーションクライアント（セカンダリサイト）がスロットへの接続を切断すると、レプリケーションスロットは「非アクティブ」としてマークされます。非アクティブなレプリケーションスロットは、再接続時およびスロットが再びアクティブになったときにクライアントに送信されるため、WALファイルが保持されます。セカンダリサイトが再接続できない場合は、次の手順に従って、対応する非アクティブなレプリケーションスロットを削除してください:

1. Geoプライマリサイトのデータベースノードで、[PostgreSQLコンソールセッションを開始](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-postgresql-database)します:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

   {{< alert type="note" >}}

   `gitlab-rails dbconsole`を使用しても、レプリケーションスロットの管理にはスーパーユーザー権限が必要なため、機能しません。

   {{< /alert >}}

1. レプリケーションスロットを表示し、非アクティブな場合は削除します:

   ```sql
   SELECT * FROM pg_replication_slots;
   ```

   `active`が`f`のスロットは非アクティブです。

- そのスロットを使用するように構成された**セカンダリ**サイトがあるため、このスロットがアクティブになっているはずの場合:
  - レプリケーションが実行されていない理由を表示するには、**セカンダリ**サイトの[PostgreSQLログ](../../../logs/_index.md#postgresql-logs)を確認してください。
  - セカンダリサイトが再接続できなくなった場合:

    1. PostgreSQLコンソールセッションを使用してスロットを削除します:

       ```sql
       SELECT pg_drop_replication_slot('<name_of_inactive_slot>');
       ```

    1. [レプリケーションプロセスを再開](../../setup/database.md#step-3-initiate-the-replication-process)すると、レプリケーションスロットが正しく再作成されます。

- スロットをもう使用していない場合（たとえば、Geoが有効になっていない場合）、[そのGeoサイトを削除](../remove_geo_site.md)する手順に従います。

## メッセージ: `WARNING: oldest xmin is far in the past`および`pg_wal`サイズの増大 {#message-warning-oldest-xmin-is-far-in-the-past-and-pg_wal-size-growing}

レプリケーションスロットが非アクティブの場合、スロットに対応する`pg_wal`ログは永久に予約されます（またはスロットが再びアクティブになるまで）。これにより、ディスクI/O使用量が増加し続け、[PostgreSQLログ](../../../logs/_index.md#postgresql-logs)に次のメッセージが繰り返し表示されます:

```plaintext
WARNING: oldest xmin is far in the past
HINT: Close open transactions soon to avoid wraparound problems.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
```

これを解決するには、[非アクティブなレプリケーションスロットを削除](#removing-an-inactive-replication-slot)して、レプリケーションを再開する必要があります。

## メッセージ: `ERROR:  replication slots can only be used if max_replication_slots > 0`? {#message-error--replication-slots-can-only-be-used-if-max_replication_slots--0}

これは、`max_replication_slots`というPostgreSQLの変数を**プライマリ**データベースに設定する必要があることを意味します。この設定のデフォルトは1です。**セカンダリ**サイトが多い場合は、この値を大きくする必要があるかもしれません。

これを有効にするには、PostgreSQLを再起動してください。詳細については、[PostgreSQLレプリケーションのセットアップ](../../setup/database.md#postgresql-replication)ガイドを参照してください。

## メッセージ: `replication slot "geo_secondary_my_domain_com" does not exist` {#message-replication-slot-geo_secondary_my_domain_com-does-not-exist}

このエラーは、PostgreSQLに、その名前の**セカンダリ**サイトのレプリケーションスロットがない場合に発生します:

```plaintext
FATAL:  could not start WAL streaming: ERROR:  replication slot "geo_secondary_my_domain_com" does not exist
```

**セカンダリ**サイトで[レプリケーションプロセス](../../setup/database.md)を再実行することをお勧めします。

## メッセージ: レプリケーションの設定時に`Command exceeded allowed execution time`？ {#message-command-exceeded-allowed-execution-time-when-setting-up-replication}

これは、**セカンダリ**サイトで[レプリケーションプロセスを開始](../../setup/database.md#step-3-initiate-the-replication-process)するときに発生する可能性があり、初期データセットが大きすぎて、デフォルトのタイムアウト（30分）でレプリケートできないことを示しています。

`gitlab-ctl replicate-geo-database`を再実行しますが、`--backup-timeout`のより大きな値を含めます:

```shell
sudo gitlab-ctl \
   replicate-geo-database \
   --host=<primary_node_hostname> \
   --slot-name=<secondary_slot_name> \
   --backup-timeout=21600
```

これにより、初期レプリケーションは、デフォルトの30分ではなく、最大6時間で完了します。インストールに必要な調整を行います。

## メッセージ: `PANIC: could not write to file 'pg_xlog/xlogtemp.123': No space left on device` {#message-panic-could-not-write-to-file-pg_xlogxlogtemp123-no-space-left-on-device}

**プライマリ**データベースに、未使用のレプリケーションスロットがあるかどうかを判断します。これにより、大量のログデータが`pg_xlog`に蓄積される可能性があります。

[非アクティブなスロットを削除](#removing-an-inactive-replication-slot)すると、`pg_xlog`で使用される容量を削減できます。

## メッセージ: `ERROR: canceling statement due to conflict with recovery` {#message-error-canceling-statement-due-to-conflict-with-recovery}

このエラーメッセージは、通常の使用ではまれに発生し、システムは回復するのに十分な回復力があります。

ただし、特定の条件下では、セカンダリでの一部のデータベースクエリの実行時間が過度に長くなり、このエラーメッセージの頻度が増加する可能性があります。これにより、すべてのレプリケーションでキャンセルされるため、一部のクエリが完了しない状況が発生する可能性があります。

これらの長時間実行されているクエリは[将来削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/34269)ですが、回避策として、[`hot_standby_feedback`](https://www.postgresql.org/docs/16/hot-standby.html#HOT-STANDBY-CONFLICT)を有効にすることをお勧めします。これにより、`VACUUM`が最近削除された行を削除できなくなるため、**プライマリ**サイトでの肥大化の可能性が高まります。ただし、GitLab.comの本番環境では正常に使用されています。

`hot_standby_feedback`を有効にするには、**セカンダリ**サイトの`/etc/gitlab/gitlab.rb`に次を追加します:

```ruby
postgresql['hot_standby_feedback'] = 'on'
```

次に、GitLabを再構成します:

```shell
sudo gitlab-ctl reconfigure
```

この問題を解決するために、[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/4489)にコメントすることを検討してください。

## メッセージ: `server certificate for "PostgreSQL" does not match host name` {#message-server-certificate-for-postgresql-does-not-match-host-name}

このエラーが表示された場合:

```plaintext
FATAL:  could not connect to the primary server: server certificate for "PostgreSQL" does not match host name
```

これは、Linuxパッケージが自動的に作成するPostgreSQL証明書に共通名`PostgreSQL`が含まれていますが、レプリケーションは別のホストに接続しており、GitLabはデフォルトで`verify-full` SSLモードを使用しようとするために発生します。

この問題を修正するには、次のいずれかを実行します:

- `replicate-geo-database`コマンドで`--sslmode=verify-ca`引数を使用します。
- すでにレプリケートされたデータベースの場合は、`/var/opt/gitlab/postgresql/data/gitlab-geo.conf`の`sslmode=verify-full`を`sslmode=verify-ca`に変更し、`gitlab-ctl restart postgresql`を実行します。
- 自動的に生成された証明書を使用する代わりに、カスタム証明書（データベースへの接続に使用されるホスト名を含むCNまたはSAN）を使用して[PostgreSQLのSSLを構成](https://docs.gitlab.com/omnibus/settings/database.html#configuring-ssl)します。

## メッセージ: `LOG:  invalid CIDR mask in address` {#message-log--invalid-cidr-mask-in-address}

これは、`postgresql['md5_auth_cidr_addresses']`の形式が誤ったアドレスで発生します。

```plaintext
2020-03-20_23:59:57.60499 LOG:  invalid CIDR mask in address "***"
2020-03-20_23:59:57.60501 CONTEXT:  line 74 of configuration file "/var/opt/gitlab/postgresql/data/pg_hba.conf"
```

これを修正するには、CIDR形式（たとえば、`10.0.0.1/32`）を尊重するように、`postgresql['md5_auth_cidr_addresses']`の`/etc/gitlab/gitlab.rb`のIPアドレスを更新します。

## メッセージ: `LOG:  invalid IP mask "md5": Name or service not known` {#message-log--invalid-ip-mask-md5-name-or-service-not-known}

これは、`postgresql['md5_auth_cidr_addresses']`でサブネットマスクなしでIPアドレスを追加した場合に発生します。

```plaintext
2020-03-21_00:23:01.97353 LOG:  invalid IP mask "md5": Name or service not known
2020-03-21_00:23:01.97354 CONTEXT:  line 75 of configuration file "/var/opt/gitlab/postgresql/data/pg_hba.conf"
```

これを修正するには、CIDR形式（たとえば、`10.0.0.1/32`）を尊重するように、`postgresql['md5_auth_cidr_addresses']`の`/etc/gitlab/gitlab.rb`にサブネットマスクを追加します。

## メッセージ: `Found data in the gitlabhq_production database` {#message-found-data-in-the-gitlabhq_production-database}

`gitlab-ctl replicate-geo-database`の実行時にエラー`Found data in the gitlabhq_production database!`が表示された場合、`projects`テーブルでデータが検出されました。1つ以上のプロジェクトが検出されると、誤ったデータ損失を防ぐために操作は中断されます。このメッセージを回避するには、コマンドに`--force`オプションを渡します。

## メッセージ: `FATAL:  could not map anonymous shared memory: Cannot allocate memory` {#message-fatal--could-not-map-anonymous-shared-memory-cannot-allocate-memory}

このメッセージが表示された場合、セカンダリサイトのPostgreSQLが、使用可能なメモリよりも高いメモリをリクエストしようとしていることを意味します。この問題を追跡する[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/381585)があります。

Patroniログ（Linuxパッケージインストールの場合は`/var/log/gitlab/patroni/current`にあります）のエラーメッセージの例:

```plaintext
2023-11-21_23:55:18.63727 FATAL:  could not map anonymous shared memory: Cannot allocate memory
2023-11-21_23:55:18.63729 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory, swap space, or huge pages. To reduce the request size (currently 17035526144 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
```

回避策は、プライマリサイトのPostgreSQLノードのメモリ要件に合わせて、セカンダリサイトのPostgreSQLノードで使用可能なメモリを増やすことです。

## メッセージ: `could not open certificate file "/root/.postgresql/postgresql.crt"` {#message-could-not-open-certificate-file-rootpostgresqlpostgresqlcrt}

このエラーが表示された場合:

```plaintext
sql: error: connection to server at "x.x.x.x", port 5432 failed:
could not open certificate file "/root/.postgresql/postgresql.crt": Permission denied...
```

このエラーは、`psql`や`libpq`を使用するアプリケーションなどのPostgreSQLクライアントが、`/root/.postgresql/postgresql.crt`などの特定のデフォルトの場所でクライアントSSL証明書を検索するために発生します。ただし、このエラーメッセージは誤解を招く可能性があります。GitLabレプリケーションユーザーに間違ったパスワードを使用するなど、他の理由で認証が失敗した場合によく発生します。SSL証明書の問題をトラブルシューティングする前に、まず認証認証情報が正しいことを確認してください。

## データベースレプリケーションのラグの原因を調査 {#investigate-causes-of-database-replication-lag}

`sudo gitlab-rake geo:status`の出力に`Database replication lag`が時間の経過とともに大幅に高いままであることが示されている場合、データベースレプリケーションのプライマリノードをチェックして、データベースレプリケーションプロセスのさまざまな部分のラグの状態を判断できます。これらの値は、`write_lag`、`flush_lag`、および`replay_lag`として知られています。詳細については、[PostgreSQLの公式ドキュメント](https://www.postgresql.org/docs/16/monitoring-stats.html#MONITORING-PG-STAT-REPLICATION-VIEW)を参照してください。

関連する出力を提供するには、プライマリGeoノードのデータベースから次のコマンドを実行します:

```shell
gitlab-psql -xc 'SELECT write_lag,flush_lag,replay_lag FROM pg_stat_replication;'

-[ RECORD 1 ]---------------
write_lag  | 00:00:00.072392
flush_lag  | 00:00:00.108168
replay_lag | 00:00:00.108283
```

これらの値の1つ以上が著しく高い場合、問題を示している可能性があり、さらに調査する必要があります。原因を特定するときは、次の点を考慮してください:

- `write_lag`は、WALバイトがプライマリによって送信されてから、セカンダリに受信されたが、まだフラッシュまたは適用されていない時間を示します。
- 高い`write_lag`値は、プライマリおよびセカンダリノード間のネットワーキングパフォーマンスの低下または不十分なネットワーク速度を示している可能性があります。
- 高い`flush_lag`値は、セカンダリノードのストレージデバイスでのパフォーマンスが低下または最適化されていないディスクI/Oを示している可能性があります。
- 高い`replay_lag`値は、PostgreSQLでの長時間実行されているトランザクション、またはCPUなどの必要なリソースの飽和を示している可能性があります。
- `write_lag`と`flush_lag`の間の時間の差は、WALバイトが基盤となるストレージシステムに送信されたが、フラッシュされたことが報告されていないことを示しています。このデータは、永続ストレージに完全には書き込まれていない可能性が高く、揮発性の書き込みキャッシュに保持されている可能性があります。
- `flush_lag`と`replay_lag`の違いは、ストレージに正常に永続化されたWALバイトを示していますが、データベースシステムで再生できませんでした。

## でスタック`Message: pg_basebackup: initiating base backup, waiting for checkpoint to complete` {#stuck-at-message-pg_basebackup-initiating-base-backup-waiting-for-checkpoint-to-complete}

初期レプリケーションが`Message: pg_basebackup: initiating base backup, waiting for checkpoint to complete`でスタックしている場合、これはプライマリGeoサイトがアクティブに使用されていないことを意味します。これは、ほとんどの場合、非本番環境のGitLabサーバーまたは真新しいGitLabインストールで発生します。

回避策は、データベースの書き込みを引き起こすことです。たとえば、プライマリサイトにサインインして、いくつかのイシューとコメントを作成できます。

別の回避策は、プライマリサイトのデータベースでSQLクエリ`CHECKPOINT;`を実行することです:

```shell
sudo gitlab-psql -xc 'CHECKPOINT;
```
