---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Docker 빌드 문제 해결
---

## 오류: `docker: Cannot connect to the Docker daemon at tcp://docker:2375` {#error-docker-cannot-connect-to-the-docker-daemon-at-tcpdocker2375}

이 오류는 [Docker-in-Docker](using_docker_build.md#use-docker-in-docker) v19.03 이상을 사용할 때 일반적입니다:

```plaintext
docker: Cannot connect to the Docker daemon at tcp://docker:2375. Is the docker daemon running?
```

이 오류는 Docker가 TLS를 자동으로 시작하기 때문에 발생합니다.

- 처음 설정하는 경우 [Docker 이미지와 함께 Docker 실행기 사용](using_docker_build.md#use-docker-in-docker)을 참조하세요.
- v18.09 이전 버전에서 업그레이드하는 경우 [업그레이드 가이드](https://about.gitlab.com/blog/docker-in-docker-with-docker-19-dot-03/)를 참조하세요.

이 오류는 [Kubernetes 실행기](https://docs.gitlab.com/runner/executors/kubernetes/#using-dockerdind)와 함께 Docker-in-Docker 서비스에 완전히 시작되기 전에 액세스하려고 할 때도 발생할 수 있습니다. 자세한 설명은 [이슈 27215](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27215)를 참조하세요.

## Docker `no such host` 오류 {#docker-no-such-host-error}

`docker: error during connect: Post https://docker:2376/v1.40/containers/create: dial tcp: lookup docker on x.x.x.x:53: no such host`라는 오류가 나타날 수 있습니다.

이 이슈는 서비스의 이미지 이름이 [레지스트리 호스트 이름을 포함](../services/_index.md#available-settings-for-services)할 때 발생할 수 있습니다. 예를 들어:

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - registry.hub.docker.com/library/docker:24.0.5-dind
```

서비스의 호스트 이름은 [전체 이미지 이름에서 파생됩니다](../services/_index.md#accessing-the-services). 하지만 더 짧은 서비스 호스트 이름 `docker`이(가) 예상됩니다. 서비스 해석 및 액세스를 허용하려면 서비스 이름 `docker`에 대한 명시적 별칭을 추가하세요:

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - name: registry.hub.docker.com/library/docker:24.0.5-dind
      alias: docker
```

## 오류: `Cannot connect to the Docker daemon at unix:///var/run/docker.sock` {#error-cannot-connect-to-the-docker-daemon-at-unixvarrundockersock}

`docker` 명령을 실행하여 `dind` 서비스에 액세스하려고 할 때 다음과 같은 오류가 나타날 수 있습니다:

```shell
$ docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

작업이 다음 환경 변수를 정의했는지 확인하세요:

- `DOCKER_HOST`
- `DOCKER_TLS_CERTDIR` (선택 사항)
- `DOCKER_TLS_VERIFY` (선택 사항)

Docker 클라이언트를 제공하는 이미지를 업데이트할 수도 있습니다. 예를 들어 [`docker/compose` 이미지는 더 이상 사용되지 않으며](https://hub.docker.com/r/docker/compose) [`docker`](https://hub.docker.com/_/docker)로 교체해야 합니다.

[러너 이슈 30944](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30944#note_1514250909)에 설명된 대로, 작업이 이전에 [Docker `--link` 매개변수](https://docs.docker.com/network/links/#environment-variables)에서 파생된 환경 변수(예: `DOCKER_PORT_2375_TCP`)에 의존했을 경우 이 오류가 발생할 수 있습니다. 다음 조건에서 작업이 이 오류로 인해 실패합니다:

- CI/CD 이미지가 `DOCKER_PORT_2375_TCP`과(와) 같은 레거시 변수에 의존합니다.
- [러너 기능 플래그 `FF_NETWORK_PER_BUILD`](https://docs.gitlab.com/runner/configuration/feature-flags/)이(가) `true`로 설정되었습니다.
- `DOCKER_HOST`이(가) 명시적으로 설정되지 않았습니다.

## 오류: `unauthorized: incorrect username or password` {#error-unauthorized-incorrect-username-or-password}

이 오류는 더 이상 사용되지 않는 변수 `CI_BUILD_TOKEN`을(를) 사용할 때 나타납니다:

```plaintext
Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized: incorrect username or password
```

사용자가 이 오류를 받지 않도록 하려면 다음을 수행해야 합니다:

- 대신 [CI_JOB_TOKEN](../jobs/ci_job_token.md)을(를) 사용하세요.
- `gitlab-ci-token/CI_BUILD_TOKEN`에서 `$CI_REGISTRY_USER/$CI_REGISTRY_PASSWORD`로 변경하세요.

## 연결 중 오류: `no such host` {#error-during-connect-no-such-host}

이 오류는 `dind` 서비스 시작에 실패했을 때 나타납니다:

```plaintext
error during connect: Post "https://docker:2376/v1.24/auth": dial tcp: lookup docker on 127.0.0.11:53: no such host
```

`mount: permission denied (are you root?)`이(가) 나타나는지 확인하려면 작업 로그를 확인하세요. 예를 들어:

```plaintext
Service container logs:
2023-08-01T16:04:09.541703572Z Certificate request self-signature ok
2023-08-01T16:04:09.541770852Z subject=CN = docker:dind server
2023-08-01T16:04:09.556183222Z /certs/server/cert.pem: OK
2023-08-01T16:04:10.641128729Z Certificate request self-signature ok
2023-08-01T16:04:10.641173149Z subject=CN = docker:dind client
2023-08-01T16:04:10.656089908Z /certs/client/cert.pem: OK
2023-08-01T16:04:10.659571093Z ip: can't find device 'ip_tables'
2023-08-01T16:04:10.660872131Z modprobe: can't change directory to '/lib/modules': No such file or directory
2023-08-01T16:04:10.664620455Z mount: permission denied (are you root?)
2023-08-01T16:04:10.664692175Z Could not mount /sys/kernel/security.
2023-08-01T16:04:10.664703615Z AppArmor detection and --privileged mode might break.
2023-08-01T16:04:10.665952353Z mount: permission denied (are you root?)
```

이는 러너가 `dind` 서비스를 시작할 권한이 없음을 나타냅니다:

1. `privileged = true`이(가) `config.toml`에 설정되어 있는지 확인하세요.
1. CI 작업이 이러한 권한이 있는 러너를 사용할 수 있는 올바른 러너 태그를 가지고 있는지 확인하세요.

## 오류: `cgroups: cgroup mountpoint does not exist: unknown` {#error-cgroups-cgroup-mountpoint-does-not-exist-unknown}

Docker Engine 20.10으로 인해 알려진 호환성 문제가 있습니다.

호스트가 Docker Engine 20.10 이상을 사용할 때 20.10보다 오래된 버전의 `docker:dind` 서비스는 예상대로 작동하지 않습니다.

서비스 자체는 문제 없이 시작되지만 컨테이너 이미지를 빌드하려고 하면 다음 오류가 발생합니다:

```plaintext
cgroups: cgroup mountpoint does not exist: unknown
```

이 이슈를 해결하려면 `docker:dind` 컨테이너를 최소 20.10.x 버전으로 업데이트하세요. 예: `docker:24.0.5-dind`.

반대 구성(`docker:24.0.5-dind` 서비스 및 호스트의 Docker Engine 버전 19.06.x 이상)은 문제 없이 작동합니다. 최적의 전략을 위해 작업 환경 버전을 자주 테스트하고 최신 버전으로 업데이트해야 합니다. 이는 새로운 기능, 향상된 보안을 제공하며, 특히 이 경우 러너 호스트의 기본 Docker Engine 업그레이드를 작업에 투명하게 만듭니다.

## 오류: `failed to verify certificate: x509: certificate signed by unknown authority` {#error-failed-to-verify-certificate-x509-certificate-signed-by-unknown-authority}

이 오류는 Docker-in-Docker 환경에서 `docker build` 또는 `docker pull`과(와) 같은 Docker 명령이 실행될 때 나타날 수 있습니다. 여기서 사용자 지정 또는 프라이빗 인증서(예: Zscaler 인증서)가 사용됩니다:

```plaintext
error pulling image configuration: download failed after attempts=6: tls: failed to verify certificate: x509: certificate signed by unknown authority
```

이 오류는 Docker-in-Docker 환경의 Docker 명령이 두 개의 별도 컨테이너를 사용하기 때문에 발생합니다:

- **build container**는 Docker 클라이언트(`/usr/bin/docker`)를 실행하고 작업의 스크립트 명령을 실행합니다.
- **service container**(종종 `svc`라고 명명됨)는 대부분의 Docker 명령을 처리하는 Docker 데몬을 실행합니다.

조직이 사용자 지정 인증서를 사용할 때 두 컨테이너 모두 이러한 인증서가 필요합니다. 두 컨테이너에서 적절한 인증서 구성이 없으면 외부 레지스트리 또는 서비스에 연결되는 Docker 작업이 인증서 오류로 인해 실패합니다.

이 이슈를 해결하려면:

1. 루트 인증서를 [CI/CD 변수](../variables/_index.md#define-a-cicd-variable-in-the-ui)로 `CA_CERTIFICATE`라는 이름으로 저장하세요. 인증서는 다음 형식이어야 합니다:

   ```plaintext
   -----BEGIN CERTIFICATE-----
   (certificate content)
   -----END CERTIFICATE-----
   ```

1. Docker 데몬을 시작하기 전에 서비스 컨테이너에 인증서를 설치하도록 파이프라인을 구성하세요. 예를 들어:

   ```yaml
   image_build:
     stage: build
     image:
       name: docker:19.03
     variables:
       DOCKER_HOST: tcp://localhost:2375
       DOCKER_TLS_CERTDIR: ""
       CA_CERTIFICATE: "$CA_CERTIFICATE"
     services:
       - name: docker:19.03-dind
         command:
           - /bin/sh
           - -c
           - |
             echo "$CA_CERTIFICATE" > /usr/local/share/ca-certificates/custom-ca.crt && \
             update-ca-certificates && \
             dockerd-entrypoint.sh || exit
     script:
       - docker info
       - docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $DOCKER_REGISTRY
       - docker build -t "${DOCKER_REGISTRY}/my-app:${CI_COMMIT_REF_NAME}" .
       - docker push "${DOCKER_REGISTRY}/my-app:${CI_COMMIT_REF_NAME}"
   ```
