---
stage: Application Security Testing
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SARIF 보고서
description: 타사 SARIF 스캐너의 결과를 GitLab 취약성 관리에 추가합니다.
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 18.11에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/452042) [플래그](../../../administration/feature_flags/_index.md) `sarif_ingestion`과 함께 도입되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 19.1에서 기본적으로 활성화됨
- GitLab 19.2에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/work_items/602748)됨 기능 플래그 `sarif_ingestion`이 제거되었습니다.

{{< /history >}}

타사 SARIF 보고서를 사용하여 모든 [SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html) 스캐너의 결과를 GitLab 취약성 관리에 추가합니다. CI/CD 작업은 SARIF를 생성하는 스캐너를 실행하고 SARIF 아티팩트를 추가합니다. GitLab은 아티팩트를 구문 분석, 검증하고 보안 결과로 추가합니다.

보고서를 추가한 후 결과는 다음 페이지에서 기본 GitLab 스캐너의 결과와 함께 표시됩니다:

- 파이프라인 **보안** 탭
- 프로젝트 취약성 보고서
- 보안 대시보드
- 머지 리퀘스트 보안 위젯
- 보안 정책

타사 SARIF 보고서는 GitLab이 제공하는 기본 제공 스캐너를 보완합니다. 이를 사용하여 GitLab이 기본적으로 제공하지 않는 타사 스캐너를 통합하거나 이미 실행 중인 도구의 결과를 통합합니다.

## SARIF 보고서 추가 {#add-sarif-reports}

GitLab에 SARIF 결과를 추가하려면:

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.
- SARIF 2.1.0 파일을 생성하는 CI/CD 작업

1. `.gitlab-ci.yml` 파일에서 스캐너를 실행하고 SARIF 출력을 `artifacts:reports:sarif` 아티팩트로 저장하는 작업을 정의합니다. 예:

   ```yaml
   sarif_scan:
     image: <scanner-image>
     script:
       - <scanner-command> --output sarif.json
     artifacts:
       reports:
         sarif: sarif.json
   ```

1. 변경 사항을 커밋하고 푸시합니다. GitLab은 작업이 완료되면 SARIF 파일을 구문 분석합니다.
1. 파이프라인 **보안** 탭에서 추가된 결과를 확인합니다.

