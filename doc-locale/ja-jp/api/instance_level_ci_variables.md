---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: インスタンスレベルインスタンスのCI/CD変数API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、インスタンスの[CI/CD変数](../ci/variables/_index.md#for-an-instance)を操作します。

## すべてのインスタンス変数をリスト表示 {#list-all-instance-variables}

{{< history >}}

- `description`パラメータがGitLab 16.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)。

{{< /history >}}

すべてのインスタンスレベルの変数のリストを取得します。結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

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

## インスタンス変数の詳細を表示 {#show-instance-variable-details}

{{< history >}}

- `description`パラメータがGitLab 16.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)。

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

## インスタンス変数を作成 {#create-instance-variable}

{{< history >}}

- `description`パラメータがGitLab 16.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)。

{{< /history >}}

新しいインスタンスレベルの変数を作成します。

[インスタンスレベルの変数の最大数](../administration/instance_limits.md#cicd-variable-limits)は変更可能です。

```plaintext
POST /admin/ci/variables
```

| 属性       | 型    | 必須 | 説明 |
|-----------------|---------|----------|-------------|
| `key`           | 文字列  | はい      | 変数の`key`。最大255文字、`A-Z`、`a-z`、`0-9`、および`_`のみが許可されます。 |
| `value`         | 文字列  | はい      | 変数の`value`。最大10,000文字。 |
| `description`   | 文字列  | いいえ       | 変数の説明。最大255文字。 |
| `masked`        | ブール値 | いいえ       | 変数がマスクされるかどうかを指定します。 |
| `protected`     | ブール値 | いいえ       | 変数が保護されるかどうかを指定します。 |
| `raw`           | ブール値 | いいえ       | 変数が展開可能かどうか。 |
| `variable_type` | 文字列  | いいえ       | 変数の種類。使用可能な種類は、`env_var`（デフォルト）と`file`です。 |

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

## インスタンス変数を更新 {#update-instance-variable}

{{< history >}}

- `description`パラメータがGitLab 16.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)。

{{< /history >}}

インスタンスレベルの変数を更新します。

```plaintext
PUT /admin/ci/variables/:key
```

| 属性       | 型    | 必須 | 説明 |
|-----------------|---------|----------|-------------|
| `description`   | 文字列  | いいえ       | 変数の説明。最大255文字。 |
| `key`           | 文字列  | はい      | 変数の`key`。最大255文字、`A-Z`、`a-z`、`0-9`、および`_`のみが許可されます。 |
| `masked`        | ブール値 | いいえ       | 変数がマスクされるかどうかを指定します。 |
| `protected`     | ブール値 | いいえ       | 変数が保護されるかどうかを指定します。 |
| `raw`           | ブール値 | いいえ       | 変数が展開可能かどうか。 |
| `value`         | 文字列  | はい      | 変数の`value`。最大10,000文字。 |
| `variable_type` | 文字列  | いいえ       | 変数の種類。使用可能な種類は、`env_var`（デフォルト）と`file`です。 |

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

## インスタンス変数を削除 {#remove-instance-variable}

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
