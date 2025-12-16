---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: メンバーロール 
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96996)されました。[`customizable_roles`フラグの背後にデプロイ](../administration/feature_flags/_index.md)され、デフォルトでは無効になっています。
- GitLab 15.9で、[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810)になりました。
- GitLab 16.0で[脆弱性の読み取りが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114734)されました。
- GitLab 16.1で[管理者脆弱性が追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121534)されました。
- GitLab 16.3で[依存関係の読み取りが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126247)されました。
- GitLab 16.3で[名前と説明のフィールドが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126423)されました。
- `admin_merge_request`という名前の[フラグ](../administration/feature_flags/_index.md)を使用して、GitLab 16.4で[管理マージリクエストが導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128302)されました。デフォルトでは無効になっています。
- GitLab 16.5で[機能フラグ`admin_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132578)が削除されました。
- `admin_group_member`という名前の[フラグ](../administration/feature_flags/_index.md)を使用して、GitLab 16.5で[管理者グループメンバーが導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131914)されました。デフォルトでは無効になっています。GitLab 16.6では、機能フラグは削除されました。
- `manage_project_access_tokens`という名前の[フラグ](../administration/feature_flags/_index.md)を使用して、GitLab 16.5で[プロジェクトアクセストークンの管理が導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132342)されました。デフォルトでは無効になっています。
- GitLab 16.7で[プロジェクトのアーカイブが導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134998)されました。
- GitLab 16.8で[プロジェクトの削除が導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139696)されました。
- グループアクセストークンのサポートは、GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140115)されました。
- GitLab 16.8で[管理者Terraformステートが導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140759)されました。
- GitLab Self-Managedでインスタンス全体のカスタムロールを作成および削除する機能は、GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141562)されました。
- `custom_ability_admin_security_testing`という名前の[フラグ](../administration/feature_flags/_index.md)を使用して、GitLab 17.9で[管理者セキュリティテストが導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176628)されました。デフォルトでは無効になっています。

{{< /history >}}

このAPIを使用して、GitLab.comグループまたはGitLab Self-Managedインスタンス全体のメンバーロールを操作します。

## インスタンスメンバーロールの管理 {#manage-instance-member-roles}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件: 

- [管理者として認証してください](rest/authentication.md)。

### インスタンスメンバーロールをすべて取得 {#get-all-instance-member-roles}

インスタンス内のすべてのメンバーロールを取得します。

```plaintext
GET /member_roles
```

リクエスト例:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/member_roles"
```

レスポンス例:

```json
[
  {
    "id": 2,
    "name": "Instance custom role",
    "description": "Custom guest that can read code",
    "group_id": null,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": false,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": false,
    "read_vulnerability": false,
    "remove_group": false,
    "remove_project": false
  }
]
```

### インスタンスメンバーロールの作成 {#create-a-instance-member-role}

インスタンス全体のメンバーロールを作成します。

```plaintext
POST /member_roles
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
|:----------|:--------|:---------|:-------------------------------------|
| `name`         | 文字列         | はい      | メンバーロールの名前。 |
| `description`  | 文字列         | いいえ       | メンバーロールの説明。 |
| `base_access_level` | 整数   | はい      | 構成されたロールのベースアクセスレベル。有効な値は、`10` (ゲスト)、`15` (プランナー)、`20` (レポーター)、`30` (デベロッパー)、`40` (メンテナー)、または`50` (オーナー)です。|
| `admin_cicd_variables` | ブール値 | いいえ       | CI/CD変数の作成、読み取り、更新、削除の権限。 |
| `admin_compliance_framework` | ブール値 | いいえ       | コンプライアンスフレームワークを管理する権限。 |
| `admin_group_member` | ブール値 | いいえ       | グループ内のメンバーを追加、削除、割り当てる権限。 |
| `admin_merge_request` | ブール値 | いいえ       | マージリクエストを承認する権限。 |
| `admin_push_rules` | ブール値 | いいえ       | グループレベルまたはプロジェクトレベルでリポジトリのプッシュルールを構成する権限。 |
| `admin_terraform_state` | ブール値 | いいえ       | プロジェクトTerraformステートを管理する権限。 |
| `admin_vulnerability` | ブール値 | いいえ       | 脆弱性オブジェクトを編集する権限（ステータスの編集、イシューのリンクなど）。 |
| `admin_web_hook` | ブール値 | いいえ       | Webhookを管理する権限。 |
| `archive_project` | ブール値 | いいえ       | プロジェクトをアーカイブする権限。 |
| `manage_deploy_tokens` | ブール値 | いいえ       | デプロイトークンを管理する権限。 |
| `manage_group_access_tokens` | ブール値 | いいえ       | グループアクセストークンを管理する権限。 |
| `manage_merge_request_settings` | ブール値 | いいえ       | マージリクエストの設定を構成する権限。 |
| `manage_project_access_tokens` | ブール値 | いいえ       | プロジェクトアクセストークンを管理する権限。 |
| `manage_security_policy_link` | ブール値 | いいえ       | セキュリティポリシープロジェクトをリンクする権限。 |
| `read_code`           | ブール値 | いいえ       | プロジェクトコードを読み取りる権限。 |
| `read_runners`     | ブール値 | いいえ       | プロジェクトRunnerを表示する権限。 |
| `read_dependency`     | ブール値 | いいえ       | プロジェクトの依存関係を読み取りる権限。 |
| `read_vulnerability`  | ブール値 | いいえ       | プロジェクトの脆弱性を読み取りる権限。 |
| `remove_group` | ブール値 | いいえ       | グループを削除または復元する権限。 |
| `remove_project` | ブール値 | いいえ       | プロジェクトを削除する権限。 |

利用可能な権限の詳細については、[カスタム権限](../user/custom_roles/abilities.md)を参照してください。

リクエスト例:

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"name" : "Custom guest (instance)", "base_access_level" : 10, "read_code" : true}' \
  --url "https://gitlab.example.com/api/v4/member_roles"
```

レスポンス例:

```json
{
  "id": 3,
  "name": "Custom guest (instance)",
  "group_id": null,
  "description": null,
  "base_access_level": 10,
  "admin_cicd_variables": false,
  "admin_compliance_framework": false,
  "admin_group_member": false,
  "admin_merge_request": false,
  "admin_push_rules": false,
  "admin_terraform_state": false,
  "admin_vulnerability": false,
  "admin_web_hook": false,
  "archive_project": false,
  "manage_deploy_tokens": false,
  "manage_group_access_tokens": false,
  "manage_merge_request_settings": false,
  "manage_project_access_tokens": false,
  "manage_security_policy_link": false,
  "read_code": true,
  "read_runners": false,
  "read_dependency": false,
  "read_vulnerability": false,
  "remove_group": false,
  "remove_project": false
}
```

### インスタンスメンバーロールの削除 {#delete-an-instance-member-role}

インスタンスからメンバーロールを削除します。

```plaintext
DELETE /member_roles/:member_role_id
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
|:----------|:--------|:---------|:-------------------------------------|
| `member_role_id` | 整数 | はい   | メンバーロールのID。 |

成功した場合は、[`204`](rest/troubleshooting.md#status-codes)と空のレスポンスを返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/member_roles/1"
```

## グループメンバーロールの管理 {#manage-group-member-roles}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com

{{< /details >}}

前提要件: 

- グループのオーナーロールを持っている必要があります。

### グループメンバーロールをすべて取得 {#get-all-group-member-roles}

```plaintext
GET /groups/:id/member_roles
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/84/member_roles"
```

レスポンス例:

```json
[
  {
    "id": 2,
    "name": "Guest + read code",
    "description": "Custom guest that can read code",
    "group_id": 84,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": false,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": false,
    "read_vulnerability": false,
    "remove_group": false,
    "remove_project": false
  },
  {
    "id": 3,
    "name": "Guest + security",
    "description": "Custom guest that read and admin security entities",
    "group_id": 84,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": true,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": true,
    "read_vulnerability": true,
    "remove_group": false,
    "remove_project": false
  }
]
```

### グループへのメンバーロールの追加 {#add-a-member-role-to-a-group}

{{< history >}}

- カスタムロールの作成時に名前と説明を追加する機能は、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126423)されました。

