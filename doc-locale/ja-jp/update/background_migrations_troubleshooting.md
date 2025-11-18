---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バックグラウンド移行のトラブルシューティング
description: バックグラウンド移行に関する問題の解決策。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

<!-- Linked from lib/gitlab/database/migrations/batched_background_migration_helpers.rb -->

## バッチ処理されたバックグラウンド移行が完了していないため、データベース移行に失敗する {#database-migrations-failing-because-of-batched-background-migration-not-finished}

GitLabバージョン14.2以降にアップデートすると、次のようなメッセージでデータベース移行が失敗する場合があります:

```plaintext
StandardError: An error has occurred, all later migrations canceled:

Expected batched background migration for the given configuration to be marked as 'finished', but it is 'active':
  {:job_class_name=>"CopyColumnUsingBackgroundMigrationJob",
   :table_name=>"push_event_payloads",
   :column_name=>"event_id",
   :job_arguments=>[["event_id"],
   ["event_id_convert_to_bigint"]]
  }
```

このエラーを解決するには:

- [14.2のバージョン固有のアップグレード手順](https://archives.docs.gitlab.com/17.3/ee/update/versions/gitlab_14_changes.html#1420)に従った場合は、[バッチ処理されたバックグラウンド移行を手動で完了](background_migrations.md#finish-a-failed-migration-manually)してください。
- これらの手順に従わなかった場合は、次のいずれかの操作を行う必要があります:
  - 14.2以降にアップデートする前に、必須バージョンのいずれかを[ロールバックしてアップグレード](#roll-back-and-follow-the-required-upgrade-path)します。
  - [ロールフォワード](#roll-forward-and-finish-the-migrations-on-the-upgraded-version)して、現在のバージョンに留まり、バッチ処理された移行が正常に完了することを手動で確認します。

### ロールバックして、必要なアップグレードパスに従ってください {#roll-back-and-follow-the-required-upgrade-path}

ロールバックして、必要なアップグレードパスに従うには、次の手順を実行します:

1. [以前にインストールしたバージョンをロールバックして復元する](../administration/backup_restore/_index.md)。
1. 14.2以降にアップデートする前に、14.0.5または14.1にアップデートしてください。
1. バッチ処理されたバックグラウンド移行の[ステータスを確認](background_migrations.md#check-the-status-of-batched-background-migrations)し、再度アップグレードを試みる前に、すべて完了とマークされていることを確認してください。アクティブとマークされたものが残っている場合は、[手動で完了させてください](background_migrations.md#finish-a-failed-migration-manually)。

### アップグレードされたバージョンで移行をロールフォワードして完了します {#roll-forward-and-finish-the-migrations-on-the-upgraded-version}

ロールフォワードのプロセスは、ダウンタイムが必要かどうかによって異なります。

#### ダウンタイムを伴うデプロイの場合 {#for-a-deployment-with-downtime}

すべてのバッチ処理されたバックグラウンド移行を実行すると、GitLabインスタンスのサイズによっては、かなりの時間がかかる場合があります。

1. データベース内のバッチ処理されたバックグラウンド移行の[ステータスを確認](background_migrations.md#check-the-status-of-batched-background-migrations)し、ステータスクエリが行を返さなくなるまで、適切な引数を指定して[手動で実行します](background_migrations.md#finish-a-failed-migration-manually)。
1. それらすべてのステータスが完了とマークされたら、インストールの移行を再度実行します。
1. GitLabアップグレードから[データベース移行を完了](../administration/raketasks/maintenance.md#run-incomplete-database-migrations)させます:

   ```plaintext
   sudo gitlab-rake db:migrate
   ```

1. 再構成を実行します:

   ```plaintext
   sudo gitlab-ctl reconfigure
   ```

1. インストールのアップグレードを完了させます。

#### ダウンタイムなしのデプロイの場合 {#for-a-no-downtime-deployment}

失敗している移行はデプロイ後の移行であるため、アップグレードされたバージョンの実行中のインスタンスにとどまり、バッチ処理されたバックグラウンド移行が完了するのを待つことができます。

1. エラーメッセージからバッチ処理されたバックグラウンド移行の[ステータスを確認](background_migrations.md#check-the-status-of-batched-background-migrations)し、完了としてリストされていることを確認します。移行がまだアクティブな場合は、次のいずれかを行います:
   - 完了するまで待ちます。
   - [手動で完了させる](background_migrations.md#finish-a-failed-migration-manually)。
1. インストールの移行を再度実行して、残りのデプロイ後の移行を完了させます。

## 高度な検索移行がスタックしている {#advanced-search-migrations-are-stuck}

GitLab 15.0では、`DeleteOrphanedCommit`という名前の高度な検索移行は、アップグレード全体で保留状態のままになる可能性があります。このイシューは[GitLab 15.1で修正されています](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89539)。

高度な検索でGitLab 15.0を使用しているGitLab Self-Managedのお客様は、パフォーマンスの低下が発生します。移行をクリーンアップするには、15.1以降にアップグレードしてください。

保留中の問題でスタックしている他の高度な検索移行については、[停止した移行を再試行](../integration/advanced_search/elasticsearch.md#retry-a-halted-migration)してください。

高度な検索の保留中の移行がすべて完了する前にGitLabをアップグレードすると、新しいバージョンで削除された保留中の移行は、実行または再試行されません。この場合、[インデックスをゼロから再作成する](../integration/elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index)必要があります。

## エラー: `Elasticsearch version not compatible`（コンポーネントビルドエラー: specは有効なJSONスキーマである必要があります） {#error-elasticsearch-version-not-compatible}

この問題を解決するするには、お使いのElasticsearchまたはOpenSearchのバージョンが[お使いのGitLabのバージョンと互換性がある](../integration/advanced_search/elasticsearch.md#version-requirements)ことを確認してください。
