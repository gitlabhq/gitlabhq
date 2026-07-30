---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OmniAuth
description: 외부 인증을 타사 ID 공급자로 구성합니다.

---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

사용자는 Google, GitHub 및 기타 인기 있는 서비스의 자격 증명을 사용하여 GitLab에 로그인할 수 있습니다. [OmniAuth](https://rubygems.org/gems/omniauth/)는 GitLab이 이 인증을 제공하기 위해 사용하는 Rack 프레임워크입니다.

구성하면 추가 로그인 옵션이 로그인 페이지에 표시됩니다.

## 지원되는 공급자 {#supported-providers}

GitLab은 다음 OmniAuth 공급자를 지원합니다.

| 공급자 설명서                                              | OmniAuth 공급자 이름     |
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

## 일반 설정 구성 {#configure-common-settings}

OmniAuth 공급자를 구성하기 전에 모든 공급자에 공통인 설정을 구성합니다.

| 옵션 | 설명 |
| ------ | ----------- |
| `allow_bypass_two_factor`    | 사용자가 지정된 공급자로 2단계 인증(2FA) 없이 로그인할 수 있습니다. `true`, `false`, 또는 공급자 배열로 설정할 수 있습니다. 자세한 내용은 [2단계 인증 우회](#bypass-two-factor-authentication)를 참조하세요. |
| `allow_single_sign_on`       | OmniAuth로 로그인할 때 계정을 자동으로 생성합니다. `true`, `false` 또는 공급자 배열로 설정할 수 있습니다. 공급자 이름은 [지원되는 공급자 표](#supported-providers)를 참조하세요. `false`일 때 기존 GitLab 계정 없이 OmniAuth 공급자 계정으로 로그인할 수 없습니다. 먼저 GitLab 계정을 만든 다음 프로필 설정을 통해 OmniAuth 공급자 계정에 연결해야 합니다. |
| `auto_link_ldap_user`        | OmniAuth 공급자를 통해 생성된 사용자의 LDAP ID를 GitLab에서 생성합니다. 이 설정을 활성화하려면 [LDAP 통합](../administration/auth/ldap/_index.md)이 활성화되어 있어야 합니다. 사용자의 `uid`가 LDAP과 OmniAuth 공급자 모두에서 동일해야 합니다. |
| `auto_link_saml_user`        | SAML 공급자를 통해 인증하는 사용자가 이메일이 일치하면 현재 GitLab 사용자에게 자동으로 연결되도록 합니다. 이 설정을 활성화하려면 SAML 통합이 활성화되어 있어야 합니다. |
| `auto_link_user`             | OmniAuth 공급자를 통해 인증하는 사용자가 이메일이 일치하면 현재 GitLab 사용자에게 자동으로 연결되도록 합니다. `true`, `false`, 또는 공급자 배열로 설정할 수 있습니다. 공급자 이름은 [지원되는 공급자 표](#supported-providers)를 참조하세요. |
| `auto_sign_in_with_provider` | 사용자가 단일 공급자 이름을 사용하여 자동으로 로그인할 수 있습니다. 이는 `saml` 또는 `google_oauth2`와 같은 공급자의 이름과 일치해야 합니다. 무한 로그인 루프를 방지하려면 사용자가 GitLab에서 로그아웃하기 전에 ID 공급자 계정에서 로그아웃해야 합니다. [SAML](https://gitlab.com/gitlab-org/gitlab/-/issues/14414)과 같은 지속적인 기능 개선이 있어 지원되는 OmniAuth 공급자에 대한 페더레이션 로그아웃을 구현합니다. |
| `block_auto_created_users`   | 자동으로 생성된 사용자를 [승인 대기 중](../administration/moderate_users.md#users-pending-approval) 상태(로그인 불가)에 배치하며, 관리자가 승인할 때까지 유지합니다. `false`일 때 SAML 또는 Google과 같이 제어할 수 있는 공급자를 정의해야 합니다. 그렇지 않으면 인터넷의 모든 사용자가 관리자 승인 없이 GitLab에 로그인할 수 있습니다. `true`일 때 자동 생성된 사용자는 기본적으로 차단되며 로그인하기 전에 관리자가 차단을 해제해야 합니다. |
| `enabled`                    | GitLab에서 OmniAuth의 사용을 활성화하고 비활성화합니다. `false`일 때 OmniAuth 공급자 버튼이 사용자 인터페이스에 표시되지 않습니다. |
| `external_providers`         | OmniAuth 공급자를 `external`로 정의하여 이러한 공급자를 통해 계정을 생성하거나 로그인하는 모든 사용자가 내부 프로젝트에 액세스할 수 없도록 합니다. Google의 경우 `google_oauth2`와 같은 공급자의 전체 이름을 사용해야 합니다. 자세한 내용은 [외부 공급자 목록 만들기](#create-an-external-providers-list)를 참조하세요. |
| `providers`                  | 공급자 이름은 [지원되는 공급자 표](#supported-providers)에서 확인할 수 있습니다. |
| `sync_profile_attributes`    | 로그인할 때 공급자에서 동기화할 프로필 특성의 목록입니다. 자세한 내용은 [OmniAuth 사용자 프로필 최신 상태 유지](#keep-omniauth-user-profiles-up-to-date)를 참조하세요. |
| `sync_profile_from_provider` | GitLab이 프로필 정보를 자동으로 동기화해야 하는 공급자 이름의 목록입니다. 항목은 `saml` 또는 `google_oauth2`와 같은 공급자의 이름과 일치해야 합니다. 자세한 내용은 [OmniAuth 사용자 프로필 최신 상태 유지](#keep-omniauth-user-profiles-up-to-date)를 참조하세요. |

### 초기 설정 구성 {#configure-initial-settings}

OmniAuth 설정을 변경하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

   ```ruby
   # CAUTION!
   # This allows users to sign in without having a user account first. Define the allowed providers
   # using an array, for example, ["saml", "google_oauth2"], or as true/false to allow all providers or none.
   # User accounts will be created automatically when authentication was successful.
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'google_oauth2']
   gitlab_rails['omniauth_auto_link_ldap_user'] = true
   gitlab_rails['omniauth_block_auto_created_users'] = true
   ```

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집하고 `globals.appConfig` 아래의 `omniauth` 섹션을 업데이트합니다:

   ```yaml
   global:
     appConfig:
       omniauth:
         enabled: true
         allowSingleSignOn: ['saml', 'google_oauth2']
         autoLinkLdapUser: false
         blockAutoCreatedUsers: true
   ```

   자세한 내용은 [전역 설명서](https://docs.gitlab.com/charts/charts/globals/#omniauth)를 참조하세요.
1. 파일을 저장하고 새 값을 적용하세요:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

이 설정을 구성한 후 선택한 [공급자](#supported-providers)를 구성할 수 있습니다.

### 공급자별 구성 {#per-provider-configuration}

{{< history >}}

- GitLab 15.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89379)되었습니다.

{{< /history >}}

`allow_single_sign_on`이 설정되면 GitLab은 OmniAuth `auth_hash`에서 반환된 다음 필드 중 하나를 사용하여 로그인하는 사용자의 GitLab 사용자 이름을 설정하며, 존재하는 첫 번째 필드를 선택합니다:

- `username`.
- `nickname`.
- `email`.

공급자별로 GitLab 구성을 만들 수 있으며, `args`을 사용하여 [공급자](#supported-providers)에 제공됩니다. 공급자의 `args`에서 `gitlab_username_claim` 변수를 설정하면 GitLab 사용자 이름에 사용할 다른 클레임을 선택할 수 있습니다. 선택한 클레임은 충돌을 피하기 위해 고유해야 합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

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

{{< tab title="Self-compiled(source)" >}}

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

### OmniAuth를 통해 생성된 사용자의 비밀번호 {#passwords-for-users-created-via-omniauth}

[통합 인증을 통해 생성된 사용자용 생성된 비밀번호](../user/profile/user_passwords.md) 가이드는 GitLab이 OmniAuth를 사용하여 생성된 사용자의 비밀번호를 어떻게 생성하고 설정하는지에 대한 개요를 제공합니다.

## 기존 사용자에 대해 OmniAuth 활성화 {#enable-omniauth-for-an-existing-user}

기존 사용자인 경우 GitLab 계정을 생성한 후 OmniAuth 공급자를 활성화할 수 있습니다. 예를 들어 원래 LDAP로 로그인했다면 Google과 같은 OmniAuth 공급자를 활성화할 수 있습니다.

1. GitLab 자격 증명, LDAP 또는 다른 OmniAuth 공급자로 GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **비밀번호와 인증**을 선택합니다.
1. **서비스 로그인** 섹션에서 Google과 같은 OmniAuth 공급자를 선택합니다.
1. 공급자로 리디렉션됩니다. GitLab을 승인하면 GitLab으로 다시 리디렉션됩니다.

이제 선택한 OmniAuth 공급자를 사용하여 GitLab에 로그인할 수 있습니다.

## 가져오기 소스를 비활성화하지 않고 OmniAuth 공급자로 로그인 활성화 또는 비활성화 {#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources}

관리자는 일부 OmniAuth 공급자에 대한 로그인을 활성화하거나 비활성화할 수 있습니다.

> [!note]
> 기본적으로 로그인은 `config/gitlab.yml`에서 구성된 모든 OAuth 공급자에 대해 활성화됩니다.

OmniAuth 공급자를 활성화하거나 비활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **로그인 제한**을 확장합니다.
1. **활성화된 OAuth 인증 소스** 섹션에서 활성화 또는 비활성화할 각 공급자의 확인란을 선택하거나 선택 해제합니다.

## OmniAuth 비활성화 {#disable-omniauth}

OmniAuth는 기본적으로 활성화되어 있습니다. 그러나 OmniAuth는 공급자가 구성되고 [활성화](#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources)된 경우에만 작동합니다.

OmniAuth 공급자가 개별적으로 비활성화되어도 문제를 일으키는 경우 구성 파일을 수정하여 전체 OmniAuth 하위 시스템을 비활성화할 수 있습니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```ruby
gitlab_rails['omniauth_enabled'] = false
```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

```yaml
omniauth:
  enabled: false
```

{{< /tab >}}

{{< /tabs >}}

## 기존 사용자를 OmniAuth 사용자에 연결 {#link-existing-users-to-omniauth-users}

이메일 주소가 일치하면 기존 GitLab 사용자와 OmniAuth 사용자를 자동으로 연결할 수 있습니다.

다음 예는 OpenID Connect 공급자 및 Google OAuth 공급자에 대한 자동 연결을 활성화합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```ruby
gitlab_rails['omniauth_auto_link_user'] = ["openid_connect", "google_oauth2"]
```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

```yaml
omniauth:
  auto_link_user: ["openid_connect", "google_oauth2"]
```

{{< /tab >}}

{{< /tabs >}}

이 자동 연결 활성화 방법은 [SAML 제외](https://gitlab.com/gitlab-org/gitlab/-/issues/338293) 모든 공급자에 대해 작동합니다. SAML에 대한 자동 연결을 활성화하려면 [SAML 설정 지침](saml.md#configure-saml-support-in-gitlab)을 참조하세요.

## 외부 공급자 목록 만들기 {#create-an-external-providers-list}

외부 OmniAuth 공급자의 목록을 정의할 수 있습니다. 나열된 공급자를 통해 계정을 생성하거나 GitLab에 로그인하는 사용자는 [내부 프로젝트](../user/public_access.md#internal-projects-and-groups)에 액세스할 수 없으며 [외부 사용자](../administration/external_users.md)로 표시됩니다.

외부 공급자 목록을 정의하려면 Google의 경우 `google_oauth2`과 같은 공급자의 전체 이름을 사용합니다. 공급자 이름은 [지원되는 공급자 표](#supported-providers)의 **OmniAuth provider name** 열을 참조하세요.

> [!note]
> 외부 공급자 목록에서 OmniAuth 공급자를 제거하면 이 로그인 방법을 사용하는 사용자를 수동으로 업데이트하여 해당 계정을 전체 내부 계정으로 업그레이드해야 합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```ruby
gitlab_rails['omniauth_external_providers'] = ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

```yaml
omniauth:
  external_providers: ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< /tabs >}}

## OmniAuth 사용자 프로필 최신 상태 유지 {#keep-omniauth-user-profiles-up-to-date}

{{< history >}}

- [GitLab 17.9에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/505575) `job_title` 및 `organization` 특성입니다.

{{< /history >}}

> [!note]
> 일부 공급자는 이러한 특성을 동기화하기 위해 추가 구성이 필요합니다. 예를 들어 SAML 공급자는 [프로필 특성 매핑](saml.md#map-profile-attributes)이 필요합니다.

선택한 OmniAuth 공급자에서 프로필 동기화를 활성화할 수 있습니다. 다음 사용자 특성의 모든 조합을 동기화할 수 있습니다:

- `name`
- `email`
- `job_title`
- `location`
- `organization`

LDAP를 사용하여 인증할 때 사용자의 이름과 이메일은 항상 동기화됩니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

   ```ruby
   gitlab_rails['omniauth_sync_profile_from_provider'] = ['saml', 'google_oauth2']
   gitlab_rails['omniauth_sync_profile_attributes'] = ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > values.yaml
   ```

1. `values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         syncProfileFromProvider: ['saml', 'google_oauth2']
         syncProfileAttributes: ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. 파일을 저장하고 새 값을 적용하세요:

   ```shell
   helm upgrade -f values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을 편집합니다.

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_sync_profile_from_provider'] = ['saml', 'google_oauth2']
           gitlab_rails['omniauth_sync_profile_attributes'] = ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다.

   ```yaml
   production: &base
     omniauth:
       sync_profile_from_provider: ['saml', 'google_oauth2']
       sync_profile_attributes: ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 2단계 인증 바이패스 {#bypass-two-factor-authentication}

특정 OmniAuth 공급자를 사용하면 사용자가 2단계 인증(2FA) 없이 로그인할 수 있습니다.

2FA를 우회하려면 다음 중 하나를 수행할 수 있습니다:

- 배열을 사용하여 허용된 공급자를 정의합니다(예: `['saml', 'google_oauth2']`).
- 모든 공급자를 허용하려면 `true`을, 허용하지 않으려면 `false`을 지정합니다.

이 옵션은 이미 2FA가 있는 공급자에 대해서만 구성해야 합니다. 기본값은 `false`입니다.

이 구성은 SAML에는 적용되지 않습니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```ruby
gitlab_rails['omniauth_allow_bypass_two_factor'] = ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

```yaml
omniauth:
  allow_bypass_two_factor: ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< /tabs >}}

## 공급자로 자동으로 로그인 {#sign-in-with-a-provider-automatically}

GitLab 구성에 `auto_sign_in_with_provider` 설정을 추가하여 로그인 요청을 인증을 위해 OmniAuth 공급자로 리디렉션할 수 있습니다. 이렇게 하면 로그인하기 전에 공급자를 선택할 필요가 없어집니다.

예를 들어 [Azure v2 통합](azure.md)에 대한 자동 로그인을 활성화하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```ruby
gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'azure_activedirectory_v2'
```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

```yaml
omniauth:
  auto_sign_in_with_provider: azure_activedirectory_v2
```

{{< /tab >}}

{{< /tabs >}}

모든 로그인 시도가 OmniAuth 공급자로 리디렉션되므로 로컬 자격 증명으로 로그인할 수 없습니다. OmniAuth 사용자 중 최소 한 명이 관리자인지 확인합니다.

`https://gitlab.example.com/users/sign_in?auto_sign_in=false`을 탐색하여 자동 로그인을 우회할 수도 있습니다.

## 사용자 지정 OmniAuth 공급자 아이콘 사용 {#use-a-custom-omniauth-provider-icon}

지원되는 대부분의 공급자는 렌더링된 로그인 버튼용으로 기본 제공 아이콘을 포함합니다.

사용자 지정 아이콘을 사용하려면 64x64 픽셀에서 렌더링하도록 이미지를 최적화한 후 다음 두 가지 방법 중 하나로 아이콘을 재정의합니다:

- **Provide a custom image path**:

  1. GitLab 서버 도메인 외부에서 이미지를 호스팅하는 경우 [콘텐츠 보안 정책](https://docs.gitlab.com/omnibus/settings/configuration/#set-a-content-security-policy)이 이미지 파일에 대한 액세스를 허용하도록 구성되어 있는지 확인합니다.
  1. GitLab 설치 방법에 따라 GitLab 구성 파일에 사용자 지정 `icon` 매개변수를 추가합니다. OpenID Connect 공급자의 예는 [OpenID Connect OmniAuth 공급자](../administration/auth/oidc.md)를 참조하세요.
- **Embed an image directly in a configuration file**: 이 예에서는 [데이터 URL](https://developer.mozilla.org/en-US/docs/Web/URI/Reference/Schemes/data)을 통해 제공할 수 있는 이미지의 Base64로 인코딩된 버전을 만듭니다:

  1. GNU `base64` 명령(예: `base64 -w 0 <logo.png>`)으로 이미지 파일을 인코딩하면 단일 라인 `<base64-data>` 문자열이 반환됩니다.
  1. Base64로 인코딩된 데이터를 GitLab 구성 파일의 사용자 지정 `icon` 매개변수에 추가합니다:

     ```yaml
     omniauth:
       providers:
         - { name: '...'
             icon: 'data:image/png;base64,<base64-data>'
             # Additional parameters removed for readability
           }
     ```

## 앱 또는 구성 변경 {#change-apps-or-configuration}

GitLab의 OAuth는 동일한 외부 인증 및 권한 공급자를 여러 공급자로 설정하는 것을 지원하지 않으므로 공급자 또는 앱이 변경되면 GitLab 구성 및 사용자 식별이 동시에 업데이트되어야 합니다. 예를 들어 `saml` 및 `azure_activedirectory_v2`을 설정할 수 있지만 동일한 구성에 두 번째 `azure_activedirectory_v2`을 추가할 수 없습니다.

이 지침은 GitLab이 `extern_uid`을 저장하고 사용자 인증에 사용되는 유일한 데이터인 모든 인증 방법에 적용됩니다.

공급자 내에서 앱을 변경할 때 사용자 `extern_uid`이 변경되지 않으면 GitLab 구성만 업데이트하면 됩니다.

구성을 교환하려면:

1. `gitlab.rb` 파일에서 공급자 구성을 변경합니다.
1. 이전 공급자에 대해 GitLab에서 ID를 가진 모든 사용자의 `extern_uid`을 업데이트합니다.

`extern_uid`을 찾으려면 기존 사용자의 현재 `extern_uid`을 확인하여 현재 공급자에서 동일한 사용자의 적절한 필드와 일치하는 ID를 찾습니다.

`extern_uid`을 업데이트하는 두 가지 방법이 있습니다:

- [사용자 API](../api/users.md#modify-a-user)를 사용합니다. 공급자 이름과 새 `extern_uid`을 전달합니다.
- [Rails 콘솔](../administration/operations/rails_console.md)을 사용합니다:

  ```ruby
  Identity.where(extern_uid: 'old-id').update!(extern_uid: 'new-id')
  ```

## 알려진 이슈 {#known-issues}

지원되는 대부분의 OmniAuth 공급자는 HTTP 암호 인증을 통한 Git을 지원하지 않습니다. 임시 해결책으로 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을 사용하여 인증할 수 있습니다.
