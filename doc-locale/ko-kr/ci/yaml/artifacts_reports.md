---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "테스트 결과, 보안 스캔, 코드 품질 검사 및 성능 메트릭스에 대한 아티팩트 보고서 유형."
title: CI/CD 아티팩트 보고서 유형
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[`artifacts:reports`](_index.md#artifactsreports)을(를) 사용하여 다음을 수행합니다:

- 테스트 보고서, 코드 품질 보고서, 보안 보고서 및 작업에 포함된 템플릿으로 생성된 기타 아티팩트를 수집합니다.
- 이 보고서의 일부는 다음에서 정보를 표시하는 데 사용됩니다:
  - 머지 리퀘스트.
  - 파이프라인 보기.
  - [보안 대시보드](../../user/application_security/security_dashboard/_index.md).

`artifacts: reports`에 대해 생성된 아티팩트는 작업 결과(성공 또는 실패) 관계없이 항상 업로드됩니다. [`artifacts:expire_in`](_index.md#artifactsexpire_in)를 사용하여 아티팩트의 만료 시간을 설정할 수 있습니다. 이는 인스턴스의 [기본 설정](../../administration/settings/continuous_integration.md#set-default-artifacts-expiration)을(를) 재정의합니다. GitLab.com은 [다른 기본 아티팩트 만료 값](../../user/gitlab_com/_index.md#cicd)을(를) 가질 수 있습니다.

일부 `artifacts:reports` 유형은 동일한 파이프라인에서 여러 작업으로 생성될 수 있으며, 각 작업에서 머지 리퀘스트 또는 파이프라인 기능으로 사용될 수 있습니다.

보고서 출력 파일을 찾아보려면 작업 정의에 [`artifacts:paths`](_index.md#artifactspaths) 키워드를 포함해야 합니다.

> [!note]
> 상위 파이프라인의 결합된 보고서에서 [하위 파이프라인의 아티팩트](_index.md#needspipelinejob)를 사용하는 것은 지원되지 않습니다. 이 기능에 대한 지원은 [에픽 8205](https://gitlab.com/groups/gitlab-org/-/epics/8205)에서 제안되었습니다.

## `artifacts:reports:accessibility` {#artifactsreportsaccessibility}

`accessibility` 보고서는 [pa11y](https://pa11y.org/)를 사용하여 머지 리퀘스트에 도입된 변경 사항의 접근성 영향을 보고합니다.

GitLab은 머지 리퀘스트 [접근성 위젯](../testing/accessibility_testing.md#accessibility-merge-request-widget)에서 하나 이상의 보고서 결과를 표시할 수 있습니다.

자세한 내용은 [접근성 테스트](../testing/accessibility_testing.md)를 참조하세요.

## `artifacts:reports:annotations` {#artifactsreportsannotations}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)되었습니다.

{{< /history >}}

`annotations` 보고서는 작업에 보조 데이터를 첨부하는 데 사용됩니다.

주석 보고서는 주석 섹션이 있는 JSON 파일입니다. 각 주석 섹션은 원하는 이름을 가질 수 있으며 동일하거나 다른 유형의 여러 주석을 포함할 수 있습니다.

각 주석은 단일 키(주석 유형)이며, 해당 주석의 데이터가 있는 하위 키를 포함합니다.

### 주석 유형 {#annotation-types}

#### `external_link` {#external_link}

`external_link` 주석을 작업에 첨부하여 작업 출력 페이지에 링크를 추가할 수 있습니다. `external_link` 주석의 값은 다음 키가 있는 객체입니다:

| 키     | 설명 |
|---------|-------------|
| `label` | 링크와 연결된 사람이 읽을 수 있는 레이블입니다. |
| `url`   | 링크가 가리키는 URL입니다. |

### 예제 보고서 {#example-report}

다음은 작업 주석 보고서가 어떻게 보일 수 있는지에 대한 예입니다:

```json
{
  "my_annotation_section_1": [
    {
      "external_link": {
        "label": "URL 1",
        "url": "https://url1.example.com/"
      }
    },
    {
      "external_link": {
        "label": "URL 2",
        "url": "https://url2.example.com/"
      }
    }
  ]
}
```

## `artifacts:reports:api_fuzzing` {#artifactsreportsapi_fuzzing}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

`api_fuzzing` 보고서는 [API 퍼징 버그](../../user/application_security/api_fuzzing/_index.md)를 아티팩트로 수집합니다.

GitLab은 다음에서 하나 이상의 보고서 결과를 표시할 수 있습니다:

- 머지 리퀘스트 [보안 위젯](../../user/application_security/api_fuzzing/configuration/enabling_the_analyzer.md#view-details-of-an-api-fuzzing-vulnerability).
- [프로젝트 취약성 보고서](../../user/application_security/vulnerability_report/_index.md).
- 파이프라인 [**보안** 탭](../../user/application_security/detect/security_scanning_results.md).
- [보안 대시보드](../../user/application_security/api_fuzzing/configuration/enabling_the_analyzer.md#security-dashboard).

## `artifacts:reports:browser_performance` {#artifactsreportsbrowser_performance}

{{< details >}}

- 티어: Premium, Ultimate

{{< /details >}}

`browser_performance` 보고서는 브라우저 성능 테스트 메트릭스를 아티팩트로 수집합니다. 이 아티팩트는 [GitLab sitespeed.io 플러그인](https://gitlab.com/gitlab-org/gl-performance)으로 생성된 JSON 파일입니다.

GitLab은 머지 리퀘스트에서 결과를 표시합니다. 자세한 내용은 [브라우저 성능 테스트](../testing/browser_performance_testing.md)를 참조하세요.

GitLab은 여러 `browser_performance` 보고서의 결합된 결과를 표시할 수 없습니다.

## `artifacts:reports:coverage_report` {#artifactsreportscoverage_report}

`coverage_report`을(를) 사용하여 Cobertura 또는 JaCoCo 형식의 커버리지 보고서를 수집합니다. 파이프라인이 완료된 후 GitLab은 보고서를 구문 분석하고 머지 리퀘스트 diff에서 줄 단위 커버리지 주석을 표시합니다.

> [!note]
> 이 키워드는 diff 주석만 생성합니다. 머지 리퀘스트 위젯에 커버리지 백분율을 표시하거나 커버리지 기록 그래프를 채우지 않습니다. 커버리지 백분율을 표시하려면 [`coverage`](_index.md#coverage) 키워드를 별도로 구성합니다.

자세한 정보는 다음을 참조하세요.

- [Cobertura 커버리지 시각화](../testing/code_coverage/cobertura.md)
- [JaCoCo 커버리지 시각화](../testing/code_coverage/jacoco.md)

```yaml
artifacts:
  reports:
    coverage_report:
      coverage_format: cobertura
      path: coverage/cobertura-coverage.xml
```

[와일드카드](../jobs/job_artifacts.md#with-wildcards)를 사용하여 여러 보고서를 생성하고 수집할 수 있습니다. GitLab은 결과를 단일 보고서로 병합합니다.

하위 파이프라인의 커버리지 보고서는 머지 리퀘스트 diff 주석에 나타나지만 상위 파이프라인과 공유되지 않습니다.

## `artifacts:reports:codequality` {#artifactsreportscodequality}

`codequality` 보고서는 [코드 품질 이슈](../testing/code_quality.md)를 수집합니다. 수집된 코드 품질 보고서는 GitLab에 아티팩트로 업로드됩니다.

GitLab은 다음에서 하나 이상의 보고서 결과를 표시할 수 있습니다:

- 머지 리퀘스트 [코드 품질 보고서](../../user/project/merge_requests/reports.md#code-quality-report).
- 머지 리퀘스트 [diff 주석](../testing/code_quality.md#merge-request-changes-view).
- [전체 보고서](../testing/metrics_reports.md).

[`artifacts:expire_in`](_index.md#artifactsexpire_in) 값이 `1 week`로 설정됩니다.

## `artifacts:reports:container_scanning` {#artifactsreportscontainer_scanning}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

`container_scanning` 보고서는 [컨테이너 스캔 취약성](../../user/application_security/container_scanning/_index.md)을(를) 수집합니다. 수집된 컨테이너 스캔 보고서는 GitLab에 아티팩트로 업로드됩니다.

GitLab은 다음에서 하나 이상의 보고서 결과를 표시할 수 있습니다:

- 머지 리퀘스트 [컨테이너 스캔 위젯](../../user/application_security/container_scanning/_index.md).
- 파이프라인 [**보안** 탭](../../user/application_security/detect/security_scanning_results.md).
- [보안 대시보드](../../user/application_security/security_dashboard/_index.md).
- [프로젝트 취약성 보고서](../../user/application_security/vulnerability_report/_index.md).

## `artifacts:reports:coverage_fuzzing` {#artifactsreportscoverage_fuzzing}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

`coverage_fuzzing` 보고서는 [커버리지 퍼징 버그](../../user/application_security/coverage_fuzzing/_index.md)를 수집합니다. 수집된 커버리지 퍼징 보고서는 GitLab에 아티팩트로 업로드됩니다. GitLab은 다음에서 하나 이상의 보고서 결과를 표시할 수 있습니다:

- 머지 리퀘스트 [커버리지 퍼징 위젯](../../user/application_security/coverage_fuzzing/_index.md#interacting-with-the-vulnerabilities).
- 파이프라인 [**보안** 탭](../../user/application_security/detect/security_scanning_results.md).
- [프로젝트 취약성 보고서](../../user/application_security/vulnerability_report/_index.md).
- [보안 대시보드](../../user/application_security/security_dashboard/_index.md).

## `artifacts:reports:cyclonedx` {#artifactsreportscyclonedx}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

이 보고서는 [CycloneDX](https://cyclonedx.org/docs/1.4) 프로토콜 형식에 따라 프로젝트의 구성 요소를 설명하는 소프트웨어 물질 명세서입니다.

작업당 여러 CycloneDX 보고서를 지정할 수 있습니다. 이는 파일 이름 목록, 파일 이름 패턴 또는 둘 다로 제공될 수 있습니다:

- 파일 이름 패턴 (`cyclonedx: gl-sbom-*.json`, `junit: test-results/**/*.json`).
- 파일 이름 배열 (`cyclonedx: [gl-sbom-npm-npm.cdx.json, gl-sbom-bundler-gem.cdx.json]`).
- 둘 다의 조합 (`cyclonedx: [gl-sbom-*.json, my-cyclonedx.json]`).
- 디렉토리는 지원되지 않습니다(`cyclonedx: test-results`, `cyclonedx: test-results/**`).

다음 예는 CycloneDX 아티팩트를 노출하는 작업을 보여줍니다:

```yaml
artifacts:
  reports:
    cyclonedx:
      - gl-sbom-npm-npm.cdx.json
      - gl-sbom-bundler-gem.cdx.json
```

## `artifacts:reports:dast` {#artifactsreportsdast}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

`dast` 보고서는 [DAST 취약성](../../user/application_security/dast/_index.md)을(를) 수집합니다. 수집된 DAST 보고서는 GitLab에 아티팩트로 업로드됩니다.

GitLab은 다음에서 하나 이상의 보고서 결과를 표시할 수 있습니다:

- 머지 리퀘스트 보안 위젯.
- 파이프라인 [**보안** 탭](../../user/application_security/detect/security_scanning_results.md).
- [프로젝트 취약성 보고서](../../user/application_security/vulnerability_report/_index.md).
- [보안 대시보드](../../user/application_security/security_dashboard/_index.md).

## `artifacts:reports:dependency_scanning` {#artifactsreportsdependency_scanning}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

`dependency_scanning` 보고서는 [종속성 검사 취약성](../../user/application_security/dependency_scanning/_index.md)을(를) 수집합니다. 수집된 종속성 검사 보고서는 GitLab에 아티팩트로 업로드됩니다.

GitLab은 다음에서 하나 이상의 보고서 결과를 표시할 수 있습니다:

- 머지 리퀘스트 [종속성 검사 위젯](../../user/application_security/dependency_scanning/_index.md).
- 파이프라인 [**보안** 탭](../../user/application_security/detect/security_scanning_results.md).
- [보안 대시보드](../../user/application_security/security_dashboard/_index.md).
- [프로젝트 취약성 보고서](../../user/application_security/vulnerability_report/_index.md).
- [종속성 목록](../../user/application_security/dependency_list/_index.md).

## `artifacts:reports:dotenv` {#artifactsreportsdotenv}

`dotenv` 보고서는 파일에서 환경 변수를 수집하고 CI/CD 변수로 파이프라인의 나중 작업에 제공합니다.

자세한 내용은 [dotenv 변수](../variables/dotenv_variables.md)를 참조하세요.

## `artifacts:reports:junit` {#artifactsreportsjunit}

`junit` 보고서는 [JUnit 보고서 형식 XML 파일](https://www.ibm.com/docs/en/developer-for-zos/16.0?topic=formats-junit-xml-format)을(를) 수집합니다. 수집된 단위 테스트 보고서는 GitLab에 아티팩트로 업로드됩니다. JUnit은 원래 Java에서 개발되었지만 JavaScript, Python 및 Ruby와 같은 다른 언어에 대한 많은 타사 포트가 있습니다.

[단위 테스트 보고서](../testing/unit_test_reports.md)를 참조하여 더 많은 세부 정보와 예를 확인하세요. 다음 예는 Ruby RSpec 테스트에서 JUnit XML 보고서를 수집하는 방법을 보여줍니다:

```yaml
rspec:
  stage: test
  script:
    - bundle install
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

GitLab은 다음에서 하나 이상의 보고서 결과를 표시할 수 있습니다:

- 머지 리퀘스트 [**테스트 요약** 패널](../testing/unit_test_reports.md#view-test-results-in-merge-requests).
- [파이프라인 **테스트** 탭](../testing/unit_test_reports.md#view-test-results-in-pipelines).

일부 JUnit 도구는 여러 XML 파일로 내보냅니다. 단일 작업에서 여러 테스트 보고서 경로를 지정하여 단일 파일로 연결할 수 있습니다. 다음 중 하나를 사용합니다:

- 파일 이름 패턴 (`junit: rspec-*.xml`, `junit: test-results/**/*.xml`).
- 파일 이름 배열 (`junit: [rspec-1.xml, rspec-2.xml, rspec-3.xml]`).
- 둘 다의 조합 (`junit: [rspec.xml, test-results/TEST-*.xml]`).
- 디렉토리는 지원되지 않습니다 (`junit: test-results`, `junit: test-results/**`).

## `artifacts:reports:load_performance` {#artifactsreportsload_performance}

{{< details >}}

- 티어: Premium, Ultimate

{{< /details >}}

`load_performance` 보고서는 [부하 성능 테스트 메트릭스](../testing/load_performance_testing.md)를 수집하고 아티팩트로 업로드됩니다.

결과는 머지 리퀘스트 [부하 테스트 위젯](../testing/load_performance_testing.md#load-performance-results-in-merge-requests)에 표시됩니다. 여러 `load_performance` 보고서의 결합된 결과는 지원되지 않습니다.

## `artifacts:reports:metrics` {#artifactsreportsmetrics}

{{< details >}}

- 티어: Premium, Ultimate

{{< /details >}}

`metrics` 보고서는 [메트릭스](../testing/metrics_reports.md)를 수집합니다. 수집된 메트릭스 보고서는 GitLab에 아티팩트로 업로드됩니다.

GitLab은 머지 리퀘스트 [메트릭스 보고서 위젯](../testing/metrics_reports.md)에서 하나 이상의 보고서 결과를 표시할 수 있습니다.

## `artifacts:reports:requirements` {#artifactsreportsrequirements}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

`requirements` 보고서는 `requirements.json` 파일을 수집합니다. 수집된 요구사항 보고서는 GitLab에 아티팩트로 업로드되며 기존 [요구사항](../../user/project/requirements/_index.md)은 만족으로 표시됩니다.

GitLab은 [프로젝트 요구사항](../../user/project/requirements/_index.md#view-a-requirement)에서 하나 이상의 보고서 결과를 표시할 수 있습니다.

## `artifacts:reports:sarif` {#artifactsreportssarif}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

{{< history >}}

- [GitLab 18.11에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/452042) - [기능 플래그](../../administration/feature_flags/_index.md) `sarif_ingestion` 포함. 기본적으로 비활성화되어 있습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 `sarif_ingestion`라는 기능 플래그에 의해 제어됩니다. 자세한 내용은 기록을 참조하세요.

`sarif` 보고서는 [SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html) 출력을 내보내는 도구에서 보안 결과를 수집합니다. 수집된 SARIF 보고서는 GitLab에 아티팩트로 업로드됩니다.

이 보고서 유형을 사용하여 Semgrep, ESLint 보안 플러그인 또는 GitHub Advanced Security 도구와 같은 SARIF 호환 스캐너에서 결과를 수집합니다.

GitLab은 다음에서 하나 이상의 보고서 결과를 표시할 수 있습니다:

- 파이프라인 [**보안** 탭](../../user/application_security/detect/security_scanning_results.md).
- [보안 대시보드](../../user/application_security/security_dashboard/_index.md).
- [프로젝트 취약성 보고서](../../user/application_security/vulnerability_report/_index.md).

**예**:

```yaml
semgrep:
  image: returntocorp/semgrep
  script:
    - semgrep ci --sarif --output gl-sarif-report.sarif
  artifacts:
    reports:
      sarif: gl-sarif-report.sarif
```

동작, 제한, 필드 매핑 및 추론된 보고서 유형에 대한 세부 정보는 [SARIF 보고서](../../user/application_security/detect/sarif.md)를 참조하세요.

## `artifacts:reports:sast` {#artifactsreportssast}

`sast` 보고서는 [SAST 취약성](../../user/application_security/sast/_index.md)을(를) 수집합니다. 수집된 SAST 보고서는 GitLab에 아티팩트로 업로드됩니다.

자세한 정보는 다음을 참조하세요.

- [SAST 결과 보기](../../user/application_security/sast/_index.md#understanding-the-results)
- [SAST 출력](../../user/application_security/sast/_index.md#download-a-sast-report)

## `artifacts:reports:secret_detection` {#artifactsreportssecret_detection}

`secret-detection` 보고서는 [시크릿 검색 대상](../../user/application_security/secret_detection/pipeline/_index.md)을(를) 수집합니다. 수집된 시크릿 검색 보고서는 GitLab에 업로드됩니다.

GitLab은 다음에서 하나 이상의 보고서 결과를 표시할 수 있습니다:

- 머지 리퀘스트 [시크릿 검색 위젯](../../user/application_security/secret_detection/pipeline/_index.md).
- [파이프라인 보안 탭](../../user/application_security/detect/security_scanning_results.md).
- [보안 대시보드](../../user/application_security/security_dashboard/_index.md).

## `artifacts:reports:terraform` {#artifactsreportsterraform}

`terraform` 보고서는 OpenTofu `tfplan.json` 파일을 얻습니다. [자격 증명을 제거하기 위해 JQ 처리 필요](../../user/infrastructure/iac/mr_integration.md#configure-opentofu-report-artifacts). 수집된 OpenTofu 계획 보고서는 GitLab에 아티팩트로 업로드됩니다.

GitLab은 머지 리퀘스트 [OpenTofu 위젯](../../user/infrastructure/iac/mr_integration.md#output-opentofu-plan-information-into-a-merge-request)에서 하나 이상의 보고서 결과를 표시할 수 있습니다.

자세한 내용은 [`tofu plan` 정보를 머지 리퀘스트에 출력](../../user/infrastructure/iac/mr_integration.md)을 참조하세요.
