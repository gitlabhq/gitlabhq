---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: NuGet API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

これは、[NuGetパッケージ](../../user/packages/nuget_repository/_index.md)のAPIドキュメントです。

{{< alert type="warning" >}}

このAPIは、[NuGetパッケージマネージャー](https://www.nuget.org/)クライアントで使用され、通常は手動での使用を目的としていません。

{{< /alert >}}

GitLabパッケージレジストリからNuGetパッケージをアップロードおよびインストールする方法については、[NuGetパッケージレジストリのドキュメント](../../user/packages/nuget_repository/_index.md)を参照してください。

{{< alert type="note" >}}

これらのエンドポイントは、標準のAPI認証方式に準拠していません。どのヘッダーとトークンタイプがサポートされているかの詳細については、[NuGetパッケージレジストリドキュメント](../../user/packages/nuget_repository/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

{{< /alert >}}

## パッケージインデックス {#package-index}

指定されたパッケージのインデックスを返します。これには、利用可能なバージョンのリストが含まれます:

```plaintext
GET projects/:id/packages/nuget/download/:package_name/index
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 文字列 | はい      | プロジェクトのIDまたはフルパス。 |
| `package_name` | 文字列 | はい      | パッケージの名前。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/index"
```

レスポンス例:

```json
{
  "versions": [
    "1.3.0.17"
  ]
}
```

## パッケージファイルをダウンロードする {#download-a-package-file}

NuGetパッケージファイルをダウンロードします。[メタデータサービス](#metadata-service)は、このURLを提供します。

```plaintext
GET projects/:id/packages/nuget/download/:package_name/:package_version/:package_filename
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 文字列 | はい      | プロジェクトのIDまたはフルパス。 |
| `package_name`    | 文字列 | はい      | パッケージの名前。 |
| `package_version` | 文字列 | はい      | パッケージのバージョン。 |
| `package_filename`| 文字列 | はい      | ファイルの名前。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/mynugetpkg.1.3.0.17.nupkg"
```

出力をファイルに書き込みます:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/mynugetpkg.1.3.0.17.nupkg" > MyNuGetPkg.1.3.0.17.nupkg
```

これにより、ダウンロードされたファイルが現在のディレクトリの`MyNuGetPkg.1.3.0.17.nupkg`に書き込まれます。

{{< alert type="note" >}}

[グループエンドポイント](#group-level)を使用すると、このAPIは`404`ステータスを返します。このエラーを回避するには、NuGetパッケージマネージャーCLIを使用して、グループエンドポイントで[パッケージをインストール](../../user/packages/nuget_repository/_index.md#install-a-package)します。

{{< /alert >}}

## パッケージファイルをアップロード {#upload-a-package-file}

{{< history >}}

- NuGet v2フィードの場合、GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416404)されました。

{{< /history >}}

NuGetパッケージファイルをアップロードします:

- NuGet v3フィードの場合:

  ```plaintext
  PUT projects/:id/packages/nuget
  ```

- NuGet V2フィードの場合:

  ```plaintext
  PUT projects/:id/packages/nuget/v2
  ```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 文字列 | はい      | プロジェクトのIDまたはフルパス。 |
| `package_name`    | 文字列 | はい      | パッケージの名前。 |
| `package_version` | 文字列 | はい      | パッケージのバージョン。 |
| `package_filename`| 文字列 | はい      | ファイルの名前。 |

- NuGet v3フィードの場合:

  ```shell
  curl --request PUT \
      --form 'package=@path/to/mynugetpkg.1.3.0.17.nupkg' \
      --user <username>:<personal_access_token> \
      --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/"
  ```

- NuGet v2フィードの場合:

  ```shell
  curl --request PUT \
      --form 'package=@path/to/mynugetpkg.1.3.0.17.nupkg' \
      --user <username>:<personal_access_token> \
      --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"
  ```

## シンボルパッケージファイルをアップロード {#upload-a-symbol-package-file}

NuGetシンボルパッケージファイルをアップロードします(`.snupkg`):

```plaintext
PUT projects/:id/packages/nuget/symbolpackage
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 文字列 | はい      | プロジェクトのIDまたはフルパス。 |
| `package_name`    | 文字列 | はい      | パッケージの名前。 |
| `package_version` | 文字列 | はい      | パッケージのバージョン。 |
| `package_filename`| 文字列 | はい      | ファイルの名前。 |

```shell
curl --request PUT \
     --form 'package=@path/to/mynugetpkg.1.3.0.17.snupkg' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolpackage"
```

## ルートプレフィックス {#route-prefix}

残りのルートでは、それぞれ異なるスコープでリクエストを行う、同一のルートの2つのセットがあります:

- グループレベルのプレフィックスを使用して、グループのスコープでリクエストを行います。
- プロジェクトレベルのプレフィックスを使用して、単一のプロジェクトのスコープでリクエストを行います。

このドキュメントの例ではすべて、プロジェクトレベルのプレフィックスを使用しています。

### グループレベル {#group-level}

```plaintext
/groups/:id/-/packages/nuget
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | グループIDまたは完全なグループパス。 |

### プロジェクトレベル {#project-level}

```plaintext
/projects/:id/packages/nuget
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。 |

## サービスインデックス {#service-index}

### V2ソースフィード/プロトコル {#v2-source-feedprotocol}

v2 NuGetソースフィードのサービスインデックスを表すXMLドキュメントを返します。認証は必須ではありません:

```plaintext
GET <route-prefix>/v2
```

リクエスト例:

```shell
curl "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"
```

レスポンス例:

```xml
<?xml version="1.0" encoding="utf-8"?>
<service xmlns="http://www.w3.org/2007/app" xmlns:atom="http://www.w3.org/2005/Atom" xml:base="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2">
  <workspace>
    <atom:title type="text">Default</atom:title>
    <collection href="Packages">
      <atom:title type="text">Packages</atom:title>
    </collection>
  </workspace>
</service>
```

### V3ソースフィード/プロトコル {#v3-source-feedprotocol}

{{< history >}}

- GitLab 16.1でパブリックになるように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/214674)されました。

{{< /history >}}

利用可能なAPIリソースのリストを返します。認証は必須ではありません:

```plaintext
GET <route-prefix>/index
```

リクエスト例:

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/index"
```

レスポンス例:

```json
{
  "version": "3.0.0",
  "resources": [
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query",
      "@type": "SearchQueryService",
      "comment": "Filter and search for packages by keyword."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query",
      "@type": "SearchQueryService/3.0.0-beta",
      "comment": "Filter and search for packages by keyword."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query",
      "@type": "SearchQueryService/3.0.0-rc",
      "comment": "Filter and search for packages by keyword."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata",
      "@type": "RegistrationsBaseUrl",
      "comment": "Get package metadata."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata",
      "@type": "RegistrationsBaseUrl/3.0.0-beta",
      "comment": "Get package metadata."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata",
      "@type": "RegistrationsBaseUrl/3.0.0-rc",
      "comment": "Get package metadata."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download",
      "@type": "PackageBaseAddress/3.0.0",
      "comment": "Get package content (.nupkg)."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget",
      "@type": "PackagePublish/2.0.0",
      "comment": "Push and delete (or unlist) packages."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolpackage",
      "@type": "SymbolPackagePublish/4.9.0",
      "comment": "Push symbol packages."
    }
  ]
}
```

レスポンス内のURLには、リクエストに使用されるものと同じルートプレフィックスがあります。グループレベルのルートでそれらをリクエストすると、返されるURLには`/groups/:id/-`が含まれます。

## メタデータサービス {#metadata-service}

パッケージのメタデータを返します:

```plaintext
GET <route-prefix>/metadata/:package_name/index
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `package_name` | 文字列 | はい      | パッケージの名前。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/index"
```

レスポンス例:

```json
{
  "count": 1,
  "items": [
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
      "lower": "1.3.0.17",
      "upper": "1.3.0.17",
      "count": 1,
      "items": [
        {
          "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
          "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
          "catalogEntry": {
            "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
            "authors": "Author1, Author2",
            "dependencyGroups": [],
            "id": "MyNuGetPkg",
            "version": "1.3.0.17",
            "tags": "",
            "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
            "description": "Description of the package",
            "summary": "Description of the package",
            "published": "2023-05-08T17:23:25Z",
          }
        }
      ]
    }
  ]
}
```

## バージョンメタデータサービス {#version-metadata-service}

特定のパッケージバージョンのメタデータを返します:

```plaintext
GET <route-prefix>/metadata/:package_name/:package_version
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `package_name`    | 文字列 | はい      | パッケージの名前。    |
| `package_version` | 文字列 | はい      | パッケージのバージョン。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17"
```

レスポンス例:

```json
{
  "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
  "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
  "catalogEntry": {
    "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
    "authors": "Author1, Author2",
    "dependencyGroups": [],
    "id": "MyNuGetPkg",
    "version": "1.3.0.17",
    "tags": "",
    "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
    "description": "Description of the package",
    "summary": "Description of the package",
    "published": "2023-05-08T17:23:25Z",
  }
}
```

## 検索サービス {#search-service}

クエリを指定すると、リポジトリ内のNuGetパッケージを検索します:

```plaintext
GET <route-prefix>/query
```

| 属性    | 型    | 必須 | 説明 |
| ------------ | ------- | -------- | ----------- |
| `q`          | 文字列  | はい      | 検索クエリ。 |
| `skip`       | 整数 | いいえ       | スキップする結果の数。 |
| `take`       | 整数 | いいえ       | 返す結果の数。 |
| `prerelease` | ブール値 | いいえ       | プレリリースバージョンを含めます。値が指定されていない場合は、`true`にデフォルト設定されます。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query?q=MyNuGet"
```

