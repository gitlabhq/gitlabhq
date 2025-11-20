---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: マージトレインAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[マージトレイン](../ci/pipelines/merge_trains.md)を操作します。

前提要件: 

- デベロッパーロール以上が必要です。

## プロジェクトのマージトレインを一覧表示 {#list-merge-trains-for-a-project}

リクエストされたプロジェクトのすべてのマージトレインを取得します:

```plaintext
GET /projects/:id/merge_trains
GET /projects/:id/merge_trains?scope=complete
```

結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `scope`   | 文字列         | いいえ       | 指定されたスコープでフィルタリングされたマージトレインを返します。使用可能なスコープは、`active`（マージ対象）と`complete`（マージ済み）です。 |
| `sort`    | 文字列         | いいえ       | `asc`または`desc`の順にソートされたマージトレインを返します。デフォルトは`desc`です。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_trains"
```

戻り値:

- プロジェクトでマージトレインが利用できない場合は`403: Forbidden`
- ユーザーがプライベートプロジェクトのメンバーでない場合は`404: Not Found`

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

## マージトレイン内のマージリクエストを一覧表示 {#list-merge-requests-in-a-merge-train}

リクエストされたターゲットブランチのマージトレインに追加されたすべてのマージリクエストを取得します。

```plaintext
GET /projects/:id/merge_trains/:target_branch
```

結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

サポートされている属性は以下のとおりです:

| 属性       | 型           | 必須 | 説明 |
|-----------------|----------------|----------|-------------|
| `id`            | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `target_branch` | 文字列         | はい      | マージトレインのターゲットブランチ。 |
| `scope`         | 文字列         | いいえ       | 指定されたスコープでフィルタリングされたマージトレインを返します。使用可能なスコープは、`active`（マージ対象）と`complete`（マージ済み）です。 |
| `sort`          | 文字列         | いいえ       | `asc`または`desc`の順にソートされたマージトレインを返します。デフォルトは`desc`です。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/main"
```

戻り値:

- プロジェクトでマージトレインが利用できない場合は`403: Forbidden`
- ユーザーがプライベートプロジェクトのメンバーでない場合は`404: Not Found`

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
      "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80\u0026d=identicon",
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
    "updated_at":"2022-10-31T19:06:06.237Z",
    "target_branch":"main",
    "status":"idle",
    "merged_at":null,
    "duration":null
  }
]
```

## マージトレイン上のマージリクエストのステータスを取得 {#get-the-status-of-a-merge-request-on-a-merge-train}

リクエストされたマージリクエストのマージトレイン情報を取得します。

```plaintext
GET /projects/:id/merge_trains/merge_requests/:merge_request_iid
```

結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

サポートされている属性は以下のとおりです:

| 属性           | 型           | 必須 | 説明 |
|---------------------|----------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数        | はい      | マージリクエストの内部ID。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/merge_requests/1"
```

戻り値:

