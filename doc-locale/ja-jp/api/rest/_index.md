---
stage: Developer Experience
group: API
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "GitLab REST APIを使用して、プログラムによりGitLabを操作します。リクエスト、レート制限、ページネーション、エンコード、バージョニング、および応答処理が含まれます。"
title: REST API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab REST APIを使用してワークフローを自動化し、インテグレーションを構築します。

- 手動操作なしで、GitLabリソースを大規模に管理するカスタムツールを作成します。
- GitLabデータをアプリケーションに直接統合することで、コラボレーションを向上させます。
- 複数のプロジェクトにわたって、CI/CDプロセスを正確に管理します。
- プログラムでユーザーアクセスを制御して、組織全体で一貫した権限を維持します。

REST APIでは、既存のツールやシステムとの互換性のために、標準のHTTPメソッドとJSONデータ形式が使用されます。

## REST APIリクエストを実行する {#make-a-rest-api-request}

REST APIリクエストを実行するには、次のようにします。

- REST APIクライアントを使用して、APIエンドポイントにリクエストを送信します。
- GitLabインスタンスがリクエストに応答します。ステータスコードと、該当する場合はリクエストされたデータが返されます。ステータスコードはリクエストの結果を示し、[トラブルシューティング](troubleshooting.md)の際に役立ちます。

REST APIリクエストは、ルートエンドポイントとパスで始まる必要があります。

- ルートエンドポイントはGitLabホスト名です。
- パスは`/api/v4`で始まる必要があります（`v4`はAPIバージョンを表します）。

次の例では、APIリクエストでGitLabホスト（`gitlab.example.com`）上のすべてのプロジェクトのリストを取得します。

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects"
```

一部のエンドポイントへのアクセスには認証が必要です。詳細については、[認証](authentication.md)を参照してください。

## レート制限 {#rate-limits}

REST APIリクエストはレート制限設定の対象となります。この設定はGitLabインスタンスのオーバーロードのリスクを軽減するためのものです。

- 詳細については、[レート制限](../../security/rate_limits.md)を参照してください。
- GitLab.comで使用されるレート制限設定の詳細については、[GitLab.com固有のレート制限](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)を参照してください。

## 応答形式 {#response-format}

REST APIの応答はJSON形式で返されます。一部のAPIエンドポイントは、プレーンテキスト形式もサポートしています。エンドポイントでサポートされるコンテンツタイプを確認するには、[REST APIリソース](../api_resources.md)を参照してください。

## リクエスト要件 {#request-requirements}

一部のREST APIリクエストには、使用するデータ形式やエンコードなど、特定の要件があります。

### リクエストペイロード {#request-payload}

APIリクエストでは、[クエリ文字列](https://en.wikipedia.org/wiki/Query_string)または[ペイロード本文](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-p3-payload-14#section-3.2)として送信されるパラメータを使用できます。通常、GETリクエストはクエリ文字列を送信し、PUTリクエストまたはPOSTリクエストはペイロード本文を送信します。

- クエリ文字列:

  ```shell
  curl --request POST \
    --url "https://gitlab.example.com/api/v4/projects?name=<example-name>&description=<example-description>"
  ```

- リクエストペイロード（JSON）:

  ```shell
  curl --request POST \
    --header "Content-Type: application/json" \
    --data '{"name":"<example-name>", "description":"<example-description>"}' "https://gitlab.example.com/api/v4/projects"
  ```

URLエンコードされたクエリ文字列の長さには制限があります。リクエストが大きすぎると、`414 Request-URI Too Large`（リクエストURIが長すぎます）というエラーメッセージが生成されます。これは、代わりにペイロード本文を使用することで解決できます。

### パスパラメータ {#path-parameters}

エンドポイントにパスパラメータがある場合、ドキュメントでは先頭にコロンを付けて表示します。

例は次のとおりです。

```plaintext
DELETE /projects/:id/share/:group_id
```

`:id`パスパラメータはプロジェクトIDに、`:group_id`はグループのIDに置き換える必要があります。コロン（`:`）は含めないでください。

ID `5`のプロジェクトとID `17`のグループに対して送信するcURLリクエストは次のようになります。

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/share/17"
```

