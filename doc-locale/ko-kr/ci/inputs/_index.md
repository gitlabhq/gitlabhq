---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 입력된 형식의 검증된 매개변수를 사용하여 재사용 가능한 CI/CD 템플릿 및 구성 요소를 사용자 지정합니다.
title: CI/CD 입력
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 15.11](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)에서 베타 기능으로 도입되었습니다.
- [GitLab 17.0](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062)에서 일반적으로 사용 가능하게 되었습니다.

{{< /history >}}

을 사용하여 CI/CD 구성의 유연성을 높입니다. 입력과 [CI/CD 변수](../variables/_index.md)는 비슷한 방식으로 사용할 수 있지만 다른 장점을 제공합니다:

- 입력은 파이프라인 생성 시 기본 유효성 검사를 포함한 재사용 가능한 템플릿에 입력된 매개변수를 제공합니다. 파이프라인이 실행될 때 특정 값을 정의하려면 CI/CD 변수 대신 입력을 사용합니다.
- CI/CD 변수는 여러 수준에서 정의할 수 있는 유연한 값을 제공하지만 파이프라인 실행 전체에서 수정할 수 있습니다. 작업의 런타임 환경에 액세스해야 하는 값에는 변수를 사용합니다. [사전 정의된 변수](../variables/predefined_variables.md)를 `rules`와 함께 사용하여 동적 파이프라인 구성을 할 수 있습니다.

## CI/CD 입력과 변수 비교 {#cicd-inputs-and-variables-comparison}

입력:

- **Purpose**:  CI 구성(템플릿, 구성 요소 또는 `.gitlab-ci.yml`)에서 정의되고 파이프라인이 트리거될 때 값이 할당되어 소비자가 재사용 가능한 CI 구성을 사용자 지정할 수 있도록 합니다.
- **Modification**:  파이프라인 초기화 시 전달되면 입력 값은 CI/CD 구성에 보간되고 전체 파이프라인 실행 동안 고정되어 있습니다.
- **범위**:  `.gitlab-ci.yml`에 있는지 또는 `include`되는 파일인지 여부에 관계없이 정의된 파일에서만 사용 가능합니다. `include:inputs`를 사용하여 다른 파일에 명시적으로 전달하거나 `trigger:inputs`를 사용하여 파이프라인에 전달할 수 있습니다.
- **Validation**:  형식 검사, 정규식 패턴, 사전 정의된 옵션 목록 및 사용자를 위한 유용한 설명을 포함한 강력한 유효성 검사 기능을 제공합니다.

CI/CD 변수:

- **Purpose**:  작업 실행 중 및 파이프라인의 다양한 부분에서 환경 변수로 설정할 수 있는 값으로, 작업 간에 데이터를 전달합니다.
- **Modification**:  dotenv 아티팩트, 조건부 규칙 또는 작업 스크립트에서 직접 파이프라인 실행 중에 동적으로 생성되거나 수정할 수 있습니다.
- **범위**:  전역적으로(모든 작업에 영향), 작업 수준에서(특정 작업에만 영향) 또는 GitLab UI를 통해 전체 프로젝트 또는 그룹에 대해 정의할 수 있습니다.
- **Validation**:  최소한의 기본 제공 유효성 검사가 있는 단순 키-값 쌍이지만, 프로젝트 변수에 대해 GitLab UI를 통해 일부 제어를 추가할 수 있습니다.

## `spec:inputs`를 사용하여 입력 매개변수 정의 {#define-input-parameters-with-specinputs}

