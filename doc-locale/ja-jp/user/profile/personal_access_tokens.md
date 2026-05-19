---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: パーソナルアクセストークンを使用して、HTTPSを介してGitLab APIまたはGitで認証します。作成、ローテーション、取り消し、スコープ、および有効期限の設定などについて説明します。
title: パーソナルアクセストークン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パーソナルアクセストークンは、GitLabへの認証済みアクセストークンを提供します。これらは[OAuth2トークン](../../api/oauth2.md)の代替であり、グループアクセストークンおよびプロジェクトアクセストークンと似ていますが、グループまたはプロジェクトではなくユーザーに紐付けられます。

パーソナルアクセストークンを使用して、以下を認証することができます:

- [GitLab API](../../api/rest/authentication.md#personal-project-and-group-access-tokens)で認証。
- HTTPSを介したGitの場合。使用方法:
  - 任意の空白以外の値をユーザー名として使用します。
  - パーソナルアクセストークンをパスワードとして使用します。

> [!note] 
> [2要素認証（2FA）](account/two_factor_authentication.md)または[SAML](../../integration/saml.md#password-generation-for-users-created-through-saml)が有効になっている場合、パーソナルアクセストークンで認証する必要があります。

[GitLabマネージドTerraformステートバックエンド](../infrastructure/iac/terraform_state.md#use-your-gitlab-backend-as-a-remote-data-source)や[コンテナレジストリ](../packages/container_registry/authenticate_with_container_registry.md)など、ユーザー名を必要とする一部のGitLab機能では、GitLabユーザー名とパーソナルアクセストークンを使用します。これらのケースでは、ユーザー名は必須ですが、認証の一部として評価されません。詳細については、[イシュー212953](https://gitlab.com/gitlab-org/gitlab/-/issues/212953)を参照してください。

GitLab Self-ManagedおよびGitLab Dedicatedインスタンスでは、管理者は[ユーザートークンAPI](../../api/user_tokens.md#create-an-impersonation-token)を使用して、特定のユーザーとして認証するための代理トークンを作成できます。

## トークンの使用状況情報を表示する {#view-token-usage-information}

{{< history >}}

- GitLab 16.0以前では、トークンの使用状況情報は24時間ごとに更新されていました。
- トークンの使用状況情報の更新頻度は、GitLab 16.1で24時間から10分に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/410168)されました。
- IPアドレスを表示する機能は、GitLab 17.8で`pat_ip`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428577)されました。17.9ではデフォルトで有効になっています。
- IPアドレスを表示する機能は、GitLab 17.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/513302)になりました。機能フラグ`pat_ip`は削除されました。

{{< /history >}}

パーソナルアクセストークンページには、アクセストークンに関する情報が表示されます。

このページから、以下の操作を実行できます:

- パーソナルアクセストークンの作成、ローテーション、および失効。
- アクティブおよび非アクティブなすべてのパーソナルアクセストークンを表示します。
- トークン情報（スコープ、割り当てられたロール、有効期限を含む）を表示します。
- 使用状況の情報（使用日、および最後の5つの異なる接続IPアドレスを含む）を表示します。
  > [!note] 
  > GitLabは、トークンがGit操作を実行したり、[REST](../../api/rest/_index.md)または[GraphQL](../../api/graphql/_index.md) APIで操作を認証したりすると、トークンの使用状況情報を定期的に更新します。トークンの使用時間は10分ごとに、トークン使用IPアドレスは1分ごとに更新されます。

パーソナルアクセストークンを表示するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。

詳細パネルを開くには、トークンの名前を選択します。デフォルトでは、アクティブなトークンのみが表示されます。検索バーを使用して、アクセストークンのリストをフィルタリングします。

## パーソナルアクセストークンを作成する {#create-a-personal-access-token}

{{< history >}}

- 期限のないパーソナルアクセストークンを作成する機能は、GitLab 16.0で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/392855)。
- GitLab 17.6で、`buffered_token_expiration_limit`[フラグ](../../administration/feature_flags/list.md)とともに、最大許容ライフタイム制限が[400日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)されました。デフォルトでは無効になっています。
- パーソナルアクセストークンの説明は、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)されました。

{{< /history >}}

> [!flag]
> 拡張された最大許容ライフタイム制限の利用可能性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

