---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: カスタムロール
---

{{< details >}}

- プラン: Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.7で、`customizable_roles`という名前の[フラグ付き](../../administration/feature_flags.md)でカスタムロール機能が[導入されました。](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106256)
- GitLab 15.9で、[デフォルトで有効になりました。](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810)
- GitLab 15.10で、[機能フラグが削除されました。](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114524)
- UIを使用したカスタムロールの作成および削除機能がGitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/393235)。
- UIを使用して、カスタムロールを持つユーザーをグループに追加したり、ユーザーのカスタムロールを変更したり、グループメンバーからカスタムロールを削除したりする機能が、GitLab 16.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/393239)。
- GitLab Self-Managedでインスタンス全体のカスタムロールを作成および削除する機能が、GitLab 16.9で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141562)。

{{< /history >}}

カスタムロールを使用すると、組織は、組織のニーズに必要な正確な権限と許可を持つユーザーロールを作成できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> カスタムロール機能のデモについては、[[Demo] Ultimate Guest can view code on private repositories via custom role](https://www.youtube.com/watch?v=46cp_-Rtxps)（デモ: Ultimate Guestがカスタムロールを使用してプライベートリポジトリのコードを表示）を参照してください。

個々のカスタムロールと権限のリクエストについては、[イシュー391760](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)で議論できます。

{{< alert type="note" >}}

ほとんどのカスタムロールは、[シートを使用する請求対象ユーザー](#billing-and-seat-usage)と見なされます。カスタムロールを持つユーザーをグループに追加するときに、サブスクリプションに含まれている数よりも多くのシートを持っており追加料金が発生しようとしている場合、警告が表示されます。

{{< /alert >}}

## 利用可能な権限

利用可能な権限の詳細については、[カスタム権限](abilities.md)を参照してください。

{{< alert type="warning" >}}

ゲストなどの下位の基本ロールに追加された権限によっては、カスタムロールを持つユーザーは、通常、メンテナーロール以上のユーザーに制限されているアクションを実行できる場合があります。たとえば、カスタムロールがゲストであり、CI/CD変数を管理する権限がある場合、このロールを持つユーザーは、そのグループまたはプロジェクトの他のメンテナーまたはオーナーによって追加されたCI/CD変数を管理できます。

{{< /alert >}}

## カスタムロールを作成する

基本ロールに[権限](#available-permissions)を追加して、カスタムロールを作成します。そのカスタムロールには、複数の権限を追加することが可能です。たとえば、次のすべてを実行できる権限を持つカスタムロールを作成できます。

- 脆弱性レポートの表示
- 脆弱性のステータス変更
- マージリクエストの承認

### GitLab SaaS

前提要件:

- トップレベルグループのオーナーロールが必要です。

1. 左側のサイドバーで、**検索または移動**を選択して、グループを見つけます。
1. **設定 > ロールと権限**を選択します。
1. **新しいロール**を選択します。
1. **Base role to use as template(テンプレートとして使用する基本ロール)**で、既存のデフォルトロールを選択します。
1. **Role name(ロール名)**に、カスタムロールのタイトルを入力します。
1. **説明**に、カスタムロールの説明を入力します。最大255文字です。
1. 新しいカスタムロールの**権限**を選択します。
1. **ロールを作成する**を選択します。

**設定 > ロールと権限**で、すべてのカスタムロールのリストに以下が表示されます。

- カスタムロール名。
- ロールID。
- カスタムロールがテンプレートとして使用する基本ロール。
- 権限。

### GitLab Self-Managed

前提要件:

- GitLab Self-Managedインスタンスの管理者である必要があります。

GitLab Self-Managedインスタンスのカスタムロールを作成したら、そのインスタンス内の任意のグループまたはサブグループのユーザーにそのカスタムロールを割り当てることができます。

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > ロールと権限**を選択します。
1. **新しいロール**を選択します。
1. **Base role to use as template(テンプレートとして使用する基本ロール)**で、既存のデフォルトロールを選択します。
1. **Role name(ロール名)**に、カスタムロールのタイトルを入力します。
1. **説明**に、カスタムロールの説明を入力します。最大255文字です。
1. 新しいカスタムロールの**権限**を選択します。
1. **ロールを作成する**を選択します。

**設定 > ロールと権限**で、すべてのカスタムロールのリストに以下が表示されます。

- カスタムロール名。
- ロールID。
- カスタムロールがテンプレートとして使用する基本ロール。
- 権限。

カスタムロールの作成には、[APIを使用する](../../api/graphql/reference/_index.md#mutationmemberrolecreate)こともできます。

## カスタムロールを編集する

{{< history >}}

- GitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/437590)。

{{< /history >}}

カスタムロールを作成した後、そのカスタムロールの名前、説明、および権限を編集できます。基本ロールは変更できません。基本ロールを変更する必要がある場合は、新しいカスタムロールを作成する必要があります。

### GitLab SaaS

前提要件:

- グループのオーナーロールが必要です。

1. 左側のサイドバーで、**検索または移動**を選択して、グループを見つけます。
1. **設定 > ロールと権限**を選択します。
1. カスタムロールの縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**ロールを編集**を選択します。
1. 必要に応じてロールを変更します。
1. **ロールを保存**を選択して、ロールを更新します。

### GitLab Self-Managed

前提要件:

- GitLab Self-Managedインスタンスの管理者である必要があります。

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > ロールと権限**を選択します。
1. カスタムロールの縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**ロールを編集**を選択します。
1. 必要に応じてロールを変更します。
1. **ロールを保存**を選択して、ロールを更新します。

カスタムロールの編集には、[APIを使用する](../../api/graphql/reference/_index.md#mutationmemberroleupdate)こともできます。

## カスタムロールを削除する

前提要件:

- グループの管理者であるか、オーナーのロールを持っている必要があります。

そのロールが割り当てられているメンバーがいる場合は、グループからカスタムロールを削除できません。[グループまたはプロジェクトメンバーからのカスタムロールの割り当て解除](#unassign-a-custom-role-from-a-group-or-project-member)を参照してください。

1. 左側のサイドバーで、次を実行します。
   - Self-Managedの場合は、下部にある**管理者**を選択します。
   - SaaSの場合は、**検索または移動**を選択して、グループを見つけます。
1. **設定 > ロールと権限**を選択します。
1. **カスタムロール**を選択します。
1. **アクション**列で、**ロールを削除**（{{< icon name="remove" >}}）を選択して確認します。

[API](../../api/graphql/reference/_index.md#mutationmemberroledelete)を使用してカスタムロールを削除することもできます。APIを使用するには、カスタムロールの`id`を指定する必要があります。この`id`が不明な場合は、[グループに対するAPIリクエスト](../../api/graphql/reference/_index.md#groupmemberroles)または[インスタンスに対するAPIリクエスト](../../api/graphql/reference/_index.md#querymemberroles)を行うことで見つけることができます。

## カスタムロールを持つユーザーをグループまたはプロジェクトに追加する

前提要件:

カスタムロールを持つユーザーを追加する場合、

- グループに追加するには、グループのオーナーロールが必要です。
- プロジェクトに追加するには、プロジェクトのメンテナーロール以上が必要です。

カスタムロールを持つユーザーを追加するには、次の手順に従います。

- グループについては、[グループへのユーザーの追加](../group/_index.md#add-users-to-a-group)を参照してください。
- プロジェクトについては、[プロジェクトへのユーザーの追加](../project/members/_index.md#add-users-to-a-project)を参照してください。

グループまたはプロジェクトメンバーにカスタムロールがある場合、[group or project members list(グループまたはプロジェクトのメンバーリスト)](../group/_index.md#view-group-members)テーブルの**最上位のロール**列に**カスタムロール**が表示されます。

## 既存のグループまたはプロジェクトメンバーにカスタムロールを割り当てる

前提要件:

既存のメンバーにカスタムロールを割り当てる場合、

- グループメンバーの場合は、グループのオーナーロールが必要です。
- プロジェクトメンバーの場合は、プロジェクトのメンテナーロール以上が必要です。

### UIを使用してカスタムロールを割り当てる

1. 左側のサイドバーで、**検索または移動**を選択して、グループまたはプロジェクトを見つけます。
1. **管理 > メンバー**を選択します。
1. **最上位のロール**列で、メンバーのロールを選択します。**ロールの詳細**ドロワーが開きます。
1. **ロール**ドロップダウンリストを使用して、メンバーに割り当てるカスタムロールを選択します。
1. **ロールの更新**を選択して、ロールを割り当てます。

### APIを使用してカスタムロールを割り当てる

1. トップレベルグループまたはトップレベルグループの階層内の任意のサブグループまたはプロジェクトに、ユーザーをゲストとして直接メンバーとして招待します。この時点では、このゲストユーザーは、グループまたはサブグループ内のプロジェクトのコードを表示できません。
1. （オプション）カスタムロールを受け取るゲストユーザーの`id`が不明な場合は、[APIリクエスト](../../api/member_roles.md)を作成してその`id`を見つけます。
1. [グループおよびプロジェクトメンバーAPIエンドポイント](../../api/members.md#edit-a-member-of-a-group-or-project)を使用して、メンバーをゲスト+1ロールに関連付けます。

   ```shell
   # to update a project membership
   curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": '<member_role_id>', "access_level": 10}' "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"

   # to update a group membership
   curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": '<member_role_id>', "access_level": 10}' "https://gitlab.example.com/api/v4/groups/<group_id>/members/<user_id>"
   ```

   各設定項目の意味は次のとおりです。

   - `<project_id`と`<group_id>`: カスタムロールを受け取るメンバーシップに関連付けられている、`id`または[プロジェクトまたはグループのURLエンコードされたパス](../../api/rest/_index.md#namespaced-paths)。
   - `<member_role_id>`: 前のセクションで作成されたメンバーロールの`id`。
   - `<user_id>`: カスタムロールを受け取るユーザーの`id`。

   これで、ゲスト+1ユーザーは、このメンバーシップに関連付けられているすべてのプロジェクトのコードを表示できます。

## グループまたはプロジェクトメンバーからのカスタムロールを割り当て解除する

前提要件:

カスタムロールを割り当て解除する場合、

- グループメンバーの場合は、グループのオーナーロールが必要です。
- プロジェクトメンバーの場合は、プロジェクトのメンテナーロール以上が必要です。

グループまたはプロジェクトメンバーにそのロールがない場合にのみ、グループまたはプロジェクトからカスタムロールを削除できます。これを行うには、次のいずれかの方法を使用します。

- カスタムロールを持つメンバーを[グループ](../group/_index.md#remove-a-member-from-the-group)または[プロジェクト](../project/members/_index.md#remove-a-member-from-a-project)から削除します。
- [UIを使用してユーザーロールを変更します](#use-the-ui-to-change-user-role)。
- [APIを使用してユーザーロールを変更します](#use-the-api-to-change-user-role)。

### UIを使用してユーザーロールを変更する

グループメンバーからカスタムロールを削除するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、グループを見つけます。
1. **管理 > メンバー**を選択します。
1. **最上位のロール**列で、メンバーのロールを選択します。**ロールの詳細**ドロワーが開きます。
1. **ロール**ドロップダウンリストを使用して、メンバーに割り当てるデフォルトロールを選択します。
1. **ロールの更新**を選択して、ロールを割り当てます。

### APIを使用してユーザーロールを変更する

[グループおよびプロジェクトメンバーAPIエンドポイント](../../api/members.md#edit-a-member-of-a-group-or-project)を使用して、空の`member_role_id`値を渡すことで、グループメンバーからカスタムロールを更新または削除することもできます。

```shell
# to update a project membership
curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": null, "access_level": 10}' "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"

# to update a group membership
curl --request PUT --header "Content-Type: application/json" --header "Authorization: Bearer <your_access_token>" --data '{"member_role_id": null, "access_level": 10}' "https://gitlab.example.com/api/v4/groups/<group_id>/members/<user_id>"
```

## 継承

ユーザーがグループに属している場合、そのユーザーはグループの直接メンバーであり、サブグループまたはプロジェクトの[継承されたメンバー](../project/members/_index.md#membership-types)です。ユーザーにトップレベルグループによってカスタムロールが割り当てられている場合、そのロールの権限はサブグループおよびプロジェクトにも継承されます。

たとえば、次の構造が存在するとします。

- グループA
  - サブグループB
    - プロジェクト1

デベロッパーロールと`Manage CI/CD variables`権限を持つカスタムロールがグループAに割り当てられている場合、ユーザーはサブグループBおよびプロジェクト1でも`Manage CI/CD variables`権限を持ちます。

## 課金とシートの使用状況

ゲストロールを持つユーザーにカスタムロールを割り当てると、そのユーザーは基本ロールよりも高い権限を持つようになるため、

- GitLab Self-Managedでは[請求対象ユーザー](../../subscriptions/self_managed/_index.md#billable-users)と見なされます。
- GitLab.comで[シートを使用します](../../subscriptions/gitlab_com/_index.md#how-seat-usage-is-determined)。

これは、ユーザーのカスタムロールで`read_code`権限のみが有効になっている場合には適用されません。その特定の権限のみを持つゲストユーザーは、請求対象ユーザーとは見なされず、シートを使用しません。

## 招待されたグループにカスタムロールを割り当てる

{{< history >}}

- 機能フラグ`assign_custom_roles_to_group_links_sm`の背後にある、GitLab 17.4で[導入済み](https://gitlab.com/gitlab-org/gitlab/-/issues/443369)の招待されたグループのカスタムロールがサポートされるようになりました。デフォルトでは無効になっています。
- GitLab 17.4で、[GitLab Self-ManagedおよびGitLab Dedicatedが有効](https://gitlab.com/gitlab-org/gitlab/-/issues/471999)となりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

グループがカスタムロールで別のグループに招待された場合、次のルールに基づいて、新しいグループの各ユーザーのカスタム権限が決定されます。

- ユーザーが、別のグループのデフォルトロールと同じかそれよりも高い基本アクセスレベルを持つ1つのグループでカスタム権限を持っている場合、ユーザーの最大ロールはデフォルトロールになります。つまり、ユーザーには2つのアクセスレベルのうち低い方が付与されます。
- ユーザーが、元のグループと同じ基本アクセスレベルを持つカスタム権限で招待された場合、ユーザーには常に元のグループからのカスタム権限が付与されます。

たとえば、グループAに5人のユーザーがいて、次のロールが割り当てられているとしましょう。

- ユーザーA: ゲストロール
- ユーザーB: ゲストロール + `read_code`カスタム権限
- ユーザーC: ゲストロール + `read_vulnerability`カスタム権限
- ユーザーD: デベロッパーロール
- ユーザーE: デベロッパー + `admin_vulnerability`カスタム権限

グループBがグループAを招待します。次の表は、グループAの各ユーザーがグループBで持つ最大ロールを示しています。

| シナリオ                                                       | ユーザーA | ユーザーB              | ユーザーC                       | ユーザーD                       | ユーザーE                            |
|----------------------------------------------------------------|--------|---------------------|------------------------------|------------------------------|-----------------------------------|
| グループBがゲストでグループAを招待する                             | ゲスト  | ゲスト               | ゲスト                        | ゲスト                        | ゲスト                             |
| グループBがゲスト + `read_code`でグループAを招待する               | ゲスト  | ゲスト + `read_code` | ゲスト + `read_vulnerability` | ゲスト + `read_code`          | ゲスト + `read_code`               |
| グループBがゲスト + `read_vulnerability`でグループAを招待する      | ゲスト  | ゲスト + `read_code` | ゲスト + `read_vulnerability` | ゲスト + `read_vulnerability` | ゲスト + `read_vulnerability`      |
| グループBがデベロッパーでグループAを招待する                         | ゲスト  | ゲスト + `read_code` | ゲスト + `read_vulnerability` | デベロッパー                    | デベロッパー                         |
| グループBがデベロッパー + `admin_vulnerability`でグループAを招待する | ゲスト  | ゲスト + `read_code` | ゲスト + `read_vulnerability` | デベロッパー                    | デベロッパー + `admin_vulnerability` |

ユーザーCがグループBに同じデフォルトロール（ゲスト）で招待された場合でも、同じベースアクセスレベル（`read_code`と`read_vulnerability`）で異なるカスタム権限を持つ場合、ユーザーCはグループAからのカスタム権限（`read_vulnerability`）を保持します。プロジェクトにグループを共有する際にカスタムロールを割り当てる機能は、[イシュー468329](https://gitlab.com/gitlab-org/gitlab/-/issues/468329)で追跡できます。

## サポートされているオブジェクト

以下のものにカスタムロールと権限を割り当てることができます。

| オブジェクト       | バージョン       | イシュー                                                  |
| ----         | ----          | ----                                                   |
| ユーザー        | 15.9          | リリース済み                                               |
| グループ       | 17.7          | 部分的にサポートされています。プロジェクトでのグループ割り当てのさらなるサポートは、[イシュー468329](https://gitlab.com/gitlab-org/gitlab/-/issues/468329)で提案されています  |
| トークン       | サポートされていません | [イシュー 434354](https://gitlab.com/gitlab-org/gitlab/-/issues/434354) |

## サポートされているグループリンク

以下の認証プロバイダーで、ユーザーをカスタムロールに同期できます。

- [SAMLグループリンクの設定](../group/saml_sso/group_sync.md#configure-saml-group-links)を参照してください。
- [LDAP経由でのグループメンバーシップの管理](../group/access_and_permissions.md#manage-group-memberships-with-ldap)を参照してください。

## カスタム管理者ロール

{{< history >}}

- GitLab 17.7で[実験](../../policy/development_stages_support.md)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/15854)され、`custom_ability_read_admin_dashboard`という名前の[フラグ](../../administration/feature_flags.md)が付けられています。

{{< /history >}}

前提要件:

- GitLab Self-Managedインスタンスの管理者である必要があります。

APIを使用して、カスタム管理者ロールを[作成](../../api/graphql/reference/_index.md#mutationmemberroleadmincreate)および[割り当て](../../api/graphql/reference/_index.md#mutationmemberroletouserassign)できます。これらのロールを使用すると、管理者リソースへのアクセスを制限できます。

利用可能な権限については、[カスタム権限](abilities.md)を参照してください。

## 新しい権限をコントリビュートする

権限が存在しない場合、以下を実行できます。

権限が存在しない場合、以下を実行できます。

- [permission proposal issue template(権限提案イシューテンプレート)](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Permission%2520Proposal)を使用して、権限をリクエストするイシューを作成します。
- GitLabにコントリビュートして、[権限を追加](../../development/permissions/custom_roles.md)します。

## 既知の問題

- カスタムロールを持つユーザーがグループまたはプロジェクトと共有されている場合、そのカスタムロールは転送されません。ユーザーは、新しいグループまたはプロジェクトで標準のゲストロールを持ちます。
- [監査担当者ユーザー](../../administration/auditor_users.md)をカスタムロールのテンプレートとして使用することはできません。
- インスタンスまたはネームスペースに存在できるカスタムロールは10個のみです。詳細については、[イシュー450929](https://gitlab.com/gitlab-org/gitlab/-/issues/450929)を参照してください。
