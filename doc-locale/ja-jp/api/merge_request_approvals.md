---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのマージリクエストの承認に関するREST APIのドキュメント。
title: マージリクエスト承認API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- エンドポイント`/approvals`は、GitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)されました。

{{< /history >}}

このAPIは、プロジェクトまたはグループ内のマージリクエストに対する承認の設定を管理します。

- ユーザーとしてマージリクエストを承認および承認解除します。
- マージリクエストに対する自分自身だけでなく、すべての承認をリセットします。
- プロジェクトの承認ルールを表示および管理します。

すべてのエンドポイントで認証が必要です。

## マージリクエストを承認する {#approve-merge-request}

指定されたマージリクエストを承認します。現在認証済みユーザーは、[承認が可能な承認者](../user/project/merge_requests/approvals/rules.md#eligible-approvers)である必要があります。

`sha`パラメータは、マージリクエストの現在のバージョンを承認していることを保証します。定義されている場合、値はマージリクエストのHEADコミットSHAと一致する必要があります。不一致があると、`409 Conflict`応答が返されます。これは、[マージリクエストの承認](merge_requests.md#merge-a-merge-request)の動作と一致します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approve
```

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approval_password` | 文字列            | いいえ       | 現在のユーザーのパスワード。プロジェクトの設定で、[**承認するにはユーザーの再認証を要求する**](../user/project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve)が有効になっている場合は、必須です。グループまたはGitLab Self-ManagedインスタンスがSAML認証を強制するように設定されている場合、常に失敗します。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |
| `sha`               | 文字列            | いいえ       | マージリクエストの`HEAD`。 |

```json
{
  "id": 5,
  "iid": 5,
  "project_id": 1,
  "title": "Approvals API",
  "description": "Test",
  "state": "opened",
  "created_at": "2016-06-08T00:19:52.638Z",
  "updated_at": "2016-06-09T21:32:14.105Z",
  "merge_status": "can_be_merged",
  "approvals_required": 2,
  "approvals_left": 0,
  "approved_by": [
    {
      "user": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/root"
      },
      "approved_at": "2016-06-10T04:21:41.050Z"
    },
    {
      "user": {
        "name": "Nico Cartwright",
        "username": "ryley",
        "id": 2,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/cf7ad14b34162a76d593e3affca2adca?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/ryley"
      },
      "approved_at": "2016-06-10T09:17:13.520Z"
    }
  ]
}
```

### 自動化されたマージリクエストの承認 {#approvals-for-automated-merge-requests}

APIを使用してマージリクエストを作成し、すぐに承認すると、自動化によってコミットが完全に処理される前に、マージリクエストが承認される可能性があります。デフォルトでは、新しい[コミット](../user/project/merge_requests/approvals/settings.md#remove-all-approvals-when-commits-are-added-to-the-source-branch)をマージリクエストに追加すると、既存のすべての承認がリセットされます。この場合、**アクティビティー**領域には、次のような一連のメッセージがマージリクエストに表示されます。

- `(botname)`が5分前にこのマージリクエストを承認しました
- `(botname)`が5分前に1件のコミットを追加しました
- `(botname)`が5分前にブランチにプッシュすることにより、`(botname)`から承認をリセットしました

コミットの処理が完了する前に自動承認が適用されないようにするには、自動化で次のようになるまで待機（または`sleep`）関数を追加する必要があります。

- `detailed_merge_status`属性が、`checking`または`approvals_syncing`のいずれの状態にもありません。
- マージリクエストの差分にNULLではない`patch_id_sha`が含まれています。

## マージリクエストを却下する {#unapprove-a-merge-request}

指定されたマージリクエストから、現在認証済みユーザーの承認を削除します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unapprove
```

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

## マージリクエストの承認をリセットする {#reset-approvals-for-a-merge-request}

指定されたマージリクエストのすべての承認をリセットします。

有効なプロジェクトまたはグループトークンを持つ[ボットユーザー](../user/project/settings/project_access_tokens.md#bot-users-for-projects)のみが利用できます。一般ユーザーには、`401 Unauthorized`応答が返されます。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/reset_approvals
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/reset_approvals"
```

## グループの承認ルール {#approval-rules-for-projects}

これらのエンドポイントは、プロジェクトとその承認ルールに適用されます。すべてのエンドポイントで認証が必要です。

### プロジェクトの承認設定を取得します {#retrieve-approval-configuration-for-a-project}

プロジェクトの承認設定を取得します。

```plaintext
GET /projects/:id/approvals
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```json
{
  "approvers": [], // Deprecated in GitLab 12.3, always returns empty
  "approver_groups": [], // Deprecated in GitLab 12.3, always returns empty
  "approvals_before_merge": 2, // Deprecated in GitLab 12.3, use Approval Rules instead
  "reset_approvals_on_push": true,
  "selective_code_owner_removals": false,
  "disable_overriding_approvers_per_merge_request": false,
  "merge_requests_author_approval": true,
  "merge_requests_disable_committers_approval": false,
  "require_password_to_approve": true, // Deprecated in 16.9, use require_reauthentication_to_approve instead
  "require_reauthentication_to_approve": true
}
```

### プロジェクトの承認設定を更新する {#update-approval-configuration-for-a-project}

プロジェクトの承認設定を更新します。現在認証済みユーザーは、[承認が可能な承認者](../user/project/merge_requests/approvals/rules.md#eligible-approvers)である必要があります。

```plaintext
POST /projects/:id/approvals
```

サポートされている属性:

| 属性                                        | 型              | 必須 | 説明 |
|--------------------------------------------------|-------------------|----------|-------------|
| `id`                                             | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approvals_before_merge`（非推奨）            | 整数           | いいえ       | マージリクエストをマージするために必要な承認の数。GitLab 12.3で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/11132)になりました。代わりに、[承認ルールを作成](#create-an-approval-rule-for-a-project)します。 |
| `disable_overriding_approvers_per_merge_request` | ブール値           | いいえ       | `true`の場合、マージリクエスト内の承認者のオーバーライドを防ぎます。 |
| `merge_requests_author_approval`                 | ブール値           | いいえ       | `true`の場合、作成者は自分のマージリクエストを自己承認できます。 |
| `merge_requests_disable_committers_approval`     | ブール値           | いいえ       | `true`の場合、マージリクエストでコミットするユーザーは、それを承認できません。 |
| `require_password_to_approve`（非推奨）       | ブール値           | いいえ       | `true`の場合、承認者は、承認を追加する前にパスワードで認証する必要があります。GitLab 16.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/431346)になりました。代わりに`require_reauthentication_to_approve`を使用してください。 |
| `require_reauthentication_to_approve`            | ブール値           | いいえ       | `true`の場合、承認を追加する前に承認者の認証が必須になります。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/431346)されました。 |
| `reset_approvals_on_push`                        | ブール値           | いいえ       | `true`の場合、プッシュ時に承認がリセットされます。 |
| `selective_code_owner_removals`                  | ブール値           | いいえ       | `true`の場合、コードの所有者のファイルが変更されると、コードの所有者からの承認がリセットされます。このフィールドを使用するには、`reset_approvals_on_push`が`false`である必要があります。 |

```json
{
  "approvals_before_merge": 2, // Use Approval Rules instead
  "reset_approvals_on_push": true,
  "selective_code_owner_removals": false,
  "disable_overriding_approvers_per_merge_request": false,
  "merge_requests_author_approval": false,
  "merge_requests_disable_committers_approval": false,
  "require_password_to_approve": true,
  "require_reauthentication_to_approve": true
}
```

### プロジェクトのすべての承認ルールをリストする {#list-all-approval-rules-for-a-project}

指定されたプロジェクトのすべての承認ルールと、関連する詳細をリストします。

```plaintext
GET /projects/:id/approval_rules
```

承認ルールのリストを[制限](rest/_index.md#offset-based-pagination)するには、`page`および`per_page`ページネーションパラメータを使用します。

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```json
[
  {
    "id": 1,
    "name": "security",
    "rule_type": "regular",
    "report_type": null,
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "applies_to_all_protected_branches": false,
    "protected_branches": [
      {
        "id": 1,
        "name": "main",
        "push_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "merge_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "unprotect_access_levels": [
          {
            "access_level": 40,
            "access_level_description": "Maintainers"
          }
        ],
        "code_owner_approval_required": "false"
      }
    ],
    "contains_hidden_groups": false,
  },
  {
    "id": 2,
    "name": "Coverage-Check",
    "rule_type": "report_approver",
    "report_type": "code_coverage",
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "applies_to_all_protected_branches": false,
    "protected_branches": [
      {
        "id": 1,
        "name": "main",
        "push_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "merge_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "unprotect_access_levels": [
          {
            "access_level": 40,
            "access_level_description": "Maintainers"
          }
        ],
        "code_owner_approval_required": "false"
      }
    ],
    "contains_hidden_groups": false,
  }
]
```

### プロジェクトの承認ルールを取得する {#retrieve-an-approval-rule-for-a-project}

プロジェクトの指定された承認ルールに関する情報を取得します。

```plaintext
GET /projects/:id/approval_rules/:approval_rule_id
```

サポートされている属性:

| 属性          | 型              | 必須 | 説明 |
|--------------------|-------------------|----------|-------------|
| `id`               | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approval_rule_id` | 整数           | はい      | 承認ルールのID。 |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "report_type": null,
  "eligible_approvers": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 3,
  "users": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "applies_to_all_protected_branches": false,
  "protected_branches": [
    {
      "id": 1,
      "name": "main",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

### プロジェクトの承認ルールを作成する {#create-an-approval-rule-for-a-project}

プロジェクトの承認ルールを作成します。

`rule_type`フィールドは、次のルールタイプをサポートします。

- `any_approver`: `approvals_required`が`0`に設定された、事前設定済みのデフォルトルール。
- `regular`: 通常の[マージリクエストの承認ルール](../user/project/merge_requests/approvals/rules.md)に使用されます。
- `report_approver`: フィールドは、設定され有効になっている[マージリクエスト承認ポリシー](../user/application_security/policies/merge_request_approval_policies.md)からGitLabが承認ルールを作成する際に使用されます。このAPIで承認ルールを作成するときは、この値を使用しないでください。

```plaintext
POST /projects/:id/approval_rules
```

サポートされている属性:

| 属性                           | 型              | 必須 | 説明 |
|-------------------------------------|-------------------|----------|-------------|
| `id`                                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approvals_required`                | 整数           | はい      | このルールに必要な承認の数。 |
| `name`                              | 文字列            | はい      | 承認ルールの名前。1024文字に制限されています。 |
| `applies_to_all_protected_branches` | ブール値           | いいえ       | `true`の場合、ルールはすべての保護ブランチに適用され、`protected_branch_ids`属性は無視されます。 |
| `group_ids`                         | 配列             | いいえ       | 承認者としてのグループのID。 |
| `protected_branch_ids`              | 配列             | いいえ       | ルールの範囲を指定する保護ブランチのID。IDを識別するには、[保護されたブランチをリスト](protected_branches.md#list-protected-branches) APIを使用します。 |
| `report_type`                       | 文字列            | いいえ       | レポートタイプ。ルールタイプが`report_approver`の場合に必須。サポートされているレポートタイプは、`license_scanning`（GitLab 15.9で[非推奨](../update/deprecations.md#license-check-and-the-policies-tab-on-the-license-compliance-page)になりました）と`code_coverage`です。  |
| `rule_type`                         | 文字列            | いいえ       | ルールタイプ。`any_approver`、`regular`、および`report_approver`を含む、サポートされている値。 |
| `user_ids`                          | 配列             | いいえ       | 承認者としてのユーザーのID。`usernames`と併用すると、ユーザーのリストが両方とも追加されます。 |
| `usernames`                         | 文字列配列      | いいえ       | 承認者のユーザー名。`user_ids`と併用すると、ユーザーのリストが両方とも追加されます。 |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "applies_to_all_protected_branches": false,
  "protected_branches": [
    {
      "id": 1,
      "name": "main",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

必要な承認者のデフォルト数を0から増やすには、次のようにします。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"name": "Any name", "rule_type": "any_approver", "approvals_required": 2}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/approval_rules"
```

別の例として、ユーザー固有のルールを作成する方法を次に示します。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"name": "Name of your rule", "approvals_required": 3, "user_ids": [123, 456, 789]}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/approval_rules"
```

### プロジェクトの承認ルールを更新する {#update-an-approval-rule-for-a-project}

プロジェクトの指定された承認ルールを更新します。このエンドポイントは、`group_ids`、`user_ids`、または`usernames`属性で定義されていない承認者とグループを削除します。

`users`または`groups`パラメータに含まれていない隠しグループ（ユーザーに表示する権限がないプライベートグループ）は、デフォルトで保持されます。それらを削除するには、`remove_hidden_groups`を`true`に設定します。これにより、ユーザーが承認ルールを更新するときに、非表示のグループが誤って削除されなくなります。

```plaintext
PUT /projects/:id/approval_rules/:approval_rule_id
```

サポートされている属性:

| 属性                           | 型              | 必須 | 説明 |
|-------------------------------------|-------------------|----------|-------------|
| `approval_rule_id`                  | 整数           | はい      | 承認ルールのID。 |
| `id`                                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `applies_to_all_protected_branches` | ブール値           | いいえ       | `true`の場合、ルールはすべての保護ブランチに適用され、`protected_branch_ids`属性は無視されます。 |
| `approvals_required`                | 整数           | いいえ       | このルールに必要な承認の数。 |
| `group_ids`                         | 配列             | いいえ       | 承認者としてのグループのID。 |
| `name`                              | 文字列            | いいえ       | 承認ルールの名前。1024文字に制限されています。 |
| `protected_branch_ids`              | 配列             | いいえ       | ルールの範囲を指定する保護ブランチのID。IDを識別するには、[保護されたブランチをリスト](protected_branches.md#list-protected-branches) APIを使用します。 |
| `remove_hidden_groups`              | ブール値           | いいえ       | `true`の場合、承認ルールから隠しグループが削除されます。 |
| `user_ids`                          | 配列             | いいえ       | 承認者としてのユーザーのID。`usernames`と併用すると、ユーザーのリストが両方とも追加されます。 |
| `usernames`                         | 文字列配列      | いいえ       | 承認者のユーザー名。`user_ids`と併用すると、ユーザーのリストが両方とも追加されます。 |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "applies_to_all_protected_branches": false,
  "protected_branches": [
    {
      "id": 1,
      "name": "main",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

### プロジェクトの承認ルールを削除する {#delete-an-approval-rule-for-a-project}

指定されたプロジェクトの承認ルールを削除します。

```plaintext
DELETE /projects/:id/approval_rules/:approval_rule_id
```

サポートされている属性:

| 属性          | 型              | 必須 | 説明 |
|--------------------|-------------------|----------|-------------|
| `id`               | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approval_rule_id` | 整数           | はい      | 承認ルールのID。 |

## マージリクエストの承認ルール {#approval-rules-for-a-merge-request}

これらのエンドポイントは、個々のマージリクエストに適用されます。すべてのエンドポイントで認証が必要です。

### マージリクエストの承認状態を取得する {#retrieve-approval-state-for-a-merge-request}

指定されたマージリクエストの承認状態を取得します。

応答では、`approved_by`には、承認が承認ルールを満たしているかどうかに関係なく、マージリクエストのすべての承認者に関する情報が含まれています。マージリクエストの承認ルールに関する詳細情報、および受信した承認がそれらのルールを満たしているかどうかについては、[`/approval_state`エンドポイント](#retrieve-approval-details-for-a-merge-request)を参照してください。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approvals
```

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

```json
{
  "id": 5,
  "iid": 5,
  "project_id": 1,
  "title": "Approvals API",
  "description": "Test",
  "state": "opened",
  "created_at": "2016-06-08T00:19:52.638Z",
  "updated_at": "2016-06-08T21:20:42.470Z",
  "merge_status": "cannot_be_merged",
  "approvals_required": 2,
  "approvals_left": 1,
  "approved_by": [
    {
      "user": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/root"
      },
      "approved_by": "2016-06-09T01:45:21.720Z"
    }
  ]
}
```

### マージリクエストの承認の詳細を取得する {#retrieve-approval-details-for-a-merge-request}

指定されたマージリクエストの承認の詳細を取得します。

ユーザーがマージリクエストの承認ルールを変更した場合、応答には以下が含まれます。

- `approval_rules_overwritten`: `true`の場合、デフォルトの承認ルールが変更されたことを示します。
- `approved`: `true`の場合、関連付けられた承認ルールが承認されたことを示します。
- `approved_by`: 定義されている場合は、関連付けられた承認ルールを承認したユーザーの詳細を示します。承認ルールに一致しないユーザーは返されません。すべての承認ユーザーを返すには、[`/approvals`エンドポイント](#retrieve-approval-state-for-a-merge-request)を参照してください。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_state
```

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

```json
{
  "approval_rules_overwritten": true,
  "rules": [
    {
      "id": 1,
      "name": "Ruby",
      "rule_type": "regular",
      "eligible_approvers": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "approvals_required": 2,
      "users": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "groups": [],
      "contains_hidden_groups": false,
      "approved_by": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "source_rule": null,
      "approved": true,
      "overridden": false
    }
  ]
}
```

### マージリクエストのすべての承認ルールをリストする {#list-all-approval-rules-for-a-merge-request}

指定されたマージリクエストのすべての承認ルールと、関連する詳細をリストします。

`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用して、承認ルールのリストを制限します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

```json
[
  {
    "id": 1,
    "name": "security",
    "rule_type": "regular",
    "report_type": null,
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "source_rule": null,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "contains_hidden_groups": false,
    "overridden": false
  },
  {
    "id": 2,
    "name": "Coverage-Check",
    "rule_type": "report_approver",
    "report_type": "code_coverage",
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "source_rule": null,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "contains_hidden_groups": false,
    "overridden": false
  }
]
```

### 特定のマージリクエストの承認ルールを取得する {#retrieve-an-approval-rule-for-a-specific-merge-request}

特定のマージリクエストの承認ルールに関する情報を取得します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approval_rule_id`  | 整数           | はい      | 承認ルールのID。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "report_type": null,
  "eligible_approvers": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 3,
  "source_rule": null,
  "users": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### マージリクエストの承認ルールを作成する {#create-an-approval-rule-for-a-merge-request}

特定のマージリクエストの承認ルールを作成します。`approval_project_rule_id`がプロジェクトからの既存の承認ルールのIDで設定されている場合、このエンドポイントは次のようになります。

- プロジェクトのルールから、`name`、`users`、および`groups`の値をコピーします。
- 指定した`approvals_required`値を使用します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

サポートされている属性:

| 属性                  | 型              | 必須               | 説明                                                                  |
|----------------------------|-------------------|------------------------|------------------------------------------------------------------------------|
| `id`                       | 整数または文字列 | はい | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approvals_required`       | 整数           | はい | このルールに必要な承認の数。                              |
| `merge_request_iid`        | 整数           | はい | マージリクエストのIID。                                                |
| `name`                     | 文字列            | はい | 承認ルールの名前。1024文字に制限されています。                                               |
| `approval_project_rule_id` | 整数           | いいえ | プロジェクトの承認ルールのID。                                     |
| `group_ids`                | 配列             | いいえ | 承認者としてのグループのID。                                              |
| `user_ids`                 | 配列             | いいえ | 承認者としてのユーザーのID。`usernames`と併用すると、ユーザーのリストが両方とも追加されます。 |
| `usernames`                | 文字列配列      | いいえ | 承認者のユーザー名。`user_ids`と併用すると、ユーザーのリストが両方とも追加されます。 |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "source_rule": null,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### マージリクエストの承認ルールを更新する {#update-an-approval-rule-for-a-merge-request}

マージリクエストの指定された承認ルールを更新します。このエンドポイントは、`group_ids`、`user_ids`、または`usernames`属性に含まれていない承認者とグループを削除します。

`report_approver`または`code_owner`のルールはシステムによって生成されるため、編集できません。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

サポートされている属性:

| 属性              | 型              | 必須 | 説明 |
|------------------------|-------------------|----------|-------------|
| `id`                   | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approval_rule_id`     | 整数           | はい      | 承認ルールのID。 |
| `merge_request_iid`    | 整数           | はい      | マージリクエストのIID。 |
| `approvals_required`   | 整数           | いいえ       | このルールに必要な承認の数。 |
| `group_ids`            | 配列             | いいえ       | 承認者としてのグループのID。 |
| `name`                 | 文字列            | いいえ       | 承認ルールの名前。1024文字に制限されています。 |
| `remove_hidden_groups` | ブール値           | いいえ       | `true`の場合、隠しグループを削除します。 |
| `user_ids`             | 配列             | いいえ       | 承認者としてのユーザーのID。`usernames`と併用すると、ユーザーのリストが両方とも追加されます。 |
| `usernames`            | 文字列配列      | いいえ       | 承認者のユーザー名。`user_ids`と併用すると、ユーザーのリストが両方とも追加されます。 |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "source_rule": null,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### マージリクエストの承認ルールを削除する {#delete-an-approval-rule-for-a-merge-request}

指定されたマージリクエストの承認ルールを削除します。

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

`report_approver`または`code_owner`のルールはシステムによって生成されるため、編集できません。

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approval_rule_id`  | 整数           | はい      | 承認ルールのID。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

## グループの承認ルール {#approval-rules-for-groups}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 16.7で`approval_group_rules`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428051)されました。デフォルトでは無効になっています。これは[実験的機能](../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`approval_group_rules`という名前の[機能フラグを有効にする](../administration/feature_flags/_index.md)と、この機能を使用できるようになります。GitLab.comとGitLab Dedicatedでは、この機能は使用できません。この機能は本番環境での使用には対応していません。

{{< /alert >}}

グループ承認ルールは、グループに属するプロジェクトのすべての保護ブランチに適用されます。

### グループのすべての承認ルールをリストする {#list-all-approval-rules-for-a-group}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440638)されました。

{{< /history >}}

指定されたグループのすべての承認ルールと、関連する詳細をリストします。グループ管理者に制限されています。

`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用して、承認ルールのリストを制限します。

```plaintext
GET /groups/:id/approval_rules
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules"
```

レスポンス例:

```json
[
  {
    "id": 2,
    "name": "rule1",
    "rule_type": "any_approver",
    "report_type": null,
    "eligible_approvers": [],
    "approvals_required": 3,
    "users": [],
    "groups": [],
    "contains_hidden_groups": false,
    "protected_branches": [],
    "applies_to_all_protected_branches": true
  },
  {
    "id": 3,
    "name": "rule2",
    "rule_type": "code_owner",
    "report_type": null,
    "eligible_approvers": [],
    "approvals_required": 2,
    "users": [],
    "groups": [],
    "contains_hidden_groups": false,
    "protected_branches": [],
    "applies_to_all_protected_branches": true
  },
  {
    "id": 4,
    "name": "rule2",
    "rule_type": "report_approver",
    "report_type": "code_coverage",
    "eligible_approvers": [],
    "approvals_required": 2,
    "users": [],
    "groups": [],
    "contains_hidden_groups": false,
    "protected_branches": [],
    "applies_to_all_protected_branches": true
  }
]

```

### グループの承認ルールを作成する {#create-an-approval-rule-for-a-group}

グループの承認ルールを作成します。グループ管理者に制限されています。

APIから承認ルールをビルドするときは、`rule_type`フィールドを使用しないでください。フィールドは、次のルールタイプをサポートします。

- `any_approver`: `approvals_required`が`0`に設定された、事前設定済みのデフォルトルール。
- `regular`: 通常の[マージリクエストの承認ルール](../user/project/merge_requests/approvals/rules.md)に使用されます。
- `report_approver`: フィールドは、設定され有効になっている[マージリクエスト承認ポリシー](../user/application_security/policies/merge_request_approval_policies.md)からGitLabが承認ルールを作成する際に使用されます。

```plaintext
POST /groups/:id/approval_rules
```

サポートされている属性:

| 属性            | 型              | 必須 | 説明 |
|----------------------|-------------------|----------|-------------|
| `id`                 | 整数または文字列 | はい      | グループのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approvals_required` | 整数           | はい      | このルールに必要な承認の数。 |
| `name`               | 文字列            | はい      | 承認ルールの名前。1024文字に制限されています。 |
| `group_ids`          | 配列             | いいえ       | 承認者としてのグループのID。 |
| `rule_type`          | 文字列            | いいえ       | ルールタイプ。`any_approver`、`regular`、および`report_approver`を含む、サポートされている値。 |
| `user_ids`           | 配列             | いいえ       | 承認者としてのユーザーのID。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules?name=security&approvals_required=2"
```

レスポンス例:

```json
{
  "id": 5,
  "name": "security",
  "rule_type": "any_approver",
  "eligible_approvers": [],
  "approvals_required": 2,
  "users": [],
  "groups": [],
  "contains_hidden_groups": false,
  "protected_branches": [
    {
      "id": 5,
      "name": "master",
      "push_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "deploy_key_id": null,
          "user_id": null,
          "group_id": null
        }
      ],
      "merge_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "user_id": null,
          "group_id": null
        }
      ],
      "allow_force_push": false,
      "unprotect_access_levels": [],
      "code_owner_approval_required": false,
      "inherited": false
    }
  ],
  "applies_to_all_protected_branches": true
}
```

### グループの承認ルールを更新する {#update-an-approval-rule-for-a-group}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440639)されました。

{{< /history >}}

グループの承認ルールを更新します。グループ管理者に制限されています。

APIから承認ルールをビルドするときは、`rule_type`フィールドを使用しないでください。フィールドは、次のルールタイプをサポートします。

- `any_approver`: `approvals_required`が`0`に設定された、事前設定済みのデフォルトルール。
- `regular`: 通常の[マージリクエストの承認ルール](../user/project/merge_requests/approvals/rules.md)に使用されます。
- `report_approver`: フィールドは、設定され有効になっている[マージリクエスト承認ポリシー](../user/application_security/policies/merge_request_approval_policies.md)からGitLabが承認ルールを作成する際に使用されます。

```shell
PUT /groups/:id/approval_rules/:approval_rule_id
```

サポートされている属性:

| 属性            | 型              | 必須 | 説明 |
|----------------------|-------------------|----------|-------------|
| `approval_rule_id`。  | 整数           | はい      | 承認ルールのID。 |
| `id`                 | 整数または文字列 | はい      | グループのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approvals_required` | 文字列            | いいえ       | このルールに必要な承認の数。 |
| `group_ids`          | 整数           | いいえ       | 承認者としてのユーザーのID。 |
| `name`               | 文字列            | いいえ       | 承認ルールの名前。1024文字に制限されています。 |
| `rule_type`          | 配列             | いいえ       | ルールタイプ。`any_approver`、`regular`、および`report_approver`を含む、サポートされている値。 |
| `user_ids`           | 配列             | いいえ       | 承認者としてのグループのID。 |

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules/5?name=security2&approvals_required=1"
```

レスポンス例:

```json
{
  "id": 5,
  "name": "security2",
  "rule_type": "any_approver",
  "eligible_approvers": [],
  "approvals_required": 1,
  "users": [],
  "groups": [],
  "contains_hidden_groups": false,
  "protected_branches": [
    {
      "id": 5,
      "name": "master",
      "push_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "deploy_key_id": null,
          "user_id": null,
          "group_id": null
        }
      ],
      "merge_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "user_id": null,
          "group_id": null
        }
      ],
      "allow_force_push": false,
      "unprotect_access_levels": [],
      "code_owner_approval_required": false,
      "inherited": false
    }
  ],
  "applies_to_all_protected_branches": true
}
```
