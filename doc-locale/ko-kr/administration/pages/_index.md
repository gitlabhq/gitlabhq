---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pages 관리
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab Pages는 GitLab 프로젝트 및 그룹을 위한 정적 사이트 호스팅을 제공합니다. 서버 관리자는 사용자가 이 기능에 액세스하기 전에 Pages를 구성해야 합니다. GitLab Pages를 통해 관리자는 다음을 수행할 수 있습니다:

- [사용자 정의 도메인](#custom-domains)과 SSL/TLS 인증서로 정적 웹사이트를 안전하게 호스팅합니다.
- GitLab 권한을 통해 Pages 사이트에 대한 액세스를 제어하기 위해 인증을 활성화합니다.
- 멀티 노드 환경에서 객체 스토리지 또는 네트워크 스토리지를 사용하여 배포를 확장합니다.
- 속도 제한 및 사용자 정의 헤더를 통해 트래픽을 모니터링하고 관리합니다.
- 모든 Pages 사이트에 대해 IPv4 및 IPv6 주소를 지원합니다.

GitLab Pages 데몬은 별도 프로세스로 실행되며 GitLab과 동일한 서버 또는 자체 전용 인프라에서 구성할 수 있습니다. 사용자 설명서는 [GitLab Pages](../../user/project/pages/_index.md)를 참조하세요.

> [!note]
> 이 가이드는 Linux 패키지 설치를 위한 것입니다. 자체 컴파일 설치의 경우 [자체 컴파일 설치를 위한 GitLab Pages 관리](source.md)를 참조하세요.

## GitLab Pages 데몬 {#gitlab-pages-daemon}

GitLab Pages는 [GitLab Pages 데몬](https://gitlab.com/gitlab-org/gitlab-pages) 을 사용합니다. 이는 외부 IP 주소에서 수신 대기할 수 있고 [사용자 정의 도메인](#custom-domains)과 사용자 정의 인증서를 지원하는 Go로 작성된 기본 HTTP 서버입니다. 서버 이름 표시(SNI)를 통해 동적 인증서를 지원하며 기본적으로 HTTP2를 사용하여 페이지를 노출합니다.

자세한 내용은 [README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md)를 참조하세요.

[사용자 정의 도메인](#custom-domains)과 함께 사용할 때 Pages 데몬은 포트 `80` 또는 `443`에서 수신 대기해야 합니다. 이는 [와일드카드 도메인](#wildcard-domains)에는 필요하지 않습니다.

Pages 데몬을 실행할 수 있습니다:

- GitLab과 동일한 서버에서 보조 IP에서 수신 대기합니다.
- [별도 서버](#running-gitlab-pages-on-a-separate-server)에서. [Pages 경로](#change-storage-path)는 Pages 데몬이 설치된 서버에도 있어야 하므로 네트워크를 통해 공유해야 합니다.
- GitLab과 동일한 서버에서 동일한 IP에서 수신 대기하지만 다른 포트에서. 이 경우 로드 밸런서를 사용하여 트래픽을 프록시해야 합니다. HTTPS의 경우 TCP 로드 밸런싱을 사용합니다. TLS 종료(HTTPS 로드 밸런싱)를 사용하면 사용자가 제공한 인증서로 페이지를 제공할 수 없습니다. HTTP의 경우 HTTP 또는 TCP 로드 밸런싱이 모두 허용됩니다.

다음 섹션은 첫 번째 옵션을 가정합니다. 사용자 지정 도메인을 지원하지 않으면 보조 IP가 필요하지 않습니다.

## 필수 요구 사항 {#prerequisites}

이 섹션에서는 GitLab Pages를 구성하기 위한 필수 조건을 설명합니다.

> [!note]
> GitLab 인스턴스와 Pages 데몬이 프라이빗 네트워크에 배포되거나 방화벽 뒤에 있으면 GitLab Pages 웹사이트는 프라이빗 네트워크에 액세스할 수 있는 디바이스 및 사용자만 액세스할 수 있습니다.

### 와일드카드 도메인 {#wildcard-domains}

각 사이트는 자신의 하위 도메인을 얻습니다(예: `<namespace>.example.io/<project_slug>`). 이 하위 도메인에는 와일드카드 DNS 레코드(`*.example.io`)가 필요하며 대부분의 인스턴스에 권장되는 설정입니다.

와일드카드 도메인에 대해 Pages를 구성하기 전에 다음을 수행해야 합니다:

1. GitLab 인스턴스 도메인의 하위 도메인이 아닌 Pages 도메인을 보유합니다.

   | GitLab 도메인        | Pages 도메인        | 작동하나요? |
   | -------------------- | ------------------- | ------------- |
   | `example.com`        | `example.io`        | {{< icon name="check-circle" >}} 예 |
   | `example.com`        | `pages.example.com` | {{< icon name="dotted-circle" >}} 아니요 <sup>1</sup> |
   | `gitlab.example.com` | `pages.example.com` | {{< icon name="check-circle" >}} 예 |

   **각주**:

   1. Pages 도메인이 GitLab 인스턴스 도메인의 하위 도메인이면 배포된 모든 Pages 사이트가 GitLab 세션 쿠키에 액세스할 수 있습니다.

1. **wildcard DNS record**를 구성합니다.
1. 선택사항. HTTPS에서 Pages를 제공하기로 결정한 경우 해당 도메인에 대한 **wildcard certificate**를 보유합니다.
1. 선택 사항이지만 권장됩니다. [인스턴스 러너](../../ci/runners/_index.md)를 활성화하여 사용자가 자신의 것을 가져올 필요가 없도록 합니다.
1. 사용자 정의 도메인의 경우 **secondary IP**를 보유합니다.

### 단일 도메인 사이트 {#single-domain-sites}

모든 사이트가 하나의 도메인을 공유하며 와 프로젝트 슬러그가 경로 세그먼트로 사용됩니다(예: `example.io/<namespace>/<project_slug>`). 이 도메인은 단일 DNS `A` 레코드만 필요합니다.

단일 도메인 사이트에 대해 Pages를 구성하기 전에 다음을 수행해야 합니다:

1. GitLab 인스턴스 도메인의 하위 도메인이 아닌 Pages 도메인을 보유합니다.

   | GitLab 도메인        | Pages 도메인        | 지원됨 |
   | -------------------- | ------------------- | ------------- |
   | `example.com`        | `example.io`        | {{< icon name="check-circle" >}} 예 |
   | `example.com`        | `pages.example.com` | {{< icon name="dotted-circle" >}} 아니요 <sup>1</sup> |
   | `gitlab.example.com` | `pages.example.com` | {{< icon name="check-circle" >}} 예 |

   **각주**:

   1. Pages 도메인이 GitLab 인스턴스 도메인의 하위 도메인이면 배포된 모든 Pages 사이트가 GitLab 세션 쿠키에 액세스할 수 있습니다.

1. **DNS record**를 구성합니다.
1. 선택사항. HTTPS에서 Pages를 제공하기로 결정한 경우 해당 도메인에 대한 **TLS certificate**를 보유합니다.
1. 선택 사항이지만 권장됩니다. [인스턴스 러너](../../ci/runners/_index.md)를 활성화하여 사용자가 자신의 것을 가져올 필요가 없도록 합니다.
1. 사용자 정의 도메인의 경우 **secondary IP**를 보유합니다.

### Public Suffix List에 도메인 추가 {#add-the-domain-to-the-public-suffix-list}

[Public Suffix List](https://publicsuffix.org)는 하위 도메인을 처리하는 방법을 결정하기 위해 브라우저에서 사용됩니다. GitLab 인스턴스에서 공개 사용자가 GitLab Pages 사이트를 만들 수 있으면 해당 사용자가 Pages 도메인(`example.io`)에서 하위 도메인을 만들 수도 있습니다. 도메인을 Public Suffix List에 추가하면 브라우저가 [슈퍼쿠키](https://en.wikipedia.org/wiki/HTTP_cookie#Supercookie)를 수락하는 것을 방지합니다.

GitLab Pages 하위 도메인을 제출하려면 [Public Suffix List에 수정 사항 제출](https://publicsuffix.org/submit/)을 참조하세요. 예를 들어 도메인이 `example.io`인 경우 `example.io`이 Public Suffix List에 추가되도록 요청해야 합니다. GitLab.com은 `gitlab.io`을 [2016년에](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/230) 추가했습니다.

### DNS 구성 {#dns-configuration}

GitLab Pages는 자체 가상 호스트에서 실행됩니다. DNS 서버 또는 공급자에서 GitLab이 실행되는 호스트를 가리키는 [와일드카드 DNS `A` 레코드](https://en.wikipedia.org/wiki/Wildcard_DNS_record)를 추가합니다. 예를 들어:

```plaintext
*.example.io. 1800 IN A    192.0.2.1
*.example.io. 1800 IN AAAA 2001:db8::1
```

`example.io`은 GitLab Pages가 제공되는 도메인이고, `192.0.2.1`는 GitLab 인스턴스의 IPv4 주소이며, `2001:db8::1`은 IPv6 주소입니다. IPv6이 없으면 `AAAA` 레코드를 생략할 수 있습니다.

#### 단일 도메인 사이트에 대한 DNS 구성 {#dns-configuration-for-single-domain-sites}

{{< history >}}

- [GitLab 16.7에서](https://gitlab.com/gitlab-org/gitlab/-/issues/17584) [실험으로](../../policy/development_stages_support.md) 도입되었습니다.
- GitLab 16.11에서 [베타](../../policy/development_stages_support.md) 로 [전환](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621)되었습니다.
- GitLab 17.2에서 [구현이](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111) NGINX에서 GitLab Pages 코드베이스로 변경되었습니다.
- GitLab 17.4에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)되었습니다.

{{< /history >}}

와일드카드 DNS 없이 단일 도메인 사이트에 대해 GitLab Pages DNS를 구성하려면:

1. `gitlab_pages['namespace_in_path'] = true`을 `/etc/gitlab/gitlab.rb`에 추가하여 이 기능에 대한 GitLab Pages 플래그를 활성화합니다.
1. DNS 공급자에서 `example.io`에 대한 항목을 추가합니다. `example.io`를 도메인 이름으로 바꾸고 `192.0.0.0`을 인스턴스의 IPv4 주소로 바꿉니다:

   ```plaintext
   example.io          1800 IN A    192.0.0.0
   ```

1. 선택사항. GitLab 인스턴스에 IPv6 주소가 있으면 항목을 추가합니다. `example.io`을 도메인 이름으로 바꾸고 `2001:db8::1`를 인스턴스의 IPv6 주소로 바꿉니다:

   ```plaintext
   example.io          1800 IN AAAA 2001:db8::1
   ```

   `example.io`은 GitLab Pages가 제공되는 도메인입니다.

#### 사용자 정의 도메인에 대한 DNS 구성 {#dns-configuration-for-custom-domains}

사용자 정의 도메인 지원이 필요하면 Pages 루트 도메인의 모든 하위 도메인이 Pages 데몬에 전용된 보조 IP를 가리켜야 합니다. 이 구성 없이는 사용자가 `CNAME` 레코드를 사용하여 [사용자 정의 도메인](#custom-domains)을 GitLab Pages로 가리킬 수 없습니다.

예를 들어:

```plaintext
example.com   1800 IN A    192.0.2.1
*.example.io. 1800 IN A    192.0.2.2
```

이 예에 포함된 것:

- `example.com`:  GitLab 도메인입니다.
- `example.io`:  GitLab Pages가 제공되는 도메인입니다.
- `192.0.2.1`:  GitLab 인스턴스의 기본 IP입니다.
- `192.0.2.2`:  GitLab Pages에 전용된 보조 IP입니다. 기본 IP와 달라야 합니다.

> [!note]
> GitLab 도메인을 사용하여 사용자 페이지를 제공하지 마세요. 자세한 내용은 [보안 섹션](#security)을 참조하세요.

## 구성 {#configuration}

GitLab Pages를 여러 가지 방법으로 설정할 수 있습니다. 다음 예제는 가장 간단한 설정부터 가장 고급 설정까지 나열되어 있습니다.

### 와일드카드 도메인 {#wildcard-domains-1}

이 구성은 GitLab Pages를 사용하기 위한 최소 설정이며 다른 모든 설정의 기초 역할을 합니다. 이 구성에서:

- NGINX는 GitLab Pages 데몬에 대한 모든 요청을 프록시합니다.
- GitLab Pages 데몬은 공개 인터넷에 직접 수신 대기하지 않습니다.

전제 조건:

- [와일드카드 DNS](#dns-configuration)를 구성했습니다.

와일드카드 도메인을 사용하도록 GitLab Pages를 구성하려면:

1. `/etc/gitlab/gitlab.rb`에서 GitLab Pages의 외부 URL을 설정합니다:

   ```ruby
   external_url "http://example.com" # external_url here is only for reference
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

결과 URL 스키마는 `http://<namespace>.example.io/<project_slug>`입니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [GitLab CE 및 EE용 GitLab Pages 활성화](https://youtu.be/dD8c7WNcc6s) 동영상을 참조하세요.
<!-- Video published on 2017-02-22 -->

### 단일 도메인 사이트 {#single-domain-sites-1}

{{< history >}}

- [GitLab 16.7에서](https://gitlab.com/gitlab-org/gitlab/-/issues/17584) [실험으로](../../policy/development_stages_support.md) 도입되었습니다.
- GitLab 16.11에서 [베타](../../policy/development_stages_support.md) 로 [전환](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621)되었습니다.
- GitLab 17.2에서 [구현이](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111) NGINX에서 GitLab Pages 코드베이스로 변경되었습니다.
- GitLab 17.4에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)되었습니다.

{{< /history >}}

이 구성은 단일 도메인 사이트를 사용하기 위한 최소 설정이며 다른 모든 단일 도메인 설정의 기초 역할을 합니다. 이 구성에서:

- NGINX는 GitLab Pages 데몬에 대한 모든 요청을 프록시합니다.
- GitLab Pages 데몬은 공개 인터넷에 직접 수신 대기하지 않습니다.

전제 조건:

- [단일 도메인 사이트](#dns-configuration-for-single-domain-sites)에 대해 DNS를 구성했습니다.

단일 도메인 사이트를 사용하도록 GitLab Pages를 구성하려면:

1. `/etc/gitlab/gitlab.rb`에서 GitLab Pages의 외부 URL을 설정하고 기능을 활성화합니다:

   ```ruby
   external_url "http://example.com" # Swap out this URL for your own
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com

   # Set this flag to enable this feature
   gitlab_pages['namespace_in_path'] = true
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

결과 URL 스키마는 `http://example.io/<namespace>/<project_slug>`입니다.

> [!warning]
> GitLab Pages는 한 번에 하나의 URL 스키마만 지원합니다: 와일드카드 도메인 또는 단일 도메인 사이트. `namespace_in_path`을 활성화하면 기존 GitLab Pages 웹사이트는 단일 도메인 사이트로만 액세스할 수 있습니다.

### TLS 지원을 포함한 와일드카드 도메인 {#wildcard-domains-with-tls-support}

NGINX는 모든 요청을 데몬으로 프록시합니다. Pages 데몬은 공인 인터넷에 수신 대기하지 않습니다.

인스턴스에 하나의 와일드카드만 할당할 수 있습니다.

전제 조건:

- [와일드카드 DNS](#dns-configuration)를 구성했습니다.
- TLS 인증서를 보유합니다. 와일드카드 인증서이거나 [요구 사항](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md#manually-add-ssltls-certificates)을 충족하는 다른 유형일 수 있습니다.

TLS 지원을 포함한 와일드카드 도메인을 구성하려면:

1. `*.example.io`의 와일드카드 TLS 인증서와 키를 `/etc/gitlab/ssl` 내에 배치합니다.
1. `/etc/gitlab/gitlab.rb`에서 다음 구성을 지정합니다:

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['redirect_http_to_https'] = true
   ```

1. 인증서 및 키의 이름이 `example.io.crt`과 `example.io.key`가 아니면 전체 경로를 추가합니다:

   ```ruby
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [액세스 제어](#access-control) 를 사용하는 경우 GitLab Pages [시스템 OAuth 응용 프로그램](../../integration/oauth_provider.md#create-an-instance-wide-application)의 리디렉션 URI를 HTTPS 프로토콜을 사용하도록 업데이트합니다.

결과 URL 스키마는 `https://<namespace>.example.io/<project_slug>`입니다.

> [!warning]
> GitLab Pages는 리디렉션 URI 변경 시 OAuth 응용 프로그램을 업데이트하지 않습니다. 재구성하기 전에 `/etc/gitlab/gitlab-secrets.json`에서 `gitlab_pages` 섹션을 제거한 다음 `gitlab-ctl reconfigure`을 실행합니다. 자세한 내용은 [GitLab Pages가 OAuth를 재생성하지 않음](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3947)을 참조하세요.

### TLS 지원이 있는 단일 도메인 사이트 {#single-domain-sites-with-tls-support}

{{< history >}}

- [GitLab 16.7에서](https://gitlab.com/gitlab-org/gitlab/-/issues/17584) [실험으로](../../policy/development_stages_support.md) 도입되었습니다.
- GitLab 16.11에서 [베타](../../policy/development_stages_support.md) 로 [전환](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621)되었습니다.
- GitLab 17.2에서 [구현이](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111) NGINX에서 GitLab Pages 코드베이스로 변경되었습니다.
- GitLab 17.4에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)되었습니다.

{{< /history >}}

이 구성에서 NGINX는 데몬에 대한 모든 요청을 프록시합니다. GitLab Pages 데몬은 공개 인터넷에 수신 대기하지 않습니다.

전제 조건:

- [단일 도메인 사이트](#dns-configuration-for-single-domain-sites)에 대해 DNS를 구성했습니다.
- 도메인을 포함하는 TLS 인증서를 보유합니다(예: `example.io`).

TLS 지원이 있는 단일 도메인 사이트를 구성하려면:

1. TLS 인증서와 키를 `/etc/gitlab/ssl`에 추가합니다.
1. `/etc/gitlab/gitlab.rb`에서 GitLab Pages의 외부 URL을 설정하고 기능을 활성화합니다:

   ```ruby
   external_url "https://example.com" # Swap out this URL for your own
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['redirect_http_to_https'] = true

   # Set this flag to enable this feature
   gitlab_pages['namespace_in_path'] = true
   ```

1. TLS 인증서 또는 키 파일의 이름이 `example.io.crt`과 `example.io.key`가 아니면 전체 경로를 추가합니다:

   ```ruby
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

1. [액세스 제어](#access-control) 를 사용하는 경우 GitLab Pages [시스템 OAuth 응용 프로그램](../../integration/oauth_provider.md#create-an-instance-wide-application)의 리디렉션 URI를 HTTPS 프로토콜을 사용하도록 업데이트합니다.

   > [!note]
   > GitLab Pages는 OAuth 응용 프로그램을 업데이트하지 않으며 기본 `auth_redirect_uri`이 `https://example.io/projects/auth`으로 업데이트됩니다. 재구성하기 전에 `gitlab_pages`에서 `/etc/gitlab/gitlab-secrets.json` 섹션을 제거한 다음 `gitlab-ctl reconfigure`을 실행합니다. 자세한 내용은 [GitLab Pages가 OAuth를 재생성하지 않음](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3947)을 참조하세요.

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

결과 URL 스키마는 `https://example.io/<namespace>/<project_slug>`입니다.

> [!warning]
> GitLab Pages는 한 번에 하나의 URL 스키마만 지원합니다: 와일드카드 도메인 또는 단일 도메인 사이트. `namespace_in_path`을 활성화하면 기존 GitLab Pages 웹사이트는 단일 도메인 사이트로만 액세스할 수 있습니다.

### TLS 종료 로드 밸런서가 있는 와일드카드 도메인 {#wildcard-domains-with-tls-terminating-load-balancer}

Amazon Web Services에 [GitLab POC를 설치](../../install/aws/_index.md)할 때 이 설정을 사용합니다. 이 설정에는 HTTPS 연결을 수신 대기하고, TLS 인증서를 관리하며, HTTP 트래픽을 인스턴스로 전달하는 TLS 종료 [클래식 로드 밸런서](../../install/aws/_index.md#load-balancer)가 포함됩니다.

전제 조건:

- [와일드카드 DNS](#dns-configuration)를 구성했습니다.
- TLS 종료 로드 밸런서입니다.

TLS 종료 로드 밸런서가 있는 와일드카드 도메인을 구성하려면:

1. `/etc/gitlab/gitlab.rb`에서 다음 구성을 지정합니다:

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['enable'] = true
   pages_nginx['listen_port'] = 80
   pages_nginx['listen_https'] = false
   pages_nginx['redirect_http_to_https'] = true
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

결과 URL 스키마는 `https://<namespace>.example.io/<project_slug>`입니다.

### 전역 설정 {#global-settings}

다음 표는 Linux 패키지 설치에서 Pages에 알려진 모든 구성 설정을 설명합니다. 이러한 옵션은 `/etc/gitlab/gitlab.rb`에서 조정할 수 있으며 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation) 후에 적용됩니다.

이러한 설정 중 대부분은 Pages 데몬이 실행되는 방식과 사용자 환경에서 콘텐츠를 제공하는 방식을 보다 세밀하게 제어해야 하는 경우를 제외하고는 수동으로 구성할 필요가 없습니다.

| 설정                                 | 기본값                                               | 설명 |
|-----------------------------------------|-------------------------------------------------------|-------------|
| `pages_external_url` <sup>1</sup>       | 해당 없음                                        | GitLab Pages가 액세스 가능한 URL(프로토콜 HTTP/HTTPS 포함). `https://`을 사용하면 추가 구성이 필요합니다. 자세한 내용은 [TLS 지원이 있는 와일드카드 도메인](#wildcard-domains-with-tls-support) 및 [TLS 지원이 있는 사용자 정의 도메인](#custom-domains-with-tls-support)을 참조하세요. |
| **`gitlab_pages[]`**                    | 해당 없음                                        |             |
| `access_control`                        | 해당 없음                                        | [액세스 제어](_index.md#access-control) 활성화 여부. |
| `api_secret_key`                        | 자동 생성됨                                        | GitLab API로 인증하는 데 사용되는 비밀 키가 있는 파일의 전체 경로. |
| `artifacts_server`                      | 해당 없음                                        | GitLab Pages에서 [작업 아티팩트](../cicd/job_artifacts.md) 보기 활성화. |
| `artifacts_server_timeout`              | 해당 없음                                        | 아티팩트 서버에 대한 프록시 요청의 시간 초과(초 단위). |
| `artifacts_server_url`                  | GitLab `external URL` + `/api/v4`                     | 예를 들어 `https://gitlab.com/api/v4`으로 아티팩트 요청을 프록시할 API URL. 별도 Pages 서버를 실행할 때 이 URL은 기본 GitLab 서버의 API를 가리켜야 합니다. |
| `auth_redirect_uri`                     | `pages_external_url`의 프로젝트 하위 도메인 + `/auth` | GitLab으로 인증하기 위한 콜백 URL. URL은 `pages_external_url` + `/auth`의 하위 도메인이어야 하며, 예를 들어 `https://projects.example.io/auth`입니다. `namespace_in_path`이 활성화되면 `pages_external_url` + `/projects/auth`으로 기본값이 설정되며, 예를 들어 `https://example.io/projects/auth`입니다. |
| `auth_secret`                           | GitLab에서 자동으로 끌어옴                               | 인증 요청에 서명하기 위한 비밀 키. OAuth 등록 중에 GitLab에서 자동으로 끌어오도록 비워 둡니다. |
| `client_cert`                           | 해당 없음                                        | GitLab API와의 [상호 TLS](#support-mutual-tls-when-calling-the-gitlab-api)에 사용되는 클라이언트 인증서. |
| `client_key`                            | 해당 없음                                        | GitLab API와의 [상호 TLS](#support-mutual-tls-when-calling-the-gitlab-api)에 사용되는 클라이언트 키. |
| `client_ca_certs`                       | 해당 없음                                        | GitLab API와의 [상호 TLS](#support-mutual-tls-when-calling-the-gitlab-api)에 사용되는 클라이언트 인증서 서명에 사용되는 루트 CA 인증서. |
| `dir`                                   | 해당 없음                                        | 구성 및 비밀 파일의 작업 디렉터리. |
| `enable`                                | 해당 없음                                        | 현재 시스템에서 GitLab Pages를 활성화하거나 비활성화합니다. |
| `external_http`                         | 해당 없음                                        | Pages를 HTTP 요청을 처리하는 하나 이상의 보조 IP 주소에 바인딩하도록 구성합니다. 여러 주소는 배열로 정확한 포트와 함께 제공될 수 있습니다(예: `['1.2.3.4', '1.2.3.5:8063']`). `listen_http`의 값을 설정합니다. TLS 종료를 사용하여 로드 밸런서 뒤에서 GitLab Pages를 실행하는 경우 `external_http` 대신 `listen_proxy`을 지정합니다. |
| `external_https`                        | 해당 없음                                        | Pages를 HTTPS 요청을 처리하는 하나 이상의 보조 IP 주소에 바인딩하도록 구성합니다. 여러 주소는 배열로 정확한 포트와 함께 제공될 수 있습니다(예: `['1.2.3.4', '1.2.3.5:8063']`). `listen_https`의 값을 설정합니다. |
| `custom_domain_mode`                    | 해당 없음                                        | Pages를 사용자 정의 도메인을 활성화하도록 구성합니다: `http` 또는 `https`. 별도 Pages 서버를 실행할 때 GitLab 서버에서도 이 설정을 구성합니다. GitLab 18.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/285089)되었습니다. |
| `server_shutdown_timeout`               | `30s`                                                 | GitLab Pages 서버 종료 시간 초과(초 단위). |
| `gitlab_client_http_timeout`            | `60s`                                                 | GitLab API HTTP 클라이언트 연결 시간 초과(초 단위). |
| `gitlab_client_jwt_expiry`              | `30s`                                                 | JWT 토큰 만료 시간(초 단위). |
| `gitlab_cache_expiry`                   | `600s`                                                | 도메인 구성이 [캐시](#gitlab-api-cache-configuration)에 저장되는 최대 시간. |
| `gitlab_cache_refresh`                  | `60s`                                                 | 도메인 구성을 새로고칠 예정인 간격. |
| `gitlab_cache_cleanup`                  | `60s`                                                 | 만료된 항목이 [캐시](#gitlab-api-cache-configuration)에서 제거되는 간격. |
| `gitlab_retrieval_timeout`              | `30s`                                                 | GitLab API의 응답을 대기하는 최대 시간(요청당). |
| `gitlab_retrieval_interval`             | `1s`                                                  | GitLab API를 사용하여 도메인 구성을 다시 해석하기 전에 대기할 간격. |
| `gitlab_retrieval_retries`              | `3`                                                   | GitLab API를 사용하여 도메인 구성을 다시 해석하려고 시도할 최대 횟수. |
| `gitlab_id`                             | 자동 채우기됨                                           | OAuth 응용 프로그램 공개 ID. Pages가 GitLab으로 인증할 때 자동으로 채우도록 비워 둡니다. |
| `gitlab_secret`                         | 자동 채우기됨                                           | OAuth 응용 프로그램 비밀. Pages가 GitLab으로 인증할 때 자동으로 채우도록 비워 둡니다. |
| `auth_scope`                            | `api`                                                 | 인증에 사용할 OAuth 응용 프로그램 범위. GitLab Pages OAuth 응용 프로그램 설정과 일치해야 합니다. 기본적으로 `api` 범위를 사용하려면 비워 둡니다. |
| `auth_timeout`                          | `5s`                                                  | 인증용 GitLab 응용 프로그램 클라이언트 시간 초과(초 단위). `0` 값은 시간 초과가 없음을 의미합니다. |
| `auth_cookie_session_timeout`           | `10m`                                                 | 인증 쿠키 세션 시간 초과(초 단위). `0` 값은 브라우저 세션이 끝난 후 쿠키가 삭제됨을 의미합니다. |
| `gitlab_server`                         | GitLab `external_url`                                 | 액세스 제어가 활성화될 때 인증에 사용할 서버. |
| `headers`                               | 해당 없음                                        | 각 응답과 함께 클라이언트에게 전송되어야 하는 추가 HTTP 헤더를 지정합니다. 여러 헤더는 배열로 제공될 수 있으며 헤더와 값은 하나의 문자열로 제공됩니다. 예를 들어 `['my-header: myvalue', 'my-other-header: my-other-value']`. |
| `enable_disk`                           | 해당 없음                                        | GitLab Pages 데몬이 디스크에서 콘텐츠를 제공하도록 허용합니다. 공유 디스크 스토리지가 없으면 비활성화합니다. |
| `insecure_ciphers`                      | 해당 없음                                        | 3DES 및 RC4와 같은 안전하지 않은 것들을 포함할 수 있는 기본 암호 스위트 목록을 사용합니다. |
| `internal_gitlab_server`                | GitLab `external_url`                                 | API 요청 전용으로 사용되는 내부 GitLab 서버 주소. 해당 트래픽을 내부 로드 밸런서를 통해 전송하려면 사용합니다. |
| `listen_proxy`                          | 해당 없음                                        | 역 프록시 요청을 수신 대기할 주소. Pages는 이러한 주소의 네트워크 소켓에 바인딩하고 이들로부터 들어오는 요청을 수신합니다. `$nginx-dir/conf/gitlab-pages.conf`에서 `proxy_pass`의 값을 설정합니다. |
| `log_directory`                         | 해당 없음                                        | 로그 디렉터리의 절대 경로. |
| `log_format`                            | 해당 없음                                        | 로그 출력 형식: `text` 또는 `json`. |
| `log_verbose`                           | 해당 없음                                        | 자세한 로깅, true/false. |
| `namespace_in_path`                     | `false`                                               | 단일 도메인 사이트 DNS 설정을 지원하기 위해 URL 경로에서 네임스페이스를 활성화하거나 비활성화합니다. |
| `propagate_correlation_id`              | `false`                                               | 있으면 들어오는 요청 헤더 `X-Request-ID`에서 기존 상관 ID를 다시 사용하도록 true로 설정합니다. 역 프록시가 이 헤더를 설정하면 값이 요청 체인에 전파됩니다. |
| `max_connections`                       | 해당 없음                                        | HTTP, HTTPS 또는 프록시 리스너에 대한 동시 연결 수 제한. |
| `max_uri_length`                        | `2048`                                                | GitLab Pages에서 허용하는 URI의 최대 길이. 무제한 길이로 0으로 설정합니다. |
| `metrics_address`                       | 해당 없음                                        | 메트릭 요청을 수신 대기할 주소. |
| `redirect_http`                         | 해당 없음                                        | HTTP에서 HTTPS로 페이지 리디렉션, true/false. |
| `redirects_max_config_size`             | `65536`                                               | `_redirects` 파일의 최대 크기(바이트). |
| `redirects_max_path_segments`           | `25`                                                  | `_redirects` 규칙 URL에서 허용되는 경로 세그먼트의 최대 개수. |
| `redirects_max_rule_count`              | `1000`                                                | `_redirects`에서 허용되는 규칙의 최대 개수. |
| `sentry_dsn`                            | 해당 없음                                        | Sentry 충돌 보고를 보낼 주소. |
| `sentry_enabled`                        | 해당 없음                                        | Sentry를 통한 보고 및 로깅 활성화, true/false. |
| `sentry_environment`                    | 해당 없음                                        | Sentry 충돌 보고를 위한 환경. |
| `status_uri`                            | 해당 없음                                        | 예를 들어 상태 페이지의 URL 경로 `/@status`. GitLab Pages에서 상태 확인 끝점을 활성화하도록 구성합니다. |
| `tls_max_version`                       | 해당 없음                                        | 최대 TLS 버전("tls1.2" 또는 "tls1.3")을 지정합니다. |
| `tls_min_version`                       | 해당 없음                                        | 최소 TLS 버전("tls1.2" 또는 "tls1.3")을 지정합니다. |
| `use_http2`                             | 해당 없음                                        | HTTP2 지원을 활성화합니다. |
| **`gitlab_pages['env'][]`**             | 해당 없음                                        |             |
| `http_proxy`                            | 해당 없음                                        | Pages와 GitLab 간의 트래픽을 중재하도록 GitLab Pages를 HTTP 프록시를 사용하도록 구성합니다. Pages 데몬을 시작할 때 환경 변수 `http_proxy`을 설정합니다. |
| **`gitlab_rails[]`**                    | 해당 없음                                        |             |
| `pages_domain_verification_cron_worker` | 해당 없음                                        | 사용자 정의 GitLab Pages 도메인을 확인하기 위한 일정. |
| `pages_domain_ssl_renewal_cron_worker`  | 해당 없음                                        | GitLab Pages 도메인에 대해 Let's Encrypt를 통해 SSL 인증서를 획득하고 갱신하기 위한 일정. |
| `pages_domain_removal_cron_worker`      | 해당 없음                                        | 확인되지 않은 사용자 정의 GitLab Pages 도메인을 제거하기 위한 일정. |
| `pages_path`                            | `GITLAB-RAILS/shared/pages`                           | 페이지가 저장되는 디스크의 디렉터리. |
| **`pages_nginx[]`**                     | 해당 없음                                        |             |
| `enable`                                | 해당 없음                                        | NGINX 내 Pages에 대한 가상 호스트 `server{}` 블록을 포함합니다. NGINX에서 Pages 데몬에 트래픽을 프록시하는 데 필요합니다. Pages 데몬이 모든 요청을 직접 수신해야 하는 경우(예: [사용자 정의 도메인](_index.md#custom-domains) 사용 시) `false`로 설정합니다. |
| `FF_CONFIGURABLE_ROOT_DIR`              | 해당 없음                                        | [기본 폴더 사용자 정의](../../user/project/pages/introduction.md#customize-the-default-folder)에 대한 기능 플래그(기본적으로 활성화). |
| `FF_ENABLE_PLACEHOLDERS`                | 해당 없음                                        | 다시 쓰기에 대한 기능 플래그(기본적으로 활성화). 자세한 내용은 [다시 쓰기](../../user/project/pages/redirects.md#rewrites)를 참조하세요. |
| `rate_limit_source_ip`                  | 해당 없음                                        | 소스 IP당 요청 수의 속도 제한(초당). 이 기능을 비활성화하려면 `0`로 설정합니다. |
| `rate_limit_source_ip_burst`            | 해당 없음                                        | 소스 IP당 최대 버스트(초당). |
| `rate_limit_domain`                     | 해당 없음                                        | 도메인당 요청 수의 속도 제한(초당). 이 기능을 비활성화하려면 `0`로 설정합니다. |
| `rate_limit_domain_burst`               | 해당 없음                                        | 도메인당 최대 버스트(초당). |
| `rate_limit_tls_source_ip`              | 해당 없음                                        | 소스 IP당 TLS 연결 수의 속도 제한(초당). 이 기능을 비활성화하려면 `0`로 설정합니다. |
| `rate_limit_tls_source_ip_burst`        | 해당 없음                                        | 소스 IP당 최대 TLS 연결 버스트(초당). |
| `rate_limit_tls_domain`                 | 해당 없음                                        | 도메인당 TLS 연결 수의 속도 제한(초당). 이 기능을 비활성화하려면 `0`로 설정합니다. |
| `rate_limit_tls_domain_burst`           | 해당 없음                                        | 도메인당 최대 TLS 연결 버스트(초당). |
| `rate_limit_subnets_allow_list`         | 해당 없음                                        | 모든 속도 제한을 무시해야 하는 IP 범위(서브넷)의 허용 목록. 예를 들어, `['1.2.3.4/24', '2001:db8::1/32']`. GitLab 17.3에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/14653)되었습니다. |
| `server_read_timeout`                   | `5s`                                                  | 요청 헤더 및 본문을 읽을 최대 기간. 시간 초과가 없으려면 `0` 또는 음수 값으로 설정합니다. |
| `server_read_header_timeout`            | `1s`                                                  | 요청 헤더를 읽을 최대 기간. 시간 초과가 없으려면 `0` 또는 음수 값으로 설정합니다. |
| `server_write_timeout`                  | `0`                                                   | 응답의 모든 파일을 쓸 최대 기간. 더 큰 파일은 더 많은 시간이 필요합니다. 시간 초과가 없으려면 `0` 또는 음수 값으로 설정합니다. |
| `server_keep_alive`                     | `15s`                                                 | 이 리스너에서 수락한 네트워크 연결의 `Keep-Alive` 기간. `0`인 경우 프로토콜 및 운영 체제에서 지원하면 `Keep-Alive`이 활성화됩니다. 음수인 경우 `Keep-Alive`이 비활성화됩니다. |

**각주**:

1. 외부 Sidekiq 노드를 사용하는 경우 구성에 `pages_external_url`을 추가해야 합니다. 이 설정 없이는 외부 Sidekiq 노드가 배포 작업을 처리할 수 없습니다.

## 고급 구성 {#advanced-configuration}

와일드카드 도메인 외에도 사용자 지정 도메인으로 작동하도록 GitLab Pages를 구성할 수 있으며, TLS 인증서가 있거나 없을 수 있습니다. 어느 경우든 **secondary IP**가 필요합니다. IPv6 및 IPv4 주소가 모두 있으면 둘 다 사용할 수 있습니다.

### 사용자 지정 도메인 {#custom-domains}

기본적으로 GitLab Pages 사이트는 Pages 루트 도메인의 하위 도메인에서 제공됩니다(예: `namespace.example.io/project`). Pages 사이트에 대한 사용자 정의 도메인을 구성하려면 자신의 도메인(예: `example-custom-site-here.com`)을 GitLab Pages로 가리키는 CNAME DNS 레코드를 추가합니다.

기본 `*.example.io` 하위 도메인 URL만 필요한 경우 사용자 정의 도메인 지원을 구성할 필요가 없습니다.

이 구성에서 Pages 데몬이 실행 중이고 NGINX가 요청을 프록시하지만 데몬은 공인 인터넷의 요청도 받을 수 있습니다. 사용자 지정 도메인은 TLS 없이 지원됩니다.

전제 조건:

- [와일드카드 DNS](#dns-configuration)를 구성했습니다.
- 보조 IP입니다.

사용자 지정 도메인을 구성하려면:

1. `/etc/gitlab/gitlab.rb`에서 다음 구성을 지정합니다:

   ```ruby
   external_url "http://example.com" # external_url here is only for reference
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['custom_domain_mode'] = 'http' # Enable custom domain
   ```

   IPv6이 없으면 IPv6 주소를 생략합니다.

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

결과 URL 스키마는 `http://<namespace>.example.io/<project_slug>` 및 `http://custom-domain.com`입니다.

### TLS 지원을 포함한 사용자 지정 도메인 {#custom-domains-with-tls-support}

이 구성에서 Pages 데몬이 실행 중이고 NGINX가 요청을 프록시하지만 데몬은 공인 인터넷의 요청도 받을 수 있습니다. 사용자 지정 도메인 및 TLS가 지원됩니다.

전제 조건:

- [와일드카드 DNS](#dns-configuration)를 구성했습니다.
- TLS 인증서입니다. 와일드카드 인증서이거나 [요구 사항](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md#manually-add-ssltls-certificates)을 충족하는 다른 유형일 수 있습니다.
- 보조 IP입니다.

TLS 지원을 포함한 사용자 지정 도메인을 구성하려면:

1. `*.example.io`의 와일드카드 TLS 인증서와 키를 `/etc/gitlab/ssl` 내에 배치합니다.
1. `/etc/gitlab/gitlab.rb`에서 다음 구성을 지정합니다:

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['external_https'] = ['192.0.2.2:443', '[2001:db8::2]:443'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['custom_domain_mode'] = 'https' # Enable custom domain
   # Redirect pages from HTTP to HTTPS
   gitlab_pages['redirect_http'] = true
   ```

   IPv6이 없으면 IPv6 주소를 생략합니다.

1. 인증서 및 키의 이름이 `example.io.crt`과 `example.io.key`가 아니면 전체 경로를 추가합니다:

   ```ruby
   gitlab_pages['cert'] = "/etc/gitlab/ssl/example.io.crt"
   gitlab_pages['cert_key'] = "/etc/gitlab/ssl/example.io.key"
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. 액세스 제어를 사용하는 경우 GitLab Pages [시스템 OAuth 응용 프로그램](../../integration/oauth_provider.md#create-an-instance-wide-application)의 리디렉션 URI를 편집하여 HTTPS 프로토콜을 사용하도록 합니다.

### 사용자 정의 도메인 확인 {#custom-domain-verification}

악의적인 사용자가 속하지 않은 도메인을 탈취하는 것을 방지하기 위해 GitLab은 [사용자 정의 도메인 확인](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md)을 지원합니다. 사용자 정의 도메인을 추가할 때 사용자는 GitLab 제어 확인 코드를 해당 도메인의 DNS 레코드에 추가하여 소유권을 증명해야 합니다.

> [!warning]
> 도메인 확인을 비활성화하는 것은 안전하지 않으며 다양한 취약점을 초래할 수 있습니다. 비활성화하는 경우 Pages 루트 도메인 자체가 보조 IP를 가리키지 않거나 루트 도메인을 프로젝트에 사용자 정의 도메인으로 추가하는지 확인하세요. 그렇지 않으면 모든 사용자가 이 도메인을 자신의 프로젝트에 사용자 정의 도메인으로 추가할 수 있습니다.

사용자 기반이 프라이빗이거나 신뢰할 수 있는 경우 확인 요구 사항을 비활성화할 수 있습니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Pages**를 확장합니다.
1. **사용자가 사용자 정의 도메인의 소유권을 증명하도록 요구** 확인란을 선택 해제합니다. 이 설정은 기본적으로 활성화됩니다.

### Let's Encrypt 통합 {#lets-encrypt-integration}

[GitLab Pages' Let's Encrypt 통합](../../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)을 통해 사용자는 사용자 정의 도메인에서 제공되는 GitLab Pages 사이트에 Let's Encrypt SSL 인증서를 추가할 수 있습니다.

사용하도록 설정하려면:

1. 만료되는 도메인에 대한 알림을 받을 이메일 주소를 선택합니다.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Pages**를 확장합니다.
1. 알림 수신 이메일 주소를 입력하고 Let's Encrypt의 서비스 약관에 동의합니다.
1. **변경 사항 저장**을 선택합니다.

### 액세스 제어 {#access-control}

GitLab Pages 액세스 제어는 프로젝트별로 구성할 수 있으며 사용자의 프로젝트 멤버십에 따라 Pages 사이트에 대한 액세스를 제어할 수 있습니다.

액세스 제어는 Pages 데몬을 GitLab과 함께 OAuth 애플리케이션으로 등록하여 작동합니다. 인증되지 않은 사용자가 비공개 Pages 사이트에 액세스를 요청할 때마다 Pages 데몬은 사용자를 GitLab으로 리디렉션합니다. 인증이 성공하면 사용자는 쿠키에 지속되는 토큰과 함께 Pages로 다시 리디렉션됩니다. 쿠키는 비밀 키로 서명되므로 변조를 감지할 수 있습니다.

비공개 사이트의 리소스를 보기 위한 각 요청은 해당 토큰을 사용하여 Pages에 의해 인증됩니다. 수신하는 각 요청에 대해 Pages는 GitLab API에 요청하여 사용자가 해당 사이트를 읽을 권한이 있는지 확인합니다.

Pages 액세스 제어는 기본적으로 사용하지 않도록 설정됩니다. 사용하도록 설정하려면:

1. `/etc/gitlab/gitlab.rb`에서 추가합니다:

   ```ruby
   gitlab_pages['access_control'] = true
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. 사용자는 이제 [프로젝트 설정](../../user/project/pages/pages_access_control.md)에서 구성할 수 있습니다.

> [!note]
> 멀티 노드 설정에서 이 설정을 효과적으로 만들려면 모든 App 노드 및 Sidekiq 노드에 적용하세요.

#### 감소된 인증 범위로 Pages 사용 {#using-pages-with-reduced-authentication-scope}

Pages 데몬이 인증에 사용하는 범위를 구성할 수 있습니다. 기본적으로 `api` 범위를 사용합니다.

예를 들어 이것은 `/etc/gitlab/gitlab.rb`에서 범위를 `read_api`로 줄입니다:

```ruby
gitlab_pages['auth_scope'] = 'read_api'
```

인증에 사용할 범위는 GitLab Pages OAuth 응용 프로그램 설정과 일치해야 합니다. 기존 응용 프로그램의 사용자는 GitLab Pages OAuth 응용 프로그램을 수정해야 합니다.

전제 조건:

- [액세스 제어](#access-control)를 활성화했습니다.

Pages에서 사용하는 범위를 변경하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **응용 프로그램**을 선택합니다.
1. **GitLab 페이지**를 확장합니다.
1. `api` 범위의 확인란을 선택 해제하고 원하는 범위의 확인란을 선택합니다(예: `read_api`).
1. **변경 사항 저장**을 선택합니다.

#### 모든 Pages 사이트에 대한 공개 액세스 비활성화 {#disable-public-access-to-all-pages-sites}

GitLab 인스턴스에서 호스팅되는 모든 GitLab Pages 웹사이트에 액세스 제어를 적용할 수 있습니다. 이 설정을 활성화하면 인증된 사용자만 Pages 웹사이트에 액세스할 수 있습니다. 모든 프로젝트는 **모두** 가시성 수준 옵션을 잃고 프로젝트의 가시성 설정에 따라 프로젝트 멤버 또는 액세스 권한이 있는 모든 사용자로 제한됩니다.

이 설정을 사용하여 Pages로 게시된 정보를 인스턴스의 사용자에게만 제한합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스.
- 액세스 제어가 활성화되어 설정이 관리자 영역에 표시되도록 합니다.

모든 Pages 사이트에 대한 공개 액세스를 비활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Pages**를 확장합니다.
1. **Pages 사이트에 대한 공개 액세스 비활성화** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

#### 기본값으로 고유한 도메인 비활성화 {#disable-unique-domains-by-default}

{{< history >}}

- GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/555559)되었습니다.

{{< /history >}}

기본적으로 새로 생성된 모든 GitLab Pages 사이트는 고유한 도메인 URL(예: `my-project-1a2b3c.example.com`)을 사용하므로 동일한 네임스페이스 아래의 서로 다른 사이트 간에 쿠키 공유를 방지합니다.

이 기본 동작을 비활성화하여 새 Pages 사이트가 경로 기반 URL(예: `my-namespace.example.com/my-project`)을 대신 사용하도록 할 수 있습니다. 그러나 이 접근 방식은 동일한 네임스페이스 아래의 서로 다른 사이트 간에 쿠키 공유의 위험이 있습니다.

이 설정은 새 사이트에만 기본 동작을 제어합니다. 사용자는 여전히 개별 프로젝트에 대해 이 설정을 재정의할 수 있습니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스가 있어야 합니다.

기본값으로 고유한 도메인을 비활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Pages**를 확장합니다.
1. **기본값으로 고유한 도메인 활성화** 확인란을 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

이 설정은 새 Pages 사이트에만 영향을 미칩니다. 기존 사이트는 현재 고유한 도메인 구성을 유지합니다.

### 프록시 뒤에서 실행 {#running-behind-a-proxy}

외부 인터넷 연결이 프록시에 의해 제어되는 환경에서 GitLab Pages를 사용할 수 있습니다.

GitLab Pages에 프록시를 사용하려면:

1. `/etc/gitlab/gitlab.rb`에서 추가합니다:

   ```ruby
   gitlab_pages['env']['http_proxy'] = 'http://example:8080'
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

### 사용자 정의 인증 기관(CA) 사용 {#using-a-custom-certificate-authority-ca}

사용자 정의 CA에서 발급한 인증서를 사용할 때 사용자 정의 CA가 인식되지 않으면 액세스 제어 및 [HTML 작업 아티팩트의 온라인 보기](../../ci/jobs/job_artifacts.md#download-job-artifacts)가 작동하지 않습니다.

이는 일반적으로 다음 오류를 발생시킵니다:

```plaintext
Post /oauth/token: x509: certificate signed by unknown authority
```

이를 해결하려면:

- Linux 패키지 설치의 경우 [사용자 정의 CA 설치](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates).
- 자체 컴파일 설치의 경우 시스템 인증서 저장소에 사용자 정의 CA를 설치합니다.

### GitLab API를 호출할 때 상호 TLS 지원 {#support-mutual-tls-when-calling-the-gitlab-api}

{{< history >}}

- GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/548)되었습니다.

{{< /history >}}

GitLab이 [상호 TLS를 요구하도록 구성](https://docs.gitlab.com/omnibus/settings/ssl/#enable-2-way-ssl-client-authentication)된 경우 GitLab Pages 구성에 클라이언트 인증서를 추가해야 합니다.

인증서의 요구 사항:

- 인증서는 주체 대체 이름으로 호스트 이름 또는 IP 주소를 지정해야 합니다.
- 최종 사용자 인증서, 중간 인증서 및 루트 인증서를 포함한 전체 인증서 체인이 필요하며 이 순서로 필요합니다.

인증서의 일반 이름 필드는 무시됩니다.

전제 조건:

- 인스턴스는 Linux 패키지 설치 방법을 사용합니다.

GitLab Pages 서버에서 인증서를 구성하려면:

1. GitLab Pages 노드에서 `/etc/gitlab/ssl` 디렉터리를 만들고 키와 전체 인증서 체인을 복사합니다:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_pages['client_cert'] = ['/etc/gitlab/ssl/cert.pem']
   gitlab_pages['client_key'] = ['/etc/gitlab/ssl/key.pem']
   ```

1. 사용자 정의 CA를 사용한 경우 루트 CA 인증서를 `/etc/gitlab/ssl`에 복사하고 `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_pages['client_ca_certs'] = ['/etc/gitlab/ssl/ca.pem']
   ```

   여러 사용자 정의 인증 기관의 파일 경로는 쉼표로 구분됩니다.

1. 멀티 노드 GitLab Pages 설치가 있는 경우 모든 노드에서 이 단계를 반복합니다.
1. 전체 인증서 체인 파일의 사본을 모든 GitLab 노드의 `/etc/gitlab/trusted-certs` 디렉터리에 저장합니다.

### ZIP 제공 및 캐시 구성 {#zip-serving-and-cache-configuration}

> [!warning]
> 권장되는 기본값은 GitLab Pages 내에 설정됩니다. 절대적으로 필요한 경우에만 이 설정을 변경합니다.

GitLab Pages는 객체 스토리지를 통해 ZIP 아카이브에서 콘텐츠를 제공할 수 있습니다. ZIP 아카이브에서 콘텐츠를 제공할 때 성능을 향상시키기 위해 메모리 내 캐시를 사용합니다. 다음 구성 플래그를 변경하여 캐시 동작을 수정할 수 있습니다.

| 설정 | 설명 |
| ------- | ----------- |
| `zip_cache_expiration` | ZIP 아카이브의 캐시 만료 간격입니다. 부실 콘텐츠 제공을 방지하려면 0보다 커야 합니다. 기본값은 `60s`입니다. |
| `zip_cache_cleanup` | 아카이브가 만료된 후 메모리에서 정리되는 간격입니다. 기본값은 `30s`입니다. |
| `zip_cache_refresh` | `zip_cache_expiration` 이전에 액세스되는 경우 메모리에서 아카이브가 연장되는 시간 간격입니다. `zip_cache_expiration`와 함께 작동하여 아카이브가 메모리에서 연장되는지 여부를 결정합니다. 자세한 내용은 [ZIP 캐시 새로 고침 예제](#zip-cache-refresh-example)를 참조하세요. 기본값은 `30s`입니다. |
| `zip_open_timeout` | ZIP 아카이브를 열 수 있는 최대 시간입니다. 큰 아카이브 또는 느린 네트워크 연결의 경우 이 값을 증가시키세요. 기본값은 `30s`입니다. |
| `zip_http_client_timeout` | ZIP HTTP 클라이언트의 최대 시간입니다. 기본값은 `30m`입니다. |

#### ZIP 캐시 새로 고침 예제 {#zip-cache-refresh-example}

`zip_cache_expiration` 이전에 액세스되고 만료 전 남은 시간이 `zip_cache_refresh` 이하인 경우 아카이브가 캐시에서 새로 고쳐집니다(메모리에서 보유하는 시간을 연장함). 예를 들어 `archive.zip`이 시간 `0s`에 액세스되면 `60s`에서 만료됩니다(`zip_cache_expiration`의 기본값). 아카이브가 `15s` 후에 다시 열리면 남은 만료 시간(`45s`)이 `zip_cache_refresh`(기본값 `30s`)보다 크기 때문에 새로 고쳐지지 않습니다. 그러나 아카이브가 (처음 열린 이후) `45s` 후에 다시 액세스되면 새로 고쳐집니다. 이렇게 하면 아카이브가 메모리에 유지되는 시간이 `45s + zip_cache_expiration
(60s)`에서 총 `105s`로 연장됩니다.

아카이브가 `zip_cache_expiration`에 도달한 후에는 만료된 것으로 표시되고 다음 `zip_cache_cleanup` 간격에 제거됩니다.

![타임라인은 ZIP 캐시 새로 고침이 ZIP 캐시 만료 시간을 연장하는 것을 보여줍니다.](img/zip_cache_configuration_v13_7.png)

### HTTP Strict Transport Security(HSTS) 지원 {#http-strict-transport-security-hsts-support}

HTTP Strict Transport Security(HSTS)는 `gitlab_pages['headers']` 구성 옵션을 통해 활성화할 수 있습니다. HSTS는 브라우저에 웹 사이트를 항상 HTTPS를 통해 액세스해야 함을 알려주어 공격자가 암호화되지 않은 연결을 강제하는 것을 방지합니다. 또한 브라우저가 HTTPS로 리디렉션되기 전에 암호화되지 않은 HTTP 연결을 시도하는 것을 방지하여 페이지 로딩 속도를 향상시킬 수 있습니다.

```ruby
gitlab_pages['headers'] = ['Strict-Transport-Security: max-age=63072000']
```

### Pages 프로젝트 리디렉션 제한 {#pages-project-redirect-limits}

GitLab Pages는 성능 영향을 최소화하기 위해 [`_redirects` 파일](../../user/project/pages/redirects.md)에 대한 기본 제한을 가지고 있습니다.

제한을 조정하려면:

```ruby
gitlab_pages['redirects_max_config_size'] = 131072
gitlab_pages['redirects_max_path_segments'] = 50
gitlab_pages['redirects_max_rule_count'] = 2000
```

## 환경 변수 사용 {#use-environment-variables}

Pages 데몬에 환경 변수를 전달하여 기능 플래그를 활성화 또는 비활성화할 수 있습니다.

구성 가능한 디렉토리 기능을 비활성화하려면:

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_pages['env'] = {
     'FF_CONFIGURABLE_ROOT_DIR' => "false"
   }
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

## 데몬에 대한 자세한 로깅 활성화 {#activate-verbose-logging-for-daemon}

GitLab Pages 데몬의 자세한 로깅을 구성하려면:

1. 기본적으로 데몬은 `INFO` 수준으로만 로깅합니다. `DEBUG` 수준의 이벤트를 로깅하려면 `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   gitlab_pages['log_verbose'] = true
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

## 상관 ID 전파 {#propagating-the-correlation-id}

`propagate_correlation_id`을 `true`로 설정하면 리버스 프록시 뒤에 있는 설치에서 GitLab Pages로 전송된 요청에 대해 상관 ID를 생성하고 설정할 수 있습니다. 리버스 프록시가 헤더 값 `X-Request-ID`을 설정하면 값이 요청 체인에 전파됩니다. 사용자는 [로그에서 상관 ID를 찾을](../logs/tracing_correlation_id.md#identify-the-correlation-id-for-a-request) 수 있습니다.

상관 ID의 전파를 활성화하려면:

1. `/etc/gitlab/gitlab.rb`에서 추가합니다:

   ```ruby
   gitlab_pages['propagate_correlation_id'] = true
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

## 저장소 경로 변경 {#change-storage-path}

GitLab Pages 콘텐츠가 저장된 기본 경로를 변경하려면:

1. Pages는 기본적으로 `/var/opt/gitlab/gitlab-rails/shared/pages`에 저장됩니다. 다른 위치를 사용하려면 `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   gitlab_rails['pages_path'] = "/mnt/storage/pages"
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

## 리버스 프록시 요청에 대한 수신기 구성 {#configure-listener-for-reverse-proxy-requests}

GitLab Pages의 프록시 수신기를 구성하려면:

1. 기본적으로 수신기는 `localhost:8090`에서 요청을 수신하도록 구성됩니다.

   비활성화하려면 `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   gitlab_pages['listen_proxy'] = nil
   ```

   포트를 변경하려면 `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   gitlab_pages['listen_proxy'] = "localhost:10080"
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

## 각 GitLab Pages 사이트의 전역 최대 크기 설정 {#set-global-maximum-size-of-each-gitlab-pages-site}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

전제 조건:

- 인스턴스에 대한 관리자 액세스가 있어야 합니다.

프로젝트의 전역 최대 Pages 크기를 설정하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Pages**를 확장합니다.
1. **Maximum size of pages**에 값을 입력하세요. 기본값은 `100`입니다.
1. **변경 사항 저장**을 선택합니다.

## 그룹의 각 GitLab Pages 사이트의 최대 크기 설정 {#set-maximum-size-of-each-gitlab-pages-site-in-a-group}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

전제 조건:

- 인스턴스에 대한 관리자 액세스가 있어야 합니다.

상속된 설정을 재정의하여 그룹의 각 GitLab Pages 사이트의 최대 크기를 설정하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾으세요.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택하세요.
1. **Pages**를 확장합니다.
1. **Maximum size** 아래에 MB 단위로 값을 입력하세요.
1. **변경 사항 저장**을 선택합니다.

## 프로젝트의 GitLab Pages 사이트의 최대 크기 설정 {#set-maximum-size-of-gitlab-pages-site-in-a-project}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

전제 조건:

- 인스턴스에 대한 관리자 액세스가 있어야 합니다.

상속된 설정을 재정의하여 프로젝트의 GitLab Pages 사이트의 최대 크기를 설정하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **배포** > **Pages**를 선택하세요.
1. **Maximum size of pages**에 MB 단위로 크기를 입력하세요.
1. **변경 사항 저장**을 선택합니다.

## 프로젝트의 GitLab Pages 커스텀 도메인의 최대 개수 설정 {#set-maximum-number-of-gitlab-pages-custom-domains-for-a-project}

전제 조건:

- 인스턴스에 대한 관리자 액세스가 있어야 합니다.

프로젝트의 GitLab Pages 커스텀 도메인의 최대 개수를 설정하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Pages**를 확장합니다.
1. **프로젝트당 최대 커스텀 도메인 수**에 값을 입력하세요. 무제한 도메인의 경우 `0`를 사용하세요.
1. **변경 사항 저장**을 선택합니다.

## 병렬 배포에 대한 기본 만료 구성 {#configure-the-default-expiry-for-parallel-deployments}

{{< history >}}

- [GitLab 17.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/456477).

{{< /history >}}

전제 조건:

- 인스턴스에 대한 관리자 액세스.

[병렬 배포](../../user/project/pages/_index.md#parallel-deployments)가 삭제된 후의 기본 기간을 구성하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Pages**를 확장합니다.
1. **Default expiration for parallel deployments in seconds**에 값을 입력하세요. 병렬 배포가 기본적으로 만료되지 않아야 하는 경우 `0`를 사용하세요.
1. **변경 사항 저장**을 선택합니다.

## GitLab Pages 웹 사이트당 최대 파일 개수 설정 {#set-maximum-number-of-files-per-gitlab-pages-website}

파일 항목(디렉토리 및 심볼릭 링크 포함)의 총 개수는 각 GitLab Pages 웹 사이트에 대해 `200,000`로 제한됩니다.

[GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 사용하여 GitLab Self-Managed 인스턴스에서 제한을 업데이트할 수 있습니다.

자세한 내용은 [GitLab 애플리케이션 제한](../instance_limits.md#number-of-files-per-gitlab-pages-website)을 참조하세요.

## 별도 서버에서 GitLab Pages 실행 {#running-gitlab-pages-on-a-separate-server}

GitLab Pages 데몬을 별도 서버에서 실행하여 주 애플리케이션 서버의 부하를 줄일 수 있습니다.

> [!warning]
> 다음 절차에는 `gitlab-secrets.json` 파일을 백업 및 편집하는 단계가 포함됩니다. 이 파일에는 데이터베이스 암호화를 제어하는 비밀이 포함되어 있습니다. 주의 깊게 진행하세요.

별도 서버에서 GitLab Pages를 구성하려면:

1. 선택사항. 액세스 제어를 활성화하려면 다음을 `/etc/gitlab/gitlab.rb`에 추가하고 [**GitLab server**를 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요:

   > [!warning]
   > GitLab Pages를 액세스 제어와 함께 사용할 계획이라면 `gitlab-secrets.json`을 복사하기 전에 GitLab 서버에서 활성화하세요. 액세스 제어를 활성화하면 새 OAuth 애플리케이션이 생성되고 그에 대한 정보가 `gitlab-secrets.json`으로 전파됩니다. 이것이 올바른 순서로 수행되지 않으면 액세스 제어에서 문제가 발생할 수 있습니다.

   ```ruby
   gitlab_pages['access_control'] = true
   ```

1. **GitLab server**에서 비밀 파일의 백업을 만드세요:

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. **GitLab server**에서 Pages를 활성화하려면 `/etc/gitlab/gitlab.rb`에 다음을 추가하세요:

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   ```

1. 다음 중 하나를 선택하여 객체 스토리지를 설정하세요:
   - [객체 스토리지를 구성하고 GitLab Pages 데이터를 마이그레이션](#object-storage-settings)합니다.
   - [네트워크 스토리지 구성](#enable-pages-network-storage-in-multi-node-environments)합니다.
1. 변경 사항을 적용하려면 [**GitLab server**를 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요. `gitlab-secrets.json` 파일이 이제 새 구성으로 업데이트되었습니다.
1. 새 서버를 설정하세요. 이것이 **Pages server**가 됩니다.
1. **Pages server**에서 Linux 패키지를 사용하여 GitLab을 설치하고 `/etc/gitlab/gitlab.rb`를 수정하여 다음을 포함하세요:

   ```ruby
   roles ['pages_role']

   pages_external_url "http://<pages_server_URL>"

   gitlab_pages['gitlab_server'] = 'http://<gitlab_server_IP_or_URL>'

   ## If access control was enabled
   gitlab_pages['access_control'] = true
   ```

1. **GitLab server**에 커스텀 UID/GID 설정이 있는 경우 **Pages server** `/etc/gitlab/gitlab.rb`에도 추가하세요. 그렇지 않으면 **GitLab server**에서 `gitlab-ctl reconfigure`를 실행하면 파일 소유권이 변경되고 Pages 요청이 실패할 수 있습니다.

1. **Pages server**에서 비밀 파일의 백업을 만드세요:

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. 개별 GitLab Pages 사이트에 대한 커스텀 도메인을 활성화하려면 **Pages server**를 다음 중 하나를 사용하여 설정하세요:

   - [커스텀 도메인](#custom-domains).
   - [TLS 지원이 있는 커스텀 도메인](#custom-domains-with-tls-support).

1. `/etc/gitlab/gitlab-secrets.json` 파일을 **GitLab server**에서 **Pages server**로 복사하세요:

   ```shell
   # On the GitLab server
   cp /etc/gitlab/gitlab-secrets.json /mnt/pages/gitlab-secrets.json

   # On the Pages server
   mv /var/opt/gitlab/gitlab-rails/shared/pages/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json
   ```

1. 변경 사항을 적용하려면 [**Pages server**를 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.
1. **GitLab server**에서 `/etc/gitlab/gitlab.rb`에 다음을 변경하세요:

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   gitlab_pages['enable'] = false
   pages_nginx['enable'] = false
   ```

1. **GitLab server**에서 개별 GitLab Pages 사이트에 대한 커스텀 도메인을 활성화하려면 `/etc/gitlab/gitlab.rb`를 다음과 같이 변경하세요:

   - 커스텀 도메인:

     ```ruby
        gitlab_pages['custom_domain_mode'] = 'http'
     ```

   - TLS 지원이 있는 커스텀 도메인:

     ```ruby
        gitlab_pages['custom_domain_mode'] = 'https'
     ```

1. 변경 사항을 적용하려면 [**GitLab server**를 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.

로드를 분산하려면 DNS 서버를 구성하여 여러 IP를 반환하거나 IP 수준 로드 밸런서를 사용하는 등의 표준 로드 밸런싱 방법을 사용하여 여러 서버에서 GitLab Pages를 실행할 수 있습니다. 여러 서버에서 GitLab Pages를 설정하려면 각 Pages 서버에 대해 이전 절차를 반복하세요.

## 도메인 소스 구성 {#domain-source-configuration}

GitLab Pages 데몬이 요청을 처리할 때 먼저 요청된 URL을 제공해야 하는 프로젝트와 해당 콘텐츠가 저장되는 방식을 식별합니다.

기본적으로 GitLab Pages는 새 도메인이 요청될 때마다 내부 GitLab API를 사용합니다. Pages가 API에 연결할 수 없으면 시작하지 못합니다. 도메인 정보는 또한 Pages 데몬에 의해 캐시되어 후속 요청의 속도를 높입니다.

일반적인 문제는 [문제 해결 섹션](troubleshooting.md#failed-to-connect-to-the-internal-gitlab-api)을 참조하세요.

### GitLab API 캐시 구성 {#gitlab-api-cache-configuration}

API 기반 구성은 성능과 안정성을 개선하기 위해 캐싱 메커니즘을 사용합니다. 다음 설정을 변경하여 캐시 동작을 수정할 수 있지만 권장 기본값은 필요한 경우에만 변경해야 합니다. 잘못된 구성으로 인해 간헐적이거나 지속적인 오류가 발생하거나 Pages 데몬이 부실 콘텐츠를 제공할 수 있습니다.

> [!note]
> 만료, 간격 및 시간 초과 플래그는 [Go 기간 형식](https://pkg.go.dev/time#ParseDuration)을 사용합니다. 기간 문자열은 `300ms`, `1.5h` 또는 `2h45m`와 같이 선택적 분수와 단위 접미사가 포함된 가능한 부호가 있는 십진수 시퀀스입니다. 유효한 시간 단위는 `ns`, `us` (또는 `µs`), `ms`, `s`, `m`, `h`입니다.

예:

- `gitlab_cache_expiry`을 증가시키면 항목이 캐시에 더 오래 존재할 수 있습니다. GitLab Pages와 GitLab Rails 간의 통신이 안정적이지 않으면 이 설정을 사용하세요.
- `gitlab_cache_refresh`을 증가시키면 GitLab Pages가 GitLab Rails에서 도메인의 구성을 요청하는 빈도가 줄어듭니다. GitLab Pages가 GitLab API에 너무 많은 요청을 생성하고 콘텐츠가 자주 변경되지 않으면 이 설정을 사용하세요.
- `gitlab_cache_cleanup`을 감소시키면 캐시에서 만료된 항목이 더 자주 제거되어 Pages 노드의 메모리 사용량을 줄입니다.
- `gitlab_retrieval_timeout`을 감소시키면 GitLab Rails에 대한 요청이 더 빨리 중지됩니다. 이를 증가시키면 API로부터 응답을 받을 수 있는 시간이 더 많이 허용됩니다. 느린 네트워크 환경의 경우 이 설정을 사용하세요.
- `gitlab_retrieval_interval`을 감소시키면 연결 시간 초과와 같은 API로부터의 오류 응답이 있을 때만 API에 대한 요청을 더 자주 하게 됩니다.
- `gitlab_retrieval_retries`을 감소시키면 오류를 보고하기 전에 도메인의 구성을 재시도하는 횟수가 줄어듭니다.

## 객체 스토리지 설정 {#object-storage-settings}

다음 [객체 스토리지](../object_storage.md) 설정:

- 자체 컴파일 설치의 경우 `pages:` 다음 `object_store:` 아래에 중첩됩니다.
- Linux 패키지 설치의 경우 `pages_object_store_`로 접두사됩니다.

| 설정 | 설명 | 기본값 |
|---------|-------------|---------|
| `enabled` | 객체 스토리지 활성화 여부입니다. | `false` |
| `remote_directory` | Pages 사이트 콘텐츠가 저장되는 버킷의 이름입니다. | |
| `connection` | 아래에 설명된 다양한 연결 옵션입니다. | |

> [!note]
> NFS 서버 사용을 중지하고 연결을 해제하려면 [명시적으로 로컬 스토리지를 비활성화](#disable-pages-local-storage)해야 합니다.

### S3 호환 연결 설정 {#s3-compatible-connection-settings}

[통합 객체 스토리지 설정](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을 사용해야 합니다.

[다양한 공급자를 위한 사용 가능한 연결 설정](../object_storage.md#configure-the-connection-settings)을 참조하세요.

### Pages 배포를 객체 스토리지로 마이그레이션 {#migrate-pages-deployments-to-object-storage}

기존 Pages 배포 객체(ZIP 아카이브)는 로컬 스토리지 또는 객체 스토리지에 저장할 수 있습니다.

기존 Pages 배포를 로컬 스토리지에서 객체 스토리지로 마이그레이션하려면:

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_object_storage
```

[PostgreSQL 콘솔](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database)을 사용하여 진행 상황을 추적하고 모든 Pages 배포가 성공적으로 마이그레이션되었는지 확인할 수 있습니다:

- Linux 패키지 설치의 경우 `sudo gitlab-rails dbconsole --database main`.
- 자체 컴파일 설치의 경우 `sudo -u git -H psql -d gitlabhq_production`.

`objectstg` (여기서 `store=2`)이 모든 Pages 배포의 개수를 가지고 있는지 확인하세요:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM pages_deployments;

total | filesystem | objectstg
------+------------+-----------
   10 |          0 |        10
```

모든 것이 제대로 작동하는지 확인한 후 [Pages 로컬 스토리지를 비활성화](#disable-pages-local-storage)하세요.

### Pages 배포를 로컬 스토리지로 롤백 {#rolling-pages-deployments-back-to-local-storage}

객체 스토리지로 마이그레이션한 후 Pages 배포를 로컬 스토리지로 다시 이동할 수 있습니다:

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_local
```

### Pages 로컬 스토리지 비활성화 {#disable-pages-local-storage}

객체 스토리지를 사용하면 불필요한 디스크 사용량이나 쓰기를 피하기 위해 로컬 스토리지를 비활성화할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_rails['pages_local_store_enabled'] = false
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

## 다중 노드 환경에서 Pages 네트워크 스토리지 활성화 {#enable-pages-network-storage-in-multi-node-environments}

객체 스토리지는 대부분의 환경에서 선호되는 구성입니다. 그러나 네트워크 스토리지가 필요하고 Pages를 [별도 서버](#running-gitlab-pages-on-a-separate-server)에서 실행하도록 구성하려는 경우 다음을 수행해야 합니다:

1. 공유 스토리지 볼륨이 이미 마운트되어 있고 주 서버와 의도한 Pages 서버 모두에서 사용 가능한지 확인하세요.
1. 각 노드의 `/etc/gitlab/gitlab.rb`을 업데이트하여 다음을 포함하세요:

   ```ruby
   gitlab_pages['enable_disk'] = true
   gitlab_rails['pages_path'] = "/var/opt/gitlab/gitlab-rails/shared/pages" # Path to your network storage
   ```

1. 별도 서버로 Pages를 전환하세요.

별도 서버에서 Pages를 성공적으로 구성한 후에는 해당 서버만 공유 스토리지 볼륨에 액세스해야 합니다. 단일 노드 환경으로 다시 마이그레이션해야 하는 경우를 대비하여 주 서버에 공유 스토리지 볼륨을 마운트된 상태로 유지하는 것을 고려하세요.

## ZIP 스토리지 {#zip-storage}

GitLab Pages의 기본 스토리지 형식은 프로젝트당 단일 ZIP 아카이브입니다. 이 아카이브는 로컬에 또는 [객체 스토리지](#object-storage-settings)에 저장할 수 있습니다. Pages 사이트가 업데이트될 때마다 새 아카이브가 저장됩니다.

## 백업 {#backup}

GitLab Pages는 [정기 백업](../backup_restore/_index.md)의 일부이므로 별도의 백업을 구성할 필요가 없습니다.

## 보안 {#security}

XSS 공격을 방지하기 위해 GitLab과 다른 호스트명 아래에서 GitLab Pages를 실행하는 것을 강력히 권장합니다.

### 속도 제한 {#rate-limits}

{{< history >}}

- GitLab 17.3에서 [변경됨](https://gitlab.com/groups/gitlab-org/-/epics/14653):  Pages 속도 제한에서 서브넷을 제외할 수 있습니다.

{{< /history >}}

서비스 거부(DoS) 공격의 위험을 최소화하는 데 도움이 되도록 속도 제한을 적용할 수 있습니다. GitLab Pages는 토큰 버킷 알고리즘을 사용하여 속도 제한을 적용합니다. 기본적으로 지정된 제한을 초과하는 요청 또는 TLS 연결은 보고되고 거부됩니다.

GitLab Pages는 다음 유형의 속도 제한을 지원합니다:

- 각 `source_ip`에 대해:  단일 클라이언트 IP 주소에서 요청 또는 TLS 연결을 제한합니다.
- 각 `domain`에 대해:  GitLab Pages에 호스팅된 도메인당 요청 또는 TLS 연결을 제한합니다. 이것은 `example.com`와 같은 커스텀 도메인 또는 `group.gitlab.io`과 같은 그룹 도메인일 수 있습니다.

HTTP 요청 기반 속도 제한은 다음 설정을 사용하여 적용됩니다:

- `rate_limit_source_ip`:  클라이언트 IP당 초당 최대 요청 수입니다. 비활성화하려면 `0`로 설정하세요.
- `rate_limit_source_ip_burst`:  클라이언트 IP당 초기 버스트에서 허용되는 최대 요청 수(예: 페이지가 여러 리소스를 동시에 로드할 때)입니다.
- `rate_limit_domain`:  호스팅된 Pages 도메인당 초당 최대 요청 수입니다. 비활성화하려면 `0`로 설정하세요.
- `rate_limit_domain_burst`:  호스팅된 Pages 도메인당 초기 버스트에서 허용되는 최대 요청 수입니다.

TLS 연결 기반 속도 제한은 다음 설정을 사용하여 적용됩니다:

- `rate_limit_tls_source_ip`:  클라이언트 IP당 초당 최대 TLS 연결 수입니다. 비활성화하려면 `0`로 설정하세요.
- `rate_limit_tls_source_ip_burst`:  클라이언트 IP당 초기 버스트에서 허용되는 최대 TLS 연결 수입니다.
- `rate_limit_tls_domain`:  호스팅된 Pages 도메인당 초당 최대 TLS 연결 수입니다. 비활성화하려면 `0`로 설정하세요.
- `rate_limit_tls_domain_burst`:  호스팅된 Pages 도메인당 초기 버스트에서 허용되는 최대 TLS 연결 수입니다.

특정 IP 범위(서브넷)가 모든 속도 제한을 우회할 수 있도록 하려면 `rate_limit_subnets_allow_list`을 사용하세요. 예를 들어, `['1.2.3.4/24', '2001:db8::1/32']`. [예제 GitLab Pages 차트](https://docs.gitlab.com/charts/charts/gitlab/gitlab-pages/#configure-rate-limits-subnets-allow-list)를 사용할 수 있습니다.

클라이언트의 IP 주소가 IPv6인 경우 제한은 전체 주소가 아닌 길이 64인 IPv6 접두사에 적용됩니다.

#### 소스 IP별로 HTTP 요청 속도 제한 활성화 {#enable-http-requests-rate-limits-by-source-ip}

`/etc/gitlab/gitlab.rb`에서 속도 제한을 설정하려면:

1. 다음을 추가하세요:

   ```ruby
   gitlab_pages['rate_limit_source_ip'] = 20.0
   gitlab_pages['rate_limit_source_ip_burst'] = 600
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

#### 도메인별로 HTTP 요청 속도 제한 활성화 {#enable-http-requests-rate-limits-by-domain}

`/etc/gitlab/gitlab.rb`에서 속도 제한을 설정하려면:

1. 다음을 추가하세요:

   ```ruby
   gitlab_pages['rate_limit_domain'] = 1000
   gitlab_pages['rate_limit_domain_burst'] = 5000
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

#### 소스 IP별로 TLS 연결 속도 제한 활성화 {#enable-tls-connections-rate-limits-by-source-ip}

`/etc/gitlab/gitlab.rb`에서 속도 제한을 설정하려면:

1. 다음을 추가하세요:

   ```ruby
   gitlab_pages['rate_limit_tls_source_ip'] = 20.0
   gitlab_pages['rate_limit_tls_source_ip_burst'] = 600
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

#### 도메인별로 TLS 연결 속도 제한 활성화 {#enable-tls-connections-rate-limits-by-domain}

`/etc/gitlab/gitlab.rb`에서 속도 제한을 설정하려면:

1. 다음을 추가하세요:

   ```ruby
   gitlab_pages['rate_limit_tls_domain'] = 1000
   gitlab_pages['rate_limit_tls_domain_burst'] = 5000
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 재구성하세요](../restart_gitlab.md#reconfigure-a-linux-package-installation).

## 관련 항목 {#related-topics}

- [GitLab Pages 관리 문제 해결](troubleshooting.md)
- [GitLab Pages 사용자 문서](../../user/project/pages/_index.md)
- [커스텀 도메인 및 SSL/TLS 인증서](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md)
- [Pages 액세스 제어](../../user/project/pages/pages_access_control.md)
- [작업 아티팩트](../cicd/job_artifacts.md)
- [OAuth 공급자 통합](../../integration/oauth_provider.md)
- [GitLab 애플리케이션 제한](../instance_limits.md#number-of-files-per-gitlab-pages-website)
- [객체 스토리지](../object_storage.md)
- [병렬 배포](../../user/project/pages/_index.md#parallel-deployments)
- [기본 폴더 사용자 정의](../../user/project/pages/introduction.md#customize-the-default-folder)
- [Pages 리디렉션](../../user/project/pages/redirects.md)
