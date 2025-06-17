---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サービスアカウント
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

サービスアカウントとは、個々の人間ユーザーに関連付けられていない、マシンユーザーの一種です。

サービスアカウント:

- ライセンスされたシートは使用しません。しかし、GitLab.comの[トライアル版](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com?&glm_content=free-user-limit-faq/ee/user/free_user_limit.html)では利用できません。GitLab Self-Managedのトライアル版で利用できます。
- 以下ではありません。
  - 請求対象ユーザー。
  - ボットユーザー。
- グループメンバーシップにサービスアカウントとしてリストされます。
- UIからGitLabにサインインできません。
- メールアドレスが有効なアドレスに設定されていない限り、通知メールを受信しません。無効なメールアドレスを持つ非人間アカウントであるためです。

人間ユーザーのメンバーシップの変更による影響を受けずに認証情報を設定および保持する必要があるパイプラインまたはインテグレーションでは、サービスアカウントを使用する必要があります。

[パーソナルアクセストークン](personal_access_tokens.md)を使用して、サービスアカウントとして認証できます。パーソナルアクセストークンを持つサービスアカウントユーザーは、標準ユーザーと同じ機能を持っています。これには、[レジストリ](../packages/_index.md)とのやり取りや、[Git操作](personal_access_tokens.md#clone-repository-using-personal-access-token)のためのパーソナルアクセストークンの使用が含まれます。

[レート制限](../../security/rate_limits.md)は、サービスアカウントに適用されます。

- GitLab.comには、[GitLab.com固有のレート制限](../gitlab_com/_index.md#rate-limits-on-gitlabcom)があります。
- GitLab Self-ManagedとGitLab Dedicatedには、次の両方があります。
  - [設定可能なレート制限](../../security/rate_limits.md#configurable-limits)。
  - [設定不可能なレート制限](../../security/rate_limits.md#non-configurable-limits)。

## サービスアカウントを作成する

作成できるサービスアカウントの数は、ライセンスで許可されているサービスアカウントの数によって次のように制限されます。

- GitLab Freeでは、サービスアカウントは利用できません。
- GitLab Premiumでは、お持ちの有料シートごとに1つのサービスアカウントを作成できます。
- GitLab Ultimateでは、無制限の数のサービスアカウントを作成できます。

アカウントの作成方法は、自分が誰であるかによって異なります。

- トップレベルグループのオーナー。
- GitLab Self-Managedでは、管理者。

### トップレベルグループのオーナー

{{< history >}}

- GitLab 16.3でGitLab.com向けに導入されました。
- GitLab Self-Managedの場合、`allow_top_level_group_owners_to_create_service_accounts`という[機能フラグ](../../administration/feature_flags.md)を使用して、GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163726)されました。デフォルトでは無効になっています。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172502)。機能フラグ`allow_top_level_group_owners_to_create_service_accounts`を削除しました。

{{< /history >}}

前提要件:

- トップレベルグループのオーナーのロールを持っている必要があります。
- GitLab Self-ManagedまたはGitLab Dedicatedの場合、トップレベルグループのオーナーは[サービスアカウントの作成を許可](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts)されている必要があります。

1. [サービスアカウントを作成](../../api/group_service_accounts.md#create-a-service-account-user)します。

   このサービスアカウントは、トップレベルグループとのみ関連付けられていますが、特定のグループまたはプロジェクトのメンバーではありません。

1. [すべてのサービスアカウントユーザーをリスト表示](../../api/group_service_accounts.md#list-all-service-account-users)します。

1. サービスアカウントユーザーの[パーソナルアクセストークンを作成](../../api/group_service_accounts.md#create-a-personal-access-token-for-a-service-account-user)します。

   [パーソナルアクセストークンのスコープを設定する](personal_access_tokens.md#personal-access-token-scopes)ことで、サービスアカウントのスコープを定義します。

   （オプション）[有効期限のないパーソナルアクセストークンを作成](personal_access_tokens.md#access-token-expiration)できます。

   レスポンスには、パーソナルアクセストークンの値が含まれます。

1. [サービスアカウントユーザーをグループまたはプロジェクトに手動で追加する](#add-a-service-account-to-subgroup-or-project)ことで、このサービスアカウントをグループまたはプロジェクトのメンバーにします。
1. 返されたパーソナルアクセストークンの値を使用して、サービスアカウントユーザーとして認証します。

### GitLab Self-Managedの管理者

{{< details >}}

- 提供: GitLab Self-Managed

{{< /details >}}

前提要件:

- GitLab Self-Managedインスタンスの管理者である必要があります。

1. [サービスアカウントを作成](../../api/user_service_accounts.md#create-a-service-account-user)します。

   このサービスアカウントは、インスタンス全体に関連付けられていますが、特定のグループまたはプロジェクトのメンバーではありません。

1. [すべてのサービスアカウントユーザーをリスト表示](../../api/user_service_accounts.md#list-all-service-account-users)します。

1. サービスアカウントユーザーの[パーソナルアクセストークンを作成](../../api/user_tokens.md#create-a-personal-access-token-for-a-user)します。

   [パーソナルアクセストークンのスコープを設定する](personal_access_tokens.md#personal-access-token-scopes)ことで、サービスアカウントのスコープを定義します。

   （オプション）[有効期限のないパーソナルアクセストークンを作成](personal_access_tokens.md#access-token-expiration)できます。

   レスポンスには、パーソナルアクセストークンの値が含まれます。

1. [サービスアカウントユーザーをグループまたはプロジェクトに手動で追加する](#add-a-service-account-to-subgroup-or-project)ことで、このサービスアカウントをグループまたはプロジェクトのメンバーにします。
1. 返されたパーソナルアクセストークンの値を使用して、サービスアカウントユーザーとして認証します。

## サブグループまたはプロジェクトへのサービスアカウントを追加する

機能の面では、サービスアカウントは[外部ユーザー](../../administration/external_users.md)と同じです。最初に作成したときは最小限のアクセス権しかありません。

アカウントにアクセスさせたい各[プロジェクト](../project/members/_index.md#add-users-to-a-project)または[グループ](../group/_index.md#add-users-to-a-group)に、サービスアカウントを手動で追加する必要があります。

プロジェクトまたはグループに追加できるサービスアカウントの数に制限はありません。

サービスアカウントは、以下を行えます。

- 同じトップレベルグループの複数のサブグループおよびプロジェクトにわたって、異なるロールを持つことができます。
- トップレベルグループのオーナーによって作成された場合、1つのトップレベルグループにのみ属します。

### サブグループまたはプロジェクトに追加する

次の方法で、サービスアカウントをサブグループまたはプロジェクトに追加できます。

- [API](../../api/members.md#add-a-member-to-a-group-or-project)。
- [グループメンバーUI](../group/_index.md#add-users-to-a-group)。
- [プロジェクトメンバーUI](../project/members/_index.md#add-users-to-a-project)。

### サブグループまたはプロジェクトでサービスアカウントロールを変更する

UIまたはAPIを使用して、サブグループまたはプロジェクトのサービスアカウントロールを変更できます。

UIを使用するには、サブグループまたはプロジェクトのメンバーシップリストに移動し、サービスアカウントのロールを変更します。

APIを使用するには、次のエンドポイントを呼び出します。

```shell
curl --request POST --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>" \ --data "user_id=<service_account_user_id>&access_level=30" "https://gitlab.example.com/api/v4/projects/<project_id>/members"
```

属性の詳細については、[グループまたはプロジェクトのメンバーの編集に関するAPIドキュメント](../../api/members.md#edit-a-member-of-a-group-or-project)を参照してください。

### パーソナルアクセストークンをローテーションする

前提要件:

- トップレベルグループのオーナーによって作成されたサービスアカウントの場合、トップレベルグループのオーナーロールを持っているか、管理者である必要があります。
- 管理者によって作成されたサービスアカウントの場合、GitLab Self-Managedインスタンスの管理者である必要があります。

グループAPIを使用して、サービスアカウントユーザーの[パーソナルアクセストークンをローテーション](../../api/group_service_accounts.md#rotate-a-personal-access-token-for-a-service-account-user)します。

### パーソナルアクセストークンを失効させる

前提要件:

- サービスアカウントユーザーとしてサインインする必要があります。

パーソナルアクセストークンを失効させるには、[パーソナルアクセストークンAPI](../../api/personal_access_tokens.md#revoke-a-personal-access-token)を使用します。次のいずれかの方法を使用できます。

- [パーソナルアクセストークンID](../../api/personal_access_tokens.md#revoke-a-personal-access-token)を使用します。失効の実行に使用されるトークンは、[`admin_mode`](personal_access_tokens.md#personal-access-token-scopes)スコープを持っている必要があります。
- [リクエストヘッダー](../../api/personal_access_tokens.md#self-revoke)を使用します。リクエストの実行に使用されたトークンは失効します。

### サービスアカウントを削除する

#### トップレベルグループのオーナー

前提要件:

- トップレベルグループのオーナーのロールを持っている必要があります。

サービスアカウントを削除するには、[サービスアカウントAPIを使用してサービスアカウントユーザーを削除](../../api/group_service_accounts.md#delete-a-service-account-user)します。

#### GitLab Self-Managedの管理者

{{< details >}}

- 提供: GitLab Self-Managed

{{< /details >}}

前提要件:

- サービスアカウントが関連付けられているインスタンスの管理者である必要があります。

サービスアカウントを削除するには、[ユーザーAPIを使用してサービスアカウントユーザーを削除](../../api/users.md#delete-a-user)します。

### サービスアカウントを無効にする

前提要件:

- サービスアカウントが関連付けられているグループのオーナーロールを持っている必要があります。

サービスアカウントが関連付けられているインスタンスまたはグループの管理者でない場合、そのサービスアカウントを直接削除することはできません。代わりに、次を行えます。

1. すべてのサブグループおよびプロジェクトのメンバーとしてサービスアカウントを次のように削除します。

   ```shell
   curl --request DELETE --header "PRIVATE-TOKEN: <access_token_id>" "https://gitlab.example.com/api/v4/groups/<group_id>/members/<service_account_id>"
   ```

   詳細については、[グループまたはプロジェクトからのメンバーの削除に関するAPIドキュメント](../../api/members.md#remove-a-member-from-a-group-or-project)を参照してください。

## 関連トピック

- [請求対象ユーザー](../../subscriptions/self_managed/_index.md#billable-users)
- [関連レコード](account/delete_account.md#associated-records)
- [プロジェクトアクセストークン - ボットユーザー](../project/settings/project_access_tokens.md#bot-users-for-projects)
- [グループアクセストークン - ボットユーザー](../group/settings/group_access_tokens.md#bot-users-for-groups)
- [内部ユーザー](../../administration/internal_users.md)

## トラブルシューティング

### サービスアカウントの追加時に表示される「You are about to incur additional charges(追加料金が発生する可能性があります)」という警告

サービスアカウントを追加すると、サブスクリプションシート数を超えているためにこの操作によって追加料金が発生するという警告メッセージが表示される場合があります。この動作は、[issue 433141](https://gitlab.com/gitlab-org/gitlab/-/issues/433141)で追跡されています。

サービスアカウントを追加しても、次は発生しません。

- 追加料金。
- アカウントを追加した後、シートの使用数が増加する。
