---
stage: AI-powered features
group: Workflow Catalog
title: フローレジストリフレームワークv1
ignore_in_report: true
---

{{< details >}}

- プラン: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

フローレジストリフレームワークv1を使用して、GitLab Duo Agent Platform上で、コンポーネント、ツール、ルーティングロジックを単一のYAMLファイルで定義することで、カスタムAI活用のワークフローを構築します。

## YAML設定構造 {#yaml-configuration-structure}

すべてのフローは単一のYAMLファイルです。トップレベルの構造は次のとおりです:

```yaml
version: "v1"
environment: ambient

components:
  # List of components (see Component types)

routers:
  # Routing rules between components (see Routers)

flow:
  entry_point: "component_name"   # First component to run

prompts:                           # Optional - inline prompt definitions
  # Locally defined prompts (see Prompts)
```

### 必須フィールド {#required-fields}

| フィールド | 説明 |
|---|---|
| `version` | 常に`"v1"` |
| `environment` | フローインタラクションスタイル - [環境](#environment)を参照してください |
| `components` | フローを構成するコンポーネントのリスト - [コンポーネントタイプ](#component-types)を参照してください|
| `routers` | コンポーネント間のルーティングルール - [ルーター](#routers)を参照してください |
| `flow` | エントリポイントとオプションのコンテキスト入力 - [フローセクション](#flow-section)を参照してください |

### オプションフィールド {#optional-fields}

| フィールド | 説明 |
|---|---|
| `name` | 人が判読可能なフロー名 |
| `description` | フローの説明 |
| `product_group` | チームの所有権（例: `agent_foundations`） |
| `prompts` | インラインプロンプト定義 - [ローカルで定義されたプロンプト](#locally-defined-prompts)を参照してください |
| `response_schemas` | インラインレスポンススキーマ定義 - [レスポンススキーマ](#response-schemas)を参照してください |

### 環境 {#environment}

`environment`フィールドは、人間とAIのインタラクションの期待されるレベルを宣言します。

| 値 | 説明 |
|---|---|
| `ambient` | ハンズオフによるバックグラウンド実行。人間がタスクを委任し、エージェントが自律的に実行します。人間の関与を最小限に抑えます。ほとんどのカスタムフローにこれを使用します。 |
| `chat` | チャットのようなインターフェースを介した、対話型で往復する会話。 |
| `chat-partial` | シングルエージェントフロー用の、簡素化された`chat`バリアント。ボイラープレートをスキップします。厳密に1つの`AgentComponent`が必要です。 |

## クイックスタート {#quick-start}

フローを実行するには、`StartWorkflowRequest`でフロー設定を渡します:

```plaintext
flowConfigId: "<your_flow_id>"
flowConfigSchemaVersion: "v1"
flowVersion: "1.0.0"
```

このページの残りの部分では、フロー設定のYAML構造について文書化しています。コードベースに新しい基本フローを登録するための手順については、[基本フローデベロッパーガイド](foundational_flows/developer.md)を参照してください。

## セッションコンテキスト変数 {#session-context-variables}

各コンポーネントの`inputs`ブロックは、`from: "context:<key>"`を使用してセッションコンテキストから値をプルします。フレームワークは、常に利用可能な一連の変数を自動的に入力します。これらの変数を宣言する必要はありませんが、各コンポーネントの`inputs`ブロックで明示的に参照する必要があります。

### 常に利用可能な変数 {#always-available-variables}

| 変数 | タイプ | 説明 |
|---|---|---|
| `context:goal` | 文字列 | ユーザーのゴールまたは、ワークフローをトリガーしたメッセージ |
| `context:project_id` | 文字列 | GitLabプロジェクトID（数値、文字列として） |
| `context:project_http_url_to_repo` | 文字列 | リポジトリの完全なHTTPSクローンURL |

> [!note]
> `context:project_id`はプロンプトテンプレートに自動的に注入されません。エージェントがGitLab APIツールを呼び出す場合（例: `get_merge_request`、`list_issues`、または`create_merge_request`）、コンポーネントの`inputs`に追加し、プロンプトの`user:`ブロックに`Project ID: {{ project_id }}`を含める必要があります。これを省略すると、フローの失敗の最も一般的な根本原因となります。

### エージェントプラットフォーム標準コンテキスト変数 {#agent-platform-standard-context-variables}

これらの変数は、`flow.inputs`スタンザを宣言した場合にのみ利用可能です。これらはブランチとセッションのメタデータを含み、CI Runnerによって注入されます。

| 変数 | タイプ | 説明 |
|---|---|---|
| `context:inputs.agent_platform_standard_context.primary_branch` | 文字列 | リポジトリのデフォルトブランチ（例: `main`） |
| `context:inputs.agent_platform_standard_context.workload_branch` | 文字列 | CIワークロードRunnerによって使用されるGit参照 |
| `context:inputs.agent_platform_standard_context.session_owner_id` | 文字列 | フローをトリガーしたユーザーのGitLabユーザーID |

フローがブランチを作成したり、マージリクエストを開いたり、またはデフォルトブランチを知る必要がある場合に、これらを宣言します。詳細については、[フローセクション](#flow-section)を参照してください。

## フローセクション {#flow-section}

`flow`セクションでは、エントリポイントと、オプションで、注入する外部コンテキストカテゴリを定義します。

### 最小限 {#minimal}

```yaml
flow:
  entry_point: "my_first_component"
```

### エージェントプラットフォーム標準コンテキストを含む {#with-agent-platform-standard-context}

フローで`primary_branch`、`workload_branch`、または`session_owner_id`が必要な場合に必須です:

```yaml
flow:
  entry_point: "create_feature_branch"
  inputs:
    - category: agent_platform_standard_context
      input_schema:
        primary_branch:
          type: string
          description: The default/primary branch of the repository (for example, 'main', 'master')
        workload_branch:
          type: string
          description: git ref to workload branch
        session_owner_id:
          type: string
          description: Human user's ID that initiated the flow
```

## コンポーネントのタイプ {#component-types}

| コンポーネント | 目的 | AIの関与 | 使用するケース |
|---|---|:---:|---|
| [AgentComponent](#agentcomponent) | ツールを使用した多段階のAI推論 | はい | 反復的な意思決定、会話、または複数ステップのツール使用を必要とする複雑なタスク。 |
| [OneOffComponent](#oneoffcomponent) | 単一ラウンドのAIツール実行 | はい | 組み込みの再試行ロジックを備え、1回のLLM呼び出しで完了可能な境界タスク。 |
| [DeterministicStepComponent](#deterministicstepcomponent) | 固定引数を持つ単一のツールを実行する | いいえ | ツールの引数が直接状態から来る、予測可能で反復可能な操作。 |
| [HumanInputComponent](#humaninputcomponent) | ユーザー入力のリクエストと処理 | いいえ | 承認ゲート、対話型チャット、または人間によるフィードバックが必要な任意のポイント。 |
| [EndComponent / AbortComponent](#endcomponent-and-abortcomponent) | ワークフローを終了する | いいえ | すべてのフローは`"end"`（成功）または`"abort"`（エラー）で終了する必要があります。 |

## AgentComponent {#agentcomponent}

AgentComponentは、AIを活用したフローの主要な構成要素です。これはLLMを使用して以下を行います:

- 入力を処理し、
- プロンプトに基づいて意思決定し、
- ツールを呼び出します。
- 会話履歴を維持します。
- ダウンストリームコンポーネント用の出力を生成します。

### 必須パラメータ {#required-parameters}

| パラメータ | 説明 |
|---|---|
| `name` | 固有識別子。`:`または`.`文字を含めてはなりません。 |
| `type` | `"AgentComponent"`である必要があります。 |
| `prompt_id` | プロンプトテンプレートのID（ローカルまたはレジストリベース）。 |

### オプションパラメータ {#optional-parameters}

| パラメータ | デフォルト | 説明 |
|---|---|---|
| `prompt_version` | 省略された | Semver制約（例: `"^1.0.0"`）。ローカルで定義されたプロンプトを使用するには省略します。 |
| `inputs` | `["context:goal"]` | 入力データソースのリスト。 |
| `toolset` | `[]` | エージェントが利用できるツール。[利用可能なツール](#available-tools)を参照してください。 |
| `description` | なし | スーパーバイザーの下でサブエージェントとして使用される場合に必須です。 |
| `subagents` | なし | サブエージェント名のリスト。[スーパーバイザーモード](#supervisor-mode)を有効にします。 |
| `max_delegations` | 無制限 | スーパーバイザーモードでの最大`delegate_task`呼び出し数。 |
| `response_schema_id` | なし | 構造化出力スキーマのID。 |
| `response_schema_version` | なし | レジストリベーススキーマのSemver。 |
| `model_size_preference` | `null` | `"small"`または`"large"`。 |
| `require_tool_approval` | `false` | 各ツール呼び出しの前に、人間による承認を一時停止します。 |
| `pre_approved_tools` | `[]` | 承認ステップをスキップするツール。 |
| `compaction` | なし | 会話コンパクション設定。 |
| `ui_log_events` | `[]` | UIに表示するイベント。[UIログイベント](#agentcomponent-ui-log-events)を参照してください。 |
| `ui_role_as` | `"agent"` | UIでの表示ロール（`"agent"`または`"tool"`）。 |

### 出力 {#outputs}

| 出力キー | 説明 |
|---|---|
| `context:{name}.final_answer` | エージェントの最終応答（文字列、またはカスタムスキーマを持つディクショナリ）。 |
| `context:{name}.final_answer.{field}` | カスタム応答スキーマを使用する場合の個々のフィールド。 |
| `conversation_history:{name}` | 完全なメッセージ履歴。 |

### 入力 {#inputs}

コンポーネント入力は、セッションコンテキストから値をプルし、それらをプロンプトのテンプレート変数として利用可能にします。`as:`エイリアスは、プロンプトテンプレート内で`{{ variable }}`プレースホルダーと正確に一致する必要があります。

```yaml
# In the component inputs:
inputs:
  - from: "context:goal"
    as: "goal"
  - from: "context:project_id"
    as: "project_id"
  - from: "context:previous_agent.final_answer"
    as: "previous_result"
  - from: "some constant value"
    as: "my_constant"
    literal: true

# In the prompt user block:
user: |
  Project ID: {{ project_id }}
  Goal: {{ goal }}
  Previous result: {{ previous_result }}
```

### プロンプト {#prompts}

AgentComponentはプロンプトを必要とします。フローYAMLにインラインで定義するか（カスタムフローに推奨）、またはAIゲートウェイプロンプトレジストリから参照します。

#### ローカルで定義されたプロンプト {#locally-defined-prompts}

トップレベルの`prompts`ブロックで定義されたインラインプロンプトを使用するには、`prompt_version`を省略します:

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_prompt"
    # prompt_version omitted - uses local prompt

prompts:
  - prompt_id: "my_prompt"
    name: "My Prompt"
    unit_primitives: []           # always include, even if empty
    prompt_template:
      system: |
        You are a helpful assistant.

        When your task is complete, your final answer is a plain text summary
        of what you did. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
      placeholder: history        # include explicitly
    params:
      timeout: 180
```

#### レジストリプロンプト {#registry-prompts}

`prompt_version`を指定して、`ai_gateway/prompts/definitions/`でAIゲートウェイプロンプトレジストリから読み込みます:

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_flow/my_prompt"
    prompt_version: "^1.0.0"
```

#### プロンプト作成のベストプラクティス {#prompt-writing-best-practices}

- エージェントが完了したことを常に伝えます。明示的な停止指示がないと、エージェントはループします。すべての`system:`プロンプトを`"When [condition], your final answer is [what to say]. No further steps are needed after that."`のような文で終了します。
- GitLab APIツールを呼び出すすべてのエージェントに対して、常に`project_id`を`user:`ブロックに渡します。エージェントは単独でそれを発見することはできません。
- 変数名を正確に一致させます。`inputs`内の`as:`エイリアスは、プロンプトテンプレート内の`{{ variable }}`プレースホルダーと一致する必要があります。
- 空の場合でも、インラインプロンプトに`unit_primitives: []`を常に含めます。
- インラインプロンプトテンプレートに`placeholder: history`を常に含めます。

### 利用可能なツール {#available-tools}

ツールを設定するには、`toolset`でそのsnake_case名を渡します。完全なリストは`duo_workflow_service/components/tools_registry.py`にあります。一般的な例:

- ファイル操作: `read_file`、`create_file_with_contents`、`edit_file`、`list_dir`、`find_files`、`grep`
- Git操作: `run_command`、`create_merge_request`、`create_branch`
- GitLab API: `get_issue`、`list_issues`、`get_merge_request`、`gitlab_merge_request_search`、`get_work_item`、`get_repository_file`、`list_repository_tree`、`create_issue_note`、`create_merge_request_note`、`create_commit`、`gitlab_api_get`、`get_project`

### ツールオプション {#tool-options}

LLMがそれらを変更できないように、コンポーネントレベルでツールのパラメータを上書きします:

```yaml
toolset:
  - "get_merge_request"                    # simple string - no overrides
  - "create_merge_request_note":           # object form - override a parameter
      "internal": true
```

オプションは、初期化時にツールのPydantic入力スキーマに対して検証されます。オプションキーが有効なパラメータと一致しない場合、`ValueError`が発生します。実行時、ツールオプションはLLMが提供する値よりも優先されます。

### AgentComponent UIログイベント {#agentcomponent-ui-log-events}

| イベント | 説明 |
|---|---|
| `on_agent_final_answer` | エージェントは最終応答を呼び出します。これにより、セッションUIおよびCIログで完全な最終応答の表示レベルが有効になります。出力に機密データが含まれる場合は無効にします。 |
| `on_tool_execution_success` | ツール呼び出しが正常に完了しました。 |
| `on_tool_execution_failed` | ツール呼び出しが失敗しました。 |
| `on_tool_approval_request` | ツール承認はユーザーの決定を待機中です。UIに承認リクエストを表示するには含める必要があります。 |

### ツール承認 {#tool-approval}

`require_tool_approval: true`の場合、エージェントがツール呼び出しを生成した後、ワークフローは一時停止し、続行する前にユーザーの決定を待ちます。

次の決定タイプがサポートされています:

| 決定 | 動作 |
|---|---|
| `APPROVE` | ツールは正常に実行されます。 |
| `REJECT` | 却下メッセージが履歴に追加され、エージェントは代替アプローチを試します。 |
| `MODIFY` | 却下とユーザーフィードバックが履歴に追加され、エージェントはそれに応じて調整します。 |

ツールは事前承認され、以下のいずれかに表示される場合、承認ステップをスキップします:

- コンポーネントレベル: コンポーネントの`pre_approved_tools`パラメータにリストされています。YAMLでフロー作成者によって制御されます。
- ワークフローレベル: ワークフローの`startRequest`で`pre_approved_agent_privileges`を通じて指定されます。ワークフロー呼び出し元によって呼び出し時に制御されます。

いずれかのソースからすべてのツール呼び出しが事前承認された場合、承認フローは完全にスキップされ、ツールは直ちに実行されます。

```yaml
components:
  - name: "code_editor"
    type: AgentComponent
    prompt_id: "code_assistant"
    prompt_version: "^1.0.0"
    require_tool_approval: true
    pre_approved_tools: ["read_file", "list_dir", "find_files"]
    toolset: ["read_file", "list_dir", "find_files", "edit_file", "run_command"]
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_tool_approval_request"
    inputs: ["context:goal"]
```

### 使用モード {#usage-modes}

| モード | 使用時 | `description`は必須 |
|---|---|---|
| スタンドアロン | フロー内の通常のコンポーネント。 | いいえ |
| 管理 | スーパーバイザーによって委任されたサブエージェント。 | はい |
| スーパーバイザー | `delegate_task`を介してサブエージェントのオーケストレーションを行う。 | いいえ（スーパーバイザー自体に） |

### スーパーバイザーモード {#supervisor-mode}

`subagents`が提供されると、エージェントはスーパーバイザーになり、`delegate_task`と`final_response_tool`に自動的にアクセスできるようになります。LLMが`delegate_task`を呼び出すと、フレームワークは以下を行います:

1. 指定されたサブエージェントの番号が付けられたサブセッションを割り当てまたは再開します。
1. 委任プロンプトでサブエージェントの会話履歴をシードします。
1. 実行をサブエージェントのReActループにルーティングします。
1. サブエージェントの完了時に、結果をスーパーバイザーの履歴に注入し、スーパーバイザーに制御を戻します。

#### 制約 {#constraints}

- `subagents`は少なくとも1つのエントリを含める必要があります。
- リストされているすべてのサブエージェントには、`description`フィールドが必要です。
- `AgentComponent`は最大で1つのスーパーバイザーによって所有されます。
- スーパーバイザープロンプトは、LLMに`delegate_task`と`final_response_tool`をいつ使用するかを指示する必要があります。

#### スーパーバイザーの出力 {#supervisor-outputs}

| 出力キー | 説明 |
|---|---|
| `context:{supervisor_name}.final_answer` | スーパーバイザーの最終応答。 |
| `conversation_history:{supervisor_name}` | スーパーバイザー自身のメッセージ履歴。 |

### 応答スキーマ {#response-schemas}

応答スキーマは、AgentComponentの出力を構造化されたフォーマットに制約をかけます。スキーマがない場合、エージェントは`final_answer`にプレーンな文字列を返します。スキーマがある場合、`final_answer`は辞書であり、各フィールドは`context:{name}.final_answer.{field}`としてもアクセス可能です。

#### インラインスキーマ（カスタムフローに推奨） {#inline-schema-recommended-for-custom-flows}

```yaml
components:
  - name: "code_reviewer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    response_schema_id: "code_review"   # no response_schema_version = inline lookup
    toolset: ["read_file"]

response_schemas:
  - schema_id: "code_review"
    definition:
      "$schema": "http://json-schema.org/draft-07/schema#"
      title: "code_review_response"
      type: object
      properties:
        summary:
          type: string
          description: "Brief summary of findings"
        overall_score:
          type: integer
          minimum: 1
          maximum: 10
      required: [summary, overall_score]
```

#### レジストリスキーマ {#registry-schema}

`response_schema_id`と`response_schema_version`の両方を提供して、`ai_gateway/response_schemas/definitions/`でサーバー側のレジストリから読み込みます:

```yaml
components:
  - name: "code_reviewer"
    type: AgentComponent
    prompt_id: "code_review/detailed_analysis"
    prompt_version: "^1.0.0"
    response_schema_id: "analysis/code_review"
    response_schema_version: "^1.0.0"
```

ダウンストリームコンポーネントは、個々のスキーマフィールドを参照できます:

```yaml
inputs:
  - from: "context:code_reviewer.final_answer.overall_score"
    as: "score"
```

#### スキーマ定義参照 {#schema-definition-reference}

応答スキーマは[JSON Schema](https://json-schema.org/)形式を使用します。重要なトップレベルフィールド:

| フィールド | 説明 |
|---|---|
| `$schema` | スキーマ方言。提供されていない場合、`draft-07`にデフォルト設定されます。 |
| `title` | エージェントが最終応答のために呼び出すツール名にマップされます。既存のツール名と一致してはなりません。競合が発生すると`ValueError`が発生します。 |
| `type` | `"object"`である必要があります。 |
| `properties` | スキーマフィールドを定義するネストされたJSONオブジェクト。ネストされた構造の`"object"`タイプをサポートします。 |
| `required` | 出力に存在しなければならないフィールド名のリスト。 |

次のJSONスキーマ検証制約は、AgentComponent応答スキーマによってサポートされています。

##### 数値制約（整数/数値） {#numeric-constraints-integernumber}

| JSONスキーマ制約 | Pydanticフィールドパラメータ | 説明 |
|---|---|---|
| `minimum` | `ge=` | 最小値（境界値を含む）- 以上。 |
| `maximum` | `le=` | 最大値（境界値を含む）- 以下。 |
| `exclusiveMinimum` | `gt=` | 最小値（境界値を含まない）- より大きい。 |
| `exclusiveMaximum` | `lt=` | 最大値（境界値を含まない）- より小さい。 |
| `multipleOf` | `multiple_of=` | 値はこの数値の倍数でなければなりません。 |

##### 文字列制約 {#string-constraints}

| JSONスキーマ制約 | Pydanticフィールドパラメータ | 説明 |
|---|---|---|
| `minLength` | `min_length=` | 最小文字列長（文字単位）。 |
| `maxLength` | `max_length=` | 最大文字列長（文字単位）。 |
| `pattern` | `pattern=` | 文字列が一致しなければならない正規表現パターン。 |

##### 配列制約 {#array-constraints}

| JSONスキーマ制約 | Pydanticフィールドパラメータ | 説明 |
|---|---|---|
| `minItems` | `min_length=` | 配列内の最小項目数。 |
| `maxItems` | `max_length=` | 配列内の最大項目数。 |

##### 列挙と定数 {#enumeration-and-constants}

| JSONスキーマ制約 | Python型 | 説明 |
|---|---|---|
| `enum` | `Literal[val1, val2, ...]` | フィールドは指定された値のいずれかでなければなりません。 |
| `const` | `Literal[value]` | フィールドは正確にこの値でなければなりません。 |

##### メタデータ {#metadata}

| JSONスキーマフィールド | Pydanticフィールドパラメータ | 説明 |
|---|---|---|
| `default` | `default=` | オプションフィールドのデフォルト値。 |
| `examples` | `examples=` | エージェントにガイダンスとして表示される例の値。 |

##### 完全なスキーマ例 {#full-schema-example}

```json
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "code_review_response_tool",
    "type": "object",
    "properties": {
        "summary": {
            "type": "string",
            "description": "Brief summary of the code review findings"
        },
        "issues_found": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "severity": {
                        "type": "string",
                        "enum": ["low", "medium", "high", "critical"]
                    },
                    "description": { "type": "string" },
                    "file_path": { "type": "string" },
                    "line_number": { "type": "integer" }
                },
                "required": ["severity", "description"]
            }
        },
        "recommendations": {
            "type": "array",
            "items": { "type": "string" }
        },
        "overall_score": {
            "type": "integer",
            "minimum": 1,
            "maximum": 10
        }
    },
    "required": ["summary", "issues_found", "overall_score"]
}
```

### AgentComponentの例 {#agentcomponent-example}

```yaml
components:
  - name: "code_assistant"
    type: AgentComponent
    prompt_id: "code_review_helper"
    prompt_version: "^1.0.0"
    inputs: ["context:goal"]
    require_tool_approval: true
    pre_approved_tools: ["read_file", "list_dir", "find_files"]
    toolset:
      - "read_file"
      - "list_dir"
      - "find_files"
      - "create_file_with_contents"
      - "create_merge_request_note":
          "internal": true
      - "edit_file"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
    ui_role_as: "agent"
```

## HumanInputComponent {#humaninputcomponent}

HumanInputComponentは次のとおりです:

- ワークフローの実行を一時停止します。
- 人間にプロンプトを提示します。
- 人間が応答すると再開します。

レビューゲート、承認、およびフィードバックループに使用します。

### 必須パラメータ {#required-parameters-1}

| パラメータ | 説明 |
|---|---|
| `name` | 固有識別子。`:`または`.`文字を含めてはなりません。 |
| `type` | `"HumanInputComponent"`である必要があります。 |
| `sends_response_to` | 会話履歴に人間の応答を受け取るAgentComponentの名前。[これはすでに実行されているコンポーネントである必要があります](#critical-constraint-sends_response_to-must-point-to-an-already-run-component)。 |
| `message_template` | 人間に表示されるJinja2テンプレート。`inputs`を介して変数を参照する場合があります。 |

### オプションパラメータ {#optional-parameters-1}

| パラメータ | デフォルト | 説明 |
|---|---|---|
| `interaction_type` | `"approval"` | `"approval"`は承認/却下/変更ボタンをレンダリングします。`"input"`はテキスト入力をレンダリングします。これを常に明示的に設定してください - デフォルトに依存しないでください。 |
| `inputs` | `[]` | `message_template`にレンダリングする変数。 |
| `ui_log_events` | `[]` | 常に両方の[UIログイベント](#ui-log-events)を含める必要があります。 |

### 重要な制約: `sends_response_to`はすでに実行されているコンポーネントを指す必要があります {#critical-constraint-sends_response_to-must-point-to-an-already-run-component}

> [!note]
> これは`HumanInputComponent`で最も誤解されやすいフィールドです。

フレームワークは、ターゲットコンポーネントの既存の会話履歴に人間のフィードバックを注入します。そのコンポーネントがまだ実行されていない場合、会話履歴エントリがなく、フレームワークは`KeyError('<component_name>')`でクラッシュします。

> [!note]
> `sends_response_to`には、ゲートがトリガーされる前にすでに実行を完了しているコンポーネントの名前を指定する必要があります。

実際には、これはほとんど常に、ゲートの直前に実行されたエージェントにそれを指し戻すことを意味します。

`modify`ルートターゲットがまだ実行されていない場合、代わりにその`inputs`を通じてフィードバックを渡します:

```yaml
# Correct pattern - sends_response_to points to the already-run agent
- name: "review_gate"
  type: HumanInputComponent
  sends_response_to: "suggester_agent"    # suggester already ran ✅
  interaction_type: "approval"
  ...

# The modify handler gets feedback through inputs instead:
- name: "modify_handler"
  type: AgentComponent
  inputs:
    - from: "context:review_gate.approval"
      as: "human_feedback"               # feedback passed explicitly ✅
```

```yaml
# Wrong pattern - crashes with KeyError
- name: "review_gate"
  sends_response_to: "modify_handler"    # has not run yet → KeyError ❌
```

### UIログイベント {#ui-log-events}

両方のイベントを含める必要があります。これらがないと、ゲートはセッションUIで非表示になります:

| イベント | 説明 |
|---|---|
| `on_user_input_prompt` | プロンプトを表示し、正しい入力コントロール（ボタンまたはテキストボックス）をレンダリングします。 |
| `on_user_response` | UIチャットログに人間の応答をキャプチャします。 |

### 出力 {#outputs-1}

| 出力キー | 説明 |
|---|---|
| `context:{name}.approval` | 人間の決定: `"approve"`、`"reject"`、または`"modify"`。 |
| `conversation_history:{sends_response_to}` | ターゲットエージェントの履歴に注入された人間のメッセージ。 |

### 承認ルーター - 2つではなく3つの値 {#approval-router---three-values-not-two}

`interaction_type: "approval"`の場合、人間は3つの値で応答できます。ルーターは3つすべてを処理する必要があります。そうしないと、`modify`パスは`default_route`にサイレントにフォールスルーします:

| 値 | 意味 |
|---|---|
| `"approve"` | 人間が受け入れました - 次のステップに進みます。 |
| `"reject"` | 人間が却下しました - 終了またはエラー処理にルーティングします。 |
| `"modify"` | 人間がフィードバックを提供しました - 以前のエージェントに改訂のためにルーティングします。 |

```yaml
routers:
  - from: "review_gate"
    condition:
      input: "context:review_gate.approval"
      routes:
        "approve": "next_step"
        "modify": "prior_agent"      # loop back - feedback available in history or inputs
        "reject": "end"
        "default_route": "end"       # always include a fallback
```

### HumanInputComponentチェックリスト {#humaninputcomponent-checklist}

YAMLを保存する前に、以下を検証してください:

- `interaction_type`が明示的に設定されています（`"approval"`または`"input"`）。
- `ui_log_events`には、`"on_user_input_prompt"`と`"on_user_response"`の両方が含まれています。
- ダウンストリームルーターは（`to:`ではなく）`condition:`を使用します。
- ルーターは`"approve"`、`"modify"`、および`"reject"`を明示的に処理します。
- ルーターに`"default_route"`が存在します。
- `sends_response_to`は、ゲートがトリガーされる前にすでに実行されているコンポーネントを指します。
- `modify`ターゲットがまだ実行されていない場合、その`inputs`には`from: "context:{gate_name}.approval" as: "human_feedback"`が含まれます。

### 使用パターン {#usage-patterns}

#### 承認ワークフロー {#approval-workflow}

```yaml
components:
  - name: "user_approval"
    type: HumanInputComponent
    sends_response_to: "proposal_agent"   # proposal_agent already ran
    interaction_type: "approval"
    message_template: |
      Please review the proposed changes and choose an action:
      - ✅ Approve: Proceed
      - ✏️ Modify: Provide feedback for revision
      - ❌ Reject: Discard
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

routers:
  - from: "user_approval"
    condition:
      input: "context:user_approval.approval"
      routes:
        "approve": "executor"
        "modify": "proposal_agent"
        "reject": "end"
        "default_route": "end"
```

#### 対話型チャット {#interactive-chat}

```yaml
components:
  - name: "user_input"
    type: HumanInputComponent
    sends_response_to: "chat_agent"
    interaction_type: "input"
    message_template: "How can I help you today?"
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

routers:
  - from: "user_input"
    to: "chat_agent"
  - from: "chat_agent"
    to: "user_input"  # loop back for continued interaction
```

## DeterministicStepComponent {#deterministicstepcomponent}

LLMの関与なしに、単一のツールを直接実行します。パラメータはフローの状態から抽出されます。複数のインスタンスを連結して、順次ツール操作を実行します。

### 必須パラメータ {#required-parameters-2}

| パラメータ | 説明 |
|---|---|
| `name` | 固有識別子。`:`または`.`文字を含めてはなりません。 |
| `type` | `"DeterministicStepComponent"`である必要があります。 |
| `tool_name` | 実行する単一のツールの名前。 |

### オプションパラメータ {#optional-parameters-2}

| パラメータ | デフォルト | 説明 |
|---|---|---|
| `toolset` | 自動 | ツールを含むツールセット（省略された場合は自動作成されます）。 |
| `inputs` | `[]` | ツールパラメータにマップする入力ソース。 |
| `ui_log_events` | `[]` | UIに表示するイベント。 |
| `ui_role_as` | `"tool"` | UIでの表示ロール。 |

### 出力 {#outputs-2}

| 出力キー | 説明 |
|---|---|
| `context:{name}.tool_responses` | ツールの実行結果。 |
| `context:{name}.error` | 発生したすべてのエラー。 |
| `context:{name}.execution_result` | `"success"`または`"failed"`。 |

### 検証 {#validation}

コンポーネントは、初期化時にツール引数を検証します:

- 指定されたツールがツールセットに存在することを検証します。
- すべての必須ツールパラメータが`inputs`で設定されていることを確認します。
- パラメータがツールの期待されるスキーマに一致することを検証します。

エラーは、ランタイム時ではなく設定時に捕捉されます。

### 例: 複数のツールを連結する {#example-chain-multiple-tools}

```yaml
components:
  - name: "read_config"
    type: DeterministicStepComponent
    inputs:
      - from: "context:goal"
        as: "config_path"
    tool_name: "read_file"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

  - name: "backup_config"
    type: DeterministicStepComponent
    inputs:
      - from: "context:read_config.tool_responses"
        as: "contents"
      - from: "config_backup.txt"
        as: "file_path"
        literal: true
    tool_name: "create_file_with_contents"
```

## OneOffComponent {#oneoffcomponent}

`AgentComponent`と`DeterministicStepComponent`の間に位置します。LLMを使用して単一ラウンドでツール呼び出しを生成し、その後、成功時に終了します。失敗した実行の組み込みの再試行ロジックが含まれています。

タスクが1回のLLM呼び出しで完了できるが、ツールパラメータを決定するためにLLMの推論から恩恵を受ける場合に使用します。

### 必須パラメータ {#required-parameters-3}

| パラメータ | 説明 |
|---|---|
| `name` | 固有識別子。`:`または`.`文字を含めてはなりません。 |
| `type` | `"OneOffComponent"`である必要があります。 |
| `prompt_id` | ツール呼び出しを指示するプロンプト。 |
| `toolset` | 単一ラウンドで利用可能なツール。 |

### オプションパラメータ {#optional-parameters-3}

| パラメータ | デフォルト | 説明 |
|---|---|---|
| `prompt_version` | 省略された | ローカルで定義されたプロンプトを使用するには省略します。 |
| `inputs` | `["context:goal"]` | 入力データソース。 |
| `max_correction_attempts` | `3` | 失敗した実行の再試行制限。 |
| `model_size_preference` | `null` | `"small"`または`"large"`。 |
| `compaction` | なし | 会話コンパクション設定。 |
| `ui_log_events` | `[]` | UIに表示するイベント。 |

### 出力 {#outputs-3}

| 出力キー | 説明 |
|---|---|
| `context:{name}.tool_responses` | ツールの実行結果。 |
| `context:{name}.tool_calls` | 行われたツール呼び出しの記録。 |
| `context:{name}.execution_result` | `"success"`または`"failed"`。 |

### UIログイベント {#ui-log-events-1}

| イベント | 説明 |
|---|---|
| `on_tool_call_input` | ツールがその引数とともに呼び出されようとしています。 |
| `on_tool_execution_success` | ツールが正常に完了しました。 |
| `on_tool_execution_failed` | ツールの実行に失敗しました。 |
| `on_agent_reasoning` | 制限により、エージェントはツール呼び出しを生成できませんでした。 |

### 内部アーキテクチャ {#internal-architecture}

OneOffComponentは3つの内部ノードで構成されます:

- LLMノード（`{name}#llm`）: `AgentNode`を使用して1つ以上のツール呼び出しを生成します。
- ツールノード（`{name}#tools`）: `ToolNodeWithErrorCorrection`を介して、エラー修正を伴ってツール呼び出しを実行します。
- 終了ノード（`{name}#exit`）: 完了と状態のロギングを処理します。

### 例 {#example}

```yaml
components:
  - name: "file_reader"
    type: OneOffComponent
    prompt_id: "read_specific_file"
    prompt_version: "^1.0.0"
    inputs:
      - from: "context:goal"
        as: "target_file"
    toolset:
      - "read_file"
    max_correction_attempts: 2
    ui_log_events:
      - "on_tool_call_input"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
```

## EndComponentおよびAbortComponent {#endcomponent-and-abortcomponent}

両方ともすべてのフローで自動的に利用可能です。定義は不要です。

| 名前 | ルーターキー | ステータス設定 | 使用する場合 |
|---|---|---|---|
| EndComponent | `"end"` | `COMPLETED` | ワークフローが正常に完了しました。 |
| AbortComponent | `"abort"` | `ERROR` | 回復不可能なエラー。再試行回数が上限に達しました。 |

```yaml
routers:
  - from: "my_component"
    to: "end"    # successful completion

  - from: "my_component"
    to: "abort"  # error termination
```

## ルーター {#routers}

ルーターは、各コンポーネントが完了した後、実行がコンポーネント間でどのように移動するかを定義します。

### シンプルなルーター {#simple-router}

無条件に次のコンポーネントにルーティングします:

```yaml
routers:
  - from: "component_a"
    to: "component_b"
```

### 条件付きルーター {#conditional-router}

コンテキスト変数の値に基づいてルーティングします:

```yaml
routers:
  - from: "component_a"
    condition:
      input: "context:component_a.final_answer"
      routes:
        "approved": "component_b"
        "rejected": "end"
        "default_route": "end"   # fallback if value matches nothing
```

サイレントな行き止まりを防ぐために、`"default_route"`を常に含めます。

## よくある落とし穴 {#common-pitfalls}

| 症状 | 根本原因 | 修正 |
|---|---|---|
| エージェントがプロジェクトを見つけられない、またはプロジェクトコンテキストがないと言う | `project_id`がコンポーネント`inputs`にない | GitLab APIツールを呼び出すすべてのコンポーネントに`- from: "context:project_id" as: "project_id"`を追加し、`user:`ブロックに`Project ID: {{ project_id }}`を含めます。 |
| `primary_branch`が未定義である | `flow.inputs`スタンザが見つからない | `agent_platform_standard_context`スキーマで完全な`flow.inputs`ブロックを追加します。 |
| HITLゲートがUIに何も表示しない | `HumanInputComponent`に`ui_log_events`がない | `ui_log_events`に`on_user_input_prompt`と`on_user_response`を追加します。 |
| 変更時の`KeyError('<component_name>')` | `sends_response_to`は、まだ実行されていないコンポーネントを指します。 | `sends_response_to`には直前に実行を完了したエージェントを指定し、その`inputs`を介して修正対象にフィードバックを渡します。 |
| `modify`応答が予期せず`default_route`にルーティングされる | ルーターに`"modify"`ルートがない | `HumanInputComponent`の後で、すべての条件付きルーターに`"modify": "<target_component>"`を追加します。 |
| エージェントが無限にループする | プロンプトに停止指示がない | すべての`system:`プロンプトを明示的な完了指示で終了します。 |
| セッション開始時の`NoneType: None`クラッシュ | エージェントシステムプロンプトの`{{ }}` Jinja2構文 | プラットフォームは、モデルに渡す前にJinja2を介してシステムプロンプトをレンダリングします。プロンプトテキスト内の任意の`{{ variable }}`はテンプレート変数として扱われます。`<<variable>>`表記を文書で使用するか、または`{% raw %}{{ }}{% endraw %}`でエスケープします。 |
| 読み込み時のYAML解析エラー | インラインプロンプトに`unit_primitives: []`が見つからない | 空の場合でも、`unit_primitives: []`を常に含めます。 |
| エージェントが空白の変数を受け取る | `as:`エイリアスが`{{ }}`プレースホルダーと一致しない | `inputs`内の`as:`の値がプレースホルダー名と正確に一致することを検証します。 |

## フローの例 {#flow-examples}

### ローカルプロンプト付きのシンプルなアンビエントフロー {#simple-ambient-flow-with-local-prompt}

```yaml
version: "v1"
environment: ambient

components:
  - name: "code_analyzer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    inputs:
      - from: "context:goal"
        as: "mr_link"
    toolset: ["read_file", "list_dir"]
    ui_log_events:
      - "on_agent_final_answer"

prompts:
  - prompt_id: "code_review_prompt"
    name: "Code Review"
    unit_primitives: []
    prompt_template:
      system: |
        You are an experienced software developer. Conduct a thorough code review
        and provide actionable feedback. When complete, your final answer is a
        summary of your findings. No further steps are needed after that.
      user: |
        Please conduct a code review for the merge request at: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "code_analyzer"
    to: "end"

flow:
  entry_point: "code_analyzer"
```

### 制御されたツール動作のためのツールオプション付きのアンビエントフロー {#ambient-flow-with-tool-options-for-controlled-tool-behavior}

```yaml
version: "v1"
environment: ambient

components:
  - name: "security_agent"
    type: AgentComponent
    prompt_id: "security_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_link"
    toolset:
      - "create_merge_request_note":
          "internal": true
      - "get_merge_request"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_agent_final_answer"

  - name: "general_agent"
    type: AgentComponent
    prompt_id: "general_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_link"
    toolset:
      - "create_merge_request_note"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_agent_final_answer"

prompts:
  - prompt_id: "security_prompt"
    name: "Security Analysis Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are a security analyst. Review the MR and leave an internal note
        summarizing any security concerns. When complete, your final answer is
        a confirmation that the note was posted. No further steps are needed.
      user: |
        Project ID: {{ project_id }}
        Merge Request: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

  - prompt_id: "general_prompt"
    name: "General Summary Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are a helpful assistant. Leave a public note on the MR summarizing
        the changes. When complete, your final answer is a confirmation that
        the note was posted. No further steps are needed.
      user: |
        Project ID: {{ project_id }}
        Merge Request: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "security_agent"
    to: "general_agent"
  - from: "general_agent"
    to: "end"

flow:
  entry_point: "security_agent"
```

### HITL承認フロー {#hitl-approval-flow}

このフローはアクションを提案し、人間によるレビューのために提示し、承認に基づいて実行します。これは正しい`sends_response_to`パターンと、3つのルータールートすべてを示しています。

```yaml
version: "v1"
environment: ambient

components:
  - name: "proposal_agent"
    type: AgentComponent
    prompt_id: "proposal_prompt"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:project_id"
        as: "project_id"
    toolset:
      - "get_issue"
      - "list_issues"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

  - name: "review_gate"
    type: HumanInputComponent
    sends_response_to: "proposal_agent"     # proposal_agent has already run ✅
    interaction_type: "approval"
    message_template: |
      The agent has proposed an action. Please review and choose:
      - ✅ Approve: Proceed with the proposed action
      - ✏️ Modify: Provide feedback - the agent will revise
      - ❌ Reject: Discard
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

  - name: "executor_agent"
    type: AgentComponent
    prompt_id: "executor_prompt"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:project_id"
        as: "project_id"
      - from: "context:proposal_agent.final_answer"
        as: "approved_proposal"
    toolset:
      - "update_issue"
      - "create_issue_note"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

prompts:
  - prompt_id: "proposal_prompt"
    name: "Proposal Agent"
    unit_primitives: []
    prompt_template:
      system: |
        Review the goal and propose a concrete action. Do not execute anything yet.
        When you have formed your proposal, your final answer is a clear description
        of the proposed action. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
      placeholder: history
    params:
      timeout: 180

  - prompt_id: "executor_prompt"
    name: "Executor Agent"
    unit_primitives: []
    prompt_template:
      system: |
        Execute the approved proposal. If the human provided modification feedback,
        it is in your conversation history - incorporate it before executing.
        When execution is complete, your final answer is a confirmation of what
        was done. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
        Approved proposal: {{ approved_proposal }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "proposal_agent"
    to: "review_gate"
  - from: "review_gate"
    condition:
      input: "context:review_gate.approval"
      routes:
        "approve": "executor_agent"
        "modify": "proposal_agent"    # loops back - feedback in proposal_agent history
        "reject": "end"
        "default_route": "end"
  - from: "executor_agent"
    to: "end"

flow:
  entry_point: "proposal_agent"
```

### モデルサイズ設定付きフロー {#flow-with-model-size-preference}

軽量タスクをより小さなモデルにルーティングし、複雑なタスクをより大きなモデルにルーティングします:

```yaml
version: "v1"
environment: ambient

components:
  - name: "explorer"
    type: AgentComponent
    prompt_id: "explorer_agent"
    prompt_version: "^1.0.0"
    model_size_preference: "small"
    inputs: ["context:goal"]
    toolset:
      - "read_file"
      - "list_dir"
      - "find_files"
    ui_log_events:
      - "on_tool_execution_success"

  - name: "implementer"
    type: AgentComponent
    prompt_id: "implementer_agent"
    prompt_version: "^1.0.0"
    model_size_preference: "large"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:explorer.final_answer"
        as: "codebase_context"
    toolset:
      - "read_file"
      - "edit_file"
      - "create_file_with_contents"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

routers:
  - from: "explorer"
    to: "implementer"
  - from: "implementer"
    to: "end"

flow:
  entry_point: "explorer"
```

### マルチエージェントスーパーバイザーフロー {#multi-agent-supervisor-flow}

```yaml
version: "v1"
environment: ambient

components:
  - name: "developer"
    type: AgentComponent
    description: "Implements code changes, creates and edits files based on requirements."
    prompt_id: "developer_agent"
    prompt_version: "^1.0.0"
    toolset:
      - "read_file"
      - "edit_file"
      - "create_file_with_contents"
      - "list_dir"
      - "find_files"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"

  - name: "tester"
    type: AgentComponent
    description: "Writes and runs automated tests to verify code correctness."
    prompt_id: "tester_agent"
    prompt_version: "^1.0.0"
    toolset:
      - "read_file"
      - "create_file_with_contents"
      - "run_command"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"

  - name: "supervisor"
    type: AgentComponent
    prompt_id: "supervisor_agent"
    prompt_version: "^1.0.0"
    inputs: ["context:goal"]
    subagents:
      - name: "developer"
      - name: "tester"
    max_delegations: 20
    toolset:
      - "get_issue"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

routers:
  - from: "supervisor"
    to: "end"

flow:
  entry_point: "supervisor"
```

### 会話型コードレビューのためのチャット部分的なフロー {#chat-partial-flow-for-conversational-code-review}

```yaml
version: "v1"
environment: chat-partial

components:  # exactly one AgentComponent when using chat-partial
  - name: "code_analyzer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    ui_log_events: ["on_agent_final_answer"]
    inputs:
      - from: "context:goal"
        as: "mr_link"
    toolset: ["read_file", "list_dir"]

prompts:
  - prompt_id: "code_review_prompt"
    name: "Code Review Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are an experienced software developer. Conduct a thorough code review
        and mentor engineers on best practices.
      user: |
        Please conduct a code review for the merge request at: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers: []
flow: {}
```
