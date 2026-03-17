---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: お使いのGitLabサーバーをBitbucket Cloudと統合する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Bitbucket.orgをOAuth 2.0プロバイダーとして設定し、Bitbucket.orgの認証情報を使用してGitLabにサインインできます。Bitbucket.orgからプロジェクトをインポートすることもできます。

- Bitbucket.orgをOmniAuthプロバイダーとして使用するには、[Bitbucket OmniAuthプロバイダー](#use-bitbucket-as-an-oauth-20-authentication-provider)セクションに従ってください。
- Bitbucketからプロジェクトをインポートするには、[Bitbucket OmniAuthプロバイダー](#use-bitbucket-as-an-oauth-20-authentication-provider)と[Bitbucket project import](#bitbucket-project-import)の両方のセクションに従ってください。

## BitbucketをOAuth 2.0認証プロバイダーとして使用する {#use-bitbucket-as-an-oauth-20-authentication-provider}

Bitbucket OmniAuthプロバイダーを有効にするには、アプリケーションをBitbucket.orgに登録する必要があります。Bitbucketが、使用するアプリケーションIDとシークレットキーを生成します。

1. [Bitbucket.org](https://bitbucket.org)にサインインします。
1. アプリケーションを登録する方法に応じて、個人のユーザー設定（**Bitbucket settings**）またはチームの設定（**Manage team**）に移動します。アプリケーションを個人として登録するかチームとして登録するかは、完全にあなた次第です。
1. 左メニューの**Access Management**で、**OAuth**を選択します。
1. **Add consumer**を選択します。
1. 必要な詳細を入力します:

   - **Name**: これは任意のものです。`<Organization>'s GitLab`や`<Your Name>'s GitLab`のような、説明的なものを検討してください。
   - **Application description**: （オプション）必要に応じて入力してください。
   - **コールバックURL**: （GitLabバージョン8.15以降で必須）`https://gitlab.example.com/users/auth`のような、GitLabインストールのURL。このフィールドを空のままにすると、`Invalid redirect_uri`メッセージが表示されます。

     > [!warning] 
     > 
     > [OAuth 2 covert redirect](https://oauth.net/advisories/2014-1-covert-redirect/)攻撃を防ぐため、Bitbucket認可コールバックURLの末尾に`/users/auth`を追加してください。Bitbucketで認証する、およびBitbucketリポジトリからデータをインポートするには、この認可エンドポイントを含める必要があります。

   - **URL**: `https://gitlab.example.com`のような、GitLabインストールのURL。

1. 以下の権限を付与します:

   - **アカウント**: `Email`, `Read`
   - **プロジェクト**: `Read`
   - **リポジトリ**: `Read`
   - **Pull Requests**: `Read`
   - **イシュー**: `Read`
   - **Wikis**: `Read and write`

1. **Save**を選択します。
1. 新しく作成したOAuthコンシューマーを選択すると、**キー**と**シークレット**がOAuthコンシューマーのリストに表示されます。設定を続行する間、このページを開いたままにしてください。

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

   セルフコンパイルインストールの場合:

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

   `<bitbucket_app_key>`は**キー**、`<bitbucket_app_secret>`は**シークレット**です（Bitbucketアプリケーションページから）。

1. 設定ファイルを保存します。
1. 変更を有効にするには、Linuxパッケージを使用してインストールした場合は[GitLabを再設定](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) 、自己コンパイルでインストールした場合は[再起動](../administration/restart_gitlab.md#self-compiled-installations)します。

サインインページに、通常のサインインフォームの下にBitbucketアイコンが表示されます。そのアイコンを選択すると、認証プロセスが開始されます。Bitbucketは、ユーザーにサインインしてGitLabアプリケーションを認可するよう求めます。成功すると、ユーザーはGitLabに戻り、サインインします。

> [!note]
> 
> マルチノードアーキテクチャの場合、プロジェクトをインポートできるように、Bitbucketプロバイダーの設定をSidekiqノードにも含める必要があります。

## Bitbucketプロジェクトインポート {#bitbucket-project-import}

以前の設定が完了したら、Bitbucketを使用してGitLabにサインインし、[プロジェクトのインポートを開始](../user/import/bitbucket_cloud.md)できます。

Bitbucketからプロジェクトをインポートしたいが、サインインを有効にしたくない場合は、[サインインを無効にするには、**管理者**エリアで](omniauth.md#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources)できます。
