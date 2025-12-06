---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バンドルされたPgBouncerサービスの操作
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

PgBouncerは`gitlab-ee`パッケージにバンドルされていますが、無料で使用できます。サポートを受けるには、[Premiumサブスクリプション](https://about.gitlab.com/pricing/)が必要です。

{{< /alert >}}

[PgBouncer](https://www.pgbouncer.org/)は、フェイルオーバーシナリオでサーバー間のデータベース接続をシームレスに移行するために使用されます。さらに、フォールトトレラントではない設定で使用して、接続をプールし、リソースの使用量を削減しながら応答時間を短縮できます。

GitLab Premiumには、`/etc/gitlab/gitlab.rb`を使用して管理できるバンドル版のPgBouncerが含まれています。

## フォールトトレラントなGitLabインストールの一部としてのPgBouncer {#pgbouncer-as-part-of-a-fault-tolerant-gitlab-installation}

このコンテンツは、[新しい場所](replication_and_failover.md#configure-pgbouncer-nodes)に移植されました。

## フォールトトレラントではないGitLabインストールの一部としてのPgBouncer {#pgbouncer-as-part-of-a-non-fault-tolerant-gitlab-installation}

1. コマンド`gitlab-ctl pg-password-md5 pgbouncer`を使用して`PGBOUNCER_USER_PASSWORD_HASH`を生成します

1. コマンド`gitlab-ctl pg-password-md5 gitlab`を使用して`SQL_USER_PASSWORD_HASH`を生成します。平文のSQL_USER_PASSWORDを後で入力します。

1. データベースノードで、`/etc/gitlab/gitlab.rb`に以下が設定されていることを確認します

   ```ruby
   postgresql['pgbouncer_user_password'] = 'PGBOUNCER_USER_PASSWORD_HASH'
   postgresql['sql_user_password'] = 'SQL_USER_PASSWORD_HASH'
   postgresql['listen_address'] = 'XX.XX.XX.Y' # Where XX.XX.XX.Y is the ip address on the node postgresql should listen on
   postgresql['md5_auth_cidr_addresses'] = %w(AA.AA.AA.B/32) # Where AA.AA.AA.B is the IP address of the pgbouncer node
   ```

1. `gitlab-ctl reconfigure`を実行

   {{< alert type="note" >}}

   データベースがすでに実行されている場合は、`gitlab-ctl restart postgresql`を実行して、再設定後に再起動する必要があります。

   {{< /alert >}}

1. PgBouncerを実行しているノードで、`/etc/gitlab/gitlab.rb`に以下が設定されていることを確認してください

   ```ruby
   pgbouncer['enable'] = true
   pgbouncer['databases'] = {
     gitlabhq_production: {
       host: 'DATABASE_HOST',
       user: 'pgbouncer',
       password: 'PGBOUNCER_USER_PASSWORD_HASH'
     }
   }
   ```

   データベースごとに、追加の設定パラメータを渡すことができます（例:

   ```ruby
   pgbouncer['databases'] = {
     gitlabhq_production: {
        ...
        pool_mode: 'transaction'
     }
   }
   ```

   これらのパラメータは慎重に使用してください。パラメータの完全なリストについては、[PgBouncerのドキュメント](https://www.pgbouncer.org/config.html#section-databases)を参照してください。

1. `gitlab-ctl reconfigure`を実行

1. Pumaを実行しているノードで、`/etc/gitlab/gitlab.rb`に以下が設定されていることを確認してください

   ```ruby
   gitlab_rails['db_host'] = 'PGBOUNCER_HOST'
   gitlab_rails['db_port'] = '6432'
   gitlab_rails['db_password'] = 'SQL_USER_PASSWORD'
   ```

1. `gitlab-ctl reconfigure`を実行

1. この時点で、インスタンスはPgBouncerを介してデータベースに接続する必要があります。問題が発生した場合は、[トラブルシューティング](#troubleshooting)セクションを参照してください

## バックアップ {#backups}

PgBouncer接続を介してGitLabをバックアップまたは復元しないでください。GitLabの停止が発生します。

[これとバックアップを再設定する方法の詳細](../backup_restore/backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer)。

## モニタリングの有効化 {#enable-monitoring}

モニタリングを有効にする場合は、すべてのPgBouncerサーバーで有効にする必要があります。

1. `/etc/gitlab/gitlab.rb`を作成/編集し、次の設定を追加します:

   ```ruby
   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   # Replace placeholders
   # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
   # with the addresses of the Consul server nodes
   consul['configuration'] = {
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   pgbouncer_exporter['listen_address'] = '0.0.0.0:9188'
   ```

1. `sudo gitlab-ctl reconfigure`を実行して設定をコンパイルします。

## 管理コンソール {#administrative-console}

Linuxパッケージインストールでは、PgBouncer管理コンソールに自動的に接続するコマンドが提供されています。コンソールの操作方法の詳細については、[PgBouncerドキュメント](https://www.pgbouncer.org/usage.html#admin-console)を参照してください。

セッションを開始するには、以下を実行し、`pgbouncer`ユーザーのパスワードを入力します:

```shell
sudo gitlab-ctl pgb-console
```

インスタンスに関する基本情報を取得するには:

```shell
pgbouncer=# show databases; show clients; show servers;
        name         |   host    | port |      database       | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections
---------------------+-----------+------+---------------------+------------+-----------+--------------+-----------+-----------------+---------------------
 gitlabhq_production | 127.0.0.1 | 5432 | gitlabhq_production |            |       100 |            5 |           |               0 |                   1
 pgbouncer           |           | 6432 | pgbouncer           | pgbouncer  |         2 |            0 | statement |               0 |                   0
(2 rows)

 type |   user    |      database       | state  |   addr    | port  | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link
| remote_pid | tls
------+-----------+---------------------+--------+-----------+-------+------------+------------+---------------------+---------------------+-----------+------
+------------+-----
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44590 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x12444c0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44592 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x12447c0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44594 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x1244940 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44706 | 127.0.0.1  |       6432 | 2018-04-24 22:14:22 | 2018-04-24 22:16:31 | 0x1244ac0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44708 | 127.0.0.1  |       6432 | 2018-04-24 22:14:22 | 2018-04-24 22:15:15 | 0x1244c40 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44794 | 127.0.0.1  |       6432 | 2018-04-24 22:15:15 | 2018-04-24 22:15:15 | 0x1244dc0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44798 | 127.0.0.1  |       6432 | 2018-04-24 22:15:15 | 2018-04-24 22:16:31 | 0x1244f40 |
|          0 |
 C    | pgbouncer | pgbouncer           | active | 127.0.0.1 | 44660 | 127.0.0.1  |       6432 | 2018-04-24 22:13:51 | 2018-04-24 22:17:12 | 0x1244640 |
|          0 |
(8 rows)

 type |  user  |      database       | state |   addr    | port | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link | rem
ote_pid | tls
------+--------+---------------------+-------+-----------+------+------------+------------+---------------------+---------------------+-----------+------+----
--------+-----
 S    | gitlab | gitlabhq_production | idle  | 127.0.0.1 | 5432 | 127.0.0.1  |      35646 | 2018-04-24 22:15:15 | 2018-04-24 22:17:10 | 0x124dca0 |      |
  19980 |
(1 row)
```

## PgBouncerを回避する手順 {#procedure-for-bypassing-pgbouncer}

### Linuxパッケージインストール {#linux-package-installations}

データベースの変更の中には、PgBouncerを介さずに直接行う必要があるものがあります。

主な影響を受けるタスクは、[データベースの復元](../backup_restore/backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer)と[データベース移行を伴うGitLabのアップグレード](../../update/zero_downtime.md)です。

1. プライマリノードを見つけるには、データベースノードで以下を実行します:

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. タスクを実行しているアプリケーションノードの`/etc/gitlab/gitlab.rb`を編集し、データベースプライマリのホストとポートで`gitlab_rails['db_host']`と`gitlab_rails['db_port']`を更新します。

1. 再設定を実行します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

タスクまたは手順を実行したら、PgBouncerの使用に戻します:

1. `/etc/gitlab/gitlab.rb`をPgBouncerをポートするように変更します。
1. 再設定を実行します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Helmチャートによるインストール {#helm-chart-installations}

高可用性デプロイも、Linuxパッケージベースのものと同じ理由でPgBouncerを回避する必要があります。Helmチャートでインストールした場合:

- データベースのバックアップと復元のタスクは、toolboxコンテナによって実行されます。
- 移行のタスクは、移行コンテナによって実行されます。

これらのタスクを実行してPostgreSQLに直接接続できるように、各サブチャートでPostgreSQLポートをオーバーライドする必要があります:

- [Toolbox](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/toolbox/values.yaml#L40)
- [移行](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/migrations/values.yaml#L46)

## 微調整 {#fine-tuning}

PgBouncerのデフォルトの設定は、ほとんどのインストールに適しています。特定の場合には、パフォーマンス固有およびリソース固有の変数を変更して、可能なスループットを向上させるか、データベースでメモリ枯渇を引き起こす可能性のあるリソース使用量を制限することができます。

パラメータとそれぞれのドキュメントは、[PgBouncerの公式ドキュメント](https://www.pgbouncer.org/config.html)にあります。以下に、最も関連性の高いものと、Linuxパッケージインストールでのデフォルトを示します:

- `pgbouncer['max_client_conn']`（デフォルト: `2048`、サーバーファイルの記述子制限に依存）これはPgBouncerにおける「フロントエンド」プールです: RailsからPgBouncerへの接続を指します。
- `pgbouncer['default_pool_size']`（デフォルト: `100`）これはPgBouncerにおける「バックエンド」プールです: PgBouncerからデータベースへの接続を指します。

`default_pool_size`の理想的な数は、データベースへのアクセスを必要とする、プロビジョニングされたすべてのサービスを処理するのに十分な数である必要があります。必要なプールサイズを計算するための詳細なガイダンスについては、[PostgreSQLの調整](tune.md)を参照してください。

内部ロードバランサーで複数のPgBouncerを使用している場合は、`default_pool_size`をインスタンス数で割って、それらの間で均等に分散された負荷を保証できる場合があります。

`pgbouncer['max_client_conn']`は、PgBouncerが受け入れることができる接続のハード制限です。これを変更する必要はおそらくありません。そのハード制限に達している場合は、内部ロードバランサーで追加のPgBouncerを追加することを検討してください。

GeoトラッキングデータベースをポートするPgBouncerの制限を設定する場合、`puma`はおそらく考慮しなくてもかまいません。これは、そのデータベースに散発的にしかアクセスしないためです。

## トラブルシューティング {#troubleshooting}

PgBouncerを介した接続で問題が発生している場合は、最初にログを確認してください:

```shell
sudo gitlab-ctl tail pgbouncer
```

さらに、[管理コンソール](#administrative-console)で`show databases`からの出力を確認できます。出力では、`gitlabhq_production`データベースの`host`フィールドに値が表示されることが予想されます。さらに、`current_connections`は1より大きくなければなりません。

### メッセージ: `LOG:  invalid CIDR mask in address` {#message-log--invalid-cidr-mask-in-address}

[Geoドキュメント](../geo/replication/troubleshooting/postgresql_replication.md#message-log--invalid-cidr-mask-in-address)で提案された修正を参照してください。

### メッセージ: `LOG:  invalid IP mask "md5": Name or service not known` {#message-log--invalid-ip-mask-md5-name-or-service-not-known}

[Geoドキュメント](../geo/replication/troubleshooting/postgresql_replication.md#message-log--invalid-ip-mask-md5-name-or-service-not-known)で提案された修正を参照してください。
