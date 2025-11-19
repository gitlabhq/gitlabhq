---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Atlassian Crowdを認証プロバイダーとして使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Atlassian Crowd OmniAuthプロバイダーを使用してGitLabを認証します。このプロバイダーを有効にすると、Git-over-httpsリクエストの認証もCrowdでできるようになります。

## 新しいCrowdアプリケーションを構成する {#configure-a-new-crowd-application}

1. 上部のメニューで、**アプリケーション** > **Add application**（アプリケーションの追加）を選択します。
1. **Add application**（アプリケーションの追加）の手順を実行し、適切な詳細を入力します。
1. 完了したら、**Add application**（アプリケーションの追加） を選択します。

## GitLabを設定する {#configure-gitlab}

1. GitLabサーバーで、設定ファイルを開きます。

   - Linuxパッケージインストール:

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

   - 自己コンパイルによるインストール:

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

1. [共通設定](../../integration/omniauth.md#configure-common-settings)で、`crowd`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。

1. プロバイダーの設定を追加します:

   - Linuxパッケージインストール:

     ```ruby
       gitlab_rails['omniauth_providers'] = [
         {
           name: "crowd",
           args: {
             crowd_server_url: "CROWD_SERVER_URL",
             application_name: "YOUR_APP_NAME",
             application_password: "YOUR_APP_PASSWORD"
           }
         }
       ]
     ```

   - 自己コンパイルによるインストール:

     ```yaml
        - { name: 'crowd',
            args: {
              crowd_server_url: 'CROWD_SERVER_URL',
              application_name: 'YOUR_APP_NAME',
              application_password: 'YOUR_APP_PASSWORD' } }
     ```

1. `CROWD_SERVER_URL`をCrowdサーバーの[ベースURL](https://confluence.atlassian.com/crowdkb/how-to-change-the-crowd-base-url-245827278.html)に変更します。
1. `YOUR_APP_NAME`をCrowdアプリケーションページからアプリケーション名に変更します。
1. `YOUR_APP_PASSWORD`を、設定したアプリケーションのパスワードに変更します。
1. 設定ファイルを保存します。
1. 変更を有効にするには、[再構成](../restart_gitlab.md#reconfigure-a-linux-package-installation)または[再起動](../restart_gitlab.md#self-compiled-installations)します。

サインインページのサインインフォームに、Crowdタブが表示されるはずです。

## トラブルシューティング {#troubleshooting}

### エラー: 「認証情報が無効なため、Crowdからの認可に失敗しました」 {#error-could-not-authorize-you-from-crowd-because-invalid-credentials}

このエラーは、ユーザーがCrowdで認証を試みると発生することがあります。Crowdの管理者は、ログファイルを参照して、このエラーメッセージの正確な原因を特定する必要があります。

GitLabにサインインする必要があるCrowdユーザーが、[アプリケーション](#configure-a-new-crowd-application)の**Authorization**ステップで認可されていることを確認します。これは、Crowdの「認証テスト」（2.11以降）を試すことで確認できます。

![Crowdの認可ステージ](img/crowd_application_authorisation_v10_4.png)
