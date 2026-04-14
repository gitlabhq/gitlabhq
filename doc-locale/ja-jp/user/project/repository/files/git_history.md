---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: ファイルのGit履歴をGitLabで表示する方法。
title: Gitファイル履歴
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ファイルのGit履歴は、ファイルに関連付けられたコミット履歴に関する情報を提供します:

![単一ファイルの3つのコミットのリスト。「検証済み」とマークされた最新のコミット。](img/file_history_output_v17_2.png)

各コミットには以下が表示されます:

- コミットの日付。GitLabは、同じ日に作成されたすべてのコミットをグループ化します。
- ユーザーのアバター。
- ユーザー名。名前にカーソルを合わせると、ユーザーの役職、場所、現地時間、現在のステータスメッセージが表示されます。
- コミットの日付（経過時間形式）。コミットの正確な日時を確認するには、日付にカーソルを合わせます。
- もし[コミットが署名されている](../signed_commits/_index.md)場合、**検証済み**バッジが表示されます。
- コミットSHA。GitLabは最初の8文字を表示します。**コミットのSHAをコピー**（{{< icon name="copy-to-clipboard" >}}）を選択すると、SHA全体をコピーできます。
- このコミット時のファイルを参照（{{< icon name="folder-open" >}}）するためのリンク。

GitLabは、ユーザーがコミットを作成したときに、コントリビューターの[Git設定](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)からユーザー名とメール情報を取得します。

## ファイルのGit履歴を表示する {#view-a-files-git-history}

UIでファイルのGit履歴を表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**コード** > **リポジトリ**を選択します。
1. リポジトリ内の目的のファイルに移動します。
1. 最後のコミットブロックで、**履歴**を選択します。

## 履歴の検索結果範囲を制限する {#limit-history-range-of-results}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423108)されました。

{{< /history >}}

古いファイルや多数のコミットを含むファイルの履歴をレビューする際、日付で検索結果を制限できます。コミットの日付を制限すると、非常に大きなリポジトリで[コミット履歴リクエストタイムアウト](https://gitlab.com/gitlab-org/gitaly/-/issues/5426)を修正するのに役立ちます。

GitLab UIで、URLを編集します。`YYYY-MM-DD`形式でこれらのパラメータを含めます（日付はUTCで解釈されます）:

- `committed_before`
- `committed_after`

クエリ文字列内の各キー/バリューペアをアンパサンド（`&`）で区切ります。例:

```plaintext
?ref_type=heads&committed_after=2023-05-15&committed_before=2023-11-22
```

コミットの範囲への完全なURLは次のようになります:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/commits/master/CONTRIBUTING.md?ref_type=heads&committed_after=2023-05-15&committed_before=2023-11-22
```

## 関連トピック {#related-topics}

- [Git blame](git_blame.md)
- [一般的なGitコマンド](../../../../topics/git/commands.md)
- [Gitでのファイル管理](../../../../topics/git/file_management.md)
- [ファイルツリーブラウザー](file_tree_browser.md)
