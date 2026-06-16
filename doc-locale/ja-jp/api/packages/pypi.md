---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PyPI API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[PyPIパッケージマネージャークライアント](../../user/packages/pypi_repository/_index.md)と対話します。

> [!warning]
> このAPIは[PyPIパッケージマネージャークライアント](https://pypi.org/)によって使用されるものであり、通常は手動での利用を意図していません。

これらのエンドポイントは、標準のAPI認証方法に準拠していません。[PyPIパッケージレジストリドキュメント](../../user/packages/pypi_repository/_index.md)で、どのヘッダーとトークンタイプがサポートされているかの詳細を確認してください。記載されていない認証方法は、将来削除される可能性があります。

> [!note]
> [Twine 3.4.2](https://twine.readthedocs.io/en/stable/changelog.html?highlight=FIPS#id28)以降は、FIPSモードが有効な場合に推奨されます。

## グループのパッケージファイルをダウンロード {#download-a-package-file-for-a-group}

指定されたPyPIパッケージファイルをグループ用にダウンロードします。このURLは通常、[シンプルなAPI](#retrieve-package-descriptor-for-a-group)が提供します。

```plaintext
GET groups/:id/-/packages/pypi/files/:sha256/:file_identifier
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 文字列 | はい      | グループのIDまたは完全なパス。 |
| `sha256`          | 文字列 | はい      | PyPIパッケージファイルのsha256チェックサム。 |
| `file_identifier` | 文字列 | はい      | PyPIパッケージファイル名。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz"
```

出力をファイルに書き込むには:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz" >> my.pypi.package-0.0.1.tar.gz
```

これにより、ダウンロードされたファイルが現在のディレクトリの`my.pypi.package-0.0.1.tar.gz`に書き込まれます。

## グループのすべてのパッケージを一覧表示 {#list-all-packages-for-a-group}

指定されたグループのすべてのパッケージをHTMLファイルで一覧表示します。

```plaintext
GET groups/:id/-/packages/pypi/simple
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列 | はい | グループのIDまたは完全なパス。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple"
```

レスポンス例: 

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for Group</title>
  </head>
  <body>
    <h1>Links for Group</h1>
    <a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my-pypi-package" data-requires-python="">my.pypi.package</a><br><a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/package-2" data-requires-python="3.8">package_2</a><br>
  </body>
</html>
```

出力をファイルに書き込むには:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple" >> simple_index.html
```

これにより、ダウンロードされたファイルが現在のディレクトリの`simple_index.html`に書き込まれます。

## グループのパッケージディスクリプタを取得する {#retrieve-package-descriptor-for-a-group}

指定されたグループ内のパッケージのパッケージディスクリプタをHTMLファイルとして取得します。

```plaintext
GET groups/:id/-/packages/pypi/simple/:package_name
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 文字列 | はい      | グループのIDまたは完全なパス。 |
| `package_name` | 文字列 | はい      | パッケージ名。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my.pypi.package"
```

レスポンス例: 

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for my.pypi.package</title>
  </head>
  <body>
    <h1>Links for my.pypi.package</h1>
    <a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1-py3-none-any.whl#sha256=5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1-py3-none-any.whl</a><br><a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/9s9w01b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2/my.pypi.package-0.0.1.tar.gz#sha256=9s9w011b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1.tar.gz</a><br>
  </body>
</html>
```

出力をファイルに書き込むには:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my.pypi.package" >> simple.html
```

これにより、ダウンロードされたファイルが現在のディレクトリの`simple.html`に書き込まれます。

## プロジェクト用のパッケージファイルをダウンロードする {#download-a-package-file-for-a-project}

指定されたPyPIパッケージファイルをプロジェクト用にダウンロードします。このURLは通常、[シンプルなAPI](#retrieve-package-descriptor-for-a-project)が提供します。

```plaintext
GET projects/:id/packages/pypi/files/:sha256/:file_identifier
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`              | 文字列 | はい | プロジェクトのIDまたは完全なパス。 |
| `sha256`          | 文字列 | はい | PyPIパッケージファイルのsha256チェックサム。 |
| `file_identifier` | 文字列 | はい | PyPIパッケージファイル名。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz"
```

出力をファイルに書き込むには:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz" >> my.pypi.package-0.0.1.tar.gz
```

これにより、ダウンロードされたファイルが現在のディレクトリの`my.pypi.package-0.0.1.tar.gz`に書き込まれます。

## プロジェクトのすべてのパッケージを一覧表示 {#list-all-packages-for-a-project}

指定されたプロジェクトのすべてのパッケージをHTMLファイルで一覧表示します。

```plaintext
GET projects/:id/packages/pypi/simple
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列 | はい | プロジェクトのIDまたは完全なパス。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple"
```

レスポンス例: 

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for Project</title>
  </head>
  <body>
    <h1>Links for Project</h1>
    <a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my-pypi-package" data-requires-python="">my.pypi.package</a><br><a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/package-2" data-requires-python="3.8">package_2</a><br>
  </body>
</html>
```

出力をファイルに書き込むには:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple" >> simple_index.html
```

これにより、ダウンロードされたファイルが現在のディレクトリの`simple_index.html`に書き込まれます。

## プロジェクトのパッケージディスクリプタを取得する {#retrieve-package-descriptor-for-a-project}

指定されたプロジェクト内のパッケージのパッケージディスクリプタをHTMLファイルとして取得します。

```plaintext
GET projects/:id/packages/pypi/simple/:package_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`           | 文字列 | はい | プロジェクトのIDまたは完全なパス。 |
| `package_name` | 文字列 | はい | パッケージ名。 |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my.pypi.package"
```

レスポンス例: 

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for my.pypi.package</title>
  </head>
  <body>
    <h1>Links for my.pypi.package</h1>
    <a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1-py3-none-any.whl#sha256=5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1-py3-none-any.whl</a><br><a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/9s9w01b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2/my.pypi.package-0.0.1.tar.gz#sha256=9s9w011b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1.tar.gz</a><br>
  </body>
</html>
```

出力をファイルに書き込むには:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my.pypi.package" >> simple.html
```

これにより、ダウンロードされたファイルが現在のディレクトリの`simple.html`に書き込まれます。

## パッケージをアップロードする {#upload-a-package}

指定されたプロジェクトのPyPIパッケージをアップロードします。

```plaintext
POST projects/:id/packages/pypi
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | はい | プロジェクトのIDまたは完全なパス。 |
| `requires_python` | 文字列 | いいえ | PyPIの必須バージョン。 |
| `sha256_digest` | 文字列 | いいえ | パッケージファイルのSHA256チェックサム。アップロードには不要ですが、この属性がないと、パッケージインデックスURLに必要なチェックサムがないため、`pip install`は失敗します。 |

```shell
curl --request POST \
     --form 'content=@path/to/my.pypi.package-0.0.1.tar.gz' \
     --form "sha256_digest=$(shasum -a 256 < path/to/my.pypi.package-0.0.1.tar.gz | cut -d' ' -f1)" \
     --form 'name=my.pypi.package' \
     --form 'version=1.3.7' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi"
```
