---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 웹 IDE에서 VS Code 확장 및 웹 보기를 격리하는 데 사용되는 와일드카드 도메인 표시
title: 웹 IDE 확장 호스트 도메인
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

확장 호스트 도메인은 [확장 마켓플레이스](../../user/project/web_ide/_index.md#manage-extensions)를 사용하여 설치된 타사 코드를 격리하기 위해 웹 IDE에서 사용하는 와일드카드 도메인 이름입니다. 웹 IDE는 웹 브라우저의 [동일 출처](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy) 정책을 사용하여 샌드박스 환경에서 확장을 실행합니다.

GitLab은 기본적으로 모든 GitLab 제공 서비스에서 사용 가능한 기본 확장 호스트 도메인 `*.cdn.web-ide.gitlab-static.net`을 제공합니다. 이 와일드카드 도메인은 VS Code 정적 자산을 호스팅하는 외부 HTTP 서버를 가리킵니다. 각 확장은 자신의 서브도메인에서 제공됩니다. 오프라인 환경에서는 사용자의 웹 브라우저가 이 외부 HTTP 서버에 연결할 수 없으므로 웹 IDE의 기능이 제한됩니다.

이 제한을 우회하기 위해 GitLab 인스턴스 관리자는 사용자 정의 확장 호스트 도메인을 설정할 수 있습니다. 사용자 정의 확장 호스트 도메인은 기본 솔루션처럼 VS Code 정적 자산도 제공할 수 있는 GitLab 인스턴스 자체를 가리킵니다.

> [!warning]
> 웹 IDE 확장 호스트 도메인에서 지나치게 광범위한 와일드카드 도메인을 구성하면 심각한 보안 위험이 발생합니다. 잘못된 구성으로 인해 GitLab 인스턴스 및 모든 관련 데이터가 손상될 수 있습니다.

## 사용자 정의 확장 호스트 도메인 설정 {#set-up-custom-extension-host-domain}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

이 지침은 기본 NGINX 설치를 사용하는 [Linux 패키지 설치](../../install/package/_index.md)를 위한 것입니다. GitLab 관리자 및 DevOps 엔지니어는 이 가이드를 다른 설치 방법에 맞게 조정해야 합니다.

1. [NGINX 구성에 사용자 정의 설정 삽입](https://docs.gitlab.com/omnibus/settings/nginx/#insert-custom-settings-into-the-nginx-configuration) 가이드를 따르고 `server` 블록을 추가합니다. 이 블록은 확장 호스트 도메인에 대한 요청을 처리하도록 NGINX를 구성합니다. 다음 코드 스니펫은 참조 구성을 제공합니다. `<extension-host-domain-placeholder>`을 웹 IDE 확장 호스트 도메인의 와일드카드 도메인 이름으로 바꿉니다:

   ```nginx
   server {
     listen *:443 ssl;
     server_name *.<extension-host-domain-placeholder>;

     ssl_certificate /etc/gitlab/ssl/<extension-host-domain-placeholder>.pem;
     ssl_certificate_key /etc/gitlab/ssl/<extension-host-domain-placeholder>-key.pem;

     ## Individual nginx logs for this GitLab vhost
     access_log  /var/log/gitlab/nginx/gitlab_access.log gitlab_access;
     error_log   /var/log/gitlab/nginx/gitlab_error.log;

     location /assets/ {
       client_max_body_size 0;
       gzip off;

       proxy_read_timeout      300;
       proxy_connect_timeout   300;
       proxy_redirect          off;

       proxy_http_version 1.1;

       proxy_set_header    Host                $http_host;
       proxy_set_header    X-Real-IP           $remote_addr;
       proxy_set_header    X-Forwarded-For     $remote_addr;
       proxy_set_header    X-Forwarded-Proto   $scheme;

       proxy_pass http://gitlab-workhorse;
     }
   }
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다. 그런 다음 GitLab 애플리케이션을 엽니다.
1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **웹 IDE**를 확장합니다.
1. **확장 호스트 도메인** 텍스트 상자에 사용자 정의 확장 호스트 도메인을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

변경 사항을 저장한 후 웹 IDE에서 프로젝트를 열어 사용자 정의 확장 호스트가 편집기에서 사용되는지 확인할 수 있습니다.

## 단일 오리진 폴백 {#single-origin-fallback}

> [!warning]
> 단일 오리진 폴백은 기본적으로 활성화되어 있으며 보안 위험이 있습니다. 폴백을 비활성화해야 하며, 대신 확장 호스트 도메인이 CORS 구성, 웹 브라우저 보안 정책 또는 프록시 서버에 의해 차단되지 않도록 해야 합니다.

기본적으로 웹 IDE는 다중 오리진 모드에서 실행되며, 별도의 확장 호스트 도메인에서 VS Code 정적 자산을 제공합니다. 이 격리는 악의적인 행위자가 확장 호스트를 악용하여 GitLab 인스턴스에 인증된 요청을 하는 것을 방지합니다.

그러나 네트워크 또는 CORS 제한으로 인해 확장 호스트 도메인에 도달할 수 없는 경우 웹 IDE는 자동으로 단일 오리진 모드로 폴백됩니다. 이 모드에서 WebIDE는 GitLab 애플리케이션과 동일한 오리진에서 VS Code 자산을 제공하므로 공격 표면이 증가하고 보안 취약점이 생성됩니다.

**단일 오리진 폴백 활성화** 설정은 확장 호스트 도메인에 도달할 수 없을 때 웹 IDE가 단일 오리진 모드로 폴백할 수 있는지 여부를 제어합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

이 설정을 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **웹 IDE**를 확장합니다.
1. **단일 오리진 폴백 활성화** 확인란을 선택하거나 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.
