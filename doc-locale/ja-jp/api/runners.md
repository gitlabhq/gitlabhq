---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Runner API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このページでは、インスタンスに登録されているRunnerのエンドポイントについて説明します。現在のユーザーにリンクされたRunnerを作成するには、[Runnerの作成](users.md#create-a-runner-linked-to-a-user)を参照してください。

[ページネーション](rest/_index.md#pagination)は、次のAPIエンドポイント（デフォルトでは20個のアイテムを返します）で使用できます: 

```plaintext
GET /runners
GET /runners/all
GET /runners/:id/jobs
GET /projects/:id/runners
GET /groups/:id/runners
```

## 登録トークンと認証トークン {#registration-and-authentication-tokens}

RunnerをGitLabに接続するには、2つのトークンが必要です。

| トークン | 説明 |
| ----- | ----------- |
| 登録トークン（GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)となり、GitLab 20.0で削除予定） | [Runnerを登録](https://docs.gitlab.com/runner/register/)するために使用するトークン。[GitLabを通じて取得](../ci/runners/_index.md)できます。 |
| 認証トークン | GitLabインスタンスでRunnerを認証するために使用するトークン。このトークンは、ユーザーが[Runnerを登録](https://docs.gitlab.com/runner/register/)すると、自動的に取得されます。つまり、ユーザーが手動で[Runnerを登録](#create-a-runner)するか、[認証トークンをリセット](#reset-runners-authentication-token-by-using-the-runner-id)すると、Runners APIによって自動的に取得されます。[`POST /user/runners`](users.md#create-a-runner-linked-to-a-user)エンドポイントを使用しても、トークンを取得できます。 |

次に、Runnerの登録にトークンを使用する方法の例を示します:

1. GitLab APIと登録トークンを使用してRunnerを登録し、認証トークンを受け取ります。
1. 認証トークンを[Runnerの設定ファイル](https://docs.gitlab.com/runner/commands/#configuration-file)に追加します:

   ```toml
   [[runners]]
     token = "<authentication_token>"
   ```

これで、GitLabとRunnerが接続されます。

## 利用可能なRunnerの一覧 {#list-available-runners}

ユーザーが利用できるRunnerのリストを取得します。

前提要件: 

- グループRunnerの場合、オーナーのネームスペースでオーナーロールが必要です。
- プロジェクトRunnerの場合、Runnerに割り当てられたプロジェクトのメンテナーロール以上が必要です。

```plaintext
GET /runners
GET /runners?scope=active
GET /runners?type=project_type
GET /runners?status=online
GET /runners?paused=true
GET /runners?tag_list=tag1,tag2
```

| 属性        | 型         | 必須 | 説明 |
|------------------|--------------|----------|-------------|
| `scope`          | 文字列       | いいえ       | 非推奨: 代わりに、`type`または`status`を使用してください。返されるRunnerのスコープ（`active`、`paused`、`online`、`offline`のいずれか）。指定されていない場合は、すべてのRunnerが表示されます |
| `type`           | 文字列       | いいえ       | 返されるRunnerのタイプ（`instance_type`、`group_type`、`project_type`のいずれか） |
| `status`         | 文字列       | いいえ       | 返されるRunnerの状態（`online`、`offline`、`stale`、`never_contacted`のいずれか）。<br/>その他の可能な値は、非推奨の`active`と`paused`です。<br/>`offline` Runnerをリクエストすると、`stale`が`offline`に含まれているため、`stale` Runnerも返される場合があります。 |
| `paused`         | ブール値      | いいえ       | 新規ジョブを受け入れているRunnerのみを含めるか、無視しているRunnerのみを含めるか |
| `tag_list`       | 文字列配列 | いいえ       | Runnerタグのリスト |
| `version_prefix` | 文字列       | いいえ       | 返されるRunnerのバージョンのプレフィックス。例: `15.0`、`14`、`16.1.241` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners"
```

{{< alert type="warning" >}}

`status`クエリパラメータの`active`と`paused`の値は非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`クエリパラメータを使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

応答の`active`属性は非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`属性を使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

応答の`ip_address`属性は[GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159)で非推奨となり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。GitLab 17.0では、この属性は空の文字列を返します。`ipAddress`属性は、それぞれのRunnerマネージャー内にあります。GraphQL [`CiRunnerManager`タイプ](graphql/reference/_index.md#cirunnermanager)でのみ利用可能です。

{{< /alert >}}

レスポンス例:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "test-1-20150125",
        "id": 6,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": true,
        "status": "online"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "group_type",
        "name": null,
        "online": false,
        "status": "offline"
    }
]
```

## すべてのRunnerをリストする {#list-all-runners}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabインスタンス（プロジェクトおよび共有）内のすべてのRunnerのリストを取得します。

前提要件: 

- 管理者アクセス権または監査担当者アクセス権が必要です。

```plaintext
GET /runners/all
GET /runners/all?scope=online
GET /runners/all?type=project_type
GET /runners/all?status=online
GET /runners/all?paused=true
GET /runners/all?tag_list=tag1,tag2
```

| 属性        | 型         | 必須 | 説明 |
|------------------|--------------|----------|-------------|
| `scope`          | 文字列       | いいえ       | 非推奨: 代わりに、`type`または`status`を使用してください。返されるRunnerのスコープ（`specific`、`shared`、`active`、`paused`、`online`、`offline`のいずれか）指定されていない場合は、すべてのRunnerが表示されます |
| `type`           | 文字列       | いいえ       | 返されるRunnerのタイプ（`instance_type`、`group_type`、`project_type`のいずれか） |
| `status`         | 文字列       | いいえ       | 返されるRunnerの状態（`online`、`offline`、`stale`、`never_contacted`のいずれか）。<br/>その他の可能な値は、非推奨の`active`と`paused`です。<br/>`offline` Runnerをリクエストすると、`stale`が`offline`に含まれているため、`stale` Runnerも返される場合があります。 |
| `paused`         | ブール値      | いいえ       | 新規ジョブを受け入れているRunnerのみを含めるか、無視しているRunnerのみを含めるか |
| `tag_list`       | 文字列配列 | いいえ       | Runnerタグのリスト |
| `version_prefix` | 文字列       | いいえ       | 返されるRunnerのバージョンのプレフィックス。例: `15.0`、`16.1.241` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/all"
```

{{< alert type="warning" >}}

`status`クエリパラメータの`active`と`paused`の値は非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`クエリパラメータを使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

応答の`active`属性は非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`属性を使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

応答の`ip_address`属性は[GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159)で非推奨となり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。GitLab 17.0では、この属性は空の文字列を返します。`ipAddress`属性は、それぞれのRunnerマネージャー内にあります。GraphQL [`CiRunnerManager`タイプ](graphql/reference/_index.md#cirunnermanager)でのみ利用可能です。

{{< /alert >}}

レスポンス例:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "shared-runner-1",
        "id": 1,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": true,
        "status": "online"
    },
    {
        "active": true,
        "paused": false,
        "description": "shared-runner-2",
        "id": 3,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": false,
        "status": "offline"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-1-20150125",
        "id": 6,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": true,
        "status": "paused"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "group_type",
        "name": null,
        "online": false,
        "status": "offline"
    }
]
```

最初の20個よりも多くのRunnerを表示するには、[ページネーション](rest/_index.md#pagination)を使用してください。

## Runnerの詳細を取得する {#get-runners-details}

Runnerの詳細を取得します。

このエンドポイントを介したインスタンスRunnerの詳細は、すべての認証済みユーザーが利用できます。

前提要件: 

- ユーザーアクセス: 次のいずれかが必要です:

  - グループRunnerの場合: オーナーのネームスペースで、メンテナーロール以上。
  - プロジェクトRunnerの場合: Runnerを所有するプロジェクトで、メンテナーロール以上。
  - 関連するグループまたはプロジェクトで、`admin_runners`権限を持つカスタムロール。

- `manage_runner`スコープと適切なロールを持つアクセストークン。

```plaintext
GET /runners/:id
```

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `id`      | 整数 | はい      | RunnerのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6"
```

{{< alert type="warning" >}}

応答の`active`属性は非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`属性を使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

応答の`ip_address`属性は[GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159)で非推奨となり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。GitLab 17.0では、この属性は空の文字列を返します。`ipAddress`属性は、それぞれのRunnerマネージャー内にあります。GraphQL [`CiRunnerManager`タイプ](graphql/reference/_index.md#cirunnermanager)でのみ利用可能です。

{{< /alert >}}

{{< alert type="note" >}}

応答の`version`、`revision`、`platform`、および`architecture`属性は[GitLab 17.0](https://gitlab.com/gitlab-org/gitlab/-/issues/457128)で非推奨となり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。同じ属性が、それぞれのRunnerマネージャー内にあります。GraphQL [`CiRunnerManager`タイプ](graphql/reference/_index.md#cirunnermanager)でのみ利用可能です。

{{< /alert >}}

レスポンス例:

```json
{
    "active": true,
    "paused": false,
    "architecture": null,
    "description": "test-1-20150125",
    "id": 6,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "project_type",
    "contacted_at": "2016-01-25T16:39:48.066Z",
    "maintenance_note": null,
    "name": null,
    "online": true,
    "status": "online",
    "platform": null,
    "projects": [
        {
            "id": 1,
            "name": "GitLab Community Edition",
            "name_with_namespace": "GitLab.org / GitLab Community Edition",
            "path": "gitlab-foss",
            "path_with_namespace": "gitlab-org/gitlab-foss"
        }
    ],
    "revision": null,
    "tag_list": [
        "ruby",
        "mysql"
    ],
    "version": null,
    "access_level": "ref_protected",
    "maximum_timeout": 3600
}
```

## Runnerの詳細を更新する {#update-runners-details}

Runnerの詳細を更新します。

```plaintext
PUT /runners/:id
```

前提要件: 

- ユーザーアクセス: 次のいずれかが必要です:

  - インスタンスRunnerの場合: GitLabインスタンスへの管理者アクセス。
  - グループRunnerの場合: オーナーのネームスペースにおけるオーナーロール。
  - プロジェクトRunnerの場合: Runnerに割り当てられたプロジェクトで、メンテナーロール以上。
  - 関連するグループまたはプロジェクトで、`admin_runners`権限を持つカスタムロール。

- `manage_runner`スコープと適切なロールを持つアクセストークン。

| 属性          | 型    | 必須 | 説明 |
|--------------------|---------|----------|-------------|
| `id`               | 整数 | はい      | RunnerのID |
| `description`      | 文字列  | いいえ       | Runnerの説明 |
| `active`           | ブール値 | いいえ       | 非推奨: 代わりに、`paused`を使用してください。Runnerがジョブの受信を許可されているかどうかを示すフラグ |
| `paused`           | ブール値 | いいえ       | Runnerが新規ジョブを無視する必要があるかどうかを指定します |
| `tag_list`         | 配列   | いいえ       | Runnerのタグのリスト |
| `run_untagged`     | ブール値 | いいえ       | タグ付けされていないジョブをRunnerが実行できるかどうかを指定します |
| `locked`           | ブール値 | いいえ       | Runnerがロックされるかどうかを指定します |
| `access_level`     | 文字列  | いいえ       | Runnerのアクセスレベル（`not_protected`または`ref_protected`） |
| `maximum_timeout`  | 整数 | いいえ       | Runnerがジョブを実行できる時間（秒単位）を制限する最大タイムアウト |
| `maintenance_note` | 文字列  | いいえ       | Runnerの自由形式のメンテナンスノート（1024文字） |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6" \
     --form "description=test-1-20150125-test" --form "tag_list=ruby,mysql,tag1,tag2"
```

{{< alert type="warning" >}}

`active`クエリパラメータは非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`属性を使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

応答の`ip_address`属性は[GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159)で非推奨となり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。GitLab 17.0では、この属性は空の文字列を返します。`ipAddress`属性は、それぞれのRunnerマネージャー内にあります。GraphQL [`CiRunnerManager`タイプ](graphql/reference/_index.md#cirunnermanager)でのみ利用可能です。

{{< /alert >}}

レスポンス例:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125-test",
    "id": 6,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "group_type",
    "contacted_at": "2016-01-25T16:39:48.066Z",
    "maintenance_note": null,
    "name": null,
    "online": true,
    "status": "online",
    "platform": null,
    "projects": [
        {
            "id": 1,
            "name": "GitLab Community Edition",
            "name_with_namespace": "GitLab.org / GitLab Community Edition",
            "path": "gitlab-foss",
            "path_with_namespace": "gitlab-org/gitlab-foss"
        }
    ],
    "revision": null,
    "tag_list": [
        "ruby",
        "mysql",
        "tag1",
        "tag2"
    ],
    "version": null,
    "access_level": "ref_protected",
    "maximum_timeout": null
}
```

### Runnerを一時停止する {#pause-a-runner}

Runnerを一時停止します。

前提要件: 

- ユーザーアクセス: 次のいずれかが必要です:

  - インスタンスRunnerの場合: GitLabインスタンスへの管理者アクセス。
  - グループRunnerの場合: オーナーのネームスペースにおけるオーナーロール。
  - プロジェクトRunnerの場合: Runnerに割り当てられたプロジェクトで、メンテナーロール以上。
  - 関連するグループまたはプロジェクトで、`admin_runners`権限を持つカスタムロール。

- `manage_runner`スコープと適切なロールを持つアクセストークン。

```plaintext
PUT --form "paused=true" /runners/:runner_id

# --or--

# Deprecated: removal planned in 16.0
PUT --form "active=false" /runners/:runner_id
```

| 属性   | 型    | 必須 | 説明 |
|-------------|---------|----------|-------------|
| `runner_id` | 整数 | はい      | RunnerのID |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "paused=true"  "https://gitlab.example.com/api/v4/runners/6"

# --or--

# Deprecated: removal planned in 16.0
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "active=false"  "https://gitlab.example.com/api/v4/runners/6"
```

{{< alert type="warning" >}}

`active`フォーム属性は非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`属性を使用してください。

{{< /alert >}}

## Runnerが処理したジョブをリストする {#list-jobs-processed-by-a-runner}

指定されたRunnerが処理している、または処理したジョブをリストします。ジョブのリストは、ユーザーが少なくともレポーターロールを持っているプロジェクトに限定されます。

```plaintext
GET /runners/:id/jobs
```

| 属性   | 型    | 必須 | 説明 |
|-------------|---------|----------|-------------|
| `id`        | 整数 | はい      | RunnerのID |
| `system_id` | 文字列  | いいえ       | Runnerマネージャーが実行されているマシンのシステムID |
| `status`    | 文字列  | いいえ       | ジョブの状態（`running`、`success`、`failed`、`canceled`のいずれか） |
| `order_by`  | 文字列  | いいえ       | `id`でジョブを順序付けます |
| `sort`      | 文字列  | いいえ       | `asc`または`desc`順にジョブを並べ替えます（デフォルト: `desc`）。`sort`が指定されている場合は、`order_by`も指定する必要があります |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/1/jobs?status=running"
```

レスポンス例:

```json
[
    {
        "id": 2,
        "status": "running",
        "stage": "test",
        "name": "test",
        "ref": "main",
        "tag": false,
        "coverage": null,
        "created_at": "2017-11-16T08:50:29.000Z",
        "started_at": "2017-11-16T08:51:29.000Z",
        "finished_at": "2017-11-16T08:53:29.000Z",
        "duration": 120,
        "queued_duration": 2,
        "user": {
            "id": 1,
            "name": "John Doe2",
            "username": "user2",
            "state": "active",
            "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
            "web_url": "http://localhost/user2",
            "created_at": "2017-11-16T18:38:46.000Z",
            "bio": null,
            "location": null,
            "public_email": "",
            "linkedin": "",
            "twitter": "",
            "website_url": "",
            "organization": null
        },
        "commit": {
            "id": "97de212e80737a608d939f648d959671fb0a0142",
            "short_id": "97de212e",
            "title": "Update configuration\r",
            "created_at": "2017-11-16T08:50:28.000Z",
            "parent_ids": [
                "1b12f15a11fc6e62177bef08f47bc7b5ce50b141",
                "498214de67004b1da3d820901307bed2a68a8ef6"
            ],
            "message": "See merge request !123",
            "author_name": "John Doe2",
            "author_email": "user2@example.org",
            "authored_date": "2017-11-16T08:50:27.000Z",
            "committer_name": "John Doe2",
            "committer_email": "user2@example.org",
            "committed_date": "2017-11-16T08:50:27.000Z"
        },
        "pipeline": {
            "id": 2,
            "sha": "97de212e80737a608d939f648d959671fb0a0142",
            "ref": "main",
            "status": "running"
        },
        "project": {
            "id": 1,
            "description": null,
            "name": "project1",
            "name_with_namespace": "John Doe2 / project1",
            "path": "project1",
            "path_with_namespace": "namespace1/project1",
            "created_at": "2017-11-16T18:38:46.620Z"
        }
    }
]
```

## Runnerのマネージャーをリストする {#list-runners-managers}

Runnerのすべてのマネージャーをリストします。

```plaintext
GET /runners/:id/managers
```

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `id`      | 整数 | はい      | RunnerのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/1/managers"
```

レスポンス例:

```json
[
    {
      "id": 1,
      "system_id": "s_89e5e9956577",
      "version": "16.11.1",
      "revision": "535ced5f",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-06-09T11:12:02.507Z",
      "contacted_at": "2024-06-09T06:30:09.355Z",
      "ip_address": "127.0.0.1",
      "status": "offline"
    },
    {
      "id": 2,
      "system_id": "runner-2",
      "version": "16.11.0",
      "revision": "91a27b2a",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-06-09T09:12:02.507Z",
      "contacted_at": "2024-06-09T06:30:09.355Z",
      "ip_address": "127.0.0.1",
      "status": "offline"
    }
]
```

## プロジェクトのRunnerをリストする {#list-projects-runners}

祖先グループと[許可されているインスタンスRunner](../ci/runners/runners_scope.md#enable-instance-runners-for-a-project)を含めて、プロジェクトで利用可能なすべてのRunnerをリストします。

前提要件: 

- GitLabインスタンスの管理者であるか、対象プロジェクトのメンテナーまたは監査担当者ロール以上を持っている必要があります。

```plaintext
GET /projects/:id/runners
GET /projects/:id/runners?scope=active
GET /projects/:id/runners?type=project_type
GET /projects/:id/runners/all?status=online
GET /projects/:id/runners/all?paused=true
GET /projects/:id/runners?tag_list=tag1,tag2
```

| 属性        | 型           | 必須 | 説明 |
|------------------|----------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `scope`          | 文字列         | いいえ       | 非推奨: 代わりに、`type`または`status`を使用してください。返されるRunnerのスコープ（`active`、`paused`、`online`、`offline`のいずれか）。指定されていない場合は、すべてのRunnerが表示されます |
| `type`           | 文字列         | いいえ       | 返されるRunnerのタイプ（`instance_type`、`group_type`、`project_type`のいずれか） |
| `status`         | 文字列         | いいえ       | 返されるRunnerの状態（`online`、`offline`、`stale`、`never_contacted`のいずれか）。<br/>その他の可能な値は、非推奨の`active`と`paused`です。<br/>`offline` Runnerをリクエストすると、`stale`が`offline`に含まれているため、`stale` Runnerも返される場合があります。 |
| `paused`         | ブール値        | いいえ       | 新規ジョブを受け入れているRunnerのみを含めるか、無視しているRunnerのみを含めるか |
| `tag_list`       | 文字列配列   | いいえ       | Runnerタグのリスト |
| `version_prefix` | 文字列         | いいえ       | 返されるRunnerのバージョンのプレフィックス。例: `15.0`、`14`、`16.1.241` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners"
```

{{< alert type="warning" >}}

`status`クエリパラメータの`active`と`paused`の値は非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`クエリパラメータを使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

応答の`active`属性は非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`属性を使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

応答の`ip_address`属性は[GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159)で非推奨となり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。GitLab 17.0では、この属性は空の文字列を返します。`ipAddress`属性は、それぞれのRunnerマネージャー内にあります。GraphQL [`CiRunnerManager`タイプ](graphql/reference/_index.md#cirunnermanager)でのみ利用可能です。

{{< /alert >}}

レスポンス例:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": false,
        "status": "offline"
    },
    {
        "active": true,
        "paused": false,
        "description": "development_runner",
        "id": 5,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": true,
        "status": "online"
    }
]
```

## Runnerをプロジェクトに割り当てる {#assign-a-runner-to-project}

利用可能なプロジェクトRunnerをプロジェクトに割り当てます。

前提要件: 

- ユーザーアクセス: 次のいずれかが必要です:

  - Runnerを所有するプロジェクトおよび対象プロジェクトのメンテナーロール以上。
  - 関連するグループまたはプロジェクトで、`admin_runners`権限を持つカスタムロール。

```plaintext
POST /projects/:id/runners
```

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `runner_id` | 整数        | はい      | RunnerのID |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners" \
     --form "runner_id=9"
```

{{< alert type="warning" >}}

応答の`ip_address`属性は[GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159)で非推奨となり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。GitLab 17.0では、この属性は空の文字列を返します。`ipAddress`属性は、それぞれのRunnerマネージャー内にあります。GraphQL [`CiRunnerManager`タイプ](graphql/reference/_index.md#cirunnermanager)でのみ利用可能です。

{{< /alert >}}

レスポンス例:

```json
{
    "active": true,
    "description": "test-2016-02-01",
    "id": 9,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "project_type",
    "name": null,
    "online": true,
    "status": "online"
}
```

## プロジェクトからRunnerの割り当てを解除する {#unassign-a-runner-from-project}

プロジェクトからプロジェクトRunnerの割り当てを解除します。オーナープロジェクトからRunnerの割り当てを解除することはできません。このアクションを試みると、エラーが発生します。代わりに、[Runnerの削除](#delete-a-runner)への呼び出しを使用します。

前提要件: 

- 管理者でない限り、Runnerをロックしてはいけません。
- ユーザーアクセス: 次のいずれかが必要です:

  - 割り当てを解除するプロジェクトで、メンテナーロール以上。
  - 関連するグループまたはプロジェクトで、`admin_runners`権限を持つカスタムロール。

- `manage_runner`スコープと適切なロールを持つアクセストークン。

```plaintext
DELETE /projects/:id/runners/:runner_id
```

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `runner_id` | 整数        | はい      | RunnerのID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners/9"
```

## グループのRunnerをリストする {#list-groups-runners}

[許可されているインスタンスRunner](../ci/runners/runners_scope.md#enable-instance-runners-for-a-group)を含めて、グループとその祖先グループで利用可能なすべてのRunnerをリストます。

前提要件: 

- ユーザーアクセス: 次のいずれかが必要です:

  - GitLabインスタンスへの管理者アクセス。
  - グループのオーナーまたは監査担当者ロール。
  - グループ内で`admin_runners`権限を持つカスタムロール。

- `manage_runner`スコープと適切なロールを持つアクセストークン。

```plaintext
GET /groups/:id/runners
GET /groups/:id/runners?type=group_type
GET /groups/:id/runners/all?status=online
GET /groups/:id/runners/all?paused=true
GET /groups/:id/runners?tag_list=tag1,tag2
```

| 属性        | 型         | 必須 | 説明 |
|------------------|--------------|----------|-------------|
| `id`             | 整数      | はい      | グループのID |
| `type`           | 文字列       | いいえ       | 返されるRunnerのタイプ（`instance_type`、`group_type`、`project_type`のいずれか）。`project_type`値は[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/351466)であり、GitLab 15.0で削除される予定です |
| `status`         | 文字列       | いいえ       | 返されるRunnerの状態（`online`、`offline`、`stale`、`never_contacted`のいずれか）。<br/>その他の可能な値は、非推奨の`active`と`paused`です。<br/>`offline` Runnerをリクエストすると、`stale`が`offline`に含まれているため、`stale` Runnerも返される場合があります。 |
| `paused`         | ブール値      | いいえ       | 新規ジョブを受け入れているRunnerのみを含めるか、無視しているRunnerのみを含めるか |
| `tag_list`       | 文字列配列 | いいえ       | Runnerタグのリスト |
| `version_prefix` | 文字列       | いいえ       | 返されるRunnerのバージョンのプレフィックス。例: `15.0`、`14`、`16.1.241` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/9/runners"
```

{{< alert type="warning" >}}

`status`クエリパラメータの`active`と`paused`の値は非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`クエリパラメータを使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

応答の`active`属性は非推奨であり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。代わりに、`paused`属性を使用してください。

{{< /alert >}}

{{< alert type="warning" >}}

応答の`ip_address`属性は[GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159)で非推奨となり、[REST APIの将来のバージョン](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)で削除される予定です。GitLabでは、t属性は空の文字列を返します。`ipAddress`属性は、それぞれのRunnerマネージャー内にあります。GraphQL [`CiRunnerManager`タイプ](graphql/reference/_index.md#cirunnermanager)でのみ利用可能です。

{{< /alert >}}

レスポンス例:

```json
[
  {
    "id": 3,
    "description": "Shared",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": true,
    "runner_type": "instance_type",
    "name": "gitlab-runner",
    "online": null,
    "status": "never_contacted"
  },
  {
    "id": 6,
    "description": "Test",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": true,
    "runner_type": "instance_type",
    "name": "gitlab-runner",
    "online": false,
    "status": "offline"
  },
  {
    "id": 8,
    "description": "Test 2",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": false,
    "runner_type": "group_type",
    "name": "gitlab-runner",
    "online": null,
    "status": "never_contacted"
  }
]
```

## Runnerを作成する {#create-a-runner}

{{< alert type="warning" >}}

このエンドポイントは、Runner登録トークンを使用した登録がプロジェクト設定またはグループ設定で無効になっている場合、`HTTP 410 Gone`状態コードを返します。Runner登録トークンを使用した登録が無効になっている場合は、[`POST /user/runners`](users.md#create-a-runner-linked-to-a-user)エンドポイントを使用して、Runnerを作成して登録します。

{{< /alert >}}

Runner登録トークンを使用してRunnerを作成します。

```plaintext
POST /runners
```

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `token`            | 文字列       | はい      | [登録トークン](#registration-and-authentication-tokens) |
| `description`      | 文字列       | いいえ       | Runnerの説明 |
| `info`             | ハッシュ         | いいえ       | Runnerのメタデータ。`name`、`version`、`revision`、`platform`、`architecture`を含めることができますが、UIの**管理者**エリアには、`version`、`platform`、`architecture`のみが表示されます |
| `active`           | ブール値      | いいえ       | 非推奨: 代わりに、`paused`を使用してください。Runnerに新規ジョブの受信を許可するかどうかを指定します |
| `paused`           | ブール値      | いいえ       | Runnerが新規ジョブを無視する必要があるかどうかを指定します |
| `locked`           | ブール値      | いいえ       | 現在のプロジェクトに対してRunnerをロックする必要があるかどうかを指定します |
| `run_untagged`     | ブール値      | いいえ       | タグ付けされていないジョブをRunnerが処理する必要があるかどうかを指定します |
| `tag_list`         | 文字列配列 | いいえ       | Runnerタグのリスト |
| `access_level`     | 文字列       | いいえ       | Runnerのアクセスレベル（`not_protected`または`ref_protected`） |
| `maximum_timeout`  | 整数      | いいえ       | Runnerがジョブを実行できる時間（秒単位）を制限する最大タイムアウト |
| `maintainer_note`  | 文字列       | いいえ       | [非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/350730)。`maintenance_note`を参照してください |
| `maintenance_note` | 文字列       | いいえ       | Runnerの自由形式のメンテナンスノート（1024文字） |

```shell
curl --request POST "https://gitlab.example.com/api/v4/runners" \
     --form "token=<registration_token>" --form "description=test-1-20150125-test" \
     --form "tag_list=ruby,mysql,tag1,tag2"
```

応答:

| 状態 | 説明 |
|--------|-------------|
| 201    | Runnerが作成されました |
| 403    | 無効なRunner登録トークン |
| 410    | Runner登録が無効になっています |

レスポンス例:

```json
{
    "id": 12345,
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## Runnerを削除する {#delete-a-runner}

次の要素を指定して、Runnerを削除できます:

- RunnerのID
- Runnerの認証トークン

### IDでRunnerを削除する {#delete-a-runner-by-id}

IDでRunnerを削除するには、アクセストークンとRunnerのIDを使用します:

前提要件: 

- ユーザーアクセス: 次のいずれかが必要です:

  - インスタンスRunnerの場合: GitLabインスタンスへの管理者アクセス。
  - グループRunnerの場合: オーナーのネームスペースにおけるオーナーロール。
  - プロジェクトRunnerの場合: Runnerを所有するプロジェクトで、メンテナーロール以上。
  - 関連するグループまたはプロジェクトで、`admin_runners`権限を持つカスタムロール。

- `manage_runner`スコープと適切なロールを持つアクセストークン。

```plaintext
DELETE /runners/:id
```

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `id`      | 整数 | はい      | RunnerのID。IDは、**設定** > **CI/CD**で確認できます。**Runners**を展開すると、**Remove Runner**（Runnerの削除）の下にポンド記号で始まるIDが表示されます（例: `#6`）。 |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6"
```

### 認証トークンでRunnerを削除する {#delete-a-runner-by-authentication-token}

認証トークンを使用してRunnerを削除します。

```plaintext
DELETE /runners
```

| 属性 | 型   | 必須 | 説明 |
|-----------|--------|----------|-------------|
| `token`   | 文字列 | はい      | Runnerの[認証トークン](#registration-and-authentication-tokens)。 |

```shell
curl --request DELETE "https://gitlab.example.com/api/v4/runners" \
     --form "token=<authentication_token>"
```

応答:

| 状態 | 説明 |
|--------|-------------|
| 204    | Runnerが削除されました |

## 登録済みRunnerの認証を検証する {#verify-authentication-for-a-registered-runner}

登録済みRunnerの認証情報を検証します。

```plaintext
POST /runners/verify
```

| 属性   | 型   | 必須 | 説明 |
|-------------|--------|----------|-------------|
| `token`     | 文字列 | はい      | Runnerの[認証トークン](#registration-and-authentication-tokens)。 |
| `system_id` | 文字列 | いいえ       | Runnerのシステム識別子。この属性は、`token`が`glrt-`で始まる場合に必須です。 |

```shell
curl --request POST "https://gitlab.example.com/api/v4/runners/verify" \
     --form "token=<authentication_token>"
```

応答:

| 状態 | 説明 |
|--------|-------------|
| 200    | 認証情報が有効です |
| 403    | 認証情報が無効です |

レスポンス例:

```json
{
    "id": 12345,
    "token": "glrt-6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## インスタンスのRunner登録トークンをリセットする {#reset-instances-runner-registration-token}

{{< alert type="warning" >}}

Runner登録トークンを渡すオプションと、特定の設定引数のサポートは、GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)となっており、GitLab 20.0で削除される予定です。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。

詳細については、[新しいRunner登録ワークフローに移行する](../ci/runners/new_creation_workflow.md)を参照してください。

{{< /alert >}}

GitLabインスタンスのRunner登録トークンをリセットします。

```plaintext
POST /runners/reset_registration_token
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/runners/reset_registration_token"
```

## プロジェクトのRunner登録トークンをリセットする {#reset-projects-runner-registration-token}

{{< alert type="warning" >}}

Runner登録トークンを渡すオプションと、特定の設定引数のサポートは、GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)となっており、GitLab 20.0で削除される予定です。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。詳細については、[新しいRunner登録ワークフローに移行する](../ci/runners/new_creation_workflow.md)を参照してください。

{{< /alert >}}

プロジェクトのRunner登録トークンをリセットします。

```plaintext
POST /projects/:id/runners/reset_registration_token
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/9/runners/reset_registration_token"
```

## グループのRunner登録トークンをリセットする {#reset-groups-runner-registration-token}

{{< alert type="warning" >}}

Runner登録トークンを渡すオプションと、特定の設定引数のサポートは、GitLab 15.6で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)となっており、GitLab 20.0で削除される予定です。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。詳細については、[新しいRunner登録ワークフローに移行する](../ci/runners/new_creation_workflow.md)を参照してください。

{{< /alert >}}

グループのRunner登録トークンをリセットします。

```plaintext
POST /groups/:id/runners/reset_registration_token
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/9/runners/reset_registration_token"
```

## Runner IDを使用してRunnerの認証トークンをリセットする {#reset-runners-authentication-token-by-using-the-runner-id}

Runner IDを使用して、Runnerの認証トークンをリセットします。

前提要件: 

- ユーザーアクセス: 次のいずれかが必要です:

  - インスタンスRunnerの場合: GitLabインスタンスへの管理者アクセス。
  - グループRunnerの場合: オーナーのネームスペースにおけるオーナーロール。
  - プロジェクトRunnerの場合: Runnerに割り当てられたプロジェクトで、メンテナーロール以上。
  - 関連するグループまたはプロジェクトで、`admin_runners`権限を持つカスタムロール。

- `manage_runner`スコープと適切なロールを持つアクセストークン。

```plaintext
POST /runners/:id/reset_authentication_token
```

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `id`      | 整数 | はい      | RunnerのID |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/runners/1/reset_authentication_token"
```

レスポンス例:

```json
{
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## 現在のトークンを使用してRunnerの認証トークンをリセットする {#reset-runners-authentication-token-by-using-the-current-token}

現在のトークンの値をインプットとして使用して、Runnerの認証トークンをリセットします。

```plaintext
POST /runners/reset_authentication_token
```

| 属性 | 型   | 必須 | 説明 |
|-----------|--------|----------|-------------|
| `token`   | 文字列 | はい      | Runnerの認証トークン |

```shell
curl --request POST --form "token=<current token>" \
     "https://gitlab.example.com/api/v4/runners/reset_authentication_token"
```

レスポンス例:

```json
{
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```
