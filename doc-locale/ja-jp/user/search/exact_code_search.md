---
stage: Foundations
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

- GitLab 15.9で、`index_code_with_zoekt`と`search_code_with_zoekt`という名前の[フラグとともに](../../administration/feature_flags.md)[ベータ](../../policy/development_stages_support.md#beta)として[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049)。デフォルトでは無効になっています。
- GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/388519)になりました。
- GitLab 17.1で、機能フラグ`index_code_with_zoekt`、`search_code_with_zoekt`は[削除されました。](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378)

{{< /history >}}

{{< alert type="warning" >}}

この機能は[ベータ](../../policy/development_stages_support.md#beta)版であり、予告なしに変更される場合があります。詳しくは、[エピック9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)をご覧ください。

{{< /alert >}}

完全一致コードの検索を使用すると、完全一致モードと正規表現モードを使用して、GitLab全体または特定のプロジェクト内のコードを検索できます。

完全一致コードの検索は[Zoekt](https://github.com/sourcegraph/zoekt)を利用しており、この機能が有効になっているグループではデフォルトで使用されます。

## 完全一致コードの検索を有効にする

- [GitLab.com](../../subscriptions/gitlab_com/_index.md)の場合、完全一致コードの検索は有料サブスクリプションで有効になります。
- [GitLab Self-Managed](../../subscriptions/self_managed/_index.md)の場合、管理者は[Zoektをインストール](../../integration/exact_code_search/zoekt.md#install-zoekt)して、[完全一致コードの検索を有効にする](../../integration/exact_code_search/zoekt.md#enable-exact-code-search)必要があります。

ユーザー設定で[完全一致コードの検索を無効にする](../profile/preferences.md#disable-exact-code-search)と、代わりに[高度な検索](advanced_search.md)を使用できます。

## Zoekt検索API

{{< history >}}

- GitLab 16.9で`zoekt_search_api`[フラグ](../../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143666)されました。デフォルトで有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については履歴を参照してください。この機能はテストには使用できますが、本番環境での使用はまだ許可されていません。

{{< /alert >}}

Zoekt検索APIを使用すると、[検索API](../../api/search.md)を完全一致コードの検索に使用できます。代わりに[高度な検索](advanced_search.md)または基本検索を使用する場合は、[検索タイプの指定](_index.md#specify-a-search-type)を参照してください。

デフォルトでは、Zoekt検索APIは、破壊的な変更を避けるためにGitLab.comでは無効になっています。この機能へのアクセスをリクエストするには、GitLabにお問い合わせください。

## グローバルコード検索

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077)されました。[フラグ](../../administration/feature_flags.md)が`zoekt_cross_namespace_search`という名前で付けられています。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については履歴を参照してください。この機能はテストには使用できますが、本番環境での使用はまだ許可されていません。

{{< /alert >}}

この機能を使用すると、GitLabインスタンス全体のコードを検索できます。

グローバルコード検索は、大規模なGitLabインスタンスでは適切に機能しません。この機能が20,000を超えるプロジェクトを持つインスタンスで有効になっている場合、検索がタイムアウトする可能性があります。

## 検索モード

{{< history >}}

- GitLab 16.8で`zoekt_exact_search`[フラグ](../../administration/feature_flags.md)とともに[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/434417)。デフォルトでは無効になっています。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/436457)になりました。機能フラグ`zoekt_exact_search`が削除されました。

{{< /history >}}

GitLabには2つの検索モードがあります。

- **完全一致モード:** クエリに完全に一致する結果を返します。
- **正規表現モード:** 正規表現とブール式をサポートします。

デフォルトでは、完全一致モードが使用されます。正規表現モードに切り替えるには、検索ボックスの右側にある**正規表現を使用**（{{< icon name="regular-expression" >}}）を選択します。

### 構文

<!-- Remember to also update the table in `doc/drawers/exact_code_search_syntax.md` -->

次のテーブルは、完全一致モードと正規表現モードのクエリの例を示しています。

| クエリ                | 完全一致モード                                        | 正規表現モード |
| -------------------- | ------------------------------------------------------- | ----------------------- |
| `"foo"`              | `"foo"`                                                 | `foo` |
| `foo file:^doc/`     | `/doc`で始まるディレクトリ内の`foo`             | `/doc`で始まるディレクトリ内の`foo` |
| `"class foo"`        | `"class foo"`                                           | `class foo` |
| `class foo`          | `class foo`                                             | `class`と`foo` |
| `foo or bar`         | `foo or bar`                                            | `foo`または`bar` |
| `class Foo`          | `class Foo`（大文字と小文字を区別）                            | `class`（大文字と小文字を区別しない）と `Foo`（大文字と小文字を区別する） |
| `class Foo case:yes` | `class Foo`（大文字と小文字を区別）                            | `class`と`Foo`（どちらも大文字と小文字を区別） |
| `foo -bar`           | `foo -bar`                                              | `foo`だが`bar`ではない |
| `foo file:js`        | `js`を含む名前のファイル内の`foo`             | `js`を含む名前のファイル内の`foo` |
| `foo -file:test`     | `test`を含まない名前のファイル内の`foo`    | `test`を含まない名前のファイル内の`foo` |
| `foo lang:ruby`      | Rubyのソースコード内の`foo`                               | Rubyのソースコード内の`foo` |
| `foo file:\.js$`     | `.js`で終わる名前のファイル内の`foo`           | `.js`で終わる名前のファイル内の`foo` |
| `foo.*bar`           | `foo.*bar`（(リテラル）                                    | `foo.*bar`（正規表現） |
| `sym:foo`            | クラス、メソッド、変数名などのシンボル内の`foo` | クラス、メソッド、変数名などのシンボル内の`foo` |

## 既知の問題

- `20_000`トリグラム未満で1MB未満のファイルのみが検索可能となっています。詳しくは、[イシュー455073](https://gitlab.com/gitlab-org/gitlab/-/issues/455073)をご覧ください。
- プロジェクトのデフォルトブランチでのみ、完全一致コードの検索を使用できます。詳しくは、[イシュー403307](https://gitlab.com/gitlab-org/gitlab/-/issues/403307)をご覧ください。
- 1行に複数の一致がある場合、1つの結果としてカウントされます。詳しくは、[イシュー514526](https://gitlab.com/gitlab-org/gitlab/-/issues/514526)をご覧ください。
- 改行が正しく表示されない結果が発生した場合は、`gitlab-zoekt`をバージョン1.5.0以降に更新する必要があります。詳しくは、[イシュー516937](https://gitlab.com/gitlab-org/gitlab/-/issues/516937)をご覧ください。