CI/CD 구성 [헤더](../yaml/_index.md#header-keywords)에서 `spec:inputs`를 사용하여 구성 파일에 전달할 수 있는 입력 매개변수를 정의합니다.

헤더 섹션 외부에서 `$[[ inputs.input-id ]]` 보간 형식을 사용하여 입력을 사용할 위치를 선언합니다.

예를 들어:

```yaml
spec:
  inputs:
    job-stage:
      default: test
    environment:
      default: production
---
scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

이 예에서 입력은 `job-stage`과 `environment`입니다.

`spec` 섹션이 있는 파일에서만 입력 값을 사용할 수 있습니다. `include`로 추가된 다른 파일에서 입력 값을 사용하려면 [명시적으로 포함된 파일에 전달](#for-configuration-added-with-include)합니다.

`spec:inputs`를 사용하면:

- `default`이 지정되지 않으면 입력이 필수입니다.
- 입력은 파이프라인 생성 중에 구성을 가져올 때 평가되고 채워집니다.
- 입력을 포함하는 문자열은 1 MB 미만이어야 합니다.
- 입력 내의 문자열은 1 KB 미만이어야 합니다.
- 입력은 CI/CD 변수를 사용할 수 있지만 [`include` 키워드와 동일한 변수 제한](../yaml/includes.md#use-variables-with-include)이 있습니다.
- `spec:inputs`을 정의하는 파일에 작업 정의도 포함되는 경우 헤더 뒤에 YAML 문서 구분자(`---`)를 추가합니다.

그런 후 다음 경우에 입력 값을 설정합니다:

- 이 구성 파일을 사용하여 [새 파이프라인 실행](#for-a-pipeline)합니다. `include` 이외의 다른 방법으로 입력을 사용하여 새 파이프라인을 구성할 때 항상 기본값을 설정해야 합니다. 그렇지 않으면 새 파이프라인이 자동으로 트리거될 경우 파이프라인이 시작되지 않을 수 있습니다:
  - 머지 리퀘스트 파이프라인
  - 브랜치 파이프라인
  - 태그 파이프라인
- 파이프라인에 [구성 포함](#for-configuration-added-with-include)합니다. 필수인 모든 입력을 `include:inputs` 섹션에 추가해야 하며, 구성이 포함될 때마다 사용됩니다.

### 입력 구성 {#input-configuration}

입력을 구성하려면 다음을 사용하세요:

- [`spec:inputs:default`](../yaml/_index.md#specinputsdefault)를 사용하여 지정되지 않을 때 입력의 기본값을 정의합니다. 기본값을 지정하면 입력이 더 이상 필수가 아닙니다.
- [`spec:inputs:description`](../yaml/_index.md#specinputsdescription)를 사용하여 특정 입력에 설명을 제공합니다. 설명은 입력에 영향을 주지 않지만 사용자가 입력 세부 정보 또는 예상 값을 이해하는 데 도움이 될 수 있습니다.
- [`spec:inputs:options`](../yaml/_index.md#specinputsoptions)를 사용하여 입력에 허용된 값의 목록을 지정합니다.
- [`spec:inputs:regex`](../yaml/_index.md#specinputsregex)를 사용하여 입력이 일치해야 하는 정규식을 지정합니다.
- [`spec:inputs:type`](../yaml/_index.md#specinputstype)를 사용하여 특정 입력 형식을 강제하며, `string`(지정하지 않을 때 기본값), `array`, `number` 또는 `boolean`일 수 있습니다.
- [`spec:inputs:rules`](../yaml/_index.md#specinputsrules)를 사용하여 다른 입력의 값을 기반으로 조건부 `options` 및 `default` 값을 정의합니다.

CI/CD 구성 파일당 여러 입력을 정의할 수 있으며 각 입력은 여러 구성 매개변수를 가질 수 있습니다.

예를 들어 `scan-website-job.yml`이라는 파일에서:

```yaml
spec:
  inputs:
    job-prefix:     # Mandatory string input
      description: "Define a prefix for the job name"
    job-stage:      # Optional string input with a default value when not provided
      default: test
    environment:    # Mandatory input that must match one of the options
      options: ['test', 'staging', 'production']
    concurrency:
      type: number  # Optional numeric input with a default value when not provided
      default: 1
    version:        # Mandatory string input that must match the regular expression
      type: string
      regex: ^v\d\.\d+(\.\d+)$
    export_results: # Optional boolean input with a default value when not provided
      type: boolean
      default: true
---

"$[[ inputs.job-prefix ]]-scan-website":
  stage: $[[ inputs.job-stage ]]
  script:
    - echo "scanning website -e $[[ inputs.environment ]] -c $[[ inputs.concurrency ]] -v $[[ inputs.version ]]"
    - if $[[ inputs.export_results ]]; then echo "export results"; fi
```

이 예에서:

- `job-prefix`은 필수 문자열 입력이며 정의해야 합니다.
- `job-stage`은 선택 사항입니다. 정의되지 않으면 값은 `test`입니다.
- `environment`은 정의된 옵션 중 하나와 일치해야 하는 필수 문자열 입력입니다.
- `concurrency`은 선택적 숫자 입력입니다. 지정되지 않으면 `1`로 기본값이 설정됩니다.
- `version`은 지정된 정규식과 일치해야 하는 필수 문자열 입력입니다.
- `export_results`은 선택적 부울 입력입니다. 지정되지 않으면 `true`로 기본값이 설정됩니다.

### 입력 형식 {#input-types}

선택적 `spec:inputs:type` 키워드를 사용하여 입력이 특정 형식을 사용해야 함을 지정할 수 있습니다.

입력 형식은:

- [`array`](#array-type)
- `boolean`
- `number`
- `string`(지정하지 않을 때 기본값)

입력이 CI/CD 구성에서 전체 YAML 값을 바꾸면 지정된 형식으로 구성에 보간됩니다. 예를 들어:

```yaml
spec:
  inputs:
    array_input:
      type: array
    boolean_input:
      type: boolean
    number_input:
      type: number
    string_input:
      type: string
---

test_job:
  allow_failure: $[[ inputs.boolean_input ]]
  needs: $[[ inputs.array_input ]]
  parallel: $[[ inputs.number_input ]]
  script: $[[ inputs.string_input ]]
```

입력이 더 큰 문자열의 일부로 YAML 값에 삽입되면 입력은 항상 문자열로 보간됩니다. 예를 들어:

```yaml
spec:
  inputs:
    port:
      type: number
---

test_job:
  script: curl "https://gitlab.com:$[[ inputs.port ]]"
```

#### 배열 형식 {#array-type}

{{< history >}}

- [GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/issues/407176)에서 도입되었습니다.

{{< /history >}}

배열 형식의 항목 내용은 모든 유효한 YAML 맵, 시퀀스 또는 스칼라일 수 있습니다. [`!reference`](../yaml/yaml_optimization.md#reference-tags)와 같은 더 복잡한 YAML 기능은 사용할 수 없습니다. 배열 입력의 값을 문자열(예: `echo "My rules: $[[ inputs.rules-config ]]"`) `script:` 섹션)에서 사용할 때 예상치 못한 결과가 나타날 수 있습니다. 배열 입력은 문자열 표현으로 변환되며, 이는 맵과 같은 복잡한 YAML 구조에 대한 예상과 일치하지 않을 수 있습니다.

```yaml
spec:
  inputs:
    rules-config:
      type: array
      default:
        - if: $CI_PIPELINE_SOURCE == "merge_request_event"
          when: manual
        - if: $CI_PIPELINE_SOURCE == "schedule"
---

test_job:
  rules: $[[ inputs.rules-config ]]
  script: ls
```

배열 입력을 다음에 대해 수동으로 전달할 때 `["array-input-1", "array-input-2"]`과 같이 JSON으로 형식화해야 합니다:

- [파이프라인 수동 실행](../pipelines/_index.md#run-a-pipeline-manually).
- [파이프라인 트리거 API](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token).
- [파이프라인 API](../../api/pipelines.md#create-a-new-pipeline).
- Git [푸시 옵션](../../topics/git/commit.md#push-options-for-gitlab-cicd)
- [파이프라인 일정](../pipelines/schedules.md#create-a-pipeline-schedule)

##### 옵션이 있는 배열 입력 {#array-inputs-with-options}

{{< history >}}

- [GitLab 19.0](https://gitlab.com/gitlab-org/gitlab/-/issues/566155)에서 도입되었습니다.

{{< /history >}}

배열 입력에 대해 허용된 값을 제한하는 옵션 목록을 정의할 수 있습니다. 파이프라인을 수동으로 실행하면 UI에 텍스트 필드 대신 다중 선택 드롭다운이 표시됩니다. 예를 들어:

```yaml
spec:
  inputs:
    runner_tags:
      type: array
      default: ["docker"]
      options:
        - docker
        - linux
        - gpu
        - macos
---

test:
  script:
    - run_tests.sh
  tags: $[[ inputs.runner_tags ]]
```

배열 입력의 모든 값이 나열된 옵션과 일치하지 않으면 파이프라인이 시작되지 않습니다.

##### 개별 배열 요소 액세스 {#access-individual-array-elements}

{{< history >}}

- [GitLab 18.10](https://gitlab.com/gitlab-org/gitlab/-/work_items/587657) 에서 [플래그](../../administration/feature_flags/_index.md) `ci_inputs_array_index_operator`로 도입되었습니다. 기본적으로 비활성화됨.
- [GitLab 18.11](https://gitlab.com/gitlab-org/gitlab/-/work_items/587657)에서 일반적으로 사용 가능합니다. 기능 플래그 `ci_inputs_array_index_operator`이 제거되었습니다.

{{< /history >}}

배열 입력의 개별 요소에 액세스하기 위해 인덱스 번호가 있는 괄호 표기법을 사용합니다. 배열 항목은 YAML 배열에 정의된 순서대로 양수로 인덱싱되며, `[0]` 인덱스 항목이 배열의 첫 번째 항목입니다.

예를 들어:

```yaml
spec:
  inputs:
    supported_versions:
      type: array
      default:
        - '2.0'
        - '1.0'
        - '0.1'
---

job:
  script:
    # Outputs: 'Latest version is 2.0'
    - echo 'Latest version is $[[ inputs.supported_versions[0] ]]'
```

배열 인덱싱을 점 표기법과 함께 연결하여 중첩된 값에 액세스할 수 있습니다:

```yaml
spec:
  inputs:
    servers:
      type: array
      default:
        - host: server1.example.com
          port: 8080
---

job:
  script:
    - curl "https://$[[ inputs.servers[0].host ]]:$[[ inputs.servers[0].port ]]"
```

다차원 배열의 경우 여러 인덱스를 행으로 사용합니다. 예를 들어 2차원 배열에 `[0][1]`을 사용할 수 있습니다:

```yaml
spec:
  inputs:
    matrix:
      type: array
      default:
        - ['a', 'b']
        - ['c', 'd']
---

job:
  script:
    # Outputs: 'b'
    - echo $[[ inputs.matrix[0][1] ]]
```

세그먼트당 최대 5개의 인덱스를 연결할 수 있습니다(예: `arr[0][1][2][3][4]`).

#### 다중 행 입력 문자열 값 {#multi-line-input-string-values}

입력은 다양한 값 형식을 지원합니다. 다음 형식을 사용하여 다중 문자열 값을 전달할 수 있습니다:

```yaml
spec:
  inputs:
    closed_message:
      description: Message to announce when an issue is closed.
      default: 'Hi {{author}} :wave:,

        Based on the policy for inactive issues, this is now being closed.

        If this issue requires further attention, reopen this issue.'
---
```

### `spec:inputs:rules`를 사용하여 조건부 입력 옵션 정의 {#define-conditional-input-options-with-specinputsrules}

{{< history >}}

- [GitLab 18.7](https://gitlab.com/groups/gitlab-org/-/epics/18546)에서 도입되었습니다.

{{< /history >}}

[`spec:inputs:rules`](../yaml/_index.md#specinputsrules)를 사용하여 다른 입력의 값을 기반으로 입력에 대한 다른 `options` 및 `default` 값을 정의합니다. 한 입력이 다른 입력에서 제공하는 컨텍스트에 따라 다른 허용 값을 가져야 할 때 이 구성을 사용할 수 있습니다.

`rules` 목록의 각 규칙은 다음을 포함할 수 있습니다:

- `if`:  이 규칙이 적용될 때를 결정하기 위해 하나 이상의 입력 값을 확인하는 표현식입니다. [`$[[ inputs.input-id ]]` 보간](#define-input-parameters-with-specinputs)과 동일한 구문을 사용합니다.
- `options`:  이 규칙이 일치할 때 입력에 허용되는 값의 목록입니다.
- `default`:  이 규칙이 일치할 때 사용할 기본값입니다.

규칙은 순서대로 평가됩니다. 일치하는 `if` 조건이 있는 첫 번째 규칙이 사용됩니다. `if` 조건이 없는 마지막 규칙은 다른 규칙이 일치하지 않을 때 대체로 작동합니다.

예를 들어 클라우드 공급자와 환경에 따라 달라지는 인스턴스 형식을 정의하려면:

```yaml
spec:
  inputs:
    cloud_provider:
      options: ['aws', 'gcp', 'azure']
      default: 'aws'
      description: 'Cloud provider'

    environment:
      options: ['development', 'staging', 'production']
      default: 'development'
      description: 'Target environment'

    instance_type:
      description: 'VM instance type'
      rules:
        - if: $[[ inputs.cloud_provider ]] == 'aws' && $[[ inputs.environment ]] == 'development'
          options: ['t3.micro', 't3.small']
          default: 't3.micro'
        - if: $[[ inputs.cloud_provider ]] == 'aws' && $[[ inputs.environment ]] == 'production'
          options: ['t3.xlarge', 't3.2xlarge', 'm5.xlarge']
          default: 't3.xlarge'
        - if: $[[ inputs.cloud_provider ]] == 'gcp'
          options: ['e2-micro', 'e2-small', 'e2-standard-4']
          default: 'e2-micro'
        - if: $[[ inputs.cloud_provider ]] == 'azure'
          options: ['Standard_B1s', 'Standard_B2s', 'Standard_D2s_v3']
          default: 'Standard_B1s'
        - options: ['small', 'medium', 'large']  # Fallback for any other case
          default: 'small'
---

deploy:
  script: |
    echo "Deploying to $[[ inputs.cloud_provider ]]"
    echo "Environment: $[[ inputs.environment ]]"
    echo "Instance: $[[ inputs.instance_type ]]"
```

이 예에서:

- `cloud_provider`이 `aws`이고 `environment`이 `development`일 때 사용자는 `t3.micro` 또는 `t3.small` 인스턴스 형식에서 선택할 수 있으며, `t3.micro`이 기본값입니다.
- `cloud_provider`이 `aws`이고 `environment`이 `production`일 때 다양한 인스턴스 형식(`t3.xlarge`, `t3.2xlarge`, `m5.xlarge`)을 사용할 수 있습니다.
- `cloud_provider`이 `gcp`일 때 환경에 관계없이 GCP 관련 인스턴스 형식을 사용할 수 있습니다.
- 조건이 일치하지 않으면 대체 규칙이 일반적인 크기 옵션을 제공합니다.

`||`(OR) 연산자를 사용하여 여러 조건과 일치할 수도 있습니다. 예를 들어:

```yaml
spec:
  inputs:
    deployment_type:
      options: ['canary', 'blue-green', 'rolling', 'recreate']
      default: 'rolling'

    requires_approval:
      description: 'Whether deployment requires manual approval'
      rules:
        - if: $[[ inputs.deployment_type ]] == 'canary' || $[[ inputs.deployment_type ]] == 'blue-green'
          options: ['true']
          default: 'true'
        - options: ['true', 'false']
          default: 'false'
---

deploy:
  script: echo "Deploying with $[[ inputs.deployment_type ]] strategy"
```

이 예에서 `requires_approval` 입력은 `deployment_type`이 `canary` 또는 `blue-green`일 때 `true`로 설정됩니다. 다른 모든 경우에는 기본값이 `false`이고 `true` 또는 `false`이 모두 허용된 옵션입니다.

### `default: null`를 사용하여 사용자가 입력한 값 허용 {#allow-user-entered-values-with-default-null}

{{< history >}}

- [GitLab 18.9](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218804)에서 도입되었습니다.

{{< /history >}}

`spec:inputs:rules`를 `default: null`과 함께 사용하고 `options` 없이 사용하여 사용자가 입력의 고유한 값을 입력하도록 허용합니다. 이는 환경 이름 또는 테스트 구성과 같은 워크플로우별 값에 유용합니다.

예를 들어:

```yaml
spec:
  inputs:
    deployment_type:
      options: ['standard', 'custom']
      default: 'standard'

    custom_config:
      description: 'Custom configuration value'
      rules:
        - if: $[[ inputs.deployment_type ]] == 'custom'
          default: null
---

deploy:
  script: echo "Config: $[[ inputs.custom_config ]]"
```

이 예에서 `deployment_type`이 `custom`일 때 `custom_config` 입력은 파이프라인 실행 페이지에 나열되고 사용자는 입력 값을 입력해야 합니다.

### `spec:inputs:rules`을 사용하여 부울 입력 사용 {#use-boolean-inputs-with-specinputsrules}

규칙 조건에서 부울 입력을 사용할 수 있습니다. 부울 값은 부울 리터럴(`true`/`false`)을 사용하여 비교할 수 있습니다:

```yaml
spec:
  inputs:
    publish:
      type: boolean
      default: true

    publish_stage:
      rules:
        - if: $[[ inputs.publish ]] == true
          default: 'publish'
        - if: $[[ inputs.publish ]] == false
          default: 'test'
---

job:
  stage: $[[ inputs.publish_stage ]]
  script: echo "Publishing is $[[ inputs.publish ]]"
```

이 예에서 `publish`이 `true`일 때 `publish_stage`은 `publish`로 기본값이 설정됩니다. `publish`이 `false`일 때는 `test`로 기본값이 설정됩니다.

## 입력 값 설정 {#set-input-values}

파이프라인 구성에서 또는 파이프라인을 트리거할 때 입력 값을 설정할 수 있습니다.

파이프라인이 시작된 후에는 사용된 입력 값을 가져올 수 없습니다. 값이 노출하기에 안전하면 향후 참조용으로 작업 로그에서 값을 출력하거나 아티팩트에 저장할 수 있습니다.

### `include`로 추가된 구성 {#for-configuration-added-with-include}

{{< history >}}

- `include:with`이 GitLab 16.0에서 [`include:inputs`으로 이름이 변경](https://gitlab.com/gitlab-org/gitlab/-/issues/406780)되었습니다.

{{< /history >}}

[`include:inputs`](../yaml/_index.md#includeinputs)를 사용하여 포함된 구성이 파이프라인에 추가될 때 입력의 값을 설정합니다:

- [CI/CD 구성 요소](../components/_index.md)
- `include`로 추가된 다른 구성입니다.

예를 들어 `scan-website-job.yml`에 대한 입력 값을 포함하고 설정하려면 [입력 구성 예](#input-configuration):

```yaml
include:
  - local: 'scan-website-job.yml'
    inputs:
      job-prefix: 'some-service-'
      environment: 'staging'
      concurrency: 2
      version: 'v1.3.2'
      export_results: false
```

이 예에서 포함된 구성의 입력은:

| 입력            | 값           | 세부 정보 |
|------------------|-----------------|---------|
| `job-prefix`     | `some-service-` | 명시적으로 정의해야 합니다. |
| `job-stage`      | `test`          | `include:inputs`에서 정의되지 않았으므로 값이 포함된 구성의 `spec:inputs:default`에서 나옵니다. |
| `environment`    | `staging`       | 명시적으로 정의해야 하며, 포함된 구성의 `spec:inputs:options` 값 중 하나와 일치해야 합니다. |
| `concurrency`    | `2`             | 포함된 구성에서 `number`로 설정된 `spec:inputs:type`과 일치하도록 숫자 값이어야 합니다. 기본값을 재정의합니다. |
| `version`        | `v1.3.2`        | 명시적으로 정의해야 하며, 포함된 구성의 `spec:inputs:regex` 정규식과 일치해야 합니다. |
| `export_results` | `false`         | 포함된 구성에서 `boolean`로 설정된 `spec:inputs:type`과 일치하도록 `true` 또는 `false`이어야 합니다. 기본값을 재정의합니다. |

입력 값은 `spec` 섹션을 정의하는 같은 파일에서만 사용 가능합니다. `include`로 추가된 파일은 다른 파일이나 포함하는 파일에서 정의된 입력에 액세스할 수 없습니다. 포함된 파일의 값을 사용하려면 `include:inputs`으로 명시적으로 전달합니다.

#### 여러 `include` 항목 {#with-multiple-include-entries}

입력은 각 포함 항목에 대해 별도로 지정해야 합니다. 예를 들어:

```yaml
include:
  - component: $CI_SERVER_FQDN/the-namespace/the-project/the-component@1.0
    inputs:
      stage: my-stage
  - local: path/to/file.yml
    inputs:
      stage: my-stage
```

### 파이프라인 {#for-a-pipeline}

{{< history >}}

- [GitLab 17.11](https://gitlab.com/groups/gitlab-org/-/epics/16321)에서 도입되었습니다.

{{< /history >}}

입력은 형식 검사, 유효성 검사 및 명확한 계약을 포함하여 변수보다 많은 장점을 제공합니다. 예상치 못한 입력은 거부됩니다. 파이프라인의 입력은 메인 `.gitlab-ci.yml` 파일의 [`spec:inputs` 헤더](#define-input-parameters-with-specinputs)에서 정의해야 합니다. 포함된 파일에 정의된 입력을 파이프라인 수준 구성에 사용할 수 없습니다.

> [!note]
> [GitLab 17.7](../../update/deprecations.md#increased-default-security-for-use-of-pipeline-variables) 이상에서는 [파이프라인 변수](../variables/_index.md#use-pipeline-variables)를 전달하는 것보다 파이프라인 입력을 권장합니다. 보안 강화를 위해 입력을 사용할 때 [파이프라인 변수를 비활성화](../variables/_index.md#restrict-pipeline-variables)해야 합니다.

파이프라인에 대한 입력을 정의할 때 항상 기본값을 설정해야 합니다. 입력이 기본값이 누락되면 자동으로 트리거될 때 파이프라인이 실패합니다. 예를 들어 머지 리퀘스트 파이프라인은 머지 리퀘스트의 소스 브랜치 변경에 대해 트리거될 수 있습니다. 머지 리퀘스트 파이프라인에 대해 입력을 수동으로 설정할 수 없으므로 입력이 기본값이 누락되면 파이프라인이 실패합니다. 이는 브랜치 파이프라인, 태그 파이프라인 및 기타 자동으로 트리거되는 파이프라인에서도 발생할 수 있습니다.

다음을 사용하여 입력 값을 설정할 수 있습니다:

- [다운스트림 파이프라인](../pipelines/downstream_pipelines.md#pass-inputs-to-a-downstream-pipeline)
- [파이프라인 수동 실행](../pipelines/_index.md#run-a-pipeline-manually).
- [파이프라인 트리거 API](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)
- [파이프라인 API](../../api/pipelines.md#create-a-new-pipeline)
- Git [푸시 옵션](../../topics/git/commit.md#push-options-for-gitlab-cicd)
- [파이프라인 일정](../pipelines/schedules.md#create-a-pipeline-schedule)
- [`trigger` 키워드](../pipelines/downstream_pipelines.md#pass-inputs-to-a-downstream-pipeline)

파이프라인은 최대 20개의 입력을 받을 수 있습니다.

[이 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/533802)에서 피드백을 환영합니다.

다운스트림 파이프라인의 구성 파일이 [`spec:inputs`](#define-input-parameters-with-specinputs) 를 사용하는 경우 [다운스트림 파이프라인](../pipelines/downstream_pipelines.md)에 입력을 전달할 수 있습니다.

예를 들어 [`trigger:inputs`](../yaml/_index.md#triggerinputs)와 함께:

{{< tabs >}}

{{< tab title="상위-하위 파이프라인" >}}

```yaml
trigger-job:
  trigger:
    strategy: mirror
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

{{< /tab >}}

{{< tab title="다중 프로젝트 파이프라인" >}}

```yaml
trigger-job:
  trigger:
    strategy: mirror
    project: project-group/my-downstream-project
    inputs:
      job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

{{< /tab >}}

{{< /tabs >}}

#### 외부 파일에서 파이프라인 입력 정의 {#define-pipeline-inputs-in-external-files}

{{< history >}}

- [GitLab 18.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206931) 에서 [플래그](../../administration/feature_flags/_index.md) `ci_file_inputs`로 도입되었습니다. 기본적으로 비활성화됨.
- [GitLab 18.9](https://gitlab.com/gitlab-org/gitlab/-/issues/579240)에서 일반적으로 사용 가능합니다. 기능 플래그 `ci_file_inputs`이 제거되었습니다.

{{< /history >}}

외부 파일에서 정의하고 [`spec:include`](../yaml/_index.md#specinclude)를 사용하여 프로젝트의 파이프라인 구성에 포함하여 여러 CI/CD 구성에서 파이프라인 입력 정의를 재사용할 수 있습니다.

입력 정의가 포함된 파일(예: `shared-inputs.yml`이라는 파일)을 만듭니다:

```yaml
inputs:
  environment:
    description: "Deployment environment"
    options: ['staging', 'production']
  region:
    default: 'us-east-1'
```

그런 다음 `local`를 사용하여 `.gitlab-ci.yml`에서 외부 입력을 포함할 수 있습니다:

```yaml
spec:
  include:
    - local: /shared-inputs.yml
---

deploy:
  script: echo "Deploying to $[[ inputs.environment ]] in $[[ inputs.region ]]"
```

파일이 프로젝트 외부에 저장된 경우 다음을 사용할 수 있습니다:

- 다른 GitLab 프로젝트의 파일에 `project`을 사용합니다. 전체 프로젝트 경로를 사용하고 `file`를 사용하여 파일 이름을 정의합니다. 선택 사항으로 `ref`를 정의하여 파일을 가져올 수도 있습니다.
- 다른 서버의 파일에 `remote`을 사용합니다. 파일의 전체 URL을 사용합니다.

예를 들어 동시에 여러 입력 파일을 포함할 수도 있습니다:

```yaml
spec:
  include:
    - local: /shared-inputs.yml
    - project: 'my-group/shared-configs'
      ref: main
      file: '/ci/common-inputs.yml'
    - remote: 'https://example.com/ci/shared-inputs.yml'
---
```

> [!note]
> `spec:include`를 [CI/CD 구성 요소](../components/_index.md#component-spec-section) 입력에 사용할 수 없습니다.

#### 외부 파일에서 입력 재정의 {#override-inputs-from-an-external-file}

{{< history >}}

- [GitLab 18.9](https://gitlab.com/gitlab-org/gitlab/-/issues/557867)에서 도입되었습니다.

{{< /history >}}

입력 키는 모든 포함된 파일과 인라인 사양에서 고유해야 합니다. 여러 포함된 파일이나 포함된 파일과 `.gitlab-ci.yml` 구성의 `inputs:` 섹션 모두에서 동일한 키를 사용하여 입력을 정의하는 경우 다음 오류가 반환됩니다:

```plaintext
Duplicate input keys found: environment. Input keys must be unique across all included files and inline specifications.
```

이 오류를 해결하려면 각 입력 키가 포함된 파일이나 인라인 `inputs:` 섹션 중 하나에만 정의되도록 하되 둘 다에서는 정의하지 않도록 합니다.

## 입력 값을 조작할 함수 지정 {#specify-functions-to-manipulate-input-values}

{{< history >}}

- [GitLab 16.3](https://gitlab.com/gitlab-org/gitlab/-/issues/409462)에서 도입되었습니다.

{{< /history >}}

보간 블록에서 사전 정의된 함수를 지정하여 입력 값을 조작할 수 있습니다. 지원되는 형식은 다음과 같습니다:

```yaml
$[[ input.input-id | <function1> | <function2> | ... <functionN> ]]
```

함수 사용:

- [사전 정의된 보간 함수](#predefined-interpolation-functions)만 허용됩니다.
- 단일 보간 블록에 최대 3개의 함수를 지정할 수 있습니다.
- 함수는 지정된 순서대로 실행됩니다.

```yaml
spec:
  inputs:
    test:
      default: 'test $MY_VAR'
---

test-job:
  script: echo $[[ inputs.test | expand_vars | truncate(5,8) ]]
```

이 예에서 입력이 기본값을 사용하고 `$MY_VAR`이 값 `my value`의 마스크되지 않은 프로젝트 변수라고 가정합니다:

1. 먼저 [`expand_vars`](#expand_vars) 함수는 값을 `test my value`로 확장합니다.
1. 그런 다음 [`truncate`](#truncate)는 `test my value`에 `5`의 문자 오프셋과 `8`의 길이로 적용됩니다.
1. `script`의 출력은 `echo my value`입니다.

### 사전 정의된 보간 함수 {#predefined-interpolation-functions}

#### `expand_vars` {#expand_vars}

{{< history >}}

- [GitLab 16.5](https://gitlab.com/gitlab-org/gitlab/-/issues/387632)에서 도입되었습니다.

{{< /history >}}

`expand_vars`를 사용하여 입력 값에서 [CI/CD 변수](../variables/_index.md)를 확장합니다.

[`include` 키워드와 함께 사용](../yaml/includes.md#use-variables-with-include)할 수 있는 유일한 변수이고 확장 가능한 것으로 [표시](../variables/_index.md#mask-a-cicd-variable)되지 **않습니다.** [중첩된 변수 확장](../variables/where_variables_can_be_used.md#nested-variable-expansion)은 지원되지 않습니다.

예:

```yaml
spec:
  inputs:
    test:
      default: 'test $MY_VAR'
---

test-job:
  script: echo $[[ inputs.test | expand_vars ]]
```

이 예에서 `$MY_VAR`이 마스크되지 않았거나(작업 로그에 노출됨) 값 `my value`이면 입력이 `test my value`으로 확장됩니다.

#### `truncate` {#truncate}

{{< history >}}

- [GitLab 16.3](https://gitlab.com/gitlab-org/gitlab/-/issues/409462)에서 도입되었습니다.

{{< /history >}}

`truncate`를 사용하여 보간된 값을 단축합니다. 예를 들어:

- `truncate(<offset>,<length>)`

| 이름 | 형식 | 설명 |
| ---- | ---- | ----------- |
| `offset` | 정수 | 오프셋할 문자 수입니다. |
| `length` | 정수 | 오프셋 후 반환할 문자 수입니다. |

예:

```yaml
$[[ inputs.test | truncate(3,5) ]]
```

`inputs.test`의 값이 `0123456789`이면 출력은 `34567`입니다.

#### `posix_escape` {#posix_escape}

{{< history >}}

- [GitLab 18.6](https://gitlab.com/gitlab-org/gitlab/-/issues/568289)에서 도입되었습니다.

{{< /history >}}

`posix_escape`를 사용하여 입력 값의 POSIX _Bourne 셸_ 제어 또는 메타 문자를 이스케이프합니다. `posix_escape`는 ` \ `를 입력의 관련 문자 앞에 삽입하여 문자를 이스케이프합니다.

예:

```yaml
spec:
  inputs:
    test:
      default: |
        A string with single ' and double " quotes and   blanks
---

test-job:
  script: printf '%s\n' $[[ inputs.test | posix_escape ]]
```

이 예에서 `posix_escape`은 셸 제어 또는 메타데이터 문자일 수 있는 문자를 이스케이프합니다:

```console
$ printf '%s\n' A\ string\ with\ single\ \'\ and\ double\ \"\ quotes\ and\ \ \ blanks
A string with single ' and double " quotes and   blanks
```

이스케이프된 입력은 제공된 대로 특수 문자 및 간격을 유지합니다.

> [!warning]
> 신뢰할 수 없는 입력 값에 대해 `posix_escape`를 보안 목적으로 의존하지 마세요.

`posix_escape`는 입력 값을 정확히 유지하려고 최선의 노력을 하지만 일부 문자 조합은 여전히 원하지 않는 결과를 초래할 수 있습니다. `posix_escape`를 사용하는 경우에도 다음이 가능합니다:

- 문자열에 포함된 셸 코드가 실행될 수 있습니다.
- 작은따옴표 또는 큰따옴표를 사용하여 주변 인용을 이스케이프할 수 있습니다.
- 변수 참조를 사용하여 보호된 변수에 액세스할 수 있습니다.
- 입력 또는 출력 리디렉션을 사용하여 로컬 파일을 읽거나 쓸 수 있습니다.
- 이스케이프되지 않은 공백은 셸에서 문자열을 여러 인수로 분할하는 데 사용됩니다.

보안상 입력이 신뢰할 수 있는지 확인해야 합니다. 다음을 사용할 수 있습니다:

- 문제가 있는 문자를 포함할 수 없는 [`spec:input:type`](../yaml/_index.md#specinputstype) `number` 또는 `boolean`.
- 문제가 있는 입력을 방지하기 위한 [`spec:input:regex`](../yaml/_index.md#specinputsregex) 키워드.
- 사전 정의된 입력 옵션 목록을 정의하기 위한 [`spec:input:options`](../yaml/_index.md#specinputsoptions) 키워드.

`posix_escape`을 `expand_vars`과 결합하는 경우 먼저 `expand_vars`을 설정해야 합니다. 그렇지 않으면 `posix_escape`이 변수의 `$`을 이스케이프하여 확장을 방지합니다. 예를 들어:

```yaml
test-job:
  script: echo $[[ inputs.test | expand_vars | posix_escape ]]
```

## 문제 해결 {#troubleshooting}

### `inputs`을 `rules`에서 사용할 때의 YAML 구문 오류 {#yaml-syntax-errors-when-using-inputs-in-rules}

입력을 사용하여 `rules:if` 표현식을 수정할 때 [다양한 구문 오류](../jobs/job_troubleshooting.md#this-gitlab-ci-configuration-is-invalid-for-variable-expressions) 중 하나가 발생할 수 있습니다.

이러한 오류는 종종 [CI/CD 변수 표현식](../jobs/job_rules.md#cicd-variable-expressions)에서 문자열을 처리하는 방식과 관련이 있습니다. `rules:if`의 표현식은 CI/CD 변수를 따옴표 문자열(`'` 또는 `"`) 또는 다른 변수와 비교하기를 예상합니다. 입력 값이 파이프라인 런타임에 `rules` 구성에 삽입되면 결과 값이 따옴표 문자열이나 변수가 아닐 수 있으며 이로 인해 오류가 발생합니다.

예를 들어 포함할 구성에서:

```yaml
spec:
  inputs:
    branch:
      default: $CI_DEFAULT_BRANCH
    branch2:
      default: $CI_DEFAULT_BRANCH
---

job-name:
  rules:
    - if: $CI_COMMIT_REF_NAME == $[[ inputs.branch ]]
    - if: $CI_COMMIT_REF_NAME == $[[ inputs.branch2 ]]
```

그런 다음 메인 구성 파일에서:

```yaml
include:
  inputs:
    branch: $CI_DEFAULT_BRANCH  # Valid
    branch2: main               # Invalid
```

이 예에서:

- `branch: $CI_DEFAULT_BRANCH`을 사용하는 것은 유효합니다. `if:` 절은 `if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH`으로 평가되며, 이는 유효한 변수 표현식입니다. 변수를 따옴표로 묶을 필요가 없습니다.
- `branch2: main`을 사용하는 것은 유효하지 않습니다. `if:` 절은 `if: $CI_COMMIT_REF_NAME == main`으로 평가되며, `main`는 문자열이지만 따옴표로 묶이지 않았으므로 유효하지 않습니다.

입력 값을 구성에 삽입한 후 표현식이 올바르게 형식화되어 있는지 확인합니다. 이를 위해 추가 따옴표 문자가 필요할 수 있습니다. 예를 들어 문자열 값을 사용하는 규칙에 따옴표를 추가합니다:

```yaml
rules:
  if: $CI_COMMIT_REF_NAME == "$[[ inputs.branch2 ]]"
```

[`expand_vars`](#expand_vars)와 같은 보간 함수의 경우 전체 `if:` 표현식을 따옴표로 묶어야 할 수도 있습니다. 예를 들어:

```yaml
spec:
  inputs:
    environment:
      default: "$ENVIRONMENT"
---

$[[ inputs.environment | expand_vars ]] job:
  script: echo
  rules:
    - if: '"$[[ inputs.environment | expand_vars ]]" == "production"'
```

이 예에서 입력과 전체 `if:` 표현식을 모두 따옴표로 묶으면 입력이 평가된 후 유효한 구문을 보장합니다. 따옴표가 중첩된 경우 내부 따옴표에는 `"`를 사용하고 외부 따옴표에는 `'`를 사용하거나 그 반대로 사용합니다.

작업 이름은 따옴표로 묶을 필요가 없습니다.