{{< /history >}}

メンバーロールをグループに追加します。グループのルートレベルでのみメンバーロールを追加できます。

```plaintext
POST /groups/:id/member_roles
```

パラメータは以下のとおりです:

| 属性 | 型                | 必須 | 説明 |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | 整数または文字列      | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `admin_cicd_variables` | ブール値 | いいえ       | CI/CD変数の作成、読み取り、更新、削除の権限。 |
| `admin_compliance_framework` | ブール値 | いいえ       | コンプライアンスフレームワークを管理する権限。 |
| `admin_group_member` | ブール値 | いいえ       | グループ内のメンバーを追加、削除、割り当てる権限。 |
| `admin_merge_request` | ブール値 | いいえ       | マージリクエストを承認する権限。 |
| `admin_push_rules` | ブール値 | いいえ       | グループレベルまたはプロジェクトレベルでリポジトリのプッシュルールを構成する権限。 |
| `admin_terraform_state` | ブール値 | いいえ       | プロジェクトTerraformステートを管理する権限。 |
| `admin_vulnerability` | ブール値 | いいえ       | プロジェクトの脆弱性を管理する権限。 |
| `admin_web_hook` | ブール値 | いいえ       | Webhookを管理する権限。 |
| `archive_project` | ブール値 | いいえ       | プロジェクトをアーカイブする権限。 |
| `manage_deploy_tokens` | ブール値 | いいえ       | デプロイトークンを管理する権限。 |
| `manage_group_access_tokens` | ブール値 | いいえ       | グループアクセストークンを管理する権限。 |
| `manage_merge_request_settings` | ブール値 | いいえ       | マージリクエストの設定を構成する権限。 |
| `manage_project_access_tokens` | ブール値 | いいえ       | プロジェクトアクセストークンを管理する権限。 |
| `manage_security_policy_link` | ブール値 | いいえ       | セキュリティポリシープロジェクトをリンクする権限。 |
| `read_code`           | ブール値 | いいえ       | プロジェクトコードを読み取りる権限。 |
| `read_runners`     | ブール値 | いいえ       | プロジェクトRunnerを表示する権限。 |
| `read_dependency`     | ブール値 | いいえ       | プロジェクトの依存関係を読み取りる権限。 |
| `read_vulnerability`  | ブール値 | いいえ       | プロジェクトの脆弱性を読み取りる権限。 |
| `remove_group` | ブール値 | いいえ       | グループを削除または復元する権限。 |
| `remove_project` | ブール値 | いいえ       | プロジェクトを削除する権限。 |

