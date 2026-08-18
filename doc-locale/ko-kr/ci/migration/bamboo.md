---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Bamboo에서 마이그레이션
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Atlassian Bamboo에서 GitLab CI/CD로 마이그레이션할 수 있습니다. Bamboo UI에서 내보낸 Bamboo Specs YAML 구성을 변환하거나 Spec 리포지토리에 저장된 구성을 사용합니다.

## 주요 마이그레이션 고려 사항 {#key-migration-considerations}

| 구성 측면  | Bamboo                             | GitLab CI/CD                         | 마이그레이션 작업 |
| --------------------- | ---------------------------------- | ------------------------------------ | --------------- |
| 구성 파일   | Bamboo Specs (Java 또는 YAML)        | `.gitlab-ci.yml` 파일                | Specs를 GitLab YAML 구문으로 변환 |
| 변수 구문       | `${bamboo.variableName}`           | `$VARIABLE_NAME`                     | 스크립트의 모든 변수 참조 업데이트 |
| 실행 환경 | 에이전트 (로컬 또는 원격)           | 실행기가 있는 러너               | 러너 설치 및 구성 |
| 아티팩트 공유      | 구독을 포함한 명명된 아티팩트 | 스테이지 간 자동 상속 | 아티팩트 구성 단순화 |
| 배포           | 별도의 배포 프로젝트       | 환경이 있는 배포 작업    | 단일 파이프라인에서 빌드 및 배포 결합 |

## 구성 예 {#configuration-examples}

### Bamboo Specs 내보내기 {#bamboo-specs-export}

다음 예에서는 UI의 Bamboo Specs YAML 내보내기와 해당하는 GitLab CI/CD를 보여줍니다.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo는 프로젝트에 여러 플랜이 포함되고, 플랜에서 스테이지 및 작업을 정의하며, 작업에서 개별 작업을 실행하는 중첩 계층 구조를 통해 빌드를 구성합니다. 프로젝트는 여러 플랜이 액세스할 수 있는 변수, 자격 증명, 리포지토리 연결과 같은 공유 리소스의 컨테이너 역할을 합니다.

UI의 Bamboo Specs 내보내기에는 권한, 알림 및 프로젝트 설정과 같은 관리 메타데이터뿐만 아니라 완전한 계층 구조가 포함됩니다.

내보내기를 검토할 때 다음 마이그레이션 중요 요소에 집중하세요:

- 작업 및 작업: 실제 빌드 명령 및 스크립트
- 스테이지 정의: 순차 실행 순서 및 종속성
- 변수 및 아티팩트: 작업 간 공유되는 데이터 및 파일
- 트리거 및 조건: 빌드 실행 시기를 결정하는 규칙

```yaml
version: 2
plan:
  project-key: AB
  key: TP
  name: test plan
stages:
  - Default Stage:
      manual: false
      final: false
      jobs:
        - Default Job
Default Job:
  key: JOB1
  tasks:
  - checkout:
      force-clean-build: false
      description: Checkout Default Repository
  - script:
      interpreter: SHELL
      scripts:
        - |-
          ruby -v  # Print out ruby version for debugging
          bundle config set --local deployment true  # Install dependencies into ./vendor/ruby
          bundle install -j $(nproc)
          rubocop
          rspec spec
      description: run bundler
  artifact-subscriptions: []
repositories:
  - Demo Project:
      scope: global
triggers:
  - polling:
      period: '180'
branches:
  create: manually
  delete: never
  link-to-jira: true
notifications: []
labels: []
dependencies:
  require-all-stages-passing: false
  enabled-for-branches: true
  block-strategy: none
  plans: []
other:
  concurrent-build-plugin: system-default

---

version: 2
plan:
  key: AB-TP
plan-permissions:
  - users:
    - root
    permissions:
    - view
    - edit
    - build
    - clone
    - admin
    - view-configuration
  - roles:
    - logged-in
    - anonymous
    permissions:
    - view
...
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CD는 중첩된 복잡성을 제거합니다. 대신 각 리포지토리에는 모든 스테이지 및 작업을 정의하는 단일 `.gitlab-ci.yml` 파일이 포함됩니다.

```yaml
default:
  image: ruby:latest