パーソナルアクセストークンを作成するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。
1. **トークンを生成**ドロップダウンリストから、**レガシートークン**を選択します。
1. **トークン名**に、トークンの名前を入力します。
1. オプション。**トークンの説明**に、トークンの説明を入力します。
1. **有効期限**に、トークンの有効期限を入力します。
   - トークンは、その日のUTC深夜に期限が切れます。
   - 日付を入力しない場合、有効期限は今日から365日後に設定されます。
   - デフォルトでは、有効期限は今日から365日を超えることはできません。GitLab 17.6以降では、管理者は[アクセストークンの最大ライフタイムを変更](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)できます。
1. 1つ以上の[パーソナルアクセストークンスコープ](#personal-access-token-scopes)を選択します。
1. **トークンを生成**を選択します。

パーソナルアクセストークンが表示されます。パーソナルアクセストークンを安全な場所に保存します。ページを離れるか更新すると、再度表示することはできません。

すべてのアクセストークンは、パーソナルアクセストークン用に設定された[デフォルトプレフィックス設定](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)を継承します。

### パーソナルアクセストークンの詳細を事前に入力する {#prefill-personal-access-token-details}

名前、説明、およびスコープのリストをURLに付加することで、パーソナルアクセストークンの詳細を事前に入力できます。例: 

```plaintext
https://gitlab.example.com/-/user_settings/personal_access_tokens?name=Example+Access+token&description=My+description&scopes=api,read_user
```

> [!note]
> パーソナルアクセストークンは慎重に取り扱う必要があります。パーソナルアクセストークンの管理に関するガイダンスについては、[トークンのセキュリティに関する考慮事項](../../security/tokens/_index.md#security-considerations)を参照してください。

### パーソナルアクセストークンのスコープ {#personal-access-token-scopes}

{{< history >}}

- パーソナルアクセストークンがコンテナレジストリまたはパッケージレジストリにアクセスできなくなりました。この措置は、GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/387721)されました。
- `k8s_proxy`は、GitLab 16.4で`k8s_proxy_pat`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422408)されました。デフォルトでは有効になっています。
- 機能フラグ`k8s_proxy_pat`は、GitLab 16.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518)されました。
- `read_service_ping`は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/42692#note_1222832412)されました。
- `manage_runner`は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460721)されました。
- `self_rotate`は、GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111)されました。デフォルトでは有効になっています。

{{< /history >}}

スコープは、パーソナルアクセストークンで認証する際に利用できるアクションを定義します。以下のスコープが利用可能です:

> [!note] 
> [きめ細かいパーソナルアクセストークン](../../auth/tokens/fine_grained_access_tokens.md)は異なるスコープを使用します。

