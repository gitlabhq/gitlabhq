---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 直接移行のトラブルシューティング
description: "GitLabの直接移行に関するトラブルシューティングについて、Railsコンソールコマンド、エラー解決策、および設定のヒントを提供します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)で、グループのインポート試行の失敗またはエラーメッセージを見つけることができます:

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

[APIエンドポイント](../../../api/bulk_imports.md#list-all-group-or-project-migration-entities)を使用して、関連する失敗を含むすべての移行済みエンティティも表示できます。

## 移行が遅い、またはタイムアウトする {#migrations-are-slow-or-timing-out}

移行中に処理が非常に遅い、または[タイムアウト](../../../administration/instance_limits.md#direct-transfer-migration)が発生する場合は、移行期間を短縮するためにこれらの戦略を使用してください。

### 移行先インスタンスにSidekiqワーカーを追加する {#add-sidekiq-workers-to-the-destination-instance}

GitLabのSelf-Managedインスタンスに移行する場合、移行を高速化するために、宛先インスタンスにSidekiqワーカーを追加できます。Sidekiqワーカーの数を増やす際には、以下を考慮する必要があります:

- 単一の直接移行では、宛先インスタンスで利用可能なSidekiqワーカーの数にかかわらず、一度に5つのグループまたはプロジェクトを移行することができます。
- 宛先インスタンスは、より多くの並行処理ジョブを処理できる能力が必要です。その場合、Sidekiqワーカーを増やすことで、各グループまたはプロジェクトをインポートするのにかかる時間を短縮できます。

宛先インスタンスにSidekiqワーカーを追加する方法の詳細については、[インポート用のSidekiq設定](../../../administration/sidekiq/configuration_for_imports.md)を参照してください。

### 個別の移行を開始する {#start-separate-migrations}

ソースインスタンスに5つのグループを並行してエクスポートするリソースがない場合、遅延や潜在的なタイムアウトが発生する可能性があります。ソースインスタンスのリソースが不足している場合、宛先インスタンスはエクスポートされたデータが利用可能になるまで待機する必要があります。

並行エクスポートによって引き起こされる遅延を減らすために、すべてのグループとプロジェクトを同時に行うのではなく、各グループに対して個別の移行を開始してください。GitLab UIはトップレベルグループのみを移行できるため、APIを使用してサブグループ内のプロジェクトを移行する必要がある場合があります。

## 古いインポート {#stale-imports}

ソースまたは宛先インスタンスの問題により、移行が停止したり、`timeout`ステータスで終了したりする可能性があります。これらの問題を解決するには、ソースインスタンスと宛先インスタンスの両方からログを検査してください。

### ソースインスタンス {#source-instance}

ソースインスタンスでは、古いインポートは過剰なメモリ使用量が原因であることが多く、これによりSidekiqプロセスが再起動され、エクスポートジョブが中断される可能性があります。宛先インスタンスは、エクスポートファイルが準備できるまで待機し、最終的に移行がタイムアウトする可能性があります。

リレーションが正常にエクスポートされたかどうかを確認するには、[グループ](../../../api/group_relations_export.md#export-status)または[プロジェクト](../../../api/project_relations_export.md#export-status)のリレーションをチェックし、次のコマンドを実行します:

```shell
curl --request GET --location "https://example.gitlab.com/api/v4/projects/:ID/export_relations/status" \
--header "PRIVATE-TOKEN: <your_access_token>"
```

リレーションのステータスが`1`以外の場合、そのリレーションは正常にエクスポートされなかったことを意味し、問題はソースインスタンスにあります。

中断されたエクスポートジョブを検索するために、次のコマンドを実行することもできます。Sidekiqログは再起動後にローテーションされる可能性があるため、ローテーションされたログも必ず確認してください。

```shell
grep `BulkImports::RelationBatchExportWorker` sidekiq.log | grep "interrupted_count"
```

Sidekiqの再起動が問題を引き起こしている場合:

- エクスポートジョブ用に個別のSidekiqプロセスを設定します。詳細については、[インポート用のSidekiq設定](../../../administration/sidekiq/configuration_for_imports.md)を参照してください。問題が解決しない場合は、Sidekiqの並行処理を減らして、同時に処理されるジョブの数を制限してください。
- Sidekiqのメモリ制限を増やす: お使いのインスタンスに利用可能なメモリがある場合、Sidekiqプロセスの[最大RSS制限を増やしてください](../../../administration/sidekiq/sidekiq_memory_killer.md#configuring-the-limits)。例えば、頻繁な再起動を防ぐために、制限を2 GBから3 GBに増やすことができます。
- 最大中断数を増やす: ジョブが失敗する前により多くの中断を許可するには、[`BulkImports::RelationBatchExportWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/b8e11d267cdd4a00807984f98a9d8d8cfa51602e/app/workers/bulk_imports/relation_batch_export_worker.rb#L4)の最大中断数を増やすことができます:

  1. 制限を`20`に増やすには、次の設定を追加します（デフォルト値は`3`です）:

     ```ruby
     sidekiq_options max_retries_after_interruption: 20
     ```

  1. 変更を有効にするにはSidekiqを再起動してください。

これで、新しい移行をトリガーするか、[プロジェクトリレーションエクスポートAPI](../../../api/project_relations_export.md#schedule-new-export)を使用して手動でエクスポートをトリガーすることができます。リレーションが正常にエクスポートされているかどうかを確認するには、[エクスポートステータス](../../../api/project_relations_export.md#export-status)を確認してください。

例えば、特定のプロジェクトのエクスポートをトリガーするには、次のコマンドを実行します:

```shell
curl --request POST --location "https://example.gitlab.com/api/v4/projects/:ID/export_relations" \
--header "PRIVATE-TOKEN: <your_access_token>" \
--form 'batched="true"'
```

### 宛先インスタンス {#destination-instance}

まれに、宛先インスタンスがグループまたはプロジェクトの移行に正常に失敗する場合があります。詳細については、[イシュー498720](https://gitlab.com/gitlab-org/gitlab/-/issues/498720)を参照してください。

この問題を解決するには、[インポートAPI](../../../api/import.md)を使用して、失敗したグループまたはプロジェクトを移行します。このAPIを使用すると、特定のグループとプロジェクトを個別に移行することができます。

## エラー: `404 Group Not Found` {#error-404-group-not-found}

数字のみで構成されるパスを持つグループをインポートしようとすると（例：`5000`）、GitLabはパスではなくIDでグループを検索しようとします。これは、GitLab 15.4と以前のバージョンで`404 Group Not Found`エラーを引き起こします。

これを解決するには、次のいずれかの方法を使用して、ソースグループのパスを非数値文字を含むように変更する必要があります:

- GitLab UI:

  1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
  1. **設定** > **一般**を選択します。
  1. **高度な設定**を展開します。
  1. **グループのURLの変更**で、グループのURLを非数値文字を含むように変更してください。

- [グループAPI](../../../api/groups.md#update-group-attributes)。

## その他の`404`エラー {#other-404-errors}

グループをインポートする際に、その他の`404`エラーが発生する場合があります。例:

```json
"exception_message": "Unsuccessful response 404 from [FILTERED] Bo...",
"exception_class": "BulkImports::NetworkError",
```

このエラーは、ソースインスタンスからの転送中に問題が発生したことを示しています。これを解決するには、ソースインスタンスで[前提条件](direct_transfer_migrations.md#prerequisites)が満たされていることを確認してください。

## グループまたはプロジェクトのパス名が一致しない {#mismatched-group-or-project-path-names}

ソースグループまたはプロジェクトのパスが[命名規則](../../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)に準拠していない場合、そのパスは有効であることを保証するために正規化されます。例えば、`Destination-Project-Path`は`destination-project-path`に正規化されます。

## エラー: `command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]` {#error-command-exited-with-error-code-15-and-unable-to-save-filtered-into-filtered}

直接転送を使用してプロジェクトを移行する際に、ログに`command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]`エラーが表示されることがあります。このエラーが表示された場合、安全に無視できます。GitLabは終了したコマンドを再試行します。

## エラー: `Batch export [batch_number] from source instance failed` {#error-batch-export-batch_number-from-source-instance-failed}

宛先インスタンスで、次のエラーが発生する可能性があります:

```plaintext
Batch export [batch_number] from source instance failed: [source instance error]
```

このエラーは、ソースインスタンスが一部のレコードのエクスポートに失敗した場合に発生します。最も一般的な理由は次のとおりです:

- ディスク容量の不足
- メモリ不足によるSidekiqジョブの複数回の中断
- データベースステートメントのタイムアウト

この問題を解決するには、次の手順に従います:

1. ソースインスタンスで問題を特定し、修正します。
1. 宛先インスタンスから部分的にインポートされたプロジェクトまたはグループを削除し、新しいインポートを開始します。

エクスポートに失敗したリレーションとバッチの詳細については、ソースインスタンスの[プロジェクト](../../../api/project_relations_export.md#export-status)および[グループ](../../../api/group_relations_export.md#export-status)のエクスポートステータスAPIエンドポイントを使用してください。

## エラー: `duplicate key value violates unique constraint` {#error-duplicate-key-value-violates-unique-constraint}

レコードをインポートする際に、次のエラーが表示されることがあります:

```plaintext
PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint
```

このエラーは、次の場合に発生する可能性があります:

- 高いメモリまたはCPU使用量により、インポートを処理中のSidekiqワーカーが再起動した場合。インポート中のSidekiqリソース問題を軽減するには:
  - [インポート用のSidekiq設定](../../../administration/sidekiq/configuration_for_imports.md)を最適化します。
  - `bulk_import_concurrent_pipeline_batch_limit` [アプリケーション設定](../../../api/settings.md)で、並行処理ジョブの数を制限します。
- [異なるソースグループのグループまたはプロジェクトを単一の宛先グループに統合](_index.md#known-issues)している場合。異なるソースグループのエピックが同じ内部IDを持つ場合（単一グループ内で一意である）、それらを単一の宛先グループにインポートすると競合が発生します。この競合により、`index_issues_on_namespace_id_iid_unique`または`index_epics_on_group_id_and_iid`を参照する`PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint`エラーが発生します。

## エラー: `BulkImports::FileDownloadService::ServiceError Invalid content type` {#error-bulkimportsfiledownloadserviceserviceerror-invalid-content-type}

GitLabインスタンス間で直接転送を使用すると、次のエラーが発生する可能性があります:

```plaintext
BulkImports::FileDownloadService::ServiceError Invalid content type
```

このエラーは、インスタンス間のネットワークトラフィックのルーティング方法に関連しています。`application/gzip`以外のコンテンツタイプが返された場合、ネットワークリクエストがGitLab Workhorseをバイパスしている可能性があります。

この問題を解決するには、次の手順に従います:

- お使いのIngressが、`8181`ポートでGitLab Workhorseを介してトラフィックをルーティングするように設定されていることを確認してください。Pumaに直接ルーティングされていないことを確認してください。
- オブジェクトストレージの[プロキシダウンロード](../../../administration/object_storage.md#proxy-download)を有効にすることを検討してください。

## `(imported-xx-datetime)`が付加されたマイルストーンのタイトル {#milestone-titles-appended-with-imported-xx-datetime}

グループをインポートする際、宛先ネームスペース内の既存のタイトルとグループおよびプロジェクトのマイルストーンタイトルが[競合する場合](../../../user/project/milestones/_index.md#milestone-title-rules)、インポートされたマイルストーンのタイトルには一意のサフィックスが付加されます。例: `18.0 (imported-3d-1770206299)`。

これらのマイルストーンを特定するには、宛先インスタンス上の`log/importer.log`ファイルを検索して、以下を探してください:

```plaintext
Updating milestone title - source title used by existing group or project milestone
```

ログエントリには以下が含まれます:

- `importable_id`: インポートされているグループのID。
- `milestone_title`: 名前が変更されているマイルストーンのタイトル。
- `existing_group_id`または`existing_project_id`: 既存のマイルストーンを含むグループまたはプロジェクトのID。

この情報を使用して、マイルストーンを見つけ、好みに合わせてタイトルを更新できます。
