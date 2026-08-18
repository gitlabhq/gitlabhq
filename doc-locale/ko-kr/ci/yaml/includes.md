---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 다른 파일에서 CI/CD 구성 사용
description: 키워드를 사용하여 다른 YAML 파일의 콘텐츠로 CI/CD 구성을 확장합니다.
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[`include`](_index.md#include)를 사용하여 외부 YAML 파일을 CI/CD 작업에 포함할 수 있습니다.

## 단일 구성 파일 포함 {#include-a-single-configuration-file}

단일 구성 파일을 포함하려면 `include`를 단일 파일과 함께 사용하고 다음 구문 옵션 중 하나를 선택합니다:

- 같은 줄에:

  ```yaml
  include: 'my-config.yml'
  ```

- 배열의 단일 항목으로:

  ```yaml
  include:
    - 'my-config.yml'
  ```

파일이 로컬 파일이면 [`include:local`](_index.md#includelocal)와 동일한 동작입니다. 파일이 원격 파일이면 [`include:remote`](_index.md#includeremote)와 동일합니다.

## 구성 파일 배열 포함 {#include-an-array-of-configuration-files}

구성 파일 배열을 포함할 수 있습니다:

- `include` 타입을 지정하지 않으면 각 배열 항목은 필요에 따라 [`include:local`](_index.md#includelocal) 또는 [`include:remote`](_index.md#includeremote)로 기본 설정됩니다:

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - 'templates/.after-script-template.yml'
  ```

- 단일 항목 배열을 정의할 수 있습니다:

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
  ```

- 배열을 정의하고 여러 `include` 타입을 명시적으로 지정할 수 있습니다:

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - local: 'templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
  ```

- 기본 및 특정 `include` 타입을 모두 결합하는 배열을 정의할 수 있습니다:

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - 'templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
    - project: 'my-group/my-project'
      ref: main
      file: 'templates/.gitlab-ci-template.yml'
  ```

## 포함된 구성 파일에서 `default` 구성 사용 {#use-default-configuration-from-an-included-configuration-file}

구성 파일에서 [`default`](_index.md#default) 섹션을 정의할 수 있습니다. `default` 섹션을 `include` 키워드와 함께 사용하면 기본값이 파이프라인의 모든 작업에 적용됩니다.

예를 들어 `default` 섹션을 [`before_script`](_index.md#before_script)와 함께 사용할 수 있습니다.

`/templates/.before-script-template.yml`로 명명된 사용자 지정 구성 파일의 콘텐츠:

```yaml
default:
  before_script:
    - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
    - gem install bundler --no-document
    - bundle install --jobs $(nproc)  "${FLAGS[@]}"
```

`.gitlab-ci.yml`의 내용:

```yaml
include: 'templates/.before-script-template.yml'

rspec1:
  script:
    - bundle exec rspec

rspec2:
  script:
    - bundle exec rspec
```

기본 `before_script` 명령은 `script` 명령 전에 두 `rspec` 작업에서 실행됩니다.

## 포함된 구성 값 재정의 {#override-included-configuration-values}

`include` 키워드를 사용하면 포함된 구성 값을 재정의하여 파이프라인 요구사항에 맞게 조정할 수 있습니다.

다음 예제에서는 `.gitlab-ci.yml` 파일에서 사용자 지정된 `include` 파일을 보여줍니다. `production` 작업의 특정 YAML 정의 변수 및 세부 정보를 재정의합니다.

`autodevops-template.yml`로 명명된 사용자 지정 구성 파일의 콘텐츠:

```yaml
variables:
  POSTGRES_USER: user
  POSTGRES_PASSWORD: testing_password
  POSTGRES_DB: $CI_ENVIRONMENT_SLUG

production:
  stage: production
  script:
    - install_dependencies
    - deploy
  environment:
    name: production
    url: https://$CI_PROJECT_PATH_SLUG.$KUBE_INGRESS_BASE_DOMAIN
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

`.gitlab-ci.yml`의 내용:

```yaml
include: 'https://company.com/autodevops-template.yml'

default:
  image: alpine:latest

variables:
  POSTGRES_USER: root
  POSTGRES_PASSWORD: secure_password

stages:
  - build
  - test
  - production

production:
  environment:
    url: https://domain.com
```

`.gitlab-ci.yml` 파일에 정의된 `production` 작업의 `POSTGRES_USER` 및 `POSTGRES_PASSWORD` 변수 및 `environment:url`은 `autodevops-template.yml` 파일에 정의된 값을 재정의합니다. 다른 키워드는 변경되지 않습니다. 이 방법을 _병합_이라고 합니다.

### `include`에 대한 병합 방법 {#merge-method-for-include}

`include` 구성은 다음 프로세스로 주 구성 파일과 병합됩니다:

- 포함된 파일은 구성 파일에 정의된 순서대로 읽혀지고 포함된 구성이 같은 순서로 함께 병합됩니다.
- 포함된 파일도 `include`를 사용하면 중첩된 `include` 구성이 먼저 병합됩니다(재귀적).
- 매개변수가 겹치면 포함된 파일에서 구성을 병합할 때 마지막 포함된 파일이 우선합니다.
- `include`로 추가된 모든 구성이 함께 병합된 후 주 구성이 포함된 구성과 병합됩니다.

이 병합 방법은 _깊은 병합_이며, 구성의 모든 깊이에서 해시 맵이 병합됩니다. 해시 맵 "A"(지금까지 병합된 구성 포함) 및 "B"(다음 구성 조각)을 병합하기 위해 키와 값은 다음과 같이 처리됩니다:

- 키가 A에만 있으면 A의 키와 값을 사용합니다.
- 키가 A와 B 모두에 있고 해당 값이 모두 해시 맵이면 해시 맵을 병합합니다.
- 키가 A와 B 모두에 있고 값 중 하나가 해시 맵이 아니면 B의 값을 사용합니다.
- 그렇지 않으면 B의 키와 값을 사용합니다.

예를 들어 두 파일로 구성된 구성의 경우:

- `.gitlab-ci.yml` 파일:

  ```yaml
  include: 'common.yml'

  variables:
    POSTGRES_USER: username

  test:
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
        when: manual
    artifacts:
      reports:
        junit: rspec.xml
  ```

- `common.yml` 파일:

  ```yaml
  variables:
    POSTGRES_USER: common_username
    POSTGRES_PASSWORD: testing_password

  test:
    rules:
      - when: never
    script:
      - echo LOGIN=${POSTGRES_USER} > deploy.env
      - rake spec
    artifacts:
      reports:
        dotenv: deploy.env
  ```

병합 결과:

```yaml
variables:
  POSTGRES_USER: username
  POSTGRES_PASSWORD: testing_password

test:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
  script:
    - echo LOGIN=${POSTGRES_USER} > deploy.env
    - rake spec
  artifacts:
    reports:
      junit: rspec.xml
      dotenv: deploy.env
```

이 예에서:

- 변수는 모든 파일이 병합된 후에만 평가됩니다. 포함된 파일의 작업이 다른 파일에 정의된 변수 값을 사용할 수 있습니다.
- `rules`은 배열이므로 병합할 수 없습니다. 최상위 파일이 우선합니다.
- `artifacts`은 해시 맵이므로 깊은 병합이 가능합니다.

## 포함된 구성 배열 재정의 {#override-included-configuration-arrays}

병합을 사용하여 포함된 템플릿의 구성을 확장하고 재정의할 수 있지만 배열의 개별 항목을 추가하거나 수정할 수 없습니다. 예를 들어 추가 `notify_owner` 명령을 확장된 `production` 작업의 `script` 배열에 추가하려면:

`autodevops-template.yml`의 내용:

```yaml
production:
  stage: production
  script:
    - install_dependencies
    - deploy
```

`.gitlab-ci.yml`의 내용:

```yaml
include: 'autodevops-template.yml'

stages:
  - production

production:
  script:
    - install_dependencies
    - deploy
    - notify_owner
```

`install_dependencies` 및 `deploy`이 `.gitlab-ci.yml` 파일에서 반복되지 않으면 `production` 작업은 스크립트에 `notify_owner`만 포함합니다.

## 중첩된 포함 사용 {#use-nested-includes}

`include` 섹션을 구성 파일에 중첩한 후 다른 구성에 포함할 수 있습니다. 예를 들어 `include` 키워드를 3단계 깊이로 중첩하려면:

`.gitlab-ci.yml`의 내용:

```yaml
include:
  - local: /.gitlab-ci/another-config.yml
```

`/.gitlab-ci/another-config.yml`의 내용:

```yaml
include:
  - local: /.gitlab-ci/config-defaults.yml
```

`/.gitlab-ci/config-defaults.yml`의 내용:

```yaml
default:
  after_script:
    - echo "Job complete."
```

### 중복된 `include` 항목으로 중첩된 포함 사용 {#use-nested-includes-with-duplicate-include-entries}

주 구성 파일과 중첩된 포함에서 같은 구성 파일을 여러 번 포함할 수 있습니다.

파일이 [재정의](#override-included-configuration-values)를 사용하여 포함된 구성을 변경하면 `include` 항목의 순서가 최종 구성에 영향을 미칠 수 있습니다. 마지막으로 구성이 포함되면 파일이 포함된 이전 모든 시간을 재정의합니다. 예를 들어:

- `defaults.gitlab-ci.yml` 파일의 콘텐츠:

  ```yaml
  default:
    before_script: echo "Default before script"
  ```

- `unit-tests.gitlab-ci.yml` 파일의 콘텐츠:

  ```yaml
  include:
    - template: defaults.gitlab-ci.yml

  default:  # Override the included default
    before_script: echo "Unit test default override"

  unit-test-job:
    script: unit-test.sh
  ```

- `smoke-tests.gitlab-ci.yml` 파일의 콘텐츠:

  ```yaml
  include:
    - template: defaults.gitlab-ci.yml

  default:  # Override the included default
    before_script: echo "Smoke test default override"

  smoke-test-job:
    script: smoke-test.sh
  ```

이 세 파일의 포함 순서는 최종 구성을 변경합니다. 다음:

- `unit-tests`을 먼저 포함하면 `.gitlab-ci.yml` 파일의 콘텐츠는:

  ```yaml
  include:
    - local: unit-tests.gitlab-ci.yml
    - local: smoke-tests.gitlab-ci.yml
  ```

  최종 구성은:

  ```yaml
  unit-test-job:
   before_script: echo "Smoke test default override"
   script: unit-test.sh

  smoke-test-job:
   before_script: echo "Smoke test default override"
   script: smoke-test.sh
  ```

- `unit-tests`을 마지막에 포함하면 `.gitlab-ci.yml` 파일의 콘텐츠는:

  ```yaml
  include:
    - local: smoke-tests.gitlab-ci.yml
    - local: unit-tests.gitlab-ci.yml
  ```

- 최종 구성은:

  ```yaml
  unit-test-job:
   before_script: echo "Unit test default override"
   script: unit-test.sh

  smoke-test-job:
   before_script: echo "Unit test default override"
   script: smoke-test.sh
  ```

파일이 포함된 구성을 재정의하지 않으면 `include` 항목의 순서는 최종 구성에 영향을 주지 않습니다

## `include`과 함께 변수 사용 {#use-variables-with-include}

`.gitlab-ci.yml` 파일의 `include` 섹션에서 다음을 사용할 수 있습니다:

- [프로젝트 변수](../variables/_index.md#for-a-project).
- [그룹 변수](../variables/_index.md#for-a-group).
- [인스턴스 변수](../variables/_index.md#for-an-instance).
- 프로젝트 [사전 정의 변수](../variables/predefined_variables.md)(`CI_PROJECT_*`).
- [트리거 변수](../triggers/_index.md#pass-cicd-variables-in-the-api-call).
- [예약된 파이프라인 변수](../pipelines/schedules.md#create-a-pipeline-schedule).
- [수동 파이프라인 실행 변수](../pipelines/_index.md#run-a-pipeline-manually).
- `CI_PIPELINE_SOURCE` 및 `CI_PIPELINE_TRIGGERED` [사전 정의 변수](../variables/predefined_variables.md).
- `$CI_COMMIT_REF_NAME` [사전 정의 변수](../variables/predefined_variables.md).

예를 들어:

```yaml
include:
  project: '$CI_PROJECT_PATH'
  file: '.compliance-gitlab-ci.yml'
```

작업에 정의된 변수 또는 모든 작업의 기본 변수를 정의하는 전역 [`variables`](_index.md#variables) 섹션에서 변수를 사용할 수 없습니다. 포함이 작업보다 먼저 평가되므로 이 변수들은 `include`과 함께 사용할 수 없습니다.

사전 정의 변수를 포함하는 방법과 변수가 CI/CD 작업에 미치는 영향에 대한 예제는 이 [CI/CD 변수 데모](https://youtu.be/4XR8gw3Pkos)를 참조하세요.

동적 하위 파이프라인의 구성에서 `include` 섹션의 CI/CD 변수를 사용할 수 없습니다. [이슈 378717](https://gitlab.com/gitlab-org/gitlab/-/issues/378717)은 이 이슈를 해결할 것을 제안합니다.

## `rules`을(를) `include`와(과) 함께 사용 {#use-rules-with-include}

[`rules`](_index.md#rules)를 `include`과 함께 사용하여 조건부로 다른 구성 파일을 포함할 수 있습니다.

`rules`을 [특정 변수](#use-variables-with-include)와 함께 사용할 수 있으며 다음 키워드가 있습니다:

- [`rules:if`](_index.md#rulesif).
- [`rules:exists`](_index.md#rulesexists).
- [`rules:changes`](_index.md#ruleschanges).

### `include`을 `rules:if`과 함께 사용 {#include-with-rulesif}

[`rules:if`](_index.md#rulesif)를 사용하여 CI/CD 변수 상태를 기반으로 다른 구성 파일을 조건부로 포함합니다. 예를 들어:

```yaml
include:
  - local: builds.yml
    rules:
      - if: $DONT_INCLUDE_BUILDS == "true"
        when: never
  - local: builds.yml
    rules:
      - if: $ALWAYS_INCLUDE_BUILDS == "true"
        when: always
  - local: builds.yml
    rules:
      - if: $INCLUDE_BUILDS == "true"
  - local: deploys.yml
    rules:
      - if: $CI_COMMIT_BRANCH == "main"

test:
  stage: test
  script: exit 0
```

### `include`을 `rules:exists`과 함께 사용 {#include-with-rulesexists}

[`rules:exists`](_index.md#rulesexists)를 사용하여 파일의 존재를 기반으로 다른 구성 파일을 조건부로 포함합니다. 예를 들어:

```yaml
include:
  - local: builds.yml
    rules:
      - exists:
          - exception-file.md
        when: never
  - local: builds.yml
    rules:
      - exists:
          - important-file.md
        when: always
  - local: builds.yml
    rules:
      - exists:
          - file.md

test:
  stage: test
  script: exit 0
```

이 예제에서 GitLab은 현재 파이프라인에서 `file.md`의 존재를 확인합니다.

다른 파이프라인의 포함 파일에서 `include`을 `rules:exists`과 함께 사용하는 경우 구성을 주의 깊게 검토하세요. GitLab은 다른 파이프라인의 파일 존재를 확인합니다. 예를 들어:

```yaml
# Pipeline configuration in my-group/my-project
include:
  - project: my-group/other-project
    ref: other_branch
    file: other-file.yml

test:
  script: exit 0

# other-file.yml in my-group/other-project on ref other_branch
include:
  - project: my-group/my-project
    ref: main
    file: my-file.yml
    rules:
      - exists:
          - file.md
```

이 예제에서 GitLab은 파이프라인이 실행되는 파이프라인/ref가 아닌 `other_branch` 커밋 ref의 `my-group/other-project`에서 `file.md`의 존재를 검색합니다.

검색 컨텍스트를 변경하려면 [`rules:exists:paths`](_index.md#rulesexistspaths)를 [`rules:exists:project`](_index.md#rulesexistsproject)과 함께 사용할 수 있습니다. 예를 들어:

```yaml
include:
  - project: my-group/my-project
    ref: main
    file: my-file.yml
    rules:
      - exists:
          paths:
            - file.md
          project: my-group/my-project
          ref: main
```

### `include`을 `rules:changes`과 함께 사용 {#include-with-ruleschanges}

[`rules:changes`](_index.md#ruleschanges)를 사용하여 변경된 파일을 기반으로 다른 구성 파일을 조건부로 포함합니다. 예를 들어:

```yaml
include:
  - local: builds1.yml
    rules:
      - changes:
        - Dockerfile
  - local: builds2.yml
    rules:
      - changes:
          paths:
            - Dockerfile
          compare_to: 'refs/heads/branch1'
        when: always
  - local: builds3.yml
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
        changes:
          paths:
            - Dockerfile

test:
  stage: test
  script: exit 0
```

이 예에서:

- `builds1.yml`은 `Dockerfile`이 변경되었을 때 포함됩니다.
- `builds2.yml`은 `Dockerfile`이 `refs/heads/branch1`에 상대적으로 변경되었을 때 포함됩니다.
- `builds3.yml`은 `Dockerfile`이 변경되고 파이프라인 소스가 머지 리퀘스트 이벤트일 때 포함됩니다. `builds3.yml`의 작업은 [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md#configure-merge-request-pipelines)에 대해 실행되도록 구성되어야 합니다.

## 와일드카드 파일 경로로 `include:local` 사용 {#use-includelocal-with-wildcard-file-paths}

와일드카드 경로(`*` 및 `**`)를 `include:local`과 함께 사용할 수 있습니다.

예:

```yaml
include: 'configs/*.yml'
```

파이프라인이 실행되면 GitLab은:

- `configs` 디렉토리의 모든 `.yml` 파일을 파이프라인 구성에 추가합니다.
- `configs` 디렉토리의 하위 폴더에 있는 `.yml` 파일을 추가하지 않습니다. 이를 허용하려면 다음 구성을 추가합니다:

  ```yaml
  # This matches all `.yml` files in `configs` and any subfolder in it.
  include: 'configs/**.yml'

  # This matches all `.yml` files only in subfolders of `configs`.
  include: 'configs/**/*.yml'
  ```

## 문제 해결 {#troubleshooting}

### `Maximum of 150 nested includes are allowed!` 오류 {#maximum-of-150-nested-includes-are-allowed-error}

파이프라인에 대한 [중첩된 포함 파일](#use-nested-includes)의 최대 개수는 150입니다. `Maximum 150 includes are allowed` 오류 메시지가 파이프라인에 표시되면 다음 중 하나일 가능성이 있습니다:

- 중첩된 구성의 일부는 추가 중첩된 `include` 구성을 과도하게 많이 포함합니다.
- 중첩된 포함에 실수로 루프가 있습니다. 예를 들어 `include1.yml`이 `include1.yml`을 포함한 `include2.yml`를 포함하고 재귀 루프를 생성합니다.

이 문제가 발생할 위험을 줄이려면 [파이프라인 편집기](../pipeline_editor/_index.md)로 파이프라인 구성 파일을 편집합니다. 이 편집기는 제한에 도달했는지 확인합니다. 루프의 원인이거나 포함된 파일이 과도한 구성 파일을 찾으려면 한 번에 하나씩 포함된 파일을 제거할 수 있습니다.

GitLab Self-Managed의 사용자는 [최대 포함](../../administration/cicd/limits.md#maximum-number-of-includes) 값을 변경할 수 있습니다.

### 오류: `Local file <file> does not exist!`을 `include:local`과 함께 사용 {#error-local-file-file-does-not-exist-with-includelocal}

[`include:local`](_index.md#includelocal)을 사용할 때 `Local file <file> does not exist!` 오류가 발생할 수 있습니다. 파일이 리포지토리에 있어도 말입니다.

이 오류는 CI/CD 구성 이슈가 아닌 알려진 시스템 수준 이슈입니다. 분산된 Gitaly 또는 Praefect 설정에서 간헐적으로 관찰되었습니다. 이 오류가 발생하면 파이프라인을 다시 시도하세요.

자세한 내용은 [이슈 336789](https://gitlab.com/gitlab-org/gitlab/-/issues/336789)를 참조하세요.

### `SSL_connect SYSCALL returned=5 errno=0 state=SSLv3/TLS write client hello` 및 기타 네트워크 오류 {#ssl_connect-syscall-returned5-errno0-statesslv3tls-write-client-hello-and-other-network-failures}

[`include:remote`](_index.md#includeremote)를 사용할 때 GitLab은 HTTP(S)를 통해 원격 파일을 가져오려고 합니다. 이 프로세스는 다양한 연결 이슈로 인해 실패할 수 있습니다.

`SSL_connect SYSCALL returned=5 errno=0 state=SSLv3/TLS write client hello` 오류는 GitLab이 원격 호스트에 대한 HTTPS 연결을 설정할 수 없을 때 발생합니다. 이 이슈는 원격 호스트가 서버를 요청으로 과부하하는 것을 방지하기 위해 속도 제한을 가지고 있을 경우 발생할 수 있습니다.

예를 들어 GitLab.com의 [GitLab Pages](../../user/project/pages/_index.md) 서버는 속도 제한됩니다. GitLab Pages에서 호스팅되는 CI/CD 구성 파일을 반복적으로 가져오려고 시도하면 속도 제한에 도달하고 오류가 발생할 수 있습니다. GitLab Pages 사이트에서 CI/CD 구성 파일을 호스팅하지 않아야 합니다.

가능한 경우 [`include:project`](_index.md#includeproject)를 사용하여 외부 HTTP(S) 요청을 하지 않고 GitLab 인스턴스 내의 다른 프로젝트에서 구성 파일을 가져옵니다.
