---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: OmniAuth
description: サードパーティのIdentity Providerで外部認証を設定します。

---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ユーザーは、Google、GitHub、その他の一般的なサービスの認証情報を使用してGitLabにサインインできます。[OmniAuth](https://rubygems.org/gems/omniauth/)は、GitLabがこの認証を提供するために使用するRackフレームワークです。

設定すると、追加のサインインオプションがサインインページに表示されます。

## サポートされているプロバイダー {#supported-providers}

GitLabは、次のOmniAuthプロバイダーをサポートしています。

| プロバイダーのドキュメント                                              | OmniAuthプロバイダー名     |
|---------------------------------------------------------------------|----------------------------|
| [AliCloud](alicloud.md)                                             | `alicloud`                 |
| [Atlassian](../administration/auth/atlassian.md)                    | `atlassian_oauth2`         |
| [Auth0](auth0.md)                                                   | `auth0`                    |
| [AWS Cognito](../administration/auth/cognito.md)                    | `cognito`                  |
| [Azure v2](azure.md)                                                | `azure_activedirectory_v2` |
| [Bitbucket Cloud](bitbucket.md)                                     | `bitbucket`                |
| [Generic OAuth 2.0](oauth2_generic.md)                              | `oauth2_generic`           |
| [GitHub](github.md)                                                 | `github`                   |
| [GitLab.com](gitlab.md)                                             | `gitlab`                   |
| [Google](google.md)                                                 | `google_oauth2`            |
| [JWT](../administration/auth/jwt.md)                                | `jwt`                      |
| [Kerberos](kerberos.md)                                             | `kerberos`                 |
| [OpenID Connect](../administration/auth/oidc.md)                    | `openid_connect`           |
| [Salesforce](salesforce.md)                                         | `salesforce`               |
| [SAML](saml.md)                                                     | `saml`                     |
| [Shibboleth](shibboleth.md)                                         | `shibboleth`               |

## 共通設定を行う {#configure-common-settings}

OmniAuthプロバイダーを設定する前に、すべてのプロバイダーに共通の設定を行います。

| オプション | 説明 |
| ------ | ----------- |
| `allow_bypass_two_factor`    | ユーザーが2要素認証（2FA）なしで、指定されたプロバイダーでサインインできるようにします。`true`、`false`、またはプロバイダーの配列を指定できます。詳細については、[2要素認証を回避する](#bypass-two-factor-authentication)を参照してください。 |
| `allow_single_sign_on`       | OmniAuthでサインインする際のアカウントの自動作成を有効にします。`true`、`false`、またはプロバイダーの配列を指定できます。プロバイダー名については、[サポートされているプロバイダーの表](#supported-providers)を参照してください。`false`の場合、既存のGitLabアカウントなしで、OmniAuthプロバイダーのアカウントを使用してサインインすることはできません。まずGitLabアカウントを作成してから、プロファイル設定でOmniAuthプロバイダーのアカウントと接続する必要があります。 |
| `auto_link_ldap_user`        | OmniAuthプロバイダーを介して作成されたユーザーに対して、GitLabでLDAPアイデンティティを作成します。この設定を有効にするには、[LDAPインテグレーション](../administration/auth/ldap/_index.md)が有効になっている必要があります。また、LDAPおよびOmniAuthプロバイダーでユーザーの`uid`が同一である必要があります。 |
| `auto_link_saml_user`        | SAMLプロバイダーを介して認証するユーザーと、既存のGitLabユーザーのメールアドレスが一致する場合に、それらを自動的にリンクできるようにします。この設定を有効にするには、SAMLインテグレーションが有効になっている必要があります。 |
| `auto_link_user`             | OmniAuthプロバイダーを介して認証するユーザーと、既存のGitLabユーザーのメールアドレスが一致する場合に、それらを自動的にリンクできるようにします。`true`、`false`、またはプロバイダーの配列を指定できます。プロバイダー名については、[サポートされているプロバイダーの表](#supported-providers)を参照してください。 |
| `auto_sign_in_with_provider` | 単一のプロバイダー名を使用してユーザーが自動的にサインインできるようにします。ここで指定する名前は、`saml`や`google_oauth2`など、プロバイダー名と一致している必要があります。サインインの無限ループを防ぐために、ユーザーはGitLabからサインアウトする前に、Identity Providerのアカウントからサインアウトしておく必要があります。サポートされているOmniAuthプロバイダー向けのフェデレーションサインアウトを実装するために、[SAML](https://gitlab.com/gitlab-org/gitlab/-/issues/14414)などを対象とした機能拡張が現在進行中です。 |
| `block_auto_created_users`   | 自動的に作成されたユーザーを、管理者が承認するまで[承認保留中](../administration/moderate_users.md#users-pending-approval)状態にします。`false`に設定した場合は、SAMLやGoogleなど、制御可能なプロバイダーを必ず指定してください。そうしないと、インターネット上の誰でも、管理者の承認なしにGitLabにサインインできるようになる可能性があります。`true`に設定した場合は、自動作成されたユーザーはデフォルトでブロックされ、サインインできるようにするには管理者がブロックを解除する必要があります。 |
| `enabled`                    | GitLabにおけるOmniAuthの使用を有効または無効にします。`false`の場合、UIにOmniAuthプロバイダーボタンは表示されません。 |
| `external_providers`         | `external`（外部）プロバイダーとして扱うOmniAuthプロバイダーを定義できます。この設定により、これらのプロバイダーを介してアカウントの作成やサインインを行うユーザーは、内部プロジェクトにアクセスできなくなります。プロバイダーのフルネームを指定する必要があります。たとえば、Googleの場合は`google_oauth2`です。詳細については、[外部プロバイダーリストを作成する](#create-an-external-providers-list)を参照してください。 |
| `providers`                  | プロバイダー名は、[サポートされているプロバイダーの表](#supported-providers)に記載されています。 |
| `sync_profile_attributes`    | サインイン時にプロバイダーから同期するプロファイル属性のリスト。詳細については、[OmniAuthユーザープロファイルを最新の状態に保つ](#keep-omniauth-user-profiles-up-to-date)を参照してください。 |
| `sync_profile_from_provider` | GitLabがプロファイル情報を自動的に同期するプロバイダー名のリスト。各エントリは、`saml`や`google_oauth2`など、プロバイダー名と一致している必要があります。詳細については、[OmniAuthユーザープロファイルを最新の状態に保つ](#keep-omniauth-user-profiles-up-to-date)を参照してください。 |

### 初期設定を行う {#configure-initial-settings}

OmniAuth設定を変更するには、次の手順に従います:

  {{< tabs >}}

  {{< tab title="Linuxパッケージ（Omnibus）" >}}

  1. `/etc/gitlab/gitlab.rb`を編集します:

     ```ruby
     # CAUTION!
     # This allows users to sign in without having a user account first. Define the allowed providers
     # using an array, for example, ["saml", "google_oauth2"], or as true/false to allow all providers or none.
     # User accounts will be created automatically when authentication was successful.
     gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'google_oauth2']
     gitlab_rails['omniauth_auto_link_ldap_user'] = true
     gitlab_rails['omniauth_block_auto_created_users'] = true
     ```

  1. ファイルを保存して、GitLabを再設定します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  {{< /tab >}}

  {{< tab title="Helmチャート（Kubernetes）" >}}

  1. Helm値をエクスポートします:

     ```shell
     helm get values gitlab > gitlab_values.yaml
     ```

  1. `gitlab_values.yaml`を編集し、`globals.appConfig`の`omniauth`セクションを更新します:

     ```yaml
     global:
       appConfig:
         omniauth:
           enabled: true
           allowSingleSignOn: ['saml', 'google_oauth2']
           autoLinkLdapUser: false
           blockAutoCreatedUsers: true
     ```

     詳細については、[グローバル設定に関するドキュメント](https://docs.gitlab.com/charts/charts/globals.html#omniauth)を参照してください。

  1. ファイルを保存して、新しい値を適用します:

     ```shell
     helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
     ```

  {{< /tab >}}

  {{< tab title="Docker" >}}

  1. `docker-compose.yml`を編集します:

     ```yaml
     version: "3.6"
     services:
       gitlab:
         environment:
           GITLAB_OMNIBUS_CONFIG: |
             gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'google_oauth2']
             gitlab_rails['omniauth_auto_link_ldap_user'] = true
             gitlab_rails['omniauth_block_auto_created_users'] = true
     ```

  1. ファイルを保存して、GitLabを再起動します:

     ```shell
     docker compose up -d
     ```

  {{< /tab >}}

  {{< tab title="自己コンパイル（ソース）" >}}

  1. `/home/git/gitlab/config/gitlab.yml`を編集します:

     ```yaml
     ## OmniAuth settings
     omniauth:
       # Allow sign-in by using Google, GitLab, etc. using OmniAuth providers
       # Versions prior to 11.4 require this to be set to true
       # enabled: true

       # CAUTION!
       # This allows users to sign in without having a user account first. Define the allowed providers
       # using an array, for example, ["saml", "google_oauth2"], or as true/false to allow all providers or none.
       # User accounts will be created automatically when authentication was successful.
       allow_single_sign_on: ["saml", "google_oauth2"]

       auto_link_ldap_user: true

       # Locks down those users until they have been cleared by the admin (default: true).
       block_auto_created_users: true
     ```

  1. ファイルを保存して、GitLabを再起動します:

     ```shell
     # For systems running systemd
     sudo systemctl restart gitlab.target

     # For systems running SysV init
     sudo service gitlab restart
     ```

  {{< /tab >}}

  {{< /tabs >}}

これらの設定を終えたら、選択した[プロバイダー](#supported-providers)の設定に進むことができます。

### プロバイダーごとの設定 {#per-provider-configuration}

{{< history >}}

- GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89379)されました。

{{< /history >}}

`allow_single_sign_on`が設定されている場合、GitLabはサインインしているユーザーのユーザー名を決定するために、OmniAuthの`auth_hash`で返された次のフィールドのいずれかを使用し、存在するフィールドの中で最初に見つかったものを選択します:

- `username`
- `nickname`
- `email`

プロバイダーごとにGitLabの設定を作成し、`args`を使用してその[プロバイダー](#supported-providers)に設定を渡すことができます。あるプロバイダーに対する`args`に`gitlab_username_claim`変数を設定すると、GitLabのユーザー名として使用する別のクレームを選択できます。指定するクレームは、競合が発生しないよう一意である必要があります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```ruby
gitlab_rails['omniauth_providers'] = [

  # The generic pattern for configuring a provider with name PROVIDER_NAME

  gitlab_rails['omniauth_providers'] = {
    name: "PROVIDER_NAME"
    ...
    args: { gitlab_username_claim: 'sub' } # For users signing in with the provider you configure, the GitLab username will be set to the "sub" received from the provider
  },

  # Here are examples using GitHub and Kerberos

  gitlab_rails['omniauth_providers'] = {
    name: "github"
    ...
    args: { gitlab_username_claim: 'name' } # For users signing in with GitHub, the GitLab username will be set to the "name" received from GitHub
  },
  {
    name: "kerberos"
    ...
    args: { gitlab_username_claim: 'uid' } # For users signing in with Kerberos, the GitLab username will be set to the "uid" received from Kerberos
  },
]
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```yaml
- { name: 'PROVIDER_NAME',
  # ...
  args: { gitlab_username_claim: 'sub' }
}
- { name: 'github',
  # ...
  args: { gitlab_username_claim: 'name' }
}
- { name: 'kerberos',
  # ...
  args: { gitlab_username_claim: 'uid' }
}
```

{{< /tab >}}

{{< /tabs >}}

### OmniAuthを介して作成されたユーザーのパスワード {#passwords-for-users-created-via-omniauth}

[統合認証で作成されたユーザーのパスワードの生成](../security/passwords_for_integrated_authentication_methods.md)に関するガイドでは、OmniAuthで作成されたユーザーに対してGitLabがパスワードを生成および設定する方法の概要を説明しています。

## 既存のユーザーに対してOmniAuthを有効にする {#enable-omniauth-for-an-existing-user}

既存のユーザーの場合は、GitLabアカウントが作成された後、OmniAuthプロバイダーを有効にできます。たとえば、最初にLDAPでサインインした場合、GoogleなどのOmniAuthプロバイダーを有効にできます。

1. GitLabの認証情報、LDAP、または別のOmniAuthプロバイダーでGitLabにサインインします。
1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アカウント**を選択します。
1. **接続したアカウント**セクションで、GoogleなどのOmniAuthプロバイダーを選択します。
1. プロバイダーにリダイレクトされます。GitLabを承認すると、GitLabにリダイレクトされます。

これで、選択したOmniAuthプロバイダーを使用してGitLabにサインインできます。

## インポートソースを無効にせずにOmniAuthプロバイダーでのサインインを有効または無効にする {#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources}

管理者は、一部のOmniAuthプロバイダーのサインインを有効または無効にできます。

{{< alert type="note" >}}

デフォルトでは、`config/gitlab.yml`で設定されたすべてのOAuthプロバイダーに対してサインインは有効になっています。

{{< /alert >}}

OmniAuthプロバイダーを有効または無効にするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **サインインの制限**を展開します。
1. **有効なOAuth認証ソース**セクションで、有効または無効にする各プロバイダーのチェックボックスをオンまたはオフにします。

## OmniAuthを無効にする {#disable-omniauth}

OmniAuthはデフォルトで有効になっています。ただし、OmniAuthは、プロバイダーが設定され、[有効](#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources)になっている場合にのみ機能します。

OmniAuthプロバイダーを個別に無効にしていても問題を引き起こす場合は、設定ファイルを変更することで、OmniAuthサブシステム全体を無効にできます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```ruby
gitlab_rails['omniauth_enabled'] = false
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```yaml
omniauth:
  enabled: false
```

{{< /tab >}}

{{< /tabs >}}

## 既存のユーザーをOmniAuthユーザーにリンクする {#link-existing-users-to-omniauth-users}

OmniAuthユーザーと既存のGitLabユーザーのメールアドレスが一致する場合、それらを自動的にリンクできます。

次の例では、OpenID ConnectプロバイダーとGoogle OAuthプロバイダーに対して、自動リンクを有効にしています。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```ruby
gitlab_rails['omniauth_auto_link_user'] = ["openid_connect", "google_oauth2"]
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```yaml
omniauth:
  auto_link_user: ["openid_connect", "google_oauth2"]
```

{{< /tab >}}

{{< /tabs >}}

自動リンクを有効にするこの方法は、[SAMLを除く](https://gitlab.com/gitlab-org/gitlab/-/issues/338293)すべてのプロバイダーに対して機能します。SAMLの自動リンクを有効にするには、[SAMLのセットアップ手順](saml.md#configure-saml-support-in-gitlab)を参照してください。

## 外部プロバイダーリストを作成する {#create-an-external-providers-list}

外部OmniAuthプロバイダーのリストを定義できます。リストに含まれているプロバイダーを介してアカウントを作成またはGitLabにサインインしたユーザーは、[内部プロジェクト](../user/public_access.md#internal-projects-and-groups)へのアクセス権を付与されず、[外部ユーザー](../administration/external_users.md)としてマークされます。

外部プロバイダーリストを定義するには、プロバイダーのフルネームを使用します。たとえば、Googleの場合は`google_oauth2`です。プロバイダー名については、[サポートされているプロバイダーの表](#supported-providers)の**OmniAuth provider name**（OmniAuthプロバイダー名）の列を参照してください。

{{< alert type="note" >}}

OmniAuthプロバイダーを外部プロバイダーリストから削除する場合、このサインイン方法を使用するユーザーを手動で更新して、アカウントを完全な内部アカウントにアップグレードする必要があります。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```ruby
gitlab_rails['omniauth_external_providers'] = ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```yaml
omniauth:
  external_providers: ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< /tabs >}}

## OmniAuthユーザープロファイルを最新の状態に保つ {#keep-omniauth-user-profiles-up-to-date}

{{< history >}}

- GitLab 17.9で、`job_title`属性と`organization`属性が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/505575)されました。

{{< /history >}}

{{< alert type="note" >}}

一部のプロバイダーでは、これらの属性を同期するために追加の設定が必要です。たとえば、SAMLプロバイダーでは[プロファイル属性のマッピング](saml.md#map-profile-attributes)が必要です。

{{< /alert >}}

選択したOmniAuthプロバイダーからのプロファイル同期を有効にできます。次のユーザー属性を任意の組み合わせで同期できます:

- `name`
- `email`
- `job_title`
- `location`
- `organization`

LDAPを使用して認証する場合は、ユーザーの名前とメールアドレスは常に同期されます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['omniauth_sync_profile_from_provider'] = ['saml', 'google_oauth2']
   gitlab_rails['omniauth_sync_profile_attributes'] = ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helm値をエクスポートします:

   ```shell
   helm get values gitlab > values.yaml
   ```

1. `values.yaml`を編集します:

   ```yaml
   global:
     appConfig:
       omniauth:
         syncProfileFromProvider: ['saml', 'google_oauth2']
         syncProfileAttributes: ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. ファイルを保存して、新しい値を適用します:

   ```shell
   helm upgrade -f values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_sync_profile_from_provider'] = ['saml', 'google_oauth2']
           gitlab_rails['omniauth_sync_profile_attributes'] = ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. ファイルを保存して、GitLabを再起動します:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します:

   ```yaml
   production: &base
     omniauth:
       sync_profile_from_provider: ['saml', 'google_oauth2']
       sync_profile_attributes: ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. ファイルを保存して、GitLabを再起動します:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 2要素認証を回避する {#bypass-two-factor-authentication}

特定のOmniAuthプロバイダーを使用すると、ユーザーは2要素認証（2FA）を使用せずにサインインできます。

2FAを回避するには、次のいずれかを実行します:

- 配列を使用して、許可されるプロバイダーを定義する（例: `['saml', 'google_oauth2']`）。
- すべてのプロバイダーを許可する場合は`true`、許可しない場合は`false`を指定する。

このオプションは、すでに2FAを備えているプロバイダーに対してのみ設定する必要があります。デフォルトは`false`です。

この設定はSAMLには適用されません。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```ruby
gitlab_rails['omniauth_allow_bypass_two_factor'] = ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```yaml
omniauth:
  allow_bypass_two_factor: ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< /tabs >}}

## プロバイダーで自動的にサインインする {#sign-in-with-a-provider-automatically}

`auto_sign_in_with_provider`設定をGitLabの設定に追加することで、認証のためにログインリクエストをOmniAuthプロバイダーにリダイレクトできます。これにより、サインインする前にプロバイダーを選択する必要がなくなります。

たとえば、[Azure v2インテグレーション](azure.md)の自動サインインを有効にするには、次の手順に従います:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```ruby
gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'azure_activedirectory_v2'
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```yaml
omniauth:
  auto_sign_in_with_provider: azure_activedirectory_v2
```

{{< /tab >}}

{{< /tabs >}}

すべてのサインイン試行がOmniAuthプロバイダーにリダイレクトされるため、ローカルの認証情報を使用してサインインできなくなる点に注意してください。少なくとも1人のOmniAuthユーザーが管理者であることを確認してください。

`https://gitlab.example.com/users/sign_in?auto_sign_in=false`にアクセスして、自動サインインを回避することもできます。

## カスタムOmniAuthプロバイダーアイコンを使用する {#use-a-custom-omniauth-provider-icon}

ほとんどのサポートされているプロバイダーには、表示されるサインインボタン用の組み込みのアイコンが用意されています。

独自のアイコンを使用するには、画像が64 x 64ピクセルで表示されるように最適化されていることを確認したうえで、次の2つの方法のいずれかでアイコンをオーバーライドします:

- **Provide a custom image path**（カスタム画像パスを指定する）:

  1. GitLabサーバーのドメインの外部で画像をホストしている場合は、画像ファイルへのアクセスを許可するように[コンテンツセキュリティポリシー](https://docs.gitlab.com/omnibus/settings/configuration.html#content-security-policy)を設定します。
  1. GitLabのインストール方法に応じて、GitLab設定ファイルにカスタム`icon`パラメータを追加します。OpenID Connectプロバイダーの例については、[OpenID Connect OmniAuthプロバイダー](../administration/auth/oidc.md)を参照してください。

- **Embed an image directly in a configuration file**（設定ファイルに画像を直接埋め込む）: この例では、画像のBase64エンコードバージョンを作成します。この形式の画像は、[Data URL](https://developer.mozilla.org/en-US/docs/Web/URI/Schemes/data)を介して提供できます:

  1. GNU `base64`コマンド（例: `base64 -w 0 <logo.png>`）を使用して画像ファイルをエンコードします。このコマンドは、1行の`<base64-data>`文字列を返します。
  1. Base64エンコードされたデータを、GitLab設定ファイルのカスタム`icon`パラメータに追加します:

     ```yaml
     omniauth:
       providers:
         - { name: '...'
             icon: 'data:image/png;base64,<base64-data>'
             # Additional parameters removed for readability
           }
     ```

## アプリまたは設定を変更する {#change-apps-or-configuration}

GitLabのOAuthは、同じ外部認証および認可プロバイダーを複数のプロバイダーとして設定することをサポートしていないため、プロバイダーまたはアプリを変更する場合は、GitLabの設定とユーザーアイデンティティを同時に更新する必要があります。たとえば、`saml`と`azure_activedirectory_v2`を設定できますが、同じ設定内に`azure_activedirectory_v2`をもう1つ追加することはできません。

この手順は、GitLabが`extern_uid`を保存しており、それがユーザー認証に使用する唯一のデータであるすべての認証方法に適用されます。

プロバイダー内でアプリを変更する場合、ユーザーの`extern_uid`が変更されないのであれば、更新する必要があるのはGitLabの設定のみです。

設定を切り替えるには、次の手順に従います:

1. `gitlab.rb`ファイルでプロバイダーの設定を変更します。
1. 以前のプロバイダーに対応するGitLabのアイデンティティを持つすべてのユーザーの`extern_uid`を更新します。

`extern_uid`を確認するには、既存ユーザーの現在の`extern_uid`を調べ、同じユーザーについて、現在のプロバイダーの適切なフィールドと一致するIDを特定します。

`extern_uid`を更新するには、次の2つの方法があります:

- [ユーザーAPI](../api/users.md#modify-a-user)を使用する（プロバイダー名と新しい`extern_uid`を渡す）。
- [Railsコンソール](../administration/operations/rails_console.md)を使用する:

  ```ruby
  Identity.where(extern_uid: 'old-id').update!(extern_uid: 'new-id')
  ```

## 既知の問題 {#known-issues}

ほとんどのサポートされているOmniAuthプロバイダーは、HTTPパスワード認証を介したGitをサポートしていません。回避策として、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用して認証できます。
