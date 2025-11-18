---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループバッジAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、グループバッジを操作します。詳細については、[グループ](../user/project/badges.md#group-badges)を参照してください。

## 補間トークン {#placeholder-tokens}

[バッジ](../user/project/badges.md)は、リンクとイメージURLの両方でリアルタイムに置き換えられる補間をサポートしています。使用できる補間は次のとおりです:

<!-- vale gitlab_base.Spelling = NO -->

- **%{project_path}**: プロジェクトのパスに置き換えられます。
- **%{project_title}**: プロジェクトのタイトルに置き換えられます。
- **%{project_name}**: プロジェクト名に置き換えられます。
- **%{project_id}**: プロジェクトIDに置き換えられます。
- **%{project_namespace}**: プロジェクトのネームスペースのフルパスに置き換えられます。
- **%{group_name}**: プロジェクトのトップレベルグループ名に置き換えられます。
- **%{gitlab_server}**: プロジェクトのサーバー名に置き換えられます。
- **%{gitlab_pages_domain}**: GitLab Pagesをホストするドメイン名に置き換えられます。
- **%{default_branch}**: プロジェクトのデフォルトのブランチに置き換えられます。
- **%{commit_sha}**: プロジェクトの最後のコミットSHAに置き換えられます。
- **%{latest_tag}**: プロジェクトの最後のタグに置き換えられます。

<!-- vale gitlab_base.Spelling = YES -->

これらのエンドポイントはプロジェクトのコンテキスト内にないため、補間を置き換えるために使用される情報は、作成日順で最初のグループのプロジェクトから取得されます。グループにプロジェクトがない場合は、補間を含む元のURLが返されます。

## グループのすべてのバッジをリスト表示 {#list-all-badges-of-a-group}

グループのバッジのリストを取得します。

```plaintext
GET /groups/:id/badges
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`    | 文字列         | いいえ  | 返すバッジの名前（大文字と小文字を区別）。 |

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

## グループのバッジを取得 {#get-a-badge-of-a-group}

グループのバッジを取得します。

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

## グループにバッジを追加 {#add-a-badge-to-a-group}

グループにバッジを追加します。

```plaintext
POST /groups/:id/badges
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `link_url` | 文字列         | はい | バッジリンクのURL |
| `image_url` | 文字列 | はい | バッジイメージのURL |
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

## グループのバッジを編集 {#edit-a-badge-of-a-group}

グループのバッジを更新します。

```plaintext
PUT /groups/:id/badges/:badge_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `badge_id` | 整数 | はい   | バッジID |
| `link_url` | 文字列         | いいえ | バッジリンクのURL |
| `image_url` | 文字列 | いいえ | バッジイメージのURL |
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

## グループからバッジを削除 {#remove-a-badge-from-a-group}

グループからバッジを削除します。

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

## グループからバッジをプレビュー {#preview-a-badge-from-a-group}

`link_url`と`image_url`の最終的なURLが、補間を解決するとどうなるかを返します。

```plaintext
GET /groups/:id/badges/render
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `link_url` | 文字列         | はい | バッジリンクのURL|
| `image_url` | 文字列 | はい | バッジイメージのURL |

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
