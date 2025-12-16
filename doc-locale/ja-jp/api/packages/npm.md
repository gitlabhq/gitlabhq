---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: npm 
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[npmパッケージマネージャー](../../user/packages/npm_registry/_index.md)クライアントとやり取りします。

{{< alert type="warning" >}}

このAPIは、[npmパッケージマネージャー](https://docs.npmjs.com/)クライアントで使用され、手動で使用することを意図したものではありません。

{{< /alert >}}

{{< alert type="note" >}}

これらのエンドポイントは、標準のAPI認証方式に準拠していません。サポートされているヘッダーとトークンの種類について詳しくは、[npmパッケージレジストリのドキュメント](../../user/packages/npm_registry/_index.md)を参照してください。文書化されていない認証方式は、将来削除される可能性があります。記載されていない認証方法は、将来削除される可能性があります。

{{< /alert >}}

## パッケージをダウンロードする {#download-a-package}

npmパッケージをダウンロードします。このURLは、[メタデータエンドポイント](#metadata)によって提供されます。

```plaintext
GET projects/:id/packages/npm/:package_name/-/:file_name
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 文字列 | はい      | プロジェクトのIDまたはフルパス。 |
| `package_name`    | 文字列 | はい      | パッケージの名前。 |
| `file_name`       | 文字列 | はい      | パッケージファイルの名前。 |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@my-scope/my-pkg-0.0.1.tgz"
```

ファイルに出力を書き込みます:

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@my-scope/my-pkg-0.0.1.tgz" >> @myscope/my-pkg-0.0.1.tgz
```

これにより、ダウンロードされたファイルが現在のディレクトリの`@myscope/my-pkg-0.0.1.tgz`に書き込まれます。

## パッケージファイルをアップロードします {#upload-a-package-file}

パッケージをアップロードします。

```plaintext
PUT projects/:id/packages/npm/:package_name
```

| 属性      | 型   | 必須 | 説明                         |
|----------------|--------|----------|-------------------------------------|
| `id`           | 文字列 | はい      | プロジェクトのIDまたはフルパス。 |
| `package_name` | 文字列 | はい      | パッケージの名前。            |
| `versions`     | 文字列 | はい      | パッケージのバージョン情報。        |

```shell
curl --request PUT
     --header "Content-Type: application/json"
     --data @./path/to/metadata/file.json
     --header "Authorization: Bearer <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope%2fmy-pkg"
```

メタデータファイルの内容はnpmによって生成されますが、次のようになります:

```json
{
    "_attachments": {
        "@myscope/my-pkg-1.3.7.tgz": {
            "content_type": "application/octet-stream",
            "data": "H4sIAAAAAAAAE+1TQUvDMBjdeb/iI4edZEldV2dPwhARPIjiyXlI26zN1iYhSeeK7L+bNJtednMg4l4OKe+9PF7DF0XzNS0ZVmEfr4wUgxODEJLEMRzjPRJyCYPJNCFRlCTE+dzH1PvJqYscQ2ss1a7KT3PCv8DX/kfwMQRAgjYMpYBuIoIzKtwy6MILG6YNl8Jr0XgyvgpswUyuubJ75TGMDuSaUcsKyDooa1C6De6G8t7GRcG2br4CGxKME3wDR1hmrLexvJKwQLdaS52CkOAFMIrlfMlZsUAwGgHbcgsRcid3fdqade9SFz7u9a1naGsrqX3gHbcPNINDyydWcmN1By+W19x2oU7NcyZMfwn3z/PAqTaruanmUix5+V3UXVKq9yEoRZW1yqQYl9zWNBvnssFUcbyJsdJyxXJrcHQdz8gsTg6PzGChGty3H+6Gvz0BZ5xxxn/FJ1EDRNIACAAA",
            "length": 354
        }
    },
    "_id": "@myscope/my-pkg",
    "description": "Package created by me",
    "dist-tags": {
        "latest": "1.3.7"
    },
    "name": "@myscope/my-pkg",
    "readme": "ERROR: No README data found!",
    "versions": {
        "1.3.7": {
            "_id": "@myscope/my-pkg@1.3.7",
            "_nodeVersion": "12.18.4",
            "_npmVersion": "6.14.6",
            "author": {
                "name": "GitLab package registry Utility"
            },
            "description": "Package created by me",
            "dist": {
                "integrity": "sha512-loy16p+Dtw2S43lBmD3Nye+t+Vwv7Tbhv143UN2mwcjaHJyBfGZdNCTXnma3gJCUSE/AR4FPGWEyCOOTJ+ev9g==",
                "shasum": "4a9dbd94ca6093feda03d909f3d7e6bd89d9d4bf",
                "tarball": "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@myscope/my-pkg-1.3.7.tgz"
            },
            "keywords": [],
            "license": "ISC",
            "main": "index.js",
            "name": "@myscope/my-pkg",
            "publishConfig": {
                "@myscope:registry": "https://gitlab.example.com/api/v4/projects/1/packages/npm"
            },
            "readme": "ERROR: No README data found!",
            "scripts": {
                "test": "echo \"Error: no test specified\" && exit 1"
            },
            "version": "1.3.7"
        }
    }
}
```

## ルートプレフィックス {#route-prefix}

残りのルートには、それぞれ異なるスコープでリクエストを行う、同一のルートが2組あります:

- インスタンスレベルのプレフィックスを使用して、インスタンス全体のスコープでリクエストを行います。
- プロジェクトレベルのプレフィックスを使用して、単一プロジェクトのスコープでリクエストを行います。
- グループレベルのプレフィックスを使用して、グループのスコープでリクエストを行います。

このドキュメントの例はすべて、プロジェクトレベルのプレフィックスを使用しています。

### インスタンスレベル {#instance-level}

```plaintext
/packages/npm
```

### プロジェクトレベル {#project-level}

```plaintext
/projects/:id/packages/npm
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。 |

### グループレベル {#group-level}

{{< history >}}

- GitLab 16.0で`npm_group_level_endpoints`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/299834)されました。デフォルトでは無効になっています。
- GitLab 16.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121837)になりました。機能フラグ`npm_group_level_endpoints`は削除されました。

