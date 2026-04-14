---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabプロジェクトでは、Jupyter Notebookファイルをrawファイルではなく、クリーンで人間が読み取り可能なファイルとして表示します。
title: Jupyter Notebookファイル
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Jupyter Notebook](https://jupyter.org/)（以前はIPython Notebook）ファイルは、多くの分野でインタラクティブな計算に使用されます。これらには、ユーザーセッションの完全な記録が含まれており、次のものが含まれます:

- コード。
- 説明文。
- 数式。
- リッチ出力。

Jupyter Notebook（`.ipynb`拡張子）をリポジトリに追加すると、表示時にHTMLにレンダリングされます:

![Jupyter Notebookリッチ出力](img/jupyter_notebook_v17_10.png)

JavaScriptプロットを含むインタラクティブ機能は、GitLabで表示しても動作しません。

## cleaner diffとraw diff {#cleaner-diffs-and-raw-diffs}

Jupyter Notebookファイルへの変更がコミットに含まれる場合、GitLabは次の処理を行います:

- 機械が読み取り可能な`.ipynb`ファイルを、人間が読み取り可能なMarkdownファイルに変換します。
- 構文ハイライトを含む、よりクリーンな差分を表示します。
- コミットページと比較ページで、raw差分とレンダリングされた差分を切り替えることができます。（マージリクエストページでは利用できません。）
- 差分上の画像をレンダリングします。

コード提案は、`.ipynb`ファイルに対する差分とマージリクエストでは利用できません。

ノートブックが大きすぎる場合、よりクリーンなノートブック差分は生成されません。

## Jupyter Gitインテグレーション {#jupyter-git-integration}

Jupyterは、認証済みユーザーに代わって動作する、リポジトリアクセス権限を持つOAuthアプリケーションとして設定できます。設定例については、[手順書](../../../clusters/runbooks/_index.md)を参照してください。
