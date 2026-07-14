---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: GitLab과 LDAP 통합
description: 중앙화된 인증을 위해 디렉터리 서비스를 통합합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 [LDAP - Lightweight Directory Access Protocol](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)과 통합되어 사용자 인증을 지원합니다.

이 통합은 다음을 포함한 대부분의 LDAP 호환 디렉터리 서버와 작동합니다:

- Microsoft Active Directory.
- Apple Open Directory.
- OpenLDAP.
- 389 Server.

> [!note]
> GitLab은 [Microsoft Active Directory Trusts](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc771568(v=ws.10))를 지원하지 않습니다.

LDAP를 통해 추가된 사용자:

- 보통 [라이선스 사용자](../../../subscriptions/manage_seats.md#billable-users)를 사용합니다.
- Git 암호 인증이 [비활성화](../../settings/sign_in_restrictions.md#allow-password-authentication-for-git-over-https)된 경우에도 GitLab 사용자 이름 또는 이메일 및 LDAP 암호를 사용하여 Git으로 인증할 수 있습니다.

LDAP 고유 이름(DN)은 다음과 같은 경우에 기존 GitLab 사용자와 연결됩니다:

- 기존 사용자가 처음으로 LDAP를 사용하여 GitLab에 로그인합니다.
- LDAP 이메일 주소가 기존 GitLab 사용자의 기본 이메일 주소입니다. LDAP 이메일 속성을 GitLab 사용자 데이터베이스에서 찾을 수 없으면 새 사용자가 생성됩니다.

기존 GitLab 사용자가 자신을 위해 LDAP 로그인을 활성화하려면 다음을 수행해야 합니다:

1. GitLab 이메일 주소가 LDAP 이메일 주소와 일치하는지 확인하세요.
1. LDAP 자격 증명을 사용하여 GitLab에 로그인합니다.

> [!note]
> 사용자가 LDAP 자격 증명을 자신의 GitLab 계정에 연결한 후에는 표준 사용자 이름과 암호 인증 플로우를 더 이상 사용할 수 없습니다. 대신 사용자는 LDAP 자격 증명으로 인증해야 합니다. 사용자 이름과 암호 인증으로 로그인을 시도하면 [잘못된 로그인 또는 암호 오류](ldap-troubleshooting.md#users-see-an-error-invalid-login-or-password)가 반환됩니다.

## 보안 {#security}

GitLab은 사용자가 LDAP에서 여전히 활성 상태인지 확인합니다.

다음과 같은 경우 사용자는 LDAP에서 비활성으로 간주됩니다:

- 디렉터리에서 완전히 제거됩니다.
- 구성된 `base` DN 또는 `user_filter` 검색 외부에 있습니다.
- 사용자 계정 제어 속성을 통해 Active Directory에서 비활성화 또는 비활성화로 표시됩니다. 이는 `userAccountControl:1.2.840.113556.1.4.803` 속성에 비트 2가 설정되어 있음을 의미합니다.

LDAP에서 사용자가 활성 또는 비활성 상태인지 확인하려면 다음 PowerShell 명령과 [Active Directory Module](https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2022-ps)을 사용하여 Active Directory를 확인합니다:

```powershell
Get-ADUser -Identity <username> -Properties userAccountControl | Select-Object Name, userAccountControl
```

GitLab은 LDAP 사용자의 상태를 확인합니다:

- 모든 인증 공급자를 사용하여 로그인할 때.
- 토큰 또는 SSH 키를 사용하는 활성 웹 세션 또는 Git 요청에 대해 시간당 한 번.
- LDAP 사용자 이름과 암호를 사용하여 Git over HTTP 요청을 수행할 때.
- [사용자 동기화](ldap_synchronization.md#user-sync) 중에 하루에 한 번.

사용자가 더 이상 LDAP에서 활성 상태가 아니면 다음과 같습니다:

- 로그아웃됩니다.
- `ldap_blocked` 상태로 배치됩니다.
- LDAP에서 재활성화될 때까지 모든 인증 공급자를 사용하여 로그인할 수 없습니다.

### 보안 위험 {#security-risks}

LDAP 통합은 LDAP 사용자가 다음을 수행할 수 없는 경우에만 사용해야 합니다:

- LDAP 서버에서 `mail`, `email` 또는 `userPrincipalName` 속성을 변경합니다. 이 사용자들은 GitLab 서버의 모든 계정을 잠재적으로 탈취할 수 있습니다.
- 이메일 주소를 공유합니다. 동일한 이메일 주소를 가진 LDAP 사용자는 동일한 GitLab 계정을 공유할 수 있습니다.

## LDAP 구성 {#configure-ldap}

전제 조건:

- LDAP를 사용하려면 로그인할 때 해당 이메일 주소를 사용하는지 여부에 관계없이 이메일 주소가 있어야 합니다.

LDAP를 구성하려면 구성 파일의 설정을 편집합니다:

- 구성 파일은 다음 [기본 구성 설정](#basic-configuration-settings)을 포함해야 합니다:
  - `label`
  - `host`
  - `port`
  - `uid`
  - `base`
  - `encryption`
- 구성 파일에 다음 선택적 설정을 포함할 수 있습니다:
  - [선택적 기본 구성 설정](#basic-configuration-settings).
  - [SSL 설정](#ssl-configuration-settings).
  - [속성 설정](#attribute-configuration-settings).
  - [LDAP 동기화 설정](#ldap-sync-configuration-settings).
- LDAP를 다음과 같이 구성할 수도 있습니다:
  - [여러 서버 사용](#use-multiple-ldap-servers).
  - [사용자 필터링](#set-up-ldap-user-filter).
  - [LDAP 사용자 이름을 자동으로 소문자로 설정](#enable-ldap-username-lowercase).
  - [LDAP 웹 로그인 비활성화](#disable-ldap-web-sign-in).
  - [GitLab을 위한 스마트 카드 인증 제공](#provide-smart-card-authentication-for-gitlab)
  - [암호화된 자격 증명 사용](#use-encrypted-credentials).

편집하는 파일은 GitLab 설정에 따라 다릅니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'LDAP',
       'host' => 'ldap.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'bind_dn' => 'CN=Gitlab,OU=Users,DC=domain,DC=com',
       'password' => '<bind_user_password>',
       'encryption' => 'simple_tls',
       'verify_certificates' => true,
       'timeout' => 10,
       'active_directory' => false,
       'user_filter' => '(employeeType=developer)',
       'base' => 'dc=example,dc=com',
       'lowercase_usernames' => 'false',
       'retry_empty_result_with_codes' => [80],
       'allow_username_or_email_login' => false,
       'block_auto_created_users' => false
     }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'LDAP'
             host: 'ldap.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             bind_dn: 'CN=Gitlab,OU=Users,DC=domain,DC=com'
             password: '<bind_user_password>'
             encryption: 'simple_tls'
             verify_certificates: true
             timeout: 10
             active_directory: false
             user_filter: '(employeeType=developer)'
             base: 'dc=example,dc=com'
             lowercase_usernames: false
             retry_empty_result_with_codes: [80]
             allow_username_or_email_login: false
             block_auto_created_users: false
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

자세한 내용은 [Helm 차트를 사용하여 설치한 GitLab 인스턴스에 대해 LDAP를 구성하는 방법](https://docs.gitlab.com/charts/charts/globals/#ldap)을 참조하세요.

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'LDAP',
               'host' => 'ldap.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'bind_dn' => 'CN=Gitlab,OU=Users,DC=domain,DC=com',
               'password' => '<bind_user_password>',
               'encryption' => 'simple_tls',
               'verify_certificates' => true,
               'timeout' => 10,
               'active_directory' => false,
               'user_filter' => '(employeeType=developer)',
               'base' => 'dc=example,dc=com',
               'lowercase_usernames' => 'false',
               'retry_empty_result_with_codes' => [80],
               'allow_username_or_email_login' => false,
               'block_auto_created_users' => false
             }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ldap:
       enabled: true
       servers:
         main:
           label: 'LDAP'
           host: 'ldap.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           bind_dn: 'CN=Gitlab,OU=Users,DC=domain,DC=com'
           password: '<bind_user_password>'
           encryption: 'simple_tls'
           verify_certificates: true
           timeout: 10
           active_directory: false
           user_filter: '(employeeType=developer)'
           base: 'dc=example,dc=com'
           lowercase_usernames: false
           retry_empty_result_with_codes: [80]
           allow_username_or_email_login: false
           block_auto_created_users: false
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

다양한 LDAP 옵션에 대한 자세한 내용은 [`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)에서 `ldap` 설정을 참조하세요.

{{< /tab >}}

{{< /tabs >}}

LDAP를 구성한 후 구성을 테스트하려면 [LDAP check Rake task](../../raketasks/ldap.md#check)를 사용합니다.

### 기본 구성 설정 {#basic-configuration-settings}

다음 기본 설정을 사용할 수 있습니다:

| 설정                         | 필수                             | 타입                          | 설명 |
|---------------------------------|--------------------------------------|-------------------------------|-------------|
| `label`                         | {{< icon name="check-circle" >}} Yes | String                        | LDAP 서버의 친화적인 이름입니다. 로그인 페이지에 표시됩니다. 예: `'Paris'` 또는 `'Acme, Ltd.'` |
| `host`                          | {{< icon name="check-circle" >}} Yes | String                        | LDAP 서버의 IP 주소 또는 도메인 이름입니다. `hosts`이 정의되면 무시됩니다. 예: `'ldap.mydomain.com'` |
| `port`                          | {{< icon name="check-circle" >}} Yes | Integer                       | LDAP 서버에 연결할 포트입니다. `hosts`이 정의되면 무시됩니다. 예: `389` 또는 `636` (SSL의 경우) |
| `uid`                           | {{< icon name="check-circle" >}} Yes | String                        | 사용자가 로그인할 때 사용하는 사용자 이름에 매핑되는 LDAP 속성입니다. `uid`에 매핑되는 속성이 아닌 속성이어야 합니다. GitLab 사용자 이름에 영향을 주지 않습니다 ([속성 섹션](#attribute-configuration-settings) 참조). 예: `'sAMAccountName'` 또는 `'uid'` 또는 `'userPrincipalName'` |
| `base`                          | {{< icon name="check-circle" >}} Yes | String                        | 사용자를 검색할 수 있는 기본 위치입니다. 예: `'ou=people,dc=gitlab,dc=example'` 또는 `'DC=mydomain,DC=com'` |
| `encryption`                    | {{< icon name="check-circle" >}} Yes | String                        | `method` 키는 `encryption`를 위해 더 이상 사용되지 않습니다. 세 가지 값 중 하나를 가질 수 있습니다. `'start_tls'`, `'simple_tls'` 또는 `'plain'`. `simple_tls`은 LDAP 라이브러리에서 'Simple TLS'에 해당합니다. `start_tls`은 StartTLS에 해당하며 일반 TLS와 혼동하지 않습니다. `simple_tls`을 지정하면 보통 포트 636에 있고, `start_tls` (StartTLS)는 포트 389입니다. `plain`은 포트 389에서도 작동합니다. |
| `hosts`                         | {{< icon name="dotted-circle" >}} No | 문자열 및 정수 배열 | 연결을 열기 위한 호스트 및 포트 쌍의 배열입니다. 구성된 각 서버는 동일한 데이터 세트를 가져야 합니다. 이는 여러 개의 서로 다른 LDAP 서버를 구성하기 위한 것이 아니라 장애 조치를 구성하기 위한 것입니다. 호스트는 구성된 순서대로 시도됩니다. 예: `[['ldap1.mydomain.com', 636], ['ldap2.mydomain.com', 636]]` |
| `bind_dn`                       | {{< icon name="dotted-circle" >}} No | String                        | 바인드할 사용자의 전체 DN입니다. 예: `'america\momo'` 또는 `'CN=Gitlab,OU=Users,DC=domain,DC=com'` |
| `password`                      | {{< icon name="dotted-circle" >}} No | String                        | 바인드 사용자의 암호입니다. |
| `verify_certificates`           | {{< icon name="dotted-circle" >}} No | Boolean                       | `true`로 기본값 설정됩니다. 암호화 방법이 `start_tls` 또는 `simple_tls`인 경우 SSL 인증서 검증을 활성화합니다. `false`로 설정하면 LDAP 서버의 SSL 인증서 검증이 수행되지 않습니다. |
| `timeout`                       | {{< icon name="dotted-circle" >}} No | Integer                       | `10`로 기본값 설정됩니다. LDAP 쿼리의 시간 초과(초)를 설정합니다. LDAP 서버가 응답하지 않으면 요청 차단을 방지합니다. `0`의 값은 시간 초과가 없음을 의미합니다. |
| `active_directory`              | {{< icon name="dotted-circle" >}} No | Boolean                       | 이 설정은 LDAP 서버가 Active Directory LDAP 서버인지 여부를 지정합니다. AD가 아닌 서버의 경우 AD 특정 쿼리를 건너뜁니다. LDAP 서버가 AD가 아니면 이를 false로 설정합니다. |
| `allow_username_or_email_login` | {{< icon name="dotted-circle" >}} No | Boolean                       | `false`로 기본값 설정됩니다. 활성화되면 GitLab은 로그인 시 사용자가 제출한 LDAP 사용자 이름에서 첫 번째 `@` 이후의 모든 내용을 무시합니다. ActiveDirectory에서 `uid: 'userPrincipalName'`을 사용 중이면 이 설정을 비활성화해야 합니다. `userPrincipalName`에는 `@`이 포함되어 있기 때문입니다. |
| `block_auto_created_users`      | {{< icon name="dotted-circle" >}} No | Boolean                       | `false`로 기본값 설정됩니다. GitLab 설치의 청구 가능한 사용자 수를 엄격하게 제어하려면 이 설정을 활성화하여 관리자가 승인할 때까지 새 사용자를 차단 상태로 유지합니다. |
| `user_filter`                   | {{< icon name="dotted-circle" >}} No | String                        | LDAP 사용자를 필터링합니다. [RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html)의 형식을 따릅니다. GitLab은 `omniauth-ldap`의 사용자 정의 필터 구문을 지원하지 않습니다. `user_filter` 필드 구문의 예:<br/><br/>- `'(employeeType=developer)'`<br/>- `'(&(objectclass=user)(\|(samaccountname=momo)(samaccountname=toto)))'` |
| `lowercase_usernames`           | {{< icon name="dotted-circle" >}} No | Boolean                       | 활성화되면 GitLab은 이름을 소문자로 변환합니다. |
| `retry_empty_result_with_codes` | {{< icon name="dotted-circle" >}} No | Array                         | 결과/콘텐츠가 비어 있으면 작업을 다시 시도하려고 시도하는 LDAP 쿼리 응답 코드의 배열입니다. Google Secure LDAP의 경우 이 값을 `[80]`로 설정합니다. |

> [!note]
> GitLab은 [Microsoft advisory ADV190023](https://msrc.microsoft.com/update-guide/en-us/advisory/ADV190023)과 함께 도입된 Microsoft Active Directory Services에 대한 더 엄격한 바인딩 요구 사항의 영향을 받지 않습니다. 자세한 내용은 [이슈 201894](https://gitlab.com/gitlab-org/gitlab/-/issues/201894#note_2807513217)를 참조하세요.

### SSL 구성 설정 {#ssl-configuration-settings}

`tls_options` 이름/값 쌍 아래에서 SSL 구성 설정을 구성할 수 있습니다. 다음 설정은 모두 선택 사항입니다:

| 설정       | 설명 | 예 |
|---------------|-------------|----------|
| `ca_file`     | PEM 형식 CA 인증서가 포함된 파일의 경로를 지정합니다 (예: 내부 CA가 필요한 경우). | `'/etc/ca.pem'` |
| `ssl_version` | OpenSSL 기본값이 적절하지 않은 경우 OpenSSL이 사용할 SSL 버전을 지정합니다. | `'TLSv1_1'` |
| `ciphers`     | LDAP 서버와의 통신에 사용할 특정 SSL 암호입니다. | `'ALL:!EXPORT:!LOW:!aNULL:!eNULL:!SSLv2'` |
| `cert`        | 클라이언트 인증서입니다. | `'-----BEGIN CERTIFICATE----- <REDACTED> -----END CERTIFICATE -----'` |
| `key`         | 클라이언트 개인 키입니다. | `'-----BEGIN PRIVATE KEY----- <REDACTED> -----END PRIVATE KEY -----'` |

다음 예는 `ca_file` 및 `ssl_version`를 `tls_options`에서 설정하는 방법을 보여줍니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'LDAP',
       'host' => 'ldap.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
       'tls_options' => {
         'ca_file' => '/path/to/ca_file.pem',
         'ssl_version' => 'TLSv1_2'
       }
     }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'LDAP'
             host: 'ldap.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
             tls_options:
               ca_file: '/path/to/ca_file.pem'
               ssl_version: 'TLSv1_2'
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

자세한 내용은 [Helm 차트를 사용하여 설치한 GitLab 인스턴스에 대해 LDAP를 구성하는 방법](https://docs.gitlab.com/charts/charts/globals/#ldap)을 참조하세요.

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'LDAP',
               'host' => 'ldap.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
               'tls_options' => {
                 'ca_file' => '/path/to/ca_file.pem',
                 'ssl_version' => 'TLSv1_2'
               }
             }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ldap:
       enabled: true
       servers:
         main:
           label: 'LDAP'
           host: 'ldap.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           encryption: 'simple_tls'
           base: 'dc=example,dc=com'
           tls_options:
             ca_file: '/path/to/ca_file.pem'
             ssl_version: 'TLSv1_2'
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### 속성 구성 설정 {#attribute-configuration-settings}

GitLab은 이러한 LDAP 속성을 사용하여 LDAP 사용자에 대한 계정을 생성합니다. 지정된 속성은 다음 중 하나일 수 있습니다:

- 문자열로 속성 이름입니다. 예를 들어, `'mail'`.
- 순서대로 시도할 속성 이름의 배열입니다. 예를 들어, `['mail', 'email']`.

사용자의 LDAP 로그인은 [`uid`로 지정된](#basic-configuration-settings) LDAP 속성입니다.

다음 LDAP 속성은 모두 선택 사항입니다. 이러한 속성을 정의하면 다음 LDAP 속성은 모두 선택 사항입니다. 기본값과 다른 속성만 지정하면 됩니다. 예를 들어 `username`을 지정하면 다른 속성을 지정할 필요가 없으며 기본값이 적용됩니다.

이들 중 어느 것을 정의하면 `attributes` 해시에서 정의해야 합니다.

| 설정      | 설명 | 기본값 |
|--------------|-------------|----------|
| `username`   | GitLab 계정이 프로비저닝될 `@username`입니다. 값에 이메일 주소가 포함되면 GitLab 사용자 이름은 이메일 주소에서 `@` 이전의 부분입니다. | [`uid`로 지정된](#basic-configuration-settings) LDAP 속성으로 기본값 설정됩니다 (`['uid', 'userid', 'sAMAccountName']`). |
| `email`      | 사용자 이메일을 위한 LDAP 속성입니다. | `['mail', 'email', 'userPrincipalName']` |
| `name`       | 사용자 표시 이름을 위한 LDAP 속성입니다. `name`이 비어 있으면 전체 이름이 `first_name` 및 `last_name`에서 가져옵니다. `'cn'` 또는 `'displayName'` 속성은 일반적으로 전체 이름을 전달합니다. 또는 `first_name` 및 `last_name`의 사용을 `'somethingNonExistent'`과 같은 존재하지 않는 속성을 지정하여 강제할 수 있습니다. | `'cn'` |
| `first_name` | 사용자 이름을 위한 LDAP 속성입니다. `name`에 대해 구성된 속성이 존재하지 않을 때 사용됩니다. | `'givenName'` |
| `last_name`  | 사용자 성을 위한 LDAP 속성입니다. `name`에 대해 구성된 속성이 존재하지 않을 때 사용됩니다. | `'sn'` |

`displayName`을 사용자 이름으로 사용하고 `email`을 위한 속성 배열을 사용하는 구성 예:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       # Other configuration settings ...
       'attributes' => {
         'username' => 'uid',
         'email' => ['mail', 'email', 'userPrincipalName'],
         'name' => 'displayName',
         'first_name' => 'givenName',
         'last_name' => 'sn'
       }
     }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             # Other configuration settings ...
             attributes:
               username: 'uid'
               email:
                 - 'mail'
                 - 'email'
                 - 'userPrincipalName'
               name: 'displayName'
               first_name: 'givenName'
               last_name: 'sn'
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               # Other configuration settings ...
               'attributes' => {
                 'username' => 'uid',
                 'email' => ['mail', 'email', 'userPrincipalName'],
                 'name' => 'displayName',
                 'first_name' => 'givenName',
                 'last_name' => 'sn'
               }
             }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           # Other configuration settings ...
           attributes:
             username: 'uid'
             email:
               - 'mail'
               - 'email'
               - 'userPrincipalName'
             name: 'displayName'
             first_name: 'givenName'
             last_name: 'sn'
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### LDAP 동기화 구성 설정 {#ldap-sync-configuration-settings}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이러한 LDAP 동기화 구성 설정은 선택 사항이며, `external_groups`가 구성되어 있을 때 `group_base`을 제외합니다:

| 설정           | 설명 | 예 |
|-------------------|-------------|----------|
| `group_base`      | 그룹을 검색하는 데 사용되는 기본 위치입니다. 모든 유효한 그룹은 DN의 일부로 이 기본 위치를 가집니다. | `'ou=groups,dc=gitlab,dc=example'` |
| `admin_group`     | GitLab 관리자를 포함하는 그룹의 CN입니다. `cn=administrators` 또는 전체 DN이 아닙니다. | `'administrators'` |
| `external_groups` | 외부로 간주되어야 하는 사용자를 포함하는 그룹의 CN 배열입니다. `cn=interns` 또는 전체 DN이 아닙니다. | `['interns', 'contractors']` |
| `sync_ssh_keys`   | 사용자의 공개 SSH 키를 포함하는 LDAP 속성입니다. | `'sshPublicKey'` 또는 설정되지 않은 경우 false |

> [!note]
> Sidekiq이 Rails 서버와 다른 서버에 구성되어 있으면 LDAP 동기화가 작동하도록 모든 Sidekiq 서버에 LDAP 구성을 추가해야 합니다.

### 여러 LDAP 서버 사용 {#use-multiple-ldap-servers}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

여러 LDAP 서버에 사용자가 있는 경우 GitLab을 사용하도록 구성할 수 있습니다. 추가 LDAP 서버를 추가하려면:

1. [`main` LDAP 구성을 복제합니다](#configure-ldap).
1. 각 복제 구성을 추가 서버의 세부 정보로 편집합니다.
   - 각 추가 서버에 대해 `main`, `secondary` 또는 `tertiary`과 같은 다른 공급자 ID를 선택합니다. 소문자 영숫자를 사용합니다. GitLab은 공급자 ID를 사용하여 각 사용자를 특정 LDAP 서버와 연결합니다.
   - 각 항목에 대해 고유한 `label` 값을 사용합니다. 이 값들은 로그인 페이지의 탭 이름으로 사용됩니다.

다음 예는 최소 구성으로 세 개의 LDAP 서버를 구성하는 방법을 보여줍니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'GitLab AD',
       'host' => 'ad.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     },

     'secondary' => {
       'label' => 'GitLab Secondary AD',
       'host' => 'ad-secondary.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     },

     'tertiary' => {
       'label' => 'GitLab Tertiary AD',
       'host' => 'ad-tertiary.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'GitLab AD'
             host: 'ad.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
           secondary:
             label: 'GitLab Secondary AD'
             host: 'ad-secondary.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
           tertiary:
             label: 'GitLab Tertiary AD'
             host: 'ad-tertiary.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'GitLab AD',
               'host' => 'ad.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             },

             'secondary' => {
               'label' => 'GitLab Secondary AD',
               'host' => 'ad-secondary.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             },

             'tertiary' => {
               'label' => 'GitLab Tertiary AD',
               'host' => 'ad-tertiary.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ldap:
       enabled: true
       servers:
         main:
           label: 'GitLab AD'
           host: 'ad.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
         secondary:
           label: 'GitLab Secondary AD'
           host: 'ad-secondary.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
         tertiary:
           label: 'GitLab Tertiary AD'
           host: 'ad-tertiary.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

다양한 LDAP 옵션에 대한 자세한 내용은 [`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)에서 `ldap` 설정을 참조하세요.

{{< /tab >}}

{{< /tabs >}}

이 예는 다음 탭이 있는 로그인 페이지를 생성합니다:

- **GitLab AD**.
- **GitLab Secondary AD**.
- **GitLab Tertiary AD**.

### LDAP 사용자 필터 설정 {#set-up-ldap-user-filter}

GitLab 액세스를 LDAP 서버의 LDAP 사용자 부분 집합으로 제한하려면 먼저 구성된 `base`을 좁힙니다. 그러나 필요한 경우 사용자를 추가로 필터링하려면 LDAP 사용자 필터를 설정할 수 있습니다. 필터는 [RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html)를 준수해야 합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'user_filter' => '(employeeType=developer)'
     }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             user_filter: '(employeeType=developer)'
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'user_filter' => '(employeeType=developer)'
             }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           user_filter: '(employeeType=developer)'
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

Active Directory 그룹의 중첩된 멤버에 대한 액세스를 제한하려면 다음 구문을 사용합니다:

```plaintext
(memberOf:1.2.840.113556.1.4.1941:=CN=My Group,DC=Example,DC=com)
```

`LDAP_MATCHING_RULE_IN_CHAIN` 필터에 대한 자세한 내용은 [Search Filter Syntax](https://learn.microsoft.com/en-us/windows/win32/adsi/search-filter-syntax)를 참조하세요.

사용자 필터의 중첩된 멤버에 대한 지원을 [그룹 동기화 중첩 그룹](ldap_synchronization.md#supported-ldap-group-typesattributes) 지원과 혼동하면 안 됩니다.

GitLab은 OmniAuth LDAP에서 사용하는 사용자 정의 필터 구문을 지원하지 않습니다.

#### `user_filter`에서 특수 문자 이스케이프 {#escape-special-characters-in-user_filter}

`user_filter` DN에는 특수 문자가 포함될 수 있습니다. 예를 들어:

- 쉼표:

  ```plaintext
  OU=GitLab, Inc,DC=gitlab,DC=com
  ```

- 대괄호 열기 및 닫기:

  ```plaintext
  OU=GitLab (Inc),DC=gitlab,DC=com
  ```

이러한 문자는 [RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html#section-4)에 문서화된 대로 이스케이프되어야 합니다.

- `\2C`으로 쉼표를 이스케이프합니다. 예를 들어:

  ```plaintext
  OU=GitLab\2C Inc,DC=gitlab,DC=com
  ```

- `\28`으로 열린 대괄호를 이스케이프하고 `\29`로 닫힌 대괄호를 이스케이프합니다. 예를 들어:

  ```plaintext
  OU=GitLab \28Inc\29,DC=gitlab,DC=com
  ```

### LDAP 사용자 이름 소문자 활성화 {#enable-ldap-username-lowercase}

일부 LDAP 서버는 구성에 따라 대문자 사용자 이름을 반환할 수 있습니다. 이는 대문자 이름으로 링크 또는 네임스페이스를 생성하는 것과 같은 혼란스러운 여러 이슈를 야기할 수 있습니다.

GitLab은 구성 옵션 `lowercase_usernames`을 활성화하여 LDAP 서버에서 제공하는 사용자 이름을 자동으로 소문자로 변환할 수 있습니다. 기본적으로 이 구성 옵션은 `false`입니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'lowercase_usernames' => true
     }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             lowercase_usernames: true
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'lowercase_usernames' => true
             }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `config/gitlab.yaml`을(를) 편집합니다:

   ```yaml
   production:
     ldap:
       servers:
         main:
           lowercase_usernames: true
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### LDAP 웹 로그인 비활성화 {#disable-ldap-web-sign-in}

SAML과 같은 다른 옵션이 선호되는 경우 웹 UI를 통해 LDAP 자격 증명을 사용하는 것을 방지하는 것이 유용할 수 있습니다. 이를 통해 LDAP를 그룹 동기화에 사용할 수 있으며 SAML 신원 공급자가 사용자 정의 2FA와 같은 추가 확인을 처리할 수 있습니다.

LDAP 웹 로그인이 비활성화되면 사용자는 로그인 페이지에서 **LDAP** 탭을 보지 못합니다. 이는 Git 액세스에 대한 LDAP 자격 증명 사용을 비활성화하지 않습니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['prevent_ldap_sign_in'] = true
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         preventSignin: true
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['prevent_ldap_sign_in'] = true
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `config/gitlab.yaml`을(를) 편집합니다:

   ```yaml
   production:
     ldap:
       prevent_ldap_sign_in: true
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### GitLab을 위한 스마트 카드 인증 제공 {#provide-smart-card-authentication-for-gitlab}

LDAP 서버 및 GitLab에서 스마트 카드 사용에 대한 자세한 내용은 [스마트 카드 인증](../smartcard.md)을 참조하세요.

### 암호화된 자격 증명 사용 {#use-encrypted-credentials}

LDAP 통합 자격 증명을 구성 파일에 평문으로 저장하지 않고 LDAP 자격 증명을 위해 암호화된 파일을 선택적으로 사용할 수 있습니다.

전제 조건:

- 암호화된 자격 증명을 사용하려면 먼저 [암호화된 구성](../../encrypted_configuration.md)을 활성화해야 합니다.

LDAP용 암호화된 구성은 암호화된 YAML 파일에 존재합니다. 파일의 암호화되지 않은 내용은 LDAP 구성의 `servers` 블록에서 비밀 설정의 부분 집합이어야 합니다.

암호화된 파일에 지원되는 구성 항목:

- `bind_dn`
- `password`

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. 처음에 `/etc/gitlab/gitlab.rb`의 LDAP 구성이 다음과 같았다면:

   ```ruby
     gitlab_rails['ldap_servers'] = {
       'main' => {
         'bind_dn' => 'admin',
         'password' => '123'
       }
     }
   ```

1. 암호화된 비밀을 편집합니다:

   ```shell
   sudo gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
   ```

1. LDAP 비밀의 암호화되지 않은 내용을 입력합니다:

   ```yaml
   main:
     bind_dn: admin
     password: '123'
   ```

1. `/etc/gitlab/gitlab.rb`을 편집하고 `bind_dn` 및 `password`의 설정을 제거합니다.
1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

LDAP 암호를 저장하기 위해 Kubernetes 비밀을 사용합니다. 자세한 내용은 [Helm LDAP 비밀](https://docs.gitlab.com/charts/installation/secrets/#ldap-password)을 참조하세요.

{{< /tab >}}

{{< tab title="Docker" >}}

1. 처음에 `docker-compose.yml`의 LDAP 구성이 다음과 같았다면:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'bind_dn' => 'admin',
               'password' => '123'
             }
           }
   ```

1. 컨테이너 내부로 이동하여 암호화된 비밀을 편집합니다:

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
   ```

1. LDAP 비밀의 암호화되지 않은 내용을 입력합니다:

   ```yaml
   main:
     bind_dn: admin
     password: '123'
   ```

1. `docker-compose.yml`을 편집하고 `bind_dn` 및 `password`의 설정을 제거합니다.
1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. 처음에 `/home/git/gitlab/config/gitlab.yml`의 LDAP 구성이 다음과 같았다면:

   ```yaml
   production:
     ldap:
       servers:
         main:
           bind_dn: admin
           password: '123'
   ```

1. 암호화된 비밀을 편집합니다:

   ```shell
   bundle exec rake gitlab:ldap:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. LDAP 비밀의 암호화되지 않은 내용을 입력합니다:

   ```yaml
   main:
    bind_dn: admin
    password: '123'
   ```

1. `/home/git/gitlab/config/gitlab.yml`을 편집하고 `bind_dn` 및 `password`의 설정을 제거합니다.
1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## LDAP DN 및 이메일 업데이트 {#updating-ldap-dn-and-email}

LDAP 서버가 GitLab에서 사용자를 생성하면 사용자의 LDAP DN이 식별자로 GitLab 계정에 연결됩니다.

사용자가 LDAP를 사용하여 로그인을 시도하면 GitLab은 해당 사용자의 계정에 저장된 DN을 사용하여 사용자를 찾으려고 시도합니다.

- GitLab이 DN과 사용자의 이메일 주소로 사용자를 찾은 경우:
  - GitLab 계정의 이메일 주소와 일치하면 GitLab은 추가 조치를 취하지 않습니다.
  - 변경된 경우 GitLab은 사용자의 이메일 기록을 LDAP의 이메일과 일치하도록 업데이트합니다.
- GitLab이 DN으로 사용자를 찾을 수 없으면 이메일로 사용자를 찾으려고 시도합니다. GitLab이:
  - 이메일로 사용자를 찾으면 GitLab은 사용자의 GitLab 계정에 저장된 DN을 업데이트합니다. 두 값 모두 이제 LDAP에 저장된 정보와 일치합니다.
  - 이메일 주소로 사용자를 찾을 수 없습니다 (DN **그리고** 이메일 주소가 모두 변경됨). [사용자 DN 및 이메일이 변경됨](ldap-troubleshooting.md#user-dn-and-email-have-changed)을 참조하세요.

## 익명 LDAP 인증 비활성화 {#disable-anonymous-ldap-authentication}

GitLab은 TLS 클라이언트 인증을 지원하지 않습니다. LDAP 서버에서 다음 단계를 완료합니다.

1. 익명 인증을 비활성화합니다.
1. 다음 인증 유형 중 하나를 활성화합니다:
   - 단순 인증입니다.
   - Simple Authentication and Security Layer (SASL) 인증입니다.

LDAP 서버의 TLS 클라이언트 인증 설정은 필수가 될 수 없으며 클라이언트는 TLS 프로토콜로 인증할 수 없습니다.

## LDAP에서 삭제된 사용자 {#users-deleted-from-ldap}

LDAP 서버에서 삭제된 사용자:

- GitLab에 로그인하는 것이 즉시 차단됩니다.
- [더 이상 라이선스를 사용하지 않습니다](../../moderate_users.md).

그러나 이러한 사용자는 [LDAP check cache가 실행](ldap_synchronization.md#adjust-ldap-sync-schedule)되는 다음 시간까지 SSH를 통해 Git을 계속 사용할 수 있습니다.

계정을 즉시 삭제하려면 수동으로 [사용자를 차단](../../moderate_users.md#block-a-user)할 수 있습니다.

## 사용자 이메일 주소 업데이트 {#update-user-email-addresses}

LDAP 서버의 이메일 주소는 LDAP를 사용하여 로그인할 때 사용자의 진실의 원천으로 간주됩니다.

사용자 이메일 주소 업데이트는 사용자를 관리하는 LDAP 서버에서 수행해야 합니다. GitLab의 이메일 주소는 다음 중 하나로 업데이트됩니다:

- 사용자가 다음에 로그인할 때.
- 다음 [사용자 동기화](ldap_synchronization.md#user-sync)가 실행될 때.

업데이트된 사용자의 이전 이메일 주소는 해당 사용자의 커밋 기록을 보존하기 위한 보조 이메일 주소가 됩니다.

사용자 업데이트의 예상 동작에 대한 자세한 내용은 [LDAP 문제 해결 섹션](ldap-troubleshooting.md#user-dn-and-email-have-changed)에서 찾을 수 있습니다.

## Google Secure LDAP {#google-secure-ldap}

[Google Cloud Identity](https://cloud.google.com/identity/)는 GitLab과 함께 인증 및 그룹 동기화를 위해 구성할 수 있는 Secure LDAP 서비스를 제공합니다. 자세한 구성 지침은 [Google Secure LDAP](google_secure_ldap.md)을 참조하세요.

## 사용자 및 그룹 동기화 {#synchronize-users-and-groups}

LDAP와 GitLab 간의 사용자 및 그룹 동기화에 대한 자세한 내용은 [LDAP 동기화](ldap_synchronization.md)를 참조하세요.

## LDAP에서 SAML로 이동 {#move-from-ldap-to-saml}

1. [SAML 구성 추가](../../../integration/saml.md):
   - [Linux package 설치를 위한 `gitlab.rb`](../../../integration/saml.md).
   - [Helm chart 설치를 위한 `values.yml`](../../../integration/saml.md).

1. 선택사항. [로그인 페이지에서 LDAP 인증 비활성화](#disable-ldap-web-sign-in).
1. 선택사항. 사용자 연결 이슈를 해결하려면 먼저 [해당 사용자의 LDAP 자격 증명 제거](ldap-troubleshooting.md#remove-the-identity-records-that-relate-to-the-removed-ldap-server)를 수행할 수 있습니다.
1. 사용자가 자신의 계정에 로그인할 수 있는지 확인합니다. 사용자가 로그인할 수 없으면 해당 사용자의 LDAP이 여전히 있는지 확인하고 필요한 경우 제거합니다. 이 이슈가 계속되면 로그를 확인하여 이슈를 식별합니다.
1. 구성 파일에서 다음을 변경합니다:
   - `omniauth_auto_link_user`을 `saml`만으로 변경합니다.
   - `omniauth_auto_link_ldap_user`을 false로 변경합니다.
   - `ldap_enabled`을 `false`로 변경합니다. LDAP 공급자 설정을 주석 처리할 수도 있습니다.

## 문제 해결 {#troubleshooting}

[LDAP 문제 해결을 위한 관리자 가이드](ldap-troubleshooting.md)를 참조하세요.
