---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab DedicatedのSAMLシングルサインオン（SSO）認証を設定します。
title: GitLab DedicatedのSAML SSO
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

最大10個のIdentity Provider（IdP）に対して、GitLab DedicatedインスタンスのSAMLシングルサインオン（SSO）を設定できます。

次のSAML SSOオプションを使用できます:

- [リクエスト署名](#request-signing)
- [グループのSAML SSO](#saml-groups)
- [グループ同期](#group-sync)

{{< alert type="note" >}}

これは、GitLab Dedicatedインスタンスのエンドユーザーに対してSAML SSOを設定します。スイッチボードの管理者向けにSSOを設定するには、[スイッチボードのSSOを設定する](_index.md#configure-switchboard-sso)を参照してください。

{{< /alert >}}

## 前提要件 {#prerequisites}

- GitLab DedicatedのSAMLを設定する前に、[Identity Providerを設定](../../../../integration/saml.md#set-up-identity-providers)する必要があります。
- SAML認証リクエストに署名するようにGitLabを設定するには、GitLab Dedicatedインスタンスのプライベートキーと公開証明書のペアを作成する必要があります。

## スイッチボードでSAMLプロバイダーを追加 {#add-a-saml-provider-with-switchboard}

GitLab DedicatedインスタンスのSAMLプロバイダーを追加するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部にある**設定**を選択します。
1. **SAML providers**（SAMLプロバイダー）を展開します。
1. **Add SAML provider**（SAMLプロバイダーの追加）を選択します。
1. **SAML label**（SAMLラベル）テキストボックスに、スイッチボードでこのプロバイダーを識別するための名前を入力します。
1. オプション。SAMLグループメンバーシップに基づいてユーザーを設定するか、グループ同期を使用するには、次のフィールドに入力します:
   - **SAML group attribute**（SAMLグループ属性）
   - **Admin groups**（管理者グループ）
   - **Auditor groups**（監査担当者グループ）
   - **External groups**（外部グループ）
   - **Required groups**（必須グループ）
1. **IdP cert fingerprint**（IdP証明書フィンガープリント）テキストボックスに、IdP証明書フィンガープリントを入力します。この値は、IdPの`X.509`証明書のフィンガープリントのSHA1チェックサムです。
1. **IdP SSO target URL**（IdP SSOターゲットURL）テキストボックスに、GitLab Dedicatedがユーザーをリダイレクトしてこのプロバイダーで認証を行うIdP上のエンドポイントのURLを入力します。
1. **Name identifier format**（名前識別子形式）ドロップダウンリストから、このプロバイダーがGitLabに送信するNameIDの形式を選択します。
1. オプション。リクエスト署名を設定するには、次のフィールドに入力します:
   - **発行者**
   - **Attribute statements**（属性ステートメント）
   - **セキュリティ**
1. このプロバイダーの使用を開始するには、**Enable this provider**（このプロバイダーを有効にする）チェックボックスを選択します。
1. **保存**を選択します。
1. 別のSAMLプロバイダーを追加するには、**Add SAML provider**（SAMLプロバイダーの追加）をもう一度選択し、前の手順に従います。最大10個のプロバイダーを追加できます。
1. ページの一番上までスクロールします。**Initiated changes**（開始された変更）バナーには、SAML設定の変更が次のメンテナンス期間中に適用されることが説明されています。変更をすぐに適用するには、**Apply changes now**（今すぐ変更を適用）を選択します。

変更が適用されると、このSAMLプロバイダーを使用してGitLab Dedicatedインスタンスにサインインできます。グループ同期を使用するには、[SAMLグループリンクを設定](../../../../user/group/saml_sso/group_sync.md#configure-saml-group-links)します。

## SAML設定を検証します {#verify-your-saml-configuration}

SAML設定が成功したことを検証するには:

1. サインアウトして、GitLab Dedicatedインスタンスのサインインページに移動します。
1. SAMLプロバイダーのSSOボタンがサインインページに表示されることを確認します。
1. インスタンスのメタデータURL（`https://INSTANCE-URL/users/auth/saml/metadata`）に移動します。メタデータURLには、Identity Providerの設定を簡素化し、SAML設定を検証するのに役立つ情報が表示されます。
1. SAMLプロバイダーを介してサインインし、認証フローが正しく機能することを確認します。

トラブルシューティング情報については、[SAMLのトラブルシューティング](../../../../user/group/saml_sso/troubleshooting.md)を参照してください。

## サポートチケットを使用してSAMLプロバイダーを追加 {#add-a-saml-provider-with-a-support-request}

スイッチボードを使用してGitLab DedicatedインスタンスのSAMLを追加または更新できない場合は、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開くことができます:

1. 必要な変更を行うには、GitLabアプリケーションに必要な[SAML設定ブロック](../../../../integration/saml.md#configure-saml-support-in-gitlab)をサポートチケットに含めます。SAMLを有効にするには、GitLabに少なくとも次の情報が必要です:
   - IDP SSOターゲットURL
   - 証明書フィンガープリントまたは証明書
   - NameID形式
   - SSOログインボタンの説明

   ```json
   "saml": {
     "attribute_statements": {
         //optional
     },
     "enabled": true,
     "groups_attribute": "",
     "admin_groups": [
       // optional
     ],
     "idp_cert_fingerprint": "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8",
     "idp_sso_target_url": "https://login.example.com/idp",
     "label": "IDP Name",
     "name_identifier_format": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
     "security": {
       // optional
     },
     "auditor_groups": [
       // optional
     ],
     "external_groups": [
       // optional
     ],
     "required_groups": [
       // optional
     ],
   }
   ```

1. GitLabがSAML設定をインスタンスにデプロイすると、サポートチケットで通知されます。
1. SAML設定が成功したことを検証するには:
   - SSOログインボタンの説明がインスタンスのログインページに表示されていることを確認します。
   - GitLabがサポートチケットで提供するインスタンスのメタデータURLに移動します。このページを使用すると、Identity Providerの設定の多くを簡素化できるだけでなく、設定を手動で検証することもできます。

## リクエスト署名 {#request-signing}

[SAMLリクエスト署名](../../../../integration/saml.md#sign-saml-authentication-requests-optional)が必要な場合は、証明書を取得する必要があります。この証明書は自己署名することができ、任意の共通名（CN）の所有権を公開認証局（CA）に証明する必要がないという利点があります。

{{< alert type="note" >}}

SAMLリクエスト署名には証明書署名が必要なため、この機能を有効にしてSAMLを使用するには、これらの手順を完了する必要があります。

{{< /alert >}}

SAMLリクエスト署名を有効にするには:

1. [サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、リクエスト署名を有効にすることを指示します。
1. GitLabは、署名するために証明書署名リクエスト（CSR）の送信について協力します。または、CSRは公開CAで署名できます。
1. 証明書に署名した後、証明書とそれに関連付けられたプライベートキーを使用して、スイッチボードの[SAML設定](#add-a-saml-provider-with-switchboard)の`security`セクションを完了できます。

GitLabからIdentity Providerへの認証リクエストに署名できるようになりました。

## SAMLグループ {#saml-groups}

SAMLグループを使用すると、SAMLグループメンバーシップに基づいてGitLabユーザーを設定できます。

SAMLグループを有効にするには、[必要な要素](../../../../integration/saml.md#configure-users-based-on-saml-group-membership)を[スイッチボード](#add-a-saml-provider-with-switchboard)のSAML設定に追加するか、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)で提供するSAMLブロックに追加します。

## グループ同期 {#group-sync}

[グループ同期](../../../../user/group/saml_sso/group_sync.md)を使用すると、Identity Providerグループ間でユーザーをGitLab内のマップされたグループに同期できます。

グループ同期を有効にするには:

1. [必要な要素](../../../../user/group/saml_sso/group_sync.md#configure-saml-group-sync)を[スイッチボード](#add-a-saml-provider-with-switchboard)のSAML設定に追加するか、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)で提供するSAML設定ブロックに追加します。
1. [グループリンク](../../../../user/group/saml_sso/group_sync.md#configure-saml-group-links)を設定します。
