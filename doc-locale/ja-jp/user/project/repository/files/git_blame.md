---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Gitファイルのblameに関するドキュメント。
title: Gitファイルblame
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Git blame](https://git-scm.com/docs/git-blame)は、ファイル内のすべての行に関する詳細情報（最終更新時刻、作成者、コミットハッシュなど）を提供します。

## ファイルのblameを表示 {#view-blame-for-a-file}

{{< history >}}

- ファイルビューでのblameの直接表示は、GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/430950)され、`inline_blame`という名前の[フラグ](../../../../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。

{{< /history >}}

前提条件: 

- ファイルには判読可能なテキストコンテンツが含まれている必要があります。GitLab UIは、`git blame`の結果を、`.rb`、`.js`、`.md`、`.txt`、`.yml`などのテキストファイル形式で表示します。画像やPDFなどのバイナリファイルはサポートされていません。

ファイルのblameを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**コード** > **リポジトリ**を選択します。
1. 確認するファイルを選択します。
1. 次のいずれかの操作を行います:
   - 現在のファイルの表示を変更するには、ファイルのヘッダーで**Blame**を選択します。
   - 完全なblameページを開くには、右上隅で**Blame**を選択します。
1. 見たい行に移動します。

**Blame**を選択すると、この情報が表示されます:

![Git blame出力](img/file_blame_output_v16_6.png "Blameボタン出力")

コミットの正確な日時を確認するには、日付にカーソルを合わせます。ユーザーアバターの左にある垂直バーは、コミットの一般的な経過時間を示します。最新のコミットには濃い青色のバーが表示されます。コミットの経過時間が長くなるにつれて、バーの色は明るい灰色に変わります。

### 前のコミットのblame {#blame-previous-commit}

特定の行の以前のリビジョンを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**コード** > **リポジトリ**を選択します。
1. 確認するファイルを選択します。
1. 右上隅で**Blame**を選択し、見たい行に移動します。
1. **この変更前のblameを表示**（{{< icon name="doc-versions" >}}）を選択し、表示したい変更が見つかるまで繰り返します。

### 特定のリビジョンを無視する {#ignore-specific-revisions}

{{< history >}}

- GitLab 17.10で`blame_ignore_revs`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/514684)されました。デフォルトでは無効になっています。
- GitLab 17.10の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/514325)。
- GitLab 17.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/525095)になりました。機能フラグ`blame_ignore_revs`は削除されました。

{{< /history >}}

Git blameで特定のリビジョンを無視するように設定するには:

1. あなたのリポジトリのルートに、`.git-blame-ignore-revs`ファイルを作成します。
1. 無視したいコミットハッシュを1行に1つずつ追加します。例: 

   ```plaintext
   a24cb33c0e1390b0719e9d9a4a4fc0e4a3a069cc
   676c1c7e8b9e2c9c93e4d5266c6f3a50ad602a4c
   ```

1. blameビューでファイルを開きます。
1. **Blame環境設定**ドロップダウンリストを選択します。
1. **特定のリビジョンを無視する**を選択します。

blameビューは更新され、`.git-blame-ignore-revs`ファイルで指定されたリビジョンをスキップし、代わりに以前の重要な変更を表示します。

## 関連トピック {#related-topics}

- [Gitファイルblame REST API](../../../../api/repository_files.md#retrieve-file-blame-history-from-a-repository)
- [一般的なGitコマンド](../../../../topics/git/commands.md)
- [Gitを使用したファイル管理](../../../../topics/git/file_management.md)
- [ファイルツリーブラウザー](file_tree_browser.md)
