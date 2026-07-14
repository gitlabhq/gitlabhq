---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabのコンテナレジストリ保護タグルールのREST APIのドキュメント。
title: コンテナレジストリ保護タグルールAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/581199)されました。

{{< /history >}}

このAPIを使用して、[保護されたコンテナタグ](../user/packages/container_registry/protected_container_tags.md)を管理します。

## コンテナレジストリ保護タグルールの一覧表示 {#list-container-registry-protection-tag-rules}

プロジェクトのコンテナレジストリ保護タグルールの一覧を取得します。

```plaintext
GET /api/v4/projects/:id/registry/protection/tag/rules
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明                                                                     |
|-----------|-------------------|----------|---------------------------------------------------------------------------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。      |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `id` | 整数 | 保護されたコンテナタグルールのID。 |
| `minimum_access_level_for_delete` | 文字列 | タグを削除するために必要な最小アクセスレベル。指定可能な値: `maintainer`、`owner`、または`admin`。 |
| `minimum_access_level_for_push` | 文字列 | タグにプッシュするために必要な最小アクセスレベル。指定可能な値: `maintainer`、`owner`、または`admin`。 |
| `project_id` | 整数 | プロジェクトのID。 |
| `tag_name_pattern` | 文字列 | タグ名のパターン。例: `v*-release`、`latest`。 |

次のステータスコードを返すことができます。

- `200 OK`: 保護ルールの一覧。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: ユーザーには、このプロジェクトの保護ルールを一覧表示する権限がありません。
- `404 Not Found`: プロジェクトが見つかりませんでした。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "project_id": 7,
    "tag_name_pattern": "v*-release",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  },
  {
    "id": 2,
    "project_id": 7,
    "tag_name_pattern": "latest",
    "minimum_access_level_for_push": "owner",
    "minimum_access_level_for_delete": "owner"
  }
]
```

## コンテナレジストリ保護タグルールを作成 {#create-a-container-registry-protection-tag-rule}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/581199)されました。

{{< /history >}}

プロジェクトのコンテナレジストリ保護タグルールを作成します。

```plaintext
POST /api/v4/projects/:id/registry/protection/tag/rules
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `tag_name_pattern` | 文字列 | はい | 保護ルールによって保護されているコンテナタグ名パターン。たとえば`v*-release`などです。ワイルドカード文字`*`を使用できます。 |
| `minimum_access_level_for_push` | 文字列 | はい | コンテナタグをプッシュするために必要な最小GitLabアクセスレベル。指定可能な値: `maintainer`、`owner`、または`admin`。 |
| `minimum_access_level_for_delete` | 文字列 | はい | コンテナタグを削除するために必要な最小GitLabアクセスレベル。指定可能な値: `maintainer`、`owner`、または`admin`。 |

成功した場合は、[`201 Created`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `id` | 整数 | コンテナタグルールの固有識別子。 |
| `project_id` | 整数 | このコンテナタグルールが属するプロジェクトのID。 |
| `tag_name_pattern` | 文字列 | コンテナタグ名を照合するために使用されるglobパターン。たとえば`v*-release`などです。 |
| `minimum_access_level_for_push` | 文字列 | このパターンに一致するコンテナタグをプッシュするために必要な最小アクセスレベル。指定可能な値: `maintainer`、`owner`、または`admin`。 |
| `minimum_access_level_for_delete` | 文字列 | このパターンに一致するコンテナタグを削除するために必要な最小アクセスレベル。指定可能な値: `maintainer`、`owner`、または`admin`。 |

次のステータスコードを返すことができます。

- `201 Created`: 保護ルールが正常に作成されました。
- `400 Bad Request`: 保護ルールが無効です。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: ユーザーには、保護ルールを作成する権限がありません。
- `404 Not Found`: プロジェクトが見つかりませんでした。
- `422 Unprocessable Entity`: 保護ルールを作成できませんでした。たとえば、`tag_name_pattern`コードがすでに使用されている場合などです。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules" \
  --data '{
        "tag_name_pattern": "v*-release",
        "minimum_access_level_for_push": "maintainer",
        "minimum_access_level_for_delete": "maintainer"
    }'
```

