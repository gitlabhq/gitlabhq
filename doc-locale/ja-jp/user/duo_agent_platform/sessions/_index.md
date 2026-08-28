---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 実行したエージェントとフローのステータスおよび実行データを表示および管理します。
title: セッション
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

セッションは、実行したエージェントおよびフローのステータスと実行データを表示します。

セッションはGitLab Duo Agentic Chatと、IDEまたはUI内の基本フローによって作成されます。例:

- Runner上で実行されるフロー。例えば、[CI/CDパイプライン修正フロー](../flows/foundational_flows/fix_pipeline.md)のようなものです。これらのセッションは、UIの**AI** > **セッション**の下に表示されます。
- IDEで実行されるフロー。例えば、[ソフトウェア開発フロー](../flows/foundational_flows/software_development.md)のようなものです。これらのセッションは、IDEの**フロー**タブの**セッション**で確認できます。
- GitLab Duo Chatによって作成されるセッション。これらのセッションは、右側のサイドバーの**GitLab Duo Chat履歴**を選択すると確認できます。
- トリガーによって実行されるフロー。これらのセッションは、UIの**AI** > **セッション**の下に表示されます。

## プロジェクトのセッションを表示する {#view-sessions-for-your-project}

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロールが必要です。

プロジェクトのセッションを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**AI** > **セッション**を選択します。
1. セッションを選択すると、詳細が表示されます。

## 自分がトリガーしたセッションを表示する {#view-sessions-youve-triggered}

自分がトリガーしたセッションを表示するには:

1. 右サイドバーで、**GitLab Duoのセッション**を選択します。
1. セッションを選択すると、詳細が表示されます。
1. オプション。詳細をフィルタリングして、すべてのログ、または要点のみを表示します。

## GitLab Duo Agentic Chatセッション {#gitlab-duo-agentic-chat-sessions}

チャットはインタラクティブであるため、UI上でより明確に区別する必要があります。Chatの履歴は、セッションをChat専用に切り分けたものと考えることができます。

GitLab Duo CLIでチャットセッションを参照して切り替える方法については、[セッションを切り替える](../../gitlab_duo_cli/use.md#switch-sessions)を参照してください。

## 実行中のセッションをキャンセルする {#cancel-a-running-session}

実行中または入力待ちのセッションはキャンセルできます。セッションをキャンセルするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**AI** > **セッション**を選択します。
1. **詳細**タブで、一番下までスクロールします。
1. **セッションをキャンセル**を選択します。
1. 確認ダイアログで、**セッションをキャンセル**を選択して確定します。

キャンセル後は、次のようになります:

- セッションのステータスが**停止中**に変わります。
- セッションを再開または再起動することはできません。

## エージェントのアクションをレビューおよび制御する {#review-and-control-agent-actions}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提条件: 

- カスタムフローには、フロー定義YAMLに[`HumanInputComponent`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/flow_registry/v1.md#humaninputcomponent)が含まれている必要があります。

フローが人間とのインタラクションチェックポイントに達すると、実行は一時停止し、セッションは入力を待機します。

### 承認通知 {#approval-notifications}

フローがチェックポイントで一時停止すると、GitLabは2つの方法で通知します:

- **To-Doアイテム**: **Duo Workflowの承認が必要**というラベルが付いたTo-Do項目が、**マイワーク** > **To-Doリスト**に追加されます。その項目は、アクションを実行できるセッションに直接リンクしています。GitLabは、リクエストの承認、拒否、修正のいずれか、またはワークフローがキャンセルまたは停止された場合に、To-Do項目を自動的に完了としてマークします。
- **メール**: ワークフロー名、それが属するプロジェクト、完了したアクションの概要と保留中のリクエスト、および承認UIへの直接リンクを含むメール通知が送信されます。

### エージェントのチェックポイントに応答する {#respond-to-an-agent-checkpoint}

エージェントのチェックポイントをレビューして応答するには:

1. GitLab Duoサイドバーで、**セッション**を選択します。
1. レビュー待ちのセッションを選択します。
1. エージェントが完了したアクションと、提案されている次のステップをレビューします。
1. 次のいずれかを選択します。
   - **承認**: エージェントが計画されたアクションを続行できるようにします。
   - **拒否**: フローの実行を直ちに停止します。
   - **修正**: エージェントにフィードバックまたは提案を送信します。エージェントは、別のレビューのためにチェックポイントに戻ります。

## セッションの保持 {#session-retention}

セッションは、最後のアクティビティから30日後に自動的に削除されます。保持期間はセッションを操作するたびにリセットされます。たとえば、セッションを20日ごとに操作している場合、自動的に削除されることはありません。

IDEでは、30日の保持期間が終了する前に、セッションを手動で削除することもできます。
