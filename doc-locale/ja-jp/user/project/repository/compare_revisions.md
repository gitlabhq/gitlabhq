---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: ブランチ、タグ、およびコミットを比較して、リポジトリ内のリビジョン間の違いを表示します。
title: リビジョンを比較する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

**リビジョンを比較**を使用して、リビジョン間で変更されたコミットとファイルの一覧を表示します。

以下を比較できます:

- あるブランチから別のブランチへ。
- あるタグからブランチまたは別のタグへ。
- あるコミットから別のコミットまたはブランチへ。

## 比較の方法 {#compare-methods}

GitLabには、リビジョンを比較する2つの方法があります:

- **ソースからの変更のみ**（デフォルト）: 両方のリビジョンの最新の共通コミット以降のソースからの差異を表示します。この方法では、ソースの作成後にターゲットに加えられた無関係な変更を除外します。これを使用して、ソースのリビジョンによって導入された変更のみを表示します。

  この方法では、`git diff <from>...<to>` Gitコマンドを使用します。実際にはコミットを直接比較するのではなく、マージベース（共通の祖先コミット）からターゲットと比較します。

- **Include changes to target after source was created**（ソースの作成後にターゲットへの変更を含める）: ソースとターゲットの両方に対する変更を含む、2つのリビジョン間のすべての差異を表示します。これを使用して、リポジトリの履歴における2つのポイント間の完全な差異を表示します。

  この方法では、`git diff <from> <to>` Gitコマンドを使用します。実際のコミットを直接比較して、それらの間のすべての変更を表示します。

## ブランチ、タグ、またはコミットを比較する {#compare-branches-tags-or-commits}

リビジョンを比較するには、:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **リビジョンを比較**を選択します。
1. **ソース**リビジョンを選択します:

   - ブランチを検索するには、ブランチ名を入力します。最初に完全一致が表示されます。
   - タグを検索するには、タグ名を入力します。
   - コミットを検索するには、コミットSHAを入力します。
   - 演算子を使用して検索を絞り込むには、次のようにします:
     - `^`は名前の先頭と一致します。`^feat`は`feat/user-authentication`と一致します。
     - `$`は名前の末尾と一致します: `widget$`は`feat/search-box-widget`と一致します。
     - `*`はワイルドカードを使用して一致します。`branch*cache*`は`fix/branch-search-cache-expiration`と一致します。
     - 演算子を組み合わせることができます。`^chore/*migration$`は`chore/user-data-migration`と一致します。

1. **ターゲット**リポジトリとリビジョンを選択します。
1. **変更を表示**の下で、**ソースからの変更のみ**または**Include changes to target after source was created**（ソースの作成後にターゲットへの変更を含める）を選択します。
1. **比較**を選択します。
1. オプション。**ソース**と**ターゲット**を元に戻すには、**リビジョンの入れ替え**（{{< icon name="substitute" >}}）を選択します。

比較ページには、リビジョン間で変更されたコミットとファイルの一覧が表示されます。

## 関連トピック {#related-topics}

- [ブランチ](branches/_index.md)
- [タグ](tags/_index.md)
- [コミット](commits/_index.md)
- [Gitコマンド](../../../topics/git/commands.md)
