---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 保護タグAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[保護タグ](../user/project/protected_tags.md)を管理します。

## 有効なアクセスレベル {#valid-access-levels}

以下のアクセスレベルが認識されます:

- `0`: アクセスなし
- `30`: デベロッパーロール
- `40`: メンテナーロール

## 保護タグをリストする {#list-protected-tags}

{{< history >}}

- デプロイキー情報がGitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846)されました。

{{< /history >}}

プロジェクトから[保護タグ](../user/project/protected_tags.md)のリストを取得します。この機能は、保護タグのリストを制限するためにページネーションパラメータ`page`と`per_page`を取ります。

```plaintext
GET /projects/:id/protected_tags
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明                                                                      |
|-----------|-------------------|----------|----------------------------------------------------------------------------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。       |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                                         | 型    | 説明 |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | 配列   | アクセスレベル設定の作成の配列。 |
| `create_access_levels[].access_level`             | 整数 | タグを作成するためのアクセスレベル。 |
| `create_access_levels[].access_level_description` | 文字列  | アクセスレベルの人間が読める説明。 |
| `create_access_levels[].deploy_key_id`            | 整数 | 作成アクセスレベルを持つデプロイキーのID。 |
| `create_access_levels[].group_id`                 | 整数 | 作成アクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `create_access_levels[].id`                       | 整数 | アクセスレベル設定作成のID。 |
| `create_access_levels[].user_id`                  | 整数 | 作成アクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |
| `name`                                            | 文字列  | 保護タグの名前。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags"
```

レスポンス例: 

```json
[
  {
    "name": "release-1-0",
    "create_access_levels": [
      {
        "id":1,
        "access_level": 40,
        "access_level_description": "Maintainers"
      },
      {
        "id": 2,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1
      }
    ]
  }
]
```

## 保護タグまたはワイルドカード保護タグを取得する {#get-a-protected-tag-or-wildcard-protected-tag}

単一の保護タグまたはワイルドカード保護タグを取得します。

```plaintext
GET /projects/:id/protected_tags/:name
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列            | はい      | タグまたはワイルドカードの名前。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                                         | 型    | 説明 |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | 配列   | アクセスレベル設定の作成の配列。 |
| `create_access_levels[].access_level`             | 整数 | タグを作成するためのアクセスレベル。 |
| `create_access_levels[].access_level_description` | 文字列  | アクセスレベルの人間が読める説明。 |
| `create_access_levels[].deploy_key_id`            | 整数 | 作成アクセスレベルを持つデプロイキーのID。 |
| `create_access_levels[].group_id`                 | 整数 | 作成アクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `create_access_levels[].id`                       | 整数 | アクセスレベル設定作成のID。 |
| `create_access_levels[].user_id`                  | 整数 | 作成アクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |
| `name`                                            | 文字列  | 保護タグの名前。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags/release-1-0"
```

レスポンス例: 

```json
{
  "name": "release-1-0",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ]
}
```

## リポジトリタグを保護する {#protect-a-repository-tag}

{{< history >}}

- `deploy_key_id`の設定はGitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166866)されました。
- `deploy_key_id`の設定は、GitLab 18.10でPremiumからFreeに[移動](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224542)されました。

{{< /history >}}

ワイルドカード保護タグを使用して、単一のリポジトリタグ、または複数のプロジェクトリポジトリタグを保護します。

```plaintext
POST /projects/:id/protected_tags
```

サポートされている属性は以下のとおりです: 

| 属性             | 型              | 必須 | 説明 |
|-----------------------|-------------------|----------|-------------|
| `id`                  | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`                | 文字列            | はい      | タグまたはワイルドカードの名前。 |
| `allowed_to_create`   | 配列             | いいえ       | タグの作成を許可されるアクセスレベルの配列。それぞれ`{user_id: integer}`、`{group_id: integer}`、`{deploy_key_id: integer}`、または`{access_level: integer}`のハッシュの形式で記述されます。`user_id`、`group_id`、および`access_level`はPremiumおよびUltimateのみです。 |
| `create_access_level` | 整数           | いいえ       | 作成を許可されるアクセスレベル。デフォルトは`40` (メンテナーロール) です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                                         | 型    | 説明 |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | 配列   | アクセスレベル設定の作成の配列。 |
| `create_access_levels[].access_level`             | 整数 | タグを作成するためのアクセスレベル。 |
| `create_access_levels[].access_level_description` | 文字列  | アクセスレベルの人間が読める説明。 |
| `create_access_levels[].deploy_key_id`            | 整数 | 作成アクセスレベルを持つデプロイキーのID。 |
| `create_access_levels[].group_id`                 | 整数 | 作成アクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `create_access_levels[].id`                       | 整数 | アクセスレベル設定作成のID。 |
| `create_access_levels[].user_id`                  | 整数 | 作成アクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |
| `name`                                            | 文字列  | 保護タグの名前。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags" \
  --data '{
   "allowed_to_create" : [
      {
         "user_id" : 1
      },
      {
         "access_level" : 30
      }
   ],
   "create_access_level" : 30,
   "name" : "*-stable"
}'
```

レスポンス例: 

```json
{
  "name": "*-stable",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ]
}
```

### ユーザーとグループアクセスレベルの例 {#example-with-user-and-group-access}

`allowed_to_create`配列の要素は、`{user_id: integer}`、`{group_id: integer}`、`{deploy_key_id: integer}`、または`{access_level: integer}`の形式である必要があります。各ユーザーはプロジェクトへのアクセス権を持ち、各グループは[このプロジェクトを共有している](../user/project/members/sharing_projects_groups.md)必要があります。これらのアクセスレベルにより、保護タグアクセスをより詳細に制御できます。詳細については、[保護タグにグループを追加](../user/project/protected_tags.md#add-a-group-to-protected-tags)を参照してください。

このリクエストの例は、特定のユーザーとグループに作成アクセスを許可する保護タグを作成する方法を示しています:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags" \
  --data "name=*-stable" \
  --data "allowed_to_create[][user_id]=10" \
  --data "allowed_to_create[][group_id]=20"
```

この応答の例には以下が含まれます:

- `"*-stable"`という名前の保護タグ。
- ID `10`を持つユーザーのID `1`を持つ`create_access_levels`。
- ID `20`を持つグループのID `2`を持つ`create_access_levels`。

```json
{
  "name": "*-stable",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": null,
      "user_id": 10,
      "group_id": null,
      "access_level_description": "Administrator"
    },
    {
      "id": 2,
      "access_level": null,
      "user_id": null,
      "group_id": 20,
      "access_level_description": "Example Create Group"
    }
  ]
}
```

## リポジトリタグの保護を解除する {#unprotect-repository-tags}

指定された保護タグまたはワイルドカード保護タグの保護を解除します。

```plaintext
DELETE /projects/:id/protected_tags/:name
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列            | はい      | タグの名前。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags/*-stable"
```

## 関連トピック {#related-topics}

- すべてのタグの[タグAPI](tags.md)
- [タグ](../user/project/repository/tags/_index.md)ユーザードキュメント
- [保護タグ](../user/project/protected_tags.md)ユーザードキュメント
