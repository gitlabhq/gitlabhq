---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 完全一致コードの検索
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 15.9で`index_code_with_zoekt`および`search_code_with_zoekt`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049)されました。デフォルトでは無効になっています。
- GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/388519)になりました。
- 機能フラグ`index_code_with_zoekt`および`search_code_with_zoekt`は、GitLab 17.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378)されました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は[ベータ](../../policy/development_stages_support.md#beta)版であり、予告なく変更される場合があります。詳細については、[エピック9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)を参照してください。この機能に関するフィードバックを提供するには、[イシュー420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)にコメントを残してください。

{{< /alert >}}

完全一致コードの検索を使用すると、完全一致モードと正規表現モードを使用して、GitLab全体または特定のプロジェクト内のコードを検索できます。

完全一致コードの検索はZoektによって実現され、この機能が有効になっているグループではデフォルトで使用されます。

## 完全一致コードの検索を使用する {#use-exact-code-search}

前提要件: 

- 完全一致コードの検索を有効にする必要があります:
  - GitLab.comの場合、完全一致コードの検索は有料サブスクリプションで有効になります。
  - GitLab Self-Managedの場合、管理者は[Zoektをインストール](../../integration/zoekt/_index.md#install-zoekt)して、[完全一致コードの検索](../../integration/zoekt/_index.md#enable-exact-code-search)を有効にする必要があります。

完全一致コードの検索を使用するには:

1. 左側のサイドバーで、**検索または移動先**を選択します。
1. 検索ボックスに検索語句を入力します。
1. 左側のサイドバーで、**コード**を選択します。

プロジェクトまたはグループで完全一致コードの検索を使用することもできます。

## 使用可能なスコープ {#available-scopes}

スコープは、検索するデータの種類を表します。完全一致コードの検索では、次のスコープを使用できます:

| スコープ | グローバル<sup>1</sup><sup>2</sup>   | グループ                                       | プロジェクト |
|-------|:----------------------------------:|:-------------------------------------------:|:-------:|
| コード  | {{< icon name="dash-circle" >}}非対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 |

**Footnotes**（補足説明）:

1. 管理者は、[グローバル検索のスコープを無効にできます](_index.md#disable-global-search-scopes)。GitLab Self-Managedでは、管理者は`zoekt_cross_namespace_search`機能フラグを使用して、グローバル検索を有効にできます。
1. GitLab.comでは、グローバル検索は有効になっていません。

## Zoekt検索API {#zoekt-search-api}

{{< history >}}

- GitLab 16.9で`zoekt_search_api`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143666)されました。デフォルトでは有効になっています。
- GitLab 18.4で[一般提供](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17522)になりました。機能フラグ`zoekt_search_api`は削除されました。

{{< /history >}}

Zoekt検索APIを使用すると、検索APIを完全一致コードの検索に使用できます。代わりに[高度な検索](_index.md#specify-a-search-type)または基本的な検索を使用する場合は、検索タイプを指定するを参照してください。

## グローバルコード検索 {#global-code-search}

{{< history >}}

- GitLab 16.11で`zoekt_cross_namespace_search`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

この機能を使用すると、GitLabインスタンス全体のコードを検索できます。

グローバルコード検索は、大規模なGitLabインスタンスでは適切に機能しません。この機能が20,000を超えるプロジェクトを持つインスタンスで有効になっている場合、検索がタイムアウトする可能性があります。

## 検索モード {#search-modes}

{{< history >}}

- GitLab 16.8で`zoekt_exact_search`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/434417)されました。デフォルトでは無効になっています。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/436457)になりました。機能フラグ`zoekt_exact_search`は削除されました。

{{< /history >}}

GitLabには2つの検索モードがあります:

- **Exact match mode**（完全一致モード）: クエリに完全に一致する結果を返します。
- **Regular expression mode**（正規表現モード）: 正規表現とブール式をサポートします。

デフォルトでは、完全一致モードが使用されます。正規表現モードに切り替えるには、検索ボックスの右側にある**Use regular expression**（正規表現を使用）（{{< icon name="regular-expression" >}}）を選択します。

### 構文 {#syntax}

<!-- Remember to also update the table in `doc/drawers/exact_code_search_syntax.md` -->

次の表は、完全一致モードと正規表現モードのクエリの例を示しています。

| クエリ                | 完全一致モード                                        | 正規表現モード |
| -------------------- | ------------------------------------------------------- | ----------------------- |
| `"foo"`              | `"foo"`                                                 | `foo` |
| `foo file:^doc/`     | `/doc`で始まるディレクトリ内の`foo`             | `/doc`で始まるディレクトリ内の`foo` |
| `"class foo"`        | `"class foo"`                                           | `class foo` |
| `class foo`          | `class foo`                                             | `class`と`foo` |
| `foo or bar`         | `foo or bar`                                            | `foo`または`bar` |
| `class Foo`          | `class Foo`（大文字と小文字を区別）                            | `class`（大文字と小文字を区別しない）と`Foo`（大文字と小文字を区別する） |
| `class Foo case:yes` | `class Foo`（大文字と小文字を区別）                            | `class`と`Foo`（どちらも大文字と小文字を区別） |
| `foo -bar`           | `foo -bar`                                              | `foo`だが`bar`ではない |
| `foo file:js`        | `js`を含む名前のファイル内の`foo`             | `js`を含む名前のファイル内の`foo` |
| `foo -file:test`     | `test`を含まない名前のファイル内の`foo`    | `test`を含まない名前のファイル内の`foo` |
| `foo lang:ruby`      | Rubyのソースコード内の`foo`                               | Rubyのソースコード内の`foo` |
| `foo file:\.js$`     | `.js`で終わる名前のファイル内の`foo`           | `.js`で終わる名前のファイル内の`foo` |
| `foo.*bar`           | `foo.*bar`（リテラル）                                    | `foo.*bar`（正規表現） |
| `sym:foo`            | クラス、メソッド、変数名などのシンボル内の`foo` | クラス、メソッド、変数名などのシンボル内の`foo` |

## 既知の問題 {#known-issues}

- `20_000`トライグラム以下で1 MB未満のファイルのみが検索可能となっています。詳しくは、[イシュー455073](https://gitlab.com/gitlab-org/gitlab/-/issues/455073)をご覧ください。
- プロジェクトのデフォルトブランチのみで、完全一致コードの検索を使用できます。詳しくは、[イシュー403307](https://gitlab.com/gitlab-org/gitlab/-/issues/403307)をご覧ください。
- 1行に複数の一致がある場合、1つの結果としてカウントされます。
- 改行が正しく表示されない結果が発生した場合は、`gitlab-zoekt`をバージョン1.5.0以降に更新する必要があります。
