---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリAPI
description: GitLabコンテナレジストリをREST APIで管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

これらのAPIエンドポイントを使用して、[GitLabコンテナレジストリ](../user/packages/container_registry/_index.md)を操作します。

CI/CDジョブからこれらのエンドポイントで認証するには、[`$CI_JOB_TOKEN`](../ci/jobs/ci_job_token.md)変数を`JOB-TOKEN`ヘッダーとして渡します。ジョブトークンは、パイプラインを作成したプロジェクトのコンテナレジストリにのみアクセスできます。

## コンテナレジストリの表示レベルを変更する {#change-the-visibility-of-the-container-registry}

コンテナレジストリの閲覧権限を制御します。

```plaintext
PUT /projects/:id/
```

| 属性                         | 型              | 必須 | 説明 |
|-----------------------------------|-------------------|----------|-------------|
| `id`                              | 整数または文字列 | はい      | 認証済みユーザーがアクセスできるプロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `container_registry_access_level` | 文字列            | いいえ       | コンテナレジストリに必要な表示レベル。`enabled`（デフォルト）、`private`、または`disabled`のいずれか。 |

`container_registry_access_level`の可能な値の説明:

- `enabled`（デフォルト）: コンテナレジストリは、プロジェクトにアクセスできるすべてのユーザーに表示されます。プロジェクトが公開の場合、コンテナレジストリも公開になります。プロジェクトが内部または非公開の場合、コンテナレジストリも内部または非公開になります。
- `private`: コンテナレジストリは、レポーターロール以上のロールを持つプロジェクトメンバーのみに表示されます。この動作は、コンテナレジストリの表示レベルが有効に設定された非公開プロジェクトの動作に似ています。
- `disabled`: コンテナレジストリは無効になっています。

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

## コンテナレジストリのページネーション {#container-registry-pagination}

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

## レジストリリポジトリのリストを取得する {#list-registry-repositories}

### プロジェクト内 {#within-a-project}

プロジェクト内のレジストリリポジトリのリストを取得します。

```plaintext
GET /projects/:id/registry/repositories
```

| 属性    | 型           | 必須 | 説明 |
|--------------|----------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | 認証済みユーザーがアクセスできるプロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `tags`       | ブール値        | いいえ       | パラメータがtrueとして含まれている場合、各リポジトリの応答に`"tags"`の配列が含まれます。 |
| `tags_count` | ブール値        | いいえ       | パラメータがtrueとして含まれている場合、各リポジトリの応答に`"tags_count"`が含まれます。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories"
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

### グループ内 {#within-a-group}

{{< history >}}

- `tags`属性と`tag_count`属性は、GitLab 15.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/336912)されました。

{{< /history >}}

グループ内のレジストリリポジトリのリストを取得します。

```plaintext
GET /groups/:id/registry/repositories
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | 認証済みユーザーがアクセスできるグループのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/registry/repositories"
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

## 単一リポジトリの詳細を取得する {#get-details-of-a-single-repository}

レジストリリポジトリの詳細を取得します。

```plaintext
GET /registry/repositories/:id
```

| 属性    | 型           | 必須 | 説明 |
|--------------|----------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | 認証済みユーザーがアクセスできるレジストリリポジトリのID。 |
| `tags`       | ブール値        | いいえ       | パラメータが`true`として含まれている場合、応答に`"tags"`の配列が含まれます。 |
| `tags_count` | ブール値        | いいえ       | パラメータが`true`として含まれている場合、応答に`"tags_count"`が含まれます。 |
| `size`       | ブール値        | いいえ       | パラメータが`true`として含まれている場合、応答に`"size"`が含まれます。これは、リポジトリ内のすべてのイメージの重複排除後のサイズです。重複排除により、同一データの余分なコピーが除去されます。たとえば、イメージを2回アップロードした場合、コンテナレジストリには1つのコピーのみが保存されます。このフィールドは、GitLab.comで`2021-11-04`より後に作成されたリポジトリに対してのみ使用できます。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/registry/repositories/2?tags=true&tags_count=true&size=true"
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

## レジストリリポジトリを削除する {#delete-registry-repository}

レジストリ内のリポジトリを削除します。

この操作は非同期で実行されるため、実行されるまでに時間がかかる場合があります。

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id
```

| 属性       | 型           | 必須 | 説明 |
|-----------------|----------------|----------|-------------|
| `id`            | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_id` | 整数        | はい      | レジストリリポジトリのID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2"
```

## レジストリリポジトリのタグのリストを取得する {#list-registry-repository-tags}

### プロジェクト内 {#within-a-project-1}

{{< history >}}

