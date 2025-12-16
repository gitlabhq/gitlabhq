---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: サインインの制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

サインインの制限を使用して、WebインターフェースおよびHTTP(S)経由のGitの認証制限をカスタマイズします。

## 設定 {#settings}

サインイン制限設定にアクセスするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **サインインの制限**セクションを展開します。

## パスワード認証が有効 {#password-authentication-enabled}

WebインターフェースおよびHTTP(S)経由のGitのパスワード認証を制限できます:

- **Web interface**（Webインターフェース）: この機能が無効になっている場合、**標準**サインインタブが削除され、[外部認証プロバイダー](../auth/_index.md)を使用する必要があります。
- **Git over HTTP(S)**（Git over HTTP(S)）: この機能が無効になっている場合は、[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)またはLDAPパスワードを使用して認証する必要があります。

外部認証プロバイダーの停止が発生した場合、[GitLab Railsコンソール](../operations/rails_console.md)を使用して、[標準のWebサインインフォームを再度有効](#re-enable-standard-web-sign-in-form-in-rails-console)にします。この設定は、管理者アカウントのパーソナルアクセストークンで認証中に、[アプリケーション設定REST API](../../api/settings.md#update-application-settings)を介して変更することもできます。

### SSO識別子を使用するユーザーのパスワード認証を無効にする {#disable-password-authentication-for-users-with-an-sso-identity}

パスワード認証が有効になっている場合でも、SSOユーザーがパスワードでサインインする機能を制限することが望ましい場合があります。**SSO識別子を使用するユーザーのパスワード認証を無効にします。**を選択して、SSOユーザーが常に外部プロバイダーでサインインするようにします。

これにより、WebインターフェースとHTTP(S)経由のGitの両方のパスワード認証が制限されます。

## 管理者モード {#admin-mode}

管理者の場合は、管理者アクセスなしでGitLabで作業したい場合があります。管理者アクセス権を持たない別のユーザーアカウントを作成するか、管理者モードを使用することができます。

管理者モードでは、デフォルトでは、アカウントに管理者アクセス権はありません。メンバーになっているグループやプロジェクトへのアクセスは継続できます。ただし、管理タスクの場合、（[特定の機能](#known-issues)を除き）認証する必要があります。

管理者モードが有効になっている場合、インスタンス上のすべての管理者に適用されます。

管理者モードがインスタンスに対して有効になっている場合、管理者は以下を行います:

- メンバーであるグループおよびプロジェクトへのアクセスを許可されます。
- **管理者**エリアにアクセスできません。

### インスタンスの管理者モードを有効にする {#enable-admin-mode-for-your-instance}

管理者は、API、Railsコンソール、またはUIから管理者モードを有効にできます。

#### APIを使用して管理者モードを有効にする {#use-the-api-to-enable-admin-mode}

インスタンスエンドポイントに次のリクエストを行います:

```shell
curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab.example.com>/api/v4/application/settings?admin_mode=true"
```

`<gitlab.example.com>`をインスタンスのURLに置き換えます。

詳細については、[APIコールを介してアクセスできる設定のリスト](../../api/settings.md)を参照してください。

#### Railsコンソールを使用して管理者モードを有効にする {#use-the-rails-console-to-enable-admin-mode}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

[Railsコンソール](../operations/rails_console.md)を開き、以下を実行します:

```ruby
::Gitlab::CurrentSettings.update!(admin_mode: true)
```

#### UIを使用して管理者モードを有効にする {#use-the-ui-to-enable-admin-mode}

UIから管理者モードを有効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **サインインの制限**を展開します。
1. **管理者モードを有効にする**を選択します。
1. **変更を保存**を選択します。

### セッションの管理者モードをオンにする {#turn-on-admin-mode-for-your-session}

現在のセッションの管理者モードをオンにして、潜在的に危険なリソースにアクセスするには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **管理者モードにする**を選択します。
1. URLに`/admin`が含まれるUIの任意の部分にアクセスしてみてください（管理者アクセスが必要です）。

管理者モードステータスが無効またはオフになっている場合、管理者は明示的にアクセス権が付与されていない限り、リソースにアクセスできません。たとえば、管理者がプライベートグループまたはプロジェクトを開こうとすると、そのグループまたはプロジェクトのメンバーでない限り、`404`エラーが発生します。

管理者は2要素認証を有効にする必要があります。2FA、OmniAuthプロバイダー、およびLDAP認証は管理者モードでサポートされています。管理者モードステータスは現在のユーザーセッションに保存され、次のいずれかになるまでアクティブなままです:

- 明示的に無効になっている。
- 6時間後に自動的に無効になる。

### セッションで管理者モードが有効になっているかどうかを確認する {#check-if-your-session-has-admin-mode-enabled}

{{< history >}}

- GitLab 16.10で`show_admin_mode_within_active_sessions`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438674)されました。デフォルトでは無効になっています。
- GitLab 16.10の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/444188)で有効になりました。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/438674)になりました。機能フラグ`show_admin_mode_within_active_sessions`は削除されました。

