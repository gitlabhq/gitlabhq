---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ラベルAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `archived`属性は、GitLab 18.3で`labels_archive`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/4233)されました。デフォルトでは無効になっています。

{{< /history >}}

[ラベル](../user/project/labels.md)をREST APIで使用して操作します。

## ラベルの一覧表示 {#list-labels}

特定のプロジェクトのすべてのラベルを取得します。

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、このリクエストは一度に20個の結果を返します。

```plaintext
GET /projects/:id/labels
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                                                              |
| `with_counts` | ブール値        | いいえ       | イシューとマージリクエストの数を組み込むかどうか。`false`がデフォルトです。 |
| `include_ancestor_groups` | ブール値 | いいえ | 祖先グループを含めます。`true`がデフォルトです。 |
| `search` | 文字列 | いいえ | ラベルをフィルタリングするキーワード。 |
| `archived` | ブール値 | いいえ | ラベルがアーカイブされているかどうか。設定されていない場合、すべてのラベルを返します。`labels_archive`機能フラグを有効にする必要があります。 |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels?with_counts=true"
```

レスポンス例:

```json
[
  {
    "id" : 1,
    "name" : "bug",
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "description": "Bug reported by user",
    "description_html": "Bug reported by user",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 1,
    "subscribed": false,
    "priority": 10,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 4,
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "name" : "confirmed",
    "description": "Confirmed issue",
    "description_html": "Confirmed issue",
    "open_issues_count": 2,
    "closed_issues_count": 5,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "priority": null,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 7,
    "name" : "critical",
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "description": "Critical issue. Need fix ASAP",
    "description_html": "Critical issue. Need fix ASAP",
    "open_issues_count": 1,
    "closed_issues_count": 3,
    "open_merge_requests_count": 1,
    "subscribed": false,
    "priority": null,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 8,
    "name" : "documentation",
    "color" : "#f0ad4e",
    "text_color" : "#FFFFFF",
    "description": "Issue about documentation",
    "description_html": "Issue about documentation",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 2,
    "subscribed": false,
    "priority": null,
    "is_project_label": false,
    "archived": false
  },
  {
    "id" : 9,
    "color" : "#5cb85c",
    "text_color" : "#FFFFFF",
    "name" : "enhancement",
    "description": "Enhancement proposal",
    "description_html": "Enhancement proposal",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 1,
    "subscribed": true,
    "priority": null,
    "is_project_label": true,
    "archived": false
  }
]
```

## 単一プロジェクトラベルを取得します {#get-a-single-project-label}

特定のプロジェクトの単一のラベルを取得します。

```plaintext
GET /projects/:id/labels/:label_id
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                                                              |
| `label_id` | 整数または文字列 | はい | プロジェクトのラベルのIDまたはタイトル。 |
| `include_ancestor_groups` | ブール値 | いいえ | 祖先グループを含めます。`true`がデフォルトです。 |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/bug"
```

レスポンス例:

```json
{
  "id" : 1,
  "name" : "bug",
  "color" : "#d9534f",
  "text_color" : "#FFFFFF",
  "description": "Bug reported by user",
  "description_html": "Bug reported by user",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 1,
  "subscribed": false,
  "priority": 10,
  "is_project_label": true,
  "archived": false
}
```

## 新しいラベルを作成 {#create-a-new-label}

指定されたリポジトリに、指定された名前と色で新しいラベルを作成します。

```plaintext
POST /projects/:id/labels
```

| 属性     | 型    | 必須 | 説明                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`      | 整数または文字列    | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`        | 文字列  | はい      | ラベルの名前        |
| `color`       | 文字列  | はい      | ラベルの色。先頭が「#」記号の6桁の16進数表記（#FFAABBなど）か、または[CSSカラー名](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords)のいずれかで指定。 |
| `description` | 文字列  | いいえ       | ラベルの説明。 |
| `priority`    | 整数 | いいえ       | ラベルの優先度。優先度を削除するには、ゼロ以上または`null`にする必要があります。 |
| `archived`    | ブール値 | いいえ       | ラベルがアーカイブされているかどうか。`false`がデフォルトです。`labels_archive`機能フラグを有効にする必要があります。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels" \
  --data "name=feature&color=#5843AD"
