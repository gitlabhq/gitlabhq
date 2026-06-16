---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: プッシュルールを使用して、リポジトリが受け入れるGitコミットの内容と形式を制御します。コミットメッセージの標準を設定し、シークレットや認証情報が誤って追加されないようにします。
title: グループプッシュルールAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、グループ内の新規作成プロジェクトの[グループプッシュルール](../user/project/repository/push_rules.md#group-push-rules)を管理します。

前提条件: 

- グループのオーナーロールを持つか、インスタンスの管理者である必要があります。

## グループのプッシュルールを取得する {#retrieve-the-push-rules-of-a-group}

指定されたグループのプッシュルールを取得する。

```plaintext
GET /groups/:id/push_rule
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのID、またはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                         | 型    | 説明 |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | 文字列  | この正規表現に一致するコミット作成者のメールアドレスのみを許可します。 |
| `branch_name_regex`               | 文字列  | この正規表現に一致するブランチ名のみを許可します。 |
| `commit_committer_check`          | ブール値 | `true`の場合、コミッターのメールアドレスが自身の検証済みメールアドレスのいずれかである場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_committer_name_check`     | ブール値 | `true`の場合、コミット作成者名がGitLabアカウント名と一致する場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_message_negative_regex`   | 文字列  | この正規表現に一致するコミットメッセージを拒否します。 |
| `commit_message_regex`            | 文字列  | この正規表現に一致するコミットメッセージのみを許可します。 |
| `created_at`                      | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`                 | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`                 | 文字列  | この正規表現に一致するファイル名を拒否します。 |
| `id`                              | 整数 | プッシュルールのID。 |
| `max_file_size`                   | 整数 | 許可される最大ファイルサイズ（MB）。 |
| `member_check`                    | ブール値 | `true`の場合、GitLabユーザーのみがコミットを作成者できます。 |
| `prevent_secrets`                 | ブール値 | `true`の場合、シークレットを含む可能性のあるファイルを拒否します。 |
| `reject_non_dco_commits`          | ブール値 | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`         | ブール値 | `true`の場合、署名されていないコミットを拒否します。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/push_rule"
```

すべての設定が無効になっている場合にプッシュルールが構成されている場合の応答例:

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

グループにプッシュルールが構成されていない場合、[`404 Not Found`](rest/troubleshooting.md#status-codes)を返します:

```json
{
  "message": "404 Not Found"
}
```

> [!note]
> これは、[プロジェクトプッシュルールAPI](project_push_rules.md#retrieve-the-push-rules-of-a-project)とは異なります。このAPIは、プッシュルールが構成されていない場合に、リテラル文字列`"null"`とともにHTTP `200 OK`を返します。

無効になっている場合、一部のブール属性は`false`ではなく`null`を返します。例: 

- `commit_committer_check`
- `reject_unsigned_commits`
- `reject_non_dco_commits`

## グループにプッシュルールを追加する {#add-push-rules-to-a-group}

指定されたグループにプッシュルールを追加します。これまでにプッシュルールを定義していない場合にのみ使用してください。

```plaintext
POST /groups/:id/push_rule
```

サポートされている属性は以下のとおりです: 

| 属性                         | 型           | 必須 | 説明 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 整数または文字列 | はい   | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `author_email_regex`              | 文字列         | いいえ       | この属性で提供される正規表現に一致するコミット作成者のメールアドレスのみを許可します。`@my-company.com$`など。 |
| `branch_name_regex`               | 文字列         | いいえ       | この属性で提供される正規表現に一致するブランチ名のみを許可します。`(feature\|hotfix)\/.*`など。 |
| `commit_committer_check`          | ブール値        | いいえ       | `true`の場合、コミッターのメールアドレスが自身の検証済みメールアドレスのいずれかである場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_committer_name_check`     | ブール値        | いいえ       | `true`の場合、コミット作成者名がGitLabアカウント名と一致する場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_message_negative_regex`   | 文字列         | いいえ       | この属性で提供される正規表現に一致するコミットメッセージを拒否します。`ssh\:\/\/`など。 |
| `commit_message_regex`            | 文字列         | いいえ       | `true`の場合、この属性で提供される正規表現に一致するコミットメッセージのみを許可します。`Fixed \d+\..*`など。 |
| `deny_delete_tag`                 | ブール値        | いいえ       | タグの削除を拒否します。 |
| `file_name_regex`                 | 文字列         | いいえ       | この属性で提供される正規表現に一致するファイル名を拒否します。`(jar\|exe)$`など。 |
| `max_file_size`                   | 整数        | いいえ       | 許可される最大ファイルサイズ（MB）。 |
| `member_check`                    | ブール値        | いいえ       | `true`の場合、GitLabユーザーのみがコミットを作成者できます。 |
| `prevent_secrets`                 | ブール値        | いいえ       | `true`の場合、[シークレットを含む](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml)可能性のあるファイルを拒否します。 |
| `reject_non_dco_commits`          | ブール値        | いいえ       | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`         | ブール値        | いいえ       | `true`の場合、署名されていないコミットを拒否します。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                         | 型    | 説明 |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | 文字列  | この正規表現に一致するコミット作成者のメールアドレスのみを許可します。 |
| `branch_name_regex`               | 文字列  | この正規表現に一致するブランチ名のみを許可します。 |
| `commit_committer_check`          | ブール値 | `true`の場合、コミッターのメールアドレスが自身の検証済みメールアドレスのいずれかである場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_committer_name_check`     | ブール値 | `true`の場合、コミット作成者名がGitLabアカウント名と一致する場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_message_negative_regex`   | 文字列  | この正規表現に一致するコミットメッセージを拒否します。 |
| `commit_message_regex`            | 文字列  | `true`の場合、この正規表現に一致するコミットメッセージのみを許可します。 |
| `created_at`                      | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`                 | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`                 | 文字列  | この正規表現に一致するファイル名を拒否します。 |
| `id`                              | 整数 | プッシュルールのID。 |
| `max_file_size`                   | 整数 | 許可される最大ファイルサイズ（MB）。 |
| `member_check`                    | ブール値 | `true`の場合、GitLabユーザーのみがコミットを作成者できます。 |
| `prevent_secrets`                 | ブール値 | `true`の場合、シークレットを含む可能性のあるファイルを拒否します。 |
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

## グループのプッシュルールを更新する {#update-push-rules-of-a-group}

指定されたグループのプッシュルールを更新します。

```plaintext
PUT /groups/:id/push_rule
```

サポートされている属性は以下のとおりです: 

| 属性                         | 型           | 必須 | 説明 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 整数または文字列 | はい   | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `author_email_regex`              | 文字列         | いいえ       | この属性で提供される正規表現に一致するコミット作成者のメールアドレスのみを許可します。`@my-company.com$`など。 |
| `branch_name_regex`               | 文字列         | いいえ       | この属性で提供される正規表現に一致するブランチ名のみを許可します。`(feature\|hotfix)\/.*`など。 |
| `commit_committer_check`          | ブール値        | いいえ       | `true`の場合、コミッターのメールアドレスが自身の検証済みメールアドレスのいずれかである場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_committer_name_check`     | ブール値        | いいえ       | `true`の場合、コミット作成者名がGitLabアカウント名と一致する場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_message_negative_regex`   | 文字列         | いいえ       | この属性で提供される正規表現に一致するコミットメッセージを拒否します。`ssh\:\/\/`など。 |
| `commit_message_regex`            | 文字列         | いいえ       | `true`の場合、この属性で提供される正規表現に一致するコミットメッセージのみを許可します。`Fixed \d+\..*`など。 |
| `deny_delete_tag`                 | ブール値        | いいえ       | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`                 | 文字列         | いいえ       | この属性で提供される正規表現に一致するファイル名を拒否します。`(jar\|exe)$`など。 |
| `max_file_size`                   | 整数        | いいえ       | 許可される最大ファイルサイズ（MB）。 |
| `member_check`                    | ブール値        | いいえ       | `true`の場合、GitLabユーザーのみがコミットを作成者できます。 |
| `prevent_secrets`                 | ブール値        | いいえ       | `true`の場合、[シークレットを含む](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml)可能性のあるファイルを拒否します。 |
| `reject_non_dco_commits`          | ブール値        | いいえ       | `true`の場合、DCO認証されていないコミットを拒否します。 |
| `reject_unsigned_commits`         | ブール値        | いいえ       | `true`の場合、署名されていないコミットを拒否します。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                         | 型    | 説明 |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | 文字列  | この正規表現に一致するコミット作成者のメールアドレスのみを許可します。 |
| `branch_name_regex`               | 文字列  | この正規表現に一致するブランチ名のみを許可します。 |
| `commit_committer_check`          | ブール値 | `true`の場合、コミッターのメールアドレスが自身の検証済みメールアドレスのいずれかである場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_committer_name_check`     | ブール値 | `true`の場合、コミット作成者名がGitLabアカウント名と一致する場合にのみ、ユーザーからのコミットを許可します。 |
| `commit_message_negative_regex`   | 文字列  | この正規表現に一致するコミットメッセージを拒否します。 |
| `commit_message_regex`            | 文字列  | `true`の場合、この正規表現に一致するコミットメッセージのみを許可します。 |
| `created_at`                      | 文字列  | プッシュルールが作成された日時。 |
| `deny_delete_tag`                 | ブール値 | `true`の場合、タグの削除を拒否します。 |
| `file_name_regex`                 | 文字列  | この正規表現に一致するファイル名を拒否します。 |
| `id`                              | 整数 | プッシュルールのID。 |
| `max_file_size`                   | 整数 | 許可される最大ファイルサイズ（MB）。 |
| `member_check`                    | ブール値 | `true`の場合、GitLabユーザーのみがコミットを作成者できます。 |
| `prevent_secrets`                 | ブール値 | `true`の場合、シークレットを含む可能性のあるファイルを拒否します。 |
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

## グループのプッシュルールを削除する {#delete-the-push-rules-of-a-group}

指定されたグループのすべてのプッシュルールを削除します。

```plaintext
DELETE /groups/:id/push_rule
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、応答ボディなしで[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule"
```
