---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Webhook操作のレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- Webhookテストのレート制限は、GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150066)され、[フラグ](../feature_flags/_index.md) `web_hook_test_api_endpoint_rate_limit`が付けられています。デフォルトでは有効になっています。
- Webhookイベント再送信のレート制限は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130)され、[フラグ](../feature_flags/_index.md) `web_hook_event_resend_api_endpoint_rate_limit`が付けられています。デフォルトでは有効になっています。
- カスタマイズ可能なレート制限は、GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/587887)されました。機能フラグ`web_hook_test_api_endpoint_rate_limit`および`web_hook_event_resend_api_endpoint_rate_limit`は削除されました。

{{< /history >}}

次のリクエストに対する1分あたりのレート制限を設定します:

- [Webhookをテストする](../../user/project/integrations/webhooks.md#test-a-webhook)。
- [Webhookイベントを再送信する](../../user/project/integrations/webhooks.md#inspect-request-and-response-details)。

| 制限 | デフォルト |
|-------|---------|
| Webhookテストリクエスト | 毎分5回 |
| Webhookイベント再送信リクエスト | 毎分5回 |

各レート制限は、特定のプロジェクトまたはグループに対し、ユーザーごとに適用され、UIとAPIの両方を対象とします。同じプロジェクトまたはグループ内のすべてのWebhookは、この制限を共有します。

これらの制限は、Webhookがトリガーできる頻度を制限する[Webhook配信レート制限](../instance_limits.md#webhook-rate-limit)とは別のものです。Webhook配信のレート制限の設定は、インスタンスの種類によって異なります:

- GitLab Self-Managedでは、管理者が[プラン制限API](../../api/plan_limits.md)で設定します。
- GitLab.comでは、配信制限は[プランに依存](../../user/gitlab_com/_index.md#webhooks)し、変更できません。

例えば、Webhookテストレート制限を5に設定し、1分間に6回Webhookをテストしようとすると、最後のリクエストはブロックされます。1分後に、再びWebhookをテストできます。

## レート制限を変更する {#change-the-rate-limit}

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **Webhookレート制限**を展開します。
1. 利用可能なレート制限の値を設定します。レート制限を無効にするには、`0`を入力します。
1. **変更を保存**を選択します。

レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。
