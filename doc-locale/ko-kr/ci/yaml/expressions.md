---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 식
---

CI/CD 식을 사용하면 변수와 입력을 특수한 컨텍스트에서 참조하여 CI/CD 파이프라인에서 동적 구성을 활성화할 수 있습니다. GitLab은 파이프라인이 생성되기 전에 파이프라인 구성에서 식을 평가합니다.

## 구성 식 {#configuration-expressions}

구성 식은 `$[[ ]]` 문법을 사용하며 파이프라인 생성 시간(컴파일 시간)에 평가됩니다. 다양한 컨텍스트를 기반으로 동적 구성을 활성화합니다.

모든 구성 식은 다음과 같은 특성을 공유합니다:

- **Compile-time evaluation**: 파이프라인 구성이 생성될 때 값이 확인되며, 작업 실행 중에는 확인되지 않습니다. 많은 수의 식은 파이프라인 생성 시간을 증가시킬 수 있지만 작업 실행 시간에는 영향을 주지 않습니다.
- **Static resolution**: 동적 논리를 수행하거나 런타임 작업 상태에 액세스할 수 없습니다.

구성 식은 값에 액세스하기 위한 다양한 컨텍스트를 지원합니다:

| 컨텍스트                                 | 문법                        | 가용성       | 목적 |
|-----------------------------------------|-------------------------------|--------------------|---------|
| [입력 컨텍스트](#inputs-context)       | `$[[ inputs.INPUT_NAME ]]`    | GitLab 17.0        | 재사용 가능한 구성에서 CI/CD 입력을 참조합니다. |
| [매트릭스 컨텍스트](#matrix-context)       | `$[[ matrix.IDENTIFIER ]]`    | GitLab 18.6 (베타) | 작업 종속성에서 `parallel:matrix` 식별자를 참조합니다. |
| [구성 요소 컨텍스트](#component-context) | `$[[ component.FIELD_NAME ]]` | GitLab 18.6 (베타) | 구성 요소 템플릿에서 구성 요소 메타데이터를 참조합니다. |

### 입력 컨텍스트 {#inputs-context}

{{< history >}}

- GitLab 15.11에서 베타 기능으로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)되었습니다.
- GitLab 17.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062)하게 되었습니다.

{{< /history >}}

`inputs.` 컨텍스트를 사용하여 재사용 가능한 구성에서 [CI/CD 입력](../inputs/_index.md)을 `$[[ inputs.INPUT_NAME ]]` 문법으로 참조합니다.

예를 들어:

```yaml
spec:
  inputs:
    environment:
      default: production
    job-stage:
      default: test
---
scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

`input.` 식은 다음과 같은 특성을 가집니다:

- 타입 유효성 검사: `string`, `number`, `boolean`, `array` 타입을 유효성 검사와 함께 지원합니다. 유효성 검사 입력은 유효하지 않은 값으로 파이프라인이 생성되는 것을 방지합니다.
- 함수 지원: `expand_vars` 및 `truncate`와 같은 미리 정의된 함수를 사용하여 값을 조작할 수 있습니다.
- 범위: 정의된 파일에서 사용 가능하거나 `include:inputs`과 함께 명시적으로 전달됩니다.

### 매트릭스 컨텍스트 {#matrix-context}

{{< history >}}

- GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/423553)되었습니다. 이 기능은 [베타](../../policy/development_stages_support.md#beta) 단계입니다.

{{< /history >}}

[`matrix.` 컨텍스트](matrix_expressions.md)를 사용하여 [`parallel:matrix`](_index.md#parallelmatrix) 값을 `$[[ matrix.IDENTIFIER ]]` 문법으로 참조합니다. `parallel:matrix` 작업 간의 동적 1:1 매핑을 활성화하기 위해 작업 종속성에서 사용합니다.

예를 들어:

```yaml
.os-arch-matrix:
  parallel:
    matrix:
      - OS: [ubuntu, alpine]
        ARCH: [amd64, arm64]

build:
  script: echo "Testing $OS on $ARCH"
  parallel: !reference [.os-arch-matrix, parallel]

test:
  script: echo "Testing $OS on $ARCH"
  parallel: !reference [.os-arch-matrix, parallel]
  needs:
    - job: build
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
```

`matrix.` 식은 다음과 같은 특성을 가집니다:

- 작업 수준 `parallel:matrix`으로 범위 지정: 현재 작업의 값만 참조할 수 있습니다.
- 자동 매핑: 스테이지 간에 매트릭스 작업 간의 1:1 종속성을 생성합니다

### 구성 요소 컨텍스트 {#component-context}

{{< history >}}

- GitLab 18.6에서 [베타](../../policy/development_stages_support.md#beta)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/438275)되었으며 [플래그](../../administration/feature_flags/_index.md) 이름은 `ci_component_context_interpolation`입니다. 기본적으로 활성화됩니다.
- GitLab 18.7에서 [일반 공급 개시](https://gitlab.com/gitlab-org/gitlab/-/issues/571986)됨. 기능 플래그 `ci_component_context_interpolation`이 제거되었습니다.

{{< /history >}}

`component.` 컨텍스트를 사용하여 구성 요소 템플릿에서 [CI/CD 구성 요소](../components/_index.md) 메타데이터를 `$[[ component.FIELD_NAME ]]` 문법으로 참조합니다.

구성 요소 컨텍스트는 구성 요소의 이름, 버전, 커밋 SHA와 같은 구성 요소 자체에 대한 메타데이터를 제공합니다. 이를 통해 구성 요소 템플릿이 자신의 메타데이터를 동적으로 참조할 수 있습니다.

구성 요소 컨텍스트를 사용하려면 [`spec:component`](_index.md#speccomponent) 헤더에서 필요한 필드를 선언한 다음 구성 요소 템플릿에서 참조합니다.

예를 들어:

```yaml
spec:
  component: [name, version]
  inputs:
    stage:
      default: build
---

build-job:
  stage: $[[ inputs.stage ]]
  image: registry.example.com/$[[ component.name ]]:$[[ component.version ]]
  script:
    - echo "Building with component version $[[ component.version ]]"
```

## 관련 항목 {#related-topics}

- [Moa 식 언어](../functions/moa.md)
- [CI/CD 입력](../inputs/_index.md)
- [CI/CD 구성 요소](../components/_index.md)
- [매트릭스 식](matrix_expressions.md)
- [YAML 최적화](yaml_optimization.md)
