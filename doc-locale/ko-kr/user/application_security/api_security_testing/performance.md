---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 성능 튜닝 및 테스트 속도
---

API 보안 테스트와 같은 동적 분석 테스트를 수행하는 보안 도구는 실행 중인 애플리케이션 인스턴스로 요청을 전송하여 테스트를 수행합니다. 요청은 애플리케이션에 존재할 수 있는 특정 취약점을 테스트하도록 설계되었습니다. 동적 분석 테스트의 속도는 다음에 따라 달라집니다:

- GitLab 도구가 애플리케이션으로 초당 전송할 수 있는 요청 수
- 애플리케이션이 요청에 응답하는 속도
- 애플리케이션을 테스트하기 위해 전송해야 하는 요청 수
  - API를 구성하는 작업의 수
  - 각 작업의 필드 수(JSON 본문, 헤더, 쿼리 문자열, 쿠키 등을 생각해 보세요)

이 성능 가이드의 조언을 따른 후 API 보안 테스트 작업이 예상보다 오래 걸리는 경우 추가 지원을 위해 지원팀에 문의하세요.

## 성능 이슈 진단 {#diagnosing-performance-issues}

성능 이슈를 해결하는 첫 번째 단계는 예상보다 느린 테스트 시간에 기여하는 원인을 파악하는 것입니다. 일반적으로 보고되는 이슈는 다음과 같습니다:

- API 보안 테스트가 저사양 vCPU 러너에서 실행 중입니다.
- 배포된 애플리케이션이 느린/단일 CPU 인스턴스에서 실행되며 테스트 부하를 따라가지 못합니다.
- 애플리케이션에 전체 테스트 속도에 영향을 미치는 느린 작업이 포함되어 있습니다(> 1/2초)
- 애플리케이션에 많은 양의 데이터를 반환하는 작업이 포함되어 있습니다(> 500K+)
- 애플리케이션에 많은 수의 작업이 포함되어 있습니다(> 40)

### 애플리케이션에 전체 테스트 속도에 영향을 미치는 느린 작업이 포함되어 있습니다(> 1/2초) {#the-application-contains-a-slow-operation-that-impacts-the-overall-test-speed--12-second}

API 보안 테스트 작업 출력에는 테스트 속도, 작업 응답 시간 및 요약 정보에 대한 유용한 정보가 포함되어 있습니다. 다음 샘플 출력은 요약 출력을 사용하여 성능 이슈를 추적하는 방법을 보여줍니다:

```shell
API SECURITY: Loaded 10 operations from: assets/har-large-response/large_responses.har
API SECURITY:
API SECURITY: Testing operation [1/10]: 'GET http://target:7777/api/large_response_json'.
API SECURITY:  - Parameters: (Headers: 4, Query: 0, Body: 0)
API SECURITY:  - Request body size: 0 Bytes (0 bytes)
API SECURITY:
API SECURITY: Finished testing operation 'GET http://target:7777/api/large_response_json'.
API SECURITY:  - Excluded Parameters: (Headers: 0, Query: 0, Body: 0)
API SECURITY:  - Performed 767 requests
API SECURITY:  - Average response body size: 130 MB
API SECURITY:  - Average call time: 2 seconds and 82.69 milliseconds (2.082693 seconds)
API SECURITY:  - Time to complete: 14 minutes, 8 seconds and 788.36 milliseconds (848.788358 seconds)
```

작업 콘솔 출력 스니펫은 발견된 작업의 수(10)로 시작합니다. 다음으로 특정 작업에서 테스트가 시작되었으며 작업 요약이 완료되었음을 알려줍니다. 요약은 API 보안 테스트가 이 작업 및 관련 필드를 완전히 테스트하기 위해 767개의 요청이 필요했음을 보여줍니다. 요약은 또한 작업의 평균 응답 시간이 2초였으며 완료하는 데 14분이 걸렸음을 보여줍니다.

2초의 평균 응답 시간은 이 특정 작업을 테스트하는 데 오래 걸린다는 좋은 초기 지표입니다. 요약은 또한 긴 응답 시간을 야기하는 큰 응답 본문 크기를 보여줍니다. 각 요청의 대부분의 응답 시간은 응답 본문 데이터를 전송하는 데 소비됩니다.

이 이슈에 대해 팀은 다음을 결정할 수 있습니다:

