---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "特定のプロジェクトまたはGitLab全体でコードを検索するために、完全一致コードの検索を使用できます。"
title: 完全一致コードの検索
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 利用制限

{{< /details >}}

{{< history >}}

- GitLab 15.9で`index_code_with_zoekt`および`search_code_with_zoekt`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049)されました。デフォルトでは無効になっています。
- [GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/388519)にGitLab 16.6でなりました。
- グローバルコード検索はGitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077)され、[フラグ](../../administration/feature_flags/_index.md)は`zoekt_cross_namespace_search`と名付けられました。デフォルトでは無効になっています。
- 機能フラグ`index_code_with_zoekt`および`search_code_with_zoekt`は、GitLab 17.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378)されました。
- GitLab 18.6でベータ版から限定提供に[変更](https://gitlab.com/groups/gitlab-org/-/epics/17918)されました。
- GitLab 18.7で機能フラグ`zoekt_cross_namespace_search`が[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213413)されました。

{{< /history >}}

> [!warning]
> この機能は[限定提供](../../policy/development_stages_support.md#limited-availability)です。詳細については、[エピック9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)を参照してください。[イシュー420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)でフィードバックを提供してください。

完全一致コードの検索を使用すると、完全一致モードと正規表現モードを使用して、GitLab全体または特定のプロジェクト内のコードを検索できます。

完全一致コードの検索はZoektによって提供され、機能が有効になっているグループではデフォルトで使用されます。

## 完全一致コードの検索を使用 {#use-exact-code-search}

前提条件: 

- 完全一致コードの検索を有効にする必要があります:
  - GitLab.comの場合、完全一致コードの検索は有料サブスクリプションでデフォルトで有効になっています。
  - GitLab Self-Managedの場合、管理者はZoektを[インストール](../../integration/zoekt/_index.md#install-zoekt)し、[完全一致コードの検索](../../integration/zoekt/_index.md#enable-exact-code-search)を有効にする必要があります。

完全一致コードの検索を使用するには:

1. 上部のバーで、**検索または移動先**を選択します。
1. 検索ボックスに検索語句を入力します。
1. 左サイドバーで、**コード**を選択します。

プロジェクトまたはグループで完全一致コードの検索を使用することもできます。

## 使用可能なスコープ {#available-scopes}

スコープは、検索するデータの種類を表します。完全一致コードの検索では、次のスコープを使用できます。

| スコープ | グローバル<sup>1</sup> <sup>2</sup> |    グループ    | プロジェクト     |
|-------|:--------------------------------:|:-----------:|:-----------:|
| コード  |           {{< no >}}             | {{< yes >}} | {{< yes >}} |

**脚注**: 

1. 管理者は、[グローバル検索のスコープを無効にできます](_index.md#disable-global-search-scopes)。GitLab 18.6以前では、GitLab Self-Managedでグローバル検索を有効にするには、管理者が`zoekt_cross_namespace_search`機能フラグも有効にする必要があります。
1. GitLab.comでは、グローバル検索は有効になっていません。

## Zoekt検索API {#zoekt-search-api}

{{< history >}}

- GitLab 16.9で`zoekt_search_api`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143666)されました。デフォルトでは有効になっています。
- GitLab 18.4で[一般提供](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17522)になりました。機能フラグ`zoekt_search_api`は削除されました。

{{< /history >}}

Zoekt検索APIを使用すると、完全一致コードの検索の検索APIを使用できます。代わりに高度な検索または基本的な検索を使用するには、[検索タイプを指定](_index.md#specify-a-search-type)します。

## 検索モード {#search-modes}

{{< history >}}

- GitLab 16.8で`zoekt_exact_search`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/434417)されました。デフォルトでは無効になっています。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/436457)になりました。機能フラグ`zoekt_exact_search`は削除されました。

{{< /history >}}

GitLabには2つの検索モードがあります。

- **完全一致モード**: クエリに完全に一致する結果を返します。
- **正規表現モード**: 正規表現とブール式をサポートします。

デフォルトでは、完全一致モードが使用されます。正規表現モードに切り替えるには、検索ボックスの右側にある**正規表現を使用**（{{< icon name="regular-expression" >}}）を選択します。

### 構文 {#syntax}

<!-- Remember to also update the table in `doc/drawers/exact_code_search_syntax.md` -->

次の表は、完全一致モードと正規表現モードのクエリの例を示しています。

| クエリ                | 完全一致モード                                                                | 正規表現モード                                                         |
|----------------------|---------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| `"foo"`              | `"foo"`                                                                         | `foo`                                                                           |
| `foo file:^doc/`     | `/doc`で始まるディレクトリ内の`foo`                                     | `/doc`で始まるディレクトリ内の`foo`                                     |
| `"class foo"`        | `"class foo"`                                                                   | `class foo`                                                                     |
| `class foo`          | `class foo`                                                                     | `class`と`foo`                                                               |
| `foo or bar`         | `foo or bar`                                                                    | `foo`または`bar`                                                                  |
| `class Foo`          | `class Foo`（大文字と小文字を区別）                                                    | `class`（大文字と小文字を区別しない）と`Foo`（大文字と小文字を区別する）                           |
| `class Foo case:yes` | `class Foo`（大文字と小文字を区別）                                                    | `class`と`Foo`（どちらも大文字と小文字を区別）                                         |
| `foo -bar`           | `foo -bar`                                                                      | `foo`だが`bar`ではない                                                             |
| `foo file:js`        | `js`を含む名前のファイル内の`foo`                                     | `js`を含む名前のファイル内の`foo`                                     |
| `foo -file:test`     | `test`を含まない名前のファイル内の`foo`                            | `test`を含まない名前のファイル内の`foo`                            |
| `foo lang:ruby`      | Rubyのソースコード内の`foo`                                                       | Rubyのソースコード内の`foo`                                                       |
| `foo file:\.js$`     | `.js`で終わる名前のファイル内の`foo`                                   | `.js`で終わる名前のファイル内の`foo`                                   |
| `foo.*bar`           | `foo.*bar`（リテラル）                                                            | `foo.*bar`（正規表現）                                                 |
| `sym:foo`            | クラス、メソッド、変数名などのシンボル内の`foo`                         | クラス、メソッド、変数名などのシンボル内の`foo`                         |
| `test repo:(?i)foo`  | 名前に`foo`を含むプロジェクト（大文字と小文字を区別しない）で`test`を検索します。`repo:`は正規表現をサポートします。 | 名前に`foo`を含むプロジェクト（大文字と小文字を区別しない）で`test`を検索します。`repo:`は正規表現をサポートします。 |

## 既知の問題 {#known-issues}

- `20_000`トライグラム以下で1 MB未満のファイルのみが検索可能となっています。詳しくは、[イシュー455073](https://gitlab.com/gitlab-org/gitlab/-/issues/455073)をご覧ください。
- プロジェクトのデフォルトブランチのみで、完全一致コードの検索を使用できます。詳しくは、[イシュー403307](https://gitlab.com/gitlab-org/gitlab/-/issues/403307)をご覧ください。
- 1行に複数の一致がある場合、1つの結果としてカウントされます。
- 改行が正しく表示されない結果に遭遇した場合は、`gitlab-zoekt`をバージョン1.5.0以降に更新してください。
