---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: JWTを認証プロバイダーとして使用
description: Just-In-Timeユーザープロビジョニングを使用して、GitLabでJWTベースのSSOを構成します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

JWT OmniAuthプロバイダーを有効にするには、アプリケーションをJWTに登録する必要があります。JWTは、あなたが使用するためのシークレットキーを提供します。

1. GitLabサーバーで、設定ファイルを開きます。

   Linuxパッケージインストールの場合:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   自己コンパイルによるインストールの場合:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. [共通設定](../../integration/omniauth.md#configure-common-settings)で、`jwt`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。
1. プロバイダー設定を追加します。

   Linuxパッケージインストールの場合:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: "jwt",
       label: "Provider name", # optional label for login button, defaults to "Jwt"
       args: {
         secret: "YOUR_APP_SECRET",
         algorithm: "HS256", # Supported algorithms: "RS256", "RS384", "RS512", "ES256", "ES384", "ES512", "HS256", "HS384", "HS512"
         uid_claim: "email",
         required_claims: ["name", "email"],
         info_map: { name: "name", email: "email" },
         auth_url: "https://example.com/",
         valid_within: 3600 # 1 hour
       }
     }
   ]
   ```

   自己コンパイルによるインストールの場合:

   ```yaml
   - { name: 'jwt',
       label: 'Provider name', # optional label for login button, defaults to "Jwt"
       args: {
         secret: 'YOUR_APP_SECRET',
         algorithm: 'HS256', # Supported algorithms: 'RS256', 'RS384', 'RS512', 'ES256', 'ES384', 'ES512', 'HS256', 'HS384', 'HS512'
         uid_claim: 'email',
         required_claims: ['name', 'email'],
         info_map: { name: 'name', email: 'email' },
         auth_url: 'https://example.com/',
         valid_within: 3600 # 1 hour
       }
     }
   ```

   各設定オプションの詳細については、[OmniAuth JWT使用ドキュメント](https://github.com/mbleigh/omniauth-jwt#usage)を参照してください。

   > [!warning]
   > これらの設定を誤って構成すると、脆弱なインスタンスになる可能性があります。

1. `YOUR_APP_SECRET`をクライアントのシークレットキーに変更し、`auth_url`をリダイレクトURLに設定します。
1. 設定ファイルを保存します。
1. 変更を有効にするには、次の手順に従います。
   - Linuxパッケージを使用してGitLabをインストールした場合は、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
   - GitLabインストールを自分でコンパイルした場合は、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

サインインページに、通常のサインインフォームの下にJWTアイコンが表示されるはずです。そのアイコンを選択すると、認証プロセスが開始されます。JWTは、ユーザーにサインインしてGitLabアプリケーションを承認するよう求めます。すべてがうまくいけば、ユーザーはGitLabにリダイレクトされ、サインインされます。
