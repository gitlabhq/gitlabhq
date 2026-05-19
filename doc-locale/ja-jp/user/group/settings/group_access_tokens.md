---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループアクセストークン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループアクセストークンは、グループとそのプロジェクトへの認証されたアクセスを提供します。それらはパーソナルアクセストークンおよびプロジェクトアクセストークンに似ていますが、ユーザーやプロジェクトではなくグループに紐付けられています。グループアクセストークンを使用して、他のグループ、プロジェクト、またはパーソナルアクセストークンを作成することはできません。

グループアクセストークンを使用すると、次の認証が可能です。

- [GitLab API](../../../api/rest/authentication.md#personal-project-and-group-access-tokens)で認証。
- HTTPSを介したGitの場合。使用方法:
  - 任意の空白以外の値をユーザー名として使用します。
  - グループアクセストークンをパスワードとして使用します。

前提条件: 

- グループのオーナーロール。

> [!note] 
> GitLab.comでは、グループアクセストークンにはPremiumまたはUltimateプランのサブスクリプションが必要です。それらは[トライアル](https://about.gitlab.com/free-trial/#what-is-included-in-my-free-trial-what-is-excluded)期間中は利用できません。
>
> GitLab Self-ManagedおよびGitLab Dedicatedでは、グループアクセストークンはどのライセンスでも利用できます。

## あなたのアクセストークンを表示する {#view-your-access-tokens}

{{< history >}}

- GitLab 16.0以前では、トークンの使用状況情報は24時間ごとに更新されていました。
- トークンの使用状況情報の更新頻度は、GitLab 16.1で24時間から10分に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/410168)されました。
- IPアドレスを表示する機能は、GitLab 17.8で`pat_ip`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428577)されました。17.9ではデフォルトで有効になっています。
- IPアドレスを表示する機能は、GitLab 17.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/513302)になりました。機能フラグ`pat_ip`は削除されました。

{{< /history >}}

グループアクセストークンページには、あなたのアクセストークンに関する情報が表示されます。

このページから、以下の操作を実行できます:

- グループアクセストークンの作成、ローテーション、および失効。
- すべてのアクティブなグループアクセストークンと無効なグループアクセストークンを表示します。
- トークン情報（スコープ、割り当てられたロール、有効期限を含む）を表示します。
- 使用状況の情報（使用日、および最後の5つの異なる接続IPアドレスを含む）を表示します。
  > [!note] 
  > GitLabは、トークンがGit操作を実行したり、[REST](../../../api/rest/_index.md)または[GraphQL](../../../api/graphql/_index.md) APIで操作を認証したりすると、トークンの使用状況情報を定期的に更新します。トークンの使用時間は10分ごとに、トークン使用IPアドレスは1分ごとに更新されます。

あなたのグループアクセストークンを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **アクセストークン**を選択します。

アクティブで利用可能なアクセストークンは、**アクティブなグループアクセストークン**セクションに保存されます。期限切れ、ローテーション済み、または失効したトークンは、**無効なグループアクセストークン**セクションに保存されます。

## グループアクセストークンの作成 {#create-a-group-access-token}

{{< history >}}

- 期限切れにならないグループアクセストークンを作成する機能は、GitLab 16.0で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/392855)。
- GitLab 17.6で、`buffered_token_expiration_limit`[フラグ](../../../administration/feature_flags/_index.md)とともに、最大許容ライフタイム制限が[400日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)されました。デフォルトでは無効になっています。
- グループアクセストークンの説明は、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)されました。

{{< /history >}}

> [!flag]
> 拡張された最大許容ライフタイム制限の利用可能性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

### UIを使用する場合 {#with-the-ui}

グループアクセストークンを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **アクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. **トークン名**に、名前を入力します。トークン名は、グループを表示する権限を持つすべてのユーザーに表示されます。
1. オプション。**トークンの説明**に、トークンの説明を入力します。
1. **有効期限**に、トークンの有効期限を入力します。
   - トークンは、その日のUTC深夜に期限が切れます。
   - 日付を入力しない場合、有効期限は今日から365日後に設定されます。
   - デフォルトでは、有効期限は今日から365日を超えることはできません。GitLab 17.6以降では、管理者は[アクセストークンの最大ライフタイムを変更](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)できます。
