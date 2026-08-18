---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループレベルの保護ブランチAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/500250)になりました。機能フラグ`group_protected_branches`は削除されました。

{{< /history >}}

このAPIを使用して、グループ内のすべてのプロジェクトに継承される[保護ブランチの設定](../user/project/repository/branches/protected.md#in-a-group)を管理します。グループの保護ブランチは、[有効なアクセスレベル](#valid-access-levels)のみをサポートします。個々のユーザーとグループは指定できません。

> [!warning]
> 保護ブランチの設定は、トップレベルグループにのみ限定されます。

## 有効なアクセスレベル {#valid-access-levels}

アクセスレベルは、`ProtectedRefAccess.allowed_access_levels`メソッドで定義されています。これらのレベルは認識されます:

```plaintext
0  => No access
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## 保護ブランチをリスト表示 {#list-protected-branches}

グループから保護ブランチのリストを取得します。ワイルドカードが設定されている場合、そのワイルドカードに一致するブランチの正確な名前ではなく、ワイルドカードが返されます。

```plaintext
GET /groups/:id/protected_branches
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search` | 文字列 | いいえ | 検索対象となる保護ブランチの名前またはその一部。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  {
    "id": 1,
    "name": "release/*",
    "push_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  ...
]
```

## 単一の保護ブランチまたはワイルドカード保護ブランチを取得 {#get-a-single-protected-branch-or-wildcard-protected-branch}

単一の保護ブランチまたはワイルドカード保護ブランチを取得します。

```plaintext
GET /groups/:id/protected_branches/:name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name` | 文字列 | はい | ブランチまたはワイルドカードの名前。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/main"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

## リポジトリブランチを保護 {#protect-repository-branches}

ワイルドカード保護ブランチを使用して、単一のリポジトリブランチを保護します。

```plaintext
POST /groups/:id/protected_branches
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches?name=*-stable&push_access_level=30&merge_access_level=30&unprotect_access_level=40"
```

| 属性                                    | 型 | 必須 | 説明 |
| -------------------------------------------- | ---- | -------- | ----------- |
| `id`                                         | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`                                       | 文字列         | はい | ブランチまたはワイルドカードの名前。 |
| `allow_force_push`                           | ブール値        | いいえ  | プッシュアクセス権を持つすべてのユーザーが強制プッシュできるようにします。デフォルト: `false`。 |
| `allowed_to_merge`                           | 配列          | いいえ  | マージが許可されるアクセスレベルの配列。それぞれ`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されます。 |
| `allowed_to_push`                            | 配列          | いいえ  | プッシュが許可されるアクセスレベルの配列。それぞれ`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されます。 |
| `allowed_to_unprotect`                       | 配列          | いいえ  | 保護解除が許可されるアクセスレベルの配列。それぞれ`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されます。 |
| `code_owner_approval_required`               | ブール値        | いいえ  | [`CODEOWNERS`ファイル](../user/project/codeowners/_index.md)内の項目に一致する場合、このブランチへのプッシュを禁止します。デフォルト: `false`。 |
| `merge_access_level`                         | 整数        | いいえ  | マージが許可されるアクセスレベル。デフォルト: `40`、メンテナーロール。 |
| `push_access_level`                          | 整数        | いいえ  | プッシュが許可されるアクセスレベル。デフォルト: `40`、メンテナーロール。 |
| `unprotect_access_level`                     | 整数        | いいえ  | 保護解除が許可されるアクセスレベル。デフォルト: `40`、メンテナーロール。 |

レスポンス例: 

```json
{
  "id": 1,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  1,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### アクセスレベルの例 {#example-with-access-levels}

アクセスレベルを使用して、グループの保護ブランチを構成します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_push": [{"access_level": 30}],
    "allowed_to_merge": [{
        "access_level": 30
      },{
        "access_level": 40
      }
    ]}'
    --url "https://gitlab.example.com/api/v4/groups/5/protected_branches"
```

レスポンス例: 

```json
{
    "id": 5,
    "name": "main",
    "push_access_levels": [
        {
            "id": 1,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "merge_access_levels": [
        {
            "id": 1,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        },
        {
            "id": 2,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "unprotect_access_levels": [
        {
            "id": 1,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
}
```

## リポジトリブランチの保護を解除 {#unprotect-repository-branches}

指定された保護ブランチまたはワイルドカード保護ブランチの保護を解除します。

```plaintext
DELETE /groups/:id/protected_branches/:name
```

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/*-stable"
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name` | 文字列 | はい | ブランチの名前 |

レスポンス例: 

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

## 保護ブランチを更新 {#update-a-protected-branch}

保護ブランチを更新します。

```plaintext
PATCH /groups/:id/protected_branches/:name
```

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/feature-branch?allow_force_push=true&code_owner_approval_required=true"
```

| 属性                                    | 型           | 必須 | 説明                                                                                                                          |
| -------------------------------------------- | ---- | -------- | ----------- |
| `id`                                         | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                       |
| `name`                                       | 文字列         | はい      | ブランチの名前                                                                                                               |
| `allow_force_push`                           | ブール値        | いいえ       | 有効にすると、このブランチにプッシュできるメンバーも強制プッシュできます。                                                               |
| `allowed_to_push`                            | 配列          | いいえ       | プッシュアクセスレベルの配列。それぞれハッシュで記述されます。                                                                          |
| `allowed_to_merge`                           | 配列          | いいえ       | マージアクセスレベルの配列。それぞれハッシュで記述されます。                                                                         |
| `allowed_to_unprotect`                       | 配列          | いいえ       | 保護解除アクセスレベルの配列。それぞれハッシュで記述されます。                                                                     |
| `code_owner_approval_required`               | ブール値        | いいえ       | [`CODEOWNERS`ファイル](../user/project/codeowners/_index.md)内の項目に一致する場合、このブランチへのプッシュを禁止します。デフォルト: `false`。 |

`allowed_to_push`、`allowed_to_merge`、および`allowed_to_unprotect`配列内の要素は、`{access_level: integer}`の形式を取る必要があります。各アクセスレベルは、[有効なアクセスレベル](#valid-access-levels)から有効な値である必要があります。

- アクセスレベルを更新するには、それぞれのハッシュで`access_level`の`id`も渡す必要があります。
- アクセスレベルを削除するには、`_destroy`を`true`に設定して渡す必要があります。次の例を参照してください。

### 例: `push_access_level`レコードを作成 {#example-create-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{access_level: 40}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
```

レスポンス例: 

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### 例: `push_access_level`レコードを更新 {#example-update-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "access_level": 0}]' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
```

レスポンス例: 

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 0,
         "access_level_description": "No One",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### 例: `push_access_level`レコードを削除 {#example-delete-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "_destroy": true}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
```

レスポンス例: 

```json
{
   "name": "main",
   "push_access_levels": []
}
```
