---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アップグレードする前に移行を確認する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabをアップグレードする前に、既存のすべてのバックグラウンド移行が完了していることを確認する必要があります。

## 保留中のデータベースバックグラウンド移行を確認する {#check-for-pending-database-background-migrations}

{{< history >}}

- 機能[フラグ](../administration/feature_flags/_index.md)`execute_batched_migrations_on_schedule`は、GitLab 13.12で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/329511)になっています。
- GitLab Self-Managedでは、管理者は無効にすることを選択できます。

{{< /history >}}

データベーステーブルをバッチで更新するために、GitLabはバッチバックグラウンド移行を使用できます。これらの移行はGitLabの開発者により作成され、アップグレード時に自動的に実行されます。ただし、このような移行は、一部の`integer`データベースの列を`bigint`に移行できるようにするために、スコープが制限されています。これは、一部のテーブルで整数のオーバーフローを防ぐために必要です。

バッチバックグラウンド移行はSidekiqによって処理され、分離して実行されるため、インスタンスは移行の処理中も動作し続けることができます。ただし、バッチバックグラウンド移行の実行中に、大規模なインスタンスが頻繁に使用されると、パフォーマンスが低下する可能性があります。すべての移行が完了するまで、[Sidekiqのステータスを常にモニタリング](../administration/admin_area.md#background-jobs)する必要があります。

これらの移行を完了するために必要な時間を短縮するには、`background_migration`キューでジョブを処理できる[Sidekiqワーカー](../administration/sidekiq/extra_sidekiq_processes.md)の数を増やします。

### バッチバックグラウンド移行のステータスを確認する {#check-the-status-of-batched-background-migrations}

GitLab UIで、またはデータベースに直接クエリを実行することで、バッチバックグラウンド移行のステータスを確認できます。GitLabをアップグレードする前に、すべての移行が`Finished`ステータスになっている必要があります。

移行が完了していない状態でGitLabをアップグレードしようとすると、次のエラーが表示されることがあります。

```plaintext
Expected batched background migration for the given configuration to be marked
as 'finished', but it is 'active':
```

このエラーが発生した場合は、GitLabのアップグレードに必要なバッチバックグラウンド移行を完了させる方法について、[オプションを確認](background_migrations_troubleshooting.md#database-migrations-failing-because-of-batched-background-migration-not-finished)してください。

#### GitLab UIから {#from-the-gitlab-ui}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

バッチバックグラウンド移行のステータスを確認するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **モニタリング > バックグラウンド移行**を選択します。
1. **待機中**または**完了中**を選択して未完了の移行を表示し、**失敗**を選択して失敗した移行を表示します。

#### データベースから {#from-the-database}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

データベースに直接クエリを実行して、バッチバックグラウンド移行のステータスを確認するには:

1. インスタンスのインストール方法の説明に従って、`psql`プロンプトにサインインします。たとえば、Linuxパッケージのインストールでは、`sudo gitlab-psql`を使用します。
1. 未完了のバッチバックグラウンド移行の詳細を表示するには、`psql`セッションで次のクエリを実行します。

   ```sql
   SELECT
     job_class_name,
     table_name,
     column_name,
     job_arguments
   FROM batched_background_migrations
   WHERE status NOT IN(3, 6);
   ```

または、`gitlab-psql -c "<QUERY>"`でクエリをラップして、バッチバックグラウンド移行のステータスを確認することもできます。

```shell
gitlab-psql -c "SELECT job_class_name, table_name, column_name, job_arguments FROM batched_background_migrations WHERE status NOT IN(3, 6);"
```

クエリがゼロ行を返す場合、すべてのバッチバックグラウンド移行は完了しています。

### 高度な機能を有効または無効にする {#enable-or-disable-advanced-features}

バッチバックグラウンド移行は、移行をカスタマイズしたり、完全に一時停止したりできる機能フラグを提供します。これらの機能フラグは、無効にするリスクを理解している上級ユーザーのみが無効にすることができます。

#### バッチバックグラウンド移行を一時停止する {#pause-batched-background-migrations}

{{< alert type="warning" >}}

[リリースされた機能を無効にすると、リスクが生じる](../administration/feature_flags/_index.md#risks-when-disabling-released-features)可能性があります。詳細については、各機能の履歴を参照してください。

{{< /alert >}}

進行中のバッチバックグラウンド移行を一時停止するには、バッチバックグラウンド移行機能を無効にします。この機能を無効にすると、現在の移行のバッチが完了し、機能が再び有効になるまで、次のバッチの開始を待機します。

前提要件:

- インスタンスへの管理者アクセス権が必要です。

現在のバッチバックグラウンド移行の状態を確認するには、次のデータベースクエリを使用します。

1. 実行中の移行のIDを取得します。

   ```sql
   SELECT
    id,
    job_class_name,
    table_name,
    column_name,
    job_arguments
   FROM batched_background_migrations
   WHERE status NOT IN(3, 6);
   ```

1. 次のクエリを実行します。`XX`を前の手順で取得したIDに置き換えて、移行のステータスを確認します。

   ```sql
   SELECT
    started_at,
    finished_at,
    finished_at - started_at AS duration,
    min_value,
    max_value,
    batch_size,
    sub_batch_size
   FROM batched_background_migration_jobs
   WHERE batched_background_migration_id = XX
   ORDER BY id DESC
   limit 10;
   ```

1. 数分以内にクエリを複数回実行して、新しい行が追加されていないことを確認します。新しい行が追加されていない場合、移行は一時停止されています。

1. 移行が一時停止されたことを確認したら、（上記の`enable`コマンドを使用して）移行を再開してバッチを続行します。大規模なインスタンスでは、バックグラウンド移行で各バッチの完了に最大48時間かかります。

#### バッチサイズの自動最適化 {#automatic-batch-size-optimization}

{{< history >}}

- GitLab 13.2で`optimize_batched_migrations`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60133)されました。デフォルトでは有効になっています。

{{< /history >}}

{{< alert type="warning" >}}

[リリースされた機能を無効にすると、リスクが生じる](../administration/feature_flags/_index.md#risks-when-disabling-released-features)可能性があります。詳細については、この機能の履歴を参照してください。

{{< /alert >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能を利用できます。機能を非表示にするには、管理者に`optimize_batched_migrations`という名前の[機能フラグを無効](../administration/feature_flags/_index.md)にするように依頼してください。GitLab.comでは、この機能を利用できます。GitLab Dedicatedでは、この機能は利用できません。

{{< /alert >}}

バッチバックグラウンド移行のスループット（時間単位で更新されるレコード数）を最大化するために、バッチサイズは、以前のバッチの完了にかかった処理時間に基づいて自動的に調整されます。

#### 並列実行 {#parallel-execution}

{{< history >}}

- GitLab 15.7で`batched_migrations_parallel_execution`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104027)されました。デフォルトでは無効になっています。
- GitLab 15.11の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/372316)。
- GitLab 16.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120808)になりました。機能フラグ`batched_migrations_parallel_execution`は削除されました。

{{< /history >}}

{{< alert type="warning" >}}

[リリースされた機能を無効にすると、リスクが生じる](../administration/feature_flags/_index.md#risks-when-disabling-released-features)可能性があります。詳細については、この機能の履歴を参照してください。

{{< /alert >}}

バッチバックグラウンド移行の実行を高速化するために、2つの移行が同時に実行されます。

[GitLab Railsコンソールへのアクセス権を持つGitLab管理者](../administration/feature_flags/_index.md)は、並行して実行されるバッチバックグラウンド移行の数を変更できます。

```ruby
ApplicationSetting.update_all(database_max_running_batched_background_migrations: 4)
```

### 失敗したバッチバックグラウンド移行を解決する {#resolve-failed-batched-background-migrations}

バッチバックグラウンド移行が失敗した場合は、[修正して再試行](#fix-and-retry-the-migration)してください。移行がエラーで引き続き失敗する場合は、次のいずれかの操作を行います。

- [失敗した移行を手動で完了する](#finish-a-failed-migration-manually)
- [失敗した移行を完了済みとしてマークする](#mark-a-failed-migration-finished)

#### 移行を修正して再試行する {#fix-and-retry-the-migration}

GitLabの新しいバージョンにアップグレードするには、失敗したバッチバックグラウンド移行をすべて解決する必要があります。バッチバックグラウンド移行の[ステータスを確認](#check-the-status-of-batched-background-migrations)すると、**失敗**タブに一部の移行が**失敗**ステータスで表示される場合があります。

![失敗したバッチバックグラウンド移行のテーブル](img/batched_background_migrations_failed_v14_3.png)

バッチバックグラウンド移行が失敗した理由を特定するには、失敗のエラーログを表示するか、UIでエラー情報を表示します。

前提要件:

- インスタンスへの管理者アクセス権が必要です。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **モニタリング > バックグラウンド移行**を選択します。
1. **失敗**タブを選択します。これにより、失敗したバッチバックグラウンド移行のリストが表示されます。
1. 失敗した**移行**を選択して、移行パラメータと失敗したジョブを確認します。
1. **失敗したジョブ**で、各**ID**を選択して、ジョブが失敗した理由を確認します。

GitLabのお客様は、バッチバックグラウンド移行が失敗した理由をデバッグするために、[サポートリクエスト](https://support.gitlab.com/hc/en-us/requests/new)を開くことを検討してください。

問題を修正するために、失敗した移行を再試行できます。

前提要件:

- インスタンスへの管理者アクセス権が必要です。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **モニタリング > バックグラウンド移行**を選択します。
1. **失敗**タブを選択します。これにより、失敗したバッチバックグラウンド移行のリストが表示されます。
1. 再試行ボタン（{{< icon name="retry" >}}）をクリックして、失敗したバッチバックグラウンド移行を選択して、再試行します。

再試行されたバッチバックグラウンド移行をモニタリングするには、定期的に[バッチバックグラウンド移行のステータスを確認](#check-the-status-of-batched-background-migrations)します。

#### 失敗した移行を手動で完了する {#finish-a-failed-migration-manually}

エラーで失敗したバッチバックグラウンド移行を手動で完了するには、失敗のエラーログまたはデータベースの情報を使用します。

{{< tabs >}}

{{< tab title="失敗のエラーログから" >}}

1. 失敗のエラーログを表示し、次のような`An error has occurred, all later migrations canceled`エラーメッセージを探します。

   ```plaintext
   StandardError: An error has occurred, all later migrations canceled:

   Expected batched background migration for the given configuration to be marked as
   'finished', but it is 'active':
     {:job_class_name=>"CopyColumnUsingBackgroundMigrationJob",
      :table_name=>"push_event_payloads",
      :column_name=>"event_id",
      :job_arguments=>[["event_id"],
      ["event_id_convert_to_bigint"]]
     }
   ```

1. 次のコマンドを実行し、山かっこ内の値を正しい引数に置き換えます。

   ```shell
   sudo gitlab-rake gitlab:background_migrations:finalize[<job_class_name>,<table_name>,<column_name>,'<job_arguments>']
   ```

   `[["id"],["id_convert_to_bigint"]]`などの複数の引数を処理する場合は、無効な文字エラーを防ぐために、各引数間のコンマをバックスラッシュ` \ `でエスケープします。たとえば、前のステップから移行を完了するには、次のようにします。

   ```shell
   sudo gitlab-rake gitlab:background_migrations:finalize[CopyColumnUsingBackgroundMigrationJob,push_event_payloads,event_id,'[["event_id"]\, ["event_id_convert_to_bigint"]]']
   ```

{{< /tab >}}

{{< tab title="データベースから" >}}

1. データベースで移行の[ステータスを確認](#check-the-status-of-batched-background-migrations)します。
1. クエリ結果を使用して移行コマンドを作成し、山かっこ内の値を正しい引数に置き換えます。

   ```shell
   sudo gitlab-rake gitlab:background_migrations:finalize[<job_class_name>,<table_name>,<column_name>,'<job_arguments>']
   ```

   たとえば、クエリが次のデータを返す場合:

   - `job_class_name`: `CopyColumnUsingBackgroundMigrationJob`
   - `table_name`: `events`
   - `column_name`: `id`
   - `job_arguments`: `[["id"], ["id_convert_to_bigint"]]`

 `[["id"],["id_convert_to_bigint"]]`などの複数の引数を処理する場合は、無効な文字エラーを防ぐために、各引数間のコンマをバックスラッシュ` \ `でエスケープします。`job_arguments`パラメータ値のすべてのコンマは、バックスラッシュでエスケープする必要があります。

 次に例を示します。

 ```shell
 sudo gitlab-rake gitlab:background_migrations:finalize[CopyColumnUsingBackgroundMigrationJob,ci_builds,id,'[["id"\, "stage_id"]\,["id_convert_to_bigint"\,"stage_id_convert_to_bigint"]]']
   ```

{{< /tab >}}

{{< /tabs >}}

#### 失敗した移行を完了済みとしてマークする {#mark-a-failed-migration-finished}

{{< alert type="warning" >}}

これらの手順を使用する前に、[GitLabサポートにお問い合わせ](https://about.gitlab.com/support/#contact-support)ください。この操作を行うと、データが失われたり、インスタンスが回復困難な方法で失敗したりする可能性があります。

{{< /alert >}}

多数のバージョンアップグレードをスキップしたり、下位互換性のないデータベーススキーマの変更を行ったりすると、バックグラウンド移行が失敗する場合があります（例については、[イシュー393216](https://gitlab.com/gitlab-org/gitlab/-/issues/393216)を参照してください）。失敗したバックグラウンド移行があると、アプリケーションをさらにアップグレードすることができません。

バックグラウンド移行がスキップしても「安全」であると判断された場合、移行を手動で完了済みとしてマークできます。

{{< alert type="warning" >}}

続行する前に、必ずバックアップを作成してください。

{{< /alert >}}

```ruby
# Start the rails console

connection = ApplicationRecord.connection # or Ci::ApplicationRecord.connection, depending on which DB was the migration scheduled

Gitlab::Database::SharedModel.using_connection(connection) do
  migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_for_configuration(
    Gitlab::Database.gitlab_schemas_for_connection(connection),
    'BackfillUserDetailsFields',
    :users,
    :id,
    []
  )

  # mark all jobs completed
  migration.batched_jobs.update_all(status: Gitlab::Database::BackgroundMigration::BatchedJob.state_machine.states['succeeded'].value)
  migration.update_attribute(:status, Gitlab::Database::BackgroundMigration::BatchedMigration.state_machine.states[:finished].value)
end
```

### すべてのバックグラウンド移行を同期的に実行する {#run-all-background-migrations-synchronously}

メンテナンス期間中に、バックグラウンド移行をフォアグラウンドで強制的に実行したい場合があります。

このスクリプトは、すべての移行が完了する前にタイムアウトまたは終了する可能性があります。すべての移行が完了するまで、再度実行できます。

```ruby
# Start the rails console

databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

Gitlab::Database.database_base_models.each do |database_name, model|
  Gitlab::Database::SharedModel.using_connection(model.connection) do
    Gitlab::Database::BackgroundMigration::BatchedMigration.with_status([:paused, :active]).find_each(batch_size: 100) do |migration|
      puts "#{database_name}: Finalizing migration #{migration.job_class_name} (ID: #{migration.id})... "
      Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.finalize(
        migration.job_class_name,
        migration.table_name,
        migration.column_name,
        Gitlab::Json.parse(migration.job_arguments),
        connection: model.connection
      )
      puts("done!\n")
    end
  end
end
```

## 保留中の高度な検索の移行を確認する {#check-for-pending-advanced-search-migrations}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このセクションは、[Elasticsearchのインテグレーション](../integration/advanced_search/elasticsearch.md)を有効にしている場合にのみ適用されます。メジャーリリースでは、メジャーバージョンのアップグレード前に、現在のバージョンで最新のマイナーリリースからすべての[高度な検索の移行](../integration/advanced_search/elasticsearch.md#advanced-search-migrations)を完了する必要があります。保留中の移行は、次のコマンドを実行すると見つかります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:elastic:list_pending_migrations
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:elastic:list_pending_migrations
```

{{< /tab >}}

{{< /tabs >}}

アップグレードパスが長く、保留中の移行が多い場合は、`Requeue indexing workers`と`Number of shards for non-code indexing`を設定して、インデックス作成を高速化することをおすすめします。もう1つのオプションは、保留中の移行を無視し、GitLabをターゲットバージョンにアップグレードした後で[インスタンスのインデックスを再作成](../integration/advanced_search/elasticsearch.md#index-the-instance)することです。このプロセス中に、[`Search with Elasticsearch enabled`](../integration/advanced_search/elasticsearch.md#advanced-search-configuration)設定で高度な検索を無効にすることもできます。

{{< alert type="warning" >}}

大規模なインスタンスのインデックス作成にはリスクが伴います。詳細については、[大規模なインスタンスのインデックスを効率的に作成する](../integration/advanced_search/elasticsearch.md#index-large-instances-efficiently)を参照してください。

{{< /alert >}}
