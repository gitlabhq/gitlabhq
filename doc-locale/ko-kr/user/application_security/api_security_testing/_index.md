---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API 보안 테스트 분석기
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.0에서 "DAST API 분석기"에서 "API 보안 테스트 분석기"로 [이름이 바뀌었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/457449).

{{< /history >}}

웹 API를 테스트하여 다른 QA 프로세스에서 놓칠 수 있는 버그와 잠재적인 보안 이슈를 발견하도록 도와줍니다. 다른 보안 스캐너 및 자신의 테스트 프로세스와 함께 API 보안 테스트를 사용하세요. CI/CD 워크플로우의 일부로, [온디맨드](../dast/on-demand_scan.md)로 또는 둘 다로 API 보안 테스트 테스트를 실행할 수 있습니다.

> [!warning]
> 프로덕션 서버에 대해 API 보안 테스트를 실행하지 마세요. API가 수행할 수 있는 모든 함수를 수행할 수 있을 뿐만 아니라, API의 버그를 트리거할 수도 있습니다. 여기에는 데이터 수정 및 삭제와 같은 작업이 포함됩니다. 테스트 서버에 대해서만 API 보안 테스트를 실행하세요.

## 시작하기 {#getting-started}

CI/CD 구성을 편집하여 API 보안 테스트를 시작하세요.

전제 조건:

- 지원되는 API 유형 중 하나를 사용하는 웹 API가 있습니다:
  - REST API
  - SOAP
  - GraphQL
  - 양식 본문, JSON 또는 XML
