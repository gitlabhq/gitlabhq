---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab for Slackアプリ
description: "GitLab for Slackアプリを設定して、スラッシュコマンドを使用し、GitLabから通知をSlackワークスペースで受信します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.2のGitLab Self-Managedで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/358872)されました。

{{< /history >}}

{{< alert type="note" >}}

このページには、GitLab for Slackアプリのユーザー向けドキュメントが含まれています。管理者向けドキュメントについては、[GitLab for Slackアプリの管理](../../../administration/settings/slack_app.md)を参照してください。

{{< /alert >}}

GitLab for Slackアプリは、[スラッシュコマンド](#slash-commands)と[通知](#slack-notifications)をSlackワークスペースに提供するネイティブSlackアプリです。GitLabは、SlackユーザーとGitLabユーザーをリンクさせることで、Slackで実行するコマンドが、リンクされたGitLabユーザーによって実行されるようにします。

## GitLab for Slackアプリをインストールする {#install-the-gitlab-for-slack-app}

前提要件:

- [Slackワークスペースにアプリを追加するための適切な権限](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)が必要です。
- GitLab Self-Managedでは、管理者が[インテグレーションを有効にする](../../../administration/settings/slack_app.md)必要があります。

GitLab 15.0以降、GitLab for Slackアプリは[きめ細かい権限](https://medium.com/slack-developer-blog/more-precision-less-restrictions-a3550006f9c3)を使用します。機能は変更されていませんが、[アプリを再インストール](#reinstall-the-gitlab-for-slack-app)する必要があります。

### プロジェクト設定またはグループ設定から {#from-the-project-or-group-settings}

{{< history >}}

- グループレベルでのインストールは、GitLab 16.10で`gitlab_for_slack_app_instance_and_group_level`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391526)されました。デフォルトでは無効になっています。
- GitLab 16.11の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820)になりました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803)になりました。機能フラグ`gitlab_for_slack_app_instance_and_group_level`は削除されました。

{{< /history >}}

プロジェクトまたはグループの設定からGitLab for Slackアプリをインストールするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **GitLab for Slack app**を選択します。
1. **Slackアプリ用GitLabをインストール**を選択します。Slackの確認ページにリダイレクトされます。
1. Slackの確認ページで次の手順を実行します:
   1. オプション。複数のSlackワークスペースにサインインしている場合は、右上にあるドロップダウンリストから、アプリをインストールするワークスペースを選択します。GitLab Self-ManagedおよびGitLab Dedicatedでは、ドロップダウンリストを表示するには、まず管理者が[複数のワークスペースのサポートを有効にする](../../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces)必要があります。
   1. **許可**を選択します。

### Slack App Directoryから {#from-the-slack-app-directory}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

