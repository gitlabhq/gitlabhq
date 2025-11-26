---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトアクセストークン
description: 認証、作成、失効、トークンの有効期限。
---

{{< details >}}

プラン: Premium、Ultimate提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1のトライアルサブスクリプションで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386041)されました。

{{< /history >}}

プロジェクトアクセストークンはパスワードと似ていますが、リソースへのアクセスを制限したり、制限付きのロールを選択したり、有効期限を設定したりできます。

{{< alert type="note" >}}

特定のプロジェクトへのアクセスは、[ロールと権限](../../permissions.md)、およびトークンスコープの組み合わせによって制御されます。

{{< /alert >}}

プロジェクトアクセストークンを使用して認証するには:

- GitLab APIを使用して認証します。
- Gitを使用します。HTTP基本認証を使う場合は次のようにします:
  - 任意の空白でない値をユーザー名として使用します。
  - パスワードとしてプロジェクトアクセストークンを使用します。

{{< alert type="note" >}}

GitLab SaaSでは、PremiumまたはUltimateのサブスクリプションでプロジェクトアクセストークンを使用できます。[トライアルライセンス](https://about.gitlab.com/free-trial/)をお持ちの場合、プロジェクトアクセストークンを1つ作成することもできます。

GitLab Self-Managedインスタンスでは、どのサブスクリプションでもプロジェクトアクセストークンを使用できます。Freeプランをお使いの場合は、悪用の可能性を減らすために、[プロジェクトアクセストークンの作成を制限](#restrict-the-creation-of-project-access-tokens)できます。

{{< /alert >}}

プロジェクトアクセストークンは、グループアクセストークンおよびパーソナルアクセストークンと似ていますが、関連付けられたプロジェクトにのみスコープが設定されています。プロジェクトアクセストークンを使用して、他のプロジェクトに属するリソースにアクセスすることはできません。

GitLab Self-Managedインスタンスでは、プロジェクトアクセストークンには、制限が設定されている場合、パーソナルアクセストークンと同じライフタイム制限が適用されます。

プロジェクトアクセストークンを使用して、他のグループ、プロジェクト、またはパーソナルアクセストークンを作成することはできません。

プロジェクトアクセストークンは、パーソナルアクセストークンに設定されている[デフォルトのプレフィックス設定](../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)を継承します。

## プロジェクトアクセストークンを作成する {#create-a-project-access-token}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89114)され、オーナーがプロジェクトアクセストークンのオーナーロールを選択できます。
- GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348660)され、UIにはデフォルトの有効期限（30日）とデフォルトロール（ゲスト）が入力されています。
- 有効期限のないプロジェクトアクセストークンを作成する機能は、GitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/392855)されました。
- GitLab 17.6で、`buffered_token_expiration_limit`[フラグ](../../../administration/feature_flags/_index.md)とともに、最大許容ライフタイム制限が[400日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)されました。デフォルトでは無効になっています。
- プロジェクトアクセストークンの説明は、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)されました。

{{< /history >}}

{{< alert type="flag" >}}

拡張された最大許容ライフタイム制限の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

{{< alert type="warning" >}}

有効期限のないプロジェクトアクセストークンを作成する機能は、GitLab 15.4で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/369122)となり、GitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/392855)されました。既存のトークンに追加された有効期限の詳細については、[アクセストークンの有効期限](#access-token-expiration)に関するドキュメントを参照してください。

{{< /alert >}}

プロジェクトアクセストークンを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **アクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. **トークン名**に名前を入力します。トークン名は、プロジェクトを表示する権限を持つすべてのユーザーに表示されます。
1. オプション。**トークンの説明**に、トークンの説明を入力します。
1. **有効期限**に、トークンの有効期限を入力します。
   - トークンは、その日付のUTC午前0時に期限切れになります。有効期限が2024-01-01のトークンは、2024-01-01の00:00:00 UTCに期限切れになります。
   - 有効期限を入力しない場合、有効期限は現在の日付より30日後に自動的に設定されます。
   - デフォルトでは、この日付は現在の日付より最大365日後に設定できます。GitLab 17.6以降では、この制限を400日に延長できます。
   - インスタンス全体のライフタイム設定により、GitLab Self-Managedインスタンスで許可される最大ライフタイムが制限される場合があります。
1. トークンのロールを選択します。
1. 必要なスコープを選択します。
1. **Create project access token**（プロジェクトアクセストークンを作成）を選択します。

プロジェクトアクセストークンが表示されます。プロジェクトアクセストークンを安全な場所に保存します。ページから離れたり、ページを更新したりすると、再度表示することはできません。

{{< alert type="warning" >}}

プロジェクトアクセストークンは内部ユーザーとして扱われます。内部ユーザーがプロジェクトアクセストークンを作成した場合、そのトークンは、表示レベルが内部に設定されているすべてのプロジェクトにアクセスできます。

{{< /alert >}}

## プロジェクトアクセストークンを失効させる、またはローテーションする {#revoke-or-rotate-a-project-access-token}

{{< history >}}

- 期限切れおよび失効したトークンを表示する機能は、GitLab 17.3で`retain_resource_access_token_user_after_revoke`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)されました。デフォルトでは無効になっています。
- 期限切れおよび失効したトークンを表示する機能は、自動的に削除されるまで、GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/471683)されます。機能フラグ`retain_resource_access_token_user_after_revoke`は削除されました。

