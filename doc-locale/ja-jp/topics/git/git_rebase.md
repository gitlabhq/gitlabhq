---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Gitリベースおよび強制プッシュの概要、コマンドラインからマージコンフリクトを解決する方法について説明します。
title: リベースしてマージコンフリクトを解決する
---

Gitリベースは、コミットをターゲットブランチの先端に移動することで、1つのブランチから別のブランチへの変更を統合します。この操作の特徴:

- ターゲットブランチからの最新のコードを使ってブランチを更新します。
- デバッグとコードレビューを容易にするため、クリーンで直線的なコミット履歴を保持します。
- 競合解決のために、コミットレベルで[マージコンフリクト](../../user/project/merge_requests/conflicts.md)を解決します。
- コード変更の時系列順序を保持します。

リベースを実行すると:

1. 最初にブランチを作成した後、Gitがターゲットブランチに送信されたすべてのコミットをインポートします。
1. Gitは、インポートされたコミットの上に、ブランチからのコミットを適用します。この例では、`feature`という名前のブランチが作成された後（オレンジ色）、`main`（紫色）からの4つのコミットが`feature`ブランチにインポートされます。

   ![Gitリベースの図](img/rebase_v17_10.drawio.svg)

ほとんどのリベースは`main`に対して実行されますが、他のブランチに対してもリベースできます。別のリモートリポジトリを指定することもできます。たとえば、`origin`の代わりに`upstream`を指定します。

{{< alert type="warning" >}}

`git rebase`はコミット履歴を書き換えます。共有ブランチで競合が発生し、複雑なマージコンフリクトが発生する可能性があります。デフォルトブランチに対してブランチをリベースする代わりに、`git pull origin master`の使用を検討してください。プルすると、他のユーザーの作業を損なうリスクを軽減しながら、同様の効果が得られます。

{{< /alert >}}

## リベース {#rebase}

Gitを使用してリベースを行うと、各コミットがブランチに適用されます。マージコンフリクトが発生すると、それらに対処するように求めるプロンプトが表示されます。

