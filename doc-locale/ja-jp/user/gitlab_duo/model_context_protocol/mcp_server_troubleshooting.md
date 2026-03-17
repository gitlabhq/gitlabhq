---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab MCPサーバーに関する一般的な問題のトラブルシューティングを行う。
title: GitLab Model Context Protocolサーバーのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

GitLab MCPサーバーを使用している際に、次の問題に遭遇する可能性があります。

## GitLab MCPサーバー起動時の`404 Not Found`エラー {#404-not-found-when-starting-the-gitlab-mcp-server}

GitLab MCPサーバーを起動しようとすると、`404 Not Found`エラーが発生する可能性があります。このエラーは、GitLab Duo Coreまたはベータ版および実験的機能が無効になっている場合に発生します。

この問題を解決するには、GitLab MCPサーバーのすべての[前提条件](mcp_server.md#prerequisites)を満たしていることを確認してください。

## エラー: `Server's protocol version is not supported: 2025-06-18` {#error-servers-protocol-version-is-not-supported-2025-06-18}

GitLab 18.6以前では、MCPクライアントライブラリがGitLab MCPサーバープロトコルの仕様をサポートしていない場合に、このエラーが発生する可能性があります。

この問題を解決するには、AIツールプロバイダーにクライアント実装を更新するよう依頼してください。

## CursorでGitLab MCPサーバーをトラブルシューティングする {#troubleshoot-the-gitlab-mcp-server-in-cursor}

1. Cursorで出力表示を開くには、次のいずれかを実行します:
   - **View** > **Output**に移動します。
   - macOSでは、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>U</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>U</kbd>を押します。
1. 出力表示で、**MCP:SERVERNAME**を選択します。名前はMCPの設定値によって異なります。`GitLab`を使用した例では、`MCP: user-GitLab`になります。
1. バグをレポートする場合は、出力をイシューテンプレートのログセクションにコピーします。

## CLIでmcp-remoteを使用してGitLab MCPサーバーをトラブルシューティングする {#troubleshoot-the-gitlab-mcp-server-on-the-cli-with-mcp-remote}

1. [Node.js](https://nodejs.org/en/download)バージョン20以降をインストールします。

1. IDEおよびデスクトップクライアントとまったく同じコマンドをテストするには:
   1. MCP設定を抽出します。
   1. `npx`コマンドライン文字列を1行に組み立てます。
   1. コマンド文字列を実行します。

   ```shell
   rm -rf ~/.mcp-auth/mcp-remote*

   npx -y mcp-remote@latest https://gitlab.example.com/api/v4/mcp --static-oauth-client-metadata '{"scope": "mcp"}'
   ```

1. より詳細な出力を記録するには、`--debug`パラメータを追加します:

   ```shell
   rm -rf ~/.mcp-auth/mcp-remote*

   npx -y mcp-remote@latest https://gitlab.example.com/api/v4/mcp --static-oauth-client-metadata '{"scope": "mcp"}' --debug
   ```

1. オプション。`mcp-remote-client`実行可能ファイルを直接実行します。

   ```shell
   rm -rf ~/.mcp-auth/mcp-remote*

   npx -p mcp-remote@latest mcp-remote-client https://gitlab.example.com/api/v4/mcp --static-oauth-client-metadata '{"scope": "mcp"}'
   ```

1. オプション。バージョン固有のバグが発生した場合は、`mcp-remote`モジュールのバージョンを特定のバージョンに固定します。たとえば、`mcp-remote@0.1.26`を使用して、バージョンを`0.1.26`に固定します。

   > [!note]
   > セキュリティ上の理由から、可能な限りバージョンを固定すべきではありません。

## Claude DesktopでGitLab MCPサーバーをトラブルシューティングする {#troubleshoot-gitlab-mcp-server-with-claude-desktop}

インストールされている[Node.js](https://nodejs.org/en/download)のバージョンを検証します。Claude Desktopには、Node.jsバージョン20以降が必要です。

```shell
for n in $(which -a node); do echo "$n" && $n -v; done
```

## MCP認証キャッシュを削除する {#delete-mcp-authentication-caches}

MCP認証は主にローカルにキャッシュされます。トラブルシューティング中に、誤検出が発生する可能性があります。これらを防ぐには、トラブルシューティング中にキャッシュディレクトリを削除します:

```shell
rm -rf ~/.mcp-auth/mcp-remote*
```

## デバッグおよび開発ツール {#debugging-and-development-tools}

[MCP Inspector](https://modelcontextprotocol.io/legacy/tools/inspector)は、MCPサーバーをテストおよびデバッグするためのインタラクティブなデベロッパーツールです。このツールを実行するには、コマンドラインを使用し、WebインターフェースにアクセスしてGitLab MCPサーバーを検査します。

```shell
npx -y @modelcontextprotocol/inspector npx
```