- プロジェクトでマージトレインが利用できない場合は`403: Forbidden`
- ユーザーがプライベートプロジェクトのメンバーでない場合は`404: Not Found`

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
    "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80\u0026d=identicon",
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
  "updated_at":"2022-10-31T19:06:06.237Z",
  "target_branch":"main",
  "status":"idle",
  "merged_at":null,
  "duration":null
}
```

## マージトレインにマージリクエストを追加する {#add-a-merge-request-to-a-merge-train}

マージリクエストのターゲットブランチを対象とするマージトレインにマージリクエストを追加します。

```plaintext
POST /projects/:id/merge_trains/merge_requests/:merge_request_iid
```

サポートされている属性は以下のとおりです:

| 属性                | 型           | 必須 | 説明 |
|--------------------------|----------------|----------|-------------|
| `id`                     | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid`      | 整数        | はい      | マージリクエストの内部ID。 |
| `auto_merge`             | ブール値        | いいえ       | trueの場合、チェックに合格すると、マージリクエストがマージトレインに追加されます。falseまたは未指定の場合、マージリクエストはマージトレインに直接追加されます。 |
| `sha`                    | 文字列         | いいえ       | 存在する場合、SHAはソースブランチの`HEAD`と一致している必要があります。一致しない場合、マージは失敗します。 |
| `squash`                 | ブール値        | いいえ       | trueの場合、コミットはマージ時に単一のコミットにスカッシュされます。 |
| `when_pipeline_succeeds` | ブール値        | いいえ       | GitLab 17.11で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/521290)になりました。代わりに`auto_merge`を使用してください。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/597/merge_trains/merge_requests/1"
```

成功した場合、以下を返します:

- マージリクエストがマージトレインにすぐに追加された場合は`201 Created`
- マージリクエストがマージトレインに追加されるようにスケジュールされている場合は`202 Accepted`

その他の発生しうる応答:

- マージに失敗した場合は`400 Bad Request`
- 認証が必要な場合は`401 Unauthorized`
- プロジェクトでマージトレインが利用できない場合は`403 Forbidden`
- プロジェクトまたはマージリクエストが見つからない場合は`404 Not Found`
- 競合するリソースがある場合は`409 Conflict`

成功すると、レスポンスには次の属性が含まれます:

| 属性                              | 型    | 説明 |
|----------------------------------------|---------|-------------|
| `created_at`                           | 日時 | マージトレインが作成されたときのタイムスタンプ。 |
| `duration`                             | 整数  | 秒単位の期間、または完了していない場合は`null`。 |
| `id`                                   | 整数  | マージトレインのID。 |
| `merge_request`                        | オブジェクト   | マージリクエストの詳細。 |
| `merge_request.created_at`             | 日時 | マージリクエストが作成された時点のタイムスタンプ。 |
| `merge_request.description`            | 文字列   | マージリクエストの説明。 |
| `merge_request.id`                     | 整数  | マージリクエストのID。 |
| `merge_request.iid`                    | 整数  | マージリクエストの内部ID。 |
| `merge_request.project_id`             | 整数  | マージリクエストを含むプロジェクトのID。 |
| `merge_request.state`                  | 文字列   | マージリクエストの状態。 |
| `merge_request.title`                  | 文字列   | マージリクエストのタイトル。 |
| `merge_request.updated_at`             | 日時 | マージリクエストの最終更新時のタイムスタンプ。 |
| `merge_request.web_url`                | 文字列   | マージリクエストのWeb URL。 |
| `merged_at`                            | 日時 | マージリクエストがマージされたときのタイムスタンプ。マージされていない場合は`null`。 |
| `pipeline`                             | オブジェクト   | パイプラインの詳細 |
| `pipeline.created_at`                  | 日時 | パイプラインの作成時のタイムスタンプ。 |
| `pipeline.id`                          | 整数  | パイプラインのID。 |
| `pipeline.iid`                         | 整数  | パイプラインの内部ID。 |
| `pipeline.project_id`                  | 整数  | パイプラインを含むプロジェクトのID。 |
| `pipeline.ref`                         | 文字列   | パイプラインのGit参照。 |
| `pipeline.sha`                         | 文字列   | パイプラインをトリガーしたコミットのSHA。 |
| `pipeline.source`                      | 文字列   | パイプライントリガーのソース。 |
| `pipeline.status`                      | 文字列   | パイプラインのステータス。 |
| `pipeline.updated_at`                  | 日時 | パイプラインの最終更新時のタイムスタンプ。 |
| `pipeline.web_url`                     | 文字列   | パイプラインのWeb URL。 |
| `status`                               | 文字列   | マージトレインのステータス。使用可能な値：`idle`、`merged`、`stale`、`fresh`、`merging`、`skip_merged`。 |
| `target_branch`                        | 文字列   | ターゲットブランチの名前。 |
| `updated_at`                           | 日時 | マージトレインの最終更新時のタイムスタンプ。 |
| `user`                                 | オブジェクト   | マージトレインにマージリクエストを追加したユーザー。 |
| `user.avatar_url`                      | 文字列   | ユーザーのアバターURL。 |
| `user.id`                              | 整数  | ユーザーのID。 |
| `user.name`                            | 文字列   | ユーザー名。 |
| `user.state`                           | 文字列   | ユーザーアカウントの状態。 |
| `user.username`                        | 文字列   | ユーザーのユーザー名。 |
| `user.web_url`                         | 文字列   | ユーザープロフィールのWeb URL。 |

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
      "avatar_url": "https://www.gravatar.com/avatar/6c8365de387cb3db10ecc7b1880203c4?s=80\u0026d=identicon",
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
    "updated_at":"2022-10-31T19:06:06.237Z",
    "target_branch":"main",
    "status":"idle",
    "merged_at":null,
    "duration":null
  }
]
```
