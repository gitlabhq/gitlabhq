---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mattermost通知
description: "Mattermost通知を設定して、MattermostチャンネルでGitLabからの通知を受信するようにします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Mattermost通知インテグレーションを使用して、GitLabイベント（`issue created`など）の通知をMattermostに送信します。[Mattermost](#configure-mattermost-to-receive-gitlab-notifications)と[GitLab](#configure-gitlab-to-send-notifications-to-mattermost)の両方を設定する必要があります。

[Mattermostスラッシュコマンド](mattermost_slash_commands.md)を使用して、Mattermost内でGitLabを制御することもできます。

## GitLabの通知を受信するようにMattermostを設定します {#configure-mattermost-to-receive-gitlab-notifications}

Mattermostインテグレーションを使用するには、Mattermostで受信Webhookインテグレーションを作成する必要があります:

1. Mattermostインスタンスにサインインします。
1. [着信Webhookを有効にする](https://docs.mattermost.com/configure/integrations-configuration-settings.html#enable-incoming-webhooks)。
1. [着信Webhookを追加](https://developers.mattermost.com/integrate/webhooks/incoming/#create-an-incoming-webhook)。
1. 表示名、説明、チャンネルを選択します。これらはGitLabでオーバーライドできます。
1. 保存して**WebhookのURL**をコピーします。これは後でGitLabで必要になるためです。

受信Webhookは、Mattermostインスタンスでブロックされている可能性があります。Mattermost管理者に、以下で有効にするように依頼してください:

- **Mattermost System Console**（Mattermostシステムコンソール） > **インテグレーション** > Mattermostバージョン5.12以降の**Integration Management**。
- **Mattermost System Console**（Mattermostシステムコンソール） > **インテグレーション** > Mattermostバージョン5.11以前の**Custom Integrations**（カスタムインテグレーション）。

表示名のオーバーライドはデフォルトで有効になっていません。Mattermost管理者に、同じセクションで有効にするように依頼する必要があります。

## Mattermostに通知を送信するようにGitLabを設定します {#configure-gitlab-to-send-notifications-to-mattermost}

{{< history >}}

- [変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106760): Mattermostチャンネルをイベントあたり10個に制限するために、GitLab 15.9で行われました。

{{< /history >}}

Mattermostインスタンスに受信Webhookがセットアップされたら、通知を送信するようにGitLabをセットアップできます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Mattermost通知**を選択します。
1. 通知を生成するGitLabイベントを選択します。選択したイベントごとに、通知を受信するMattermostチャンネルを入力します。ハッシュ記号（`#`）を追加する必要はありません。
1. インテグレーションの設定に入力します:

   - **Webhook**: Mattermostの受信WebhookのURL。`http://mattermost.example/hooks/5xo…`に類似しています。
   - **ユーザー名**: オプション。Mattermostに送信されるメッセージに表示されるユーザー名。ボットのユーザー名を変更するには、値を入力します。
   - **壊れたパイプラインのみ通知**: **パイプライン**イベントを有効にして、失敗したパイプラインに関する通知のみが必要な場合。
   - **通知を送信するブランチ**: 通知を送信するブランチ。
   - **Labels to be notified**（通知されるラベル）: オプション。通知をトリガーするためにイシューまたはマージリクエストに必要なラベル。すべてのイシューとマージリクエストの通知をトリガーするには、空白のままにします。
   - **Labels to be notified behavior**（通知されるラベルの動作）: **Labels to be notified**（通知されるラベル）フィルターを使用すると、イシューまたはマージリクエストにフィルターで指定されたラベルのいずれかが含まれている場合に、メッセージが送信されます。イシューまたはマージリクエストにフィルターで定義されたすべてのラベルが含まれている場合にのみメッセージをトリガーするように選択することもできます。
