---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabサブスクリプションのシート超過に対する請求プロセスについて説明します。
title: シート超過分を請求する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabサブスクリプションの請求対象ユーザーが購入したシート数より多い場合、追加シートに対して課金されます。

[GitLabサブスクリプション契約](https://about.gitlab.com/terms/)に基づき、GitLabは、四半期ごと（四半期調整プロセス）または年1回（年次調整プロセス）のいずれかで、シートの使用状況を確認し、超過分の請求書を送信します。

- **四半期ごとの調整**: サブスクリプション期間の残りの部分について、四半期ごとに日割り計算で請求されます。四半期中に使用したシートの最大数に対して料金を支払います。年間を通して支払う金額が少なくなり、大幅な節約につながる可能性があります。
- **年次調整**: 年間を通して追加されたユーザーに対して、年間サブスクリプション料金全額を支払います。

詳細はこちら:

- GitLab.comでの[シート使用量の決定方法](manage_users_and_seats.md#gitlabcom-billing-and-usage)。
- GitLab Self-Managedでの[GitLabのユーザーへの請求方法](manage_users_and_seats.md#self-managed-billing-and-usage)。

超過を防ぐために、[グループ](../user/group/manage.md#turn-on-restricted-access)または[インスタンス](../administration/settings/sign_up_restrictions.md#turn-on-restricted-access)へのアクセス制限を有効にすることができます。この設定は、サブスクリプションに残っているシートがない場合に、グループが新しい請求対象ユーザーを追加することを制限します。

## 例 {#example}

たとえば、1月に100ユーザーの年間ライセンスを購入し、追加のシートごとに100ドルかかるとします。年間を通して、ユーザー数は95〜120の間で変動しました。これは、年間を通してライセンスを20ユーザー超過したことを意味します。

次のチャートは、年間、月ごと、四半期ごとのユーザー数を示しています。

![月ごとおよび四半期ごとのユーザー数を示す棒チャート](img/quarterly_reconciliation_v14_7.png)

四半期ごとに請求される場合:

- 第1四半期には110人のユーザーがいました。サブスクリプションを10ユーザー超過xユーザーあたり25ドルx 3四半期 = 750ドル。これで、110ユーザーのライセンスを支払うことになります。
- 第2四半期には105人のユーザーがいました。110ユーザーを超えていないため、料金はかかりません。
- 第3四半期には120人のユーザーがいました。サブスクリプションを10ユーザー超過xユーザーあたり25ドルx残り1四半期 = 250ドル。これで、120ユーザーのライセンスを支払うことになります。
- 第4四半期には120人のユーザーがいました。第3四半期のユーザー数を超えていないため、料金はかかりません。ただし、数を超えた場合でも、第4四半期には数を超過しても料金は発生しません。
- 年間の合計費用は1000ドルです。

年単位で請求される場合:

- 追加のシートについては、100ドルx 20ユーザーを支払います。
- 年間の合計費用は2000ドルです。

## 四半期ごとの調整 {#quarterly-reconciliation}

### 資格 {#eligibility}

以下の場合、四半期調整に自動的に登録されます:

- サブスクリプションの購入に使用したクレジットカードが、引き続きGitLabアカウントにリンクされている。
- 請求書でサブスクリプションを購入した。

以下の場合、四半期調整から除外されます:

- リセラーまたは別のチャンネルパートナーからサブスクリプションを購入した。
- 12か月期間ではないサブスクリプションを購入した（複数年および非標準の長さのサブスクリプションを含む）。
- 発注書でサブスクリプションを購入した。
- [エンタープライズアジャイルプランニング](manage_subscription.md#enterprise-agile-planning)製品を購入した。
- 公共部門の顧客である。
- オフライン環境があり、ライセンスファイルを使用してサブスクリプションをアクティブ化した。
- Free層を提供するプログラム（GitLab for Education、オープンソース団体向けGitLab、スタートアップ向けGitLabなど）に登録している。

四半期調整から除外され、Free層に登録していない場合、調整は年1回調整されます。または、[追加シートを購入](manage_users_and_seats.md#buy-more-seats)して、超過分を調整できます。

### 請求と支払い {#invoicing-and-payment}

各サブスクリプション四半期の終わりに、GitLabから超過について通知が届きます。超過について通知される日付は、請求される日付と同じではありません。

1. [超過シート数](manage_users_and_seats.md#seats-owed)と予想される請求金額を伝えるメールが送信されます:

   - GitLab.comの場合: 調整日に、グループオーナーと請求アカウントマネージャーに送信されます。
   - GitLab Self-Managedの場合: 調整日の6日後、請求アカウントマネージャーに送信されます。

1. メール通知から7日後、サブスクリプションが更新され、追加のシートが含まれるようになり、日割り計算された金額の請求書が生成されます。クレジットカードが登録されている場合、支払いは自動的に適用されます。それ以外の場合は、請求書を受け取ります。これは、支払い条件に従う必要があります。

## 年次調整 {#annual-true-up}

以下の場合、サブスクリプションの請求は、デフォルトで年次調整プロセスになります:

- 契約修正を使用して、四半期調整を明示的にオプトアウトする。
- 四半期調整の対象とならない。

## トラブルシューティング {#troubleshooting}

### 支払いの失敗 {#failed-payment}

四半期調整プロセス中にクレジットカードが拒否された場合は、件名が`Action required: Your GitLab subscription failed to reconcile`のメールが届きます。この問題を解決するには、以下を実行します:

1. [お支払い情報を更新](billing_account.md#change-your-payment-method)してください。
1. [選択した支払い方法をデフォルトとして設定](billing_account.md#set-a-default-payment-method)。

支払い方法が更新されると、調整が自動的に再試行されます。
