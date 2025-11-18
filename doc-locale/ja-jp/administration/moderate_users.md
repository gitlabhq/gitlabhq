---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: ユーザーをモデレートする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インスタンス管理者の場合、ユーザーアクセスをモデレートおよび制御するためのオプションがいくつかあります。

{{< alert type="note" >}}

このトピックは、特にGitLab Self-Managedでのユーザーモデレーションに関するものです。グループ関連の情報については、[グループドキュメント](../user/group/moderate_users.md)を参照してください。

{{< /alert >}}

## タイプ別のユーザーの表示 {#view-users-by-type}

{{< history >}}

- タイプ別のユーザーの絞り込みがGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/541186)。

{{< /history >}}

確立されたGitLabインスタンスは、多くの場合、多数の人間およびボットユーザーが存在する可能性があります。ユーザーのリストをフィルタリングして、人間または[ボットユーザー](internal_users.md)のみを表示できます。

タイプ別にユーザーを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスに、フィルターを入力します。
   - 人間のユーザーを表示するには、**Type=Humans**と入力します。
   - ボットユーザーを表示するには、**Type=Bots**と入力します。
1. <kbd>Enter</kbd>キーを押します。

## 承認待ちのユーザー {#users-pending-approval}

承認承認待ちの状態のユーザーは、管理者によるアクションを必要とします。管理者が次のオプションのいずれかを有効にしている場合、ユーザーサインアップは承認待ちの状態になる可能性があります:

- [新しいサインアップに対して管理者の承認を要求する](settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups)設定。
- [ユーザーキャップ](settings/sign_up_restrictions.md#user-cap)。
- [自動作成されたユーザーのブロック(OmniAuth)](../integration/omniauth.md#configure-common-settings)
- [自動作成されたユーザーのブロック(LDAP)](auth/ldap/_index.md#basic-configuration-settings)

この設定が有効になっているときにユーザーがアカウントを登録すると:

- ユーザーは**承認保留中**の状態になります。
- ユーザーには、アカウントが管理者による承認を待機中であるというメッセージが表示されます。

承認待ちのユーザー:

- [ブロックされた](#block-a-user)ユーザーと機能的に同じです。
- サインインできません。
- GitリポジトリまたはGitLab APIにアクセスできません。
- GitLabからの通知を受信しません。
- [シート](../subscriptions/manage_users_and_seats.md#billable-users)を消費しません。

管理者は、サインインを許可するために、[サインアップを承認する必要があります](#approve-or-reject-a-user-sign-up)。

### 承認待ちのユーザーサインアップを表示 {#view-user-sign-ups-pending-approval}

{{< history >}}

- 状態によるユーザーの絞り込みがGitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)。

{{< /history >}}

承認待ちのユーザーサインアップを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで、**State=Pending approval**（State=Pending approval）でフィルタリングし、<kbd>Enter</kbd>を押します。

### ユーザーサインアップの承認または拒否 {#approve-or-reject-a-user-sign-up}

{{< history >}}

- 状態によるユーザーの絞り込みがGitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)。

{{< /history >}}

承認待ちのユーザーサインアップは、**管理者**エリアから承認または拒否できます。

ユーザーサインアップを承認または拒否するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで、**State=Pending approval**（State=Pending approval）でフィルタリングし、<kbd>Enter</kbd>を押します。
1. 承認または拒否するユーザーサインアップについて、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、**承認する**または**拒否**を選択します。

ユーザーの承認:

- アカウントをアクティブ化します。
- ユーザーの状態をアクティブに変更します。
- サブスクリプションの[シート](../subscriptions/manage_users_and_seats.md#billable-users)を消費します。

ユーザーの拒否:

- ユーザーがサインインしたり、インスタンス情報にアクセスしたりすることを防ぎます。
- ユーザーを削除します。

## ロールプロモーション保留中のユーザーの表示 {#view-users-pending-role-promotion}

[ロールのプロモーションに対する管理者の承認](settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)が有効になっている場合、既存のユーザーを請求対象のロールにプロモートするメンバーシップリクエストには、管理者による承認が必要です。

ロールプロモーション保留中のユーザーを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. **ロールの昇格**を選択します。

要求された最高のロールを持つユーザーのリストが表示されます。リクエストを**承認する**または**拒否**できます。

## ブロックとブロック解除のユーザー {#block-and-unblock-users}

GitLab管理者は、ユーザーをブロックおよびブロック解除できます。ユーザーにインスタンスへのアクセスを許可したくないが、データを保持したい場合は、ユーザーをブロックする必要があります。

ブロックされたユーザー:

- サインインまたはリポジトリへのアクセスはできません。
  - 関連するデータはこれらのリポジトリに残ります。
- [スラッシュコマンド](../user/project/integrations/gitlab_slack_application.md#slash-commands)は使用できません。
- [シート](../subscriptions/manage_users_and_seats.md#billable-users)を占有しません。

### ユーザーをブロック {#block-a-user}

前提要件: 

- インスタンスの管理者である。

ユーザーのインスタンスへのアクセスをブロックできます。

ユーザーをブロックするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. ブロックするユーザーについて、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、**ブロック**を選択します。

他のユーザーからのレポートについては、[不正行為のレポート](../user/report_abuse.md)を参照してください。**管理者**エリアでの不正行為レポートの詳細については、[不正行為レポートの解決](review_abuse_reports.md#resolving-abuse-reports)を参照してください。

### ユーザーのブロック解除 {#unblock-a-user}

{{< history >}}

- 状態によるユーザーの絞り込みがGitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)。

{{< /history >}}

ブロックされたユーザーは、**管理者**エリアからブロック解除できます。これを行うには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで、**State=Blocked**（State=Blocked）でフィルタリングし、<kbd>Enter</kbd>を押します。
1. ブロック解除するユーザーについて、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、**ブロック解除**を選択します。

ユーザーの状態はアクティブに設定され、[シート](../subscriptions/manage_users_and_seats.md#billable-users)を消費します。

{{< alert type="note" >}}

ユーザーは、[GitLab API](../api/user_moderation.md#unblock-access-to-a-user)を使用してブロック解除することもできます。

{{< /alert >}}

ブロック解除オプションは、LDAPユーザーでは使用できない場合があります。ブロック解除オプションを有効にするには、最初にLDAP識別子を削除する必要があります:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで、**State=Blocked**（State=Blocked）でフィルタリングし、<kbd>Enter</kbd>を押します。
1. ユーザーを選択します。
1. **識別子**タブを選択します。
1. LDAPプロバイダーを見つけて、**削除**を選択します。

## ユーザーの非アクティブ化と再アクティブ化 {#deactivate-and-reactivate-users}

GitLab管理者は、ユーザーを非アクティブ化および再アクティブ化できます。最近アクティビティーがなく、インスタンスでシートを占有させたくない場合は、ユーザーを非アクティブ化する必要があります。

非アクティブ化されたユーザー:

- GitLabにサインインできます。
  - 非アクティブ化されたユーザーがサインインすると、自動的に再アクティブ化されます。
- リポジトリまたはAPIにアクセスできません。
- スラッシュコマンドを使用できません。詳細については、[スラッシュコマンド](../user/project/integrations/gitlab_slack_application.md#slash-commands)を参照してください。
- シートを占有しません。詳細については、[請求対象ユーザー](../subscriptions/manage_users_and_seats.md#billable-users)を参照してください。

ユーザーを非アクティブ化すると、プロジェクト、グループ、および履歴が保持されます。

### ユーザーを非アクティブ化 {#deactivate-a-user}

前提要件: 

- ユーザーは過去90日間アクティビティーがありません。

ユーザーを非アクティブ化するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 非アクティブ化するユーザーについて、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、**無効にする**を選択します。
1. ダイアログで、**無効にする**を選択します。

ユーザーは、アカウントが非アクティブ化されたというメール通知を受信します。このメールの通知を受信しなくなります。詳細については、[ユーザーの非アクティブ化メール](settings/email.md#user-deactivation-emails)を参照してください。

GitLab APIを使用してユーザーを非アクティブ化するには、[ユーザーの非アクティブ化](../api/user_moderation.md#deactivate-a-user)を参照してください。ユーザーの永続的な制限については、[ブロックとブロック解除のユーザー](#block-and-unblock-users)を参照してください。

GitLab.comサブスクリプションからユーザーを削除するには、[サブスクリプションからのユーザーの削除](../subscriptions/manage_users_and_seats.md#remove-users-from-subscription)を参照してください。

### 休止中のユーザーを自動的に非アクティブ化 {#automatically-deactivate-dormant-users}

{{< history >}}

- カスタマイズ可能な期間がGitLab 15.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/336747)
- 非アクティブ期間の下限が90日に設定されましたGitLab 15.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100793)

{{< /history >}}

管理者は、次のいずれかに該当するユーザーの自動非アクティブ化を有効にできます:

- 1週間以上前に作成され、サインインしていない。
- 指定された期間（デフォルトおよび最小値は90日）アクティビティーがない。

これを行うには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**セクションを展開します。
1. **休止中のユーザー**で、**非アクティブな期間後に休眠ユーザーを非アクティブ化する**をオンにします。
1. **アクティブ解除前の非アクティブ期間**で、アクティブ解除までの日数を入力します。最小値は90日です。
1. **変更を保存**を選択します。

この機能が有効になっている場合、GitLabは毎日のジョブを実行して、休止中のユーザーを非アクティブ化します。

1日に最大100,000人のユーザーを非アクティブ化できます。

デフォルトでは、ユーザーはアカウントが非アクティブ化されると、メール通知を受信します。[ユーザーの非アクティブ化メール](settings/email.md#user-deactivation-emails)を無効にできます。

{{< alert type="note" >}}

GitLabで生成されたボットは、休止中のユーザーの自動非アクティブ化から除外されます。

{{< /alert >}}

### 未確認のユーザーを自動的に削除する {#automatically-delete-unconfirmed-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.1で`delete_unconfirmed_users_setting`[フラグ](feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352514)されました。デフォルトでは無効になっています。
- GitLab 16.2で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124982)になりました。

{{< /history >}}

前提要件:

- 管理者である必要があります。

次の両方に該当するユーザーの自動削除を有効にできます:

- メールアドレスを確認しなかった。
- 過去に指定された日数を超えてGitLabにサインアップしました。

これらの設定は、[設定API](../api/settings.md)またはRailsコンソールで構成できます:

```ruby
 Gitlab::CurrentSettings.update(delete_unconfirmed_users: true)
 Gitlab::CurrentSettings.update(unconfirmed_users_delete_after_days: 365)
```

`delete_unconfirmed_users`設定が有効になっている場合、GitLabは1時間に1回ジョブを実行して、未確認のユーザーを削除します。このジョブは、`unconfirmed_users_delete_after_days`日以上前にサインアップしたユーザーのみを削除します。

このジョブは、`email_confirmation_setting`が`soft`または`hard`に設定されている場合にのみ実行されます。

1日に最大240,000人のユーザーを削除できます。

### ユーザーを再アクティブ化 {#reactivate-a-user}

{{< history >}}

- 状態によるユーザーの絞り込みがGitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)。

{{< /history >}}

非アクティブ化されたユーザーは、**管理者**エリアから再アクティブ化できます。

これを行うには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで、**State=Deactivated**（State=Deactivated）でフィルタリングし、<kbd>Enter</kbd>を押します。
1. 再アクティブ化するユーザーについて、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、**アクティブ化**を選択します。

ユーザーの状態はアクティブに設定され、[シート](../subscriptions/manage_users_and_seats.md#billable-users)を消費します。

{{< alert type="note" >}}

非アクティブ化されたユーザーは、ユーザーインターフェースから再度ログインすることで、自分でアカウントを再アクティブ化することもできます。ユーザーは、[GitLab API](../api/user_moderation.md#reactivate-a-user)を使用して再アクティブ化することもできます。

{{< /alert >}}

## ユーザーのBANとBAN {#ban-and-unban-users}

{{< history >}}

- BANされたユーザーのマージリクエストを非表示にすることがGitLab 15.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107836)。`hide_merge_requests_from_banned_users`という名前の[フラグ](feature_flags/_index.md)付き。デフォルトでは無効になっています。
- BANされたユーザーのコメントを非表示にすることがGitLab 15.11で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112973)。`hidden_notes`という名前の[フラグ](feature_flags/_index.md)付き。デフォルトでは無効になっています。
- BANされたユーザーのプロジェクトを非表示にすることがGitLab 16.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121488)。`hide_projects_of_banned_users`という名前の[フラグ](feature_flags/_index.md)付き。デフォルトでは無効になっています。
- BANされたユーザーのマージリクエストを非表示にすることがGitLab 18.0で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188770)されました。機能フラグ`hide_merge_requests_from_banned_users`は削除されました。

{{< /history >}}

GitLab管理者は、ユーザーをBANおよびBANできます。ユーザーをブロックし、アクティビティーをインスタンスから非表示にする場合は、ユーザーをBANする必要があります。

BANされたユーザー:

- サインインまたはリポジトリへのアクセスはできません。
  - 関連するプロジェクト、イシュー、マージリクエスト、またはコメントは非表示になります。
- [スラッシュコマンド](../user/project/integrations/gitlab_slack_application.md#slash-commands)は使用できません。
- [シート](../subscriptions/manage_users_and_seats.md#billable-users)を占有しません。

### ユーザーをBAN {#ban-a-user}

ユーザーをブロックし、コントリビュートを非表示にするために、管理者はユーザーをBANできます。

ユーザーをBANするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. BANするメンバーの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. ドロップダウンリストから、**メンバーをBAN**を選択します。

### ユーザーのBAN {#unban-a-user}

{{< history >}}

- 状態によるユーザーの絞り込みがGitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)。

{{< /history >}}

ユーザーのBANを解除するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで、**State=Banned**（State=Banned）でフィルタリングし、<kbd>Enter</kbd>を押します。
1. BANするメンバーの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. ドロップダウンリストから、**Unban member**（メンバーをBAN）を選択します。

ユーザーの状態はアクティブに設定され、[シート](../subscriptions/manage_users_and_seats.md#billable-users)を消費します。

## ユーザーを削除する {#delete-a-user}

**管理者**エリアを使用して、ユーザーを削除します。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 削除するユーザーについて、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、**ユーザーを削除**を選択します。
1. ユーザー名を入力します。
1. **ユーザーを削除**を選択します。

{{< alert type="note" >}}

ユーザーを削除できるのは、グループの継承されたオーナーまたは直接のオーナーがいる場合のみです。ユーザーが唯一のグループオーナーである場合は、ユーザーを削除できません。

{{< /alert >}}

ユーザーとそのコントリビュート（マージリクエスト、イシュー、および唯一のグループオーナーであるグループなど）を削除することもできます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 削除するユーザーについて、縦方向の省略記号({{< icon name="ellipsis_v" >}})を選択し、**ユーザーとコントリビュートを削除**を選択します。
1. ユーザー名を入力します。
1. **ユーザーとコントリビュートを削除**を選択します。

{{< alert type="note" >}}

15.1より前は、削除されたユーザーが直接のメンバーの中で唯一のオーナーであったグループも削除されていました。

{{< /alert >}}

## ユーザーの信頼と信頼の解除 {#trust-and-untrust-users}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132402)されました。
- 状態によるユーザーの絞り込みがGitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)。

{{< /history >}}

ユーザーの信頼と信頼の解除は、**管理者**エリアから行うことができます。

デフォルトでは、ユーザーは信頼されておらず、スパムと見なされるイシュー、ノート、およびスニペットの作成をブロックされています。ユーザーを信頼すると、イシュー、ノート、スニペットをブロックされずに作成できます。

前提要件:

- 管理者である必要があります。

{{< tabs >}}

{{< tab title="ユーザーを信頼する" >}}

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. ユーザーを選択します。
1. **ユーザー管理**ドロップダウンリストから、**ユーザーを信頼する**を選択します。
1. 確認ダイアログで、**ユーザーを信頼する**を選択します。

ユーザーは信頼されます。

{{< /tab >}}

{{< tab title="ユーザーの信用を解除" >}}

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索ボックスで**State=Trusted**（State=Trusted）でフィルタリングし、<kbd>Enter</kbd>を押します。
1. ユーザーを選択します。
1. **ユーザー管理**ドロップダウンリストから、**ユーザーの信用を解除**を選択します。
1. 確認ダイアログで、**ユーザーの信用を解除**を選択します。

ユーザーの信頼が解除されます。

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング {#troubleshooting}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

ユーザーをモデレートする場合、特定の条件に基づいて、ユーザーに対して一括操作を実行する必要がある場合があります。次のRailsコンソールスクリプトに、その例をいくつか示します。[Railsコンソールセッションを開始](operations/rails_console.md#starting-a-rails-console-session)し、次のようなスクリプトを使用できます:

### 最近アクティビティーのないユーザーを非アクティブ化 {#deactivate-users-that-have-no-recent-activity}

管理者は、最近アクティビティーのないユーザーを非アクティブ化できます。

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.deactivate!
end
```

### 最近アクティビティーのないユーザーをブロック {#block-users-that-have-no-recent-activity}

管理者は、最近アクティビティーのないユーザーをブロックできます。

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.block!
end
```

### プロジェクトまたはグループを持たないユーザーをブロックまたは削除 {#block-or-delete-users-that-have-no-projects-or-groups}

管理者は、プロジェクトまたはグループを持たないユーザーをブロックまたは削除できます。

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

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
