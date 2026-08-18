---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CD 구성 파일 최적화
description: "YAML 앵커, !reference 태그, `extends` 키워드를 사용하여 CI/CD 구성 파일의 복잡성을 줄입니다."
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD 구성 파일에서 복잡성과 중복된 구성을 줄일 수 있습니다:

- [앵커(`&`)](#anchors), 별칭(`*`), 맵 병합(`<<`) 같은 YAML 특정 기능을 사용합니다. 다양한 [YAML 기능](https://learnxinyminutes.com/docs/yaml/)에 대해 자세히 알아봅니다.
- 더 유연하고 읽기 쉬운 [`extends` 키워드](#use-extends-to-reuse-configuration-sections)를 사용합니다. 가능한 한 `extends`을 사용해야 합니다.

다양한 변수 값으로 여러 개의 유사한 작업을 생성하려면 [parallel:matrix](../jobs/job_control.md#run-a-matrix-of-parallel-trigger-jobs)를 사용합니다.

## 앵커 {#anchors}

YAML에는 문서 전체에서 콘텐츠를 중복하는 데 사용할 수 있는 '앵커'라는 기능이 있습니다.

앵커를 사용하여 속성을 중복하거나 상속할 수 있습니다. [숨겨진 작업](../jobs/_index.md#hide-a-job)과 함께 앵커를 사용하여 작업을 위한 템플릿을 제공합니다.

`&` 문자는 앵커 이름을 표시하고, `*` 문자는 앵커를 참조하는 별칭입니다. YAML 파일에서 앵커를 참조하는 모든 별칭보다 높게 앵커를 정의해야 합니다.

중복 키가 있으면 마지막으로 포함된 키가 우선이 되며 다른 키를 재정의합니다.

특정 경우([스크립트용 YAML 앵커](#yaml-anchors-for-scripts) 참조)에서 YAML 앵커를 사용하여 다른 곳에서 정의된 여러 구성 요소가 있는 배열을 빌드할 수 있습니다. 예를 들어:

```yaml
.default_scripts: &default_scripts
  - ./default-script1.sh
  - ./default-script2.sh

job1:
  script:
    - *default_scripts
    - ./job-script.sh
```

[`include`](_index.md#include) 키워드를 사용할 때 여러 파일에서 YAML 앵커를 사용할 수 없습니다. 앵커는 정의된 파일에서만 유효합니다. 다양한 YAML 파일에서 구성을 재사용하려면 [`!reference` 태그](#reference-tags) 또는 [`extends` 키워드](#use-extends-to-reuse-configuration-sections)를 사용합니다.

다음 예제는 앵커와 맵 병합을 사용합니다. `test1` 및 `test2` 두 개의 작업을 생성하며, 각각 `.job_template` 구성을 상속하고 자신의 `script`를 정의합니다:

```yaml
.job_template: &job_configuration  # Hidden yaml configuration that defines an anchor named 'job_configuration'
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  <<: *job_configuration           # Add the contents of the 'job_configuration' alias
  script:
    - test1 project

test2:
  <<: *job_configuration           # Add the contents of the 'job_configuration' alias
  script:
    - test2 project
```

`&`은 앵커의 이름(`job_configuration`)을 설정하고, `<<`는 '주어진 해시를 현재 해시에 병합'을 의미하며, `*`는 명명된 앵커(`job_configuration`)를 포함합니다. 이 예제의 [확장된](../pipeline_editor/_index.md#view-full-configuration) 버전은 다음과 같습니다:

```yaml
.job_template:
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test1 project

test2:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test2 project
```

앵커를 사용하여 두 세트의 서비스를 정의할 수 있습니다. 예를 들어, `test:postgres` 및 `test:mysql`는 `.job_template`에서 정의된 `script`을 공유하지만 `.postgres_services` 및 `.mysql_services`에서 정의된 다양한 `services`을 사용합니다:

```yaml
.job_template: &job_configuration
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services: &postgres_configuration
    - postgres
    - ruby

.mysql_services:
  services: &mysql_configuration
    - mysql
    - ruby

test:postgres:
  <<: *job_configuration
  services: *postgres_configuration
  tags:
    - postgres

test:mysql:
  <<: *job_configuration
  services: *mysql_configuration
```

[확장된](../pipeline_editor/_index.md#view-full-configuration) 버전은 다음과 같습니다:

```yaml
.job_template:
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services:
    - postgres
    - ruby

.mysql_services:
  services:
    - mysql
    - ruby

test:postgres:
  script:
    - test project
  services:
    - postgres
    - ruby
  tags:
    - postgres

test:mysql:
  script:
    - test project
  services:
    - mysql
    - ruby
  tags:
    - dev
```

숨겨진 작업이 편리하게 템플릿으로 사용되는 것을 볼 수 있으며, `tags: [postgres]`이 `tags: [dev]`을 재정의합니다.

### 스크립트용 YAML 앵커 {#yaml-anchors-for-scripts}

[YAML 앵커](#anchors)를 [script](_index.md#script), [`before_script`](_index.md#before_script), [`after_script`](_index.md#after_script)와 함께 사용하여 여러 작업에서 미리 정의된 명령을 사용할 수 있습니다:

```yaml
.some-script-before: &some-script-before
  - echo "Execute this script first"

.some-script: &some-script
  - echo "Execute this script second"
  - echo "Execute this script too"

.some-script-after: &some-script-after
  - echo "Execute this script last"

job1:
  before_script:
    - *some-script-before
  script:
    - *some-script
    - echo "Execute something, for this job only"
  after_script:
    - *some-script-after

job2:
  script:
    - *some-script-before
    - *some-script
    - echo "Execute something else, for this job only"
    - *some-script-after
```

## `extends`을 사용하여 구성 섹션 재사용 {#use-extends-to-reuse-configuration-sections}

[`extends` 키워드](_index.md#extends)를 사용하여 여러 작업에서 구성을 재사용할 수 있습니다. [YAML 앵커](#anchors)와 유사하지만 더 간단하며 [`extends`를 `includes`와 함께 사용](#use-extends-and-include-together)할 수 있습니다.

`extends`은 다중 레벨 상속을 지원합니다. 추가 복잡성으로 인해 3개 이상의 레벨 사용을 피해야 하지만 최대 11개까지 사용할 수 있습니다. 다음 예제는 두 개 레벨의 상속을 가집니다:

```yaml
.tests:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"

.rspec:
  extends: .tests
  script: rake rspec

rspec 1:
  variables:
    RSPEC_SUITE: '1'
  extends: .rspec

rspec 2:
  variables:
    RSPEC_SUITE: '2'
  extends: .rspec

spinach:
  extends: .tests
  script: rake spinach
```

### `extends`에서 키 제외 {#exclude-a-key-from-extends}

확장된 콘텐츠에서 키를 제외하려면 `null`로 할당해야 하며, 예를 들어:

```yaml
.base:
  script: test
  variables:
    VAR1: base var 1

test1:
  extends: .base
  variables:
    VAR1: test1 var 1
    VAR2: test2 var 2

test2:
  extends: .base
  variables:
    VAR2: test2 var 2

test3:
  extends: .base
  variables: {}

test4:
  extends: .base
  variables: null
```

병합된 구성:

```yaml
test1:
  script: test
  variables:
    VAR1: test1 var 1
    VAR2: test2 var 2

test2:
  script: test
  variables:
    VAR1: base var 1
    VAR2: test2 var 2

test3:
  script: test
  variables:
    VAR1: base var 1

test4:
  script: test
  variables: null
```

### `extends` 및 `include`를 함께 사용 {#use-extends-and-include-together}

다양한 구성 파일에서 구성을 재사용하려면 `extends`과 [`include`](_index.md#include)을 결합합니다.

다음 예제에서 `script`이 `included.yml` 파일에 정의됩니다. 그런 다음 `.gitlab-ci.yml` 파일에서 `extends`는 `script`의 콘텐츠를 참조합니다:

- `included.yml`:

  ```yaml
  .template:
    script:
      - echo Hello!
  ```

- `.gitlab-ci.yml`:

  ```yaml
  include: included.yml

  useTemplate:
    image: alpine
    extends: .template
  ```

### 병합 세부 정보 {#merge-details}

`extends`을 사용하여 해시를 병합할 수 있지만 배열은 병합할 수 없습니다. 중복 키가 있으면 GitLab은 키를 기반으로 역방향 깊은 병합을 수행합니다. 마지막 멤버의 키는 항상 다른 레벨에서 정의된 항목을 재정의합니다. 예를 들어:

```yaml
.only-important:
  variables:
    URL: "http://my-url.internal"
    IMPORTANT_VAR: "the details"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH == "stable"
  tags:
    - production
  script:
    - echo "Hello world!"

.in-docker:
  variables:
    URL: "http://docker-url.internal"
  tags:
    - docker
  image: alpine

rspec:
  variables:
    GITLAB: "is-awesome"
  extends:
    - .only-important
    - .in-docker
  script:
    - rake rspec
```

결과는 이 `rspec` 작업입니다:

```yaml
rspec:
  variables:
    URL: "http://docker-url.internal"
    IMPORTANT_VAR: "the details"
    GITLAB: "is-awesome"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH == "stable"
  tags:
    - docker
  image: alpine
  script:
    - rake rspec
```

이 예에서:

- `variables` 섹션이 병합되지만 `URL: "http://docker-url.internal"`이 `URL: "http://my-url.internal"`을 재정의합니다.
- `tags: ['docker']`이 `tags: ['production']`을 재정의합니다.
- `script`은 병합되지 않지만 `script: ['rake rspec']`이 `script: ['echo "Hello world!"']`을 재정의합니다. [YAML 앵커](yaml_optimization.md#anchors)를 사용하여 배열을 병합할 수 있습니다.

## `!reference` 태그 {#reference-tags}

`!reference` 사용자 정의 YAML 태그를 사용하여 다른 작업 섹션에서 키워드 구성을 선택하고 현재 섹션에서 재사용합니다. [YAML 앵커](#anchors)와 달리 `!reference` 태그를 사용하여 [포함된](_index.md#include) 구성 파일에서도 구성을 재사용할 수 있습니다.

`!reference` 태그를 사용하여 포함된 파일의 구성을 재정의하는 경우 대신 [CI/CD 입력](../inputs/_index.md)을 사용하는 것을 고려하세요. CI/CD 입력을 `!reference` 태그에서 사용할 수 없습니다. `!reference` 태그는 입력 보간 전에 평가되기 때문입니다.

다음 예제에서 두 개의 다른 위치에서 `script`과 `after_script`을 `test` 작업에서 재사용합니다:

- `configs.yml`:

  ```yaml
  .setup:
    script:
      - echo creating environment
  ```

- `.gitlab-ci.yml`:

  ```yaml
  include:
    - local: configs.yml

  .teardown:
    after_script:
      - echo deleting environment

  test:
    script:
      - !reference [.setup, script]
      - echo running my own command
    after_script:
      - !reference [.teardown, after_script]
  ```

다음 예제에서 `test-vars-1`은 `.vars`의 모든 변수를 재사용하고, `test-vars-2`은 특정 변수를 선택하고 새 `MY_VAR` 변수로 재사용합니다.

```yaml
.vars:
  variables:
    URL: "http://my-url.internal"
    IMPORTANT_VAR: "the details"

test-vars-1:
  variables: !reference [.vars, variables]
  script:
    - printenv

test-vars-2:
  variables:
    MY_VAR: !reference [.vars, variables, IMPORTANT_VAR]
  script:
    - printenv
```

여러 `!reference` 태그를 사용하여 `rules`, `script`, 또는 스테이지가 있는 배열을 빌드할 수 있습니다. 예를 들어:

```yaml
.rules_prod:
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  - if: $CI_PIPELINE_SOURCE == "schedule"

.rules_staging:
  - if: $CI_COMMIT_BRANCH =~ /^wip-.*/
  - if: $CI_PIPELINE_SOURCE == "push"

deploy_job:
  script: echo test
  rules:
    - !reference [.rules_prod]
    - !reference [.rules_staging]
```

다른 모든 키워드의 경우 [`config should be an array of` 유효성 검사 오류](../debugging.md#config-should-be-an-array-of-hashes-error-message)가 발생합니다.

### `!reference` 태그를 `script`, `before_script`, `after_script`에 중첩 {#nest-reference-tags-in-script-before_script-and-after_script}

`!reference` 태그를 `script`, `before_script`, `after_script` 섹션에서 최대 10개 레벨까지 중첩할 수 있습니다. 더 복잡한 스크립트를 빌드할 때 재사용 가능한 섹션을 정의하려면 중첩된 태그를 사용합니다. 예를 들어:

```yaml
.snippets:
  one:
    - echo "ONE!"
  two:
    - !reference [.snippets, one]
    - echo "TWO!"
  three:
    - !reference [.snippets, two]
    - echo "THREE!"

nested-references:
  script:
    - !reference [.snippets, three]
```

이 예제에서 `nested-references` 작업은 3개의 `echo` 명령을 모두 실행합니다.

### `!reference` 태그를 지원하도록 IDE 구성 {#configure-your-ide-to-support-reference-tags}

[파이프라인 편집기](../pipeline_editor/_index.md)는 `!reference` 태그를 지원합니다. 그러나 `!reference` 같은 사용자 정의 YAML 태그의 스키마 규칙은 기본적으로 편집기에서 유효하지 않은 것으로 처리될 수 있습니다. 일부 편집기를 구성하여 `!reference` 태그를 허용할 수 있습니다. 예를 들어:

- VS Code에서 `vscode-yaml`을 설정하여 `settings.json` 파일에서 `customTags`을 구문 분석할 수 있습니다:

  ```json
  "yaml.customTags": [
     "!reference sequence"
  ]
  ```

- Sublime Text에서 `LSP-yaml` 패키지를 사용하는 경우 `LSP-yaml` 사용자 설정에서 `customTags`을 설정할 수 있습니다:

  ```json
  {
    "settings": {
      "yaml.customTags": ["!reference sequence"]
    }
  }
  ```
