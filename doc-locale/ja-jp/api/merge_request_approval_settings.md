---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのマージリクエストの承認設定に関するREST APIのドキュメント。
title: マージリクエスト承認設定API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループまたはプロジェクト内の[すべてのマージリクエストに対する承認設定](../user/project/merge_requests/approvals/settings.md)の設定です。すべてのエンドポイントで認証が必要です。

## グループマージリクエスト承認設定 {#group-mr-approval-settings}

前提要件: 

- グループのオーナーロールを持っている必要があります。

### グループマージリクエスト承認設定を取得 {#get-group-mr-approval-settings}

グループのマージリクエスト承認設定を取得します。

```plaintext
GET /groups/:id/merge_request_approval_setting
```

パラメータは以下のとおりです:

| 属性        | 型           | 必須 | 説明 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/merge_request_approval_setting"
```

レスポンス例:

```json
{
  "allow_author_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

### グループマージリクエスト承認設定を更新 {#update-group-mr-approval-settings}

グループのマージリクエスト承認設定を更新します。

```plaintext
PUT /groups/:id/merge_request_approval_setting
```

パラメータは以下のとおりです:

| 属性                                            | 型              | 必須 | 説明 |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `allow_author_approval`                              | ブール値           | いいえ       | 作成者がマージリクエストを自己承認することを許可または禁止します。`true`は、作成者が自己承認できることを意味します。 |
| `allow_committer_approval`                           | ブール値           | いいえ       | コミッターがマージリクエストを自己承認することを許可または禁止します。 |
| `allow_overrides_to_approver_list_per_merge_request` | ブール値           | いいえ       | マージリクエストごとに承認者をオーバーライドすることを許可または禁止します。 |
| `retain_approvals_on_push`                           | ブール値           | いいえ       | 新しいプッシュで承認数を保持します。 |
| `require_reauthentication_to_approve`                | ブール値           | いいえ       | 承認者が承認を追加する前に認証を必須とする。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/431346)されました。 |

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/merge_request_approval_setting?allow_author_approval=false"
```

レスポンス例:

```json
{
  "allow_author_approval": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

## プロジェクトマージリクエスト承認設定 {#project-mr-approval-settings}

前提要件: 

- プロジェクトのメンテナーロールが必要です。

### プロジェクトマージリクエスト承認設定を取得 {#get-project-mr-approval-settings}

プロジェクトのマージリクエスト承認設定を取得します。

```plaintext
GET /projects/:id/merge_request_approval_setting
```

パラメータは以下のとおりです:

| 属性        | 型           | 必須 | 説明 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/merge_request_approval_setting"
```

レスポンス例:

```json
{
  "allow_author_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": true,
    "inherited_from": "group"
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

### プロジェクトマージリクエスト承認設定を更新 {#update-project-mr-approval-settings}

プロジェクトのマージリクエスト承認設定を更新します。

```plaintext
PUT /projects/:id/merge_request_approval_setting
```

パラメータは以下のとおりです:

| 属性                                            | 型              | 必須 | 説明 |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `allow_author_approval`                              | ブール値           | いいえ       | 作成者がマージリクエストを自己承認することを許可または禁止します。`true`は、作成者が自己承認できることを意味します。 |
| `allow_committer_approval`                           | ブール値           | いいえ       | コミッターがマージリクエストを自己承認することを許可または禁止します。 |
| `allow_overrides_to_approver_list_per_merge_request` | ブール値           | いいえ       | マージリクエストごとに承認者をオーバーライドすることを許可または禁止します。 |
| `retain_approvals_on_push`                           | ブール値           | いいえ       | 新しいプッシュで承認数を保持します。 |
| `selective_code_owner_removals`                      | ブール値           | いいえ       | GitLabコードオーナーのファイルが変更された場合、GitLabコードオーナーからの承認をリセットします。このフィールドを使用するには、`retain_approvals_on_push`フィールドを無効にする必要があります。 |
| `require_reauthentication_to_approve`                | ブール値           | いいえ       | 承認者が承認を追加する前に認証を必須とする。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/431346)されました。 |

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/merge_request_approval_setting?allow_author_approval=false"
```

レスポンス例:

```json
{
  "allow_author_approval": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```
