---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: カスタムフローYAMLスキーマ
---

{{< details >}}

- プラン: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

カスタムフローは、[flowレジストリv1仕様](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/flow_registry/v1.md)構文を使用します。v1仕様では、`version`、`environment`、`components`、`prompts`、`routers`、`flow`などのフィールドを含む、完全なYAML構造を定義します。

v1仕様の一部のフィールドは、カスタムフローで制限されています。詳細については、[restricted fields](#restricted-fields)を参照してください。

## トリガータイプごとの目標値 {#goal-values-by-trigger-type}

カスタムフローを設計する際、目標値はフローを開始するトリガータイプによって異なります。フローには複数のトリガータイプを設定でき、各トリガータイプは`context:goal`として異なる値を渡します。フローは、設定する各トリガータイプの目標フォーマットを処理する必要があります。

トリガータイプに関する詳細については、[トリガー](../../duo_agent_platform/triggers/_index.md)を参照してください。

コンポーネントは、`inputs`フィールドを介して目標にアクセスします:

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - "context:goal"
```

### メンションイベント {#mention-events}

ユーザーがコメントでフローサービスアカウントをメンションすると、完全なコメントテキストとリソースコンテキストが目標として渡されます。

目標はこのフォーマットを使用します:

```plaintext
Input: <comment_text>
Context: {<resource_type> IID: <iid>}
```

たとえば、ユーザーがイシュー`#2`で`@ai-my-flow Can you work on this?`と書き込んだ場合、目標は次のようになります:

```plaintext
Input: @ai-my-flow Can you work on this?
Context: {Issue IID: 2}
```

### 割り当ておよびレビュアー割り当てイベント {#assign-and-assign-reviewer-events}

フローサービスアカウントがイシューまたはマージリクエストに割り当てられた場合、またはレビュアーとして割り当てられた場合、リソースのIIDが目標として渡されます。

たとえば、フローサービスアカウントがマージリクエスト`!10`のレビュアーとして割り当てられた場合、`context:goal`の値は`10`です。

IIDを`context:project_id`とともに使用してリソースを読み取ります:

```yaml
components:
  - name: "review_mr"
    type: AgentComponent
    prompt_id: "review_mr_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_iid"
```

### パイプラインイベント {#pipeline-events}

パイプラインイベントがフローをトリガーすると、完全な[パイプラインイベントWebhookペイロード](../../project/integrations/webhook_events.md#pipeline-events)が目標として渡されます。

## 制限されたフィールド {#restricted-fields}

v1仕様の一部のフィールドと機能は、カスタムフローがGitLabで一貫して機能するように制限されています。

### `environment` {#environment}

カスタムフローでは、`environment`フィールドは`ambient`の値のみをサポートします。

`chat`と`chat-partial`の値はサポートされていません。

### プロンプト内の`model` {#model-in-prompts}

`prompts`エントリ内の`model`フィールドはサポートされていません。

モデルは、グループまたはインスタンス設定で構成されたモデルプロバイダーによって決定されます。

### `AgentComponent`フィールド {#agentcomponent-fields}

`response_schema_id`と`response_schema_version`フィールドはサポートされていません。

### `OneOffComponent`フィールド {#oneoffcomponent-fields}

`ui_role_as`フィールドはサポートされていません。

### プロンプトパラメータ内の`stop` {#stop-in-prompt-parameters}

`params`エントリ内の`stop`フィールドはサポートされていません。

### トップレベルフィールド {#top-level-fields}

v1仕様の`name`、`description`、および`product_group`フィールドはサポートされていません。カスタムフローはこれらのフィールドを拒否します。
