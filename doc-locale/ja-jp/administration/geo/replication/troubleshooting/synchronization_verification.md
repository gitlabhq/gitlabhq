---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geoの同期と検証のエラーのトラブルシューティング
description: "Geoの同期と検証の失敗のトラブルシューティングを行い、手動再試行手順、一括操作、エラー診断、データ整合性の復元について説明します。"
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`Admin > Geo > Sites`または[同期ステータスのRakeタスク](common.md#sync-status-rake-task)でレプリケーションまたは検証の失敗に気付いた場合は、次の一般的な手順で失敗を解決できます:

1. Geoは、失敗を自動的に再試行します。失敗が新しく数が少ない場合、または根本原因が既に解決されていると思われる場合は、失敗がなくなるまで待つことができます。
1. 失敗が長時間存在する場合は、多くの再試行が既に行われており、自動再試行の間隔は、失敗の種類に応じて最大4時間まで長くなっています。根本原因が既に解決されていると思われる場合は、待機時間を回避するために[レプリケーションまたは検証を手動で再試行](#manually-retry-replication-or-verification)できます。
1. 失敗が解決しない場合は、次のセクションを使用して解決を試みます。

## トラブルシューティングの手順 {#diagnostic-procedures}

手動での再試行を試みる前に、これらの拡張された診断手順を使用して、同期の問題の範囲と性質をより深く理解できます。

### レジストリステータスチェック {#registry-status-check}

この手順では、すべてのGeoレジストリタイプに関する詳細なステータス情報が提供され、失敗のパターンを特定できます。

1. [Railsコンソールセッションを開始](../../../operations/rails_console.md#starting-a-rails-console-session)します。**セカンダリ**サイトで。

1. 包括的な概要を取得するには、次のスクリプトを実行します:

   ```ruby
   def output_geo_failures()
     registry_classes = [
       Geo::UploadRegistry,
       Geo::JobArtifactRegistry,
       Geo::PackageFileRegistry,
       Geo::PagesDeploymentRegistry,
       Geo::ProjectRepositoryRegistry,
       Geo::TerraformStateVersionRegistry,
       Geo::MergeRequestDiffRegistry,
       Geo::LfsObjectRegistry,
       Geo::PipelineArtifactRegistry,
       Geo::CiSecureFileRegistry
     ]

     registry_classes.each do |klass|
       puts "\n=== #{klass.name} ==="
       puts "Total: #{klass.count}"
       puts "Failed: #{klass.failed.count}"
       puts "Synced: #{klass.synced.count}"
       puts "Pending: #{klass.pending.count}"
       puts "Started: #{klass.with_state(:started).count}"

       if klass.failed.count > 0
          puts "\nSample failed records:"
          klass.failed.limit(3).each { |record| puts "  ID: #{record.id}, Error: #{record.last_sync_failure}" }
       end
     end

     nil
   end

   output_geo_failures()
   ```

1. このスクリプトは、各レジストリタイプに関する詳細情報を出力します。以下を含みます:
   - レコードの総数
   - 失敗、同期、および保留中のレコードの数
   - 調査用のサンプル失敗レコード

## レプリケーションまたは検証を手動で再試行 {#manually-retry-replication-or-verification}

[Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)でセカンダリGeoサイトにいる場合は、以下を実行できます:

- [個々のコンポーネントを再度同期して再検証する](#resync-and-reverify-individual-components)
- [複数のコンポーネントを再度同期して再検証する](#resync-and-reverify-multiple-components)

### 個々のコンポーネントの再同期と再検証 {#resync-and-reverify-individual-components}

セカンダリサイトで、**管理者** > **Geo** > **レプリケーション**にアクセスして、個々のアイテムの再同期または再検証を強制します。

ただし、これでうまくいかない場合は、Railsコンソールを使用して同じアクションを実行できます。次のセクションでは、[Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)で内部アプリケーションコマンドを使用して、個々のレコードのレプリケーションまたは検証を同期的または非同期的に行う方法について説明します。

#### Replicatorインスタンスの取得 {#obtaining-a-replicator-instance}

> [!warning]データを変更するコマンドは、正しく実行されない場合、または適切な条件下で実行されない場合に、損傷を引き起こす可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

同期または検証操作を実行する前に、Replicatorインスタンスを取得する必要があります。

まず、実行する内容に応じて、**プライマリ**または**セカンダリ**サイトで[Railsコンソールセッションを開始](../../../operations/rails_console.md#starting-a-rails-console-session)します。

**プライマリ**サイト:

- リソースをチェックサムできます

**セカンダリ**サイト:

- リソースを同期できます
- リソースをチェックサムし、そのチェックサムをプライマリサイトのチェックサムと照合して検証できます

次に、次のスニペットのいずれかを実行して、Replicatorインスタンスを取得します。

##### モデルレコードのIDを指定した場合 {#given-a-model-records-id}

- `123`を実際のIDに置き換えます。
- `Packages::PackageFile`を[Geoデータ型モデルクラス](#geo-data-type-model-classes)のいずれかに置き換えます。

```ruby
model_record = Packages::PackageFile.find_by(id: 123)
replicator = model_record.replicator
```

##### レジストリレコードのIDを指定した場合 {#given-a-registry-records-id}

- `432`を実際のIDに置き換えます。レジストリレコードは、追跡するModelレコードと同じID値を持つ場合と持たない場合があります。
- `Geo::PackageFileRegistry`を[Geoレジストリクラス](#geo-registry-classes)のいずれかに置き換えます。

セカンダリGeoサイトの場合:

```ruby
registry_record = Geo::PackageFileRegistry.find_by(id: 432)
replicator = registry_record.replicator
```

##### レジストリレコードの`last_sync_failure`のエラーメッセージを指定した場合 {#given-an-error-message-in-a-registry-records-last_sync_failure}

- `Geo::PackageFileRegistry`を[Geoレジストリクラス](#geo-registry-classes)のいずれかに置き換えます。
- `error message here`を実際のエラーメッセージに置き換えます。

```ruby
registry = Geo::PackageFileRegistry.find_by("last_sync_failure LIKE '%error message here%'")
replicator = registry.replicator
```

##### レジストリレコードの`verification_failure`のエラーメッセージを指定した場合 {#given-an-error-message-in-a-registry-records-verification_failure}

- `Geo::PackageFileRegistry`を[Geoレジストリクラス](#geo-registry-classes)のいずれかに置き換えます。
- `error message here`を実際のエラーメッセージに置き換えます。

```ruby
registry = Geo::PackageFileRegistry.find_by("verification_failure LIKE '%error message here%'")
replicator = registry.replicator
```

#### Replicatorインスタンスを使用した操作の実行 {#performing-operations-with-a-replicator-instance}

`replicator`変数に格納されているReplicatorインスタンスがある場合は、多くの操作を実行できます:

##### コンソールでの同期 {#sync-in-the-console}

このスニペットは、**セカンダリ**サイトでのみ機能します。

これにより、コンソールで同期コードが同同期的に実行されるため、リソースの同期にかかる時間を確認したり、完全なエラーバックトレースを表示したりできます。

```ruby
replicator.sync
```

オプションで、コンソールのログレベルを構成されたログレベルよりも詳細にしてから、同期を実行します:

```ruby
Rails.logger.level = :debug
```

##### コンソールでのチェックサムまたは検証 {#checksum-or-verify-in-the-console}

このスニペットは、**プライマリ**または**セカンダリ**サイトで機能します。

**プライマリ**サイトでは、リソースをチェックサムし、結果をメインのGitLabデータベースに保存します。**セカンダリ**サイトでは、リソースをチェックサムし、メインのGitLabデータベース(**プライマリ**サイトによって生成される)のチェックサムと照合して、結果をGeoトラッキングデータベースに保存します。

これにより、コンソールでチェックサムと検証コードが同同期的に実行されるため、かかる時間を確認したり、完全なエラーバックトレースを表示したりできます。

```ruby
replicator.verify
```

##### Sidekiqジョブでの同期 {#sync-in-a-sidekiq-job}

このスニペットは、**セカンダリ**サイトでのみ機能します。

Sidekiqがリソースの[sync](#sync-in-the-console)を実行するためのジョブをエンキューします。

```ruby
replicator.enqueue_sync
```

##### Sidekiqジョブでの検証 {#verify-in-a-sidekiq-job}

このスニペットは、**プライマリ**または**セカンダリ**サイトで機能します。

Sidekiqがリソースの[チェックサムまたは検証](#checksum-or-verify-in-the-console)を実行するためのジョブをエンキューします。

```ruby
replicator.verify_async
```

##### モデルレコードの取得 {#get-a-model-record}

このスニペットは、**プライマリ**または**セカンダリ**サイトで機能します。

```ruby
replicator.model_record
```

##### レジストリレコードの取得 {#get-a-registry-record}

このスニペットは、**セカンダリ**サイトでのみ機能します。これは、レジストリテーブルがGeoトラッキングDBに格納されているためです。

```ruby
replicator.registry
```

#### Geoデータ型モデルクラス {#geo-data-type-model-classes}

Geoデータ型は、関連データを格納するために1つ以上のGitLab機能に必要なデータの特定のクラスであり、Geoによってセカンダリサイトにレプリケートされます。

- **Blob types**:
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
- **Git Repository types**:
  - `DesignManagement::Repository`
  - `ProjectRepository`
  - `ProjectWikiRepository`
  - `SnippetRepository`
  - `GroupWikiRepository`
- **Other types**:
  - `ContainerRepository`

主なクラスの種類は、レジストリ、モデル、およびReplicatorです。これらのクラスのいずれかのインスタンスがある場合は、他のインスタンスを取得できます。レジストリとモデルは、主にPostgreSQL DBの状態を管理します。Replicatorは、PostgreSQL以外のデータ(ファイル/Gitリポジトリ/コンテナリポジトリ)をレプリケートまたは検証する方法を認識しています。

#### Geoレジストリクラス {#geo-registry-classes}

GitLab Geoのコンテキストでは、**registry record**は、Geoトラッキングデータベース内のレジストリテーブルを指します。各レコードは、LFSファイルやプロジェクトのGitリポジトリなど、メインのGitLabデータベース内の単一のレプリケート可能なファイルを追跡します。クエリできるGeoレジストリテーブルに対応するRailsモデルは次のとおりです:

- **Blob types**:
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
- **Git Repository types**:
  - `Geo::DesignManagementRepositoryRegistry`
  - `Geo::ProjectRepositoryRegistry`
  - `Geo::ProjectWikiRepositoryRegistry`
  - `Geo::SnippetRepositoryRegistry`
  - `Geo::GroupWikiRepositoryRegistry`
- **Other types**:
  - `Geo::ContainerRepositoryRegistry`

### 複数のコンポーネントを再度同期して再検証する {#resync-and-reverify-multiple-components}

{{< history >}}

- 一括再同期と再検証がGitLab 16.5で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/364729)されました。

{{< /history >}}

コンポーネントリソースの同期または検証に失敗した場合、一括アクションをトリガーしてレプリケーションキューを再開できます。これらのアクションは、再試行回数とスケジュール時刻を0にリセットし、システムが失敗したリソースを最大1時間待機するのではなく、より早く処理するようにします。

> [!note]これらのアクションは、リソースをすぐに処理するわけではありません。代わりに、同期と検証を処理するバックグラウンドジョブを再キューに入れます。実際には、標準のGeoレプリケーションプロセスを通じて、非同期的にレプリケーション作業が行われます。

#### 再同期と再検証の仕組み {#how-resync-and-reverification-works}

再同期または再検証アクションをトリガーすると、システムは一致するレコードを`pending`としてマークします。Geoの再同期と再検証のバックグラウンドワーカーは、これらのレコードを取得し、通常のキューの優先度に従って処理します。このメカニズムを使用すると、操作ですぐにブロックせずに、失敗したリソースの処理を迅速化できます。

> [!note]正常に同期されていないレコードを再検証することはできません。同期されたレコードのみを検証できます。

UIまたはRailsコンソールから一括アクションをトリガーできます。

#### UIから {#from-the-ui}

UIから1つのコンポーネントのすべてのリソースの完全な再同期をスケジュールできます:

1. 右上隅で、**管理者**を選択します。
1. 右上隅で、**Geo**を選択します。次に**サイト**を選択します。
1. **Replication details**で、目的のコンポーネントを選択します。

##### 選択したコンポーネントのリソースを再同期する {#resync-resources-for-the-selected-component}

1. **すべて再同期**を選択します: これにより、選択したリソースのすべてのレコードの状態が、既に同期されているかどうかに関係なくリセットされます。
1. **すべての再同期に失敗しました**を選択します: これにより、同期に失敗したすべてのレコードがリセットされます。

##### 選択したコンポーネントのリソースを再検証する {#reverify-resources-for-the-selected-component}

1. **すべて再検証**を選択します: これにより、選択したリソースのすべてのレコードの状態が、既に検証されているかどうかに関係なくリセットされます。
1. **すべての失敗を再検証**を選択します: これにより、検証に失敗したが、同期が成功したすべてのレコードがリセットされます。

##### すべてのサイトで1つのコンポーネントを再検証する {#reverify-one-component-on-all-sites}

**プライマリ**サイトのチェックサムに疑問がある場合は、**プライマリ**サイトにチェックサムを再計算させる必要があります。**プライマリ**サイトで各チェックサムが再計算された後、すべての**セカンダリ**サイトに伝播されるイベントが生成され、チェックサムが再計算され、値が比較されるため、「完全な再検証」が実現されます。不一致があると、レジストリが`sync failed`としてマークされ、同期の再試行がスケジュールされます。

UIからプライマリサイトのチェックサムを再計算できます:

1. 右上隅で、**管理者**を選択します。
1. **モニタリング** > **データ管理**を選択します。
1. ドロップダウンリストで目的のコンポーネントを選択します。
1. **すべてのチェックサム**を選択します。

> [!warning] **すべて再同期**、**すべて再検証**、および**すべてのチェックサム**は、すでに同期または検証されているかどうかに関係なく、すべてのリソースの更新をトリガーします。インスタンス内に何千ものオブジェクトタイプ(CIジョブアーティファクトなど)がある場合は、実行しないでください。

#### Railsコンソールから {#from-the-rails-console}

> [!warning]データを変更するコマンドは、正しく実行されない場合、または適切な条件下で実行されない場合に、損傷を引き起こす可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

次のセクションでは、[Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)で内部アプリケーションコマンドを使用して、一括レプリケーションまたは検証を行う方法について説明します。

##### 同期に失敗した1つのコンポーネントのすべてのリソースを同期する {#sync-all-resources-of-one-component-that-failed-to-sync}

次のスクリプト:

- 失敗したすべてのリポジトリをループ処理します。
- 最後の失敗の理由を含む、Geo同期と検証のメタデータを表示します。
- リポジトリの再同期を試みます。
- 失敗が発生した場合、およびその理由を報告します。
- 完了するまでに時間がかかる場合があります。各リポジトリチェックは、結果を報告する前に完了する必要があります。セッションがタイムアウトした場合は、`screen`セッションを開始するか、[Railsランナー](../../../operations/rails_console.md#using-the-rails-runner)と`nohup`を使用して実行するなど、プロセスが実行され続けるように対策を講じてください。

このスクリプトを**on the secondary Geo site**実行します。

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

##### プライマリサイトでチェックサムに失敗したすべてのリソースを再検証する {#reverify-all-resources-that-failed-to-checksum-on-the-primary-site}

システムは、プライマリサイトでチェックサムに失敗したすべてのリソースを自動的に再検証しますが、過剰な量の失敗を回避するために、段階的なバックオフ方式を使用します。

オプションで、たとえば、試行された介入を完了した場合は、より早く手動で再検証をトリガーできます:

1. **プライマリ**サイトのGitLab RailsノードにSSH接続します。
1. [Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)を開きます。
1. `Upload`を[Geoデータ型モデルクラス](#geo-data-type-model-classes)のいずれかに置き換えて、すべてのリソースを`pending verification`としてマークします:

   ```ruby
   Upload.verification_state_table_class.where(verification_state: 3).each_batch do |relation|
     relation.update_all(verification_state: 0)
   end
   ```

## エラー {#errors}

### メッセージ: `The file is missing on the Geo primary site` {#message-the-file-is-missing-on-the-geo-primary-site}

`The file is missing on the Geo primary site`同期の失敗は、最初にセカンダリGeoサイトをセットアップするときによく発生しますが、これはプライマリサイトのデータ不整合が原因です。

GitLabの運用中に、システムエラーまたは人為的エラーが原因で、データの不整合やファイルの欠落が発生する可能性があります。たとえば、インスタンス管理者がローカルファイルシステムの複数のアーティファクトを手動で削除したとします。このような変更はデータベースに適切に伝播されず、不整合が発生します。これらの矛盾は残り、摩擦を引き起こす可能性があります。これらのファイルはデータベースでまだ参照されているために、Geoセカンダリは引き続きこれらのファイルのレプリケートを試行する可能性がありますが、ファイルは存在していません。

> [!note]ローカルからオブジェクトストレージへの最近の移行の場合は、専用の[オブジェクトストレージトラブルシューティングセクション](../../../object_storage.md#inconsistencies-after-migrating-to-object-storage)を参照してください。

#### 矛盾の特定 {#identify-inconsistencies}

ファイルが見つからない場合や矛盾がある場合は、次のような`geo.log`にエントリが表示されることがあります。フィールド`"primary_missing_file" : true`に注意してください:

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

特定のレプリケート可能オブジェクトの同期ステータスを確認すると、同じエラーが**管理者** > **Geo** > **サイト**のUIにも反映されます。このシナリオでは、特定のアップロードが見つかりません:

![すべての失敗したエラーを表示するGeoアップロードレプリケート可能なダッシュボード。](img/geo_uploads_file_missing_v17_11.png)

![ファイルが見つからないエラーを表示するGeoアップロードレプリケート可能なダッシュボード。](img/geo_uploads_file_missing_details_v17_11.png)

#### 不整合をクリーンアップする {#clean-up-inconsistencies}

> [!warning]削除コマンドを発行する前に、最近使用したバックアップを手元に用意しておいてください。

これらのエラーを削除するには、まず、どの特定のリソースが影響を受けているかを特定します。次に、適切な`destroy`コマンドを実行して、すべてのGeoサイトとそのデータベースに削除が確実に伝播されるようにします。前のシナリオに基づいて、**upload**がそれらのエラーを引き起こしており、以下の例として使用されます。

1. 特定された不整合を、それぞれの[Geoモデルクラス](#geo-data-type-model-classes)名にマップします。クラス名は、以下のステップで必要になります。このシナリオでは、アップロードの場合、`Upload`に対応します。
1. **Geo primary site**で[Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)を開始します。
1. 前の手順の*Geoモデルクラス*に基づいて、ファイルが見つからないために検証が失敗したすべてのリソースを照会します。より多くの結果を表示するには、`limit(20)`を調整または削除します。リストされたリソースがUIに表示される失敗したリソースと一致することを確認してください:

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

   - 影響を受けるリソースを回復する必要があると判断した場合は、次のオプション(すべてではありません)を検討して回復できます:
     - セカンダリサイトにオブジェクトがあるかどうかを確認し、手動でプライマリにコピーします。
     - 古いバックアップを調べて、オブジェクトを手動でプライマリサイトにコピーして戻します。
     - いくつかのスポットチェックを行い、レコードを削除しても問題ないかどうかを確認します。たとえば、すべて非常に古いアーティファクトである場合、それらは重要なデータではない可能性があります。

1. 識別されたリソースの`id`を使用して、`destroy`を使用して個別にまたはまとめて適切に削除します。適切な*Geo Model class*名を使用してください。
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

影響を受けるすべてのリソースとGeoデータタイプについて、これらの手順を繰り返します。

### メッセージ: `"Error during verification","error":"File is not checksummable"` {#message-error-during-verificationerrorfile-is-not-checksummable}

エラー`"Error during verification","error":"File is not checksummable"`は、プライマリサイトの不整合が原因で発生します。[Geoプライマリサイトにファイルがない](#message-the-file-is-missing-on-the-geo-primary-site)に記載されている手順に従ってください。

### プライマリGeoサイトでのアップロードの検証に失敗しました {#failed-verification-of-uploads-on-the-primary-geo-site}

いくつかのアップロードの検証が、`verification_checksum = nil`のあるプライマリGeoサイトで失敗した場合、`verification_failure`に``Error during verification: undefined method `underscore' for NilClass:Class``または``The model which owns this Upload is missing.``が含まれている場合、これは孤立したアップロードが原因です。アップロードを所有する親レコード（アップロードの「モデル」）が何らかの理由で削除されましたが、アップロードレコードはまだ存在します。これは通常、アプリケーションのバグが原因で発生します。関連するアップロードレコードをまとめて削除することを忘れて、「モデル」の一括削除を実装することで導入されます。したがって、これらの検証の失敗は検証の失敗ではなく、Postgres内のデータが不良であることによって発生したエラーです。

これらのエラーは、プライマリGeoサイトの`geo.log`ファイルで確認できます。

モデルレコードが存在しないことを確認するには、プライマリGeoサイトでRakeタスクを実行します:

```shell
sudo gitlab-rake gitlab:uploads:check
```

これらのエラーを取り除くために、プライマリGeoサイトでこれらのアップロードレコードを削除するには、[Railsコンソール](../../../operations/rails_console.md)から次のスクリプトを実行します:

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

前のスクリプトは、ドライ実行を実行するためにこのように呼び出すことができる`delete_orphaned_uploads`という名前のメソッドを定義します:

```ruby
delete_orphaned_uploads(dry_run: true)
```

また、孤立したアップロードの行を実際に削除するには、:

```ruby
delete_orphaned_uploads(dry_run: false)
```

### エラー: `Error syncing repository: 13:fatal: could not read Username` {#error-error-syncing-repository-13fatal-could-not-read-username}

`last_sync_failure`エラー`Error syncing repository: 13:fatal: could not read Username for 'https://gitlab.example.com': terminal prompts disabled`は、Geoクローンまたはフェッチリクエスト中にJWT認証が失敗していることを示します。

まず、システムクロックが同期されていることを確認してください。[ヘルスチェックRakeタスク](common.md#health-check-rake-task)を実行するか、セカンダリサイトのすべてのSidekiqノードと、プライマリサイトのすべてのPumaノードで`date`が同じであることを手動で確認します。

システムクロックが同期されている場合、Gitフェッチが2つの別個のHTTPリクエスト間で計算を実行している間に、JWTトークンが期限切れになる可能性があります。[イシュー464101](https://gitlab.com/gitlab-org/gitlab/-/issues/464101)を参照してください。これは、GitLab 17.1.0、17.0.5、および16.11.7で修正されるまで、すべてのGitLabバージョンに存在していました。

この問題が発生しているかどうかを検証するには:

1. [Railsコンソール](../../../operations/rails_console.md#starting-a-rails-console-session)でコードにモンキーパッチを適用して、トークンの有効期間を1分から10分に増やします。同じRailsコンソールで、影響を受けるプロジェクトを再同期します:

   ```ruby
   module Gitlab; module Geo; class BaseRequest
     private
     def geo_auth_token(message)
       signed_data = Gitlab::Geo::SignedData.new(geo_node: requesting_node, validity_period: 10.minutes).sign_and_encode_data(message)

       "#{GITLAB_GEO_AUTH_TOKEN_TYPE} #{signed_data}"
     end
   end;end;end
   ```

1. 同じRailsコンソールで、影響を受けるプロジェクトを再同期します:

   ```ruby
   Project.find_by_full_path('<mygroup/mysubgroup/myproject>').replicator.resync
   ```

1. 同期状態を確認してください:

   ```ruby
   Project.find_by_full_path('<mygroup/mysubgroup/myproject>').replicator.registry
   ```

1. `last_sync_failure`にエラー`fatal: could not read Username`が含まれなくなった場合は、この問題の影響を受けています。状態は`2`になり、同期されたことを意味します。その場合は、修正を含むGitLabバージョンにアップグレードする必要があります。この問題の重大度を軽減する[イシュー466681](https://gitlab.com/gitlab-org/gitlab/-/issues/466681)に同意するかコメントすることもできます。

この問題を回避するには、JWTの有効期限を延長するために、セカンダリサイトのすべてのSidekiqノードにホットパッチを適用する必要があります:

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

1. 修正を含むバージョンにアップグレードしない限り、GitLabをアップグレードするたびにこの回避策を繰り返す必要があります。

### エラー: `Error syncing repository: 13:creating repository: cloning repository: exit status 128` {#error-error-syncing-repository-13creating-repository-cloning-repository-exit-status-128}

このエラーは、同期が正常に実行されないプロジェクトで表示される可能性があります。

リポジトリの作成中に終了コード128が発生した場合、Gitがクローン作成中に致命的なエラーが発生したことを意味します。これは、リポジトリの破損、ネットワークの問題、認証の問題、リソース制限、またはプロジェクトに関連付けられたGitリポジトリがないことが原因である可能性があります。このような失敗の特定の原因に関する詳細については、Gitalyのログに記録されます。

どこから始めればよいかわからない場合は、[コマンドラインで`git fsck`コマンドを手動で実行する](../../../../administration/repository_checks.md#run-a-check-using-the-command-line)ことで、プライマリサイトのソースリポジトリで整合性チェックを実行します。

### エラー: `gitmodulesUrl: disallowed submodule url` {#error-gitmodulesurl-disallowed-submodule-url}

一部のプロジェクトリポジトリは、エラー`Error syncing repository: 13:creating repository: cloning repository: exit status 128`で一貫して同期に失敗します。ただし、一部のリポジトリでは、Gitalyログの特定のエラーメッセージが異なり、 `gitmodulesUrl: disallowed submodule url`と表示されます。このエラーは、リポジトリに`.gitmodules`ファイル内の無効なサブモジュールURLが含まれている場合に発生します。

**根本原因: **この問題は、不正な形式のURLを持つ`.gitmodules`ファイルを含むGitリポジトリ内の**historical commits**によって引き起こされます。この問題は、Geoがプライマリからセカンダリにリポジトリをクローンしようとしたときに実行されるGitの整合性チェック（`git fsck`）中に発生します。

問題はリポジトリのコミット履歴にあります。`.gitmodules`ファイル内のサブモジュールURLには無効な形式が含まれており、パス内で`:`の代わりに`/`を使用しています:

- 無効: `https://example.gitlab.com:group/project.git`
- 有効: `https://example.gitlab.com/group/project.git`

**Why this breaks Geo synchronization:**

1. **Git's strict validation**: GitLab 17.0以降のGitバージョンでは、Gitはクローン操作中に、より厳密な`fsck`チェックを実行します
1. **Historical data persistence**: 現在の`.gitmodules`ファイルが正しい場合でも、Gitはすべての過去のバージョンをリポジトリ内の「blob」として保存します
1. **Clone-time failure**: Geoがリポジトリをクローンしようとすると、Gitの`fsck`は**all objects**を調べ、不正な形式のURLが見つかると失敗します
1. **Complete sync failure**: クローン操作全体が失敗し、リポジトリがセカンダリサイトに到達するのを防ぎます

**重要:**問題のあるデータはリポジトリのGit履歴に存在し、ファイルの現在のバージョンにのみ存在するわけではないため、現在の`.gitmodules`ファイルを編集しても、この問題は**not**されません。

この問題はGitLab 17.0以降で確認されており、より厳密なリポジトリ整合性チェックの結果です。この新しい動作は、このチェックが追加されたGit自体の変更の結果です。これは、GitLab GeoまたはGitalyに固有のものではありません。詳細については、[イシュー468560](https://gitlab.com/gitlab-org/gitlab/-/issues/468560)を参照してください。

#### 回避策 {#workaround}

1. **Backup projects**

   続行する前に、[プロジェクトエクスポートオプション](../../../../user/project/settings/import_export.md)を使用して、プロジェクトを事前にバックアップしてください。

1. **Identify problematic blob IDs**

   影響を受ける各プロジェクトについて、次のいずれかの方法を使用して、問題のあるblobIDを識別します:

   - `git fsck`を使用します: リポジトリをクローンし、 `git fsck`を実行して問題を確認します:

     ```shell
     git clone https://example.gitlab.com/group/project.git
     cd project
     git fsck
     ```

     出力には、問題のあるblobが表示されます:

     ```plaintext
     Checking object directories: 100% (256/256), done.
     error in blob <SHA>: gitmodulesUrl: disallowed submodule url: https://example.gitlab.com:group/project.git
     Checking objects: 100% (12/12), done.
     ```

   - Gitalyログを確認します。`gitmodulesUrl`を含むエラーメッセージを探して、特定のblob SHAを見つけます。

1. **blobを消去する**

   影響を受ける各プロジェクトについて、前の手順で識別された[問題のあるblobIDを削除します](../../../../user/project/repository/repository_size.md#remove-blobs)。

   **Important limitation:**これらのリポジトリのいずれかがフォークネットワークの一部である場合、blobの削除方法は機能しない可能性があります（オブジェクトプールに含まれるblobはこの方法では削除できません）。

1. **Fix .gitmodules invalid URLs if required**

   影響を受ける各リポジトリで`.gitmodules`ファイルの状態を確認します

   `.gitmodules`に`https://example.gitlab.com:foo/bar.git`の代わりに`https://example.gitlab.com/foo/bar.git`のような無効なURLがまだ含まれている場合、顧客は次のことを行う必要があります:

   - `.gitmodules`ファイル内のURLを修正します
   - 有効なURLでコミットをプッシュします

> [!warning]修正後、影響を受けるプロジェクトで作業しているすべてのデベロッパーは、現在のローカルコピーを削除し、新しいリポジトリをクローンする必要があります。そうしないと、変更をプッシュするときに、問題のあるblobが再度導入される可能性があります。

### エラー: 正確に3時間後の`fetch remote: signal: terminated: context deadline exceeded` {#error-fetch-remote-signal-terminated-context-deadline-exceeded-at-exactly-3-hours}

Gitリポジトリの同期中にGitフェッチが正確に3時間後に失敗した場合:

1. `/etc/gitlab/gitlab.rb`を編集して、Gitタイムアウトをデフォルトの10800秒から増やします:

   ```ruby
   # Git timeout in seconds
   gitlab_rails['gitlab_shell_git_timeout'] = 21600
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### レジストリレプリケーションの設定時にセカンダリでエラー`Failed to open TCP connection to localhost:5000` {#error-failed-to-open-tcp-connection-to-localhost5000-on-secondary-when-configuring-registry-replication}

セカンダリサイトでコンテナレジストリレプリケーションを構成するときに、次のエラーが発生する場合があります:

```plaintext
Failed to open TCP connection to localhost:5000 (Connection refused - connect(2) for \"localhost\" port 5000)"
```

これは、セカンダリサイトでコンテナレジストリが有効になっていない場合に発生します。これを修正するには、コンテナレジストリが[セカンダリサイトで有効](../../../packages/container_registry.md#enable-the-container-registry)になっていることを確認してください。[Let's Encryptインテグレーションが無効](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually)になっている場合、コンテナレジストリも無効になり、[手動で構成](../../../packages/container_registry.md#configure-container-registry-under-its-own-domain)する必要があります。

### エラー: `Verification timed out after 28800` {#error-verification-timed-out-after-28800}

**ありうる根本原因:** レジストリレコードの重複が、さまざまなレジストリタイプ間で検証の競合を引き起こしています。

**Diagnosis:**

セカンダリサイトの異なるタイプ間で重複したレジストリがないか確認します:

```ruby
# Check for duplicate upload registries
upload_ids = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').pluck(:file_id)
puts "Duplicate upload IDs count: #{upload_ids.size}"
puts 'Duplicate Upload IDs:', upload_ids

# Check for duplicate job artifact registries
artifact_ids = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').pluck(:artifact_id)
puts "Duplicate artifact IDs count: #{artifact_ids.size}"
puts 'Duplicate Artifact IDs:', artifact_ids

# Check for duplicate package file registries
package_file_ids = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').pluck(:package_file_id)
puts "Duplicate package file IDs count: #{package_file_ids.size}"
puts 'Duplicate Package File IDs:', package_file_ids

# Check for duplicate LFS object registries
lfs_object_ids = Geo::LfsObjectRegistry.group(:lfs_object_id).having('COUNT(*) > 1').pluck(:lfs_object_id)
puts "Duplicate LFS object IDs count: #{lfs_object_ids.size}"
puts 'Duplicate LFS Object IDs:', lfs_object_ids

# Check for duplicate pages deployment registries
pages_deployment_ids = Geo::PagesDeploymentRegistry.group(:pages_deployment_id).having('COUNT(*) > 1').pluck(:pages_deployment_id)
puts "Duplicate pages deployment IDs count: #{pages_deployment_ids.size}"
puts 'Duplicate Pages Deployment IDs:', pages_deployment_ids

# Check for duplicate terraform state version registries
terraform_state_ids = Geo::TerraformStateVersionRegistry.group(:terraform_state_version_id).having('COUNT(*) > 1').pluck(:terraform_state_version_id)
puts "Duplicate terraform state version IDs count: #{terraform_state_ids.size}"
puts 'Duplicate Terraform State Version IDs:', terraform_state_ids
```

**Resolution:**

1. 影響を受けるタイプごとに、重複したレジストリエントリを削除します:

   ```ruby
   # Remove duplicate upload registries
   upload_ids = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').pluck(:file_id)
   if upload_ids.any?
     Geo::UploadRegistry.where(file_id: upload_ids).delete_all
     puts "Removed #{upload_ids.size} duplicate upload registry entries"
   end

   # Remove duplicate job artifact registries
   artifact_ids = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').pluck(:artifact_id)
   if artifact_ids.any?
     Geo::JobArtifactRegistry.where(artifact_id: artifact_ids).delete_all
     puts "Removed #{artifact_ids.size} duplicate job artifact registry entries"
   end

   # Remove duplicate package file registries
   package_file_ids = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').pluck(:package_file_id)
   if package_file_ids.any?
     Geo::PackageFileRegistry.where(package_file_id: package_file_ids).delete_all
     puts "Removed #{package_file_ids.size} duplicate package file registry entries"
   end

   # Remove duplicate LFS object registries
   lfs_object_ids = Geo::LfsObjectRegistry.group(:lfs_object_id).having('COUNT(*) > 1').pluck(:lfs_object_id)
   if lfs_object_ids.any?
     Geo::LfsObjectRegistry.where(lfs_object_id: lfs_object_ids).delete_all
     puts "Removed #{lfs_object_ids.size} duplicate LFS object registry entries"
   end

   # Remove duplicate pages deployment registries
   pages_deployment_ids = Geo::PagesDeploymentRegistry.group(:pages_deployment_id).having('COUNT(*) > 1').pluck(:pages_deployment_id)
   if pages_deployment_ids.any?
     Geo::PagesDeploymentRegistry.where(pages_deployment_id: pages_deployment_ids).delete_all
     puts "Removed #{pages_deployment_ids.size} duplicate pages deployment registry entries"
   end

   # Remove duplicate terraform state version registries
   terraform_state_ids = Geo::TerraformStateVersionRegistry.group(:terraform_state_version_id).having('COUNT(*) > 1').pluck(:terraform_state_version_id)
   if terraform_state_ids.any?
     Geo::TerraformStateVersionRegistry.where(terraform_state_version_id: terraform_state_ids).delete_all
     puts "Removed #{terraform_state_ids.size} duplicate terraform state version registry entries"
   end
   ```

1. すべてのレジストリタイプでクリーンアップを検証します:

   ```ruby
   # Verify no remaining duplicates
   upload_duplicates = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').count
   artifact_duplicates = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').count
   package_duplicates = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').count
   lfs_duplicates = Geo::LfsObjectRegistry.group(:lfs_object_id).having('COUNT(*) > 1').count
   pages_duplicates = Geo::PagesDeploymentRegistry.group(:pages_deployment_id).having('COUNT(*) > 1').count
   terraform_duplicates = Geo::TerraformStateVersionRegistry.group(:terraform_state_version_id).having('COUNT(*) > 1').count

   puts "Remaining duplicates:"
   puts "  Uploads: #{upload_duplicates.size}"
   puts "  Job Artifacts: #{artifact_duplicates.size}"
   puts "  Package Files: #{package_duplicates.size}"
   puts "  LFS Objects: #{lfs_duplicates.size}"
   puts "  Pages Deployments: #{pages_duplicates.size}"
   puts "  Terraform State Versions: #{terraform_duplicates.size}"
   ```

### エラー: `Checksum does not match the primary checksum` {#error-checksum-does-not-match-the-primary-checksum}

**ありうる根本原因:** チェックサムの不整合を引き起こすリポジトリまたはコンテナレジストリの検証間隔の変更。

**Diagnosis:**

セカンダリで失敗したリポジトリまたはコンテナレジストリを確認します:

```ruby
failed_repos = Geo::ProjectRepositoryRegistry.failed.limit(100)
failed_repos.each do |repo|
  puts "Project ID: #{repo.project_id}"
  puts "Primary checksum: #{repo.verification_checksum_mismatched}"
  puts "Secondary checksum: #{repo.verification_checksum}"
  puts "Error: #{repo.last_sync_failure}"
  puts "---"
end
```

```ruby
failed_container_repos = Geo::ContainerRepositoryRegistry.failed.limit(100)
failed_container_repos.each do |repo|
  puts "Container Repo Id: #{repo.model_record_id}"
  puts "Primary checksum: #{repo.verification_checksum_mismatched}"
  puts "Secondary checksum: #{repo.verification_checksum}"
  puts "Error: #{repo.last_sync_failure}"
  puts "---"
end
```

**Resolution:**

特定のプロジェクトまたはコンテナレジストリに対して、プライマリで再検証を強制します:

```ruby
project_ids = [1, 2, 3] # Replace with actual failing project IDs

project_ids.each do |project_id|
  project = Project.find(project_id)
  puts "Reverifying project: #{project.full_path}"

  project_state = project.project_state
  project_state.update!(verification_state: 0)

  puts "Project #{project_id} marked for reverification"
end
```

```ruby
container_repo_ids = [1, 2, 3]

container_repo_ids.each do |repo_id|
  container_repo = ContainerRepository.find(repo_id)
  puts "Reverifying container repository: #{container_repo.path}"

  state = container_repo.container_repository_state
  state.update!(verification_state: 0)

  puts "Container Repo #{repo_id} marked for reverification"
end
```

### `Error during verification: File is not checksummable`のオブジェクトタイプ固有のトラブルシューティング {#object-type-specific-troubleshooting-for-error-during-verification-file-is-not-checksummable}

Geoデータタイプが異なると、固有の特性と一般的な失敗パターンがあります。このセクションでは、特定のオブジェクトタイプを対象としたトラブルシューティングについて説明します。

#### アップロード {#uploads}

**Diagnosis:**

ファイルが欠落しているアップロードを識別します:

```ruby
checksummable_failures = Upload.verification_failed
                                .where("verification_failure LIKE '%File is not checksummable%'")

puts "Found #{checksummable_failures.count} uploads with missing files"

# Adjust 'limit' to count
checksummable_failures.limit(5).each_with_index do |record, index|
  puts "Record #{index + 1}:"
  puts "  ID: #{record.id}"
  puts "  Path: #{record.path}"
  puts "  Model: #{record.model_type} (ID: #{record.model_id})"
  puts "  Created: #{record.created_at}"
  puts "---"
end
```

**Resolution:**

> [!warning]アップロードレコードを削除する前に、最新の動作するバックアップがあることを確認してください。これらのアップロードを安全に削除できることを確認するために、チームと調整します。

確認後、問題のあるアップロードを削除します:

```ruby
# Remove individual upload
Upload.find(55).destroy

# Or remove all uploads with missing files (use with extreme caution)
Upload.verification_failed.where("verification_failure LIKE '%File is not checksummable%'").destroy_all
```

#### ページデプロイ {#pages-deployments}

**Diagnosis:**

問題のあるページデプロイを調べます:

```ruby
checksummable_failures = PagesDeployment.verification_failed
                                        .where("verification_failure LIKE '%File is not checksummable%'")

checksummable_failures.each_with_index do |record, index|
  puts "Record #{index + 1}:"
  puts "  ID: #{record.id}"
  puts "  Project: #{record.project.full_path}"
  puts "  Created: #{record.created_at}"
  puts "  File exists: #{record.file.exists?}"
  puts "---"
end
```

**Resolution:**

デプロイを安全に削除できることをチームに確認した後:

```ruby
failed_ids = [21875, 21907, 21992] # Replace with actual IDs
PagesDeployment.where(id: failed_ids).destroy_all
puts "Removed #{failed_ids.size} problematic pages deployments"
```

#### LFSオブジェクト {#lfs-objects}

**Diagnosis:**

問題のあるLFSオブジェクトを調べます:

```ruby
checksummable_failures = LfsObject.verification_failed
                                  .where("verification_failure LIKE '%File is not checksummable%'")

checksummable_failures.each_with_index do |record, index|
  puts "Record #{index + 1}:"
  puts "  OID: #{record.oid}"
  puts "  Size: #{record.size} bytes"
  puts "  File Store: #{record.file_store}"
  puts "  Created: #{record.created_at}"

  # Show associated projects
  associations = record.lfs_objects_projects.includes(:project)
  puts "  Associated projects (#{associations.count}):"
  associations.each do |assoc|
    project = assoc.project
    if project
      puts "    - #{project.full_path}"
    else
      puts "    - Project ID: #{assoc.project_id} (not found)"
    end
  end
  puts "---"
end
```

**Resolution:**

> [!warning]LFSオブジェクトを削除すると、それらを参照するすべてのプロジェクトに影響します。削除する前に、バックアップを用意し、プロジェクトメンテナーと調整してください。

ファイルが欠落しているLFSオブジェクトを削除します:

```ruby
def destroy_lfs_not_checksummable(dry_run: true)
  lfs_objects = LfsObject.verification_failed.where("verification_failure like '%File is not checksummable%'")
  puts "Found #{lfs_objects.count} LFS objects that failed verification with 'File is not checksummable'."

  if dry_run
    puts "DRY RUN - No changes made"
    lfs_objects.each { |obj| puts "Would remove: OID #{obj.oid}, Size: #{obj.size}" }
    return
  end

  puts "Enter 'y' to continue with deletion: "
  prompt = STDIN.gets.chomp
  if prompt != 'y'
    puts "Exiting without action..."
    return
  end

  puts "Destroying all..."
  lfs_objects.each do |lfs_object|
    lfs_object.lfs_objects_projects.destroy_all
    lfs_object.destroy!
  end
  puts "Done!"
end

# Run in dry run mode first
destroy_lfs_not_checksummable(dry_run: true)
```

#### ジョブアーティファクト {#job-artifacts}

**Diagnosis:**

ファイルが欠落しているアーティファクトがないか確認します:

```ruby
failed_artifacts = Ci::JobArtifact.verification_failed.where("verification_failure LIKE '%File is not checksummable%'")

failed_artifacts.each do |registry|
  artifact = Ci::JobArtifact.find_by(id: registry.id)
  if artifact
    puts "Artifact ID: #{artifact.id}"
    puts "Job ID: #{artifact.job_id}"
    puts "Project ID: #{artifact.project_id}"
    puts "File exists: #{artifact.file.exists?}"
    puts "File path: #{artifact.file.path}"
  else
    puts "Artifact ID #{artifact.id} not found in database"
  end
  puts "---"
end
```

**Resolution:**

ファイルが欠落しているアーティファクトをクリーンアップします:

```ruby
def cleanup_missing_artifacts(dry_run: true)
  missing_file_artifacts = []

  Ci::JobArtifact.find_each do |artifact|
    unless artifact.file.exists?
      missing_file_artifacts << artifact.id
      puts "Missing file for artifact #{artifact.id}" if dry_run
    end
  end

  puts "Found #{missing_file_artifacts.size} artifacts with missing files"

  unless dry_run
    Ci::JobArtifact.where(id: missing_file_artifacts).destroy_all
    puts "Removed #{missing_file_artifacts.size} artifacts with missing files"
  end
end

# Run in dry run mode first
cleanup_missing_artifacts(dry_run: true)
```

#### パイプラインアーティファクト {#pipeline-artifacts}

**Diagnosis:**

ファイルが欠落しているアーティファクトがないか確認します:

```ruby
failed_pipeline_artifacts = Ci::PipelineArtifact.verification_failed.where("verification_failure LIKE '%checksummable%'")

failed_pipeline_artifacts.each do |registry|
  artifact = Ci::PipelineArtifact.find_by(id: registry.id)
  if artifact
    puts "Artifact ID: #{artifact.id}"
    puts "Pipeline ID: #{artifact.pipeline_id}"
    puts "Project ID: #{artifact.project_id}"
    puts "File exists: #{artifact.file.exists?}"
    puts "File path: #{artifact.file.path}"
  else
    puts "Artifact ID #{artifact.id} not found in database"
  end
  puts "---"
end
```

**Resolution:**

ファイルが欠落しているパイプラインアーティファクトを削除します:

```ruby
def destroy_pipeline_artifacts_not_checksummable
  artifacts = Ci::PipelineArtifact.verification_failed.where("verification_failure like '%File is not checksummable%'")
  puts "Found #{artifacts.count} pipeline artifacts that failed verification with 'File is not checksummable'."
  puts "Enter 'y' to continue: "
  prompt = STDIN.gets.chomp
  if prompt != 'y'
    puts "Exiting without action..."
    return
  end

  puts "Destroying all..."
  artifacts.destroy_all
  puts "Done!"
end

destroy_pipeline_artifacts_not_checksummable
```

### エラー: `Projects - Error during verification: Repository does not exist` {#error-projects---error-during-verification-repository-does-not-exist}

**根本原因:** Gitリポジトリがないプロジェクトでは、検証に失敗します。

**Symptoms:**

- プロジェクトの検証中に「リポジトリが存在しません」というエラーが表示されます
- 正当な理由でリポジトリがないプロジェクトの場合、Geo UIに誤ったエラーレポートが表示されます
- 存在しないリポジトリでの無駄な同期試行

**回避策:**

存在しない場合に、プライマリにプロジェクトリポジトリを作成します:

```ruby
puts "Found #{Project.verification_failed.count} project repos failed to checksum"
Project.verification_failed.find_each do |p|
  puts "#{p.full_path} #{p.ensure_repository.inspect}"
end
```

### エラー: `Expected(200) <=> Actual(403 Forbidden)` {#error-expected200--actual403-forbidden}

**根本原因:** S3 APIが404ではなく403を返す原因となる、`ListBucket`権限がありません。

**Symptoms:**

- S3エンドポイントを使用したログの403エラー
- S3バケットへのHEADリクエストの失敗
- オブジェクトストレージをバックアップしたデータタイプの同期の失敗

**Resolution:**

これには、インフラストラクチャチームの介入が必要になり、GitLabで使用されるS3 IAMポリシーに`ListBucket`権限を追加する必要があります。

### メッセージ: `Synchronization failed - Error syncing repository` {#message-synchronization-failed---error-syncing-repository}

> [!warning]この問題の影響を受ける大規模なリポジトリがある場合、再同期には時間がかかり、Geoサイト、ストレージ、およびネットワークシステムに大きな負荷がかかる可能性があります。

次のエラーメッセージは、リポジトリの同期中に整合性チェックエラーが発生したことを示しています:

```plaintext
Synchronization failed - Error syncing repository [..] fatal: fsck error in packed object
```

いくつかの問題がこのエラーをトリガーする可能性があります。たとえば、メールアドレスに関する問題:

```plaintext
Error syncing repository: 13:fetch remote: "error: object <SHA>: badEmail: invalid author/committer line - bad email
   fatal: fsck error in packed object
   fatal: fetch-pack: invalid index-pack output
```

このエラーをトリガーする可能性のあるもう1つの問題は`object <SHA>: hasDotgit: contains '.git'`です。すべてのリポジトリで複数の問題が発生している可能性があるため、特定のエラーを確認してください。

2番目の同期エラーは、リポジトリチェックの問題によっても引き起こされる可能性があります:

```plaintext
Error syncing repository: 13:Received RST_STREAM with error code 2.
```

これらのエラーは、[失敗したすべてのリポジトリをすぐに同期する](#sync-all-resources-of-one-component-that-failed-to-sync)ことで確認できます。

整合性エラーの原因となっている不正な形式のオブジェクトを削除するには、リポジトリの履歴を書き換える必要があります。これは通常、オプションではありません。

これらの整合性チェックを無視するには、これらの`git fsck`の問題を無視するように、**on the secondary Geo sites** Gitalyを再構成します。次の構成例:

- GitLab 16.0から必須となった[新しい構成構造を使用](../../../../update/versions/gitlab_16_changes.md#gitaly-configuration-structure-change)します。
- 5つの一般的なチェックエラーを無視します。

Gitalyの[ドキュメントには、](../../../gitaly/consistency_checks.md)Gitのその他のチェックエラーやGitLabの以前のバージョンに関する詳細が記載されています。

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

包括的な`fsck`エラーの一覧は、[Gitドキュメント](https://git-scm.com/docs/git-fsck#_fsck_messages)に記載されています。

GitLab 16.1バージョン以降では、これらのイシューの一部を解決できる可能性のある[拡張機能](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5879)が含まれています。

[Gitaly issue 5625](https://gitlab.com/gitlab-org/gitaly/-/issues/5625)では、Geoが、ソースリポジトリに問題のあるコミットが含まれている場合でも、リポジトリをレプリケートすることを保証することを提案しています。

### 関連エラー`does not appear to be a git repository` {#related-error-does-not-appear-to-be-a-git-repository}

次のログメッセージとともに、エラーメッセージ`Synchronization failed - Error syncing repository`が表示されることもあります。このエラーは、期待されるGeoリモートが`.git/config`ファイルシステム上のsecondary Geoサイトのリポジトリのファイルに存在しないことを示しています:

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

これを解決するには、次の手順に従います:

1. secondary GeoサイトのWebインターフェースでサインインします。

1. [`.git`フォルダー](../../../repository_storage_paths.md#translate-hashed-storage-paths)をバックアップします。

1. オプション。それらのIDのいくつかが、既知のGeoレプリケーションの失敗が発生しているプロジェクトに実際に対応しているかどうかを[スポットチェック](../../../logs/log_parsing.md#find-all-projects-affected-by-a-fatal-git-problem)します。`fatal: 'geo'`を`grep`用語として使用し、次のAPIコールを使用します:

   ```shell
   curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<first_failed_geo_sync_ID>"
   ```

1. [Railsコンソール](../../../operations/rails_console.md)を起動して、以下を実行します:

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

1. 各プロジェクトの新しい同期を実行するには、次のコマンドを実行します:

   ```ruby
   failed_project_registries.each do |registry|
     registry.replicator.sync
     puts "Sync initiated for registry ID: #{registry.id}, Project ID: #{registry.project_id}"
   end
   ```

## バックフィル中の失敗 {#failures-during-backfill}

[バックフィル](../../_index.md#backfill)中に、失敗はバックフィルキューの最後に再試行されるようにスケジュールされるため、これらの失敗はバックフィルが完了した**後**にのみ解消されます。

## メッセージ: `unexpected disconnect while reading sideband packet` {#message-unexpected-disconnect-while-reading-sideband-packet}

不安定なネットワーキング状態により、プライマリサイトから大きなリポジトリデータをフェッチしようとすると、Gitalyが失敗する可能性があります。これらの状態により、次のエラーが発生する可能性があります:

```plaintext
curl 18 transfer closed with outstanding read data remaining & fetch-pack:
unexpected disconnect while reading sideband packet
```

このエラーは、リポジトリをサイト間でゼロからレプリケートする必要がある場合に発生しやすくなります。

Geoは数回再試行しますが、ネットワークの同期がネットワークのヒカップによって一貫して中断される場合は、`rsync`などの別の方法を使用して`git`を回避し、Geoによるレプリケーションに失敗したリポジトリの初期コピーを作成できます。

各失敗リポジトリを個別に転送し、各転送後に一貫性をチェックすることをお勧めします。プライマリサイトから[影響を受ける各リポジトリを`rsync`を別のサーバーにプルする手順に従って、secondaryサイトに転送します](../../../operations/moving_repositories.md#use-rsync-to-another-server)。

## Geosecondaryサイトでリポジトリチェックの失敗を見つける {#find-repository-check-failures-in-a-geo-secondary-site}

> [!note]すべてのリポジトリデータ型は、GitLab 16.3でGeo Self-Service Frameworkに移行されました。[Geo Self-Service Frameworkにこの機能を実装し直すためのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/426659)があります。

GitLab 16.2以前の場合:

[すべてのプロジェクトで有効になっている](../../../repository_checks.md#enable-repository-checks-for-all-projects)場合、[リポジトリチェック](../../../repository_checks.md)もGeosecondaryサイトで実行されます。メタデータは、Geoトラッキングデータベースに保存されます。

Geosecondaryサイトでのリポジトリチェックの失敗は、必ずしもレプリケーションの問題を意味するものではありません。これらの失敗を解決するための一般的なアプローチを次に示します。

1. 以下に示す影響を受けるリポジトリと、[記録されたエラー](../../../repository_checks.md#what-to-do-if-a-check-failed)を検索します。
1. 特定のエラーを診断してみてください`git fsck`。可能性のあるエラーの範囲は広いため、検索エンジンに入力してみてください。
1. 影響を受けるリポジトリの一般的な機能をテストします。secondaryからプルし、ファイルを表示します。
1. プライマリサイトのリポジトリのコピーに同一のエラーがあるかどうかを確認します`git fsck`。フェイルオーバーを計画している場合は、secondaryサイトにプライマリサイトと同じ情報があることを優先することを検討してください。プライマリのバックアップがあることを確認し、[計画されたフェイルオーバーのガイドライン](../../disaster_recovery/planned_failover.md)に従ってください。
1. プライマリにプッシュし、変更がsecondaryサイトにレプリケートされるかどうかを確認します。
1. レプリケーションが自動的に機能しない場合は、リポジトリを同期を手動で試してください。

[Railsコンソールセッションを開始](../../../operations/rails_console.md#starting-a-rails-console-session)して、次の基本的なトラブルシューティングの手順を実行します。

> [!warning]データを変更するコマンドは、正しく実行されない場合、または適切な条件下で実行されない場合に、損害を引き起こす可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

### リポジトリチェックに失敗したリポジトリの数を取得します {#get-the-number-of-repositories-that-failed-the-repository-check}

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true).count
```

### リポジトリチェックに失敗したリポジトリを見つける {#find-the-repositories-that-failed-the-repository-check}

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true)
```

## Gitaly Clusterからリポジトリを完全に削除して再同期する {#hard-delete-a-repository-from-gitaly-cluster-and-resync}

> [!warning]この手順は危険で、強引です。他のトラブルシューティング方法が失敗した場合にのみ、最後の手段として使用してください。この手順により、リポジトリが再同期されるまで、一時的なデータ損失が発生します。

この手順では、secondaryサイトのGitalyクラスターからリポジトリを削除し、再度同期します。リスクを理解している場合にのみ、使用を検討する必要があります。また、次の条件がすべて当てはまる場合にのみ使用する必要があります:

- プライマリサイト上のリポジトリで`git clone`が機能しています。
- `p.replicator.sync_repository`(ここで、`p`はプロジェクトモデルインスタンスです)は、secondaryサイトでGitalyエラーを記録します。
- 標準のトラブルシューティングで問題が解決しませんでした。

前提条件: 

- secondaryサイトのRailsコンソールとPraefectノードの両方への管理アクセス権があることを確認してください。
- リポジトリがプライマリサイトでアクセス可能で、正しく機能していることを確認します。
- この手順を元に戻す必要がある場合に備えて、バックアップ計画を用意しておいてください。

これを行うには、次の手順を実行します:

1. secondaryサイトのRailsコンソールにサインインします。
1. プロジェクトモデルをインスタンス化し、次のいずれかのオプションを使用して、変数`p`に保存します:

   - 影響を受けるプロジェクトIDがわかっている場合 (たとえば、`60087`):

     ```ruby
     p = Project.find(60087)
     ```

   - GitLabで影響を受けるプロジェクトパスがわかっている場合 (たとえば、`my-group/my-project`):

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

1. secondaryサイトのPraefectノードにSSHで接続します。
1. [Gitalyクラスターからリポジトリを手動で削除する](../../../gitaly/praefect/recovery.md#manually-remove-repositories)手順に従って、前の手順で書き留めた仮想ストレージと相対パスを使用します。

   secondaryサイトのGitリポジトリが削除されました。

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

Gitリポジトリがプライマリサイトからsecondaryサイトに再同期されるようになりました。Geo管理インターフェースを通じて同期処理を監視するか、Railsコンソールでリポジトリの同期ステータスを確認します。

## インフラストラクチャとパフォーマンスに関する考慮事項 {#infrastructure-and-performance-considerations}

一部の同期の問題は、インフラストラクチャレベルの問題またはパフォーマンスの制約によって発生します。

### 並行処理の高い問題 {#high-concurrency-issues}

過度のGeo検証並行処理は、データベースを圧倒し、同期の失敗を引き起こす可能性があります。

**Symptoms:**

- データベース接続タイムアウト
- データベースサーバーでのCPU使用率が高い
- インフラストラクチャが正常であるにもかかわらず、同期の処理が遅い

**Diagnosis and Resolution:**

[UI](../tuning.md#changing-the-syncverification-concurrency-values)を使用して、**プライマリ**サイトの並行処理設定を削減します

## 手動同期ステータスの更新 {#manual-sync-status-updates}

場合によっては、根本的な問題を解決した後、オブジェクト型を手動で同期済みとしてマークする必要がある場合があります。このシナリオは、secondaryサイトのオブジェクトバケットに手動でファイルをアップロードすることでしか問題を修正できない場合に発生します。通常、その操作は必要ありませんが、バージョンのバグが原因で発生する可能性があります。以下に、それらの手動でアップロードされたオブジェクト型（この場合はアップロード）を同期済みとしてマークする方法を示します。

> [!warning]ファイルが実際にsecondaryサイトに存在し、アクセス可能であることを確認した場合にのみ、オブジェクトを同期済みとしてマークしてください。

```ruby
def mark_upload_synced(upload_id)
  upload = Upload.find(upload_id)
  registry = upload.replicator.registry
  registry.start
  registry.synced!
  puts "Marked upload #{upload_id} as synced"
end

# Mark specific uploads as synced
upload_ids = [107221, 107320] # Replace with actual IDs
upload_ids.each { |id| mark_upload_synced(id) }
```

## Geo**セカンダリ**サイトのレプリケーションのリセット {#resetting-geo-secondary-site-replication}

壊れた状態の**セカンダリ**サイトを取得し、レプリケーションの状態をリセットして最初からやり直したい場合は、いくつかの手順が役立ちます:

1. SidekiqとGeoログカーソルを停止します。

   Sidekiqを正常に停止させることは可能ですが、新しいジョブを取得するのを停止させ、現在のジョブが処理を終了するまで待機させます。

   最初のフェーズでは**SIGTSTP**キルシグナルを送信し、すべてのジョブが完了したら**SIGTERM**を送信する必要があります。それ以外の場合は、`gitlab-ctl stop`コマンドを使用します。

   ```shell
   gitlab-ctl status sidekiq
   # run: sidekiq: (pid 10180) <- this is the PID you will use
   kill -TSTP 10180 # change to the correct PID

   gitlab-ctl stop sidekiq
   gitlab-ctl stop geo-logcursor
   ```

   [Sidekiqログ](../../../logs/_index.md#sidekiq-logs)を監視して、Sidekiqジョブの処理がいつ終了したかを確認できます:

   ```shell
   gitlab-ctl tail sidekiq
   ```

1. GitalyとGitaly Cluster（Praefect）データをクリアします。

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```shell
   mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
   sudo gitlab-ctl reconfigure
   ```

   {{< /tab >}}

   {{< tab title="Gitalyクラスター（Praefect）" >}}

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

   1. 各Gitalyノードからリポジトリデータの名前を変更/削除します:

      ```shell
      sudo mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
      sudo gitlab-ctl reconfigure
      ```

   1. Praefectデプロイノードで、データベースを設定するために再構成を実行します:

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

   > [!note]ディスク容量を節約するために、今後必要ないと判断したらすぐに`/var/opt/gitlab/git-data/repositories.old`を削除することをお勧めします。

1. オプション。他のデータフォルダーの名前を変更し、新しいフォルダーを作成します。

   > [!warning] **プライマリ**サイトから削除された**セカンダリ**サイトにファイルがまだ存在する可能性がありますが、この削除は反映されていません。この手順をスキップすると、これらのファイルはGeo**セカンダリ**サイトから削除されません。

   （ファイルの添付ファイル、アバター、またはLFSオブジェクトなどの）アップロードされたコンテンツは、次のパスのいずれかのサブフォルダーに保存されます:

   - `/var/opt/gitlab/gitlab-rails/shared`
   - `/var/opt/gitlab/gitlab-rails/uploads`

   それらのすべての名前を変更するには:

   ```shell
   gitlab-ctl stop

   mv /var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared.old
   mkdir -p /var/opt/gitlab/gitlab-rails/shared

   mv /var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads.old
   mkdir -p /var/opt/gitlab/gitlab-rails/uploads

   gitlab-ctl start postgresql
   gitlab-ctl start geo-postgresql
   ```

   フォルダーを再作成し、権限と所有権が正しいことを確認するために再構成します:

   ```shell
   gitlab-ctl reconfigure
   ```

1. トラッキングデータベースをリセットします。

   > [!warning]オプションの手順3をスキップした場合は、`geo-postgresql`サービスと`postgresql`サービスの両方が実行されていることを確認してください。

   ```shell
   gitlab-rake db:drop:geo DISABLE_DATABASE_ENVIRONMENT_CHECK=1   # on a secondary app node
   gitlab-ctl reconfigure     # on the tracking database node
   gitlab-rake db:migrate:geo # on a secondary app node
   ```

1. 以前に停止したサービスを再起動します。

   ```shell
   gitlab-ctl start
   ```
