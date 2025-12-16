---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: デプロイAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab CI/CDジョブトークン](../ci/jobs/ci_job_token.md)認証のサポートが、GitLab 16.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/414549)。

{{< /history >}}

このAPIを使用して、GitLab環境への[コードデプロイ](../ci/environments/deployments.md)とやり取りします。

## プロジェクトデプロイの一覧表示 {#list-project-deployments}

プロジェクト内のデプロイの一覧を取得します。

```plaintext
GET /projects/:id/deployments
```

| 属性         | 型           | 必須 | 説明                                                                                                     |
|-------------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`              | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `order_by`        | 文字列         | いいえ       | `id`、`iid`、`created_at`、`updated_at`、`finished_at`、`ref`のいずれかのフィールドで順序付けられたデプロイを返します。デフォルトは`id`です。    |
| `sort`            | 文字列         | いいえ       | `asc`または`desc`の順にソートされたデプロイを返します。デフォルトは`asc`です。                                            |
| `updated_after`   | 日時       | いいえ       | 指定された日付より後に更新されたデプロイを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `updated_before`  | 日時       | いいえ       | 指定された日付より前に更新されたデプロイを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `finished_after`  | 日時       | いいえ       | 指定された日付より後に完了したデプロイを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `finished_before` | 日時       | いいえ       | 指定された日付より前に完了したデプロイを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `environment`     | 文字列         | いいえ       | デプロイをフィルタリングする[環境名](../ci/environments/_index.md)。       |
| `status`          | 文字列         | いいえ       | デプロイをフィルタリングするステータス。`created`、`running`、`success`、`failed`、`canceled`、`blocked`のいずれか。 |

```shell
curl --request "GET" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments"
```

{{< alert type="note" >}}

`finished_before`または`finished_after`を使用する場合は、`order_by`を`finished_at`に指定し、`status`を`success`にする必要があります。

{{< /alert >}}

レスポンス例:

```json
[
  {
    "created_at": "2016-08-11T07:36:40.222Z",
    "updated_at": "2016-08-11T07:38:12.414Z",
    "status": "created",
    "deployable": {
      "commit": {
        "author_email": "admin@example.com",
        "author_name": "Administrator",
        "created_at": "2016-08-11T09:36:01.000+02:00",
        "id": "99d03678b90d914dbb1b109132516d71a4a03ea8",
        "message": "Merge branch 'new-title' into 'main'\r\n\r\nUpdate README\r\n\r\n\r\n\r\nSee merge request !1",
        "short_id": "99d03678",
        "title": "Merge branch 'new-title' into 'main'\r"
      },
      "coverage": null,
      "created_at": "2016-08-11T07:36:27.357Z",
      "finished_at": "2016-08-11T07:36:39.851Z",
      "id": 657,
      "name": "deploy",
      "ref": "main",
      "runner": null,
      "stage": "deploy",
      "started_at": null,
      "status": "success",
      "tag": false,
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
        "organization": ""
      },
      "pipeline": {
        "created_at": "2016-08-11T02:12:10.222Z",
        "id": 36,
        "ref": "main",
        "sha": "99d03678b90d914dbb1b109132516d71a4a03ea8",
        "status": "success",
        "updated_at": "2016-08-11T02:12:10.222Z",
        "web_url": "http://gitlab.dev/root/project/pipelines/12"
      }
    },
    "environment": {
      "external_url": "https://about.gitlab.com",
      "id": 9,
      "name": "production"
    },
    "id": 41,
    "iid": 1,
    "ref": "main",
    "sha": "99d03678b90d914dbb1b109132516d71a4a03ea8",
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "web_url": "http://localhost:3000/root"
    }
  },
  {
    "created_at": "2016-08-11T11:32:35.444Z",
    "updated_at": "2016-08-11T11:34:01.123Z",
    "status": "created",
    "deployable": {
      "commit": {
        "author_email": "admin@example.com",
        "author_name": "Administrator",
        "created_at": "2016-08-11T13:28:26.000+02:00",
        "id": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "message": "Merge branch 'rename-readme' into 'main'\r\n\r\nRename README\r\n\r\n\r\n\r\nSee merge request !2",
        "short_id": "a91957a8",
        "title": "Merge branch 'rename-readme' into 'main'\r"
      },
      "coverage": null,
      "created_at": "2016-08-11T11:32:24.456Z",
      "finished_at": "2016-08-11T11:32:35.145Z",
      "id": 664,
      "name": "deploy",
      "ref": "main",
      "runner": null,
      "stage": "deploy",
      "started_at": null,
      "status": "success",
      "tag": false,
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
        "organization": ""
      },
      "pipeline": {
        "created_at": "2016-08-11T07:43:52.143Z",
        "id": 37,
        "ref": "main",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "status": "success",
        "updated_at": "2016-08-11T07:43:52.143Z",
        "web_url": "http://gitlab.dev/root/project/pipelines/13"
      }
    },
    "environment": {
      "external_url": "https://about.gitlab.com",
      "id": 9,
      "name": "production"
    },
    "id": 42,
    "iid": 2,
    "ref": "main",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "web_url": "http://localhost:3000/root"
    }
  }
]
```

## 特定のデプロイを取得 {#get-a-specific-deployment}

```plaintext
GET /projects/:id/deployments/:deployment_id
```

| 属性 | 型    | 必須 | 説明         |
|-----------|---------|----------|---------------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `deployment_id` | 整数 | はい      | デプロイのID |

```shell
curl --request "GET" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/1"
```

レスポンス例:

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "updated_at": "2016-08-11T11:34:01.123Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": {
    "id": 664,
    "status": "success",
    "stage": "deploy",
    "name": "deploy",
    "ref": "main",
    "tag": false,
    "coverage": null,
    "created_at": "2016-08-11T11:32:24.456Z",
    "started_at": null,
    "finished_at": "2016-08-11T11:32:35.145Z",
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
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    },
    "commit": {
      "id": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "short_id": "a91957a8",
      "title": "Merge branch 'rename-readme' into 'main'\r",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "created_at": "2016-08-11T13:28:26.000+02:00",
      "message": "Merge branch 'rename-readme' into 'main'\r\n\r\nRename README\r\n\r\n\r\n\r\nSee merge request !2"
    },
    "pipeline": {
      "created_at": "2016-08-11T07:43:52.143Z",
      "id": 42,
      "ref": "main",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "status": "success",
      "updated_at": "2016-08-11T07:43:52.143Z",
      "web_url": "http://gitlab.dev/root/project/pipelines/5"
    },
    "runner": null
  }
}
```

