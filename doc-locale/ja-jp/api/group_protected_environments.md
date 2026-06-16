---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループレベルの保護環境API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/215888)されたGitLab 14.0。[`group_level_protected_environments`機能フラグの背後でデプロイされ、デフォルトでは無効になっています。](../administration/feature_flags/_index.md)
- [機能フラグ`group_level_protected_environments`](https://gitlab.com/gitlab-org/gitlab/-/issues/331085)はGitLab 14.3で削除されました。
- [一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/331085)がGitLab 14.3で開始されました。

{{< /history >}}

このAPIを使用して、[グループレベルの保護環境](../ci/environments/protected_environments.md#group-level-protected-environments)を操作します。

> [!note]
> 保護環境については、[保護環境API](protected_environments.md)を参照してください。

## 有効なアクセスレベル {#valid-access-levels}

アクセスレベルは、`ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS`メソッドで定義されています。現在、これらのレベルが認識されます:

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## すべてのグループレベルの保護環境をリスト表示 {#list-all-group-level-protected-environments}

指定されたグループのすべての保護環境をリスト表示します。

```plaintext
GET /groups/:id/protected_environments
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 認証済みユーザーによってメンテナーされているグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_environments/"
```

レスポンス例: 

```json
[
   {
      "name":"production",
      "deploy_access_levels":[
         {
            "id": 12,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
         }
      ],
      "required_approval_count": 0
   }
]
```

## 単一の保護環境を取得 {#retrieve-a-single-protected-environment}

グループから指定された保護環境を取得します。

```plaintext
GET /groups/:id/protected_environments/:name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 認証済みユーザーによってメンテナーされているグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列 | はい    | 保護環境の[デプロイ階層](../ci/environments/_index.md#deployment-tier-of-environments)。指定可能な値: `production`、`staging`、`testing`、`development`、または`other`。|

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_environments/production"
```

レスポンス例: 

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level":40,
         "access_level_description":"Maintainers",
         "user_id":null,
         "group_id":null
      }
   ],
   "required_approval_count": 0
}
```

## 単一の環境を保護する {#protect-a-single-environment}

単一の環境を保護します。

```plaintext
POST /groups/:id/protected_environments
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | 認証済みユーザーによってメンテナーされているグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列 | はい    | 保護環境の[デプロイ階層](../ci/environments/_index.md#deployment-tier-of-environments)。指定可能な値: `production`、`staging`、`testing`、`development`、または`other`。|
| `deploy_access_levels`          | 配列          | はい | デプロイを許可するアクセスレベルの配列。ハッシュでそれぞれ記述されます。指定可能な値: `user_id`、`group_id`、または`access_level`。これらは`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式を取ります。 |
| `approval_rules`                | 配列          | いいえ  | 承認を許可するアクセスレベルの配列。ハッシュでそれぞれ記述されます。指定可能な値: `user_id`、`group_id`、または`access_level`。これらは`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式を取ります。指定されたエンティティからの必要な承認の数を`required_approvals`フィールドで指定することもできます。詳細については、[複数の承認ルール](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)を参照してください。 |

割り当て可能な`user_id`は、メンテナーロール（またはそれ以上）で指定されたグループに属するユーザーです。割り当て可能な`group_id`は、指定されたグループの下にあるサブグループです。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments" \
  --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}]}'
```

レスポンス例: 

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899826
      }
   ],
   "required_approval_count": 0
}
```

複数の承認ルールの例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/128/protected_environments" \
  --data '{
    "name": "production",
    "deploy_access_levels": [{"group_id": 138}],
    "approval_rules": [
      {"group_id": 134},
      {"group_id": 135, "required_approvals": 2}
    ]
  }'
