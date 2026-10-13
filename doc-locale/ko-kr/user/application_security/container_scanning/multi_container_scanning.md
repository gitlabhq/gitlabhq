---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 멀티 컨테이너 스캔
description: "이미지 취약성 스캔, 구성, 사용자 지정 및 보고."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 18.7에서 [실험](../../../policy/development_stages_support.md)으로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/3139)되었습니다.

{{< /history >}}

단일 파이프라인에서 여러 컨테이너 이미지를 스캔하려면 멀티 컨테이너 스캔을 사용하세요. 이 기능을 통해 다음을 수행할 수 있습니다:

- 여러 이미지를 병렬로 스캔합니다.
- 단일 구성 파일에서 스캔 대상을 구성합니다.
- 기존 컨테이너 스캔 워크플로우와 통합합니다.

멀티 컨테이너 스캔은 [동적 자식 파이프라인](../../../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines)을 사용하여 스캔을 동시에 실행하고 전체 파이프라인 실행 시간을 단축합니다.

## 지원되는 이미지 {#supported-images}

멀티 컨테이너 스캔은 다음을 지원합니다:

- 공개 레지스트리의 이미지(Docker Hub, GitLab 컨테이너 레지스트리 및 기타)
- 비공개 레지스트리의 이미지(인증 구성됨)
- 멀티 아키텍처 이미지

## 멀티 컨테이너 스캔 켜기 {#turn-on-multi-container-scanning}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- Docker 실행기가 있는 GitLab 러너.
- `.gitlab-multi-image.yml` 구성 파일이 리포지토리 루트에 있어야 합니다.
- 스캔할 컨테이너 이미지가 최소 1개 필요합니다.

멀티 컨테이너 스캔을 켜려면:

1. 리포지토리 루트에 `.gitlab-multi-image.yml` 파일을 생성합니다:

   ```yaml
      scanTargets:
        - name: alpine
          tag: latest
        - name: python
          tag: 3.9-slim
   ```

1. `.gitlab-ci.yml`에 템플릿을 포함합니다:

   ```yaml
      include:
        - template: Jobs/Multi-Container-Scanning.latest.gitlab-ci.yml
   ```

1. 커밋하고 변경 사항을 푸시합니다. 파이프라인에서 스캔을 자동으로 실행합니다.

## 구성 {#configuration}

`.gitlab-multi-image.yml` 파일을 편집하여 멀티 컨테이너 스캔을 구성합니다.

### 기본 구성 예시 {#basic-configuration-example}

```yaml
scanTargets:
  - name: alpine
    tag: "3.19"
  - name: ubuntu
    tag: "22.04"
```

### 완전한 구성 예제 {#complete-configuration-example}

```yaml
# Include license information in reports
includeLicenses: true

# Configure registry authentication
auths:
  registry.example.com:
    username: ${REGISTRY_USER}
    password: ${REGISTRY_PASSWORD}

# Allow insecure connections (not recommended for production)
allowInsecure: false

# Additional CA certificates for custom registries
additionalCaCertificateBundle: |
  -----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----

# Images to scan
scanTargets:
  - name: registry.example.com/myapp
    tag: "v1.2.3"
  - name: postgres
    tag: "15-alpine"
```

### 구성 옵션 {#configuration-options}

