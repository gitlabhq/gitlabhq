---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: セッション
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

セッションは、実行したエージェントおよびフローのステータスと実行データを表示します。

セッションは、IDEまたはUIにおいて、GitLab Duo Chat（エージェント）および基本フローによって作成されます。例:

- Runnerで実行されるフロー（[CI/CDパイプライン修正フロー](../flows/foundational_flows/fix_pipeline.md)など）。これらのセッションは、UIの**自動化** > **セッション**で確認できます。
- IDEで実行されるフロー（[ソフトウェア開発フロー](../flows/foundational_flows/software_development.md)など）。これらのセッションは、IDEの**フロー**タブの**セッション**で確認できます。
- GitLab Duo Chatによって作成されるセッション。これらのセッションは、右側のサイドバーの**GitLab Duo Chat履歴**を選択すると確認できます。
- トリガーによって実行されるフロー。これらのセッションは、UIの**自動化** > **セッション**で確認できます。

GitLab Duo Chat（クラシック）はエージェント型ではないため、セッションを作成しません。

## プロジェクトのセッションを表示する {#view-sessions-for-your-project}

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロールが必要です。

プロジェクトのセッションを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **セッション**を選択します。
1. セッションを選択すると、詳細が表示されます。

## 自分がトリガーしたセッションを表示する {#view-sessions-youve-triggered}

自分がトリガーしたセッションを表示するには:

1. 右サイドバーで、**GitLab Duoのセッション**を選択します。
1. セッションを選択すると、詳細が表示されます。
1. オプション。詳細をフィルタリングして、すべてのログ、または要点のみを表示します。

## GitLab Duo Chat（エージェント）のセッション {#gitlab-duo-chat-agentic-sessions}

チャットはインタラクティブであるため、UI上でより明確に区別する必要があります。Chatの履歴は、セッションをChat専用に切り分けたものと考えることができます。

## 実行中のセッションをキャンセルする {#cancel-a-running-session}

実行中または入力待ちのセッションはキャンセルできます。セッションをキャンセルするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **セッション**を選択します。
1. **詳細**タブで、一番下までスクロールします。
1. **セッションをキャンセル**を選択します。
1. 確認ダイアログで、**セッションをキャンセル**を選択して確定します。

キャンセル後は、次のようになります:

- セッションのステータスが**停止中**に変わります。
- セッションを再開または再起動することはできません。

## セッションの保持 {#session-retention}

セッションは、最後のアクティビティから30日後に自動的に削除されます。保持期間はセッションを操作するたびにリセットされます。たとえば、セッションを20日ごとに操作している場合、自動的に削除されることはありません。

IDEでは、30日の保持期間が終了する前に、セッションを手動で削除することもできます。