- 다음 형식 중 하나의 API 사양이 있습니다:
  - [OpenAPI v2 또는 v3 사양](configuration/enabling_the_analyzer.md#openapi-specification)
  - [GraphQL 스키마](configuration/enabling_the_analyzer.md#graphql-schema)
  - [HTTP 아카이브(HAR)](configuration/enabling_the_analyzer.md#http-archive-har)
  - [Postman 컬렉션 v2.0 또는 v2.1](configuration/enabling_the_analyzer.md#postman-collection)

  각 스캔은 정확히 하나의 사양을 지원합니다. 두 개 이상의 사양을 스캔하려면 여러 스캔을 사용하세요.
- [러너](../../../ci/runners/_index.md) 사용이 가능하며, Linux/amd64의 [`docker` 실행기](https://docs.gitlab.com/runner/executors/docker/)를 사용합니다.
- 배포된 대상 애플리케이션이 있습니다. 자세한 내용은 [배포 옵션](#application-deployment-options)을 참조하세요.
- `dast` 스테이지는 CI/CD 파이프라인 정의에 `deploy` 스테이지 후에 추가됩니다. 예를 들어:

  ```yaml
  stages:
    - build
    - test
    - deploy
    - dast
  ```

API 보안 테스트를 활성화하려면 환경의 고유한 요구 사항에 따라 GitLab CI/CD 구성 YAML을 변경해야 합니다. 다음을 사용하여 스캔할 API를 지정할 수 있습니다:

- [OpenAPI v2 또는 v3 사양](configuration/enabling_the_analyzer.md#openapi-specification)
- [GraphQL 스키마](configuration/enabling_the_analyzer.md#graphql-schema)
- [HTTP 아카이브(HAR)](configuration/enabling_the_analyzer.md#http-archive-har)
- [Postman 컬렉션 v2.0 또는 v2.1](configuration/enabling_the_analyzer.md#postman-collection)

## 결과 이해 {#understanding-the-results}

보안 스캔의 출력을 보려면:

1. 상단 바에서 **Search or go to**를 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 파이프라인을 선택합니다.
1. **보안** 탭을 선택합니다.
1. 취약성을 선택하여 세부 정보를 확인합니다:
   - 상태:  취약성이 심사되었는지 또는 해결되었는지 여부를 나타냅니다.
   - 설명:  취약성의 원인, 잠재적 영향 및 권장 수정 단계를 설명합니다.
   - 심각도:  영향에 따라 6가지 수준으로 분류됩니다. [심각도 수준에 대해 자세히 알아보기](../vulnerabilities/severities.md).
   - 스캐너:  취약성을 감지한 분석기를 식별합니다.
   - 메서드:  취약한 서버 상호 작용 유형을 설정합니다.
   - URL:  취약성의 위치를 표시합니다.
   - 증거:  주어진 취약성의 존재를 증명하기 위한 테스트 사례를 설명합니다.
   - 식별자:  CWE 식별자와 같은 취약성을 분류하는 데 사용되는 참조 목록입니다.

보안 스캔 결과를 다운로드할 수도 있습니다:

- 파이프라인의 **보안** 탭에서 **결과 다운로드**를 선택합니다.

자세한 내용은 [파이프라인 보안 보고서](../detect/security_scanning_results.md)를 참조하세요.

> [!note]
> 검사 결과는 기능 브랜치에서 생성됩니다. 결과가 기본 브랜치에 병합되면 취약성이 됩니다. 이 구분은 보안 태세를 평가할 때 중요합니다.

## 최적화 {#optimization}

API 보안 테스트를 최대한 활용하려면 다음 권장 사항을 따르세요:

- 러너를 구성하여 [항상 풀(pull) 정책](https://docs.gitlab.com/runner/executors/docker/#using-the-always-pull-policy)을 사용하여 분석기의 최신 버전을 실행하세요.
- 기본적으로 API 보안 테스트는 파이프라인의 이전 작업에서 정의한 모든 작업 아티팩트를 다운로드합니다. DAST 작업이 테스트할 URL을 정의하기 위해 `environment_url.txt`에 의존하지 않거나 이전 작업에서 생성된 다른 파일에 의존하지 않으면 아티팩트를 다운로드하면 안 됩니다. 아티팩트 다운로드를 피하려면 분석기 CI/CD 작업을 확장하여 종속성이 없음을 지정하세요. 예를 들어 API 보안 테스트 분석기의 경우 `.gitlab-ci.yml` 파일에 다음을 추가하세요:

  ```yaml
  api_security:
    dependencies: []
  ```

특정 애플리케이션 또는 환경을 위해 API 보안 테스트를 구성하려면 [구성 옵션](configuration/_index.md)의 전체 목록을 참조하세요.

## 배포 및 확장 {#roll-out}

CI/CD 파이프라인에서 실행할 때 API 보안 테스트 스캔은 기본적으로 `dast` 스테이지에서 실행됩니다. API 보안 테스트 스캔이 최신 코드를 검사하도록 하려면 CI/CD 파이프라인이 `dast` 스테이지 전의 스테이지에서 변경 사항을 테스트 환경에 배포하도록 하세요.

각 실행에서 동일한 웹 서버에 배포하도록 파이프라인이 구성된 경우, 다른 파이프라인이 여전히 실행 중인 동안 파이프라인을 실행하면 한 파이프라인이 다른 파이프라인의 코드를 덮어쓸 수 있는 경쟁 조건이 발생할 수 있습니다. 스캔할 API는 API 보안 테스트 스캔 기간 동안 변경 사항에서 제외되어야 합니다. API에 대한 유일한 변경은 API 보안 테스트 스캐너에서 가져와야 합니다. 스캔 중에 API(예: 사용자, 예약된 작업, 데이터베이스 변경 사항, 코드 변경 사항, 다른 파이프라인 또는 다른 스캐너)에 대한 변경 사항은 부정확한 결과를 초래할 수 있습니다.

### API 보안 테스트 스캔 구성 예제 {#example-api-security-testing-scanning-configurations}

다음 프로젝트는 API 보안 테스트 스캔을 보여줍니다:

- [OpenAPI v3 사양 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-v3-example)
- [OpenAPI v2 사양 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-example)
- [HTTP 아카이브(HAR) 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-dast/har-example)
- [Postman 컬렉션 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-dast/postman-example)
- [GraphQL 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-dast/graphql-example)
- [SOAP 프로젝트 예제](https://gitlab.com/gitlab-org/security-products/demos/api-dast/soap-example)
- [Selenium을 사용한 인증 토큰](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-token-selenium)

### 애플리케이션 배포 옵션 {#application-deployment-options}

API 보안 테스트는 스캔할 수 있도록 배포된 애플리케이션이 필요합니다.

대상 애플리케이션의 복잡도에 따라 API 보안 테스트 템플릿을 배포하고 구성하는 방법에 몇 가지 옵션이 있습니다.

#### 검토 앱 {#review-apps}

검토 앱은 DAST 대상 애플리케이션을 배포하는 가장 복잡한 방법입니다. 프로세스를 지원하기 위해 GitLab은 Google Kubernetes Engine(GKE)을 사용하여 검토 앱 배포를 만들었습니다. 이 예제는 [검토 앱 - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke) 프로젝트에서 찾을 수 있으며, DAST용 검토 앱을 구성하기 위한 자세한 지침은 [README.md](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke/-/blob/master/README.md)에서 찾을 수 있습니다.

#### Docker 서비스 {#docker-services}

애플리케이션이 Docker 컨테이너를 사용하는 경우 DAST로 배포하고 스캔하는 또 다른 옵션이 있습니다. Docker 빌드 작업이 완료되고 이미지가 컨테이너 레지스트리에 추가되면 이미지를 [서비스](../../../ci/services/_index.md)로 사용할 수 있습니다.

`.gitlab-ci.yml`에서 서비스 정의를 사용하여 DAST 분석기로 서비스를 스캔할 수 있습니다.

`services` 섹션을 작업에 추가할 때 `alias`는 서비스에 액세스하는 데 사용할 수 있는 호스트명을 정의하는 데 사용됩니다. 다음 예제에서 `dast` 작업 정의의 `alias: yourapp` 부분은 배포된 애플리케이션의 URL이 `yourapp`를 호스트명으로 사용함을 의미합니다(`https://yourapp/`).

```yaml
stages:
  - build
  - dast

include:
  - template: API-Security.gitlab-ci.yml

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

api_security:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  APISEC_TARGET_URL: https://yourapp
```

대부분의 애플리케이션은 데이터베이스 또는 캐싱 서비스와 같은 여러 서비스에 의존합니다. 기본적으로 서비스 필드에 정의된 서비스는 서로 통신할 수 없습니다. 서비스 간 통신을 허용하려면 `FF_NETWORK_PER_BUILD` [기능 플래그](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags)를 활성화하세요.

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```

## 지원 받기 또는 개선 요청 {#get-support-or-request-an-improvement}

특정 문제에 대한 지원을 받으려면 [도움말 채널](https://about.gitlab.com/get-help/)을 사용합니다.

[GitLab.com의 GitLab 이슈 트래커](https://gitlab.com/gitlab-org/gitlab/-/issues)는 API 보안 테스트에 대한 버그 및 기능 제안을 위한 올바른 위치입니다. API 보안 테스트와 관련하여 새 이슈를 열 때 `~"Category:API Security"` 레이블을 사용하여 적절한 담당자가 빠르게 검토하도록 하세요.

[이슈 추적기 검색](https://gitlab.com/gitlab-org/gitlab/-/issues)을 통해 유사한 항목이 없는지 먼저 확인한 후 자신의 항목을 제출하세요. 누군가 이미 같은 이슈 또는 기능 제안을 했을 가능성이 있습니다. 이모지 반응으로 지원을 표시하거나 토론에 참여합니다.

예상대로 작동하지 않는 동작이 있을 때, 상황 정보를 제공하는 것을 고려합니다:

- GitLab Self-Managed 인스턴스를 사용하는 경우 GitLab 버전입니다.
- `.gitlab-ci.yml` 작업 정의.
- 전체 작업 콘솔 출력.
- `gl-api-security-scanner.log` 이름의 작업 아티팩트로 사용 가능한 스캐너 로그 파일입니다.

> [!warning]
> **지원 이슈에 첨부된 데이터를 익명화합니다**. 자격 증명, 비밀번호, 토큰, 키 및 보안 암호를 포함한 민감한 정보를 제거합니다.

## 용어집 {#glossary}

- Assert:  Assert는 취약성을 트리거하기 위해 확인으로 사용되는 감지 모듈입니다. 많은 Assert에는 구성이 있습니다. 확인은 여러 Assert를 사용할 수 있습니다. 예를 들어 로그 분석, 응답 분석 및 상태 코드는 확인으로 함께 사용되는 일반적인 Assert입니다. 여러 Assert가 있는 확인은 켜고 끌 수 있습니다.
- 확인:  특정 유형의 테스트를 수행하거나 취약성 유형에 대한 확인을 수행합니다. 예를 들어 SQL 주입 확인은 SQL 주입 취약성을 위한 DAST 테스트를 수행합니다. API 보안 테스트 스캐너는 여러 확인으로 구성됩니다. 확인은 프로필에서 켜고 끌 수 있습니다.
- 프로필:  구성 파일에는 하나 이상의 테스트 프로필 또는 하위 구성이 있습니다. 기능 브랜치용 프로필과 메인 브랜치용 추가 테스트가 있는 다른 프로필을 가질 수 있습니다.
