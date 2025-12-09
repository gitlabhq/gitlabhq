---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ダイレクト移行のトラブルシューティング
description: "Railsコンソールコマンド、エラー解決策、および設定のヒントを使用した、GitLabダイレクト移行のトラブルシューティング。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)で、グループインポートの試行に関する失敗またはエラーメッセージを検索できます:

```ruby
# Get relevant import records
import = BulkImports::Entity.where(namespace_id: Group.id).map(&:bulk_import).last

# Alternative lookup by user
import = BulkImport.where(user_id: User.find(...)).last

# Get list of import entities. Each entity represents either a group or a project
entities = import.entities

# Get a list of entity failures
entities.map(&:failures).flatten

# Alternative failure lookup by status
entities.where(status: [-1]).pluck(:destination_name, :destination_namespace, :status)
```

また、[APIエンドポイント](../../../api/bulk_imports.md#list-all-group-or-project-migrations-entities)を使用して、移行されたすべてのエンティティとそれらに関連する失敗を確認できます。

## Staleインポート {#stale-imports}

移行は、ソースまたは宛先インスタンスの問題により、`timeout`ステータスでタイムアウトまたは終了する可能性があります。これらの問題を解決するには、ソースと宛先の両方のインスタンスからログを調べます。

### ソースインスタンス {#source-instance}

ソースインスタンスでは、古いインポートは、過度のメモリ使用量が原因であることが多く、これによりSidekiqプロセスが再起動され、エクスポートジョブが中断される可能性があります。宛先インスタンスは、移行が最終的にタイムアウトするまで、エクスポートファイルを待機する場合があります。

[グループ](../../../api/group_relations_export.md#export-status)または[プロジェクト](../../../api/project_relations_export.md#export-status)リレーションが正常にエクスポートされたかどうかを確認するには、次のコマンドを実行します:

```shell
curl --request GET --location "https://example.gitlab.com/api/v4/projects/:ID/export_relations/status" \
--header "PRIVATE-TOKEN: <your_access_token>"
```

リレーションのステータスが`1`以外の場合、リレーションは正常にエクスポートされず、問題はソースインスタンスにあります。

次のコマンドを実行して、中断されたエクスポートジョブを検索することもできます。Sidekiqのログは再起動後にローテーションされる可能性があるため、ローテーションされたログも必ず確認してください。

```shell
grep `BulkImports::RelationBatchExportWorker` sidekiq.log | grep "interrupted_count"
```

Sidekiqの再起動が問題の原因である場合:

- エクスポートジョブ用に個別のSidekiqプロセスを設定します。詳細については、[Sidekiqの設定](../../project/import/_index.md#sidekiq-configuration)を参照してください。問題が解決しない場合は、Sidekiqの並行処理を減らして、同時に処理されるジョブの数を制限します。
- Sidekiqのメモリ使用量制限を増やします: インスタンスで使用可能なメモリ使用量がある場合は、Sidekiqプロセスの[最大RSS制限を増やします](../../../administration/sidekiq/sidekiq_memory_killer.md#configuring-the-limits)。たとえば、頻繁な再起動を防ぐために、制限を2 GBから3 GBに増やすことができます。
- 最大中断回数を増やします: ジョブが失敗する前により多くの中断を許可するには、[`BulkImports::RelationBatchExportWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/b8e11d267cdd4a00807984f98a9d8d8cfa51602e/app/workers/bulk_imports/relation_batch_export_worker.rb#L4)の最大中断回数を増やすことができます:

  1. 制限を`20`に増やすには、次の設定を追加します（デフォルト値は`3`です）:

     ```ruby
     sidekiq_options max_retries_after_interruption: 20
     ```

  1. 変更を有効にするには、Sidekiqを再起動します。

新しい移行をトリガーするか、[リレーションエクスポートAPI](../../../api/project_relations_export.md#schedule-new-export)を使用して、エクスポートを手動でトリガーできます。リレーションが正常にエクスポートされているかどうかを確認するには、[エクスポートステータス](../../../api/project_relations_export.md#export-status)を確認してください。

たとえば、特定のプロジェクトのエクスポートをトリガーするには、次のコマンドを実行します:

```shell
curl --request POST --location "https://example.gitlab.com/api/v4/projects/:ID/export_relations" \
--header "PRIVATE-TOKEN: <your_access_token>" \
--form 'batched="true"'
```

### 宛先インスタンス {#destination-instance}

まれに、宛先インスタンスがグループまたはプロジェクトの移行に失敗する可能性があります。詳細については、[issue 498720](https://gitlab.com/gitlab-org/gitlab/-/issues/498720)を参照してください。

この問題を解決するには、[インポートAPI](../../../api/import.md)を使用して、失敗したグループまたはプロジェクトを移行します。このAPIを使用すると、特定のグループとプロジェクトを個別に移行できます。

## エラー: `404 Group Not Found` {#error-404-group-not-found}

（たとえば、`5000`）数値のみで構成されるパスを持つグループをインポートしようとすると、GitLabはパスの代わりにIDでグループを検索しようとします。これにより、GitLab 15.4以前に`404 Group Not Found`エラーが発生します。

これを解決するには、次のいずれかを使用して、数値以外の文字を含めるようにソースグループパスを変更する必要があります:

- GitLab UIを使用します:

  1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
  1. **設定** > **一般**を選択します。
  1. **高度な設定**を展開します。
  1. **グループのURLの変更**で、数値以外の文字を含めるようにグループのURLを変更します。

- [グループAPI](../../../api/groups.md#update-group-attributes)。

## その他の`404`エラー {#other-404-errors}

グループをインポートするときに、他の`404`エラーが発生する可能性があります。例:

```json
"exception_message": "Unsuccessful response 404 from [FILTERED] Bo...",
"exception_class": "BulkImports::NetworkError",
```

このエラーは、ソースインスタンスからの転送の問題を示しています。これを解決するには、ソースインスタンスの[前提条件](direct_transfer_migrations.md#prerequisites)を満たしていることを確認してください。

## グループまたはプロジェクトのパス名が一致しません {#mismatched-group-or-project-path-names}

ソースグループまたはプロジェクトのパスが[命名規則](../../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)に準拠していない場合、パスは正規化され、有効であることが保証されます。たとえば、`Destination-Project-Path`は`destination-project-path`に正規化されます。

## エラー: `command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]` {#error-command-exited-with-error-code-15-and-unable-to-save-filtered-into-filtered}

ダイレクトトランスファーを使用してプロジェクトを移行すると、ログにエラー`command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]`が表示される場合があります。このエラーが表示された場合は、無視しても問題ありません。GitLabは、終了したコマンドを再試行します。

## エラー: `Batch export [batch_number] from source instance failed` {#error-batch-export-batch_number-from-source-instance-failed}

宛先インスタンスで、次のエラーが発生する可能性があります:

```plaintext
Batch export [batch_number] from source instance failed: [source instance error]
```

このエラーは、ソースインスタンスが一部のレコードのエクスポートに失敗した場合に発生します。最も一般的な理由は次のとおりです:

- ディスク容量の不足
- メモリ使用量の不足によるSidekiqジョブの複数の中断
- データベースステートメントのタイムアウト

この問題を解決するには、以下を実行します:

1. ソースインスタンスの問題を特定して修正します。
1. インポートが部分的に実行されたプロジェクトまたはグループを宛先インスタンスから削除し、新しいインポートを開始します。

エクスポートに失敗したリレーションとバッチの詳細については、ソースインスタンスの[プロジェクト](../../../api/project_relations_export.md#export-status)および[グループ](../../../api/group_relations_export.md#export-status)のエクスポートステータスAPIエンドポイントを使用してください。

## エラー: `duplicate key value violates unique constraint` {#error-duplicate-key-value-violates-unique-constraint}

レコードをインポートすると、次のエラーが発生する場合があります:

```plaintext
PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint
```

このエラーは、インポート中にメモリ使用量またはCPU使用率が高いために、インポートを処理するSidekiqワーカーが再起動すると発生する可能性があります。

インポート中のSidekiqメモリ使用量またはCPUの問題を軽減するには:

- インポート用に[Sidekiqの設定](../../project/import/_index.md#sidekiq-configuration)を最適化します。
- `bulk_import_concurrent_pipeline_batch_limit` [アプリケーション設定](../../../api/settings.md)で、同時実行ジョブの数を制限します。

## エラー: `BulkImports::FileDownloadService::ServiceError Invalid content type` {#error-bulkimportsfiledownloadserviceserviceerror-invalid-content-type}

GitLabインスタンス間でダイレクト転送を使用する場合、次のエラーが発生する可能性があります:

```plaintext
BulkImports::FileDownloadService::ServiceError Invalid content type
```

このエラーは、インスタンス間でネットワークトラフィックがどのようにルーティングされるかに関連しています。`application/gzip`以外のコンテンツタイプが返された場合、ネットワークリクエストがGitLab Workhorseを回避する可能性があります。

この問題を解決するには、以下を実行します:

- Ingressが、Pumaに直接ではなく、ポート`8181`のGitLab Workhorseを介してトラフィックをルーティングするように設定されていることを確認してください。
- オブジェクトストレージの[プロキシダウンロード](../../../administration/object_storage.md#proxy-download)を有効にすることを検討してください。
