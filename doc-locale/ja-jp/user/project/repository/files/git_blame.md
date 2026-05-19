---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Gitファイルblameのドキュメント。
title: Gitファイルblame
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Git blame](https://git-scm.com/docs/git-blame)は、ファイル内のすべての行に関する詳細情報（最終更新時刻、作成者、コミットハッシュなど）を提供します。

## ファイルごとのblameを表示 {#view-blame-for-a-file}

{{< history >}}

- ファイルビューで直接blameを表示する機能は、GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/430950)されました。[フラグ](../../../../administration/feature_flags/_index.md)名は`inline_blame`です。デフォルトでは無効になっています。

{{< /history >}}

前提条件: 

- ファイルには読み取り可能なテキストコンテンツが含まれている必要があります。GitLab UIは、`git blame`の結果を`.rb`、`.js`、`.md`、`.txt`、`.yml`などのテキストファイル形式で表示します。画像やPDFなどのバイナリファイルはサポートされていません。

ファイルのblameを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**コード** > **リポジトリ**を選択します。
1. レビューしたいファイルを選択します。
1. 次のいずれかの操作を行います:
   - 現在のファイルのビューを変更するには、ファイルヘッダーで**Blame**を選択します。
   - 完全なblameページを開くには、右上隅で**Blame**を選択します。
1. 表示したい行に移動します。

**Blame**を選択すると、この情報が表示されます:

![Git blameの出力](img/file_blame_output_v18_11.png "blameボタンの出力")

コミットの正確な日時を確認するには、日付にカーソルを合わせるます。コミットの経過時間を示す色凡例を表示するには、[経過時間インジケーターの凡例を表示](#show-age-indicator-legend)を参照してください。

### 前のコミットのblame {#blame-previous-commit}

特定の行の以前のリビジョンを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**コード** > **リポジトリ**を選択します。
1. レビューしたいファイルを選択します。
1. 右上隅で**Blame**を選択し、表示したい行に移動します。
1. 表示したい変更が見つかるまで、**この変更前のblameを表示** ({{< icon name="doc-versions" >}}) を選択します。

### 特定の改訂版を無視する {#ignore-specific-revisions}

{{< history >}}

- GitLab 17.10で`blame_ignore_revs`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/514684)されました。デフォルトでは無効になっています。
- GitLab 17.10の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/514325)。
- GitLab 17.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/525095)になりました。機能フラグ`blame_ignore_revs`は削除されました。

{{< /history >}}

Git blameが特定の改訂版を無視するように設定するには:

1. ローカルのリポジトリのルートに、`.git-blame-ignore-revs`ファイルを作成します。
1. 無視したいコミットハッシュを1行に1つずつ追加します。例: 

   ```plaintext
   a24cb33c0e1390b0719e9d9a4a4fc0e4a3a069cc
   676c1c7e8b9e2c9c93e4d5266c6f3a50ad602a4c
   ```

1. blameビューでファイルを開きます。
1. **Blame環境設定** ({{< icon name="preferences" >}})を選択します。
1. **特定のリビジョンを無視する**チェックボックスを選択します。

blameビューが更新され、`.git-blame-ignore-revs`ファイルで指定されたリビジョンはスキップされ、以前の重要な変更が表示されます。

### 経過時間インジケーターの凡例を表示 {#show-age-indicator-legend}

{{< history >}}

- GitLab 18.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/589722)されました。

{{< /history >}}

インラインのblameビューで、インライン経過時間インジケーターの凡例を表示または非表示にできます。この凡例は、コミットの経過時間を解釈するのに役立つ、**新しい**から**古い**までのカラースケールを表示します。

経過時間インジケーターの凡例を表示または非表示にするには:

1. blameビューでファイルを開きます。
1. **Blame環境設定** ({{< icon name="preferences" >}})を選択します。
1. **経過時間インジケーターの凡例を表示**チェックボックスを選択またはクリアします。

## 関連トピック {#related-topics}

- [Gitファイルblame REST API](../../../../api/repository_files.md#retrieve-file-blame-history-from-a-repository)
- [一般的なGitコマンド](../../../../topics/git/commands.md)
- [Gitでのファイル管理](../../../../topics/git/file_management.md)
- [ファイルツリーブラウザー](file_tree_browser.md)
