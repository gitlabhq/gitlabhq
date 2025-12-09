---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitリモートURLを更新する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitリモートリポジトリのURLを更新するのは、次のような場合です:

- 別のGitリポジトリホストから既存のプロジェクトをインポートした場合。
- 新しいドメイン名で、組織がプロジェクトを新しいGitLabインスタンスに移行した場合。
- プロジェクトが同じGitLabインスタンス内の新しいパスに名前変更された場合。

{{< alert type="note" >}}

古いリモートリポジトリからの既存のローカル実行コピーがない場合は、このチュートリアルは不要です。代わりに、新しいGitLabのURLからプロジェクトをクローンできます。

{{< /alert >}}

このチュートリアルでは、ローカルリポジトリのリモートURLを、次のことを行わずに更新する方法について説明します:

- 未完了のローカルでの変更を失うことなく。
- GitLabにまだ公開されていない変更を失うことなく。
- 新しいURLからリポジトリの新しいクローン実行コピーを作成せずに。

このチュートリアルでは、`git-remote`コマンドを使用して[リモートおよび追跡されたリポジトリを管理](https://git-scm.com/docs/git-remote)します。

GitリモートURLを更新するには、以下を実行します:

- [既存および新規URLを特定](#determine-existing-and-new-urls)
- [GitリモートURLを更新する](#update-git-remote-urls)
- [（オプション）元のリモートURLを保持](#optional-keep-original-remote-urls)

## はじめる前 {#before-you-begin}

以下が必要です:

- Gitリポジトリと新しいGitLabのURLを持つGitLabプロジェクト。
- 新しいGitLabのURLに移行するプロジェクトのクローン作成されたローカル実行コピー。
- Gitが[ローカルマシンにインストール](../../topics/git/how_to_install_git/_index.md)されていること。
- ローカルマシンのコマンドラインインターフェース（CLI）へのアクセス。macOSでは、ターミナルを使用できます。Windowsでは、PowerShellを使用できます。Linuxユーザーはおそらく、システムのCLIをよくご存じでしょう。
- GitLabの認証情報:
  - GitリモートURLを更新するには、GitLabで認証する必要があります。GitLabアカウントでユーザー名とパスワードによる基本的な認証を使用している場合は、[2要素認証（2FA）](../../user/profile/account/two_factor_authentication.md)を無効にして、CLIから認証を行う必要があります。または、[SSHキーを使用してGitLabで認証する](../../user/ssh.md)こともできます。

## 既存および新規URLを特定 {#determine-existing-and-new-urls}

GitリモートURLを更新するには、リポジトリの既存および新しいURLを特定します:

1. ターミナルまたはコマンドプロンプトを開きます。

1. ローカルリポジトリの実行コピーに移動します。ディレクトリを変更するには、`cd`を使用します:

   ```shell
   cd <repository-name>
   ```

1. 各リポジトリには、`origin`というデフォルトのリモートがあります。現在のリモート_フェッチ_および_プッシュ_ URLをリモートリポジトリで表示するには、以下を実行します:

   ```shell
   git remote -v
   ```

1. 返されたURLをコピーしてメモしておきます。通常、これらは同一です。

1. 新しいURLを取得します:
   1. GitLabに移動します。
   1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
   1. 左側のサイドバーで、**コード** > **リポジトリ**を選択して、プロジェクトの**リポジトリ**ページに移動します。
   1. 右上隅で**コード**を選択します。
   1. `git`での認証とクローン作成に使用する方法に応じて、HTTPSまたはSSH URLのいずれかをコピーします。不明な場合は、前の手順の`origin` URLと同じ方法を使用します。
   1. コピーしたURLをメモしておきます。

## GitリモートURLを更新する {#update-git-remote-urls}

GitリモートURLを更新するには:

1. ターミナルまたはコマンドプロンプトを開きます。

1. ローカルリポジトリの実行コピーに移動します。ディレクトリを変更するには、`cd`を使用します:

   ```shell
   cd <repository-name>
   ```

1. リモートURLを更新し、`<new_url>`をコピーした新しいリポジトリURLに置き換えます:

   ```shell
   git remote set-url origin <new_url>
   ```

1. リモートURLの更新が成功したことを確認します。次のコマンドは、フェッチとプッシュの両方の操作に対して新しいURLを表示し、ローカルブランチをリストし、GitLabに追跡されていることを確認します:

   ```shell
   git remote show origin
   ```

   - 更新が失敗した場合は、前の手順に戻り、正しい`<new_url>`があることを確認して、もう一度試してください。

複数のリポジトリのリモートURLを更新するには:

1. `git remote set-url`コマンドを使用します。`origin`を、更新するリモートの名前に置き換えます。例: 

   ```shell
   git remote set-url <remote_name> <new_url>
   ```

1. 各リモートURLの更新を確認します:

   ```shell
   git remote show <remote_name>
   ```

リモートURLを更新した後、通常どおりGitコマンドを引き続き使用できます。次の`git fetch`、`git pull`、または`git push`はGitLabからの新しいURLを使用します。

おめでとうございます。リポジトリのリモートURLが正常に更新されました。

## （オプション）元のリモートURLを保持 {#optional-keep-original-remote-urls}

プロジェクトには、複数のリモートの場所がある場合があります。たとえば、GitHubでホストされているプロジェクトからフォークしたリポジトリがあり、GitHubにプルリクエストを行う前にGitLabで自分のフォークで作業したいとします。

元のリモートURLを更新に加えて保持し、新旧両方のリモートURLを維持するには、既存のリモートを変更する代わりに、新しいリモートを追加できます。

このアプローチを使用すると、元のリポジトリへのアクセスを維持しながら、新しいURLに段階的に移行できます。

新しいリモートURLを追加するには:

1. ターミナルまたはコマンドプロンプトを開きます。

1. ローカルリポジトリの実行コピーに移動します。

1. 新しいリモートURLを追加します。`<new_remote_name>`を新しいリモートの名前に置き換えます（たとえば、`new-origin`）、`<new_url>`を新しいリポジトリURLに置き換えます:

   ```shell
   git remote add <new_remote_name> <new_url>
   ```

1. 新しいリモートが追加されたことを確認します:

   ```shell
   git remote -v
   ```

これで、元のリモートと新しいリモートの両方を使用できます。例: 

- 元のリモートにプッシュするには：`git push origin main`
- 新しいリモートにプッシュするには：`git push <new_remote_name> main`
