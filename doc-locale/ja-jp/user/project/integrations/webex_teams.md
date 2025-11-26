---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Webex Teams
description: "webhookを使用して、GitLabからWebex Teamsスペースにイベント通知を送信します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabを構成して、Webex Teamsスペースに通知を送信できます:

1. スペースのWebhookを作成します。
1. WebhookをGitLabに追加します。

## スペースのWebhookを作成します {#create-a-webhook-for-the-space}

1. [Incoming Webhooks app page](https://apphub.webex.com/applications/incoming-webhooks-cisco-systems-38054-23307-75252)に移動します。
1. 必要に応じて、**接続**を選択し、Webex Teamsにサインインします。
1. Webhookの名前を入力し、通知を受信するスペースを選択します。
1. **ADD**を選択します。
1. **WebhookのURL**をコピーします。

## GitLabで設定を構成する {#configure-settings-in-gitlab}

Webex TeamsスペースのWebhook URLを取得したら、GitLabを構成して通知を送信できます:

1. インテグレーションを有効にするには:
   - プロジェクトまたはグループレベル:
     1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
     1. **設定** > **インテグレーション**を選択します。
   - インスタンスレベル:
     1. 左側のサイドバーの下部で、**管理者**を選択します。
     1. **設定** > **インテグレーション**を選択します。
1. **Webex Teams**インテグレーションを選択します。
1. **有効**トグルが有効になっていることを確認してください。
1. Webex Teamsで受信するGitLabイベントに対応するチェックボックスを選択します。
1. Webex Teamsスペースの**Webhook** URLを貼り付けます。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

Webex Teamsスペースは、該当するすべてのGitLabイベントを受信し始めます。
