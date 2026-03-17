---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabセルフマネージドまたはGitLab Dedicated用にSCIMを設定する
description: 自動アカウントプロビジョニングでユーザーのライフサイクルを管理します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/groups/gitlab-org/-/epics/8902)されました。

{{< /history >}}

オープン標準であるSCIM（SCIM）を使用すると、次のことを自動的に実行できます:

- ユーザーの作成。
- ユーザーのブロック。
- ユーザーの再追加（SCIMアイデンティティの再アクティブ化）。

[内部GitLab SCIM API](../../development/internal_api/_index.md#instance-scim-api)は[RFC7644プロトコル](https://www.rfc-editor.org/rfc/rfc7644)の一部を実装しています。

GitLab.comユーザーの場合は、[GitLab.comグループのSCIM設定](../../user/group/saml_sso/scim_setup.md)を参照してください。

## GitLabを設定する {#configure-gitlab}

前提条件: 

- [SAMLシングルサインオン](../../integration/saml.md)が設定されています。
- 管理者アクセス権が必要です。

GitLab SCIMを設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **SCIMトークン**セクションを展開し、**SCIMトークンを生成**を選択します。
1. Identity Providerの設定のために、以下を保存します:
   - **あなたのSCIMトークン**フィールドからトークン。
   - **SCIM APIエンドポイントのURL**フィールドからURL。

## Identity Providerを設定する {#configure-an-identity-provider}

次のものをIdentity Providerとして設定できます:

- [Okta](#configure-okta)。
- [Microsoft Entra ID（旧Azure Active Directory）](#configure-microsoft-entra-id-formerly-azure-active-directory)

> [!note]その他のIdentity ProviderもGitLabで動作する場合がありますが、テストされておらず、サポートされていません。サポートについてはプロバイダーにお問い合わせください。GitLabサポートは関連するログエントリをレビューすることで支援できます。

### Oktaを設定する {#configure-okta}

Oktaの[シングルサインオン](../../integration/saml.md)設定中に作成されたSAMLアプリケーションは、SCIM用に設定する必要があります。

前提条件: 

- [Okta Lifecycle Management](https://www.okta.com/products/lifecycle-management/)製品を使用する必要があります。OktaでSCIMを使用するには、この製品層が必要です。
- [GitLabはSCIM用に設定されています](#configure-gitlab)。
- [Okta設定ノート](../../integration/saml.md#set-up-okta)に記載されているとおりに設定された、[Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/)用のSAMLアプリケーション。
- Okta SAML設定は、[設定手順](_index.md)、特にNameIDの設定と一致している必要があります。

OktaをSCIM用に設定するには:

1. Oktaにサインインします。
1. 右上隅で、**管理者**を選択します。ボタンは**管理者**エリアからは見えません。
1. **Application**タブで、**Browse App Catalog**を選択します。
1. **GitLab**アプリケーションを検索して選択します。
1. GitLabアプリケーションの概要ページで、**Add Integration**を選択します。
1. **Application Visibility**の下で、両方のチェックボックスを選択します。GitLabアプリケーションはSAML認証をサポートしていないため、アイコンはユーザーに表示されるべきではありません。
1. **完了**を選択してアプリケーションの追加を終了します。
1. **Provisioning**タブで、**Configure API integration**を選択します。
1. **Enable API integration**を選択します。
   - **Base URL**には、GitLab SCIMの設定ページで**SCIM APIエンドポイントのURL**からコピーしたURLを貼り付けます。
   - **API Token**には、GitLab SCIMの設定ページで**あなたのSCIMトークン**からコピーしたSCIMトークンを貼り付けます。
1. 設定を検証するには、**Test API Credentials**を選択します。
1. **Save**を選択します。
1. APIインテグレーションの詳細を保存した後、左側に新しい設定タブが表示されます。**To App**を選択します。
1. **編集**を選択します。
1. **Create Users**と**Deactivate Users**の両方で**有効**チェックボックスを選択します。
1. **Save**を選択します。
1. **割り当て**タブでユーザーを割り当てます。割り当てられたユーザーは、GitLabグループで作成および管理されます。

### Microsoft Entra ID（旧Azure Active Directory）を設定する {#configure-microsoft-entra-id-formerly-azure-active-directory}

{{< history >}}

- GitLab 16.10でMicrosoft Entra IDの用語に[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143146)されました。

{{< /history >}}

前提条件: 

- [GitLabはSCIM用に設定されています](#configure-gitlab)。
- The [Microsoft Entra ID用のSAMLアプリケーションが設定されています](../../integration/saml.md#set-up-microsoft-entra-id)。

[Azure Active Directory](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/view-applications-portal)の[シングルサインオン](../../integration/saml.md)設定中に作成されたSAMLアプリケーションは、SCIM用に設定する必要があります。例については、[example configuration](../../user/group/saml_sso/example_saml_config.md#scim-mapping)を参照してください。

> [!note]次の手順で詳しく説明されているとおりに、SCIMプロビジョニングを正確に設定する必要があります。設定が誤っていると、ユーザープロビジョニングとサインインで問題が発生し、解決に多大な労力が必要になります。いずれかのステップで問題や質問がある場合は、GitLabサポートにお問い合わせください。

Microsoft Entra IDを設定するには、以下を設定します:

- SCIM用のMicrosoft Entra ID。
- 設定。
- 属性マッピングを含むマッピング。

#### SCIM用にMicrosoft Entra IDを設定する {#configure-microsoft-entra-id-for-scim}

1. アプリで、**Provisioning**タブに移動し、**始めましょう**を選択します。
1. **Provisioning Mode**を**Automatic**に設定します。
1. **Admin Credentials**を次の値を使用して完了します:
   - GitLabの**SCIM APIエンドポイントのURL**を**Tenant URL**フィールドに入力します。
   - GitLabの**あなたのSCIMトークン**を**Secret Token**フィールドに入力します。
1. **Test Connection**を選択します。

   テストが成功した場合は、設定を保存します。

   テストが失敗した場合は、解決するために[トラブルシューティング](../../user/group/saml_sso/troubleshooting.md)を参照してください。
1. **Save**を選択します。

保存後、**Mappings**と**設定**セクションが表示されます。

#### マッピングを設定する {#configure-mappings}

**Mappings**セクションで、まずグループをプロビジョニングします:

1. **Provision Microsoft Entra ID Groups**を選択します。
1. 属性マッピングページで、**有効**切替をオフにします。

   GitLabではSCIMグループのプロビジョニングはサポートされていません。グループプロビジョニングを有効にしたままにしても、SCIMユーザープロビジョニングが中断されることはありませんが、Entra ID SCIMプロビジョニングログに混乱を招く可能性のあるエラーが発生します。

   > [!note] **Provision Microsoft Entra ID Groups**が無効になっている場合でも、マッピングセクションには**有効と表示されることがあります: 可能**。この動作は安全に無視できる表示バグです。

1. **Save**を選択します。

次に、ユーザーをプロビジョニングします:

1. **Provision Microsoft Entra ID Users**を選択します。
1. **有効**切替が**可能**に設定されていることを確認します。
1. すべての**Target Object Actions**が有効になっていることを確認します。
1. **Attribute Mappings**で、[設定済みの属性マッピング](#configure-attribute-mappings)と一致するようにマッピングを設定します:
   1. （オプション）オプション。**customappsso Attribute**列で、`externalId`を検索して削除します。
   1. 最初の属性を次のように編集します:
      - `objectId`の**source attribute**。
      - `externalId`の**target attribute**。
      - `1`の**matching precedence**。
   1. 既存の**customappsso**属性を更新して、[設定済みの属性マッピング](#configure-attribute-mappings)と一致させます。
   1. [属性マッピングテーブル](#configure-attribute-mappings)にない追加の属性は削除します。削除しなくても問題は発生しませんが、GitLabはこれらの属性を消費しません。
1. マッピングリストの下で、**Show advanced options**チェックボックスを選択します。
1. **Edit attribute list for customappsso**リンクを選択します。
1. `id`がプライマリおよび必須フィールドであり、`externalId`も必須であることを確認します。
1. **保存**を選択すると、属性マッピング設定ページに戻ります。
1. **Attribute Mapping**設定ページを閉じるには、右上隅にある`X`を選択します。

##### 属性マッピングを設定する {#configure-attribute-mappings}

> [!note] MicrosoftがAzure Active DirectoryからEntra IDの命名スキームに移行する間、ユーザーインターフェースに不整合が見られる場合があります。問題がある場合は、このドキュメントの古いバージョンを表示するか、GitLabサポートに問い合わせることができます。

[SCIM用にEntra IDを設定](#configure-microsoft-entra-id-formerly-azure-active-directory)する際に、属性マッピングを設定します。例については、[example configuration](../../user/group/saml_sso/example_saml_config.md#scim-mapping)を参照してください。

次の表は、GitLabに必要な属性マッピングを示しています。

| ソース属性                                                           | ターゲット属性               | マッチング優先順位 |
|:---------------------------------------------------------------------------|:-------------------------------|:--------------------|
| `objectId`                                                                 | `externalId`                   | 1                   |
| `userPrincipalName`または`mail` <sup>1</sup>                                 | `emails[type eq "work"].value` |                     |
| `mailNickname`                                                    | `userName`                     |                     |
| `displayName`または`Join(" ", [givenName], [surname])` <sup>2</sup>          | `name.formatted`               |                     |
| `Switch([IsSoftDeleted], , "False", "True", "True", "False")` <sup>3</sup> | `active`                       |                     |

**脚注**: 

1. `userPrincipalName`がメールアドレスではないか、配信できない場合は、`mail`をソース属性として使用します。
1. `displayName`が`Firstname Lastname`の形式と一致しない場合は、`Join`式を使用します。
1. これは式マッピングタイプであり、直接マッピングではありません。**Mapping type**ドロップダウンリストで**Expression**を選択します。

各属性マッピングには、次のものがあります:

- **target attribute**に対応する**customappsso Attribute**。
- **source attribute**に対応する**Microsoft Entra ID Attribute**。
- マッチング優先順位。

各属性について:

1. 既存の属性を編集するか、新しい属性を追加します。
1. ドロップダウンリストから、必要なソースおよびターゲット属性マッピングを選択します。
1. **OK**を選択します。
1. **Save**を選択します。

SAMLの設定が[推奨されるSAMLの設定](../../integration/saml.md)と異なる場合は、マッピング属性を選択し、それに応じて変更します。`externalId`ターゲット属性にマップするソース属性は、SAML `NameID`に使用される属性と一致している必要があります。

マッピングが表にない場合は、Microsoft Entra IDのデフォルトを使用します。必須属性のリストについては、[内部インスタンスSCIM API](../../development/internal_api/_index.md#instance-scim-api)のドキュメントを参照してください。

#### 設定を設定する {#configure-settings}

**設定**セクションで:

1. （オプション）必要に応じて、**Send an email notification when a failure occurs**チェックボックスを選択します。
1. （オプション）必要に応じて、**Prevent accidental deletion**チェックボックスを選択します。
1. 必要に応じて、**保存**を選択してすべての変更が保存されたことを確認します。

マッピングと設定を設定したら、アプリの概要ページに戻り、**Start provisioning**を選択して、GitLabでのユーザーの自動SCIMプロビジョニングを開始します。

> [!warning]同期後、`id`および`externalId`にマップされたフィールドを変更すると、エラーが発生する可能性があります。これには、プロビジョニングエラー、重複ユーザーが含まれ、既存のユーザーがGitLabグループにアクセスできない可能性があります。

## アクセスを削除する {#remove-access}

Identity Providerでユーザーを削除または非アクティブ化すると、GitLabインスタンスでユーザーがブロックされますが、SCIMのアイデンティティはGitLabユーザーにリンクされたままになります。

ユーザーSCIMのアイデンティティを更新するには、[内部GitLab SCIM API](../../development/internal_api/_index.md#update-a-single-scim-provisioned-user-1)を使用します。

### アクセスを再アクティブ化する {#reactivate-access}

{{< history >}}

- GitLab 16.0で`skip_saml_identity_destroy_during_scim_deprovision`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/379149)されました。デフォルトでは無効になっています。
- GitLab 16.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121226)になりました。機能フラグ`skip_saml_identity_destroy_during_scim_deprovision`は削除されました。

{{< /history >}}

SCIMによってユーザーが削除または非アクティブ化された後、そのユーザーをSCIMIdentity Providerに追加することで再アクティブ化できます。

Identity Providerが設定されたスケジュールに基づいて同期を実行すると、ユーザーのSCIMアイデンティティが再アクティブ化され、GitLabインスタンスへのアクセスが復元されます。

## SCIMを使用したグループ同期 {#group-synchronization-with-scim}

{{< history >}}

- GitLab 18.0で`self_managed_scim_group_sync`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/15990)されました。デフォルトでは無効になっています。
- GitLab 18.2で、GitLabセルフマネージドで[デフォルト](https://gitlab.com/gitlab-org/gitlab/-/issues/553662)で有効化されました。
- GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/554271)になりました。機能フラグ`self_managed_scim_group_sync`は削除されました。

{{< /history >}}

ユーザープロビジョニングに加えて、SCIMを使用してIdentity ProviderとGitLabの間でグループメンバーシップを同期できます。この方法を使用すると、Identity Providerでのグループメンバーシップに基づいて、GitLabグループからユーザーを自動的に追加および削除できます。

前提条件: 

- まず[SAMLグループリンク](../../user/group/saml_sso/group_sync.md#configure-saml-group-links)を設定する必要があります。
- Identity ProviderのSAMLグループ名は、GitLabで設定されたSAMLグループ名と一致している必要があります。

SCIMグループ同期は、SAMLグループリンクと連携してグループメンバーシップを管理します。Identity ProviderがSCIM APIを介してグループメンバーシップの変更を送信すると、GitLabはそのSCIMグループに関連付けられているSAMLグループリンクを持つすべてのGitLabグループのユーザーグループメンバーシップを更新します。

SCIMは一方向プロトコルです: 変更はIdentity ProviderからGitLabに流れます。GitLabでSAMLグループリンクに変更を加えた場合（追加または削除など）、Identity ProviderはSCIMを介してこれらの変更を検出する手段がありません。

### 新しいグループリンクの既知の制限 {#known-limitation-of-new-group-links}

Identity Providerが最初にSCIMグループをプロビジョニングする際（`POST /Groups`を介して）、GitLabはSCIMグループIDを、一致するグループ名を持つすべての既存のSAMLグループリンクと関連付けます。ただし、最初のプロビジョニング後に同じグループ名を持つ新しいSAMLグループリンクを追加しても、新しいグループリンクはSCIMグループIDに自動的に関連付けられません。これは、Identity ProviderからのSCIMメンバーシップ更新が、新しく追加されたグループリンクのユーザーに影響を与えないことを意味します。

改善のサポートは[イシュー582729](https://gitlab.com/gitlab-org/gitlab/-/issues/582729)で提案されています。

> [!note]すべてのグループリンクが最初からSCIMグループに関連付けられていることを確認するには、Identity ProviderでSCIMグループプロビジョニングを設定する前に、すべてのSAMLグループリンクを設定する必要があります。

最初のプロビジョニング後にグループリンクを追加する必要がある場合は、SCIMグループプロビジョニング（IdPグループ自体ではなく）を削除してから再作成することで、Identity ProviderでSCIMグループを再プロビジョニングできます。このアクションにより、現在のすべてのSAMLグループリンクがSCIMグループに再関連付けされます。詳細については、SCIMグループプロビジョニングの管理に関するIdentity Providerのドキュメントを参照してください。

GitLabでSAMLグループリンクを削除しても、そのリンクを介してそのグループのメンバーであるユーザーはグループに残ります。ただし、グループリンクが削除されたため、SCIMはそのグループでのメンバーシップを管理しなくなります。必要に応じて、手動で[グループからメンバーを削除](../../user/group/_index.md#remove-a-member-from-the-group)できます。

### Identity Providerでグループ同期を設定する {#configure-group-synchronization-in-your-identity-provider}

Identity Providerでのグループ同期の設定に関する詳細な手順については、プロバイダーのドキュメントを参照してください。以下に例を示します:

- [Okta Groups API](https://developer.okta.com/docs/reference/api/groups/)
- [Microsoft Entra ID（Azure AD）SCIM Groups](https://learn.microsoft.com/en-us/entra/identity/app-provisioning/use-scim-to-provision-users-and-groups) \- デフォルトでは、`displayName`ソース属性は、ユーザーフレンドリーな名前を持つSAMLグループリンクを見つけるために使用されます。 - ただし、SAMLグループリンクが名前としてオブジェクトIDを使用している場合は、ソース属性を`objectId`に更新する必要があります。

> [!warning]複数のSAMLグループリンクが同じGitLabグループにマップされている場合、ユーザーはすべてのマッピンググループリンクの中で最高のロールを割り当てられます。IdPグループから削除されたユーザーは、別のSAMLグループにリンクされている場合、GitLabグループに残ります。

Oktaアプリケーションカタログの標準GitLab SCIMアプリケーションは、グループ同期をサポートしていません。あるいは、Oktaとのグループ同期のためにカスタムSCIMインテグレーションを作成できます。詳細については、[イシュー582729](https://gitlab.com/gitlab-org/gitlab/-/issues/582729)を参照してください。

## トラブルシューティング {#troubleshooting}

[当社のSCIMトラブルシューティングガイド](../../user/group/saml_sso/troubleshooting_scim.md)を参照してください。
