---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セッション
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

この機能は、[GitLabクレジット](../../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

エージェントと実行したフローのステータスと実行データがセッションに表示されます。

セッションは、IDEまたはUIにおいて、GitLab Duo Chat（エージェント）および基本フローによって作成されます。例:

- ランナーで実行されるフロー（[Fix your CI/CD Pipeline Flow](../flows/fix_pipeline.md)など）。これらのセッションは、UIの**自動化** > **セッション**に表示されます。
- IDEで実行されるフロー（[Software development Flow](../flows/software_development.md)など）。これらのセッションは、IDEの**フロー**タブの**セッション**に表示されます。
- GitLab Duo Chatによって作成されたセッション。これらのセッションは、右側のサイドバーの**GitLab Duo Chat履歴**を選択すると表示されます。
- トリガーによって実行されるフロー。これらのセッションは、UIの**自動化** > **セッション**に表示されます。

GitLab Duo Chat（クラシック）はエージェント型ではないため、セッションを作成しません。

## プロジェクトのセッションを表示する {#view-sessions-for-your-project}

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロールが必要です。

プロジェクトのセッションを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **セッション**を選択します。
1. セッションを選択すると、詳細が表示されます。

## トリガーしたセッションを表示する {#view-sessions-youve-triggered}

トリガーしたセッションを表示するには:

1. 右側のサイドバーで、**GitLab Duoのセッション**を選択します。
1. セッションを選択すると、詳細が表示されます。
1. オプション。すべてのログを表示するか、簡潔なサブセットのみを表示するように詳細をフィルタリングします。

## GitLab Duo Chat（エージェント）のセッション {#gitlab-duo-chat-agentic-sessions}

チャットはインタラクティブであるため、UIでより明確に分ける必要があります。Chatの履歴は、Chat専用に存在するセッションのフィルタリングされたビューと考えることができます。

## 実行中のセッションをキャンセル {#cancel-a-running-session}

実行中または入力待ちのセッションをキャンセルできます。セッションをキャンセルするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **自動化** > **セッション**を選択します。
1. **詳細**タブで、一番下までスクロールします。
1. **セッションをキャンセル**を選択します。
1. 確認ダイアログで、**セッションをキャンセル**を選択して確定します。

キャンセル後:

- セッションのステータスが**停止中**に変わります。
- セッションを再開または再起動することはできません。

## セッションの保持 {#session-retention}

セッションは、最後のアクティビティーから30日後に自動的に削除されます。保持期間はセッションを操作するたびにリセットされます。たとえば、セッションを20日ごとに操作している場合、自動的に削除されることはありません。

IDEでは、30日の保持期間が終了する前に、セッションを手動で削除することもできます。
