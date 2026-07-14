---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトバッジAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- CI/CDジョブトークンによる認証は、GitLab 19.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/326910)。

{{< /history >}}

このAPIを使用して、プロジェクトの[バッジ](../user/project/badges.md)を管理します。

バッジは、リンクと画像URLの両方でリアルタイムに置き換えられるプレースホルダーをサポートしています。次のプレースホルダーを使用できます:

- `%{project_path}`: プロジェクトパスに置き換えられます。
- `%{project_title}`: プロジェクトのタイトルに置き換えられます。
- `%{project_name}`: プロジェクト名に置き換えられます。
- `%{project_id}`: プロジェクトIDに置き換えられます。
- `%{project_namespace}`: プロジェクトのネームスペースのフルパスに置き換えられます。
- `%{group_name}`: プロジェクトのトップレベルグループ名に置き換えられます。
- `%{gitlab_server}`: プロジェクトのサーバー名に置き換えられます。
- `%{gitlab_pages_domain}`: GitLab Pagesをホストするドメイン名に置き換えられます。
- `%{default_branch}`: プロジェクトのデフォルトブランチに置き換えられます。
- `%{commit_sha}`: プロジェクトの最後のコミットSHAに置き換えられます。
- `%{latest_tag}`: プロジェクトの最後のタグに置き換えられます。

## プロジェクトのすべてのバッジを一覧表示 {#list-all-badges-of-a-project}

グループバッジを含む、プロジェクトのすべてのバッジを一覧表示します。

```plaintext
GET /projects/:id/badges
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`    | 文字列         | いいえ  | 返却するバッジの名前 (大文字と小文字を区別)。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges?name=Coverage"
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
    "kind": "project"
  },
  {
    "name": "Pipeline",
    "id": 2,
    "link_url": "http://example.com/ci_status.svg?project=%{project_path}&ref=%{default_branch}",
    "image_url": "https://shields.io/my/badge",
    "rendered_link_url": "http://example.com/ci_status.svg?project=example-org/example-project&ref=main",
    "rendered_image_url": "https://shields.io/my/badge",
    "kind": "group"
  }
]
```

## プロジェクトのバッジを取得する {#retrieve-a-badge-of-a-project}

プロジェクトのバッジを取得する。

```plaintext
GET /projects/:id/badges/:badge_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `badge_id` | 整数 | はい   | バッジID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges/:badge_id"
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
  "kind": "project"
}
```

## プロジェクトにバッジを作成する {#create-a-badge-for-a-project}

プロジェクトにバッジを作成します。

```plaintext
POST /projects/:id/badges
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `link_url` | 文字列         | はい | バッジリンクのURL |
| `image_url` | 文字列 | はい | バッジ画像のURL |
| `name` | 文字列 | いいえ | バッジの名前 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "link_url=https://gitlab.com/gitlab-org/gitlab-foss/commits/main" \
  --form "image_url=https://shields.io/my/badge1" \
  --form "name=mybadge" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
  "image_url": "https://shields.io/my/badge1",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
  "rendered_image_url": "https://shields.io/my/badge1",
  "kind": "project"
}
```

## プロジェクトのバッジを更新する {#update-a-badge-of-a-project}

プロジェクトのバッジを更新します。

```plaintext
PUT /projects/:id/badges/:badge_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `badge_id` | 整数 | はい   | バッジID |
| `link_url` | 文字列         | いいえ | バッジリンクのURL |
| `image_url` | 文字列 | いいえ | バッジ画像のURL |
| `name` | 文字列 | いいえ | バッジの名前 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges/:badge_id"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "mybadge",
  "link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
  "image_url": "https://shields.io/my/badge",
  "rendered_link_url": "https://gitlab.com/gitlab-org/gitlab-foss/commits/main",
  "rendered_image_url": "https://shields.io/my/badge",
  "kind": "project"
}
```

## プロジェクトからバッジを削除する {#delete-a-badge-from-a-project}

プロジェクトからバッジを削除します。グループバッジを削除するには、代わりに[グループバッジAPI](group_badges.md)を使用します。

```plaintext
DELETE /projects/:id/badges/:badge_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `badge_id` | 整数 | はい   | バッジID |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges/:badge_id"
```

## プロジェクトからバッジをプレビュー {#preview-a-badge-from-a-project}

プレースホルダーの補間が解決された後、`link_url`と`image_url`の最終URLがどうなるかを返します。

```plaintext
GET /projects/:id/badges/render
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `link_url` | 文字列         | はい | バッジリンクのURL|
| `image_url` | 文字列 | はい | バッジ画像のURL |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/badges/render?link_url=http%3A%2F%2Fexample.com%2Fci_status.svg%3Fproject%3D%25%7Bproject_path%7D%26ref%3D%25%7Bdefault_branch%7D&image_url=https%3A%2F%2Fshields.io%2Fmy%2Fbadge"
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
