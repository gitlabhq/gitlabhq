---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo CLIのオプション、コマンド、環境変数。
title: GitLab Duo CLIリファレンス
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Duo CLIを起動または実行するときは、これらのオプション、コマンド、および環境変数を使用します。

これは完全なリストではありません。完全な参照については、[GitLab Duo CLI完全参照](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)をご覧ください。

## オプション {#options}

GitLab Duo CLIは、次のオプションをサポートしています:

- `-C, --cwd <path>`: 作業ディレクトリを変更します。
- `-h, --help`: GitLab Duo CLIまたは特定のコマンドのヘルプを表示します。例: `duo --help`、`duo run --help`。
- `-v`、`--version`: バージョン情報を表示します。
- `--model <model>`: セッションに使用するAIモデルを選択します。

オプションの完全なリストについては、GitLab Duo CLI完全参照をご覧ください。

## コマンド {#commands}

各セットアップでは次のコマンドを使用できます:

{{< tabs >}}

{{< tab title="glab" >}}

- `glab duo cli`: インタラクティブモードを開始します。
- `glab duo cli log`: ログを表示および管理します。
- `glab duo cli run`: ヘッドレスモードを開始します。

{{< /tab >}}

{{< tab title="duo" >}}

- `duo`: インタラクティブモードを開始します。
- `duo config`: 設定と認証設定を管理します。
- `duo log`: ログを表示および管理します。
- `duo run`: ヘッドレスモードを開始します。

{{< /tab >}}

{{< /tabs >}}

コマンドの完全なリストについては、GitLab Duo CLI完全参照をご覧ください。

## 環境変数 {#environment-variables}

{{< history >}}

- GitLab 19.0リリース時に、GitLab Duo CLI 8.95.0で`AI_AGENT`環境変数が[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0)されました。

{{< /history >}}

環境変数を使用してGitLab Duo CLIを設定できます:

- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTP認証パスワード。
- `DUO_WORKFLOW_GIT_HTTP_USER`: Git HTTP認証ユーザー名。
- `GITLAB_BASE_URL`または`GITLAB_URL`: GitLabインスタンスのURL。
- `GITLAB_DUO_MODEL`: セッションに使用するAIモデル。
- `GITLAB_OAUTH_TOKEN`または`GITLAB_TOKEN`: 認証トークン。

GitLab Duo CLIがユーザーに代わってコマンドを実行すると、そのプロセスに`AI_AGENT`環境変数が設定されます。スクリプトやツールは`AI_AGENT`を読み取って、AIによって実行されていることを検出できます。

環境変数の完全なリストについては、GitLab Duo CLI完全参照をご覧ください。

## ターミナルの進行状況シグナル {#terminal-progress-signals}

{{< history >}}

- GitLab 18.11リリース時にGitLab Duo CLI 8.79.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.79.0)されました。

{{< /history >}}

インタラクティブモードとヘッドレスモードの両方で、GitLab Duo CLIはOperating System Command（OSC）`9;4`の進行状況エスケープシーケンスを`/dev/tty`に書き込むことでステータスを報告します。このシーケンスをサポートするターミナルは、GitLab Duo CLIを実行しているタブまたはウィンドウに進行状況インジケーターを表示します。ターミナルマルチプレクサとステータスツールは、同じシーケンスを解析してGitLab Duo CLIの状態を検出できます。

GitLab Duo CLIは、各シグナルを`ESC ] <sequence> ESC \`として書き込みます。`<sequence>`は以下のいずれかです:

| シーケンス   | ステータス         | 説明                                       |
|------------|---------------|---------------------------------------------------|
| `9;4;3`    | 不確定 | GitLab Duo CLIはリクエストを処理しています。       |
| `9;4;4;50` | 一時停止        | ツール呼び出しが承認を待っています。         |
| `9;4;0`    | クリア         | GitLab Duo CLIはアイドル状態で、入力を待っています。 |
| `9;4;2`    | Error         | 最後のリクエストはエラーで終了しました。             |

GitLab Duo CLIは、その標準出力がターミナルにアタッチされており、`/dev/tty`デバイスが利用可能な場合にのみ、これらのシグナルを書き込みます。シグナルは標準出力ではなく`/dev/tty`に送られるため、リダイレクトされた出力やキャプチャされた出力には表示されません。GitLab Duo CLIが終了すると、進行状況ステータスがクリアされます。

GitLab Duo CLIが`tmux`セッションで実行される場合、シーケンスは`tmux`パススルーエスケープシーケンスでラップされます。`tmux` 3.3以降では、`allow-passthrough`オプションをオンにした場合にのみ、シーケンスは外部ターミナルに到達します。

GitLab Duo CLIは、セッションに注意が必要な場合に[システム通知](use.md#system-notifications)を送信することもできます。
