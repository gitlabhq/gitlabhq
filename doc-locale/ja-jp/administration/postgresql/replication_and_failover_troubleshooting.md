---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linuxパッケージインストールに関するPostgreSQLのレプリケーションとフェイルオーバーのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

PostgreSQLのレプリケーションとフェイルオーバーを使用する際、以下の問題が発生する可能性があります。

## ConsulとPostgreSQLの変更が有効にならない {#consul-and-postgresql-changes-not-taking-effect}

潜在的な影響があるため、`gitlab-ctl reconfigure`はConsulとPostgreSQLをリロードするだけで、サービスは再起動しません。ただし、すべての変更がリロードによって有効になるわけではありません。

いずれかのサービスを再起動するには、`gitlab-ctl restart SERVICE`を実行します

PostgreSQLの場合、通常はデフォルトでリーダーノードを再起動しても安全です。自動フェイルオーバーのタイムアウトは、デフォルトで1分に設定されています。データベースがそれまでに戻れば、他に行う必要はありません。

Consulサーバーノードでは、制御された方法で[Consulサービスを再起動](../consul.md#restart-consul)することが重要です。

## PgBouncerエラー`ERROR: pgbouncer cannot connect to server` {#pgbouncer-error-error-pgbouncer-cannot-connect-to-server}

`gitlab-rake gitlab:db:configure`の実行時、またはPgBouncerログファイルで、このエラーが発生する可能性があります。

```plaintext
PG::ConnectionBad: ERROR:  pgbouncer cannot connect to server
```

問題は、PgBouncerノードのIPアドレスが、データベースノードの`/etc/gitlab/gitlab.rb`の`trust_auth_cidr_addresses`設定に含まれていないことが原因である可能性があります。

リーダーデータベースノードのPostgreSQLログファイルを確認することで、この問題を確認できます。次のエラーが表示される場合、`trust_auth_cidr_addresses`が問題です。

```plaintext
2018-03-29_13:59:12.11776 FATAL:  no pg_hba.conf entry for host "123.123.123.123", user "pgbouncer", database "gitlabhq_production", SSL off
```

問題を修正するには、IPアドレスを`/etc/gitlab/gitlab.rb`に追加します。

```ruby
postgresql['trust_auth_cidr_addresses'] = %w(123.123.123.123/32 <other_cidrs>)
```

変更を有効にするには、[GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

## Patroniスイッチオーバー後にPgBouncerノードがフェイルオーバーしない {#pgbouncer-nodes-dont-fail-over-after-patroni-switchover}

GitLabのバージョン16.5.0より前のバージョンに影響を与える[既知の問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8166)が原因で、[Patroniスイッチオーバー](replication_and_failover.md#manual-failover-procedure-for-patroni)後にPgBouncerノードの自動フェイルオーバーは発生しません。この例では、GitLabは一時停止されたデータベースの検出に失敗し、一時停止されていないデータベースの`RESUME`を試みました:

```plaintext
INFO -- : Running: gitlab-ctl pgb-notify --pg-database gitlabhq_production --newhost database7.example.com --user pgbouncer --hostuser gitlab-consul
ERROR -- : STDERR: Error running command: GitlabCtl::Errors::ExecutionError
ERROR -- : STDERR: ERROR: ERROR:  database gitlabhq_production is not paused
```

[Patroniスイッチオーバー](replication_and_failover.md#manual-failover-procedure-for-patroni)を成功させるには、次のコマンドを使用して、すべてのPgBouncerノードでPgBouncerサービスを手動で再起動する必要があります:

```shell
gitlab-ctl restart pgbouncer
```

## レプリカの再初期化 {#reinitialize-a-replica}

レプリカが起動またはクラスターに再参加できない場合、またはラグが遅れて追いつけない場合は、レプリカを再初期化する必要があるかもしれません:

1. どのサーバーを再初期化する必要があるかを確認するには、[レプリケーションステータスを確認します](replication_and_failover.md#check-replication-status)。例: 

   ```plaintext
   + Cluster: postgresql-ha (6970678148837286213) ------+---------+--------------+----+-----------+
   | Member                              | Host         | Role    | State        | TL | Lag in MB |
   +-------------------------------------+--------------+---------+--------------+----+-----------+
   | gitlab-database-1.example.com       | 172.18.0.111 | Replica | running      | 55 |         0 |
   | gitlab-database-2.example.com       | 172.18.0.112 | Replica | start failed |    |   unknown |
   | gitlab-database-3.example.com       | 172.18.0.113 | Leader  | running      | 55 |           |
   +-------------------------------------+--------------+---------+--------------+----+-----------+
   ```

1. 破損したサーバーにサインインし、データベースとレプリケーションを再初期化します。Patroniは、そのサーバーでPostgreSQLをシャットダウンし、データディレクトリを削除して、最初から再初期化します:

   ```shell
   sudo gitlab-ctl patroni reinitialize-replica --member gitlab-database-2.example.com
   ```

   これは任意のPatroniノードで実行できますが、`sudo gitlab-ctl patroni reinitialize-replica`（`--member`なし）は実行されているサーバーを再起動することに注意してください。意図しないデータ損失のリスクを軽減するために、破損したサーバーでローカルに実行する必要があります。
1. ログを追跡します:

   ```shell
   sudo gitlab-ctl tail patroni
   ```

## ConsulでのPatroni状態のリセット {#reset-the-patroni-state-in-consul}

{{< alert type="warning" >}}

ConsulでPatroni状態をリセットすることは、潜在的に破壊的なプロセスです。最初に正常なデータベースバックアップがあることを確認してください。

{{< /alert >}}

最後の手段として、ConsulでPatroni状態を完全にリセットできます。

これは、Patroniクラスターが不明または異常な状態にあり、ノードが起動できない場合に必要になることがあります:

```plaintext
+ Cluster: postgresql-ha (6970678148837286213) ------+---------+---------+----+-----------+
| Member                              | Host         | Role    | State   | TL | Lag in MB |
+-------------------------------------+--------------+---------+---------+----+-----------+
| gitlab-database-1.example.com       | 172.18.0.111 | Replica | stopped |    |   unknown |
| gitlab-database-2.example.com       | 172.18.0.112 | Replica | stopped |    |   unknown |
| gitlab-database-3.example.com       | 172.18.0.113 | Replica | stopped |    |   unknown |
+-------------------------------------+--------------+---------+---------+----+-----------+
```

ConsulでPatroni状態を削除する前に、Patroniノードで[`gitlab-ctl`エラーの解決](#errors-running-gitlab-ctl)を試してください。

このプロセスにより、最初のPatroniノードが起動すると、再初期化されたPatroniクラスターが選挙されます。

ConsulでPatroni状態をリセットするには:

1. リーダーだったPatroniノード、またはアプリケーションが現在のリーダーであると考えているノードをメモします（現在の状態が複数またはゼロを示す場合）:
   - 現在のリーダーのホスト名が含まれている`/var/opt/gitlab/consul/databases.ini`のPgBouncerノードを確認します。
   - すべてのデータベースノードで、`/var/log/gitlab/patroni/current`（または、以前にローテーションされ圧縮されたログ`/var/log/gitlab/patroni/@40000*`）のPatroniログを確認して、クラスターによってリーダーとして最も最近に識別されたサーバーを確認します:

     ```plaintext
     INFO: no action. I am a secondary (database1.local) and following a leader (database2.local)
     ```

1. すべてのノードでPatroniを停止します:

   ```shell
   sudo gitlab-ctl stop patroni
   ```

1. Consulで状態をリセットします:

   ```shell
   /opt/gitlab/embedded/bin/consul kv delete -recurse /service/postgresql-ha/
   ```

1. 1つのPatroniノードを起動します。これにより、リーダーとして選挙されるPatroniクラスターが初期化されます。（最初の手順で説明した）以前のリーダーを起動することを強くお勧めします。これにより、破損したクラスター状態のためにレプリケートされなかった可能性のある既存の書き込みが失われないようにします:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. レプリカとしてPatroniクラスターに参加する他のすべてのPatroniノードを起動します:

   ```shell
   sudo gitlab-ctl start patroni
   ```

それでも問題が発生する場合は、次の手順として、最後に正常なバックアップを復元するます。

## `127.0.0.1`の`pg_hba.conf`エントリに関するPatroniログのエラー {#errors-in-the-patroni-log-about-a-pg_hbaconf-entry-for-127001}

Patroniログ内の次のログエントリは、レプリケーションが機能しておらず、設定の変更が必要であることを示しています:

```plaintext
FATAL:  no pg_hba.conf entry for replication connection from host "127.0.0.1", user "gitlab_replicator"
```

問題を修正するには、CIDRアドレスリストにループバックインターフェースが含まれていることを確認します:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   postgresql['trust_auth_cidr_addresses'] = %w(<other_cidrs> 127.0.0.1/32)
   ```

1. 変更を有効にするには、[GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。
1. [すべてのレプリカが同期されている](replication_and_failover.md#check-replication-status)ことを確認します

## エラー: リクエストされた開始ポイントがWAL（Write Ahead Log）フラッシュ位置よりも前にある {#error-requested-start-point-is-ahead-of-the-write-ahead-log-wal-flush-position}

Patroniログのこのエラーは、データベースがレプリケートされていないことを示しています:

```plaintext
FATAL:  could not receive data from WAL stream:
ERROR:  requested starting point 0/5000000 is ahead of the WAL flush position of this server 0/4000388
```

このエラー例は、最初に誤って設定され、レプリケートされなかったレプリカからのものです。

[レプリカを再初期化することによって](#reinitialize-a-replica)、修正します。

## Patroniが`MemoryError`で起動に失敗しました {#patroni-fails-to-start-with-memoryerror}

Patroniは起動に失敗し、エラーとスタックトレースをログに記録する場合があります:

```plaintext
MemoryError
Traceback (most recent call last):
  File "/opt/gitlab/embedded/bin/patroni", line 8, in <module>
    sys.exit(main())
[..]
  File "/opt/gitlab/embedded/lib/python3.7/ctypes/__init__.py", line 273, in _reset_cache
    CFUNCTYPE(c_int)(lambda: None)
```

スタックトレースが`CFUNCTYPE(c_int)(lambda: None)`で終わる場合、Linuxサーバーがセキュリティのために強化されている場合、このコードは`MemoryError`をトリガーします。

このコードにより、Pythonは一時的な実行可能ファイルを書き込みますが、これを行うファイルシステムが見つからない場合。たとえば、`/tmp`ファイルシステムで`noexec`が設定されている場合、`MemoryError`で失敗します（[問題の詳細](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6184)をお読みください）。

## `gitlab-ctl`の実行エラー {#errors-running-gitlab-ctl}

Patroniノードは、`gitlab-ctl`コマンドが失敗し、`gitlab-ctl reconfigure`がノードを修正できない状態になることがあります。

これがPostgreSQLのバージョンアップグレードと一致する場合は、[別の手順に従ってください](#postgresql-major-version-upgrade-fails-on-a-patroni-replica)

一般的な症状の1つは、データベースサーバーが起動に失敗した場合、`gitlab-ctl`がインストールに必要な情報を判別できないことです:

```plaintext
Malformed configuration JSON file found at /opt/gitlab/embedded/nodes/<HOSTNAME>.json.
This usually happens when your last run of `gitlab-ctl reconfigure` didn't complete successfully.
```

```plaintext
Error while reinitializing replica on the current node: Attributes not found in
/opt/gitlab/embedded/nodes/<HOSTNAME>.json, has reconfigure been run yet?
```

同様に、ノードファイル（`/opt/gitlab/embedded/nodes/<HOSTNAME>.json`）には多くの情報が含まれている必要がありますが、次のようにのみ作成される可能性があります:

```json
{
  "name": "<HOSTNAME>"
}
```

この問題を修正するための次のプロセスには、このレプリカの再初期化が含まれます。このノードのPostgreSQLの現在の状態は破棄されます:

1. Patroniサービスと（存在する場合は）PostgreSQLサービスをシャットダウンします:

   ```shell
   sudo gitlab-ctl status
   sudo gitlab-ctl stop patroni
   sudo gitlab-ctl stop postgresql
   ```

1. 状態がPostgreSQLの起動を妨げる場合に備えて、`/var/opt/gitlab/postgresql/data`を削除します:

   ```shell
   cd /var/opt/gitlab/postgresql
   sudo rm -rf data
   ```

   {{< alert type="warning" >}}

   データ損失を避けるために、この手順には注意してください。この手順は、`data/`の名前を変更することでも実現できます。レプリカが修正されたら、プライマリデータベースの新しいコピーに十分な空きディスクがあることを確認し、余分なディレクトリを削除してください。

   {{< /alert >}}

1. PostgreSQLが実行されていない場合、ノードファイルが正常に作成されるようになりました:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Patroniを起動します:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. ログを追跡し、クラスターの状態を確認します:

   ```shell
   sudo gitlab-ctl tail patroni
   sudo gitlab-ctl patroni members
   ```

1. `reconfigure`を再度実行します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `gitlab-ctl patroni members`でこれが必要であることが示されている場合は、レプリカを再初期化します:

   ```shell
   sudo gitlab-ctl patroni reinitialize-replica
   ```

この手順が機能せず、クラスターがリーダーを選挙できない場合は、[別の修正があります](#reset-the-patroni-state-in-consul)。これは最後の手段としてのみ使用してください。

## PatroniレプリカでPostgreSQLのメジャーバージョンアップグレードが失敗する {#postgresql-major-version-upgrade-fails-on-a-patroni-replica}

Patroniレプリカは、`gitlab-ctl pg-upgrade`中にループに陥る可能性があり、アップグレードは失敗します。

症状の例を次に示します:

1. `postgresql`サービスが定義されています。これは通常、Patroniノードには存在しないはずです。これは、`gitlab-ctl pg-upgrade`が新しい空のデータベースを作成するために追加するためです:

   ```plaintext
   run: patroni: (pid 1972) 1919s; run: log: (pid 1971) 1919s
   down: postgresql: 1s, normally up, want up; run: log: (pid 1973) 1919s
   ```

1. Patroniがレプリカを再初期化する際に`/var/opt/gitlab/postgresql/data`を削除するため、PostgreSQLは`PANIC`ログエントリを`/var/log/gitlab/postgresql/current`に生成します:

   ```plaintext
   DETAIL:  Could not open file "pg_xact/0000": No such file or directory.
   WARNING:  terminating connection because of crash of another server process
   LOG:  all server processes terminated; reinitializing
   PANIC:  could not open file "global/pg_control": No such file or directory
   ```

1. `/var/log/gitlab/patroni/current`で、Patroniは次の内容をログに記録します。ローカルPostgreSQLバージョンがクラスターリーダーと異なっています:

   ```plaintext
   INFO: trying to bootstrap from leader 'HOSTNAME'
   pg_basebackup: incompatible server version 12.6
   pg_basebackup: removing data directory "/var/opt/gitlab/postgresql/data"
   ERROR: Error when fetching backup: pg_basebackup exited with code=1
   ```

この回避策は、Patroniクラスターが次の状態にある場合に適用されます:

- [リーダーが新しいメジャーバージョンに正常にアップグレードされました](replication_and_failover.md#upgrading-postgresql-major-version-in-a-patroni-cluster)。
- レプリカでPostgreSQLをアップグレードする手順が失敗しています。

この回避策は、ノードを新しいPostgreSQLバージョンを使用するように設定し、リーダーがアップグレードされたときに作成された新しいクラスターでレプリカとして再初期化することにより、PatroniレプリカでのPostgreSQLアップグレードを完了します:

1. すべてのノードでクラスターの状態を確認して、リーダーがどれで、レプリカがどのような状態にあるかを確認します。

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. レプリカ: PostgreSQLのどのバージョンがアクティブかを確認します:

   ```shell
   sudo ls -al /opt/gitlab/embedded/bin | grep postgres
   ```

1. レプリカ: ノードファイルが正しく、`gitlab-ctl`が実行できることを確認します。[`gitlab-ctl`の実行エラー](#errors-running-gitlab-ctl)の問題もレプリカにある場合は、これを解決します:

   ```shell
   sudo gitlab-ctl stop patroni
   sudo gitlab-ctl reconfigure
   ```

1. レプリカ: PostgreSQLバイナリを必要なバージョンに再リンクして、`incompatible server version`エラーを修正します:

   1. `/etc/gitlab/gitlab.rb`を編集して、必要なバージョンを指定します:

      ```ruby
      postgresql['version'] = 13
      ```

   1. GitLabを再設定します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. バイナリが再リンクされていることを確認します。PostgreSQL用に配布されるバイナリはメジャーリリースによって異なり、通常、少数の誤ったシンボリックリンクがあります:

      ```shell
      sudo ls -al /opt/gitlab/embedded/bin | grep postgres
      ```

1. レプリカ: 指定されたバージョンに対して、PostgreSQLが完全に再初期化されていることを確認します:

   ```shell
   cd /var/opt/gitlab/postgresql
   sudo rm -rf data
   sudo gitlab-ctl reconfigure
   ```

1. レプリカ: オプションで、2つの追加のターミナルセッションでデータベースを追跡します:

   - `pg_basebackup`の実行時にディスク使用量が増加します。次の方法でレプリカの初期化の進行状況を追跡します:

     ```shell
     cd /var/opt/gitlab/postgresql
     watch du -sh data
     ```

   - ログでプロセスを追跡します:

     ```shell
     sudo gitlab-ctl tail patroni
     ```

1. レプリカ: Patroniを起動して、レプリカを再初期化します:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. レプリカ: 完了したら、`/etc/gitlab/gitlab.rb`からハードコードされたバージョンを削除します:

   1. `/etc/gitlab/gitlab.rb`を編集し、`postgresql['version']`を削除します。
   1. GitLabを再設定します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. 正しいバイナリがリンクされていることを確認します:

      ```shell
      sudo ls -al /opt/gitlab/embedded/bin | grep postgres
      ```

1. すべてのノードでクラスターの状態を確認します:

   ```shell
   sudo gitlab-ctl patroni members
   ```

必要に応じて、他のレプリカでこの手順を繰り返します。

## PostgreSQLレプリカが作成中にループに陥っている {#postgresql-replicas-stuck-in-loop-while-being-created}

PostgreSQLレプリカが移行するように見えても、ループで再起動する場合は、レプリカとプライマリサーバーの`/opt/gitlab-data/postgresql/`フォルダーの権限を確認してください。

また、ログに次のエラーメッセージが表示されることがあります: `could not get COPY data stream: ERROR: could not open file "<file>" Permission denied`。

## 他のコンポーネントの問題 {#issues-with-other-components}

ここに概説されていないコンポーネントで問題が発生した場合は、特定のドキュメントページのトラブルシューティングセクションを必ず確認してください:

- [Consul](../consul.md#troubleshooting-consul)
- [PostgreSQL](https://docs.gitlab.com/omnibus/settings/database.html#troubleshooting)
