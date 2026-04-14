---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AWS CognitoをOAuth 2.0認証プロバイダーとして使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Amazon Web Services（AWS）Cognitoを使用すると、GitLabインスタンスにユーザー登録、サインイン、およびアクセス制御を追加できます。次のドキュメントでは、AWS CognitoをOAuth 2.0プロバイダーとして有効にします。

## AWS Cognitoを設定する {#configure-aws-cognito}

[AWS Cognito](https://aws.amazon.com/cognito/) OAuth 2.0 OmniAuthプロバイダーを有効にするには、アプリケーションをCognitoに登録します。このプロセスにより、アプリケーションのクライアントIDとクライアントのシークレットキーが生成されます。AWS Cognitoを認証プロバイダーとして有効にするには、次の手順を完了してください。後で、設定を適宜変更できます。

1. [AWS console](https://console.aws.amazon.com/console/home)にサインインします。
1. **サービス**メニューから、**Cognito**を選択します。
1. **Manage User Pools**を選択し、右上隅にある**Create a user pool**を選択します。
1. ユーザープール名を入力し、**Step through settings**を選択します。
1. **How do you want your end users to sign in?**で、**Email address or phone number**と**Allow email addresses**を選択します。
1. **Which standard attributes do you want to require?**で、**email**を選択します。
1. 残りの設定は必要に応じて構成します。基本的なセットアップでは、これらの設定はGitLab設定に影響しません。
1. **App clients**の設定で、以下を行います:
   1. **Add an app client**を選択します。
   1. **App client name**を追加します。
   1. **Enable username password based authentication**チェックボックスを選択します。
1. **Create app client**を選択します。
1. AWS Lambda機能でメール送信を設定し、ユーザープールの作成を完了します。
1. ユーザープールの作成後、**App client settings**に移動して、必要な情報を提供します:

   - **Enabled Identity Providers** \- すべて選択
   - **コールバックURL** - `https://<your_gitlab_instance_url>/users/auth/cognito/callback`
   - **Allowed OAuth Flows** \- Authorization code grant
   - **Allowed OAuth 2.0 Scopes** - `email`、`openid`、および`profile`

1. アプリクライアントの設定の変更を保存します。
1. **Domain name**で、AWS CognitoアプリケーションのAWSドメイン名を含めます。
1. **App Clients**で、アプリクライアントIDを見つけます。アプリクライアントのシークレットキーを表示するには、**詳細を表示**を選択します。これらの値は、OAuth 2.0クライアントIDとクライアントのシークレットキーに対応します。これらの値を保存します。

## GitLabを設定する {#configure-gitlab}

1. [共通設定](../../integration/omniauth.md#configure-common-settings)で、`cognito`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。
1. GitLabサーバーで、設定ファイルを開きます。Linuxパッケージインストールの場合:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

1. 次のコードでAWS Cognitoアプリケーション情報を次のパラメータに入力します:

   - `app_id`: クライアントID。
   - `app_secret`: クライアントのシークレットキー。
   - `site`: Amazonのドメインとリージョン。

   コードブロックを`/etc/gitlab/gitlab.rb`ファイルに含めます:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['cognito']
   gitlab_rails['omniauth_providers'] = [
     {
       name: "cognito",
       label: "Provider name", # optional label for login button, defaults to "Cognito"
       icon: nil,   # Optional icon URL
       app_id: "<client_id>",
       app_secret: "<client_secret>",
       args: {
         scope: "openid profile email",
         client_options: {
           site: "https://<your_domain>.auth.<your_region>.amazoncognito.com",
           authorize_url: "/oauth2/authorize",
           token_url: "/oauth2/token",
           user_info_url: "/oauth2/userInfo"
         },
         user_response_structure: {
           root_path: [],
           id_path: ["sub"],
           attributes: { nickname: "email", name: "email", email: "email" }
         },
         name: "cognito",
         strategy_class: "OmniAuth::Strategies::OAuth2Generic"
       }
     }
   ]
   ```

1. 設定ファイルを保存します。
1. ファイルを保存し、変更を有効にするためにGitLabを[reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

サインインページに通常のサインインフォームの下にCognitoオプションが表示されるようになりました。このオプションを選択すると、認証プロセスが開始されます。AWS CognitoはサインインとGitLabアプリケーションの認可を要求します。認可が成功すると、リダイレクトされてGitLabインスタンスにサインインします。

詳細については、[Configure common設定](../../integration/omniauth.md#configure-common-settings)を参照してください。
