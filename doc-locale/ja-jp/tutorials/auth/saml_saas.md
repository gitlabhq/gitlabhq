---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitLab.comグループのSAML SSOを設定する'
---

このチュートリアルでは、OktaやMicrosoft Entra IDなどのアイデンティティプロバイダ（IdP）を使用して、GitLab.comグループのSAMLシングルサインオン（SSO）を設定する方法について説明します。完了すると、グループのメンバーはIdP経由でGitLabにサインインできます。

このチュートリアルでは、次のことを行います:

1. IdPアプリケーションを介してSAMLを設定します。
1. GitLabグループでSAML SSOを設定します。
1. SAML接続をテストします。
1. 設定を検証するためにユーザーアカウントをリンクします。

## はじめる前 {#before-you-begin}

前提条件: 

- GitLab.comのGitLab PremiumまたはUltimateプランのグループのオーナーロールが必要です。
- IdPへの管理者アクセス権が必要です。
- IdPに少なくとも1つのテストユーザーアカウントが必要です。
- シングルサインオンの概念を理解しておく必要があります。

完了までの時間: 20～30分

## ステップ1: GitLabの情報を収集する {#step-1-gather-gitlab-information}

IdPで何かを設定する前に、IdPがGitLabグループと通信する方法を伝えるGitLabからの接続詳細をいくつか取得する必要があります。

GitLabの情報を収集するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **SAML SSO**を選択します。
1. これらの値を書き留めます:
   - **識別子**
   - **アサーションコンシューマサービスURL**
   - **GitLabシングルサインオンURL**

## ステップ2: IdPアプリケーションを作成する {#step-2-create-an-idp-application}

GitLabの詳細が準備できたので、IdPでアプリケーションを作成します。このアプリケーションは、GitLabの情報をIdPにマップし、2つのシステム間のユーザー情報フローを設定します。

IdPアプリケーションを作成するには:

{{< tabs >}}

{{< tab title="Okta" >}}

1. 管理者としてOktaにサインインします。
1. 管理コンソールで、**アプリケーション** > **アプリケーション**を選択します。
1. **Create App Integration**を選択します。
1. **Sign-in method**セクションで、**SAML 2.0**を選択します。
1. **Next**を選択します。
1. **一般設定**タブで、アプリケーションの名前を入力します。例: `GitLab SAML`。
1. **Next**を選択します。
1. **Configure SAML**タブで、手順1の値を使用してフィールドに入力します:
   - **Single sign-on URL**: **アサーションコンシューマーサービスURL**を入力します。
   - **Use this for Recipient URL and Destination URL**チェックボックスをオンにします。
   - **Audience URI (SP Entity ID)**: **識別子**を入力します。
1. 名前識別子を設定します:
   - **Application username (NameID)**: **カスタム**を選択し、`user.getInternalProperty("id")`を入力します。
   - **Name ID Format**: **Persistent**を選択します。
1. **Attribute Statements (optional)**セクションで、この属性を追加します:
   - **名前**: `email`
   - **値**: `user.email`
1. **Application Login Page**設定までスクロールします:
   - **Login page URL**: **GitLabシングルサインオンのURL**を入力します。
1. **Next**を選択します。
1. **Feedback**タブで、ユースケースに適したオプションを選択します。
1. **Finish**を選択します。

SAMLアプリケーションがOktaに作成されます。

