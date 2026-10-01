---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab for Slackアプリ
description: "Slackワークスペースからスラッシュコマンドの使用、通知の受信、GitLab Duoとの対話を行うようにGitLab for Slackアプリを設定します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!note]
> 管理者向けドキュメントについては、[GitLab for Slackアプリの管理](../../../administration/settings/slack_app.md)を参照してください。

GitLab for Slackアプリは、Slackワークスペースで[スラッシュコマンド](#slash-commands)、[通知](#slack-notifications)、および[GitLab Duoインテグレーション](#gitlab-duo)を提供するネイティブSlackアプリです。GitLabは、SlackユーザーとGitLabユーザーをリンクさせることで、Slackで実行するコマンドが、リンクされたGitLabユーザーによって実行されるようにします。

## GitLab for Slackアプリをインストールする {#install-the-gitlab-for-slack-app}

前提条件: 

- [Slackワークスペースにアプリを追加するための適切な権限](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)が必要です。
- GitLab Self-Managedでは、管理者が[インテグレーションを有効にする](../../../administration/settings/slack_app.md)必要があります。

GitLab for Slackアプリは[きめ細かなパーミッション](https://medium.com/slack-developer-blog/more-precision-less-restrictions-a3550006f9c3)を使用します。機能は変更されていませんが、[アプリを再インストール](#reinstall-the-gitlab-for-slack-app)する必要があります。

### プロジェクト設定またはグループ設定から {#from-the-project-or-group-settings}

{{< history >}}

- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803)になりました。機能フラグ`gitlab_for_slack_app_instance_and_group_level`は削除されました。

{{< /history >}}

プロジェクトまたはグループの設定からGitLab for Slackアプリをインストールするには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**設定** > **インテグレーション**を選択します。
1. **GitLab for Slackアプリ**を選択します。
1. **GitLab for Slackアプリをインストール**を選択します。Slackの確認ページにリダイレクトされます。
1. Slackの確認ページで次の手順を実行します。
   1. オプション。複数のSlackワークスペースにサインインしている場合は、右上にあるドロップダウンリストから、アプリをインストールするワークスペースを選択します。GitLab Self-ManagedおよびGitLab Dedicatedでは、ドロップダウンリストを表示するには、まず管理者が[複数のワークスペースのサポートを有効にする](../../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces)必要があります。
   1. **許可**を選択します。

グループにアプリをインストールすると、インテグレーションが設定されていないグループ内のすべてのサブグループとプロジェクトでも、インテグレーションが有効になります。すでにインテグレーションが設定されているサブグループやプロジェクトは影響を受けませんが、いつでも継承された設定を使用できます。詳細については、[プロジェクトインテグレーションのグループデフォルト設定を管理する](_index.md#manage-group-default-settings-for-a-project-integration)を参照してください。各プロジェクトは、そのプロジェクトパスに基づいたプロジェクト固有のエイリアスを取得し、[スラッシュコマンド](#slash-commands)で使用できます。

### Slack App Directoryから {#from-the-slack-app-directory}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

GitLab.comでは、[Slack App Directory](https://slack-platform.slack.com/apps/A676ADMV5-gitlab)からGitLab for Slackアプリをインストールすることもできます。

Slack App DirectoryからGitLab for Slackアプリをインストールするには、次の手順に従います。

1. [GitLab for Slackのページ](https://gitlab.com/-/profile/slack/edit)に移動します。
1. SlackワークスペースとリンクするGitLabプロジェクトを選択します。

## GitLab for Slackアプリを再インストールする {#reinstall-the-gitlab-for-slack-app}

GitLabがGitLab for Slackアプリの新しい機能をリリースした場合、これらの機能を使用するには、アプリを再インストールする必要がある場合があります。

GitLab for Slackアプリを再インストールするには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **インテグレーション**を選択します。
1. **GitLab for Slackアプリ**を選択します。
1. **GitLab for Slackアプリをインストール**を選択します。Slackの確認ページにリダイレクトされます。
1. Slackの確認ページで次の手順を実行します。
   1. オプション。複数のSlackワークスペースにサインインしている場合は、右上にあるドロップダウンリストから、アプリを再インストールするワークスペースを選択します。GitLab Self-ManagedおよびGitLab Dedicatedでは、ドロップダウンリストを表示するには、まず管理者が[複数のワークスペースのサポートを有効にする](../../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces)必要があります。
   1. **許可**を選択します。

GitLab for Slackアプリは、インテグレーションを使用するすべてのプロジェクトで更新されます。

または、[インテグレーションを再度設定](https://about.gitlab.com/solutions/slack/)することもできます。

## GitLab Duo {#gitlab-duo}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.1で`slack_duo_agent`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/590434)されました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- GitLab 19.4で[GitLab.comおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/work_items/592185)になりました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

<!-- Two distinct notes, so the blank line between them is intentional. -->

> [!note]
> 複数のSlackインストールをSlack Enterprise Gridなしで使用している場合、SlackはGitLab Duoのレート制限を1分あたり15会話オブジェクトに設定します。単一の実行がチャンネル履歴から50件のメッセージをコンテキストとして要求するため、これによりインテグレーションの機能が妨げられます。SlackでGitLab Duoのレート制限を回避するには、すべてのSlackワークスペースを単一のEnterprise Grid組織に保持してください。

ボットが存在する任意のチャンネルまたはスレッドでGitLabボットにメンションすることで、Slackから直接[GitLab Duo](../../gitlab_duo/_index.md)と対話できます。GitLab Duoは、会話スレッド全体と最近のチャンネル履歴をコンテキストとして読み込み、CI/CD Runnerでフローを実行し、結果をSlackスレッドに投稿します。

例えば、GitLab Duoに以下のことを依頼できます:

- 会話をGitLabイシューに変換します。
- 既存のイシューまたはマージリクエストを検索します。
- ディスカッションスレッドを要約します。
- プロジェクトに関する質問に回答します。

各インタラクションはGitLab Duoエージェントセッションを実行し、GitLabクレジットを消費します。セッションは、呼び出し元のユーザーのデフォルトDuoネームスペースにあるCI/CD Runnerで実行され、初回使用時に`duo-workspace`プロジェクトが自動的に作成されます。異なるトップレベルグループのプロジェクトについて尋ねると、SlackのGitLab Duoは失敗します。

チャンネルでメンションされると、エージェントはそのチャンネルからの最近のメッセージをコンテキストとして読み込み、応答します。応答中のメッセージより後に投稿されたメッセージは含まれません。ユーザーがGitLab Duoと対話すると、実行したユーザーのみに表示されるエージェントセッションが作成され、`duo-workspace`プロジェクトにアクセスできるすべての人には表示されません。

> [!note]
> スレッドでGitLabボットにメンションすると、会話のコンテンツ全体（すべての参加者からのメッセージを含む）が大規模言語モデル（LLM）に送信され、応答が生成されます。GitLab Duoにメンションするスレッドでは、機密情報を共有しないでください。

### 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformを有効にする](../../duo_agent_platform/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off)。
- [ベータ版および実験的機能を有効にする](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)。
- SlackアカウントをGitLabアカウントにリンクします。アカウントがリンクされていない場合、GitLabは初回メンション時に接続を承認するためのリンクを含むメッセージを送信します。
- [デフォルトのGitLab Duoネームスペースを設定する](../../profile/preferences.md#set-a-default-gitlab-duo-namespace)。
- トップレベルグループの[デベロッパーフロー](../../duo_agent_platform/flows/foundational_flows/developer.md)を有効にします。
- GitLabボットを使用したいSlackチャンネルに追加します。
- 既存のインストールでは、GitLab Duoに必要な追加のパーミッションを付与するために、[GitLab for Slackアプリを再インストール](#reinstall-the-gitlab-for-slack-app)します。

### SlackでGitLab Duoを使用する {#use-gitlab-duo-in-slack}

SlackでGitLab Duoを使用するには:

1. `/invite @GitLab`を使用してアプリをチャンネルに招待します。
1. Slackチャンネルまたはそのチャンネルのスレッドで、`@GitLab`に続けてリクエストを入力します（例: `@GitLab create an issue to track this bug`）。
1. 初めて`@GitLab`と入力すると、GitLabはSlackとGitLabアカウントを接続するためのリンクを含むメッセージを送信します。
1. GitLab Duoはあなたのリクエストを認識し、タスクの実行を開始します。
1. タスクが完了すると、GitLab Duoはスレッド形式で結果を返信します。

エラーが発生した場合、GitLab Duoはあなたのメッセージにロックされた南京錠の絵文字リアクションを返し、イシューの詳細を記載したメッセージを送信します。このメッセージはあなたにのみ表示されます。

この機能のパフォーマンスに関するフィードバックを残すには、任意の応答に「いいね」または「よくないね」を使用します。

SlackのGitLab Duoは以下のチャンネルとスレッドで動作します:

- エージェントがチャンネルのメンバーである公開およびプライベートチャンネル。
- 2人以上のグループダイレクトメッセージ。GitLab Duoは、メンションされたメッセージのみを認識し、以前の会話は認識しません。

GitLab Duoは以下のスレッドでは動作しません:

- エージェントとの1対1のダイレクトメッセージ。
- Slackトップバーのエージェントパネル内。

### ワークスペースプロジェクト {#workspace-project}

SlackからGitLab Duoを初めて使用すると、デフォルトのGitLab Duoネームスペースに`duo-workspace`というワークスペースプロジェクトが自動的に作成されます。このプロジェクトは、Slackからトリガーされたフローの実行環境として機能します。

ワークスペースプロジェクトでエージェントの動作をカスタマイズできます。詳細については、[デベロッパーフロー](../../duo_agent_platform/flows/foundational_flows/developer.md)を参照してください。

### GitLab for Slackアプリのパーミッション {#gitlab-for-slack-app-permissions}

GitLab Duoには、以下の追加のGitLab for Slackアプリのパーミッションが必要です:

| スコープ               | 目的 |
|---------------------|---------|
| `app_mentions:read` | ユーザーがチャンネルでボットにメンションしたときにイベントを受信します。 |
| `channels:history`  | 公開チャンネルの会話履歴を読み取り、スレッドおよびチャンネルのコンテキストをエージェントに提供します。 |
| `groups:history`    | プライベートチャンネルの会話履歴を読み取り、スレッドおよびチャンネルのコンテキストをエージェントに提供します。 |
| `reactions:write`   | メッセージに絵文字リアクションを追加して、エージェントのライフサイクルステータスを示します。 |

新規インストールでは、これらのパーミッションが自動的に付与されます。既存のインストールでは、[GitLab for Slackアプリを再インストール](#reinstall-the-gitlab-for-slack-app)した後にのみ、これらのパーミッションが付与されます。

## スラッシュコマンド {#slash-commands}

スラッシュコマンドを使用して、一般的なGitLabオペレーションを実行できます。

GitLab for Slackアプリの場合:

- 最初のスラッシュコマンドを実行するときに、Slackユーザーを承認する必要があります。
- `<project>`をプロジェクトのフルパスに置き換えるか、スラッシュコマンドの[プロジェクトエイリアスを作成](#create-a-project-alias)できます。

代わりに[Mattermostスラッシュコマンド](mattermost_slash_commands.md)を使用する場合:

- `/gitlab`を、これらのインテグレーション用に設定したトリガー名に置き換えます。
- `<project>`を削除します。

GitLabでは、次のスラッシュコマンドを使用できます。

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

GitLab for Slackアプリでスラッシュコマンドのプロジェクトエイリアスを作成するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **インテグレーション**を選択します。
1. **GitLab for Slackアプリ**を選択します。
1. プロジェクトのパスまたはエイリアスの横にある**編集**を選択します。
1. 新しいエイリアスを入力し、**変更を保存**を選択します。

Slackワークスペースでエイリアスの衝突が発生した場合（例: 複数のプロジェクトまたはグループが同じエイリアスを使用しようとする場合）、GitLabは以下の形式でフォールバックエイリアスを自動的に割り当てます:

- プロジェクトの場合: `p-<project_id>` （例: `p-12345`）
- グループの場合: `g-<group_id>` （例: `g-67890`）

優先エイリアスが利用できない場合、スラッシュコマンドでこれらのフォールバックエイリアスを使用できます。

## Slack通知 {#slack-notifications}

特定のGitLab[イベント](#notification-events)に関する通知をSlackチャンネルで受信できます。

### 通知を設定する {#configure-notifications}

Slack通知を設定するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **インテグレーション**を選択します。
1. **GitLab for Slackアプリ**を選択します。
1. **トリガー**セクションで、次のことを行います。
   - Slackで通知を受信するGitLab[イベント](#notification-events)ごとにチェックボックスをオンにします。
   - オンにしたチェックボックスごとに、通知を受信するSlackチャンネルの名前を入力します。コンマで区切られた最大10個のチャンネル名を入力できます（例: `#channel-one, #channel-two`）。

     > [!note]
     > Slackチャンネルがプライベートの場合、[GitLab for Slackアプリをチャンネルに追加](#receive-notifications-to-a-private-channel)する必要があります。

1. オプション。**通知設定**セクションで、次のことを行います。
   - **失敗したパイプラインのみを通知**チェックボックスをオンにして、失敗したパイプラインの通知のみを受信します。
   - **ステータス変更時のみ通知**チェックボックスを選択すると、refのパイプラインステータスが変更された場合のみ通知を受信します。
   - **通知を送信するブランチ**ドロップダウンリストから、通知を受信するブランチを選択します。

     これらのブランチから作成されたタグによってトリガーされたパイプラインについても通知が送信されます。

     脆弱性に関する通知は、選択したブランチに関係なく、デフォルトブランチによってのみトリガーされます。詳細については、[イシュー469373](https://gitlab.com/gitlab-org/gitlab/-/issues/469373)を参照してください。
   - **通知するラベル**には、通知を受信するためにGitLabイシュー、マージリクエスト、またはコメントが持つ必要のあるラベルの一部またはすべてを入力します。すべてのイベントの通知を受信するには、空白のままにします。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

### 非公開チャンネルへの通知を受信する {#receive-notifications-to-a-private-channel}

Slack非公開チャンネルへの通知を受信するには、次の手順に従って、GitLab for Slackアプリをチャンネルに追加する必要があります。

1. `@GitLab`を入力して、チャンネルでアプリをメンションします。
1. **チャンネルに追加**を選択します。

### 通知イベント {#notification-events}

次のGitLabイベントは、Slackで通知をトリガーできます。

| イベント                                                                 | 説明 |
| --------------------------------------------------------------------- | ----------- |
| プッシュ                                                                  | プッシュがリポジトリに対して行われます。 |
| イシュー                                                                 | 作業アイテムが作成、クローズ、または再オープンされました。 |
| 非公開のイシュー                                                    | 機密の作業アイテムが作成、クローズ、または再オープンされました。 |
| マージリクエスト                                                         | マージリクエストが作成、マージ、承認、クローズ、または再オープンされました。 |
| メモ                                                                  | コメントが追加されます。 |
| 非公開メモ                                                     | 機密の作業アイテムに内部メモまたはコメントが追加されました。 |
| タグのプッシュ                                                              | タグがリポジトリにプッシュされるか、削除されます。 |
| パイプライン                                                              | パイプラインの状態が変化します。 |
| Wikiページ                                                             | Wikiページが作成または更新されます。 |
| デプロイ                                                            | デプロイが開始または終了します。 |
| 公開の[グループメンション](#trigger-notifications-for-group-mentions)  | 公開チャンネルでグループがメンションされます。 |
| 非公開の[グループメンション](#trigger-notifications-for-group-mentions) | 非公開チャンネルでグループがメンションされます。 |
| [インシデント](../../../operations/incident_management/slack.md)          | インシデントが作成、クローズ、または再度オープンされます。 |
| [脆弱性](../../application_security/vulnerabilities/_index.md) | 新しい一意の脆弱性がデフォルトブランチに記録されます。 |
| アラート                                                                 | 新しい一意のアラートが記録されます。 |

### グループメンションの通知をトリガーする {#trigger-notifications-for-group-mentions}

{{< history >}}

- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803)になりました。機能フラグ`gitlab_for_slack_app_instance_and_group_level`は削除されました。

{{< /history >}}

グループメンションの[通知イベント](#notification-events)をトリガーするには、次の場所で`@<group_name>`を使用します。

- イシューとマージリクエストの説明
- イシュー、マージリクエスト、コミットのコメント
