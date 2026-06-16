---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループラベルAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3で、`archived`属性が`labels_archive`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/4233)されました。
- GitLab 18.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/556700)になりました。機能フラグ`labels_archive`は削除されました。

{{< /history >}}

このAPIを使用して、[グループラベル](../user/project/labels.md#types-of-labels)を管理します。

プロジェクトラベルには、[プロジェクトラベルAPI](labels.md)を使用します。

## グループラベルの一覧表示 {#list-group-labels}

指定されたグループのすべてのラベルを取得します。

```plaintext
GET /groups/:id/labels
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                  |
| ---------     | ----           | -------- | -----------                                                                                                                                                                  |
| `id`          | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                               |
| `with_counts` | ブール値        | いいえ       | イシューとマージリクエストの数を含めるかどうか。`false`がデフォルトです。 |
| `include_ancestor_groups` | ブール値 | いいえ | 祖先グループを含めます。`true`がデフォルトです。 |
| `include_descendant_groups` | ブール値 | いいえ | 子孫グループを含めます。`false`がデフォルトです。 |
| `only_group_labels` | ブール値 | いいえ | グループラベルのみを含めるか、プロジェクトラベルも一緒に含めるかの切替。`true`がデフォルトです。 |
| `search` | 文字列 | いいえ | ラベルでフィルタリングするキーワード。 |
| `archived` | ブール値 | いいえ | `true`の場合、アーカイブされたラベルのみを返します。設定されていない場合、すべてのラベルを返します。 |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels?with_counts=true"
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

指定されたグループの単一のラベルを取得します。

```plaintext
GET /groups/:id/labels/:label_id
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                  |
| ---------     | ----           | -------- | -----------                                                                                                                                                                  |
| `id`          | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                               |
| `label_id` | 整数または文字列 | はい | グループのラベルのIDまたはタイトル。 |
| `include_ancestor_groups` | ブール値 | いいえ | 祖先グループを含めます。`true`がデフォルトです。 |
| `include_descendant_groups` | ブール値 | いいえ | 子孫グループを含めます。`false`がデフォルトです。 |
| `only_group_labels` | ブール値 | いいえ | グループラベルのみを含めるか、プロジェクトラベルも一緒に含めるかの切替。`true`がデフォルトです。 |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/bug"
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

指定されたグループの新しいグループラベルを作成します。

```plaintext
POST /groups/:id/labels
```

| 属性     | 型    | 必須 | 説明                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`        | 文字列  | はい      | ラベルの名前        |
| `color`       | 文字列  | はい      | ラベルの色。先頭に「#」が付いた6桁の16進表記（例: #FFAABB）または[CSSカラー名](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords)のいずれかで指定します。 |
| `description` | 文字列  | いいえ       | ラベルの説明、 |
| `archived`    | ブール値 | いいえ       | `true`の場合、ラベルをアーカイブ済みとしてマークします。デフォルト値: false。デフォルト値: `false`。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "Feature Proposal",
    "color": "#FFA500",
    "description": "Describes new ideas"
  }' \
  --url "https://gitlab.example.com/api/v4/groups/5/labels"
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

既存のグループラベルを更新します。グループラベルを更新するには、少なくとも1つのパラメータが必要です。

```plaintext
PUT /groups/:id/labels/:label_id
```

| 属性     | 型    | 必須 | 説明                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい | グループのラベルのIDまたはタイトル。 |
| `new_name`    | 文字列  | いいえ      | ラベルの新しい名前        |
| `color`       | 文字列  | いいえ      | ラベルの色。先頭に「#」が付いた6桁の16進表記（例: #FFAABB）または[CSSカラー名](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords)のいずれかで指定します。 |
| `description` | 文字列  | いいえ       | ラベルの説明。 |
| `archived`    | ブール値 | いいえ       | `true`の場合、ラベルをアーカイブ済みとしてマークします。デフォルト値: false。デフォルト値: `false`。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"new_name": "Feature Idea"}' \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/Feature%20Proposal"
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

> [!note]
> 古いエンドポイント`PUT /groups/:id/labels` (パラメータに`name`を含む) は引き続き利用可能ですが、非推奨です。

## グループラベルを削除 {#delete-a-group-label}

指定された名前のグループラベルを削除します。

```plaintext
DELETE /groups/:id/labels/:label_id
```

| 属性 | 型    | 必須 | 説明           |
| --------- | ------- | -------- | --------------------- |
| `id`      | 整数または文字列    | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい | グループのラベルのIDまたはタイトル。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/bug"
```

> [!note]
> 古いエンドポイント`DELETE /groups/:id/labels` (パラメータに`name`を含む) は引き続き利用可能ですが、非推奨です。

## グループラベルを購読 {#subscribe-to-a-group-label}

認証済みユーザーをグループラベルに登録し、通知を受け取ります。ユーザーがすでにラベルを購読している場合、ステータスコード`304`が返されます。

```plaintext
POST /groups/:id/labels/:label_id/subscribe
```

| 属性  | 型              | 必須 | 説明                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | 整数または文字列    | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい      | グループのラベルのIDまたはタイトル。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/9/subscribe"
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

## グループラベルの購読解除 {#unsubscribe-from-a-group-label}

認証済みユーザーをグループラベルから登録解除し、それからの通知を受け取らないようにします。ユーザーがラベルを購読していない場合、ステータスコード`304`が返されます。

```plaintext
POST /groups/:id/labels/:label_id/unsubscribe
```

| 属性  | 型              | 必須 | 説明                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | 整数または文字列    | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい      | グループのラベルのIDまたはタイトル。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/9/unsubscribe"
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