1. トークンのロールを選択します。
1. 1つまたは複数の[グループアクセストークンのスコープ](#group-access-token-scopes)を選択します。
1. **グループアクセストークンを作成**を選択します。

グループアクセストークンが表示されます。グループアクセストークンを安全な場所に保存します。ページを離れるか更新すると、再度表示することはできません。

すべてのグループアクセストークンは、パーソナルアクセストークンに設定された[デフォルトのプレフィックス設定](../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)を継承します。

> [!warning]
> グループアクセストークンは内部ユーザーとして扱われます。内部ユーザーがグループアクセストークンを作成した場合、そのトークンは、表示レベルがInternalに設定されているすべてのプロジェクトにアクセスできます。

### Railsコンソールを使用する場合 {#with-the-rails-console}

管理者の場合は、Railsコンソールでグループアクセストークンを作成できます。

1. [Railsコンソール](../../../administration/operations/rails_console.md)で次のコマンドを実行します。

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

   1. GitLab REST APIで、`PRIVATE-TOKEN`ヘッダーでグループアクセストークンを使用します。例: 

      - グループに[エピックを作成](../../../api/epics.md#create-an-epic)します。
      - グループのプロジェクトの1つに[プロジェクトパイプラインを作成](../../../api/pipelines.md#create-a-new-pipeline)します。
      - グループのプロジェクトの1つに[イシューを作成](../../../api/issues.md#create-an-issue)します。

   1. グループトークンを使用して、HTTPSを使って[グループのプロジェクトを複製](../../../topics/git/clone.md#clone-with-https)します。

### グループアクセストークンのスコープ {#group-access-token-scopes}

{{< history >}}

- `k8s_proxy`は、GitLab 16.4で`k8s_proxy_pat`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422408)されました。デフォルトでは有効になっています。
- 機能フラグ`k8s_proxy_pat`は、GitLab 16.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518)されました。
- `self_rotate`は、GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111)されました。デフォルトでは有効になっています。

{{< /history >}}

スコープは、グループアクセストークンで認証するときに利用可能なアクションを定義します。

| スコープ                    | 説明 |
| ------------------------ | ----------- |
| `api`                    | スコープ付きグループおよび関連するプロジェクトAPIへの完全な読み取り/書き込みアクセスを許可します（[コンテナレジストリ](../../packages/container_registry/_index.md)、[依存プロキシ](../../packages/dependency_proxy/_index.md)、[パッケージレジストリ](../../packages/package_registry/_index.md)を含む）。 |
| `read_api`               | [パッケージレジストリ](../../packages/package_registry/_index.md)を含む、スコープ付きグループおよび関連プロジェクトAPIへの読み取りアクセスを許可します。 |
| `read_repository`        | グループ内のすべてのリポジトリに対する読み取りアクセス（プル）を付与します。 |
| `write_repository`       | グループ内のすべてのリポジトリに対する読み取り/書き込みアクセス（プルおよびプッシュ）を付与します。 |
| `read_registry`          | グループ内のいずれかのプロジェクトがプライベートで認可が必要な場合、[コンテナレジストリ](../../packages/container_registry/_index.md)イメージへの読み取りアクセス（プル）を付与します。コンテナレジストリが有効になっている場合にのみ使用できます。 |
| `write_registry`         | [コンテナレジストリ](../../packages/container_registry/_index.md)への書き込みアクセス（プッシュ）を許可します。イメージをプッシュするには、`read_registry`スコープを含める必要があります。コンテナレジストリが有効になっている場合にのみ使用できます。 |
| `read_virtual_registry`  | [依存プロキシ](../../packages/dependency_proxy/_index.md)を介したコンテナイメージへの読み取りアクセス（プル）を付与します。依存プロキシが有効になっている場合にのみ使用できます。 |
| `write_virtual_registry` | [依存プロキシ](../../packages/dependency_proxy/_index.md)を介したコンテナイメージへの読み取りおよび書き込みアクセス（プル、プッシュ、削除）を付与します。依存プロキシが有効になっている場合にのみ使用できます。 |
| `create_runner`          | グループ内にRunnerを作成する権限を付与します。 |
| `manage_runner`          | グループ内のRunnerを管理する権限を付与します。 |
| `ai_features`            | GitLab Duo、コード提案API、およびGitLab Duo Chat APIのアクションを実行する権限を付与します。GitLab Duoプラグインfor JetBrainsと連携するように設計されています。その他のすべての拡張機能については、個々の拡張機能のドキュメントを参照してください。GitLab Self-Managedバージョン16.5、16.6、16.7では動作しません。 |
| `k8s_proxy`              | グループ内のKubernetes用エージェントを使用してKubernetes APIコールを実行する権限を付与します。 |
| `self_rotate`            | [パーソナルアクセストークンAPI](../../../api/personal_access_tokens.md#rotate-a-personal-access-token)を使用して、このトークンをローテーションする権限を付与します。他のトークンのローテーションは許可しません。 |

## グループアクセストークンをローテーションする {#rotate-a-group-access-token}

{{< history >}}

- 期限切れおよび失効したトークンを表示する機能は、GitLab 17.3で`retain_resource_access_token_user_after_revoke`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)されました。デフォルトでは無効になっています。
- 期限切れおよび失効したトークンが自動的に削除されるまで表示する機能は、GitLab 17.9で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/471683)されました。機能フラグ`retain_resource_access_token_user_after_revoke`は削除されました。

{{< /history >}}

トークンをローテーションして、元のトークンと同じ権限とスコープを持つ新しいトークンを作成します。元のトークンは直ちに無効になり、GitLabは監査目的で両方のバージョンを保持します。アクセストークンページで、アクティブなトークンと無効なトークンの両方を表示できます。

GitLab Self-ManagedおよびGitLab Dedicatedでは、[無効なトークンの保持期間](../../../administration/settings/account_and_limit_settings.md#inactive-project-and-group-access-token-retention-period)を変更できます。

> [!warning]
> このアクションは元に戻せません。ローテーションされたアクセストークンに依存するツールは、新しいトークンを参照するまで機能しなくなります。

グループアクセストークンをローテーションするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **アクセストークン**を選択します。
1. 関連するトークンの**ローテーション**（{{< icon name="retry" >}}）を選択します。
1. 確認ダイアログで、**ローテーション**を選択します。

## グループアクセストークンを失効する {#revoke-a-group-access-token}

{{< history >}}

- 期限切れおよび失効したトークンを表示する機能は、GitLab 17.3で`retain_resource_access_token_user_after_revoke`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)されました。デフォルトでは無効になっています。
- 期限切れおよび失効したトークンが自動的に削除されるまで表示する機能は、GitLab 17.9で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/471683)されました。機能フラグ`retain_resource_access_token_user_after_revoke`は削除されました。

