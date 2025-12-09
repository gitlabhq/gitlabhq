---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geoの同期と検証のエラーのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`Admin > Geo > Sites`または[同期ステータスRakeタスク](common.md#sync-status-rake-task)でレプリケーションまたは検証の失敗に気付いた場合は、以下の一般的な手順で失敗を解決してみてください:

1. Geoは自動的に失敗を再試行します。失敗が新しく数が少ない場合、または根本原因がすでに解決されていると思われる場合は、失敗がなくなるまで待つことができます。
1. 失敗が長期間存在する場合、多くの再試行がすでに発生しており、自動再試行の間隔は、失敗の種類に応じて最大4時間に増加しています。根本原因がすでに解決されていると思われる場合は、[手動でレプリケーションまたは検証を再試行する](#manually-retry-replication-or-verification)ことで、待機時間を回避できます。
1. それでも失敗が解決しない場合は、次のセクションを参照して解決を試みてください。

## 手動でのレプリケーションまたは検証の再試行 {#manually-retry-replication-or-verification}

[Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)で、セカンダリGeoサイトで以下を実行できます:

- [個々のコンポーネントの手動再同期と再検証](#resync-and-reverify-individual-components)
- [複数のコンポーネントの手動再同期と再検証](#resync-and-reverify-multiple-components)

### 個々のコンポーネントの再同期と再検証 {#resync-and-reverify-individual-components}

セカンダリサイトで、**管理者** > **Geo** > **Replication**（レプリケーション）にアクセスして、個々のアイテムの再同期または再検証を強制的に実行します。

ただし、これでうまくいかない場合は、Railsコンソールを使用して同じアクションを実行できます。以下のセクションでは、[Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)で内部アプリケーションコマンドを使用して、個々のレコードのレプリケーションまたは検証を同期または非同期で実行する方法について説明します。

#### Replicatorインスタンスの取得 {#obtaining-a-replicator-instance}

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

同期または検証操作を実行する前に、Replicatorインスタンスを取得する必要があります。

まず、実行する内容に応じて、[Railsコンソールセッションを開始](../../../operations/rails_console.md#starting-a-rails-console-session)し、**プライマリ**または**セカンダリ**サイトで実行します。

**プライマリ**サイト:

- リソースのチェックサムを計算できます

**セカンダリ**サイト:

- リソースを同期できます
- リソースのチェックサムを計算し、プライマリサイトのチェックサムに対してそのチェックサムを検証できます

次に、以下のスニペットのいずれかを実行して、Replicatorインスタンスを取得します。

##### モデルレコードのIDを指定した場合 {#given-a-model-records-id}

- `123`を実際のIDに置き換えます。
- `Packages::PackageFile`を[Geoデータ型モデルクラス](#geo-data-type-model-classes)のいずれかに置き換えます。

```ruby
model_record = Packages::PackageFile.find_by(id: 123)
replicator = model_record.replicator
```

##### レジストリレコードのIDを指定した場合 {#given-a-registry-records-id}

- `432`を実際のIDに置き換えます。レジストリレコードは、追跡するモデルレコードと同じID値を持つ場合と持たない場合があります。
- `Geo::PackageFileRegistry`を[Geoレジストリクラス](#geo-registry-classes)のいずれかに置き換えます。

セカンダリGeoサイト内:

```ruby
registry_record = Geo::PackageFileRegistry.find_by(id: 432)
replicator = registry_record.replicator
```

##### レジストリレコードの`last_sync_failure`にエラーメッセージが表示された場合 {#given-an-error-message-in-a-registry-records-last_sync_failure}

- `Geo::PackageFileRegistry`を[Geoレジストリクラス](#geo-registry-classes)のいずれかに置き換えます。
- `error message here`を実際のエラーメッセージに置き換えます。

```ruby
registry = Geo::PackageFileRegistry.find_by("last_sync_failure LIKE '%error message here%'")
replicator = registry.replicator
```

##### レジストリレコードの`verification_failure`にエラーメッセージが表示された場合 {#given-an-error-message-in-a-registry-records-verification_failure}

- `Geo::PackageFileRegistry`を[Geoレジストリクラス](#geo-registry-classes)のいずれかに置き換えます。
- `error message here`を実際のエラーメッセージに置き換えます。

```ruby
registry = Geo::PackageFileRegistry.find_by("verification_failure LIKE '%error message here%'")
replicator = registry.replicator
```

#### Replicatorインスタンスを使用した操作の実行 {#performing-operations-with-a-replicator-instance}

`replicator`変数に格納されているReplicatorインスタンスがある場合、多くの操作を実行できます:

##### コンソールでの同期 {#sync-in-the-console}

このスニペットは、**セカンダリ**サイトでのみ機能します。

これにより、コンソールで同期コードが同期的に実行されるため、リソースの同期にかかる時間を観察したり、完全なエラーバック履歴を表示したりできます。

```ruby
replicator.sync
```

オプションで、コンソールのログレベルを構成済みのログレベルよりも詳細にしてから、同期を実行します:

```ruby
Rails.logger.level = :debug
```

##### コンソールでのチェックサムまたは検証 {#checksum-or-verify-in-the-console}

このスニペットは、**プライマリ**または**セカンダリ**サイトで機能します。

**プライマリ**サイトでは、リソースのチェックサムを計算し、その結果をメインのGitLabデータベースに格納します。**セカンダリ**サイトでは、リソースのチェックサムを計算し、メインのGitLabデータベース(**プライマリ**サイトによって生成される)のチェックサムと比較して、その結果をGeo追跡データベースに格納します。

これにより、コンソールでチェックサムと検証コードが同期的に実行されるため、かかる時間を観察したり、完全なエラーバック履歴を表示したりできます。

```ruby
replicator.verify
```

##### Sidekiqジョブでの同期 {#sync-in-a-sidekiq-job}

このスニペットは、**セカンダリ**サイトでのみ機能します。

リソースの[sync](#sync-in-the-console)を実行するために、Sidekiqのジョブをエンキューします。

```ruby
replicator.enqueue_sync
```

##### Sidekiqジョブでの検証 {#verify-in-a-sidekiq-job}

このスニペットは、**プライマリ**または**セカンダリ**サイトで機能します。

リソースの[チェックサムまたは検証](#checksum-or-verify-in-the-console)を実行するために、Sidekiqのジョブをエンキューします。

```ruby
replicator.verify_async
```

##### モデルレコードの取得 {#get-a-model-record}

このスニペットは、**プライマリ**または**セカンダリ**サイトで機能します。

```ruby
replicator.model_record
```

##### レジストリレコードの取得 {#get-a-registry-record}

このスニペットは、レジストリテーブルがGeo追跡DBに格納されているため、**セカンダリ**サイトでのみ機能します。

```ruby
replicator.registry
```

#### Geoデータ型モデルクラス {#geo-data-type-model-classes}

Geoデータ型は、1つ以上のGitLab機能が関連データを格納するために必要とし、Geoによってセカンダリサイトにレプリケートされるデータの特定のクラスです。

- **Blob types**（blob）型:
  - `Ci::JobArtifact`
  - `Ci::PipelineArtifact`
  - `Ci::SecureFile`
  - `LfsObject`
  - `MergeRequestDiff`
  - `Packages::PackageFile`
  - `PagesDeployment`
  - `Terraform::StateVersion`
  - `Upload`
  - `DependencyProxy::Manifest`
  - `DependencyProxy::Blob`
- **Git Repository types**（Gitリポジトリタイプ）:
  - `DesignManagement::Repository`
  - `ProjectRepository`
  - `ProjectWikiRepository`
  - `SnippetRepository`
  - `GroupWikiRepository`
- **Other types**（その他のタイプ）:
  - `ContainerRepository`

主なクラスの種類は、レジストリ、モデル、Replicatorです。これらのクラスのいずれかのインスタンスがある場合は、他のインスタンスを取得できます。レジストリとモデルは、主にPostgreSQL DBの状態を管理します。Replicatorは、PostgreSQL以外のデータ(ファイルシステム/Gitリポジトリ/コンテナリポジトリ)をレプリケートまたは検証する方法を認識します。

#### Geoレジストリクラス {#geo-registry-classes}

GitLab Geoのコンテキストでは、**registry record**（レジストリレコード）は、Geo追跡データベース内のレジストリテーブルを指します。各レコードは、LFSファイルシステムやプロジェクトGitリポジトリなど、メインのGitLabデータベース内の単一のレプリケート可能なアイテムを追跡します。クエリできるGeoレジストリテーブルに対応するRailsモデルは次のとおりです:

- **Blob types**（blob）型:
  - `Geo::CiSecureFileRegistry`
  - `Geo::DependencyProxyBlobRegistry`
  - `Geo::DependencyProxyManifestRegistry`
  - `Geo::JobArtifactRegistry`
  - `Geo::LfsObjectRegistry`
  - `Geo::MergeRequestDiffRegistry`
  - `Geo::PackageFileRegistry`
  - `Geo::PagesDeploymentRegistry`
  - `Geo::PipelineArtifactRegistry`
  - `Geo::ProjectWikiRepositoryRegistry`
  - `Geo::SnippetRepositoryRegistry`
  - `Geo::TerraformStateVersionRegistry`
  - `Geo::UploadRegistry`
- **Git Repository types**（Gitリポジトリタイプ）:
  - `Geo::DesignManagementRepositoryRegistry`
  - `Geo::ProjectRepositoryRegistry`
  - `Geo::ProjectWikiRepositoryRegistry`
  - `Geo::SnippetRepositoryRegistry`
  - `Geo::GroupWikiRepositoryRegistry`
- **Other types**（その他のタイプ）:
  - `Geo::ContainerRepositoryRegistry`

### 複数のコンポーネントの再同期と再検証 {#resync-and-reverify-multiple-components}

{{< history >}}

- GitLab 16.5で一括再同期と再検証が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/364729)されました。

{{< /history >}}

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

以下のセクションでは、[Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)で内部アプリケーションコマンドを使用して、一括レプリケーションまたは検証を行う方法について説明します。

#### 1つのコンポーネントのすべてのリソースを再同期する {#resync-all-resources-of-one-component}

UIから1つのコンポーネントのすべてのリソースの完全な再同期をスケジュールできます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. **Replication details**（レプリケーション）の詳細]で、目的のコンポーネントを選択します。
1. **すべて再同期**を選択します。

または、[Railsコンソールセッションを開始](../../../operations/rails_console.md#starting-a-rails-console-session)して**on the secondary Geo site**（セカンダリGeoサイト）で詳細な情報を収集するか、以下のスニペットを使用してこれらの操作を手動で実行します。

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

##### 同期に失敗した1つのコンポーネントのすべてのリソースを同期する {#sync-all-resources-of-one-component-that-failed-to-sync}

次のスクリプト:

- すべての失敗したリポジトリをループします。
- 最後の失敗の理由など、Geo同期および検証メタデータを表示します。
- リポジトリの再同期を試みます。
- 失敗が発生した場合、その理由を報告します。
- 完了するまでに時間がかかる場合があります。各リポジトリチェックは、結果を報告する前に完了する必要があります。セッションがタイムアウトした場合は、プロセスが`screen`セッションの開始、または[Rails Runner](../../../operations/rails_console.md#using-the-rails-runner)と`nohup`を使用した実行など、実行を継続できるように対策を講じてください。

```ruby
Geo::ProjectRepositoryRegistry.failed.find_each do |registry|
   begin
     puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Last Sync Failure: '#{registry.last_sync_failure}'"
     registry.replicator.sync
     puts "Sync initiated for registry ID: #{registry.id}"
   rescue => e
     puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Failed: '#{e}'", e.backtrace.join("\n")
   end
end; nil
```

#### すべてのサイトで1つのコンポーネントを再検証する {#reverify-one-component-on-all-sites}

**プライマリ**サイトのチェックサムが問題になっている場合は、**プライマリ**サイトにチェックサムを再計算させる必要があります。次に、**プライマリ**サイトで各チェックサムが再計算された後、すべての**セカンダリ**サイトに伝播するイベントが生成され、チェックサムが再計算され、値が比較されるため、「完全な再検証」が実現されます。不一致があると、レジストリが`sync failed`としてマークされ、同期の再試行がスケジュールされます。

UIには、完全な再検証を行うためのボタンはありません。これをシミュレートするには、**プライマリ**サイトの`Re-verification interval`を**管理者**>**Geo**>**ノード**>**編集**で1(日)に設定します。次に、**プライマリ**サイトは、1日以上前にチェックサムされたリソースのチェックサムを再計算します。

オプションで、これを手動で行うことができます:

1. **プライマリ**サイトでGitLab RailsノードにSSHで接続します。
1. [Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)を開きます。
1. `Upload`を[Geoデータ型モデルクラス](#geo-data-type-model-classes)のいずれかに置き換えて、すべてのリソースを`pending verification`としてマークします:

   ```ruby
   Upload.verification_state_table_class.each_batch do |relation|
     relation.update_all(verification_state: 0)
   end
   ```

##### プライマリサイトでチェックサムに失敗したすべてのリソースを再検証する {#reverify-all-resources-that-failed-to-checksum-on-the-primary-site}

システムは、プライマリサイトでチェックサムに失敗したすべてのリソースを自動的に再検証しますが、過剰な量の障害を回避するために、段階的なバックオフスキームを使用します。

オプションで、たとえば試行された介入を完了した場合は、再検証をより早く手動でトリガーできます:

1. **プライマリ**サイトでGitLab RailsノードにSSHで接続します。
1. [Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)を開きます。
1. `Upload`を[Geoデータ型モデルクラス](#geo-data-type-model-classes)のいずれかに置き換えて、すべてのリソースを`pending verification`としてマークします:

   ```ruby
   Upload.verification_state_table_class.where(verification_state: 3).each_batch do |relation|
     relation.update_all(verification_state: 0)
   end
   ```

#### 1つのセカンダリサイトで1つのコンポーネントを再検証する {#reverify-one-component-on-one-secondary-site}

**プライマリ**サイトのチェックサムが正しいと思われる場合は、UIから1つの**セカンダリ**サイトで1つのコンポーネントの再検証をスケジュールできます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. **Replication details**（レプリケーション）の詳細]で、目的のコンポーネントを選択します。
1. **すべて再検証**を選択します。

## エラー {#errors}

### メッセージ: `The file is missing on the Geo primary site` {#message-the-file-is-missing-on-the-geo-primary-site}

同期の失敗`The file is missing on the Geo primary site`は、セカンダリGeoサイトを初めてセットアップするときによく見られますが、これはプライマリサイトでのデータ不整合が原因です。

データ不整合と見つからないファイルシステムは、GitLabの操作時にシステムエラーまたは人的エラーが原因で発生する可能性があります。たとえば、インスタンス管理者がローカルファイルシステムの複数のアーティファクトを手動で削除したとします。このような変更はデータベースに適切に伝播されず、不整合が発生します。これらの不整合は残り、摩擦を引き起こす可能性があります。これらのファイルはデータベースでまだ参照されているために、Geoセカンダリは引き続きこれらのファイルのレプリケートを試行する可能性がありますが、ファイルは存在していません。

{{< alert type="note" >}}

ローカルからオブジェクトストレージへの最近の移行の場合は、専用の[オブジェクトストレージトラブルシューティングセクション](../../../object_storage.md#inconsistencies-after-migrating-to-object-storage)を参照してください。

{{< /alert >}}

#### 不整合の特定 {#identify-inconsistencies}

見つからないファイルシステムまたは不整合が存在する場合、次のような`geo.log`のエントリが発生する可能性があります。フィールド`"primary_missing_file" : true`に注意してください:

```json
{
   "bytes_downloaded" : 0,
   "class" : "Geo::BlobDownloadService",
   "correlation_id" : "01JT69C1ECRBEMZHA60E5SAX8E",
   "download_success" : false,
   "download_time_s" : 0.196,
   "gitlab_host" : "gitlab.example.com",
   "mark_as_synced" : false,
   "message" : "Blob download",
   "model_record_id" : 55,
   "primary_missing_file" : true,
   "reason" : "Not Found",
   "replicable_name" : "upload",
   "severity" : "WARN",
   "status_code" : 404,
   "time" : "2025-05-01T16:02:44.836Z",
   "url" : "http://gitlab.example.com/api/v4/geo/retrieve/upload/55"
}
```

同じエラーは、特定のリプリカブルの同期ステータスをレビューするときに、**管理者**>**Geo**>**サイト**のUIにも反映されます。このシナリオでは、特定のアップロードが見つからないです:

![すべての失敗したエラーを表示するGeoアップロードリプリカブルダッシュボード。](img/geo_uploads_file_missing_v17_11.png)

![見つからないファイルシステムエラーを表示するGeoアップロードリプリカブルダッシュボード。](img/geo_uploads_file_missing_details_v17_11.png)

#### 不整合をクリーンアップする {#clean-up-inconsistencies}

{{< alert type="warning" >}}

削除コマンドを実行する前に、適切に機能する最近のバックアップを用意しておいてください。

{{< /alert >}}

これらのエラーを削除するには、まず、どの特定のリソースが影響を受けているかを特定します。次に、適切な`destroy`コマンドを実行して、すべてのGeoサイトとそのデータベースに削除が確実に伝播されるようにします。前のシナリオに基づいて、**upload**（アップロード）は、以下の例として使用されているこれらのエラーを引き起こしています。

1. 特定された不整合を、それぞれのGeo [Model class](#geo-data-type-model-classes)名にマップします。以降の手順では、クラス名が必要です。このシナリオでは、アップロードの場合、これは`Upload`に対応します。
1. **Geo primary site**（Geoプライマリサイト）で[Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)を起動します。
1. 前の手順の*Geoモデルクラス*に基づいて、見つからないファイルシステムが原因で検証に失敗したすべてのリソースをクエリします。より多くの結果を表示するには、`limit(20)`を調整または削除します。リストされたリソースがUIに表示される失敗したリソースと一致する方法を観察します:

   ```ruby
   Upload.verification_failed.where("verification_failure like '%File is not checksummable%'").limit(20)

   => #<Upload:0x00007b362bb6c4e8
    id: 55,
    size: 13346,
    path: "503d99159e2aa8a3ac23602058cfdf58/openbao.png",
    checksum: "db29d233de49b25d2085dcd8610bac787070e721baa8dcedba528a292b6e816b",
    model_id: 1,
    model_type: "Project",
    uploader: "FileUploader",
    created_at: Thu, 01 May 2025 15:54:10.549178000 UTC +00:00,
    store: 1,
    mount_point: nil,
    secret: "[FILTERED]",
    version: 2,
    uploaded_by_user_id: 1,
    organization_id: nil,
    namespace_id: nil,
    project_id: 1,
    verification_checksum: nil>
   ```

1. オプションで、影響を受けるリソースの`id`を使用して、それらがまだ必要かどうかを判断します:

   ```ruby
   Upload.find(55)

   => #<Upload:0x00007b362bb6c4e8
    id: 55,
    size: 13346,
    path: "503d99159e2aa8a3ac23602058cfdf58/openbao.png",
    checksum: "db29d233de49b25d2085dcd8610bac787070e721baa8dcedba528a292b6e816b",
    model_id: 1,
    model_type: "Project",
    uploader: "FileUploader",
    created_at: Thu, 01 May 2025 15:54:10.549178000 UTC +00:00,
    store: 1,
    mount_point: nil,
    secret: "[FILTERED]",
    version: 2,
    uploaded_by_user_id: 1,
    organization_id: nil,
    namespace_id: nil,
    project_id: 1,
    verification_checksum: nil>
   ```

   - 影響を受けるリソースを回復する必要があると判断した場合は、次のオプション(網羅的ではない)を調査して回復できます:
     - セカンダリサイトにオブジェクトがあるかどうかを確認し、手動でプライマリにコピーします。
     - 古いバックアップを調べて、手動でオブジェクトをプライマリサイトにコピーして戻します。
     - それらのレコードを削除するのがおそらく問題ないことを判断するために、いくつかのスポットチェックを行います。たとえば、それらがすべて非常に古いアーティファクトである場合、それらは重要なデータではない可能性があります。

1. 特定されたリソースの`id`を使用して、`destroy`を使用して個別にまたは一括で適切に削除します。適切な*Geoモデルクラス*名を使用するようにしてください。
   - 個々のリソースを削除します:

     ```ruby
     Upload.find(55).destroy
     ```

   - 影響を受けるすべてのリソースを削除します:

     ```ruby
     def destroy_uploads_not_checksummable
       uploads = Upload.verification_failed.where("verification_failure like '%File is not checksummable%'");1
       puts "Found #{uploads.count} resources that failed verification with 'File is not checksummable'."
       puts "Enter 'y' to continue: "
       prompt = STDIN.gets.chomp
       if prompt != 'y'
         puts "Exiting without action..."
         return
       end

       puts "Destroying all..."
       uploads.destroy_all
     end

     destroy_uploads_not_checksummable
     ```

影響を受けるすべてのリソースとGeoデータタイプについて、手順を繰り返します。

### メッセージ: `"Error during verification","error":"File is not checksummable"` {#message-error-during-verificationerrorfile-is-not-checksummable}

エラー`"Error during verification","error":"File is not checksummable"`は、プライマリサイトの不整合が原因で発生します。[Geoプライマリサイトにファイルシステムがない](#message-the-file-is-missing-on-the-geo-primary-site)で提供されている手順に従ってください。

### プライマリGeoサイトでのアップロードの検証の失敗 {#failed-verification-of-uploads-on-the-primary-geo-site}

一部のアップロードの検証がプライマリGeoサイトで`verification_checksum = nil`を使用して失敗し、`verification_failure`に``Error during verification: undefined method `underscore' for NilClass:Class``または``The model which owns this Upload is missing.``が含まれている場合、これは孤立したアップロードが原因です。アップロードを所有する親レコード(アップロードの「モデル」)は、何らかの理由で削除されていますが、アップロードレコードはまだ存在します。これは通常、アプリケーションのバグが原因であり、関連するアップロードレコードの一括削除を忘れて、「モデル」の一括削除を実装することで導入されました。したがって、これらの検証の失敗は検証の失敗ではなく、エラーはPostgresの不良データの結果です。

これらのエラーは、プライマリGeoサイトの`geo.log`ファイルシステムで見つけることができます。

モデルレコードが見つからないことを確認するには、プライマリGeoサイトでRakeタスクを実行できます:

```shell
sudo gitlab-rake gitlab:uploads:check
```

次のスクリプトを[Railsコンソール](../../../operations/rails_console.md)から実行して、これらの失敗を取り除くために、プライマリGeoサイトでこれらのアップロードレコードを削除できます:

```ruby
def delete_orphaned_uploads(dry_run: true)
  if dry_run
    p "This is a dry run. Upload rows will only be printed."
  else
    p "This is NOT A DRY RUN! Upload rows will be deleted from the DB!"
  end

  subquery = Geo::UploadState.where("(verification_failure LIKE 'Error during verification: The model which owns this Upload is missing.%' OR verification_failure = 'Error during verification: undefined method `underscore'' for NilClass:Class') AND verification_checksum IS NULL")
  uploads = Upload.where(upload_state: subquery)
  p "Found #{uploads.count} uploads with a model that does not exist"

  uploads_deleted = 0
  begin
    uploads.each do |upload|

      if dry_run
        p upload
      else
        uploads_deleted=uploads_deleted + 1
        p upload.destroy!
      end
    rescue => e
      puts "checking upload #{upload.id} failed with #{e.message}"
    end
  end

  p "#{uploads_deleted} remote objects were destroyed." unless dry_run
end
```

前のスクリプトは`delete_orphaned_uploads`という名前のメソッドを定義します。これを呼び出して、ドライランを実行できます:

```ruby
delete_orphaned_uploads(dry_run: true)
```

また、実際に孤立したアップロード行を削除するには、次のようにします:

```ruby
delete_orphaned_uploads(dry_run: false)
```

### エラー: `Error syncing repository: 13:fatal: could not read Username` {#error-error-syncing-repository-13fatal-could-not-read-username}

`last_sync_failure`エラー`Error syncing repository: 13:fatal: could not read Username for 'https://gitlab.example.com': terminal prompts disabled`は、Geoクローンまたはフェッチリクエスト中にJWT認証が失敗していることを示します。

まず、システムクロックが同期されていることを確認します。[ヘルスチェックRakeタスク](common.md#health-check-rake-task)を実行するか、セカンダリサイトのすべてのSidekiqノードとプライマリサイトのすべてのPumaノードで`date`が同じであることを手動で確認します。

システムクロックが同期されている場合、Gitフェッチが2つの別々のHTTPリクエスト間で計算を実行している間に、JWTトークンが有効期限切れになっている可能性があります。[イシュー464101](https://gitlab.com/gitlab-org/gitlab/-/issues/464101)を参照してください。このイシューはGitLabバージョン17.1.0、17.0.5、および16.11.7で修正されるまで、すべてのGitLabバージョンに存在していました。

この問題が発生しているかどうかを検証するには、次の手順を実行します:

1. [Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)でコードをモンキーパッチして、トークンの有効期限を1分から10分に増やします。セカンダリサイトのRailsコンソールでこれを実行します:

   ```ruby
   module Gitlab; module Geo; class BaseRequest
     private
     def geo_auth_token(message)
       signed_data = Gitlab::Geo::SignedData.new(geo_node: requesting_node, validity_period: 10.minutes).sign_and_encode_data(message)

       "#{GITLAB_GEO_AUTH_TOKEN_TYPE} #{signed_data}"
     end
   end;end;end
   ```

1. 同じRailsコンソールで、影響を受けているプロジェクトを同期します:

   ```ruby
   Project.find_by_full_path('<mygroup/mysubgroup/myproject>').replicator.resync
   ```

1. 同期状態を確認します:

   ```ruby
   Project.find_by_full_path('<mygroup/mysubgroup/myproject>').replicator.registry
   ```

1. `last_sync_failure`にエラー`fatal: could not read Username`が含まれなくなった場合、この問題の影響を受けています。状態は現在`2`になっているはずです。これは同期されていることを意味します。その場合は、修正を含むGitLabバージョンにアップグレードする必要があります。また、この問題の重大度を下げるであろう[イシュー466681](https://gitlab.com/gitlab-org/gitlab/-/issues/466681)に同意するか、コメントすることもできます。

この問題を回避するには、JWT有効期限を延長するために、セカンダリサイトのすべてのSidekiqノードにホットパッチを適用する必要があります:

1. `/opt/gitlab/embedded/service/gitlab-rails/ee/lib/gitlab/geo/signed_data.rb`を編集します。
1. `Gitlab::Geo::SignedData.new(geo_node: requesting_node)`を見つけて、`, validity_period: 10.minutes`を追加します:

   ```diff
   - Gitlab::Geo::SignedData.new(geo_node: requesting_node)
   + Gitlab::Geo::SignedData.new(geo_node: requesting_node, validity_period: 10.minutes)
   ```

1. Sidekiqを再起動します:

   ```shell
   sudo gitlab-ctl restart sidekiq
   ```

1. 修正を含むバージョンにアップグレードしない限り、GitLabをアップグレードするたびに、この回避策を繰り返す必要があります。

### エラー: `Error syncing repository: 13:creating repository: cloning repository: exit status 128` {#error-error-syncing-repository-13creating-repository-cloning-repository-exit-status-128}

このエラーは、同期が正常に完了しないプロジェクトで発生する可能性があります。

リポジトリの作成中に終了コード128が発生した場合、Gitがクローン作成中に致命的なエラーが発生したことを意味します。これは、リポジトリの破損、ネットワーキングの問題、認証の問題、リソース制限、またはプロジェクトに関連付けられたGitリポジトリがないことが原因である可能性があります。このような失敗の具体的な原因の詳細については、Gitalyログで確認できます。

どこから始めればよいかわからない場合は、[`git fsck`コマンドラインで手動で呼び出す](../../../../administration/repository_checks.md#run-a-check-using-the-command-line)ことで、プライマリサイトのソースリポジトリで整合性チェックを実行します。

### エラー: `gitmodulesUrl: disallowed submodule url` {#error-gitmodulesurl-disallowed-submodule-url}

一部のプロジェクトリポジトリは、エラー`Error syncing repository: 13:creating repository: cloning repository: exit status 128`で一貫して同期に失敗します。ただし、一部のリポジトリでは、Gitalyログの特定のエラーメッセージが異なります: `gitmodulesUrl: disallowed submodule url`この失敗は、リポジトリに`.gitmodules`ファイル内の不正なサブモジュールURLが含まれている場合に発生します。

問題は、リポジトリのコミット履歴にあります。`.gitmodules`ファイル内のサブモジュールURLには、パスに`/`の代わりに`:`を使用した不正な形式が含まれています:

- 無効：`https://example.gitlab.com:group/project.git`
- 有効：`https://example.gitlab.com/group/project.git`

この問題はGitLabバージョン17.0以降で認識されており、リポジトリの整合性チェックがより厳密になった結果です。この新しい動作は、このチェックが追加されたGit自体の変更によるものです。GitLab GeoまたはGitalyに固有のものではありません。詳細については、[issue 468560](https://gitlab.com/gitlab-org/gitlab/-/issues/468560)を参照してください。

#### 回避策 {#workaround}

{{< alert type="note" >}}

問題のあるリポジトリがフォークネットワーキングの一部である場合、オブジェクトプールに含まれるblobはこの方法で削除できないため、このblob削除メソッドは機能しない可能性があります。

{{< /alert >}}

問題のあるblobをリポジトリから削除する必要があります:

1. [プロジェクトのエクスポートオプション](../../../../user/project/settings/import_export.md)を使用して、続行する前にプロジェクトをバックアップします。

1. 次のいずれかの方法を使用して、問題のあるblob SHA IDを特定します:

   - `git fsck`を使用してください: リポジトリをクローンし、`git fsck`を実行して問題を確認します:

     ```shell
     git clone https://example.gitlab.com/group/project.git
     cd project
     git fsck
     ```

     出力に、問題のあるblobが表示されます:

     ```plaintext
     Checking object directories: 100% (256/256), done.
     error in blob <SHA>: gitmodulesUrl: disallowed submodule url: https://example.gitlab.com:group/project.git
     Checking objects: 100% (12/12), done.
     ```

   - Gitalyログを確認します。`gitmodulesUrl`を含むエラーメッセージを探して、特定のblob SHAを見つけます。

1. [リポジトリサイズの管理ガイドライン](../../../../user/project/repository/repository_size.md#remove-blobs)に記載されているプロセスを使用して、不正なblobを削除します。

1. blobを削除したら、現在のブランチの`.gitmodules`ファイルで不正なURLを確認します。ファイルを編集して、URLを`https://example.gitlab.com:group/project.git`（コロンを使用）から`https://example.gitlab.com/group/project.git`（スラッシュを使用）に変更し、変更をコミットします。

{{< alert type="warning" >}}

修正後、影響を受けるプロジェクトに取り組んでいるすべてのデベロッパーは、現在のローカルコピーを削除し、新しいリポジトリをクローンする必要があります。そうしないと、変更をプッシュするときに、不正なblobが再導入される可能性があります。

{{< /alert >}}

### エラー：`fetch remote: signal: terminated: context deadline exceeded`（正確に3時間後） {#error-fetch-remote-signal-terminated-context-deadline-exceeded-at-exactly-3-hours}

Gitリポジトリの同期中にGitフェッチが正確に3時間で失敗する場合:

1. `/etc/gitlab/gitlab.rb`を編集して、Gitのタイムアウトをデフォルトの10800秒から増やします:

   ```ruby
   # Git timeout in seconds
   gitlab_rails['gitlab_shell_git_timeout'] = 21600
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### レジストリレプリケーションを構成する際のセカンダリのエラー`Failed to open TCP connection to localhost:5000` {#error-failed-to-open-tcp-connection-to-localhost5000-on-secondary-when-configuring-registry-replication}

セカンダリサイトでコンテナレジストリレプリケーションを構成する際に、次のエラーが発生する可能性があります:

```plaintext
Failed to open TCP connection to localhost:5000 (Connection refused - connect(2) for \"localhost\" port 5000)"
```

これは、コンテナレジストリがセカンダリサイトで有効になっていない場合に発生します。解決するには、コンテナレジストリが[セカンダリサイトで有効になっている](../../../packages/container_registry.md#enable-the-container-registry)ことを確認してください。[Let's Encrypt](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually)インテグレーションが無効になっている場合、コンテナレジストリも無効になり、[手動で構成する](../../../packages/container_registry.md#configure-container-registry-under-its-own-domain)必要があります。

### メッセージ: `Synchronization failed - Error syncing repository` {#message-synchronization-failed---error-syncing-repository}

{{< alert type="warning" >}}

大規模なリポジトリがこの問題の影響を受けている場合、再同期に時間がかかり、Geoサイト、ストレージ、およびネットワーキングシステムに大きな負荷がかかる可能性があります。

{{< /alert >}}

次のエラーメッセージは、リポジトリの同期中に整合性チェックエラーが発生したことを示しています:

```plaintext
Synchronization failed - Error syncing repository [..] fatal: fsck error in packed object
```

いくつかの問題でこのエラーがトリガーされる可能性があります。たとえば、メールアドレスに関する問題があります:

```plaintext
Error syncing repository: 13:fetch remote: "error: object <SHA>: badEmail: invalid author/committer line - bad email
   fatal: fsck error in packed object
   fatal: fetch-pack: invalid index-pack output
```

このエラーをトリガーする可能性のあるもう1つの問題は`object <SHA>: hasDotgit: contains '.git'`です。すべてのリポジトリで複数の問題が発生している可能性があるため、特定のエラーを確認してください。

2番目の同期エラーは、リポジトリチェックの問題によっても発生する可能性があります:

```plaintext
Error syncing repository: 13:Received RST_STREAM with error code 2.
```

これらのエラーは、[すぐに失敗したすべてのリポジトリを同期する](#sync-all-resources-of-one-component-that-failed-to-sync)ことで確認できます。

整合性エラーを引き起こしている不正な形式オブジェクトを削除するには、リポジトリの履歴を書き換える必要があります。これは通常、オプションではありません。

これらの整合性チェックを無視するには、これらの`git fsck`の問題を無視するように、**on the secondary Geo sites**（セカンダリGeoサイト）でGitalyを再構成します。次の設定例:

- GitLab 16.0から必要な[新しい設定構造を使用](../../../../update/versions/gitlab_16_changes.md#gitaly-configuration-structure-change)します。
- 5つの一般的なチェックの失敗を無視します。

[Gitalyドキュメントには](../../../gitaly/consistency_checks.md)、他のGitチェックの失敗とGitLabの以前のバージョンに関する詳細が記載されています。

```ruby
gitaly['configuration'] = {
  git: {
    config: [
      { key: "fsck.duplicateEntries", value: "ignore" },
      { key: "fsck.badFilemode", value: "ignore" },
      { key: "fsck.missingEmail", value: "ignore" },
      { key: "fsck.badEmail", value: "ignore" },
      { key: "fsck.hasDotgit", value: "ignore" },
      { key: "fetch.fsck.duplicateEntries", value: "ignore" },
      { key: "fetch.fsck.badFilemode", value: "ignore" },
      { key: "fetch.fsck.missingEmail", value: "ignore" },
      { key: "fetch.fsck.badEmail", value: "ignore" },
      { key: "fetch.fsck.hasDotgit", value: "ignore" },
      { key: "receive.fsck.duplicateEntries", value: "ignore" },
      { key: "receive.fsck.badFilemode", value: "ignore" },
      { key: "receive.fsck.missingEmail", value: "ignore" },
      { key: "receive.fsck.badEmail", value: "ignore" },
      { key: "receive.fsck.hasDotgit", value: "ignore" },
    ],
  },
}
```

`fsck`エラーの包括的なリストは、[Gitドキュメント](https://git-scm.com/docs/git-fsck#_fsck_messages)にあります。

GitLab 16.1以降には、これらの問題の一部を解決する可能性のある[機能強化が含まれています](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5879)。

[Gitaly問題5625](https://gitlab.com/gitlab-org/gitaly/-/issues/5625)は、ソースリポジトリに問題のあるコミットが含まれている場合でも、Geoがリポジトリをレプリケートすることを保証することを提案しています。

### 関連エラー`does not appear to be a git repository` {#related-error-does-not-appear-to-be-a-git-repository}

次のログメッセージとともに、エラーメッセージ`Synchronization failed - Error syncing repository`が表示されることもあります。このエラーは、予期されるGeoリモートが、セカンダリGeoサイトのファイルシステムのリポジトリの`.git/config`ファイルに存在しないことを示しています:

```json
{
  "created": "@1603481145.084348757",
  "description": "Error received from peer unix:/var/opt/gitlab/gitaly/gitaly.socket",
  …
  "grpc_message": "exit status 128",
  "grpc_status": 13
}
{  …
  "grpc.request.fullMethod": "/gitaly.RemoteService/FindRemoteRootRef",
  "grpc.request.glProjectPath": "<namespace>/<project>",
  …
  "level": "error",
  "msg": "fatal: 'geo' does not appear to be a git repository
          fatal: Could not read from remote repository. …",
}
```

これを解決するには:

1. セカンダリGeoサイトのWebインターフェースにサインインします。

1. [`.git`フォルダー](../../../repository_storage_paths.md#translate-hashed-storage-paths)をバックアップします。

1. オプション。[スポットチェック](../../../logs/log_parsing.md#find-all-projects-affected-by-a-fatal-git-problem)して、それらのIDのいくつかが、既知のGeoレプリケーションの失敗があるプロジェクトに実際に対応しているかどうかを確認します。`fatal: 'geo'`を`grep`用語として、次のAPIコールを使用します:

   ```shell
   curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<first_failed_geo_sync_ID>"
   ```

1. [Railsコンソール](../../../operations/rails_console.md)に入り、実行します:

   ```ruby
   failed_project_registries = Geo::ProjectRepositoryRegistry.failed

   if failed_project_registries.any?
     puts "Found #{failed_project_registries.count} failed project repository registry entries:"

     failed_project_registries.each do |registry|
       puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Last Sync Failure: '#{registry.last_sync_failure}'"
     end
   else
     puts "No failed project repository registry entries found."
   end
   ```

1. 次のコマンドを実行して、各プロジェクトの新しい同期を実行します:

   ```ruby
   failed_project_registries.each do |registry|
     registry.replicator.sync
     puts "Sync initiated for registry ID: #{registry.id}, Project ID: #{registry.project_id}"
   end
   ```

## バックフィル中の失敗 {#failures-during-backfill}

[バックフィル](../../_index.md#backfill)中、失敗はバックフィルキューの最後に再試行されるようにスケジュールされているため、これらの失敗は**after**（以降）のバックフィルが完了した後にのみクリアされます。

## メッセージ: `unexpected disconnect while reading sideband packet` {#message-unexpected-disconnect-while-reading-sideband-packet}

不安定なネットワーキング状態により、プライマリサイトから大規模なリポジトリデータをフェッチしようとすると、Gitalyが失敗する可能性があります。これらの状態により、次のエラーが発生する可能性があります:

```plaintext
curl 18 transfer closed with outstanding read data remaining & fetch-pack:
unexpected disconnect while reading sideband packet
```

このエラーは、リポジトリをサイト間でゼロからレプリケートする必要がある場合に発生する可能性が高くなります。

Geoは数回再試行しますが、転送がネットワークのヒカップによって一貫して中断される場合は、`rsync`などの別の方法を使用して`git`を回避し、Geoによるレプリケートに失敗したリポジトリの最初のコピーを作成できます。

各転送後に、失敗した各リポジトリを個別に転送し、整合性をチェックすることをお勧めします。[`rsync`を別のサーバーに指示する](../../../operations/moving_repositories.md#use-rsync-to-another-server)に従って、影響を受ける各リポジトリをプライマリサイトからセカンダリサイトに転送します。

## Geoセカンダリサイトでのリポジトリチェックの失敗を検索する {#find-repository-check-failures-in-a-geo-secondary-site}

{{< alert type="note" >}}

すべてのリポジトリデータ型が、GitLab 16.3のGeoセルフサービスフレームワークに移行されました。[この機能をGeoセルフサービスフレームワークに実装し直すイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/426659)があります。

{{< /alert >}}

GitLab 16.2以前:

[すべてのプロジェクトで有効](../../../repository_checks.md#enable-repository-checks-for-all-projects)にすると、[リポジトリチェック](../../../repository_checks.md)はGeoセカンダリサイトでも実行されます。メタデータはGeoトラッキングデータベースに保存されます。

Geoセカンダリサイトでのリポジトリチェックの失敗は、必ずしもレプリケーションの問題を意味するわけではありません。これらの失敗を解決するための一般的なアプローチを次に示します。

1. 以下に示すように、影響を受けるリポジトリとその[記録されたエラー](../../../repository_checks.md#what-to-do-if-a-check-failed)を見つけます。
1. 特定の`git fsck`エラーを診断してみてください。発生する可能性のあるエラーの範囲は広いため、検索エンジンに入力してみてください。
1. 影響を受けるリポジトリの一般的な機能をテストします。セカンダリからプルし、ファイルを表示します。
1. プライマリサイトのリポジトリのコピーに同一の`git fsck`エラーがあるかどうかを確認します。フェイルオーバーを計画している場合は、セカンダリサイトにプライマリサイトと同じ情報が含まれるように優先順位を付けることを検討してください。プライマリのバックアップがあることを確認し、[計画されたフェイルオーバーのガイドライン](../../disaster_recovery/planned_failover.md)に従ってください。
1. プライマリにプッシュし、変更がセカンダリサイトにレプリケートされているかどうかを確認します。
1. レプリケーションが自動的に機能しない場合は、手動でリポジトリを同期してみてください。

[Railsコンソールセッションを開始](../../../operations/rails_console.md#starting-a-rails-console-session)して、次の基本的なトラブルシューティング手順を実行します。

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

### リポジトリチェックに失敗したリポジトリの数を取得する {#get-the-number-of-repositories-that-failed-the-repository-check}

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true).count
```

### リポジトリチェックに失敗したリポジトリを検索する {#find-the-repositories-that-failed-the-repository-check}

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true)
```

## Gitalyクラスタリングからリポジトリを完全に削除し、再同期する {#hard-delete-a-repository-from-gitaly-cluster-and-resync}

{{< alert type="warning" >}}

この手順は危険で、強引です。他のトラブルシューティング方法が失敗した場合にのみ、最後の手段として使用してください。この手順により、リポジトリが再同期されるまで、一時的なデータ損失が発生します。

{{< /alert >}}

この手順では、セカンダリサイトのGitalyクラスタリングからリポジトリを削除し、再同期します。リスクを理解していて、次の条件がすべて満たされている場合にのみ、使用を検討する必要があります:

- `git clone`がプライマリサイトのリポジトリで機能しています。
- `p.replicator.sync_repository`（`p`はプロジェクトモデルインスタンス）は、セカンダリサイトでGitalyエラーを記録します。
- 標準的なトラブルシューティングで問題が解決されていません。

前提要件: 

- セカンダリサイトのRailsコンソールとPraefectノードの両方への管理アクセス権があることを確認します。
- リポジトリがプライマリサイトでアクセス可能で、正しく機能していることを確認します。
- この手順をリセットする必要がある場合に備えて、バックアッププランを用意してください。

これを行うには、次の手順を実行します:

1. セカンダリサイトのRailsコンソールにサインインします。
1. プロジェクトモデルをインスタンス化し、これらのオプションのいずれかを使用して、変数`p`に保存します:

   - 影響を受けるプロジェクトID（たとえば、`60087`）がわかっている場合:

     ```ruby
     p = Project.find(60087)
     ```

   - GitLabで影響を受けるプロジェクトパス（たとえば、`my-group/my-project`）がわかっている場合:

     ```ruby
     p = Project.find_by_full_path('my-group/my-project')
     ```

1. プロジェクトGitリポジトリの仮想ストレージを出力し、後で使用するために書き留めます:

   ```ruby
   p.repository.storage
   ```

   出力例: 

   ```ruby
   irb(main):002:0> p.repository.storage
   => "default"
   ```

1. プロジェクトGitリポジトリの相対パスを出力し、後で使用するために書き留めます:

   ```ruby
   p.repository.disk_path + '.git'
   ```

   出力例: 

   ```ruby
   irb(main):003:0> p.repository.disk_path + '.git'
   => "@hashed/66/b2/66b2fc8562b3432399acc2d0108fcd2782b32bd31d59226c7a03a20b32c76ee8.git"
   ```

1. セカンダリサイトのPraefectノードにSSHでサインインします。
1. 前の手順で書き留めた仮想ストレージと相対パスを使用して、[Gitalyクラスタリングからリポジトリを手動で削除する](../../../gitaly/praefect/recovery.md#manually-remove-repositories)手順に従います。

   セカンダリサイトのGitリポジトリが削除されました。

1. Railsコンソールで、再同期する前に、相関IDを設定します。このIDを使用すると、このセッションで実行するコマンドに関連するすべてのログを検索できます:

   ```ruby
   Gitlab::ApplicationContext.push({})
   ```

   出力例: 

   ```ruby
   [2] pry(main)> Gitlab::ApplicationContext.push({})
   => #<Labkit::Context:0x0000000122aa4060 @data={"correlation_id"=>"53da64ae800bd4794a2b61ab1c80b028"}>
   ```

1. プロジェクトGitリポジトリを同期します:

   ```ruby
   p.replicator.sync_repository
   ```

Gitリポジトリがプライマリサイトからセカンダリサイトに再同期されるようになりました。Geo管理インターフェースを通じて、またはRailsコンソールでリポジトリの同期ステータスを確認して、同期プロセスを監視します。

## Geo**セカンダリ**サイトレプリケーションのリセット {#resetting-geo-secondary-site-replication}

壊れた状態の**セカンダリ**サイトを取得し、レプリケーション状態をリセットして、最初からやり直したい場合は、いくつかの手順が役立ちます:

1. SidekiqとGeoログカーソルを停止します。

   Sidekiqを正常に停止させることは可能ですが、新しいジョブの取得を停止し、現在のジョブが処理を完了するのを待機させます。

   最初のフェーズでは**SIGTSTP**キルシグナルを送信し、すべてのジョブが完了したら**SIGTERM**を送信する必要があります。それ以外の場合は、`gitlab-ctl stop`コマンドを使用してください。

   ```shell
   gitlab-ctl status sidekiq
   # run: sidekiq: (pid 10180) <- this is the PID you will use
   kill -TSTP 10180 # change to the correct PID

   gitlab-ctl stop sidekiq
   gitlab-ctl stop geo-logcursor
   ```

   [Sidekiqのログ](../../../logs/_index.md#sidekiq-logs)を監視して、Sidekiqジョブの処理が完了したことを確認できます:

   ```shell
   gitlab-ctl tail sidekiq
   ```

1. GitalyおよびGitalyクラスタリング (Praefect) データをクリアします。

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```shell
   mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
   sudo gitlab-ctl reconfigure
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   1. オプション。Praefect内部ロードバランサーを無効にします。
   1. 各PraefectサーバーでPraefectを停止します:

      ```shell
      sudo gitlab-ctl stop praefect
      ```

   1. Praefectデータベースをリセットします:

      ```shell
      sudo /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h localhost -c "DROP DATABASE praefect_production WITH (FORCE);"
      sudo /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h localhost -c "CREATE DATABASE praefect_production WITH OWNER=praefect ENCODING=UTF8;"
      ```

   1. 各Gitalyノードからリポジトリのデータを名前変更または削除します:

      ```shell
      sudo mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
      sudo gitlab-ctl reconfigure
      ```

   1. Praefectデプロイノードで再構成を実行し、データベースをセットアップします:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. 各PraefectサーバーでPraefectを開始します:

      ```shell
      sudo gitlab-ctl start praefect
      ```

   1. オプション。無効にした場合は、Praefect内部ロードバランサーを再度アクティブ化します。

   {{< /tab >}}

   {{< /tabs >}}

   {{< alert type="note" >}}

   ディスク領域を節約するために、不要になったことが確認できたら、将来`/var/opt/gitlab/git-data/repositories.old`を削除することをお勧めします。

   {{< /alert >}}

1. オプション。他のデータフォルダーの名前を変更し、新しいデータフォルダーを作成します。

   {{< alert type="warning" >}}

   **セカンダリ**サイトにあるファイルが**プライマリ**サイトから削除されている可能性がありますが、この削除は反映されていません。この手順をスキップすると、これらのファイルはGeoの**セカンダリ**サイトから削除されません。

   {{< /alert >}}

   アップロードされたコンテンツ（ファイル添付ファイル、アバター、またはLFSオブジェクトなど）は、次のパスのいずれかのサブフォルダーに保存されます:

   - `/var/opt/gitlab/gitlab-rails/shared`
   - `/var/opt/gitlab/gitlab-rails/uploads`

   すべて名前を変更するには:

   ```shell
   gitlab-ctl stop

   mv /var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared.old
   mkdir -p /var/opt/gitlab/gitlab-rails/shared

   mv /var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads.old
   mkdir -p /var/opt/gitlab/gitlab-rails/uploads

   gitlab-ctl start postgresql
   gitlab-ctl start geo-postgresql
   ```

   再構成してフォルダーを再作成し、アクセス許可と所有権が正しいことを確認します:

   ```shell
   gitlab-ctl reconfigure
   ```

1. トラッキングデータベースをリセットします。

   {{< alert type="warning" >}}

   オプションの手順3をスキップした場合は、`geo-postgresql`サービスと`postgresql`サービスの両方が実行されていることを確認してください。

   {{< /alert >}}

   ```shell
   gitlab-rake db:drop:geo DISABLE_DATABASE_ENVIRONMENT_CHECK=1   # on a secondary app node
   gitlab-ctl reconfigure     # on the tracking database node
   gitlab-rake db:migrate:geo # on a secondary app node
   ```

1. 以前に停止したサービスを再起動します。

   ```shell
   gitlab-ctl start
   ```
