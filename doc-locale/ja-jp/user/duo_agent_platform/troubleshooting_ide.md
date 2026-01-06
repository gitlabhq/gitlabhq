---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: IDEでのエージェントプラットフォームのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

IDEでGitLab Duo Agent Platformを使用している場合、次のイシューが発生する可能性があります。

## 一般的なガイダンス {#general-guidance}

まず、GitLab Duoがオンになっていることと、適切に接続されていることを確認します。

- [前提条件](_index.md#prerequisites)を満たしていることを確認してください。
- 作業するブランチがチェックアウトされていることを確認します。
- IDEで必要な設定がオンになっていることを確認します。
- [管理者モードが無効になっている](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session)ことを確認してください。

## ネットワークの問題 {#network-issues}

ログに`/-/cable` WebSocketエンドポイントではなく、`HTTP/1.1`の応答がGitLab Duoから表示される場合は、WebSocket接続がブロックされている可能性があります。

GitLabインスタンスは、IDEクライアントからの受信WebSocket接続を許可する必要があります。ネットワーク管理者に、これが問題と思われる場合は、[WebSocketトラフィックをGitLabインスタンスに許可する](../../administration/gitlab_duo/setup.md#allow-inbound-connections-from-clients-to-the-gitlab-instance)ように依頼してください。

## VS Codeでデバッグログを表示 {#view-debugging-logs-in-vs-code}

VS Codeでは、デバッグログを表示して、いくつかのイシューのトラブルシューティングを行うことができます。

1. ローカルデバッグログを開きます:
   - macOSの場合: <kbd>Command</kbd>+<kbd>,</kbd>
   - WindowsおよびLinuxの場合: <kbd>Control</kbd>+<kbd>,</kbd>
1. 設定**GitLab: を検索します: デバッグ**し、有効にします。
1. 言語サーバーログを開きます:
   1. VS Codeで、**表示** > **Output**（出力）を選択します。
   1. 下部の出力パネルの右上隅で、リストから**GitLab Workflow**または**GitLab Language Server**を選択します。
1. エラー、警告、接続のイシュー、または認証の問題がないか確認してください。

## VS Codeの設定 {#vs-code-configuration}

リポジトリがVS Codeで適切に設定され、接続されていることを確認するために、いくつかのことを試すことができます。

### GitLab Workflow拡張機能でプロジェクトを表示 {#view-the-project-in-the-gitlab-workflow-extension}

まず、VS Code用のGitLab Workflow拡張機能で正しいプロジェクトが選択されていることを確認します。

1. VS Codeの左側のサイドバーで、**GitLab Workflow** ({{< icon name="tanuki" >}})を選択します。
1. プロジェクトがリストされ、選択されていることを確認します。

プロジェクト名の横にエラーメッセージが表示された場合は、それを選択して、更新が必要な内容を表示します。

たとえば、複数のリポジトリがあり、1つを選択する必要がある場合や、リポジトリがまったくない場合があります。

#### Gitリポジトリなし {#no-git-repository}

ワークスペースにGitリポジトリが初期化されていない場合は、新しいリポジトリを作成する必要があります:

1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="branch" >}}）を選択します。
1. **Initialize Repository**を選択します。

リポジトリが初期化されると、**Source Control**（ソース管理）ビューに名前が表示されます。

#### GitLabリモートのないGitリポジトリ {#git-repository-with-no-gitlab-remote}

Gitリポジトリがあるかもしれませんが、GitLabに適切に接続されていません。

1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="branch" >}}）を選択します。
1. **Source Control**（ソース管理）のラベルで、右クリックして**リポジトリ**を選択します。
1. お使いのリポジトリの横にある省略記号 ({{< icon name=ellipsis_h >}}) を選択し、**リモート** > **Add Remote**（リモートの追加） を選択します。
1. GitLabプロジェクトURLを入力します。
1. 新しく追加されたリモートをアップストリームとして選択します。

#### 複数のGitLabリモート {#multiple-gitlab-remotes}

お使いのリポジトリには、複数のGitLabリモートが設定されている可能性があります。正しいものを選択するには:

