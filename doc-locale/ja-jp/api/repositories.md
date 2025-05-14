---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for Git repositories in GitLab.
title: リポジトリAPI
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## リポジトリツリーをリストする

プロジェクト内のリポジトリファイルとディレクトリのリストを取得します。リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

このコマンドは、基本的に`git ls-tree`コマンドと同じ機能を提供します。詳細については、Gitの内部ドキュメントの[ツリーオブジェクト](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html#_tree_objects)のセクションを参照してください。

{{< alert type="warning" >}}

GitLab 15.0でこのエンドポイントが[キーセットベースのページネーション](rest/_index.md#keyset-based-pagination)に変更されました。数値（`?page=2`）を使用した結果ページのイテレーションはサポートされていません。

{{< /alert >}}

{{< alert type="warning" >}}

バージョン17.7で、リクエストされたパスが見つからない場合のエラー処理動作が更新されました。エンドポイントはステータスコード`404 Not Found`を返すようになりました。以前のステータスコードは`200 OK`でした。

ご使用の実装が、パスが欠落している場合に`200`ステータスコードと空の配列を受信することに依存している場合は、新しい`404`応答を処理するようにエラー処理を更新する必要があります。

{{< /alert >}}

```plaintext
GET /projects/:id/repository/tree
```

サポートされている属性:

| 属性   | 型           | 必須 | 説明 |
| :---------- | :------------- | :------- | :---------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `page_token` | 文字列        | いいえ       | 次のページをフェッチするツリーレコードID。キーセットページネーションでのみ使用されます。 |
| `pagination` | 文字列        | いいえ       | `keyset`の場合、[キーセットベースのページネーション方式](rest/_index.md#keyset-based-pagination)を使用します。 |
| `path`      | 文字列         | いいえ       | リポジトリ内のパス。サブディレクトリの内容を取得するために使用されます。 |
| `per_page`  | 整数        | いいえ       | ページあたりの表示結果数。指定しない場合、デフォルトは`20`です。詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。 |
| `recursive` | ブール値        | いいえ       | 再帰的なツリーを取得するために使用されるブール値。デフォルトは`false`です。 |
| `ref`       | 文字列         | いいえ       | リポジトリのブランチまたはタグの名前。指定されていない場合はデフォルトのブランチの名前です。 |

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

## リポジトリからblobを取得する

サイズや内容など、リポジトリ内のblobに関する情報を受け取ることができるようにしますblobコンテンツはBase64エンコードされています。リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

```plaintext
GET /projects/:id/repository/blobs/:sha
```

サポートされている属性:

| 属性 | 型           | 必須 | 説明 |
| :-------- | :------------- | :------- | :---------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `sha`     | 文字列         | はい      | blob SHA。 |

## raw blobコンテンツ

blob SHAを指定して、blobのrawファイルのコンテンツを取得します。リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

```plaintext
GET /projects/:id/repository/blobs/:sha/raw
```

サポートされている属性:

| 属性 | 型     | 必須 | 説明 |
| :-------- | :------- | :------- | :---------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `sha`     | 文字列 | はい      | blob SHA。 |

## ファイルアーカイブを取得する

リポジトリのアーカイブを取得します。リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

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

サポートされている属性:

| 属性   | 型           | 必須 | 説明           |
|:------------|:---------------|:---------|:----------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `path`      | 文字列         | いいえ       | ダウンロードするリポジトリのサブパス。空の文字列の場合、デフォルトはリポジトリ全体です。  |
| `sha`       | 文字列         | いいえ       | ダウンロードするコミットSHA。タグ、ブランチ参照、またはSHAを使用できます。指定しない場合、デフォルトはデフォルトブランチの先端です。 |
| `include_lfs_blobs` | ブール値 | いいえ | LFSオブジェクトをアーカイブに含めるかどうかを決定します。デフォルトは`true`です。`false`に設定すると、LFSオブジェクトは除外されます。 |
| `exclude_paths` | 配列 | いいえ | アーカイブから除外するパスのリスト。 |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.com/api/v4/projects/<project_id>/repository/archive?sha=<commit_sha>&path=<path>&exclude_paths=<path1,path2>"
```

## ブランチ、タグ、コミットを比較する

リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。[差分の制限](../development/merge_request_concepts/diffs/_index.md#diff-limits)に達すると、差分に空の差分文字列が含まれる可能性があります。

```plaintext
GET /projects/:id/repository/compare
```

サポートされている属性:

| 属性         | 型           | 必須 | 説明 |
| :---------        | :------------- | :------- | :---------- |
| `id`              | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `from`            | 文字列         | はい      | コミットSHAまたはブランチ名。 |
| `to`              | 文字列         | はい      | コミットSHAまたはブランチ名。 |
| `from_project_id` | 整数        | いいえ       | 比較元のID。 |
| `straight`        | ブール値        | いいえ       | 比較方法:: `from`と`to`（`from`..`to`）の間の直接比較の場合は`true`、マージベース（`from`...`to`）を使用して比較する場合は`false`です。デフォルトは`false`です。 |
| `unidiff`           | ブール値 | いいえ       | [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html)形式で差分を表示します。デフォルトはfalseです。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610)されました。     |

```plaintext
GET /projects/:id/repository/compare?from=main&to=feature
```

応答の例:

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
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }],
  "compare_timeout": false,
  "compare_same_ref": false,
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/compare/ae73cb07c9eeaf35924a10f713b364d32b2dd34f...0b4bc9a49b562e85de7cc9e834518ea6828729b9"
}
```

## コントリビューター

{{< history >}}

- `ref`はGitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156852)されました。

{{< /history >}}

リポジトリコントリビューターのリストを取得します。リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

返されるコミット数にマージコミットは含まれません。

```plaintext
GET /projects/:id/repository/contributors
```

サポートされている属性:

| 属性  | 型           | 必須 | 説明 |
| :--------- | :------------- | :------- | :---------- |
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `ref`      | 文字列         | いいえ       | リポジトリのブランチまたはタグの名前。指定しない場合は、デフォルトブランチです。 |
| `order_by` | 文字列         | いいえ       | `name`、`email`、または`commits`（コミット日で並べ替え）フィールドで並べ替えられたコントリビューターを返します。デフォルトは`commits`です。 |
| `sort`     | 文字列         | いいえ       | `asc`または`desc`の順にソートされたコントリビューターを返します。デフォルトは`asc`です。 |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/repository/contributors"
```

応答の例:

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

## マージベース

コミットSHA、ブランチ名、タグなど、2つ以上のrefの共通の祖先を取得します。

```plaintext
GET /projects/:id/repository/merge_base
```

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ---------------------------------------------------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `refs`    | 配列          | はい      | 共通の祖先を見つけるためのref。複数のrefを指定できます。                    |

読みやすくするためにrefが切り詰められたリクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/merge_base?refs[]=304d257d&refs[]=0031876f"
```

応答の例:

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
  "committed_date": "2014-02-27T08:03:18.000Z"
}
```

## 変更履歴データを変更履歴ファイルに追加する

{{< history >}}

- コミット範囲の制限は、GitLab 15.1で`changelog_commits_limitation`[フラグを使用して](../administration/feature_flags.md)[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89032)されました。デフォルトでは無効になっています。
- GitLab 15.3の[GitLab.comで有効であり、GitLab Self-Managedではデフォルトで有効です](https://gitlab.com/gitlab-org/gitlab/-/issues/33893)。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/364101)になりました。機能フラグ`changelog_commits_limitation`が削除されました。

{{< /history >}}

リポジトリ内のコミットに基づいて変更履歴データを生成します。

[セマンティックバージョン](https://semver.org/)とコミット範囲を指定すると、GitLabは特定の[Gitトレーラー](https://git-scm.com/docs/git-interpret-trailers)を使用するすべてのコミットの変更履歴を生成します。GitLabは、プロジェクトのGitリポジトリ内の変更履歴ファイルに、新しいMarkdown形式のセクションを追加します。出力形式はカスタマイズできます。

パフォーマンスとセキュリティ上の理由から、変更履歴の設定の解析は`2`秒に制限されています。この制限は、不正な形式の変更履歴テンプレートからの潜在的なDoS攻撃を防ぐのに役立ちます。リクエストがタイムアウトした場合は、`changelog_config.yml`ファイルのサイズを小さくすることを検討してください。

ユーザー向けドキュメントについては、[変更履歴](../user/project/changelogs.md)を参照してください。

```plaintext
POST /projects/:id/repository/changelog
```

### サポートされている属性

変更履歴では次の属性がサポートされています。

| 属性 | 型     | 必須   | 説明 |
| :-------- | :------- | :--------- | :---------- |
| `version` | 文字列   | はい | 変更履歴を生成するバージョン。形式は、[セマンティックバージョニング](https://semver.org/)に従っている必要があります。 |
| `branch`  | 文字列   | いいえ | 変更履歴の変更をコミットするブランチ。デフォルトは、プロジェクトのデフォルトブランチです。 |
| `config_file` | 文字列   | いいえ | プロジェクトのGitリポジトリ内の変更履歴設定ファイルのパス。デフォルトは`.gitlab/changelog_config.yml`です。 |
| `date`    | 日時 | いいえ | リリースの日時。デフォルトは現在の時刻です。 |
| `file`    | 文字列   | いいえ | 変更をコミットするファイル。デフォルトは`CHANGELOG.md`です。 |
| `from`    | 文字列   | いいえ | 変更履歴に含めるコミットの範囲の開始を示すコミットのSHA。このコミットは変更履歴には含まれません。 |
| `message` | 文字列   | いいえ | 変更をコミットするときに使用するコミットメッセージ。デフォルトは`Add changelog for version X`です。ここで、`X`は`version`引数の値です。 |
| `to`      | 文字列   | いいえ | 変更履歴に含めるコミットの範囲の終わりを示すコミットのSHA。このコミットは変更履歴に_含まれます_。デフォルトは、`branch`属性に指定されたブランチです。15000コミットに制限されています。 |
| `trailer` | 文字列   | いいえ | コミットを含めるために使用するGitトレーラー。デフォルトは`Changelog`です。大文字と小文字を区別します。`Example`は`example`または`eXaMpLE`と一致しません。 |

### `from`属性の要件

`from`属性が指定されていない場合、GitLabは`version`属性で指定されているバージョンより前の最新の安定版バージョンのGitタグを使用します。GitLabがタグ名からバージョン番号を抽出できるようにするには、Gitタグ名が特定の形式に従っている必要があります。デフォルトでは、GitLabは次の形式を使用するタグを考慮します。

- `vX.Y.Z`
- `X.Y.Z`

ここで、`X.Y.Z`は[セマンティックバージョニング](https://semver.org/)に従うバージョンです。たとえば、次のタグが付いているプロジェクトがあるとします。

- `v1.0.0-pre1`
- `v1.0.0`
- `v1.1.0`
- `v2.0.0`

`version`属性が`2.1.0`の場合、GitLabはタグ`v2.0.0`を使用します。バージョンが`1.1.1`または`1.2.0`の場合、GitLabはタグ`v1.1.0`を使用します。プレリリースタグは無視されるため、タグ`v1.0.0-pre1`が使用されることはありません。

`version`属性は`v`で始めることができます。たとえば`v1.0.0`などです。応答は、`version`の値が`1.0.0`の場合と同じです。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/437616)されました。

`from`が指定されておらず、使用するタグが見つからない場合、APIはエラーを生成します。このようなエラーを解決するには、`from`属性の値を明示的に指定する必要があります。

### 手動で管理される変更履歴ファイルからGitトレーラーへ移行する

手動で管理される既存の変更履歴ファイルから、Gitトレーラーを使用する変更履歴ファイルに移行する場合は、変更履歴ファイルが[予期される形式](../user/project/changelogs.md)と一致していることを確認してください。そうしないと、APIによって追加される新しい変更履歴エントリが、予期しない位置に挿入される可能性があります。たとえば、手動で管理される変更履歴ファイルのバージョンの値が`X.Y.Z`ではなく`vX.Y.Z`として指定されている場合、Gitトレーラーを使用して追加される新しい変更履歴エントリは、変更履歴ファイルの末尾に付加されます。

[イシュー444183](https://gitlab.com/gitlab-org/gitlab/-/issues/444183)では、変更履歴ファイルのバージョンヘッダー形式をカスタマイズすることを提案しています。ただし、このイシューが完了するまで、変更履歴ファイルで予期されるバージョンヘッダー形式は`X.Y.Z`です。

### 例

以下に示す例では、[cURL](https://curl.se/)を使用してHTTPリクエストを実行します。コマンドの例では次の値を使用します。

- **プロジェクトID**:42
- **場所**: GitLab.com でホスト
- **API トークンの例**: `token`

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

別のブランチのデータを生成するには、`branch`パラメーターを指定します。次のコマンドは、`foo`ブランチからデータを生成します。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&branch=foo" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

別のトレーラーを使用するには、`trailer`パラメーターを使用します。

```shell
curl --request POST --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&trailer=Type" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

結果を別のファイルに保存するには、`file`パラメーターを使用します。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&file=NEWS" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

パラメーターとしてブランチを指定するには、`to`属性を使用します。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog?version=1.0.0&to=release/x.x.x"
```

## 変更履歴データを生成する

{{< history >}}

- GitLab 17.7で、[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)による認証が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172842)されました。

{{< /history >}}

リポジトリ内のコミットに基づいて変更履歴データを生成し、変更履歴データを変更履歴ファイルにコミットしません。

変更履歴データが変更履歴ファイルにコミットされないことを除き、`POST /projects/:id/repository/changelog`とまったく同様に機能します。

```plaintext
GET /projects/:id/repository/changelog
```

サポートされている属性:

| 属性 | 型     | 必須   | 説明 |
| :-------- | :------- | :--------- | :---------- |
| `version` | 文字列   | はい | 変更履歴を生成するバージョン。形式は、[セマンティックバージョニング](https://semver.org/)に従っている必要があります。 |
| `config_file` | 文字列   | いいえ | プロジェクトのGitリポジトリ内の変更履歴設定ファイルのパス。デフォルトは`.gitlab/changelog_config.yml`です。 |
| `date`    | 日時 | いいえ | リリースの日時。ISO 8601形式を使用します。たとえば`2016-03-11T03:45:40Z`などです。デフォルトは現在の時刻です。 |
| `from`    | 文字列   | いいえ | 変更履歴の生成に使用するコミット範囲の開始（SHAとして）。このコミット自体は、リストには含まれません。 |
| `to`      | 文字列   | いいえ | 変更履歴に使用するコミット範囲の終了（SHAとして）。このコミットはリストに_含まれます_。デフォルトは、デフォルトのプロジェクトブランチのHEADです。 |
| `trailer` | 文字列   | いいえ | コミットを含めるために使用するGitトレーラー。デフォルトは`Changelog`です。 |

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

## ヘルス

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182220)されました。[project_repositories_health](https://gitlab.com/gitlab-org/gitlab/-/issues/521115)機能フラグで保護されています。

{{< /history >}}

プロジェクトリポジトリのヘルスに関連する統計を取得します。このエンドポイントは、プロジェクトごとに1時間あたり5件のリクエストにレート制限されています。

```plaintext
GET /projects/:id/repository/health
```

サポートされている属性:

| 属性  | 型    | 必須 | 説明                                                                            |
|:-----------|:--------|:---------|:---------------------------------------------------------------------------------------|
| `generate` | ブール値 | いいえ       | 新しいヘルスレポートを生成するかどうか。エンドポイントが404を返す場合に設定します。 |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/health"
```

応答の例:

```json
{
  "size": 42002816,
  "references": {
    "loose_count": 3,
    "packed_size": 315703,
    "reference_backend": "REFERENCE_BACKEND_FILES"
  },
  "objects": {
    "size": 39651458,
    "recent_size": 39461265,
    "stale_size": 190193,
    "keep_size": 0
  },
  "updated_at": "2025-02-26T03:42:13.015Z"
}
```

## 関連トピック

- [変更履歴](../user/project/changelogs.md)のユーザー向けドキュメント
- GitLabの[変更履歴エントリ](../development/changelog.md)に関するデベロッパー向けドキュメント
