---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 자체 컴파일된 설치를 위한 GitLab Pages 관리
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

> [!note]
> GitLab Pages를 사용하도록 설정하기 전에 먼저 [GitLab을 설치](../../install/self_compiled/_index.md)했는지 확인하세요.

이 문서에서는 자체 컴파일된 GitLab 설치에 대해 GitLab Pages를 구성하는 방법을 설명합니다.

Linux 패키지 설치를 위한 GitLab Pages 구성에 대한 자세한 내용은 [Linux 패키지 설명서](_index.md)를 참조하세요. Linux 패키지 설치에는 GitLab Pages의 최신 지원 버전이 포함됩니다.

## GitLab Pages 작동 방식 {#how-gitlab-pages-works}

GitLab Pages는 외부 IP 주소에서 수신 대기하고 사용자 지정 도메인 및 인증서를 지원하는 경량 HTTP 서버인 GitLab Pages 데몬을 사용합니다. `SNI`를 통해 동적 인증서를 지원하며 기본적으로 HTTP2를 사용하여 페이지를 제공합니다. 자세한 내용은 [README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md)를 참조하세요.

[사용자 지정 도메인](#custom-domains)의 경우 Pages 데몬은 포트 `80` 또는 `443`에서 수신 대기해야 합니다. 이는 [와일드카드 도메인](#wildcard-domains)에는 적용되지 않습니다. 다음 중 한 가지 방법으로 설정할 수 있습니다:

- GitLab과 동일한 서버에서 보조 IP에서 수신 대기합니다.
- 별도의 서버에서. [Pages 경로](#change-storage-path)도 해당 서버에 있어야 하므로 네트워크를 통해 공유해야 합니다.
- GitLab과 동일한 서버에서 동일한 IP에서 수신 대기하지만 다른 포트에서. 이 경우 로드 밸런서를 사용하여 트래픽을 프록시해야 합니다. HTTPS의 경우 TCP 로드 밸런싱을 사용합니다. TLS 종료(HTTPS 로드 밸런싱)를 사용하면 사용자가 제공한 인증서로 페이지를 제공할 수 없습니다. HTTP의 경우 HTTP 또는 TCP 로드 밸런싱이 모두 허용됩니다.

다음 섹션은 첫 번째 옵션을 가정합니다. 사용자 지정 도메인을 지원하지 않으면 보조 IP가 필요하지 않습니다.

## 필수 요구 사항 {#prerequisites}

Pages 구성을 진행하기 전에 다음을 확인하세요:

- GitLab Pages를 제공할 별도의 도메인이 있어야 합니다. 이 문서에서 이 도메인은 `example.io`입니다.
- 해당 도메인에 대해 **wildcard DNS record**를 구성했습니다.
- GitLab이 설치된 동일한 서버에 `zip` 및 `unzip` 패키지를 설치했습니다. 패키지는 Pages 아티팩트를 압축 및 압축 해제하는 데 필요합니다.
- 선택사항. Pages 도메인(`*.example.io`)에 대한 **wildcard certificate**가 있으며 HTTPS에서 Pages를 제공하기로 결정했습니다.
- 선택 사항이지만 권장됩니다. [인스턴스 러너](../../ci/runners/_index.md)를 구성하고 사용하도록 설정하여 사용자가 자신을 가져올 필요가 없습니다.

### DNS 구성 {#dns-configuration}

GitLab Pages는 자신의 가상 호스트에서 실행되어야 합니다. DNS 서버 또는 공급자에서 GitLab이 실행되는 호스트를 가리키는 [와일드카드 DNS `A` 레코드](https://en.wikipedia.org/wiki/Wildcard_DNS_record)를 추가합니다. 예를 들어:

```plaintext
*.example.io. 1800 IN A 192.0.2.1
```

`example.io`은(는) GitLab Pages가 제공되는 도메인이고 `192.0.2.1`은(는) GitLab 인스턴스의 IP 주소입니다.

> [!note]
> GitLab 도메인을 사용하여 사용자 페이지를 제공하지 마세요. 자세한 내용은 [보안 섹션](#security)을 참조하세요.

## 구성 {#configuration}

GitLab Pages를 여러 가지 방법으로 설정할 수 있습니다. 다음 옵션은 가장 간단한 설정부터 가장 고급 설정까지 나열되어 있습니다. 모든 구성의 최소 요구 사항은 와일드카드 DNS 레코드입니다.

### 와일드카드 도메인 {#wildcard-domains}

각 사이트는 자신의 하위 도메인을 얻습니다(예: `<namespace>.example.io/<project_slug>`). 이 하위 도메인에는 와일드카드 DNS 레코드(`*.example.io`)가 필요하며 대부분의 인스턴스에 권장되는 설정입니다.

전제 조건:

- [와일드카드 DNS 설정](#dns-configuration)

이 설정은 Pages를 사용할 수 있는 최소 설정입니다. 아래에 설명된 모든 다른 설정의 기반입니다. NGINX는 모든 요청을 데몬으로 프록시합니다. Pages 데몬은 외부 세계에 수신 대기하지 않습니다.

1. Pages 데몬을 설치합니다:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. GitLab 설치 디렉터리로 이동합니다:

   ```shell
   cd /home/git/gitlab
   ```

1. `gitlab.yml`을 편집하고 `pages` 설정 아래에서 `enabled`을 `true`로 설정하고 `host`를 GitLab Pages를 제공할 FQDN으로 설정합니다:

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     access_control: false
     port: 8090
     https: false
     artifacts_server: false
     external_http: ["127.0.0.1:8090"]
     secret_file: /home/git/gitlab/gitlab-pages-secret
   ```

1. `/home/git/gitlab-pages/gitlab-pages.conf`에 다음 구성 파일을 추가합니다. `example.io`를 GitLab Pages를 제공할 FQDN으로 바꾸고 `gitlab.example.com`를 GitLab 인스턴스의 URL로 바꿉니다:

   ```ini
   listen-http=:8090
   pages-root=/home/git/gitlab/shared/pages
   api-secret-key=/home/git/gitlab/gitlab-pages-secret
   pages-domain=example.io
   internal-gitlab-server=https://gitlab.example.com

   You can use an `http` address when running GitLab Pages and GitLab on the same host. If you use
   `https` with a self-signed certificate, make your custom CA available to GitLab Pages, for
   example by setting the `SSL_CERT_DIR` environment variable.

1. 비밀 API 키를 추가합니다:

   ```shell
   sudo -u git -H openssl rand -base64 32 > /home/git/gitlab/gitlab-pages-secret
   ```

1. pages 데몬을 사용하도록 설정하려면:

   - 시스템에서 systemd init를 사용하는 경우 다음을 실행합니다:

     ```shell
     sudo systemctl edit gitlab.target
     ```

     편집기에서 다음을 추가하고 파일을 저장합니다:

     ```plaintext
     [Unit]
     Wants=gitlab-pages.service
     ```

   - 시스템에서 SysV init를 사용하는 경우 `/etc/default/gitlab`을 편집하고 `gitlab_pages_enabled`를 `true`로 설정합니다:

     ```ini
     gitlab_pages_enabled=true
     ```

1. `gitlab-pages` NGINX 구성 파일을 복사합니다:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. NGINX를 다시 시작합니다.
1. [GitLab을 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

### TLS 지원을 포함한 와일드카드 도메인 {#wildcard-domains-with-tls-support}

전제 조건:

- [와일드카드 DNS 설정](#dns-configuration)
- 와일드카드 TLS 인증서

URL 체계: `https://<namespace>.example.io/<project_slug>`

NGINX는 모든 요청을 데몬으로 프록시합니다. Pages 데몬은 공인 인터넷에 수신 대기하지 않습니다.

TLS 지원을 포함한 와일드카드 도메인을 구성하려면:

1. Pages 데몬을 설치합니다:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. `gitlab.yml`에서 `port`를 `443`로 설정하고 `https`를 `true`로 설정합니다:

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 443
     https: true
   ```

1. `/etc/default/gitlab`을 편집하고 `gitlab_pages_enabled`를 `true`로 설정합니다. `gitlab_pages_options`에서 `-pages-domain`는 `host` 값과 일치해야 합니다. `-root-cert` 및 `-root-key` 설정은 `example.io` 도메인에 대한 와일드카드 TLS 인증서입니다:

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key"
   ```

1. `gitlab-pages-ssl` NGINX 구성 파일을 복사합니다:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. NGINX를 다시 시작합니다.
1. [GitLab을 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

## 고급 구성 {#advanced-configuration}

와일드카드 도메인 외에도 사용자 지정 도메인으로 작동하도록 GitLab Pages를 구성할 수 있으며, TLS 인증서가 있거나 없을 수 있습니다.

### 사용자 지정 도메인 {#custom-domains}

전제 조건:

- [와일드카드 DNS 설정](#dns-configuration)
- 보조 IP

URL 체계: `http://<namespace>.example.io/<project_slug>` 및 `http://custom-domain.com`

이 구성에서 Pages 데몬이 실행 중이고 NGINX가 요청을 프록시하지만 데몬은 공인 인터넷의 요청도 받을 수 있습니다. 사용자 지정 도메인은 TLS 없이 지원됩니다.

사용자 지정 도메인을 구성하려면:

1. Pages 데몬을 설치합니다:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. `gitlab.yml`을 편집합니다. `host`를 GitLab Pages를 제공할 FQDN으로 설정하고 `external_http`를 Pages 데몬이 수신 대기하는 보조 IP로 설정합니다:

   ```yaml
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 80
     https: false

     external_http: 192.0.2.2:80
   ```

1. `/etc/default/gitlab`을 편집하고 `gitlab_pages_enabled`를 `true`로 설정합니다. `gitlab_pages_options`에서:

   - `-pages-domain`은 `host`와 일치해야 합니다.
   - `-listen-http`은 `external_http`와 일치해야 합니다.
   - `-listen-https`은 `external_https`와 일치해야 합니다.

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80"
   ```

1. `gitlab-pages` NGINX 구성 파일을 복사합니다:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. `/etc/nginx/site-available/`의 모든 GitLab 관련 구성을 편집하고 `0.0.0.0`를 `192.0.2.1`으로 바꿉니다. 여기서 `192.0.2.1`는 GitLab이 수신 대기하는 주 IP입니다.
1. NGINX를 다시 시작합니다.
1. [GitLab을 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

### TLS 지원을 포함한 사용자 지정 도메인 {#custom-domains-with-tls-support}

전제 조건:

- [와일드카드 DNS 설정](#dns-configuration)
- 와일드카드 TLS 인증서
- 보조 IP

URL 체계: `https://<namespace>.example.io/<project_slug>` 및 `https://custom-domain.com`

이 구성에서 Pages 데몬이 실행 중이고 NGINX가 요청을 프록시하지만 데몬은 공인 인터넷의 요청도 받을 수 있습니다. 사용자 지정 도메인 및 TLS가 지원됩니다.

TLS 지원을 포함한 사용자 지정 도메인을 구성하려면:

1. Pages 데몬을 설치합니다:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. `gitlab.yml`을 편집합니다. `host`를 GitLab Pages를 제공할 FQDN으로 설정하고 `external_http` 및 `external_https`를 Pages 데몬이 수신 대기하는 보조 IP로 설정합니다:

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 443
     https: true

     external_http: 192.0.2.2:80
     external_https: 192.0.2.2:443
   ```

1. `/etc/default/gitlab`을 편집하고 `gitlab_pages_enabled`를 `true`로 설정합니다. `gitlab_pages_options`에서:

   - `-pages-domain`은 `host`와 일치해야 합니다.
   - `-listen-http`은 `external_http`와 일치해야 합니다.
   - `-listen-https`은 `external_https`와 일치해야 합니다.

   `-root-cert` 및 `-root-key` 설정은 `example.io` 도메인에 대한 와일드카드 TLS 인증서입니다:

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80 -listen-https 192.0.2.2:443 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key"
   ```

1. `gitlab-pages-ssl` NGINX 구성 파일을 복사합니다:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. `/etc/nginx/site-available/`의 모든 GitLab 관련 구성을 편집하고 `0.0.0.0`를 `192.0.2.1`으로 바꿉니다. 여기서 `192.0.2.1`는 GitLab이 수신 대기하는 주 IP입니다.
1. NGINX를 다시 시작합니다.
1. [GitLab을 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

## NGINX 주의 사항 {#nginx-caveats}

> [!note]
> 다음 정보는 자체 컴파일된 설치에만 적용됩니다.

NGINX 구성에서 도메인 이름을 설정할 때 주의하세요. 백슬래시를 제거하면 안 됩니다.

GitLab Pages 도메인이 `example.io`인 경우 다음을 바꿉니다:

```nginx
server_name ~^.*\.YOUR_GITLAB_PAGES\.DOMAIN$;
```

다음으로:

```nginx
server_name ~^.*\.example\.io$;
```

하위 도메인을 사용하는 경우 첫 번째를 제외한 모든 점(`.`)을 백슬래시(`\`)로 이스케이프합니다. 예를 들어 `pages.example.io`는 다음과 같습니다:

```nginx
server_name ~^.*\.pages\.example\.io$;
```

## 액세스 제어 {#access-control}

GitLab Pages 액세스 제어는 프로젝트별로 구성할 수 있습니다. Pages 사이트에 대한 액세스는 해당 프로젝트에 대한 사용자의 멤버십을 기반으로 제어할 수 있습니다.

액세스 제어는 Pages 데몬을 GitLab과 함께 OAuth 애플리케이션으로 등록하여 작동합니다. 인증되지 않은 사용자가 비공개 Pages 사이트에 액세스를 요청할 때마다 Pages 데몬은 사용자를 GitLab으로 리디렉션합니다. 인증이 성공하면 사용자는 쿠키에 지속되는 토큰과 함께 Pages로 다시 리디렉션됩니다. 쿠키는 비밀 키로 서명되므로 변조를 감지할 수 있습니다.

비공개 사이트의 리소스를 보기 위한 각 요청은 해당 토큰을 사용하여 Pages에 의해 인증됩니다. 수신하는 각 요청에 대해 Pages는 GitLab API에 요청하여 사용자가 해당 사이트를 읽을 권한이 있는지 확인합니다.

Pages의 액세스 제어 매개변수는 다음과 같습니다:

- `gitlab-pages-config`이라는 규칙의 이름으로 구성 파일에 설정합니다.
- `-config` 플래그 또는 `CONFIG` 환경 변수를 사용하여 Pages에 전달합니다.

Pages 액세스 제어는 기본적으로 사용하지 않도록 설정됩니다. 사용하도록 설정하려면:

1. `config/gitlab.yml`을 수정합니다:

   ```yaml
   pages:
     access_control: true
   ```

1. [GitLab을 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.
1. 새 [시스템 OAuth 애플리케이션](../../integration/oauth_provider.md#create-a-user-owned-application)을 만듭니다. 이름을 `GitLab Pages`로 지정하고 **Redirect URL**을 `https://projects.example.io/auth`로 설정합니다. 신뢰할 수 있는 애플리케이션일 필요는 없지만 `api` 범위가 필요합니다.
1. 다음 인수를 사용하여 구성 파일을 전달하여 Pages 데몬을 시작합니다:

   ```shell
     auth-client-id=<OAuth Application ID generated by GitLab>
     auth-client-secret=<OAuth code generated by GitLab>
     auth-redirect-uri='http://projects.example.io/auth'
     auth-secret=<40 random hex characters>
     auth-server=<URL of the GitLab instance>
   ```

1. 사용자는 이제 [프로젝트 설정](../../user/project/pages/pages_access_control.md)에서 구성할 수 있습니다.

## 저장소 경로 변경 {#change-storage-path}

GitLab Pages 콘텐츠가 저장된 기본 경로를 변경하려면:

1. Pages는 기본적으로 `/home/git/gitlab/shared/pages`에 저장됩니다. 다른 위치를 사용하려면 `gitlab.yml` 섹션 아래에서 `pages`을 편집합니다:

   ```yaml
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     path: /mnt/storage/pages
   ```

1. [GitLab을 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

## 최대 Pages 크기 설정 {#set-maximum-pages-size}

프로젝트당 압축된 보관 파일의 기본 최대 크기는 100MB입니다.

전제 조건:

- 관리자 액세스.

이 값을 변경하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Pages**를 확장합니다.
1. **Maximum size of pages (MB)**의 값을 업데이트합니다.

## 백업 {#backup}

Pages는 [정기적 백업](../backup_restore/_index.md)의 일부이므로 구성할 것이 없습니다.

## 보안 {#security}

XSS 공격을 방지하기 위해 GitLab과 다른 호스트명 아래에서 GitLab Pages를 실행하는 것을 강력히 권장합니다.
