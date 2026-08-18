---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CircleCI에서 마이그레이션
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

현재 CircleCI를 사용하고 있다면 [GitLab CI/CD](../_index.md)로 CI/CD 파이프라인을 마이그레이션할 수 있으며 모든 강력한 기능을 활용할 수 있습니다.

마이그레이션을 시작하기 전에 유용할 수 있는 여러 리소스를 수집했습니다.

[빠른 시작 가이드](../quick_start/_index.md)는 GitLab CI/CD의 작동 방식에 대한 좋은 개요입니다. [Auto DevOps](../../topics/autodevops/_index.md)에도 관심이 있을 수 있으며, 이를 사용하여 거의 또는 전혀 구성 없이 애플리케이션을 빌드, 테스트 및 배포할 수 있습니다.

고급 CI/CD 팀의 경우 [사용자 지정 프로젝트 템플릿](../../administration/custom_project_templates.md)을(를) 사용하여 파이프라인 구성을 재사용할 수 있습니다.

여기서 답변하지 않은 질문이 있으면 [GitLab 커뮤니티 포럼](https://forum.gitlab.com/)이 좋은 리소스가 될 수 있습니다.

## `config.yml` 대 `.gitlab-ci.yml` {#configyml-vs-gitlab-ciyml}

CircleCI의 `config.yml` 구성 파일은 스크립트, 작업, 및 워크플로(GitLab에서는 "스테이지"라고 알려짐)를 정의합니다. GitLab에서는 리포지토리의 루트 디렉터리에 `.gitlab-ci.yml` 파일을 사용하는 유사한 방식을 사용합니다.

### 작업 {#jobs}

CircleCI에서 작업은 특정 작업을 수행하기 위한 단계 모음입니다. GitLab에서는 [작업](../jobs/_index.md)도 구성 파일의 기본 요소입니다. `checkout` 키워드는 리포지토리가 자동으로 가져와지기 때문에 GitLab CI/CD에서 필요하지 않습니다.

CircleCI 작업 정의 예:

```yaml
jobs:
  job1:
    steps:
      - checkout
      - run: "execute-script-for-job1"
```

GitLab CI/CD에서 동일한 작업 정의의 예:

```yaml
job1:
  script: "execute-script-for-job1"
```

### Docker 이미지 정의 {#docker-image-definition}

CircleCI는 작업 수준에서 이미지를 정의하며, 이는 GitLab CI/CD에서도 지원됩니다. 또한 GitLab CI/CD는 `image`이 정의되지 않은 모든 작업에서 사용할 수 있도록 전역적으로 이를 설정할 수 있습니다.

CircleCI 이미지 정의 예:

```yaml
jobs:
  job1:
    docker:
      - image: ruby:2.6
```

GitLab CI/CD에서 동일한 이미지 정의의 예:

```yaml
job1:
  image: ruby:2.6
```

### 워크플로 {#workflows}

CircleCI는 `workflows`을(를) 사용하여 작업의 실행 순서를 결정합니다. 이를 사용하여 동시, 순차, 예약 또는 수동 실행을 결정합니다. GitLab CI/CD의 동등한 기능을 [스테이지](../yaml/_index.md#stages)라고 합니다. 동일한 스테이지의 작업은 병렬로 실행되며 이전 스테이지가 완료된 후에만 실행됩니다. 작업이 실패하면 기본적으로 다음 스테이지의 실행이 건너뛰어지지만, [실패한 작업 후에도](../yaml/_index.md#allow_failure) 계속할 수 있습니다.

사용할 수 있는 다양한 유형의 파이프라인에 대한 지침은 [파이프라인 아키텍처 개요](../pipelines/pipeline_architectures.md)를 참조하세요. 파이프라인은 대규모 복잡한 프로젝트나 독립적으로 정의된 구성 요소가 있는 모노레포와 같이 사용자의 필요에 맞게 조정할 수 있습니다.

#### 병렬 및 순차 작업 실행 {#parallel-and-sequential-job-execution}

다음 예제는 작업을 병렬로 또는 순차적으로 실행하는 방법을 보여줍니다:

1. `job1` 및 `job2`는 병렬로 실행됩니다(GitLab CI/CD의 `build` 스테이지에서).
1. `job3`는 `job1` 및 `job2`가 성공적으로 완료된 후에만 실행됩니다(`test` 스테이지에서).
1. `job4`는 `job3`가 성공적으로 완료된 후에만 실행됩니다(`deploy` 스테이지에서).

`workflows`을(를) 사용한 CircleCI 예:

```yaml
version: 2
jobs:
  job1:
    steps:
      - checkout
      - run: make build dependencies
  job2:
    steps:
      - run: make build artifacts
  job3:
    steps:
      - run: make test
  job4:
    steps:
      - run: make deploy

workflows:
  version: 2
  jobs:
    - job1
    - job2
    - job3:
        requires:
          - job1
          - job2
    - job4:
        requires:
          - job3
```

GitLab CI/CD에서 `stages`로 동일한 워크플로의 예:

```yaml
stages:
  - build
  - test
  - deploy

job1:
  stage: build
  script: make build dependencies

job2:
  stage: build
  script: make build artifacts

job3:
  stage: test
  script: make test

job4:
  stage: deploy
  script: make deploy
  environment: production
```

#### 예약된 실행 {#scheduled-run}

GitLab CI/CD는 [파이프라인 예약](../pipelines/schedules.md)을 위한 사용하기 쉬운 UI를 제공합니다. 또한 [규칙](../yaml/_index.md#rules)을(를) 사용하여 예약된 파이프라인에 작업을 포함할지 제외할지 결정할 수 있습니다.

예약된 워크플로의 CircleCI 예:

```yaml
commit-workflow:
  jobs:
    - build
scheduled-workflow:
  triggers:
    - schedule:
        cron: "0 1 * * *"
        filters:
          branches:
            only: try-schedule-workflow
  jobs:
    - build
```

GitLab CI/CD에서 [`rules`](../yaml/_index.md#rules)을(를) 사용한 동일한 예약된 파이프라인의 예:

```yaml
job1:
  script:
    - make build
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $CI_COMMIT_REF_NAME == "try-schedule-workflow"
```

파이프라인 구성이 저장된 후 [GitLab UI](../pipelines/schedules.md#create-a-pipeline-schedule)에서 cron 일정을 구성하고 UI에서 일정을 활성화 또는 비활성화할 수 있습니다.

#### 수동 실행 {#manual-run}

수동 워크플로의 CircleCI 예:

```yaml
release-branch-workflow:
  jobs:
    - build
    - testing:
        requires:
          - build
    - deploy:
        type: approval
        requires:
          - testing
```

GitLab CI/CD에서 [`when: manual`](../jobs/job_control.md#create-a-job-that-must-be-run-manually)을(를) 사용한 동일한 워크플로의 예:

```yaml
deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  when: manual
  environment: production
```

### 브랜치별 작업 필터링 {#filter-job-by-branch}

[규칙](../yaml/_index.md#rules)은 작업이 특정 브랜치에 대해 실행되는지 결정하는 메커니즘입니다.

브랜치별로 필터링된 작업의 CircleCI 예:

```yaml
jobs:
  deploy:
    branches:
      only:
        - main
        - /rc-.*/
```

GitLab CI/CD에서 `rules`을(를) 사용한 동일한 워크플로의 예:

```yaml
deploy:
  stage: deploy
  script:
    - echo "Deploy job"
  rules:
    - if: $CI_COMMIT_BRANCH == "main" || $CI_COMMIT_BRANCH =~ /^rc-/
  environment: production
```

### 캐싱 {#caching}

GitLab은 이전에 다운로드한 종속성을 재사용하여 작업의 빌드 시간을 단축하는 캐싱 메커니즘을 제공합니다. 이러한 기능을 최대한 활용하려면 [캐시와 아티팩트의 차이](../caching/_index.md#how-cache-is-different-from-artifacts)를 파악하는 것이 중요합니다.

캐시를 사용하는 작업의 CircleCI 예:

```yaml
jobs:
  job1:
    steps:
      - restore_cache:
          key: source-v1-< .Revision >
      - checkout
      - run: npm install
      - save_cache:
          key: source-v1-< .Revision >
          paths:
            - "node_modules"
```

GitLab CI/CD에서 `cache`을(를) 사용한 동일한 파이프라인의 예:

```yaml
test_async:
  image: node:latest
  cache:  # Cache modules in between jobs
    key: $CI_COMMIT_REF_SLUG
    paths:
      - .npm/
  before_script:
    - npm ci --cache .npm --prefer-offline
  script:
    - node ./specs/start.js ./specs/async.spec.js
```

## 컨텍스트 및 변수 {#contexts-and-variables}

CircleCI는 [컨텍스트](https://circleci.com/docs/contexts/)를 제공하여 프로젝트 파이프라인 간에 환경 변수를 안전하게 전달합니다. GitLab에서는 관련 프로젝트를 함께 모으기 위해 [그룹](../../user/group/_index.md)을 만들 수 있습니다. 그룹 수준에서 [CI/CD 변수](../variables/_index.md#for-a-group)를 개별 프로젝트 외부에 저장하고 여러 프로젝트의 파이프라인 전체에 안전하게 전달할 수 있습니다.

## Orb {#orbs}

CircleCI Orb 및 GitLab이 유사한 기능을 달성할 수 있는 방법을 다루고 있는 두 개의 GitLab 이슈가 열려 있습니다.

- [이슈 #1151](https://gitlab.com/gitlab-com/Product/-/issues/1151)
- [이슈 #195173](https://gitlab.com/gitlab-org/gitlab/-/issues/195173)

## 빌드 환경 {#build-environments}

CircleCI는 특정 작업을 실행하기 위한 기본 기술로 `executors`을(를) 제공합니다. GitLab에서는 [러너](https://docs.gitlab.com/runner/)를 사용하여 이를 수행합니다.

다음 환경이 지원됩니다:

자체 관리 러너:

- Linux
- Windows
- macOS

GitLab.com 인스턴스 러너:

- Linux
- [Windows](../runners/hosted_runners/windows.md) ([베타](../../policy/development_stages_support.md#beta)).
- [macOS](../runners/hosted_runners/macos.md) ([베타](../../policy/development_stages_support.md#beta)).

### 머신 및 특정 빌드 환경 {#machine-and-specific-build-environments}

[태그](../yaml/_index.md#tags)를 사용하여 GitLab에 어떤 러너가 작업을 실행해야 하는지 알려줌으로써 서로 다른 플랫폼에서 작업을 실행할 수 있습니다.

특정 환경에서 실행되는 작업의 CircleCI 예:

```yaml
jobs:
  ubuntuJob:
    machine:
      image: ubuntu-1604:201903-01
    steps:
      - checkout
      - run: echo "Hello, $USER!"
  osxJob:
    macos:
      xcode: 11.3.0
    steps:
      - checkout
      - run: echo "Hello, $USER!"
```

GitLab CI/CD에서 `tags`을(를) 사용한 동일한 작업의 예:

```yaml
windows job:
  stage: build
  tags:
    - windows
  script:
    - echo Hello, %USERNAME%!

osx job:
  stage: build
  tags:
    - osx
  script:
    - echo "Hello, $USER!"
```
