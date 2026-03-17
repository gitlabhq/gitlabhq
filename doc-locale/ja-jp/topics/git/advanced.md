---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 高度なGit操作
description: リベース、チェリーピック</cherry-ピック、変更のRevert、リポジトリ、およびファイル管理。
---

高度なGit操作は、コードの保守と管理のタスクを実行するのに役立ちます。これらは、[基本的なGit操作](basics.md)を超える、より複雑なアクションです。これらの操作により、以下が可能になります:

- コミット履歴を書き換えます。
- 変更をRevertおよび元に戻します。
- リモートリポジトリ接続を管理します。

それらはあなたに以下の利点を提供します:

- コード品質: クリーンで線形なプロジェクト履歴を維持します。
- 問題解決: 間違いを修正したり、リポジトリの状態を調整するためのツールを提供します。
- ワークフローの最適化: 複雑な開発プロセスを合理化します。
- コラボレーション: 大規模または複雑なプロジェクトでのよりスムーズなチームワークを促進します。

Git操作を効果的に使用するには、リポジトリ、ブランチ、コミット、マージリクエストなどの主要な概念を理解することが重要です。詳細については、[Gitの学習を開始する](get_started.md)を参照してください。

## ベストプラクティス {#best-practices}

高度なGit操作を使用する場合、次のことを行う必要があります:

- バックアップを作成するか、[別のブランチ](branch.md)で作業します。
- 共有ブランチ履歴に影響する操作を使用する前に、チームとコミュニケーションを取ります。
- 履歴を書き換えるときは、[記述的なコミットメッセージ](../../tutorials/update_commit_messages/_index.md)を使用してください。
- ベストプラクティスと新機能に対応するために、Gitの知識を更新してください。詳細については、[Gitドキュメント](https://git-scm.com/docs)を参照してください。
- テストリポジトリで高度な操作を練習します。

## リベースと競合を解決する {#rebase-and-resolve-conflicts}

`git rebase`コマンドは、別のブランチの内容で自分のブランチを更新します。これは、自分のブランチの変更がターゲットブランチの変更と競合しないことを確認します。[マージコンフリクト](../../user/project/merge_requests/conflicts.md)がある場合は、リベースして修正できます。

詳細については、[マージコンフリクトに対処するためのリベース](git_rebase.md)を参照してください。

## 変更のチェリーピック {#cherry-pick-changes}

`git cherry-pick`コマンドは、特定のコミットをあるブランチから別のブランチに適用します。次の目的で使用します:

- デフォルトブランチから以前のリリースブランチにバグ修正をバックポートする。
- フォークからアップストリームリポジトリに変更をコピーする。
- 完全にブランチをマージせずに特定の変更を適用します。

詳細については、[Gitでの変更のチェリーピック](cherry_pick.md)を参照してください。

## 変更のRevertおよび元に戻す {#revert-and-undo-changes}

以下のGitコマンドは、変更をRevertおよび元に戻すのに役立ちます:

- `git revert`: 以前のコミットで行われた変更を元に戻す新しいコミットを作成します。これは、間違いや不要になった変更を元に戻すのに役立ちます。
- `git reset`: まだコミットされていない変更をリセットして元に戻します。
- `git restore`: 失われた、または削除された変更を復元します。

詳細については、[変更をRevertする](undo.md)を参照してください。

## リポジトリのサイズを縮小する {#reduce-repository-size}

Gitリポジトリのサイズは、パフォーマンスとストレージコストに影響を与える可能性があります。圧縮、ハウスキーピング、その他の要因により、インスタンスごとに若干異なる場合があります。リポジトリのサイズに関する詳細については、[リポジトリのサイズ](../../user/project/repository/repository_size.md)を参照してください。

Gitを使用して、リポジトリの履歴からファイルをパージし、そのサイズを縮小できます。詳細については、[リポジトリのサイズを縮小する](repository.md)を参照してください。

## ファイル管理 {#file-management}

Gitを使用して、リポジトリ内のファイルを管理できます。これにより、変更を追跡し、他のユーザーと共同作業を行い、大きなファイルを管理できます。次のオプションを利用できます:

- `git log`: リポジトリ内のファイルの変更を表示します。
- `git blame`: ファイル内のコード行を最後に変更したユーザーを識別します。
- `git lfs`: リポジトリ内のファイルを管理、追跡、およびロックします。

<!-- Include when the relevant MR is merged.

For more information, see [File management](file_management.md).

-->

## GitリモートURLを更新する {#update-git-remote-urls}

`git remote set-url`コマンドは、リモートリポジトリのURLを更新します。次の場合に使用します:

- 既存のプロジェクトを別のGitリポジトリホストからインポートした場合。
- 組織がプロジェクトを新しいドメイン名の新しいGitLabインスタンスに移動した場合。
- プロジェクトが同じGitLabインスタンス内の新しいパスに名前変更された場合。

詳細については、[GitリモートURLを更新する](../../tutorials/update_git_remote_url/_index.md)を参照してください。

## 関連トピック {#related-topics}

- [はじめに](get_started.md)
- [基本的なGit操作](basics.md)
- [一般的なGitコマンド](commands.md)