レスポンス例:

```json
{
  "totalHits": 1,
  "data": [
    {
      "@type": "Package",
      "authors": "Author1, Author2",
      "id": "MyNuGetPkg",
      "title": "MyNuGetPkg",
      "description": "Description of the package",
      "summary": "Description of the package",
      "totalDownloads": 0,
      "verified": true,
      "version": "1.3.0.17",
      "versions": [
        {
          "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
          "version": "1.3.0.17",
          "downloads": 0
        }
      ],
      "tags": ""
    }
  ]
}
```

## サービスの削除 {#delete-service}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/38275)されました。

{{< /history >}}

NuGetパッケージを削除します:

```plaintext
DELETE projects/:id/packages/nuget/:package_name/:package_version
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 文字列 | はい      | プロジェクトのIDまたはフルパス。 |
| `package_name`    | 文字列 | はい      | パッケージの名前。 |
| `package_version` | 文字列 | はい      | パッケージのバージョン。 |

```shell
curl --request DELETE \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/MyNuGetPkg/1.3.0.17"
```

リクエストに対する考えられるレスポンス:

| ステータス | 説明 |
| ------ | ----------- |
| `204`  | パッケージが削除されました |
| `401`  | 認証されていません |
| `403`  | 禁止されています |
| `404`  | 見つかりません |

## デバッグシンボルファイル`.pdb`をダウンロードします {#download-a-debugging-symbol-file-pdb}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416178)されました。

{{< /history >}}

デバッグシンボルファイル(`.pdb`)をダウンロード:

```plaintext
GET <route-prefix>/symbolfiles/:file_name/:signature/:file_name
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `file_name`       | 文字列 | はい      | ファイルの名前。 |
| `signature`       | 文字列 | はい      | ファイルの署名。 |
| `Symbolchecksum` | 文字列 | はい      | 必須ヘッダー。ファイルのチェックサム。 |

