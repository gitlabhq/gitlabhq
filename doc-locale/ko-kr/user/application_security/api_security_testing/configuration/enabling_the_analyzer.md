---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 분석기 활성화
---

다음을 사용하여 스캔할 API를 지정할 수 있습니다:

- [OpenAPI v2 또는 v3 사양](#openapi-specification)
- [GraphQL 스키마](#graphql-schema)
- [HTTP 아카이브(HAR)](#http-archive-har)
- [Postman Collection v2.0 또는 v2.1](#postman-collection)

## OpenAPI 사양 {#openapi-specification}

[OpenAPI 사양](https://www.openapis.org/)(이전에는 Swagger 사양으로 알려짐)은 REST API를 위한 API 설명 형식입니다. 이 섹션에서는 OpenAPI 사양을 사용하여 API 보안 테스트 스캔을 구성하는 방법을 보여줍니다. OpenAPI 사양은 파일 시스템 리소스 또는 URL로 제공됩니다. JSON 및 YAML OpenAPI 형식이 모두 지원됩니다.

API 보안 테스트는 OpenAPI 문서를 사용하여 요청 본문을 생성합니다. 요청 본문이 필요한 경우 본문 생성은 다음 본문 유형으로 제한됩니다:

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `application/json`
- `application/xml`

## OpenAPI 및 미디어 유형 {#openapi-and-media-types}

미디어 유형(이전에는 MIME 유형으로 알려짐)은 파일 형식 및 전송되는 형식 콘텐츠의 식별자입니다. OpenAPI 문서를 사용하면 주어진 작업이 서로 다른 미디어 유형을 수락할 수 있도록 지정할 수 있으므로, 주어진 요청은 다른 파일 콘텐츠를 사용하여 데이터를 보낼 수 있습니다. 예를 들어 `PUT /user` 작업을 사용하여 사용자 데이터를 업데이트할 때 XML(미디어 유형 `application/xml`) 또는 JSON(미디어 유형 `application/json`) 형식의 데이터를 수락할 수 있습니다. OpenAPI 2.x를 사용하면 허용되는 미디어 유형을 전역적으로 또는 작업별로 지정할 수 있으며, OpenAPI 3.x를 사용하면 허용되는 미디어 유형을 작업별로 지정할 수 있습니다. API 보안 테스트는 나열된 미디어 유형을 확인하고 지원되는 각 미디어 유형에 대해 샘플 데이터를 생성하려고 시도합니다.

- 기본 동작은 사용할 지원되는 미디어 유형 중 하나를 선택하는 것입니다. 목록에서 지원되는 첫 번째 미디어 유형이 선택됩니다. 이 동작은 구성 가능합니다.

동일한 작업(예: `POST /user`)을 다른 미디어 유형(예: `application/json` 및 `application/xml`)을 사용하여 테스트하는 것이 항상 바람직하지는 않습니다. 예를 들어, 대상 애플리케이션이 요청 콘텐츠 유형에 관계없이 동일한 코드를 실행하면 테스트 세션을 완료하는 데 더 오래 걸리며, 대상 앱에 따라 요청 본문과 관련된 중복된 취약성을 보고할 수 있습니다.

환경 변수 `APISEC_OPENAPI_ALL_MEDIA_TYPES`를 사용하면 주어진 작업에 대해 요청을 생성할 때 하나 대신 지원되는 모든 미디어 유형을 사용할지 여부를 지정할 수 있습니다. 환경 변수 `APISEC_OPENAPI_ALL_MEDIA_TYPES`가 어떤 값으로든 설정되면 API 보안 테스트는 주어진 작업에서 하나 대신 지원되는 모든 미디어 유형에 대한 요청을 생성하려고 시도합니다. 이렇게 하면 제공된 각 미디어 유형에 대해 테스트가 반복되므로 테스트를 완료하는 데 더 오래 걸립니다.

또는 변수 `APISEC_OPENAPI_MEDIA_TYPES`를 사용하여 테스트할 미디어 유형 목록을 제공합니다. 둘 이상의 미디어 유형을 제공하면 선택된 각 미디어 유형에 대해 테스트가 수행되므로 테스트를 완료하는 데 더 오래 걸립니다. 환경 변수 `APISEC_OPENAPI_MEDIA_TYPES`가 미디어 유형 목록으로 설정되면 요청을 만들 때 나열된 미디어 유형만 포함됩니다.

`APISEC_OPENAPI_MEDIA_TYPES`의 여러 미디어 유형은 콜론(`:`)으로 구분됩니다. 예를 들어 요청 생성을 미디어 유형 `application/x-www-form-urlencoded` 및 `multipart/form-data`로 제한하려면 환경 변수 `APISEC_OPENAPI_MEDIA_TYPES`를 `application/x-www-form-urlencoded:multipart/form-data`로 설정합니다. 이 목록의 지원되는 미디어 유형만 요청을 만들 때 포함되지만 지원되지 않는 미디어 유형은 항상 건너뜁니다. 미디어 유형 텍스트는 다양한 섹션을 포함할 수 있습니다. 예를 들어 `application/vnd.api+json; charset=UTF-8`은 `type "/" [tree "."] subtype ["+" suffix]* [";" parameter]`의 복합체입니다. 요청 생성 시 미디어 유형 필터링을 수행할 때 매개변수는 고려되지 않습니다.

환경 변수 `APISEC_OPENAPI_ALL_MEDIA_TYPES` 및 `APISEC_OPENAPI_MEDIA_TYPES`를 사용하여 미디어 유형을 처리하는 방법을 결정할 수 있습니다. 이 설정은 상호 배타적입니다. 둘 다 활성화되면 API 보안 테스트가 오류를 보고합니다.

### OpenAPI 사양으로 API 보안 테스트 구성 {#configure-api-security-testing-with-an-openapi-specification}

OpenAPI 사양으로 API 보안 테스트 스캔을 구성하려면:

1. [포함](../../../../ci/yaml/_index.md#includetemplate)하여 `.gitlab-ci.yml` 파일에 [`API-Security.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)을 포함합니다.
1. [구성 파일](variables.md#configuration-files)에는 다양한 확인이 활성화된 여러 테스트 프로필이 정의되어 있습니다. `Quick` 프로필로 시작합니다. 이 프로필을 사용한 테스트는 더 빠르게 완료되므로 더 쉬운 구성 검증이 가능합니다. `APISEC_PROFILE` CI/CD 변수를 `.gitlab-ci.yml` 파일에 추가하여 프로필을 제공합니다.
1. OpenAPI 사양의 위치를 파일 또는 URL로 제공합니다. `APISEC_OPENAPI` 변수를 추가하여 위치를 지정합니다.
1. 대상 API 인스턴스의 기본 URL도 필요합니다. `APISEC_TARGET_URL` 변수 또는 `environment_url.txt` 파일을 사용하여 제공합니다.

   프로젝트 루트의 `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서의 테스트에 좋습니다. GitLab CI/CD 파이프라인 중에 동적으로 생성된 앱에 대해 API 보안 테스트를 실행하려면 `environment_url.txt` 파일에서 앱이 URL을 유지하도록 합니다. API 보안 테스트는 해당 파일을 자동으로 파싱하여 스캔 대상을 찾습니다. GitLab [Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)에서 이에 대한 예를 볼 수 있습니다.

OpenAPI 사양 사용의 완전한 예제 구성:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
```

이것은 API 보안 테스트의 최소 구성입니다. 여기서 수행할 수 있는 작업:

- [첫 번째 스캔 실행](#running-your-first-scan).
- [인증 추가](customizing_analyzer_settings.md#authentication).
- [거짓 양성 처리](#handling-false-positives) 방법을 알아봅니다.

## HTTP 아카이브(HAR) {#http-archive-har}

[HTTP 아카이브 형식(HAR)](../../api_fuzzing/create_har_files.md)은 HTTP 트랜잭션을 로깅하기 위한 아카이브 파일 형식입니다. GitLab API 보안 테스트 스캐너와 함께 사용할 때 HAR 파일은 테스트할 웹 API 호출 기록을 포함해야 합니다. API 보안 테스트 스캐너는 모든 요청을 추출하고 이를 사용하여 테스트를 수행합니다.

HAR 파일을 생성하는 데 사용할 수 있는 다양한 도구가 있습니다:

- [Insomnia Core](https://insomnia.rest/):  API 클라이언트
- [Chrome](https://www.google.com/chrome/):  브라우저
- [Firefox](https://www.mozilla.org/en-US/firefox/):  브라우저
- [Fiddler](https://www.telerik.com/fiddler):  웹 디버깅 프록시
- [GitLab HAR Recorder](https://gitlab.com/gitlab-org/security-products/har-recorder):  명령줄

> [!warning]
> HAR 파일은 인증 토큰, API 키 및 세션 쿠키와 같은 민감한 정보를 포함할 수 있습니다. 리포지토리에 추가하기 전에 HAR 파일 콘텐츠를 검토합니다.

### HAR 파일을 사용한 API 보안 테스트 스캔 {#api-security-testing-scanning-with-a-har-file}

대상 API에 대한 정보를 제공하는 HAR 파일을 사용하도록 API 보안 테스트를 구성하려면:

1. [포함](../../../../ci/yaml/_index.md#includetemplate)하여 `.gitlab-ci.yml` 파일에 [`API-Security.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)을 포함합니다.
1. [구성 파일](variables.md#configuration-files)에는 다양한 확인이 활성화된 여러 테스트 프로필이 정의되어 있습니다. `Quick` 프로필로 시작합니다. 이 프로필을 사용한 테스트는 더 빠르게 완료되므로 더 쉬운 구성 검증이 가능합니다.

   `APISEC_PROFILE` CI/CD 변수를 `.gitlab-ci.yml` 파일에 추가하여 프로필을 제공합니다.
1. HAR 파일의 위치를 제공합니다. 파일 경로 또는 URL로 위치를 제공할 수 있습니다. `APISEC_HAR` 변수를 추가하여 위치를 지정합니다.
1. 대상 API 인스턴스의 기본 URL도 필요합니다. `APISEC_TARGET_URL` 변수 또는 `environment_url.txt` 파일을 사용하여 제공합니다.

   프로젝트 루트의 `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서의 테스트에 좋습니다. GitLab CI/CD 파이프라인 중에 동적으로 생성된 앱에 대해 API 보안 테스트를 실행하려면 `environment_url.txt` 파일에서 앱이 URL을 유지하도록 합니다. API 보안 테스트는 해당 파일을 자동으로 파싱하여 스캔 대상을 찾습니다. GitLab [Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)에서 이에 대한 예를 볼 수 있습니다.

HAR 파일 사용의 완전한 예제 구성:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_HAR: test-api-recording.har
  APISEC_TARGET_URL: http://test-deployment/
```

이 예제는 API 보안 테스트의 최소 구성입니다. 여기서 수행할 수 있는 작업:

- [첫 번째 스캔 실행](#running-your-first-scan).
- [인증 추가](customizing_analyzer_settings.md#authentication).
- [거짓 양성 처리](#handling-false-positives) 방법을 알아봅니다.

## GraphQL 스키마 {#graphql-schema}

{{< history >}}

- GraphQL 스키마 지원이 GitLab 15.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/352780)되었습니다.

{{< /history >}}

GraphQL은 API를 위한 쿼리 언어이며 REST API의 대안입니다. API 보안 테스트는 GraphQL 엔드포인트를 여러 가지 방식으로 테스트하도록 지원합니다:

- GraphQL 스키마를 사용하여 테스트합니다. GitLab 15.4에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/352780).
- GraphQL 쿼리의 기록(HAR)을 사용하여 테스트합니다.
- GraphQL 쿼리가 포함된 Postman Collection을 사용하여 테스트합니다.

이 섹션에서는 GraphQL 스키마를 사용하여 테스트하는 방법을 설명합니다. API 보안 테스트의 GraphQL 스키마 지원은 [자동검사](https://graphql.org/learn/introspection/)를 지원하는 엔드포인트에서 스키마를 쿼리할 수 있습니다. 자동검사는 GraphiQL과 같은 도구가 작동하도록 기본적으로 활성화됩니다. 자동검사를 활성화하는 방법에 대한 세부 사항은 GraphQL 프레임워크 설명서를 참조하세요.

### GraphQL 엔드포인트 URL을 사용한 API 보안 테스트 스캔 {#api-security-testing-scanning-with-a-graphql-endpoint-url}

API 보안 테스트의 GraphQL 지원은 스키마에 대해 GraphQL 엔드포인트를 쿼리할 수 있습니다.

> [!note]
> GraphQL 엔드포인트는 이 방법이 올바르게 작동하려면 자동검사 쿼리를 지원해야 합니다.

대상 API에 대한 정보를 제공하는 GraphQL 엔드포인트 URL을 사용하도록 API 보안 테스트를 구성하려면:

1. [포함](../../../../ci/yaml/_index.md#includetemplate)하여 `.gitlab-ci.yml` 파일에 [`API-Security.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)을 포함합니다.
1. 예를 들어 GraphQL 엔드포인트의 경로를 제공합니다 `/api/graphql`. `APISEC_GRAPHQL` 변수를 추가하여 위치를 지정합니다.
1. 대상 API 인스턴스의 기본 URL도 필요합니다. `APISEC_TARGET_URL` 변수 또는 `environment_url.txt` 파일을 사용하여 제공합니다.

   프로젝트 루트의 `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서의 테스트에 좋습니다. 자세한 정보는 [동적 환경 솔루션](../troubleshooting.md#dynamic-environment-solutions)을 참조하세요.

GraphQL 엔드포인트 경로 사용의 완전한 예제 구성:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_GRAPHQL: /api/graphql
    APISEC_TARGET_URL: http://test-deployment/
```

이 예제는 API 보안 테스트의 최소 구성입니다. 여기서 수행할 수 있는 작업:

- [첫 번째 스캔 실행](#running-your-first-scan).
- [인증 추가](customizing_analyzer_settings.md#authentication).
- [거짓 양성 처리](#handling-false-positives) 방법을 알아봅니다.

### GraphQL 스키마 파일을 사용한 API 보안 테스트 스캔 {#api-security-testing-scanning-with-a-graphql-schema-file}

API 보안 테스트는 GraphQL 스키마 파일을 사용하여 자동검사가 비활성화된 GraphQL 엔드포인트를 이해하고 테스트할 수 있습니다. GraphQL 스키마 파일을 사용하려면 자동검사 JSON 형식이어야 합니다. GraphQL 스키마를 온라인 제3자 도구를 사용하여 자동검사 JSON 형식으로 변환할 수 있습니다: <https://transform.tools/graphql-to-introspection-json>.

대상 API에 대한 정보를 제공하는 GraphQL 스키마 파일을 사용하도록 API 보안 테스트를 구성하려면:

1. [포함](../../../../ci/yaml/_index.md#includetemplate)하여 `.gitlab-ci.yml` 파일에 [`API-Security.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)을 포함합니다.
1. 예를 들어 GraphQL 엔드포인트 경로를 제공합니다 `/api/graphql`. `APISEC_GRAPHQL` 변수를 추가하여 경로를 지정합니다.
1. GraphQL 스키마 파일의 위치를 제공합니다. 파일 경로 또는 URL로 위치를 제공할 수 있습니다. `APISEC_GRAPHQL_SCHEMA` 변수를 추가하여 위치를 지정합니다.
1. 대상 API 인스턴스의 기본 URL도 필요합니다. `APISEC_TARGET_URL` 변수 또는 `environment_url.txt` 파일을 사용하여 제공합니다.

   프로젝트 루트의 `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서의 테스트에 좋습니다. 자세한 정보는 [동적 환경 솔루션](../troubleshooting.md#dynamic-environment-solutions)을 참조하세요.

GraphQL 스키마 파일 사용의 완전한 예제 구성:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_GRAPHQL: /api/graphql
    APISEC_GRAPHQL_SCHEMA: test-api-graphql.schema
    APISEC_TARGET_URL: http://test-deployment/
```

GraphQL 스키마 파일 URL 사용의 완전한 예제 구성:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_GRAPHQL: /api/graphql
    APISEC_GRAPHQL_SCHEMA: http://file-store/files/test-api-graphql.schema
    APISEC_TARGET_URL: http://test-deployment/
```

이 예제는 API 보안 테스트의 최소 구성입니다. 여기서 수행할 수 있는 작업:

- [첫 번째 스캔 실행](#running-your-first-scan).
- [인증 추가](customizing_analyzer_settings.md#authentication).
- [거짓 양성 처리](#handling-false-positives) 방법을 알아봅니다.

## Postman Collection {#postman-collection}

[Postman API 클라이언트](https://www.postman.com/product/api-client/)는 개발자와 테스터가 다양한 유형의 API를 호출하는 데 사용하는 인기 있는 도구입니다. API 정의를 [Postman Collection 파일로 내보낼 수 있으며](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections) API 보안 테스트에 사용할 수 있습니다. 내보낼 때 Postman Collection의 지원되는 버전을 선택했는지 확인합니다: v2.0 또는 v2.1.

GitLab API 보안 테스트 스캐너와 함께 사용할 때 Postman Collection은 유효한 데이터로 테스트할 웹 API의 정의를 포함해야 합니다. API 보안 테스트 스캐너는 모든 API 정의를 추출하고 이를 사용하여 테스트를 수행합니다.

> [!warning]
> Postman Collection 파일은 인증 토큰, API 키 및 세션 쿠키와 같은 민감한 정보를 포함할 수 있습니다. 리포지토리에 추가하기 전에 Postman Collection 파일 콘텐츠를 검토합니다.

### Postman Collection 파일을 사용한 API 보안 테스트 스캔 {#api-security-testing-scanning-with-a-postman-collection-file}

대상 API에 대한 정보를 제공하는 Postman Collection 파일을 사용하도록 API 보안 테스트를 구성하려면:

1. [포함](../../../../ci/yaml/_index.md#includetemplate) 하여 [`API-Security.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)을 포함합니다.
1. [구성 파일](variables.md#configuration-files)에는 다양한 확인이 활성화된 여러 테스트 프로필이 정의되어 있습니다. `Quick` 프로필로 시작합니다. 이 프로필을 사용한 테스트는 더 빠르게 완료되므로 더 쉬운 구성 검증이 가능합니다.

   `APISEC_PROFILE` CI/CD 변수를 `.gitlab-ci.yml` 파일에 추가하여 프로필을 제공합니다.
1. Postman Collection 파일의 위치를 파일 또는 URL로 제공합니다. `APISEC_POSTMAN_COLLECTION` 변수를 추가하여 위치를 지정합니다.
1. 대상 API 인스턴스의 기본 URL도 필요합니다. `APISEC_TARGET_URL` 변수 또는 `environment_url.txt` 파일을 사용하여 제공합니다.

   프로젝트 루트의 `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서의 테스트에 좋습니다. GitLab CI/CD 파이프라인 중에 동적으로 생성된 앱에 대해 API 보안 테스트를 실행하려면 `environment_url.txt` 파일에서 앱이 URL을 유지하도록 합니다. API 보안 테스트는 해당 파일을 자동으로 파싱하여 스캔 대상을 찾습니다. GitLab [Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)에서 이에 대한 예를 볼 수 있습니다.

Postman Collection 사용의 완전한 예제 구성:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection_serviceA.json
  APISEC_TARGET_URL: http://test-deployment/
```

이것은 API 보안 테스트의 최소 구성입니다. 여기서 수행할 수 있는 작업:

- [첫 번째 스캔 실행](#running-your-first-scan).
- [인증 추가](customizing_analyzer_settings.md#authentication).
- [거짓 양성 처리](#handling-false-positives) 방법을 알아봅니다.

### Postman 변수 {#postman-variables}

{{< history >}}

- Postman 환경 파일 형식 지원이 GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)되었습니다.
- 여러 변수 파일 지원이 GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)되었습니다.
- Postman 변수 범위 지원:  전역 및 환경이 GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)되었습니다.

{{< /history >}}

#### Postman 클라이언트의 변수 {#variables-in-postman-client}

Postman을 사용하면 개발자가 요청의 여러 부분에서 사용할 수 있는 자리 표시자를 정의할 수 있습니다. 이러한 자리 표시자를 변수라고 하며 [변수 사용](https://learning.postman.com/docs/sending-requests/variables/variables/#using-variables)에서 설명합니다. 변수를 사용하여 요청 및 스크립트에서 값을 저장하고 재사용할 수 있습니다. 예를 들어 컬렉션을 편집하여 문서에 변수를 추가할 수 있습니다:

![컬렉션 변수 탭 편집 보기](img/dast_api_postman_collection_edit_variable_v18_5.png)

또는 대신 환경에서 변수를 추가할 수 있습니다:

![환경 변수 편집 보기](img/dast_api_postman_environment_edit_variable_v18_5.png)

그러면 URL, 헤더 등의 섹션에서 변수를 사용할 수 있습니다:

![변수를 사용한 요청 편집 보기](img/dast_api_postman_request_edit_v18_5.png)

Postman은 좋은 UX 경험을 제공하는 기본 클라이언트 도구에서 스크립트를 사용하여 API를 테스트하고, 보조 요청을 트리거하는 복잡한 컬렉션을 만들고, 진행하면서 변수를 설정할 수 있는 더 복잡한 생태계로 성장했습니다. Postman 생태계의 모든 기능이 지원되는 것은 아닙니다. 예를 들어 스크립트는 지원되지 않습니다. Postman 지원의 주요 초점은 Postman 클라이언트에서 사용하는 Postman Collection 정의와 워크스페이스, 환경 및 컬렉션 자체에 정의된 관련 변수를 수집하는 것입니다.

Postman을 사용하면 다양한 범위에서 변수를 만들 수 있습니다. 각 범위는 Postman 도구에서 다양한 가시성 수준을 갖습니다. 예를 들어 모든 작업 정의 및 워크스페이스에 표시되는 _전역 환경_ 범위에서 변수를 만들 수 있습니다. 특정 _환경_ 범위에서 변수를 만들 수도 있습니다. 이는 해당 특정 환경이 사용하도록 선택된 경우에만 표시되고 사용됩니다. 일부 범위는 항상 사용 가능하지 않습니다. 예를 들어 Postman 생태계에서 Postman 클라이언트에서 요청을 만들 수 있지만 이러한 요청은 _로컬_ 범위를 갖지 않지만 테스트 스크립트는 갖습니다.

Postman의 변수 범위는 다루기 어려운 주제일 수 있으며 모든 사람이 익숙하지 않습니다. 진행하기 전에 Postman 설명서에서 [변수 범위](https://learning.postman.com/docs/sending-requests/variables/variables/#variable-scopes)를 읽으세요.

앞서 언급했듯이 다양한 변수 범위가 있으며, 각각은 목적을 가지고 있으며 Postman 문서에 더 많은 유연성을 제공하는 데 사용할 수 있습니다. 변수 값이 계산되는 방법에 대한 중요한 참고 사항이 있습니다(Postman 설명서 참조):

> [!note]
> 동일한 이름으로 선언된 변수가 두 범위에 있으면 가장 좁은 범위의 변수에 저장된 값이 사용됩니다. 예를 들어 `username`라는 전역 변수와 `username`라는 로컬 변수가 있으면 요청이 실행될 때 로컬 값이 사용됩니다.

다음은 Postman 클라이언트 및 API 보안 테스트에서 지원하는 변수 범위의 요약입니다:

- **Global Environment (Global) scope**는 워크스페이스 전체에서 사용 가능한 특수 사전 정의된 환경입니다. _전역 환경_ 범위를 _전역_ 범위로도 부를 수 있습니다. Postman 클라이언트는 전역 환경을 JSON 파일로 내보낼 수 있으며, 이를 API 보안 테스트에 사용할 수 있습니다.
- **Environment scope**은 Postman 클라이언트의 사용자가 만든 이름의 변수 그룹입니다. Postman 클라이언트는 전역 환경과 함께 단일 활성 환경을 지원합니다. 활성 사용자 생성 환경에 정의된 변수는 전역 환경에 정의된 변수보다 우선합니다. Postman 클라이언트는 환경을 JSON 파일로 내보낼 수 있으며, 이를 API 보안 테스트에 사용할 수 있습니다.
- **Collection scope**는 주어진 컬렉션에 선언된 변수 그룹입니다. 컬렉션 변수는 선언된 컬렉션과 중첩된 요청 또는 컬렉션에서 사용할 수 있습니다. 컬렉션 범위에 정의된 변수는 _전역 환경_ 범위 및 _환경_ 범위보다 우선합니다. Postman 클라이언트는 하나 이상의 컬렉션을 JSON 파일로 내보낼 수 있으며, 이 JSON 파일에는 선택한 컬렉션, 요청 및 컬렉션 변수가 포함됩니다.
- **API security testing scope**는 사용자가 추가 변수를 제공하거나 지원되는 다른 범위에 정의된 변수를 재정의할 수 있도록 API 보안 테스트에서 추가한 새로운 범위입니다. 이 범위는 Postman에서 지원되지 않습니다. _API 보안 테스트 범위_ 변수는 [사용자 지정 JSON 파일 형식](#api-security-testing-scope-custom-json-file-format)을 사용하여 제공됩니다.
  - 환경 또는 컬렉션에 정의된 값 재정의
  - 스크립트에서 변수 정의
  - 지원되지 않는 _데이터 범위_에서 단일 행의 데이터 정의
- **데이터 범위**는 이름과 값이 JSON 또는 CSV 파일에서 오는 변수 그룹입니다. [Newman](https://learning.postman.com/docs/collections/using-newman-cli/command-line-integration-with-newman/) 또는 [Postman Collection Runner](https://learning.postman.com/docs/collections/running-collections/intro-to-collection-runs/)와 같은 Postman Collection 러너는 JSON 또는 CSV 파일과 동일한 항목 수만큼 컬렉션의 요청을 실행합니다. 이러한 변수의 좋은 사용 사례는 Postman에서 스크립트를 사용하여 테스트를 자동화하는 것입니다. API 보안 테스트는 CSV 또는 JSON 파일에서 데이터 읽기를 지원하지 않습니다.
- **로컬 범위**는 Postman 스크립트에 정의된 변수입니다. API 보안 테스트는 Postman 스크립트를 지원하지 않으며 확장 기능에 따라 스크립트에 정의된 변수를 지원하지 않습니다. 지원되는 범위 중 하나 또는 사용자 지정 JSON 형식에 변수를 정의하여 스크립트 정의 변수의 값을 제공할 수 있습니다.

모든 범위가 API 보안 테스트에서 지원되는 것은 아니며 스크립트에 정의된 변수는 지원되지 않습니다. 다음 표는 가장 넓은 범위에서 가장 좁은 범위로 정렬됩니다.

| 범위                      | Postman | API 보안 테스트 | 설명                                    |
|----------------------------|:-------:|:--------------------:|:-------------------------------------------|
| 전역 환경         |   예   |         예          | 특수 사전 정의된 환경            |
| 환경                |   예   |         예          | 이름이 지정된 환경                         |
| 컬렉션                 |   예   |         예          | postman collection에 정의됨         |
| API 보안 테스트 범위 |   아니요    |         예          | API 보안 테스트에서 추가한 사용자 지정 범위 |
| 데이터                       |   예   |          아니요          | CSV 또는 JSON 형식의 외부 파일       |
| 로컬                      |   예   |          아니요          | 스크립트에 정의된 변수               |

다양한 범위에서 변수를 정의하고 내보내는 방법에 대한 자세한 내용은 다음을 참조하세요:

- [컬렉션 변수 정의](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-collection-variables)
- [환경 변수 정의](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-environment-variables)
- [전역 변수 정의](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-global-variables)

##### Postman 클라이언트에서 내보내기 {#exporting-from-postman-client}

Postman 클라이언트를 사용하면 다양한 파일 형식을 내보낼 수 있습니다. 예를 들어 Postman Collection 또는 Postman 환경을 내보낼 수 있습니다. 내보낸 환경은 전역 환경(항상 사용 가능)이거나 이전에 만든 사용자 지정 환경일 수 있습니다. Postman Collection을 내보낼 때 _컬렉션_ 및 _로컬_ 범위 변수에 대한 선언만 포함할 수 있습니다. _환경_ 범위 변수는 포함되지 않습니다.

_환경_ 범위 변수에 대한 선언을 가져오려면 당시에 주어진 환경을 내보내야 합니다. 각 내보낸 파일은 선택한 환경의 변수만 포함합니다.

다양한 지원 범위에서 변수 내보내기에 대한 자세한 내용은 다음을 참조하세요:

- [컬렉션 내보내기](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)
- [환경 내보내기](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [전역 환경 다운로드](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)

#### API 보안 테스트 범위, 사용자 지정 JSON 파일 형식 {#api-security-testing-scope-custom-json-file-format}

사용자 지정 JSON 파일 형식은 각 객체 속성이 변수 이름을 나타내고 속성 값이 변수 값을 나타내는 JSON 객체입니다. 이 파일은 즐겨 찾는 텍스트 편집기를 사용하여 만들거나 파이프라인의 이전 작업으로 생성될 수 있습니다.

이 예제는 API 보안 테스트 범위에서 `base_url` 및 `token` 두 변수를 정의합니다:

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### API 보안 테스트에서 범위 사용 {#using-scopes-with-api-security-testing}

범위: _전역_, _환경_, _컬렉션_, 및 _GitLab API 보안 테스트_는 [GitLab 15.1 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)에서 지원됩니다. GitLab 15.0 이하는 _컬렉션_ 및 _GitLab API 보안 테스트_ 범위만 지원합니다.

다음 표는 범위 파일/URL을 API 보안 테스트 구성 변수에 매핑하기 위한 빠른 참조를 제공합니다:

| 범위              |  제공 방법 |
| ------------------ | --------------- |
| 전역 환경 | APISEC_POSTMAN_COLLECTION_VARIABLES |
| 환경        | APISEC_POSTMAN_COLLECTION_VARIABLES |
| 컬렉션         | APISEC_POSTMAN_COLLECTION           |
| API 보안 테스트 범위 | APISEC_POSTMAN_COLLECTION_VARIABLES |
| 데이터               | 지원되지 않음   |
| 로컬              | 지원되지 않음   |

Postman Collection 문서는 자동으로 모든 _컬렉션_ 범위 변수를 포함합니다. Postman Collection은 구성 변수 `APISEC_POSTMAN_COLLECTION`로 제공됩니다. 이 변수는 단일 [내보낸 Postman Collection](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)으로 설정할 수 있습니다.

다른 범위의 변수는 `APISEC_POSTMAN_COLLECTION_VARIABLES` 구성 변수를 통해 제공됩니다. 구성 변수는 [GitLab 15.1 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)에서 쉼표(`,`) 구분 파일 목록을 지원합니다. GitLab 15.0 이하는 단일 파일만 지원합니다. 제공된 파일의 순서는 파일이 필요한 범위 정보를 제공하므로 중요하지 않습니다.

구성 변수 `APISEC_POSTMAN_COLLECTION_VARIABLES`를 다음으로 설정할 수 있습니다:

- [내보낸 전역 환경](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)
- [내보낸 환경](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [API 보안 테스트 사용자 지정 JSON 형식](#api-security-testing-scope-custom-json-file-format)

#### 정의되지 않은 Postman 변수 {#undefined-postman-variables}

API 보안 테스트 엔진이 Postman Collection 파일에서 사용 중인 모든 변수 참조를 찾을 수 없을 가능성이 있습니다. 일부 경우가 있을 수 있습니다:

- _데이터_ 또는 _로컬_ 범위 변수를 사용 중이며 앞서 언급했듯이 이러한 범위는 API 보안 테스트에서 지원되지 않습니다. 따라서 이러한 변수의 값이 [API 보안 테스트 범위](#api-security-testing-scope-custom-json-file-format)를 통해 제공되지 않았다고 가정하면 _데이터_ 및 _로컬_ 범위 변수의 값은 정의되지 않습니다.
- 변수 이름이 잘못 입력되었으며 이름이 정의된 변수와 일치하지 않습니다.
- Postman 클라이언트는 API 보안 테스트에서 지원하지 않는 새로운 동적 변수를 지원합니다.

가능한 경우 API 보안 테스트는 정의되지 않은 변수를 처리할 때 Postman 클라이언트와 동일한 동작을 따릅니다. 변수 참조의 텍스트는 동일하게 유지되며 텍스트 대체가 없습니다. 동일한 동작이 지원되지 않는 모든 동적 변수에도 적용됩니다.

예를 들어 Postman Collection의 요청 정의가 변수 `{{full_url}}`를 참조하고 변수를 찾을 수 없으면 `{{full_url}}` 값으로 변경되지 않은 상태로 남아 있습니다.

#### 동적 Postman 변수 {#dynamic-postman-variables}

사용자가 다양한 범위 수준에서 정의할 수 있는 변수 외에도 Postman에는 _동적_ 변수라고 하는 사전 정의된 변수 집합이 있습니다. [_동적_ 변수](https://learning.postman.com/docs/tests-and-scripts/write-scripts/variables-list/)는 이미 정의되어 있으며 이름 앞에 달러 기호(`$`)가 붙습니다. 예: `$guid`. _동적_ 변수는 다른 변수처럼 사용할 수 있으며 Postman 클라이언트에서 요청/컬렉션 실행 중에 임의의 값을 생성합니다.

API 보안 테스트와 Postman 간의 중요한 차이점은 API 보안 테스트가 동일한 동적 변수의 각 사용에 대해 동일한 값을 반환한다는 것입니다. 이는 동일한 동적 변수를 사용할 때마다 임의의 값을 반환하는 Postman 클라이언트 동작과 다릅니다. 즉, API 보안 테스트는 동적 변수에 정적 값을 사용하지만 Postman은 임의의 값을 사용합니다.

스캔 프로세스 중에 지원되는 동적 변수는:

| 변수    | 값       |
| ----------- | ----------- |
| `$guid` | `611c2e81-2ccb-42d8-9ddc-2d0bfa65c1b4` |
| `$isoTimestamp` | `2020-06-09T21:10:36.177Z` |
| `$randomAbbreviation` | `PCI` |
| `$randomAbstractImage` | `http://no-a-valid-host/640/480/abstract` |
| `$randomAdjective` | `auxiliary` |
| `$randomAlphaNumeric` | `a` |
| `$randomAnimalsImage` | `http://no-a-valid-host/640/480/animals` |
| `$randomAvatarImage` | `https://no-a-valid-host/path/to/some/image.jpg` |
| `$randomBankAccount` | `09454073` |
| `$randomBankAccountBic` | `EZIAUGJ1` |
| `$randomBankAccountIban` | `MU20ZPUN3039684000618086155TKZ` |
| `$randomBankAccountName` | `Home Loan Account` |
| `$randomBitcoin` | `3VB8JGT7Y4Z63U68KGGKDXMLLH5` |
| `$randomBoolean` | `true` |
| `$randomBs` | `killer leverage schemas` |
| `$randomBsAdjective` | `viral` |
| `$randomBsBuzz` | `repurpose` |
| `$randomBsNoun` | `markets` |
| `$randomBusinessImage` | `http://no-a-valid-host/640/480/business` |
| `$randomCatchPhrase` | `Future-proofed heuristic open architecture` |
| `$randomCatchPhraseAdjective` | `Business-focused` |
| `$randomCatchPhraseDescriptor` | `bandwidth-monitored` |
| `$randomCatchPhraseNoun` | `superstructure` |
| `$randomCatsImage` | `http://no-a-valid-host/640/480/cats` |
| `$randomCity` | `Spinkahaven` |
| `$randomCityImage` | `http://no-a-valid-host/640/480/city` |
| `$randomColor` | `fuchsia` |
| `$randomCommonFileExt` | `wav` |
| `$randomCommonFileName` | `well_modulated.mpg4` |
| `$randomCommonFileType` | `audio` |
| `$randomCompanyName` | `Grady LLC` |
| `$randomCompanySuffix` | `Inc` |
| `$randomCountry` | `Kazakhstan` |
| `$randomCountryCode` | `MD` |
| `$randomCreditCardMask` | `3622` |
| `$randomCurrencyCode` | `ZMK` |
| `$randomCurrencyName` | `Pound Sterling` |
| `$randomCurrencySymbol` | `£` |
| `$randomDatabaseCollation` | `utf8_general_ci` |
| `$randomDatabaseColumn` | `updatedAt` |
| `$randomDatabaseEngine` | `Memory` |
| `$randomDatabaseType` | `text` |
| `$randomDateFuture` | `Tue Mar 17 2020 13:11:50 GMT+0530 (India Standard Time)` |
| `$randomDatePast` | `Sat Mar 02 2019 09:09:26 GMT+0530 (India Standard Time)` |
| `$randomDateRecent` | `Tue Jul 09 2019 23:12:37 GMT+0530 (India Standard Time)` |
| `$randomDepartment` | `Electronics` |
| `$randomDirectoryPath` | `/usr/local/bin` |
| `$randomDomainName` | `trevor.info` |
| `$randomDomainSuffix` | `org` |
| `$randomDomainWord` | `jaden` |
| `$randomEmail` | `Iva.Kovacek61@no-a-valid-host.com` |
| `$randomExampleEmail` | `non-a-valid-user@example.net` |
| `$randomFashionImage` | `http://no-a-valid-host/640/480/fashion` |
| `$randomFileExt` | `war` |
| `$randomFileName` | `neural_sri_lanka_rupee_gloves.gdoc` |
| `$randomFilePath` | `/home/programming_chicken.cpio` |
| `$randomFileType` | `application` |
| `$randomFirstName` | `Chandler` |
| `$randomFoodImage` | `http://no-a-valid-host/640/480/food` |
| `$randomFullName` | `Connie Runolfsdottir` |
| `$randomHexColor` | `#47594a` |
| `$randomImageDataUri` | `data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20version%3D%221.1%22%20baseProfile%3D%22full%22%20width%3D%22undefined%22%20height%3D%22undefined%22%3E%20%3Crect%20width%3D%22100%25%22%20height%3D%22100%25%22%20fill%3D%22grey%22%2F%3E%20%20%3Ctext%20x%3D%220%22%20y%3D%2220%22%20font-size%3D%2220%22%20text-anchor%3D%22start%22%20fill%3D%22white%22%3Eundefinedxundefined%3C%2Ftext%3E%20%3C%2Fsvg%3E` |
| `$randomImageUrl` | `http://no-a-valid-host/640/480` |
| `$randomIngverb` | `navigating` |
| `$randomInt` | `494` |
| `$randomIP` | `241.102.234.100` |
| `$randomIPV6` | `dbe2:7ae6:119b:c161:1560:6dda:3a9b:90a9` |
| `$randomJobArea` | `Mobility` |
| `$randomJobDescriptor` | `Senior` |
| `$randomJobTitle` | `International Creative Liaison` |
| `$randomJobType` | `Supervisor` |
| `$randomLastName` | `Schneider` |
| `$randomLatitude` | `55.2099` |
| `$randomLocale` | `ny` |
| `$randomLongitude` | `40.6609` |
| `$randomLoremLines` | `Ducimus in ut mollitia.\nA itaque non.\nHarum temporibus nihil voluptas.\nIste in sed et nesciunt in quaerat sed.` |
| `$randomLoremParagraph` | `Ab aliquid odio iste quo voluptas voluptatem dignissimos velit. Recusandae facilis qui commodi ea magnam enim nostrum quia quis. Nihil est suscipit assumenda ut voluptatem sed. Esse ab voluptas odit qui molestiae. Rem est nesciunt est quis ipsam expedita consequuntur.` |
| `$randomLoremParagraphs` | `Voluptatem rem magnam aliquam ab id aut quaerat. Placeat provident possimus voluptatibus dicta velit non aut quasi. Mollitia et aliquam expedita sunt dolores nam consequuntur. Nam dolorum delectus ipsam repudiandae et ipsam ut voluptatum totam. Nobis labore labore recusandae ipsam quo.` |
| `$randomLoremSentence` | `Molestias consequuntur nisi non quod.` |
| `$randomLoremSentences` | `Et sint voluptas similique iure amet perspiciatis vero sequi atque. Ut porro sit et hic. Neque aspernatur vitae fugiat ut dolore et veritatis. Ab iusto ex delectus animi. Voluptates nisi iusto. Impedit quod quae voluptate qui.` |
| `$randomLoremSlug` | `eos-aperiam-accusamus, beatae-id-molestiae, qui-est-repellat` |
| `$randomLoremText` | `Quisquam asperiores exercitationem ut ipsum. Aut eius nesciunt. Et reiciendis aut alias eaque. Nihil amet laboriosam pariatur eligendi. Sunt ullam ut sint natus ducimus. Voluptas harum aspernatur soluta rem nam.` |
| `$randomLoremWord` | `est` |
| `$randomLoremWords` | `vel repellat nobis` |
| `$randomMACAddress` | `33:d4:68:5f:b4:c7` |
| `$randomMimeType` | `audio/vnd.vmx.cvsd` |
| `$randomMonth` | `February` |
| `$randomNamePrefix` | `Dr.` |
| `$randomNameSuffix` | `MD` |
| `$randomNatureImage` | `http://no-a-valid-host/640/480/nature` |
| `$randomNightlifeImage` | `http://no-a-valid-host/640/480/nightlife` |
| `$randomNoun` | `bus` |
| `$randomPassword` | `t9iXe7COoDKv8k3` |
| `$randomPeopleImage` | `http://no-a-valid-host/640/480/people` |
| `$randomPhoneNumber` | `700-008-5275` |
| `$randomPhoneNumberExt` | `27-199-983-3864` |
| `$randomPhrase` | `You can't program the monitor without navigating the mobile XML program!` |
| `$randomPrice` | `531.55` |
| `$randomProduct` | `Pizza` |
| `$randomProductAdjective` | `Unbranded` |
| `$randomProductMaterial` | `Steel` |
| `$randomProductName` | `Handmade Concrete Tuna` |
| `$randomProtocol` | `https` |
| `$randomSemver` | `7.0.5` |
| `$randomSportsImage` | `http://no-a-valid-host/640/480/sports` |
| `$randomStreetAddress` | `5742 Harvey Streets` |
| `$randomStreetName` | `Kuhic Island` |
| `$randomTransactionType` | `payment` |
| `$randomTransportImage` | `http://no-a-valid-host/640/480/transport` |
| `$randomUrl` | `https://no-a-valid-host.net` |
| `$randomUserAgent` | `Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.9.8; rv:15.6) Gecko/20100101 Firefox/15.6.6` |
| `$randomUserName` | `Jarrell.Gutkowski` |
| `$randomUUID` | `6929bb52-3ab2-448a-9796-d6480ecad36b` |
| `$randomVerb` | `navigate` |
| `$randomWeekday` | `Thursday` |
| `$randomWord` | `withdrawal` |
| `$randomWords` | `Samoa Synergistic sticky copying Grocery` |
| `$timestamp` | `1562757107` |

#### 예:  전역 범위 {#example-global-scope}

이 예제에서는 Postman 클라이언트에서 [_전역_ 범위를 내보내](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) `global-scope.json`로 내보내고 `APISEC_POSTMAN_COLLECTION_VARIABLES` 구성 변수를 통해 API 보안 테스트에 제공합니다.

`APISEC_POSTMAN_COLLECTION_VARIABLES` 사용의 예:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: global-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### 예:  환경 범위 {#example-environment-scope}

이 예제에서는 Postman 클라이언트에서 [_환경_ 범위를 내보내](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) `environment-scope.json`로 내보내고 `APISEC_POSTMAN_COLLECTION_VARIABLES` 구성 변수를 통해 API 보안 테스트에 제공합니다.

`APISEC_POSTMAN_COLLECTION_VARIABLES` 사용의 예:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: environment-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### 예:  컬렉션 범위 {#example-collection-scope}

_컬렉션_ 범위 변수는 내보낸 Postman Collection 파일에 포함되며 `APISEC_POSTMAN_COLLECTION` 구성 변수를 통해 제공됩니다.

`APISEC_POSTMAN_COLLECTION` 사용의 예:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### 예:  API 보안 테스트 범위 {#example-api-security-testing-scope}

API 보안 테스트 범위는 API 보안 테스트에서 지원하지 않는 _데이터_ 및 _로컬_ 범위 변수를 정의하고 다른 범위에 정의된 기존 변수의 값을 변경하는 두 가지 주요 목적으로 사용됩니다. API 보안 테스트 범위는 `APISEC_POSTMAN_COLLECTION_VARIABLES` 구성 변수를 통해 제공됩니다.

`APISEC_POSTMAN_COLLECTION_VARIABLES` 사용의 예:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: dast-api-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

`dast-api-scope.json` 파일은 [사용자 지정 JSON 파일 형식](#api-security-testing-scope-custom-json-file-format)을 사용합니다. 이 JSON은 속성에 대한 키-값 쌍이 있는 객체입니다. 키는 변수의 이름이고 값은 변수의 값입니다. 예를 들어:

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### 예:  여러 범위 {#example-multiple-scopes}

이 예제에서 _전역_ 범위, _환경_ 범위, 및 _컬렉션_ 범위가 구성됩니다. 첫 번째 단계는 다양한 범위를 내보내는 것입니다.

- [_전역_ 범위를 내보내](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) `global-scope.json`로 내보냅니다.
- [_환경_ 범위를 내보내](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) `environment-scope.json`로 내보냅니다.
- _컬렉션_ 범위를 포함하는 Postman Collection을 `postman-collection.json`로 내보냅니다.

Postman Collection은 `APISEC_POSTMAN_COLLECTION` 변수를 사용하여 제공되며, 다른 범위는 `APISEC_POSTMAN_COLLECTION_VARIABLES`를 사용하여 제공됩니다. API 보안 테스트는 각 파일에 제공된 데이터를 사용하여 제공된 파일이 일치하는 범위를 식별할 수 있습니다.

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### 예:  변수 값 변경 {#example-changing-a-variables-value}

내보낸 범위를 사용할 때 API 보안 테스트에 사용하기 위해 변수의 값을 변경해야 하는 경우가 많습니다. 예를 들어, _컬렉션_ 범위 변수는 `api_version` 값 `v2`를 포함할 수 있지만 테스트에는 `v1` 값이 필요합니다. 내보낸 컬렉션을 수정하여 값을 변경하는 대신 API 보안 테스트 범위를 사용하여 값을 변경할 수 있습니다. 이는 _API 보안 테스트_ 범위가 다른 모든 범위보다 우선하기 때문에 작동합니다.

_컬렉션_ 범위 변수는 내보낸 Postman Collection 파일에 포함되며 `APISEC_POSTMAN_COLLECTION` 구성 변수를 통해 제공됩니다.

API 보안 테스트 범위는 `APISEC_POSTMAN_COLLECTION_VARIABLES` 구성 변수를 통해 제공됩니다. 하지만 먼저 파일을 만들어야 합니다. `dast-api-scope.json` 파일은 [사용자 지정 JSON 파일 형식](#api-security-testing-scope-custom-json-file-format)을 사용합니다. 이 JSON은 속성에 대한 키-값 쌍이 있는 객체입니다. 키는 변수의 이름이고 값은 변수의 값입니다. 예를 들어:

```json
{
  "api_version": "v1"
}
```

CI 정의:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: dast-api-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### 예:  여러 범위로 변수 값 변경 {#example-changing-a-variables-value-with-multiple-scopes}

내보낸 범위를 사용할 때 API 보안 테스트에 사용하기 위해 변수의 값을 변경해야 하는 경우가 많습니다. 예를 들어, _환경_ 범위는 `api_version` 값 `v2`를 포함할 수 있지만 테스트에는 `v1` 값이 필요합니다. 내보낸 파일을 수정하여 값을 변경하는 대신 API 보안 테스트 범위를 사용할 수 있습니다. 이는 _API 보안 테스트_ 범위가 다른 모든 범위보다 우선하기 때문에 작동합니다.

이 예제에서 _전역_ 범위, _환경_ 범위, _컬렉션_ 범위, 및 _API 보안 테스트_ 범위가 구성됩니다. 첫 번째 단계는 다양한 범위를 내보내고 만드는 것입니다.

- [_전역_ 범위를 내보내](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) `global-scope.json`로 내보냅니다.
- [_환경_ 범위를 내보내](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) `environment-scope.json`로 내보냅니다.
- _컬렉션_ 범위를 포함하는 Postman Collection을 `postman-collection.json`로 내보냅니다.

API 보안 테스트 범위는 `dast-api-scope.json` 파일을 [사용자 지정 JSON 파일 형식](#api-security-testing-scope-custom-json-file-format)을 사용하여 생성함으로써 사용됩니다. 이 JSON은 속성에 대한 키-값 쌍이 있는 객체입니다. 키는 변수의 이름이고 값은 변수의 값입니다. 예를 들어:

```json
{
  "api_version": "v1"
}
```

Postman Collection은 `APISEC_POSTMAN_COLLECTION` 변수를 사용하여 제공되며, 다른 범위는 `APISEC_POSTMAN_COLLECTION_VARIABLES`를 사용하여 제공됩니다. API 보안 테스트는 각 파일에 제공된 데이터를 사용하여 제공된 파일이 일치하는 범위를 식별할 수 있습니다.

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json,dast-api-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

## 첫 번째 스캔 실행 {#running-your-first-scan}

올바르게 구성되면 CI/CD 파이프라인은 `dast` 스테이지와 `dast_api` 작업을 포함합니다. 작업은 잘못된 구성이 제공된 경우에만 실패합니다. 일반적인 작업 중에 테스트 중에 취약성이 식별되는 경우에도 작업은 항상 성공합니다.

취약성은 **보안** 파이프라인 탭에 도구 모음 이름과 함께 표시됩니다. 저장소의 기본 브랜치에 대해 테스트할 때 API 보안 테스트 취약성도 보안 및 준수의 취약성 보고서에 표시됩니다.

보고된 과도한 취약성의 수를 방지하기 위해 API 보안 테스트 스캐너는 작업당 보고하는 취약성의 수를 제한합니다.

## API 보안 테스트 취약성 보기 {#viewing-api-security-testing-vulnerabilities}

API 보안 테스트 분석기는 [GitLab 취약성 화면에 취약성을 채우는 데](#view-details-of-an-api-security-testing-vulnerability) 사용되는 JSON 보고서를 생성합니다.

[거짓 양성 처리](#handling-false-positives)에서 거짓 양성 보고 수를 제한하기 위해 수행할 수 있는 구성 변경 사항에 대한 정보를 참조하세요.

### API 보안 테스트 취약성의 세부 정보 보기 {#view-details-of-an-api-security-testing-vulnerability}

취약성의 세부 정보를 보려면 다음 단계를 따르세요:

1. 프로젝트 또는 머지 리퀘스트에서 취약성을 볼 수 있습니다:

   - 프로젝트에서 프로젝트의 **보안** > **취약성 보고서** 페이지로 이동합니다. 이 페이지에는 기본 브랜치의 모든 취약성만 표시됩니다.
   - 머지 리퀘스트에서 머지 리퀘스트의 **보안** 섹션으로 이동하여 **펼침** 버튼을 선택합니다. API 보안 테스트 취약성은 **DAST detected N potential vulnerabilities** 레이블이 있는 섹션에서 사용할 수 있습니다. 제목을 선택하여 취약성 세부 정보를 표시합니다.

1. 취약성 제목을 선택하여 세부 정보를 표시합니다. 아래 표는 이러한 세부 정보를 설명합니다.

   | 필드               | 설명                                                                             |
   |:--------------------|:----------------------------------------------------------------------------------------|
   | 설명         | 수정된 내용을 포함한 취약성의 설명입니다.                           |
   | 프로젝트             | 취약성이 감지된 네임스페이스 및 프로젝트입니다.                          |
   | 방법              | 취약성을 감지하는 데 사용되는 HTTP 방법입니다.                                           |
   | URL                 | 취약성이 감지된 URL입니다.                                            |
   | 요청             | 취약성을 초래한 HTTP 요청입니다.                                         |
   | 수정되지 않은 응답 | 수정되지 않은 요청의 응답입니다. 일반적인 작동 응답은 수정되지 않은 응답처럼 보입니다.|
   | 실제 응답     | 테스트 요청에서 받은 응답입니다.                                                    |
   | 증거            | GitLab이 취약성이 발생한 것으로 판단한 방법입니다.                                         |
   | 식별자         | 이 취약성을 찾는 데 사용된 API 보안 테스트 확인입니다.                         |
   | 심각도            | 취약성의 심각도입니다.                                                          |
   | 스캐너 유형        | 테스트를 수행하는 데 사용되는 스캐너입니다.                                                        |

### 보안 대시보드 {#security-dashboard}

보안 대시보드는 그룹, 프로젝트 및 파이프라인의 모든 보안 취약성을 개요할 수 있는 좋은 위치입니다. 자세한 정보는 [보안 대시보드 문서](../../security_dashboard/_index.md)를 참조하세요.

### 취약성과의 상호 작용 {#interacting-with-the-vulnerabilities}

취약성이 발견되면 이와 상호 작용할 수 있습니다. [취약성을 해결하는 방법](../../vulnerabilities/_index.md)에 대해 자세히 알아봅시다.

### 거짓 양성 처리 {#handling-false-positives}

거짓 양성은 여러 방식으로 처리할 수 있습니다:

- 취약성을 무시합니다.
- 일부 확인에는 취약성이 식별될 때를 감지하는 여러 방법이 있으며 이를 _확인_이라고 합니다. 확인을 끄고 구성할 수도 있습니다. 예를 들어 API 보안 테스트 스캐너는 기본적으로 HTTP 상태 코드를 사용하여 이슈가 실제인지 식별하는 데 도움을 줍니다. 테스트 중에 API가 500 오류를 반환하면 취약성이 생성됩니다. 일부 프레임워크는 500 오류를 자주 반환하므로 항상 원하는 것은 아닙니다.
- 거짓 양성을 생성하는 확인을 끕니다. 이는 확인이 취약성을 생성하지 못하도록 합니다. 예제 확인은 SQL 주입 확인 및 JSON 하이재킹 확인입니다.

#### 확인 끄기 {#turn-off-a-check}

확인은 특정 유형의 테스트를 수행하며 특정 구성 프로필에 대해 켜고 끌 수 있습니다. 제공된 [구성 파일](variables.md#configuration-files)은 사용할 수 있는 여러 프로필을 정의합니다. 구성 파일의 프로필 정의는 스캔 중에 활성화되는 모든 확인을 나열합니다. 특정 확인을 끄려면 구성 파일의 프로필 정의에서 제거합니다. 프로필은 구성 파일의 `Profiles` 섹션에 정의됩니다.

예제 프로필 정의:

```yaml
Profiles:
  - Name: Quick
    DefaultProfile: Empty
    Routes:
      - Route: *Route0
        Checks:
          - Name: ApplicationInformationCheck
          - Name: CleartextAuthenticationCheck
          - Name: FrameworkDebugModeCheck
          - Name: HtmlInjectionCheck
          - Name: InsecureHttpMethodsCheck
          - Name: JsonHijackingCheck
          - Name: JsonInjectionCheck
          - Name: SensitiveInformationCheck
          - Name: SessionCookieCheck
          - Name: SqlInjectionCheck
          - Name: TokenCheck
          - Name: XmlInjectionCheck
```

JSON 하이재킹 확인을 끄려면 다음 줄을 제거할 수 있습니다:

```yaml
          - Name: JsonHijackingCheck
```

이 결과 다음 YAML:

```yaml
- Name: Quick
  DefaultProfile: Empty
  Routes:
    - Route: *Route0
      Checks:
        - Name: ApplicationInformationCheck
        - Name: CleartextAuthenticationCheck
        - Name: FrameworkDebugModeCheck
        - Name: HtmlInjectionCheck
        - Name: InsecureHttpMethodsCheck
        - Name: JsonInjectionCheck
        - Name: SensitiveInformationCheck
        - Name: SessionCookieCheck
        - Name: SqlInjectionCheck
        - Name: TokenCheck
        - Name: XmlInjectionCheck
```

#### 확인에 대한 확인 끄기 {#turn-off-an-assertion-for-a-check}

확인은 확인으로 생성된 테스트에서 취약성을 감지합니다. 많은 확인은 로그 분석, 응답 분석 및 상태 코드와 같은 여러 확인을 지원합니다. 취약성이 발견되면 사용된 확인이 제공됩니다. 기본적으로 어떤 확인이 활성화되어 있는지 확인하려면 구성 파일의 확인 기본 구성을 참조하세요. 이 섹션은 `Checks`라고 합니다.

이 예제는 SQL 주입 확인을 보여줍니다:

```yaml
- Name: SqlInjectionCheck
  Configuration:
    UserInjections: []
  Assertions:
    - Name: LogAnalysisAssertion
    - Name: ResponseAnalysisAssertion
    - Name: StatusCodeAssertion
```

여기서 세 개의 확인이 기본적으로 활성화되어 있음을 볼 수 있습니다. 거짓 양성의 일반적인 원인은 `StatusCodeAssertion`입니다. 이를 끄려면 `Profiles` 섹션에서 구성을 수정합니다. 이 예제는 다른 두 확인(`LogAnalysisAssertion`, `ResponseAnalysisAssertion`)만 제공합니다. 이는 `SqlInjectionCheck`가 `StatusCodeAssertion`를 사용하는 것을 방지합니다:

```yaml
Profiles:
  - Name: Quick
    DefaultProfile: Empty
    Routes:
      - Route: *Route0
        Checks:
          - Name: ApplicationInformationCheck
          - Name: CleartextAuthenticationCheck
          - Name: FrameworkDebugModeCheck
          - Name: HtmlInjectionCheck
          - Name: InsecureHttpMethodsCheck
          - Name: JsonHijackingCheck
          - Name: JsonInjectionCheck
          - Name: SensitiveInformationCheck
          - Name: SessionCookieCheck
          - Name: SqlInjectionCheck
            Assertions:
              - Name: LogAnalysisAssertion
              - Name: ResponseAnalysisAssertion
          - Name: TokenCheck
          - Name: XmlInjectionCheck
```
