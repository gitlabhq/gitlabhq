---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトリリースAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIは、プロジェクトの[リリース](../../user/project/releases/_index.md)を処理するために使用します。

{{< alert type="note" >}}

グループのリリースを処理する場合は、[グループリリースAPI](../group_releases.md)を参照してください。

リンクをリリースアセットとして操作するには、[リリースリンクAPI](links.md)を参照してください。

{{< /alert >}}

## 認証 {#authentication}

認証の場合、リリースAPIは次のいずれかを受け入れます。

- `PRIVATE-TOKEN`ヘッダーを使用した[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)
- `JOB-TOKEN`ヘッダーを使用した[GitLab CI/CDジョブトークン](../../ci/jobs/ci_job_token.md)`$CI_JOB_TOKEN`

## リリースをリストする {#list-releases}

リリースのページネーションされたリストを返します。`released_at`でソートされています。

```plaintext
GET /projects/:id/releases
```

| 属性     | 型           | 必須 | 説明                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `order_by`    | 文字列         | いいえ       | 順序として使用するフィールド。`released_at`（デフォルト）または`created_at`。 |
| `sort`        | 文字列         | いいえ       | 並び替えの方向。降順の場合は`desc`（デフォルト）、昇順の場合は`asc`。 |
| `include_html_description` | ブール値        | いいえ       | `true`の場合、応答には、リリースの説明のMarkdownのHTMLレンダリングが含まれます。   |