CI/CD 아티팩트 참조는 [`artifacts:reports:sarif`](../../../ci/yaml/artifacts_reports.md#artifactsreportssarif)을 참조하세요.

## 지정된 보고서 유형 {#assigned-report-types}

GitLab은 결과의 위치 및 식별자를 기반으로 각 SARIF 결과에 대해 취약성 보고서 유형을 지정합니다. 유형은 결과가 취약성 보고서에 표시되는 위치와 보안 정책과 상호 작용하는 방식을 결정합니다.

GitLab은 다음 규칙을 순서대로 평가하고 결과와 일치하는 첫 번째 유형을 지정합니다.

| 규칙                                                                                         | 지정된 보고서 유형 |
|----------------------------------------------------------------------------------------------|----------------------|
| 식별자가 CVE입니다.                                                                     | 종속성 검사  |
| 식별자가 시크릿 검색 관련 CWE입니다. <sup>1</sup>                                         | 시크릿 검색     |
| 기본값 (규칙이 일치하지 않음)                                                          | SAST                 |

**각주:**

1. 다음 CWE는 시크릿 검색 관련입니다:

   - [CWE-798 (하드코딩된 자격 증명)](https://cwe.mitre.org/data/definitions/798.html)
   - [CWE-259 (하드코딩된 암호)](https://cwe.mitre.org/data/definitions/259.html)
   - [CWE-321 (하드코딩된 암호화 키)](https://cwe.mitre.org/data/definitions/321.html)
   - [CWE-522 (부족하게 보호된 자격 증명)](https://cwe.mitre.org/data/definitions/522.html)
   - [CWE-312 (일반 텍스트로 저장된 민감한 정보)](https://cwe.mitre.org/data/definitions/312.html)
   - [CWE-319 (일반 텍스트로 전송된 민감한 정보)](https://cwe.mitre.org/data/definitions/319.html)
   - [CWE-256 (암호의 일반 텍스트 저장)](https://cwe.mitre.org/data/definitions/256.html)
   - [CWE-257 (복구 가능한 형식으로 암호 저장)](https://cwe.mitre.org/data/definitions/257.html)
   - [CWE-540 (소스 코드에 민감한 정보 포함)](https://cwe.mitre.org/data/definitions/540.html)

GitLab은 결과 및 규칙의 세 가지 소스에서 식별자를 읽으며, 순서는 다음과 같습니다:

1. `result.ruleId` (항목이 `CVE-YYYY-N` 또는 `CWE-N` 형식과 일치할 때)
1. `rule.properties.tags[]` (항목이 `cwe:N`, `cwe-N`, `cve:YYYY-N` 또는 `cve-YYYY-N` 형식과 일치할 때)
1. `rule.relationships[]` (관계의 `target.toolComponent.name`가 `CWE`일 때)

> [!note]
> CVE 또는 지원되는 CWE 식별자가 없는 결과는 SAST로 지정됩니다. GitLab이 지정하는 유형을 변경하려면 스캐너를 구성하여 일치하는 CVE 또는 CWE 식별자를 내보내야 합니다.

## SARIF 필드 매핑 {#sarif-field-mapping}

GitLab은 다음 규칙에 따라 SARIF 필드를 GitLab과 호환되는 필드에 지정합니다.

| GitLab 필드          | SARIF 소스                                                                          | 필수    | 참고                                                                                                                                         |
|-----------------------|---------------------------------------------------------------------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| 심각도              | [심각도 해결](#severity-resolution) 참조                                       | {{< no >}}  | 심각도 필드가 설정되지 않은 경우 `medium`로 기본 설정됩니다.                                                                                           |
| 기본 식별자    | `result.ruleId`은(는) `run.tool.driver.rules[].id`의 해당 값과 일치합니다. | {{< yes >}} | `ruleId`이(가) 없는 결과는 추가되지 않습니다.                                                                                                    |
| 보조 식별자 | `rule.properties.tags[]` 및 `rule.relationships[]`                                   | {{< no >}}  | 보고서 유형을 지정하는 데 사용됩니다.                                                                                                               |
| 위치              | `result.locations[0].physicalLocation`                                                | {{< yes >}} | 물리적 위치가 없는 결과는 추가되지 않습니다.                                                                                           |
| 스캐너 이름          | `run.tool.driver.name`                                                                | {{< yes >}} | [유효한 SARIF](https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790791)에 필요합니다. |
| 스캐너 공급업체        | `run.tool.driver.organization`, 그 다음 `run.tool.driver.informationUri`                 | {{< no >}}  | 첫 번째 비어 있지 않은 값이 사용됩니다.                                                                                                                 |
| 스캐너 버전       | `run.tool.driver.version`, 그 다음 `run.tool.driver.semanticVersion`                     | {{< no >}}  | 첫 번째 비어 있지 않은 값이 사용됩니다.                                                                                                                 |
| 억제           | `result.suppressions[]`                                                               | {{< no >}}  | 억제된 결과는 모든 억제가 `underReview` 또는 `rejected`이 아닌 경우 건너뜁니다.                                                       |

## 심각도 해결 {#severity-resolution}

GitLab은 우선 순위 순서로 다음 필드를 확인하여 SARIF 결과의 심각도를 해결합니다. 값이 있는 첫 번째 필드가 사용됩니다.

1. `result.rank` `0.0`에서 `100.0`까지의 부동 소수점 숫자입니다.
1. `rule.properties.security-severity` `0.0`에서 `10.0`까지의 부동 소수점 숫자입니다. 값은 버킷팅 전에 10을 곱합니다.
1. `result.properties.security-severity` `0.0`에서 `10.0`까지의 부동 소수점 숫자입니다. 값은 버킷팅 전에 10을 곱합니다.
1. `result.level`
1. `rule.defaultConfiguration.level`
1. 다른 일치 항목이 없을 경우 `medium`을(를) 기본값으로 사용합니다.

`result.rank` 또는 `security-severity`의 숫자 점수는 다음 범위를 사용하여 심각도로 지정됩니다:

| 점수 (0-100) | 심각도 |
|---------------|----------|
| `0.0`-`9.9`   | 정보     |
| `10.0`-`39.9` | 낮음      |
| `40.0`-`69.9` | 중간   |
| `70.0`-`89.9` | 높음     |
| `90.0`-`100`  | 긴급 |

SARIF `level` 값은 다음과 같이 매핑됩니다:

| `level`   | 심각도 |
|-----------|----------|
| `error`   | 높음     |
| `warning` | 중간   |
| `note`    | 낮음      |
| `none`    | 정보     |

> [!note]
> GitLab은 `level: error`을(를) 높음으로 지정하며, 긴급이 아닙니다. 긴급 결과를 보고하려면 `result.rank`을(를) `90` 이상으로 설정하거나 `security-severity`을(를) `9.0` 이상으로 설정합니다.

## 수집 동작 {#ingestion-behavior}

SARIF 파일이 형식이 올바르지만 일부 결과를 추가할 수 없는 경우, GitLab은 처리할 수 없는 결과의 백분율을 사용하여 전체 스캔을 처리할 방법을 결정합니다.

| 삭제 비율     | 동작                                                | 보고됨           |
|---------------|---------------------------------------------------------|------------------------|
| 0%            | 모든 결과가 수집됩니다.                              | 메시지 없음            |
| 1% ~ 50%     | 유효한 결과가 수집됩니다.                        | 삭제 수를 포함한 경고 |
| 50% 초과 | 전체 스캔이 실패합니다. 보고서의 결과가 수집되지 않습니다. | 삭제 수를 포함한 오류   |

GitLab은 다음 중 하나의 경우 결과를 처리할 수 없습니다:

- `ruleId`이(가) 누락됨
- `physicalLocation`이(가) 누락됨
- 결과 식별자를 생성하는 데 필요한 구성 요소 중 일부가 nil입니다.
- 문자열 필드가 [문자 제한](#limits)을(를) 초과합니다.

삭제 비율은 파일의 각 `run`이(가) 아니라 전체 SARIF 아티팩트에 대해 계산됩니다. 모든 실행의 처리 불가능한 결과의 공유가 임계값을 초과하면, 수집 피드백이 아티팩트에서 내보낸 모든 보고서에 적용됩니다.

스키마 검증 오류 및 지원되지 않는 SARIF 버전은 삭제 비율과 관계없이 전체 보고서가 거부됩니다.

## 다중 도구 보고서 {#multi-tool-reports}

SARIF 파일은 각각 자체 `runs[]` 항목이 있는 여러 도구 실행을 포함할 수 있습니다. 각 실행에 대해 GitLab은 추론된 보고서 유형별로 결과를 그룹화하고 각 그룹에 대해 별도의 스캔 레코드를 만듭니다. 둘 이상의 추론된 유형의 결과를 포함하는 실행은 둘 이상의 스캔 레코드를 생성합니다. 각 스캔은 실행의 `tool.driver.name`을(를) 스캐너로 사용합니다.

다중 실행 보고서를 사용하여 여러 스캐너의 출력을 단일 아티팩트로 결합합니다. 예를 들어, 작업은 두 개의 스캐너를 실행하고 두 개의 실행을 포함하는 단일 SARIF 파일을 내보낼 수 있습니다.

파일당 실행 제한은 [제한](#limits)을 참조하세요.

## 제한 {#limits}

| 한도                                  | 기본값                                                       | 구성 가능 |
|----------------------------------------|---------------------------------------------------------------|--------------|
| 최대 SARIF 아티팩트 크기            | 10 MB (`ci_max_artifact_size_sarif`)                          | {{< yes >}}  |
| SARIF 파일당 최대 실행            | 20                                                            | {{< no >}}   |
| 실행당 최대 결과                | 5,000                                                         | {{< no >}}   |
| 실행당 최대 규칙                  | 25,000                                                        | {{< no >}}   |
| 규칙당 최대 태그                  | 10                                                            | {{< no >}}   |
| 최대 `rule.name` 길이             | 255자                                                | {{< no >}}   |
| 최대 `shortDescription.text` 길이 | 1,024자                                              | {{< no >}}   |
| 최대 `fullDescription.text` 길이  | 1,024자, 결과 제목으로 사용할 때 255자로 잘림 | {{< no >}}   |
| 최대 `message.text` 길이          | 1,024자, 결과 제목으로 사용할 때 255자로 잘림 | {{< no >}}   |
| 최대 `helpUri` 길이               | 2,048자                                              | {{< no >}}   |
| 지원되는 SARIF 버전               | 2.1.0만                                                    | {{< no >}}   |

실행당 수 제한을 초과하면 GitLab은 첫 N 항목을 처리하고 경고를 기록합니다. 결과에 문자 제한을 초과하는 문자열 필드가 있으면 전체 결과는 건너뛰고 [삭제 비율](#ingestion-behavior)로 계산됩니다.

GitLab Self-Managed 인스턴스의 경우 관리자는 [인스턴스 제한](../../../administration/instance_limits.md)을 통해 구성 가능한 제한을 변경할 수 있습니다.

## 알려진 이슈 {#known-issues}

- SAST, 종속성 검사 또는 시크릿 검색으로 지정된 SARIF 결과는 동등한 기본 GitLab 스캐너의 결과에 대해 중복 제거되지 않습니다. 자세한 내용은 [이슈 592410](https://gitlab.com/gitlab-org/gitlab/-/issues/592410)을 참조하세요.
- SARIF 억제를 통해 결과를 제외할 수 있지만 GitLab은 억제를 기반으로 취약성 해제를 생성하지 않습니다. 결과를 해제하려면 취약성 보고서를 사용합니다.

## 관련 항목 {#related-topics}

- [`artifacts:reports:sarif`](../../../ci/yaml/artifacts_reports.md#artifactsreportssarif)
- [파이프라인 보안 보고서](security_scanning_results.md)
- [프로젝트 취약성 보고서](../vulnerability_report/_index.md)
- [보안 정책](../policies/_index.md)
- [SARIF 2.1.0 사양](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
