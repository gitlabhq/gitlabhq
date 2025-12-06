---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: カスタムロール
description: 特定の組織のニーズを満たすように調整された権限を持つカスタムロールを作成します。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- UIを使用してカスタムロールを作成および削除する機能は、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393235)されました。
- UIを使用してカスタムロールを持つユーザーをグループに追加する、ユーザーのカスタムロールを変更する、グループメンバーからカスタムロールを削除する機能は、GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393239)されました。
- GitLab Self-Managedでインスタンス全体のカスタムロールを作成および削除する機能は、GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141562)されました。
- カスタム管理者ロールは、GitLab 17.7で`custom_ability_read_admin_dashboard`[フラグ](../../administration/feature_flags/_index.md)とともに[実験的機能](../../policy/development_stages_support.md)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/15854)されました。
- UIを使用してカスタム管理者ロールを管理する機能は、GitLab 17.9で`custom_admin_roles`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181346)されました。デフォルトでは無効になっています。
- カスタム管理者ロールは、GitLab 18.3で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/15957)されています。機能フラグ`custom_admin_roles`がデフォルトで有効になっています。

{{< /history >}}

カスタムロールを使用すると、組織に必要な特定の[カスタム権限](abilities.md)のみを持つロールを作成できます。各カスタムロールは、既存のデフォルトロールに基づいています。たとえば、ゲストロールに基づいてカスタムロールを作成し、プロジェクトリポジトリ内のコードを参照する権限を含めることもできます。

カスタムロールには、次の2種類があります:

