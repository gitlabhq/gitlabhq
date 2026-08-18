---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Docker를 사용하여 Docker 이미지 빌드
description: "GitLab CI/CD에서 셸 실행기, Docker-in-Docker, 소켓 바인딩 또는 파이프 바인딩을 사용하여 컨테이너 이미지를 빌드하고 푸시합니다."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD와 Docker를 함께 사용하여 Docker 이미지를 생성할 수 있습니다. 예를 들어 애플리케이션의 Docker 이미지를 생성하고, 테스트한 후 컨테이너 레지스트리에 푸시할 수 있습니다.

CI/CD 작업에서 Docker 명령을 실행하려면 러너를 구성하여 `docker` 명령을 지원해야 합니다. 이 방법은 `privileged` 모드가 필요합니다.

러너에서 `privileged` 모드를 활성화하지 않고 Docker 이미지를 빌드하려는 경우 [Docker 대체 방법](#docker-alternatives)을 사용할 수 있습니다.

## CI/CD 작업에서 Docker 명령 활성화 {#enable-docker-commands-in-your-cicd-jobs}

CI/CD 작업에 대해 Docker 명령을 활성화하려면 다음을 사용할 수 있습니다:

- [셸 실행기](#use-the-shell-executor)
- [Docker-in-Docker](#use-docker-in-docker)
- [Docker 소켓 바인딩](#use-docker-socket-binding)
- [Docker 파이프 바인딩](#use-docker-pipe-binding)

### 셸 실행기 사용 {#use-the-shell-executor}

CI/CD 작업에 Docker 명령을 포함하려면 러너를 구성하여 `shell` 실행기를 사용하도록 할 수 있습니다. 이 구성에서 `gitlab-runner` 사용자가 Docker 명령을 실행하지만 그렇게 할 수 있는 권한이 필요합니다.

1. [러너를 설치합니다](https://gitlab.com/gitlab-org/gitlab-runner/#installation).
1. [러너를 등록합니다](https://docs.gitlab.com/runner/register/). `shell` 실행기를 선택합니다. 예를 들어:

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor shell \
     --description "My Runner"
   ```

1. 러너가 설치된 서버에 Docker Engine을 설치합니다. [지원되는 플랫폼](https://docs.docker.com/engine/install/) 목록을 봅니다.

1. `gitlab-runner` 사용자를 `docker` 그룹에 추가합니다:

   ```shell
   sudo usermod -aG docker gitlab-runner
   ```

1. `gitlab-runner`이 Docker에 액세스할 수 있는지 확인합니다:

   ```shell
   sudo -u gitlab-runner -H docker info
   ```

1. GitLab에서 `docker info`을 `.gitlab-ci.yml`에 추가하여 Docker가 작동하는지 확인합니다:

   ```yaml
   default:
     before_script:
       - docker info
   build_image:
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

이제 `docker` 명령을 사용할 수 있습니다(필요한 경우 Docker Compose를 설치할 수 있음).

`gitlab-runner`을 `docker` 그룹에 추가하면 `gitlab-runner`에 전체 루트 권한을 부여하게 됩니다. 자세한 내용은 [`docker` 그룹의 보안](https://blog.zopyx.com/on-docker-security-docker-group-considered-harmful/)을 참조하세요.

### Docker-in-Docker 사용 {#use-docker-in-docker}

"Docker-in-Docker"(`dind`)는 다음을 의미합니다:

- 등록된 러너는 [Docker 실행기](https://docs.gitlab.com/runner/executors/docker/) 또는 [Kubernetes 실행기](https://docs.gitlab.com/runner/executors/kubernetes/)를 사용합니다.
- 이 실행기는 Docker에서 제공하는 [Docker의 컨테이너 이미지](https://hub.docker.com/_/docker/)를 사용하여 CI/CD 작업을 실행합니다.

Docker 이미지에는 모든 `docker` 도구가 포함되어 있으며 권한 있는 모드에서 이미지의 컨텍스트 내 작업 스크립트를 실행할 수 있습니다.

[GitLab.com 인스턴스 러너](../runners/_index.md)에서 지원하는 TLS를 활성화하여 Docker-in-Docker를 사용해야 합니다.

항상 `docker:24.0.5`과 같은 이미지의 특정 버전을 고정해야 합니다. `docker:latest`와 같은 태그를 사용하는 경우 어떤 버전이 사용되는지 제어할 수 없습니다. 새 버전이 릴리스될 때 호환성 문제가 발생할 수 있습니다.

#### Docker 실행기에서 Docker-in-Docker 사용 {#use-the-docker-executor-with-docker-in-docker}

Docker 실행기를 사용하여 Docker 컨테이너에서 작업을 실행할 수 있습니다.

##### Docker 실행기에서 TLS를 활성화한 Docker-in-Docker {#docker-in-docker-with-tls-enabled-in-the-docker-executor}

Docker 데몬은 TLS를 통한 연결을 지원합니다. TLS는 Docker 19.03.12 이상에서 기본값입니다.

> [!warning]
> 이 작업은 `--docker-privileged`를 활성화하여 컨테이너의 보안 메커니즘을 효과적으로 비활성화하고 호스트를 권한 상승에 노출시킵니다. 이 작업으로 인해 컨테이너 탈출이 발생할 수 있습니다. 자세한 내용은 [런타임 권한 및 Linux 기능](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities)을 참조하세요.

TLS를 활성화하여 Docker-in-Docker를 사용하려면 다음을 수행하세요:

1. [러너](https://docs.gitlab.com/runner/install/)를 설치합니다.
1. 명령줄에서 러너를 등록합니다. `docker` 및 `privileged` 모드를 사용합니다:

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --tag-list "tls-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-privileged \
     --docker-volumes "/certs/client"
   ```

   - 이 명령은 `docker:24.0.5-cli` 이미지를 사용하도록 새 러너를 등록합니다(작업 수준에서 지정된 것이 없는 경우). 빌드 및 서비스 컨테이너를 시작하려면 `privileged` 모드를 사용합니다. Docker-in-Docker를 사용하려면 항상 Docker 컨테이너에서 `privileged = true`을 사용해야 합니다.
   - 이 명령은 서비스 및 빌드 컨테이너에 대해 `/certs/client`을 마운트하며, 이는 Docker 클라이언트가 해당 디렉토리의 인증서를 사용하는 데 필요합니다. 자세한 내용은 [Docker 이미지 설명서](https://hub.docker.com/_/docker/)를 참조하세요.

   이전 명령은 다음 예시와 유사한 `config.toml` 항목을 생성합니다:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = true
       disable_cache = false
       volumes = ["/certs/client", "/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. 이제 작업 스크립트에서 `docker`을 사용할 수 있습니다. `docker:24.0.5-dind` 서비스를 포함해야 합니다:

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - docker:24.0.5-dind
     before_script:
       - docker info

   variables:
     # When you use the dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket. Docker 19.03 does this automatically
     # by setting the DOCKER_HOST in
     # https://github.com/docker-library/docker/blob/d45051476babc297257df490d22cbd806f1b11e4/19.03/docker-entrypoint.sh#L23-L29
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # Specify to Docker where to create the certificates. Docker
     # creates them automatically on boot, and creates
     # `/certs/client` to share between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"

   build:
     stage: build
     tags:
       - tls-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

##### Docker-in-Docker와 빌드 컨테이너 간의 공유 볼륨에 Unix 소켓 사용 {#use-a-unix-socket-on-a-shared-volume-between-docker-in-docker-and-build-container}

`volumes = ["/certs/client", "/cache"]`에 정의된 디렉토리는 [Docker 실행기에서 TLS를 활성화한 Docker-in-Docker](#docker-in-docker-with-tls-enabled-in-the-docker-executor) 접근 방식에서 [빌드 간에 유지](https://docs.gitlab.com/runner/executors/docker/#persistent-storage)됩니다. Docker 실행기 러너를 사용하는 여러 CI/CD 작업에서 Docker-in-Docker 서비스가 활성화되면 각 작업은 디렉토리 경로에 쓰게 됩니다. 이 접근 방식으로 인해 충돌이 발생할 수 있습니다.

이 충돌을 해결하려면 Docker-in-Docker 서비스와 빌드 컨테이너 간에 공유된 볼륨의 Unix 소켓을 사용하세요. 이 접근 방식은 성능을 개선하고 서비스와 클라이언트 간의 안전한 연결을 구축합니다.

다음은 빌드 및 서비스 컨테이너 간에 공유되는 임시 볼륨이 있는 샘플 `config.toml`입니다:

```toml
[[runners]]
  url = "https://gitlab.com/"
  token = TOKEN
  executor = "docker"
  [runners.docker]
    image = "docker:24.0.5-cli"
    privileged = true
    volumes = ["/runner/services/docker"] # Temporary volume shared between build and service containers.
```

Docker-in-Docker 서비스는 `docker.sock`을 생성합니다. Docker 클라이언트는 Docker Unix 소켓 볼륨을 통해 `docker.sock`에 연결합니다.

```yaml
job:
  variables:
    # This variable is shared by both the DinD service and Docker client.
    # For the service, it will instruct DinD to create `docker.sock` here.
    # For the client, it tells the Docker client which Docker Unix socket to connect to.
    DOCKER_HOST: "unix:///runner/services/docker/docker.sock"
  services:
    - docker:24.0.5-dind
  image: docker:24.0.5-cli
  script:
    - docker version
```

##### Docker 실행기에서 TLS를 비활성화한 Docker-in-Docker {#docker-in-docker-with-tls-disabled-in-the-docker-executor}

TLS를 비활성화하기 위한 정당한 이유가 있는 경우도 있습니다. 예를 들어 사용 중인 러너 구성을 제어할 수 없습니다.

1. 명령줄에서 러너를 등록합니다. `docker` 및 `privileged` 모드를 사용합니다:

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --tag-list "no-tls-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-privileged
   ```

   이전 명령은 다음 예시와 유사한 `config.toml` 항목을 생성합니다:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = true
       disable_cache = false
       volumes = ["/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. 작업 스크립트에 `docker:24.0.5-dind` 서비스를 포함합니다:

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - docker:24.0.5-dind
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct docker to talk with the
     # daemon started inside of the service. The daemon is available with
     # a network connection instead of the default /var/run/docker.sock socket.
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services
     #
     DOCKER_HOST: tcp://docker:2375
     #
     # This instructs Docker not to start over TLS.
     DOCKER_TLS_CERTDIR: ""

   build:
     stage: build
     tags:
       - no-tls-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

##### Docker 실행기에서 프록시를 활성화한 Docker-in-Docker {#docker-in-docker-with-proxy-enabled-in-the-docker-executor}

`docker push` 명령을 사용하도록 프록시 설정을 구성해야 할 수 있습니다.

자세한 내용은 [dind 서비스 사용 시 프록시 설정](https://docs.gitlab.com/runner/configuration/proxy/#proxy-settings-when-using-dind-service)을 참조하세요.

#### Docker-in-Docker와 함께 Kubernetes 실행기 사용 {#use-the-kubernetes-executor-with-docker-in-docker}

[Kubernetes 실행기](https://docs.gitlab.com/runner/executors/kubernetes/)를 사용하여 Docker 컨테이너에서 작업을 실행할 수 있습니다.

##### Kubernetes에서 TLS를 활성화한 Docker-in-Docker {#docker-in-docker-with-tls-enabled-in-kubernetes}

Kubernetes에서 TLS를 활성화하여 Docker-in-Docker를 사용하려면 다음을 수행하세요:

1. [Helm 차트](https://docs.gitlab.com/runner/install/kubernetes/)를 사용하여 [`values.yml` 파일](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)을 업데이트하여 볼륨 마운트를 지정합니다.

   ```yaml
   runners:
     tags: "tls-dind-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = true
         [[runners.kubernetes.volumes.empty_dir]]
           name = "docker-certs"
           mount_path = "/certs/client"
           medium = "Memory"
   ```

1. 작업에 `docker:24.0.5-dind` 서비스를 포함합니다:

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - name: docker:24.0.5-dind
         variables:
           HEALTHCHECK_TCP_PORT: "2376"
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket.
     DOCKER_HOST: tcp://docker:2376
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # Specify to Docker where to create the certificates. Docker
     # creates them automatically on boot, and creates
     # `/certs/client` to share between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"
     # These are usually specified by the entrypoint, however the
     # Kubernetes executor doesn't run entrypoints
     # https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4125
     DOCKER_TLS_VERIFY: 1
     DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"

   build:
     stage: build
     tags:
       - tls-dind-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

##### Kubernetes에서 TLS를 비활성화한 Docker-in-Docker {#docker-in-docker-with-tls-disabled-in-kubernetes}

Kubernetes에서 TLS를 비활성화하여 Docker-in-Docker를 사용하려면 이전 예시를 다음과 같이 수정해야 합니다:

- `[[runners.kubernetes.volumes.empty_dir]]` 섹션을 `values.yml` 파일에서 제거합니다.
- 포트를 `2376`에서 `2375`로 변경하고 `DOCKER_HOST: tcp://docker:2375`을 사용합니다.
- `DOCKER_TLS_CERTDIR: ""`로 TLS를 비활성화한 상태로 Docker를 시작하도록 지시합니다.

예를 들어:

1. [Helm 차트](https://docs.gitlab.com/runner/install/kubernetes/)를 사용하여 [`values.yml` 파일](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)을 업데이트합니다:

   ```yaml
   runners:
     tags: "no-tls-dind-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = true
   ```

1. 이제 작업 스크립트에서 `docker`을 사용할 수 있습니다. `docker:24.0.5-dind` 서비스를 포함해야 합니다:

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - name: docker:24.0.5-dind
         variables:
           HEALTHCHECK_TCP_PORT: "2375"
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket.
     DOCKER_HOST: tcp://docker:2375
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # This instructs Docker not to start over TLS.
     DOCKER_TLS_CERTDIR: ""
   build:
     stage: build
     tags:
       - no-tls-dind-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Docker-in-Docker의 알려진 이슈 {#known-issues-with-docker-in-docker}

Docker-in-Docker는 권장 구성이지만 다음 이슈에 주의해야 합니다:

- **`docker-compose` 명령**: 이 명령은 기본적으로 이 구성에서 사용할 수 없습니다. 작업 스크립트에서 `docker-compose`을 사용하려면 Docker Compose [설치 지침](https://docs.docker.com/compose/install/)을 따르세요.
- **Cache**: 각 작업은 새 환경에서 실행됩니다. 모든 빌드가 Docker 엔진의 자체 인스턴스를 가져오므로 동시 작업으로 인한 충돌이 발생하지 않습니다. 그러나 레이어 캐싱이 없어 작업이 더 느려질 수 있습니다. [Docker 레이어 캐싱](#docker-layer-caching)을 참조하세요.
- **Storage drivers**: 기본적으로 Docker의 이전 버전은 `vfs` 스토리지 드라이버를 사용하며, 이는 각 작업에 대해 파일 시스템을 복사합니다. Docker 17.09 이상은 `--storage-driver overlay2`을 사용하며, 이는 권장 스토리지 드라이버입니다. 자세한 내용은 [OverlayFS 드라이버 사용](#use-the-overlayfs-driver)을 참조하세요.
- **Root file system**: `docker:24.0.5-dind` 컨테이너와 러너 컨테이너는 루트 파일 시스템을 공유하지 않으므로 작업의 작업 디렉토리를 하위 컨테이너의 마운트 포인트로 사용할 수 있습니다. 예를 들어 자식 컨테이너와 공유하려는 파일이 있는 경우 `/builds/$CI_PROJECT_PATH` 아래에 하위 디렉토리를 만들고 마운트 포인트로 사용할 수 있습니다. 자세한 설명은 [이슈 #41227](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41227)을 참조하세요.

  ```yaml
  variables:
    MOUNT_POINT: /builds/$CI_PROJECT_PATH/mnt
  script:
    - mkdir -p "$MOUNT_POINT"
    - docker run -v "$MOUNT_POINT:/mnt" my-docker-image
  ```

### Docker 소켓 바인딩 사용 {#use-docker-socket-binding}

CI/CD 작업에서 Docker 명령을 사용하려면 `/var/run/docker.sock`을 빌드 컨테이너에 바인드 마운트할 수 있습니다. Docker는 이미지의 컨텍스트에서 사용할 수 있습니다.

Docker 소켓을 바인드하는 경우 `docker:24.0.5-dind`을 서비스로 사용할 수 없습니다. 볼륨 바인딩은 또한 서비스에 영향을 미쳐 호환되지 않게 합니다.

#### Docker 소켓 바인딩과 함께 Docker 실행기 사용 {#use-the-docker-executor-with-docker-socket-binding}

Docker 실행기로 Docker 소켓을 마운트하려면 `"/var/run/docker.sock:/var/run/docker.sock"`을 [`[runners.docker]` 섹션의 볼륨](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section)에 추가합니다.

1. 러너를 등록할 때 `/var/run/docker.sock`을 마운트하려면 다음 옵션을 포함합니다:

   ```shell
   sudo gitlab-runner register \
     --non-interactive \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor "docker" \
     --description "docker-runner" \
     --tag-list "socket-binding-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
   ```

   이전 명령은 다음 예시와 유사한 `config.toml` 항목을 생성합니다:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = RUNNER_TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = false
       disable_cache = false
       volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
     [runners.cache]
       Insecure = false
   ```

1. 작업 스크립트에서 Docker를 사용합니다:

   ```yaml
   default:
     image: docker:24.0.5-cli
     before_script:
       - docker info

   build:
     stage: build
     tags:
       - socket-binding-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Docker 소켓 바인딩과 함께 Kubernetes 실행기 사용 {#use-the-kubernetes-executor-with-docker-socket-binding}

Kubernetes 실행기로 Docker 소켓을 마운트하려면 `"/var/run/docker.sock"`을 [`[[runners.kubernetes.volumes.host_path]]` 섹션의 볼륨](https://docs.gitlab.com/runner/executors/kubernetes/index/#hostpath-volume)에 추가합니다.

1. 볼륨 마운트를 지정하려면 [`values.yml` 파일](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)을 [Helm 차트](https://docs.gitlab.com/runner/install/kubernetes/)를 사용하여 업데이트합니다.

   ```yaml
   runners:
     tags: "socket-binding-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = false
         [runners.kubernetes]
           [[runners.kubernetes.volumes.host_path]]
             host_path = '/var/run/docker.sock'
             mount_path = '/var/run/docker.sock'
             name = 'docker-sock'
             read_only = true
   ```

1. 작업 스크립트에서 Docker를 사용합니다:

   ```yaml
   default:
     image: docker:24.0.5-cli
     before_script:
       - docker info
   build:
     stage: build
     tags:
       - socket-binding-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Docker 소켓 바인딩의 알려진 이슈 {#known-issues-with-docker-socket-binding}

Docker 소켓 바인딩을 사용하는 경우 권한 있는 모드에서 Docker를 실행하는 것을 방지합니다. 그러나 이 방법의 함의는 다음과 같습니다:

- Docker 데몬을 공유하면 컨테이너의 보안 메커니즘을 효과적으로 비활성화하고 호스트를 권한 상승에 노출시킵니다. 이로 인해 컨테이너 탈출이 발생할 수 있습니다. 예를 들어 프로젝트에서 `docker rm -f $(docker ps -a -q)`을 실행하는 경우 러너 컨테이너를 제거합니다.
- 동시 작업이 작동하지 않을 수 있습니다. 테스트에서 특정 이름으로 컨테이너를 만드는 경우 서로 충돌할 수 있습니다.
- Docker 명령으로 생성된 모든 컨테이너는 러너의 하위 항목이 아니라 러너의 형제입니다. 이로 인해 워크플로우에 합병증이 발생할 수 있습니다.
- 소스 리포지토리의 파일 및 디렉토리를 컨테이너로 공유하는 것이 예상대로 작동하지 않을 수 있습니다. 볼륨 마운팅은 빌드 컨테이너가 아닌 호스트 머신의 컨텍스트에서 수행됩니다. 예를 들어:

  ```shell
  docker run --rm -t -i -v $(pwd)/src:/home/app/src test-image:latest run_app_tests
  ```

Docker-in-Docker 실행기를 사용할 때처럼 `docker:24.0.5-dind` 서비스를 포함할 필요가 없습니다:

```yaml
default:
  image: docker:24.0.5-cli
  before_script:
    - docker info

build:
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

[CodeClimate를 사용한 코드 품질 스캔](../testing/code_quality_codeclimate_scanning.md)과 같은 복잡한 Docker-in-Docker 설정의 경우 적절한 실행을 위해 호스트 및 컨테이너 경로를 일치시켜야 합니다. 자세한 내용은 [CodeClimate 기반 스캔용 개인 러너 사용](../testing/code_quality_codeclimate_scanning.md#use-private-runners)을 참조하세요.

### Docker 파이프 바인딩 사용 {#use-docker-pipe-binding}

Windows 컨테이너는 Windows Server 커널 및 사용자 영역(windowsservercore 또는 nanoserver)에 대해 컴파일된 Windows 실행 파일을 실행합니다. Windows 컨테이너를 빌드하고 실행하려면 컨테이너 지원이 있는 Windows 시스템이 필요합니다. 자세한 내용은 [Windows 컨테이너](https://learn.microsoft.com/en-us/virtualization/windowscontainers/)를 참조하세요.

Windows 컨테이너는 [Docker-in-Docker 접근 방식을 지원하지 않으므로](https://github.com/docker-library/docker/issues/49) 컨테이너 내에서 중첩된 Docker Engine을 실행할 수 없습니다. Windows 컨테이너 내에서 Docker 이미지를 빌드하거나 관리하려면 Docker 파이프 바인딩(Docker-outside-of-Docker 또는 DooD라고도 함)을 사용합니다.

> [!warning]
> Docker 파이프 바인딩에는 보안상의 함의가 있습니다. `\\\\.\\pipe\\docker_engine`를 바인드 마운트하면 컨테이너는 호스트의 Docker 데몬에 대한 전체 관리 액세스 권한을 갖습니다. 컨테이너 내의 프로세스는 다른 컨테이너를 시작 또는 중지하고, 이미지를 관리하며, 호스트 시스템에서 상승된 권한을 얻을 수 있습니다.

Docker 파이프 바인딩을 사용하려면 호스트 Windows Server 운영 체제에 Docker Engine을 설치하고 실행해야 합니다. 자세한 내용은 [Windows Server에 Docker Community Edition(CE) 설치](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-1)을 참조하세요.

Windows 기반 컨테이너 CI/CD 작업에서 Docker 명령을 사용하려면 `\\\\.\\pipe\\docker_engine`을 시작된 실행기 컨테이너에 바인드 마운트할 수 있습니다. Docker는 이미지의 컨텍스트에서 사용할 수 있습니다.

[Windows의 Docker 파이프 바인딩](#use-docker-pipe-binding)은 [Linux의 Docker 소켓 바인딩](#use-docker-socket-binding)과 유사하며 [Docker 소켓 바인딩의 알려진 이슈](#known-issues-with-docker-socket-binding)와 동일한 [알려진 이슈](#known-issues-with-docker-pipe-binding)를 갖습니다.

Docker 파이프 바인딩 사용의 필수 전제 조건은 호스트 Windows Server 운영 체제에 Docker Engine을 설치하고 실행하는 것입니다. 참조: [Windows Server에 Docker Community Edition(CE) 설치](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-2)

#### Docker 파이프 바인딩과 함께 Docker 실행기 사용 {#use-the-docker-executor-with-docker-pipe-binding}

[Docker 실행기](https://docs.gitlab.com/runner/executors/docker/)를 사용하여 Windows 기반 컨테이너에서 작업을 실행할 수 있습니다.

Docker 실행기로 Docker 파이프를 마운트하려면 `"\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"`을 [`[runners.docker]` 섹션의 볼륨](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section)에 추가합니다.

1. 러너를 등록할 때 `\\\\.\\pipe\\docker_engine`을 마운트하려면 다음 옵션을 포함합니다:

   ```powershell
   .\gitlab-runner.exe register \
     --non-interactive \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor "docker-windows" \
     --description "docker-windows-runner"
     --tag-list "docker-windows-runner" \
     --docker-image "docker:25-windowsservercore-ltsc2022" \
     --docker-volumes "\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"
   ```

   이전 명령은 다음 예시와 유사한 `config.toml` 항목을 생성합니다:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = RUNNER_TOKEN
     executor = "docker-windows"
     [runners.docker]
       tls_verify = false
       image = "docker:25-windowsservercore-ltsc2022"
       privileged = false
       disable_cache = false
       volumes = ["\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"]
   ```

1. 작업 스크립트에서 Docker를 사용합니다:

   ```yaml
   default:
     image: docker:25-windowsservercore-ltsc2022
     before_script:
       - docker version
       - docker info

   build:
     stage: build
     tags:
       - docker-windows-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Docker 파이프 바인딩과 함께 Kubernetes 실행기 사용 {#use-the-kubernetes-executor-with-docker-pipe-binding}

[Kubernetes 실행기](https://docs.gitlab.com/runner/executors/kubernetes/)를 사용하여 Windows 기반 컨테이너에서 작업을 실행할 수 있습니다.

Windows 기반 컨테이너에 Kubernetes 실행기를 사용하려면 Kubernetes 클러스터에 Windows 노드를 포함해야 합니다. 자세한 내용은 [Kubernetes의 Windows 컨테이너](https://kubernetes.io/docs/concepts/windows/intro/)를 참조하세요.

[Linux 환경에서 작동하지만 Windows 노드를 대상으로 하는 러너](https://docs.gitlab.com/runner/executors/kubernetes/#example-for-windowsamd64)를 사용할 수 있습니다.

Kubernetes 실행기로 Docker 파이프를 마운트하려면 `"\\.\pipe\docker_engine"`을 [`[[runners.kubernetes.volumes.host_path]]` 섹션의 볼륨](https://docs.gitlab.com/runner/executors/kubernetes/index/#hostpath-volume)에 추가합니다.

1. 볼륨 마운트를 지정하려면 [`values.yml` 파일](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)을 [Helm 차트](https://docs.gitlab.com/runner/install/kubernetes/)를 사용하여 업데이트합니다.

   ```yaml
   runners:
     tags: "kubernetes-windows-runner"
     config: |
       [[runners]]
         executor = "kubernetes"

         # The FF_USE_POWERSHELL_PATH_RESOLVER feature flag has to be enabled for PowerShell
         # to resolve paths for Windows correctly when Runner is operating in a Linux environment
         # but targeting Windows nodes.
         [runners.feature_flags]
           FF_USE_POWERSHELL_PATH_RESOLVER = true

         [runners.kubernetes]
           [[runners.kubernetes.volumes.host_path]]
             host_path = '\\\\.\\pipe\\docker_engine'
             mount_path = '\\\\.\\pipe\\docker_engine'
             name = 'docker-pipe'
             read_only = true

           [runners.kubernetes.node_selector]
             "kubernetes.io/arch" = "amd64"
             "kubernetes.io/os" = "windows"
             "node.kubernetes.io/windows-build" = "10.0.20348"
   ```

1. 작업 스크립트에서 Docker를 사용합니다:

   ```yaml
   default:
     image: docker:25-windowsservercore-ltsc2022
     before_script:
       - docker version
       - docker info

   build:
     stage: build
     tags:
       - kubernetes-windows-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

##### AWS EKS Kubernetes 클러스터의 알려진 이슈 {#known-issues-with-aws-eks-kubernetes-cluster}

`dockerd`에서 `containerd`로 마이그레이션할 때 AWS EKS 부트스트랩 스크립트 `Start-EKSBootstrap.ps1`는 Docker Service를 중지하고 비활성화합니다. 이 이슈를 해결하려면 [Windows Server에 Docker Community Edition(CE) 설치](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-1) 후 이 스크립트를 사용하여 Docker Service의 이름을 바꿉니다:

```powershell
Write-Output "Rename the just installed Docker Engine Service from docker to dockerd"
Write-Output "because the Start-EKSBootstrap.ps1 stops and disables the docker Service as part of migration from dockerd to containerd"
Stop-Service -Name docker
dockerd --register-service --service-name dockerd
Start-Service -Name dockerd
Write-Output "Ready to do Docker pipe binding on Windows EKS Node! :-)"
```

#### Docker 파이프 바인딩의 알려진 이슈 {#known-issues-with-docker-pipe-binding}

Docker 파이프 바인딩은 [Docker 소켓 바인딩의 알려진 이슈](#known-issues-with-docker-socket-binding)와 동일한 보안 및 격리 이슈 세트를 갖습니다.

## `docker:dind` 서비스에 대해 레지스트리 미러 활성화 {#enable-registry-mirror-for-dockerdind-service}

Docker 데몬이 서비스 컨테이너 내에서 시작되면 기본 구성을 사용합니다. [레지스트리 미러](https://docs.docker.com/docker-hub/mirror/)를 구성하여 성능을 향상시키고 Docker Hub 속도 제한을 초과하지 않도록 할 수 있습니다.

### `.gitlab-ci.yml` 파일의 서비스 {#the-service-in-the-gitlab-ciyml-file}

`dind` 서비스에 추가 CLI 플래그를 추가하여 레지스트리 미러를 설정할 수 있습니다:

```yaml
services:
  - name: docker:24.0.5-dind
    command: ["--registry-mirror", "https://registry-mirror.example.com"]  # Specify the registry mirror to use
```

### 러너 구성 파일의 서비스 {#the-service-in-the-gitlab-runner-configuration-file}

러너 관리자인 경우 `command`을 지정하여 Docker 데몬에 대한 레지스트리 미러를 구성할 수 있습니다. `dind` 서비스는 [Docker](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnersdockerservices-section) 또는 [Kubernetes 실행기](https://docs.gitlab.com/runner/executors/kubernetes/#define-a-list-of-services)에 대해 정의되어야 합니다.

Docker:

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    [[runners.docker.services]]
      name = "docker:24.0.5-dind"
      command = ["--registry-mirror", "https://registry-mirror.example.com"]
```

Kubernetes:

```toml
[[runners]]
  ...
  name = "kubernetes"
  [runners.kubernetes]
    ...
    privileged = true
    [[runners.kubernetes.services]]
      name = "docker:24.0.5-dind"
      command = ["--registry-mirror", "https://registry-mirror.example.com"]
```

### 러너 구성 파일의 Docker 실행기 {#the-docker-executor-in-the-gitlab-runner-configuration-file}

러너 관리자인 경우 모든 `dind` 서비스에 대해 미러를 사용할 수 있습니다. [구성](https://docs.gitlab.com/runner/configuration/advanced-configuration/)을 업데이트하여 [볼륨 마운트](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section)를 지정합니다.

예를 들어 다음 콘텐츠가 있는 `/opt/docker/daemon.json` 파일이 있는 경우:

```json
{
  "registry-mirrors": [
    "https://registry-mirror.example.com"
  ]
}
```

`config.toml` 파일을 업데이트하여 파일을 `/etc/docker/daemon.json`에 마운트합니다. 이것은 러너에서 생성한 **every** 컨테이너에 대해 파일을 마운트합니다. 구성은 `dind` 서비스에서 감지됩니다.

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    image = "alpine:3.12"
    privileged = true
    volumes = ["/opt/docker/daemon.json:/etc/docker/daemon.json:ro"]
```

### 러너 구성 파일의 Kubernetes 실행기 {#the-kubernetes-executor-in-the-gitlab-runner-configuration-file}

러너 관리자인 경우 모든 `dind` 서비스에 대해 미러를 사용할 수 있습니다. [구성](https://docs.gitlab.com/runner/configuration/advanced-configuration/)을 업데이트하여 [ConfigMap 볼륨 마운트](https://docs.gitlab.com/runner/executors/kubernetes/#configmap-volume)를 지정합니다.

예를 들어 다음 콘텐츠가 있는 `/tmp/daemon.json` 파일이 있는 경우:

```json
{
  "registry-mirrors": [
    "https://registry-mirror.example.com"
  ]
}
```

이 파일의 콘텐츠를 사용하여 [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/)을 생성합니다. 다음과 같은 명령으로 이를 수행할 수 있습니다:

```shell
kubectl create configmap docker-daemon --namespace gitlab-runner --from-file /tmp/daemon.json
```

> [!note]
> Kubernetes 실행기가 작업 포드를 생성하는 데 사용하는 네임스페이스를 사용해야 합니다.

ConfigMap이 생성된 후 `config.toml` 파일을 업데이트하여 파일을 `/etc/docker/daemon.json`에 마운트할 수 있습니다. 이 업데이트는 러너에서 생성한 **every** 컨테이너에 대해 파일을 마운트합니다. `dind` 서비스가 이 구성을 감지합니다.

```toml
[[runners]]
  ...
  executor = "kubernetes"
  [runners.kubernetes]
    image = "alpine:3.12"
    privileged = true
    [[runners.kubernetes.volumes.config_map]]
      name = "docker-daemon"
      mount_path = "/etc/docker/daemon.json"
      sub_path = "daemon.json"
```

## Docker-in-Docker에서 레지스트리 인증 {#authenticate-with-registry-in-docker-in-docker}

Docker-in-Docker를 사용할 때 새로운 Docker 데몬이 서비스와 함께 시작되므로 [표준 인증 방법](using_docker_images.md#access-an-image-from-a-private-container-registry)은 작동하지 않습니다. [레지스트리 인증](authenticate_registry.md)을 해야 합니다.

## Docker 레이어 캐싱 {#docker-layer-caching}

Docker 레이어를 캐싱하여 빌드 속도를 높일 수 있습니다. 자세한 내용은 [Docker-in-Docker 빌드에서 Docker 레이어 캐싱](docker_layer_caching.md)을 참조하세요.

## OverlayFS 드라이버 사용 {#use-the-overlayfs-driver}

> [!note]
> GitLab.com의 인스턴스 러너는 기본적으로 `overlay2` 드라이버를 사용합니다.

기본적으로 `docker:dind`을 사용할 때 Docker는 `vfs` 스토리지 드라이버를 사용하며, 이는 모든 실행에 대해 파일 시스템을 복사합니다. 다른 드라이버(예: `overlay2`)를 사용하여 이 디스크 집약적인 작업을 방지할 수 있습니다.

### 요구사항 {#requirements}

1. 최근 커널(가능하면 `>= 4.2`)을 사용하는지 확인합니다.
1. `overlay` 모듈이 로드되었는지 확인합니다:

   ```shell
   sudo lsmod | grep overlay
   ```

   결과가 표시되지 않으면 모듈이 로드되지 않은 것입니다. 모듈을 로드하려면 다음을 사용합니다:

   ```shell
   sudo modprobe overlay
   ```

   모듈이 로드된 경우 재부팅 시 모듈이 로드되는지 확인해야 합니다. Ubuntu 시스템에서는 다음 줄을 `/etc/modules`에 추가하여 이를 수행합니다:

   ```plaintext
   overlay
   ```

### 프로젝트별 OverlayFS 드라이버 사용 {#use-the-overlayfs-driver-per-project}

`DOCKER_DRIVER`[CI/CD 변수](../yaml/_index.md#variables)를 사용하여 `.gitlab-ci.yml`에서 각 프로젝트에 대해 개별적으로 드라이버를 활성화할 수 있습니다:

```yaml
variables:
  DOCKER_DRIVER: overlay2
```

### 모든 프로젝트에 대해 OverlayFS 드라이버 사용 {#use-the-overlayfs-driver-for-every-project}

자신의 [러너](https://docs.gitlab.com/runner/)를 사용하는 경우 `DOCKER_DRIVER` 환경 변수를 [`config.toml` 파일의 `[[runners]]` 섹션](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)에서 설정하여 모든 프로젝트에 대해 드라이버를 활성화할 수 있습니다:

```toml
environment = ["DOCKER_DRIVER=overlay2"]
```

여러 러너를 실행하는 경우 모든 구성 파일을 수정해야 합니다.

[러너 구성](https://docs.gitlab.com/runner/configuration/) 및 [OverlayFS 스토리지 드라이버 사용](https://docs.docker.com/storage/storagedriver/overlayfs-driver/)에 대해 자세히 알아보세요.

## Docker 대체 방법 {#docker-alternatives}

러너에서 권한 있는 모드를 활성화하지 않고 컨테이너 이미지를 빌드할 수 있습니다:

- [BuildKit](using_buildkit.md): Docker 데몬 종속성을 제거하는 루트리스 BuildKit 옵션을 포함합니다.
- [Buildah](#buildah-example): Docker 데몬을 필요로 하지 않고 OCI 호환 이미지를 빌드합니다.

### Buildah 예시 {#buildah-example}

GitLab CI/CD와 함께 Buildah를 사용하려면 다음 실행기 중 하나를 사용하는 [러너](https://docs.gitlab.com/runner/)가 필요합니다:

- [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/).
- [Docker](https://docs.gitlab.com/runner/executors/docker/).
- [Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine/).

이 예시에서는 Buildah를 사용하여 다음을 수행합니다:

1. Docker 이미지를 빌드합니다.
1. [GitLab 컨테이너 레지스트리](../../user/packages/container_registry/_index.md)에 푸시합니다.

마지막 단계에서 Buildah는 프로젝트의 루트 디렉토리 아래의 `Dockerfile`을 사용하여 Docker 이미지를 빌드합니다. 마지막으로 이미지를 프로젝트의 컨테이너 레지스트리에 푸시합니다:

```yaml
build:
  stage: build
  image: quay.io/buildah/stable
  variables:
    # Use vfs with buildah. Docker offers overlayfs as a default, but Buildah
    # cannot stack overlayfs on top of another overlayfs filesystem.
    STORAGE_DRIVER: vfs
    # Write all image metadata in the docker format, not the standard OCI format.
    # Newer versions of docker can handle the OCI format, but older versions, like
    # the one shipped with Fedora 30, cannot handle the format.
    BUILDAH_FORMAT: docker
    FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE/test"
  before_script:
    # GitLab container registry credentials taken from the
    # [predefined CI/CD variables](../variables/_index.md#predefined-cicd-variables)
    # to authenticate to the registry.
    - echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY
  script:
    - buildah images
    - buildah build -t $FQ_IMAGE_NAME
    - buildah images
    - buildah push $FQ_IMAGE_NAME
```

OpenShift 클러스터에 배포된 GitLab Runner Operator를 사용하는 경우 [루트리스 컨테이너에서 Buildah를 사용하여 이미지를 빌드하는 방법에 대한 튜토리얼](buildah_rootless_tutorial.md)을 시도해보세요.

## GitLab 컨테이너 레지스트리 사용 {#use-the-gitlab-container-registry}

Docker 이미지를 빌드한 후 [GitLab 컨테이너 레지스트리](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd)에 푸시할 수 있습니다.

## 문제 해결 {#troubleshooting}

### `open //./pipe/docker_engine: The system cannot find the file specified` {#open-pipedocker_engine-the-system-cannot-find-the-file-specified}

다음 오류는 PowerShell 스크립트에서 `docker` 명령을 실행하여 마운트된 Docker 파이프에 액세스할 때 나타날 수 있습니다:

```powershell
PS C:\> docker version
Client:
 Version:           25.0.5
 API version:       1.44
 Go version:        go1.21.8
 Git commit:        5dc9bcc
 Built:             Tue Mar 19 15:06:12 2024
 OS/Arch:           windows/amd64
 Context:           default
error during connect: this error may indicate that the docker daemon is not running: Get "http://%2F%2F.%2Fpipe%2Fdocker_engine/v1.44/version": open //./pipe/docker_engine: The system cannot find the file specified.
```

이 오류는 Docker Engine이 Windows EKS 노드에서 실행되지 않고 있으며 Docker 파이프 바인딩을 Windows 기반 실행기 컨테이너에서 사용할 수 없음을 나타냅니다.

문제를 해결하려면 [Docker 파이프 바인딩과 함께 Kubernetes 실행기 사용](#use-the-kubernetes-executor-with-docker-pipe-binding)에서 설명하는 해결 방법을 사용합니다.
