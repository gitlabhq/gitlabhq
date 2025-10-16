---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプライントリガートークンAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[パイプラインをトリガー](../ci/triggers/_index.md)します。

## プロジェクトのトリガートークンのリストを取得する {#list-project-trigger-tokens}

プロジェクトのパイプライントリガートークンのリストを取得します。

```plaintext
GET /projects/:id/triggers
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers"
```

```json
[
    {
        "id": 10,
        "description": "my trigger",
        "created_at": "2016-01-07T09:53:58.235Z",
        "last_used": null,
        "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
        "updated_at": "2016-01-07T09:53:58.235Z",
        "owner": null
    }
]
```

認証済みユーザーがトリガートークンを作成した場合、トリガートークンは完全に表示されます。他のユーザーが作成したトリガートークンは、4文字に短縮されます。

## トリガートークンの詳細を取得する {#get-trigger-token-details}

プロジェクトのパイプライントリガートークンの詳細を取得します。

```plaintext
GET /projects/:id/triggers/:trigger_id
```

| 属性    | 型           | 必須 | 説明 |
|--------------|----------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `trigger_id` | 整数        | はい      | トリガーID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers/5"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## トリガートークンを作成する {#create-a-trigger-token}

プロジェクトのパイプライントリガートークンを作成します。

```plaintext
POST /projects/:id/triggers
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `description` | 文字列         | はい      | トリガー名 |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form description="my description" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## パイプライントリガートークンを更新する {#update-a-pipeline-trigger-token}

プロジェクトのパイプライントリガートークンを更新します。

```plaintext
PUT /projects/:id/triggers/:trigger_id
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `trigger_id`  | 整数        | はい      | トリガーID |
| `description` | 文字列         | いいえ       | トリガー名 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form description="my description" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers/10"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## パイプライントリガートークンを削除する {#remove-a-pipeline-trigger-token}

プロジェクトのパイプライントリガートークンを削除します。

```plaintext
DELETE /projects/:id/triggers/:trigger_id
```

| 属性    | 型           | 必須 | 説明 |
|--------------|----------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `trigger_id` | 整数        | はい      | トリガーID |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers/5"
```

## トークンでパイプラインをトリガーする {#trigger-a-pipeline-with-a-token}

{{< history >}}

- `inputs`属性は、GitLab 17.10で`ci_inputs_for_pipelines`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519958)されました。デフォルトでは無効になっています。
- `inputs`属性は、GitLab 17.11で[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/525504)になりました。
- `inputs`属性は、GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/536548)になりました。機能フラグ`ci_inputs_for_pipelines`は削除されました。

{{< /history >}}

[パイプライントリガートークン](../ci/triggers/_index.md#create-a-pipeline-trigger-token)または[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)を使用して認証することにより、パイプラインをトリガーします。

CI/CDジョブトークンを使用すると、[トリガーされたパイプラインはマルチプロジェクトパイプラインになります](../ci/pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api)。リクエストを認証するジョブはアップストリームパイプラインに関連付けられ、パイプライングラフに表示されます。

ジョブでトリガートークンを使用する場合、ジョブはアップストリームパイプラインに関連付けられません。

```plaintext
POST /projects/:id/trigger/pipeline
```

サポートされている属性:

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `ref`       | 文字列         | はい      | パイプラインを実行するブランチまたはタグ。 |
| `token`     | 文字列         | はい      | トリガートークンまたはCI/CDジョブトークン。 |
| `variables` | ハッシュ           | いいえ       | パイプライン変数を含むキーと値の文字列のマップ。例: `{ VAR1: "value1", VAR2: "value2" }`。 |
| `inputs`    | ハッシュ           | いいえ       | パイプラインの作成時に使用するインプットのマップ（キーと値のペア）。 |

[変数](../ci/variables/_index.md)を使用したリクエストの例:

```shell
curl --request POST \
  --form "variables[VAR1]=value1" \
  --form "variables[VAR2]=value2" \
  --url "https://gitlab.example.com/api/v4/projects/123/trigger/pipeline?token=2cb1840fb9dfc9fb0b7b1609cd29cb&ref=main"
```

[インプット](../ci/inputs/_index.md)を使用したリクエストの例:

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --data '{"inputs": {"environment": "environment", "scan_security": false, "level": 3}}' \
  --url "https://gitlab.example.com/api/v4/projects/123/trigger/pipeline?token=2cb1840fb9dfc9fb0b7b1609cd29cb&ref=main"
```

応答の例:

```json
{
  "id": 257,
  "iid": 118,
  "project_id": 123,
  "sha": "91e2711a93e5d9e8dddfeb6d003b636b25bf6fc9",
  "ref": "main",
  "status": "created",
  "source": "trigger",
  "created_at": "2022-03-31T01:12:49.068Z",
  "updated_at": "2022-03-31T01:12:49.068Z",
  "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/257",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "id": 1,
    "username": "root",
    "name": "Administrator",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://127.0.0.1:3000/root"
  },
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "queued_duration": null,
  "coverage": null,
  "detailed_status": {
    "icon": "status_created",
    "text": "created",
    "label": "created",
    "group": "created",
    "tooltip": "created",
    "has_details": true,
    "details_path": "/test-group/test-project/-/pipelines/257",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_created-4b975aa976d24e5a3ea7cd9a5713e6ce2cd9afd08b910415e96675de35f64955.png"
  }
}
```
