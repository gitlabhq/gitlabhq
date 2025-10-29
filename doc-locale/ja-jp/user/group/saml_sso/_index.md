---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab.comグループのSAML SSO
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< alert type="note" >}}

GitLab Self-Managedについては、[GitLab Self-ManagedのSAML SSO](../../../integration/saml.md)を参照してください。

{{< /alert >}}

ユーザーは、SAML Identity Providerを使用してGitLabにサインインできます。

[SCIM](scim_setup.md)は、GitLab.comのグループとユーザーを同期します。

- SCIMアプリでユーザーを追加または削除すると、SCIMはGitLabグループからユーザーを追加または削除します。
- ユーザーがまだグループメンバーでない場合は、サインインプロセスの一部としてユーザーがグループに追加されます。

SAML SSOは、トップレベルグループに対してのみ設定できます。

## Identity Providerを設定する {#set-up-your-identity-provider}

SAML標準は、GitLabで幅広いIdentity Providerを使用できることを意味します。Identity Providerには関連ドキュメントがある場合があります。一般的なSAMLドキュメントの場合もあれば、GitLabを対象とする場合もあります。

Identity Providerを設定するときは、使用される用語のガイドとして次のプロバイダー固有のドキュメントを参照して、一般的な問題を回避してください。

リストにないIdPについては、プロバイダーが必要とする可能性のある情報に関する追加ガイダンスとして、[インスタンスSAMLのIdentity Provider設定に関する注記](../../../integration/saml.md#configure-saml-on-your-idp)を参照してください。

GitLabは、ガイダンスのみを目的として、次の情報を提供します。SAMLアプリの設定に関する質問がある場合は、プロバイダーのサポートにお問い合わせください。

Identity Providerの設定で問題が発生した場合は、[トラブルシューティングのドキュメント](#troubleshooting)を参照してください。

### Azure {#azure}

AzureをIdentity ProviderとしてSSOを設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **SAML SSO**を選択します。
1. このページにある情報を書き留めます。
1. Azureに移動して、[非ギャラリーアプリケーションを作成](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/overview-application-gallery#create-your-own-application)し、[アプリケーションのSSOを設定](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso)します。次のGitLab設定はAzureフィールドに対応しています。

   | GitLab設定                           | Azureフィールド                                    |
   | -----------------------------------------| ---------------------------------------------- |
   | **識別子**                           | **Identifier (Entity ID)**（識別子（エンティティID））                     |
   | **アサーションコンシューマーサービスURL**       | **Reply URL (Assertion Consumer Service URL)**（応答URL（アサーションコンシューマサービスURL）） |
   | **GitLabシングルサインオンのURL**            | **Sign on URL**（サインオンURL）                                |
   | **アイデンティティプロバイダのシングルサインオンURL** | **Login URL**（ログインURL）                                  |
   | **証明書のフィンガープリント**              | **Thumbprint**（サムプリント）                                 |

1. 次の属性を設定する必要があります:
   - **Unique User Identifier (Name ID)**（一意のユーザー識別子（名前ID））を`user.objectID`にします。
      - **Name identifier format**（名前識別子形式）を`persistent`にします。詳細については、[ユーザーSAMLアイデンティティの管理](#manage-user-saml-identity)を参照してください。
   - **Additional claims**（追加のクレーム）を[サポートされる属性](#configure-assertions)に追加します。

1. Identity Providerが、プロバイダーによって開始された呼び出しで既存のGitLabアカウントにリンクするように設定されていることを確認します。

1. オプション。[グループ同期](group_sync.md)を使用している場合は、グループクレームの名前を必要な属性と一致するようにカスタマイズします。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [SCIM Provisioning on Azure Using SAML SSO for Groups Demo](https://youtu.be/24-ZxmTeEBU)をご覧ください。この動画では、`objectID`マッピングは古くなっています。代わりに、[SCIMドキュメント](scim_setup.md#configure-microsoft-entra-id-formerly-azure-active-directory)に従ってください。

詳細については、[Azure設定の例](example_saml_config.md#azure-active-directory)を参照してください。

### Google Workspace {#google-workspace}

Google WorkspaceをIdentity Providerとして設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **SAML SSO**を選択します。
1. このページにある情報を書き留めます。
1. [GoogleをIdentity ProviderとしてSSOを設定](https://support.google.com/a/answer/6087519?hl=en)するための手順に従います。次のGitLab設定はGoogle Workspaceフィールドに対応しています。

   | GitLab設定                           | Google Workspaceフィールド |
   |:-----------------------------------------|:-----------------------|
   | **識別子**                           | **エンティティID**          |
   | **アサーションコンシューマーサービスURL**       | **ACS URL**（ACS URL）            |
   | **GitLabシングルサインオンのURL**            | **Start URL**（開始URL）          |
   | **アイデンティティプロバイダのシングルサインオンURL** | **SSO URL**（SSO URL）            |

1. 証明書を取得すると、Google WorkspaceでSHA256フィンガープリントが表示されます。後でSHA256フィンガープリントを生成する必要がある場合は、[フィンガープリントを計算する](troubleshooting.md#calculate-the-fingerprint)を参照してください。

1. これらの値を設定します:
   - **プライマリーメール**の場合: `email`。
   - **お名前(名)**の場合: `first_name`。
   - **お名前(姓)**の場合: `last_name`。
   - **Name ID format**（名前ID形式）の場合: `EMAIL`。
   - **NameID**の場合: `Basic Information > Primary email`。詳細については、[サポートされる属性](#configure-assertions)を参照してください。

1. Identity Providerが、プロバイダーによって開始された呼び出しで既存のGitLabアカウントにリンクするように設定されていることを確認します。

GitLab SAML SSOページで、**SAML構成の確認**を選択したときに、**NameID**形式を`persistent`に設定することを推奨する警告を無視します。

詳細については、[Google Workspace設定の例](example_saml_config.md#google-workspace)を参照してください。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Google WorkspaceでSAMLを設定し、グループ同期を設定する方法](https://youtu.be/NKs0FSQVfCY)のデモをご覧ください。

### Okta {#okta}

OktaをIdentity ProviderとしてSSOを設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **SAML SSO**を選択します。
1. このページにある情報を書き留めます。
1. [OktaでSAMLアプリケーションを設定](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/)するための手順に従います。

   次のGitLab設定はOktaフィールドに対応しています。

   | GitLab設定                           | Oktaフィールド                                                     |
   | ---------------------------------------- | -------------------------------------------------------------- |
   | **識別子**                           | **Audience URI**（オーディエンスURI）                                               |
   | **アサーションコンシューマーサービスURL**       | **Single sign-on URL**（シングルサインオンURL）                                         |
   | **GitLabシングルサインオンのURL**            | **Login page URL**（ログインページURL）（**Application Login Page**（アプリケーションログインページ）設定の下） |
   | **アイデンティティプロバイダのシングルサインオンURL** | **Identity Provider Single Sign-On URL**（Identity ProviderのシングルサインオンURL）                       |

1. Oktaの**Single sign-on URL**（シングルサインオンURL）フィールドで、**Use this for Recipient URL and Destination URL**（これを受信者URLおよび宛先URLに使用する）チェックボックスをオンにします。

1. これらの値を設定します:
   - **Application username (NameID)**（アプリケーションユーザー名（NameID））の場合: **カスタム**`user.getInternalProperty("id")`。
   - **Name ID Format**（名前ID形式）の場合: `Persistent`。詳細については、[ユーザーSAMLアイデンティティの管理](#manage-user-saml-identity)を参照してください。
   - **email**（メール）の場合: `user.email`など。
   - 追加の**Attribute Statements**（属性ステートメント）については、[サポートされる属性](#configure-assertions)を参照してください。

1. Identity Providerが、プロバイダーによって開始された呼び出しで既存のGitLabアカウントにリンクするように設定されていることを確認します。

App Catalogで利用可能なOkta GitLabアプリケーションは、[SCIM](scim_setup.md)のみをサポートします。SAMLのサポートは、[イシュー216173](https://gitlab.com/gitlab-org/gitlab/-/issues/216173)で提案されています。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> SCIMを含むOkta SAML設定のデモについては、[Demo: Okta Group SAML & SCIM setup](https://youtu.be/0ES9HsZq0AQ)（デモ: OktaグループSAMLとSCIMの設定）をご覧ください。

詳細については、[Okta設定の例](example_saml_config.md#okta)を参照してください。

### OneLogin {#onelogin}

OneLoginは、独自の[GitLab（SaaS）アプリケーション](https://onelogin.service-now.com/support?id=kb_article&sys_id=08e6b9d9879a6990c44486e5cebb3556&kb_category=50984e84db738300d5505eea4b961913)をサポートしています。

OneLoginをIdentity Providerとして設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **SAML SSO**を選択します。
1. このページにある情報を書き留めます。
1. OneLoginの一般的な[SAML Test Connector (Advanced)](https://onelogin.service-now.com/support?id=kb_article&sys_id=b2c19353dbde7b8024c780c74b9619fb&kb_category=93e869b0db185340d5505eea4b961934)を使用する場合は、[OneLogin SAML Test Connectorを使用](https://onelogin.service-now.com/support?id=kb_article&sys_id=93f95543db109700d5505eea4b96198f)する必要があります。次のGitLab設定はOneLoginフィールドに対応しています:

   | GitLab設定                                       | OneLoginフィールド                   |
   | ---------------------------------------------------- | -------------------------------- |
   | **識別子**                                       | **オーディエンス**                     |
   | **アサーションコンシューマーサービスURL**                   | **Recipient**（受信者）                    |
   | **アサーションコンシューマーサービスURL**                   | **ACS (Consumer) URL**（ACS（コンシューマ）URL）           |
   | **Assertion consumer service URL (escaped version)**（アサーションコンシューマサービスURL（エスケープされたバージョン）） | **ACS (Consumer) URL Validator**（ACS（コンシューマ）URLバリデーター） |
   | **GitLabシングルサインオンのURL**                        | **Login URL**（ログインURL）                    |
   | **アイデンティティプロバイダのシングルサインオンURL**             | **SAML 2.0 Endpoint**（SAML 2.0エンドポイント）            |

1. **NameID**には、`OneLogin ID`を使用します。詳細については、[ユーザーSAMLアイデンティティの管理](#manage-user-saml-identity)を参照してください。
1. [必須およびサポートされる属性](#configure-assertions)を設定します。
1. Identity Providerが、プロバイダーによって開始された呼び出しで既存のGitLabアカウントにリンクするように設定されていることを確認します。

詳細については、[OneLogin設定の例](example_saml_config.md#onelogin)を参照してください。

### Keycloak {#keycloak}

KeycloakをIdentity Providerとして設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **SAML SSO**を選択します。
1. このページにある情報を書き留めます。
1. [KeycloackでSAMLクライアントを作成する](https://www.keycloak.org/docs/latest/server_admin/index.html#_client-saml-configuration)ための手順に従います。

次のGitLab設定はKeycloakフィールドに対応しています。

   | GitLab設定                           | Keycloakフィールド                          |
   |:-----------------------------------------|:------------------------------------------------|
   | **識別子**                           | **クライアントID**                                   |
   | **アサーションコンシューマーサービスURL**       | **Valid redirect URIs**（有効なリダイレクトURI）                         |
   | **アサーションコンシューマーサービスURL**       | **Assertion Consumer Service POST Binding URL**（アサーションコンシューマサービスPOSTバインディングURL） |
   | **GitLabシングルサインオンのURL**            | **Home URL**（ホームURL）                                    |

1. KeycloakでGitLabクライアントを設定します。
   1. Keycloakで、**クライアント**に移動し、GitLabクライアントの設定を選択します。
   1. **設定**タブの**SAML capabilities**（SAML機能）セクションで、次のようにします:
      1. **Name ID format**（名前ID形式）を`persistent`に設定します。
      1. **Force name ID format**（名前ID形式の強制）をオンにします。
      1. **Force POST binding**（POSTバインディングの強制）をオンにします。
      1. **Include AuthnStatement**（AuthnStatementを含める）をオンにします。
   1. **Signature and Encryption**（署名と暗号化）セクションで、**Sign documents**（ドキュメントに署名）をオンにします。
   1. **キー**タブで、すべてのセクションが無効になっていることを確認します。
   1. **Client scopes**（クライアントスコープ）タブで、次のようにします:
      1. GitLabのクライアントスコープを選択します。
      1. `email` AttributeStatementを選択します。
      1. **User Attribute**（ユーザー属性）フィールドを`email`に設定します。
      1. **保存**を選択します。
1. Keycloakからクライアント情報を取得します。
   1. **アクション**ドロップダウンリストで、**Download adapter config**（アダプター設定のダウンロード）を選択します。
   1. **Download adapter config**（アダプター設定のダウンロード）ダイアログで、ドロップダウンリストから**mod-auth-mellon**（mod-auth-mellon）を選択します。
   1. **ダウンロード**を選択します。
   1. ダウンロードしたアーカイブを解凍し、`idp-metadata.xml`を開きます。
   1. Identity ProviderのシングルサインオンURLを取得します。
      1. `<md:SingleSignOnService>`タグを探します。
      1. `Location`属性の値を書き留めます。
   1. 証明書フィンガープリントを取得します。
      1. `<ds:X509Certificate>`タグの値を書き留めます。
      1. 値を[PEM形式](https://www.ssl.com/guide/pem-der-crt-and-cer-x-509-encodings-and-conversions/#ftoc-heading-3)に変換します。
      1. [フィンガープリントを計算します](troubleshooting.md#calculate-the-fingerprint)。

### アサーションを設定する {#configure-assertions}

{{< alert type="note" >}}

これらの属性では、大文字と小文字は区別されません。

{{< /alert >}}

少なくとも、次のアサーションを設定する必要があります:

1. [NameID](#manage-user-saml-identity)。
1. メール。

オプションで、SAMLアサーションの属性としてユーザー情報をGitLabに渡すことができます。

- ユーザーのメールアドレスは、**email**（email）属性または**mail**（mail）属性にすることができます。
- ユーザー名は、**ユーザー名**属性または**nickname**（nickname）属性にすることができます。これらのいずれか1つだけを指定する必要があります。

使用可能な属性の詳細については、[GitLab Self-ManagedのSAML SSO](../../../integration/saml.md#configure-assertions)を参照してください。

### メタデータを使用する {#use-metadata}

一部のIdentity Providerを設定するには、GitLabメタデータURLが必要です。このURLを見つけるには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **SAML SSO**を選択します。
1. 指定された**GitLabメタデータURL**をコピーします。
1. Identity Providerのドキュメントに従い、要求されたらメタデータURLを貼り付けます。

Identity ProviderがGitLabメタデータURLをサポートしているかどうかを確認するには、そのドキュメントを確認してください。

### Identity Providerを管理する {#manage-the-identity-provider}

Identity Providerを設定した後、次のことができます:

- Identity Providerを変更します。
- Eメールのドメインを変更します。

#### Identity Providerを変更する {#change-the-identity-provider}

別のIdentity Providerに変更できます。変更処理中、ユーザーはSAMLグループにアクセスできません。これを軽減するには、[SSOの強制](#sso-enforcement)を無効にすることができます。

Identity Providerを変更するには:

1. 新しいIdentity Providerでグループを[設定](#set-up-your-identity-provider)します。
1. オプション。**NameID**が同一でない場合は、[ユーザーの**NameID**を変更](#manage-user-saml-identity)します。

#### Eメールドメインを変更する {#change-email-domains}

ユーザーを新しいEメールのドメインに移行するには、次の手順を実行するようにユーザーに指示します:

1. [新しいメールをアカウントにプライマリメールとして追加](../../profile/_index.md#change-your-primary-email)して、検証します。
1. オプション。アカウントから古いメールを削除します。

**NameID**がメールアドレスで設定されている場合は、[ユーザーの**NameID**を変更](#manage-user-saml-identity)します。

## GitLabを設定する {#configure-gitlab}

{{< history >}}

- デフォルトのメンバーシップロールとしてカスタムロールを設定する機能は、GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/417285)されました。

{{< /history >}}

GitLabでIdentity Providerを使用するように設定したら、認証に使用するようにGitLabを設定する必要があります:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **SAML SSO**を選択します。
1. フィールドに入力します:
   - **アイデンティティプロバイダのシングルサインオンURL**フィールドに、Identity ProviderからのSSO URLを入力します。
   - **証明書のフィンガープリント**フィールドに、SAMLトークン署名証明書フィンガープリントを入力します。
1. GitLab.comのグループの場合: **デフォルトのメンバーシップロール**フィールドで、以下を選択します:
   1. 新しいユーザーに割り当てるロール。
   1. SAMLグループリンクがグループに設定されているときに、[マップされたSAMLグループのメンバーではないユーザー](group_sync.md#automatic-member-removal)に割り当てるロール。
1. GitLab Self-Managedインスタンスのグループの場合: **デフォルトのメンバーシップロール**フィールドで、新しいユーザーに割り当てるロールを選択します。デフォルトロールは**ゲスト**です。そのロールは、グループに追加されたすべてのユーザーの開始ロールになります:
   - GitLab 16.7以降では、グループのオーナーは[カスタムロール](../../custom_roles/_index.md)を設定できます。
   - GitLab 16.6以前では、グループオーナーは、デフォルトのメンバーシップロールとして、**ゲスト**以外のデフォルトのメンバーシップロールを設定できます。
1. **このグループのSAML認証を有効にします**チェックボックスを選択します。
1. （推奨）以下を選択します:
   - GitLab 17.4以降では、**Enterpriseユーザーのパスワード認証を無効にする**。詳細については、[Enterpriseユーザーのパスワード認証を無効にすることに関するドキュメント](#disable-password-authentication-for-enterprise-users)を参照してください。
   - **このグループのWEBアクティビティーにSSOのみの認証を適用します**。
   - **このグループのGitおよび依存プロキシのアクティビティーに対してSSOのみの認証を実施する**。詳細については、[SSOの強制に関するドキュメント](#sso-enforcement)を参照してください。
1. **変更を保存**を選択します。

GitLabの設定で問題が発生した場合は、[トラブルシューティングドキュメント](#troubleshooting)を参照してください。

## ユーザーアクセスと管理 {#user-access-and-management}

グループSSOが設定され、有効になった後、ユーザーはIdentity ProviderのダッシュボードからGitLab.comグループにアクセスできます。[SCIM](scim_setup.md)が設定されている場合は、SCIMページの[ユーザーアクセス](scim_setup.md#user-access)を参照してください。

ユーザーがグループSSOでサインインしようとすると、GitLabは次の情報に基づいてユーザーを検索または作成しようとします:

- 一致するSAMLアイデンティティを持つ既存のユーザーを検索します。これは、ユーザーのアカウントが[SCIM](scim_setup.md)によって作成されたか、グループのSAML IdPで以前にサインインしたことを意味します。
- 同じメールアドレスのアカウントがまだ存在しない場合は、新しいアカウントを自動的に作成します。GitLabは、プライマリとセカンダリの両方のメールアドレスを照合しようとします。
- 同じメールアドレスのアカウントが既に存在する場合は、サインインページにリダイレクトして、次の操作を行います:
  - 別のメールアドレスで新しいアカウントを作成します。
  - 既存のアカウントにサインインして、SAML IDをリンクします。

### SAMLを既存のGitLab.comアカウントにリンクする {#link-saml-to-your-existing-gitlabcom-account}

{{< history >}}

- **ログイン情報を記憶する**チェックボックスは、GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/121569)されました。

{{< /history >}}

{{< alert type="note" >}}

ユーザーがそのグループの[Enterpriseユーザー](../../enterprise_user/_index.md)である場合、以下の手順は適用されません。代わりに、Enterpriseユーザーは[GitLabアカウントと同じメールアドレスを持つSAMLアカウントでサインイン](#automatic-identity-linking-for-enterprise-users)する必要があります。これにより、GitLabはSAMLアカウントを既存のアカウントにリンクできます。

{{< /alert >}}

SAMLを既存のGitLab.comアカウントにリンクするには:

1. GitLab.comアカウントにサインインします。必要に応じて、[パスワードをリセット](https://gitlab.com/users/password/new)します。
1. サインインするグループの**GitLabシングルサインオンのURL**を見つけてアクセスします。グループの**設定** > **SAML SSO**ページで、グループのオーナーがこれを見つけることができます。サインインURLが設定されている場合、ユーザーはIdentity ProviderからGitLabアプリケーションに接続できます。
1. オプション。**ログイン情報を記憶する**チェックボックスを選択すると、GitLabへのサインイン状態が2週間維持されます。SAMLプロバイダーによる再認証が、より頻繁に求められる場合があります。
1. **許可する**を選択します。
1. プロンプトが表示されたら、Identity Providerで認証情報を入力します。
1. その後、GitLab.comにリダイレクトされ、グループにアクセスできるようになります。今後は、SAMLを使用してGitLab.comにサインインできます。

ユーザーが既にグループのメンバーである場合、SAML IDをリンクしてもロールは変更されません。

以降のアクセスでは、[SAMLでGitLab.comにサインイン](#sign-in-to-gitlabcom-with-saml)するか、リンクに直接アクセスできるようになります。**enforce SSO**（SSOの強制）オプションがオンになっている場合は、Identity Provider経由でサインインするようにリダイレクトされます。

#### エンタープライズユーザーの自動アイデンティティリンキング {#automatic-identity-linking-for-enterprise-users}

Enterpriseユーザーがグループから削除された後、復帰した場合、エンタープライズSSOアカウントでサインインできます。Identity Providerのユーザーのメールアドレスが既存のGitLabアカウントのメールアドレスと同じままである限り、SSO IDはアカウントに自動的にリンクされ、ユーザーは問題なくサインインできます。この機能は、エンタープライズユーザーとして要求されたものの、まだグループにサインインしていない既存のユーザーにも適用されます。

### SAMLでGitLab.comにサインインする {#sign-in-to-gitlabcom-with-saml}

1. Identity Providerにサインインします。
1. アプリケーションのリストから、「GitLab.com」アプリケーションを選択します（名前は、Identity Providerの管理者によって設定されます）。
1. その後、GitLab.comにサインインすると、グループにリダイレクトされます。

### ユーザーSAML IDの管理 {#manage-user-saml-identity}

{{< history >}}

- SAML APIを使用したSAML IDの更新は、GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/227841)されました。

{{< /history >}}

GitLab.comは、SAML **NameID**を使用してユーザーを識別します。**NameID**は、次のとおりです:

- SAML応答の必須フィールド。
- 大文字と小文字を区別しません。

**NameID**は、次の条件を満たす必要があります:

- 各ユーザーに固有であること。
- ランダムに生成された一意のユーザーIDなど、決して変更されない永続的な値であること。
- 以降のサインイン試行で完全に一致させる必要があります。大文字と小文字の間で変化する可能性のあるユーザーインプットに依存しないでください。

**NameID**は、次の理由により、メールアドレスまたはユーザー名にしないでください:

- メールアドレスとユーザー名は、時間の経過とともに変更される可能性が高くなります。たとえば、人の名前が変わる場合などです。
- メールアドレスでは大文字と小文字が区別されないため、ユーザーがサインインできなくなる可能性があります。

**NameID**形式は、別の形式を必要とするメールなどのフィールドを使用していない限り、`Persistent`である必要があります。`Transient`を除く、任意の形式を使用できます。

#### ユーザー**NameID**を変更する {#change-user-nameid}

グループオーナーは、[SAML API](../../../api/saml.md#update-extern_uid-field-for-a-saml-identity)を使用して、グループメンバーの**NameID**を変更し、SAML IDを更新できます。

[SCIM](scim_setup.md)が設定されている場合、グループオーナーは[SCIM API](../../../api/scim.md#update-extern_uid-field-for-a-scim-identity)を使用してSCIM IDを更新できます。

または、ユーザーにSAMLアカウントの再接続を依頼します。

1. 関係するユーザーに、[アカウントをグループからアンリンク](#unlink-accounts)するように依頼します。
1. 関係するユーザーに、[アカウントを新しいSAMLアプリケーションにリンク](#link-saml-to-your-existing-gitlabcom-account)するように依頼します。

{{< alert type="warning" >}}

ユーザーがSSO SAMLを使用してGitLabにサインインした後、**NameID**の値を変更すると設定が中断され、ユーザーがGitLabグループからロックアウトされる可能性があります。

{{< /alert >}}

特定のIdentity Providerに推奨される値と形式の詳細については、[Identity Providerのセットアップ](#set-up-your-identity-provider)を参照してください。

### SAMLレスポンスからEnterpriseユーザー設定を構成する {#configure-enterprise-user-settings-from-saml-response}

{{< history >}}

- GitLab 16.7で、Enterpriseユーザー設定のみを構成するように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/412898)されました。

{{< /history >}}

GitLabでは、SAML応答の値に基づいて、特定のユーザー属性を設定できます。既存のユーザーの属性は、そのユーザーがグループの[Enterpriseユーザー](../../enterprise_user/_index.md)である場合、SAML応答の値から更新されます。

#### サポートされているユーザー属性 {#supported-user-attributes}

- **can_create_group**（can_create_group） - Enterpriseユーザーが新しいトップレベルグループを作成できるかどうかを示す`true`または`false`。デフォルトは`true`です。
- **projects_limit**（projects_limit） - Enterpriseユーザーが作成できる個人プロジェクトの総数。`0`の値は、ユーザーが自分の個人ネームスペースに新しいプロジェクトを作成できないことを意味します。デフォルトは`100000`です。
- **SessionNotOnOrAfter**（SessionNotOnOrAfter） - ユーザーSAMLセッションを終了するタイミングを示すISO 8601タイムスタンプ値。

#### SAML応答の例 {#example-saml-response}

SAML応答は、ブラウザのデベロッパーツールまたはコンソールで、base64エンコード形式で確認できます。任意のbase64デコードツールを使用して、情報をXMLに変換します。SAML応答の例を次に示します。

```xml
   <saml2:AttributeStatement>
      <saml2:Attribute Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.email</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="username" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.nickName</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="first_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.firstName</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="last_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.lastName</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="can_create_group" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">true</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="projects_limit" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">10</saml2:AttributeValue>
      </saml2:Attribute>
   </saml2:AttributeStatement>
```

### SAMLセッションのタイムアウトをカスタマイズする {#customize-saml-session-timeout}

{{< history >}}

- GitLab 18.2で`saml_timeout_supplied_by_idp_override`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/262074)されました。

{{< /history >}}

デフォルトでは、GitLabのSAMLセッションは24時間後に終了します。SAML2 AuthnStatementの`SessionNotOnOrAfter`属性を使用して、この期間をカスタマイズできます。この属性には、ユーザーセッションを終了するタイミングを示すISO 8601タイムスタンプ値が含まれています。指定された場合、この値はSAMLセッションのデフォルトのタイムアウト（24時間）をオーバーライドします。

GitLabではデフォルトで、非アクティブ状態が7日間（10080分）続くとセッションが終了します。`SessionNotOnOrAfter`タイムスタンプがこの時間を過ぎている場合、ユーザーはセッションが終了したときに再度認証する必要があります。

#### レスポンス例 {#example-response}

```xml
   <saml:AuthnStatement SessionIndex="WDE5aBYjNEj_9IjCFiK0E1YelZT" SessionNotOnOrAfter="2025-08-25T01:23:45.067Z" AuthnInstant="2025-08-24T13:23:45.067Z">
      <saml:AuthnContext>
         <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified</saml:AuthnContextClassRef>
      </saml:AuthnContext>
   </saml:AuthnStatement>
```

### 検証済みドメインによるユーザーメール確認を回避する {#bypass-user-email-confirmation-with-verified-domains}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/238461)されました。

{{< /history >}}

デフォルトでは、SAMLまたはSCIMでプロビジョニングされたユーザーには、IDを検証するための検証メールが送信されます。代わりに、[GitLabをカスタムドメインで設定](../../enterprise_user/_index.md#add-group-domains)すると、GitLabはユーザーアカウントを自動的に確認します。ユーザーは引き続き[Enterprise](../../enterprise_user/_index.md)ユーザーのウェルカムメールを受信します。次の両方が当てはまる場合、確認は回避されます:

- ユーザーはSAMLまたはSCIMでプロビジョニングされる。
- ユーザーのメールアドレスが検証済みドメインに属している。

### Enterpriseユーザーのパスワード認証を無効にする {#disable-password-authentication-for-enterprise-users}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/373718)されました。

{{< /history >}}

前提要件:

- Enterpriseユーザーが所属するグループのオーナーロールを持っている必要があります。
- グループSSOを有効にする必要があります。

グループ内のすべての[エンタープライズユーザー](../../enterprise_user/_index.md)に対して、パスワード認証を無効にできます。これは、グループの管理者であるEnterpriseユーザーにも適用されます。この設定を構成すると、Enterpriseユーザーはパスワードの変更、リセット、またはパスワードによる認証ができなくなります。代わりに、これらのユーザーは以下で認証できます:

- GitLab Web UIのグループSAML IdP。
- グループで[Enterpriseユーザーのパーソナルアクセストークンが無効になっている](../../profile/personal_access_tokens.md#disable-personal-access-tokens-for-enterprise-users)場合を除き、GitLab APIおよびHTTP基本認証を使用するGitのパーソナルアクセストークン。

Enterpriseユーザーのパスワード認証を無効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **SAML SSO**を選択します。
1. **設定**で、**Enterpriseユーザーのパスワード認証を無効にする**を選択します。
1. **変更を保存**を選択します。

### ユーザーアクセスのブロック {#block-user-access}

SAML SSOのみが設定されている場合に、ユーザーのグループへのアクセスを取り消すには、次のいずれかの操作を行います:

- ユーザーを以下から（順番に）削除します:
  1. Identity Providerのユーザーデータストアまたは特定のアプリケーションのユーザーリスト。
  1. GitLab.comグループ。
- [最小アクセス](../../permissions.md#users-with-minimal-access)に設定されたデフォルトロールを使用して、グループのトップレベルで[グループ同期](group_sync.md#automatic-member-removal)を使用し、グループ内のすべてのリソースへのアクセスを自動的にブロックします。

SCIMも使用している場合に、ユーザーのグループへのアクセスを取り消すには、[アクセスの削除](scim_setup.md#remove-access)を参照してください。

### アカウントのアンリンク {#unlink-accounts}

ユーザーは、プロファイルページからグループのSAMLをアンリンクできます。これは、次の場合に役立ちます:

- グループがGitLab.comへのサインインを許可されないようにする場合。
- SAML **NameID**が変更されたため、GitLabがユーザーを見つけられなくなった場合。

{{< alert type="warning" >}}

アカウントをアンリンクすると、グループ内のそのユーザーに割り当てられているすべてのロールが削除されます。ユーザーがアカウントを再リンクする場合、ロールを再割り当てする必要があります。

{{< /alert >}}

グループには、少なくとも1人のオーナーが必要です。アカウントがグループ内の唯一のオーナーである場合、アカウントのアンリンクは許可されません。その場合は、別のユーザーをグループオーナーとして設定してから、アカウントをアンリンクできます。

たとえば、`MyOrg`アカウントをアンリンクするには:

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アカウント**を選択します。
1. **サインインに利用するサービス**セクションで、接続されているアカウントの横にある**切断**を選択します。

## SSOの強制 {#sso-enforcement}

{{< history >}}

- GitLab 15.5で、`transparent_sso_enforcement`[フラグ](../../../administration/feature_flags/_index.md)とともに、SSOの強制が有効になっていない場合でも透過的な強制を含めるように[改善](https://gitlab.com/gitlab-org/gitlab/-/issues/215155)されました。GitLab.comで無効になりました。
- GitLab 15.8で、GitLab.comでの透過的なSSOがデフォルトで有効になるように[で改善](https://gitlab.com/gitlab-org/gitlab/-/issues/375788)されました。
- GitLab 15.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/389562)になりました。機能フラグ`transparent_sso_enforcement`は削除されました。

{{< /history >}}

GitLab.comでは、SSOが次の場合に強制されます:

- SAML SSOが有効になっている場合。
- 組織のグループ階層内のグループとプロジェクトにアクセスするときに、既存のSAML IDを持つユーザーの場合。GitLab.comの認証情報を使用することで、ユーザーはSAML SSOを使用してサインインしなくても、組織外の他のグループやプロジェクト、およびユーザー設定を表示できます。

ユーザーは、次のいずれかまたは両方が当てはまる場合に、SAML IDを持ちます:

- GitLabグループのシングルサインオンURLを使用してGitLabにサインインしたことがある。
- SCIMによってプロビジョニングされた。

ユーザーはアクセスするたびにSSOによるサインインを求められることはありません。GitLabは、ユーザーがSSOを使用して認証されているかどうかを確認します。ユーザーが最後にサインインしてから24時間以上経過した場合、GitLabはSSOを使用して再度サインインするように求めます。

SSOは次のように強制されます:

| プロジェクト/グループの表示レベル | SSOの強制設定 | IDを持つメンバー | IDを持たないメンバー | メンバーではないか、サインインしていない |
|--------------------------|---------------------|----------------------|-------------------------|-----------------------------|
| 非公開                  | オフ                 | 強制             | 強制されない            | 強制されない                |
| 非公開                  | オン                  | 強制             | 強制                | 強制                    |
| 公開                   | オフ                 | 強制             | 強制されない            | 強制されない                |
| 公開                   | オン                  | 強制             | 強制                | 強制されない                |

APIアクティビティーに対して同様のSSO要求事項を追加するための[イシューが存在](https://gitlab.com/gitlab-org/gitlab/-/issues/297389)します。この要求事項が追加されるまでは、アクティブなSSOセッションなしでAPIに依存する機能を使用できます。

### WEBアクティビティーのSSOのみ強制 {#sso-only-for-web-activity-enforcement}

**このグループのWEBアクティビティーにSSOのみの認証を適用します**オプションが有効になっている場合:

- すべてのメンバーは、既存のSAML IDを持っているかどうかに関係なく、GitLabグループのシングルサインオンURLを使用してGitLabにアクセスし、グループリソースにアクセスする必要があります。
- SSOは、ユーザーが組織のグループ階層内のグループおよびプロジェクトにアクセスするときに強制されます。ユーザーは、SAML SSOを使用してサインインしなくても、組織外の他のグループやプロジェクトを表示できます。
- ユーザーを新しいメンバーとして手動で追加することはできません。
- オーナーロールを持つユーザーは、標準のサインインプロセスを使用して、トップレベルグループの設定に必要な変更を加えることができます。
- メンバーではないユーザー、またはサインインしていないユーザーの場合:
  - パブリックグループのリソースにアクセスする場合、SSOは強制されません。
  - プライベートグループのリソースにアクセスする場合、SSOは強制されます。
- 組織のグループ階層内のアイテムの場合、ダッシュボードの表示レベルは次のようになります:
  - [To-Doリスト](../../todos.md)を表示する場合、SSOが強制されます。SSOセッションが期限切れになるとTo Doアイテムが非表示になり、[アラートが表示](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115254)されます。
  - 割り当て済みのイシューのリストを表示する際に、SSOが適用されます。SSOセッションが期限切れになると、イシューは非表示になります。[イシュー414475](https://gitlab.com/gitlab-org/gitlab/-/issues/414475)では、イシューが表示されるように、この動作を変更することが提案されています。
  - 自分が担当者またはレビュアーである場合、マージリクエストを表示する際に、SSOは強制されません。SSOセッションが期限切れになった場合でも、マージリクエストを表示できます。
  - ゲスト以上のロールを持っている場合、プライベートプロジェクトのスニペットを表示する際に、SSOは強制されません。

WEBアクティビティーに対するSSOの強制を有効にすると、次の影響があります:

- グループの場合、プロジェクトがフォークされている場合でも、ユーザーはトップレベルグループ外でグループ内のプロジェクトを共有できません。
- CI/CDジョブから発生するGitアクティビティーには、SSOチェックは強制されません。
- 通常のユーザーに関連付けられていない認証情報（たとえば、プロジェクトおよびグループアクセストークン、サービスアカウント、デプロイキー）には、SSOチェックは強制されません。
- ユーザーは、[依存プロキシ](../../packages/dependency_proxy/_index.md)を使用してイメージをプルするには、SSOを使用してサインインする必要があります。
- **このグループのGitおよび依存プロキシのアクティビティーに対してSSOのみの認証を実施する**オプションを有効にすると、Gitアクティビティーに関連するAPIエンドポイントはすべてSSO強制の対象になります。たとえば、ブランチ、コミット、タグの作成または削除などです。SSHおよびHTTPS経由のGitアクティビティーの場合、ユーザーがGitLabリポジトリにプッシュまたはプルするには、SSOを使用してサインインしたアクティブなセッションが少なくとも1つ必要です。アクティブなセッションは、別のデバイス上にある可能性があります。

ウェブアクティビティーに対するSSOが強制されている場合、非SSOグループメンバーはすぐにアクセスを失うわけではありません。ユーザーは次のようになります:

- アクティブなセッションを持っている場合、Identity Providerのセッションがタイムアウトするまで、グループへのアクセスを最大24時間継続できます。
- サインアウトした場合、Identity Providerから削除された後はグループにアクセスできません。

## 新しいIdentity Providerへの移行 {#migrate-to-a-new-identity-provider}

新しいIdentity Providerに移行するには、[SAML API](../../../api/saml.md)を使用して、すべてのグループメンバーのIDを更新します。

例:

1. メンテナンス期間を設定して、その時点でアクティブなユーザーがいないようにします。
1. [各ユーザーのIDを更新](../../../api/saml.md#update-extern_uid-field-for-a-saml-identity)するには、SAML APIを使用します。
1. 新しいIdentity Providerを設定します。
1. サインインが機能することを確認します。

## 関連トピック {#related-topics}

- [GitLab Self-ManagedのSAML SSO](../../../integration/saml.md)
- [用語集](../../../integration/saml.md#glossary)
- [ブログ記事: GitLab.comでSAMLとSSOを有効にするための究極のガイド](https://about.gitlab.com/blog/2023/09/14/the-ultimate-guide-to-enabling-saml/)
- [SaaSとSelf-Managed間の認証の比較](../../../administration/auth/_index.md#gitlabcom-compared-to-gitlab-self-managed)
- [統合認証で作成されたユーザーのパスワード](../../../security/passwords_for_integrated_authentication_methods.md)
- [SAMLグループ同期](group_sync.md)

## トラブルシューティング {#troubleshooting}

GitLabとIdentity Provider間で異なるSAML用語を対応させるのが難しい場合:

1. Identity Providerのドキュメントを確認してください。使用する用語に関する情報について、SAML設定の例をご覧ください。
1. [GitLab Self-ManagedドキュメントのSAML SSO](../../../integration/saml.md)を確認してください。GitLab Self-Managed SAML設定ファイルは、GitLab.comファイルよりも多くのオプションをサポートしています。GitLab Self-Managedインスタンスファイルに関する情報は、以下をご覧ください:
   - 外部の[OmniAuth SAMLドキュメント](https://github.com/omniauth/omniauth-saml/)。
   - [`ruby-saml`ライブラリ](https://github.com/onelogin/ruby-saml)。
1. プロバイダーからのXMLレスポンスと、[内部テストで使用されるXMLの例](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/fixtures/saml/response.xml)を比較します。

その他のトラブルシューティング情報については、[SAMLのトラブルシューティングガイド](troubleshooting.md)を参照してください。