{{< /history >}}

トークンを失効すると、直ちに無効になり、それ以降の使用が防止されます。トークンはすぐに削除されませんが、トークンリストをフィルタリングしてアクティブなトークンのみを表示できます。デフォルトでは、GitLabは失効したグループアクセストークンおよびプロジェクトアクセストークンを30日後に削除します。詳細については、[無効なトークンの保持](../../../administration/settings/account_and_limit_settings.md#inactive-project-and-group-access-token-retention-period)を参照してください。

> [!warning]
> このアクションは元に戻せません。失効したアクセストークンに依存するツールは、新しいトークンを追加するまで機能しなくなります。

グループアクセストークンを失効するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **アクセストークン**を選択します。
1. 関連するトークンの**取り消し**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**取り消し**を選択します。

## アクセストークンの有効期限 {#access-token-expiration}

パーソナルアクセストークン、グループアクセストークン、およびプロジェクトアクセストークンは、有効期限のUTC深夜に期限が切れます。期限切れになると、それらはリクエストを認証するために使用できなくなります。

GitLab 16.0以降では、新しいアクセストークンには有効期限が必要です。有効期限がトークン作成時に明示的に設定されていない場合、今日から365日間の有効期限が適用されます。Ultimateでは、管理者はアクセストークンの[最大許容ライフタイム](../../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)を設定できます。

あなたのGitLabバージョンと提供内容によっては、GitLabバージョンのアップグレード時に既存のアクセストークンに有効期限が自動的に適用される場合があります。詳細については、[期限切れにならないアクセストークン](../../../update/deprecations.md#non-expiring-access-tokens)を参照してください。

### グループアクセストークンの有効期限に関するメール {#group-access-token-expiry-emails}

{{< history >}}

- 60日前と30日前の有効期限通知は、GitLab 17.6で`expiring_pats_30d_60d_notifications`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)されました。デフォルトでは無効になっています。
- 60日前と30日前の通知は、GitLab 17.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792)になりました。機能フラグ`expiring_pats_30d_60d_notifications`は削除されました。
- 継承されたグループメンバーへの通知は、GitLab 17.7で`pat_expiry_inherited_members_notification`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)されました。デフォルトでは無効になっています。
- 機能フラグ`pat_expiry_inherited_members_notification`は、GitLab 17.10でデフォルトで[有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)。
- 機能フラグ`pat_expiry_inherited_members_notification`は、GitLab `17.11`で削除されました。

