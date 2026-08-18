---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 서비스
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD를 구성할 때, 작업이 실행되는 컨테이너를 생성하는 데 사용되는 이미지를 지정합니다. 이 이미지를 지정하려면 `image` 키워드를 사용합니다.

`services` 키워드를 사용하여 추가 이미지를 지정할 수 있습니다. 이 추가 이미지는 첫 번째 컨테이너에서 사용할 수 있는 다른 컨테이너를 생성하는 데 사용됩니다. 두 컨테이너는 서로 액세스할 수 있으며 작업 실행 중에 통신할 수 있습니다.

서비스 이미지는 모든 애플리케이션을 실행할 수 있지만, 가장 일반적인 사용 사례는 데이터베이스 컨테이너를 실행하는 것입니다. 예를 들면 다음과 같습니다:

- [MySQL](mysql.md)
- [PostgreSQL](postgres.md)
- [Redis](redis.md)
- JSON API를 제공하는 마이크로서비스의 예로 [GitLab](gitlab.md)

> [!warning]
> 서비스 간 네트워킹을 활성화하려면 `FF_NETWORK_PER_BUILD`을(를) `true`(으)로 설정합니다. 이 플래그가 없으면 서비스가 제대로 작동하지 않을 수 있습니다. 자세한 내용은 [기능 플래그](https://docs.gitlab.com/runner/configuration/feature-flags)를 참조하세요.

저장소용 데이터베이스를 사용하는 콘텐츠 관리 시스템을 개발하고 있다고 가정합니다. 애플리케이션의 모든 기능을 테스트하려면 데이터베이스가 필요합니다. 데이터베이스 컨테이너를 서비스 이미지로 실행하는 것은 이 시나리오에서 좋은 사용 사례입니다.

프로젝트를 빌드할 때마다 `mysql`을(를) 설치하는 대신 기존 이미지를 사용하여 추가 컨테이너로 실행합니다.

데이터베이스 서비스만으로 제한되지 않습니다. `.gitlab-ci.yml`에 필요한 만큼의 서비스를 추가하거나 [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration/)를 수동으로 수정할 수 있습니다. [Docker Hub](https://hub.docker.com/)에서 찾은 모든 이미지 또는 프라이빗 컨테이너 레지스트리의 이미지를 서비스로 사용할 수 있습니다.

프라이빗 이미지 사용에 대한 자세한 내용은 [프라이빗 컨테이너 레지스트리에서 이미지 액세스](../docker/using_docker_images.md#access-an-image-from-a-private-container-registry)를 참조하세요.

서비스는 CI 컨테이너 자체와 동일한 DNS 서버, 검색 도메인 및 추가 호스트를 상속합니다.

## 서비스가 작업에 연결되는 방식 {#how-services-are-linked-to-the-job}

컨테이너 연결의 작동 방식을 더 잘 이해하려면 [컨테이너 함께 연결](https://docs.docker.com/network/links/)를 읽으세요.

`mysql`을(를) 애플리케이션에 서비스로 추가하면, 이미지는 작업 컨테이너에 연결된 컨테이너를 생성하는 데 사용됩니다.

MySQL 서비스 컨테이너는 호스트명 `mysql` 아래에서 액세스할 수 있습니다. 데이터베이스 서비스에 액세스하려면 소켓이나 `localhost` 대신 `mysql`이라는 호스트에 연결합니다. [서비스 액세스](#accessing-the-services)에서 자세히 알아보세요.

## 서비스의 상태 확인 작동 방식 {#how-the-health-check-of-services-works}

서비스는 **network accessible** 추가 기능을 제공하도록 설계되었습니다. MySQL, Redis와 같은 데이터베이스일 수 있으며 Docker-in-Docker(DinD)를 사용할 수 있게 해주는 `docker:dind`일 수도 있습니다. CI/CD 작업을 진행하는 데 필요한 거의 모든 것이 될 수 있으며 네트워크를 통해 액세스됩니다.

이것이 작동하도록 하려면 러너는 다음을 수행합니다:

1. 기본적으로 컨테이너에서 노출되는 포트를 확인합니다.
1. 이러한 포트가 액세스 가능할 때까지 대기하는 특수 컨테이너를 시작합니다.

두 번째 검사 단계가 실패하면 `*** WARNING: Service XYZ probably didn't start properly` 경고를 인쇄합니다. 이 문제는 다음과 같은 이유로 발생할 수 있습니다:

- 서비스에 열린 포트가 없습니다.
- 서비스가 제한 시간 전에 올바르게 시작되지 않았으며 포트가 응답하지 않습니다.

대부분의 경우 작업에 영향을 미치지만 경고가 인쇄되었더라도 작업이 성공하는 경우가 있을 수 있습니다. 예를 들어:

- 경고가 발생한 후 서비스가 시작되었고, 작업이 처음부터 연결된 서비스를 사용하지 않는 경우입니다. 이 경우 작업이 서비스에 액세스해야 할 때, 서비스가 이미 연결을 대기 중일 수 있습니다.
- 서비스 컨테이너는 네트워킹 서비스를 제공하지 않지만 작업의 디렉터리로 무언가를 수행하고 있습니다(모든 서비스는 작업 디렉터리가 `/builds` 아래에 볼륨으로 마운트됨). 이 경우 서비스는 작업을 수행하고, 작업이 연결을 시도하지 않으므로 실패하지 않습니다.

서비스가 성공적으로 시작되면 [`before_script`](../yaml/_index.md#before_script)가 실행되기 전에 시작됩니다. 이는 서비스를 쿼리하는 `before_script`을(를) 작성할 수 있음을 의미합니다.

서비스는 작업이 실패하더라도 작업이 끝날 때 중지됩니다.

## 서비스 이미지가 제공하는 소프트웨어 사용 {#using-software-provided-by-a-service-image}

`service`을(를) 지정하면 **network accessible** 서비스를 제공합니다. 데이터베이스는 가장 간단한 서비스 예입니다.

서비스 기능은 정의된 `services` 이미지의 소프트웨어를 작업의 컨테이너에 추가하지 않습니다.

예를 들어, 작업에서 다음 `services`이(가) 정의되어 있으면 `php`, `node` 또는 `go` 명령을 사용할 수 없으며 작업이 실패합니다:

```yaml
job:
  services:
    - php:8.4
    - node:latest
    - golang:1.25
  image: alpine:3.23
  script:
    - php -v
    - node -v
    - go version
```

스크립트에서 `php`, `node` 및 `go`을(를) 사용할 수 있어야 하는 경우 다음 중 하나를 수행해야 합니다:

- 필요한 모든 도구가 포함된 기존 Docker 이미지를 선택합니다.
- 필요한 모든 도구가 포함된 자신만의 Docker 이미지를 만들고 작업에서 사용합니다.

## `services` 파일에서 `.gitlab-ci.yml` 정의 {#define-services-in-the-gitlab-ciyml-file}

작업당 다양한 이미지 및 서비스를 정의할 수도 있습니다:

```yaml
default:
  before_script:
    - bundle install

test:4.0:
  image: ruby:4.0
  services:
    - postgres:18
  script:
    - bundle exec rake spec

test:3.4:
  image: ruby:3.4
  services:
    - postgres:17
  script:
    - bundle exec rake spec
```

또는 `image` 및 `services`에 대해 [확장 구성 옵션](../docker/using_docker_images.md#extended-docker-configuration-options)을(를) 전달할 수 있습니다:

```yaml
default:
  image:
    name: ruby:4.0
    entrypoint: ["/bin/bash"]
  services:
    - name: my-postgres:18
      alias: db,postgres,pg
      entrypoint: ["/usr/local/bin/db-postgres"]
      command: ["start"]
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

## 서비스 액세스 {#accessing-the-services}

[서비스 별칭을 지정](#available-settings-for-services)하지 않으면 빌드 컨테이너에서 두 개의 호스트명 아래에서 액세스할 수 있습니다:

- `namespace-projectname`
- `namespace__projectname`

밑줄이 있는 호스트명은 RFC 유효하지 않으며 타사 애플리케이션에서 문제를 일으킬 수 있습니다.

서비스의 호스트명에 대한 기본 별칭은 다음 규칙에 따라 이미지 이름에서 생성됩니다:

- 콜론(`:`) 뒤의 모든 항목이 제거됩니다.
- 슬래시(`/`)가 이중 밑줄(`__`)로 바뀌고 기본 별칭이 생성됩니다.
- 슬래시(`/`)가 단일 대시(`-`)로 바뀌고 보조 별칭이 생성됩니다.

기본 동작을 재정의하려면 [하나 이상의 서비스 별칭을 지정](#available-settings-for-services)할 수 있습니다.

### 서비스 연결 {#connecting-services}

외부 API가 자체 데이터베이스와 통신해야 하는 종단 간 테스트와 같은 복잡한 작업에서 상호 종속 서비스를 사용할 수 있습니다.

예를 들어, API를 사용하고 API에 데이터베이스가 필요한 프론트엔드 애플리케이션의 종단 간 테스트:

```yaml
end-to-end-tests:
  image: node:latest
  services:
    - name: selenium/standalone-firefox:${FIREFOX_VERSION}
      alias: firefox
    - name: registry.gitlab.com/organization/private-api:latest
      alias: backend-api
    - name: postgres:18
      alias: db postgres db
  variables:
    FF_NETWORK_PER_BUILD: 1 # activate container-to-container networking
    POSTGRES_PASSWORD: supersecretpassword
    BACKEND_POSTGRES_HOST: postgres
  script:
    - npm install
    - npm test
```

이 솔루션이 작동하려면 [각 작업에 대해 새 네트워크를 생성하는 네트워킹 모드](https://docs.gitlab.com/runner/executors/docker/#create-a-network-for-each-job)를 사용해야 합니다.

## 서비스에 CI/CD 변수 전달 {#passing-cicd-variables-to-services}

또한 사용자 정의 [CI/CD 변수](../variables/_index.md)를 전달하여 Docker `images` 및 `services`를 `.gitlab-ci.yml` 파일에서 직접 세부 조정할 수 있습니다. 자세한 내용은 [`.gitlab-ci.yml` 정의 변수](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)에 대해 읽으세요.

```yaml
# The following variables are automatically passed down to the Postgres container
# as well as the Ruby container and available within each.
variables:
  HTTPS_PROXY: "https://10.1.1.1:8090"
  HTTP_PROXY: "https://10.1.1.1:8090"
  POSTGRES_DB: "my_custom_db"
  POSTGRES_USER: "postgres"
  POSTGRES_PASSWORD: "example"
  PGDATA: "/var/lib/postgresql/data"
  POSTGRES_INITDB_ARGS: "--encoding=UTF8 --data-checksums"

default:
  services:
    - name: postgres:18
      alias: db
      entrypoint: ["docker-entrypoint.sh"]
      command: ["postgres"]
  image:
    name: ruby:4.0
    entrypoint: ["/bin/bash"]
  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

## `services`에 사용 가능한 설정 {#available-settings-for-services}

`services:` 서브키에 대한 자세한 정보는 [CI/CD YAML 참조](../yaml/_index.md#services)를 참조하세요.

## 동일한 이미지에서 여러 서비스 시작 {#starting-multiple-services-from-the-same-image}

새로운 확장 Docker 구성 옵션 이전에는 다음 구성이 제대로 작동하지 않았습니다:

```yaml
services:
  - mysql:latest
  - mysql:latest
```

러너는 `mysql:latest` 이미지를 사용하는 두 개의 컨테이너를 시작합니다. 하지만 둘 다 [기본 호스트명 명명](#accessing-the-services)을(를) 기반으로 `mysql` 별칭을 사용하여 작업의 컨테이너에 추가됩니다. 이 경우 서비스 중 하나에 액세스할 수 없게 됩니다.

새로운 확장 Docker 구성 옵션 이후에는 이전 예제가 다음과 같이 보입니다:

```yaml
services:
  - name: mysql:latest
    alias: mysql-1
  - name: mysql:latest
    alias: mysql-2
```

러너는 여전히 `mysql:latest` 이미지를 사용하는 두 개의 컨테이너를 시작하지만, 이제는 각각 `.gitlab-ci.yml` 파일에 구성된 별칭으로도 액세스할 수 있습니다.

## 서비스의 명령 설정 {#setting-a-command-for-the-service}

`super/sql:latest` 이미지에 일부 SQL 데이터베이스가 있다고 가정합니다. 이를 작업의 서비스로 사용하고 싶습니다. 또한 이 이미지가 컨테이너를 시작하는 동안 데이터베이스 프로세스를 시작하지 않는다고 가정합시다. 사용자는 데이터베이스를 시작하기 위해 수동으로 `/usr/bin/super-sql run`을(를) 명령으로 사용해야 합니다.

새로운 확장 Docker 구성 옵션 이전에는 다음을 수행해야 했습니다:

- `super/sql:latest` 이미지를 기반으로 자신만의 이미지를 만듭니다.
- 기본 명령을 추가합니다.
- 작업의 구성에서 이미지를 사용합니다.

  - `my-super-sql:latest` 이미지의 Dockerfile:

    ```dockerfile
    FROM super/sql:latest
    CMD ["/usr/bin/super-sql", "run"]
    ```

  - `.gitlab-ci.yml`의 작업에서:

    ```yaml
    services:
      - my-super-sql:latest
    ```

새로운 확장 Docker 구성 옵션 이후에는 `.gitlab-ci.yml` 파일에서 `command`을(를) 설정할 수 있습니다:

```yaml
services:
  - name: super/sql:latest
    command: ["/usr/bin/super-sql", "run"]
```

`command`의 구문은 [Dockerfile `CMD`](https://docs.docker.com/reference/dockerfile/#cmd)과(와) 유사합니다.

## Kubernetes 실행기의 서비스 컨테이너 이름으로 별칭 사용 {#using-aliases-as-service-container-names-for-the-kubernetes-executor}

{{< history >}}

- GitLab 및 GitLab Runner 17.9에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/421131).

{{< /history >}}

Kubernetes 실행기의 서비스 컨테이너 이름으로 서비스 별칭을 사용할 수 있습니다. GitLab Runner는 다음 조건에 따라 컨테이너 이름을 지정합니다:

- 여러 별칭이 서비스에 대해 설정되면 서비스 컨테이너는 다음 중 첫 번째 별칭의 이름을 사용합니다:
  - 다른 서비스 컨테이너에서 이미 사용 중이 아닙니다.
  - [Kubernetes 레이블 이름 제약 조건](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names)을(를) 따릅니다.
- 별칭을 서비스 컨테이너 이름으로 사용할 수 없는 경우 GitLab Runner는 `svc-i` 패턴으로 돌아갑니다.

다음 예제에서는 Kubernetes 실행기의 서비스 컨테이너 이름 지정에 별칭을 사용하는 방법을 보여줍니다.

### 서비스당 하나의 별칭 {#one-alias-per-services}

다음 `.gitlab-ci.yml` 파일에서:

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: alpine:latest
      alias: alpine
    - name: mysql:latest
      alias: mysql
```

시스템은 표준 `build` 및 `helper` 컨테이너 외에 `alpine` 및 `mysql`이라는 이름의 컨테이너가 있는 작업 Pod를 생성합니다. 이러한 별칭을 사용하는 이유는 다음과 같습니다:

- 다른 서비스 컨테이너에서 사용 중이 아닙니다.
- [Kubernetes 레이블 이름 제약 조건](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-label-names)을(를) 따릅니다.

하지만 다음 `.gitlab-ci.yml`에서:

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: mysql:lts
      alias: mysql
    - name: mysql:latest
      alias: mysql
```

시스템은 `build` 및 `helper` 컨테이너 외에 `mysql` 및 `svc-0`이라는 이름의 두 개의 컨테이너를 더 생성합니다. `mysql` 컨테이너는 `mysql:lts` 이미지에 해당하고, `svc-0` 컨테이너는 `mysql:latest` 이미지에 해당합니다.

### 서비스당 여러 별칭 {#multiple-aliases-per-services}

다음 `.gitlab-ci.yml` 파일에서:

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: alpine:latest
      alias: alpine,alpine-latest
    - name: alpine:edge
      alias: alpine,alpine-edge,alpine-latest
```

시스템은 `build` 및 `helper` 컨테이너 외에 4개의 컨테이너를 더 생성합니다:

- `alpine` 이미지를 가진 컨테이너에 해당해야 하는 `alpine:latest`.
- `alpine:edge` 이미지를 가진 컨테이너에 해당해야 하는 `alpine-edge`(`alpine` 별칭이 이미 이전 컨테이너에 사용됨).

이 예에서는 `alpine-latest` 별칭이 사용되지 않습니다.

하지만 다음 `.gitlab-ci.yml`에서:

```yaml
job:
  image: alpine:latest
  script:
    - sleep 10
  services:
    - name: alpine:latest
      alias: alpine,alpine-edge
    - name: alpine:edge
      alias: alpine,alpine-edge
    - name: alpine:3.21
      alias: alpine,alpine-edge
```

`build` 및 `helper` 컨테이너 외에 6개의 컨테이너가 더 생성됩니다.

- `alpine` 이미지를 가진 컨테이너를 나타내야 하는 `alpine:latest`.
- `alpine:edge` 이미지를 가진 컨테이너를 나타내야 하는 `alpine-edge`(`alpine` 별칭이 이미 이전 컨테이너에 사용됨).
- `alpine:3.21` 이미지를 가진 컨테이너를 나타내야 하는 `svc-0`(`alpine` 및 `alpine-edge` 별칭이 이미 이전 컨테이너에 사용됨).

  - `svc-i` 패턴의 `i`은(는) 제공된 목록에서 서비스의 위치를 나타내지 않습니다. 대신 사용 가능한 별칭이 없을 때 서비스의 위치를 나타냅니다.

  - 잘못된 별칭이 제공된 경우(Kubernetes 제약 조건을 충족하지 않음), 작업은 다음 오류로 실패합니다(`alpine_edge` 별칭의 예). 이 실패는 별칭이 작업 Pod의 로컬 DNS 항목을 생성하는 데도 사용되기 때문에 발생합니다.

    ```plaintext
    ERROR: Job failed (system failure): prepare environment: setting up build pod: provided host alias
    alpine_edge for service alpine:edge is invalid DNS. a lowercase RFC 1123 subdomain must consist of lower
    case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g.
    'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*').
    Check https://docs.gitlab.com/runner/shells/index/#shell-profile-loading for more information.
    ```

## `services`을(를) `docker run`(Docker-in-Docker)와 나란히 사용 {#using-services-with-docker-run-docker-in-docker-side-by-side}

`docker run`로 시작한 컨테이너도 GitLab에서 제공하는 서비스에 연결할 수 있습니다.

서비스 부팅이 비용이 많이 들거나 시간이 오래 걸리는 경우 다양한 클라이언트 환경에서 테스트를 실행할 수 있으며 테스트된 서비스는 한 번만 부팅합니다.

```yaml
access-service:
  stage: build
  image: docker:20.10.16
  services:
    - docker:dind                    # necessary for docker run
    - traefik/whoami:latest
  variables:
    FF_NETWORK_PER_BUILD: "true"     # activate container-to-container networking
  script: |
    docker run --rm --name curl \
      --volume  "$(pwd)":"$(pwd)"    \
      --workdir "$(pwd)"             \
      --network=host                 \
      curlimages/curl:latest curl "http://traefik-whoami"
```

이 솔루션이 작동하려면 다음을 수행해야 합니다:

- [각 작업에 대해 새 네트워크를 생성하는 네트워킹 모드](https://docs.gitlab.com/runner/executors/docker/#create-a-network-for-each-job)를 사용합니다.
- [Docker 소켓 바인딩과 함께 Docker 실행기를 사용하지 마세요](../docker/using_docker_build.md#use-docker-socket-binding). 필요한 경우 위의 예에서 `host` 대신 이 작업에 대해 생성된 동적 네트워크 이름을 사용합니다.

## Docker 통합의 작동 방식 {#how-docker-integration-works}

다음은 작업 중에 Docker가 수행하는 단계에 대한 높은 수준의 개요입니다.

1. 서비스 컨테이너 생성: `mysql`, `postgresql`, `mongodb`, `redis`.
1. `config.toml` 및 `Dockerfile`에서 정의한 대로 모든 볼륨을 저장하는 캐시 컨테이너를 생성합니다(빌드 이미지의 `ruby:4.0`(이전 예제와 같음)).
1. 빌드 컨테이너를 생성하고 서비스 컨테이너를 빌드 컨테이너에 연결합니다.
1. 빌드 컨테이너를 시작하고 작업 스크립트를 컨테이너에 보냅니다.
1. 작업 스크립트를 실행합니다.
1. 코드 체크아웃: `/builds/group-name/project-name/`.
1. `.gitlab-ci.yml`에서 정의한 모든 단계를 실행합니다.
1. 빌드 스크립트의 종료 상태를 확인합니다.
1. 빌드 컨테이너 및 생성된 모든 서비스 컨테이너를 제거합니다.

## 서비스 컨테이너 로그 캡처 {#capturing-service-container-logs}

서비스 컨테이너에서 실행 중인 애플리케이션에 의해 생성된 로그는 후속 검사 및 디버깅을 위해 캡처할 수 있습니다. 서비스 컨테이너가 성공적으로 시작되지만 예상치 못한 동작으로 인해 작업 실패를 초래할 때 서비스 컨테이너 로그를 확인합니다. 로그는 컨테이너의 서비스 누락 또는 부정확한 구성을 나타낼 수 있습니다.

`CI_DEBUG_SERVICES`은(는) 서비스 컨테이너 로그 캡처에 대한 저장소 및 성능 결과가 모두 있으므로 서비스 컨테이너가 적극적으로 디버깅될 때만 활성화해야 합니다.

> [!warning]
> `CI_DEBUG_SERVICES`을(를) 활성화하면 마스킹된 변수가 노출될 수 있습니다. `CI_DEBUG_SERVICES`을(를) 활성화하면 서비스 컨테이너 로그와 CI 작업 로그가 작업의 추적 로그로 동시에 스트리밍됩니다. 이는 서비스 컨테이너 로그가 작업의 마스킹된 로그에 삽입될 수 있음을 의미합니다. 이는 변수 마스킹 메커니즘을 방해하고 마스킹된 변수가 노출되는 결과를 초래합니다.

서비스 로깅을 활성화하려면 `CI_DEBUG_SERVICES` 변수를 프로젝트의 `.gitlab-ci.yml` 파일에 추가합니다:

```yaml
variables:
  CI_DEBUG_SERVICES: "true"
```

허용되는 값은 다음과 같습니다:

- 활성화됨: `TRUE`, `true`, `True`
- 비활성화됨: `FALSE`, `false`, `False`

다른 값은 오류 메시지를 발생시키고 기능을 효과적으로 비활성화합니다.

활성화되면 모든 서비스 컨테이너의 로그가 캡처되고 다른 로그와 동시에 작업의 추적 로그로 스트리밍됩니다. 각 컨테이너의 로그는 컨테이너의 별칭으로 접두사가 지정되고 다른 색으로 표시됩니다.

> [!note]
> 작업 실패를 진단하기 위해 로그를 캡처하려는 서비스 컨테이너의 로깅 수준을 조정할 수 있습니다. 기본 로깅 수준은 충분한 문제 해결 정보를 제공하지 않을 수 있습니다.

[CI/CD 변수 마스킹](../variables/_index.md#mask-a-cicd-variable) 참조

## 작업을 로컬에서 디버깅 {#debug-a-job-locally}

다음 명령은 루트 권한 없이 실행됩니다. 사용자 계정으로 Docker 명령을 실행할 수 있는지 확인합니다.

먼저 `build_script`이라는 파일을 만들어서 시작합니다:

```shell
cat <<EOF > build_script
git clone https://gitlab.com/gitlab-org/gitlab-runner.git /builds/gitlab-org/gitlab-runner
cd /builds/gitlab-org/gitlab-runner
make runner-bin-host
EOF
```

이 예제는 Makefile을 포함하는 GitLab Runner 리포지토리를 사용하므로 `make`을(를) 실행하면 Makefile에 정의된 대상을 실행합니다. `make runner-bin-host` 대신 프로젝트에 특정한 명령을 실행할 수 있습니다.

그런 다음 서비스 컨테이너를 생성합니다:

```shell
docker run -d --name service-redis redis:latest
```

이전 명령은 최신 Redis 이미지를 사용하여 `service-redis`이라는 서비스 컨테이너를 생성합니다. 서비스 컨테이너는 백그라운드에서 실행됩니다(`-d`).

마지막으로 이전에 생성한 `build_script` 파일을 실행하여 빌드 컨테이너를 생성합니다:

```shell
docker run --name build -i --link=service-redis:redis golang:latest /bin/bash < build_script
```

이전 명령은 `golang:latest` 이미지에서 생성되고 연결된 서비스가 하나 있는 `build`이라는 컨테이너를 생성합니다. `build_script`은(는) `stdin`를 사용하여 bash 인터프리터로 파이프되며, 이는 `build` 컨테이너에서 `build_script`을(를) 실행합니다.

테스트가 완료된 후 컨테이너를 제거하려면 다음 명령을 사용합니다:

```shell
docker rm -f -v build service-redis
```

이전 명령은 `build` 컨테이너, 서비스 컨테이너 및 컨테이너 생성 시 생성된 모든 볼륨을 강제(`-f`)로 제거합니다(`-v`).

## 서비스 컨테이너 사용 시 보안 {#security-when-using-services-containers}

Docker 권한 모드는 서비스에 적용됩니다. 이는 서비스 이미지 컨테이너가 호스트 시스템에 액세스할 수 있음을 의미합니다. 신뢰할 수 있는 소스의 컨테이너 이미지만 사용해야 합니다.

## 공유된 `/builds` 디렉터리 {#shared-builds-directory}

빌드 디렉터리는 `/builds` 아래에 볼륨으로 마운트되며 작업과 서비스 간에 공유됩니다. 작업은 서비스 실행 후 `/builds/$CI_PROJECT_PATH`에 프로젝트를 체크아웃합니다. 서비스는 프로젝트 파일에 액세스하거나 아티팩트를 저장해야 할 수 있습니다. 그렇다면 디렉터리가 존재하고 `$CI_COMMIT_SHA`이(가) 체크아웃될 때까지 기다립니다. 작업 체크아웃 프로세스가 완료되기 전에 수행된 모든 변경 사항은 체크아웃 프로세스에 의해 제거됩니다.

서비스는 작업 디렉터리가 채워지고 처리할 준비가 되었을 때를 감지해야 합니다. 예를 들어 특정 파일이 사용 가능해질 때까지 기다립니다.

시작할 때 즉시 작동을 시작하는 서비스는 작업 데이터를 아직 사용할 수 없으므로 실패할 가능성이 있습니다. 예를 들어 컨테이너는 `docker build` 명령을 사용하여 DinD 서비스에 네트워크 연결을 만듭니다. 서비스는 API에 컨테이너 이미지 빌드를 시작하도록 지시합니다. Docker Engine은 Dockerfile에서 참조하는 파일에 액세스할 수 있어야 합니다. 따라서 서비스에서 `CI_PROJECT_DIR`에 액세스해야 합니다. 그러나 Docker Engine은 작업에서 `docker build` 명령을 호출할 때까지 액세스를 시도하지 않습니다. 이때 `/builds` 디렉터리는 이미 데이터로 채워져 있습니다. 시작 직후에 `CI_PROJECT_DIR`을(를) 작성하려고 시도하는 서비스는 `No such file or directory` 오류로 실패할 수 있습니다.

작업 자체로 제어되지 않는 작업 데이터와 상호 작용하는 서비스의 시나리오에서는 [Docker 실행기 워크플로우](https://docs.gitlab.com/runner/executors/docker/#docker-executor-workflow)를 고려합니다.
