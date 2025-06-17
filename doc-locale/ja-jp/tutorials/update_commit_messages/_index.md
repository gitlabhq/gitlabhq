---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: Gitコミットメッセージを更新する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ブランチにいくつかのコミットを行った後、1つ以上のコミットメッセージを更新する必要があることに気付くことがあります。タイプミスを見つけた場合や、自動化によってコミットメッセージがプロジェクトの[コミットメッセージガイドライン](../../development/contributing/merge_request_workflow.md#commit-messages-guidelines)に一部準拠していないことが警告された場合などです。

コマンドラインインターフェース（CLI）からGitを使用する練習をあまりしていない場合、メッセージの更新は難しい場合があります。ただし、今までGitLab UIでのみ作業していた場合でも、心配する必要はありません。次の手順に従ってCLIを使用できます。

このチュートリアルでは、次の2つの場合にコミットメッセージを書き換える方法について説明します。

- GitLab UIでのみ作業している場合は、手順1から開始します。
- すでにローカルでリポジトリをクローンしている場合は、手順1を省略して手順2に進むことができます。

任意の数のコミットメッセージを書き換えるには:

1. [プロジェクトのリポジトリをローカルマシンにクローンします](#clone-your-repository-to-your-local-machine)。
1. [ブランチをフェッチしてローカルでチェックアウトします](#fetch-and-check-out-your-branch)。
1. [コミットメッセージを更新します](#update-the-commit-messages)。
1. [変更をGitLabにプッシュします](#push-the-changes-up-to-gitlab)。

## はじめる前

以下が必要です。

- 更新するコミットを含んでいるGitブランチがあるGitLabプロジェクト。
- Gitが[ローカルマシンにインストール](../../topics/git/how_to_install_git/_index.md)されていること。
- ローカルマシンのコマンドラインインターフェース（CLI）へのアクセス。macOSでは、ターミナルを使用できます。Windowsでは、PowerShellを使用できます。Linuxユーザーはおそらく、システムのCLIをよくご存じでしょう。
- システムのデフォルトのエディタに精通していること。このチュートリアルでは、エディタがVimであることを前提としていますが、どのテキストエディタでも動作するはずです。Vimに慣れていない場合は、[Getting started with Vim](https://opensource.com/article/19/3/getting-started-vim)（Vimの使用を開始する）の手順1–2で、このチュートリアルの後半で使用するすべてのコマンドについて説明されているので参考にしてください。
- コミットメッセージを上書きする権限。同じブランチで複数の人が作業している場合は、まずコミットを更新しても問題ないことを他の作業者と確認する必要があります。一部の組織では、コミットの書き換えは破壊的な変更と見なされるため、禁止されている場合があります。

最後の手順でコミットメッセージを上書きするには、GitLabと認証を行う必要があります。GitLabアカウントでユーザー名とパスワードによる基本的な認証を使用している場合は、CLIから認証を行うには[2要素認証（2FA）](../../user/profile/account/two_factor_authentication.md)を無効にする必要があります。または、[SSH鍵を使用してGitLabと認証を行う](../../user/ssh.md)こともできます。

## リポジトリをローカルマシンにクローンする

最初の手順は、ローカルマシンにリポジトリのクローンを取得することです。

1. GitLabで、プロジェクトの概要ページの右上隅にある**コード**を選択します。
1. ドロップダウンリストで、次の項目の横にある{{< icon name="copy-to-clipboard" >}}を選択して、リポジトリのURLをコピーします。
   - GitLabアカウントがユーザー名とパスワードによる基本的な認証を使用している場合は、**HTTPSでクローン**
   - SSHを使用してGitLabと認証を行う場合は、**SSHでクローン**
1. 次に、ローカルマシンのCLI（ターミナル、PowerShellなど）に切り替え、リポジトリをクローンするディレクトリに移動します。たとえば、`/users/my-username/my-projects/`です。
1. `git clone`を実行し、前にコピーしたURLを貼り付けます。次に例を示します。

   ```shell
   git clone https://gitlab.com/my-username/my-awesome-project.git
   ```

   これにより、リポジトリは`my-awesome-project/`という新しいディレクトリにクローンされます。

リポジトリがコンピュータに保存されたので、Git CLIコマンドを使用する準備ができました。

## ブランチをフェッチしてチェックアウトする

次に、更新するコミットを含んでいるブランチをチェックアウトする必要があります。

1. 前の手順と同じCLIの場所にいることを前提として、`cd`でプロジェクトディレクトリに変更します。

   ```shell
   cd my-awesome-project
   ```

1. オプション。リポジトリをクローンしたばかりの場合は、ブランチもすでにコンピュータ上にあるはずです。ただし、以前にリポジトリをクローンしていて、この手順に直接進んだ場合は、次のコマンドでブランチをフェッチする必要がある場合があります。

   ```shell
   git fetch origin my-branch-name
   ```

1. ブランチがローカルシステムにあることは確かであるため、そのブランチに切り替えます。

   ```shell
   git checkout my-branch-name
   ```

1. `git log`で正しいブランチであることを確認し、最近のコミットがGitLabのブランチ内のコミットと一致することを確認します。ログを終了するには、`q`を使用します。

## コミットメッセージを更新する

これで、コミットメッセージを更新する準備ができました。

1. GitLabで、コミット履歴をどこまで遡る必要があるかを確認します。

   - ブランチに対してマージリクエストがすでにオープンされている場合は、**コミット**タブを確認して、コミットの合計数を使用できます。
   - ブランチからのみ作業している場合:
     1. **コード > コミット**に移動します。
     1. 左上にあるドロップダウンリストを選択し、ブランチを見つけます。
     1. 更新する最も古いコミットを見つけ、どれくらい前のコミットかを確認します。たとえば、2番目と4番目のコミットを更新する場合、カウントは4になります。

1. コマンドラインインターフェース（CLI）から、インタラクティブなリベースを開始します。これは、コミットを更新するGitプロセスです。前の手順で確認したコミットのカウントを`HEAD~`の最後に追加します。次に例を示します。

   ```shell
   git rebase -i HEAD~4
   ```

   この例では、Gitはブランチ内の最近の4つのコミットを選択して更新します。

1. Gitはテキストエディタを起動し、選択したコミットをリストします。たとえば、次のように表示されます。

   ```shell
   pick a0cea50 Fix broken link
   pick bb84712 Update milestone-plan.md
   pick ce11fad Add list of maintainers
   pick d211d03 update template.md

   # Rebase 1f5ec88..d211d03 onto 1f5ec88 (4 commands)
   #
   # Commands:
   # p, pick <commit> = use commit
   # r, reword <commit> = use commit, but edit the commit message
   # e, edit <commit> = use commit, but stop for amending
   # s, squash <commit> = use commit, but meld into previous commit
   # f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
   #                    commit's log message, unless -C is used, in which case
   # [and so on...]
   ```

1. `pick`コマンドは、変更せずにコミットを使用するようにGitに指示します。更新するコミットに対するコマンドを`pick`から`reword`に変更する必要があります。`i`と入力して`INSERT`モードに入り、テキストを編集します。

   たとえば、上記の例で2番目と4番目のコミットのテキストを更新するには、次のように編集します。

   ```shell
   pick a0cea50 Fix broken link
   reword bb84712 Update milestone-plan.md
   pick ce11fad Add list of maintainers
   reword d211d03 update template.md
   ```

1. 編集したテキストを保存します。<kbd>Escape</kbd>キーを押して`INSERT`モードを終了し、`:wq`と入力して<kbd>Enter</kbd>キーを押し、保存して終了します。

1. Gitはコミットを1つずつ処理し、選択したコマンドを適用します。`pick`を使用したコミットは、変更されずにブランチに再度追加されます。Gitは`reword`を使用したコミットに到達すると、停止して再度テキストエディタを開きます。ここでコミットメッセージのテキストを更新します。

   - 1行のコミットメッセージのみが必要な場合は、必要に応じてテキストを更新します。次に例を示します。

     ```plaintext
     Update the monthly milestone plan
     ```

   - コミットメッセージにタイトルと本文が必要な場合は、空白行で区切ります。次に例を示します。

     ```plaintext
     Update the monthly milestone plan

     Make the milestone plan clearer by listing the responsibilities
     of each maintainer.
     ```

   保存して終了すると、Gitはコミットメッセージを更新し、次のコミットを順番に処理します。完了すると、`Successfully rebased and update refs/heads/my-branch-name`というメッセージが表示されます。

1. オプション。コミットメッセージが更新されたことを確認するには、`git log`を実行し、下にスクロールしてコミットメッセージを確認します。

## 変更をGitLabにプッシュする

残りの作業は、これらの変更をGitLabにプッシュすることです。

1. CLIから、変更をGitLabにプッシュします。コミットが更新されたため、`-f`「強制プッシュ」オプションを使用する必要があります。強制プッシュはGitLabの古いコミットを上書きします。

   ```shell
   git push -f origin
   ```

   GitLabでコミットメッセージを上書きする前に、ターミナルからユーザー名とパスワードの入力を求められる場合があります。

1. GitLabのプロジェクトで、コミットが更新されたことを確認します。

   - ブランチに対してマージリクエストがすでにオープンされている場合は、**コミット**タブを確認します。
   - ブランチからのみ作業している場合:
     1. **コード > コミット**に移動します。
     1. 左上にあるドロップダウンリストを選択し、ブランチを見つけます。
     1. リストの関連するコミットが更新されたことを確認します。

おめでとうございます。コミットメッセージを正常に更新し、GitLabにプッシュできました。
