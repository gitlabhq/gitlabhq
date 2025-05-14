---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

これらのAPIエンドポイントを使用して、[GitLabコンテナレジストリ](../user/packages/container_registry/_index.md)を操作します。

[`$CI_JOB_TOKEN`](../ci/jobs/ci_job_token.md)変数を`JOB-TOKEN`ヘッダーとして渡すことにより、CI/CDジョブからこれらのエンドポイントで認証できます。ジョブトークンは、パイプラインを作成したプロジェクトのコンテナレジストリへのアクセス権のみを持ちます。

## コンテナレジストリの表示レベルを変更する

次のコマンドは、誰がコンテナレジストリを表示できるかを制御します。

```plaintext
PUT /projects/:id/
```

| 属性                         | 型           | 必須 | 説明 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 整数/文字列 | はい      | 認証済みユーザーがアクセスできるプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `container_registry_access_level` | 文字列         | いいえ       | コンテナレジストリに必要な表示レベル。`enabled`（デフォルト）`private`または `disabled`。 |

`container_registry_access_level`で使用可能な値の説明:

- **enabled**（デフォルト）: コンテナレジストリは、プロジェクトへのアクセス権を持つすべてのユーザーに表示されます。プロジェクトが公開されている場合、コンテナレジストリも公開されます。プロジェクトが内部またはプライベートの場合、コンテナレジストリも内部またはプライベートになります。
- **private**: コンテナレジストリは、レポーターロール以上のロールを持つプロジェクトメンバーのみに表示されます。この動作は、コンテナレジストリの表示レベルが**enabled**に設定されたプライベートプロジェクトの動作に似ています。
- **disabled**: コンテナレジストリが無効になっています。

