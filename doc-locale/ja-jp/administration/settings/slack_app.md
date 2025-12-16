---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab for Slackアプリの管理
description: "GitLab Self-Managedインスタンス上でGitLab for Slackアプリを管理、設定、および問題を解決するします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.2のGitLab Self-Managedで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/358872)されました。

{{< /history >}}

{{< alert type="note" >}}

このページには、GitLab for Slack appの管理者向けドキュメントが掲載されています。ユーザー向けドキュメントは、[GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md)を参照してください。

{{< /alert >}}

Slack App Directoryから配布されたGitLab for Slackアプリは、GitLab.comでのみ動作します。Self-Managedインスタンスでは、[マニフェストファイル](https://api.slack.com/reference/manifests#creating_apps)からGitLab for Slackアプリの独自のコピーを作成し、インスタンスを設定できます。

このアプリは、Slackワークスペースにのみインストールされるプライベートな1回限りのコピーであり、Slack App Directoryからは配布されません。Self-Managedインスタンスで[GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md)を使用するには、インテグレーションを有効にする必要があります。

## GitLab for Slackアプリを作成する {#create-a-gitlab-for-slack-app}

前提要件: 

- 少なくとも[Slackワークスペース管理者](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack)である必要があります。

GitLab for Slackアプリを作成するには:

- **GitLab全体で**:

  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **GitLab for Slack app**を展開します。
  1. **Slackアプリを作成**を選択します。

次の手順のためにSlackにリダイレクトされます。

- **Slackで**:

  1. アプリを作成するSlackワークスペースを選択し、**次へ**を選択します。
  1. Slackは、レビュー用にアプリのサマリーを表示します。完全なマニフェストを表示するには、**Edit Configurations**（構成を編集）を選択します。レビューの概要に戻るには、**次へ**を選択します。
  1. **作成**を選択します。
  1. **了解**を選択してダイアログを閉じます。
  1. **Install to Workspace**（ワークスペースにインストール）を選択します。

## 設定を構成する {#configure-the-settings}

[GitLab for Slackアプリを作成](#create-a-gitlab-for-slack-app)した後、GitLabで設定を構成できます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab for Slack app**を展開します。
1. **SlackアプリのためにGitLabを有効にする**チェックボックスを選択します。
1. GitLab for Slackアプリの詳細を入力します:
   1. [Slack API](https://api.slack.com/apps)にアクセスします。
   1. **GitLab (<your host name>)**（GitLab（<ホスト名>））を検索して選択します。
   1. **App Credentials**（アプリの認証情報）までスクロールします。
1. **変更を保存**を選択します。

### 設定をテストします {#test-your-configuration}

GitLab for Slackアプリの設定をテストするには:

1. Slackワークスペースのチャンネルに`/gitlab help`スラッシュコマンドを入力します。
1. <kbd>Enter</kbd>キーを押します。

利用可能なスラッシュコマンドのリストが表示されます。

プロジェクトでスラッシュコマンドを使用するには、プロジェクトの[GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md)を構成します。

## GitLab for Slackアプリをインストールする {#install-the-gitlab-for-slack-app}

{{< history >}}

- 特定のインスタンスのインストールは、GitLab 16.10で`gitlab_for_slack_app_instance_and_group_level`という名前の[フラグ付きで](../feature_flags/_index.md) [導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/391526)。デフォルトでは無効になっています。
- GitLab 16.11の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820)になりました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803)になりました。機能フラグ`gitlab_for_slack_app_instance_and_group_level`は削除されました。

{{< /history >}}

前提要件: 

- [Slackワークスペースにアプリを追加するための適切な権限](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)が必要です。
- [GitLab for Slackアプリを作成](#create-a-gitlab-for-slack-app)し、[アプリの設定を構成する](#configure-the-settings)必要があります。

インスタンス設定からGitLab for Slackアプリをインストールするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **インテグレーション**を選択します。
1. **GitLab for Slack app**を選択します。
1. **Slackアプリ用GitLabをインストール**を選択します。
1. Slackの確認ページで、**許可**を選択します。

## GitLab for Slack appをアップデートします {#update-the-gitlab-for-slack-app}

前提要件: 

- 少なくとも[Slackワークスペース管理者](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack)である必要があります。

GitLabがGitLab for Slackアプリの新しいリリースをリリースすると、新しい機能を使用するためにコピーを手動で更新する必要がある場合があります。

GitLab for Slackアプリのコピーを更新するには:

- **GitLab全体で**:

  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **GitLab for Slack app**を展開します。
  1. `slack_manifest.json`をダウンロードするには、**最新のマニフェストファイルをダウンロード**を選択します。

- **Slackで**:

  1. [Slack API](https://api.slack.com/apps)にアクセスします。
  1. **GitLab (<your host name>)**（GitLab（<ホスト名>））を検索して選択します。
  1. 左側のサイドバーで、**App Manifest**を選択します。
  1. **JSON**タブを選択して、マニフェストのJSONビューにスイッチします。
  1. GitLabからダウンロードした`slack_manifest.json`ファイルの内容をコピーします。
  1. 既存のコンテンツを置き換えるために、コンテンツをJSONビューアに貼り付けます。
  1. **変更を保存**を選択します。

## 接続要件 {#connectivity-requirements}

GitLab for Slackアプリの機能を有効にするには、ネットワーキングでGitLabとSlack間の受信および送信接続を許可する必要があります。

- [Slack通知](../../user/project/integrations/gitlab_slack_application.md#slack-notifications)の場合、GitLabインスタンスは`https://slack.com`にリクエストを送信できる必要があります。
- [スラッシュコマンド](../../user/project/integrations/gitlab_slack_application.md#slash-commands)およびその他の機能の場合、GitLabインスタンスは`https://slack.com`からリクエストを受信できる必要があります。

## 複数のワークスペースのサポートを有効にする {#enable-support-for-multiple-workspaces}

デフォルトでは、1つのSlackワークスペースにのみ[GitLab for Slackアプリをインストール](../../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)できます。管理者は、[GitLab for Slackアプリを作成](#create-a-gitlab-for-slack-app)するときに、このワークスペースを選択します。

複数のSlackワークスペースのサポートを有効にするには、GitLab for Slackアプリを[非掲載の分散アプリ](https://api.slack.com/distribution#unlisted-distributed-apps)として設定する必要があります。非掲載の分散アプリ:

- Slack App Directoryに公開されていません。
- 他のサイトではなく、GitLabインスタンスでのみ使用できます。

GitLab for Slackアプリを非掲載の分散アプリとして設定するには:

1. Slackの[**Your Apps**](https://api.slack.com/apps)ページにアクセスし、GitLab for Slackアプリを選択します。
1. **Manage Distribution**を選択します。
1. **Share Your App with Other Workspaces**セクションで、**Remove Hard Coded Information**を展開します。
1. **I've reviewed and removed any hard-coded information**チェックボックスを選択します。
1. **Activate Public Distribution**を選択します。

## トラブルシューティング {#troubleshooting}

GitLab for Slackアプリを管理する場合、次のイシューが発生する可能性があります。

ユーザー向けドキュメントは、[GitLab for Slack app](../../user/project/integrations/gitlab_slack_app_troubleshooting.md)を参照してください。

### スラッシュコマンドがSlackで`dispatch_failed`を返す {#slash-commands-return-dispatch_failed-in-slack}

スラッシュコマンドは、Slackで`/gitlab failed with the error "dispatch_failed"`を返す場合があります。

この問題を解決するには、以下を確認してください:

- GitLab for Slackアプリが適切に[設定されて](#configure-the-settings)おり、**SlackアプリのためにGitLabを有効にする**チェックボックスが選択されている。
- GitLabインスタンスが[Slackとの間でリクエストを許可して](#connectivity-requirements)います。
