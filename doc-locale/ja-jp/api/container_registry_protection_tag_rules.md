---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
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

サポートされている属性: 

| 属性 | 型              | 必須 | 説明                                                                     |
|-----------|-------------------|----------|---------------------------------------------------------------------------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。      |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `id` | 整数 | 保護されたコンテナタグルールのID。 |
| `minimum_access_level_for_delete` | 文字列 | タグの削除に必要な最小アクセスレベル（`maintainer`、`owner`など）。 |
| `minimum_access_level_for_push` | 文字列 | タグへのプッシュに必要な最小アクセスレベル（`maintainer`、`owner`など）。 |
| `project_id` | 整数 | プロジェクトのID。 |
| `tag_name_pattern` | 文字列 | タグタグ名パターン（`v*-release`、`latest`など）。 |

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

## コンテナレジストリ保護タグルールを更新 {#update-a-container-registry-protection-tag-rule}

{{< history >}}

- GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/581199)。

{{< /history >}}

プロジェクトのコンテナレジストリ保護タグルールを更新します。

```plaintext
PATCH /api/v4/projects/:id/registry/protection/tag/rules/:protection_rule_id
```

サポートされている属性: 

| 属性 | 型 | 必須 | 説明 |
|-----------|------|----------|-------------|
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `protection_rule_id` | 整数 | はい | 更新する保護タグルールのID。 |
| `minimum_access_level_for_delete` | 文字列 | いいえ | コンテナタグの削除に必要な最小アクセスレベル。たとえば、`maintainer`、`owner`、`admin`などです。値を設定しない場合は、空の文字列（`""`）を使用します。 |
| `minimum_access_level_for_push` | 文字列 | いいえ | コンテナタグのプッシュに必要な最小アクセスレベル。例: `maintainer`、`owner`、`admin`。値を設定しない場合は、空の文字列（`""`）を使用します。 |
| `tag_name_pattern` | 文字列 | いいえ | 保護ルールによって保護されているコンテナタグタグ名パターン。例: `v*-release`。ワイルドカード文字`*`を使用できます。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。保護タグルールを更新できなかった場合は、`422 Unprocessable Entity`を返します。たとえば、`tag_name_pattern`コードがすでに使用されている場合などです。

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
