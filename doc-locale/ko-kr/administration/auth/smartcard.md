---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 스마트 카드 인증
description: 인증서 기반 로그인을 위해 하드웨어 장치를 사용하여 인증합니다.
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 스마트 카드를 사용한 인증을 지원합니다.

## 기존 암호 인증 {#existing-password-authentication}

기본적으로 스마트 카드 인증이 활성화되면 기존 사용자는 사용자 이름과 암호로 계속 로그인할 수 있습니다.

기존 사용자가 스마트 카드 인증만 사용하도록 강제하려면 [사용자 이름 및 암호 인증 비활성화](../settings/sign_in_restrictions.md#password-and-passkey-authentication)를 수행합니다.

## 인증 방법 {#authentication-methods}

GitLab은 다음 두 가지 인증 방법을 지원합니다:

- 로컬 데이터베이스를 사용하는 X.509 인증서
- LDAP 서버

### 로컬 데이터베이스를 사용한 X.509 인증서에 대한 인증 {#authentication-against-a-local-database-with-x509-certificates}

{{< details >}}

- 상태:  실험

{{< /details >}}

X.509 인증서를 사용하는 스마트 카드를 GitLab에 대한 인증에 사용할 수 있습니다.

X.509 인증서를 사용하는 스마트 카드로 GitLab의 로컬 데이터베이스에 대해 인증하려면 `CN`과 `emailAddress`를 인증서에 정의해야 합니다. 예를 들어:

```plaintext
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 12856475246677808609 (0xb26b601ecdd555e1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=Random Corp Ltd, CN=Random Corp
        Validity
            Not Before: Oct 30 12:00:00 2018 GMT
            Not After : Oct 30 12:00:00 2019 GMT
        Subject: CN=Gitlab User, emailAddress=gitlab-user@example.com
```

### 로컬 데이터베이스를 사용한 X.509 인증서 및 SAN 확장에 대한 인증 {#authentication-against-a-local-database-with-x509-certificates-and-san-extension}

{{< details >}}

- 상태:  실험

{{< /details >}}

SAN 확장을 사용하는 X.509 인증서를 사용하는 스마트 카드를 GitLab에 대한 인증에 사용할 수 있습니다.

X.509 인증서를 사용하는 스마트 카드로 GitLab의 로컬 데이터베이스에 대해 인증하려면 다음을 수행합니다:

- `subjectAltName` (SAN) 확장 중 최소 하나는 GitLab 인스턴스 내에서 사용자 ID(`email`)를 정의해야 합니다(`URI`).
- `URI`은 `Gitlab.config.host.gitlab`과 일치해야 합니다.
- 인증서에 **one**의 SAN 이메일 항목만 포함되어 있으면 `email`를 `URI`과 일치하도록 추가하거나 수정할 필요가 없습니다.

예를 들어:

```plaintext
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 12856475246677808609 (0xb26b601ecdd555e1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=Random Corp Ltd, CN=Random Corp
        Validity
            Not Before: Oct 30 12:00:00 2018 GMT
            Not After : Oct 30 12:00:00 2019 GMT
        ...
        X509v3 extensions:
            X509v3 Key Usage:
                Key Encipherment, Data Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Alternative Name:
                email:gitlab-user@example.com, URI:http://gitlab.example.com/
```

### LDAP 서버에 대한 인증 {#authentication-against-an-ldap-server}

{{< details >}}

- 상태:  실험

{{< /details >}}

GitLab은 [RFC4523](https://www.rfc-editor.org/rfc/rfc4523)에 따라 표준 인증서 일치 방법을 구현합니다. `certificateExactMatch` 인증서 일치 규칙을 `userCertificate` 속성에 대해 사용합니다. 사전 조건으로 다음을 충족하는 LDAP 서버를 사용해야 합니다:

- `certificateExactMatch` 일치 규칙을 지원합니다.
- `userCertificate` 속성에 인증서가 저장되어 있습니다.

### Active Directory LDAP 서버에 대한 인증 {#authentication-against-an-active-directory-ldap-server}

{{< history >}}

- GitLab 16.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/328074)되었습니다.
- GitLab 17.11에서 `reverse_issuer_and_subject`와 `reverse_issuer_and_serial_number` 형식이 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/514025)되었습니다.
- `issuer_and_subject`, `reverse_issuer_and_subject`, 및 `subject` 형식이 GitLab 18.6에서 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208209) 되었습니다 [기능 플래그](../feature_flags/_index.md) `smartcard_ad_formats_v2`을 사용합니다. 기본적으로 활성화됨. 이 플래그를 비활성화하여 이러한 형식을 이전 버전으로 되돌립니다.
- GitLab 18.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/577375)합니다. 기능 플래그 `smartcard_ad_formats_v2` 제거됨.

