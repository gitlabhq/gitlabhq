---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo CLIのフック、カスタムスラッシュコマンド、プラグイン、およびネットワーク設定を構成します。
title: GitLab Duo CLIをカスタマイズする
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.0リリース時に、GitLab Duo CLI 8.83.0で、ユーザーレベルのAgent Skillsを有効にするための環境変数とオプションが[実験的機能](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0)されました。

{{< /history >}}

GitLab Duo CLIは次のカスタマイズをサポートしています:

- フックを使用すると、GitLab Duo CLIのライフサイクルにおける特定のタイミングでカスタムコマンドを実行できます。
- カスタムスラッシュコマンドを使用して、CLIをワークフローまたはユースケースにより適応させます。
- プラグインを使用して、Agent Skills、カスタムスラッシュコマンド、およびModel Context Protocol（MCP）サーバーをマーケットプレイスからインストールします。
- GitLab Duo Agent Platformに合わせて設定された[カスタム手順](../duo_agent_platform/customize/_index.md)を、ワークフロー、コーディング標準、またはプロジェクト要件に合わせるために使用します。

## フック {#hooks}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.1リリース時に、GitLab Duo CLI 8.95.0で[実験的機能](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2209)されました。

{{< /history >}}

フックを使用すると、GitLab Duo CLIのライフサイクルにおける特定のタイミングでカスタムコマンドを実行できます。

たとえば、環境に関する情報を収集するスクリプトを実行して、新しいチャットセッションごとに追加のコンテキストを挿入できます。

GitLab Duo CLIは、次の2つのレベルでフックをサポートしています:

- ユーザーレベル（グローバル）: すべてのプロジェクトに適用されます。
- プロジェクトレベル: 特定のプロジェクトにのみ適用されます。チェックアウトされたリポジトリから任意のコードが実行されるのを防ぐため、プロジェクトレベルのフックはデフォルトで無効になっています。

ユーザーレベルとプロジェクトレベルの両方の`hooks.json`ファイルが存在する場合、CLIはフックをマージし、ユーザーレベルのフックを先に実行します。

> [!note]
> セキュリティ上の理由により、機密性の高い環境変数（`GITLAB_TOKEN`、`GITLAB_OAUTH_TOKEN`、`CI_JOB_TOKEN`）はフックプロセスから除外されます。

### フックの実行 {#hook-execution}

フックが実行されると、GitLab Duo CLIは次の処理を行います:

1. セッションメタデータを含むJSONオブジェクトを、コマンドの標準入力に送信します:

   ```json
   {
     "session_id": "abc-123",
     "cwd": "/path/to/project",
     "transcript_path": "",
     "hook_event_name": "SessionStart",
     "source": "startup"
   }
   ```

1. フックプロセスに対して、環境変数`DUO_SESSION_ID`と`DUO_PROJECT_DIR`を設定します。
1. セッションの追加コンテキストとして、コマンドの標準出力を収集します。

フックは、標準出力にプレーンテキストまたはJSONオブジェクトを返すことができます:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Your context string here"
  }
}
```

フックがゼロ以外のステータスで終了した場合やタイムアウトした場合、その内容は警告としてログに記録されますが、セッションの開始はブロックされません。

### フックを作成する {#create-hooks}

GitLab Duo CLIは`SessionStart`イベントをサポートしています。このイベントは、新しいセッションの開始時または既存のセッションの再開時に実行されます。

フックを作成するには:

1. `hooks.json`ファイルを作成します。
   - ユーザーレベルのフックの場合:
     - LinuxまたはmacOSでは、`~/.gitlab/duo/hooks.json`にファイルを作成します。
     - Windowsでは、`%APPDATA%\GitLab\duo\hooks.json`にファイルを作成します。
   - プロジェクトレベルのフックの場合、プロジェクトのルートに次のファイルを作成します: `<project>/.gitlab/duo/hooks.json`
1. ファイル内でフックを定義します。
   - フックをトリガーする各`SessionStart`イベントソース（`startup`または`resume`）に対して、マッチャーグループを作成します。
   - 各マッチャーグループには、オプションの正規表現`matcher`値とコマンドフックの配列が含まれます。

     | フィールド | 説明 |
     |-------|-------------|
     | `matcher` | オプション。イベントソース（`SessionStart`の場合は`startup`または`resume`）に対してテストされる正規表現。すべてに一致させる場合は省略します。 |
     | `hooks[].type` | `"command"`である必要があります。 |
     | `hooks[].command` | 実行するShellコマンド。 |
     | `hooks[].timeout` | オプション。タイムアウトまでの秒数。デフォルト: 30。 |

   - 例: 

     ```json
     {
       "hooks": {
         "SessionStart": [
           {
             "matcher": "startup",
             "hooks": [
               {
                 "type": "command",
                 "command": "cat ~/.my-coding-preferences.md",
                 "timeout": 10
               }
             ]
          }
         ]
       }
     }
     ```

1. プロジェクトレベルのフックがある場合は、GitLab Duo CLIを起動するときにフックを有効にします:

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli --enable-project-hooks
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo --enable-project-hooks
   ```

   {{< /tab >}}

   {{< /tabs >}}

   または、環境変数を設定します:

   ```shell
   export GITLAB_ENABLE_PROJECT_HOOKS=true
   ```

