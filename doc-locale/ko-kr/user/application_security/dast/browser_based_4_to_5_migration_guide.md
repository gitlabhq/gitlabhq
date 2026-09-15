---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DAST 버전 4 브라우저 기반 분석기에서 DAST 버전 5로 마이그레이션
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [DAST 프록시 기반 분석기](proxy_based_to_browser_based_migration_guide.md)는 GitLab 16.6에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/430966) 17.0에서 제거되었습니다.

{{< /history >}}

[DAST 버전 5](browser/_index.md)는 DAST 버전 4를 대체합니다. 이 문서는 DAST 버전 4 브라우저 기반 분석기에서 DAST 버전 5로 마이그레이션하기 위한 가이드입니다.

다음 조건을 모두 충족하는 경우 이 마이그레이션 가이드를 따르세요:

1. GitLab DAST를 사용하여 CI/CD 파이프라인에서 DAST 스캔을 실행합니다.
1. DAST CI/CD 작업은 DAST 템플릿 `DAST.gitlab-ci.yml` 또는 `DAST.latest.gitlab-ci.yml` 중 하나를 포함하여 구성합니다.
1. `DAST_VERSION` CI/CD 변수는 설정되어 있지 않거나 `4` 이하로 설정되어 있습니다.
1. `DAST_BROWSER_SCAN` CI/CD 변수는 `true`로 설정됩니다.

다음 섹션을 읽고 권장 변경 사항을 적용하여 DAST 버전 5로 마이그레이션합니다.

## DAST 분석기 버전 {#dast-analyzer-versions}

