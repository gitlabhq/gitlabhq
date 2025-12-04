---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duoのサブスクリプションアドオンを見つけて、シートを割り当てます。
title: GitLab Duoアドオン
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。
- UIのGitLab Duo Chat (Classic) が、GitLab 18.3で[Coreに追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)されました。
- [自己管理インスタンスでシートの割り当てに関するメールを無効にする機能が追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/557290)（GitLab 18.4）。

{{< /history >}}

GitLab Duoアドオンは、PremiumまたはUltimateのサブスクリプションをAIネイティブな機能で拡張します。GitLab Duoを使用すると、開発ワークフローを加速し、反復的なコードタスクを削減し、プロジェクト全体のより深いインサイトを得ることができます。

3つのアドオンが利用可能です: GitLab Duo Core、Pro、およびEnterprise。

各アドオンは、[GitLab Duo機能のセット](../user/gitlab_duo/feature_summary.md)へのアクセスを提供します。

## GitLab Duo Core {#gitlab-duo-core}

以下をお持ちの場合、GitLab Duo Coreが自動的に含まれます:

- GitLab 18.0以降。
- PremiumまたはUltimateサブスクリプション。

GitLab 17.11以前から利用している場合は、[WebまたはIDEの機能をオンにする](../user/gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)と、GitLab Duo Coreの使用を開始する必要があります。

GitLab 18.0以降の新規ユーザーの場合、GitLab Duo Coreの機能は自動的にオンになり、それ以上のアクションは必要ありません。

