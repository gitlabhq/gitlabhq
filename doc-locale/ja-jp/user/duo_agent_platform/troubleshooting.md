---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoエージェントプラットフォームの問題のトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

統合開発環境（IDE）でGitLab Duoエージェントプラットフォームを使用している場合、次の問題が発生することがあります。

## 一般的なガイダンス {#general-guidance}

まず、GitLab Duoがオンになっていること、および適切に接続されていることを確認します。

- [前提条件](_index.md#prerequisites)を満たしていることを確認してください。
- 作業するブランチがチェックアウトされていることを確認します。
- IDEで必要な設定がオンになっていることを確認します。
- [管理者モードが無効になっている](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session)ことを確認してください。

## ネットワークの問題 {#network-issues}

ファイアウォールを使用するなどして、ネットワークがエージェントプラットフォームへの接続をブロックしている可能性があります。デフォルトでは、エージェントプラットフォームはgRPC（Google Remote Procedureコール）接続を使用します。ネットワークは、gRPCが機能するために、HTTP/2トラフィックをサービスに通過させる必要があります。

gRPCは、IDEで[WebSocket接続に変更](#use-websocket-connection-instead-of-grpc)できます。

gRPCを使用してエージェントプラットフォーム・サービスに接続できることを確認するには:

1. Google ChromeまたはFirefoxで、開発者ツールを開き、**ネットワーク**タブを選択します。
1. 列ヘッダーを右クリックして、**Protocol**（プロトコル）列を表示します。
1. アドレスバーに、`https://duo-workflow-svc.runway.gitlab.net/DuoWorkflow/ExecuteWorkflow`と入力します。
1. リクエストが成功し、**Protocol**（プロトコル）列にChromeでは`h2`、Firefoxでは`HTTP/2`が含まれていることを確認します。

リクエストが失敗した場合、またはHTTP/2プロトコルが表示されない場合:

- NetskopeやZscalerなどのセキュリティシステムが、トラフィックをブロックまたは検査するように設定されている可能性があります。
- HTTP/2プロトコルがHTTP/1.1にダウングレードされると、エージェントプラットフォームが正常に動作しなくなります。

この問題を修正するには、ネットワーク管理者に`https://duo-workflow-svc.runway.gitlab.net/DuoWorkflow/ExecuteWorkflow`を正しい許可リストに登録するか、トラフィック検査から除外するように依頼してください。

### gRPCの代わりにWebSocket接続を使用する {#use-websocket-connection-instead-of-grpc}

ネットワークの状況でgRPC接続が許可されない場合、VS CodeとJetBrains IDEでは、WebSocketが代替手段となります:

- VS Codeの場合:
  1. **File** > **Preferences** > **Settings**を選択します。
  1. **GitLab: GitLab Duo Agent Platform: Connection Type**設定を検索し、`WebSocket`を選択します。

- JetBrainsの場合:
  1. 上部のバーで、メインメニューを選択し、**設定**を選択します。
  1. 左側のサイドバーで、**ツール** > **GitLab Duo**を選択します。
  1. **GitLab Duo Agent Platform** > **Connection Type**（接続の種類）セクションで、`WebSocket`を選択します。

## VS Codeでデバッグログを表示する {#view-debugging-logs-in-vs-code}

VS Codeでは、デバッグログを表示して、いくつかの問題をトラブルシューティングできます。

1. ローカルデバッグログを開きます:
   - macOSの場合: <kbd>Command</kbd>+<kbd>,</kbd>
   - WindowsおよびLinuxの場合: <kbd>Control</kbd>+<kbd>,</kbd>
1. **GitLab: Debug**設定を検索して有効にします。
1. 言語サーバーログを開きます:
   1. VS Codeで、**表示** > **Output**（出力）を選択します。
   1. 下部の出力パネルの右上隅で、リストから**GitLab Workflow**または**GitLab Language Server**（GitLab言語サーバー）を選択します。
1. エラー、警告、接続の問題、または認証の問題がないか確認します。

## VS Codeの設定 {#vs-code-configuration}

いくつかの方法を試して、GitリポジトリがVS Codeで適切に設定され、接続されていることを確認できます。

### VS Code用GitLab Workflow拡張機能でプロジェクトを表示する {#view-the-project-in-the-gitlab-workflow-extension}

まず、VS CodeのVS Code用GitLab Workflow拡張機能で正しいプロジェクトが選択されていることを確認します。

1. VS Codeの左側のサイドバーで、**GitLab Workflow**（{{< icon name="tanuki" >}}）を選択します。
1. プロジェクトがリストされ、選択されていることを確認します。

プロジェクト名の横にエラーメッセージが表示された場合は、それを選択して、更新する必要があるものを表示します。

たとえば、複数のリポジトリがあり、1つを選択する必要がある場合や、リポジトリがまったくない場合があります。

#### Gitリポジトリがない {#no-git-repository}

ワークスペースに初期化されたGitリポジトリがない場合は、新しいリポジトリを作成する必要があります:

1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="branch" >}}）を選択します。
1. **Initialize Repository**（リポジトリの初期化）を選択します。