- キーセットページネーションは、GitLab.comのみに対して、GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/432470)されました。

{{< /history >}}

指定されたレジストリリポジトリのタグのリストを取得します。

{{< alert type="note" >}}

オフセットページネーションは非推奨となり、キーセットページネーションが推奨のページネーション方法になりました。

{{< /alert >}}

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags
```

| 属性       | 型           | 必須 | 説明 |
|-----------------|----------------|----------|-------------|
| `id`            | 整数または文字列 | はい      | 認証済みユーザーがアクセスできるプロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_id` | 整数        | はい      | レジストリリポジトリのID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
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

## レジストリリポジトリのタグの詳細を取得する {#get-details-of-a-registry-repository-tag}

レジストリリポジトリのタグの詳細を取得します。

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| 属性       | 型           | 必須 | 説明 |
|-----------------|----------------|----------|-------------|
| `id`            | 整数または文字列 | はい      | 認証済みユーザーがアクセスできるプロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_id` | 整数        | はい      | レジストリリポジトリのID。 |
| `tag_name`      | 文字列         | はい      | タグの名前。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
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

## レジストリリポジトリのタグを削除する {#delete-a-registry-repository-tag}

コンテナレジストリリポジトリのタグを削除します。

タグがプロジェクトの保護ルールに一致する場合、エンドポイントは[`403 Forbidden`](rest/troubleshooting.md#status-codes)エラーを返します。タグ保護ルールの詳細については、[保護されたコンテナタグ](../user/packages/container_registry/protected_container_tags.md)を参照してください。

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| 属性       | 型           | 必須 | 説明 |
|-----------------|----------------|----------|-------------|
| `id`            | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_id` | 整数        | はい      | レジストリリポジトリのID。 |
| `tag_name`      | 文字列         | はい      | タグの名前。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

