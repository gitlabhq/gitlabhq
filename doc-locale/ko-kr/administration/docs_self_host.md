---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 제품 설명서 호스팅
description: 제품 설명서를 직접 호스팅합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

`docs.gitlab.com`에서 GitLab 제품 설명서에 접근할 수 없으면, 대신 설명서를 직접 호스팅할 수 있습니다.

> [!note]
> 인스턴스의 로컬 도움말에는 모든 문서가 포함되지 않습니다(예를 들어, GitLab Runner 또는 GitLab Operator의 설명서는 포함되지 않음). 또한 검색 가능하거나 탐색 가능하지 않습니다. 인스턴스 내에서 특정 페이지로의 직접 링크만 지원하도록 의도되었습니다.

## 컨테이너 레지스트리 URL {#container-registry-url}

원하는 컨테이너 이미지의 URL은 필요한 GitLab 문서 버전에 따라 달라집니다. 다음 섹션에서 사용할 URL에 대한 가이드로 다음 표를 참조합니다.

| GitLab 버전 | 컨테이너 레지스트리                                                                           | 컨테이너 이미지 URL |
|:---------------|:---------------------------------------------------------------------------------------------|:--------------------|
| 17.8 이상 | <https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/container_registry/8244403> | `registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:<version>` |
| 15.5 - 17.7    | <https://gitlab.com/gitlab-org/gitlab-docs/container_registry/3631228>                       | `registry.gitlab.com/gitlab-org/gitlab-docs/archives:<version>` |
| 10.3 - 15.4    | <https://gitlab.com/gitlab-org/gitlab-docs/container_registry/631635>                        | `registry.gitlab.com/gitlab-org/gitlab-docs:<version>` |

## 설명서 자체 호스팅 옵션 {#documentation-self-hosting-options}

GitLab 제품 설명서를 호스팅하기 위해 다음을 사용할 수 있습니다:

- Docker 컨테이너
- GitLab Pages
- 자신의 웹 서버

다음 예제에서는 GitLab 17.8을 사용하지만, GitLab 인스턴스에 해당하는 버전을 사용해야 합니다.

### Docker를 사용하여 제품 설명서 자체 호스팅 {#self-host-the-product-documentation-with-docker}

설명서 웹사이트는 컨테이너 내의 포트 `4000`에서 제공됩니다. 다음 예제에서는 호스트에서 동일한 포트로 이를 노출합니다.

다음 중 하나를 수행해야 합니다:

- 방화벽에서 포트 `4000`를 허용합니다.
- 다른 포트를 사용합니다. 다음 예제에서 가장 왼쪽 `4000`를 다른 포트 번호로 바꿉니다.

Docker 컨테이너에서 GitLab 제품 설명서 웹사이트를 실행하려면:

1. GitLab을 호스팅하는 서버 또는 GitLab 인스턴스가 통신할 수 있는 다른 서버에서:

   - 일반 Docker를 사용하는 경우 다음을 실행합니다:

     ```shell
     docker run --detach --name gitlab_docs -it --rm -p 4000:4000 registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     ```

   - [Docker Compose](../install/docker/installation.md#install-gitlab-by-using-docker-compose)를 사용하여 GitLab 인스턴스를 호스팅하는 경우, 기존 `docker-compose.yaml`에 다음을 추가합니다:

     ```yaml
     version: '3.6'
     services:
       gitlab_docs:
         image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
         hostname: 'docs.gitlab.example.com'
         ports:
           - '4000:4000'
     ```

     그런 다음 변경 사항을 가져옵니다:

     ```shell
     docker-compose up -d
     ```

1. `http://0.0.0.0:4000`을 방문하여 설명서 웹사이트를 보고 작동하는지 확인합니다.
1. [도움말 링크를 새 설명서 사이트로 리디렉션](#redirect-the-help-links-to-the-new-docs-site)합니다.

### GitLab Pages를 사용하여 제품 설명서 자체 호스팅 {#self-host-the-product-documentation-with-gitlab-pages}

GitLab Pages를 사용하여 GitLab 제품 설명서를 호스팅할 수 있습니다.

전제 조건:

- Pages 사이트 URL이 하위 폴더를 사용하지 않는지 확인합니다. 사이트가 사전 컴파일되는 방식 때문에 CSS 및 JavaScript 파일은 기본 도메인 또는 하위 도메인에 상대적입니다. 예를 들어, `https://example.com/docs/`과 같은 URL은 지원되지 않습니다.

GitLab Pages를 사용하여 제품 설명서 사이트를 호스팅하려면:

1. [빈 프로젝트를 생성](../user/project/_index.md#create-a-blank-project)합니다.
1. 새로운 `.gitlab-ci.yml` 파일을 생성하거나 기존 파일을 편집하고, 다음 `pages` 작업을 추가합니다. 버전이 GitLab 설치와 동일한지 확인하세요:

   ```yaml
   pages:
     image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     script:
       - mkdir public
       - cp -a /usr/share/nginx/html/* public/
     artifacts:
       paths:
       - public
   ```

1. 선택사항. GitLab Pages 도메인 이름을 설정합니다. GitLab Pages 웹사이트의 유형에 따라 두 가지 옵션이 있습니다:

   | 웹사이트 유형         | [기본 도메인](../user/project/pages/getting_started_part_one.md#gitlab-pages-default-domain-names) | [사용자 지정 도메인](../user/project/pages/custom_domains_ssl_tls_certification/_index.md) |
   |-------------------------|----------------|---------------|
   | [프로젝트 웹사이트](../user/project/pages/getting_started_part_one.md#project-website-examples) | 지원되지 않음 | 지원됨 |
   | [사용자 또는 그룹 웹사이트](../user/project/pages/getting_started_part_one.md#user-and-group-website-examples) | 지원됨 | 지원됨 |

1. [도움말 링크를 새 설명서 사이트로 리디렉션](#redirect-the-help-links-to-the-new-docs-site)합니다.

### 자신의 웹 서버에서 제품 설명서 자체 호스팅 {#self-host-the-product-documentation-on-your-own-web-server}

> [!note]
> 생성하는 웹사이트는 설치된 GitLab 버전과 일치하는 하위 디렉토리 아래에 호스팅되어야 합니다(예: `17.8/`). [Docker 이미지](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/container_registry/8244403)는 기본적으로 이 버전을 사용합니다.

제품 설명서 사이트는 정적이므로, 컨테이너 내부에서 `/usr/share/nginx/html`의 내용을 가져와서 자신의 웹 서버를 사용하여 원하는 곳에 설명서를 호스팅할 수 있습니다.

`html` 디렉토리는 그대로 제공되어야 하며 다음과 같은 구조를 가집니다:

```plaintext
├── 17.8/
├── index.html
```

이 예제에서:

- `17.8/`는 설명서가 호스팅되는 디렉토리입니다.
- `index.html`는 설명서를 포함하는 디렉토리로 리디렉션되는 간단한 HTML 파일입니다. 이 경우 `17.8/`입니다.

설명서 사이트의 HTML 파일을 추출하려면:

1. 설명서 웹사이트의 HTML 파일을 보유하는 컨테이너를 생성합니다:

   ```shell
   docker create -it --name gitlab_docs registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   ```

1. 웹사이트를 `/srv/gitlab/` 아래에 복사합니다:

   ```shell
   docker cp gitlab-docs:/usr/share/nginx/html /srv/gitlab/
   ```

   `/srv/gitlab/html/` 디렉토리를 사용하여 설명서 웹사이트를 보유합니다.

1. 컨테이너를 제거합니다:

   ```shell
   docker rm -f gitlab_docs
   ```

1. 웹 서버가 `/srv/gitlab/html/`의 내용을 제공하도록 합니다.
1. [도움말 링크를 새 설명서 사이트로 리디렉션](#redirect-the-help-links-to-the-new-docs-site)합니다.

## `/help` 링크를 새 문서 사이트로 리디렉션 {#redirect-the-help-links-to-the-new-docs-site}

로컬 제품 설명서 사이트가 실행 중인 후, [도움말 링크를 리디렉션](settings/help_page.md#redirect-help-pages)하여 GitLab 애플리케이션의 로컬 사이트로 이동하게 하되, 정규화된 도메인 이름을 설명서 URL로 사용합니다. 예를 들어, [Docker 방법](#self-host-the-product-documentation-with-docker)을 사용한 경우 `http://0.0.0.0:4000`을 입력합니다.

버전을 추가할 필요가 없습니다. GitLab이 이를 감지하고 필요에 따라 설명서 URL 요청에 추가합니다. 예를 들어, GitLab 버전이 17.8인 경우:

- GitLab 설명서 URL은 `http://0.0.0.0:4000/17.8/`이 됩니다.
- GitLab의 링크는 `<instance_url>/help/administration/settings/help_page#destination-requirements`로 표시됩니다.
- 링크를 선택하면 `http://0.0.0.0:4000/17.8/administration/settings/help_page/#destination-requirements`로 리디렉션됩니다.

설정을 테스트하려면 GitLab에서 **자세히 알아보기** 링크를 선택합니다. 예를 들어:

1. 오른쪽 상단 모서리에서 아바타를 선택합니다.
1. **환경설정**을 선택합니다.
1. **Syntax highlighting theme** 섹션에서 **자세히 알아보기**를 선택합니다.

## 제품 설명서를 최신 버전으로 업그레이드 {#upgrade-the-product-documentation-to-a-later-version}

설명서 사이트를 최신 버전으로 업그레이드하려면 최신 Docker 이미지 태그를 다운로드해야 합니다.

### Docker를 사용하여 업그레이드 {#upgrade-using-docker}

최신 버전으로 업그레이드하려면 [Docker를 사용](#self-host-the-product-documentation-with-docker)합니다:

- Docker를 사용하는 경우:

  1. 실행 중인 컨테이너를 중지합니다:

     ```shell
     sudo docker stop gitlab_docs
     ```

  1. 기존 컨테이너를 제거합니다:

     ```shell
     sudo docker rm gitlab_docs
     ```

  1. 새 이미지를 가져옵니다. 예를 들어, 17.8:

     ```shell
     docker run --detach --name gitlab_docs -it --rm -p 4000:4000 registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     ```

- Docker Compose를 사용하는 경우:

  1. `docker-compose.yaml`의 버전을 변경합니다. 예를 들어, 17.8:

     ```yaml
     version: '3.6'
     services:
       gitlab_docs:
         image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
         hostname: 'docs.gitlab.example.com'
         ports:
           - '4000:4000'
     ```

  1. 변경 사항을 가져옵니다:

     ```shell
     docker-compose up -d
     ```

### GitLab Pages를 사용하여 업그레이드 {#upgrade-using-gitlab-pages}

최신 버전으로 업그레이드하려면 [GitLab Pages를 사용](#self-host-the-product-documentation-with-gitlab-pages)합니다:

1. 기존 `.gitlab-ci.yml` 파일을 편집하고 `image` 버전 번호를 바꿉니다:

   ```yaml
   image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   ```

1. 변경 사항을 커밋하고 푸시하면 GitLab Pages가 새 설명서 사이트 버전을 가져옵니다.

### 자신의 웹 서버를 사용하여 업그레이드 {#upgrade-using-your-own-web-server}

최신 버전으로 업그레이드하려면 [자신의 웹 서버를 사용](#self-host-the-product-documentation-on-your-own-web-server)합니다:

1. 설명서 사이트의 HTML 파일을 복사합니다:

   ```shell
   docker create -it --name gitlab_docs registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   docker cp gitlab_docs:/usr/share/nginx/html /srv/gitlab/
   docker rm -f gitlab_docs
   ```

1. 선택사항. 이전 사이트를 제거합니다:

   ```shell
   rm -r /srv/gitlab/html/17.8/
   ```

## 문제 해결 {#troubleshooting}

### 검색이 작동하지 않음 {#search-does-not-work}

로컬 검색은 버전 15.6 이상에 포함되어 있습니다. 이전 버전을 사용하는 경우 검색이 작동하지 않습니다.

자세한 내용은 GitLab 문서에서 사용하는 [다양한 유형의 검색](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/search.md)에 대해 읽습니다.

### Docker 이미지를 찾을 수 없음 {#the-docker-image-is-not-found}

Docker 이미지를 찾을 수 없다는 오류가 표시되면 [올바른 레지스트리 URL](#container-registry-url)을 사용하고 있는지 확인합니다.

### Docker 호스팅 설명서 사이트가 리디렉션에 실패 {#docker-hosted-documentation-site-fails-to-redirect}

macOS에서 Docker의 GitLab 설명서를 미리 볼 때, 설명서로의 리디렉션을 방지하는 문제가 발생할 수 있으며, `If you are not redirected automatically, click here.` 메시지가 표시됩니다.

리디렉션을 벗어나려면 `http://127.0.0.1:4000/16.8/`과 같이 URL에 버전 번호를 추가해야 합니다.
