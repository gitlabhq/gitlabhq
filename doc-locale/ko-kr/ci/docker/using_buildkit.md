---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: BuildKit을 사용하여 Docker 이미지 빌드
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[BuildKit](https://docs.docker.com/build/buildkit/)은 Docker에서 사용하는 빌드 엔진이며 다중 플랫폼 빌드와 빌드 캐싱을 제공합니다.

## BuildKit 방법 {#buildkit-methods}

BuildKit은 Docker 이미지를 빌드하기 위해 다음 방법을 제공합니다:

| 방법            | 보안 요구 사항     | 명령어                 | 사용할 상황 |
| ----------------- | ------------------------ | ------------------------ | ----------------- |
| BuildKit rootless | 권한 있는 컨테이너 없음 | `buildctl-daemonless.sh` | 최대 보안 또는 Kaniko의 대체 솔루션 |
| Docker Buildx     | `docker:dind`이 필요함   | `docker buildx`          | 익숙한 Docker 워크플로우 |
| 네이티브 BuildKit   | `docker:dind`이 필요함   | `buildctl`               | 고급 BuildKit 제어 |

## 전제 조건 {#prerequisites}

- Docker 실행기가 있는 러너
- Docker Buildx를 사용하기 위해 Docker 19.03 이상
- `Dockerfile`이 포함된 프로젝트

## BuildKit rootless {#buildkit-rootless}

독립 실행형 모드의 BuildKit은 Docker 데몬 종속성 없이 rootless 이미지 빌드를 제공합니다. 이 방법은 권한 있는 컨테이너를 완전히 제거하고 Kaniko 빌드의 직접적인 대체를 제공합니다.

다른 방법과의 주요 차이점:

- `moby/buildkit:rootless` 이미지를 사용합니다
- rootless 작업을 위해 `BUILDKITD_FLAGS: --oci-worker-no-process-sandbox`을 포함합니다
- `buildctl-daemonless.sh`을 사용하여 BuildKit 데몬을 자동으로 관리합니다
- Docker 데몬 또는 권한 있는 컨테이너 종속성 없음
- 수동 레지스트리 인증 설정 필요

### 컨테이너 레지스트리로 인증 {#authenticate-with-container-registries}

GitLab CI/CD는 사전 정의된 변수를 통해 GitLab 컨테이너 레지스트리에 대한 자동 인증을 제공합니다. BuildKit rootless의 경우 Docker 설정 파일을 수동으로 만들어야 합니다.

#### GitLab 컨테이너 레지스트리로 인증 {#authenticate-with-the-gitlab-container-registry}

GitLab은 자동으로 이러한 사전 정의된 변수를 제공합니다:

- `CI_REGISTRY`: 레지스트리 URL
- `CI_REGISTRY_USER`: 레지스트리 사용자 이름
- `CI_REGISTRY_PASSWORD`: 레지스트리 비밀번호

rootless 빌드에 대한 인증을 구성하려면 작업에 `before_script` 설정을 추가하세요. 예를 들어:

```yaml
before_script:
  - mkdir -p ~/.docker
  - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
```

#### 여러 레지스트리로 인증 {#authenticate-with-multiple-registries}

추가 컨테이너 레지스트리로 인증하려면 `before_script` 섹션에서 인증 항목을 결합하세요. 예를 들어:

```yaml
before_script:
  - mkdir -p ~/.docker
  - |
    echo "{
      \"auths\": {
        \"${CI_REGISTRY}\": {
          \"auth\": \"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"
        },
        \"docker.io\": {
          \"auth\": \"$(printf "%s:%s" "${DOCKER_HUB_USER}" "${DOCKER_HUB_PASSWORD}" | base64 | tr -d '\n')\"
        }
      }
    }" > ~/.docker/config.json
```

#### 종속성 프록시로 인증 {#authenticate-with-the-dependency-proxy}

GitLab 종속성 프록시를 통해 이미지를 가져오려면 `before_script` 섹션에서 인증을 구성하세요. 예를 들어:

```yaml
before_script:
  - mkdir -p ~/.docker
  - |
    echo "{
      \"auths\": {
        \"${CI_REGISTRY}\": {
          \"auth\": \"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"
        },
        \"$(echo -n $CI_DEPENDENCY_PROXY_SERVER | awk -F[:] '{print $1}')\": {
          \"auth\": \"$(printf "%s:%s" ${CI_DEPENDENCY_PROXY_USER} "${CI_DEPENDENCY_PROXY_PASSWORD}" | base64 | tr -d '\n')\"
        }
      }
    }" > ~/.docker/config.json
```

자세한 내용은 [CI/CD 내에서 인증](../../user/packages/dependency_proxy/_index.md#authenticate-within-cicd)을 참조하세요.

### rootless 모드에서 이미지 빌드 {#build-images-in-rootless-mode}

Docker 데몬 종속성 없이 이미지를 빌드하려면 다음과 같은 작업을 추가하세요:

```yaml
build-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### rootless 모드에서 다중 플랫폼 이미지 빌드 {#build-multi-platform-images-in-rootless-mode}

rootless 모드에서 여러 아키텍처에 대한 이미지를 빌드하려면 대상 플랫폼을 지정하도록 작업을 구성하세요. 예를 들어:

```yaml
build-multiarch-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --opt platform=linux/amd64,linux/arm64 \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### rootless 모드에서 캐싱 사용 {#use-caching-in-rootless-mode}

더 빠른 후속 빌드를 위해 레지스트리 기반 캐싱을 사용하려면 빌드 작업에서 캐시 가져오기 및 내보내기를 구성하세요. 예를 들어:

```yaml
build-cached-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
    CACHE_IMAGE: $CI_REGISTRY_IMAGE:cache
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --export-cache type=registry,ref=$CACHE_IMAGE \
        --import-cache type=registry,ref=$CACHE_IMAGE \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### rootless 모드에서 레지스트리 미러 사용 {#use-a-registry-mirror-in-rootless-mode}

레지스트리 미러는 더 빠른 이미지 가져오기를 제공하며 속도 제한 또는 네트워크 제한을 완화할 수 있습니다.

레지스트리 미러를 구성하려면 미러 엔드포인트를 지정하는 `buildkit.toml` 파일을 만드세요. 예를 들어:

```yaml
build-mirror-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox --config /tmp/buildkit.toml
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
    - cat <<'EOF' > /tmp/buildkit.toml
      [registry."docker.io"]
        mirrors = ["mirror.example.com"]
      EOF
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

이 예제에서 `mirror.example.com`을 레지스트리 미러 URL로 바꾸세요.

### 프록시 설정 구성 {#configure-proxy-settings}

러너가 HTTP(S) 프록시 뒤에서 작동하는 경우 작업의 변수로 프록시 설정을 구성하세요. 예를 들어:

```yaml
build-behind-proxy:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
    http_proxy: <your-proxy>
    https_proxy: <your-proxy>
    no_proxy: <your-no-proxy>
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --build-arg http_proxy=$http_proxy \
        --build-arg https_proxy=$https_proxy \
        --build-arg no_proxy=$no_proxy \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

이 예제에서 `<your-proxy>`과 `<your-no-proxy>`을 프록시 설정으로 바꾸세요.

### 사용자 정의 인증서 추가 {#add-custom-certificates}

사용자 정의 CA 인증서를 사용하여 레지스트리에 푸시하려면 빌드하기 전에 컨테이너의 인증서 저장소에 인증서를 추가하세요. 예를 들어:

```yaml
build-with-custom-certs:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - export SSL_CERT_FILE="$HOME/ca_chain.pem"
    - cat /etc/ssl/certs/ca-certificates.crt > "$SSL_CERT_FILE"
    - echo "$MY_CA_CERT" >> "$SSL_CERT_FILE"
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

이 예제에서 `MY_CA_CERT` 변수를 루트 및 모든 중간 인증서를 포함한 CA 인증서의 전체 내용으로 채우세요.

## Kaniko에서 BuildKit으로 마이그레이션 {#migrate-from-kaniko-to-buildkit}

BuildKit rootless는 Kaniko의 보안 대체입니다. rootless 작업을 유지하면서 향상된 성능, 더 나은 캐싱, 향상된 보안 기능을 제공합니다.

### 설정 업데이트 {#update-your-configuration}

기존 Kaniko 구성을 업데이트하여 BuildKit rootless 방법을 사용하세요. 예를 들어:

이전, Kaniko 사용:

```yaml
build:
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - /kaniko/executor
      --context $CI_PROJECT_DIR
      --dockerfile $CI_PROJECT_DIR/Dockerfile
      --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

이후, BuildKit rootless 사용:

```yaml
build:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

## 대체 BuildKit 방법 {#alternative-buildkit-methods}

rootless 빌드가 필요하지 않은 경우 BuildKit은 `docker:dind` 서비스가 필요하지만 익숙한 워크플로우 또는 고급 기능을 제공하는 추가 방법을 제공합니다.

### Docker Buildx {#docker-buildx}

Docker Buildx는 BuildKit 기능으로 Docker 빌드 기능을 확장하면서 익숙한 명령 구문을 유지합니다. 이 방법은 `docker:dind` 서비스가 필요합니다.

#### 기본 이미지 빌드 {#build-basic-images}

Buildx를 사용하여 Docker 이미지를 빌드하려면 `docker:dind` 서비스로 작업을 구성하고 `buildx` 빌더를 만드세요. 예를 들어:

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-image:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name builder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --push .
  after_script:
    - docker buildx rm builder
```

#### 다중 플랫폼 이미지 빌드 {#build-multi-platform-images}

다중 플랫폼 빌드는 단일 빌드 명령으로 다양한 아키텍처에 대한 이미지를 만듭니다. 결과 매니페스트는 여러 아키텍처를 지원하며 Docker는 각 배포 대상에 대해 적절한 이미지를 자동으로 선택합니다.

여러 아키텍처에 대한 이미지를 빌드하려면 대상 아키텍처를 지정할 `--platform` 플래그를 추가하세요. 예를 들어:

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-multiplatform:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name multibuilder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build
        --platform linux/amd64,linux/arm64
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        --push .
  after_script:
    - docker buildx rm multibuilder
```

#### 빌드 캐싱 사용 {#use-build-caching}

레지스트리 기반 캐싱은 빌드 레이어를 컨테이너 레지스트리에 저장하여 빌드 전체에서 재사용합니다.

`mode=max` 옵션은 모든 레이어를 캐시로 내보내고 후속 빌드의 최대 재사용 잠재력을 제공합니다.

빌드 캐싱을 사용하려면 빌드 명령에 캐시 옵션을 추가하세요. 예를 들어:

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"
  CACHE_IMAGE: $CI_REGISTRY_IMAGE:cache

build-with-cache:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name cached-builder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build
        --cache-from type=registry,ref=$CACHE_IMAGE
        --cache-to type=registry,ref=$CACHE_IMAGE,mode=max
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        --push .
  after_script:
    - docker buildx rm cached-builder
```

### 네이티브 BuildKit {#native-buildkit}

빌드 프로세스를 더 많이 제어하려면 네이티브 BuildKit `buildctl` 명령을 사용하세요. 이 방법은 `docker:dind` 서비스가 필요합니다.

BuildKit을 직접 사용하려면 BuildKit 이미지 및 `docker:dind` 서비스로 작업을 구성하세요. 예를 들어:

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-with-buildkit:
  image: moby/buildkit:latest
  services:
    - docker:dind
  stage: build
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

## 문제 해결 {#troubleshooting}

### 인증 오류로 빌드 실패 {#build-fails-with-authentication-errors}

레지스트리 인증 실패가 발생한 경우:

- `CI_REGISTRY_USER` 및 `CI_REGISTRY_PASSWORD` 변수를 사용할 수 있는지 확인합니다.
- 대상 레지스트리에 푸시 권한이 있는지 확인합니다.
- 외부 레지스트리의 경우 프로젝트의 CI/CD 변수에서 인증 자격 증명이 올바르게 구성되어 있는지 확인합니다.

### Rootless 빌드가 권한 오류로 실패 {#rootless-build-fails-with-permission-errors}

rootless 모드의 권한 관련 이슈의 경우:

- `BUILDKITD_FLAGS: --oci-worker-no-process-sandbox`이 설정되어 있는지 확인하세요.
- 러너에 충분한 리소스가 할당되어 있는지 확인하세요.
- `Dockerfile`에서 권한 있는 작업이 시도되지 않는지 확인하세요.

Kubernetes 러너에서 `[rootlesskit:child ] error: failed to share mount point: /: permission denied`을 받으면 AppArmor가 BuildKit에 필요한 마운트 syscall을 차단하고 있습니다.

이 이슈를 해결하려면 러너 설정에 다음을 추가하세요:

```toml
[runners.kubernetes.pod_annotations]
  "container.apparmor.security.beta.kubernetes.io/build" = "unconfined"
```

### 오류: `invalid local: stat path/to/image/Dockerfile: not a directory` {#error-invalid-local-stat-pathtoimagedockerfile-not-a-directory}

`invalid local: stat path/to/image/Dockerfile: not a directory`이라는 오류가 나타날 수 있습니다.

이 이슈는 `--local dockerfile=` 매개변수에 전체 파일 경로 대신 디렉터리 경로를 지정할 때 발생합니다. BuildKit은 `Dockerfile`라는 파일을 포함하는 디렉터리 경로를 예상합니다.

이 이슈를 해결하려면 전체 파일 경로 대신 디렉터리 경로를 사용하세요. 예를 들어:

- 사용: `--local dockerfile=path/to/image`
- 대신: `--local dockerfile=path/to/image/Dockerfile`

### 다중 플랫폼 빌드 실패 {#multi-platform-builds-fail}

다중 플랫폼 빌드 이슈의 경우:

- `Dockerfile`의 기본 이미지가 대상 아키텍처를 지원하는지 확인합니다.
- 아키텍처별 종속성이 모든 대상 플랫폼에서 사용 가능한지 확인합니다.
- `Dockerfile`에서 아키텍처별 로직을 위해 조건부 문을 사용하는 것을 고려합니다.
