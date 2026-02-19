---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab for Slackアプリケーションの管理
description: "GitLab Self-ManagedインスタンスでGitLab for Slackアプリケーションを管理、設定、トラブルシューティングを行う。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.2のGitLab Self-Managedで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/358872)されました。

{{< /history >}}

> [!note]このページでは、GitLab for Slackアプリケーションの管理者向けドキュメントを提供します。ユーザー向けドキュメントについては、[GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md)を参照してください。

Slackアプリケーションディレクトリを通じて配布されるGitLab for Slackアプリケーションは、GitLab.comでのみ動作します。GitLab Self-Managedインスタンスでは、[マニフェストファイル](https://api.slack.com/reference/manifests#creating_apps)からGitLab for Slackアプリケーション独自のコピーを作成し、インスタンスを設定できます。

このアプリケーションは、Slackワークスペースにのみインストールされるプライベートな1回限りのコピーであり、Slackアプリケーションディレクトリを通じて配布されるものではありません。GitLab Self-Managedインスタンスで[GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md)を使用するには、インテグレーションを有効にする必要があります。

## Slackアプリケーションを作成する {#create-a-gitlab-for-slack-app}

前提条件: 

- [Slackワークスペース管理者](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack)以上である必要があります。

GitLab for Slackアプリケーションを作成するには:

- **GitLabの場合**:

  1. 右上隅で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **GitLab for Slack app**を展開します。
  1. **Slackアプリを作成**を選択します。

次の手順のためにSlackにリダイレクトされます。

- **In Slack**:

  1. アプリケーションの作成先のSlackワークスペースを選択し、**Next**を選択します。
  1. Slackにレビュー用のアプリケーションの概要が表示されます。マニフェスト全体を表示するには、**Edit Configurations**を選択します。レビューの概要に戻るには、**Next**を選択します。
  1. **Create**を選択します。
  1. **了解**を選択してダイアログを閉じます。
  1. **Install to Workspace**を選択します。

## 設定を設定する {#configure-the-settings}

[GitLab for Slack app](#create-a-gitlab-for-slack-app)を作成したら、GitLabで設定を設定できます:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab for Slack app**を展開します。
1. **SlackアプリのためにGitLabを有効にする**チェックボックスを選択します。
1. GitLab for Slackアプリケーションの詳細を入力します:
   1. [Slack API](https://api.slack.com/apps)に移動します。
   1. **GitLab（`<your host name>`）**を検索して選択します。
   1. **App Credentials**までスクロールします。
1. **変更を保存**を選択します。

## GitLab for Slackアプリをインストールする {#install-the-gitlab-for-slack-app}

{{< history >}}

- 特定のインスタンスのインストールは、`gitlab_for_slack_app_instance_and_group_level`という名前の[フラグ](../feature_flags/_index.md)でGitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391526)されました。デフォルトでは無効になっています。
- GitLab 16.11の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820)になりました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803)になりました。機能フラグ`gitlab_for_slack_app_instance_and_group_level`は削除されました。

{{< /history >}}

前提条件: 

