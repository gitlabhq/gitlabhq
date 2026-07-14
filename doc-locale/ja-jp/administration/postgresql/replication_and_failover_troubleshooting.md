---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: LinuxパッケージインストールのPostgreSQLレプリケーションとフェイルオーバーのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

PostgreSQLのレプリケーションおよびフェイルオーバーを使用する際に、以下の問題が発生する可能性があります。

## ConsulとPostgreSQLの変更が適用されない {#consul-and-postgresql-changes-not-taking-effect}

潜在的な影響を考慮して、`gitlab-ctl reconfigure`はConsulとPostgreSQLをリロードするだけで、サービスを再起動しません。しかし、すべての変更がリロードによって有効になるわけではありません。

いずれかのサービスを再起動するには、`gitlab-ctl restart SERVICE`を実行してください。

PostgreSQLの場合、デフォルトではリーダーノードの再起動は通常安全です。自動フェイルオーバーは、タイムアウトが1分にデフォルト設定されています。データベースがそれまでに復旧すれば、他に何もする必要はありません。

Consulサーバーノードでは、制御された方法で[Consulサービスを再起動](../consul.md#restart-consul)することが重要です。

## PgBouncerエラー`ERROR: pgbouncer cannot connect to server` {#pgbouncer-error-error-pgbouncer-cannot-connect-to-server}

`gitlab-rake gitlab:db:configure`の実行中にこのエラーが発生するか、PgBouncerのログファイルにエラーが表示される場合があります。

```plaintext
PG::ConnectionBad: ERROR:  pgbouncer cannot connect to server
```

問題は、データベースノード上の`/etc/gitlab/gitlab.rb`の`trust_auth_cidr_addresses`設定に、PgBouncerノードのIPアドレスが含まれていないことかもしれません。

リーダーデータベースノード上のPostgreSQLログを確認することで、これが問題であることを確認できます。以下のエラーが表示された場合、`trust_auth_cidr_addresses`が問題です。

```plaintext
2018-03-29_13:59:12.11776 FATAL:  no pg_hba.conf entry for host "123.123.123.123", user "pgbouncer", database "gitlabhq_production", SSL off
```

問題を修正するには、`/etc/gitlab/gitlab.rb`にIPアドレスを追加します。

```ruby
postgresql['trust_auth_cidr_addresses'] = %w(123.123.123.123/32 <other_cidrs>)
```

変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## Patroniスイッチオーバー後にPgBouncerノードがフェイルオーバーしない {#pgbouncer-nodes-dont-fail-over-after-patroni-switchover}

GitLabバージョン16.5.0より前のバージョンに影響する[既知のイシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8166)により、[Patroniスイッチオーバー](replication_and_failover.md#manual-failover-procedure-for-patroni)後にPgBouncerノードの自動フェイルオーバーは発生しません。この例では、GitLabは一時停止されたデータベースを検出するのに失敗し、一時停止されていないデータベースを`RESUME`しようとしました:

```plaintext
INFO -- : Running: gitlab-ctl pgb-notify --pg-database gitlabhq_production --newhost database7.example.com --user pgbouncer --hostuser gitlab-consul
ERROR -- : STDERR: Error running command: GitlabCtl::Errors::ExecutionError
ERROR -- : STDERR: ERROR: ERROR:  database gitlabhq_production is not paused
```

[Patroniスイッチオーバー](replication_and_failover.md#manual-failover-procedure-for-patroni)を成功させるには、すべてのPgBouncerノードでPgBouncerサービスをこのコマンドで手動で再起動する必要があります:

```shell
gitlab-ctl restart pgbouncer
```

## レプリカを再初期化する {#reinitialize-a-replica}

レプリカが起動できない、またはクラスターに再結合できない場合、あるいはラグが大きく追いつけない場合、レプリカを再初期化する必要があるかもしれません:

1. どのサーバーを再初期化する必要があるかを確認するために、[レプリケーションステータス](replication_and_failover.md#check-replication-status)を確認します。例: 

   ```plaintext
   + Cluster: postgresql-ha (6970678148837286213) ------+---------+--------------+----+-----------+
   | Member                              | Host         | Role    | State        | TL | Lag in MB |
   +-------------------------------------+--------------+---------+--------------+----+-----------+
   | gitlab-database-1.example.com       | 172.18.0.111 | Replica | running      | 55 |         0 |
   | gitlab-database-2.example.com       | 172.18.0.112 | Replica | start failed |    |   unknown |
   | gitlab-database-3.example.com       | 172.18.0.113 | Leader  | running      | 55 |           |
   +-------------------------------------+--------------+---------+--------------+----+-----------+
   ```

1. 障害が発生したサーバーにサインインし、データベースとレプリケーションを再初期化します。Patroniはそのサーバー上のPostgreSQLをシャットダウンし、データディレクトリを削除し、ゼロから再初期化します:

   ```shell
   sudo gitlab-ctl patroni reinitialize-replica --member gitlab-database-2.example.com
   ```

   これは任意のPatroniノードで実行できますが、`--member`なしの`sudo gitlab-ctl patroni reinitialize-replica`は、実行されているサーバーを再起動することに注意してください。意図しないデータ損失のリスクを減らすために、障害が発生したサーバーでローカルに実行してください。
1. ログを監視します:

   ```shell
   sudo gitlab-ctl tail patroni
   ```

## Consul内のPatroniステートをリセットする {#reset-the-patroni-state-in-consul}

> [!warning]
> Consul内のPatroniステートをリセットすることは、潜在的に破壊的なプロセスです。まず、健全なデータベースバックアップがあることを確認してください。

最終手段として、Consul内のPatroniステートを完全にリセットできます。

これは、Patroniクラスターが不明な状態または不良な状態であり、どのノードも起動できない場合に必要となる場合があります:

```plaintext
+ Cluster: postgresql-ha (6970678148837286213) ------+---------+---------+----+-----------+
| Member                              | Host         | Role    | State   | TL | Lag in MB |
+-------------------------------------+--------------+---------+---------+----+-----------+
| gitlab-database-1.example.com       | 172.18.0.111 | Replica | stopped |    |   unknown |
| gitlab-database-2.example.com       | 172.18.0.112 | Replica | stopped |    |   unknown |
| gitlab-database-3.example.com       | 172.18.0.113 | Replica | stopped |    |   unknown |
+-------------------------------------+--------------+---------+---------+----+-----------+
```

Consul内のPatroniステートを削除する前に、Patroniノードで[`gitlab-ctl`エラーを解決することを試して](#errors-running-gitlab-ctl)ください。

このプロセスは、最初のPatroniノードが起動すると、再初期化されたPatroniクラスターになります。

Consul内のPatroniステートをリセットするには:

1. 現在の状態が複数のリーダーまたはリーダーがないことを示している場合は、リーダーであったPatroniノード、またはアプリケーションが現在のリーダーと考えているPatroniノードを記録しておきます:
   - 現在のリーダーのホスト名を含む`/var/opt/gitlab/consul/databases.ini`にあるPgBouncerノードを確認します。
   - すべてのデータベースノードのPatroniログ`/var/log/gitlab/patroni/current` (または古いローテーションおよび圧縮されたログ`/var/log/gitlab/patroni/@40000*`) を確認して、クラスターによって最後にリーダーとして識別されたサーバーを確認します:

     ```plaintext
     INFO: no action. I am a secondary (database1.local) and following a leader (database2.local)
     ```

1. すべてのノードでPatroniを停止します:

   ```shell
   sudo gitlab-ctl stop patroni
   ```

1. Consul内のステートをリセットします:

   ```shell
   /opt/gitlab/embedded/bin/consul kv delete -recurse /service/postgresql-ha/
   ```

1. 1つのPatroniノードを起動します。これにより、リーダーとして選出されるPatroniクラスターが初期化されます。最初のステップで記録した以前のリーダーを起動することを強くお勧めします。これは、破損したクラスターの状態のためにレプリケートされていない可能性のある既存の書き込みを失わないためです:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. Patroniクラスターにレプリカとして参加する他のすべてのPatroniノードを起動します:

   ```shell
   sudo gitlab-ctl start patroni
   ```

引き続き問題が発生する場合は、次のステップは最後の健全なバックアップをリストアすることです。

## Patroniログにおける`127.0.0.1`の`pg_hba.conf`エントリに関するエラー {#errors-in-the-patroni-log-about-a-pg_hbaconf-entry-for-127001}

Patroniログ内の以下のログエントリは、レプリケーションが機能しておらず、設定変更が必要であることを示しています:

```plaintext
FATAL:  no pg_hba.conf entry for replication connection from host "127.0.0.1", user "gitlab_replicator"
```

問題を修正するには、ループバックインターフェースがCIDRアドレスリストに含まれていることを確認してください:

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   postgresql['trust_auth_cidr_addresses'] = %w(<other_cidrs> 127.0.0.1/32)
   ```

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. [すべてのレプリカが同期されている](replication_and_failover.md#check-replication-status)ことを確認します。

## Patroniメンバーが再起動保留中として表示される {#patroni-members-showing-as-pending-restart}

`gitlab-ctl patroni members`の出力には、セカンダリサイトのPatroniメンバーが再起動保留中のステータスで表示される場合があります:

```shell
secondary-site:postgresql-1> gitlab-ctl patroni members
+ Cluster: postgresql-ha ------------------------------------------------------------------+
| Member         | Host      | Role           | State   | TL | Lag in MB | Pending restart |
+----------------+-----------+----------------+---------+----+-----------+-----------------+
| patroni-1 | 10.20.0.1 | Replica        | running | 27 |         0 | *               |
| patroni-2 | 10.20.0.2 | Replica        | running | 27 |         5 | *               |
| patroni-3 | 10.20.0.3 | Standby Leader | running | 27 |           | *               |
+----------------+-----------+----------------+---------+----+-----------+----------
```

再起動保留中のステータスは、これらのノードが一部の設定変更を適用するために再起動を待っていることを意味します。

これらの再起動保留中の設定が何かを知るには、確認する必要があるインスタンスで以下を実行します:

```shell
sudo gitlab-psql -c "select name, setting,  short_desc, sourcefile, sourceline  from pg_settings where pending_restart"
```

保留中の設定変更を適用するには、影響を受けるノードを再起動します:

1. レプリカノードの場合は、`sudo gitlab-ctl restart patroni`を実行します。
1. リーダーノードの場合は、まずフェイルオーバーの実行を検討するか、ダウンタイムを避けるために`sudo gitlab-ctl reload patroni`を実行します。

## エラー: 要求された開始ポイントが先行書き込みログ (WAL) フラッシュ位置より前にある {#error-requested-start-point-is-ahead-of-the-write-ahead-log-wal-flush-position}

Patroniログのこのエラーは、データベースがレプリケートされていないことを示しています:

```plaintext
FATAL:  could not receive data from WAL stream:
ERROR:  requested starting point 0/5000000 is ahead of the WAL flush position of this server 0/4000388
```

この例のエラーは、最初に誤って設定され、一度もレプリケートされなかったレプリカからのものです。

[レプリカを再初期化して](#reinitialize-a-replica)、修正します。

## Patroniが`MemoryError`で起動に失敗する {#patroni-fails-to-start-with-memoryerror}

Patroniが起動に失敗し、エラーとスタックトレースがログに記録されることがあります:

```plaintext
MemoryError
Traceback (most recent call last):
  File "/opt/gitlab/embedded/bin/patroni", line 8, in <module>
    sys.exit(main())
[..]
  File "/opt/gitlab/embedded/lib/python3.7/ctypes/__init__.py", line 273, in _reset_cache
    CFUNCTYPE(c_int)(lambda: None)
```

スタックトレースが`CFUNCTYPE(c_int)(lambda: None)`で終わる場合、Linuxサーバーがセキュリティのために強化されていると、このコードは`MemoryError`をトリガーします。

このコードはPythonに一時的な実行可能ファイルを書き込ませるものであり、これが実行できるファイルシステムが見つからない場合。例えば、`/tmp`ファイルシステムで`noexec`が設定されている場合、`MemoryError`で失敗します（[イシューで詳細を読む](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6184)）。

## `gitlab-ctl`の実行エラー {#errors-running-gitlab-ctl}

Patroniノードは、`gitlab-ctl`コマンドが失敗し、`gitlab-ctl reconfigure`がノードを修正できない状態になることがあります。

これがPostgreSQLのバージョンアップグレードと重なる場合は、[異なる手順](#postgresql-major-version-upgrade-fails-on-a-patroni-replica)に従ってください。

一般的な症状の1つは、データベースサーバーが起動に失敗している場合、`gitlab-ctl`がインストールに必要な情報を判断できないことです:

```plaintext
Malformed configuration JSON file found at /opt/gitlab/embedded/nodes/<HOSTNAME>.json.
This usually happens when your last run of `gitlab-ctl reconfigure` didn't complete successfully.
```

```plaintext
Error while reinitializing replica on the current node: Attributes not found in
/opt/gitlab/embedded/nodes/<HOSTNAME>.json, has reconfigure been run yet?
```

同様に、ノードファイル (`/opt/gitlab/embedded/nodes/<HOSTNAME>.json`) には多くの情報が含まれているはずですが、以下のみで作成される場合があります:

```json
{
  "name": "<HOSTNAME>"
}
```

これを修正するための以下のプロセスには、このレプリカの再初期化が含まれます: このノード上のPostgreSQLの現在の状態は破棄されます:

1. Patroniおよび(存在する場合は)PostgreSQLサービスをシャットダウンします:

   ```shell
   sudo gitlab-ctl status
   sudo gitlab-ctl stop patroni
   sudo gitlab-ctl stop postgresql
   ```

1. PostgreSQLの起動を妨げる状態である場合に備えて、`/var/opt/gitlab/postgresql/data`を削除します:

   ```shell
   cd /var/opt/gitlab/postgresql
   sudo rm -rf data
   ```

   > [!warning]
   > データ損失を避けるため、このステップには注意してください。このステップは、`data/`の名前を変更することでも実現できます: プライマリデータベースの新しいコピーに十分な空きディスクがあることを確認し、レプリカが修正されたら余分なディレクトリを削除します。

1. PostgreSQLが実行されていない状態で、ノードファイルが正常に作成されるようになりました:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Patroniを起動します:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. ログを監視し、クラスターの状態を確認します:

   ```shell
   sudo gitlab-ctl tail patroni
   sudo gitlab-ctl patroni members
   ```

1. `reconfigure`を再度実行します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `gitlab-ctl patroni members`が必要であると示している場合は、レプリカを再初期化します:

   ```shell
   sudo gitlab-ctl patroni reinitialize-replica
   ```

この手順が機能せず、クラスターがリーダーを選出できない場合は、最終手段としてのみ使用すべき[別の修正方法](#reset-the-patroni-state-in-consul)があります。

## PatroniレプリカでのPostgreSQLメジャーバージョンアップグレードが失敗する {#postgresql-major-version-upgrade-fails-on-a-patroni-replica}

Patroniレプリカが`gitlab-ctl pg-upgrade`の実行中にループにはまり、アップグレードが失敗することがあります。

症状の例は次のとおりです:

1. 通常Patroniノードに存在しないはずの`postgresql`サービスが定義されています。これは、`gitlab-ctl pg-upgrade`が新しい空のデータベースを作成するために追加するためです:

   ```plaintext
   run: patroni: (pid 1972) 1919s; run: log: (pid 1971) 1919s
   down: postgresql: 1s, normally up, want up; run: log: (pid 1973) 1919s
   ```

1. Patroniがレプリカの再初期化の一部として`/var/opt/gitlab/postgresql/data`を削除する際に、PostgreSQLは`/var/log/gitlab/postgresql/current`に`PANIC`ログエントリを生成します:

   ```plaintext
   DETAIL:  Could not open file "pg_xact/0000": No such file or directory.
   WARNING:  terminating connection because of crash of another server process
   LOG:  all server processes terminated; reinitializing
   PANIC:  could not open file "global/pg_control": No such file or directory
   ```

1. `/var/log/gitlab/patroni/current`で、Patroniは以下をログに記録します。ローカルのPostgreSQLバージョンは、クラスターリーダーとは異なります:

   ```plaintext
   INFO: trying to bootstrap from leader 'HOSTNAME'
   pg_basebackup: incompatible server version 12.6
   pg_basebackup: removing data directory "/var/opt/gitlab/postgresql/data"
   ERROR: Error when fetching backup: pg_basebackup exited with code=1
   ```

この回避策は、Patroniクラスターが以下の状態にある場合に適用されます:

- [リーダーは新しいメジャーバージョンに正常にアップグレードされました](replication_and_failover.md#upgrading-postgresql-major-version-in-a-patroni-cluster)。
- レプリカ上のPostgreSQLをアップグレードするステップが失敗しています。

この回避策は、ノードを新しいPostgreSQLバージョンを使用するように設定し、リーダーがアップグレードされたときに作成された新しいクラスターでレプリカとして再初期化することにより、Patroniレプリカ上のPostgreSQLアップグレードを完了します:

1. すべてのノードでクラスターステータスを確認し、どれがリーダーで、レプリカがどの状態にあるかを確認します。

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. レプリカ: どのPostgreSQLバージョンがアクティブかを確認します:

   ```shell
   sudo ls -al /opt/gitlab/embedded/bin | grep postgres
   ```

1. レプリカ: ノードファイルが正しいことと、`gitlab-ctl`が実行できることを確認します。これにより、レプリカにも同様のエラーがある場合、[`gitlab-ctl`の実行エラー](#errors-running-gitlab-ctl)のイシューが解決されます:

   ```shell
   sudo gitlab-ctl stop patroni
   sudo gitlab-ctl reconfigure
   ```

1. レプリカ: `incompatible server version`エラーを修正するために、PostgreSQLバイナリを必要なバージョンに再リンクします:

   1. `/etc/gitlab/gitlab.rb`を編集し、必要なバージョンを指定します:

      ```ruby
      postgresql['version'] = 13
      ```

   1. GitLabを再設定します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. バイナリが再リンクされていることを確認します。PostgreSQL用に配布されるバイナリはメジャーリリース間で異なります。少数の誤ったシンボリックリンクがあるのが一般的です:

      ```shell
      sudo ls -al /opt/gitlab/embedded/bin | grep postgres
      ```

1. レプリカ: 指定されたバージョンに対してPostgreSQLが完全に再初期化されていることを確認します:

   ```shell
   cd /var/opt/gitlab/postgresql
   sudo rm -rf data
   sudo gitlab-ctl reconfigure
   ```

1. レプリカ: 必要に応じて、追加の2つのターミナルセッションでデータベースを監視します:

   - `pg_basebackup`の実行に伴い、ディスク使用量が増加します。レプリカの初期化の進行状況を以下で追跡します:

     ```shell
     cd /var/opt/gitlab/postgresql
     watch du -sh data
     ```

   - ログでプロセスを監視します:

     ```shell
     sudo gitlab-ctl tail patroni
     ```

1. レプリカ: Patroniを起動してレプリカを再初期化します:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. レプリカ: 完了後、`/etc/gitlab/gitlab.rb`からハードコードされたバージョンを削除します:

   1. `/etc/gitlab/gitlab.rb`を編集し、`postgresql['version']`を削除します。
   1. GitLabを再設定します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. 正しいバイナリがリンクされていることを確認します:

      ```shell
      sudo ls -al /opt/gitlab/embedded/bin | grep postgres
      ```

1. すべてのノードでクラスターステータスを確認します:

   ```shell
   sudo gitlab-ctl patroni members
   ```

必要に応じて、他のレプリカでもこの手順を繰り返します。

## PostgreSQLレプリカが作成中にループにはまる {#postgresql-replicas-stuck-in-loop-while-being-created}

PostgreSQLレプリカが移行しているように見えても、その後ループで再起動する場合は、レプリカとプライマリサーバーの`/opt/gitlab-data/postgresql/`フォルダーのパーミッションを確認してください。

このエラーメッセージはログにも表示されます: `could not get COPY data stream: ERROR: could not open file "<file>" Permission denied`。

## その他のコンポーネントに関するイシュー {#issues-with-other-components}

ここで説明されていないコンポーネントでイシューが発生した場合は、そのコンポーネントの特定のドキュメントページのトラブルシューティングセクションを必ず確認してください:

- [Consul](../consul.md#troubleshooting-consul)
- [PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#troubleshooting)
