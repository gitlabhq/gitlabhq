---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: イベントの送信に使用されるカスタムHTTPコールバック
title: Webhookのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Webhookに関する一般的なイシューのトラブルシューティングと解決を行います。

## デバッグWebhook {#debug-webhooks}

次の方法で、GitLab Webhookをデバッグし、ペイロードをキャプチャします:

- [パブリックWebhook検査ツール](#use-public-webhook-inspection-tools)
- [Webhook](webhooks.md#inspect-request-and-response-details)リクエストと応答の詳細を調べる
- [GitLab Development Kit（GDK）](#use-the-gitlab-development-kit-gdk)
- [プライベートWebhookレシーバー](#create-a-private-webhook-receiver)

WebhookイベントとJSONペイロードについては、[Webhookイベント](webhook_events.md)を参照してください。

### パブリックWebhook検査ツールを使用する {#use-public-webhook-inspection-tools}

パブリックツールを使用して、Webhookのペイロードを検査およびテストします。これらのツールは、HTTPリクエストに対するキャッチオールエンドポイントを提供し、`200 OK`ステータスコードで応答します。

{{< alert type="warning" >}}

パブリックツールを使用する際は、機密データを外部サービスに送信する可能性があるため、注意してください。テストトークンを使用し、サードパーティに誤って送信されたシークレットをローテーションします。プライバシーを強化するには、[プライベートWebhookレシーバーを作成](#create-a-private-webhook-receiver)します。

{{< /alert >}}

パブリックWebhook検査ツールには、次のものがあります:

<!-- vale gitlab_base.Spelling = NO -->
- [Beeceptor](https://beeceptor.com): 一時的なHTTPSエンドポイントを作成し、受信ペイロードを検査します。
<!-- vale gitlab_base.Spelling = YES -->
- [Webhook.site](https://webhook.site): 受信ペイロードをレビューします。
- [Webhook Tester](https://webhook-test.com): 受信ペイロードを検査およびデバッグします。

### GitLab Development Kit（GDK）を使用する {#use-the-gitlab-development-kit-gdk}

より安全な開発環境を実現するには、[GitLab Development Kit（GDK）](https://gitlab.com/gitlab-org/gitlab-development-kit)を使用して、ローカルでGitLab Webhookを操作します。GDKを使用して、ローカルのGitLabインスタンスからマシン上のWebhookレシーバーにWebhookを送信します。

このアプローチを使用するには、GDKをインストールして構成します。

### プライベートWebhookレシーバーを作成する {#create-a-private-webhook-receiver}

[パブリックレシーバー](#use-public-webhook-inspection-tools)にWebhookのペイロードを送信できない場合は、独自のプライベートWebhookレシーバーを作成します。

前提要件: 

- Rubyがシステムにインストールされている。

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

1. 未使用のポート（例: `8000`）を選択して、スクリプトを開始します:

   ```shell
   ruby print_http_body.rb 8000
   ```

1. GitLabで、レシーバーのURL（例: `http://receiver.example.com:8000/`）を使用して[Webhookを構成](webhooks.md#configure-webhooks)します。
1. **テスト**を選択します。次のような出力が表示されます:

   ```plaintext
   {"before":"077a85dd266e6f3573ef7e9ef8ce3343ad659c4e","after":"95cd4a99e93bc4bbabacfa2cd10e6725b1403c60",<SNIP>}
   example.com - - [14/May/2014:07:45:26 EDT] "POST / HTTP/1.1" 200 0
   - -> /
   ```

{{< alert type="note" >}}

このレシーバーを追加するには、[ローカルネットワークへのリクエストを許可する](../../../security/webhooks.md)必要がある場合があります。

{{< /alert >}}

## SSL証明書の検証エラーを解決する {#resolve-ssl-certificate-verification-errors}

SSL検証が有効になっている場合、GitLabは次のエラーでWebhookエンドポイントのSSL証明書の検証に失敗する可能性があります:

```plaintext
unable to get local issuer certificate
```

このエラーは通常、ルート証明書が[認証局](http://www.cacert.org/)によって発行されていない場合に発生します。

この問題を解決するには、以下を実行します:

1. [SSLチェッカー](https://www.sslshopper.com/ssl-checker.html)を使用して、特定のエラーを特定します。
1. 検証失敗の一般的な原因である、中間証明書がないか確認してください。

## Webhookがトリガーされない {#webhook-not-triggered}

{{< history >}}

- サイレントモードでトリガーされないWebhookは、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393639)されました。

{{< /history >}}

Webhookがトリガーされない場合は、以下を確認してください:

- Webhookが[自動的に無効](webhooks.md#auto-disabled-webhooks)になっていないこと。
- GitLabインスタンスが[サイレントモード](../../../administration/silent_mode/_index.md)になっていないこと。
- **Push event activities limit**（プッシュイベントアクティビティー制限）および**Push event hooks limit**（プッシュイベントフック制限）の設定が[**管理者**エリア](../../../administration/settings/push_event_activities_limit.md)で`0`より大きい値に設定されていること。
