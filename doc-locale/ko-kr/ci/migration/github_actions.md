---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitHub Actions에서 마이그레이션
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitHub Actions에서 GitLab CI/CD로 마이그레이션하는 경우, GitHub Action 워크플로우를 복제하고 향상하는 CI/CD 파이프라인을 만들 수 있습니다.

이를 수동으로 수행하거나 선택한 에이전트와 함께 [GitHub Actions to GitLab CI/CD agent skill](https://about.gitlab.com/github-actions-to-gitlab-ci/)을 사용할 수 있습니다.

## 주요 유사점 및 차이점 {#key-similarities-and-differences}

GitHub Actions와 GitLab CI/CD는 모두 코드를 빌드, 테스트 및 배포하는 것을 자동화하는 파이프라인을 생성하는 데 사용됩니다. 둘 다 다음을 포함한 유사점을 공유합니다:

- CI/CD 기능은 프로젝트 리포지토리에 저장된 코드에 직접 액세스할 수 있습니다.
- 파이프라인 구성은 YAML로 작성되고 프로젝트 리포지토리에 저장됩니다.
- 파이프라인은 구성 가능하며 다양한 스테이지에서 실행할 수 있습니다.
- 각 작업은 다른 컨테이너 이미지를 사용할 수 있습니다.

또한 두 서비스 간에 몇 가지 중요한 차이점이 있습니다:

- GitHub에는 타사 작업을 다운로드할 수 있는 마켓플레이스가 있으며, 이는 추가 지원 또는 라이선스가 필요할 수 있습니다.
- GitLab Self-Managed는 수평 및 수직 크기 조정을 모두 지원하지만, GitHub Enterprise Server는 수직 크기 조정만 지원합니다.
- GitLab은 모든 기능을 사내에서 유지 관리 및 지원하며, 일부 타사 통합은 템플릿을 통해 액세스할 수 있습니다.
- GitLab은 기본 제공 컨테이너 레지스트리를 제공합니다.
- GitLab은 기본적으로 Kubernetes 배포를 지원합니다.
- GitLab은 세분화된 보안 정책을 제공합니다.

## 기능 및 개념 비교 {#comparison-of-features-and-concepts}

많은 GitHub 기능 및 개념은 동일한 기능을 제공하는 GitLab의 동등한 기능을 가지고 있습니다.

### 구성 파일 {#configuration-file}

GitHub Actions는 [workflow YAML file](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#understanding-the-workflow-file)로 구성할 수 있습니다. GitLab CI/CD는 기본적으로 `.gitlab-ci.yml` YAML 파일을 사용합니다.

예를 들어, GitHub Actions `workflow` 파일에서:

```yaml
on: [push]
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Hello World"
```

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
stages:
  - hello

hello:
  stage: hello
  script:
    - echo "Hello World"
```

### GitHub Actions 워크플로우 구문 {#github-actions-workflow-syntax}

GitHub Actions 구성은 특정 키워드를 사용하여 `workflow` YAML 파일에서 정의됩니다. GitLab CI/CD는 유사한 기능을 가지고 있으며, 일반적으로 YAML 키워드로도 구성됩니다.

| GitHub    | GitLab         | 설명 |
|-----------|----------------|-------------|
| `env`     | `variables`    | `env`은 워크플로우, 작업, 또는 단계에서 설정된 변수를 정의합니다. GitLab은 `variables`을 사용하여 전역 또는 작업 수준에서 [CI/CD 변수](../variables/_index.md)를 정의합니다. 변수는 UI에서도 추가할 수 있습니다. |
| `jobs`    | `stages`       | `jobs`은 워크플로우에서 실행되는 모든 작업을 함께 그룹화합니다. GitLab은 `stages`을 사용하여 작업을 함께 그룹화합니다. |
| `on`      | 해당 없음 | `on`은 워크플로우가 트리거되는 시점을 정의합니다. GitLab은 Git과 긴밀하게 통합되어 있으므로 트리거를 위한 SCM 폴링 옵션이 필요하지 않지만, 필요한 경우 작업별로 구성할 수 있습니다. |
| `run`     | 해당 없음 | 작업에서 실행할 명령입니다. GitLab은 `script` 키워드 아래에 YAML 배열을 사용하며, 실행할 각 명령에 대해 하나의 항목입니다. |
| `runs-on` | `tags`         | `runs-on`은 작업이 실행되어야 하는 GitHub 러너를 정의합니다. GitLab은 `tags`을 사용하여 러너를 선택합니다. |
| `steps`   | `script`       | `steps`은 작업에서 실행되는 모든 단계를 함께 그룹화합니다. GitLab은 `script`을 사용하여 작업에서 실행되는 모든 명령을 함께 그룹화합니다. |
| `uses`    | `include`      | `uses`은 `step`에 추가할 GitHub Action을 정의합니다. GitLab은 `include`을 사용하여 다른 파일의 구성을 작업에 추가합니다. |

### 일반적인 구성 {#common-configurations}

이 섹션에서는 일반적으로 사용되는 CI/CD 구성을 살펴보고 GitHub Actions에서 GitLab CI/CD로 변환하는 방법을 보여줍니다.

[GitHub Action 워크플로우](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#workflows)는 새로운 커밋을 푸시하는 것과 같이 특정 이벤트가 발생할 때 트리거되는 자동화된 CI/CD 작업을 생성합니다. GitHub Action 워크플로우는 리포지토리의 루트에 위치한 `.github/workflows` 디렉터리에서 정의된 YAML 파일입니다. GitLab과 동등한 것은 `.gitlab-ci.yml` 구성 파일이며, 이는 리포지토리의 루트 디렉터리에도 있습니다.

#### 작업 {#jobs}

작업은 컨테이너를 빌드하거나 프로덕션에 배포하는 것과 같이 특정 결과를 달성하기 위해 순서대로 실행되는 명령 집합입니다.

예를 들어, 이 GitHub Actions `workflow`은 컨테이너를 빌드한 다음 프로덕션에 배포합니다. 작업은 순차적으로 실행되며, `deploy` 작업이 `build` 작업에 의존하기 때문입니다:

```yaml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    container: golang:alpine
    steps:
      - run: apk update
      - run: go build -o bin/hello
      - uses: actions/upload-artifact@v3
        with:
          name: hello
          path: bin/hello
          retention-days: 7
  deploy:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    container: golang:alpine
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: hello
      - run: echo "Deploying to Staging"
      - run: scp bin/hello remoteuser@remotehost:/remote/directory
```

이 예제:

- `golang:alpine` 컨테이너 이미지를 사용합니다.
- 코드 빌드를 위한 작업을 실행합니다.
  - 빌드 실행 파일을 성공물로 저장합니다.
- `staging`에 배포하기 위한 두 번째 작업을 실행하며, 이는 또한:
  - 빌드 작업이 실행되기 전에 성공해야 합니다.
  - 커밋 대상 브랜치를 `staging`로 요구합니다.
  - 빌드 실행 파일 성공물을 사용합니다.

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
default:
  image: golang:alpine

stages:
  - build
  - deploy

build-job:
  stage: build
  script:
    - apk update
    - go build -o bin/hello
  artifacts:
    paths:
      - bin/hello
    expire_in: 1 week

deploy-job:
  stage: deploy
  script:
    - echo "Deploying to Staging"
    - scp bin/hello remoteuser@remotehost:/remote/directory
  rules:
    - if: $CI_COMMIT_BRANCH == 'staging'
```

##### 병렬 {#parallel}

GitHub와 GitLab 모두에서 작업은 기본적으로 병렬로 실행됩니다.

예를 들어, GitHub Actions `workflow` 파일에서:

```yaml
on: [push]
jobs:
  python-version:
    runs-on: ubuntu-latest
    container: python:latest
    steps:
      - run: python --version
  java-version:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    container: openjdk:latest
    steps:
      - run: java -version
```

이 예제는 Python 작업과 Java 작업을 병렬로 실행하며, 서로 다른 컨테이너 이미지를 사용합니다. Java 작업은 `staging` 브랜치가 변경될 때만 실행됩니다.

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
python-version:
  image: python:latest
  script:
    - python --version

java-version:
  image: openjdk:latest
  rules:
    - if: $CI_COMMIT_BRANCH == 'staging'
  script:
    - java -version
```

이 경우 작업을 병렬로 실행하기 위해 추가 구성이 필요하지 않습니다. 작업은 기본적으로 병렬로 실행되며, 모든 작업에 충분한 러너가 있다고 가정하여 각각 다른 러너에서 실행됩니다. Java 작업은 `staging` 브랜치가 변경될 때만 실행되도록 설정됩니다.

##### 매트릭스 {#matrix}

GitLab과 GitHub 모두에서 매트릭스를 사용하여 단일 파이프라인에서 작업을 여러 번 병렬로 실행할 수 있지만, 작업의 각 인스턴스에 대해 서로 다른 변수 값을 사용합니다.

예를 들어, GitHub Actions `workflow` 파일에서:

```yaml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
```

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
stages:
  - build
  - test
  - deploy

.parallel-hidden-job:
  parallel:
    matrix:
      - PLATFORM: [linux, mac, windows]
        ARCH: [x64, x86]

build-job:
  extends: .parallel-hidden-job
  stage: build
  script:
    - echo "Building $PLATFORM for $ARCH"

test-job:
  extends: .parallel-hidden-job
  stage: test
  script:
    - echo "Testing $PLATFORM for $ARCH"

deploy-job:
  extends: .parallel-hidden-job
  stage: deploy
  script:
    - echo "Deploying $PLATFORM for $ARCH"
```

#### 트리거 {#trigger}

GitHub Actions는 워크플로우에 대한 트리거를 추가하도록 요구합니다. GitLab은 Git과 긴밀하게 통합되어 있으므로 트리거를 위한 SCM 폴링 옵션이 필요하지 않지만, 필요한 경우 작업별로 구성할 수 있습니다.

샘플 GitHub Actions 구성:

```yaml
on:
  push:
    branches:
      - main
```

동등한 GitLab CI/CD 구성은 다음과 같습니다:

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH == main'
```

파이프라인은 [Cron 구문을 사용하여 예약](../pipelines/schedules.md)할 수도 있습니다.

#### 컨테이너 이미지 {#container-images}

GitLab을 사용하면 [CI/CD 작업을 별도의 격리된 Docker 컨테이너에서 실행](../docker/using_docker_images.md)할 수 있으며, [`image`](../yaml/_index.md#image) 키워드를 사용합니다.

예를 들어, GitHub Actions `workflow` 파일에서:

```yaml
jobs:
  update:
    runs-on: ubuntu-latest
    container: alpine:latest
    steps:
      - run: apk update
```

이 예제에서 `apk update` 명령은 `alpine:latest` 컨테이너에서 실행됩니다.

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
update-job:
  image: alpine:latest
  script:
    - apk update
```

GitLab은 모든 프로젝트에 컨테이너 이미지를 호스팅하기 위한 [컨테이너 레지스트리](../../user/packages/container_registry/_index.md)를 제공합니다. 컨테이너 이미지는 GitLab CI/CD 파이프라인에서 직접 빌드하고 저장할 수 있습니다.

예를 들어:

```yaml
stages:
  - build

build-image:
  stage: build
  variables:
    IMAGE: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE .
    - docker push $IMAGE
```

#### 변수 {#variables}

`variables` 키워드를 사용하여 런타임에 다양한 [CI/CD 변수](../variables/_index.md)를 정의할 수 있습니다. 파이프라인에서 구성 데이터를 재사용해야 할 때 변수를 사용합니다. 변수를 전역적으로 또는 작업별로 정의할 수 있습니다.

예를 들어, GitHub Actions `workflow` 파일에서:

```yaml
env:
  NAME: "fern"

jobs:
  english:
    runs-on: ubuntu-latest
    env:
      Greeting: "hello"
    steps:
      - run: echo "$GREETING $NAME"
  spanish:
    runs-on: ubuntu-latest
    env:
      Greeting: "hola"
    steps:
      - run: echo "$GREETING $NAME"
```

이 예제에서 변수는 작업에 대해 서로 다른 출력을 제공합니다.

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
default:
  image: ubuntu-latest

variables:
  NAME: "fern"

english:
  variables:
    GREETING: "hello"
  script:
    - echo "$GREETING $NAME"

spanish:
  variables:
    GREETING: "hola"
  script:
    - echo "$GREETING $NAME"
```

변수는 CI/CD 설정의 GitLab UI를 통해서도 설정할 수 있으며, 여기서 변수를 [보호](../variables/_index.md#protect-a-cicd-variable)하거나 [마스킹](../variables/_index.md#mask-a-cicd-variable)할 수 있습니다. 마스킹된 변수는 작업 로그에서 숨겨지지만, 보호된 변수는 보호된 브랜치 또는 태그의 파이프라인에서만 액세스할 수 있습니다.

예를 들어, GitHub Actions `workflow` 파일에서:

```yaml
jobs:
  login:
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
    steps:
      - run: my-login-script.sh "$AWS_ACCESS_KEY"
```

`AWS_ACCESS_KEY` 변수가 GitLab 프로젝트 설정에서 정의된 경우, 동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
login:
  script:
    - my-login-script.sh $AWS_ACCESS_KEY
```

또한, [GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/contexts)와 [GitLab CI/CD](../variables/predefined_variables.md)는 파이프라인과 리포지토리와 관련된 데이터를 포함하는 기본 제공 변수를 제공합니다.

#### 조건 {#conditionals}

새로운 파이프라인이 시작되면, GitLab은 파이프라인 구성을 확인하여 어떤 작업이 해당 파이프라인에서 실행되어야 하는지 결정합니다. [`rules` 키워드](../yaml/_index.md#rules)를 사용하여 변수 상태 또는 파이프라인 유형과 같은 조건에 따라 실행되도록 작업을 구성할 수 있습니다.

예를 들어, GitHub Actions `workflow` 파일에서:

```yaml
jobs:
  deploy_staging:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploy to staging server"
```

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
deploy_staging:
  stage: deploy
  script:
    - echo "Deploy to staging server"
  rules:
    - if: '$CI_COMMIT_BRANCH == staging'
```

#### 러너 {#runners}

러너는 작업을 실행하는 서비스입니다. GitLab.com을 사용하는 경우, [인스턴스 러너 플릿](../runners/_index.md)을 사용하여 자체 관리 러너를 프로비저닝하지 않고도 작업을 실행할 수 있습니다.

러너에 대한 몇 가지 주요 세부 정보:

- 러너는 [구성](../runners/runners_scope.md)되어 인스턴스, 그룹 또는 단일 프로젝트 전체에서 공유될 수 있습니다.
- [`tags` 키워드](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)를 사용하여 더 세밀한 제어를 수행하고 러너를 특정 작업과 연결할 수 있습니다. 예를 들어, 전용, 더 강력하거나 특정 하드웨어가 필요한 작업에 대해 태그를 사용할 수 있습니다.
- GitLab은 [러너에 대한 자동 크기 조정](https://docs.gitlab.com/runner/configuration/autoscale/)을 가지고 있습니다. 필요할 때만 러너를 프로비저닝하고 필요하지 않을 때 축소하려면 자동 크기 조정을 사용하세요.

예를 들어, GitHub Actions `workflow` 파일에서:

```yaml
linux_job:
  runs-on: ubuntu-latest
  steps:
    - run: echo "Hello, $USER"

windows_job:
  runs-on: windows-latest
  steps:
    - run: echo "Hello, %USERNAME%"
```

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
linux_job:
  stage: build
  tags:
    - linux-runners
  script:
    - echo "Hello, $USER"

windows_job:
  stage: build
  tags:
    - windows-runners
  script:
    - echo "Hello, %USERNAME%"
```

#### 아티팩트 {#artifacts}

GitLab에서 모든 작업은 [성공물](../yaml/_index.md#artifacts) 키워드를 사용하여 작업이 완료될 때 저장할 일련의 성공물을 정의할 수 있습니다. [성공물](../jobs/job_artifacts.md)은 나중의 작업에서 사용할 수 있는 파일입니다.

예를 들어, GitHub Actions `workflow` 파일에서:

```yaml
on: [push]
jobs:
  generate_cat:
    steps:
      - run: touch cat.txt
      - run: echo "meow" > cat.txt
      - uses: actions/upload-artifact@v3
        with:
          name: cat
          path: cat.txt
          retention-days: 7
  use_cat:
    needs: [generate_cat]
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: cat
      - run: cat cat.txt
```

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
stage:
  - generate
  - use

generate_cat:
  stage: generate
  script:
    - touch cat.txt
    - echo "meow" > cat.txt
  artifacts:
    paths:
      - cat.txt
    expire_in: 1 week

use_cat:
  stage: use
  script:
    - cat cat.txt
```

#### 캐싱 {#caching}

[캐시](../caching/_index.md)는 작업이 하나 이상의 파일을 다운로드하고 향후 더 빠른 액세스를 위해 저장할 때 생성됩니다. 동일한 캐시를 사용하는 후속 작업은 파일을 다시 다운로드할 필요가 없으므로 더 빠르게 실행됩니다. 캐시는 러너에 저장되고 [분산 캐시가 활성화된](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching) 경우 S3로 업로드됩니다.

예를 들어, GitHub Actions `workflow` 파일에서:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - run: echo "This job uses a cache."
    - uses: actions/cache@v3
      with:
        path: binaries/
        key: binaries-cache-$CI_COMMIT_REF_SLUG
```

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

#### 템플릿 {#templates}

GitHub에서 Action은 자주 반복해야 하는 복잡한 작업 집합이며, CI/CD 파이프라인을 다시 정의하지 않고도 재사용을 가능하게 하기 위해 저장됩니다. GitLab에서 작업과 동등한 것은 [`include` 키워드](../yaml/includes.md)이며, 이를 통해 [다른 파일에서 CI/CD 파이프라인 추가](../yaml/includes.md)할 수 있으며, GitLab에 내장된 템플릿 파일을 포함합니다.

샘플 GitHub Actions 구성:

```yaml
- uses: hashicorp/setup-terraform@v2.0.3
```

동등한 GitLab CI/CD 구성은 다음과 같습니다:

```yaml
include:
  - template: Terraform.gitlab-ci.yml
```

이 예제에서 `setup-terraform` GitHub Action과 `Terraform.gitlab-ci.yml` GitLab 템플릿은 정확히 일치하지 않습니다. 이 두 예제는 복잡한 구성을 재사용하는 방법을 보여주기 위한 것입니다.

### 보안 스캐닝 기능 {#security-scanning-features}

GitLab은 SLDC의 모든 부분에서 취약점을 감지하기 위해 즉시 사용 가능한 다양한 [보안 스캐너](../../user/application_security/_index.md)를 제공합니다. 템플릿을 사용하여 이러한 기능을 GitLab CI/CD 파이프라인에 추가할 수 있습니다.

예를 들어 SAST 스캐닝을 파이프라인에 추가하려면 `.gitlab-ci.yml`에 다음을 추가합니다:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

CI/CD 변수를 사용하여 보안 스캐너의 동작을 사용자 정의할 수 있으며, 예를 들어 [SAST 스캐너](../../user/application_security/sast/_index.md#available-cicd-variables)를 사용합니다.

### 시크릿 관리 {#secrets-management}

"시크릿"이라고 하는 권한 있는 정보는 CI/CD 워크플로우에서 필요한 민감한 정보 또는 자격 증명입니다. 시크릿을 사용하여 보호된 리소스나 도구, 애플리케이션, 컨테이너 및 클라우드 네이티브 환경에서 민감한 정보를 잠금 해제할 수 있습니다.

GitLab의 시크릿 관리를 위해 외부 서비스용 [지원되는 통합](../secrets/_index.md) 중 하나를 사용할 수 있습니다. 이 서비스는 GitLab 프로젝트 외부에서 시크릿을 안전하게 저장하지만, 서비스에 대한 구독이 있어야 합니다.

GitLab은 OIDC를 지원하는 다른 타사 서비스용 [OIDC 인증](../secrets/id_token_authentication.md)도 지원합니다.

또한 CI/CD 변수에 저장하여 작업에 자격 증명을 사용할 수 있게 하지만, 일반 텍스트로 저장된 시크릿은 실수로 노출될 가능성이 있습니다. 민감한 정보는 항상 [마스킹된](../variables/_index.md#mask-a-cicd-variable) 변수와 [보호](../variables/_index.md#protect-a-cicd-variable) 변수에 저장해야 하므로 일부 위험을 완화합니다.

`.gitlab-ci.yml` 파일에 시크릿을 변수로 저장하면 안 되며, 이는 프로젝트에 액세스할 수 있는 모든 사용자에게 공개됩니다. 민감한 정보를 변수에 저장하는 것은 [프로젝트, 그룹 또는 인스턴스 설정](../variables/_index.md#define-a-cicd-variable-in-the-ui)에서만 수행해야 합니다.

CI/CD 변수의 안전성을 개선하려면 [보안 지침](../variables/_index.md#cicd-variable-security)을 검토하세요.

## 마이그레이션 계획 및 수행 {#planning-and-performing-a-migration}

다음 권장 단계 목록은 이 마이그레이션을 빠르게 완료할 수 있었던 조직을 관찰한 후에 작성되었습니다.

### 마이그레이션 계획 만들기 {#create-a-migration-plan}

마이그레이션을 시작하기 전에 마이그레이션 준비를 위해 [마이그레이션 계획](plan_a_migration.md)을 수립해야 합니다.

### 전제 조건 {#prerequisites}

마이그레이션 작업을 수행하기 전에 먼저 다음을 수행해야 합니다:

1. GitLab에 익숙해지세요.
   - [GitLab CI/CD 주요 기능](../_index.md)에 대해 읽어보세요.
   - [첫 번째 GitLab 파이프라인](../quick_start/_index.md)을 만들고 [더 복잡한 파이프라인](../quick_start/tutorial.md)을 만드는 튜토리얼을 따라 정적 사이트를 빌드, 테스트 및 배포합니다.
   - [CI/CD YAML 구문 참조](../yaml/_index.md)를 검토하세요.
1. GitLab을 설정하고 구성하세요.
1. GitLab 인스턴스를 테스트하세요.
   - 공유 GitLab.com 러너를 사용하거나 새로운 러너를 설치하여 [러너](../runners/_index.md)를 사용할 수 있는지 확인하세요.

### 마이그레이션 단계 {#migration-steps}

1. GitHub에서 GitLab으로 프로젝트 마이그레이션:
   - (권장) [GitHub Importer](../../user/project/import/github.md)를 사용하여 외부 SCM 공급자에서 대량 가져오기를 자동화할 수 있습니다.
   - [URL로 리포지토리 가져오기](../../user/import/third_party_systems/repo_by_url.md)를 수행할 수 있습니다.
1. 각 프로젝트에서 `.gitlab-ci.yml`을 만듭니다.
1. GitHub Actions 작업을 GitLab CI/CD 작업으로 마이그레이션하고 머지 리퀘스트에서 직접 결과를 표시하도록 구성합니다. 이는 [제공된 Agent Skill](https://gitlab.com/gitlab-org/ci-cd/github-actions-to-gitlab-ci)을 사용하여 자동화할 수 있습니다.
1. [클라우드 배포 템플릿](../cloud_deployment/_index.md), [환경](../environments/_index.md) 및 [Kubernetes용 GitLab 에이전트](../../user/clusters/agent/_index.md)를 사용하여 배포 작업을 마이그레이션합니다.
1. 다양한 프로젝트 간에 재사용할 수 있는 CI/CD 구성이 있는지 확인한 후 [CI/CD 구성 요소](../components/_index.md)를 만들고 공유합니다.
1. [파이프라인 효율성 문서](../pipelines/pipeline_efficiency.md)를 확인하여 GitLab CI/CD 파이프라인을 더 빠르고 효율적으로 만드는 방법을 알아보세요.

### 추가 리소스 {#additional-resources}

- [비디오: GitHub에서 Actions를 포함한 GitLab으로 마이그레이션하는 방법](https://youtu.be/0Id5oMl1Kqs?feature=shared)
- [블로그: GitHub에서 GitLab으로의 쉬운 마이그레이션](https://about.gitlab.com/blog/github-to-gitlab-migration-made-easy/)

여기서 답변하지 않은 질문이 있으면 [GitLab 커뮤니티 포럼](https://forum.gitlab.com/)이 좋은 리소스가 될 수 있습니다.
