---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 취약성 심각도 수준
description: "분류, 영향, 우선순위 지정 및 위험 평가입니다."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 취약성 분석기는 가능한 한 취약성 심각도 수준 값을 반환하려고 시도합니다. 다음은 가장 심각한 것부터 가장 덜 심각한 것까지 순위가 지정된 사용 가능한 GitLab 취약성 심각도 수준의 목록입니다:

- 긴급
- 높음
- 중간
- 낮음
- 정보
- 알 수 없음

GitLab 분석기는 아래 심각도 설명에 맞추려고 노력하지만 항상 정확한 것은 아닙니다. 타사 공급업체가 제공하는 분석기 및 스캐너는 동일한 분류를 따르지 않을 수 있습니다.

## 긴급 심각도 {#critical-severity}

긴급 심각도 수준에서 식별된 취약성은 즉시 조사해야 합니다. 이 수준의 취약성은 결함 악용으로 인해 전체 시스템 또는 데이터 침해가 발생할 수 있다고 가정합니다. 긴급 심각도 결함의 예는 명령/코드 주입 및 SQL 주입입니다. 일반적으로 이러한 결함은 CVSS 4.0 점수 9.0~10.0 사이로 평가됩니다.

## 높음 심각도 {#high-severity}

높음 심각도 취약성은 공격자가 애플리케이션 리소스에 액세스하거나 데이터가 의도하지 않게 노출될 수 있는 결함으로 특징지어집니다. 높음 심각도 결함의 예는 외부 XML 엔터티 주입(XXE), 서버 측 요청 위조(SSRF), 로컬 파일 포함, 경로 순회 및 특정 형태의 크로스 사이트 스크립팅(XSS)입니다. 일반적으로 이러한 결함은 CVSS 4.0 점수 7.0~8.9 사이로 평가됩니다.

## 중간 심각도 {#medium-severity}

중간 심각도 취약성은 일반적으로 시스템 구성 오류 또는 보안 제어 부족으로 인해 발생합니다. 이러한 취약성의 악용으로 인해 제한된 양의 데이터에 액세스할 수 있거나 다른 결함과 함께 사용하여 시스템 또는 리소스에 대한 의도하지 않은 액세스를 얻을 수 있습니다. 중간 심각도 결함의 예는 반영된 XSS, 잘못된 HTTP 세션 처리 및 누락된 보안 제어입니다. 일반적으로 이러한 결함은 CVSS 4.0 점수 4.0~6.9 사이로 평가됩니다.

## 낮음 심각도 {#low-severity}

낮음 심각도 취약성에는 직접 악용되지는 않지만 애플리케이션 또는 시스템에 불필요한 약점을 야기하는 결함이 포함됩니다. 이러한 결함은 일반적으로 누락된 보안 제어 또는 애플리케이션 환경에 대한 불필요한 정보 공개로 인해 발생합니다. 낮음 심각도 취약성의 예는 누락된 쿠키 보안 지시문 및 자세한 오류 또는 예외 메시지입니다. 일반적으로 이러한 결함은 CVSS 4.0 점수 0.1~3.9 사이로 평가됩니다.

## 정보 심각도 {#info-severity}

정보 수준 심각도 취약성에는 가치가 있을 수 있는 정보가 포함되지만 특정 결함 또는 약점과 반드시 연관되어 있지는 않습니다. 일반적으로 이러한 문제는 CVSS 등급이 없습니다.

## 알 수 없음 심각도 {#unknown-severity}

이 수준에서 식별된 문제는 심각도를 명확하게 보여주기에 충분한 컨텍스트가 없습니다.

GitLab 취약성 분석기에는 인기 있는 오픈 소스 스캔 도구가 포함됩니다. 각 오픈 소스 스캔 도구는 자체 기본 취약성 심각도 수준 값을 제공합니다. 이러한 값은 다음 중 하나일 수 있습니다:

| 기본 취약성 심각도 수준 유형                                                                                          | 예                                       |
|-----------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|
| 문자열                                                                                                                            | `WARNING`, `ERROR`, `Critical`, `Negligible`   |
| 정수                                                                                                                           | `1`, `2`, `5`                                  |
| [CVSS v2.0 등급](https://nvd.nist.gov/vuln-metrics/cvss)                                                                        | `(AV:N/AC:L/Au:S/C:P/I:P/A:N)`                 |
| [CVSS v3.1 정성적 심각도 등급](https://www.first.org/cvss/v3.1/specification-document#Qualitative-Severity-Rating-Scale) | `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` |
| [CVSS v4.0 정성적 심각도 등급](https://www.first.org/cvss/v4.0/specification-document#Qualitative-Severity-Rating-Scale) | `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N` |

일관된 취약성 심각도 수준 값을 제공하기 위해 GitLab 취약성 분석기는 이전 값에서 표준화된 GitLab 취약성 심각도 수준으로 변환하며, 다음 표에 설명되어 있습니다:

## 컨테이너 스캔 {#container-scanning}

| GitLab 분석기                                                        | 심각도 수준을 출력합니까? | 기본 심각도 수준 유형 | 기본 심각도 수준 예                                |
|------------------------------------------------------------------------|--------------------------|----------------------------|--------------------------------------------------------------|
| [`container-scanning`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)| {{< yes >}} | 문자열 | `Unknown`, `Low`, `Medium`, `High`, `Critical` |

사용 가능한 경우 공급업체 심각도 수준이 우선 적용되며 분석기에서 사용됩니다. 사용할 수 없는 경우 CVSS v4.0 등급으로 돌아갑니다. 그것도 사용할 수 없는 경우 CVSS v3.1 등급이 사용됩니다. 그것도 사용할 수 없는 경우 CVSS v2.0 등급이 대신 사용됩니다.

## 동적 애플리케이션 보안 테스팅(DAST) {#dynamic-application-security-testing-dast}

| GitLab 분석기                                                                          | 심각도 수준을 출력합니까?     | 기본 심각도 수준 유형 | 기본 심각도 수준 예       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`Browser-based DAST`](../dast/browser/_index.md)         | {{< yes >}}       | 문자열 | `HIGH`, `MEDIUM`, `LOW`, `INFO` |

## API 보안 테스팅 {#api-security-testing}

| GitLab 분석기                                                                          | 심각도 수준을 출력합니까?     | 기본 심각도 수준 유형 | 기본 심각도 수준 예       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`API security testing`](../api_security_testing/_index.md)         | {{< yes >}}       | 문자열 | `HIGH`, `MEDIUM`, `LOW` |

## 종속성 검사 {#dependency-scanning}

| GitLab 분석기                                                                          | 심각도 수준을 출력합니까?     | 기본 심각도 수준 유형 | 기본 심각도 수준 예       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`gemnasium`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)         | {{< yes >}}       | CVSS v2.0 등급, CVSS v3.1 정성적 심각도 등급 <sup>1</sup> 및 CVSS v4.0 정성적 심각도 등급 <sup>1</sup> | `(AV:N/AC:L/Au:S/C:P/I:P/A:N)`, `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H`, `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N` |

CVSS v4.0 등급은 심각도 수준을 계산하는 데 사용됩니다. 사용할 수 없는 경우 CVSS v3.1 등급이 사용됩니다. 그것도 사용할 수 없는 경우 CVSS v2.0 등급이 대신 사용됩니다.

## 퍼즈 테스팅 {#fuzz-testing}

모든 퍼즈 테스팅 결과는 알 수 없음 심각도로 보고됩니다. 이들은 악용 가능한 결함을 찾기 위해 수동으로 검토 및 분류해야 수정 우선순위를 정할 수 있습니다.

## 정적 애플리케이션 보안 테스팅(SAST) {#static-application-security-testing-sast}

|  GitLab 분석기                                                                 | 심각도 수준을 출력합니까? | 기본 심각도 수준 유형 | 기본 심각도 수준 예 |
|----------------------------------------------------------------------------------|--------------------------|----------------------------|-------------------------|
| [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec)   | {{< yes >}}   | 문자열                     | `CriticalSeverity`, `InfoSeverity` |
| [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex) | {{< yes >}}   | 정수                    | `1`, `2`, `3`, `4`, `5`            |
| [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)   | {{< yes >}}   | 문자열                     | `error`, `warning`, `note`, `none` |
| [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)   | {{< yes >}}   | 해당 없음             | 모든 심각도 수준을 `Unknown`로 하드코딩 |
| [`SpotBugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) | {{< yes >}}   | 정수                    | `1`, `2`, `3`, `11`, `12`, `18`    |

## 코드 기반 인프라(IaC) 스캔 {#infrastructure-as-code-iac-scanning}

|  GitLab 분석기                                                                                         | 심각도 수준을 출력합니까? | 기본 심각도 수준 유형 | 기본 심각도 수준 예      |
|----------------------------------------------------------------------------------------------------------|--------------------------|----------------------------|------------------------------------|
| [`kics`](https://gitlab.com/gitlab-org/security-products/analyzers/kics)                                 | {{< yes >}}   | 문자열                     | `error`, `warning`, `note`, `none` (`info`로 매핑됨 [분석기 버전 3.7.0 이상](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/releases/v3.7.0)) |

### 코드 기반 인프라 보안 유지(KICS) 심각도 매핑 {#keeping-infrastructure-as-code-secure-kics-severity-mapping}

KICS 분석기는 출력을 정적 분석 결과 교환 형식(SARIF) 심각도로 매핑하며, 이는 GitLab 심각도로 매핑됩니다. 아래 표를 사용하여 GitLab 취약성 보고서에서 해당 심각도를 확인하세요.

| KICS 심각도 | KICS SARIF 심각도 | GitLab 심각도 |
|---------------|---------------------|-----------------|
| 긴급      | 오류               | 긴급        |
| 높음          | 오류               | 긴급        |
| 중간        | 경고             | 중간          |
| 낮음           | 참고                | 정보            |
| 정보          | 없음                | 정보            |
| 무효       | 없음                | 정보            |

KICS와 GitLab 모두 높은 심각도를 정의하지만 SARIF는 정의하지 않으므로, KICS의 높은 심각도 취약성은 GitLab의 긴급 심각도로 매핑됩니다.

[GitLab 매핑용 소스 코드](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/902c7dcb5f3a0e551223167931ebf39588a0193a/sarif/sarif.go#L279-315).

## 시크릿 검색 {#secret-detection}

GitLab [`secrets`](https://gitlab.com/gitlab-org/security-products/analyzers/secrets) 분석기는 모든 심각도 수준을 긴급으로 하드코딩합니다. [에픽 10320](https://gitlab.com/groups/gitlab-org/-/epics/10320)에서 더 세분화된 심각도 등급을 제안합니다.