成功した場合、[`200 OK`](../rest/troubleshooting.md#status-codes)と次の応答属性を返します。

| 属性                             | 型   | 説明                                      |
|:--------------------------------------|:-------|:-------------------------------------------------|
| `[]._links`                           | オブジェクト | リリースのリンク                            |
| `[]._links.closed_issues_url`         | 文字列 | リリースの完了イシューのHTTP URL         |
| `[]._links.closed_merge_requests_url` | 文字列 | リリースの完了マージリクエストのHTTP URL |
| `[]._links.edit_url`                  | 文字列 | リリースの編集ページのHTTP URL             |
| `[]._links.merged_merge_requests_url` | 文字列 | リリースのマージ済みのマージリクエストのHTTP URL |
| `[]._links.opened_issues_url`         | 文字列 | リリースの未完了イシューのHTTP URL           |
| `[]._links.opened_merge_requests_url` | 文字列 | リリースの未完了マージリクエストのHTTP URL   |
| `[]._links.self`                      | 文字列 | リリースのHTTP URL                         |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases"
```

応答の例:

```json
[
   {
      "tag_name":"v0.2",
      "description":"## CHANGELOG\r\n\r\n- Escape label and milestone titles to prevent XSS in GLFM autocomplete. !2740\r\n- Prevent private snippets from being embeddable.\r\n- Add subresources removal to member destroy service.",
      "name":"Awesome app v0.2 beta",
      "created_at":"2019-01-03T01:56:19.539Z",
      "released_at":"2019-01-03T01:56:19.539Z",
      "author":{
         "id":1,
         "name":"Administrator",
         "username":"root",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
         "web_url":"https://gitlab.example.com/root"
      },
      "commit":{
         "id":"079e90101242458910cccd35eab0e211dfc359c0",
         "short_id":"079e9010",
         "title":"Update README.md",
         "created_at":"2019-01-03T01:55:38.000Z",
         "parent_ids":[
            "f8d3d94cbd347e924aa7b715845e439d00e80ca4"
         ],
         "message":"Update README.md",
         "author_name":"Administrator",
         "author_email":"admin@example.com",
         "authored_date":"2019-01-03T01:55:38.000Z",
         "committer_name":"Administrator",
         "committer_email":"admin@example.com",
         "committed_date":"2019-01-03T01:55:38.000Z"
      },
      "milestones": [
         {
            "id":51,
            "iid":1,
            "project_id":24,
            "title":"v1.0-rc",
            "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
            "state":"closed",
            "created_at":"2019-07-12T19:45:44.256Z",
            "updated_at":"2019-07-12T19:45:44.256Z",
            "due_date":"2019-08-16",
            "start_date":"2019-07-30",
            "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
            "issue_stats": {
               "total": 98,
               "closed": 76
            }
         },
         {
            "id":52,
            "iid":2,
            "project_id":24,
            "title":"v1.0",
            "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
            "state":"closed",
            "created_at":"2019-07-16T14:00:12.256Z",
            "updated_at":"2019-07-16T14:00:12.256Z",
            "due_date":"2019-08-16",
            "start_date":"2019-07-30",
            "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
            "issue_stats": {
               "total": 24,
               "closed": 21
            }
         }
      ],
      "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
      "tag_path":"/root/awesome-app/-/tags/v0.11.1",
      "assets":{
         "count":6,
         "sources":[
            {
               "format":"zip",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.zip"
            },
            {
               "format":"tar.gz",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar.gz"
            },
            {
               "format":"tar.bz2",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar.bz2"
            },
            {
               "format":"tar",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar"
            }
         ],
         "links":[
            {
               "id":2,
               "name":"awesome-v0.2.msi",
               "url":"http://192.168.10.15:3000/msi",
               "link_type":"other"
            },
            {
               "id":1,
               "name":"awesome-v0.2.dmg",
               "url":"http://192.168.10.15:3000",
               "link_type":"other"
            }
         ],
         "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.2/evidence.json"
      },
      "evidences":[
        {
          "sha": "760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
          "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.2/evidence.json",
          "collected_at": "2019-01-03T01:56:19.539Z"
        }
     ]
   },
   {
      "tag_name":"v0.1",
      "description":"## CHANGELOG\r\n\r\n-Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
      "name":"Awesome app v0.1 alpha",
      "created_at":"2019-01-03T01:55:18.203Z",
      "released_at":"2019-01-03T01:55:18.203Z",
      "author":{
         "id":1,
         "name":"Administrator",
         "username":"root",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
         "web_url":"https://gitlab.example.com/root"
      },
      "commit":{
         "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
         "short_id":"f8d3d94c",
         "title":"Initial commit",
         "created_at":"2019-01-03T01:53:28.000Z",
         "parent_ids":[

         ],
         "message":"Initial commit",
         "author_name":"Administrator",
         "author_email":"admin@example.com",
         "authored_date":"2019-01-03T01:53:28.000Z",
         "committer_name":"Administrator",
         "committer_email":"admin@example.com",
         "committed_date":"2019-01-03T01:53:28.000Z"
      },
      "assets":{
         "count":4,
         "sources":[
            {
               "format":"zip",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
            },
            {
               "format":"tar.gz",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
            },
            {
               "format":"tar.bz2",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
            },
            {
               "format":"tar",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
            }
         ],
         "links":[

         ],
         "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
      },
      "evidences":[
        {
          "sha": "c3ffedec13af470e760d6cdfb08790f71cf52c6cde4d",
          "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json",
          "collected_at": "2019-01-03T01:55:18.203Z"
        }
      ],
      "_links": {
         "closed_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=closed",
         "closed_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=closed",
         "edit_url": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/edit",
         "merged_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=merged",
         "opened_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=opened",
         "opened_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=opened",
         "self": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1"
      }
   }
]
```

## タグ名でリリースを取得する {#get-a-release-by-a-tag-name}

指定されたタグのリリースを取得します。

```plaintext
GET /projects/:id/releases/:tag_name
```

| 属性                  | 型           | 必須 | 説明                                                                         |
|----------------------------| -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`                       | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。  |
| `tag_name`                 | 文字列         | はい      | リリースが関連付けられているGitタグ。                                         |
| `include_html_description` | ブール値        | いいえ       | `true`の場合、応答には、リリースの説明のMarkdownのHTMLレンダリングが含まれます。   |

成功した場合、[`200 OK`](../rest/troubleshooting.md#status-codes)と次の応答属性を返します。

| 属性                             | 型   | 説明                                      |
|:--------------------------------------|:-------|:-------------------------------------------------|
| `[]._links`                           | オブジェクト | リリースのリンク                            |
| `[]._links.closed_issues_url`         | 文字列 | リリースの完了イシューのHTTP URL         |
| `[]._links.closed_merge_requests_url` | 文字列 | リリースの完了マージリクエストのHTTP URL |
| `[]._links.edit_url`                  | 文字列 | リリースの編集ページのHTTP URL             |
| `[]._links.merged_merge_requests_url` | 文字列 | リリースのマージ済みのマージリクエストのHTTP URL |
| `[]._links.opened_issues_url`         | 文字列 | リリースの未完了イシューのHTTP URL           |
| `[]._links.opened_merge_requests_url` | 文字列 | リリースの未完了マージリクエストのHTTP URL   |
| `[]._links.self`                      | 文字列 | リリースのHTTP URL                         |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

応答の例:

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"Awesome app v0.1 alpha",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "milestones": [
       {
         "id":51,
         "iid":1,
         "project_id":24,
         "title":"v1.0-rc",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-12T19:45:44.256Z",
         "updated_at":"2019-07-12T19:45:44.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
         "issue_stats": {
            "total": 98,
            "closed": 76
         }
       },
       {
         "id":52,
         "iid":2,
         "project_id":24,
         "title":"v1.0",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-16T14:00:12.256Z",
         "updated_at":"2019-07-16T14:00:12.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
         "issue_stats": {
            "total": 24,
            "closed": 21
         }
       }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "assets":{
      "count":5,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[
         {
            "id":3,
            "name":"hoge",
            "url":"https://gitlab.example.com/root/awesome-app/-/tags/v0.11.1/binaries/linux-amd64",
            "link_type":"other"
         }
      ]
   },
   "evidences":[
     {
       "sha": "760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
       "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json",
       "collected_at": "2019-07-16T14:00:12.256Z"
     },
   "_links": {
      "closed_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=closed",
      "closed_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=closed",
      "edit_url": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/edit",
      "merged_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=merged",
      "opened_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=opened",
      "opened_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=opened",
      "self": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1"
    }
  ]
}
```

## リリースアセットをダウンロードする {#download-a-release-asset}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/358188)されました。

{{< /history >}}

次の形式でリクエストを作成して、リリースアセットファイルをダウンロードします。

```plaintext
GET /projects/:id/releases/:tag_name/downloads/:direct_asset_path
```

| 属性                  | 型           | 必須 | 説明                                                                         |
|----------------------------| -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`                       | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。  |
| `tag_name`                 | 文字列         | はい      | リリースが関連付けられているGitタグ。                                         |
| `direct_asset_path`        | 文字列         | はい      | リンクを[作成](links.md#create-a-release-link)または[更新](links.md#update-a-release-link)するときに指定された、リリースアセットファイルへのパス。 |

リクエストの例:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/downloads/bin/asset.exe"
```

### 最新のリリースを取得する {#get-the-latest-release}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/358188)されました。

{{< /history >}}

最新のリリース情報には、永続的なAPI URLからアクセスできます。

URLの形式:

```plaintext
GET /projects/:id/releases/permalink/latest
```

リリースタグを必要とする他のGET APIを呼び出すには、`permalink/latest` APIパスにサフィックスを付加します。

たとえば、最新の[リリースエビデンス](#collect-release-evidence)を取得するには、次の形式を使用できます。

```plaintext
GET /projects/:id/releases/permalink/latest/evidence
```

もう1つの例は、最新のリリースの[アセットをダウンロード](#download-a-release-asset)することであり、これには次の形式を使用できます。

```plaintext
GET /projects/:id/releases/permalink/latest/downloads/bin/asset.exe
```

#### 並べ替えの設定 {#sorting-preferences}

デフォルトでは、GitLabは`released_at`時間を使用してリリースをフェッチします。クエリパラメータ`?order_by=released_at`の使用はオプションであり、`?order_by=semver`のサポートは、[イシュー352945](https://gitlab.com/gitlab-org/gitlab/-/issues/352945)で追跡されています。

## リリースを作成する {#create-a-release}

リリースを作成します。リリースを作成するには、プロジェクトへのデベロッパーレベルのアクセスが必要です。

```plaintext
POST /projects/:id/releases
```

| 属性          | 型            | 必須                    | 説明                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | 整数または文字列  | はい                         | プロジェクトのID、または[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。                                              |
| `name`             | 文字列          | いいえ                          | リリース名。                                                                                                                |
| `tag_name`         | 文字列          | はい                         | リリースの作成元のタグ。                                                                                  |
| `tag_message`      | 文字列          | いいえ                          | 新しい注釈付きタグを作成する場合に使用するメッセージ。                                                                                  |
| `description`      | 文字列          | いいえ                          | リリースに関する説明。[Markdown](../../user/markdown.md)を使用できます。                                                  |
| `ref`              | 文字列          | はい（`tag_name`が存在しない場合） | `tag_name`で指定されたタグが存在しない場合、リリースは`ref`から作成され、`tag_name`でタグ付けされます。コミットSHA、別のタグ名、またはブランチ名にすることができます。 |
| `milestones`       | 文字列の配列 | いいえ                          | リリースが関連付けられている各マイルストーンのタイトル。[GitLab Premium](https://about.gitlab.com/pricing/)のお客様は、グループマイルストーンを指定できます。                                                                      |
| `assets:links`     | ハッシュの配列   | いいえ                          | アセットリンクの配列。                                                                                                        |
| `assets:links:name`| 文字列          | `assets:links`で必要 | リンクの名前。リンク名は、リリース内で一意である必要があります。                                                              |
| `assets:links:url` | 文字列          | `assets:links`で必要 | リンクのURL。リンクURLは、リリース内で一意である必要があります。                                                                |
| `assets:links:direct_asset_path` | 文字列     | いいえ | [ダイレクトアセットリンク](../../user/project/releases/release_fields.md#permanent-links-to-release-assets)のオプションのパス。 |
| `assets:links:link_type` | 文字列     | いいえ | リンクの種類: `other`、`runbook`、`image`、`package`。`other`がデフォルトです。 |
| `released_at`      | 日時        | いいえ                          | リリースの日時。デフォルトは現在の時刻です。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。このフィールドは、[今後の](../../user/project/releases/_index.md#upcoming-releases)リリースまたは[過去の](../../user/project/releases/_index.md#historical-releases)リリースを作成する場合のみ指定します。  |

リクエストの例:

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "name": "New release", "tag_name": "v0.3", "description": "Super nice release", "milestones": ["v1.0", "v1.0-rc"], "assets": { "links": [{ "name": "hoge", "url": "https://google.com", "direct_asset_path": "/binaries/linux-amd64", "link_type":"other" }] } }' \
     --request POST "https://gitlab.example.com/api/v4/projects/24/releases"
```

応答の例:

```json
{
   "tag_name":"v0.3",
   "description":"Super nice release",
   "name":"New release",
   "created_at":"2019-01-03T02:22:45.118Z",
   "released_at":"2019-01-03T02:22:45.118Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"079e90101242458910cccd35eab0e211dfc359c0",
      "short_id":"079e9010",
      "title":"Update README.md",
      "created_at":"2019-01-03T01:55:38.000Z",
      "parent_ids":[
         "f8d3d94cbd347e924aa7b715845e439d00e80ca4"
      ],
      "message":"Update README.md",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:55:38.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:55:38.000Z"
   },
   "milestones": [
       {
         "id":51,
         "iid":1,
         "project_id":24,
         "title":"v1.0-rc",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-12T19:45:44.256Z",
         "updated_at":"2019-07-12T19:45:44.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
         "issue_stats": {
            "total": 99,
            "closed": 76
         }
       },
       {
         "id":52,
         "iid":2,
         "project_id":24,
         "title":"v1.0",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-16T14:00:12.256Z",
         "updated_at":"2019-07-16T14:00:12.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
         "issue_stats": {
            "total": 24,
            "closed": 21
         }
       }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":5,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar"
         }
      ],
      "links":[
         {
            "id":3,
            "name":"hoge",
            "url":"https://gitlab.example.com/root/awesome-app/-/tags/v0.11.1/binaries/linux-amd64",
            "link_type":"other"
         }
      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.3/evidence.json"
   }
}
```

### グループマイルストーン {#group-milestones}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトに関連付けられたグループマイルストーンは、[リリースを作成する](#create-a-release)および[リリースを更新する](#update-a-release)のAPIコールの`milestones`配列で指定できます。プロジェクトのグループに関連付けられたマイルストーンのみを指定でき、祖先グループのマイルストーンを追加するとエラーが発生します。

## リリースエビデンスを収集する {#collect-release-evidence}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

既存のリリースのエビデンスを作成します。

```plaintext
POST /projects/:id/releases/:tag_name/evidence
```

| 属性     | 型           | 必須 | 説明                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `tag_name`    | 文字列         | はい      | リリースが関連付けられているGitタグ。                                         |

リクエストの例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/evidence"
```

応答の例:

```json
200
```

## リリースを更新する {#update-a-release}

{{< history >}}

- GitLab 14.5で`JOB-TOKEN`が利用できるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72448)されました。

{{< /history >}}

リリースを更新します。リリースを更新するには、プロジェクトに対するデベロッパーレベルのアクセス権が必要です。

```plaintext
PUT /projects/:id/releases/:tag_name
```

| 属性     | 型            | 必須 | 説明                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | 整数または文字列  | はい      | プロジェクトのID、または[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。                         |
| `tag_name`    | 文字列          | はい      | リリースが関連付けられているGitタグ。                                                                 |
| `name`        | 文字列          | いいえ       | リリース名。                                                                                           |
| `description` | 文字列          | いいえ       | リリースに関する説明。[Markdown](../../user/markdown.md)を使用できます。                             |
| `milestones`  | 文字列の配列 | いいえ       | リリースに関連付ける各マイルストーンのタイトル。[GitLab Premium](https://about.gitlab.com/pricing/)のお客様は、グループマイルストーンを指定できます。リリースからすべてのマイルストーンを削除するには、`[]`を指定します。 |
| `released_at` | 日時        | いいえ       | リリースが準備完了になる/なった日付。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。          |

リクエストの例:

```shell
curl --header 'Content-Type: application/json' --request PUT --data '{"name": "new name", "milestones": ["v1.2"]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

応答の例:

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"new name",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "milestones": [
      {
         "id":53,
         "iid":3,
         "project_id":24,
         "title":"v1.2",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"active",
         "created_at":"2019-09-01T13:00:00.256Z",
         "updated_at":"2019-09-01T13:00:00.256Z",
         "due_date":"2019-09-20",
         "start_date":"2019-09-05",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/3",
         "issue_stats": {
            "opened": 11,
            "closed": 78
         }
      }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":4,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[

      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
   }
}
```

## リリースを削除する {#delete-a-release}

リリースを削除します。リリースを削除しても、関連付けられているタグは削除されません。リリースを削除するには、プロジェクトに対するメンテナーレベルのアクセス権が必要です。

```plaintext
DELETE /projects/:id/releases/:tag_name
```

| 属性     | 型           | 必須 | 説明                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `tag_name`    | 文字列         | はい      | リリースが関連付けられているGitタグ。                                         |

リクエストの例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

応答の例:

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"new name",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":4,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[

      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
   }
}
```

## 将来のリリース {#upcoming-releases}

`released_at`属性が将来の日付に設定されたリリースは、[UIで](../../user/project/releases/_index.md#upcoming-releases)**今後のリリース**としてラベル付けされます。

また、[APIからリリースがリクエストされた](#list-releases)場合、`release_at`属性が将来の日付に設定された各リリースに対して、追加の属性`upcoming_release`（trueに設定）が応答の一部として返されます。

## 過去のリリース {#historical-releases}

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/199429)されました。

{{< /history >}}

`released_at`属性が過去の日付に設定されたリリースは、[UIで](../../user/project/releases/_index.md#historical-releases)**過去のリリース**としてラベル付けされます。

また、[APIからリリースがリクエストされた](#list-releases)場合、`release_at`属性が過去の日付に設定された各リリースに対して、追加の属性`historical_release`（trueに設定）が応答の一部として返されます。