GitLab Duo Coreにどのロールがアクセスできるかを確認するには、[GitLab Duoグループの権限](../user/permissions.md#gitlab-duo-group-permissions)を参照してください。

### GitLab Duo Self-Hosted {#gitlab-duo-self-hosted}

オフラインライセンスをお持ちのお客様の場合、GitLab Duo CoreはGitLab Duoセルフホストでは利用できません。GitLab Duo CoreがGitLab AIゲートウェイへの接続を必要とするためです。

オンラインライセンスをお持ちのお客様は、GitLab Duo CoreをGitLab Duoセルフホストと組み合わせて使用できますが、GitLab Duo Coreを有効にするには、インスタンス全体のGitLab Duoチャットおよびコード提案にGitLab AIベンダーモデルを選択する必要があります。

### GitLab Duo Coreの制限 {#gitlab-duo-core-limits}

[GitLab利用規約](https://about.gitlab.com/terms/)とともに、利用制限は、PremiumおよびUltimateプランのお客様による、含まれているコード提案およびGitLab Duoチャット機能の使用に適用されます。

GitLabは、これらの制限の施行が開始される30日前までに事前通知を提供します。その時点で、組織の管理者は、消費を監視および管理するためのツールを持ち、追加の容量を購入できるようになります。

| 機能          | 1ユーザーあたりの月間リクエスト数 |
|------------------|-----------------------------|
| コード提案 | 2,000                       |
| GitLab Duo Chat  | 100                         |

制限は、GitLab Duo ProまたはGitLab Duo Enterpriseには適用されません。

## GitLab Duo ProとGitLab Duo Enterprise {#gitlab-duo-pro-and-enterprise}

GitLab Duo ProおよびGitLab Duo Enterpriseでは、シートを購入してチームメンバーに割り当てる必要があります。シートベースのモデルにより、特定のチームのニーズに基づいて、機能へのアクセスとコスト管理を制御できます。

## Purchase GitLab Duo {#purchase-gitlab-duo}

GitLab Duo Enterpriseを購入するには、[GitLabセールスチーム](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)にお問い合わせください。

GitLab Duo Proのシートを購入するには、カスタマーポータルを使用するか、[GitLabセールスチーム](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)にお問い合わせください。

ポータルを使用するには、次の手順に従います:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/)にサインインします。
1. サブスクリプションカードで、縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **Buy GitLab Duo Pro**（GitLab Duo Proを購入する） を選択します。
1. GitLab Duoのシート数を入力します。
1. **Purchase summary**（購入の概要）セクションを確認します。
1. **Payment method**ドロップダウンリストから、お支払い方法を選択します。
1. **ライセンスを購入する**を選択します。

## GitLab Duoのシートを追加購入する {#purchase-additional-gitlab-duo-seats}

グループネームスペースまたはSelf-Managedインスタンス用に、GitLab Duo ProまたはGitLab Duo Enterpriseのシートを追加購入できます。購入が完了すると、シートはサブスクリプション内のGitLab Duoのシートの合計数に追加されます。

前提要件: 

- GitLab Duo ProまたはGitLab Duo Enterpriseアドオンを購入する必要があります。

### GitLab.comの場合 {#for-gitlabcom}

前提要件: 

- オーナーロールを持っている必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. **ライセンスを購入する**を選択します。
1. カスタマーポータルの**シートの追加**フィールドに、シートの数を入力します。金額は、グループネームスペースに関連付けられているサブスクリプション内のシート数を超えることはできません。
1. **Billing information**（料金情報）セクションで、ドロップダウンリストから支払い方法を選択します。
1. **Privacy Policy**（プライバシーポリシー）と**Terms of Service**（利用規約）のチェックボックスを選択します。
1. **ライセンスを購入する**を選択します。
1. **GitLab SaaS**タブを選択し、ページを更新します。

### GitLab Self-ManagedおよびGitLab Dedicatedの場合 {#for-gitlab-self-managed-and-gitlab-dedicated}

前提要件: 

- 管理者である必要があります。

1. [GitLabカスタマーポータル](https://customers.gitlab.com/)にサインインします。
1. サブスクリプションカードの**GitLab Duo Pro**セクションで、**シートを追加**を選択します。
1. シートの数を入力します。金額は、サブスクリプション内のシート数を超えることはできません。
1. **Purchase summary**（購入の概要）セクションを確認します。
1. **Payment method**ドロップダウンリストから、お支払い方法を選択します。
1. **ライセンスを購入する**を選択します。

## Assign GitLab Duo seats {#assign-gitlab-duo-seats}

前提要件: 

- GitLab Duo ProまたはGitLab Duo Enterpriseアドオンを購入するか、アクティブなGitLab Duoトライアルが必要です。
- GitLab Self-ManagedおよびGitLab Dedicatedの場合:
  - GitLab Duo Proアドオンは、GitLab 16.8以降で利用可能です。
  - GitLab Duo Enterpriseアドオンは、GitLab 17.3以降でのみ利用可能です。

GitLab Duo ProまたはGitLab Duo Enterpriseを購入すると、ユーザーにシートを割り当てて、アドオンへのアクセスを許可できます。

### GitLab.comの場合 {#for-gitlabcom-1}

前提要件: 

- オーナーロールを持っている必要があります。

プロジェクトまたはグループでGitLab Duo機能を使用するには、少なくとも1つのトップレベルグループでユーザーにシートを割り当てる必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. ユーザーの右側にある切り替えをオンにして、GitLab Duoのシートを割り当てます。

ユーザーに確認メールが送信されます。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed}

前提要件: 

- 管理者である必要があります。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
   - **GitLab Duo**メニュー項目が使用できない場合は、購入後にサブスクリプションを同期します:
     1. 左側のサイドバーで、**サブスクリプション**を選択します。
     1. **サブスクリプションの詳細**の**最後の同期**の右側で、サブスクリプションの同期（{{< icon name="retry" >}}）を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. ユーザーの右側にある切り替えをオンにして、GitLab Duoのシートを割り当てます。

ユーザーに確認メールが送信されます。

- このメールを無効にするには、`sm_duo_seat_assignment_email`機能フラグを`false`に設定します。この機能フラグは、デフォルトで有効になっています。

シートを割り当てたら、[GitLab DuoがGitLab Self-Managedインスタンス用にセットアップされていることを確認してください](../user/gitlab_duo/setup.md)。

## シートの割り当てと一括消去 {#assign-and-remove-gitlab-duo-seats-in-bulk}

複数のユーザーに対して、シートを一括で割り当てたり、消去したりできます。

### SAML Group Sync {#saml-group-sync}

GitLab.comグループは、SAMLグループ同期を使用して[GitLab Duoのシートの割り当てを管理](../user/group/saml_sso/group_sync.md#manage-gitlab-duo-seat-assignment)できます。

### GitLab.comの場合 {#for-gitlabcom-2}

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. 右下のほうで、ページの表示を調整して、選択可能なユーザー数を増やすために**50**または**100**項目を表示できます。
1. シートを割り当てまたは消去するユーザーを選択します:
   - 複数のユーザーを選択するには、各ユーザーの左側にあるチェックボックスをオンにします。
   - すべて選択するには、テーブルの上部にあるチェックボックスをオンにします。
1. シートを割り当てまたは消去します:
   - シートを割り当てるには、**シートを割り当てる**、次に**シートをアサイン**を選択して確定します。
   - シートからユーザーを消去するには、**シートを消去**を選択し、次に**シートを消去**を選択して確定します。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed-1}

前提要件: 

- 管理者である必要があります。
- GitLab 17.5以降が必要です。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. 右下のほうで、ページの表示を調整して、選択可能なユーザー数を増やすために**50**または**100**項目を表示できます。
1. シートを割り当てまたは消去するユーザーを選択します:
   - 複数のユーザーを選択するには、各ユーザーの左側にあるチェックボックスをオンにします。
   - すべて選択するには、テーブルの上部にあるチェックボックスをオンにします。
1. シートを割り当てまたは消去します:
   - シートを割り当てるには、**シートを割り当てる**、次に**シートをアサイン**を選択して確定します。
   - シートからユーザーを消去するには、**シートを消去**を選択し、次に**シートを消去**を選択して確定します。
1. ユーザーの右側にある切り替えをオンにして、GitLab Duoのシートを割り当てます。

GitLab Self-Managedインスタンスの管理者は、[Rakeタスク](../administration/raketasks/user_management.md#bulk-assign-users-to-gitlab-duo)を使用して、シートを一括で割り当てたり、消去したりすることもできます。

#### LDAP構成でのGitLab Duoのシートの管理 {#managing-gitlab-duo-seats-with-ldap-configuration}

LDAPグループメンバーシップに基づいて、LDAP対応ユーザーのGitLab Duoのシートを自動的に割り当てたり、消去したりできます。

この機能を有効にするには、LDAP設定で[`duo_add_on_groups`プロパティを構成](../administration/auth/ldap/ldap_synchronization.md#gitlab-duo-add-on-for-groups)する必要があります。

`duo_add_on_groups`が構成されると、LDAP対応ユーザー間でのDuoシート管理の信頼できる唯一の情報源になります。詳細については、[シートの割り当てワークフロー](../administration/duo_add_on_seat_management_with_ldap.md#seat-management-workflow)を参照してください。

この自動化されたプロセスにより、組織のLDAPグループ構造に基づいて、Duoシートが効率的に割り当てられるようになります。詳細については、[LDAPを使用したGitLab Duoアドオンシート管理](../administration/duo_add_on_seat_management_with_ldap.md)を参照してください。

## 割り当てられたGitLab Duoユーザーを表示 {#view-assigned-gitlab-duo-users}

{{< history >}}

- 最後のGitLab DuoアクティビティーフィールドがGitLab 18.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/455761)。

{{< /history >}}

前提要件: 

- GitLab Duo ProまたはGitLab Duo Enterpriseアドオンを購入するか、アクティブなGitLab Duoトライアルが必要です。

GitLab Duo ProまたはGitLab Duo Enterpriseを購入すると、ユーザーにシートを割り当てて、アドオンへのアクセスを許可できます。次に、割り当てられたGitLab Duoユーザーの詳細を表示できます。

GitLab Duoシート使用状況ページには、各ユーザーに関する次の情報が表示されます:

- ユーザーの氏名とユーザー名
- シートの割り当てステータス
- 公開メールアドレス: ユーザーの公開プロファイルに表示されるメール。
- 最後のGitLabアクティビティー: ユーザーがGitLabで最後にアクションを実行した日付。
- 最後のGitLab Duoアクティビティー: ユーザーが最後にGitLab Duo機能を使用した日付。GitLab Duoのアクティビティーによって更新されます。

これらのフィールドは、[GraphQL API](../api/graphql/reference/_index.md#addonuser)の`AddOnUser`タイプからのデータを使用します。

### GitLab.comの場合 {#for-gitlabcom-3}

前提要件: 

- オーナーロールを持っている必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. フィルターバーから、**アサインされたシート**と**可能**を選択します。
1. ユーザーリストは、GitLab Duoのシートが割り当てられているユーザーのみにフィルター処理されます。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed-2}

前提要件: 

- 管理者である必要があります。
- GitLab 17.5以降が必要です。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
   - **GitLab Duo**メニュー項目が使用できない場合は、購入後にサブスクリプションを同期します:
     1. 左側のサイドバーで、**サブスクリプション**を選択します。
     1. **サブスクリプションの詳細**の**最後の同期**の右側で、サブスクリプションの同期（{{< icon name="retry" >}}）を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. GitLab Duoのシートに割り当てられたユーザーでフィルターするには、**ユーザーをフィルター**バーで、**アサインされたシート**を選択し、次に**可能**を選択します。
1. ユーザーリストは、GitLab Duoのシートが割り当てられているユーザーのみにフィルター処理されます。

## シートの自動消去 {#automatic-seat-removal}

GitLab Duoアドオンのシートは、対象となるユーザーのみがアクセスできるように、自動的に消去されます。これは、次の場合に発生します:

- シートの超過
- ブロック、BAN、および非アクティブ化されたユーザー

### サブスクリプションの有効期限時 {#at-subscription-expiration}

GitLab Duoアドオンを含むサブスクリプションが有効期限切れになった場合、シートの割り当ては28日間保持されます。サブスクリプションが更新された場合、またはこの28日間の期間中にGitLab Duoを含む新しいサブスクリプションが購入された場合、ユーザーは自動的に再度割り当てられます。それ以外の場合、シートの割り当ては消去され、ユーザーを再度割り当てる必要があります。

### シートの超過の場合 {#for-seat-overages}

購入したGitLab Duoアドオンのシートの数が減少した場合、サブスクリプションで利用可能なシートの数に合わせてシートの割り当てが自動的に消去されます。

例: 

- すべてのシートが割り当てられている50シートのGitLab Duo Proサブスクリプションがあります。
- 30シートのサブスクリプションを更新します。サブスクリプションを超える20人のユーザーは、GitLab Duo Proシートの割り当てから自動的に消去されます。
- 更新前に20人のユーザーのみがGitLab Duo Proシートに割り当てられていた場合、シートの消去は発生しません。

シートは、次の基準に基づいて、この順序で消去対象として選択されます:

1. まだコード提案を使用していないユーザー（最も最近割り当てられた順）。
1. コード提案を使用したユーザー（コード提案の最新の使用状況の少ない順）。

### ブロック、BAN、および非アクティブ化されたユーザーの場合 {#for-blocked-banned-and-deactivated-users}

1日に1～2回、CronJobがGitLab Duoシートの割り当てをレビューします。GitLab Duoのシートが割り当てられているユーザーがブロック、BAN、または非アクティブ化された場合、GitLab Duo機能へのアクセスは自動的に消去されます。

シートを削除すると、そのシートは利用可能になり、新しいユーザーに再割り当てできます。

## トラブルシューティング {#troubleshooting}

### UIを使用してユーザーに割り当てることができません {#unable-to-use-the-ui-to-assign-seats-to-your-users}

**使用量クォータ**ページで、次の両方の問題が発生した場合、UIを使用してユーザーにシートを割り当てることはできません:

- **シート**タブが読み込まれません。
- 次のエラーメッセージが表示されます:

  ```plaintext
  An error occurred while loading billable members list.
  ```

回避策として、[このスニペット](https://gitlab.com/gitlab-org/gitlab/-/snippets/3763094)内のGraphQLのクエリを使用して、ユーザーにシートを割り当てることができます。
