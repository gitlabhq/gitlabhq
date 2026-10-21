---
stage: GitLab Dedicated
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geoデータの再同期と再検証
description: "UIまたはRailsコンソールから、個々のGeoコンポーネントまたは複数のコンポーネントを一括で手動で再同期および再検証します。"
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

再同期と再検証は、標準的な運用アクションです。これらを使用すると、自動再試行間隔を待たずにレプリケーションまたは検証を再試行したり、レプリケーションまたは検証の失敗後に復旧したりできます。

[Railsコンソール](../../operations/rails_console.md#starting-a-rails-console-session)でセカンダリGeoサイトにいる場合は、以下を実行できます:

- [個々のコンポーネントを再度同期して再検証する](#resync-and-reverify-individual-components)
- [複数のコンポーネントを再度同期して再検証する](#resync-and-reverify-multiple-components)

## 個々のコンポーネントの再同期と再検証 {#resync-and-reverify-individual-components}

セカンダリサイトで、**管理者** > **Geo** > **レプリケーション**にアクセスして、個々のアイテムの再同期または再検証を強制します。

ただし、これでうまくいかない場合は、Railsコンソールを使用して同じアクションを実行できます。次のセクションでは、[Railsコンソール](../../operations/rails_console.md#starting-a-rails-console-session)で内部アプリケーションコマンドを使用して、個々のレコードのレプリケーションまたは検証を同期的または非同期的に行う方法について説明します。

### Replicatorインスタンスの取得 {#obtaining-a-replicator-instance}

> [!warning]
> データを変更するコマンドは、正しく実行されない場合や適切な条件下で実行されない場合、損害を引き起こす可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

同期または検証操作を実行する前に、Replicatorインスタンスを取得する必要があります。

まず、実行したい操作に応じて、プライマリサイトまたはセカンダリサイトで[Railsコンソールセッションを開始](../../operations/rails_console.md#starting-a-rails-console-session)します。

プライマリサイト:

- リソースをチェックサムできます

セカンダリサイト:

- リソースを同期できます
- リソースをチェックサムし、そのチェックサムをプライマリサイトのチェックサムと照合して検証できます

次に、次のスニペットのいずれかを実行して、Replicatorインスタンスを取得します。

#### モデルレコードのIDを指定した場合 {#given-a-model-records-id}

- `123`を実際のIDに置き換えます。
- `Packages::PackageFile`を[Geoデータ型モデルクラス](#geo-data-type-model-classes)のいずれかに置き換えます。

```ruby
model_record = Packages::PackageFile.find_by(id: 123)
replicator = model_record.replicator
```

#### レジストリレコードのIDを指定した場合 {#given-a-registry-records-id}

- `432`を実際のIDに置き換えます。レジストリレコードは、追跡するModelレコードと同じID値を持つ場合と持たない場合があります。
- `Geo::PackageFileRegistry`を[Geoレジストリクラス](#geo-registry-classes)のいずれかに置き換えます。

セカンダリGeoサイトの場合:

```ruby
registry_record = Geo::PackageFileRegistry.find_by(id: 432)
replicator = registry_record.replicator
```

#### レジストリレコードの`last_sync_failure`のエラーメッセージを指定した場合 {#given-an-error-message-in-a-registry-records-last_sync_failure}

- `Geo::PackageFileRegistry`を[Geoレジストリクラス](#geo-registry-classes)のいずれかに置き換えます。
- `error message here`を実際のエラーメッセージに置き換えます。

```ruby
registry = Geo::PackageFileRegistry.find_by("last_sync_failure LIKE '%error message here%'")
replicator = registry.replicator
```

#### レジストリレコードの`verification_failure`のエラーメッセージを指定した場合 {#given-an-error-message-in-a-registry-records-verification_failure}

- `Geo::PackageFileRegistry`を[Geoレジストリクラス](#geo-registry-classes)のいずれかに置き換えます。
- `error message here`を実際のエラーメッセージに置き換えます。

```ruby
registry = Geo::PackageFileRegistry.find_by("verification_failure LIKE '%error message here%'")
replicator = registry.replicator
```

### Replicatorインスタンスを使用した操作の実行 {#performing-operations-with-a-replicator-instance}

`replicator`変数に格納されているReplicatorインスタンスがある場合は、多くの操作を実行できます:

#### コンソールでの同期 {#sync-in-the-console}

このスニペットはセカンダリサイトでのみ機能します。

このコマンドはコンソール上で同期コードを同期的に実行します。そのため、リソースの同期にかかる時間を確認したり、エラーの完全なバックトレースを表示したりすることができます。

```ruby
replicator.sync
```

必要に応じて、コンソールのログレベルを設定済みのレベルより詳細に変更し、その後で同期処理を実行してください:

```ruby
Rails.logger.level = :debug
```

#### コンソールでのチェックサムまたは検証 {#checksum-or-verify-in-the-console}

このスニペットはプライマリサイトまたはセカンダリサイトのどちらでも機能します。

プライマリサイトでは、リソースのチェックサムを計算し、その結果をメインのGitLabデータベースに保存します。セカンダリサイトでは、リソースのチェックサムを計算し、メインのGitLabデータベース（プライマリサイトによって生成されたもの）のチェックサムと比較し、その結果をGeoトラッキングデータベースに保存します。

これにより、コンソールでチェックサムと検証コードが同期的に実行されるため、かかる時間を確認したり、完全なエラーバックトレースを表示したりできます。

```ruby
replicator.verify
```

#### Sidekiqジョブでの同期 {#sync-in-a-sidekiq-job}

このスニペットはセカンダリサイトでのみ機能します。

このコマンドは、Sidekiqにジョブをキューイングし、リソースの[同期処理](#sync-in-the-console)を実行させます。

```ruby
replicator.enqueue_sync
```

#### Sidekiqジョブでの検証 {#verify-in-a-sidekiq-job}

このスニペットはプライマリサイトまたはセカンダリサイトのどちらでも機能します。

Sidekiqがリソースの[チェックサムまたは検証](#checksum-or-verify-in-the-console)を実行するためのジョブをキューイングします。

```ruby
replicator.verify_async
```

#### モデルレコードの取得 {#get-a-model-record}

このスニペットはプライマリサイトまたはセカンダリサイトのどちらでも機能します。

```ruby
replicator.model_record
```

#### レジストリレコードの取得 {#get-a-registry-record}

このスニペットは、レジストリテーブルがGeoトラッキングDBに保存されているため、セカンダリサイトでのみ機能します。

```ruby
replicator.registry
```

### Geoデータ型モデルクラス {#geo-data-type-model-classes}

Geoデータ型は、関連データを格納するために1つ以上のGitLab機能に必要なデータの特定のクラスであり、Geoによってセカンダリサイトにレプリケートされます。

- **Blob型**:
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
- **Gitリポジトリ型**:
  - `DesignManagement::Repository`
  - `ProjectRepository`
  - `ProjectWikiRepository`
  - `SnippetRepository`
  - `GroupWikiRepository`
- **その他の型**:
  - `ContainerRepository`

主なクラスの種類は、レジストリ、モデル、およびReplicatorです。これらのクラスのいずれかのインスタンスがある場合は、他のインスタンスを取得できます。レジストリとモデルは、主にPostgreSQL DBの状態を管理します。Replicatorは、PostgreSQL以外のデータ（ファイル/Gitリポジトリ/コンテナリポジトリ）をレプリケートまたは検証する方法を認識しています。

### Geoレジストリクラス {#geo-registry-classes}

GitLab Geoのコンテキストでは、**レジストリレコード**とは、Geoトラッキングデータベース内のレジストリテーブルを指します。各レコードは、LFSファイルやプロジェクトのGitリポジトリなど、メインのGitLabデータベース内の単一のレプリケート可能なファイルを追跡します。クエリできるGeoレジストリテーブルに対応するRailsモデルは次のとおりです:

- **Blob型**:
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
- **Gitリポジトリ型**:
  - `Geo::DesignManagementRepositoryRegistry`
  - `Geo::ProjectRepositoryRegistry`
  - `Geo::ProjectWikiRepositoryRegistry`
  - `Geo::SnippetRepositoryRegistry`
  - `Geo::GroupWikiRepositoryRegistry`
- **その他の型**:
  - `Geo::ContainerRepositoryRegistry`

## 複数のコンポーネントを再度同期して再検証する {#resync-and-reverify-multiple-components}

コンポーネントリソースの同期や検証に失敗した場合、一括アクションを実行してレプリケーションキューを再起動することができます。これらのアクションは再試行回数とスケジュール時間を0にリセットし、最大1時間待たずに失敗したリソースを優先的に処理させます。

> [!note]
> これらのアクションは、リソースをすぐには処理しません。代わりに、同期と検証を処理するバックグラウンドジョブを再キューに入れます。実際には、標準のGeoレプリケーションプロセスを通じて、非同期的にレプリケーション作業が行われます。

### 再同期と再検証の仕組み {#how-resync-and-reverification-works}

再同期または再検証アクションをトリガーすると、システムは一致するレコードを`pending`としてマークします。Geoの再同期と再検証のバックグラウンドワーカーは、これらのレコードを取得し、通常のキューの優先度に従って処理します。このメカニズムを使用すると、操作ですぐにブロックせずに、失敗したリソースの処理を迅速化できます。

> [!note]
> 正常に同期されていないレコードを再検証することはできません。同期されたレコードのみを検証できます。

UIまたはRailsコンソールから一括アクションをトリガーできます。

### UIから {#from-the-ui}

UIから1つのコンポーネントのすべてのリソースの完全な再同期をスケジュールできます:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**Geo** > **サイト**を選択します。
1. **レプリケーションの詳細**で、目的のコンポーネントを選択します。

#### 選択したコンポーネントのリソースを再同期する {#resync-resources-for-the-selected-component}

1. **すべて再同期**を選択: これにより、選択したリソースのすべてのレコードの状態が、既に同期されているかどうかに関係なくリセットされます。
1. **すべての再同期に失敗しました**を選択: これにより、同期に失敗したすべてのレコードがリセットされます。

#### 選択したコンポーネントのリソースを再検証する {#reverify-resources-for-the-selected-component}

1. **すべて再検証**を選択: これにより、選択したリソースのすべてのレコードの状態が、既に検証されているかどうかに関係なくリセットされます。
1. **すべての失敗を再検証**を選択: これにより、検証に失敗したが、同期が成功したすべてのレコードがリセットされます。

#### すべてのサイトで1つのコンポーネントを再検証する {#reverify-one-component-on-all-sites}

プライマリサイトのチェックサムに疑いがある場合は、プライマリサイトにチェックサムを再計算させる必要があります。プライマリサイトで各チェックサムが再計算されるたびに、すべてのセカンダリサイトに伝播するイベントが生成され、それらのサイトがチェックサムを再計算して値を比較するため、「完全な再検証」が実現されます。不一致があると、レジストリが`sync failed`としてマークされ、同期の再試行がスケジュールされます。

UIからプライマリサイトのチェックサムを再計算できます:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **データ管理**を選択します。
1. ドロップダウンリストで目的のコンポーネントを選択します。
1. **すべてのチェックサム**を選択します。

> [!warning]
> **すべて再同期**、**すべて再検証**、および**すべてのチェックサム**は、すでに同期または検証されているかどうかにかかわらず、すべてのリソースの更新をトリガーします。インスタンス内に何千ものオブジェクトタイプ（CIジョブアーティファクトなど）がある場合は、実行しないでください。

### Railsコンソールから {#from-the-rails-console}

> [!warning]
> データを変更するコマンドは、正しく実行されない場合や適切な条件下で実行されない場合、損害を引き起こす可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

次のセクションでは、[Railsコンソール](../../operations/rails_console.md#starting-a-rails-console-session)で内部アプリケーションコマンドを使用して、一括レプリケーションまたは検証を行う方法について説明します。

#### 同期に失敗した1つのコンポーネントのすべてのリソースを同期する {#sync-all-resources-of-one-component-that-failed-to-sync}

次のスクリプトは、以下を行います:

- 失敗したすべてのリポジトリをループ処理します。
- 最後の失敗の理由を含む、Geoの同期と検証のメタデータを表示します。
- リポジトリの再同期を試みます。
- 失敗が発生した場合、およびその理由を報告します。
- 完了するまでに時間がかかる場合があります。各リポジトリチェックは、結果を報告する前に完了する必要があります。セッションがタイムアウトした場合は、`screen`セッションを開始するか、[Railsランナー](../../operations/rails_console.md#using-the-rails-runner)と`nohup`を使用して実行するなど、プロセスが実行され続けるように対策を講じてください。

このスクリプトはセカンダリGeoサイトで実行してください。

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

#### プライマリサイトでチェックサムに失敗したすべてのリソースを再検証する {#reverify-all-resources-that-failed-to-checksum-on-the-primary-site}

システムは、プライマリサイトでチェックサムに失敗したすべてのリソースを自動的に再検証します。ただし、過剰な失敗発生を防ぐために段階的なバックオフ方式を採用しています。

たとえば試行された介入を完了した場合は、オプションでより早く手動で再検証をトリガーできます:

1. プライマリサイトのGitLab RailsノードにSSH接続します。
1. [Railsコンソール](../../operations/rails_console.md#starting-a-rails-console-session)を開きます。
1. `LfsObject`を[Geoデータ型モデルクラス](#geo-data-type-model-classes)のいずれかに置き換えて、すべてのリソースを`pending verification`としてマークします:

   ```ruby
   LfsObject.verification_state_table_class.where(verification_state: 3).each_batch do |relation|
     relation.update_all(verification_state: 0)
   end
   ```
