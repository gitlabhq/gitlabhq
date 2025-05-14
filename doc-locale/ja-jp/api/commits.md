---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for Git commits in GitLab.
title: コミットAPI
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIは、[リポジトリコミット](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository)に対して動作します。コミットに関する[GitLab固有の情報](../user/project/repository/_index.md#commit-changes-to-a-repository)の詳細をお読みください。

## 応答

このAPIからの応答に含まれる日付フィールドの一部で、情報が重複しているか、またはそのように見えることがあります。

- `created_at`フィールドは、他のGitLab APIとの整合性の目的でのみ存在しています。常に`committed_date`フィールドと同一です。
- `committed_date`フィールドと`authored_date`フィールドは異なるソースから生成されるため、同一ではない場合があります。

## リポジトリコミットをリストする

{{< history >}}

- 作成者によるコミットがGitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114417)されました。

{{< /history >}}

プロジェクト内のリポジトリコミットのリストを取得します。

```plaintext
GET /projects/:id/repository/commits
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `ref_name` | 文字列 | いいえ | リポジトリのブランチ名、タグ、またはリビジョン範囲。指定されていない場合はデフォルトのブランチです。 |
| `since` | 文字列 | いいえ | この日付以降のコミットのみがISO 8601形式（`YYYY-MM-DDTHH:MM:SSZ`）で返されます。 |
| `until` | 文字列 | いいえ | この日付以前のコミットのみがISO 8601形式（`YYYY-MM-DDTHH:MM:SSZ`）で返されます。 |
| `path` | 文字列 | いいえ | ファイルパス |
| `author` | 文字列 | いいえ | コミット作成者でコミットを検索します。|
| `all` | ブール値 | いいえ | リポジトリからすべてのコミットを取得します |
| `with_stats` | ブール値 | いいえ | 各コミットに関する統計が応答に追加されます。 |
| `first_parent` | ブール値 | いいえ | マージコミットが確認されたら、最初の親コミットのみをフォローします。 |
| `order` | 文字列 | いいえ | コミットを順にリストします。使用可能な値は`default`、[`topo`](https://git-scm.com/docs/git-log#Documentation/git-log.txt---topo-order)です。デフォルトは`default`で、コミットは逆時系列順に表示されます。 |
| `trailers` | ブール値 | いいえ | 各コミットの[Gitトレーラー](https://git-scm.com/docs/git-interpret-trailers)を解析して含めます。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits"
```

応答の例:

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2021-09-20T11:50:22.001+00:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2021-09-20T11:50:22.001+00:00",
    "created_at": "2021-09-20T11:50:22.001+00:00",
    "message": "Replace sanitize with escape once",
    "parent_ids": [
      "6104942438c14ec7bd21c6cd5bd995272b3faff6"
    ],
    "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746",
    "trailers": {},
    "extended_trailers": {}
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "randx",
    "author_email": "user@example.com",
    "committer_name": "ExampleName",
    "committer_email": "user@example.com",
    "created_at": "2021-09-20T09:06:12.201+00:00",
    "message": "Sanitize for network graph\nCc: John Doe <johndoe@gitlab.com>\nCc: Jane Doe <janedoe@gitlab.com>",
    "parent_ids": [
      "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
    ],
    "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746",
    "trailers": { "Cc": "Jane Doe <janedoe@gitlab.com>" },
    "extended_trailers": { "Cc": ["John Doe <johndoe@gitlab.com>", "Jane Doe <janedoe@gitlab.com>"] }
  }
]
```

## 複数のファイルとアクションを含むコミットを作成する

JSONペイロードを送信することでコミットを作成します。

```plaintext
POST /projects/:id/repository/commits
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `branch` | 文字列 | はい | コミット先のブランチの名前。新しいブランチを作成するには、`start_branch`または`start_sha`を指定します。また、オプションで`start_project`も指定できます。 |
| `commit_message` | 文字列 | はい | コミットメッセージ |
| `start_branch` | 文字列 | いいえ | 新しいブランチの開始元となるブランチの名前。 |
| `start_sha` | 文字列 | いいえ | 新しいブランチの開始元となるコミットのSHA。 |
| `start_project` | 整数/文字列 | いいえ | 新しいブランチの開始元となるプロジェクトのプロジェクトIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。デフォルトは`id`の値です。 |
| `actions[]` | 配列 | はい | バッチとしてコミットするアクションハッシュの配列。どのような属性を取ることができるかについては、次の表を参照してください。 |
| `author_email` | 文字列 | いいえ | コミット作成者のメールアドレスを指定します。 |
| `author_name` | 文字列 | いいえ | コミット作成者の名前を指定します。 |
| `stats` | ブール値 | いいえ | コミット統計を含めます。デフォルトはtrueです。 |
| `force` | ブール値 | いいえ | `true`の場合、`start_branch`または`start_sha`に基づく新しいコミットでターゲットブランチを上書きします。 |

