---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용 가능한 CI/CD 변수 및 설정 파일
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/450445) 템플릿 이름: `DAST-API.gitlab-ci.yml`에서 `API-Security.gitlab-ci.yml`로, 변수 접두사: `DAST_API_`에서 `APISEC_`로 (GitLab 17.1).

{{< /history >}}

## 사용 가능한 CI/CD 변수 {#available-cicd-variables}

| CI/CD 변수                                                                              | 설명 |
|---------------------------------------------------------------------------------------------|-------------|
| `SECURE_ANALYZERS_PREFIX`                                                                   | 분석기를 다운로드할 Docker 레지스트리 기본 주소를 지정합니다. |
| `APISEC_DISABLED`                                                                           | 'true' 또는 '1'로 설정하여 API 보안 테스트 스캔을 비활성화합니다. |
| `APISEC_DISABLED_FOR_DEFAULT_BRANCH`                                                        | 'true' 또는 '1'로 설정하여 기본(프로덕션) 브랜치에서만 API 보안 테스트 스캔을 비활성화합니다. |
| `APISEC_VERSION`                                                                            | API 보안 테스트 컨테이너 버전을 지정합니다. `3`로 기본값이 설정됩니다. |
| `APISEC_IMAGE_SUFFIX`                                                                       | 컨테이너 이미지 접미사를 지정합니다. 기본값은 없습니다. |
| `APISEC_API_PORT`                                                                           | API 보안 테스트 엔진에서 사용하는 통신 포트 번호를 지정합니다. `5500`로 기본값이 설정됩니다. [GitLab 15.5에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/367734). |
| `APISEC_TARGET_URL`                                                                         | API 테스트 대상의 기본 URL입니다. |
| `APISEC_TARGET_CHECK_SKIP`                                                                  | 대상을 사용할 수 있게 될 때까지 기다리지 않습니다. [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442699)됨. |
| `APISEC_TARGET_CHECK_STATUS_CODE`                                                           | 대상 가용성 확인을 위한 예상 상태 코드를 제공합니다. 제공되지 않은 경우 500이 아닌 모든 상태 코드를 허용합니다. [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442699)됨. |
| [`APISEC_CONFIG`](#configuration-files)                                                     | API 보안 테스트 설정 파일입니다. `.gitlab-dast-api.yml`로 기본값이 설정됩니다. |
| [`APISEC_PROFILE`](#configuration-files)                                                    | 테스트 중에 사용할 구성 프로필입니다. `Quick`로 기본값이 설정됩니다. |
| [`APISEC_EXCLUDE_PATHS`](customizing_analyzer_settings.md#exclude-paths)                    | 테스트에서 API URL 경로를 제외합니다. |
| [`APISEC_EXCLUDE_URLS`](customizing_analyzer_settings.md#exclude-urls)                      | 테스트에서 API URL을 제외합니다. |
| [`APISEC_EXCLUDE_PARAMETER_ENV`](customizing_analyzer_settings.md#exclude-parameters)       | 제외된 매개변수를 포함하는 JSON 문자열입니다. |
| [`APISEC_EXCLUDE_PARAMETER_FILE`](customizing_analyzer_settings.md#exclude-parameters)      | 제외된 매개변수를 포함하는 JSON 파일의 경로입니다. |
| [`APISEC_REQUEST_HEADERS`](customizing_analyzer_settings.md#request-headers)                | 각 스캔 요청에 포함할 헤더의 쉼표 구분(`,`) 목록입니다. [마스킹된 변수](../../../../ci/variables/_index.md#mask-a-cicd-variable)에서 비밀 헤더 값을 저장할 때 `APISEC_REQUEST_HEADERS_BASE64`를 사용하는 것이 좋습니다. 이 변수는 문자 집합 제한이 있습니다. |
| [`APISEC_REQUEST_HEADERS_BASE64`](customizing_analyzer_settings.md#request-headers)         | 각 스캔 요청에 포함할 헤더의 쉼표 구분(`,`) 목록으로, Base64로 인코딩됩니다. [GitLab 15.6에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/378440). |
| [`APISEC_OPENAPI`](enabling_the_analyzer.md#openapi-specification)                          | OpenAPI 사양 파일 또는 URL입니다. |
| [`APISEC_OPENAPI_RELAXED_VALIDATION`](enabling_the_analyzer.md#openapi-specification)       | 문서 유효성 검사를 완화합니다. 기본값은 비활성화입니다. |
| [`APISEC_OPENAPI_ALL_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)          | 요청을 생성할 때 하나 대신 지원되는 모든 미디어 유형을 사용합니다. 테스트 기간이 더 길어집니다. 기본값은 비활성화입니다. |
| [`APISEC_OPENAPI_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)              | 콜론(`:`) 구분 테스트에 허용되는 미디어 유형입니다. 기본값은 비활성화입니다. |
| [`APISEC_HAR`](enabling_the_analyzer.md#http-archive-har)                                   | HTTP Archive (HAR) 파일입니다. |
| [`APISEC_GRAPHQL`](enabling_the_analyzer.md#graphql-schema)                                 | GraphQL 끝점의 경로입니다. 예를 들어 `/api/graphql`입니다. GitLab 15.4에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/352780). |
| [`APISEC_GRAPHQL_SCHEMA`](enabling_the_analyzer.md#graphql-schema)                          | JSON 형식의 GraphQL 스키마에 대한 URL 또는 파일 이름입니다. GitLab 15.4에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/352780). |
| [`APISEC_POSTMAN_COLLECTION`](enabling_the_analyzer.md#postman-collection)                  | Postman Collection 파일입니다. |
| [`APISEC_POSTMAN_COLLECTION_VARIABLES`](enabling_the_analyzer.md#postman-variables)         | Postman 변수 값을 추출하기 위한 JSON 파일의 경로입니다. 쉼표로 구분된(`,`) 파일에 대한 지원은 GitLab 15.1에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/356312). |
| [`APISEC_OVERRIDES_FILE`](customizing_analyzer_settings.md#overrides)                       | 재정의를 포함하는 JSON 파일의 경로입니다. |
| [`APISEC_OVERRIDES_ENV`](customizing_analyzer_settings.md#overrides)                        | 재정의할 헤더를 포함하는 JSON 문자열입니다. |
| [`APISEC_OVERRIDES_CMD`](customizing_analyzer_settings.md#overrides)                        | 재정의 명령입니다. |
| [`APISEC_OVERRIDES_CMD_VERBOSE`](customizing_analyzer_settings.md#overrides)                | 모든 값으로 설정합니다. 재정의 명령 출력을 `gl-api-security-scanner.log` 작업 아티팩트 파일에 기록합니다. |
| `APISEC_PER_REQUEST_SCRIPT`                                                                 | 요청별 스크립트의 전체 경로 및 파일 이름입니다. [예제를 보려면 데모 프로젝트를 참조하세요](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-with-request-example). GitLab 17.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/13691)되었습니다. |
| `APISEC_PRE_SCRIPT`                                                                         | 스캔 세션이 시작되기 전에 사용자 명령 또는 스크립트를 실행합니다. `sudo`은 패키지 설치와 같은 권한이 필요한 작업에 사용해야 합니다. |
| `APISEC_POST_SCRIPT`                                                                        | 스캔 세션이 완료된 후 사용자 명령 또는 스크립트를 실행합니다. `sudo`은 패키지 설치와 같은 권한이 필요한 작업에 사용해야 합니다. |
| [`APISEC_OVERRIDES_INTERVAL`](customizing_analyzer_settings.md#overrides)                   | 재정의 명령을 실행하는 빈도(초)입니다. 기본값은 `0`(한 번)입니다. |
| [`APISEC_HTTP_USERNAME`](customizing_analyzer_settings.md#http-basic-authentication)        | HTTP 인증을 위한 사용자 이름입니다. |
| [`APISEC_HTTP_PASSWORD`](customizing_analyzer_settings.md#http-basic-authentication)        | HTTP 인증을 위한 암호입니다. 대신 `APISEC_HTTP_PASSWORD_BASE64`을 사용하는 것이 좋습니다. |
| [`APISEC_HTTP_PASSWORD_BASE64`](customizing_analyzer_settings.md#http-basic-authentication) | HTTP 인증을 위한 암호로, base64로 인코딩됩니다. GitLab 15.4에서 [도입됨](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing-src/-/merge_requests/702). |
| `APISEC_SERVICE_START_TIMEOUT`                                                              | 대상 API를 사용할 수 있을 때까지 대기하는 시간(초)입니다. 기본값은 300초입니다. |
| `APISEC_TIMEOUT`                                                                            | API 응답을 기다리는 시간(초)입니다. 기본값은 30초입니다. |
| `APISEC_SUCCESS_STATUS_CODES`                                                               | API 보안 테스트 스캔 작업이 통과했는지 여부를 결정하는 HTTP 성공 상태 코드의 쉼표 구분(`,`) 목록을 지정합니다. [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442219)됨. 예: `'200, 201, 204'` |

## 설정 파일 {#configuration-files}

빠르게 시작할 수 있도록 GitLab은 설정 파일 [`gitlab-dast-api-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/dast/-/blob/master/config/gitlab-dast-api-config.yml)을 제공합니다. 이 파일에는 다양한 수의 테스트를 수행하는 여러 테스트 프로필이 있습니다. 각 프로필의 실행 시간은 테스트 수가 증가함에 따라 증가합니다. 설정 파일을 사용하려면 리포지토리의 루트에 `.gitlab/gitlab-dast-api-config.yml`로 추가합니다.

### 프로필 {#profiles}

다음 프로필은 기본 설정 파일에서 미리 정의됩니다. 사용자 정의 설정을 만들어 프로필을 추가, 제거 및 수정할 수 있습니다.

#### 수동 {#passive}

- 응용 프로그램 정보 확인
- 평문 인증 확인
- JSON 하이재킹 확인
- 민감한 정보 확인
- 세션 쿠키 확인

#### 빠른 실행 {#quick}

- 응용 프로그램 정보 확인
- 평문 인증 확인
- FrameworkDebugModeCheck
- HTML 삽입 확인
- 안전하지 않은 HTTP 메서드 확인
- JSON 하이재킹 확인
- JSON 삽입 확인
- 민감한 정보 확인
- 세션 쿠키 확인
- SQL 삽입 확인
- 토큰 확인
- XML 인젝션 확인

#### 전체 {#full}

- 응용 프로그램 정보 확인
- 평문 인증 확인
- CORS 확인
- DNS 재바인딩 확인
- 프레임워크 디버그 모드 확인
- HTML 삽입 확인
- 안전하지 않은 HTTP 메서드 확인
- JSON 하이재킹 확인
- JSON 삽입 확인
- 개방 리다이렉트 확인
- 민감한 파일 확인
- 민감한 정보 확인
- 세션 쿠키 확인
- SQL 삽입 확인
- TLS 설정 확인
- 토큰 확인
- XML 인젝션 확인
