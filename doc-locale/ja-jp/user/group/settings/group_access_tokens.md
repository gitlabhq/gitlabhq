---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループアクセストークン
---

{{< details >}}

- プラン：Premium、Ultimate
- 提供形態：GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループアクセストークンを使用すると、単一のトークンで次の操作を実行できます：

- グループのアクションを実行する。
- グループ内のプロジェクトを管理する。

グループアクセストークンを使用して、以下を認証できます。

- [GitLab API](../../../api/rest/authentication.md#personalprojectgroup-access-tokens)を使用して
- HTTPS 経由で Git で認証します。用途：

  - 空白でない任意の値をユーザー名とする。
  - グループアクセストークンをパスワードとする。

> GitLab.com では、Premium または Ultimate ライセンスプランをお持ちの場合、グループアクセストークンを使用できます。グループアクセストークンは、[トライアルライセンス](https://about.gitlab.com/free-trial/)では使用できません。
>
> GitLab Dedicated および GitLab Self-Managedインスタンスでは、どのライセンスプランでもグループアクセストークンを使用できます。Freeプランをお持ちの場合：
>
> - [ユーザーのセルフ登録](../../../administration/settings/sign_up_restrictions.md#disable-new-sign-ups)に関するセキュリティおよびコンプライアンス関連のポリシーを確認します。
> - 潜在的な不正利用を減らすために、[グループアクセストークンの作成を制限する](#restrict-the-creation-of-group-access-tokens)ことを検討してください。

グループアクセストークンは[プロジェクトアクセストークン](../../project/settings/project_access_tokens.md)および[パーソナルアクセストークン](../../profile/personal_access_tokens.md)に似ていますが、プロジェクトまたはユーザーではなくグループに関連付けられている点が異なります。

GitLab Self-Managedインスタンスでは、制限が設定されている場合、グループアクセストークンはパーソナルアクセストークンと同じ[最大ライフタイム制限](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)の対象となります。

グループアクセストークンを使用して、他のグループ、プロジェクト、またはパーソナルアクセストークンを作成することはできません。

グループアクセストークンは、パーソナルアクセストークンに設定された[デフォルトのプレフィックス設定](../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)を継承します。

## グループアクセストークンの作成

{{< history >}}

- GitLab 15.3 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348660)され、UI にはデフォルトの有効期限（30 日）とデフォルトロール（ゲスト）が入力されています。
- 有効期限のないグループアクセストークンを作成する機能は、GitLab 16.0 で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/392855)されました。
- GitLab 17.6 では、許容される最大ライフタイム制限が[400 日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)されました（`buffered_token_expiration_limit` という[フラグ](../../../administration/feature_flags.md)を使用）。デフォルトでは無効になっています。
- グループアクセストークンの説明は、GitLab 17.7 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)されました。

{{< /history >}}

{{< alert type="flag" >}}

拡張された最大許容ライフタイム制限の可用性は、機能フラグによって制御されます。詳しくは、履歴をご覧ください。

{{< /alert >}}

{{< alert type="warning" >}}

有効期限のないグループアクセストークンを作成する機能は、GitLab 15.4 で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/369122)となり、GitLab 16.0 で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/392855)されました。既存のトークンに追加された有効期限の詳細については、[アクセストークンの有効期限](#access-token-expiration)に関するドキュメントを参照してください。

{{< /alert >}}

### UIを使用して

グループアクセストークンを作成するには：

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。
1. **設定 ＞ アクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. **トークン名**に、名前を入力します。トークン名は、グループを表示する権限を持つすべてのユーザーに表示されます。
1. 任意。**トークンの説明**に、トークンの説明を入力します。
1. **有効期限**に、トークンの有効期限を入力します。
   - トークンは、その日付の UTC 午前 0 時に期限切れになります。有効期限が 2024 年 1 月 1 日のトークンは、2024 1 月 1 日の UTC 午前 0 時に期限切れになります。
   - 有効期限を入力しない場合、有効期限は現在の日付より 365 日後に自動的に設定されます。
   - デフォルトでは、この日付は現在の日付より最大 365 日後になります。GitLab 17.6 以降では、[この制限を 400 日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)できます。

   - インスタンス全体の[最大ライフタイム](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)設定により、GitLab Self-Managedインスタンスで許可される最大ライフタイムが制限される場合があります。
1. トークンのロールを選択します。
1. [必要なスコープ](#scopes-for-a-group-access-token)を選択します。
1. **グループアクセストークンを作成**を選択します。

グループアクセストークンが表示されます。グループアクセストークンを安全な場所に保存します。ページから離れたり、ページを更新したりすると、再度表示することはできません。

{{< alert type="warning" >}}

グループアクセストークンは[内部ユーザー](../../../administration/internal_users.md)として扱われます。内部ユーザーがグループアクセストークンを作成した場合、そのトークンは表示レベルが[内部](../../public_access.md)に設定されているすべてのプロジェクトにアクセスできます。

{{< /alert >}}

### Railsコンソールを使用

管理者の場合は、Railsコンソールでグループアクセストークンを作成できます。

1. [Railsコンソール](../../../administration/operations/rails_console.md)で次のコマンドを実行します：

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

1. 生成されたグループアクセストークンが動作するかテストします。

   1. GitLab REST API で、`PRIVATE-TOKEN` ヘッダーでグループアクセストークンを使用します。次に例を示します。

      - グループに[エピックを作成](../../../api/epics.md#new-epic)します。
      - グループのプロジェクトの 1 つに[プロジェクトパイプラインを作成](../../../api/pipelines.md#create-a-new-pipeline)します。
      - グループのプロジェクトの 1 つに[イシューを作成](../../../api/issues.md#new-issue)します。

   1. グループトークンを使用して、HTTPS を使用して[グループのプロジェクトを複製](../../../topics/git/clone.md#clone-with-https)します。

## グループアクセストークンの失効またはローテーション

{{< history >}}

- 期限切れおよび失効したトークンを表示する機能は、GitLab 17.3 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)されました（`retain_resource_access_token_user_after_revoke` という[フラグ](../../../administration/feature_flags.md)を使用）。デフォルトでは無効になっています。
- 期限切れおよび失効したトークンを表示する機能は、30 日間に制限されており、GitLab 17.9 で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/471683)されています。機能フラグ`retain_resource_access_token_user_after_revoke` は削除されました。

{{< /history >}}

GitLab 17.9 以降では、アクティブおよび非アクティブのグループアクセストークンの両方をアクセストークンページで表示できます。

非アクティブのグループアクセストークンテーブルには、失効したトークンと期限切れのトークンが、非アクティブになってから 30 日間表示されます。

[アクティブなトークンファミリー](../../../api/personal_access_tokens.md#automatic-reuse-detection)に属するトークンは、ファミリーからの最新のアクティブなトークンが期限切れまたは失効してから 30 日間表示されます。

グループアクセストークンを失効またはローテーションするには：

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。
1. **設定 ＞ アクセストークン**を選択します。
1. 関連するトークンについて、**失効**（{{< icon name="remove" >}}）または**ローテーション**（{{< icon name="retry" >}}）を選択します。
1. 確認ダイアログで、**失効**または**ローテーション**を選択します。

## グループアクセストークンのスコープ

{{< history >}}

- `k8s_proxy` は GitLab 16.4 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422408)されました（`k8s_proxy_pat` という[フラグ](../../../administration/feature_flags.md)を使用）。デフォルトで有効になっています。
- 機能フラグ`k8s_proxy_pat` は GitLab 16.5 で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518)されました。
- `self_rotate` は GitLab 17.9 で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111)されました。デフォルトで有効になっています。

{{< /history >}}

スコープは、グループアクセストークンで認証するときに実行できるアクションを決定します。

| スコープ              | 説明                                                                                                                                                                                                                                                                                                |
|:-------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`              | スコープ付きグループおよび関連するプロジェクトAPIへの完全な読み取り/書き込みアクセスを許可します（[コンテナレジストリ](../../packages/container_registry/_index.md)、[依存プロキシ](../../packages/dependency_proxy/_index.md)、[パッケージレジストリ](../../packages/package_registry/_index.md)を含む）。 |
| `read_api`         | [パッケージレジストリ](../../packages/package_registry/_index.md)を含む、スコープ付きグループおよび関連プロジェクト API への読み取りアクセスを許可します。                                                                                                                                                                |
| `read_registry`    | グループ内のプロジェクトがプライベートで認証が必要な場合に、[コンテナレジストリ](../../packages/container_registry/_index.md)イメージへの読み取りアクセス（プル）を許可します。                                                                                                                           |
| `write_registry`   | [コンテナレジストリ](../../packages/container_registry/_index.md)への書き込みアクセス（プッシュ）を許可します。イメージをプッシュするには、読み取りと書き込みの両方のアクセス権が必要です。                                                                                                                                                |
| `read_repository`  | グループ内のすべてのリポジトリへの読み取りアクセス（プル）を許可します。                                                                                                                                                                                                                                              |
| `write_repository` | グループ内のすべてのリポジトリへの読み取り/書き込みアクセス（プル/プッシュ）を許可します。                                                                                                                                                                                                                           |
| `create_runner`    | グループでRunnerを作成する権限を付与します。                                                                                                                                                                                                                                                            |
| `manage_runner`    | グループでRunnerを管理する権限を付与します。                                                                                                                                                                                                                                                            |
| `ai_features`      | GitLab Duo の API アクションを実行する権限を付与します。このスコープは、JetBrains 用の GitLab Duo プラグインと連携するように設計されています。その他のすべての拡張機能については、スコープの要件を参照してください。                                                                                                          |
| `k8s_proxy`        | グループ内のKubernetes用エージェントを使用してKubernetes APIコールを実行する権限を付与します。                                                                                                                                                                                                               |
| `self_rotate`      | [パーソナルアクセストークン API](../../../api/personal_access_tokens.md#rotate-a-personal-access-token)を使用して、このトークンをローテーションする権限を付与します。他のトークンのローテーションは許可しません。 |

## グループアクセストークンの作成を制限する

潜在的な不正利用を制限するために、ユーザーがグループ階層のトークンを作成できないように制限できます。この設定は、トップレベルグループに対してのみ構成可能であり、すべてのダウンストリームサブグループおよびプロジェクトに適用されます。既存のグループアクセストークンは、有効期限が切れるまで、または手動で失効するまで有効なままです。

グループアクセストークンの作成を制限するには：

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。このグループはトップレベルにある必要があります。
1. **設定 ＞ 一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **権限**で、**ユーザーはこのグループでプロジェクトアクセストークンとグループアクセストークンを作成できます** チェックボックスをオフにします。
1. **変更を保存**を選択します。

## アクセストークンの有効期限

既存のグループアクセストークンに有効期限が自動的に適用されるかどうかは、お使いの GitLab の提供形態と、GitLab 16.0 以降にアップグレードした時期によって異なります：

- GitLab.com では、16.0 マイルストーン期間中に、有効期限のない既存のグループアクセストークンには、現在の日付より 365 日後の有効期限が自動的に付与されました。
- GitLab Self-Managed で、GitLab 15.11 以前から GitLab 16.0 以降にアップグレードした場合：
  - 2024 年 7 月 23 日以前は、有効期限のない既存のグループアクセストークンには、現在の日付より 365 日後の有効期限が自動的に付与されました。この変更は破格の変更です。
  - 2024 年 7 月 24 日以降、有効期限のない既存のグループアクセストークンには有効期限が設定されませんでした。

GitLab Self-Managed で、次のいずれかの GitLab バージョンを新規インストールした場合、既存のグループアクセストークンに有効期限が自動的に適用されることはありません。

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

### グループアクセストークンの有効期限に関するメール

{{< history >}}

- 60 日および 30 日の有効期限通知は、GitLab 17.6 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)されました（`expiring_pats_30d_60d_notifications` という[フラグ](../../../administration/feature_flags.md)を使用）。デフォルトでは無効になっています。
- 60 日および 30 日の通知は、GitLab 17.7 で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792)されています。機能フラグ`expiring_pats_30d_60d_notifications` は削除されました。
- 継承されたグループメンバーへの通知は、GitLab 17.7 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)されました（`pat_expiry_inherited_members_notification` という[フラグ](../../../administration/feature_flags.md)を使用）。デフォルトでは無効になっています。
- 機能フラグ`pat_expiry_inherited_members_notification` は、GitLab 17.10 でデフォルトで[有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)。

{{< /history >}}

GitLab は、毎日午前 1:00 UTC にチェックを実行して、近い将来に有効期限が切れるグループアクセストークンを特定します。オーナーロールを持つグループのメンバーには、これらのトークンが特定の期間内に期限切れになるとメールで通知されます。日数は GitLab のバージョンによって異なります。

- GitLab 17.6 以降では、グループオーナーは、チェックでグループアクセストークンが今後 60 日以内に期限切れになると識別された場合に、メールで通知されます。チェックでグループアクセストークンが今後 30 日以内に期限切れになると識別された場合、追加のメールが送信されます。
- グループオーナーは、チェックでグループアクセストークンが今後 7 日以内に期限切れになると識別された場合に、メールで通知されます。
- GitLab 17.7 以降では、グループ内でオーナーのロールを継承したメンバーも通知メールを受信できます。これは、以下を変更することで設定できます。
  - グループまたは親グループの[グループ設定](../manage.md#expiry-emails-for-group-and-project-access-tokens)。
  - GitLab Self-Managed では、[インスタンス設定](../../../administration/settings/email.md#group-and-project-access-token-expiry-emails-to-inherited-members)。

期限切れのアクセストークンは、トークンの期限切れ後 30 日間、[非アクティブなグループアクセストークンテーブル](#revoke-or-rotate-a-group-access-token)にリストされます。

## グループのボットユーザー

グループの[ボットユーザーは、GitLab が作成した請求対象外のユーザー](../../../subscriptions/self_managed/_index.md#billable-users)です。グループアクセストークンを作成するたびに、ボットユーザーが作成され、グループに追加されます。これらのボットユーザーは[プロジェクトのボットユーザー](../../project/settings/project_access_tokens.md#bot-users-for-projects)に似ていますが、プロジェクトではなくグループに追加される点が異なります。グループのボットユーザー：

- 請求対象ユーザーではないため、ライセンス制限にはカウントされません。
- グループの最大ロールはオーナーにすることができます。詳しくは、[グループアクセストークンの作成](../../../api/group_access_tokens.md#create-a-group-access-token)をご覧ください。
- ユーザー名は `group_{group_id}_bot_{random_string}` に設定されています。たとえば、`group_123_bot_4ffca233d8298ea1` のようにします。
- メールは `group_{group_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}` に設定されています。たとえば、`group_123_bot_4ffca233d8298ea1@noreply.example.com` のようにします。

その他すべてのプロパティは、[プロジェクトのボットユーザー](../../project/settings/project_access_tokens.md#bot-users-for-projects)と同様です。

## トークンの可用性

グループアクセストークンは、有料サブスクリプションでのみ利用可能で、トライアルサブスクリプションでは利用できません。詳しくは、GitLabトライアルFAQの[「何が含まれていますか」セクション](https://about.gitlab.com/free-trial/#what-is-included-in-my-free-trial-what-is-excluded)をご覧ください。

## 関連トピック

- [グループアクセストークン API](../../../api/group_access_tokens.md)
