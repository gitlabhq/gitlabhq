---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Self-Managed용 SAML SSO
description: 단일 사인온 액세스를 위한 SAML 통합으로 엔터프라이즈 인증을 구성합니다.
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

> [!note]
> GitLab.com의 경우 [GitLab.com 그룹용 SAML SSO](../user/group/saml_sso/_index.md)를 참조하세요.

이 페이지에서는 GitLab Self-Managed용 인스턴스 전체 SAML 단일 사인온(SSO)을 설정하는 방법을 설명합니다.

GitLab을 SAML 서비스 제공자(SP)로 작동하도록 구성할 수 있습니다. 이를 통해 GitLab은 Okta와 같은 SAML ID 공급자(IdP)의 어설션을 소비하여 사용자를 인증할 수 있습니다.

다음에 대한 자세한 정보:

- OmniAuth 제공자 설정은 [OmniAuth 문서](omniauth.md)를 참조하세요.
- 일반적으로 사용되는 용어는 [용어집](../auth/auth_glossary.md)을 참조하세요.

## GitLab에서 SAML 지원 구성 {#configure-saml-support-in-gitlab}

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. GitLab이 [HTTPS로 구성](https://docs.gitlab.com/omnibus/settings/ssl/)되어 있는지 확인하세요.
1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `saml`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 사용자가 계정을 먼저 수동으로 생성하지 않고도 SAML을 사용하여 가입할 수 있도록 하려면 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
   gitlab_rails['omniauth_block_auto_created_users'] = false
   ```

1. 선택 사항. 이메일 주소가 일치하는 경우 처음으로 SAML에 사인인한 기존 GitLab 사용자와 자동으로 연결해야 합니다. 이를 위해 `/etc/gitlab/gitlab.rb`에 다음 설정을 추가하세요:

   ```ruby
   gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   GitLab 계정의 기본 이메일 주소만 SAML 응답의 이메일과 비교됩니다.

   또는 사용자는 [기존 사용자에 대해 OmniAuth 활성화](omniauth.md#enable-omniauth-for-an-existing-user)를 통해 SAML 정체성을 기존 GitLab 계정에 수동으로 연결할 수 있습니다.
1. SAML 사용자가 변경할 수 없도록 다음 특성을 구성하세요:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email`(를) `omniauth_auto_link_saml_user`와(과) 함께 사용할 때.

   사용자가 이러한 특성을 변경할 수 있으면 다른 승인된 사용자로 사인인할 수 있습니다. 이러한 특성을 변경 불가능하게 만드는 방법에 대한 자세한 내용은 SAML IdP 문서를 참조하세요.
1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 제공자 구성을 추가하세요:

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

   | 인수                         | 설명 |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | GitLab HTTPS 끝점(GitLab 설치의 HTTPS URL에 `/users/auth/saml/callback`을(를) 추가)입니다. |
   | `idp_cert_fingerprint`           | IdP 값입니다. 인증서에서 SHA256 지문을 생성하려면 [지문 계산](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint)을 참조하세요. |
   | `idp_sso_target_url`             | IdP 값입니다. |
   | `issuer`                         | 애플리케이션을 IdP에 식별하는 고유한 이름으로 변경합니다. |
   | `name_identifier_format`         | IdP 값입니다. |

   이러한 값에 대한 자세한 내용은 [OmniAuth SAML 문서](https://github.com/omniauth/omniauth-saml)를 참조하세요. 다른 구성 설정에 대한 자세한 내용은 [IdP에서 SAML 구성](#configure-saml-on-your-idp)을 참조하세요.
1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. GitLab이 [HTTPS로 구성](https://docs.gitlab.com/charts/installation/tls/)되어 있는지 확인하세요.
1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `saml`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. 사용자가 계정을 먼저 수동으로 생성하지 않고도 SAML을 사용하여 가입할 수 있도록 하려면 `gitlab_values.yaml`을(를) 편집하세요:

   ```yaml
   global:
     appConfig:
       omniauth:
         enabled: true
         allowSingleSignOn: ['saml']
         blockAutoCreatedUsers: false
   ```

1. 선택 사항. 이메일 주소가 일치하는 경우 `gitlab_values.yaml`에 다음 설정을 추가하여 SAML 사용자를 기존 GitLab 사용자와 자동으로 연결할 수 있습니다:

   ```yaml
   global:
     appConfig:
       omniauth:
         autoLinkSamlUser: true
   ```

   또는 사용자는 [기존 사용자에 대해 OmniAuth 활성화](omniauth.md#enable-omniauth-for-an-existing-user)를 통해 SAML 정체성을 기존 GitLab 계정에 수동으로 연결할 수 있습니다.
1. SAML 사용자가 변경할 수 없도록 다음 특성을 구성하세요:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email`(를) `omniauth_auto_link_saml_user`와(과) 함께 사용할 때.

   사용자가 이러한 특성을 변경할 수 있으면 다른 승인된 사용자로 사인인할 수 있습니다. 이러한 특성을 변경 불가능하게 만드는 방법에 대한 자세한 내용은 SAML IdP 문서를 참조하세요.
1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

   | 인수                         | 설명 |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | GitLab HTTPS 끝점(GitLab 설치의 HTTPS URL에 `/users/auth/saml/callback`을(를) 추가)입니다. |
   | `idp_cert_fingerprint`           | IdP 값입니다. 인증서에서 SHA256 지문을 생성하려면 [지문 계산](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint)을 참조하세요. |
   | `idp_sso_target_url`             | IdP 값입니다. |
   | `issuer`                         | 애플리케이션을 IdP에 식별하는 고유한 이름으로 변경합니다. |
   | `name_identifier_format`         | IdP 값입니다. |

   이러한 값에 대한 자세한 내용은 [OmniAuth SAML 문서](https://github.com/omniauth/omniauth-saml)를 참조하세요. 다른 구성 설정에 대한 자세한 내용은 [IdP에서 SAML 구성](#configure-saml-on-your-idp)을 참조하세요.
1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집하고 제공자 구성을 추가하세요:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. 파일을 저장하고 새 값을 적용하세요:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. GitLab이 [HTTPS로 구성](https://docs.gitlab.com/omnibus/settings/ssl/)되어 있는지 확인하세요.
1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `saml`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 사용자가 계정을 먼저 수동으로 생성하지 않고도 SAML을 사용하여 가입할 수 있도록 하려면 `docker-compose.yml`을(를) 편집하세요:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
           gitlab_rails['omniauth_block_auto_created_users'] = false
   ```

1. 선택 사항. 이메일 주소가 일치하는 경우 `docker-compose.yml`에 다음 설정을 추가하여 SAML 사용자를 기존 GitLab 사용자와 자동으로 연결할 수 있습니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   또는 사용자는 [기존 사용자에 대해 OmniAuth 활성화](omniauth.md#enable-omniauth-for-an-existing-user)를 통해 SAML 정체성을 기존 GitLab 계정에 수동으로 연결할 수 있습니다.
1. SAML 사용자가 변경할 수 없도록 다음 특성을 구성하세요:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email`(를) `omniauth_auto_link_saml_user`와(과) 함께 사용할 때.

   사용자가 이러한 특성을 변경할 수 있으면 다른 승인된 사용자로 사인인할 수 있습니다. 이러한 특성을 변경 불가능하게 만드는 방법에 대한 자세한 내용은 SAML IdP 문서를 참조하세요.
1. `docker-compose.yml`을(를) 편집하고 제공자 구성을 추가하세요:

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

   | 인수                         | 설명 |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | GitLab HTTPS 끝점(GitLab 설치의 HTTPS URL에 `/users/auth/saml/callback`을(를) 추가)입니다. |
   | `idp_cert_fingerprint`           | IdP 값입니다. 인증서에서 SHA256 지문을 생성하려면 [지문 계산](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint)을 참조하세요. |
   | `idp_sso_target_url`             | IdP 값입니다. |
   | `issuer`                         | 애플리케이션을 IdP에 식별하는 고유한 이름으로 변경합니다. |
   | `name_identifier_format`         | IdP 값입니다. |

   이러한 값에 대한 자세한 내용은 [OmniAuth SAML 문서](https://github.com/omniauth/omniauth-saml)를 참조하세요. 다른 구성 설정에 대한 자세한 내용은 [IdP에서 SAML 구성](#configure-saml-on-your-idp)을 참조하세요.
1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

1. GitLab이 [HTTPS로 구성](../install/self_compiled/_index.md#using-https)되어 있는지 확인하세요.
1. [공통 설정](omniauth.md#configure-common-settings)을 구성하여 `saml`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.
1. 사용자가 계정을 먼저 수동으로 생성하지 않고도 SAML을 사용하여 가입할 수 있도록 하려면 `/home/git/gitlab/config/gitlab.yml`을(를) 편집하세요:

   ```yaml
   production: &base
     omniauth:
       enabled: true
       allow_single_sign_on: ["saml"]
       block_auto_created_users: false
   ```

1. 선택 사항. 이메일 주소가 일치하는 경우 `/home/git/gitlab/config/gitlab.yml`에 다음 설정을 추가하여 SAML 사용자를 기존 GitLab 사용자와 자동으로 연결할 수 있습니다:

   ```yaml
   production: &base
     omniauth:
       auto_link_saml_user: true
   ```

   또는 사용자는 [기존 사용자에 대해 OmniAuth 활성화](omniauth.md#enable-omniauth-for-an-existing-user)를 통해 SAML 정체성을 기존 GitLab 계정에 수동으로 연결할 수 있습니다.
1. SAML 사용자가 변경할 수 없도록 다음 특성을 구성하세요:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email`(를) `omniauth_auto_link_saml_user`와(과) 함께 사용할 때.

   사용자가 이러한 특성을 변경할 수 있으면 다른 승인된 사용자로 사인인할 수 있습니다. 이러한 특성을 변경 불가능하게 만드는 방법에 대한 자세한 내용은 SAML IdP 문서를 참조하세요.
1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 제공자 구성을 추가하세요:

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

   | 인수                         | 설명 |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | GitLab HTTPS 끝점(GitLab 설치의 HTTPS URL에 `/users/auth/saml/callback`을(를) 추가)입니다. |
   | `idp_cert_fingerprint`           | IdP 값입니다. 인증서에서 SHA256 지문을 생성하려면 [지문 계산](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint)을 참조하세요. |
   | `idp_sso_target_url`             | IdP 값입니다. |
   | `issuer`                         | 애플리케이션을 IdP에 식별하는 고유한 이름으로 변경합니다. |
   | `name_identifier_format`         | IdP 값입니다. |

   이러한 값에 대한 자세한 내용은 [OmniAuth SAML 문서](https://github.com/omniauth/omniauth-saml)를 참조하세요. 다른 구성 설정에 대한 자세한 내용은 [IdP에서 SAML 구성](#configure-saml-on-your-idp)을 참조하세요.
1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### SAML IdP에 GitLab 등록 {#register-gitlab-in-your-saml-idp}

1. `issuer`에 지정된 애플리케이션 이름을 사용하여 SAML IdP에 GitLab SP를 등록하세요.
1. IdP에 구성 정보를 제공하려면 애플리케이션의 메타데이터 URL을 빌드하세요. GitLab의 메타데이터 URL을 빌드하려면 GitLab 설치의 HTTPS URL에 `users/auth/saml/metadata`을(를) 추가하세요. 예를 들어:

   ```plaintext
   https://gitlab.example.com/users/auth/saml/metadata
   ```

   최소한 IdP는 **must** `email` 또는 `mail`을(를) 사용하여 사용자의 이메일 주소를 포함하는 클레임을 제공해야 합니다. 다른 사용 가능한 클레임에 대한 자세한 내용은 [어설션 구성](#configure-assertions)을 참조하세요.
1. 사인인 페이지에는 이제 일반 사인인 양식 아래에 SAML 아이콘이 있어야 합니다. 아이콘을 선택하여 인증 프로세스를 시작합니다. 인증이 성공하면 GitLab으로 반환되어 사인인됩니다.

### IdP에서 SAML 구성 {#configure-saml-on-your-idp}

IdP에서 SAML 애플리케이션을 구성하려면 최소한 다음 정보가 필요합니다:

- 어설션 소비자 서비스 URL.
- 발급자.
- [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
- [이메일 주소 클레임](#configure-assertions).

예제 구성은 [ID 공급자 설정](#set-up-identity-providers)을 참조하세요.

IdP에는 추가 구성이 필요할 수 있습니다. 자세한 내용은 [IdP의 SAML 앱에 대한 추가 구성](#additional-configuration-for-saml-apps-on-your-idp)을 참조하세요.

### 여러 SAML IdP를 사용하도록 GitLab 구성 {#configure-gitlab-to-use-multiple-saml-idps}

다음 경우에 여러 SAML IdP를 사용하도록 GitLab을 구성할 수 있습니다:

- 각 제공자는 `args`에 설정된 이름과 일치하는 고유한 이름 집합을 가집니다.
- 제공자의 이름은 다음과 같이 사용됩니다:
  - 제공자 이름을 기반으로 속성에 대한 OmniAuth 구성에서. 예를 들어 `allowBypassTwoFactor`, `allowSingleSignOn`, 및 `syncProfileFromProvider`.
  - 각 기존 사용자에 대한 추가 정체성으로의 연관.
- `assertion_consumer_service_url`이(가) 제공자 이름과 일치합니다.
- `strategy_class`은(는) 제공자 이름에서 추론할 수 없으므로 명시적으로 설정됩니다.

> [!note]
> 여러 SAML IdP를 구성할 때 SAML 그룹 링크가 작동하도록 하려면 모든 SAML IdP를 SAML 응답에 그룹 특성을 포함하도록 구성해야 합니다. 자세한 내용은 [SAML 그룹 링크](../user/group/saml_sso/group_sync.md)를 참조하세요.

여러 SAML IdP를 설정하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

   사용자가 제공자 중 하나에서 계정을 먼저 수동으로 생성하지 않고도 SAML을 사용하여 가입할 수 있도록 하려면 구성에 다음 값을 추가하세요:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml_2']
   ```

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. 첫 번째 SAML 제공자로 사용할 [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

   ```yaml
   name: 'saml' # At least one provider must be named 'saml'
   label: 'Provider 1' # Differentiate the two buttons and providers in the UI
   args:
     name: 'saml' # This is mandatory and must match the provider name
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback' # URL must match the name of the provider
     strategy_class: 'OmniAuth::Strategies::SAML' # Mandatory
     # Include all required arguments similar to a single provider
   ```

1. 두 번째 SAML 제공자로 사용할 [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml_2.yaml`이라는 파일에 다음 내용을 입력하세요:

   ```yaml
   name: 'saml_2'
   label: 'Provider 2' # Differentiate the two buttons and providers in the UI
   args:
     name: 'saml_2' # This is mandatory and must match the provider name
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback' # URL must match the name of the provider
     strategy_class: 'OmniAuth::Strategies::SAML' # Mandatory
     # Include all required arguments similar to a single provider
   ```

1. 선택 사항. 동일한 단계를 따르여 추가 SAML 제공자를 설정하세요.
1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml \
      --from-file=saml=saml.yaml \
      --from-file=saml_2=saml_2.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

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

   사용자가 제공자 중 하나에서 계정을 먼저 수동으로 생성하지 않고도 SAML을 사용하여 가입할 수 있도록 하려면 구성에 다음 값을 추가하세요:

   ```yaml
   global:
     appConfig:
       omniauth:
         allowSingleSignOn: ['saml', 'saml_2']
   ```

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

   사용자가 제공자 중 하나에서 계정을 먼저 수동으로 생성하지 않고도 SAML을 사용하여 가입할 수 있도록 하려면 구성에 다음 값을 추가하세요:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml_2']
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

   사용자가 제공자 중 하나에서 계정을 먼저 수동으로 생성하지 않고도 SAML을 사용하여 가입할 수 있도록 하려면 구성에 다음 값을 추가하세요:

   ```yaml
   production: &base
     omniauth:
       allow_single_sign_on: ["saml", "saml_2"]
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

## ID 공급자 설정 {#set-up-identity-providers}

GitLab SAML 지원은 다양한 IdP를 통해 GitLab에 사인인할 수 있음을 의미합니다.

GitLab은 Okta 및 Google Workspace IdP 설정에 대한 다음 내용을 참고용으로만 제공합니다. 이러한 IdP 중 하나를 구성하는 방법에 대해 질문이 있는 경우 공급자의 지원팀에 문의하세요.

### Okta 설정 {#set-up-okta}

1. Okta 관리자 섹션에서 **응용 프로그램**을 선택하세요.
1. 앱 화면에서 **Create App Integration**을 선택한 후 다음 화면에서 **SAML 2.0**을 선택하세요.
1. 선택 사항. [GitLab Press](https://about.gitlab.com/press/press-kit/)에서 로고를 선택하여 추가하세요. 로고를 자르고 크기를 조정해야 합니다.
1. SAML 일반 구성을 완료하세요. 입력:
   - `"Single sign-on URL"`: 어설션 소비자 서비스 URL을 사용하세요.
   - `"Audience URI"`: 발급자를 사용하세요.
   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - [어설션](#configure-assertions).
1. 피드백 섹션에 귀사가 고객이며 내부 사용을 위한 앱을 생성하고 있다고 입력하세요.
1. 새 앱의 프로필 상단에서 **SAML 2.0 configuration instructions**을 선택하세요.
1. **Identity Provider Single Sign-On URL**을(를) 기록하세요. GitLab 구성 파일에서 `idp_sso_target_url`의 이 URL을 사용하세요.
1. Okta에서 로그아웃하기 전에 사용자와 그룹이 있으면 추가하세요.

### Google Workspace 설정 {#set-up-google-workspace}

전제 조건:

- [Google Workspace 슈퍼 관리자 계정](https://support.google.com/a/answer/2405986#super_admin)에 액세스할 수 있는지 확인하세요.

Google Workspace를 설정하려면:

1. 다음 정보를 사용하여 [Google Workspace에서 자신의 사용자 정의 SAML 애플리케이션 설정](https://support.google.com/a/answer/6087519?hl=en)의 지침을 따르세요.

   |                  | 일반적인 값                                      | 설명                                                                                   |
   |:-----------------|:---------------------------------------------------|:----------------------------------------------------------------------------------------------|
   | SAML 앱 이름 | GitLab                                             | 다른 이름도 가능합니다.                                                                               |
   | ACS URL          | `https://<GITLAB_DOMAIN>/users/auth/saml/callback` | 어설션 소비자 서비스 URL.                                                               |
   | `GITLAB_DOMAIN`  | `gitlab.example.com`                               | GitLab 인스턴스 도메인.                                                                  |
   | 엔터티 ID        | `https://gitlab.example.com`                       | SAML 애플리케이션에 고유한 값입니다. GitLab 구성에서 `issuer`로 설정하세요. |
   | 이름 ID 형식   | `EMAIL`                                            | 필수 값입니다. `name_identifier_format`로도 알려져 있습니다.                                       |
   | 이름 ID          | 기본 이메일 주소                              | 사용자의 이메일 주소입니다. 해당 주소로 전송된 콘텐츠를 받을 사람이 있는지 확인하세요.                  |
   | 이름       | `first_name`                                       | 이름. GitLab과 통신하는 데 필요한 값입니다. GitLab과 통신하는 데 필요한 값입니다.                                        |
   | 성        | `last_name`                                        | 성. GitLab과 통신하는 데 필요한 값입니다. GitLab과 통신하는 데 필요한 값입니다.                                         |

1. 다음 SAML 특성 매핑을 설정하세요:

   | Google 디렉터리 특성       | 앱 특성 |
   |-----------------------------------|----------------|
   | 기본 정보 > 이메일         | `email`        |
   | 기본 정보 > 이름    | `first_name`   |
   | 기본 정보 > 성     | `last_name`    |

   [GitLab에서 SAML 지원 구성](#configure-saml-support-in-gitlab)할 때 이 정보의 일부를 사용할 수 있습니다.

Google Workspace SAML 애플리케이션을 구성할 때 다음 정보를 기록하세요:

|                    | 값        | 설명 |
| ------------------ | ------------ | ----------- |
| SSO URL            | 종속      | Google ID 공급자 세부 정보입니다. GitLab `idp_sso_target_url` 설정으로 설정하세요. |
| 인증서        | 다운로드 가능 | Google SAML 인증서. |
| SHA256 지문 | 종속      | 인증서를 다운로드할 때 사용 가능합니다. 인증서에서 SHA256 지문을 생성하려면 [지문 계산](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint)을 참조하세요. |

Google Workspace 관리자는 또한 IdP 메타데이터, 엔터티 ID 및 SHA-256 지문을 제공합니다. 그러나 GitLab은 Google Workspace SAML 애플리케이션에 연결하기 위해 이 정보가 필요하지 않습니다.

### Microsoft Entra ID 설정 {#set-up-microsoft-entra-id}

1. [Microsoft Entra 관리 센터](https://entra.microsoft.com/)에 사인인하세요.
1. [갤러리가 아닌 애플리케이션 생성](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/overview-application-gallery#create-your-own-application).
1. [해당 애플리케이션에 대해 SSO 구성](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso).

   `gitlab.rb` 파일의 다음 설정은 Microsoft Entra ID 필드에 해당합니다:

   | `gitlab.rb` 설정                 | Microsoft Entra ID 필드                       |
   | ------------------------------------| ---------------------------------------------- |
   | `issuer`                           | **Identifier (Entity ID)**                     |
   | `assertion_consumer_service_url`   | **Reply URL (Assertion Consumer Service URL)** |
   | `idp_sso_target_url`               | **Login URL**                                  |
   | `idp_cert_fingerprint`             | **Thumbprint**                                 |

1. 다음 특성을 설정하세요:
   - **Unique User Identifier (Name ID)**를 `user.objectID`로 설정합니다.
     - **Name identifier format**을 `persistent`으로 설정합니다. 자세한 내용은 [사용자 SAML 정체성 관리](../user/group/saml_sso/_index.md#manage-user-saml-identity) 방법을 참조하세요.
   - **Additional claims**을 [지원되는 특성](#configure-assertions)로 설정합니다.

자세한 내용은 [예제 구성 페이지](../user/group/saml_sso/example_saml_config.md#azure-active-directory)를 참조하세요.

### 다른 IdP 설정 {#set-up-other-idps}

일부 IdP에는 SAML 구성에서 IdP로 사용하는 방법에 대한 문서가 있습니다. 예를 들어:

- [Active Directory Federation Services(ADFS)](https://learn.microsoft.com/en-us/previous-versions/windows-server/it-pro/windows-server-2012/identity/ad-fs/operations/Create-a-Relying-Party-Trust)
- [Auth0](https://auth0.com/docs/authenticate/single-sign-on/outbound-single-sign-on/configure-auth0-saml-identity-provider)

SAML 구성에서 IdP 구성에 대한 질문이 있는 경우 공급자의 지원팀에 문의하세요.

### 어설션 구성 {#configure-assertions}

{{< details >}}

- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Microsoft Azure/Entra ID 특성 지원은 GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/420766)되었습니다.

{{< /history >}}

> [!note]
> 이러한 특성은 대소문자를 구분합니다.

| 필드           | 지원되는 기본 키                                                                                                                                                         |
|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 이메일(필수)| `email`, `mail`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/emailaddress`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/email`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/email`, `urn:oid:0.9.2342.19200300.100.1.3`                  |
| 전체 이름       | `name`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/name`, `urn:oid:2.16.840.1.113730.3.1.241`, `urn:oid:2.5.4.3`                                           |
| 이름      | `first_name`, `firstname`, `firstName`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/givenname`, `urn:oid:2.5.4.42` |
| 성       | `last_name`, `lastname`, `lastName`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/surname`, `urn:oid:2.5.4.4`   |

GitLab이 SAML SSO 제공자로부터 SAML 응답을 받으면 GitLab은 attribute `name` 필드에서 다음 값을 찾습니다:

- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"`
- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"`
- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"`
- `firstname`
- `lastname`
- `email`

GitLab이 SAML 응답을 구문 분석할 수 있도록 attribute `Name` 필드에 이러한 값을 올바르게 포함해야 합니다. 예를 들어 GitLab은 다음 SAML 응답 스니펫을 구문 분석할 수 있습니다:

- `Name` 특성이 이전 테이블의 필수 값 중 하나로 설정되어 있으므로 이것은 승인됩니다.

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

- `Name` 특성이 이전 테이블의 값 중 하나와 일치하므로 이것은 승인됩니다.

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

그러나 GitLab은 다음 SAML 응답 스니펫을 구문 분석할 수 없습니다:

- `Name` 특성의 값이 이전 테이블의 지원되는 값 중 하나가 아니기 때문에 이것은 승인되지 않습니다.

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

- `FriendlyName`이(가) 지원되는 값을 가지고 있더라도 `Name` 특성은 그렇지 않기 때문에 이것은 실패합니다.

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

다음을 위해 [`attribute_statements`](#map-saml-response-attribute-names)를 참조하세요:

- 사용자 정의 어설션 구성 예제입니다.
- 사용자 정의 사용자 이름 특성을 구성하는 방법입니다.

지원되는 모든 어설션 목록은 [OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml/blob/master/lib/omniauth/strategies/saml.rb)을 참조하세요.

## SAML 그룹 멤버십을 기반으로 사용자 구성 {#configure-users-based-on-saml-group-membership}

다음을 수행할 수 있습니다.

- 특정 그룹의 구성원이 되도록 사용자를 요구합니다.
- 그룹 멤버십을 기반으로 사용자를 [외부](../administration/external_users.md), 관리자 또는 [감사자](../administration/auditor_users.md) 역할로 할당합니다.

GitLab은 각 SAML 사인인 시 이러한 그룹을 확인하고 필요에 따라 사용자 특성을 업데이트합니다. 이 기능은 사용자를 GitLab [그룹](../user/group/_index.md)에 자동으로 추가할 수 없습니다.

이러한 그룹에 대한 지원은 다음에 따라 달라집니다:

- 사용자의 [구독](https://about.gitlab.com/pricing/).
- [GitLab Enterprise Edition(EE)](https://about.gitlab.com/install/)을(를) 설치했는지 여부.

| 그룹                        | 티어               | GitLab Enterprise Edition(EE) 전용? |
|------------------------------|--------------------|--------------------------------------|
| [필수](#required-groups) | Free, Premium, Ultimate | 예                                  |
| [외부](#external-groups) | Free, Premium, Ultimate | 아니요                                   |
| [관리자](#administrator-groups) | Free, Premium, Ultimate | 예                                  |
| [감사자](#auditor-groups)   | Premium, Ultimate | 예                                  |

전제 조건:

- GitLab에 그룹 정보를 찾을 위치를 알려야 합니다. 이를 위해 IdP 서버가 일반 SAML 응답과 함께 특정 `AttributeStatement`을(를) 전송하는지 확인하세요. 예를 들어:

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

  특성의 이름은 사용자가 속한 그룹을 포함해야 합니다. GitLab에 이러한 그룹을 찾을 위치를 알리려면 SAML 설정에 `groups_attribute:` 요소를 추가하세요. 이 특성은 대소문자를 구분합니다.

### 필수 그룹 {#required-groups}

IdP가 SAML 응답의 그룹 정보를 GitLab에 전달합니다. 이 응답을 사용하려면 GitLab을 다음과 같이 구성하세요:

- `groups_attribute` 설정을 사용하여 SAML 응답에서 그룹을 찾을 위치입니다.
- 그룹 또는 사용자 설정을 사용하여 그룹 또는 사용자에 대한 정보입니다.

`required_groups` 설정을 사용하여 사인인하는 데 필요한 그룹 멤버십을 식별하도록 GitLab을 구성합니다.

`required_groups`을(를) 설정하지 않거나 설정을 비워두면 적절한 인증을 가진 모든 사람이 서비스를 사용할 수 있습니다.

`groups_attribute`에 지정된 특성이 없거나 누락되면 모든 사용자가 차단됩니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### 외부 그룹 {#external-groups}

IdP가 SAML 응답의 그룹 정보를 GitLab에 전달합니다. 이 응답을 사용하려면 GitLab을 다음과 같이 구성하세요:

- `groups_attribute` 설정을 사용하여 SAML 응답에서 그룹을 찾을 위치입니다.
- 그룹 또는 사용자 설정을 사용하여 그룹 또는 사용자에 대한 정보입니다.

SAML은 `external_groups` 설정을 기반으로 사용자를 [외부 사용자](../administration/external_users.md)로 자동으로 식별할 수 있습니다.

> [!note]
> `groups_attribute`에 지정된 특성이 없거나 누락되면 사용자는 표준 사용자로 액세스합니다.

예제 구성:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### 관리자 그룹 {#administrator-groups}

IdP가 SAML 응답의 그룹 정보를 GitLab에 전달합니다. 이 응답을 사용하려면 GitLab을 다음과 같이 구성하세요:

- `groups_attribute` 설정을 사용하여 SAML 응답에서 그룹을 찾을 위치입니다.
- 그룹 또는 사용자 설정을 사용하여 그룹 또는 사용자에 대한 정보입니다.

`admin_groups` 설정을 사용하여 사용자에게 관리자 액세스 권한을 부여하는 그룹을 식별하도록 GitLab을 구성합니다.

`groups_attribute`에 지정된 특성이 없거나 누락되면 사용자가 관리자 액세스 권한을 잃게 됩니다.

예제 구성:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### 감사자 그룹 {#auditor-groups}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

IdP가 SAML 응답의 그룹 정보를 GitLab에 전달합니다. 이 응답을 사용하려면 GitLab을 다음과 같이 구성하세요:

- `groups_attribute` 설정을 사용하여 SAML 응답에서 그룹을 찾을 위치입니다.
- 그룹 또는 사용자 설정을 사용하여 그룹 또는 사용자에 대한 정보입니다.

`auditor_groups` 설정을 사용하여 [감사자 액세스 권한](../administration/auditor_users.md)을(를) 가진 사용자를 포함하는 그룹을 식별하도록 GitLab을 구성합니다.

`groups_attribute`에 지정된 특성이 없거나 누락되면 사용자가 감사자 액세스 권한을 잃게 됩니다.

예제 구성:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## SAML 그룹 동기화 자동 관리 {#automatically-manage-saml-group-sync}

GitLab 그룹 멤버십 자동 관리에 대한 정보는 [SAML 그룹 동기화](../user/group/saml_sso/group_sync.md)를 참조하세요.

### SAML 세션 시간 제한 사용자 정의 {#customize-saml-session-timeout}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/262074)되었으며 `saml_timeout_supplied_by_idp_override` 이름의 [기능 플래그](../administration/feature_flags/_index.md)를 사용합니다.
- GitLab 18.3에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/work_items/553931)되었습니다.

{{< /history >}}

기본적으로 GitLab은 24시간 후에 SAML 세션을 종료합니다. SAML2 AuthnStatement의 `SessionNotOnOrAfter` 특성을 사용하여 이 기간을 사용자 정의할 수 있습니다. 이 특성에는 사용자 세션을 종료할 시기를 나타내는 ISO 8601 타임스탬프 값이 포함됩니다. 지정되면 이 값은 24시간의 기본 SAML 세션 시간 제한을 재정의합니다.

인스턴스에 `SessionNotOnOrAfter` 타임스탬프보다 빠른 사용자 정의 [세션 기간](../administration/settings/account_and_limit_settings.md#session-duration)이 구성된 경우 GitLab 사용자 세션이 종료될 때 사용자가 다시 인증해야 합니다.

## 2단계 인증 바이패스 {#bypass-two-factor-authentication}

{{< history >}}

- 2FA 적용 바이패스는 GitLab 16.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122109)되었으며 `by_pass_two_factor_current_session` 이름의 [기능 플래그](../administration/feature_flags/_index.md)를 사용합니다.
- GitLab 17.8에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/416535)되었습니다.

{{< /history >}}

SAML 인증 방법을 세션당 기준으로 2단계 인증(2FA)으로 계산되도록 구성하려면 `upstream_two_factor_authn_contexts` 목록에 해당 방법을 등록하세요.

1. IdP가 `AuthnContext`을(를) 반환하는지 확인하세요. 예를 들어:

   ```xml
   <saml:AuthnStatement>
       <saml:AuthnContext>
           <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:MediumStrongCertificateProtectedTransport</saml:AuthnContextClassRef>
       </saml:AuthnContext>
   </saml:AuthnStatement>
   ```

1. SAML 인증 방법을 `upstream_two_factor_authn_contexts` 목록에 등록하도록 설치를 구성하세요. SAML 응답에서 `AuthnContext`을(를) 입력해야 합니다.

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

   1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

   1. 파일을 저장하고 GitLab을 다시 구성합니다.

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Helm 차트(Kubernetes)" >}}

   1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

   1. Kubernetes Secret을 생성합니다:

      ```shell
      kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
      ```

   1. Helm 값을 내보냅니다:

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. `gitlab_values.yaml`을 편집합니다.

      ```yaml
      global:
        appConfig:
          omniauth:
            providers:
              - secret: gitlab-saml
      ```

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

   1. 파일을 저장하고 GitLab을 다시 시작합니다.

      ```shell
      # For systems running systemd
      sudo systemctl restart gitlab.target

      # For systems running SysV init
      sudo service gitlab restart
      ```

   {{< /tab >}}

   {{< /tabs >}}

## 응답 서명 검증 {#validate-response-signatures}

IdP는 어설션이 변조되지 않았는지 확인하기 위해 SAML 응답에 서명해야 합니다.

이는 특정 그룹 멤버십이 필요할 때 사용자 가장 및 권한 상승을 방지합니다.

### `idp_cert_fingerprint` 사용 {#using-idp_cert_fingerprint}

`idp_cert_fingerprint`을(를) 사용하여 응답 서명 유효성 검사를 구성할 수 있습니다. 예제 구성:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### `idp_cert` 사용 {#using-idp_cert}

`idp_cert`을(를) 사용하여 GitLab을 직접 구성할 수도 있습니다. 예제 구성:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

응답 서명 유효성 검사를 잘못 구성한 경우 다음과 같은 오류 메시지가 표시될 수 있습니다:

- 키 유효성 검사 오류입니다.
- 다이제스트 불일치.
- 지문 불일치.

이러한 오류를 해결하는 방법에 대한 자세한 내용은 [SAML 문제 해결 가이드](../user/group/saml_sso/troubleshooting.md)를 참조하세요.

## SAML 설정 사용자 정의 {#customize-saml-settings}

### SAML 서버로 인증을 위해 사용자 리디렉션 {#redirect-users-to-saml-server-for-authentication}

`auto_sign_in_with_provider` 설정을 GitLab 구성에 추가하여 SAML 서버로 자동 리디렉션할 수 있습니다. 이렇게 하면 실제로 사인인하기 전에 요소를 선택할 필요가 없습니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

   ```ruby
   gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
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

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         autoSignInWithProvider: 'saml'
   ```

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
           gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
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
       auto_sign_in_with_provider: 'saml'
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

모든 사인인 시도는 SAML 서버로 리디렉션되므로 로컬 자격 증명을 사용하여 사인인할 수 없습니다. 최소한 SAML 사용자 중 하나가 관리자 액세스 권한을 가지고 있는지 확인하세요.

> [!note]
> 자동 사인인 설정을 바이패스하려면 사인인 URL에 `?auto_sign_in=false`을(를) 추가하세요. 예: `https://gitlab.example.com/users/sign_in?auto_sign_in=false`.

### SAML 응답 특성 이름 매핑 {#map-saml-response-attribute-names}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

`attribute_statements`을(를) 사용하여 SAML 응답의 특성 이름을 OmniAuth [`info` 해시](https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema#schema-10-and-later)의 항목으로 매핑할 수 있습니다.

> [!note]
> OmniAuth `info` 해시 스키마의 일부인 특성만 매핑하는 데 이 설정을 사용하세요.

예를 들어 `SAMLResponse`에 `EmailAddress`이라는 특성이 포함되어 있으면 `{ email: ['EmailAddress'] }`을(를) 지정하여 특성을 `info` 해시의 해당 키로 매핑하세요. URI 명명 특성도 지원되며, 예를 들어 `{ email: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] }`.

이 설정을 사용하여 GitLab에 계정을 생성하는 데 필요한 특정 특성을 찾을 위치를 알립니다. 예를 들어 IdP가 사용자의 이메일 주소를 `EmailAddress` 대신 `email`로 보내면 GitLab 구성에서 설정하여 GitLab에 알리세요:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

#### 사용자 이름 설정 {#set-a-username}

기본적으로 SAML 응답의 이메일 주소의 로컬 부분을 사용하여 사용자의 GitLab 사용자 이름을 생성합니다.

`attribute_statements`에서 [`username` 또는 `nickname`](omniauth.md#per-provider-configuration)을(를) 구성하여 사용자의 원하는 사용자 이름을 포함하는 하나 이상의 특성을 지정하세요:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

이는 또한 SAML 응답의 `username` 특성을 GitLab의 사용자 이름으로 설정합니다.

#### 프로필 특성 매핑 {#map-profile-attributes}

{{< history >}}

- `job_title` 및 `organization` 특성이 GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/505575)되었습니다.

{{< /history >}}

SAML 제공자의 프로필 정보를 동기화하려면 이러한 특성을 매핑하도록 `attribute_statements`을(를) 구성해야 합니다.

지원되는 프로필 특성은:

- `job_title`
- `organization`

이러한 특성은 기본 매핑이 없으며 명시적으로 구성되지 않으면 동기화되지 않습니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. [원하는 특성을 동기화하도록 OmniAuth 구성](omniauth.md#keep-omniauth-user-profiles-up-to-date).
1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [원하는 특성을 동기화하도록 OmniAuth 구성](omniauth.md#keep-omniauth-user-profiles-up-to-date).
1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 YAML 콘텐츠를 저장하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. 파일을 저장하고 새 값을 적용하세요:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. [원하는 특성을 동기화하도록 OmniAuth 구성](omniauth.md#keep-omniauth-user-profiles-up-to-date).
1. `docker-compose.yml`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

1. [원하는 특성을 동기화하도록 OmniAuth 구성](omniauth.md#keep-omniauth-user-profiles-up-to-date).
1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### 시계 드리프트 허용 {#allow-for-clock-drift}

IdP의 시계가 시스템 시계보다 약간 앞으로 표류할 수 있습니다. 작은 양의 시계 드리프트를 허용하려면 설정에서 `allowed_clock_drift`을(를) 사용하세요. 매개변수의 값을 초의 숫자와 분수로 입력해야 합니다. 주어진 값은 응답을 검증하는 현재 시간에 추가됩니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### `uid`(선택 사항)에 대한 고유한 특성 지정 {#designate-a-unique-attribute-for-the-uid-optional}

기본적으로 사용자 `uid`은(는) SAML 응답의 `NameID` 특성으로 설정됩니다. `uid`에 대해 다른 특성을 지정하려면 `uid_attribute`을(를) 설정할 수 있습니다.

`uid`을(를) 고유한 특성으로 설정하기 전에 SAML 사용자가 변경할 수 없도록 다음 특성을 구성했는지 확인하세요:

- [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
- `Email`(를) `omniauth_auto_link_saml_user`와(과) 함께 사용할 때.

사용자가 이러한 특성을 변경할 수 있으면 다른 승인된 사용자로 사인인할 수 있습니다. 이러한 특성을 변경 불가능하게 만드는 방법에 대한 자세한 내용은 SAML IdP 문서를 참조하세요. 다음 예제에서 SAML 응답의 `uid` 특성 값은 `uid_attribute`로 설정됩니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 어설션 암호화(선택 사항) {#assertion-encryption-optional}

SAML 어설션 암호화는 선택 사항이지만 권장됩니다. 이는 암호화되지 않은 데이터가 기록되거나 악의적인 행위자에 의해 가로채지는 것을 방지하기 위한 추가 보호 계층을 추가합니다.

> [!note]
> 이 통합은 어설션 암호화 및 요청 서명 모두에 `certificate` 및 `private_key` 설정을 사용합니다.

SAML 어설션을 암호화하려면 GitLab SAML 설정에 개인 키와 공개 인증서를 정의하세요. IdP는 공개 인증서로 어설션을 암호화하고 GitLab은 개인 키로 어설션을 암호 해제합니다.

키와 인증서를 정의할 때 키 파일의 모든 줄 바꿈을 `\n`로 바꾸세요. 이렇게 하면 키 파일이 줄 바꿈이 없는 긴 문자열이 됩니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## SAML 인증 요청 서명(선택 사항) {#sign-saml-authentication-requests-optional}

GitLab이 SAML 인증 요청에 서명하도록 구성할 수 있습니다. GitLab SAML 요청이 SAML 리디렉션 바인딩을 사용하므로 이 구성은 선택 사항입니다.

서명을 구현하려면:

1. GitLab 인스턴스가 SAML에 사용할 개인 키와 공개 인증서 쌍을 생성하세요.
1. 구성의 `security` 섹션에서 서명 설정을 구성하세요. 예를 들어:

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

   1. `/etc/gitlab/gitlab.rb`을 편집합니다.

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

   1. 파일을 저장하고 GitLab을 다시 구성합니다.

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Helm 차트(Kubernetes)" >}}

   1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `saml.yaml`이라는 파일에 다음 내용을 입력하세요:

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

   1. Kubernetes Secret을 생성합니다:

      ```shell
      kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
      ```

   1. Helm 값을 내보냅니다:

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. `gitlab_values.yaml`을 편집합니다.

      ```yaml
      global:
        appConfig:
          omniauth:
            providers:
              - secret: gitlab-saml
      ```

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

   1. 파일을 저장하고 GitLab을 다시 시작합니다.

      ```shell
      # For systems running systemd
      sudo systemctl restart gitlab.target

      # For systems running SysV init
      sudo service gitlab restart
      ```

   {{< /tab >}}

   {{< /tabs >}}

그러면 GitLab이:

- 제공된 개인 키로 요청에 서명합니다.
- 구성된 공개 x500 인증서를 메타데이터에 포함하여 IdP가 수신된 요청의 서명을 검증할 수 있습니다.

이 옵션에 대한 자세한 내용은 [Ruby SAML gem 문서](https://github.com/SAML-Toolkits/ruby-saml/tree/v1.7.0)를 참조하세요.

Ruby SAML gem은 [OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml)에서 SAML 인증의 클라이언트 측을 구현하는 데 사용됩니다.

> [!note]
> SAML 리디렉션 바인딩은 SAML POST 바인딩과 다릅니다. POST 바인딩에서는 중간자가 요청을 변조하는 것을 방지하기 위해 서명이 필요합니다.

## SAML을 통해 생성된 사용자의 암호 생성 {#password-generation-for-users-created-through-saml}

GitLab [SAML을 통해 생성된 사용자를 위해 암호를 생성하고 설정합니다](../user/profile/user_passwords.md).

SSO 또는 SAML로 인증된 사용자는 HTTPS를 통한 Git 작업에 암호를 사용하면 안 됩니다. 이러한 사용자는 대신:

- [개인](../user/profile/personal_access_tokens.md), [프로젝트](../user/project/settings/project_access_tokens.md), 또는 [그룹](../user/group/settings/group_access_tokens.md) 액세스 토큰을 설정하세요.
- [OAuth 자격 증명 도우미](../user/profile/account/two_factor_authentication.md#oauth-credential-helpers)를 사용하세요.

## 기존 사용자의 SAML 정체성 연결 {#link-saml-identity-for-an-existing-user}

관리자는 SAML 사용자를 기존 GitLab 사용자와 자동으로 연결하도록 GitLab을 구성할 수 있습니다. 자세한 내용은 [GitLab에서 SAML 지원 구성](#configure-saml-support-in-gitlab)을 참조하세요.

사용자는 SAML 정체성을 기존 GitLab 계정에 수동으로 연결할 수 있습니다. 자세한 내용은 [기존 사용자에 대해 OmniAuth 활성화](omniauth.md#enable-omniauth-for-an-existing-user)를 참조하세요.

## GitLab Self-Managed에서 그룹 SAML SSO 구성 {#configure-group-saml-sso-on-gitlab-self-managed}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Self-Managed 인스턴스에서 여러 SAML IdP를 통한 액세스를 허용해야 하는 경우 그룹 SAML SSO를 사용합니다.

그룹 SAML SSO를 구성하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. GitLab이 [HTTPS로 구성](https://docs.gitlab.com/omnibus/settings/ssl/)되어 있는지 확인하세요.
1. `/etc/gitlab/gitlab.rb`을(를) 편집하여 OmniAuth 및 `group_saml` 제공자를 활성화하세요:

   ```ruby
   gitlab_rails['omniauth_enabled'] = true
   gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. GitLab이 [HTTPS로 구성](https://docs.gitlab.com/charts/installation/tls/)되어 있는지 확인하세요.
1. [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#providers)으로 사용할 `group_saml.yaml`이라는 파일에 다음 내용을 입력하세요:

   ```yaml
   name: 'group_saml'
   ```

1. Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-group-saml --from-file=provider=group_saml.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집하여 OmniAuth 및 `group_saml` 제공자를 활성화하세요:

   ```yaml
   global:
     appConfig:
       omniauth:
         enabled: true
         providers:
           - secret: gitlab-group-saml
   ```

1. 파일을 저장하고 새 값을 적용하세요:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. GitLab이 [HTTPS로 구성](https://docs.gitlab.com/omnibus/settings/ssl/)되어 있는지 확인하세요.
1. `docker-compose.yml`을(를) 편집하여 OmniAuth 및 `group_saml` 제공자를 활성화하세요:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_enabled'] = true
           gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다.

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

1. GitLab이 [HTTPS로 구성](../install/self_compiled/_index.md#using-https)되어 있는지 확인하세요.
1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하여 OmniAuth 및 `group_saml` 제공자를 활성화하세요:

   ```yaml
   production: &base
     omniauth:
       enabled: true
       providers:
         - { name: 'group_saml' }
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

다중 테넌트 솔루션인 GitLab Self-Managed의 그룹 SAML은 권장되는 [인스턴스 전체 SAML](saml.md)과 비교하여 제한됩니다. 인스턴스 전체 SAML을 사용하여 다음을 활용하세요:

- [LDAP 호환성](../administration/auth/ldap/_index.md).
- [LDAP 그룹 동기화](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap).
- [필수 그룹](#required-groups).
- [관리자 그룹](#administrator-groups).
- [감사자 그룹](#auditor-groups).

## IdP의 SAML 앱에 대한 추가 구성 {#additional-configuration-for-saml-apps-on-your-idp}

IdP에서 SAML 앱을 구성할 때 IdP에는 다음과 같은 추가 구성이 필요할 수 있습니다:

| 필드 | 값 | 참고 |
|-------|-------|-------|
| SAML 프로필 | 웹 브라우저 SSO 프로필 | GitLab은 SAML을 사용하여 사용자가 브라우저를 통해 사인인하도록 합니다. IdP로 직접 요청이 없습니다. |
| SAML 요청 바인딩 | HTTP 리디렉션 | GitLab(SP)이 base64 인코딩된 `SAMLRequest` HTTP 매개변수로 IdP에 사용자를 리디렉션합니다. |
| SAML 응답 바인딩 | HTTP POST | SAML 토큰이 IdP에서 전송되는 방식을 지정합니다. `SAMLResponse`을(를) 포함하며, 사용자의 브라우저에서 GitLab으로 다시 제출합니다. |
| SAML 응답 서명 | 필수 | 변조를 방지합니다. |
| 응답의 X.509 인증서 | 필수 | 응답에 서명하고 제공된 지문을 기준으로 응답을 확인합니다. |
| 지문 알고리즘 | SHA-1 | GitLab은 인증서의 SHA-1 해시를 사용하여 SAML 응답에 서명합니다. |
| 서명 알고리즘 | SHA-1/SHA-256/SHA-384/SHA-512 | 응답에 서명하는 방식을 결정합니다. 다이제스트 방법으로도 알려져 있으며, SAML 응답에서 지정할 수 있습니다. |
| SAML 어설션 암호화 | 선택적 | ID 공급자, 사용자의 브라우저, GitLab 간에 TLS를 사용합니다. |
| SAML 어설션 서명 | 선택적 | SAML 어설션의 무결성을 확인합니다. 활성화되면 전체 응답에 서명합니다. |
| SAML 요청 서명 확인 | 선택적 | SAML 응답의 서명을 확인합니다. |
| 기본 RelayState | 선택적 | 사용자가 IdP를 통해 SAML에 성공적으로 로그인한 후 도착할 기본 URL의 하위 경로를 지정합니다. |
| NameID 형식 | 영구 | [NameID 형식 세부 정보](../user/group/saml_sso/_index.md#manage-user-saml-identity)를 참조하세요. |
| 추가 URL | 선택적 | 일부 공급자의 다른 필드에 발급자, 식별자 또는 어설션 소비자 서비스 URL이 포함될 수 있습니다. |

예제 구성을 보려면 [특정 공급자에 대한 참고 사항](#set-up-identity-providers)을(를) 참조하세요.

## Geo를 사용하여 SAML 구성 {#configure-saml-with-geo}

Geo를 사용하여 SAML을 구성하려면 [인스턴스 전체 SAML 구성](../administration/geo/replication/single_sign_on.md#configuring-instance-wide-saml)을(를) 참조하세요.

자세한 내용은 [Geo 및 Single Sign On (SSO)](../administration/geo/replication/single_sign_on.md)을(를) 참조하세요.

## 문제 해결 {#troubleshooting}

[SAML 문제 해결 가이드](../user/group/saml_sso/troubleshooting.md)를 참조하세요.
