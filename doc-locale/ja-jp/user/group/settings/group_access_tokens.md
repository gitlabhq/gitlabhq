---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループアクセストークン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループアクセストークンを使用すると、単一のトークンで次の操作を実行できます:

- グループのアクションを実行する。
- グループ内のプロジェクトを管理する。

グループアクセストークンを使用すると、次の認証が可能です:

- GitLab APIで認証します。
- HTTPS経由のGitで認証。この場合、次のようにします:

  - 任意の空白以外の値をユーザー名として使用します。
  - グループアクセストークンをパスワードとして使用します。

グループアクセストークンは[プロジェクトアクセストークン](../../project/settings/project_access_tokens.md)および[パーソナルアクセストークン](../../profile/personal_access_tokens.md)に似ていますが、プロジェクトまたはユーザーではなくグループに関連付けられている点が異なります。

グループアクセストークンを使用して、他のグループ、プロジェクト、またはパーソナルアクセストークンを作成することはできません。

グループアクセストークンは、パーソナルアクセストークンに設定された[デフォルトのプレフィックス設定](../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)を継承します。

## 可用性 {#availability}

- GitLab.comでは、PremiumまたはUltimateプランをお持ちの場合、グループアクセストークンを使用できます。トライアルライセンスでは使用できません。
- GitLab DedicatedおよびGitLab Self-Managedインスタンスのみ:
  - どのライセンス層でもグループアクセストークンを使用できます。Freeプランをお持ちの場合は、次のとおりです:
    - ユーザーのセルフ登録に関するセキュリティおよびコンプライアンス関連のポリシーを確認します。
    - 不正使用のリスクを軽減するために、グループアクセストークンの作成を制限することを検討してください。
  - GitLab Self-Managedインスタンスでは、制限が設定されている場合、グループアクセストークンはパーソナルアクセストークンと同じ[最大ライフタイム制限](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)の対象となります。

## グループアクセストークンの作成 {#create-a-group-access-token}

{{< history >}}

- GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348660)され、UIには、デフォルトの有効期限（30日）とデフォルトロール（ゲスト）が入力されています。
- 有効期限のないグループアクセストークンを作成する機能は、GitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/392855)されました。
- GitLab 17.6で、`buffered_token_expiration_limit`[フラグ](../../../administration/feature_flags/_index.md)とともに、最大許容ライフタイム制限が[400日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)されました。デフォルトでは無効になっています。
- グループアクセストークンの説明は、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)されました。

{{< /history >}}

{{< alert type="flag" >}}

拡張された最大許容ライフタイム制限の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

{{< alert type="warning" >}}