> [!note]
> 멀티 컨테이너 스캔에서 자식 작업의 러너 태그를 지정할 수 없지만 [이슈 363687](https://gitlab.com/gitlab-org/gitlab/-/work_items/363687)에서 이 동작을 변경할 것을 제안합니다.

| 옵션                          | 형식    | 필수 | 설명                              |
|---------------------------------|---------|----------|------------------------------------------|
| `scanTargets`                   | 배열   | 예      | 스캔할 컨테이너 이미지 목록         |
| `scanTargets[].name`            | 문자열  | 예      | 이미지 이름(선택적 레지스트리 포함)      |
| `scanTargets[].tag`             | 문자열  | 아니요       | 이미지 태그(기본값: `latest`)            |
| `scanTargets[].registry`        | 문자열  | 아니요       | 레지스트리 재정의                        |
| `includeLicenses`               | 부울 | 아니요       | 보고서에 라이센스 정보 포함   |
| `auths`                         | 개체  | 아니요       | 레지스트리 인증 자격 증명      |
| `allowInsecure`                 | 부울 | 아니요       | 보안되지 않은 HTTPS 연결 허용         |
| `additionalCaCertificateBundle` | 문자열  | 아니요       | PEM 형식의 추가 CA 인증서 |

## 일반적인 시나리오 {#common-scenarios}

다음 섹션에서는 필요에 맞게 조정할 수 있는 몇 가지 예시 시나리오를 설명합니다.

### 다른 레지스트리에서 이미지 스캔 {#scan-images-from-different-registries}

```yaml
scanTargets:
  - name: docker.io/library/nginx
    tag: "1.25"
  - name: registry.gitlab.com/mygroup/myapp
    tag: "main"
  - name: gcr.io/myproject/service
    tag: "prod"
```

### 비공개 레지스트리 인증 사용 {#use-private-registry-authentication}

```yaml
auths:
  registry.gitlab.com:
    username: ${CI_REGISTRY_USER}
    password: ${CI_REGISTRY_PASSWORD}
  docker.io:
    username: ${DOCKERHUB_USER}
    password: ${DOCKERHUB_TOKEN}

scanTargets:
  - name: registry.gitlab.com/private/image
    tag: latest
```

### 규정 준수를 위한 특정 버전 스캔 {#scan-specific-versions-for-compliance}

```yaml
scanTargets:
  - name: postgres
    tag: "14.10"
  - name: redis
    tag: "7.2.3"
  - name: nginx
    tag: "1.25.3"
```

### 동적으로 빌드된 이미지 스캔 {#scan-dynamically-built-images}

이미지 이름과 태그를 런타임에만 알 수 있는 경우 정적 `.gitlab-multi-image.yml` 파일에서 `scanTargets`를 정의할 수 없습니다.

이러한 이미지를 스캔하려면 `multi-cs::generate-scan` 작업을 재정의하여 빌드 작업에서 생성된 dotenv 아티팩트에서 구성 파일을 동적으로 빌드합니다:

```yaml
include:
  - template: Jobs/Multi-Container-Scanning.latest.gitlab-ci.yml

.build-rules: &build-rules
  rules:
    - if: $CONTAINER_SCANNING_DISABLED == 'true' || $CONTAINER_SCANNING_DISABLED == '1'
      when: never
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

build-image-1:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  <<: *build-rules
  script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
    - export IMAGE1_NAME="$CI_REGISTRY_IMAGE/app1:$CI_COMMIT_SHORT_SHA-$CI_JOB_ID"
    - docker build -f Dockerfiles/Dockerfile.app1 -t "$IMAGE1_NAME" .
    - docker push "$IMAGE1_NAME"
    - echo "IMAGE1_NAME=$IMAGE1_NAME" >> build1.env
  artifacts:
    reports:
      dotenv: build1.env

build-image-2:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  <<: *build-rules
  script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
    - export IMAGE2_NAME="$CI_REGISTRY_IMAGE/app2:$CI_COMMIT_SHORT_SHA-$CI_JOB_ID"
    - docker build -f Dockerfiles/Dockerfile.app2 -t "$IMAGE2_NAME" .
    - docker push "$IMAGE2_NAME"
    - echo "IMAGE2_NAME=$IMAGE2_NAME" >> build2.env
  artifacts:
    reports:
      dotenv: build2.env

# Override the template job to inject the dynamically generated config
multi-cs::generate-scan:
  needs:
    - job: build-image-1
      artifacts: true
    - job: build-image-2
      artifacts: true
  before_script:
    - !reference [.multi-cs-generate-scan-base, before_script]  # preserve template steps if any
    - IMAGE1_REPO="${IMAGE1_NAME%:*}"
    - IMAGE1_TAG="${IMAGE1_NAME##*:}"
    - IMAGE2_REPO="${IMAGE2_NAME%:*}"
    - IMAGE2_TAG="${IMAGE2_NAME##*:}"
    - |
      cat > .gitlab-multi-image.yml <<EOF
      scanTargets:
        - name: ${IMAGE1_REPO}
          tag: ${IMAGE1_TAG}
        - name: ${IMAGE2_REPO}
          tag: ${IMAGE2_TAG}
      auths:
        registry.gitlab.com: # Replace with your $CI_REGISTRY value for self-managed GitLab
          username: \${CI_REGISTRY_USER}
          password: \${CI_REGISTRY_PASSWORD}
      EOF
```

## CI/CD 변수 {#cicd-variables}

CI/CD 변수를 사용하여 멀티 컨테이너 스캔 동작을 사용자 지정할 수 있습니다.

| 변수                      | 기본값                                                | 설명                                |
|-------------------------------|--------------------------------------------------------|--------------------------------------------|
| `CONTAINER_SCANNING_DISABLED` | -                                                      | `true` 또는 `1`로 설정하여 스캔을 비활성화합니다.   |
| `AST_ENABLE_MR_PIPELINES`     | `true`                                                 | 머지 리퀘스트 파이프라인에서 스캔 활성화 |
| `CS_SCANNER_IMAGE`            | `registry.gitlab.com/.../multiple-container-scanner:0` | 사용할 스캐너 이미지                       |

### 멀티 컨테이너 스캔 비활성화 {#disable-multi-container-scanning}

임시로 스캔을 비활성화하려면:

```yaml
variables:
  CONTAINER_SCANNING_DISABLED: "true"
```

### 머지 리퀘스트 파이프라인 스캔 비활성화 {#disable-mr-pipeline-scanning}

```yaml
variables:
  AST_ENABLE_MR_PIPELINES: "false"
```

## 스캔 결과 보기 {#view-scan-results}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- 프로젝트에서 멀티 컨테이너 스캔이 켜져 있어야 합니다.
- 파이프라인이 컨테이너 스캔 결과와 함께 완료되었습니다.

스캔 결과를 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 머지 리퀘스트 또는 파이프라인 세부 정보 페이지로 이동합니다.
1. **보안** 탭을 선택합니다.
1. 스캔된 모든 이미지에서 감지된 취약성을 봅니다.

스캔된 각 이미지는 다음을 생성합니다:

- 컨테이너 스캔 보고서입니다.
- CycloneDX SBOM(Software Bill of Materials)입니다.
- 라이센스 정보(`includeLicenses: true` 경우).

### 파이프라인 구조 {#pipeline-structure}

멀티 컨테이너 스캔은 두 개의 작업을 생성합니다:

- `multi-cs::generate-scan`: 스캔 구성을 생성합니다.
- `multi-cs::trigger-scan`: 병렬 스캔 작업으로 자식 파이프라인을 트리거합니다.

자식 파이프라인은 `scanTargets`의 각 이미지당 하나의 작업을 포함합니다.

## 문제 해결 {#troubleshooting}

멀티 컨테이너 스캔을 사용하면서 다음 문제가 발생할 수 있습니다.

### 파이프라인 "구성 파일을 찾을 수 없음"으로 실패 {#pipeline-fails-with-configuration-file-not-found}

원인: `.gitlab-multi-image.yml` 파일이 누락되었거나 잘못된 위치에 있습니다.

해결 방법: `.gitlab-multi-image.yml`이 리포지토리 루트에 있는지 확인합니다.

### 비공개 레지스트리에 대한 인증 실패 {#authentication-fails-for-private-registry}

원인: 잘못된 자격 증명 또는 누락된 인증 구성입니다.

해결 방법:

1. 자격 증명이 올바르고 제대로 구성되었는지 확인합니다.

   ```yaml
      auths:
        registry.example.com:
          username: ${REGISTRY_USER}
          password: ${REGISTRY_PASSWORD}
   ```

1. **설정** > \*\*CI/CD > **변수**에서 변수를 정의합니다.

### 스캔이 너무 오래 걸림 {#scan-takes-too-long}

원인: 여러 대형 이미지가 순차적으로 스캔되고 있습니다.

해결 방법: 멀티 컨테이너 스캔은 이미 병렬로 스캔을 실행합니다.

다음을 고려하세요:

- 더 작은 기본 이미지 사용
- 특정 이미지 버전만 스캔
- GitLab 러너 동시성 설정 조정

### 자식 파이프라인이 보고서를 표시하지 않음 {#child-pipeline-doesnt-show-reports}

원인: 트리거 구성에서 `strategy: mirror`이 누락되었습니다.

해결 방법: 이는 템플릿에서 기본적으로 구성됩니다. 템플릿을 사용자 지정한 경우 트리거 작업에 `strategy: mirror`이 포함되어 있는지 확인합니다.

### 자식 파이프라인이 예상치 못한 러너에서 실행됨 {#child-pipeline-runs-on-unexpected-runner}

자식 파이프라인 작업이 예상하지 못한 러너에서 실행될 수 있습니다.

이 문제는 자식 파이프라인 작업이 부모 작업의 러너 태그를 상속하지 않기 때문에 발생합니다. [이슈 363687](https://gitlab.com/gitlab-org/gitlab/-/work_items/363687)에서 이 동작을 변경할 것을 제안합니다.
