---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Slack通知（非推奨）
---

<!--- start_remove The following content will be removed on remove_date: '2026-05-16' -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 15.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/435909)となり、19.0で削除される予定です。代わりに[GitLab for Slackアプリ](gitlab_slack_application.md)を使用してください。これは破壊的な変更です。

{{< /alert >}}

Slack通知インテグレーションを使用すると、GitLabプロジェクトでイベント（イシューの作成など）を既存のSlackチームに通知として送信できます。Slack通知を設定するには、SlackとGitLabの両方で設定の変更が必要です。

SlackからGitLabを制御するために、[Slackスラッシュコマンド](slack_slash_commands.md)を使用することもできます。スラッシュコマンドは個別に構成されます。

## Slackの設定 {#configure-slack}

1. Slackチームにサインインし、[新しい受信WebHooks設定を開始](https://my.slack.com/services/new/incoming-webhook)します。
1. 通知の送信先となるSlackチャンネルをデフォルトで指定します。**Add Incoming WebHooks integration**（受信WebHooksインテグレーションの追加]を選択）して、設定を追加します。
1. **WebhookのURL**をコピーして、GitLabを設定する際に使用します。

## GitLabを設定する {#configure-gitlab}

{{< history >}}

- GitLab 15.9で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106760)され、Slackチャンネルがイベントごとに10個に制限されました。

