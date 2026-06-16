---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ダイレクト転送移行のトラブルシューティング
description: "GitLabダイレクト転送移行のRailsコンソールコマンド、エラー解決策、および設定のヒントに関するトラブルシューティングです。"
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

[APIエンドポイント](../../../api/bulk_imports.md#list-all-group-or-project-migration-entities)を使用すると、関連する失敗のあるすべての移行済みエンティティも確認できます。

## 移行が遅いか、タイムアウトしている {#migrations-are-slow-or-timing-out}

非常に遅い移行または[タイムアウト](../../../administration/instance_limits.md#direct-transfer-migration)が発生している場合は、これらの戦略を使用して移行期間を短縮してください。

### 移行先インスタンスにSidekiqワーカーを追加する {#add-sidekiq-workers-to-the-destination-instance}

GitLab Self-Managedインスタンスに移行する場合、移行を高速化するために、宛先インスタンスにSidekiqワーカーを追加できます。Sidekiqワーカーの数を増やす場合、次の点を考慮する必要があります:

- 単一のダイレクト転送移行は、宛先インスタンスで利用可能なSidekiqワーカーの数に関係なく、一度に5つのグループまたはプロジェクトを移行します。
- 宛先インスタンスには、より多くの同時ジョブを処理する能力が必要です。もしそうなら、より多くのSidekiqワーカーを追加すると、各グループまたはプロジェクトをインポートするのにかかる時間を短縮できます。

宛先インスタンスにSidekiqワーカーを追加する方法の詳細については、[インポート用のSidekiq設定](../../../administration/sidekiq/configuration_for_imports.md)を参照してください。

### 個別の移行を開始する {#start-separate-migrations}

ソースインスタンスが5つのグループを並行してエクスポートするリソースを持っていない場合、遅延や潜在的なタイムアウトが発生する可能性があります。ソースインスタンスのリソースが不足している場合、宛先インスタンスはエクスポートされたデータが利用可能になるまで待機する必要があります。

並行エクスポートによって引き起こされる遅延を軽減するため、すべてのグループとプロジェクトを同時に行うのではなく、各グループに対して個別の移行を開始してください。GitLab UIはトップレベルグループのみを移行できるため、APIを使用してサブグループ内のプロジェクトを移行する必要がある場合があります。

## 古いインポート {#stale-imports}

移行は、ソースまたは宛先インスタンスの問題により、停止するか`timeout`ステータスで完了する可能性があります。これらの問題を解決するには、ソースインスタンスと宛先インスタンスの両方からログを検査してください。

### ソースインスタンス {#source-instance}

ソースインスタンスでは、古いインポートは、Sidekiqプロセスを再起動し、エクスポートジョブを中断する可能性のある過剰なメモリ使用が原因であることがよくあります。宛先インスタンスは、移行が最終的にタイムアウトするまで、エクスポートファイルを待機する可能性があります。

[グループ](../../../api/group_relations_export.md#retrieve-the-status-of-an-export)または[プロジェクト](../../../api/project_relations_export.md#retrieve-the-status-of-an-export)のリレーションが正常にエクスポートされたかを確認するには、次のコマンドを実行します:

```shell
curl --request GET --location "https://example.gitlab.com/api/v4/projects/:ID/export_relations/status" \
--header "PRIVATE-TOKEN: <your_access_token>"
```

{{< glossary-tooltip text="リレーション" >}}が`1`以外のステータスの場合、そのリレーションは正常にエクスポートされず、問題はソースインスタンスにあります。

中断されたエクスポートジョブを検索するには、次のコマンドを実行することもできます。Sidekiqログは再起動後にローテーションされる可能性があるため、ローテーションされたログも確認するようにしてください。

```shell
grep `BulkImports::RelationBatchExportWorker` sidekiq.log | grep "interrupted_count"
```

Sidekiqの再起動が問題を引き起こしている場合:

- エクスポートジョブ用に個別のSidekiqプロセスを設定します。詳細については、[インポート用のSidekiq設定](../../../administration/sidekiq/configuration_for_imports.md)を参照してください。問題が解決しない場合は、Sidekiqの並行処理を減らして、同時に処理されるジョブの数を制限してください。
- Sidekiqメモリ制限を増やします: お使いのインスタンスに利用可能なメモリがある場合、Sidekiqプロセスの[最大RSS制限を増やす](../../../administration/sidekiq/sidekiq_memory_killer.md#configuring-the-limits)ことができます。例えば、頻繁な再起動を防ぐために、制限を2 GBから3 GBに増やすことができます。
- 最大中断回数を増やします: ジョブが失敗する前により多くの中断を許可するには、[`BulkImports::RelationBatchExportWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/b8e11d267cdd4a00807984f98a9d8d8cfa51602e/app/workers/bulk_imports/relation_batch_export_worker.rb#L4)の最大中断回数を増やすことができます:

  1. 制限を`20`に増やすには、次の設定を追加します（デフォルト値は`3`です）:

     ```ruby
     sidekiq_options max_retries_after_interruption: 20
     ```

  1. 変更を有効にするため、Sidekiqを再起動します。

これで、新しい移行をトリガーするか、[プロジェクトリレーションエクスポートAPI](../../../api/project_relations_export.md#schedule-a-new-export-for-a-project)を使用して手動でエクスポートをトリガーすることができます。リレーションが正常にエクスポートされているかを確認するには、[エクスポートステータス](../../../api/project_relations_export.md#retrieve-the-status-of-an-export)を確認してください。

例えば、特定のプロジェクトのエクスポートをトリガーするには、次のコマンドを実行します:

```shell
curl --request POST --location "https://example.gitlab.com/api/v4/projects/:ID/export_relations" \
--header "PRIVATE-TOKEN: <your_access_token>" \
--form 'batched="true"'
```

### 宛先インスタンス {#destination-instance}

まれに、宛先インスタンスがグループまたはプロジェクトの移行に失敗する可能性があります。詳細については、[イシュー498720](https://gitlab.com/gitlab-org/gitlab/-/issues/498720)を参照してください。

この問題を解決するには、[インポートAPI](../../../api/import.md)を使用して、失敗したグループまたはプロジェクトを移行します。このAPIを使用すると、特定のグループやプロジェクトを個別に移行できます。

## エラー: `404 Group Not Found` {#error-404-group-not-found}

数字のみで構成されるパス（例: `5000`）を持つグループをインポートしようとすると、GitLabはパスではなくIDでグループを検索しようとします。これにより、GitLab 15.4および以前では`404 Group Not Found`エラーが発生します。

これを解決するには、次のいずれかを使用してソースグループのパスを非数値文字を含むように変更する必要があります:

- GitLab UI:

  1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
  1. **設定** > **一般**を選択します。
  1. **高度な設定**を展開します。
  1. **グループのURLの変更**の下で、グループのURLを非数値文字を含むように変更します。

- [グループAPI](../../../api/groups.md#update-group-attributes)。

## その他の`404`エラー {#other-404-errors}

グループをインポートする際に、その他の`404`エラーを受け取る可能性があります。例えば:

```json
"exception_message": "Unsuccessful response 404 from [FILTERED] Bo...",
"exception_class": "BulkImports::NetworkError",
```

このエラーは、ソースインスタンスからの転送に関する問題を示しています。これを解決するには、ソースインスタンスで[前提条件](direct_transfer_migrations.md#prerequisites)を満たしていることを確認してください。

## 不一致のグループまたはプロジェクトのパス名 {#mismatched-group-or-project-path-names}

ソースグループまたはプロジェクトのパスが[命名規則](../../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)に準拠していない場合、そのパスが有効であることを確認するために正規化されます。例えば、`Destination-Project-Path`は`destination-project-path`に正規化されます。

## エラー: `command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]` {#error-command-exited-with-error-code-15-and-unable-to-save-filtered-into-filtered}

ダイレクト転送を使用してプロジェクトを移行する際に、ログで`command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]`エラーを受け取る可能性があります。このエラーを受け取った場合、安全に無視できます。GitLabは終了したコマンドを再試行します。

## エラー: `Batch export [batch_number] from source instance failed` {#error-batch-export-batch_number-from-source-instance-failed}

宛先インスタンスで、次のエラーが発生する可能性があります:

```plaintext
Batch export [batch_number] from source instance failed: [source instance error]
```

このエラーは、ソースインスタンスが一部のレコードのエクスポートに失敗した場合に発生します。最も一般的な理由は次のとおりです:

- ディスク容量不足
- メモリ不足によるSidekiqジョブの複数の中断
- データベースステートメントタイムアウト

この問題を解決するには、次の手順に従います:

1. ソースインスタンスで問題を特定して修正します。
1. 部分的にインポートされたプロジェクトまたはグループを宛先インスタンスから削除し、新しいインポートを開始します。

エクスポートに失敗したリレーションとバッチの詳細については、ソースインスタンスで[プロジェクト](../../../api/project_relations_export.md#retrieve-the-status-of-an-export)と[グループ](../../../api/group_relations_export.md#retrieve-the-status-of-an-export)のエクスポートステータスAPIエンドポイントを使用してください。

## エラー: `duplicate key value violates unique constraint` {#error-duplicate-key-value-violates-unique-constraint}

レコードをインポートする際、次のエラーが発生する可能性があります:

```plaintext
PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint
```

このエラーは次の場合に発生する可能性があります:

- インポートを処理中のSidekiqワーカーが、高いメモリまたはCPU使用率のために再起動した場合。インポート中のSidekiqのリソース問題を軽減するには:
  - [インポート用のSidekiq設定](../../../administration/sidekiq/configuration_for_imports.md)を最適化します。
  - `bulk_import_concurrent_pipeline_batch_limit` [アプリケーション設定](../../../api/settings.md)で、同時ジョブの数を制限します。
- 異なるソースグループから単一の宛先グループに、グループまたはプロジェクトを[統合](_index.md#known-issues)しています。異なるソースグループからのエピックが同じ内部ID（単一グループ内で一意）を持っている場合、それらを単一の宛先グループにインポートすると競合が発生します。この競合により、`index_issues_on_namespace_id_iid_unique`または`index_epics_on_group_id_and_iid`を参照する`PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint`エラーが発生します。

## エラー: `Import::BulkImports::FileDownloadStrategy::ServiceError Invalid content type` {#error-importbulkimportsfiledownloadstrategyserviceerror-invalid-content-type}

GitLabインスタンス間でダイレクト転送を使用する場合、次のエラーが発生する可能性があります:

```plaintext
Import::BulkImports::FileDownloadStrategy::ServiceError Invalid content type
```

このエラーは、インスタンス間でネットワークトラフィックがルーティングされる方法に関連しています。`application/gzip`以外のコンテンツタイプが返された場合、ネットワークリクエストがGitLab Workhorseをバイパスしている可能性があります。

この問題を解決するには、次の手順に従います:

- お使いのIngressが、GitLab Workhorseを介して`8181`ポートでトラフィックをルーティングするように設定されていること、Pumaに直接ではないことを確認してください。
- オブジェクトストレージの[プロキシダウンロード](../../../administration/object_storage.md#proxy-download)を有効にすることを検討してください。

## マイルストーンのタイトルに`(imported-xx-datetime)`が付加された {#milestone-titles-appended-with-imported-xx-datetime}

グループをインポートする際、宛先ネームスペースでグループおよびプロジェクトのマイルストーンタイトルが[既存のタイトルと競合](../../project/milestones/_index.md#milestone-title-rules)する場合、インポートされたマイルストーンには、タイトルに一意のサフィックスが付加されます。例: `18.0 (imported-3d-1770206299)`。

これらのマイルストーンを特定するには、宛先インスタンスで`log/importer.log`ファイルを検索して、次のものを見つけてください:

```plaintext
Updating milestone title - source title used by existing group or project milestone
```

ログエントリには以下が含まれます:

- `importable_id`: インポートされているグループのID。
- `milestone_title`: 名前が変更されているマイルストーンのタイトル。
- `existing_group_id`または`existing_project_id`: 既存のマイルストーンを含むグループまたはプロジェクトのID。

この情報を使用して、マイルストーンを特定し、好みに合わせてタイトルを更新できます。

## エラー: `Destination belongs to a different organization than the current one` {#error-destination-belongs-to-a-different-organization-than-the-current-one}

ソースと宛先のネームスペースが異なる組織に属し、どちらかの組織が隔離済みとしてマークされている場合、ダイレクト転送による移行は失敗します。

このエラーを解決するには、現在の組織に属する宛先ネームスペースに移行してください。詳細については、[イシュー595674](https://gitlab.com/gitlab-org/gitlab/-/issues/595674)を参照してください。
