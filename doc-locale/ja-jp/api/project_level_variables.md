---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトレベルのCI/CD変数API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.9で[`filter`](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)が導入されました。

{{< /history >}}

このAPIを使用して、プロジェクトの[CI/CD変数](../ci/variables/_index.md#for-a-project)を操作します。

## プロジェクト変数をリストする {#list-project-variables}

プロジェクトのすべての変数をリスト表示します。結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

```plaintext
GET /projects/:id/variables
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables"
```

レスポンス例: 

```json
[
    {
        "variable_type": "env_var",
        "key": "TEST_VARIABLE_1",
        "value": "TEST_1",
        "protected": false,
        "masked": true,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    },
    {
        "variable_type": "env_var",
        "key": "TEST_VARIABLE_2",
        "value": "TEST_2",
        "protected": false,
        "masked": false,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    }
]
```

## 単一の変数を取得する {#retrieve-a-single-variable}

単一の変数の詳細を取得します。同じキーを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
GET /projects/:id/variables/:key
```

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | 変数のキー。 |
| `filter`  | ハッシュ              | いいえ       | 複数の変数が同じキーを共有している場合に、結果をフィルタリングします。使用可能な値: `[environment_scope]`。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/TEST_VARIABLE_1"
```

レスポンス例: 

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": true,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

`filter`を含むリクエストの例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```

## 変数を作成する {#create-a-variable}

{{< history >}}

- `masked_and_hidden`属性と`hidden`属性は、GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/29674)されました。

{{< /history >}}

新しい変数を作成します。同じ`key`を持つ変数がすでに存在する場合、新しい変数は異なる`environment_scope`を持つ必要があります。そうでない場合、GitLabは`VARIABLE_NAME has already been taken`のようなメッセージを返します。

```plaintext
POST /projects/:id/variables
```

| 属性           | 型           | 必須 | 説明 |
|---------------------|----------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key`               | 文字列         | はい      | 変数の`key`。255文字以下である必要があります。`A-Z`、`a-z`、`0-9`、および`_`のみが許可されています。 |
| `value`             | 文字列         | はい      | 変数の`value`。 |
| `description`       | 文字列         | いいえ       | 変数の説明。デフォルトは`null`です。GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409641)されました。 |
| `environment_scope` | 文字列         | いいえ       | 変数の`environment_scope`。デフォルトは`*`です。 |
| `masked`            | ブール値        | いいえ       | 変数がマスクされるかどうかを指定します。デフォルトは`false`です。 |
| `masked_and_hidden` | ブール値        | いいえ       | 変数がマスクされ、非表示になるかどうかを指定します。デフォルトは`false`です。 |
| `protected`         | ブール値        | いいえ       | 変数が保護されるかどうかを指定します。デフォルトは`false`です。 |
| `raw`               | ブール値        | いいえ       | 変数がraw文字列として扱われるかどうかを指定します。デフォルトは`true`です。`false`の場合、値内の変数は[展開されます](../ci/variables/_index.md#allow-cicd-variable-expansion)。 |
| `variable_type`     | 文字列         | いいえ       | 変数の型。利用可能な型は、`env_var`（デフォルト）と`file`です。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

レスポンス例: 

```json
{
    "variable_type": "env_var",
    "key": "NEW_VARIABLE",
    "value": "new value",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## 変数を更新する {#update-a-variable}

プロジェクト変数を更新します。同じキーを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
PUT /projects/:id/variables/:key
```

| 属性           | 型              | 必須 | 説明 |
| ------------------- | ----------------- | -------- | ----------- |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`               | 文字列            | はい      | 変数のキー。 |
| `value`             | 文字列            | はい      | 変数の値。 |
| `description`       | 文字列            | いいえ       | 変数の説明。GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409641)されました。デフォルトは`null`です。 |
| `environment_scope` | 文字列            | いいえ       | 変数の環境スコープ。 |
| `filter`            | ハッシュ              | いいえ       | 複数の変数が同じキーを共有している場合に、結果をフィルタリングします。使用可能な値: `[environment_scope]`。 |
| `masked`            | ブール値           | いいえ       | `true`の場合、変数はマスクされます。 |
| `protected`         | ブール値           | いいえ       | `true`の場合、変数は保護されます。 |
| `raw`               | ブール値           | いいえ       | `true`の場合、変数はraw文字列として扱われます。`false`の場合、変数の値は[展開されます](../ci/variables/_index.md#allow-cicd-variable-expansion)。デフォルトは`true`です。 |
| `variable_type`     | 文字列            | いいえ       | 変数のタイプ。利用可能なタイプは: `env_var` (デフォルト) と`file`。 |

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

レスポンス例: 

```json
{
    "variable_type": "env_var",
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "protected": true,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": "null"
}
```

`filter`を含むリクエストの例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1" \
  --form "value=updated value" \
  --form "environment_scope=production" \
  --form "filter[environment_scope]=production"
```

## 変数を削除する {#delete-a-variable}

プロジェクト変数を削除します。同じキーを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
DELETE /projects/:id/variables/:key
```

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | 変数のキー。 |
| `filter`  | ハッシュ              | いいえ       | 複数の変数が同じキーを共有している場合に、結果をフィルタリングします。使用可能な値: `[environment_scope]`。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>"
  --url "https://gitlab.example.com/api/v4/projects/1/variables/VARIABLE_1"
```

`filter`を含むリクエストの例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>"
  --url "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```
