---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: サービスアカウント
description: 自動化されたプロセスやサードパーティのサービス統合用に、非人間的なアカウントを作成します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- サービスアカウントのFree tier:
  - GitLab 18.10で`service_accounts_available_on_free_or_unlicensed`という名前の[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225913)されました。デフォルトでは無効になっています。
  - GitLab 18.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227910)されました。機能フラグが削除されました。
- プロジェクトサービスアカウントは、GitLab 18.10で[introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/585509)され、`allow_projects_to_create_service_accounts`という名前の[with a flag](../../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- サブグループサービスアカウントは、GitLab 18.10で[introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/585513)され、`allow_subgroups_to_create_service_accounts`という名前の[with a flag](../../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- サブグループとプロジェクトサービスアカウントは、GitLab 18.11で[generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225485/)です。機能フラグ`allow_subgroups_to_create_service_accounts`および`allow_projects_to_create_service_accounts`は削除されました。

{{< /history >}}

サービスアカウントは、個々の人ではなく、人間ではないエンティティを表すユーザーアカウントです。サービスアカウントを使用して、自動化されたアクションを実行したり、データにアクセスしたり、スケジュールされたプロセスを実行したりできます。サービスアカウントは、チームのメンバーシップの変更に関わらず認証情報が安定している必要があるパイプラインやサードパーティの統合でよく使用されます。

サービスアカウントは、[パーソナルアクセストークン](personal_access_tokens.md)で認証するします。これらは[パッケージとコンテナレジストリ](../packages/_index.md)と対話したり、[Gitオペレーション](personal_access_tokens.md#clone-repository-using-personal-access-token)を実行したり、APIにアクセスしたりできます。

サービスアカウントには、次の特徴があります:

- これらはシートを使用しません。
- これらは[請求対象ユーザー](../../subscriptions/manage_seats.md#billable-users)でも[internal users](../../administration/internal_users.md)でもありません。
- これらは常に[external users](../../administration/external_users.md)としてマークされます。
- これらはUIを介してGitLabにサインインできません。
- これらはLDAPなどのサービスを介して管理できません。
- これらは、サブグループやプロジェクトによってプロビジョニングされた場合、トップレベルグループや他のサービスアカウントを作成できません。
- これらは、通常のユーザーとしてではなく、サービスアカウントとしてグループおよびプロジェクトのメンバーシップリストに表示されます。
- [カスタムメールアドレス](../../api/service_accounts.md#create-an-instance-service-account)を追加しない限り、これらは通知メールを受け取りません。
- これらはGitLabの[トライアルバージョン](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com&glm_content=free-user-limit-faq/ee/user/free_user_limit.html)で利用できます。GitLab.comでは、トップレベルグループのオーナーが最初に本人確認を行う必要があります。

[サービスアカウントAPI](../../api/service_accounts.md)を通じてサービスアカウントを管理することもできます。

作成できるサービスアカウントの数は、サブスクリプションとオファリングによって異なります:

- PremiumとUltimateでは、すべてのオファリングで無制限のサービスアカウントを作成できます。
- GitLab Freeでは、オファリングによって制限が異なります:
  - GitLab.comでは、トップレベルグループごとに最大100のサービスアカウントを作成できます。これには、サブグループまたはプロジェクトで作成されたサービスアカウントが含まれます。
  - GitLab Self-Managed Enterprise Edition (EE)では、インスタンス全体で最大100のサービスアカウントを作成できます。
  - GitLab Self-Managed GitLab CEでは、サービスアカウントを作成できません。

## サービスアカウントのタイプ {#types-of-service-accounts}

サービスアカウントには3つのタイプがあり、それぞれ異なるスコープと前提条件があります:

{{< tabs >}}

{{< tab title="インスタンスサービスアカウント" >}}

インスタンスサービスアカウントは、管理者エリアを通じて作成され、インスタンス上の任意のグループまたはプロジェクトに招待できます。

前提条件: 

- インスタンスへの管理者アクセス権。

{{< /tab >}}

{{< tab title="グループのサービスアカウント" >}}

グループサービスアカウントは、特定のグループによって作成され、作成されたグループ、またはその子孫のサブグループやプロジェクトに招待できます。これらはトップレベルグループやサービスアカウントを作成できません。

前提条件: 

- GitLab.comでは、グループのオーナーロールが必要です。
- GitLab Self-ManagedまたはGitLab Dedicatedでは、次のいずれかの条件を満たす必要があります:
  - インスタンスの管理者である。
  - グループでオーナーロールを持ち、[サービスアカウントを作成することを許可](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)されていること。

{{< /tab >}}

{{< tab title="プロジェクトサービスアカウント" >}}

プロジェクトサービスアカウントは、特定のプロジェクトによって作成され、そのプロジェクトでのみ利用できます。これらはトップレベルグループやサービスアカウントを作成できません。

前提条件: 

- GitLab.comでは、プロジェクトのオーナーまたはメンテナーロールが必要です。
- GitLab Self-ManagedまたはGitLab Dedicatedでは、次のいずれかの条件を満たす必要があります:
  - インスタンスの管理者である。
  - プロジェクトでオーナーまたはメンテナーロールを持っていること。

{{< /tab >}}

{{< /tabs >}}

## サービスアカウントの表示と管理 {#view-and-manage-service-accounts}

{{< history >}}

- GitLab 17.11でGitLab.com向けに導入されました。

{{< /history >}}

サービスアカウントページには、グループ、プロジェクト、またはインスタンス内のサービスアカウントに関する情報が表示されます。各グループ、プロジェクト、およびSelf-Managedインスタンスには、個別のサービスアカウントページがあります。これらのページから、次のことができます。

- グループまたはインスタンスのすべてのサービスアカウントを表示する。
- サービスアカウントを削除する
- サービスアカウントの名前またはユーザー名を編集する。
- サービスアカウントのパーソナルアクセストークンを管理する。

{{< tabs >}}

{{< tab title="インスタンスサービスアカウント" >}}

インスタンス全体のサービスアカウントを表示するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **サービスアカウント**を選択します。

{{< /tab >}}

{{< tab title="グループのサービスアカウント" >}}

グループのサービスアカウントを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **サービスアカウント**を選択します。

{{< /tab >}}

{{< tab title="プロジェクトサービスアカウント" >}}

プロジェクトのサービスアカウントを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **サービスアカウント**を選択します。

{{< /tab >}}

{{< /tabs >}}

### サービスアカウントを作成する {#create-a-service-account}

{{< history >}}

- GitLab 16.3でGitLab.com向けに導入されました。
- トップレベルグループのオーナーがサービスアカウントを作成できるようにする機能は、GitLab 17.5で、`allow_top_level_group_owners_to_create_service_accounts`[機能フラグ](../../administration/feature_flags/_index.md)とともに、GitLab Self-Managed向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163726)されました。デフォルトでは無効になっています。
- トップレベルグループのオーナーがサービスアカウントを作成できるようにする機能は、GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172502)になりました。機能フラグ`allow_top_level_group_owners_to_create_service_accounts`は削除されました。

{{< /history >}}

GitLab.comでは、トップレベルグループのOwnersのみがサービスアカウントを作成できます。

デフォルトでは、GitLab Self-ManagedおよびGitLab Dedicatedでは、管理者の管理者のみがどちらのタイプのサービスアカウントも作成できます。ただし、[インスタンスを設定](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)して、トップレベルグループのOwnersがグループサービスアカウントを作成できるようにすることができます。

作成できるサービスアカウントの数は、サブスクリプションとオファリングによって異なります:

- PremiumとUltimateでは、すべてのオファリングで無制限のサービスアカウントを作成できます。
- GitLab Freeでは、オファリングによって制限が異なります:
  - GitLab.comでは、トップレベルグループごとに最大100のサービスアカウントを作成できます。これには、サブグループまたはプロジェクトで作成されたサービスアカウントが含まれます。
  - GitLab Self-Managed Enterprise Edition (EE)では、インスタンス全体で最大100のサービスアカウントを作成できます。
  - GitLab Self-Managed GitLab CEでは、サービスアカウントを作成できません。

サービスアカウントを作成するには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. **サービスアカウントの追加**を選択します。
1. サービスアカウントの名前を入力します。ユーザー名は、名前に基づいて自動的に生成されます。必要に応じて、ユーザー名を変更できます。
1. **サービスアカウントの作成**を選択します。

### サービスアカウントを編集する {#edit-a-service-account}

{{< history >}}

- GitLab 18.9で、複合IDを持つサービスアカウントのユーザー名制限が[追加](https://gitlab.com/gitlab-org/gitlab/-/work_items/581050)されました。

{{< /history >}}

サービスアカウントの名前またはユーザー名を編集できます。

> [!note]
> [複合ID](../duo_agent_platform/composite_identity.md)に関連付けられたサービスアカウントのユーザー名を更新することはできません。

サービスアカウントを編集するには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **編集**を選択します。
1. サービスアカウントの名前またはユーザー名を編集します。
1. **変更を保存**を選択します。

### グループまたはプロジェクトにサービスアカウントを追加する {#add-a-service-account-to-a-group-or-project}

サービスアカウントは、グループまたはプロジェクトのメンバーとして追加するまでアクセスが制限されます。任意の数のサービスアカウントをグループまたはプロジェクトに追加でき、各サービスアカウントは、各グループ、サブグループ、またはプロジェクトで異なるロールを持つことができます。

サービスアカウントのアクセスは、サービスアカウントのタイプによって異なります:

- インスタンスサービスアカウント: インスタンス上の任意のグループまたはプロジェクトに招待できます。
- グループサービスアカウント: 作成されたグループ、またはその子孫のサブグループやプロジェクトに招待できます。
- プロジェクトサービスアカウント: 作成されたプロジェクトのみに招待できます。

グループが[別のグループと共有](../project/members/sharing_projects_groups.md#invite-a-group-to-a-group)されると、サービスアカウントを含むそのグループのすべてのメンバーが共有グループにアクセスできます。

サービスアカウントをグループとプロジェクトに割り当てるには、次の方法を使用します:

- GitLab UI:
  - [ユーザーをグループに追加](../group/_index.md#add-users-to-a-group)。
  - [ユーザーをプロジェクトに追加](../project/members/_index.md#add-users-to-a-project)。
- API:
  - [グループメンバーAPI](../../api/group_members.md)。
  - [プロジェクトメンバーAPI](../../api/project_members.md)。

> [!note]
> [グローバルSAMLグループメンバーシップロック](../group/saml_sso/group_sync.md#global-saml-group-memberships-lock)または[グローバルLDAPグループメンバーシップロック](../../administration/auth/ldap/ldap_synchronization.md#global-ldap-group-memberships-lock)の設定が有効になっている場合、サービスアカウントのメンバーシップを制御するにはAPIを使用する必要があります。

## サービスアカウントでプロジェクトをフォークする {#fork-projects-with-a-service-account}

サービスアカウントは、[プロジェクトフォークAPI](../../api/project_forks.md)を通じてプロジェクトをフォークすることができますが、個人のネームスペースにフォークすることはできません。サービスアカウントでフォークする場合、ターゲットグループのネームスペースを指定する必要があります。

前提条件: 

- サービスアカウントにはデベロッパーロールがあり、ターゲットグループのメンバーです。
- サービスアカウントのパーソナルアクセストークンに対して`api`スコープがオンになっています。

サービスアカウントを使用してプロジェクトをフォークするには:

1. フォークが作成されるターゲットグループを特定します。
1. サービスアカウントが適切な権限を持つそのグループのメンバーであることを確認します。
1. `namespace_id`または`namespace_path`のいずれかを使用して、[プロジェクトフォークAPI](../../api/project_forks.md)を使用します:

   ```shell
    curl --request POST --header "PRIVATE-TOKEN: <service_account_token>" \
      --data "namespace_path=target-group" \
      "https://gitlab.example.com/api/v4/projects/<project_id>/fork"
   ```

### サービスアカウントを削除する {#delete-a-service-account}

サービスアカウントを削除すると、そのアカウントによる貢献は保持され、所有権はゴーストユーザーに転送されます。これらのコントリビュートには、マージリクエスト、イシュー、プロジェクト、グループなどのアクティビティが含まれます。

サービスアカウントを削除するには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アカウントの削除**を選択します。
1. サービスアカウントの名前を入力します。
1. **ユーザーを削除**を選択します。

サービスアカウントと、アカウントによって行われたコントリビュートを削除することもできます。これらのコントリビュートには、マージリクエスト、イシュー、グループ、プロジェクトなどのアクティビティが含まれます。

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アカウントとコントリビュートの削除**を選択します。
1. サービスアカウントの名前を入力します。
1. **ユーザーとコントリビュートを削除**を選択します。

APIを通じてサービスアカウントを削除することもできます。

- インスタンスサービスアカウントの場合は、[ユーザーAPI](../../api/users.md#delete-a-user)を使用します。
- グループサービスアカウントの場合は、[サービスアカウントAPI](../../api/service_accounts.md#delete-a-group-service-account)を使用します。

## サービスアカウントのパーソナルアクセストークンの表示と管理 {#view-and-manage-personal-access-tokens-for-a-service-account}

パーソナルアクセストークンページには、トップレベルグループまたはインスタンスのサービスアカウントに関連付けられたパーソナルアクセストークンに関する情報が表示されます。これらのページから、次のことができます。

- パーソナルアクセストークンをフィルタリングしたり、ソートしたり、その詳細を表示したりする。
- パーソナルアクセストークンをローテーションする。
- パーソナルアクセストークンを取り消す。

APIを通じてサービスアカウントのパーソナルアクセストークンを管理することもできます。

- インスタンスサービスアカウントの場合は、[パーソナルアクセストークンAPI](../../api/personal_access_tokens.md)を使用します。
- グループサービスアカウントの場合は、[サービスアカウントAPI](../../api/service_accounts.md)を使用します。

サービスアカウントのパーソナルアクセストークンページを表示するには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アクセストークンを管理**を選択します。

### サービスアカウントのパーソナルアクセストークンを作成する {#create-a-personal-access-token-for-a-service-account}

サービスアカウントを使用するには、パーソナルアクセストークンを作成してリクエストを認証する必要があります。

サービスアカウントのパーソナルアクセストークンを作成するには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アクセストークンを管理**を選択します。
1. **新しいトークンを追加**を選択します。
1. **トークン名**に、トークンの名前を入力します。
1. オプション。**トークンの説明**に、トークンの説明を入力します。
1. **有効期限**に、トークンの有効期限を入力します。
   - トークンは、その日付のUTC午前0時に期限切れになります。有効期限が2024-01-01のトークンは、2024-01-01の00:00:00 UTCに期限切れになります。
   - 有効期限を入力しない場合、有効期限は現在の日付より365日後に自動的に設定されます。
   - デフォルトでは、この日付は現在の日付より最大365日後に設定できます。GitLab 17.6以降では、[この制限を400日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)できます。
1. [必要なスコープ](personal_access_tokens.md#personal-access-token-scopes)を選択します。
1. **パーソナルアクセストークンを作成**を選択します。

### パーソナルアクセストークンをローテーションする {#rotate-a-personal-access-token}

パーソナルアクセストークンをローテーションして、現在のトークンを無効にし、新しい値を生成できます。

> [!warning]
> これは元に戻せません。回転されたトークンに依存するサービスは動作を停止します。

サービスアカウントのパーソナルアクセストークンをローテーションするには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アクセストークンを管理**を選択します。
1. アクティブなトークンの横にある縦方向の省略記号 ({{< icon name="ellipsis_v" >}}) を選択します。
1. **ローテーション**を選択します。
1. 確認ダイアログで、**ローテーション**を選択します。

### パーソナルアクセストークンを取り消す {#revoke-a-personal-access-token}

パーソナルアクセストークンをローテーションして、現在のトークンを無効にすることができます。

> [!warning]
> これは元に戻せません。失効されたトークンに依存するサービスは動作を停止します。

サービスアカウントのパーソナルアクセストークンを取り消すには:

1. [サービスアカウント](#view-and-manage-service-accounts)ページに移動します。
1. サービスアカウントを特定します。
1. 縦方向の省略記号（{{< icon name="ellipsis_v" >}}） > **アクセストークンを管理**を選択します。
1. アクティブなトークンの横にある縦方向の省略記号 ({{< icon name="ellipsis_v" >}}) を選択します。
1. **取り消し**を選択します。
1. 確認ダイアログで、**取り消し**を選択します。

## レート制限 {#rate-limits}

[レート制限](../../security/rate_limits.md)がサービスアカウントに適用されます。

- GitLab.comでは、[GitLab.com固有のレート制限](../gitlab_com/_index.md#rate-limits-on-gitlabcom)が適用されます。
- GitLab Self-ManagedとGitLab Dedicatedでは、次のレート制限が適用されます。
  - [設定可能なレート制限](../../security/rate_limits.md#configurable-limits)
  - [設定不可能なレート制限](../../security/rate_limits.md#non-configurable-limits)

## 関連トピック {#related-topics}

- [請求対象ユーザー](../../subscriptions/manage_seats.md#billable-users)
- [関連レコード](account/delete_account.md#associated-records)
- [プロジェクトアクセストークン - ボットユーザー](../project/settings/project_access_tokens.md#bot-users-for-projects)
- [グループアクセストークン - ボットユーザー](../group/settings/group_access_tokens.md#bot-users-for-groups)
- [内部ユーザー](../../administration/internal_users.md)
