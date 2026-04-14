---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: コマンドラインを使用して、ファイルをGitリポジトリに追加、コミット、プッシュします。
title: ブランチにファイルを追加する
---

Gitを使用して、ローカルリポジトリのブランチにファイルを追加します。このアクションにより、次回のコミットのためにファイルのスナップショットが作成され、バージョン管理のモニタリングが開始されます。Gitでファイルを追加する際、次を実行します。

- バージョン管理の追跡用にコンテンツを準備します。
- ファイルの追加と変更の記録を作成します。
- 将来参照できるようにファイル履歴を保持します。
- チームコラボレーションのためにプロジェクトファイルを利用できるようにします。

## Gitリポジトリにファイルを追加する {#add-files-to-a-git-repository}

コマンドラインから新しいファイルを追加するには:

1. ターミナルを開きます。
1. プロジェクトのフォルダに移動するまで、ディレクトリを変更します。

   ```shell
   cd my-project
   ```

1. 処理するGitブランチを選択します。
   - ブランチを作成するには: `git checkout -b <branchname>`
   - 既存のブランチに切り替えるには: `git checkout <branchname>`

1. 追加するファイルを、追加先のディレクトリにコピーします。
1. ファイルがディレクトリにあることを確認します。
   - Windows: `dir`
   - その他すべてのオペレーティングシステム: `ls`

   ファイル名が表示されます。
1. ファイルのステータスを確認します。

   ```shell
   git status
   ```

   ファイル名は赤色で表示されます。ファイルはファイルシステムにありますが、Gitはまだ追跡していません。
1. Gitにファイルを追跡するように指示します。

   ```shell
   git add <filename>
   ```

1. ファイルのステータスを再度確認します。

   ```shell
   git status
   ```

   ファイル名は緑色で表示されます。ファイルはGitによってステージング（ローカルで追跡）されていますが、[コミットおよびプッシュ](commit.md)はされていません。

## ファイルを最後のコミットに追加する {#add-a-file-to-the-last-commit}

ファイルの変更を新しいコミットではなく、最後のコミットに追加するには、既存のコミットを修正します。

```shell
git add <filename>
git commit --amend
```

コミットメッセージを編集しない場合は、`--no-edit`を`commit`コマンドに付加します。

## 関連トピック {#related-topics}

- [UIからファイルを追加する](../../user/project/repository/_index.md#add-a-file-from-the-ui)
- [Web IDEからファイルを追加する](../../user/project/repository/web_editor.md#upload-a-file)
- [コミットに署名する](../../user/project/repository/signed_commits/gpg.md)
