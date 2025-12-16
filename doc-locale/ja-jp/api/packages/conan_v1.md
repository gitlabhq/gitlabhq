---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Conan v1 API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

Conan v2の操作については、[Conan v2 API](conan_v2.md)を参照してください。

{{< /alert >}}

このAPIを使用して、[Conan v1パッケージマネージャー](../../user/packages/conan_1_repository/_index.md)を操作します。これらのエンドポイントは、プロジェクトとインスタンスの両方で機能します。

通常、これらのエンドポイントは[Conan 1パッケージマネージャークライアント](https://docs.conan.io/en/latest/)で使用され、手動での使用は想定されていません。

{{< alert type="note" >}}

- これらのエンドポイントは、標準のAPI認証方法に準拠していません。認証情報の受け渡し方法の詳細については、各ルートを参照してください。記載されていない認証方法は、将来削除される可能性があります。

- Conanレジストリは連邦情報処理規格に準拠しておらず、FIPSモードが有効になっている場合は無効になります。これらのエンドポイントはすべて`404 Not Found`を返します。

{{< /alert >}}

## 認証トークンを作成します {#create-an-authentication-token}

Conanパッケージマネージャークライアントへの他のリクエストでBearerヘッダーとして使用するJSON Webトークン（JWT）を作成します。

```shell
"Authorization: Bearer <authenticate_token>"
```

```plaintext
GET /packages/conan/v1/users/authenticate
GET /projects/:id/packages/conan/v1/users/authenticate
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |

```shell
curl --user <username>:<your_access_token> \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/users/authenticate"
```

レスポンス例:

```shell
eyJhbGciOiJIUzI1NiIiheR5cCI6IkpXVCJ9.eyJhY2Nlc3NfdG9rZW4iOjMyMTQyMzAsqaVzZXJfaWQiOjQwNTkyNTQsImp0aSI6IjdlNzBiZTNjLWFlNWQtNDEyOC1hMmIyLWZiOThhZWM0MWM2OSIsImlhd3r1MTYxNjYyMzQzNSwibmJmIjoxNjE2NjIzNDMwLCJleHAiOjE2MTY2MjcwMzV9.QF0Q3ZIB2GW5zNKyMSIe0HIFOITjEsZEioR-27Rtu7E
```

## Conanリポジトリの可用性を確認する {#verify-availability-of-a-conan-repository}

GitLab Conanリポジトリの可用性を確認します。

```plaintext
GET /packages/conan/v1/ping
GET /projects/:id/packages/conan/v1/ping
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |

```shell
curl --url "https://gitlab.example.com/api/v4/packages/conan/v1/ping"
```

レスポンス例:

```json
""
```

## Conanパッケージを検索する {#search-for-a-conan-package}

インスタンスで、指定された名前のConanパッケージを検索します。

```plaintext
GET /packages/conan/v1/conans/search
GET /projects/:id/packages/conan/v1/conans/search
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `q`       | 文字列 | はい | 検索クエリ。`*`をワイルドカードとして使用できます。 |

```shell
curl --user <username>:<your_access_token> \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/search?q=Hello*"
```

レスポンス例:

```json
{
  "results": [
    "Hello/0.1@foo+conan_test_prod/beta",
    "Hello/0.1@foo+conan_test_prod/stable",
    "Hello/0.2@foo+conan_test_prod/beta",
    "Hello/0.3@foo+conan_test_prod/beta",
    "Hello/0.1@foo+conan-reference-test/stable",
    "HelloWorld/0.1@baz+conan-reference-test/beta"
    "hello-world/0.4@buz+conan-test/alpha"
  ]
}
```

## 認証情報を確認する {#verify-authentication-credentials}

基本認証認証情報、または[`/authenticate`](#create-an-authentication-token)エンドポイントから生成されたConan JWTの有効性を検証します。

```plaintext
GET /packages/conan/v1/users/check_credentials
GET /projects/:id/packages/conan/v1/users/check_credentials
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/users/check_credentials"
```

レスポンス例:

```shell
ok
```

## レシピスナップショットを取得する {#get-a-recipe-snapshot}

指定されたConanレシピのファイルのスナップショットを取得します。スナップショットは、関連するMD5ハッシュを持つファイル名のリストです。

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
GET /projects/:id/packages/conan/v1/conans/:package_version/:package_username/:package_channel
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable"
```

レスポンス例:

```json
{
  "conan_sources.tgz": "eadf19b33f4c3c7e113faabf26e76277",
  "conanfile.py": "25e55b96a28f81a14ba8e8a8c99eeace",
  "conanmanifest.txt": "5b6fd77a2ba14303ce4cdb08c87e82ab"
}
```

## パッケージスナップショットを取得する {#get-a-package-snapshot}

指定されたConanパッケージおよび参照のファイルのスナップショットを取得します。スナップショットは、関連するMD5ハッシュを持つファイル名のリストです。

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |
| `conan_package_reference` | 文字列 | はい | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f"
```

レスポンス例:

```json
{
  "conan_package.tgz": "749b29bdf72587081ca03ec033ee59dc",
  "conaninfo.txt": "32859d737fe84e6a7ccfa4d64dc0d1f2",
  "conanmanifest.txt": "a86b398e813bd9aa111485a9054a2301"
}
```

## レシピマニフェストを取得する {#get-a-recipe-manifest}

指定されたレシピのファイルと関連するダウンロードURLのリストを含むマニフェストを取得します。

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/digest
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/digest
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/digest"
```

レスポンス例:

```json
{
  "conan_sources.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conan_sources.tgz",
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

## パッケージマニフェストを取得する {#get-a-package-manifest}

指定されたパッケージのファイルと関連するダウンロードURLのリストを含むマニフェストを取得します。

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/digest
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/digest
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |
| `conan_package_reference` | 文字列 | はい | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/digest"
```

レスポンス例:

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt"
}
```

## すべてのレシピのダウンロードURLをリストする {#list-all-recipe-download-urls}

指定されたレシピのすべてのファイルと関連するダウンロードURLをリストします。[レシピマニフェスト](#get-a-recipe-manifest)エンドポイントと同じペイロードを返します。

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/download_urls
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/download_urls
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/digest"
```

