---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab for Slackアプリの管理
description: "GitLab Self-ManagedインスタンスでGitLab for Slackアプリの管理、設定、トラブルシューティングを行います。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.2のGitLab Self-Managedで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/358872)されました。

{{< /history >}}

> [!note]
> このページには、GitLab for Slackアプリの管理者向けドキュメントが掲載されています。ユーザー向けドキュメントについては、[GitLab for Slackアプリ](../../user/project/integrations/gitlab_slack_application.md)を参照してください。

Slack App Directoryを通じて配布されているGitLab for Slackアプリは、GitLab.comでのみ動作します。GitLab Self-Managedでは、[マニフェストファイル](https://api.slack.com/reference/manifests#creating_apps)からGitLab for Slackアプリのコピーを独自に作成し、インスタンスを設定できます。

このアプリケーションは、Slackワークスペースにのみインストールされるプライベートな1回限りのコピーであり、Slack App Directoryで配布されるものではありません。GitLab Self-Managedインスタンスで[GitLab for Slackアプリ](../../user/project/integrations/gitlab_slack_application.md)を使用するには、インテグレーションを有効にする必要があります。

## GitLab for Slackアプリを作成する {#create-a-gitlab-for-slack-app}

前提条件: 

- 少なくとも[Slackワークスペース管理者](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack)である必要があります。

GitLab for Slackアプリを作成するには:

- **GitLab**で、次の手順に従います:

  1. 右上隅で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **GitLab for Slackアプリ**を展開します。
  1. **Slackアプリを作成**を選択します。

次の手順のため、Slackにリダイレクトされます。

- **Slack**で、次の手順に従います:

  1. アプリを作成するSlackワークスペースを選択し、**Next**を選択します。
  1. Slackに確認用のアプリの概要が表示されます。マニフェスト全体を確認するには、**Edit Configurations**を選択します。確認用の概要に戻るには、**Next**を選択します。
  1. **Create**を選択します。
  1. ダイアログを閉じるために**Got it**を選択します。
  1. **Install to Workspace**を選択します。

## 設定する {#configure-the-settings}

[GitLab for Slackアプリを作成](#create-a-gitlab-for-slack-app)したら、GitLabで設定を行えます:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab for Slackアプリ**を展開します。
1. **GitLab for Slackを有効にする**チェックボックスをオンにします。
1. GitLab for Slackアプリの詳細を入力します:
   1. [Slack API](https://api.slack.com/apps)に移動します。
   1. **GitLab（`<your host name>`）**を検索して選択します。
   1. **アプリの認証情報**までスクロールします。
1. **変更を保存**を選択します。

## GitLab for Slackアプリをインストールする {#install-the-gitlab-for-slack-app}

{{< history >}}

- GitLab 16.10で特定のインスタンス向けのインストールが`gitlab_for_slack_app_instance_and_group_level`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391526)されました。デフォルトでは無効になっています。
- GitLab 16.11の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820)になりました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803)になりました。機能フラグ`gitlab_for_slack_app_instance_and_group_level`は削除されました。

{{< /history >}}

前提条件: 