複数の[承認ルール](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)が設定されている場合、GitLab PremiumまたはUltimateのユーザーが作成したデプロイには、`approval_summary`プロパティが含まれています:

```json
{
  "approval_summary": {
    "rules": [
      {
        "user_id": null,
        "group_id": 134,
        "access_level": null,
        "access_level_description": "qa-group",
        "required_approvals": 1,
        "deployment_approvals": []
      },
      {
        "user_id": null,
        "group_id": 135,
        "access_level": null,
        "access_level_description": "security-group",
        "required_approvals": 2,
        "deployment_approvals": [
          {
            "user": {
              "id": 100,
              "username": "security-user-1",
              "name": "security user-1",
              "state": "active",
              "avatar_url": "https://www.gravatar.com/avatar/e130fcd3a1681f41a3de69d10841afa9?s=80&d=identicon",
              "web_url": "http://localhost:3000/security-user-1"
            },
            "status": "approved",
            "created_at": "2022-04-11T03:37:03.058Z",
            "comment": null
          }
        ]
      }
    ]
  }
  ...
}
```

## デプロイの作成 {#create-a-deployment}

```plaintext
POST /projects/:id/deployments
```

| 属性     | 型           | 必須 | 説明                                                                                                     |
|---------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。|
| `environment` | 文字列         | はい      | デプロイを作成する[環境名](../ci/environments/_index.md)。                        |
| `sha`         | 文字列         | はい      | デプロイされるコミットのSHA。                                                                         |
| `ref`         | 文字列         | はい      | デプロイされるブランチまたはタグの名前。                                                                 |
| `tag`         | ブール値        | はい      | デプロイされたrefsがタグ (`true`) かどうかを示すブール値、またはそうでないか (`false`) を示します。                                |
| `status`      | 文字列         | はい      | 作成されるデプロイのステータス。`running`、`success`、`failed`、`canceled`、、またはのいずれか        |

```shell
curl --request "POST" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "environment=production&sha=a91957a858320c0e17f3a0eca7cfacbff50ea29a&ref=main&tag=false&status=success" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments"
```

