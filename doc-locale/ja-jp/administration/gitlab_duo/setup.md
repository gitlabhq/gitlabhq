---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duoが正しく設定され、動作していることを確認してください。
title: GitLab Self-ManagedインスタンスでのGitLab Duoの設定
gitlab_dedicated: no
---

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Duoが正しく設定され、GitLabに接続できることを確認するには、以下を実行します:

- 送信と受信の両方の接続が存在することを確認する必要があります。ネットワークファイアウォールはラグまたは遅延の原因となる可能性があります。
- [サイレントモード](../../administration/silent_mode/_index.md)をオンにしないでください。
- [アクティベーションコードを使用して、インスタンスをアクティブ化](../../administration/license.md#activate-gitlab-ee)する必要があります。[オフラインライセンス](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#what-is-an-offline-cloud-license)または従来のライセンスは使用できません。
- 最良の結果を得るには、GitLab 17.2バージョン以降を使用してください。以前のバージョンでも引き続き動作する可能性はありますが、エクスペリエンスが低下するおそれがあります。

試験的またはベータ版のGitLab Duo機能は、デフォルトでオフになっており、[オンにする必要があります](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)。

## GitLabインスタンスからの送信接続を許可する {#allow-outbound-connections-from-the-gitlab-instance}

 送信と受信の両方の設定を確認します:

- ファイアウォールとHTTP/Sプロキシサーバーは、`cloud.gitlab.com`および`customers.gitlab.com`への送信接続をポート`443`で許可する必要があります（`https://`）。これらのホストはCloudflareによって保護されています。すべてのIPアドレスへのトラフィックを許可するようにファイアウォールの設定を更新します（[Cloudflareが公開しているIP範囲のリスト](https://www.cloudflare.com/ips/)）。
- HTTP/Sプロキシを使用するには、`gitLab_workhorse`と`gitLab_rails`の両方に必要な[ウェブプロキシ環境変数](https://docs.gitlab.com/omnibus/settings/environment-variables.html)が設定されている必要があります。
- マルチノードのGitLabインストールでは、すべての**Rails**および**Sidekiq**（Sidekiq） ノードでHTTP/Sプロキシを設定します。
- GitLabアプリケーションノードは、[GitLab Duoワークフローサービス](https://duo-workflow-svc.runway.gitlab.net)に接続できる必要があります。

## クライアントからGitLabインスタンスへの受信接続を許可する {#allow-inbound-connections-from-clients-to-the-gitlab-instance}

- GitLabインスタンスは、ポート443で、Duoクライアント（[IDE](../../editor_extensions/_index.md)、コードエディター、およびGitLab Webフロントエンド）からの受信接続を許可する必要があります（`https://`と`wss://`）。
- `HTTP2`と`'upgrade'`ヘッダーの両方を許可する必要があります。これは、GitLab DuoがRESTとWebSocketsの両方を使用するためです。
- WebSocket（`wss://`）トラフィックから`wss://gitlab.example.com/-/cable`およびその他の`.com`ドメインへの制限を確認してください。`wss://`トラフィックに対するネットワークポリシーの制限により、一部のGitLab Duoチャットサービスで問題が発生する可能性があります。これらのサービスを許可するようにポリシーの更新を検討してください。
- Apacheなどのリバースプロキシを使用している場合、ログに**WebSocket connection to .... failures**のようなGitLab Duoチャット接続の問題が表示されることがあります。

この問題を解決するには、Apacheプロキシの設定を編集してみてください:

```apache
# Enable WebSocket reverse Proxy
# Needs proxy_wstunnel enabled
  RewriteCond %{HTTP:Upgrade} websocket [NC]
  RewriteCond %{HTTP:Connection} upgrade [NC]
  RewriteRule ^/?(.*) "ws://127.0.0.1:8181/$1" [P,L]
```

## GitLab Duoのヘルスチェックを実行する {#run-a-health-check-for-gitlab-duo}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997)されました。
- [ヘルスチェックレポートのダウンロードが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165032)されました（GitLab 17.5）。

{{< /history >}}

GitLab Duoを使用するための要件をインスタンスが満たしているかどうかを判断できます。ヘルスチェックが完了すると、合格または失敗の結果と問題のタイプが表示されます。ヘルスチェックがテストに失敗した場合、ユーザーはインスタンスでGitLab Duo機能を使用できない可能性があります。

これは[ベータ](../../policy/development_stages_support.md)版の機能です。

前提要件: 

- 管理者である必要があります。

ヘルスチェックを実行するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. 右上隅で、**ヘルスチェックを実行する**を選択します。
1. オプション。GitLab 17.5以降では、ヘルスチェックが完了した後、**レポートのダウンロード**を選択して、ヘルスチェック結果の詳細なレポートを保存できます。

次のテストが実行されます:

| Test | 説明 |
|-----------------|-------------|
| ネットワーク | インスタンスが`customers.gitlab.com`および`cloud.gitlab.com`に接続できるかどうかをテストします。<br><br>インスタンスがいずれかの宛先に接続できない場合は、ファイアウォールまたはプロキシサーバーの設定で[接続を許可](setup.md)していることを確認してください。 |
| 同期 | サブスクリプションをテストします:<br>\- アクティベーションコードでアクティブ化されており、`customers.gitlab.com`と同期できます。<br>\- 正しいアクセス認証情報を持っている。<br>\- 最近同期されている。そうでない場合、またはアクセス認証情報がないか期限切れになっている場合は、サブスクリプションデータを[手動で同期](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)できます。 |
| システム交換 | インスタンスでコード提案を使用できるかどうかをテストします。システム交換アセスメントが失敗した場合、ユーザーはGitLab Duo機能を使用できない可能性があります。 |

バージョン17.10以前のGitLabインスタンスで、ヘルスチェックに問題が発生した場合は、[トラブルシューティングページ](../../user/gitlab_duo/troubleshooting.md)を参照してください。

## その他のホスティングオプション {#other-hosting-options}

デフォルトでは、GitLab DuoはサポートされているAIベンダーの言語モデルを使用し、GitLabがホストするクラウドベースのAIゲートウェイを介してデータを送信します。

独自の言語モデルまたはAIゲートウェイをホストする場合は、以下を実行します:

- [GitLab Duo Self-Hostedインスタンスを使用してAIゲートウェイをホストし、サポートされているセルフホストモデルを使用](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)できます。このオプションを使用すると、データとセキュリティを完全に制御できます。
- [ハイブリッド設定](../../administration/gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration)を使用します。一部の機能では独自のAIゲートウェイとモデルをホストしますが、他の機能を設定して、GitLab AIゲートウェイとAIベンダーモデルを使用します。

## GitLab Duo Coreの可用性を示すサイドバーウィジェットを非表示にする {#hide-sidebar-widget-that-shows-gitlab-duo-core-availability}

左側のサイドバーの下部付近に、GitLab Duo Coreの可用性を示すウィジェットが表示されます。このウィジェットを非表示にするには、`duo_agent_platform_widget_self_managed`機能フラグを無効にします。

![GitLab Duo Coreの可用性を示すウィジェット](img/widget_v18_5.png)