レスポンス例: 

```json
{
  "id": 1,
  "project_id": 7,
  "tag_name_pattern": "v*-release",
  "minimum_access_level_for_push": "maintainer",
  "minimum_access_level_for_delete": "maintainer"
}
```

## コンテナレジストリ保護タグルールの更新 {#update-a-container-registry-protection-tag-rule}

{{< history >}}

- GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/581199)されました。

{{< /history >}}

プロジェクトのコンテナレジストリ保護タグルールを更新します。

```plaintext
PATCH /api/v4/projects/:id/registry/protection/tag/rules/:protection_rule_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `protection_rule_id` | 整数 | はい | 更新する保護タグルールのID。 |
| `minimum_access_level_for_delete` | 文字列 | いいえ | コンテナタグの削除に必要な最小アクセスレベル。指定可能な値: `maintainer`、`owner`、または`admin`。値を設定しない場合は、空の文字列（`""`）を使用します。 |
| `minimum_access_level_for_push` | 文字列 | いいえ | コンテナタグのプッシュに必要な最小アクセスレベル。指定可能な値: `maintainer`、`owner`、または`admin`。値を設定しない場合は、空の文字列（`""`）を使用します。 |
| `tag_name_pattern` | 文字列 | いいえ | 保護ルールによって保護されているコンテナタグ名パターン。たとえば`v*-release`などです。ワイルドカード文字`*`を使用できます。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `id` | 整数 | コンテナタグルールの固有識別子。 |
| `project_id` | 整数 | このコンテナタグルールが属するプロジェクトのID。 |
| `tag_name_pattern` | 文字列 | コンテナタグ名を照合するために使用されるglobパターン。たとえば`v*-release`などです。 |
| `minimum_access_level_for_push` | 文字列 | このパターンに一致するコンテナタグをプッシュするために必要な最小アクセスレベル。指定可能な値: `maintainer`、`owner`、または`admin`。 |
| `minimum_access_level_for_delete` | 文字列 | このパターンに一致するコンテナタグを削除するために必要な最小アクセスレベル。指定可能な値: `maintainer`、`owner`、または`admin`。 |

次のステータスコードを返すことができます。

- `200 OK`: 保護ルールが正常に更新されました。
- `400 Bad Request`: 保護ルールが無効です。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: ユーザーには、保護ルールを更新する権限がありません。
- `404 Not Found`: プロジェクトが見つかりませんでした。
- `422 Unprocessable Entity`: 保護ルールを更新できませんでした。たとえば、`tag_name_pattern`コードがすでに使用されている場合などです。

リクエスト例:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules/1" \
  --data '{
       "tag_name_pattern": "v*-stable"
    }'
```

レスポンス例: 

```json
{
  "id": 1,
  "project_id": 7,
  "tag_name_pattern": "v*-stable",
  "minimum_access_level_for_push": "maintainer",
  "minimum_access_level_for_delete": "maintainer"
}
```

## コンテナレジストリ保護タグルールを削除 {#delete-a-container-registry-protection-tag-rule}

{{< history >}}

- GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/581199)されました。

{{< /history >}}

プロジェクトからコンテナレジストリの保護タグルールを削除します。

```plaintext
DELETE /api/v4/projects/:id/registry/protection/tag/rules/:protection_rule_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `protection_rule_id` | 整数 | はい | 削除するコンテナレジストリ保護タグルールのID。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

次のステータスコードを返すことができます。

- `204 No Content`: 保護ルールが正常に削除されました。
- `400 Bad Request`: `id`または`protection_rule_id`が欠落しているか、無効です。
- `401 Unauthorized`: アクセストークンが無効です。
- `403 Forbidden`: ユーザーには、保護ルールを削除する権限がありません。
- `404 Not Found`: プロジェクトまたは保護ルールが見つかりませんでした。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules/1"
```
