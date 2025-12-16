---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Telegram
description: "Telegramインテグレーションを設定して、GitLabからの通知をTelegramのチャットまたはチャンネルで受信するようにします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122879)されました。

{{< /history >}}

GitLabを構成して、通知をTelegramのチャットまたはチャンネルに送信できます。Telegramインテグレーションをセットアップするには、次の手順を実行する必要があります:

1. [Telegramボットを作成する](#create-a-telegram-bot)。
1. [Telegramボットを設定する](#configure-the-telegram-bot)。
1. [GitLabでTelegramインテグレーションをセットアップする](#set-up-the-telegram-integration-in-gitlab)。

## Telegramボットを作成する {#create-a-telegram-bot}

Telegramでボットを作成するには:

1. `@BotFather`との新しいチャットを開始します。
1. Telegramのドキュメントの説明に従って、[新しいボットを作成](https://core.telegram.org/bots/features#creating-a-new-bot)します。

ボットを作成すると、`BotFather`からAPIトークンが提供されます。このトークンは、Telegramでボットを認証するために必要なため、安全に保管してください。

## Telegramボットを設定する {#configure-the-telegram-bot}

Telegramでボットを設定するには:

1. ボットを管理者として、新規または既存のチャンネルに追加します。
1. イベントを受信するために、ボットに`Post Messages`権限を割り当てます。
1. チャンネルの識別子を作成します。
   - パブリックチャンネルの場合は、パブリックリンクを入力し、チャンネル識別子（例: `https:/t.me/MY_IDENTIFIER`）をコピーします。
   - プライベートチャンネルの場合は、APIトークンで[`getUpdates`](https://telegram-bot-sdk.readme.io/reference/getupdates)メソッドを使用し、チャンネル識別子（例: `-2241293890657`）をコピーします。

## GitLabでTelegramインテグレーションをセットアップする {#set-up-the-telegram-integration-in-gitlab}

{{< history >}}

- **メッセージスレッドID**は、GitLab 16.11で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/441097)。
- **ホスト名**は、GitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/461313)。

{{< /history >}}

ボットをTelegramチャンネルに招待した後、通知を送信するようにGitLabを構成できます:

1. インテグレーションを有効にするには、次のようにします:
   - **For your group or project**（グループまたはプロジェクトの場合）:
     1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
     1. **設定** > **インテグレーション**を選択します。
   - **For your instance**（インスタンス）の場合:
     1. 左側のサイドバーの下部で、**管理者**を選択します。
     1. **設定** > **インテグレーション**を選択します。
1. **Telegram**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. オプション。**ホスト名**に、[ローカルボットAPIサーバー](https://core.telegram.org/bots/api#using-a-local-bot-api-server)のホスト名を入力します。
1. **パイプライントークン**に、[Telegramボットからトークン値を貼り付け](#create-a-telegram-bot)ます。
1. **トリガー**セクションで、Telegramで受信するGitLabイベントのチェックボックスを選択します。
1. **通知設定**セクションで、次のことを行います:
   - **チャンネルの識別子**に、[Telegramチャンネル識別子を貼り付け](#configure-the-telegram-bot)ます。
   - オプション。**メッセージスレッドID**に、ターゲットメッセージスレッド（フォーラムスーパーグループのトピック）の固有識別子を貼り付けます。
   - オプション。**壊れたパイプラインのみ通知**チェックボックスをオンにして、失敗したパイプラインの通知のみを受信します。
   - オプション。**通知を送信するブランチ**ドロップダウンリストから、通知を受信するブランチを選択します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

Telegramチャンネルは、選択されたすべてのGitLabイベントを受信できるようになりました。
