---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトアクセストークン
description: 認証、作成、失効、トークンの有効期限。
---

{{< details >}}

プラン: Free、Premium、Ultimate 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトアクセストークンは、特定のプロジェクトへの認証されたアクセスを提供します。これらはグループアクセストークンやパーソナルアクセストークンに似ていますが、グループやユーザーではなく関連するプロジェクトにスコープされています。他のプロジェクトのプロジェクトアクセストークンを使用してリソースにアクセスしたり、他のグループアクセストークン、プロジェクトアクセストークン、またはパーソナルアクセストークンを作成したりすることはできません。

プロジェクトアクセストークンを使用して認証できるのは以下のとおりです:

- [GitLab API](../../../api/rest/authentication.md#personal-project-and-group-access-tokens)で認証。
- HTTPS経由でのGit。使用方法:
  - 任意の空白以外の値をユーザー名として使用します。
  - パスワードとしてプロジェクトアクセストークンを使用します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

> [!note]
> GitLab.comでは、プロジェクトアクセストークンにはPremiumまたはUltimateのサブスクリプションが必要です。[トライアル](https://about.gitlab.com/free-trial/#what-is-included-in-my-free-trial-what-is-excluded)期間中は、プロジェクトアクセストークンは1つに制限されます。
>
> GitLab Self-ManagedおよびGitLab Dedicatedでは、プロジェクトアクセストークンは任意のライセンスで利用できます。

## プロジェクトアクセストークンを作成する {#create-a-project-access-token}

{{< history >}}

- 最大許容ライフタイム制限は、GitLab 17.6で[400日に延長され](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)、`buffered_token_expiration_limit`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)で導入されました。デフォルトでは無効になっています。
- プロジェクトアクセストークンの説明は、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)されました。

{{< /history >}}

> [!flag]
> 延長された最大許容ライフタイム制限の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

プロジェクトアクセストークンを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **アクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. **トークン名**に名前を入力します。トークン名は、プロジェクトを表示する権限を持つすべてのユーザーに表示されます。
1. オプション。**トークンの説明**に、トークンの説明を入力します。
1. **有効期限**に、トークンの有効期限を入力します。
   - トークンは、その日付のUTC真夜中に期限切れになります。
   - 日付を入力しない場合、有効期限は今日から365日後に設定されます。
   - デフォルトでは、有効期限は今日から365日を超えることはできません。GitLab 17.6以降、管理者は[アクセストークンの最大ライフタイムを修正](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)できます。
1. トークンのロールを選択します。
1. 1つ以上の[プロジェクトアクセストークンスコープ](../../../security/tokens/access_token_scopes.md)を選択します。
1. **プロジェクトアクセストークンを作成**を選択します。

プロジェクトアクセストークンが表示されます。プロジェクトアクセストークンを安全な場所に保存します。ページを離れるか更新すると、再度表示することはできません。

すべてのプロジェクトアクセストークンは、パーソナルアクセストークン用に設定された[デフォルトのプレフィックス設定](../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)を継承します。

> [!warning]
> プロジェクトアクセストークンは内部ユーザーとして扱われます。内部ユーザーがプロジェクトアクセストークンを作成した場合、そのトークンは表示レベルがInternalに設定されているすべてのプロジェクトにアクセスできます。

## アクセストークンを表示 {#view-your-access-tokens}

{{< history >}}

- IPアドレスを表示する機能は、GitLab 17.8で`pat_ip`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/428577)。17.9ではデフォルトで有効になっています。
- IPアドレスを表示する機能は、GitLab 17.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/513302)になりました。機能フラグ`pat_ip`は削除されました。

{{< /history >}}

プロジェクトアクセストークンページには、アクセストークンに関する情報が表示されます。

このページから、以下の操作を実行できます:

- プロジェクトアクセストークンの作成、ローテーション、および失効。
- すべてのアクティブおよび非アクティブなプロジェクトアクセストークンを表示。
- トークン情報（スコープ、割り当てられたロール、有効期限を含む）を表示。
- 利用状況の情報（利用日、および過去5件の固有の接続IPアドレスを含む）を表示。
  > [!note]
  > GitLabは、トークンがGit操作を実行したり、[REST](../../../api/rest/_index.md)または[GraphQL](../../../api/graphql/_index.md) APIで操作を認証する際に、トークンの使用情報を定期的に更新します。トークンの使用時間は10分ごとに、トークンの使用IPアドレスは1分ごとに更新されます。