{{< /history >}}

```plaintext
/groups/:id/-/packages/npm
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | グループIDまたはフルグループパス。 |

## メタデータ {#metadata}

指定されたパッケージのメタデータを返します。

```plaintext
GET <route-prefix>/:package_name
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `package_name` | 文字列 | はい      | パッケージの名前。 |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg"
```

レスポンス例:

```json
{
  "name": "@myscope/my-pkg",
  "versions": {
    "0.0.2": {
      "name": "@myscope/my-pkg",
      "version": "0.0.1",
      "dist": {
        "shasum": "93abb605b1110c0e3cca0a5b805e5cb01ac4ca9b",
        "tarball": "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@myscope/my-pkg-0.0.1.tgz"
      }
    }
  },
  "dist-tags": {
    "latest": "0.0.1"
  }
}
```

レスポンス内のURLは、それらのリクエストに使用されたものと同じルートプレフィックスを持ちます。インスタンスレベルのルートでそれらをリクエストすると、返されるURLには`/api/v4/packages/npm`が含まれます。

## Dist-タグ {#dist-tags}

### タグをリストします {#list-tags}

パッケージのdist-タグをリストします。

```plaintext
GET <route-prefix>/-/package/:package_name/dist-tags
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `package_name` | 文字列 | はい      | パッケージの名前。 |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/-/package/@myscope/my-pkg/dist-tags"
```

レスポンス例:

```json
{
  "latest": "2.1.1",
  "stable": "1.0.0"
}
```

レスポンス内のURLは、それらのリクエストに使用されたものと同じルートプレフィックスを持ちます。インスタンスレベルのルートでそれらをリクエストすると、返されるURLには`/api/v4/packages/npm`が含まれます。

### タグを作成または更新します {#create-or-update-a-tag}

dist-タグを作成または更新します。

```plaintext
PUT <route-prefix>/-/package/:package_name/dist-tags/:tag
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `package_name` | 文字列 | はい      | パッケージの名前。 |
| `tag`          | 文字列 | はい      | 作成または更新されるタグ。 |
| `version`      | 文字列 | はい      | タグ付けされるバージョン。 |

```shell
curl --request PUT --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/-/package/@myscope/my-pkg/dist-tags/stable"
```

このエンドポイントは、`204 No Content`で正常に応答します。

### タグを削除する {#delete-a-tag}

ディストリビューションタグを削除します。

```plaintext
DELETE <route-prefix>/-/package/:package_name/dist-tags/:tag
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `package_name` | 文字列 | はい      | パッケージの名前。 |
| `tag`          | 文字列 | はい      | 作成または更新されるタグ。 |

```shell
curl --request DELETE --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/-/package/@myscope/my-pkg/dist-tags/stable"
```

このエンドポイントは、`204 No Content`で正常に応答します。
