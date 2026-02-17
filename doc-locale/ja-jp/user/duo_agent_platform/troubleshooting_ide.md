---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: IDEでのエージェントプラットフォームのトラブルシューティング
---

IDEでGitLab Duo Agent Platformを使用している場合、次の問題が発生する可能性があります。

## 一般的なガイダンス {#general-guidance}

まず、GitLab Duoがオンになっていること、IDEがGitLabに適切に接続されていることを確認します。

- [前提条件](_index.md#prerequisites)を満たしていることを確認してください。
- 作業対象のブランチがチェックアウトされていることを確認してください。
- IDEで必要な設定がオンになっていることを確認してください。
- [管理者モードが無効になっている](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session)ことを確認してください。

## ネットワークの問題 {#network-issues}

ログに`/-/cable` WebSocketエンドポイントではなく、GitLab Duoからの`HTTP/1.1`レスポンスが表示される場合は、WebSocket接続がブロックされている可能性があります。

GitLabインスタンスは、IDEクライアントからの受信WebSocket接続を許可する必要があります。これによって問題が発生していると思われる場合は、[GitLabインスタンスへのWebSocketトラフィックを許可する](../../administration/gitlab_duo/configure/gitlab_self_managed.md#allow-inbound-connections-from-clients-to-the-gitlab-instance)ようネットワーク管理者に依頼してください。

## VS Codeでデバッグログを表示する {#view-debugging-logs-in-vs-code}

VS Codeでは、デバッグログを表示して、いくつかの問題のトラブルシューティングを行えます。

1. ローカルのデバッグログを開きます:
   - macOSの場合: <kbd>Command</kbd>+<kbd>,</kbd>
   - WindowsおよびLinuxの場合: <kbd>Control</kbd>+<kbd>,</kbd>
1. **GitLab: Debug**設定を検索し、有効にします。
1. 言語サーバーのログを開きます:
   1. VS Codeで、**View** > **Output**を選択します。
   1. 下部の出力パネルの右上隅で、リストから**GitLab Workflow**または**GitLab Language Server**を選択します。
1. エラー、警告、接続の問題、または認証の問題がないか確認します。

## VS Codeの設定 {#vs-code-configuration}

VS Codeでリポジトリが適切に設定され、接続されていることを確認するために、いくつかの方法を試すことができます。

### GitLab Workflow拡張機能でプロジェクトを表示する {#view-the-project-in-the-gitlab-workflow-extension}

まず、VS Code用GitLab Workflow拡張機能で、正しいプロジェクトが選択されていることを確認します。

1. VS Codeの左側のサイドバーで、**GitLab Workflow**（{{< icon name="tanuki" >}}）を選択します。
1. プロジェクトがリストに表示され、選択されていることを確認します。

プロジェクト名の横にエラーメッセージが表示されている場合は、それを選択して、更新が必要な内容を確認します。

たとえば、複数のリポジトリがあり、その中から1つを選択する必要がある場合や、リポジトリがまったく存在しない場合があります。

#### Gitリポジトリがない {#no-git-repository}

ワークスペースに初期化されたGitリポジトリが存在しない場合は、新しいリポジトリを作成する必要があります:

1. 左側のサイドバーで、**Source Control**（{{< icon name="branch" >}}）を選択します。
1. **Initialize Repository**を選択します。

リポジトリが初期化されると、**Source Control**ビューに名前が表示されます。

#### GitLabリモートが設定されていないGitリポジトリ {#git-repository-with-no-gitlab-remote}

Gitリポジトリが存在していても、GitLabに適切に接続されていない場合があります。

1. 左側のサイドバーで、**Source Control**（{{< icon name="branch" >}}）を選択します。
1. **Source Control**ラベルを右クリックして、**Repositories**を選択します。
1. お使いのリポジトリの横にある省略記号（{{< icon name=ellipsis_h >}}）を選択し、**Remote** > **Add Remote**を選択します。
1. GitLabプロジェクトのURLを入力します。
1. 新しく追加したリモートをアップストリームとして選択します。

#### 複数のGitLabリモート {#multiple-gitlab-remotes}

リポジトリに、複数のGitLabリモートが設定されている場合があります。正しいリポジトリを選択するには:

1. 左側のサイドバーで、**Source Control**（{{< icon name="branch" >}}）を選択します。
1. ステータスバーで、現在のリモート名を選択します。
1. リストから、適切なGitLabリモートを選択します。
1. 選択したリモートが、GitLabのグループネームスペースに属していることを確認します。

#### 複数のGitLabプロジェクト {#multiple-gitlab-projects}

VS Codeのワークスペースに複数のGitLabプロジェクトが含まれている場合、使用していないプロジェクトをすべて閉じたほうがよい場合があります。

プロジェクトを閉じるには:

1. 左側のサイドバーで、**Source Control**（{{< icon name="branch" >}}）を選択します。
1. リポジトリが表示されていることを確認します: **Source Control**ラベルを右クリックして、**Repositories**を選択します。
1. 閉じるリポジトリを右クリックし、**Close Repository**を選択します。

#### SSHカスタムエイリアスを使用したGitリモート {#git-remote-with-ssh-custom-alias}

リポジトリのリモートでSSHカスタムエイリアス（たとえば、`git@gitlab.com:group/project.git`の代わりに`git@my-work-gitlab:group/project.git`）を使用している場合、GitLab Workflow拡張機能が、リポジトリをGitLabプロジェクトに正しく関連付けられない可能性があります。

この問題を解決するには、次の操作を実行します:

- カスタムエイリアスなしでSSHを使用する、またはHTTPを使用するようにリモートを変更する。
- Agent Platformのデフォルトネームスペースを設定する。

デフォルトネームスペースを設定するには:

1. [プロジェクトが属するネームスペースを特定します](../namespace/_index.md#determine-which-type-of-namespace-youre-in)。
1. VS Codeで、**File** > **Preferences** > **Settings**を選択します。
1. **GitLab** > **Duo Agent Platform: Default Namespace**を検索し、ネームスペースを入力します。

### グループネームスペースに属していないプロジェクト {#project-not-in-a-group-namespace}

GitLab Duo Agent Platformでは、プロジェクトがグループネームスペースに属している必要があります。

プロジェクトが属しているネームスペースを特定するには、[URLを確認](../namespace/_index.md#determine-which-type-of-namespace-youre-in)します。

必要に応じて、[プロジェクトをグループネームスペースに転送](../../tutorials/move_personal_project_to_group/_index.md#move-your-project-to-a-group)することができます。

## IDEコマンドが失敗する、または無期限に実行される {#ide-commands-fail-or-run-indefinitely}

IDEでGitLab Duo Chat（エージェント）またはソフトウェア開発フローを使用している場合、GitLab Duoがループ状態に陥ったり、コマンドの実行が正常に行われなくなったりすることがあります。

この問題は、`Oh My ZSH!`や`powerlevel10k`などのシェルテーマまたはインテグレーションを使用している場合に発生することがあります。GitLab Duoエージェントがターミナルを起動すると、これらのテーマやインテグレーションが原因で、コマンドが適切に実行されない場合があります。

回避策として、エージェントが送信するコマンドには、よりシンプルなテーマを使用してください。この動作の改善については[イシュー2070](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/2070)で追跡され、この回避策は不要になりました。

### `.zshrc`ファイルを編集する {#edit-your-zshrc-file}

VS CodeおよびJetBrains IDEでは、エージェントから送信されたコマンドを実行する際によりシンプルなテーマを使用するように、`Oh My ZSH!`や`powerlevel10k`を設定してください。IDEによって公開された環境変数を使用して、これらの値を設定できます。

`~/.zshrc`ファイルを編集し、次のコードを追加します:

```shell
# ~/.zshrc

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# ...

# Decide whether to load a full terminal environment,
# or keep it minimal for agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" || "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]]; then
  echo "IDE agentic environment detected, not loading full shell integrations"
else
  # Oh My ZSH
  source $ZSH/oh-my-zsh.sh
  # Theme: Powerlevel10k
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  # Other integrations like syntax highlighting
fi

# Other setup, like PATH variables
```

### Bashシェルを編集する {#edit-your-bash-shell}

VS CodeまたはJetBrains IDEでは、Bashの高度なプロンプトをオフにして、エージェントがそれらを起動するのを防ぐことができます。`~/.bashrc`ファイルまたは`~/.bash_profile`ファイルを編集し、次のコードを追加します:

```shell
# ~/.bashrc or ~/.bash_profile

# Decide whether to load a full terminal environment,
# or keep it minimal for Agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" || "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]]; then
  echo "IDE agentic environment detected, not loading full shell integrations"

  # Keep only essential settings for agents
  export PS1='\$ '  # Minimal prompt

else
  # Load full Bash environment

  # Custom prompt (e.g., Starship, custom PS1)
  if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
  else
    # ... Add your own PS1 variable
  fi

  # Load additional integrations
fi

# Always load essential environment variables and aliases
```

## まだ問題が発生していますか？ {#still-having-issues}

サポートが必要な場合は、GitLab管理者にお問い合わせください。
