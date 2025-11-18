---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 高度な検索
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

高度な検索を使用すると、GitLabインスタンス全体から必要なものを正確に見つけることができます。

高度な検索を使用すると次のことができます:

- すべてのプロジェクトにわたるコードパターンを特定して、共有コンポーネントをより効率的にリファクタリングすること。
- 組織全体のコードベースと依存関係にあるセキュリティの脆弱性を一度に特定します。
- すべてのリポジトリ全体で、非推奨の関数またはライブラリを追跡する。
- イシュー、マージリクエスト、コメントに埋もれているディスカッションを見つける。
- すでに存在する機能を一新する代わりに、既存のソリューションを見つける。

高度な検索は、プロジェクト、イシュー、マージリクエスト、マイルストーン、ユーザー、エピック、コード、コメント、コミット、Wikiで機能します。

## 高度な検索を使用するには {#use-advanced-search}

前提要件: 

- 高度な検索を有効にする必要があります:
  - GitLab.comとGitLab Dedicatedの場合、高度な検索は有料サブスクリプションでデフォルトで有効になっています。
  - [GitLab Self-Managed](../../integration/advanced_search/elasticsearch.md#enable-advanced-search)の場合、管理者は高度な検索を有効にする必要があります。

高度な検索を使用するには:

1. 左側のサイドバーで、**検索または移動先**を選択します。
1. 検索ボックスに検索語句を入力します。

プロジェクトまたはグループで高度な検索を使用することもできます。

## 使用可能なスコープ {#available-scopes}

スコープは、検索するデータの種類を示します。高度な検索では、次のスコープを利用できます:

| スコープ          | グローバル<sup>1</sup><sup>2</sup>            | グループ                                       | プロジェクト |
|----------------|:-------------------------------------------:|:-------------------------------------------:|:-------:|
| コード           | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| コメント       | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| コミット        | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| エピック          | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応 |
| イシュー         | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| マージリクエスト | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| マイルストーン     | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| プロジェクト       | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応 |
| ユーザー          | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |
| Wiki          | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |

**Footnotes**（補足説明）:

1. 管理者は、[グローバル検索のスコープを無効にできます](_index.md#disable-global-search-scopes)。GitLab Self-Managedでは、制限付きインデックス作成がデフォルトで有効になっている場合、グローバル検索は使用できません。管理者は、[グローバル検索で制限付きインデックス作成を有効にできます](../../integration/advanced_search/elasticsearch.md#indexed-namespaces)。
1. GitLab.comでは、コード、コミット、およびWikiに対してグローバル検索は有効になっていません。

## 構文 {#syntax}

<!-- Remember to also update the tables in `doc/drawers/advanced_search_syntax.md` -->

高度な検索では、[`simple_query_string`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html)を使用します。これは、完全一致クエリとあいまい一致クエリの両方をサポートします。

ユーザーを検索すると、デフォルトで[`fuzzy`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-fuzzy-query.html)クエリが使用されます。`simple_query_string`を使用して、ユーザーの検索を絞り込むことができます。

| 構文 | 説明      | 例 |
|--------|------------------|---------|
| `"`    | 完全一致検索     | `"gem sidekiq"` |
| `~`    | あいまい検索     | `J~ Doe` |
| `\|`   | または               | `display \| banner` |
| `+`    | および              | `display +banner` |
| `-`    | 除外          | `display -banner` |
| `*`    | 部分          | `bug error 50*` |
| ` \ `  | エスケープ           | `\*md`  |
| `#`    | イシューID         | `#23456` |
| `!`    | マージリクエストID | `!23456` |

### コード検索 {#code-search}

| 構文       | 説明                                     | 例 |
|--------------|-------------------------------------------------|---------|
| `filename:`  | ファイル名                                        | `filename:*spec.rb` |
| `path:`      | リポジトリの場所（完全一致または部分一致）   | `path:spec/workers/` |
| `extension:` | `.`なしのファイル拡張子（完全一致のみ） | `extension:js` |
| `blob:`      | GitオブジェクトID（完全一致のみ）              | `blob:998707*` |

### 例 {#examples}

<!-- markdownlint-disable MD044 -->

| クエリ                                 | 説明 |
|---------------------------------------|-------------|
| `rails -filename:gemfile.lock`        | `gemfile.lock`ファイルを除くすべてのファイルの`rails`を返します。 |
| `RSpec.describe Resolvers -*builder`  | `builder`で始まらない`RSpec.describe Resolvers`を返します。 |
| `bug \| (display +banner)`            | `bug`または、`display`と`banner`の両方を返します。 |
| `helper -extension:yml -extension:js` | `.yml`拡張子または`.js`拡張子のファイルを除く、すべてのファイルの`helper`を返します。 |
| `helper path:lib/git`                 | パスに`lib/git*`の付くすべてのファイル（`spec/lib/gitlab`など）の`helper`を返します。 |

<!-- markdownlint-enable MD044 -->

## 既知の問題 {#known-issues}

- 1 MB未満のファイルのみ検索できます。GitLab Self-Managedの場合、管理者は[インデックスが作成されるファイルの最大サイズ](../../administration/instance_limits.md#maximum-file-size-indexed)を設定できます。
- プロジェクトのデフォルトブランチのみで高度な検索を使用できます。詳細については、[イシュー229966](https://gitlab.com/gitlab-org/gitlab/-/issues/229966)を参照してください。
- 検索クエリに、次のいずれの文字も使用しないでください:

  ```plaintext
  . , : ; / ` ' = ? $ & ^ | < > ( ) { } [ ] @
  ```

- 検索結果には、ファイル内で最初に一致した結果のみが表示されます。