- [Slackワークスペースにアプリを追加するための適切な権限](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)が必要です。
- [GitLab for Slack app](#create-a-gitlab-for-slack-app)を作成し、[アプリの設定を設定する](#configure-the-settings)必要があります。

インスタンスの設定からGitLab for Slackアプリケーションをインストールするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **インテグレーション**を選択します。
1. **GitLab for Slackアプリ**を選択します。
1. **GitLab for Slackアプリをインストール**を選択します。
1. Slackの確認ページで、**許可**を選択します。

### 構成をテストする {#test-your-configuration}

GitLab for Slackアプリケーションの構成をテストするには:

1. Slackワークスペースのチャンネルに`/gitlab help`スラッシュコマンドを入力します。
1. <kbd>Enter</kbd>キーを押します。

使用可能なスラッシュコマンドのリストが表示されます。

プロジェクトでスラッシュコマンドを使用するには、プロジェクトの[GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md)を設定します。

## GitLab for Slackアプリケーションを更新する {#update-the-gitlab-for-slack-app}

前提条件: 

- [Slackワークスペース管理者](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack)以上である必要があります。

GitLabがGitLab for Slackアプリケーションの新機能をリリースすると、新しい機能を使用するために、コピーを手動で更新する必要がある場合があります。

GitLab for Slackアプリケーションのコピーを更新するには:

- **GitLabの場合**:

  1. 右上隅で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **GitLab for Slack app**を展開します。
  1. `slack_manifest.json`をダウンロードするには、**最新のマニフェストファイルをダウンロード**を選択します。

- **In Slack**:

  1. [Slack API](https://api.slack.com/apps)に移動します。
  1. **GitLab（`<your host name>`）**を検索して選択します。
  1. 左側のサイドバーで、**App Manifest**を選択します。
  1. マニフェストのJSONビューに切り替えるには、**JSON**タブを選択します。
  1. GitLabからダウンロードした`slack_manifest.json`ファイルの内容をコピーします。
  1. JSONビューアーに内容を貼り付けて、既存の内容を置き換えます。
  1. **変更を保存**を選択します。

## 接続要件 {#connectivity-requirements}

GitLab for Slackアプリケーションの機能を有効にするには、ネットワークがGitLabとSlack間の受信接続と送信接続を許可する必要があります。

- [Slack notifications](../../user/project/integrations/gitlab_slack_application.md#slack-notifications)の場合、GitLabインスタンスは、`https://slack.com`にリクエストを送信できる必要があります。
- [Slash commands](../../user/project/integrations/gitlab_slack_application.md#slash-commands)およびその他の機能の場合、GitLabインスタンスは、`https://slack.com`からリクエストを受信できる必要があります。

## 複数のワークスペースのサポートを有効にする {#enable-support-for-multiple-workspaces}

デフォルトでは、1つのSlackワークスペースにのみ[GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)をインストールできます。管理者は、[Slackアプリケーション用にGitLabを作成](#create-a-gitlab-for-slack-app)するときに、このワークスペースを選択します。

複数のSlackワークスペースのサポートを有効にするには、GitLab for Slackアプリケーションを[非リリースの分散型アプリケーション](https://api.slack.com/distribution#unlisted-distributed-apps)として設定する必要があります。非リリースの分散型アプリケーション:

- Slackアプリケーションディレクトリに公開されていません。
- お使いのGitLabインスタンスでのみ使用でき、他のサイトでは使用できません。

GitLab for Slackアプリケーションを非リリースの分散型アプリケーションとして設定するには:

1. Slackの[**Your Apps**](https://api.slack.com/apps)ページに移動し、GitLab for Slackアプリケーションを選択します。
1. **Manage Distribution**を選択します。
1. **Share Your App with Other Workspaces**セクションで、**Remove Hard Coded Information**を展開します。
1. **I've reviewed and removed any hard-coded information**チェックボックスを選択します。
1. **Activate Public Distribution**を選択します。

## トラブルシューティング {#troubleshooting}

GitLab for Slackアプリケーションを管理する場合、次のイシューが発生する可能性があります。

ユーザー向けドキュメントについては、[GitLab for Slack app](../../user/project/integrations/gitlab_slack_app_troubleshooting.md)を参照してください。

### スラッシュコマンドがSlackで`dispatch_failed`を返す {#slash-commands-return-dispatch_failed-in-slack}

スラッシュコマンドがSlackで`/gitlab failed with the error "dispatch_failed"`を返す場合があります。

このイシューを解決するには、以下を確認してください:

- GitLab for Slackアプリケーションが適切に[構成](#configure-the-settings)され、**SlackアプリのためにGitLabを有効にする**チェックボックスがオンになっている。
- GitLabインスタンスが[Slackとの間でリクエストを許可している](#connectivity-requirements)。
