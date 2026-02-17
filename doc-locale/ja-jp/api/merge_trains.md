---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのマージトレインのREST APIのドキュメント。
title: マージトレインAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[merge trains](../ci/pipelines/merge_trains.md)とやり取りします。

前提条件: 

- デベロッパーロール以上が必要です。

すべてのマージトレインエンドポイントは、`page`および`per_page`パラメータを使用して、[offset-based pagination](rest/_index.md#offset-based-pagination)（オフセットベースのページネーション）をサポートします。

## プロジェクトのすべてのマージトレインをリストします {#list-all-merge-trains-for-a-project}

指定されたプロジェクトのすべてのマージトレインをリストします。

```plaintext
GET /projects/:id/merge_trains
```

サポートされている属性: 

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `scope`   | 文字列            | いいえ       | 指定されたスコープでフィルタリングされたマージトレインを返します。使用可能なスコープは、`active`（マージ対象）および`complete`（マージ済み）です。 |
| `sort`    | 文字列            | いいえ       | `asc`または`desc`順にソートされたマージトレインを返します。デフォルトは`desc`です。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                   | 型     | 説明 |
| --------------------------- | -------- | ----------- |
| `created_at`                | 日時 | マージトレインが作成されたときのタイムスタンプ。 |
| `duration`                  | 整数  | マージトレインに費やした時間（秒単位）。完了していない場合は`null`。 |
| `id`                        | 整数  | マージトレインのID。 |
| `merged_at`                 | 日時 | マージリクエストがマージされたときのタイムスタンプ。マージされていない場合は`null`。 |
| `merge_request`             | オブジェクト   | マージリクエストの詳細。 |
| `merge_request.created_at`  | 日時 | マージリクエストが作成されたときのタイムスタンプ。 |
| `merge_request.description` | 文字列   | マージリクエストの説明。 |
| `merge_request.id`          | 整数  | マージリクエストのID。 |
| `merge_request.iid`         | 整数  | マージリクエストの内部ID。 |
| `merge_request.project_id`  | 整数  | マージリクエストを含むプロジェクトのID。 |
| `merge_request.state`       | 文字列   | マージリクエストの状態。 |
| `merge_request.title`       | 文字列   | マージリクエストのタイトル。 |
| `merge_request.updated_at`  | 日時 | マージリクエストが最後に更新されたときのタイムスタンプ。 |
| `merge_request.web_url`     | 文字列   | マージリクエストのWeb URL。 |
| `pipeline`                  | オブジェクト   | パイプラインの詳細。パイプラインが関連付けられていない場合は`null`。 |
| `pipeline.created_at`       | 日時 | パイプラインが作成されたときのタイムスタンプ。 |
| `pipeline.id`               | 整数  | パイプラインのID。 |
| `pipeline.iid`              | 整数  | パイプラインの内部ID。 |
| `pipeline.project_id`       | 整数  | パイプラインを含むプロジェクトのID。 |
| `pipeline.ref`              | 文字列   | パイプラインのGit参照。 |
| `pipeline.sha`              | 文字列   | パイプラインをトリガーしたコミットのSHA。 |
| `pipeline.source`           | 文字列   | パイプライントリガーのソース。 |
| `pipeline.status`           | 文字列   | パイプラインのステータス。 |
| `pipeline.updated_at`       | 日時 | パイプラインが最後に更新されたときのタイムスタンプ。 |
| `pipeline.web_url`          | 文字列   | パイプラインのWeb URL。 |
| `status`                    | 文字列   | マージトレインのステータス。指定可能な値：`idle`、`stale`、`fresh`、`merging`、`merged`、`skip_merged`。 |
| `target_branch`             | 文字列   | ターゲットブランチの名前。 |
| `updated_at`                | 日時 | マージトレインが最後に更新されたときのタイムスタンプ。 |
| `user`                      | オブジェクト   | マージリクエストをマージトレインに追加したユーザー。 |
| `user.avatar_url`           | 文字列   | ユーザーのアバターURL。 |
| `user.id`                   | 整数  | ユーザーのID。 |
| `user.name`                 | 文字列   | ユーザーの名前。 |
| `user.state`                | 文字列   | ユーザーアカウントのユーザー状態。 |
| `user.username`             | 文字列   | ユーザーのユーザー名。 |
| `user.web_url`              | 文字列   | ユーザープロファイルのWeb URL。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_trains"
```

レスポンス例:

```json
[
  {
    "id": 110,
    "merge_request": {
      "id": 126,
      "iid": 59,
      "project_id": 20,
      "title": "Test MR 1580978354",
      "description": "",
      "state": "merged",
      "created_at": "2020-02-06T08:39:14.883Z",
      "updated_at": "2020-02-06T08:40:57.038Z",
      "web_url": "http://local.gitlab.test:8181/root/merge-train-race-condition/-/merge_requests/59"
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://local.gitlab.test:8181/root"
    },
    "pipeline": {
      "id": 246,
      "sha": "bcc17a8ffd51be1afe45605e714085df28b80b13",
      "ref": "refs/merge-requests/59/train",
      "status": "success",
      "created_at": "2020-02-06T08:40:42.410Z",
      "updated_at": "2020-02-06T08:40:46.912Z",
      "web_url": "http://local.gitlab.test:8181/root/merge-train-race-condition/pipelines/246"
    },
    "created_at": "2020-02-06T08:39:47.217Z",
    "updated_at": "2020-02-06T08:40:57.720Z",
    "target_branch": "feature-1580973432",
    "status": "merged",
    "merged_at": "2020-02-06T08:40:57.719Z",
    "duration": 70
  }
]
```

## マージトレイン内のすべてのマージリクエストをリストします {#list-all-merge-requests-in-a-merge-train}

ターゲットブランチのマージトレイン内のすべてのマージリクエストをリストします。

```plaintext
GET /projects/:id/merge_trains/:target_branch
```

サポートされている属性: 

| 属性       | 型              | 必須 | 説明 |
| --------------- | ----------------- | -------- | ----------- |
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `target_branch` | 文字列            | はい      | マージトレインのターゲットブランチ。 |
| `scope`         | 文字列            | いいえ       | 指定されたスコープでフィルタリングされたマージトレインを返します。使用可能なスコープは、`active`（マージ対象）および`complete`（マージ済み）です。 |
| `sort`          | 文字列            | いいえ       | `asc`または`desc`順にソートされたマージトレインを返します。デフォルトは`desc`です。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                   | 型     | 説明 |
| --------------------------- | -------- | ----------- |
| `created_at`                | 日時 | マージトレインが作成されたときのタイムスタンプ。 |
| `duration`                  | 整数  | マージトレインに費やした時間（秒単位）。完了していない場合は`null`。 |
| `id`                        | 整数  | マージトレインのID。 |
| `merged_at`                 | 日時 | マージリクエストがマージされたときのタイムスタンプ。マージされていない場合は`null`。 |
| `merge_request`             | オブジェクト   | マージリクエストの詳細。 |
| `merge_request.created_at`  | 日時 | マージリクエストが作成されたときのタイムスタンプ。 |
| `merge_request.description` | 文字列   | マージリクエストの説明。 |
| `merge_request.id`          | 整数  | マージリクエストのID。 |
| `merge_request.iid`         | 整数  | マージリクエストの内部ID。 |
| `merge_request.project_id`  | 整数  | マージリクエストを含むプロジェクトのID。 |
| `merge_request.state`       | 文字列   | マージリクエストの状態。 |
| `merge_request.title`       | 文字列   | マージリクエストのタイトル。 |
| `merge_request.updated_at`  | 日時 | マージリクエストが最後に更新されたときのタイムスタンプ。 |
| `merge_request.web_url`     | 文字列   | マージリクエストのWeb URL。 |
| `pipeline`                  | オブジェクト   | パイプラインの詳細。パイプラインが関連付けられていない場合は`null`。 |
| `pipeline.created_at`       | 日時 | パイプラインが作成されたときのタイムスタンプ。 |
| `pipeline.id`               | 整数  | パイプラインのID。 |
| `pipeline.iid`              | 整数  | パイプラインの内部ID。 |
| `pipeline.project_id`       | 整数  | パイプラインを含むプロジェクトのID。 |
| `pipeline.ref`              | 文字列   | パイプラインのGit参照。 |
| `pipeline.sha`              | 文字列   | パイプラインをトリガーしたコミットのSHA。 |
| `pipeline.source`           | 文字列   | パイプライントリガーのソース。 |
| `pipeline.status`           | 文字列   | パイプラインのステータス。 |
| `pipeline.updated_at`       | 日時 | パイプラインが最後に更新されたときのタイムスタンプ。 |
| `pipeline.web_url`          | 文字列   | パイプラインのWeb URL。 |
| `status`                    | 文字列   | マージトレインのステータス。指定可能な値：`idle`、`stale`、`fresh`、`merging`、`merged`、`skip_merged`。 |
| `target_branch`             | 文字列   | ターゲットブランチの名前。 |
| `updated_at`                | 日時 | マージトレインが最後に更新されたときのタイムスタンプ。 |
| `user`                      | オブジェクト   | マージリクエストをマージトレインに追加したユーザー。 |
| `user.avatar_url`           | 文字列   | ユーザーのアバターURL。 |
| `user.id`                   | 整数  | ユーザーのID。 |
| `user.name`                 | 文字列   | ユーザーの名前。 |
| `user.state`                | 文字列   | ユーザーアカウントのユーザー状態。 |
| `user.username`             | 文字列   | ユーザーのユーザー名。 |
| `user.web_url`              | 文字列   | ユーザープロファイルのWeb URL。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/main"
```

レスポンス例:

```json
[
  {
    "id": 267,
    "merge_request": {
      "id": 273,
      "iid": 1,
      "project_id": 597,
      "title": "My title 9",
      "description": null,
      "state": "opened",
      "created_at": "2022-10-31T19:06:05.725Z",
      "updated_at": "2022-10-31T19:06:05.725Z",
      "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
    },
    "user": {
      "id": 933,
      "username": "user12",
      "name": "Sidney Jones31",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
      "web_url": "http://localhost/user12"
    },
    "pipeline": {
      "id": 273,
      "iid": 1,
      "project_id": 598,
      "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
      "ref": "main",
      "status": "pending",
      "source": "push",
      "created_at": "2022-10-31T19:06:06.231Z",
      "updated_at": "2022-10-31T19:06:06.231Z",
      "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
    },
    "created_at": "2022-10-31T19:06:06.237Z",
    "updated_at": "2022-10-31T19:06:06.237Z",
    "target_branch": "main",
    "status": "idle",
    "merged_at": null,
    "duration": null
  }
]
```

## マージトレインステータスを取得する {#retrieve-merge-train-status}

指定されたマージリクエストのマージトレインステータスを取得する。

```plaintext
GET /projects/:id/merge_trains/merge_requests/:merge_request_iid
```

サポートされている属性: 

| 属性           | 型              | 必須 | 説明 |
| ------------------- | ----------------- | -------- | ----------- |
| `id`                | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | マージリクエストの内部ID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                   | 型     | 説明 |
| --------------------------- | -------- | ----------- |
| `created_at`                | 日時 | マージトレインが作成されたときのタイムスタンプ。 |
| `duration`                  | 整数  | マージトレインに費やした時間（秒単位）。完了していない場合は`null`。 |
| `id`                        | 整数  | マージトレインのID。 |
| `merged_at`                 | 日時 | マージリクエストがマージされたときのタイムスタンプ。マージされていない場合は`null`。 |
| `merge_request`             | オブジェクト   | マージリクエストの詳細。 |
| `merge_request.created_at`  | 日時 | マージリクエストが作成されたときのタイムスタンプ。 |
| `merge_request.description` | 文字列   | マージリクエストの説明。 |
| `merge_request.id`          | 整数  | マージリクエストのID。 |
| `merge_request.iid`         | 整数  | マージリクエストの内部ID。 |
| `merge_request.project_id`  | 整数  | マージリクエストを含むプロジェクトのID。 |
| `merge_request.state`       | 文字列   | マージリクエストの状態。 |
| `merge_request.title`       | 文字列   | マージリクエストのタイトル。 |
| `merge_request.updated_at`  | 日時 | マージリクエストが最後に更新されたときのタイムスタンプ。 |
| `merge_request.web_url`     | 文字列   | マージリクエストのWeb URL。 |
| `pipeline`                  | オブジェクト   | パイプラインの詳細。パイプラインが関連付けられていない場合は`null`。 |
| `pipeline.created_at`       | 日時 | パイプラインが作成されたときのタイムスタンプ。 |
| `pipeline.id`               | 整数  | パイプラインのID。 |
| `pipeline.iid`              | 整数  | パイプラインの内部ID。 |
| `pipeline.project_id`       | 整数  | パイプラインを含むプロジェクトのID。 |
| `pipeline.ref`              | 文字列   | パイプラインのGit参照。 |
| `pipeline.sha`              | 文字列   | パイプラインをトリガーしたコミットのSHA。 |
| `pipeline.source`           | 文字列   | パイプライントリガーのソース。 |
| `pipeline.status`           | 文字列   | パイプラインのステータス。 |
| `pipeline.updated_at`       | 日時 | パイプラインが最後に更新されたときのタイムスタンプ。 |
| `pipeline.web_url`          | 文字列   | パイプラインのWeb URL。 |
| `status`                    | 文字列   | マージトレインのステータス。指定可能な値：`idle`、`stale`、`fresh`、`merging`、`merged`、`skip_merged`。 |
| `target_branch`             | 文字列   | ターゲットブランチの名前。 |
| `updated_at`                | 日時 | マージトレインが最後に更新されたときのタイムスタンプ。 |
| `user`                      | オブジェクト   | マージリクエストをマージトレインに追加したユーザー。 |
| `user.avatar_url`           | 文字列   | ユーザーのアバターURL。 |
| `user.id`                   | 整数  | ユーザーのID。 |
| `user.name`                 | 文字列   | ユーザーの名前。 |
| `user.state`                | 文字列   | ユーザーアカウントのユーザー状態。 |
| `user.username`             | 文字列   | ユーザーのユーザー名。 |
| `user.web_url`              | 文字列   | ユーザープロファイルのWeb URL。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/merge_requests/1"
```

レスポンス例:

```json
{
  "id": 267,
  "merge_request": {
    "id": 273,
    "iid": 1,
    "project_id": 597,
    "title": "My title 9",
    "description": null,
    "state": "opened",
    "created_at": "2022-10-31T19:06:05.725Z",
    "updated_at": "2022-10-31T19:06:05.725Z",
    "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
  },
  "user": {
    "id": 933,
    "username": "user12",
    "name": "Sidney Jones31",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
    "web_url": "http://localhost/user12"
  },
  "pipeline": {
    "id": 273,
    "iid": 1,
    "project_id": 598,
    "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
    "ref": "main",
    "status": "pending",
    "source": "push",
    "created_at": "2022-10-31T19:06:06.231Z",
    "updated_at": "2022-10-31T19:06:06.231Z",
    "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
  },
  "created_at": "2022-10-31T19:06:06.237Z",
  "updated_at": "2022-10-31T19:06:06.237Z",
  "target_branch": "main",
  "status": "idle",
  "merged_at": null,
  "duration": null
}
```

## マージリクエストをマージトレインに追加します {#add-a-merge-request-to-a-merge-train}

指定されたマージリクエストをマージトレインに追加します。

```plaintext
POST /projects/:id/merge_trains/merge_requests/:merge_request_iid
```

サポートされている属性: 

| 属性                | 型              | 必須 | 説明 |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid`      | 整数           | はい      | マージリクエストの内部ID。 |
| `auto_merge`             | ブール値           | いいえ       | trueの場合、チェックに合格すると、マージリクエストがマージトレインに追加されます。falseまたは未指定の場合、マージリクエストはマージトレインに直接追加されます。 |
| `sha`                    | 文字列            | いいえ       | 存在する場合、SHAはソースブランチの`HEAD`と一致する必要があります。そうでない場合、マージは失敗します。 |
| `squash`                 | ブール値           | いいえ       | trueの場合、コミットはマージ時に単一のコミットにスカッシュされます。 |
| `when_pipeline_succeeds` | ブール値           | いいえ       | GitLab 17.11で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/521290)になりました。代わりに`auto_merge`を使用してください。 |

