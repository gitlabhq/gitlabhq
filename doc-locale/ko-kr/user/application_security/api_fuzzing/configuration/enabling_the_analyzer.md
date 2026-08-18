---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 분석기 활성화
---

전제 조건:

- 다음 웹 API 유형 중 하나:
  - REST API
  - SOAP
  - GraphQL
  - 양식 본문, JSON 또는 XML
- 테스트할 API를 제공하는 다음 자산 중 하나:
  - OpenAPI v2 또는 v3 API 정의
  - 테스트할 API 요청의 HTTP 아카이브(HAR)
  - Postman 컬렉션 v2.0 또는 v2.1

  > [!warning]
  > **없음** 프로덕션 서버에 대해 퍼징 테스트를 실행하세요. API가 수행할 수 있는 모든 함수를 수행할 수 있을 뿐만 아니라, API의 버그를 트리거할 수도 있습니다. 여기에는 데이터 수정 및 삭제와 같은 작업이 포함됩니다. 테스트 서버에 대해서만 퍼징을 실행하세요.

웹 API 퍼징을 활성화하려면 웹 API 퍼징 구성 양식을 사용합니다.

- 수동 구성 지침은 API 유형에 따라 해당 섹션을 참조하세요:
  - [OpenAPI 명세](#openapi-specification)
  - [GraphQL 스키마](#graphql-schema)
  - [HTTP 아카이브(HAR)](#http-archive-har)
  - [Postman Collection](#postman-collection)
- 그렇지 않으면 [웹 API 퍼징 구성 양식](#web-api-fuzzing-configuration-form)을 참조하세요.

API 퍼징 구성 파일은 리포지토리의 `.gitlab` 디렉터리에 있어야 합니다.

## 웹 API 퍼징 구성 양식 {#web-api-fuzzing-configuration-form}

API 퍼징 구성 양식은 프로젝트의 API 퍼징 구성을 생성하거나 수정하는 데 도움이 됩니다. 이 양식을 사용하면 가장 일반적인 API 퍼징 옵션에 대한 값을 선택하고 GitLab CI/CD 구성에 붙여넣을 수 있는 YAML 스니펫을 생성할 수 있습니다.

### UI에서 웹 API 퍼징 구성 {#configure-web-api-fuzzing-in-the-ui}

API 퍼징 구성 스니펫을 생성하려면:

1. 상단 바에서 **Search or go to**를 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **API 퍼징** 행에서 **Enable API Fuzzing**을 선택합니다.
1. 필드를 완성하세요. 자세한 내용은 [사용 가능한 CI/CD 변수](variables.md)를 참조하세요.
1. **코드 스니펫 생성**을 선택합니다. 양식에서 선택한 옵션에 해당하는 YAML 스니펫이 있는 대화 상자가 열립니다.
1. 다음 중 하나를 수행합니다:
   1. 스니펫을 클립보드에 복사하려면 **코드만 복사**를 선택합니다.
   1. 스니펫을 프로젝트의 `.gitlab-ci.yml` 파일에 추가하려면 **Copy code and open `.gitlab-ci.yml` file**을 선택합니다. 파이프라인 편집기가 열립니다.
      1. 스니펫을 `.gitlab-ci.yml` 파일에 붙여넣습니다.
      1. **Lint** 탭을 선택하여 편집된 `.gitlab-ci.yml` 파일이 유효한지 확인합니다.
      1. **편집** 탭을 선택한 후 **변경 사항 커밋**을 선택합니다.

스니펫이 `.gitlab-ci.yml` 파일에 커밋되면 파이프라인에는 API 퍼징 작업이 포함됩니다.

## OpenAPI 명세 {#openapi-specification}

[OpenAPI 명세](https://www.openapis.org/)(이전의 Swagger 명세)는 REST API용 API 설명 형식입니다. 이 섹션에서는 OpenAPI 명세를 사용하여 API 퍼징을 구성하여 테스트할 대상 API에 대한 정보를 제공하는 방법을 보여줍니다. OpenAPI 명세는 파일 시스템 리소스 또는 URL로 제공됩니다. JSON 및 YAML OpenAPI 형식이 모두 지원됩니다.

API 퍼징은 OpenAPI 문서를 사용하여 요청 본문을 생성합니다. 요청 본문이 필요한 경우 본문 생성은 다음 본문 유형으로 제한됩니다:

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `application/json`
- `application/xml`

## OpenAPI 및 미디어 유형 {#openapi-and-media-types}

미디어 유형(이전의 MIME 유형)은 전송되는 파일 형식 및 형식 콘텐츠에 대한 식별자입니다. OpenAPI 문서를 사용하면 주어진 작업이 다양한 미디어 유형을 허용할 수 있으므로 주어진 요청은 다양한 파일 콘텐츠를 사용하여 데이터를 보낼 수 있습니다. 예를 들어 `PUT /user` 작업은 XML(미디어 유형 `application/xml`) 또는 JSON(미디어 유형 `application/json`) 형식으로 사용자 데이터를 업데이트할 수 있습니다. OpenAPI 2.x를 사용하면 허용된 미디어 유형을 전역으로 또는 작업별로 지정할 수 있으며, OpenAPI 3.x를 사용하면 허용된 미디어 유형을 작업별로 지정할 수 있습니다. API 퍼징은 나열된 미디어 유형을 확인하고 지원되는 각 미디어 유형에 대한 샘플 데이터를 생성하려고 시도합니다.

- 기본 동작은 사용할 지원되는 미디어 유형 중 하나를 선택하는 것입니다. 목록에서 첫 번째 지원되는 미디어 유형을 선택합니다. 이 동작은 구성 가능합니다.

동일한 작업(예: `POST /user`)을 다양한 미디어 유형(예: `application/json` 및 `application/xml`)을 사용하여 테스트하는 것이 항상 바람직한 것은 아닙니다. 예를 들어 대상 애플리케이션이 요청 콘텐츠 유형에 관계없이 동일한 코드를 실행하면 테스트 세션을 완료하는 데 더 오래 걸리고 대상 앱에 따라 요청 본문과 관련된 중복 취약성을 보고할 수 있습니다.

환경 변수 `FUZZAPI_OPENAPI_ALL_MEDIA_TYPES`을 사용하면 주어진 작업에 대한 요청을 생성할 때 하나 대신 지원되는 모든 미디어 유형을 사용할지 여부를 지정할 수 있습니다. 환경 변수 `FUZZAPI_OPENAPI_ALL_MEDIA_TYPES`를 값으로 설정하면 API 퍼징은 주어진 작업에서 하나 대신 지원되는 모든 미디어 유형에 대한 요청을 생성하려고 시도합니다. 제공된 각 미디어 유형에 대해 테스트가 반복되므로 테스트가 더 오래 걸립니다.

또는 변수 `FUZZAPI_OPENAPI_MEDIA_TYPES`을 사용하여 테스트할 미디어 유형 목록을 제공합니다. 둘 이상의 미디어 유형을 제공하면 선택한 각 미디어 유형에 대해 테스트가 수행되므로 테스트가 더 오래 걸립니다. 환경 변수 `FUZZAPI_OPENAPI_MEDIA_TYPES`를 미디어 유형 목록으로 설정하면 요청을 생성할 때 나열된 미디어 유형만 포함됩니다.

`FUZZAPI_OPENAPI_MEDIA_TYPES`의 여러 미디어 유형은 콜론(`:`)으로 구분되어야 합니다. 예를 들어 요청 생성을 미디어 유형 `application/x-www-form-urlencoded` 및 `multipart/form-data`로 제한하려면 환경 변수 `FUZZAPI_OPENAPI_MEDIA_TYPES`를 `application/x-www-form-urlencoded:multipart/form-data`으로 설정합니다. 이 목록에서는 지원되는 미디어 유형만 요청을 생성할 때 포함되며, 지원되지 않는 미디어 유형은 항상 건너뜁니다. 미디어 유형 텍스트는 다양한 섹션을 포함할 수 있습니다. 예를 들어 `application/vnd.api+json; charset=UTF-8`은 `type "/" [tree "."] subtype ["+" suffix]* [";" parameter]`의 복합입니다. 요청 생성 시 미디어 유형 필터링할 때는 매개변수를 고려하지 않습니다.

환경 변수 `FUZZAPI_OPENAPI_ALL_MEDIA_TYPES` 및 `FUZZAPI_OPENAPI_MEDIA_TYPES`를 사용하여 미디어 유형을 처리하는 방법을 결정할 수 있습니다. 이 설정은 상호 배타적입니다. 둘 다 활성화되면 API 퍼징은 오류를 보고합니다.

### OpenAPI 명세로 웹 API 퍼징 구성 {#configure-web-api-fuzzing-with-an-openapi-specification}

OpenAPI 명세로 GitLab에서 API 퍼징을 구성하려면:

1. `fuzz` 스테이지를 `.gitlab-ci.yml` 파일에 추가합니다.
1. [포함](../../../../ci/yaml/_index.md#includetemplate) [`API-Fuzzing.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)을 `.gitlab-ci.yml` 파일에 포함합니다.
1. `FUZZAPI_PROFILE` CI/CD 변수를 `.gitlab-ci.yml` 파일에 추가하여 프로필을 제공합니다. 프로필은 실행되는 테스트의 수를 지정합니다. `Quick-10`를 선택한 프로필로 대체합니다. 자세한 내용은 [API 퍼징 프로필](customizing_analyzer_settings.md#api-fuzzing-profiles)을 참조하세요.

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. OpenAPI 명세의 위치를 제공합니다. 명세를 파일 또는 URL로 제공할 수 있습니다. `FUZZAPI_OPENAPI` 변수를 추가하여 위치를 지정합니다.
1. 대상 API 인스턴스의 기본 URL을 제공합니다. `FUZZAPI_TARGET_URL` 변수 또는 `environment_url.txt` 파일을 사용합니다.

   `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서 테스트하는 데 좋습니다. GitLab CI/CD 파이프라인 중에 동적으로 생성되는 애플리케이션에 대해 API 퍼징을 실행하려면 애플리케이션이 해당 URL을 `environment_url.txt` 파일에 유지하도록 합니다. API 퍼징은 자동으로 해당 파일을 구문 분석하여 스캔 대상을 찾습니다. [Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)의 예시를 볼 수 있습니다.

OpenAPI 명세를 사용하는 `.gitlab-ci.yml` 파일의 예:

   ```yaml
   stages:
     - fuzz

   include:
     - template: Security/API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_OPENAPI: test-api-specification.json
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

이것은 API 퍼징의 최소한의 구성입니다. 여기서 다음을 수행할 수 있습니다:

- [첫 스캔 실행](#running-your-first-scan).
- [인증 추가](customizing_analyzer_settings.md#authentication).
- [거짓 양성 처리](#handling-false-positives) 방법을 알아봅니다.

API 퍼징 구성 옵션의 자세한 내용은 [사용 가능한 CI/CD 변수](variables.md)를 참조하세요.

## HTTP 아카이브(HAR) {#http-archive-har}

[HTTP 아카이브 형식(HAR)](http://www.softwareishard.com/blog/har-12-spec/)은 HTTP 트랜잭션을 기록하기 위한 아카이브 파일 형식입니다. GitLab API 퍼저와 함께 사용할 때 HAR에는 테스트할 웹 API를 호출하는 기록이 포함되어야 합니다. API 퍼저는 모든 요청을 추출하고 이를 사용하여 테스트를 수행합니다.

자세한 내용(HAR 파일을 생성하는 방법 포함)은 [HTTP 아카이브 형식](../create_har_files.md)을 참조하세요.

> [!warning]
> HAR 파일에는 인증 토큰, API 키 및 세션 쿠키와 같은 민감한 정보가 포함될 수 있습니다. HAR 파일 콘텐츠를 리포지토리에 추가하기 전에 검토해야 합니다.

### HAR 파일로 웹 API 퍼징 구성 {#configure-web-api-fuzzing-with-a-har-file}

API 퍼징을 구성하여 HAR 파일을 사용하려면:

1. `fuzz` 스테이지를 `.gitlab-ci.yml` 파일에 추가합니다.
1. [포함](../../../../ci/yaml/_index.md#includetemplate) [`API-Fuzzing.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)을 `.gitlab-ci.yml` 파일에 포함합니다.
1. `FUZZAPI_PROFILE` CI/CD 변수를 `.gitlab-ci.yml` 파일에 추가하여 프로필을 제공합니다. 프로필은 실행되는 테스트의 수를 지정합니다. `Quick-10`를 선택한 프로필로 대체합니다. 자세한 내용은 [API 퍼징 프로필](customizing_analyzer_settings.md#api-fuzzing-profiles)을 참조하세요.

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. HAR 명세의 위치를 제공합니다. 명세를 파일 또는 URL로 제공할 수 있습니다. `FUZZAPI_HAR` 변수를 추가하여 위치를 지정합니다.
1. 대상 API 인스턴스의 기본 URL도 필요합니다. `FUZZAPI_TARGET_URL` 변수 또는 `environment_url.txt` 파일을 사용하여 제공합니다.

   `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서 테스트하는 데 좋습니다. GitLab CI/CD 파이프라인 중에 동적으로 생성되는 앱에 대해 API 퍼징을 실행하려면 앱이 해당 도메인을 `environment_url.txt` 파일에 유지하도록 합니다. API 퍼징은 자동으로 해당 파일을 구문 분석하여 스캔 대상을 찾습니다. [GitLab Auto DevOps CI YAML의 예시](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)를 볼 수 있습니다.

HAR 파일을 사용하는 `.gitlab-ci.yml` 파일의 예:

   ```yaml
   stages:
     - fuzz

   include:
     - template: Security/API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_HAR: test-api-recording.har
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

이 예시는 API 퍼징의 최소한의 구성입니다. 여기서 다음을 수행할 수 있습니다:

- [첫 스캔 실행](#running-your-first-scan).
- [인증 추가](customizing_analyzer_settings.md#authentication).
- [거짓 양성 처리](#handling-false-positives) 방법을 알아봅니다.

API 퍼징 구성 옵션의 자세한 내용은 [사용 가능한 CI/CD 변수](variables.md)를 참조하세요.

## GraphQL 스키마 {#graphql-schema}

{{< history >}}

- GraphQL 스키마에 대한 지원은 GitLab 15.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/352780)되었습니다.

{{< /history >}}

GraphQL은 API를 위한 쿼리 언어이며 REST API의 대안입니다. API 퍼징은 여러 방식으로 GraphQL 엔드포인트 테스트를 지원합니다:

- GraphQL 스키마를 사용하여 테스트합니다. GitLab 15.4에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/352780).
- GraphQL 쿼리의 기록(HAR)을 사용하여 테스트합니다.
- GraphQL 쿼리를 포함하는 Postman Collection을 사용하여 테스트합니다.

이 섹션에서는 GraphQL 스키마를 사용하여 테스트하는 방법을 설명합니다. API 퍼징의 GraphQL 스키마 지원은 내부 검사를 지원하는 엔드포인트에서 스키마를 쿼리할 수 있습니다. 내부 검사는 기본적으로 활성화되어 GraphiQL과 같은 도구가 작동할 수 있습니다.

### GraphQL 엔드포인트 URL을 사용한 API 퍼징 스캔 {#api-fuzzing-scanning-with-a-graphql-endpoint-url}

API 퍼징의 GraphQL 지원은 GraphQL 엔드포인트에 스키마를 쿼리할 수 있습니다.

> [!note]
> GraphQL 엔드포인트는 이 방법이 올바르게 작동하려면 내부 검사 쿼리를 지원해야 합니다.

테스트할 대상 API에 대한 정보를 제공하는 GraphQL 엔드포인트 URL을 사용하도록 API 퍼징을 구성하려면:

1. [포함](../../../../ci/yaml/_index.md#includetemplate) [`API-Fuzzing.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)을 `.gitlab-ci.yml` 파일에 포함합니다.
1. GraphQL 엔드포인트 경로(예: `/api/graphql`)를 제공합니다. `FUZZAPI_GRAPHQL` 변수를 추가하여 경로를 지정합니다.
1. 대상 API 인스턴스의 기본 URL도 필요합니다. `FUZZAPI_TARGET_URL` 변수 또는 `environment_url.txt` 파일을 사용하여 제공합니다.

   `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서 테스트하는 데 좋습니다. 자세한 내용은 [동적 환경 솔루션](../troubleshooting.md#dynamic-environment-solutions)을 참조하세요.

GraphQL 엔드포인트 URL을 사용하는 완전한 예시 구성:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzer_fuzz:
  variables:
    FUZZAPI_GRAPHQL: /api/graphql
    FUZZAPI_TARGET_URL: http://test-deployment/
```

이 예시는 API 퍼징의 최소한의 구성입니다. 여기서 다음을 수행할 수 있습니다:

- [첫 스캔 실행](#running-your-first-scan).
- [인증 추가](customizing_analyzer_settings.md#authentication).
- [거짓 양성 처리](#handling-false-positives) 방법을 알아봅니다.

### GraphQL 스키마 파일을 사용한 API 퍼징 {#api-fuzzing-with-a-graphql-schema-file}

API 퍼징은 GraphQL 스키마 파일을 사용하여 내부 검사가 비활성화된 GraphQL 엔드포인트를 이해하고 테스트할 수 있습니다. GraphQL 스키마 파일을 사용하려면 내부 검사 JSON 형식이어야 합니다. GraphQL 스키마는 온라인 타사 도구 <https://transform.tools/graphql-to-introspection-json>를 사용하여 내부 검사 JSON 형식으로 변환할 수 있습니다.

테스트할 대상 API에 대한 정보를 제공하는 GraphQL 스키마 파일을 사용하도록 API 퍼징을 구성하려면:

1. [포함](../../../../ci/yaml/_index.md#includetemplate) [`API-Fuzzing.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)을 `.gitlab-ci.yml` 파일에 포함합니다.
1. GraphQL 엔드포인트 경로(예: `/api/graphql`)를 제공합니다. `FUZZAPI_GRAPHQL` 변수를 추가하여 경로를 지정합니다.
1. GraphQL 스키마 파일의 위치를 제공합니다. 위치를 파일 경로 또는 URL로 제공할 수 있습니다. `FUZZAPI_GRAPHQL_SCHEMA` 변수를 추가하여 위치를 지정합니다.
1. 대상 API 인스턴스의 기본 URL도 필요합니다. `FUZZAPI_TARGET_URL` 변수 또는 `environment_url.txt` 파일을 사용하여 제공합니다.

   `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서 테스트하는 데 좋습니다. 자세한 내용은 [동적 환경 솔루션](../troubleshooting.md#dynamic-environment-solutions)을 참조하세요.

GraphQL 스키마 파일을 사용하는 완전한 예시 구성:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzer_fuzz:
  variables:
    FUZZAPI_GRAPHQL: /api/graphql
    FUZZAPI_GRAPHQL_SCHEMA: test-api-graphql.schema
    FUZZAPI_TARGET_URL: http://test-deployment/
```

GraphQL 스키마 파일 URL을 사용하는 완전한 예시 구성:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzer_fuzz:
  variables:
    FUZZAPI_GRAPHQL: /api/graphql
    FUZZAPI_GRAPHQL_SCHEMA: http://file-store/files/test-api-graphql.schema
    FUZZAPI_TARGET_URL: http://test-deployment/
```

이 예시는 API 퍼징의 최소한의 구성입니다. 여기서 다음을 수행할 수 있습니다:

- [첫 스캔 실행](#running-your-first-scan).
- [인증 추가](customizing_analyzer_settings.md#authentication).
- [거짓 양성 처리](#handling-false-positives) 방법을 알아봅니다.

## Postman Collection {#postman-collection}

[Postman API Client](https://www.postman.com/product/api-client/)는 개발자와 테스터가 다양한 유형의 API를 호출하는 데 사용하는 인기 있는 도구입니다. API 정의는 [Postman Collection 파일로 내보낼 수 있습니다](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections) API 퍼징 사용. 내보낼 때 지원되는 Postman Collection 버전(v2.0 또는 v2.1)을 선택해야 합니다.

GitLab API 퍼저와 함께 사용할 때 Postman Collection에는 유효한 데이터로 테스트할 웹 API의 정의가 포함되어야 합니다. API 퍼저는 모든 API 정의를 추출하고 이를 사용하여 테스트를 수행합니다.

> [!warning]
> Postman Collection 파일에는 인증 토큰, API 키 및 세션 쿠키와 같은 민감한 정보가 포함될 수 있습니다. Postman Collection 파일 콘텐츠를 리포지토리에 추가하기 전에 검토해야 합니다.

### Postman Collection 파일로 웹 API 퍼징 구성 {#configure-web-api-fuzzing-with-a-postman-collection-file}

API 퍼징을 구성하여 Postman Collection 파일을 사용하려면:

1. `fuzz` 스테이지를 `.gitlab-ci.yml` 파일에 추가합니다.
1. [포함](../../../../ci/yaml/_index.md#includetemplate) [`API-Fuzzing.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)을 `.gitlab-ci.yml` 파일에 포함합니다.
1. `FUZZAPI_PROFILE` CI/CD 변수를 `.gitlab-ci.yml` 파일에 추가하여 프로필을 제공합니다. 프로필은 실행되는 테스트의 수를 지정합니다. `Quick-10`를 선택한 프로필로 대체합니다. 자세한 내용은 [API 퍼징 프로필](customizing_analyzer_settings.md#api-fuzzing-profiles)을 참조하세요.

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Postman Collection 명세의 위치를 제공합니다. 명세를 파일 또는 URL로 제공할 수 있습니다. `FUZZAPI_POSTMAN_COLLECTION` 변수를 추가하여 위치를 지정합니다.
1. 대상 API 인스턴스의 기본 URL을 제공합니다. `FUZZAPI_TARGET_URL` 변수 또는 `environment_url.txt` 파일을 사용합니다.

   `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서 테스트하는 데 좋습니다. GitLab CI/CD 파이프라인 중에 동적으로 생성되는 앱에 대해 API 퍼징을 실행하려면 앱이 해당 도메인을 `environment_url.txt` 파일에 유지하도록 합니다. API 퍼징은 자동으로 해당 파일을 구문 분석하여 스캔 대상을 찾습니다. [GitLab Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)의 예시를 볼 수 있습니다.

Postman Collection 파일을 사용하는 `.gitlab-ci.yml` 파일의 예:

   ```yaml
   stages:
     - fuzz

   include:
     - template: Security/API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_POSTMAN_COLLECTION: postman-collection_serviceA.json
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

이것은 API 퍼징의 최소한의 구성입니다. 여기서 다음을 수행할 수 있습니다:

- [첫 스캔 실행](#running-your-first-scan).
- [인증 추가](customizing_analyzer_settings.md#authentication).
- [거짓 양성 처리](#handling-false-positives) 방법을 알아봅니다.

API 퍼징 구성 옵션의 자세한 내용은 [사용 가능한 CI/CD 변수](variables.md)를 참조하세요.

### Postman 변수 {#postman-variables}

{{< history >}}

- Postman 환경 파일 형식에 대한 지원은 GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)되었습니다.
- 여러 변수 파일에 대한 지원은 GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)되었습니다.
- Postman 변수 범위에 대한 지원(전역 및 환경)은 GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)되었습니다.

{{< /history >}}

#### Postman Client의 변수 {#variables-in-postman-client}

Postman을 사용하면 개발자가 요청의 다양한 부분에서 사용할 수 있는 자리 표시자를 정의할 수 있습니다. 이러한 자리 표시자를 [변수 사용](https://learning.postman.com/docs/sending-requests/variables/variables/)에서 설명한 대로 변수라고 합니다. 변수를 사용하여 요청 및 스크립트에서 값을 저장하고 재사용할 수 있습니다. 예를 들어 컬렉션을 편집하여 문서에 변수를 추가할 수 있습니다:

![컬렉션 변수 탭 보기 편집](img/api_fuzzing_postman_collection_edit_variable_v18_5.png)

또는 대신 환경에 변수를 추가할 수 있습니다:

![환경 변수 보기 편집](img/api_fuzzing_postman_environment_edit_variable_v18_5.png)

그러면 URL, 헤더 및 기타 섹션에서 변수를 사용할 수 있습니다:

![변수를 사용한 요청 편집 보기](img/api_fuzzing_postman_request_edit_v18_5.png)

Postman은 좋은 UX 경험을 가진 기본 클라이언트 도구에서 스크립트로 API를 테스트하고, 보조 요청을 트리거하는 복잡한 컬렉션을 생성하고, 변수를 설정할 수 있는 더 복잡한 에코시스템으로 발전했습니다. Postman 에코시스템의 모든 기능이 지원되는 것은 아닙니다. 예를 들어 스크립트는 지원되지 않습니다. Postman 지원의 주요 초점은 Postman Client에서 사용되는 Postman Collection 정의와 워크스페이스, 환경 및 컬렉션 자체에 정의된 관련 변수를 수집하는 것입니다.

Postman을 사용하면 다양한 범위에 변수를 생성할 수 있습니다. 각 범위는 Postman 도구에서 다른 수준의 가시성을 가집니다. 예를 들어 모든 작업 정의 및 워크스페이스에서 볼 수 있는 전역 환경 범위에 변수를 만들 수 있습니다. 특정 환경이 사용하도록 선택된 경우에만 표시되고 사용되는 특정 환경 범위에 변수를 만들 수도 있습니다. 일부 범위는 항상 사용 가능하지 않습니다. 예를 들어 Postman 에코시스템에서 Postman Client에서 요청을 만들 수 있지만 이러한 요청에는 로컬 범위가 없지만 테스트 스크립트는 있습니다.

Postman의 변수 범위는 까다로운 주제일 수 있으며 모두가 익숙한 것은 아닙니다. 계속하기 전에 Postman 설명서에서 [변수 범위](https://learning.postman.com/docs/sending-requests/variables/variables/#variable-scopes)를 읽으세요.

앞서 언급했듯이 다양한 변수 범위가 있으며 각각은 Postman 문서에 유연성을 제공하는 데 사용될 수 있는 목적이 있습니다. 변수 값이 계산되는 방식에 대한 중요한 참고 사항이 있습니다(Postman 설명서 참조):

> [!note]
> 같은 이름의 변수가 두 개의 다른 범위에서 선언되면 가장 좁은 범위의 변수에 저장된 값이 사용됩니다. 예를 들어 `username`라는 전역 변수와 `username`라는 로컬 변수가 있으면 요청이 실행될 때 로컬 값이 사용됩니다.

다음은 Postman Client 및 API 퍼징에서 지원하는 변수 범위의 요약입니다:

- **Global environment (global) scope**는 워크스페이스 전체에서 사용 가능한 특별한 사전 정의 환경입니다. 전역 환경 범위는 전역 범위라고도 불릴 수 있습니다. Postman Client를 사용하면 전역 환경을 JSON 파일로 내보낼 수 있으며 API 퍼징과 함께 사용할 수 있습니다.
- **환경 범위**는 Postman Client의 사용자가 생성한 명명된 변수 그룹입니다. Postman Client는 전역 환경과 함께 단일 활성 환경을 지원합니다. 활성 사용자 생성 환경에 정의된 변수는 전역 환경에 정의된 변수보다 우선합니다. Postman Client를 사용하면 환경을 JSON 파일로 내보낼 수 있으며 API 퍼징과 함께 사용할 수 있습니다.
- **Collection scope**는 주어진 컬렉션에 선언된 변수의 그룹입니다. 컬렉션 변수는 선언된 컬렉션 및 중첩된 요청 또는 컬렉션에서 사용 가능합니다. 컬렉션 범위에 정의된 변수는 전역 환경 범위 및 환경 범위보다 우선합니다. Postman Client는 하나 이상의 컬렉션을 JSON 파일로 내보낼 수 있으며, 이 JSON 파일에는 선택한 컬렉션, 요청 및 컬렉션 변수가 포함됩니다.
- **API fuzzing scope**는 사용자가 추가 변수를 제공하거나 다른 지원되는 범위에 정의된 변수를 재정의할 수 있도록 API 퍼징에서 추가한 새로운 범위입니다. 이 범위는 Postman에서 지원되지 않습니다. API 퍼징 범위 변수는 [사용자 지정 JSON 파일 형식](#api-fuzzing-scope-custom-json-file-format)을 사용하여 제공됩니다.
  - 환경 또는 컬렉션에 정의된 값 재정의
  - 스크립트의 변수 정의
  - 지원되지 않는 _데이터 범위_에서 단일 데이터 행 정의
- **Data scope**는 이름과 값이 JSON 또는 CSV 파일에서 오는 변수의 그룹입니다. [Newman](https://learning.postman.com/docs/collections/using-newman-cli/command-line-integration-with-newman/) 또는 [Postman Collection Runner](https://learning.postman.com/docs/collections/running-collections/intro-to-collection-runs/)와 같은 Postman 컬렉션 실행기는 JSON 또는 CSV 파일의 항목 수만큼 컬렉션의 요청을 실행합니다. 이러한 변수의 좋은 사용 사례는 Postman에서 스크립트를 사용하여 테스트를 자동화하는 것입니다. API 퍼징은 CSV 또는 JSON 파일에서 데이터를 읽는 것을 지원하지 않습니다.
- **Local scope**는 Postman 스크립트에서 정의된 변수입니다. API 퍼징은 Postman 스크립트를 지원하지 않으며 따라서 스크립트에 정의된 변수를 지원하지 않습니다. 지원되는 범위 중 하나에 정의하거나 사용자 지정 JSON 형식으로 정의하여 스크립트 정의 변수에 대한 값을 제공할 수 있습니다.

모든 범위가 API 퍼징에서 지원되는 것은 아니며 스크립트에 정의된 변수는 지원되지 않습니다. 다음 표는 가장 넓은 범위부터 가장 좁은 범위 순으로 정렬되어 있습니다.

| 범위              | Postman   | API 퍼징 | 주석 |
| ------------------ |:---------:|:-----------:| :-------|
| 전역 환경 | 예       | 예         | 특별 사전 정의 환경 |
| 환경        | 예       | 예         | 명명된 환경 |
| 컬렉션         | 예       | 예         | postman 컬렉션에 정의됨 |
| API 퍼징 범위  | 아니요        | 예         | API 퍼징에서 추가한 사용자 지정 범위 |
| 데이터               | 예       | 아니요          | CSV 또는 JSON 형식의 외부 파일 |
| 로컬              | 예       | 아니요          | 스크립트에 정의된 변수 |

다양한 범위에서 변수를 정의하고 내보내는 방법에 대한 자세한 내용은 다음을 참조하세요:

- [컬렉션 변수 정의](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-collection-variables)
- [환경 변수 정의](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-environment-variables)
- [전역 변수 정의](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-global-variables)

#### Postman Client에서 내보내기 {#exporting-from-postman-client}

Postman Client를 사용하면 다양한 파일 형식을 내보낼 수 있습니다. 예를 들어 Postman 컬렉션 또는 Postman 환경을 내보낼 수 있습니다. 내보낸 환경은 전역 환경(항상 사용 가능)이거나 이전에 만든 사용자 지정 환경일 수 있습니다. Postman Collection을 내보낼 때 컬렉션 및 로컬 범위 변수에 대한 선언만 포함될 수 있으며 환경 범위 변수는 포함되지 않습니다.

환경 범위 변수에 대한 선언을 얻으려면 해당 시간에 주어진 환경을 내보내야 합니다. 각 내보낸 파일에는 선택한 환경의 변수만 포함됩니다.

다양한 지원되는 범위에서 변수를 내보내는 방법에 대한 자세한 내용은 다음을 참조하세요:

- [컬렉션 내보내기](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)
- [환경 내보내기](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [전역 환경 다운로드](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)

#### API 퍼징 범위, 사용자 지정 JSON 파일 형식 {#api-fuzzing-scope-custom-json-file-format}

사용자 지정 JSON 파일 형식은 각 객체 속성이 변수 이름을 나타내고 속성 값이 변수 값을 나타내는 JSON 객체입니다. 이 파일은 선호하는 텍스트 편집기를 사용하여 만들 수도 있고 파이프라인의 이전 작업으로 생성될 수도 있습니다.

이 예시는 API 퍼징 범위에서 `base_url` 및 `token` 두 변수를 정의합니다:

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### API 퍼징과 범위 사용 {#using-scopes-with-api-fuzzing}

범위(전역, 환경, 컬렉션 및 GitLab API 퍼징)는 [GitLab 15.1 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)에서 지원됩니다. GitLab 15.0 이전에는 컬렉션 및 GitLab API 퍼징 범위만 지원합니다.

다음 표는 범위 파일/URL을 API 퍼징 구성 변수에 매핑하기 위한 빠른 참조를 제공합니다:

| 범위              |  제공 방법 |
| ------------------ | --------------- |
| 전역 환경 | FUZZAPI_POSTMAN_COLLECTION_VARIABLES |
| 환경        | FUZZAPI_POSTMAN_COLLECTION_VARIABLES |
| 컬렉션         | FUZZAPI_POSTMAN_COLLECTION           |
| API 퍼징 범위  | FUZZAPI_POSTMAN_COLLECTION_VARIABLES |
| 데이터               | 지원되지 않음   |
| 로컬              | 지원되지 않음   |

Postman Collection 문서에는 모든 컬렉션 범위 변수가 자동으로 포함됩니다. Postman Collection은 구성 변수 `FUZZAPI_POSTMAN_COLLECTION`로 제공됩니다. 이 변수는 단일 [내보낸 Postman 컬렉션](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)으로 설정할 수 있습니다.

다른 범위의 변수는 `FUZZAPI_POSTMAN_COLLECTION_VARIABLES` 구성 변수를 통해 제공됩니다. 구성 변수는 [GitLab 15.1 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)에서 쉼표(`,`) 구분 파일 목록을 지원합니다. GitLab 15.0 이전에는 단일 파일만 지원합니다. 제공된 파일의 순서는 파일이 필요한 범위 정보를 제공하므로 중요하지 않습니다.

구성 변수 `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`를 다음으로 설정할 수 있습니다:

- [내보낸 전역 환경](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)
- [내보낸 환경](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [API 퍼징 사용자 지정 JSON 형식](#api-fuzzing-scope-custom-json-file-format)

#### 정의되지 않은 Postman 변수 {#undefined-postman-variables}

API 퍼징 엔진이 Postman 컬렉션 파일에서 사용 중인 모든 변수 참조를 찾지 못할 수 있습니다. 일부 경우는 다음과 같습니다:

- 데이터 또는 로컬 범위 변수를 사용 중이며, 앞서 설명한 대로 이러한 범위는 API 퍼징에서 지원되지 않습니다. 따라서 [API 퍼징 범위](#api-fuzzing-scope-custom-json-file-format)를 통해 이러한 변수에 대한 값이 제공되지 않았다고 가정하면 데이터 및 로컬 범위 변수의 값이 정의되지 않습니다.
- 변수 이름이 잘못 입력되었으며 이름이 정의된 변수와 일치하지 않습니다.
- Postman Client는 API 퍼징에서 지원하지 않는 새로운 동적 변수를 지원합니다.

가능한 경우 API 퍼징은 정의되지 않은 변수를 처리할 때 Postman Client와 동일한 동작을 따릅니다. 변수 참조의 텍스트는 동일하게 유지되며 텍스트 대체가 없습니다. 동일한 동작은 지원되지 않는 동적 변수에도 적용됩니다.

예를 들어 Postman Collection의 요청 정의가 변수 `{{full_url}}`를 참조하고 변수를 찾을 수 없으면 값 `{{full_url}}`로 변경되지 않은 상태로 남겨집니다.

#### 동적 Postman 변수 {#dynamic-postman-variables}

사용자가 다양한 범위 수준에서 정의할 수 있는 변수 외에도 Postman에는 동적 변수라고 하는 사전 정의된 변수 세트가 있습니다. [동적 변수](https://learning.postman.com/docs/tests-and-scripts/write-scripts/variables-list/)는 이미 정의되어 있으며 이름 앞에는 달러 기호(`$`)가 붙습니다(예: `$guid`). 동적 변수는 다른 변수처럼 사용할 수 있으며 Postman Client에서 요청/컬렉션 실행 중에 임의의 값을 생성합니다.

API 퍼징과 Postman의 중요한 차이점은 API 퍼징이 동일한 동적 변수를 사용할 때마다 동일한 값을 반환한다는 것입니다. 이는 동일한 동적 변수의 각 사용에서 임의의 값을 반환하는 Postman Client 동작과 다릅니다. 다시 말해 API 퍼징은 동적 변수에 정적 값을 사용하고 Postman은 임의의 값을 사용합니다.

스캔 프로세스 중에 지원되는 동적 변수는 다음과 같습니다:

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

이 예시에서 [전역 범위는 내보내집니다](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) Postman Client에서 `global-scope.json`로 가져오고 `FUZZAPI_POSTMAN_COLLECTION_VARIABLES` 구성 변수를 통해 API 퍼징에 제공됩니다.

`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`을 사용하는 예시는 다음과 같습니다:

```yaml
stages:
     - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: global-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### 예:  환경 범위 {#example-environment-scope}

이 예시에서 [환경 범위는 내보내집니다](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) Postman Client에서 `environment-scope.json`로 가져오고 `FUZZAPI_POSTMAN_COLLECTION_VARIABLES` 구성 변수를 통해 API 퍼징에 제공됩니다.

`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`을 사용하는 예시는 다음과 같습니다:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: environment-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### 예:  컬렉션 범위 {#example-collection-scope}

컬렉션 범위 변수는 내보낸 Postman Collection 파일에 포함되어 있으며 `FUZZAPI_POSTMAN_COLLECTION` 구성 변수를 통해 제공됩니다.

`FUZZAPI_POSTMAN_COLLECTION`을 사용하는 예시는 다음과 같습니다:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: variable-collection-dictionary.json
```

#### 예:  API 퍼징 범위 {#example-api-fuzzing-scope}

API 퍼징 범위는 API 퍼징에서 지원하지 않는 _데이터_ 및 _로컬_ 범위 변수를 정의하고 다른 범위에 정의된 기존 변수의 값을 변경하는 두 가지 주요 목적으로 사용됩니다. API 퍼징 범위는 `FUZZAPI_POSTMAN_COLLECTION_VARIABLES` 구성 변수를 통해 제공됩니다.

`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`을 사용하는 예시는 다음과 같습니다:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: api-fuzzing-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

`api-fuzzing-scope.json` 파일은 API 퍼징 [사용자 지정 JSON 파일 형식](#api-fuzzing-scope-custom-json-file-format)을 사용합니다. 이 JSON은 속성에 대한 키-값 쌍을 가진 객체입니다. 키는 변수 이름이고 값은 변수 값입니다. 예를 들어:

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### 예:  여러 범위 {#example-multiple-scopes}

이 예시에서 전역 범위, 환경 범위 및 컬렉션 범위가 구성됩니다. 첫 번째 단계는 다양한 범위를 내보내는 것입니다.

- [전역 범위 내보내기](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) `global-scope.json`로
- [환경 범위 내보내기](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) `environment-scope.json`로
- _컬렉션_ 범위를 포함하는 Postman Collection을 내보내기 `postman-collection.json`로

Postman Collection은 `FUZZAPI_POSTMAN_COLLECTION` 변수를 사용하여 제공되고 다른 범위는 `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`를 사용하여 제공됩니다. API 퍼징은 각 파일에 제공된 데이터를 사용하여 제공된 파일이 일치하는 범위를 식별할 수 있습니다.

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### 예:  변수 값 변경 {#example-changing-variables-value}

내보낸 범위를 사용할 때 변수 값을 API 퍼징과 함께 사용하도록 변경해야 하는 경우가 많습니다. 예를 들어 _컬렉션_ 범위 변수에는 `api_version` 값이 `v2`인 변수가 포함될 수 있으며 테스트에는 `v1`의 값이 필요합니다. 내보낸 컬렉션을 수정하여 값을 변경하는 대신 API 퍼징 범위를 사용하여 값을 변경할 수 있습니다. API 퍼징 범위가 다른 모든 범위보다 우선하므로 작동합니다.

컬렉션 범위 변수는 내보낸 Postman Collection 파일에 포함되어 있으며 `FUZZAPI_POSTMAN_COLLECTION` 구성 변수를 통해 제공됩니다.

API 퍼징 범위는 `FUZZAPI_POSTMAN_COLLECTION_VARIABLES` 구성 변수를 통해 제공되지만 먼저 파일을 만들어야 합니다. `api-fuzzing-scope.json` 파일은 API 퍼징 [사용자 지정 JSON 파일 형식](#api-fuzzing-scope-custom-json-file-format)을 사용합니다. 이 JSON은 속성에 대한 키-값 쌍을 가진 객체입니다. 키는 변수 이름이고 값은 변수 값입니다. 예를 들어:

```json
{
  "api_version": "v1"
}
```

CI 정의:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: api-fuzzing-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### 예:  여러 범위를 사용하여 변수 값 변경 {#example-changing-a-variables-value-with-multiple-scopes}

내보낸 범위를 사용할 때 변수 값을 API 퍼징과 함께 사용하도록 변경해야 하는 경우가 많습니다. 예를 들어 환경 범위에는 `api_version` 값이 `v2`인 변수가 포함될 수 있으며 테스트에는 `v1`의 값이 필요합니다. 내보낸 파일을 수정하여 값을 변경하는 대신 API 퍼징 범위를 사용할 수 있습니다. API 퍼징 범위가 다른 모든 범위보다 우선하므로 작동합니다.

이 예시에서 전역 범위, 환경 범위, 컬렉션 범위 및 API 퍼징 범위가 구성됩니다. 첫 번째 단계는 다양한 범위를 내보내고 만드는 것입니다.

- [전역 범위 내보내기](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) `global-scope.json`로
- [환경 범위 내보내기](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) `environment-scope.json`로
- 컬렉션 범위를 포함하는 Postman Collection을 내보내기 `postman-collection.json`로

API 퍼징 범위는 `api-fuzzing-scope.json` 파일을 만들어서 API 퍼징 [사용자 지정 JSON 파일 형식](#api-fuzzing-scope-custom-json-file-format)을 사용합니다. 이 JSON은 속성에 대한 키-값 쌍을 가진 객체입니다. 키는 변수 이름이고 값은 변수 값입니다. 예를 들어:

```json
{
  "api_version": "v1"
}
```

Postman Collection은 `FUZZAPI_POSTMAN_COLLECTION` 변수를 사용하여 제공되고 다른 범위는 `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`를 사용하여 제공됩니다. API 퍼징은 각 파일에 제공된 데이터를 사용하여 제공된 파일이 일치하는 범위를 식별할 수 있습니다.

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json,api-fuzzing-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

## 첫 스캔 실행 {#running-your-first-scan}

올바르게 구성되면 CI/CD 파이프라인에 `fuzz` 스테이지와 `apifuzzer_fuzz` 또는 `apifuzzer_fuzz_dnd` 작업이 포함됩니다. 작업은 잘못된 구성이 제공될 때만 실패합니다. 일반적인 작동 중에 퍼징 테스트 중에 결함이 식별되더라도 작업은 항상 성공합니다.

결함은 **보안** 파이프라인 탭에 스위트 이름과 함께 표시됩니다. 리포지토리 기본 브랜치에 대해 테스트할 때 퍼징 결함도 보안 및 규정 준수의 취약성 보고서에 표시됩니다.

보고된 결함의 과도한 수를 방지하기 위해 API 퍼징 스캐너는 보고하는 결함의 수를 제한합니다.

## 퍼징 결함 보기 {#viewing-fuzzing-faults}

API 퍼징 분석기는 [GitLab 취약성 화면에 결함을 채우는 데 사용](#view-details-of-an-api-fuzzing-vulnerability)되는 JSON 보고서를 생성합니다. 퍼징 결함은 심각도가 알 수 없는 취약성으로 표시됩니다.

API 퍼징이 찾는 결함에는 수동 조사가 필요하며 특정 취약성 유형과 연결되지 않습니다. 이를 조사하여 보안 이슈인지 여부와 수정해야 하는지 판단해야 합니다. 거짓 양성 수를 제한하기 위해 수행할 수 있는 구성 변경에 대한 정보는 [거짓 양성 처리](#handling-false-positives)를 참조하세요.

### API 퍼징 취약성의 세부 정보 보기 {#view-details-of-an-api-fuzzing-vulnerability}

API 퍼징에서 탐지한 결함은 라이브 웹 애플리케이션에서 발생하며 취약성인지 여부를 판단하기 위해 수동 조사가 필요합니다. 퍼징 결함은 심각도가 알 수 없는 취약성으로 포함됩니다. 퍼징 결함의 조사를 용이하게 하기 위해 전송 및 수신된 HTTP 메시지와 수행된 수정 사항에 대한 설명에 대한 자세한 정보가 제공됩니다.

퍼징 결함의 세부 정보를 보려면 다음 단계를 따르세요:

1. 프로젝트 또는 머지 리퀘스트에서 결함을 볼 수 있습니다:

   - 프로젝트에서 프로젝트의 **보안** > **취약성 보고서** 페이지로 이동합니다. 이 페이지에는 기본 브랜치의 모든 취약성만 표시됩니다.
   - 머지 리퀘스트에서 머지 리퀘스트의 **보안** 섹션으로 이동하여 **펼침** 버튼을 선택합니다. API 퍼징 결함은 **API fuzzing detected N potential vulnerabilities**라는 레이블이 붙은 섹션에서 사용 가능합니다. 결함 세부 정보를 표시하려면 제목을 선택합니다.

1. 결함의 제목을 선택하여 결함의 세부 정보를 표시합니다. 아래 표는 이러한 세부 정보를 설명합니다.

   | 필드               | 설명                                                                             |
   |:--------------------|:----------------------------------------------------------------------------------------|
   | 설명         | 수정된 내용을 포함한 결함의 설명입니다.                                   |
   | 프로젝트             | 취약성이 탐지된 네임스페이스 및 프로젝트입니다.                          |
   | 방법              | 취약성을 탐지하는 데 사용된 HTTP 메서드입니다.                                           |
   | URL                 | 취약성이 탐지된 URL입니다.                                            |
   | 요청             | 결함을 야기한 HTTP 요청입니다.                                                 |
   | 수정되지 않은 응답 | 수정되지 않은 요청의 응답입니다. 일반적인 작동 응답은 수정되지 않은 응답처럼 보입니다. |
   | 실제 응답     | 퍼징된 요청에서 받은 응답입니다.                                                  |
   | 증거            | GitLab이 결함이 발생했다고 판단한 방법입니다.                                                 |
   | 식별자         | 이 결함을 찾기 위해 사용된 퍼징 확인입니다.                                              |
   | 심각도            | 발견 사항의 심각도는 항상 알 수 없습니다.                                              |
   | 스캐너 유형        | 테스트를 수행하는 데 사용되는 스캐너입니다.                                                        |

### 보안 대시보드 {#security-dashboard}

퍼징 결함은 심각도가 알 수 없는 취약성으로 표시됩니다. 보안 대시보드는 그룹, 프로젝트 및 파이프라인의 모든 보안 취약성을 개괄적으로 파악할 수 있는 좋은 장소입니다. 자세한 내용은 [보안 대시보드 설명서](../../security_dashboard/_index.md)를 참조하세요.

### 취약성과 상호작용 {#interacting-with-the-vulnerabilities}

퍼징 결함은 심각도가 알 수 없는 취약성으로 표시됩니다. 결함이 발견된 후 상호 작용할 수 있습니다. [취약성 해결](../../vulnerabilities/_index.md) 방법에 대해 자세히 알아봅니다.

## 거짓 양성 처리 {#handling-false-positives}

거짓 양성은 두 가지 방법으로 처리할 수 있습니다:

- 거짓 양성을 생성하는 확인을 해제합니다. 이는 확인이 결함을 생성하지 않도록 합니다. 예시 확인은 `JSONFuzzingCheck` 및 `FormBodyFuzzingCheck`입니다.
- 퍼징 확인에는 결함이 식별될 때 감지하는 여러 방법이 있으며 "어설션"이라고 합니다. 어설션을 해제하고 구성할 수도 있습니다. 예를 들어 API 퍼저는 기본적으로 HTTP 상태 코드를 사용하여 실제 이슈인 경우를 식별하는 데 도움이 됩니다. API가 테스트 중에 500 오류를 반환하면 결함이 생성됩니다. 일부 프레임워크가 자주 500개 오류를 반환하므로 항상 바람직하지 않습니다.

### 확인 해제 {#turn-off-a-check}

확인은 특정 유형의 테스트를 수행하며 특정 구성 프로필에 대해 설정 및 해제할 수 있습니다. 기본 구성 파일은 사용할 수 있는 여러 프로필을 정의합니다. 구성 파일의 프로필 정의는 스캔 중에 활성화되는 모든 확인을 나열합니다. 특정 확인을 해제하려면 구성 파일의 프로필 정의에서 제거합니다. 프로필은 구성 파일의 `Profiles` 섹션에 정의됩니다.

예시 프로필 정의:

```yaml
Profiles:
  - Name: Quick-10
    DefaultProfile: Quick
    Routes:
      - Route: *Route0
        Checks:
          - Name: FormBodyFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: GeneralFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: JsonFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: XmlFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
```

`GeneralFuzzingCheck`을 해제하려면 다음 줄을 제거할 수 있습니다:

```yaml
- Name: GeneralFuzzingCheck
  Configuration:
    FuzzingCount: 10
    UnicodeFuzzing: true
```

결과는 다음 YAML입니다:

```yaml
- Name: Quick-10
  DefaultProfile: Quick
  Routes:
    - Route: *Route0
      Checks:
        - Name: FormBodyFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
        - Name: JsonFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
        - Name: XmlFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
```

### 확인에 대한 어설션 해제 {#turn-off-an-assertion-for-a-check}

어설션은 확인에서 생성된 테스트의 결함을 감지합니다. 많은 확인이 로그 분석, 응답 분석 및 상태 코드와 같은 여러 어설션을 지원합니다. 결함이 발견되면 사용된 어설션이 제공됩니다. 기본적으로 활성화되는 어설션을 식별하려면 구성 파일의 확인 기본 구성을 참조하세요. 섹션의 이름은 `Checks`입니다.

이 예시는 `FormBodyFuzzingCheck`을 보여줍니다:

```yaml
Checks:
  - Name: FormBodyFuzzingCheck
    Configuration:
      FuzzingCount: 30
      UnicodeFuzzing: true
    Assertions:
      - Name: LogAnalysisAssertion
      - Name: ResponseAnalysisAssertion
      - Name: StatusCodeAssertion
```

기본적으로 세 개의 어설션이 활성화되어 있습니다. 거짓 양성의 일반적인 원인은 `StatusCodeAssertion`입니다. 이를 해제하려면 `Profiles` 섹션에서 구성을 수정합니다. 이 예시는 다른 두 개의 어설션만 제공합니다(`LogAnalysisAssertion`, `ResponseAnalysisAssertion`). 이것은 `FormBodyFuzzingCheck`이 `StatusCodeAssertion`을 사용하지 못하도록 합니다:

```yaml
Profiles:
  - Name: Quick-10
    DefaultProfile: Quick
    Routes:
      - Route: *Route0
        Checks:
          - Name: FormBodyFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
            Assertions:
              - Name: LogAnalysisAssertion
              - Name: ResponseAnalysisAssertion
          - Name: GeneralFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: JsonFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: XmlInjectionCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
```