{{< /history >}}

GitLab 17.9以降、アクティブおよび非アクティブのプロジェクトアクセストークンの両方をアクセストークンページで表示できるようになります。

非アクティブなプロジェクトアクセストークンテーブルには、失効および期限切れのトークンが[自動的に削除](#inactive-token-retention)されるまで表示されます。

プロジェクトアクセストークンを失効させる、またはローテーションするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **アクセストークン**を選択します。
1. 関連するトークンについて、**取り消し**（{{< icon name="remove" >}}）または**ローテーション**（{{< icon name="retry" >}}）を選択します。
1. 確認ダイアログで、**取り消し**または**ローテーション**を選択します。

## プロジェクトアクセストークンのスコープ {#scopes-for-a-project-access-token}

{{< history >}}

- `k8s_proxy`は、GitLab 16.4で`k8s_proxy_pat`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422408)されました。デフォルトでは有効になっています。
- 機能フラグ`k8s_proxy_pat`は、GitLab 16.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518)されました。
- `self_rotate`は、GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111)されました。デフォルトでは有効になっています。

{{< /history >}}

スコープは、プロジェクトアクセストークンで認証するときに実行できるアクションを決定します。

{{< alert type="note" >}}

[プロジェクトアクセストークンの作成](#create-a-project-access-token)の内部プロジェクトに関する警告を参照してください。

{{< /alert >}}

| スコープ              | 説明                                                                                                                                                                                                                                                                              |
|:-------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`              | スコープ付きプロジェクトAPIへの完全な読み取り/書き込みアクセスを許可します（[コンテナレジストリ](../../packages/container_registry/_index.md) 、[依存プロキシ](../../packages/dependency_proxy/_index.md) 、[パッケージレジストリ](../../packages/package_registry/_index.md)を含む）。 |
| `read_api`         | [パッケージレジストリ](../../packages/package_registry/_index.md)を含む、スコープ付きプロジェクトAPIへの読み取りアクセスを許可します。                                                                                                                                                                |
| `read_registry`    | プロジェクトがプライベートかつ認証が必要な場合、[コンテナレジストリ](../../packages/container_registry/_index.md)イメージへの読み取りアクセス（プル）を許可します。                                                                                                                          |
| `write_registry`   | [コンテナレジストリ](../../packages/container_registry/_index.md)への書き込みアクセス（プッシュ）を許可します。イメージをプッシュするには、読み取りと書き込みの両方のアクセス権が必要です。                                                                                                                              |
| `read_repository`  | リポジトリへの読み取りアクセス（プル）を許可します。                                                                                                                                                                                                                                             |
| `write_repository` | リポジトリへの読み取りおよび書き込みアクセス（プルおよびプッシュ）を許可します。                                                                                                                                                                                                                          |
| `create_runner`    | プロジェクトでRunnerを作成する権限を付与します。                                                                                                                                                                                                                                      |
| `manage_runner`    | プロジェクトでRunnerを管理する権限を付与します。                                                                                                                                                                                                                                      |
| `ai_features`      | GitLab DuoでAPIアクションを実行する権限を付与します。このスコープは、JetBrains用のGitLab Duoプラグインと連携するように設計されています。その他のすべての拡張機能については、スコープの要件を参照してください。                                                                                                          |
| `k8s_proxy`        | プロジェクトでKubernetesのエージェントを使用してKubernetes APIコールを実行する権限を付与します。                                                                                                                                                                                         |
| `self_rotate`      | [パーソナルアクセストークンAPI](../../../api/personal_access_tokens.md#rotate-a-personal-access-token)を使用して、このトークンをローテーションする権限を付与します。他のトークンのローテーションは許可しません。 |

## プロジェクトアクセストークンの作成を制限する {#restrict-the-creation-of-project-access-tokens}

潜在的な不正利用を制限するために、ユーザーがグループ階層のトークンを作成できないように制限できます。この設定は、トップレベルグループに対してのみ構成可能であり、すべてのダウンストリームプロジェクトおよびサブグループに適用されます。既存のプロジェクトアクセストークンは、有効期限が切れるまで、または手動で失効させるまで有効です。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **権限**で、**Users can create project access tokens and group access tokens in this group**（ユーザーはこのグループでプロジェクトアクセストークンとグループアクセストークンを作成できます）チェックボックスをオフにします。

## アクセストークンの有効期限 {#access-token-expiration}

既存のプロジェクトアクセストークンに有効期限が自動的に適用されるかどうかは、お使いのGitLabの提供形態と、GitLab 16.0以降にアップグレードした時期によって異なります:

- GitLab.comでは、16.0マイルストーン期間中に、有効期限のない既存のプロジェクトアクセストークンには、現在の日付より365日後の有効期限日が自動的に付与されました。
- GitLab Self-Managedで、GitLab 15.11以前からGitLab 16.0以降にアップグレードした場合:
  - 2024年7月23日以前は、有効期限のない既存のプロジェクトアクセストークンには、現在の日付より365日後の有効期限日が自動的に付与されました。これは破壊的な変更です。
  - 2024年7月24日以降は、有効期限のない既存のプロジェクトアクセストークンには、有効期限日が設定されていませんでした。

GitLab Self-Managedで、次のいずれかのGitLabバージョンを新規インストールした場合、既存のプロジェクトアクセストークンに有効期限が自動的に適用されることはありません:

- 16.0.9
- 16.1.7
- 16.2.10
- 16.3.8
- 16.4.6
- 16.5.9
- 16.6.9
- 16.7.9
- 16.8.9
- 16.9.10
- 16.10.9
- 16.11.7
- 17.0.5
- 17.1.3
- 17.2.1

### プロジェクトアクセストークンの有効期限に関するメール {#project-access-token-expiry-emails}

{{< history >}}

- 60日前と30日前の有効期限通知は、GitLab 17.6で`expiring_pats_30d_60d_notifications`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)されました。デフォルトでは無効になっています。
- 60日前と30日前の通知は、GitLab 17.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792)になりました。機能フラグ`expiring_pats_30d_60d_notifications`は削除されました。
- 継承されたグループメンバーへの通知は、GitLab 17.7で`pat_expiry_inherited_members_notification`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)されました。デフォルトでは無効になっています。
- 機能フラグ`pat_expiry_inherited_members_notification`は、GitLab 17.10でデフォルトで[有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)。
- 機能フラグ`pat_expiry_inherited_members_notification`は、GitLab `17.11`で削除されました。

{{< /history >}}

GitLabは、UTC午前1時00分にチェックを毎日実行して、近い将来に有効期限が切れるプロジェクトアクセストークンを特定します。少なくともメンテナーロールを持つプロジェクトのメンバーには、これらのトークンが特定の日数で期限切れになるとメールで通知されます。日数はGitLabのバージョンによって異なります:

- GitLab 176以降では、プロジェクトメンテナーおよびオーナーは、チェックによりプロジェクトアクセストークンが今後60日以内に期限切れになることが確認された場合に、メールで通知を受け取ります。プロジェクトアクセストークンが今後30日以内に期限切れになることが確認された場合、追加のメールを受け取ります。
- プロジェクトメンテナーおよびオーナーは、チェックによりプロジェクトアクセストークンが今後60日以内に期限切れになることが確認された場合に、メールで通知を受け取ります。
- GitLab 17.7以降では、プロジェクトがグループに属しているためにオーナーまたはメンテナーロールを継承したプロジェクトメンバーも、通知メールを受け取ることができます。これは、以下を変更することで有効にできます:
  - プロジェクトの親グループのいずれかの[グループ設定](../../group/manage.md#expiry-emails-for-group-and-project-access-tokens)。
  - GitLab Self-Managedでは、[インスタンス設定](../../../administration/settings/email.md#group-and-project-access-token-expiry-emails-to-inherited-members)。

期限切れのアクセストークンは、[非アクティブなプロジェクトアクセストークンテーブル](#revoke-or-rotate-a-project-access-token)に、[自動的に削除](#inactive-token-retention)されるまで表示されます。

## プロジェクトのボットユーザー {#bot-users-for-projects}

{{< history >}}

- GitLab 17.2で`retain_resource_access_token_user_after_revoke`[フラグ](../../../administration/feature_flags/_index.md)とともに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)されました。デフォルトでは無効になっています。有効にすると、新しいボットユーザーは有効期限なしでメンバーになり、トークンが後で失効させられたり、または期限切れになった場合も、ボットユーザーは30日間保持されます。
- 非アクティブなボットユーザーの保持は、GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)になりました。機能フラグ`retain_resource_access_token_user_after_revoke`は削除されました。

{{< /history >}}

プロジェクトのボットユーザーは、[GitLabが作成した請求対象外のユーザー](../../../subscriptions/manage_users_and_seats.md#criteria-for-non-billable-users)です。プロジェクトアクセストークンを作成するたびに、ボットユーザーが作成され、プロジェクトに追加されます。このユーザーは、請求対象ユーザーではないため、ライセンス制限にはカウントされません。

プロジェクトのボットユーザーには、プロジェクトアクセストークンの選択されたロールと[スコープ](#scopes-for-a-project-access-token)に対応する[権限](../../permissions.md#project-members-permissions)が付与されます。

- 名前はトークンの名前に設定されます。
- ユーザー名は`project_{project_id}_bot_{random_string}`に設定されます。たとえば、`project_123_bot_4ffca233d8298ea1`などです。
- メールは`project_{project_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}`に設定されます。たとえば、`project_123_bot_4ffca233d8298ea1@noreply.example.com`などです。

プロジェクトアクセストークンを使用して行われたAPIコールは、対応するボットユーザーに関連付けられます。

プロジェクトのボットユーザー:

- プロジェクトのメンバーリストに含まれていますが、変更することはできません。
- 他のプロジェクトに追加することはできません。
- プロジェクトの最大ロールはオーナーにすることができます。詳細については、[プロジェクトアクセストークンを作成する](../../../api/project_access_tokens.md#create-a-project-access-token)を参照してください。

プロジェクトアクセストークンが[失効](#revoke-or-rotate-a-project-access-token)すると:

- [非アクティブなトークンの保持](#inactive-token-retention)に準拠して、ボットユーザーが保持されます。
- 30日後、ボットユーザーは削除されます。すべてのレコードは、システム全体のユーザー名が[Ghostユーザー](../../profile/account/delete_account.md#associated-records)のユーザーに移動されます。

詳しくは、[グループのボットユーザー](../../group/settings/group_access_tokens.md#bot-users-for-groups)をご覧ください。

## 非アクティブなトークンの保持 {#inactive-token-retention}

デフォルトでは、GitLabは、グループとプロジェクトアクセストークン、およびそれらの[トークンファミリー](../../../api/personal_access_tokens.md#automatic-reuse-detection)を、トークンファミリーからの最後のアクティブなトークンが非アクティブになってから30日後に削除します。これにより、トークンファミリー内のすべてのトークンと、関連付けられたボットユーザーが削除され、ボットユーザーのコントリビューションがシステム全体の「Ghostユーザー」に移行されます。

非アクティブなトークンの保持期間を変更するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **非アクティブなプロジェクトやグループアクセストークンの保持期間**テキストボックスで、保持期間を変更します。
   - 数値が定義されている場合、すべてのグループとプロジェクトアクセストークンは、指定された日数だけ非アクティブになった後に削除されます。
   - フィールドが空白の場合、非アクティブなトークンは削除されません。
1. **変更を保存**を選択します。

[アプリケーション設定API](../../../api/settings.md)を使用して、`inactive_resource_access_tokens_delete_after_days`属性を変更することもできます。

## トークンの可用性 {#token-availability}

複数のプロジェクトアクセストークンは、有料のサブスクリプションでのみ利用可能です。PremiumとUltimateトライアルサブスクリプションの場合、含まれるプロジェクトアクセストークンは1つのみです。詳しくは、GitLabトライアルFAQの[「何が含まれていますか」セクション](https://about.gitlab.com/free-trial/#what-is-included-in-my-free-trial-what-is-excluded)をご覧ください。

## 関連トピック {#related-topics}

- [パーソナルアクセストークン](../../profile/personal_access_tokens.md)
- [グループアクセストークン](../../group/settings/group_access_tokens.md)
- [プロジェクトアクセストークンAPI](../../../api/project_access_tokens.md)