レスポンス例:

```json
{
  "conan_sources.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conan_sources.tgz",
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

## すべてのパッケージのダウンロードURLをリストする {#list-all-package-download-urls}

指定されたパッケージのすべてのファイルと関連するダウンロードURLをリストします。[パッケージマニフェスト](#get-a-package-manifest)エンドポイントと同じペイロードを返します。

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/download_urls
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/download_urls
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |
| `conan_package_reference` | 文字列 | はい | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/download_urls"
```

レスポンス例:

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt"
}
```

## すべてのレシピのアップロードURLをリストする {#list-all-recipe-upload-urls}

指定されたレシピファイルのコレクションのアップロードURLをリストします。リクエストには、個々のファイルの名前とサイズを含むJSONオブジェクトを含める必要があります。

```plaintext
POST /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/upload_urls
POST /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/upload_urls
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |

リクエストのJSONペイロードの例:

ペイロードには、ファイルの名前とサイズの両方を含める必要があります。

```json
{
  "conanfile.py": 410,
  "conanmanifest.txt": 130
}
```

```shell
curl --request POST \
     --header "Authorization: Bearer <authenticate_token>" \
     --header "Content-Type: application/json" \
     --data '{"conanfile.py":410,"conanmanifest.txt":130}' \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/upload_urls"
```

レスポンス例:

```json
{
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

## すべてのパッケージのアップロードURLをリストする {#list-all-package-upload-urls}

指定されたパッケージファイルのコレクションのアップロードURLをリストします。リクエストには、個々のファイルの名前とサイズを含むJSONオブジェクトを含める必要があります。

```plaintext
POST /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/upload_urls
POST /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/upload_urls
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |
| `conan_package_reference` | 文字列 | はい | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。 |

リクエストのJSONペイロードの例:

ペイロードには、ファイルの名前とサイズの両方を含める必要があります。

```json
{
  "conan_package.tgz": 5412,
  "conanmanifest.txt": 130,
  "conaninfo.txt": 210
}
```

```shell
curl --request POST \
     --header "Authorization: Bearer <authenticate_token>" \
     --header "Content-Type: application/json" \
     --data '{"conan_package.tgz":5412,"conanmanifest.txt":130,"conaninfo.txt":210}' \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/upload_urls"
```

レスポンス例:

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
}
```

## レシピファイルを取得する {#get-a-recipe-file}

パッケージレジストリからレシピファイルを取得します。[レシピのダウンロードURL](#list-all-recipe-download-urls)エンドポイントから返されたダウンロードURLを使用する必要があります。

```plaintext
GET /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
GET /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |
| `recipe_revision`   | 文字列 | はい | レシピのリビジョン。GitLabはまだConanリビジョンをサポートしていないため、デフォルト値`0`が常に使用されます。 |
| `file_name`         | 文字列 | はい | リクエストされたファイルの名前とファイル拡張子。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py"
```

次の方法で、出力をファイルに書き込むこともできます:

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py" \
     >> conanfile.py
```