| スコープ                    | 説明 |
| ------------------------ | ----------- |
| `api`                    | すべてのグループとプロジェクト、[コンテナレジストリ](../packages/container_registry/_index.md) 、[依存プロキシ](../packages/dependency_proxy/_index.md) 、および[パッケージレジストリ](../packages/package_registry/_index.md)を含む、APIへの完全な読み取りおよび書き込みアクセスを付与します。また、Git-over-HTTPを使用してレジストリとリポジトリへの完全な読み取りおよび書き込みアクセスも付与します。 |
| `read_api`               | APIへの読み取りアクセスを許可します。このアクセスの対象には、すべてのグループとプロジェクト、コンテナレジストリ、パッケージレジストリが含まれます。 |
| `read_registry`          | プロジェクトがプライベートで認可が必要な場合、[コンテナレジストリ](../packages/container_registry/_index.md)イメージへの読み取りアクセス（プル）を付与します。コンテナレジストリが有効になっている場合にのみ使用できます。 |
| `write_registry`         | プロジェクトがプライベートで認可が必要な場合、[コンテナレジストリ](../packages/container_registry/_index.md)イメージへの書き込みアクセス（プッシュ）を付与します。コンテナレジストリが有効になっている場合にのみ使用できます。 |
| `read_virtual_registry`  | プロジェクトがプライベートで認可が必要な場合、[依存プロキシ](../packages/dependency_proxy/_index.md)を介したコンテナイメージへの読み取りアクセス（プル）を付与します。依存プロキシが有効になっている場合にのみ使用できます。 |
| `write_virtual_registry` | プロジェクトがプライベートで認可が必要な場合、[依存プロキシ](../packages/dependency_proxy/_index.md)を介したコンテナイメージへの読み取りおよび書き込みアクセス（プル、プッシュ、削除）を付与します。依存プロキシが有効になっている場合にのみ使用できます。 |
| `read_repository`        | Git-over-HTTPまたは[リポジトリファイルAPI](../../api/repository_files.md)を使用して、プライベートプロジェクトのリポジトリへの読み取りアクセス（プル）を付与します。 |
| `write_repository`       | Git-over-HTTPを使用して、プライベートプロジェクトのリポジトリへの読み取りおよび書き込みアクセス（プルおよびプッシュ）を付与します。API認証はサポートしていません。 |
| `create_runner`          | Runnerを作成する権限を付与します。 |
| `manage_runner`          | Runnerを管理する権限を付与します。 |
| `admin_mode`             | [管理者モード](../../administration/settings/sign_in_restrictions.md#admin-mode)が有効になっている場合にAPIアクションを実行する権限を付与します。GitLab Self-Managedインスタンスの管理者のみが使用できます。 |
| `ai_features`            | GitLab Duo、コード提案API、およびGitLab Duo Chat APIのアクションを実行する権限を付与します。GitLab Duoプラグインfor JetBrainsと連携するように設計されています。その他のすべての拡張機能については、個々の拡張機能のドキュメントを参照してください。GitLab Self-Managedバージョン16.5、16.6、16.7では動作しません。 |
| `k8s_proxy`              | Kubernetesエージェントを使用してKubernetes APIコールを実行する権限を付与します。 |
| `self_rotate`            | [パーソナルアクセストークンAPI](../../api/personal_access_tokens.md#rotate-a-personal-access-token)を使用して、このトークンをローテーションする権限を付与します。他のトークンのローテーションは許可しません。 |
| `read_service_ping`      | 管理者として認証すると、APIを介してService Pingペイロードをダウンロードするアクセス権を付与します。 |
| `sudo`                   | 管理者として認証されている場合、システム内の任意のユーザーとしてAPIアクションを実行する権限を許可します。 |
| `read_user`              | `/user` APIエンドポイントを介して、認証済みユーザーのプロファイルへの読み取り専用アクセスを許可します。これには、ユーザー名、公開メール、および氏名が含まれます。また、[`/users`](../../api/users.md)の下にある読み取り専用APIエンドポイントへのアクセスも許可します。 |

> [!warning] 
> [外部認可](../../administration/settings/external_authorization.md)を有効にしている場合、パーソナルアクセストークンはコンテナまたはパッケージレジストリにアクセスできません。アクセスを復元するには、外部認可を無効にします。

## パーソナルアクセストークンをローテーションする {#rotate-a-personal-access-token}

{{< history >}}

- UIを使用してパーソナルアクセストークンをローテーションする機能は、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/241523)されました。
- GitLab 18.1で[UI](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194582)を更新しました。

{{< /history >}}

トークンをローテーションして、元のトークンと同じ権限とスコープを持つ新しいトークンを作成します。元のトークンは直ちに無効になり、GitLabは監査目的で両方のバージョンを保持します。

> [!warning]
> このアクションは元に戻せません。ローテーションされたアクセストークンに依存するツールは、新しいトークンを参照するまで機能しなくなります。

パーソナルアクセストークンをローテーションするには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。
1. アクティブなトークンの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **ローテーション**（{{< icon name="retry" >}}）を選択します。
1. 確認ダイアログで、**ローテーション**を選択します。

## パーソナルアクセストークンを失効させる {#revoke-a-personal-access-token}

{{< history >}}

- GitLab 18.1で[UI](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194582)を更新しました。

{{< /history >}}

トークンを失効すると、直ちに無効になり、それ以降の使用が防止されます。GitLabは監査目的でトークンを保持します。トークンを完全に削除することはできませんが、トークンリストをフィルタリングしてアクティブなトークンのみを表示できます。

> [!warning]
> このアクションは元に戻せません。失効したアクセストークンに依存するツールは、新しいトークンを追加するまで機能しなくなります。

パーソナルアクセストークンを失効するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。
1. アクティブなトークンの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **取り消し**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**取り消し**を選択します。

## アクセストークンの有効期限 {#access-token-expiration}

パーソナルアクセストークン、グループアクセストークン、およびプロジェクトアクセストークンは、有効期限のUTC深夜に期限が切れます。期限切れになると、それらはリクエストを認証するために使用できなくなります。

GitLab 16.0以降では、新しいアクセストークンには有効期限が必要です。有効期限がトークン作成時に明示的に設定されていない場合、今日から365日間の有効期限が適用されます。Ultimateでは、管理者はアクセストークンの[最大許容ライフタイム](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)を設定できます。

あなたのGitLabバージョンと提供内容によっては、GitLabバージョンのアップグレード時に既存のアクセストークンに有効期限が自動的に適用される場合があります。詳細については、[期限切れにならないアクセストークン](../../update/deprecations.md#non-expiring-access-tokens)を参照してください。

### パーソナルアクセストークンの有効期限に関するメール {#personal-access-token-expiry-emails}

{{< history >}}

- 60日前と30日前の有効期限通知は、GitLab 17.6で`expiring_pats_30d_60d_notifications`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)されました。デフォルトでは無効になっています。
- 60日前と30日前の通知は、GitLab 17.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792)になりました。機能フラグ`expiring_pats_30d_60d_notifications`は削除されました。