プロジェクトアクセストークンを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **アクセストークン**を選択します。

アクティブで利用可能なアクセストークンは、**アクティブなプロジェクトアクセストークン**セクションに保存されます。期限切れ、ローテーションされた、または失効されたトークンは、**無効なプロジェクトアクセストークン**セクションに保存されます。

## プロジェクトアクセストークンをローテーションする {#rotate-a-project-access-token}

{{< history >}}

- 期限切れおよび失効したトークンを表示する機能は、GitLab 17.3で`retain_resource_access_token_user_after_revoke`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)。デフォルトでは無効になっています。
- 期限切れおよび失効されたトークンが自動的に削除されるまで表示する機能は、GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/471683)されました。機能フラグ`retain_resource_access_token_user_after_revoke`は削除されました。

{{< /history >}}

元のトークンと同じ権限とスコープを持つ新しいトークンを作成するために、トークンをローテーションします。元のトークンはすぐに非アクティブになり、GitLabは監査目的で両方のバージョンを保持します。アクティブおよび非アクティブなトークンの両方を、アクセストークンページで表示できます。

GitLab Self-ManagedおよびGitLab Dedicatedでは、[非アクティブなトークンの保持期間](../../../administration/settings/account_and_limit_settings.md#inactive-project-and-group-access-token-retention-period)を変更できます。

> [!warning]
> この操作は元に戻せません。ローテーションされたアクセストークンに依存するツールは、新しいトークンを参照するまで機能しなくなります。

プロジェクトアクセストークンをローテーションするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **アクセストークン**を選択します。
1. 該当するトークンについて、**ローテーション**（{{< icon name="retry" >}}）を選択します。
1. 確認ダイアログで、**ローテーション**を選択します。

## プロジェクトアクセストークンを失効させる {#revoke-a-project-access-token}

{{< history >}}

- 期限切れおよび失効したトークンを表示する機能は、GitLab 17.3で`retain_resource_access_token_user_after_revoke`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)。デフォルトでは無効になっています。
- 期限切れおよび失効されたトークンが自動的に削除されるまで表示する機能は、GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/471683)されました。機能フラグ`retain_resource_access_token_user_after_revoke`は削除されました。

{{< /history >}}

トークンを失効すると、直ちにそのトークンが無効になり、それ以降の使用を防ぎます。失効されたトークンはすぐに削除されませんが、トークンリストをフィルタリングしてアクティブなトークンのみを表示できます。デフォルトでは、GitLabは失効されたグループアクセストークンおよびプロジェクトアクセストークンを30日後に削除します。詳細については、[非アクティブなトークンの保持](../../../administration/settings/account_and_limit_settings.md#inactive-project-and-group-access-token-retention-period)を参照してください。

> [!warning]
> この操作は元に戻せません。失効されたアクセストークンに依存するツールは、新しいトークンを追加するまで機能しなくなります。

プロジェクトアクセストークンを失効するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **アクセストークン**を選択します。
1. 該当するトークンについて、**取り消し**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**取り消し**を選択します。

## アクセストークンの有効期限 {#access-token-expiration}

パーソナルアクセストークン、グループアクセストークン、およびプロジェクトアクセストークンは、有効期限日のUTC真夜中に期限切れになります。期限切れになると、それらのトークンはリクエストの認証に利用できなくなります。

新しいアクセストークンには有効期限が必要です。トークン作成時に有効期限が明示的に設定されていない場合、現在の日付から365日間の有効期限が適用されます。Ultimateプランでは、管理者はアクセストークンの[最大許容ライフタイム](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)を設定できます。

お使いのGitLabのバージョンと提供内容によっては、GitLabのバージョンをアップグレードする際に、既存のアクセストークンに有効期限が自動的に適用される場合があります。詳細については、[期限切れにならないアクセストークン](../../../update/deprecations.md#non-expiring-access-tokens)を参照してください。

### プロジェクトアクセストークンの有効期限に関するメール {#project-access-token-expiry-emails}

{{< history >}}

- 60日および30日の期限切れ通知は、GitLab 17.6で`expiring_pats_30d_60d_notifications`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)。デフォルトでは無効になっています。
- 60日前と30日前の通知は、GitLab 17.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792)になりました。機能フラグ`expiring_pats_30d_60d_notifications`は削除されました。
- 継承されたグループメンバーへの通知は、GitLab 17.7で`pat_expiry_inherited_members_notification`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)。デフォルトでは無効になっています。
- 機能フラグ`pat_expiry_inherited_members_notification`は、GitLab 17.10でデフォルトで[有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)。
- 機能フラグ`pat_expiry_inherited_members_notification`は、GitLab `17.11`で削除されました。

