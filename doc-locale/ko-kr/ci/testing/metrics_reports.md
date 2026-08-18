---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "성능, 메모리 및 사용자 지정 메트릭을 추적하고 비교합니다."
title: 측정항목 보고서
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

머지 리퀘스트에서 사용자 지정 메트릭을 표시하여 브랜치 간 성능, 메모리 사용량 및 기타 측정값을 추적합니다.

측정항목 보고서를 사용하여:

- 메모리 사용량 변화를 모니터링합니다.
- 로드 테스트 결과를 추적합니다.
- 코드 복잡도를 측정합니다.
- 코드 커버리지 통계를 비교합니다.

## 측정항목 처리 워크플로우 {#metrics-processing-workflow}

파이프라인이 실행되면 GitLab은 보고서 아티팩트에서 측정항목을 읽고 비교를 위해 문자열 값으로 저장합니다. 기본 파일명은 `metrics.txt`입니다.

머지 리퀘스트의 경우 GitLab은 기능 브랜치의 측정항목을 대상 브랜치의 값과 비교하여 다음 순서대로 머지 리퀘스트 위젯에 표시합니다:

- 변경된 값이 있는 기존 측정항목입니다.
- 머지 리퀘스트에서 추가된 측정항목(**신규** 배지로 표시).
- 머지 리퀘스트에서 제거된 측정항목(**제거됨** 배지로 표시).
- 변경되지 않은 값이 있는 기존 측정항목입니다.

### 기준 파이프라인 선택 {#baseline-pipeline-selection}

브랜치 간의 측정항목을 비교하기 위해 GitLab은 다음 프로세스를 사용하여 대상 브랜치에서 기준 파이프라인을 식별합니다:

1. 다음 커밋 SHA와 일치하는 대상 브랜치의 파이프라인을 확인합니다(순서대로):
   1. [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md)이 생성된 당시의 대상 브랜치 팁입니다. 이 SHA는 머지 리퀘스트 파이프라인에서만 사용할 수 있습니다.
   1. 병합 베이스 커밋(소스 및 대상 브랜치의 공통 상위).
   1. 머지 리퀘스트 diff의 시작 커밋.
1. 일치하는 파이프라인이 있는 첫 번째 SHA에 대해 가장 최근에 생성된 파이프라인(파이프라인 ID 기준)을 선택합니다.

기준 파이프라인 선택:

- 파이프라인 상태로 필터링하지 않습니다. 모든 상태(`success`, `failed`, `canceled`, 또는 `skipped`)의 파이프라인을 기준으로 선택할 수 있습니다.
- 기준 파이프라인에 측정항목 보고서 아티팩트가 있는지 확인하지 않습니다. 기준 파이프라인이 존재하지만 측정항목 아티팩트가 없으면 기능 브랜치의 모든 측정항목이 신규로 표시됩니다.

측정항목 비교 위젯은 기능 브랜치 파이프라인이 완료된 상태이고 측정항목 보고서 아티팩트가 있을 때만 표시됩니다.

파이프라인의 유형은 일치하는 첫 번째 커밋 SHA에 영향을 줍니다:

- 머지 리퀘스트 파이프라인: 대상 브랜치 팁 SHA를 일반적으로 사용할 수 있으므로 기준은 일반적으로 머지 리퀘스트 파이프라인이 생성된 대상 브랜치 팁의 최신 파이프라인입니다.
- 브랜치 파이프라인: 대상 브랜치 팁 SHA를 사용할 수 없으므로 병합 베이스 커밋이 대신 사용됩니다. 기준은 공통 상위 커밋의 대상 브랜치에서 최신 파이프라인입니다.

비교를 위해 기준이 항상 사용 가능한지 확인하려면:

- 측정항목 보고서 아티팩트를 생성하는 대상 브랜치에서 파이프라인을 실행합니다.
- 브랜치 파이프라인을 사용하는 경우 병합 베이스 커밋이 대상 브랜치에 파이프라인을 가지고 있는지 확인합니다.

## 측정항목 보고서 구성 {#configure-metrics-reports}

CI/CD 파이프라인에 측정항목 보고서를 추가하여 머지 리퀘스트에서 사용자 지정 측정항목을 추적합니다.

전제 조건:

- 측정항목 파일은 [OpenMetrics](https://prometheus.io/docs/instrumenting/exposition_formats/#openmetrics-text-format) 텍스트 형식을 사용해야 합니다.

측정항목 보고서를 구성하려면:

1. `.gitlab-ci.yml` 파일에서 측정항목 보고서를 생성하는 작업을 추가합니다.
1. OpenMetrics 형식으로 측정항목을 생성하는 작업에 스크립트를 추가합니다.
1. 작업을 구성하여 [`artifacts:reports:metrics`](../yaml/artifacts_reports.md#artifactsreportsmetrics)로 측정항목 파일을 업로드합니다.

예를 들어:

```yaml
metrics:
  stage: test
  script:
    - echo 'memory_usage_bytes 2621440' > metrics.txt
    - echo 'response_time_seconds 0.234' >> metrics.txt
    - echo 'test_coverage_percent 87.5' >> metrics.txt
    - echo '# EOF' >> metrics.txt
  artifacts:
    reports:
      metrics: metrics.txt
```

파이프라인이 실행된 후 측정항목 보고서가 머지 리퀘스트 위젯에 표시됩니다.

![측정항목 이름과 값을 표시하는 머지 리퀘스트의 측정항목 보고서 위젯.](img/metrics_report_v18_3.png)

추가 형식 사양 및 예제는 [Prometheus 텍스트 형식 세부 정보](https://prometheus.io/docs/instrumenting/exposition_formats/#text-format-details)를 참조하세요.

## 문제 해결 {#troubleshooting}

측정항목 보고서로 작업할 때 다음과 같은 문제가 발생할 수 있습니다.

### 측정항목 보고서가 변경되지 않음 {#metrics-reports-did-not-change}

머지 리퀘스트에서 측정항목 보고서를 볼 때 **측정항목 보고서 스캔에서 새 변경 사항이 감지되지 않음**이 표시될 수 있습니다.

이 문제는 다음의 경우에 발생합니다:

- 대상 브랜치에 비교할 기준 측정항목 보고서가 없습니다.
- GitLab 구독에 측정항목 보고서가 포함되지 않습니다(Premium 또는 Ultimate 필수).

이 이슈를 해결하려면:

1. GitLab 구독 티어에 측정항목 보고서가 포함되는지 확인합니다.
1. 대상 브랜치에 측정항목 보고서가 구성된 파이프라인이 있는지 확인합니다. 사용 가능한지 확인하려면 측정항목 보고서 아티팩트를 생성하는 대상 브랜치에서 파이프라인을 실행합니다.
1. 측정항목 파일이 유효한 OpenMetrics 형식을 사용하는지 확인합니다.
