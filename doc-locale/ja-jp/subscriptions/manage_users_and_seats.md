---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabサブスクリプションに関連付けられているユーザーとシートを管理します。
title: ユーザーとシートを管理する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## 請求対象ユーザー {#billable-users}

請求対象ユーザーは、サブスクリプションのネームスペースにアクセスできるユーザーであり、直接の[members](../user/project/members/_index.md#membership-types)、継承されたメンバー、招待されたユーザーなど、次のいずれかのロールを持つユーザーです:

- ゲスト (Premiumでは請求対象、FreeおよびUltimateでは請求対象外)
- プランナー
- レポーター
- デベロッパー
- メンテナー
- オーナー

請求対象ユーザーは、サブスクリプションで購入したシート数にカウントされます。現在のサブスクリプション期間中にユーザーをブロック、無効化、またはインスタンスに追加すると、請求対象ユーザーの数が変わります。ユーザーが、サブスクリプションを保持する同じトップレベルグループに属する複数のグループまたはプロジェクトにいる場合、そのユーザーは1回のみカウントされます。

シートの使用状況は、[四半期ごとまたは年1回](quarterly_reconciliation.md)確認されます。GitLab Self-Managedでは、**請求可能ユーザー**の金額は、**管理者**エリアで1日に1回レポートされます。

GitLab.comでは、サブスクリプション機能は、サブスクリプションが適用されるトップレベルグループ内でのみ適用されます。ユーザーが別のトップレベルグループ（たとえば、自分で作成したグループ）を表示または選択したときに、そのグループに有料サブスクリプションがない場合、ユーザーには有料機能が表示されません。

ユーザーは、異なるサブスクリプションを持つ2つの異なるトップレベルグループに属することができます。この場合、ユーザーにはそのサブスクリプションで利用可能な機能のみが表示されます。

予期せずに新しい請求対象ユーザーを追加し、超過料金が発生するのを防ぐために、次のことを行う必要があります:

- [グループ階層外へのグループの招待を禁止する](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy)。
- [制限付きアクセス](../user/group/manage.md#turn-on-restricted-access)をオンにする

## 請求対象外ユーザーの条件 {#criteria-for-non-billable-users}

次の場合、ユーザーは請求対象ユーザーとしてカウントされません:

- 承認待ちである。
- それらは、[非アクティブ化](../administration/moderate_users.md#deactivate-a-user) 、[BAN](../user/group/moderate_users.md#ban-a-user) 、または[ブロック](../administration/moderate_users.md#block-a-user)されています。
- プロジェクトまたはグループのメンバーではありません（Ultimateプランのサブスクリプションのみ）。
- ユーザーが[Ultimateプランでゲストロール](#free-guest-users)のみを持っている。
- GitLab.comサブスクリプションの[最小アクセスロール](../user/permissions.md#users-with-minimal-access)のみを持っている。
- アカウントは、GitLabで作成されたサービスアカウントです:
  - [Ghostユーザー](../user/profile/account/delete_account.md#associated-records)。
  - ボット:
    - [サポートボット](../user/project/service_desk/configure.md#support-bot-user)。
    - [プロジェクトのボットユーザー](../user/project/settings/project_access_tokens.md#bot-users-for-projects)。
    - [グループのボットユーザー](../user/group/settings/group_access_tokens.md#bot-users-for-groups)。
    - その他の[内部ユーザー](../administration/internal_users.md)。

## 無料のゲストユーザー {#free-guest-users}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

**Ultimate**プランでは、ゲストロールが割り当て済のユーザーはシートを消費しません。インスタンスまたはGitLab.comのネームスペースのすべての場所で、このユーザーに他のロールを割り当てることはできません。

- プロジェクトによる違い:
  - プロジェクトが非公開または内部の場合、ゲストロールを持つユーザーは[一連の権限](../user/permissions.md#project-members-permissions)を持ちます。
  - プロジェクトがパブリックの場合、ゲストロールを持つユーザーを含むすべてのユーザーがプロジェクトにアクセスできます。
- GitLab.comの場合、ゲストロールを持つユーザーが個人のネームスペースにプロジェクトを作成すると、このユーザーはシートを消費しません。プロジェクトはユーザーの個人用ネームスペースにあり、Ultimateサブスクリプションを持つグループには関連していません。
- GitLab Self-Managedでは、ユーザーに割り当て済の最高のロールは非同期的に更新され、更新に時間がかかる場合があります。

{{< alert type="note" >}}

GitLab Self-Managedで、ユーザーがプロジェクトを作成すると、ユーザーにはメンテナーロールまたはオーナーロールが割り当てられます。ユーザーがプロジェクトを作成できないようにするために、管理者は、ユーザーを[外部](../administration/external_users.md)とマークできます。

{{< /alert >}}

## シートを追加購入 {#buy-more-seats}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

サブスクリプションの費用は、請求期間中に使用するシートの最大数に基づいています。

[アクセス制限](../user/group/manage.md#turn-on-restricted-access)が以下の場合:

- 制限付きアクセスがオンになっているときに、サブスクリプションに残っているシートがない場合は、さらにシートを購入して、グループが新しい請求対象ユーザーを追加できるようにする必要があります。
- 制限付きアクセスがオフになっているときに、サブスクリプションに残っているシートがない場合、グループは請求対象ユーザーを引き続き追加できます。GitLabは、[超過分の料金を請求](quarterly_reconciliation.md)します。

次のいずれかに該当する場合、サブスクリプションのシートを購入できません:

- [認定リセラー](billing_account.md#subscription-purchased-through-a-reseller)を通じてサブスクリプションを購入した場合。シートをさらに追加するには、リセラーにお問い合わせください。
- 複数年サブスクリプションをお持ちの場合。シートをさらに追加するには、[営業チーム](https://customers.gitlab.com/contact_us)にお問い合わせください。

サブスクリプションのシートを購入するには:

1. [カスタマーポータル](https://customers.gitlab.com/)にサインインします。
1. **Subscriptions & purchases**（サブスクリプションと購入）ページに移動します。
1. 関連するサブスクリプションカードで、**シートを追加**を選択します。
1. 追加ユーザーの数を入力します。
1. **Purchase summary**（購入の概要）セクションを確認します。システムには、システム上のすべてのユーザーの合計金額と、すでに支払った金額のクレジットが表示されます。正味の変更分のみが請求されます。
1. お支払い情報を入力してください。
1. **I accept the Privacy Statement and Terms of Service**（プライバシーに関する声明および利用規約に同意します）チェックボックスをオンにします。
1. **ライセンスを購入する**を選択します。

支払いの領収書がメールで届きます。領収書には、カスタマーポータルの[**Invoices**（インボイス）](https://customers.gitlab.com/invoices)からもアクセスできます。

## シートを削減 {#reduce-seats}

サブスクリプションの更新中にのみシートを削減できます。サブスクリプションのシート数を減らす場合は、[より少ないシートで更新](manage_subscription.md#renew-for-fewer-seats)できます。

## Self-Managedの請求と使用量 {#self-managed-billing-and-usage}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Self-Managedサブスクリプションは、ハイブリッドモデルを使用しています。サブスクリプション期間中に有効になっている最大ユーザー数に応じて、サブスクリプションの料金をお支払いいただきます。

オフラインまたはクローズドネットワーク上にないインスタンスの場合、GitLab Self-Managedインスタンス内の同時ユーザーの最大数は四半期ごとにチェックされます。

インスタンスが四半期ごとのレポートを生成できない場合は、既存のTrue-upモデルが使用されます。四半期ごとの使用状況レポートがないと、比例配分による請求はできません。

サブスクリプションのユーザー数は、現在のライセンスに含まれているユーザー数を表し、支払い対象に基づいています。この数は、シートを追加購入しない限り、サブスクリプション期間中に変わりません。

最大ユーザー数は、現在のライセンス期間におけるシステム上の請求対象ユーザーの最大数を表します。

[ライセンス使用量](../administration/license_usage.md)を表示およびエクスポートできます。

### サブスクリプションを超えるユーザー数 {#users-over-subscription}

GitLabサブスクリプションは、特定の数のシートに対して有効です。サブスクリプションを超えるユーザー数は、現在のサブスクリプション期間中にサブスクリプションで許可されている数を超えるユーザー数を示します。

現在のライセンス期間に対して、`Maximum users` - `Users in subscription`として計算されます。たとえば、10人のユーザーのサブスクリプションを購入した場合、次のようになります。

| イベント                                              | 請求対象ユーザー数   | 最大ユーザー数 |
|:---------------------------------------------------|:-----------------|:--------------|
| 10人のユーザーが10シートすべてを占有します。                     | 10               | 10            |
| 2人の新しいユーザーが参加します。                                | 12               | 12            |
| 3人のユーザーが退出し、そのアカウントがブロックされます。  | 9                | 12            |
| 4人の新しいユーザーが参加します。                               | 13               | 13            |

サブスクリプションを超えるユーザー数 = 13 - 10（最大ユーザー数 - ライセンスのユーザー数）

サブスクリプションを超えるユーザーの値は、トライアルライセンスでは常にゼロです。

サブスクリプションを超えるユーザーの値がゼロを超える場合、GitLabインスタンスには認可されている数よりも多くのユーザーが存在します。追加のユーザーの料金を[更新前または更新時に](quarterly_reconciliation.md)支払う必要があります。これは、「true-up」プロセスと呼ばれます。これを行わない場合、ライセンスキーは機能しません。

サブスクリプションを超えるユーザー数を表示するには、**管理者**エリアに移動します。

### ユーザーを表示する {#view-users}

インスタンスのユーザーのリストを表示するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **ユーザー**を選択します。

ユーザーを選択して、アカウント情報を表示します。

#### 毎日および過去の請求対象ユーザー数を確認する {#check-daily-and-historical-billable-users}

前提要件: 

- 管理者である必要があります。

GitLabインスタンスの毎日および過去の請求対象ユーザーのリストを取得できます:

1. [Railsコンソールセッションを開始](../administration/operations/rails_console.md#starting-a-rails-console-session)します。
1. インスタンス内のユーザー数をカウントします:

   ```ruby
   User.billable.count
   ```

1. 過去1年間についてインスタンスの過去の最大ユーザー数を取得します:

   ```ruby
   ::HistoricalData.max_historical_user_count(from: 1.year.ago.beginning_of_day, to: Time.current.end_of_day)
   ```

#### 毎日および過去の請求対象ユーザー数を更新する {#update-daily-and-historical-billable-users}

前提要件: 

- 管理者である必要があります。

GitLabインスタンスの毎日および過去の請求対象ユーザー数の手動更新をトリガーできます。

1. [Railsコンソールセッションを開始](../administration/operations/rails_console.md#starting-a-rails-console-session)します。
1. 毎日の請求対象ユーザー数の更新を強制的に実行します:

   ```ruby
   identifier = Analytics::UsageTrends::Measurement.identifiers[:billable_users]
   ::Analytics::UsageTrends::CounterJobWorker.new.perform(identifier, User.minimum(:id), User.maximum(:id), Time.zone.now)
   ```

1. 過去の最大請求対象ユーザー数の更新を強制的に実行します:

   ```ruby
   ::HistoricalDataWorker.new.perform
   ```

### ユーザーとサブスクリプションシートを管理する {#manage-users-and-subscription-seats}

サブスクリプションシートの数に対するユーザー数の管理は困難な場合があります:

- [LDAPがGitLabと統合されている](../administration/auth/ldap/_index.md)場合、設定されたドメイン内のすべての人がGitLabアカウントにサインアップできます。これにより、更新時に予期しない請求が発生する可能性があります。
- インスタンスでサインアップがオンになっている場合、インスタンスにアクセスできるすべての人がアカウントにサインアップできます。

GitLabには、ユーザー数の管理に役立ついくつかの機能があります。次のことを実行できます:

- [新しいサインアップに対して管理者の承認を要求する](../administration/settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups)。
- [LDAP](../administration/auth/ldap/_index.md#basic-configuration-settings)または[OmniAuth](../integration/omniauth.md#configure-common-settings)を介して、新しいユーザーを自動的にブロックする。
- 管理者による承認なしにサブスクリプションにサインアップまたは追加できる[請求対象ユーザーの数を制限する](../administration/settings/sign_up_restrictions.md#user-cap)。
- [新しいサインアップを無効](../administration/settings/sign_up_restrictions.md)にし、その代わりに、新しいユーザーを手動で管理する。
- [ユーザー統計](../administration/admin_area.md#users-statistics)ページで、ロール別のユーザーの内訳を表示する。
- [ロールの昇格に対する管理者の承認をオン](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)にします。
- [ゲストロールを持つユーザーがプロジェクトやグループを作成できないようにする](../administration/settings/account_and_limit_settings.md#prevent-non-members-from-creating-projects-and-groups)。

ライセンスでカバーされるユーザー数を増やすには、サブスクリプション期間中に[シートを追加購入](#buy-more-seats)します。サブスクリプション期間中に追加されたシートのコストは、購入日からサブスクリプション期間の終了まで比例配分されます。ライセンスカウントのユーザー数に達した場合でも、ユーザーを追加し続けることができます。GitLabは、[超過分の料金を請求](quarterly_reconciliation.md)します。

サブスクリプションがアクティベーションコードでアクティブ化された場合、追加のシートはインスタンスにすぐに反映されます。ライセンスファイルを使用している場合は、更新されたファイルが届きます。シートを追加するには、インスタンスに[ライセンスファイルを追加](../administration/license_file.md)します。

## GitLab.comの請求と使用量 {#gitlabcom-billing-and-usage}

{{< details >}}

- 提供形態: GitLab.com

{{< /details >}}

GitLab.comのサブスクリプションは、同時（シート）モデルを使用します。同時にサブスクリプションを使用できるユーザーのシート数を選択し、請求期間中にトップレベルグループ、そのサブグループ、およびプロジェクトに割り当てられたユーザーの最大数に応じて、サブスクリプションの料金を支払います。

特定の時点におけるユーザーの合計数がサブスクリプション数を超えない限り、追加料金なしで、サブスクリプション期間中にユーザーを追加したり削除したりできます。ユーザーを追加して購入したシート数を超えると、超過料金が発生し、次回の[請求書](quarterly_reconciliation.md)に含まれます。

### 不足しているシート数 {#seats-owed}

請求対象ユーザーの数が**seats in subscription**（サブスクリプションしているシート数）を超える場合（**seats owed**（不足しているシート数）と呼ばれます）、超過したユーザー数に対する料金を支払う必要があります。

たとえば、10人のユーザーのサブスクリプションを購入した場合、次のようになります:

| イベント                                              | 請求対象メンバー数 | 最大ユーザー数 |
|:---------------------------------------------------|:-----------------|:--------------|
| 10人のユーザーが10シートすべてを占有します。                     | 10               | 10            |
| 2人の新しいユーザーが参加します。                                | 12               | 12            |
| 3人のユーザーが退出し、そのアカウントが削除されます。  | 9                | 12            |

不足しているシート数 = 12 - 10（最大ユーザー数 - サブスクリプションのユーザー数）

不足しているシート数からの請求を防ぐために、[制限されたアクセスをオンにする](../user/group/manage.md#turn-on-restricted-access)ことができます。この設定は、サブスクリプションに残っているシートがない場合に、グループが新しい請求対象ユーザーを追加することを制限します。

### シート使用状況アラート {#seat-usage-alerts}

{{< history >}}

- GitLab 15.2で`seat_flag_alerts`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348481)されました。
- GitLab 15.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/362041)になりました。機能フラグ`seat_flag_alerts`は削除されました。

{{< /history >}}

[四半期ごとのサブスクリプションの調整](quarterly_reconciliation.md)に登録されているサブスクリプションにリンクされているトップレベルグループのオーナーロールを持っている場合、サブスクリプションのシート使用量に関するアラートが届きます。

このアラートは、グループ、サブグループ、およびプロジェクトページに表示されます。アラートを閉じると、別のシートが使用されるまで表示されません。

このアラートは、次の間隔で表示されます:

| サブスクリプションしているシート数 | アラート               |
|-----------------------|---------------------|
| 0–15                  | シートが1つ残っているとき。   |
| 16–25                 | シートが2つ残っているとき。   |
| 26–99                 | シートが10%残っているとき。|
| 100–999               | シートが8%残っているとき。 |
| 1000+                 | シートが5%残っているとき。 |

### シートの使用状況を表示する {#view-seat-usage}

使用中のシートのリストを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **使用量クォータ**を選択します。
1. **シート**タブを選択します。

各ユーザーについて、ユーザーが直接のメンバーであるグループとプロジェクトを示すリストが表示されます。

- **グループ招待**は、ユーザーが、[グループに招待されたグループ](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group)のメンバーであることを示します。
- **プロジェクトへの招待**は、ユーザーが、[プロジェクトに招待されたグループ](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)のメンバーであることを示します。

シート使用状況リスト、**Seats in use**（使用量）、**サブスクリプションしているシート数**のデータは、ライブで更新されます。**最大使用シート数**と**不足しているシート数**は、1日に1回更新されます。

#### 料金情報を表示する {#view-billing-information}

サブスクリプション情報とシート数の概要を表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **請求**を選択します。

- 使用状況の統計は1日に1回更新されるため、**使用量クォータ**ページの情報と**Billing page**（請求）ページの情報が異なる場合があります。
- **最終ログイン**フィールドは、ユーザーがサインアウトした後にサインインすると更新されます。ユーザーが再認証するときにアクティブなセッションがある場合（たとえば、24時間のSAMLセッションがタイムアウトした後）、このフィールドは更新されません。

### ユーザーのシート使用量を検索 {#search-users-seat-usage}

サブスクリプションでシートを使用するユーザーを表示できます。ユーザーのシート使用量を検索するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **使用量クォータ**を選択します。
1. **シート**タブの検索ボックスに、ユーザーの名前またはユーザー名を入力します。検索文字列は、3文字以上である必要があります。

検索では、名、姓、またはユーザー名に検索文字列が含まれるユーザーが返されます。

たとえば、名がAmirのユーザーの場合、検索文字列`ami`は一致しますが、`amr`は一致しません。

### シートの使用状況データをエクスポートする {#export-seat-usage-data}

シートの使用状況データをCSVファイルとしてエクスポートするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **使用量クォータ**を選択します。
1. **シート**タブで、**エクスポートリスト**を選択します。

### シート使用履歴をエクスポートする {#export-seat-usage-history}

前提要件: 

- グループのオーナーロールを持っている必要があります。

シートの使用履歴をCSVファイルとしてエクスポートするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **使用量クォータ**を選択します。
1. **シート**タブで、**シート使用履歴をエクスポート**を選択します。

生成されたリストには、使用されているすべてのシートが含まれており、現在の検索の影響を受けません。

### サブスクリプションからユーザーを削除する {#remove-users-from-subscription}

GitLab.comサブスクリプションから請求対象ユーザーを削除するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **請求**を選択します。
1. **現在使用中のシート数**セクションで、**使用状況を見る**を選択します。
1. 削除するユーザーの行の右側にある**ユーザーを削除**を選択します。
1. ユーザー名を再入力し、**ユーザーを削除**を選択します。

[グループを別のグループと共有](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group)する機能を使用してグループにメンバーを追加した場合、この方法を使用してメンバーを削除することはできません。代わりに、次のいずれかを実行できます:

- 共有グループからメンバーを[削除](../user/group/_index.md#remove-a-member-from-the-group)します。
- 招待グループを[削除](../user/project/members/sharing_projects_groups.md#remove-an-invited-group)します。
