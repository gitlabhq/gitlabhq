---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabインスタンスにGitLab Duoを設定します。
title: GitLab Duoを設定する
---

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated for Government

{{< /details >}}

GitLab Duoは、ソフトウェア開発ライフサイクル全体を支援する、AIネイティブなアシスタントです。

GitLab Duoは、以下の構成で使用できます:

- クラウドベースのAIゲートウェイ（デフォルト）: GitLabがホストするAIゲートウェイと、ベンダーの言語モデルを使用します。
- セルフホストモデル: 独自のAIゲートウェイと言語モデルを使用し、データとセキュリティを完全に制御します。
- ハイブリッド構成: 一部の機能にはセルフホストモデル、その他の機能にはクラウドベースのモデルを使用します。

## 前提条件 {#prerequisites}

- サイレントモードが[オフ](../../silent_mode/_index.md#turn-off-silent-mode)になっている。
- [アクティベーションコードでインスタンスをアクティブ化](../../license.md#activate-gitlab-ee)している。
  - ライセンスキーは使用できません。
  - [GitLab Duo Self-Hosted](../../gitlab_duo_self_hosted/_index.md)を除き、オフラインライセンスではGitLab Duoを使用できません。
- HTTP/Sプロキシサーバーを使用している場合でも、インスタンスを実行するホストがDNSでパブリックホスト名を解決できる。

## GitLabインスタンスからGitLab Duoへの送信接続を許可する {#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo}

- GitLabアプリケーションノードは、HTTP/2を使用して`https://duo-workflow-svc.runway.gitlab.net`にあるGitLab Duo Workflowに接続する必要があります。アプリケーションとサービスはgRPCを使用して通信します。
- GitLab Duo Agent Platformの機能を使用するには、ファイアウォールとHTTP/Sプロキシサーバーにおいて、`https://`とHTTP/2トラフィックをサポートし、ポート`443`で`duo-workflow-svc.runway.gitlab.net`への送信接続を許可する必要があります。
- インスタンスがHTTP/Sプロキシサーバー経由で接続する場合でも、ホストがDNSを使用してパブリックホスト名を解決できる必要があります。ホスト名をプロキシサーバー経由でしか解決できない場合、GitLab Duoのヘルスチェック、GitLabクレジットダッシュボード、GitLab Duo Agent PlatformなどのGitLab Duo機能がタイムアウトしたり、失敗したりする可能性があります。詳細については、[イシュー602538](https://gitlab.com/gitlab-org/gitlab/-/issues/602538)を参照してください。
- AI機能は、長時間維持されるHTTP接続を介してレスポンスをストリーミングします。リクエストの最大継続時間やアイドルタイムアウトを適用するHTTP/Sプロキシサーバーまたはファイアウォールでは、エラーを表示せずに長いレスポンスが切断される可能性があります。プロキシには、経路上にある他のコンポーネントよりも長いタイムアウトを設定してください。

## クライアントからGitLabインスタンスへの受信接続を許可する {#allow-inbound-connections-from-clients-to-the-gitlab-instance}

GitLabインスタンスは、IDEクライアントからの受信接続を許可する必要があります。

1. 次のヘッダーを含むWebSocketプロトコルのアップグレードリクエストを許可します:
   - `Connection: upgrade`
   - `Upgrade: websocket`
   - `HTTP/2`プロトコルのサポート
   - 標準のWebSocketセキュリティヘッダー: `Sec-WebSocket-*`
1. `wss://`（WebSocket Secure）プロトコルのサポートを有効にします。
1. 許可する特定のエンドポイントを追加します:
   - プライマリエンドポイント: `wss://<customer-instance>/-/cable`
   - `HTTP/2`プロトコルが`HTTP/1.1`にダウングレードされないことを確認してください。
   - ポート: `443`（HTTPS/WSS）

問題が発生した場合:

- `wss://gitlab.example.com/-/cable`やその他の`.com`ドメインへのWebSocketトラフィックに制限がかかっていないか確認してください。
- Apacheなどのリバースプロキシを使用している場合、ログに**WebSocket connection to .... failures**のようなGitLab Duo Chat接続の問題が表示されることがあります。

この問題を解決するには、プロキシ設定を編集します:

```apache
# Enable WebSocket reverse Proxy
# Needs proxy_wstunnel enabled
  RewriteCond %{HTTP:Upgrade} websocket [NC]
  RewriteCond %{HTTP:Connection} upgrade [NC]
  RewriteRule ^/?(.*) "ws://127.0.0.1:8181/$1" [P,L]
```

## Runnerからの接続を許可する {#allow-connections-from-the-runner}

フローなど、Runnerを使用するGitLab Duo Agent Platformの機能では、RunnerがGitLabインスタンスに接続できる必要があります。

[クライアントからGitLabインスタンスへの受信接続](#allow-inbound-connections-from-clients-to-the-gitlab-instance)として許可されているものと同じ接続を、RunnerからGitLabインスタンスへの送信接続としても許可する必要があります。

さらに、Runnerは以下に接続できる必要があります:

| 宛先 | ポート | 目的 |
|-------------|------|---------|
| `registry.npmjs.org` | `443` | 実行時にDuo CLIパッケージをダウンロードする |
| `registry.gitlab.com` | `443` | デフォルトのDockerイメージをダウンロードする（[カスタムイメージ](../../../user/duo_agent_platform/flows/execution/images.md#change-the-default-docker-image)を使用する場合を除く） |

組織でパブリックnpmレジストリへのアクセスを許可できない場合は、必要な依存関係がすでにインストールされている[カスタムDockerイメージ](../../../user/duo_agent_platform/flows/execution/images.md#change-the-default-docker-image)を使用できます。

> [!note]
> RunnerからGitLab Duo Agent Platformサービスへの接続は、GitLabインスタンスを経由します。Runnerが`duo-workflow-svc.runway.gitlab.net`に直接接続することはありません。ポート`443`で`duo-workflow-svc.runway.gitlab.net`への接続を許可するファイアウォール要件は、RunnerではなくGitLabインスタンスに適用されます。Runnerのネットワーク設定では、GitLabインスタンスへの送信HTTPSトラフィックを許可する必要があります。

## GitLabと使用状況データを共有する {#share-usage-data-with-gitlab}

{{< history >}}

- GitLab 18.9.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/587976)されました。

{{< /history >}}

サービス品質の向上に役立つよう、GitLab Duo Agent Platform機能に関する使用状況データをGitLabと共有できます。

データ収集をオンにすると、GitLabはGitLab Duo機能の使用状況に関する情報を記録します。このデータは、サービス改善およびデバッグのみに使用され、AIモデルのトレーニングには使用されません。

収集されるデータの詳細については、[Agent Platformの使用状況データ](../../../user/gitlab_duo/data_usage.md#agent-platform-usage-data)を参照してください。

前提条件: 

- GitLab 18.9.1以降が必要です。

拡張ロギングをオンにするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **使用状況データを収集**チェックボックスを選択します。
1. **変更を保存**を選択します。

### セルフホストモデルでのデータの使用 {#data-usage-with-self-hosted-models}

セルフホストAIゲートウェイとセルフホストモデルを使用する場合、詳細なログは自身のインフラストラクチャに保存され、GitLabとは共有されません。GitLabとデータを共有するには、外部の可観測性サービスにトレースを送信するように、セルフホストAIゲートウェイを設定する必要があります。

[Service Ping](../../settings/usage_statistics.md#service-ping)を使用して、使用状況データをGitLabに送信できます。このデータは[テレメトリデータ](../../../user/gitlab_duo/data_usage.md#telemetry)とは異なります。

## GitLab Duoのヘルスチェックを実行する {#run-a-health-check-for-gitlab-duo}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997)されました。
- GitLab 17.5で[ヘルスチェックレポートのダウンロードが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165032)されました。
- GitLab 19.1で基本フローの準備状況チェックが[追加](https://gitlab.com/gitlab-org/gitlab/-/work_items/599536)されました。

{{< /history >}}

インスタンスがGitLab Duoを使用するための要件を満たしているかどうかを判断できます。ヘルスチェックが完了すると、合格または失敗の結果と問題の種類が表示されます。ヘルスチェックがテストに失敗した場合、ユーザーはインスタンスでGitLab Duo機能を使用できない可能性があります。

これは[ベータ](../../../policy/development_stages_support.md)版の機能です。

前提条件: 

- 管理者である必要があります。

ヘルスチェックを実行するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. 右上隅で、**ヘルスチェックを実行する**を選択します。
1. オプション。GitLab 17.5以降では、ヘルスチェックが完了した後、**レポートのダウンロード**を選択して、ヘルスチェック結果の詳細レポートを保存できます。

次のテストが実行されます:

| テスト                      | 説明 |
|---------------------------|-------------|
| AIゲートウェイ                | GitLab Duo Self-Hostedモデルのみ。AIゲートウェイのURLが環境変数として設定されているかどうかをテストします。この接続は、AIゲートウェイを使用するセルフホストモデルのデプロイに必要です。 |
| ネットワーク                   | インスタンスが`customers.gitlab.com`および`cloud.gitlab.com`に接続できるかどうかをテストします。<br><br>インスタンスがいずれかの宛先に接続できない場合は、ファイアウォールまたはプロキシサーバーの設定が[接続を許可](#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo)していることを確認してください。 |
| 同期           | サブスクリプションが次の条件を満たしているかどうかをテストします:<br>\- アクティベーションコードでアクティブ化されており、`customers.gitlab.com`と同期できる。<br>\- 正しいアクセス認証情報を持っている。<br>\- 最近同期されている。そうでない場合、またはアクセス認証情報がないか期限切れになっている場合は、サブスクリプションデータを[手動で同期](../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)できます。 |
| コード提案          | GitLab Duo Self-Hostedモデルのみ。コード提案が利用可能かどうかをテストします:<br>\- ライセンスにコード提案機能へのアクセスが含まれている。<br>\- この機能を使用するために必要な権限を持っている。 |
| GitLab Duo Agent Platform | バックエンドサービスが稼働中でアクセス可能かどうかをテストします。このサービスは、Agent PlatformやGitLab Duo Agentic Chatなど、エージェント型の機能に必要です。<br><br>GitLab Duo Self-Hostedでは、[GitLab Duo Agent Platform機能に使用するセルフホストモデルを選択](../../gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature)するまで、このテストは合格しません。<br><br>また、次の基本フローの前提条件も検証します:<br>\- インスタンスレベルのフロー実行設定が有効になっている。<br>\- インスタンスレベルの基本フロー設定が有効になっている。<br>- `gitlab--duo`タグが設定され、アクティブなインスタンスRunnerが1つ以上登録および接続されており、Docker互換のexecutorを使用している。|
| システム連携           | インスタンスでコード提案を使用できるかどうかをテストします。システム連携アセスメントが失敗した場合、ユーザーはGitLab Duo機能を使用できない可能性があります。 |
| 使用量課金           | インスタンスがカスタマーポータル、AIゲートウェイ、Duo Workflowサービスを含む使用量課金エンドポイントに接続できるかどうかをテストします。 |

バージョン17.10より前のGitLabインスタンスで、ヘルスチェックに問題が発生した場合は、[トラブルシューティングページ](../../../user/gitlab_duo/troubleshooting.md)を参照してください。

## その他のホスティングオプション {#other-hosting-options}

デフォルトでは、GitLab DuoはサポートされているAIベンダーの言語モデルを使用し、GitLabがホストするクラウドベースのAIゲートウェイを介してデータを送信します。

独自の言語モデルまたはAIゲートウェイをホストする場合:

- [GitLab Duo Self-Hostedを使用してAIゲートウェイをホストし、サポートされているセルフホストモデルを使用](../../gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)できます。このオプションを選択すると、データとセキュリティを完全に制御できます。
- [ハイブリッド構成](../../gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration)を使用します。一部の機能には独自のAIゲートウェイとモデルをホストしますが、他の機能にはGitLab AIゲートウェイとAIベンダーモデルを使用します。

## GitLab Dedicated for Government {#gitlab-dedicated-for-government}

GitLab Dedicated for Governmentでは、GitLab Duo Self-HostedをFedRAMP承認済みモデルと組み合わせて使用する必要があります。クラウドベースのAIゲートウェイとベンダーモデルは、GitLab Dedicated for Governmentでは使用できません。

詳細については、[GitLab Dedicated for GovernmentでGitLab Duoを設定する](gitlab_dedicated_for_government.md)を参照してください。

## 関連トピック {#related-topics}

- [GitLab Duoの機能の概要](../../../user/gitlab_duo/feature_summary.md)
- [GitLab Duoの可用性を制御する](../../../user/gitlab_duo/turn_on_off.md)
- [GitLab Duoのトラブルシューティング](../../../user/gitlab_duo/troubleshooting.md)
