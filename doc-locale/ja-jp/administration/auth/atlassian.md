---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AtlassianをOAuth 2.0の認証プロバイダーとして使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

パスワードなしの認証のためにAtlassianのOmniAuthプロバイダーを有効にするには、Atlassianにアプリケーションを登録する必要があります。

## Atlassianアプリケーション登録 {#atlassian-application-registration}

1. [Atlassian developer console](https://developer.atlassian.com/console/myapps/)にアクセスし、Atlassianアカウントでサインインしてアプリケーションを管理します。
1. **Create a new app**を選択します。
1. アプリ名（'GitLab'など）を選択し、**作成**を選択します。
1. [GitLab設定](#gitlab-configuration)の手順のために、`Client ID`と`Secret`を控えておきます。
1. 左サイドバーの**APIS AND FEATURES**の下にある、**OAuth 2.0 (3LO)**を選択します。
1. `https://gitlab.example.com/users/auth/atlassian_oauth2/callback`の形式を使用してGitLabコールバックURLを入力し、**変更を保存**を選択します。
1. 左サイドバーの**APIS AND FEATURES**の下にある**\+ Add**を選択します。
1. **Jira platform REST API**に対して**追加**を選択し、次に**設定する**を選択します。
1. 次のスコープの横にある**追加**を選択します:
   - **View Jira issue data**
   - **View user profiles**
   - **Create and manage issues**

## GitLab設定 {#gitlab-configuration}

1. GitLabサーバーで、設定ファイルを開きます:

   Linuxパッケージインストールの場合:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   自己コンパイルによるインストールの場合:

   ```shell
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. [共通設定](../../integration/omniauth.md#configure-common-settings)で、`atlassian_oauth2`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。
1. Atlassianのプロバイダー設定を追加します:

   Linuxパッケージインストールの場合:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "atlassian_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Atlassian"
       app_id: "<your_client_id>",
       app_secret: "<your_client_secret>",
       args: { scope: "offline_access read:jira-user read:jira-work", prompt: "consent" }
     }
   ]
   ```

   自己コンパイルによるインストールの場合:

   ```yaml
   - { name: "atlassian_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Atlassian"
       app_id: "<your_client_id>",
       app_secret: "<your_client_secret>",
       args: { scope: "offline_access read:jira-user read:jira-work", prompt: "consent" }
    }
   ```

1. [アプリケーション登録](#atlassian-application-registration)中に受け取ったクライアント認証情報に`<your_client_id>`と`<your_client_secret>`を変更します。
1. 設定ファイルを保存します。

1. 変更を有効にするには:
   - Linuxパッケージを使用してインストールした場合は、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
   - インストールを自己コンパイルした場合は、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

サインインページには、通常のサインインフォームの下にAtlassianアイコンが表示されるはずです。そのアイコンを選択すると、認証プロセスが開始されます。

すべてがうまくいけば、ユーザーは自分のAtlassian認証情報を使用してGitLabにサインインされます。