stages:
  - default-stage

job1:
  stage: default-stage
  script:
    - ruby -v  # Print out ruby version for debugging
    - bundle config set --local deployment true  # Install dependencies into ./vendor/ruby
    - bundle install -j $(nproc)
    - rubocop
    - rspec spec
```

{{< /tab >}}

{{< /tabs >}}

### 작업 및 작업 {#jobs-and-tasks}

GitLab과 Bamboo 모두에서 같은 스테이지의 작업은 작업을 실행하기 전에 충족해야 하는 종속성이 있는 경우를 제외하고 병렬로 실행됩니다.

Bamboo에서 실행할 수 있는 작업의 수는 Bamboo 에이전트의 가용성과 Bamboo 라이선스 크기에 따라 다릅니다.

GitLab CI/CD를 사용하면 병렬 작업의 수는 GitLab 인스턴스와 통합된 러너의 수와 러너에 설정된 동시성에 따라 다릅니다.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo에서 작업은 스크립트로 실행되는 명령 집합이거나 소스 코드 체크아웃, 아티팩트 다운로드 및 Atlassian 작업 마켓플레이스에서 사용 가능한 기타 작업과 같은 사전 정의된 작업인 작업으로 구성됩니다.

```yaml
version: 2
#...

Default Job:
  key: JOB1
  tasks:
  - checkout:
      force-clean-build: false
      description: Checkout Default Repository
  - script:
      interpreter: SHELL
      scripts:
        - |-
          ruby -v
          bundle config set --local deployment true
          bundle install -j $(nproc)
      description: run bundler
other:
  concurrent-build-plugin: system-default
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab의 작업 동등물은 `script`이며, 러너가 실행할 명령을 지정합니다. CI/CD 템플릿 및 CI/CD 구성 요소를 사용하여 모든 것을 직접 작성할 필요 없이 파이프라인을 작성할 수 있습니다.

```yaml
job1:
  script: "bundle exec rspec"

job2:
  script:
    - ruby -v
    - bundle config set --local deployment true
    - bundle install -j $(nproc)
```

{{< /tab >}}

{{< /tabs >}}

### 컨테이너 이미지 {#container-images}

다음 예에서는 Bamboo `docker` 키워드가 GitLab `image` 키워드로 변환되는 방식을 보여줍니다.

{{< tabs >}}

{{< tab title="Bamboo" >}}

빌드 및 배포는 기본적으로 Bamboo 에이전트의 기본 운영 체제에서 실행되지만, `docker` 키워드를 사용하여 컨테이너에서 실행되도록 구성할 수 있습니다.

```yaml
version: 2
plan:
  project-key: SAMPLE
  name: Build Ruby App
  key: BUILD-APP

docker: alpine:latest

stages:
  - Build App:
      jobs:
        - Build Application

Build Application:
  tasks:
    - script:
        - # Run builds
  docker:
    image: alpine:edge
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CD에서는 `image` 키워드만 필요합니다.

```yaml
default:
  image: alpine:latest

stages:
  - build

build-application:
  stage: build
  script:
    - # Run builds
  image:
    name: alpine:edge
```

{{< /tab >}}

{{< /tabs >}}

### 변수 {#variables}

다음 예에서는 변수 정의 및 액세스의 구문 차이를 보여줍니다.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo는 다양한 액세스 패턴을 가진 다양한 변수 유형을 가지고 있습니다. 시스템 변수는 `${system.variableName}`을 사용하고 기타 변수는 `${bamboo.variableName}`을 사용합니다.

스크립트 작업에서 점은 밑줄로 변환됩니다. 예를 들어, `${bamboo.variableName}`은 `$bamboo_variableName`이 됩니다.

```yaml
variables:
  username: admin
  releaseType: milestone

Default job:
  tasks:
    - script: echo '$bamboo_username is the DRI for $bamboo_releaseType'
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CD에서 변수는 `$VARIABLE_NAME`을 사용하는 일반 Shell 스크립트 변수처럼 액세스됩니다. Bamboo의 시스템 및 글로벌 변수와 마찬가지로 GitLab에는 모든 작업에서 사용할 수 있는 사전 정의된 CI/CD 변수가 있습니다.

