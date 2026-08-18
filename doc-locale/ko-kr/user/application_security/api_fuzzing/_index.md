---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 웹 API 퍼즈 테스팅
description: "테스팅, 보안, 취약성, 자동화 및 오류."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

웹 API 퍼즈 테스팅은 예상치 못한 값을 API 작업 매개 변수에 전달하여 백엔드에서 예상치 못한 동작과 오류를 야기합니다. 퍼즈 테스팅을 사용하여 다른 QA 프로세스에서 놓칠 수 있는 버그 및 잠재적 취약성을 발견합니다.

[GitLab Secure](../_index.md) 및 자체 테스트 프로세스의 다른 보안 스캐너와 함께 퍼즈 테스팅을 사용해야 합니다. [GitLab CI/CD](../../../ci/_index.md)를 사용하는 경우 CI/CD 파이프라인의 일부로 퍼즈 테스트를 실행할 수 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [웹 API 퍼징 - 고급 보안 테스팅](https://www.youtube.com/watch?v=oUHsfvLGhDk)을 참조하세요.

## 시작하기 {#getting-started}

CI/CD 구성을 편집하여 API 퍼즈 테스팅을 시작합니다.

전제 조건:

- 지원되는 API 유형 중 하나를 사용하는 웹 API:
  - REST API
  - SOAP
  - GraphQL
  - 양식 본문, JSON 또는 XML
- 다음 형식 중 하나의 API 스펙:
  - OpenAPI v2 또는 v3 스펙
  - GraphQL 스키마
  - HTTP 아카이브(HAR)
  - Postman 컬렉션 v2.0 또는 v2.1
- `docker` 실행기가 있는 사용 가능한 러너가 Linux/amd64에 필요합니다.
- 배포된 대상 애플리케이션.
- `fuzz` 스테이지가 `deploy` 스테이지 이후 CI/CD 파이프라인 정의에 추가됩니다:

  ```yaml
  stages:
    - build
    - test
    - deploy
    - fuzz
  ```

API 퍼즈 테스팅을 사용하려면:

- [웹 API 퍼즈 테스팅 구성 양식](configuration/enabling_the_analyzer.md#web-api-fuzzing-configuration-form)을 사용합니다.

  양식을 사용하면 가장 일반적인 API 퍼즈 테스팅 옵션의 값을 선택하고 GitLab CI/CD 구성에 붙여넣을 수 있는 YAML 스니펫을 생성할 수 있습니다.

## 결과 이해 {#understanding-the-results}

보안 스캔의 출력을 보려면:

1. 상단 바에서 **Search or go to**를 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 파이프라인을 선택합니다.
1. **보안** 탭을 선택합니다.
1. 취약성을 선택하여 다음을 포함한 세부 정보를 봅니다:
   - 상태:  취약성이 심사되었는지 또는 해결되었는지 여부를 나타냅니다.
   - 설명:  취약성의 원인, 잠재적 영향 및 권장 수정 단계를 설명합니다.
   - 심각도:  영향에 따라 6가지 수준으로 분류됩니다. 자세한 내용은 [심각도 수준](../vulnerabilities/severities.md)을 참조하세요.
   - 스캐너:  취약성을 감지한 분석기를 식별합니다.
   - 메서드:  취약한 서버 상호 작용 유형을 설정합니다.
   - URL:  취약성의 위치를 보여줍니다.
   - 증거:  주어진 취약성의 존재를 증명하기 위한 테스트 사례를 설명합니다.
   - 식별자:  취약성을 분류하기 위해 사용되는 참조 목록(예: CWE 식별자).

보안 스캔 결과를 다운로드할 수도 있습니다:

- 파이프라인의 **보안** 탭에서 **결과 다운로드**를 선택합니다.

자세한 내용은 [파이프라인 보안 보고서](../detect/security_scanning_results.md)를 참조하세요.

> [!note]
> 결과물은 기능 브랜치에서 생성됩니다. 결과가 기본 브랜치에 병합되면 취약성이 됩니다. 이 구분은 보안 태세를 평가할 때 중요합니다.

## 최적화 {#optimization}

API 퍼즈 테스팅을 최대한 활용하려면 다음 권장 사항을 따르세요:

- 최신 버전의 분석기를 실행하려면 러너를 `pull_policy: always`를 사용하도록 구성합니다.
- 기본적으로 API 퍼즈 테스팅은 파이프라인의 이전 작업에 의해 정의된 모든 작업 아티팩트를 다운로드합니다. API 퍼즈 테스팅 작업이 테스트 중인 URL을 정의하기 위해 `environment_url.txt`에 의존하지 않거나 이전 작업에서 생성된 다른 파일이 없는 경우 작업 아티팩트를 다운로드하지 않아야 합니다.

  작업 아티팩트 다운로드를 피하려면 분석기 CI/CD 작업을 확장하여 종속성이 없음을 지정합니다. 예를 들어 API 퍼즈 테스팅 분석기의 경우 다음을 `.gitlab-ci.yml` 파일에 추가합니다:

  ```yaml
  apifuzzer_fuzz:
    dependencies: []
  ```

### 애플리케이션 배포 옵션 {#application-deployment-options}

API 퍼즈 테스팅을 위해 배포된 애플리케이션을 스캔할 수 있어야 합니다.

대상 애플리케이션의 복잡성에 따라 API 퍼즈 테스팅 템플릿을 배포하고 구성하는 방법에 대한 몇 가지 옵션이 있습니다.

#### 검토 앱 {#review-apps}

검토 앱은 API 퍼즈 테스팅 대상 애플리케이션을 배포하는 가장 복잡한 방법입니다. 이 프로세스를 지원하기 위해 GitLab은 Google Kubernetes Engine(GKE)을 사용한 검토 앱 배포를 만들었습니다. 이 예제는 [검토 앱 - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke) 이슈 프로젝트에서 찾을 수 있으며 DAST에서 검토 앱을 구성하기 위한 자세한 지침이 있습니다.

#### Docker 서비스 {#docker-services}

애플리케이션이 Docker 컨테이너를 사용하는 경우 API 퍼즈 테스팅으로 배포하고 스캔하는 또 다른 옵션이 있습니다. Docker 빌드 작업이 완료되고 이미지가 컨테이너 레지스트리에 추가된 후 이미지를 서비스로 사용할 수 있습니다.

`.gitlab-ci.yml`에서 서비스 정의를 사용하면 DAST 분석기로 서비스를 스캔할 수 있습니다.

`services` 섹션을 작업에 추가할 때 `alias`는 서비스에 액세스하는 데 사용할 수 있는 호스트 이름을 정의하는 데 사용됩니다. 다음 예제에서 `alias: yourapp` 작업 정의의 `dast` 부분은 배포된 애플리케이션의 URL이 `yourapp`를 호스트 이름으로 사용함을 의미합니다: `https://yourapp/`.

```yaml
stages:
  - build
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

# Deploys the container to the GitLab container registry
deploy:
  services:
  - name: docker:dind
    alias: dind
  image: docker:20.10.16
  stage: build
  script:
    - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
    - docker pull $CI_REGISTRY_IMAGE:latest || true
    - docker build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest

apifuzzer_fuzz:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  FUZZAPI_TARGET_URL: https://yourapp
```

대부분의 애플리케이션은 데이터베이스나 캐싱 서비스와 같은 여러 서비스에 종속됩니다. 기본적으로 서비스 필드에 정의된 서비스는 서로 통신할 수 없습니다. 서비스 간 통신을 허용하려면 `FF_NETWORK_PER_BUILD` 기능 플래그를 활성화합니다.

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```

## 배포 및 확장 {#roll-out}

웹 API 퍼즈 테스팅은 CI/CD 파이프라인의 `fuzz` 스테이지에서 실행됩니다. API 퍼즈 테스팅이 최신 코드를 스캔하도록 하려면 CI/CD 파이프라인이 `fuzz` 스테이지 이전의 스테이지 중 하나에서 변경 사항을 테스트 환경에 배포해야 합니다.

파이프라인이 각 실행마다 동일한 웹 서버에 배포되도록 구성된 경우 다른 파이프라인이 여전히 실행 중인 동안 파이프라인을 실행하면 한 파이프라인이 다른 파이프라인의 코드를 덮어쓰는 경쟁 상태가 발생할 수 있습니다. 스캔할 API는 퍼즈 테스팅 스캔 기간 동안 변경 사항에서 제외되어야 합니다. API에 대한 유일한 변경은 퍼즈 테스팅 스캐너에서 나와야 합니다. 스캔 중에 API에 대한 모든 변경 사항(예: 사용자, 예약된 작업, 데이터베이스 변경, 코드 변경, 다른 파이프라인 또는 다른 스캐너)이 부정확한 결과를 야기할 수 있습니다.

다음 방법을 사용하여 웹 API 퍼즈 테스팅 스캔을 실행할 수 있습니다:

- OpenAPI 스펙(버전 2 및 3)
- GraphQL 스키마
- HTTP 아카이브(HAR)
- Postman 컬렉션(버전 2.0 및 2.1)

### API 퍼즈 테스팅 프로젝트 예제 {#example-api-fuzzing-projects}

- [OpenAPI v2 스펙 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/openapi)
- [HTTP 아카이브(HAR) 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/har)
- [Postman 컬렉션 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/postman-api-fuzzing-example)
- [GraphQL 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/graphql-api-fuzzing-example)
- [SOAP 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/soap-api-fuzzing-example)
- [Selenium을 사용한 인증 토큰](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/auth-token-selenium)

## 지원을 받거나 개선을 요청하세요 {#get-support-or-request-an-improvement}

특정 문제에 대한 지원을 받으려면 [도움말 채널 받기](https://about.gitlab.com/get-help/)를 사용합니다.

[GitLab.com의 GitLab 이슈 트래커](https://gitlab.com/gitlab-org/gitlab/-/issues)는 API 보안 및 API 퍼즈 테스팅에 대한 버그 및 기능 제안을 위한 적절한 장소입니다. API 퍼즈 테스팅에 관한 새 이슈를 열 때 `~"Category:API Security"` 레이블을 사용하여 적절한 사람들에 의해 빠르게 검토되도록 합니다.

제출하기 전에 이슈 트래커에서 유사한 항목을 검색합니다. 다른 사람이 동일한 이슈 또는 기능 제안을 했을 가능성이 높습니다. 이모지 반응으로 지원을 표시하거나 토론에 참여합니다.

예상대로 작동하지 않는 동작이 발생하는 경우 상황에 맞는 정보를 제공하는 것을 고려합니다:

- GitLab Self-Managed 인스턴스를 사용하는 경우 GitLab 버전입니다.
- `.gitlab-ci.yml` 작업 정의.
- 전체 작업 콘솔 출력.
- `gl-api-security-scanner.log` 이름의 작업 아티팩트로 사용 가능한 스캐너 로그 파일.

> [!warning]
> 이슈를 제출할 때 민감한 정보를 포함하지 마십시오. 암호, 토큰 및 키와 같은 자격 증명을 제거합니다.

## 용어 {#glossary}

- 어설션:  어설션은 검사에서 결함을 트리거하는 데 사용되는 감지 모듈입니다. 많은 어설션에는 구성이 있습니다. 검사는 여러 어설션을 사용할 수 있습니다. 예를 들어 로그 분석, 응답 분석 및 상태 코드는 검사에서 함께 사용되는 일반적인 어설션입니다. 여러 어설션이 있는 검사를 통해 켜고 끌 수 있습니다.
- 검사:  특정 유형의 테스트를 수행하거나 유형의 취약성에 대한 검사를 수행합니다. 예를 들어 JSON 퍼징 검사는 JSON 페이로드의 퍼즈 테스팅을 수행합니다. API 퍼저는 여러 검사로 구성됩니다. 검사를 프로필에서 켜고 끌 수 있습니다.
- 결함:  퍼징 중에 어설션으로 식별된 실패를 결함이라고 합니다. 결함은 보안 취약성, 비보안 이슈 또는 거짓 긍정인지 여부를 확인하기 위해 조사됩니다. 결함은 조사될 때까지 알려진 취약성 유형이 없습니다. 취약성 유형의 예는 SQL 주입 및 서비스 거부입니다.
- 프로필:  구성 파일에는 하나 이상의 테스팅 프로필 또는 하위 구성이 있습니다. 기능 브랜치에 대한 프로필을 가질 수 있고 주 브랜치에 대한 추가 테스팅이 있는 다른 프로필을 가질 수 있습니다.
