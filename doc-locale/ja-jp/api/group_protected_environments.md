---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループレベルの保護環境API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/215888) GitLab 14.0。[`group_level_protected_environments`フラグの背後にデプロイされました](../administration/feature_flags/_index.md)。デフォルトでは無効になっています。
- GitLab 14.3で[機能フラグ`group_level_protected_environments`](https://gitlab.com/gitlab-org/gitlab/-/issues/331085)は削除されました。
- [一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/331085)はGitLab 14.3で行われました。

{{< /history >}}

このAPIを使用して、[グループレベルの保護環境](../ci/environments/protected_environments.md#group-level-protected-environments)とやり取りします。

{{< alert type="note" >}}

保護環境については、[保護環境API](protected_environments.md)を参照してください

{{< /alert >}}

## 有効なアクセスレベル {#valid-access-levels}

アクセスレベルは、`ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS`メソッドで定義されています。現在、これらのレベルが認識されています:

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## グループレベルの保護環境の一覧 {#list-group-level-protected-environments}

グループから保護環境のリストを取得します。

```plaintext
GET /groups/:id/protected_environments
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 認証済みユーザーが管理するグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

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

## 単一の保護環境を取得します {#get-a-single-protected-environment}

単一の保護環境を取得します。

```plaintext
GET /groups/:id/protected_environments/:name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 認証済みユーザーが管理するグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列 | はい    | 保護環境のデプロイ階層。`production`、`staging`、`testing`、`development`、`other`のいずれか[デプロイ階層](../ci/environments/_index.md#deployment-tier-of-environments)の詳細についてお読みください。|

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
| `id`      | 整数または文字列 | はい | 認証済みユーザーが管理するグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列 | はい    | 保護環境のデプロイ階層。`production`、`staging`、`testing`、`development`、`other`のいずれか[デプロイ階層](../ci/environments/_index.md#deployment-tier-of-environments)の詳細についてお読みください。|
| `deploy_access_levels`          | 配列          | はい | 各ハッシュで記述された、デプロイを許可されたアクセスレベルの配列。`user_id`、`group_id`、または`access_level`のいずれか。それらは、`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式をとります。 |
| `approval_rules`                | 配列          | いいえ  | 各ハッシュで記述された、承認を許可されたアクセスレベルの配列。`user_id`、`group_id`、または`access_level`のいずれか。それらは、`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式をとります。指定されたエンティティからの必要な承認の数を`required_approvals`フィールドで指定することもできます。詳しくは、[複数の承認ルール](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)をご覧ください。 |

割り当て可能な`user_id`は、メンテナーロール以上の権限を持つ、特定のグループに所属するユーザーです。割り当て可能な`group_id`は、特定のグループのサブグループです。

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

この構成では、オペレーターグループ`"group_id": 138`は、品質保証グループ`"group_id": 134`とセキュリティグループ`"group_id": 135`がデプロイを承認した後にのみ、`production`へのデプロイメントジョブを実行できます。

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
| `id`      | 整数または文字列 | はい | 認証済みユーザーが管理するグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列 | はい    | 保護環境のデプロイ階層。`production`、`staging`、`testing`、`development`、`other`のいずれか[デプロイ階層](../ci/environments/_index.md#deployment-tier-of-environments)の詳細についてお読みください。|
| `deploy_access_levels`          | 配列          | いいえ | 各ハッシュで記述された、デプロイを許可されたアクセスレベルの配列。`user_id`、`group_id`、または`access_level`のいずれか。それらは、`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式をとります。 |
| `required_approval_count` | 整数        | いいえ       | この環境にデプロイするために必要な承認の数。 |
| `approval_rules`                | 配列          | いいえ  | 各ハッシュで記述された、承認を許可されたアクセスレベルの配列。`user_id`、`group_id`、または`access_level`のいずれか。それらは、`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式をとります。指定されたエンティティからの必要な承認の数を`required_approvals`フィールドで指定することもできます。詳しくは、[複数の承認ルール](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)をご覧ください。 |

更新するには:

- **`user_id`**: 更新されたユーザーが、メンテナーロール以上の権限を持つ、特定のグループに所属していることを確認してください。それぞれのハッシュで、`deploy_access_level`または`approval_rule`の`id`も渡す必要があります。
- **`group_id`**: 更新されたグループが、この保護環境が所属するグループのサブグループであることを確認します。それぞれのハッシュで、`deploy_access_level`または`approval_rule`の`id`も渡す必要があります。

削除するには:

- `_destroy``true`に設定して渡す必要があります。次の例を参照してください。

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

特定の保護環境の保護を解除します。

```plaintext
DELETE /groups/:id/protected_environments/:name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 認証済みユーザーが管理するグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列 | はい    | 保護環境のデプロイ階層。`production`、`staging`、`testing`、`development`、`other`のいずれか[デプロイ階層](../ci/environments/_index.md#deployment-tier-of-environments)の詳細についてお読みください。|

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_environments/staging"
```

応答は200コードを返す必要があります。