{{< /history >}}

GitLabは、まもなく有効期限が切れるパーソナルアクセストークンを特定するために、毎日UTC午前1:00にチェックを実行します。トークンの有効期限が切れる7日前に、ユーザーにメールで通知されます。GitLab 17.6以降では、トークンの期限が切れる30日前と60日前にも通知が送信されます。

### パーソナルアクセストークンの有効期限カレンダー {#personal-access-token-expiry-calendar}

各トークンの有効期限にイベントが設定されたiCalendarエンドポイントをサブスクライブできます。サインイン後、このエンドポイントは`/-/user_settings/personal_access_tokens.ics`で利用できます。

### 有効期限のないサービスアカウントのパーソナルアクセストークンを作成する {#create-a-service-account-personal-access-token-with-no-expiry-date}

有効期限のない[サービスアカウントのパーソナルアクセストークンを作成](../../api/service_accounts.md#create-a-personal-access-token-for-a-group-service-account)できます。これらのパーソナルアクセストークンは、通常のアカウントのパーソナルアクセストークンとは異なり、有効期限切れになることはありません。

> [!note]
> サービスアカウントのパーソナルアクセストークンを有効期限なしで作成できるようにすると、この設定を変更した後に作成されたトークンのみに影響します。既存のトークンには影響しません。

#### GitLab.com {#gitlabcom}

前提条件: 

- トップレベルグループのオーナーロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般** > **権限とグループ機能**を選択します。
1. **サービスアカウントトークンの有効期限**チェックボックスをオフにします。

これで、有効期限のないサービスアカウントユーザーのパーソナルアクセストークンを作成できます。

#### GitLab Self-Managed {#gitlab-self-managed}

前提条件: 

- GitLab Self-Managedインスタンスの管理者である必要があります。

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **サービスアカウントトークンの有効期限**チェックボックスをオフにします。

これで、有効期限のないサービスアカウントユーザーのパーソナルアクセストークンを作成できます。

## アクセストークンを無効にする {#disable-access-tokens}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/436991) `Disable access tokens`設定。

{{< /history >}}

前提条件: 

- 管理者アクセス権が必要です。

GitLabインスタンス全体で、ユーザーがアクセストークンで認証するのを防ぐことができます。この設定は、パーソナルアクセストークン、グループアクセストークン、プロジェクトアクセストークン、および代理トークンに影響します。この設定は、サービスアカウントのパーソナルアクセストークンにも適用されます。

アクセストークンを無効にすると、次のルールが適用されます:

- ユーザーはパーソナルアクセストークンを使用してGitLabにサインインできません。
- パーソナルアクセストークンページは、`404 Not Found`エラーを返します。
- RSS、Atom、およびカレンダーフィードのフィードトークンは機能しなくなります。
- パーソナルアクセストークンで認証するされたAPIリクエストは拒否されます。

インスタンスのアクセストークンを無効にするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **アクセストークンを無効にする**チェックボックスを選択します。
1. **変更を保存**を選択します。

アプリケーション設定APIで[`disable_personal_access_tokens`属性](../../api/settings.md#available-settings)を使用することもできます。

## エンタープライズユーザーのパーソナルアクセストークンを無効にする {#disable-personal-access-tokens-for-enterprise-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.11で`enterprise_disable_personal_access_tokens`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)されました。デフォルトでは無効になっています。
- GitLab 17.2の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)になりました。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)になりました。機能フラグ`enterprise_disable_personal_access_tokens`は削除されました。

