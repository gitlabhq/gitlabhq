---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: インスタンスレベルCI/CD変数API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、インスタンスの[CI/CD変数](../ci/variables/_index.md#for-an-instance)を操作します。

## すべてのインスタンス変数をリスト {#list-all-instance-variables}

{{< history >}}

- `description`パラメータはGitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)されました。

{{< /history >}}

すべてのインスタンスレベルの変数をリストします。結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

```plaintext
GET /admin/ci/variables
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "description": null,
        "variable_type": "env_var",
        "value": "TEST_1",
        "protected": false,
        "masked": false,
        "raw": false
    },
    {
        "key": "TEST_VARIABLE_2",
        "description": null,
        "variable_type": "env_var",
        "value": "TEST_2",
        "protected": false,
        "masked": false,
        "raw": false
    }
]
```

## インスタンス変数の詳細を取得 {#retrieve-instance-variable-details}

{{< history >}}

- `description`パラメータはGitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)されました。

{{< /history >}}

特定のインスタンスレベルの変数の詳細を取得します。

```plaintext
GET /admin/ci/variables/:key
```

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `key`     | 文字列  | はい      | 変数の`key`。 |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "description": null,
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": false,
    "raw": false
}
```

## インスタンス変数の作成 {#create-instance-variable}

{{< history >}}

- `description`パラメータはGitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)されました。

{{< /history >}}

新しいインスタンスレベルの変数を作成します。

[最大数のインスタンスレベルの変数](../administration/cicd/limits.md#instance-cicd-variable-limit)は変更できます。

```plaintext
POST /admin/ci/variables
```

| 属性       | 型    | 必須 | 説明 |
|-----------------|---------|----------|-------------|
| `key`           | 文字列  | はい      | 変数の`key`。最大255文字で、`A-Z`、`a-z`、`0-9`、`_`のみが許可されています。 |
| `value`         | 文字列  | はい      | 変数の`value`。最大10,000文字。 |
| `description`   | 文字列  | いいえ       | 変数の説明。最大255文字。 |
| `masked`        | ブール値 | いいえ       | 変数がマスクされるかどうかを指定します。 |
| `protected`     | ブール値 | いいえ       | 変数が保護されるかどうかを指定します。 |
| `raw`           | ブール値 | いいえ       | 変数が展開可能かどうか。 |
| `variable_type` | 文字列  | いいえ       | 変数のタイプ。利用可能なタイプは、`env_var`（デフォルト）と`file`です。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "description": null,
    "value": "new value",
    "variable_type": "env_var",
    "protected": false,
    "masked": false,
    "raw": false
}
```

## インスタンス変数の更新 {#update-instance-variable}

{{< history >}}

- `description`パラメータはGitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)されました。

{{< /history >}}

インスタンスレベルの変数を更新します。

```plaintext
PUT /admin/ci/variables/:key
```

| 属性       | 型    | 必須 | 説明 |
|-----------------|---------|----------|-------------|
| `description`   | 文字列  | いいえ       | 変数の説明。最大255文字。 |
| `key`           | 文字列  | はい      | 変数の`key`。最大255文字で、`A-Z`、`a-z`、`0-9`、`_`のみが許可されています。 |
| `masked`        | ブール値 | いいえ       | 変数がマスクされるかどうかを指定します。 |
| `protected`     | ブール値 | いいえ       | 変数が保護されるかどうかを指定します。 |
| `raw`           | ブール値 | いいえ       | 変数が展開可能かどうか。 |
| `value`         | 文字列  | はい      | 変数の`value`。最大10,000文字。 |
| `variable_type` | 文字列  | いいえ       | 変数のタイプ。利用可能なタイプは、`env_var`（デフォルト）と`file`です。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "description": null,
    "value": "updated value",
    "variable_type": "env_var",
    "protected": true,
    "masked": true,
    "raw": true
}
```

## インスタンス変数の削除 {#delete-instance-variable}

インスタンスレベルの変数を削除します。

```plaintext
DELETE /admin/ci/variables/:key
```

| 属性 | 型   | 必須 | 説明 |
|-----------|--------|----------|-------------|
| `key`     | 文字列 | はい      | 変数の`key`。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables/VARIABLE_1"
```
