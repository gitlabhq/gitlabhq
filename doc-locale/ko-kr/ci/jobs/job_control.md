---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 작업 실행 방식 제어
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

새 파이프라인이 시작되기 전에 GitLab은 파이프라인 구성을 확인하여 해당 파이프라인에서 실행할 수 있는 작업을 결정합니다. 변수 값이나 파이프라인 유형과 같은 조건에 따라 작업을 실행하도록 구성할 수 있으며, [`rules`](job_rules.md)을(를) 사용합니다. 작업 규칙을 사용할 때는 [중복 파이프라인 방지](job_rules.md#avoid-duplicate-pipelines) 방법을 알아보세요. 파이프라인 생성을 제어하려면 [`workflow:rules`](../yaml/workflow.md)을(를) 사용합니다.

## 수동으로 실행해야 하는 작업 만들기 {#create-a-job-that-must-be-run-manually}

사용자가 시작하지 않으면 작업이 실행되지 않도록 요구할 수 있습니다. 이를 **manual job**이라고 합니다. 프로덕션에 배포하는 것과 같은 작업을 위해 수동 작업을 사용할 수 있습니다.

작업을 수동으로 지정하려면 [`when: manual`](../yaml/_index.md#when)을(를) `.gitlab-ci.yml` 파일의 작업에 추가합니다.

기본적으로 수동 작업은 파이프라인이 시작될 때 건너뜬 것으로 표시됩니다.

[보호된 브랜치](../../user/project/repository/branches/protected.md)를 사용하여 권한이 없는 사용자가 수동 배포를 실행하지 못하도록 [수동 작업 보호](#protect-manual-jobs)를 할 수 있습니다.

[보관된](../../administration/settings/continuous_integration.md#archive-pipelines) 수동 작업은 실행되지 않습니다.

### 수동 작업의 유형 {#types-of-manual-jobs}

수동 작업은 선택적이거나 차단일 수 있습니다.

선택적 수동 작업에서:

- [`allow_failure`](../yaml/_index.md#allow_failure)는 `true`이며, 이는 `rules` 외부에 정의된 `when: manual`가 있는 작업의 기본 설정입니다.
- 상태는 전체 파이프라인 상태에 기여하지 않습니다. 파이프라인은 모든 수동 작업이 실패해도 성공할 수 있습니다.

차단 수동 작업에서:

- `allow_failure`은(는) `false`이며, 이는 [`rules`](../yaml/_index.md#rules) 내에 정의된 `when: manual`가 있는 작업의 기본 설정입니다.
- 파이프라인은 스테이지에서 정의된 위치에서 중지됩니다. 파이프라인을 계속 실행하려면 [수동 작업 실행](#run-a-manual-job)을 수행합니다.
- [**파이프라인이 성공해야 함**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)이 활성화된 프로젝트의 머지 리퀘스트는 차단된 파이프라인과 병합할 수 없습니다.
- 파이프라인은 **blocked**의 상태를 표시합니다.

[`trigger:strategy`](../yaml/_index.md#triggerstrategy)을(를) 사용하여 다운스트림 파이프라인에서 수동 작업을 사용할 때, 수동 작업의 유형은 파이프라인 실행 중에 트리거 작업의 상태에 영향을 줄 수 있습니다.

### 수동 작업 실행 {#run-a-manual-job}

수동 작업을 실행하려면 할당된 브랜치에 병합할 수 있는 권한이 있어야 합니다:

1. 파이프라인, 작업, [환경](../environments/deployments.md#configure-manual-deployments) 또는 배포 보기로 이동합니다.
1. 수동 작업 옆에서 **실행**({{< icon name="play" >}})을 선택합니다.

### 수동 작업 실행 시 변수 지정 {#specify-variables-when-running-manual-jobs}

수동 작업을 실행할 때 작업 특정 CI/CD 변수를 추가로 제공할 수 있습니다. [CI/CD 변수](../variables/_index.md)를 사용하는 작업 실행을 변경하려는 경우 여기서 변수를 지정합니다.

수동 작업을 실행하고 재시도할 때 모두 재정의할 수 있는 입력된 유효성 검사된 매개 변수의 경우 [작업 입력](job_inputs.md)을 대신 사용합니다.

수동 작업을 실행하고 추가 변수를 지정하려면:

- 파이프라인 보기에서 수동 작업의 **이름**을 선택합니다. **실행**({{< icon name="play" >}})이 아닙니다.
- 양식에서 변수 키 및 값 쌍을 추가합니다.
- **작업 실행**을 선택합니다.

> [!warning]
> 수동 작업을 실행할 수 있는 권한이 있는 모든 프로젝트 멤버는 작업을 재시도하고 작업이 처음 실행될 때 제공된 변수를 볼 수 있습니다. 여기에는 다음이 포함됩니다:
>
> - 공개 프로젝트에서: 개발자, 유지 관리자 또는 소유자 역할을 가진 사용자입니다.
> - 비공개 또는 내부 프로젝트에서: 게스트, 플래너, 보고자, 개발자, 유지 관리자 또는 소유자 역할을 가진 사용자입니다.
>
> 수동 작업 변수로 민감한 정보를 입력할 때 이 표시를 고려합니다.

CI/CD 변수 설정이나 `.gitlab-ci.yml` 파일에 이미 정의된 변수를 추가하면 [변수가 새 값으로 재정의됩니다](../variables/_index.md#use-pipeline-variables). 이 프로세스를 사용하여 재정의된 모든 변수는 [확장](../variables/_index.md#allow-cicd-variable-expansion)되며 [마스킹되지](../variables/_index.md#mask-a-cicd-variable) 않습니다.

#### 업데이트된 변수로 수동 작업 재시도 {#retry-a-manual-job-with-updated-variables}

수동으로 지정된 변수로 이전에 실행된 수동 작업을 재시도할 때 변수를 업데이트하거나 동일한 변수를 사용할 수 있습니다.

입력된 유효성 검사된 매개 변수를 사용하여 수동 작업을 재시도하려면 [작업 입력](job_inputs.md)을 대신 사용합니다.

이전에 지정된 변수로 수동 작업을 재시도하려면:

- 동일한 변수 사용:
  - 작업 세부 정보 페이지에서 **재시도**({{< icon name="retry" >}})를 선택합니다.
- 업데이트된 변수 사용:
  - 작업 세부 정보 페이지에서 드롭다운에서 **수정된 값으로 작업 다시 시도**를 선택합니다.
  - 이전 실행에서 지정된 변수가 양식에 미리 채워집니다. 이 양식에서 CI/CD 변수를 추가, 수정 또는 삭제할 수 있습니다.
  - **작업 다시 실행**을 선택합니다.

### 수동 작업에 대한 확인 요구 {#require-confirmation-for-manual-jobs}

수동 작업에 대한 확인을 요구하려면 [`manual_confirmation`](../yaml/_index.md#manual_confirmation)을(를) `when: manual`과(와) 함께 사용합니다. 이는 프로덕션에 배포하는 것과 같은 민감한 작업에 대한 실수로 인한 배포 또는 삭제를 방지하는 데 도움이 됩니다.

작업을 실행할 때 실행하기 전에 작업을 확인해야 합니다.

### 수동 작업 보호 {#protect-manual-jobs}

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[보호 환경](../environments/protected_environments.md)을(를) 사용하여 수동 작업을 실행할 권한이 있는 사용자 목록을 정의합니다. 보호된 환경과 연결된 사용자만 수동 작업을 실행하도록 권한을 부여할 수 있으며, 이는 다음을 수행할 수 있습니다:

- 환경에 배포할 수 있는 사용자를 더욱 정확하게 제한합니다.
- 승인된 사용자가 "승인"할 때까지 파이프라인을 차단합니다.

수동 작업을 보호하려면:

1. `environment`을(를) 작업에 추가합니다. 예를 들어:

   ```yaml
   deploy_prod:
     stage: deploy
     script:
       - echo "Deploy to production server"
     environment:
       name: production
       url: https://example.com
     when: manual
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
   ```

1. [보호된 환경 설정](../environments/protected_environments.md#protecting-environments)에서 환경(`production`)을 선택하고 수동 작업을 실행할 권한이 있는 사용자, 역할 또는 그룹을 **Allowed to Deploy** 목록에 추가합니다. 이 목록의 사용자만 이 수동 작업을 실행할 수 있으며, GitLab 관리자는 항상 보호된 환경을 사용할 수 있습니다.

차단 수동 작업으로 보호된 환경을 사용하여 이후 파이프라인 단계를 승인할 수 있는 사용자 목록을 유지할 수 있습니다. 수동 작업이 권한이 있는 사용자에 의해 트리거된 후에만 `allow_failure: false`을(를) 보호된 수동 작업에 추가하고 파이프라인의 다음 단계가 실행됩니다.

## 지연 후 작업 실행 {#run-a-job-after-a-delay}

[`when: delayed`](../yaml/_index.md#when)을(를) 사용하여 대기 시간 후 스크립트를 실행하거나 작업이 즉시 `pending` 상태로 진입하는 것을 방지하려는 경우입니다.

`start_in` 키워드로 기간을 설정할 수 있습니다. `start_in`의 값은 단위가 제공되지 않는 한 초 단위의 경과 시간입니다. 최소값은 1초이고 최대값은 1주입니다. 유효한 값의 예는 다음과 같습니다:

- `'5'` (단위 없는 값은 단일 따옴표로 묶어야 함)
- `5 seconds`
- `30 minutes`
- `1 day`
- `1 week`

스테이지에 지연된 작업이 포함되면 지연된 작업이 완료될 때까지 파이프라인이 진행되지 않습니다. 이 키워드를 사용하여 다양한 스테이지 간에 지연을 삽입할 수 있습니다.

지연된 작업의 타이머는 이전 스테이지가 완료된 직후에 시작됩니다. 다른 유형의 작업과 유사하게, 지연된 작업의 타이머는 이전 스테이지가 통과하지 않으면 시작되지 않습니다.

다음 예는 이전 스테이지가 완료된 후 30분 후에 실행되는 `timed rollout 10%` 라는 이름의 작업을 만듭니다:

```yaml
timed rollout 10%:
  stage: deploy
  script: echo 'Rolling out 10% ...'
  when: delayed
  start_in: 30 minutes
  environment: production
```

지연된 작업의 활성 타이머를 중지하려면 **스케쥴 취소**({{< icon name="time-out" >}})를 선택합니다. 이 작업은 더 이상 자동으로 실행되도록 예약할 수 없습니다. 그러나 작업을 수동으로 실행할 수 있습니다.

지연된 작업을 수동으로 시작하려면 **스케쥴 취소**({{< icon name="time-out" >}})를 선택하여 지연 타이머를 중지한 다음 **실행**({{< icon name="play" >}})을 선택합니다. 곧 GitLab 러너가 작업을 시작합니다.

[보관된](../../administration/settings/continuous_integration.md#archive-pipelines) 지연된 작업은 실행되지 않습니다.

## 큰 작업을(를) 병렬화 {#parallelize-large-jobs}

큰 작업을 병렬로 실행되는 여러 개의 작은 작업으로 분할하려면 `.gitlab-ci.yml` 파일에서 [`parallel`](../yaml/_index.md#parallel) 키워드를 사용합니다.

다양한 언어와 테스트 스위트는 병렬화를 활성화하는 다양한 방법을 가지고 있습니다. 예를 들어 [Semaphore Test Boosters](https://github.com/renderedtext/test-boosters)와 RSpec을 사용하여 Ruby 테스트를 병렬로 실행합니다:

```ruby
# Gemfile
source 'https://rubygems.org'

gem 'rspec'
gem 'semaphore_test_boosters'
```

```yaml
test:
  parallel: 3
  script:
    - bundle
    - bundle exec rspec_booster --job $CI_NODE_INDEX/$CI_NODE_TOTAL
```

그런 다음 새 파이프라인 빌드의 **작업** 탭으로 이동하여 RSpec 작업이 3개의 별도 작업으로 분할된 것을 확인할 수 있습니다.

> [!warning]
> Test Boosters는 저자에게 사용 통계를 보고합니다.

### 병렬 작업의 1차원 매트릭스 실행 {#run-a-one-dimensional-matrix-of-parallel-jobs}

단일 파이프라인에서 여러 번 병렬로 작업을 실행하되 각 작업 인스턴스의 값이 다르도록 하려면 [`parallel:matrix`](../yaml/_index.md#parallelmatrix) 키워드를 사용합니다:

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: [aws, ovh, gcp, vultr]
  environment: production/$PROVIDER
```

이 예에서는 4개의 `deploystacks` 작업이 생성되고 `PROVIDER`는 각각 다른 값을 가진 CI/CD 변수가 됩니다:

- `deploystacks: [aws]`
- `deploystacks: [ovh]`
- `deploystacks: [gcp]`
- `deploystacks: [vultr]`

### 병렬 트리거 작업의 매트릭스 실행 {#run-a-matrix-of-parallel-trigger-jobs}

단일 파이프라인에서 [트리거](../yaml/_index.md#trigger) 작업을 여러 번 병렬로 실행할 수 있지만 각 작업 인스턴스에서 사용 가능한 변수가 다릅니다.

예를 들어:

```yaml
deploystacks:
  stage: deploy
  trigger:
    include: path/to/child-pipeline.yml
  parallel:
    matrix:
      - PROVIDER: aws
        STACK: [monitoring, app1]
      - PROVIDER: ovh
        STACK: [monitoring, backup]
      - PROVIDER: [gcp, vultr]
        STACK: [data]
```

이 예는 각각 `PROVIDER`와 `STACK`에 대해 다른 값을 가진 6개의 병렬 `deploystacks` 트리거 작업을 생성하며, 이러한 변수를 사용하여 6개의 서로 다른 자식 파이프라인을 만듭니다.

```plaintext
deploystacks: [aws, monitoring]
deploystacks: [aws, app1]
deploystacks: [ovh, monitoring]
deploystacks: [ovh, backup]
deploystacks: [gcp, data]
deploystacks: [vultr, data]
```

### 각 병렬 매트릭스 작업에 대해 다른 러너 태그 선택 {#select-different-runner-tags-for-each-parallel-matrix-job}

`parallel: matrix`에 정의된 값을 동적 러너 선택을 위해 [`tags`](../yaml/_index.md#tags) 키워드와 함께 사용할 수 있습니다:

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: aws
        STACK: [monitoring, app1]
      - PROVIDER: gcp
        STACK: [data]
  tags:
    - ${PROVIDER}-${STACK}
  environment: $PROVIDER/$STACK
```

### 규칙에서 매트릭스 변수 사용 {#use-matrix-variables-in-rules}

GitLab은 각 개별 매트릭스 작업에 대해 규칙을 별도로 평가하며 해당 작업의 변수 값을 사용합니다.

#### `rules:if`에서 매트릭스 변수 사용 {#use-matrix-variables-in-rulesif}

[`rules:if`](../yaml/_index.md#rulesif) 식에서 매트릭스 변수를 사용하여 변수 값에 따라 개별 매트릭스 작업을 포함 또는 제외합니다.

예를 들어, 매트릭스 변수 `SKIP`이(가) `"true"`로 설정된 경우 작업을 건너뜁니다:

```yaml
test:
  script: echo "Building $ARCH"
  parallel:
    matrix:
      - ARCH: [amd64, arm64]
        SKIP: ["false", "true"]
  rules:
    - if: $SKIP == "true"
      when: never
    - when: on_success
```

`SKIP`이(가) `"false"`인 작업만 파이프라인에 포함됩니다.

> [!note]
> `rules:if`의 매트릭스 변수는 중첩된 확장을 지원하지 않습니다. 매트릭스 변수 값이 다른 CI/CD 변수를 참조하는 경우 (예를 들어, `FILE: $GLOBAL_FILE`), 참조가 해석되지 않습니다. 식은 리터럴 문자열 값을 사용하므로 `$FILE`은(는) `"$GLOBAL_FILE"`로 평가되며 `GLOBAL_FILE`의 값이 아닙니다.

#### `rules:changes`에서 매트릭스 변수 사용 {#use-matrix-variables-in-ruleschanges}

[`rules:changes`](../yaml/_index.md#ruleschanges) 경로에서 매트릭스 변수를 사용하여 해당 작업과 관련된 파일이 변경된 경우에만 매트릭스 작업을 포함합니다. 이 패턴은 각 매트릭스 값이 자신의 디렉토리가 있는 구성 요소 또는 서비스에 해당하는 모노리포에서 유용합니다.

예를 들어, 파일이 변경된 구성 요소에 대해서만 테스트 작업을 실행합니다:

```yaml
test:
  script: echo "Testing $COMPONENT"
  parallel:
    matrix:
      - COMPONENT: [frontend, backend, database]
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
      changes:
        - components/$COMPONENT/**/*
```

이 예에서:

- 각 `COMPONENT` 값에 대해 3개의 `test` 작업이 평가됩니다.
- 각 작업은 경로에 대체된 자신의 `$COMPONENT` 값으로 `rules:changes`을(를) 확인합니다.
- 일치하는 파일이 변경된 작업만 파이프라인에 추가됩니다.

예를 들어, `components/frontend/npm.lock`만 변경된 경우 `frontend` 작업만 실행됩니다.

동일한 경로에서 여러 매트릭스 변수를 사용할 수 있습니다:

```yaml
test:
  script: echo "Testing $SERVICE in $ENV"
  parallel:
    matrix:
      - SERVICE: [api, web]
        ENV: [dev, prod]
  rules:
    - changes:
        - config/$SERVICE/$ENV/**/*
```

#### `rules:exists`에서 매트릭스 변수 사용 {#use-matrix-variables-in-rulesexists}

[`rules:exists`](../yaml/_index.md#rulesexists) 경로에서 매트릭스 변수를 사용하여 특정 파일이 존재할 때만 매트릭스 작업을 포함합니다.

예를 들어:

```yaml
test:
  script: echo "Testing $TYPE"
  parallel:
    matrix:
      - TYPE: [go, ruby, python]
  rules:
    - exists:
        - "**/*.$TYPE"
```

### `parallel:matrix` 작업에서 아티팩트 가져오기 {#fetch-artifacts-from-a-parallelmatrix-job}

[`parallel:matrix`](../yaml/_index.md#parallelmatrix)으(로) 만든 작업에서 아티팩트를 가져올 수 있으며 [`dependencies`](../yaml/_index.md#dependencies) 키워드를 사용합니다. `dependencies`의 값으로 작업 이름을 다음 형식의 문자열로 사용합니다:

```plaintext
<job_name> [<matrix argument 1>, <matrix argument 2>, ... <matrix argument N>]
```

예를 들어, `RUBY_VERSION`이(가) `2.7`이고 `PROVIDER`이(가) `aws`인 작업에서 아티팩트를 가져옵니다:

```yaml
ruby:
  image: ruby:${RUBY_VERSION}
  parallel:
    matrix:
      - RUBY_VERSION: ["2.5", "2.6", "2.7", "3.0", "3.1"]
        PROVIDER: [aws, gcp]
  script: bundle install

deploy:
  image: ruby:2.7
  stage: deploy
  dependencies:
    - "ruby: [2.7, aws]"
  script: echo hello
  environment: production
```

`dependencies` 항목 주변의 따옴표가 필요합니다.

### 여러 병렬화 작업을 사용하여 병렬화 작업 필요 지정 {#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs}

[`needs:parallel:matrix`](../yaml/_index.md#needsparallelmatrix)을(를) 사용하여 여러 병렬화 작업 간 [작업 종속성](../yaml/needs.md)을 만듭니다.

구성에는 두 가지 기술을 사용할 수 있습니다:

- [`matrix.` 식](../yaml/matrix_expressions.md)을(를) 사용하여 자동으로 수행합니다.
- 아래에서 보여주는 대로 수동으로 수행합니다.

예를 들어:

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2

mac:build:
  stage: build
  script: echo "Building mac..."
  parallel:
    matrix:
      - PROVIDER: [gcp, vultr]
        STACK: [data, processing]

linux:rspec:
  stage: test
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: aws
            STACK: app1
  script: echo "Running rspec on linux..."

mac:rspec:
  stage: test
  needs:
    - job: mac:build
      parallel:
        matrix:
          - PROVIDER: [gcp, vultr]
            STACK: [data]
  script: echo "Running rspec on mac..."

production:
  stage: deploy
  script: echo "Running production..."
  environment: production
```

이 예는 여러 작업을 생성합니다. 병렬 작업은 각각 `PROVIDER`과 `STACK`에 대해 다른 값을 가집니다.

- 3개의 병렬 `linux:build` 작업:
  - `linux:build: [aws, monitoring]`
  - `linux:build: [aws, app1]`
  - `linux:build: [aws, app2]`
- 4개의 병렬 `mac:build` 작업:
  - `mac:build: [gcp, data]`
  - `mac:build: [gcp, processing]`
  - `mac:build: [vultr, data]`
  - `mac:build: [vultr, processing]`
- `linux:rspec` 작업.
- `production` 작업.

작업에는 3가지 실행 경로가 있습니다:

- Linux 경로: `linux:rspec` 작업은 `linux:build: [aws, app1]` 작업이 완료되는 즉시 실행되며, `mac:build`이 완료될 때까지 기다리지 않습니다.
- macOS 경로: `mac:rspec` 작업은 `mac:build: [gcp, data]`과 `mac:build: [vultr, data]` 작업이 완료되는 즉시 실행되며, `linux:build`이 완료될 때까지 기다리지 않습니다.
- `production` 작업은 모든 이전 작업이 완료되는 즉시 실행됩니다.

#### 병렬화 작업 간 필요 지정 {#specify-needs-between-parallelized-jobs}

[`needs:parallel:matrix`](../yaml/_index.md#needsparallelmatrix)을(를) 사용하여 각 병렬 매트릭스 작업의 순서를 더 정의할 수 있습니다.

예를 들어:

```yaml
build_job:
  stage: build
  script:
    # ensure that other parallel job other than build_job [1, A] runs longer
    - '[[ "$VERSION" == "1" && "$MODE" == "A" ]] || sleep 30'
    - echo build $VERSION $MODE
  parallel:
    matrix:
      - VERSION: [1,2]
        MODE: [A, B]

deploy_job:
  stage: deploy
  script: echo deploy $VERSION $MODE
  parallel:
    matrix:
      - VERSION: [3,4]
        MODE: [C, D]

'deploy_job: [3, D]':
  stage: deploy
  script: echo something
  needs:
  - 'build_job: [1, A]'
```

이 예는 여러 작업을 생성합니다. 병렬 작업은 각각 `VERSION`과 `MODE`에 대해 다른 값을 가집니다.

- 4개의 병렬 `build_job` 작업:
  - `build_job: [1, A]`
  - `build_job: [1, B]`
  - `build_job: [2, A]`
  - `build_job: [2, B]`
- 4개의 병렬 `deploy_job` 작업:
  - `deploy_job: [3, C]`
  - `deploy_job: [3, D]`
  - `deploy_job: [4, C]`
  - `deploy_job: [4, D]`

`deploy_job: [3, D]` 작업은 `build_job: [1, A]` 작업이 완료되는 즉시 실행되며, 다른 `build_job` 작업이 완료될 때까지 기다리지 않습니다.

## 문제 해결 {#troubleshooting}

### 수동 작업 실행 시 불일치 사용자 할당 {#inconsistent-user-assignment-when-running-manual-jobs}

일부 경계 사례에서 수동 작업을 실행하는 사용자는 수동 작업에 종속된 이후 작업의 사용자로 할당되지 않습니다.

수동 작업에 종속된 작업의 사용자로 할당된 사람에 대해 엄격한 보안이 필요한 경우 [수동 작업 보호](#protect-manual-jobs)를 수행해야 합니다.
