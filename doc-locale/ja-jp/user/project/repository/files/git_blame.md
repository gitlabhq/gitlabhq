---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Gitファイルのblameに関するドキュメント。
title: Gitファイルのblame
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Git blame](https://git-scm.com/docs/git-blame)は、最終更新時刻、作成者、コミットハッシュなど、ファイル内のすべての行に関する詳細情報を提供します。

## ファイルのblameを表示する {#view-blame-for-a-file}

{{< history >}}

- ファイルビューで直接blameを表示することは、GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/430950)されました。`inline_blame`という名前の[フラグ付き](../../../../administration/feature_flags/_index.md)。デフォルトでは無効になっています。

{{< /history >}}

前提要件: 

- ファイルには、読み取り可能なテキストコンテンツが含まれている必要があります。GitLab UIは、`.rb`、`.js`、`.md`、`.txt`、`.yml`などのテキストファイルに対する`git blame`の結果を表示します。画像やPDFなどのバイナリファイルはサポートされていません。

ファイルのblameを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **リポジトリ**を選択します。
1. レビューするファイルを選択します。
1. 次のいずれかの操作を行います:
   - 現在のファイルの表示を変更するには、ファイルヘッダーで**Blame**を選択します。
   - 完全なblameページを開くには、右上隅で**Blame**を選択します。
1. 表示する行にカーソルを合わせるます。

**Blame**を選択すると、次の情報が出力されます:

![Git blameの出力](img/file_blame_output_v16_6.png "Blameボタンの出力")

コミットの正確な日時を確認するには、日付にカーソルを合わせるます。ユーザーアバターの左側にある縦のバーは、コミットのおおよその経過時間を示しています。最新のコミットには、濃い青色のバーが表示されます。コミットの経過時間が長くなるにつれて、バーの色は薄い灰色に変化します。

### Blameの前のコミット {#blame-previous-commit}

特定の行の以前のリビジョンを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **リポジトリ**を選択します。
1. レビューするファイルを選択します。
1. 右上隅で**Blame**を選択し、表示する行に移動します。
1. 表示したい変更が見つかるまで、**この変更前のblameを表示** ({{< icon name="doc-versions" >}}) を選択します。

### 特定のリビジョンを無視する {#ignore-specific-revisions}

{{< history >}}

- GitLab 17.10で`blame_ignore_revs`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/514684)されました。デフォルトでは無効になっています。
- GitLab 17.10の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/514325)。
- GitLab 17.11[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/525095)になりました。機能フラグ`blame_ignore_revs`は削除されました。{{< /history >}}

特定のリビジョンを無視するようにGit blameを設定するには:

1. リポジトリのルートに`.git-blame-ignore-revs`ファイルを作成します。
1. 無視するコミットハッシュを、1行に1つずつ追加します。例: 

   ```plaintext
   a24cb33c0e1390b0719e9d9a4a4fc0e4a3a069cc
   676c1c7e8b9e2c9c93e4d5266c6f3a50ad602a4c
   ```

1. Blameビューでファイルを開きます。
1. **Blame環境設定**ドロップダウンリストを選択します。
1. **特定のリビジョンを無視する**を選択します。

Blameビューが更新され、`.git-blame-ignore-revs`ファイルに指定されたリビジョンがスキップされ、代わりに以前の有意義な変更が表示されます。

## 関連トピック {#related-topics}

- [Gitファイルblame REST API](../../../../api/repository_files.md#get-file-blame-from-repository)
- [一般的なGitコマンド](../../../../topics/git/commands.md)
- [Gitを使用したファイル管理](../../../../topics/git/file_management.md)
