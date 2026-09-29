---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: インタラクティブモードとヘッドレスモードでGitLab Duo CLIを使用します。
title: GitLab Duo CLIの使用
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Duo CLIは2つのモードで使用できます:

- インタラクティブモード: GitLab UIまたはエディタ拡張機能内のGitLab Duo Chatと同様のチャットエクスペリエンスを提供します。ビルドモードとプランモードをサポートします。
- ヘッドレスモード: Runner、スクリプト、その他の自動化されたワークフローで非インタラクティブに使用できます。

## 前提条件 {#prerequisites}

- GitLab Duo CLIがインストールされ、[セットアップ](set_up.md)されていること。
- [デフォルトのGitLab Duoネームスペース](../profile/preferences.md#namespace-resolution-in-your-local-environment)が設定されているか、GitLab Duoにアクセスできるオープンなプロジェクト。

## インタラクティブモード {#interactive-mode}

GitLab Duo CLIをインタラクティブモードで使用するには:

1. セットアップに応じて、インタラクティブモードを開始するコマンドを入力します:

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

1. ターミナルウィンドウにプロンプト`>`が表示されます。プロンプトの後に質問またはリクエストを入力し、<kbd>Enter</kbd>を押します。

   例: 

   ```plaintext
   What is this repository about?

   Which issues need my attention?

   Help me implement issue 15.

   The pipelines in MR 23 are failing. Please help me fix them.
   ```

GitLab Duo CLIの処理中にレスポンスをキャンセルするには、<kbd>Escape</kbd>を押します。GitLab Duo CLIは現在の操作を停止し、プロンプトに戻ります。

プロンプトの履歴を表示するには<kbd>↑</kbd>キーを使用します。履歴を検索するには<kbd>Control</kbd>+<kbd>R</kbd>を使用します。

### ビルドモードとプランモードを切り替える {#switch-between-build-and-plan-modes}

インタラクティブモードでは、作業中にGitLab Duo CLIを次の2つのモードに切り替えることができます:

| モード                 | 権限 | 仕組み                                                                  |
|----------------------|-------------|-------------------------------------------------------------------------------|
| ビルドモード（デフォルト） | 読み取り/書き込み  | GitLab Duoはタスクを実行し、プロジェクトに変更を加えることができます。               |
| プランモード            | 読み取り専用   | GitLab Duoは、変更を加えることなくプロジェクトを分析し、プランを作成できます。 |

たとえば、最初にプランモードでGitLab Duoと問題について検討します。準備ができたらビルドモードに切り替え、プランを実装するようにGitLab Duoに指示します。

GitLab Duo CLIでは、現在のモードが`>`プロンプトの下に表示します。モードを切り替えるには、<kbd>Tab</kbd>を押します。

### スラッシュコマンド {#slash-commands}

{{< history >}}

- GitLab 19.0リリース時に、GitLab Duo CLI 8.88.0で`/exit`スラッシュコマンドが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.88.0)されました。
- GitLab 19.0リリース時に、GitLab Duo CLI 8.94.0で`/doctor`スラッシュコマンドが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.94.0)されました。
- GitLab 19.0リリース時に、GitLab Duo CLI 8.81.0で`/skills`スラッシュコマンドが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.81.0)されました。
- GitLab 19.0リリース時に、GitLab Duo CLI 8.95.0で`/mcp`スラッシュコマンドが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0)されました。
- GitLab 19.4リリース中に、GitLab Duo CLI 9.17.0で`/goal`スラッシュコマンドが[導入されました](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.17.0)。

{{< /history >}}

インタラクティブモードでは、スラッシュコマンドを使用してGitLab Duo CLIを設定したり、アクションを実行したりできます。プロンプトにスラッシュコマンドを入力し、<kbd>Enter</kbd>を押します。

次のスラッシュコマンドを使用できます:

| コマンド     | 説明                                          |
|-------------|------------------------------------------------------|
| `/copy`     | GitLab Duoの最後のレスポンスをクリップボードにコピーします。  |
| `/doctor`   | GitLab Duo CLI環境の診断情報を表示します。 |
| `/exit`     | GitLab Duo CLIを終了します。                             |
| `/feedback` | バグレポートまたは機能リクエストを送信します。              |
| `/goal`     | 目標達成に向けたセッションを開始します。            |
| `/help`     | 利用可能なスラッシュコマンドのリストを表示します。          |
| `/mcp`      | 設定済みのMCPサーバーとそのステータスを表示します。        |
| `/model`    | 現在のセッションで使用するAIモデルを切り替えます。         |
| `/new`      | 新しいチャットセッションを開始します。                            |
| `/sessions` | セッションを参照、検索、切り替えます。                 |
| `/settings` | 設定パネルを開きます。                             |
| `/skills`   | 現在のプロジェクトで利用可能なAgent Skillsを一覧表示します。  |

