---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for merge request approvals in GitLab.
title: マージリクエスト承認API
---

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- エンドポイント`/approvals`は、GitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)されました。

{{< /history >}}

プロジェクト内の[すべてのマージリクエストの承認](../user/project/merge_requests/approvals/_index.md)の設定。すべてのエンドポイントで認証が必要です。

## マージリクエストを承認する

適切なロールを持つユーザーは、このエンドポイントを使用してマージリクエストを承認できます。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approve
```

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approval_password` | 文字列            | いいえ       | 現在のユーザーのパスワード。プロジェクト設定で[**承認するにはユーザーの再認証が必要です**](../user/project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve)が有効になっている場合は必須。グループまたはGitLab Self-ManagedインスタンスがSAML認証を強制するように設定されている場合、常に失敗します。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |
| `sha`               | 文字列            | いいえ       | マージリクエストの`HEAD`。 |

`sha`パラメーターは、[マージリクエストを承認する](merge_requests.md#merge-a-merge-request)場合と同じように機能します。このパラメーターが渡された場合、承認を追加するには、マージリクエストの現在のHEADと一致する必要があります。一致しない場合、応答コードは`409`になります。

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
      }
    },
    {
      "user": {
        "name": "Nico Cartwright",
        "username": "ryley",
        "id": 2,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/cf7ad14b34162a76d593e3affca2adca?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/ryley"
      }
    }
  ]
}
```

## マージリクエストの承認を取り消す

マージリクエストを承認した場合、次のエンドポイントを使用して承認を取り消すことができます。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unapprove
```

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

## マージリクエストの承認をリセットする

マージリクエストのすべての承認をクリアします。

プロジェクトまたはグループのトークンに基づいて、[ボットユーザー](../user/project/settings/project_access_tokens.md#bot-users-for-projects)のみが利用できます。ボット権限を持たないユーザーは、`401 Unauthorized`応答を受信します。

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

## プロジェクト承認ルール

[プロジェクト承認ルール](#get-all-approval-rules-for-project)を使用して、この情報にアクセスします。

次のエンドポイントを使用して、プロジェクトの承認設定に関する情報をリクエストできます。

```plaintext
GET /projects/:id/approvals
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

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

### 設定の変更

適切なロールを持つユーザーは、このエンドポイントを使用して承認設定を変更できます。

```plaintext
POST /projects/:id/approvals
```

サポートされている属性:

| 属性                                        | 型              | 必須 | 説明 |
|--------------------------------------------------|-------------------|----------|-------------|
| `id`                                             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approvals_before_merge`（非推奨）            | 整数           | いいえ       | マージリクエストをマージするために必要な承認の数。GitLab 12.3で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/11132)になりました。代わりに、[承認ルール](#create-project-approval-rule)を使用してください。 |
| `disable_overriding_approvers_per_merge_request` | ブール値           | いいえ       | マージリクエストごとに承認者をオーバーライドすることを許可または禁止します。 |
| `merge_requests_author_approval`                 | ブール値           | いいえ       | 作成者がマージリクエストを自己承認することを許可または禁止します。`true`は、作成者が自己承認できることを意味します。 |
| `merge_requests_disable_committers_approval`     | ブール値           | いいえ       | コミッターがマージリクエストを自己承認することを許可または禁止します。 |
| `require_password_to_approve`（非推奨）       | ブール値           | いいえ       | 承認を追加する前に、承認者がパスワードを入力して認証する必要があります。GitLab 16.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/431346)になりました。代わりに、`require_reauthentication_to_approve`を使用してください。 |
| `require_reauthentication_to_approve`            | ブール値           | いいえ       | 承認を追加する前に、承認者がパスワードを入力して認証する必要があります。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/431346)されました。 |
| `reset_approvals_on_push`                        | ブール値           | いいえ       | 新しいプッシュ時に承認をリセットします。 |
| `selective_code_owner_removals`                  | ブール値           | いいえ       | GitLabコードオーナーのファイルが変更された場合、GitLabコードオーナーからの承認をリセットします。このフィールドを使用するには、`reset_approvals_on_push`フィールドを無効にする必要があります。 |

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

