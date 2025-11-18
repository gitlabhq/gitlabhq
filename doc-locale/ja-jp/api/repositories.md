---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのGitリポジトリのためのREST APIのドキュメント
title: リポジトリAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[GitLabリポジトリ](../user/project/repository/_index.md)を管理します。

## リポジトリツリーの一覧 {#list-repository-tree}

プロジェクト内のリポジトリファイルとディレクトリのリストを取得します。リポジトリが公開されている場合、このエンドポイントは認証なしでアクセスできます。

このコマンドは、基本的に`git ls-tree`コマンドと同じ機能を提供します。詳細については、Gitの内部ドキュメントにある[ツリーオブジェクト](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html#_tree_objects)のセクションを参照してください。

{{< alert type="warning" >}}

GitLabバージョン17.7では、リクエストされたパスが見つからない場合のエラー処理動作が変更されました。エンドポイントはステータスコード`404 Not Found`を返すようになりました。以前のステータスコードは`200 OK`でした。

ご使用の実装が、存在しないパスに対して空の配列を持つ`200`ステータスコードが返ってくることを前提としている場合は、新しい`404`応答に対応できるよう、エラー処理を更新する必要があります。

{{< /alert >}}

```plaintext
GET /projects/:id/repository/tree
```

サポートされている属性は以下のとおりです。

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `page_token` | 文字列            | いいえ       | 次のページをフェッチするツリーレコードIDキーセットページネーションでのみ使用されます。 |
| `pagination` | 文字列            | いいえ       | `keyset`の場合、[キーセットベースのページネーション方式](rest/_index.md#keyset-based-pagination)を使用します。 |
| `path`       | 文字列            | いいえ       | リポジトリ内のパス。サブディレクトリの内容を取得するために使用されます。 |
| `per_page`   | 整数           | いいえ       | ページあたりの表示結果数。指定しない場合、デフォルトは`20`です。詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。 |
| `recursive`  | ブール値           | いいえ       | `true`の場合、再帰的なツリーを取得します。デフォルトは`false`です。 |
| `ref`        | 文字列            | いいえ       | リポジトリのブランチまたはタグの名前。指定しない場合、デフォルトブランチを使用します。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)とツリーオブジェクトの配列を返します。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/tree"
```

レスポンス例:

```json
[
  {
    "id": "a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba",
    "name": "html",
    "type": "tree",
    "path": "files/html",
    "mode": "040000"
  },
  {
    "id": "4535904260b1082e14f867f7a24fd8c21495bde3",
    "name": "images",
    "type": "tree",
    "path": "files/images",
    "mode": "040000"
  },
  {
    "id": "31405c5ddef582c5a9b7a85230413ff90e2fe720",
    "name": "js",
    "type": "tree",
    "path": "files/js",
    "mode": "040000"
  },
  {
    "id": "cc71111cfad871212dc99572599a568bfe1e7e00",
    "name": "lfs",
    "type": "tree",
    "path": "files/lfs",
    "mode": "040000"
  },
  {
    "id": "fd581c619bf59cfdfa9c8282377bb09c2f897520",
    "name": "markdown",
    "type": "tree",
    "path": "files/markdown",
    "mode": "040000"
  },
  {
    "id": "23ea4d11a4bdd960ee5320c5cb65b5b3fdbc60db",
    "name": "ruby",
    "type": "tree",
    "path": "files/ruby",
    "mode": "040000"
  },
  {
    "id": "7d70e02340bac451f281cecf0a980907974bd8be",
    "name": "whitespace",
    "type": "blob",
    "path": "files/whitespace",
    "mode": "100644"
  }
]
```

## リポジトリからblobを取得する {#get-a-blob-from-repository}

リポジトリ内のblobについて、サイズや内容といった情報を取得できるようにします。blobコンテンツはBase64エンコードされています。リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

10 MBを超えるblobの場合、このエンドポイントには1分あたり5リクエストというレート制限があります。

```plaintext
GET /projects/:id/repository/blobs/:sha
```

サポートされている属性は以下のとおりです。

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `sha`     | 文字列            | はい      | blob SHA。   |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性  | 型    | 説明 |
|------------|---------|-------------|
| `content`  | 文字列  | Base64エンコードされたblobコンテンツ。 |
| `encoding` | 文字列  | blobコンテンツに使用されるエンコード。 |
| `sha`      | 文字列  | blob SHA。   |
| `size`     | 整数 | Blobのサイズ（バイト単位）。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/blobs/79f7bbd25901e8334750839545a9bd021f0e4c83"
```

レスポンス例:

```json
{
  "size": 1476,
  "encoding": "base64",
  "content": "VGhpcyBpcyBhIGJpbmFyeSBmaWxl",
  "sha": "79f7bbd25901e8334750839545a9bd021f0e4c83"
}
```

## raw blobコンテンツを取得する {#get-raw-blob-content}

blob SHAを指定して、blobのrawファイルのコンテンツを取得します。リポジトリが公開されている場合、このエンドポイントは認証なしでアクセスできます。

```plaintext
GET /projects/:id/repository/blobs/:sha/raw
```

サポートされている属性は以下のとおりです。

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `sha`     | 文字列            | はい      | blob SHA。   |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/blobs/79f7bbd25901e8334750839545a9bd021f0e4c83/raw"
```

## ファイルアーカイブを取得する {#get-file-archive}

リポジトリのアーカイブを取得します。リポジトリが公開されている場合、このエンドポイントは認証なしでアクセスできます。

GitLab.comのユーザーの場合、このエンドポイントには1分あたり5リクエストというレート制限しきい値が設定されています。

```plaintext
GET /projects/:id/repository/archive[.format]
```

`format`はアーカイブ形式のオプションのサフィックスであり、デフォルトは`tar.gz`です。たとえば`archive.zip`を指定すると、ZIP形式でアーカイブが送信されます。使用可能なオプションは次のとおりです。

- `bz2`
- `tar`
- `tar.bz2`
- `tar.gz`
- `tb2`
- `tbz`
- `tbz2`
- `zip`

サポートされている属性は以下のとおりです。

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `exclude_paths`     | 文字列            | いいえ       | アーカイブから除外するパスのカンマ区切りリスト。 |
| `include_lfs_blobs` | ブール値           | いいえ       | `true`の場合、LFSオブジェクトがアーカイブに含まれます。`false`に設定すると、LFSオブジェクトは除外されます。デフォルトは`true`です。 |
| `path`              | 文字列            | いいえ       | ダウンロードするリポジトリのサブパス。空の文字列の場合、デフォルトはリポジトリ全体です。 |
| `sha`               | 文字列            | いいえ       | ダウンロードするコミットSHA。タグ、ブランチ参照、またはSHAを受け入れます。指定しない場合、デフォルトはデフォルトブランチの先端です。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.com/api/v4/projects/<project_id>/repository/archive?sha=<commit_sha>&path=<path>&exclude_paths=<path1,path2>"
```

## ブランチ、タグ、またはコミットを比較する {#compare-branches-tags-or-commits}

{{< history >}}

- `collapsed`および`too_large`レスポンス属性はGitLab 18.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633)。

