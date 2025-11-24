---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Discord通知
description: "Discordの通知インテグレーションを設定して、DiscordチャンネルでGitLabから通知を受信するようにします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Discord通知インテグレーションは、Webhookが作成されたチャンネルに、GitLabからのイベント通知を送信します。

GitLabイベント通知をDiscordチャンネルに送信するには、[DiscordでWebhookを作成](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)し、GitLabで設定します。

## Webhookの作成 {#create-webhook}

1. GitLabイベント通知を受信するDiscordチャンネルを開きます。
1. チャンネルメニューから、**Edit channel**（チャンネルを編集）を選択します。
1. **インテグレーション**を選択します。
1. 既存のWebhookがない場合は、**Create Webhook**（Webhookを作成）を選択します。それ以外の場合は、**View Webhooks**（Webhookを表示）、**New Webhook**（新しいWebhook）の順に選択します。
1. メッセージを投稿するボットの名前を入力します。
1. オプション。アバターを編集します。
1. **WEBHOOK URL**フィールドからURLをコピーします。
1. **保存**を選択します。

## GitLabで作成されたWebhookを設定する {#configure-created-webhook-in-gitlab}

{{< history >}}

- イベントWebhookのオーバーライドは、GitLab 16.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125621)。
- Webhook URL検証は、GitLab 18.0で導入されました。

{{< /history >}}

前提要件: 

- Discord URL（`https://discord.com/api/webhooks/webhook-snowflake/webhook-token`）を使用する必要があります。

Discordチャンネルで作成されたWebhook URLを使用して、GitLabでDiscord通知インテグレーションを設定できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Discord通知**を選択します。
1. **有効**トグルが有効になっていることを確認します。
1. [以前に作成した](#create-webhook) Webhook URLを、**Webhook**フィールドに貼り付けます。
1. Discordに通知を送信するGitLabイベントに対応するチェックボックスを選択します。
1. オプションで、選択した各チェックボックスについて、[設定](#create-webhook)した新しいDiscord Webhook URLを入力して、**Webhook**フィールドのデフォルトのURLをオーバーライドします。
1. 残りのオプションを設定し、**変更を保存**ボタンを選択します。

Webhookを作成したDiscordチャンネルは、設定されたGitLabイベントの通知を受信するようになります。