### プロジェクトのすべての承認ルールを取得する

{{< history >}}

- ページネーションのサポートは、GitLab 15.3で`approval_rules_pagination`という名前の[フラグ](../administration/feature_flags.md)とともに導入されました。デフォルトで有効になっています。GitLabチームのメンバーは、この機密情報イシュー（`https://gitlab.com/gitlab-org/gitlab/-/issues/31011`）で詳細情報を確認できます。
- `applies_to_all_protected_branches`プロパティは、GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/335316)されました。
- ページネーションのサポートは、GitLab 15.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/366823)になりました。機能フラグ`approval_rules_pagination`は削除されました。
- `usernames`プロパティは、GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102446)されました。

{{< /history >}}

次のエンドポイントを使用して、プロジェクトの承認ルールに関する情報をリクエストできます。

```plaintext
GET /projects/:id/approval_rules
```

`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメーターを使用して、承認ルールのリストを制限します。

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

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

### プロジェクトの単一の承認ルールを取得する

{{< history >}}

- `applies_to_all_protected_branches`プロパティは、GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/335316)されました。
- `usernames`プロパティは、GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102446)されました。

{{< /history >}}

次のエンドポイントを使用して、プロジェクトの単一の承認ルールに関する情報をリクエストできます。

```plaintext
GET /projects/:id/approval_rules/:approval_rule_id
```

サポートされている属性:

| 属性          | 型              | 必須 | 説明 |
|--------------------|-------------------|----------|-------------|
| `id`               | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
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

### プロジェクト承認ルールを作成する

{{< history >}}

- 脆弱性チェック機能は、GitLab 15.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/357300)されました。
- `applies_to_all_protected_branches`プロパティは、GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/335316)されました。
- `usernames`プロパティは、GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102446)されました。

{{< /history >}}

次のエンドポイントを使用して、プロジェクト承認ルールを作成できます。

```plaintext
POST /projects/:id/approval_rules
```

サポートされている属性:

| 属性                           | 型              | 必須 | 説明 |
|-------------------------------------|-------------------|----------|-------------|
| `id`                                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approvals_required`                | 整数           | はい      | このルールに必要な承認の数。 |
| `name`                              | 文字列            | はい      | 承認ルールの名前。1024文字に制限されています。 |
| `applies_to_all_protected_branches` | ブール値           | いいえ       | ルールをすべての保護ブランチに適用するかどうかを指定します。`true`に設定すると、`protected_branch_ids`の値は無視されます。デフォルトは`false`です。GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/335316)されました。 |
| `group_ids`                         | 配列             | いいえ       | 承認者としてのグループのID。 |
| `protected_branch_ids`              | 配列             | いいえ       | ルールをスコープする保護ブランチのID。IDを識別するには、[APIを使用](protected_branches.md#list-protected-branches)します。 |
| `report_type`                       | 文字列            | いいえ       | ルールタイプが`report_approver`の場合に必要なレポートタイプ。サポートされているレポートタイプは、`license_scanning`[（GitLab 15.9で非推奨にりました）](../update/deprecations.md#license-check-and-the-policies-tab-on-the-license-compliance-page)と`code_coverage`です。 |
| `rule_type`                         | 文字列            | いいえ       | ルールタイプ。`any_approver`は、`approvals_required`が`0`の事前設定されたデフォルトルールです。その他のルールは、`regular`（通常の[マージリクエスト承認ルール](../user/project/merge_requests/approvals/rules.md)に使用されます）と`report_approver`です。このフィールドを使用して、APIから承認ルールを作成しないでください。`report_approver`フィールドは、GitLabが、設定および有効化された[マージリクエスト承認ポリシー](../user/application_security/policies/merge_request_approval_policies.md)から承認ルールを作成するときに使用されます。 |
| `user_ids`                          | 配列             | いいえ       | 承認者としてのユーザーのID。`user_ids`と`usernames`の両方を指定すると、ユーザーに関する両方のリストが追加されます。 |
| `usernames`                         | 文字列配列      | いいえ       | このルールの承認者のユーザー名（`user_ids`と同じですが、ユーザー名のリストが必要です）。`user_ids`と`usernames`の両方を指定すると、ユーザーに関する両方のリストが追加されます。 |

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

必要な承認者のデフォルト数である0を増やすには、次のようにします。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"name": "Any name", "rule_type": "any_approver", "approvals_required": 2}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/approval_rules"
```

もう1つの例では、ユーザー固有のルールを作成すします。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"name": "Name of your rule", "approvals_required": 3, "user_ids": [123, 456, 789]}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/approval_rules"
```

### プロジェクト承認ルールを更新する

{{< history >}}

- 脆弱性チェック機能は、GitLab 15.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/357300)されました。
- `applies_to_all_protected_branches`プロパティは、GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/335316)されました。
- `usernames`プロパティは、GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102446)されました。