```shell
curl --header "Symbolchecksum: SHA256:<file_checksum>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolfiles/:file_name/:signature/:file_name"
```

出力をファイルに書き込みます:

```shell
curl --header "Symbolchecksum: SHA256:<file_checksum>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolfiles/mynugetpkg.pdb/k813f89485474661234z7109cve5709eFFFFFFFF/mynugetpkg.pdb" > mynugetpkg.pdb
```

リクエストに対する考えられるレスポンス:

| ステータス | 説明 |
| ------ | ----------- |
| `200`  | ファイルがダウンロードされました |
| `400`  | 無効なリクエスト |
| `403`  | 禁止されています |
| `404`  | 見つかりません |

## V2フィードメタデータエンドポイント {#v2-feed-metadata-endpoints}

{{< history >}}

- GitLab 16.3で導入されました。

{{< /history >}}

### $metadataエンドポイント {#metadata-endpoint}

認証は必須ではありません。V2フィードで使用可能なエンドポイントのメタデータを返します:

```plaintext
GET <route-prefix>/v2/$metadata
```

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/$metadata"
```

レスポンス例:

```xml
<edmx:Edmx xmlns:edmx="http://schemas.microsoft.com/ado/2007/06/edmx" Version="1.0">
  <edmx:DataServices xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" m:DataServiceVersion="2.0" m:MaxDataServiceVersion="2.0">
    <Schema xmlns="http://schemas.microsoft.com/ado/2006/04/edm" Namespace="NuGetGallery.OData">
      <EntityType Name="V2FeedPackage" m:HasStream="true">
        <Key>
          <PropertyRef Name="Id"/>
          <PropertyRef Name="Version"/>
        </Key>
        <Property Name="Id" Type="Edm.String" Nullable="false"/>
        <Property Name="Version" Type="Edm.String" Nullable="false"/>
        <Property Name="Authors" Type="Edm.String"/>
        <Property Name="Dependencies" Type="Edm.String"/>
        <Property Name="Description" Type="Edm.String"/>
        <Property Name="DownloadCount" Type="Edm.Int64" Nullable="false"/>
        <Property Name="IconUrl" Type="Edm.String"/>
        <Property Name="Published" Type="Edm.DateTime" Nullable="false"/>
        <Property Name="ProjectUrl" Type="Edm.String"/>
        <Property Name="Tags" Type="Edm.String"/>
        <Property Name="Title" Type="Edm.String"/>
        <Property Name="LicenseUrl" Type="Edm.String"/>
      </EntityType>
    </Schema>
    <Schema xmlns="http://schemas.microsoft.com/ado/2006/04/edm" Namespace="NuGetGallery">
      <EntityContainer Name="V2FeedContext" m:IsDefaultEntityContainer="true">
        <EntitySet Name="Packages" EntityType="NuGetGallery.OData.V2FeedPackage"/>
        <FunctionImport Name="FindPackagesById" ReturnType="Collection(NuGetGallery.OData.V2FeedPackage)" EntitySet="Packages">
          <Parameter Name="id" Type="Edm.String" FixedLength="false" Unicode="false"/>
        </FunctionImport>
      </EntityContainer>
    </Schema>
  </edmx:DataServices>