{{< /history >}}

GitLabは、まもなく期限切れになるグループアクセストークンを特定するために、UTC午前1:00に毎日チェックを実行します。オーナーロールを持つ直接のメンバーには、トークンの期限が切れる7日前にメールで通知されます。GitLab 17.6以降では、トークンの期限が切れる30日前と60日前にも通知が送信されます。

GitLab 17.7以降では、オーナーロールを持つ継承されたメンバーもこれらのメールを受け取ることができます。これは、[GitLabインスタンス](../../../administration/settings/email.md#group-and-project-access-token-expiry-emails-to-inherited-members)上のすべてのグループ、または[特定のグループ](../manage.md#expiry-emails-for-group-and-project-access-tokens)に対して設定できます。親グループに適用された場合、この設定はすべての子孫グループとプロジェクトに継承されます。

期限切れのトークンは、自動的に削除されるまで無効なグループアクセストークンセクションに表示されます。GitLab Self-Managedでは、この[保持期間](../../../administration/settings/account_and_limit_settings.md#inactive-project-and-group-access-token-retention-period)を変更できます。

## グループのボットユーザー {#bot-users-for-groups}

グループアクセストークンを作成すると、GitLabはボットユーザーを作成し、それをトークンに関連付けます。

ボットユーザーは以下のプロパティを持っています:

- それらには、関連付けられたアクセストークンのロールとスコープに対応する権限が付与されます。
- それらはグループのメンバーであり、サブグループとプロジェクトのメンバーシップを継承しますが、他のグループやプロジェクトに直接追加することはできません。
- それらは[非請求対象ユーザー](../../../subscriptions/manage_seats.md#criteria-for-non-billable-users)であり、ライセンス制限にはカウントされません。
- 彼らのコントリビュートは、ボットユーザーアカウントに関連付けられています。
- 削除されると、彼らのコントリビュートは[ゴーストユーザー](../../profile/account/delete_account.md#associated-records)に移動されます。

ボットユーザーが作成されると、以下の属性が定義されます:

| 属性 | 値                                                                                                | 例 |
| --------- | ---------------------------------------------------------------------------------------------------- | ------- |
| 名前      | 関連付けられたアクセストークンの名前。                                                             | `Main token - Read registry` |
| ユーザー名  | この形式で生成されます: `group_{group_id}_bot_{random_string}`                                     | `group_123_bot_4ffca233d8298ea1` |
| メール     | この形式で生成されます: `group_{group_id}_bot_{random_string}@noreply.{Gitlab.config.gitlab.host}` | `group_123_bot_4ffca233d8298ea1@noreply.example.com` |

## グループアクセストークンとプロジェクトアクセストークンの作成を制限する {#restrict-the-creation-of-group-and-project-access-tokens}

潜在的な悪用を制限するために、トップレベルグループおよび任意の子孫サブグループやプロジェクトでのアクセストークンの作成をユーザーに制限できます。既存のトークンは、期限が切れるか手動で失効されるまで有効です。

アクセストークンの作成を制限するには:

1. 上部のバーで**検索または移動先**を選択し、トップレベルグループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **Users can create group access tokens and project access tokens in this group**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## 関連トピック {#related-topics}

- [パーソナルアクセストークン](../../profile/personal_access_tokens.md)
- [プロジェクトアクセストークン](../../project/settings/project_access_tokens.md)
- [グループアクセストークンAPI](../../../api/group_access_tokens.md)
