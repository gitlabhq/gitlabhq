---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoのトラブルシューティング
---

GitLab Duoの使用中に、問題が発生することがあります。

[ヘルスチェックの実行](../../administration/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo)から開始して、お使いのインスタンスがGitLab Duoを使用するための要件を満たしているかどうかを判断してください。

GitLab Duoのトラブルシューティングの詳細については、以下を参照してください:

- [コード提案のトラブルシューティング](../project/repository/code_suggestions/troubleshooting.md)。
- [GitLab Duo Chat](../gitlab_duo_chat/troubleshooting.md)のトラブルシューティング。
- [GitLab Duo Self-Hostedのトラブルシューティング](../../administration/gitlab_duo_self_hosted/troubleshooting.md)。

ヘルスチェックで問題が解決しない場合は、次のトラブルシューティングの手順を確認してください。

## GitLab Duo機能がセルフマネージドで動作しない {#gitlab-duo-features-do-not-work-on-self-managed}

[GitLab Duoの機能がオンになっていることを確認する](turn_on_off.md)ことに加えて、次のこともできます:

1. 管理者として、GitLab Duoのヘルスチェックを実行します。

   {{< tabs >}}

   {{< tab title="17.5以降" >}}

   GitLab 17.5以降では、UIを使用してヘルスチェックを実行し、問題の特定とトラブルシューティングに役立つ詳細なレポートをダウンロードできます。

   {{< /tab >}}

   {{< tab title="17.4" >}}

   GitLab 17.4では、ヘルスチェックRakeタスクを実行して、問題の特定とトラブルシューティングに役立つ詳細なレポートを生成できます。

   ```shell
   sudo gitlab-rails 'cloud_connector:health_check(root,report.json)'
   ```

   {{< /tab >}}

   {{< tab title="17.3以前" >}}

   GitLab 17.3以前では、`health_check`スクリプトをダウンロードして実行し、問題の特定とトラブルシューティングに役立つ詳細なレポートを生成できます。

   1. ヘルスチェックスクリプトをダウンロードします:

      ```shell
      wget https://gitlab.com/gitlab-org/gitlab/-/snippets/3734617/raw/main/health_check.rb
      ```

   1. Railsランナーを使用してスクリプトを実行します:

      ```shell
      gitlab-rails runner [full_path/to/health_check.rb] --debug --username [username] --output-file [report.txt]
      ```

      ```shell
      Usage: gitlab-rails runner full_path/to/health_check.rb
             --debug                Enable debug mode
             --output-file FILE     Write a report to FILE
             --username USERNAME    Provide a username to test seat assignments
             --skip [CHECK]         Skip specific check (options: access_data, token, license, host, features, end_to_end)
      ```

   {{< /tab >}}

   {{< /tabs >}}

1. GitLabインスタンスが[必要なGitLab.comエンドポイント](setup.md)に到達できることを確認します。接続を確認するには、`curl`などのコマンドラインツールを使用できます。

   ```shell
   curl --verbose "https://cloud.gitlab.com"

   curl --verbose "https://customers.gitlab.com"
   ```

   GitLabインスタンスに対してHTTP/Sプロキシが構成されている場合は、`proxy`パラメータを`curl`コマンドに含めます。

   ```shell
   # https proxy for curl
   curl --verbose --proxy "http://USERNAME:PASSWORD@example.com:8080" "https://cloud.gitlab.com"
   curl --verbose --proxy "http://USERNAME:PASSWORD@example.com:8080" "https://customers.gitlab.com"
   ```

