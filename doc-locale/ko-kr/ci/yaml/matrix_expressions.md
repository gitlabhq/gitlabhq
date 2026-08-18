---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CD의 매트릭스 표현식
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/423553)되었습니다.

{{< /history >}}

매트릭스 표현식은 [`parallel:matrix`](_index.md#parallelmatrix) 식별자를 기반으로 동적 작업 의존성을 활성화하여 `parallel:matrix` 작업 간에 1:1 매핑을 만듭니다.

매트릭스 표현식은 [입력 표현식](expressions.md#inputs-context)과 비교하여 몇 가지 제한 사항이 있습니다:

- 컴파일 타임 전용: 식별자는 파이프라인이 생성될 때 해결되며 작업 실행 중에는 해결되지 않습니다.
- 문자열 대체만 해당: 복잡한 논리나 변환이 없습니다.
- 매트릭스 식별자만 해당: CI/CD 변수 또는 입력을 참조할 수 없습니다.

## 구문 {#syntax}

매트릭스 표현식은 `$[[ matrix.IDENTIFIER ]]` 구문을 사용하여 작업 의존성에서 `parallel:matrix` 식별자를 참조합니다. 예를 들어:

```yaml
needs:
  - job: build
    parallel:
      matrix:
        - OS: ['$[[ matrix.OS ]]']
          ARCH: ['$[[ matrix.ARCH ]]']
```

### `needs:parallel:matrix`의 매트릭스 표현식 {#matrix-expressions-in-needsparallelmatrix}

매트릭스 표현식을 사용하여 작업 의존성에서 매트릭스 식별자를 동적으로 참조하여 모든 조합을 수동으로 지정하지 않고도 매트릭스 작업 간에 1:1 매핑을 활성화할 수 있습니다.

예를 들어:

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: [aws, gcp]
        STACK: [monitoring, app1, app2]

linux:test:
  stage: test
  script: echo "Testing linux..."
  parallel:
    matrix:
      - PROVIDER: [aws, gcp]
        STACK: [monitoring, app1, app2]
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: ['$[[ matrix.PROVIDER ]]']
            STACK: ['$[[ matrix.STACK ]]']
```

이 예제는 모든 `linux:build` 및 `linux:test` 작업 간에 1:1 의존성 매핑을 생성합니다:

- `linux:test: [aws, monitoring]`은 `linux:build: [aws, monitoring]`에 종속됩니다
- `linux:test: [aws, app1]`은 `linux:build: [aws, app1]`에 종속됩니다
- 모든 6개의 `parallel:matrix` 값 조합에도 동일하게 적용됩니다.

`matrix.` 표현식을 사용하면 각 매트릭스 조합을 수동으로 지정할 필요가 없습니다.

매트릭스 표현식은 현재 작업의 매트릭스 구성에서만 식별자를 참조합니다.

### `parallel:matrix` 구성을 재사용하기 위해 YAML 앵커 사용 {#use-yaml-anchors-to-reuse-parallelmatrix-configuration}

[YAML 앵커](yaml_optimization.md#anchors)를 사용하여 `parallel:matrix` 구성을 복잡한 `parallel:matrix` 구성 및 의존성이 있는 여러 작업에서 재사용할 수 있습니다.

예를 들어:

```yaml
stages:
  - compile
  - test
  - deploy

.build_matrix: &build_matrix
  parallel:
    matrix:
      - OS: ["ubuntu", "alpine"]
        ARCH: ["amd64", "arm64"]
        VARIANT: ["slim", "full"]

compile_binary:
  stage: compile
  script:
    - echo "Compiling for $OS-$ARCH-$VARIANT"
  <<: *build_matrix

integration_test:
  stage: test
  script:
    - echo "Testing $OS-$ARCH-$VARIANT"
  <<: *build_matrix
  needs:
    - job: compile_binary
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
            VARIANT: ['$[[ matrix.VARIANT ]]']

deploy_artifact:
  stage: deploy
  script:
    - echo "Deploying $OS-$ARCH-$VARIANT"
  <<: *build_matrix
  needs:
    - job: integration_test
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
            VARIANT: ['$[[ matrix.VARIANT ]]']
```

이 구성은 24개의 작업을 생성합니다: 각 스테이지에서 8개의 작업 (2 `OS` × 2 `ARCH` × 2 `VARIANT` 조합), 스테이지 간 1:1 의존성 포함.

### 값의 부분 집합 사용 {#use-a-subset-of-values}

매트릭스 표현식을 특정 값과 결합하여 선택적 의존성 부분 집합을 만들 수 있습니다:

```yaml
stages:
  - prepare
  - build
  - test

.full_matrix: &full_matrix
  parallel:
    matrix:
      - PLATFORM: ["linux", "windows", "macos"]
        VERSION: ["16", "18", "20"]

.platform_only: &platform_only
  parallel:
    matrix:
      - PLATFORM: ["linux", "windows", "macos"]

prepare_env:
  stage: prepare
  script:
    - echo "Preparing $PLATFORM with Node.js $VERSION"
  <<: *full_matrix

build_project:
  stage: build
  script:
    - echo "Building on $PLATFORM"
  needs:
    - job: prepare_env
      parallel:
        matrix:
          - PLATFORM: ['$[[ matrix.PLATFORM ]]']
            VERSION: ["18"]  # Only depend on Node.js 18 preparations
  <<: *platform_only
```

이 예에서:

- `prepare_env`은 `parallel:matrix`을 사용하여 9개의 작업을 생성합니다: 3 `PLATFORM` × 3 `VERSIONS`.
- `build_project`은 `parallel:matrix`을 사용하여 3개의 작업을 생성합니다: 3 `PLATFORM` 값만.
- 각 `build_project` 작업은 모든 플랫폼(`PLATFORM`)에 대해 Node.js `18`(`VERSION`)에만 종속됩니다.

또는 [모든 의존성을 수동으로 구성](../jobs/job_control.md#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs)할 수 있습니다.

## 관련 항목 {#related-topics}

- [매트릭스를 사용한 병렬 작업](../jobs/job_control.md#parallelize-large-jobs)
- [`needs`를 사용한 작업 의존성](needs.md)
- [CI 표현식 개요](expressions.md)
- [YAML 최적화](yaml_optimization.md)
