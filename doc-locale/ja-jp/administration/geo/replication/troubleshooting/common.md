---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 一般的なGeoエラーのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## 基本的なトラブルシューティング {#basic-troubleshooting}

より高度なトラブルシューティングを試す前に:

- [Geoサイト](#check-the-health-of-the-geo-sites)のヘルスチェックを確認します。
- [PostgreSQLのレプリケーションが動作しているか](#check-if-postgresql-replication-is-working)確認します。

### Geoサイトのヘルスチェック {#check-the-health-of-the-geo-sites}

**プライマリ**サイトで:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。

問題の特定に役立つように、各**セカンダリ**サイトで次のヘルスチェックを実行します:

- サイトは実行されていますか？
- セカンダリサイトのデータベースは、ストリーミングレプリケーション用に設定されていますか？
- セカンダリサイトの追跡データベースは設定されていますか？
- セカンダリサイトの追跡データベースは接続されていますか？
- セカンダリサイトの追跡データベースは最新の状態ですか？
- セカンダリサイトのステータスは1時間以内ですか？

サイトのステータスが1時間以上前の場合、サイトは「Unhealthy」と表示されます。その場合は、影響を受けているセカンダリサイトの[Railsコンソール](../../../operations/rails_console.md)で以下を実行してみてください:

```ruby
Geo::MetricsUpdateWorker.new.perform
```

エラーが発生した場合、ジョブが完了しない原因もそのエラーである可能性があります。1時間以上かかる場合、ステータスが時々更新されても、「Unhealthy」としてステータスが変動したり、そのままになったりする可能性があります。これは、使用量の増加、時間の経過に伴うデータの増加、またはデータベースインデックスの欠落などのパフォーマンスバグが原因である可能性があります。

`top`や`htop`のようなユーティリティでシステムのCPU負荷を監視できます。PostgreSQLが大量のCPUを使用している場合、問題があるか、システムのリソースが不足している可能性があります。システムメモリも監視する必要があります。

メモリを増やす場合は、`/etc/gitlab/gitlab.rb`設定でPostgreSQLのメモリ関連の設定も確認する必要があります。

ステータスが正常に更新された場合、Sidekiqに問題がある可能性があります。実行されていますか？ログにエラーが表示されますか？このジョブは毎分エンキューされることになっていますが、[ジョブの重複排除の冪等キー](../../../sidekiq/sidekiq_troubleshooting.md#clearing-a-sidekiq-job-deduplication-idempotency-key)が適切にクリアされていない場合は実行されない可能性があります。これらのジョブのうち1つだけが一度に実行されるようにするために、Redisで排他的リースを取得します。プライマリサイトは、PostgreSQLデータベースでステータスを直接更新します。セカンダリサイトは、ステータスデータとともにプライマリサイトにHTTP Postリクエストを送信します。

特定のヘルスチェックが失敗した場合も、サイトは「Unhealthy」と表示されます。影響を受けるセカンダリサイトの[Railsコンソール](../../../operations/rails_console.md)で以下を実行して、失敗を明らかにすることができます:

```ruby
Gitlab::Geo::HealthCheck.new.perform_checks
```

`""`（空の文字列）または`"Healthy"`が返された場合、チェックは成功しています。それ以外の場合は、メッセージで何が失敗したかを説明するか、例外メッセージを表示する必要があります。

ユーザーインターフェースからレポートされた一般的なエラーメッセージを解決する方法については、[一般的なエラーの修正](#fixing-common-errors)を参照してください。

ユーザーインターフェースが機能しない場合、またはサインインできない場合は、Geoヘルスチェックを手動で実行して、この情報といくつかの詳細を取得できます。

#### ヘルスチェックRakeタスク {#health-check-rake-task}

{{< history >}}

- カスタムNTPサーバーの使用は、GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105514)されました。

{{< /history >}}

このRakeタスクは、**Rails**または**プライマリ** Geoサイトの**セカンダリ**ノードで実行できます:

```shell
sudo gitlab-rake gitlab:geo:check
```

出力例: 

```plaintext
Checking Geo ...

GitLab Geo is available ... yes
GitLab Geo is enabled ... yes
This machine's Geo node name matches a database record ... yes, found a secondary node named "Shanghai"
GitLab Geo tracking database is correctly configured ... yes
Database replication enabled? ... yes
Database replication working? ... yes
GitLab Geo HTTP(S) connectivity ...
* Can connect to the primary node ... yes
HTTP/HTTPS repository cloning is enabled ... yes
Machine clock is synchronized ... yes
Git user has default SSH configuration? ... yes
OpenSSH configured to use AuthorizedKeysCommand ... yes
GitLab configured to disable writing to authorized_keys file ... yes
GitLab configured to store new projects in hashed storage? ... yes
All projects are in hashed storage? ... yes

Checking Geo ... Finished
```

環境変数を使用してカスタムNTPサーバーを指定することもできます。例: 

```shell
sudo gitlab-rake gitlab:geo:check NTP_HOST="ntp.ubuntu.com" NTP_TIMEOUT="30"
```

次の環境変数がサポートされています。

| 変数      | 説明 | デフォルト値 |
| ------------- | ----------- | ------------- |
| `NTP_HOST`    | NTPホスト。 | `pool.ntp.org` |
| `NTP_PORT`    | ホストがリッスンするNTPポート。 | `ntp` |
| `NTP_TIMEOUT` | NTPタイムアウト（秒）。 | `net-ntp` Rubyライブラリで定義された値（[60秒](https://github.com/zencoder/net-ntp/blob/3d0990214f439a5127782e0f50faeaf2c8ca7023/lib/net/ntp/ntp.rb#L6)）。 |

Rakeタスクが`OpenSSH configured to use AuthorizedKeysCommand`チェックをスキップすると、次の出力が表示されます:

```plaintext
OpenSSH configured to use AuthorizedKeysCommand ... skipped
  Reason:
  Cannot access OpenSSH configuration file
  Try fixing it:
  This is expected if you are using SELinux. You may want to check configuration manually
  For more information see:
  doc/administration/operations/fast_ssh_key_lookup.md
```

この問題は、次のいずれかの場合に発生する可能性があります:

- [SELinux](../../../operations/fast_ssh_key_lookup.md#selinux-support)を使用している。
- SELinuxを使用しておらず、ファイル権限が制限されているため、`git`ユーザーがOpenSSH設定ファイルにアクセスできません。

後者の場合、次の出力は、`root`ユーザーのみがこのファイルを読み取ることができることを示しています:

```plaintext
sudo stat -c '%G:%U %A %a %n' /etc/ssh/sshd_config

root:root -rw------- 600 /etc/ssh/sshd_config
```

ファイルオーナーまたは権限を変更せずに、`git`ユーザーがOpenSSH設定ファイルを読み取れるようにするには、`acl`を使用します:

```plaintext
sudo setfacl -m u:git:r /etc/ssh/sshd_config
```

#### 同期ステータスRakeタスク {#sync-status-rake-task}

現在の同期情報は、Geo **セカンダリ**サイトでRails（Puma、Sidekiq、またはGeoログカーソル）を実行している任意のノードでこのRakeタスクを手動で実行することで確認できます。

GitLabは、オブジェクトストレージに保存されているオブジェクトを検証**not**（しません）。オブジェクトストレージを使用している場合、すべての「検証済み」チェックに0件の成功が表示されます。これは想定されており、懸念の原因ではありません。

```shell
sudo gitlab-rake geo:status
```

出力には次のものが含まれます:

- 発生した失敗があった場合の「失敗」アイテムの数
- 「成功」アイテムの割合（「合計」に対する割合）

例: 

```plaintext
                        Geo Site Information
--------------------------------------------
                                      Name: example-us-east-2
                                       URL: https://gitlab.example.com
                                  Geo Role: Secondary
                             Health Status: Healthy
                This Node's GitLab Version: 17.7.0-ee

                     Replication Information
--------------------------------------------
                             Sync Settings: Full
                  Database replication lag: 0 seconds
           Last event ID seen from primary: 12345 (about 2 minutes ago)
                   Last event ID processed: 12345 (about 2 minutes ago)
                    Last status report was: 1 minute ago

                          Replication Status
--------------------------------------------
                    Lfs Objects replicated: succeeded 111 / total 111 (100%)
            Merge Request Diffs replicated: succeeded 28 / total 28 (100%)
                  Package Files replicated: succeeded 90 / total 90 (100%)
       Terraform State Versions replicated: succeeded 65 / total 65 (100%)
           Snippet Repositories replicated: succeeded 63 / total 63 (100%)
        Group Wiki Repositories replicated: succeeded 14 / total 14 (100%)
             Pipeline Artifacts replicated: succeeded 112 / total 112 (100%)
              Pages Deployments replicated: succeeded 55 / total 55 (100%)
                        Uploads replicated: succeeded 2 / total 2 (100%)
                  Job Artifacts replicated: succeeded 32 / total 32 (100%)
                Ci Secure Files replicated: succeeded 44 / total 44 (100%)
         Dependency Proxy Blobs replicated: succeeded 15 / total 15 (100%)
     Dependency Proxy Manifests replicated: succeeded 2 / total 2 (100%)
      Project Wiki Repositories replicated: succeeded 2 / total 2 (100%)
 Design Management Repositories replicated: succeeded 1 / total 1 (100%)
           Project Repositories replicated: succeeded 2 / total 2 (100%)

                         Verification Status
--------------------------------------------
                      Lfs Objects verified: succeeded 111 / total 111 (100%)
              Merge Request Diffs verified: succeeded 28 / total 28 (100%)
                    Package Files verified: succeeded 90 / total 90 (100%)
         Terraform State Versions verified: succeeded 65 / total 65 (100%)
             Snippet Repositories verified: succeeded 63 / total 63 (100%)
          Group Wiki Repositories verified: succeeded 14 / total 14 (100%)
               Pipeline Artifacts verified: succeeded 112 / total 112 (100%)
                Pages Deployments verified: succeeded 55 / total 55 (100%)
                          Uploads verified: succeeded 2 / total 2 (100%)
                    Job Artifacts verified: succeeded 32 / total 32 (100%)
                  Ci Secure Files verified: succeeded 44 / total 44 (100%)
           Dependency Proxy Blobs verified: succeeded 15 / total 15 (100%)
       Dependency Proxy Manifests verified: succeeded 2 / total 2 (100%)
        Project Wiki Repositories verified: succeeded 2 / total 2 (100%)
   Design Management Repositories verified: succeeded 1 / total 1 (100%)
             Project Repositories verified: succeeded 2 / total 2 (100%)

```

すべてのオブジェクトはレプリケーションおよび検証され、[Geo用語集](../../glossary.md)で定義されています。各データ型をレプリケートおよび検証するために使用する方法の詳細については、[サポートされているGeoデータ型](../datatypes.md#data-types)を参照してください。

失敗したアイテムの詳細については、[ファイル`gitlab-rails/geo.log`を確認してください](../../../logs/log_parsing.md#find-most-common-geo-sync-errors)

レプリケーションまたは検証の失敗に気付いた場合は、[解決を試みることができます](synchronization_verification.md)。

##### GeoチェックRakeタスクの実行時に見つかったエラーの修正 {#fixing-errors-found-when-running-the-geo-check-rake-task}

このRakeタスクを実行すると、ノードが適切に設定されていない場合、エラーメッセージが表示されることがあります:

```shell
sudo gitlab-rake gitlab:geo:check
```

- Railsは、データベースに接続するときにパスワードを提供しませんでした。

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... Exception: fe_sendauth: no password supplied
  GitLab Geo is enabled ... Exception: fe_sendauth: no password supplied
  ...
  Checking Geo ... Finished
  ```

  `gitlab_rails['db_password']`が、`postgresql['sql_user_password']`のハッシュを作成するときに使用されたプレーンテキストパスワードに設定されていることを確認します。

- Railsはデータベースに接続できません。

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... Exception: FATAL:  no pg_hba.conf entry for host "1.1.1.1",  user "gitlab", database "gitlabhq_production", SSL on
  FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL off
  GitLab Geo is enabled ... Exception: FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL on
  FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL off
  ...
  Checking Geo ... Finished
  ```

  `postgresql['md5_auth_cidr_addresses']`に含まれているRailsノードのIPアドレスがあることを確認します。また、IPアドレスにサブネットマスクが含まれていることを確認します: `postgresql['md5_auth_cidr_addresses'] = ['1.1.1.1/32']`。

- Railsが誤ったパスワードを提供しました。

  ```plaintext
  Checking Geo ...
  GitLab Geo is available ... Exception: FATAL:  password authentication failed for user "gitlab"
  FATAL:  password authentication failed for user "gitlab"
  GitLab Geo is enabled ... Exception: FATAL:  password authentication failed for user "gitlab"
  FATAL:  password authentication failed for user "gitlab"
  ...
  Checking Geo ... Finished
  ```

  `gitlab_rails['db_password']`でハッシュを作成するときに使用された`postgresql['sql_user_password']`に対して正しいパスワードが設定されていることを確認するには、`gitlab-ctl pg-password-md5 gitlab`を実行してパスワードを入力します。

- チェックから`not a secondary node`が返されます。

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... yes
  GitLab Geo is enabled ... yes
  GitLab Geo tracking database is correctly configured ... not a secondary node
  Database replication enabled? ... not a secondary node
  ...
  Checking Geo ... Finished
  ```

  **プライマリ**サイトのWebインターフェースで、**管理者**エリアの**Geo** > **サイト**でセカンダリサイトを追加したことを確認します。また、**プライマリ**サイトの**管理者**エリアでセカンダリサイトを追加するときに`gitlab_rails['geo_node_name']`を入力したことを確認します。

- チェックから`Exception: PG::UndefinedTable: ERROR:  relation "geo_nodes" does not exist`が返されます。

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... no
    Try fixing it:
    Add a new license that includes the GitLab Geo feature
    For more information see:
    https://about.gitlab.com/features/gitlab-geo/
  GitLab Geo is enabled ... Exception: PG::UndefinedTable: ERROR:  relation "geo_nodes" does not exist
  LINE 8:                WHERE a.attrelid = '"geo_nodes"'::regclass
                                             ^
  :               SELECT a.attname, format_type(a.atttypid, a.atttypmod),
                       pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod,
                       c.collname, col_description(a.attrelid, a.attnum) AS comment
                  FROM pg_attribute a
                  LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
                  LEFT JOIN pg_type t ON a.atttypid = t.oid
                  LEFT JOIN pg_collation c ON a.attcollation = c.oid AND a.attcollation <> t.typcollation
                 WHERE a.attrelid = '"geo_nodes"'::regclass
                   AND a.attnum > 0 AND NOT a.attisdropped
                 ORDER BY a.attnum
  ...
  Checking Geo ... Finished
  ```

  PostgreSQLのメジャーバージョン（9 > 10）を実行する場合、この更新は想定されています。[replicationレプリケーションプロセスの開始](../../setup/database.md#step-3-initiate-the-replication-process)に従います。

- Railsには、Geo追跡データベースに接続するために必要な設定がないようです。

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... yes
  GitLab Geo is enabled ... yes
  GitLab Geo tracking database is correctly configured ... no
  Try fixing it:
  Rails does not appear to have the configuration necessary to connect to the Geo tracking database. If the tracking database is running on a node other than this one, then you may need to add configuration.
  ...
  Checking Geo ... Finished
  ```

  - すべてのサービスの単一ノードでセカンダリサイトを実行している場合は、[Geoデータベースレプリケーション-セカンダリサーバーの設定](../../setup/database.md#step-2-configure-the-secondary-server)に従います。
  - セカンダリサイトの追跡データベースを独自のノードで実行している場合は、[複数のサーバーのGeo-GeoセカンダリサイトでのGeo追跡データベースの設定](../multiple_servers.md#step-2-configure-the-geo-tracking-database-on-the-geo-secondary-site)に従います
  - セカンダリサイトの追跡データベースをPatroniクラスターで実行している場合は、[Geoデータベースレプリケーション-追跡PostgreSQLデータベース用のPatroniクラスターの設定](../../setup/database.md#configuring-patroni-cluster-for-the-tracking-postgresql-database)に従います
  - セカンダリサイトの追跡データベースを外部データベースで実行している場合は、[外部PostgreSQLインスタンスでのGeo](../../setup/external_database.md#configure-the-tracking-database)に従います
  - Geoチェックタスクが、GitLab Railsアプリ（Puma、Sidekiq、またはGeoログカーソル）を実行するサービスを実行していないノードで実行された場合、このエラーは無視できます。ノードはRailsを設定する必要はありません。

##### メッセージ: マシンの時計は同期されています...例外 {#message-machine-clock-is-synchronized--exception}

Rakeタスクは、サーバーの時計がNTPと同期されていることを検証しようとします。Geoが正しく機能するには、同期された時計が必要です。例として、セキュリティのために、プライマリサイトとセカンダリサイトのサーバー時間が約1分以上異なる場合、Geoサイト間のリクエストは失敗します。このチェックタスクが、時間の不一致以外の理由で完了しなくても、Geoが機能しないとは限りません。

チェックを実行するRubyジェムは、`pool.ntp.org`がその参照時間ソースとしてハードコードされています。

- 例外メッセージ`Machine clock is synchronized ... Exception: Timeout::Error`

  この問題は、サーバーがホスト`pool.ntp.org`にアクセスできない場合に発生します。

- 例外メッセージ`Machine clock is synchronized ... Exception: No route to host - recvfrom(2)`

  この問題は、ホスト名`pool.ntp.org`が時刻サービスを提供しないサーバーに解決される場合に発生します。

この場合、GitLab 15.7以降では、[環境変数を使用してカスタムNTPサーバーを指定](#health-check-rake-task)します。

GitLab 15.6以前では、次の回避策のいずれかを使用します:

- リクエストを有効なローカルタイムサーバーに送信するために、`pool.ntp.org`の`/etc/hosts`にエントリを追加します。これにより、長いタイムアウトとタイムアウトエラーが修正されます。
- チェックを有効なIPアドレスに直接送信します。これにより、タイムアウトの問題は解決されますが、前に述べたように、チェックは`No route to host`エラーで失敗します。

[クラウドネイティブGitLabデプロイ](https://docs.gitlab.com/charts/advanced/geo/#set-the-geo-primary-site)は、Kubernetesのコンテナがホストクロックにアクセスできないため、エラーを生成します:

```plaintext
Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
```

##### メッセージ: `cannot execute INSERT in a read-only transaction` {#message-cannot-execute-insert-in-a-read-only-transaction}

このエラーがセカンダリサイトで発生した場合、`gitlab-rails`または`gitlab-rake`コマンドなど、GitLab Railsのすべての使用法、およびPuma、Sidekiq、Geoログカーソルのサービスに影響を与える可能性があります。

```plaintext
ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute INSERT in a read-only transaction
/opt/gitlab/embedded/service/gitlab-rails/app/models/application_record.rb:86:in `block in safe_find_or_create_by'
/opt/gitlab/embedded/service/gitlab-rails/app/models/concerns/cross_database_modification.rb:92:in `block in transaction'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/database.rb:332:in `block in transaction'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/database.rb:331:in `transaction'
/opt/gitlab/embedded/service/gitlab-rails/app/models/concerns/cross_database_modification.rb:83:in `transaction'
/opt/gitlab/embedded/service/gitlab-rails/app/models/application_record.rb:86:in `safe_find_or_create_by'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:21:in `by_name'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `block in populate!'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `map'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `populate!'
/opt/gitlab/embedded/service/gitlab-rails/config/initializers/fill_shards.rb:9:in `<top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb:7:in `<top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
```

PostgreSQLのリードレプリカのデータベースは、これらのエラーを生成します:

```plaintext
2023-01-17_17:44:54.64268 ERROR:  cannot execute INSERT in a read-only transaction
2023-01-17_17:44:54.64271 STATEMENT:  /*application:web,db_config_name:main*/ INSERT INTO "shards" ("name") VALUES ('storage1') RETURNING "id"
```

この状況は、次の場合に発生する可能性があります:

- セカンダリサイトがまだセカンダリサイトであることを認識していない初期設定中。エラーを解決するには、[手順3に従ってください。セカンダリサイトを追加してください](../configuration.md#step-3-add-the-secondary-site)。
- Geoセカンダリサイトのアップグレード中。`gitlab_rails['auto_migrate']`が`true`に設定されている可能性があり、GitLabがレプリカデータベースでデータベース移行を試みる原因となっていますが、これは不要です。エラーを解決するには:

  1. セカンダリサイトのGitLab RailsノードにルートとしてSSH接続します。
  1. `/etc/gitlab/gitlab.rb`を編集し、この設定をコメントアウトするか、falseに設定します:

     ```ruby
     gitlab_rails['auto_migrate'] = false
     ```

  1. GitLabを再設定します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

### PostgreSQLレプリケーションが動作しているかどうかの確認 {#check-if-postgresql-replication-is-working}

PostgreSQLレプリケーションが動作しているかどうかを確認するには、以下を確認してください:

- [サイトが正しいデータベースノードを指している](#are-sites-pointing-to-the-correct-database-node)。
- [Geoが現在のサイトを正しく検出できる](#can-geo-detect-the-current-site-correctly)。

それでも問題が解決しない場合は、[高度なレプリケーションのトラブルシューティング](synchronization_verification.md)を参照してください。

#### サイトは正しいデータベースノードを指していますか？ {#are-sites-pointing-to-the-correct-database-node}

**プライマリ**Geo [サイト](../../glossary.md)が、書き込み権限を持つデータベースノードを指していることを確認する必要があります。

すべての**セカンダリ**サイトは、読み取り専用のデータベースノードのみを指している必要があります。

#### Geoは現在のサイトを正しく検出できますか？ {#can-geo-detect-the-current-site-correctly}

Geoは、次のロジックを使用して、現在のPumaまたはSidekiqノードのGeo [サイト](../../glossary.md)名を`/etc/gitlab/gitlab.rb`で検索します:

1. 「Geoノード名」を取得します（[設定の名前を「Geoサイト名」に変更するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/335944)があります）:
   - Linuxパッケージ: `gitlab_rails['geo_node_name']`設定を取得します。
   - GitLab Helmチャート: `global.geo.nodeName`設定を取得します（[GitLab Geoを使用したチャート](https://docs.gitlab.com/charts/advanced/geo/)を参照）。
1. それが定義されていない場合は、`external_url`設定を取得します。

この名前は、**Geoサイト**ダッシュボードで同じ**名前**を持つGeoサイトを検索するために使用されます。

現在のマシンに、データベース内のサイトと一致するサイト名があるかどうかを確認するには、チェックタスクを実行します:

```shell
sudo gitlab-rake gitlab:geo:check
```

現在のマシンのサイト名と、一致するデータベースレコードが**プライマリ**サイトまたは**セカンダリ**サイトのどちらであるかを表示します。

```plaintext
This machine's Geo node name matches a database record ... yes, found a secondary node named "Shanghai"
```

```plaintext
This machine's Geo node name matches a database record ... no
  Try fixing it:
  You could add or update a Geo node database record, setting the name to "https://example.com/".
  Or you could set this machine's Geo node name to match the name of an existing database record: "London", "Shanghai"
  For more information see:
  doc/administration/geo/replication/troubleshooting/_index.md#can-geo-detect-the-current-node-correctly
```

[名前]フィールドの説明にある推奨されるサイト名の詳細については、[Geo **管理者**エリアの共通設定](../../../geo_sites.md#common-settings)を参照してください。

### OSロケールデータの互換性を確認する {#check-os-locale-data-compatibility}

可能であれば、すべてのサイトのすべてのGeoノードは、[Geoを実行するための要件](../../_index.md#requirements-for-running-geo)で定義されているように、同じメソッドとオペレーティングシステムでデプロイする必要があります。

異なるオペレーティングシステムまたは異なるオペレーティングシステムのバージョンがGeoサイト全体にデプロイされている場合は、Geoをセットアップする前にロケールデータの互換性チェックを**must**（行う必要があります）。また、GitLabデプロイメソッドの組み合わせを使用する場合は、`glibc`を確認する必要があります。ロケールは、Linuxパッケージインストール、GitLab Dockerコンテナ、Helmチャートデプロイ、または外部データベースサービス間で異なる場合があります。`glibc`バージョンの互換性の確認方法を含め、[PostgreSQLのオペレーティングシステムのアップグレードに関するドキュメント](../../../postgresql/upgrading_os.md)を参照してください。

Geoは、PostgreSQLとストリーミングレプリケーションを使用して、Geoサイト間でデータをレプリケートします。PostgreSQLは、テキストをソートするために、オペレーティングシステムのCライブラリによって提供されるロケールデータを使用します。CライブラリのロケールデータがGeoサイト間で互換性がない場合、エラーが発生したクエリの結果が発生し、[セカンダリサイトでの正しくない動作](https://gitlab.com/gitlab-org/gitlab/-/issues/360723)につながります。

たとえば、Ubuntu 18.04（以前）およびRHEL/CentOS 7（以前）は、以降のリリースと互換性がありません。詳細については、[PostgreSQL Wikiを参照してください](https://wiki.postgresql.org/wiki/Locale_data_changes)。

## 一般的なエラーの修正 {#fixing-common-errors}

このセクションでは、Webインターフェースの**管理者**エリアにレポートされる一般的なエラーメッセージと、それらを修正する方法について説明します。

### 既存の追跡データベースを再利用できません {#an-existing-tracking-database-cannot-be-reused}

Geoは、既存の追跡データベースを再利用できません。

新しいセカンダリを使用するか、[Geoセカンダリサイトのレプリケーションのリセット](synchronization_verification.md#resetting-geo-secondary-site-replication)に従って、セカンダリ全体をリセットするのが最も安全です。

セカンダリサイトがGeoイベントを見逃している可能性があるため、セカンダリサイトをリセットせずに再利用するのは危険です。たとえば、削除イベントが見過ごされると、セカンダリサイトには、削除されるべきデータが永続的に残ってしまいます。同様に、データの場所を物理的に移動させるイベントを見失うと、データは1つの場所に永続的に放置され、再検証されるまで他の場所では見つからなくなります。これが、GitLabがデータの移動を不要にするハッシュストレージに切り替えた理由です。イベントの消失により、他にも未知の問題が発生する可能性があります。

これらの種類のリスクが適用されない場合（たとえば、テスト環境など）、またはメインのPostgresデータベースにGeoサイトが追加されてからのすべてのGeoイベントがまだ含まれていることがわかっている場合は、このヘルスチェックを回避できます:

1. 最後に処理されたイベントの時刻を取得します。**セカンダリ**サイトのRailsコンソールで、以下を実行します:

   ```ruby
   Geo::EventLogState.last.created_at.utc
   ```

1. たとえば、`2024-02-21 23:50:50.676918 UTC`のように出力内容をコピーします。
1. セカンダリサイトの作成時刻を更新して、より古く見えるようにします。**プライマリ**サイトのRailsコンソールで、以下を実行します:

   ```ruby
   GeoNode.secondary_nodes.last.update_column(:created_at, DateTime.parse('2024-02-21 23:50:50.676918 UTC') - 1.second)
   ```

   このコマンドは、影響を受けるセカンダリサイトが最後に作成されたものであることを前提としています。

1. **管理者** > **Geo** > **サイト**で、セカンダリサイトのステータスを更新します。**セカンダリ**サイトのRailsコンソールで、以下を実行します:

   ```ruby
   Geo::MetricsUpdateWorker.new.perform
   ```

1. セカンダリサイトは不健全と表示されるはずです。そうでない場合は、セカンダリサイトで`gitlab-rake gitlab:geo:check`を実行するか、セカンダリサイトを再度追加してからRailsを再起動してみてください。
1. 不足しているデータ、または最新ではないデータを同期するには、**管理者** > **Geo** > **サイト**に移動します。
1. セカンダリサイトの下の**レプリケーションの詳細**を選択します。
1. すべてのデータ型に対して**すべて再検証**を選択します。

### Geoサイトのデータベースが書き込み可能 {#geo-site-has-a-database-that-is-writable}

このエラーメッセージは、**セカンダリ**サイト上のデータベースレプリカの問題を示しており、Geoがアクセスできることを想定しています。書き込み可能なセカンダリサイトのデータベースは、データベースがプライマリサイトとのレプリケーション用に構成されていないことを示しています。通常、次のいずれかを意味します:

- サポートされていないレプリケーション方式が使用された（たとえば、論理レプリケーション）。
- [Geoデータベースレプリケーション](../../setup/database.md)をセットアップする手順が正しく実行されませんでした。
- データベース接続の詳細が正しくありません。つまり、`/etc/gitlab/gitlab.rb`ファイルで間違ったユーザーを指定しています。

Geoの**セカンダリ**サイトには、2つの別個のPostgreSQLインスタンスが必要です:

- **プライマリ**サイトの読み取り専用レプリカ。
- レプリケーションメタデータを保持する、通常の書き込み可能なインスタンス。つまり、Geoのトラッキングデータベースです。

このエラーメッセージは、**セカンダリ**サイト内のレプリカデータベースが誤って構成されており、レプリケーションが停止したことを示します。

データベースを復元し、レプリケーションを再開するには、次のいずれかを実行します:

- [Geoセカンダリサイトのレプリケーションをリセットします](synchronization_verification.md#resetting-geo-secondary-site-replication)。
- [Linuxパッケージを使用して、新しいGeoセカンダリをセットアップします](../../setup/_index.md#using-linux-package-installations)。

新しいセカンダリを最初からセットアップする場合は、[Geoクラスターから古いサイトを削除する](../remove_geo_site.md)必要もあります。

### Geoサイトがプライマリサイトからデータベースをレプリケートしていないようです {#geo-site-does-not-appear-to-be-replicating-the-database-from-the-primary-site}

データベースが正しくレプリケートされないようにする最も一般的な問題は次のとおりです:

- **セカンダリ**サイトが**プライマリ**サイトに到達できません。認証情報と[ファイアウォールルール](../../_index.md#firewall-rules)を確認してください。
- SSL証明書の問題。**プライマリ**サイトから`/etc/gitlab/gitlab-secrets.json`をコピーしたことを確認してください。
- データベースストレージディスクがいっぱいです。
- データベースレプリケーションスロットが誤って構成されています。
- データベースがレプリケーションスロットまたは別の代替手段を使用しておらず、WALファイルがパージされたため、追いつくことができません。

サポートされている設定については、[Geoデータベースレプリケーション](../../setup/database.md)の手順に従ってください。

### Geoデータベースバージョン（...）が最新の移行（...）と一致しません {#geo-database-version--does-not-match-latest-migration-}

Linuxパッケージインストールを使用している場合、アップグレード中に何らかのエラーが発生した可能性があります。次のことができます: 

- `sudo gitlab-ctl reconfigure`を実行します。
- **セカンダリ**サイトでrootとして`sudo gitlab-rake db:migrate:geo`を実行して、データベース移行を手動でトリガーします。

### GitLabが100％を超えるリポジトリが同期されたことを示しています {#gitlab-indicates-that-more-than-100-of-repositories-were-synced}

これは、プロジェクトレジストリ内の孤立したレコードが原因である可能性があります。これらはレジストリワーカーを使用して定期的にクリーンアップされているため、自身で修正するまでしばらくお待ちください。

### プライマリサイトのチェックサムが失敗しました {#failed-checksums-on-primary-site}

Geoのプライマリ検証情報画面で識別された失敗したチェックサムは、ファイルが見つからないか、チェックサムが一致しないことが原因である可能性があります。`gitlab-rails/geo.log`ファイルに、`"Repository cannot be checksummed because it does not exist"`または`"File is not checksummable"`のようなエラーメッセージが表示されることがあります。

失敗した項目に関する追加情報については、[整合性チェックRakeタスク](../../../raketasks/check.md#uploaded-files-integrity)を実行します:

```ruby
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:ci_secure_files:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

個々のエラーに関する詳細情報については、`VERBOSE=1`変数を使用します。

### セカンダリサイトがUIで**不健全**と表示される {#secondary-site-shows-unhealthy-in-ui}

プライマリサイトの`/etc/gitlab/gitlab.rb`で`external_url`の値を更新した場合、またはプロトコルを`http`から`https`に変更した場合、セカンダリサイトが**不健全**と表示されることがあります。また、`geo.log`に次のエラーが表示されることもあります:

```plaintext
"class": "Geo::NodeStatusRequestService",
...
"message": "Failed to Net::HTTP::Post to primary url: http://primary-site.gitlab.tld/api/v4/geo/status",
  "error": "Failed to open TCP connection to <PRIMARY_IP_ADDRESS>:80 (Connection refused - connect(2) for \"<PRIMARY_ID_ADDRESS>\" port 80)"
```

この場合、変更されたURLをすべてのサイトで必ず更新してください:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. URLを変更して、変更を保存します。

### メッセージ: バックアップ中の`ERROR: canceling statement due to conflict with recovery` {#message-error-canceling-statement-due-to-conflict-with-recovery-during-backup}

Geo**セカンダリ**でのバックアップの実行は[サポートされていません](https://gitlab.com/gitlab-org/gitlab/-/issues/211668)。

**セカンダリ**でバックアップを実行すると、次のエラーメッセージが表示されることがあります:

```plaintext
Dumping PostgreSQL database gitlabhq_production ...
pg_dump: error: Dumping the contents of table "notes" failed: PQgetResult() failed.
pg_dump: error: Error message from server: ERROR:  canceling statement due to conflict with recovery
DETAIL:  User query might have needed to see row versions that must be removed.
pg_dump: error: The command was: COPY public.notes (id, note, [...], last_edited_at) TO stdout;
```

Geo**secondaries**（セカンダリ）でのGitLabアップグレード中にデータベースのバックアップが自動的に作成されるのを防ぐには、次の空のファイルを作成します:

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

### オブジェクト検証中のプライマリでのCPU使用率が高い {#high-cpu-usage-on-primary-during-object-verification}

GitLab 16.11からGitLab 17.2まで、PostgreSQLインデックスがないと、CPU使用率が高くなり、アーティファクトの検証の進行が遅くなります。さらに、Geoセカンダリサイトが不健全としてレポートされる可能性があります。[イシュー471727](https://gitlab.com/gitlab-org/gitlab/-/issues/471727)では、動作について詳しく説明しています。

この問題が発生している可能性があるかどうかを判断するには、[影響を受けているかどうかを確認する](https://gitlab.com/gitlab-org/gitlab/-/issues/471727#to-confirm-if-you-are-affected)手順に従ってください。

影響を受けている場合は、[回避策](https://gitlab.com/gitlab-org/gitlab/-/issues/471727#workaround)の手順に従って、インデックスを手動で作成してください。インデックスを作成すると、完了するまでPostgreSQLがわずかに多くのリソースを消費するようになります。その後、検証が続行されている間はCPU使用率が高いままになる可能性がありますが、クエリの完了が大幅に速くなり、セカンダリサイトのステータスが正しく更新されるはずです。

### 検証に失敗しました: `Verification timed out after (...)` {#verification-failed-with-verification-timed-out-after-}

GitLab 16.11以降、Geoは同じ`artifact_id`に対して重複した`JobArtifactRegistry`エントリを作成する可能性があり、これにより、プライマリサイトとセカンダリサイト間で同期の失敗が発生する可能性があります。この問題は、`UploadRegistry`および`PackageFileRegistry`エントリにも影響を与える可能性があります。

この問題が発生している可能性があるかどうかを判断し、重複するエントリを削除するには、次の手順に従います:

1. セカンダリサイトで[Railsコンソール](../../../operations/rails_console.md)を開きます。
1. 重複があるモデルレコードIDの数を取得します:

   ```ruby
   artifact_ids = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').pluck(:artifact_id); artifact_ids.size
   upload_ids = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').pluck(:file_id); upload_ids.size
   package_file_ids = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').pluck(:package_file_id); package_file_ids.size
   ```

1. IDを出力します:

   ```ruby
   puts 'BEGIN Artifact IDs', artifact_ids, 'END Artifact IDs'
   puts 'BEGIN Upload IDs', upload_ids, 'END Upload IDs'
   puts 'BEGIN Package File IDs', package_file_ids, 'END Package File IDs'
   ```

   出力が空の場合、影響を受けていません。そうでない場合は、後で接続が失われた場合に備えて、ターミナル出力をテキストファイルに保存します。

1. すべての重複を削除します:

   ```ruby
   Geo::JobArtifactRegistry.where(artifact_id: artifact_ids).delete_all
   Geo::UploadRegistry.where(file_id: upload_ids).delete_all
   Geo::PackageFileRegistry.where(package_file_id: package_file_ids).delete_all
   ```

1. バックグラウンドジョブがレジストリ行を再度作成して同期されるまで待ちます。

[イシュー479852](https://gitlab.com/gitlab-org/gitlab/-/issues/479852)に従って、修正に関するフィードバックを入手してください。

### セカンダリでGeoRakeタスクチェックタスクを実行するときのエラー`end of file reached` {#error-end-of-file-reached-when-running-geo-rake-check-task-on-secondary}

セカンダリサイトで[ヘルスチェックRakeタスク](common.md#health-check-rake-task)を実行すると、次のエラーが発生する場合があります:

```plaintext
Can connect to the primary node ... no
Reason:
end of file reached
```

これは、プライマリサイトへの不正なURLが設定で指定されている場合に発生する可能性があります。トラブルシュートを行うには、[Railsコンソール](../../../operations/rails_console.md)で次のコマンドを実行します:

```ruby
primary = Gitlab::Geo.primary_node
primary.internal_uri
Gitlab::HTTP.get(primary.internal_uri, allow_local_requests: true, limit: 10)
```

以前の出力で、`internal_uri`の値が正しいことを確認してください。プライマリサイトのURLが正しくない場合は、`/etc/gitlab/gitlab.rb`、および**管理者** > **Geo** > **サイト**で再確認してください。

### Geoメトリクスコレクションからの過剰なデータベースIO {#excessive-database-io-from-geo-metrics-collection}

頻繁なGeoメトリクスコレクションが原因でデータベースの負荷が高い場合は、`geo_metrics_update_worker`ジョブの頻度を減らすことができます。この調整により、メトリクスの収集がデータベースのパフォーマンスに大きな影響を与える大規模なGitLabインスタンスでのデータベースの負荷を軽減できます。

間隔を大きくすると、Geoメトリクスの更新頻度が低くなります。これにより、メトリクスが最新ではない状態になる時間が長くなり、Geoレプリケーションをリアルタイムで監視する機能に影響を与える可能性があります。メトリクスが10分以上最新ではない場合、サイトは管理者エリアで恣意的に「不健全」としてマークされます。

次の例では、ジョブを30分ごとに実行するように設定します。必要に応じてcronスケジュールを調整します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`で次の設定を追加または変更します:

   ```ruby
   gitlab_rails['geo_metrics_update_worker_cron'] = "*/30 * * * *"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します: 

   ```yaml
   production: &base
     ee_cron_jobs:
       geo_metrics_update_worker:
         cron: "*/30 * * * *"
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}