パスパラメータでURLエンコードが必要なら、その形式に従う必要があります。そうでない場合、APIエンドポイントと一致せず、404エラーが返されます。APIの前に何か（Apacheなど）がある場合、それがURLエンコードされたパスパラメータをデコードしないことを確認してください。

### `id`と`iid`の違い {#id-vs-iid}

一部のAPIリソースには、類似する名前のフィールドが2つあります。たとえば、[イシュー](../issues.md) 、[マージリクエスト](../merge_requests.md) 、[プロジェクトのマイルストーン](../merge_requests.md)などです。これらのフィールドを以下に示します。

- `id`: すべてのプロジェクトで一意のID。
- `iid`: 追加の内部ID（Web UIに表示）。単一プロジェクトのスコープ内で一意。

リソースに`iid`フィールドと`id`フィールドの両方がある場合、通常はリソースをフェッチするために`id`フィールドではなく`iid`フィールドが使用されます。

たとえば、`id: 42`のプロジェクトに`id: 46`と`iid: 5`のイシューがあるとします。この場合、次のようになります。

- イシューを取得するための有効なAPIリクエストは`GET /projects/42/issues/5`です。
- イシューを取得するための無効なAPIリクエストは`GET /projects/42/issues/46`です。

`iid`フィールドを持つすべてのリソースが`iid`によってフェッチされるわけではありません。どのフィールドを使用すべきかについては、特定のリソースのドキュメントを参照してください。

### エンコード {#encoding}

REST APIリクエストを実行する場合、特殊文字とデータ構造を考慮して一部のコンテンツをエンコードする必要があります。

#### ネームスペース付きのパス {#namespaced-paths}

ネームスペース付きのAPIリクエストを使用する場合は、`NAMESPACE/PROJECT_PATH`がURLエンコードされていることを確認してください。

たとえば、`/`は`%2F`で表されます。

```plaintext
GET /api/v4/projects/diaspora%2Fdiaspora
```

プロジェクトのパスは、必ずしもその名前と同じではありません。プロジェクトのパスは、プロジェクトのURLまたはプロジェクトの設定の**一般 > 高度な設定 > パスを変更**にあります。

#### ファイルパス、ブランチ、タグ名 {#file-path-branches-and-tags-name}

ファイルパス、ブランチ、またはタグに`/`が含まれている場合は、URLエンコードされていることを確認してください。

たとえば、`/`は`%2F`で表されます。

```plaintext
GET /api/v4/projects/1/repository/files/src%2FREADME.md?ref=master
GET /api/v4/projects/1/branches/my%2Fbranch/commits
GET /api/v4/projects/1/repository/tags/my%2Ftag
```

#### array（配列）型とhash（ハッシュ）型 {#array-and-hash-types}

`array`型と`hash`型のパラメータを使用してAPIをリクエストできます。

##### `array` {#array}

`import_sources`は`array`型のパラメータです。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  -d "import_sources[]=github" \
  -d "import_sources[]=bitbucket" \
  --url "https://gitlab.example.com/api/v4/some_endpoint"
```

##### `hash` {#hash}

`override_params`は`hash`型のパラメータです。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "namespace=email" \
  --form "path=impapi" \
  --form "file=@/path/to/somefile.txt" \
  --form "override_params[visibility]=private" \
  --form "override_params[some_other_param]=some_value" \
  --url "https://gitlab.example.com/api/v4/projects/import"
```

##### ハッシュの配列 {#array-of-hashes}

`variables`は、ハッシュのキー/値ペア`[{ 'key': 'UPLOAD_TO_S3', 'value': 'true' }]`を含む`array`型のパラメータです。

```shell
curl --globoff --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/169/pipeline?ref=master&variables[0][key]=VAR1&variables[0][value]=hello&variables[1][key]=VAR2&variables[1][value]=world"

curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{ "ref": "master", "variables": [ {"key": "VAR1", "value": "hello"}, {"key": "VAR2", "value": "world"} ] }' \
  --url "https://gitlab.example.com/api/v4/projects/169/pipeline"
```

#### ISO 8601形式の日付での`+`のエンコード {#encoding--in-iso-8601-dates}

