---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Composer API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[Composerパッケージマネージャークライアント](../../user/packages/composer_repository/_index.md)と対話します。

> [!warning]
> このAPIは[Composerパッケージマネージャークライアント](https://getcomposer.org/)によって使用され、通常は手動での利用を意図していません。

これらのエンドポイントは、標準のAPI認証方法に準拠していません。サポートされているヘッダーとトークンのタイプに関する詳細は、[Composerパッケージレジストリドキュメント](../../user/packages/composer_repository/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

## リポジトリURLテンプレートを取得する {#retrieve-repository-url-templates}

グループの個々のパッケージをリクエストするための、リポジトリURLテンプレートを取得する。

```plaintext
GET group/:id/-/packages/composer/packages
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | グループのIDまたは完全なパス。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/packages"
```

レスポンス例: 

```json
{
  "packages": [],
  "metadata-url": "/api/v4/group/1/-/packages/composer/p2/%package%.json",
  "provider-includes": {
    "p/%hash%.json": {
      "sha256": "082df4a5035f8725a12a4a3d2da5e6aaa966d06843d0a5c6d499313810427bd6"
    }
  },
  "providers-url": "/api/v4/group/1/-/packages/composer/%package%$%hash%.json"
}
```

このエンドポイントはComposer V1およびV2で使用されます。V2固有のレスポンスを確認するには、Composer `User-Agent`ヘッダーを含めてください。Composer V2の使用をV1よりも推奨します。

```shell
curl --user <username>:<personal_access_token> \
     --header "User-Agent: Composer/2" \
     --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/packages"
```

レスポンス例: 

```json
{
  "packages": [],
  "metadata-url": "/api/v4/group/1/-/packages/composer/p2/%package%.json"
}
```

## V1パッケージリスト {#v1-packages-list}

V1プロバイダーSHAを指定して、グループのリポジトリ内のパッケージのリストを取得する。Composer V2の使用をV1よりも推奨します。

```plaintext
GET group/:id/-/packages/composer/p/:sha
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | はい | グループのIDまたは完全なパス。 |
| `sha`     | 文字列 | はい | Composerの[base request](#retrieve-repository-url-templates)によって提供されるプロバイダーSHA。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/p/082df4a5035f8725a12a4a3d2da5e6aaa966d06843d0a5c6d499313810427bd6"
```

レスポンス例: 

```json
{
  "providers": {
    "my-org/my-composer-package": {
      "sha256": "5c873497cdaa82eda35af5de24b789be92dfb6510baf117c42f03899c166b6e7"
    }
  }
}
```

## V1パッケージメタデータを取得する {#retrieve-v1-package-metadata}

グループの指定されたパッケージのバージョンとメタデータのリストを取得する。Composer V2の使用をV1よりも推奨します。

```plaintext
GET group/:id/-/packages/composer/:package_name$:sha
```

URL内の`$`記号に注意してください。リクエストを行う場合、`%24`記号のURLエンコードされたバージョンが必要になる場合があります。表の後にある例を参照してください:

| 属性      | 型   | 必須 | 説明                                                                           |
|----------------|--------|----------|---------------------------------------------------------------------------------------|
| `id`           | 文字列 | はい      | グループのIDまたは完全なパス。                                                     |
| `package_name` | 文字列 | はい      | パッケージ名。                                                              |
| `sha`          | 文字列 | はい      | [V1パッケージリスト](#v1-packages-list)によって提供される、パッケージのSHAダイジェスト。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/my-org/my-composer-package%245c873497cdaa82eda35af5de24b789be92dfb6510baf117c42f03899c166b6e7"
```

レスポンス例: 

```json
{
  "packages": {
    "my-org/my-composer-package": {
      "1.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "1.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      },
      "2.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "2.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      }
    }
  }
}
```

## V2パッケージメタデータを取得する {#retrieve-v2-package-metadata}

グループの指定されたパッケージのバージョンとメタデータのリストを取得する。

```plaintext
GET group/:id/-/packages/composer/p2/:package_name
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 文字列 | はい      | グループのIDまたは完全なパス。 |
| `package_name` | 文字列 | はい      | パッケージ名。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/p2/my-org/my-composer-package"
```

レスポンス例: 

```json
{
  "packages": {
    "my-org/my-composer-package": {
      "1.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "1.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      },
      "2.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "2.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      }
    }
  }
}
```

## パッケージを作成する {#create-a-package}

指定されたGitタグまたはブランチから、プロジェクト用のComposerパッケージを作成します。

```plaintext
POST projects/:id/packages/composer
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | グループのIDまたは完全なパス。 |
| `tag`     | 文字列 | いいえ       | パッケージのターゲットとなるタグの名前。 |
| `branch`  | 文字列 | いいえ       | パッケージのターゲットとなるブランチの名前。 |

```shell
curl --request POST --user <username>:<personal_access_token> \
     --data tag=v1.0.0 \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/composer"
```

レスポンス例: 

```json
{
  "message": "201 Created"
}
```

## パッケージアーカイブをダウンロードする {#download-a-package-archive}

プロジェクトの指定されたComposerパッケージアーカイブをダウンロードします。このURLは、[v1](#retrieve-v1-package-metadata)または[v2パッケージメタデータ](#retrieve-v2-package-metadata)レスポンスで提供されます。`.zip`ファイル拡張子がリクエストに含まれている必要があります。

```plaintext
GET projects/:id/packages/composer/archives/:package_name
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 文字列 | はい      | グループのIDまたは完全なパス。 |
| `package_name` | 文字列 | はい      | パッケージ名。 |
| `sha`          | 文字列 | はい      | パッケージバージョンのターゲットSHA。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
```

出力をファイルに書き込む:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab" >> package.zip
```

これにより、ダウンロードされたファイルが現在のディレクトリの`package.zip`に書き込まれます。
