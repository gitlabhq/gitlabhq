---
stage: Data Access
group: Durability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 新しいサーバーに移行する
---

<!-- some details borrowed from GitLab.com move from Azure to GCP detailed at https://gitlab.com/gitlab-com/migration/-/blob/master/.gitlab/issue_templates/failover.md -->

GitLabのバックアップと復元機能を使用して、インスタンスを新しいサーバーに移行できます。このセクションでは、単一のサーバーで実行されているGitLabデプロイの一般的な手順の概要を説明します。GitLab Geoを実行している場合、代替手段として[計画フェイルオーバーにおけるGeoディザスターリカバリー](../geo/disaster_recovery/planned_failover.md)があります。移行手段としてGeoを選択する前に、すべてのサイトが[Geoの要件](../geo/_index.md#requirements-for-running-geo)を満たしていることを確認する必要があります。

{{< alert type="warning" >}}

新旧両方のサーバーが連携することなく個別にデータを処理することは避けてください。複数のサーバーが同時に接続して同じデータを処理してしまう可能性があります。たとえば、[受信メール](../incoming_email.md)を使用している場合、両方のGitLabインスタンスが同時にメールを処理すると、どちらのインスタンスでも一部のデータが失われる可能性があります。このような問題は、[パッケージ化されていないデータベース](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server)、パッケージ化されていないRedisインスタンス、パッケージ化されていないSidekiqなど、他のサービスでも発生する可能性があります。

{{< /alert >}}

前提要件:

- 移行の少し前に、[ブロードキャストメッセージバナー](../broadcast_messages.md)で今後のスケジュール済みメンテナンスについてユーザーに通知することを検討してください。
- バックアップが完了し、最新の状態であることを確認してください。破壊的なコマンド（`rm`など）が誤って実行された場合に備えて、システムレベルの完全なバックアップを作成するか、移行に関わるすべてのサーバーのスナップショットを作成しておいてください。

## 新しいサーバーを準備する {#prepare-the-new-server}

新しいサーバーを準備するには、次の手順に従います。

1. 中間者攻撃に関する警告を避けるため、旧サーバーから[SSHホストキー](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)をコピーします。手順の例については、[プライマリサイトのSSHホストキーを手動でレプリケートする](../geo/replication/configuration.md#step-2-manually-replicate-the-primary-sites-ssh-host-keys)を参照してください。
1. [GitLabをインストールして設定](https://about.gitlab.com/install/)します（[受信メール](../incoming_email.md)を除く）。
   1. GitLabをインストールします。
   1. 旧サーバーから新サーバーに`/etc/gitlab`ファイルをコピーして設定し、必要に応じて更新します。詳細については、[Linuxパッケージインストールのバックアップおよび復元手順](https://docs.gitlab.com/omnibus/settings/backups.html)を参照してください。
   1. 該当する場合は、[受信メール](../incoming_email.md)を無効にします。
   1. バックアップと復元後の最初の起動時に、新しいCI/CDジョブが開始されないようにブロックします。`/etc/gitlab/gitlab.rb`を編集し、次のように設定します。

      ```ruby
      nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
      ```

   1. GitLabを再設定します。

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. 不要かつ意図しないデータ処理を避けるため、GitLabを停止します。

   ```shell
   sudo gitlab-ctl stop
   ```

1. RedisデータベースおよびGitLabバックアップファイルを受信できるように、新しいサーバーを設定します。

   ```shell
   sudo rm -f /var/opt/gitlab/redis/dump.rdb
   sudo chown <your-linux-username> /var/opt/gitlab/redis /var/opt/gitlab/backups
   ```

## 旧サーバーのコンテンツを準備して転送する {#prepare-and-transfer-content-from-the-old-server}

1. 旧サーバーの最新のシステムレベルのバックアップまたはスナップショットがあることを確認します。
1. お使いのGitLabのエディションでサポートされている場合は、[メンテナンスモード](../maintenance_mode/_index.md)を有効にします。
1. 新しいCI/CDジョブが開始されないようにブロックします。
   1. `/etc/gitlab/gitlab.rb`を編集し、次のように設定します。

      ```ruby
      nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
      ```

   1. GitLabを再設定します。

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. 定期的なバックグラウンドジョブを無効にします。
   1. 左側のサイドバーの下部で、**管理者**を選択します。
   1. 左側のサイドバーで、**モニタリング** > **バックグラウンドジョブ**を選択します。
   1. Sidekiqのダッシュボードで、**Cron**タブを選択し、次に**Disable All**を選択します。
1. 実行中のCI/CDジョブが完了するまで待ちます。そうしないと、完了していないジョブが失われる可能性があります。実行中のジョブを表示するには、左側のサイドバーで**Overviews** > **Jobs**を選択し、次に**Running**を選択します。
1. Sidekiqジョブが完了するのを待ちます。
   1. 左側のサイドバーで、**モニタリング** > **バックグラウンドジョブ**を選択します。
   1. Sidekiqダッシュボードで、**Queues**を選択し、次に**Live Poll**を選択します。**Busy**および**Enqueued**が0になるまで待ちます。これらのキューにはユーザーから送信された作業が含まれています。これらのジョブが完了する前にシャットダウンすると、作業が失われる可能性があります。移行後の検証に備えて、Sidekiqダッシュボードに表示されている数値をメモしておいてください。
1. Redisデータベースをディスクにフラッシュし、移行に必要なサービス以外のGitLabを停止します。

   ```shell
   sudo /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket save && sudo gitlab-ctl stop && sudo gitlab-ctl start postgresql && sudo gitlab-ctl start gitaly
   ```

1. GitLabのバックアップを作成します。

   ```shell
   sudo gitlab-backup create
   ```

1. 次のGitLabサービスを無効にし、意図しない再起動を防ぐため、`/etc/gitlab/gitlab.rb`の末尾に次の設定を追加します。

   ```ruby
   alertmanager['enable'] = false
   gitaly['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_pages['enable'] = false
   gitlab_workhorse['enable'] = false
   grafana['enable'] = false
   logrotate['enable'] = false
   gitlab_rails['incoming_email_enabled'] = false
   nginx['enable'] = false
   node_exporter['enable'] = false
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   prometheus['enable'] = false
   puma['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   registry['enable'] = false
   sidekiq['enable'] = false
   ```

1. GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. すべてが停止していること、そして実行中のサービスがないことを確認します。

   ```shell
   sudo gitlab-ctl status
   ```

1. Redisデータベースのバックアップを転送する前に、新しいサーバー上のRedisを停止します。

   ```shell
   sudo gitlab-ctl stop redis
   ```

1. RedisデータベースとGitLabのバックアップを新しいサーバーに転送します。

   ```shell
   sudo scp /var/opt/gitlab/redis/dump.rdb <your-linux-username>@new-server:/var/opt/gitlab/redis
   sudo scp /var/opt/gitlab/backups/your-backup.tar <your-linux-username>@new-server:/var/opt/gitlab/backups
   ```

### Gitやオブジェクトのデータ量が多いインスタンスの場合 {#for-instances-with-a-large-volume-of-git-and-object-data}

GitLabインスタンスのローカルボリューム上に大量のデータがある場合、たとえば1 TBを超えるようなケースでは、バックアップに時間がかかることがあります。そのような場合は、新しいインスタンスの適切なボリュームにデータを転送する方が簡単なこともあります。

手動で移行する必要がある主なボリュームは次のとおりです。

- すべてのGitデータを含む`/var/opt/gitlab/git-data`ディレクトリ。Gitデータの破損を防ぐために、[リポジトリの移動に関するドキュメントの該当セクション](../operations/moving_repositories.md#migrating-to-another-gitlab-instance)を必ずお読みください。
- アーティファクトなどのオブジェクトデータを含む`/var/opt/gitlab/gitlab-rails/shared`ディレクトリ。
- Linuxパッケージに含まれているバンドル版PostgreSQLを使用している場合は、`/var/opt/gitlab/postgresql/data`にある[PostgreSQLデータディレクトリ](https://docs.gitlab.com/omnibus/settings/database.html#store-postgresql-data-in-a-different-directory)も移行する必要があります。

すべてのGitLabサービスが停止したら、`rsync`などのツールを使用するか、ボリュームスナップショットをマウントして、新しい環境にデータを移行できます。

## 新しいサーバーでデータを復元する {#restore-data-on-the-new-server}

1. 適切なファイルシステムの権限を復元します。

   ```shell
   sudo chown gitlab-redis /var/opt/gitlab/redis
   sudo chown gitlab-redis:gitlab-redis /var/opt/gitlab/redis/dump.rdb
   sudo chown git:root /var/opt/gitlab/backups
   sudo chown git:git /var/opt/gitlab/backups/your-backup.tar
   ```

1. Redisを起動します。

   ```shell
   sudo gitlab-ctl start redis
   ```

   Redisは`dump.rdb`を自動的に検出して復元します。

1. [GitLabバックアップを復元](restore_gitlab.md)します。
1. Redisデータベースが正しく復元されたことを確認します。
   1. 左側のサイドバーの下部で、**管理者**を選択します。
   1. 左側のサイドバーで、**モニタリング** > **バックグラウンドジョブ**を選択します。
   1. Sidekiqダッシュボードで、表示されている数値が旧サーバーの数値と一致することを確認します。
   1. Sidekiqダッシュボードで、**Cron**を選択し、次に**Enable All**を選択して、定期的なバックグラウンドジョブを再度有効にします。
1. GitLabインスタンスでの読み取り専用操作が期待どおりに機能することをテストします。たとえば、プロジェクトのリポジトリファイル、マージリクエスト、イシューを参照します。
1. 以前に[メンテナンスモード](../maintenance_mode/_index.md)を有効にしていた場合は、無効にします。
1. GitLabインスタンスが期待どおりに動作していることをテストします。
1. 該当する場合は、[受信メール](../incoming_email.md)を再度有効にし、期待どおりに動作していることをテストします。
1. DNSまたはロードバランサーを更新して、新しいサーバーを指すようにします。
1. 以前に追加したカスタムNGINX設定を削除して、新しいCI/CDジョブの開始をブロック解除します。

   ```ruby
   # The following line must be removed
   nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
   ```

1. GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. スケジュール済みメンテナンスに関する[ブロードキャストメッセージバナー](../broadcast_messages.md)を削除します。