## カスタムスラッシュコマンド {#custom-slash-commands}

{{< history >}}

- GitLab 19.2リリース時に、GitLab Duo CLI 9.2.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3617)されました。

{{< /history >}}

頻繁に使用するプロンプト用のカスタムスラッシュコマンドを作成できます。

GitLab Duo CLIは、次の2つのレベルでカスタムスラッシュコマンドをサポートしています:

- ユーザーレベル: すべてのプロジェクトに適用されます。
- プロジェクトレベル: 特定のプロジェクトにのみ適用されます。

ユーザーレベルのコマンドとプロジェクトレベルのコマンドが同じ名前を共有している場合、プロジェクトレベルのコマンドが優先されます。カスタムスラッシュコマンドは、組み込みのスラッシュコマンドや[Agent Skills](../duo_agent_platform/customize/agent_skills.md#expose-skills-as-slash-commands)のスラッシュコマンドをオーバーライドできません。

### カスタムスラッシュコマンドを作成する {#create-a-custom-slash-command}

カスタムスラッシュコマンドを作成するには、Markdownファイルを作成します。

ファイル名がコマンド名となり、ファイルの内容がプロンプトになります。

たとえば、`daily.md`という名前のファイルを作成すると、`/daily`コマンドが作成されます:

1. `commands`ディレクトリを作成します:
   - プロジェクトレベルのコマンドの場合、プロジェクトのルートにディレクトリを作成します: `<project>/.agents/commands/`。
   - ユーザーレベルのコマンドの場合、次のいずれかの場所を使用します:
     - GitLab Duoの他のカスタマイズファイルとともにコマンドを保存する場合:
       - LinuxまたはmacOSでは、`~/.gitlab/duo/commands/`にディレクトリを作成します。
       - Windowsでは、`%APPDATA%\GitLab\duo\commands\`にディレクトリを作成します。
       - `GLAB_CONFIG_DIR`または`XDG_CONFIG_HOME`を設定している場合、`$GLAB_CONFIG_DIR/commands/`または`$XDG_CONFIG_HOME/gitlab/duo/commands/`を使用します。両方が設定されている場合、`GLAB_CONFIG_DIR`が優先されます。
     - 他のAIツールとコマンドを共有する場合:
       - LinuxまたはmacOSでは、`~/.agents/commands/`にディレクトリを作成します。
       - Windowsでは、`%USERPROFILE%\.agents\commands\`にディレクトリを作成します。
1. そのディレクトリにMarkdownファイルを作成します。ファイル名にはコマンド名を使用します。コマンド名は文字または数字で始める必要があり、使用できるのは文字、数字、ハイフン、アンダースコアのみです。
1. ファイルにプロンプトを追加します。
1. オプション。ファイルの先頭にあるYAMLフロントマターに`description`フィールドを追加します。説明は、スラッシュコマンドメニューでコマンドの横に表示されます。

   たとえば、`daily.md`で定義された`/daily`コマンドは次のようになります:

   ```markdown
   ---
   description: Prepare a daily report
   ---

   Use `glab todo list` to fetch my open TODO items. Give me a concise morning report ranked by priority.
   ```

1. GitLab Duo CLIを再起動します。CLIは起動時にカスタムスラッシュコマンドを検出します。

### カスタムスラッシュコマンドを使用する {#use-a-custom-slash-command}

インタラクティブモードで、プロンプトにスラッシュコマンドを入力し、<kbd>Enter</kbd>を押します。GitLab Duo CLIは、ファイルの内容をプロンプトとして送信します。

コマンド名の後に入力したテキストは、プロンプトの末尾に追加されます。

カスタムスラッシュコマンドが実行する内容をカスタマイズするには、追加のテキストを使用します。

例: `/daily prioritize my milestone deliverables`。

## プラグイン {#plugins}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab Duo CLI 9.10.0で、[実験](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.10.0)されました（GitLab 19.3リリース時）。

{{< /history >}}

GitLab Duo CLIに機能を追加するためにプラグインを使用します。

プラグインは、GitLab Duo CLI用の拡張機能をバンドルするディレクトリです。プラグインは、[Agent Skills](../duo_agent_platform/customize/agent_skills.md)、[カスタムスラッシュコマンド](#custom-slash-commands)、および[MCPサーバー](../gitlab_duo/model_context_protocol/mcp_clients.md)をバンドルできます。

マーケットプレイスは、Gitリポジトリまたはローカルディレクトリ内の利用可能なプラグインのカタログです。`marketplace.json`ファイルには、利用可能なプラグインとそれらの場所がリストされています。

プラグインを使用するには、それを含むマーケットプレイスを登録し、そのマーケットプレイスからプラグインをインストールします。プラグインは`<plugin>@<marketplace>`として識別されます。

既存のコミュニティプラグインエコシステムとの互換性のため、GitLab Duo CLIは`.claude-plugin/marketplace.json`ファイルも読み取ります。既存のプラグインマーケットプレイスは、変更なしでGitLab Duo CLIと連携します。

前提条件: 

- [GitLab Duo CLIをセットアップ](set_up.md)します。
- Gitリポジトリからマーケットプレイスを追加する場合は、Gitを使用します。

### マーケットプレイスを登録する {#register-a-marketplace}

プラグインをインストールする前に、それを含むマーケットプレイスを登録する必要があります。

プラグインを初めて使用すると、GitLab Duo CLIは公式のGitLabマーケットプレイスである[`gitlab-duo-plugins`](https://gitlab.com/gitlab-org/ai/gitlab-duo-plugins)を自動的に登録します。このマーケットプレイスを削除した場合、GitLab Duo CLIは再度登録しません。

マーケットプレイスを登録するには:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add <source>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add <source>
```

{{< /tab >}}

{{< /tabs >}}

`<source>`は次のいずれかです:

| ソースタイプ      | 形式                                                                                     | 例                                          |
|-------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------|
| Gitリポジトリ    | `git clone`が受け入れるURL。オプションで`#<ref>`を追加して、ブランチまたはタグを固定します。          | `https://gitlab.com/group/marketplace.git#stable` |
| ローカルディレクトリ   | 絶対パスまたは相対パス。`~`はホームディレクトリに展開されます。                       | `~/marketplaces/internal`                        |

例: 

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add https://gitlab.com/example-group/example-marketplace.git
```

```shell
glab duo plugin marketplace add ~/marketplaces/internal
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add https://gitlab.com/example-group/example-marketplace.git
```

```shell
duo plugin marketplace add ~/marketplaces/internal
```

{{< /tab >}}

{{< /tabs >}}

GitLab Duo CLIは、`marketplace.json`ファイル内の`name`フィールドによってマーケットプレイスを識別します。

#### マーケットプレイスからプラグインを自動的に更新する {#automatically-update-plugins-from-a-marketplace}

マーケットプレイスからインストールしたプラグインを自動的に更新するには、`--auto-update`オプションを指定してマーケットプレイスを登録します:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add <source> --auto-update
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add <source> --auto-update
```

{{< /tab >}}

{{< /tabs >}}

GitLab Duo CLIが起動すると、このマーケットプレイスからインストールされたプラグインが、確認なしでバックグラウンドで更新されます。プラグインが更新されると、GitLab Duo CLIは新しいバージョンを読み込むために再起動を促します。

#### 登録されているマーケットプレイスをリストする {#list-registered-marketplaces}

登録済みのマーケットプレイスをリストするには:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace list
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace list
```

{{< /tab >}}

{{< /tabs >}}

各マーケットプレイスについて、GitLab Duo CLIは以下を表示します:

- マーケットプレイスのソース。
- マーケットプレイスが最後に更新された日時。
- マーケットプレイスが持つプラグインの数。
- マーケットプレイスの自動更新が有効かどうか。

#### 利用可能なマーケットプレイスプラグインをリストする {#list-available-marketplace-plugins}

マーケットプレイスが提供するプラグインをリストするには:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace show <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace show <name>
```

{{< /tab >}}

{{< /tabs >}}

各プラグインについて、GitLab Duo CLIはバージョン、説明、およびプラグインがインストールされている場所（存在する場合）を表示します。

#### マーケットプレイスを更新する {#update-a-marketplace}

マーケットプレイスのカタログをそのソースから更新するには:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace update <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace update <name>
```

{{< /tab >}}

{{< /tabs >}}

#### マーケットプレイスを削除する {#remove-a-marketplace}

登録されているマーケットプレイスを削除するには:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace remove <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace remove <name>
```

{{< /tab >}}

{{< /tabs >}}

> [!warning]
> マーケットプレイスを削除すると、そこからインストールしたすべてのプラグインもアンインストールされます。

### プラグインのインストールと管理 {#install-and-manage-plugins}

プラグインをインストールする際に、スコープを選択します。スコープは、GitLab Duo CLIが更新する設定ファイルと、インストールが適用される対象を決定します。

| スコープ               | 設定ファイル                          | 用途                                                            |
|----------------------|----------------------------------------------|------------------------------------------------------------------------|
| `user`（デフォルト）     | `<config dir>/plugins.json`                 | すべてのプロジェクト用のプラグイン。                                       |
| `project`            | プロジェクト内の`.gitlab/duo/plugins.json`   | チーム共有のプラグイン。このファイルをリポジトリにコミットします。           |
| `local`              | プロジェクト内の`.gitlab/duo/plugins.local.json` | 個人の、プロジェクトごとのプラグイン。このファイルを`.gitignore`に追加します。 |

`<config dir>`は、LinuxおよびmacOSでは`~/.gitlab/duo`、Windowsでは`%APPDATA%\GitLab\duo`です。

登録されているマーケットプレイスからプラグインをインストールするには:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin install <plugin>@<marketplace> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin install <plugin>@<marketplace> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

`--scope`を指定しない場合、GitLab Duo CLIは`user`スコープを使用します。

例: 

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin install my-plugin@my-marketplace
```

```shell
glab duo plugin install my-plugin@my-marketplace --scope project
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin install my-plugin@my-marketplace
```

```shell
duo plugin install my-plugin@my-marketplace --scope project
```

{{< /tab >}}

{{< /tabs >}}

#### インストール後の有効化状態 {#enabled-state-after-installation}

プラグインをインストールすると、GitLab Duo CLIは、プラグインがスコープの設定ファイルで有効になっているかどうかを記録します。初期状態を決定するために、GitLab Duo CLIは優先順位の高い順に以下を使用します:

1. 対象スコープまたはより広範囲のスコープで以前にプラグインに対して記録した有効または無効の設定。たとえば、プラグインを無効にし、アンインストールし、その後再インストールした場合、プラグインは無効のままになります。
1. プラグインのマーケットプレイスカタログエントリにある`defaultEnabled`値。
1. プラグインの`plugin.json`マニフェストにある`defaultEnabled`値。

これらのいずれも設定されていない場合、プラグインは有効になります。

#### インストールされているプラグインをリストする {#list-installed-plugins}

インストールされているプラグインをリストするには:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin list
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin list
```

{{< /tab >}}

{{< /tabs >}}

インストールされているプラグインはスコープごとにグループ化され、各プラグインが有効になっているかどうかがリストに表示されます。

#### プラグインを有効または無効にする {#enable-or-disable-a-plugin}

プラグインを有効、無効、またはアンインストールする際に、その名前だけで識別子を識別できます。複数のマーケットプレイスから同じプラグイン名がインストールされている場合は、完全な`<plugin>@<marketplace>`識別子を使用します。

インストールされているプラグインを有効または無効にするには:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin enable <plugin> [--scope user|project|local]
glab duo plugin disable <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin enable <plugin> [--scope user|project|local]
duo plugin disable <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

複数のスコープでプラグインを有効または無効にする場合、最も特定のスコープが優先されます: `local`、次に`project`、次に`user`。

#### プラグインを更新する {#update-a-plugin}

プラグインを、そのマーケットプレイスから利用可能な最新バージョンに更新するには:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin update <plugin>@<marketplace>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin update <plugin>@<marketplace>
```

{{< /tab >}}

{{< /tabs >}}

更新は、プラグインがインストールされているすべてのスコープに適用されます。

#### プラグインをアンインストールする {#uninstall-a-plugin}

プラグインをアンインストールするには:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin uninstall <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin uninstall <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

アンインストールすると、プラグインは設定から削除されます。

### インストール済みのプラグインを使用する {#use-an-installed-plugin}

プラグインをインストールして有効にすると、GitLab Duo CLIは次回起動時に、プラグインがバンドルするすべてのものを検出します:

- スキルは他のAgent Skillsと同じ方法で利用可能になります。
- カスタムスラッシュコマンドがスラッシュコマンドメニューに表示されます。組み込みスラッシュコマンド、Agent Skillsスラッシュコマンド、および独自のカスタムスラッシュコマンドは、同じ名前のプラグインコマンドよりも優先されます。
- MCPサーバーは、設定済みのMCPサーバーとともに読み込まれ、同様に[ツールの承認](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-tool-approval)が必要です。サーバーの出所を識別するために、GitLab Duo CLIはサーバー名にプラグイン名をプレフィックスとして付けます。

### マーケットプレイスを作成する {#create-a-marketplace}

マーケットプレイスを作成するには、Gitリポジトリまたはローカルディレクトリのルートに`marketplace.json`ファイルを追加します。例: 

```json
{
  "name": "my-marketplace",
  "owner": {
    "name": "Your Name"
  },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "description": "A short description of the plugin."
    }
  ]
}
```

`plugins`の各エントリは、`source`をマーケットプレイスのルートに対する相対パスに設定し、`./`で始める必要があります。

### プラグインを作成する {#create-a-plugin}

プラグインは、オプションの`plugin.json`マニフェストと、プラグインがバンドルする拡張機能（スキル、カスタムスラッシュコマンド、MCPサーバー）を含むディレクトリです。

`plugin.json`マニフェストは次のフィールドをサポートしています:

| フィールド             | 必須 | 説明                                              |
|--------------------|----------|--------------------------------------------------------------|
| `name`             | はい      | プラグイン名。                                            |
| `version`          | いいえ       | プラグインのバージョン。                                         |
| `description`      | いいえ       | プラグインの簡単な説明。                            |
| `defaultEnabled`   | いいえ       | インストール時にプラグインがデフォルトで有効になるかどうか。      |

例: 

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "A short description of the plugin.",
  "defaultEnabled": true
}
```

