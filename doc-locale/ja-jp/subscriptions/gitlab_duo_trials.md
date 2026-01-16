---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: シートの割り当て、GitLab Duoサブスクリプションアドオン。
title: GitLab Duoのトライアル
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Duoをお試しいただくには、無料トライアルで期間限定でアクセスできます。

トライアル期間中は、選択したアドオンのすべての機能セットにアクセスできます。トライアル期間が終了した後、アクセスを維持するには、アドオンを購入してください。

GitLab Duoアドオンのトライアル期間は次のとおりです:

- GitLab.comのFreeプランをご利用の場合、30日間。
- PremiumまたはUltimateプランをご利用の場合、60日間。

トライアルは、アクティベーションコードを含む確認メールを受信したときに開始され、アクティブ化したときには開始されません。

## GitLab Duo CoreでUltimateトライアルを開始 {#start-ultimate-trial-with-gitlab-duo-core}

### GitLab Self-Managed {#on-gitlab-self-managed}

前提条件: 

- アクティブな[GitLab Enterprise Edition (EE)](../administration/license.md)が必要です。
- GitLab 18.0以降が必要です。
- お使いのインスタンスが[GitLab Duo Core](subscription-add-ons.md#gitlab-duo-self-hosted)にアクセスできるように設定されている必要があります。

GitLab Duo CoreでUltimateトライアルを開始し、AIネイティブ機能にアクセスするには:

1. [GitLab Ultimate with Duo Core](https://about.gitlab.com/free-trial/?hosted=self-managed)のトライアルページに移動します。
1. フィールドに入力します。
1. **Get Started**を選択します。
1. トライアルのアクティベーションコードについて、メールを確認してください。アクティベーションコードが記載されたメールは、トライアルリクエストフォームに入力されたメールアドレスに、トライアルリクエストの送信後すぐに送信されます。アクティベーションコードは、1回のみ有効です。
1. 管理者としてGitLabにサインインします。
1. 右上隅で、**管理者**を選択します。
1. **サブスクリプション**を選択します。
1. **アクティベーションコード**にアクティベーションコードを貼り付けます。
1. 利用規約を読んで同意してください。
1. **アクティブ化**を選択します。

トライアルがアクティブ化されました。

## GitLab Duo Proトライアルを開始 {#start-gitlab-duo-pro-trial}

トライアルを入手して、期間限定で[GitLab Duo Proの機能](../user/gitlab_duo/feature_summary.md)をお試しください。

GitLab.com、GitLab Self-Managed、またはGitLab DedicatedのPremiumプランをお持ちの場合、トライアルを入手できます。

### GitLab.com {#on-gitlabcom}

前提条件: 

- アクティブな有料Premiumサブスクリプションをお持ちのトップレベルグループのオーナーロールが必要です。グループメンバーシップによる間接的な所有権では十分ではありません。

GitLab.comでGitLab Duo Proトライアルを開始するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **請求**を選択します。
1. **Start a free GitLab Duo Pro trial**を選択します。
1. フィールドに入力します。
1. **次に進む**を選択します。
1. トライアルを適用するグループを選択するように求められた場合は、グループを選択します。
1. **トライアル版を有効にする**を選択します。
1. アクセスを必要とするユーザーに[席を割り当て](subscription-add-ons.md#assign-gitlab-duo-seats)ます。

### GitLab Self-Managed {#on-gitlab-self-managed-1}

前提条件: 

- アクティブな有料Premiumサブスクリプションが必要です。
- GitLab 16.8以降が必要であり、インスタンスがGitLabと[サブスクリプションデータを同期できる](manage_subscription.md#subscription-data-synchronization)必要があります。
- GitLab Duoで最適なユーザーエクスペリエンスと結果を得るには、GitLab 17.2以降が必要です。それ以前のバージョンでも動作する可能性はありますが、エクスペリエンスが低下するおそれがあります。

GitLab Self-ManagedまたはGitLab DedicatedでGitLab Duo Proトライアルを開始するには:

1. `[GitLab Duo Proトライアルページ](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?toggle=gitlab-duo-pro)`に移動します。
1. フィールドに入力します。

   - サブスクリプション名を見つけるには:
     1. GitLabカスタマーポータルの**Subscriptions & purchases**ページで、トライアルを適用するサブスクリプションを見つけます。
     1. ページの上部に、サブスクリプション名がバッジで表示されます。

        ![Subscription name](img/subscription_name_v17_0.png)
   - トライアル登録のために送信するメールアドレスが、[サブスクリプションの担当者](billing_account.md#change-your-subscription-contact)のメールアドレスと一致していることを確認してください。
1. **送信**を選択します。

トライアルは24時間以内にお客様のインスタンスに自動的に同期されます。トライアルの同期後、GitLab Duoへのアクセスを必要とするユーザーに[席を割り当て](subscription-add-ons.md#assign-gitlab-duo-seats)ます。

### GitLab Dedicatedの場合 {#on-gitlab-dedicated}

トライアルにご興味のある方は、営業担当者にお問い合わせください。

## GitLab Duo Enterpriseのトライアルを開始 {#start-gitlab-duo-enterprise-trial}

トライアルを入手して、期間限定で[GitLab Duo Enterpriseの機能](../user/gitlab_duo/feature_summary.md)をお試しください。

次の場合、GitLab Duo Enterpriseトライアルを入手できます:

- GitLab.comでFreeプランをご利用の場合。その場合は、GitLab Duo EnterpriseでUltimateプランをお試しいただけます。
- GitLab.com、GitLab Self-Managed、またはGitLab DedicatedのPremiumまたはUltimateプランをお持ちの場合。

GitLab Self-ManagedでFreeプランをご利用の場合、トライアルはご利用いただけません。

### GitLab.com {#on-gitlabcom-1}

前提条件: 

- アクティブな有料Ultimateサブスクリプションをお持ちのトップレベルグループのオーナーロールが必要です。

GitLab.comでGitLab Duo Enterpriseトライアルを開始するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **請求**を選択します。
1. **Start a free GitLab Duo Enterprise trial**を選択します。
1. フィールドに入力します。
1. **次に進む**を選択します。
1. トライアルを適用するグループを選択するように求められた場合は、グループを選択します。
1. **トライアル版を有効にする**を選択します。
1. アクセスを必要とするユーザーに[席を割り当て](subscription-add-ons.md#assign-gitlab-duo-seats)ます。

### GitLab Self-Managed {#on-gitlab-self-managed-2}

前提条件: 

- アクティブな有料Ultimateサブスクリプションが必要です。
- GitLab 17.3以降が必要であり、インスタンスがGitLabと[サブスクリプションデータを同期できる](manage_subscription.md#subscription-data-synchronization)必要があります。

GitLab Self-ManagedまたはGitLab DedicatedでGitLab Duo Enterpriseトライアルを開始するには:

1. `[GitLab Duo Enterpriseトライアルページ](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?toggle=gitlab-duo-enterprise)`に移動します。
1. フィールドに入力します。

   - サブスクリプション名を見つけるには:
     1. GitLabカスタマーポータルの**Subscriptions & purchases**ページで、トライアルを適用するサブスクリプションを見つけます。
     1. ページの上部に、サブスクリプション名がバッジで表示されます。

        ![Subscription name](img/subscription_name_v17_0.png)
   - トライアル登録のために送信するメールアドレスが、[サブスクリプションの担当者](billing_account.md#change-your-subscription-contact)のメールアドレスと一致していることを確認してください。
1. **送信**を選択します。

トライアルは24時間以内にお客様のインスタンスに自動的に同期されます。トライアルの同期後、GitLab Duoへのアクセスを必要とするユーザーに[席を割り当て](subscription-add-ons.md#assign-gitlab-duo-seats)ます。

### GitLab Dedicatedの場合 {#on-gitlab-dedicated-1}

トライアルにご興味のある方は、営業担当者にお問い合わせください。
