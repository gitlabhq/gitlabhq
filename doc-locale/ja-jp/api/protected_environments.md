---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 保護環境API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[保護環境](../ci/environments/protected_environments.md)とやり取りします。

{{< alert type="note" >}}

グループレベルの[group-level protected environments API](group_protected_environments.md)については、こちらを参照してください

{{< /alert >}}

## 有効なアクセスレベル {#valid-access-levels}

アクセスレベルは、`ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS`メソッドで定義されています。現在、次のレベルが認識されています:

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## グループメンバーシップの継承の種類 {#group-inheritance-types}

グループメンバーシップの継承により、デプロイアクセスレベルと承認ルールは、継承されたグループメンバーシップを考慮に入れることができます。グループメンバーシップの継承の種類は、`ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE`で定義されます。次の種類が認識されます:

```plaintext
0 => Direct group membership only (default)
1 => All inherited groups
```

## 保護された環境の一覧 {#list-protected-environments}

プロジェクトから保護環境の一覧を取得します:

```plaintext
GET /projects/:id/protected_environments
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_environments/"
```

レスポンス例:

```json
[
   {
      "name":"production",
      "deploy_access_levels":[
         {
            "id": 12,
            "access_level":40,
            "access_level_description":"Maintainers",
            "user_id":null,
            "group_id":null,
            "group_inheritance_type": 0
         }
      ],
      "required_approval_count": 0
   }
]
```

## 単一の保護環境を取得 {#get-a-single-protected-environment}

単一の保護環境を取得します:

```plaintext
GET /projects/:id/protected_environments/:name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name` | 文字列 | はい | 保護環境の名前 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_environments/production"
```

レスポンス例:

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 0
}
```

## 単一の環境を保護 {#protect-a-single-environment}

単一の環境を保護します:

```plaintext
POST /projects/:id/protected_environments
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                            | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`                          | 文字列         | はい | 環境の名前。 |
| `deploy_access_levels`          | 配列          | はい | デプロイを許可されたアクセスレベルの配列。それぞれはハッシュで記述されます。 |
| `approval_rules`                | 配列          | いいえ  | 承認を許可されたアクセスレベルの配列。それぞれはハッシュで記述されます。[複数の承認ルール](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)を参照してください。 |

`deploy_access_levels`および`approval_rules`配列内の要素は、`user_id`、`group_id`、または`access_level`のいずれかで、形式は`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`になります。オプションで、[有効なグループメンバーシップの継承タイプ](#group-inheritance-types)のいずれかとして、各`group_inheritance_type`を指定できます。

各ユーザーはプロジェクトへのアクセス権を持ち、各グループは[このプロジェクトを共有](../user/project/members/sharing_projects_groups.md)する必要があります。

```shell
curl --header 'Content-Type: application/json' \
     --request POST \
     --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}], "approval_rules": [{"group_id": 134}, {"group_id": 135, "required_approvals": 2}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments"
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
         "group_id": 9899826,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 0,
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 134,
         "access_level": null,
         "access_level_description": "qa-group",
         "required_approvals": 1,
         "group_inheritance_type": 0
      },
      {
         "id": 39,
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

## 保護環境を更新 {#update-a-protected-environment}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/351854)されました。

{{< /history >}}

単一の環境を更新します。

```plaintext
PUT /projects/:id/protected_environments/:name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`                            | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`                          | 文字列         | はい | 環境の名前。 |
| `deploy_access_levels`          | 配列          | いいえ  | デプロイを許可されたアクセスレベルの配列。それぞれはハッシュで記述されます。 |
| `approval_rules`                | 配列          | いいえ  | 承認を許可されたアクセスレベルの配列。それぞれはハッシュで記述されます。詳細については、[複数の承認ルール](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)を参照してください。 |

`deploy_access_levels`および`approval_rules`配列内の要素は、`user_id`、`group_id`、または`access_level`のいずれかで、形式は`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`になります。オプションで、[有効なグループメンバーシップの継承タイプ](#group-inheritance-types)のいずれかとして、各`group_inheritance_type`を指定できます。

更新するには:

- **`user_id`**: 更新されたユーザーがプロジェクトへのアクセス権を持っていることを確認します。それぞれのハッシュで、`deploy_access_level`デプロイアクセスレベルまたは`approval_rule`承認ルールの`id`も渡す必要があります。
- **`group_id`**: 更新されたグループが[このプロジェクトを共有](../user/project/members/sharing_projects_groups.md)していることを確認します。それぞれのハッシュで、`deploy_access_level`デプロイアクセスレベルまたは`approval_rule`承認ルールの`id`も渡す必要があります。

削除するには:

- `_destroy`を`true`に設定して渡す必要があります。次の例を参照してください。

### 例: `deploy_access_level`デプロイアクセスレベルレコードを作成 {#example-create-a-deploy_access_level-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"deploy_access_levels": [{"group_id": 9899829, access_level: 40}]' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
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

### 例: `deploy_access_level`デプロイアクセスレベルレコードを更新 {#example-update-a-deploy_access_level-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"deploy_access_levels": [{"id": 12, "group_id": 22034120}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
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

### 例: `deploy_access_level`デプロイアクセスレベルレコードを削除 {#example-delete-a-deploy_access_level-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"deploy_access_levels": [{"id": 12, "_destroy": true}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

レスポンス例:

```json
{
   "name": "production",
   "deploy_access_levels": [],
   "required_approval_count": 0
}
```

### 例: `approval_rule`承認ルールレコードを作成 {#example-create-an-approval_rule-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"approval_rules": [{"group_id": 134, "required_approvals": 1}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
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

### 例: `approval_rule`承認ルールレコードを更新 {#example-update-an-approval_rule-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"approval_rules": [{"id": 38, "group_id": 135, "required_approvals": 2}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
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

### 例: `approval_rule`承認ルールレコードを削除 {#example-delete-an-approval_rule-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"approval_rules": [{"id": 38, "_destroy": true}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

レスポンス例:

```json
{
   "name": "production",
   "approval_rules": []
}
```

## 単一の環境の保護を解除 {#unprotect-a-single-environment}

指定された保護環境の保護を解除します:

```plaintext
DELETE /projects/:id/protected_environments/:name
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name` | 文字列 | はい | 保護環境の名前。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_environments/staging"
```
