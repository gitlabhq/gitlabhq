---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pumble
description: "GitLabを設定して、Pumbleチャンネルに通知を送信します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93623)されました。

{{< /history >}}

GitLabを設定して、Pumbleチャンネルに通知を送信できます:

1. チャンネルのWebhookを作成します。
1. そのWebhookをGitLabに追加します。

## PumbleチャンネルのWebhookを作成する {#create-a-webhook-for-your-pumble-channel}

1. Pumbleドキュメントの[Pumbleの受信Webhook](https://pumble.com/help/integrations/add-pumble-apps/incoming-webhooks-for-pumble/)の手順に従ってください。
1. Webhook URLをコピーします。

## GitLabで設定を構成する {#configure-settings-in-gitlab}

PumbleチャンネルのWebhook URLを取得したら、GitLabを設定して通知を送信します:

1. グループまたはプロジェクトのインテグレーションを有効にするには:
   1. グループまたはプロジェクトで、左側のサイドバーで**設定** > **インテグレーション**を選択します。
1. インスタンスのインテグレーションを有効にするには:
   1. 左側のサイドバーの下部で、**管理者**を選択します。
   1. 左側のサイドバーで、**設定** > **インテグレーション**を選択します。
1. **Pumble**インテグレーションを選択します。
1. **有効**トグルが有効になっていることを確認します。
1. Pumbleで受信したいGitLabイベントに対応するチェックボックスを選択します。
1. Pumbleチャンネルの**Webhook** URLを貼り付けます。
1. 残りのオプションを設定します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

Pumbleチャンネルは、該当するすべてのGitLabイベントの受信を開始します。