{{< /history >}}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Slack notifications**（Slack通知）を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. **トリガー**セクションで、Slackに通知として送信するGitLabイベントの各タイプのチェックボックスをオンにします。完全なリストについては、[Slack通知のトリガー](#triggers-for-slack-notifications)を参照してください。デフォルトでは、メッセージは[Slackの設定](#configure-slack)で構成したチャンネルに送信されます。
1. オプション。別のチャンネル、複数のチャンネル、またはダイレクトメッセージとしてメッセージを送信するには:
   - *チャンネルにメッセージを送信するには*、カンマで区切ってSlackチャンネル名を入力します。
   - *ダイレクトメッセージを送信するには*、ユーザーのSlackプロファイルにあるメンバーIDを使用します。
1. **Webhook**に、[Slackの設定](#configure-slack)手順でコピーしたWebhookのURLを入力します。
1. オプション。**ユーザー名**に、通知を送信するSlackボットのユーザー名を入力します。
1. **壊れたパイプラインのみ通知**チェックボックスをオンにして、失敗した場合のみ通知します。
1. **通知を送信するブランチ**ドロップダウンリストで、通知を送信するブランチの種類を選択します。
1. すべての通知を取得するには、**Labels to be notified**（通知するラベル）フィールドを空白のままにするか、イシューまたはマージリクエストが通知をトリガーするために必要なラベルを追加します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

Slackチームは、構成されたGitLabイベント通知を受信するようになります。

## Slack通知のトリガー {#triggers-for-slack-notifications}

Slack通知には、次のトリガーを使用できます:

| トリガー名                                                             | トリガーイベント                                        |
|--------------------------------------------------------------------------|------------------------------------------------------|
| **プッシュ**                                                                 | リポジトリへのプッシュ。                            |
| **イシュー**                                                                | イシューが作成、クローズ、または再度オープンされます。            |
| **インシデント**                                                             | インシデントが作成、クローズ、または再度オープンされます。         |
| **非公開のイシュー**                                                   | 機密情報イシューが作成、クローズ、または再度オープンされます。|
| **マージリクエスト**                                                        | マージリクエストが作成、マージ、クローズ、または再度オープンされます。|
| **メモ**                                                                 | コメントが追加されます。                                  |
| **非公開メモ**                                                    | 機密情報イシューに関する内部メモまたはコメントが追加されます。|
| **タグのプッシュ**                                                             | タグがリポジトリにプッシュされるか、削除されます。    |
| **パイプライン**                                                             | パイプラインのステータスが変更されました。                           |
| **Wikiページ**                                                            | Wikiページが作成または更新されます。                   |
| **デプロイ**                                                           | デプロイが開始または完了した。                     |
| **アラート**                                                                | 新しい一意のアラートが記録されます。                     |
| **[Group mention in public](#trigger-notifications-for-group-mentions)**（パブリックでのグループメンション）                                              | 公開コンテキストでグループがメンションされます。            |
| **[Group mention in private](#trigger-notifications-for-group-mentions)**（プライベートでのグループメンション）                                             | グループが機密コンテキストで言及されている。      |
| [**脆弱性**](../../application_security/vulnerabilities/_index.md) | 新しい一意の脆弱性が記録される。             |

## グループメンションの通知をトリガーする {#trigger-notifications-for-group-mentions}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/417751)されました。
- 通知トリガーの制限は、`group_mention_access_check`という名前の[機能フラグ付き](../../../administration/feature_flags/_index.md)でGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134677)されました。デフォルトでは無効になっています。

{{< /history >}}

グループメンションの[通知イベント](#triggers-for-slack-notifications)をトリガーするには、次の場所で`@<group_name>`を使用します:

- イシューとマージリクエストの説明
- イシュー、マージリクエスト、コミットのコメント

通知は、言及が行われたリソース（たとえば、マージリクエスト）を表示する権限がすべての直接グループメンバーにある場合にのみ、トリガーされます。1つのイベントで最大3つのグループにのみ通知が送信されます。

## トラブルシューティング {#troubleshooting}

Slackインテグレーションが機能しない場合は、Slackサービスに関連するエラーについて、[Sidekiqログ](../../../administration/logs/_index.md#sidekiqlog)を検索してトラブルシューティングを開始します。

### エラー: `Something went wrong on our end` {#error-something-went-wrong-on-our-end}

この一般的なエラーメッセージがGitLab UIに表示される場合があります。エラーメッセージを見つけて、そこからトラブルシューティングを続けるには、[ログ](../../../administration/logs/_index.md#productionlog)をレビューしてください。

### エラー: `certificate verify failed` {#error-certificate-verify-failed}

Sidekiqログに次のようなエントリが表示される場合があります:

```plaintext
2019-01-10_13:22:08.42572 2019-01-10T13:22:08.425Z 6877 TID-abcdefg Integrations::ExecuteWorker JID-3bade5fb3dd47a85db6d78c5 ERROR: {:class=>"Integrations::ExecuteWorker :integration_class=>"SlackService", :message=>"SSL_connect returned=1 errno=0 state=error: certificate verify failed"}
```

このイシューは、GitLabとSlack間の通信、またはGitLab自体との通信に問題がある場合に発生します。Slackセキュリティ証明書は常に信頼されるため、前者の可能性は低くなります。

これらの問題のどちらが原因であるかを表示するには:

1. Railsコンソールを起動します:

   ```shell
   sudo gitlab-rails console -e production

   # for source installs:
   bundle exec rails console -e production
   ```

1. 次のコマンドを実行します:

   ```ruby
   # replace <SLACK URL> with your actual Slack URL
   result = Net::HTTP.get(URI('https://<SLACK URL>'));0

   # replace <GITLAB URL> with your actual GitLab URL
   result = Net::HTTP.get(URI('https://<GITLAB URL>'));0
   ```

GitLabがHTTPS接続を信頼しない場合は、[証明書をGitLabの信頼できる証明書に追加](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)します。

GitLabがSlackへの接続を信頼しない場合、GitLab OpenSSLトラストストアが正しくありません。一般的な原因は次のとおりです:

- `gitlab_rails['env'] = {"SSL_CERT_FILE" => "/path/to/file.pem"}`でトラストストアをオーバーライドする。
- デフォルトのCAバンドル`/opt/gitlab/embedded/ssl/certs/cacert.pem`を誤って変更しました。

### Slack通知インテグレーションを無効にする一括更新 {#bulk-update-to-disable-the-slack-notification-integration}

Slackインテグレーションが有効になっているすべてのプロジェクトの通知を無効にするには、[Railsコンソールセッションを開始](../../../administration/operations/rails_console.md#starting-a-rails-console-session)し、次のようなスクリプトを使用します:

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

```ruby
# Grab all projects that have the Slack notifications enabled
p = Project.find_by_sql("SELECT p.id FROM projects p LEFT JOIN integrations s ON p.id = s.project_id WHERE s.type_new = 'Integrations::Slack' AND s.active = true")

# Disable the integration on each of the projects that were found.
p.each do |project|
  project.slack_integration.update!(:active, false)
end
```

<!--- end_remove -->
