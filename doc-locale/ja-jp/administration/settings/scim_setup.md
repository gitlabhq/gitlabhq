---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Self-ManagedまたはGitLab DedicatedのSCIMを設定
description: 自動化されたアカウントプロビジョニングでユーザーライフサイクルを管理します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/groups/gitlab-org/-/epics/8902)されました。

{{< /history >}}

オープン標準のSystem for Cross-domain Identity Management（SCIM）を使用して、以下を自動化できます:

- ユーザーを作成します。
- ユーザーをブロックする。
- ユーザーを再度追加する（SCIMアイデンティティ管理を再アクティブ化）。

[内部GitLab SCIM API](../../development/internal_api/_index.md#instance-scim-api)は、[RFC7644プロトコル](https://www.rfc-editor.org/rfc/rfc7644)の一部を実装しています。

GitLab.comのユーザーの方は、[GitLab.comグループのSCIMの設定](../../user/group/saml_sso/scim_setup.md)を参照してください。

## GitLabを設定する {#configure-gitlab}

前提要件: 

- [SAMLシングルサインオン](../../integration/saml.md)を設定します。

GitLab SCIMを設定するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. 左側のサイドバーの下部にある**SCIMトークン**セクションを展開し、**SCIMトークンを生成**を選択します。
1. Identity Providerを設定するには、以下を保存します:
   - **あなたのSCIMトークン**フィールドのトークン。
   - **SCIM APIエンドポイントのURL**フィールドのURL。

## Identity Providerを設定する {#configure-an-identity-provider}

以下のものをIdentity Providerとして設定できます:

- [Okta](#configure-okta)。
- [Microsoft Entra ID（旧称Azure Active Directory）](#configure-microsoft-entra-id-formerly-azure-active-directory)

{{< alert type="note" >}}

他のIdentity ProviderもGitLabで動作する可能性がありますが、テストされておらず、サポートされていません。サポートについては、プロバイダーにお問い合わせください。GitLabサポートは、関連するログエントリをレビューすることで支援できます。

{{< /alert >}}

### Oktaを設定する {#configure-okta}

Oktaの[シングルサインオン](../../integration/saml.md)設定時に作成されたSAMLアプリケーションは、SCIM用に設定する必要があります。

前提要件: 

- [Oktaライフサイクル管理](https://www.okta.com/products/lifecycle-management/)製品を使用する必要があります。この製品層は、OktaでSCIMを使用するために必要です。
- [GitLabが設定されました](#configure-gitlab) SCIM用。
- [Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/)のSAMLアプリケーションは、[Oktaセットアップノート](../../integration/saml.md#set-up-okta)に記載されているように設定されています。
- Okta SAML設定は、特にNameID設定において、[設定手順](_index.md)と一致している必要があります。

SCIM用にOktaを設定するには:

1. Oktaにサインインします。
1. 右上隅で**管理者**を選択します。ボタンは、**管理者**エリアからは表示されません。
1. **Application**タブで、**Browse App Catalog**を選択します。
1. **GitLab**アプリケーションを見つけて選択します。
1. GitLabアプリケーションの概要ページで、**Add Integration**を選択します。
1. **Application Visibility**で、両方のチェックボックスを選択します。GitLabアプリケーションはSAML認証をサポートしていないため、アイコンはユーザーに表示されません。
1. **完了**を選択して、アプリケーションの追加を完了します。
1. **Provisioning**タブで、**Configure API integration**を選択します。
1. **Enable API integration**を選択します。
   - **Base URL**に、GitLab SCIM設定ページの**SCIM APIエンドポイントのURL**からコピーしたURLを貼り付けます。
   - **API Token**に、GitLab SCIM設定ページの**あなたのSCIMトークン**からコピーしたSCIMトークンを貼り付けます。
1. 設定を確認するには、**Test API Credentials**を選択します。
1. **保存**を選択します。
1. APIインテグレーションの詳細を保存すると、左側に新しい設定タブが表示されます。**To App**を選択します。
1. **編集**を選択します。
1. **Create Users**と**Deactivate Users**の両方に対して**Enable**のチェックボックスをオンにします。
1. **保存**を選択します。
1. **Assignments**タブでユーザーを割り当てます。割り当てられたユーザーは、GitLabグループで作成および管理されます。

### Microsoft Entra ID（旧称Azure Active Directory）を設定する {#configure-microsoft-entra-id-formerly-azure-active-directory}

{{< history >}}

- [変更点](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143146) GitLabバージョン16.10のMicrosoft Entra ID用語。

{{< /history >}}

前提要件: 

- [GitLabが設定されました](#configure-gitlab) SCIM用。
- [Microsoft Entra IDのSAMLアプリケーションがセットアップされました](../../integration/saml.md#set-up-microsoft-entra-id)。

[Azure Active Directory](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/view-applications-portal)の[シングルサインオン](../../integration/saml.md)設定時に作成されたSAMLアプリケーションは、SCIM用に設定する必要があります。例については、[設定例](../../user/group/saml_sso/example_saml_config.md#scim-mapping)を参照してください。

{{< alert type="note" >}}

次の手順で詳しく説明されているように、SCIMプロビジョニングを正確に設定する必要があります。設定を誤ると、ユーザーのプロビジョニングとサインインで問題が発生し、解決に多大な労力を要します。いずれかの手順で問題や質問がある場合は、GitLabサポートにお問い合わせください。

{{< /alert >}}

Microsoft Entra IDを設定するには、以下を設定します:

- SCIM用のMicrosoft Entra ID。
- 設定。
- 属性マッピングを含む、マッピング。

#### Microsoft Entra IDをSCIM用に設定する {#configure-microsoft-entra-id-for-scim}

1. アプリで、**Provisioning**タブに移動し、**Get started**を選択します。
1. **Provisioning Mode**を**Automatic**に設定します。
1. 以下の値を使用して、**Admin Credentials**に入力します:
   - **Tenant URL**フィールドには、**SCIM APIエンドポイントのURL**。
   - **Secret Token**フィールドには、GitLabの**あなたのSCIMトークン**。
1. **Test Connection**を選択します。

   テストが成功した場合は、設定を保存します。

   テストが失敗した場合は、[トラブルシューティング](../../user/group/saml_sso/troubleshooting.md)を参照して、この問題を解決してください。
1. **保存**を選択します。

保存後、**Mappings**セクションと**Settings**セクションが表示されます。

#### マッピングを構成する {#configure-mappings}

**Mappings**セクションで、最初にグループをプロビジョンします:

1. **Provision Microsoft Entra ID Groups**を選択します。
1. [Attribute Mapping]ページで、**有効**切替をオフにします。

   SCIMグループプロビジョニングはGitLabではサポートされていません。グループプロビジョニングを有効のままにしても、SCIMユーザープロビジョニングは中断されませんが、Entra ID SCIMプロビジョニングログにエラーが発生し、混乱や誤解を招く可能性があります。

   {{< alert type="note" >}}

   **Provision Microsoft Entra ID Groups**が無効になっている場合でも、マッピングセクションには**Enabled: Yes**と表示される場合があります。この動作は、無視しても問題ない表示上のバグです。

   {{< /alert >}}

1. **保存**を選択します。

次に、ユーザーをプロビジョンします:

1. **Provision Microsoft Entra ID Users**を選択します。
1. **Enabled**の切り替えが**Yes**に設定されていることを確認します。
1. すべての**Target Object Actions**が有効になっていることを確認します。
1. **Attribute Mappings**で、[構成された属性マッピング](#configure-attribute-mappings)と一致するようにマッピングを構成します:
   1. オプション。**customappsso Attribute**列で、`externalId`を見つけて削除します。
   1. 最初属性を編集して、以下を設定します:
      - `objectId`の**source attribute**。
      - `externalId`の**target attribute**。
      - `1`の**matching precedence**。
   1. 既存の**customappsso**属性を更新して、[構成された属性マッピング](#configure-attribute-mappings)と一致させます。
   1. [属性マッピングテーブル](#configure-attribute-mappings)に存在しない追加属性はすべて削除します。削除しなくても問題は発生しませんが、GitLabは属性を使用しません。
1. マッピングリストの下にある**Show advanced options**チェックボックスを選択します。
1. **Edit attribute list for customappsso**リンクを選択します。
1. `id`がプライマリで必須のフィールドであり、`externalId`も必須であることを確認します。
1. **保存**を選択すると、Attribute Mapping設定ページに戻ります。
1. **Attribute Mapping**設定ページを閉じるには、右上隅にある`X`を選択します。

##### 属性マッピングを構成する {#configure-attribute-mappings}

{{< alert type="note" >}}

MicrosoftがAzure Active DirectoryからEntra IDの命名体系に移行する際に、ユーザーUIに矛盾が見られる場合があります。問題がある場合は、このドキュメントの古いバージョンを表示するか、GitLabサポートにお問い合わせください。

{{< /alert >}}

[SCIM用にEntra IDを構成](#configure-microsoft-entra-id-formerly-azure-active-directory)する際に、属性マッピングを構成します。例については、[設定例](../../user/group/saml_sso/example_saml_config.md#scim-mapping)を参照してください。

次の表に、GitLabに必要な属性マッピングを示します。

| ソース属性                                                           | ターゲット属性               | 照合優先順位 |
|:---------------------------------------------------------------------------|:-------------------------------|:--------------------|
| `objectId`                                                                 | `externalId`                   | 1                   |
| `userPrincipalName`または`mail`<sup>1</sup>                                 | `emails[type eq "work"].value` |                     |
| `mailNickname`                                                    | `userName`                     |                     |
| `displayName`または`Join(" ", [givenName], [surname])`<sup>2</sup>          | `name.formatted`               |                     |
| `Switch([IsSoftDeleted], , "False", "True", "True", "False")`<sup>3</sup> | `active`                       |                     |

**脚注**: 

1. `userPrincipalName`がメールアドレスでない場合、または配信できない場合は、`mail`をソース属性として使用します。
1. `displayName`が`Firstname Lastname`の形式と一致しない場合は、`Join`式を使用します。
1. これは式マッピングタイプであり、直接マッピングではありません。**Mapping type**ドロップダウンリストで**Expression**を選択します。

各属性マッピングには、以下があります:

- **customappsso Attribute**。**target attribute**に対応。
- **Microsoft Entra ID Attribute**。**source attribute**に対応。
- 照合優先順位。

各属性について:

1. 既存の属性を編集するか、新しい属性を追加します。
1. ドロップダウンリストから、必要なソースとターゲットの属性マッピングを選択します。
1. **OK**を選択します。
1. **保存**を選択します。

[推奨されるSAML設定](../../integration/saml.md)とSAML設定が異なる場合は、マッピング属性を選択して、それに応じて変更します。`externalId`ターゲット属性にマップするソース属性は、SAML`NameID`に使用される属性と一致する必要があります。

マッピングが表にリストされていない場合は、Microsoft Entra IDデフォルトを使用します。必要な属性のリストについては、[内部インスタンスSCIM API](../../development/internal_api/_index.md#instance-scim-api)のドキュメントを参照してください。

#### 設定を構成する {#configure-settings}

**設定**セクション:

1. オプション。必要に応じて、**Send an email notification when a failure occurs**チェックボックスをオンにします。
1. オプション。必要に応じて、**Prevent accidental deletion**チェックボックスをオンにします。
1. 必要に応じて、**保存**を選択して、すべての変更が保存されていることを確認します。

マッピングと設定を構成したら、アプリの概要ページに戻り、**Start provisioning**を選択して、GitLabでのユーザーの自動SCIMプロビジョニングを開始します。

{{< alert type="warning" >}}

一度同期されると、`id`と`externalId`にマップされたフィールドを変更すると、エラーが発生する可能性があります。これらには、プロビジョニングエラー、重複ユーザーが含まれ、既存のユーザーがGitLabグループにアクセスできなくなる可能性があります。

{{< /alert >}}

## アクセス権を削除する {#remove-access}

Identity Providerでユーザーを削除または非アクティブ化すると、GitLabインスタンスでユーザーがブロックされますが、SCIMアイデンティティ管理はGitLabユーザーにリンクされたままになります。

ユーザーのSCIMアイデンティティ管理を更新するには、[内部GitLab SCIM API](../../development/internal_api/_index.md#update-a-single-scim-provisioned-user-1)を使用します。

### アクセス権を再度アクティブにする {#reactivate-access}

{{< history >}}

- GitLab 16.0で`skip_saml_identity_destroy_during_scim_deprovision`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/379149)されました。デフォルトでは無効になっています。
- GitLab 16.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121226)になりました。機能フラグ`skip_saml_identity_destroy_during_scim_deprovision`は削除されました。

{{< /history >}}

SCIMを介してユーザーが削除または非アクティブ化された後、そのユーザーをSCIMIdentity Providerに追加することで、そのユーザーを再度アクティブ化できます。

Identity Providerが構成されたスケジュールに基づいて同期を実行すると、ユーザーのSCIMアイデンティティ管理が再度アクティブ化され、GitLabインスタンスへのアクセスが復元されます。

## SCIMとのグループ同期 {#group-synchronization-with-scim}

{{< history >}}

- GitLab 18.0で`self_managed_scim_group_sync`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/15990)されました。デフォルトでは無効になっています。
- デフォルトではGitLab 18.2の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/553662)。
- GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/554271)。機能フラグ`self_managed_scim_group_sync`は削除されました。

{{< /history >}}

ユーザープロビジョニングに加えて、SCIMを使用して、Identity ProviderとGitLab間のグループメンバーシップを同期できます。この方法を使用すると、Identity Providerのグループメンバーシップに基づいて、GitLabグループからユーザーを自動的に追加および削除できます。

前提要件: 

- [SAMLグループリンク](../../user/group/saml_sso/group_sync.md#configure-saml-group-links)を最初に構成する必要があります。
- Identity ProviderのSAMLグループ名は、GitLabで構成されているSAMLグループ名と一致する必要があります。

### Identity Providerでグループ同期を構成する {#configure-group-synchronization-in-your-identity-provider}

Identity Providerでグループ同期を構成する詳細な手順については、プロバイダーのドキュメントを参照してください。以下に例を示します:

- [OktaグループAPI](https://developer.okta.com/docs/reference/api/groups/)
- [Microsoft Entra ID（Azure AD）SCIMグループ](https://learn.microsoft.com/en-us/entra/identity/app-provisioning/use-scim-to-provision-users-and-groups)

{{< alert type="warning" >}}

複数のSAMLグループリンクが同じGitLabグループにマップされている場合、ユーザーには、すべてのマッピンググループリンクで最も高いロールが割り当てられます。IdPグループから削除されたユーザーは、リンクされている別のSAMLグループに属している場合、GitLabグループに留まります。

{{< /alert >}}

## トラブルシューティング {#troubleshooting}

SCIMガイドの[トラブルシューティング](../../user/group/saml_sso/troubleshooting_scim.md)を参照してください。
