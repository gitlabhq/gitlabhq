---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitHubリポジトリをGitLab CI/CDに接続します。
title: GitHubリポジトリでGitLab CI/CDを使用する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab CI/CDは、**GitHub.com**および**GitHub Enterprise**で、[CI/CDプロジェクト](_index.md)を作成して、GitHubリポジトリをGitLabに接続することで使用できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitHubリポジトリでGitLab CI/CDパイプラインを使用する](https://www.youtube.com/watch?v=qgl3F2j-1cI)のビデオをご覧ください。

{{< alert type="note" >}}

[GitHubの制限事項](https://gitlab.com/gitlab-org/gitlab/-/issues/9147)により、外部CI/CDリポジトリとして[GitHub OAuth](../../integration/github.md#enable-github-oauth-in-gitlab)を使用してGitHubで認証することはできません。

{{< /alert >}}

## パーソナルアクセストークンで接続 {#connect-with-personal-access-token}

パーソナルアクセストークンは、GitHub.comリポジトリをGitLabに接続するためにのみ使用でき、GitHubユーザーは[オーナー](https://docs.github.com/en/get-started/learning-about-github/access-permissions-on-github)ロールを持っている必要があります。

GitHubで1回限りの認可を実行して、GitLabにリポジトリへのアクセスを許可するには、次の手順に従います:

1. GitHubで、トークンを作成します:
   1. <https://github.com/settings/tokens/new>を開きます。
   1. パーソナルアクセストークンを作成します。
   1. **トークンの説明**を入力し、`repo`と`admin:repo_hook`を許可するようにスコープを更新して、GitLabがプロジェクトにアクセスし、コミットステータスを更新し、新しいコミットをGitLabに通知するWebhookを作成できるようにします。
1. GitLabで、プロジェクトを作成します:
   1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
   1. **外部リポジトリのCI/CDを実行**を選択します。
   1. **GitHub**を選択します。
   1. **パーソナルアクセストークン**には、トークンを貼り付けます。
   1. **List Repositories**（リポジトリ一覧）を選択します。
   1. **接続**を選択して、リポジトリを選択します。
1. GitHubで、`.gitlab-ci.yml`を追加して、[GitLab CI/CDを構成](../quick_start/_index.md)します。

GitLab:

1. プロジェクトをインポートします。
1. [プルミラーリング](../../user/project/repository/mirror/pull.md)を有効にします。
1. [GitHubプロジェクトインテグレーション](../../user/project/integrations/github.md)を有効にします。
1. GitHubにWebhookを作成して、新しいコミットをGitLabに通知します。

## 手動で接続 {#connect-manually}

**GitHub Enterprise**を**GitLab.com**で使用するには、この方法を使用します。

リポジトリのGitLab CI/CDを手動で有効にするには、次の手順に従います:

1. GitHubで、トークンを作成します:
   1. <https://github.com/settings/tokens/new>を開きます。
   1. パーソナルアクセストークンを作成します。
   1. **トークンの説明**を入力し、`repo`を許可するようにスコープを更新して、GitLabがプロジェクトにアクセスし、コミットステータスを更新できるようにします。
1. GitLabで、プロジェクトを作成します:
   1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
   1. **外部リポジトリのCI/CDを実行**と**リポジトリのURL**を選択します。
   1. **GitリポジトリのURL**フィールドに、GitHubリポジトリのHTTPS URLを入力します。プロジェクトがプライベートの場合は、作成したばかりのパーソナルアクセストークンを認証に使用します。
   1. 他のすべてのフィールドに入力し、**プロジェクトを作成**を選択します。GitLabは、ポーリングベースのプルミラーリングを自動的に構成します。
1. GitLabで、[GitHubプロジェクトインテグレーション](../../user/project/integrations/github.md)を有効にします:
   1. 左側のサイドバーで、**設定** > **インテグレーション**を選択します。
   1. **有効**チェックボックスを選択します。
   1. パーソナルアクセストークンとHTTPSリポジトリのURLをフォームに貼り付け、**保存**を選択します。
1. GitLabで、`API`スコープのパーソナルアクセストークンを作成して、新しいコミットをGitLabに通知するGitHub Webhookを認証します。
1. GitHubで、**設定** > **Webhooks**から、新しいコミットをGitLabに通知するWebhookを作成します。

   Webhook URLは、GitLabパーソナルアクセストークンを使用して、GitLab APIに設定し、[プルミラーリングをトリガーする](../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)必要があります:

   ```plaintext
   https://gitlab.com/api/v4/projects/<NAMESPACE>%2F<PROJECT>/mirror/pull?private_token=<PERSONAL_ACCESS_TOKEN>
   ```

   **Let me select individual events**（個別のイベントを選択させてください）オプションを選択し、**プルリクエスト**チェックボックスと**プッシュ**チェックボックスをオンにします。これらの設定は、[外部プルリクエストのパイプライン](_index.md#pipelines-for-external-pull-requests)に必要です。

1. GitHubで、`.gitlab-ci.yml`を追加して、GitLab CI/CDを構成します。