リクエスト例:

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"name" : "Custom guest", "base_access_level" : 10, "read_code" : true}' \
  --url "https://gitlab.example.com/api/v4/groups/84/member_roles"
```

レスポンス例:

```json
{
  "id": 3,
  "name": "Custom guest",
  "description": null,
  "group_id": 84,
  "base_access_level": 10,
  "admin_cicd_variables": false,
  "admin_compliance_framework": false,
  "admin_group_member": false,
  "admin_merge_request": false,
  "admin_push_rules": false,
  "admin_terraform_state": false,
  "admin_vulnerability": false,
  "admin_web_hook": false,
  "archive_project": false,
  "manage_deploy_tokens": false,
  "manage_group_access_tokens": false,
  "manage_merge_request_settings": false,
  "manage_project_access_tokens": false,
  "manage_security_policy_link": false,
  "read_code": true,
  "read_runners": false,
  "read_dependency": false,
  "read_vulnerability": false,
  "remove_group": false,
  "remove_project": false
}
```

GitLab 16.3以降では、APIを使用して以下を実行できます:

- [新しいカスタムロールを作成する](../user/custom_roles/_index.md#create-a-custom-member-role)ときに、名前（必須）と説明（オプション）を追加します。
- 既存のカスタムロールの名前と説明を更新します。

### グループのメンバーロールの削除 {#remove-member-role-of-a-group}

グループのメンバーロールを削除します。

```plaintext
DELETE /groups/:id/member_roles/:member_role_id
```

| 属性 | 型 | 必須 | 説明 |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `member_role_id` | 整数 | はい   | メンバーロールのID。 |

成功した場合は、[`204`](rest/troubleshooting.md#status-codes)と空のレスポンスを返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/84/member_roles/1"
```