{{< /history >}}

前提条件: 

- エンタープライズユーザーが所属するグループのオーナーロール。

グループの[エンタープライズユーザー](../enterprise_user/_index.md)のパーソナルアクセストークンを無効にすると、次のようになります。

- エンタープライズユーザーは新しいパーソナルアクセストークンを作成できなくなります。この動作は、エンタープライズユーザーがグループ管理者である場合でも適用されます。
- エンタープライズユーザーの既存のパーソナルアクセストークンが無効になります。

> [!warning]
> エンタープライズユーザーのパーソナルアクセストークンを無効にしても、[サービスアカウント](service_accounts.md)のパーソナルアクセストークンは無効になりません。

エンタープライズユーザーのパーソナルアクセストークンは、次の手順で無効にできます。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **エンタープライズのユーザー**で、**パーソナルアクセストークンを無効にする**を選択します。
1. **変更を保存**を選択します。

エンタープライズユーザーアカウントを削除またはブロックすると、そのユーザーのパーソナルアクセストークンは自動的に取り消されます。

## パーソナルアクセストークンでDPoPを使用する {#use-dpop-with-personal-access-tokens}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.10で`dpop_authentication`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181053)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

Demonstrating Proof of Possession（DPoP、所有証明の実証）は、パーソナルアクセストークンのセキュリティを強化し、意図しないトークンの漏洩の影響を最小限に抑えます。アカウントでこの機能を有効にすると、PATを含むすべてのRESTおよびGraphQL APIリクエストで、署名付きDPoPヘッダーも提供する必要が生じます。署名付きDPoPヘッダーを作成するには、対応する秘密SSHキーが必要です。

> [!note]
> この機能を有効にすると、有効なDPoPヘッダーのないすべてのAPIリクエストは`DpopValidationError`エラーを返します。
>
> アクセストークンを含むHTTPS経由のGitオペレーションでは、DPoPヘッダーは必須ではありません。

前提条件: 

