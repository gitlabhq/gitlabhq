---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API 보안 테스트 작업 문제 해결
---

## API 보안 테스트 작업이 N시간 후에 시간 초과되는 경우 {#api-security-testing-job-times-out-after-n-hours}

대규모 리포지토리의 경우 API 보안 테스트 작업이 [Linux의 소형 호스팅 러너](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64)에서 시간 초과될 수 있으며, 이는 기본적으로 설정됩니다. 작업에서 이 문제가 발생하면 [더 큰 러너](performance.md#using-a-larger-runner)로 확장해야 합니다.

지원을 위해 다음 설명서 섹션을 참고하세요:

- [성능 튜닝 및 테스트 속도](performance.md)
- [더 큰 러너 사용](performance.md#using-a-larger-runner)
- [경로별 작업 제외](configuration/customizing_analyzer_settings.md#exclude-paths)
- [느린 작업 제외](performance.md#excluding-slow-operations)

## API 보안 테스트 작업이 완료하는 데 너무 오래 걸리는 경우 {#api-security-testing-job-takes-too-long-to-complete}

[성능 튜닝 및 테스트 속도](performance.md) 참고

## 오류: `Error waiting for DAST API 'http://127.0.0.1:5000' to become available` {#error-error-waiting-for-dast-api-http1270015000-to-become-available}

v1.6.196 이전 버전의 API 보안 테스트 분석기에는 특정 조건에서 백그라운드 프로세스가 실패할 수 있는 버그가 있습니다. 해결 방법은 API 보안 테스트 분석기를 최신 버전으로 업데이트하는 것입니다.

버전 정보는 `dast_api` 작업에 대한 작업 세부 정보에서 찾을 수 있습니다.

v1.6.196 이상 버전에서 이슈가 발생하면 지원팀에 문의하여 다음 정보를 제공하세요:

1. 이 이슈 해결 섹션을 참조하고 Dynamic Analysis Team으로 에스컬레이션하도록 요청하세요.
1. 작업의 전체 콘솔 출력.
1. `gl-api-security-scanner.log` 파일(작업 아티팩트로 사용 가능). 작업 세부 정보 페이지의 오른쪽 패널에서 **탐색**을 선택하세요.
1. `dast_api` 작업 정의(파일 `.gitlab-ci.yml`에서).

## `Failed to start scanner session (version header not found)` {#failed-to-start-scanner-session-version-header-not-found}

API 보안 테스트 엔진은 스캐너 애플리케이션 구성 요소와 연결을 설정할 수 없을 때 오류 메시지를 출력합니다. 오류 메시지는 `dast_api` 작업의 작업 출력 창에 표시됩니다. 이 이슈의 일반적인 원인은 `APISEC_API` 변수를 기본값에서 변경하는 것입니다.

**Error message**

- `Failed to start scanner session (version header not found).`

**해결 방법**

- `APISEC_API` 변수를 `.gitlab-ci.yml` 파일에서 제거하세요. 값은 API 보안 테스트 CI/CD 템플릿에서 상속됩니다. 수동으로 값을 설정하는 대신 이 방법을 사용하세요.
- 변수를 제거할 수 없는 경우, 최신 버전의 [API 보안 테스트 CI/CD 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)에서 이 값이 변경되었는지 확인하세요. 그렇다면 `.gitlab-ci.yml` 파일에서 값을 업데이트하세요.

## `Failed to start session with scanner. Please retry, and if the problem persists reach out to support.` {#failed-to-start-session-with-scanner-please-retry-and-if-the-problem-persists-reach-out-to-support}

API 보안 테스트 엔진은 스캐너 애플리케이션 구성 요소와 연결을 설정할 수 없을 때 오류 메시지를 출력합니다. 오류 메시지는 `dast_api` 작업의 작업 출력 창에 표시됩니다. 이 이슈의 일반적인 원인은 백그라운드 구성 요소가 선택된 포트를 사용할 수 없다는 것입니다(이미 사용 중). 타이밍이 관여하는 경우(경합 조건) 이 오류가 간헐적으로 발생할 수 있습니다. 이 이슈는 다른 서비스가 컨테이너에 매핑되어 포트 충돌을 야기하는 Kubernetes 환경에서 가장 자주 발생합니다.

해결 방법을 진행하기 전에, 오류 메시지가 포트가 이미 사용 중이었기 때문에 생성되었음을 확인하는 것이 중요합니다. 이것이 원인임을 확인하려면:

1. 작업 콘솔로 이동하세요.
1. `gl-api-security-scanner.log` 아티팩트를 찾으세요. **다운로드**를 선택하여 모든 아티팩트를 다운로드하고 파일을 검색하거나, **탐색**을 선택하여 직접 검색을 시작할 수 있습니다.
1. `gl-api-security-scanner.log` 파일을 텍스트 편집기에서 열어보세요.
1. 포트가 이미 사용 중이었기 때문에 오류 메시지가 생성되었다면 파일에서 다음과 같은 메시지를 볼 수 있어야 합니다:

   ```log
   Failed to bind to address http://127.0.0.1:5500: address already in use.
   ```

이전 메시지의 `http://[::]:5000` 텍스트는 경우에 따라 다를 수 있으며, 예를 들어 `http://[::]:5500` 또는 `http://127.0.0.1:5500`일 수 있습니다. 오류 메시지의 나머지 부분이 동일한 한, 포트가 이미 사용 중이었다고 가정하는 것이 안전합니다.

포트가 이미 사용 중이었다는 증거를 찾지 못한 경우, 작업 콘솔 출력에 표시되는 동일한 오류 메시지를 다루는 다른 문제 해결 섹션을 확인하세요. 더 이상 옵션이 없으면 적절한 채널을 통해 [지원을 받거나 개선을 요청](_index.md#get-support-or-request-an-improvement)하세요.

포트가 이미 사용 중이었기 때문에 이슈가 발생했다는 것을 확인할 수 있으면, `APISEC_API_PORT` CI/CD 변수를 사용하여 스캐너 백그라운드 구성 요소의 다른 포트를 지정하세요.

**해결 방법**

1. `.gitlab-ci.yml` 파일이 `APISEC_API_PORT` 구성 변수를 정의하는지 확인하세요.
1. `APISEC_API_PORT` 변수의 값을 1024보다 큰 사용 가능한 포트 번호로 업데이트하세요. 제안된 포트 번호가 GitLab에서 사용하지 않는지 확인해야 합니다. [패키지 기본값](../../../administration/package_information/defaults.md#ports)에서 GitLab에서 사용하는 포트의 전체 목록을 참고하세요.

## `Application cannot determine the base URL for the target API` {#application-cannot-determine-the-base-url-for-the-target-api}

API 보안 테스트 엔진은 OpenAPI 문서를 검사한 후 대상 API를 결정할 수 없을 때 오류 메시지를 출력합니다. 이 오류 메시지는 `.gitlab-ci.yml` 파일에서 대상 API가 설정되지 않았거나 `environment_url.txt` 파일에서 사용할 수 없으며 OpenAPI 문서를 사용하여 계산할 수 없을 때 표시됩니다.

API 보안 테스트 엔진이 다양한 소스를 확인할 때 대상 API를 가져오려고 시도하는 순서가 있습니다. 먼저 `APISEC_TARGET_URL`을 사용하려고 시도합니다. 환경 변수가 설정되지 않았으면 API 보안 테스트 엔진은 `environment_url.txt` 파일을 사용하려고 시도합니다. `environment_url.txt` 파일이 없으면 API 보안 테스트 엔진은 OpenAPI 문서 콘텐츠와 `APISEC_OPENAPI`에서 제공하는 URL(URL이 제공되는 경우)을 사용하여 대상 API를 계산하려고 시도합니다.

가장 적합한 해결 방법은 대상 API가 배포마다 변경되는지 여부에 따라 달라집니다. 정적 환경에서 대상 API는 배포마다 동일하므로, 이 경우 [정적 환경 해결 방법](#static-environment-solution)을 참고하세요. 대상 API가 배포마다 변경되는 경우 [동적 환경 해결 방법](#dynamic-environment-solutions)을 적용해야 합니다.

## API 보안 테스트 작업이 작업에서 일부 경로를 제외하는 경우 {#api-security-testing-job-excludes-some-paths-from-operations}

일부 경로가 작업에서 제외되고 있다면, 다음을 확인하세요:

- `DAST_API_EXCLUDE_URLS` 변수가 테스트하려는 작업을 제외하도록 구성되지 않았는지 확인하세요.
- `consumes` 배열이 정의되어 있고 대상 정의 JSON 파일에 유효한 유형이 있는지 확인하세요.

  예제 정의는 [예제 프로젝트 대상 정의 파일](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-example/-/blob/12e2b039d08208f1dd38a1e7c52b0bda848bb449/rest_target_openapi.json?plain=1#L13)을 참고하세요.

### 정적 환경 해결 방법 {#static-environment-solution}

이 해결 방법은 대상 API URL이 변경되지 않는(정적인) 파이프라인을 위한 것입니다.

**환경 변수 추가**

대상 API가 동일하게 유지되는 환경의 경우 `APISEC_TARGET_URL` 환경 변수를 사용하여 대상 URL을 지정하세요. `.gitlab-ci.yml`에서 `APISEC_TARGET_URL` 변수를 추가하세요. 변수는 API 테스트 대상의 기본 URL로 설정해야 합니다. 예를 들어:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OPENAPI: test-api-specification.json
```

### 동적 환경 해결 방법 {#dynamic-environment-solutions}

동적 환경에서 대상 API는 배포마다 변경됩니다. 이 경우 동적 환경을 다룰 때 `environment_url.txt` 파일을 사용하는 것을 포함하여 둘 이상의 해결 방법이 있습니다.

**`environment_url.txt` 사용**

대상 API URL이 각 파이프라인 중에 변경되는 동적 환경을 지원하려면 API 보안 테스트 엔진은 사용할 URL을 포함하는 `environment_url.txt` 파일을 지원합니다. 이 파일은 리포지토리에 체크인되지 않으며, 대신 테스트 대상을 배포하는 작업에 의해 파이프라인 중에 생성되고 파이프라인의 이후 작업에서 사용할 수 있는 아티팩트로 수집됩니다. `environment_url.txt` 파일을 생성하는 작업은 API 보안 테스트 엔진 작업보다 먼저 실행되어야 합니다.

1. 테스트 대상 배포 작업을 수정하여 프로젝트 루트의 `environment_url.txt` 파일에 기본 URL을 추가하세요.
1. 테스트 대상 배포 작업을 수정하여 `environment_url.txt`을 아티팩트로 수집하세요.

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

## 유효하지 않은 스키마로 OpenAPI 사용 {#use-openapi-with-an-invalid-schema}

OpenAPI 문서는 때때로 유효하지 않은 스키마로 자동 생성되거나 적절한 시간 내에 수동으로 편집할 수 없습니다. 이러한 시나리오에서는 `APISEC_OPENAPI_RELAXED_VALIDATION` 변수를 설정하여 API 보안 테스트가 완화된 유효성 검사를 수행할 수 있습니다. 예상치 못한 동작을 방지하려면 완전히 호환되는 OpenAPI 문서를 제공하세요.

### 비준수 OpenAPI 파일 편집 {#edit-a-non-compliant-openapi-file}

편집기를 사용하여 OpenAPI 사양을 준수하지 않는 요소를 감지하고 수정하세요. 편집기는 일반적으로 문서 유효성 검사를 제공하고 스키마 호환 OpenAPI 문서를 생성하기 위한 제안을 제공합니다. 권장되는 편집기는 다음을 포함합니다:

| 편집기 | OpenAPI 2.0 | OpenAPI 3.0.x | OpenAPI 3.1.x |
|--------|-------------|---------------|---------------|
| [Stoplight Studio](https://stoplight.io/solutions) | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON |
| [Swagger Editor](https://editor.swagger.io/)       | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="dotted-circle" >}} YAML, JSON |

OpenAPI 문서가 수동으로 생성된 경우, 문서를 편집기에 로드하고 준수하지 않는 항목을 모두 수정하세요. 문서가 자동으로 생성된 경우, 편집기에 로드하여 스키마의 이슈를 식별하세요. 그런 다음 사용 중인 프레임워크를 기반으로 애플리케이션의 이슈를 수정하세요.

### OpenAPI 완화된 유효성 검사 활성화 {#enable-openapi-relaxed-validation}

완화된 유효성 검사는 OpenAPI 문서가 OpenAPI 사양을 충족할 수 없지만 다양한 도구에서 사용할 수 있을 만큼 충분한 콘텐츠가 있는 경우를 위한 것입니다. 유효성 검사가 수행되지만 문서 스키마와 관련하여 덜 엄격합니다.

API 보안 테스트는 OpenAPI 사양을 완전히 준수하지 않는 OpenAPI 문서를 계속 사용하려고 시도할 수 있습니다. API 보안 테스트가 완화된 유효성 검사를 수행하도록 지시하려면 `APISEC_OPENAPI_RELAXED_VALIDATION` 변수를 임의의 값으로 설정하세요. 예를 들어:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_OPENAPI_RELAXED_VALIDATION: 'On'
```

## `No operation in the OpenAPI document is consuming any supported media type` {#no-operation-in-the-openapi-document-is-consuming-any-supported-media-type}

API 보안 테스트는 OpenAPI 문서에 지정된 미디어 유형을 사용하여 요청을 생성합니다. 지원되는 미디어 유형이 부족하여 요청을 생성할 수 없으면 오류가 발생합니다.

**Error message**

- `Error, no operation in the OpenApi document is consuming any supported media type. Check 'OpenAPI Specification' to check the supported media types.`

**해결 방법**

1. [OpenAPI 사양](configuration/enabling_the_analyzer.md#openapi-specification) 섹션에서 지원되는 미디어 유형을 검토하세요.
1. OpenAPI 문서를 편집하여 지정된 작업이 지원되는 미디어 유형 중 적어도 하나를 수락하도록 허용하세요. 또는 지원되는 미디어 유형을 OpenAPI 문서 레벨에서 설정하고 모든 작업에 적용할 수 있습니다. 이 단계에는 지원되는 미디어 유형이 애플리케이션에서 수락되도록 보장하기 위해 애플리케이션에서 변경이 필요할 수 있습니다.

## 오류: `The SSL connection could not be established, see inner exception.` {#error-the-ssl-connection-could-not-be-established-see-inner-exception}

API 보안 테스트는 구식 프로토콜 및 암호를 포함한 광범위한 TLS 구성과 호환됩니다. 광범위한 지원에도 불구하고 다음과 같은 연결 오류가 발생할 수 있습니다:

```plaintext
Error, error occurred trying to download `<URL>`:
There was an error when retrieving content from Uri:' <URL>'.
Error:The SSL connection could not be established, see inner exception.
```

이 오류는 API 보안 테스트가 주어진 URL의 서버와 보안 연결을 설정할 수 없기 때문에 발생합니다.

이슈를 해결하려면:

오류 메시지의 호스트가 비-TLS 연결을 지원하면 구성에서 `https://`을 `http://`로 변경하세요. 예를 들어, 다음 구성에서 오류가 발생하면:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: https://test-deployment/
  APISEC_OPENAPI: https://specs/openapi.json
```

`APISEC_OPENAPI`의 접두사를 `https://`에서 `http://`로 변경하세요:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: https://test-deployment/
  APISEC_OPENAPI: http://specs/openapi.json
```

비-TLS 연결을 사용하여 URL에 액세스할 수 없으면 지원팀에 문의하세요.

[testssl.sh 도구](https://testssl.sh/)로 조사를 가속화할 수 있습니다. bash 셸이 있고 영향을 받는 서버에 연결할 수 있는 머신에서:

1. <https://github.com/drwetter/testssl.sh/releases>에서 최신 릴리스 `zip` 또는 `tar.gz` 파일을 다운로드하고 추출하세요.
1. `./testssl.sh --log https://specs`을 실행하세요.
1. 로그 파일을 지원 티켓에 첨부하세요.

## `ERROR: Job failed: failed to pull image` {#error-job-failed-failed-to-pull-image}

이 오류 메시지는 인증이 필요한(공개 상태가 아닌) 컨테이너 레지스트리에서 이미지를 가져올 때 발생합니다.

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

- GitLab 15.9 이하에서 `ERROR: Job failed: failed to pull image`은 `Error response from daemon: Get IMAGE: unauthorized`로 표시됩니다.

**해결 방법**

인증 자격 증명은 [개인 컨테이너 레지스트리에서 이미지 액세스](../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry) 설명서 섹션에 설명된 방법을 사용하여 제공됩니다. 사용되는 방법은 컨테이너 레지스트리 공급자 및 해당 구성에 따라 결정됩니다. Azure, Google Cloud (GCP), AWS 등과 같은 타사에서 제공하는 컨테이너 레지스트리를 사용하는 경우, 해당 컨테이너 레지스트리에 인증하는 방법에 대한 정보는 공급자의 설명서를 확인하세요.

다음 예제는 [정적으로 정의된 자격 증명](../../../ci/docker/using_docker_images.md#use-statically-defined-credentials) 인증 방법을 사용합니다. 이 예제에서 컨테이너 레지스트리는 `registry.example.com`이고 이미지는 `my-target-app:latest`입니다.

1. [`DOCKER_AUTH_CONFIG` 데이터를 결정하는 방법을 읽기](../../../ci/docker/using_docker_images.md#determine-your-docker_auth_config-data)를 통해 `DOCKER_AUTH_CONFIG`의 변수 값을 계산하는 방법을 이해하세요. 구성 변수 `DOCKER_AUTH_CONFIG`는 적절한 인증 정보를 제공하는 Docker JSON 구성을 포함합니다. 예를 들어, 개인 컨테이너 레지스트리 `registry.example.com`에 `abcdefghijklmn` 자격 증명으로 액세스하려면 Docker JSON은 다음과 같습니다:

   ```json
   {
       "auths": {
           "registry.example.com": {
               "auth": "abcdefghijklmn"
           }
       }
   }
   ```

1. `DOCKER_AUTH_CONFIG`를 CI/CD 변수로 추가하세요. `.gitlab-ci.yml` 파일에 구성 변수를 직접 추가하는 대신 프로젝트 [CI/CD 변수](../../../ci/variables/_index.md#for-a-project)를 생성해야 합니다.
1. 작업을 다시 실행하면 정적으로 정의된 자격 증명이 이제 개인 컨테이너 레지스트리 `registry.example.com`에 로그인하는 데 사용되고, `my-target-app:latest` 이미지를 가져올 수 있게 됩니다. 성공하면 작업 콘솔에 다음과 같은 출력이 표시됩니다:

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

## 연속 스캔 간에 다양한 취약성 결과 {#differing-vulnerability-results-between-consecutive-scans}

코드 또는 구성이 변경되지 않은 상태에서도 연속 스캔이 다양한 취약성 결과를 반환할 수 있습니다. 이는 주로 대상 환경 및 해당 상태와 관련된 예측 불가능성과 스캐너에서 전송된 요청의 병렬화로 인한 것입니다. 스캐너는 스캔 시간을 최적화하기 위해 여러 요청을 병렬로 전송하며, 이는 대상 서버가 요청에 응답하는 정확한 순서를 예측할 수 없음을 의미합니다.

요청과 응답 사이의 시간 길이로 감지되는 타이밍 공격 취약성은 서버가 로드 상태이고 주어진 임계값 내에서 테스트에 응답할 수 없는 경우 감지될 수 있습니다. 서버가 로드 상태가 아닐 때 동일한 스캔 실행은 이러한 취약성에 대한 긍정적 결과를 반환하지 않을 수 있으며, 다양한 결과로 이어집니다. 대상 서버 프로파일링, [성능 튜닝 및 테스트 속도](performance.md), 테스트 중 최적 서버 성능에 대한 기준선 설정은 위의 요인으로 인해 거짓 양성이 나타날 수 있는 위치를 파악하는 데 도움이 될 수 있습니다.

## 오류: `sudo: The "no new privileges" flag is set, which prevents sudo from running as root.` {#error-sudo-the-no-new-privileges-flag-is-set-which-prevents-sudo-from-running-as-root}

분석기의 v5부터는 기본적으로 루트가 아닌 사용자가 사용됩니다. 이는 권한이 있는 작업을 수행할 때 `sudo`을 사용해야 합니다.

이 오류는 실행 중인 컨테이너가 새 권한을 얻지 못하도록 하는 특정 컨테이너 데몬 설정에서 발생합니다. 대부분의 설정에서 이는 기본 구성이 아니며, 보안 강화 가이드의 일부로 특별히 구성된 것입니다.

**Error message**

이 이슈는 `before_script` 또는 `APISEC_PRE_SCRIPT`이 실행될 때 생성되는 오류 메시지로 식별할 수 있습니다:

```shell
$ sudo apk add nodejs

sudo: The "no new privileges" flag is set, which prevents sudo from running as root.

sudo: If sudo is running in a container, you may need to adjust the container configuration to disable the flag.
```

**해결 방법**

이 이슈는 다음과 같은 방법으로 해결할 수 있습니다:

- `root` 사용자로 컨테이너를 실행하세요. 모든 경우에 작동하지 않을 수 있으므로 이 구성을 테스트해야 합니다. CI/CD 구성을 수정하고 작업 출력을 확인하여 `whoami`이 `root`을 반환하는지 확인하고 `gitlab`이 아님을 확인하여 수행할 수 있습니다. `gitlab`이 표시되면 다른 해결 방법을 사용하세요. 테스트에서 변경이 성공했음을 확인한 후 `before_script`을 제거할 수 있습니다.

  ```yaml
  api_security:
    image:
      name: $SECURE_ANALYZERS_PREFIX/$APISEC_IMAGE:$APISEC_VERSION$APISEC_IMAGE_SUFFIX
      docker:
        user: root
   before_script:
     - whoami
  ```

  _작업 콘솔 출력 예제:_

  ```log
  Executing "step_script" stage of the job script
  Using docker image sha256:8b95f188b37d6b342dc740f68557771bb214fe520a5dc78a88c7a9cc6a0f9901 for registry.gitlab.com/security-products/api-security:5 with digest registry.gitlab.com/security-products/api-security@sha256:092909baa2b41db8a7e3584f91b982174772abdfe8ceafc97cf567c3de3179d1 ...
  $ whoami
  root
  $ /peach/analyzer-api-security
  17:17:14 [INF] API Security: Gitlab API Security
  17:17:14 [INF] API Security: -------------------
  17:17:14 [INF] API Security:
  17:17:14 [INF] API Security: version: 5.7.0
  ```

- 컨테이너를 래핑하고 빌드 시간에 종속성을 추가하세요. 이 옵션은 일부 고객에게 요구 사항일 수 있는 루트보다 낮은 권한으로 실행할 수 있다는 이점이 있습니다.

  1. 기존 이미지를 래핑하는 새 `Dockerfile`을 생성하세요.

     ```yaml
     ARG SECURE_ANALYZERS_PREFIX
     ARG APISEC_IMAGE
     ARG APISEC_VERSION
     ARG APISEC_IMAGE_SUFFIX
     FROM $SECURE_ANALYZERS_PREFIX/$APISEC_IMAGE:$APISEC_VERSION$APISEC_IMAGE_SUFFIX
     USER root

     RUN pip install ...
     RUN apk add ...

     USER gitlab
     ```

  1. API 보안 테스트 작업이 시작되기 전에 새 이미지를 빌드하고 로컬 컨테이너 레지스트리로 푸시하세요. `api_security` 작업이 완료된 후 이미지를 제거해야 합니다.

     ```shell
     TARGET_NAME=apisec-$CI_COMMIT_SHA
     docker build -t $TARGET_IMAGE \
       --build-arg "SECURE_ANALYZERS_PREFIX=$SECURE_ANALYZERS_PREFIX" \
       --build-arg "APISEC_IMAGE=$APISEC_IMAGE" \
       --build-arg "APISEC_VERSION=$APISEC_VERSION" \
       --build-arg "APISEC_IMAGE_SUFFIX=$APISEC_IMAGE_SUFFIX" \
       .
     docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
     docker push $TARGET_IMAGE
     ```

  1. `api_security` 작업을 확장하고 새 이미지 이름을 사용하세요.

     ```yaml
     api_security:
       image: apisec-$CI_COMMIT_SHA
     ```

  1. 컨테이너 레지스트리에서 임시 컨테이너를 제거하세요. [컨테이너 이미지 제거에 대한 정보는 이 설명서 페이지를 참고하세요.](../../packages/container_registry/delete_container_registry_images.md)

- GitLab 러너 구성을 변경하여 no-new-privileges 플래그를 비활성화하세요. 이는 보안 영향을 미칠 수 있으며 운영 및 보안 팀과 논의해야 합니다.

## `Index was outside the bounds of the array.    at Peach.Web.Runner.Services.RunnerOptions.GetHeaders()` {#index-was-outside-the-bounds-of-the-array----at-peachwebrunnerservicesrunneroptionsgetheaders}

이 오류 메시지는 API 보안 테스트 분석기가 `APISEC_REQUEST_HEADERS` 또는 `APISEC_REQUEST_HEADERS_BASE64` 구성 변수의 값을 구문 분석할 수 없음을 나타냅니다.

**Error message**

이 이슈는 두 가지 오류 메시지로 식별할 수 있습니다. 첫 번째 오류 메시지는 작업 콘솔 출력에 표시되고 두 번째는 `gl-api-security-scanner.log` 파일에 표시됩니다.

_작업 콘솔 오류 메시지:_

```plaintext
05:48:38 [ERR] API Security: Testing failed: An unexpected exception occurred: Index was outside the bounds of the array.
```

_`gl_api_security-scanner.log`에서 오류 메시지:_

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

이 이슈는 형식이 잘못된 `APISEC_REQUEST_HEADERS` 또는 `APISEC_REQUEST_HEADERS_BASE64` 변수로 인해 발생합니다. 예상 형식은 쉼표로 구분된 `Header: value` 구성의 하나 이상의 헤더입니다. 해결 방법은 구문을 예상되는 것과 일치하도록 수정하는 것입니다.

_유효한 예제:_

- `Authorization: Bearer XYZ`
- `X-Custom: Value,Authorization: Bearer XYZ`

_잘못된 예제:_

- `Header:,value`
- `HeaderA: value,HeaderB:,HeaderC: value`
- `Header`
