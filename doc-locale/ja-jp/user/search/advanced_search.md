---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 高度な検索
description: "高度な検索を使用して、GitLabインスタンス全体でコード、コミット、作業アイテム、マージリクエストを検索します。"
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

高度な検索を使用すると、GitLabインスタンス全体から必要なものを正確に見つけることができます。

高度な検索を使用すると次のことができます。

- すべてのプロジェクトにわたるコードパターンを特定して、共有コンポーネントをより効率的にリファクタリングすること。
- 組織全体のコードベースと依存関係にわたるセキュリティ脆弱性を特定します。
- すべてのリポジトリ全体で、非推奨の関数またはライブラリを追跡する。
- イシュー、マージリクエスト、コメントに埋もれているディスカッションを見つける。
- すでに存在する機能を一新する代わりに、既存のソリューションを見つける。

高度な検索は以下で機能します:

- コード
- コメント
- コミット
- 作業アイテム
- マージリクエスト
- マイルストーン
- プロジェクト
- ユーザー
- Wiki

## 高度な検索を使用する {#use-advanced-search}

前提条件: 

- 高度な検索を有効にする必要があります:
  - GitLab.comおよびGitLab Dedicatedの場合、有料のサブスクリプションでは高度な検索がデフォルトで有効になっています。
  - GitLab Self-Managedの場合、管理者が[高度な検索を有効にする](../../integration/advanced_search/elasticsearch.md#enable-advanced-search)必要があります。

高度な検索を使用するには:

1. 上部のバーで、**検索または移動先**を選択します。
1. 検索ボックスに検索語句を入力します。

プロジェクトまたはグループで高度な検索を使用することもできます。

## 使用可能なスコープ {#available-scopes}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/513146)されたイシューのコメント検索は、[フラグ](../../administration/feature_flags/_index.md) `search_work_item_queries_notes`という名前で提供されています。デフォルトでは無効になっています。
- GitLab 18.1で、イシューのコメント検索が[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/536912)。
- GitLab 18.6で、イシューのコメント検索が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191369)されました。機能フラグ`search_work_item_queries_notes`は削除されました。
- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/572590)されたマージリクエストのコメント検索は、[フラグ](../../administration/feature_flags/_index.md) `search_merge_request_queries_notes`という名前で提供されています。デフォルトでは無効になっています。
- GitLab 18.7で、マージリクエストのコメント検索が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/573750)されました。機能フラグ`search_merge_request_queries_notes`は削除されました。

{{< /history >}}

スコープは、検索するデータの種類を表します。高度な検索では、次のスコープを利用できます。

| スコープ                       | グローバル<sup>1</sup> <sup>2</sup> | グループ       | プロジェクト     |
|-----------------------------|----------------------------------|-------------|-------------|
| コード                        | {{< yes >}}                      | {{< yes >}} | {{< yes >}} |
| コメント                    | {{< yes >}}                      | {{< yes >}} | {{< yes >}} |
| コミット                     | {{< yes >}}                      | {{< yes >}} | {{< yes >}} |
| 作業アイテム<sup>3</sup>     | {{< yes >}}                      | {{< yes >}} | {{< yes >}} |
| マージリクエスト<sup>3</sup> | {{< yes >}}                      | {{< yes >}} | {{< yes >}} |
| マイルストーン<sup>4</sup>     | {{< yes >}}                      | {{< yes >}} | {{< yes >}} |
| プロジェクト                    | {{< yes >}}                      | {{< yes >}} | {{< no >}}  |
| ユーザー                       | {{< yes >}}                      | {{< yes >}} | {{< yes >}} |
| Wiki                       | {{< yes >}}                      | {{< yes >}} | {{< yes >}} |

**脚注**: 

1. 管理者は、[グローバル検索のスコープを無効にできます](_index.md#disable-global-search-scopes)。GitLab Self-Managedでは、制限付きインデックス作成がデフォルトで有効になっている場合、グローバル検索は使用できません。管理者は、[グローバル検索で制限付きインデックス作成を有効にできます](../../integration/advanced_search/elasticsearch.md#indexed-namespaces)。
1. GitLab.comでは、コード、コミット、Wikiに対してグローバル検索は有効になっていません。
1. 作業アイテムとマージリクエストを検索すると、検索語に一致するコメントが結果に含まれます。
1. 高度な検索では、グループのマイルストーンがElasticsearchにインデックスされないため、プロジェクトのマイルストーンのみが返されます。詳細については、[イシュー428589](https://gitlab.com/gitlab-org/gitlab/-/issues/428589)を参照してください。

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

| クエリ                                 | 説明 |
|---------------------------------------|-------------|
| `rails -filename:gemfile.lock`        | `gemfile.lock`ファイルを除くすべてのファイルの`rails`を返します。 |
| `RSpec.describe Resolvers -*builder`  | `builder`で始まらない`RSpec.describe Resolvers`を返します。 |
| `bug \| (display +banner)`            | `bug`または、`display`と`banner`の両方を返します。 |
| `helper -extension:yml -extension:js` | `.yml`拡張子または`.js`拡張子のファイルを除く、すべてのファイルの`helper`を返します。 |
| `helper path:lib/git`                 | パスに`lib/git*`の付くすべてのファイル（`spec/lib/gitlab`など）の`helper`を返します。 |

## 既知の問題 {#known-issues}

- 1 MB未満のファイルのみ検索できます。GitLab Self-Managedの場合、管理者は[インデックス](../../administration/instance_limits.md#maximum-file-size-indexed)される最大ファイルサイズに制限を設定できます。
- プロジェクトのデフォルトブランチのみで高度な検索を使用できます。詳細については、[イシュー229966](https://gitlab.com/gitlab-org/gitlab/-/issues/229966)を参照してください。
- 検索クエリに、次のいずれの文字も使用しないでください。

  ```plaintext
  . , : ; / ` ' = ? $ & ^ | < > ( ) { } [ ] @
  ```

- 検索結果には、ファイル内で最初に一致した結果のみが表示されます。

## 関連トピック {#related-topics}

- [セキュリティの脆弱性を特定](../application_security/vulnerability_report/_index.md#advanced-vulnerability-management)
