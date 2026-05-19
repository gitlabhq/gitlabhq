---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: ユーザーをブロック、無効化、BAN、または信頼することで、インスタンスへのアクセスとアクティビティを制御します。
gitlab_dedicated: yes
title: ユーザーをモデレートする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インスタンス管理者である場合、ユーザーアクセスをモデレートおよび制御するためのいくつかのオプションがあります。

> [!note]
> このトピックは、GitLab Self-Managedでのユーザーモデレーションに特に関連しています。グループに関する情報については、[グループドキュメント](../user/group/moderate_users.md)を参照してください。

## ユーザーを表示する {#view-users}

お使いのインスタンス内のすべてのユーザーを表示するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。

ユーザーを選択して、アカウント情報を表示します。

### タイプ別にユーザーを表示 {#view-users-by-type}

{{< history >}}

- GitLab 18.1で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/541186)ユーザータイプのフィルタリング

{{< /history >}}

確立されたGitLabインスタンスには、多くの場合、多数の人間ユーザーとボットユーザーが存在します。ユーザーのリストをフィルタリングして、人間または[ボットユーザー](internal_users.md)のみを表示できます。

タイプ別にユーザーを表示するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスに、フィルターを入力します。
   - 人間ユーザーを表示するには、**Type=Humans**と入力します。
   - ボットユーザーを表示するには、**Type=Bots**と入力します。
1. <kbd>Enter</kbd>キーを押します。

## 請求対象ユーザー {#billable-users}

