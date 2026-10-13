---
stage: Agent Foundations
group: Agent Developer
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: プロジェクトまたはグループのWebhookでGitLab Duoフローのライフサイクルイベントを受信します。
title: Webhookコールバック
---

{{< details >}}

- プラン: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.4で`duo_flow_callback_hooks`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249145)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

[Flows API](../../../api/duo_agent_platform_flows.md)でフローをトリガーすると、GitLabは指定したWebhookにフローのライフサイクルイベントを送信できます。これにより、APIをポーリングしてフローのステータスを確認する代わりに、フローの開始時、完了時、または失敗時に対応できます。

プロジェクトまたはグループでWebhookを使用できます。子プロジェクトはWebhookを継承します。これは、トップレベルグループのWebhookが、そのグループ内のすべてのプロジェクトのフローを処理することを意味します。

## 前提条件 {#prerequisites}

Webhookがフローイベントを受信するには、以下の前提条件が満たされていることを確認してください:

- プロジェクトまたはグループ用にWebhookが[作成](../../project/integrations/webhooks.md#create-a-webhook)されており、そのWebhookで[コールバックが有効](#turn-on-callbacks-for-a-webhook)になっている。
- Webhookは、フローが実行されるプロジェクトまたはグループ、あるいはそのプロジェクトまたはグループの祖先グループのいずれかに属している。
- Webhookが[システムWebhook](../../../administration/system_hooks.md)ではないこと。

## Webhookのコールバックを有効にする {#turn-on-callbacks-for-a-webhook}

前提条件: 

- プロジェクトのWebhookの場合、プロジェクトのメンテナーまたはオーナーロールが必要です。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。

Webhookのコールバックを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**設定** > **Webhooks**を選択します。
1. **新しいWebhookを追加**を選択するか、既存のWebhookの場合は**編集**を選択します。
1. **GitLab Duo Agent Platform**の下で、**このWebhookにDuoフローイベントを送信**チェックボックスを選択します。
1. **Webhookを追加**または**変更を保存**を選択します。

`duo_flow_callback_enabled`属性は、[プロジェクトWebhook API](../../../api/project_webhooks.md)または[グループWebhook API](../../../api/group_webhooks.md)で設定することもできます。いずれかのAPIを使用してWebhookをリストし、コールバックを有効にしたWebhookのIDを見つけます。

コールバックを有効にするために必要なロールは、Webhookにのみ適用されます。Webhookを参照するフローをトリガーするユーザーは、それらを必要としません。

## フローのコールバックを受信する {#receive-callbacks-for-a-flow}

前提条件: 

- [フローの前提条件](_index.md#prerequisites)を満たしている必要があります。

コールバックを受信するには、[フローをトリガー](../../../api/duo_agent_platform_flows.md#trigger-a-flow)するときに、Webhook IDを`callback_hook_id`属性として渡します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "workflow_definition": "developer/v1",
    "start_workflow": true,
    "callback_hook_id": 42,
    "client_reference": "run-abc123"
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

GitLabが送信するイベントと各ペイロードの構造については、[GitLab Duoフローイベント](../../project/integrations/webhook_events.md#gitlab-duo-flow-events)を参照してください。

### コールバックをリクエストと関連付ける {#correlate-callbacks-with-a-request}

オプションの`client_reference`属性を使用して、コールバックとフローをトリガーしたリクエストを関連付けます。GitLabは、そのフローのすべてのコールバックでその値をエコーバックし、解釈しません。

## エンドポイントでのコールバックの処理 {#handling-callbacks-in-your-endpoint}

コールバックがGitLabからのものであることを確認してから、それに対してアクションを実行してください。コールバックには他のすべてのWebhookイベントと同じヘッダーが含まれるため、Webhookに署名トークンを設定し、[署名を検証](../../project/integrations/webhooks.md#verify-the-signature)してください。

GitLabは同じイベントを複数回配信する可能性があるため、エンドポイントを冪等にしてください。エンドポイントが成功またはリダイレクト応答を返さない場合、GitLabはバックオフ付きで最大5回配信を再試行します。再試行では元のペイロードの`event_id`が繰り返されるため、処理済みの`event_id`値を保存し、すでに確認したイベントは無視してください。再試行が尽きると、GitLabはそのイベントの配信を停止します。

繰り返される配信失敗はWebhookの失敗制限にカウントされ、GitLabは[Webhookを自動的に無効](../../project/integrations/webhooks.md#auto-disabled-webhooks)にすることができます。Webhookが[一時的に無効](../../project/integrations/webhooks.md#temporarily-disabled-webhooks)になっている場合、GitLabはそのWebhookのフローイベントを保持し、無効期間が終了した後に配信します。GitLabはイベントを最大3回保持します。Webhookがまだ無効になっている場合、GitLabはイベントを配信しません。GitLabは、[完全に無効](../../project/integrations/webhooks.md#permanently-disabled-webhooks)になっているWebhookにはフローイベントを送信しません。フローイベントを再度受信するには、[Webhookを再度有効](../../project/integrations/webhooks.md#re-enable-disabled-webhooks)にしてください。

配信試行ごとに、GitLabはWebhookの[コールバックがまだ有効になっている](#turn-on-callbacks-for-a-webhook)ことを確認します。フローの実行中にコールバックをオフにすると、GitLabはキューに入っているイベントや保留中の再試行を含め、そのフローのイベントの送信を停止します。

GitLabが何を送信し、エンドポイントが何を返したかを確認するには、[Webhookリクエスト履歴](../../project/integrations/webhooks.md#view-webhook-request-history)を表示します。**最近のイベント**セクションには、過去2日間にWebhookに対して行われたすべてのリクエストが表示されます。このセクションには配信試行のみが表示されるため、Webhookが無効になっている間にGitLabが保留したイベントや配信しなかったイベントは含まれません。

## 関連トピック {#related-topics}

- [GitLab Duoフローイベント](../../project/integrations/webhook_events.md#gitlab-duo-flow-events)
- [Flows API](../../../api/duo_agent_platform_flows.md)
- [Webhook](../../project/integrations/webhooks.md)
