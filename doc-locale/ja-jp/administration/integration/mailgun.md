---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: Mailgun
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabインスタンスのメール送信にMailgunを使用し、[Mailgun](https://www.mailgun.com/)インテグレーションがGitLabで有効化され構成されている場合、配信失敗を追跡するためのWebhookを受信できます。インテグレーションを設定するには、次のことをする必要があります:

1. [Mailgunドメインを設定](#configure-your-mailgun-domain)。
1. [Mailgunインテグレーションを有効にする](#enable-mailgun-integration)。

インテグレーションの完了後、Mailgunの`temporary_failure`と`permanent_failure`のWebhookがGitLabインスタンスに送信されます。

## Mailgunドメインを設定 {#configure-your-mailgun-domain}

{{< history >}}

- GitLab 15.0で`/-/members/mailgun/permanent_failures` URLは[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/359113)になりました。
- GitLab 15.0で一時的な失敗と永続的な失敗の両方に対応するようにURLを[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/359113)しました。

{{< /history >}}

GitLabでMailgunを有効にする前に、Webhookを受信するように独自のMailgunエンドポイントを設定します。

[Mailgun Webhookガイド](https://www.mailgun.com/blog/product/a-guide-to-using-mailguns-webhooks/)を使用:

1. **Event type**（イベントタイプ）が**Permanent Failure**（永続的な失敗）に設定されたWebhookを追加します。
1. インスタンスのURLを入力し、`/-/mailgun/webhooks`パスを含めます。

   例: 

   ```plaintext
   https://myinstance.gitlab.com/-/mailgun/webhooks
   ```

1. **Event type**（イベントタイプ）が**Temporary Failure**（一時的な失敗）に設定された別のWebhookを追加します。
1. インスタンスのURLを入力し、同じ`/-/mailgun/webhooks`パスを使用します。

## Mailgunインテグレーションを有効にする {#enable-mailgun-integration}

WebhookエンドポイントのMailgunドメインを設定したら、Mailgunインテグレーションを有効にする準備が完了です:

1. [管理者](../../user/permissions.md)ユーザーとしてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーで、**設定**>**一般**に移動し、**Mailgun**セクションを展開します。
1. **Enable Mailgun**（Mailgunを有効にする）チェックボックスを選択します。
1. [Mailgunドキュメント](https://documentation.mailgun.com/docs/mailgun/user-manual/get-started/)に記載され、MailgunアカウントのAPIセキュリティ（`https://app.mailgun.com/app/account/security/api_keys`）セクションに示されているように、Mailgun HTTP Webhook署名キーを入力します。
1. **変更を保存**を選択します。
