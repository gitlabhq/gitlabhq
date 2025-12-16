---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループラベルAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `archived`属性は、GitLab 18.3で`labels_archive`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/4233)されました。デフォルトでは無効になっています。

{{< /history >}}

このAPIは、[group labels](../user/project/labels.md#types-of-labels)の管理をサポートします。これにより、ユーザーはgroup labelsを一覧表示、作成、更新、削除できます。さらに、ユーザーはgroup labelsをサブスクライブおよびサブスクライブ解除できます。

## Group labelsの一覧表示 {#list-group-labels}

特定のグループのすべてのラベルを取得します。

```plaintext
GET /groups/:id/labels
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                  |
| ---------     | ----           | -------- | -----------                                                                                                                                                                  |
| `id`          | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                               |
| `with_counts` | ブール値        | いいえ       | イシューとマージリクエストの数を表示するかどうか。`false`がデフォルトです。 |
| `include_ancestor_groups` | ブール値 | いいえ | 祖先グループを含めます。`true`がデフォルトです。 |
| `include_descendant_groups` | ブール値 | いいえ | 子孫グループを含めます。`false`がデフォルトです。 |
| `only_group_labels` | ブール値 | いいえ | group labelsのみを含めるか、プロジェクトラベルも表示するかを切り替えます。`true`がデフォルトです。 |
| `search` | 文字列 | いいえ | ラベルをフィルターするキーワード。 |
| `archived` | ブール値 | いいえ | ラベルがアーカイブされているかどうか。設定されていない場合は、すべてのラベルを返します。`:labels_archive`機能フラグを有効にする必要があります。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/labels?with_counts=true"
```

レスポンス例:

```json
[
  {
    "id": 7,
    "name": "bug",
    "color": "#FF0000",
    "text_color" : "#FFFFFF",
    "description": null,
    "description_html": null,
    "open_issues_count": 0,
    "closed_issues_count": 0,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "archived": false
  },
  {
    "id": 4,
    "name": "feature",
    "color": "#228B22",
    "text_color" : "#FFFFFF",
    "description": null,
    "description_html": null,
    "open_issues_count": 0,
    "closed_issues_count": 0,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "archived": false
  }
]
```

## 単一のグループラベルを取得 {#get-a-single-group-label}

特定のグループの単一のラベルを取得します。

```plaintext
GET /groups/:id/labels/:label_id
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                  |
| ---------     | ----           | -------- | -----------                                                                                                                                                                  |
| `id`          | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                               |
| `label_id` | 整数または文字列 | はい | グループのラベルのIDまたはタイトル。 |
| `include_ancestor_groups` | ブール値 | いいえ | 祖先グループを含めます。`true`がデフォルトです。 |
| `include_descendant_groups` | ブール値 | いいえ | 子孫グループを含めます。`false`がデフォルトです。 |
| `only_group_labels` | ブール値 | いいえ | group labelsのみを含めるか、プロジェクトラベルも表示するかを切り替えます。`true`がデフォルトです。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/labels/bug"
```

レスポンス例:

```json
{
  "id": 7,
  "name": "bug",
  "color": "#FF0000",
  "text_color" : "#FFFFFF",
  "description": null,
  "description_html": null,
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```

## 新しいグループラベルを作成 {#create-a-new-group-label}

特定のグループに新しいgroup labelを作成します。

```plaintext
POST /groups/:id/labels
```

| 属性     | 型    | 必須 | 説明                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`        | 文字列  | はい      | ラベルの名前        |
| `color`       | 文字列  | はい      | ラベルの色。先頭が「#」記号の6桁の16進数表記（#FFAABBなど）か、[CSSカラー名](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords)のいずれかで指定。 |
| `description` | 文字列  | いいえ       | ラベルの説明 |
| `archived`    | ブール値 | いいえ       | ラベルがアーカイブされているかどうか。`labels_archive`機能フラグを有効にする必要があります。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     --data '{"name": "Feature Proposal", "color": "#FFA500", "description": "Describes new ideas" }' \
     "https://gitlab.example.com/api/v4/groups/5/labels"
```

レスポンス例:

```json
{
  "id": 9,
  "name": "Feature Proposal",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```

## グループラベルを更新 {#update-a-group-label}

既存のgroup labelを更新します。少なくとも1つのパラメータは、group labelを更新するために必要です。

```plaintext
PUT /groups/:id/labels/:label_id
```

| 属性     | 型    | 必須 | 説明                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい | グループのラベルのIDまたはタイトル。 |
| `new_name`    | 文字列  | いいえ      | ラベルの新しい名前        |
| `color`       | 文字列  | いいえ      | ラベルの色。先頭が「#」記号の6桁の16進数表記（#FFAABBなど）か、[CSSカラー名](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords)のいずれかで指定。 |
| `description` | 文字列  | いいえ       | ラベルの説明。 |
| `archived`    | ブール値 | いいえ       | ラベルがアーカイブされているかどうか。`labels_archive`機能フラグを有効にする必要があります。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     --data '{"new_name": "Feature Idea" }' "https://gitlab.example.com/api/v4/groups/5/labels/Feature%20Proposal"
```

レスポンス例:

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```

{{< alert type="note" >}}

古いエンドポイント`PUT /groups/:id/labels`（パラメータに`name`がある）はまだ使用できますが、非推奨です。

{{< /alert >}}

## グループラベルを削除 {#delete-a-group-label}

指定された名前でgroup labelを削除します。

```plaintext
DELETE /groups/:id/labels/:label_id
```

| 属性 | 型    | 必須 | 説明           |
| --------- | ------- | -------- | --------------------- |
| `id`      | 整数または文字列    | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい | グループのラベルのIDまたはタイトル。 |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/labels/bug"
```

{{< alert type="note" >}}

古いエンドポイント`DELETE /groups/:id/labels`（パラメータに`name`がある）はまだ使用できますが、非推奨です。

{{< /alert >}}

## Group labelをサブスクライブする {#subscribe-to-a-group-label}

認証済みユーザーが通知を受信できるように、グループラベルをサブスクライブします。ユーザーがすでにラベルをサブスクライブしている場合、ステータスコード`304`が返されます。

```plaintext
POST /groups/:id/labels/:label_id/subscribe
```

| 属性  | 型              | 必須 | 説明                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | 整数または文字列    | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい      | グループのラベルのIDまたはタイトル。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/labels/9/subscribe"
```

レスポンス例:

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": true,
  "archived": false
}
```

## Group labelのサブスクライブを解除する {#unsubscribe-from-a-group-label}

通知を受信しないようにするため、認証済みユーザーをグループラベルからサブスクライブ解除します。ユーザーがラベルをサブスクライブしていない場合、ステータスコード`304`が返されます。

```plaintext
POST /groups/:id/labels/:label_id/unsubscribe
```

| 属性  | 型              | 必須 | 説明                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | 整数または文字列    | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい      | グループのラベルのIDまたはタイトル。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/labels/9/unsubscribe"
```

レスポンス例:

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```
