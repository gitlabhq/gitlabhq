---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabサーバーをBitbucket Cloudと連携させます
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Bitbucket.orgをOAuth 2.0プロバイダーとして設定し、Bitbucket.orgアカウントの認証情報を使用してGitLabにサインインできます。Bitbucket.orgからプロジェクトをインポートすることもできます。

- Bitbucket.orgをOmniAuthプロバイダーとして使用するには、[Bitbucket OmniAuthプロバイダー](#use-bitbucket-as-an-oauth-20-authentication-provider)のセクションを参照してください。
- Bitbucketからプロジェクトをインポートするには、[Bitbucket OmniAuthプロバイダー](#use-bitbucket-as-an-oauth-20-authentication-provider)と[Bitbucketプロジェクトのインポート](#bitbucket-project-import)の両方のセクションを参照してください。

## BitbucketをOAuth 2.0認証プロバイダーとして使用する {#use-bitbucket-as-an-oauth-20-authentication-provider}

Bitbucket OmniAuthプロバイダーを有効にするには、Bitbucket.orgにアプリケーションを登録する必要があります。Bitbucketは、使用するアプリケーションIDとシークレットキーを生成します。

1. [Bitbucket.org](https://bitbucket.org)にサインインします。
1. アプリケーションの登録方法に応じて、個々のユーザー設定（**Bitbucket settings**（Bitbucket設定））またはチームの設定（**Manage team**（チームの管理））に移動します。アプリケーションが個人として登録されているか、チームとして登録されているかは重要ではありません。それは完全にあなた次第です。
1. 左側のメニューの**Access Management**（アクセス管理）で、**OAuth**を選択します。
1. **Add consumer**（コンシューマーを追加）を選択します。
1. 必要な詳細を入力します:

   - **名前**: これは何でもかまいません。`<Organization>'s GitLab`や`<Your Name>'s GitLab`など、わかりやすいものを検討してください。
   - **アプリケーションの説明**: オプション。必要に応じてここに入力します。
   - **コールバックURL**: (GitLabバージョン8.15以降で必須) `https://gitlab.example.com/users/auth`などのGitLabインストールのURL。このフィールドを空のままにすると、`Invalid redirect_uri`メッセージが表示されます。

     {{< alert type="warning" >}}

     [OAuth 2](https://oauth.net/advisories/2014-1-covert-redirect/)の秘密リダイレクト攻撃を防ぐために、`/users/auth`をBitbucket認可コールバックURLの末尾に追加します。Bitbucketで認証し、Bitbucketリポジトリからデータをインポートするには、この認可エンドポイントを含める必要があります。

     {{< /alert >}}

   - **URL**: `https://gitlab.example.com`などのGitLabインストールのURL。

1. 少なくとも次の権限を付与します:

   - **アカウント**: `Email`、`Read`
   - **プロジェクト**: `Read`
   - **リポジトリ**: `Read`
   - **プルリクエスト**: `Read`
   - **イシュー**: `Read`
   - **Wiki**: `Read and write`

1. **保存**を選択します。
1. 新しく作成したOAuthコンシューマーを選択すると、OAuthコンシューマーのリストに**キー**と**シークレット**が表示されます。このページを開いたまま、設定を続行します。

1. GitLabサーバーで、設定ファイルを開きます:

   ```shell
   # For Omnibus packages
   sudo editor /etc/gitlab/gitlab.rb

   # For installations from source
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. Bitbucketプロバイダーの設定を追加します:

   Linuxパッケージインストールの場合:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "bitbucket",
       # label: "Provider name", # optional label for login button, defaults to "Bitbucket"
       app_id: "<bitbucket_app_key>",
       app_secret: "<bitbucket_app_secret>",
       url: "https://bitbucket.org/"
     }
   ]
   ```

   自己コンパイルによるインストールの場合:

   ```yaml
   omniauth:
     enabled: true
     providers:
       - { name: 'bitbucket',
           # label: 'Provider name', # optional label for login button, defaults to "Bitbucket"
           app_id: '<bitbucket_app_key>',
           app_secret: '<bitbucket_app_secret>',
           url: 'https://bitbucket.org/'
         }
   ```

   `<bitbucket_app_key>`はBitbucketアプリケーションページの**キー**、`<bitbucket_app_secret>`は**シークレット**です。

1. 設定ファイルを保存します。
1. 変更を有効にするには、Linuxパッケージを使用してインストールした場合は、[GitLabを再設定してください](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) 。自己コンパイルしたインストールの場合は、[再起動](../administration/restart_gitlab.md#self-compiled-installations)してください。

サインインページには、通常のサインインフォームの下にBitbucketアイコンが表示されるはずです。そのアイコンを選択すると、認証プロセスが開始されます。Bitbucketは、ユーザーにサインインを求め、GitLabアプリケーションを認可するように求めます。成功すると、ユーザーはGitLabに戻り、サインインします。

{{< alert type="note" >}}

マルチノードアーキテクチャの場合、プロジェクトをインポートできるように、Bitbucketプロバイダーの設定をSidekiqノードにも含める必要があります。

{{< /alert >}}

## Bitbucketプロジェクトのインポート {#bitbucket-project-import}

前の設定が完了したら、Bitbucketを使用してGitLabにサインインし、[プロジェクトのインポートを開始](../user/project/import/bitbucket.md)できます。

Bitbucketからプロジェクトをインポートしたいが、サインインを有効にしたくない場合は、[**管理者**エリア](omniauth.md#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources)でサインインを無効にすることができます。