独自のスラッシュコマンドを作成することもできます。詳細については、[カスタムスラッシュコマンド](customize.md#custom-slash-commands)を参照してください。

### 設定 {#settings}

{{< history >}}

- GitLab 19.0リリース時に、GitLab Duo CLI 8.90.0で設定パネルが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.90.0)されました。
- GitLab 19.4リリース中に、GitLab Duo CLI 19.11.0で、新しいセッションで作業アイテムを表示する設定が[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.11.0)されました。
- GitLab 19.4リリース中に、GitLab Duo CLI 19.11.0で、テーマを調整する設定が[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.11.0)されました。

{{< /history >}}

設定を変更するには:

1. インタラクティブモードで`/settings`と入力し、<kbd>Enter</kbd>を押します。
1. 矢印キーを使用して、設定のリスト内を移動します。
1. 選択した設定を変更するには、<kbd>Enter</kbd>または<kbd>Space</kbd>を押します。
1. パネルを閉じるには、<kbd>Escape</kbd>を押します。

変更内容はセッション間で保持されます。

次の設定を使用できます:

| 設定                  | 説明                                                                                       |
|--------------------------|---------------------------------------------------------------------------------------------------|
| **Telemetry**            | GitLab Duoの改善に役立てるため、匿名の使用状況データを送信します。                                                  |
| **Enable global skills** | （実験的機能）`~/.agents/skills/`と`~/.gitlab/duo/skills/`から[ユーザーレベルのAgent Skills](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills)を検出します。変更を有効にするには再起動が必要です。 |
| **Notifications**        | [システム通知](#system-notifications)（`auto`または`disabled`）を制御します。                     |
| **新しいセッションで作業アイテムを表示** | 新しいセッションを開始すると、開いている作業アイテムが表示されます。|
| **テーマ**        | テーマ設定を変更します。オプションには、`auto`、`dark`、`light`、`dark high contrast`、および`light high contrast`があります。 |

### システム通知 {#system-notifications}

{{< history >}}

- GitLab 19.1リリース時に、GitLab Duo CLI 8.105.0でシステム通知が[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.105.0)されました。

{{< /history >}}

ターミナルウィンドウがフォーカスされていないときにセッションでユーザーの確認や対応が必要になると（たとえば、タスクが完了した場合や、ツールの承認が必要な場合）、GitLab Duo CLIはシステム通知を送信できます。

通知は、[設定パネル](#settings)にある**通知**設定によって制御されます:

- `auto`（デフォルト）: ターミナルがフォーカスされていない場合に、システム通知を送信します。
- `disabled`: システム通知を送信しません。

### ツールの承認 {#tool-approvals}

{{< history >}}

- GitLab 19.0でセッション中にツールを承認するオプションが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2129)されました。
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.80.0) 8.80.0で導入されました。
- GitLab 19.1でパターンベースのツール承認が[導入](https://gitlab.com/groups/gitlab-org/-/work_items/21850)されました。
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.101.0) 8.101.0で導入されました。
- パターンベースのツール承認は、2026年7月10日に[削除](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3699)されました。
  - [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.3.0) 9.3.0で削除されました。

{{< /history >}}

GitLab Duoがツールを使用する必要がある場合、使用を開始する前に承認を求めるプロンプトが表示されます。たとえば、ファイルを読み取る場合やコマンドを実行する場合などです。

次のオプションがあります:

- **承認**: GitLab Duoはツールを1回使用できます。
- **セッションで承認**: GitLab Duoは、セッションの残りの期間、指定された引数でツールを使用できます。別の引数を使用する場合は、追加の承認が必要です。
- **拒否**: GitLab Duoはツールを使用できません。