</edmx:Edmx>
```

### ODataパッケージエントリエンドポイント {#odata-package-entry-endpoints}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127667)されました。

{{< /history >}}

| エンドポイント | 説明 |
| -------- | ----------- |
| `GET projects/:id/packages/nuget/v2/Packages()?$filter=(tolower(Id) eq '<package_name>')` | 指定された名前のパッケージに関する情報を含むOData XMLドキュメントを返します。 |
| `GET projects/:id/packages/nuget/v2/FindPackagesById()?id='<package_name>'` | 指定された名前のパッケージに関する情報を含むOData XMLドキュメントを返します。 |
| `GET projects/:id/packages/nuget/v2/Packages(Id='<package_name>',Version='<package_version>')` | 指定された名前とバージョンのパッケージに関する情報を含むOData XMLドキュメントを返します。 |

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages(Id='mynugetpkg',Version='1.0.0')"
```

レスポンス例:

```xml
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices" xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml" xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xml:base="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2">
    <id>https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages(Id='mynugetpkg',Version='1.0.0')</id>
    <category term="V2FeedPackage" scheme="http://schemas.microsoft.com/ado/2007/08/dataservices/scheme"/>
    <title type="text">mynugetpkg</title>
    <content type="application/zip" src="https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/mynugetpkg/1.0.0/mynugetpkg.1.0.0.nupkg"/>
    <m:properties>
      <d:Version>1.0.0</d:Version>
    </m:properties>
 </entry>
```

{{< alert type="note" >}}

GitLabは、`Packages()`および`FindPackagesByID()`エンドポイントの認証トークンを受信しないため、パッケージの最新バージョンを返すことができません。NuGet v2フィードを使用してパッケージをインストールまたはバージョンアップグレードする場合は、バージョンを指定する必要があります。

{{< /alert >}}

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages()?$filter=(tolower(Id) eq 'mynugetpkg')"
```

レスポンス例:

```xml
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices" xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml" xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xml:base="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2">
    <id>https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages(Id='mynugetpkg',Version='')</id>
    <category term="V2FeedPackage" scheme="http://schemas.microsoft.com/ado/2007/08/dataservices/scheme"/>
    <title type="text">mynugetpkg</title>
    <content type="application/zip" src="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"/>
    <m:properties>
      <d:Version></d:Version>
    </m:properties>
 </entry>
```
