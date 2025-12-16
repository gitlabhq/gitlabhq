---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: サポートされているGeoデータタイプ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Geoデータタイプとは、1つ以上のGitLab機能が関連情報を保存するために必要とする特定のデータクラスのことです。

これらの機能によって生成されたデータをGeoでレプリケートするには、アクセス、転送、および検証を行うためのいくつかの戦略を使用します。

## データタイプ {#data-types}

以下のさまざまなデータタイプを区別します:

- [Gitリポジトリ](#git-repositories)
- [コンテナリポジトリ](#container-repositories)
- [blob](#blobs)
- [データベース](#databases)

以下に、レプリケートする各機能またはコンポーネント、対応するデータタイプ、レプリケーション、および検証方法のリストを示します:

| 型                 | 機能/コンポーネント                             | レプリケーション方法                           | 検証方法           |
|:---------------------|:------------------------------------------------|:---------------------------------------------|:------------------------------|
| データベース             | PostgreSQLのアプリケーションデータ                  | ネイティブ                                       | ネイティブ                        |
| データベース             | Redis                                           | 該当なし<sup>1</sup>                  | 該当なし                |
| データベース             | 高度な検索（ElasticsearchまたはOpenSearch）   | ネイティブ                                       | ネイティブ                        |
| データベース             | 完全一致コードの検索（Zoekt）                       | ネイティブ                                       | ネイティブ                        |
| データベース             | SSH公開キー                                 | PostgreSQLレプリケーション                       | PostgreSQLレプリケーション        |
| Git                  | プロジェクトリポジトリ                              | GeoとGitaly                              | Gitalyチェックサム               |
| Git                  | プロジェクトWikiリポジトリ                         | GeoとGitaly                              | Gitalyチェックサム               |
| Git                  | プロジェクトデザインリポジトリ                      | GeoとGitaly                              | Gitalyチェックサム               |
| Git                  | プロジェクトスニペット                                | GeoとGitaly                              | Gitalyチェックサム               |
| Git                  | パーソナルスニペット                               | GeoとGitaly                              | Gitalyチェックサム               |
| Git                  | グループウィキリポジトリ                           | GeoとGitaly                              | Gitalyチェックサム               |
| Blob                 | ユーザーアップロード_（ファイルシステム）_                    | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | ユーザーアップロード_（オブジェクトストレージ）_                 | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | LFSオブジェクト_（ファイルシステム）_                     | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | LFSオブジェクト_（オブジェクトストレージ）_                  | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | CIジョブアーティファクト_（ファイルシステム）_                | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | CIジョブアーティファクト_（オブジェクトストレージ）_             | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | アーカイブされたCIビルドトレース_（ファイルシステム）_        | GeoとAPI                                 | 未実装             |
| Blob                 | アーカイブされたCIビルドトレース_（オブジェクトストレージ）_     | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | コンテナレジストリ_（ファイルシステム）_              | GeoとAPI/Docker API                      | SHA256チェックサム               |
| Blob                 | コンテナレジストリ_（オブジェクトストレージ）_           | GeoとAPI/管理対象/Docker API<sup>2</sup> | SHA256チェックサム<sup>3</sup>  |
| Blob                 | パッケージレジストリ_（ファイルシステム）_                | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | パッケージレジストリ_（オブジェクトストレージ）_             | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | Terraformモジュールレジストリ_（ファイルシステム）_       | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | Terraformモジュールレジストリ_（オブジェクトストレージ）_    | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | バージョン管理されたTerraform State _（ファイルシステム）_       | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | バージョン管理されたTerraform State _（オブジェクトストレージ）_    | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | 外部マージリクエスト差分_（ファイルシステム）_    | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | 外部マージリクエスト差分_（オブジェクトストレージ）_ | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | パイプラインアーティファクト_（ファイルシステム）_              | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | パイプラインアーティファクト_（オブジェクトストレージ）_           | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | Pages _（ファイルシステム）_                           | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | Pages _（オブジェクトストレージ）_                        | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | CIセキュアファイル_（ファイルシステム）_                 | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | CIセキュアファイル_（オブジェクトストレージ）_              | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | インシデントメトリックイメージ_（ファイルシステム）_          | GeoとAPI/管理対象                         | SHA256チェックサム               |
| Blob                 | インシデントメトリックイメージ_（オブジェクトストレージ）_       | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | アラートメトリックイメージ_（ファイルシステム）_             | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | アラートメトリックイメージ_（オブジェクトストレージ）_          | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| Blob                 | 依存プロキシイメージ_（ファイルシステム）_         | GeoとAPI                                 | SHA256チェックサム               |
| Blob                 | 依存プロキシイメージ_（オブジェクトストレージ）_      | GeoとAPI/管理対象<sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| コンテナリポジトリ | コンテナレジストリ_（ファイルシステム）_              | GeoとAPI/Docker API                      | SHA256チェックサム               |
| コンテナリポジトリ | コンテナレジストリ_（オブジェクトストレージ）_           | GeoとAPI/管理対象/Docker API<sup>2</sup> | SHA256チェックサム<sup>3</sup>  |

**脚注**: 

1. Redisレプリケーションは、Redis SentinelでHAの一部として使用できます。Geoサイト間では使用されません。
1. オブジェクトストレージのレプリケーションは、Geoまたはオブジェクトストレージプロバイダー/アプライアンスのネイティブレプリケーション機能によって実行できます。
1. オブジェクトストレージの検証は、[機能フラグ](../../feature_flags/_index.md) `geo_object_storage_verification` [16.4で導入](https://gitlab.com/groups/gitlab-org/-/epics/8056)され、デフォルトで有効になっています。ファイルサイズチェックサムを使用して、ファイルを検証します。

### Gitリポジトリ {#git-repositories}

GitLabインスタンスには、1つ以上のリポジトリシャードを設定できます。各シャードには、ローカルに保存されたGitリポジトリへのアクセスと操作を可能にするGitalyインスタンスがあります。これは、次のマシンで実行できます:

- 単一のディスクを使用しているマシン。
- 複数のディスクが（RAIDアレイなどの構成により）単一のマウントポイントとしてマウントされているマシン。
- LVMを使用しているマシン。

GitLabは特別なファイルシステムを必要とせず、マウントされたストレージアプライアンスで動作します。ただし、リモートファイルシステムを使用すると、パフォーマンスの制限や整合性の問題が発生する可能性があります。

GeoはGitalyのガベージコレクションをトリガーし、Geoセカンダリサイト上のフォークしたリポジトリを重複排除します。

Gitaly gRPC APIが通信を行い、次の3つの同期方法があります:

- （特別な認証を使用して）あるGeoサイトから別のGeoサイトへの通常のGitクローン/フェッチを使用します。
- （最初の方法が失敗した場合、またはリポジトリが破損している場合）リポジトリのスナップショットを使用します。
- **管理者**エリアからの手動トリガー（リストされている他の可能な方法を組み合わせます）。

各プロジェクトは、最大3つの異なるリポジトリを持つことができます:

- ソースコードを保存するプロジェクトリポジトリ。
- Wikiコンテンツを保存するWikiリポジトリ。
- デザインアーティファクトをインデックス登録するデザインリポジトリ（実際のアセットはLFSに保存されます）。

これらのリポジトリはすべて同じシャード内に存在し、Wikiリポジトリとデザインリポジトリは同じベース名を共有し、それぞれ`-wiki`および`-design`というサフィックスが付きます。

それ以外に、スニペットリポジトリがあります。これらは、プロジェクトまたは特定のユーザーに接続できます。どちらのタイプもセカンダリサイトに同期されます。

### コンテナリポジトリ {#container-repositories}

コンテナリポジトリは、コンテナレジストリに格納されます。これらは、データストアとしてのコンテナレジストリ上に構築されたGitLab固有の概念です。

### blob {#blobs}

イシューの添付ファイルやLFSオブジェクトなどのファイルとblobをGitLabが格納する場所:

- 特定の場所にあるファイルシステム。
- [オブジェクトストレージ](../../object_storage.md)ソリューション。オブジェクトストレージソリューションには、次のものがあります:
  - Amazon S3やGoogle Cloud Storageなど、クラウドベースのもの。
  - ユーザー自身がホストするもの（MinIOなど）。
  - オブジェクトストレージ互換APIを提供するストレージアプライアンス。

オブジェクトストレージの代わりにファイルシステムストアを使用する場合は、複数のノードを使用するときにネットワークマウントされたファイルシステムを使用してGitLabを実行します。

レプリケーションと検証に関して:

- 内部APIリクエストを使用して、ファイルとblobを転送します。
- オブジェクトストレージを使用すると、次のいずれかを行うことができます:
  - クラウドプロバイダーレプリケーション機能を使用します。
  - GitLabにレプリケートさせます。

### データベース {#databases}

GitLabは、さまざまなユースケースに対応するため、複数のデータベースに格納されたデータに依存しています。PostgreSQLは、イシューコンテンツ、コメント、権限、認証情報など、Webインターフェースでユーザーが生成したコンテンツの信頼できる唯一の情報源です。

PostgreSQLは、HTMLレンダリングされたMarkdownやキャッシュされたマージリクエストの差分など、ある程度のレベルのキャッシュされたデータを保持することもできます。これは、オブジェクトストレージにオフロードするように構成することもできます。

**プライマリ**サイトから**セカンダリ**サイトにデータをレプリケートするために、PostgreSQL独自のレプリケーション機能を使用します。

GitLabは、キャッシュストアとして、またバックグラウンドジョブシステム用の永続データを保持するためにRedisを使用します。どちらのユースケースも同じGeoサイトに排他的なデータを持っているため、サイト間でレプリケートすることはありません。

Elasticsearchは、高度な検索のためのオプションのデータベースです。これにより、ソースコードレベルと、イシュー、マージリクエスト、ディスカッションにおけるユーザー生成コンテンツの両方で、検索を改善できます。ElasticsearchはGeoではサポートされていません。

## レプリケートされるデータタイプ {#replicated-data-types}

### 機能フラグの背後にあるレプリケートされたデータタイプ {#replicated-data-types-behind-a-feature-flag}

{{< history >}}

- これらは機能フラグの背後にデプロイされ、デフォルトで有効になっています。
- これらはGitLab.comで有効になっています。
- プロジェクトごとに有効または無効にすることはできません。
- 本番環境での使用をお勧めします。
- GitLab Self-Managedインスタンスの場合、GitLab管理者は[それらを無効にする](#enable-or-disable-replication-for-some-data-types)ことを選択できます。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

#### （一部のデータタイプで）レプリケーションを有効または無効にする {#enable-or-disable-replication-for-some-data-types}

一部のデータタイプのレプリケーションは、**デフォルトで有効になっている**機能フラグの背後でリリースされます。[GitLab Railsコンソールへのアクセス権を持つGitLab管理者](../../feature_flags/_index.md)は、インスタンスに対してそれを無効にすることを選択できます。これらの各データタイプの機能フラグ名は、以下の表の備考欄に記載されています。

無効にするには（パッケージファイルのレプリケーションなど）:

```ruby
Feature.disable(:geo_package_file_replication)
```

有効にするには（パッケージファイルのレプリケーションなど）:

```ruby
Feature.enable(:geo_package_file_replication)
```

{{< alert type="warning" >}}

このリストにない機能、または**Replicated**（レプリケート）列に**いいえ**がある機能は、**セカンダリ**Geoサイトサイトサイトにレプリケートされません。これらの機能から手動でデータをレプリケートせずにフェイルオーバーすると、データが**lost**（失われ）ます。これらの機能を**セカンダリ**サイトで使用したり、フェイルオーバーを正常に実行したりするには、他の方法でデータをレプリケートする必要があります。

{{< /alert >}}

| 機能                                                                                                               | レプリケート（GitLabバージョンで追加）                                          | 検証済み（GitLabバージョンで追加）                                            | GitLab管理のオブジェクトストレージレプリケーション（GitLabバージョンで追加）             | GitLab管理のオブジェクトストレージ検証（GitLabバージョンで追加）            | 備考 |
|:----------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:------|
| [PostgreSQLのアプリケーションデータ](../../postgresql/_index.md)                                                           | **可能**（10.2）                                                                | **可能**（10.2）                                                                | 該当なし                                                                  | 該当なし                                                                  |       |
| [プロジェクトリポジトリ](../../../user/project/repository/_index.md)                                                       | **可能**（10.2）                                                                | **可能**（10.7）                                                                | 該当なし                                                                  | 該当なし                                                                  | 16.2でセルフサービスフレームワークに移行しました。詳細については、GitLabイシュー[\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925)を参照してください。<br /><br />`geo_project_repository_replication`の機能フラグは、（16.3）でデフォルトで有効になりました。<br /><br /> [アーカイブされたプロジェクト](../../../user/project/working_with_projects.md#archive-a-project)を含む、すべてのプロジェクトがレプリケートされます。 |
| [プロジェクトウィキリポジトリ](../../../user/project/wiki/_index.md)                                                        | **可能**（10.2）<sup>2</sup>                                                    | **可能**（10.7）<sup>2</sup>                                                    | 該当なし                                                                  | 該当なし                                                                  | 15.11でセルフサービスフレームワークに移行しました。詳細については、GitLabイシュー[\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925)を参照してください。<br /><br />`geo_project_wiki_repository_replication`の機能フラグは、（15.11）でデフォルトで有効になりました。 |
| [グループウィキリポジトリ](../../../user/project/wiki/group.md)                                                          | [**可能**（13.10）](https://gitlab.com/gitlab-org/gitlab/-/issues/208147)       | [**可能**（16.3）](https://gitlab.com/gitlab-org/gitlab/-/issues/323897)        | 該当なし                                                                  | 該当なし                                                                  | `geo_group_wiki_repository_replication`機能フラグの背後にあり、デフォルトで有効になっています。 |
| [ユーザーアップロード](../../uploads.md)                                                                                           | **可能**（10.2）                                                                | **可能**（14.6）                                                                | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | レプリケーションは、`geo_upload_replication`機能フラグの背後にあり、デフォルトで有効になっています。検証は`geo_upload_verification`機能フラグの背後にあり、14.8で削除されました。 |
| [LFSオブジェクト](../../lfs/_index.md)                                                                                     | **可能**（10.2）                                                                | **可能**（14.6）                                                                | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | GitLabバージョン11.11.xおよび12.0.xは、[新しいLFSオブジェクトがレプリケートされないバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/32696)の影響を受けます。<br /><br />レプリケーションは、`geo_lfs_object_replication`機能フラグの背後にあり、デフォルトで有効になっています。検証は`geo_lfs_object_verification`機能フラグの背後にあり、14.7で削除されました。 |
| [パーソナルスニペット](../../../user/snippets.md)                                                                        | **可能**（10.2）                                                                | **可能**（10.2）                                                                | 該当なし                                                                  | 該当なし                                                                  |       |
| [プロジェクトスニペット](../../../user/snippets.md)                                                                         | **可能**（10.2）                                                                | **可能**（10.2）                                                                | 該当なし                                                                  | 該当なし                                                                  |       |
| [CIジョブ](../../../ci/jobs/job_artifacts.md)アーティファクト                                                                 | **可能**（10.4）                                                                | **可能**（14.10）                                                               | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 検証は機能フラグ`geo_job_artifact_replication`の背後にあり、14.10デフォルトで有効になっています。 |
| [パイプラインアーティファクト](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/pipeline_artifact.rb)        | [**可能**（13.11）](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)       | [**可能**（13.11）](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)       | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | パイプラインの完了後、追加のアーティファクトを永続化します。 |
| [CIセキュアファイル](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/secure_file.rb)                    | [**可能**（15.3）](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430) | [**可能**（15.3）](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430) | [**可能**（15.3）](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430)   | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 検証は機能フラグ`geo_ci_secure_file_replication`の背後にあり、15.3デフォルトで有効になっています。 |
| [コンテナレジストリ](../../packages/container_registry.md)                                                            | **可能**（12.3）<sup>1</sup>                                                    | **可能**（15.10）                                                               | **可能**（12.3）<sup>1</sup>                                                      | **可能**（15.10）                                                                 | コンテナレジストリのレプリケーションを設定するには、[手順](container_registry.md)を参照してください。 |
| [Terraformモジュールレジストリ](../../../user/packages/terraform_module_registry/_index.md)                                | **可能**（14.0）                                                                | **可能**（14.0）                                                                | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | `geo_package_file_replication`機能フラグの背後にあり、デフォルトで有効になっています。 |
| [プロジェクトデザインリポジトリ](../../../user/project/issues/design_management.md)                                       | **可能**（12.7）                                                                | **可能**（16.1）                                                                | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | デザインには、LFSオブジェクトとアップロードのレプリケーションも必要です。 |
| [パッケージレジストリ](../../../user/packages/package_registry/_index.md)                                                  | **可能**（13.2）                                                                | **可能**（13.10）                                                               | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | `geo_package_file_replication`機能フラグの背後にあり、デフォルトで有効になっています。 |
| [バージョン管理されたTerraform State](../../terraform_state.md)                                                                 | **可能**（13.5）                                                                | **可能**（13.12）                                                               | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | レプリケーションは、`geo_terraform_state_version_replication`機能フラグの背後にあり、デフォルトで有効になっています。検証は機能フラグ`geo_terraform_state_version_verification`の背後にあり、14.0で削除されました。 |
| [外部マージリクエストの差分](../../merge_request_diffs.md)                                                          | **可能**（13.5）                                                                | **可能**（14.6）                                                                | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | レプリケーションは、`geo_merge_request_diff_replication`機能フラグの背後にあり、デフォルトで有効になっています。検証は機能フラグ`geo_merge_request_diff_verification`の背後にあり、14.7で削除されました。 |
| [バージョン管理されたスニペット](../../../user/snippets.md#versioned-snippets)                                                    | [**可能**（13.7）](https://gitlab.com/groups/gitlab-org/-/epics/2809)           | [**可能**（14.2）](https://gitlab.com/groups/gitlab-org/-/epics/2810)           | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 検証は13.11の機能フラグ`geo_snippet_repository_verification`の背後に実装され、機能フラグは14.2で削除されました。 |
| [Pages](../../pages/_index.md)                                                                                  | [**可能**（14.3）](https://gitlab.com/groups/gitlab-org/-/epics/589)            | **可能**（14.6）                                                                | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | `geo_pages_deployment_replication`機能フラグの背後にあり、デフォルトで有効になっています。検証は機能フラグ`geo_pages_deployment_verification`の背後にあり、14.7で削除されました。 |
| [プロジェクトレベルのCIセキュアファイル](../../../ci/secure_files/_index.md)                                                       | **可能**（15.3）                                                                | **可能**（15.3）                                                                | **可能**（15.3）                                                                  | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) |       |
| [インシデントメトリクス画像](../../../operations/incident_management/incidents.md#metrics)                                | **可能**（15.5）                                                                | **可能**（15.5）                                                                | **可能**（15.5）                                                                  | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | レプリケーション/検証は、アップロードデータタイプを介して処理されます。 |
| [アラートメトリクスの画像](../../../operations/incident_management/alerts.md#metrics-tab)                                  | **可能**（15.5）                                                                | **可能**（15.5）                                                                | **可能**（15.5）                                                                  | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | レプリケーション/検証は、アップロードデータタイプを介して処理されます。 |
| [サーバー側のGitフック](../../server_hooks.md)                                                                        | [計画されていません](https://gitlab.com/groups/gitlab-org/-/epics/1867)              | いいえ                                                                            | 該当なし                                                                  | 該当なし                                                                  | 現在の実装の複雑さ、顧客の関心の低さ、およびフックの代替手段の利用可能性のため、計画されていません。 |
| [Elasticsearch](../../../integration/advanced_search/elasticsearch.md)                                    | [計画されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/1186)             | いいえ                                                                            | 不可                                                                              | いいえ                                                                              | 製品のさらなる調査が必要であり、Elasticsearch（ES）クラスターを再構築できるため、計画されていません。セカンダリは、プライマリと同じESクラスターを使用します。 |
| [依存プロキシ画像](../../../user/packages/dependency_proxy/_index.md)                                           | [**可能**（15.7）](https://gitlab.com/groups/gitlab-org/-/epics/8833)           | [**可能**（15.7）](https://gitlab.com/groups/gitlab-org/-/epics/8833)           | [**可能**（15.7）](https://gitlab.com/groups/gitlab-org/-/epics/8833)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) |       |
| [脆弱性エクスポート](../../../user/application_security/vulnerability_report/_index.md#exporting) | [計画されていません](https://gitlab.com/groups/gitlab-org/-/epics/3111)              | いいえ                                                                            | 不可                                                                              | いいえ                                                                              | それらは一時的なものであり、機密情報であるため、計画されていません。それらはオンデマンドで再生成できます。 |
| パッケージNPMメタデータキャッシュ                                                                                           | [計画されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/408278)           | いいえ                                                                            | 不可                                                                              | いいえ                                                                              | ディザスターリカバリー機能もセカンダリサイトでの応答時間も大幅に向上しないため、計画されていません。 |
| パッケージDebian GroupComponentFile                                                                                    | [計画されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/556945)           | いいえ                                                                            | 不可                                                                              | いいえ                                                                              |       |
| パッケージDebian ProjectComponentFile                                                                                  | [計画されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/333611)           | いいえ                                                                            | 不可                                                                              | いいえ                                                                              |       |
| パッケージDebian GroupDistribution                                                                                     | [計画されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/556947)           | いいえ                                                                            | 不可                                                                              | いいえ                                                                              |       |
| パッケージDebian ProjectDistribution                                                                                   | [計画されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/556946)           | いいえ                                                                            | 不可                                                                              | いいえ                                                                              |       |
| パッケージRPM RepositoryFile                                                                                           | [計画されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/379055)           | いいえ                                                                            | 不可                                                                              | いいえ                                                                              |       |
| パッケージNuGet Symbol                                                                                                 | [計画されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/422929)           | いいえ                                                                            | 不可                                                                              | いいえ                                                                              |       |
| VirtualRegistries Mavenキャッシュエントリ                                                                                   | [計画されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/473033)           | いいえ                                                                            | 不可                                                                              | いいえ                                                                              |       |
| SBOM脆弱性スキャンデータ                                                                                           | [計画されていません](https://gitlab.com/gitlab-org/gitlab/-/issues/398199)           | いいえ                                                                            | 不可                                                                              | いいえ                                                                              | データが一時的であり、セカンダリサイトでのディザスターリカバリー機能への影響が限られているため、計画されていません。 |

**脚注**: 

1. 15.5でセルフサービスフレームワークに移行しました。詳細については、GitLabイシュー[\#337436](https://gitlab.com/gitlab-org/gitlab/-/issues/337436)を参照してください。
1. 15.11でセルフサービスフレームワークに移行しました。`geo_project_wiki_repository_replication`機能フラグの背後にあり、デフォルトで有効になっています。詳細については、GitLabイシュー[\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925)を参照してください。
1. オブジェクトストレージに格納されているファイルの検証は、GitLab 16.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/8056)されました（`geo_object_storage_verification`という名前の[機能フラグ](../../feature_flags/_index.md)を使用）。
