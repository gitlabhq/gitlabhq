---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: TeamCity에서 마이그레이션
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

TeamCity에서 GitLab CI/CD로 마이그레이션하는 경우, TeamCity 워크플로우를 복제하고 향상시키는 CI/CD 파이프라인을 만들 수 있습니다.

## 주요 유사점 및 차이점 {#key-similarities-and-differences}

GitLab CI/CD와 TeamCity는 몇 가지 유사점이 있는 CI/CD 도구입니다. GitLab과 TeamCity는 모두 다음과 같습니다:

- 대부분의 언어에 대해 작업을 실행할 수 있을 만큼 충분히 유연합니다.
- 온프레미스 또는 클라우드에 배포될 수 있습니다.

또한 두 서비스 간에 몇 가지 중요한 차이점이 있습니다:

- GitLab CI/CD 파이프라인은 YAML 형식 구성 파일에서 구성되며, 수동으로 또는 [파이프라인 편집기](../pipeline_editor/_index.md)를 사용하여 편집할 수 있습니다. TeamCity 파이프라인은 UI에서 또는 Kotlin DSL을 사용하여 구성할 수 있습니다.
- GitLab은 기본 제공 SCM, 컨테이너 레지스트리, 보안 스캔 등이 포함된 DevSecOps 플랫폼입니다. TeamCity는 이러한 기능에 대해 별도의 솔루션이 필요하며, 일반적으로 통합으로 제공됩니다.

### 구성 파일 {#configuration-file}