{{< /history >}}

リポジトリが公開されている場合、このエンドポイントは認証なしでアクセスできます。差分の制限に達すると、差分に空の差分文字列が含まれる可能性があります。

```plaintext
GET /projects/:id/repository/compare
```

サポートされている属性は以下のとおりです。

| 属性         | 型              | 必須 | 説明 |
|-------------------|-------------------|----------|-------------|
| `from`            | 文字列            | はい      | コミットSHAまたはブランチ名。 |
| `id`              | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `to`              | 文字列            | はい      | コミットSHAまたはブランチ名。 |
| `from_project_id` | 整数           | いいえ       | 比較元のID。 |
| `straight`        | ブール値           | いいえ       | `true`の場合、比較方法は`from`と`to`間の直接比較です（`from`..`to`）。`false`の場合、マージベースを使用して比較します（`from`...`to`）。デフォルトは`false`です。 |
| `unidiff`         | ブール値           | いいえ       | `true`の場合、[unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html)形式で差分を表示します。デフォルトは`false`です。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610)されました。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性                | 型         | 説明 |
|--------------------------|--------------|-------------|
| `commit`                 | オブジェクト       | 比較対象の最新コミットの詳細。 |
| `commits`                | オブジェクト配列 | 比較に含まれるコミットのリスト。 |
| `commits[].author_email` | 文字列       | コミット作成者のメールアドレス。 |
| `commits[].author_name`  | 文字列       | コミット作成者の名前。 |
| `commits[].created_at`   | 日時     | コミット作成タイムスタンプ。 |
| `commits[].id`           | 文字列       | 完全なコミットSHA。 |
| `commits[].short_id`     | 文字列       | 短いコミットSHA。 |
| `commits[].title`        | 文字列       | コミットタイトル。 |
| `compare_same_ref`       | ブール値      | `true`の場合、比較ではFromとToの両方に同じ参照を使用します。 |
| `compare_timeout`        | ブール値      | `true`の場合、比較操作がタイムアウトしました。 |
| `diffs`                  | オブジェクト配列 | ファイルの差分のリスト。 |
| `diffs[].a_mode`         | 文字列       | 古いファイルモード。 |
| `diffs[].b_mode`         | 文字列       | 新しいファイルモード。 |
| `diffs[].collapsed`      | ブール値      | `true`の場合、ファイルの差分は除外されますが、リクエストに応じてフェッチできます。 |
| `diffs[].deleted_file`   | ブール値      | `true`の場合、ファイルは削除されています。 |
| `diffs[].diff`           | 文字列       | ファイルに加えられた変更を示す差分コンテンツ。 |
| `diffs[].new_file`       | ブール値      | `true`の場合、ファイルが追加されています。 |
| `diffs[].new_path`       | 文字列       | ファイルの新しいパス。 |
| `diffs[].old_path`       | 文字列       | ファイルの古いパス。 |
| `diffs[].renamed_file`   | ブール値      | `true`の場合、ファイルの名前が変更されています。 |
| `diffs[].too_large`      | ブール値      | `true`の場合、ファイルの差分は除外され、取得できません。 |
| `web_url`                | 文字列       | 比較を表示するためのWeb URL。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/compare?from=main&to=feature"
```

レスポンス例:

```json
{
  "commit": {
    "id": "12d65c8dd2b2676fa3ac47d955accc085a37a9c1",
    "short_id": "12d65c8dd2b",
    "title": "JS fix",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "created_at": "2014-02-27T10:27:00+02:00"
  },
  "commits": [{
    "id": "12d65c8dd2b2676fa3ac47d955accc085a37a9c1",
    "short_id": "12d65c8dd2b",
    "title": "JS fix",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "created_at": "2014-02-27T10:27:00+02:00"
  }],
  "diffs": [{
    "old_path": "files/js/application.js",
    "new_path": "files/js/application.js",
    "a_mode": null,
    "b_mode": "100644",
    "diff": "@@ -24,8 +24,10 @@\n //= require g.raphael-min\n //= require g.bar-min\n //= require branch-graph\n-//= require highlightjs.min\n-//= require ace/ace\n //= require_tree .\n //= require d3\n //= require underscore\n+\n+function fix() { \n+  alert(\"Fixed\")\n+}",
    "collapsed": false,
    "too_large": false,
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }],
  "compare_timeout": false,
  "compare_same_ref": false,
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/compare/ae73cb07c9eeaf35924a10f713b364d32b2dd34f...0b4bc9a49b562e85de7cc9e834518ea6828729b9"
}
```

## コントリビューターリストを取得する {#get-contributor-list}

{{< history >}}

- `ref`はGitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156852)されました。

{{< /history >}}

リポジトリコントリビューターのリストを取得します。リポジトリが公開されている場合、このエンドポイントは認証なしでアクセスできます。

返されるコミット数にマージコミットは含まれません。

```plaintext
GET /projects/:id/repository/contributors
```

サポートされている属性は以下のとおりです。

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `order_by` | 文字列            | いいえ       | コントリビューターを`name`、`email`、または`commits`（コミット数）で並べ替えます。指定しない場合、コントリビューターはコミット日で並べ替えられます。 |
| `ref`      | 文字列            | いいえ       | リポジトリのブランチまたはタグの名前。指定しない場合は、デフォルトブランチです。 |
| `sort`     | 文字列            | いいえ       | `asc`または`desc`の順にソートされたコントリビューターを返します。デフォルトは`asc`です。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性   | 型    | 説明 |
|-------------|---------|-------------|
| `additions` | 整数 | コントリビューターによる行の追加数。 |
| `commits`   | 整数 | コントリビューターによるコミット数。 |
| `deletions` | 整数 | コントリビューターによる行の削除数。 |
| `email`     | 文字列  | コントリビューターのメールアドレス。 |
| `name`      | 文字列  | コントリビューターの名前。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/repository/contributors"
```

