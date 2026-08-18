---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용 가능한 CI/CD 변수
---

| CI/CD 변수                                                                               | 설명 |
|----------------------------------------------------------------------------------------------|-------------|
| `SECURE_ANALYZERS_PREFIX`                                                                    | 분석기를 다운로드할 Docker 레지스트리 기본 주소를 지정합니다. |
| `FUZZAPI_VERSION`                                                                            | API 퍼징 컨테이너 버전을 지정합니다. `5`로 기본값이 설정됩니다. |
| `FUZZAPI_IMAGE_SUFFIX`                                                                       | 컨테이너 이미지 접미사를 지정합니다. 기본값은 없습니다. |
| `FUZZAPI_API_PORT`                                                                           | API 퍼징 엔진에서 사용하는 통신 포트 번호를 지정합니다. `5500`로 기본값이 설정됩니다. [GitLab 15.5에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/367734). |
| `FUZZAPI_TARGET_URL`                                                                         | API 테스트 대상의 기본 URL입니다. |
| `FUZZAPI_TARGET_CHECK_SKIP`                                                                  | 대상을 사용할 수 있게 될 때까지 기다리지 않습니다. [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442699)됨. |
| `FUZZAPI_TARGET_CHECK_STATUS_CODE`                                                           | 대상 가용성 확인을 위한 예상 상태 코드를 제공합니다. 제공되지 않은 경우 500이 아닌 모든 상태 코드를 허용합니다. [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442699)됨. |
| [`FUZZAPI_PROFILE`](customizing_analyzer_settings.md#api-fuzzing-profiles)                   | 테스트 중에 사용할 구성 프로필입니다. `Quick-10`로 기본값이 설정됩니다. |
| [`FUZZAPI_EXCLUDE_PATHS`](customizing_analyzer_settings.md#exclude-paths)                    | 테스트에서 API URL 경로를 제외합니다. |
| [`FUZZAPI_EXCLUDE_URLS`](customizing_analyzer_settings.md#exclude-urls)                      | 테스트에서 API URL을 제외합니다. |
| [`FUZZAPI_EXCLUDE_PARAMETER_ENV`](customizing_analyzer_settings.md#exclude-parameters)       | 제외된 매개변수를 포함하는 JSON 문자열입니다. |
| [`FUZZAPI_EXCLUDE_PARAMETER_FILE`](customizing_analyzer_settings.md#exclude-parameters)      | 제외된 매개변수를 포함하는 JSON 파일의 경로입니다. |
| [`FUZZAPI_OPENAPI`](enabling_the_analyzer.md#openapi-specification)                          | OpenAPI 사양 파일 또는 URL입니다. |
| [`FUZZAPI_OPENAPI_RELAXED_VALIDATION`](enabling_the_analyzer.md#openapi-specification)       | 문서 유효성 검사를 완화합니다. 기본값은 비활성화입니다. |
| [`FUZZAPI_OPENAPI_ALL_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)          | 요청을 생성할 때 하나 대신 지원되는 모든 미디어 유형을 사용합니다. 테스트 기간이 더 길어집니다. 기본값은 비활성화입니다. |
| [`FUZZAPI_OPENAPI_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)              | 콜론(`:`) 구분 테스트에 허용되는 미디어 유형입니다. 기본값은 비활성화입니다. |
| [`FUZZAPI_HAR`](enabling_the_analyzer.md#http-archive-har)                                   | HTTP Archive (HAR) 파일입니다. |
| [`FUZZAPI_GRAPHQL`](enabling_the_analyzer.md#graphql-schema)                                 | GraphQL 끝점의 경로입니다. 예를 들어 `/api/graphql`입니다. GitLab 15.4에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/352780). |
| [`FUZZAPI_GRAPHQL_SCHEMA`](enabling_the_analyzer.md#graphql-schema)                          | JSON 형식의 GraphQL 스키마에 대한 URL 또는 파일 이름입니다. GitLab 15.4에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/352780). |
| [`FUZZAPI_POSTMAN_COLLECTION`](enabling_the_analyzer.md#postman-collection)                  | Postman Collection 파일입니다. |
| [`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`](enabling_the_analyzer.md#postman-variables)         | Postman 변수 값을 추출하기 위한 JSON 파일의 경로입니다. 쉼표로 구분된(`,`) 파일에 대한 지원은 GitLab 15.1에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/356312). |
| [`FUZZAPI_OVERRIDES_FILE`](customizing_analyzer_settings.md#overrides)                       | 재정의를 포함하는 JSON 파일의 경로입니다. |
| [`FUZZAPI_OVERRIDES_ENV`](customizing_analyzer_settings.md#overrides)                        | 재정의할 헤더를 포함하는 JSON 문자열입니다. |
| [`FUZZAPI_OVERRIDES_CMD`](customizing_analyzer_settings.md#overrides)                        | 재정의 명령입니다. |
| [`FUZZAPI_OVERRIDES_CMD_VERBOSE`](customizing_analyzer_settings.md#overrides)                | 모든 값으로 설정합니다. 작업 출력의 일부로 재정의 명령 출력을 표시합니다. |
| `FUZZAPI_PER_REQUEST_SCRIPT`                                                                 | 요청별 스크립트의 전체 경로 및 파일 이름입니다. [예제를 보려면 데모 프로젝트를 참조하세요](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-with-request-example). GitLab 17.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/13691)되었습니다. |
| `FUZZAPI_PRE_SCRIPT`                                                                         | 스캔 세션이 시작되기 전에 사용자 명령 또는 스크립트를 실행합니다. `sudo`은 패키지 설치와 같은 권한이 필요한 작업에 사용해야 합니다. |
| `FUZZAPI_POST_SCRIPT`                                                                        | 스캔 세션이 완료된 후 사용자 명령 또는 스크립트를 실행합니다. `sudo`은 패키지 설치와 같은 권한이 필요한 작업에 사용해야 합니다. |
| [`FUZZAPI_OVERRIDES_INTERVAL`](customizing_analyzer_settings.md#overrides)                   | 재정의 명령을 실행하는 빈도(초)입니다. 기본값은 `0`(한 번)입니다. |
| [`FUZZAPI_HTTP_USERNAME`](customizing_analyzer_settings.md#http-basic-authentication)        | HTTP 인증을 위한 사용자 이름입니다. |
| [`FUZZAPI_HTTP_PASSWORD`](customizing_analyzer_settings.md#http-basic-authentication)        | HTTP 인증을 위한 암호입니다. |
| [`FUZZAPI_HTTP_PASSWORD_BASE64`](customizing_analyzer_settings.md#http-basic-authentication) | HTTP 인증을 위한 암호(Base64로 인코딩)입니다. GitLab 15.4에서 [도입됨](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing-src/-/merge_requests/702). |
| `FUZZAPI_SUCCESS_STATUS_CODES`                                                               | API 퍼징 테스트 스캔 작업이 통과했는지 여부를 결정하는 HTTP 성공 상태 코드의 쉼표 구분(`,`) 목록을 지정합니다. [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442219)됨. 예: `'200, 201, 204'` |
