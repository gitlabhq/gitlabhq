---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 입력 예제
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[CI/CD 입력](_index.md)을 사용하면 CI/CD 구성의 유연성을 높일 수 있습니다. 이 예제를 파이프라인에서 입력을 사용하는 방법을 구성하기 위한 지침으로 사용하세요.

## 동일한 파일 여러 번 포함 {#include-the-same-file-multiple-times}

동일한 파일을 여러 번 포함할 수 있습니다. 다양한 입력을 사용하여 포함할 수 있습니다. 그러나 동일한 이름을 가진 여러 작업이 하나의 파이프라인에 추가되면, 각 추가 작업은 동일한 이름의 이전 작업을 덮어씁니다. 구성이 중복된 작업 이름을 방지해야 합니다.

예를 들어, 다양한 입력으로 동일한 구성을 여러 번 포함합니다:

```yaml
include:
  - local: path/to/my-super-linter.yml
    inputs:
      linter: docs
      lint-path: "doc/"
  - local: path/to/my-super-linter.yml
    inputs:
      linter: yaml
      lint-path: "data/yaml/"
```

`path/to/my-super-linter.yml`의 구성은 파일이 포함될 때마다 작업이 고유한 이름을 가지도록 합니다:

```yaml
spec:
  inputs:
    linter:
    lint-path:
---
"run-$[[ inputs.linter ]]-lint":
  script: ./lint --$[[ inputs.linter ]] --path=$[[ inputs.lint-path ]]
```

## `inputs`에서 구성 재사용 {#reuse-configuration-in-inputs}

