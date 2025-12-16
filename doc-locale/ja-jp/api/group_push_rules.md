---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: プッシュルールを使用して、リポジトリが受け入れるGitコミットの内容と形式を制御します。コミットメッセージの標準を設定し、シークレットや認証情報が誤って追加されないようにします。
title: グループプッシュルール
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[プッシュルール](../user/group/access_and_permissions.md#group-push-rules)を使用して、リポジトリが受け入れるGitコミットの内容と形式を制御します。プッシュルールエンドポイントは、グループのオーナーと管理者のみが利用できます。

## グループのプッシュルールを取得します {#get-the-push-rules-of-a-group}

グループのプッシュルールを取得します。

```plaintext
GET /groups/:id/push_rule
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループの[URLエンコードされたパス](rest/_index.md#namespaced-paths)またはID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                         | 型    | 説明 |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | 文字列  | この正規表現に一致するコミットの作成者のメールアドレスのみを許可します。 |
| `branch_name_regex`               | 文字列  | この正規表現に一致するブランチ名のみを許可します。 |
| `commit_committer_check`          | ブール値 | `true`の場合、コミッターのメールが自分自身で確認済みのメールの1つである場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_committer_name_check`     | ブール値 | `true`の場合、コミットの作成者名が自分のGitLabアカウント名と一致する場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_message_negative_regex`   | 文字列  | この正規表現に一致するコミットメッセージを拒否します。 |
| `commit_message_regex`            | 文字列  | この正規表現に一致するコミットメッセージのみを許可します。 |
| `created_at`                      | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`                 | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`                 | 文字列  | この正規表現に一致するファイル名を拒否します。 |
| `id`                              | 整数 | プッシュルールのID。 |
| `max_file_size`                   | 整数 | 許可される最大ファイルサイズ（MB）。 |
| `member_check`                    | ブール値 | `true`の場合、GitLabユーザーのみがコミットを作成することを許可します。 |
| `prevent_secrets`                 | ブール値 | `true`の場合、シークレットが含まれている可能性のあるファイルを拒否します。 |
| `reject_non_dco_commits`          | ブール値 | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`         | ブール値 | `true`の場合、署名されていないコミットを拒否します。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/push_rule"
```

すべての設定が無効になっているプッシュルールが構成されている場合の応答例:

```json
{
  "id": 1,
  "created_at": "2020-08-17T19:09:19.580Z",
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": "[a-z]",
  "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
  "file_name_regex": "(exe)$",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "max_file_size": 0,
  "commit_committer_check": null,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": null,
  "reject_non_dco_commits": null
}
```

グループに対してプッシュルールが一度も構成されていない場合、[`404 Not Found`](rest/troubleshooting.md#status-codes)を返します:

```json
{
  "message": "404 Not Found"
}
```

{{< alert type="note" >}}

これは[プロジェクトのプッシュルール](project_push_rules.md#get-project-push-rules)とは異なり、プッシュルールが構成されていない場合、HTTP `200 OK`はリテラル文字列`"null"`を返します。

{{< /alert >}}

無効にすると、一部のブール型の属性は、`false`の代わりに`null`を返します。例: 

- `commit_committer_check`
- `reject_unsigned_commits`
- `reject_non_dco_commits`

## グループにプッシュルールを追加します {#add-push-rules-to-a-group}

プッシュルールをグループに追加します。これまでプッシュルールを定義していない場合にのみ使用してください。

```plaintext
POST /groups/:id/push_rule
```

サポートされている属性は以下のとおりです:

<!-- markdownlint-disable MD056 -->

| 属性                         | 型           | 必須 | 説明 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 整数または文字列 | はい   | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `author_email_regex`              | 文字列         | いいえ       | この属性で指定された正規表現に一致するコミットの作成者のメールアドレスのみを許可します（例: `@my-company.com$`）。 |
| `branch_name_regex`               | 文字列         | いいえ       | この属性で指定された正規表現に一致するブランチ名のみを許可します（例: `(feature\|hotfix)\/.*`）。 |
| `commit_committer_check`          | ブール値        | いいえ       | `true`の場合、コミッターのメールが自分自身で確認済みのメールの1つである場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_committer_name_check`     | ブール値        | いいえ       | `true`の場合、コミットの作成者名が自分のGitLabアカウント名と一致する場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_message_negative_regex`   | 文字列         | いいえ       | この属性で指定された正規表現に一致するコミットメッセージを拒否します（例: `ssh\:\/\/`）。 |
| `commit_message_regex`            | 文字列         | いいえ       | `true`の場合、この属性で指定された正規表現に一致するコミットメッセージのみを許可します（例: `Fixed \d+\..*`）。 |
| `deny_delete_tag`                 | ブール値        | いいえ       | タグの削除を拒否します。 |
| `file_name_regex`                 | 文字列         | いいえ       | この属性で指定された正規表現に一致するファイル名を拒否します（例: `(jar\|exe)$`）。 |
| `max_file_size`                   | 整数        | いいえ       | 許可される最大ファイルサイズ（MB）。 |
| `member_check`                    | ブール値        | いいえ       | `true`の場合、GitLabユーザーのみがコミットを作成することを許可します。 |
| `prevent_secrets`                 | ブール値        | いいえ       | `true`の場合、シークレットを[含む](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml)可能性のあるファイルを拒否します。 |
| `reject_non_dco_commits`          | ブール値        | いいえ       | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`         | ブール値        | いいえ       | `true`の場合、署名されていないコミットを拒否します。 |

<!-- markdownlint-enable MD056 -->

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                         | 型    | 説明 |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | 文字列  | この正規表現に一致するコミットの作成者のメールアドレスのみを許可します。 |
| `branch_name_regex`               | 文字列  | この正規表現に一致するブランチ名のみを許可します。 |
| `commit_committer_check`          | ブール値 | `true`の場合、コミッターのメールが自分自身で確認済みのメールの1つである場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_committer_name_check`     | ブール値 | `true`の場合、コミットの作成者名が自分のGitLabアカウント名と一致する場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_message_negative_regex`   | 文字列  | この正規表現に一致するコミットメッセージを拒否します。 |
| `commit_message_regex`            | 文字列  | `true`の場合、この正規表現に一致するコミットメッセージのみを許可します。 |
| `created_at`                      | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`                 | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`                 | 文字列  | この正規表現に一致するファイル名を拒否します。 |
| `id`                              | 整数 | プッシュルールのID。 |
| `max_file_size`                   | 整数 | 許可される最大ファイルサイズ（MB）。 |
| `member_check`                    | ブール値 | `true`の場合、GitLabユーザーのみがコミットを作成することを許可します。 |
| `prevent_secrets`                 | ブール値 | `true`の場合、シークレットが含まれている可能性のあるファイルを拒否します。 |
| `reject_non_dco_commits`          | ブール値 | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`         | ブール値 | `true`の場合、署名されていないコミットを拒否します。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule?prevent_secrets=true"
```

レスポンス例:

```json
{
  "id": 1,
  "created_at": "2020-08-31T15:53:00.073Z",
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false,
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": null,
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": true,
  "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
  "file_name_regex": null,
  "max_file_size": 100
}
```

## グループのプッシュルールを編集します {#edit-the-push-rules-of-a-group}

グループのプッシュルールを編集します。

```plaintext
PUT /groups/:id/push_rule
```

サポートされている属性は以下のとおりです:

<!-- markdownlint-disable MD056 -->

| 属性                         | 型           | 必須 | 説明 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 整数または文字列 | はい   | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `author_email_regex`              | 文字列         | いいえ       | この属性で指定された正規表現に一致するコミットの作成者のメールアドレスのみを許可します（例: `@my-company.com$`）。 |
| `branch_name_regex`               | 文字列         | いいえ       | この属性で指定された正規表現に一致するブランチ名のみを許可します（例: `(feature\|hotfix)\/.*`）。 |
| `commit_committer_check`          | ブール値        | いいえ       | `true`の場合、コミッターのメールが自分自身で確認済みのメールの1つである場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_committer_name_check`     | ブール値        | いいえ       | `true`の場合、コミットの作成者名が自分のGitLabアカウント名と一致する場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_message_negative_regex`   | 文字列         | いいえ       | この属性で指定された正規表現に一致するコミットメッセージを拒否します（例: `ssh\:\/\/`）。 |
| `commit_message_regex`            | 文字列         | いいえ       | `true`の場合、この属性で指定された正規表現に一致するコミットメッセージのみを許可します（例: `Fixed \d+\..*`）。 |
| `deny_delete_tag`                 | ブール値        | いいえ       | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`                 | 文字列         | いいえ       | この属性で指定された正規表現に一致するファイル名を拒否します（例: `(jar\|exe)$`）。 |
| `max_file_size`                   | 整数        | いいえ       | 許可される最大ファイルサイズ（MB）。 |
| `member_check`                    | ブール値        | いいえ       | `true`の場合、GitLabユーザーのみがコミットを作成することを許可します。 |
| `prevent_secrets`                 | ブール値        | いいえ       | `true`の場合、シークレットを[含む](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml)可能性のあるファイルを拒否します。 |
| `reject_non_dco_commits`          | ブール値        | いいえ       | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`         | ブール値        | いいえ       | `true`の場合、署名されていないコミットを拒否します。 |

<!-- markdownlint-enable MD056 -->

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                         | 型    | 説明 |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | 文字列  | この正規表現に一致するコミットの作成者のメールアドレスのみを許可します。 |
| `branch_name_regex`               | 文字列  | この正規表現に一致するブランチ名のみを許可します。 |
| `commit_committer_check`          | ブール値 | `true`の場合、コミッターのメールが自分自身で確認済みのメールの1つである場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_committer_name_check`     | ブール値 | `true`の場合、コミットの作成者名が自分のGitLabアカウント名と一致する場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_message_negative_regex`   | 文字列  | この正規表現に一致するコミットメッセージを拒否します。 |
| `commit_message_regex`            | 文字列  | `true`の場合、この正規表現に一致するコミットメッセージのみを許可します。 |
| `created_at`                      | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`                 | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`                 | 文字列  | この正規表現に一致するファイル名を拒否します。 |
| `id`                              | 整数 | プッシュルールのID。 |
| `max_file_size`                   | 整数 | 許可される最大ファイルサイズ（MB）。 |
| `member_check`                    | ブール値 | `true`の場合、GitLabユーザーのみがコミットを作成することを許可します。 |
| `prevent_secrets`                 | ブール値 | `true`の場合、シークレットが含まれている可能性のあるファイルを拒否します。 |
| `reject_non_dco_commits`          | ブール値 | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`         | ブール値 | `true`の場合、署名されていないコミットを拒否します。 |

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule?member_check=true"
```

レスポンス例:

```json
{
  "id": 19,
  "created_at": "2020-08-31T15:53:00.073Z",
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false,
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": null,
  "deny_delete_tag": false,
  "member_check": true,
  "prevent_secrets": false,
  "author_email_regex": "^[A-Za-z0-9.]+@staging.gitlab.com$",
  "file_name_regex": null,
  "max_file_size": 100
}
```

## グループのプッシュルールを削除します {#delete-the-push-rules-of-a-group}

グループのすべてのプッシュルールを削除します。

```plaintext
DELETE /groups/:id/push_rule
```

サポートされている属性は以下のとおりです:

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功すると、応答本文なしで[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule"
```
