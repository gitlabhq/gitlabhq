---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Discovery
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.9에서 [소개됨](https://gitlab.com/groups/gitlab-org/-/epics/9302). API Discovery 기능은 [베타](../../../../policy/development_stages_support.md) 상태입니다.

{{< /history >}}

API Discovery는 애플리케이션을 분석하여 노출하는 웹 API를 설명하는 OpenAPI 문서를 생성합니다. 이 스키마 문서는 [API 보안 테스팅 분석기](../../api_security_testing/_index.md) 또는 [API 퍼징](../../api_fuzzing/_index.md)에서 웹 API의 보안 검사를 수행하는 데 사용할 수 있습니다.

## 지원되는 프레임워크 {#supported-frameworks}

- [Java Spring-Boot](#java-spring-boot)

## API Discovery는 언제 실행되나요? {#when-does-api-discovery-run}

API Discovery는 파이프라인의 독립적인 작업으로 실행됩니다. 생성된 OpenAPI 문서는 작업 아티팩트로 캡처되므로 나중의 스테이지에서 다른 작업에 의해 사용될 수 있습니다.

API Discovery는 기본적으로 `test` 스테이지에서 실행됩니다. `test` 스테이지는 일반적으로 API 보안 테스팅 및 API 퍼징과 같은 다른 보안 기능에서 사용하는 스테이지보다 먼저 실행되므로 선택되었습니다.

## API Discovery 구성 예 {#example-api-discovery-configurations}

다음 프로젝트들이 API Discovery를 시연합니다:

- [예제 Java Spring Boot v2 Pet Store](https://gitlab.com/gitlab-org/security-products/demos/api-discovery/java-spring-boot-v2-petstore)

## Java Spring-Boot {#java-spring-boot}

[Spring Boot](https://spring.io/projects/spring-boot/)는 독립형 프로덕션 급 Spring 기반 애플리케이션을 생성하기 위한 인기 있는 프레임워크입니다.

### 지원되는 애플리케이션 {#supported-applications}

- Spring Boot: v2.X (>= 2.1)
- Java:  11, 17 (LTS 버전)
- 실행 가능한 JAR

API Discovery는 Spring Boot 주 버전 2, 부 버전 1 이상을 지원합니다. 2.0.X 버전은 API Discovery에 영향을 미치는 알려진 버그로 인해 지원되지 않으며, 이는 2.1에서 수정되었습니다.

주 버전 3은 향후 지원될 예정입니다. 주 버전 1 지원은 계획되지 않았습니다.

API Discovery는 Java 런타임의 LTS 버전을 사용하여 테스트되고 공식적으로 지원됩니다. 다른 버전도 작동할 수 있으며, LTS 이외의 버전에서의 버그 보고는 환영합니다.

Spring Boot [실행 가능한 JAR](https://docs.spring.io/spring-boot/redirect.html?page=executable-jar#appendix.executable-jar.nested-jars.jar-structure)로 빌드된 애플리케이션만 지원됩니다.

### 파이프라인 작업으로 구성 {#configure-as-pipeline-job}

API Discovery를 실행하는 가장 쉬운 방법은 CI 템플릿을 기반으로 하는 작업을 통한 파이프라인입니다. 이 방법으로 실행할 때, 필요한 종속성이 설치된 컨테이너 이미지를 제공합니다(예: 적절한 Java 런타임). [이미지 요구사항](#image-requirements)을 참조하세요.

1. [이미지 요구사항](#image-requirements)을 충족하는 컨테이너 이미지가 컨테이너 레지스트리에 업로드됩니다. 컨테이너 레지스트리에 인증이 필요한 경우 [이 도움말 섹션](../../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry)을 참조하세요.
1. `build`스테이지의 작업에서 애플리케이션을 빌드하고 결과 Spring Boot 실행 가능한 JAR을 작업 아티팩트로 구성합니다.
1. `.gitlab-ci.yml` 파일에 API Discovery 템플릿을 포함합니다.

   ```yaml
   include:
      - template: Security/API-Discovery.gitlab-ci.yml
   ```

   단일 `include` 명령문만 `.gitlab-ci.yml` 파일당 허용됩니다. 다른 파일을 포함하는 경우, 이를 단일 `include` 명령문으로 결합합니다.

   ```yaml
   include:
      - template: Security/API-Discovery.gitlab-ci.yml
      - template: Security/DAST-API.gitlab-ci.yml
   ```

1. `.api_discovery_java_spring_boot`에서 확장하는 새로운 작업을 생성합니다. 기본 스테이지는 `test`이며, 이는 선택적으로 모든 값으로 변경될 수 있습니다.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
   ```

1. 작업에 대해 `image`을 구성합니다.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
   ```

1. 애플리케이션에서 필요한 Java 클래스 경로를 제공합니다. 여기에는 2단계의 호환되는 빌드 아티팩트와 추가적인 모든 종속성이 포함됩니다. 이 예제에서 빌드 아티팩트는 `build/libs/spring-boot-app-0.0.0.jar`이며, 필요한 모든 종속성을 포함합니다. 변수 `API_DISCOVERY_JAVA_CLASSPATH`는 클래스 경로를 제공하는 데 사용됩니다.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
   ```

1. 선택사항. API Discovery에서 필요한 종속성이 제공된 이미지에 누락된 경우, `before_script`을 사용하여 추가할 수 있습니다. 이 예제에서, `eclipse-temurin:17-jre-alpine` 컨테이너는 API Discovery에서 필요한 `curl`을 포함하지 않습니다. 종속성은 Debian 패키지 관리자 `apt`를 사용하여 설치할 수 있습니다:

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
       before_script:
           - apk add --no-cache curl
   ```

1. 선택사항. 제공된 이미지가 `JAVA_HOME` 환경 변수를 자동으로 설정하지 않거나 경로에 `java`를 포함하지 않는 경우, `API_DISCOVERY_JAVA_HOME` 변수를 사용할 수 있습니다.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
           API_DISCOVERY_JAVA_HOME: /opt/java
   ```

1. 선택사항. `API_DISCOVERY_PACKAGES`의 패키지 레지스트리가 공개가 아닌 경우, `API_DISCOVERY_PACKAGE_TOKEN` 변수를 사용하여 GitLab API 및 레지스트리에 읽기 액세스 권한이 있는 토큰을 제공합니다. `gitlab.com`을 사용 중이고 `API_DISCOVERY_PACKAGES` 변수를 사용자 지정하지 않은 경우에는 이것이 필요하지 않습니다. 다음 예제는 토큰을 저장하기 위해 `GITLAB_READ_TOKEN` 이름의 [사용자 지정 CI/CD 변수](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)를 사용합니다.

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
           API_DISCOVERY_PACKAGE_TOKEN: $GITLAB_READ_TOKEN
   ```

API Discovery 작업이 성공적으로 실행된 후, OpenAPI 문서는 `gl-api-discovery-openapi.json`이라는 작업 아티팩트로 사용 가능합니다.

#### 이미지 요구사항 {#image-requirements}

- Linux 컨테이너 이미지.
- Java 버전 11 또는 17이 공식적으로 지원되지만, 다른 버전도 호환될 가능성이 있습니다.
- `curl` 명령.
- `/bin/sh`의 셸(`busybox`, `sh`, 또는 `bash` 등).

### 사용 가능한 CI/CD 변수 {#available-cicd-variables}

| CI/CD 변수                              | 설명        |
|---------------------------------------------|--------------------|
| `API_DISCOVERY_DISABLED`                    | 템플릿 작업 규칙을 사용할 때 API Discovery 작업을 비활성화합니다. |
| `API_DISCOVERY_DISABLED_FOR_DEFAULT_BRANCH` | 템플릿 작업 규칙을 사용할 때 기본 브랜치 파이프라인에 대해 API Discovery 작업을 비활성화합니다. |
| `API_DISCOVERY_JAVA_CLASSPATH`              | 대상 Spring Boot 애플리케이션을 포함하는 Java 클래스 경로. (`build/libs/sample-0.0.0.jar`) |
| `API_DISCOVERY_JAVA_HOME`                   | 제공된 경우 `JAVA_HOME`을 설정하는 데 사용됩니다. |
| `API_DISCOVERY_PACKAGES`                    | GitLab 프로젝트 패키지 API 접두사(기본값 `$CI_API_V4_URL/projects/42503323/packages`). |
| `API_DISCOVERY_PACKAGE_TOKEN`               | GitLab 패키지 API를 호출하기 위한 GitLab 토큰. `API_DISCOVERY_PACKAGES`이 비공개 프로젝트로 설정된 경우에만 필요합니다. |
| `API_DISCOVERY_VERSION`                     | 사용할 API Discovery 버전(`1`이 기본값). 전체 버전 번호 `1.1.0`를 제공하여 버전을 고정하는 데 사용할 수 있습니다. |

## 지원 받기 또는 개선 요청 {#get-support-or-request-an-improvement}

특정 문제에 대한 지원을 받으려면 [도움말 채널](https://about.gitlab.com/get-help/)을 사용합니다.

[GitLab.com의 GitLab 이슈 추적기](https://gitlab.com/gitlab-org/gitlab/-/issues)는 API Discovery에 대한 버그 및 기능 제안을 위한 올바른 위치입니다. API Discovery에 대한 새 이슈를 열 때 `~"Category:API Security"` 레이블을 사용하여 적절한 사람들이 빠르게 검토하도록 합니다.

[이슈 추적기 검색](https://gitlab.com/gitlab-org/gitlab/-/issues)을 통해 유사한 항목이 없는지 먼저 확인한 후 자신의 항목을 제출하세요. 누군가 이미 같은 이슈 또는 기능 제안을 했을 가능성이 있습니다. 이모지 반응으로 지원을 표시하거나 토론에 참여합니다.

예상대로 작동하지 않는 동작이 있을 때, 상황 정보를 제공하는 것을 고려합니다:

- GitLab Self-Managed 인스턴스를 사용하는 경우 GitLab 버전입니다.
- `.gitlab-ci.yml` 작업 정의.
- 전체 작업 콘솔 출력.
- 사용 중인 프레임워크 및 버전(예: "Spring Boot v2.3.2").
- 언어 런타임 및 버전(예: "Eclipse Temurin v17.0.1").

<!-- - Scanner log file is available as a job artifact named `gl-api-discovery.log`. -->

> [!warning]
> **지원 이슈에 첨부된 데이터를 익명화합니다**. 자격 증명, 비밀번호, 토큰, 키 및 보안 암호를 포함한 민감한 정보를 제거합니다.
