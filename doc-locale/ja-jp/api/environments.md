---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab環境のリスト表示、作成、更新、停止、削除を含む、GitLab環境を管理するためのAPIエンドポイント。
title: 環境API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- パラメータ`auto_stop_setting`はGitLab 17.8で[追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/428625)。
- [GitLab CI/CDジョブトークン](../ci/jobs/ci_job_token.md)認証のサポートはGitLab 16.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/414549)。

{{< /history >}}

このAPIを使用して、[GitLab環境](../ci/environments/_index.md)を操作します。

## すべての環境をリスト表示 {#list-all-environments}

指定されたプロジェクトのすべての環境をリスト表示します。

```plaintext
GET /projects/:id/environments
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `name`    | 文字列         | いいえ       | この名前の環境を返します。`search`と相互に排他的です。 |
| `search`  | 文字列         | いいえ       | 検索条件に一致する環境のリストを返します。`name`と相互に排他的です。3文字以上である必要があります。 |
| `states`  | 文字列         | いいえ       | 特定のステータスに一致するすべての環境をリスト表示します。使用可能な値: `available`、`stopping`、または`stopped`。ステータス値が指定されていない場合、すべての環境を返します。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments?name=review%2Ffix-foo"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "review/fix-foo",
    "slug": "review-fix-foo-dfjre3",
    "description": "This is review environment",
    "external_url": "https://review-fix-foo-dfjre3.gitlab.example.com",
    "state": "available",
    "tier": "development",
    "created_at": "2019-05-25T18:55:13.252Z",
    "updated_at": "2019-05-27T18:55:13.252Z",
    "enable_advanced_logs_querying": false,
    "logs_api_path": "/project/-/logs/k8s.json?environment_name=review%2Ffix-foo",
    "auto_stop_at": "2019-06-03T18:55:13.252Z",
    "kubernetes_namespace": "flux-system",
    "flux_resource_path": "HelmRelease/flux-system",
    "auto_stop_setting": "always"
  }
]
```

## 環境を取得する {#retrieve-an-environment}

プロジェクトの指定された環境を取得する。

```plaintext
GET /projects/:id/environments/:environment_id
```

| 属性        | 型           | 必須 | 説明 |
|------------------|----------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `environment_id` | 整数        | はい      | 環境のID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

レスポンス例

```json
{
  "id": 1,
  "name": "review/fix-foo",
  "slug": "review-fix-foo-dfjre3",
  "description": "This is review environment",
  "external_url": "https://review-fix-foo-dfjre3.gitlab.example.com",
  "state": "available",
  "tier": "development",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "enable_advanced_logs_querying": false,
  "logs_api_path": "/project/-/logs/k8s.json?environment_name=review%2Ffix-foo",
  "auto_stop_at": "2019-06-03T18:55:13.252Z",
  "last_deployment": {
    "id": 100,
    "iid": 34,
    "ref": "fdroid",
    "sha": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
    "created_at": "2019-03-25T18:55:13.252Z",
    "status": "success",
    "user": {
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "deployable": {
      "id": 710,
      "status": "success",
      "stage": "deploy",
      "name": "staging",
      "ref": "fdroid",
      "tag": false,
      "coverage": null,
      "created_at": "2019-03-25T18:55:13.215Z",
      "started_at": "2019-03-25T12:54:50.082Z",
      "finished_at": "2019-03-25T18:55:13.216Z",
      "duration": 21623.13423,
      "project": {
        "ci_job_token_scope_enabled": false
      },
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://gitlab.dev/root",
        "created_at": "2015-12-21T13:14:24.077Z",
        "bio": null,
        "location": null,
        "public_email": "",
        "linkedin": "",
        "twitter": "",
        "website_url": "",
        "organization": null
      },
      "commit": {
        "id": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
        "short_id": "416d8ea1",
        "created_at": "2016-01-02T15:39:18.000Z",
        "parent_ids": [
          "e9a4449c95c64358840902508fc827f1a2eab7df"
        ],
        "title": "Removed fabric to fix #40",
        "message": "Removed fabric to fix #40\n",
        "author_name": "Administrator",
        "author_email": "admin@example.com",
        "authored_date": "2016-01-02T15:39:18.000Z",
        "committer_name": "Administrator",
        "committer_email": "admin@example.com",
        "committed_date": "2016-01-02T15:39:18.000Z"
      },
      "pipeline": {
        "id": 34,
        "sha": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
        "ref": "fdroid",
        "status": "success",
        "web_url": "http://localhost:3000/Commit451/lab-coat/pipelines/34"
      },
      "web_url": "http://localhost:3000/Commit451/lab-coat/-/jobs/710",
      "artifacts": [
        {
          "file_type": "trace",
          "size": 1305,
          "filename": "job.log",
          "file_format": null
        }
      ],
      "runner": null,
      "artifacts_expire_at": null
    }
  },
  "cluster_agent": {
    "id": 1,
    "name": "agent-1",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  },
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## 環境の作成 {#create-an-environment}

指定されたプロジェクトの環境を作成します。

```plaintext
POST /projects/:id/environments
```

| 属性              | 型           | 必須 | 説明 |
|------------------------|----------------|----------|-------------|
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`                 | 文字列         | はい      | 環境の名前。 |
| `description`          | 文字列         | いいえ       | 環境の説明。 |
| `external_url`         | 文字列         | いいえ       | この環境にリンクする場所。 |
| `tier`                 | 文字列         | いいえ       | 新しい環境のティア。使用可能な値は、`production`、`staging`、`testing`、`development`、および`other`です。 |
| `cluster_agent_id`     | 整数        | いいえ       | この環境に関連付けるクラスターエージェント。 |
| `kubernetes_namespace` | 文字列         | いいえ       | この環境に関連付けるKubernetesネームスペース。 |
| `flux_resource_path`   | 文字列         | いいえ       | この環境に関連付けるFluxリソースパス。これはリソースのフルパスでなければなりません。例: `helm.toolkit.fluxcd.io/v2/namespaces/gitlab-agent/helmreleases/gitlab-agent`。 |
| `auto_stop_setting`    | 文字列         | いいえ       | 環境の自動停止設定。使用可能な値は`always`または`with_action`です。 |

