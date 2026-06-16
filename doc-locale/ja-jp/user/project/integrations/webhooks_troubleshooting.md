---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: イベントの送信に使用されるカスタムHTTPコールバック
title: Webhookのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabのWebhookに関する一般的な問題をトラブルシューティングして解決します。

## Webhookをデバッグする {#debug-webhooks}

GitLab Webhookをデバッグし、ペイロードをキャプチャするには、次の方法を使用します:

- [Public Webhook inspection tools](#use-public-webhook-inspection-tools)
- [Webhook request and response details](webhooks.md#inspect-request-and-response-details)
- [GitLab Development Kit (GDK)](#use-the-gitlab-development-kit-gdk)
- [Private Webhookレシーバー](#create-a-private-webhook-receiver)

WebhookイベントとJSONペイロードの詳細については、[webhook events](webhook_events.md)を参照してください。

### 公開のWebhook検査ツールを使用する {#use-public-webhook-inspection-tools}

公開ツールを使用してWebhookペイロードを検査およびテストします。これらのツールは、HTTPリクエストのキャッチオールエンドポイントを提供し、`200 OK`ステータスコードで応答します。

> [!warning]
> 公開ツールを使用する際は、機密データが外部サービスに送信される可能性があるため、注意してください。テストトークンを使用し、誤って第三者に送信されたシークレットをローテーションしてください。プライバシーを強化するために、[private Webhookレシーバーを作成します](#create-a-private-webhook-receiver)。

公開のWebhook検査ツールには、次のものが含まれます:

<!-- vale gitlab_base.Spelling = NO -->
- [Beeceptor](https://beeceptor.com): 一時的なHTTPSエンドポイントを作成し、受信ペイロードを検査します。
<!-- vale gitlab_base.Spelling = YES -->
- [Webhook.site](https://webhook.site): 受信ペイロードをレビューします。
- [Webhook Tester](https://webhook-test.com): 受信ペイロードを検査およびデバッグします。

### GitLab Development Kit (GDK)を使用する {#use-the-gitlab-development-kit-gdk}

より安全な開発環境のために、GitLab Webhookをローカルで操作するには、[GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit)を使用します。GDKを使用して、ローカルのGitLabインスタンスからマシンのWebhookレシーバーにWebhookを送信します。

このアプローチを使用するには、GDKをインストールして設定します。

### プライベートWebhookレシーバーを作成する {#create-a-private-webhook-receiver}

[公開Webhookレシーバー](#use-public-webhook-inspection-tools)にWebhookペイロードを送信できない場合は、独自のプライベートWebhookレシーバーを作成します。

前提条件: 

- システムにRubyがインストールされています。

プライベートWebhookレシーバーを作成するには:

1. このスクリプトを`print_http_body.rb`として保存します:

   ```ruby
   require 'webrick'

   server = WEBrick::HTTPServer.new(:Port => ARGV.first)
   server.mount_proc '/' do |req, res|
     puts req.body
   end

   trap 'INT' do
     server.shutdown
   end
   server.start
   ```

1. 未使用のポート (例: `8000`) を選択し、スクリプトを開始します:

   ```shell
   ruby print_http_body.rb 8000
   ```

1. GitLabで、[Webhook](webhooks.md#configure-webhooks)をレシーバーのURL (例: `http://receiver.example.com:8000/`) で設定します。
1. **Test**を選択します。次のような出力が表示されます:

   ```plaintext
   {"before":"077a85dd266e6f3573ef7e9ef8ce3343ad659c4e","after":"95cd4a99e93bc4bbabacfa2cd10e6725b1403c60",<SNIP>}
   example.com - - [14/May/2014:07:45:26 EDT] "POST / HTTP/1.1" 200 0
   - -> /
   ```

> [!note]
> このレシーバーを追加するには、[ローカルネットワーク](../../../security/webhooks.md)へのリクエストを許可する必要がある場合があります。

## SSL証明書検証エラーを解決する {#resolve-ssl-certificate-verification-errors}

SSL検証が有効になっている場合、GitLabはWebhookエンドポイントのSSL証明書の検証に失敗し、次のエラーが発生する可能性があります:

```plaintext
unable to get local issuer certificate
```

このエラーは通常、ルート証明書が[CAcert.org](http://www.cacert.org/)によって決定された信頼できる認証局によって発行されていない場合に発生します。

この問題を解決するには、次の手順に従います:

1. 特定のエラーを特定するには、[SSL Checker](https://www.sslshopper.com/ssl-checker.html)を使用します。
1. 検証失敗の一般的な原因である、中間証明書の欠落を確認します。

## Webhookがトリガーされない {#webhook-not-triggered}

{{< history >}}

- Silent ModeでWebhookがトリガーされない件は、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393639)されました。

{{< /history >}}

Webhookがトリガーされない場合は、以下を確認します:

- そのWebhookが[自動的に無効化](webhooks.md#auto-disabled-webhooks)されていない。
- GitLabインスタンスが[Silent Mode](../../../administration/silent_mode/_index.md)ではない。
- **Push event activities limit**と**Push event hooks limit**設定が、[**管理者**エリア](../../../administration/settings/push_event_activities_limit.md)で`0`より大きい値に設定されている。

## エラー: `Webhook rate limit exceeded` {#error-webhook-rate-limit-exceeded}

Webhookはレート制限のために失敗する可能性があります。GitLab.comは、トップレベルネームスペースごとに、毎分のWebhook呼び出しの総数を制限します。詳細については、[レート制限](../../gitlab_com/_index.md#rate-limits)を参照してください。

レート制限が問題であるかどうかを確認するには:

1. メッセージ`Webhook rate limit exceeded`について、GitLabログを確認してください。
1. Webhookをトリガーするイベントの数を減らすか、GitLabサポートに連絡して、レート制限の要件について話し合ってください。

## 引用符なしのプレースホルダーを持つカスタムWebhookテンプレートは保存できません {#custom-webhook-template-with-unquoted-placeholders-cannot-be-saved}

GitLab 18.8から18.10では、引用符なしのペイロードフィールドを持つ[カスタムWebhookテンプレート](webhooks.md#custom-webhook-template)を保存できません。この問題はGitLab 18.11で解決されました。回避策として、フィールドを引用符で囲むか、GitLab 18.11以降にアップグレードしてください。たとえば、`{"value": {{id}}}`は`{"value": "{{id}}"}`になります。

引用符で囲まれたフィールドは、数値ではなく文字列値を生成します。これがWebhookと互換性がなく、変更を加える必要がある場合は、アップグレードをお勧めします。
