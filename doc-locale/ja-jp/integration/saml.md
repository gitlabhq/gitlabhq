---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Self-ManagedのSAML SSO
description: エンタープライズ認証をSAMLインテグレーションで構成して、シングルサインオンアクセスを実現します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

GitLab.comについては、[GitLab.comグループのSAML SSO](../user/group/saml_sso/_index.md)を参照してください。

{{< /alert >}}

このページでは、GitLab Self-Managedにおいてインスタンス全体のSAMLシングルサインオン（SSO）を設定する方法について説明します。

SAMLサービスプロバイダー（SP）として機能するようにGitLabを設定できます。これによりGitLabは、OktaなどのSAML Identity Provider（IdP）が発行したアサーションを利用して、ユーザーを認証できます。

詳細については、次を参照してください:

- OmniAuthプロバイダーの設定については、[OmniAuthのドキュメント](omniauth.md)を参照してください。
- 一般的に使用される用語については、[用語集](#glossary)を参照してください。

## GitLabでSAMLのサポートを設定する {#configure-saml-support-in-gitlab}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. GitLabで[HTTPSが設定されている](https://docs.gitlab.com/omnibus/settings/ssl/)ことを確認してください。
1. [共通設定](omniauth.md#configure-common-settings)で、`saml`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。
1. ユーザーが最初に手動でアカウントを作成しなくてもSAMLを使用してサインアップできるようにするには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
   gitlab_rails['omniauth_block_auto_created_users'] = false
   ```

1. オプション。初回にSAMLでサインインする際に、SAML応答のメールアドレスが既存のGitLabユーザーと一致する場合、これらを自動的にリンクする必要があります。これを行うには、`/etc/gitlab/gitlab.rb`に次の設定を追加します:

   ```ruby
   gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   SAML応答のメールアドレスと照合されるのは、GitLabアカウントのプライマリメールアドレスのみです。

   または、ユーザーが[既存のユーザーに対してOmniAuthを有効にする](omniauth.md#enable-omniauth-for-an-existing-user)ことで、SAMLアイデンティティを既存のGitLabアカウントに手動でリンクすることも可能です。

1. 次の属性を設定し、SAMLユーザーがこれらを変更できないようにします:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity)
   - `Email`（`omniauth_auto_link_saml_user`と併用する場合）。

   ユーザーがこれらの属性を変更できる場合、他の認証済みユーザーとしてサインインできてしまいます。これらの属性を変更不可にする方法については、SAML IdPのドキュメントを参照してください。

1. `/etc/gitlab/gitlab.rb`を編集し、プロバイダー設定を追加します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "saml", # This must be lowercase.
       label: "Provider name", # optional label for login button, defaults to "Saml"
       args: {
         assertion_consumer_service_url: "https://gitlab.example.com/users/auth/saml/callback",
         idp_cert_fingerprint: "2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6",
         idp_sso_target_url: "https://login.example.com/idp",
         issuer: "https://gitlab.example.com",
         name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
       }
     }
   ]
   ```

   | 引数                         | 説明 |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | GitLab HTTPSエンドポイント（GitLabインストールのHTTPS URLに`/users/auth/saml/callback`を付加します）。 |
   | `idp_cert_fingerprint`           | IdPの値。証明書からSHA256フィンガープリントを生成するには、[フィンガープリントを計算する](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint)を参照してください。 |
   | `idp_sso_target_url`             | IdPの値。 |
   | `issuer`                         | IdPがアプリケーションを識別できるように一意の名前に変更します。 |
   | `name_identifier_format`         | IdPの値。 |

   これらの値の詳細については、[OmniAuth SAMLのドキュメント](https://github.com/omniauth/omniauth-saml)を参照してください。その他の設定項目の詳細については、[IdPでSAMLを設定する](#configure-saml-on-your-idp)を参照してください。

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. GitLabで[HTTPSが設定されている](https://docs.gitlab.com/charts/installation/tls.html)ことを確認してください。
1. [共通設定](omniauth.md#configure-common-settings)で、`saml`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。
1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. ユーザーが最初に手動でアカウントを作成しなくてもSAMLを使用してサインアップできるようにするには、`gitlab_values.yaml`を編集します:

   ```yaml
   global:
     appConfig:
       omniauth:
         enabled: true
         allowSingleSignOn: ['saml']
         blockAutoCreatedUsers: false
   ```

1. オプション。`gitlab_values.yaml`に次の設定を追加すると、SAMLユーザーと既存のGitLabユーザーのメールアドレスが一致する場合に、両者を自動的にリンクできます:

   ```yaml
   global:
     appConfig:
       omniauth:
         autoLinkSamlUser: true
   ```

   または、ユーザーが[既存のユーザーに対してOmniAuthを有効にする](omniauth.md#enable-omniauth-for-an-existing-user)ことで、SAMLアイデンティティを既存のGitLabアカウントに手動でリンクすることも可能です。

1. 次の属性を設定し、SAMLユーザーがこれらを変更できないようにします:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity)
   - `Email`（`omniauth_auto_link_saml_user`と併用する場合）。

   ユーザーがこれらの属性を変更できる場合、他の認証済みユーザーとしてサインインできてしまいます。これらの属性を変更不可にする方法については、SAML IdPのドキュメントを参照してください。

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Provider name' # optional label for login button, defaults to "Saml"
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

   | 引数                         | 説明 |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | GitLab HTTPSエンドポイント（GitLabインストールのHTTPS URLに`/users/auth/saml/callback`を付加します）。 |
   | `idp_cert_fingerprint`           | IdPの値。証明書からSHA256フィンガープリントを生成するには、[フィンガープリントを計算する](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint)を参照してください。 |
   | `idp_sso_target_url`             | IdPの値。 |
   | `issuer`                         | IdPがアプリケーションを識別できるように一意の名前に変更します。 |
   | `name_identifier_format`         | IdPの値。 |

   これらの値の詳細については、[OmniAuth SAMLのドキュメント](https://github.com/omniauth/omniauth-saml)を参照してください。その他の設定項目の詳細については、[IdPでSAMLを設定する](#configure-saml-on-your-idp)を参照してください。

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. `gitlab_values.yaml`を編集し、プロバイダー設定を追加します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. GitLabで[HTTPSが設定されている](https://docs.gitlab.com/omnibus/settings/ssl/)ことを確認してください。
1. [共通設定](omniauth.md#configure-common-settings)で、`saml`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。
1. ユーザーが最初に手動でアカウントを作成しなくてもSAMLを使用してサインアップできるようにするには、`docker-compose.yml`を編集します:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
           gitlab_rails['omniauth_block_auto_created_users'] = false
   ```

1. オプション。`docker-compose.yml`に次の設定を追加すると、SAMLユーザーと既存のGitLabユーザーのメールアドレスが一致する場合に、両者を自動的にリンクできます:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   または、ユーザーが[既存のユーザーに対してOmniAuthを有効にする](omniauth.md#enable-omniauth-for-an-existing-user)ことで、SAMLアイデンティティを既存のGitLabアカウントに手動でリンクすることも可能です。

1. 次の属性を設定し、SAMLユーザーがこれらを変更できないようにします:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity)
   - `Email`（`omniauth_auto_link_saml_user`と併用する場合）。

   ユーザーがこれらの属性を変更できる場合、他の認証済みユーザーとしてサインインできてしまいます。これらの属性を変更不可にする方法については、SAML IdPのドキュメントを参照してください。

