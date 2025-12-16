---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: シートの使用状況、コンピューティング時間、ストレージ制限、更新情。
gitlab_dedicated: yes
title: GitLabサブスクリプションのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabのサブスクリプションを購入または使用する際に、以下の問題が発生する可能性があります。

## クレジットカードが拒否されました {#credit-card-declined}

GitLabサブスクリプションを購入する際にクレジットカードが拒否される原因として、以下の理由が考えられます:

- クレジットカードの情報が正しくありません。この最も一般的な原因は、不完全または偽の住所です。
- クレジットカード口座の残高が不足しています。
- クレジットカードの有効期限が切れています。
- 取引がクレジット限度額またはカードの最大取引額を超えています。
- [トランザクションが許可されていません](#error-transaction_not_allowed)。

これらの理由のいずれかが当てはまるかどうか、金融機関に確認してください。当てはまらない場合は、[GitLabサポート](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)にお問い合わせください。

### エラー: `transaction_not_allowed` {#error-transaction_not_allowed}

GitLabサブスクリプションを購入する際に、次のエラーが表示されることがあります:

```plaintext
Transaction declined.402 - [card_error/card_declined/transaction_not_allowed]
Your card does not support this type of purchase.
```

このエラーは、実行しようとしているトランザクションの種類がカード発行会社によって制限されていることを示しています。これは、アカウントを保護するために設計されたセキュリティ対策です。

トランザクションが拒否される原因として、次の理由の1つ以上が考えられます:

- インドでカードが発行され、トランザクションが[RBIの電子マンデート規則](https://www.rbi.org.in/Scripts/NotificationUser.aspx?Id=12051&Mode=0)に準拠していません。
- カードがオンライン購入用に有効になっていません。
- カードに使用制限が設定されています。たとえば、ローカル取引のみに制限されているデビットカードなどがあります。
- トランザクションが銀行のセキュリティプロトコルをトリガーします。

この問題を解決するには、次のことを試してください:

- インドで発行されたカードの場合: 認定された現地のリセラーを通じてトランザクションを処理します。インドの次のGitLabパートナーのいずれかにお問い合わせください:

  - [Datamato Technologies Private Limited](https://about.gitlab.com/partners/channel-partners/#/1345598)
  - [FineShift Software Private Limited](https://about.gitlab.com/partners/channel-partners/#/1737250)

- 米国以外で発行されたカードの場合: カードが国際的に使用できるように有効になっていることを確認し、国固有の制限があるかどうかを確認します。
- 金融機関にお問い合わせください: トランザクションが拒否された理由を尋ね、このタイプのトランザクションでカードを有効にするようにリクエストしてください。

## エラー: `Attempt_Exceed_Limitation` {#error-attempt_exceed_limitation}

GitLabサブスクリプションを購入する際に、エラー`Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again.`が発生することがあります。

この問題は、クレジットカードフォームが1分以内に3回、または1時間以内に6回再送信された場合に発生します。この問題を解決するには、数分待ってから購入を再試行してください。

## エラー: `Subscription not allowed to add` {#error-subscription-not-allowed-to-add}

サブスクリプションアドオン（追加のシート、コンピューティング時間、ストレージ、GitLab Duo Proなど）を購入する際に、エラー`Subscription not allowed to add...`が発生することがあります。

この問題は、次のアクティブなサブスクリプションをお持ちの場合に発生します:

- [リセラー経由で購入](../billing_account.md#subscription-purchased-through-a-reseller)された。
- 複数年サブスクリプションをお持ちの場合。

この問題を解決するには、[GitLabのセールス担当者](https://customers.gitlab.com/contact_us)にご連絡いただき、購入のサポートをリクエストしてください。

## カスタマーポータルアカウントに購入が表示されない {#no-purchases-listed-in-the-customers-portal-account}

カスタマーポータルの**サブスクリプションと購入**ページで、購入を表示するには、サブスクリプションの組織の担当者として追加される必要があります。

担当者として追加されるには、[GitLabサポートチームでチケットを作成してください](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)。

## ネームスペースにサブスクリプションをリンクできません {#unable-to-link-subscription-to-namespace}

GitLab.comで、サブスクリプションをネームスペースにリンクできない場合は、十分な権限がない可能性があります。そのネームスペースのオーナーロールを持っていることを確認し、[譲渡制限](../manage_subscription.md#transfer-restrictions)を確認してください。

## サブスクリプションデータが同期に失敗しました {#subscription-data-fails-to-synchronize}

GitLab Self-ManagedまたはGitLab Dedicatedでは、サブスクリプションデータが同期に失敗する可能性があります。この問題は、GitLabインスタンスと特定のIPアドレス間のトラフィックが許可されていない場合に発生する可能性があります。

この問題を解決するには、GitLabインスタンスからIPアドレス`172.64.146.11:443`および`104.18.41.245:443`（`customers.gitlab.com`）へのネットワーキングトラフィックを許可します。
