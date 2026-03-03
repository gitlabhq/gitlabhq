---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab.comまたはSelf-ManagedインスタンスでUltimateトライアルを開始します。
title: Ultimateのトライアル
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

GitLab Ultimateプランのトライアルライセンスを取得できます。

トライアル期間中は、ほぼすべてのUltimate機能にアクセスできます。

Ultimateのトライアルライセンスの有効期間:

- Freeプランをご利用の場合、30日間。
- Premiumプランをご利用の場合、60日間。

トライアル期間は、アドオンをアクティブ化した時点ではなく、アクティベーションコードが記載された確認メールが届いた時点で開始されます。

トライアル期間が終了すると、有料機能にアクセスできなくなります。[サブスクリプションを購入](manage_subscription.md#buy-a-subscription)すると、アクセスを維持できます。

## GitLab Duo Agent Platformのトライアル {#gitlab-duo-agent-platform-trials}

前提条件: 

- GitLab Self-Managedの場合、GitLab 18.9以降が必要です。
- GitLab.comの場合、トライアルは2026年2月10日より後に開始する必要があります。

Freeプランをご利用の場合、Ultimateのトライアルを開始すると、ユーザーあたり24 [GitLabクレジット](gitlab_credits.md#included-credits)がFreeプランに付与されます。クレジットを使用してGitLab Duo Agent Platformの機能をテストできます。

クレジットはトライアル期間（30日間）有効です。サブスクリプションを購入した場合、またはトライアルが終了した場合、未使用のクレジットは繰り越されません。トライアル終了前に含まれるクレジットをすべて使用した場合、クレジットを追加取得することはできません。

クレジットが含まれていないトライアルをすでに開始または完了している場合は、新しいトライアルを開始できます:

- トライアルが期限切れになった場合は、すぐに新しいトライアルを開始できます。
- トライアルがまだ有効な場合は、新しいトライアルを開始する前に、現在のトライアル期間を完了する必要があります。

Premiumプランをご利用の場合、トライアルでは、既存のユーザーごとのクレジットに加えて、追加のクレジットは提供されません。GitLab Duo Agent Platformの機能を試すには、追加の[一時評価クレジット](gitlab_credits.md#temporary-evaluation-credits)をリクエストできます。

## GitLab.comでトライアルを開始 {#start-a-trial-on-gitlabcom}

GitLabアカウントにサインアップしていなくても、トライアルを開始できます。

### アカウントをお持ちでない場合 {#if-you-dont-have-an-account}

GitLabアカウントをお持ちでない場合、無料トライアルを開始するには以下の手順に従います:

1. [https://gitlab.com/-/trial_registrations/new](https://gitlab.com/-/trial_registrations/new)にアクセスします。
1. フォームの詳細を入力し、**次に進む**を選択します。
1. 残りの手順を完了し、**プロジェクトを作成**を選択します。新しいプロジェクトに移動し、作成した新しいユーザーとしてサインインします。
1. 左側のサイドバーの下部に、トライアルのタイプとトライアルの残り日数を表示するウィジェットが表示されます。

### すでにアカウントをお持ちの場合 {#if-you-already-have-an-account}

すでにGitLabアカウントをお持ちの場合は、グループ設定から直接トライアルを開始できます。

前提条件: 

- トライアルを適用するトップレベルグループのオーナーロールが必要です。グループメンバーシップによる間接的な所有権では不十分です。
- トップレベルグループは、以前にGitLabクレジットでトライアルを行ったことがない必要があります。

トライアルを開始するには、次の手順に従います:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **請求**を選択します。
1. **無料トライアルを開始**を選択します。
1. フィールドに入力します。
1. **続行する**を選択します。
1. トライアルを適用するグループを選択します。
1. **トライアル版を有効にする**を選択します。

トライアルがすぐに開始されます。左側のサイドバーの下部に、トライアルのタイプとトライアルの残り日数を表示するウィジェットが表示されます。

## GitLab Self-Managedインスタンスでトライアルを開始 {#start-a-trial-on-gitlab-self-managed}

GitLab Self-Managedインスタンスのトライアルを開始するには、フォームに記入して、メールでトライアルライセンスを受け取ります。

前提条件: 

- GitLab Self-Managedインスタンスが[インストール](../install/_index.md)および構成されている必要があります。
- インスタンスが[GitLabとサブスクリプションデータを同期](manage_subscription.md#subscription-data-synchronization)できる必要があります。
- 管理者である必要があります。

トライアルを開始するには、次の手順に従います:

1. [GitLab Ultimate](https://about.gitlab.com/free-trial/?hosted=self-managed)のトライアルページにGo。
1. フィールドに入力します。
1. **開始する**を選択します。
1. トライアルのアクティベーションコードが記載されたメールを確認します。トライアルリクエストの送信後すぐに、トライアルリクエストフォームに入力したメールアドレス宛てにアクティベーションコードが記載されたメールが届きます。アクティベーションコードは、1回のみ有効です。
1. 管理者としてGitLabにサインインします。
1. 右上隅で、**管理者**を選択します。
1. **サブスクリプション**を選択します。
1. **アクティベーションコード**にアクティベーションコードを貼り付けます。
1. 利用規約を読んで同意します。
1. **アクティブ化**を選択します。

これで、サブスクリプションがアクティブ化されます。

## トライアル期間の残り日数を表示 {#view-remaining-trial-period-days}

サブスクリプションのアップグレードを計画できるように、トライアル期間の残り時間を追跡できます。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーの下部に、トライアルのタイプとトライアルの残り日数を表示するウィジェットが表示されます。
1. GitLab Self-Managedインスタンスで、アップグレード時に利用できる機能に関する情報にアクセスするには、**詳しく見る**を選択します。
