---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: トラブルシューティング
---

{{< details >}}

プラン: Free、Premium、Ultimate Offering: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabに移行する際、以下のイシューが発生する可能性があります。

## インポートされたリポジトリにブランチがない {#imported-repository-is-missing-branches}

インポートされたリポジトリにソースリポジトリのすべてのブランチが含まれていない場合:

1. [環境変数](../../administration/logs/_index.md#override-default-log-level)`IMPORT_DEBUG=true`を設定します。
1. [別のグループ、サブグループ、またはプロジェクト名](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#re-import-projects-from-external-providers)を使用してインポートを再試行します。
1. 一部のブランチがまだ見つからない場合は、[`importer.log`](../../administration/logs/_index.md#importerlog)（たとえば、[`jq`](../../administration/logs/log_parsing.md#parsing-gitlab-railsimporterlog)を使用）を調べます。

## 例外: `Error Importing repository - No such file or directory @ rb_sysopen - (filename)` {#exception-error-importing-repository---no-such-file-or-directory--rb_sysopen---filename}

このエラーは、リポジトリのソースコードの`tar.gz`ファイルダウンロードをインポートしようとすると発生します。

インポートには、単なるリポジトリのダウンロードファイルではなく、[GitLabエクスポート](../project/settings/import_export.md#export-a-project-and-its-data)ファイルが必要です。

## 長期化または失敗したインポートを診断する {#diagnosing-prolonged-or-failed-imports}

ファイルベースのインポート（特にS3を使用するインポート）で長期の遅延やエラーが発生している場合は、次の方法で問題の根本原因を特定できる可能性があります。

- [インポート手順の確認](#check-import-status)
- [ログのレビュー](#review-logs)
- [一般的なイシューの特定](#identify-common-issues)

### インポート状態を確認する {#check-import-status}

インポート状態を確認します。

1. GitLab APIを使用して、影響を受けるプロジェクトの[インポート状態](../../api/project_import_export.md#import-status)を確認します。
1. 特に`status`値と`import_error`値について、エラーメッセージまたは状態情報に対する応答をレビューします。
1. 応答の`correlation_id`に注意してください。これは、さらなるトラブルシューティングに不可欠です。

### ログをレビューする {#review-logs}

関連情報についてログを検索します。

GitLab Self-Managedインスタンスの場合:

1. [Sidekiqログ](../../administration/logs/_index.md#sidekiqlog)と[`exceptions_json`ログ](../../administration/logs/_index.md#exceptions_jsonlog)を確認します。
1. `RepositoryImportWorker`および[インポート状態の確認](#check-import-status)からの相関IDに関連するエントリを検索します。
1. `job_status`、`interrupted_count`、`exception`などのフィールドを探します。

GitLab.comの場合（GitLabチームメンバーのみ）:

1. [Kibana](https://log.gprd.gitlab.net/)を使用して、次のようなクエリでSidekiqログを検索します。

   ターゲット: `pubsub-sidekiq-inf-gprd*`

   ```plaintext
   json.class: "RepositoryImportWorker" AND json.correlation_id.keyword: "<CORRELATION_ID>"
   ```

   または

   ```plaintext
   json.class: "RepositoryImportWorker" AND json.meta.project: "<project.full_path>"
   ```

1. GitLab Self-Managedインスタンスについて言及されているのと同じフィールドを探します。

### 共通のイシューを特定する {#identify-common-issues}

[ログのレビュー](#review-logs)で収集した情報を、次の一般的なイシューと照らし合わせてレビューします。

- 中断されたジョブ: 失敗を示す高い`interrupted_count`または`job_status`が表示された場合、インポートジョブが複数回中断され、デッドキューに配置された可能性があります。
- S3接続: S3を使用するインポートの場合は、ログでS3関連のエラーメッセージを確認してください。
- 大規模リポジトリ: リポジトリが非常に大きい場合、インポートがタイムアウトになる可能性があります。この場合は、[直接転送](../group/import/_index.md)の使用を検討してください。
