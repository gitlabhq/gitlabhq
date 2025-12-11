---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 直接コントリビュートする権限がないアップストリームリポジトリに変更をコントリビュートしたい場合は、Gitリポジトリをフォークします。
title: フォークを更新する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

フォークとは、リポジトリとそのすべてのブランチの個人用コピーであり、任意のネームスペースに作成します。フォークを使用すると、アクセスできない別のプロジェクトに変更を提案できます。詳細については、[フォーク型ワークフロー](../../user/project/repository/forking_workflow.md)を参照してください。

[GitLab UI](../../user/project/repository/forking_workflow.md#from-the-ui)でフォークを更新することもできます。

前提要件:

- ローカルマシンに[Gitクライアントをダウンロードしてインストール](how_to_install_git/_index.md)する必要があります。
- 更新するリポジトリの[フォークを作成](../../user/project/repository/forking_workflow.md#create-a-fork)する必要があります。

コマンドラインからフォークを更新するには、次の手順に従います:

1. `upstream`リモートリポジトリがフォークに設定されているかどうかを確認します:

   1. まだローカルコピーしていない場合は、フォークをクローンします。詳細については、[リポジトリのクローン](clone.md)を参照してください。
   1. フォークに設定されているリモートを表示します:

      ```shell
      git remote -v
      ```

   1. フォークに元のリポジトリを指すリモートがない場合は、次のいずれかの例を使用して、アップストリームというリモートを設定します:

       ```shell
       # Set any repository as your upstream after editing <upstream_url>
       git remote add upstream <upstream_url>

       # Set the main GitLab repository as your upstream
       git remote add upstream https://gitlab.com/gitlab-org/gitlab.git
       ```

1. フォークを更新する:

   1. ローカルコピーで、[デフォルトブランチ](../../user/project/repository/branches/default.md)をチェックアウトします。`main`をデフォルトブランチの名前に置き換えます:

      ```shell
      git checkout main
      ```

      {{< alert type="note" >}}

      Gitがアンステージの変更を識別した場合は、続行する前に[コミットまたはスタッシュ](commit.md)してください。

      {{< /alert >}}

   1. アップストリームリポジトリから変更をフェッチします:

      ```shell
      git fetch upstream
      ```

   1. 変更をフォークにプルします。`main`を、更新するブランチの名前に置き換えます:

      ```shell
      git pull upstream main
      ```

   1. サーバー上のフォークリポジトリに変更をプッシュします:

      ```shell
      git push origin main
      ```

## フォークをまたいだコラボレーション {#collaborate-across-forks}

GitLabでは、アップストリームプロジェクトのメンテナーとフォークのオーナー間のコラボレーションが可能です。詳細については、以下を参照してください:

- [フォークをまたいでのマージリクエストでのコラボレーション](../../user/project/merge_requests/allow_collaboration.md)
  - [アップストリームメンバーからのコミットを許可](../../user/project/merge_requests/allow_collaboration.md#allow-commits-from-upstream-members)
  - [アップストリームメンバーからのコミットを禁止](../../user/project/merge_requests/allow_collaboration.md#prevent-commits-from-upstream-members)

### アップストリームメンバーとしてフォークにプッシュします {#push-to-a-fork-as-an-upstream-member}

次の場合、フォークしたリポジトリのブランチに直接プッシュできます:

- マージリクエストの作成者が、アップストリームメンバーからのコントリビュートを有効にしている。
- アップストリームプロジェクトのデベロッパーロール以上を持っている。

次の例では、以下が実行されます:

- フォークリポジトリのURLは`git@gitlab.com:contributor/forked-project.git`です。
- マージリクエストのブランチは`fork-branch`です。

コントリビューターのマージリクエストにコミットを変更または追加するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを見つけます。
1. 右上隅で、**コード**を選択し、**ブランチをチェックアウト**を選択します。
1. ダイアログで、**コピー**（{{< icon name="copy-to-clipboard" >}}）を選択します。
1. ターミナルで、クローンされたリポジトリのバージョンに移動し、コマンドをペーストします。例:

   ```shell
   git fetch "git@gitlab.com:contributor/forked-project.git" 'fork-branch'
   git checkout -b 'contributor/fork-branch' FETCH_HEAD
   ```

   これらのコマンドは、フォークプロジェクトからブランチをフェッチし、作業するためのローカルコピーのブランチを作成します。

1. ブランチのローカルコピーに変更を加え、コミットします。
1. プッシュローカルコピーの変更をフォークプロジェクトにプッシュします。次のコマンドは、ローカルブランチ`contributor/fork-branch`を、`fork-branch`ブランチの`git@gitlab.com:contributor/forked-project.git`リポジトリにプッシュします:

   ```shell
   git push git@gitlab.com:contributor/forked-project.git contributor/fork-branch:fork-branch
   ```

   いずれかのコミットを修正またはスカッシュした場合は、`git push --force`を使用する必要があります。このコマンドはコミットの履歴を書き換えるため、注意して進めてください。

   ```shell
   git push --force git@gitlab.com:contributor/forked-project.git contributor/fork-branch:fork-branch
   ```

   コロン（`:`）は、ソースブランチと宛先ブランチを指定します。スキームは次のとおりです:

   ```shell
   git push <forked_repository_git_url> <local_branch>:<fork_branch>
   ```

## 関連トピック {#related-topics}

- [フォーク型ワークフロー](../../user/project/repository/forking_workflow.md)
  - [フォークを作成](../../user/project/repository/forking_workflow.md#create-a-fork)
  - [フォークのリンクを解除](../../user/project/repository/forking_workflow.md#unlink-a-fork)
- [フォークをまたいでのマージリクエストでのコラボレーション](../../user/project/merge_requests/allow_collaboration.md)
- [マージリクエスト](../../user/project/merge_requests/_index.md)
