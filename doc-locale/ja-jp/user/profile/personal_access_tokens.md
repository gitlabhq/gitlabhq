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
> [2要素認証](account/two_factor_authentication.md)または[SAML](../../integration/saml.md#password-generation-for-users-created-through-saml)が有効になっている場合は、パーソナルアクセストークンで認証する必要があります。

[GitLabマネージドTerraformステートバックエンド](../infrastructure/iac/terraform_state.md#use-your-gitlab-backend-as-a-remote-data-source)や[コンテナレジストリ](../packages/container_registry/authenticate_with_container_registry.md)など、ユーザー名を必要とする一部のGitLab機能では、GitLabユーザー名とパーソナルアクセストークンを使用します。これらのケースでは、ユーザー名は必須ですが、認証の一部として評価されません。詳細については、[イシュー212953](https://gitlab.com/gitlab-org/gitlab/-/issues/212953)を参照してください。

GitLab Self-ManagedおよびGitLab Dedicatedインスタンスでは、管理者は[ユーザートークンAPI](../../api/user_tokens.md#create-an-impersonation-token)を使用して、特定のユーザーとして認証するための代理トークンを作成できます。

## パーソナルアクセストークンを作成する {#create-a-personal-access-token}

{{< history >}}

- `buffered_token_expiration_limit`という名前の[機能フラグ](../../administration/feature_flags/list.md)により、GitLab 17.6で最大許容ライフタイム制限が[400日に延長されました](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)。デフォルトでは無効になっています。
- パーソナルアクセストークンの説明は、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)されました。

{{< /history >}}

> [!flag]
> 延長された最大許容ライフタイム制限の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

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
1. 1つまたは複数の[パーソナルアクセストークンのスコープ](../../security/tokens/access_token_scopes.md)を選択します。
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

## アクセストークンで認証する {#authenticate-with-an-access-token}

アクセストークンを使用して、GitLab REST API、HTTPS経由のGit、およびGitLabと統合するサードパーティツールで認証します。

### REST APIを使用する {#use-rest-api}

あなたのトークンを`PRIVATE-TOKEN`ヘッダーに渡します:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects"
```

詳細については、[REST API認証](../../api/rest/authentication.md#personal-project-and-group-access-tokens)を参照してください。

### HTTPS経由でGitを使用する {#use-git-over-https}

Gitが認証情報を要求したときに、あなたのトークンをパスワードとして使用します:

- ユーザー名: 空でない任意の文字列（GitLabはこの値を検証しません）。
- パスワード: あなたのパーソナルアクセストークン。

例: 

```shell
git clone https://oauth2:<your_access_token>@gitlab.example.com/gitlab-org/gitlab.git
```

### サードパーティツールとIDE拡張機能を使用する {#use-third-party-tools-and-ide-extensions}

GitLabと統合するIDE拡張機能、CI/CDツール、自動化スクリプトなどのツールは、認証のためにパーソナルアクセストークンを受け入れます。各ツールに関するドキュメントを参照してください:

- [GitLab CLI（`glab`）](../../editor_extensions/gitlab_cli/_index.md)
- [VS Code用GitLab Workflow拡張機能](../../editor_extensions/visual_studio_code/_index.md)
- [JetBrains IDE用のGitLabプラグイン](../../editor_extensions/jetbrains_ide/_index.md)

CI/CDパイプラインには、代わりに[CI/CDジョブトークン](../../ci/jobs/ci_job_token.md)が推奨されます。

パーソナルアクセストークンのセキュリティガイダンスについては、[トークンのセキュリティに関する考慮事項](../../security/tokens/_index.md#security-considerations)を参照してください。

## トークンの使用状況情報を表示する {#view-token-usage-information}

{{< history >}}

- `pat_ip`という名前の[機能フラグ](../../administration/feature_flags/_index.md)により、IPアドレスを表示する機能がGitLab 17.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/428577)。17.9ではデフォルトで有効になっています。
- IPアドレスを表示する機能は、GitLab 17.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/513302)になりました。機能フラグ`pat_ip`は削除されました。

{{< /history >}}

パーソナルアクセストークンページには、アクセストークンに関する情報が表示されます。

このページから、以下の操作を実行できます:

- パーソナルアクセストークンの作成、ローテーション、および失効。
- アクティブおよび非アクティブなすべてのパーソナルアクセストークンを表示します。
- トークン情報（スコープ、割り当てられたロール、有効期限を含む）を表示します。
- 使用状況の情報（使用日、および最後の5つの異なる接続IPアドレスを含む）を表示します。
  > [!note]
  > GitLabは、トークンがGit操作を実行したり、[REST](../../api/rest/_index.md)または[GraphQL](../../api/graphql/_index.md) APIで操作を認証するときに、トークンの使用状況情報を定期的に更新します。トークンの使用時間は10分ごとに、トークン使用IPアドレスは1分ごとに更新されます。

パーソナルアクセストークンを表示するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。

詳細パネルを開くには、トークンの名前を選択します。デフォルトでは、アクティブなトークンのみが表示されます。検索バーを使用して、アクセストークンのリストをフィルタリングします。

## パーソナルアクセストークンをローテーションする {#rotate-a-personal-access-token}

{{< history >}}

- UIを使用してパーソナルアクセストークンをローテーションする機能は、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/241523)されました。
- GitLab 18.1で[UI](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194582)を更新しました。

{{< /history >}}

トークンをローテーションして、元のトークンと同じ権限とスコープを持つ新しいトークンを作成します。元のトークンは直ちに無効になり、GitLabは監査目的で両方のバージョンを保持します。

> [!warning]
> この操作は元に戻せません。ローテーションされたアクセストークンに依存するツールは、新しいトークンを参照するまで機能しなくなります。

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
> この操作は元に戻せません。失効したアクセストークンに依存するツールは、新しいトークンを追加するまで機能しなくなります。

パーソナルアクセストークンを失効するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。
1. アクティブなトークンの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **取り消し**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**取り消し**を選択します。

## アクセストークンの有効期限 {#access-token-expiration}

パーソナルアクセストークン、グループアクセストークン、およびプロジェクトアクセストークンは、有効期限のUTC深夜に期限が切れます。期限切れになると、それらはリクエストを認証するために使用できなくなります。

新しいアクセストークンには、有効期限を設定する必要があります。有効期限がトークン作成時に明示的に設定されていない場合、今日から365日間の有効期限が適用されます。Ultimateでは、管理者はアクセストークンの[最大許容ライフタイム](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)を設定できます。

あなたのGitLabバージョンと提供内容によっては、GitLabバージョンのアップグレード時に既存のアクセストークンに有効期限が自動的に適用される場合があります。詳細については、[期限切れにならないアクセストークン](../../update/deprecations.md#non-expiring-access-tokens)を参照してください。

### パーソナルアクセストークンの有効期限に関するメール {#personal-access-token-expiry-emails}

{{< history >}}

- `expiring_pats_30d_60d_notifications`という名前の[機能フラグ](../../administration/feature_flags/_index.md)により、GitLab 17.6で60日および30日間の有効期限通知が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)。デフォルトでは無効になっています。
- 60日前と30日前の通知は、GitLab 17.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792)になりました。機能フラグ`expiring_pats_30d_60d_notifications`は削除されました。

{{< /history >}}

GitLabは、まもなく有効期限が切れるパーソナルアクセストークンを特定するために、毎日UTC午前1:00にチェックを実行します。トークンの有効期限が切れる7日前に、ユーザーにメールで通知されます。GitLab 17.6以降では、トークンの期限が切れる30日前と60日前にも通知が送信されます。

### パーソナルアクセストークンの有効期限カレンダー {#personal-access-token-expiry-calendar}

各トークンの有効期限にイベントが設定されたiCalendarエンドポイントをサブスクライブできます。サインイン後、このエンドポイントは`/-/user_settings/personal_access_tokens.ics`で利用できます。

### 有効期限のないサービスアカウントのパーソナルアクセストークンを作成する {#create-a-service-account-personal-access-token-with-no-expiry-date}

有効期限のない[サービスアカウントのパーソナルアクセストークンを作成](../../api/service_accounts.md#create-a-personal-access-token-for-a-group-service-account)できます。これらのパーソナルアクセストークンは、通常のアカウントのパーソナルアクセストークンとは異なり、有効期限切れになることはありません。

> [!note]
> 有効期限なしでサービスアカウント用のパーソナルアクセストークンを作成できるようにすることは、この設定を変更した後に作成されたトークンにのみ影響します。既存のトークンには影響しません。

#### GitLab.com {#gitlabcom}

前提条件: 

- トップレベルグループのオーナーロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **パーソナルアクセストークン**の下で、**サービスアカウントに有効期限を設定する**チェックボックスをオフにします。

これで、有効期限のないサービスアカウントユーザーのパーソナルアクセストークンを作成できます。

#### GitLab Self-Managed {#gitlab-self-managed}

前提条件: 

- GitLab Self-Managedインスタンスの管理者である必要があります。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **サービスアカウントトークンの有効期限**チェックボックスをオフにします。

これで、有効期限のないサービスアカウントユーザーのパーソナルアクセストークンを作成できます。

## パーソナルアクセストークンを使用してリポジトリをクローンする {#clone-repository-using-personal-access-token}

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

## アクセストークンを無効にする {#disable-access-tokens}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/436991) `Disable access tokens`設定。

{{< /history >}}

前提条件: 

- 管理者アクセス権。

GitLabインスタンス全体で、ユーザーがアクセストークンで認証するのを防ぐことができます。この設定は、パーソナルアクセストークン、グループアクセストークン、プロジェクトアクセストークン、および代理トークンに影響します。この設定は、サービスアカウントのパーソナルアクセストークンにも適用されます。

アクセストークンを無効にすると、次のルールが適用されます:

- ユーザーはパーソナルアクセストークンを使用してGitLabにサインインできません。
- パーソナルアクセストークンページは、`404 Not Found`エラーを返します。
- RSS、Atom、およびカレンダーフィードのフィードトークンは機能しなくなります。
- パーソナルアクセストークンで認証されたAPIリクエストは拒否されます。

インスタンスのアクセストークンを無効にするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
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

- GitLab 16.11で`enterprise_disable_personal_access_tokens`[機能フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)されました。デフォルトでは無効になっています。
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
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **エンタープライズのユーザー**で、**パーソナルアクセストークンを無効にする**を選択します。
1. **変更を保存**を選択します。

エンタープライズユーザーアカウントを削除またはブロックすると、そのユーザーのパーソナルアクセストークンは自動的に取り消されます。

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

## パーソナルアクセストークンでDPoPを使用する {#use-dpop-with-personal-access-tokens}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- `dpop_authentication`という名前の[機能フラグ](../../administration/feature_flags/_index.md)により、GitLab 17.10で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181053)。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

Demonstrating Proof of Possession（DPoP、所有証明の実証）は、パーソナルアクセストークンのセキュリティを強化し、意図しないトークンの漏洩の影響を最小限に抑えます。アカウントでこの機能を有効にすると、PATを含むすべてのRESTおよびGraphQL APIリクエストで、署名付きDPoPヘッダーも提供する必要が生じます。署名付きDPoPヘッダーを作成するには、対応する秘密SSHキーが必要です。

> [!note]
> この機能を有効にすると、有効なDPoPヘッダーを持たないすべてのAPIリクエストは`DpopValidationError`エラーを返します。
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
1. **Demonstrating Proof of Possession（DPoP）の使用**セクションに移動し、**DPoPを有効にする**を選択します。
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

## パーソナルアクセストークンの代替 {#alternatives-to-personal-access-tokens}

HTTPS経由のGitの場合、パーソナルアクセストークンの代替として、OAuth認証ヘルパーを使用できます。

CI/CDジョブでの認証には、以下を考慮してください:

- パイプライン認証のための、[CI/CDジョブトークン](../../ci/jobs/ci_job_token.md)と[きめ細かい権限](../../ci/jobs/fine_grained_permissions.md)。
- プロジェクト固有の自動化のための、最小限の必要な権限を持つ[プロジェクトアクセストークン](../project/settings/project_access_tokens.md)。

## 関連トピック {#related-topics}

- [グループアクセストークン](../group/settings/group_access_tokens.md)
- [プロジェクトアクセストークン](../project/settings/project_access_tokens.md)
- [パーソナルアクセストークンAPI](../../api/personal_access_tokens.md)
- [詳細権限パーソナルアクセストークン](../../auth/tokens/fine_grained_access_tokens.md)
- [Permissions Assistant](../duo_agent_platform/agents/foundational_agents/permissions_assistant.md)（GitLab Duoのエージェント）は、トークン作成時にきめ細やかな権限を選択するのに役立ちます。
