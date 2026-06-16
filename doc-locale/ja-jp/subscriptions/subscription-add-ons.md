---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duoサブスクリプションアドオンを検索し、シートを割り当てます。
title: GitLab Duoアドオン
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。
- GitLab Duo Non-Agentic ChatのUIは、GitLab 18.3で[Coreに追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)。
- GitLab 18.4で[セルフマネージドインスタンスでのシート割り当てメールを無効にする機能を追加しました](https://gitlab.com/gitlab-org/gitlab/-/issues/557290)。

{{< /history >}}

GitLab Duoアドオンは、PremiumまたはUltimateサブスクリプションをAIネイティブな機能で拡張します。GitLab Duoを使用して、開発ワークフローを加速し、反復的なコーディングタスクを削減し、プロジェクト全体のより深いインサイトを得ることができます。

3つのアドオンが利用可能です: GitLab Duo Core、Pro、およびEnterprise。

各アドオンは、[一連のGitLab Duo機能](../user/gitlab_duo/feature_summary.md)へのアクセスを提供します。

## GitLab Duo Core {#gitlab-duo-core}

{{< history >}}

- GitLab Duo Non-Agentic Chatへのアクセスは、2026年5月21日、GitLab 19.0の一部として、`no_duo_classic_for_duo_core_users`という名前の機能フラグにより、GitLab Duo Coreユーザーに対して削除されます。デフォルトでは有効になっています。

{{< /history >}}

以下の条件を満たしている場合、GitLab Duo Coreが自動的に含まれます:

- GitLab 18.0以降。
- PremiumまたはUltimateサブスクリプションを持っている。

GitLab 17.11以前からの既存のお客様は、[GitLab Duo Coreの機能をオンにする](../user/gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)必要があります。

GitLab 18.0以降の新規のお客様は、GitLab Duo Coreの機能が自動的にオンになるため、それ以上の操作は必要ありません。

GitLab Duo Coreにアクセスできるロールを確認するには、[GitLab Duoグループパーミッション](../user/permissions.md#group-gitlab-duo)を参照してください。

### GitLab Duo Self-Hosted {#gitlab-duo-self-hosted}

オフラインライセンスをお持ちの場合、GitLab Duo CoreはGitLab AIゲートウェイへの接続を必要とするため、GitLab Duo Self-Hostedでは利用できません。

オンラインライセンスをお持ちの場合は、GitLab Duo CoreをGitLab Duo Self-Hostedと組み合わせて使用できます。GitLab Duo Coreを使用するには、インスタンスのコード提案について、GitLabが管理するモデルを選択する必要があります。

### GitLab Duo Coreの制限 {#gitlab-duo-core-limits}

PremiumおよびUltimateのお客様の場合、GitLab Duo Coreにはコード提案へのアクセスが含まれ、GitLab 19.0以降ではGitLab Duo Agentic Chatへのアクセスも含まれます。

これらの機能へのアクセスは、[GitLab利用規約](https://about.gitlab.com/terms/)および[使用量課金](gitlab_credits.md)の対象となります。

GitLabは、これらの制限が施行される30日前に通知します。その時までに、組織の管理者は消費量を監視および管理するためのツールを持ち、追加の容量を購入できるようになります。

制限はGitLab Duo ProまたはEnterpriseには適用されません。

### GitLab Duo Core機能アクセスの変更 {#changes-to-gitlab-duo-core-feature-access}

2026年5月21日より、すべてのGitLabバージョンのGitLab Duo Coreユーザーは、GitLab Duo Non-Agentic Chatにアクセスできません。

代わりに、GitLab Duo Coreユーザーは、GitLab Duo Agent Platformの以下の機能を使用して、非エージェント型機能が実行していた質問への回答やタスクの完了を行うことができます:

- GitLab Duo Agentic Chat。
- 基盤、カスタム、および外部エージェント。
- 基本フローおよびカスタムフロー。
- GitLab Duoコード提案。

これらの機能を使用するには、[GitLabクレジット](gitlab_credits.md)が必要です。

Agent Platformの使用方法の詳細については、以下を参照してください:

- [GitLab Duo Chatプロンプトの例](../user/gitlab_duo_chat/example_prompts.md)
- [エージェント](../user/duo_agent_platform/agents/_index.md)
- [フロー](../user/duo_agent_platform/flows/_index.md)

## GitLab Duo ProおよびEnterprise {#gitlab-duo-pro-and-enterprise}

GitLab Duo ProおよびEnterpriseでは、シートを購入し、チームメンバーに割り当てる必要があります。シートベースのモデルにより、特定のチームのニーズに基づいて機能アクセスとコスト管理を制御できます。

## GitLab Duo Agent Platform Self-Hosted {#gitlab-duo-agent-platform-self-hosted}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.8で導入。

{{< /history >}}

オフラインライセンスをお持ちのお客様は、Agent Platformでセルフホストモデルを使用するために、GitLab Duo Agent Platform Self-Hostedアドオンを購入する必要があります。

このアドオンをお持ちのお客様は、[使用量](gitlab_credits.md)ではなくシートに基づいて課金されます。

オンラインライセンスをお持ちのお客様は、アドオンなしでAgent Platformのセルフホストモデルを使用でき、使用量に基づいて課金されます。

GitLab Duo Agent Platform Self-Hostedを購入するには、[GitLab営業チーム](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)にお問い合わせください。

## GitLab Duoの購入 {#purchase-gitlab-duo}

GitLab Duo Enterpriseを購入するには、[GitLab営業チーム](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)にお問い合わせください。

GitLab Duo Proのシートを購入するには、Customers Portalを使用するか、[GitLab営業チーム](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)にお問い合わせください。

ポータルを使用するには:

1. [GitLab Customers Portal](https://customers.gitlab.com/)にサインインします。
1. サブスクリプションカードで、縦方向の省略記号 ({{< icon name="ellipsis_v" >}}) を選択します。
1. **Buy GitLab Duo Pro**を選択します。
1. GitLab Duoのシート数を入力します。
1. **購入の概要**セクションを確認します。
1. **Payment method**ドロップダウンリストから、支払い方法を選択します。
1. **ライセンスを購入する**を選択します。

## 追加のGitLab Duoシートを購入する {#purchase-additional-gitlab-duo-seats}

GitLab Duo ProまたはGitLab Duo Enterpriseの追加のシートを、グループネームスペースまたはSelf-Managedインスタンスに対して購入できます。購入が完了すると、シートはサブスクリプション内の合計GitLab Duoシート数に追加されます。

前提条件: 

- GitLab Duo ProまたはGitLab Duo Enterpriseアドオンを購入する必要があります。

### GitLab.comの場合 {#for-gitlabcom}

前提条件: 

- オーナーロールを持っている必要があります。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**設定** > **GitLab Duo**を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. **ライセンスを購入する**を選択します。
1. Customers Portalの**シートの追加**フィールドに、シート数を入力します。その数量は、グループネームスペースに関連付けられているサブスクリプションのシート数を超えることはできません。
1. **料金情報**セクションで、ドロップダウンリストから支払い方法を選択します。
1. **Privacy Policy**と**Terms of Service**チェックボックスを選択します。
1. **ライセンスを購入する**を選択します。
1. **GitLab SaaS**タブを選択し、ページを更新します。

### GitLab Self-ManagedおよびGitLab Dedicatedの場合 {#for-gitlab-self-managed-and-gitlab-dedicated}

前提条件: 

- 管理者である必要があります。

1. [GitLab Customers Portal](https://customers.gitlab.com/)にサインインします。
1. サブスクリプションカードの**GitLab Duo Pro**セクションで**シートを追加**を選択します。
1. シート数を入力します。その数量は、サブスクリプションのシート数を超えることはできません。
1. **購入の概要**セクションを確認します。
1. **Payment method**ドロップダウンリストから、支払い方法を選択します。
1. **ライセンスを購入する**を選択します。

## GitLab Duoシートを割り当てる {#assign-gitlab-duo-seats}

前提条件: 

- GitLab Duo ProまたはEnterpriseアドオンを購入するか、アクティブなGitLab Duoトライアルをお持ちである必要があります。
- GitLab Self-ManagedおよびGitLab Dedicatedの場合:
  - GitLab Duo Proアドオンは、GitLab 16.8以降で利用可能です。
  - GitLab Duo Enterpriseアドオンは、GitLab 17.3以降でのみ利用可能です。

GitLab Duo ProまたはEnterpriseを購入した後、アドオンへのアクセスを許可するために、ユーザーにシートを割り当てることができます。

### GitLab.comの場合 {#for-gitlabcom-1}

前提条件: 

- オーナーロールを持っている必要があります。

いずれかのプロジェクトまたはグループでGitLab Duo機能を使用するには、ユーザーを少なくとも1つのトップレベルグループのシートに割り当てる必要があります。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**設定** > **GitLab Duo**を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. ユーザーの右側にある切替をオンにして、GitLab Duoシートを割り当てます。

ユーザーに確認メールが送信されます。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed}

前提条件: 

- 管理者である必要があります。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
   - **GitLab Duo**メニュー項目が利用できない場合は、購入後にサブスクリプションを同期してください:
     1. 左側のサイドバーで、**サブスクリプション**を選択します。
     1. **サブスクリプションの詳細**の**最終同期**の右側で、サブスクリプションの同期（{{< icon name="retry" >}}）を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. ユーザーの右側にある切替をオンにして、GitLab Duoシートを割り当てます。

ユーザーに確認メールが送信されます。

- このメールを無効にするには、`sm_duo_seat_assignment_email`機能フラグを`false`に設定します。このフラグはデフォルトで有効になっています。

シートを割り当てた後、[GitLab DuoがSelf-Managedインスタンス用にセットアップされていることを確認してください](../administration/gitlab_duo/configure/gitlab_self_managed.md)。

## GitLab Duoシートを一括で割り当ておよび削除 {#assign-and-remove-gitlab-duo-seats-in-bulk}

複数のユーザーに対して、シートを一括で割り当てたり削除したりできます。

### SAML Group同期 {#saml-group-sync}

GitLab.comグループは、SAML Group同期を使用して[GitLab Duoシートの割り当てを管理](../user/group/saml_sso/group_sync.md#manage-gitlab-duo-seat-assignment)できます。

### GitLab.comの場合 {#for-gitlabcom-2}

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**設定** > **GitLab Duo**を選択します。
1. 右下で、ページの表示を**50**または**100**項目に調整して、選択可能なユーザー数を増やすことができます。
1. シートを割り当てるか削除するユーザーを選択します:
   - 複数のユーザーを選択するには、各ユーザーの左側にあるチェックボックスを選択します。
   - すべてを選択するには、テーブルの先頭にあるチェックボックスを選択します。
1. シートを割り当てるか削除します:
   - シートを割り当てるには、**シートを割り当てる**を選択し、次に**シートをアサイン**を選択して確定します。
   - ユーザーをシートから削除するには、**シートを消去**を選択し、次に**シートを消去**を選択して確定します。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed-1}

前提条件: 

- 管理者である必要があります。
- GitLab 17.5以降が必要です。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. 右下で、ページの表示を**50**または**100**項目に調整して、選択可能なユーザー数を増やすことができます。
1. シートを割り当てるか削除するユーザーを選択します:
   - 複数のユーザーを選択するには、各ユーザーの左側にあるチェックボックスを選択します。
   - すべてを選択するには、テーブルの先頭にあるチェックボックスを選択します。
1. シートを割り当てるか削除します:
   - シートを割り当てるには、**シートを割り当てる**を選択し、次に**シートをアサイン**を選択して確定します。
   - ユーザーをシートから削除するには、**シートを消去**を選択し、次に**シートを消去**を選択して確定します。
1. ユーザーの右側にある切替をオンにして、GitLab Duoシートを割り当てます。

GitLab Self-Managedインスタンスの管理者は、[Rakeタスク](../administration/raketasks/user_management.md#bulk-assign-users-to-gitlab-duo)を使用してシートを一括で割り当てたり削除したりすることもできます。

#### LDAP設定によるGitLab Duoシートの管理 {#managing-gitlab-duo-seats-with-ldap-configuration}

LDAPグループメンバーシップに基づいて、LDAP対応ユーザーに対してGitLab Duoシートを自動的に割り当てたり削除したりできます。

この機能を有効にするには、LDAP設定で[`duo_add_on_groups`プロパティを設定](../administration/auth/ldap/ldap_synchronization.md#gitlab-duo-add-on-for-groups)する必要があります。

`duo_add_on_groups`が設定されると、LDAP対応ユーザー間でのGitLab Duoシート管理における信頼できる唯一の情報源となります。詳細については、[シート割り当てワークフロー](../administration/duo_add_on_seat_management_with_ldap.md#seat-management-workflow)を参照してください。

この自動化されたプロセスにより、組織のLDAPグループ構造に基づいてGitLab Duoシートが効率的に割り当てられます。詳細については、[GitLab Duoアドオンシート管理 (LDAPを使用)](../administration/duo_add_on_seat_management_with_ldap.md)を参照してください。

## 割り当て済みGitLab Duoユーザーの表示 {#view-assigned-gitlab-duo-users}

{{< history >}}

- 最終GitLab Duoアクティビティフィールドは、GitLab 18.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/455761)。

{{< /history >}}

前提条件: 

- GitLab Duo ProまたはEnterpriseアドオンを購入するか、アクティブなGitLab Duoトライアルをお持ちである必要があります。

GitLab Duo ProまたはEnterpriseを購入した後、アドオンへのアクセスを許可するために、ユーザーにシートを割り当てることができます。その後、割り当て済みGitLab Duoユーザーの詳細を表示できます。

GitLab Duoシート利用状況ページには、各ユーザーについて以下の情報が表示されます:

- ユーザーのフルネームおよびユーザー名
- シート割り当てステータス
- 公開メールアドレス: ユーザーの公開プロファイルに表示されるメール。
- 最終GitLabアクティビティ: ユーザーがGitLabで最後に行ったアクションの日付。
- 最終GitLab Duoアクティビティ: ユーザーが最後にGitLab Duo機能を使用した日付。いずれかのGitLab Duoアクティビティで更新されます。

これらのフィールドは、[GraphQL API](../api/graphql/reference/_index.md#addonuser)の`AddOnUser`タイプからのデータを使用します。

### GitLab.comの場合 {#for-gitlabcom-3}

前提条件: 

- オーナーロールを持っている必要があります。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**設定** > **GitLab Duo**を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. フィルターバーから**アサインされたシート**と**可能**を選択します。
1. ユーザーリストは、GitLab Duoシートが割り当てられたユーザーのみにフィルターされます。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed-2}

前提条件: 

- 管理者である必要があります。
- GitLab 17.5以降が必要です。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
   - **GitLab Duo**メニュー項目が利用できない場合は、購入後にサブスクリプションを同期してください:
     1. 左側のサイドバーで、**サブスクリプション**を選択します。
     1. **サブスクリプションの詳細**の**最終同期**の右側で、サブスクリプションの同期（{{< icon name="retry" >}}）を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. GitLab Duoシートが割り当てられたユーザーで絞り込むには、**ユーザーをフィルター**バーで**アサインされたシート**を選択し、次に**可能**を選択します。
1. ユーザーリストは、GitLab Duoシートが割り当てられたユーザーのみにフィルターされます。

## シートの自動削除 {#automatic-seat-removal}

GitLab Duoアドオンシートは、対象となるユーザーのみがアクセスできるように自動的に削除されます。これは、以下の場合に発生します:

- シートの超過
- ブロック、BAN、および無効化されたユーザー

### サブスクリプション有効期限時 {#at-subscription-expiration}

GitLab Duoアドオンを含むサブスクリプションの有効期限が切れた場合でも、シート割り当ては28日間保持されます。この28日間の期間中にサブスクリプションが更新されるか、GitLab Duoを含む新しいサブスクリプションが購入された場合、ユーザーは自動的に再割り当てされます。それ以外の場合、シート割り当ては削除され、ユーザーは再割り当てる必要があります。

### シート超過の場合 {#for-seat-overages}

購入したGitLab Duoアドオンシートの数量が削減された場合、シート割り当てはサブスクリプションで利用可能なシート数量に一致するように自動的に削除されます。

例: 

- あなたは、すべてのシートが割り当てられた50シートのGitLab Duo Proサブスクリプションを持っています。
- サブスクリプションを30シートで更新します。サブスクリプションを超過した20人のユーザーは、GitLab Duo Proシート割り当てから自動的に削除されます。
- 更新前に20人のユーザーのみにGitLab Duo Proシートが割り当てられていた場合、シートの削除は発生しません。

シートは、以下の基準に基づいて、この順序で削除のために選択されます:

1. まだコード提案を使用していないユーザー（最も最近割り当てられた順）。
1. コード提案を使用したユーザー（最も使用頻度が低い順）。

### ブロック、BAN、および無効化されたユーザーの場合 {#for-blocked-banned-and-deactivated-users}

毎日1回または2回、CronJobがGitLab Duoシート割り当てをレビューします。GitLab Duoシートが割り当てられたユーザーがブロック、BAN、または無効化された場合、そのユーザーのGitLab Duo機能へのアクセスは自動的に削除されます。

シートが削除されると、利用可能になり、新しいユーザーに再割り当てることができます。

## トラブルシューティング {#troubleshooting}

### UIを使用してユーザーにシートを割り当てることができません {#unable-to-use-the-ui-to-assign-seats-to-your-users}

**使用量クォータ**ページで以下の両方に該当する場合、UIを使用してユーザーにシートを割り当てることができません:

- **シート**タブが読み込まれません。
- 次のエラーメッセージが表示されます:

  ```plaintext
  An error occurred while loading billable members list.
  ```

回避策として、[このスニペット](https://gitlab.com/gitlab-org/gitlab/-/snippets/3763094)のGraphQLクエリを使用して、ユーザーにシートを割り当てることができます。