- [少なくとも1つの公開SSHキーをアカウントに追加](../ssh.md#add-an-ssh-key-to-your-gitlab-account)します。**署名**、または**認証と署名**の**使用タイプ**を設定する必要があります。
  - SSHキータイプはRSAである必要があります。
- GitLabアカウント用に[GitLab CLI](../../editor_extensions/gitlab_cli/_index.md)をインストールして設定する必要があります。

RESTおよびGraphQL APIへのすべての呼び出しで、DPoPを要求するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。
1. **Demonstrating Proof of Possession (DPoP)の使用**セクションに移動し、**DPoPを有効にする**を選択します。
1. **変更を保存**を選択します。
1. ターミナルで次のコマンドを実行して、[GitLab CLI](../../editor_extensions/gitlab_cli/_index.md)でDPoPヘッダーを生成します。`<your_access_token>`をアクセストークンに、`~/.ssh/id_rsa`を秘密キーの場所に置き換えます。

   ```shell
    glab auth dpop-gen --pat "<your_access_token>" --private-key ~/.ssh/id_rsa
   ```

CLIで生成したDPoPヘッダーは、以下のように使用できます。

- REST APIでの使用:

  ```shell
  curl --header "PRIVATE-TOKEN: <your_access_token>" \
    --header "DPoP: <dpop-from-glab>" \
    "https://gitlab.example.com/api/v4/projects"
  ```

- GraphQLでの使用:

  ```shell
   curl --request POST \
   --header "Content-Type: application/json" \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --header "DPoP: <dpop-from-glab>" \
   --data '{
   "query": "query { currentUser { id } }"
   }' \
   "https://gitlab.example.com/api/graphql"
  ```

DPoPの詳細については、ブループリント[送信者制約パーソナルアクセストークン](https://gitlab.com/gitlab-com/gl-security/product-security/appsec/security-feature-blueprints/-/tree/main/sender_constraining_access_tokens)を参照してください。

## プログラムを利用してパーソナルアクセストークンを作成する {#create-a-personal-access-token-programmatically}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

テストまたは自動化の一環として、事前に決定されたパーソナルアクセストークンを作成できます。

前提条件: 

- GitLabインスタンスで[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)を実行するための十分なアクセス権が必要です。

プログラムを利用してパーソナルアクセストークンを作成する手順は次のとおりです。

1. Railsコンソールを開きます。

   ```shell
   sudo gitlab-rails console
   ```

1. 次のコマンドを実行して、ユーザー名、トークン、スコープを参照します。

   トークンは20文字の長さでなければなりません。スコープは有効である必要があり、[ソースコード](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/auth.rb)で表示できます。

   たとえば、ユーザー名が`automation-bot`のユーザーに属し、1年後に期限切れになるトークンは、次のコマンドで作成できます。

   ```ruby
   user = User.find_by_username('automation-bot')
   token = user.personal_access_tokens.create(scopes: ['read_user', 'read_repository'], name: 'Automation token', expires_at: 365.days.from_now)
   token.set_token('token-string-here123')
   token.save!
   ```

このコードは、[Rails runner](../../administration/operations/rails_console.md#using-the-rails-runner)を使用して、単一行のシェルコマンドに短縮できます。

```shell
sudo gitlab-rails runner "token = User.find_by_username('automation-bot').personal_access_tokens.create(scopes: ['read_user', 'read_repository'], name: 'Automation token', expires_at: 365.days.from_now); token.set_token('token-string-here123'); token.save!"
```

## プログラムを利用してパーソナルアクセストークンを取り消す {#revoke-a-personal-access-token-programmatically}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

テストまたは自動化の一環として、プログラムを利用してパーソナルアクセストークンを取り消すことができます。

前提条件: 

- GitLabインスタンスで[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)を実行するための十分なアクセス権が必要です。

プログラムを利用してトークンを取り消す手順は次のとおりです。

1. Railsコンソールを開きます。

   ```shell
   sudo gitlab-rails console
   ```

1. 次のコマンドを実行して、`token-string-here123`のトークンを取り消します。

   ```ruby
   token = PersonalAccessToken.find_by_token('token-string-here123')
   token.revoke!
   ```

このコードは、[Rails runner](../../administration/operations/rails_console.md#using-the-rails-runner)を使用して、単一行のシェルコマンドに短縮できます。

```shell
sudo gitlab-rails runner "PersonalAccessToken.find_by_token('token-string-here123').revoke!"
```

## パーソナルアクセストークンを使用してリポジトリをクローンする {#clone-repository-using-personal-access-token}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

SSHが無効になっている場合にリポジトリをクローンするには、次のコマンドを実行してパーソナルアクセストークンを使用してクローンします。

```shell
git clone https://<username>:<personal_token>@gitlab.com/gitlab-org/gitlab.git
```

この方法では、パーソナルアクセストークンがbashの履歴に保存されます。これを回避するには、次のコマンドを実行します。

```shell
git clone https://<username>@gitlab.com/gitlab-org/gitlab.git
```

`https://gitlab.com`のパスワードを求められたら、パーソナルアクセストークンを入力します。

`clone`コマンドの`username`は、次の条件を満たす必要があります。

- 任意の文字列を指定できます。
- 空の文字列は使用できません。

認証に依存する自動化パイプラインを設定する場合は、この条件を必ず守ってください。

## パーソナルアクセストークンの代替 {#alternatives-to-personal-access-tokens}

HTTPS経由のGitの場合、パーソナルアクセストークンの代替として、OAuth認証ヘルパーを使用できます。

CI/CDジョブでの認証には、以下を考慮してください:

- パイプライン認証のための、[CI/CDジョブトークン](../../ci/jobs/ci_job_token.md)と[きめ細かい権限](../../ci/jobs/fine_grained_permissions.md)。
- プロジェクト固有の自動化のための、最小限の必要な権限を持つ[プロジェクトアクセストークン](../project/settings/project_access_tokens.md)。

## 関連トピック {#related-topics}

- [グループアクセストークン](../group/settings/group_access_tokens.md)
- [プロジェクトアクセストークン](../project/settings/project_access_tokens.md)
- [パーソナルアクセストークンAPI](../../api/personal_access_tokens.md)
- [きめ細かいパーソナルアクセストークンをサポートするREST APIエンドポイント](../../auth/tokens/fine_grained_access_tokens.md)
