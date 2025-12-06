---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.3でプロジェクトレベルAPIの[GitLab CI/CDジョブトークン](../ci/jobs/ci_job_token.md)認証のサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/349418)されました。

{{< /history >}}

このAPIを使用して、[GitLab Packages](../administration/packages/_index.md)とやり取りします。

## パッケージをリストする {#list-packages}

{{< history >}}

- `pipelines` GitLab 16.1で[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/341950)になりました。

{{< /history >}}

### プロジェクトの場合 {#for-a-project}

プロジェクトのパッケージのリストを取得します。すべてのパッケージタイプが結果に含まれます。認証なしでアクセスすると、公開プロジェクトのパッケージのみが返されます。デフォルトでは、`default`、`deprecated`、および`error`の状態のパッケージが返されます。他のパッケージを表示するには、`status`パラメータを使用します。

```plaintext
GET /projects/:id/packages
```

| 属性             | 型           | 必須 | 説明 |
|:----------------------|:---------------|:---------|:------------|
| `id`                  | 整数または文字列 | 可      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `order_by`            | 文字列         | 不可       | 順序として使用するフィールド。`created_at`（デフォルト）、`name`、`version`、または`type`のいずれか。 |
| `sort`                | 文字列         | 不可       | 順序の方向。昇順の場合は`asc`（デフォルト）、降順の場合は`desc`。 |
| `package_type`        | 文字列         | 不可       | 返されるパッケージをタイプでフィルタリングします。`composer`、`conan`、`generic`、`golang`、`helm`、`maven`、`npm`、`nuget`、`pypi`、`terraform_module`のいずれかです。 |
| `package_name`        | 文字列         | 不可       | プロジェクトパッケージを名前によるあいまい検索でフィルタリングします。 |
| `package_version`     | 文字列         | 不可       | プロジェクトパッケージをバージョンでフィルタリングします。`include_versionless`と組み合わせて使用すると、バージョンなしのパッケージは返されません。GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/349065)されました。 |
| `include_versionless` | ブール値        | 不可       | trueに設定すると、バージョンなしのパッケージが応答に含まれます。 |
| `status`              | 文字列         | 不可       | 返されるパッケージを状態でフィルタリングします。`default`、`hidden`、`processing`、`error`、`pending_destruction`、`deprecated`のいずれか。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven",
    "created_at": "2019-11-27T03:37:38.711Z",
    "pipeline": {
      "id": 123,
      "status": "pending",
      "ref": "new-pipeline",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "web_url": "https://example.com/foo/bar/pipelines/47",
      "created_at": "2016-08-11T11:28:34.085Z",
      "updated_at": "2016-08-11T11:32:35.169Z",
      "user": {
        "name": "Administrator",
        "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
      }
    },
    "pipelines": []
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm",
    "created_at": "2019-11-27T03:37:38.711Z",
  },
  ],
    "tags": []
  }
]
```

デフォルトでは、`GET`リクエストは20件の結果を返します。これは、APIが[ページネーション](rest/_index.md#pagination)されているためです。

パッケージを状態でフィルタリングできますが、`processing`状態のパッケージを操作すると、不正な形式のデータや破損したパッケージが発生する可能性があります。

### グループの場合 {#for-a-group}

グループレベルでプロジェクトパッケージのリストを取得します。認証なしでアクセスすると、公開プロジェクトのパッケージのみが返されます。デフォルトでは、`default`、`deprecated`、および`error`の状態のパッケージが返されます。他のパッケージを表示するには、`status`パラメータを使用します。

```plaintext
GET /groups/:id/packages
```

| 属性             | 型           | 必須 | 説明 |
|:----------------------|:---------------|:---------|:------------|
| `id`                  | 整数または文字列 | 可      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `exclude_subgroups`   | ブール値        | 不可       | パラメータがtrueとして含まれている場合、サブグループのプロジェクトからのパッケージはリストされません。デフォルトは`false`です。 |
| `order_by`            | 文字列         | 不可       | 順序として使用するフィールド。`created_at`（デフォルト）、`name`、`version`、`type`、`project_path`のいずれか |
| `sort`                | 文字列         | 不可       | 順序の方向。昇順の場合は`asc`（デフォルト）、降順の場合は`desc`。 |
| `package_type`        | 文字列         | 不可       | 返されるパッケージをタイプでフィルタリングします。`composer`、`conan`、`generic`、`golang`、`helm`、`maven`、`npm`、`nuget`、`pypi`、`terraform_module`のいずれかです。 |
| `package_name`        | 文字列         | 不可       | プロジェクトパッケージを名前によるあいまい検索でフィルタリングします。 |
| `package_version`     | 文字列         | 不可       | 返されるパッケージをバージョンでフィルタリングします。`include_versionless`と組み合わせて使用すると、バージョンなしのパッケージは返されません。GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/349065)されました。 |
| `include_versionless` | ブール値        | 不可       | trueに設定すると、バージョンなしのパッケージが応答に含まれます。 |
| `status`              | 文字列         | 不可       | 返されるパッケージを状態でフィルタリングします。`default`、`hidden`、`processing`、`error`、`pending_destruction`、`deprecated`のいずれか。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/packages?exclude_subgroups=false"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven",
    "_links": {
      "web_path": "/namespace1/project1/-/packages/1",
      "delete_api_path": "/namespace1/project1/-/packages/1"
    },
    "created_at": "2019-11-27T03:37:38.711Z",
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm",
    "_links": {
      "web_path": "/namespace1/project1/-/packages/1",
      "delete_api_path": "/namespace1/project1/-/packages/1"
    },
    "created_at": "2019-11-27T03:37:38.711Z",
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  }
]
```