この例では、現在のディレクトリの`conanfile.py`に書き込みます。

## レシピファイルをアップロードする {#upload-a-recipe-file}

パッケージレジストリに指定されたレシピファイルをアップロードします。[レシピのアップロードURL](#list-all-recipe-upload-urls)エンドポイントから返されたアップロードURLを使用する必要があります。

```plaintext
PUT /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
PUT /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |
| `recipe_revision`   | 文字列 | はい | レシピのリビジョン。GitLabはまだConanリビジョンをサポートしていないため、デフォルト値`0`が常に使用されます。 |
| `file_name`         | 文字列 | はい | リクエストされたファイルの名前とファイル拡張子。 |

リクエストの本文で、ファイルの内容を提供します:

```shell
curl --request PUT \
     --user <username>:<personal_access_token> \
     --upload-file path/to/conanfile.py \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py"
```

## パッケージファイルを取得する {#get-a-package-file}

パッケージレジストリからパッケージファイルを取得します。[パッケージのダウンロードURL](#list-all-package-download-urls)エンドポイントから返されたダウンロードURLを使用する必要があります。

```plaintext
GET /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
GET /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |
| `recipe_revision`   | 文字列 | はい | レシピのリビジョン。GitLabはまだConanリビジョンをサポートしていないため、デフォルト値`0`が常に使用されます。 |
| `conan_package_reference` | 文字列 | はい | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。 |
| `package_revision`  | 文字列 | はい | パッケージのリビジョン。GitLabはまだConanリビジョンをサポートしていないため、デフォルト値`0`が常に使用されます。 |
| `file_name`         | 文字列 | はい | リクエストされたファイルの名前とファイル拡張子。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
```

次の方法で、出力をファイルに書き込むこともできます:

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt" \
     >> conaninfo.txt
```

この例では、現在のディレクトリの`conaninfo.txt`に書き込みます。

## パッケージファイルをアップロードする {#upload-a-package-file}

パッケージレジストリに指定されたパッケージファイルをアップロードします。[パッケージのアップロードURL](#list-all-package-upload-urls)エンドポイントから返されたアップロードURLを使用する必要があります。

```plaintext
PUT /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
PUT /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |
| `recipe_revision`   | 文字列 | はい | レシピのリビジョン。GitLabはまだConanリビジョンをサポートしていないため、デフォルト値`0`が常に使用されます。 |
| `conan_package_reference` | 文字列 | はい | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。 |
| `package_revision`  | 文字列 | はい | パッケージのリビジョン。GitLabはまだConanリビジョンをサポートしていないため、デフォルト値`0`が常に使用されます。 |
| `file_name`         | 文字列 | はい | リクエストされたファイルの名前とファイル拡張子。 |

リクエストの本文で、ファイルの内容を提供します:

```shell
curl --request PUT \
     --user <username>:<your_access_token> \
     --upload-file path/to/conaninfo.txt \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
```

## レシピとパッケージを削除する {#delete-a-recipe-and-package}

指定されたConanレシピと、関連するパッケージファイルをパッケージレジストリから削除します。

```plaintext
DELETE /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
DELETE /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable"
```

レスポンス例:

```json
{
  "id": 1,
  "project_id": 123,
  "created_at": "2020-08-19T13:17:28.655Z",
  "updated_at": "2020-08-19T13:17:28.655Z",
  "name": "my-package",
  "version": "1.0",
  "package_type": "conan",
  "creator_id": null,
  "status": "default"
}
```

## パッケージ参照メタデータを取得する {#get-package-references-metadata}

パッケージのすべてのパッケージ参照のメタデータを取得します。

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/search
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/search
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/search"
```

レスポンス例:

```json
{
  "103f6067a947f366ef91fc1b7da351c588d1827f": {
    "settings": {
      "arch": "x86_64",
      "build_type": "Release",
      "compiler": "gcc",
      "compiler.libcxx": "libstdc++",
      "compiler.version": "9",
      "os": "Linux"
    },
    "options": {
      "shared": "False"
    },
    "requires": {
      "zlib/1.2.11": null
    },
    "recipe_hash": "75151329520e7685dcf5da49ded2fec0"
  }
}
```

出力には、各パッケージ参照について、次のメタデータが含まれます:

- `settings`: パッケージに使用されるビルド設定。
- `options`: パッケージオプション。
- `requires`: パッケージに必要な依存関係。
- `recipe_hash`: レシピのハッシュ。