{{< /history >}}

> [!flag]
> 이 기능의 기능은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

Active Directory는 `certificateExactMatch` 규칙 또는 `userCertificate` 속성을 지원하지 않습니다. 스마트 카드와 같은 인증서 기반 인증을 위한 대부분의 도구는 `altSecurityIdentities` 속성을 사용하며, 각 사용자에 대해 여러 인증서를 포함할 수 있습니다. 필드의 데이터는 [Microsoft에서 권장하는 형식 중 하나](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-certificate-based-authentication-certificateuserids#supported-patterns-for-certificate-user-ids)와 일치해야 합니다.

다음 속성을 사용하여 GitLab이 확인하는 필드와 인증서 데이터의 형식을 사용자 지정합니다:

- `smartcard_ad_cert_field` - 검색할 필드의 이름을 지정합니다. 사용자 객체의 모든 속성이 될 수 있습니다.
- `smartcard_ad_cert_format` - 인증서에서 수집한 정보의 형식을 지정합니다. 이 형식은 다음 값 중 하나여야 합니다. 가장 일반적인 것은 비 Active Directory LDAP 서버의 동작과 일치하는 `issuer_and_serial_number`입니다.

| `smartcard_ad_cert_format` | 예제 데이터                                                 |
| -------------------------- | ------------------------------------------------------------ |
| `principal_name`           | `X509:<PN>alice@example.com`                                 |
| `rfc822_name`              | `X509:<RFC822>bob@example.com`                               |
| `subject`                  | `X509:<S>CN=dennis,OU=UserAccounts,DC=example,DC=com`        |
| `issuer_and_serial_number` | `X509:<I>CN=CONTOSO-DC-CA,DC=example,DC=com<SR>1181914561`   |
| `issuer_and_subject`       | `X509:<I>CN=EXAMPLE-DC-CA,DC=example,DC=com<S>CN=cynthia,OU=UserAccounts,DC=example,DC=com` |
| `reverse_issuer_and_serial_number` | `X509:<I>DC=com,DC=example,CN=CONTOSO-DC-CA<SR>1181914561`   |
| `reverse_issuer_and_subject`   | `X509:<I>DC=com,DC=example,CN=CONTOSO-DC-CA<S>CN=cynthia,OU=UserAccounts,DC=example,DC=com` |
| `reverse_issuer_and_reverse_subject`   | `X509:<I>DC=com,DC=example,CN=CONTOSO-DC-CA<S>DC=com,DC=example,OU=UserAccounts,CN=cynthia` |

`issuer_and_serial_number`의 경우 `<SR>` 부분은 역바이트 순서이며 최하위 바이트가 먼저입니다. 자세한 정보는 [altSecurityIdentities 속성을 사용하여 사용자를 인증서에 매핑하는 방법](https://learn.microsoft.com/en-us/archive/blogs/spatdsg/howto-map-a-user-to-a-certificate-via-all-the-methods-available-in-the-altsecurityidentities-attribute)을 참조하세요.

역 발급자 형식은 발급자 문자열을 가장 작은 단위에서 가장 큰 단위로 정렬합니다. 일부 Active Directory 서버는 이 형식으로 인증서를 저장합니다.

> [!note]
> `smartcard_ad_cert_format`가 지정되지 않았지만 LDAP 서버가 `active_directory: true`로 구성되었고 스마트 카드가 활성화된 경우 GitLab은 16.8 이하의 동작으로 기본 설정되고 `certificateExactMatch`을 `userCertificate` 속성에 사용합니다.

### Entra ID Domain Services에 대한 인증 {#authentication-against-entra-id-domain-services}

{{< history >}}

- GitLab 16.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/328074)되었습니다.

{{< /history >}}

[Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/whatis)(이전에는 Azure Active Directory로 알려짐)는 기업 및 조직을 위한 클라우드 기반 디렉토리를 제공합니다. [Entra Domain Services](https://learn.microsoft.com/en-us/entra/identity/domain-services/overview)는 디렉토리에 대한 안전한 읽기 전용 LDAP 인터페이스를 제공하지만 Entra ID가 가진 필드의 제한된 부분만 노출합니다.

Entra ID는 `CertificateUserIds` 필드를 사용하여 사용자의 클라이언트 인증서를 관리하지만 이 필드는 LDAP / Entra ID Domain Services에 노출되지 않습니다. 클라우드 전용 설정을 사용하면 GitLab이 LDAP를 사용하여 사용자의 스마트 카드를 인증할 수 없습니다.

하이브리드 온프레미스 및 클라우드 환경에서 엔터티는 [Entra Connect](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/whatis-azure-ad-connect-v2)를 사용하여 온프레미스 Active Directory 컨트롤러와 클라우드 Entra ID 간에 동기화됩니다. [Entra ID Connect를 사용하여 `altSecurityIdentities` 속성을 Entra ID의 `certificateUserIds`로 동기화](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-certificate-based-authentication-certificateuserids#update-certificateuserids-using-microsoft-entra-connect)하는 경우 이 데이터를 LDAP / Entra ID Domain Services에 노출할 수 있으므로 GitLab에서 인증할 수 있습니다:

1. Entra ID Connect에 규칙을 추가하여 `altSecurityIdentities`를 Entra ID의 추가 속성으로 동기화합니다.
1. 해당 추가 속성을 [Entra ID Domain Services의 확장 속성](https://learn.microsoft.com/en-us/entra/identity/domain-services/concepts-custom-attributes)으로 활성화합니다.
1. GitLab에서 `smartcard_ad_cert_field` 필드를 구성하여 이 확장 속성을 사용합니다.

## 스마트 카드 인증을 위해 GitLab 구성 {#configure-gitlab-for-smart-card-authentication}

Linux 패키지 설치의 경우:

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   # Allow smart card authentication
   gitlab_rails['smartcard_enabled'] = true

   # Path to a file containing a CA certificate
   gitlab_rails['smartcard_ca_file'] = "/etc/ssl/certs/CA.pem"

   # Host and port where the client side certificate is requested by the
   # webserver (NGINX/Apache)
   gitlab_rails['smartcard_client_certificate_required_host'] = "smartcard.example.com"
   gitlab_rails['smartcard_client_certificate_required_port'] = 3444
   ```

   > [!note]
   > 다음 변수 중 최소 하나에 값을 할당합니다. `gitlab_rails['smartcard_client_certificate_required_host']` 또는 `gitlab_rails['smartcard_client_certificate_required_port']`.

1. 파일을 저장하고 변경 사항이 적용되도록 GitLab을 [재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

자체 컴파일된 설치의 경우:

1. 클라이언트 측 인증서를 요청하도록 NGINX 구성

   NGINX 구성에서 **additional** 서버 컨텍스트를 정의해야 하며 다음을 제외한 동일한 구성을 사용합니다:

   - 추가 NGINX 서버 컨텍스트는 다른 포트에서 실행되도록 구성해야 합니다:

     ```plaintext
     listen *:3444 ssl;
     ```

   - 다른 호스트 이름에서 실행되도록 구성할 수도 있습니다:

     ```plaintext
     listen smartcard.example.com:443 ssl;
     ```

   - 추가 NGINX 서버 컨텍스트는 클라이언트 측 인증서를 요청하도록 구성해야 합니다:

     ```plaintext
     ssl_verify_depth 2;
     ssl_client_certificate /etc/ssl/certs/CA.pem;
     ssl_verify_client on;
     ```

   - 추가 NGINX 서버 컨텍스트는 클라이언트 측 인증서를 전달하도록 구성해야 합니다:

     ```plaintext
     proxy_set_header    X-SSL-Client-Certificate    $ssl_client_escaped_cert;
     ```

   예를 들어 다음은 NGINX 구성 파일(예: `/etc/nginx/sites-available/gitlab-ssl`)의 예제 서버 컨텍스트입니다:

   ```plaintext
   server {
       listen smartcard.example.com:3443 ssl;

       # certificate for configuring SSL
       ssl_certificate /path/to/example.com.crt;
       ssl_certificate_key /path/to/example.com.key;

       ssl_verify_depth 2;
       # CA certificate for client side certificate verification
       ssl_client_certificate /etc/ssl/certs/CA.pem;
       ssl_verify_client on;

       location / {
           proxy_set_header    Host                        $http_host;
           proxy_set_header    X-Real-IP                   $remote_addr;
           proxy_set_header    X-Forwarded-For             $proxy_add_x_forwarded_for;
           proxy_set_header    X-Forwarded-Proto           $scheme;
           proxy_set_header    Upgrade                     $http_upgrade;
           proxy_set_header    Connection                  $connection_upgrade;

           proxy_set_header    X-SSL-Client-Certificate    $ssl_client_escaped_cert;

           proxy_read_timeout 300;

           proxy_pass http://gitlab-workhorse;
       }
   }
   ```

1. `config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   ## Smart card authentication settings
   smartcard:
     # Allow smart card authentication
     enabled: true

     # Path to a file containing a CA certificate
     ca_file: '/etc/ssl/certs/CA.pem'

     # Host and port where the client side certificate is requested by the
     # webserver (NGINX/Apache)
     client_certificate_required_host: smartcard.example.com
     client_certificate_required_port: 3443
   ```

   > [!note]
   > 다음 변수 중 최소 하나에 값을 할당합니다. `client_certificate_required_host` 또는 `client_certificate_required_port`.

1. 파일을 저장하고 변경 사항이 적용되도록 GitLab을 [다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

### 추가 보안 권장사항 {#additional-security-recommendations}

추가 보안을 위해 CloudFlare WAF 또는 [ModSecurity](https://modsecurity.org/)를 실행하는 서버와 같은 방화벽 뒤에 GitLab을 배포합니다. 다음 패턴과 일치하는 URL은 GitLab의 일부로 배포된 NGINX에 액세스할 수 있어야 하지만 외부 클라이언트에는 액세스할 수 없어야 합니다:

```plaintext
/-/smartcard/extract_certificate
/-/smartcard/verify_certificate
```

이러한 경로는 NGINX에 할당된 스마트 카드 호스트 이름 및 포트를 사용하여만 외부적으로 액세스할 수 있으며 기본 GitLab 호스트 이름 및 포트를 사용하여 외부적으로 액세스할 수 없어야 합니다. 이는 [HTTP Host Header 공격](https://portswigger.net/web-security/host-header)에 대해 견고해야 하므로 사용자가 NGINX를 거치지 않고 자신의 인증서 매개변수를 제출할 수 없습니다.

### SAN 확장을 사용할 때 추가 단계 {#additional-steps-when-using-san-extensions}

Linux 패키지 설치의 경우:

1. `/etc/gitlab/gitlab.rb`에 추가합니다:

   ```ruby
   gitlab_rails['smartcard_san_extensions'] = true
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 GitLab을 [재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

자체 컴파일된 설치의 경우:

1. `san_extensions` 행을 `config/gitlab.yml` 스마트 카드 섹션 내에 추가합니다:

   ```yaml
   smartcard:
      enabled: true
      ca_file: '/etc/ssl/certs/CA.pem'
      client_certificate_required_port: 3444

      # Enable the use of SAN extensions to match users with certificates
      san_extensions: true
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 GitLab을 [다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

### LDAP 서버에 대해 인증할 때 추가 단계 {#additional-steps-when-authenticating-against-an-ldap-server}

Linux 패키지 설치의 경우:

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_servers'] = YAML.load <<-EOS
   main:
     # snip...
     # Enable smart card authentication against the LDAP server. Valid values
     # are "false", "optional", and "required".
     smartcard_auth: optional

     # If your LDAP server is Active Directory, you can configure these two fields.
     # Specify which field contains certificate information, 'altSecurityIdentities' by default
     smartcard_ad_cert_field: altSecurityIdentities

     # Specify format of certificate information. Valid values are:
     # principal_name, rfc822_name, issuer_and_subject, subject, issuer_and_serial_number
     smartcard_ad_cert_format: issuer_and_serial_number
   EOS
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 GitLab을 [재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

자체 컴파일된 설치의 경우:

1. `config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           # Enable smart card authentication against the LDAP server. Valid values
           # are "false", "optional", and "required".
           smartcard_auth: optional

           # If your LDAP server is Active Directory, you can configure these two fields.
           # Specify which field contains certificate information, 'altSecurityIdentities' by default
           smartcard_ad_cert_field: altSecurityIdentities

           # Specify format of certificate information. Valid values are:
           # principal_name, rfc822_name, issuer_and_subject, subject, issuer_and_serial_number
           smartcard_ad_cert_format: issuer_and_serial_number
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 GitLab을 [다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

### Git 액세스를 위해 스마트 카드 로그인을 사용하는 브라우저 세션 필요 {#require-browser-session-with-smart-card-sign-in-for-git-access}

Linux 패키지 설치의 경우:

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['smartcard_required_for_git_access'] = true
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 GitLab을 [재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

자체 컴파일된 설치의 경우:

1. `config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   ## Smart card authentication settings
   smartcard:
     # snip...
     # Browser session with smart card sign-in is required for Git access
     required_for_git_access: true
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 GitLab을 [다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

## 스마트 카드 인증을 통해 생성된 사용자의 암호 {#passwords-for-users-created-via-smart-card-authentication}

[통합 인증을 통해 생성된 사용자를 위한 생성된 암호](../../user/profile/user_passwords.md) 가이드는 GitLab이 스마트 카드 인증을 통해 생성된 사용자의 암호를 생성하고 설정하는 방법을 개요로 제공합니다.
