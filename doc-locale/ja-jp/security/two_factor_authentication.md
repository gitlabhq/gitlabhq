---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 2要素認証を適用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[2要素認証（2FA）](../user/profile/account/two_factor_authentication.md)は、ユーザーが本人確認のために2つの異なる要素を提供する必要がある認証方法です:

- ユーザー名とパスワード。
- アプリケーションによって生成されたコードなど、2番目の認証方法。

2FAを使用すると、不正な人物がアカウントにアクセスすることが困難になります。両方の要素が必要になるためです。

{{< alert type="note" >}}

[SSOを使用して実施している](../user/group/saml_sso/_index.md#sso-enforcement)場合、IDプロバイダー（IdP）側で2FAをすでに実施している可能性があります。GitLabでも2FAを実施する必要はないかもしれません。

{{< /alert >}}

## すべてのユーザーに2FAを実施する {#enforce-2fa-for-all-users}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

管理者は、次の2つの異なる方法で、すべてのユーザーに2FAを実施できます:

- 次回のサインイン時に実施。
- 次回のサインイン時に推奨しますが、実施する前に猶予期間を設けます。

  設定された猶予期間が経過すると、ユーザーはサインインできますが、`/-/profile/two_factor_auth`の2FA設定エリアから移動できません。

すべてのユーザーに2FAを実施するには、UIまたはAPIを使用できます。

### UIを使用する {#use-the-ui}

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **サインインの制限**を展開します:
   - **2要素認証を実施する**を選択して、この機能フラグを有効にします。
   - **2要素認証の猶予期間**に、時間数を入力します。次回のサインイン時に2FAを実施する場合は、`0`を入力します。

### APIを使用する {#use-the-api}

[アプリケーション設定API](../api/settings.md)を使用して、次の設定を変更します:

- `require_two_factor_authentication`。
- `two_factor_grace_period`。

詳細については、[APIコール](../api/settings.md#available-settings)を通じてアクセスできる設定の一覧を参照してください。

## 管理者ユーザーに2FAを実施する {#enforce-2fa-for-administrator-users}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/427549)されました。
- カスタム管理者ロールを持つ一般ユーザーに対する2FAの実施のサポートは、GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/556110)されました。

{{< /history >}}

管理者は、次の両方に対して2FAを実施できます:

- 管理者ユーザー。
- [カスタム管理者ロール](../user/custom_roles/_index.md)が割り当てられている一般ユーザー。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **サインインの制限**セクションを展開します:
   1. **管理者に2FAの有効化を必須とする**を選択します。
   1. **2要素認証の猶予期間**に、時間数を入力します。次回のサインイン時に2FAを実施する場合は、`0`を入力します。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

外部プロバイダーを使用してGitLabにサインインしている場合、この設定はユーザーに2FAを**not**（実施しません）。2FAはその外部プロバイダーで有効にする必要があります。

{{< /alert >}}

## グループ内のすべてのユーザーに2FAを実施する {#enforce-2fa-for-all-users-in-a-group}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループまたはサブグループ内のすべてのユーザーに2FAを実施できます。

{{< alert type="note" >}}

2FAの実施は、[直接および継承されたメンバー](../user/project/members/_index.md#membership-types)グループのメンバーの両方に適用されます。2FAがサブグループで実施されている場合、継承されたメンバー（祖先グループのメンバー）も認証要素を登録する必要があります。

{{< /alert >}}

前提要件: 

- グループのオーナーロールを持っている必要があります。

グループに2FAを実施するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **このグループ内のすべてのユーザーは2要素認証を設定する必要があります**を選択します。
1. オプション。**2FA施行の遅延 (時間)**に、猶予期間を継続する時間数を入力します。トップレベルグループとそのサブグループおよびプロジェクトに複数の異なる猶予期間がある場合、最短の猶予期間が使用されます。
1. **変更を保存**を選択します。

アクセストークンはAPIベースであるため、2番目の認証要素を提供する必要はありません。2FAが実施される前に生成されたトークンは引き続き有効です。

GitLabの[受信メール](../administration/incoming_email.md)機能は、2FAの実施に従いません。ユーザーは、最初に2FAを使用して認証しなくても、イシューの作成やマージリクエストへのコメントなどの受信メール機能を使用できます。これは、2FAが実施されている場合でも適用されます。

### サブグループの2FA {#2fa-in-subgroups}

デフォルトでは、各サブグループは、親グループとは異なる可能性のある2FA要件を設定できます。

{{< alert type="note" >}}

継承されたメンバーには、階層の上位レベルで適用される異なる2FA要件が適用されている場合もあります。このような場合、最も制限の厳しい要件が優先されます。

{{< /alert >}}

サブグループが個別の2FA要件を設定できないようにするには:

1. トップレベルグループの**設定** > **一般**に移動します。
1. **権限とグループ機能**セクションを展開します。
1. **Allow subgroups to set up their own two-factor authentication rule**（サブグループが独自の2要素認証ルールを設定できるようにする） チェックボックスをオフにします。

### プロジェクトの2FA {#2fa-in-projects}

2FAを有効または実施するグループに属するプロジェクトが、2FAを有効または実施しないグループと[共有](../user/project/members/sharing_projects_groups.md)されている場合、非2FAグループのメンバーは2FAを使用せずにそのプロジェクトにアクセスできます。例: 

- グループAは2FAが有効で、実施されています。グループBは2FAが有効になっていません。
- グループAに属するプロジェクトPがグループBと共有されている場合、グループBのメンバーは2FAなしでプロジェクトPにアクセスできます。

これを防ぐには、2FAグループの[プロジェクトの共有を禁止](../user/project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups)します。

{{< alert type="warning" >}}

2FAが有効になっているグループまたはサブグループのプロジェクトにメンバーを追加する場合、個々に追加されたメンバーには2FAは**not**（不要）です。

{{< /alert >}}

## 2FAを無効にする {#disable-2fa}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

単一のユーザーまたはすべてのユーザーに対して2FAを無効にできます。

この操作は永続的であり、元に戻すことはできません。ユーザーが2FAを再度使用するには、2FAを再度アクティブ化する必要があります。

{{< alert type="warning" >}}

ユーザーの2FAを無効にしても、[すべてのユーザーに2FAを実施する](#enforce-2fa-for-all-users)または[グループ内のすべてのユーザーに2FAを実施する](#enforce-2fa-for-all-users-in-a-group)設定は無効になりません。ユーザーが次にGitLabにサインインするときに2FAの設定を再度求められないようにするには、実施された2FA設定もすべて無効にする必要があります。

{{< /alert >}}

### すべてのユーザー向け {#for-all-users}

強制2FAが無効になっている場合でも、すべてのユーザーに対して2FAを無効にするには、次のRakeタスクを使用します。

- Linuxパッケージを使用するインストールの場合:

  ```shell
  sudo gitlab-rake gitlab:two_factor:disable_for_all_users
  ```

- 自己コンパイルによるインストールの場合: 

  ```shell
  sudo -u git -H bundle exec rake gitlab:two_factor:disable_for_all_users RAILS_ENV=production
  ```

### 単一ユーザーの場合 {#for-a-single-user}

#### 管理者 {#administrators}

[Railsコンソール](../administration/operations/rails_console.md)を使用して、単一の管理者に対して2FAを無効にすることができます:

```ruby
admin = User.find_by_username('<USERNAME>')
user_to_disable = User.find_by_username('<USERNAME>')

TwoFactor::DestroyService.new(admin, user: user_to_disable).execute
```

管理者に2FAが無効になったことが通知されます。

#### 非管理者 {#non-administrators}

Railsコンソールまたは[APIエンドポイント](../api/users.md#disable-two-factor-authentication-for-a-user)を使用して、非管理者の2FAを無効にできます。

自分のアカウントの2FAを無効にすることができます。

管理者の2FAを無効にするためにエンドポイントを使用することはできません。

#### エンタープライズユーザー {#enterprise-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

トップレベルグループのオーナーは、エンタープライズユーザーの2要素認証（2FA）を無効にできます。

2FAを無効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **管理** > **メンバー**を選択します。
1. **エンタープライズ**バッジと**2FA**バッジが付いているユーザーを探します。
1. **追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択し、**二要素認証の無効化**を選択します。

エンタープライズユーザー（グループのメンバーでなくなったエンタープライズユーザーを含む）の2FAを無効にするには、[APIを使用](../api/group_enterprise_users.md#disable-two-factor-authentication-for-an-enterprise-user)することもできます。

## SSH操作によるGitの2FA {#2fa-for-git-over-ssh-operations}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="flag" >}}

デフォルトでは、この機能フラグは使用できません。管理者が`two_factor_for_cli`という名前の[機能フラグを有効にする](../administration/feature_flags/_index.md)と、この機能を使用できるようになります。この機能は本番環境での使用には対応していません。この機能フラグは、[2FAが有効になっている場合のGit操作のセッション時間](../administration/settings/account_and_limit_settings.md#customize-session-duration-for-git-operations-when-2fa-is-enabled)にも影響します。

{{< /alert >}}

SSH操作によるGitに2FAを実施できます。ただし、代わりに[ED25519_SK](../user/ssh.md#ed25519_sk-ssh-keys)または[ECDSA_SK](../user/ssh.md#ecdsa_sk-ssh-keys) SSHキーを使用する必要があります。2FAはGit操作にのみ実施され、`personal_access_token`などのGitLab Shellからの内部コマンドは除外されます。

ワンタイムパスワード（OTP）検証を実行するには、次を実行します:

```shell
ssh git@<hostname> 2fa_verify
```

次に、次のいずれかで認証します:

- 正しいOTPを入力します。
- [FortiAuthenticatorが有効になっている](../user/profile/account/two_factor_authentication.md#enable-a-one-time-password-authenticator-using-fortiauthenticator)場合、デバイスプッシュ通知に応答します。

認証に成功すると、関連付けられたSSHキーを使用して、15分間（デフォルト）Git over SSH操作を実行できます。

### セキュリティ上の制限事項 {#security-limitation}

2FAは、侵害されたプライベートSSHキーを持つユーザーを保護しません。

OTPが検証されると、設定された[セッション時間](../administration/settings/account_and_limit_settings.md#customize-session-duration-for-git-operations-when-2fa-is-enabled)の間、誰でもそのプライベートSSHキーを使用してGit over SSHを実行できます。