1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="branch" >}}）を選択します。
1. ステータスバーで、現在のリモート名を選択します。
1. リストから、適切なGitLabリモートを選択します。
1. 選択したリモートが、GitLabのグループネームスペースに属していることを確認します。

#### 複数のGitLabプロジェクト {#multiple-gitlab-projects}

VS Codeのワークスペースに複数のGitLabプロジェクトが含まれている場合は、使用していないすべてのプロジェクトを閉じることができます。

プロジェクトを閉じるには:

1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="branch" >}}）を選択します。
1. リポジトリが表示されていることを確認します。**Source Control**（ソース管理）のラベルで右クリックし、**リポジトリ**を選択します。
1. 閉じたいリポジトリを右クリックし、**Close Repository**（リポジトリを閉じる）を選択します。

#### SSHカスタムエイリアスを持つGitリモート {#git-remote-with-ssh-custom-alias}

リポジトリのリモートがSSHカスタムエイリアス (たとえば、`git@my-work-gitlab:group/project.git`ではなく`git@gitlab.com:group/project.git`) を使用している場合、GitLab Workflow拡張機能がリポジトリをGitLabプロジェクトに正しく一致させない可能性があります。

この問題を解決するには、次のいずれかの操作を実行します:

- カスタムエイリアスなしでSSHまたはHTTPを使用するようにリモートを変更します。
- GitLab Duo Agent Platformのデフォルトネームスペースを設定します。

デフォルトネームスペースを設定するには:

1. [プロジェクトがあるネームスペースを特定します](../namespace/_index.md#determine-which-type-of-namespace-youre-in)。
1. VS Codeで、**ファイル** > **設定** > **設定**を選択します。
1. **GitLab** > **Duo Agent Platform: を検索します: デフォルトのネームスペース**を入力し、ネームスペースを入力します。

### グループネームスペースにないプロジェクト {#project-not-in-a-group-namespace}

GitLab Duo Agent Platformでは、プロジェクトがグループネームスペースに属している必要があります。

プロジェクトがあるネームスペースを特定するには、[URLをご覧ください](../namespace/_index.md#determine-which-type-of-namespace-youre-in)。

必要に応じて、[プロジェクトをグループネームスペースに転送する](../../tutorials/move_personal_project_to_group/_index.md#move-your-project-to-a-group)ことができます。

## IDEコマンドが失敗するか、無期限に実行されます {#ide-commands-fail-or-run-indefinitely}

IDEでGitLab Duoチャット (エージェント型) またはソフトウェア開発フローを使用している場合、GitLab Duoがループに陥ったり、コマンドの実行が困難になったりする可能性があります。

このイシューは、`Oh My ZSH!`や`powerlevel10k`のようなシェルテーマまたはインテグレーションを使用している場合に発生する可能性があります。GitLab Duoエージェントがターミナルを起動すると、テーマまたはインテグレーションによってコマンドが適切に実行されない可能性があります。

回避策として、エージェントから送信されたコマンドには、よりシンプルなテーマを使用してください。[Issue 2070](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/2070)は、この動作の改善を追跡するため、この回避策は不要になりました。

### `.zshrc`ファイルを編集 {#edit-your-zshrc-file}

VS CodeとJetBrains IDEでは、エージェントから送信されたコマンドを実行するときに、よりシンプルなテーマを使用するように`Oh My ZSH!`または`powerlevel10k`を設定します。IDEによって公開された環境変数を使用して、これらの値を設定できます。

このコードを含めるように`~/.zshrc`ファイルを編集します:

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

### Bashシェルを編集 {#edit-your-bash-shell}

VS CodeまたはJetBrains IDEでは、Bashの詳細なプロンプトをオフにして、エージェントがそれらを初期化しないようにすることができます。このコードを含めるように`~/.bashrc`ファイルまたは`~/.bash_profile`ファイルを編集します:

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

## まだ問題がありますか？ {#still-having-issues}

支援が必要な場合は、GitLab管理者にお問い合わせください。