この設定がユーザーに付与する権限の詳細については、[コンテナレジストリの表示レベルの権限](../user/packages/container_registry/_index.md#container-registry-visibility-permissions)を参照してください。

```shell
curl --request PUT "https://gitlab.example.com/api/v4/projects/5/" \
     --header 'PRIVATE-TOKEN: <your_access_token>' \
     --header 'Accept: application/json' \
     --header 'Content-Type: application/json' \
     --data-raw '{
         "container_registry_access_level": "private"
     }'
```

応答の例:

```json
{
  "id": 5,
  "name": "Project 5",
  "container_registry_access_level": "private",
  ...
}
```

## コンテナレジストリのページネーション

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

## レジストリリポジトリをリストする

### プロジェクト内

プロジェクト内のレジストリリポジトリのリストを取得します。

```plaintext
GET /projects/:id/registry/repositories
```

| 属性    | 型           | 必須 | 説明 |
|--------------|----------------|----------|-------------|
| `id`         | 整数/文字列 | はい      | 認証済みユーザーがアクセスできるプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `tags`       | ブール値        | いいえ       | パラメーターがtrueとして含まれている場合、各リポジトリは、応答に`"tags"`の配列を含めます。 |
| `tags_count` | ブール値        | いいえ       | パラメーターがtrueとして含まれている場合、各リポジトリは、応答に`"tags_count"`を含めます。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories"
```

応答の例:

```json
[
  {
    "id": 1,
    "name": "",
    "path": "group/project",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project",
    "created_at": "2019-01-10T13:38:57.391Z",
    "cleanup_policy_started_at": "2020-01-10T15:40:57.391Z",
    "status": null
  },
  {
    "id": 2,
    "name": "releases",
    "path": "group/project/releases",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project/releases",
    "created_at": "2019-01-10T13:39:08.229Z",
    "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
    "status": "delete_ongoing"
  }
]
```

### グループ内

{{< history >}}

- GitLab 15.0で`tags`属性と `tag_count`属性が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/336912)されました。

{{< /history >}}

グループ内のレジストリリポジトリのリストを取得します。

```plaintext
GET /groups/:id/registry/repositories
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数/文字列 | はい      | 認証済みユーザーがアクセスできるグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/2/registry/repositories"
```

応答の例:

```json
[
  {
    "id": 1,
    "name": "",
    "path": "group/project",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project",
    "created_at": "2019-01-10T13:38:57.391Z",
    "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
  },
  {
    "id": 2,
    "name": "",
    "path": "group/other_project",
    "project_id": 11,
    "location": "gitlab.example.com:5000/group/other_project",
    "created_at": "2019-01-10T13:39:08.229Z",
    "cleanup_policy_started_at": "2020-01-10T15:40:57.391Z",
  }
]
```

## 単一のリポジトリの詳細を取得する

レジストリリポジトリの詳細を取得します。

```plaintext
GET /registry/repositories/:id
```

| 属性    | 型           | 必須 | 説明 |
|--------------|----------------|----------|-------------|
| `id`         | 整数/文字列 | はい      | 認証済みユーザーがアクセスできるレジストリリポジトリのID。 |
| `tags`       | ブール値        | いいえ       | パラメーターが`true`として含まれている場合、応答には`"tags"`の配列が含まれます。 |
| `tags_count` | ブール値        | いいえ       | パラメーターが`true`として含まれている場合、応答には`"tags_count"`が含まれます。 |
| `size`       | ブール値        | いいえ       | パラメーターが`true`として含まれている場合、応答には`"size"`が含まれます。これは、リポジトリ内のすべてのイメージの重複排除されたサイズです。重複排除は、同一データの余分なコピーを削除します。たとえば、同じイメージを2回アップロードした場合、コンテナレジストリには1つのコピーのみが保存されます。このフィールドは、GitLab.comで`2021-11-04`より後に作成されたリポジトリに対してのみ使用できます。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/registry/repositories/2?tags=true&tags_count=true&size=true"
```

応答の例:

```json
{
  "id": 2,
  "name": "",
  "path": "group/project",
  "project_id": 9,
  "location": "gitlab.example.com:5000/group/project",
  "created_at": "2019-01-10T13:38:57.391Z",
  "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
  "tags_count": 1,
  "tags": [
    {
      "name": "0.0.1",
      "path": "group/project:0.0.1",
      "location": "gitlab.example.com:5000/group/project:0.0.1"
    }
  ],
  "size": 2818413,
  "status": "delete_scheduled"
}
```

## レジストリリポジトリを削除する

レジストリのリポジトリを削除します。

この操作は非同期で実行されるため、実行されるまでに時間がかかる場合があります。

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id
```

| 属性       | 型           | 必須 | 説明 |
|-----------------|----------------|----------|-------------|
| `id`            | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_id` | 整数        | はい      | レジストリリポジトリのID。 |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2"
```

## レジストリリポジトリのタグをリストする

### プロジェクト内

{{< history >}}

- キーセットページネーションは、GitLab.comのみに対して、GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/432470)されました。

{{< /history >}}

指定されたレジストリリポジトリのタグのリストを取得します。

{{< alert type="note" >}}

オフセットページネーションは非推奨となり、キーセットページネーションが推奨されるページネーション方法になりました。

{{< /alert >}}

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags
```

| 属性       | 型           | 必須 | 説明 |
|-----------------|----------------|----------|-------------|
| `id`            | 整数/文字列 | はい      | 認証済みユーザーがアクセスできるプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_id` | 整数        | はい      | レジストリリポジトリのID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
```

応答の例:

```json
[
  {
    "name": "A",
    "path": "group/project:A",
    "location": "gitlab.example.com:5000/group/project:A"
  },
  {
    "name": "latest",
    "path": "group/project:latest",
    "location": "gitlab.example.com:5000/group/project:latest"
  }
]
```

## レジストリリポジトリのタグの詳細を取得する

レジストリリポジトリのタグの詳細を取得します。

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| 属性       | 型           | 必須 | 説明 |
|-----------------|----------------|----------|-------------|
| `id`            | 整数/文字列 | はい      | 認証済みユーザーがアクセスできるプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_id` | 整数        | はい      | レジストリリポジトリのID。 |
| `tag_name`      | 文字列         | はい      | タグの名前。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

応答の例:

```json
{
  "name": "v10.0.0",
  "path": "group/project:latest",
  "location": "gitlab.example.com:5000/group/project:latest",
  "revision": "e9ed9d87c881d8c2fd3a31b41904d01ba0b836e7fd15240d774d811a1c248181",
  "short_revision": "e9ed9d87c",
  "digest": "sha256:c3490dcf10ffb6530c1303522a1405dfaf7daecd8f38d3e6a1ba19ea1f8a1751",
  "created_at": "2019-01-06T16:49:51.272+00:00",
  "total_size": 350224384
}
```

## レジストリリポジトリのタグを削除する

コンテナレジストリリポジトリのタグを削除します。

タグがプロジェクトの保護ルールに一致する場合、エンドポイントは403エラーを返します。タグの保護ルールの詳細については、[保護されたコンテナタグ](../user/packages/container_registry/protected_container_tags.md)を参照してください。

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| 属性       | 型           | 必須 | 説明 |
|-----------------|----------------|----------|-------------|
| `id`            | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_id` | 整数        | はい      | レジストリリポジトリのID。 |
| `tag_name`      | 文字列         | はい      | タグの名前。 |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

この操作ではblobは削除されません。ディスク容量を回復させるには、[ガベージコレクションを実行](../administration/packages/container_registry.md#container-registry-garbage-collection)します。

## レジストリリポジトリのタグを一括削除する

指定された条件に基づいて、レジストリリポジトリのタグを一括で削除します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> 概要については、[コンテナレジストリAPIを使用して、\*以外のすべてのタグを削除する](https://youtu.be/Hi19bKe_xsg)を参照してください。

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags
```

| 属性           | 型           | 必須 | 説明 |
|---------------------|----------------|----------|-------------|
| `id`                | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_id`     | 整数        | はい      | レジストリリポジトリのID。 |
| `name_regex`        | 文字列         | いいえ       | 削除する名前の[re2](https://github.com/google/re2/wiki/Syntax)正規表現。すべてのタグを削除するには、`.*`を指定します。**注:** `name_regex`は非推奨となり、`name_regex_delete`が推奨されます。このフィールドは検証されます。 |
| `name_regex_delete` | 文字列         | はい      | 削除する名前の[re2](https://github.com/google/re2/wiki/Syntax)正規表現。すべてのタグを削除するには、`.*`を指定します。このフィールドは検証されます。 |
| `name_regex_keep`   | 文字列         | いいえ       | 保持する名前の[re2](https://github.com/google/re2/wiki/Syntax)正規表現。この値は、`name_regex_delete`からの一致を上書きします。このフィールドは検証されます。注: `.*`に設定すると、何も行われません。 |
| `keep_n`            | 整数        | いいえ       | 保持する指定された名前の最新タグの数量。 |
| `older_than`        | 文字列         | いいえ       | 指定された時間より古い削除するタグ。`1h`、`1d`、`1month`など、人間が読める形式で記述されています。 |

このAPIは成功した場合、[HTTP応答ステータスコード202](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/202)を返し、次の操作を実行します。

- すべてのタグを作成日で並べ替えます。作成日は、タグのプッシュ時ではなく、マニフェストの作成時です。
- 指定された`name_regex_delete`（または非推奨の`name_regex`）に一致するタグのみを削除し、`name_regex_keep`に一致するタグは保持します。
- `latest`という名前のタグは削除しません。
- N個の最新の一致するタグを保持します（`keep_n`が指定されている場合）。
- X時間より古いタグのみを削除します（`older_than`が指定されている場合）。
- [保護タグ](../user/packages/container_registry/protected_container_tags.md)を除外します。
- バックグラウンドで実行される非同期ジョブをスケジュールします。

これらの操作は非同期で実行されるため、実行されるまでに時間がかかる場合があります。操作は、特定のコンテナリポジトリに対して1時間に1回まで実行できます。

この操作ではblobは削除されません。ディスク容量を回復させるには、[ガベージコレクションを実行](../administration/packages/container_registry.md#container-registry-garbage-collection)します。

{{< alert type="warning" >}}

GitLab.comではコンテナレジストリの規模が大きいため、このAPIで削除されるタグの数は制限されています。コンテナレジストリに削除するタグが多数ある場合、一部のタグのみが削除されるため、このAPIを複数回呼び出す必要がある場合があります。自動削除されるようにタグをスケジュールするには、代わりに[クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#cleanup-policy)を使用します。

{{< /alert >}}

例:

- 正規表現（Git SHA）に一致するタグ名を削除し、少なくとも5つのタグを常に保持し、2日より古いものを削除します。

  ```shell
  curl --request DELETE --data 'name_regex_delete=[0-9a-z]{40}' --data 'keep_n=5' --data 'older_than=2d' \
       --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- すべてのタグを削除しますが、最新の5つのタグを常に保持します。

  ```shell
  curl --request DELETE --data 'name_regex_delete=.*' --data 'keep_n=5' \
       --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- すべてのタグを削除しますが、`stable`で始まるタグを常に保持します。

  ```shell
  curl --request DELETE --data 'name_regex_delete=.*' --data 'name_regex_keep=stable.*' \
       --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- 1か月より古いすべてのタグを削除します。

  ```shell
  curl --request DELETE --data 'name_regex_delete=.*' --data 'older_than=1month' \
       --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

### `+`を含む正規表現でcURLを使用する

cURLを使用する場合、GitLab Railsバックエンドで正しく処理されるように、正規表現の`+`文字は[URLエンコード](https://curl.se/docs/manpage.html#--data-urlencode)する必要があります。例:

```shell
curl --request DELETE --data-urlencode 'name_regex_delete=dev-.+' \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
```

## インスタンス全体のエンドポイント

上記で説明したグループおよびプロジェクト固有のGitLab APIに加えて、コンテナレジストリには独自のエンドポイントがあります。これらにクエリを実行するには、レジストリに組み込まれているメカニズムに従って、[認証トークン](https://distribution.github.io/distribution/spec/auth/token/)を取得して使用します。

{{< alert type="note" >}}

これらは、GitLabアプリケーションのプロジェクトアクセストークンまたはパーソナルアクセストークンとは異なります。

{{< /alert >}}

### GitLabからトークンを取得する

```plaintext
GET ${CI_SERVER_URL}/jwt/auth?service=container_registry&scope=*
```

有効なトークンを取得するには、正しい[スコープとアクション](https://distribution.github.io/distribution/spec/auth/scope/)を指定する必要があります。

```shell
$ SCOPE="repository:${CI_REGISTRY_IMAGE}:delete" #or push,pull

$ curl  --request GET --user "${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD}" \
        "https://gitlab.example.com/jwt/auth?service=container_registry&scope=${SCOPE}"
{"token":" ... "}
```

### 参照でイメージタグを削除する

{{< history >}}

- GitLab 16.4でエンドポイント`v2/<name>/manifests/<tag>`が[導入](https://gitlab.com/gitlab-org/container-registry/-/issues/1091)され、エンドポイント`v2/<name>/tags/reference/<tag>`は[非推奨](https://gitlab.com/gitlab-org/container-registry/-/issues/1094)になりました。

{{< /history >}}

```plaintext
DELETE http(s)://${CI_REGISTRY}/v2/${CI_REGISTRY_IMAGE}/tags/reference/${CI_COMMIT_SHORT_SHA}
```

事前定義された`CI_REGISTRY_USER`変数と`CI_REGISTRY_PASSWORD`変数で取得したトークンを使用して、GitLabインスタンスで参照によってコンテナイメージタグを削除できます。`tag_delete`[Container-Registry-Feature](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/docker/v2/api.md#delete-tag)を有効にする必要があります。

```shell
$ curl  --request DELETE --header "Authorization: Bearer <token_from_above>" \
        --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        "https://gitlab.example.com:5050/v2/${CI_REGISTRY_IMAGE}/manifests/${CI_COMMIT_SHORT_SHA}"
```

### すべてのコンテナリポジトリをリストする

```plaintext
GET http(s)://${CI_REGISTRY}/v2/_catalog
```

GitLabインスタンス上のすべてのコンテナリポジトリをリストするには、管理者の認証情報が必要です。

```shell
$ SCOPE="registry:catalog:*"

$ curl  --request GET --user "<admin-username>:<admin-password>" \
        "https://gitlab.example.com/jwt/auth?service=container_registry&scope=${SCOPE}"
{"token":" ... "}

$ curl --header "Authorization: Bearer <token_from_above>" https://gitlab.example.com:5050/v2/_catalog
```
