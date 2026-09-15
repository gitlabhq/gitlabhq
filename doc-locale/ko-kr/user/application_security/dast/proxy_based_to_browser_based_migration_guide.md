---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DAST 프록시 기반 분석기에서 DAST 버전 5로 마이그레이션
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [DAST 프록시 기반 분석기](proxy_based_to_browser_based_migration_guide.md)는 GitLab 16.6에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/430966) 17.0에서 제거되었습니다.

{{< /history >}}

[DAST 버전 5](browser/_index.md)는 프록시 기반 분석기를 브라우저 기반 분석기로 교체합니다. 이 문서는 프록시 기반 분석기에서 DAST 버전 5로 마이그레이션하기 위한 안내입니다.

다음 조건을 모두 충족하는 경우 이 마이그레이션 가이드를 따르세요:

1. GitLab DAST를 사용하여 CI/CD 파이프라인에서 DAST 스캔을 실행합니다.
1. DAST CI/CD 작업은 DAST 템플릿 `DAST.gitlab-ci.yml` 또는 `DAST.latest.gitlab-ci.yml` 중 하나를 포함하여 구성합니다.
1. `DAST_VERSION` CI/CD 변수는 설정되어 있지 않거나 `4` 이하로 설정되어 있습니다.
1. CI/CD 변수 `DAST_BROWSER_SCAN`이(가) 설정되지 않았거나 `false`로 설정되어 있습니다.

다음 섹션을 읽고 권장 변경 사항을 적용하여 DAST 버전 5로 마이그레이션합니다.

## DAST 분석기 버전 {#dast-analyzer-versions}