レスポンス例:

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": null
}
```

GitLab PremiumまたはUltimateのユーザーが作成したデプロイには、`approvals`プロパティと`pending_approval_count`プロパティが含まれています:

```json
{
  "status": "created",
  "pending_approval_count": 0,
  "approvals": [],
  ...
}
```

## デプロイの更新 {#update-a-deployment}

```plaintext
PUT /projects/:id/deployments/:deployment_id
```

| 属性        | 型           | 必須 | 説明         |
|------------------|----------------|----------|---------------------|
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `deployment_id`  | 整数        | はい      | 更新するデプロイのID。 |
| `status`         | 文字列         | はい      | デプロイの新しいステータス`running`、`success`、`failed`、`canceled`のいずれかです。                         |

```shell
curl --request "PUT" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "status=success" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/42"
```

レスポンス例:

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": null
}
```

GitLab PremiumまたはUltimateのユーザーが作成したデプロイには、`approvals`プロパティと`pending_approval_count`プロパティが含まれています:

```json
{
  "status": "created",
  "pending_approval_count": 0,
  "approvals": [
    {
      "user": {
        "id": 49,
        "username": "project_6_bot",
        "name": "****",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/e83ac685f68ea07553ad3054c738c709?s=80&d=identicon",
        "web_url": "http://localhost:3000/project_6_bot"
      },
      "status": "approved",
      "created_at": "2022-02-24T20:22:30.097Z",
      "comment": "Looks good to me"
    }
  ],
  ...
}
```

## 特定のデプロイを削除 {#delete-a-specific-deployment}

現在環境の最後のデプロイではない、または`running`状態ではない特定のデプロイを削除します

```plaintext
DELETE /projects/:id/deployments/:deployment_id
```

| 属性 | 型    | 必須 | 説明         |
|-----------|---------|----------|---------------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `deployment_id` | 整数 | はい      | デプロイのID |

```shell
curl --request "DELETE" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/1"
```

レスポンス例:

```json
{ "message": "204 Deployment destroyed" }
```

```json
{ "message": "403 Forbidden" }
```

```json
{ "message": "400 Cannot destroy running deployment" }
```

```json
{ "message": "400 Deployment currently deployed to environment" }
```

## デプロイに関連付けられたマージリクエストの一覧 {#list-of-merge-requests-associated-with-a-deployment}

{{< alert type="note" >}}

すべてのデプロイがマージリクエストに関連付けられるわけではありません。詳細については、[どのマージリクエストが環境にデプロイされたかを追跡する](../ci/environments/deployments.md#track-newly-included-merge-requests-per-deployment)を参照してください。

{{< /alert >}}

このAPIは、特定のデプロイで出荷されたマージリクエストの一覧を取得します:

```plaintext
GET /projects/:id/deployments/:deployment_id/merge_requests
```

これは、[マージリクエストAPI](merge_requests.md#list-merge-requests)と同じパラメータをサポートし、同じ形式で応答を返します:

```shell
curl --request "GET" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/42/merge_requests"
```

## ブロックされたデプロイを承認または拒否する {#approve-or-reject-a-blocked-deployment}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 14.7で、`deployment_approvals`[フラグ](../administration/feature_flags/_index.md)という名前の[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/343864)がされましたデフォルトでは無効になっています。
- GitLab 14.8で[機能フラグ](https://gitlab.com/gitlab-org/gitlab/-/issues/347342)が削除されました

{{< /history >}}

この機能の詳細については、[デプロイの承認](../ci/environments/deployment_approvals.md)を参照してください。

```plaintext
POST /projects/:id/deployments/:deployment_id/approval
```

| 属性       | 型           | 必須 | 説明                                                                                                     |
|-----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `deployment_id` | 整数        | はい      | デプロイのID                                                                                       |
| `status`        | 文字列         | はい      | 承認のステータス（`approved`または`rejected`のいずれか）                                                   |
| `comment`       | 文字列         | いいえ       | 承認に伴うコメント                                                                               |
| `represented_as`| 文字列         | いいえ       | ユーザーが[複数の承認ルール](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)に属している場合に、承認に使用するユーザー/グループ/ロールの名前 |

```shell
curl --request "POST" \
  --data "status=approved&comment=Looks good to me&represented_as=security" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/1/approval"
```

レスポンス例:

```json
{
  "user": {
    "id": 100,
    "username": "security-user-1",
    "name": "security user-1",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e130fcd3a1681f41a3de69d10841afa9?s=80&d=identicon",
    "web_url": "http://localhost:3000/security-user-1"
  },
  "status": "approved",
  "created_at": "2022-02-24T20:22:30.097Z",
  "comment":"Looks good to me"
}
```