{{< /history >}}

次のエンドポイントを使用して、プロジェクト承認ルールを更新できます。

```plaintext
PUT /projects/:id/approval_rules/:approval_rule_id
```

{{< alert type="note" >}}

承認者とグループ（`users`パラメーターまたは`groups`パラメーターにない非表示のグループを除く）は**削除**されます。非表示のグループとは、ユーザーが表示する権限を持っていないプライベートグループのことです。`remove_hidden_groups`パラメーターが`true`でない限り、非表示のグループはデフォルトで削除されません。これにより、ユーザーが承認ルールを更新するときに、非表示のグループが誤って削除されないようになります。

{{< /alert >}}

サポートされている属性:

| 属性                           | 型              | 必須 | 説明 |
|-------------------------------------|-------------------|----------|-------------|
| `id`                                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approvals_required`                | 整数           | はい      | このルールに必要な承認の数。 |
| `approval_rule_id`                  | 整数           | はい      | 承認ルールのID。 |
| `name`                              | 文字列            | はい      | 承認ルールの名前。1024文字に制限されています。 |
| `applies_to_all_protected_branches` | ブール値           | いいえ       | ルールをすべての保護ブランチに適用するかどうかを指定します。`true`に設定すると、`protected_branch_ids`の値は無視されます。GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/335316)されました。 |
| `group_ids`                         | 配列             | いいえ       | 承認者としてのグループのID。 |
| `protected_branch_ids`              | 配列             | いいえ       | ルールをスコープする保護ブランチのID。IDを識別するには、[APIを使用](protected_branches.md#list-protected-branches)します。 |
| `remove_hidden_groups`              | ブール値           | いいえ       | 非表示のグループを承認ルールから削除するかどうかを指定します。 |
| `user_ids`                          | 配列             | いいえ       | 承認者としてのユーザーのID。`user_ids`と`usernames`の両方を指定すると、ユーザーに関する両方のリストが追加されます。 |
| `usernames`                         | 文字列配列      | いいえ       | このルールの承認者のユーザー名（`user_ids`と同じですが、ユーザー名のリストが必要です）。`user_ids`と`usernames`の両方を指定すると、ユーザーに関する両方のリストが追加されます。 |

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

### プロジェクト承認ルールを削除する

次のエンドポイントを使用して、プロジェクト承認ルールを削除できます。

```plaintext
DELETE /projects/:id/approval_rules/:approval_rule_id
```

サポートされている属性:

| 属性          | 型              | 必須 | 説明 |
|--------------------|-------------------|----------|-------------|
| `id`               | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approval_rule_id` | 整数           | はい      | 承認ルールのID。 |

## 単一のマージリクエストの承認

特定のマージリクエストに関する承認の設定。すべてのエンドポイントで認証が必要です。

次のエンドポイントを使用して、マージリクエストの承認ステータスに関する情報をリクエストできます。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approvals
```

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
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
      }
    }
  ]
}
```

### マージリクエストの承認ステータスを取得する