| `actions[]`属性 | 型    | 必須 | 説明 |
|-----------------------|---------|----------|-------------|
| `action`              | 文字列  | はい      | 実行するアクション（`create`、`delete`、`move`、`update`、または`chmod`）。 |
| `file_path`           | 文字列  | はい      | ファイルのフルパス。たとえば`lib/class.rb`などです。 |
| `previous_path`       | 文字列  | いいえ       | 移動されるファイルの元のフルパス。たとえば`lib/class1.rb`などです。`move`アクションの場合のみ考慮されます。 |
| `content`             | 文字列  | いいえ       | ファイルの内容。`delete`、`chmod`、`move`を除くすべての場合に必須です。移動アクションで`content`が指定されていない場合、既存のファイルコンテンツが保持されます。`content`の他の値の場合、ファイルの内容が上書きされます。 |
| `encoding`            | 文字列  | いいえ       | `text`または`base64`。`text`がデフォルトです。 |
| `last_commit_id`      | 文字列  | いいえ       | 既知の最新のファイルコミットID。update、move、およびdeleteアクションでのみ考慮されます。 |
| `execute_filemode`    | ブール値 | いいえ       | `true/false`。ファイルで実行フラグを有効/無効にします。`chmod`アクションの場合のみ考慮されます。 |

```shell
PAYLOAD=$(cat << 'JSON'
{
  "branch": "main",
  "commit_message": "some commit message",
  "actions": [
    {
      "action": "create",
      "file_path": "foo/bar",
      "content": "some content"
    },
    {
      "action": "delete",
      "file_path": "foo/bar2"
    },
    {
      "action": "move",
      "file_path": "foo/bar3",
      "previous_path": "foo/bar4",
      "content": "some content"
    },
    {
      "action": "update",
      "file_path": "foo/bar5",
      "content": "new content"
    },
    {
      "action": "chmod",
      "file_path": "foo/bar5",
      "execute_filemode": true
    }
  ]
}
JSON
)
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data "$PAYLOAD" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/commits"
```

応答の例:

```json
{
  "id": "ed899a2f4b50b4370feeea94676502b42383c746",
  "short_id": "ed899a2f4b5",
  "title": "some commit message",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "committer_name": "Example User",
  "committer_email": "user@example.com",
  "created_at": "2016-09-20T09:26:24.000-07:00",
  "message": "some commit message",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "committed_date": "2016-09-20T09:26:24.000-07:00",
  "authored_date": "2016-09-20T09:26:24.000-07:00",
  "stats": {
    "additions": 2,
    "deletions": 2,
    "total": 4
  },
  "status": null,
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746"
}
```