{{< /history >}}

アクティブなセッションのリストに移動します:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アクティブなセッション**を選択します。

管理者モードがオンになっているセッションには、**Signed in on `date of session` with Admin Mode**（に管理者モードでサインイン）というテキストが表示されます。

### セッションの管理者モードをオフにする {#turn-off-admin-mode-for-your-session}

現在のセッションの管理者モードをオフにするには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **管理者モードを終了する**を選択します。

### 既知の問題 {#known-issues}

管理者モードは6時間後にタイムアウトになり、このタイムアウト制限を変更することはできません。

次のアクセス方法は管理者モードによって保護されていません:

- Gitクライアントアクセス（公開キーを使用したSSH、またはパーソナルアクセストークンを使用したHTTPS）。

つまり、管理者モードによって制限されている管理者は、追加の認証手順なしでGitクライアントを使用できます。

GitLabREST APIまたはGraphQL APIを使用するには、管理者は、[パーソナルアクセストークンを作成](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)するか、[OAuthトークン](../../api/oauth2.md)を[`admin_mode`スコープ](../../user/profile/personal_access_tokens.md#personal-access-token-scopes)で作成する必要があります。

`admin_mode`スコープを持つパーソナルアクセストークンを持つ管理者が管理者アクセス権を失った場合、そのユーザーは`admin_mode`スコープを持つトークンをまだ持っていても、管理者としてAPIにアクセスできません。詳細については、[エピック2158](https://gitlab.com/groups/gitlab-org/-/epics/2158)を参照してください。

また、GitLab Geoが有効になっている場合、セカンダリノード上にある間は、プロジェクトと設計のレプリケーションステータスを表示できません。プロジェクト（[イシュー367926](https://gitlab.com/gitlab-org/gitlab/-/issues/367926) ）と設計（[イシュー355660](https://gitlab.com/gitlab-org/gitlab/-/issues/355660)）が新しいGeoフレームワークに移行すると、修正が提案されます。

### トラブルシューティング管理者モード {#troubleshooting-admin-mode}

必要に応じて、次の2つの方法のいずれかを使用して、管理者として**管理者モード**を無効にできます:

- API: 

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?admin_mode=false"
  ```

- [Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update!(admin_mode: false)
  ```

## 2要素認証 {#two-factor-authentication}

この機能が有効になっている場合、すべてのユーザーが[2要素認証](../../user/profile/account/two_factor_authentication.md)を使用する必要があります。

2要素認証が必須として構成された後、ユーザーは、設定可能な猶予時間（時間単位）の間、2要素認証の強制設定をスキップできます。

![2要素認証の猶予期間は48時間に設定されています。](img/two_factor_grace_period_v12_5.png)

## 不明なサインインのメール通知 {#email-notification-for-unknown-sign-ins}

有効にすると、GitLabは不明なIPアドレスまたはデバイスからのサインインをユーザーに通知します。詳細については、[メール通知（不明なサインインの場合）](../../user/profile/notifications.md#notifications-for-unknown-sign-ins)を参照してください。

![メール通知が有効（不明なサインインの場合）](img/email_notification_for_unknown_sign_ins_v13_2.png)

## サインイン情報 {#sign-in-information}

{{< history >}}

- **Sign-in text**（サインインテキスト）設定はGitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/410885)になりました。

{{< /history >}}

ログインしていないすべてのユーザーは、値が空でない場合、設定された**ホームページのURL**で表されるページにリダイレクトされます。

すべてのユーザーは、値が空でない場合、サインアウト後に設定された**サインアウトページのURL**で表されるページにリダイレクトされます。

サインインページにヘルプメッセージを追加するには、[サインインページと登録ページをカスタマイズ](../appearance.md#customize-your-sign-in-and-register-pages)します。

## トラブルシューティング {#troubleshooting}

### Railsコンソールで標準Webサインインフォームを再度有効にする {#re-enable-standard-web-sign-in-form-in-rails-console}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

[サインイン制限](#password-authentication-enabled)として無効になっている場合は、標準のユーザー名とパスワードベースのサインインフォームを再度有効にします。

（SSOまたはLDAP設定による）設定された外部認証プロバイダーが停止に直面しており、GitLabへの直接サインインアクセスが必要な場合は、[Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を使用してこの方法を使用できます。

```ruby
Gitlab::CurrentSettings.update!(password_authentication_enabled_for_web: true)
```
