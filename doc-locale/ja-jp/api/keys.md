---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: キーAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[SSHキー](../user/ssh.md)に関する情報を取得することができます。デプロイキーのフィンガープリントに関するクエリは、そのキーを使用しているプロジェクトに関する情報も取得することができます。

SHA256フィンガープリントをAPIコールで使用する場合は、フィンガープリントをURLエンコードする必要があります。

## SSHキーIDでユーザーを取得する {#retrieve-user-by-ssh-key-id}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

指定されたSSHキーを所有するユーザーに関する情報を取得することができます。

```plaintext
GET /keys/:id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明           |
|-----------|---------|----------|-----------------------|
| `id`      | 整数 | はい      | SSHキーのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `created_at`        | 文字列  | ISO 8601形式のSSHキーの作成日時。 |
| `expires_at`        | 文字列  | ISO 8601形式のSSHキーの有効期限日時。 |
| `id`                | 整数 | SSHキーのID。 |
| `key`               | 文字列  | SSHキーのコンテンツ。 |
| `last_used_at`      | 文字列  | ISO 8601形式のSSHキーの最終使用日時。 |
| `title`             | 文字列  | SSHキーのタイトル。 |
| `usage_type`        | 文字列  | SSHキーの使用タイプ（例: `auth`または`auth_and_signing`）。 |
| `user`              | オブジェクト  | SSHキーに関連付けられたユーザー。 |
| `user.avatar_url`   | 文字列  | ユーザーのアバターのURL。 |
| `user.bio`          | 文字列  | ユーザーの経歴。 |
| `user.created_at`   | 文字列  | ISO 8601形式のユーザーアカウントの作成日時。 |
| `user.id`           | 整数 | ユーザーのID。 |
| `user.linkedin`     | 文字列  | ユーザーのLinkedInプロフィールURL。 |
| `user.location`     | 文字列  | ユーザーの所在地。 |
| `user.name`         | 文字列  | ユーザーの名前。 |
| `user.organization` | 文字列  | ユーザーの所属組織。 |
| `user.public_email` | 文字列  | ユーザーの公開メールアドレス。 |
| `user.state`        | 文字列  | ユーザーの状態。 |
| `user.twitter`      | 文字列  | ユーザーのTwitterプロフィールURL。 |
| `user.username`     | 文字列  | ユーザーのユーザー名。 |
| `user.web_url`      | 文字列  | ユーザーのプロフィールURL。 |
| `user.website_url`  | 文字列  | ユーザーのウェブサイトURL。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "title": "Sample key 25",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1256k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2015-09-03T07:24:44.627Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "name": "John Smith",
    "username": "john_smith",
    "id": 25,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/cfa35b8cd2ec278026357769582fa563?s=40\u0026d=identicon",
    "web_url": "http://localhost:3000/john_smith",
    "created_at": "2015-09-03T07:24:01.670Z",
    "bio": null,
    "location": null,
    "public_email": "john@example.com",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2015-09-03T07:24:01.670Z",
    "confirmed_at": "2015-09-03T07:24:01.670Z",
    "last_activity_on": "2015-09-03",
    "email": "john@example.com",
    "theme_id": 2,
    "color_scheme_id": 1,
    "projects_limit": 10,
    "current_sign_in_at": null,
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": null
  }
}
```

## SSHキーのフィンガープリントでユーザーを取得する {#retrieve-user-by-ssh-key-fingerprint}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

指定されたSSHキーを所有するユーザーに関する情報を取得することができます。

```plaintext
GET /keys
```

サポートされている属性は以下のとおりです: 

