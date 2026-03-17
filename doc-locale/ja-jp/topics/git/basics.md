---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 一般的なGitコマンドとワークフロー。
title: 基本的なGit操作
description: プロジェクトを作成し、リポジトリをクローンし、変更をスタッシュし、ブランチ、およびフォークを作成します。
---

基本的なGit操作は、Gitリポジトリを管理し、コードに変更を加えるのに役立ちます。それらはあなたに以下の利点を提供します:

- バージョン管理: プロジェクトの履歴を維持し、変更を追跡するとともに、必要に応じて以前のバージョンに戻します。
- コラボレーション: コラボレーションを可能にし、コードの共有を容易にし、同時に作業できます。
- 組織化: ブランチとマージリクエストを使用して作業を整理および管理できます。
- コード品質: マージリクエストによるコードレビューを促進し、コード品質と一貫性を維持するのに役立ちます。
- バックアップとリカバリー: リモートリポジトリに変更をプッシュすることで、作業がバックアップされ、リカバリー可能であることを保証します。

Git操作を効果的に使用するには、リポジトリ、ブランチ、コミット、マージリクエストなどの主要な概念を理解することが重要です。詳細については、[Gitの学習を開始する](get_started.md)を参照してください。

一般的に使用されるGitコマンドの詳細については、[Gitコマンド](commands.md)を参照してください。

## プロジェクトを作成する {#create-a-project}

`git push`コマンドは、ローカルリポジトリの変更をリモートリポジトリに送信します。ローカルリポジトリからプロジェクトを作成するか、既存のリポジトリをインポートできます。リポジトリを追加すると、GitLabは選択したネームスペースにプロジェクトを作成します。詳細については、[Create a project](project.md)を参照してください。

## リポジトリのクローンを作成する {#clone-a-repository}

`git clone`コマンドは、リモートリポジトリのコピーをコンピューター上に作成します。ローカルでコードを操作し、変更をリモートリポジトリにプッシュすることができます。詳細については、[Clone a Git repository](clone.md)を参照してください。

## ブランチを作成する {#create-a-branch}

`git checkout -b <name-of-branch>`コマンドは、あなたのリポジトリに新しいブランチを作成します。ブランチは、リポジトリ内のファイルのコピーであり、デフォルトブランチに影響を与えることなく変更できます。詳細については、[Create a branch](branch.md)を参照してください。

## 変更のステージング、コミット、プッシュ {#stage-commit-and-push-changes}

`git add`、`git commit`、および`git push`コマンドは、あなたの変更をリモートリポジトリに更新します。Gitは、チェックアウトされたブランチの最新バージョンに対して変更を追跡します。詳細については、[変更のステージング、コミット、プッシュ](commit.md)を参照してください。

## 変更をスタッシュする {#stash-changes}

`git stash`コマンドは、すぐにコミットしたくない変更を一時的に保存します。ブランチを切り替えるか、不完全な変更をコミットすることなく他の操作を実行できます。詳細については、[Stash changes](stash.md)を参照してください。

## ブランチにファイルを追加する {#add-files-to-a-branch}

`git add <filename>`コマンドは、Gitリポジトリまたはブランチにファイルを追加します。新しいファイルを追加したり、既存のファイルを変更したり、ファイルを削除したりできます。詳細については、[Add files to a branch](add_files.md)を参照してください。

## マージリクエスト {#merge-requests}

マージリクエストとは、あるブランチから別のブランチへ変更をマージするためのリクエストです。マージリクエストは、共同作業やコードレビューを行う方法を提供します。詳細については、[Merge requests](../../user/project/merge_requests/_index.md)および[Merge your branch](merge.md)を参照してください。

## フォークを更新する {#update-your-fork}

フォークは、リポジトリとすべてのブランチの個人用コピーであり、選択したネームスペースに作成できます。自分のフォークで変更を加え、`git push`を使用して提出できます。詳細については、[Update a fork](forks.md)を参照してください。

## 関連トピック {#related-topics}

- [Get started learning Git](get_started.md)
  - [Gitをインストールする](how_to_install_git/_index.md)
  - [一般的なGitコマンド](commands.md)
- [高度な操作](advanced.md)
- [Gitのトラブルシューティング](troubleshooting_git.md)
- [Gitチートシート](https://about.gitlab.com/images/press/git-cheat-sheet.pdf)
