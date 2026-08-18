---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Buildah를 사용하여 다중 플랫폼 이미지 빌드
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Buildah를 사용하여 여러 CPU 아키텍처용 이미지를 빌드합니다. 다중 플랫폼 빌드는 여러 하드웨어 플랫폼에서 작동하는 이미지를 생성하며, Docker는 각 배포 대상에 적합한 이미지를 자동으로 선택합니다.

## 전제 조건 {#prerequisites}

- 이미지를 빌드할 Dockerfile
- (선택 사항) 다양한 CPU 아키텍처에서 실행 중인 GitLab 러너

## 다중 플랫폼 이미지 빌드 {#build-multi-platform-images}

Buildah를 사용하여 다중 플랫폼 이미지를 빌드하려면:

1. 각 대상 아키텍처를 위해 별도의 빌드 작업을 구성합니다.
1. 아키텍처별 이미지를 결합하는 매니페스트 작업을 생성합니다.
1. 결합된 매니페스트를 레지스트리에 푸시하도록 매니페스트 작업을 구성합니다.

각 아키텍처에서 작업을 실행하면 CPU 명령어 변환으로 인한 성능 이슈를 방지할 수 있습니다. 필요한 경우 단일 아키텍처에서 두 빌드를 모두 실행할 수 있습니다. 기본이 아닌 아키텍처용으로 빌드하면 더 느린 빌드 시간이 발생할 수 있습니다.

다음 예제에서는 두 개의 [GitLab 호스팅 러너(Linux)](../runners/hosted_runners/linux.md)를 사용합니다:

- `saas-linux-small-arm64`
- `saas-linux-small-amd64`

```yaml
stages:
  - build

variables:
  STORAGE_DRIVER: vfs
  BUILDAH_FORMAT: docker
  FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE:latest"

default:
  image: quay.io/buildah/stable
  before_script:
    - echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY

build-amd64:
  stage: build
  tags:
    - saas-linux-small-amd64
  script:
    - buildah build --platform=linux/amd64 -t $CI_REGISTRY_IMAGE:amd64 .
    - buildah push $CI_REGISTRY_IMAGE:amd64

build-arm64:
  stage: build
  tags:
    - saas-linux-small-arm64
  script:
    - buildah build --platform=linux/arm64/v8 -t $CI_REGISTRY_IMAGE:arm64 .
    - buildah push $CI_REGISTRY_IMAGE:arm64

create_manifest:
  stage: build
  needs: ["build-arm64", "build-amd64"]
  tags:
    - saas-linux-small-amd64
  script:
    - buildah manifest create $FQ_IMAGE_NAME
    - buildah manifest add $FQ_IMAGE_NAME docker://$CI_REGISTRY_IMAGE:amd64
    - buildah manifest add $FQ_IMAGE_NAME docker://$CI_REGISTRY_IMAGE:arm64
    - buildah manifest push --all $FQ_IMAGE_NAME
```

이 파이프라인은 `amd64` 및 `arm64`로 태그된 아키텍처별 이미지를 생성한 다음, 이를 `latest` 태그 아래에서 사용 가능한 단일 매니페스트로 결합합니다.

## 문제 해결 {#troubleshooting}

### 인증 오류로 빌드 실패 {#build-fails-with-authentication-errors}

레지스트리 인증 실패가 발생한 경우:

- `CI_REGISTRY_USER` 및 `CI_REGISTRY_PASSWORD` 변수를 사용할 수 있는지 확인합니다.
- 대상 레지스트리에 푸시 권한이 있는지 확인합니다.
- 외부 레지스트리의 경우 프로젝트의 CI/CD 변수에서 인증 자격 증명이 올바르게 구성되어 있는지 확인합니다.

### 다중 플랫폼 빌드 실패 {#multi-platform-builds-fail}

다중 플랫폼 빌드 이슈의 경우:

- `Dockerfile`의 기본 이미지가 대상 아키텍처를 지원하는지 확인합니다.
- 아키텍처별 종속성이 모든 대상 플랫폼에서 사용 가능한지 확인합니다.
- `Dockerfile`에서 아키텍처별 로직을 위해 조건부 문을 사용하는 것을 고려합니다.

### 오류: `Error during unshare(CLONE_NEWUSER): Operation not permitted` {#error-error-during-unshareclone_newuser-operation-not-permitted}

Buildah 또는 [Docker BuildKit](using_buildkit.md)을 rootless 모드에서 사용하여 CI/CD 작업에서 Docker 이미지를 빌드할 때 `Error during unshare(CLONE_NEWUSER): Operation not permitted`이 발생할 수 있습니다.

이 오류는 rootless 컨테이너 빌드에 필요한 보안 옵션이 설정되지 않았을 때 발생합니다.

이 이슈를 해결하려면 러너의 `[runners.docker]` 섹션을 `config.toml` 파일에서 구성합니다:

```toml
[runners.docker]
  security_opt = ["seccomp:unconfined", "apparmor:unconfined"]
```

자세한 내용은 [BuildKit rootless Docker 빌드 및 보안 요구 사항](https://github.com/moby/buildkit/blob/master/docs/rootless.md#docker)을 참조하십시오.