```yaml
variables:
  DEFAULT_VAR: "A default variable"

job1:
  variables:
    JOB_VAR: "A job variable"
  script:
    - echo "Variables are '$DEFAULT_VAR' and '$JOB_VAR'"
```

{{< /tab >}}

{{< /tabs >}}

### 조건 및 트리거 {#conditions-and-triggers}

이 예에서는 Bamboo 조건 및 트리거가 GitLab 규칙으로 변환되는 방식을 보여줍니다.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo는 코드 변경, 일정, 다른 플랜의 결과 또는 요청 시 기반할 수 있는 빌드를 트리거하기 위한 다양한 옵션을 가지고 있습니다. 플랜을 구성하여 프로젝트를 주기적으로 폴링하여 새로운 변경 사항을 확인할 수 있습니다.

```yaml
tasks:
  - script:
      scripts:
        - echo "Hello"
      conditions:
        - variable:
            equals:
              planRepository.branch: development

triggers:
  - polling:
      period: '180'
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CD 파이프라인은 코드 변경, 일정 또는 API 호출을 기반으로 트리거됩니다. 파이프라인은 폴링을 사용하지 않습니다.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_COMMIT_REF_NAME == "development"

workflow:
  rules:
    - changes:
        - .gitlab/**/**.md
      when: never
```

{{< /tab >}}

{{< /tabs >}}

### 아티팩트 {#artifacts}

GitLab과 Bamboo에서 모두 `artifacts` 키워드를 사용하여 작업 아티팩트를 정의할 수 있습니다.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo에서 아티팩트는 이름, 위치 및 패턴으로 정의됩니다. 다른 작업 및 플랜과 아티팩트를 공유하거나 아티팩트를 구독하는 작업을 정의할 수 있습니다.

`artifact-subscriptions`은 같은 플랜의 다른 작업에서 아티팩트에 액세스하는 데 사용되고, `artifact-download`은 다른 플랜의 작업에서 아티팩트에 액세스하는 데 사용됩니다.

```yaml
version: 2
# ...
Build:
  # ...
  artifacts:
    - name: Test Reports
      location: target/reports
      pattern: '*.xml'
      required: false
      shared: false
    - name: Special Reports
      location: target/reports
      pattern: 'special/*.xml'
      shared: true

Test app:
  artifact-subscriptions:
    - artifact: Test Reports
      destination: deploy

# ...
Build:
  # ...
  tasks:
    - artifact-download:
        source-plan: PROJECTKEY-PLANKEY
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab에서는 기본적으로 이전 스테이지의 완료된 작업에서 모든 아티팩트가 다운로드됩니다.

```yaml
stages:
  - build

pdf:
  stage: build
  script: #generate XML reports
  artifacts:
    name: "test-report-files"
    untracked: true
    paths:
      - target/reports
```

이 예에서:

- 아티팩트의 이름은 명시적으로 지정되지만, CI/CD 변수를 사용하여 동적으로 만들 수 있습니다.
- `untracked` 키워드는 `paths`으로 명시적으로 지정된 파일과 함께 Git 추적되지 않은 파일도 포함하도록 아티팩트를 설정합니다.

{{< /tab >}}

{{< /tabs >}}

### 캐싱 {#caching}

Bamboo에서 Git 캐시를 사용하여 빌드 속도를 높일 수 있습니다. Git 캐시는 Bamboo 관리 설정에서 구성되고 Bamboo 서버 또는 원격 에이전트에 저장됩니다.

GitLab은 Git 캐시와 작업 캐시를 모두 지원합니다. 캐시는 `cache` 키워드를 사용하여 각 작업에 대해 정의됩니다:

```yaml
test-job:
  stage: build
  cache:
    - key:
        files:
          - Gemfile.lock
      paths:
        - vendor/ruby
    - key:
        files:
          - yarn.lock
      paths:
        - .yarn-cache/
  script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install
    - yarn install --cache-folder .yarn-cache
    - echo Run tests...
