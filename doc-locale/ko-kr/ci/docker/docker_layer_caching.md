---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page,
  see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 인라인 또는 레지스트리 캐시 백엔드를 사용하여 파이프라인 실행 간에 이미지 레이어를 캐싱하여 Docker-in-Docker 빌드를 가속화합니다.
title: Docker-in-Docker 빌드에서 Docker 레이어 캐싱
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Docker-in-Docker를 사용할 때 Docker는 매번 빌드할 때마다 이미지의 모든 레이어를 다운로드합니다. Docker 1.13 이상은 `docker build` 단계에서 캐시로 기존 이미지를 사용할 수 있으며, 이는 빌드 프로세스를 크게 가속화합니다.

Docker가 `docker build`을 실행하면 각 `Dockerfile` 명령이 레이어를 생성합니다. Docker는 이러한 레이어를 캐시로 유지하고 변경 사항이 없으면 재사용합니다. 한 레이어의 변경으로 인해 모든 후속 레이어가 다시 빌드됩니다. 태그된 이미지를 `docker build`의 캐시 소스로 사용하려면 `--cache-from` 인수를 전달합니다. 여러 캐시 소스를 지정하려면 `--cache-from`을 여러 번 사용합니다.

## 전제 조건 {#prerequisites}

Docker 27.0.1 이상에서는 기본 `docker` 빌드 드라이버가 `containerd` 이미지 저장소가 활성화된 경우에만 캐시 백엔드를 지원합니다. 다음 중 하나를 수행합니다:

- Docker 데몬 구성에서 `containerd` 이미지 저장소를 활성화합니다.
- 다른 빌드 드라이버를 선택합니다.

## 인라인 캐싱 사용 {#use-inline-caching}

기본 `docker build` 명령과 함께 `inline` 캐시 백엔드를 사용합니다. 캐싱을 시작하는 가장 간단한 방법입니다. 캐시는 이미지 자체 내에 저장되며 별도의 캐시 이미지가 필요하지 않습니다. 복잡한 빌드 플로우나 다단계 빌드의 경우 대신 [레지스트리 캐싱](#use-registry-caching)을 사용합니다. 자세한 내용은 [인라인 캐싱 옵션](https://docs.docker.com/build/cache/backends/inline/)을 참조하세요.

> [!note]
> `--build-arg BUILDKIT_INLINE_CACHE=1` 인수는 필수입니다. 이는 Docker에 캐시 메타데이터를 이미지에 임베드하도록 지시하여 후속 빌드가 `--cache-from`을 사용하여 캐시 소스로 사용할 수 있도록 합니다. 이 인수가 없으면 캐싱이 조용히 실패합니다.

파이프라인에서 인라인 캐싱을 사용하려면:

1. 프로젝트에 다음 `.gitlab-ci.yml` 구성을 추가합니다:

   ```yaml
   default:
     image: docker:27.4.1-cli
     services:
       - docker:27.4.1-dind
     before_script:
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

   variables:
     # Use TLS https://docs.gitlab.com/ci/docker/using_docker_build/#tls-enabled
     DOCKER_HOST: tcp://docker:2376
     DOCKER_TLS_CERTDIR: "/certs"

   build:
     stage: build
     script:
       - docker pull $CI_REGISTRY_IMAGE:latest || true
       - docker build --build-arg BUILDKIT_INLINE_CACHE=1 --cache-from $CI_REGISTRY_IMAGE:latest
         --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
       - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
       - docker push $CI_REGISTRY_IMAGE:latest
   ```

   `build` 작업 `script`에서:

   - 첫 번째 명령은 레지스트리에서 이미지를 캐시 소스로 사용하기 위해 가져오려고 시도합니다. `--cache-from`과 함께 사용되는 모든 이미지는 사용하기 전에 `docker pull`로 가져와야 합니다.
   - 두 번째 명령은 가져온 이미지를 캐시로 사용하여 Docker 이미지를 빌드한 다음(`--cache-from $CI_REGISTRY_IMAGE:latest` 통해) 태그를 지정합니다. `--build-arg BUILDKIT_INLINE_CACHE=1` 플래그는 빌드 캐시를 이미지에 임베드합니다.
   - 마지막 두 명령은 두 개의 태그된 이미지를 컨테이너 레지스트리로 푸시하여 향후 빌드에서 캐시로 사용할 수 있도록 합니다.

## 레지스트리 캐싱 사용 {#use-registry-caching}

`docker buildx build`와 함께 `registry` 캐시 백엔드를 사용하여 애플리케이션 이미지와 별도의 전용 캐시 이미지에 빌드 캐시를 저장합니다. 이는 다단계 빌드 및 복잡한 빌드 플로우에서 인라인 캐싱보다 더 잘 확장됩니다. 자세한 내용은 [캐시 백엔드 옵션](https://docs.docker.com/build/cache/backends/)을 참조하세요.

파이프라인에서 레지스트리 캐싱을 사용하려면:

1. 프로젝트에 다음 `.gitlab-ci.yml` 구성을 추가합니다:

   ```yaml
   default:
     image: docker:27.4.1-cli
     services:
       - docker:27.4.1-dind
     before_script:
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

   variables:
     # Use TLS https://docs.gitlab.com/ci/docker/using_docker_build/#tls-enabled
     DOCKER_HOST: tcp://docker:2376
     DOCKER_TLS_CERTDIR: "/certs"

   build:
     stage: build
     script:
       - docker context create my-builder
       - docker buildx create my-builder --driver docker-container --use
       - docker buildx build --push -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
         --cache-to type=registry,ref=$CI_REGISTRY_IMAGE/cache-image,mode=max
         --cache-from type=registry,ref=$CI_REGISTRY_IMAGE/cache-image .
   ```

   `build` 작업 `script`에서:

   - 처음 두 명령은 `docker-container` BuildKit 드라이버를 생성 및 구성하며, 이는 `registry` 캐시 백엔드를 지원합니다.
   - 세 번째 명령은 Docker 이미지를 빌드하고 푸시합니다. `--cache-from`을 사용하여 전용 캐시 이미지에서 읽고 `--cache-to`로 업데이트합니다. `max` 모드는 모든 중간 레이어를 캐시합니다.
