---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duoが、GitLab Self-Managedで正しく設定、動作することを確認します。
title: GitLab Self-ManagedでのGitLab Duoの設定
gitlab_dedicated: no
---

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

## 前提条件 {#prerequisites}

- 送信と受信の両方の接続を許可します。ネットワークファイアウォールによって遅延が発生する可能性があります。
- [サイレントモードをオフにする](../../silent_mode/_index.md#turn-off-silent-mode)。
- [アクティベーションコードでGitLabインスタンスをアクティベートします](../../license.md#activate-gitlab-ee)。レガシーライセンスは使用できません。[GitLab Duo Self-Hosted](../../gitlab_duo_self_hosted/_index.md)の場合を除き、オフラインライセンスも使用できません。
- 複合アイデンティティをオンにします。

最良の結果を得るには、GitLab 17.2以降を使用してください。以前のバージョンでも動作する可能性がありますが、パフォーマンスが低下する可能性があります。

## 複合アイデンティティをオンにする {#turn-on-composite-identity}

[複合アイデンティティ](../../../user/duo_agent_platform/composite_identity.md)をオンにして、`@duo-developer`サービスアカウントがユーザーの代わりにアクションを実行できるようにする必要があります。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **GitLab Duo Agent Platformの複合アイデンティティ**で、**Turn on composite identity**を選択します。

## GitLabインスタンスからの送信接続を許可する {#allow-outbound-connections-from-the-gitlab-instance}

 送信と受信の両方の設定を確認します:

- ファイアウォールとHTTP/Sプロキシサーバーは、`https://`を使用してポート`443`で`cloud.gitlab.com`と`customers.gitlab.com`への送信接続を許可する必要があります。これらのホストはCloudflareによって保護されています。ファイアウォールの設定を更新して、[Cloudflareが公開しているIP範囲のリスト](https://www.cloudflare.com/ips/)内のすべてのIPアドレスへのトラフィックを許可します。
- HTTP/Sプロキシを使用するには、`gitLab_workhorse`と`gitLab_rails`の両方に必要な[Webプロキシ環境変数](https://docs.gitlab.com/omnibus/settings/environment-variables.html)を設定する必要があります。
- マルチノードのGitLabインストールでは、すべての**Rails**および**Sidekiq**ノードでHTTP/Sプロキシを設定します。
- GitLabアプリケーションノードは、HTTP/2で`https://duo-workflow-svc.runway.gitlab.net`にあるGitLab Duoワークフローに接続する必要があります。アプリケーションとサービスはgRPCで通信します。
- GitLab DuoエージェントPlatformの機能では、ファイアウォールとHTTP/Sプロキシサーバーが、`https://`を使用して`443`の`duo-workflow-svc.runway.gitlab.net`への送信接続を許可し、HTTP/2トラフィックをサポートする必要があります。

## クライアントからGitLabインスタンスへの受信接続を許可する {#allow-inbound-connections-from-clients-to-the-gitlab-instance}

GitLabインスタンスは、IDEクライアントからの受信接続を許可する必要があります。

1. ヘッダーでWebSocketプロトコルのアップグレードリクエストを許可します:
   - `Connection: upgrade`
   - `Upgrade: websocket`
   - `HTTP/2`プロトコルのサポート
   - 標準のWebSocketセキュリティヘッダー: `Sec-WebSocket-*`
1. `wss://`（WebSocket Secure）プロトコルのサポートを有効にします。
1. 許可する特定のエンドポイントを追加します:
   - プライマリエンドポイント: `wss://<customer-instance>/-/cable`
   - `HTTP/2`プロトコルが`HTTP/1.1`にダウングレードされないようにします。
   - ポート: `443`（HTTPS/WSS）

問題が発生した場合:

- `wss://gitlab.example.com/-/cable`やその他の`.com`ドメインへのWebSocketトラフィックの制限を確認します。
- Apacheのようなリバースプロキシを使用している場合は、ログにGitLab Duo Chat接続の問題（**WebSocket connection to .... failures**など）が表示されることがあります。

この問題を解決するには、プロキシ設定を編集します:

```apache
# Enable WebSocket reverse Proxy
# Needs proxy_wstunnel enabled
  RewriteCond %{HTTP:Upgrade} websocket [NC]
  RewriteCond %{HTTP:Connection} upgrade [NC]
  RewriteRule ^/?(.*) "ws://127.0.0.1:8181/$1" [P,L]
```

## Runnerからの接続を許可する {#allow-connections-from-the-runner}

フローのようなRunnerを使用するGitLab DuoエージェントPlatformの機能では、RunnerがGitLabインスタンスに接続できる必要があります。

（[クライアントからGitLabインスタンスへの受信接続](#allow-inbound-connections-from-clients-to-the-gitlab-instance)）と同じ接続を、RunnerからGitLabインスタンスへの送信接続として許可する必要があります。

## GitLab Duoのヘルスチェックを実行する {#run-a-health-check-for-gitlab-duo}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997)されました。
- GitLab 17.5で[ヘルスチェックレポートのダウンロードが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165032)されました。

{{< /history >}}

インスタンスがGitLab Duoを使用するための要件を満たしているかどうかを判断できます。ヘルスチェックが完了すると、合格または失敗の結果と問題の種類が表示されます。ヘルスチェックがテストに失敗した場合、ユーザーはインスタンスでGitLab Duo機能を使用できない可能性があります。

これは[ベータ](../../../policy/development_stages_support.md)版の機能です。

前提条件: 

- 管理者である必要があります。

ヘルスチェックを実行するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. 右上隅で**ヘルスチェックを実行する**を選択します。
1. オプション。GitLab 17.5以降では、ヘルスチェックが完了した後、**レポートのダウンロード**を選択して、ヘルスチェック結果の詳細レポートを保存できます。

次のテストが実行されます:

| テスト | 説明 |
|-----------------|-------------|
| AIゲートウェイ | GitLab Duo Self-Hostedモデルのみ。AIゲートウェイのURLが環境変数として設定されているかどうかをテストします。この接続は、AIゲートウェイを使用するセルフホストモデルのデプロイに必要です。 |
| ネットワーク | インスタンスが`customers.gitlab.com`および`cloud.gitlab.com`に接続できるかどうかをテストします。<br><br>インスタンスがいずれかの宛先に接続できない場合は、ファイアウォールまたはプロキシサーバーの設定が[接続を許可](gitlab_self_managed.md)していることを確認してください。 |
| 同期 | サブスクリプションが次の条件を満たしているかどうかををテストします:<br>\- アクティベーションコードでアクティブ化されており、`customers.gitlab.com`と同期できる。<br>\- 正しいアクセス認証情報を持っている。<br>\- 最近同期されている。そうでない場合、またはアクセス認証情報がないか期限切れになっている場合は、サブスクリプションデータを[手動で同期](../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)できます。 |
| コード提案 | GitLab Duo Self-Hostedモデルのみ。コード提案が利用可能かどうかをテストします:<br>\- お客様のライセンスには、コード提案へのアクセスが含まれています。<br>\- この機能を使用するために必要な権限が必要です。 |
| GitLab Duo Agent Platform | バックエンドサービスが稼働中でアクセス可能かどうかをテストします。このサービスは、Agent PlatformやGitLab Duo Chat（エージェント）のようなエージェント機能に必要です。 |
| システム連携 | インスタンスでコード提案を使用できるかどうかをテストします。システム連携アセスメントが失敗した場合、ユーザーはGitLab Duo機能を使用できない可能性があります。 |

バージョン17.10より前のGitLabインスタンスで、ヘルスチェックに問題が発生した場合は、[トラブルシューティングページ](../../../user/gitlab_duo/troubleshooting.md)を参照してください。

## その他のホスティングオプション {#other-hosting-options}

デフォルトでは、GitLab DuoはサポートされているAIベンダーの言語モデルを使用し、GitLabがホストするクラウドベースのAIゲートウェイを介してデータを送信します。

独自の言語モデルまたはAIゲートウェイをホストする場合:

- [GitLab Duo Self-Hostedを使用してAIゲートウェイをホストし、サポートされているセルフホストモデルを使用](../../gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)できます。このオプションを選択すると、データとセキュリティを完全に制御できます。
- [ハイブリッド構成](../../gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration)を使用します。一部の機能には独自のAIゲートウェイとモデルをホストしますが、他の機能にはGitLab AIゲートウェイとAIベンダーモデルを使用します。

## GitLab Duo Coreの可用性を示すサイドバーウィジェットを非表示にする（削除済み） {#hide-sidebar-widget-that-shows-gitlab-duo-core-availability-removed}

<!--- start_remove The following content will be removed on remove_date: '2026-02-11' -->

この機能はGitLab 18.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210564)されました。

<!--- end_remove -->
