---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サーバーをGitLab.comと統合する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab.comからプロジェクトをインポートし、GitLab.comアカウントでGitLabインスタンスにログインします。

GitLab.com OmniAuthプロバイダーを有効にするには、GitLab.comにアプリケーションを登録する必要があります。GitLab.comは、使用するアプリケーションIDとシークレットキーを生成します。

1. GitLab.comにサインインします。
1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アプリケーション**を選択します。
1. **新しいアプリケーションを追加**に必要な詳細を入力します。
   - 名前: これは何でもかまいません。`<Organization>'s GitLab`、`<Your Name>'s GitLab`、またはその他の説明的なものを検討してください。
   - リダイレクトURI:

     ```plaintext
     # You can also use a non-SSL URL, but you should use SSL URLs.
     https://your-gitlab.example.com/import/gitlab/callback
     https://your-gitlab.example.com/users/auth/gitlab/callback
     ```

   最初のリンクはインポーターに必要で、2番目のリンクは認証に必要です。

   以下の場合:

   - インポーターを使用する予定がある場合は、スコープをそのままにしておくことができます。
   - このアプリケーションを認証にのみ使用する場合は、より最小限のスコープセットを使用することをお勧めします。`read_user`で十分です。

1. **アプリケーションを保存**を選択します。
1. **アプリケーションID**と**シークレット**が表示されます。設定を続行するときは、このページを開いたままにしてください。
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

1. [共通設定](omniauth.md#configure-common-settings)で、`gitlab`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。
1. プロバイダーの設定を追加します:

   Linuxパッケージインストールで**GitLab.com**に対して認証する場合:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "gitlab",
       # label: "Provider name", # optional label for login button, defaults to "GitLab.com"
       app_id: "YOUR_APP_ID",
       app_secret: "YOUR_APP_SECRET",
       args: { scope: "read_user" } # optional: defaults to the scopes of the application
     }
   ]
   ```

   または、別のGitLabインスタンスに対して認証するLinuxパッケージインストールの場合:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "gitlab",
       label: "Provider name", # optional label for login button, defaults to "GitLab.com"
       app_id: "YOUR_APP_ID",
       app_secret: "YOUR_APP_SECRET",
       args: { scope: "read_user", # optional: defaults to the scopes of the application
               client_options: { site: "https://gitlab.example.com" } }
     }
   ]
   ```

   セルフコンパイルインストールで**GitLab.com**に対して認証する場合:

   ```yaml
   - { name: 'gitlab',
       # label: 'Provider name', # optional label for login button, defaults to "GitLab.com"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
   ```

   または、別のGitLabインスタンスに対して認証するためにセルフコンパイルインストールする場合:

   ```yaml
   - { name: 'gitlab',
       label: 'Provider name', # optional label for login button, defaults to "GitLab.com"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { "client_options": { "site": 'https://gitlab.example.com' } }
   ```

   {{< alert type="note" >}}

   GitLab 15.1以前は、`site`パラメータに`/api/v4`サフィックスが必要です。GitLab 15.2以降にアップグレードした後は、このサフィックスを削除することをお勧めします。

   {{< /alert >}}

1. `'YOUR_APP_ID'`をGitLab.comアプリケーションページのアプリケーションIDに変更します。
1. `'YOUR_APP_SECRET'`をGitLab.comアプリケーションページのシークレットに変更します。
1. 設定ファイルを保存します。
1. 適切な方法を使用して、これらの変更を実装します:
   - Linuxパッケージインストールの場合、[GitLabを再設定](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)します。
   - 自己コンパイルインストールの場合、[GitLabを再起動](../administration/restart_gitlab.md#self-compiled-installations)します。

サインインページに、通常のサインインフォームに続くGitLab.comアイコンが表示されるはずです。そのアイコンを選択すると、認証プロセスが開始されます。GitLab.comは、ユーザーにサインインしてGitLabアプリケーションを認可するように求めます。すべてがうまくいけば、ユーザーはGitLabインスタンスに戻り、サインインされます。

## サインイン時のアクセス権限を削減 {#reduce-access-privileges-on-sign-in}

{{< history >}}

- GitLab 14.8で`omniauth_login_minimal_scopes`[フラグ](../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは無効になっています。
- GitLab 14.9で[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/351331)になりました。
- GitLab 15.2で[機能フラグ`omniauth_login_minimal_scopes`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83453)は削除されました。

{{< /history >}}

認証にGitLabインスタンスを使用している場合は、OAuthアプリケーションがサインインに使用されるときに、アクセス権を減らすことができます。

任意のOAuthアプリケーションは、認可パラメータ`gl_auth_type=login`を使用してアプリケーションの目的をアドバタイズできます。アプリケーションが`api`または`read_api`で設定されている場合、より高い権限は必要ないため、アクセストークンはサインインのために`read_user`で発行されます。

GitLab OAuthクライアントは、このパラメータを渡すように設定されていますが、他のアプリケーションも渡すことができます。