```

### 배포 {#deployments}

다음 예에서는 Bamboo 배포 프로젝트를 GitLab 배포 작업으로 변환하는 방법을 보여줍니다.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo는 빌드 플랜에 연결되어 배포 환경에 아티팩트를 추적, 가져오기 및 배포하는 배포 프로젝트를 가지고 있습니다. 프로젝트를 만들 때 빌드 플랜에 연결하고, 배포 환경을 지정하고, 배포를 수행할 작업을 지정합니다.

```yaml
deployment:
  name: Deploy ruby app
  source-plan: build-app

release-naming: release-1.0

environments:
  - Production

Production:
  tasks:
    - # scripts to deploy app to production
    - ./.ci/deploy_prod.sh
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CD에서는 환경에 배포하거나 릴리스를 생성하는 배포 작업을 생성할 수 있습니다.

```yaml
deploy-to-production:
  stage: deploy
  script:
    - # Run Deployment script
    - ./.ci/deploy_prod.sh
  environment:
    name: production
```

대신 릴리스를 생성하려면 `release` 키워드와 `glab` CLI 도구를 사용하여 Git 태그에 대한 릴리스를 생성합니다:

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  rules:
    - if: $CI_COMMIT_TAG                  # Run this job when a tag is created manually
  script:
    - echo "Building release version"
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the CLI.'
```

{{< /tab >}}

{{< /tabs >}}

## 보안 스캔 {#security-scanning}

Bamboo는 보안 스캔을 실행하기 위해 Atlassian Marketplace에서 제공하는 타사 작업을 사용합니다.

GitLab은 SDLC의 모든 부분에서 취약점을 감지하기 위한 보안 스캐너를 제공합니다. 템플릿을 사용하여 GitLab에서 이 스캐너를 추가할 수 있습니다(예: 파이프라인에 SAST 스캔 추가):

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

CI/CD 변수를 사용하여 보안 스캐너의 동작을 사용자 지정할 수 있습니다.

## 시크릿 관리 {#secrets-management}

Bamboo의 시크릿 관리는 공유 자격 증명을 사용하거나 Atlassian 마켓플레이스의 타사 애플리케이션을 사용하여 처리됩니다.

GitLab의 시크릿 관리를 위해 외부 서비스에 대해 지원되는 통합을 사용할 수 있습니다. 이 서비스는 GitLab 프로젝트 외부에서 시크릿을 안전하게 저장하지만, 서비스에 대한 구독이 있어야 합니다.

GitLab은 OIDC를 지원하는 다른 타사 서비스에 대한 OIDC 인증도 지원합니다.

또한 CI/CD 변수에 저장하여 작업에 자격 증명을 사용할 수 있게 하지만, 일반 텍스트로 저장된 시크릿은 실수로 노출될 가능성이 있습니다. 항상 위험을 완화하는 마스크된 보호된 변수에 민감한 정보를 저장해야 합니다.

> [!note]
> 프로젝트에 액세스할 수 있는 모든 사용자에게 공개되는 `.gitlab-ci.yml` 파일에 시크릿을 변수로 저장하지 마세요. 민감한 정보를 변수에 저장하는 것은 프로젝트, 그룹 또는 인스턴스 설정에서만 수행해야 합니다.

## 마이그레이션 계획 작성 {#create-a-migration-plan}

마이그레이션을 시작하기 전에 [마이그레이션 계획](plan_a_migration.md)을 작성하고 다음 질문에 답하세요:

- 오늘날 작업에서 사용하는 Bamboo 작업은 무엇이며 무엇을 합니까?
- 작업이 Maven, Gradle 또는 NPM과 같은 일반적인 빌드 도구를 래핑합니까?
- Bamboo 에이전트에 설치된 소프트웨어는 무엇입니까?
- Bamboo에서 (SSH 키, API 토큰 또는 기타 시크릿)에서 어떻게 인증합니까?
- 외부 서비스에 액세스할 수 있는 Bamboo의 자격 증명이 있습니까?
- 사용 중인 공유 라이브러리 또는 템플릿이 있습니까?

## Bamboo에서 GitLab CI/CD로 마이그레이션 {#migrate-from-bamboo-to-gitlab-cicd}

전제 조건:

- GitLab 인스턴스를 설정하고 구성해야 합니다.
- [러너](../runners/_index.md)를 사용할 수 있어야 합니다.

Bamboo에서 마이그레이션하려면:

1. Bamboo 구성 감시:
   - Bamboo UI에서 Bamboo 프로젝트/플랜을 YAML Spec로 내보냅니다.
   - 작업에 사용되는 모든 Bamboo 작업(예: Maven, Docker, SCP)을 나열합니다.
   - 각 Bamboo 에이전트에 설치된 소프트웨어 버전을 문서화합니다.
   - 모든 공유 자격 증명 및 해당 사용을 식별합니다.

1. 소스 코드 리포지토리를 GitLab으로 마이그레이션:
   - 사용 가능한 [가져오기](../../user/import/_index.md)를 사용하여 외부 SCM 공급자로부터의 대량 가져오기를 자동화합니다.
   - 개별 리포지토리에 대해 [URL로 리포지토리 가져오기](../../user/import/third_party_systems/repo_by_url.md)를 수행합니다.

1. 동등한 소프트웨어로 GitLab 러너 설정:
   - Bamboo 에이전트에 있는 동일한 소프트웨어 버전을 설치합니다.
   - 복잡한 에이전트 설정의 경우 필요한 도구를 사용하여 사용자 지정 Docker 이미지를 생성합니다.
   - 러너가 빌드 명령을 성공적으로 실행할 수 있는지 테스트합니다.

1. Bamboo Specs을 `.gitlab-ci.yml` 파일로 변환:
   - Bamboo 플랜 구조를 GitLab 스테이지 및 작업으로 바꿉니다.
   - `${bamboo.variableName}` 구문을 `$VARIABLE_NAME`로 변환합니다.
   - `${bamboo.planKey}`와 같은 Bamboo 특정 변수를 `$CI_PIPELINE_ID`과 같은 GitLab 동등값으로 바꿉니다.
   - Bamboo 체크아웃 작업을 제거합니다. GitLab은 각 작업의 시작 부분에서 소스 코드를 자동으로 체크아웃합니다.

1. 아티팩트 처리 마이그레이션:
   - Bamboo `artifact-subscriptions`및 `artifact-download` 구성을 제거합니다.
   - 스테이지 간 자동 아티팩트 상속을 사용합니다.
   - GitLab 작업 구조와 일치하도록 아티팩트 경로를 업데이트합니다.

1. Bamboo 배포 프로젝트 변환:
   - 별도의 Bamboo 배포 프로젝트에서 주 `.gitlab-ci.yml` 파일로 배포 작업을 이동합니다.
   - Bamboo 환경을 GitLab [환경](../environments/_index.md)으로 바꿉니다.
   - 일반적인 배포 패턴에 [클라우드 배포 템플릿](../cloud_deployment/_index.md)을 사용합니다.
   - Kubernetes에 배포하는 경우 [Kubernetes용 GitLab 에이전트](../../user/clusters/agent/_index.md)를 구성합니다.

1. 시크릿 및 자격 증명 마이그레이션:
   - [외부 시크릿 통합](../secrets/_index.md)을 사용하거나 자격 증명을 마스크된 CI/CD 변수로 저장합니다.

1. 마이그레이션된 파이프라인 테스트 및 최적화:
   - 기능을 확인하기 위해 테스트 파이프라인을 실행합니다.
   - 파이프라인 결과를 표시하기 위해 머지 리퀘스트 통합을 추가합니다.
   - 파이프라인 성능을 최적화하고 재사용 가능한 템플릿을 만듭니다.

## 관련 항목 {#related-topics}

- [시작 가이드](../_index.md)
- [CI/CD YAML 구문 참고](../yaml/_index.md)
- [GitLab CI/CD 변수](../variables/_index.md)
- [파이프라인 효율](../pipelines/pipeline_efficiency.md)