> [!note]
> **セッションで承認**オプションを使用するには、管理者がグループまたはインスタンスでこのオプションを有効にする必要があります。詳細については、[ツールの承認](../gitlab_duo_chat/agentic_chat.md#tool-approvals)を参照してください。

## ヘッドレスモード {#headless-mode}

> [!caution]
> ヘッドレスモードは、制御された[サンドボックス環境](../../editor_extensions/security_considerations.md#use-development-containers-for-isolation)で注意して使用してください。

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
- 以前の会話からのコンテキストを保持しません。`run`コマンドを実行するたびに、新しいワークフローが開始されます。

## モデルを選択する {#select-a-model}

{{< history >}}

- GitLab 18.10リリース時に、GitLab Duo CLI 8.68.0で、モデル選択オプションと環境変数が[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.68.0)されました。
- GitLab 18.10リリース時に、GitLab Duo CLI 8.76.0で、モデル選択スラッシュコマンドが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.76.0)されました。

{{< /history >}}

インタラクティブモードまたはヘッドレスモードで使用するモデルを選択できます。

### インタラクティブモードの場合 {#for-interactive-mode}

選択したモデルはセッション間で保持され、コンテキストを失うことなく、会話の途中でモデルを切り替えることができます。

前提条件: 

- GitLab Duo CLI 8.76.0以降。

インタラクティブモードでモデルを選択するには:

1. インタラクティブモードで`/model`と入力し、<kbd>Enter</kbd>を押します。
1. 矢印キーを使用して利用可能なモデルのリストをスクロールするか、モデル名を入力してリストを絞り込みます。
1. モデルを選択し、<kbd>Enter</kbd>を押してそのモデルに切り替えます。

### ヘッドレスモードの場合 {#for-headless-mode}

選択したモデルはセッション間で保持されません。

前提条件: 

- GitLab Duo CLI 8.68.0以降。

ヘッドレスモードでモデルを選択するには:

1. モデルの[`gitlab_identifier`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml)を確認します。
1. GitLab Duo CLIを実行するときに、`--model`オプションまたは`GITLAB_DUO_MODEL`環境変数を`gitlab_identifier`の値に設定します。

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

   たとえば、[`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448)を使用するには:

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

   たとえば、[`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448)を使用するには:

   ```shell
   duo --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex duo
   ```

   {{< /tab >}}

   {{< /tabs >}}

## セッションを切り替える {#switch-sessions}

GitLab Duo Chatセッションには、会話履歴とワークフローのデータが保存されます。セッションは、GitLab Duo CLI、GitLab UI、およびエディタ拡張機能で共有されます。

たとえば、ブラウザで会話を開始し、ターミナルでその会話を続けることができます。

セッションを参照して切り替えるには:

1. インタラクティブモードで`/sessions`と入力し、<kbd>Enter</kbd>を押します。
1. 矢印キーを使用して利用可能なセッションのリストをスクロールするか、テキストを入力してリストを絞り込みます。
1. セッションを選択し、<kbd>Enter</kbd>を押します。

ヘッドレスモードでセッションを切り替えるには、`--existing-session-id`オプションを使用します。

## Model Context Protocol（MCP）接続 {#model-context-protocol-mcp-connections}

GitLab Duo CLIをローカルまたはリモートのMCPサーバーに接続するには、GitLab IDE拡張機能と同じMCP設定を使用します。手順については、[MCPサーバーを設定する](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-mcp-servers)を参照してください。

## 関連トピック {#related-topics}

- [GitLab Duo CLIの完全なリファレンス](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [エディタ拡張機能のセキュリティに関する考慮事項](../../editor_extensions/security_considerations.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
- [GitLab Duo Agent Platformをカスタマイズする](../duo_agent_platform/customize/_index.md)
- [GitLab Duo Agent Platformセッション](../duo_agent_platform/sessions/_index.md)

## トラブルシューティング {#troubleshooting}

GitLab Duo CLIを使用する際、次の問題に遭遇する可能性があります。

### 証明書エラー {#certificate-errors}

証明書エラーが発生する可能性があります:

```plaintext
Error: unable to verify the first certificate
Error: self-signed certificate in certificate chain
```

これらのエラーは、組織がHTTPS傍受プロキシなどでカスタム認証局（CA）を使用している場合に発生します。

証明書エラーを解決するには、次のいずれかの方法を使用します:

- システム証明書ストアを使用する（推奨）: 
  1. CA証明書がオペレーティングシステムの証明書ストアにインストールされている場合は、それを使用するようにNode.jsを設定します。これにはNode.js 22.15.0、23.9.0、または24.0.0以降が必要です。
  1. GitLab Duo CLIをコンテナ内で実行する場合は、ホストシステムのストアではなく、コンテナのシステムストアにCA証明書をインストールします。

     ```shell
     export NODE_OPTIONS="--use-system-ca"
     ```

- CA証明書ファイルを指定する: 
  1. 古いバージョンのNode.jsを使用している場合、またはCA証明書がシステムストアにない場合は、Node.jsに証明書ファイルを直接指定します。ファイルはPEM形式である必要があります。
  1. GitLab Duo CLIをコンテナで実行する場合は、コンテナ内の場所を指すパスを設定します。証明書ファイルを提供するには、ボリュームマウントを使用します。

     ```shell
     export NODE_EXTRA_CA_CERTS=/path/to/custom-ca.pem
     ```

### 証明書エラーを無視する {#ignore-certificate-errors}

証明書エラーが引き続き発生する場合は、証明書の検証を無効にできます。

> [!warning]
> 証明書の検証を無効にすることはセキュリティ上のリスクとなります。本番環境で検証を無効にしないでください。

証明書エラーは潜在的なセキュリティ漏洩を警告するため、検証の無効化が安全であると確信できる場合にのみ、証明書の検証を無効にしてください。

前提条件: 

- ブラウザで証明書チェーンを検証した、または管理者がこのエラーを無視しても安全であることを確認した。

証明書の検証を無効にするには:

```shell
export NODE_TLS_REJECT_UNAUTHORIZED=0
```
