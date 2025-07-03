---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 高度な検索
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

高度な検索を使用すると、GitLabインスタンス全体から必要なものを正確に見つけることができます。

高度な検索を使用すると次のことができます。

- すべてのプロジェクトにわたるコードパターンを特定して、共有コンポーネントをより効率的にリファクタコードすること。
- 組織全体の依存関係にあるセキュリティの脆弱性を一度に特定すること。
- すべてのリポジトリ全体で、非推奨の関数またはライブラリの使用状況を追跡すること。
- イシュー、マージリクエスト、コメントに埋もれているディスカッションを見つること。
- すでに存在する機能を一新する代わりに、既存のソリューションを見つけること。

高度な検索は、プロジェクト、イシュー、マージリクエスト、マイルストーン、ユーザー、エピック、コード、コメント、コミット、Wikiで機能します。

## 高度な検索を有効にする

- [GitLab.com](../../subscriptions/gitlab_com/_index.md)と[GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md)の場合、高度な検索は有料サブスクリプションで有効になっています。
- [GitLab Self-Managed](../../subscriptions/self_managed/_index.md)の場合、[管理者](../../integration/advanced_search/elasticsearch.md#enable-advanced-search)が高度な検索を有効にする必要があります。

## 構文

<!-- Remember to also update the tables in `doc/drawers/advanced_search_syntax.md` -->

{{< history >}}

- ユーザーの絞り込み検索はGitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/388409)されました。

{{< /history >}}

高度な検索では、[`simple_query_string`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html)を使用します。これは、完全一致クエリとあいまい一致クエリの両方をサポートします。

ユーザーを検索すると、デフォルトで[`fuzzy`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-fuzzy-query.html)クエリが使用されます。`simple_query_string`を使用して、ユーザーの検索を絞り込むことができます。

| 構文              | 説明      | 例 |
|---------------------|------------------|---------|
| `"`                 | 完全一致検索     | [`"gem sidekiq"`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=%22gem+sidekiq%22) |
| `~`                 | あいまい検索     | [`J~ Doe`](https://gitlab.com/search?scope=users&search=j%7E+doe) |
| `\|` | または               | [`display \| banner`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=display+%7C+banner) |
| `+`                 | および              | [`display +banner`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=display+%2Bbanner&snippets=) |
| `-`                 | 除外          | [`display -banner`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=display+-banner) |
| `*`                 | 部分的          | [`bug error 50*`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=bug+error+50%2A&snippets=) |
| <code>\\</code>  | エスケープ           | [`\*md`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=%5C*md&group_id=9970&project_id=278964) |
| `#`                 | イシューID         | [`#23456`](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=%2323456&group_id=9970&project_id=278964) |
| `!`                 | マージリクエストID | [`!23456`](https://gitlab.com/search?snippets=&scope=merge_requests&repository_ref=&search=%2123456&group_id=9970&project_id=278964) |

### コード検索

| 構文       | 説明                                     | 例 |
|--------------|-------------------------------------------------|---------|
| `filename:`  | ファイル名                                        | [`filename:*spec.rb`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=filename%3A*spec.rb&group_id=9970&project_id=278964) |
| `path:`      | リポジトリの場所（完全一致または部分一致）   | [`path:spec/workers/`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=path%3Aspec%2Fworkers&snippets=) |
| `extension:` | `.`なしのファイル拡張子（完全一致のみ） | [`extension:js`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=extension%3Ajs&snippets=) |
| `blob:`      | GitオブジェクトID（完全一致のみ）              | [`blob:998707*`](https://gitlab.com/search?snippets=false&scope=blobs&repository_ref=&search=blob%3A998707*&group_id=9970) |

### 例

<!-- markdownlint-disable MD044 -->

| クエリ                                              | 説明 |
|----------------------------------------------------|-------------|
| [`rails -filename:gemfile.lock`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=rails+-filename%3Agemfile.lock&snippets=) | `gemfile.lock`ファイルを除くすべてのファイルの`rails`を返します。 |
| [`RSpec.describe Resolvers -*builder`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=RSpec.describe+Resolvers+-*builder) | `builder`で始まらない`RSpec.describe Resolvers`を返します。 |
| [`bug \| (display +banner)`](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=bug+%7C+%28display+%2Bbanner%29&group_id=9970&project_id=278964) | `bug`または、`display`と`banner`の両方を返します。 |
| [`helper -extension:yml -extension:js`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=helper+-extension%3Ayml+-extension%3Ajs&snippets=) | `.yml`拡張子または`.js`拡張子のファイルを除く、すべてのファイルの`helper`を返します。 |
| [`helper path:lib/git`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=helper+path%3Alib%2Fgit) | パスに`lib/git*`の付くすべてのファイル（`spec/lib/gitlab`など）の`helper`を返します。 |

<!-- markdownlint-enable MD044 -->

## 既知の問題

- 1 MB未満のファイルのみ検索できます。詳細については、[イシュー195764](https://gitlab.com/gitlab-org/gitlab/-/issues/195764)を参照してください。GitLab Self-Managedの場合、管理者は[**インデックスが作成されたファイルの最大サイズ**を設定できます](../../integration/advanced_search/elasticsearch.md#advanced-search-configuration)。
- プロジェクトのデフォルトブランチでのみ高度な検索を使用できます。詳細については、[イシュー229966](https://gitlab.com/gitlab-org/gitlab/-/issues/229966)を参照してください。
- 検索クエリに、次のいずれの文字も使用しないでください。

  ```plaintext
  . , : ; / ` ' = ? $ & ^ | < > ( ) { } [ ] @
  ```

  詳細については、[イシュー325234](https://gitlab.com/gitlab-org/gitlab/-/issues/325234)を参照してください。
- 検索結果には、ファイル内で最初に一致した結果のみが表示されます。詳細については、[イシュー668](https://gitlab.com/gitlab-org/gitlab/-/issues/668)を参照してください。