成功した場合、以下を返します:

- [`201 Created`](rest/troubleshooting.md#status-codes)マージリクエストがマージトレインにすぐに追加される場合。
- [`202 Accepted`](rest/troubleshooting.md#status-codes)マージリクエストがマージトレインに追加されるようにスケジュールされている場合。

次のレスポンス属性が返されます:

| 属性                   | 型     | 説明 |
| --------------------------- | -------- | ----------- |
| `created_at`                | 日時 | マージトレインが作成されたときのタイムスタンプ。 |
| `duration`                  | 整数  | マージトレインに費やした時間（秒単位）。完了していない場合は`null`。 |
| `id`                        | 整数  | マージトレインのID。 |
| `merged_at`                 | 日時 | マージリクエストがマージされたときのタイムスタンプ。マージされていない場合は`null`。 |
| `merge_request`             | オブジェクト   | マージリクエストの詳細。 |
| `merge_request.created_at`  | 日時 | マージリクエストが作成されたときのタイムスタンプ。 |
| `merge_request.description` | 文字列   | マージリクエストの説明。 |
| `merge_request.id`          | 整数  | マージリクエストのID。 |
| `merge_request.iid`         | 整数  | マージリクエストの内部ID。 |
| `merge_request.project_id`  | 整数  | マージリクエストを含むプロジェクトのID。 |
| `merge_request.state`       | 文字列   | マージリクエストの状態。 |
| `merge_request.title`       | 文字列   | マージリクエストのタイトル。 |
| `merge_request.updated_at`  | 日時 | マージリクエストが最後に更新されたときのタイムスタンプ。 |
| `merge_request.web_url`     | 文字列   | マージリクエストのWeb URL。 |
| `pipeline`                  | オブジェクト   | パイプラインの詳細。パイプラインが関連付けられていない場合は`null`。 |
| `pipeline.created_at`       | 日時 | パイプラインが作成されたときのタイムスタンプ。 |
| `pipeline.id`               | 整数  | パイプラインのID。 |
| `pipeline.iid`              | 整数  | パイプラインの内部ID。 |
| `pipeline.project_id`       | 整数  | パイプラインを含むプロジェクトのID。 |
| `pipeline.ref`              | 文字列   | パイプラインのGit参照。 |
| `pipeline.sha`              | 文字列   | パイプラインをトリガーしたコミットのSHA。 |
| `pipeline.source`           | 文字列   | パイプライントリガーのソース。 |
| `pipeline.status`           | 文字列   | パイプラインのステータス。 |
| `pipeline.updated_at`       | 日時 | パイプラインが最後に更新されたときのタイムスタンプ。 |
| `pipeline.web_url`          | 文字列   | パイプラインのWeb URL。 |
| `status`                    | 文字列   | マージトレインのステータス。指定可能な値：`idle`、`stale`、`fresh`、`merging`、`merged`、`skip_merged`。 |
| `target_branch`             | 文字列   | ターゲットブランチの名前。 |
| `updated_at`                | 日時 | マージトレインが最後に更新されたときのタイムスタンプ。 |
| `user`                      | オブジェクト   | マージリクエストをマージトレインに追加したユーザー。 |
| `user.avatar_url`           | 文字列   | ユーザーのアバターURL。 |
| `user.id`                   | 整数  | ユーザーのID。 |
| `user.name`                 | 文字列   | ユーザーの名前。 |
| `user.state`                | 文字列   | ユーザーアカウントのユーザー状態。 |
| `user.username`             | 文字列   | ユーザーのユーザー名。 |
| `user.web_url`              | 文字列   | ユーザープロファイルのWeb URL。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/merge_requests/1"
```

レスポンス例:

```json
[
  {
    "id": 267,
    "merge_request": {
      "id": 273,
      "iid": 1,
      "project_id": 597,
      "title": "My title 9",
      "description": null,
      "state": "opened",
      "created_at": "2022-10-31T19:06:05.725Z",
      "updated_at": "2022-10-31T19:06:05.725Z",
      "web_url": "http://localhost/namespace18/project21/-/merge_requests/1"
    },
    "user": {
      "id": 933,
      "username": "user12",
      "name": "Sidney Jones31",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80&d=identicon",
      "web_url": "http://localhost/user12"
    },
    "pipeline": {
      "id": 273,
      "iid": 1,
      "project_id": 598,
      "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
      "ref": "main",
      "status": "pending",
      "source": "push",
      "created_at": "2022-10-31T19:06:06.231Z",
      "updated_at": "2022-10-31T19:06:06.231Z",
      "web_url": "http://localhost/namespace19/project22/-/pipelines/273"
    },
    "created_at": "2022-10-31T19:06:06.237Z",
    "updated_at": "2022-10-31T19:06:06.237Z",
    "target_branch": "main",
    "status": "idle",
    "merged_at": null,
    "duration": null
  }
]
```