TeamCity는 [UI에서 구성](https://www.jetbrains.com/help/teamcity/creating-and-editing-build-configurations.html)하거나 [`Teamcity Configuration` 파일을 Kotlin DSL 형식으로](https://www.jetbrains.com/help/teamcity/kotlin-dsl.html) 구성할 수 있습니다. TeamCity 빌드 구성은 소프트웨어 프로젝트를 빌드, 테스트 및 배포하는 방법을 정의하는 지시 집합입니다. 구성에는 TeamCity에서 CI/CD 프로세스를 자동화하는 데 필요한 매개변수 및 설정이 포함되어 있습니다.

GitLab에서 TeamCity 빌드 구성에 해당하는 것은 `.gitlab-ci.yml` 파일입니다. 이 파일은 프로젝트의 CI/CD 파이프라인을 정의하고, 프로젝트를 빌드, 테스트 및 배포하는 데 필요한 스테이지, 작업 및 명령을 지정합니다.

## 기능 및 개념 비교 {#comparison-of-features-and-concepts}

많은 TeamCity 기능 및 개념은 동일한 기능을 제공하는 GitLab의 동등한 기능이 있습니다.

### 작업 {#jobs}

TeamCity는 코드 컴파일, 테스트 실행, 아티팩트 패킹 등의 작업을 실행하는 명령 또는 스크립트를 정의하는 여러 빌드 단계로 구성된 빌드 구성을 사용합니다.

다음은 Docker 파일을 빌드하고 단위 테스트를 실행하는 Kotlin DSL 형식의 TeamCity 프로젝트 구성 예입니다:

```kotlin
package _Self.buildTypes

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.nodeJS
import jetbrains.buildServer.configs.kotlin.triggers.vcs

object BuildTest : BuildType({
    name = "Build & Test"

    vcs {
        root(HttpsGitlabComRutshahCicdDemoGitRefsHeadsMain)
    }

    steps {
        dockerCommand {
            id = "DockerCommand"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
            }
        }
        nodeJS {
            id = "nodejs_runner"
            workingDir = "app"
            shellScript = """
                npm install jest-teamcity --no-save
                npm run test -- --reporters=jest-teamcity
            """.trimIndent()
        }
    }

    triggers {
        vcs {
        }
    }

    features {
        perfmon {
        }
    }
})
```

GitLab CI/CD에서는 파이프라인의 일부로 실행할 작업으로 작업을 정의합니다. 각 작업은 하나 이상의 빌드 단계가 정의되어 있을 수 있습니다.

이전 예에 해당하는 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH != "main" || $CI_PIPELINE_SOURCE != "merge_request_event"
      when: never
    - when: always

stages:
  - build
  - test

build-job:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  script:
    - docker build -t cicd-demo:0.1 .

run_unit_tests:
  image: node:17-alpine3.14
  stage: test
  before_script:
    - cd app
    - npm install
  script:
    - npm test
  artifacts:
    when: always
    reports:
      junit: app/junit.xml
```

### 파이프라인 트리거 {#pipeline-triggers}

[TeamCity 트리거](https://www.jetbrains.com/help/teamcity/configuring-build-triggers.html)는 VCS 변경, 예약된 트리거 또는 다른 빌드에서 트리거된 빌드를 포함하여 빌드를 시작하는 조건을 정의합니다.

GitLab CI/CD에서는 브랜치 변경 또는 머지 리퀘스트 및 새 태그와 같은 다양한 이벤트에 대해 파이프라인을 자동으로 트리거할 수 있습니다. 파이프라인은 수동으로 [API](../triggers/_index.md)를 사용하거나 [예약된 파이프라인](../pipelines/schedules.md)으로 트리거될 수도 있습니다. 자세한 내용은 [CI/CD 파이프라인](../pipelines/_index.md)을 참조하세요.

### 변수 {#variables}

TeamCity에서는 빌드 구성 설정에서 [빌드 매개변수 및 환경 변수를 정의](https://www.jetbrains.com/help/teamcity/using-build-parameters.html)합니다.

GitLab에서는 `variables` 키워드를 사용하여 [CI/CD 변수](../variables/_index.md)를 정의합니다. 변수를 사용하여 구성 데이터를 재사용하거나, 더욱 동적인 구성을 갖거나, 중요한 값을 저장할 수 있습니다. 변수는 전역적으로 또는 작업별로 정의할 수 있습니다.

예를 들어, 변수를 사용하는 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

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

### 아티팩트 {#artifacts}

TeamCity의 빌드 구성을 통해 빌드 프로세스 중에 생성된 [아티팩트](https://www.jetbrains.com/help/teamcity/build-artifact.html)를 정의할 수 있습니다.

GitLab에서는 모든 작업이 [`artifacts`](../yaml/_index.md#artifacts) 키워드를 사용하여 작업이 완료될 때 저장할 아티팩트 집합을 정의할 수 있습니다. [아티팩트](../jobs/job_artifacts.md)는 테스트 또는 배포를 위해 나중의 작업에서 사용할 수 있는 파일입니다.

예를 들어, 아티팩트를 사용하는 GitLab CI/CD `.gitlab-ci.yml` 파일은 다음과 같습니다:

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

### 러너 {#runners}

GitLab에서 [TeamCity 에이전트](https://www.jetbrains.com/help/teamcity/build-agent.html)에 해당하는 것은 러너입니다.

GitLab CI/CD에서 러너는 작업을 실행하는 서비스입니다. GitLab.com을 사용하는 경우, [인스턴스 러너 플릿](../runners/_index.md)을 사용하여 자체 관리 러너를 프로비저닝하지 않고도 작업을 실행할 수 있습니다.

러너에 대한 몇 가지 주요 세부 정보:

- 러너는 [구성](../runners/runners_scope.md)되어 인스턴스, 그룹 또는 단일 프로젝트 전체에서 공유될 수 있습니다.
- [`tags` 키워드](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)를 사용하여 더 세밀한 제어를 수행하고 러너를 특정 작업과 연결할 수 있습니다. 예를 들어, 전용, 더 강력하거나 특정 하드웨어가 필요한 작업에 대해 태그를 사용할 수 있습니다.
- GitLab은 [러너에 대한 자동 크기 조정](https://docs.gitlab.com/runner/runner_autoscale/)을 가지고 있습니다. 필요할 때만 러너를 프로비저닝하고 필요하지 않을 때 축소하려면 자동 크기 조정을 사용하세요.

### TeamCity 빌드 기능 및 플러그인 {#teamcity-build-features--plugins}

빌드 기능 및 플러그인을 통해 활성화되는 TeamCity의 일부 기능은 GitLab CI/CD에서 CI/CD 키워드 및 기능으로 기본적으로 지원됩니다.

| TeamCity 플러그인                                                                                                                    | GitLab 기능 |
|------------------------------------------------------------------------------------------------------------------------------------|----------------|
| [코드 커버리지](https://www.jetbrains.com/help/teamcity/configuring-test-reports-and-code-coverage.html#Code+Coverage+in+TeamCity) | [코드 커버리지](../testing/code_coverage/_index.md) 및 [테스트 커버리지 시각화](../testing/code_coverage/_index.md#coverage-visualization) |
| [단위 테스트 보고서](https://www.jetbrains.com/help/teamcity/configuring-test-reports-and-code-coverage.html)                        | [JUnit 테스트 보고서 아티팩트](../yaml/artifacts_reports.md#artifactsreportsjunit) 및 [단위 테스트 보고서](../testing/unit_test_reports.md) |
| [알림](https://www.jetbrains.com/help/teamcity/configuring-notifications.html)                                            | [알림 이메일](../../user/profile/notifications.md) 및 [Slack](../../user/project/integrations/gitlab_slack_application.md) |

## 마이그레이션 계획 및 수행 {#planning-and-performing-a-migration}

다음 권장 단계 목록은 GitLab CI/CD로의 마이그레이션을 빠르게 완료할 수 있었던 조직을 관찰한 후 작성되었습니다.

### 마이그레이션 계획 작성 {#create-a-migration-plan}

마이그레이션을 시작하기 전에 마이그레이션 준비를 위해 [마이그레이션 계획](plan_a_migration.md)을 수립해야 합니다.

TeamCity에서 마이그레이션하는 경우 준비 시 다음 질문을 스스로에게 물어봅니다:

- 현재 TeamCity의 작업에서 어떤 플러그인을 사용하고 있습니까?
  - 이 플러그인이 정확히 무엇을 하는지 알고 있습니까?
- TeamCity 에이전트에 무엇이 설치되어 있습니까?
- 사용 중인 공유 라이브러리가 있습니까?
- TeamCity에서 어떻게 인증하고 있습니까? SSH 키, API 토큰 또는 기타 암호를 사용하고 있습니까?
- 파이프라인에서 액세스해야 하는 다른 프로젝트가 있습니까?
- 외부 서비스에 액세스하기 위해 TeamCity에 자격 증명이 있습니까? 예를 들어 Ansible Tower, Artifactory 또는 기타 클라우드 공급자 또는 배포 대상?

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

1. SCM 솔루션에서 GitLab으로 프로젝트를 마이그레이션합니다.
   - (권장) [사용 가능한 임포터](../../user/import/_index.md)를 사용하여 외부 SCM 공급자에서 대량 가져오기를 자동화할 수 있습니다.
   - [URL로 리포지토리 가져오기](../../user/import/third_party_systems/repo_by_url.md)를 수행할 수 있습니다.
1. 각 프로젝트에 `.gitlab-ci.yml` 파일을 만듭니다.
1. TeamCity 구성을 GitLab CI/CD 작업으로 마이그레이션하고 머지 리퀘스트에 결과를 직접 표시하도록 구성합니다.
1. [클라우드 배포 템플릿](../cloud_deployment/_index.md), [환경](../environments/_index.md) 및 [Kubernetes용 GitLab 에이전트](../../user/clusters/agent/_index.md)를 사용하여 배포 작업을 마이그레이션합니다.
1. 다양한 프로젝트 간에 재사용할 수 있는 CI/CD 구성이 있는지 확인한 후 [CI/CD 구성 요소](../components/_index.md)를 만들고 공유합니다.
1. [파이프라인 효율성](../pipelines/pipeline_efficiency.md)을 참조하여 GitLab CI/CD 파이프라인을 더 빠르고 효율적으로 만드는 방법을 알아봅니다.

여기서 답변하지 않은 질문이 있으면 [GitLab 커뮤니티 포럼](https://forum.gitlab.com/)이 좋은 리소스가 될 수 있습니다.