次のエンドポイントを使用して、マージリクエストの承認ステータスに関する情報をリクエストできます。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_state
```

マージリクエストに対して、マージリクエストレベルのルールが作成されている場合、`approval_rules_overwritten`は`true`です。ルールがない場合は、`false`です。

これには、すでに承認したユーザー（`approved_by`）と、ルールがすでに承認されているかどうか（`approved`）に関する詳細情報が含まれます。

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
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

### マージリクエスト承認ルールを取得する

{{< history >}}

- ページネーションのサポートは、GitLab 15.3で`approval_rules_pagination`という名前の[フラグ](../administration/feature_flags.md)とともに導入されました。デフォルトで有効になっています。GitLabチームのメンバーは、この機密情報イシュー（`https://gitlab.com/gitlab-org/gitlab/-/issues/31011`）で詳細情報を確認できます。
- ページネーションのサポートは、GitLab 15.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/366823)になりました。機能フラグ`approval_rules_pagination`は削除されました。

{{< /history >}}

次のエンドポイントを使用して、マージリクエストの承認ルールに関する情報をリクエストできます。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメーターを使用して、承認ルールのリストを制限します。

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
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

### 単一のマージリクエストルールを取得する

次のエンドポイントを使用して、単一のマージリクエスト承認ルールに関する情報をリクエストできます。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
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

### マージリクエストルールを作成する

次のエンドポイントを使用して、マージリクエスト承認ルールを作成できます。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

サポートされている属性:

| 属性                  | 型              | 必須               | 説明                                                                  |
|----------------------------|-------------------|------------------------|------------------------------------------------------------------------------|
| `id`                       | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `approvals_required`       | 整数           | はい | このルールに必要な承認の数。                              |
| `merge_request_iid`        | 整数           | はい | マージリクエストのIID。                                                |
| `name`                     | 文字列            | はい | 承認ルールの名前。1024文字に制限されています。                                               |
| `approval_project_rule_id` | 整数           | いいえ | プロジェクトの承認ルールのID。                                     |
| `group_ids`                | 配列             | いいえ | 承認者としてのグループのID。                                              |
| `user_ids`                 | 配列             | いいえ | 承認者としてのユーザーのID。`user_ids`と`usernames`の両方を指定すると、ユーザーに関する両方のリストが追加されます。 |
| `usernames`                | 文字列配列      | いいえ | このルールの承認者のユーザー名（`user_ids`と同じですが、ユーザー名のリストが必要です）。`user_ids`と`usernames`の両方を指定すると、ユーザーに関する両方のリストが追加されます。 |

{{< alert type="note" >}}

`approval_project_rule_id`を設定すると、プロジェクトのルールの`name`、`users`、`groups`がコピーされます。指定した`approvals_required`を使用します。

{{< /alert >}}

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

### マージリクエストルールを更新する

マージリクエスト承認ルールを更新するには、次のエンドポイントを使用します。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

このエンドポイントは、`users`パラメーターまたは`groups`パラメーターにない承認者とグループを**削除**します。

これらのルールはシステムによって生成されるため、`report_approver`ルールまたは`code_owner`ルールを更新することはできません。

サポートされている属性:

| 属性              | 型              | 必須 | 説明 |
|------------------------|-------------------|----------|-------------|
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approval_rule_id`     | 整数           | はい      | 承認ルールのID。 |
| `merge_request_iid`    | 整数           | はい      | マージリクエストのIID。 |
| `approvals_required`   | 整数           | いいえ       | このルールに必要な承認の数。 |
| `group_ids`            | 配列             | いいえ       | 承認者としてのグループのID。 |
| `name`                 | 文字列            | いいえ       | 承認ルールの名前。1024文字に制限されています。 |
| `remove_hidden_groups` | ブール値           | いいえ       | 非表示のグループを削除するかどうかを指定します。 |
| `user_ids`             | 配列             | いいえ       | 承認者としてのユーザーのID。`user_ids`と`usernames`の両方を指定すると、ユーザーに関する両方のリストが追加されます。 |
| `usernames`            | 文字列配列      | いいえ       | このルールの承認者のユーザー名（`user_ids`と同じですが、ユーザー名のリストが必要です）。`user_ids`と`usernames`の両方を指定すると、ユーザーに関する両方のリストが追加されます。 |

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

### マージリクエストルールを削除する

次のエンドポイントを使用して、マージリクエスト承認ルールを削除できます。

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

これらのルールはシステムによって生成されるため、`report_approver`ルールまたは`code_owner`ルールを更新することはできません。

サポートされている属性:

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approval_rule_id`  | 整数           | はい      | 承認ルールのID。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストのIID。 |

