---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 취약성 위험 평가 데이터
---

취약성 위험 데이터를 사용하여 환경에 대한 잠재적 영향을 평가할 수 있습니다.

- 심각도:  각 취약성에는 표준화된 GitLab 심각도 값이 할당됩니다.
- [공통 취약점 및 노출(CVE)](https://www.cve.org/) 카탈로그의 취약성의 경우 [취약성 세부 정보](_index.md) 페이지를 통하거나 GraphQL 쿼리를 사용하여 다음 데이터를 검색할 수 있습니다:
  - 악용 가능성: [악용 예측 점수 체계(EPSS)](https://www.first.org/epss/) 점수입니다.
  - 알려진 악용의 존재: [알려진 악용된 취약성(KEV)](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) 상태입니다.

이 데이터를 사용하여 수정 및 완화 조치의 우선순위를 정하는 데 도움이 됩니다. 예를 들어 중간 심각도와 높은 EPSS 점수의 취약성은 높은 심각도와 낮은 EPSS 점수의 취약성보다 더 빨리 완화가 필요할 수 있습니다.

## EPSS {#epss}

{{< history >}}

- GitLab 17.4에서 [기능 플래그](../../../administration/feature_flags/_index.md)를 사용하여 도입되었으며 `epss_querying` (이슈 [470835](https://gitlab.com/gitlab-org/gitlab/-/issues/470835)에서) 및 `epss_ingestion` (이슈 [467672](https://gitlab.com/gitlab-org/gitlab/-/issues/467672)에서) 이름이 지정되었습니다. 기본적으로 사용 중지됩니다.
- `cve_enrichment_querying` 및 `cve_enrichment_ingestion`로 이름이 바뀌었으며, GitLab 17.6에서 [GitLab.com에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/481431).
- GitLab 17.7에서 [일반적으로 사용 가능합니다](https://gitlab.com/groups/gitlab-org/-/epics/11544). `cve_enrichment_querying` 및 `cve_enrichment_ingestion` 기능 플래그가 제거되었습니다.

{{< /history >}}

EPSS 점수는 향후 30일 내에 CVE 카탈로그의 취약성이 악용될 가능성을 추정합니다. EPSS는 각 CVE에 0~1 사이의 점수(0%~100%에 해당)를 할당합니다.

## KEV {#kev}

{{< history >}}

- GitLab 17.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/499407)되었습니다.

{{< /history >}}

KEV 카탈로그에는 악용된 것으로 알려진 취약성이 나열됩니다. KEV 카탈로그의 취약성 수정을 다른 취약성보다 우선순위를 두어야 합니다. 이러한 취약성을 사용한 공격이 발생했으며 악용 방법은 공격자에게 알려져 있을 가능성이 높습니다.

## 도달 가능성 {#reachability}

{{< history >}}

- GitLab 17.11에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/16510)되었습니다.

{{< /history >}}

도달 가능성은 응용 프로그램에서 가져온 취약한 패키지를 표시합니다. 코드가 직접 상호 작용하는 패키지의 취약성은 사용되지 않는 종속성의 취약성보다 높은 위험을 초래합니다. 도달 가능한 취약성 수정을 우선순위로 지정하십시오. 이러한 취약성은 공격자가 악용할 수 있는 실제 노출 지점을 나타냅니다.

자세한 내용은 [정적 도달 가능성](../dependency_scanning/static_reachability.md)을 참조하십시오.

## 위험 평가 데이터 쿼리 {#query-risk-assessment-data}

GraphQL API를 사용하여 프로젝트의 취약성 심각도, EPSS 및 KEV 값을 쿼리합니다.

GraphQL API의 `Vulnerability` 유형에는 `cveEnrichment` 필드가 있으며, 이 필드는 `identifiers` 필드에 CVE 식별자가 포함되어 있을 때 채워집니다. `cveEnrichment` 필드에는 취약성의 CVE ID, EPSS 점수 및 KEV 상태가 포함됩니다. EPSS 점수는 소수점 둘째 자리로 반올림됩니다.

예를 들어 다음 GraphQL API 쿼리는 지정된 프로젝트의 모든 취약성과 해당 CVE ID, EPSS 점수 및 KEV 상태(`isKnownExploit`)를 반환합니다. [GraphQL 탐색기](../../../api/graphql/_index.md#interactive-graphql-explorer)나 다른 GraphQL 클라이언트에서 쿼리를 실행합니다.

```graphql
{
  project(fullPath: "<full/path/to/project>") {
    vulnerabilities {
      nodes {
        severity
        identifiers {
          externalId
          externalType
        }
        cveEnrichment {
          epssScore
          isKnownExploit
          cve
        }
        reachability
      }
    }
  }
}
```

예제 출력:

```json
{
  "data": {
    "project": {
      "vulnerabilities": {
        "nodes": [
          {
            "severity": "CRITICAL",
            "identifiers": [
              {
                "externalId": "CVE-2019-3859",
                "externalType": "cve"
              }
            ],
            "cveEnrichment": {
              "epssScore": 0.2,
              "isKnownExploit": false,
              "cve": "CVE-2019-3859"
            }
            "reachability": "UNKNOWN"
          },
          {
            "severity": "CRITICAL",
            "identifiers": [
              {
                "externalId": "CVE-2016-8735",
                "externalType": "cve"
              }
            ],
            "cveEnrichment": {
              "epssScore": 0.94,
              "isKnownExploit": true,
              "cve": "CVE-2016-8735"
            }
            "reachability": "IN_USE"
          },
        ]
      }
    }
  },
  "correlationId": "..."
}
```

## 취약성 우선순위 지정자 {#vulnerability-prioritizer}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

프로젝트의 취약성(특히 CVE)의 우선순위를 지정하는 데 도움이 되는 [취약성 우선순위 지정자 CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/vulnerability-prioritizer)를 사용합니다. 구성 요소는 `vulnerability-prioritizer` 작업의 출력에서 우선순위 지정 보고서를 출력합니다.

취약성은 다음 순서로 나열됩니다:

1. 알려진 악용이 있는 취약성(KEV)이 최우선입니다.
1. 더 높은 EPSS 점수(1에 가까울수록)가 우선순위가 지정됩니다.
1. 심각도는 `Critical`에서 `Low`로 정렬됩니다.

[종속성 검사](../dependency_scanning/_index.md) 및 [컨테이너 검사](../container_scanning/_index.md)로 감지된 취약성만 포함됩니다. 취약성 우선순위 지정자 CI/CD 구성 요소는 공통 취약점 및 노출(CVE) 레코드에서만 사용 가능한 데이터가 필요하기 때문입니다. 또한 [감지된(**분류 필요**) 및 확인된](_index.md#vulnerability-status-values) 취약성만 표시됩니다.

프로젝트의 CI/CD 파이프라인에 취약성 우선순위 지정자 CI/CD 구성 요소를 추가하려면 [취약성 우선순위 지정자 설명서](https://gitlab.com/components/vulnerability-prioritizer)를 참조하십시오.
