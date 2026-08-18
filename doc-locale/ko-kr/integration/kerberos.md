---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab과 Kerberos 통합
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 [Kerberos](https://web.mit.edu/kerberos/)를 인증 메커니즘으로 통합할 수 있습니다.

- 사용자가 Kerberos 자격 증명으로 로그인할 수 있도록 GitLab을 구성할 수 있습니다.
- Kerberos를 사용하여 [전송되는 비밀번호를 가로채거나 도청하지 못하도록 방지](https://web.mit.edu/sipb/doc/working/guide/guide/node20.html)할 수 있습니다.

Kerberos는 GitLab Enterprise Edition(EE)을 사용하는 인스턴스에서만 사용할 수 있습니다. GitLab Community Edition(CE)을 실행 중인 경우 [GitLab CE에서 GitLab EE로 변환](../update/convert_to_ee/package.md)할 수 있습니다.

> [!warning]
> GitLab CI/CD는 통합이 [전용 포트를 사용하도록 설정](#http-git-access-with-kerberos-token-passwordless-authentication)되지 않으면 Kerberos가 활성화된 GitLab 인스턴스에서 작동하지 않습니다.

## 구성 {#configuration}

GitLab이 Kerberos 토큰 기반 인증을 제공하려면 다음 필수 구성 요소를 수행합니다. 영역 지정과 같은 Kerberos 사용을 위해 시스템을 구성해야 합니다. GitLab은 시스템의 Kerberos 설정을 사용합니다.

### GitLab keytab {#gitlab-keytab}

1. GitLab 서버의 HTTP 서비스에 대한 Kerberos Service Principal을 생성합니다. GitLab 서버가 `gitlab.example.com`이고 Kerberos 영역이 `EXAMPLE.COM`인 경우 Kerberos 데이터베이스에서 Service Principal `HTTP/gitlab.example.com@EXAMPLE.COM`을 생성합니다.
1. GitLab 서버에서 Service Principal에 대한 keytab을 생성합니다. 예를 들어, `/etc/http.keytab`입니다.

keytab은 민감한 파일이므로 GitLab 사용자가 읽을 수 있어야 합니다. 소유권을 설정하고 파일을 적절히 보호합니다:

```shell
sudo chown git /etc/http.keytab
sudo chmod 0600 /etc/http.keytab
```

### GitLab 구성 {#configure-gitlab}

#### 자체 컴파일 설치 {#self-compiled-installations}

> [!note]
> 자체 컴파일 설치의 경우 `kerberos` gem 그룹이 [설치되었는지](../install/self_compiled/_index.md#install-gems) 확인합니다.

1. `kerberos` 섹션의 [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)을 편집하여 Kerberos 티켓 기반 인증을 활성화합니다. 대부분의 경우 Kerberos를 활성화하고 keytab의 위치를 지정하기만 하면 됩니다:

   ```yaml
   omniauth:
     enabled: true
     allow_single_sign_on: ['kerberos']

   kerberos:
     # Allow the HTTP Negotiate authentication method for Git clients
     enabled: true

     # Kerberos 5 keytab file. The keytab file must be readable by the GitLab user,
     # and should be different from other keytabs in the system.
     # (default: use default keytab from Krb5 config)
     keytab: /etc/http.keytab
   ```

1. [GitLab을 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

#### Linux 패키지 설치 {#linux-package-installations}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['kerberos']

   gitlab_rails['kerberos_enabled'] = true
   gitlab_rails['kerberos_keytab'] = "/etc/http.keytab"
   ```

   GitLab이 Kerberos를 통해 첫 로그인 시 사용자를 자동으로 생성하지 않으려면 `kerberos`를 `gitlab_rails['omniauth_allow_single_sign_on']`에 대해 설정하지 마십시오.
1. [GitLab 재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

GitLab은 이제 로그인 및 HTTP Git 액세스를 위한 `negotiate` 인증 방법을 제공하므로 이 인증 프로토콜을 지원하는 Git 클라이언트가 Kerberos 토큰으로 인증할 수 있습니다.

#### 단일 로그인 활성화 {#enable-single-sign-on}

[공통 설정](omniauth.md#configure-common-settings)을 구성하여 `kerberos`을 단일 로그인 공급자로 추가하세요. 이를 통해 기존 GitLab 계정이 없는 사용자를 위해 Just-In-Time 계정 프로비저닝이 활성화됩니다.

## Kerberos 계정 생성 및 연결 {#create-and-link-kerberos-accounts}

Kerberos 계정을 기존 GitLab 계정에 연결하거나 Kerberos 사용자가 로그인하려고 할 때 새 계정을 생성하도록 GitLab을 설정할 수 있습니다.

### Kerberos 계정을 기존 GitLab 계정에 연결 {#link-a-kerberos-account-to-an-existing-gitlab-account}

{{< history >}}

- Kerberos SPNEGO는 GitLab 15.4에서 Kerberos로 [이름이 바뀌었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96335).

{{< /history >}}

관리자인 경우 Kerberos 계정을 기존 GitLab 계정에 연결할 수 있습니다. 이렇게 하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 사용자를 선택한 후 **ID** 탭을 선택합니다.
1. **공급자** 드롭다운 목록에서 **Kerberos**를 선택합니다.
1. **식별자**가 Kerberos 사용자 이름과 일치하는지 확인합니다.
1. **변경 사항 저장**을 선택합니다.

관리자가 아닌 경우:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택하세요.
1. 왼쪽 사이드바에서 **액세스** > **비밀번호와 인증**을 선택하세요.
1. **서비스 로그인** 섹션에서 **Connect Kerberos**을 선택합니다. **서비스 로그인** Kerberos 옵션이 보이지 않으면 [단일 로그인 활성화](#enable-single-sign-on)의 요구 사항을 따릅니다.

어느 경우든 이제 Kerberos 자격 증명을 사용하여 GitLab 계정에 로그인할 수 있습니다.

### 첫 로그인 시 계정 생성 {#create-accounts-on-first-sign-in}

사용자가 Kerberos 계정으로 GitLab에 처음 로그인할 때 GitLab은 일치하는 계정을 생성합니다. 계속하기 전에 Linux 패키지 및 자체 컴파일 인스턴스를 위한 [일반 구성 설정](omniauth.md#configure-common-settings) 옵션을 검토합니다. `kerberos`도 포함해야 합니다.

이 정보를 준비한 상태에서:

1. `'kerberos'`을 `allow_single_sign_on` 설정과 함께 포함합니다.
1. 기본값으로 `block_auto_created_users` 옵션인 true를 수락합니다.
1. 사용자가 Kerberos 자격 증명으로 로그인하려고 하면 GitLab은 새 계정을 생성합니다.
   1. `block_auto_created_users`이 true인 경우 Kerberos 사용자에게 다음과 같은 메시지가 표시될 수 있습니다:

      ```shell
      Your account has been blocked. Please contact your GitLab
      administrator if you think this is an error.
      ```

      1. 관리자는 새로 차단된 계정을 확인할 수 있습니다:
         1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
         1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택하고 **차단됨** 탭을 검토합니다.
      1. 사용자를 활성화할 수 있습니다.
   1. `block_auto_created_users`이 false인 경우 Kerberos 사용자는 인증되고 GitLab에 로그인됩니다.

> [!warning]
> `block_auto_created_users`의 기본값을 유지할 것을 권장합니다. 관리자의 지식 없이 GitLab에 계정을 생성하는 Kerberos 사용자는 보안 위험이 될 수 있습니다.

## Kerberos 및 LDAP 계정 함께 연결 {#link-kerberos-and-ldap-accounts-together}

사용자가 Kerberos로 로그인하지만 [LDAP 통합](../administration/auth/ldap/_index.md)도 활성화된 경우 사용자는 첫 로그인 시 LDAP 계정에 연결됩니다. 이를 작동시키려면 몇 가지 필수 구성 요소를 충족해야 합니다:

Kerberos 사용자 이름은 LDAP 사용자의 UID와 일치해야 합니다. GitLab [LDAP 구성](../administration/auth/ldap/_index.md#configure-ldap)에서 UID로 사용되는 LDAP 특성을 선택할 수 있지만 Active Directory의 경우 이는 `sAMAccountName`이어야 합니다.

Kerberos 영역은 LDAP 사용자의 Distinguished Name의 도메인 부분과 일치해야 합니다. 예를 들어 Kerberos 영역이 `AD.EXAMPLE.COM`인 경우 LDAP 사용자의 Distinguished Name은 `dc=ad,dc=example,dc=com`로 끝나야 합니다.

이 규칙을 합치면 사용자의 Kerberos 사용자 이름이 `foo@AD.EXAMPLE.COM` 형식이고 LDAP Distinguished Name이 `sAMAccountName=foo,dc=ad,dc=example,dc=com`처럼 보이는 경우에만 연결이 작동합니다.

### 사용자 지정 허용된 영역 {#custom-allowed-realms}

사용자의 Kerberos 영역이 사용자의 LDAP DN에서 도메인과 일치하지 않을 때 사용자 지정 허용된 영역을 구성할 수 있습니다. 구성 값은 사용자가 가질 수 있는 모든 도메인을 지정해야 합니다. 다른 모든 도메인은 무시되고 LDAP 신원이 연결되지 않습니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

   ```ruby
   gitlab_rails['kerberos_simple_ldap_linking_allowed_realms'] = ['example.com','kerberos.example.com']
   ```

1. 파일을 저장하고 GitLab을 [재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

1. `config/gitlab.yml`을 편집합니다.

   ```yaml
   kerberos:
     simple_ldap_linking_allowed_realms: ['example.com','kerberos.example.com']
   ```

1. 파일을 저장하고 GitLab을 [다시 시작](../administration/restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

## HTTP Git 액세스 {#http-git-access}

연결된 Kerberos 계정을 사용하면 표준 GitLab 자격 증명뿐만 아니라 Kerberos 계정을 사용하여 `git pull`과 `git push`을 수행할 수 있습니다.

연결된 Kerberos 계정이 있는 GitLab 사용자는 Kerberos 토큰을 사용하여 `git pull`과 `git push`도 수행할 수 있습니다. 즉, 각 작업마다 비밀번호를 보낼 필요가 없습니다.

> [!warning]
> 버전 7.64.1보다 이전 `libcurl`에 대한 [알려진 이슈](https://github.com/curl/curl/issues/1261)가 있으며, 협상할 때 연결을 재사용하지 않습니다. 이는 푸시가 `http.postBuffer` 구성보다 클 때 인증 이슈로 이어집니다. 이를 방지하려면 Git이 최소 `libcurl` 7.64.1을 사용하고 있는지 확인합니다. 설치된 `libcurl` 버전을 확인하려면 `curl-config --version`을 실행합니다.

### Kerberos 토큰을 사용한 HTTP Git 액세스(암호 없는 인증) {#http-git-access-with-kerberos-token-passwordless-authentication}

[현재 Git 버전의 버그](https://lore.kernel.org/git/YKNVop80H8xSTCjz@coredump.intra.peff.net/T/#mab47fd7dcb61fee651f7cc8710b8edc6f62983d5) 때문에 `git` CLI 명령은 HTTP 서버가 이를 제공하는 경우에만 `negotiate` 인증 방법을 사용합니다. 이 방법이 실패한 경우에도(예: 클라이언트에 Kerberos 토큰이 없는 경우) 말입니다. 따라서 Kerberos 인증이 실패하면 포함된 사용자 이름 및 비밀번호(`basic`라고도 함) 인증으로 폴백하는 것이 불가능합니다.

GitLab 사용자가 현재 Git 버전으로 `basic` 또는 `negotiate` 인증을 사용할 수 있도록 하려면 다른 포트(예: `8443`)에서 Kerberos 티켓 기반 인증을 제공할 수 있으며 표준 포트는 `basic` 인증만 제공합니다.

> [!note]
> [Git 2.4 이상](https://github.com/git/git/blob/master/Documentation/RelNotes/2.4.0.adoc?plain=1#L225-L228)은 사용자 이름과 비밀번호를 대화형으로 전달하거나 자격 증명 관리자를 통해 전달하는 경우 `basic` 인증으로 폴백할 수 있습니다. 사용자 이름과 비밀번호가 URL의 일부로 전달되면 폴백에 실패합니다. 예를 들어 이는 [CI/CD 작업 토큰으로 인증](../ci/jobs/ci_job_token.md)하는 GitLab CI/CD 작업에서 발생할 수 있습니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

   ```ruby
   gitlab_rails['kerberos_use_dedicated_port'] = true
   gitlab_rails['kerberos_port'] = 8443
   gitlab_rails['kerberos_https'] = true
   ```

1. [GitLab 재구성](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스) HTTPS 사용" >}}

1. GitLab의 NGINX 구성 파일(예: `/etc/nginx/sites-available/gitlab-ssl`)을 편집하고 표준 HTTPS 포트 외에 포트 `8443`를 수신 대기하도록 NGINX를 구성합니다:

   ```conf
   server {
     listen 0.0.0.0:443 ssl;
     listen [::]:443 ipv6only=on ssl default_server;
     listen 0.0.0.0:8443 ssl;
     listen [::]:8443 ipv6only=on ssl;
   ```

1. `kerberos` 섹션의 [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)을 업데이트합니다:

   ```yaml
   kerberos:
     # Dedicated port: Git before 2.4 does not fall back to Basic authentication if Negotiate fails.
     # To support both Basic and Negotiate methods with older versions of Git, configure
     # nginx to proxy GitLab on an extra port (for example: 8443) and uncomment the following lines
     # to dedicate this port to Kerberos authentication. (default: false)
     use_dedicated_port: true
     port: 8443
     https: true
   ```

1. [GitLab 및 NGINX를 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

이 변경 후 Git 원격 URL을 `https://gitlab.example.com:8443/mygroup/myproject.git`로 업데이트하여 Kerberos 티켓 기반 인증을 사용합니다.

## 비밀번호 기반에서 티켓 기반 Kerberos 로그인으로 업그레이드 {#upgrading-from-password-based-to-ticket-based-kerberos-sign-ins}

이전 버전의 GitLab에서 사용자는 로그인할 때 Kerberos 사용자 이름과 비밀번호를 GitLab에 제출해야 했습니다.

GitLab 15.0에서 비밀번호 기반 Kerberos 로그인을 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/2908)했습니다.

## Active Directory Kerberos 환경 지원 {#support-for-active-directory-kerberos-environments}

Active Directory 도메인에서 Kerberos 티켓 기반 인증을 사용할 때 Kerberos 프로토콜의 확장으로 인해 HTTP 인증 헤더가 기본 크기인 8kB보다 클 수 있으므로 NGINX에서 허용하는 최대 헤더 크기를 늘려야 할 수 있습니다. `large_client_header_buffers`을 [NGINX 구성](https://nginx.org/en/docs/http/ngx_http_core_module.html#large_client_header_buffers)에서 더 큰 값으로 구성합니다.

### Windows AD에서 AES 전용 암호화를 사용하여 생성된 Keytab 사용 {#use-keytabs-created-using-aes-only-encryption-with-windows-ad}

Advanced Encryption Standard(AES) 전용 암호화를 사용하여 keytab을 생성할 때 AD 서버의 해당 계정에 대해 **This account supports Kerberos AES <128/256> bit encryption** 확인란을 선택해야 합니다. 확인란이 128비트인지 256비트인지는 keytab을 생성할 때 사용한 암호화 강도에 따라 달라집니다. 이를 확인하려면 Active Directory 서버에서:

1. **Users and Groups** 도구를 엽니다.
1. keytab을 생성하는 데 사용한 계정을 찾습니다.
1. 계정을 마우스 오른쪽 단추로 클릭하고 **특성**을 선택합니다.
1. **Account Options**에서 **계정** 탭의 적절한 AES 암호화 지원 확인란을 선택합니다.
1. 저장 및 닫기합니다.