レスポンス例:

```json
[{
  "name": "Example User",
  "email": "example@example.com",
  "commits": 117,
  "additions": 0,
  "deletions": 0
}, {
  "name": "Sample User",
  "email": "sample@example.com",
  "commits": 33,
  "additions": 0,
  "deletions": 0
}]
```

## マージベースを取得する {#get-merge-base}

コミットSHA、ブランチ名、タグなど、2つ以上のrefsの共通の祖先を取得します。

```plaintext
GET /projects/:id/repository/merge_base
```

サポートされている属性は以下のとおりです。

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `refs`    | 配列             | はい      | 共通の祖先を見つけるためのrefs。複数のrefsを指定できます。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性           | 型     | 説明 |
|---------------------|----------|-------------|
| `author_email`      | 文字列   | 作成者のメールアドレス。 |
| `author_name`       | 文字列   | 作成者名。 |
| `authored_date`     | 日時 | コミットが作成済みの日付。 |
| `committed_date`    | 日時 | コミットがコミットされた日付。 |
| `committer_email`   | 文字列   | コミッターのメールアドレス。 |
| `committer_name`    | 文字列   | コミッターの名前。 |
| `created_at`        | 日時 | コミット作成タイムスタンプ。 |
| `extended_trailers` | オブジェクト   | Gitトレーラーに関する拡張情報。 |
| `id`                | 文字列   | 完全なコミットSHA。 |
| `message`           | 文字列   | 完全なコミットメッセージ。 |
| `parent_ids`        | 配列    | 親コミットSHAのリスト。 |
| `short_id`          | 文字列   | 短いコミットSHA。 |
| `title`             | 文字列   | コミットタイトル。 |
| `trailers`          | オブジェクト   | コミットメッセージから解析されたGitトレーラー。 |
| `web_url`           | 文字列   | GitLab Webインターフェースでコミットを表示するURL。 |

