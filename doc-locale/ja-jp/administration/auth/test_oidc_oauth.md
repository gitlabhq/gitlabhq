---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabでOIDC/OAuthをテストする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabでOIDC/OAuthをテストするには、以下を行う必要があります:

1. [OIDC/OAuthを有効にする](#enable-oidcoauth-in-gitlab)
1. [クライアントアプリケーションでOIDC/OAuthをテストする](#test-oidcoauth-with-your-client-application)
1. [OIDC/OAuth認証を確認する](#verify-oidcoauth-authentication)

## 前提要件 {#prerequisites}

GitLabでOIDC/OAuthをテストする前に、以下を行う必要があります:

- パブリックにアクセス可能なインスタンスが必要です。
- インスタンスの管理者であること。
- OIDC/OAuthのテストに使用するクライアントアプリケーションが必要です。

## GitLabでOIDC/OAuthを有効にする {#enable-oidcoauth-in-gitlab}

まず、GitLabインスタンスでOIDC/OAuthアプリケーションを作成する必要があります。これを行うには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にした場合は、右上隅でアバターを選択し、**管理者**を選択します。
1. **アプリケーション**を選択します。
1. **新しいアプリケーションを追加**を選択します。
1. 名前、リダイレクト、許可されているスコープなど、クライアントアプリケーションの詳細を入力します。
1. `openid`スコープが有効になっていることを確認してください。
1. **アプリケーションを保存**を選択して、新しいアプリケーションを作成します。

## クライアントアプリケーションでOIDC/OAuthをテストする {#test-oidcoauth-with-your-client-application}

GitLabでアプリケーションを作成したら、それを使用してOIDC/OAuthをテストできます:

1. <https://openidconnect.net>をOIDC/OAuthのプレイグラウンドとして使用できます。
1. GitLabからサインアウトします。
1. クライアントアプリケーションにアクセスし、前の手順で作成したGitLabアプリケーションを使用して、OIDC/OAuthフローを開始します。
1. プロンプトに従ってGitLabにサインインし、クライアントアプリケーションがGitLabアカウントにアクセスすることを承認します。
1. OIDC/OAuthフローが完了すると、クライアントアプリケーションは、GitLabでの認証に使用できるアクセストークンを受信します。

## OIDC/OAuth認証を確認する {#verify-oidcoauth-authentication}

GitLabでOIDC/OAuth認証が正しく機能していることを確認するには、次のチェックを実行します:

1. 前の手順で受信したアクセストークンが有効であり、GitLabでの認証に使用できることを確認します。これは、アクセストークンを使用して認証するテストAPIリクエストをGitLabに行うことで実行できます。次に例を示します:

   ```shell
   curl --header "Authorization: Bearer <access_token>" https://mygitlabinstance.com/api/v4/user
   ```

    `<access_token>`を、前の手順で受信した実際のアクセストークンに置き換えます。APIリクエストが成功し、認証済みユーザーに関する情報が返された場合、OIDC/OAuth認証は正しく機能しています。

1. アプリケーションで指定したスコープが正しく適用されていることを確認します。特定のスコープを必要とするAPIリクエストを作成し、それらが期待どおりに成功するか失敗するかを確認することで、これを行うことができます。

以上です。これらの手順により、クライアントアプリケーションを使用して、GitLabインスタンスでOIDC/OAuth認証をテストできるようになります。