| 属性     | 型   | 必須 | 説明                    |
|---------------|--------|----------|--------------------------------|
| `fingerprint` | 文字列 | はい      | SSHキーのフィンガープリント。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                 | 型    | 説明 |
|---------------------------|---------|-------------|
| `created_at`              | 文字列  | ISO 8601形式のSSHキーの作成日時。 |
| `expires_at`              | 文字列  | ISO 8601形式のSSHキーの有効期限日時。 |
| `id`                      | 整数 | SSHキーのID。 |
| `key`                     | 文字列  | SSHキーのコンテンツ。 |
| `last_used_at`            | 文字列  | ISO 8601形式のSSHキーの最終使用日時。 |
| `title`                   | 文字列  | SSHキーのタイトル。 |
| `usage_type`              | 文字列  | SSHキーの使用タイプ（例: `auth`または`auth_and_signing`）。 |
| `user`                    | オブジェクト  | SSHキーに関連付けられたユーザー。 |
| `user.avatar_url`         | 文字列  | ユーザーのアバターのURL。 |
| `user.bio`                | 文字列  | ユーザーの経歴。 |
| `user.can_create_group`   | ブール値 | `true`の場合、ユーザーはグループを作成できます。 |
| `user.can_create_project` | ブール値 | `true`の場合、ユーザーはプロジェクトを作成できます。 |
| `user.color_scheme_id`    | 整数 | ユーザーのカラースキームID。 |
| `user.confirmed_at`       | 文字列  | ISO 8601形式のユーザーの確認日時。 |
| `user.created_at`         | 文字列  | ISO 8601形式のユーザーアカウントの作成日時。 |
| `user.current_sign_in_at` | 文字列  | ISO 8601形式のユーザーの現在のサインイン日時。 |
| `user.email`              | 文字列  | ユーザーのメールアドレス。 |
| `user.external`           | ブール値 | `true`の場合、ユーザーは外部ユーザーです。 |
| `user.id`                 | 整数 | ユーザーのID。 |
| `user.identities`         | 配列   | ユーザーに関連付けられたID。 |
| `user.last_activity_on`   | 文字列  | ユーザーの最終アクティビティ日。 |
| `user.last_sign_in_at`    | 文字列  | ISO 8601形式のユーザーの最終サインイン日時。 |
| `user.linkedin`           | 文字列  | ユーザーのLinkedInプロフィールURL。 |
| `user.location`           | 文字列  | ユーザーの所在地。 |
| `user.name`               | 文字列  | ユーザーの名前。 |
| `user.organization`       | 文字列  | ユーザーの所属組織。 |
| `user.private_profile`    | ブール値 | `true`の場合、ユーザーのプロフィールはプライベートです。 |
| `user.projects_limit`     | 整数 | ユーザーのプロジェクト制限。 |
| `user.public_email`       | 文字列  | ユーザーの公開メールアドレス。 |
| `user.state`              | 文字列  | ユーザーアカウントの状態。 |
| `user.theme_id`           | 整数 | ユーザーのテーマID。 |
| `user.twitter`            | 文字列  | ユーザーのTwitterプロフィールURL。 |
| `user.two_factor_enabled` | ブール値 | `true`の場合、ユーザーに対して2要素認証が有効になります。 |
| `user.username`           | 文字列  | ユーザーのユーザー名。 |
| `user.web_url`            | 文字列  | ユーザーのプロフィールURL。 |
| `user.website_url`        | 文字列  | ユーザーのウェブサイトURL。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1"
```

レスポンス例: 

```json
{
  "id": 1,
  "title": "Sample key 1",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1016k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2019-11-14T15:11:13.222Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://0.0.0.0:3000/root",
    "created_at": "2019-11-14T15:09:34.831Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2019-11-16T22:41:26.663Z",
    "confirmed_at": "2019-11-14T15:09:34.575Z",
    "last_activity_on": "2019-11-20",
    "email": "admin@example.com",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": "2019-11-19T14:42:18.078Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  }
}
```

## デプロイキーのフィンガープリントでユーザーを取得する {#retrieve-user-by-deploy-key-fingerprint}

指定されたデプロイキーのフィンガープリントを使用しているユーザーおよびプロジェクトに関する情報を取得することができます。デプロイキーは作成ユーザーにバインドされます。

```plaintext
GET /keys
```

サポートされている属性は以下のとおりです: 

| 属性     | 型   | 必須 | 説明                        |
|---------------|--------|----------|------------------------------------|
| `fingerprint` | 文字列 | はい      | デプロイキーのフィンガープリント。   |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                                 | 型    | 説明 |
|-------------------------------------------|---------|-------------|
| `created_at`                              | 文字列  | ISO 8601形式のデプロイキーの作成日時。 |
| `deploy_keys_projects`                    | 配列   | デプロイキーのプロジェクト情報。 |
| `deploy_keys_projects[].can_push`         | ブール値 | `true`の場合、デプロイキーはプロジェクトにプッシュすることができます。 |
| `deploy_keys_projects[].created_at`       | 文字列  | ISO 8601形式の作成日時。 |
| `deploy_keys_projects[].deploy_key_id`    | 整数 | デプロイキーのID。 |
| `deploy_keys_projects[].id`               | 整数 | デプロイキーとプロジェクトリレーションのID。 |
| `deploy_keys_projects[].project_id`       | 整数 | プロジェクトのID。 |
| `deploy_keys_projects[].updated_at`       | 文字列  | ISO 8601形式の最終更新日時。 |
| `expires_at`                              | 文字列  | ISO 8601形式のデプロイキーの有効期限日時。 |
| `id`                                      | 整数 | デプロイキーのID。 |
| `key`                                     | 文字列  | デプロイキーのコンテンツ。 |
| `last_used_at`                            | 文字列  | ISO 8601形式のデプロイキーの最終使用日時。 |
| `title`                                   | 文字列  | デプロイキーのタイトル。 |
| `usage_type`                              | 文字列  | デプロイキーの使用タイプ（例: `auth`または`auth_and_signing`）。 |
| `user`                                    | オブジェクト  | デプロイキーに関連付けられたユーザー。 |
| `user.avatar_url`                         | 文字列  | ユーザーのアバターのURL。 |
| `user.bio`                                | 文字列  | ユーザーの経歴。 |
| `user.can_create_group`                   | ブール値 | `true`の場合、ユーザーはグループを作成できます。 |
| `user.can_create_project`                 | ブール値 | `true`の場合、ユーザーはプロジェクトを作成できます。 |
| `user.color_scheme_id`                    | 整数 | ユーザーのカラースキームID。 |
| `user.confirmed_at`                       | 文字列  | ISO 8601形式のユーザーの確認日時。 |
| `user.created_at`                         | 文字列  | ISO 8601形式のユーザーアカウントの作成日時。 |
| `user.current_sign_in_at`                 | 文字列  | ISO 8601形式のユーザーの現在のサインイン日時。 |
| `user.email`                              | 文字列  | ユーザーのメールアドレス。 |
| `user.external`                           | ブール値 | `true`の場合、ユーザーは外部ユーザーです。 |
| `user.extra_shared_runners_minutes_limit` | 整数 | ユーザーの追加共有Runner分数制限。 |
| `user.id`                                 | 整数 | ユーザーのID。 |
| `user.identities`                         | 配列   | ユーザーに関連付けられたID。 |
| `user.last_activity_on`                   | 文字列  | ユーザーの最終アクティビティ日。 |
| `user.last_sign_in_at`                    | 文字列  | ISO 8601形式のユーザーの最終サインイン日時。 |
| `user.linkedin`                           | 文字列  | ユーザーのLinkedInプロフィールURL。 |
| `user.location`                           | 文字列  | ユーザーの所在地。 |
| `user.name`                               | 文字列  | ユーザーの名前。 |
| `user.organization`                       | 文字列  | ユーザーの所属組織。 |
| `user.private_profile`                    | ブール値 | `true`の場合、ユーザーのプロフィールはプライベートです。 |
| `user.projects_limit`                     | 整数 | ユーザーのプロジェクト制限。 |
| `user.public_email`                       | 文字列  | ユーザーの公開メールアドレス。 |
| `user.shared_runners_minutes_limit`       | 整数 | ユーザーの共有Runner分数制限。 |
| `user.state`                              | 文字列  | ユーザーアカウントの状態。 |
| `user.theme_id`                           | 整数 | ユーザーのテーマID。 |
| `user.twitter`                            | 文字列  | ユーザーのTwitterプロフィールURL。 |
| `user.two_factor_enabled`                 | ブール値 | `true`の場合、ユーザーに対して2要素認証が有効になります。 |
| `user.username`                           | 文字列  | ユーザーのユーザー名。 |
| `user.web_url`                            | 文字列  | ユーザーのプロフィールURL。 |
| `user.website_url`                        | 文字列  | ユーザーのウェブサイトURL。 |

MD5フィンガープリントのリクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1"
```

SHA256フィンガープリント（URLエンコード済み）のリクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=SHA256%3AnUhzNyftwADy8AH3wFY31tAKs7HufskYTte2aXo%2FlCg"
```

SHA256の例では、`/`は`%2F`で表され、`:`は`%3A`で表されます。

レスポンス例: 

```json
{
  "id": 1,
  "title": "Sample key 1",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1016k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2019-11-14T15:11:13.222Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://0.0.0.0:3000/root",
    "created_at": "2019-11-14T15:09:34.831Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2019-11-16T22:41:26.663Z",
    "confirmed_at": "2019-11-14T15:09:34.575Z",
    "last_activity_on": "2019-11-20",
    "email": "admin@example.com",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": "2019-11-19T14:42:18.078Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  },
  "deploy_keys_projects": [
    {
      "id": 1,
      "deploy_key_id": 1,
      "project_id": 1,
      "created_at": "2020-01-09T07:32:52.453Z",
      "updated_at": "2020-01-09T07:32:52.453Z",
      "can_push": false
    }
  ]
}
```
