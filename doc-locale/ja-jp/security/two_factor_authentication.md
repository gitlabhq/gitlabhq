---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 2要素認証を適用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[2要素認証（2FA）](../user/profile/account/two_factor_authentication.md)は、ユーザーが自身の身元を証明するために2つの異なる要素を提供する認証方法です:

- ユーザー名とパスワード。
- アプリケーションによって生成されたコードなどの2番目の認証方法。

2FAは、不正なユーザーがアカウントにアクセスするのをより困難にします。両方の要素を必要とするためです。

> [!note] 
> 
> [SSO](../user/group/saml_sso/_index.md#sso-enforcement)を使用し、適用している場合、Identity Provider（IdP）側ですでに2FAを適用している可能性があります。GitLab側でも2FAを適用するのは不要な場合があります。

## すべてのユーザーに2FAを適用する {#enforce-2fa-for-all-users}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

管理者は、次の2つの方法ですべてのユーザーに2FAを適用できます:

- 次回のサインイン時に適用します。
- 次回のサインイン時に提案しますが、適用前に猶予期間を設けます。

  設定された猶予期間が経過した後、ユーザーはサインインできますが、`/-/profile/two_factor_auth`にある2FA設定エリアを離れることはできません。

UIまたはAPIを使用して、すべてのユーザーに2FAを適用できます。

### UIを使用する {#use-the-ui}

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. 展開**サインインの制限**:
   - **2要素認証を実施する**を選択して、この機能を有効にします。
   - **2要素認証の猶予期間**に、時間数を入力します。次回のサインイン試行時に2FAを適用したい場合は、`0`と入力します。

### APIを使用する {#use-the-api}

[アプリケーション設定API](../api/settings.md)を使用して、次の設定を変更します:

- `require_two_factor_authentication`。
- `two_factor_grace_period`。

詳細については、[APIコール](../api/settings.md#available-settings)を介してアクセスできる設定のリストを参照してください。

## 管理者に2FAを適用する {#enforce-2fa-for-administrators}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/427549)されました。
- カスタム管理者ロールを持つ一般ユーザーに対する2FAの適用サポートは、GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/556110)されました。

{{< /history >}}

管理者は、次の両方に2FAを適用できます:

- 管理者ユーザー。
- カスタム管理者ロールを[割り当て](../user/custom_roles/_index.md)られている一般ユーザー。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. 展開**サインインの制限**セクション:
   1. **管理者に2要素認証を適用する**を選択します。
   1. **2要素認証の猶予期間**に、時間数を入力します。次回のサインイン試行時に2FAを適用したい場合は、`0`と入力します。
1. **変更を保存**を選択します。

> [!note] 
> 
> 外部プロバイダーを使用してGitLabにサインインする場合、この設定はユーザーに対して2FAを強制**しません**。2FAはその外部プロバイダーで有効にする必要があります。

## グループ内のすべてのユーザーに2FAを適用する {#enforce-2fa-for-all-users-in-a-group}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループまたはサブグループ内のすべてのユーザーに2FAを適用できます。

2FAの適用は、[直接および継承されたメンバー](../user/project/members/_index.md#membership-types)のグループメンバーの両方に適用されます。サブグループに2FAが適用されている場合、継承されたメンバーは認証要素を登録する必要があります。継承されたメンバーは、祖先グループのメンバーです。

> [!note]
> メールOTPは2FAの要件を満たしません。メンバーは、アプリベースのTOTPまたはWebAuthnのいずれかを設定する必要があります。

前提条件: 

- グループのオーナーロールが必要です。

グループに2FAを適用するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **このグループ内のすべてのユーザーは2要素認証を設定する必要があります**を選択します。
1. （オプション）任意。**2FA施行の遅延（時間）**で、猶予期間を継続したい時間数を入力します。トップレベルグループとそのサブグループおよびプロジェクトに複数の異なる猶予期間がある場合、最も短い猶予期間が使用されます。
1. **変更を保存**を選択します。

アクセストークンはAPIベースであるため、認証に第2要素を提供する必要はありません。トークンは2FAが適用される前に生成されたものであっても有効です。

GitLabの[受信メール](../administration/incoming_email.md)機能は2FAの適用に従いません。ユーザーは、イシューの作成やマージリクエストへのコメントなど、受信メール機能を使用できますが、最初に2FAを使用して認証する必要はありません。これは、2FAが適用されている場合でも適用されます。

### サブグループでの2FA {#2fa-in-subgroups}

デフォルトでは、各サブグループはトップレベルグループとは異なる2FA要件を設定できます。

ユーザーが階層内の複数のグループのメンバーである場合、最も制限の厳しい2FA要件がすべてのレベルに適用されます。

たとえば、トップレベルグループで2FAが適用されている場合:

- トップレベルグループのすべてのメンバーは2FAを使用する必要があります。
- 子孫サブグループのすべてのメンバーは2FAを使用する必要があります。

トップレベルグループで2FAが適用されていない場合:

- **サブグループに対して、より厳格な2FA認証の適用を許可する**が有効な場合、各サブグループは個別に2FA要件を適用できます。サブグループが2FA要件を有効にする場合:
  - トップレベルグループのすべてのメンバーは2FAを使用する必要があります。
  - 兄弟サブグループのすべてのメンバーは2FAを使用する必要があります。

- **サブグループに対して、より厳格な2FA認証の適用を許可する**が無効な場合、サブグループは個別に2FA要件を適用できません。階層内のどのメンバーにも2FAは必要ありません。

> [!note] 
> 
> **このグループ内のすべてのユーザーは2要素認証を設定する必要があります**が有効な場合、常に**サブグループに対して、より厳格な2FA認証の適用を許可する**よりも優先されます。

サブグループが個別の2FA要件を設定するのを防ぐには:

1. トップレベルグループの**設定** > **一般**に移動します。
1. **権限とグループ機能**セクションを展開します。
1. **サブグループに対して、より厳格な2FA認証の適用を許可する**チェックボックスをオフにします。

### プロジェクトでの2FA {#2fa-in-projects}

2FAを有効または適用しているグループに属するプロジェクトが、2FAを有効または適用していないグループと[共有](../user/project/members/sharing_projects_groups.md)されている場合、非2FAグループのメンバーは2FAを使用せずにそのプロジェクトにアクセスできます。例: 

- グループAは2FAを有効にして適用しています。グループBは2FAを有効にしていません。
- グループAに属するプロジェクトPがグループBと共有されている場合、グループBのメンバーは2FAなしでプロジェクトPにアクセスできます。

これを防ぐには、2FAグループの[プロジェクト共有を防止](../user/project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups)します。

> [!warning]
> 2FAが有効になっているグループまたはサブグループのプロジェクトにメンバーを追加しても、個別に追加したメンバーには2FAは必須では**ありません**。

## 2FAを無効にする {#disable-2fa}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

単一のユーザーまたはすべてのユーザーに対して2FAを無効にできます。

このアクションは永続的で元に戻せません。ユーザーは、再度使用するために2FAを再有効化する必要があります。

> [!warning]
> 
> ユーザーの2FAを無効にしても、[すべてのユーザーに2FAを適用する](#enforce-2fa-for-all-users)または[グループ内のすべてのユーザーに2FAを適用する](#enforce-2fa-for-all-users-in-a-group)設定は無効になりません。また、ユーザーが次回GitLabにサインインするときに2FAの設定を再度求められないように、適用されている2FA設定も無効にする必要があります。

### すべてのユーザー向け {#for-all-users}

強制2FAが無効になっている場合でもすべてのユーザーの2FAを無効にするには、次のRakeタスクを使用します。

- Linuxパッケージを使用するインストールの場合:

  ```shell
  sudo gitlab-rake gitlab:two_factor:disable_for_all_users
  ```

- セルフコンパイルインストールの場合:

  ```shell
  sudo -u git -H bundle exec rake gitlab:two_factor:disable_for_all_users RAILS_ENV=production
  ```

### 単一のユーザー向け {#for-a-single-user}

#### 管理者 {#administrators}

[Railsコンソール](../administration/operations/rails_console.md)を使用して、単一の管理者の2FAを無効にすることができます:

```ruby
admin = User.find_by_username('<USERNAME>')
user_to_disable = User.find_by_username('<USERNAME>')

TwoFactor::DestroyService.new(admin, user: user_to_disable).execute
```

管理者には、2FAが無効になったことが通知されます。

#### 非管理者 {#non-administrators}

Railsコンソールまたは[APIエンドポイント](../api/users.md#disable-two-factor-authentication-for-a-user)のいずれかを使用して、非管理者の2FAを無効にできます。

自分のアカウントの2FAを無効にできます。

APIエンドポイントを使用して、管理者の2FAを無効にすることはできません。

#### エンタープライズユーザー {#enterprise-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

トップレベルグループのオーナーは、エンタープライズユーザーの2要素認証（2FA）を無効にできます。

2FAを無効にするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **管理** > **メンバー**を選択します。
1. **エンタープライズ**バッジと**2FA**バッジが付いているユーザーを探します。
1. **その他のアクション**（{{< icon name="ellipsis_v" >}}）を選択し、**2要素認証を無効にする**を選択します。

[API](../api/group_enterprise_users.md#disable-two-factor-authentication-for-an-enterprise-user)を使用して、エンタープライズユーザー（グループのメンバーではなくなったエンタープライズユーザーを含む）の2FAを無効にすることもできます。

## SSH操作によるGitの2FA {#2fa-for-git-over-ssh-operations}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

> [!flag] 
> 
> デフォルトではこの機能は利用できません。管理者が`two_factor_for_cli`という名前の[機能フラグを有効にする](../administration/feature_flags/_index.md)と、この機能を使用できるようになります。この機能は本番環境での使用には対応していません。この機能フラグは、[2FAが有効な場合のGit操作のセッション期間](../administration/settings/account_and_limit_settings.md#customize-session-duration-for-git-operations-when-2fa-is-enabled)にも影響します。

SSH操作によるGitの2FAを適用できます。ただし、代わりに`ED25519_SK`または`ECDSA_SK`SSHキーを使用する必要があります。詳細については、[サポートされているSSHキーの種類](../user/ssh.md#supported-ssh-key-types)を参照してください。2FAはGit操作のみに適用され、GitLab Shellからの`personal_access_token`などの内部コマンドは除外されます。

ワンタイムパスワード（OTP）認証を実行するには、以下を実行します:

```shell
ssh git@<hostname> 2fa_verify
```

その後、次のいずれかの方法で認証します:

- 正しいOTPを入力します。
- [FortiAuthenticatorが有効](../user/profile/account/two_factor_authentication.md#add-a-fortiauthenticator-authenticator)な場合は、デバイスのプッシュ通知に応答します。

認証が成功すると、関連付けられたSSHキーを使用して、15分間（デフォルト）SSHを介したGit操作を実行できます。

### セキュリティの制限 {#security-limitation}

2FAは、侵害された秘密SSHキーを持つユーザーを保護しません。

OTPが検証されると、設定された[セッション期間](../administration/settings/account_and_limit_settings.md#customize-session-duration-for-git-operations-when-2fa-is-enabled)中、誰でもその秘密SSHキーを使用してSSHを介してGitを実行できます。