Railsコンソールを通じて、インスタンス内の[請求対象ユーザー](../subscriptions/manage_seats.md#billable-users)を表示および更新できます。

### 毎日および過去の請求対象ユーザー数を確認する {#check-daily-and-historical-billable-users}

GitLabインスタンス内の日次および過去の請求対象ユーザーのリストを取得するには:

1. [Railsコンソールセッションを開始します](operations/rails_console.md#starting-a-rails-console-session)。
1. インスタンス内のユーザー数をカウントします。

   ```ruby
   User.billable.count
   ```

1. 過去1年間についてインスタンスの過去の最大ユーザー数を取得します。

   ```ruby
   ::HistoricalData.max_historical_user_count(from: 1.year.ago.beginning_of_day, to: Time.current.end_of_day)
   ```

### 毎日および過去の請求対象ユーザー数を更新する {#update-daily-and-historical-billable-users}

GitLabインスタンス内の日次および過去の請求対象ユーザーの手動更新をトリガーするには:

1. [Railsコンソールセッションを開始します](operations/rails_console.md#starting-a-rails-console-session)。
1. 毎日の請求対象ユーザー数の更新を強制的に実行します。

   ```ruby
   identifier = Analytics::UsageTrends::Measurement.identifiers[:billable_users]
   ::Analytics::UsageTrends::CounterJobWorker.new.perform(identifier, User.minimum(:id), User.maximum(:id), Time.zone.now)
   ```

1. 過去の最大請求対象ユーザー数の更新を強制的に実行します。

   ```ruby
   ::HistoricalDataWorker.new.perform
   ```

## 承認保留中のユーザー {#users-pending-approval}

承認保留中状態のユーザーには、管理者によるアクションが必要です。管理者が以下のいずれかのオプションを有効にしている場合、ユーザー登録は承認保留中状態になることがあります:

- 新規ユーザーアカウント作成に対する[Require administrator approval for new user account creation](settings/sign_up_restrictions.md#require-administrator-approval-for-new-user-accounts)設定。
- [User cap](settings/sign_up_restrictions.md#user-cap)。
- [Block auto-created users (OmniAuth)](../integration/omniauth.md#configure-common-settings)
- [Block auto-created users (LDAP)](auth/ldap/_index.md#basic-configuration-settings)

この設定が有効な間にユーザーがアカウントを登録すると:

- ユーザーは**承認保留中**の状態になります。
- ユーザーには、アカウントが管理者による承認を待っていることを示すメッセージが表示されます。

承認保留中のユーザー:

- [ブロック](#block-a-user)されたユーザーと機能的には同じです。
- サインインできません。
- GitリポジトリまたはGitLabAPIにアクセスできません。
- GitLabから通知を受け取りません。
- [シート](../subscriptions/manage_seats.md#billable-users)を消費しません。

管理者は、サインインを許可するために、[登録を承認する](#approve-or-reject-a-new-user-account)必要があります。

### 承認保留中のユーザー登録を表示 {#view-user-sign-ups-pending-approval}

{{< history >}}

- GitLab 17.0で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)ユーザーの状態によるフィルタリング

{{< /history >}}

承認保留中のユーザー登録を表示するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで**State=Pending approval**でフィルタリングし、<kbd>Enter</kbd>を押します。

### 新しいユーザーアカウントを承認するまたは拒否する {#approve-or-reject-a-new-user-account}

{{< history >}}

- GitLab 17.0で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)ユーザーの状態によるフィルタリング

{{< /history >}}

承認保留中のユーザー登録は、**管理者**エリアから承認または拒否できます。

ユーザー登録を承認するまたは拒否するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで**State=Pending approval**でフィルタリングし、<kbd>Enter</kbd>を押します。
1. 承認するまたは拒否するユーザー登録に対して、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、次に**承認する**または**拒否**を選択します。

ユーザーを承認すると:

- アカウントが有効化されます。
- ユーザーの状態がアクティブに変更されます。
- サブスクリプションの[シート](../subscriptions/manage_seats.md#billable-users)を消費します。

ユーザーを拒否すると:

- ユーザーがサインインしたり、インスタンス情報にアクセスしたりするのを防ぎます。
- ユーザーを削除します。

## ロールのプロモート保留中のユーザーを表示 {#view-users-pending-role-promotion}

[ロールのプロモーションに対する管理者の承認](settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)が有効になっている場合、既存のユーザーを請求対象のロールにプロモートするメンバーシップリクエストには、管理者による承認が必要です。

ロールのプロモート保留中のユーザーを表示するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. **ロールのプロモート**を選択します。

リクエストされた最高のロールを持つユーザーのリストが表示されます。リクエストを**承認する**か**拒否**できます。

## ユーザーをブロックおよびブロック解除する {#block-and-unblock-users}

GitLab管理者は、ユーザーをブロックおよびブロック解除できます。ユーザーがインスタンスにアクセスするのを望まないが、そのデータを保持したい場合に、ユーザーをブロックする必要があります。

ブロックされたユーザー:

- サインインしたり、リポジトリにアクセスしたりできません。
  - 関連付けられたデータは、これらのリポジトリに残ります。
- [slash commands in Slack](../user/project/integrations/gitlab_slack_application.md#slash-commands)を使用できません。
- [シート](../subscriptions/manage_seats.md#billable-users)を占有しません。

### ユーザーをブロックする {#block-a-user}

前提条件: 

- インスタンスの管理者である必要があります。

ユーザーのインスタンスへのアクセスをブロックできます。

ユーザーをブロックするには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. ブロックしたいユーザーに対して、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、次に**ブロック**を選択します。

他のユーザーからの不正行為をレポートするには、[不正行為のレポート](../user/report_abuse.md)を参照してください。**管理者**エリアでの不正行為レポートに関する詳細については、[不正行為レポートの解決](review_abuse_reports.md#resolving-abuse-reports)を参照してください。

### ユーザーをブロック解除する {#unblock-a-user}

{{< history >}}

- GitLab 17.0で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)ユーザーの状態によるフィルタリング

{{< /history >}}

ユーザーをブロック解除して、インスタンスへのアクセスを再度許可できます。

ユーザーをブロック解除するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで**State=Blocked**でフィルタリングし、<kbd>Enter</kbd>を押します。
1. ブロック解除したいユーザーに対して、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、次に**ブロック解除**を選択します。

ユーザーの状態はアクティブに設定され、[シート](../subscriptions/manage_seats.md#billable-users)を消費します。

> [!note]
> ユーザーはGitLab[API](../api/user_moderation.md#unblock-access-to-a-user)を使用してブロック解除することもできます。

ブロック解除オプションは、LDAPユーザーでは利用できない場合があります。ブロック解除オプションを有効にするには、まずLDAPの識別子を削除する必要があります:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで**State=Blocked**でフィルタリングし、<kbd>Enter</kbd>を押します。
1. ユーザーを選択します。
1. **識別子**タブを選択します。
1. LDAPプロバイダーを見つけて**削除**を選択します。

## ユーザーを無効にするおよびアクティブ化する {#deactivate-and-reactivate-users}

GitLab管理者は、ユーザーを無効にするおよびアクティブ化できます。最近のアクティビティがない場合や、インスタンスのシートを占有させたくない場合は、ユーザーを無効にする必要があります。

無効化されたユーザー:

- GitLabにサインインできます。
  - 無効化されたユーザーがサインインすると、自動的に再アクティブ化されます。
- リポジトリまたはAPIにアクセスできません。
- [slash commands in Slack](../user/project/integrations/gitlab_slack_application.md#slash-commands)を使用できません。
- シートを占有しません。詳細については、[請求対象ユーザー](../subscriptions/manage_seats.md#billable-users)を参照してください。

ユーザーを無効にすると、そのプロジェクト、グループ、および履歴は保持されます。

### ユーザーを無効にする {#deactivate-a-user}

前提条件: 

- ユーザーは過去90日間アクティビティがありません。

ユーザーを無効にするには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 無効にするユーザーに対して、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、次に**無効にする**を選択します。
1. 確認ダイアログで、**無効にする**を選択します。

ユーザーは、アカウントが無効化されたことを知らせるメール通知を受け取ります。このメールの後、彼らは通知を受け取らなくなります。詳細については、[user deactivation emails](settings/email.md#user-deactivation-emails)を参照してください。

GitLabAPIを使用してユーザーを無効にするには、[ユーザーを無効にする](../api/user_moderation.md#deactivate-a-user)を参照してください。永続的なユーザー制限に関する情報については、[ユーザーをブロックおよびブロック解除する](#block-and-unblock-users)を参照してください。

GitLab.comサブスクリプションからユーザーを削除するには、[Remove users from your subscription](../subscriptions/manage_seats.md#remove-users-from-subscription)を参照してください。

### 休止中のユーザーを自動的に無効化する {#automatically-deactivate-dormant-users}

{{< history >}}

- GitLab 15.4で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/336747)カスタマイズ可能な期間
- GitLab 15.5で[導入された](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100793)非アクティブ期間の下限を90日に設定

{{< /history >}}

管理者は、以下のいずれかのユーザーの自動無効化を有効にできます:

- 1週間以上前に作成され、サインインしていないユーザー。
- 指定された期間（デフォルトおよび最小90日）アクティビティがないユーザー。

休止中のメンバーを自動的に無効化するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**セクションを展開します。
1. **休止中のユーザー**の下で、**非アクティブな期間後に休眠ユーザーを非アクティブ化する**をチェックします。
1. **アクティブ解除前の非アクティブ期間**の下で、非アクティブ化までの日数を入力します。最小値は90日です。
1. **変更を保存**を選択します。

この機能が有効な場合、GitLabは毎日ジョブを実行して休止中のユーザーを無効化します。

1日あたり最大100,000人のユーザーを無効化できます。

デフォルトでは、アカウントが無効化されるとユーザーはメール通知を受け取ります。[user deactivation emails](settings/email.md#user-deactivation-emails)を無効にできます。

> [!note]
> GitLabが生成したボットは、休止中のユーザーの自動無効化から除外されます。

### 未確認ユーザーを自動的に削除する {#automatically-delete-unconfirmed-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.1で`delete_unconfirmed_users_setting`[フラグ](feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352514)されました。デフォルトでは無効になっています。
- GitLab 16.2で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124982)。

{{< /history >}}

前提条件: 

- 管理者である必要があります。

以下の両方に該当するユーザーの自動削除を有効にできます:

- メールアドレスを一度も確認していない。
- 過去に指定された日数以上前にGitLabに登録している。

これらの設定は、[設定API](../api/settings.md)またはRailsコンソールを使用して構成できます:

```ruby
 Gitlab::CurrentSettings.update(delete_unconfirmed_users: true)
 Gitlab::CurrentSettings.update(unconfirmed_users_delete_after_days: 365)
```

`delete_unconfirmed_users`設定が有効な場合、GitLabは1時間ごとにジョブを実行して未確認ユーザーを削除します。このジョブは、過去`unconfirmed_users_delete_after_days`日以上前に登録したユーザーのみを削除します。

このジョブは、`email_confirmation_setting`が`soft`または`hard`に設定されている場合にのみ実行されます。

1日あたり最大240,000人のユーザーを削除できます。

### ユーザーを再アクティブ化する {#reactivate-a-user}

{{< history >}}

- GitLab 17.0で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)ユーザーの状態によるフィルタリング

{{< /history >}}

ユーザーを再アクティブ化するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで**State=Deactivated**でフィルタリングし、<kbd>Enter</kbd>を押します。
1. 再アクティブ化したいユーザーに対して、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、次に**アクティブ化**を選択します。

ユーザーの状態はアクティブに設定され、[シート](../subscriptions/manage_seats.md#billable-users)を消費します。

> [!note]
> 無効化されたユーザーは、UIを通じて再度ログインすることで、自分でアカウントを再アクティブ化することもできます。ユーザーはGitLab[API](../api/user_moderation.md#reactivate-a-user)を使用して再アクティブ化することもできます。

## ユーザーをBANおよびBANを解除する {#ban-and-unban-users}

{{< history >}}

- BANされたユーザーのマージリクエストの非表示機能は、GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107836)され、`hide_merge_requests_from_banned_users`という名前の[フラグ](feature_flags/_index.md)が付いています。デフォルトでは無効になっています。
- BANされたユーザーのコメントの非表示機能は、GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112973)され、`hidden_notes`という名前の[フラグ](feature_flags/_index.md)が付いています。デフォルトでは無効になっています。
- BANされたユーザーのプロジェクトの非表示機能は、GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121488)され、`hide_projects_of_banned_users`という名前の[フラグ](feature_flags/_index.md)が付いています。デフォルトでは無効になっています。
- BANされたユーザーのマージリクエストの非表示機能は、GitLab 18.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188770)されました。機能フラグ`hide_merge_requests_from_banned_users`は削除されました。

{{< /history >}}

GitLab管理者は、ユーザーをBANおよびBANを解除できます。ユーザーをブロックし、インスタンスから彼らのアクティビティを非表示にしたい場合に、そのユーザーをBANする必要があります。

BANされたユーザー:

- サインインしたり、リポジトリにアクセスしたりできません。
  - 関連付けられたプロジェクト、イシュー、マージリクエスト、またはコメントは非表示になります。
- [slash commands in Slack](../user/project/integrations/gitlab_slack_application.md#slash-commands)を使用できません。
- [シート](../subscriptions/manage_seats.md#billable-users)を占有しません。

### ユーザーをBANする {#ban-a-user}

ユーザーをBANしてブロックし、彼らのコントリビュートを非表示にできます。

ユーザーをBANするには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. BANしたいメンバーの隣にある縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択します。
1. ドロップダウンリストから、**メンバーをBAN**を選択します。

### ユーザーのBANを解除する {#unban-a-user}

{{< history >}}

- GitLab 17.0で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)ユーザーの状態によるフィルタリング

{{< /history >}}

ユーザーのBANを解除するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで**State=Banned**でフィルタリングし、<kbd>Enter</kbd>を押します。
1. BANしたいメンバーの隣にある縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択します。
1. ドロップダウンリストから、**Unban member**を選択します。

ユーザーの状態はアクティブに設定され、[シート](../subscriptions/manage_seats.md#billable-users)を消費します。

## ユーザーを削除する {#delete-a-user}

ユーザーを削除するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 削除したいユーザーに対して、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、次に**ユーザーを削除**を選択します。
1. ユーザー名を入力します。
1. 次のいずれかを選択します:
   - ユーザーのみを**ユーザーを削除**します。
   - ユーザーと、そのコントリビュート（マージリクエスト、イシュー、唯一のグループオーナーであるグループなど）を**ユーザーとコントリビュートを削除**します。

> [!note]
> ユーザーは、グループの継承された、または直接のオーナーである場合にのみ削除できます。ユーザーが唯一のグループオーナーである場合、そのユーザーは削除できません。

## ユーザーを信頼するおよびユーザーの信用を解除する {#trust-and-untrust-users}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132402)されました。
- GitLab 17.0で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)ユーザーの状態によるフィルタリング

{{< /history >}}

デフォルトでは、ユーザーは信頼されておらず、スパムと見なされるイシュー、ノート、およびスニペットの作成をブロックされています。ユーザーを信頼すると、ブロックされることなくイシュー、ノート、およびスニペットを作成できます。

### ユーザーを信頼する {#trust-a-user}

ユーザーを信頼するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. ユーザーを選択します。
1. **ユーザー管理**ドロップダウンリストから、**ユーザーを信頼する**を選択します。
1. 確認ダイアログで、**ユーザーを信頼する**を選択します。

### ユーザーの信用を解除する {#untrust-a-user}

ユーザーの信用を解除するには:

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで**State=Trusted**でフィルタリングし、<kbd>Enter</kbd>を押します。
1. ユーザーを選択します。
1. **ユーザー管理**ドロップダウンリストから、**ユーザーの信用を解除**を選択します。
1. 確認ダイアログで、**ユーザーの信用を解除**を選択します。

## トラブルシューティング {#troubleshooting}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

ユーザーをモデレートする際、特定の条件に基づいて一括アクションを実行する必要がある場合があります。以下のRailsコンソールスクリプトは、そのいくつかの例を示しています。[Railsコンソールセッションを開始](operations/rails_console.md#starting-a-rails-console-session)し、以下のスクリプトと同様のスクリプトを使用できます:

### 最近アクティビティがないユーザーを無効にする {#deactivate-users-that-have-no-recent-activity}

管理者は、最近アクティビティがないユーザーを無効にすることができます。

> [!warning]
> データを変更するコマンドは、正しく実行されない場合、または適切な条件下で実行されない場合に、損傷を引き起こす可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.deactivate!
end
```

### 最近アクティビティがないユーザーをブロックする {#block-users-that-have-no-recent-activity}

管理者は、最近アクティビティがないユーザーをブロックすることができます。

> [!warning]
> データを変更するコマンドは、正しく実行されない場合、または適切な条件下で実行されない場合に、損傷を引き起こす可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.block!
end
```

### プロジェクトやグループがないユーザーをブロックまたは削除する {#block-or-delete-users-that-have-no-projects-or-groups}

管理者は、プロジェクトやグループがないユーザーをブロックまたは削除することができます。

> [!warning]
> データを変更するコマンドは、正しく実行されない場合、または適切な条件下で実行されない場合に、損傷を引き起こす可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

```ruby
users = User.where('id NOT IN (select distinct(user_id) from project_authorizations)')

# How many users are removed?
users.count

# If that count looks sane:

# You can either block the users:
users.each { |user|  user.blocked? ? nil  : user.block! }

# Or you can delete them:
  # need 'current user' (your user) for auditing purposes
current_user = User.find_by(username: '<your username>')

users.each do |user|
  DeleteUserWorker.perform_async(current_user.id, user.id)
end
```
