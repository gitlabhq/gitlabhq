---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo CLI（`duo`）
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトのLLM](../duo_agent_platform/model_selection.md#default-models)
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 18.9で[実験](../../policy/development_stages_support.md#experiment)として導入。

{{< /history >}}

GitLab Duo CLIは、[GitLab Duo Chat（エージェント）](../gitlab_duo_chat/agentic_chat.md)をターミナルにもたらすコマンドラインインターフェースツールです。どのオペレーティングシステムおよびエディタでも使用でき、`duo`を使用すると、コードベースに関する複雑な質問をしたり、ユーザーに代わって自律的にアクションを実行したりできます。

GitLab Duo CLIは、以下のことに役立ちます:

- コードベースの構成、クロスファイルの機能、個々のスニペットを理解する。
- コードのビルド、変更、リファクタリング、モダナイズを行う。
- エラーのトラブルシューティングを行い、コードの問題を修正する。
- CI/CD設定を自動化し、パイプラインエラーのトラブルシューティングを行い、パイプラインを最適化する。
- 複数ステップの開発タスクを自律的に実行する。

{{< alert type="note" >}}

GitLab Duo CLI（`duo`）は、[GitLab CLI](https://docs.gitlab.com/cli/)（`glab`）とは別のツールです。`glab`は、イシューやマージリクエストなどのGitLab機能へのコマンドラインアクセスを提供する一方、`duo`は、タスクを完了し、作業中にユーザーを支援する自律的なAI機能を提供します。

統合されたエクスペリエンスが[エピック20826](https://gitlab.com/groups/gitlab-org/-/work_items/20826)で提案されています。

{{< /alert >}}

GitLab Duo CLIには、2つのモードがあります:

- インタラクティブモード: GitLab UIまたはエディタ拡張機能のGitLab Duo Chatと同様のチャットエクスペリエンスを提供します。
- ヘッドレスモード: Runner、スクリプト、およびその他の自動化されたワークフローで非対話型の使用を可能にします。

## GitLab Duo CLIをインストールする {#install-the-gitlab-duo-cli}

GitLab Duo CLIは、NPMパッケージまたはコンパイル済みのバイナリとしてインストールできます。

### NPMパッケージ {#npm-package}

前提条件: 

- Node.js 22以降。
- 自己署名証明書を使用したGitLab Self-Managedの場合:
  - Node.js LTS 22.20.0以降
  - Node.js 23.8.0以降

GitLab Duo CLIをNPMパッケージとしてインストールするには、次を実行します:

```shell
npm install --global @gitlab/duo-cli
```

### コンパイルされたバイナリ {#compiled-binary}

GitLab Duo CLIをコンパイルされたバイナリとしてインストールするには、インストールスクリプトをダウンロードして実行します。

{{< tabs >}}

{{< tab title="macOSおよびLinux" >}}

```shell
bash <(curl --fail --silent --show-error --location "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.sh")
```

{{< /tab >}}

{{< tab title="Windows" >}}

```shell
irm "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.ps1" | iex
```

{{< /tab >}}

{{< /tabs >}}

## GitLabに対して認証する {#authenticate-with-gitlab}

GitLab Duo CLIを初めて実行すると、設定画面が表示され、認証用の**GitLab Instance URL**と**GitLab Token**を設定するように求められます。

前提条件: 

- `api`権限を持つ[パーソナルアクセストークン](../profile/personal_access_tokens.md)。

認証するには:

1. **GitLab Instance URL**を入力し、<kbd>Enter</kbd>を押します。例: `https://gitlab.com`。
1. **GitLab Token**に、パーソナルアクセストークンを入力します。
1. CLIを保存して終了するには、<kbd>Control</kbd>+<kbd>S</kbd>キーを押します。
1. CLIを再起動するには、ターミナルで`duo`を実行します。

初期設定後に設定を変更するには、`duo config edit`を使用します。

## GitLab Duo CLIを使用する {#use-the-gitlab-duo-cli}

前提条件: 

- リモートリポジトリが設定されているGitLabプロジェクトを使用しているか、[デフォルトのGitLab Duoネームスペース](../profile/preferences.md#set-a-default-gitlab-duo-namespace)を設定する必要があります。

### 対話モードでGitLab Duo CLIを使用する {#use-the-gitlab-duo-cli-in-interactive-mode}

対話モードでGitLab Duo CLIを使用するには、`duo`コマンドを使用します:

1. ターミナルでインタラクティブUIを起動します:

   ```shell
   duo
   ```

1. `Duo`がターミナルウィンドウに表示されます。プロンプトの後、質問またはリクエストを入力して、<kbd>Enter</kbd>を押します。

    例: 

    ```plaintext
    What is this repository about?

    Which issues need my attention?

    Help me implement issue 15.

    The pipelines in MR 23 are failing. Please help me fix them.
    ```

### ヘッドレスモードでGitLab Duo CLIを使用する {#use-the-gitlab-duo-cli-in-headless-mode}

> [!caution]ヘッドレスモードは、慎重に、管理されたサンドボックス環境で使用してください。

非対話モードでワークフローを実行するには、`duo run`コマンドを使用します:

```shell
duo run --goal "Your goal or prompt here"
```

たとえば、ESLintコマンドを実行し、エラーをGitLab Duo CLIにパイプして解決できます:

 ```shell
duo run --goal "Fix these errors: $eslint_output"
```

ヘッドレスモードを使用すると、GitLab Duo CLIは、次のようになります:

- 手動ツール承認をバイパスし、すべてのツールを使用するために自動的に承認します。
- 以前の会話からのコンテキストを維持しません。`duo run`を実行するたびに、新しいワークフローが開始されます。

## Model Context Protocol（MCP）接続 {#model-context-protocol-mcp-connections}

GitLab Duo CLIをローカルまたはリモートのMCPサーバーに接続するには、GitLab IDE拡張機能と同じMCP構成を使用します。手順については、[MCPサーバーの設定](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-mcp-servers)を参照してください。

## オプション {#options}

GitLab Duo CLIは、次のオプションをサポートしています:

- `-C, --cwd <path>`: 作業ディレクトリを変更します。
- `-h, --help` : GitLab Duo CLIまたは特定のコマンドのヘルプを表示します。例: `duo --help`、`duo run --help`。
- `--log-level <level>`: ログレベルを設定します（`debug`、`info`、`warn`、`error`）。
- `-v`、`--version`: バージョン情報を表示します。

ヘッドレスモードの追加オプション:

- `--ai-context-items <contextItems>`: 参照用の追加コンテキスト項目のJSONエンコード配列。
- `--existing-session-id <sessionId>`: 再開する既存のセッションのID。
- `--gitlab-auth-token <token>`: GitLabインスタンスの認証トークン。
- `--gitlab-base-url <url>`: GitLabインスタンスのベースURL（デフォルト: `https://gitlab.com`）。

## コマンド {#commands}

- `duo`: 対話モードを開始します。
- `duo config`: 設定および認証設定を管理します。
- `duo log`: ログを表示および管理します。
  - `duo log last`: 最後のログファイルを開きます。
  - `duo log list`: すべてのログファイルを一覧表示します。
  - `duo log tail <args...>`: 最後のログファイルの末尾を表示します。標準のtail引数をサポートします。
  - `duo log clear`: 既存のすべてのログファイルを削除します。
- `duo run`: ヘッドレスモードを開始します。

## 環境変数 {#environment-variables}

環境変数を使用してGitLab Duo CLIを設定できます:

- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTP認証パスワード。
- `DUO_WORKFLOW_GIT_HTTP_USER`: Git HTTP認証ユーザー名。
- `GITLAB_BASE_URL`または`GITLAB_URL`: GitLabインスタンスのURL。
- `GITLAB_OAUTH_TOKEN`または`GITLAB_TOKEN`: 認証トークン。
- `LOG_LEVEL`: ログレベル。

## プロキシとカスタム証明書の設定 {#proxy-and-custom-certificate-configuration}

ネットワークがHTTPS傍受プロキシを使用しているか、カスタムSSL証明書が必要な場合は、追加の設定が必要になることがあります。

### プロキシ設定 {#proxy-configuration}

GitLab Duo CLIは、標準のプロキシ環境変数を尊重します:

- `HTTP_PROXY`または`http_proxy`: HTTPリクエストのプロキシURL。
- `HTTPS_PROXY`または`https_proxy`: HTTPSリクエストのプロキシURL。
- `NO_PROXY`または`no_proxy`: プロキシから除外するホストのカンマ区切りリスト。

### カスタムSSL証明書 {#custom-ssl-certificates}

組織がカスタム認証局（CA）をHTTPS傍受プロキシなどに使用している場合は、証明書エラーが発生する可能性があります。

```plaintext
Error: unable to verify the first certificate
Error: self-signed certificate in certificate chain
```

証明書エラーを解決するには、次のいずれかの方法を使用します:

- システム証明書ストアを使用する（推奨）: CA証明書がオペレーティングシステムの証明書ストアにインストールされている場合は、それを使用するようにNode.jsを設定します。Node.js 22.15.0、23.9.0、または24.0.0以降が必要です。

  ```shell
  export NODE_OPTIONS="--use-system-ca"
  ```

- CA証明書ファイルを指定します: 古いバージョンのNode.jsの場合、またはCA証明書がシステムストアにない場合は、証明書ファイルを直接ポイントするようにNode.jsをポイントします。ファイルはPEM形式である必要があります。

  ```shell
  export NODE_EXTRA_CA_CERTS=/path/to/custom-ca.pem
  ```

### 証明書エラーを無視する {#ignore-certificate-errors}

証明書エラーが引き続き発生する場合は、証明書の検証を無効にできます。

> [!warning]
> 証明書の検証を無効にすると、セキュリティ漏洩のリスクがあります。本番環境で検証を無効にしないでください。

証明書エラーは潜在的なセキュリティ漏洩を警告するため、安全であると確信できる場合にのみ証明書の検証を無効にする必要があります。

前提条件: 

- ブラウザで証明書チェーンを検証したか、管理者がこのエラーを無視しても安全であることを確認しました。

証明書の検証を無効にするには:

```shell
export NODE_TLS_REJECT_UNAUTHORIZED=0
```

## GitLab Duo CLIを更新する {#update-the-gitlab-duo-cli}

GitLab Duo CLIを最新バージョンに更新するには、次を実行します:

```shell
npm install --global @gitlab/duo-cli@latest
```

## GitLab Duo CLIにコントリビュートする {#contribute-to-the-gitlab-duo-cli}

GitLab Duo CLIへのコントリビュートについては、[開発ガイド](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/development.md)を参照してください。

## 関連トピック {#related-topics}

- [エディタ拡張機能のセキュリティに関する考慮事項](../../editor_extensions/security_considerations.md)