既存のコミュニティプラグインとの互換性のため、GitLab Duo CLIは`.claude-plugin/plugin.json`からマニフェストも読み取ります。

プラグインに拡張機能をバンドルするには:

- スキル: プラグイン内の`skills/<skill-name>/`ディレクトリに`SKILL.md`ファイルを追加します。`SKILL.md`ファイル形式については、[スキルを作成](../duo_agent_platform/customize/agent_skills.md#create-skills)するを参照してください。
- カスタムスラッシュコマンド: プラグイン内の`commands/`ディレクトリにMarkdownファイルを追加します。ファイル名はコマンド名で、ファイル形式は[カスタムスラッシュコマンド](#create-a-custom-slash-command)と同じです。
- MCPサーバー: プラグインのルートに`.mcp.json`ファイルを追加します。ファイル形式は[MCP設定形式](../gitlab_duo/model_context_protocol/mcp_clients.md#configuration-format)と同じです。プラグイン内のファイルを参照するには、プラグインがインストールされているディレクトリに解決される`${DUO_PLUGIN_ROOT}`変数を使用します。

たとえば、スキル、カスタムスラッシュコマンド、およびMCPサーバーをバンドルする1つのプラグインを持つマーケットプレイスリポジトリは次のとおりです:

```plaintext
my-marketplace/
├── marketplace.json
└── plugins/
    └── my-plugin/
        ├── plugin.json
        ├── .mcp.json
        ├── commands/
        │   └── my-command.md
        └── skills/
            └── my-skill/
                └── SKILL.md
```

GitLab Duo CLIは、プラグインのバージョンを優先順位の高い順に以下から決定します:

1. プラグインの`plugin.json`にある`version`フィールド。
1. マーケットプレイス`marketplace.json`内のプラグインのエントリにある`version`フィールド。

どちらのフィールドも設定されていない場合、プラグインのバージョンは`unknown`です。

## 関連トピック {#related-topics}

- [GitLab Duo CLI完全参照](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [GitLab Duo Agent Platformをカスタマイズする](../duo_agent_platform/customize/_index.md)
- [Agent Skills](../duo_agent_platform/customize/agent_skills.md)
