---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabサイレントモード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.11で[導入](https://gitlab.com/groups/gitlab-org/-/epics/9826)されました。これは[実験](../../policy/development_stages_support.md#experiment)的な機能です。
- WEB UIでのサイレントモードの有効化と無効化は、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131090)されました。
- GitLab 16.6で[一般提供](../../policy/development_stages_support.md#generally-available)になりました。

{{< /history >}}

サイレントモードでは、GitLabからの送信通信（メールなど）を停止できます。サイレントモードは、使用中の環境での使用を目的としていません。

## サイレントモードの使用場面 {#when-to-use-silent-mode}

サイレントモードは特定のテストおよび検証シナリオ向けに設計されており、本番環境向けの汎用機能として使用しないでください。

サイレントモードは、以下のシナリオ向けに設計されています:

- Geoサイトのプロモートのテスト: Geoサイトのセカンダリサイトをプロモートしてディザスターリカバリー手順を検証する際に、プライマリサイトがアクティブなままである場合。
  - たとえば、[ディザスターリカバリー](../geo/disaster_recovery/_index.md)ソリューションの一部として、セカンダリGeoサイトがあるとします。ディザスターリカバリー計画が実際に機能することを保証するためのベストプラクティスとして、それをプロモートしてプライマリGeoサイトにすることを定期的にテストしたいとします。ただし、プライマリサイトが、ユーザーへのレイテンシーが最も低い地域にあるため、フェイルオーバー全体を実際には実行したくありません。また、定期的なテストのたびにダウンタイムを発生させたくありません。そのため、プライマリサイトを起動したまま、セカンダリサイトをプロモートします。プロモートされたサイトのスモークテストを開始します。しかし、プロモートされたサイトがユーザーにメールを送信し始め、プッシュミラーが外部のGitリポジトリへの変更をプッシュするなどが発生します。ここでサイレントモードが登場します。サイトのプロモートの一部として有効にすることで、この問題を回避できます。
- GitLabのバックアップの検証: バックアップが機能していることを確認するために、別のテストインスタンスでバックアップの復元をテストする場合。サイレントモードを使用すると、無効なメールをユーザーに送信することを回避できます。
- ステージング環境のテスト: ユーザーまたは外部システムに影響を与える可能性のある送信通信をトリガーせずに、GitLabの機能をテストする必要がある場合。特に、本番データを使用してステージング環境をシードした場合。

サイレントモードは、以下のような目的には設計されていません:

- 本番環境: サイレントモードは意図的に[多くのGitLab機能を中断](#behavior-of-gitlab-features-in-silent-mode)します。サイレントモードは、予期しないエラーを引き起こす可能性があり、特に新機能で発生しやすくなります。サイレントモードでは、デフォルトで新しい通信をブロックすることで、安全側に倒す必要があります。

## サイレントモードをオンにする {#turn-on-silent-mode}

前提要件: 

- 管理者アクセス権が必要です。

サイレントモードをオンにする方法は複数あります:

- **WEB UI**

  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **Silent Mode**（サイレントモード）を展開し、**Enable Silent Mode**（サイレントモードを有効にする）切替をオンにします。
  1. 変更はすぐに保存されます。

- [**API**](../../api/settings.md):

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?silent_mode_enabled=true"
  ```

- [**Rails console**（Railsコンソール）](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update!(silent_mode_enabled: true)
  ```

有効になるまでに最大1分かかる場合があります。[イシュー405433](https://gitlab.com/gitlab-org/gitlab/-/issues/405433)は、この遅延を削除することを提案しています。

## サイレントモードをオフにする {#turn-off-silent-mode}

前提要件: 

- 管理者アクセス権が必要です。

サイレントモードを無効にする方法は複数あります:

- **WEB UI**

  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **Silent Mode**（サイレントモード）を展開し、**Enable Silent Mode**（サイレントモードを有効にする）切替をオフにします。
  1. 変更はすぐに保存されます。

- [**API**](../../api/settings.md):

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?silent_mode_enabled=false"
  ```

- [**Rails console**（Railsコンソール）](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update!(silent_mode_enabled: false)
  ```

有効になるまでに最大1分かかる場合があります。[イシュー405433](https://gitlab.com/gitlab-org/gitlab/-/issues/405433)は、この遅延を削除することを提案しています。

## サイレントモードでのGitLab機能の動作 {#behavior-of-gitlab-features-in-silent-mode}

このセクションでは、サイレントモードが有効になっている場合のGitLabの現在の動作について説明します。サイレントモードの最初のイテレーションの作業は、[エピック9826](https://gitlab.com/groups/gitlab-org/-/epics/9826)で追跡されます。

サイレントモードが有効になっている場合、設定が有効になっていること、および**All outbound communications are blocked**（すべての送信通信がブロックされている）ことを示すバナーが、すべてのユーザーに対してページの上部に表示されます。

### 停止される送信通信 {#outbound-communications-that-are-silenced}

次の機能からの送信通信は、サイレントモードによって停止されます。

| 機能                                                                   | 備考                                                                                                                                                                                                                                                   |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [GitLab Duo](../../user/gitlab_duo_chat/_index.md)                         | GitLab Duoの機能は、外部の言語言語モデルプロバイダーに接続できません。 |
| [プロジェクトおよびグループWebhook](../../user/project/integrations/webhooks.md) | UI経由でWebhookテストをトリガーすると、HTTPステータス500応答が発生します。                                                                                                                                                                               |
| [システムフック](../system_hooks.md)                                        |                                                                                                                                                                                                                                                         |
| [リモートミラー](../../user/project/repository/mirror/_index.md)           | リモートミラーへのプッシュはスキップされます。リモートミラーからのプルはスキップされます。                                                                                                                                                                             |
| [実行可能なインテグレーション](../../user/project/integrations/_index.md)       | インテグレーションは実行されません。                                                                                                                                                                                                                      |
| [サービスデスク](../../user/project/service_desk/_index.md)                  | 受信メールは引き続きイシューを提起しますが、メールをサービスデスクに送信したユーザーには、イシューの作成またはイシューへのコメントが通知されません。                                                                                                   |
| 送信メール                                                           | メールがGitLabによって送信されるはずの瞬間に、代わりにドロップされます。どこにもキューに入れられません。                                                                                                                                                 |
| 送信HTTPリクエスト                                                    | 多くのHTTPリクエストは、機能が明示的にブロックまたはスキップされていない場合にブロックされます。これらは、クラス`SilentModeBlockedError`でエラーを生成する可能性があります。特定のエラーがサイレントモードでのテスト中に問題となる場合は、[GitLabサポート](https://about.gitlab.com/support/)にお問い合わせください。一般に、呼び出し元は、HTTPリクエストの作成を試みるのではなく、サイレントモードが有効になっている場合は終了する必要があります。例外は、[サイレントモードの意図された用途](#when-to-use-silent-mode)に沿っている必要があります。 |

### 停止されない送信通信 {#outbound-communications-that-are-not-silenced}

次の機能からの送信通信は、サイレントモードによって停止されません。

| 機能                                                                                                     | 備考                                                                                                                                                                                                                                           |
| ----------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [依存プロキシ](../packages/dependency_proxy.md)                                                         | キャッシュされていないイメージをプルすると、通常どおりソースからフェッチされます。プルレート制限を検討してください。                                                                                                                                              |
| [ファイルフック](../file_hooks.md)                                                                              |                                                                                                                                                                                                                                                 |
| [サーバーフック](../server_hooks.md)                                                                          |                                                                                                                                                                                                                                                 |
| [高度な検索](../../integration/advanced_search/elasticsearch.md)                                       | 2つのGitLabインスタンスが同じ高度な検索インスタンスを使用している場合、両方とも検索データを変更できます。これは、たとえば、プライマリGeoサイトが稼働中にセカンダリGeoサイトをプロモートした後に発生する可能性のある、分割されたシナリオです。 |
| [ClickHouseの呼び出し](../../integration/clickhouse.md)                                                         | ClickHouseのリクエストは、サイトの内部と見なされるため、停止されません。                                                                                                                                                            |
| Snowplow                                                                                                    | これらのリクエストを停止するための提案が、[イシュー409661](https://gitlab.com/gitlab-org/gitlab/-/issues/409661)にあります。                                                                                                                                          |
| [非推奨のKubernetes接続](../../user/clusters/agent/_index.md)                                    | [これらのリクエストを停止するための提案](https://gitlab.com/gitlab-org/gitlab/-/issues/396470)があります。                                                                                                                                          |
| [コンテナレジストリWebhook](../packages/container_registry.md#configure-container-registry-notifications) | [これらのリクエストを停止するための提案](https://gitlab.com/gitlab-org/gitlab/-/issues/409682)があります。                                                                                                                                          |