リポジトリが初期化されると、**Source Control**（ソース管理）ビューに名前が表示されます。

#### GitLabリモートがないGitリポジトリ {#git-repository-with-no-gitlab-remote}

Gitリポジトリがあっても、GitLabに適切に接続されていない可能性があります。

1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="branch" >}}）を選択します。
1. **Source Control**（ソース管理）ラベルで右クリックし、**リポジトリ**を選択します。
1. リポジトリの横にある省略記号（{{< icon name=ellipsis_h >}}）を選択し、次に**リモート** > **Add Remote**（リモートの追加）を選択します。
1. GitLabプロジェクトのURLを入力します。
1. 新しく追加されたリモートをアップストリームとして選択します。

#### 複数のGitLabリモート {#multiple-gitlab-remotes}

リポジトリに複数のGitLabリモートが設定されている可能性があります。正しいものを選択するには:

1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="branch" >}}）を選択します。
1. ステータスバーで、現在のリモート名を選択します。
1. リストから、適切なGitLabリモートを選択します。
1. 選択したリモートがGitLabのグループネームスペースに属していることを確認します。

#### 複数のGitLabプロジェクト {#multiple-gitlab-projects}

VS Codeワークスペースに複数のGitLabプロジェクトが含まれている場合は、使用していないすべてのプロジェクトを閉じるとよいでしょう。

プロジェクトを閉じるには:

1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="branch" >}}）を選択します。
1. リポジトリが表示されていることを確認します: **Source Control**（ソース管理）ラベルで右クリックし、**リポジトリ**を選択します。
1. 閉じたいリポジトリを右クリックし、**Close Repository**（リポジトリを閉じる）を選択します。

### グループネームスペースにないプロジェクト {#project-not-in-a-group-namespace}

GitLab Duo Agent Platformでは、プロジェクトがグループネームスペースに属している必要があります。

プロジェクトがあるネームスペースを特定するには、[URLを確認してください](../namespace/_index.md#determine-which-type-of-namespace-youre-in)。

必要に応じて、[プロジェクトをグループネームスペースに転送する](../../tutorials/move_personal_project_to_group/_index.md#move-your-project-to-a-group)ことができます。

## UIにフローが表示されない {#flows-not-visible-in-the-ui}

フローを実行しようとしているのに、GitLab UIに表示されない場合:

1. プロジェクトで少なくともデベロッパーのロールを持っていることを確認します。
1. GitLab Duoが[オンになっており、フローの実行が許可されている](../gitlab_duo/turn_on_off.md)ことを確認します。
1. 必要な機能フラグである[`duo_workflow`と`duo_workflow_in_ci`](../../administration/feature_flags/_index.md)が有効になっていることを確認します。

## IDEコマンドが失敗するか、無期限に実行される {#ide-commands-fail-or-run-indefinitely}

IDEでGitLab Duoチャット（エージェント型）またはソフトウェア開発フローを使用している場合、GitLab Duoがループ状態になったり、コマンドの実行が困難になったりすることがあります。

この問題は、`Oh My ZSH!`または`powerlevel10k`のようなシェルテーマやインテグレーションを使用している場合に発生することがあります。GitLab Duoエージェントがターミナルを起動すると、テーマまたはインテグレーションによってコマンドが正常に実行されないことがあります。

回避策として、エージェントから送信されたコマンドには、よりシンプルなテーマを使用します。[イシュー2070](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/2070)は、この動作の改善を追跡するため、この回避策は不要になりました。

### `.zshrc`ファイルを編集する {#edit-your-zshrc-file}

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

### Bashシェルを編集する {#edit-your-bash-shell}

VS CodeまたはJetBrains IDEでは、Bashの詳細プロンプトをオフにして、エージェントがそれらを初期化しないようにすることができます。このコードを含めるように`~/.bashrc`または`~/.bash_profile`ファイルを編集します:

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