コミットのより高度なオプションについては、[インタラクティブなリベース](#interactive-rebase)を使用してください。

前提要件:

- ブランチに強制プッシュするには、[権限](../../user/permissions.md)が必要です。

Gitを使用してターゲットブランチに対してブランチをリベースするには:

1. ターミナルを開き、プロジェクトディレクトリに変更します。
1. ターゲットブランチのコンテンツが最新であることを確認してください。この例で、ターゲットブランチは`main`です。

   ```shell
   git fetch origin main
   ```

1. ブランチをチェックアウトします。

   ```shell
   git checkout my-branch
   ```

1. オプション。ブランチのバックアップを作成します。

   ```shell
   git branch my-branch-backup
   ```

   バックアップブランチから復元した場合、この時点以降に`my-branch`に追加された変更は失われます。

1. `main`ブランチに対してリベースを行います。

   ```shell
   git rebase origin/main
   ```

1. マージコンフリクトが存在する場合:
   1. エディタで競合を解決します。

   1. 変更をステージングします。

      ```shell
      git add .
      ```

   1. リベースを続行します。

      ```shell
      git rebase --continue
      ```

1. 他のユーザーのコミットを保護しながら、変更をターゲットブランチに強制プッシュします。

   ```shell
   git push origin my-branch --force-with-lease
   ```

## インタラクティブなリベース {#interactive-rebase}

インタラクティブなリベースを使用して、各コミットの処理方法を指定します。次の手順では、[Vim](https://www.vim.org/)テキストエディタを使用してコミットを編集します。

インタラクティブにリベースを行うには:

1. ターミナルを開き、プロジェクトディレクトリに変更します。
1. ターゲットブランチのコンテンツが最新であることを確認してください。この例で、ターゲットブランチは`main`です。

   ```shell
   git fetch origin main
   ```

1. ブランチをチェックアウトします。

   ```shell
   git checkout my-branch
   ```

1. オプション。ブランチのバックアップを作成します。

   ```shell
   git branch my-branch-backup
   ```

   バックアップブランチから復元した場合、この時点以降に`my-branch`に追加された変更は失われます。

1. GitLab UIを使用し、マージリクエストの**コミット**タブで、リベースを行うコミットの数を確認します。
1. これらのコミットを開きます。たとえば、最後の5つのコミットを編集するには:

   ```shell
   git rebase -i HEAD~5
   ```

   Gitは、ターミナルのテキストエディタで、最も古いコミットから順に開きます。各コミットには、実行するアクション、SHA、コミットタイトルが表示されます。例は次のとおりです。

   ```shell
   pick 111111111111 Second round of structural revisions
   pick 222222222222 Update inbound link to this changed page
   pick 333333333333 Shifts from H4 to H3
   pick 444444444444 Adds revisions from editorial
   pick 555555555555 Revisions continue to build the concept part out

   # Rebase 111111111111..222222222222 onto zzzzzzzzzzzz (5 commands)
   #
   # Commands:
   # p, pick <commit> = use commit
   # r, reword <commit> = use commit, but edit the commit message
   # e, edit <commit> = use commit, but stop for amending
   # s, squash <commit> = use commit, but meld into previous commit
   # f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
   ```

1. <kbd>i</kbd>を押して、Vimの編集モードに切り替えます。
1. 矢印キーを使用して、編集するコミットにカーソルを移動します。
1. 最初のコミット以外の各コミットで、`pick`を`squash`または`fixup`（または`s`または`f`）に変更します。
1. 残りのコミットに対して操作を繰り返します。
1. 編集モードを終了し、保存して終了します。

   - <kbd>ESC</kbd>を押します。
   - `:wq`と入力します。

1. スカッシュすると、Gitにはコミットメッセージを編集するように求めるプロンプトが表示されます。

   - `#`で始まる行は無視され、コミットメッセージには含まれません。
   - 現在のメッセージを保持するには、`:wq`と入力します。
   - コミットメッセージを編集するには、編集モードに切り替え、変更して保存します。

1. 変更をターゲットブランチにプッシュします。

   - リベースする前にコミットをターゲットブランチにプッシュしなかった場合:

     ```shell
     git push origin my-branch
     ```

   - 既にコミットをプッシュした場合:

     ```shell
     git push origin my-branch --force-with-lease
     ```

     一部の操作では、ブランチに変更を加えるためには強制プッシュが必要です。詳細については、[リモートブランチへ強制プッシュする](#force-push-to-a-remote-branch)を参照してください。

## コマンドラインから競合を解決する {#resolve-conflicts-from-the-command-line}

各変更の制御を最大限にするには、GitLabではなく、コマンドラインからローカルで複雑な競合を修正する必要があります。

前提要件:

- ブランチに強制プッシュするには、[権限](../../user/permissions.md)が必要です。

1. ターミナルを開き、フィーチャーブランチをチェックアウトします。

   ```shell
   git switch my-feature-branch
   ```

1. ターゲットブランチに対してブランチをリベースします。この例で、ターゲットブランチは`main`です。

   ```shell
   git fetch
   git rebase origin/main
   ```

1. 優先コードエディタで、競合するファイルを開きます。
1. 競合ブロックを見つけて解決します。
   1. 保持するバージョン（`=======`の前または後）を選択します。
   1. 保持しないバージョンを削除します。
   1. 競合マーカーを削除します。
1. ファイルを保存します。
1. 競合のある各ファイルに対してプロセスを繰り返します。
1. 変更をステージングします。

   ```shell
   git add .
   ```

1. 変更をコミットします。

   ```shell
   git commit -m "Resolve merge conflicts"
   ```

   {{< alert type="warning" >}}

   `git rebase --abort`を実行すると、この時点より前にプロセスを停止できます。Gitはリベースを中断し、ブランチを`git rebase`を実行する前の状態にロールバックします。`git rebase --continue`の実行後は、リベースを中断できません。

   {{< /alert >}}

1. リベースを続行します。

   ```shell
   git rebase --continue
   ```

1. 変更をリモートブランチへ強制プッシュします。

   ```shell
    git push origin my-feature-branch --force-with-lease
   ```

## リモートブランチへ強制プッシュする {#force-push-to-a-remote-branch}

コミットのスカッシュ、ブランチのリセット、リベースなどの複雑なGit操作を行うと、ブランチ履歴が書き換えられます。Gitでは、これらの変更を強制更新する必要があります。

共有ブランチでの強制プッシュは推奨されません。他のユーザーの変更を削除するリスクがあります。

ブランチが[保護](../../user/project/repository/branches/protected.md)されている場合、次のいずれかを行わないと、強制プッシュすることはできません。

- 保護を解除する
- 強制プッシュを許可する

詳細については、[保護されたブランチで強制プッシュを許可する](../../user/project/repository/branches/protected.md#allow-force-push)を参照してください。

## バックアップされたブランチを復元する {#restore-your-backed-up-branch}

リベースまたは強制プッシュが失敗した場合は、バックアップからブランチを復元します。

1. 正しいブランチにいることを確認します。

   ```shell
   git checkout my-branch
   ```

1. ブランチをバックアップにリセットします。

   ```shell
   git reset --hard my-branch-backup
   ```

## リベース後の承認 {#approving-after-rebase}

ブランチをリベースした場合、コミットが追加されています。プロジェクトが[コミットを追加したユーザーによる承認を防止する](../../user/project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits)ように設定されている場合、リベースしたマージリクエストを承認することはできません。また、以前はコミッターであり、以前は承認できなかったユーザーが、変更を承認できるようになる場合があります。

さらに、承認してからリベースを実行したユーザーは、マージリクエストを承認したと表示される場合があります。ただし、ユーザーの承認は、マージリクエストに必要な承認数にはカウントされません。

## 関連トピック {#related-topics}

- [変更を取り消す](undo.md)
- [ブランチとリベースに関するGitドキュメント](https://git-scm.com/book/en/v2/Git-Branching-Rebasing)
- [プロジェクトのスカッシュとマージの設定](../../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project)
- [マージコンフリクト](../../user/project/merge_requests/conflicts.md)

## トラブルシューティング {#troubleshooting}

CI/CDパイプラインのトラブルシューティング情報については、[CI/CDパイプラインのデバッグ](../../ci/debugging.md)を参照してください。

### `/rebase`クイックアクション後の`Unmergeable state` {#unmergeable-state-after-rebase-quick-action}

`/rebase`コマンドはバックグラウンドタスクをスケジュールします。タスクは、ソースブランチの変更をターゲットブランチの最新のコミットにリベースしようとします。`/rebase`[クイックアクション](../../user/project/quick_actions.md#issues-merge-requests-and-epics)を使用後にこのエラーが表示された場合は、リベースをスケジュールできません。

```plaintext
This merge request is currently in an unmergeable state, and cannot be rebased.
```

このエラーは、次のいずれかの条件に当てはまる場合に発生します。

- ソースブランチとターゲットブランチの間に競合があります。
- ソースブランチにコミットが含まれていません。
- ソースブランチまたはターゲットブランチが存在しません。
- エラーが発生し、差分が生成されませんでした。

`unmergeable state`エラーを解決するには:

1. マージコンフリクトを解決します。
1. ソースブランチが存在し、コミットがあることを確認します。
1. ターゲットブランチが存在することを確認します。
1. 差分が生成済みであることを確認します。

### `/rebase`の後に無視される`/merge`クイックアクション {#merge-quick-action-ignored-after-rebase}

`/rebase`が使用されている場合、リベースの前にソースブランチがマージまたは削除される競合状態を回避するために、`/merge`は無視されます。