```

この設定では、オペレーターグループ`"group_id": 138`は、QAグループ`"group_id": 134`とセキュリティグループ`"group_id": 135`がデプロイを承認した後にのみ、`production`へのデプロイジョブを実行できます。

## 保護環境を更新する {#update-a-protected-environment}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/351854)されました。

{{< /history >}}

単一の環境を更新します。

```plaintext
PUT /groups/:id/protected_environments/:name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | 認証済みユーザーによってメンテナーされているグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列 | はい    | 保護環境の[デプロイ階層](../ci/environments/_index.md#deployment-tier-of-environments)。指定可能な値: `production`、`staging`、`testing`、`development`、または`other`。|
| `deploy_access_levels`          | 配列          | いいえ | デプロイを許可するアクセスレベルの配列。ハッシュでそれぞれ記述されます。指定可能な値: `user_id`、`group_id`、または`access_level`。これらは`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式を取ります。 |
| `required_approval_count` | 整数        | いいえ       | この環境にデプロイするために必要な承認の数。 |
| `approval_rules`                | 配列          | いいえ  | 承認を許可するアクセスレベルの配列。ハッシュでそれぞれ記述されます。指定可能な値: `user_id`、`group_id`、または`access_level`。これらは`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式を取ります。指定されたエンティティからの必要な承認の数を`required_approvals`フィールドで指定することもできます。詳細については、[複数の承認ルール](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)を参照してください。 |

更新する場合:

- **`user_id`**: 更新されたユーザーが、メンテナーロール（またはそれ以上）で指定されたグループに属していることを確認してください。また、それぞれのハッシュで`deploy_access_level`または`approval_rule`の`id`を渡す必要があります。
- **`group_id`**: 更新されたグループが、この保護環境が属するグループのサブグループであることを確認してください。また、それぞれのハッシュで`deploy_access_level`または`approval_rule`の`id`を渡す必要があります。

削除する場合:

- `_destroy`を`true`に設定して渡す必要があります。次の例を参照してください。

### 例: `deploy_access_level`レコードを作成する {#example-create-a-deploy_access_level-record}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"deploy_access_levels": [{"group_id": 9899829, "access_level": 40}]}'
```

レスポンス例: 

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899829,
         "group_inheritance_type": 1
      }
   ],
   "required_approval_count": 0
}
```

### 例: `deploy_access_level`レコードを更新する {#example-update-a-deploy_access_level-record}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"deploy_access_levels": [{"id": 12, "group_id": 22034120}]}'
```

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 22034120,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 2
}
```

### 例: `deploy_access_level`レコードを削除する {#example-delete-a-deploy_access_level-record}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"deploy_access_levels": [{"id": 12, "_destroy": true}]}'
```

レスポンス例: 

```json
{
   "name": "production",
   "deploy_access_levels": [],
   "required_approval_count": 0
}
```

### 例: `approval_rule`レコードを作成する {#example-create-an-approval_rule-record}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"approval_rules": [{"group_id": 134, "required_approvals": 1}]}'
```

レスポンス例: 

```json
{
   "name": "production",
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 134,
         "access_level": null,
         "access_level_description": "qa-group",
         "required_approvals": 1,
         "group_inheritance_type": 0
      }
   ]
}
```

### 例: `approval_rule`レコードを更新する {#example-update-an-approval_rule-record}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"approval_rules": [{"id": 38, "group_id": 135, "required_approvals": 2}]}'
```

```json
{
   "name": "production",
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 135,
         "access_level": null,
         "access_level_description": "security-group",
         "required_approvals": 2,
         "group_inheritance_type": 0
      }
   ]
}
```

### 例: `approval_rule`レコードを削除する {#example-delete-an-approval_rule-record}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"approval_rules": [{"id": 38, "_destroy": true}]}'
```

レスポンス例: 

```json
{
   "name": "production",
   "approval_rules": []
}
```

## 単一の環境の保護を解除する {#unprotect-a-single-environment}

指定された保護環境の保護を解除します。

```plaintext
DELETE /groups/:id/protected_environments/:name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 認証済みユーザーによってメンテナーされているグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列 | はい    | 保護環境の[デプロイ階層](../ci/environments/_index.md#deployment-tier-of-environments)。指定可能な値: `production`、`staging`、`testing`、`development`、または`other`。|

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_environments/staging"
```

レスポンスは200コードを返すはずです。
