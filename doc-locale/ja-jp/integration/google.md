---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google OAuth 2.0をOAuth 2.0認証プロバイダーとして使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Google OAuth 2.0 OmniAuthプロバイダーを有効にするには、アプリケーションをGoogleに登録する必要があります。Googleは、使用するクライアントIDとシークレットキーを生成します。

Google OAuthを有効にするには、以下を構成する必要があります:

- Google Cloud Resource Manager
- Google API Console
- GitLabサーバー

## Google Cloud Resource Managerを設定する {#configure-the-google-cloud-resource-manager}

1. [Google Cloud Resource Manager](https://console.cloud.google.com/cloud-resource-manager)に移動します。
1. **CREATE PROJECT**（プロジェクトを作成）を選択します。
1. **Project name**（プロジェクト名）に、`GitLab`と入力します。
1. **Project ID**（プロジェクトID）に、Googleがランダムに生成したプロジェクトIDがデフォルトで表示されます。このランダムに生成されたIDを使用するか、新しいIDを作成できます。新しいIDを作成する場合、すべてのGoogleデベロッパー登録済みアプリケーションに対して一意である必要があります。

リストに新しいプロジェクトを表示するには、ページを更新してください。

## Google API Consoleを設定する {#configure-the-google-api-console}

1. [Google API Console](https://console.developers.google.com/apis/dashboard)に移動します。
1. 左上隅で、以前に作成したプロジェクトを選択します。
1. **OAuth consent screen**（OAuth同意画面）を選択し、フィールドに入力します。
1. **Credentials**（認証情報） > **Create credentials**（認証情報を作成） > **OAuth client ID**（OAuthクライアントID）を選択します。
1. フィールドに入力します:
   - **Application type**（アプリケーションの種類）: **Web application**（ウェブアプリケーション）を選択します。
   - **名前**: デフォルト名を使用するか、独自の名前を入力します。
   - **Authorized JavaScript origins**（許可されたJavaScriptオリジン）: `https://gitlab.example.com`を入力します。
   - **Authorized redirect URIs**（許可されたリダイレクトURI）: ドメイン名の後に、コールバックURIを1つずつ入力します:

     ```plaintext
     https://gitlab.example.com/users/auth/google_oauth2/callback
     https://gitlab.example.com/-/google_api/auth/callback
     ```

1. クライアントIDとクライアントシークレットが表示されます。それらを書き留めるか、後で必要になるため、このページを開いたままにしてください。
1. プロジェクトが[Google Kubernetes Engine](../user/infrastructure/clusters/_index.md)にアクセスできるようにするには、以下も有効にする必要があります:
   - Google Kubernetes Engine
   - Cloud Resource Manager API
   - Cloud Billing API

   これを行うには、次の手順に従います:

   1. [Google API Console](https://console.developers.google.com/apis/dashboard)に移動します。
   1. ページの上部にある**ENABLE APIS AND SERVICES**（APISとサービスを有効にする）を選択します。
   1. 前に述べた各APIを見つけます。APIのページで、**ENABLE**（有効にする）を選択します。APIが完全に機能するまでに数分かかる場合があります。

## GitLabサーバーを設定する {#configure-the-gitlab-server}

1. 設定ファイルを開きます。

   Linuxパッケージインストールの場合:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   自己コンパイルによるインストールの場合:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. [共通設定](omniauth.md#configure-common-settings)で、`google_oauth2`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。
1. プロバイダー設定を追加します。

   Linuxパッケージインストールの場合:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "google_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Google"
       app_id: "<YOUR_APP_ID>",
       app_secret: "<YOUR_APP_SECRET>",
       args: { access_type: "offline", approval_prompt: "" }
     }
   ]
   ```

   自己コンパイルによるインストールの場合:

   ```yaml
   - { name: 'google_oauth2',
       # label: 'Provider name', # optional label for login button, defaults to "Google"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { access_type: 'offline', approval_prompt: '' } }
   ```

1. `<YOUR_APP_ID>`をGoogleデベロッパーページのクライアントIDに置き換えます。
1. `<YOUR_APP_SECRET>`をGoogleデベロッパーページのクライアントシークレットに置き換えます。
1. Googleはraw IPアドレスを受け入れないため、完全修飾ドメイン名を使用するようにGitLabを設定してください。

   Linuxパッケージインストールの場合:

   ```ruby
   external_url 'https://gitlab.example.com'
   ```

   自己コンパイルによるインストールの場合:

   ```yaml
   gitlab:
     host: https://gitlab.example.com
   ```

1. 設定ファイルを保存します。
1. 変更を有効にするには:
   - Linuxパッケージを使用してインストールした場合は、[GitLabを再構成](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)します。
   - GitLabインストールを自分でコンパイルした場合は、[GitLab](../administration/restart_gitlab.md#self-compiled-installations)を再起動してください。

サインインページに、通常のサインインフォームの下にGoogleアイコンが表示されるはずです。そのアイコンを選択すると、認証プロセスが開始されます。Googleは、ユーザーにサインインを求め、GitLabアプリケーションを承認するように求めます。すべてがうまくいけば、ユーザーはGitLabに戻り、サインインします。
