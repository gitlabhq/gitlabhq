---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 성능 조정 및 테스트 속도
---

API 퍼징 같은 API 퍼징 테스트를 수행하는 보안 도구는 실행 중인 애플리케이션 인스턴스에 요청을 전송하여 테스트를 수행합니다. 요청은 퍼징 엔진에 의해 변경되어 애플리케이션에 존재할 수 있는 예상치 못한 동작을 트리거합니다. API 퍼징 테스트의 속도는 다음에 따라 달라집니다:

- GitLab 도구가 애플리케이션에 초당 보낼 수 있는 요청 수
- 애플리케이션이 요청에 응답하는 속도
- 애플리케이션을 테스트하기 위해 전송해야 하는 요청 수
  - API가 구성된 작업의 수
  - 각 작업의 필드 수(JSON 본문, 헤더, 쿼리 문자열, 쿠키 등을 생각하세요)

API 퍼징 테스트 작업이 이 성능 가이드의 조언을 따른 후에도 예상보다 오래 걸리면 추가 지원을 받으려면 지원팀에 문의하세요.

## 성능 이슈 진단 {#diagnosing-performance-issues}

성능 이슈를 해결하는 첫 번째 단계는 예상보다 느린 테스트 시간에 기여하는 원인을 파악하는 것입니다. 일반적으로 보고되는 이슈는 다음과 같습니다:

- API 퍼징이 낮은 vCPU 러너에서 실행 중입니다
- 느린/단일 CPU 인스턴스에 배포된 애플리케이션이 테스트 로드를 따라잡지 못합니다
- 애플리케이션이 전체 테스트 속도에 영향을 미치는 느린 작업을 포함합니다(> 1/2초)
- 애플리케이션이 많은 양의 데이터를 반환하는 작업을 포함합니다(> 500K+)
- 애플리케이션이 많은 수의 작업을 포함합니다(> 40)

### 애플리케이션이 전체 테스트 속도에 영향을 미치는 느린 작업을 포함합니다(> 1/2초) {#the-application-contains-a-slow-operation-that-impacts-the-overall-test-speed--12-second}

API 퍼징 작업 출력에는 테스트 속도, 작업 응답 시간 및 요약 정보에 대한 유용한 정보가 포함됩니다. 다음 샘플 출력을 사용하여 성능 이슈를 추적합니다:

```shell
API Fuzzing: Loaded 10 operations from: assets/har-large-response/large_responses.har
API Fuzzing:
API Fuzzing: Testing operation [1/10]: 'GET http://target:7777/api/large_response_json'.
API Fuzzing:  - Parameters: (Headers: 4, Query: 0, Body: 0)
API Fuzzing:  - Request body size: 0 Bytes (0 bytes)
API Fuzzing:
API Fuzzing: Finished testing operation 'GET http://target:7777/api/large_response_json'.
API Fuzzing:  - Excluded Parameters: (Headers: 0, Query: 0, Body: 0)
API Fuzzing:  - Performed 767 requests
API Fuzzing:  - Average response body size: 130 MB
API Fuzzing:  - Average call time: 2 seconds and 82.69 milliseconds (2.082693 seconds)
API Fuzzing:  - Time to complete: 14 minutes, 8 seconds and 788.36 milliseconds (848.788358 seconds)
```

작업 콘솔 출력 스니펫은 발견된 작업의 수(10)로 시작합니다. 다음으로 특정 작업에 대한 테스트가 시작되었다는 알림과 작업 요약이 완료되었습니다. 요약은 API 퍼징이 이 작업 및 관련 필드를 완전히 테스트하기 위해 767개의 요청을 수행했음을 보여줍니다. 요약은 또한 이 작업이 평균 응답 시간 2초로 완료되는 데 14분이 걸렸음을 보여줍니다.

평균 응답 시간 2초는 이 특정 작업이 테스트하는 데 오래 걸리는 초기 표시입니다. 응답 본문 크기가 크다는 것을 볼 수 있으며, 이는 긴 응답 시간의 원인입니다. 각 요청의 대부분의 응답 시간은 응답 본문 데이터를 전송하는 데 소비됩니다.

이 이슈에 대해 팀은 다음을 결정할 수 있습니다:

- 더 많은 vCPU가 있는 러너를 사용합니다. 이는 API 퍼징이 수행되는 작업을 병렬화할 수 있게 합니다. 이는 테스트 시간을 낮추는 데 도움이 되지만, 작업이 테스트하는 데 걸리는 시간으로 인해 테스트를 10분 이하로 낮추는 것이 높은 CPU 머신으로 이동하지 않고는 여전히 문제가 될 수 있습니다. 더 큰 러너는 더 비싸지만, 작업 실행이 더 빨르면 더 적은 분 동안 비용을 지불합니다.
- [이 작업 제외](#excluding-slow-operations)를 API 퍼징 테스트에서 제외합니다. 이것이 가장 간단하지만 보안 테스트 범위에 격차가 있다는 단점이 있습니다.
- [기능 브랜치 API 퍼징 테스트에서 작업을 제외하되 기본 브랜치 테스트에 포함](#excluding-operations-in-feature-branches-but-not-default-branch)합니다.
- [API 퍼징 테스트를 여러 작업으로 분할](#splitting-a-test-into-multiple-jobs)합니다.

가능한 해결 방법은 이러한 솔루션을 조합하여 사용하여 팀의 요구 사항이 5~7분 범위인 경우 허용 가능한 테스트 시간에 도달하는 것입니다.

## 성능 이슈 해결 {#addressing-performance-issues}

다음 섹션은 API 퍼징의 성능 이슈를 해결하기 위한 다양한 옵션을 문서화합니다:

- [더 큰 러너 사용](#using-a-larger-runner)
- [느린 작업 제외](#excluding-slow-operations)
- [테스트를 여러 작업으로 분할](#splitting-a-test-into-multiple-jobs)
- [기능 브랜치에서 작업 제외, 기본 브랜치 제외 안 함](#excluding-operations-in-feature-branches-but-not-default-branch)

### 더 큰 러너 사용 {#using-a-larger-runner}

가장 쉬운 성능 향상 중 하나는 API 퍼징과 함께 [더 큰 러너](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64)를 사용하여 달성할 수 있습니다. 이 표는 Java Spring Boot REST API의 벤치마킹 중에 수집된 통계를 보여줍니다. 이 벤치마크에서 대상과 API 퍼징은 단일 러너 인스턴스를 공유합니다.

| Linux 태그의 호스팅된 러너           | 초당 요청 수 |
|------------------------------------|-----------|
| `saas-linux-small-amd64` (기본값) | 255 |
| `saas-linux-medium-amd64`          | 400 |

이 표는 러너의 크기와 vCPU 수를 늘리는 것이 테스트 속도/성능에 큰 영향을 미칠 수 있는 방법을 보여줍니다.

다음은 `tags` 섹션을 추가하여 Linux에서 중간 GitLab 호스팅 러너를 사용하는 API 퍼징의 예제 작업 정의입니다. 작업은 API 퍼징 템플릿을 통해 포함된 작업 정의를 확장합니다.

```yaml
apifuzzer_fuzz:
  tags:
  - saas-linux-medium-amd64
```

`gl-api-security-scanner.log` 파일에서 보고된 최대 DOP(병렬화 정도)를 검사하기 위해 `Starting work item processor` 문자열을 검색할 수 있습니다. 최대 DOP는 러너에 할당된 vCPU 수보다 크거나 같아야 합니다. 문제를 식별할 수 없으면 지원팀에 도움을 받기 위해 티켓을 엽니다.

예제 로그 항목:

`17:00:01.084 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Starting work item processor with 4 max DOP`

### 느린 작업 제외 {#excluding-slow-operations}

하나 또는 두 개의 느린 작업이 있는 경우 팀은 작업 테스트를 건너뛰기로 결정할 수 있습니다. 작업 제외는 `FUZZAPI_EXCLUDE_PATHS` 구성 [변수를 사용하여 수행됩니다.](configuration/customizing_analyzer_settings.md#exclude-paths)

이 예제는 많은 양의 데이터를 반환하는 작업을 보여줍니다. 작업은 `GET http://target:7777/api/large_response_json`입니다. 이를 제외하려면 작업 URL의 경로 부분이 있는 `FUZZAPI_EXCLUDE_PATHS` 구성 변수를 제공합니다 `/api/large_response_json`.

작업이 제외되었는지 확인하려면 API 퍼징 작업을 실행하고 작업 콘솔 출력을 검토합니다. 테스트 끝에 포함되고 제외된 작업의 목록이 포함됩니다.

```yaml
apifuzzer_fuzz:
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/large_response_json
```

> [!warning]
> 테스트에서 작업을 제외하면 일부 취약성이 감지되지 않을 수 있습니다.

### 테스트를 여러 작업으로 분할 {#splitting-a-test-into-multiple-jobs}

테스트를 여러 작업으로 분할하는 것은 [`FUZZAPI_EXCLUDE_PATHS`](configuration/customizing_analyzer_settings.md#exclude-paths) 및 [`FUZZAPI_EXCLUDE_URLS`](configuration/customizing_analyzer_settings.md#exclude-urls)의 사용을 통해 API 퍼징에서 지원됩니다. 테스트를 분할할 때 좋은 패턴은 `apifuzzer_fuzz` 작업을 비활성화하고 식별 이름이 있는 두 개의 작업으로 바꾸는 것입니다. 이 예제는 두 개의 작업을 보여줍니다. 각 작업은 API의 버전을 테스트하며, 이름으로 반영됩니다. 그러나 이 기술은 API 버전뿐만 아니라 모든 상황에 적용될 수 있습니다.

`apifuzzer_v1` 및 `apifuzzer_v2` 작업에 사용된 규칙은 [API 퍼징 템플릿](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml)에서 복사됩니다.

```yaml
# Disable the main apifuzzer_fuzz job
apifuzzer_fuzz:
  rules:
    - if: $CI_COMMIT_BRANCH
      when: never

apifuzzer_v1:
  extends: apifuzzer_fuzz
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/v1/**
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH

apifuzzer_v2:
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/v2/**
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH
```

### 기능 브랜치에서 작업 제외, 기본 브랜치 제외 안 함 {#excluding-operations-in-feature-branches-but-not-default-branch}

하나 또는 두 개의 느린 작업이 있는 경우 팀은 작업 테스트를 건너뛰거나 기능 브랜치 테스트에서 제외하되 기본 브랜치 테스트에 포함할 수 있습니다. 작업 제외는 `FUZZAPI_EXCLUDE_PATHS` 구성 [변수를 사용하여 수행됩니다.](configuration/customizing_analyzer_settings.md#exclude-paths)

이 예제는 많은 양의 데이터를 반환하는 작업을 보여줍니다. 작업은 `GET http://target:7777/api/large_response_json`입니다. 이를 제외하려면 작업 URL의 경로 부분이 있는 `FUZZAPI_EXCLUDE_PATHS` 구성 변수를 제공합니다 `/api/large_response_json`. 구성은 주 `apifuzzer_fuzz` 작업을 비활성화하고 두 개의 새로운 작업 `apifuzzer_main` 및 `apifuzzer_branch`을 생성합니다. `apifuzzer_branch`은 긴 작업을 제외하고 기본이 아닌 브랜치에서만 실행하도록 설정됩니다(예: 기능 브랜치). `apifuzzer_main` 브랜치는 기본 브랜치에서만 실행하도록 설정됩니다(이 예제의 `main`). `apifuzzer_branch` 작업은 더 빠르게 실행되어 빠른 개발 사이클을 허용하는 반면, 기본 브랜치 빌드에서만 실행되는 `apifuzzer_main` 작업은 실행하는 데 더 오래 걸립니다.

작업이 제외되었는지 확인하려면 API 퍼징 작업을 실행하고 작업 콘솔 출력을 검토합니다. 테스트 끝에 포함되고 제외된 작업의 목록이 포함됩니다.

```yaml
# Disable the main job so you can create two jobs with
# different names
apifuzzer_fuzz:
  rules:
    - if: $CI_COMMIT_BRANCH
      when: never

# API fuzzing for feature branch work, excludes /api/large_response_json
apifuzzer_branch:
  extends: apifuzzer_fuzz
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/large_response_json
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_COMMIT_BRANCH

# API fuzzing for default branch (main in this case)
# Includes the long running operations
apifuzzer_main:
  extends: apifuzzer_fuzz
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```