この操作ではblobは削除されません。ディスク容量を回復させるには、[ガベージコレクションを実行](../administration/packages/container_registry.md#container-registry-garbage-collection)します。

## レジストリリポジトリのタグを一括削除する {#delete-registry-repository-tags-in-bulk}

指定された条件に基づいて、レジストリリポジトリのタグを一括削除します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[コンテナレジストリAPIを使用して、\*以外のすべてのタグを削除する](https://youtu.be/Hi19bKe_xsg)を参照してください。

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags
```

| 属性           | 型           | 必須 | 説明 |
|---------------------|----------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `repository_id`     | 整数        | はい      | レジストリリポジトリのID。 |
| `keep_n`            | 整数        | いいえ       | 保持する指定された名前の最新のタグの数。 |
| `name_regex`        | 文字列         | いいえ       | 削除する名前の[re2](https://github.com/google/re2/wiki/Syntax)正規表現。すべてのタグを削除するには、`.*`を指定します。**注**: `name_regex`は非推奨となり、`name_regex_delete`が推奨されます。このフィールドは検証されます。 |
| `name_regex_delete` | 文字列         | はい      | 削除する名前の[re2](https://github.com/google/re2/wiki/Syntax)正規表現。すべてのタグを削除するには、`.*`を指定します。このフィールドは検証されます。 |
| `name_regex_keep`   | 文字列         | いいえ       | 保持する名前の[re2](https://github.com/google/re2/wiki/Syntax)正規表現。この値は、`name_regex_delete`からの一致を上書きします。このフィールドは検証されます。注: `.*`に設定すると、何も実行されません。 |
| `older_than`        | 文字列         | いいえ       | 指定された時刻より前の削除対象のタグ。`1h`、`1d`、`1month`など、人間が読める形式で記述されています。 |

このAPIは成功した場合、[HTTP応答ステータスコード202](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/202)を返し、次の操作を実行します。

- すべてのタグを作成日順に並べ替えます。作成日は、タグのプッシュ時刻ではなく、manifestの作成時刻です。
- 指定された`name_regex_delete`（または非推奨の`name_regex`）に一致するタグのみを削除し、`name_regex_keep`に一致するものは保持します。
- `latest`という名前のタグは削除しません。
- N個の最新の一致するタグを保持します（`keep_n`が指定されている場合）。
- X時間以上前のタグのみを削除します（`older_than`が指定されている場合）。
- [保護タグ](../user/packages/container_registry/protected_container_tags.md)は除外します。
- バックグラウンドで実行される非同期のジョブをスケジュールします。

これらの操作は非同期で実行されるため、実行されるまでに時間がかかる場合があります。操作は、指定されたコンテナリポジトリに対して1時間に1回まで実行できます。

この操作ではblobは削除されません。ディスク容量を回復させるには、[ガベージコレクションを実行](../administration/packages/container_registry.md#container-registry-garbage-collection)します。

{{< alert type="warning" >}}

GitLab.comではコンテナレジストリの規模により、このAPIで削除されるタグ数が制限されています。コンテナレジストリに削除すべきタグが多数ある場合、一部のみが削除され、このAPIを複数回呼び出す必要がある場合があります。タグの自動削除をスケジュールするには、代わりに[クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#cleanup-policy)を使用します。

{{< /alert >}}

例:

- 正規表現（Git SHA）に一致するタグ名を削除し、常に少なくとも5個を保持し、2日以上経過したものを削除します。

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=[0-9a-z]{40}' \
    --data 'keep_n=5' \
    --data 'older_than=2d' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- すべてのタグを削除しますが、常に最新の5個を保持します。

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=.*' \
    --data 'keep_n=5' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- すべてのタグを削除しますが、`stable`で始まるタグを常に保持します。

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=.*' \
    --data 'name_regex_keep=stable.*' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- 1か月以上経過したすべてのタグを削除します。

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=.*' \
    --data 'older_than=1month' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

### `+`を含む正規表現でcURLを使用する {#use-curl-with-a-regular-expression-that-contains-}

cURLを使用する場合、GitLab Railsバックエンドで正しく処理されるように、正規表現の`+`文字は[URLエンコード](https://curl.se/docs/manpage.html#--data-urlencode)する必要があります。例は次のとおりです。

```shell
curl --request DELETE \
  --data-urlencode 'name_regex_delete=dev-.+' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
```

## インスタンス全体のエンドポイント {#instance-wide-endpoints}

前述のグループおよびプロジェクト固有のGitLab APIに加えて、コンテナレジストリには独自のエンドポイントがあります。これらに対してクエリするには、レジストリの組み込みメカニズムに従って、[認証トークン](https://distribution.github.io/distribution/spec/auth/token/)を取得して使用します。

{{< alert type="note" >}}

これらは、GitLabアプリケーションのプロジェクトアクセストークンまたはパーソナルアクセストークンとは異なります。

{{< /alert >}}

### GitLabからトークンを取得する {#obtain-token-from-gitlab}

```plaintext
GET ${CI_SERVER_URL}/jwt/auth?service=container_registry&scope=*
```

有効なトークンを取得するには、正しい[スコープとアクション](https://distribution.github.io/distribution/spec/auth/scope/)を指定する必要があります。

```shell
$ SCOPE="repository:${CI_REGISTRY_IMAGE}:delete" #or push,pull

$ curl --request GET \
    --user "${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD}" \
    --url "https://gitlab.example.com/jwt/auth?service=container_registry&scope=${SCOPE}"
{"token":" ... "}
```

### 参照でイメージタグを削除する {#delete-image-tags-by-reference}

{{< history >}}

- GitLab 16.4でエンドポイント`v2/<name>/manifests/<tag>`が[導入](https://gitlab.com/gitlab-org/container-registry/-/issues/1091)され、エンドポイント`v2/<name>/tags/reference/<tag>`が[非推奨](https://gitlab.com/gitlab-org/container-registry/-/issues/1094)になりました。

{{< /history >}}

```plaintext
DELETE http(s)://${CI_REGISTRY}/v2/${CI_REGISTRY_IMAGE}/tags/reference/${CI_COMMIT_SHORT_SHA}
```

事前定義された`CI_REGISTRY_USER`変数と`CI_REGISTRY_PASSWORD`変数で取得したトークンを使用すると、GitLabインスタンスの参照によるコンテナイメージタグを削除できます。`tag_delete`[コンテナレジストリ機能](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/docker/v2/api.md#delete-tag)を有効にする必要があります。

```shell
$ curl --request DELETE \
    --header "Authorization: Bearer <token_from_above>" \
    --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    --url "https://gitlab.example.com:5050/v2/${CI_REGISTRY_IMAGE}/manifests/${CI_COMMIT_SHORT_SHA}"
```

### すべてのコンテナリポジトリのリストを取得する {#listing-all-container-repositories}

```plaintext
GET http(s)://${CI_REGISTRY}/v2/_catalog
```

GitLabインスタンス上のすべてのコンテナリポジトリのリストを取得するには、管理者の認証情報が必要です。

```shell
$ SCOPE="registry:catalog:*"

$ curl --request GET \
    --user "<admin-username>:<admin-password>" \
    --url "https://gitlab.example.com/jwt/auth?service=container_registry&scope=${SCOPE}"
{"token":" ... "}

$ curl --header "Authorization: Bearer <token_from_above>" \
    --url "https://gitlab.example.com:5050/v2/_catalog"
```