> [!note]SAML属性と詳細な設定オプションの詳細については、[SAML SSOのドキュメントを参照してください。](../../user/group/saml_sso/_index.md#okta)

{{< /tab >}}

{{< tab title="Entra ID" >}}

1. [Microsoft Entra管理センター](https://entra.microsoft.com/)にサインインします。
1. **アイデンティティ** > **アプリケーション** > **Enterprise applications**を選択します。
1. **新しいアプリケーション**を選択します。
1. **Create your own application**を選択します。
1. ダイアログで、フィールドに入力します:
   - **Name**: アプリケーションの名前を入力します。このチュートリアルでは、`GitLab SAML`を使用します。
   - **Integrate any other application you don't find in the gallery (Non-gallery)**を選択します。
1. **Create**を選択します。

エンタープライズアプリケーションがMicrosoft Entra IDに作成されます。

1. エンタープライズアプリケーションで、左側のサイドバーから**Single sign-on**を選択します。
1. シングルサインオン方式として**SAML**を選択します。
1. **Basic SAML Configuration**セクションで、**編集**を選択します。
1. 手順1の値を使用してフィールドに入力します:
   - **Identifier (Entity ID)**: **識別子**を入力します。
   - **Reply URL (Assertion Consumer Service URL)**: **アサーションコンシューマーサービスURL**を入力します。
   - **Sign on URL**: **GitLabシングルサインオンのURL**を入力します。
1. **Save**を選択します。
1. **User Attributes & Claims**セクションで、**編集**を選択します。
1. **Add new claim**を選択し、フィールドに入力します:
   - **Name**: `email`を入力します。
   - **Source attribute**: `user.mail`を選択します。
1. **Save**を選択します。
1. **Unique User Identifier (Name ID)**クレームを編集します:
   - 既存の**Unique User Identifier**クレームを選択します。
   - **Source attribute**: `user.objectid`を選択します。
   - **Name identifier format**: **Persistent**を選択します。
1. **Save**を選択します。

> [!note]SAML属性と詳細な設定オプションの詳細については、[SAML SSOのドキュメントを参照してください。](../../user/group/saml_sso/_index.md#azure)

{{< /tab >}}

{{< /tabs >}}

## ステップ3: 接続の詳細を収集する {#step-3-gather-the-connection-details}

ここで、GitLabが認証リクエストをIdPに送信するために必要な情報を取得します。

接続の詳細を収集するには:

{{< tabs >}}

{{< tab title="Okta" >}}

1. Okta SAMLアプリで、**Sign On**タブを選択します。
1. 右側で、**View SAML setup instructions**を選択します。
1. **Identity Provider Single Sign-On URL（アイデンティティプロバイダのシングルサインオンURL）**をメモします。
1. 証明書フィンガープリントを生成します:
   1. **X.509 Certificate**フィールドで、テキストをコピーしてローカルに保存します。
   1. ターミナルを開き、証明書ファイルを保存したディレクトリに移動します。
   1. このコマンドを実行して、証明書フィンガープリントを生成します:

   ```shell
      # Replace `<certificate_filename>` with the actual filename of your downloaded certificate.
      # You might need to install OpenSSL or use an alternative method to generate the fingerprint.
       openssl x509 -noout -fingerprint -sha256 -in <certificate_filename>.crt
   ```

1. `SHA256 Fingerprint=`の後のフィンガープリント値をコピーします。フィンガープリントは`A1:B2:C3:D4:E5:F6:...`のようになります。

{{< /tab >}}

{{< tab title="Entra ID" >}}

1. エンタープライズアプリケーションで、**Single sign-on**を選択します。
1. **SAML Signing Certificate**セクションで、**Thumbprint**の値を書き留めます。サムプリントは`A1B2C3D4E5F6...`のようになります。
1. **Set up GitLab SAML**セクションで、**Login URL**を書き留めます。このセクションの名前は、エンタープライズアプリケーションの名前に基づいています。

{{< /tab >}}

{{< /tabs >}}

## ステップ4: GitLabでSAML SSOを設定する {#step-4-configure-saml-sso-in-gitlab}

接続を完了するために必要なものがすべて揃っています。GitLabに戻り、接続の詳細を入力して、グループのSAML認証をオンにします。

SAMLを設定するには:

1. GitLabグループに戻ります。
1. **設定** > **SAML SSO**を選択します。
1. **設定**セクションで、フィールドに入力します:
   - **アイデンティティプロバイダのシングルサインオンURL**: 手順3のURLを入力します。
   - **証明書のフィンガープリント**: 手順3のフィンガープリントを入力します。
1. **このグループのSAML認証を有効にします**チェックボックスを選択します。
1. **デフォルトのメンバーシップロール**ドロップダウンリストから、**最小アクセス**を選択します。
1. **変更を保存**を選択します。

基本的なSAML接続が設定されました。

> [!note]デフォルトのメンバーシップロールは、任意のロールに設定できます。すべての新しいユーザーには、SAMLを介して最初にサインインするときに、このロールが割り当てられます。デフォルトを[**最小アクセス**](../../user/permissions.md#users-with-minimal-access)に設定し、後でユーザーを昇格させると、ユーザーが過剰なアクセス権を持つリスクが軽減されます。

## ステップ5: SAML設定をテストする {#step-5-test-the-saml-configuration}

チームを招待する前に、接続が正しく機能することを確認してください。

SAML設定をテストするには:

1. **設定** > **SAML SSO**ページで、**SAML構成の確認**を選択します。GitLabはIdPにリダイレクトされます。
1. IdP認証情報でサインインします。
1. IdPがGitLabにリダイレクトすることを確認します。

エラーが表示される場合は、[トラブルシューティングガイド](../../user/group/saml_sso/troubleshooting.md)を参照してください。

## ステップ6: ユーザーアカウントをリンクして、完全なフローをテストする {#step-6-link-a-user-account-to-test-the-full-flow}

設定は問題ありません。次に、チームメンバーがIdPを介してGitLabに最初に接続するときと同様に、テストアカウントをリンクして、ユーザーの視点からエクスペリエンスをテストします。

ユーザーアカウントのリンクをテストするには:

1. GitLabからサインアウトします。
1. 別のブラウザまたはシークレットウィンドウで、テストGitLabアカウントにサインインします。
1. 手順1で書き留めたGitLabシングルサインオンURIにアクセスします。
1. **許可する**を選択します。
1. プロンプトが表示されたら、IdP認証情報でサインインします。
1. GitLabグループにリダイレクトされたことを確認します。

おつかれさまでした。SAMLアイデンティティをGitLabアカウントに正常にリンクしました。

## ステップ7: オプション: SSO強制を有効にする {#step-7-optional-turn-on-sso-enforcement}

作業用のSAML設定があります。オプションの最後の手順として、SSO強制を有効にすることができます。SSO強制では、すべてのグループメンバーがIdPを介して認証を行う必要があり、セキュリティが強化されます。ただし、他の認証方法によるアクセスは防止されます。

SSO強制を有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **SAML SSO**を選択します。
1. **このグループのWEBアクティビティーにSSOのみの認証を適用します**を選択します。
1. **変更を保存**を選択します。

強制を有効にすると、すべてのグループメンバーは、グループリソースにアクセスする前にIdP経由でサインインする必要があります。

## 次の手順 {#next-steps}

GitLabグループのSAML SSOが正常に設定されました。次に実行できることを次に示します:

- 自動的にユーザーを同期するには、[SCIMプロビジョニングを設定](../../user/group/saml_sso/scim_setup.md)します。
- IdPグループに基づいてGitLabグループメンバーシップを管理するには、[グループ同期を設定する](../../user/group/saml_sso/group_sync.md)を設定します。
- 新しいユーザーに対して[バイパスユーザーメール確認](../../user/group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains)を行うドメインを確認します。
- 高度なセキュリティオプションについては、[SSO強制ドキュメント](../../user/group/saml_sso/_index.md#sso-enforcement)を確認してください。

## トラブルシューティング {#troubleshooting}

このチュートリアルで問題が発生した場合は、次のリソースを参照してください:

- [一般的なSAMLエラーと解決策](../../user/group/saml_sso/troubleshooting.md)
- [アカウントのリンクを解除して再リンクする方法](../../user/group/saml_sso/_index.md#unlink-accounts)
- [サポートリソース](https://about.gitlab.com/support/)
