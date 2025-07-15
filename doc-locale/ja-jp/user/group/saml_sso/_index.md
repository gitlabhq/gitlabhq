---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab.com グループの SAML SSO
---

{{< details >}}

- プラン:Premium、Ultimate
- 提供:GitLab.com

{{< /details >}}

ユーザーは、SAML Identity Providerを使用して GitLab にサインインできます。

[SCIM](scim_setup.md) は、GitLab.com のグループとユーザーを同期します。

- SCIM アプリでユーザーを追加または削除すると、SCIM は GitLab グループからユーザーを追加または削除します。
- ユーザーがまだグループメンバーでない場合は、サインインプロセスの一部としてユーザーがグループに追加されます。

SAML SSO は、トップレベルグループに対してのみConfigureできます。

## Identity Provider を設定する

SAML 標準は、GitLab で幅広いIdentity Providerを使用できることを意味します。Identity Providerには関連ドキュメントがある場合があります。一般的な SAML ドキュメントの場合もあれば、GitLab を対象とする場合もあります。

Identity Providerを設定するときは、一般的なイシューを回避し、使用される用語のガイドとして、次のプロバイダー固有のドキュメントを参照してください。

リストにない IdP については、プロバイダーが必要とする可能性のある情報に関する追加ガイダンスとして、[インスタンス SAML の Identity Provider設定に関する注記](../../../integration/saml.md#configure-saml-on-your-idp)を参照してください。

GitLab は、ガイダンスのみを目的として、次の情報を提供します。SAML アプリの設定に関する質問がある場合は、プロバイダーのサポートにお問い合わせください。

Identity Providerの設定でイシューが発生した場合は、[トラブルシューティングのドキュメント](#troubleshooting)を参照してください。

### Azure

Azure を Identity Providerとして SSO を設定するには:

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。
1. **設定 > SAML SSO** を選択します。
1. このページにある情報を書き留めます。
1. Azure に移動して、[非ギャラリーアプリケーションを作成](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/overview-application-gallery#create-your-own-application) し、[アプリケーションの SSO をConfigure](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso)します。次の GitLab 設定は Azure フィールドに対応しています。

   | GitLab 設定                           | Azure フィールド                                    |
   | -----------------------------------------| ---------------------------------------------- |
   | **識別子**                           | **識別子 (エンティティ ID)**                     |
   | **アサーションコンシューマサービスURL**       | **応答 URL (アサーションコンシューマサービスURL)** |
   | **GitLab シングルサインオン URL**            | **サインオン URL**                                |
   | **Identity Providerのシングルサインオン URL** | **ログイン URL**                                  |
   | **証明書フィンガープリント**              | **サムプリント**                                 |

1. 次の属性を設定する必要があります。
   - **一意のユーザー識別子 (名前 ID)** を `user.objectID` にします。
      - **名前識別子形式** を `persistent` にします。詳細については、[ユーザー SAML アイデンティティの管理](#manage-user-saml-identity)を参照してください。
   - **追加のクレーム** を [サポートされる属性](#configure-assertions) に追加します。

1. Identity Providerが、既存の GitLab アカウントにリンクするためのプロバイダーによって開始された呼び出しを行うように設定されていることを確認します。

1. 任意。[グループ同期](group_sync.md)を使用している場合は、グループクレームの名前を必要な属性と一致するようにカスタマイズします。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [グループの SAML SSO を使用した Azure での SCIM プロビジョニング](https://youtu.be/24-ZxmTeEBU)のデモをご覧ください。この動画では、`objectID` マッピングは古くなっています。代わりに、[SCIM ドキュメント](scim_setup.md#configure-microsoft-entra-id-formerly-azure-active-directory)に従ってください。

詳細については、[Azure 設定の例](example_saml_config.md#azure-active-directory)を参照してください。

### Google Workspace

Google Workspace を Identity Providerとして設定するには:

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。
1. **設定 > SAML SSO** を選択します。
1. このページにある情報を書き留めます。
1. [Google を Identity Providerとして SSO を設定](https://support.google.com/a/answer/6087519?hl=en)する手順に従います。次の GitLab 設定は Google Workspace フィールドに対応しています。

   | GitLab 設定                           | Google Workspace フィールド |
   |:-----------------------------------------|:-----------------------|
   | **識別子**                           | **エンティティ ID**          |
   | **アサーションコンシューマサービスURL**       | **ACS URL**            |
   | **GitLab シングルサインオン URL**            | **開始 URL**          |
   | **Identity Providerのシングルサインオン URL** | **SSO URL**            |

1. Google Workspace には SHA256 フィンガープリントが表示されます。[SAML をConfigure](#configure-gitlab)するために GitLab が必要とする SHA1 フィンガープリントを取得するには:
   1. 証明書をダウンロードします。
   1. このコマンドを実行します:

      ```shell
      openssl x509 -noout -fingerprint -sha1 -inform pem -in "GoogleIDPCertificate-domain.com.pem"
      ```

1. これらの値を設定します:
   - **プライマリ メール**の場合: `email`。
   - **名**の場合: `first_name`。
   - **姓**の場合: `last_name`。
   - **名前 ID 形式**の場合: `EMAIL`。
   - **NameID**の場合: `Basic Information > Primary email`。詳細については、[サポートされる属性](#configure-assertions)を参照してください。

1. Identity Providerが、既存の GitLab アカウントにリンクするためのプロバイダーによって開始された呼び出しを行うように設定されていることを確認します。

GitLab SAML SSO ページで、**SAML 設定の検証**を選択したときに、**NameID** 形式を `persistent` に設定することを推奨する警告を無視します。

詳細については、[Google Workspace 設定の例](example_saml_config.md#google-workspace)を参照してください。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Google Workspaces で SAML をConfigureし、グループ同期を設定する方法](https://youtu.be/NKs0FSQVfCY)のデモをご覧ください。

### Okta

Okta を Identity Providerとして SSO を設定するには:

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。
1. **設定 > SAML SSO** を選択します。
1. このページにある情報を書き留めます。
1. [Okta で SAML アプリケーションを設定](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/)する手順に従います。

   次の GitLab 設定は Okta フィールドに対応しています。

   | GitLab 設定                           | Okta フィールド                                                     |
   | ---------------------------------------- | -------------------------------------------------------------- |
   | **識別子**                           | **オーディエンス URI**                                               |
   | **アサーションコンシューマサービスURL**       | **シングルサインオン URL**                                         |
   | **GitLab シングルサインオン URL**            | **ログイン ページ URL** (**アプリケーション ログイン ページ** 設定の下) |
   | **Identity Providerのシングルサインオン URL** | **Identity Providerのシングルサインオン URL**                       |

1. Okta の**シングルサインオン URL**フィールドで、**これを受信者 URL および宛先 URL に使用する** チェックボックスをオンにします。

1. これらの値を設定します:
   - **アプリケーションユーザー名 (NameID)**の場合:**カスタム** `user.getInternalProperty("id")`。
   - **名前 ID 形式**の場合: `Persistent`。詳細については、[ユーザー SAML アイデンティティの管理](#manage-user-saml-identity)を参照してください。
   - **メール**の場合: `user.email` など。
   - 追加の**属性ステートメント**については、[サポートされる属性](#configure-assertions)を参照してください。

1. Identity Providerが、既存の GitLab アカウントにリンクするためのプロバイダーによって開始された呼び出しを行うように設定されていることを確認します。

App Catalog で利用可能な Okta GitLab アプリケーションは、[SCIM](scim_setup.md)のみをサポートします。SAML のサポートは、[イシュー 216173](https://gitlab.com/gitlab-org/gitlab/-/issues/216173) で提案されています。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> SCIM を含む Okta SAML 設定のデモについては、[デモ:を御覧くださいOkta グループ SAML と SCIM の設定](https://youtu.be/0ES9HsZq0AQ)。

詳細については、[Okta 設定の例](example_saml_config.md#okta)を参照してください。

### OneLogin

OneLogin は、独自の[GitLab (SaaS) アプリケーション](https://onelogin.service-now.com/support?id=kb_article&sys_id=08e6b9d9879a6990c44486e5cebb3556&kb_category=50984e84db738300d5505eea4b961913)をサポートしています。

OneLogin を Identity Providerとして設定するには:

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。
1. **設定 > SAML SSO** を選択します。
1. このページにある情報を書き留めます。
1. OneLogin の一般的な[SAML Testコネクター (詳細)](https://onelogin.service-now.com/support?id=kb_article&sys_id=b2c19353dbde7b8024c780c74b9619fb&kb_category=93e869b0db185340d5505eea4b961934)を使用する場合は、[OneLogin SAML Testコネクターを使用](https://onelogin.service-now.com/support?id=kb_article&sys_id=93f95543db109700d5505eea4b96198f)する必要があります。次の GitLab 設定は OneLogin フィールドに対応しています:

   | GitLab 設定                                       | OneLogin フィールド                   |
   | ---------------------------------------------------- | -------------------------------- |
   | **識別子**                                       | **オーディエンス**                     |
   | **アサーションコンシューマサービスURL**                   | **受信者**                    |
   | **アサーションコンシューマサービスURL**                   | **ACS (コンシューマ) URL**           |
   | **アサーションコンシューマサービスURL (エスケープされたバージョン)** | **ACS (コンシューマ) URL バリデーター** |
   | **GitLab シングルサインオン URL**                        | **ログイン URL**                    |
   | **Identity Providerのシングルサインオン URL**             | **SAML 2.0 エンドポイント**            |

1. **NameID**には、`OneLogin ID` を使用します。詳細については、[ユーザー SAML アイデンティティの管理](#manage-user-saml-identity)を参照してください。
1. [必須およびサポートされる属性](#configure-assertions)をConfigureします。
1. Identity Providerが、既存の GitLab アカウントにリンクするためのプロバイダーによって開始された呼び出しを行うように設定されていることを確認します。

詳細については、[OneLogin 設定の例](example_saml_config.md#onelogin)を参照してください。

### アサーションをConfigureする

{{< alert type="note" >}}

これらの属性では、大文字と小文字は区別されません。

{{< /alert >}}

少なくとも、次のアサーションをConfigureする必要があります:

1. [NameID](#manage-user-saml-identity)。
1. メール。

オプションで、SAML アサーションの属性としてユーザー情報を GitLab に渡すことができます。

- ユーザーのメールアドレスは、**email** 属性または **mail** 属性にすることができます。
- ユーザー名は、**ユーザー名** 属性または **ニックネーム** 属性にすることができます。これらのいずれか 1 つだけを指定する必要があります。

使用可能な属性の詳細については、[GitLab Self-Managed の SAML SSO](../../../integration/saml.md#configure-assertions)を参照してください。

### メタデータを使用する

一部の Identity ProviderをConfigureするには、GitLab メタデータ URL が必要です。この URL を見つけるには:

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。
1. **設定 > SAML SSO** を選択します。
1. 指定された **GitLab メタデータ URL** をコピーします。
1. Identity Providerのドキュメントに従い、要求されたらメタデータ URL を貼り付けます。

Identity Providerが GitLab メタデータ URL をサポートしているかどうかを確認するには、そのドキュメントを確認してください。

### Identity Providerを管理する

Identity Providerを設定した後、次のことができます:

- Identity Providerを変更します。
- Eメールドメインを変更します。

#### Identity Providerを変更する

別の Identity Providerに変更できます。変更処理中、ユーザーは SAML グループにアクセスできません。これを軽減するには、[SSO 強制](#sso-enforcement)を無効にすることができます。

Identity Providerを変更するには:

1. 新しい Identity Providerでグループを[Configure](#set-up-your-identity-provider)します。
1. 任意。**NameID** が同一でない場合は、[ユーザーの **NameID** を変更](#manage-user-saml-identity)します。

#### Eメールドメインを変更する

ユーザーを新しい Eメールのドメインに移行するには、次の手順を実行するようにユーザーに指示します:

1. [新しいメールを](../../profile/_index.md#change-your-primary-email)アカウントにプライマリメールとして追加し、検証します。
1. 任意。アカウントから古いメールを削除します。

**NameID** がメールアドレスでConfigureされている場合は、[ユーザーの **NameID** を変更](#manage-user-saml-identity)します。

## GitLab をConfigureする

{{< history >}}

- GitLab 16.7 で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/417285)デフォルトのメンバーシップロールとしてカスタムロールを設定する機能。

{{< /history >}}

GitLab で Identity Providerを使用するように設定したら、認証に使用するように GitLab をConfigureする必要があります:

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。
1. **設定 > SAML SSO** を選択します。
1. フィールドに入力します:
   - **IdP のシングルサインオン URL** フィールドに、Identity Providerからの SSO URL を入力します。
   - **証明書フィンガープリント** フィールドに、SAML トークン署名証明書フィンガープリントを入力します。
1. GitLab.com のグループの場合: **デフォルトのメンバーシップロール** フィールドで、以下を選択します:
   1. 新しいユーザーに割り当てるロール。
   1. SAML グループリンクがグループにConfigureされているときに、[マップされた SAML グループのメンバーではないユーザー](group_sync.md#automatic-member-removal)に割り当てるロール。
1. GitLab Self-Managedインスタンスのグループの場合: **デフォルトのメンバーシップロール** フィールドで、新しいユーザーに割り当てるロールを選択します。デフォルトロールは**ゲスト**です。そのロールは、グループに追加されたすべてのユーザーの開始ロールになります:
   - GitLab 16.7 以降では、グループのオーナーは[カスタムロール](../../custom_roles/_index.md)を設定できます
   - GitLab 16.6 以前では、グループオーナーは、デフォルトのメンバーシップロールとして、**ゲスト**以外のデフォルトのメンバーシップロールを設定できます。
1. **このグループに対して SAML 認証を有効にする** チェックボックスを選択します。
1. 任意。以下を選択します:
   - GitLab 17.4 以降では、**Enterpriseユーザーのパスワード認証を無効にする**。詳細については、[Enterpriseユーザーのパスワード認証を無効にするドキュメント](#disable-password-authentication-for-enterprise-users) を参照してください。
   - **このグループのウェブアクティビティに対してSSOのみの認証を強制する**。
   - **このグループのGitおよび依存プロキシアクティビティにSSOのみの認証を強制する**。詳細については、[SSO 強制ドキュメント](#sso-enforcement) を参照してください。
1. **変更を保存** を選択します。

{{< alert type="note" >}}

証明書[フィンガープリントアルゴリズム](../../../integration/saml.md#configure-saml-on-your-idp) は SHA1 である必要があります。([Google Workspace](#google-workspace)など) Identity Providerを構成する場合は、セキュア署名アルゴリズムを使用します。

{{< /alert >}}

GitLab の設定でイシューが発生した場合は、[トラブルシューティングドキュメント](#troubleshooting)を参照してください。

## ユーザーアクセスと管理

グループ SSO がConfigureされ、有効になった後、ユーザーは Identity Providerのダッシュボードから GitLab.com グループにアクセスできます。[SCIM](scim_setup.md) がConfigureされている場合は、SCIM ページの[ユーザーアクセス](scim_setup.md#user-access)を参照してください。

ユーザーがグループ SSO でサインインしようとすると、GitLab は次の情報に基づいてユーザーを検索または作成しようとします:

- 一致する SAML アイデンティティを持つ既存のユーザーを検索します。これは、ユーザーのアカウントが[SCIM](scim_setup.md)によって作成されたか、グループの SAML IdP で以前にサインインしたことを意味します。
- 同じメールアドレスのアカウントがまだ存在しない場合は、新しいアカウントを自動的に作成します。GitLab は、プライマリとセカンダリの両方のメールアドレスを照合しようとします。
- 同じメールアドレスのアカウントが既に存在する場合は、サインインページにリダイレクトして、次の操作を行います。
  - 別のメールアドレスで新しいアカウントを作成します。
  - 既存のアカウントにサインインして、SAML ID をリンクします。

### SAML を既存の GitLab.com アカウントにリンクします

{{< history >}}

- **「Remember me (記憶する)」**チェックボックスは GitLab 15.7 [で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/121569)。

{{< /history >}}

{{< alert type="note" >}}

ユーザーがそのグループの[Enterpriseユーザー](../../enterprise_user/_index.md)である場合、以下の手順は適用されません。代わりに、Enterpriseユーザーは[GitLab アカウントと同じメールアドレスを持つ SAML アカウントでサインイン](#returning-users-automatic-identity-relinking)する必要があります。これにより、GitLab は SAML アカウントを既存のアカウントにリンクできます。

{{< /alert >}}

SAML を既存の GitLab.com アカウントにリンクするには:

1. GitLab.com アカウントにサインインします。必要に応じて、[パスワードをリセット](https://gitlab.com/users/password/new)します。
1. サインインするグループの**GitLab シングルサインオン URL**を見つけてアクセスします。グループオーナーは、グループの**設定 > SAML SSO**ページでこれを見つけることができます。サインイン URL がConfigureされている場合、ユーザーはIdentity Providerから GitLab アプリケーションに接続できます。
1. 任意。**「Remember me (記憶する)」**チェックボックスを選択すると、GitLab へのサインイン状態が 2 週間維持されます。SAML プロバイダーによる再認証が、より頻繁に求められる場合があります。
1. **Authorize (承認)** を選択します。
1. プロンプトが表示されたら、Identity Providerで認証情報を入力します。
1. その後、GitLab.com にリダイレクトされ、グループにアクセスできるようになります。今後は、SAML を使用して GitLab.com にサインインできます。

ユーザーが既にグループのメンバーである場合、SAML ID をリンクしてもロールは変更されません。

以降のアクセスでは、[SAML で GitLab.com にサインイン](#sign-in-to-gitlabcom-with-saml)するか、リンクに直接アクセスできるようになります。**SSO の強制**オプションがオンになっている場合は、Identity Provider経由でサインインするようにリダイレクトされます。

### SAML で GitLab.com にサインイン

1. Identity Providerにサインインします。
1. アプリケーションのリストから、「GitLab.com」アプリケーションを選択します。(名前は、Identity Providerの管理者によって設定されます)。
1. その後、GitLab.com にサインインし、グループにリダイレクトされます。

### ユーザー SAML ID の管理

{{< history >}}

- SAML APIを使用した SAML ID の更新は、GitLab 15.5 [で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/227841)。

{{< /history >}}

GitLab.com は、SAML **NameID** を使用してユーザーを識別します。**NameID**は、次のとおりです。

- SAML 応答の必須フィールド。
- 大文字と小文字を区別しません。

**NameID**は、次の条件を満たす必要があります。

- 各ユーザーに固有であること。
- ランダムに生成された一意のユーザー ID など、決して変更されない永続的な値であること。
- 以降のサインイン試行で完全に一致させる必要があります。大文字と小文字の間で変化する可能性のあるユーザーインプットに依存しないでください。

**NameID** は、次の理由により、メールアドレスまたはユーザー名にしないでください。

- メールアドレスとユーザー名は、時間の経過とともに変更される可能性が高くなります。たとえば、人の名前が変わる場合などです。
- メールアドレスでは大文字と小文字が区別されないため、ユーザーがサインインできなくなる可能性があります。

**NameID**形式は、別の形式を必要とするメールなどのフィールドを使用していない限り、`Persistent` である必要があります。`Transient`を除く、任意の形式を使用できます。

#### ユーザー**NameID**の変更

グループオーナーは、[SAML API](../../../api/saml.md#update-extern_uid-field-for-a-saml-identity) を使用して、グループメンバーの **NameID** を変更し、SAML ID を更新できます。

[SCIM](scim_setup.md) がConfigureされている場合、グループオーナーは[SCIM API](../../../api/scim.md#update-extern_uid-field-for-a-scim-identity) を使用して SCIM ID を更新できます。

または、ユーザーに SAML アカウントの再接続を依頼します。

1. 関係するユーザーに、[アカウントをグループからアンリンク](#unlink-accounts)するように依頼します。
1. 関係するユーザーに、[アカウントを新しい SAML アプリケーションにリンク](#link-saml-to-your-existing-gitlabcom-account)するように依頼します。

{{< alert type="warning" >}}

ユーザーが SSO SAML を使用して GitLab にサインインした後、**NameID** の値を変更すると設定が中断され、ユーザーが GitLab グループからロックアウトされる可能性があります。

{{< /alert >}}

特定のIdentity Providerに推奨される値と形式の詳細については、[アイデンティティプロバイダーのセットアップ](#set-up-your-identity-provider)を参照してください。

### SAML 応答からEnterpriseユーザー設定をConfigureする

{{< history >}}

- GitLab 16.7 [で変更](https://gitlab.com/gitlab-org/gitlab/-/issues/412898)され、Enterpriseユーザー設定のみをConfigureするようになりました。

{{< /history >}}

GitLab では、SAML 応答の値に基づいて、特定のユーザー属性を設定できます。既存のユーザーの属性は、そのユーザーがグループの[Enterpriseユーザー](../../enterprise_user/_index.md)である場合、SAML 応答の値から更新されます。

#### サポートされているユーザー属性

- **can_create_group** \- Enterpriseユーザーが新しいトップレベルグループを作成できるかどうかを示す `true` または `false`。デフォルトは `true` です。
- **projects_limit** \- Enterpriseユーザーが作成できる個人プロジェクトの総数。`0` の値は、ユーザーが自分の個人ネームスペースに新しいプロジェクトを作成できないことを意味します。デフォルトは `100000` です。

#### SAML 応答の例

SAML 応答は、ブラウザーのデベロッパーツールまたはコンソールで、base64 エンコード形式で確認できます。任意の base64 デコードツールを使用して、情報を XML に変換します。SAML 応答の例を次に示します。

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

### 検証済みドメインによるユーザーメール確認を回避する

{{< history >}}

- GitLab 15.4 [で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/238461)。

{{< /history >}}

デフォルトでは、SAML または SCIM でプロビジョニングされたユーザーには、ID を検証するための検証メールが送信されます。代わりに、[GitLab をカスタムドメインでConfigure](../../enterprise_user/_index.md#set-up-a-verified-domain)すると、GitLab はユーザーアカウントを自動的に確認します。ユーザーは引き続き[Enterpriseユーザー](../../enterprise_user/_index.md)のウェルカムメールを受信します。次の両方が当てはまる場合、確認は回避されます。

- ユーザーは SAML または SCIM でプロビジョニングされます。
- ユーザーのメールアドレスが検証済みドメインに属している。

### Enterpriseユーザーのパスワード認証を無効にする

{{< history >}}

- GitLab 17.4 [で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/373718)。

{{< /history >}}

前提要件:

- Enterpriseユーザーが所属するグループのオーナーロールを持っている必要があります。
- グループ SSO を有効にする必要があります。

グループ内のすべての[Enterpriseユーザー](../../enterprise_user/_index.md)に対して、パスワード認証を無効にできます。これは、グループの管理者であるEnterpriseユーザーにも適用されます。この設定を構成すると、Enterpriseユーザーはパスワードの変更、リセット、またはパスワードによる認証ができなくなります。代わりに、これらのユーザーは以下で認証できます。

- GitLab Web UI のグループ SAML IdP。
- グループで[Enterpriseユーザーのパーソナルアクセストークンが無効になっている](../../profile/personal_access_tokens.md#disable-personal-access-tokens-for-enterprise-users)場合を除き、GitLab API および HTTP 基本認証を使用する Git のパーソナルアクセストークン。

Enterpriseユーザーのパスワード認証を無効にするには:

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。
1. **設定 > SAML SSO** を選択します。
1. **Configuration (構成)**で、**Disable password authentication for enterprise users (エンタープライズユーザーのパスワード認証を無効にする)**を選択します。
1. **変更を保存** を選択します。

#### 復帰ユーザー (ID の自動再リンク)

Enterpriseユーザーがグループから削除された後、復帰した場合、エンタープライズ SSO アカウントでサインインできます。Identity Providerのユーザーのメールアドレスが既存の GitLab アカウントのメールアドレスと同じままである限り、SSO ID はアカウントに自動的にリンクされ、ユーザーは問題なくサインインできます。

### ユーザーアクセスのブロック

SAML SSO のみがConfigureされている場合に、ユーザーのグループへのアクセスを取り消すには、次のいずれかの操作を行います。

- ユーザーを以下から(順番に)削除します。
  1. Identity Providerのユーザーデータストアまたは特定のアプリケーションのユーザーリスト。
  1. GitLab.com グループ。
- [最小アクセス](../../permissions.md#users-with-minimal-access)に設定されたデフォルトロールを使用して、グループのトップレベルで[グループ同期](group_sync.md#automatic-member-removal)を使用し、グループ内のすべてのリソースへのアクセスを自動的にブロックします。

SCIM も使用している場合に、ユーザーのグループへのアクセスを取り消すには、[アクセスの削除](scim_setup.md#remove-access)を参照してください。

### アカウントのアンリンク

ユーザーは、プロファイルページからグループの SAML をアンリンクできます。これは、次の場合に役立ちます:

- グループが GitLab.com へのサインインを許可されないようにする場合。
- SAML **NameID** が変更されたため、GitLab がユーザーを見つけられなくなった場合。

{{< alert type="warning" >}}

アカウントをアンリンクすると、グループ内のそのユーザーに割り当てられているすべてのロールが削除されます。ユーザーがアカウントを再リンクする場合、ロールを再割り当てする必要があります。

{{< /alert >}}

グループには、少なくとも 1 人のオーナーが必要です。アカウントがグループ内の唯一のオーナーである場合、アカウントのアンリンクは許可されません。その場合は、別のユーザーをグループオーナーとして設定してから、アカウントをアンリンクできます。

たとえば、`MyOrg` アカウントをアンリンクするには:

1. 左側のサイドバーで、アバターを選択します。
1. **Edit profile (プロファイルを編集)**を選択します。
1. 左側のサイドバーで、**Account (アカウント)**を選択します。
1. **Service sign-in (サービスサインイン)**セクションで、接続されているアカウントの横にある**切断**を選択します。

## SSO の強制

{{< history >}}

- GitLab 15.5 [で改善](https://gitlab.com/gitlab-org/gitlab/-/issues/215155)され、SSO の強制が有効になっていない場合でも透過的な強制を含めるために、[フラグ](../../../administration/feature_flags.md) `transparent_sso_enforcement` が追加されました。GitLab.com で無効になっています。
- GitLab.com での透過的 SSO がデフォルトで有効になることで、GitLab 15.8 [で改善](https://gitlab.com/gitlab-org/gitlab/-/issues/375788)されました。
- GitLab 15.10 [で一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/389562)されました。機能フラグ `transparent_sso_enforcement` が削除されました。

{{< /history >}}

GitLab.com では、SSO が次の場合に強制されます。

- SAML SSO が有効になっている場合。
- 組織のグループ階層内のグループとプロジェクトにアクセスするときに、既存の SAML ID を持つユーザーの場合。GitLab.com の認証情報を使用することで、ユーザーは SAML SSO を使用してサインインしなくても、組織外の他のグループやプロジェクト、およびユーザー設定を表示できます。

ユーザーは、次のいずれかまたは両方が当てはまる場合に、SAML ID を持ちます。

- GitLab グループのシングルサインオン URL を使用して GitLab にサインインしたことがある。
- SCIM によってプロビジョニングされた。

ユーザーはアクセスするたびに SSO によるサインインを求められることはありません。GitLab は、ユーザーが SSO を使用して認証されているかどうかを確認します。ユーザーが最後にサインインしてから 24 時間以上経過した場合、GitLab は SSO を使用して再度サインインするように求めます。

SSO は次のように強制されます:

| プロジェクト/グループの表示レベル | SSO 強制設定 | ID を持つメンバー | ID を持たないメンバー | メンバーではないか、サインインしていません |
|--------------------------|---------------------|----------------------|-------------------------|-----------------------------|
| 非公開                  | オフ                 | 強制             | 強制されません            | 強制されません                |
| 非公開                  | オン                  | 強制             | 強制                | 強制                    |
| 公開                   | オフ                 | 強制             | 強制されません            | 強制されません                |
| 公開                   | オン                  | 強制             | 強制                | 強制されません                |

API アクティビティに対して同様の SSO 要求事項を追加するための[イシューが存在](https://gitlab.com/gitlab-org/gitlab/-/issues/297389)します。この要求事項が追加されるまでは、アクティブな SSO セッションなしで API に依存する機能を使用できます。

### ウェブアクティビティの SSO のみ強制

**Enforce SSO-only authentication for web activity for this group (このグループのウェブアクティビティに対して SSO のみ認証を強制)**オプションが有効になっている場合:

- すべてのメンバーは、既存の SAML ID を持っているかどうかに関係なく、GitLab グループのシングルサインオン URL を使用して GitLab にアクセスし、グループリソースにアクセスする必要があります。
- SSO は、ユーザーが組織のグループ階層内のグループおよびプロジェクトにアクセスするときに強制されます。ユーザーは、SAML SSO を使用してサインインしなくても、組織外の他のグループやプロジェクトを表示できます。
- ユーザーを新しいメンバーとして手動で追加することはできません。
- オーナーロールを持つユーザーは、標準のサインインプロセスを使用して、トップレベルグループの設定に必要な変更を加えることができます。
- メンバーではないユーザー、またはサインインしていないユーザーの場合:
  - パブリックグループのリソースにアクセスする場合、SSO は強制されません。
  - プライベートグループのリソースにアクセスする場合、SSO は強制されます。
- 組織のグループ階層内のアイテムの場合、ダッシュボードの表示レベルは次のようになります。
  - [To-Do List (To-Do リスト)](../../todos.md)を表示する場合、SSO が強制されます。SSO セッションが期限切れになると To-Do アイテムが非表示になり、[アラートが表示されます](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115254)。
  - 割り当て済みのイシューのリストを表示する際に、SSO が適用されます。SSO セッションが期限切れになると、イシューは非表示になります。[イシュー 414475](https://gitlab.com/gitlab-org/gitlab/-/issues/414475) では、イシューが表示されるように、この動作を変更することが提案されています。
  - 自分が担当者であるか、レビューがリクエストされているマージリクエストのリストを表示する際には、SSO は強制されません。SSO セッションが期限切れになった場合でも、マージリクエストを表示できます。

ウェブアクティビティに対する SSO の強制を有効にすると、次の影響があります。

- グループの場合、プロジェクトがフォークされている場合でも、ユーザーはトップレベルグループ外でグループ内のプロジェクトを共有できません。
- CI/CD ジョブから発生する Git アクティビティには、SSO チェックは強制されません。
- 通常のユーザーに関連付けられていない認証情報 (たとえば、プロジェクトおよびグループアクセストークン、デプロイキー) には、SSO チェックは強制されません。
- ユーザーは、[依存プロキシ](../../packages/dependency_proxy/_index.md)を使用してイメージをプルするには、SSO を使用してサインインする必要があります。
- **Enforce SSO-only authentication for Git and Dependency Proxy activity for this group (このグループの Git および依存プロキシアクティビティに対して SSO のみ認証を強制)**オプションを有効にすると、Git アクティビティに関連する API エンドポイントはすべて SSO 強制の対象になります。たとえば、ブランチ、コミット、またはtagの作成または削除などです。SSH および HTTPS 経由の Git アクティビティの場合、ユーザーが GitLab リポジトリにプッシュまたはプルするには、SSO を使用してサインインしたアクティブなセッションが少なくとも 1 つ必要です。アクティブなセッションは、別のデバイス上にある可能性があります。

ウェブアクティビティに対する SSO が強制されている場合、非 SSO グループメンバーはすぐにアクセスを失うわけではありません。ユーザーが:

- アクティブなセッションを持っている場合、Identity Providerのセッションがタイムアウトするまで、最大 24 時間グループへのアクセスを継続できます。
- サインアウトした場合、Identity Providerから削除された後はグループにアクセスできません。

## 新しいIdentity Providerへの移行

新しいIdentity Providerに移行するには、[SAML API](../../../api/saml.md) を使用して、すべてのグループメンバーの ID を更新します。

例:

1. メンテナンス期間を設定して、その時点でアクティブなユーザーがいないようにします。
1. [各ユーザーのIDを更新](../../../api/saml.md#update-extern_uid-field-for-a-saml-identity)するには、SAML APIを使用します。
1. 新しいIdentity ProviderをConfigureします。
1. サインインが機能することを確認します。

## 関連トピック

- [GitLab Self-ManagedのSAML SSO](../../../integration/saml.md)
- [用語集](../../../integration/saml.md#glossary)
- [ブログ記事:GitLab.com で SAML と SSO を有効にするための究極のガイド](https://about.gitlab.com/blog/2023/09/14/the-ultimate-guide-to-enabling-saml/)
- [SaaSとSelf-Managed間の認証の比較](../../../administration/auth/_index.md#gitlabcom-compared-to-gitlab-self-managed)
- [統合認証で作成されたユーザーのパスワード](../../../security/passwords_for_integrated_authentication_methods.md)
- [SAML グループ同期](group_sync.md)

## トラブルシューティング

GitLab とIdentity Provider間で異なるSAML用語を対応させるのが難しい場合:

1. Identity Providerのドキュメントを確認してください。使用する用語に関する情報について、SAML設定の例をご覧ください。
1. [GitLab Self-ManagedドキュメントのSAML SSO](../../../integration/saml.md)を確認してください。GitLab Self-Managed SAML 設定ファイルは、GitLab.com ファイルよりも多くのオプションをサポートしています。GitLab Self-Managedインスタンスファイルに関する情報は、以下をご覧ください:
   - 外部の[OmniAuth SAMLドキュメント](https://github.com/omniauth/omniauth-saml/)。
   - [`ruby-saml`ライブラリ](https://github.com/onelogin/ruby-saml)。
1. プロバイダーからの XML レスポンスと、[内部Testで使用される XML の例](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/fixtures/saml/response.xml)を比較します。

その他のトラブルシューティング情報については、[SAMLガイドのトラブルシューティング](troubleshooting.md)を参照してください。
