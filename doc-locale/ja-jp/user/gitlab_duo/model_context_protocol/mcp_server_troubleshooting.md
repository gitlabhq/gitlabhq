---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Model Context Protocolサーバーのトラブルシューティング。
title: GitLab Model Context Protocolサーバーのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.3で`mcp_server`および`oauth_dynamic_client_registration`という名前で[フラグ付き](../../../administration/feature_flags/_index.md)で導入されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

{{< alert type="warning" >}}

この機能に関するフィードバックを提供するには、[イシュー561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)にコメントしてください。

{{< /alert >}}

GitLab Model Context Protocolサーバーの操作中に、イシューが発生する可能性があります。

## CursorでGitLab Model Context Protocolサーバーのトラブルシューティング {#troubleshoot-the-gitlab-mcp-server-in-cursor}

1. Cursorで出力表示を開くには、次のいずれかを実行します。
   - **表示** > **Output**（出力）に移動します。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>U</kbd>キーを押します。
   - WindowsまたはLinuxで、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>U</kbd>を押します。
1. 出力表示で、**MCP:SERVERNAME**を選択します。名前はModel Context Protocolの設定値によって異なります。`GitLab`を使用した例では、`MCP: user-GitLab`になります。
1. バグをレポートする場合は、出力をイシューテンプレートのログセクションにコピーしてください。

## CLIでmcp-remoteを使用してGitLab Model Context Protocolサーバーのトラブルシューティング {#troubleshoot-the-gitlab-mcp-server-on-the-cli-with-mcp-remote}

1. [Node.js](https://nodejs.org/en/download)バージョン20以降をインストールします。

1. IDEおよびデスクトップクライアントとまったく同じコマンドラインをテストするには:
   1. Model Context Protocolの設定を抽出します。
   1. `npx`コマンドライン文字列を1行に組み立てます。
   1. コマンドライン文字列を実行します。

   ```shell
   rm -rf ~/.mcp-auth/mcp-remote*

   npx -y mcp-remote@latest https://gitlab.example.com/api/v4/mcp --static-oauth-client-metadata '{"scope": "mcp"}'
   ```

1. より詳細な出力をログに記録するには、`--debug`パラメータを追加します:

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

   {{< alert type="note" >}}

   セキュリティ上の理由から、可能であればバージョンを固定しないでください。

   {{< /alert >}}

## Claude DesktopでGitLab Model Context Protocolサーバーのトラブルシューティング {#troubleshoot-gitlab-mcp-server-with-claude-desktop}

インストールされている[Node.js](https://nodejs.org/en/download)のバージョンを検証します。Claude Desktopには、Node.jsバージョン20以降が必要です。

```shell
for n in $(which -a node); do echo "$n" && $n -v; done
```

## Model Context Protocol認証キャッシュの削除 {#delete-mcp-authentication-caches}

Model Context Protocol認証はローカルにキャッシュされます。トラブルシューティング中に、誤検出が発生する可能性があります。これらを防ぐには、トラブルシューティング中にキャッシュディレクトリを削除します。:

```shell
rm -rf ~/.mcp-auth/mcp-remote*
```

## デバッグおよび開発ツール {#debugging-and-development-tools}

[MCP Inspector](https://modelcontextprotocol.io/legacy/tools/inspector)は、Model Context Protocolサーバーをテストおよびデバッグするためのインタラクティブなデベロッパーツールです。このツールを実行するには、コマンドラインを使用し、WebインターフェースにアクセスしてGitLab Model Context Protocolサーバーを検査します。

```shell
npx -y @modelcontextprotocol/inspector npx
```
