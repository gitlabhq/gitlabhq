---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトプッシュルールAPI
description: プロジェクトプッシュルールを管理して、コミットの標準を適用し、メッセージを検証し、シークレットを防止し、リポジトリ操作を制御します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトのプッシュルールAPIを使用して、[プロジェクトのプッシュルール](../user/project/repository/push_rules.md)を管理します。

{{< alert type="note" >}}

GitLabのプッシュルールの正規表現では、[RE2構文](https://github.com/google/re2/wiki/Syntax)を使用します。

{{< /alert >}}

## プロジェクトプッシュルールを取得 {#get-project-push-rules}

プロジェクトのプッシュルールを取得します。

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
| `author_email_regex`            | 文字列  | すべてのコミット作成者のメールは、この正規表現と一致する必要があります。 |
| `branch_name_regex`             | 文字列  | すべてのブランチ名は、この正規表現と一致する必要があります。 |
| `commit_committer_check`        | ブール値 | `true`の場合、コミッターのメールが自分自身で検証済みのメールのいずれかである場合、ユーザーはリポジトリにコミットをプッシュできます。 |
| `commit_committer_name_check`   | ブール値 | `true`の場合、コミット作成者名が自分のGitLabアカウント名と一致する場合、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_message_negative_regex` | 文字列  | どのコミットメッセージも、この正規表現と一致することは許可されていません。 |
| `commit_message_regex`          | 文字列  | すべてのコミットメッセージは、この正規表現と一致する必要があります。 |
| `created_at`                    | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`               | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`               | 文字列  | すべてのコミットされたファイル名は、この正規表現と一致してはなりません。 |
| `id`                            | 整数 | プッシュルールのID。 |
| `max_file_size`                 | 整数 | 最大ファイルサイズ（MB）。 |
| `member_check`                  | ブール値 | `true`の場合、作成者（メール）によるコミットを既存のGitLabユーザーに制限します。 |
| `prevent_secrets`               | ブール値 | `true`の場合、GitLabは、シークレットが含まれている可能性のあるファイルを拒否します。 |
| `project_id`                    | 整数 | プロジェクトのID。 |
| `reject_non_dco_commits`        | ブール値 | `true`の場合、DCO認定されていないコミットを拒否します。 |
| `reject_unsigned_commits`       | ブール値 | `true`の場合、署名されていないコミットを拒否します。 |

プロジェクトにプッシュルールが設定されていない場合、HTTP `200 OK`と、レスポンス本文としてリテラル文字列`"null"`が返されます。

{{< alert type="note" >}}

これは[グループプッシュルールAPI](group_push_rules.md#get-the-push-rules-of-a-group)とは異なり、`404 Not Found`エラーを返します。

{{< /alert >}}

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule"
```

すべての設定が無効になっているプッシュルールが構成されている場合の応答例:

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

次の属性が無効になっている場合、`false`ではなく`null`が返されます:

- `commit_committer_check`
- `reject_unsigned_commits`
- `reject_non_dco_commits`

プッシュルールがプロジェクトに設定されていない場合の応答例:

```plaintext
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 4

null
```

これは、JSON `null`値ではなく、リテラル文字列`"null"`（4文字）を返します。

## プロジェクトプッシュルールを追加 {#add-a-project-push-rule}

指定されたプロジェクトにプッシュルールを追加します。

```plaintext
POST /projects/:id/push_rule
```

サポートされている属性は以下のとおりです:

| 属性                       | 型              | 必須 | 説明 |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `author_email_regex`            | 文字列            | いいえ       | すべてのコミット作成者のメールは、この正規表現と一致する必要があります。 |
| `branch_name_regex`             | 文字列            | いいえ       | すべてのブランチ名は、この正規表現と一致する必要があります。 |
| `commit_committer_check`        | ブール値           | いいえ       | `true`の場合、コミッターのメールが自分自身で検証済みのメールのいずれかである場合、ユーザーはリポジトリにコミットをプッシュできます。 |
| `commit_committer_name_check`   | ブール値           | いいえ       | `true`の場合、コミット作成者名が自分のGitLabアカウント名と一致する場合、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_message_negative_regex` | 文字列            | いいえ       | どのコミットメッセージも、この正規表現と一致することは許可されていません。 |
| `commit_message_regex`          | 文字列            | いいえ       | すべてのコミットメッセージは、この正規表現と一致する必要があります。 |
| `deny_delete_tag`               | ブール値           | いいえ       | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`               | 文字列            | いいえ       | すべてのコミットされたファイル名は、この正規表現と一致してはなりません。 |
| `max_file_size`                 | 整数           | いいえ       | 最大ファイルサイズ（MB）。 |
| `member_check`                  | ブール値           | いいえ       | `true`の場合、作成者（メール）によるコミットを既存のGitLabユーザーに制限します。 |
| `prevent_secrets`               | ブール値           | いいえ       | `true`の場合、GitLabは、シークレットが含まれている可能性のあるファイルを拒否します。 |
| `reject_non_dco_commits`        | ブール値           | いいえ       | `true`の場合、DCO認定されていないコミットを拒否します。 |
| `reject_unsigned_commits`       | ブール値           | いいえ       | `true`の場合、署名されていないコミットを拒否します。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                       | 型    | 説明 |
|---------------------------------|---------|-------------|
| `author_email_regex`            | 文字列  | すべてのコミット作成者のメールは、この正規表現と一致する必要があります。 |
| `branch_name_regex`             | 文字列  | すべてのブランチ名は、この正規表現と一致する必要があります。 |
| `commit_committer_check`        | ブール値 | `true`の場合、コミッターのメールが自分自身で検証済みのメールのいずれかである場合、ユーザーはリポジトリにコミットをプッシュできます。 |
| `commit_committer_name_check`   | ブール値 | `true`の場合、コミット作成者名が自分のGitLabアカウント名と一致する場合、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_message_negative_regex` | 文字列  | どのコミットメッセージも、この正規表現と一致することは許可されていません。 |
| `commit_message_regex`          | 文字列  | すべてのコミットメッセージは、この正規表現と一致する必要があります。 |
| `created_at`                    | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`               | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`               | 文字列  | すべてのコミットされたファイル名は、この正規表現と一致してはなりません。 |
| `id`                            | 整数 | プッシュルールのID。 |
| `max_file_size`                 | 整数 | 最大ファイルサイズ（MB）。 |
| `member_check`                  | ブール値 | `true`の場合、作成者（メール）によるコミットを既存のGitLabユーザーに制限します。 |
| `prevent_secrets`               | ブール値 | `true`の場合、GitLabは、シークレットが含まれている可能性のあるファイルを拒否します。 |
| `project_id`                    | 整数 | プロジェクトのID。 |
| `reject_non_dco_commits`        | ブール値 | `true`の場合、DCO認定されていないコミットを拒否します。 |
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

## プロジェクトプッシュルールを編集 {#edit-project-push-rule}

指定されたプロジェクトのプッシュルールを編集します。

```plaintext
PUT /projects/:id/push_rule
```

サポートされている属性は以下のとおりです:

| 属性                       | 型              | 必須 | 説明 |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `author_email_regex`            | 文字列            | いいえ       | すべてのコミット作成者のメールは、この正規表現と一致する必要があります。 |
| `branch_name_regex`             | 文字列            | いいえ       | すべてのブランチ名は、この正規表現と一致する必要があります。 |
| `commit_committer_check`        | ブール値           | いいえ       | `true`の場合、コミッターのメールが自分自身で検証済みのメールのいずれかである場合、ユーザーはリポジトリにコミットをプッシュできます。 |
| `commit_committer_name_check`   | ブール値           | いいえ       | `true`の場合、コミット作成者名が自分のGitLabアカウント名と一致する場合、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_message_negative_regex` | 文字列            | いいえ       | どのコミットメッセージも、この正規表現と一致することは許可されていません。 |
| `commit_message_regex`          | 文字列            | いいえ       | すべてのコミットメッセージは、この正規表現と一致する必要があります。 |
| `deny_delete_tag`               | ブール値           | いいえ       | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`               | 文字列            | いいえ       | すべてのコミットされたファイル名は、この正規表現と一致してはなりません。 |
| `max_file_size`                 | 整数           | いいえ       | 最大ファイルサイズ（MB）。 |
| `member_check`                  | ブール値           | いいえ       | `true`の場合、作成者（メール）によるコミットを既存のGitLabユーザーに制限します。 |
| `prevent_secrets`               | ブール値           | いいえ       | `true`の場合、GitLabは、シークレットが含まれている可能性のあるファイルを拒否します。 |
| `reject_non_dco_commits`        | ブール値           | いいえ       | `true`の場合、DCO認定されていないコミットを拒否します。 |
| `reject_unsigned_commits`       | ブール値           | いいえ       | `true`の場合、署名されていないコミットを拒否します。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                       | 型    | 説明 |
|---------------------------------|---------|-------------|
| `author_email_regex`            | 文字列  | すべてのコミット作成者のメールは、この正規表現と一致する必要があります。 |
| `branch_name_regex`             | 文字列  | すべてのブランチ名は、この正規表現と一致する必要があります。 |
| `commit_committer_check`        | ブール値 | `true`の場合、コミッターのメールが自分自身で検証済みのメールのいずれかである場合、ユーザーはリポジトリにコミットをプッシュできます。 |
| `commit_committer_name_check`   | ブール値 | `true`の場合、コミット作成者名が自分のGitLabアカウント名と一致する場合、ユーザーはこのリポジトリにコミットをプッシュできます。 |
| `commit_message_negative_regex` | 文字列  | どのコミットメッセージも、この正規表現と一致することは許可されていません。 |
| `commit_message_regex`          | 文字列  | すべてのコミットメッセージは、この正規表現と一致する必要があります。 |
| `created_at`                    | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`               | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`               | 文字列  | すべてのコミットされたファイル名は、この正規表現と一致してはなりません。 |
| `id`                            | 整数 | プッシュルールのID。 |
| `max_file_size`                 | 整数 | 最大ファイルサイズ（MB）。 |
| `member_check`                  | ブール値 | `true`の場合、作成者（メール）によるコミットを既存のGitLabユーザーに制限します。 |
| `prevent_secrets`               | ブール値 | `true`の場合、GitLabは、シークレットが含まれている可能性のあるファイルを拒否します。 |
| `project_id`                    | 整数 | プロジェクトのID。 |
| `reject_non_dco_commits`        | ブール値 | `true`の場合、DCO認定されていないコミットを拒否します。 |
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

## プロジェクトプッシュルールを削除 {#delete-project-push-rule}

プロジェクトからプッシュルールを削除します。

```plaintext
DELETE /projects/:id/push_rule
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule"
```