`inputs`로 구성을 재사용하려면 [YAML 앵커](../yaml/yaml_optimization.md#anchors)를 사용할 수 있습니다.

예를 들어, 입력에서 `rules` 배열을 지원하는 여러 구성 요소에 동일한 `rules` 구성을 재사용하려면:

```yaml
.my-job-rules: &my-job-rules
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

include:
  - component: $CI_SERVER_FQDN/project/path/component1@main
    inputs:
      job-rules: *my-job-rules
  - component: $CI_SERVER_FQDN/project/path/component2@main
    inputs:
      job-rules: *my-job-rules
```

입력에서 [`!reference` 태그](../yaml/yaml_optimization.md#reference-tags)를 사용할 수 없지만, [이슈 424481](https://gitlab.com/gitlab-org/gitlab/-/issues/424481)은 이 기능을 추가하도록 제안합니다.

## `inputs`을(를) `needs`와(과) 함께 사용 {#use-inputs-with-needs}

복잡한 작업 종속성을 위해 [`needs`](../yaml/_index.md#needs)에서 배열 유형 입력을 사용할 수 있습니다.

예를 들어 `component.yml`이라는 파일에서:

```yaml
spec:
  inputs:
    first_needs:
      type: array
    second_needs:
      type: array
---

test_job:
  script: echo "this job has needs"
  needs:
    - $[[ inputs.first_needs ]]
    - $[[ inputs.second_needs ]]
```

이 예제에서 입력은 `first_needs`과(와) `second_needs`이며, 모두 [배열 유형 입력](_index.md#array-type)입니다. 그런 다음 `.gitlab-ci.yml` 파일에서 이 구성을 추가하고 입력 값을 설정할 수 있습니다:

```yaml
include:
  - local: 'component.yml'
    inputs:
      first_needs:
        - build1
      second_needs:
        - build2
```

파이프라인이 시작되면, `test_job`의 `needs` 배열의 항목들이 연결됩니다:

```yaml
test_job:
  script: echo "this job has needs"
  needs:
  - build1
  - build2
```

### 포함될 때 `needs`을(를) 확장할 수 있도록 허용 {#allow-needs-to-be-expanded-when-included}

포함된 작업에 [`needs`](../yaml/_index.md#needs)을(를) 가질 수 있지만, 또한 `spec:inputs`로 `needs` 배열에 추가 작업을 추가할 수 있습니다.

예를 들어:

```yaml
spec:
  inputs:
    test_job_needs:
      type: array
      default: []
---

build-job:
  script:
    - echo "My build job"

test-job:
  script:
    - echo "My test job"
  needs:
    - build-job
    - $[[ inputs.test_job_needs ]]
```

이 예에서:

- `test-job` 작업은 항상 `build-job`이(가) 필요합니다.
- `test_job_needs:` 배열 입력이 기본적으로 비어 있으므로, 기본적으로 테스트 작업은 다른 작업이 필요하지 않습니다.

구성에서 `test-job`이(가) 다른 작업을 필요하도록 설정하려면, 파일을 포함할 때 `test_needs` 입력에 추가합니다. 예를 들어:

```yaml
include:
  - component: $CI_SERVER_FQDN/project/path/component@1.0.0
    inputs:
      test_job_needs: [my-other-job]

my-other-job:
  script:
    - echo "I want build-job` in the component to need this job too"
```

### `needs`을(를) `needs`이(가) 없는 포함된 작업에 추가 {#add-needs-to-an-included-job-that-doesnt-have-needs}

[`needs`](../yaml/_index.md#needs)을(를) 이미 `needs`이(가) 정의되지 않은 포함된 작업에 추가할 수 있습니다. 예를 들어, CI/CD 구성 요소의 구성에서:

```yaml
spec:
  inputs:
    test_job:
      default: test-job
---

build-job:
  script:
    - echo "My build job"

"$[[ inputs.test_job ]]":
  script:
    - echo "My test job"
```

이 예제에서 `spec:inputs` 섹션은 작업 이름을 사용자 지정할 수 있습니다.

그런 다음 구성 요소를 포함한 후, 추가 `needs` 구성으로 작업을 확장할 수 있습니다. 예를 들어:

```yaml
include:
  - component: $CI_SERVER_FQDN/project/path/component@1.0.0
    inputs:
      test_job: my-test-job

my-test-job:
  needs: [my-other-job]

my-other-job:
  script:
    - echo "I want `my-test-job` to need this job"
```

## `inputs`을(를) `include`과(과) 함께 사용하여 더 동적인 파이프라인 생성 {#use-inputs-with-include-for-more-dynamic-pipelines}

`inputs`을(를) `include`과(과) 함께 사용하여 포함할 추가 파이프라인 구성 파일을 선택할 수 있습니다.

예를 들어:

```yaml
spec:
  inputs:
    pipeline-type:
      type: string
      default: development
      options: ['development', 'canary', 'production']
      description: "The pipeline type, which determines which set of jobs to include."
---

include:
  - local: .gitlab/ci/$[[ inputs.pipeline-type ]].gitlab-ci.yml
```

이 예제에서 `.gitlab/ci/development.gitlab-ci.yml` 파일은 기본적으로 포함됩니다. 하지만 다른 `pipeline-type` 입력 옵션을 사용하면, 다른 구성 파일이 포함됩니다.

### 변수 표현식에서 CI/CD 입력 사용 {#use-cicd-inputs-in-variable-expressions}

[CI/CD 입력](_index.md)을 사용하여 변수 표현식을 사용자 지정할 수 있습니다. 예를 들어:

```yaml
example-job:
  script: echo "Testing"
  rules:
    - if: '"$[[ inputs.some_example ]]" == "test-branch"'
```

표현식은 두 단계로 평가됩니다:

1. 입력 보간: 파이프라인이 생성되기 전에 입력이 입력 값으로 바뀝니다. 이 예제에서 `$[[ inputs.some_example ]]` 입력이 [설정된 값](_index.md#set-input-values)으로 바뀝니다. 예를 들어, 값이 다음과 같으면:

   - `test-branch`이면, 표현식은 `if: '"test-branch" == "test-branch"'`가 됩니다.
   - `$CI_COMMIT_BRANCH`이면, 표현식은 `if: '"$CI_COMMIT_BRANCH" == "test-branch"'`가 됩니다.

1. 표현식 평가: 입력이 보간된 후, GitLab은 파이프라인을 생성하려고 시도합니다. 파이프라인 생성 중에, 파이프라인에 추가할 작업을 결정하기 위해 표현식이 평가됩니다.