1. オプション。GitLabアプリケーションとパブリックインターネットの間に[プロキシサーバー](../../administration/gitlab_duo/setup.md#allow-outbound-connections-from-the-gitlab-instance)を使用している場合は、[DNSリバインディング保護を無効にします](../../security/webhooks.md#enforce-dns-rebinding-attack-protection)。

1. [サブスクリプションデータ](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)を手動で同期する。
   - GitLabインスタンスが[サブスクリプションデータをGitLabと同期している](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/)ことを確認します。

## エラー: `Webview didn't initialize in 10000ms`{#error-webview-didnt-initialize-in-10000ms}

VS Code Remote SSHまたはWSLセッションでGitLab Duoチャットを使用すると、このエラーが発生する可能性があります。拡張機能が`127.0.0.1`アドレスに誤って接続しようとする場合もあります。

この問題は、リモート環境でレイテンシーが発生し、GitLab VS Code Extension 6.8.0以降にハードコードされた10秒のタイムアウトを超える場合に発生します。

この問題を解決するには、以下を実行します:

1. VS Codeで、**コード** > **設定** > **設定**を選択します。
1. **Open Settings (JSON)**（設定を開く（JSON））を選択して、`settings.json`ファイルを編集します。または、<kbd>F1</kbd>キーを押して、**設定を開く（JSON）を入力します: 設定を開く（JSON）**を選択します。
1. この設定を追加します:

   ```json
   "gitlab.featureFlags.languageServerWebviews": false
   ```

1. 保存してVS Codeをリロードします。

## GitLab DedicatedでのGitLab Duoのトラブルシューティング {#troubleshooting-gitlab-duo-on-gitlab-dedicated}

PremiumおよびUltimateプランのお客様の場合、GitLab 18.3以降では、GitLab Duo Coreがすぐに使用できるはずです。

プレ本番環境GitLab Dedicatedインスタンスは、設計上、GitLab Duo Coreをサポートしていません。

### 管理者エリアにGitLab Duoの設定が表示されない {#gitlab-duo-settings-not-visible-in-admin-area}

次の問題が1つ以上発生する可能性があります:

- **GitLab Duo**セクションが管理者エリアに表示されません。
- 設定オプションが見つかりません。
- APIコールが`"addOnPurchases": []`を返します。

これらの問題は、ライセンスがインスタンスと適切に同期されていない場合に発生します。

この問題を解決するには、サブスクリプションの同期を確認するためのサポートチケットを作成してください。サポートは、同期ステータスを確認し、必要に応じて新しいライセンスの生成をリクエストできます。

### エラー: `GitLab-workflow failed: the GitLab Language server failed to start in 10 seconds`{#error-gitlab-workflow-failed-the-gitlab-language-server-failed-to-start-in-10-seconds}

Web IDEでGitLab Duoチャットを使用すると、このエラーが発生する可能性があります。`Platform is missing!`に関するコンソールエラーも表示される場合があります

この問題は、`cloud.gitlab.com`および`customers.gitlab.com`へのネットワーキング接続がネットワーク設定によってブロックされている場合に発生します。

この問題を解決するには、以下を実行します:

1. `cloud.gitlab.com:443`および`customers.gitlab.com:443`への送信接続を確認します。
1. 必要に応じて、[許可リストにCloudflare IP範囲](https://www.cloudflare.com/ips/)を追加します。
1. [プライベートリンク](../../administration/dedicated/configure_instance/network_security.md#aws-private-link-connectivity)で、許可リストまたはファイアウォールの制限を確認してください。
1. [送信リクエストのフィルタリング](../../security/webhooks.md#gitlab-duo-functionality-is-blocked)に従って、接続の問題をトラブルシュートします。
1. インスタンスからの接続をテストします。

### エラー: `Unable to resolve resource`{#error-unable-to-resolve-resource}

Web IDEの読み込むに失敗すると、このエラーが発生する可能性があります。CORSエラーのブラウザーログを確認してください：`failed to load because it violates the following Content Security policy`。

この問題は、CORSポリシーがリクエストされたリソースをブロックすると発生します。

この問題を解決するには、以下を実行します:

1. GitLab Workflow Extensionバージョン6.35.1以降にアップデートします。
1. CORSポリシーに`https://*.cdn.web-ide.gitlab-static.net`を追加します。
1. トラブルシューティングをさらに行うには、HARファイルのログを確認してください。詳細については、[HARファイルを作成する](../../user/application_security/api_fuzzing/create_har_files.md)を参照してください。

詳細については、[CORSの問題](../../user/project/web_ide/_index.md#cors-issues)を参照してください。

## ユーザーが利用できないGitLab Duo機能 {#gitlab-duo-features-not-available-for-users}

[GitLab Duo機能をオンにする](turn_on_off.md)ことに加えて、次のこともできます:

- GitLab Duo Coreをお持ちの場合は、以下があることを確認してください:
  - PremiumまたはUltimateサブスクリプション。
  - [IDE機能をオンにしました](turn_on_off.md#turn-gitlab-duo-core-on-or-off)。
- GitLab Duo ProまたはEnterpriseをお持ちの場合:
  - [サブスクリプションアドオンが購入されている](../../subscriptions/subscription-add-ons.md#purchase-gitlab-duo)ことを確認します。
  - [シートがユーザーに割り当てられている](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats)ことを確認します。
- IDEの場合:
  - [拡張機能](../project/repository/code_suggestions/set_up.md#configure-editor-extension)またはプラグインが最新であることを確認します。
  - ヘルスチェックを実行し、認証をテストします。
