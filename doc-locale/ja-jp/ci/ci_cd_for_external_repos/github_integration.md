---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: あなたのGitHubリポジトリをGitLab CI/CDに接続します。
title: GitHubリポジトリでGitLab CI/CDを使用する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab CI/CDは、**GitHub.com**および**GitHub Enterprise**で、あなたのGitHubリポジトリをGitLabに接続する[CI/CDプロジェクト](_index.md)を作成して使用できます。

<i class="fa-youtube-play" aria-hidden="true"></i> [GitHubリポジトリでGitLab CI/CDパイプラインを使用する](https://www.youtube.com/watch?v=qgl3F2j-1cI)の動画をご覧ください。

> [!note]
> [GitHubの制限](https://gitlab.com/gitlab-org/gitlab/-/issues/9147)により、外部のCI/CDリポジトリとしてGitHubと認証するために[GitHub OAuth](../../integration/github.md#enable-github-oauth-in-gitlab)を使用することはできません。

## パーソナルアクセストークンで接続 {#connect-with-personal-access-token}

パーソナルアクセストークンは、GitHub.comリポジトリをGitLabに接続するためにのみ使用でき、GitHubユーザーは[オーナーロール](https://docs.github.com/en/get-started/learning-about-github/access-permissions-on-github)を持っている必要があります。

GitHubで一度限りの認可を実行して、GitLabがリポジトリにアクセスできるようにするには:

1. GitHubで、トークンを作成します:
   1. <https://github.com/settings/tokens/new>を開きます。
   1. パーソナルアクセストークンを作成します。
   1. **トークンの説明**を入力し、スコープを`repo`と`admin:repo_hook`を許可するように更新して、GitLabがプロジェクトにアクセスし、コミットステータスを更新し、新しいコミットをGitLabに通知するWebhookを作成できるようにします。
1. GitLabで、プロジェクトを作成します:
   1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
   1. **外部リポジトリのCI/CDを実行**を選択します。
   1. **GitHub**を選択します。
   1. **パーソナルアクセストークン**に、トークンを貼り付けます。
   1. **List Repositories**を選択します。
   1. リポジトリを選択するために**接続**を選択します。
1. GitHubで、GitLab CI/CDを[設定](../quick_start/_index.md)するために`.gitlab-ci.yml`を追加します。

GitLab:

1. プロジェクトをインポートします。
1. [プルミラーリング](../../user/project/repository/mirror/pull.md)を有効にします。
1. [GitHubプロジェクトインテグレーション](../../user/project/integrations/github.md)を有効にします。
1. 新しいコミットをGitLabに通知するWebhookをGitHub上に作成します。

## 手動で接続 {#connect-manually}

**GitHub Enterprise**を**GitLab.com**で使用するには、この方法を使用します。

リポジトリでGitLab CI/CDを手動で有効にするには:

1. GitHubで、トークンを作成します:
   1. <https://github.com/settings/tokens/new>を開きます。
   1. パーソナルアクセストークンを作成します。
   1. **トークンの説明**を入力し、スコープを`repo`を許可するように更新して、GitLabがプロジェクトにアクセスし、コミットステータスを更新できるようにします。
1. GitLabで、プロジェクトを作成します:
   1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
   1. **外部リポジトリのCI/CDを実行**と**リポジトリのURL**を選択します。
   1. **GitリポジトリのURL**フィールドに、あなたのGitHubリポジトリのHTTPS URLを入力します。プロジェクトがプライベートな場合は、作成したばかりのパーソナルアクセストークンを認証に使用します。
   1. 他のすべてのフィールドに入力し、**プロジェクトを作成**を選択します。GitLabはポーリングベースのプルミラーリングを自動的に構成します。
1. GitLabで、[GitHubプロジェクトインテグレーション](../../user/project/integrations/github.md)を有効にします:
   1. 左サイドバーで、**設定** > **インテグレーション**を選択します。
   1. **有効**チェックボックスを選択します。
   1. あなたのパーソナルアクセストークンとHTTPSリポジトリURLをフォームに貼り付け、**保存**を選択します。
1. GitLabで、新しいコミットをGitLabに通知するGitHub Webhookを認証するために、`API`スコープを持つパーソナルアクセストークンを作成します。
1. GitHubで、**設定** > **Webhooks**から、新しいコミットをGitLabに通知するWebhookを作成します。

   Webhook URLは、作成したGitLabパーソナルアクセストークンを使用して、[プルミラーリングをトリガーする](../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)ためにGitLab APIに設定する必要があります:

   ```plaintext
   https://gitlab.com/api/v4/projects/<NAMESPACE>%2F<PROJECT>/mirror/pull?private_token=<PERSONAL_ACCESS_TOKEN>
   ```

   **Let me select individual events**オプションを選択し、**プルリクエスト**と**プッシュ**のチェックボックスをオンにします。これらの設定は、[外部プルリクエスト用のパイプライン](_index.md#pipelines-for-external-pull-requests)に必要です。

1. GitHubで、GitLab CI/CDを設定するために`.gitlab-ci.yml`を追加します。
