---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "인스턴스, 그룹 및 프로젝트 분석입니다."
title: GitLab 사용 분석
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 그룹 수준 분석이 13.9에서 GitLab Premium으로 이동했습니다.

{{< /history >}}

GitLab은 소프트웨어 개발 수명 주기에 대한 인사이트를 제공하는 분석 기능을 제공합니다. 이러한 기능을 사용하여 생산성, 코드 품질, 배포 성능 및 보안을 추적합니다. 분석 기능은 인스턴스, 그룹 및 [프로젝트](../project/settings/_index.md#turn-off-project-analytics)에서 사용할 수 있으며 다양한 [역할 및 권한](../permissions.md#project-analytics)이 필요합니다. 이러한 방식으로 팀에 중요한 규모에서 데이터를 분석할 수 있습니다.

## 분석 기능 {#analytics-features}

### 엔드투엔드 인사이트 및 가시성 분석 {#end-to-end-insight--visibility-analytics}

이러한 기능을 사용하여 전체 소프트웨어 개발 수명 주기에 대한 인사이트를 얻습니다.

| 기능 | 설명 | 프로젝트 수준 | 그룹 수준 | 인스턴스 수준 |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Value Streams Dashboard](value_streams_dashboard.md) | DevSecOps 트렌드, 패턴 및 디지털 변환 개선 기회에 대한 인사이트입니다. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Value Stream Management Analytics](../group/value_stream_analytics/_index.md) | 사용자 지정 가능한 스테이지를 통한 가치 시간에 대한 인사이트입니다. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| DevOps 채택 [그룹별](../group/devops_adoption/_index.md) 및 [인스턴스별](../../administration/analytics/devops_adoption.md) | 시간에 따른 기능 채택 및 그룹별 기능 배포를 포함하여 DevOps 채택의 조직 성숙도입니다. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Usage trends](../../administration/analytics/usage_trends.md) | 인스턴스 데이터 및 시간에 따른 데이터 볼륨 변화의 개요입니다. | {{< no >}} | {{< no >}} | {{< yes >}} |
| [Insights](../project/insights/_index.md) | 이슈, 병합된 머지 리퀘스트 및 분류 위생을 탐색할 수 있는 사용자 지정 가능한 보고서입니다. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Analytics dashboards](analytics_dashboards.md) | 수집된 데이터를 시각화하기 위한 기본 제공 및 사용자 지정 가능한 대시보드입니다. | {{< yes >}} | {{< yes >}} | {{< no >}} |

### 생산성 분석 {#productivity-analytics}

이러한 기능을 사용하여 이슈 및 머지 리퀘스트에서 팀의 생산성에 대한 인사이트를 얻습니다.

| 기능 | 설명 | 프로젝트 수준 | 그룹 수준 | 인스턴스 수준 |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Issue analytics](../group/issues_analytics/_index.md) | 매달 생성된 이슈의 시각화입니다. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [머지 리퀘스트 분석](merge_request_analytics.md) | 평균 병합 시간, 처리량 및 활동 세부 정보가 포함된 머지 리퀘스트의 개요입니다. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [Productivity analytics](productivity_analytics.md) | 머지 리퀘스트 수명 주기는 작성자 수준까지 필터링할 수 있습니다. | {{< no >}} | {{< yes >}} | {{< no >}} |
| [코드 검토 분석](code_review_analytics.md) | 머지 리퀘스트 활동에 대한 정보가 포함된 개방형 머지 리퀘스트입니다. | {{< yes >}} | {{< no >}} | {{< no >}} |

### 개발자 분석 {#developer-analytics}

이러한 기능을 사용하여 개발자 생산성 및 코드 검토 범위에 대한 인사이트를 얻습니다.

| 기능 | 설명 | 프로젝트 수준 | 그룹 수준 | 인스턴스 수준 |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Contribution analytics](../group/contribution_analytics/_index.md) | 푸시 이벤트, 머지 리퀘스트 및 이슈의 막대 차트가 포함된 그룹 구성원이 만든 [커밋 이벤트](../profile/contributions_calendar.md)의 개요입니다. | {{< no >}} | {{< yes >}} | {{< no >}} |
| [기여자 분석](contributor_analytics.md) | 커밋 수의 선 차트가 포함된 프로젝트 구성원이 만든 커밋의 개요입니다. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [Repository analytics](../group/repositories_analytics/_index.md) | 리포지토리에서 사용된 프로그래밍 언어 및 코드 검토 적용 범위 통계입니다. | {{< yes >}} | {{< yes >}} | {{< no >}} |

### CI/CD 분석 {#cicd-analytics}

이러한 기능을 사용하여 CI/CD 성능에 대한 인사이트를 얻습니다.

| 기능 | 설명 | 프로젝트 수준 | 그룹 수준 | 인스턴스 수준 |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [CI/CD analytics](ci_cd_analytics.md) | 파이프라인 기간 및 성공 또는 실패입니다. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [DORA metrics](dora_metrics.md) | 시간에 따른 DORA 지표입니다. | {{< yes >}} | {{< yes >}} | {{< no >}} |

### 보안 분석 {#security-analytics}

이러한 기능을 사용하여 보안 취약성 및 지표에 대한 인사이트를 얻습니다.

| 기능 | 설명 | 프로젝트 수준 | 그룹 수준 | 인스턴스 수준 |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Security Dashboards](../application_security/security_dashboard/_index.md) | 보안 스캐너에서 감지한 취약성에 대한 메트릭, 평가 및 차트의 모음입니다. | {{< yes >}} | {{< yes >}} | {{< no >}} |

## 메트릭 용어집 {#metric-glossary}

다음 용어집은 분석 기능에 사용되는 일반적인 개발 메트릭의 정의를 제공하며 GitLab에서 측정되는 방식을 설명합니다.

| 메트릭 | 정의 | GitLab에서의 측정 |
| ------ | ---------- | --------------------- |
| 평균 변경 시간(MTTC) | 아이디어와 배포 사이의 평균 기간입니다. | 이슈가 생성된 시점부터 관련 머지 리퀘스트가 프로덕션에 배포될 때까지입니다. |
| 평균 탐지 시간(MTTD) | 버그가 프로덕션에서 감지되지 않은 평균 기간입니다. | 버그가 프로덕션에 배포된 시점부터 버그를 보고하기 위해 이슈가 생성될 때까지입니다. |
| 평균 병합 시간(MTTM) | 머지 리퀘스트의 평균 수명입니다. | 머지 리퀘스트가 생성된 시점부터 병합될 때까지입니다. 종료되거나 병합되지 않은 머지 리퀘스트를 제외합니다. 자세한 내용은 [머지 리퀘스트 분석](merge_request_analytics.md)을 참조하세요. |
| 평균 복구/복구/해결/해결/복원 시간(MTTR) | 버그가 프로덕션에서 수정되지 않은 평균 기간입니다. | 버그가 프로덕션에 배포된 시점부터 버그 수정이 배포될 때까지입니다. |
| 속도 | 특정 시간 기간 내에 완료된 총 이슈 부담입니다. 부담은 일반적으로 포인트 또는 가중치로 측정되며, 종종 스프린트당입니다. | 특정 시간 기간에 종료된 이슈의 총 포인트 또는 가중치입니다. 예를 들어, "스프린트당 30포인트"입니다. |

자세한 정의는 [Value Streams Dashboard 메트릭 및 드릴다운 보고서](value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports)도 참조하세요.