```

レスポンス例:

```json
{
  "id" : 10,
  "name" : "feature",
  "color" : "#5843AD",
  "text_color" : "#FFFFFF",
  "description":null,
  "description_html":null,
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

## ラベルを削除 {#delete-a-label}

指定された名前のラベルを削除します。

```plaintext
DELETE /projects/:id/labels/:label_id
```

| 属性 | 型    | 必須 | 説明           |
| --------- | ------- | -------- | --------------------- |
| `id`            | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい | グループのラベルのIDまたはタイトル。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/bug"
```

{{< alert type="note" >}}

パラメータに`name`を含む古いエンドポイント`DELETE /projects/:id/labels`はまだ利用可能ですが、非推奨です。

{{< /alert >}}

## 既存のラベルを編集 {#edit-an-existing-label}

既存のラベルを新しい名前または新しい色で更新します。ラベルを更新するには、少なくとも1つのパラメータが必要です。

```plaintext
PUT /projects/:id/labels/:label_id
```

| 属性       | 型    | 必須                          | 説明                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | 整数または文字列    | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい | グループのラベルのIDまたはタイトル。 |
| `new_name`      | 文字列  | はい（`color`が指定されていない場合）    | ラベルの新しい名前        |
| `color`         | 文字列  | はい（`new_name`が指定されていない場合） | ラベルの色。先頭が「#」記号の6桁の16進数表記（#FFAABBなど）か、または[CSSカラー名](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords)のいずれかで指定。 |
| `description`   | 文字列  | いいえ                                | 新しいラベルの説明 |
| `priority`    | 整数 | いいえ       | ラベルの新しい優先度。優先度を削除するには、ゼロ以上または`null`にする必要があります。 |
| `archived`    | ブール値 | いいえ       | ラベルがアーカイブされているかどうか。`labels_archive`機能フラグを有効にする必要があります。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/documentation" \
  --data "new_name=docs&color=#8E44AD&description=Documentation"
```

レスポンス例:

```json
{
  "id" : 8,
  "name" : "docs",
  "color" : "#8E44AD",
  "text_color" : "#FFFFFF",
  "description": "Documentation",
  "description_html": "Documentation",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 2,
  "subscribed": false,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

{{< alert type="note" >}}

パラメータに`name`または`label_id`を含む古いエンドポイント`PUT /projects/:id/labels`はまだ利用可能ですが、非推奨です。

{{< /alert >}}

## プロジェクトラベルをグループラベルにプロモート {#promote-a-project-label-to-a-group-label}

プロジェクトラベルをグループラベルにプロモートラベルはIDを保持します。

```plaintext
PUT /projects/:id/labels/:label_id/promote
```

| 属性       | 型    | 必須                          | 説明                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | 整数または文字列    | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい | グループのラベルのIDまたはタイトル。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/documentation/promote"
```

レスポンス例:

```json
{
  "id" : 8,
  "name" : "documentation",
  "color" : "#8E44AD",
  "description": "Documentation",
  "description_html": "Documentation",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 2,
  "subscribed": false,
  "archived": false
}
```

{{< alert type="note" >}}

パラメータに`name`を含む古いエンドポイント`PUT /projects/:id/labels/promote`はまだ利用可能ですが、非推奨です。

{{< /alert >}}

## ラベルにサブスクライブ {#subscribe-to-a-label}

認証済みユーザーが通知を受信できるように、ラベルをサブスクライブさせます。ユーザーがすでにラベルをサブスクライブしている場合、ステータスコード`304`が返されます。

```plaintext
POST /projects/:id/labels/:label_id/subscribe
```

| 属性  | 型              | 必須 | 説明                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | 整数または文字列    | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい      | プロジェクトのラベルのIDまたはタイトル |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/labels/1/subscribe"
```

レスポンス例:

```json
{
  "id" : 1,
  "name" : "bug",
  "color" : "#d9534f",
  "text_color" : "#FFFFFF",
  "description": "Bug reported by user",
  "description_html": "Bug reported by user",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 1,
  "subscribed": true,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

## ラベルの登録解除 {#unsubscribe-from-a-label}

通知を受信しないようにするため、認証済みユーザーをラベルからサブスクライブ解除します。ユーザーがラベルをサブスクライブしていない場合、ステータスコード`304`が返されます。

```plaintext
POST /projects/:id/labels/:label_id/unsubscribe
```

| 属性  | 型              | 必須 | 説明                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | 整数または文字列    | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい      | プロジェクトのラベルのIDまたはタイトル |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/labels/1/unsubscribe"
```
