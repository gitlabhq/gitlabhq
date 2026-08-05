---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for VS Code拡張機能を使用して、VS Codeで一般的なGitLabタスクを直接処理します。
title: GitLab for VS Code拡張機能をインストールしてセットアップする
---

GitLab for VS Code拡張機能を使用するには、拡張機能をインストールし、GitLabに接続してから、必要に応じて設定します。

## 拡張機能をインストールする {#install-the-extension}

ニーズに合ったインストール方法を選択してください:

- 標準のVS Codeの場合、[Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)からインストールします。
- 非公式のVS Codeバージョンの場合、[Open VSX Registry](https://open-vsx.org/extension/GitLab/gitlab-workflow)からインストールします。
- 安全なローカル開発のために、Visual Studio Code Dev Containerにインストールします。

### Visual Studio Code Dev Containerにインストールする {#install-in-a-visual-studio-code-dev-container}

セキュリティ強化のため、拡張機能をセットアップし、[VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)を使用したコンテナ化された開発環境でGitLab Duoを使用します。

前提条件: 

- [Docker](https://www.docker.com/products/docker-desktop/)がインストールされ、実行されています。
- Visual Studio Codeの[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)拡張機能がVS Codeにインストールされています。

VS Code Dev Containerに拡張機能をインストールするには:

1. **Dev Containers: を実行します: Add Dev Container Configuration Files**コマンドをコマンドパレットから実行します。
1. GitLab拡張機能を設定ファイルに追加します:

   ```json
   // .devcontainer/devcontainer.json
   {
   "name": "My Project",
   "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
   "customizations": {
      "vscode": {
         "extensions": [
         "GitLab.gitlab-workflow"
         ]
      }
   }
   }
   ```

1. **Dev Containers: を実行します: Open Folder in Container**コマンドを実行して、プロジェクトをVS Code Dev Containerで開きます。VS Codeは、拡張機能をコンテナ内に自動的にインストールします。

## GitLabに接続する {#connect-to-gitlab}

拡張機能をインストールしたら、認証してから、プロジェクトをGitLabのリポジトリに接続します。

### GitLabに対して認証する {#authenticate-with-gitlab}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CHANGELOG.md#release--6470-2025-09-26) GitLab 18.3リリース中に、GitLab for VS Code 6.47.0のGitLab Self-ManagedとGitLab Dedicated向けのOAuth認証を追加しました。

{{< /history >}}

{{< tabs >}}

{{< tab title="GitLab.com" >}}

前提条件: 

- PATを使用した認証の場合、`api`スコープを持つ[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)。

GitLabで認証するには:

1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. `GitLab: Authenticate`と入力して<kbd>Enter</kbd>キーを押します。
1. オプションからGitLabインスタンスURLを選択するか、手動で入力します。
   - 手動で入力する場合は、**URL to GitLab instance**に`http://`または`https://`を含む完全なURLを貼り付けます。<kbd>Enter</kbd>を押して確定します。
1. 認証方法として、**OAuth**または**PAT**を選択します。
   - OAuthの場合は、プロンプトに従ってサインインし、認証を行います。
   - PATの場合、プロンプトに従ってトークンを作成するか、既存のものを入力して認証します。

{{< /tab >}}

{{< tab title="GitLab Self-Managed and GitLab Dedicated" >}}

前提条件: 

- OAuthを使用した認証の場合、[OAuth application for VS Code](../../administration/settings/editor_extensions.md#vs-code)のアプリケーションID。
- PATを使用した認証の場合、`api`スコープを持つ[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)。

OAuthを使用するには、最初にOAuthアプリケーションのログインを設定します:

1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. `Preferences: Open User Settings`と入力して<kbd>Enter</kbd>キーを押します。
1. **設定** > **Extensions** > **GitLab** > **認証**を選択します。
1. **OAuth Client IDs**の下にある**Add Item**を選択します。
1. **キー**を選択し、GitLabインスタンスURLを入力します。
1. **値**を選択し、OAuthアプリケーションのIDを入力します。

GitLabで認証するには:

1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. `GitLab: Authenticate`と入力して<kbd>Enter</kbd>キーを押します。
1. オプションからGitLabインスタンスURLを選択するか、手動で入力します。
   - 手動で入力する場合は、**URL to GitLab instance**に`http://`または`https://`を含む完全なURLを貼り付けます。<kbd>Enter</kbd>を押して確定します。
1. 認証方法として、**OAuth**または**PAT**を選択します。
   - OAuthの場合は、プロンプトに従ってサインインし、認証を行います。
   - PATの場合、プロンプトに従ってトークンを作成するか、既存のものを入力して認証します。 {{< /tab >}}

{{< /tabs >}}

拡張機能は、あなたのGitリポジトリリモートURLと、トークンに指定したGitLabインスタンスURLを照合します。複数のアカウントまたはプロジェクトがある場合は、使用したいものを選択できます。

> [!note]
> GitLabインスタンスまたはネットワークでカスタムSSL設定を使用している場合、自己署名証明書をサポートするように拡張機能を設定できます。詳細については、[自己署名証明書を使用する環境で拡張機能を使用する](ssl.md)を参照してください。

### リポジトリに接続する {#connect-to-your-repository}

VS CodeからGitLabリポジトリに接続するには:

1. VS Codeで、トップメニューから**Terminal** > **New Terminal**を選択します。
1. リポジトリをクローンします: `git clone <repository>`。
1. リポジトリがクローンされたディレクトリに移動し、ブランチをチェックアウトします: `git checkout <branch_name>`。
1. プロジェクトが選択されていることを確認します:
   1. 左サイドバーで**GitLab**（{{< icon name="tanuki" >}}）を選択します。
   1. プロジェクト名を選択します。複数のプロジェクトがある場合は、作業したいものを選択します。
1. ターミナルで、 リポジトリがリモートで設定されていることを確認します: `git remote -v`。結果は次のようになります:

   ```plaintext
   origin  git@gitlab.com:gitlab-org/gitlab.git (fetch)
   origin  git@gitlab.com:gitlab-org/gitlab.git (push)
   ```

   リモートが定義されていない場合、または複数のリモートがある場合:

   1. 左サイドバーで**Source Control**（{{< icon name="branch" >}}）を選択します。
   1. **Source Control**ラベルを右クリックして、**Repositories**を選択します。
   1. お使いのリポジトリの横にある省略記号（{{< icon name=ellipsis_h >}}）を選択し、**Remote** > **Add Remote**を選択します。
   1. **Add remote from GitLab**を選択します。
   1. リモートを選択します。

以下の場合、拡張機能はVS Codeステータスバーに情報を表示します:

- プロジェクトに最後のコミットのためのパイプラインがあります。
- 現在のブランチがマージリクエストに関連付けられています。

## 拡張機能を設定する {#configure-the-extension}

設定するには、**Settings** > **Extensions** > **GitLab**に移動します。

### アカウントとプロジェクトを設定する {#configure-accounts-and-projects}

認証してリポジトリに接続すると、拡張機能はGitリポジトリの設定に基づいてGitLabアカウントとプロジェクトを自動的に関連付けます。

一部の環境では、認証情報を永続化するために追加の設定が必要な場合があります。

#### トークンを環境変数に保存する {#store-tokens-in-environment-variables}

GitpodコンテナのようにVS Codeストレージを頻繁に削除する場合、認証トークンを[VS Code environment variables](https://code.visualstudio.com/docs/editor/variables-reference#_environment-variables)に保存します。環境変数は、VS Codeストレージを削除しても保持されます。

VS Codeを起動する前に、これらの変数を設定します:

- `GITLAB_WORKFLOW_INSTANCE_URL`: あなたのGitLabインスタンスURL。例: `https://gitlab.com`。
- `GITLAB_WORKFLOW_TOKEN`: あなたのパーソナルアクセストークン。

拡張機能で同じGitLabインスタンスのトークンを設定した場合、拡張機能のトークンが環境変数を上書きします。

#### アカウントを切り替える {#switch-accounts}

拡張機能は、[VS Code workspace](https://code.visualstudio.com/docs/editor/workspaces)（ウィンドウ）ごとに1つのアカウントを使用します。次の場合に自動的にアカウントを選択します:

- 拡張機能で1つのGitLabアカウントのみで認証します。
- VS Codeウィンドウ内のすべてのワークスペースが、`git remote`の設定に基づいて同じGitLabアカウントを使用している場合。

複数のGitLabアカウントが存在し、拡張機能が使用するアカウントを判別できない場合、ステータスバーに**Multiple GitLab Accounts**（{{< icon name="question-o" >}}）を追加します。GitLabアカウントを選択するには、ステータスバーアイテムを選択し、プロンプトに従います。

または、 コマンドパレットを使用できます:

1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. コマンド`GitLab: Select Account for this Workspace`を実行します。
1. リストからアカウントを選択します。

#### プロジェクトを選択する {#select-a-project}

拡張機能は、Gitリポジトリリモートを使用して、どのGitLabプロジェクトをVS Codeワークスペースに関連付けるかを決定します。

Gitリポジトリに、異なるGitLabプロジェクトを指す複数のリモートがある場合、拡張機能はどれを使用すべきかを決定できません。例: 

- `origin`: `git@gitlab.com:gitlab-org/gitlab-vscode-extension.git`
- `personal-fork`: `git@gitlab.com:myusername/gitlab-vscode-extension.git`

このような場合、拡張機能はステータスバーに **（multiple projects）** ラベルを追加します。

プロジェクトを選択するには:

1. 左サイドバーで**GitLab**（{{< icon name="tanuki" >}}）を選択します。
1. **Issues and merge requests**を展開します。
1. **（multiple projects, click to select）** を含む行を選択します。
1. リストからプロジェクトを選択します。

**Issues and merge requests**リストは、選択したプロジェクトの情報で更新されます。

#### プロジェクトを変更する {#change-the-project}

プロジェクトの選択を変更するには、次の手順に従います。

1. 左サイドバーで**GitLab**（{{< icon name="tanuki" >}}）を選択します。
1. **Issues and merge requests**を展開します。
1. プロジェクトを選択します。
1. プロジェクト名の横にある**Clear Selected Project**（{{< icon name="close-xs" >}}）を選択します。

### GitLab Duoを設定する {#configure-gitlab-duo}

以下の前提条件を満たす場合、VS CodeでGitLab Duo機能がデフォルトで有効になります:

- エージェント型機能の場合は、[GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md#prerequisites)の前提条件を満たしている必要があります。
- GitLab Duoが[オン](../../user/gitlab_duo/turn_on_off.md)になっている必要があります。
- フローの場合は、[基本フローがオン](../../user/duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)になっている必要があります。
- エージェントの場合は、必要に応じて、[基本エージェントがオン](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off)になっており、[カスタムエージェントが有効](../../user/duo_agent_platform/agents/custom.md#enable-an-agent)になっている必要があります。
- プロジェクトが[group namespace](../../user/namespace/_index.md)にあります。
- [default GitLab Duo namespace](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment)が設定されているか、GitLab Duoアクセス権を持つプロジェクトが開いています。
- GitLab Duoコード提案の場合:
  - あなたは[supported language and IDE](../../user/project/repository/code_suggestions/supported_extensions.md)を使用しています。
  - オプション。オプション。GitLabプロジェクトの外部で使用する場合:
    1. VS Codeで、設定エディタを開きます:
       - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
       - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押します。
    1. **Extensions** > **GitLab** > **GitLab Duo** > **GitLab › Duo: を選択します: Enabled Without GitLab Project**。

各セッションで個別にではなく一度にAgentic Chatツールを承認するには、[tool approvals](../../user/gitlab_duo_chat/agentic_chat.md#tool-approvals)を参照してください。

#### GitLab Duoをオフにする {#turn-off-gitlab-duo}

VS CodeでGitLab Duo機能をオフにするには:

1. VS Codeで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押します。
1. **Extensions** > **GitLab** > **GitLab Duo**を選択します。
1. オフにする機能を見つけて、チェックボックスをオフにします。

### テレメトリを設定する {#configure-telemetry}

GitLab for VS Codeは、VS Codeのテレメトリ設定を使用して、使用状況とエラー情報をGitLabに送信します。VS Codeでテレメトリをオンまたはカスタマイズするには:

1. VS Codeで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押します。
1. **アプリケーション** > **Telemetry**を選択します。
1. **Telemetry Level**（テレメトリレベル）で、共有するデータを選択します。
   - `all`: 使用状況データ、一般的なエラーテレメトリ、クラッシュレポートを送信します。
   - `error`: 一般的なエラーテレメトリとクラッシュレポートを送信します。
   - `crash`: OSレベルのクラッシュレポートを送信します。
   - `off`: Visual Studio Codeのすべてのテレメトリデータを無効にします。
1. 変更を保存します。
