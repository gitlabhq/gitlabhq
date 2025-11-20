---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトインテグレーション
description: "プロジェクトとグループのインテグレーションに関するユーザー向けドキュメントです。利用可能なインテグレーションの一覧が含まれています。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

このページでは、プロジェクトのインテグレーションに関するユーザー向けドキュメントを掲載しています。管理者向けドキュメントについては、[プロジェクトインテグレーションの管理](../../../administration/settings/project_integration_management.md)を参照してください。

{{< /alert >}}

外部アプリケーションとマージして、GitLabに機能を追加できます。

以下のインテグレーションを表示および管理できます:

- [インスタンス](../../../administration/settings/project_integration_management.md#configure-default-settings-for-an-integration)（GitLab Self-Managed）
- [グループ](#manage-group-default-settings-for-a-project-integration)

以下を使用できます:

- [プロジェクトインテグレーションのインスタンスまたはグループのデフォルト設定](#use-instance-or-group-default-settings-for-a-project-integration)
- [プロジェクトまたはグループのインテグレーションのカスタム設定](#use-custom-settings-for-a-project-or-group-integration)

## プロジェクトインテグレーションのグループデフォルト設定を管理する {#manage-group-default-settings-for-a-project-integration}

前提要件: 

- グループのオーナーロールを持っている必要があります。

プロジェクトインテグレーションのグループデフォルト設定を管理するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. インテグレーションを選択します。
1. フィールドに入力します。
1. **変更を保存**を選択します。

{{< alert type="warning" >}}

これは、グループに属するすべてのサブグループおよびプロジェクト、またはそのほとんどに影響を与える可能性があります。以下の詳細を確認してください。

{{< /alert >}}

グループ設定を初めてインテグレーションに設定する場合:

- グループ設定で**インテグレーションを有効にする**切替がオンになっている場合、このインテグレーションがまだ構成されていないグループに属するすべてのサブグループおよびプロジェクトに対して、インテグレーションが有効になります。
- すでにインテグレーションが構成されているサブグループとプロジェクトは影響を受けませんが、いつでも継承された設定を使用するように選択できます。

グループデフォルトをさらに変更すると:

- デフォルト設定を使用するようにインテグレーションが設定されているグループに属するすべてのサブグループおよびプロジェクトに即座に適用されます。
- 最後にインテグレーションのデフォルトを保存した後に作成されたものであっても、新しいサブグループとプロジェクトにすぐに適用されます。グループデフォルト設定で**インテグレーションを有効にする**切替がオンになっている場合、そのようなサブグループとプロジェクトすべてに対して、インテグレーションが自動的に有効になります。
- インテグレーションに選択されたカスタム設定を持つサブグループとプロジェクトはすぐに影響を受けることはなく、いつでも最新のデフォルトを使用するように選択できます。

[インスタンス設定](../../../administration/settings/project_integration_management.md#configure-default-settings-for-an-integration)が同じインテグレーションに構成されている場合、グループ内のプロジェクトはグループから設定を継承します。

インテグレーションの全体的な設定のみを継承できます。フィールドごとの継承は、[エピック2137](https://gitlab.com/groups/gitlab-org/-/epics/2137)で提案されています。

### グループデフォルト設定を削除する {#remove-a-group-default-setting}

前提要件: 

- グループのオーナーロールを持っている必要があります。

グループデフォルト設定を削除するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. インテグレーションを選択します。
1. **リセット**を選択して確定します。

グループデフォルト設定をリセットすると、デフォルト設定を使用し、グループのプロジェクトまたはサブグループに属するインテグレーションが削除されます。

## プロジェクトインテグレーションにインスタンスまたはグループのデフォルト設定を使用する {#use-instance-or-group-default-settings-for-a-project-integration}

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

プロジェクトインテグレーションにインスタンスまたはグループのデフォルト設定を使用するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. インテグレーションを選択します。
1. 右側のドロップダウンリストから、**デフォルトの設定を使用**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスがオンになっていることを確認します。
1. フィールドに入力します。
1. **変更を保存**を選択します。

## プロジェクトまたはグループのインテグレーションにカスタム設定を使用する {#use-custom-settings-for-a-project-or-group-integration}

前提要件: 

- プロジェクトインテグレーションのメンテナー以上のロールを持っている必要があります。
- グループインテグレーションのオーナーロールが必要です。

プロジェクトまたはグループのインテグレーションにカスタム設定を使用するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. インテグレーションを選択します。
1. 右側のドロップダウンリストから、**カスタムの設定を使用**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスがオンになっていることを確認します。
1. フィールドに入力します。
1. **変更を保存**を選択します。

## 利用可能なインテグレーション {#available-integrations}

GitLabインスタンスでは、以下のインテグレーションが利用可能な場合があります。インスタンス管理者が[インテグレーション許可リスト](../../../administration/settings/project_integration_management.md#integration-allowlist)を構成している場合、それらのインテグレーションのみが利用可能です。

### CI/CD {#cicd}

| インテグレーション                                                  | 説明                                                                              | インテグレーションフック |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |
| [Atlassian Bamboo](bamboo.md)                                | Atlassian Bambooで/CI/CDパイプラインを実行します。                                               | {{< icon name="check-circle" >}}対応 |
| Buildkite                                                    | Buildkiteで/CI/CDパイプラインを実行します。                                                      | {{< icon name="check-circle" >}}対応 |
| Drone                                                        | Droneで/CI/CDパイプラインを実行します。                                                          | {{< icon name="check-circle" >}}対応 |
| [Jenkins](../../../integration/jenkins.md)                   | Jenkinsで/CI/CDパイプラインを実行します。                                                        | {{< icon name="check-circle" >}}対応 |
| JetBrains TeamCity                                           | TeamCityで/CI/CDパイプラインを実行します。                                                       | {{< icon name="check-circle" >}}対応 |

### イベント通知 {#event-notifications}

| インテグレーション                                                  | 説明                                                                              | インテグレーションフック |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |
| Campfire                                                     | Campfireをチャットに接続します。                                                                | {{< icon name="dotted-circle" >}}非対応 |
| [Discord通知](discord_notifications.md)            | プロジェクトイベントに関する通知をDiscordチャンネルに送信します。                            | {{< icon name="dotted-circle" >}}非対応 |
| [Google Chat](hangouts_chat.md)                              | GitLabプロジェクトからGoogleチャットのスペースに通知を送信します。                   | {{< icon name="dotted-circle" >}}非対応 |
| [irker（IRCゲートウェイ）](irker.md)                              | IRCチャンネルにイベント通知を送信します。                                                                       | {{< icon name="dotted-circle" >}}非対応 |
| [Matrix通知](matrix.md)                            | プロジェクトイベントに関する通知をMatrixに送信します。                                       | {{< icon name="dotted-circle" >}}非対応 |
| [Mattermost通知](mattermost.md)                    | プロジェクトイベントに関する通知をMattermostチャンネルに送信します。                          | {{< icon name="dotted-circle" >}}非対応 |
| [Microsoft Teams通知](microsoft_teams.md)          | Microsoft Teamsにイベント通知を送信します。                                          | {{< icon name="dotted-circle" >}}非対応 |
| [Pumble](pumble.md)                                          | Pumbleチャンネルにイベント通知を送信します。                                            | {{< icon name="dotted-circle" >}}非対応 |
| Pushover                                                     | デバイスにイベント通知を送信します。                                              | {{< icon name="dotted-circle" >}}非対応 |
| [Telegram](telegram.md)                                      | プロジェクトイベントに関する通知をTelegramに送信します。                                     | {{< icon name="dotted-circle" >}}非対応 |
| [Unify Circuit](unify_circuit.md)                            | プロジェクトイベントに関する通知をUnify Circuitに送信します。                                | {{< icon name="dotted-circle" >}}非対応 |
| [Webex Teams](webex_teams.md)                                | Webex Teamsにイベント通知を送信します。                                              | {{< icon name="dotted-circle" >}}非対応 |

### ストア {#stores}

| インテグレーション                                                  | 説明                                                                              | インテグレーションフック |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |
| [Apple App Store Connect](apple_app_store.md)                | GitLabを使用して、Apple App Storeでアプリをビルドおよびリリースします。                           | {{< icon name="dotted-circle" >}}非対応 |
| [Google Play](google_play.md)                                | GitLabを使用して、Google Playでアプリをビルドおよびリリースします。                                   | {{< icon name="dotted-circle" >}}非対応 |
| [Harbor](harbor.md)                                          | HarborをGitLabのコンテナレジストリとして使用します。                                         | {{< icon name="dotted-circle" >}}非対応 |
| Packagist                                                    | PackagistでPHPの依存関係を更新します。                                               | {{< icon name="check-circle" >}}対応 |

### 外部イシュートラッカー {#external-issue-trackers}

以下のインテグレーションにより、プロジェクトの左側のサイドバーに[外部イシュートラッカー](../../../integration/external-issue-tracker.md)へのリンクが追加されます。

| インテグレーション                                                  | 説明                                                                              | インテグレーションフック | イシュー同期 | 新しいイシューを作成できます |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |----------------- |----------------- |
| [Bugzilla](bugzilla.md)                                      | イシュートラッカーとしてBugzillaを使用します。                                                        | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| [ClickUp](clickup.md)                                        | イシュートラッカーとしてClickUpを使用します。                                                         | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="dotted-circle" >}}非対応 |
| [カスタムイシュートラッカー](custom_issue_tracker.md)              | カスタムイシュートラッカー                                                              | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="dotted-circle" >}}非対応 |
| [Engineering Workflow Management（EWM）](ewm.md)              | イシュートラッカーとしてEWMを使用します。                                                             | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| [Linear](linear.md)                                          | イシュートラッカーとしてLinearを使用します。                                                          | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="dotted-circle" >}}非対応 |
| [Phorge](phorge.md)                                          | イシュートラッカーとしてPhorgeを使用します。                                                          | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| [Redmine](redmine.md)                                        | イシュートラッカーとしてRedmineを使用します。                                                         | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| [YouTrack](youtrack.md)                                      | JetBrains YouTrackをプロジェクトのイシュートラッカーとして使用します。                                  | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 |

### 外部Wiki {#external-wikis}

以下のインテグレーションにより、プロジェクトの左側のサイドバーに外部Wikiへのリンクが追加されます。

| インテグレーション                                                  | 説明                                                                              | インテグレーションフック |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |
| [Confluence Workspace](confluence.md)                        | Confluence Cloudワークスペースを内部Wikiとして使用します。                                      | {{< icon name="dotted-circle" >}}非対応 |
| [外部Wiki](../wiki/_index.md#link-an-external-wiki)      | 外部Wikiにリンクする                                                                   | {{< icon name="dotted-circle" >}}非対応 |

### その他 {#other}

| インテグレーション                                                  | 説明                                                                              | インテグレーションフック |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |
| [Asana](asana.md)                                            | Asanaタスクにコミットメッセージをコメントとして追加します。                                          | {{< icon name="dotted-circle" >}}非対応 |
| Assembla                                                     | Assemblaでプロジェクトを管理します。                                                           | {{< icon name="dotted-circle" >}}非対応 |
| [Beyond Identity](beyond_identity.md)                        | Beyond Identity AuthenticatorによってGPGキーが承認されていることを確認します。                    | {{< icon name="dotted-circle" >}}非対応 |
| [Datadog](../../../integration/datadog.md)                   | DatadogでGitLabパイプラインをトレースします。                                                | {{< icon name="check-circle" >}}対応 |
| [Diffblue Cover](../../../integration/diffblue_cover.md)     | 包括的で人間のようなJava単体テストを自動的に作成します。                           | {{< icon name="check-circle" >}}非対応 |
| [プッシュ時にメールを送信](emails_on_push.md)                          | プッシュ時にコミットメッセージと差分をメールで送信します。                                                 | {{< icon name="dotted-circle" >}}非対応 |
| [GitGuardian](git_guardian.md)                               | GitGuardianポリシーに基づいてコミットメッセージを却下します。                                            | {{< icon name="dotted-circle" >}}非対応 |
| [GitHub](github.md)                                          | コミットメッセージとプルリクエストのステータスを受信します。                                          | {{< icon name="dotted-circle" >}}非対応 |
| [GitLab for Slackアプリ](gitlab_slack_application.md)          | ネイティブSlackアプリを使用して、通知を受信し、コマンドを実行します。                      | {{< icon name="dotted-circle" >}}非対応 |
| [Google Artifact Management](google_artifact_management.md)  | Google Artifactレジストリでアーティファクトを管理します。                                       | {{< icon name="dotted-circle" >}}非対応 |
| [Google Cloud IAM](../../../integration/google_cloud_iam.md) | Identity and Access Management（IAM）を使用して、Google Cloudリソースの権限を管理します。 | {{< icon name="dotted-circle" >}}非対応 |
| [Jira](../../../integration/jira/_index.md)                  | イシュートラッカーとしてJiraを使用します。                                                            | {{< icon name="dotted-circle" >}}非対応 |
| [Mattermostのスラッシュコマンド](mattermost_slash_commands.md)    | Mattermostチャット環境からスラッシュコマンドを実行します。                                   | {{< icon name="dotted-circle" >}}非対応 |
| [パイプラインステータスメール](pipeline_status_emails.md)          | パイプラインのステータスをメールで受信者のリストに送信します。                               | {{< icon name="dotted-circle" >}}非対応 |
| [Pivotal Tracker](pivotal_tracker.md)                        | Pivotal Trackerストーリーにコミットメッセージをコメントとして追加します。                              | {{< icon name="dotted-circle" >}}非対応 |
| [Slackのスラッシュコマンド](slack_slash_commands.md)              | Slackチャット環境からスラッシュコマンドを実行します。                                        | {{< icon name="dotted-circle" >}}非対応 |
| [Squash TM](squash_tm.md)                                    | GitLabイシューが変更されたときにSquash TM要件を更新します。                           | {{< icon name="check-circle" >}}対応 |

## プロジェクトWebhook {#project-webhooks}

一部のインテグレーションは、外部アプリケーションに[Webhook](webhooks.md)を使用します。

プッシュ、イシュー、またはマージリクエストなどの特定のイベントをリッスンするようにプロジェクトWebhookを構成できます。Webhookがトリガーされると、GitLabは指定されたWebhook URLにデータを含むPOSTリクエストを送信します。

Webhookを使用するインテグレーションのリストについては、[利用可能なインテグレーション](#available-integrations)を参照してください。

## プッシュフック制限 {#push-hook-limit}

単一のプッシュに3つ以上のブランチまたはタグへの変更が含まれている場合、`push_hooks`イベントと`tag_push_hooks`イベントでサポートされているインテグレーションは実行されません。

サポートされているブランチまたはタグの数を変更するには、[`push_event_hooks_limit`設定](../../../api/settings.md#available-settings)を構成します。

## SSL検証 {#ssl-verification}

デフォルトでは、送信HTTPリクエストのSSL証明書は、認証局の内部リストに基づいて検証されます。SSL証明書は自己署名できません。

[Webhook](webhooks.md#configure-webhooks)と一部のインテグレーションを構成するときに、SSL検証を無効にできます。

## 関連トピック {#related-topics}

- [インテグレーションAPI](../../../api/project_integrations.md)
- [GitLabデベロッパーポータル](https://developer.gitlab.com)
