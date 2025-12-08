---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: メンテナンスRakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、一般的なメンテナンス用のRakeタスクを提供します。

## GitLabとシステム情報を収集する {#gather-gitlab-and-system-information}

このコマンドは、GitLabのインストールと、それが実行されているシステム情報を収集します。これらは、ヘルプを求めたり、イシューを報告したりする際に役立つ場合があります。マルチノード環境では、PostgreSQLソケットエラーを回避するために、GitLab Railsを実行しているノードでこのコマンドを実行します。

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-rake gitlab:env:info
  ```

- 自己コンパイルによるインストール:

  ```shell
  bundle exec rake gitlab:env:info RAILS_ENV=production
  ```

出力例: 

```plaintext
System information
System:         Ubuntu 20.04
Proxy:          no
Current User:   git
Using RVM:      no
Ruby Version:   2.7.6p219
Gem Version:    3.1.6
Bundler Version:2.3.15
Rake Version:   13.0.6
Redis Version:  6.2.7
Sidekiq Version:6.4.2
Go Version:     unknown

GitLab information
Version:        15.5.5-ee
Revision:       5f5109f142d
Directory:      /opt/gitlab/embedded/service/gitlab-rails
DB Adapter:     PostgreSQL
DB Version:     13.8
URL:            https://app.gitaly.gcp.gitlabsandbox.net
HTTP Clone URL: https://app.gitaly.gcp.gitlabsandbox.net/some-group/some-project.git
SSH Clone URL:  git@app.gitaly.gcp.gitlabsandbox.net:some-group/some-project.git
Elasticsearch:  no
Geo:            no
Using LDAP:     no
Using Omniauth: yes
Omniauth Providers:

GitLab Shell
Version:        14.12.0
Repository storage paths:
- default:      /var/opt/gitlab/git-data/repositories
- gitaly:       /var/opt/gitlab/git-data/repositories
GitLab Shell path:              /opt/gitlab/embedded/service/gitlab-shell


Gitaly
- default Address:      unix:/var/opt/gitlab/gitaly/gitaly.socket
- default Version:      15.5.5
- default Git Version:  2.37.1.gl1
- gitaly Address:       tcp://10.128.20.6:2305
- gitaly Version:       15.5.5
- gitaly Git Version:   2.37.1.gl1
```

## GitLabのライセンス情報を表示する {#show-gitlab-license-information}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このコマンドは、[GitLabライセンス](../license.md)に関する情報と、使用されているシート数を示します。これは、GitLab Enterpriseインストールでのみ使用できます。ライセンスをGitLab Community Editionにインストールすることはできません。

これらは、サポートでチケットを発行する場合や、ライセンスパラメータをプログラムで確認する場合に役立つ場合があります。

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-rake gitlab:license:info
  ```

- 自己コンパイルによるインストール:

  ```shell
  bundle exec rake gitlab:license:info RAILS_ENV=production
  ```

出力例: 

```plaintext
Today's Date: 2020-02-29
Current User Count: 30
Max Historical Count: 30
Max Users in License: 40
License valid from: 2019-11-29 to 2020-11-28
Email associated with license: user@example.com
```

## GitLabの設定をチェック {#check-gitlab-configuration}

`gitlab:check` Rakeタスクは、次のRakeタスクを実行します:

- `gitlab:gitlab_shell:check`
- `gitlab:gitaly:check`
- `gitlab:sidekiq:check`
- `gitlab:incoming_email:check`
- `gitlab:ldap:check`
- `gitlab:app:check`
- `gitlab:geo:check`（[Geo](../geo/replication/troubleshooting/common.md#health-check-rake-task)を実行している場合のみ）

各コンポーネントがインストールガイドに従ってセットアップされていることを確認し、見つかったイシューの修正を提案します。このコマンドは、アプリケーションサーバーから実行する必要があり、[Gitaly](../gitaly/configure_gitaly.md#run-gitaly-on-its-own-server)のようなコンポーネントサーバーでは正しく動作しません。

次のトラブルシューティングガイドも参照してください:

- [GitLab](../troubleshooting/_index.md)。
- [Linuxパッケージ](https://docs.gitlab.com/omnibus/#troubleshooting)インストール。

また、[現在のシークレットを使用してデータベースの値を復号化するできることを確認](check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)する必要があります。

`gitlab:check`を実行するには、次のように実行します:

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-rake gitlab:check
  ```

- 自己コンパイルによるインストール:

  ```shell
  bundle exec rake gitlab:check RAILS_ENV=production
  ```

- Kubernetesのインストール:

  ```shell
  kubectl exec -it <toolbox-pod-name> -- sudo gitlab-rake gitlab:check
  ```

  {{< alert type="note" >}} HelmベースのGitLabインストールの特定のアーキテクチャにより、`gitlab-shell`、Sidekiq、および`systemd`関連ファイルへの接続検証で誤検知が発生する場合があります。これらの報告された失敗は予想されるものであり、実際にはイシューを示唆するものではありません。診断結果をレビューする際は無視してください。{{< /alert >}}

`SANITIZE=true`を`gitlab:check`に使用して、出力からプロジェクト名を省略できます。

出力例: 

```plaintext
Checking Environment ...

Git configured for git user? ... yes
Has python2? ... yes
python2 is supported version? ... yes

Checking Environment ... Finished

Checking GitLab Shell ...

GitLab Shell version? ... OK (1.2.0)
Repo base directory exists? ... yes
Repo base directory is a symlink? ... no
Repo base owned by git:git? ... yes
Repo base access is drwxrws---? ... yes
post-receive hook up-to-date? ... yes
post-receive hooks in repos are links: ... yes

Checking GitLab Shell ... Finished

Checking Sidekiq ...

Running? ... yes

Checking Sidekiq ... Finished

Checking GitLab App...

Database config exists? ... yes
Database is SQLite ... no
All migrations up? ... yes
GitLab config exists? ... yes
GitLab config up to date? ... no
Cable config exists? ... yes
Resque config exists? ... yes
Log directory writable? ... yes
Tmp directory writable? ... yes
Init script exists? ... yes
Init script up-to-date? ... yes
Redis version >= 2.0.0? ... yes

Checking GitLab ... Finished
```

## `authorized_keys`ファイルを再構築する {#rebuild-authorized_keys-file}

場合によっては、`authorized_keys`ファイルを再構築する必要があります。たとえば、アップグレード後に[SSH経由](../../user/ssh.md)でプッシュすると`Permission denied (publickey)`が表示され、[ファイル`gitlab-shell.log`](../logs/_index.md#gitlab-shelllog)に`404 Key Not Found`エラーが表示される場合などです。`authorized_keys`を再構築するには、次のように実行します:

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-rake gitlab:shell:setup
  ```

- 自己コンパイルによるインストール:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:shell:setup RAILS_ENV=production
  ```

出力例: 

```plaintext
This will rebuild an authorized_keys file.
You will lose any data stored in authorized_keys file.
Do you want to continue (yes/no)? yes
```

## Redisキャッシュをクリアする {#clear-redis-cache}

何らかの理由でダッシュボードに誤った情報が表示される場合は、Redisのキャッシュをクリアしてください。これを行うには、次のように実行します:

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-rake cache:clear
  ```

- 自己コンパイルによるインストール:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
  ```

## アセットをプリコンパイルします。 {#precompile-the-assets}

バージョンアップグレード中に、間違ったCSSが発生したり、一部のアイコンが失われたりする可能性があります。その場合は、アセットを再度プリコンパイルしてみてください。

このRakeタスクは、セルフコンパイルインストールにのみ適用されます。[詳細](../../update/package/package_troubleshooting.md#missing-asset-files)については、Linuxパッケージを実行しているときにこのトラブルシューティングを行う方法を参照してください。Linuxパッケージのガイダンスは、KubernetesおよびDockerのGitLabのデプロイにも適用される可能性がありますが、一般に、コンテナベースのインストールでは、アセットの欠落に関するイシューは発生しません。

- 自己コンパイルによるインストール:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production
  ```

Linuxパッケージのインストールでは、最適化されていないアセット（JavaScript、CSS）は、アップストリームGitLabのリリース時にフリーズされます。Linuxパッケージのインストールには、これらのアセットの最適化されたバージョンが含まれています。パッケージをインストールした後、本番マシンでJavaScript / CSSコードを変更しない限り、本番マシンで`rake gitlab:assets:compile`をやり直す理由はありません。アセットが破損している疑いがある場合は、Linuxパッケージを再インストールする必要があります。

## リモートサイトへのTCP接続を確認する {#check-tcp-connectivity-to-a-remote-site}

プロキシのイシューを解決するには、GitLabのインストールが別のマシン（たとえば、PostgreSQLまたはWebサーバー）上のTCPサービスに接続できるかどうかを知る必要がある場合があります。このために、Rakeタスクが含まれています。

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-rake gitlab:tcp_check[example.com,80]
  ```

- 自己コンパイルによるインストール:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:tcp_check[example.com,80] RAILS_ENV=production
  ```

## 排他的リースをクリア（危険） {#clear-exclusive-lease-danger}

GitLabは、共有ロックメカニズムである`ExclusiveLease`を使用して、共有リソースでの同時操作を防止します。例としては、リポジトリで定期的なガベージコレクションを実行することがあります。

非常に特殊な状況では、排他的リースによってロックされた操作は、ロックをリリースせずに失敗する可能性があります。期限切れになるまで待てない場合は、このタスクを実行して手動でクリアできます。

すべての排他的リースをクリアするには:

{{< alert type="warning" >}}

GitLabまたはSidekiqの実行中は実行しないでください

{{< /alert >}}

```shell
sudo gitlab-rake gitlab:exclusive_lease:clear
```

リース`type`またはリース`type + id`を指定するには、スコープを指定します:

```shell
# to clear all leases for repository garbage collection:
sudo gitlab-rake gitlab:exclusive_lease:clear[project_housekeeping:*]

# to clear a lease for repository garbage collection in a specific project: (id=4)
sudo gitlab-rake gitlab:exclusive_lease:clear[project_housekeeping:4]
```

## データベースの移行のステータスを表示する {#display-status-of-database-migrations}

GitLabのアップグレード時に移行が完了したことを確認する方法については、[バックグラウンド移行のドキュメント](../../update/background_migrations.md)を参照してください。

特定の移行のステータスを確認するには、次のRakeタスクを使用できます:

```shell
sudo gitlab-rake db:migrate:status
```

[Geoセカンダリサイト上のトラッキングデータベース](../geo/setup/external_database.md#configure-the-tracking-database)を確認するには、次のRakeタスクを使用できます:

```shell
sudo gitlab-rake db:migrate:status:geo
```

これにより、各移行の`Status`が`up`または`down`のテーブルが出力されます。例: 

```shell
database: gitlabhq_production

 Status   Migration ID    Type     Milestone    Name
--------------------------------------------------
   up     20240701074848  regular  17.2         AddGroupIdToPackagesDebianGroupComponents
   up     20240701153843  regular  17.2         AddWorkItemsDatesSourcesSyncToIssuesTrigger
   up     20240702072515  regular  17.2         AddGroupIdToPackagesDebianGroupArchitectures
   up     20240702133021  regular  17.2         AddWorkspaceTerminationTimeoutsToRemoteDevelopmentAgentConfigs
   up     20240604064938  post     17.2         FinalizeBackfillPartitionIdCiPipelineMessage
   up     20240604111157  post     17.2         AddApprovalPolicyRulesFkOnApprovalGroupRules
```

GitLab 17.1以降、移行はGitLabリリースケイデンスに準拠した順序で実行されます。

## 完了していないデータベースの移行を実行する {#run-incomplete-database-migrations}

データベースの移行は、`sudo gitlab-rake db:migrate:status`コマンドの出力で、完了していない状態になることがあり、`down`ステータスが表示されます。

1. これらの移行を完了するには、次のRakeタスクを使用します:

   ```shell
   sudo gitlab-rake db:migrate
   ```

1. コマンドが完了したら、`sudo gitlab-rake db:migrate:status`を実行して、すべての移行が完了したかどうかを確認します（`up`ステータスになっているか）。

1. `puma`および`sidekiq`サービスをホットリロードします:

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   ```

GitLab 17.1以降、移行はGitLabリリースケイデンスに準拠した順序で実行されます。

## データベースのインデックスを再構築する {#rebuild-database-indexes}

{{< history >}}

- GitLab 13.5で`database_reindexing`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/42705)されました。デフォルトでは無効になっています。
- GitLab 13.9の[GitLab.comで有効](https://gitlab.com/groups/gitlab-org/-/epics/3989)になりました。
- GitLab 18.0の[GitLab Self-ManagedおよびGitLab Dedicatedで有効になりました。](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188548)

{{< /history >}}

{{< alert type="warning" >}}

本番環境で実行する場合は注意して使用し、オフピーク時に実行してください。

{{< /alert >}}

データベースのインデックスは、定期的に再構築して、領域を再利用し、時間の経過とともにインデックスの健全な肥大化レベルを維持できます。再インデックスは、[定期的なcronジョブ](https://docs.gitlab.com/omnibus/settings/database.html#automatic-database-reindexing)として実行することもできます。肥大化の「健全な」レベルは、特定のインデックスに大きく依存しますが、通常は30%0未満である必要があります。

前提要件: 

- この機能を使用するには、PostgreSQL 12以降が必要です。
- これらのインデックスタイプは**not supported**（サポートされていません）：式のインデックスと、制約除外に使用されるインデックス。

### 再インデックスを実行する {#run-reindexing}

次のタスクは、各データベースで最も肥大化している2つのインデックスのみを再構築します。3つ以上のインデックスを再構築するには、目的のすべてのインデックスが再構築されるまで、タスクを再度実行します。

1. 再インデックスタスクを実行します:

   ```shell
   sudo gitlab-rake gitlab:db:reindex
   ```

1. トラブルシューティングまたは実行を確認するには、[application_json.log](../../administration/logs/_index.md#application_jsonlog)を確認してください。

### 再インデックス設定をカスタマイズする {#customize-reindexing-settings}

小規模なインスタンスの場合、または再インデックスの動作を調整するには、Railsコンソールを使用してこれらの設定を変更できます:

```shell
sudo gitlab-rails console
```

次に、設定をカスタマイズします:

```ruby
# Lower minimum index size to 100 MB (default is 1 GB)
Gitlab::Database::Reindexing.minimum_index_size!(100.megabytes)

# Change minimum bloat threshold to 30% (default is 20%, there is no benefit from setting it lower)
Gitlab::Database::Reindexing.minimum_relative_bloat_size!(0.3)
```

### 自動再インデックス {#automated-reindexing}

データベースサイズが大幅に大きい大規模なインスタンスの場合は、アクティビティーが低い期間に実行するようにスケジュールすることで、データベースの再インデックスを自動化します。

#### Cronジョブでスケジュールする {#schedule-with-crontab}

パッケージ化されたGitLabインストールの場合、cronジョブを使用します:

1. Cronジョブを編集します:

   ```shell
   sudo crontab -e
   ```

1. 優先スケジュールに基づいてエントリを追加します:

   1. オプション1: 静かな期間中に毎日実行する

   ```shell
   # Run database reindexing every day at 21:12
   # The log will be rotated by the packaged logrotate daemon
   12 21 * * * /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

   1. オプション2: 週末のみに実行する

   ```shell
   # Run database reindexing at 01:00 AM on weekends
   0 1 * * 0,6 /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

   1. オプション3: トラフィックの少ない時間帯に頻繁に実行する

   ```shell
   # Run database reindexing every 3 hours during night hours (22:00-07:00)
   0 22,1,4,7 * * * /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

Kubernetesのデプロイの場合、CronJobリソースを使用して同様のスケジュールを作成し、再インデックスタスクを実行できます。

### 注 {#notes}

- データベースのインデックスの再構築はディスクを大量に使用するタスクであるため、オフピーク時にタスクを実行する必要があります。ピーク時にタスクを実行すると、肥大化が増加し、特定のクエリの実行速度が低下する可能性があります。
- このタスクには、復元するされるインデックス用に空きディスク領域が必要です。作成されたインデックスには`_ccnew`が付加されます。再インデックスタスクが失敗した場合、タスクを再度実行すると、一時的なインデックスがクリーンアップされます。
- データベースのインデックスの再構築が完了するまでの時間は、ターゲットデータベースのサイズによって異なります。数時間から数日かかる場合があります。
- このタスクはRedisロックを使用しているため、頻繁に実行するようにスケジュールしても安全です。別の再インデックスタスクが既に実行されている場合、操作は行われません。

## データベースのスキーマをダンプする {#dump-the-database-schema}

まれに、すべてのデータベースの移行が完了していても、データベースのスキーマがアプリケーションコードで想定されるものと異なる場合があります。これが発生すると、GitLabで奇妙なエラーが発生する可能性があります。

データベースのスキーマをダンプするには:

```shell
SCHEMA=/tmp/structure.sql gitlab-rake db:schema:dump
```

このRakeタスクは、データベースのスキーマダンプを含む`/tmp/structure.sql`ファイルを作成します。

違いがあるかどうかを判断するには:

1. [`db/structure.sql`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/structure.sql)プロジェクトの[`gitlab`](https://gitlab.com/gitlab-org/gitlab)ファイルに移動します。GitLabバージョンに一致するブランチを選択します。たとえば、GitLab 16.2のファイルは<https://gitlab.com/gitlab-org/gitlab/-/blob/16-2-stable-ee/db/structure.sql>です。
1. お使いのバージョンの`db/structure.sql`ファイルと`/tmp/structure.sql`を比較します。

## スキーマの不整合についてデータベースをチェックする {#check-the-database-for-schema-inconsistencies}

{{< history >}}

- GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/390719)されました。

{{< /history >}}

このRakeタスクは、スキーマに不整合がないかデータベースをチェックし、それらをターミナルに出力します。このタスクは、GitLabサポートのガイダンスの下で使用される診断ツールです。データベースの不整合が予想される場合があるため、ルーチンチェックにタスクを使用しないでください。

```shell
gitlab-rake gitlab:db:schema_checker:run
```

## データベースに関する情報と統計を収集する {#collect-information-and-statistics-about-the-database}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/groups/gitlab-com/-/epics/2456)されました。

{{< /history >}}

`gitlab:db:sos`コマンドは、GitLabデータベースに関する設定、パフォーマンス、および診断データを収集して、イシューのトラブルシューティングを支援します。このコマンドの実行場所は、設定によって異なります。GitLabがインストールされている場所（`(/gitlab)`）を基準にして、このコマンドを実行してください。

- **Scaled GitLab**（スケールされたGitLab）：PumaまたはSidekiqサーバー上。
- **Cloud native install**（クラウドネイティブインストール）：ツールボックスポッド上。
- **All other configurations**（その他すべての設定）：GitLabサーバー上。

必要に応じてコマンドを変更します:

- **Default path**（デフォルト） パス - デフォルトのファイルパス（`/var/opt/gitlab/gitlab-rails/tmp/sos.zip`）でコマンドを実行するには、`gitlab-rake gitlab:db:sos`を実行します。
- **Custom path**（カスタム） パス - ファイルパスを変更するには、`gitlab-rake gitlab:db:sos["/absolute/custom/path/to/file.zip"]`を実行します。
- **Zsh users**（Zshユーザー） - Zsh設定を変更していない場合は、次のようにコマンド全体を引用符で囲む必要があります：`gitlab-rake "gitlab:db:sos[/absolute/custom/path/to/file.zip]"`

Rakeタスクは5分間実行されます。指定したパスに圧縮フォルダーが作成されます。圧縮フォルダーには、多数のファイルが含まれています。

### オプションのクエリ統計データを有効にする {#enable-optional-query-statistics-data}

`gitlab:db:sos`Rakeタスクは、[`pg_stat_statements`拡張機能](https://www.postgresql.org/docs/16/pgstatstatements.html)を使用して、遅いクエリのトラブルシューティングを行うためのデータを収集することもできます。

この拡張機能を有効にするのはオプションであり、PostgreSQLとGitLabを再起動する必要があります。このデータは、遅いデータベースによって引き起こされるGitLabのパフォーマンスイシューのトラブルシューティングに必要となる可能性があります。

前提要件: 

- 拡張機能を有効または無効にするには、スーパーユーザー特権を持つPostgreSQLユーザーである必要があります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. 次の行を追加するには、`/etc/gitlab/gitlab.rb`を変更します:

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. 再設定を実行します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. この拡張機能をロードするにはPostgreSQLを再起動する必要があるため、GitLabも再起動する必要があります:

   ```shell
   sudo gitlab-ctl restart postgresql
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. 次の行を追加するには、`/etc/gitlab/gitlab.rb`を変更します:

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. 再設定を実行します:

   ```shell
   docker exec -it <container-id> gitlab-ctl reconfigure
   ```

1. この拡張機能をロードするにはPostgreSQLを再起動する必要があるため、GitLabも再起動する必要があります:

   ```shell
   docker exec -it <container-id> gitlab-ctl restart postgresql
   docker exec -it <container-id> gitlab-ctl restart sidekiq
   docker exec -it <container-id> gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="外部PostgreSQLサービス" >}}

1. `postgresql.conf`ファイルで次のパラメータを追加またはコメント解除します

   ```shell
   shared_preload_libraries = 'pg_stat_statements'
   pg_stat_statements.track = all
   ```

1. 変更を有効にするには、PostgreSQLを再起動します。

1. GitLabを再起動します。Web（Puma）サービスとSidekiqサービスを再起動する必要があります。

{{< /tab >}}

{{< /tabs >}}

1. [データベースコンソール](../troubleshooting/postgresql.md)で、以下を実行します:

   ```SQL
   CREATE EXTENSION pg_stat_statements;
   ```

1. 拡張機能が動作していることを確認します:

   ```SQL
   SELECT extname FROM pg_extension WHERE extname = 'pg_stat_statements';
   SELECT * FROM pg_stat_statements LIMIT 10;
   ```

## 重複するCI/CDタグについてデータベースをチェックする {#check-the-database-for-duplicate-cicd-tags}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/518698)されました。

{{< /history >}}

このRakeタスクは、`ci`データベースの`tags`テーブルで重複するタグをチェックします。このイシューは、長期間にわたって複数のメジャーアップグレードが行われたインスタンスに影響を与える可能性があります。次のコマンドを実行して重複するタグを検索し、重複するタグを参照するタグの割り当てを書き換えて、代わりに元のタグを使用します。

```shell
sudo gitlab-rake gitlab:db:deduplicate_tags
```

このコマンドをドライランモードで実行するには、環境変数`DRY_RUN=true`を設定します。

## PostgreSQL照合バージョンの不一致を検出する {#detect-postgresql-collation-version-mismatches}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195450) in GitLab 18.2.
- 破損の事前定義されたインデックスセットのスポットチェックが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198071)されたGitLab 18.3。
- `MAX_TABLE_SIZE`をカスタマイズし、PgBouncerを[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202736)するオプションが回避されたGitLab 18.4。

{{< /history >}}

PostgreSQL照合チェッカー:

- データベースとオペレーティングシステム間の照合バージョンの不一致を検出し、インデックスの破損を引き起こす可能性があります。PostgreSQLは、文字列照合（並べ替えおよび比較ルール）にオペレーティングシステムの`glibc`ライブラリを使用します。
- 照合の不一致が原因で破損しやすいことがわかっている、事前定義されたインデックスセットで、破損のスポットチェック（重複検出）を実行します。これらのインデックスは、照合の不一致が原因で破損しやすいことがわかっています。

基盤となる`glibc`ライブラリを変更するオペレーティングシステムのアップグレード後に、このタスクを実行します。

前提要件: 

- PostgreSQL 13以降。

PostgreSQL照合の不一致と、関連するインデックスの破損をすべてのデータベースでチェックするには:

```shell
sudo gitlab-rake gitlab:db:collation_checker
```

特定のデータベースをチェックするには:

```shell
# Check main database
sudo gitlab-rake gitlab:db:collation_checker:main

# Check CI database
sudo gitlab-rake gitlab:db:collation_checker:ci
```

### テーブルサイズの制限を調整する {#adjust-table-size-limits}

デフォルトでは、データベースのパフォーマンスに影響を与える可能性のある、実行時間の長いクエリを回避するために、1 GBを超えるテーブルはスキップされます。`MAX_TABLE_SIZE`環境変数を設定して、テーブルサイズのしきい値を調整できます。

{{< alert type="warning" >}}

テーブルサイズの制限を増やすと、データベースのパフォーマンスに影響を与える可能性のある、実行時間の長いクエリが発生する可能性があります。

{{< /alert >}}

```shell
# Set custom table size limit (in bytes)
# to increase the max table size threshold to 10 GB
MAX_TABLE_SIZE=10737418240 sudo gitlab-rake gitlab:db:collation_checker:main
```

### 実行時間の長いクエリに対するPgBouncerの回避 {#bypass-pgbouncer-for-long-running-queries}

トラブルシューティングセクションの[ステートメントタイムアウトエラーの解決](#resolve-statement-timeout-errors)を参照してください。

### 出力例 {#example-output}

問題が見つからない場合:

```plaintext
Checking for PostgreSQL collation mismatches on main database...
No collation mismatches detected on main.
Found 8 indexes to corruption spot check.
No corrupted indexes detected.
```

不一致が検出された場合、タスクは、影響を受けるインデックスを修正するための修正手順を提供します。

不一致がある場合の出力例:

```plaintext
Checking for PostgreSQL collation mismatches on main database...
⚠️ COLLATION MISMATCHES DETECTED on main database!
2 collation(s) have version mismatches:
  - en_US.utf8: stored=428.1, actual=513.1
  - es_ES.utf8: stored=428.1, actual=513.1

Found 8 indexes to corruption spot check.
Affected indexes that need to be rebuilt:
  - index_projects_on_name (btree) on table projects
    • Issues detected: duplicates
    • Affected columns: name
    • Type: UNIQUE
    • Needs deduplication: Yes

REMEDIATION STEPS:
1. Put GitLab into maintenance mode
2. Run the following SQL commands:

# Step 1: Check for duplicate entries in unique indexes
SELECT name, COUNT(*), ARRAY_AGG(id) FROM projects GROUP BY name HAVING COUNT(*) > 1 LIMIT 1;

# If duplicates exist, you may need to use gitlab:db:deduplicate_tags or similar tasks
# to fix duplicate entries before rebuilding unique indexes.

# Step 2: Rebuild affected indexes
# Option A: Rebuild individual indexes with minimal downtime:
REINDEX INDEX CONCURRENTLY index_projects_on_name;

# Option B: Alternatively, rebuild all indexes at once (requires downtime):
REINDEX DATABASE main;

# Step 3: Refresh collation versions
ALTER DATABASE main REFRESH COLLATION VERSION;

3. Take GitLab out of maintenance mode
```

PostgreSQLの照合順序の問題と、それがデータベースインデックスにどのように影響するかについて詳しくは、[PostgreSQLのOSアップグレードに関するドキュメント](../postgresql/upgrading_os.md)を参照してください。

## 破損したデータベースインデックスの修復 {#repair-corrupted-database-indexes}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196677) in GitLab 18.2.
- GitLab 18.4でPgBouncerを回避するオプションが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203843)。

{{< /history >}}

インデックス修復ツールは、データの整合性の問題を引き起こす可能性のある、破損または欠落しているデータベースインデックスを修正します。このツールは、照合順序の不一致やその他の破損の問題によって影響を受ける、特定の問題のあるインデックスに対応します。このツール:

- 一意のインデックスが破損している場合、データを重複排除します。
- データの整合性を維持するために参照を更新します。
- 正しい設定でインデックスを再構築または作成します。

インデックスを修復する前に、ドライランモードでツールを実行して、潜在的な変更を分析します:

```shell
sudo DRY_RUN=true gitlab-rake gitlab:db:repair_index
```

次の出力例は、変更点を示しています:

```shell
INFO -- : DRY RUN: Analysis only, no changes will be made.
INFO -- : Running Index repair on database main...
INFO -- : Processing index 'index_merge_request_diff_commit_users_on_name_and_email'...
INFO -- : Index is unique. Checking for duplicate data...
INFO -- : No duplicates found in 'merge_request_diff_commit_users' for columns: name,email.
INFO -- : Index exists. Reindexing...
INFO -- : Index reindexed successfully.
```

すべてのデータベース内の既知の問題のあるすべてのインデックスを修復するには:

```shell
sudo gitlab-rake gitlab:db:repair_index
```

このコマンドは、各データベースを処理し、インデックスを修復します。例: 

```shell
INFO -- : Running Index repair on database main...
INFO -- : Processing index 'index_merge_request_diff_commit_users_on_name_and_email'...
INFO -- : Index is unique. Checking for duplicate data...
INFO -- : No duplicates found in 'merge_request_diff_commit_users' for columns: name,email.
INFO -- : Index does not exist. Creating new index...
INFO -- : Index created successfully.
INFO -- : Index repair completed for database main.
```

特定のデータベースのインデックスを修復するには:

```shell
# Repair indexes in main database
sudo gitlab-rake gitlab:db:repair_index:main

# Repair indexes in CI database
sudo gitlab-rake gitlab:db:repair_index:ci
```

### 実行時間の長いクエリに対するPgBouncerの回避 {#bypass-pgbouncer-for-long-running-queries-1}

トラブルシューティングセクションの[ステートメントタイムアウトエラーの解決](#resolve-statement-timeout-errors)を参照してください。

## トラブルシューティング {#troubleshooting}

### アドバイザリロック接続情報 {#advisory-lock-connection-information}

`db:migrate` Rakeタスクを実行すると、次のような出力が表示されることがあります:

```shell
main: == [advisory_lock_connection] object_id: 173580, pg_backend_pid: 5532
main: == [advisory_lock_connection] object_id: 173580, pg_backend_pid: 5532
```

返されるメッセージは情報提供を目的としたものであり、無視できます。

### `gitlab:env:info` Rakeタスク実行時のPostgreSQLソケットエラー {#postgresql-socket-errors-when-executing-the-gitlabenvinfo-rake-task}

Gitalyなどの非Railsノードで`sudo gitlab-rake gitlab:env:info`を実行すると、次のエラーが表示されることがあります:

```plaintext
PG::ConnectionBad: could not connect to server: No such file or directory
Is the server running locally and accepting
connections on Unix domain socket "/var/opt/gitlab/postgresql/.s.PGSQL.5432"?
```

これは、マルチノード環境では、`gitlab:env:info` Rakeタスクは、**GitLab Rails**を実行しているノードでのみ実行する必要があるためです。

### ステートメントタイムアウトエラーの解決 {#resolve-statement-timeout-errors}

GitLabインスタンスでPgBouncerを使用しており、データベースのメンテナンスタスク（照合順序チェッカーやインデックス修復など）中にステートメントタイムアウトが発生した場合は、直接PostgreSQL接続を使用してPgBouncerを回避します。

```shell
# Example with direct connection
GITLAB_BACKUP_PGUSER=postgres GITLAB_BACKUP_PGHOST=localhost sudo gitlab-rake gitlab:db:collation_checker

GITLAB_BACKUP_PGUSER=postgres GITLAB_BACKUP_PGHOST=localhost sudo gitlab-rake gitlab:db:repair_index
```

サポートされている環境変数:

- `GITLAB_BACKUP_PGHOST`
- `GITLAB_BACKUP_PGUSER`
- `GITLAB_BACKUP_PGPORT`
- `GITLAB_BACKUP_PGPASSWORD`

PgBouncerの回避方法と、サポートされている環境変数の完全なリストについて詳しくは、[PgBouncerを回避する手順](../postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)を参照してください。