有効期限のないグループアクセストークンを作成する機能は、GitLab 15.4で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/369122)となり、GitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/392855)されました。既存のトークンに追加された有効期限の詳細については、[アクセストークンの有効期限](#access-token-expiration)に関するドキュメントを参照してください。

{{< /alert >}}

### UIを使用する場合 {#with-the-ui}

グループアクセストークンを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **アクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. **トークン名**に、名前を入力します。トークン名は、グループを表示する権限を持つすべてのユーザーに表示されます。
1. オプション。**トークンの説明**に、トークンの説明を入力します。
1. **有効期限**に、トークンの有効期限を入力します:
   - トークンは、その日付のUTC午前0時に有効期限切れになります。有効期限が2024-01-01のトークンは、2024-01-01の00:00:00 UTCに期限切れになります。
   - 有効期限を入力しない場合、有効期限は現在の日付より365日後に自動的に設定されます。
   - デフォルトでは、この日付は現在の日付より最大365日後に設定できます。GitLab 17.6以降では、この制限を400日に延長できます。

   - インスタンス全体の最大ライフタイム設定により、GitLab Self-Managedインスタンスで許可される最大ライフタイムが制限される場合があります。
1. トークンのロールを選択します。
1. 必要なスコープを選択します。
1. **Create group access token**（グループアクセストークンを作成）を選択します。

グループアクセストークンが表示されます。グループアクセストークンを安全な場所に保存します。ページから離れたり、ページを更新したりすると、再度表示することはできません。

{{< alert type="warning" >}}

グループアクセストークンは内部ユーザーとして扱われます。内部ユーザーがグループアクセストークンを作成した場合、そのトークンは表示レベルが内部に設定されているすべてのプロジェクトにアクセスできます。

{{< /alert >}}

### Railsコンソールを使用 {#with-the-rails-console}

管理者の場合は、Railsコンソールでグループアクセストークンを作成できます:

1. [Railsコンソール](../../../administration/operations/rails_console.md)で次のコマンドを実行します:

   ```ruby
   # Set the GitLab administration user to use. If user ID 1 is not available or is not an administrator, use 'admin = User.admins.first' instead to select an administrator.
   admin = User.find(1)

   # Set the group you want to create a token for. For example, group with ID 109.
   group = Group.find(109)

   # Create the group bot user. For further group access tokens, the username should be `group_{group_id}_bot_{random_string}` and email address `group_{group_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}`.
   random_string = SecureRandom.hex(16)
   service_response = Users::CreateService.new(admin, { name: 'group_token', username: "group_#{group.id}_bot_#{random_string}", email: "group_#{group.id}_bot_#{random_string}@noreply.#{Gitlab.config.gitlab.host}", user_type: :project_bot }).execute
   bot = service_response.payload[:user] if service_response.success?

   # Confirm the group bot.
   bot.confirm

   # Add the bot to the group with the required role.
   group.add_member(bot, :maintainer)

   # Give the bot a personal access token.
   token = bot.personal_access_tokens.create(scopes:[:api, :write_repository], name: 'group_token')

   # Get the token value.
   gtoken = token.token
   ```

1. 生成されたグループアクセストークンが動作するかテストします:

   1. GitLab REST APIで、`PRIVATE-TOKEN`ヘッダーでグループアクセストークンを使用します。次に例を示します:

      - グループに[エピックを作成](../../../api/epics.md#new-epic)します。
      - グループのプロジェクトの1つに[プロジェクトパイプラインを作成](../../../api/pipelines.md#create-a-new-pipeline)します。
      - グループのプロジェクトの1つに[イシューを作成](../../../api/issues.md#new-issue)します。

   1. グループトークンを使用して、HTTPSを使って[グループのプロジェクトを複製](../../../topics/git/clone.md#clone-with-https)します。

## グループアクセストークンの失効またはローテーション {#revoke-or-rotate-a-group-access-token}

{{< history >}}

- 期限切れおよび失効したトークンを表示する機能は、GitLab 17.3で`retain_resource_access_token_user_after_revoke`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)されました。デフォルトでは無効になっています。
- 期限切れおよび失効したトークンを表示する機能は、自動的に削除されるまで、GitLab 17.9で[一般的に利用可能](https://gitlab.com/gitlab-org/gitlab/-/issues/471683)です。機能フラグ`retain_resource_access_token_user_after_revoke`は削除されました。

{{< /history >}}

GitLab 17.9以降では、アクティブおよび非アクティブなグループアクセストークンをアクセストークンページで表示できます。

非アクティブなグループアクセストークンテーブルには、[自動的に削除される](../../project/settings/project_access_tokens.md#inactive-token-retention)まで、失効および期限切れのトークンが表示されます。

グループアクセストークンを取り消したりローテーションしたりするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **アクセストークン**を選択します。
1. 関連するトークンについて、**取り消し**（{{< icon name="remove" >}}）または**ローテーション**（{{< icon name="retry" >}}）を選択します。
1. 確認ダイアログで、**取り消し**または**ローテーション**を選択します。

## グループアクセストークンのスコープ {#scopes-for-a-group-access-token}

{{< history >}}

- `k8s_proxy`は、GitLab 16.4で`k8s_proxy_pat`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422408)されました。デフォルトでは有効になっています。
- 機能フラグ`k8s_proxy_pat`は、GitLab 16.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518)されました。
- `self_rotate`は、GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111)されました。デフォルトでは有効になっています。

{{< /history >}}

スコープは、グループアクセストークンで認証するときに実行できるアクションを決定します。

| スコープ              | 説明                                                                                                                                                                                                                                                                                                |
|:-------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`              | スコープ付きグループおよび関連するプロジェクトAPIへの完全な読み取り/書き込みアクセスを許可します（[コンテナレジストリ](../../packages/container_registry/_index.md) 、[依存プロキシ](../../packages/dependency_proxy/_index.md) 、[パッケージレジストリ](../../packages/package_registry/_index.md)を含む）。 |
| `read_api`         | [パッケージレジストリ](../../packages/package_registry/_index.md)を含む、スコープ付きグループおよび関連プロジェクトAPIへの読み取りアクセスを許可します。                                                                                                                                                                |
| `read_registry`    | グループ内のいずれかのプロジェクトが非公開で認証が必要な場合、[コンテナレジストリ](../../packages/container_registry/_index.md)イメージへの読み取りアクセスを許可します。                                                                                                                           |
| `write_registry`   | [コンテナレジストリ](../../packages/container_registry/_index.md)への書き込みアクセスを許可します。イメージをプッシュするには、読み取りと書き込みの両方のアクセス権が必要です。                                                                                                                                                |
| `read_virtual_registry`  | プロジェクトがプライベートで、認証が必要な場合は、[依存プロキシ](../../packages/dependency_proxy/_index.md)を介して、コンテナイメージへの読み取り専用アクセス権を付与します。依存プロキシが有効になっている場合にのみ使用できます。 |
| `write_virtual_registry` | プロジェクトがプライベートで、認証が必要な場合は、[依存プロキシ](../../packages/dependency_proxy/_index.md)を介して、コンテナイメージへの読み取り、書き込み（プッシュ）、および削除アクセス権を付与します。依存プロキシが有効になっている場合にのみ使用できます。 |
| `read_repository`  | グループ内のすべてのリポジトリへの読み取りアクセス（プル）を許可します。                                                                                                                                                                                                                                              |
| `write_repository` | グループ内のすべてのリポジトリへの読み取り/書き込みアクセス（プル/プッシュ）を許可します。                                                                                                                                                                                                                           |
| `create_runner`    | グループでRunnerを作成する権限を付与します。                                                                                                                                                                                                                                                            |
| `manage_runner`    | グループでRunnerを管理する権限を付与します。                                                                                                                                                                                                                                                            |
| `ai_features`      | GitLab DuoでAPIアクションを実行する権限を付与します。このスコープは、JetBrains用のGitLab Duoプラグインと連携するように設計されています。その他のすべての拡張機能については、スコープの要件を参照してください。                                                                                                          |
| `k8s_proxy`        | グループ内のKubernetes用エージェントを使用してKubernetes APIコールを実行する権限を付与します。                                                                                                                                                                                                               |
| `self_rotate`      | [パーソナルアクセストークンAPI](../../../api/personal_access_tokens.md#rotate-a-personal-access-token)を使用して、このトークンをローテーションする権限を付与します。他のトークンのローテーションは許可しません。 |

## グループアクセストークンの作成を制限する {#restrict-the-creation-of-group-access-tokens}

潜在的な不正利用を制限するために、ユーザーがグループ階層のトークンを作成できないように制限できます。この設定は、トップレベルグループに対してのみ構成可能であり、すべてのダウンストリームサブグループおよびプロジェクトに適用されます。既存のグループアクセストークンは、有効期限が切れるまで、または手動で失効するまで有効なままです。

グループアクセストークンの作成を制限するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **権限**で、**Users can create project access tokens and group access tokens in this group**（ユーザーはこのグループでプロジェクトアクセストークンとグループアクセストークンを作成できます）チェックボックスをオフにします。
1. **変更を保存**を選択します。

## アクセストークンの有効期限 {#access-token-expiration}

既存のグループアクセストークンに有効期限が自動的に適用されるかどうかは、お使いのGitLabの提供形態と、GitLab 16.0以降にアップグレードした時期によって異なります:

- GitLab.comでは、16.0マイルストーン期間中に、有効期限のない既存のグループアクセストークンには、現在の日付より365日後の有効期限が自動的に付与されました。
- GitLab Self-Managedで、GitLab 15.11以前からGitLab 16.0以降にアップグレードした場合は、次のようになります:
  - 2024年7月23日以前は、有効期限のない既存のグループアクセストークンには、現在の日付より365日後の有効期限が自動的に付与されました。これは破壊的な変更です。
  - 2024年7月24日以降、有効期限のない既存のグループアクセストークンには有効期限が設定されませんでした。

GitLab Self-Managedで、次のいずれかのGitLabバージョンを新規インストールした場合、既存のグループアクセストークンに有効期限が自動的に適用されることはありません:

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

### グループアクセストークンの有効期限に関するメール {#group-access-token-expiry-emails}

{{< history >}}

- 60日前と30日前の有効期限通知は、GitLab 17.6で`expiring_pats_30d_60d_notifications`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)されました。デフォルトでは無効になっています。
- 60日前と30日前の通知は、GitLab 17.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792)になりました。機能フラグ`expiring_pats_30d_60d_notifications`は削除されました。
- 継承されたグループメンバーへの通知は、GitLab 17.7で`pat_expiry_inherited_members_notification`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)されました。デフォルトでは無効になっています。
- 機能フラグ`pat_expiry_inherited_members_notification`は、GitLab 17.10でデフォルトで[有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)。
- 機能フラグ`pat_expiry_inherited_members_notification`は、GitLab `17.11`で削除されました。

{{< /history >}}

GitLabは、UTC午前1時00分にチェックを毎日実行して、近い将来に有効期限が切れるグループアクセストークンを特定します。オーナーロールを持つグループのメンバーには、これらのトークンが特定の期間内に期限切れになるとメールで通知されます。日数はGitLabのバージョンによって異なります:

- GitLab 17.6以降では、チェックでグループアクセストークンが今後60日以内に期限切れになると識別された場合、グループオーナーはメールで通知されます。チェックでグループアクセストークンが今後30日以内に期限切れになると識別された場合、追加のメールが送信されます。
- チェックでグループアクセストークンが今後7日以内に期限切れになると識別された場合に、グループオーナーはメールで通知されます。
- GitLab 17.7以降では、グループ内でオーナーロールを継承したメンバーも通知メールを受信できます。これは、以下を変更することで設定できます:
  - グループまたは親グループの[グループ設定](../manage.md#expiry-emails-for-group-and-project-access-tokens)。
  - GitLab Self-Managedでは、[インスタンス設定](../../../administration/settings/email.md#group-and-project-access-token-expiry-emails-to-inherited-members)。

期限切れのアクセストークンは、[自動的に削除される](../../project/settings/project_access_tokens.md#inactive-token-retention)まで、[非アクティブなグループアクセストークンテーブル](#revoke-or-rotate-a-group-access-token)にリストされます。

## グループのボットユーザー {#bot-users-for-groups}

グループの[ボットユーザーは、GitLabが作成した請求対象外のユーザー](../../../subscriptions/manage_users_and_seats.md#criteria-for-non-billable-users)です。グループアクセストークンを作成するたびに、ボットユーザーが作成され、グループに追加されます。これらのボットユーザーは[プロジェクトのボットユーザー](../../project/settings/project_access_tokens.md#bot-users-for-projects)に似ていますが、プロジェクトではなくグループに追加される点が異なります。グループのボットユーザーは、次のようなユーザーです:

- 請求対象ユーザーではないため、ライセンス制限にはカウントされません。
- グループの最大ロールはオーナーにすることができます。詳しくは、[グループアクセストークンの作成](../../../api/group_access_tokens.md#create-a-group-access-token)をご覧ください。
- ユーザー名は`group_{group_id}_bot_{random_string}`に設定されています。たとえば、`group_123_bot_4ffca233d8298ea1`のようにします。
- メールは`group_{group_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}`に設定されています。たとえば、`group_123_bot_4ffca233d8298ea1@noreply.example.com`のようにします。

その他すべてのプロパティは、[プロジェクトのボットユーザー](../../project/settings/project_access_tokens.md#bot-users-for-projects)と同様です。

## トークンの可用性 {#token-availability}

グループアクセストークンは、有料サブスクリプションでのみ利用可能で、トライアルサブスクリプションでは利用できません。詳しくは、[GitLabトライアルFAQの「何が含まれていますか」セクション](https://about.gitlab.com/free-trial/#what-is-included-in-my-free-trial-what-is-excluded)をご覧ください。

## 関連トピック {#related-topics}

- [パーソナルアクセストークン](../../profile/personal_access_tokens.md)
- [プロジェクトアクセストークン](../../project/settings/project_access_tokens.md)
- [グループアクセストークンAPI](../../../api/group_access_tokens.md)
