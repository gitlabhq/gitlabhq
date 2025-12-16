---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitHubをOAuth 2.0認証プロバイダーとして使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabインスタンスをGitHub.comおよびGitHub Enterpriseとインテグレーションできます。GitHubからプロジェクトをインポートしたり、GitHubの認証情報を使用してGitLabにサインインしたりできます。

## GitHubでOAuthアプリを作成します。 {#create-an-oauth-app-in-github}

GitHub OmniAuthプロバイダーを有効にするには、GitHubからのOAuth 2.0クライアントIDとクライアントのシークレットキーが必要です:

1. GitHubにサインインします。
1. [OAuthアプリを作成](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app)し、次の情報を入力します:
   - `https://gitlab.example.com`などのGitLabインスタンスのURL。
   - `https://gitlab.example.com/users/auth`などの認可コールバックURL。GitLabインスタンスがデフォルト以外のポートを使用している場合は、ポート番号を含めます。

### セキュリティの脆弱性をチェック {#check-for-security-vulnerabilities}

一部のインテグレーションでは、[OAuth 2 covert redirect](https://oauth.net/advisories/2014-1-covert-redirect/)の脆弱性により、GitLabアカウントが侵害される可能性があります。この脆弱性を軽減するには、`/users/auth`を認可コールバックURLに追加します。

ただし、GitHubは`redirect_uri`のサブドメイン部分を検証しません。したがって、Webサイトのサブドメインのサブドメインの乗っ取り、XSS、またはオープンリダイレクトにより、covert redirect攻撃が可能になる可能性があります。

## GitLabでGitHub OAuthを有効にする {#enable-github-oauth-in-gitlab}

1. [共通設定](omniauth.md#configure-common-settings)で、`github`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。

1. 次の情報を使用して、GitLabの設定ファイルを編集します:

   | GitHubの設定 | GitLabの設定ファイルの値 | 説明             |
   |----------------|----------------------------------------|-------------------------|
   | Client ID（クライアントID）      | `YOUR_APP_ID`                          | OAuth 2.0クライアントID     |
   | クライアントシークレット  | `YOUR_APP_SECRET`                      | OAuth 2.0クライアントシークレット |
   | URL            | `https://github.example.com/`          | GitHubデプロイURL   |

   - Linuxパッケージインストールの場合:

     1. `/etc/gitlab/gitlab.rb`ファイルを開きます。

        GitHub.comの場合は、次のセクションを更新します:

        ```ruby
        gitlab_rails['omniauth_providers'] = [
          {
            name: "github",
            # label: "Provider name", # optional label for login button, defaults to "GitHub"
            app_id: "YOUR_APP_ID",
            app_secret: "YOUR_APP_SECRET",
            args: { scope: "user:email" }
          }
        ]
        ```

        GitHub Enterpriseの場合は、次のセクションを更新し、`https://github.example.com/`をGitHubのURLに置き換えます:

        ```ruby
        gitlab_rails['omniauth_providers'] = [
          {
            name: "github",
            # label: "Provider name", # optional label for login button, defaults to "GitHub"
            app_id: "YOUR_APP_ID",
            app_secret: "YOUR_APP_SECRET",
            url: "https://github.example.com/",
            args: { scope: "user:email" }
          }
        ]
        ```

     1. ファイルを保存して、GitLabを[再構成](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)します。

   - 自己コンパイルによるインストールの場合: 

     1. `config/gitlab.yml`ファイルを開きます。

        GitHub.comの場合は、次のセクションを更新します:

        ```yaml
        - { name: 'github',
            # label: 'Provider name', # optional label for login button, defaults to "GitHub"
            app_id: 'YOUR_APP_ID',
            app_secret: 'YOUR_APP_SECRET',
            args: { scope: 'user:email' } }
        ```

        GitHub Enterpriseの場合は、次のセクションを更新し、`https://github.example.com/`をGitHubのURLに置き換えます:

        ```yaml
        - { name: 'github',
            # label: 'Provider name', # optional label for login button, defaults to "GitHub"
            app_id: 'YOUR_APP_ID',
            app_secret: 'YOUR_APP_SECRET',
            url: "https://github.example.com/",
            args: { scope: 'user:email' } }
        ```

     1. ファイルを保存して、GitLabを[再起動](../administration/restart_gitlab.md#self-compiled-installations)します。

1. GitLabのサインインページを更新します。GitHubアイコンがサインインフォームの下に表示されます。

1. アイコンを選択します。GitHubにサインインして、GitLabアプリケーションを認可します。

## トラブルシューティング {#troubleshooting}

### GitHub Enterpriseから自己署名SSL証明書を使用したインポートに失敗する {#imports-from-github-enterprise-with-a-self-signed-certificate-fail}

自己署名証明書を使用してGitHub Enterpriseからプロジェクトをインポートすると、インポートが失敗します。

このイシューを修正するには、SSL検証を無効にする必要があります:

1. 設定ファイルで`verify_ssl`を`false`に設定します。

   - Linuxパッケージインストールの場合:

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         name: "github",
         # label: "Provider name", # optional label for login button, defaults to "GitHub"
         app_id: "YOUR_APP_ID",
         app_secret: "YOUR_APP_SECRET",
         url: "https://github.example.com/",
         verify_ssl: false,
         args: { scope: "user:email" }
       }
     ]
     ```

   - 自己コンパイルによるインストールの場合: 

     ```yaml
     - { name: 'github',
         # label: 'Provider name', # optional label for login button, defaults to "GitHub"
         app_id: 'YOUR_APP_ID',
         app_secret: 'YOUR_APP_SECRET',
         url: "https://github.example.com/",
         verify_ssl: false,
         args: { scope: 'user:email' } }
     ```

1. GitLabサーバーで、グローバルGit `sslVerify`オプションを`false`に変更します。

   - [GitLab 15.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6800)以降を実行しているLinuxパッケージインストールの場合:

     ```ruby
     gitaly['gitconfig'] = [
        {key: "http.sslVerify", value: "false"},
     ]
     ```

   - GitLab 15.2以前（レガシーメソッド）を実行しているLinuxパッケージインストールの場合:

     ```ruby
     omnibus_gitconfig['system'] = { "http" => ["sslVerify = false"] }
     ```

   - [GitLab 15.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6800)以降を実行しているセルフコンパイルインストールの場合は、Gitaly設定（`gitaly.toml`）を編集します:

     ```toml
     [[git.config]]
     key = "http.sslVerify"
     value = "false"
     ```

   - GitLab 15.2以前（レガシーメソッド）を実行しているセルフコンパイルインストールの場合:

     ```shell
     git config --global http.sslVerify false
     ```

1. Linuxパッケージを使用してインストールした場合は、[GitLabを再構成](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)するか、セルフコンパイルインストールした場合は、[GitLabを再起動](../administration/restart_gitlab.md#self-compiled-installations)します。

### GitHub Enterpriseを使用したサインインで500エラーが返される {#signing-in-using-github-enterprise-returns-a-500-error}

このエラーは、GitLabインスタンスとGitHub Enterprise間のネットワーク接続の問題が原因で発生する可能性があります。

接続のイシューを確認するには:

1. GitLabサーバーの[`production.log`](../administration/logs/_index.md#productionlog)に移動し、次のエラーを探します:

   ``` plaintext
   Faraday::ConnectionFailed (execution expired)
   ```

1. [Railsコンソールを起動](../administration/operations/rails_console.md#starting-a-rails-console-session)し、次のコマンドを実行します。`<github_url>`をGitHub EnterpriseインスタンスのURLに置き換えます:

   ```ruby
   uri = URI.parse("https://<github_url>") # replace `GitHub-URL` with the real one here
   http = Net::HTTP.new(uri.host, uri.port)
   http.use_ssl = true
   http.verify_mode = 1
   response = http.request(Net::HTTP::Get.new(uri.request_uri))
   ```

1. 同様の`execution expired`エラーが返された場合、これは、エラーが接続のイシューによって発生したことを確認します。GitLabサーバーがGitHub Enterpriseインスタンスに到達できることを確認してください。

### 既存のGitLabアカウントがないGitHubアカウントを使用してサインインすることは許可されていません {#signing-in-using-your-github-account-without-a-pre-existing-gitlab-account-is-not-allowed}

GitLabにサインインすると、次のエラーが表示されます:

```plaintext
Signing in using your GitHub account without a pre-existing
GitLab account is not allowed. Create a GitLab account first,
and then connect it to your GitHub account
```

このイシューを修正するには、GitLabでGitHubサインインをアクティブにする必要があります:

1. 左側のサイドバーで、自分のアバターを選択します。[新しいナビゲーションをオンに](../user/interface_redesign.md#turn-new-navigation-on-or-off)している場合、このボタンは右上隅にあります。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アカウント**を選択します。
1. **サインインに利用するサービス**セクションで、**Connect to GitHub**（GitHubに接続）を選択します。