DAST는 두 가지 주요 버전으로 제공됩니다: 4 및 5. GitLab 17.0부터 DAST 템플릿 `DAST.gitlab-ci.yml` 및 `DAST.latest.gitlab-ci.yml`는 기본적으로 DAST 버전 5를 사용합니다. DAST 버전 4를 계속 사용할 수 있지만, DAST 버전 5로 마이그레이션하는 동안 임시 조치로만 사용해야 합니다. 자세한 내용은 [버전 4 계속 사용](#continuing-to-use-version-4)을 참조하세요.

각 DAST 주요 버전은 다른 분석기를 실행합니다:

- DAST 버전 4는 프록시 기반 또는 브라우저 기반 분석기를 실행할 수 있으며, 기본적으로 프록시 기반 분석기를 사용합니다.
- DAST 버전 5는 브라우저 기반 분석기만 실행합니다.

DAST 버전 5는 새로운 CI/CD 변수 세트를 사용합니다. DAST 버전 4 변수 이름에 대한 별칭이 생성되었습니다.

변경할 사항:

- `DAST_WEBSITE`을(를) `DAST_TARGET_URL`(으)로 이름을 바꾸세요.
- `DAST_VERSION`을(를) 5로 설정하는 새로운 템플릿 사용을 시작할 때, `DAST_VERSION` CI/CD 변수가 설정되어 있지 않은지 확인하세요.

## 버전 4 계속 사용 {#continuing-to-use-version-4}

GitLab 18.0까지 DAST 버전 4 프록시 기반 분석기를 계속 사용할 수 있습니다. 이 레거시 분석기의 버그 및 취약성은 수정되지 않습니다.

변경할 사항:

- DAST 버전 4를 계속 사용하려면 CI/CD 변수 `DAST_VERSION` 변수를 4로 설정하세요.

## 아티팩트 {#artifacts}

GitLab 17.0은 DAST 버전 5에서 생성된 아티팩트를 DAST CI 작업에 자동으로 게시합니다.

변경할 사항:

- 파일 로그, 크롤 그래프 또는 인증 보고서를 노출하기 위해 재정의한 경우 CI 작업 정의에서 `artifacts`을(를) 제거하세요.
- CI/CD 변수 `DAST_BROWSER_FILE_LOG_PATH` 및 `DAST_FILE_LOG_PATH` 는 더 이상 필요하지 않습니다.

## 취약성 검사 범위 {#vulnerability-check-coverage}

브라우저 기반 DAST 버전 4는 브라우저 기반 분석기에 포함되지 않은 활성 검사에 대해 프록시 기반 분석기 검사를 사용합니다. 브라우저 기반 DAST 버전 5는 프록시 기반 분석기를 포함하지 않으므로 버전 5로 마이그레이션할 때 검사 범위의 간격이 있습니다.

브라우저 기반 분석기가 포함하지 않는 프록시 기반 활성 검사가 하나 있습니다. 남은 활성 검사의 마이그레이션은 [에픽 13411](https://gitlab.com/groups/gitlab-org/-/epics/13411)에서 제안됩니다. 마지막 검사가 마이그레이션될 때까지 DAST 버전 4로 유지하려면 [버전 4 계속 사용](#continuing-to-use-version-4)을 참조하세요.

남은 검사:

- CWE-79: 교차 사이트 스크립팅(XSS)

에픽 [BBD의 남은 활성 검사](https://gitlab.com/groups/gitlab-org/-/epics/13411)에서 남은 검사의 진행 상황을 확인하세요.

## CI/CD 변수 변경 {#changes-to-cicd-variables}

다음 표는 각 브라우저 기반 분석기 DAST 버전 4 CI/CD 변수에 필요한 마이그레이션 조치를 설명합니다. 브라우저 기반 분석기 구성에 대한 자세한 내용은 [구성](browser/configuration/_index.md)을 참조하세요.

| DAST 버전 4 CI/CD 변수               | 필요한 조치    | 참고                                         |
|:--------------------------------------------|:-------------------|:----------------------------------------------|
| `DAST_ADVERTISE_SCAN`                       | 이름 바꾸기             | `DAST_REQUEST_ADVERTISE_SCAN`(으)로              |
| `DAST_AFTER_LOGIN_ACTIONS`                  | 이름 바꾸기             | `DAST_AUTH_AFTER_LOGIN_ACTIONS`(으)로            |
| `DAST_AUTH_COOKIES`                         | 이름 바꾸기             | `DAST_AUTH_COOKIE_NAMES`(으)로                   |
| `DAST_AUTH_DISABLE_CLEAR_FIELDS`            | 이름 바꾸기             | `DAST_AUTH_CLEAR_INPUT_FIELDS`(으)로             |
| `DAST_AUTH_REPORT`                          | 조치 불필요 |                                               |
| `DAST_AUTH_TYPE`                            | 조치 불필요 |                                               |
| `DAST_AUTH_URL`                             | 조치 불필요 |                                               |
| `DAST_AUTH_VERIFICATION_LOGIN_FORM`         | 이름 바꾸기             | `DAST_AUTH_SUCCESS_IF_NO_LOGIN_FORM`(으)로       |
| `DAST_AUTH_VERIFICATION_SELECTOR`           | 이름 바꾸기             | `DAST_AUTH_SUCCESS_IF_ELEMENT_FOUND`(으)로       |
| `DAST_AUTH_VERIFICATION_URL`                | 이름 바꾸기             | `DAST_AUTH_SUCCESS_IF_AT_URL`(으)로              |
| `DAST_BROWSER_PATH_TO_LOGIN_FORM`           | 이름 바꾸기             | `DAST_AUTH_BEFORE_LOGIN_ACTIONS`(으)로           |
| `DAST_BROWSER_ACTION_STABILITY_TIMEOUT`     | 교체            | `DAST_PAGE_DOM_READY_TIMEOUT`(으)로 교체            |
| `DAST_BROWSER_ACTION_TIMEOUT`               | 제거             | 지원되지 않음                                 |
| `DAST_BROWSER_ALLOWED_HOSTS`                | 이름 바꾸기             | `DAST_SCOPE_ALLOW_HOSTS`(으)로                   |
| `DAST_BROWSER_CACHE`                        | 이름 바꾸기             | `DAST_USE_CACHE`(으)로                           |
| `DAST_BROWSER_COOKIES`                      | 이름 바꾸기             | `DAST_REQUEST_COOKIES`(으)로                     |
| `DAST_BROWSER_CRAWL_GRAPH`                  | 이름 바꾸기             | `DAST_CRAWL_GRAPH`(으)로                         |
| `DAST_BROWSER_CRAWL_TIMEOUT`                | 이름 바꾸기             | `DAST_CRAWL_TIMEOUT`(으)로                       |
| `DAST_BROWSER_DEVTOOLS_LOG`                 | 이름 바꾸기             | `DAST_LOG_DEVTOOLS_CONFIG`(으)로                 |
| `DAST_BROWSER_DOM_READY_AFTER_TIMEOUT`      | 이름 바꾸기             | `DAST_PAGE_DOM_STABLE_WAIT`(으)로                |
| `DAST_BROWSER_ELEMENT_TIMEOUT`              | 이름 바꾸기             | `DAST_PAGE_ELEMENT_READY_TIMEOUT`(으)로          |
| `DAST_BROWSER_EXCLUDED_ELEMENTS`            | 이름 바꾸기             | `DAST_SCOPE_EXCLUDE_ELEMENTS`(으)로              |
| `DAST_BROWSER_EXCLUDED_HOSTS`               | 이름 바꾸기             | `DAST_SCOPE_EXCLUDE_HOSTS`(으)로                 |
| `DAST_BROWSER_EXTRACT_ELEMENT_TIMEOUT`      | 이름 바꾸기             | `DAST_CRAWL_EXTRACT_ELEMENT_TIMEOUT`(으)로       |
| `DAST_BROWSER_FILE_LOG`                     | 이름 바꾸기             | `DAST_LOG_FILE_CONFIG`(으)로                     |
| `DAST_BROWSER_FILE_LOG_PATH`                | 제거             | 더 이상 필요하지 않음                            |
| `DAST_BROWSER_IGNORED_HOSTS`                | 이름 바꾸기             | `DAST_SCOPE_IGNORE_HOSTS`(으)로                  |
| `DAST_BROWSER_INCLUDE_ONLY_RULES`           | 이름 바꾸기             | `DAST_CHECKS_TO_RUN`(으)로                       |
| `DAST_BROWSER_LOG`                          | 이름 바꾸기             | `DAST_LOG_CONFIG`(으)로                          |
| `DAST_BROWSER_LOG_CHROMIUM_OUTPUT`          | 이름 바꾸기             | `DAST_LOG_BROWSER_OUTPUT`(으)로                  |
| `DAST_BROWSER_MAX_ACTIONS`                  | 이름 바꾸기             | `DAST_CRAWL_MAX_ACTIONS`(으)로                   |
| `DAST_BROWSER_MAX_DEPTH`                    | 이름 바꾸기             | `DAST_CRAWL_MAX_DEPTH`(으)로                     |
| `DAST_BROWSER_MAX_RESPONSE_SIZE_MB`         | 이름 바꾸기             | `DAST_PAGE_MAX_RESPONSE_SIZE_MB`(으)로           |
| `DAST_BROWSER_NAVIGATION_STABILITY_TIMEOUT` | 이름 바꾸기             | `DAST_PAGE_DOM_READY_TIMEOUT`(으)로              |
| `DAST_BROWSER_NAVIGATION_TIMEOUT`           | 이름 바꾸기             | `DAST_PAGE_READY_AFTER_NAVIGATION_TIMEOUT`(으)로 |
| `DAST_BROWSER_NUMBER_OF_BROWSERS`           | 이름 바꾸기             | `DAST_CRAWL_WORKER_COUNT`(으)로                  |
| `DAST_BROWSER_PAGE_LOADING_SELECTOR`        | 이름 바꾸기             | `DAST_PAGE_IS_LOADING_ELEMENT`(으)로             |
| `DAST_BROWSER_PAGE_READY_SELECTOR`          | 이름 바꾸기             | `DAST_PAGE_IS_READY_ELEMENT`(으)로               |
| `DAST_BROWSER_PASSIVE_CHECK_WORKERS`        | 이름 바꾸기             | `DAST_PASSIVE_SCAN_WORKER_COUNT`(으)로           |
| `DAST_BROWSER_SCAN`                         | 제거             | 더 이상 필요하지 않음                            |
| `DAST_BROWSER_SEARCH_ELEMENT_TIMEOUT`       | 이름 바꾸기             | `DAST_CRAWL_SEARCH_ELEMENT_TIMEOUT`(으)로        |
| `DAST_BROWSER_STABILITY_TIMEOUT`            | 이름 바꾸기             | `DAST_PAGE_READY_AFTER_ACTION_TIMEOUT`(으)로     |
| `DAST_EXCLUDE_RULES`                        | 이름 바꾸기             | `DAST_CHECKS_TO_EXCLUDE`(으)로                   |
| `DAST_EXCLUDE_URLS`                         | 이름 바꾸기             | `DAST_SCOPE_EXCLUDE_URLS`(으)로                  |
| `DAST_FF_ENABLE_BAS`                        | 제거             | 지원되지 않음                                 |
| `DAST_FILE_LOG_PATH`                        | 제거             | 더 이상 필요하지 않음                            |
| `DAST_FIRST_SUBMIT_FIELD`                   | 이름 바꾸기             | `DAST_AUTH_FIRST_SUBMIT_FIELD`(으)로             |
| `DAST_FULL_SCAN_ENABLED`                    | 이름 바꾸기             | `DAST_FULL_SCAN`(으)로                           |
| `DAST_PASSWORD`                             | 이름 바꾸기             | `DAST_AUTH_PASSWORD`(으)로                       |
| `DAST_PASSWORD_FIELD`                       | 이름 바꾸기             | `DAST_AUTH_PASSWORD_FIELD`(으)로                 |
| `DAST_PATHS`                                | 이름 바꾸기             | `DAST_TARGET_PATHS`(으)로                        |
| `DAST_PATHS_FILE`                           | 이름 바꾸기             | `DAST_TARGET_PATHS_FROM_FILE`(으)로              |
| `DAST_PKCS12_CERTIFICATE_BASE64`            | 조치 불필요 |                                               |
| `DAST_PKCS12_PASSWORD`                      | 조치 불필요 |                                               |
| `DAST_REQUEST_HEADERS`                      | 조치 불필요 |                                               |
| `DAST_SKIP_TARGET_CHECK`                    | 이름 바꾸기             | `DAST_TARGET_CHECK_SKIP`(으)로                   |
| `DAST_SUBMIT_FIELD`                         | 이름 바꾸기             | `DAST_AUTH_SUBMIT_FIELD`(으)로                   |
| `DAST_TARGET_AVAILABILITY_TIMEOUT`          | 이름 바꾸기             | `DAST_TARGET_CHECK_TIMEOUT`(으)로                |
| `DAST_USERNAME`                             | 이름 바꾸기             | `DAST_AUTH_USERNAME`(으)로                       |
| `DAST_USERNAME_FIELD`                       | 이름 바꾸기             | `DAST_AUTH_USERNAME_FIELD`(으)로                 |
| `DAST_WEBSITE`                              | 이름 바꾸기             | `DAST_TARGET_URL`(으)로<br/>GitLab Self-Managed: `DAST_WEBSITE`을(를) 제거하기 전에 인스턴스를 버전 17.0 이상으로 업그레이드하세요. 이 변수는 GitLab의 17.0 이전 버전에 포함된 `DAST.gitlab-ci.yml` 파일을 사용하는 경우 필요합니다. |