GitLab.comでは、[Slack App Directory](https://slack-platform.slack.com/apps/A676ADMV5-gitlab)からGitLab for Slackアプリをインストールすることもできます。

Slack App DirectoryからGitLab for Slackアプリをインストールするには、次の手順に従います:

1. [GitLab for Slackのページ](https://gitlab.com/-/profile/slack/edit)に移動します。
1. SlackワークスペースとリンクするGitLabプロジェクトを選択します。

## GitLab for Slackアプリを再インストールする {#reinstall-the-gitlab-for-slack-app}

GitLabがGitLab for Slackアプリの新しい機能をリリースした場合、これらの機能を使用するには、アプリを再インストールする必要がある場合があります。

GitLab for Slackアプリを再インストールするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **GitLab for Slack app**を選択します。
1. **Slackアプリ用GitLabをインストール**を選択します。Slackの確認ページにリダイレクトされます。
1. Slackの確認ページで次の手順を実行します:
   1. オプション。複数のSlackワークスペースにサインインしている場合は、右上にあるドロップダウンリストから、アプリを再インストールするワークスペースを選択します。GitLab Self-ManagedおよびGitLab Dedicatedでは、ドロップダウンリストを表示するには、まず管理者が[複数のワークスペースのサポートを有効にする](../../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces)必要があります。
   1. **許可**を選択します。

GitLab for Slackアプリは、インテグレーションを使用するすべてのプロジェクトで更新されます。

または、[インテグレーションを再度設定](https://about.gitlab.com/solutions/slack/)することもできます。

## スラッシュコマンド {#slash-commands}

スラッシュコマンドを使用して、一般的なGitLabオペレーションを実行できます。

GitLab for Slackアプリの場合:

- 最初のスラッシュコマンドを実行するときに、Slackユーザーを承認する必要があります。
- `<project>`をプロジェクトのフルパスに置き換えるか、スラッシュコマンドの[プロジェクトエイリアスを作成](#create-a-project-alias)できます。

[Slackスラッシュコマンド](slack_slash_commands.md)または[Mattermostスラッシュコマンド](mattermost_slash_commands.md)を代わりに使用する場合:

- `/gitlab`を、これらのインテグレーション用に設定したトリガー名に置き換えます。
- `<project>`を削除します。

GitLabでは、次のスラッシュコマンドを使用できます:

| コマンド | 説明 |
| ------- | ----------- |
| `/gitlab help` | 使用可能なすべてのスラッシュコマンドを表示します。 |
| `/gitlab <project> issue show <id>` | ID `<id>`があるイシューを表示します。 |
| `/gitlab <project> issue new <title>` <kbd>Shift</kbd>+<kbd>Enter</kbd> `<description>` | タイトル`<title>`と説明`<description>`があるイシューを作成します。 |
| `/gitlab <project> issue search <query>` | `<query>`に一致するイシューを最大5つ表示します。 |
| `/gitlab <project> issue move <id> to <project>` | ID `<id>`があるイシューを`<project>`に移動します。 |
| `/gitlab <project> issue close <id>` | ID `<id>`があるイシューを閉じます。 |
| `/gitlab <project> issue comment <id>` <kbd>Shift</kbd>+<kbd>Enter</kbd> `<comment>` | コメント本文`<comment>`があるコメントを、ID `<id>`があるイシューに追加します。 |
| `/gitlab <project> deploy <from> to <to>` | `<from>`環境から`<to>`環境に[デプロイ](#deploy-command)します。 |
| `/gitlab <project> run <job name> <arguments>` | デフォルトブランチで[ChatOps](../../../ci/chatops/_index.md)ジョブ`<job name>`を実行します。 |
| `/gitlab incident declare` | [Slackからインシデントを作成](../../../operations/incident_management/slack.md)するためのダイアログを開きます。 |

### `deploy`コマンド {#deploy-command}

環境へのデプロイのために、GitLabはパイプラインで手動デプロイアクションを見つけようとします。

1つのデプロイアクションのみが環境に定義されている場合、そのアクションがトリガーされます。複数のデプロイアクションが定義されている場合、GitLabは環境名に一致するアクション名を見つけようとします。

GitLabが一致するデプロイアクションを見つけられない場合、コマンドはエラーを返します。

### プロジェクトエイリアスを作成する {#create-a-project-alias}

GitLab for Slackアプリでは、スラッシュコマンドはプロジェクトのフルパスをデフォルトで使用します。代わりに、プロジェクトエイリアスを使用することができます。

GitLab for Slackアプリでスラッシュコマンドのプロジェクトエイリアスを作成するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **GitLab for Slack app**を選択します。
1. プロジェクトのパスまたはエイリアスの横にある**編集**を選択します。
1. 新しいエイリアスを入力し、**変更を保存**を選択します。

## Slack通知 {#slack-notifications}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/381012)されました。

{{< /history >}}

特定のGitLab[イベント](#notification-events)に関する通知をSlackチャンネルで受信できます。

### 通知を設定する {#configure-notifications}

Slack通知を設定するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **GitLab for Slack app**を選択します。
1. **トリガー**セクションで、次のことを行います:
   - Slackで通知を受信するGitLab[イベント](#notification-events)ごとにチェックボックスをオンにします。
   - オンにしたチェックボックスごとに、通知を受信するSlackチャンネルの名前を入力します。コンマで区切られた最大10個のチャンネル名を入力できます（例: `#channel-one, #channel-two`）。

     {{< alert type="note" >}}

    Slackチャンネルが非公開の場合、[GitLab for Slackアプリをチャンネルに追加](#receive-notifications-to-a-private-channel)する必要があります。

     {{< /alert >}}

1. オプション。**通知設定**セクションで、次のことを行います:
   - **壊れたパイプラインのみ通知**チェックボックスをオンにして、失敗したパイプラインの通知のみを受信します。
   - **通知を送信するブランチ**ドロップダウンリストから、通知を受信するブランチを選択します。

     通知は、これらのブランチから作成されたタグによってトリガーされたパイプラインに対しても送信されます。

     脆弱性に関する通知は、選択したブランチに関係なく、デフォルトブランチによってのみトリガーされます。詳細については、[イシュー469373](https://gitlab.com/gitlab-org/gitlab/-/issues/469373)を参照してください。
   - **Labels to be notified**（通知するラベル）には、通知を受信するためにGitLabイシュー、マージリクエスト、またはコメントが持つ必要のあるラベルの一部またはすべてを入力します。すべてのイベントの通知を受信するには、空白のままにします。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

### 非公開チャンネルへの通知を受信する {#receive-notifications-to-a-private-channel}

Slack非公開チャンネルへの通知を受信するには、次の手順に従って、GitLab for Slackアプリをチャンネルに追加する必要があります:

1. `@GitLab`を入力して、チャンネルでアプリをメンションします。
1. **Add to Channel**（チャンネルに追加）を選択します。

### 通知イベント {#notification-events}

次のGitLabイベントは、Slackで通知をトリガーできます:

| イベント                                                                 | 説明                                                   |
|-----------------------------------------------------------------------|---------------------------------------------------------------|
| プッシュ                                                                  | プッシュがリポジトリに対して行われます。                             |
| イシュー                                                                 | イシューが作成、クローズ、または再度オープンされます。                     |
| 機密情報イシュー                                                    | 機密情報イシューが作成、クローズ、または再度オープンされます。         |
| マージリクエスト                                                         | マージリクエストが作成、マージ、クローズ、または再度オープンされます。      |
| メモ                                                                  | コメントが追加されます。                                           |
| 機密情報メモ                                                     | 機密情報イシューに関する内部メモまたはコメントが追加されます。 |
| タグプッシュ                                                              | タグがリポジトリにプッシュされるか、削除されます。                 |
| パイプライン                                                              | パイプラインの状態が変化します。                                    |
| Wikiページ                                                             | Wikiページが作成または更新されます。                            |
| デプロイ                                                            | デプロイが開始または終了します。                          |
| 公開の[グループメンション](#trigger-notifications-for-group-mentions)  | 公開チャンネルでグループがメンションされます。                     |
| 非公開の[グループメンション](#trigger-notifications-for-group-mentions) | 非公開チャンネルでグループがメンションされます。                    |
| [インシデント](../../../operations/incident_management/slack.md)          | インシデントが作成、クローズ、または再度オープンされます。                  |
| [脆弱性](../../application_security/vulnerabilities/_index.md)  | 新しい一意の脆弱性がデフォルトブランチに記録されます。|
| アラート                                                                 | 新しい一意のアラートが記録されます。                              |

### グループメンションの通知をトリガーする {#trigger-notifications-for-group-mentions}

{{< history >}}

- GitLab 16.10で`gitlab_for_slack_app_instance_and_group_level`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391526)されました。デフォルトでは無効になっています。
- GitLab 16.11の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820)になりました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803)になりました。機能フラグ`gitlab_for_slack_app_instance_and_group_level`は削除されました。

{{< /history >}}

グループメンションの[通知イベント](#notification-events)をトリガーするには、次の場所で`@<group_name>`を使用します:

- イシューとマージリクエストの説明
- イシュー、マージリクエスト、コミットのコメント
