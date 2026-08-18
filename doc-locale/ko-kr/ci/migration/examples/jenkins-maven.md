---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jenkins에서 GitLab CI/CD로 Maven 빌드 마이그레이션
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Jenkins에 Maven 빌드가 있는 경우 [Java Spring](https://gitlab.com/gitlab-org/project-templates/spring) 프로젝트 템플릿을 사용하여 GitLab으로 마이그레이션할 수 있습니다. 이 템플릿은 기본 종속성 관리를 위해 Maven을 사용합니다.

## Sample Jenkins 구성 {#sample-jenkins-configurations}

다음 세 가지 Jenkins 예제는 각각 Maven 프로젝트를 테스트, 빌드 및 셸 에이전트에 설치하는 다양한 방법을 사용합니다:

- 셸 실행을 사용한 Freestyle
- Maven 작업 플러그인을 사용한 Freestyle
- Jenkinsfile을 사용한 선언적 파이프라인

세 가지 예제 모두 세 가지 다른 스테이지에서 동일한 세 가지 명령을 순서대로 실행합니다:

- `mvn test`: 코드베이스에서 찾은 테스트를 실행합니다.
- `mvn package -DskipTests`: 코드를 POM에 정의된 실행 가능한 유형으로 컴파일하고 첫 번째 스테이지에서 이미 완료되었으므로 테스트 실행을 건너뜁니다.
- `mvn install -DskipTests`: 컴파일된 실행 파일을 에이전트의 로컬 Maven `.m2` 리포지토리에 설치하고 다시 테스트 실행을 건너뜁니다.

이 예제는 에이전트에 Maven이 사전 설치되어 있어야 하는 단일의 지속적인 Jenkins 에이전트를 사용합니다. 이 실행 방법은 [shell executor](https://docs.gitlab.com/runner/executors/shell/)를 사용하는 러너와 유사합니다.

### 셸 실행을 사용한 Freestyle {#freestyle-with-shell-execution}

Jenkins의 기본 제공 셸 실행 옵션을 사용하여 에이전트의 셸에서 `mvn` 명령을 직접 호출하는 경우 구성은 다음과 같을 수 있습니다:

![Maven 명령이 셸 명령으로 정의된 빌드 단계를 보여주는 Jenkins UI입니다.](img/maven-freestyle-shell_v16_4.png)

### Maven 작업 플러그인을 사용한 Freestyle {#freestyle-with-maven-task-plugin}

Jenkins의 Maven 플러그인을 사용하여 [Maven 빌드 수명 주기](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html)에서 특정 목표를 선언하고 실행하는 경우 구성은 다음과 같을 수 있습니다:

![Maven 플러그인을 사용하여 정의된 Maven 명령이 있는 빌드 단계를 보여주는 Jenkins UI입니다.](img/maven-freestyle-plugin_v16_4.png)

이 플러그인은 Jenkins 에이전트에 Maven이 설치되어 있어야 하며 Maven 명령을 호출하기 위해 스크립트 래퍼를 사용합니다.

### 선언적 파이프라인 사용 {#using-a-declarative-pipeline}

선언적 파이프라인을 사용하는 경우 구성은 다음과 같을 수 있습니다:

```groovy
pipeline {
    agent any
    tools {
        maven 'maven-3.6.3'
        jdk 'jdk11'
    }
    stages {
        stage('Build') {
            steps {
                sh "mvn package -DskipTests"
            }
        }
        stage('Test') {
            steps {
                sh "mvn test"
            }
        }
        stage('Install') {
            steps {
                sh "mvn install -DskipTests"
            }
        }
    }
}
```

이 예제는 플러그인 대신 셸 실행 명령을 사용합니다.

기본적으로 선언적 파이프라인 구성은 Jenkins 파이프라인 구성에 저장되거나 `Jenksinfile` 의 Git 리포지토리에 직접 저장됩니다.

## Jenkins 구성을 GitLab CI/CD로 변환 {#convert-jenkins-configuration-to-gitlab-cicd}

이전 예제는 모두 약간 다르지만 모두 동일한 파이프라인 구성으로 GitLab CI/CD로 마이그레이션할 수 있습니다.

전제 조건:

- Shell executor가 있는 GitLab Runner
- 셸 runner에 설치된 Maven 3.6.3 및 Java 11 JDK

이 예제는 Jenkins에서 빌드, 테스트 및 설치의 동작과 구문을 모방합니다.

GitLab CI/CD 파이프라인에서 명령은 "작업"으로 실행되며, 이는 스테이지로 그룹화됩니다. `.gitlab-ci.yml` 구성 파일의 마이그레이션된 구성은 두 개의 전역 키워드(`stages` 및 `variables`)와 3개의 작업으로 구성됩니다:

```yaml
stages:
  - build
  - test
  - install

variables:
  MAVEN_OPTS: >-
    -Dhttps.protocols=TLSv1.2
    -Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository
  MAVEN_CLI_OPTS: >-
    -DskipTests

build-JAR:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS package

test-code:
  stage: test
  script:
    - mvn test

install-JAR:
  stage: install
  script:
    - mvn $MAVEN_CLI_OPTS install
```

이 예에서:

- `stages`은 순서대로 실행되는 세 개의 스테이지를 정의합니다. 이전 Jenkins 예제와 마찬가지로 테스트 작업이 먼저 실행되고, 빌드 작업이 따라오고, 마지막으로 설치 작업이 실행됩니다.
- `variables`은 모든 작업에서 사용할 수 있는 [CI/CD 변수](../../variables/_index.md)를 정의합니다:
  - `MAVEN_OPTS`은 Maven이 실행될 때마다 필요한 Maven 환경 변수입니다:
    - `-Dhttps.protocols=TLSv1.2`은 파이프라인의 모든 HTTP 요청에 대해 TLS 프로토콜을 버전 1.2로 설정합니다.
    - `-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository`은 로컬 Maven 리포지토리의 위치를 GitLab 파이프라인 디렉터리의 runner로 설정하므로 작업이 리포지토리에 액세스하고 수정할 수 있습니다.
  - `MAVEN_CLI_OPTS`은 `mvn` 명령에 추가할 특정 인수입니다:
    - `-DskipTests`은 Maven 빌드 수명 주기의 `test` 스테이지를 건너뜁니다.
- `test-code`, `build-JAR`, 및 `install-JAR`은 파이프라인에서 실행할 작업의 사용자 정의 이름입니다:
  - `stage`은 작업이 실행되는 스테이지를 정의합니다. 파이프라인은 하나 이상의 스테이지를 포함하고 스테이지는 하나 이상의 작업을 포함합니다. 이 예제에는 각각 단일 작업이 있는 세 개의 스테이지가 있습니다.
  - `script`은 해당 작업에서 실행할 명령을 정의하며 `Jenkinsfile`의 `steps`과 유사합니다. 작업은 이미지 컨테이너에서 실행되는 여러 명령을 순서대로 실행할 수 있지만 이 예제에서 작업은 각각 하나의 명령만 실행합니다.

### Docker 컨테이너에서 작업 실행 {#run-jobs-in-docker-containers}

Jenkins 샘플처럼 이 빌드 프로세스를 처리하기 위해 지속적인 머신을 사용하는 대신 이 예제는 임시 Docker 컨테이너를 사용하여 실행을 처리합니다. 컨테이너를 사용하면 가상 머신 유지 관리 및 설치된 Maven 버전의 필요성이 제거됩니다. 또한 파이프라인의 기능을 확장 및 확대할 수 있는 유연성을 높입니다.

전제 조건:

- 프로젝트에서 사용할 수 있는 Docker executor가 있는 GitLab Runner GitLab.com을 사용하는 경우 공개 인스턴스 러너를 사용할 수 있습니다.

이 마이그레이션된 파이프라인 구성은 세 개의 전역 키워드(`stages`, `default`, 및 `variables`)와 3개의 작업으로 구성됩니다. 이 구성은 [이전 예제](#convert-jenkins-configuration-to-gitlab-cicd)와 비교하여 향상된 파이프라인을 위해 추가 GitLab CI/CD 기능을 사용합니다:

```yaml
stages:
  - build
  - test
  - install

default:
  image: maven:3.6.3-openjdk-11
  cache:
    key: $CI_COMMIT_REF_SLUG
    paths:
      - .m2/

variables:
  MAVEN_OPTS: >-
    -Dhttps.protocols=TLSv1.2
    -Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository
  MAVEN_CLI_OPTS: >-
    -DskipTests

build-JAR:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS package

test-code:
  stage: test
  script:
    - mvn test

install-JAR:
  stage: install
  script:
    - mvn $MAVEN_CLI_OPTS install
```

이 예에서:

- `stages`은 순서대로 실행되는 세 개의 스테이지를 정의합니다. 이전 Jenkins 예제와 마찬가지로 테스트 작업이 먼저 실행되고, 빌드 작업이 따라오고, 마지막으로 설치 작업이 실행됩니다.
- `default`은 기본적으로 모든 작업에서 재사용할 표준 구성을 정의합니다:
  - `image`은 사용할 Docker 이미지 컨테이너와 명령을 실행할 위치를 정의합니다. 이 예제에서는 필요한 모든 것이 이미 설치된 공식 Maven Docker 이미지입니다.
  - `cache`은 종속성을 캐시하고 재사용하는 데 사용됩니다:
    - `key`은 특정 캐시 아카이브의 고유 식별자입니다. 이 예제에서는 Git 커밋 ref의 단축된 버전이며 [미리 정의된 CI/CD 변수](../../variables/predefined_variables.md)로 자동 생성됩니다. 동일한 커밋 ref에 대해 실행되는 모든 작업은 동일한 캐시를 재사용합니다.
    - `paths`은 캐시에 포함할 디렉터리 또는 파일입니다. 이 예제는 `.m2/` 디렉터리를 캐시하여 작업 실행 간의 종속성 재설치를 방지합니다.
- `variables`은 모든 작업에서 사용할 수 있는 [CI/CD 변수](../../variables/_index.md)를 정의합니다:
  - `MAVEN_OPTS`은 Maven이 실행될 때마다 필요한 Maven 환경 변수입니다:
    - `-Dhttps.protocols=TLSv1.2`은 파이프라인의 모든 HTTP 요청에 대해 TLS 프로토콜을 버전 1.2로 설정합니다.
    - `-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository`은 로컬 Maven 리포지토리의 위치를 GitLab 파이프라인 디렉터리의 runner로 설정하므로 작업이 리포지토리에 액세스하고 수정할 수 있습니다.
  - `MAVEN_CLI_OPTS`은 `mvn` 명령에 추가할 특정 인수입니다:
    - `-DskipTests`은 Maven 빌드 수명 주기의 `test` 스테이지를 건너뜁니다.
- `test-code`, `build-JAR`, 및 `install-JAR`은 파이프라인에서 실행할 작업의 사용자 정의 이름입니다:
  - `stage`은 작업이 실행되는 스테이지를 정의합니다. 파이프라인은 하나 이상의 스테이지를 포함하고 스테이지는 하나 이상의 작업을 포함합니다. 이 예제에는 각각 단일 작업이 있는 세 개의 스테이지가 있습니다.
  - `script`은 해당 작업에서 실행할 명령을 정의하며 `Jenkinsfile`의 `steps`과 유사합니다. 작업은 이미지 컨테이너에서 실행되는 여러 명령을 순서대로 실행할 수 있지만 이 예제에서 작업은 각각 하나의 명령만 실행합니다.
