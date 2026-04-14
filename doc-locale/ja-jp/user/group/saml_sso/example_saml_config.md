---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループSAMLとSCIMの設定例
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

これらは、GitLabサポートチームがトラブルシューティング中に使用することがある、グループSAMLおよびSCIMに関するメモとスクリーンショットですが、公式ドキュメントには含まれていません。GitLabはこの情報を公開しており、誰もがサポートチームが収集した知識を利用できるようにしています。

機能に関する情報と設定方法については、GitLabの[Group SAML](_index.md)ドキュメントを参照してください。

SAML設定のトラブルシューティングを行う際、GitLabチームメンバーはしばしば[SAMLトラブルシューティングセクション](_index.md#troubleshooting)から開始します。

その後、目的のIdentity Providerのテスト設定を行う場合があります。このセクションには、スクリーンショットの例が含まれています。

## SAMLおよびSCIMのスクリーンショット {#saml-and-scim-screenshots}

このセクションには、[Group SAML](_index.md)と[Group SCIM](scim_setup.md)の以下の例の設定に関するスクリーンショットが含まれています:

- [Azure Active Directory](#azure-active-directory)
- [AWS IAM Identity Center](#aws-iam-identity-center)
- [Google Workspace](#google-workspace)
- [Okta](#okta)
- [OneLogin](#onelogin)

> [!warning]
> これらのスクリーンショットは、GitLabサポートが必要に応じてのみ更新します。公式ドキュメントでは**ありません**。

現在GitLabで問題が発生している場合は、[サポートオプション](https://about.gitlab.com/support/)を確認することをお勧めします。

## Azure Active Directory {#azure-active-directory}

このセクションには、Azure Active Directory設定の要素に関するスクリーンショットが含まれています。

### 基本SAMLアプリ設定 {#basic-saml-app-configuration}

![Azure AD基本SAML](img/AzureAD-basic_SAML_v14_1.png)

### ユーザーの要求と属性 {#user-claims-and-attributes}

![Azure ADユーザー要求](img/AzureAD-claims_v14_1.png)

### SCIMマッピング {#scim-mapping}

プロビジョニング:

![Azure AD SCIMプロビジョニング](img/AzureAD-scim_provisioning_v14_8.png)

### 属性マッピング {#attribute-mapping}

![Azure AD SCIM属性マッピング](img/AzureAD-scim_attribute_mapping_v12_2.png)

### グループ同期 {#group-sync}

![Azureグループ要求](img/azure_configure_group_claim_v14_0.png)

**グループID**ソース属性を使用するには、ユーザーはSAMLグループリンクを設定する際に、グループIDまたはオブジェクトIDを入力する必要があります。

利用可能な場合は、代わりにユーザーフレンドリーなグループ名を追加できます。Azureグループ要求を設定する際:

1. **sAMAccountName**ソース属性を選択します。
1. グループ名を入力してください。最大256文字の長さを指定できます。
1. 属性がアサーションの一部であることを確認するには、**Emit group names for cloud-only groups**を選択します。

[Azure ADは、SAML応答で送信できるグループの数を150に制限します](https://support.esri.com/en-us/knowledge-base/when-azure-ad-is-the-saml-identify-provider-the-group-a-000022190)。ユーザーが150を超えるグループのメンバーである場合、Azureはそのユーザーのグループ要求をSAML応答に含めません。

## Google Workspace {#google-workspace}

### 基本SAMLアプリ設定 {#basic-saml-app-configuration-1}

![Google Workspace基本SAML](img/GoogleWorkspace-basic-SAML_v14_10.png)

### ユーザーの要求と属性 {#user-claims-and-attributes-1}

![Google Workspaceユーザー要求](img/GoogleWorkspace-claims_v14_10.png)

### IdPリンクと証明書 {#idp-links-and-certificate}

![Google Workspaceリンクと証明書](img/GoogleWorkspace-linkscert_v14_10.png)

## Okta {#okta}

### GitLab.comグループの基本SAMLアプリ設定 {#basic-saml-app-configuration-for-gitlabcom-groups}

![Okta基本SAML](img/Okta-GroupSAML_v15_3.png)

### GitLabセルフマネージドの基本SAMLアプリ設定 {#basic-saml-app-configuration-for-gitlab-self-managed}

![Okta管理者パネルビュー](img/Okta-SM_v15_3.png)

### ユーザーの要求と属性 {#user-claims-and-attributes-2}

![Okta Attributes](img/Okta-attributes_v15_3.png)

### グループ同期 {#group-sync-1}

![Oktaグループ属性](img/Okta-GroupAttribute_v15_3.png)

### 詳細SAMLアプリ設定（デフォルト） {#advanced-saml-app-settings-defaults}

![Okta Advanced Settings](img/Okta-advancedsettings_v15_3.png)

### IdPリンクと証明書 {#idp-links-and-certificate-1}

![Okta Links and Certificate](img/Okta-linkscert_v15_3.png)

### SAMLサインオン設定 {#saml-sign-on-settings}

![Okta SAML設定](img/okta_saml_settings_v15_3.png)

### SCIM設定 {#scim-settings}

SCIMアプリを割り当てる際に、新しくプロビジョニングされたユーザーのユーザー名を設定します:

![OktaでユーザーにSCIMアプリを割り当てる](img/okta_setting_username_v14_6.png)

## OneLogin {#onelogin}

### 基本SAMLアプリ設定 {#basic-saml-app-configuration-2}

![OneLogin application details](img/OneLogin-app_details_v12_8.png)

### パラメータ {#parameters}

![OneLogin application details](img/OneLogin-parameters_v12_8.png)

### ユーザーの追加 {#adding-a-user}

![OneLoginユーザー追加](img/OneLogin-userAdd_v12_8.png)

### SSO設定 {#sso-settings}

![OneLogin SSO設定](img/OneLogin-SSOsettings_v12_8.png)

## AWS IAM Identity Center {#aws-iam-identity-center}

以下の表の値を使用してAWS IAM Identity Centerを設定します。完全なセットアップ手順については、[AWS IAM Identity Center](_index.md#aws-iam-identity-center)を参照してください。

### アプリケーションプロパティ {#application-properties}

AWS IAM Identity Centerで独自のSAML 2.0アプリケーションを設定する際は、以下のアプリケーションプロパティを設定します:

| AWS Identity Centerフィールド       | 値                                                                                         |
| ------------------------------- | --------------------------------------------------------------------------------------------- |
| **Application ACS URL**         | グループの**アサーションコンシューマサービスURL**（GitLab **SAML SSO**設定から）           |
| **Application SAML audience**   | グループの**識別子**（GitLab **SAML SSO**設定から）                               |
| **Application start URL**       | グループの**GitLabシングルサインオンURL**（GitLab **SAML SSO**設定から）                |

SP開始ログインのために**Application start URL**を設定します。これがないと、既存のユーザーはアカウントをリンクできません。

### 属性マッピング {#attribute-mappings}

| 属性      | 値                | 形式        |
| -------------- | -------------------- | ------------- |
| **件名**    | `${user:email}`      | `unspecified` |
| **email**      | `${user:email}`      | `unspecified` |
| **first_name** | `${user:givenName}`  | `unspecified` |
| **last_name**  | `${user:familyName}` | `unspecified` |

> [!warning] 
> **件名** (NameID) の形式を`unspecified`に設定する必要があります。形式を`persistent`または`transient`に設定すると、既存のGitLabユーザーはSAMLを介してアカウントをリンクしようとしたときに`403`エラーを受け取ります。このエラーはアカウントリンク中にのみ発生し、AWS IAM Identity Centerを介してプロビジョニングされた新しいユーザーには影響しません。

### GitLab SAML SSO設定 {#gitlab-saml-sso-settings}

| GitLabフィールド                             | 値                                                                           |
| ---------------------------------------- | ------------------------------------------------------------------------------- |
| **Identity ProviderのシングルサインオンURL** | **IAM Identity Center sign-in URL**（アプリケーションの**IAM Identity Center SAML metadata**セクションから）|
| **証明書フィンガープリント**              | AWS Identity Centerからダウンロードされた証明書のSHA1フィンガープリント         |

## SAML応答の例 {#saml-response-example}

ユーザーがSAMLを使用してサインインすると、GitLabはSAML応答を受け取ります。SAML応答は、base64エンコードされたメッセージとして`production.log`ログにあります。`SAMLResponse`を検索して応答を見つけます。デコードされたSAML応答はXML形式です。例: 

```xml
<?xml version="1.0" encoding="UTF-8"?>
<saml2p:Response xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:xs="http://www.w3.org/2001/XMLSchema" Destination="https://gitlabexample/-/saml/callback" ID="id4898983630840142426821432" InResponseTo="_c65e4c88-9425-4472-b42c-37f4186ac0ee" IssueInstant="2022-05-30T21:30:35.696Z" Version="2.0">
 <saml2:Issuer xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion" Format="urn:oasis:names:tc:SAML:2.0:nameid-format:entity">http://www.okta.com/exk2y6j57o1Pdr2lI8qh7</saml2:Issuer>
 <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
   <ds:SignedInfo>
     <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
     <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
     <ds:Reference URI="#id4898983630840142426821432">
       <ds:Transforms>
         <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
         <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#">
           <ec:InclusiveNamespaces xmlns:ec="http://www.w3.org/2001/10/xml-exc-c14n#" PrefixList="xs"/>
         </ds:Transform>
       </ds:Transforms>
       <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
       <ds:DigestValue>neiQvv9d3OgS4GZW8Nptp4JhjpKs3GCefibn+vmRgk4=</ds:DigestValue>
     </ds:Reference>
   </ds:SignedInfo>
   <ds:SignatureValue>dMsQX8ivi...HMuKGhyLRvabGU6CuPrf7==</ds:SignatureValue>
   <ds:KeyInfo>
     <ds:X509Data>
       <ds:X509Certificate>MIIDq...cptGr3vN9TQ==</ds:X509Certificate>
     </ds:X509Data>
   </ds:KeyInfo>
 </ds:Signature>
 <saml2p:Status xmlns:saml2p="urn:oasis:names:tc:SAML:2.0:protocol">
   <saml2p:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
 </saml2p:Status>
 <saml2:Assertion xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:xs="http://www.w3.org/2001/XMLSchema" ID="id489" IssueInstant="2022-05-30T21:30:35.696Z" Version="2.0">
   <saml2:Issuer xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion" Format="urn:oasis:names:tc:SAML:2.0:nameid-format:entity">http://www.okta.com/exk2y6j57o1Pdr2lI8qh7</saml2:Issuer>
   <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
     <ds:SignedInfo>
       <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
       <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
       <ds:Reference URI="#id48989836309833801859473359">
         <ds:Transforms>
           <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
           <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#">
             <ec:InclusiveNamespaces xmlns:ec="http://www.w3.org/2001/10/xml-exc-c14n#" PrefixList="xs"/>
           </ds:Transform>
         </ds:Transforms>
         <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
         <ds:DigestValue>MaIsoi8hbT9gsi/mNZsz449mUuAcuEWY0q3bc4asOQs=</ds:DigestValue>
       </ds:Reference>
     </ds:SignedInfo>
     <ds:SignatureValue>dMsQX8ivi...HMuKGhyLRvabGU6CuPrf7==<</ds:SignatureValue>
     <ds:KeyInfo>
       <ds:X509Data>
         <ds:X509Certificate>MIIDq...cptGr3vN9TQ==</ds:X509Certificate>
       </ds:X509Data>
     </ds:KeyInfo>
   </ds:Signature>
   <saml2:Subject xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion">
     <saml2:NameID Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent">useremail@domain.com</saml2:NameID>
     <saml2:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
       <saml2:SubjectConfirmationData InResponseTo="_c65e4c88-9425-4472-b42c-37f4186ac0ee" NotOnOrAfter="2022-05-30T21:35:35.696Z" Recipient="https://gitlab.example.com/-/saml/callback"/>
     </saml2:SubjectConfirmation>
   </saml2:Subject>
   <saml2:Conditions xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion" NotBefore="2022-05-30T21:25:35.696Z" NotOnOrAfter="2022-05-30T21:35:35.696Z">
     <saml2:AudienceRestriction>
       <saml2:Audience>https://gitlab.example.com/</saml2:Audience>
     </saml2:AudienceRestriction>
   </saml2:Conditions>
   <saml2:AuthnStatement xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion" AuthnInstant="2022-05-30T21:30:35.696Z" SessionIndex="_c65e4c88-9425-4472-b42c-37f4186ac0ee">
     <saml2:AuthnContext>
       <saml2:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</saml2:AuthnContextClassRef>
     </saml2:AuthnContext>
   </saml2:AuthnStatement>
   <saml2:AttributeStatement xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion">
     <saml2:Attribute Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
       <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">useremail@domain.com</saml2:AttributeValue>
     </saml2:Attribute>
     <saml2:Attribute Name="firstname" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
       <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">John</saml2:AttributeValue>
     </saml2:Attribute>
     <saml2:Attribute Name="lastname" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
       <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Doe</saml2:AttributeValue>
     </saml2:Attribute>
     <saml2:Attribute Name="Groups" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
       <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">Super-awesome-group</saml2:AttributeValue>
     </saml2:Attribute>
   </saml2:AttributeStatement>
 </saml2:Assertion>
</saml2p:Response>
```