読みやすさのためにrefを省略したリクエスト例は以下のとおりです。

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/merge_base?refs[]=304d257d&refs[]=0031876f"
```

レスポンス例:

```json
{
  "id": "1a0b36b3cdad1d2ee32457c102a8c0b7056fa863",
  "short_id": "1a0b36b3",
  "title": "Initial commit",
  "created_at": "2014-02-27T08:03:18.000Z",
  "parent_ids": [],
  "message": "Initial commit\n",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "authored_date": "2014-02-27T08:03:18.000Z",
  "committer_name": "Example User",
  "committer_email": "user@example.com",
  "committed_date": "2014-02-27T08:03:18.000Z",
  "trailers": {},
  "extended_trailers": {},
  "web_url": "https://gitlab.example.com/example-group/example-project/-/commit/1a0b36b3cdad1d2ee32457c102a8c0b7056fa863"
}
```

## 変更履歴データを生成する {#generate-changelog-data}

{{< history >}}

- GitLab 17.7で、[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)による認証が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172842)されました。
- `config_file_ref`属性は、GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/426108)されました。

{{< /history >}}

リポジトリ内のコミットに基づいて変更履歴データを生成し、変更履歴データを変更履歴ファイルにコミットしません。

変更履歴データが変更履歴ファイルにコミットされないことを除き、`POST /projects/:id/repository/changelog`とまったく同様に機能します。

```plaintext
GET /projects/:id/repository/changelog
```

サポートされている属性は以下のとおりです。

| 属性         | 型     | 必須 | 説明 |
|-------------------|----------|----------|-------------|
| `version`         | 文字列   | はい      | 変更履歴を生成するバージョン。形式は、[セマンティックバージョニング](https://semver.org/)に従う必要があります。 |
| `config_file`     | 文字列   | いいえ       | プロジェクトのGitリポジトリ内の変更履歴設定ファイルのパス。デフォルトは`.gitlab/changelog_config.yml`です。 |
| `config_file_ref` | 文字列   | いいえ       | 変更履歴設定ファイルが定義されているGit参照（例：ブランチ）。デフォルトでは、リポジトリのブランチが使用されます。 |
| `date`            | 日時 | いいえ       | リリースの日時。ISO 8601形式を使用します。たとえば`2016-03-11T03:45:40Z`などです。デフォルトは現在の時刻です。 |
| `from`            | 文字列   | いいえ       | 変更履歴を生成する際に使用するコミット範囲の開始点（SHA）。このコミット自体は、リストには含まれません。 |
| `to`              | 文字列   | いいえ       | 変更履歴に使用するコミット範囲の終了点（SHA）。このコミットはリストに含まれます。デフォルトは、デフォルトのプロジェクトブランチのHEADです。 |
| `trailer`         | 文字列   | いいえ       | コミットを含めるために使用するGitトレーラー。デフォルトは`Changelog`です。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性 | 型   | 説明 |
|-----------|--------|-------------|
| `notes`   | 文字列 | Markdown形式で生成された変更履歴データ。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog?version=1.0.0"
```