成功した場合、`201`を返します。パラメータが間違っている場合、`400`を返します。

```shell
curl --data "name=deploy&external_url=https://deploy.gitlab.example.com" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "description": null,
  "external_url": "https://deploy.gitlab.example.com",
  "state": "available",
  "tier": "production",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## 既存の環境を更新 {#update-an-existing-environment}

{{< history >}}

- パラメータ`name`はGitLab 16.0で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/338897)。

{{< /history >}}

プロジェクトの既存の環境を更新します。

```plaintext
PUT /projects/:id/environments/:environments_id
```

| 属性              | 型            | 必須 | 説明 |
|------------------------|-----------------|----------|-------------|
| `id`                   | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `environment_id`       | 整数         | はい      | 環境のID。 |
| `description`          | 文字列          | いいえ       | 環境の説明。 |
| `external_url`         | 文字列          | いいえ       | 新しい`external_url`。 |
| `tier`                 | 文字列          | いいえ       | 新しい環境のティア。使用可能な値は、`production`、`staging`、`testing`、`development`、および`other`です。 |
| `cluster_agent_id`     | 整数またはnull | いいえ       | この環境に関連付けるクラスターエージェント、またはそれを削除するための`null`。 |
| `kubernetes_namespace` | stringまたはnull  | いいえ       | この環境に関連付けるKubernetesネームスペース、またはそれを削除するための`null`。 |
| `flux_resource_path`   | stringまたはnull  | いいえ       | この環境に関連付けるFluxリソースパス、またはそれを削除するための`null`。 |
| `auto_stop_setting`    | stringまたはnull  | いいえ       | 環境の自動停止設定。使用可能な値は`always`または`with_action`です。 |

成功した場合、`200`を返します。エラーが発生した場合、`400`を返します。

```shell
curl --request PUT \
  --data "external_url=https://staging.gitlab.example.com" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "staging",
  "slug": "staging",
  "description": null,
  "external_url": "https://staging.gitlab.example.com",
  "state": "available",
  "tier": "staging",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## 環境を削除する {#delete-an-environment}

プロジェクトから環境を削除します。環境は最初に停止する必要があります。

```plaintext
DELETE /projects/:id/environments/:environment_id
```

| 属性        | 型           | 必須 | 説明 |
|------------------|----------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `environment_id` | 整数        | はい      | 環境のID。 |

成功した場合、`204`を返します。環境が存在しない場合、`404`を返します。環境が停止していない場合、`403`を返します。

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

## 停止した複数のレビューアプリを削除 {#delete-multiple-stopped-review-apps}

既に[停止](../ci/environments/_index.md#stopping-an-environment)され、[レビューアプリフォルダー](../ci/review_apps/_index.md)にある複数の環境の削除をスケジュールします。実際の削除は、実行時刻から1週間後に実行されます。デフォルトでは、30日以上前の環境のみが削除されます。

```plaintext
DELETE /projects/:id/environments/review_apps
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `before`  | 日時       | いいえ       | 環境を削除できる日付。デフォルトは30日前です。ISO 8601形式（`YYYY-MM-DDTHH:MM:SSZ`）で指定します。 |
| `limit`   | 整数        | いいえ       | 削除する環境の最大数。デフォルトは100です。 |
| `dry_run` | ブール値        | いいえ       | 安全のため、デフォルトは`true`です。実際の削除は行われないドライランを実行します。環境を実際に削除するには`false`に設定します。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/review_apps"
```

レスポンス例: 

```json
{
  "scheduled_entries": [
    {
      "id": 387,
      "name": "review/023f1bce01229c686a73",
      "slug": "review-023f1bce01-3uxznk",
      "external_url": null
    },
    {
      "id": 388,
      "name": "review/85d4c26a388348d3c4c0",
      "slug": "review-85d4c26a38-5giw1c",
      "external_url": null
    }
  ],
  "unprocessable_entries": []
}
```

## 環境を停止 {#stop-an-environment}

実行中の環境を停止します。

```plaintext
POST /projects/:id/environments/:environment_id/stop
```

| 属性        | 型           | 必須 | 説明 |
|------------------|----------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `environment_id` | 整数        | はい      | 環境のID。 |
| `force`          | ブール値        | いいえ       | `on_stop`アクションを実行せずに環境を強制的に停止します。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1/stop"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "external_url": "https://deploy.gitlab.example.com",
  "state": "stopped",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## 古い環境を停止 {#stop-stale-environments}

指定された日付より前に最終更新またはデプロイされたすべての環境を停止します。保護環境を除外します。

```plaintext
POST /projects/:id/environments/stop_stale
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `before`  | 日付           | はい      | 指定された日付より前に変更またはデプロイされた環境を停止します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。有効な入力は10年前から1週間前までです。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/stop_stale?before=10%2F10%2F2021"
```

レスポンス例: 

```json
{
  "message": "Successfully requested stop for all stale environments"
}
```
