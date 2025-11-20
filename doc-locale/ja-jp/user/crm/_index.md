---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 顧客関係管理（CRM）
description: 顧客管理、組織、連絡先、権限。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `customer_relations`という名前の[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 14.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/2256)されました。デフォルトでは無効になっています。
- GitLab 14.8以降では、[トップレベルグループでのみ連絡先と組織を作成](https://gitlab.com/gitlab-org/gitlab/-/issues/350634)できます。
- GitLab 15.0の[GitLab.comおよびGitLab Self-Managedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/346082)。
- GitLab 15.1で[機能フラグは削除](https://gitlab.com/gitlab-org/gitlab/-/issues/346082)されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

{{< alert type="note" >}}

この機能は活発な開発は行われていませんが、[コミュニティコントリビュート](https://about.gitlab.com/community/contribute/)を歓迎します。機能がニーズに合っているかどうかを判断するには、[クライアントエピックの管理と課金](https://gitlab.com/groups/gitlab-org/-/epics/5323)で未解決のイシューを参照してください。

{{< /alert >}}

顧客関係管理（CRM）を使用すると、連絡先（個人）と組織（企業）の記録を作成し、それらをイシューに関連付けることができます。

デフォルトでは、連絡先と組織はトップレベルグループに対してのみ作成できます。他のグループで連絡先と組織を作成するには、[グループを連絡先のソースとして割り当て](#configure-the-contact-source)ます。

連絡先と組織を使用して、請求とレポートの目的で作業を顧客に結び付けることができます。将来計画されていることの詳細については、[イシュー2256](https://gitlab.com/gitlab-org/gitlab/-/issues/2256)を参照してください。

## 権限 {#permissions}

| 権限                         | ゲスト | プランナー | グループレポーター | グループデベロッパー、メンテナー、オーナー |
|------------------------------------|-------|---------|----------------|----------------------------------------|
| 連絡先/組織の表示        |       | ✓       | ✓              | ✓                                      |
| イシューの連絡先の表示                |       | ✓       | ✓              | ✓                                      |
| イシューの連絡先の追加/削除          |       | ✓       | ✓              | ✓                                      |
| 連絡先/組織の作成/編集 |       |         |                | ✓                                      |

## 顧客関係管理（CRM）の有効化 {#enable-customer-relations-management-crm}

{{< history >}}

- GitLab 16.9で、[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108378)になりました。

{{< /history >}}

顧客関係管理機能は、グループレベルで有効になります。グループにサブグループも含まれており、サブグループでCRM機能を使用する場合は、サブグループでもCRM機能を有効にする必要があります。

グループまたはサブグループで顧客関係管理を有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループまたはサブグループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**セクションを展開します。
1. **顧客関係が有効になっています**を選択します。
1. **変更を保存**を選択します。

## 連絡先のソースの構成 {#configure-the-contact-source}

{{< history >}}

- GitLab 17.6で[利用可能](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167475)です。

{{< /history >}}

デフォルトでは、連絡先はイシューのトップレベルグループから提供されます。

グループの連絡先のソースは、構成された連絡先のソースがない限り、すべてのサブグループに適用されます。

グループまたはサブグループの連絡先のソースを構成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループまたはサブグループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**セクションを展開します。
1. **連絡先のソース** > **グループを検索**を選択します。
1. 連絡元のグループを選択します。
1. **変更を保存**を選択します。

## 連絡先 {#contacts}

### グループにリンクされた連絡先の表示 {#view-contacts-linked-to-a-group}

前提要件: 

- グループのプランナーロール以上を持っている必要があります。

グループの連絡先を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **顧客関係**を選択します。

![連絡先リスト](crm_contacts_v14_10.png)

### 連絡先の作成 {#create-a-contact}

前提要件: 

- グループのデベロッパーロール以上が必要です。

連絡先を作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **顧客関係**を選択します。
1. **新しい連絡先**を選択します。
1. 必須フィールドをすべて入力します。
1. **Create new contact**（新しい連絡先）を選択します。

GraphQL APIを使用して連絡先を[作成](../../api/graphql/reference/_index.md#mutationcustomerrelationscontactcreate)することもできます。

### 連絡先の編集 {#edit-a-contact}

前提要件: 

- グループのデベロッパーロール以上が必要です。

既存の連絡先を編集するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **顧客関係**を選択します。
1. 編集する連絡先の横にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. 必須フィールドを編集します。
1. **変更を保存**を選択します。

GraphQL APIを使用して連絡先を[編集](../../api/graphql/reference/_index.md#mutationcustomerrelationscontactupdate)することもできます。

#### 連絡先の状態の変更 {#change-the-state-of-a-contact}

各連絡先は、次の2つの状態のいずれかになります:

- **有効**：この状態の連絡先は、イシューに追加できます。
- **無効**：この状態の連絡先は、イシューに追加できません。

連絡先の状態を変更するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **顧客関係**を選択します。
1. 編集する連絡先の横にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. **有効**チェックボックスをオンまたはオフにします。
1. **変更を保存**を選択します。

## 組織 {#organizations}

### 組織の表示 {#view-organizations}

前提要件: 

- グループのプランナーロール以上を持っている必要があります。

グループの組織を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **顧客関係**を選択します。
1. 右上にある**組織**を選択します。

![組織リスト](crm_organizations_v14_10.png)

### 組織の作成 {#create-an-organization}

前提要件: 

- グループのデベロッパーロール以上が必要です。

組織を作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **顧客関係**を選択します。
1. 右上にある**組織**を選択します。
1. **新しい組織**を選択します。
1. 必須フィールドをすべて入力します。
1. **Create new organization**（新しい組織）を選択します。

GraphQL APIを使用して組織を[作成](../../api/graphql/reference/_index.md#mutationcustomerrelationsorganizationcreate)することもできます。

### 組織を編集 {#edit-an-organization}

前提要件: 

- グループのデベロッパーロール以上が必要です。

既存の組織を編集するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **顧客関係**を選択します。
1. 右上にある**組織**を選択します。
1. 編集する組織の横にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. 必須フィールドを編集します。
1. **変更を保存**を選択します。

GraphQL APIを使用して組織を[編集](../../api/graphql/reference/_index.md#mutationcustomerrelationsorganizationupdate)することもできます。

## イシュー {#issues}

[サービスデスク](../project/service_desk/_index.md)を使用してメールからイシューを作成する場合、イシューは、メールの送信者とCCのメールアドレスに一致する連絡先にリンクされます。

### 連絡先にリンクされたイシューの表示 {#view-issues-linked-to-a-contact}

前提要件: 

- グループのプランナーロール以上を持っている必要があります。

連絡先のイシューを表示するには、イシューサイドバーから連絡先を選択するか:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **顧客関係**を選択します。
1. イシューを表示する連絡先の横にある**イシューを表示**（{{< icon name="issues" >}}）を選択します。

### 組織にリンクされたイシューの表示 {#view-issues-linked-to-an-organization}

前提要件: 

- グループのプランナーロール以上を持っている必要があります。

組織のイシューを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **顧客関係**を選択します。
1. 右上にある**組織**を選択します。
1. イシューを表示する組織の横にある**イシューを表示**（{{< icon name="issues" >}}）を選択します。

### イシューにリンクされた連絡先の表示 {#view-contacts-linked-to-an-issue}

前提要件: 

- グループのプランナーロール以上を持っている必要があります。

イシューに関連付けられている連絡先を右側のサイドバーで表示できます。

連絡先の詳細を表示するには、連絡先の名前の上にカーソルを合わせるます。

![イシューの連絡先](issue_crm_contacts_v14_6.png)

[GraphQL](../../api/graphql/reference/_index.md#mutationcustomerrelationsorganizationcreate) APIを使用して、イシューの連絡先を表示することもできます。

### イシューへの連絡先の追加 {#add-contacts-to-an-issue}

前提要件: 

- グループのプランナーロール以上を持っている必要があります。

イシューに[有効](#change-the-state-of-a-contact)な連絡先を追加するには、`/add_contacts [contact:address@example.com]` [クイックアクション](../project/quick_actions.md)を使用します。

[GraphQL](../../api/graphql/reference/_index.md#mutationissuesetcrmcontacts) APIを使用して、イシューの連絡先を追加、削除、または置換することもできます。

### イシューからの連絡先の削除 {#remove-contacts-from-an-issue}

前提要件: 

- グループのプランナーロール以上を持っている必要があります。

イシューから連絡先を削除するには、`/remove_contacts [contact:address@example.com]` [クイックアクション](../project/quick_actions.md)を使用します。

[GraphQL](../../api/graphql/reference/_index.md#mutationissuesetcrmcontacts) APIを使用して、イシューの連絡先を追加、削除、または置換することもできます。

## オートコンプリート連絡先 {#autocomplete-contacts}

{{< history >}}

- `contacts_autocomplete`という名前の[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 14.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/2256)されました。デフォルトでは無効になっています。
- GitLab 15.0の[GitLab.comおよびGitLab Self-Managedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/352123)。
- GitLab 15.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/352123)となりました。[機能フラグ`contacts_autocomplete`](https://gitlab.com/gitlab-org/gitlab/-/issues/352123)は削除されました。

{{< /history >}}

`/add_contacts`クイックアクションを使用すると、`[contact:`が続き、[有効](#change-the-state-of-a-contact)な連絡先を含むオートコンプリートリストが表示されます:

```plaintext
/add_contacts [contact:
```

`/remove_contacts`クイックアクションを使用すると、`[contact:`が続き、イシューに追加された連絡先を含むオートコンプリートリストが表示されます:

```plaintext
/remove_contacts [contact:
```

## CRMエントリを使用したオブジェクトの移行 {#moving-objects-with-crm-entries}

イシューまたはプロジェクトを移行し、**parent group contact source matches**（親グループの連絡先のソースが一致）すると、イシューは連絡先を保持します。

イシューまたはプロジェクトを移行し、**parent group contact source changes**（親グループの連絡先のソースが変更）されると、イシューは連絡先を失います。

[連絡先のソースが構成](#configure-the-contact-source)されているグループを移行するか、**contact source remains unchanged**（連絡先のソースが変更されない）場合、イシューは連絡先を保持します。

グループとその**contact source changes**（連絡先のソースが変更）された場合:

- すべての一意の連絡先と組織が新しいトップレベルグループに移行されます。
- （メールアドレスで）すでに存在する連絡先は、重複と見なされて削除されます。
- （名前で）すでに存在する組織は、重複と見なされて削除されます。
- すべてのイシューは連絡先を保持するか、同じメールアドレスの連絡先を指すように更新されます。

新しいトップレベルグループで連絡先と組織を作成する権限がない場合、グループの転送は失敗します。
