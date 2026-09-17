---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DAST 스캔 문제 해결
---

다음의 문제 해결 시나리오는 고객 지원 사례에서 수집되었습니다. 여기에서 다루지 않은 문제가 발생하거나 여기의 정보로 문제가 해결되지 않으면 지원 티켓을 생성합니다. 자세한 내용은 [GitLab 지원](https://support.gitlab.com/) 페이지를 참조합니다.

## 문제가 발생했을 때 {#when-something-goes-wrong}

DAST 스캔에 문제가 발생했을 때:

- DAST를 처음 설정하는 경우 [DAST 설정](#setting-up-dast)을 확인합니다.
- 특정 오류 메시지가 있는 경우 [알려진 문제](#known-problems)를 확인합니다.

그렇지 않으면 다음 질문에 답변하여 문제를 발견해봅니다:

- [예상되는 결과는 무엇입니까?](#what-is-the-expected-outcome)
- [그 결과가 사용자가 달성할 수 있습니까?](#is-the-outcome-achievable-by-a-human)
- [DAST가 작동하지 않을 이유가 있습니까?](#any-reason-why-dast-would-not-work)
- [애플리케이션은 어떻게 작동합니까?](#how-does-your-application-work)
- [DAST는 무엇을 수행합니까?](#what-is-dast-doing)

### DAST 설정 {#setting-up-dast}

DAST를 처음 설정할 때 다음의 문제가 발생할 수 있습니다.

#### 구성 유효성 검사 실패: 필수 필드 URL이 설정되지 않음 {#configuration-validation-failed-required-field-url-was-not-set}

대상 URL을 정의하지 않고 DAST 템플릿을 포함하면 파이프라인이 구성 유효성 검사 중에 다음 오류로 실패합니다:

```plaintext
ERR MAIN  configuration validation failed error="the required field URL was not set"
```

이 오류는 DAST가 어느 URL을 스캔할지 모른다는 것을 나타냅니다. 이 문제를 해결하려면 다음의 방법 중 하나로 대상 URL을 정의합니다:

- `DAST_TARGET_URL` CI/CD 변수를 `.gitlab-ci.yml` 파일에 설정합니다:

  ```yaml
  stages:
    - dast

  include:
    - template: Security/DAST.gitlab-ci.yml

  dast:
    variables:
      DAST_TARGET_URL: "https://example.com"
  ```

- 프로젝트의 루트에 `environment_url.txt` 파일을 생성하고 대상 URL을 추가합니다. 이 방법을 사용하여 동적 환경의 애플리케이션을 테스트합니다.

#### 러너가 대상 애플리케이션에 연결할 수 없음 {#runner-cannot-connect-to-target-application}

러너가 대상 애플리케이션에 도달할 수 없으면 DAST 스캔이 연결 오류로 실패합니다. 이것은 일반적으로 네트워크 구성 또는 방화벽 문제로 인해 발생합니다.

DAST는 지정한 URL을 사용하여 애플리케이션에 연결해야 합니다:

- `DAST_TARGET_URL` 또는 `DAST_AUTH_URL`에 포트 번호가 포함되어 있으면 러너가 해당 특정 포트에 액세스할 수 있는지 확인합니다.
- URL에 포트가 지정되지 않으면 DAST는 표준 포트를 사용합니다:
  - HTTP URL의 경우 포트 `80` (예: `http://example.com`).
  - HTTPS URL의 경우 포트 `443` (예: `https://example.com`).

연결 문제의 일반적인 원인은 다음을 포함합니다:

- 혼합 HTTP 및 HTTPS 콘텐츠. 애플리케이션이 HTTP와 HTTPS를 모두 사용할 수 있습니다. 예를 들어 대상 URL이 `http://example.com`이지만 사이트가 `https://example.com`에서 리소스를 로드하는 경우 러너가 두 포트 모두에 액세스할 수 있는지 확인합니다.
- 사용자 지정 포트. 애플리케이션이 비표준 포트에서 실행되는 경우 `DAST_TARGET_URL`에 포함시킵니다. 예를 들어, `https://example.com:8443`입니다.
- 방화벽 규칙. 애플리케이션이 방화벽 뒤에 있으면 러너의 IP 주소에서의 트래픽을 허용하도록 규칙을 구성합니다.
- 내부 및 외부 네트워크. 러너가 애플리케이션에 도달할 수 있는 네트워크에 있는지 확인합니다. 예를 들어 내부 네트워크의 스테이징 환경에서 테스트하는 경우 동일한 네트워크의 러너를 사용합니다.

#### 대상 연결 문제 {#target-connection-issues}

DAST가 스캔을 시작하기 전에 대상 URL에 도달할 수 있는지 확인합니다. 대상 URL에 도달할 수 없으면 DAST는 문제를 진단하는 데 도움이 되는 자세한 오류 메시지를 생성합니다. 기본적으로 DAST는 2초마다 최대 60초까지 연결을 다시 시도합니다. DAST가 연결을 다시 시도하는 시간을 `DAST_TARGET_CHECK_TIMEOUT`으로 구성할 수 있습니다.

연결 문제가 발생하는 경우:

1. `DAST_TARGET_URL` 구성을 확인합니다.
   - 호스트 이름, 포트 또는 프로토콜의 오타를 확인합니다.
   - URL에 프로토콜(`http://` 또는 `https://`)이 포함되어 있는지 확인합니다.
   - 포트 번호가 애플리케이션이 실행되는 위치와 일치하는지 확인합니다.

1. 러너에서 연결을 테스트합니다.
   - 연결 테스트: `curl --verbose "http://your-target-url:port"`
   - DNS 확인: `nslookup your-hostname.com`
   - 포트가 열려 있는지 확인: `nc -zv your-hostname.com port`

1. 애플리케이션이 실행 중인지 확인합니다.
   - 애플리케이션이 성공적으로 시작되었는지 확인합니다.
   - 애플리케이션 로그에서 시작 오류를 검토합니다.
   - 데이터베이스 및 API를 포함한 모든 종속성을 사용할 수 있는지 확인합니다.

1. 네트워크 및 방화벽 구성을 확인합니다.
   - 방화벽 규칙이 필요한 포트에서의 트래픽을 허용하는지 확인합니다.
   - 내부 애플리케이션의 경우 러너가 내부 DNS 서버에 액세스할 수 있는지 확인합니다.

1. 애플리케이션이 시작되거나 정상이 되는 데 오래 걸리는 경우 타임아웃을 증가시킵니다:

   ```yaml
      variables:
        DAST_TARGET_CHECK_TIMEOUT: "5m"  # Wait up to 5 minutes
   ```

#### DNS 조회 실패 {#dns-lookup-failed}

`DNS lookup failed`과 같은 오류가 표시될 수 있습니다. 이것은 DAST가 제공한 호스트 이름에 대한 서버 주소를 찾을 수 없을 때 발생합니다. 그 이유는:

- `DAST_TARGET_URL`의 호스트 이름이 잘못되었거나 오타가 있습니다.
- 도메인이 등록되지 않았거나 존재하지 않습니다.
- 네트워크 또는 러너 환경에 DNS 확인 문제가 있습니다.

#### 연결 거부됨 {#connection-refused}

`connection refused`이라고 말하는 오류가 표시될 수 있습니다. 이것은 일반적으로 서버는 존재하지만 다음과 같은 경우에 발생합니다:

- 애플리케이션이 아직 시작을 마치지 못했습니다.
- 애플리케이션이 지정된 것과 다른 포트에서 실행 중입니다.
- 방화벽이 러너와 애플리케이션 간의 연결을 차단합니다.
- 애플리케이션이 충돌했거나 시작에 실패했습니다.

#### 대상이 HTTP 5xx 오류로 응답함 {#target-responded-with-http-5xx-error}

대상 애플리케이션이 `HTTP 5xx` 오류로 응답할 수 있습니다. 이것은 애플리케이션에 도달할 수 있지만 `500 Internal Server Error`, `502 Bad Gateway`, `503 Service Unavailable` 또는 `504 Gateway Timeout`와 같은 서버 오류로 응답하는 경우에 발생합니다.

다음과 같은 경우에 서버 오류가 표시될 수 있습니다:

- 애플리케이션이 시작 중이고 완전히 준비되지 않았습니다.
- 애플리케이션에 구성 오류가 있습니다.
- 데이터베이스 및 API와 같은 필수 종속성을 사용할 수 없습니다.

### 예상되는 결과는 무엇입니까? {#what-is-the-expected-outcome}

DAST 스캔의 문제를 마주친 많은 사용자는 스캐너가 수행할 것으로 생각되는 것에 대해 좋은 수준의 생각을 가지고 있습니다. 예를 들어 특정 페이지를 스캔하지 않거나 페이지의 버튼을 선택하지 않습니다.

가능한 한 문제를 격리하여 솔루션 검색을 좁히는 데 도움이 됩니다. 예를 들어 DAST가 특정 페이지를 스캔하지 않는 경우를 생각해봅니다. DAST는 어디서 페이지를 찾았어야 합니까? 거기에 도달하기 위해 어떤 경로를 취했습니까? DAST가 선택했어야 하지만 선택하지 않은 참조 페이지의 요소가 있었습니까?

### 그 결과가 사용자가 달성할 수 있습니까? {#is-the-outcome-achievable-by-a-human}

사용자가 애플리케이션을 수동으로 탐색할 수 없으면 DAST는 애플리케이션을 스캔할 수 없습니다.

예상되는 결과를 알고 있으면 컴퓨터의 브라우저를 사용하여 수동으로 복제해봅니다. 예를 들어:

- 새로운 시크릿/프라이빗 브라우저 창을 엽니다.
- 개발자 도구를 엽니다. 콘솔에서 오류 메시지를 주시합니다.
  - Chrome에서: `View -> Developer -> Developer Tools`.
  - Firefox에서: `Tools -> Browser Tools -> Web Developer Tools`.
- 인증하는 경우:
  - `DAST_AUTH_URL`로 이동합니다.
  - `DAST_AUTH_USERNAME_FIELD`에 `DAST_AUTH_USERNAME`을 입력합니다.
  - `DAST_AUTH_PASSWORD_FIELD`에 `DAST_AUTH_PASSWORD`을 입력합니다.
  - `DAST_AUTH_SUBMIT_FIELD`을 선택합니다.
- 링크를 선택하고 양식을 작성합니다. 올바르게 스캔되지 않는 페이지로 이동합니다.
- 애플리케이션의 동작을 관찰합니다. 자동화된 스캐너에 문제를 일으킬 수 있는 것이 있는지 확인합니다.

### DAST가 작동하지 않을 이유가 있습니까? {#any-reason-why-dast-would-not-work}

다음과 같은 경우에 DAST는 올바르게 스캔할 수 없습니다:

- CAPTCHA가 있습니다. 스캔되는 애플리케이션의 테스트 환경에서 이들을 비활성화합니다.
- 대상 애플리케이션에 액세스할 수 없습니다. 러너가 DAST 구성에 사용되는 URL을 사용하여 애플리케이션에 액세스할 수 있는지 확인합니다.

### 애플리케이션은 어떻게 작동합니까? {#how-does-your-application-work}

애플리케이션이 어떻게 작동하는지 이해하는 것은 DAST 스캔이 작동하지 않는 이유를 파악하는 데 필수적입니다. 예를 들어 다음 상황에서는 추가 구성 설정이 필요할 수 있습니다.

- 요소를 숨기는 팝업 대화 상자가 있습니까?
- 로드된 페이지가 일정 시간 후에 급격히 변경됩니까?
- 애플리케이션이 로드하기에 특히 느리거나 빠릅니까?
- 대상 애플리케이션이 로드 중에 끊겨 있습니까?
- 애플리케이션이 클라이언트의 위치에 따라 다르게 작동합니까?
- 애플리케이션이 단일 페이지 애플리케이션입니까?
- 애플리케이션이 HTML 양식을 제출합니까, 아니면 JavaScript 및 AJAX를 사용합니까?
- 애플리케이션이 웹소켓을 사용합니까?
- 애플리케이션이 특정 웹 프레임워크를 사용합니까?
- 버튼을 선택하면 양식 제출을 계속하기 전에 JavaScript를 실행합니까? 빠릅니까, 느립니까?
- DAST가 요소 또는 페이지가 준비되기 전에 요소를 선택하거나 검색할 수 있습니까?

### DAST는 무엇을 수행합니까? {#what-is-dast-doing}

{{< history >}}

- 간단한 로그가 GitLab [18.3](https://gitlab.com/gitlab-org/gitlab/-/issues/553625)에서 도입되었습니다.

{{< /history >}}

작업 콘솔(CI/CD 작업 로그)은 DAST가 수행하는 작업의 간단한 요약을 제공합니다. 더 자세한 진단 정보를 얻으려면 로그 파일을 구성하여 세분화된 출력을 생성할 수 있습니다.

다음의 로깅 옵션을 사용할 수 있습니다:

- [진단 로그](#diagnostic-logs)는 분석기가 수행하는 작업을 이해하는 데 유용합니다.
- [Chromium DevTools 로깅](#chromium-devtools-logging)은 DAST와 Chromium 간의 통신을 검사하는 데 유용합니다.
- [Chromium 로그](#chromium-logs)는 Chromium이 예기치 않게 충돌할 때 오류를 로깅하는 데 유용합니다.

## 진단 로그 {#diagnostic-logs}

분석기 로그 파일을 사용하여 스캔 문제를 진단합니다. 분석기의 다른 부분을 다른 수준에서 로깅할 수 있습니다.

### 로그 메시지 형식 {#log-message-format}

로그 메시지의 형식은 `[time] [log level] [log module] [message] [additional properties]`입니다.

예를 들어 다음 로그 항목의 수준은 `INFO`이고, `CRAWL` 로그 모듈의 일부이며, 메시지는 `Crawled path`이고, 추가 속성은 `nav_id` 및 `path`입니다.

```plaintext
2021-04-21T00:34:04.000 INF CRAWL Crawled path nav_id=0cc7fd path="LoadURL [https://my.site.com:8090]"
```

### 로그 대상 {#log-destination}

로그는 로그 파일 로 전송됩니다. 환경 변수 `DAST_LOG_FILE_CONFIG`을 사용하여 각 대상이 수락할 다른 로그를 구성할 수 있습니다. 예를 들어:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_BROWSER_SCAN: "true"
    DAST_LOG_FILE_CONFIG: "loglevel:debug,cache:warn"           # file log defaults to DEBUG level, logs CACHE module at WARN
```

기본적으로 파일 로그는 `gl-dast-scan.log`이라는 작업 아티팩트입니다. [이 경로를 구성](configuration/variables.md)하려면 `DAST_LOG_FILE_PATH` CI/CD 변수를 수정합니다.

### 로그 수준 {#log-levels}

구성할 수 있는 로그 수준은 다음과 같습니다:

| 로그 모듈              | 구성 요소 개요                                                       | 추가                             |
|-------------------------|--------------------------------------------------------------------------|----------------------------------|
| `TRACE`                 | 기능의 특정하고 종종 잡음이 많은 내부 작동에 사용됩니다.              |                                  |
| `DEBUG`                 | 기능의 내부 작동을 설명합니다. 진단 목적으로 사용됩니다. |                                  |
| `INFO`                  | 스캔의 높은 수준의 흐름과 결과를 설명합니다.               | 지정되지 않은 경우 기본 수준. |
| `WARN`                  | DAST가 복구하고 스캔을 계속하는 오류 상황을 설명합니다. |                                  |
| `FATAL`/`ERROR`/`PANIC` | 종료 전의 복구 불가능한 오류를 설명합니다.                            |                                  |

### 로그 모듈 {#log-modules}

`LOGLEVEL`은 로그 대상의 기본 로그 수준을 구성합니다. 다음 모듈이 구성되면 DAST는 기본 로그 수준보다 해당 모듈의 로그 수준을 우선적으로 사용합니다.

로깅을 위해 구성할 수 있는 모듈은 다음과 같습니다:

| 로그 모듈 | 구성 요소 개요                                                                                |
|------------|---------------------------------------------------------------------------------------------------|
| `ACTIV`    | 활성 공격에 사용됩니다.                                                                          |
| `AUTH`     | 인증된 스캔을 생성하는 데 사용됩니다.                                                          |
| `BPOOL`    | 크롤링을 위해 임대되는 브라우저 집합입니다.                                             |
| `BROWS`    | 브라우저의 상태 또는 페이지를 쿼리하는 데 사용됩니다.                                               |
| `CACHE`    | 캐시된 HTTP 리소스의 캐시 적중 및 누락 보고에 사용됩니다.                               |
| `CHROM`    | Chrome DevTools 메시지를 로깅하는 데 사용됩니다.                                                             |
| `CONFG`    | 분석기 구성을 로깅하는 데 사용됩니다.                                                           |
| `CONTA`    | DevTools 메시지에서 HTTP 요청 및 응답의 일부를 수집하는 컨테이너에 사용됩니다. |
| `CRAWL`    | 핵심 크롤러 알고리즘에 사용됩니다.                                                              |
| `CRWLG`    | 크롤 그래프 생성기에 사용됩니다.                                                               |
| `DATAB`    | 내부 데이터베이스에 데이터를 유지하는 데 사용됩니다.                                                |
| `LEASE`    | 브라우저를 생성하여 브라우저 풀에 추가하는 데 사용됩니다.                                          |
| `MAIN`     | 크롤러의 주요 이벤트 루프의 흐름에 사용됩니다.                                          |
| `NAVDB`    | 탐색 항목을 저장하는 지속성 메커니즘에 사용됩니다.                                      |
| `REGEX`    | 정규식을 실행할 때 성능 통계를 기록하는 데 사용됩니다.                       |
| `REPT`     | 보고서를 생성하는 데 사용됩니다.                                                                      |
| `STAT`     | 스캔을 실행하는 동안 일반 통계에 사용됩니다.                                               |
| `VLDFN`    | 취약성 정의를 로드하고 구문 분석하는 데 사용됩니다.                                           |
| `WEBGW`    | 활성 검사를 실행할 때 대상 애플리케이션으로 전송된 메시지를 로깅하는 데 사용됩니다.                   |
| `SCOPE`    | [범위 관리](configuration/customize_settings.md#managing-scope)와 관련된 메시지를 로깅하는 데 사용됩니다. |

### SECURE_LOG_LEVEL {#secure_log_level}

{{< history >}}

- GitLab 17.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/524632)되었습니다.

{{< /history >}}

`DAST_LOG_FILE_CONFIG`로 로그 모듈을 구성하는 더 간단한 대안으로서 `SECURE_LOG_LEVEL`를 설정할 수 있습니다:

- [지원되는 로그 수준](#log-levels) 중 하나입니다. 이렇게 하면 지정된 수준이 모든 모듈의 로그 파일의 기본 로그 수준이 됩니다.
- [인증 보고서](configuration/authentication.md#configure-the-authentication-report)를 활성화하려면 `debug` 또는 `trace`입니다.
- [DevTools 로깅](#chromium-devtools-logging)을 활성화하려면 `trace`

예를 들어:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    SECURE_LOG_LEVEL: "trace"
    # is equivalent to:
    # DAST_LOG_FILE_CONFIG: "loglevel:trace"
    # DAST_LOG_DEVTOOLS_CONFIG: "Default:messageAndBody,truncate:2000"
    # DAST_AUTH_REPORT: "true"
```

`DAST_LOG_FILE_CONFIG`, `DAST_LOG_DEVTOOLS_CONFIG`, `DAST_AUTH_REPORT`의 설정은 `SECURE_LOG_LEVEL`의 설정을 재정의합니다.

### 예제 - 크롤링된 경로 로깅 {#example---log-crawled-paths}

로그 파일 모듈 `CRAWL`을 `DEBUG`로 설정하여 스캔의 크롤 단계에서 발견된 탐색 경로를 로그 파일에 로깅합니다. 이것은 DAST가 대상 애플리케이션을 올바르게 크롤링하고 있는지 이해하는 데 유용합니다.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "crawl:debug"
```

예를 들어 다음 출력은 `https://example.com`의 페이지 크롤 중에 발견된 4개의 앵커 링크를 보여줍니다.

```plaintext
2022-11-17T11:18:05.578 DBG CRAWL executing step nav_id=6ec647d8255c729160dd31cb124e6f89 path="LoadURL [https://example.com]" step=1
...
2022-11-17T11:18:11.900 DBG CRAWL found new navigations browser_id=2243909820020928961 nav_count=4 nav_id=6ec647d8255c729160dd31cb124e6f89 of=1 step=1
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page1.html]" nav=bd458cc1fc2d7c6fb984464b6d968866 parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page2.html]" nav=6dcb25f9f9ece3ee0071ac2e3166d8e6 parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page3.html]" nav=89efbb0c6154d6c6d85a63b61a7cdc6f parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page4.html]" nav=f29b4f4e0bdee70f5255de7fc080f04d parent_nav=6ec647d8255c729160dd31cb124e6f89
```

## Chromium DevTools 로깅 {#chromium-devtools-logging}

> [!warning]
> DevTools 메시지 로깅은 보안 위험입니다. 출력에는 사용자 이름, 암호, 인증 토큰과 같은 비밀이 포함됩니다. 출력이 GitLab 서버에 업로드되며 작업 로그에 표시될 수 있습니다.

DAST 브라우저 기반 스캐너는 [Chrome DevTools 프로토콜](https://chromedevtools.github.io/devtools-protocol/)을 사용하여 Chromium 브라우저를 제어합니다. DevTools 메시지 로깅은 브라우저가 수행하는 작업에 투명성을 제공합니다. 예를 들어 버튼을 선택하지 않으면 DevTools 메시지는 원인이 브라우저 콘솔 로그의 CORS 오류임을 표시할 수 있습니다. DevTools 메시지를 포함하는 로그가 크기가 매우 클 수 있습니다. 이러한 이유로 단기 작업에서만 활성화해야 합니다.

모든 DevTools 메시지를 로깅하려면 `CHROM` 로그 모듈을 `trace`로 변환하고 로깅 수준을 구성합니다. 다음은 DevTools 로그의 예입니다:

```plaintext
2022-12-05T06:27:24.280 TRC CHROM event received    {"method":"Fetch.requestPaused","params":{"requestId":"interception-job-3.0","request":{"url":"http://auth-auto:8090/font-awesome.min.css","method":"GET","headers":{"Accept":"text/css,*/*;q=0.1","Referer":"http://auth-auto:8090/login.html","User-Agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/105.0.5195.102 Safari/537.36"},"initialPriority":"VeryHigh","referrerPolicy":"strict-origin-when-cross-origin"},"frameId":"A706468B01C2FFAA2EB6ED365FF95889","resourceType":"Stylesheet","networkId":"39.3"}} method=Fetch.requestPaused
2022-12-05T06:27:24.280 TRC CHROM request sent      {"id":47,"method":"Fetch.continueRequest","params":{"requestId":"interception-job-3.0","headers":[{"name":"Accept","value":"text/css,*/*;q=0.1"},{"name":"Referer","value":"http://auth-auto:8090/login.html"},{"name":"User-Agent","value":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/105.0.5195.102 Safari/537.36"}]}} id=47 method=Fetch.continueRequest
2022-12-05T06:27:24.281 TRC CHROM response received {"id":47,"result":{}} id=47 method=Fetch.continueRequest
```

### DevTools 로그 수준 사용자 지정 {#customizing-devtools-log-levels}

Chrome DevTools 요청, 응답 및 이벤트는 도메인별로 네임스페이스화됩니다. DAST는 각 도메인과 메시지가 있는 각 도메인이 다른 로깅 구성을 가질 수 있도록 합니다. 환경 변수 `DAST_LOG_DEVTOOLS_CONFIG`은 세미콜론으로 구분된 로깅 구성 목록을 받습니다. 로깅 구성은 구조 `[domain/message]:[what-to-log][,truncate:[max-message-size]]`을 사용하여 선언됩니다.

- `domain/message`은 로깅되는 항목을 참조합니다.
  - `Default`은 모든 도메인 및 메시지를 나타내는 값으로 사용할 수 있습니다.
  - 도메인일 수 있습니다. 예: `Browser`, `CSS`, `Page`, `Network`.
  - 메시지가 있는 도메인일 수 있습니다. 예: `Network.responseReceived`.
  - 여러 구성이 적용되면 가장 구체적인 구성이 사용됩니다.
- `what-to-log`은 로깅할 항목과 여부를 참조합니다.
  - `message`은 메시지가 수신되었으며 메시지 콘텐츠를 로깅하지 않음을 로깅합니다.
  - `messageAndBody`은 메시지 콘텐츠와 함께 메시지를 로깅합니다. `truncate`와 함께 사용하는 것이 좋습니다.
  - `suppress`은 메시지를 로깅하지 않습니다. 잡음이 많은 도메인 및 메시지를 무음 처리하는 데 사용됩니다.
- `truncate`은 인쇄된 메시지의 크기를 제한하는 선택적 구성입니다.

### 예제 - 모든 DevTools 메시지 로깅 {#example---log-all-devtools-messages}

시작할 위치를 확실하지 않을 때 모든 것을 로깅하는 데 사용됩니다.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "chrom:trace"
    DAST_LOG_DEVTOOLS_CONFIG: "Default:messageAndBody,truncate:2000"
```

### 예제 - HTTP 메시지 로깅 {#example---log-http-messages}

리소스가 올바르게 로드되지 않을 때 유용합니다. HTTP 메시지 이벤트가 로깅되고, 요청을 계속하거나 실패할 결정도 마찬가지입니다. 브라우저 콘솔의 모든 오류도 로깅됩니다.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "chrom:trace"
    DAST_LOG_DEVTOOLS_CONFIG: "Default:suppress;Fetch:messageAndBody,truncate:2000;Network:messageAndBody,truncate:2000;Log:messageAndBody,truncate:2000;Console:messageAndBody,truncate:2000"
```

### 작업 콘솔 출력 재정의 {#override-the-job-console-output}

기본적으로 작업 콘솔은 DAST 활동의 간단한 요약을 표시합니다. 전체 진단 로그를 작업 콘솔에 출력하려면 `DAST_FF_DIAGNOSTIC_JOB_OUTPUT` 및 `DAST_LOG_CONFIG` 변수를 모두 설정합니다:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_FF_DIAGNOSTIC_JOB_OUTPUT: "true"
    DAST_LOG_CONFIG: "crawl:debug"                               # console log defaults to INFO level, logs AUTH module at DEBUG
```

[이슈 552171](https://gitlab.com/gitlab-org/gitlab/-/issues/552171)은 GitLab 19.0에서 이 옵션을 제거할 것을 제안합니다.

## Chromium 로그 {#chromium-logs}

Chromium이 충돌하는 드문 경우 Chromium 프로세스 `STDOUT` 및 `STDERR`를 로그에 작성하는 것이 도움이 될 수 있습니다. 환경 변수 `DAST_LOG_BROWSER_OUTPUT`를 `true`로 설정하면 이 목적을 달성합니다.

DAST는 많은 Chromium 프로세스를 시작하고 중지합니다. DAST는 각 프로세스 출력을 로그 모듈 `LEASE` 및 로그 수준 `INFO`이 있는 모든 로그 대상에 전송합니다.

예를 들어:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_BROWSER_OUTPUT: "true"
```

## 알려진 문제 {#known-problems}

### 로그에 `response body exceeds allowed size` 포함 {#logs-contain-response-body-exceeds-allowed-size}

기본적으로 DAST는 HTTP 응답 본문이 10 MB 이하인 HTTP 요청을 처리합니다. 그렇지 않으면 DAST는 응답을 차단하여 스캔이 실패할 수 있습니다. 이 제약은 스캔 중에 메모리 소비를 줄이기 위한 것입니다.

다음은 DAST가 `https://example.com/large.js`에서 발견된 JavaScript 파일을 차단한 예 로그입니다. 그 크기가 제한보다 큽니다:

```plaintext
2022-12-05T06:28:43.093 WRN BROWS response body exceeds allowed size allowed_size_bytes=1000000 browser_id=752944257619431212 nav_id=ae23afe2acbce2c537657a9112926f1a of=1 request_id=interception-job-2.0 response_size_bytes=9333408 step=1 url=https://example.com/large.js
2022-12-05T06:28:58.104 WRN CONTA request failed, attempting to continue scan error=net::ERR_BLOCKED_BY_RESPONSE index=0 requestID=38.2 url=https://example.com/large.js
```

이를 구성 `DAST_PAGE_MAX_RESPONSE_SIZE_MB`을 사용하여 변경할 수 있습니다. 예를 들어,

```yaml
dast:
  variables:
    DAST_PAGE_MAX_RESPONSE_SIZE_MB: "25"
```

### 크롤러가 예상 페이지에 도달하지 못함 {#crawler-doesnt-reach-expected-pages}

#### 캐시 비활성화 시도 {#try-disabling-the-cache}

DAST가 애플리케이션 페이지를 잘못 캐시하면 DAST가 애플리케이션을 제대로 크롤링하지 못할 수 있습니다. 크롤러에서 일부 페이지를 찾지 못한 경우 `DAST_USE_CACHE: "false"` 변수를 설정하여 도움이 되는지 확인해봅니다. 이것은 스캔의 성능을 크게 감소시킬 수 있습니다. 절대적으로 필요한 경우에만 캐시를 비활성화합니다. 구독이 있는 경우 [지원 티켓을 생성](https://support.gitlab.com/)하여 캐시가 웹 사이트 크롤링을 방지하는 이유를 조사합니다.

#### 직접 대상 경로 지정 {#specifying-target-paths-directly}

크롤러는 일반적으로 정의된 대상 URL에서 시작하여 사이트와 상호 작용하여 추가 페이지를 찾으려고 시도합니다. 하지만 크롤러가 시작할 경로를 직접 지정하는 두 가지 방법이 있습니다:

- sitemap.xml 사용: [사이트맵](https://www.sitemaps.org/protocol.html)은 웹 사이트의 페이지를 지정하는 잘 정의된 프로토콜입니다. DAST의 크롤러는 `<target URL>/sitemap.xml`에서 sitemap.xml 파일을 찾고 지정된 모든 URL을 크롤러의 시작점으로 사용합니다. [사이트맵 인덱스](https://www.sitemaps.org/protocol.html#index) 파일은 지원되지 않습니다.
- `DAST_TARGET_PATHS` 사용: 이 구성 변수를 사용하면 크롤러의 입력 경로를 지정할 수 있습니다. 예: `DAST_TARGET_PATHS: /,/page/1.html,/page/2.html`.

#### 요청이 차단되지 않는지 확인 {#make-sure-requests-are-not-getting-blocked}

기본적으로 DAST는 대상 URL 도메인으로의 요청만 허용합니다. 웹 사이트가 대상이 아닌 다른 도메인으로 요청을 하는 경우 `DAST_SCOPE_ALLOW_HOSTS`을 사용하여 이러한 호스트를 지정합니다. 예: "example.com"은 인증 토큰을 갱신하기 위해 "auth.example.com"에 인증 요청을 합니다. 도메인이 허용되지 않으므로 요청이 차단되고 크롤러가 새 페이지를 찾지 못합니다.

#### 최대 작업 및 크롤러 타임아웃 {#maximum-actions-and-crawler-timeout}

크롤러는 활동 및 대상 사이트에서 보낸 시간에 기본 제한이 있습니다:

1. 기본적으로 크롤러는 10,000개의 작업을 처리합니다. 작업은 링크를 선택하거나 양식을 작성할 수 있습니다. 크롤러가 이 제한을 위반하면 디버그 수준 로그 `not adding navigation as it exceeds max actions`이 표시됩니다.
1. 기본적으로 크롤러는 최대 24시간 동안 실행됩니다. 이 시간 제한을 초과하면 추적 수준 로그 `crawl complete, timed out`이 표시됩니다.

크롤러가 이 제한 중 하나에 도달하면 스캐너가 중지되고 대상 웹 사이트를 완전히 포함할 수 없습니다. 따라서 이러한 제한 위반은 스캔 중의 문제 및 최적화의 잠재적 기회를 나타낼 수 있습니다.

애플리케이션이 페이지 전체에서 유사한 구조이지만 다른 데이터를 가진 템플릿 기반 페이지가 있거나 URL 패턴(예: `/products/item-123`, `/products/item-456`, `/products/item-789`)을 발견한 경우 [그룹화된 URL](configuration/customize_settings.md#grouped-urls)을 구성하여 스캔 시간을 줄이면서 보안 범위를 유지합니다.

그룹화된 URL은 많은 제품 페이지가 있는 전자 상거래 사이트, 콘텐츠 기반 사이트 또는 검색 인터페이스(예: `/search?q=term&page=1`, `/search?q=term&page=2`)에 잘 작동합니다.

스캔 시간 관리에 대한 자세한 내용은 [스캔 시간 관리](configuration/customize_settings.md#managing-scan-time)를 참조합니다. 다른 전략이 적절하지 않고 대상 사이트가 광범위한 경우 크롤러 타임아웃(`DAST_CRAWL_TIMEOUT`) 또는 최대 작업(`DAST_CRAWL_MAX_ACTIONS`)을 증가시킵니다.