1. `docker-compose.yml`を編集し、プロバイダー設定を追加します: 

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
             {
               name: "saml",
               label: "Provider name", # optional label for login button, defaults to "Saml"
               args: {
                 assertion_consumer_service_url: "https://gitlab.example.com/users/auth/saml/callback",
                 idp_cert_fingerprint: "2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6",
                 idp_sso_target_url: "https://login.example.com/idp",
                 issuer: "https://gitlab.example.com",
                 name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
               }
             }
           ]
   ```

   | 引数                         | 説明 |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | GitLab HTTPSエンドポイント（GitLabインストールのHTTPS URLに`/users/auth/saml/callback`を付加します）。 |
   | `idp_cert_fingerprint`           | IdPの値。証明書からSHA256フィンガープリントを生成するには、[フィンガープリントを計算する](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint)を参照してください。 |
   | `idp_sso_target_url`             | IdPの値。 |
   | `issuer`                         | IdPがアプリケーションを識別できるように一意の名前に変更します。 |
   | `name_identifier_format`         | IdPの値。 |

   これらの値の詳細については、[OmniAuth SAMLのドキュメント](https://github.com/omniauth/omniauth-saml)を参照してください。その他の設定項目の詳細については、[IdPでSAMLを設定する](#configure-saml-on-your-idp)を参照してください。

1. ファイルを保存して、GitLabを再起動します:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. GitLabで[HTTPSが設定されている](../install/self_compiled/_index.md#using-https)ことを確認してください。
1. [共通設定](omniauth.md#configure-common-settings)で、`saml`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。
1. ユーザーが最初に手動でアカウントを作成しなくてもSAMLを使用してサインアップできるようにするには、`/home/git/gitlab/config/gitlab.yml`を編集します:

   ```yaml
   production: &base
     omniauth:
       enabled: true
       allow_single_sign_on: ["saml"]
       block_auto_created_users: false
   ```

1. オプション。`/home/git/gitlab/config/gitlab.yml`に次の設定を追加すると、SAMLユーザーと既存のGitLabユーザーのメールアドレスが一致する場合に、両者を自動的にリンクできます:

   ```yaml
   production: &base
     omniauth:
       auto_link_saml_user: true
   ```

   または、ユーザーが[既存のユーザーに対してOmniAuthを有効にする](omniauth.md#enable-omniauth-for-an-existing-user)ことで、SAMLアイデンティティを既存のGitLabアカウントに手動でリンクすることも可能です。

1. 次の属性を設定し、SAMLユーザーがこれらを変更できないようにします:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity)
   - `Email`（`omniauth_auto_link_saml_user`と併用する場合）。

   ユーザーがこれらの属性を変更できる場合、他の認証済みユーザーとしてサインインできてしまいます。これらの属性を変更不可にする方法については、SAML IdPのドキュメントを参照してください。

1. `/home/git/gitlab/config/gitlab.yml`を編集し、プロバイダー設定を追加します: 

   ```yaml
   omniauth:
     providers:
       - {
         name: 'saml',
         label: 'Provider name', # optional label for login button, defaults to "Saml"
         args: {
           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
           idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
           idp_sso_target_url: 'https://login.example.com/idp',
           issuer: 'https://gitlab.example.com',
           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
         }
       }
   ```

   | 引数                         | 説明 |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | GitLab HTTPSエンドポイント（GitLabインストールのHTTPS URLに`/users/auth/saml/callback`を付加します）。 |
   | `idp_cert_fingerprint`           | IdPの値。証明書からSHA256フィンガープリントを生成するには、[フィンガープリントを計算する](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint)を参照してください。 |
   | `idp_sso_target_url`             | IdPの値。 |
   | `issuer`                         | IdPがアプリケーションを識別できるように一意の名前に変更します。 |
   | `name_identifier_format`         | IdPの値。 |

   これらの値の詳細については、[OmniAuth SAMLのドキュメント](https://github.com/omniauth/omniauth-saml)を参照してください。その他の設定項目の詳細については、[IdPでSAMLを設定する](#configure-saml-on-your-idp)を参照してください。

1. ファイルを保存して、GitLabを再起動します:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### SAML IdPにGitLabを登録する {#register-gitlab-in-your-saml-idp}

1. `issuer`で指定されたアプリケーション名を使用して、SAML IdPにGitLabのSPを登録します。

1. IdPに設定情報を提供するには、アプリケーションのメタデータURLを作成します。GitLabのメタデータURLを作成するには、GitLabインストールのHTTPS URLに`users/auth/saml/metadata`を付加します。次に例を示します:

   ```plaintext
   https://gitlab.example.com/users/auth/saml/metadata
   ```

   IdPは最低限、`email`または`mail`を使用して、ユーザーのメールアドレスを含むクレームを提供する**must**（必要があります）。その他の利用可能なクレームの詳細については、[アサーションを設定する](#configure-assertions)を参照してください。

1. サインインページでは、標準のサインインフォームの下にSAMLのアイコンが表示されているはずです。そのアイコンを選択すると、認証プロセスが開始されます。認証に成功すると、GitLabに戻り、サインインした状態になります。

### IdPでSAMLを設定する {#configure-saml-on-your-idp}

IdPでSAMLアプリケーションを設定するには、少なくとも次の情報が必要です:

- アサーションコンシューマサービスURL。
- 発行者。
- [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity)
- [メールアドレスのクレーム](#configure-assertions)。

設定例については、[Identity Providerを設定する](#set-up-identity-providers)を参照してください。

IdPによっては追加の設定が必要になる場合があります。詳細については、[IdPにおけるSAMLアプリ用の追加の設定](#additional-configuration-for-saml-apps-on-your-idp)を参照してください。

### 複数のSAML IdPを使用するようにGitLabを設定する {#configure-gitlab-to-use-multiple-saml-idps}

次の条件を満たす場合、複数のSAML IdPを使用するようにGitLabを設定できます:

- 各プロバイダーに、`args`に指定された名前と一致する、一意の名前が設定されている。
- プロバイダー名を次のように使用している:
  - OmniAuthの設定で、プロバイダー名に基づいてプロパティを設定している。例: `allowBypassTwoFactor`、`allowSingleSignOn`、`syncProfileFromProvider`。
  - プロバイダー名を使用して、既存の各ユーザーに追加のIDとして関連付けている。
- `assertion_consumer_service_url`がプロバイダー名と一致している。
- `strategy_class`が明示的に設定されている（プロバイダー名からは推測できないため）。

{{< alert type="note" >}}

複数のSAML IdPを設定する場合、SAMLグループのリンクを適切に機能させるには、SAML応答にグループ属性が含まれるように、すべてのSAML IdPを設定する必要があります。詳細については、[SAMLグループのリンク](../user/group/saml_sso/group_sync.md)を参照してください。

{{< /alert >}}

複数のSAML IdPを設定するには、次の手順に従います:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: 'saml', # This must match the following name configuration parameter
       label: 'Provider 1' # Differentiate the two buttons and providers in the UI
       args: {
               name: 'saml', # This is mandatory and must match the provider name
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback', # URL must match the name of the provider
               strategy_class: 'OmniAuth::Strategies::SAML',
               # Include all required arguments similar to a single provider
             },
     },
     {
       name: 'saml_2', # This must match the following name configuration parameter
       label: 'Provider 2' # Differentiate the two buttons and providers in the UI
       args: {
               name: 'saml_2', # This is mandatory and must match the provider name
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
               strategy_class: 'OmniAuth::Strategies::SAML',
               # Include all required arguments similar to a single provider
             },
     }
   ]
   ```

   ユーザーがいずれかのプロバイダーから手動でアカウントを作成することなく、SAMLを使用してサインアップできるようにするには、次の値を設定に追加します:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml_2']
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、最初のSAMLプロバイダーの[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml' # At least one provider must be named 'saml'
   label: 'Provider 1' # Differentiate the two buttons and providers in the UI
   args:
     name: 'saml' # This is mandatory and must match the provider name
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback' # URL must match the name of the provider
     strategy_class: 'OmniAuth::Strategies::SAML' # Mandatory
     # Include all required arguments similar to a single provider
   ```

1. 次の内容を`saml_2.yaml`ファイルに記述し、2番目のSAMLプロバイダーの[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml_2'
   label: 'Provider 2' # Differentiate the two buttons and providers in the UI
   args:
     name: 'saml_2' # This is mandatory and must match the provider name
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback' # URL must match the name of the provider
     strategy_class: 'OmniAuth::Strategies::SAML' # Mandatory
     # Include all required arguments similar to a single provider
   ```

1. オプション。同じ手順に従って、追加のSAMLプロバイダーを設定します。
1. Kubernetes Secretsを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml \
      --from-file=saml=saml.yaml \
      --from-file=saml_2=saml_2.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
             key: saml
           - secret: gitlab-saml
             key: saml_2
   ```

   ユーザーがいずれかのプロバイダーから手動でアカウントを作成することなく、SAMLを使用してサインアップできるようにするには、次の値を設定に追加します:

   ```yaml
   global:
     appConfig:
       omniauth:
         allowSingleSignOn: ['saml', 'saml_2']
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml1']
           gitlab_rails['omniauth_providers'] = [
             {
               name: 'saml', # This must match the following name configuration parameter
               label: 'Provider 1' # Differentiate the two buttons and providers in the UI
               args: {
                       name: 'saml', # This is mandatory and must match the provider name
                       assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback', # URL must match the name of the provider
                       strategy_class: 'OmniAuth::Strategies::SAML',
                       # Include all required arguments similar to a single provider
                     },
             },
             {
               name: 'saml_2', # This must match the following name configuration parameter
               label: 'Provider 2' # Differentiate the two buttons and providers in the UI
               args: {
                       name: 'saml_2', # This is mandatory and must match the provider name
                       assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
                       strategy_class: 'OmniAuth::Strategies::SAML',
                       # Include all required arguments similar to a single provider
                     },
             }
           ]
   ```

   ユーザーがいずれかのプロバイダーから手動でアカウントを作成することなく、SAMLを使用してサインアップできるようにするには、次の値を設定に追加します:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml_2']
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
       providers:
         - {
           name: 'saml', # This must match the following name configuration parameter
           label: 'Provider 1' # Differentiate the two buttons and providers in the UI
           args: {
             name: 'saml', # This is mandatory and must match the provider name
             assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback', # URL must match the name of the provider
             strategy_class: 'OmniAuth::Strategies::SAML',
             # Include all required arguments similar to a single provider
           },
         }
         - {
           name: 'saml_2', # This must match the following name configuration parameter
           label: 'Provider 2' # Differentiate the two buttons and providers in the UI
           args: {
             name: 'saml_2', # This is mandatory and must match the provider name
             strategy_class: 'OmniAuth::Strategies::SAML',
             assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
             # Include all required arguments similar to a single provider
           },
         }
   ```

   ユーザーがいずれかのプロバイダーから手動でアカウントを作成することなく、SAMLを使用してサインアップできるようにするには、次の値を設定に追加します:

   ```yaml
   production: &base
     omniauth:
       allow_single_sign_on: ["saml", "saml_2"]
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

## Identity Providerを設定する {#set-up-identity-providers}

GitLabはSAMLをサポートしているため、広範なIdPを通じてGitLabにサインインすることが可能です。

GitLabは、OktaやGoogle WorkspaceのIdPの設定に関する次の情報をガイダンスとして提供しています。いずれかのIdPの設定についてご不明な点がある場合は、各プロバイダーのサポートにお問い合わせください。

### Oktaを設定する {#set-up-okta}

1. Oktaの管理者セクションで、**アプリケーション**を選択します。
1. アプリ画面で、**Create App Integration**（アプリ統合を作成）を選択し、次の画面で**SAML 2.0**を選択します。
1. オプション。[GitLab Press](https://about.gitlab.com/press/press-kit/)からロゴを選択して追加します。ロゴをトリミングしてサイズを変更する必要があります。
1. SAMLの一般設定を入力します。次の項目を設定します:
   - `"Single sign-on URL"`: アサーションコンシューマサービスURLを使用します。
   - `"Audience URI"`: 発行者を使用します。
   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity)
   - [アサーション](#configure-assertions)。
1. フィードバックセクションで、自分が顧客であり、内部使用のためにアプリを作成していることを入力します。
1. 新しいアプリのプロファイルの上部で、**SAML 2.0 configuration instructions**（SAML 2.0設定手順）を選択します。
1. **Identity Provider Single Sign-On URL**（アイデンティティプロバイダのシングルサインオンURL）をメモします。このURLは、GitLab設定ファイルの`idp_sso_target_url`に使用します。
1. Oktaからサインアウトする前に、ユーザーとグループ（存在する場合）を必ず追加してください。

### Google Workspaceを設定する {#set-up-google-workspace}

前提要件: 

- [Google Workspaceの特権管理者アカウント](https://support.google.com/a/answer/2405986#super_admin)へのアクセス権があることを確認してください。

Google Workspaceを設定するには、次の手順に従います:

1. 次の情報を使用し、[Google WorkspaceでカスタムSAMLアプリを設定する](https://support.google.com/a/answer/6087519?hl=en)手順に従います。

   |                  | 一般的な値                                      | 説明                                                                                   |
   |:-----------------|:---------------------------------------------------|:----------------------------------------------------------------------------------------------|
   | SAMLアプリの名前 | GitLab                                             | 他の名前でもかまいません。                                                                               |
   | ACS URL          | `https://<GITLAB_DOMAIN>/users/auth/saml/callback` | アサーションコンシューマサービスURL。                                                               |
   | `GITLAB_DOMAIN`  | `gitlab.example.com`                               | GitLabインスタンスのドメイン。                                                                  |
   | エンティティID        | `https://gitlab.example.com`                       | SAMLアプリケーションに固有の値。この値は、GitLabの設定で`issuer`に指定します。 |
   | 名前IDの形式   | `EMAIL`                                            | 必須の値です。`name_identifier_format`としても知られています。                                       |
   | 名前ID          | プライマリーメールアドレス                              | お使いのメールアドレス。そのアドレス宛てに送信された内容を受信できることを確認してください。                  |
   | お名前(名)       | `first_name`                                       | お名前(名)。GitLabと通信するために必須の値です。                                        |
   | お名前(姓)        | `last_name`                                        | お名前(姓)。GitLabと通信するために必須の値です。                                         |

1. 次のSAML属性マッピングを設定します:

   | Googleディレクトリの属性       | アプリケーションの属性 |
   |-----------------------------------|----------------|
   | Basic information（基本情報） > Email（メールアドレス）         | `email`        |
   | Basic information（基本情報） > お名前(名)    | `first_name`   |
   | 基本情報 > お名前(姓)     | `last_name`    |

   この情報の一部は、[GitLabでSAMLのサポートを設定する](#configure-saml-support-in-gitlab)際に使用する場合があります。

Google Workspace SAMLアプリケーションを設定する際に、次の情報を記録しておいてください:

|                    | 値        | 説明 |
| ------------------ | ------------ | ----------- |
| SSO URL            | 環境により異なる      | Google Identity Providerの詳細。GitLabの`idp_sso_target_url`設定に指定します。 |
| 証明書        | ダウンロード可能 | Google SAML証明書。 |
| SHA256フィンガープリント | 環境により異なる      | 証明書をダウンロードすると利用できます。証明書からSHA256フィンガープリントを生成するには、[フィンガープリントを計算する](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint)を参照してください。 |

Google Workspace管理者は、IdPメタデータ、エンティティID、SHA-256フィンガープリントも提供します。ただし、GitLabがGoogle Workspace SAMLアプリケーションに接続するために、これらの情報は必要ありません。

### Microsoft Entra IDを設定する {#set-up-microsoft-entra-id}

1. [Microsoft Entra管理センター](https://entra.microsoft.com/)にサインインします。
1. [ギャラリー以外のアプリケーションを作成](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/overview-application-gallery#create-your-own-application)します。
1. [そのアプリケーションのSSOを設定](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso)します。

   `gitlab.rb`ファイル内の次の設定は、Microsoft Entra IDのフィールドに対応しています:

   | `gitlab.rb`の設定                 | Microsoft Entra IDフィールド                       |
   | ------------------------------------| ---------------------------------------------- |
   | `issuer`                           | **Identifier (Entity ID)**（識別子（エンティティID））                     |
   | `assertion_consumer_service_url`   | **Reply URL (Assertion Consumer Service URL)**（応答URL（アサーションコンシューマサービスURL）） |
   | `idp_sso_target_url`               | **Login URL**（Login URL（ログインURL））                                  |
   | `idp_cert_fingerprint`             | **Thumbprint**（Thumbprint（サムプリント））                                 |

1. 次の属性を設定します:
   - **Unique User Identifier (Name ID)**（一意のユーザー識別子（名前ID））には`user.objectID`を指定します。
      - **Name identifier format**（名前識別子形式）を`persistent`にします。詳細については、[ユーザーSAMLアイデンティティの管理](../user/group/saml_sso/_index.md#manage-user-saml-identity)を参照してください。
   - **Additional claims**（追加のクレーム）には[サポートされている属性](#configure-assertions)を指定します。

詳細については、[設定例のページ](../user/group/saml_sso/example_saml_config.md#azure-active-directory)を参照してください。

### 他のIdPを設定する {#set-up-other-idps}

一部のIdPには、SAML設定でIdPとして使用する方法に関するドキュメントが用意されています。次に例を示します:

- [Active Directory Federation Services（ADFS）](https://learn.microsoft.com/en-us/previous-versions/windows-server/it-pro/windows-server-2012/identity/ad-fs/operations/Create-a-Relying-Party-Trust)
- [Auth0](https://auth0.com/docs/authenticate/single-sign-on/outbound-single-sign-on/configure-auth0-saml-identity-provider)

SAML設定におけるIdPの設定方法についてご不明な点がある場合は、各プロバイダーのサポートにお問い合わせください。

### アサーションを設定する {#configure-assertions}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.7で、Microsoft Azure/Entra ID属性のサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420766)されました。

{{< /history >}}

{{< alert type="note" >}}

これらの属性は大文字と小文字が区別されます。

{{< /alert >}}

| フィールド           | サポートされているデフォルトキー                                                                                                                                                         |
|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| メール（必須）| `email`、`mail`、`http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress`、`http://schemas.microsoft.com/ws/2008/06/identity/claims/emailaddress`、`http://schemas.xmlsoap.org/ws/2005/05/identity/claims/email`、`http://schemas.microsoft.com/ws/2008/06/identity/claims/email`、`urn:oid:0.9.2342.19200300.100.1.3`                  |
| フルネーム       | `name`、`http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name`、`http://schemas.microsoft.com/ws/2008/06/identity/claims/name`、`urn:oid:2.16.840.1.113730.3.1.241`、`urn:oid:2.5.4.3`                                           |
| お名前(名)      | `first_name`、`firstname`、`firstName`、`http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname`、`http://schemas.microsoft.com/ws/2008/06/identity/claims/givenname`、`urn:oid:2.5.4.42` |
| お名前(姓)       | `last_name`、`lastname`、`lastName`、`http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname`、`http://schemas.microsoft.com/ws/2008/06/identity/claims/surname`、`urn:oid:2.5.4.4`   |

GitLabがSAML SSOプロバイダーからSAML応答を受信すると、GitLabは属性の`name`フィールドで次の値を検索します:

- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"`
- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"`
- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"`
- `firstname`
- `lastname`
- `email`

GitLabがSAML応答を解析できるように、これらの値を属性の`Name`フィールドに正しく含める必要があります。たとえば、GitLabは次のようなSAML応答のスニペットを解析できます:

- これは、`Name`属性が前の表にある必須値のいずれかに設定されているため、受け入れられます。

  ```xml
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

- これは、`Name`属性が前の表にある値の1つと一致するため、受け入れられます。

  ```xml
           <Attribute Name="firstname">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute Name="lastname">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute Name="email">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

ただし、GitLabは次のSAML応答スニペットを解析できません:

- これは、`Name`属性の値が前の表にあるサポート対象の値のいずれでもないため、受け入れられません。

  ```xml
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/firstname">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/lastname">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/mail">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

- これは、`FriendlyName`にサポート対象の値が設定されていても、`Name`属性にサポート対象外の値が設定されているため、失敗します。

  ```xml
           <Attribute FriendlyName="firstname" Name="urn:oid:2.5.4.42">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute FriendlyName="lastname" Name="urn:oid:2.5.4.4">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute FriendlyName="email" Name="urn:oid:0.9.2342.19200300.100.1.3">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

以下については、[`attribute_statements`を参照してください。](#map-saml-response-attribute-names):

- カスタムアサーション設定の例。
- カスタムユーザー名属性を設定する方法。

サポート対象のアサーションの完全なリストについては、[gem OmniAuth SAML](https://github.com/omniauth/omniauth-saml/blob/master/lib/omniauth/strategies/saml.rb)を参照してください

## SAMLグループメンバーシップに基づいてユーザーを設定する {#configure-users-based-on-saml-group-membership}

次のことが可能です:

- ユーザーが特定のグループのメンバーであることを必須にする。
- グループメンバーシップに基づいて、ユーザーに[外部](../administration/external_users.md) 、管理者、[監査担当者](../administration/auditor_users.md)のいずれかのロールを割り当てる。

GitLabは、SAMLサインインのたびにこれらのグループをチェックし、必要に応じてユーザー属性を更新します。ただし、この機能では、GitLab[グループ](../user/group/_index.md)にユーザーを自動的に追加することは**does not**（できません）。

これらのグループのサポートは、以下に依存します:

- お客様の[サブスクリプション](https://about.gitlab.com/pricing/)。
- [GitLab Enterprise Edition（EE）](https://about.gitlab.com/install/)をインストールしているかどうか。

| グループ                        | プラン               | GitLab Enterprise Edition（EE）のみか？ |
|------------------------------|--------------------|--------------------------------------|
| [必須](#required-groups) | Free、Premium、Ultimate | はい                                  |
| [外部](#external-groups) | Free、Premium、Ultimate | いいえ                                   |
| [管理者](#administrator-groups) | Free、Premium、Ultimate | はい                                  |
| [監査担当者](#auditor-groups)   | Premium、Ultimate | はい                                  |

前提要件: 

- グループ情報がどこにあるかを、GitLabに指示する必要があります。そのためには、IdPサーバーが標準のSAML応答とともに特定の`AttributeStatement`を送信するように設定してください。次に例を示します:

  ```xml
  <saml:AttributeStatement>
    <saml:Attribute Name="Groups">
      <saml:AttributeValue xsi:type="xs:string">Developers</saml:AttributeValue>
      <saml:AttributeValue xsi:type="xs:string">Freelancers</saml:AttributeValue>
      <saml:AttributeValue xsi:type="xs:string">Admins</saml:AttributeValue>
      <saml:AttributeValue xsi:type="xs:string">Auditors</saml:AttributeValue>
    </saml:Attribute>
  </saml:AttributeStatement>
  ```

  属性の名前には、ユーザーが所属しているグループを含める必要があります。これらのグループがある場所をGitLabに指示するには、SAML設定に`groups_attribute:`要素を追加します。この属性は大文字と小文字が区別されます。

### 必須グループ {#required-groups}

IdPは、SAML応答でグループ情報をGitLabに渡します。この応答を使用するには、以下を識別できるようにGitLabを設定します:

- SAML応答内でグループがある場所（`groups_attribute`設定を使用）。
- グループまたはユーザーに関する情報（グループ設定を使用）。

`required_groups`設定を使用して、サインインに必要なグループメンバーシップをGitLabが識別できるようにします。

`required_groups`を設定しない場合、または設定を空のままにしている場合は、適切に認証されたユーザーであれば誰でもこのサービスを使用できます。

`groups_attribute`で指定された属性が誤っているか存在しない場合、すべてのユーザーがブロックされます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
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
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
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

### 外部グループ {#external-groups}

IdPは、SAML応答でグループ情報をGitLabに渡します。この応答を使用するには、以下を識別できるようにGitLabを設定します:

- SAML応答内でグループがある場所（`groups_attribute`設定を使用）。
- グループまたはユーザーに関する情報（グループ設定を使用）。

SAMLは、`external_groups`設定に基づいて、ユーザーを[外部ユーザー](../administration/external_users.md)として自動的に識別できます。

{{< alert type="note" >}}

`groups_attribute`で指定された属性が誤っているか存在しない場合、ユーザーは標準ユーザーとしてアクセスします。

{{< /alert >}}

設定例: 

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [

     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       external_groups: ['Freelancers'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               # or
               # idp_cert: '-----BEGIN CERTIFICATE-----\n ... \n-----END CERTIFICATE-----',

               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   external_groups: ['Freelancers']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     # or
     # idp_cert: '-----BEGIN CERTIFICATE-----\n ... \n-----END CERTIFICATE-----',
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
             { name: 'saml',
               label: 'Our SAML Provider',
               groups_attribute: 'Groups',
               external_groups: ['Freelancers'],
               args: {
                       assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                       idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                       idp_sso_target_url: 'https://login.example.com/idp',
                       issuer: 'https://gitlab.example.com',
                       name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
               }
             }
           ]
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
       providers:
          - { name: 'saml',
              label: 'Our SAML Provider',
              groups_attribute: 'Groups',
              external_groups: ['Freelancers'],
              args: {
                      assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                      idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                      idp_sso_target_url: 'https://login.example.com/idp',
                      issuer: 'https://gitlab.example.com',
                      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
              }
            }
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

### 管理者グループ {#administrator-groups}

IdPは、SAML応答でグループ情報をGitLabに渡します。この応答を使用するには、以下を識別できるようにGitLabを設定します:

- SAML応答内でグループがある場所（`groups_attribute`設定を使用）。
- グループまたはユーザーに関する情報（グループ設定を使用）。

`admin_groups`設定を使用して、ユーザーに管理者アクセス権を付与するグループをGitLabが識別できるようにします。

`groups_attribute`で指定された属性が誤っているか存在しない場合、ユーザーは管理者アクセス権を失います。

設定例: 

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       admin_groups: ['Admins'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               # or
               # idp_cert: '-----BEGIN CERTIFICATE-----\n ... \n-----END CERTIFICATE-----',

               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   admin_groups: ['Admins']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                admin_groups: ['Admins'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
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
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             admin_groups: ['Admins'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
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

### 監査担当者グループ {#auditor-groups}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

IdPは、SAML応答でグループ情報をGitLabに渡します。この応答を使用するには、以下を識別できるようにGitLabを設定します:

- SAML応答内でグループがある場所（`groups_attribute`設定を使用）。
- グループまたはユーザーに関する情報（グループ設定を使用）。

`auditor_groups`設定を使用して、[監査担当者アクセス権](../administration/auditor_users.md)を持つユーザーを含むグループをGitLabが識別できるようにします。

`groups_attribute`で指定された属性が誤っているか存在しない場合、ユーザーは監査担当者アクセス権を失います。

設定例: 

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       auditor_groups: ['Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   auditor_groups: ['Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                auditor_groups: ['Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
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
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             auditor_groups: ['Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
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

## SAMLグループ同期を自動的に管理する {#automatically-manage-saml-group-sync}

GitLabグループメンバーシップの自動管理については、[SAMLグループ同期](../user/group/saml_sso/group_sync.md)を参照してください。

### SAMLセッションのタイムアウトをカスタマイズする {#customize-saml-session-timeout}

{{< history >}}

- GitLab 18.2で`saml_timeout_supplied_by_idp_override`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/262074)されました。

{{< /history >}}

デフォルトでは、GitLabのSAMLセッションは24時間後に終了します。SAML2 AuthnStatementの`SessionNotOnOrAfter`属性を使用して、この期間をカスタマイズできます。この属性には、ユーザーセッションを終了するタイミングを示すISO 8601タイムスタンプ値が含まれています。指定された場合、この値はSAMLセッションのデフォルトのタイムアウト（24時間）をオーバーライドします。

インスタンスにカスタム[session duration](../administration/settings/account_and_limit_settings.md#session-duration)（セッション時間）が設定されており、それが`SessionNotOnOrAfter`タイムスタンプよりも以前である場合、ユーザーはGitLabユーザーセッションの終了時に再度認証する必要があります。

## 2要素認証を回避する {#bypass-two-factor-authentication}

{{< history >}}

- 2FAの適用を回避する機能は、GitLab 16.1で`by_pass_two_factor_current_session`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122109)されました。
- GitLab 17.8で、[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/416535)になりました。

{{< /history >}}

セッション単位で2要素認証（2FA）としてカウントするようにSAML認証方法を設定するには、`upstream_two_factor_authn_contexts`リストにその方式を登録します。

1. IdPが`AuthnContext`を返すようになっていることを確認してください。次に例を示します:

   ```xml
   <saml:AuthnStatement>
       <saml:AuthnContext>
           <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:MediumStrongCertificateProtectedTransport</saml:AuthnContextClassRef>
       </saml:AuthnContext>
   </saml:AuthnStatement>
   ```

1. インストール設定を編集し、`upstream_two_factor_authn_contexts`リストにSAML認証方法を登録します。SAML応答に含まれている`AuthnContext`を入力する必要があります。

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   1. `/etc/gitlab/gitlab.rb`を編集します: 

      ```ruby
      gitlab_rails['omniauth_providers'] = [
        { name: 'saml',
          label: 'Our SAML Provider',
          args: {
                  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                  idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                  idp_sso_target_url: 'https://login.example.com/idp',
                  issuer: 'https://gitlab.example.com',
                  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                  upstream_two_factor_authn_contexts:
                    %w(
                      urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport
                      urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS
                      urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN
                    ),
          }
        }
      ]
      ```

   1. ファイルを保存して、GitLabを再設定します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Helmチャート（Kubernetes）" >}}

   1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

      ```yaml
      name: 'saml'
      label: 'Our SAML Provider'
      args:
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
        idp_sso_target_url: 'https://login.example.com/idp'
        issuer: 'https://gitlab.example.com'
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
        upstream_two_factor_authn_contexts:
          - 'urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport'
          - 'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS'
          - 'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN'
      ```

   1. Kubernetes Secretを作成します:

      ```shell
      kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
      ```

   1. Helm値をエクスポートします: 

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. `gitlab_values.yaml`を編集します: 

      ```yaml
      global:
        appConfig:
          omniauth:
            providers:
              - secret: gitlab-saml
      ```

   1. ファイルを保存し、新しい値を適用します: 

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
              gitlab_rails['omniauth_providers'] = [
                 { name: 'saml',
                   label: 'Our SAML Provider',
                   args: {
                           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                           idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                           idp_sso_target_url: 'https://login.example.com/idp',
                           issuer: 'https://gitlab.example.com',
                           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                           upstream_two_factor_authn_contexts:
                             %w(
                               urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport
                               urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS
                               urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN
                             )
                   }
                 }
              ]
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
          providers:
            - { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                        upstream_two_factor_authn_contexts:
                          [
                            'urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport',
                            'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS',
                            'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN'
                          ]
                }
              }
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

## 応答署名を検証する {#validate-response-signatures}

IdPは、アサーションが改ざんされていないことを保証するために、SAMLレスポンスに署名する必要があります。

これにより、特定のグループメンバーシップが必要な場合に、ユーザーの代理および権限昇格を防止できます。

### `idp_cert_fingerprint`を使用する {#using-idp_cert_fingerprint}

`idp_cert_fingerprint`を使用して、レスポンス署名の検証を設定できます。設定例を以下に示します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
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
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
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

### `idp_cert`を使用する {#using-idp_cert}

`idp_cert`を使用して、GitLabを直接設定することもできます。設定例を以下に示します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert: '-----BEGIN CERTIFICATE-----
                 <redacted>
                 -----END CERTIFICATE-----',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert: |
       -----BEGIN CERTIFICATE-----
       <redacted>
       -----END CERTIFICATE-----
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert: '-----BEGIN CERTIFICATE-----
                          <redacted>
                          -----END CERTIFICATE-----',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
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
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert: '-----BEGIN CERTIFICATE-----
                       <redacted>
                       -----END CERTIFICATE-----',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
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

応答署名検証が正しく設定されていない場合は、次のようなエラーメッセージが表示されることがあります:

- キー検証エラー。
- ダイジェストの不一致。
- フィンガープリントの不一致。

これらのエラーの解決方法については、[SAMLのトラブルシューティング](../user/group/saml_sso/troubleshooting.md)ガイドを参照してください。

## SAML設定をカスタマイズする {#customize-saml-settings}

### 認証のためにユーザーをSAMLサーバーにリダイレクトする {#redirect-users-to-saml-server-for-authentication}

GitLabの設定に`auto_sign_in_with_provider`を付加すると、認証のためにSAMLサーバーに自動的にリダイレクトできます。これにより、実際にサインインする前に要素を選択する必要がなくなります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
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

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         autoSignInWithProvider: 'saml'
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
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
       auto_sign_in_with_provider: 'saml'
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

すべてのサインイン試行がSAMLサーバーにリダイレクトされるため、ローカル認証情報を使用してサインインすることはできません。SAMLユーザーのうち少なくとも1人が管理者アクセス権を持っていることを確認してください。

{{< alert type="note" >}}

自動サインイン設定を回避するには、サインインURLに`?auto_sign_in=false`を付加します。例: `https://gitlab.example.com/users/sign_in?auto_sign_in=false`。

{{< /alert >}}

### SAMLレスポンス属性名をマップする {#map-saml-response-attribute-names}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`attribute_statements`を使用すると、SAML応答の属性名をOmniAuthの[`info`ハッシュ](https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema#schema-10-and-later)エントリにマップできます。

{{< alert type="note" >}}

この設定は、OmniAuthの`info`ハッシュスキーマに含まれる属性をマップする場合にのみ使用してください。

{{< /alert >}}

たとえば、`SAMLResponse`に`EmailAddress`という属性が含まれている場合は、`{ email: ['EmailAddress'] }`を指定することで、属性を`info`ハッシュの対応するキーにマップできます。URI形式の属性もサポートしています。例: `{ email: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] }`

この設定を使用して、アカウントの作成に必要な特定の属性をどこから取得すべきかをGitLabに指示します。たとえば、IdPがユーザーのメールアドレスを`email`ではなく`EmailAddress`として送信する場合は、それを設定することでGitLabに知らせます:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               attribute_statements: { email: ['EmailAddress'] }
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     attribute_statements:
       email: ['EmailAddress']
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        attribute_statements: { email: ['EmailAddress'] }
                }
              }
           ]
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
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     attribute_statements: { email: ['EmailAddress'] }
             }
           }
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

#### ユーザー名を設定する {#set-a-username}

デフォルトでは、SAML応答内のメールアドレスのローカル部分が、GitLabユーザー名の生成に使用されます。

ユーザーが希望するユーザー名を含む1つ以上の属性を指定するには、`attribute_statements`で[`username`または`nickname`](omniauth.md#per-provider-configuration)を設定します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               attribute_statements: { nickname: ['username'] }
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     attribute_statements:
       nickname: ['username']
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        attribute_statements: { nickname: ['username'] }
                }
              }
           ]
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
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     attribute_statements: { nickname: ['username'] }
             }
           }
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

これにより、SAML応答内の`username`属性の値がGitLabのユーザー名として設定されます。

#### プロファイル属性をマップする {#map-profile-attributes}

{{< history >}}

- GitLab 17.8で、`job_title`属性と`organization`属性が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/505575)されました。

{{< /history >}}

SAMLプロバイダーからプロファイル情報を同期するには、これらの属性をマップするように`attribute_statements`を設定する必要があります。

サポートされているプロファイル属性は次のとおりです:

- `job_title`
- `organization`

これらの属性にはデフォルトのマッピングがなく、明示的に設定しない限り同期されません。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. [目的の属性を同期するようにOmniAuthを設定](omniauth.md#keep-omniauth-user-profiles-up-to-date)します。
1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               attribute_statements: {
                 organization: ['organization'],
                 job_title: ['job_title']
               }
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. [目的の属性を同期するようにOmniAuthを設定](omniauth.md#keep-omniauth-user-profiles-up-to-date)します。
1. 次のYAMLの内容を`saml.yaml`ファイルに記述して保存し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     attribute_statements:
       organization: ['organization']
       job_title: ['job_title']
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. [目的の属性を同期するようにOmniAuthを設定](omniauth.md#keep-omniauth-user-profiles-up-to-date)します。
1. `docker-compose.yml`を編集します: 

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        attribute_statements: {
                          organization: ['organization'],
                          job_title: ['job_title']
                        }
                }
              }
           ]
   ```

1. ファイルを保存して、GitLabを再起動します:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. [目的の属性を同期するようにOmniAuthを設定](omniauth.md#keep-omniauth-user-profiles-up-to-date)します。
1. `/home/git/gitlab/config/gitlab.yml`を編集します: 

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     attribute_statements: {
                       organization: ['organization'],
                       job_title: ['job_title']
                     }
             }
           }
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

### クロックドリフト（時刻のずれ）を許容する {#allow-for-clock-drift}

IdPの時刻が、システム時刻よりもわずかに進んでいる場合があります。わずかなクロックドリフトを許容するには、設定で`allowed_clock_drift`を使用します。このパラメータには秒単位で値を入力する必要があります。小数を指定することもできます。指定した値は、応答の検証時の現在時刻に上乗せされます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               allowed_clock_drift: 1  # for one second clock drift
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     allowed_clock_drift: 1  # for one second clock drift
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        allowed_clock_drift: 1  # for one second clock drift
                }
              }
           ]
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
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     allowed_clock_drift: 1  # for one second clock drift
             }
           }
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

### `uid`に一意の属性を指定する（オプション） {#designate-a-unique-attribute-for-the-uid-optional}

デフォルトでは、ユーザーの`uid`は、SAML応答の`NameID`属性として設定されます。`uid`に別の属性を指定するには、`uid_attribute`を設定します。

`uid`に一意の属性を設定する前に、SAMLユーザーが次の属性を変更できないよう、各属性が変更不可に設定されていることを確認してください:

- [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity)
- `Email`（`omniauth_auto_link_saml_user`と併用する場合）。

ユーザーがこれらの属性を変更できる場合、他の認証済みユーザーとしてサインインできてしまいます。これらの属性を変更不可にする方法については、SAML IdPのドキュメントを参照してください。次の例では、SAML応答内の`uid`属性の値が`uid_attribute`として設定されています。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               uid_attribute: 'uid'
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     uid_attribute: 'uid'
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        uid_attribute: 'uid'
                }
              }
           ]
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
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     uid_attribute: 'uid'
             }
           }
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

## アサーションを暗号化する（オプション） {#assertion-encryption-optional}

SAMLアサーションの暗号化は推奨されるオプションです。これにより、暗号化されていないデータがログに記録されたり、悪意のあるアクターによって傍受されたりするのを防ぐための保護レイヤーが追加されます。

{{< alert type="note" >}}

このインテグレーションでは、アサーションの暗号化とリクエストの署名の両方に`certificate`および`private_key`の設定を使用します。

{{< /alert >}}

SAMLアサーションを暗号化するには、GitLab SAML設定で秘密キーと公開証明書を定義します。IdPは公開証明書でアサーションを暗号化し、GitLabは秘密キーでアサーションを復号化します。

キーと証明書を定義する際は、キーファイル内のすべての改行を`\n`に置き換えます。これにより、キーファイルは改行のない1行の長い文字列になります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               certificate:|
               -----BEGIN CERTIFICATE-----
               <redacted>
               -----END CERTIFICATE-----,
               private_key:|
               -----BEGIN PRIVATE KEY-----
               <redacted>
               -----END PRIVATE KEY-----
       }
     }
   ]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     certificate:|
     -----BEGIN CERTIFICATE-----
     <redacted>
     ----END CERTIFICATE-----,
     private_key:|
     -----BEGIN PRIVATE KEY-----
     <redacted>
     -----END PRIVATE KEY-----
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        certificate:|
                        -----BEGIN CERTIFICATE-----
                        <redacted>
                        -----END CERTIFICATE-----,
                        private_key:|
                        -----BEGIN PRIVATE KEY-----
                        <redacted>
                        -----END PRIVATE KEY-----
                }
              }
           ]
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
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                     private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----'
             }
           }
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

## SAML認証リクエストに署名する（オプション） {#sign-saml-authentication-requests-optional}

SAML認証リクエストに署名するようにGitLabを設定できます。GitLab SAMLリクエストはSAMLリダイレクトバインディングを使用しているため、この設定はオプションです。

署名を実装するには、次の手順に従います:

1. SAMLに使用するGitLabインスタンスの秘密キーと公開証明書ペアを作成します。
1. 設定の`security`セクションで署名に関する設定を行います。次に例を示します:

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   1. `/etc/gitlab/gitlab.rb`を編集します: 

      ```ruby
      gitlab_rails['omniauth_providers'] = [
        { name: 'saml',
          label: 'Our SAML Provider',
          args: {
                  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                  idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                  idp_sso_target_url: 'https://login.example.com/idp',
                  issuer: 'https://gitlab.example.com',
                  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                  certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                  private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----',
                  security: {
                    authn_requests_signed: true,  # enable signature on AuthNRequest
                    want_assertions_signed: true,  # enable the requirement of signed assertion
                    want_assertions_encrypted: false,  # enable the requirement of encrypted assertion
                    metadata_signed: false,  # enable signature on Metadata
                    signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
                    digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
                  }
          }
        }
      ]
      ```

   1. ファイルを保存して、GitLabを再設定します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Helmチャート（Kubernetes）" >}}

   1. 次の内容を`saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

      ```yaml
      name: 'saml'
      label: 'Our SAML Provider'
      args:
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
        idp_sso_target_url: 'https://login.example.com/idp'
        issuer: 'https://gitlab.example.com'
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
        certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----'
        private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----'
        security:
          authn_requests_signed: true  # enable signature on AuthNRequest
          want_assertions_signed: true  # enable the requirement of signed assertion
          want_assertions_encrypted: false  # enable the requirement of encrypted assertion
          metadata_signed: false  # enable signature on Metadata
          signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'
          digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256'
      ```

   1. Kubernetes Secretを作成します:

      ```shell
      kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
      ```

   1. Helm値をエクスポートします: 

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. `gitlab_values.yaml`を編集します: 

      ```yaml
      global:
        appConfig:
          omniauth:
            providers:
              - secret: gitlab-saml
      ```

   1. ファイルを保存し、新しい値を適用します: 

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
              gitlab_rails['omniauth_providers'] = [
                 { name: 'saml',
                   label: 'Our SAML Provider',
                   args: {
                           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                           idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                           idp_sso_target_url: 'https://login.example.com/idp',
                           issuer: 'https://gitlab.example.com',
                           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                           certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                           private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----',
                           security: {
                             authn_requests_signed: true,  # enable signature on AuthNRequest
                             want_assertions_signed: true,  # enable the requirement of signed assertion
                             want_assertions_encrypted: false,  # enable the requirement of encrypted assertion
                             metadata_signed: false,  # enable signature on Metadata
                             signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
                             digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
                           }
                   }
                 }
              ]
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
          providers:
            - { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                        private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----',
                        security: {
                          authn_requests_signed: true,  # enable signature on AuthNRequest
                          want_assertions_signed: true,  # enable the requirement of signed assertion
                          want_assertions_encrypted: false,  # enable the requirement of encrypted assertion
                          metadata_signed: false,  # enable signature on Metadata
                          signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
                          digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
                        }
                }
              }
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

その後、GitLabは次の処理を行います:

- 指定された秘密キーでリクエストに署名します。
- 受信したリクエストの署名をIdPが検証できるよう、設定された公開x500証明書をIdPのメタデータに含めます。

このオプションの詳細については、[Ruby SAML gemのドキュメント](https://github.com/SAML-Toolkits/ruby-saml/tree/v1.7.0)を参照してください。

Ruby SAML gemは、[OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml)がSAML認証のクライアント側を実装するために使用します。

{{< alert type="note" >}}

SAMLのリダイレクトバインディングは、SAMLのPOSTバインディングとは異なります。POSTバインディングでは、仲介者によってリクエストが改ざんされるのを防ぐために署名が必須となります。

{{< /alert >}}

## SAMLを通じて作成されたユーザーのパスワードを生成する {#password-generation-for-users-created-through-saml}

GitLabは、[SAMLを通じて作成されたユーザーに対して、パスワードを生成して設定](../security/passwords_for_integrated_authentication_methods.md)します。

SSOまたはSAMLで認証されたユーザーは、HTTPS経由でのGitオペレーションにパスワードを使用してはなりません。代わりに、次のいずれかが可能です:

- [パーソナル](../user/profile/personal_access_tokens.md) 、[プロジェクト](../user/project/settings/project_access_tokens.md) 、または[グループ](../user/group/settings/group_access_tokens.md)アクセストークンを設定する。
- [OAuth認証情報ヘルパー](../user/profile/account/two_factor_authentication.md#oauth-credential-helpers)を使用します。

## 既存のユーザーにSAMLアイデンティティをリンクする {#link-saml-identity-for-an-existing-user}

管理者は、SAMLユーザーを既存のGitLabユーザーに自動的にリンクするようにGitLabを設定できます。詳細については、[GitLabでのSAMLサポートの設定](#configure-saml-support-in-gitlab)を参照してください。

ユーザーは、SAMLアイデンティティを既存のGitLabアカウントに手動でリンクできます。詳細については、[既存のユーザーに対してOmniAuthを有効にする](omniauth.md#enable-omniauth-for-an-existing-user)を参照してください。

## GitLab Self-ManagedでグループSAML SSOを設定する {#configure-group-saml-sso-on-gitlab-self-managed}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Self-Managedインスタンスで複数のSAML IdPを通じてアクセスを許可する必要がある場合は、グループSAML SSOを使用します。

グループSAML SSOを設定するには、次の手順に従います:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. GitLabで[HTTPSが設定されている](https://docs.gitlab.com/omnibus/settings/ssl/)ことを確認してください。
1. `/etc/gitlab/gitlab.rb`を編集して、OmniAuthと`group_saml`プロバイダーを有効にします:

   ```ruby
   gitlab_rails['omniauth_enabled'] = true
   gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. GitLabで[HTTPSが設定されている](https://docs.gitlab.com/charts/installation/tls.html)ことを確認してください。
1. 次の内容を`group_saml.yaml`ファイルに記述し、[Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)として使用します:

   ```yaml
   name: 'group_saml'
   ```

1. Kubernetes Secretを作成します:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-group-saml --from-file=provider=group_saml.yaml
   ```

1. Helm値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集して、OmniAuthと`group_saml`プロバイダーを有効にします:

   ```yaml
   global:
     appConfig:
       omniauth:
         enabled: true
         providers:
           - secret: gitlab-group-saml
   ```

1. ファイルを保存し、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. GitLabで[HTTPSが設定されている](https://docs.gitlab.com/omnibus/settings/ssl/)ことを確認してください。
1. `docker-compose.yml`を編集して、OmniAuthと`group_saml`プロバイダーを有効にします:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_enabled'] = true
           gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

1. ファイルを保存して、GitLabを再起動します:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. GitLabで[HTTPSが設定されている](../install/self_compiled/_index.md#using-https)ことを確認してください。
1. `/home/git/gitlab/config/gitlab.yml`を編集して、OmniAuthと`group_saml`プロバイダーを有効にします:

   ```yaml
   production: &base
     omniauth:
       enabled: true
       providers:
         - { name: 'group_saml' }
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

マルチテナントソリューションであるため、GitLab Self-ManagedにおけるグループSAMLは、推奨される[インスタンス全体のSAML](saml.md)と比べて機能が制限されています。以下の機能を活用するには、インスタンス全体のSAMLを使用してください:

- [LDAPとの互換性](../administration/auth/ldap/_index.md)。
- [LDAPグループ同期](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)。
- [必須グループ。](#required-groups)
- [管理者グループ](#administrator-groups)。
- [監査担当者グループ](#auditor-groups)。

## IdPにおけるSAMLアプリ用の追加の設定 {#additional-configuration-for-saml-apps-on-your-idp}

IdPでSAMLアプリを設定する場合、次のような追加の設定が必要になる場合があります:

| フィールド | 値 | 備考 |
|-------|-------|-------|
| SAMLプロファイル | WebブラウザSSOプロファイル | GitLabはSAMLを使用して、ユーザーをブラウザ経由でサインインさせます。IdPに直接リクエストが送信されることはありません。 |
| SAMLリクエストバインディング | HTTPリダイレクト | GitLab（SP）はbase64でエンコードされた`SAMLRequest` HTTPパラメータを使用して、ユーザーをIdPにリダイレクトします。 |
| SAML応答バインディング | HTTP POST | IdPによるSAMLトークンの送信方法を指定します。これには、ユーザーのブラウザがGitLabに送り返す`SAMLResponse`を含みます。 |
| SAML応答の署名 | 必須 | 改ざんを防止します。 |
| 応答内のX.509証明書 | 必須 | 応答に署名し、指定されたフィンガープリントと照合して応答をチェックします。 |
| フィンガープリントアルゴリズム | SHA-1 | GitLabは証明書のSHA-1ハッシュを使用して、SAML応答に署名します。 |
| 署名アルゴリズム | SHA-1/SHA-256/SHA-384/SHA-512 | 応答への署名方法を指定します。ダイジェスト方式とも呼ばれ、SAML応答内で指定できます。 |
| SAMLアサーションの暗号化 | オプション | Identity Provider、ユーザーのブラウザ、およびGitLab間でTLSを使用します。 |
| SAMLアサーションへの署名 | オプション | SAMLアサーションの整合性を検証します。有効にすると、応答全体に署名します。 |
| SAMLリクエスト署名の確認 | オプション | SAML応答の署名を確認します。 |
| デフォルトのRelayState | オプション | ユーザーがIdPを通じてSAML認証で正常にサインインした後に、最終的にアクセスするベースURLのサブパスを指定します。 |
| NameID形式 | 永続的 | [NameID形式の詳細](../user/group/saml_sso/_index.md#manage-user-saml-identity)を参照してください。 |
| 追加のURL | オプション | 一部のプロバイダーでは、発行者、識別子、またはアサーションコンシューマサービスURLを他のフィールドに含める場合があります。 |

設定例については、[特定のプロバイダーに関する注記](#set-up-identity-providers)を参照してください。

## Geo環境でSAMLを設定する {#configure-saml-with-geo}

Geo環境でSAMLを設定するには、[インスタンス全体のSAMLを設定する](../administration/geo/replication/single_sign_on.md#configuring-instance-wide-saml)を参照してください。

詳細については、[Geoにおけるシングルサインオン（SSO）](../administration/geo/replication/single_sign_on.md)を参照してください。

## 用語集 {#glossary}

| 用語                           | 説明 |
|--------------------------------|-------------|
| Identity Provider（IdP）        | OktaやOneLoginなど、ユーザー認証情報を管理するサービス。 |
| サービスプロバイダー（SP）          | OktaなどのSAML Identity Provider（IdP）が発行したアサーションを利用して、ユーザーを認証します。GitLabはSAML 2.0 SPとして設定できます。 |
| アサーション                      | ユーザーの名前やロールなど、ユーザーの認証に関する情報。クレームまたは属性とも呼ばれます。 |
| シングルサインオン（SSO）           | 認証スキームの名前。 |
| アサーションコンシューマサービスURL | IdPでの認証に成功した後、ユーザーがリダイレクトされるGitLab側のコールバック先。 |
| 発行者                         | GitLabがIdPに対して自身を識別する方法。「relying party trust identifier（証明書利用者信頼の識別子）」とも呼ばれます。 |
| 証明書フィンガープリント        | サーバーが正しい証明書で通信に署名していることを確認することにより、SAMLを介した通信の安全性を保証します。証明書フィンガープリントとも呼ばれます。 |

## トラブルシューティング {#troubleshooting}

[SAMLのトラブルシューティングガイド](../user/group/saml_sso/troubleshooting.md)を参照してください。