GitLabは[フォームエンコード](rest/_index.md#array-and-hash-types)をサポートしています。次に、フォームエンコードでコミットAPIを使用する例を示します。

```shell
curl --request POST \
     --form "branch=main" \
     --form "commit_message=some commit message" \
     --form "start_branch=main" \
     --form "actions[][action]=create" \
     --form "actions[][file_path]=foo/bar" \
     --form "actions[][content]=</path/to/local.file" \
     --form "actions[][action]=delete" \
     --form "actions[][file_path]=foo/bar2" \
     --form "actions[][action]=move" \
     --form "actions[][file_path]=foo/bar3" \
     --form "actions[][previous_path]=foo/bar4" \
     --form "actions[][content]=</path/to/local1.file" \
     --form "actions[][action]=update" \
     --form "actions[][file_path]=foo/bar5" \
     --form "actions[][content]=</path/to/local2.file" \
     --form "actions[][action]=chmod" \
     --form "actions[][file_path]=foo/bar5" \
     --form "actions[][execute_filemode]=true" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/repository/commits"
```

## 1つのコミットを取得する

ブランチまたはタグのコミットハッシュまたは名前で識別される特定のコミットを取得します。

```plaintext
GET /projects/:id/repository/commits/:sha
```

パラメーター:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `sha` | 文字列 | はい | リポジトリブランチまたはタグのコミットハッシュまたは名前 |
| `stats` | ブール値 | いいえ | コミット統計を含めます。デフォルトはtrueです。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main"
```

応答の例:

```json
{
  "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
  "short_id": "6104942438c",
  "title": "Sanitize for network graph",
  "author_name": "randx",
  "author_email": "user@example.com",
  "committer_name": "Dmitriy",
  "committer_email": "user@example.com",
  "created_at": "2021-09-20T09:06:12.300+03:00",
  "message": "Sanitize for network graph",
  "committed_date": "2021-09-20T09:06:12.300+03:00",
  "authored_date": "2021-09-20T09:06:12.420+03:00",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "last_pipeline" : {
    "id": 8,
    "ref": "main",
    "sha": "2dc6aa325a317eda67812f05600bdf0fcdc70ab0",
    "status": "created"
  },
  "stats": {
    "additions": 15,
    "deletions": 10,
    "total": 25
  },
  "status": "running",
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/6104942438c14ec7bd21c6cd5bd995272b3faff6"
}
```

## コミットのプッシュ先の参照を取得する

コミットのプッシュ先の参照をすべて（ブランチまたはタグから）を取得します。ページネーションパラメーター`page`と`per_page`を使用して、参照のリストを制限できます。

```plaintext
GET /projects/:id/repository/commits/:sha/refs
```

パラメーター:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `sha` | 文字列 | はい | コミットハッシュ。  |
| `type` | 文字列 | いいえ | コミットのスコープ。使用可能な値は`branch`、`tag`、`all`です。デフォルトは`all`です。  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/5937ac0a7beb003549fc5fd26fc247adbce4a52e/refs?type=all"
```

応答の例:

```json
[
  {"type": "branch", "name": "'test'"},
  {"type": "branch", "name": "add-balsamiq-file"},
  {"type": "branch", "name": "wip"},
  {"type": "tag", "name": "v1.1.0"}
 ]

```

## コミットのシーケンスを取得する

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438151)されました。

{{< /history >}}

指定されたコミットから親リンクをたどって、プロジェクト内のコミットのシーケンス番号を取得します。

このAPIは、特定のコミットSHAに対する`git rev-list --count`コマンドと基本的に同じ機能を提供します。

```plaintext
GET /projects/:id/repository/commits/:sha/sequence
```

パラメーター:

| 属性      | 型           | 必須 | 説明 |
| -------------- | -------------- | -------- | ----------- |
| `id`           | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `sha`          | 文字列         | はい      | コミットハッシュ。 |
| `first_parent` | ブール値        | いいえ       | マージコミットが確認されたら、最初の親コミットのみに従います。 |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/5937ac0a7beb003549fc5fd26fc247adbce4a52e/sequence"
```

応答の例:

```json
{
  "count": 632
}
```

## コミットをcherry-pickする

指定されたブランチにコミットをcherry-pickします。

```plaintext
POST /projects/:id/repository/commits/:sha/cherry_pick
```

パラメーター:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `sha` | 文字列 | はい | コミットハッシュ。  |
| `branch` | 文字列 | はい | ブランチの名前  |
| `dry_run` | ブール値 | いいえ | 変更をコミットしません。デフォルトはfalseです。 |
| `message` | 文字列 | いいえ | 新しいコミットに使用するカスタムコミットメッセージ。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "branch=main" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/cherry_pick"
```

応答の例:

```json
{
  "id": "8b090c1b79a14f2bd9e8a738f717824ff53aebad",
  "short_id": "8b090c1b",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "authored_date": "2016-12-12T20:10:39.000+01:00",
  "created_at": "2016-12-12T20:10:39.000+01:00",
  "committer_name": "Administrator",
  "committer_email": "admin@example.com",
  "committed_date": "2016-12-12T20:10:39.000+01:00",
  "title": "Feature added",
  "message": "Feature added\n\nSigned-off-by: Example User <user@example.com>\n",
  "parent_ids": [
    "a738f717824ff53aebad8b090c1b79a14f2bd9e8"
  ],
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/8b090c1b79a14f2bd9e8a738f717824ff53aebad"
}
```

cherry-pickが失敗した場合、応答はその理由に関するコンテキストを提供します。

