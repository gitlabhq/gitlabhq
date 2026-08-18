---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API 퍼징 작업 문제 해결
---

## API 퍼징 작업이 N시간 후 시간 초과 {#api-fuzzing-job-times-out-after-n-hours}

더 큰 리포지토리의 경우, API 퍼징 작업이 [Linux의 소형 호스팅 러너](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64)에서 시간 초과될 수 있으며, 이는 기본값으로 설정되어 있습니다. 작업에서 이 문제가 발생하면 [더 큰 러너](performance.md#using-a-larger-runner)로 확장해야 합니다.

도움을 받으려면 다음 설명서 섹션을 참조하세요:

- [성능 조정 및 테스트 속도](performance.md)
- [더 큰 러너 사용](performance.md#using-a-larger-runner)
- [경로별 작업 제외](configuration/customizing_analyzer_settings.md#exclude-paths)
- [느린 작업 제외](performance.md#excluding-slow-operations)

## API 퍼징 작업이 완료되는 데 너무 오래 걸림 {#api-fuzzing-job-takes-too-long-to-complete}

[성능 조정 및 테스트 속도](performance.md)를 참조하세요

## 오류: `Error waiting for API fuzzing 'http://127.0.0.1:5000' to become available` {#error-error-waiting-for-api-fuzzing-http1270015000-to-become-available}

v1.6.196 이전 API 퍼징 분석기 버전에 특정 조건에서 백그라운드 프로세스 실패를 유발할 수 있는 버그가 존재합니다. 해결 방법은 API 퍼징 분석기의 최신 버전으로 업데이트하는 것입니다.

버전 정보는 `apifuzzer_fuzz` 작업의 작업 세부 정보에서 찾을 수 있습니다.

v1.6.196 이상 버전에서 이슈가 발생하면 지원팀에 문의하여 다음 정보를 제공하세요:

1. 이 이슈 해결 섹션을 참조하고 Dynamic Analysis Team으로 에스컬레이션하도록 요청하세요.
1. 작업의 전체 콘솔 출력입니다.
1. `gl-api-security-scanner.log` 파일(작업 아티팩트로 사용 가능). 작업 세부 정보 페이지의 오른쪽 패널에서 **탐색** 버튼을 선택합니다.
1. `apifuzzer_fuzz` 작업 정의(파일 `.gitlab-ci.yml`에서).

**Error message**

- [GitLab 15.6 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/376078)에서, `Error waiting for API Fuzzing 'http://127.0.0.1:5000' to become available`
- GitLab 15.5 이전에는 `Error waiting for API Security 'http://127.0.0.1:5000' to become available`입니다.

### `Failed to start session with scanner. Please retry, and if the problem persists reach out to support.` {#failed-to-start-session-with-scanner-please-retry-and-if-the-problem-persists-reach-out-to-support}

API 퍼징 엔진은 스캐너 애플리케이션 구성 요소와의 연결을 설정할 수 없을 때 오류 메시지를 출력합니다. 오류 메시지는 `apifuzzer_fuzz` 작업의 작업 출력 창에 표시됩니다. 이 이슈의 일반적인 원인은 백그라운드 구성 요소가 선택된 포트를 사용할 수 없다는 것입니다(이미 사용 중). 이 오류는 타이밍이 역할을 할 경우 간헐적으로 발생할 수 있습니다(경합 조건). 이 이슈는 다른 서비스가 컨테이너에 매핑되어 포트 충돌을 야기하는 Kubernetes 환경에서 가장 자주 발생합니다.

해결 방법을 진행하기 전에 포트가 이미 사용 중이었기 때문에 오류 메시지가 생성되었음을 확인하는 것이 중요합니다. 이것이 원인임을 확인하려면:

1. 작업 콘솔로 이동합니다.
1. `gl-api-security-scanner.log` 아티팩트를 찾습니다. **다운로드**를 선택하여 모든 아티팩트를 다운로드한 후 파일을 검색하거나, **탐색**을 선택하여 직접 검색을 시작할 수 있습니다.
1. `gl-api-security-scanner.log` 파일을 텍스트 편집기에서 엽니다.
1. 포트가 이미 사용 중이었기 때문에 오류 메시지가 생성되었다면, 파일에서 다음과 같은 메시지를 볼 수 있습니다:

- [GitLab 15.5 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/367734):

  ```log
  Failed to bind to address http://127.0.0.1:5500: address already in use.
  ```

- GitLab 15.4 이전:

  ```log
  Failed to bind to address http://[::]:5000: address already in use.
  ```

이전 메시지의 `http://[::]:5000` 텍스트는 경우에 따라 다를 수 있습니다. 예를 들어 `http://[::]:5500` 또는 `http://127.0.0.1:5500`일 수 있습니다. 오류 메시지의 나머지 부분이 동일한 한 포트가 이미 사용 중이었다고 가정하는 것이 안전합니다.

포트가 이미 사용 중이었다는 증거를 찾지 못한 경우, 작업 콘솔 출력에 표시되는 동일한 오류 메시지를 다루는 다른 문제 해결 섹션을 확인하세요. 더 이상의 옵션이 없으면 [지원 받기 또는 개선 사항 요청](_index.md#get-support-or-request-an-improvement)을 적절한 채널을 통해 자유롭게 진행하세요.

포트가 이미 사용 중이었기 때문에 이슈가 발생했음을 확인한 후, [GitLab 15.5 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/367734)에서 구성 변수 `FUZZAPI_API_PORT`이 도입되었습니다. 이 구성 변수를 사용하면 스캐너 백그라운드 구성 요소의 고정 포트 번호를 설정할 수 있습니다.

**해결 방법**

1. `.gitlab-ci.yml` 파일이 구성 변수 `FUZZAPI_API_PORT`을 정의하는지 확인합니다.
1. `FUZZAPI_API_PORT`의 값을 1024보다 큰 사용 가능한 포트 번호로 업데이트합니다. 새 값이 GitLab에서 사용 중이 아닌지 확인하세요. [패키지 기본값](../../../administration/package_information/defaults.md#ports)에서 GitLab이 사용하는 포트의 전체 목록을 참조하세요

## 오류: `Errors were found during validation of the document using the published OpenAPI schema` {#error-errors-were-found-during-validation-of-the-document-using-the-published-openapi-schema}

API 퍼징 작업을 시작할 때 OpenAPI 사양은 [게시된 스키마](https://github.com/OAI/OpenAPI-Specification/tree/master/schemas)에 대해 검증됩니다. 이 오류는 제공된 OpenAPI 사양에 검증 오류가 있을 때 표시됩니다:

```plaintext
Error, the OpenAPI document is not valid.
Errors were found during validation of the document using the published OpenAPI schema
```

OpenAPI 사양을 수동으로 생성할 때와 스키마가 생성될 때 오류가 발생할 수 있습니다.

자동으로 생성되는 OpenAPI 사양의 경우 검증 오류는 종종 누락된 코드 주석의 결과입니다.

**Error message**

- `Error, the OpenAPI document is not valid. Errors were found during validation of the document using the published OpenAPI schema`
  - `OpenAPI 2.0 schema validation error ...`
  - `OpenAPI 3.0.x schema validation error ...`

**해결 방법**

**For generated OpenAPI Specifications**

1. 검증 오류를 식별합니다.
   1. [Swagger Editor](https://editor.swagger.io/)를 사용하여 사양의 검증 문제를 식별합니다. Swagger Editor의 시각적 특성으로 인해 변경해야 할 사항을 더 쉽게 이해할 수 있습니다.
   1. 또는 로그 출력을 확인하고 스키마 검증 경고를 찾을 수 있습니다. 이들은 `OpenAPI 2.0 schema validation error` 또는 `OpenAPI 3.0.x schema validation error`와 같은 메시지로 접두사됩니다. 각 실패한 검증은 `location` 및 `description`에 대한 추가 정보를 제공합니다. JSON 스키마 검증 메시지는 복잡할 수 있으며, 편집기는 스키마 문서의 검증을 도와줄 수 있습니다.
1. 프레임워크/기술 스택이 사용하는 OpenAPI 생성에 대한 설명서를 검토합니다. 올바른 OpenAPI 문서를 생성하는 데 필요한 변경 사항을 식별합니다.
1. 검증 이슈를 해결한 후 파이프라인을 다시 실행합니다.

**For manually created OpenAPI Specifications**

1. 검증 오류를 식별합니다.
   1. 가장 간단한 해결 방법은 시각 도구를 사용하여 OpenAPI 문서를 편집하고 검증하는 것입니다. 예를 들어 [Swagger Editor](https://editor.swagger.io/)는 스키마 오류와 가능한 솔루션을 강조 표시합니다.
   1. 또는 로그 출력을 확인하고 스키마 검증 경고를 찾을 수 있습니다. 이들은 `OpenAPI 2.0 schema validation error` 또는 `OpenAPI 3.0.x schema validation error`와 같은 메시지로 접두사됩니다. 각 실패한 검증은 `location` 및 `description`에 대한 추가 정보를 제공합니다. 각 검증 실패를 수정한 후 OpenAPI 문서를 다시 제출합니다. JSON 스키마 검증 메시지는 복잡할 수 있으며, 편집기는 스키마 문서의 검증을 도와줄 수 있습니다.
1. 검증 이슈를 해결한 후 파이프라인을 다시 실행합니다.

## `Failed to start scanner session (version header not found)` {#failed-to-start-scanner-session-version-header-not-found}

API 퍼징 엔진은 스캐너 애플리케이션 구성 요소와의 연결을 설정할 수 없을 때 오류 메시지를 출력합니다. 오류 메시지는 `apifuzzer_fuzz` 작업의 작업 출력 창에 표시됩니다. 이 이슈의 일반적인 원인은 `FUZZAPI_API` 변수를 기본값에서 변경하는 것입니다.

**Error message**

- `Failed to start scanner session (version header not found).`

**해결 방법**

- `FUZZAPI_API` 변수를 `.gitlab-ci.yml` 파일에서 제거합니다. 값은 API 퍼징 CI/CD 템플릿에서 상속됩니다. 이 방법을 값을 수동으로 설정하는 대신 사용하세요.
- 변수를 제거하는 것이 불가능한 경우, [API 퍼징 CI/CD 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)의 최신 버전에서 이 값이 변경되었는지 확인하세요. 그렇다면 `.gitlab-ci.yml` 파일에서 값을 업데이트합니다.

## `Application cannot determine the base URL for the target API` {#application-cannot-determine-the-base-url-for-the-target-api}

API 퍼징 분석기는 OpenAPI 문서를 검사한 후 대상 API를 결정할 수 없을 때 오류 메시지를 출력합니다. 이 오류 메시지는 대상 API가 `.gitlab-ci.yml`파일에서 설정되지 않았거나, `environment_url.txt` 파일에서 사용 가능하지 않으며, OpenAPI 문서를 사용하여 계산할 수 없을 때 표시됩니다.

API 퍼징 분석기가 다양한 소스를 확인할 때 대상 API를 가져오려고 시도하는 우선순위 순서가 있습니다. 먼저 `FUZZAPI_TARGET_URL`을 사용하려고 시도합니다. 환경 변수가 설정되지 않은 경우, API 퍼징 분석기는 `environment_url.txt` 파일을 사용하려고 시도합니다. `environment_url.txt` 파일이 없으면 API 퍼징 분석기는 OpenAPI 문서 콘텐츠와 `FUZZAPI_OPENAPI`에 제공된 URL(URL이 제공된 경우)을 사용하여 대상 API를 계산하려고 시도합니다.

가장 적합한 해결 방법은 배포마다 대상 API가 변경되는지 여부에 따라 달라집니다:

- 대상 API가 각 배포마다 동일한 경우(정적 환경), [정적 환경 솔루션](#static-environment-solution)을 사용합니다.
- 대상 API가 각 배포마다 변경되면 [동적 환경 솔루션](#dynamic-environment-solutions)을 사용합니다.

### 정적 환경 솔루션 {#static-environment-solution}

이 솔루션은 대상 API URL이 변경되지 않는(정적인) 파이프라인에 적용됩니다.

**Add environmental variable**

대상 API가 동일하게 유지되는 환경의 경우, `FUZZAPI_TARGET_URL` 환경 변수를 사용하여 대상 URL을 지정해야 합니다. `.gitlab-ci.yml` 파일에서 변수 `FUZZAPI_TARGET_URL`을 추가합니다. 변수는 API 테스트 대상의 기본 URL로 설정해야 합니다. 예를 들어:

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OPENAPI: test-api-specification.json
```

### 동적 환경 솔루션 {#dynamic-environment-solutions}

동적 환경에서 대상 API는 각 배포마다 변경됩니다. 이 경우 둘 이상의 가능한 솔루션이 있습니다. 동적 환경을 다룰 때 `environment_url.txt` 파일 사용을 고려하세요.

**`environment_url.txt` 사용**

동적 환경을 지원하기 위해 대상 API URL이 각 파이프라인 중에 변경되는 경우, API 퍼징은 사용할 URL을 포함하는 `environment_url.txt` 파일 사용을 지원합니다. 이 파일은 리포지토리에 체크인되지 않고 대신 테스트 대상을 배포하는 작업에 의해 파이프라인 중에 생성되며 파이프라인의 나중의 작업에서 사용할 수 있는 아티팩트로 수집됩니다. `environment_url.txt` 파일을 생성하는 작업은 API 퍼징 작업 전에 실행되어야 합니다.

1. 테스트 대상 배포 작업을 수정하여 프로젝트 루트의 `environment_url.txt` 파일에 기본 URL을 추가합니다.
1. 테스트 대상 배포 작업을 수정하여 `environment_url.txt`을 아티팩트로 수집합니다.

예: 

```yaml
deploy-test-target:
  script:
    # Perform deployment steps
    # Create environment_url.txt (example)
    - echo http://${CI_PROJECT_ID}-${CI_ENVIRONMENT_SLUG}.example.org > environment_url.txt

  artifacts:
    paths:
      - environment_url.txt
```

## 잘못된 스키마로 OpenAPI 사용 {#use-openapi-with-an-invalid-schema}

문서가 잘못된 스키마로 자동 생성되거나 적절한 시간 내에 수동으로 편집할 수 없는 경우가 있습니다. 이러한 시나리오에서 API 퍼징은 변수 `FUZZAPI_OPENAPI_RELAXED_VALIDATION`을 설정하여 완화된 검증을 수행할 수 있습니다. 예기치 않은 동작을 방지하려면 완벽하게 규격을 준수하는 OpenAPI 문서를 제공하세요.

### 규격을 준수하지 않는 OpenAPI 파일 편집 {#edit-a-non-compliant-openapi-file}

편집기를 사용하여 OpenAPI 사양을 준수하지 않는 요소를 감지하고 수정합니다. 편집기는 일반적으로 문서 검증과 규격을 준수하는 OpenAPI 문서를 생성하기 위한 제안을 제공합니다. 권장 편집기는 다음과 같습니다:

| 편집기                                             | OpenAPI 2.0                   | OpenAPI 3.0.x                 | OpenAPI 3.1.x |
|----------------------------------------------------|-------------------------------|-------------------------------|---------------|
| [Swagger Editor](https://editor.swagger.io/)       | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="dotted-circle" >}} YAML, JSON |
| [Stoplight Studio](https://stoplight.io/solutions) | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON |

OpenAPI 문서가 수동으로 생성된 경우 편집기에 문서를 로드하고 규격을 준수하지 않는 항목을 모두 수정합니다. 문서가 자동으로 생성된 경우 편집기에 로드하여 스키마의 이슈를 식별한 후 애플리케이션으로 이동하여 사용 중인 프레임워크를 기반으로 수정을 수행합니다.

### OpenAPI 완화된 검증 활성화 {#enable-openapi-relaxed-validation}

완화된 검증은 OpenAPI 문서가 OpenAPI 사양을 충족할 수 없지만 여전히 다양한 도구에서 사용할 수 있는 충분한 콘텐츠가 있는 경우를 위한 것입니다. 검증이 수행되지만 문서 스키마와 관련하여 덜 엄격합니다.

API 퍼징은 OpenAPI 사양을 완벽하게 준수하지 않는 OpenAPI 문서를 계속 사용하려고 시도할 수 있습니다. API 퍼징 분석기에 완화된 검증을 수행하도록 지시하려면 변수 `FUZZAPI_OPENAPI_RELAXED_VALIDATION`을 임의의 값으로 설정합니다(예:):

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_OPENAPI_RELAXED_VALIDATION: 'On'
```

## `No operation in the OpenAPI document is consuming any supported media type` {#no-operation-in-the-openapi-document-is-consuming-any-supported-media-type}

API 퍼징은 OpenAPI 문서에 지정된 미디어 유형을 사용하여 요청을 생성합니다. 지원되는 미디어 유형이 부족하여 요청을 만들 수 없으면 오류가 발생합니다.

**Error message**

- `Error, no operation in the OpenApi document is consuming any supported media type. Check 'OpenAPI Specification' to check the supported media types.`

**해결 방법**

1. [OpenAPI 사양](configuration/enabling_the_analyzer.md#openapi-specification) 섹션에서 지원되는 미디어 유형을 검토합니다.
1. OpenAPI 문서를 편집하여 적어도 주어진 작업이 지원되는 미디어 유형 중 하나를 수락하도록 허용합니다. 또는 지원되는 미디어 유형을 OpenAPI 문서 수준에서 설정하고 모든 작업에 적용할 수 있습니다. 이 단계에서는 애플리케이션에서 지원되는 미디어 유형을 수락하도록 애플리케이션을 변경해야 할 수 있습니다.

## 오류: `The SSL connection could not be established, see inner exception.` {#error-the-ssl-connection-could-not-be-established-see-inner-exception}

API 퍼징은 오래된 프로토콜과 암호를 포함하여 광범위한 TLS 구성과 호환됩니다. 광범위한 지원에도 불구하고 다음과 같은 연결 오류가 발생할 수 있습니다:

```plaintext
Error, error occurred trying to download `<URL>`:
There was an error when retrieving content from Uri:' <URL>'.
Error:The SSL connection could not be established, see inner exception.
```

이 오류는 API 퍼징이 지정된 URL의 서버와 보안 연결을 설정하지 못했기 때문에 발생합니다.

이슈를 해결하려면:

오류 메시지의 호스트가 비TLS 연결을 지원하는 경우 구성에서 `https://`을 `http://`로 변경합니다. 예를 들어 다음 구성에서 오류가 발생하는 경우:

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: https://test-deployment/
  FUZZAPI_OPENAPI: https://specs/openapi.json
```

`FUZZAPI_OPENAPI`의 접두사를 `https://`에서 `http://`으로 변경합니다:

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: https://test-deployment/
  FUZZAPI_OPENAPI: http://specs/openapi.json
```

비TLS 연결을 사용하여 URL에 액세스할 수 없는 경우 지원팀에 문의하여 도움을 받으세요.

[testssl.sh 도구](https://testssl.sh/)로 조사를 가속화할 수 있습니다. bash 셸이 있고 영향을 받는 서버에 연결할 수 있는 머신에서:

1. 최신 릴리스 `zip` 또는 `tar.gz` 파일을 <https://github.com/drwetter/testssl.sh/releases>에서 다운로드하고 추출합니다.
1. `./testssl.sh --log https://specs`을 실행합니다.
1. 로그 파일을 지원 티켓에 첨부합니다.

## `ERROR: Job failed: failed to pull image` {#error-job-failed-failed-to-pull-image}

이 오류 메시지는 액세스하기 위해 인증이 필요한 컨테이너 레지스트리에서 이미지를 끌어올 때 발생합니다(공개 상태가 아님).

작업 콘솔 출력에서 오류는 다음과 같습니다:

```plaintext
Running with gitlab-runner 15.6.0~beta.186.ga889181a (a889181a)
  on blue-2.shared.runners-manager.gitlab.com/default XxUrkriX
Resolving secrets
00:00
Preparing the "docker+machine" executor
00:06
Using Docker executor with image registry.gitlab.com/security-products/api-security:2 ...
Starting service registry.example.com/my-target-app:latest ...
Pulling docker image registry.example.com/my-target-app:latest ...
WARNING: Failed to pull image with policy "always": Error response from daemon: Get https://registry.example.com/my-target-app/manifests/latest: unauthorized (manager.go:237:0s)
ERROR: Job failed: failed to pull image "registry.example.com/my-target-app:latest" with specified policies [always]: Error response from daemon: Get https://registry.example.com/my-target-app/manifests/latest: unauthorized (manager.go:237:0s)
```

**Error message**

- GitLab 15.9 이전에는 `ERROR: Job failed: failed to pull image` 다음 `Error response from daemon: Get IMAGE: unauthorized`입니다.

**해결 방법**

인증 자격 증명은 [프라이빗 컨테이너 레지스트리에서 이미지 액세스](../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry) 설명서 섹션에 설명된 방법을 사용하여 제공됩니다. 사용된 방법은 컨테이너 레지스트리 공급자와 그 구성에 의해 결정됩니다. Azure, Google Cloud(GCP), AWS 등의 클라우드 공급자와 같은 타사에서 제공하는 컨테이너 레지스트리를 사용하는 경우 공급자의 설명서를 확인하여 해당 컨테이너 레지스트리에 인증하는 방법에 대한 정보를 확인하세요.

다음 예제에서는 [정적으로 정의된 자격 증명](../../../ci/docker/using_docker_images.md#use-statically-defined-credentials) 인증 방법을 사용합니다. 이 예제에서 컨테이너 레지스트리는 `registry.example.com`이고 이미지는 `my-target-app:latest`입니다.

1. [`DOCKER_AUTH_CONFIG` 데이터를 결정하는 방법](../../../ci/docker/using_docker_images.md#determine-your-docker_auth_config-data)을 읽어 `DOCKER_AUTH_CONFIG`의 변수 값을 계산하는 방법을 이해합니다. 구성 변수 `DOCKER_AUTH_CONFIG`에는 적절한 인증 정보를 제공하는 Docker JSON 구성이 포함되어 있습니다. 예를 들어 프라이빗 컨테이너 레지스트리에 액세스하려면 `registry.example.com`을 자격 증명 `abcdefghijklmn`으로 사용하며, Docker JSON은 다음과 같습니다:

   ```json
   {
       "auths": {
           "registry.example.com": {
               "auth": "abcdefghijklmn"
           }
       }
   }
   ```

1. `DOCKER_AUTH_CONFIG`을 CI/CD 변수로 추가합니다. 구성 변수를 `.gitlab-ci.yml` 파일에 직접 추가하는 대신 프로젝트 [CI/CD 변수](../../../ci/variables/_index.md#for-a-project)를 만들어야 합니다.
1. 작업을 다시 실행하면 정적으로 정의된 자격 증명이 이제 프라이빗 컨테이너 레지스트리 `registry.example.com`에 로그인하는 데 사용되고 이미지 `my-target-app:latest`을 끌어올 수 있습니다. 성공한 경우 작업 콘솔은 다음과 같은 출력을 표시합니다:

   ```log
   Running with gitlab-runner 15.6.0~beta.186.ga889181a (a889181a)
     on blue-4.shared.runners-manager.gitlab.com/default J2nyww-s
   Resolving secrets
   00:00
   Preparing the "docker+machine" executor
   00:56
   Using Docker executor with image registry.gitlab.com/security-products/api-security:2 ...
   Starting service registry.example.com/my-target-app:latest ...
   Authenticating with credentials from $DOCKER_AUTH_CONFIG
   Pulling docker image registry.example.com/my-target-app:latest ...
   Using docker image sha256:139c39668e5e4417f7d0eb0eeb74145ba862f4f3c24f7c6594ecb2f82dc4ad06 for registry.example.com/my-target-app:latest with digest registry.example.com/my-target-
   app@sha256:2b69fc7c3627dbd0ebaa17674c264fcd2f2ba21ed9552a472acf8b065d39039c ...
   Waiting for services to be up and running (timeout 30 seconds)...
   ```

## 오류: `sudo: The "no new privileges" flag is set, which prevents sudo from running as root.` {#error-sudo-the-no-new-privileges-flag-is-set-which-prevents-sudo-from-running-as-root}

분석기의 v5부터 기본적으로 루트가 아닌 사용자가 사용됩니다. 이를 위해서는 권한이 있는 작업을 수행할 때 `sudo`을 사용해야 합니다.

이 오류는 실행 중인 컨테이너가 새 권한을 얻지 못하도록 하는 특정 컨테이너 데몬 설정으로 발생합니다. 대부분의 설정에서 이것은 기본 구성이 아니며, 특히 보안 강화 가이드의 일부로 구성된 것입니다.

**Error message**

이 이슈는 `before_script` 또는 `FUZZAPI_PRE_SCRIPT`이 실행될 때 생성되는 오류 메시지로 식별할 수 있습니다:

```shell
$ sudo apk add nodejs

sudo: The "no new privileges" flag is set, which prevents sudo from running as root.

sudo: If sudo is running in a container, you may need to adjust the container configuration to disable the flag.
```

**해결 방법**

이 이슈는 다음과 같은 방법으로 해결할 수 있습니다:

- 컨테이너를 `root` 사용자로 실행합니다. 모든 경우에서 작동하지 않을 수 있으므로 이 구성을 테스트하는 것이 좋습니다. 이를 위해 CICD 구성을 수정하고 작업 출력을 확인하여 `whoami`가 `root`을 반환하고 `gitlab`을 반환하지 않는지 확인합니다. `gitlab`이 표시되면 다른 해결 방법을 사용합니다. 테스트 후 `before_script`을 제거할 수 있습니다.

  ```yaml
  apifuzzer_fuzz:
    image:
      name: $SECURE_ANALYZERS_PREFIX/$FUZZAPI_IMAGE:$FUZZAPI_VERSION$FUZZAPI_IMAGE_SUFFIX
      docker:
        user: root
   before_script:
     - whoami
  ```

  _작업 콘솔 출력 예:_

  ```log
  Executing "step_script" stage of the job script
  Using docker image sha256:8b95f188b37d6b342dc740f68557771bb214fe520a5dc78a88c7a9cc6a0f9901 for registry.gitlab.com/security-products/api-security:5 with digest registry.gitlab.com/security-products/api-security@sha256:092909baa2b41db8a7e3584f91b982174772abdfe8ceafc97cf567c3de3179d1 ...
  $ whoami
  root
  $ /peach/analyzer-api-fuzzing
  17:17:14 [INF] API Security: Gitlab API Security
  17:17:14 [INF] API Security: -------------------
  17:17:14 [INF] API Security:
  17:17:14 [INF] API Security: version: 5.7.0
  ```

- 컨테이너를 래핑하고 빌드 시간에 종속성을 추가합니다. 이 옵션은 루트보다 낮은 권한으로 실행할 수 있다는 이점이 있으며, 일부 고객의 경우 요구 사항일 수 있습니다.

  1. 기존 이미지를 래핑하는 새로운 `Dockerfile`을 생성합니다.

     ```yaml
     ARG SECURE_ANALYZERS_PREFIX
     ARG FUZZAPI_IMAGE
     ARG FUZZAPI_VERSION
     ARG FUZZAPI_IMAGE_SUFFIX
     FROM $SECURE_ANALYZERS_PREFIX/$FUZZAPI_IMAGE:$FUZZAPI_VERSION$FUZZAPI_IMAGE_SUFFIX
     USER root

     RUN pip install ...
     RUN apk add ...

     USER gitlab
     ```

  1. 새 이미지를 빌드하고 API 퍼징 작업을 시작하기 전에 로컬 컨테이너 레지스트리로 푸시합니다. 작업이 완료된 후 이미지를 제거해야 합니다.

     ```shell
     TARGET_NAME=apifuzz-$CI_COMMIT_SHA
     docker build -t $TARGET_IMAGE \
       --build-arg "SECURE_ANALYZERS_PREFIX=$SECURE_ANALYZERS_PREFIX" \
       --build-arg "FUZZAPI_IMAGE=$APISEC_IMAGE" \
       --build-arg "FUZZAPI_VERSION=$APISEC_VERSION" \
       --build-arg "FUZZAPI_IMAGE_SUFFIX=$APISEC_IMAGE_SUFFIX" \
       .
     docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
     docker push $TARGET_IMAGE
     ```

  1. `apifuzzer_fuzz` 작업을 확장하고 새 이미지 이름을 사용합니다.

     ```yaml
     apifuzzer_fuzz:
       image: apifuzz-$CI_COMMIT_SHA
     ```

  1. 레지스트리에서 임시 컨테이너를 제거합니다. 컨테이너 이미지를 제거하는 방법에 대한 정보는 [이 설명서 페이지를 참조하세요.](../../packages/container_registry/delete_container_registry_images.md)

- GitLab 러너 구성을 변경하여 no-new-privileges 플래그를 비활성화합니다. 이는 보안에 영향을 미칠 수 있으므로 운영 및 보안 팀과 논의해야 합니다.

## `Index was outside the bounds of the array at Peach.Web.Runner.Services.RunnerOptions.GetHeaders()` {#index-was-outside-the-bounds-of-the-array-at-peachwebrunnerservicesrunneroptionsgetheaders}

이 오류 메시지는 API 퍼징 분석기가 `FUZZAPI_REQUEST_HEADERS` 또는 `FUZZAPI_REQUEST_HEADERS_BASE64` 구성 변수의 값을 구문 분석할 수 없음을 나타냅니다.

**Error message**

이 이슈는 두 가지 오류 메시지로 식별할 수 있습니다. 첫 번째 오류 메시지는 작업 콘솔 출력에 표시되고 두 번째는 `gl-api-security-scanner.log` 파일에 표시됩니다.

_작업 콘솔의 오류 메시지:_

```plaintext
05:48:38 [ERR] API Security: Testing failed: An unexpected exception occurred: Index was outside the bounds of the array.
```

_`gl_api_security-scanner.log`의 오류 메시지:_

```plaintext
08:45:43.616 [ERR] <Peach.Web.Core.Services.WebRunnerMachine> Unexpected exception in WebRunnerMachine::Run()
System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at Peach.Web.Runner.Services.RunnerOptions.GetHeaders() in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Runner/Services/[RunnerOptions.cs:line 362
   at Peach.Web.Runner.Services.RunnerService.Start(Job job, IRunnerOptions options) in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Runner/Services/RunnerService.cs:line 67
   at Peach.Web.Core.Services.WebRunnerMachine.Run(IRunnerOptions runnerOptions, CancellationToken token) in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Core/Services/WebRunnerMachine.cs:line 321
08:45:43.634 [WRN] <Peach.Web.Core.Services.WebRunnerMachine> * Session failed: An unexpected exception occurred: Index was outside the bounds of the array.
08:45:43.677 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Finished testing. Performed a total of 0 requests.
```

**해결 방법**

이 이슈는 형식이 잘못된 `FUZZAPI_REQUEST_HEADERS` 또는 `FUZZAPI_REQUEST_HEADERS_BASE64` 변수로 인해 발생합니다. 예상 형식은 `Header: value` 구성의 하나 이상의 헤더이며 쉼표로 분리됩니다. 구문을 수정하여 예상된 형식과 일치하도록 하세요.

_유효한 예:_

- `Authorization: Bearer XYZ`
- `X-Custom: Value,Authorization: Bearer XYZ`

_유효하지 않은 예:_

- `Header:,value`
- `HeaderA: value,HeaderB:,HeaderC: value`
- `Header`
