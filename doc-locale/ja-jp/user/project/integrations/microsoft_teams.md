---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Microsoft Teams通知
description: "Microsoft Teamsインテグレーションを設定して、Microsoft TeamsのGitLabから通知を受信するように設定します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Microsoft Teamsの通知をGitLabと連携させて、Microsoft TeamsでGitLabプロジェクトに関する通知を表示できます。サービスを連携させるには、次の手順が必要です:

1. Webhookが変更をリッスンできるように、[Microsoft Teamsを設定](#configure-microsoft-teams)します。
1. Microsoft TeamsのWebhookに通知をプッシュするように、[GitLabプロジェクトを設定](#configure-your-gitlab-project)します。

## Microsoft Teamsを設定する {#configure-microsoft-teams}

{{< alert type="warning" >}}

Microsoftコネクタを使用した新しいMicrosoft Teamsのインテグレーションは作成できなくなりました。既存のインテグレーションは、2025年12月までにワークフローアプリに移行する必要があります。Microsoftは、Microsoftコネクタを使用したMicrosoft Teamsのインテグレーションの廃止を[発表](https://devblogs.microsoft.com/microsoft365dev/retirement-of-office-365-connectors-within-microsoft-teams/)しました。

{{< /alert >}}

GitLabからの通知をリッスンするようにMicrosoft Teamsを設定するには、次の手順に従います:

1. Microsoft Teamsで、ワークフローテンプレート「Post to a channel when a webhook request is received」（Webhook要求が受信されたときにチャネルに投稿する）を見つけて選択します。

   ![Microsoft TeamsでのワークフローWebhookの選択](img/microsoft_teams_select_webhook_workflow_v17_4.png)

1. Webhookの名前を入力します。この名前は、Webhook経由で受信するすべてのメッセージの横に表示されます。**次へ**を選択します。
1. インテグレーションを追加するチームとチャンネルを選択し、**Add workflow**（ワークフローを追加）を選択します。
1. GitLabの設定に必要なため、WebhookのURLをコピーします。

## GitLabプロジェクトを設定する {#configure-your-gitlab-project}

通知を受信するようにMicrosoft Teamsを設定したら、通知を送信するようにGitLabを設定する必要があります:

1. 管理者としてGitLabにサインインします。
1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Microsoft Teams notifications**（Microsoft Teams通知）を選択します。
1. インテグレーションを有効にするには、**有効**を選択します。
1. **トリガー**セクションで、各イベントの横にあるチェックボックスをオンにして有効にします:
   - プッシュ
   - イシュー
   - 非公開のイシュー
   - マージリクエスト
   - メモ
   - 非公開メモ
   - タグのプッシュ
   - パイプライン
   - Wikiページ
1. **Webhook**で、[Microsoft Teamsを設定した](#configure-microsoft-teams)ときにコピーしたURLを貼り付けます。
1. オプション。パイプラインのトリガーを有効にする場合は、**壊れたパイプラインのみ通知**チェックボックスをオンにして、パイプラインが失敗した場合にのみ通知をプッシュします。
1. 通知を送信するブランチを選択します。
1. **変更を保存**を選択します。

## 関連トピック {#related-topics}

- [Microsoft Teamsでの受信Webhookの設定](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using#setting-up-a-custom-incoming-webhook)
