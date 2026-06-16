---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループレベル変数API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.9で[`filter`](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)が導入されました。

{{< /history >}}

このAPIを使用して、グループの[CI/CD変数](../ci/variables/_index.md#for-a-group)を操作します。

前提条件: 

- グループのオーナーのロールを持っている必要があります。

## すべてのグループ変数を一覧表示 {#list-all-group-variables}

指定されたグループのすべての変数をリスト表示します。結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

```plaintext
GET /groups/:id/variables
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

```shell
curl --request GET \
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

## グループ変数の詳細を取得する {#retrieve-details-of-a-group-variable}

{{< history >}}

- GitLab 16.9で`filter`パラメータが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)されました。

{{< /history >}}

指定されたグループ変数の詳細を取得します。同じキーを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
GET /groups/:id/variables/:key
```

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | 変数のキー。 |
| `filter`  | ハッシュ              | いいえ       | 複数の変数が同じキーを共有している場合に結果をフィルターします。指定可能な値: `[environment_scope]`。PremiumおよびUltimateのみです。 |

リクエスト例: 

```shell
curl --request GET \
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

`filter`を伴うリクエストの例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```

## グループ変数を作成する {#create-a-group-variable}

{{< history >}}

- `masked_and_hidden`属性と`hidden`属性は、GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/29674)されました。

{{< /history >}}

グループ変数を作成します。

```plaintext
POST /groups/:id/variables
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`               | 文字列            | はい      | 変数の`key`。最大255文字。許可されるのは、`A-Z`、`a-z`、`0-9`、および`_`のみです。 |
| `value`             | 文字列            | はい      | 変数の`value`。 |
| `description`       | 文字列            | いいえ       | 変数の`description`。最大255文字。デフォルトは`null`です。 |
| `environment_scope` | 文字列            | いいえ       | 変数の[環境スコープ](../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)。PremiumおよびUltimateのみです。 |
| `masked`            | ブール値           | いいえ       | 変数がマスクされるかどうかを指定します。 |
| `masked_and_hidden` | ブール値           | いいえ       | 変数がマスクされ、非表示になるかどうかを指定します。デフォルトは`false`です。 |
| `protected`         | ブール値           | いいえ       | 変数が保護されるかどうかを指定します。 |
| `raw`               | ブール値           | いいえ       | 変数がraw文字列として扱われるかどうかを指定します。デフォルトは`true`です。`false`の場合、値内の変数は[展開されます](../ci/variables/_index.md#allow-cicd-variable-expansion)。 |
| `variable_type`     | 文字列            | いいえ       | 変数の型。利用可能なタイプは、`env_var`（デフォルト）と`file`です。 |

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

## グループ変数を更新する {#update-a-group-variable}

{{< history >}}

- GitLab 16.9で`filter`パラメータが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)されました。

{{< /history >}}

指定されたグループ変数を更新します。同じキーを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

> [!warning]
> `environment_scope`に対してフィルタリングしたときに、その`environment_scope`が存在しない場合、エンドポイントは同じ名前で異なる環境スコープの変数の更新にフォールバックします。[グループ変数の詳細を取得する](#retrieve-details-of-a-group-variable)エンドポイントを使用して、指定された変数のスコープの存在を確認します。

```plaintext
PUT /groups/:id/variables/:key
```

| 属性           | 型              | 必須 | 説明 |
| ------------------- | ----------------- | -------- | ----------- |
| `id`                | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`               | 文字列            | はい      | 変数のキー。 |
| `value`             | 文字列            | はい      | 変数の値。 |
| `description`       | 文字列            | いいえ       | 変数の説明。GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409641)されました。デフォルトは`null`です。 |
| `environment_scope` | 文字列            | いいえ       | 変数の[環境スコープ](../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)。PremiumおよびUltimateのみです。 |
| `filter`            | ハッシュ              | いいえ       | 複数の変数が同じキーを共有している場合に結果をフィルターします。指定可能な値: `[environment_scope]`。PremiumおよびUltimateのみです。 |
| `masked`            | ブール値           | いいえ       | `true`の場合、変数がマスクされていることを示します。 |
| `protected`         | ブール値           | いいえ       | `true`の場合、変数が保護されていることを示します。 |
| `raw`               | ブール値           | いいえ       | `true`の場合、変数がraw文字列として扱われることを示します。`false`の場合、変数の値は[展開されます](../ci/variables/_index.md#allow-cicd-variable-expansion)。デフォルトは`true`です。 |
| `variable_type`     | 文字列            | いいえ       | 変数のタイプ。利用可能なタイプは、`env_var`（デフォルト）と`file`です。 |

リクエスト例: 

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

`filter`を伴うリクエストの例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1" \
  --form "value=updated value" \
  --form "environment_scope=production" \
  --form "filter[environment_scope]=production"
```

## グループ変数を削除する {#delete-a-group-variable}

{{< history >}}

- GitLab 16.9で`filter`パラメータが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/340185)されました。

{{< /history >}}

指定されたグループ変数を削除します。同じキーを持つ変数が複数ある場合は、`filter`を使用して、正しい`environment_scope`を選択します。

```plaintext
DELETE /groups/:id/variables/:key
```

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | 変数のキー。 |
| `filter`  | ハッシュ              | いいえ       | 複数の変数が同じキーを共有している場合に結果をフィルターします。指定可能な値: `[environment_scope]`。PremiumおよびUltimateのみです。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/VARIABLE_1"
```

`filter`を伴うリクエストの例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```
