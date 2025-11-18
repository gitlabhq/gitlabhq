---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サービスアカウント
description: 自動化されたプロセスとサードパーティのインテグレーションのために、非メールアカウントを作成します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

サービスアカウントは、個々の人ではなく、人間ではないエンティティを表すユーザーアカウントです。サービスアカウントを使用すると、自動化されたアクションの実行、データへのアクセス、スケジュールされたプロセスを実行できます。通常、サービスアカウントは、認証情報が安定しており、人間のユーザーメンバーシップの変更に影響されないことが求められる、パイプラインまたはサードパーティのインテグレーションで使用されます。

サービスアカウントには、次の2つの種類があります:

- インスタンスサービスアカウント: GitLabインスタンス全体で利用できますが、ゲストユーザーのようにグループやプロジェクトに追加する必要があります。GitLab Self-ManagedおよびGitLab Dedicatedでのみ利用可能です。
- グループサービスアカウント: 特定のトップレベルグループが所有しており、ゲストユーザーのようにサブグループやプロジェクトへの継承が可能です。

[パーソナルアクセストークン](personal_access_tokens.md)を使用して、サービスアカウントとして認証できます。サービスアカウントは人間のユーザーと同じ機能を持っており、[パッケージやコンテナレジストリ](../packages/_index.md)とのやり取り、[Gitオペレーション](personal_access_tokens.md#clone-repository-using-personal-access-token)の実行、APIへのアクセスなどのアクションを実行できます。

サービスアカウント:

- シートを使用しません。
- UIからGitLabにサインインできません。
- グループおよびプロジェクトのメンバーシップでサービスアカウントとして識別されます。
- カスタムメールアドレスを[追加](../../api/service_accounts.md#create-an-instance-service-account)しない限り、通知メールを受信しません。
- [請求対象ユーザー](../../subscriptions/manage_users_and_seats.md#billable-users)や[内部ユーザー](../../administration/internal_users.md)ではありません。
- GitLab.comの[トライアルバージョン](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com&glm_content=free-user-limit-faq/ee/user/free_user_limit.html)では使用できません。
- GitLab Self-ManagedおよびGitLab Dedicatedのトライアルバージョンで使用できます。

[サービスアカウントAPI](../../api/service_accounts.md)を使用して、サービスアカウントを管理することもできます。

## 前提要件 {#prerequisites}

- GitLab.comでは、トップレベルグループのオーナーロールを持っている必要があります。
- GitLab Self-ManagedまたはGitLab Dedicatedでは、次の条件を満たす必要があります:
  - インスタンスの管理者である。
  - トップレベルグループでオーナーロールを持ち、[サービスアカウントの作成を許可されている](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)。

## サービスアカウントの表示と管理 {#view-and-manage-service-accounts}

{{< history >}}

- GitLab 17.11でGitLab.com向けに導入されました。

{{< /history >}}

サービスアカウントページには、トップレベルグループまたはインスタンスのサービスアカウントに関する情報が表示されます。各トップレベルグループとGitLab Self-Managedインスタンスには、個別のサービスアカウントページがあります。これらのページから、次のことができます:

- グループまたはインスタンスのすべてのサービスアカウントを表示する。
- サービスアカウントを削除する
- サービスアカウントの名前またはユーザー名を編集する。
- サービスアカウントのパーソナルアクセストークンを管理する。

{{< tabs >}}

{{< tab title="インスタンス全体のサービスアカウント" >}}

インスタンス全体のサービスアカウントを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **サービスアカウント**を選択します。

{{< /tab >}}

{{< tab title="グループのサービスアカウント" >}}

トップレベルグループのサービスアカウントを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **サービスアカウント**を選択します。

{{< /tab >}}

{{< /tabs >}}

### サービスアカウントを作成する {#create-a-service-account}

{{< history >}}

- GitLab 16.3でGitLab.com向けに導入されました。
- トップレベルグループのオーナーがサービスアカウントを作成できるようにする機能は、GitLab 17.5で、`allow_top_level_group_owners_to_create_service_accounts`[機能フラグ](../../administration/feature_flags/_index.md)とともに、GitLab Self-Managed向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163726)されました。デフォルトでは無効になっています。
- トップレベルグループのオーナーがサービスアカウントを作成できるようにする機能は、GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172502)になりました。機能フラグ`allow_top_level_group_owners_to_create_service_accounts`は削除されました。

{{< /history >}}

GitLab.comでは、トップレベルグループのオーナーのみがサービスアカウントを作成できます。

デフォルトでは、GitLab DedicatedとGitLab Dedicatedで、管理者のみがサービスアカウントを作成できます。ただし、トップレベルグループのオーナーがグループサービスアカウントを作成できるように、[インスタンスを設定](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)できます。

作成できるサービスアカウントの数は、ライセンスによって制限されます:

- GitLab Freeでは、サービスアカウントを作成できません。
- GitLab Premiumでは、有料シートごとに1つのサービスアカウントを作成できます。
- GitLab Ultimateでは、無制限の数のサービスアカウントを作成できます。

サービスアカウントを作成するには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. **サービスアカウントの追加**を選択します。
1. サービスアカウントの名前を入力します。ユーザー名は、名前に基づいて自動的に生成されます。必要に応じて、ユーザー名を変更できます。
1. **サービスアカウントの作成**を選択します。

### サービスアカウントを編集する {#edit-a-service-account}

サービスアカウントの名前またはユーザー名を編集できます。

サービスアカウントを編集するには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **編集**を選択します。
1. サービスアカウントの名前またはユーザー名を編集します。
1. **変更を保存**を選択します。

### グループとプロジェクトへのサービスアカウントアクセス {#service-account-access-to-groups-and-projects}

サービスアカウントは[外部ユーザー](../../administration/external_users.md)に似ています。最初に作成されたときは、グループとプロジェクトへのアクセスが制限されています。リソースにサービスアカウントアクセスを付与するには、各グループまたはプロジェクトにサービスアカウントを追加する必要があります。

グループまたはプロジェクトに追加できるサービスアカウントの数に制限はありません。サービスアカウントは、メンバーになっている各グループ、サブグループ、またはプロジェクトでさまざまなロールを持つことができます。GitLab.comでは、グループのサービスアカウントは、1つのトップレベルグループのみに属することができます。

人間のユーザーのアクセスを管理するのと同じ方法で、グループとプロジェクトへのサービスアカウントアクセスを管理できます。詳細については、[グループ](../group/_index.md#add-users-to-a-group)と[プロジェクトのメンバー](../project/members/_index.md#add-users-to-a-project)を参照してください。

[メンバーAPI](../../api/members.md)を使用して、グループとプロジェクトの割り当てを管理することもできます。[グローバルSAMLグループメンバーシップロック](../group/saml_sso/group_sync.md#global-saml-group-memberships-lock)または[グローバルLDAPグループメンバーシップロック](../../administration/auth/ldap/ldap_synchronization.md#global-ldap-group-memberships-lock)が有効になっている場合は、このAPIを使用する必要があります。

### サービスアカウントを削除する {#delete-a-service-account}

サービスアカウントを削除した場合、アカウントによって行われたコントリビュートが保持され、所有権がシステム全体のGhostユーザーアカウントに移転します。これらのコントリビュートには、マージリクエスト、イシュー、プロジェクト、グループなどのアクティビティーが含まれます。

サービスアカウントを削除するには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アカウントを削除**を選択します。
1. サービスアカウントの名前を入力します。
1. **ユーザーを削除**を選択します。

サービスアカウントと、アカウントによって行われたコントリビュートを削除することもできます。これらのコントリビュートには、マージリクエスト、イシュー、グループ、プロジェクトなどのアクティビティーが含まれます。

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アカウントとコントリビュートの削除**を選択します。
1. サービスアカウントの名前を入力します。
1. **ユーザーとコントリビュートを削除**を選択します。

APIを通じてサービスアカウントを削除することもできます。

- インスタンスのサービスアカウントの場合は、[users API](../../api/users.md#delete-a-user)を使用します。
- グループのサービスアカウントの場合は、[サービスアカウントAPI](../../api/service_accounts.md#delete-a-group-service-account)を使用します。

## サービスアカウントのパーソナルアクセストークンの表示と管理 {#view-and-manage-personal-access-tokens-for-a-service-account}

パーソナルアクセストークンページには、トップレベルグループまたはインスタンスのサービスアカウントに関連付けられたパーソナルアクセストークンに関する情報が表示されます。これらのページから、次のことができます:

- パーソナルアクセストークンをフィルタリングしたり、ソートしたり、その詳細を表示したりする。
- パーソナルアクセストークンをローテーションする。
- パーソナルアクセストークンを取り消す。

APIを通じてサービスアカウントのパーソナルアクセストークンを管理することもできます。

- インスタンスのサービスアカウントの場合は、[パーソナルアクセストークンAPI](../../api/personal_access_tokens.md)を使用します。
- グループのサービスアカウントの場合は、[サービスアカウントAPI](../../api/service_accounts.md)を使用します。

サービスアカウントのパーソナルアクセストークンページを表示するには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アクセストークンの管理**を選択します。

### サービスアカウントのパーソナルアクセストークンを作成する {#create-a-personal-access-token-for-a-service-account}

サービスアカウントを使用するには、パーソナルアクセストークンを作成してリクエストを認証する必要があります。

サービスアカウントのパーソナルアクセストークンを作成するには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アクセストークンの管理**を選択します。
1. **新しいトークンを追加**を選択します。
1. **トークン名**に、トークンの名前を入力します。
1. オプション。**トークンの説明**に、トークンの説明を入力します。
1. **有効期限**に、トークンの有効期限を入力します。
   - トークンは、その日付のUTC午前0時に期限切れになります。有効期限が2024-01-01のトークンは、2024-01-01の00:00:00 UTCに期限切れになります。
   - 有効期限を入力しない場合、有効期限は現在の日付より365日後に自動的に設定されます。
   - デフォルトでは、この日付は現在の日付より最大365日後に設定できます。GitLab 17.6以降では、[この制限を400日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)できます。
1. [必要なスコープ](personal_access_tokens.md#personal-access-token-scopes)を選択します。
1. **Create personal access token**（パーソナルアクセストークンを作成）を選択します。

### パーソナルアクセストークンをローテーションする {#rotate-a-personal-access-token}

パーソナルアクセストークンをローテーションして、現在のトークンを無効にし、新しい値を生成できます。

{{< alert type="warning" >}}

これは元に戻せません。ローテーションされたトークンに依存するサービスは動作を停止します。

{{< /alert >}}

サービスアカウントのパーソナルアクセストークンをローテーションするには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アクセストークンの管理**を選択します。
1. アクティブなトークンの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **ローテーション**を選択します。
1. 確認ダイアログで、**ローテーション**を選択します。

### パーソナルアクセストークンを取り消す {#revoke-a-personal-access-token}

パーソナルアクセストークンをローテーションして、現在のトークンを無効にすることができます。

{{< alert type="warning" >}}

これは元に戻せません。取り消されたトークンに依存するサービスは動作を停止します。

{{< /alert >}}

サービスアカウントのパーソナルアクセストークンを取り消すには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アクセストークンの管理**を選択します。
1. アクティブなトークンの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **取り消し**を選択します。
1. 確認ダイアログで、**取り消し**を選択します。

## レート制限 {#rate-limits}

[レート制限](../../security/rate_limits.md)がサービスアカウントに適用されます:

- GitLab.comでは、[GitLab.com固有のレート制限](../gitlab_com/_index.md#rate-limits-on-gitlabcom)が適用されます。
- GitLab Self-ManagedとGitLab Dedicatedでは、次のレート制限が適用されます:
  - [設定可能なレート制限](../../security/rate_limits.md#configurable-limits)。
  - [設定不可のレート制限](../../security/rate_limits.md#non-configurable-limits)。

## 関連トピック {#related-topics}

- [請求対象ユーザー](../../subscriptions/manage_users_and_seats.md#billable-users)
- [関連レコード](account/delete_account.md#associated-records)
- [プロジェクトアクセストークン - ボットユーザー](../project/settings/project_access_tokens.md#bot-users-for-projects)
- [グループアクセストークン - ボットユーザー](../group/settings/group_access_tokens.md#bot-users-for-groups)
- [内部ユーザー](../../administration/internal_users.md)
