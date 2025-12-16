---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: PyPI 
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[PyPIパッケージマネージャークライアント](../../user/packages/pypi_repository/_index.md)を操作します。

{{< alert type="warning" >}}

このAPIは、[PyPIパッケージマネージャークライアント](https://pypi.org/)によって使用され、通常は通常は手動での使用を想定していません。

{{< /alert >}}

{{< alert type="note" >}}

これらのエンドポイントは、標準の認証方式に準拠していません。どのヘッダーとトークンタイプがサポートされているかの詳細については、[PyPIパッケージレジストリドキュメント](../../user/packages/pypi_repository/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

{{< /alert >}}

{{< alert type="note" >}}

連邦情報処理規格モードが有効になっている場合は、[Twine 3.4.2](https://twine.readthedocs.io/en/stable/changelog.html?highlight=FIPS#id28)以上を推奨します。{{< /alert >}}

## グループからパッケージファイルをダウンロードする {#download-a-package-file-from-a-group}

PyPIパッケージファイルをダウンロードします。[simple](#group-level-simple-api-entry-point)は通常、このURLを提供します。

```plaintext
GET groups/:id/-/packages/pypi/files/:sha256/:file_identifier
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 文字列 | はい      | グループのまたはフルパス。 |
| `sha256`          | 文字列 | はい      | PyPIパッケージファイルのsha256チェックサム。 |
| `file_identifier` | 文字列 | はい      | PyPIパッケージファイルの名前。 |

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

## グループレベルのsimpleインデックス {#group-level-simple-api-index}

グループ内のパッケージのリストをHTMLファイルとして返します:

```plaintext
GET groups/:id/-/packages/pypi/simple
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列 | はい | グループのまたはフルパス。 |

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

## グループレベルのsimpleエントリポイント {#group-level-simple-api-entry-point}

パッケージ記述子をHTMLファイルとして返します:

```plaintext
GET groups/:id/-/packages/pypi/simple/:package_name
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 文字列 | はい      | グループのまたはフルパス。 |
| `package_name` | 文字列 | はい      | パッケージの名前。 |

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

## プロジェクトからパッケージファイルをダウンロードする {#download-a-package-file-from-a-project}

PyPIパッケージファイルをダウンロードします。[simple](#project-level-simple-api-entry-point)は通常、このURLを提供します。

```plaintext
GET projects/:id/packages/pypi/files/:sha256/:file_identifier
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`              | 文字列 | はい | プロジェクトのまたはフルパス。 |
| `sha256`          | 文字列 | はい | PyPIパッケージファイルsha256チェックサム。 |
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

## プロジェクトレベルのsimpleインデックス {#project-level-simple-api-index}

プロジェクト内のパッケージのリストをHTMLファイルとして返します:

```plaintext
GET projects/:id/packages/pypi/simple
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列 | はい | プロジェクトのまたはフルパス。 |

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

## プロジェクトレベルのsimpleエントリポイント {#project-level-simple-api-entry-point}

パッケージ記述子をHTMLファイルとして返します:

```plaintext
GET projects/:id/packages/pypi/simple/:package_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`           | 文字列 | はい | プロジェクトのまたはフルパス。 |
| `package_name` | 文字列 | はい | パッケージの名前。 |

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

PyPIパッケージをアップロードします:

```plaintext
POST projects/:id/packages/pypi
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | はい | プロジェクトのまたはフルパス。 |
| `requires_python` | 文字列 | いいえ | PyPIに必要なバージョン。 |

```shell
curl --request POST \
     --form 'content=@path/to/my.pypi.package-0.0.1.tar.gz' \
     --form 'name=my.pypi.package' \
     --form 'version=1.3.7' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi"
```
