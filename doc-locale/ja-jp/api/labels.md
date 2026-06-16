---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトラベルAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `archived`属性がGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/4233)され、`labels_archive`という[フラグ](../administration/feature_flags/_index.md)が付けられました。
- GitLab 18.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/556700)になりました。機能フラグ`labels_archive`は削除されました。

{{< /history >}}

このAPIを使用して、[プロジェクトラベル](../user/project/labels.md)を管理します。

グループラベルの場合は、[グループラベルAPI](group_labels.md)を使用します。

## すべてのプロジェクトラベルをリスト表示 {#list-all-project-labels}

指定されたプロジェクトのすべてのラベルをリスト表示します。

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、このリクエストは一度に20個の結果を返します。

```plaintext
GET /projects/:id/labels
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                                                              |
| `with_counts` | ブール値        | いいえ       | イシューとマージリクエストの数をインクルードするかどうか。`false`がデフォルトです。 |
| `include_ancestor_groups` | ブール値 | いいえ | 祖先グループを含めます。`true`がデフォルトです。 |
| `search` | 文字列 | いいえ | ラベルをフィルタリングするためのキーワード。 |
| `archived` | ブール値 | いいえ | `true`の場合、アーカイブされたラベルのみを返します。設定されていない場合、すべてのラベルを返します。 |

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

## プロジェクトラベルを取得する {#retrieve-a-project-label}

プロジェクトの指定されたラベルを取得します。

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

## プロジェクトラベルを作成 {#create-a-project-label}

指定された名前と色で、指定されたプロジェクトのラベルを作成します。

```plaintext
POST /projects/:id/labels
```

| 属性     | 型    | 必須 | 説明                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`      | 整数または文字列    | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`        | 文字列  | はい      | ラベルの名前        |
| `color`       | 文字列  | はい      | 先頭に「#」記号が付いた6桁の16進表記（例: #FFAABB）で指定されたラベルの色、または[CSSの色名](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords)のいずれか。 |
| `description` | 文字列  | いいえ       | ラベルの説明 |
| `priority`    | 整数 | いいえ       | ラベルの優先度。0以上であるか、`null`を設定して優先度を削除する必要があります。 |
| `archived`    | ブール値 | いいえ       | `true`の場合、ラベルをアーカイブ済みとしてマークします。デフォルト値: `false`。 |

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

## プロジェクトラベルを削除 {#delete-a-project-label}

プロジェクトから指定されたラベルを削除します。

```plaintext
DELETE /projects/:id/labels/:label_id
```

| 属性 | 型    | 必須 | 説明           |
| --------- | ------- | -------- | --------------------- |
| `id`            | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい | プロジェクトのラベルのIDまたはタイトル。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/bug"
```

> [!note]
> パラメータに`name`を含む古いエンドポイント`DELETE /projects/:id/labels`は引き続き利用可能ですが、非推奨です。

## プロジェクトラベルを更新 {#update-a-project-label}

指定されたプロジェクトの指定されたラベルを新しい名前または色で更新します。ラベルを更新するには、少なくとも1つのパラメータが必要です。

```plaintext
PUT /projects/:id/labels/:label_id
```

| 属性       | 型    | 必須                          | 説明                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | 整数または文字列    | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい | プロジェクトのラベルのIDまたはタイトル。 |
| `new_name`      | 文字列  | `color`が指定されていない場合はyes    | ラベルの新しい名前        |
| `color`         | 文字列  | `new_name`が指定されていない場合はyes | 先頭に「#」記号が付いた6桁の16進表記（例: #FFAABB）で指定されたラベルの色、または[CSSの色名](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords)のいずれか。 |
| `description`   | 文字列  | いいえ                                | ラベルの新しい説明 |
| `priority`    | 整数 | いいえ       | ラベルの新しい優先度。0以上であるか、`null`を設定して優先度を削除する必要があります。 |
| `archived`    | ブール値 | いいえ       | `true`の場合、ラベルをアーカイブ済みとしてマークします。デフォルト値: `false`。 |

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

> [!note]
> パラメータに`name`または`label_id`を含む古いエンドポイント`PUT /projects/:id/labels`は引き続き利用可能ですが、非推奨です。

## プロジェクトラベルをグループラベルにプロモート {#promote-a-project-label-to-a-group-label}

指定されたプロジェクトラベルをグループラベルにプロモートします。このラベルは元のIDを保持します。

```plaintext
PUT /projects/:id/labels/:label_id/promote
```

| 属性       | 型    | 必須                          | 説明                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | 整数または文字列    | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `label_id` | 整数または文字列 | はい | プロジェクトのラベルのIDまたはタイトル。 |

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

> [!note]
> パラメータに`name`を含む古いエンドポイント`PUT /projects/:id/labels/promote`は引き続き利用可能ですが、非推奨です。

## プロジェクトラベルを購読 {#subscribe-to-a-project-label}

認証済みユーザーを、指定されたプロジェクトラベルに購読させて通知を受け取ります。ユーザーがすでにラベルを購読している場合、ステータスコード`304`が返されます。

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

## プロジェクトラベルの購読を解除 {#unsubscribe-from-a-project-label}

認証済みユーザーを、指定されたプロジェクトラベルの購読から解除して通知の受信を停止します。ユーザーがラベルを購読していない場合、ステータスコード`304`が返されます。

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