## グループ承認ルール

{{< details >}}

- 状態: Experiment版

{{< /details >}}

{{< history >}}

- GitLab 16.7で`approval_group_rules`という名前の[フラグ](../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428051)されました。デフォルトでは無効になっています。この機能は[Experiment版](../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、この機能はデフォルトで使用できません。管理者が`approval_group_rules`という名前の[機能フラグを有効](../administration/feature_flags.md)にすると、利用できるようになります。GitLab.comとGitLab Dedicatedでは、この機能は使用できません。この機能は本番環境での使用には対応していません。

{{< /alert >}}

グループ承認ルールは、グループに属するプロジェクトのすべての保護ブランチに適用されます。この機能は[Experiment版](../policy/development_stages_support.md)です。

### グループ承認ルールを取得する

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440638)されました。

{{< /history >}}

グループ管理者は、次のエンドポイントを使用して、グループの承認ルールに関する情報をリクエストできます。

```plaintext
GET /groups/:id/approval_rules
```

`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメーターを使用して、承認ルールのリストを制限します。

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエストの例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules"
```

応答の例:

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

### グループ承認ルールを作成する

グループ管理者は、次のエンドポイントを使用して、グループの承認ルールを作成できます。

```plaintext
POST /groups/:id/approval_rules
```

サポートされている属性:

| 属性            | 型              | 必須 | 説明 |
|----------------------|-------------------|----------|-------------|
| `id`                 | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approvals_required` | 整数           | はい      | このルールに必要な承認の数。 |
| `name`               | 文字列            | はい      | 承認ルールの名前。1024文字に制限されています。 |
| `group_ids`          | 配列             | いいえ       | 承認者としてのグループのID。 |
| `rule_type`          | 文字列            | いいえ       | ルールタイプ。`any_approver`は、`approvals_required`が`0`の事前設定されたデフォルトルールです。その他のルールは、`regular`（通常の[マージリクエスト承認ルール](../user/project/merge_requests/approvals/rules.md)に使用されます）と`report_approver`です。このフィールドを使用して、APIから承認ルールを作成しないでください。`report_approver`フィールドは、GitLabが、設定および有効化された[マージリクエスト承認ポリシー](../user/application_security/policies/merge_request_approval_policies.md)から承認ルールを作成するときに使用されます。 |
| `user_ids`           | 配列             | いいえ       | 承認者としてのユーザーのID。 |

リクエストの例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules?name=security&approvals_required=2"
```

応答の例:

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

### グループ承認ルールを更新する

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440639)されました。

{{< /history >}}

グループ管理者は、次のエンドポイントを使用して、グループ承認ルールを更新できます。

```shell
PUT /groups/:id/approval_rules/:approval_rule_id
```

サポートされている属性:

| 属性            | 型              | 必須 | 説明 |
|----------------------|-------------------|----------|-------------|
| `approval_rule_id`  | 整数           | はい      | 承認ルールのID。 |
| `id`                 | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `approvals_required` | 文字列            | いいえ       | このルールに必要な承認の数。 |
| `group_ids`          | 整数           | いいえ       | 承認者としてのユーザーのID。 |
| `name`               | 文字列            | いいえ       | 承認ルールの名前。1024文字に制限されています。 |
| `rule_type`          | 配列             | いいえ       | ルールタイプ。`any_approver`は、`approvals_required`が`0`の事前設定されたデフォルトルールです。その他のルールは、`regular`（通常の[マージリクエスト承認ルール](../user/project/merge_requests/approvals/rules.md)に使用されます）と`report_approver`です。このフィールドを使用して、APIから承認ルールを作成しないでください。`report_approver`フィールドは、GitLabが、設定および有効化された[マージリクエスト承認ポリシー](../user/application_security/policies/merge_request_approval_policies.md)から承認ルールを作成するときに使用されます。 |
| `user_ids`           | 配列             | いいえ       | 承認者としてのグループのID。 |

リクエストの例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules/5?name=security2&approvals_required=1"
```

応答の例:

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