[W3の推奨事項](https://www.w3.org/Addressing/URL/4_URI_Recommentations.html)によって`+`がスペースとして解釈されることから、クエリパラメータに`+`を含める必要がある場合は、代わりに`%2B`を使用する必要があります。たとえば、ISO 8601形式の日付で特定の時刻を含める場合、次のようになります。

```plaintext
2017-10-17T23:11:13.000+05:30
```

クエリパラメータの正しいエンコードは次のようになります。

```plaintext
2017-10-17T23:11:13.000%2B05:30
```

## 応答の評価 {#evaluating-a-response}

状況によっては、API応答が予想どおりにならない場合があります。可能性のある問題としては、null値やリダイレクトなどがあります。応答で数値のステータスコードを受け取った場合は、[ステータスコード](troubleshooting.md#status-codes)を参照してください。

### `null`と`false`の違い {#null-vs-false}

API応答では、一部のブール値フィールドに`null`値が含まれる場合があります。`null`ブール値はデフォルト値がなく、`true`でも`false`でもありません。GitLabは、ブール値フィールドの`null`値を`false`と同様に扱います。

ブール値引数に設定する値は、`true`か`false`の値だけです（`null`ではありません）。

### リダイレクト {#redirects}

{{< history >}}

- GitLab 16.4で`api_redirect_moved_projects`[フラグ](../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは無効になっています。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137578)になりました。機能フラグ`api_redirect_moved_projects`は削除されました。

{{< /history >}}

[パスの変更](../../user/project/repository/_index.md#repository-path-changes)後、REST APIはエンドポイントが移動したことを示すメッセージで応答することがあります。この場合、`Location`ヘッダーに指定されたエンドポイントを使用してください。

別のパスに移動したプロジェクトの例:

```shell
curl --request GET \
  --verbose \
  --url "https://gitlab.example.com/api/v4/projects/gitlab-org%2Fold-path-project"
```

応答は次のようになります。

```plaintext
...
< Location: http://gitlab.example.com/api/v4/projects/81
...
This resource has been moved permanently to https://gitlab.example.com/api/v4/projects/81
```

## ページネーション {#pagination}

GitLabは、次のページネーション方法をサポートしています。

- オフセットベースのページネーション。デフォルトの方法であり、GitLab 16.5以降で、`users`エンドポイントを除くすべてのエンドポイントで使用できます。
- キーセットベースのページネーション。一部のエンドポイントに追加され、[段階的にロールアウト](https://gitlab.com/groups/gitlab-org/-/epics/2039)されています。

大規模なコレクションの場合、パフォーマンス上の理由から、オフセットページネーションではなくキーセットページネーション（利用可能な場合）を使用してください。

### オフセットベースのページネーション {#offset-based-pagination}

{{< history >}}

- `users`エンドポイントは、GitLab 16.5でオフセットベースのページネーションでは[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/426547)になりました。17.0で削除される予定です。これは破壊的な変更です。代わりに、このエンドポイントにはキーセットベースのページネーションを使用してください。
- GitLab 17.0では、リクエストされたレコード数が50,000を超える場合、`users`エンドポイントでキーセットベースのページネーションが強制的に適用されます。

{{< /history >}}

場合によっては、返される結果が複数のページにわたることがあります。リソースを一覧表示するときに、次のパラメータを渡すことができます。

| パラメータ  | 説明                                                   |
|:-----------|:--------------------------------------------------------------|
| `page`     | ページ番号（デフォルトは`1`）。                                   |
| `per_page` | ページごとに表示するアイテム数（デフォルトは`20`、最大値は`100`）。 |

次の例では、ページごとに50個の[ネームスペース](../namespaces.md)を一覧表示しています。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces?per_page=50"
```

{{< alert type="note" >}}

オフセットページネーションには、[最大許容オフセット制限](../../administration/instance_limits.md#max-offset-allowed-by-the-rest-api-for-offset-based-pagination)があります。GitLab Self-Managedインスタンスでこの制限を変更できます。

{{< /alert >}}

#### ページネーション`Link`ヘッダー {#pagination-link-header}

[`Link`ヘッダー](https://www.w3.org/wiki/LinkHeader)は、各応答とともに返されます。このヘッダーでは、`rel`が`prev`、`next`、`first`、`last`のいずれかに設定されており、関連するURLが含まれています。独自のURLを生成するのではなく、必ずこれらのリンクを使用してください。

GitLab.comユーザーの場合、[一部のページネーションヘッダーが返されないことがあります](../../user/gitlab_com/_index.md#pagination-response-headers)。

次のcURLの例では、出力をページあたり3アイテム（`per_page=3`）に制限し、プロジェクトID `9`に属するID `8`のイシューの[コメント](../notes.md)の2ページ目（`page=2`）をリクエストしています。

```shell
curl --request GET \
  --head \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/9/issues/8/notes?per_page=3&page=2"
```

応答は次のようになります。

```http
HTTP/2 200 OK
cache-control: no-cache
content-length: 1103
content-type: application/json
date: Mon, 18 Jan 2016 09:43:18 GMT
link: <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=1&per_page=3>; rel="prev", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=3&per_page=3>; rel="next", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=1&per_page=3>; rel="first", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=3&per_page=3>; rel="last"
status: 200 OK
vary: Origin
x-next-page: 3
x-page: 2
x-per-page: 3
x-prev-page: 1
x-request-id: 732ad4ee-9870-4866-a199-a9db0cde3c86
x-runtime: 0.108688
x-total: 8
x-total-pages: 3
```

#### その他のページネーションヘッダー {#other-pagination-headers}

GitLabは、次のページネーションヘッダーも返します。

| ヘッダー          | 説明 |
|:----------------|:------------|
| `x-next-page`   | 次のページのインデックス。 |
| `x-page`        | 現在のページのインデックス（1から開始）。 |
| `x-per-page`    | ページあたりのアイテム数。 |
| `x-prev-page`   | 前のページのインデックス。 |
| `x-total`       | アイテムの合計数。 |
| `x-total-pages` | ページの合計数。 |

GitLab.comユーザーの場合、[一部のページネーションヘッダーが返されないことがあります](../../user/gitlab_com/_index.md#pagination-response-headers)。

### キーセットベースのページネーション {#keyset-based-pagination}

キーセットページネーションを使用すると、ページをより効率的に取得できるようになります。オフセットベースのページネーションとは対照的に、ランタイムはコレクションのサイズに依存しません。

この方法は次のパラメータで制御されます。`order_by`と`sort`はどちらも必須です。

| パラメータ    | 必須 | 説明 |
|--------------|----------|-------------|
| `pagination` | はい      | `keyset`（キーセットページネーションを有効にする）。 |
| `per_page`   | いいえ       | ページごとに表示するアイテム数（デフォルトは`20`、最大値は`100`）。 |
| `order_by`   | はい      | 並べ替えの基準となる列。 |
| `sort`       | はい      | 並び替え順（`asc`または`desc`） |

次の例では、[プロジェクト](../projects.md)をページあたり50個、`id`の昇順で一覧表示します。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc"
```

応答ヘッダーには、次のページへのリンクが含まれています。例は次のとおりです。

```http
HTTP/1.1 200 OK
...
Link: <https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc&id_after=42>; rel="next"
Status: 200 OK
...
```

次のページへのリンクには、すでに取得したレコードを除外する追加のフィルター`id_after=42`が含まれています。

別の例として、次のリクエストは、キーセットページネーションを使用して、[グループ](../groups.md)をページあたり50個、`name`の昇順で一覧表示します。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups?pagination=keyset&per_page=50&order_by=name&sort=asc"
```

応答ヘッダーには、次のページへのリンクが含まれています。

```http
HTTP/1.1 200 OK
...
Link: <https://gitlab.example.com/api/v4/groups?pagination=keyset&per_page=50&order_by=name&sort=asc&cursor=eyJuYW1lIjoiRmxpZ2h0anMiLCJpZCI6IjI2IiwiX2tkIjoibiJ9>; rel="next"
Status: 200 OK
...
```

次のページへのリンクには、すでに取得したレコードを除外する追加のフィルター`cursor=eyJuYW1lIjoiRmxpZ2h0anMiLCJpZCI6IjI2IiwiX2tkIjoibiJ9`が含まれています。

フィルターの種類は、使用される`order_by`オプションによって異なります。また、複数の追加フィルターを設定できます。

{{< alert type="warning" >}}

`Links`ヘッダーは、[W3Cの`Link`仕様](https://www.w3.org/wiki/LinkHeader)に対応するために削除されました。代わりに`Link`ヘッダーを使用する必要があります。

{{< /alert >}}

コレクションの末尾に達し、取得する追加のレコードがない場合には、`Link`ヘッダーは存在せず、結果の配列は空になります。

独自のURLを作成するのではなく、指定されたリンクのみを使用して次のページを取得する必要があります。表示されているヘッダー以外に、追加のページネーションヘッダーは公開されていません。

#### サポートされているリソース {#supported-resources}

キーセットベースのページネーションは、一部のリソースと並べ替えオプションでのみサポートされています。

| リソース                                                                       | オプション                                                                                                                                                                               | 利用可能 |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| [グループ監査イベント](../audit_events.md#retrieve-all-group-audit-events)       | `order_by=id`、`sort=desc`のみ                                                                                                                                                       | 認証済みユーザーのみ。 |
| [グループ](../groups.md#list-groups)                                             | `order_by=name`、`sort=asc`のみ                                                                                                                                                      | 未認証ユーザーのみ。 |
| [インスタンス監査イベント](../audit_events.md#retrieve-all-instance-audit-events) | `order_by=id`、`sort=desc`のみ                                                                                                                                                       | 認証済みユーザーのみ。 |
| [パッケージパイプライン](../packages.md#list-package-pipelines)                     | `order_by=id`、`sort=desc`のみ                                                                                                                                                       | 認証済みユーザーのみ。 |
| [プロジェクトジョブ](../jobs.md#list-project-jobs)                                   | `order_by=id`、`sort=desc`のみ                                                                                                                                                       | 認証済みユーザーのみ。 |
| [プロジェクト監査イベント](../audit_events.md#retrieve-all-project-audit-events)   | `order_by=id`、`sort=desc`のみ                                                                                                                                                       | 認証済みユーザーのみ。 |
| [プロジェクト](../projects.md)                                                     | `order_by=id`のみ                                                                                                                                                                    | 認証済みユーザーおよび未認証ユーザー。 |
| [ユーザー](../users.md)                                                           | `order_by=id`、`order_by=name`、`order_by=username`、`order_by=created_at`、または`order_by=updated_at`。                                                                                 | 認証済みユーザーおよび未認証ユーザー。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419556)されました。 |
| [レジストリリポジトリタグ](../container_registry.md)                           | `order_by=name`、`sort=asc`、または`sort=desc`のみ。                                                                                                                                     | 認証済みユーザーのみ。 |
| [リポジトリツリーをリストする](../repositories.md#list-repository-tree)                | N/A                                                                                                                                                                                   | 認証済みユーザーおよび未認証ユーザー。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154897)されました。 |
| [プロジェクトイシュー](../issues.md#list-project-issues)                             | `order_by=created_at`、`order_by=updated_at`、`order_by=title`、`order_by=id`、`order_by=weight`、`order_by=due_date`、`order_by=relative_position`、`sort=asc`、または`sort=desc`のみ。 | 認証済みユーザーおよび未認証ユーザー。GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199887/)されました。 |

### ページネーション応答ヘッダー {#pagination-response-headers}

パフォーマンス上の理由から、クエリが返すレコードの数が10,000件を超える場合、GitLabは次のヘッダーを返しません。

- `x-total`。
- `x-total-pages`。
- `rel="last"` `link`

## バージョニングと非推奨 {#versioning-and-deprecations}

REST APIのバージョンは、セマンティックバージョニング仕様に準拠しています。メジャーバージョン番号は`4`です。下位互換性のない変更の場合、このバージョン番号を変更する必要があります。

- マイナーバージョンは明示的にされておらず、安定したAPIエンドポイントを提供します。
- 新機能は同じバージョン番号のAPIに追加されます。
- メジャーAPIバージョンの変更とAPIバージョン全体の削除は、GitLabのメジャーリリースと連動して行われます。
- バージョン間のすべての非推奨と変更は、ドキュメントに記載されています。

以下は非推奨プロセスの対象外であり、予告なしにいつでも削除される可能性があります。

- [REST APIリソース](../api_resources.md)で[実験的またはベータ](../../policy/development_stages_support.md)としてラベル付けされた要素。
- 機能フラグで制御されており、デフォルトで無効になっているフィールド。

GitLab Self-Managedの場合、EEインスタンスからCEインスタンスに[ダウングレード](../../downgrade_ee_to_ce/_index.md)すると、破壊的な変更が発生します。