- カスタムメンバーロール:
  - グループまたはプロジェクトのメンバーに割り当てることができます。
  - サブグループまたはプロジェクトで同じ権限を取得します。詳細については、[メンバーシップの種類](../../user/project/members/_index.md#membership-types)を参照してください。
  - [シートを使用](../../subscriptions/manage_users_and_seats.md#gitlabcom-billing-and-usage)し、[請求対象ユーザー](../../subscriptions/manage_users_and_seats.md#billable-users)になります。
    - `read_code`権限のみを持つカスタムゲストメンバーロールは、シートを使用しません。
- カスタム管理者ロール:
  - インスタンス上の任意のユーザーに割り当てることができます。
  - 特定の管理者アクションを実行する権限を取得します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>カスタムロール機能のデモについては、[[Demo] Ultimate Guest can view code on private repositories via custom role](https://www.youtube.com/watch?v=46cp_-Rtxps)（デモ: Ultimate Guestがカスタムロールを使用してプライベートリポジトリのコードを表示）をご覧ください。
<!-- Video published on 2023-02-13 -->

## カスタムメンバーロールを作成する {#create-a-custom-member-role}

カスタムメンバーロールを作成するには、デフォルトのGitLabロールを選択し、追加の[権限](abilities.md)を付与します。基本ロールは、カスタムロールで使用可能な最小限の権限を定義します。[監査担当者](../../administration/auditor_users.md)を基本ロールとして使用することはできません。

カスタム権限を使用すると、通常はメンテナーまたはオーナーロールに限定されているアクションを許可できます。たとえば、CI/CD変数を管理する権限を持つカスタムロールを使用すると、他のメンテナーまたはオーナーによって追加されたCI/CD変数の管理も可能になります。

カスタムメンバーロールは、次のスコープ内のグループおよびプロジェクトで使用できます:

- GitLab.comでは、カスタムロールが作成されたトップレベルグループの配下。
- GitLab Self-ManagedおよびGitLab Dedicatedでは、インスタンス全体。

前提要件:

- GitLab.comの場合、グループのオーナーロールが必要です。
- GitLab Self-ManagedおよびGitLab Dedicatedの場合、インスタンスへの管理者アクセス権が必要です。
- カスタムロールが10個未満である必要があります。

カスタムメンバーロールを作成するには:

1. 左側のサイドバーで、次を実行します:
   - GitLab.comの場合は、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
   - GitLab Self-ManagedおよびGitLab Dedicatedの場合は、下部にある**管理者**を選択します。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、右上隅で自分のアバターを選択し、**管理者**を選択します。
1. **設定** > **ロールと権限**を選択します。
1. **新しいロール**を選択します。
1. GitLab Self-ManagedおよびGitLab Dedicatedインスタンスのみ。**メンバーロール**を選択します。
1. カスタムロールの名前と説明を入力します。
1. **基本のロール**ドロップダウンリストから、デフォルトロールを選択します。
1. カスタムロールの任意の権限を選択します。
1. **ロールを作成する**を選択します。

カスタムロールの作成には、[APIを使用](../../api/graphql/reference/_index.md#mutationmemberrolecreate)することもできます。

## カスタム管理者ロールを作成する {#create-a-custom-admin-role}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

カスタム管理者ロールを作成するには、通常は管理者に限定されているアクションを許可する[権限](abilities.md)を追加します。各カスタム管理者ロールは、1つ以上の権限を持つことができます。

前提要件:

- インスタンスへの管理者アクセス権が必要です。
- カスタムロールが10個未満である必要があります。

カスタム管理者ロールを作成するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、右上隅で自分のアバターを選択し、**管理者**を選択します。
1. **設定** > **ロールと権限**を選択します。
1. **新しいロール**を選択します。
1. **管理者ロール**を選択します。
1. カスタムロールの名前と説明を入力します。
1. カスタムロールの任意の権限を選択します。
1. **ロールを作成する**を選択します。

カスタムロールの作成には、[APIを使用](../../api/graphql/reference/_index.md#mutationmemberroleadmincreate)することもできます。

## カスタムロールを編集する {#edit-a-custom-role}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/437590)されました。

{{< /history >}}

カスタムロールの名前、説明、および権限は編集できますが、基本ロールを編集することはできません。基本ロールを変更する必要がある場合は、新しいカスタムロールを作成する必要があります。

前提要件:

- GitLab.comの場合、グループのオーナーロールが必要です。
- GitLab Self-ManagedおよびGitLab Dedicatedの場合、インスタンスへの管理者アクセス権が必要です。

カスタムロールを編集するには:

1. 左側のサイドバーで、次を実行します:
   - GitLab.comの場合は、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
   - GitLab Self-ManagedおよびGitLab Dedicatedの場合は、下部にある**管理者**を選択します。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、右上隅で自分のアバターを選択し、**管理者**を選択します。
1. **設定** > **ロールと権限**を選択します。
1. カスタムロールの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **ロールを編集**を選択します。
1. ロールを変更します。
1. **ロールを保存**を選択します。

APIを使用して、[カスタムメンバーロール](../../api/graphql/reference/_index.md#mutationmemberroleupdate)または[カスタム管理者ロール](../../api/graphql/reference/_index.md#mutationmemberroleadminupdate)を編集することもできます。

## カスタムロールの詳細を表示する {#view-details-of-a-custom-role}

**ロールと権限**ページには、利用可能なすべてのデフォルトロールとカスタムロールに関する基本情報が一覧表示されます。これには、名前、説明、各カスタムロールに割り当て済みのユーザー数などの情報が含まれます。各カスタムロールには、`Custom member role`または`Custom admin role`バッジが含まれています。

また、ロールID、基本ロール、特定の権限など、カスタムロールに関する詳細情報を表示することもできます。

前提要件:

- GitLab.comの場合、グループのオーナーロールが必要です。
- GitLab Self-ManagedおよびGitLab Dedicatedの場合、インスタンスへの管理者アクセス権が必要です。

カスタムロールの詳細を表示するには:

1. 左側のサイドバーで、次を実行します:
   - GitLab.comの場合は、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
   - GitLab Self-ManagedおよびGitLab Dedicatedの場合は、下部にある**管理者**を選択します。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、右上隅で自分のアバターを選択し、**管理者**を選択します。
1. **設定** > **ロールと権限**を選択します。
1. カスタムロールの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **詳細を表示**を選択します。

## カスタムロールを削除する {#delete-a-custom-role}

ユーザーにまだ割り当てられているカスタムロールは削除できません。[ユーザーにカスタムロールを割り当てる](#assign-a-custom-member-role)を参照してください。

前提要件:

- GitLab.comの場合、グループのオーナーロールが必要です。
- GitLab Self-ManagedおよびGitLab Dedicatedの場合、インスタンスへの管理者アクセス権が必要です。

カスタムロールを削除するには:

1. 左側のサイドバーで、次を実行します:
   - GitLab.comの場合は、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
   - GitLab Self-ManagedおよびGitLab Dedicatedの場合は、下部にある**管理者**を選択します。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、右上隅で自分のアバターを選択し、**管理者**を選択します。
1. **設定** > **ロールと権限**を選択します。
1. カスタムロールの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **ロールを削除**を選択します。
1. 確認ダイアログで、**ロールを削除**を選択します。

APIを使用して、[カスタムメンバーロール](../../api/graphql/reference/_index.md#mutationmemberroledelete)または[カスタム管理者ロール](../../api/graphql/reference/_index.md#mutationmemberroleadmindelete)を削除することもできます。

## カスタムメンバーロールを割り当てる {#assign-a-custom-member-role}

グループおよびプロジェクトのメンバーのロールを割り当てたり、変更したりすることができます。この操作は、既存のユーザーに対して、またはユーザーを[グループ](../group/_index.md#add-users-to-a-group) 、[プロジェクト](../project/members/_index.md#add-users-to-a-project) 、または[インスタンス](../profile/account/create_accounts.md)に追加するときに行うことができます。

前提要件:

- グループの場合、グループのオーナーロールが必要です。
- プロジェクトの場合、プロジェクトのメンテナーロール以上が必要です。

既存のユーザーにカスタムメンバーロールを割り当てるには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループまたはプロジェクトを見つけます。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **管理** > **メンバー**を選択します。
1. **ロール**列で、既存のメンバーのロールを選択します。**ロールの詳細**ドロワーが開きます。
1. **ロール**ドロップダウンリストから、メンバーに割り当てるロールを選択します。
1. **ロールを更新する**を選択して、ロールを割り当てます。

[APIを使用](../../api/graphql/reference/_index.md#mutationmemberroletouserassign)して、カスタムロールの割り当てや既存の割り当ての変更を行うこともできます。

## カスタム管理者ロールを割り当てる {#assign-a-custom-admin-role}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インスタンス内のユーザーに管理者ロールを割り当てたり、変更したりすることができます。この操作は、既存のユーザーに対して、またはユーザーを[インスタンス](../profile/account/create_accounts.md)に追加するときに行うことができます。

前提要件:

- GitLabインスタンスの管理者である必要があります。

既存のユーザーにカスタム管理者ロールを割り当てるには:

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、右上隅で自分のアバターを選択し、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 対象ユーザーの**編集**を選択します。
1. **アクセス**セクションで、アクセスレベルを**標準**または**監査担当者**に設定します。
1. **管理者エリア**ドロップダウンリストから、カスタム管理者ロールを選択します。

[APIを使用](../../api/graphql/reference/_index.md#mutationmemberroletouserassign)して、カスタムロールの割り当てや既存の割り当ての変更を行うこともできます。

## 招待されたグループにカスタムロールを割り当てる {#assign-a-custom-role-to-an-invited-group}

{{< history >}}

- 招待されたグループ向けのカスタムロールのサポートは、GitLab 17.4で`assign_custom_roles_to_group_links_sm`機能フラグによって制限される形で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443369)されました。デフォルトでは無効になっています。
- GitLab 17.4の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/471999)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

[グループをグループに招待](../project/members/sharing_projects_groups.md#invite-a-group-to-a-group)すると、グループ内のすべてのユーザーにカスタムロールを割り当てることができます。

割り当てられたロールは、元のグループでのユーザーロールおよび権限と比較されます。通常、ユーザーには最小のアクセスレベルを持つロールが割り当てられます。ただし、ユーザーが元のグループでカスタムロールを持っている場合は、次のようになります:

- 基本ロールのみがアクセスレベルの比較に使用されます。カスタム権限は比較されません。
- 両方のカスタムロールが同じ基本ロールを持っている場合、ユーザーは元のグループのカスタムロールを保持します。

次の表は、グループに招待されたユーザーが利用できる最大のロールの例を示しています:

| シナリオ                                                | ゲストロールを持つユーザー | ゲストロールを持つユーザー + `read_code` | ゲストロールを持つユーザー + `read_vulnerability` | デベロッパーロールを持つユーザー     | デベロッパーロールを持つユーザー + `admin_vulnerability` |
| ------------------------------------------------------- | -------------------- | ---------------------------------- | ------------------------------------------- | ---------------------------- | ------------------------------------------------ |
| **Invited with Guest role**（ゲストロールで招待）                             | ゲスト                | ゲスト                            | ゲスト                                     | ゲスト                        | ゲスト                                          |
| **Invited with Guest role + `read_code`**（ゲストロール + で招待）               | ゲスト                | ゲスト + `read_code`              | ゲスト + `read_vulnerability`              | ゲスト + `read_code`          | ゲスト + `read_code`                            |
| **Invited with Guest role + `read_vulnerability`**（ゲストロール + で招待）      | ゲスト                | ゲスト + `read_code`              | ゲスト + `read_vulnerability`              | ゲスト + `read_vulnerability` | ゲスト + `read_vulnerability`                   |
| **Invited with Developer role**（デベロッパーロールで招待）                         | ゲスト                | ゲスト + `read_code`              | ゲスト + `read_vulnerability`              | デベロッパー                    | デベロッパー                                      |
| **Invited with Developer role + `admin_vulnerability`**（デベロッパーロール + で招待） | ゲスト                | ゲスト + `read_code`              | ゲスト + `read_vulnerability`              | デベロッパー                    | デベロッパー + `admin_vulnerability`              |

グループを別のグループに招待する場合にのみ、カスタムロールを割り当てることができます。[イシュー468329](https://gitlab.com/gitlab-org/gitlab/-/issues/468329)では、グループをプロジェクトに招待するときにカスタムロールを割り当てることを提案しています。

## サポートされているオブジェクト {#supported-objects}

以下に、各オブジェクトに対するカスタムロールと権限のサポート状況を示します:

| オブジェクト | バージョン       | イシュー |
|--------|---------------|-------|
| ユーザー  | 15.9          | リリース済み |
| グループ | 17.7          | 部分的にサポートされています。プロジェクトでのグループ割り当てのさらなるサポートは、[イシュー468329](https://gitlab.com/gitlab-org/gitlab/-/issues/468329)で提案されています |
| トークン | サポートされていません | [イシュー434354](https://gitlab.com/gitlab-org/gitlab/-/issues/434354) |

## ユーザーをカスタムロールに同期する {#sync-users-to-custom-roles}

SAMLやLDAPなどのツールを使用してグループメンバーシップを管理する場合は、ユーザーをカスタムロールに自動的に同期できます。詳細については、以下を参照してください:

- [SAMLグループリンクを設定する](../group/saml_sso/group_sync.md#configure-saml-group-links)。
- [LDAP経由でグループメンバーシップを管理する](../group/access_and_permissions.md#manage-group-memberships-with-ldap)。

## LDAPグループを管理者ロールに同期する {#sync-ldap-groups-to-admin-roles}

カスタム管理者ロールをLDAPグループにリンクできます。このリンクにより、グループ内のすべてのユーザーにカスタム管理者ロールが割り当てられます。

ユーザーが、割り当て済みのカスタム管理者ロールが異なる複数のLDAPグループに属している場合、GitLabは、先に作成されたLDAPリンクに関連するロールを割り当てます。たとえば、ユーザーがLDAPグループ`owner`および`dev`のメンバーであるとします。`owner`グループが`dev`グループより先にカスタム管理者ロールにリンクされていたとすると、ユーザーには`owner`グループに関連するロールが割り当てられます。

LDAPおよびグループ同期の管理の詳細については、[LDAP同期](../../administration/auth/ldap/ldap_synchronization.md#group-sync)を参照してください。

{{< alert type="note" >}}

カスタム管理者ロールを持つLDAPユーザーが、同期を設定した後にLDAPグループから削除された場合、カスタムロールは次回の同期まで削除されません。

{{< /alert >}}

### カスタム管理者ロールをLDAP CNとリンクする {#link-a-custom-admin-role-with-an-ldap-cn}

前提要件:

- LDAPサーバーとインスタンスを統合している必要があります。

カスタム管理者ロールをLDAP CNとリンクするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、右上隅で自分のアバターを選択し、**管理者**を選択します。
1. **設定** > **ロールと権限**を選択します。
1. **LDAP同期**タブで、**LDAP Server**（LDAPサーバー）を選択します。
1. **同期方法**フィールドで、`Group cn`を選択します。
1. **グループcn**フィールドに、グループのCNの先頭何文字かを入力します。設定済みの`group_base`の範囲内で一致するCNが、ドロップダウンリストに表示されます。
1. ドロップダウンリストからCNを選択します。
1. **カスタム管理者ロール**フィールドで、カスタム管理者ロールを選択します。
1. **追加**を選択します。

GitLabが、一致するLDAPユーザーへのロールのリンクを開始します。このプロセスが完了するまでに1時間以上かかる場合があります。

### カスタム管理者ロールをLDAPフィルターとリンクする {#link-a-custom-admin-role-with-an-ldap-filter}

前提要件:

- LDAPサーバーとインスタンスを統合している必要があります。

カスタム管理者ロールをLDAPフィルターとリンクするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、右上隅で自分のアバターを選択し、**管理者**を選択します。
1. **設定** > **ロールと権限**を選択します。
1. **LDAP同期**タブで、**LDAP Server**（LDAPサーバー）を選択します。
1. **同期方法**フィールドで、`User filter`を選択します。
1. **ユーザーフィルター**ボックスに、フィルターを入力します。詳細については、[LDAPユーザーフィルターを設定する](../../administration/auth/ldap/_index.md#set-up-ldap-user-filter)を参照してください。
1. **カスタム管理者ロール**フィールドで、カスタム管理者ロールを選択します。
1. **追加**を選択します。

GitLabが、一致するLDAPユーザーへのロールのリンクを開始します。このプロセスが完了するまでに1時間以上かかる場合があります。

## 新しい権限をコントリビュートする {#contribute-new-permissions}

権限が存在しない場合、以下を実行できます:

- 個々のカスタムロールと権限のリクエストについて、[イシュー391760](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)で議論します。
- [権限提案イシューテンプレート](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Permission%20Proposal)を使用して、権限をリクエストするイシューを作成します。
- GitLabにコントリビュートして、権限を追加します。
