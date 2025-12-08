---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループレベル変数API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、グループの[CI/CD変数](../ci/variables/_index.md#for-a-group)を操作します。

## グループ変数の一覧表示 {#list-group-variables}

グループの変数のリストを取得します。結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

```plaintext
GET /groups/:id/variables
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "variable_type": "env_var",
        "value": "TEST_1",
        "protected": false,
        "masked": false,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    },
    {
        "key": "TEST_VARIABLE_2",
        "variable_type": "env_var",
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

## 変数の詳細を表示 {#show-variable-details}

{{< history >}}

- `filter`パラメータは、GitLab 16.9で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)。

{{< /history >}}

グループの特定の変数の詳細を取得します。同じキーを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
GET /groups/:id/variables/:key
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key`     | 文字列         | はい      | 変数の`key`。 |
| `filter`  | ハッシュ           | いいえ       | 利用可能なフィルターは`[environment_scope]`です。[`filter`パラメータ](#the-filter-parameter)の詳細を参照してください。 |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## 変数を作成 {#create-variable}

{{< history >}}

- `masked_and_hidden`属性と`hidden`属性は、GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/29674)されました。

{{< /history >}}

新しい変数を作成します。

```plaintext
POST /groups/:id/variables
```

| 属性                             | 型           | 必須 | 説明 |
|---------------------------------------|----------------|----------|-------------|
| `id`                                  | 整数または文字列 | はい      | グループのIDまたはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`                                 | 文字列         | はい      | 変数の`key`。255文字以下である必要があります。`A-Z`、`a-z`、`0-9`、および`_`のみが使用できます。 |
| `value`                               | 文字列         | はい      | 変数の`value`。 |
| `description`                         | 文字列         | いいえ       | 変数の`description`。255文字以内で指定してください。デフォルトは`null`です。 |
| `environment_scope`                   | 文字列         | いいえ       | 変数の[環境スコープ](../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)。PremiumおよびUltimateのみです。 |
| `masked`                              | ブール値        | いいえ       | 変数がマスクされるかどうかを指定します。 |
| `masked_and_hidden`                   | ブール値        | いいえ       | 変数がマスクされ、非表示になるかどうかを指定します。デフォルトは`false`です。 |
| `protected`                           | ブール値        | いいえ       | 変数が保護されるかどうかを指定します。 |
| `raw`                                 | ブール値        | いいえ       | 変数がraw文字列として扱われるかどうかを指定します。デフォルトは`true`です。`false`の場合、値の変数は[展開](../ci/variables/_index.md#allow-cicd-variable-expansion)されます。 |
| `variable_type`                       | 文字列         | いいえ       | 変数の型。使用可能なタイプは、`env_var`（デフォルト）と`file`です。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value",
    "variable_type": "env_var",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## 変数を更新 {#update-variable}

{{< history >}}

- `filter`パラメータは、GitLab 16.9で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)。

{{< /history >}}

グループの変数を更新します。同じキーを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
PUT /groups/:id/variables/:key
```

| 属性                             | 型           | 必須 | 説明 |
|---------------------------------------|----------------|----------|-------------|
| `id`                                  | 整数または文字列 | はい      | グループのIDまたはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key`                                 | 文字列         | はい      | 変数の`key`。 |
| `value`                               | 文字列         | はい      | 変数の`value`。 |
| `description`                         | 文字列         | いいえ       | 変数の説明。デフォルトは`null`です。GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409641)されました。 |
| `environment_scope`                   | 文字列         | いいえ       | 変数の[環境スコープ](../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)。PremiumおよびUltimateのみです。 |
| `filter`                              | ハッシュ           | いいえ       | 利用可能なフィルターは`[environment_scope]`です。[`filter`パラメータ](#the-filter-parameter)の詳細を参照してください。 |
| `masked`                              | ブール値        | いいえ       | 変数がマスクされるかどうかを指定します。 |
| `protected`                           | ブール値        | いいえ       | 変数が保護されるかどうかを指定します。 |
| `raw`                                 | ブール値        | いいえ       | 変数がraw文字列として扱われるかどうかを指定します。デフォルトは`true`です。`false`の場合、値の変数は[展開](../ci/variables/_index.md#allow-cicd-variable-expansion)されます。 |
| `variable_type`                       | 文字列         | いいえ       | 変数の型。利用可能な型は、`env_var`（デフォルト）と`file`です。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "variable_type": "env_var",
    "protected": true,
    "masked": true,
    "hidden": false,
    "raw": true,
    "environment_scope": "*",
    "description": null
}
```

## 変数を削除 {#remove-variable}

{{< history >}}

- `filter`パラメータは、GitLab 16.9で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)。

{{< /history >}}

グループの変数を削除します。同じキーを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
DELETE /groups/:id/variables/:key
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `key`     | 文字列         | はい      | 変数の`key`。 |
| `filter`  | ハッシュ           | いいえ       | 利用可能なフィルターは`[environment_scope]`です。[`filter`パラメータ](#the-filter-parameter)の詳細を参照してください。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/VARIABLE_1"
```

## `filter`パラメータ {#the-filter-parameter}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)されました。

{{< /history >}}

複数の変数が同じ`key`を持っている場合、[GET](#show-variable-details) 、[PUT](#update-variable) 、または[DELETE](#remove-variable)リクエストは次のメッセージを返す可能性があります:

```plaintext
There are multiple variables with provided parameters. Please use 'filter[environment_scope]'.
```

このような場合は、`filter[environment_scope]`を使用して、一致する`environment_scope`属性を持つ変数を選択します。

例: 

- GET:

  ```shell
  curl \
    --globoff \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1?filter[environment_scope]=production"
  ```

- PUT:

  ```shell
  curl --request PUT \
    --globoff \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1?value=scoped-variable-updated-value&environment_scope=production&filter[environment_scope]=production"
  ```

- DELETE:

  ```shell
  curl --request DELETE \
    --globoff \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1?filter[environment_scope]=production"
  ```
