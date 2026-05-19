---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo CLI（`duo`）
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトLLM](../duo_agent_platform/model_selection.md#default-models)
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 18.9で[実験的機能](../../policy/development_stages_support.md#experiment)として導入されました。
- [追加](https://gitlab.com/gitlab-org/cli/-/merge_requests/2838)されました。GitLab CLIに実験として`glab` 1.87.0に、GitLab 18.9のリリース中に。
- GitLab 18.10のリリース中に、GitLab Duo CLI 8.68.0でモデル選択オプションと環境変数が[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.68.0)されました。
- GitLab 18.10のリリース中に、GitLab Duo CLI 8.76.0でモデル選択スラッシュコマンドが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.76.0)されました。
- GitLab 18.11で実験からベータに[変更](https://gitlab.com/groups/gitlab-org/-/work_items/19716)されました。
- 環境変数とユーザーレベルのAgent Skillsを有効にするオプションは、GitLab 19.0リリース中に、GitLab Duo CLI 8.83.0で[実験](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0)として[導入](../../policy/development_stages_support.md#experiment)されました。
 
{{< /history >}}

GitLab Duo CLIは、ターミナルに[GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md)をもたらすコマンドラインインターフェースツールです。どのオペレーティングシステムとエディタでも使用でき、CLIを使用してコードベースに関する複雑な質問をしたり、あなたの代わりに自律的にアクションを実行したりできます。

GitLab Duo CLIは、以下を支援します:

- コードベースの構造、複数ファイルにまたがる機能、個々のコードスニペットを理解する。
- コードを作成、変更、リファクタリング、モダナイズする。
- エラーのトラブルシューティングを行い、コードの問題を修正する。
- CI/CD設定を自動化し、パイプラインエラーのトラブルシューティングを行い、パイプラインを最適化する。
- 複数ステップの開発タスクを自律的に実行する。

GitLab Duo CLIには、2つのモードがあります:

- インタラクティブモード: GitLab UIまたはエディタ拡張機能内のGitLab Duo Chatと同様のチャットエクスペリエンスを提供します。ビルドモードとプランモードをサポートします。
- ヘッドレスモード: Runner、スクリプト、その他の自動化されたワークフローで非インタラクティブに使用できます。

また、GitLab Duo Agent Platform用に設定された[カスタム指示](../duo_agent_platform/customize/_index.md)もサポートしており、`chat-rules.md`、`AGENTS.md`、`SKILL.md`ファイルが含まれます。

## 前提条件 {#prerequisites}

- GitLab 18.11以降。
- [GitLab Duo Agent Platformの前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしてください。
- [ベータ版および実験的機能](../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features)が有効になっている。

## GitLab Duo CLIをセットアップする {#set-up-the-gitlab-duo-cli}

[GitLab CLI](https://docs.gitlab.com/cli/)（`glab`）を介してGitLab Duo CLIを使用できます。GitLab CLIを使用すると、他のGitLab機能にアクセスでき、OAuthまたはパーソナルアクセストークンを使用して一度だけ認証する必要があります。

あるいは、GitLab Duo CLI（`duo`）をスタンドアロンのAIツールとしてインストールして使用し、パーソナルアクセストークンで個別に認証することもできます。

どちらのセットアップも、すべてのGitLab Duo CLIのオプション、コマンド、機能とともに、インタラクティブモードとヘッドレスモードをサポートしています。

### GitLab CLIを使用する {#with-the-gitlab-cli}

前提条件: 

- [GitLab CLI](https://docs.gitlab.com/cli/) 1.87.0以降。
- GitLab CLIは[認証済み](https://docs.gitlab.com/cli/#authenticate-with-gitlab)です。

GitLab CLIを介してGitLab Duo CLIを使用するようにセットアップするには:

1. GitLab Duo CLIに対して`glab`コマンドを実行します:

   ```shell
   glab duo cli
   ```

1. プロンプトに従ってGitLab Duo CLIバイナリをインストールします。

GitLab CLIは認証を自動的に処理するため、すぐにGitLab Duo CLIの使用を開始できます。

### GitLab CLIなしで {#without-the-gitlab-cli}

GitLab Duo CLIをスタンドアロンツールとして使用するには、インストールしてから認証する必要があります。

#### インストール {#install}

GitLab Duo CLIをNPMパッケージまたはコンパイル済みバイナリとしてインストールします。

{{< tabs >}}

{{< tab title="NPMパッケージ" >}}

前提条件: 

- Node.js 22以降。
- 自己署名証明書を使用するGitLab Self-Managedの場合、次のいずれか:
  - Node.js LTS 22.20.0以降
  - Node.js 23.8.0以降

GitLab Duo CLIをnpmパッケージとしてインストールするには、次を実行します:

```shell
npm install --global @gitlab/duo-cli
```

{{< /tab >}}

{{< tab title="コンパイル済みバイナリ" >}}

GitLab Duo CLIをコンパイル済みバイナリとしてインストールするには、インストールスクリプトをダウンロードして実行します。

macOSおよびLinuxの場合:

```shell
bash <(curl --fail --silent --show-error --location "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.sh")
```

Windowsの場合:

```shell
irm "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.ps1" | iex
```

{{< /tab >}}

{{< /tabs >}}

#### 認証 {#authenticate}

> [!note]
> `glab`がシステムにインストールされ、最初に`duo`を実行したときに認証済みの場合、`duo`は`glab`を認証情報ヘルパーとして自動的に使用します。個別に認証する必要はありません。これには`glab` 1.85.2以降と`duo` 8.68.0以降が必要です。
>
> この機能が利用可能になる前に`duo`を認証済みで、代わりに`glab`を認証情報ヘルパーとして使用したい場合は、`~/.gitlab/storage.json`か認証設定を削除してください。

前提条件: 

- `api`権限を持つ[パーソナルアクセストークン](../profile/personal_access_tokens.md)。

認証するには:

1. `duo`をターミナルで実行します。GitLab Duo CLIを最初に実行すると、設定画面が表示されます。
1. **GitLab Instance URL**を入力し、<kbd>Enter</kbd>を押します:
   - GitLab.comの場合は、`https://gitlab.com`を入力します。
   - GitLab Self-ManagedまたはGitLab Dedicatedの場合は、インスタンスURLを入力します。
1. **GitLabトークン**に、パーソナルアクセストークンを入力します。
1. CLIを保存して終了するには、<kbd>Enter</kbd>を押します。
1. CLIを再起動するには、ターミナルで`duo`を実行します。

初期設定後に設定を変更するには、`duo config edit`を使用します。

#### 環境変数で認証する {#authenticate-with-environment-variables}

前提条件: 

- `api`権限を持つ[パーソナルアクセストークン](../profile/personal_access_tokens.md)。

環境変数で認証するには:

1. `GITLAB_TOKEN`または`GITLAB_OAUTH_TOKEN`をパーソナルアクセストークンに設定します。

   ```shell
   export GITLAB_TOKEN="<your-personal-access-token>"
   ```

1. オプション。`GITLAB_BASE_URL`または`GITLAB_URL`をカスタムGitLabインスタンスURL (`https://gitlab.example.com`など) に設定します。デフォルトは`https://gitlab.com`です。

   ```shell
   export GITLAB_BASE_URL="<your-instance-url>"
   ```

この方法は、インタラクティブな認証が不可能なヘッドレスモード、CI/CDパイプライン、スクリプト化されたワークフローに役立ちます。

## GitLab Duo CLIを使用する {#use-the-gitlab-duo-cli}

前提条件: 

- [デフォルトのGitLab Duoネームスペース](../profile/preferences.md#namespace-resolution-in-your-local-environment)が設定されているか、GitLab Duoにアクセスできる公開プロジェクト。

### インタラクティブモード {#interactive-mode}

GitLab Duo CLIをインタラクティブモードで使用するには:

1. セットアップに基づいて、インタラクティブモードを開始するコマンドを入力します:

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. プロンプト`>`があなたのターミナルウィンドウに表示されます。プロンプトの後に質問またはリクエストを入力し、<kbd>Enter</kbd>を押します。

   例: 

   ```plaintext
   What is this repository about?

   Which issues need my attention?

   Help me implement issue 15.

   The pipelines in MR 23 are failing. Please help me fix them.
   ```

GitLab Duo CLIの動作中に応答をキャンセルするには、<kbd>Escape</kbd>を押します。GitLab Duo CLIは現在の操作を停止し、プロンプトに戻ります。

<kbd>↑</kbd>キーを使用してプロンプトの履歴を表示するか、<kbd>Control</kbd>+<kbd>R</kbd>で検索します。

#### ビルドモードとプランモードを切り替える {#switch-between-build-and-plan-modes}

インタラクティブモードでは、作業中にGitLab Duo CLIを2つのモードで切り替えることができます:

| モード                 | 権限 | 仕組み                                                                  |
|----------------------|-------------|-------------------------------------------------------------------------------|
| ビルドモード（デフォルト） | 読み取り/書き込み  | GitLab Duoはタスクを実行し、プロジェクトに変更を加えることができます。               |
| プランモード            | 読み取り専用   | GitLab Duoは、変更を加えることなくプロジェクトを分析し、プランを作成できます。 |

たとえば、プランモードでGitLab Duoと問題について議論することから始めます。準備ができたら、ビルドモードに切り替えて、GitLab Duoにプランを実行するように指示します。

GitLab Duo CLIは、`>`プロンプトの下に現在のモードを表示します。モードを切り替えるには、<kbd>Tab</kbd>を押します。

#### スラッシュコマンド {#slash-commands}

インタラクティブモードでは、スラッシュコマンドを使用してGitLab Duo CLIを設定し、アクションを実行します。プロンプトでスラッシュコマンドを入力し、<kbd>Enter</kbd>を押します。

以下のスラッシュコマンドが利用可能です:

| コマンド      | 説明                                         |
|--------------|-----------------------------------------------------|
| `/copy`      | 最後のGitLab Duoの応答をクリップボードにコピーします。 |
| `/feedback`  | バグレポートまたは機能リクエストを送信します。             |
| `/help`      | 利用可能なスラッシュコマンドのリストを表示します。         |
| `/model`     | 現在のセッションのAIモデルを切り替えます。        |
| `/new`       | 新しいチャットセッションを開始します。                           |
| `/sessions`  | セッションを参照、検索、切り替えます。                |

### ヘッドレスモード {#headless-mode}

> [!caution]
> ヘッドレスモードは、注意して制御された[サンドボックス環境](../../editor_extensions/security_considerations.md#use-development-containers-for-isolation)で使用してください。

非インタラクティブモードでワークフローを実行するには、セットアップに応じたコマンドを使用します:

{{< tabs >}}

{{< tab title="glab" >}}

`glab duo cli run`を使用します: 

```shell
glab duo cli run --goal "Your goal or prompt here"
```

たとえば、ESLintコマンドを実行し、エラーをGitLab Duo CLIに渡して解決させることができます:

 ```shell
glab duo cli run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< tab title="duo" >}}

`duo run`を使用します: 

```shell
duo run --goal "Your goal or prompt here"
```

たとえば、ESLintコマンドを実行し、エラーをGitLab Duo CLIに渡して解決させることができます:

 ```shell
duo run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< /tabs >}}

ヘッドレスモードを使用すると、GitLab Duo CLIは次のように動作します:

- 手動によるツール承認をバイパスし、すべてのツールの使用を自動的に承認します。
- 以前の会話からのコンテキストを保持しません。`run`コマンドを実行するたびに新しいワークフローが開始されます。

## モデルを選択する {#select-a-model}

インタラクティブモードまたはヘッドレスモードでモデルを選択できます。

### インタラクティブモードの場合 {#for-interactive-mode}

選択したモデルはセッション間で永続化され、コンテキストを失うことなく会話の途中でモデルを切り替えることができます。

前提条件: 

- GitLab Duo CLI 8.76.0以降。

インタラクティブモードでモデルを選択するには:

1. インタラクティブモードで、`/model`と入力し、<kbd>Enter</kbd>を押します。
1. 矢印キーを使用して利用可能なモデルのリストをスクロールするか、モデル名を入力してリストを絞り込みます。
1. モデルを選択し、<kbd>Enter</kbd>を押して切り替えます。

### ヘッドレスモードの場合 {#for-headless-mode}

選択したモデルはセッション間で永続化されません。

前提条件: 

- GitLab Duo CLI 8.68.0以降。

ヘッドレスモードでモデルを選択するには:

1. モデルの[`gitlab_identifier`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml)を見つけます。
1. GitLab Duo CLIを実行するときに、`--model`オプションまたは`GITLAB_DUO_MODEL`環境変数を`gitlab_identifier`値に設定します。

   {{< tabs >}}

   {{< tab title="glab" >}}

   `--model`オプションを使用します:

   ```shell
   glab duo cli --model <gitlab_identifier_for_the_model>
   ```

   `GITLAB_DUO_MODEL`環境変数を使用します:

   ```shell
   GITLAB_DUO_MODEL=<gitlab_identifier_for_the_model> glab duo cli
   ```

   例えば、[`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448)を使用する場合:

   ```shell
   glab duo cli --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex glab duo cli
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   `--model`オプションを使用します:

   ```shell
   duo --model <gitlab_identifier_for_the_model>
   ```

   `GITLAB_DUO_MODEL`環境変数を使用します:

   ```shell
   GITLAB_DUO_MODEL=<gitlab_identifier_for_the_model> duo
   ```

   例えば、[`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448)を使用する場合:

   ```shell
   duo --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex duo
   ```

   {{< /tab >}}

   {{< /tabs >}}

## セッションの切り替え {#switch-sessions}

GitLab Duo Chatセッションは、会話の履歴とワークフローデータを保存し、GitLab Duo CLI、GitLab UI、およびエディタ拡張機能全体で共有されます。

たとえば、ブラウザで会話を開始し、ターミナルで続けることができます。

セッションを参照して切り替えるには:

1. インタラクティブモードで、`/sessions`と入力し、<kbd>Enter</kbd>を押します。
1. 矢印キーを使用して利用可能なセッションのリストをスクロールするか、テキストを入力してリストをフィルターします。
1. セッションを選択し、<kbd>Enter</kbd>を押します。

ヘッドレスモードでセッションに切り替えるには、`--existing-session-id`オプションを使用します。

## Model Context Protocol（MCP）接続 {#model-context-protocol-mcp-connections}

GitLab Duo CLIをローカルまたはリモートのMCPサーバーに接続するには、GitLab IDE拡張機能と同じMCP設定を使用します。手順については、[MCPサーバーを設定する](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-mcp-servers)を参照してください。

## オプション {#options}

GitLab Duo CLIは、次のオプションをサポートしています:

- `-C, --cwd <path>`: 作業ディレクトリを変更します。
- `-h, --help`: GitLab Duo CLIまたは特定のコマンドのヘルプを表示します。例: `duo --help`、`duo run --help`。
- `--log-level <level>`: ログレベルを設定します（`debug`、`info`、`warn`、`error`）。
- `-v`、`--version`: バージョン情報を表示します。
- `--enable-global-skills`: （実験的）ユーザーレベルの[Agent Skills](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills)を有効にします。
- `--model <model>`: セッションに使用するAIモデルを選択します。

ヘッドレスモードの追加オプション:

- `--ai-context-items <contextItems>`: 参照用に追加するコンテキスト項目のJSONエンコード配列。
- `--existing-session-id <sessionId>`: 再開する既存セッションのID。
- `--gitlab-auth-token <token>`: GitLabインスタンスの認証トークン。
- `--gitlab-base-url <url>`: GitLabインスタンスのベースURL（デフォルト: `https://gitlab.com`）。

## コマンド {#commands}

各セットアップで以下のコマンドが利用可能です:

{{< tabs >}}

{{< tab title="glab" >}}

- `glab duo cli`: インタラクティブモードを開始します。
- `glab duo cli log`: ログを表示および管理します。
  - `glab duo cli log last`: 直近のログファイルを開きます。
  - `glab duo cli log list`: すべてのログファイルを一覧表示します。
  - `glab duo cli log tail <args...>`: 直近のログファイルの末尾を表示します。標準のtail引数をサポートします。
  - `glab duo cli log clear`: 既存のログファイルをすべて削除します。
- `glab duo cli run`: ヘッドレスモードを開始します。

{{< /tab >}}

{{< tab title="duo" >}}

- `duo`: インタラクティブモードを開始します。
- `duo config`: 設定と認証設定を管理します。
- `duo log`: ログを表示および管理します。
  - `duo log last`: 直近のログファイルを開きます。
  - `duo log list`: すべてのログファイルを一覧表示します。
  - `duo log tail <args...>`: 直近のログファイルの末尾を表示します。標準のtail引数をサポートします。
  - `duo log clear`: 既存のログファイルをすべて削除します。
- `duo run`: ヘッドレスモードを開始します。

{{< /tab >}}

{{< /tabs >}}

## 環境変数 {#environment-variables}

環境変数を使用してGitLab Duo CLIを設定できます:

- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTP認証パスワード。
- `DUO_WORKFLOW_GIT_HTTP_USER`: Git HTTP認証ユーザー名。
- `GITLAB_BASE_URL`または`GITLAB_URL`: GitLabインスタンスのURL。
- `GITLAB_DUO_MODEL`: セッションに使用するAIモデル。
- `GITLAB_ENABLE_GLOBAL_SKILLS`: （実験的）ユーザーレベルの[Agent Skills](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills)を有効にします。
- `GITLAB_OAUTH_TOKEN`または`GITLAB_TOKEN`: 認証トークン。
- `LOG_LEVEL`: ログレベル。

## プロキシとカスタム証明書の設定 {#proxy-and-custom-certificate-configuration}

ネットワークでHTTPSインターセプトプロキシを使用している場合、またはカスタムSSL証明書が必要な場合は、追加の設定が必要になることがあります。

### プロキシ設定 {#proxy-configuration}

GitLab Duo CLIは、標準のプロキシ環境変数に対応しています:

- `HTTP_PROXY`または`http_proxy`: HTTPリクエスト用のプロキシURL。
- `HTTPS_PROXY`または`https_proxy`: HTTPSリクエスト用のプロキシURL。
- `NO_PROXY`または`no_proxy`: プロキシ経由から除外するホストのカンマ区切りリスト。

### カスタムSSL証明書 {#custom-ssl-certificates}

組織でHTTPSインターセプトプロキシなどのためにカスタム認証局（CA）を使用している場合、証明書エラーが発生することがあります。

```plaintext
Error: unable to verify the first certificate
Error: self-signed certificate in certificate chain
```

証明書エラーを解決するには、次のいずれかの方法を使用します:

- システム証明書ストアを使用する（推奨）: 
  - CA証明書がオペレーティングシステムの証明書ストアにインストールされている場合は、それを使用するようにNode.jsを設定します。これにはNode.js 22.15.0、23.9.0、または24.0.0以降が必要です。
  - GitLab Duo CLIをコンテナで実行する場合は、CA証明書をホストシステムのストアではなく、コンテナのシステムストアにインストールします。

  ```shell
  export NODE_OPTIONS="--use-system-ca"
  ```

- CA証明書ファイルを指定する: 
  - 古いバージョンのNode.jsを使用している場合、またはCA証明書がシステムストアにない場合は、Node.jsに証明書ファイルを直接指定します。ファイルはPEM形式である必要があります。
  - GitLab Duo CLIをコンテナで実行する場合は、コンテナ内の場所へのパスを設定します。ボリュームマウントを使用して証明書ファイルを提供します。

  ```shell
  export NODE_EXTRA_CA_CERTS=/path/to/custom-ca.pem
  ```

### 証明書エラーを無視する {#ignore-certificate-errors}

証明書エラーが引き続き発生する場合は、証明書の検証を無効にできます。

> [!warning]
> 証明書の検証を無効にすることはセキュリティ上のリスクとなります。本番環境で検証を無効にしないでください。

証明書エラーは潜在的なセキュリティ漏洩を警告するためのものです。安全であると確信できる場合にのみ、証明書の検証を無効にしてください。

前提条件: 

- ブラウザで証明書チェーンを検証した、または管理者がこのエラーを無視しても安全であることを確認した。

証明書の検証を無効にするには:

```shell
export NODE_TLS_REJECT_UNAUTHORIZED=0
```

## GitLab Duo CLIを更新する {#update-the-gitlab-duo-cli}

GitLab Duo CLIを最新バージョンに手動で更新するには、セットアップに応じたコマンドを実行します:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo cli --update
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
npm install --global @gitlab/duo-cli@latest
```

{{< /tab >}}

{{< /tabs >}}

## GitLab Duo CLIにコントリビュートする {#contribute-to-the-gitlab-duo-cli}

GitLab Duo CLIへのコントリビュートについては、[開発ガイド](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/development.md)を参照してください。

## 関連トピック {#related-topics}

- [エディタ拡張機能のセキュリティに関する考慮事項](../../editor_extensions/security_considerations.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
- [GitLab Duo Agent Platformをカスタマイズする](../duo_agent_platform/customize/_index.md)
- [GitLab Duo Agent Platformセッション](../duo_agent_platform/sessions/_index.md)