{{< /history >}}

GitLabは毎日UTC午前1時にチェックを実行し、まもなく期限切れになるプロジェクトアクセストークンを特定します。メンテナーまたはオーナーのロールを持つ直接メンバーには、トークンの有効期限が切れる7日前にメールで通知されます。GitLab 17.6以降では、トークンの期限が切れる30日前と60日前にも通知が送信されます。

GitLab 17.7以降では、継承されたメンテナーまたはオーナーロールを持つメンバーもこれらのメールを受信できます。これは、[GitLabインスタンス](../../../administration/settings/email.md#group-and-project-access-token-expiry-emails-to-inherited-members)上のすべてのグループとプロジェクト、または[特定の親グループ](../../group/manage.md#expiry-emails-for-group-and-project-access-tokens)に対して設定できます。親グループに適用された場合、この設定はすべての子孫グループおよびプロジェクトに継承されます。

期限切れのトークンは、自動的に削除されるまで非アクティブなプロジェクトアクセストークンセクションに表示されます。GitLab Self-Managedでは、この[保持期間](../../../administration/settings/account_and_limit_settings.md#inactive-project-and-group-access-token-retention-period)を変更できます。

## プロジェクトのボットユーザー {#bot-users-for-projects}

{{< history >}}

- GitLab 17.2で`retain_resource_access_token_user_after_revoke`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)で[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)。デフォルトでは無効になっています。有効にすると、新しいボットユーザーは有効期限なしでメンバーになり、トークンが後で失効させられたり、または期限切れになった場合も、ボットユーザーは30日間保持されます。
- 非アクティブなボットユーザーの保持は、GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)になりました。機能フラグ`retain_resource_access_token_user_after_revoke`は削除されました。

{{< /history >}}

プロジェクトアクセストークンを作成すると、GitLabはボットユーザーを作成し、それをトークンに関連付けます。

ボットユーザーには以下のプロパティがあります:

- 関連付けられたアクセストークンのロールとスコープに対応する権限が付与されます。
- それらはプロジェクトのメンバーですが、プロジェクトから削除したり、他のグループやプロジェクトに直接追加したりすることはできません。
- これらは[課金対象外ユーザー](../../../subscriptions/manage_seats.md#criteria-for-non-billable-users)であり、ライセンス制限の対象にはなりません。
- 彼らのコントリビュートはボットユーザーアカウントに関連付けられています。
- 削除されると、彼らのコントリビュートは[ゴーストユーザー](../../profile/account/delete_account.md#associated-records)に移動されます。

ボットユーザーが作成されると、以下の属性が定義されます:

| 属性 | 値                                                                                                    | 例 |
| --------- | -------------------------------------------------------------------------------------------------------- | ------- |
| 名前      | 関連付けられたアクセストークンの名前。                                                                 | `Main token - Read registry` |
| ユーザー名  | この形式で生成されます: `project_{project_id}_bot_{random_string}`                                     | `project_123_bot_4ffca233d8298ea1` |
| メール     | この形式で生成されます: `project_{project_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}` | `project_123_bot_4ffca233d8298ea1@noreply.example.com` |

## プロジェクトアクセストークンの作成を制限する {#restrict-the-creation-of-project-access-tokens}

悪用を防ぐため、トップレベルグループ内のプロジェクトに対するアクセストークンの作成をユーザーに制限できます。既存のトークンは、期限切れになるか手動で失効されるまで有効です。

詳細については、[グループおよびプロジェクトアクセストークンの作成を制限する](../../group/settings/group_access_tokens.md#restrict-the-creation-of-group-and-project-access-tokens)を参照してください。

## 関連トピック {#related-topics}

- [パーソナルアクセストークン](../../profile/personal_access_tokens.md)
- [グループアクセストークン](../../group/settings/group_access_tokens.md)
- [プロジェクトアクセストークンAPI](../../../api/project_access_tokens.md)
