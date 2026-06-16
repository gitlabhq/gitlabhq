---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトプッシュルールAPI
description: コミット標準の適用、メッセージの検証、シークレットの防止、およびリポジトリ操作の制御のために、プロジェクトのプッシュルールを管理します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、プロジェクトの[プッシュルール](../user/project/repository/push_rules.md)を管理します。

> [!note]
> GitLabは、プッシュルール内のすべての正規表現に[RE2構文](https://github.com/google/re2/wiki/Syntax)を使用します。

## プロジェクトのプッシュルールを取得する {#retrieve-the-push-rules-of-a-project}

指定されたプロジェクトのプッシュルールを取得する。

```plaintext
GET /projects/:id/push_rule
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                       | 型    | 説明 |
|---------------------------------|---------|-------------|
| `author_email_regex`            | 文字列  | すべてのコミット作成者メールアドレスは、この正規表現に一致する必要があります。 |
| `branch_name_regex`             | 文字列  | すべてのブランチ名は、この正規表現に一致する必要があります。 |
| `commit_committer_check`        | ブール値 | `true`の場合、コミッターメールアドレスがユーザー自身の検証済みメールアドレスのいずれかである場合に限り、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_committer_name_check`   | ブール値 | `true`の場合、コミット作成者名がGitLabアカウント名と一致する場合に限り、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_message_negative_regex` | 文字列  | どのコミットメッセージも、この正規表現に一致することはできません。 |
| `commit_message_regex`          | 文字列  | すべてのコミットメッセージは、この正規表現に一致する必要があります。 |
| `created_at`                    | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`               | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`               | 文字列  | すべてのコミット済みファイル名は、この正規表現に一致してはなりません。 |
| `id`                            | 整数 | プッシュルールのID。 |
| `max_file_size`                 | 整数 | 最大ファイルサイズ（MB）。 |
| `member_check`                  | ブール値 | `true`の場合、作成者（メール）によるコミットを既存のGitLabユーザーに制限します。 |
| `prevent_secrets`               | ブール値 | `true`の場合、GitLabはシークレットを含む可能性のあるファイルをすべて拒否します。 |
| `project_id`                    | 整数 | プロジェクトのID。 |
| `reject_non_dco_commits`        | ブール値 | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`       | ブール値 | `true`の場合、署名されていないコミットを拒否します。 |

プロジェクトに対してプッシュルールが一度も設定されていない場合、HTTP `200 OK`と、レスポンスボディとしてリテラル文字列`"null"`が返されます。

> [!note]
> これは、`404 Not Found`エラーを返す[グループプッシュルールAPI](group_push_rules.md#retrieve-the-push-rules-of-a-group)とは異なります。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule"
```

すべての設定が無効になっているプッシュルールが設定されている場合のレスポンス例:

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "ssh\\:\\/\\/",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": null,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": null,
  "reject_non_dco_commits": null
}
```

次の属性が無効になっている場合、それらは`false`の代わりに`null`を返します:

- `commit_committer_check`
- `reject_unsigned_commits`
- `reject_non_dco_commits`

プッシュルールがプロジェクトに対して一度も設定されていない場合のレスポンス例:

```plaintext
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 4

null
```

これはリテラル文字列`"null"`（4文字）を返し、JSON `null`値ではありません。

## プロジェクトにプッシュルールを追加する {#add-push-rules-to-a-project}

指定されたプロジェクトにプッシュルールを追加します。

```plaintext
POST /projects/:id/push_rule
```

サポートされている属性は以下のとおりです: 

| 属性                       | 型              | 必須 | 説明 |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `author_email_regex`            | 文字列            | いいえ       | すべてのコミット作成者メールアドレスは、この正規表現に一致する必要があります。 |
| `branch_name_regex`             | 文字列            | いいえ       | すべてのブランチ名は、この正規表現に一致する必要があります。 |
| `commit_committer_check`        | ブール値           | いいえ       | `true`の場合、コミッターメールアドレスがユーザー自身の検証済みメールアドレスのいずれかである場合に限り、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_committer_name_check`   | ブール値           | いいえ       | `true`の場合、コミット作成者名がGitLabアカウント名と一致する場合に限り、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_message_negative_regex` | 文字列            | いいえ       | どのコミットメッセージも、この正規表現に一致することはできません。 |
| `commit_message_regex`          | 文字列            | いいえ       | すべてのコミットメッセージは、この正規表現に一致する必要があります。 |
| `deny_delete_tag`               | ブール値           | いいえ       | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`               | 文字列            | いいえ       | すべてのコミット済みファイル名は、この正規表現に一致してはなりません。 |
| `max_file_size`                 | 整数           | いいえ       | 最大ファイルサイズ（MB）。 |
| `member_check`                  | ブール値           | いいえ       | `true`の場合、作成者（メール）によるコミットを既存のGitLabユーザーに制限します。 |
| `prevent_secrets`               | ブール値           | いいえ       | `true`の場合、GitLabはシークレットを含む可能性のあるファイルをすべて拒否します。 |
| `reject_non_dco_commits`        | ブール値           | いいえ       | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`       | ブール値           | いいえ       | `true`の場合、署名されていないコミットを拒否します。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                       | 型    | 説明 |
|---------------------------------|---------|-------------|
| `author_email_regex`            | 文字列  | すべてのコミット作成者メールアドレスは、この正規表現に一致する必要があります。 |
| `branch_name_regex`             | 文字列  | すべてのブランチ名は、この正規表現に一致する必要があります。 |
| `commit_committer_check`        | ブール値 | `true`の場合、コミッターメールアドレスがユーザー自身の検証済みメールアドレスのいずれかである場合に限り、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_committer_name_check`   | ブール値 | `true`の場合、コミット作成者名がGitLabアカウント名と一致する場合に限り、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_message_negative_regex` | 文字列  | どのコミットメッセージも、この正規表現に一致することはできません。 |
| `commit_message_regex`          | 文字列  | すべてのコミットメッセージは、この正規表現に一致する必要があります。 |
| `created_at`                    | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`               | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`               | 文字列  | すべてのコミット済みファイル名は、この正規表現に一致してはなりません。 |
| `id`                            | 整数 | プッシュルールのID。 |
| `max_file_size`                 | 整数 | 最大ファイルサイズ（MB）。 |
| `member_check`                  | ブール値 | `true`の場合、作成者（メール）によるコミットを既存のGitLabユーザーに制限します。 |
| `prevent_secrets`               | ブール値 | `true`の場合、GitLabはシークレットを含む可能性のあるファイルをすべて拒否します。 |
| `project_id`                    | 整数 | プロジェクトのID。 |
| `reject_non_dco_commits`        | ブール値 | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`       | ブール値 | `true`の場合、署名されていないコミットを拒否します。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule" \
  --data "commit_message_regex=Fixes \\d+\\..*" \
  --data "deny_delete_tag=false"
```

レスポンス例: 

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false
}
```

## プロジェクトのプッシュルールを更新する {#update-push-rules-of-a-project}

指定されたプロジェクトのプッシュルールを更新します。

```plaintext
PUT /projects/:id/push_rule
```

サポートされている属性は以下のとおりです: 

| 属性                       | 型              | 必須 | 説明 |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `author_email_regex`            | 文字列            | いいえ       | すべてのコミット作成者メールアドレスは、この正規表現に一致する必要があります。 |
| `branch_name_regex`             | 文字列            | いいえ       | すべてのブランチ名は、この正規表現に一致する必要があります。 |
| `commit_committer_check`        | ブール値           | いいえ       | `true`の場合、コミッターメールアドレスがユーザー自身の検証済みメールアドレスのいずれかである場合に限り、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_committer_name_check`   | ブール値           | いいえ       | `true`の場合、コミット作成者名がGitLabアカウント名と一致する場合に限り、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_message_negative_regex` | 文字列            | いいえ       | どのコミットメッセージも、この正規表現に一致することはできません。 |
| `commit_message_regex`          | 文字列            | いいえ       | すべてのコミットメッセージは、この正規表現に一致する必要があります。 |
| `deny_delete_tag`               | ブール値           | いいえ       | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`               | 文字列            | いいえ       | すべてのコミット済みファイル名は、この正規表現に一致してはなりません。 |
| `max_file_size`                 | 整数           | いいえ       | 最大ファイルサイズ（MB）。 |
| `member_check`                  | ブール値           | いいえ       | `true`の場合、作成者（メール）によるコミットを既存のGitLabユーザーに制限します。 |
| `prevent_secrets`               | ブール値           | いいえ       | `true`の場合、GitLabはシークレットを含む可能性のあるファイルをすべて拒否します。 |
| `reject_non_dco_commits`        | ブール値           | いいえ       | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`       | ブール値           | いいえ       | `true`の場合、署名されていないコミットを拒否します。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                       | 型    | 説明 |
|---------------------------------|---------|-------------|
| `author_email_regex`            | 文字列  | すべてのコミット作成者メールアドレスは、この正規表現に一致する必要があります。 |
| `branch_name_regex`             | 文字列  | すべてのブランチ名は、この正規表現に一致する必要があります。 |
| `commit_committer_check`        | ブール値 | `true`の場合、コミッターメールアドレスがユーザー自身の検証済みメールアドレスのいずれかである場合に限り、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_committer_name_check`   | ブール値 | `true`の場合、コミット作成者名がGitLabアカウント名と一致する場合に限り、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_message_negative_regex` | 文字列  | どのコミットメッセージも、この正規表現に一致することはできません。 |
| `commit_message_regex`          | 文字列  | すべてのコミットメッセージは、この正規表現に一致する必要があります。 |
| `created_at`                    | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`               | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`               | 文字列  | すべてのコミット済みファイル名は、この正規表現に一致してはなりません。 |
| `id`                            | 整数 | プッシュルールのID。 |
| `max_file_size`                 | 整数 | 最大ファイルサイズ（MB）。 |
| `member_check`                  | ブール値 | `true`の場合、作成者（メール）によるコミットを既存のGitLabユーザーに制限します。 |
| `prevent_secrets`               | ブール値 | `true`の場合、GitLabはシークレットを含む可能性のあるファイルをすべて拒否します。 |
| `project_id`                    | 整数 | プロジェクトのID。 |
| `reject_non_dco_commits`        | ブール値 | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`       | ブール値 | `true`の場合、署名されていないコミットを拒否します。 |

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule" \
  --data "commit_message_regex=Fixes \\d+\\..*" \
  --data "deny_delete_tag=true"
```

レスポンス例: 

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "",
  "branch_name_regex": "",
  "deny_delete_tag": true,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false
}
```

## プロジェクトのプッシュルールを削除する {#delete-the-push-rules-of-a-project}

指定されたプロジェクトのすべてのプッシュルールを削除します。

```plaintext
DELETE /projects/:id/push_rule
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule"
```