DAST는 두 가지 주요 버전으로 제공됩니다: 4 및 5. GitLab 17.0부터 DAST 템플릿 `DAST.gitlab-ci.yml` 및 `DAST.latest.gitlab-ci.yml`는 기본적으로 DAST 버전 5를 사용합니다. DAST 버전 4를 계속 사용할 수 있지만, DAST 버전 5로 마이그레이션하는 동안 임시 조치로만 사용해야 합니다. 자세한 내용은 [프록시 기반 분석기 사용 계속](#continuing-to-use-the-proxy-based-analyzer)을(를) 참조하세요.

각 DAST 주요 버전은 기본적으로 다른 분석기를 사용합니다:

- DAST 버전 4는 프록시 기반 분석기를 사용합니다.
- DAST 버전 5는 브라우저 기반 분석기를 사용합니다.

DAST 버전 5는 새로운 CI/CD 변수 세트를 사용합니다. DAST 버전 4 변수 이름에 대한 별칭이 생성되었습니다.

## 프록시 기반 분석기 사용 계속 {#continuing-to-use-the-proxy-based-analyzer}

GitLab 18.0까지 프록시 기반 DAST 분석기를 사용할 수 있습니다. 이 레거시 분석기의 버그 및 취약성은 수정되지 않습니다.

변경할 사항:

- 프록시 기반 분석기를 계속 사용하려면 CI/CD 변수 `DAST_VERSION`을(를) `4`로 설정합니다.

## 아티팩트 {#artifacts}

GitLab 17.0은 DAST 버전 5에서 생성된 아티팩트를 DAST CI 작업에 자동으로 게시합니다.

변경할 사항:

- 파일 로그, 크롤 그래프 또는 인증 보고서를 노출하기 위해 재정의한 경우 CI 작업 정의에서 `artifacts`을(를) 제거하세요.
- CI/CD 변수 `DAST_BROWSER_FILE_LOG_PATH` 및 `DAST_FILE_LOG_PATH` 는 더 이상 필요하지 않습니다.

## 인증 {#authentication}

프록시 기반 분석기와 DAST 버전 5는 모두 브라우저 기반 분석기를 사용하여 인증합니다. DAST 버전 5로 업그레이드해도 인증이 작동하는 방식은 변경되지 않습니다.

변경할 사항:

- 인증 CI/CD 변수의 이름을 바꾸려면 `DAST_AUTH` 접두사가 있는 변수를 참조하세요.
- 아직 완료되지 않은 경우 `DAST_SCOPE_EXCLUDE_URLS`을(를) 사용하여 로그아웃 URL을 스캔에서 제외합니다.

## 크롤링 {#crawling}

DAST 버전 5는 브라우저에서 대상 애플리케이션을 크롤링하여 더 나은 크롤 범위를 제공합니다. 이는 동등한 프록시 기반 분석기 크롤과 비교하여 더 많은 리소스를 실행해야 할 수 있습니다.

변경할 사항:

- `DAST_TARGET_URL`을(를) `DAST_WEBSITE` 대신 사용합니다.
- `DAST_CRAWL_TIMEOUT`을(를) `DAST_SPIDER_MINS` 대신 사용합니다.
- CI/CD 변수 `DAST_USE_AJAX_SPIDER`, `DAST_SPIDER_START_AT_HOST`, `DAST_ZAP_CLI_OPTIONS` 및 `DAST_ZAP_LOG_CONFIGURATION`는 더 이상 지원되지 않습니다.
- DAST이(가) 10 MB보다 큰 응답 본문을 처리해야 하는 경우 `DAST_PAGE_MAX_RESPONSE_SIZE_MB`을(를) 구성합니다.
- DAST 작업을 실행하는 GitLab 러너에 더 많은 CPU 리소스를 제공하는 것을 고려합니다.

## 범위 {#scope}

DAST 버전 5는 프록시 기반 분석기와 비교하여 범위에 대한 더 많은 제어를 제공합니다.

변경할 사항:

- `DAST_SCOPE_ALLOW_HOSTS`을(를) `DAST_ALLOWED_HOSTS` 대신 사용합니다.
- `DAST_TARGET_URL`의 도메인이 `DAST_SCOPE_ALLOW_HOSTS`에 자동으로 추가되므로 대상 애플리케이션 API 및 자산 엔드포인트에 대한 도메인을 추가하는 것을 고려합니다.
- 도메인을 `DAST_SCOPE_EXCLUDE_HOSTS`에 추가하여 스캔에서 제거합니다(인증 중 제외).

## 취약성 검사 {#vulnerability-checks}

### 필수 변경 사항 {#changes-required}

DAST 버전 5는 GitLab에서 빌드한 취약성 정의를 사용하며 이는 프록시 기반 분석기 정의에 직접 매핑되지 않습니다.

변경할 사항:

- `DAST_CHECKS_TO_RUN`을(를) `DAST_ONLY_INCLUDE_RULES` 대신 사용합니다. 사용된 ID를 GitLab DAST 취약성 검사 ID로 변경합니다.
- `DAST_CHECKS_TO_EXCLUDE`을(를) `DAST_EXCLUDE_RULES` 대신 사용합니다. 사용된 ID를 GitLab DAST 취약성 검사 ID로 변경합니다.
- GitLab DAST 취약성 검사의 설명 및 ID에 대해 [취약성 검사](browser/checks/_index.md) 문서를 참조하세요.
- CI/CD 변수 `DAST_AGGREGATE_VULNERABILITIES` 및 `DAST_MAX_URLS_PER_VULNERABILITY`는 더 이상 지원되지 않습니다.

### 마이그레이션이 다른 취약성을 생성하는 이유 {#why-migrating-produces-different-vulnerabilities}

프록시 기반 스캔과 브라우저 기반 DAST 버전 5 스캔은 다른 취약성 검사 세트를 사용하기 때문에 동일한 결과를 생성하지 않습니다.

DAST 버전 5에는 너무 많은 거짓 양성을 생성하거나 최신 브라우저가 취약성을 악용하도록 허용하지 않기 때문에 실행할 가치가 없거나 더 이상 관련성이 없는 것으로 간주되는 프록시 기반 검사에 해당하는 것이 없습니다. DAST 버전 5에는 프록시 기반 분석기가 없는 검사가 포함되어 있습니다.

DAST 버전 5 스캔은 애플리케이션의 더 나은 범위를 제공하므로 더 많은 사이트가 스캔되기 때문에 더 많은 취약성을 식별할 수 있습니다.

### 범위 {#coverage}

아직 브라우저 기반 DAST 분석기에서 구현되지 않은 프록시 기반 활성 검사가 하나 있습니다. 남은 활성 검사의 마이그레이션은 [에픽 13411](https://gitlab.com/groups/gitlab-org/-/epics/13411)에서 제안됩니다. 마지막 검사가 마이그레이션될 때까지 DAST 버전 4에 남아 있으려면 [프록시 기반 분석기 사용 계속](#continuing-to-use-the-proxy-based-analyzer)을(를) 참조하세요.

남은 검사:

- CWE-79: 교차 사이트 스크립팅(XSS)

## 온디맨드 스캔 {#on-demand-scans}

온디맨드 스캔은 GitLab 17.0부터 [DAST 버전 5](https://gitlab.com/groups/gitlab-org/-/epics/11429)를 사용하여 브라우저 기반 스캔을 실행합니다.

## 문제 해결 {#troubleshooting}

DAST 버전 5 [문제 해결](browser/troubleshooting.md) 문서를 참조하세요.

## CI/CD 변수 변경 {#changes-to-cicd-variables}

다음 표는 각 프록시 기반 분석기 CI/CD 변수에 필요한 마이그레이션 작업을 설명합니다. DAST 버전 5 구성에 대한 자세한 내용은 [구성](browser/configuration/_index.md)을(를) 참조하세요.

| 프록시 기반 분석기 CI/CD 변수  | 필요한 조치          | 참고                                                                                    |
|:-------------------------------------|:-------------------------|:-----------------------------------------------------------------------------------------|
| `DAST_ADVERTISE_SCAN`                | 이름 바꾸기                   | `DAST_REQUEST_ADVERTISE_SCAN`(으)로                                                         |
| `DAST_ALLOWED_HOSTS`                 | 이름 바꾸기                   | `DAST_SCOPE_ALLOW_HOSTS`(으)로                                                              |
| `DAST_API_HOST_OVERRIDE`             | 제거                   | 지원되지 않음                                                                            |
| `DAST_API_SPECIFICATION`             | 제거                   | 지원되지 않음                                                                            |
| `DAST_AUTH_EXCLUDE_URLS`             | 이름 바꾸기                   | `DAST_SCOPE_EXCLUDE_URLS`(으)로                                                             |
| `DAST_AUTO_UPDATE_ADDONS`            | 제거                   | 지원되지 않음                                                                            |
| `DAST_BROWSER_FILE_LOG_PATH`         | 제거                   | 더 이상 필요하지 않음                                                                       |
| `DAST_DEBUG`                         | 제거                   | 지원되지 않음                                                                            |
| `DAST_EXCLUDE_RULES`                 | 이름 바꾸기, 검사 ID 업데이트 | `DAST_CHECKS_TO_EXCLUDE`(으)로                                                              |
| `DAST_EXCLUDE_URLS`                  | 이름 바꾸기                   | `DAST_SCOPE_EXCLUDE_URLS`(으)로                                                             |
| `DAST_FILE_LOG_PATH`                 | 제거                   | 더 이상 필요하지 않음                                                                       |
| `DAST_FULL_SCAN_ENABLED`             | 이름 바꾸기                   | `DAST_FULL_SCAN`(으)로                                                                      |
| `DAST_HTML_REPORT`                   | 제거                   | 지원되지 않음                                                                            |
| `DAST_INCLUDE_ALPHA_VULNERABILITIES` | 제거                   | 지원되지 않음                                                                            |
| `DAST_MARKDOWN_REPORT`               | 제거                   | 지원되지 않음                                                                            |
| `DAST_MASK_HTTP_HEADERS`             | 제거                   | 지원되지 않음                                                                            |
| `DAST_MAX_URLS_PER_VULNERABILITY`    | 제거                   | 지원되지 않음                                                                            |
| `DAST_ONLY_INCLUDE_RULES`            | 이름 바꾸기, 검사 ID 업데이트 | `DAST_CHECKS_TO_RUN`(으)로                                                                  |
| `DAST_PATHS`                         | 없음                     | 지원됨                                                                                |
| `DAST_PATHS_FILE`                    | 없음                     | 지원됨                                                                                |
| `DAST_PKCS12_CERTIFICATE_BASE64`     | 없음                     | 지원됨                                                                                |
| `DAST_PKCS12_PASSWORD`               | 없음                     | 지원됨                                                                                |
| `DAST_SKIP_TARGET_CHECK`             | 없음                     | 지원됨                                                                                |
| `DAST_SPIDER_MINS`                   | 변경                   | 기간을 사용하여 `DAST_CRAWL_TIMEOUT`로 변경합니다. 예를 들어 `5` 대신 `5m`을(를) 사용합니다.          |
| `DAST_SPIDER_START_AT_HOST`          | 제거                   | 지원되지 않음                                                                            |
| `DAST_TARGET_AVAILABILITY_TIMEOUT`   | 변경                   | 기간을 사용하여 `DAST_TARGET_CHECK_TIMEOUT`로 변경합니다. 예를 들어 `60` 대신 `60s`을(를) 사용합니다. |
| `DAST_USE_AJAX_SPIDER`               | 제거                   | 지원되지 않음                                                                            |
| `DAST_XML_REPORT`                    | 제거                   | 지원되지 않음                                                                            |
| `DAST_WEBSITE`                              | 이름 바꾸기             | `DAST_TARGET_URL`(으)로<br/>GitLab Self-Managed: `DAST_WEBSITE`을(를) 제거하기 전에 인스턴스를 버전 17.0 이상으로 업그레이드하세요. 이 변수는 GitLab의 17.0 이전 버전에 포함된 `DAST.gitlab-ci.yml` 파일을 사용하는 경우 필요합니다. |
| `DAST_ZAP_CLI_OPTIONS`               | 제거                   | 지원되지 않음                                                                            |
| `DAST_ZAP_LOG_CONFIGURATION`         | 제거                   | 지원되지 않음                                                                            |
| `SECURE_ANALYZERS_PREFIX`            | 없음                     | 지원됨                                                                                |
