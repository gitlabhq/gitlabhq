---
stage: none
group: Tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Claude DesktopをGitLab MCPサーバーに接続し、イシューを作成する。
title: "チュートリアル: Claude DesktopをGitLab MCPサーバーに接続する"
---

この[GitLab Model Context Protocol（MCP）サーバー](../../user/gitlab_duo/model_context_protocol/mcp_server.md)を使用すると、外部AIツールとアプリケーションをGitLabのインスタンスに接続できます。このチュートリアルでは、GitLab MCPサーバーをClaude Desktopに接続するように設定します。Claude DesktopをMCPサーバーと正常に統合した後、ClaudeにGitLabのインスタンスにイシューを作成するよう指示します。

## はじめる前 {#before-you-begin}

- [GitLab Duo](../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-on-or-off)と[ベータ版および実験的機能](../../user/duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features)を有効にします。
- オペレーティングシステム用の[Claude Desktop](https://support.claude.com/en/articles/10065433-installing-claude-desktop)をインストールします。
- Node.jsバージョン20以降をインストールします。Node.jsが`PATH`環境変数にグローバルで利用可能であることを確認してください (`which -a node`)。
- イシューを作成できるアクティブなプロジェクトが少なくとも1つあることを確認してください。

## Claude DesktopをGitLab MCPサーバーに接続する {#connect-claude-desktop-to-the-gitlab-mcp-server}

1. Claude Desktopを開きます。
1. 設定ファイルを編集します。次のいずれかを実行します:
   - Claude Desktopで、**設定** > **デベロッパー** > **Edit Config**を選択します。
   - お使いのファイルシステムで、`claude_desktop_config.json`に移動してファイルを開きます。例: 
     - macOSの場合: `~/Library/Application Support/Claude/claude_desktop_config.json`。
     - Windowsの場合: `%APPDATA%\Claude\claude_desktop_config.json`。
1. 必要に応じて編集し、GitLab MCPサーバーに次のエントリを追加します:
   - `"command":`パラメータの場合、`npx`がグローバルではなくローカルにインストールされている場合は、`npx`へのフルパスを指定してください。
   - `<gitlab.example.com>`を以下に置き換えます:
     - GitLab Self-Managedでは、GitLabインスタンスのURL。
     - GitLab.comでは、`GitLab.com`。

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "command": "npx",
         "args": [
           "-y",
           "mcp-remote",
           "https://<gitlab.example.com>/api/v4/mcp"
         ]
       }
     }
   }
   ```

1. 設定を保存して、Claude Desktopを再起動します。
1. 初回接続時、Claude DesktopはOAuth認証用のブラウザウィンドウを開きます。リクエストを確認して承認します。
1. **Settings** > **Developer**に移動し、新しいGitLab MCP設定を確認します。

![Claude Desktopで接続済みのローカルMCPサーバーを表示](img/view_local_mcp_servers_v18_10.png)

## ツール権限をカスタマイズする {#customize-tool-permissions}

MCPサーバーへの接続が正常に完了したら、GitLabのインスタンスとインタラクトする際にClaudeが使用できるツールをカスタマイズできます。たとえば、Claudeがイシューの作成やCI/CDパイプラインの管理のような特定のアクションを実行する前に、承認をリクエストするように設定できます。

Claudeでツール権限を表示するには:

1. 左サイドバーで、**Customize** > **Connectors**を選択します。
1. **Desktop**の下で、**GitLab**を選択します。
1. `create_issue`を**Needs approval**または**Always allow**に設定します。

![Claude Desktopでコネクタのツール権限を表示](img/view_connectors_v18_10.png)

## 接続をテストする {#test-the-connection}

Claude DesktopをMCPサーバーに正常に接続できたので、プロンプトで接続をテストします:

1. チャットのテキストボックスに次のように入力します:

   ```plaintext
   Which MCP server version are you using?
   ```

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。

Claudeは、インテグレーションの詳細とプロンプトに回答するために使用したツールとともに、サーバーのバージョンで応答するはずです。

![MCPサーバーのバージョンをプロンプトで検証し、Claudeが使用したツールを確認](img/verify_mcp_server_version_v18_10.png)

## プロジェクトにイシューを作成する {#create-an-issue-in-a-project}

次に、Claudeにテストイシューを作成できる特定のプロジェクトを見つけるように依頼します。

1. チャットのテキストボックスに次のように入力します:

   ```plaintext
   Can you find my project <project_name>?
   ```

   `<project_name>`を自分のプロジェクトに置き換えます。
1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. Claudeがプロジェクトを見つけたら、Claudeにプロジェクト内にイシューを作成するよう依頼します。チャットのテキストボックスに次のように入力します:

   ```plaintext
   Can you create an issue in the project called "Test issue from MCP server", and give it the following description: "This is a test issue created by Claude Desktop and the GitLab MCP server."
   ```

1. <kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. `create_issue`を**Needs approval**に設定した場合、Claudeはイシューを作成する権限を求めます。**Always allow**を選択するか、ドロップダウンリストから**Allow once**を選択します。

   ![Claudeにプロジェクト内にイシューを作成する権限を付与](img/grant_permission_to_create_issue_v18_10.png)

Claudeがイシューを作成すると、ブラウザでイシューにアクセスするためのURLを含む詳細情報が表示されます。