```json
{
  "message": "Sorry, we cannot cherry-pick this commit automatically. This commit may already have been cherry-picked, or a more recent commit may have updated some of its content.",
  "error_code": "empty"
}
```

この場合、変更セットが空であるためにcherry-pickが失敗しました。これは、コミットがターゲットブランチにすでに存在することを示している可能性があります。返される可能性があるもう1つのエラーコードは`conflict`です。これはマージコンフリクトが発生していたことを示します。

`dry_run`が有効になっている場合、サーバーはcherry-pickの適用を試みますが、_実際には結果の変更をコミットしません_。cherry-pickが正常に適用されると、APIは`200 OK`で応答します。

```json
{
  "dry_run": "success"
}
```

失敗した場合、ドライランなしの失敗と同じエラーが表示されます。

## コミットをリバートする

指定されたブランチのコミットをリバートします。

```plaintext
POST /projects/:id/repository/commits/:sha/revert
```

パラメーター:

| 属性 | 型           | 必須 | 説明                                                                     |
| --------- | ----           | -------- | -----------                                                                     |
| `id`      | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `sha`     | 文字列         | はい      | リバートするコミットSHA                                                            |
| `branch`  | 文字列         | はい      | ターゲットブランチ名                                                              |
| `dry_run` | ブール値        | いいえ       | 変更をコミットしません。デフォルトはfalseです。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "branch=main" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/a738f717824ff53aebad8b090c1b79a14f2bd9e8/revert"
```

応答の例:

```json
{
  "id":"8b090c1b79a14f2bd9e8a738f717824ff53aebad",
  "short_id": "8b090c1b",
  "title":"Revert \"Feature added\"",
  "created_at":"2018-11-08T15:55:26.000Z",
  "parent_ids":["a738f717824ff53aebad8b090c1b79a14f2bd9e8"],
  "message":"Revert \"Feature added\"\n\nThis reverts commit a738f717824ff53aebad8b090c1b79a14f2bd9e8",
  "author_name":"Administrator",
  "author_email":"admin@example.com",
  "authored_date":"2018-11-08T15:55:26.000Z",
  "committer_name":"Administrator",
  "committer_email":"admin@example.com",
  "committed_date":"2018-11-08T15:55:26.000Z",
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/8b090c1b79a14f2bd9e8a738f717824ff53aebad"
}
```

リバートが失敗した場合、応答はその理由に関するコンテキストを提供します。

```json
{
  "message": "Sorry, we cannot revert this commit automatically. This commit may already have been reverted, or a more recent commit may have updated some of its content.",
  "error_code": "conflict"
}
```

上記の例では、試行されたリバートによってマージコンフリクトが発生したためにリバートが失敗しました。返される可能性があるもう1つのエラーコードは`empty`です。これは、変更がすでにリバートされているために、変更セットが空であることを示しています。

`dry_run`が有効になっている場合、サーバーはリバートの適用を試みますが、_実際には結果の変更をコミットしません_。リバートが正常に適用されると、APIは`200 OK`で応答します。

```json
{
  "dry_run": "success"
}
```

失敗した場合、ドライランなしの失敗と同じエラーが表示されます。

## コミットの差分を取得する

プロジェクト内のコミットの差分を取得します。

```plaintext
GET /projects/:id/repository/commits/:sha/diff
```

パラメーター:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `sha` | 文字列 | はい | リポジトリブランチまたはタグのコミットハッシュまたは名前 |
| `unidiff` | ブール値 | いいえ | [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html)形式で差分を表示します。デフォルトはfalseです。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610)されました。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/diff"
```

応答の例:

```json
[
  {
    "diff": "@@ -71,6 +71,8 @@\n sudo -u git -H bundle exec rake migrate_keys RAILS_ENV=production\n sudo -u git -H bundle exec rake migrate_inline_notes RAILS_ENV=production\n \n+sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production\n+\n ```\n \n ### 6. Update config files",
    "new_path": "doc/update/5.4-to-6.0.md",
    "old_path": "doc/update/5.4-to-6.0.md",
    "a_mode": null,
    "b_mode": "100644",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }
]
```

## コミットのコメントを取得する

プロジェクト内のコミットのコメントを取得します。

```plaintext
GET /projects/:id/repository/commits/:sha/comments
```

パラメーター:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `sha` | 文字列 | はい | リポジトリブランチまたはタグのコミットハッシュまたは名前 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/comments"
```

応答の例:

```json
[
  {
    "note": "this code is really nice",
    "author": {
      "id": 11,
      "username": "admin",
      "email": "admin@local.host",
      "name": "Administrator",
      "state": "active",
      "created_at": "2014-03-06T08:17:35.000Z"
    }
  }
]
```

## コミットへのコメントを投稿する

コミットにコメントを追加します。

特定のファイルの特定の行にコメントを投稿するには、完全なコミットSHA、`path`、`line`を指定する必要があり、`line_type`は`new`である必要があります。

以下の1つ以上のケースに該当する場合、コメントは最終コミットの終わりに追加されます。

- ブランチまたはタグの代わりに`sha`があり、`line`または`path`が無効である
- `line`番号が無効である（存在しない）
- `path`が無効である（存在しない）

上記のいずれの場合も、`line`、`line_type`、`path`の応答は`null`に設定されます。

マージリクエストへコメントするその他の方法については、ノートAPIの[新しいマージリクエストノートを作成する](notes.md#create-new-merge-request-note)、およびディスカッションAPIの[マージリクエスト差分に新しいスレッドを作成する](discussions.md#create-a-new-thread-in-the-merge-request-diff)を参照してください。

```plaintext
POST /projects/:id/repository/commits/:sha/comments
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `sha`       | 文字列  | はい | リポジトリのブランチまたはタグのコミットSHAまたは名前 |
| `note`      | 文字列  | はい | コメントのテキスト |
| `path`      | 文字列  | いいえ  | リポジトリを基準とした相対的なファイルパス |
| `line`      | 整数 | いいえ  | コメントを配置する行の番号 |
| `line_type` | 文字列  | いいえ  | 行のタイプ。引数として`new`または`old`を取ります。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=Nice picture\!" \
  --form "path=README.md" \
  --form "line=11" \
  --form "line_type=new" \
  --url "https://gitlab.example.com/api/v4/projects/17/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/comments"
```

応答の例:

```json
{
   "author" : {
      "web_url" : "https://gitlab.example.com/janedoe",
      "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
      "username" : "janedoe",
      "state" : "active",
      "name" : "Jane Doe",
      "id" : 28
   },
   "created_at" : "2016-01-19T09:44:55.600Z",
   "line_type" : "new",
   "path" : "README.md",
   "line" : 11,
   "note" : "Nice picture!"
}
```

## コミットのディスカッションを取得する

プロジェクト内のコミットのディスカッションを取得します。

```plaintext
GET /projects/:id/repository/commits/:sha/discussions
```

パラメーター:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `sha`     | 文字列 | はい | リポジトリブランチまたはタグのコミットハッシュまたは名前 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/4604744a1c64de00ff62e1e8a6766919923d2b41/discussions"
```

応答の例:

```json
[
  {
    "id": "4604744a1c64de00ff62e1e8a6766919923d2b41",
    "individual_note": true,
    "notes": [
      {
        "id": 334686748,
        "type": null,
        "body": "Nice piece of code!",
        "attachment": null,
        "author" : {
          "id" : 28,
          "name" : "Jane Doe",
          "username" : "janedoe",
          "web_url" : "https://gitlab.example.com/janedoe",
          "state" : "active",
          "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png"
        },
        "created_at": "2020-04-30T18:48:11.432Z",
        "updated_at": "2020-04-30T18:48:11.432Z",
        "system": false,
        "noteable_id": null,
        "noteable_type": "Commit",
        "resolvable": false,
        "confidential": null,
        "noteable_iid": null,
        "commands_changes": {}
      }
    ]
  }
]

```

## コミットステータス

GitLabで使用するコミットステータスAPIです。

### コミットのステータスをリストする

{{< history >}}

- `pipeline_id`、`order_by`、および`sort`フィールドは、GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176142)されました。

{{< /history >}}

プロジェクト内のコミットのステータスをリストします。ページネーションパラメーター`page`と`per_page`を使用して、参照のリストを制限できます。

```plaintext
GET /projects/:id/repository/commits/:sha/statuses
```

| 属性     | 型           | 必須 | 説明                                                                          |
|---------------|----------------| -------- |--------------------------------------------------------------------------------------|
| `id`          | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。          |
| `sha`         | 文字列         | はい | コミットのハッシュ。                                                                      |
| `ref`         | 文字列         | いいえ  | ブランチまたはタグの名前。デフォルトはデフォルトブランチです。          |
| `stage`       | 文字列         | いいえ  | [ビルドステージ](../ci/yaml/_index.md#stages)でステータスをフィルタリングします。たとえば`test`などです。             |
| `name`        | 文字列         | いいえ  | [ジョブ名](../ci/yaml/_index.md#job-keywords)でステータスをフィルタリングします。たとえば`bundler:audit`などです。 |
| `pipeline_id` | 整数        | いいえ  | パイプラインIDでステータスをフィルタリングします。たとえば`1234`などです。                                            |
| `order_by`    | 文字列         | いいえ  | ステータスをソートするための値。有効な値は`id`と`pipeline_id`です。デフォルトは`id`です。                    |
| `sort`        | 文字列         | いいえ  | ステータスを昇順または降順でソートします。有効な値は`asc`と`desc`です。デフォルトは`asc`です。                  |
| `all`         | ブール値        | いいえ  | 最新のステータスだけでなく、すべてのステータスを含めます。デフォルトは`false`です。                                       |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/17/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/statuses"
```

応答の例:

```json
[
   ...

   {
      "status" : "pending",
      "created_at" : "2016-01-19T08:40:25.934Z",
      "started_at" : null,
      "name" : "bundler:audit",
      "allow_failure" : true,
      "author" : {
         "username" : "janedoe",
         "state" : "active",
         "web_url" : "https://gitlab.example.com/janedoe",
         "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
         "id" : 28,
         "name" : "Jane Doe"
      },
      "description" : null,
      "sha" : "18f3e63d05582537db6d183d9d557be09e1f90c8",
      "target_url" : "https://gitlab.example.com/janedoe/gitlab-foss/builds/91",
      "finished_at" : null,
      "id" : 91,
      "ref" : "main"
   },
   {
      "started_at" : null,
      "name" : "test",
      "allow_failure" : false,
      "status" : "pending",
      "created_at" : "2016-01-19T08:40:25.832Z",
      "target_url" : "https://gitlab.example.com/janedoe/gitlab-foss/builds/90",
      "id" : 90,
      "finished_at" : null,
      "ref" : "main",
      "sha" : "18f3e63d05582537db6d183d9d557be09e1f90c8",
      "author" : {
         "id" : 28,
         "name" : "Jane Doe",
         "username" : "janedoe",
         "web_url" : "https://gitlab.example.com/janedoe",
         "state" : "active",
         "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png"
      },
      "description" : null
   },

   ...
]
```

### コミットのパイプラインステータスを設定する

コミットのパイプラインステータスを追加または更新します。コミットがマージリクエストに関連付けられている場合、APIコールのターゲットはマージリクエストのソースブランチのコミットである必要があります。

```plaintext
POST /projects/:id/statuses/:sha
```

| 属性 | 型 | 必須 | 説明                                                                                                           |
| --------- | ---- | -------- |-----------------------------------------------------------------------------------------------------------------------|
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                                           |
| `sha`     | 文字列  | はい   | コミットSHA                                                                                                        |
| `state`   | 文字列  | はい   | ステータスの状態。`pending`、`running`、`success`、`failed`、`canceled`、`skipped`のいずれかになります。 |
| `ref`     | 文字列  | いいえ    | ステータスが参照する`ref`（ブランチまたはタグ）。255文字以下にする必要があります。                                                                  |
| `name`または`context` | 文字列  | いいえ | このステータスを他のシステムのステータスと区別するためのラベル。デフォルト値は`default`です                   |
| `target_url` |  文字列  | いいえ  | このステータスに関連付けるターゲットURL。255文字以下にする必要があります。                                                                          |
| `description` | 文字列  | いいえ  | ステータスの短い説明。255文字以下にする必要があります。                                                                                   |
| `coverage` | 浮動小数点数  | いいえ    | 合計コードカバレッジ                                                                                               |
| `pipeline_id` |  整数  | いいえ  | ステータスを設定するパイプラインのID。同じSHAで複数のパイプラインがある場合に使用します。                                    |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/17/statuses/18f3e63d05582537db6d183d9d557be09e1f90c8?state=success"
```

応答の例:

```json
{
   "author" : {
      "web_url" : "https://gitlab.example.com/janedoe",
      "name" : "Jane Doe",
      "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
      "username" : "janedoe",
      "state" : "active",
      "id" : 28
   },
   "name" : "default",
   "sha" : "18f3e63d05582537db6d183d9d557be09e1f90c8",
   "status" : "success",
   "coverage": 100.0,
   "description" : null,
   "id" : 93,
   "target_url" : null,
   "ref" : null,
   "started_at" : null,
   "created_at" : "2016-01-19T09:05:50.355Z",
   "allow_failure" : false,
   "finished_at" : "2016-01-19T09:05:50.365Z"
}
```

## コミットに関連付けられたマージリクエストをリストする

特定のコミットを最初に導入したマージリクエストに関する情報を返します。

```plaintext
GET /projects/:id/repository/commits/:sha/merge_requests
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `sha`     | 文字列  | はい   | コミットSHA |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/af5b13261899fb2c0db30abdd0af8b07cb44fdc5/merge_requests"
```

応答の例:

```json
[
   {
      "id":45,
      "iid":1,
      "project_id":35,
      "title":"Add new file",
      "description":"",
      "state":"opened",
      "created_at":"2018-03-26T17:26:30.916Z",
      "updated_at":"2018-03-26T17:26:30.916Z",
      "target_branch":"main",
      "source_branch":"test-branch",
      "upvotes":0,
      "downvotes":0,
      "author" : {
        "web_url" : "https://gitlab.example.com/janedoe",
        "name" : "Jane Doe",
        "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
        "username" : "janedoe",
        "state" : "active",
        "id" : 28
      },
      "assignee":null,
      "source_project_id":35,
      "target_project_id":35,
      "labels":[ ],
      "draft":false,
      "work_in_progress":false,
      "milestone":null,
      "merge_when_pipeline_succeeds":false,
      "merge_status":"can_be_merged",
      "sha":"af5b13261899fb2c0db30abdd0af8b07cb44fdc5",
      "merge_commit_sha":null,
      "squash_commit_sha":null,
      "user_notes_count":0,
      "discussion_locked":null,
      "should_remove_source_branch":null,
      "force_remove_source_branch":false,
      "web_url":"https://gitlab.example.com/root/test-project/merge_requests/1",
      "time_stats":{
         "time_estimate":0,
         "total_time_spent":0,
         "human_time_estimate":null,
         "human_total_time_spent":null
      }
   }
]
```

## コミットの署名を取得する

コミットが署名されている場合に[コミットから署名](../user/project/repository/signed_commits/_index.md)を取得します。署名なしコミットの場合、404応答になります。

```plaintext
GET /projects/:id/repository/commits/:sha/signature
```

パラメーター:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数/文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `sha` | 文字列 | はい | リポジトリブランチまたはタグのコミットハッシュまたは名前 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/commits/da738facbc19eb2fc2cef57c49be0e6038570352/signature"
```

コミットがGPGで署名されている場合の応答の例:

```json
{
  "signature_type": "PGP",
  "verification_status": "verified",
  "gpg_key_id": 1,
  "gpg_key_primary_keyid": "8254AAB3FBD54AC9",
  "gpg_key_user_name": "John Doe",
  "gpg_key_user_email": "johndoe@example.com",
  "gpg_key_subkey_id": null,
  "commit_source": "gitaly"
}
```

コミットがSSHで署名されている場合の応答の例:

```json
{
  "signature_type": "SSH",
  "verification_status": "verified",
  "key": {
    "id": 11,
    "title": "Key",
    "created_at": "2023-05-08T09:12:38.503Z",
    "expires_at": "2024-05-07T00:00:00.000Z",
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZzYDq6DhLp3aX84DGIV3F6Vf+Ae4yCTTz7RnqMJOlR MyKey)",
    "usage_type": "auth_and_signing"
  },
  "commit_source": "gitaly"
}
```

コミットがX.509で署名されている場合の応答の例:

```json
{
  "signature_type": "X509",
  "verification_status": "unverified",
  "x509_certificate": {
    "id": 1,
    "subject": "CN=gitlab@example.org,OU=Example,O=World",
    "subject_key_identifier": "BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC",
    "email": "gitlab@example.org",
    "serial_number": 278969561018901340486471282831158785578,
    "certificate_status": "good",
    "x509_issuer": {
      "id": 1,
      "subject": "CN=PKI,OU=Example,O=World",
      "subject_key_identifier": "AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB",
      "crl_url": "http://example.com/pki.crl"
    }
  },
  "commit_source": "gitaly"
}
```

コミットが署名されていない場合の応答の例:

```json
{
  "message": "404 GPG Signature Not Found"
}
```
