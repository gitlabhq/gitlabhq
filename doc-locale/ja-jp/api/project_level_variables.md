---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトレベルのCI/CD変数API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、プロジェクトの[CI/CD変数](../ci/variables/_index.md#for-a-project)を操作します。

## プロジェクト変数をリストする {#list-project-variables}

プロジェクトの変数のリストを取得します。結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

```plaintext
GET /projects/:id/variables
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/variables"
```

応答の例:

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

## 単一の変数を取得する {#get-a-single-variable}

単一の変数の詳細を取得します。同じを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
GET /projects/:id/variables/:key
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列         | はい      | 変数の`key`。 |
| `filter`  | ハッシュ           | いいえ       | 利用可能なフィルターは`[environment_scope]`です。[`filter`パラメータ](#the-filter-parameter)の詳細を参照してください。 |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/variables/TEST_VARIABLE_1"
```

応答の例:

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
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`               | 文字列         | はい      | 変数の`key`。255文字以下である必要があります。`A-Z`、`a-z`、`0-9`、および`_`のみが許可されています。 |
| `value`             | 文字列         | はい      | 変数の`value`。 |
| `description`       | 文字列         | いいえ       | 変数の説明。デフォルトは`null`です。GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409641)されました。 |
| `environment_scope` | 文字列         | いいえ       | 変数の`environment_scope`。デフォルトは`*`です。 |
| `masked`            | ブール値        | いいえ       | 変数がマスクされるかどうかを指定します。デフォルトは`false`です。 |
| `masked_and_hidden` | ブール値        | いいえ       | 変数がマスクされ、非表示になるかどうかを指定します。デフォルトは`false`です。 |
| `protected`         | ブール値        | いいえ       | 変数が保護されるかどうかを指定します。デフォルトは`false`です。 |
| `raw`               | ブール値        | いいえ       | 変数がraw文字列として扱われるかどうかを指定します。デフォルトは`false`です。`true`の場合、値の変数は[展開](../ci/variables/_index.md#prevent-cicd-variable-expansion)されません。 |
| `variable_type`     | 文字列         | いいえ       | 変数の型。利用可能な型は、`env_var`（デフォルト）と`file`です。 |

リクエストの例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/variables" --form "key=NEW_VARIABLE" --form "value=new value"
```

応答の例:

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

プロジェクトの変数を更新します。同じを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
PUT /projects/:id/variables/:key
```

| 属性           | 型           | 必須 | 説明 |
|---------------------|----------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`               | 文字列         | はい      | 変数の`key`。 |
| `value`             | 文字列         | はい      | 変数の`value`。 |
| `description`       | 文字列         | いいえ       | 変数の説明。デフォルトは`null`です。GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409641)されました。 |
| `environment_scope` | 文字列         | いいえ       | 変数の`environment_scope`。 |
| `filter`            | ハッシュ           | いいえ       | 利用可能なフィルターは`[environment_scope]`です。[`filter`パラメータ](#the-filter-parameter)の詳細を参照してください。 |
| `masked`            | ブール値        | いいえ       | 変数がマスクされるかどうかを指定します。 |
| `protected`         | ブール値        | いいえ       | 変数が保護されるかどうかを指定します。 |
| `raw`               | ブール値        | いいえ       | 変数がraw文字列として扱われるかどうかを指定します。デフォルトは`false`です。`true`の場合、値の変数は[展開](../ci/variables/_index.md#prevent-cicd-variable-expansion)されません。 |
| `variable_type`     | 文字列         | いいえ       | 変数の型。利用可能な型は、`env_var`（デフォルト）と`file`です。 |

リクエストの例:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/variables/NEW_VARIABLE" --form "value=updated value"
```

応答の例:

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

## 変数を削除する {#delete-a-variable}

プロジェクトの変数を削除します。同じを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
DELETE /projects/:id/variables/:key
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列         | はい      | 変数の`key`。 |
| `filter`  | ハッシュ           | いいえ       | 利用可能なフィルターは`[environment_scope]`です。[`filter`パラメータ](#the-filter-parameter)の詳細を参照してください。 |

リクエストの例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/variables/VARIABLE_1"
```

## `filter`パラメータ {#the-filter-parameter}

複数の変数が同じ`key`を持っている場合、[GET](#get-a-single-variable) 、[PUT](#update-a-variable) 、または[DELETE](#delete-a-variable)リクエストは次のメッセージを返す可能性があります。

```plaintext
There are multiple variables with provided parameters. Please use 'filter[environment_scope]'.
```

このような場合は、`filter[environment_scope]`を使用して、一致する`environment_scope`属性を持つ変数を選択します。

例:

- GET:

  ```shell
  curl --globoff --header "PRIVATE-TOKEN: <your_access_token>" \
       "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1?filter[environment_scope]=production"
  ```

- PUT:

  ```shell
  curl --request PUT --globoff --header "PRIVATE-TOKEN: <your_access_token>" \
       "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1?value=scoped-variable-updated-value&environment_scope=production&filter[environment_scope]=production"
  ```

- DELETE:

  ```shell
  curl --request DELETE --globoff --header "PRIVATE-TOKEN: <your_access_token>" \
       "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1?filter[environment_scope]=production"
  ```
