---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループバッジAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、グループバッジを操作します。詳細については、[グループバッジ](../user/project/badges.md#group-badges)を参照してください。

バッジは、リンクと画像URLの両方でリアルタイムに置換されるプレースホルダーをサポートしています。次のプレースホルダーを使用できます:

- `%{project_path}`: プロジェクトパスに置換されます。
- `%{project_title}`: プロジェクトタイトルに置換されます。
- `%{project_name}`: プロジェクト名に置換されます。
- `%{project_id}`: プロジェクトIDに置換されます。
- `%{project_namespace}`: プロジェクトのネームスペースのフルパスに置換されます。
- `%{group_name}`: プロジェクトのトップレベルグループ名に置換されます。
- `%{gitlab_server}`: プロジェクトのサーバー名に置換されます。
- `%{gitlab_pages_domain}`: GitLab Pagesをホストしているドメイン名に置換されます。
- `%{default_branch}`: プロジェクトのデフォルトブランチに置換されます。
- `%{commit_sha}`: プロジェクトの最後のコミットSHAに置換されます。
- `%{latest_tag}`: プロジェクトの最後のタグに置換されます。

これらのエンドポイントはプロジェクトのコンテキスト内にないため、プレースホルダーの置換に使用される情報は、作成日順で最初のグループのプロジェクトから取得されます。グループにプロジェクトがない場合、プレースホルダーを含む元のURLが返されます。

## すべてのグループバッジをリストする {#list-all-group-badges}

指定されたグループのバッジをリストします。

```plaintext
GET /groups/:id/badges
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`    | 文字列         | いいえ  | 返すバッジの名前（大文字と小文字を区別します）。 |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges?name=Coverage"
```

レスポンス例: 

```json
[
  {
    "name": "Coverage",
    "id": 1,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
    "rendered_image_url": "https://shields.io/my/badge",
    "kind": "group"
  }
]
```

## グループバッジを取得する {#retrieve-a-group-badge}

グループの指定されたバッジを取得します。

```plaintext
GET /groups/:id/badges/:badge_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `badge_id` | 整数 | はい   | バッジID |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
```

レスポンス例: 

```json
{
  "name": "Coverage",
  "id": 1,
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "group"
}
```

## グループバッジを作成する {#create-a-group-badge}

指定されたグループのバッジを作成します。

```plaintext
POST /groups/:id/badges
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `link_url` | 文字列         | はい | バッジリンクのURL |
| `image_url` | 文字列 | はい | バッジ画像のURL |
| `name` | 文字列 | いいえ | バッジの名前 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges" \
  --data "link_url=https://gitlab.com/gitlab-org/gitlab-foss/commits/master&image_url=https://shields.io/my/badge1&name=mybadge&position=0"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "image_url": "https://shields.io/my/badge1",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "rendered_image_url": "https://shields.io/my/badge1",
  "kind": "group"
}
```

## グループバッジを更新する {#update-a-group-badge}

指定されたグループのバッジを更新します。

```plaintext
PUT /groups/:id/badges/:badge_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `badge_id` | 整数 | はい   | バッジID |
| `link_url` | 文字列         | いいえ | バッジリンクのURL |
| `image_url` | 文字列 | いいえ | バッジ画像のURL |
| `name` | 文字列 | いいえ | バッジの名前 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/master",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "group"
}
```

## グループバッジを削除する {#delete-a-group-badge}

グループから指定されたバッジを削除します。

```plaintext
DELETE /groups/:id/badges/:badge_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `badge_id` | 整数 | はい   | バッジID |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/:badge_id"
```

## グループバッジプレビューを取得する {#retrieve-a-group-badge-preview}

プレースホルダーの補間を解決した後、指定されたグループの最終的な`link_url`と`image_url`のURLのプレビューを取得します。

```plaintext
GET /groups/:id/badges/render
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `link_url` | 文字列         | はい | バッジリンクのURL|
| `image_url` | 文字列 | はい | バッジ画像のURL |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/badges/render?link_url=http%3A%2F%2Fexample.com%2Fci_status.svg%3Fproject%3D%25%7Bproject_path%7D%26ref%3D%25%7Bdefault_branch%7D&image_url=https%3A%2F%2Fshields.io%2Fmy%2Fbadge"
```

レスポンス例: 

```json
{
  "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
  "rendered_image_url": "https://shields.io/my/badge"
}
```
