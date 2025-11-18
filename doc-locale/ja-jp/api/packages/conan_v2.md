---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Conan v2 API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.11で`conan_package_revisions_support`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519741)されました。デフォルトでは無効になっています。
- GitLab 18.3の[GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14896)で有効になりました。機能フラグ`conan_package_revisions_support`は削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

{{< alert type="note" >}}

Conan v1の操作については、[Conan v1 API](conan_v1.md)を参照してください。

{{< /alert >}}

このAPIを使用して、[Conan v2パッケージマネージャー](../../user/packages/conan_2_repository/_index.md)とやり取りします。

通常、これらのエンドポイントは[Conan 2パッケージマネージャークライアント](https://docs.conan.io/2/index.html)によって使用され、手動での使用は意図されていません。

{{< alert type="note" >}}

- これらのエンドポイントは、標準のAPI認証方法に準拠していません。認証情報の受け渡し方法の詳細については、各ルートを参照してください。記載されていない認証方法は、将来削除される可能性があります。

- Conanレジストリは連邦情報処理規格に準拠しておらず、FIPSモードが有効になっている場合は無効になります。これらのエンドポイントはすべて`404 Not Found`を返します。{{< /alert >}}

## 認証トークンを作成します {#create-an-authentication-token}

他のリクエストでBearerヘッダーとして使用するJSON Webトークン（JWT）を作成します。

```shell
"Authorization: Bearer <authenticate_token>
```

Conan 2パッケージマネージャークライアントは、このトークンを自動的に使用します。

```plaintext
GET /projects/:id/packages/conan/v2/users/authenticate
```

| 属性 | 型   | 必須      | 説明                                                                  |
| --------- | ------ | ------------- | ---------------------------------------------------------------------------- |
| `id`      | 文字列 | 条件付き | プロジェクトIDまたは完全なプロジェクトパス。プロジェクトエンドポイントでのみ必須。 |

base64でエンコードされたBasic基本認証トークンを生成します:

```shell
echo -n "<username>:<your_access_token>"|base64
```

base64でエンコードされたBasic基本認証トークンを使用して、JWTトークンを取得します:

```shell
curl --request GET \
     --header 'Authorization: Basic <base64_encoded_token>' \
     --url "https://gitlab.example.com/api/v4/packages/conan/v2/users/authenticate"
```

レスポンス例:

```shell
eyJhbGciOiJIUzI1NiIiheR5cCI6IkpXVCJ9.eyJhY2Nlc3NfdG9rZW4iOjMyMTQyMzAsqaVzZXJfaWQiOjQwNTkyNTQsImp0aSI6IjdlNzBiZTNjLWFlNWQtNDEyOC1hMmIyLWZiOThhZWM0MWM2OSIsImlhd3r1MTYxNjYyMzQzNSwibmJmIjoxNjE2NjIzNDMwLCJleHAiOjE2MTY2MjcwMzV9.QF0Q3ZIB2GW5zNKyMSIe0HIFOITjEsZEioR-27Rtu7E
```

## 認証情報を確認する {#verify-authentication-credentials}

Basic基本認証認証情報、またはConan v1 [`/authenticate`](conan_v1.md#create-an-authentication-token)エンドポイントから生成されたConan JWTの有効性を検証します。

```plaintext
GET /projects/:id/packages/conan/v2/users/check_credentials
```

| 属性 | 型   | 必須 | 説明                          |
| --------- | ------ | -------- | ------------------------------------ |
| `id`      | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。 |

```shell
curl --request GET \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/packages/conan/v2/users/check_credentials"
```

レスポンス例:

```plaintext
ok
```

## Conanパッケージを検索する {#search-for-a-conan-package}

指定された名前のConanパッケージをプロジェクトで検索します。

```plaintext
GET /projects/:id/packages/conan/v2/conans/search?q=:query
```

| 属性 | 型   | 必須 | 説明                                  |
| --------- | ------ | -------- | -------------------------------------------- |
| `id`      | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。         |
| `query`   | 文字列 | はい      | 検索クエリ。`*`をワイルドカードとして使用できます。 |

```shell
curl --request GET \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/search?q=Hello*"
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

## 最新のレシピリビジョンを取得します {#get-latest-recipe-revision}

最新のパッケージレシピのリビジョンハッシュと作成日を取得します。

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/latest
```

| 属性          | 型   | 必須 | 説明                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`     | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`  | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username` | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`  | 文字列 | はい      | パッケージのチャンネル。                                                                       |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/latest"
```

レスポンス例:

```json
{
  "revision" : "75151329520e7685dcf5da49ded2fec0",
  "time" : "2024-12-17T09:16:40.334+0000"
}
```

## すべてのレシピリビジョンをリストします {#list-all-recipe-revisions}

パッケージレシピのすべてのリビジョンをリストします。

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions
```

| 属性          | 型   | 必須 | 説明                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`     | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`  | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username` | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`  | 文字列 | はい      | パッケージのチャンネル。                                                                       |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions"
```

レスポンス例:

```json
{
  "reference": "my-package/1.0@my-group+my-project/stable",
  "revisions": [
    {
      "revision": "75151329520e7685dcf5da49ded2fec0",
      "time": "2024-12-17T09:16:40.334+0000"
    },
    {
      "revision": "df28fd816be3a119de5ce4d374436b25",
      "time": "2024-12-17T09:15:30.123+0000"
    }
  ]
}
```

## レシピリビジョンを削除します {#delete-a-recipe-revision}

レジストリからレシピリビジョンを削除します。パッケージにレシピリビジョンが1つしかない場合、パッケージも削除されます。

```plaintext
DELETE /projects/:id/packages/conan/conans/:package_name/package_version/:package_username/:package_channel/revisions/:recipe_revision
```

| 属性          | 型   | 必須 | 説明                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`     | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`  | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username` | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`  | 文字列 | はい      | パッケージのチャンネル。                                                                       |
| `recipe_revision`  | 文字列 | はい      | 削除するレシピリビジョンのリビジョンハッシュ。                                                |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/2be19f5a69b2cb02ab576755252319b9"
```

## すべてのレシピファイルをリストします {#list-all-recipe-files}

パッケージレジストリからすべてのレシピファイルをリストします。

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files
```

| 属性          | 型   | 必須 | 説明                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`     | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`  | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username` | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`  | 文字列 | はい      | パッケージのチャンネル。                                                                       |
| `recipe_revision`  | 文字列 | はい      | レシピのリビジョン。`0`の値は受け入れません。                                     |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files"
```

レスポンス例:

```json
{
  "files": {
    "conan_sources.tgz": {},
    "conanfile.py": {},
    "conanmanifest.txt": {}
  }
}
```

## レシピファイルを取得する {#get-a-recipe-file}

パッケージレジストリからレシピファイルを取得します。

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files/:file_name
```

| 属性          | 型   | 必須 | 説明                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`     | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`  | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username` | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`  | 文字列 | はい      | パッケージのチャンネル。                                                                       |
| `recipe_revision`  | 文字列 | はい      | レシピのリビジョン。`0`の値は受け入れません。                                     |
| `file_name`        | 文字列 | はい      | リクエストされたファイルの名前とファイル拡張子。                                          |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files/conanfile.py"
```

次の方法で、出力をファイルに書き込むこともできます:

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files/conanfile.py" \
     >> conanfile.py
```

この例では、現在のディレクトリの`conanfile.py`に書き込みます。

## レシピファイルをアップロードする {#upload-a-recipe-file}

レシピファイルをパッケージレジストリにアップロードします。

```plaintext
PUT /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files/:file_name
```

| 属性          | 型   | 必須 | 説明                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`     | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`  | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username` | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`  | 文字列 | はい      | パッケージのチャンネル。                                                                       |
| `recipe_revision`  | 文字列 | はい      | レシピのリビジョン。`0`の値は受け入れません。                                     |
| `file_name`        | 文字列 | はい      | リクエストされたファイルの名前とファイル拡張子。                                          |

```shell
curl --request PUT \
     --header "Authorization: Bearer <authenticate_token>" \
     --upload-file path/to/conanfile.py \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/upload-v2-package/1.0.0/user/stable/revisions/123456789012345678901234567890ab/files/conanfile.py"
```

レスポンス例:

```json
{
  "id": 38,
  "package_id": 28,
  "created_at": "2025-04-07T12:35:40.841Z",
  "updated_at": "2025-04-07T12:35:40.841Z",
  "size": 24,
  "file_store": 1,
  "file_md5": "131f806af123b497209a516f46d12ffd",
  "file_sha1": "01b992b2b1976a3f4c1e5294d0cab549cd438502",
  "file_name": "conanfile.py",
  "file": {
    "url": "/94/00/9400f1b21cb527d7fa3d3eabba93557a18ebe7a2ca4e471cfe5e4c5b4ca7f767/packages/28/files/38/conanfile.py"
  },
  "file_sha256": null,
  "verification_retry_at": null,
  "verified_at": null,
  "verification_failure": null,
  "verification_retry_count": null,
  "verification_checksum": null,
  "verification_state": 0,
  "verification_started_at": null,
  "status": "default",
  "file_final_path": null,
  "project_id": 9,
  "new_file_path": null
}
```

## すべてのパッケージリビジョンをリストします {#list-all-package-revisions}

特定のレシピリビジョンとパッケージ参照のすべてのパッケージリビジョンをリストします。

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions
```

| 属性                 | 型   | 必須 | 説明                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`            | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`         | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username`        | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`         | 文字列 | はい      | パッケージのチャンネル。                                                                       |
| `recipe_revision`         | 文字列 | はい      | レシピのリビジョン。`0`の値は受け入れません。                                     |
| `conan_package_reference` | 文字列 | はい      | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。                              |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions"
```

レスポンス例:

```json
{
  "reference": "my-package/1.0@my-group+my-project/stable#75151329520e7685dcf5da49ded2fec0:103f6067a947f366ef91fc1b7da351c588d1827f",
  "revisions": [
    {
      "revision": "2bfb52659449d84ed11356c353bfbe86",
      "time": "2024-12-17T09:16:40.334+0000"
    },
    {
      "revision": "3bdd2d8c8e76c876ebd1ac0469a4e72c",
      "time": "2024-12-17T09:15:30.123+0000"
    }
  ]
}
```

## 最新のパッケージリビジョンを取得します {#get-latest-package-revision}

特定のレシピリビジョンおよびパッケージ参照の最新のパッケージリビジョンのリビジョンハッシュと作成日を取得します。

```plaintext
GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/latest
```

| 属性                 | 型   | 必須 | 説明                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`            | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`         | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username`        | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`         | 文字列 | はい      | パッケージのチャンネル。                                                                       |
| `recipe_revision`         | 文字列 | はい      | レシピのリビジョン。`0`の値は受け入れません。                                     |
| `conan_package_reference` | 文字列 | はい      | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。                              |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/latest"
```

レスポンス例:

```json
{
  "revision" : "3bdd2d8c8e76c876ebd1ac0469a4e72c",
  "time" : "2024-12-17T09:16:40.334+0000"
}
```

## パッケージリビジョンを削除します {#delete-a-package-revision}

レジストリからパッケージリビジョンを削除します。パッケージ参照にパッケージリビジョンが1つしかない場合、パッケージ参照も削除されます。

```plaintext
DELETE /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision
```

| 属性                 | 型   | 必須 | 説明                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`            | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`         | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username`        | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`         | 文字列 | はい      | パッケージのチャンネル。                                                                       |
| `recipe_revision`         | 文字列 | はい      | レシピのリビジョン。`0`の値は受け入れません。                                             |
| `conan_package_reference` | 文字列 | はい      | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。                              |
| `package_revision`        | 文字列 | はい      | パッケージのリビジョン。`0`の値は受け入れません。                                    |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c"
```

## パッケージファイルを取得する {#get-a-package-file}

パッケージレジストリからパッケージファイルを取得します。

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/files/:file_name
```

| 属性                 | 型   | 必須 | 説明                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`            | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`         | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username`        | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`         | 文字列 | はい      | パッケージのチャンネル。                                                                       |
| `recipe_revision`         | 文字列 | はい      | レシピのリビジョン。`0`の値は受け入れません。                                     |
| `conan_package_reference` | 文字列 | はい      | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。                              |
| `package_revision`        | 文字列 | はい      | パッケージのリビジョン。`0`の値は受け入れません。                                    |
| `file_name`               | 文字列 | はい      | リクエストされたファイルの名前とファイル拡張子。                                          |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt"
```

次の方法で、出力をファイルに書き込むこともできます:

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt" \
     >> conaninfo.txt
```

この例では、現在のディレクトリの`conaninfo.txt`に書き込みます。

## パッケージファイルをアップロードする {#upload-a-package-file}

パッケージファイルをパッケージレジストリにアップロードします。

```plaintext
PUT /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/files/:file_name
```

| 属性                 | 型   | 必須 | 説明                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | 文字列 | はい      | プロジェクトIDまたは完全なプロジェクトパス。                                                        |
| `package_name`            | 文字列 | はい      | パッケージ名。                                                                          |
| `package_version`         | 文字列 | はい      | パッケージのバージョン。                                                                       |
| `package_username`        | 文字列 | はい      | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`         | 文字列 | はい      | パッケージのチャンネル。                                                                       |
| `recipe_revision`         | 文字列 | はい      | レシピのリビジョン。`0`の値は受け入れません。                                     |
| `conan_package_reference` | 文字列 | はい      | Conanパッケージの参照ハッシュ。Conanはこの値を生成します。                              |
| `package_revision`        | 文字列 | はい      | パッケージのリビジョン。`0`の値は受け入れません。                                    |
| `file_name`               | 文字列 | はい      | リクエストされたファイルの名前とファイル拡張子。                                          |

リクエストの本文で、ファイルの内容を提供します:

```shell
curl --request PUT \
     --header "Authorization: Bearer <authenticate_token>" \
     --upload-file path/to/conaninfo.txt \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt"
```

レスポンス例:

```json
{
  "id": 202,
  "package_id": 48,
  "created_at": "2025-03-19T10:06:53.626Z",
  "updated_at": "2025-03-19T10:06:53.626Z",
  "size": 208,
  "file_store": 1,
  "file_md5": "bf996313bbdd75944b58f8c673661d99",
  "file_sha1": "02c8adf14c94135fb95d472f96525063efe09ee8",
  "file_name": "conaninfo.txt",
  "file": {
      "url": "/94/00/9400f1b21cb527d7fa3d3eabba93557a18ebe7a2ca4e471cfe5e4c5b4ca7f767/packages/48/files/202/conaninfo.txt"
  },
  "file_sha256": null,
  "verification_retry_at": null,
  "verified_at": null,
  "verification_failure": null,
  "verification_retry_count": null,
  "verification_checksum": null,
  "verification_state": 0,
  "verification_started_at": null,
  "status": "default",
  "file_final_path": null,
  "project_id": 9,
  "new_file_path": null
}
```

## パッケージ参照メタデータを取得する {#get-package-references-metadata}

パッケージのすべてのパッケージ参照のメタデータを取得します。

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/search
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | はい | プロジェクトIDまたは完全なプロジェクトパス。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/search"
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

## レシピリビジョンでパッケージ参照メタデータを取得します {#get-package-references-metadata-by-recipe-revision}

特定のレシピリビジョンに関連付けられているすべてのパッケージ参照のメタデータを取得します。

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/search
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                | 文字列 | はい | プロジェクトIDまたは完全なプロジェクトパス。 |
| `package_name`      | 文字列 | はい | パッケージ名。 |
| `package_version`   | 文字列 | はい | パッケージのバージョン。 |
| `package_username`  | 文字列 | はい | パッケージのConanユーザー名。この属性は、プロジェクトの`+`区切りのフルパスです。 |
| `package_channel`   | 文字列 | はい | パッケージのチャンネル。 |
| `recipe_revision`   | 文字列 | はい | レシピのリビジョン。`0`の値は受け入れません。 |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/search"
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