読みやすくするために改行を追加した応答の例:

```json
{
  "notes": "## 1.0.0 (2021-11-17)\n\n### feature (2 changes)\n\n-
    [Title 2](namespace13/project13@ad608eb642124f5b3944ac0ac772fecaf570a6bf)
    ([merge request](namespace13/project13!2))\n-
    [Title 1](namespace13/project13@3c6b80ff7034fa0d585314e1571cc780596ce3c8)
    ([merge request](namespace13/project13!1))\n"
}
```

## ファイルに変更履歴データを追加 {#add-changelog-data-to-file}

{{< history >}}

- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/364101)になりました。機能フラグ`changelog_commits_limitation`は削除されました。
- `config_file_ref`は、GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/426108)されました。

{{< /history >}}

リポジトリ内のコミットに基づいて変更履歴データを生成し、変更履歴データを変更履歴ファイルにコミットしません。

[セマンティックバージョニング](https://semver.org/)とコミット範囲を指定すると、GitLabは特定の[Gitトレーラー](https://git-scm.com/docs/git-interpret-trailers)を使用するすべてのコミットの変更履歴を生成します。GitLabは、プロジェクトのGitリポジトリ内の変更履歴ファイルに、新しいMarkdown形式のセクションを追加します。出力形式はカスタマイズできます。

パフォーマンスとセキュリティ上の理由から、変更履歴の設定の解析中は秒に制限されています。この制限は、不正な形式の変更履歴テンプレートからの潜在的なDoS攻撃を防ぐのに役立ちます。リクエストがタイムアウトした場合は、`changelog_config.yml`ファイルのサイズを小さくすることを検討してください。

ユーザー向けドキュメントについては、[変更履歴](../user/project/changelogs.md)を参照してください。

```plaintext
POST /projects/:id/repository/changelog
```

変更履歴は、次の属性をサポートしています。

| 属性              | 型     | 必須 | 説明 |
|------------------------|----------|----------|-------------|
| `version` <sup>18.2</sup> | 文字列   | はい      | 変更履歴を生成するバージョン。形式は、[セマンティックバージョニング](https://semver.org/)に従う必要があります。 |
| `branch`               | 文字列   | いいえ       | 変更履歴の変更をコミットするブランチ。デフォルトは、プロジェクトのデフォルトブランチです。 |
| `config_file`          | 文字列   | いいえ       | プロジェクトのGitリポジトリ内の変更履歴設定ファイルのパス。デフォルトは`.gitlab/changelog_config.yml`です。 |
| `config_file_ref`      | 文字列   | いいえ       | 変更履歴設定ファイルが定義されているGit参照（例：ブランチ）。デフォルトでは、リポジトリのブランチが使用されます。 |
| `date`                 | 日時 | いいえ       | リリースの日時。デフォルトは現在の時刻です。 |
| `file`                 | 文字列   | いいえ       | 変更をコミットするファイル。デフォルトは`CHANGELOG.md`です。 |
| `from` <sup>2</sup>    | 文字列   | いいえ       | 変更履歴に含めるコミットの範囲の開始を示すコミットのSHA。このコミットは変更履歴には含まれません。 |
| `message`              | 文字列   | いいえ       | 変更をコミットするときに使用するコミットメッセージ。デフォルトは`Add changelog for version X`です。ここで、`X`は`version`引数の値です。 |
| `to`                   | 文字列   | いいえ       | 変更履歴に含めるコミットの範囲の終わりを示すコミットのSHA。このコミットは変更履歴に含まれます。デフォルトは、`branch`属性に指定されたブランチです。15,000コミットに制限されています。 |
| `trailer`              | 文字列   | いいえ       | コミットを含めるために使用するGitトレーラー。デフォルトは`Changelog`です。大文字と小文字を区別します。`Example`は`example`または`eXaMpLE`と一致しません。 |

**脚注**:

1. 属性`version`には、`v`プレフィックスを含めることも、省略することもできます。`1.0.0`と`v1.0.0`はどちらも同じ結果を生成します。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/437616)されました。

1. `from`が指定されていない場合、GitLabは、指定されたバージョンより前の最後の安定したバージョンのタグを自動的に検索します。GitLabは、セマンティックバージョニングに従って、`X.Y.Z`または`vX.Y.Z`形式のタグを認識します。

   たとえば、`version`が`2.1.0`の場合、GitLabはタグ`v2.0.0`を使用します。`version`が`1.1.1`または`1.2.0`の場合、GitLabはタグ`v1.1.0`を使用します。`v1.0.0-pre1`のようなプレリリースタグは無視されます。

   適切なタグが見つからない場合、APIはエラーを返し、`from`属性を明示的に指定する必要があります。

### 例 {#examples}

以下に示す例では、[cURL](https://curl.se/)を使用してHTTPリクエストを実行します。コマンドの例では次の値を使用します。

- プロジェクトID: 42
- ロケーション: GitLab.comでホスト
- APIトークンの例: `token`

次のコマンドは、バージョン`1.0.0`の変更履歴を生成します。

コミット範囲:

- 最後のリリースのタグから開始します。
- ターゲットブランチの最後のコミットで終了します。デフォルトのターゲットブランチは、プロジェクトのデフォルトブランチです。

最後のタグが`v0.9.0`で、デフォルトブランチが`main`の場合、この例に含まれるコミットの範囲は`v0.9.0..main`です。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

別のブランチのデータを生成するには、`branch`パラメータを指定します。次のコマンドは、`foo`ブランチからデータを生成します。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&branch=foo" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

別のトレーラーを使用するには、`trailer`パラメータを使用します。

```shell
curl --request POST --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&trailer=Type" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

結果を別のファイルに保存するには、`file`パラメータを使用します。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&file=NEWS" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

パラメータとしてブランチを指定するには、`to`属性を使用します。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog?version=1.0.0&to=release/x.x.x"
```

## 手動変更履歴ファイルからの移行 {#migrate-from-manual-changelog-files}

手動で管理される既存の変更履歴ファイルから、Gitトレーラーを使用する変更履歴ファイルに移行する場合は、変更履歴ファイルが[予期される形式](../user/project/changelogs.md)と一致していることを確認してください。そうしないと、APIによって追加される新しい変更履歴エントリが、予期しない位置に挿入される可能性があります。たとえば、手動で管理される変更履歴ファイルのバージョンの値が`X.Y.Z`ではなく`vX.Y.Z`として指定されている場合、Gitトレーラーを使用して追加される新しい変更履歴エントリは、変更履歴ファイルの末尾に付加されます。

[イシュー444183](https://gitlab.com/gitlab-org/gitlab/-/issues/444183)では、変更履歴ファイルのバージョンヘッダー形式をカスタマイズすることを提案しています。ただし、このイシューが完了するまで、変更履歴ファイルで予期されるバージョンヘッダー形式は`X.Y.Z`です。

## ヘルス {#health}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182220)されました。[`project_repositories_health`](https://gitlab.com/gitlab-org/gitlab/-/issues/521115)機能フラグの背後で保護されています。
- GitLab 18.1で新しいフィールドが[追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191263)。

{{< /history >}}

プロジェクトリポジトリのヘルスに関連する統計を取得します。このエンドポイントは、プロジェクトごとに1時間あたり5件のリクエストにレート制限されています。

```plaintext
GET /projects/:id/repository/health
```

サポートされている属性は以下のとおりです。

| 属性  | 型    | 必須 | 説明                                                                            |
|------------|---------|----------|----------------------------------------------------------------------------------------|
| `generate` | ブール値 | いいえ       | `true`の場合、新しいヘルスレポートを生成するかどうか。エンドポイントが`404`を返す場合に設定します。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)とリポジトリのヘルス統計が返されます。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/health"
```

レスポンス例:

```json
{
  "size": 2619748827,
  "references": {
    "loose_count": 13,
    "packed_size": 333978,
    "reference_backend": "REFERENCE_BACKEND_FILES"
  },
  "objects": {
    "size": 2180475409,
    "recent_size": 2180453999,
    "stale_size": 21410,
    "keep_size": 0,
    "packfile_count": 1,
    "reverse_index_count": 1,
    "cruft_count": 0,
    "keep_count": 0,
    "loose_objects_count": 36,
    "stale_loose_objects_count": 36,
    "loose_objects_garbage_count": 0
  },
  "commit_graph": {
    "commit_graph_chain_length": 1,
    "has_bloom_filters": true,
    "has_generation_data": true,
    "has_generation_data_overflow": false
  },
  "bitmap": null,
  "multi_pack_index": {
    "packfile_count": 1,
    "version": 1
  },
  "multi_pack_index_bitmap": {
    "has_hash_cache": true,
    "has_lookup_table": true,
    "version": 1
  },
  "alternates": null,
  "is_object_pool": false,
  "last_full_repack": {
    "seconds": 1745892013,
    "nanos": 0
  },
  "updated_at": "2025-05-14T02:31:08.022Z"
}
```

応答の各フィールドの説明については、[`RepositoryInfoResponse`](https://gitlab.com/gitlab-org/gitaly/blob/fcb986a6482f82b088488db3ed7ca35adfa42fdc/proto/repository.proto#L444) protobufメッセージを参照してください。

## 関連トピック {#related-topics}

- [変更履歴](../user/project/changelogs.md)のユーザー向けドキュメント
