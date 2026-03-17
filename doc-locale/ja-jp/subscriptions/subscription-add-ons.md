---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duoのサブスクリプションアドオンを発見し、ユーザーのアカウント数を割り当てます。
title: GitLab Duoアドオン
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。
- GitLab 18.3で、UIのGitLab Duo Chat（クラシック）が[Coreに追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)されました。
- GitLab 18.4で[セルフマネージドインスタンスにおけるシート割り当てメールの無効化機能を追加](https://gitlab.com/gitlab-org/gitlab/-/issues/557290)しました。

{{< /history >}}

GitLab Duoアドオンは、PremiumまたはUltimateのサブスクリプションをAIネイティブ機能で拡張します。GitLab Duoを使用して、開発ワークフローを加速し、反復的なコーディングタスクを削減し、プロジェクト全体のより深いインサイトを得ることができます。

3つのアドオンを利用できます: GitLab Duo Core、Pro、およびEnterprise。

各アドオンは、[GitLab Duo機能のセット](../user/gitlab_duo/feature_summary.md)へのアクセスを提供します。

## GitLab Duo Core {#gitlab-duo-core}

次の場合、GitLab Duo Coreは自動的に含まれます:

- GitLab 18.0以降。
- PremiumまたはUltimateサブスクリプションを持っている。

GitLab 17.11以前からの既存のGitLabユーザーは、[GitLab Duo Coreの機能を有効](../user/gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)にする必要があります。

GitLab 18.0以降の新規GitLabユーザーの場合、GitLab Duo Core機能は自動的に有効になるため、それ以上の操作は必要ありません。

どのロールがGitLab Duo Coreにアクセスできるかを確認するには、[GitLab Duoグループパーミッション](../user/permissions.md#group-gitlab-duo)を参照してください。

### GitLab Duo Self-Hosted {#gitlab-duo-self-hosted}

オフラインライセンスをお持ちの場合、GitLab Duo CoreはGitLab Duo Self-Hostedでは利用できません。GitLab Duo CoreはGitLab AIゲートウェイへの接続が必要だからです。

オンラインライセンスをお持ちの場合、GitLab Duo CoreをGitLab Duo Self-Hostedと組み合わせて使用できます。GitLab Duo Coreを使用するには、GitLab Duo Chat（Classic）およびインスタンスのコード提案に対して、GitLabマネージドモデルを選択する必要があります。

### GitLab Duo Coreの制限 {#gitlab-duo-core-limits}

[GitLab利用規約](https://about.gitlab.com/terms/)とともに、使用制限が、PremiumおよびUltimateのGitLabユーザーの、含まれるコード提案およびGitLab Duo Chat機能の使用に適用されます。

これらの制限が有効になる30日前に、GitLabは事前通知を行います。その時点で、組織の管理者は消費量を監視および管理するためのツールを利用でき、追加の容量を購入できるようになります。

制限はDuo ProまたはEnterpriseには適用されません。

## Duo ProおよびEnterprise {#gitlab-duo-pro-and-enterprise}

Duo ProおよびEnterpriseでは、ユーザーのアカウント数を購入し、チームメンバーに割り当てる必要があります。シートベースのモデルにより、特定のチームのニーズに基づいて機能アクセスとコスト管理を制御できます。

## GitLab Duo Agent Platform Self-Hosted {#gitlab-duo-agent-platform-self-hosted}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.8で導入。

{{< /history >}}

オフラインライセンスをお持ちのお客様は、GitLab Duo Agent Platform Self-Hostedアドオンを購入して、エージェントPlatformでセルフホストモデルを使用する必要があります。

このアドオンをお持ちのお客様は、[使用量](gitlab_credits.md)ではなく、シート使用量に基づいて請求されます。

オンラインライセンスをお持ちのお客様は、アドオンなしでエージェントPlatformでセルフホストモデルを使用でき、使用量に基づいて請求されます。

GitLab Duo Agent Platform Self-Hostedを購入するには、[GitLab Salesチーム](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)にお問い合わせください。

## GitLab Duoの購入 {#purchase-gitlab-duo}

GitLab Duo Enterpriseを購入するには、[GitLab Salesチーム](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)にお問い合わせください。

Duo Proのユーザーのアカウント数を購入するには、カスタマーポータルを使用するか、[GitLab Salesチーム](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)にお問い合わせください。

ポータルを使用するには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/)にサインインします。
1. サブスクリプションカードで、縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **Buy GitLab Duo Pro**を選択します。
1. GitLab Duoのユーザーのアカウント数を入力します。
1. **購入の概要**セクションを確認します。
1. **Payment method**ドロップダウンリストから、支払い方法を選択します。
1. **ライセンスを購入する**を選択します。

## 追加のGitLab Duoユーザーのアカウント数を購入 {#purchase-additional-gitlab-duo-seats}

Duo ProまたはGitLab Duo Enterpriseの追加ユーザーのアカウント数をグループネームスペースまたはSelf-Managedインスタンス用に購入できます。購入が完了すると、ユーザーのアカウント数がサブスクリプション内のGitLab Duoユーザーのアカウント数の合計に追加されます。

前提条件: 

- Duo ProまたはGitLab Duo Enterpriseアドオンを購入する必要があります。

### GitLab.comの場合 {#for-gitlabcom}

前提条件: 

- オーナーロールを持っている必要があります。

1. トップバーで**検索または移動先**を選択し、グループを検索します。
1. **設定** > **GitLab Duo**を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. **ライセンスを購入する**を選択します。
1. カスタマーポータルの**シートの追加**フィールドに、ユーザーのアカウント数を入力します。この金額は、グループネームスペースに関連付けられたサブスクリプションのユーザーのアカウント数よりも多くすることはできません。
1. **料金情報**セクションで、ドロップダウンリストから支払い方法を選択します。
1. **Privacy Policy**および**Terms of Service**チェックボックスを選択します。
1. **ライセンスを購入する**を選択します。
1. **GitLab SaaS**タブを選択してページを更新するます。

### GitLab Self-ManagedおよびGitLab Dedicatedの場合 {#for-gitlab-self-managed-and-gitlab-dedicated}

前提条件: 

- 管理者である必要があります。

1. [GitLabカスタマーポータル](https://customers.gitlab.com/)にサインインします。
1. サブスクリプションカードの**GitLab Duo Pro**セクションで、**シートを追加**を選択します。
1. ユーザーのアカウント数を入力します。この金額は、サブスクリプション内のユーザーのアカウント数よりも多くすることはできません。
1. **購入の概要**セクションを確認します。
1. **Payment method**ドロップダウンリストから、支払い方法を選択します。
1. **ライセンスを購入する**を選択します。

## GitLab Duoユーザーのアカウント数を割り当てる {#assign-gitlab-duo-seats}

前提条件: 

- Duo ProまたはEnterpriseアドオンを購入するか、有効なGitLab Duoトライアルを保持している必要があります。
- GitLab Self-ManagedおよびGitLab Dedicatedの場合:
  - Duo ProアドオンはGitLab 16.8以降で利用可能です。
  - GitLab Duo EnterpriseアドオンはGitLab 17.3以降でのみ利用可能です。

Duo ProまたはEnterpriseを購入した後、ユーザーのアカウント数をユーザーに割り当ててアドオンへのアクセスを許可できます。

### GitLab.comの場合 {#for-gitlabcom-1}

前提条件: 

- オーナーロールを持っている必要があります。

任意のプロジェクトまたはグループでGitLab Duo機能を使用するには、少なくとも1つのトップレベルグループでユーザーをユーザーのアカウント数に割り当てる必要があります。

1. トップバーで**検索または移動先**を選択し、グループを検索します。
1. **設定** > **GitLab Duo**を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. ユーザーの右側にある切替をオンにして、GitLab Duoユーザーのアカウント数を割り当てます。

ユーザーに確認メールが送信されます。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed}

前提条件: 

- 管理者である必要があります。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
   - **GitLab Duo**メニュー項目が利用できない場合は、購入後にサブスクリプションを同期します:
     1. 左側のサイドバーで、**サブスクリプション**を選択します。
     1. **サブスクリプションの詳細**の**最終同期**の右側で、サブスクリプションの同期（{{< icon name="retry" >}}）を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. ユーザーの右側にある切替をオンにして、GitLab Duoユーザーのアカウント数を割り当てます。

ユーザーに確認メールが送信されます。

- このメールを無効にするには、`sm_duo_seat_assignment_email`機能フラグを`false`に設定します。このフラグはデフォルトで有効になっています。

ユーザーのアカウント数を割り当てた後、[GitLab DuoがSelf-Managedインスタンスに設定されていることを確認](../administration/gitlab_duo/configure/gitlab_self_managed.md)してください。

## GitLab Duoユーザーのアカウント数を一括で割り当ておよび削除 {#assign-and-remove-gitlab-duo-seats-in-bulk}

複数のユーザーに対してユーザーのアカウント数を一括で割り当てたり、削除したりできます。

### SAMLグループ同期 {#saml-group-sync}

GitLab.comグループは、SAMLグループ同期を使用して[GitLab Duoユーザーのアカウント数の割り当てを管理](../user/group/saml_sso/group_sync.md#manage-gitlab-duo-seat-assignment)できます。

### GitLab.comの場合 {#for-gitlabcom-2}

1. トップバーで**検索または移動先**を選択し、グループを検索します。
1. **設定** > **GitLab Duo**を選択します。
1. 右下で、ページ表示を**50**または**100**項目に調整して、選択可能なユーザーの数を増やすことができます。
1. ユーザーのアカウント数を割り当てまたは削除するユーザーを選択します:
   - 複数のユーザーを選択するには、各ユーザーの左側にあるチェックボックスを選択します。
   - すべてを選択するには、テーブルの最上部にあるチェックボックスを選択します。
1. ユーザーのアカウント数の割り当てまたは削除:
   - ユーザーのアカウント数を割り当てるには、**シートを割り当てる**を選択し、次に**シートをアサイン**を選択して確認します。
   - ユーザーのアカウント数からユーザーを削除するには、**シートを消去**を選択し、次に**シートを消去**を選択して確認します。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed-1}

前提条件: 

- 管理者である必要があります。
- GitLab 17.5以降が必要です。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. 右下で、ページ表示を**50**または**100**項目に調整して、選択可能なユーザーの数を増やすことができます。
1. ユーザーのアカウント数を割り当てまたは削除するユーザーを選択します:
   - 複数のユーザーを選択するには、各ユーザーの左側にあるチェックボックスを選択します。
   - すべてを選択するには、テーブルの最上部にあるチェックボックスを選択します。
1. ユーザーのアカウント数の割り当てまたは削除:
   - ユーザーのアカウント数を割り当てるには、**シートを割り当てる**を選択し、次に**シートをアサイン**を選択して確認します。
   - ユーザーのアカウント数からユーザーを削除するには、**シートを消去**を選択し、次に**シートを消去**を選択して確認します。
1. ユーザーの右側にある切替をオンにして、GitLab Duoユーザーのアカウント数を割り当てます。

Self-Managedインスタンスの管理者は、[Rakeタスク](../administration/raketasks/user_management.md#bulk-assign-users-to-gitlab-duo)を使用してユーザーのアカウント数を一括で割り当てたり削除したりすることもできます。

#### LDAP設定によるGitLab Duoユーザーのアカウント数の管理 {#managing-gitlab-duo-seats-with-ldap-configuration}

LDAPグループグループメンバーシップに基づいて、LDAPが有効なユーザーにGitLab Duoユーザーのアカウント数を自動的に割り当てたり削除したりできます。

この機能を有効にするには、LDAP設定で[`duo_add_on_groups`プロパティを設定](../administration/auth/ldap/ldap_synchronization.md#gitlab-duo-add-on-for-groups)する必要があります。

`duo_add_on_groups`が設定されると、LDAPが有効なユーザー間のGitLab Duoユーザーのアカウント数管理における信頼できる唯一の情報源になります。詳細については、[ユーザーのアカウント数の割り当てワークフロー](../administration/duo_add_on_seat_management_with_ldap.md#seat-management-workflow)を参照してください。

この自動化されたプロセスにより、組織のLDAPグループ構造に基づいてGitLab Duoユーザーのアカウント数が効率的に割り当てられます。詳細については、[GitLab Duoアドオンユーザーのアカウント数のLDAPによる管理](../administration/duo_add_on_seat_management_with_ldap.md)を参照してください。

## 割り当てられたGitLab Duoユーザーを表示 {#view-assigned-gitlab-duo-users}

{{< history >}}

- 最終GitLab DuoアクティビティフィールドはGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/455761)されました。

{{< /history >}}

前提条件: 

- Duo ProまたはEnterpriseアドオンを購入するか、有効なGitLab Duoトライアルを保持している必要があります。

Duo ProまたはEnterpriseを購入した後、ユーザーのアカウント数をユーザーに割り当ててアドオンへのアクセスを許可できます。その後、割り当てられたGitLab Duoユーザーの詳細を表示できます。

GitLab Duoシートの利用ページには、各ユーザーに関する次の情報が表示されます:

- ユーザーのフルネームとユーザー名
- シート割り当てステータス
- 公開メールアドレス: ユーザーの公開プロフィールに表示されるメール。
- 最終GitLabアクティビティ: ユーザーがGitLabで最後にアクションを実行した日付。
- 最終GitLab Duoアクティビティ: ユーザーが最後にGitLab Duo機能を使用した日付。いずれかのGitLab Duoアクティビティで更新されます。

これらのフィールドは、[GraphQL API](../api/graphql/reference/_index.md#addonuser)の`AddOnUser`タイプからのデータを使用します。

### GitLab.comの場合 {#for-gitlabcom-3}

前提条件: 

- オーナーロールを持っている必要があります。

1. トップバーで**検索または移動先**を選択し、グループを検索します。
1. **設定** > **GitLab Duo**を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. フィルターバーから、**アサインされたシート**と**可能**を選択します。
1. ユーザーリストは、GitLab Duoユーザーのアカウント数が割り当てられたユーザーのみにフィルターされます。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed-2}

前提条件: 

- 管理者である必要があります。
- GitLab 17.5以降が必要です。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
   - **GitLab Duo**メニュー項目が利用できない場合は、購入後にサブスクリプションを同期します:
     1. 左側のサイドバーで、**サブスクリプション**を選択します。
     1. **サブスクリプションの詳細**の**最終同期**の右側で、サブスクリプションの同期（{{< icon name="retry" >}}）を選択します。
1. **シートの利用**で、**シートをアサイン**を選択します。
1. GitLab Duoユーザーのアカウント数が割り当てられているユーザーでフィルターするには、**ユーザーをフィルター**バーで**アサインされたシート**を選択し、次に**可能**を選択します。
1. ユーザーリストは、GitLab Duoユーザーのアカウント数が割り当てられたユーザーのみにフィルターされます。

## ユーザーのアカウント数の自動削除 {#automatic-seat-removal}

GitLab Duoアドオンのユーザーのアカウント数は、対象ユーザーのみがアクセスできるように自動的に削除されます。これは次の状況で発生します:

- シート超過
- ブロック、BAN、および非アクティブ化されたユーザー

### サブスクリプションの有効期限時 {#at-subscription-expiration}

GitLab Duoアドオンを含むサブスクリプションの有効期限が切れた場合、ユーザーのアカウント数の割り当ては28日間保持されます。サブスクリプションが更新されるか、この28日間の期間中にGitLab Duoを含む新しいサブスクリプションが購入された場合、ユーザーは自動的に再割り当てられます。そうでない場合、ユーザーのアカウント数の割り当ては削除され、ユーザーは再割り当てる必要があります。

### ユーザーのアカウント数の超過 {#for-seat-overages}

購入したGitLab Duoアドオンのユーザーのアカウント数が削減された場合、サブスクリプションで利用可能なユーザーのアカウント数と一致するように、ユーザーのアカウント数の割り当ては自動的に削除されます。

例: 

- 50ユーザーのアカウント数のDuo Proサブスクリプションがあり、すべてのユーザーのアカウント数が割り当てられています。
- 30ユーザーのアカウント数でサブスクリプションを更新します。サブスクリプションを超過した20人のユーザーは、Duo Proのユーザーのアカウント数の割り当てから自動的に削除されます。
- 更新前に20人のユーザーのみにDuo Proユーザーのアカウント数が割り当てられていた場合、ユーザーのアカウント数の削除は発生しません。

ユーザーのアカウント数は、次の基準に基づいてこの順序で削除のために選択されます:

1. まだコード提案を使用していないユーザー（最近割り当てられた順）。
1. コード提案を使用したユーザー（コード提案の最終使用が最も古い順）。

### ブロック、BAN、および非アクティブ化されたユーザー向け {#for-blocked-banned-and-deactivated-users}

毎日1回または2回、CronJobがGitLab Duoのユーザーのアカウント数の割り当てをレビューします。GitLab Duoユーザーのアカウント数が割り当てられているユーザーがブロック、BAN、または非アクティブ化された場合、そのユーザーのGitLab Duo機能へのアクセスは自動的に削除されます。

ユーザーのアカウント数が削除された後、利用可能になり、新しいユーザーに再割り当てることができます。

## トラブルシューティング {#troubleshooting}

### UIを使用してユーザーにユーザーのアカウント数を割り当てることができません {#unable-to-use-the-ui-to-assign-seats-to-your-users}

**使用量クォータ**ページで次の両方の事象が発生した場合、UIを使用してユーザーにユーザーのアカウント数を割り当てることはできません:

- **シート**タブが読み込むれません。
- 次のエラーメッセージが表示されます:

  ```plaintext
  An error occurred while loading billable members list.
  ```

回避策として、[このスニペット](https://gitlab.com/gitlab-org/gitlab/-/snippets/3763094)のGraphQLクエリを使用してユーザーのアカウント数をユーザーに割り当てることができます。