デフォルトでは、`GET`リクエストは20件の結果を返します。これは、APIが[ページネーション](rest/_index.md#pagination)されているためです。

`_links`オブジェクトには、次のプロパティが含まれています:

- `web_path`: GitLabでアクセスして、パッケージの詳細を表示できるパス。
- `delete_api_path`: パッケージを削除するためのAPIパス。リクエストユーザーに削除するための権限がある場合にのみ使用できます。

パッケージを状態でフィルタリングできますが、`processing`状態のパッケージを操作すると、不正な形式のデータや破損したパッケージが発生する可能性があります。

## プロジェクトパッケージを取得する {#get-a-project-package}

{{< history >}}

- `pipelines` GitLab 16.1で[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/341950)になりました。

{{< /history >}}

単一のプロジェクトパッケージを取得します。状態が`default`または`deprecated`のパッケージのみが返されます。

```plaintext
GET /projects/:id/packages/:package_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | 可 | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `package_id`      | 整数 | 可 | パッケージのID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id"
```

レスポンス例:

```json
{
  "id": 1,
  "name": "com/mycompany/my-app",
  "version": "1.0-SNAPSHOT",
  "package_type": "maven",
  "_links": {
    "web_path": "/namespace1/project1/-/packages/1",
    "delete_api_path": "/namespace1/project1/-/packages/1"
  },
  "created_at": "2019-11-27T03:37:38.711Z",
  "last_downloaded_at": "2022-09-07T07:51:50.504Z",
  "pipelines": [
    {
      "id": 123,
      "status": "pending",
      "ref": "new-pipeline",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "web_url": "https://example.com/foo/bar/pipelines/47",
      "created_at": "2016-08-11T11:28:34.085Z",
      "updated_at": "2016-08-11T11:32:35.169Z",
      "user": {
        "name": "Administrator",
        "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
      }
    }
  ],
  "versions": [
    {
      "id":2,
      "version":"2.0-SNAPSHOT",
      "created_at":"2020-04-28T04:42:11.573Z",
      "pipelines": [
        {
          "id": 234,
          "status": "pending",
          "ref": "new-pipeline",
          "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
          "web_url": "https://example.com/foo/bar/pipelines/58",
          "created_at": "2016-08-11T11:28:34.085Z",
          "updated_at": "2016-08-11T11:32:35.169Z",
          "user": {
            "name": "Administrator",
            "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
          }
        }
      ]
    }
  ]
}
```

`_links`オブジェクトには、次のプロパティが含まれています:

- `web_path`: GitLabでアクセスして、パッケージの詳細を表示できるパス。パッケージの状態が`default`または`deprecated`の場合にのみ使用できます。
- `delete_api_path`: パッケージを削除するためのAPIパス。リクエストユーザーに削除するための権限がある場合にのみ使用できます。

## パッケージファイルをリストする {#list-package-files}

単一のパッケージのパッケージファイルのリストを取得します。

```plaintext
GET /projects/:id/packages/:package_id/package_files
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | 可 | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `package_id`      | 整数 | 可 | パッケージのID。 |
| `order_by`            | 文字列         | 不可       | 順序として使用するフィールド。`id`（デフォルト）、`file_name`、`created_at`のいずれか |
| `sort`                | 文字列         | 不可       | 順序の方向。昇順の場合は`asc`（デフォルト）、降順の場合は`desc`。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/package_files"
```

レスポンス例:

```json
[
  {
    "id": 25,
    "package_id": 4,
    "created_at": "2018-11-07T15:25:52.199Z",
    "file_name": "my-app-1.5-20181107.152550-1.jar",
    "size": 2421,
    "file_md5": "58e6a45a629910c6ff99145a688971ac",
    "file_sha1": "ebd193463d3915d7e22219f52740056dfd26cbfe",
    "file_sha256": "a903393463d3915d7e22219f52740056dfd26cbfeff321b",
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  },
  {
    "id": 26,
    "package_id": 4,
    "created_at": "2018-11-07T15:25:56.776Z",
    "file_name": "my-app-1.5-20181107.152550-1.pom",
    "size": 1122,
    "file_md5": "d90f11d851e17c5513586b4a7e98f1b2",
    "file_sha1": "9608d068fe88aff85781811a42f32d97feb440b5",
    "file_sha256": "2987d068fe88aff85781811a42f32d97feb4f092a399"
  },
  {
    "id": 27,
    "package_id": 4,
    "created_at": "2018-11-07T15:26:00.556Z",
    "file_name": "maven-metadata.xml",
    "size": 767,
    "file_md5": "6dfd0cce1203145a927fef5e3a1c650c",
    "file_sha1": "d25932de56052d320a8ac156f745ece73f6a8cd2",
    "file_sha256": "ac849d002e56052d320a8ac156f745ece73f6a8cd2f3e82"
  }
]
```

デフォルトでは、`GET`リクエストは20件の結果を返します。これは、APIが[ページネーション](rest/_index.md#pagination)されているためです。

## パッケージパイプラインをリストする {#list-package-pipelines}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/341950)されました。

{{< /history >}}

単一のパッケージのパイプラインのリストを取得します。結果は、`id`で降順にソートされます。

結果は[ページネーション](rest/_index.md#keyset-based-pagination)され、ページあたり最大20件のレコードが返されます。

```plaintext
GET /projects/:id/packages/:package_id/pipelines
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | 可 | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `package_id`      | 整数 | 可 | パッケージのID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/pipelines"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 9,
    "sha": "2b6127f6bb6f475c4e81afcc2251e3f941e554f9",
    "ref": "mytag",
    "status": "failed",
    "source": "push",
    "created_at": "2023-02-01T12:19:21.895Z",
    "updated_at": "2023-02-01T14:00:05.922Z",
    "web_url": "http://gdk.test:3001/feature-testing/composer-repository/-/pipelines/1",
    "user": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url": "http://gdk.test:3001/root"
    }
  },
  {
    "id": 2,
    "iid": 2,
    "project_id": 9,
    "sha": "e564015ac6cb3d8617647802c875b27d392f72a6",
    "ref": "main",
    "status": "canceled",
    "source": "push",
    "created_at": "2023-02-01T12:23:23.694Z",
    "updated_at": "2023-02-01T12:26:28.635Z",
    "web_url": "http://gdk.test:3001/feature-testing/composer-repository/-/pipelines/2",
    "user": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url": "http://gdk.test:3001/root"
    }
  }
]
```

## プロジェクトパッケージを削除する {#delete-a-project-package}

プロジェクトパッケージを削除します。

```plaintext
DELETE /projects/:id/packages/:package_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | 可 | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `package_id`      | 整数 | 可 | パッケージのID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id"
```

次のステータスコードを返すことができます:

- `204 No Content`: パッケージは正常に削除されました。
- `403 Forbidden`: パッケージは削除から保護されています。
- `404 Not Found`: パッケージが見つかりませんでした。

[リクエスト転送](../user/packages/package_registry/supported_functionality.md#forwarding-requests)が有効になっている場合、パッケージを削除すると、[依存関係の混乱リスク](../user/packages/package_registry/supported_functionality.md#deleting-packages)が生じる可能性があります。

パッケージが[保護ルール](../user/packages/package_registry/package_protection_rules.md#protect-a-package)によって保護されている場合、パッケージの削除は禁止されています。

## パッケージファイルを削除する {#delete-a-package-file}

{{< alert type="warning" >}}

パッケージファイルを削除すると、パッケージが破損し、パッケージマネージャーのクライアントから使用またはプルできなくなる可能性があります。パッケージファイルを削除する場合は、何をしているかを理解していることを確認してください。

{{< /alert >}}

パッケージファイルの削除:

```plaintext
DELETE /projects/:id/packages/:package_id/package_files/:package_file_id
```

| 属性         | 型           | 必須 | 説明 |
| ----------------- | -------------- | -------- | ----------- |
| `id`              | 整数または文字列 | 可 | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `package_id`      | 整数        | 可 | パッケージのID。 |
| `package_file_id` | 整数        | 可 | パッケージファイルのID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/package_files/:package_file_id"
```

次のステータスコードを返すことができます:

- `204 No Content`: パッケージは正常に削除されました。
- `403 Forbidden`: ユーザーにファイルを削除する権限がないか、パッケージが削除から保護されています。
- `404 Not Found`: パッケージまたはパッケージファイルが見つかりませんでした。

パッケージファイルが属するパッケージが[保護ルール](../user/packages/package_registry/package_protection_rules.md#protect-a-package)によって保護されている場合、パッケージファイルの削除は禁止されています。
