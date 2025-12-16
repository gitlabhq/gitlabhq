---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのサブスクリプションを購入、表示、更新します。
title: サブスクリプションを管理する
---

## サブスクリプションを購入 {#buy-a-subscription}

GitLab.comまたはGitLab Self-Managedのサブスクリプションを購入できます。サブスクリプションによって、非公開プロジェクトで利用できる機能が決まります。

GitLabにサブスクリプション登録すると、サブスクリプションの詳細を管理できます。問題が発生した場合は、[GitLabサブスクリプションのトラブルシューティング](gitlab_com/gitlab_subscription_troubleshooting.md)を参照してください。

パブリックオープンソースプロジェクトを使用する組織は、[オープンソース団体向けGitLab](community_programs.md#gitlab-for-open-source)に申し込むことができます。

### GitLab.comの場合 {#for-gitlabcom}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

GitLab.comは、GitLabのマルチテナントSoftware-as-a-Service（SaaS）製品です。GitLab.comを使用するために何かをインストールする必要はなく、[サインアップ](https://gitlab.com/users/sign_up)するだけで済みます。サインアップするときは、以下を選択します:

- [サブスクリプション](https://about.gitlab.com/pricing/)。
- 必要なシート数。

GitLab.comサブスクリプションは、トップレベルグループに適用されます。グループ内のすべてのサブグループとプロジェクトのメンバーは、次のことができます:

- サブスクリプションの機能を使用する。
- サブスクリプションのシートを消費する。

GitLab.comにサブスクライブするには、次の手順に従います:

1. [GitLab.comの機能比較](https://about.gitlab.com/pricing/feature-comparison/)を表示して、必要なプランを決定します。
1. [サインアップページ](https://gitlab.com/users/sign_up)を使用して、自分のユーザーアカウントを作成します。
1. [グループ](../user/group/_index.md#create-a-group)を作成します。サブスクリプションプランは、トップレベルグループ、そのサブグループ、プロジェクトに適用されます。
1. 追加のユーザーを作成して、[グループに追加](../user/group/_index.md#add-users-to-a-group)します。このグループ、そのサブグループ、プロジェクトのユーザーは、サブスクリプションプランの機能を使用したり、サブスクリプションのシートを消費したりできます。
1. 左側のサイドバーで、**設定** > **請求**を選択し、プランを選択します。カスタマーポータルに移動します。
1. フォームに入力して購入を完了します。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Self-ManagedインスタンスのGitLabにサブスクライブするには、次の手順に従います:

1. [価格ページ](https://about.gitlab.com/pricing/)に移動し、Self-Managedプランを選択します。[カスタマーポータル](https://customers.gitlab.com/)にリダイレクトされた後、購入を完了します。
1. 購入後、カスタマーポータルアカウントに関連付けられたメールアドレスにアクティベーションコードが送信されます。[このコードをGitLabインスタンスに追加](../administration/license.md)する必要があります。

{{< alert type="note" >}}

既存の**無料** GitLab Self-Managedインスタンスのサブスクリプションを購入する場合は、[ユーザーをカバー](../administration/admin_area.md#administering-users)するのに十分なシート数を購入してください。

{{< /alert >}}

## サブスクリプションの表示 {#view-subscription}

### GitLab.comの場合 {#for-gitlabcom-1}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

前提要件: 

- グループのオーナーロールを持っている必要があります。

GitLab.comサブスクリプションのステータスを確認するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **請求**を選択します。

次の情報が表示されます:

| フィールド                       | 説明 |
|:----------------------------|:------------|
| **サブスクリプションしているシート数**   | 有料プランの場合、このグループ向けに購入したシート数を表します。 |
| **現在使用中のシート数**  | 使用中のシート数。これらのシートを使用しているユーザーのリストを表示するには、**使用状況を見る**を選択します。 |
| **Maximum seats used**（最大使用シート数）      | 使用したシートの最大数。 |
| **不足しているシート数**              | **最大使用シート数** - **サブスクリプションしているシート数**。 |
| **サブスクリプション開始日** | サブスクリプションが開始された日付。 |
| **サブスクリプション終了日**   | 現在のサブスクリプションが終了する日付。 |

### GitLab Self-Managedの場合 {#for-gitlab-self-managed-1}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

前提要件: 

- 管理者である必要があります。

サブスクリプションのステータスを表示できます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **サブスクリプション**を選択します。

**サブスクリプション**ページには、次の情報が含まれています:

- ライセンシー
- プラン
- アップロードされた日時、開始された日時、および有効期限
- サブスクリプションのユーザー数
- 請求対象ユーザーの数
- 最大ユーザー数
- サブスクリプションを超えるユーザーの数

## アカウントを確認する {#review-your-account}

請求先アカウントの設定と購入情報を定期的に確認する必要があります。

請求先アカウントの設定を確認するには、次の手順に従います:

1. [カスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインします。
1. **Billing account settings**（請求先アカウント設定）を選択します。
1. 次の情報を確認または更新します:
   - **Payment methods**（支払い方法）にある、登録されているクレジットカード。
   - **Company information**（会社情報）にある、サブスクリプションと請求に関する連絡先の詳細。
1. 変更を保存します。

また、ユーザーアカウントを定期的に確認して、正しい数のアクティブな請求対象ユーザーに対してのみ更新していることを確認する必要があります。非アクティブなユーザーアカウントについては、次のようになります:

- 請求対象ユーザーとしてカウントされる可能性があります。非アクティブなユーザーアカウントを更新すると、必要以上に料金を支払うことになります。
- セキュリティリスクになる可能性があります。定期的な確認は、このリスクを軽減するのに役立ちます。

詳細については、以下に関するドキュメントを参照してください:

- [ユーザー統計](../administration/admin_area.md#users-statistics)。
- [ライセンスの使用状況](../administration/license_usage.md)。
- [ユーザーとサブスクリプションシートを管理する](manage_users_and_seats.md#manage-users-and-subscription-seats)。

## サブスクリプションプランをアップグレードする {#upgrade-subscription-tier}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

[GitLabプラン](https://about.gitlab.com/pricing/)をアップグレードするには、次の手順に従います:

1. [カスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインします。
1. 関連するサブスクリプションカードで、**プランをアップグレード**を選択します。
1. アクティブな支払い方法を確認するか、新しい支払い方法を追加します。
1. **I accept the Privacy Statement and Terms of Service**（プライバシーに関する声明および利用規約に同意します）チェックボックスをオンにします。
1. **Upgrade subscription**（サブスクリプションをアップグレード）を選択します。

次の内容がメールで送信されます:

- 支払いの領収書。この情報には、カスタマーポータルの[**Invoices**（インボイス）](https://customers.gitlab.com/invoices)からもアクセスできます。
- GitLab Self-Managedでは、ライセンスの新しいアクティベーションコードが送信されます。

GitLab Self-Managedでは、新しい階層は、次回のサブスクリプションの同期時に有効になります。すぐにアップグレードするには、[サブスクリプションを手動で同期させることもできます。](#subscription-data-synchronization)

## サブスクリプションの更新 {#renew-subscription}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

サブスクリプションの更新日の前に、アカウントを確認して、現在のシートの使用状況と請求対象ユーザーを確認する必要があります。

サブスクリプションは、自動または手動で更新できます。次のいずれかを行う場合は、サブスクリプションを手動で更新する必要があります:

- より少ないシート数で更新する。
- 更新される製品の数量を増やす、または減らす。
- 更新されたサブスクリプション期間に対して不要になったアドオン製品を削除する。
- サブスクリプションプランをアップグレードする。

更新期間の開始日は、グループの料金ページの**次期サブスクリプション開始日**に表示されます。

以下にお問い合わせください:

- カスタマーポータルへのアクセスや、サブスクリプションを管理する連絡担当者の変更についてサポートが必要な場合は、[サポートチーム](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)にお問い合わせください。
- サブスクリプションの更新についてサポートが必要な場合は、[営業チーム](https://customers.gitlab.com/contact_us)にお問い合わせください。

### サブスクリプションの有効期限の確認 {#check-when-subscription-expires}

サブスクリプションの有効期限が切れる15日前に、GitLabユーザーインターフェースで、サブスクリプションの有効期限日が記載されたバナーが管理者に表示されます。

サブスクリプションの有効期限が切れる15日前よりも前に、サブスクリプションを手動で更新することはできません。いつ更新できるかを確認するには、次の手順に従います:

1. [カスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインします。
1. **Subscription actions**（サブスクリプションアクション）({{< icon name="ellipsis_v" >}})を選択してから、**サブスクリプションの更新**を選択し、更新できる日付を表示します。

### 自動更新 {#renew-automatically}

前提要件: 

- GitLab Self-Managedの場合、変更が確実に同期されるように、更新の少なくとも2日前に[サブスクリプションデータを同期させ](#subscription-data-synchronization)、アカウントを確認する必要があります。

サブスクリプションが自動更新に設定されている場合、利用可能なサービスに不一致が生じることなく、有効期限日の午前0時（UTC）に自動的に更新されます。サブスクリプションが自動的に更新される前に、[メール通知](#renewal-notifications)が届きます。

シート数は、更新時に自動的に減少しません。更新時に、現在のサブスクリプションの数量よりも多くの請求対象ユーザーがいる場合、シート数は、[グループ](manage_users_and_seats.md#view-seat-usage)または[インスタンス](manage_users_and_seats.md#view-users)内の現在のユーザー数と一致するように自動的に増加します。サブスクリプションが予想以上に多くのシートで更新されるのを避けるために、[より少ないシート数で更新する方法](#renew-for-fewer-seats)を学びましょう。

カスタマーポータルで購入したサブスクリプションは、デフォルトで自動更新に設定されますが、[サブスクリプションの自動更新を無効](#turn-on-or-turn-off-automatic-subscription-renewal)にすることができます。

#### サブスクリプションの自動更新のオン/オフを切り替えます {#turn-on-or-turn-off-automatic-subscription-renewal}

カスタマーポータルを使用して、サブスクリプションの自動更新をオンまたはオフにすることができます:

1. [カスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインします。**Subscriptions & purchases**（サブスクリプションと購入）ページに移動します。
1. サブスクリプションカードを確認します:
   - カードに**Expires on DATE**（DATEに失効）と表示されている場合、サブスクリプションは自動的に更新されるように設定されていません。自動更新を有効にするには、**Subscription actions**（サブスクリプションアクション）（{{< icon name="ellipsis_v" >}}）で、**Turn on auto-renew**（自動更新をオンにする）を選択します。
   - カードに**Auto-renews on DATE**（DATEに自動更新）と表示されている場合、サブスクリプションは自動的に更新されるように設定されています。自動更新を無効にするには、次の手順に従います:
     1. **Subscription actions**（サブスクリプションアクション）（{{< icon name="ellipsis_v" >}}）で、**Cancel subscription**（サブスクリプションをキャンセル）を選択します。
     1. キャンセルの理由を選択します。
     1. オプション。**Would you like to add anything?**（何か追加しますか？）に、関連情報を入力します。
     1. **Cancel subscription**（サブスクリプションをキャンセル）を選択します。

### 手動で更新 {#renew-manually}

サブスクリプションを手動で更新するには、次の手順に従います:

1. 次のサブスクリプション期間に必要なユーザー数を決定します。
1. [カスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインします。
1. 既存のサブスクリプションで、**Start renewal**（更新）を選択します。このボタンは、サブスクリプションの有効期限が切れる15日前まで表示されません。
1. PremiumまたはUltimateプランを更新する場合は、**シート**のテキストボックスに、今後1年間に必要なユーザーのアカウント数の総数を入力します。

   {{< alert type="note" >}}

   この数が、更新時のシステム内の[請求対象ユーザー](manage_users_and_seats.md#billable-users)数以上であることを確認してください。

   {{< /alert >}}

1. オプション。インスタンス内のユーザーの最大数が、以前のサブスクリプション期間中に許可されていた数を超えた場合、更新時に[超過](quarterly_reconciliation.md)が発生します。

   **Users over license**（ライセンス外のユーザー）テキストボックスに、発生したユーザー超過の[サブスクリプションを超えるユーザー](manage_users_and_seats.md#users-over-subscription)の数を入力します。
1. オプション。アドオン製品を更新する場合は、希望する数量を確認して更新します。製品を削除することもできます。
1. オプション。サブスクリプションプランをアップグレードする場合は、希望するオプションを選択します。
1. 更新の詳細を確認し、**サブスクリプションの更新**を選択して、支払いプロセスを完了します。
1. GitLab Self-Managedの場合、関連するサブスクリプションカードの[サブスクリプションと購入](https://customers.gitlab.com/subscriptions)ページで、**Copy activation code**（アクティベーションコードをコピー）を選択して、更新期間のアクティベーションコードのコピーを取得し、アクティベーション[コードをインスタンスに追加](../administration/license.md)します。

サブスクリプションに製品を追加するには、[営業チームにお問い合わせください](https://customers.gitlab.com/contact_us)。

### より少ないシート数で更新する {#renew-for-fewer-seats}

より少ないシート数でのサブスクリプション更新は、現在の請求対象ユーザー数以上である必要があります。

サブスクリプションを更新する前に:

- GitLab.comの場合、更新するシート数を超える場合は、[請求対象ユーザーの数を減らします](manage_users_and_seats.md#remove-users-from-subscription)。
- GitLab Self-Managedの場合は、[非アクティブまたは不要なユーザーをブロックします](../administration/moderate_users.md#block-a-user)。

より少ないシート数でサブスクリプションを手動で更新するには、次のいずれかを実行します:

- サブスクリプション更新日から15日以内に[手動で更新](#renew-manually)します。更新時に必ずシート数を指定してください。
- [サブスクリプションの自動更新を無効](#turn-on-or-turn-off-automatic-subscription-renewal)にし、[営業チーム](https://customers.gitlab.com/contact_us)に連絡して、必要なシート数でサブスクリプションを更新してください。

### 更新通知 {#renewal-notifications}

サブスクリプションが自動的に更新される15日前に、更新に関する情報が記載されたメールが送信されます。

- クレジットカードの有効期限が切れている場合は、クレジットカードを更新する方法がメールに記載されています。
- 未払いの超過料金がある場合、またはその他の理由でサブスクリプションを自動的に更新できない場合、営業チームに連絡したり、カスタマーポータルで手動で更新するようにメールで促されます。
- 問題がない場合は、メールに次の情報が明記されています:
  - 更新される製品の名前と数量。
  - 未払い合計金額。更新前に使用量が増加した場合、この金額は変更されます。

### 更新インボイスを管理する {#manage-renewal-invoice}

更新に対してインボイスが生成されます。この更新インボイスを表示またはダウンロードするには、[カスタマーポータルのインボイスページ](https://customers.gitlab.com/invoices)にアクセスしてください。

アカウントに[保存されたクレジットカード](billing_account.md#change-your-payment-method)がある場合、カードにインボイス金額が請求されます。

GitLabが支払いを処理できない場合、またはその他の理由で自動更新が失敗した場合は、サブスクリプションを更新できる期間が14日間あります。その期間が過ぎると、GitLabプランがダウングレードされます。

## 期限切れのサブスクリプション {#expired-subscription}

サブスクリプションは、有効期限日の開始時（サーバー時間00:00）に失効します。

たとえば、サブスクリプションが2024年1月1日から2025年1月1日まで有効な場合:

- 2024-12-31 11:59:59 PM（UTC）に期限切れになります。
- 2025-1-1 12:00:00 AM（UTC）から期限切れと見なされます。

### GitLab.comの場合 {#for-gitlabcom-2}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

サブスクリプションが期限切れになると、有料機能は使用できなくなります。ただし、Freeプランの機能は引き続き使用できます。有料機能の機能を再開するには、サブスクリプションを更新してください。

### GitLab Self-Managedの場合 {#for-gitlab-self-managed-2}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ライセンスの有効期限が切れると:

- インスタンスが読み取り専用になります。
- GitLabは、Gitプッシュやイシュー作成などの機能をロックします。
- 有効期限切れのメッセージがすべての管理者に表示されます。

ライセンスの有効期限が切れた後は、次のようにする必要があります:

- 機能を再開するには、[新しいサブスクリプションをアクティブ化](../administration/license_file.md#activate-subscription-during-installation)します。
- Freeプランの機能のみを使用し続けるには、[有効期限切れのライセンスを削除](../administration/license_file.md#remove-a-license)します。

## サブスクリプションデータの同期 {#subscription-data-synchronization}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

前提要件: 

- GitLab Enterprise Edition（EE）
- インターネットに接続されていて、オフライン環境ではない必要があります。
- アクティベーションコードでインスタンスを[アクティブ化](../administration/license.md)している必要があります。

[サブスクリプションデータ](#subscription-data)は、GitLab Self-ManagedインスタンスとGitLabの間で自動的に1日に1回同期されます。

この毎日の同期ジョブは、おおよそ午前3時（UTC）に、[サブスクリプションデータ](#subscription-data)をカスタマーポータルに送信します。そのため、アップデートや更新がすぐに適用されない場合があります。

データは、ポート`443`で暗号化されたHTTPS接続を介して`customers.gitlab.com`に安全に送信されます。ジョブが失敗した場合、約17時間にわたって最大12回再試行されます。

自動データ同期を設定すると、次のプロセスも自動化されます。

- [四半期ごとのサブスクリプション調整](quarterly_reconciliation.md)。
- サブスクリプションの更新。
- シートの追加やGitLabプランのアップグレードなどのサブスクリプション更新。

### サブスクリプションデータを手動で同期する {#manually-synchronize-subscription-data}

サブスクリプションデータをいつでも手動で同期できます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **サブスクリプション**を選択します。
1. **サブスクリプションの詳細**セクションで、**Sync**（同期）（{{< icon name="retry" >}}）を選択します。

その後、同期ジョブがキューに入れられます。ジョブが完了すると、サブスクリプションの詳細が更新されます。

### サブスクリプションデータ {#subscription-data}

{{< history >}}

- 一意のインスタンスIDは、GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189399)されました。

{{< /history >}}

毎日の同期ジョブは、次の情報をカスタマーポータルに送信します:

- 日付
- タイムスタンプ
- キー内に次の情報が暗号化されたライセンスキー:
  - 会社名
  - ライセンシーの名前
  - ライセンシーのメールアドレス
- 過去の[最大ユーザー数](manage_users_and_seats.md#self-managed-billing-and-usage)
- [請求対象ユーザー数](manage_users_and_seats.md#billable-users)
- GitLabのバージョン
- ホスト名
- インスタンスID
- 一意のインスタンスID

さらに、次のようなアドオンメトリクスも送信します:

- アドオンタイプ
- 購入したシート
- 割り当てられたシート

ライセンス同期リクエストの例:

```json
{
  "gitlab_version": "14.1.0-pre",
  "timestamp": "2021-06-14T12:00:09Z",
  "date": "2021-06-14",
  "license_key": "XXX",
  "max_historical_user_count": 75,
  "billable_users_count": 75,
  "hostname": "gitlab.example.com",
  "instance_id": "9367590b-82ad-48cb-9da7-938134c29088",
  "unique_instance_id": "a98bab6e-73e3-5689-a487-1e7b89a56901",
  "add_on_metrics": [
    {
      "add_on_type": "duo_enterprise",
      "purchased_seats": 100,
      "assigned_seats": 50
    }
  ]
}
```

## サブスクリプションをグループにリンクする {#link-subscription-to-a-group}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

GitLab.comサブスクリプションにリンクされているグループを変更するには、次の手順に従います:

1. [リンクされた](billing_account.md#link-a-gitlabcom-account) GitLab.comアカウントで[カスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインします。
1. 次のいずれかを実行します:
   - サブスクリプションがグループにリンクされていない場合は、**Link subscription to a group**（サブスクリプションをグループにリンクする）を選択します。
   - サブスクリプションがすでにグループにリンクされている場合は、**Subscription actions**（サブスクリプションアクション） ({{< icon name="ellipsis_v" >}}) > **Change linked group**（リンクされたグループを変更）を選択します。
1. **New Namespace**（新しいネームスペース）ドロップダウンリストから目的のグループを選択します。ここに表示されるグループについては、そのグループのオーナーロールを持っている必要があります。
1. グループの[ユーザーの合計数](manage_users_and_seats.md#view-seat-usage)がサブスクリプションのシート数を超える場合は、追加ユーザーの料金を支払うように求められます。サブスクリプション料金は、サブグループとネストされたプロジェクトを含む、グループ内のユーザーの合計数に基づいて計算されます。

   認定リセラーを通じてサブスクリプションを購入した場合、追加ユーザーの料金を支払うことはできません。次のいずれかを実行できます:

   - 追加ユーザーを削除して、超過が検出されないようにします。
   - パートナーに連絡して、追加のシートを今すぐ、またはサブスクリプション期間の終了時に購入します。

1. **Confirm changes**（変更を確認）を選択します。

1つのネームスペースのみをサブスクリプションにリンクできます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>デモについては、[GitLabサブスクリプションをネームスペースにリンクする](https://youtu.be/8iOsN8ajBUw)を参照してください。

## サブスクリプションの連絡担当者を追加または変更する {#add-or-change-subscription-contacts}

連絡担当者は、サブスクリプションを更新したり、キャンセルしたり、別のネームスペースに転送したりできます。

[プロファイル所有者情報の変更](billing_account.md#change-profile-owner-information)および[別の請求先アカウントマネージャーの追加](billing_account.md#add-a-billing-account-manager)を実行できます。

### 転送の制限 {#transfer-restrictions}

リンクされたネームスペースを変更できますが、これはすべてのサブスクリプションタイプでサポートされているわけではありません。

次のサブスクリプションを転送することはできません:

- 期限切れのサブスクリプションまたはトライアルサブスクリプション。
- ネームスペースにすでにリンクされている、コンピューティング時間が含まれたサブスクリプション。
- PremiumプランまたはUltimateプランがすでにあるネームスペースへの、PremiumプランまたはUltimateプランが含まれたサブスクリプション。
- GitLab Duoアドオンが含まれたサブスクリプションがすでにあるネームスペースへの、GitLab Duoアドオンが含まれたサブスクリプション。

## エンタープライズアジャイルプランニング {#enterprise-agile-planning}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabエンタープライズアジャイルプランニングは、エンジニアがコードをビルド、テスト、保護、デプロイするのと同じDevSecOpsプラットフォームに、技術者以外のユーザーを取り込むのに役立つアドオンです。このアドオンにより、エンジニアリングチーム以外のメンバーのために完全なGitLabライセンスを購入しなくても、デベロッパーと非デベロッパーのチーム間のコラボレーションが可能になります。エンタープライズアジャイルプランニングシートを使用すると、非エンジニアリングチームのメンバーは、計画ワークフローに参加して、バリューストリーム分析でソフトウェアデリバリーのベロシティと影響を測定し、エグゼクティブダッシュボードを使用して組織の可視性を促進することができます。

追加のエンタープライズアジャイルプランニングシートを購入するには、[GitLabの営業担当者](https://customers.gitlab.com/contact_us)に問い合わせて、詳細を確認してください。
