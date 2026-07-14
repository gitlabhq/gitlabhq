---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: GitLab Self-Managed와 PlantUML 통합을 구성합니다.
title: PlantUML
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[PlantUML](https://plantuml.com) 통합을 사용하여 스니펫, 위키 및 리포지토리에서 다이어그램을 만듭니다. GitLab.com은 모든 사용자를 위해 PlantUML과 통합되며 추가 구성이 필요하지 않습니다.

GitLab Self-Managed 인스턴스에서 통합을 설정하려면 [PlantUML 서버를 구성](#configure-your-plantuml-server)해야 합니다.

통합을 완료하면 PlantUML이 `plantuml` 블록을 HTML 이미지 태그로 변환하며, 소스는 PlantUML 인스턴스를 가리킵니다. PlantUML 다이어그램 구분 기호 `@startuml`/`@enduml`는 필수가 아닙니다. `plantuml` 블록으로 대체되기 때문입니다:

- `.md` 확장자를 가진 Markdown 파일:

  ````markdown
  ```plantuml
  Bob -> Alice : hello
  Alice -> Bob : hi
  ```
  ````

  추가 허용 가능한 확장자를 보려면 [`languages.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/vendor/languages.yml#L3174) 파일을 검토하세요.

- `.asciidoc`, `.adoc`, 또는 `.asc` 확장자를 가진 AsciiDoc 파일:

  ```plaintext
  [plantuml, format="png", id="myDiagram", width="200px"]
  ----
  Bob->Alice : hello
  Alice -> Bob : hi
  ----
  ```

- reStructuredText:

  ```plaintext
  .. plantuml::
     :caption: Caption with **bold** and *italic*

     Bob -> Alice: hello
     Alice -> Bob: hi
  ```

   `uml::` 지시문을 사용할 수 있으며 [`sphinxcontrib-plantuml`](https://pypi.org/project/sphinxcontrib-plantuml/)과의 호환성을 위해 사용할 수 있지만, GitLab은 `caption` 옵션만 지원합니다.

PlantUML 서버가 올바르게 구성되면 이러한 예제는 코드 블록 대신 다이어그램을 렌더링해야 합니다:

```plantuml
Bob -> Alice : hello
Alice -> Bob : hi
```

블록 내에 PlantUML이 지원하는 다이어그램을 추가합니다. 예를 들어:

- [활동](https://plantuml.com/activity-diagram-legacy)
- [클래스](https://plantuml.com/class-diagram)
- [구성 요소](https://plantuml.com/component-diagram)
- [개체](https://plantuml.com/object-diagram)
- [시퀀스](https://plantuml.com/sequence-diagram)
- [상태](https://plantuml.com/state-diagram)
- [사용 사례](https://plantuml.com/use-case-diagram)

블록 정의에 매개변수를 추가합니다:

- `id`:  다이어그램 HTML 태그에 추가되는 CSS ID입니다.
- `width`:  이미지 태그에 추가되는 너비 속성입니다.
- `height`:  이미지 태그에 추가되는 높이 속성입니다.

Markdown은 매개변수를 지원하지 않으며 항상 PNG 형식을 사용합니다.

## 다이어그램 파일 포함 {#include-diagram-files}

리포지토리의 별도 파일에서 PlantUML 다이어그램을 포함하거나 포함하려면 `include` 지시문을 사용합니다. 이를 사용하여 복잡한 다이어그램을 전용 파일에서 유지 관리하거나 다이어그램을 재사용할 수 있습니다. 예를 들어:

- Markdown:

  ````markdown
  ```plantuml
  ::include{file=diagram.puml}
  ```
  ````

- AsciiDoc:

  ```plaintext
  [plantuml, format="png", id="myDiagram", width="200px"]
  ----
  include::diagram.puml[]
  ----
  ```

> [!note]
> `::include` 지시문은 파일이 리포지토리에 커밋된 후에만 해결됩니다. Markdown 편집기 미리 보기는 포함된 파일을 렌더링하지 않습니다. 다이어그램이 올바르게 렌더링되는지 확인하려면 파일을 커밋하고 리포지토리 파일 브라우저에서 확인합니다.

## PlantUML 서버 구성 {#configure-your-plantuml-server}

GitLab에서 PlantUML을 활성화하기 전에 다이어그램을 생성하기 위해 자신의 PlantUML 서버를 설정해야 합니다:

- [Docker](#docker) (권장)
- [Debian/Ubuntu](#debianubuntu)

### Docker {#docker}

Docker에서 PlantUML 컨테이너를 실행하려면 다음 명령을 실행합니다:

```shell
docker run -d --name plantuml -p 8005:8080 plantuml/plantuml-server:tomcat
```

**PlantUML URL**은 컨테이너를 실행하는 서버의 호스트명입니다.

GitLab을 Docker에서 실행할 때는 PlantUML 컨테이너에 접근할 수 있어야 합니다. 이를 위해 [Docker Compose](https://docs.docker.com/compose/)를 사용합니다. 이 기본 `docker-compose.yml` 파일에서 PlantUML은 `http://plantuml:8080/` URL에서 GitLab에 접근할 수 있습니다:

```yaml
services:
  gitlab:
    image: 'gitlab/gitlab-ee:18.9.1-ee.0'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n    rewrite ^/-/plantuml/(.*) /$1 break;\n proxy_cache off; \n    proxy_pass  http://plantuml:8080/; \n}\n"

  plantuml:
    image: 'plantuml/plantuml-server:tomcat'
    container_name: plantuml
    ports:
     - "8005:8080"
```

다음을 수행할 수 있습니다:

1. [로컬 PlantUML 접근 구성](#configure-local-plantuml-access)
1. [PlantUML 설치 확인](#verify-the-plantuml-installation) 완료

### Debian/Ubuntu {#debianubuntu}

Debian/Ubuntu 배포판에서 Tomcat 또는 Jetty를 사용하여 PlantUML 서버를 설치하고 구성할 수 있습니다. 아래 지침은 Tomcat용입니다.

전제 조건:

- JRE/JDK 버전 11 이상.
- (권장) Jetty 버전 11 이상.
- (권장) Tomcat 버전 10 이상.

#### 설치 {#installation}

PlantUML은 Tomcat 10.1 이상을 설치할 것을 권장합니다. 이 페이지의 범위는 기본 Tomcat 서버 설정만 포함합니다. 더 많은 프로덕션 준비 구성은 [Tomcat 설명서](https://tomcat.apache.org/tomcat-10.1-doc/index.html)를 참조하세요.

1. JDK/JRE 11 설치:

   ```shell
   sudo apt update
   sudo apt install default-jre-headless graphviz git
   ```

1. Tomcat 사용자 추가:

   ```shell
   sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat
   ```

1. Tomcat 10.1 설치 및 구성:

   ```shell
   wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.33/bin/apache-tomcat-10.1.33.tar.gz -P /tmp
   sudo tar xzvf /tmp/apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1
   sudo chown -R tomcat:tomcat /opt/tomcat/
   sudo chmod -R u+x /opt/tomcat/bin
   ```

1. systemd 서비스를 만듭니다. `/etc/systemd/system/tomcat.service` 파일을 편집하고 다음을 추가합니다:

   ```shell
   [Unit]
   Description=Tomcat
   After=network.target

   [Service]
   Type=forking

   User=tomcat
   Group=tomcat

   Environment="JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64"
   Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
   Environment="CATALINA_BASE=/opt/tomcat"
   Environment="CATALINA_HOME=/opt/tomcat"
   Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
   Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

   ExecStart=/opt/tomcat/bin/startup.sh
   ExecStop=/opt/tomcat/bin/shutdown.sh

   RestartSec=10
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

   `JAVA_HOME`은 `sudo update-java-alternatives -l`에서 볼 수 있는 것과 동일한 경로여야 합니다.

1. 포트를 구성하려면 `/opt/tomcat/conf/server.xml`을 편집하고 포트를 선택합니다. 권장:

   - Tomcat 종료 포트를 `8005`에서 `8006`로 변경합니다.
   - `8005` 포트를 Tomcat HTTP 끝점에 사용합니다. 기본 포트 `8080`는 피해야 합니다. [Puma](../operations/puma.md)가 메트릭을 위해 `8080` 포트에서 수신하기 때문입니다.

   ```diff
   - <Server port="8006" shutdown="SHUTDOWN">
   + <Server port="8005" shutdown="SHUTDOWN">

   - <Connector port="8005" protocol="HTTP/1.1"
   + <Connector port="8080" protocol="HTTP/1.1"
   ```

1. Tomcat을 다시 로드하고 시작합니다:

   ```shell
   sudo systemctl daemon-reload
   sudo systemctl start tomcat
   sudo systemctl status tomcat
   sudo systemctl enable tomcat
   ```

   Java 프로세스는 다음 포트에서 수신해야 합니다:

   ```shell
   root@gitlab-omnibus:/plantuml-server# ❯ ss -plnt | grep java
   LISTEN   0        1          [::ffff:127.0.0.1]:8006                   *:*       users:(("java",pid=27338,fd=52))
   LISTEN   0        100                         *:8005                   *:*       users:(("java",pid=27338,fd=43))
   ```

1. PlantUML을 설치하고 `.war` 파일을 복사합니다:

   [최신 릴리스](https://github.com/plantuml/plantuml-server/releases) (`plantuml-jsp`)를 사용합니다. 예를 들어: `plantuml-jsp-v1.2024.8.war`. 컨텍스트는 [이슈 265](https://github.com/plantuml/plantuml-server/issues/265)를 참조하세요.

   ```shell
   wget -P /tmp https://github.com/plantuml/plantuml-server/releases/download/v1.2024.8/plantuml-jsp-v1.2024.8.war
   sudo cp /tmp/plantuml-jsp-v1.2024.8.war /opt/tomcat/webapps/plantuml.war
   sudo chown tomcat:tomcat /opt/tomcat/webapps/plantuml.war
   sudo systemctl restart tomcat
   ```

Tomcat 서비스가 다시 시작되어야 합니다. 다시 시작이 완료되면 PlantUML 통합이 준비되었으며 `8005` 포트에서 요청을 수신합니다. `http://localhost:8005/plantuml`.

Tomcat 기본값을 변경하려면 `/opt/tomcat/conf/server.xml` 파일을 편집합니다.

> [!note]
> 이 방식을 사용할 때 기본 URL이 다릅니다. Docker 기반 이미지는 상대 경로 없이 루트 URL에서 서비스를 사용할 수 있도록 합니다. 아래 구성을 적절히 조정하세요.

다음을 수행할 수 있습니다:

1. [로컬 PlantUML 접근 구성](#configure-local-plantuml-access). 링크에 구성된 `proxy_pass` 포트가 `server.xml`의 Connector 포트와 일치하는지 확인하세요.
1. [PlantUML 설치 확인](#verify-the-plantuml-installation) 완료.

### 로컬 PlantUML 접근 구성 {#configure-local-plantuml-access}

PlantUML 서버는 서버에서 로컬로 실행되므로 기본적으로 외부에서 접근할 수 없습니다. 서버는 `https://gitlab.example.com/-/plantuml/`에 대한 외부 PlantUML 호출을 포착하고 로컬 PlantUML 서버로 리디렉션해야 합니다. 설정에 따라 URL은 다음 중 하나입니다:

- `http://plantuml:8080/`
- `http://localhost:8080/plantuml/`
- `http://plantuml:8005/`
- `http://localhost:8005/plantuml/`

[TLS가 있는 GitLab](https://docs.gitlab.com/omnibus/settings/ssl/)을 실행 중인 경우 이 리디렉션을 구성해야 합니다. PlantUML은 안전하지 않은 HTTP 프로토콜을 사용하기 때문입니다. 최신 브라우저는 HTTPS를 통해 제공되는 페이지에서 안전하지 않은 HTTP 리소스를 로드하지 않습니다.

#### 번들 GitLab NGINX 사용 {#use-bundled-gitlab-nginx}

`/etc/gitlab/gitlab.rb`을 수정할 수 있는 경우 번들 NGINX를 구성하여 리디렉션을 처리합니다:

1. `/etc/gitlab/gitlab.rb`에 다음 줄을 추가합니다. 설정 방법에 따라 다릅니다:

   ```ruby
   # Docker install
   nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n  rewrite ^/-/plantuml/(.*) /$1 break;\n  proxy_cache off; \n    proxy_pass  http://plantuml:8005/; \n}\n"

   # Debian/Ubuntu install
   nginx['custom_gitlab_server_config'] = "location /-/plantuml/ { \n  rewrite ^/-/plantuml/(.*) /$1 break;\n  proxy_cache off; \n    proxy_pass  http://localhost:8005/plantuml; \n}\n"
   ```

1. 변경 사항을 활성화하려면 다음 명령을 실행합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

#### HTTPS PlantUML 서버 사용 {#use-https-plantuml-server}

`gitlab.rb` 파일을 수정할 수 없는 경우 PlantUML 서버를 직접 HTTPS를 사용하도록 구성합니다. 이 방법은 GitLab Dedicated 인스턴스에 권장됩니다.

이 설정은 NGINX를 사용하여 SSL 종료를 처리하고 PlantUML 컨테이너로 요청을 프록시합니다. SSL 종료를 위해 AWS Application Load Balancer (ALB)와 같은 클라우드 기반 로드 밸런서를 사용할 수도 있습니다.

1. `nginx.conf` 파일을 만듭니다:

   ```nginx
   events {
       worker_connections 1024;
   }

   http {
       server {
           listen 443 ssl;
           server_name _;
           ssl_certificate /etc/nginx/ssl/plantuml.crt;
           ssl_certificate_key /etc/nginx/ssl/plantuml.key;
           location / {
               proxy_pass http://plantuml:8080;
               proxy_set_header Host $host;
               proxy_set_header X-Real-IP $remote_addr;
               proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
               proxy_set_header X-Forwarded-Proto $scheme;
           }
       }
   }
   ```

1. `plantuml.crt` 및 `plantuml.key` 파일을 `ssl` 디렉터리에 추가합니다.
1. `docker-compose.yml` 파일을 구성합니다:

   ```yaml
   version: '3.8'

   services:
     plantuml:
       image: plantuml/plantuml-server:tomcat
       container_name: plantuml
       networks:
         - plantuml-net

     plantuml-ssl:
       image: nginx
       container_name: plantuml-ssl
       ports:
         - "8443:443"
       volumes:
         - ./nginx.conf:/etc/nginx/nginx.conf:ro
         - ./ssl:/etc/nginx/ssl:ro
       depends_on:
         - plantuml
       networks:
         - plantuml-net

   networks:
     plantuml-net:
       driver: bridge
   ```

1. `docker-compose up`로 PlantUML 서버를 시작합니다.
1. [PlantUML 통합 활성화](#enable-plantuml-integration) (`https://your-server:8443` URL 포함).

### PlantUML 설치 확인 {#verify-the-plantuml-installation}

설치가 성공했는지 확인하려면:

1. PlantUML 서버를 직접 테스트합니다:

   ```shell
   # Docker install
   curl --location --verbose "http://localhost:8005/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000"

   # Debian/Ubuntu install
   curl --location --verbose "http://localhost:8005/plantuml/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000"
   ```

   `hello` 텍스트가 포함된 SVG 출력을 받아야 합니다.

1. GitLab이 NGINX를 통해 PlantUML에 접근할 수 있는지 테스트합니다:

   ```plaintext
   http://gitlab.example.com/-/plantuml/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000
   ```

   `gitlab.example.com`을 GitLab 인스턴스 URL로 바꿉니다. `hello`을 표시하는 렌더링된 PlantUML 다이어그램이 표시되어야 합니다.

   ```plaintext
   Bob -> Alice : hello
   ```

### PlantUML 보안 구성 {#configure-plantuml-security}

PlantUML에는 네트워크 리소스를 가져올 수 있는 기능이 있습니다. PlantUML 서버를 자체 호스팅하는 경우 격리하기 위해 네트워크 제어를 설정합니다. 예를 들어 PlantUML의 [보안 프로필](https://plantuml.com/security)을 활용합니다.

```plaintext
@startuml
start
    ' ...
    !include http://localhost/
stop;
@enduml
```

#### PlantUML SVG 다이어그램 출력 보안 {#secure-plantuml-svg-diagram-output}

PlantUML 다이어그램을 SVG 형식으로 생성할 때 향상된 보안을 위해 서버를 구성합니다. 잠재적 보안 문제를 방지하기 위해 NGINX 구성에서 SVG 출력 경로를 비활성화합니다.

SVG 출력 경로를 비활성화하려면 PlantUML 서비스를 호스팅하는 NGINX 서버에 이 구성을 추가합니다:

```nginx
location ~ ^/-/plantuml/svg/ {
    return 403;
}
```

이 구성은 잠재적으로 악의적인 다이어그램 코드가 브라우저에서 실행되는 것을 방지합니다.

## PlantUML 통합 활성화 {#enable-plantuml-integration}

로컬 PlantUML 서버를 구성한 후 PlantUML 통합을 활성화할 준비가 되었습니다:

1. [운영자](../../user/permissions.md) 사용자로 GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**으로 이동하여 **PlantUML** 섹션을 확장합니다.
1. **PlantUML 활성화** 체크박스를 선택합니다.
1. PlantUML 인스턴스를 `https://gitlab.example.com/-/plantuml/`로 설정하고 **변경사항 저장**을 선택합니다.

브라우저가 외부 PlantUML 서비스로 다이어그램 콘텐츠를 전송하는 것을 방지하려면 [다이어그램 프록시](diagram_proxy.md)를 사용합니다.

PlantUML 및 GitLab 버전 번호에 따라 다음 단계를 수행해야 할 수도 있습니다:

- [plantuml.com](https://plantuml.com)과 같이 v1.2020.9 이상을 실행하는 PlantUML 서버의 경우 `deflate` 압축을 활성화하려면 `PLANTUML_ENCODING` 환경 변수를 설정해야 합니다. Linux 패키지 설치에서 이 값을 `/etc/gitlab/gitlab.rb`에서 다음 명령으로 설정할 수 있습니다:

  ```ruby
  gitlab_rails['env'] = { 'PLANTUML_ENCODING' => 'deflate' }
  ```

  GitLab Helm 차트에서 [global.extraEnv](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/charts/globals.md#extraenv) 섹션에 변수를 추가하여 설정할 수 있습니다. 다음과 같습니다:

  ```yaml
  global:
  extraEnv:
    PLANTUML_ENCODING: deflate
  ```

- `deflate`은 PlantUML의 기본 인코딩 유형입니다. 다른 인코딩 유형을 사용하려면 PlantUML 통합에서 [URL의 헤더 접두사가 필요합니다](https://plantuml.com/text-encoding). 이는 다양한 인코딩 유형을 구분하기 위해 필요합니다.

## 문제 해결 {#troubleshooting}

### 렌더링된 다이어그램 URL이 업데이트 후에도 동일하게 유지됨 {#rendered-diagram-url-remains-the-same-after-update}

렌더링된 다이어그램은 캐시됩니다. 업데이트를 확인하려면 다음 단계를 수행합니다:

- 다이어그램이 Markdown 파일에 있는 경우 Markdown 파일을 작은 변경을 한 후 커밋합니다. 이는 다시 렌더링을 트리거합니다.
- [Markdown 캐시를 무효화](../invalidate_markdown_cache.md#invalidate-the-cache)하여 데이터베이스 또는 Redis에서 캐시된 모든 Markdown을 지웁니다.

업데이트된 URL이 여전히 표시되지 않으면 다음을 확인하세요:

- PlantUML 서버가 GitLab 인스턴스에서 접근 가능한지 확인합니다.
- PlantUML 통합이 GitLab 설정에서 활성화되어 있는지 확인합니다.
- PlantUML 렌더링과 관련된 오류에 대한 GitLab 로그를 확인합니다.
- [GitLab Redis 캐시를 지웁니다](../raketasks/maintenance.md#clear-redis-cache).

### `404` 오류 - 브라우저에서 PlantUML 페이지 열기 {#404-error-when-opening-the-plantuml-page-in-the-browser}

PlantUML 서버가 [Debian 또는 Ubuntu에서](#debianubuntu) 설정되어 있을 때 `https://gitlab.example.com/-/plantuml/`를 방문할 때 `404` 오류가 발생할 수 있습니다.

이는 통합이 작동 중일 때도 발생할 수 있습니다. 반드시 PlantUML 서버 또는 구성에 문제가 있음을 나타내는 것은 아닙니다.

PlantUML이 올바르게 작동하는지 확인하려면 [PlantUML 설치를 확인](#verify-the-plantuml-installation)할 수 있습니다.