- [Slackワークスペースにアプリを追加するための適切な権限](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)が必要です。
- [GitLab for Slackアプリ](#create-a-gitlab-for-slack-app)を作成し、[アプリの設定](#configure-the-settings)を完了している必要があります。

インスタンスの設定からGitLab for Slackアプリをインストールするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **インテグレーション**を選択します。
1. **GitLab for Slackアプリ**を選択します。
1. **GitLab for Slackアプリをインストール**を選択します。
1. Slackの確認ページで、**許可**を選択します。

### 設定をテストする {#test-your-configuration}

GitLab for Slackアプリの設定をテストするには:

1. Slackワークスペースのチャンネルで、スラッシュコマンド`/gitlab help`を入力します。
1. <kbd>Enter</kbd>キーを押します。

利用可能なスラッシュコマンドのリストが表示されます。

プロジェクトでスラッシュコマンドを使用するには、そのプロジェクト向けに[GitLab for Slackアプリ](../../user/project/integrations/gitlab_slack_application.md)を設定します。

## GitLab for Slackアプリを更新する {#update-the-gitlab-for-slack-app}

前提条件: 

- 少なくとも[Slackワークスペース管理者](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack)である必要があります。

GitLabがGitLab for Slackアプリの新機能をリリースした場合、その新機能を使用するには、ご利用のコピーを手動で更新する必要がある場合があります。

GitLab for Slackアプリのコピーを更新するには:

- **GitLab**で、次の手順に従います:

  1. 右上隅で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **GitLab for Slackアプリ**を展開します。
  1. **最新のマニフェストファイルをダウンロード**を選択して、`slack_manifest.json`をダウンロードします。

- **Slack**で、次の手順に従います:

  1. [Slack API](https://api.slack.com/apps)に移動します。
  1. **GitLab（`<your host name>`）**を検索して選択します。
  1. 左側のサイドバーで、**App Manifest**を選択します。
  1. **JSON**タブを選択して、マニフェストのJSONビューに切り替えます。
  1. GitLabからダウンロードした`slack_manifest.json`ファイルの内容をコピーします。
  1. コピーした内容をJSONビューアに貼り付けて、既存の内容を置き換えます。
  1. **変更を保存**を選択します。

## 接続要件 {#connectivity-requirements}

GitLab for Slackアプリの機能を有効にするには、ネットワークがGitLabとSlack間の受信接続と送信接続を許可している必要があります。

- [Slack通知](../../user/project/integrations/gitlab_slack_application.md#slack-notifications)の場合、GitLabインスタンスは、`https://slack.com`にリクエストを送信できる必要があります。
- [スラッシュコマンド](../../user/project/integrations/gitlab_slack_application.md#slash-commands)やその他の機能の場合、GitLabインスタンスは、`https://slack.com`からのリクエストを受信できる必要があります。

## 複数のワークスペースのサポートを有効にする {#enable-support-for-multiple-workspaces}

デフォルトでは、[GitLab for Slackアプリをインストール](../../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)できるのは1つのSlackワークスペースのみです。管理者は、[GitLab for Slackアプリを作成](#create-a-gitlab-for-slack-app)する際に、このワークスペースを選択します。

複数のSlackワークスペースのサポートを有効にするには、GitLab for Slackアプリを[非掲載の配布アプリ](https://api.slack.com/distribution#unlisted-distributed-apps)として設定する必要があります。非掲載の配布アプリには次の特徴があります:

- Slack App Directoryには公開されません。
- お使いのGitLabインスタンスでのみ使用でき、他のサイトでは使用できません。

GitLab for Slackアプリを非掲載の配布アプリとして設定するには:

1. Slackの[**Your Apps**](https://api.slack.com/apps)ページに移動し、GitLab for Slackアプリを選択します。
1. **Manage Distribution**を選択します。
1. **Share Your App with Other Workspaces**セクションで、**Remove Hard Coded Information**を展開します。
1. **I've reviewed and removed any hard-coded information**チェックボックスをオンにします。
1. **Activate Public Distribution**を選択します。

## トラブルシューティング {#troubleshooting}

GitLab for Slackアプリを管理する際、次の問題が発生する可能性があります。

ユーザー向けドキュメントについては、[GitLab for Slackアプリ](../../user/project/integrations/gitlab_slack_app_troubleshooting.md)を参照してください。

### Slackでスラッシュコマンドが`dispatch_failed`を返す {#slash-commands-return-dispatch_failed-in-slack}

Slackでスラッシュコマンドが`/gitlab failed with the error "dispatch_failed"`を返す場合があります。

この問題を解決するには、次の点を確認してください:

- GitLab for Slackアプリが適切に[設定](#configure-the-settings)され、**GitLab for Slackアプリを有効にする**チェックボックスがオンになっている。
- GitLabインスタンスが[Slackとの間でリクエストの送受信を許可](#connectivity-requirements)している。