- 더 많은 vCPU가 있는 러너를 사용하면 API 보안 테스트가 수행 중인 작업을 병렬화할 수 있습니다. 이렇게 하면 테스트 시간을 줄일 수 있지만, 작업을 테스트하는 데 걸리는 시간이 얼마나 오래되는지 때문에 고사양 CPU 머신으로 이동하지 않으면 테스트를 10분 이하로 내리는 것이 여전히 문제가 될 수 있습니다. 더 큰 러너는 비용이 더 많이 들지만, 작업 실행이 더 빠르면 더 적은 분에 대해 비용을 지불합니다.
- [이 작업을 제외](#excluding-slow-operations)하고 API 보안 테스트를 진행합니다. 이것이 가장 간단하지만 보안 테스트 범위에 격차가 생긴다는 단점이 있습니다.
- [기능 브랜치에서 작업을 제외하되 기본 브랜치 테스트에는 포함](#excluding-operations-in-feature-branches-but-not-default-branch)합니다.
- [API 보안 테스트를 여러 작업으로 분할](#splitting-a-test-into-multiple-jobs)합니다.

가능성 있는 솔루션은 이러한 솔루션들의 조합을 사용하여 팀의 요구 사항이 5~7분 범위에 있다고 가정할 때 허용 가능한 테스트 시간에 도달하는 것입니다.

## 성능 이슈 해결 {#addressing-performance-issues}

다음 섹션에서는 API 보안 테스트의 성능 이슈를 해결하기 위한 다양한 옵션을 설명합니다:

- [더 큰 러너 사용](#using-a-larger-runner)
- [느린 작업 제외](#excluding-slow-operations)
- [테스트를 여러 작업으로 분할](#splitting-a-test-into-multiple-jobs)
- [기능 브랜치에서 작업을 제외하되 기본 브랜치에는 포함하지 않음](#excluding-operations-in-feature-branches-but-not-default-branch)

### 더 큰 러너 사용 {#using-a-larger-runner}

가장 쉬운 성능 향상 중 하나는 API 보안 테스트에서 [더 큰 러너](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64)를 사용하여 얻을 수 있습니다. 이 표는 Java Spring Boot REST API 벤치마킹 중에 수집된 통계를 보여줍니다. 이 벤치마크에서 대상 및 API 보안 테스트는 단일 러너 인스턴스를 공유합니다.

| Linux 태그의 호스팅된 러너           | 초당 요청 수 |
|------------------------------------|-----------|
| `saas-linux-small-amd64`(기본값) | 255 |
| `saas-linux-medium-amd64`          | 400 |

이 표는 러너 크기 및 vCPU 수를 증가시키면 테스트 속도/성능에 큰 영향을 미칠 수 있음을 보여줍니다.

다음은 `tags` 섹션을 추가하여 Linux에서 중간 GitLab 호스팅 러너를 사용하는 API 보안 테스트의 예제 작업 정의입니다. 작업은 API 보안 테스트 템플릿을 통해 포함된 작업 정의를 확장합니다.

```yaml
api_security:
  tags:
  - saas-linux-medium-amd64
```

`gl-api-security-scanner.log` 파일에서 문자열 `Starting work item processor`를 검색하여 보고된 최대 DOP(병렬 처리 정도)를 검사할 수 있습니다. 최대 DOP는 러너에 할당된 vCPU 수보다 크거나 같아야 합니다. 문제를 파악할 수 없으면 지원팀에 도움을 요청하는 티켓을 엽니다.

예제 로그 항목:

`17:00:01.084 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Starting work item processor with 4 max DOP`

### 느린 작업 제외 {#excluding-slow-operations}

느린 작업이 하나 또는 두 개인 경우 팀이 작업 테스트를 건너뛰기로 결정할 수 있습니다. 작업을 제외하는 것은 `APISEC_EXCLUDE_PATHS` 구성 [변수로 설명된 대로 수행됩니다.](configuration/customizing_analyzer_settings.md#exclude-paths)

이 예제는 많은 양의 데이터를 반환하는 작업을 보여줍니다. 작업은 `GET http://target:7777/api/large_response_json`입니다. 이를 제외하려면 `APISEC_EXCLUDE_PATHS` 구성 변수에 작업 URL의 경로 부분 `/api/large_response_json`을(를) 제공하세요.

작업이 제외되었는지 확인하려면 API 보안 테스트 작업을 실행하고 작업 콘솔 출력을 검토하세요. 테스트 끝에 포함되고 제외된 작업의 목록을 포함합니다.

```yaml
api_security:
  variables:
    APISEC_EXCLUDE_PATHS: /api/large_response_json
```

> [!warning]
> 테스트에서 작업을 제외하면 일부 취약점을 감지하지 못할 수 있습니다.

### 테스트를 여러 작업으로 분할 {#splitting-a-test-into-multiple-jobs}

테스트를 여러 작업으로 분할하는 것은 [`APISEC_EXCLUDE_PATHS`](configuration/customizing_analyzer_settings.md#exclude-paths) 와(과) [`APISEC_EXCLUDE_URLS`](configuration/customizing_analyzer_settings.md#exclude-urls)의 사용을 통해 API 보안 테스트에서 지원됩니다. 테스트를 분할할 때 좋은 패턴은 `dast_api` 작업을 비활성화하고 식별 이름이 있는 두 개의 작업으로 바꾸는 것입니다. 이 예제는 두 개의 작업을 보여줍니다. 각 작업은 API의 버전을 테스트하며, 이름에 반영됩니다. 그러나 이 기술은 API 버전뿐만 아니라 모든 상황에 적용할 수 있습니다.

`APISEC_v1`과(과) `APISEC_v2` 작업에서 사용된 규칙은 [API 보안 테스트 템플릿](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)에서 복사됩니다.

```yaml
# Disable the main dast_api job
api_security:
  rules:
  - if: $CI_COMMIT_BRANCH
    when: never

APISEC_v1:
  extends: dast_api
  variables:
    APISEC_EXCLUDE_PATHS: /api/v1/**
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH

APISEC_v2:
  variables:
    APISEC_EXCLUDE_PATHS: /api/v2/**
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH
```

### 기능 브랜치에서 작업을 제외하되 기본 브랜치에는 포함하지 않음 {#excluding-operations-in-feature-branches-but-not-default-branch}

느린 작업이 하나 또는 두 개인 경우 팀이 작업 테스트를 건너뛰거나, 기능 브랜치 테스트에서 제외하되 기본 브랜치 테스트에는 포함하기로 결정할 수 있습니다. 작업을 제외하는 것은 `APISEC_EXCLUDE_PATHS` 구성 [변수로 설명된 대로 수행됩니다.](configuration/customizing_analyzer_settings.md#exclude-paths)

이 예제는 많은 양의 데이터를 반환하는 작업을 보여줍니다. 작업은 `GET http://target:7777/api/large_response_json`입니다. 이를 제외하려면 `APISEC_EXCLUDE_PATHS` 구성 변수에 작업 URL의 경로 부분 `/api/large_response_json`을(를) 제공하세요. 구성은 주요 `dast_api` 작업을 비활성화하고 두 개의 새로운 작업 `APISEC_main`과(과) `APISEC_branch`을(를) 만듭니다. `APISEC_branch`은(는) 오래 걸리는 작업을 제외하고 기본이 아닌 브랜치(예: 기능 브랜치)에서만 실행되도록 설정됩니다. `APISEC_main` 브랜치는 기본 브랜치(`main`(이 예제에서))에서만 실행되도록 설정됩니다. `APISEC_branch` 작업은(는) 더 빠르게 실행되어 빠른 개발 사이클을 허용하는 반면, 기본 브랜치 빌드에서만 실행되는 `APISEC_main` 작업은(는) 더 오래 실행됩니다.

작업이 제외되었는지 확인하려면 API 보안 테스트 작업을 실행하고 작업 콘솔 출력을 검토하세요. 테스트 끝에 포함되고 제외된 작업의 목록을 포함합니다.

```yaml
# Disable the main job so you can create two jobs with
# different names
api_security:
  rules:
  - if: $CI_COMMIT_BRANCH
    when: never

# API security testing for feature branch work, excludes /api/large_response_json
APISEC_branch:
  extends: dast_api
  variables:
    APISEC_EXCLUDE_PATHS: /api/large_response_json
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    when: never
  - if: $CI_COMMIT_BRANCH

# API security testing for default branch (main in this case)
# Includes the long running operations
APISEC_main:
  extends: dast_api
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```
