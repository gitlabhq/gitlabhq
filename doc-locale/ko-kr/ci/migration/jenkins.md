---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jenkins에서 마이그레이션
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Jenkins에서 GitLab CI/CD로 마이그레이션하는 경우 Jenkins 워크플로우를 복제하고 개선하는 CI/CD 파이프라인을 만들 수 있습니다.

## 주요 유사점과 차이점 {#key-similarities-and-differences}

GitLab CI/CD와 Jenkins는 몇 가지 유사점이 있는 CI/CD 도구입니다. GitLab과 Jenkins 모두:

- 스테이지를 작업 모음으로 사용합니다.
- 컨테이너 기반 빌드를 지원합니다.

또한 둘 사이에는 몇 가지 중요한 차이점이 있습니다:

- GitLab CI/CD 파이프라인은 모두 YAML 형식 구성 파일에서 구성됩니다. Jenkins는 Groovy 형식 구성 파일(선언형 파이프라인) 또는 Jenkins DSL(스크립트형 파이프라인)을 사용합니다.
- GitLab은 [GitLab.com](../../subscriptions/manage_seats.md#gitlabcom-billing-and-usage)(다중 테넌트 SaaS 서비스)과 [GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md)(완전히 격리된 단일 테넌트 서비스)를 제공합니다. 자신의 [GitLab Self-Managed](../../subscriptions/manage_subscription.md) 인스턴스를 실행할 수도 있습니다. Jenkins 배포는 자체 호스팅되어야 합니다.
- GitLab은 소스 코드 관리(SCM)를 기본으로 제공합니다. Jenkins는 코드를 저장하기 위해 별도의 SCM 솔루션이 필요합니다.
- GitLab은 기본 제공 컨테이너 레지스트리를 제공합니다. Jenkins는 컨테이너 이미지를 저장하기 위해 별도의 솔루션이 필요합니다.
- GitLab은 코드 스캔을 위한 기본 제공 템플릿을 제공합니다. Jenkins는 코드 스캔을 위해 타사 플러그인이 필요합니다.

## 기능 및 개념 비교 {#comparison-of-features-and-concepts}

많은 Jenkins 기능 및 개념이 GitLab에서 동일한 기능을 제공하는 동등한 기능을 가지고 있습니다.

### 구성 파일 {#configuration-file}

Jenkins는 Groovy 형식의 [`Jenkinsfile`](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/)로 구성할 수 있습니다. GitLab CI/CD는 기본적으로 `.gitlab-ci.yml` 파일을 사용합니다.

`Jenkinsfile`의 예:

```groovy
pipeline {
    agent any

    stages {
        stage('hello') {
            steps {
                echo "Hello World"
            }
        }
    }
}
```

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
stages:
  - hello

hello-job:
  stage: hello
  script:
    - echo "Hello World"
```

### Jenkins 파이프라인 구문 {#jenkins-pipeline-syntax}

Jenkins 구성은 섹션 및 지시문이 있는 `pipeline` 블록으로 구성됩니다. GitLab CI/CD는 YAML 키워드로 구성된 유사한 기능을 가지고 있습니다.

#### 섹션 {#sections}

| Jenkins  | GitLab         | 설명 |
|----------|----------------|-------------|
| `agent`  | `image`        | Jenkins 파이프라인은 에이전트에서 실행되며, `agent` 섹션은 파이프라인 실행 방식 및 사용할 Docker 컨테이너를 정의합니다. GitLab 작업은 러너에서 실행되며, `image` 키워드는 사용할 컨테이너를 정의합니다. Kubernetes 또는 다른 호스트에서 자신의 러너를 구성할 수 있습니다. |
| `post`   | `after_script` 또는 `stage` | Jenkins `post` 섹션은 스테이지 또는 파이프라인 끝에서 수행해야 하는 작업을 정의합니다. GitLab에서는 `after_script`를 사용하여 작업 끝에 실행할 명령을 지정하고, `before_script`를 사용하여 작업의 다른 명령 전에 실행할 작업을 지정합니다. `stage`를 사용하여 작업이 실행되어야 하는 정확한 스테이지를 선택합니다. GitLab은 `.pre` 및 `.post` 스테이지를 지원하며, 이는 항상 다른 모든 정의된 스테이지 전이나 후에 실행됩니다. |
| `stages` | `stages`       | Jenkins 스테이지는 작업 그룹입니다. GitLab CI/CD도 스테이지를 사용하지만 더 유연합니다. 각각 여러 개의 독립적인 작업이 있는 여러 스테이지를 가질 수 있습니다. `stages`를 최상위 수준에서 사용하여 스테이지와 실행 순서를 정의하고, `stage`를 작업 수준에서 사용하여 해당 작업의 스테이지를 정의합니다. |
| `steps`  | `script`       | Jenkins `steps`는 실행할 작업을 정의합니다. GitLab CI/CD는 유사한 `script` 섹션을 사용합니다. `script` 섹션은 순서대로 실행할 각 명령의 별도 항목이 있는 YAML 배열입니다. |

#### 지시문 {#directives}

| Jenkins       | GitLab         | 설명 |
|---------------|----------------|-------------|
| `environment` | `variables`    | Jenkins는 환경 변수를 위해 `environment`을(를) 사용합니다. GitLab CI/CD는 `variables` 키워드를 사용하여 작업 실행 중에 사용할 수 있는 CI/CD 변수를 정의하지만 더 동적인 파이프라인 구성에도 사용됩니다. 이러한 항목은 GitLab UI의 CI/CD 설정에서도 설정할 수 있습니다. |
| `options`     | 해당 없음 | Jenkins는 타임아웃 및 재시도 값을 포함한 추가 구성을 위해 `options`을(를) 사용합니다. GitLab은 옵션을 위한 별도의 섹션이 필요하지 않습니다. 모든 구성은 작업 또는 파이프라인 수준에서 CI/CD 키워드로 추가됩니다(예: `timeout` 또는 `retry`). |
| `parameters`  | 해당 없음 | Jenkins에서는 파이프라인을 트리거할 때 매개변수가 필요할 수 있습니다. 매개변수는 GitLab에서 CI/CD 변수로 처리되며, 파이프라인 구성, 프로젝트 설정, 런타임 중 UI를 통해 수동으로, 또는 API를 포함한 여러 위치에서 정의할 수 있습니다. |
| `triggers`    | `rules`        | Jenkins에서 `triggers`는 cron 표기법을 통해 예를 들어 파이프라인이 다시 실행되는 시기를 정의합니다. GitLab CI/CD는 Git 변경 사항 및 머지 리퀘스트 업데이트를 포함한 여러 가지 이유로 파이프라인을 자동으로 실행할 수 있습니다. `rules` 키워드를 사용하여 작업을 실행할 이벤트를 제어합니다. 예약된 파이프라인은 프로젝트 설정에서 정의됩니다. |
| `tools`       | 해당 없음 | Jenkins에서 `tools`는 환경에 설치할 추가 도구를 정의합니다. GitLab은 유사한 키워드를 가지고 있지 않습니다. 권장 사항은 작업에 필요한 정확한 도구로 미리 빌드된 컨테이너 이미지를 사용하는 것입니다. 이러한 이미지는 캐시할 수 있으며, 파이프라인에 필요한 도구를 이미 포함하도록 빌드할 수 있습니다. 작업에 추가 도구가 필요한 경우 `before_script` 섹션의 일부로 설치할 수 있습니다. |
| `input`       | 해당 없음 | Jenkins에서 `input`는 사용자 입력에 대한 프롬프트를 추가합니다. `parameters`와 유사하게 입력은 GitLab에서 CI/CD 변수를 통해 처리됩니다. |
| `when`        | `rules`        | Jenkins에서 `when`는 스테이지가 실행되는 시기를 정의합니다. GitLab도 `when` 키워드를 가지고 있으며, 이는 이전 작업의 상태(예: 작업 통과 또는 실패 여부)에 따라 작업이 실행을 시작하는지 여부를 정의합니다. 특정 파이프라인에 작업을 추가할 시기를 제어하려면 `rules`을(를) 사용합니다. |

### 일반적인 구성 {#common-configurations}

이 섹션에서는 commonly used CI/CD configurations를 다루고 있으며, Jenkins에서 GitLab CI/CD로 변환할 수 있는 방법을 설명합니다.

[Jenkins 파이프라인](https://www.jenkins.io/doc/book/pipeline/)은 새 커밋이 푸시되는 등 특정 이벤트가 발생할 때 트리거되는 자동화된 CI/CD 작업을 생성합니다. Jenkins 파이프라인은 `Jenkinsfile`에 정의됩니다. GitLab 동등 항목은 [`.gitlab-ci.yml` 구성 파일](../yaml/_index.md)입니다.

Jenkins는 소스 코드를 저장할 수 있는 위치를 제공하지 않으므로 `Jenkinsfile`을(를) 별도의 소스 제어 리포지토리에 저장해야 합니다.

#### 작업 {#jobs}

작업은 특정 결과를 얻기 위해 집합 시퀀스에서 실행되는 명령 세트입니다.

예를 들어 `Jenkinsfile`에서 컨테이너를 빌드한 다음 프로덕션에 배포하는 경우:

```groovy
pipeline {
    agent any
    stages {
        stage('build') {
            agent { docker 'golang:alpine' }
            steps {
                apk update
                go build -o bin/hello
            }
            post {
              always {
                archiveArtifacts artifacts: 'bin/hello'
                onlyIfSuccessful: true
              }
            }
        }
        stage('deploy') {
            agent { docker 'golang:alpine' }
            when {
              branch 'staging'
            }
            steps {
                echo "Deploying to staging"
                scp bin/hello remoteuser@remotehost:/remote/directory
            }
        }
    }
}
```

이 예에서는:

- `golang:alpine` 컨테이너 이미지를 사용합니다.
- 코드 빌드를 위한 작업을 실행합니다.
  - 빌드된 실행 파일을 아티팩트로 저장합니다.
- 배포를 위해 두 번째 작업을 `staging`에 추가하는데, 다음을 수행합니다:
  - 커밋이 `staging` 브랜치를 대상으로 하는 경우에만 존재합니다.
  - 빌드 스테이지가 성공하면 시작됩니다.
  - 이전 작업에서 빌드된 실행 파일 아티팩트를 사용합니다.

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
  artifacts:
    paths:
      - bin/hello
```

##### 병렬 {#parallel}

Jenkins에서는 이전 작업에 의존하지 않는 작업이 `parallel` 섹션에 추가될 때 병렬로 실행될 수 있습니다.

예를 들어 `Jenkinsfile`에서:

```groovy
pipeline {
    agent any
    stages {
        stage('Parallel') {
            parallel {
                stage('Python') {
                    agent { docker 'python:latest' }
                    steps {
                        sh "python --version"
                    }
                }
                stage('Java') {
                    agent { docker 'openjdk:latest' }
                    when {
                        branch 'staging'
                    }
                    steps {
                        sh "java -version"
                    }
                }
            }
        }
    }
}
```

이 예에서는 Python 및 Java 작업을 병렬로 실행하며 다양한 컨테이너 이미지를 사용합니다. Java 작업은 `staging` 브랜치가 변경될 때만 실행됩니다.

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

이 경우 작업이 병렬로 실행되도록 하는 데 추가 구성이 필요하지 않습니다. 작업은 기본적으로 병렬로 실행되며, 모든 작업에 대해 충분한 러너가 있다고 가정하여 각각 다른 러너에서 실행됩니다. Java 작업은 `staging` 브랜치가 변경될 때만 실행되도록 설정됩니다.

##### 행렬 {#matrix}

GitLab에서는 행렬을 사용하여 작업을 단일 파이프라인에서 여러 번 병렬로 실행할 수 있지만, 각 작업 인스턴스에 대해 다양한 변수 값을 사용합니다. Jenkins는 행렬을 순차적으로 실행합니다.

예를 들어 `Jenkinsfile`에서:

```groovy
matrix {
    axes {
        axis {
            name 'PLATFORM'
            values 'linux', 'mac', 'windows'
        }
        axis {
            name 'ARCH'
            values 'x64', 'x86'
        }
    }
    stages {
        stage('build') {
            echo "Building $PLATFORM for $ARCH"
        }
        stage('test') {
            echo "Building $PLATFORM for $ARCH"
        }
        stage('deploy') {
            echo "Building $PLATFORM for $ARCH"
        }
    }
}
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
    - echo "Testing $PLATFORM for $ARCH"
```

#### 컨테이너 이미지 {#container-images}

GitLab에서는 [CI/CD 작업을 별도의 격리된 Docker 컨테이너에서 실행](../docker/using_docker_images.md)할 수 있으며, [image](../yaml/_index.md#image) 키워드를 사용합니다.

예를 들어 `Jenkinsfile`에서:

```groovy
stage('Version') {
    agent { docker 'python:latest' }
    steps {
        echo 'Hello Python'
        sh 'python --version'
    }
}
```

이 예에서는 `python:latest` 컨테이너에서 명령을 실행하는 것을 보여줍니다.

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
version-job:
  image: python:latest
  script:
    - echo "Hello Python"
    - python --version
```

#### 변수 {#variables}

GitLab에서는 `variables` 키워드를 사용하여 [CI/CD 변수](../variables/_index.md)를 정의합니다. 변수를 사용하여 구성 데이터를 재사용하거나, 더 동적인 구성을 가지거나, 중요한 값을 저장합니다. 변수는 전역적으로 또는 작업당 정의할 수 있습니다.

예를 들어 `Jenkinsfile`에서:

```groovy
pipeline {
    agent any
    environment {
        NAME = 'Fern'
    }
    stages {
        stage('English') {
            environment {
                GREETING = 'Hello'
            }
            steps {
                sh 'echo "$GREETING $NAME"'
            }
        }
        stage('Spanish') {
            environment {
                GREETING = 'Hola'
            }
            steps {
                sh 'echo "$GREETING $NAME"'
            }
        }
    }
}
```

이 예에서는 변수를 사용하여 작업의 명령에 값을 전달하는 방법을 보여줍니다.

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
default:
  image: alpine:latest

stages:
  - greet

variables:
  NAME: "Fern"

english:
  stage: greet
  variables:
    GREETING: "Hello"
  script:
    - echo "$GREETING $NAME"

spanish:
  stage: greet
  variables:
    GREETING: "Hola"
  script:
    - echo "$GREETING $NAME"
```

변수는 또한 [GitLab UI의 CI/CD 설정에서 설정](../variables/_index.md#define-a-cicd-variable-in-the-ui)할 수 있습니다. 경우에 따라 [보호된](../variables/_index.md#protect-a-cicd-variable) 변수 및 [마스킹된](../variables/_index.md#mask-a-cicd-variable) 변수를 사용하여 시크릿 값을 저장할 수 있습니다. 이러한 변수는 구성 파일에 정의된 변수와 동일한 방식으로 파이프라인 작업에서 접근할 수 있습니다.

예를 들어 `Jenkinsfile`에서:

```groovy
pipeline {
    agent any
    stages {
        stage('Example Username/Password') {
            environment {
                AWS_ACCESS_KEY = credentials('aws-access-key')
            }
            steps {
                sh 'my-login-script.sh $AWS_ACCESS_KEY'
            }
        }
    }
}
```

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
login-job:
  script:
    - my-login-script.sh $AWS_ACCESS_KEY
```

또한 GitLab CI/CD는 [미리 정의된 변수](../variables/predefined_variables.md)를 모든 파이프라인 및 작업에 제공하며, 이는 파이프라인 및 리포지토리와 관련된 값을 포함합니다.

#### 표현 및 조건 {#expressions-and-conditionals}

새 파이프라인이 시작되면 GitLab은 해당 파이프라인에서 실행해야 하는 작업을 확인합니다. 변수의 상태 또는 파이프라인 유형과 같은 요소에 따라 작업이 실행되도록 구성할 수 있습니다.

예를 들어 `Jenkinsfile`에서:

```groovy
stage('deploy_staging') {
    agent { docker 'alpine:latest' }
    when {
        branch 'staging'
    }
    steps {
        echo "Deploying to staging"
    }
}
```

이 예에서는 작업이 브랜치가 `staging`로 명명되었을 때만 실행됩니다.

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

Jenkins 에이전트와 마찬가지로 GitLab 러너는 작업을 실행하는 호스트입니다. GitLab.com을 사용하는 경우 [인스턴스 러너 플릿](../runners/_index.md)을 사용하여 자신의 러너를 프로비저닝하지 않고 작업을 실행할 수 있습니다.

Jenkins 에이전트를 GitLab CI/CD용으로 변환하려면 에이전트를 제거한 다음 [러너를 설치 및 등록](../runners/_index.md)합니다. 러너는 많은 오버헤드를 필요로 하지 않으므로, 사용 중이던 Jenkins 에이전트와 유사한 프로비저닝을 사용할 수 있을 것입니다.

러너에 대한 몇 가지 주요 세부 사항:

- 러너는 인스턴스 전체에서 공유되거나, 그룹에서 공유되거나, 단일 프로젝트에만 사용되도록 [구성](../runners/runners_scope.md)할 수 있습니다.
- [`tags` 키워드](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)를 사용하여 더 세밀한 제어를 수행할 수 있으며, 러너를 특정 작업과 연결할 수 있습니다. 예를 들어, 태그를 사용하여 전용 또는 더 강력하거나 특정 하드웨어가 필요한 작업에 대한 태그를 사용할 수 있습니다.
- GitLab은 [러너에 대한 자동 크기 조정](https://docs.gitlab.com/runner/configuration/autoscale/)을 제공합니다. 자동 크기 조정을 사용하여 필요할 때만 러너를 프로비저닝하고 필요하지 않을 때 축소합니다.

예를 들어 `Jenkinsfile`에서:

```groovy
pipeline {
    agent none
    stages {
        stage('Linux') {
            agent {
                label 'linux'
            }
            steps {
                echo "Hello, $USER"
            }
        }
        stage('Windows') {
            agent {
                label 'windows'
            }
            steps {
                echo "Hello, %USERNAME%"
            }
        }
    }
}
```

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
linux_job:
  stage: build
  tags:
    - linux
  script:
    - echo "Hello, $USER"

windows_job:
  stage: build
  tags:
    - windows
  script:
    - echo "Hello, %USERNAME%"
```

#### 아티팩트 {#artifacts}

GitLab에서는 모든 작업이 [`artifacts`](../yaml/_index.md#artifacts) 키워드를 사용하여 작업이 완료될 때 저장할 아티팩트 세트를 정의할 수 있습니다. [아티팩트](../jobs/job_artifacts.md)는 나중의 작업(예: 테스트 또는 배포용)에서 사용할 수 있는 파일입니다.

예를 들어 `Jenkinsfile`에서:

```groovy
stages {
    stage('Generate Cat') {
        steps {
            sh 'touch cat.txt'
            sh 'echo "meow" > cat.txt'
        }
        post {
            always {
                archiveArtifacts artifacts: 'cat.txt'
                onlyIfSuccessful: true
            }
        }
    }
    stage('Use Cat') {
        steps {
            sh 'cat cat.txt'
        }
    }
  }
```

동등한 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
stages:
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
  artifacts:
    paths:
      - cat.txt
```

#### 캐싱 {#caching}

[캐시](../caching/_index.md)는 작업이 하나 이상의 파일을 다운로드하고 나중에 더 빠른 액세스를 위해 저장할 때 생성됩니다. 동일한 캐시를 사용하는 후속 작업은 파일을 다시 다운로드할 필요가 없으므로 더 빠르게 실행됩니다. 캐시는 러너에 저장되며 [분산 캐시가 활성화된](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching) 경우 S3에 업로드됩니다. Jenkins 핵심은 캐싱을 제공하지 않습니다.

예를 들어 `.gitlab-ci.yml` 파일에서:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

### Jenkins 플러그인 {#jenkins-plugins}

Jenkins에서 플러그인을 통해 활성화되는 일부 기능은 GitLab에서 유사한 기능을 제공하는 키워드 및 기능으로 기본 지원됩니다. 예를 들어:

| Jenkins 플러그인                                                                    | GitLab 기능 |
|-----------------------------------------------------------------------------------|----------------|
| [Build Timeout](https://plugins.jenkins.io/build-timeout/)                        | [`timeout` 키워드](../yaml/_index.md#timeout) |
| [Cobertura](https://plugins.jenkins.io/cobertura/)                                | [코드 커버리지 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscoverage_report) 및 [코드 커버리지](../testing/code_coverage/_index.md) |
| [코드 커버리지 API](https://plugins.jenkins.io/code-coverage-api/)                | [코드 커버리지](../testing/code_coverage/_index.md) 및 [코드 커버리지 시각화](../testing/code_coverage/_index.md#coverage-visualization) |
| [Embeddable Build Status](https://plugins.jenkins.io/embeddable-build-status/)    | [파이프라인 상태 배지](../../user/project/badges.md#pipeline-status-badges) |
| [JUnit](https://plugins.jenkins.io/junit/)                                        | [JUnit 테스트 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportsjunit) 및 [단위 테스트 리포트](../testing/unit_test_reports.md) |
| [Mailer](https://plugins.jenkins.io/mailer/)                                      | [알림 이메일](../../user/profile/notifications.md) |
| [Parameterized Trigger Plugin](https://plugins.jenkins.io/parameterized-trigger/) | [`trigger` 키워드](../yaml/_index.md#trigger) 및 [다운스트림 파이프라인](../pipelines/downstream_pipelines.md) |
| [Role-based Authorization Strategy](https://plugins.jenkins.io/role-strategy/)    | GitLab [권한 및 역할](../../user/permissions.md) |
| [Timestamper](https://plugins.jenkins.io/timestamper/)                            | [작업](../jobs/_index.md) 로그는 기본적으로 타임스탬프됩니다. |

### 보안 스캔 기능 {#security-scanning-features}

Jenkins에서 코드 품질, 보안 또는 정적 응용 프로그램 스캔 같은 플러그인을 사용했을 수 있습니다. GitLab은 [보안 스캐너](../../user/application_security/_index.md)를 기본으로 제공하여 SDLC의 모든 부분에서 취약점을 감지합니다. GitLab에서 템플릿을 사용하여 이러한 플러그인을 추가할 수 있으며, 예를 들어 파이프라인에 SAST 스캔을 추가하려면 다음을 `.gitlab-ci.yml`에 추가합니다:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

CI/CD 변수를 사용하여 보안 스캐너의 동작을 사용자 지정할 수 있습니다(예: [SAST 스캐너](../../user/application_security/sast/_index.md#available-cicd-variables)).

### 시크릿 관리 {#secrets-management}

"시크릿"이라고 불리는 권한이 있는 정보는 CI/CD 워크플로우에서 필요한 민감한 정보 또는 자격 증명입니다. 시크릿을 사용하여 도구, 응용 프로그램, 컨테이너 및 클라우드 네이티브 환경에서 보호된 리소스 또는 민감한 정보의 잠금을 해제할 수 있습니다.

Jenkins에서의 시크릿 관리는 일반적으로 `Secret` 타입 필드 또는 자격 증명 플러그인으로 처리됩니다. Jenkins 설정에 저장된 자격 증명은 자격 증명 바인딩 플러그인을 사용하여 환경 변수로 작업에 노출될 수 있습니다.

GitLab에서 시크릿 관리를 위해 외부 서비스에 대한 [지원되는 통합](../secrets/_index.md)중 하나를 사용할 수 있습니다. 이러한 서비스는 GitLab 프로젝트 외부에서 시크릿을 안전하게 저장하지만, 해당 서비스에 대한 구독이 필요합니다.

GitLab은 또한 OIDC를 지원하는 다른 타사 서비스에 대한 [OIDC 인증](../secrets/id_token_authentication.md)을 지원합니다.

또한 CI/CD 변수에 자격 증명을 저장하여 작업에서 사용 가능하게 할 수 있지만, 일반 텍스트로 저장된 시크릿은 실수로 노출될 수 있습니다([Jenkins와 동일](https://www.jenkins.io/doc/developer/security/secrets/#storing-secrets)). 항상 [마스킹된](../variables/_index.md#mask-a-cicd-variable) 및 [보호된](../variables/_index.md#protect-a-cicd-variable) 변수에 민감한 정보를 저장해야 하며, 이는 일부 위험을 완화합니다.

`.gitlab-ci.yml` 파일에서 시크릿을 변수로 저장하지 마세요. 이 파일은 프로젝트에 액세스할 수 있는 모든 사용자에게 공개됩니다. 민감한 정보를 변수에 저장하는 것은 [프로젝트, 그룹 또는 인스턴스 설정](../variables/_index.md#define-a-cicd-variable-in-the-ui)에서만 수행해야 합니다.

CI/CD 변수의 안전성을 개선하려면 [보안 지침](../variables/_index.md#cicd-variable-security)을 검토하세요.

## 마이그레이션 계획 및 수행 {#planning-and-performing-a-migration}

다음 권장 단계 목록은 이 마이그레이션을 빠르게 완료할 수 있었던 조직을 관찰한 후에 생성되었습니다.

### 마이그레이션 계획 만들기 {#create-a-migration-plan}

마이그레이션을 시작하기 전에 마이그레이션 준비를 위해 [마이그레이션 계획](plan_a_migration.md)을 만들어야 합니다. Jenkins에서의 마이그레이션을 위해 준비할 때 다음 질문을 자문해보세요:

- 현재 Jenkins의 작업에서 사용하는 플러그인은 무엇입니까?
  - 이러한 플러그인이 정확히 무엇을 하는지 알고 있습니까?
  - 플러그인이 일반적인 빌드 도구를 래핑합니까? 예를 들어 Maven, Gradle 또는 NPM?
- Jenkins 에이전트에는 무엇이 설치되어 있습니까?
- 사용 중인 공유 라이브러리가 있습니까?
- Jenkins에서 인증하는 방식은 무엇입니까? SSH 키, API 토큰 또는 다른 시크릿을 사용 중입니까?
- 파이프라인에서 액세스해야 하는 다른 프로젝트가 있습니까?
- 외부 서비스에 액세스하기 위해 Jenkins의 자격 증명이 있습니까? 예를 들어 Ansible Tower, Artifactory 또는 기타 클라우드 공급자 또는 배포 대상?

### 전제 조건 {#prerequisites}

마이그레이션 작업을 수행하기 전에 먼저 다음을 수행해야 합니다:

1. GitLab에 익숙해집니다.
   - [주요 GitLab CI/CD 기능](../_index.md)에 대해 읽어보세요.
   - 정적 사이트를 빌드, 테스트 및 배포하는 [첫 번째 GitLab 파이프라인](../quick_start/_index.md) 및 [더 복잡한 파이프라인](../quick_start/tutorial.md)을 만드는 튜토리얼을 따르세요.
   - [CI/CD YAML 구문 참조](../yaml/_index.md)를 검토합니다.
1. GitLab을 설정하고 구성합니다.
1. GitLab 인스턴스를 테스트합니다.
   - [러너](../runners/_index.md)가 사용 가능한지 확인합니다. GitLab.com 공유 러너를 사용하거나 새 러너를 설치합니다.

### 마이그레이션 단계 {#migration-steps}

1. SCM 솔루션에서 GitLab으로 프로젝트를 마이그레이션합니다.
   - (권장됨) [가져오기](../../user/import/_index.md)를 사용하여 외부 SCM 공급자의 대량 가져오기를 자동화할 수 있습니다.
   - [URL로 리포지토리를 가져올](../../user/import/third_party_systems/repo_by_url.md) 수 있습니다.
1. 각 프로젝트에 `.gitlab-ci.yml` 파일을 만듭니다.
1. Jenkins 구성을 GitLab CI/CD 작업으로 마이그레이션하고 머지 리퀘스트에 직접 결과를 표시하도록 구성합니다.
1. [클라우드 배포 템플릿](../cloud_deployment/_index.md), [환경](../environments/_index.md) 및 [Kubernetes용 GitLab 에이전트](../../user/clusters/agent/_index.md)를 사용하여 배포 작업을 마이그레이션합니다.
1. CI/CD 구성을 다양한 프로젝트 간에 재사용할 수 있는지 확인한 다음 CI/CD 템플릿을 만들고 공유합니다.
1. GitLab CI/CD 파이프라인을 더 빠르고 효율적으로 만드는 방법을 학습하려면 [파이프라인 효율성 문서](../pipelines/pipeline_efficiency.md)를 확인합니다.

### 추가 리소스 {#additional-resources}

- 플러그인을 포함하여 GitLab CI/CD 작업 내에서 완전한 Jenkins 인스턴스를 실행하려면 [JenkinsFile Wrapper](https://gitlab.com/gitlab-org/jfr-container-builder/)를 사용할 수 있습니다. 덜 긴급한 파이프라인의 마이그레이션을 지연하여 GitLab CI/CD로의 전환을 용이하게 하려면 이 도구를 사용합니다.

  > [!note]
  > JenkinsFile Wrapper는 GitLab과 함께 패키징되지 않으며 지원 범위를 벗어납니다. 자세한 내용은 [지원 명세서](https://about.gitlab.com/support/statement-of-support/)를 참고하세요.

여기에서 답하지 않은 질문이 있는 경우 [GitLab 커뮤니티 포럼](https://forum.gitlab.com/)이 훌륭한 리소스가 될 수 있습니다.
