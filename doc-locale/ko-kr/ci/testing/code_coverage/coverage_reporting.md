---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "머지 리퀘스트, 분석, 배지에 테스트 커버리지 백분율을 표시합니다."
title: 커버리지 보고
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[`coverage`](../../yaml/_index.md#coverage) 키워드를 사용하여 테스트 작업의 로그 출력에서 커버리지 백분율을 추출하고 머지 리퀘스트 및 분석에 표시합니다.

이 키워드는 커버리지 백분율만 표시합니다. 머지 리퀘스트 diff에서 줄별 주석을 생성하지 않습니다. 줄별 주석을 표시하려면 [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)을(를) 별도로 구성합니다.

## 커버리지 보고 구성 {#configure-coverage-reporting}

커버리지 보고를 구성하려면:

1. 테스트 도구의 출력과 일치하는 정규 표현식과 함께 `coverage` 키워드를 작업에 추가합니다:

   ```yaml
   test:
     script:
       - pytest --cov
     coverage: '/TOTAL.*? (100(?:\.0+)?\%|[1-9]?\d(?:\.\d+)?\%)$/'
   ```

1. 여러 작업에서 커버리지를 집계하려면 각 작업에 `coverage` 키워드를 추가합니다.

### 커버리지 정규 표현식 패턴 {#coverage-regex-patterns}

다음 정규 표현식 패턴은 일반적인 테스트 커버리지 도구의 출력과 일치합니다. 도구 출력 형식이 시간에 따라 변할 수 있으므로 신중하게 테스트합니다.

{{< tabs >}}

{{< tab title="Python 및 Ruby" >}}

| 도구           | 언어 | 명령        | 정규 표현식 패턴 |
| -------------- | -------- | -------------- | ------------- |
| pytest-cov     | Python   | `pytest --cov` | `/TOTAL.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |
| Simplecov-html | Ruby     | `rspec spec`   | `/Line\sCoverage:\s\d+\.\d+%/` |

{{< /tab >}}

{{< tab title="C/C++ 및 Rust" >}}

| 도구      | 언어 | 명령           | 정규 표현식 패턴 |
| --------- | -------- | ----------------- | ------------- |
| gcovr     | C/C++    | `gcovr`           | `/^TOTAL.*\s+(\d+\%)$/` |
| tarpaulin | Rust     | `cargo tarpaulin` | `/^\d+.\d+% coverage/` |

{{< /tab >}}

{{< tab title="Java 및 JVM" >}}

| 도구      | 언어    | 명령                            | 정규 표현식 패턴 |
| --------- | ----------- | ---------------------------------- | ------------- |
| JaCoCo    | Java/Kotlin | `./gradlew test jacocoTestReport`  | `/Total.*?([0-9]{1,3})%/` |
| Scoverage | Scala       | `sbt coverage test coverageReport` | `/(?i)total.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |

{{< /tab >}}

{{< tab title="Node.js" >}}

| 도구      | 명령                                    | 정규 표현식 패턴 |
| --------- | ------------------------------------------ | ------------- |
| tap       | `tap --coverage-report=text-summary`       | `/^Statements\s*:\s*([^%]+)/` |
| nyc       | `nyc npm test`                             | `/All files[^\|]*\|[^\|]*\s+([\d\.]+)/` |
| jest      | `jest --ci --coverage`                     | `/All files[^\|]*\|[^\|]*\s+([\d\.]+)/` |
| node:test | `node --experimental-test-coverage --test` | `/all files[^\|]*\|[^\|]*\s+([\d\.]+)/` |

{{< /tab >}}

{{< tab title="PHP" >}}

| 도구    | 명령                                  | 정규 표현식 패턴 |
| ------- | ---------------------------------------- | ------------- |
| pest    | `pest --coverage --colors=never`         | `/Statement coverage[A-Za-z\.*]\s*:\s*([^%]+)/` |
| phpunit | `phpunit --coverage-text --colors=never` | `/^\s*Lines:\s*\d+.\d+\%/` |

{{< /tab >}}

{{< tab title="Go" >}}

| 도구              | 명령                                                                    | 정규 표현식 패턴 |
| ----------------- | -------------------------------------------------------------------------- | ------------- |
| go test (단일)  | `go test -cover`                                                           | `/coverage: \d+.\d+% of statements/` |
| go test (프로젝트) | `go test -coverprofile=cover.profile && go tool cover -func cover.profile` | `/total:\s+\(statements\)\s+\d+.\d+%/` |

{{< /tab >}}

{{< tab title=".NET 및 PowerShell" >}}

| 도구        | 언어   | 명령       | 정규 표현식 패턴 |
| ----------- | ---------- | ------------- | ------------- |
| OpenCover   | .NET       | 없음          | `/(Visited Points).*\((.*)\)/` |
| dotnet test | .NET       | `dotnet test` | `/Total\s*\|*\s(\d+(?:\.\d+)?)/` |
| Pester      | PowerShell | 없음          | `/Covered (\d{1,3}(\.\|,)?\d{0,2}%)/` |

{{< /tab >}}

{{< tab title="Elixir" >}}

| 도구        | 명령            | 정규 표현식 패턴 |
| ----------- | ------------------ | ------------- |
| excoveralls | 없음               | `/\[TOTAL\]\s+(\d+\.\d+)%/` |
| mix         | `mix test --cover` | `/\d+.\d+\%\s+\|\s+Total/` |

{{< /tab >}}

{{< /tabs >}}

## 커버리지 확인 승인 규칙 추가 {#add-a-coverage-check-approval-rule}

{{< details >}}

- 티어: Premium, Ultimate

{{< /details >}}

프로젝트의 테스트 커버리지를 감소시키는 머지 리퀘스트를 승인하도록 특정 사용자 또는 그룹을 요구할 수 있습니다.

전제 조건:

- 커버리지 보고를 구성합니다.

`Coverage-Check` 승인 규칙을 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **머지 리퀘스트**를 선택합니다.
1. **머지 리퀘스트 승인** 아래에서 다음 중 하나를 수행합니다:
   - `Coverage-Check` 승인 규칙 옆에서 **사용**을(를) 선택합니다.
   - 수동 설정의 경우 **승인 규칙 추가**를 선택한 다음 `Coverage-Check`을(를) **규칙 이름**으로 입력합니다.
1. **대상 브랜치**를 선택합니다.
1. **필요한 승인 수**를 설정합니다.
1. **사용자** 또는 **그룹**을(를) 선택하여 승인을 제공합니다.
1. **변경사항 저장**을 선택합니다.

> [!note]
> `Coverage-Check` 승인 규칙은 병합 기본 파이프라인에 커버리지 데이터가 없을 때 승인을 요구하며, 머지 리퀘스트가 전체 커버리지를 개선하더라도 그렇습니다.

## 커버리지 이력 보기 {#view-coverage-history}

시간에 따라 프로젝트 또는 그룹의 커버리지 추세를 추적할 수 있습니다.

### 프로젝트의 경우 {#for-a-project}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **분석** > **리포지토리 분석**을(를) 선택합니다.
1. 드롭다운 목록에서 이력 데이터를 볼 작업을(를) 선택합니다.
1. 선택 사항. 데이터를 다운로드하려면 **raw 데이터 다운로드 (.csv)**를 선택합니다.

### 그룹의 경우 {#for-a-group}

{{< details >}}

- 티어: Premium, Ultimate

{{< /details >}}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **분석** > **리포지토리 분석**을(를) 선택합니다.
1. 선택 사항. 데이터를 다운로드하려면 **테스트 커버리지 이력 데이터(.csv) 다운로드**를 선택합니다.

## 커버리지 배지 표시 {#display-coverage-badges}

프로젝트에 커버리지 배지를 추가하려면 [테스트 커버리지 보고서 배지](../../../user/project/badges.md#test-coverage-report-badges)를 참조하세요.

## 문제 해결 {#troubleshooting}

커버리지 보고로 작업할 때 다음과 같은 이슈가 발생할 수 있습니다.

### 머지 리퀘스트 위젯에 커버리지 백분율이 표시되지 않음 {#coverage-percentage-does-not-appear-in-the-mr-widget}

`coverage` 키워드는 정규 표현식을 사용하여 작업의 로그 출력에서 백분율을 추출합니다. 백분율이 표시되지 않으면:

- 정규 표현식이 도구의 실제 출력과 일치하는지 확인합니다. 작업 로그에서 한 줄을 복사하여 정규 표현식으로 테스트합니다.
- 일부 도구는 정규 표현식 일치를 중단하는 ANSI 색상 코드를 출력합니다. 도구가 색상 출력 비활성화를 지원하지 않으면 구문 분석 전에 코드를 제거합니다:

  ```shell
  lein cloverage | perl -pe 's/\e\[?.*?[\@-~]//g'
  ```

- 작업이 성공적으로 완료되었는지 확인합니다. 커버리지는 성공한 작업에서만 추출됩니다.
- 자식 파이프라인의 커버리지 출력은 기록되지 않습니다. 자세한 내용은 [이슈 280818](https://gitlab.com/gitlab-org/gitlab/-/issues/280818)을(를) 참조하세요.

> [!note]
> `coverage` 키워드는 머지 리퀘스트 위젯에만 백분율을 표시합니다. diff에서 줄별 주석의 경우 [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)을(를) 별도로 구성합니다.
