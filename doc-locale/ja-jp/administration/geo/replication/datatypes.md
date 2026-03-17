---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Geoでサポートされているデータ型
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Geoデータ型は、1つ以上のGitLab機能が関連情報を保存するために必要な特定のデータクラスです。

これらの機能によって生成されたデータをGeoでレプリケートするために、アクセス、転送、および検証にいくつかの戦略を使用します。

## データ型 {#data-types}

以下の異なるデータ型を区別します:

- [Gitリポジトリ](#git-repositories)
- [コンテナリポジトリ](#container-repositories)
- [blob](#blobs)
- [データベース](#databases)

レプリケートする各機能またはコンポーネント、対応するデータ型、レプリケーション、および検証方法のリストを以下に示します:

| 種類                 | 機能 / コンポーネント                             | レプリケーション方法                           | 検証方法           |
|:---------------------|:------------------------------------------------|:---------------------------------------------|:------------------------------|
| データベース             | PostgreSQLのアプリケーションデータ                  | ネイティブ                                       | ネイティブ                        |
| データベース             | Redis                                           | 該当なし<sup>1</sup>                  | 該当なし                |
| データベース             | 高度な検索（ElasticsearchまたはOpenSearch）   | ネイティブ                                       | ネイティブ                        |
| データベース             | 完全一致コードの検索（Zoekt）                       | ネイティブ                                       | ネイティブ                        |
| データベース             | SSH公開キー                                 | PostgreSQLレプリケーション                       | PostgreSQLレプリケーション        |
| Git                  | プロジェクトリポジトリ                              | GeoとGitaly                              | Gitalyチェックサム               |
| Git                  | プロジェクトウィキリポジトリ                         | GeoとGitaly                              | Gitalyチェックサム               |
| Git                  | プロジェクトデザインリポジトリ                      | GeoとGitaly                              | Gitalyチェックサム               |
| Git                  | プロジェクトスニペット                                | GeoとGitaly                              | Gitalyチェックサム               |
| Git                  | 個人スニペット                               | GeoとGitaly                              | Gitalyチェックサム               |
| Git                  | グループウィキリポジトリ                           | GeoとGitaly                              | Gitalyチェックサム               |
| blob                 | ユーザーのアップロード_（ファイルシステム）_                    | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | ユーザーのアップロード_（オブジェクトストレージ）_                 | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | LFSオブジェクト_（ファイルシステム）_                     | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | LFSオブジェクト_（オブジェクトストレージ）_                  | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | CIジョブアーティファクト_（ファイルシステム）_                | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | CIジョブアーティファクト_（オブジェクトストレージ）_             | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | アーカイブされたCIビルドトレース_（ファイルシステム）_        | GeoとAPI                                 | 未実装             |
| blob                 | アーカイブされたCIビルドトレース_（オブジェクトストレージ）_     | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | コンテナレジストリ_（ファイルシステム）_              | GeoとAPI/Docker API                      | SHA256チェックサム               |
| blob                 | コンテナレジストリ_（オブジェクトストレージ）_           | GeoとAPI/Managed/Docker API <sup>2</sup> | SHA256チェックサム<sup>3</sup>  |
| blob                 | パッケージレジストリ_（ファイルシステム）_                | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | パッケージレジストリ_（オブジェクトストレージ）_             | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | Terraformモジュールレジストリ_（ファイルシステム）_       | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | Terraformモジュールレジストリ_（オブジェクトストレージ）_    | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | バージョン管理されたTerraform State _（ファイルシステム）_       | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | バージョン管理されたTerraform State _（オブジェクトストレージ）_    | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | 外部マージリクエストの差分_（ファイルシステム）_    | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | 外部マージリクエストの差分_（オブジェクトストレージ）_ | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | パイプラインアーティファクト_（ファイルシステム）_              | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | パイプラインアーティファクト_（オブジェクトストレージ）_           | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | Pages _（ファイルシステム）_                           | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | Pages _（オブジェクトストレージ）_                        | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | CIセキュアファイル_（ファイルシステム）_                 | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | CIセキュアファイル_（オブジェクトストレージ）_              | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | インシデントメトリクス画像_（ファイルシステム）_          | GeoとAPI/Managed                         | SHA256チェックサム               |
| blob                 | インシデントメトリクス画像_（オブジェクトストレージ）_       | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | アラートメトリクス画像_（ファイルシステム）_             | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | アラートメトリクス画像_（オブジェクトストレージ）_          | GeoとAPI/Managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| blob                 | 依存プロキシ画像_（ファイルシステム）_         | GeoとAPI                                 | SHA256チェックサム               |
| blob                 | 依存プロキシ画像_（オブジェクトストレージ）_      | GeoとAPI/managed <sup>2</sup>            | SHA256チェックサム<sup>3</sup>  |
| コンテナリポジトリ | コンテナレジストリ_（ファイルシステム）_              | GeoとAPI/Docker API                      | SHA256チェックサム               |
| コンテナリポジトリ | コンテナレジストリ_（オブジェクトストレージ）_           | GeoとAPI/Managed/Docker API <sup>2</sup> | SHA256チェックサム<sup>3</sup>  |

**脚注**: 

1. Redisレプリケーションは、Redis Sentinelを使用したHAの一部として使用できます。Geoサイト間では使用されません。
1. オブジェクトストレージのレプリケーションは、Geoまたはオブジェクトストレージプロバイダー/アプライアンスのネイティブレプリケーション機能によって実行できます。
1. オブジェクトストレージの検証は、[機能フラグ](../../feature_flags/_index.md)、`geo_object_storage_verification`、[16.4で導入され](https://gitlab.com/groups/gitlab-org/-/epics/8056)、デフォルトで有効になっています。ファイルサイズからチェックサムを使用してファイルを検証します。

### Gitリポジトリ {#git-repositories}

GitLabインスタンスには、1つ以上のリポジトリシャードを設定できます。各シャードには、ローカルに保存されているGitリポジトリへのアクセスと操作を許可するGitalyインスタンスがあります。これはマシン上で実行できます:

- 単一のディスクを使用しているマシン。
- 複数のディスクが（RAIDアレイなどの構成により）単一のマウントポイントとしてマウントされているマシン。
- LVMを使用しているマシン。

GitLabは特別なファイルシステムを必要とせず、マウントされたStorage Applianceで動作します。ただし、リモートファイルシステムを使用する場合、パフォーマンスの制限や一貫性の問題が発生する可能性があります。

GeoはGitalyでガベージコレクションをトリガーして、Geoセカンダリサイト上のフォークしたリポジトリの重複を排除します。

Gitaly gRPC APIは通信を行い、3つの可能な同期方法があります:

- あるGeoサイトから別のGeoサイトへの通常のGitクローン/フェッチの使用（特別な認証を使用）。
- リポジトリスナップショットの使用（最初の方法が失敗した場合、またはリポジトリが破損している場合）。
- **管理者**管理者エリアからの手動トリガー（他のリストされた可能な方法を組み合わせます）。

各プロジェクトは最大3つの異なるリポジトリを持つことができます:

- ソースコードを保存するプロジェクトリポジトリ。
- Wikiコンテンツを保存するWikiリポジトリ。
- デザインアーティファクトをインデックス登録するデザインリポジトリ（実際のアセットはLFSに保存されます）。

これらのリポジトリはすべて同じシャード内に存在し、Wikiリポジトリとデザインリポジトリは同じベース名を共有し、それぞれ`-wiki`および`-design`というサフィックスが付きます。

その他に、スニペットリポジトリがあります。それらはプロジェクトまたは特定のユーザーに接続できます。両方のタイプはセカンダリサイトに同期されます。

### コンテナリポジトリ {#container-repositories}

コンテナリポジトリはコンテナレジストリに保存されます。これらはコンテナレジストリをデータストアとして構築された、GitLab固有のコンセプトです。

### blob {#blobs}

GitLabは、イシューの添付ファイルやLFSオブジェクトなどのファイルやblobを以下のいずれかに保存します:

- 特定の場所にあるファイルシステム。
- [オブジェクトストレージ](../../object_storage.md)ソリューション。オブジェクトストレージソリューションには、次のものがあります。
  - Amazon S3やGoogle Cloud Storageなど、クラウドベースのもの。
  - セルフホスト型S3互換オブジェクトストレージ。
  - オブジェクトストレージ互換APIを提供するストレージアプライアンス。

オブジェクトストレージの代わりにファイルシステムストアを使用する場合、複数のノードを使用する際にGitLabを実行するにはネットワークマウントされたファイルシステムを使用します。

レプリケーションと検証に関して:

- 内部APIリクエストを使用してファイルとblobを転送します。
- オブジェクトストレージを使用すると、次のいずれかを実行できます:
  - クラウドプロバイダーのレプリケーション機能を使用します。
  - GitLabにレプリケートするよう依頼します。

### データベース {#databases}

GitLabは、さまざまなユースケースのために複数のデータベースに保存されているデータに依存しています。PostgreSQLは、Webインターフェース内のユーザー生成コンテンツ（イシューのコンテンツ、コメント、権限、および認証情報など）の単一の真実点です。

PostgreSQLは、HTMLレンダリングされたMarkdownやキャッシュされたマージリクエストの差分のような、ある程度のキャッシュデータを保持することもできます。これは、オブジェクトストレージにオフロードするように設定することもできます。

PostgreSQL独自のレプリケーション機能を使用して、**プライマリ**から**セカンダリ**サイトにデータをレプリケートするます。

Redisは、キャッシュデータストアとして、またバックグラウンドジョブシステム用の永続データを保持するために使用されます。両方のユースケースには同じGeoサイトに固有のデータがあるため、サイト間でレプリケートすることはありません。

Elasticsearchは、高度な検索のためのオプションのデータベースです。これにより、ソースコードレベルと、イシュー、マージリクエスト、ディスカッションにおけるユーザー生成コンテンツの両方で、検索を改善できます。GeoではElasticsearchはサポートされていません。

## レプリケートされるデータタイプ {#replicated-data-types}

### 機能フラグの背後にあるレプリケートされたデータ型 {#replicated-data-types-behind-a-feature-flag}

{{< history >}}

- それらは機能フラグの背後にデプロイされ、デフォルトで有効になっています。
- それらはGitLab.comで有効になっています。
- プロジェクトごとに有効または無効にすることはできません。
- それらは本番環境での使用が推奨されます。
- GitLab Self-Managedインスタンスの場合、GitLab管理者は[それらを無効にする](#enable-or-disable-replication-for-some-data-types)ことを選択できます。

{{< /history >}}

> [!flag] 
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

#### レプリケーションを有効または無効にする（一部のデータ型の場合） {#enable-or-disable-replication-for-some-data-types}

一部のデータ型のレプリケーションは、機能フラグの背後でリリースされており、**enabled by default**で有効になっています。GitLab Railsコンソールにアクセスできる[GitLab管理者](../../feature_flags/_index.md)は、インスタンスでそれを無効にすることを選択できます。それらの各データ型の機能フラグ名は、以下の表のノート列に記載されています。

無効にするには、パッケージファイルのレプリケーションの場合と同様に、次のコマンドを実行します:

```ruby
Feature.disable(:geo_package_file_replication)
```

有効にするには、パッケージファイルのレプリケーションの場合と同様に、次のコマンドを実行します:

```ruby
Feature.enable(:geo_package_file_replication)
```

> [!warning]
> このリストにない機能、または**Replicated**列に**いいえ**と記載されている機能は、**セカンダリ**サイトにはレプリケートされません。それらの機能からデータを手動でレプリケートするせずにフェイルオーバーすると、データが**lost**。**セカンダリ**サイトでそれらの機能を使用するには、またはフェイルオーバーを正常に実行するには、他の手段を使用してデータをレプリケートする必要があります。

| 機能                                                                                                               | Replicated（GitLabバージョンで追加）                                          | 検証済み（GitLabバージョンで追加）                                            | GitLab管理のオブジェクトストレージレプリケーション（GitLabバージョンで追加）             | GitLab管理のオブジェクトストレージ検証（GitLabバージョンで追加）            | 備考 |
|:----------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:------|
| [PostgreSQLのアプリケーションデータ](../../postgresql/_index.md)                                                           | **可能**（10.2）                                                                | **可能**（10.2）                                                                | 該当なし                                                                  | 該当なし                                                                  |       |
| [プロジェクトリポジトリ](../../../user/project/repository/_index.md)                                                       | **可能**（10.2）                                                                | **可能**（10.7）                                                                | 該当なし                                                                  | 該当なし                                                                  | 16.2でセルフサービスフレームワークに移行されました。詳細については、GitLabイシュー[\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925)を参照してください。<br /><br />機能フラグ`geo_project_repository_replication`の背後で、（16.3）でデフォルトで有効になっています。<br /><br /> [アーカイブされたプロジェクト](../../../user/project/working_with_projects.md#archive-a-project)を含むすべてのプロジェクトがレプリケートされます。 |
| [プロジェクトウィキリポジトリ](../../../user/project/wiki/_index.md)                                                        | **可能**（10.2）<sup>2</sup>                                                    | **可能**（10.7）<sup>2</sup>                                                    | 該当なし                                                                  | 該当なし                                                                  | 15.11でセルフサービスフレームワークに移行されました。詳細については、GitLabイシュー[\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925)を参照してください。<br /><br />機能フラグ`geo_project_wiki_repository_replication`の背後で、（15.11）でデフォルトで有効になっています。 |
| [グループウィキリポジトリ](../../../user/project/wiki/group.md)                                                          | [**可能**（13.10）](https://gitlab.com/gitlab-org/gitlab/-/issues/208147)       | [**可能**（16.3）](https://gitlab.com/gitlab-org/gitlab/-/issues/323897)        | 該当なし                                                                  | 該当なし                                                                  | 機能フラグ`geo_group_wiki_repository_replication`の背後で、デフォルトで有効になっています。 |
| [ユーザーアップロード](../../uploads.md)                                                                                           | **可能**（10.2）                                                                | **可能**（14.6）                                                                | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | レプリケーションは、機能フラグ`geo_upload_replication`の背後で、デフォルトで有効になっています。検証は、機能フラグ`geo_upload_verification`の背後で行われましたが、14.8で削除されました。 |
| [LFSオブジェクト](../../lfs/_index.md)                                                                                     | **可能**（10.2）                                                                | **可能**（14.6）                                                                | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | GitLabバージョン11.11.xおよび12.0.xは、[新しいLFSオブジェクトのレプリケートするを妨げるバグ](https://gitlab.com/gitlab-org/gitlab/-/issues/32696)の影響を受けます。<br /><br />レプリケーションは、機能フラグ`geo_lfs_object_replication`の背後で、デフォルトで有効になっています。検証は、機能フラグ`geo_lfs_object_verification`の背後で行われましたが、14.7で削除されました。 |
| [個人スニペット](../../../user/snippets.md)                                                                        | **可能**（10.2）                                                                | **可能**（10.2）                                                                | 該当なし                                                                  | 該当なし                                                                  |       |
| [プロジェクトスニペット](../../../user/snippets.md)                                                                         | **可能**（10.2）                                                                | **可能**（10.2）                                                                | 該当なし                                                                  | 該当なし                                                                  |       |
| [CIジョブアーティファクト](../../../ci/jobs/job_artifacts.md)                                                                 | **可能**（10.4）                                                                | **可能**（14.10）                                                               | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 検証は、機能フラグ`geo_job_artifact_replication`の背後で、14.10でデフォルトで有効になっています。 |
| [パイプラインアーティファクト](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/pipeline_artifact.rb)        | [**可能**（13.11）](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)       | [**可能**（13.11）](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)       | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | パイプラインが完了した後に追加のアーティファクトを保持します。 |
| [CIセキュアファイル](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/secure_file.rb)                    | [**可能**（15.3）](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430) | [**可能**（15.3）](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430) | [**可能**（15.3）](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430)   | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 検証は、機能フラグ`geo_ci_secure_file_replication`の背後で、15.3でデフォルトで有効になっています。 |
| [コンテナレジストリ](../../packages/container_registry.md)                                                            | **可能**（12.3）<sup>1</sup>                                                    | **可能**（15.10）                                                               | **可能**（12.3）<sup>1</sup>                                                      | **可能**（15.10）                                                                 | コンテナレジストリのレプリケーションを設定する[手順](container_registry.md)を参照してください。 |
| [Terraformモジュールレジストリ](../../../user/packages/terraform_module_registry/_index.md)                                | **可能**（14.0）                                                                | **可能**（14.0）                                                                | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 機能フラグ`geo_package_file_replication`の背後で、デフォルトで有効になっています。 |
| [プロジェクトデザインリポジトリ](../../../user/project/issues/design_management.md)                                       | **可能**（12.7）                                                                | **可能**（16.1）                                                                | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | デザインには、LFSオブジェクトとアップロードのレプリケーションも必要です。 |
| [パッケージレジストリ](../../../user/packages/package_registry/_index.md)                                                  | **可能**（13.2）                                                                | **可能**（13.10）                                                               | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 機能フラグ`geo_package_file_replication`の背後で、デフォルトで有効になっています。 |
| [バージョン管理されたTerraform State](../../terraform_state.md)                                                                 | **可能**（13.5）                                                                | **可能**（13.12）                                                               | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | レプリケーションは、機能フラグ`geo_terraform_state_version_replication`の背後で、デフォルトで有効になっています。検証は、機能フラグ`geo_terraform_state_version_verification`の背後で行われましたが、14.0で削除されました。 |
| [外部マージリクエストの差分](../../merge_request_diffs.md)                                                          | **可能**（13.5）                                                                | **可能**（14.6）                                                                | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | レプリケーションは、機能フラグ`geo_merge_request_diff_replication`の背後で、デフォルトで有効になっています。検証は、機能フラグ`geo_merge_request_diff_verification`の背後で行われましたが、14.7で削除されました。 |
| [バージョン管理されたスニペット](../../../user/snippets.md#versioned-snippets)                                                    | [**可能**（13.7）](https://gitlab.com/groups/gitlab-org/-/epics/2809)           | [**可能**（14.2）](https://gitlab.com/groups/gitlab-org/-/epics/2810)           | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 検証は13.11で機能フラグ`geo_snippet_repository_verification`の背後で実装されましたが、この機能フラグは14.2で削除されました。 |
| [Pages](../../pages/_index.md)                                                                                  | [**可能**（14.3）](https://gitlab.com/groups/gitlab-org/-/epics/589)            | **可能**（14.6）                                                                | [**可能**（15.1）](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 機能フラグ`geo_pages_deployment_replication`の背後で、デフォルトで有効になっています。検証は、機能フラグ`geo_pages_deployment_verification`の背後で行われましたが、14.7で削除されました。 |
| [プロジェクトレベルのCIセキュアファイル](../../../ci/secure_files/_index.md)                                                       | **可能**（15.3）                                                                | **可能**（15.3）                                                                | **可能**（15.3）                                                                  | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) |       |
| [インシデントメトリクス画像](../../../operations/incident_management/incidents.md#metrics)                                | **可能**（15.5）                                                                | **可能**（15.5）                                                                | **可能**（15.5）                                                                  | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | レプリケーション/検証は、アップロードデータ型を介して処理されます。 |
| [アラートメトリクス画像](../../../operations/incident_management/alerts.md#metrics-tab)                                  | **可能**（15.5）                                                                | **可能**（15.5）                                                                | **可能**（15.5）                                                                  | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | レプリケーション/検証は、アップロードデータ型を介して処理されます。 |
| [サーバーサイドGitフック](../../server_hooks.md)                                                                        | [計画なし](https://gitlab.com/groups/gitlab-org/-/epics/1867)              | いいえ                                                                            | 該当なし                                                                  | 該当なし                                                                  | 現在の実装の複雑さ、顧客の関心の低さ、およびフックに代わるものの利用可能性のため、計画されていません。 |
| [Elasticsearch](../../../integration/advanced_search/elasticsearch.md)                                    | [計画なし](https://gitlab.com/gitlab-org/gitlab/-/issues/1186)             | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              | さらなる製品発見が必要であり、Elasticsearch（ES）クラスターは再構築できるため、計画されていません。セカンダリは、プライマリと同じESクラスターを使用します。 |
| [依存プロキシ画像](../../../user/packages/dependency_proxy/_index.md)                                           | [**可能**（15.7）](https://gitlab.com/groups/gitlab-org/-/epics/8833)           | [**可能**（15.7）](https://gitlab.com/groups/gitlab-org/-/epics/8833)           | [**可能**（15.7）](https://gitlab.com/groups/gitlab-org/-/epics/8833)             | [**可能**（16.4）<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) |       |
| [脆弱性エクスポート](../../../user/application_security/vulnerability_report/_index.md#exporting) | [計画なし](https://gitlab.com/groups/gitlab-org/-/epics/3111)              | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              | それらは一時的なものであり、機密情報であるため、計画されていません。必要に応じて再生成できます。 |
| パッケージNPMメタデータキャッシュ                                                                                           | [計画なし](https://gitlab.com/gitlab-org/gitlab/-/issues/408278)           | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              | ディザスターリカバリー機能もセカンダリサイトでの応答時間も著しく改善しないため、計画されていません。 |
| パッケージDebian GroupComponentFile                                                                                    | [計画なし](https://gitlab.com/gitlab-org/gitlab/-/issues/556945)           | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              |       |
| パッケージDebian ProjectComponentFile                                                                                  | [計画なし](https://gitlab.com/gitlab-org/gitlab/-/issues/333611)           | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              |       |
| パッケージDebian GroupDistribution                                                                                     | [計画なし](https://gitlab.com/gitlab-org/gitlab/-/issues/556947)           | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              |       |
| パッケージDebian ProjectDistribution                                                                                   | [計画なし](https://gitlab.com/gitlab-org/gitlab/-/issues/556946)           | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              |       |
| パッケージRPMリポジトリFile                                                                                           | [計画なし](https://gitlab.com/gitlab-org/gitlab/-/issues/379055)           | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              |       |
| パッケージNuGet Symbol                                                                                                 | [計画なし](https://gitlab.com/gitlab-org/gitlab/-/issues/422929)           | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              |       |
| VirtualRegistries Mavenキャッシュエントリ                                                                                   | [計画なし](https://gitlab.com/gitlab-org/gitlab/-/issues/473033)           | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              |       |
| SBOM脆弱性スキャンデータ                                                                                           | [計画なし](https://gitlab.com/gitlab-org/gitlab/-/issues/398199)           | いいえ                                                                            | いいえ                                                                              | いいえ                                                                              | データが一時的なものであり、ディザスターリカバリー機能およびセカンダリサイトでの影響が限定的であるため、計画されていません。 |

**脚注**: 

1. 15.5でセルフサービスフレームワークに移行されました。詳細については、GitLabイシュー[\#337436](https://gitlab.com/gitlab-org/gitlab/-/issues/337436)を参照してください。
1. 15.11でセルフサービスフレームワークに移行されました。機能フラグ`geo_project_wiki_repository_replication`の背後で、デフォルトで有効になっています。詳細については、GitLabイシュー[\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925)を参照してください。
1. オブジェクトストレージに保存されたファイルの検証は、GitLab 16.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/8056)され、`geo_object_storage_verification`という名前の[機能フラグ](../../feature_flags/_index.md)でデフォルトで有効になりました。
