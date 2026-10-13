---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "조직 전체에서 DevSecOps 메트릭(예: DORA 및 취약성)을 커스터마이징 가능한 대시보드에서 확인합니다."
title: Value Streams Dashboard
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.2에서 [GitLab Ultimate에서 GitLab Premium으로 이동](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195086)되었습니다.

{{< /history >}}

가치 흐름 대시보드는 디지털 혁신 개선 기회를 식별하기 위해 추세, 패턴 및 개선 방안을 찾을 수 있는 커스터마이징 가능한 대시보드입니다. 가치 흐름 대시보드의 중앙화된 UI는 단일 정보 원본(SSOT) 역할을 하여 모든 이해관계자가 조직과 관련된 동일한 메트릭 세트에 접근하고 확인할 수 있습니다. 가치 흐름 대시보드에는 다음 메트릭을 시각화하는 패널이 포함됩니다:

- [DORA metrics](dora_metrics.md)
- [가치 흐름 분석(VSA) - 플로우 메트릭](../group/value_stream_analytics/_index.md)
- [취약성](../application_security/vulnerability_report/_index.md)
- GitLab Duo Code Suggestions

가치 흐름 대시보드를 사용하면 다음을 수행할 수 있습니다:

- 시간 경과에 따라 이전에 나열한 메트릭을 추적하고 비교합니다.
- 하향 추세를 조기에 식별합니다.
- 보안 노출을 파악합니다.
- 개별 프로젝트 또는 메트릭으로 드릴다운하여 개선 조치를 취합니다.
- 소프트웨어 개발 수명 주기(SDLC)에 AI를 추가하는 영향을 파악하고 GitLab Duo에 대한 투자의 투자 수익률(ROI)을 입증합니다.

클릭스루 데모를 보려면 [가치 흐름 관리 제품 투어](https://gitlab.navattic.com/vsm)를 참조하세요.

그룹의 분석 대시보드로 가치 흐름 대시보드를 확인하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **분석** > **분석 대시보드**를 선택합니다.
1. 사용 가능한 대시보드 목록에서 **가치 흐름 대시보드**를 선택합니다.

> [!note]
> 가치 흐름 대시보드에 표시된 데이터는 백엔드에서 지속적으로 수집됩니다. Ultimate 티어로 업그레이드하면 과거 데이터에 접근할 수 있으며 GitLab 사용 및 성능에 대한 과거 메트릭을 확인할 수 있습니다.

## 패널 {#panels}

가치 흐름 대시보드 패널에는 기본 구성이 있지만 대시보드 패널을 커스터마이징할 수도 있습니다.

### 개요 {#overview}

{{< history >}}

- GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/439699)되었으며 [기능 플래그](../../administration/feature_flags/_index.md)는 `group_analytics_dashboard_dynamic_vsd`입니다. 기본적으로 비활성화되었습니다.
- GitLab 17.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/432185)합니다.
- 기능 플래그 `group_analytics_dashboard_dynamic_vsd`은 GitLab 17.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/441206)되었습니다.

{{< /history >}}

개요는 주요 DevOps 메트릭을 시각화하여 최상위 네임스페이스 활동에 대한 전체적인 보기를 제공합니다:

- 네임스페이스 이름, 유형 및 가시성을 표시하는 네임스페이스 메타데이터 패널입니다.
- 사용량 개수를 표시하는 단일 통계 패널 행입니다.

다음 표에는 그룹 및 프로젝트 네임스페이스의 리소스에 대한 사용 가능한 사용량 개수가 표시됩니다:

| 사용량 개수    | 시각화          | 그룹       | 프로젝트     |
|----------------|------------------------|-------------|-------------|
| 하위 그룹      | `groups_count`         | {{< yes >}} | {{< no >}}  |
| 프로젝트       | `projects_count`       | {{< yes >}} | {{< no >}}  |
| 사용자          | `users_count`          | {{< yes >}} | {{< no >}}  |
| 이슈         | `issues_count`         | {{< yes >}} | {{< yes >}} |
| 머지 리퀘스트 | `merge_requests_count` | {{< yes >}} | {{< yes >}} |
| 파이프라인      | `pipelines_count`      | {{< yes >}} | {{< yes >}} |

개요에 표시된 데이터는 배치 처리로 수집됩니다. GitLab은 데이터베이스에 각 하위 그룹의 레코드 개수를 저장한 다음 최상위 그룹의 메트릭을 제공하기 위해 레코드 개수를 집계합니다. 데이터는 월별로 월말 근처에 GitLab 시스템의 부하에 따라 최선의 노력 기준으로 집계됩니다.

자세한 내용은 [에픽 10417](https://gitlab.com/groups/gitlab-org/-/epics/10417#iterations-path)을 참조하세요.

### DevSecOps 메트릭 비교 {#devsecops-metrics-comparison}

{{< history >}}

- 프로젝트 수준의 기여자 개수 메트릭은 GitLab 18.0에서 GitLab.com에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/474119)되었습니다.
- DevSecOps 메트릭 비교 테이블은 GitLab 18.5에서 `ai_impact_table` 시각화로 [마이그레이션](https://gitlab.com/gitlab-org/gitlab/-/issues/541489)되었습니다.

{{< /history >}}

DevSecOps 메트릭 비교 패널은 그룹 또는 프로젝트의 지난 6개월 메트릭을 표시합니다. 이러한 시각화는 주요 DevSecOps 메트릭이 월별로 개선되는지 여부를 파악하는 데 도움이 됩니다. 가치 흐름 대시보드에는 3개의 DevSecOps 메트릭 비교 패널이 표시됩니다:

- 수명 주기 측정항목
- DORA 메트릭(Ultimate만 해당)
- 보안 메트릭(Ultimate만 해당, 최소 **개발자** 역할)

각 비교 패널에서 다음을 수행할 수 있습니다:

- 그룹, 프로젝트 및 팀 간의 성능을 한눈에 비교합니다.
- 가장 큰 가치 기여자, 뛰어난 성과자 또는 저성과자인 팀과 프로젝트를 식별합니다.
- 메트릭을 드릴다운하여 추가 분석을 수행합니다.

메트릭 위에 마우스를 올리면 메트릭 설명 및 관련 설명서 페이지 링크가 표시된 도구 설명이 표시됩니다.

**Change %** 열은 지난 6개월에 비해 이전 달의 메트릭 값의 백분율 증가 또는 감소를 나타냅니다.

**경향** 열은 시간 경과에 따른 메트릭 추세(예: 계절 변화)의 패턴을 식별하는 데 도움이 되는 스파크라인을 표시합니다. 스파크라인 색상은 파란색에서 초록색 범위이며, 초록색은 긍정적인 추세를 나타내고 파란색은 부정적인 추세를 나타냅니다.

### DORA Performers 점수 {#dora-performers-score}

{{< details >}}

- 티어:  Ultimate

{{< /details >}}

DORA Performers 점수 패널은 지난 전체 달력 월의 다양한 프로젝트 전체에서 조직의 DevOps 성능 수준 상태를 시각화하는 그룹 수준 막대 차트입니다.

![그룹의 DORA 메트릭 막대 차트](img/vsd_dora_performers_score_v17_7.png)

차트는 프로젝트의 DORA 점수를 [높음, 중간 또는 낮음으로 분류](https://cloud.google.com/blog/products/devops-sre/dora-2022-accelerate-state-of-devops-report-now-out)한 분석입니다. 차트는 그룹의 모든 하위 프로젝트를 집계합니다.

차트 막대는 월별로 계산된 점수 범주별 프로젝트의 총 개수를 표시합니다. 차트에서 데이터를 제외하려면(예: **포함되지 않음**) 범례에서 제외할 계열을 선택합니다. 각 막대 위에 마우스를 올리면 점수 정의를 설명하는 대화 상자가 표시됩니다.

예를 들어 프로젝트가 배포 빈도(속도)에 대해 높은 점수를 가지면 프로젝트가 하루에 프로덕션에 배포되는 경우가 하나 이상입니다.

| 메트릭                  | 높음 | 중간  | 낮음  | 설명 |
|-------------------------|------|---------|------|-------------|
| 배포 빈도    | ≥30  | 1-29    | <1  | 하루에 프로덕션에 배포되는 횟수 |
| 변경을 위한 리드 타임   | ≤7   | 8-29    | ≥30  | 커밋된 코드에서 프로덕션에서 성공적으로 실행되는 코드로 이동하는 데 걸리는 일 수 |
| 서비스 복구 시간 | ≤1   | 2-6     | ≥7   | 서비스 인시던트가 발생하거나 사용자에게 영향을 미치는 결함이 발생한 경우 서비스를 복원하는 데 걸리는 일 수 |
| 변경 실패율     | ≤15% | 16%-44% | ≥45% | 프로덕션에 대한 변경 사항 중 저하된 서비스가 발생한 백분율 |

자세히 알아보려면 [GitLab 가치 흐름 대시보드의 DORA Performers 점수 내부](https://about.gitlab.com/blog/inside-dora-performers-score-in-gitlab-value-streams-dashboard/) 블로그 게시물을 참조하세요.

#### 프로젝트 주제별 패널 필터링 {#filter-the-panel-by-project-topic}

YAML 구성으로 대시보드를 커스터마이징할 때 할당된 [주제](../project/project_topics.md)로 표시된 프로젝트를 필터링할 수 있습니다.

```yaml
panels:
  - title: 'My dora performers scores'
    visualization: dora_performers_score
    queryOverrides:
      namespace: group/my-custom-group
      filters:
        projectTopics:
          - JavaScript
          - Vue.js
```

여러 주제가 제공되면 프로젝트가 결과에 포함되려면 모든 주제가 일치해야 합니다.

### DORA 메트릭별 프로젝트 {#projects-by-dora-metric}

{{< details >}}

- 티어:  Ultimate

{{< /details >}}

{{< history >}}

- GitLab 17.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/408516)되었습니다.

{{< /history >}}

**Projects by DORA metric** 패널은 프로젝트 전체에서 조직의 DevOps 성능 수준 상태를 나열하는 그룹 수준 테이블입니다.

표에는 모든 프로젝트와 그들의 DORA 메트릭이 나열되며 그룹 및 하위 그룹의 하위 프로젝트에서 데이터를 집계합니다. 메트릭은 지난 전체 달력 월에 대해 집계됩니다.

메트릭 값으로 프로젝트를 정렬할 수 있으므로 높은 성과, 중간 성과 및 낮은 성과 프로젝트를 식별하는 데 도움이 됩니다. 추가 조사를 위해 프로젝트 이름을 선택하여 해당 프로젝트 페이지로 드릴다운할 수 있습니다.

![다양한 프로젝트의 DORA 메트릭이 포함된 표](img/vsd_projects_dora_metrics_v17_7.png)

## 개요 백그라운드 집계 활성화 또는 비활성화 {#enable-or-disable-overview-background-aggregation}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

가치 흐름 대시보드에 대한 개요 개수 집계를 활성화 또는 비활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다. 이 그룹은 최상위 수준이어야 합니다.
1. 왼쪽 사이드바에서 **설정** > **분석**을 선택합니다.
1. **가치 흐름 대시보드**에서 **가치 흐름 대시보드에 대한 개요 백그라운드 집계 활성화** 확인란을 선택하거나 선택 해제합니다.

그룹에서 집계된 사용량 개수를 검색하려면 [GraphQL API](../../api/graphql/reference/_index.md#groupvaluestreamdashboardusageoverview)를 사용합니다.

## 가치 흐름 대시보드 보기 {#view-the-value-streams-dashboard}

전제 조건:

- 그룹 또는 프로젝트에 대해 Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- 개요 백그라운드 집계를 활성화해야 합니다.
- 비교 패널에서 기여자 개수 메트릭을 보려면 [ClickHouse를 설정](../../integration/clickhouse.md)해야 합니다.
- 프로덕션에 배포를 추적하려면 그룹 또는 프로젝트에 [프로덕션 배포 티어](../../ci/environments/_index.md#deployment-tier-of-environments)의 환경이 있어야 합니다.
- 사이클 시간을 측정하려면 [커밋 메시지에서 이슈를 교차 연결](../project/issues/crosslinking_issues.md#from-commit-messages)해야 합니다.

### 그룹의 경우 {#for-groups}

그룹의 가치 흐름 대시보드를 보려면:

- 분석 대시보드에서:
  1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
  1. **분석** > **분석 대시보드**를 선택합니다.
- 가치 흐름 분석에서:
  1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
  1. **분석** > **가치 흐름 분석**을 선택합니다.
  1. **필터 결과** 텍스트 상자 아래의 **수명 주기 측정항목** 행에서 **Value Streams Dashboard / DORA**를 선택합니다.
  1. 선택 사항. 새 페이지를 열려면 이 경로 `/analytics/dashboards/value_streams_dashboard`를 그룹 URL에 추가합니다(예: `https://gitlab.com/groups/gitlab-org/-/analytics/dashboards/value_streams_dashboard`).

### 프로젝트의 경우 {#for-projects}

{{< history >}}

- GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137483)되었으며 [기능 플래그](../../administration/feature_flags/_index.md)는 `project_analytics_dashboard_dynamic_vsd`입니다. 기본적으로 비활성화되었습니다.
- 기능 플래그 `project_analytics_dashboard_dynamic_vsd`은 GitLab 17.5에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/441207)되었습니다.

{{< /history >}}

프로젝트의 분석 대시보드로 가치 흐름 대시보드를 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **분석** > **분석 대시보드**를 선택합니다.
1. 사용 가능한 대시보드 목록에서 **가치 흐름 대시보드**를 선택합니다.

## 보고서 예약 {#schedule-reports}

CI/CD 구성 요소 [가치 흐름 대시보드 예약 보고서 도구](https://gitlab.com/components/vsd-reports-generator)를 사용하여 보고서를 예약할 수 있습니다. 이 도구는 올바른 대시보드를 관련 데이터와 함께 수동으로 검색할 필요를 제거하여 시간과 노력을 절약하므로 인사이트 분석에 집중할 수 있습니다. 보고서를 예약하면 조직의 의사 결정자가 사전 예방적이고 시기 적절하며 관련성 있는 정보를 받도록 할 수 있습니다.

예약된 보고서 도구는 공개 GitLab GraphQL API를 통해 프로젝트 또는 그룹에서 메트릭을 수집한 다음 GitLab Flavored Markdown을 사용하여 보고서를 작성하고 지정된 프로젝트에서 이슈를 엽니다. 이슈에는 Markdown 형식의 비교 메트릭 테이블이 포함됩니다.

[예약된 보고서 예](https://gitlab.com/components/vsd-reports-generator#example-for-monthly-executive-value-streams-report)를 참조하세요. 자세히 알아보려면 [새로운 예약된 보고서 생성 도구가 가치 흐름 관리를 단순화합니다](https://about.gitlab.com/blog/new-scheduled-reports-generation-tool-simplifies-value-stream-management/) 블로그 게시물을 참조하세요.

## 대시보드 패널 커스터마이징 {#customize-dashboard-panels}

가치 흐름 대시보드를 커스터마이징하고 페이지에 포함할 하위 그룹 및 프로젝트를 구성할 수 있습니다.

페이지의 기본 콘텐츠를 커스터마이징하려면 선택한 프로젝트에서 YAML 구성 파일을 만들어야 합니다. 이 파일에서 제목, 설명 및 패널 수와 같은 다양한 설정 및 매개 변수를 정의할 수 있습니다. 파일은 스키마 기반이며 Git과 같은 버전 제어 시스템으로 관리됩니다. 이를 통해 구성 변경 기록을 추적 및 유지하고, 필요한 경우 이전 버전으로 복원하고, 팀 구성원과 효과적으로 협업할 수 있습니다. 쿼리 매개 변수를 사용하여 YAML 구성을 재정의할 수 있습니다.

대시보드 패널을 커스터마이징하기 전에 YAML 구성 파일을 저장할 프로젝트를 선택해야 합니다.

전제 조건:

- 그룹에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **분석**을 선택합니다.
1. YAML 구성 파일을 저장할 프로젝트를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

프로젝트를 설정한 후 구성 파일을 설정합니다:

1. 상단 바에서 **검색 또는 이동**을 선택하고 이전 단계에서 선택한 프로젝트를 찾습니다.
1. 기본 브랜치에서 구성 파일을 만듭니다: `.gitlab/analytics/dashboards/value_streams/value_streams.yaml`.
1. `value_streams.yaml` 구성 파일에서 구성 옵션을 입력합니다:

| 필드                                      | 설명 |
|--------------------------------------------|-------------|
| `title`                                    | 패널의 커스텀 이름 |
| `queryOverrides`(이전의 `data`)         | 각 시각화에 특정한 데이터 쿼리 매개 변수를 재정의합니다. |
| `namespace`(`queryOverrides`의 하위 필드) | 패널에 사용할 그룹 또는 프로젝트 경로 |
| `filters`(`queryOverrides`의 하위 필드)   | 지원되는 각 시각화 유형에 대한 쿼리를 필터링합니다. |
| `visualization`                            | 렌더링할 시각화의 유형입니다. 지원되는 옵션은 `ai_impact_table`, `dora_performers_score`, `namespace_metadata` 및 사용량 개수입니다. |
| `gridAttributes`                           | 패널의 크기 및 위치 지정 |
| `xPos`(`gridAttributes`의 하위 필드)      | 패널의 수평 위치 |
| `yPos`(`gridAttributes`의 하위 필드)      | 패널의 수직 위치 |
| `width`(`gridAttributes`의 하위 필드)     | 패널의 너비(최대 12) |
| `height`(`gridAttributes`의 하위 필드)    | 패널의 높이 |

```yaml
# version - The latest version of the analytics dashboard schema
version: '2'

# title - Change the title of the Value Streams Dashboard.
title: 'Custom Dashboard title'

# description - Change the description of the Value Streams Dashboard. [optional]
description: 'Custom description'

# panels - List of panels that contain panel settings.
#   title - Change the title of the panel.
#   visualization - The type of visualization to be rendered
#   gridAttributes - The size and positioning of the panel
#   queryOverrides.namespace - The Group or Project path to use for the chart panel
#   queryOverrides.filters.includeMetrics - Shows rows by metric ID in the table panel.
panels:
  - title: 'Group usage overview'
    visualization: namespace_metadata
    gridAttributes:
      yPos: 0
      xPos: 0
      height: 4
      width: 12
  - title: 'Groups'
    visualization: groups_count
    gridAttributes:
      yPos: 4
      xPos: 0
      height: 4
      width: 4
  - title: 'Issues'
    visualization: issues_count
    gridAttributes:
      yPos: 4
      xPos: 4
      height: 4
      width: 4
  - title: 'Merge requests'
    visualization: merge_requests_count
    gridAttributes:
      yPos: 4
      xPos: 8
      height: 4
      width: 4
  - title: 'Group dora and issue metrics'
    visualization: ai_impact_table
    queryOverrides:
      namespace: group
      filters:
        includeMetrics:
          - deployment_frequency
          - deploys
    gridAttributes:
      yPos: 8
      xPos: 0
      height: 12
      width: 12
  - title: 'My dora performers scores'
    visualization: dora_performers_score
    queryOverrides:
      namespace: group/my-project
      filters:
        projectTopics:
          - ruby
          - javascript
    gridAttributes:
      yPos: 20
      xPos: 0
      height: 12
      width: 12
```

### 지원되는 시각화 필터 {#supported-visualization-filters}

`filters` 하위 필드는 `queryOverrides` 필드에서 패널에 표시된 데이터를 커스터마이징하는 데 사용될 수 있습니다.

#### DevSecOps 메트릭 비교 패널 필터 {#devsecops-metrics-comparison-panel-filters}

`ai_impact_table` 시각화에 대한 필터입니다.

| 필터           | 설명                                                                       | 지원되는 값                          |
|------------------|-----------------------------------------------------------------------------------|-------------------------------------------|
| `includeMetrics` | 표 패널에서 메트릭 ID로 행을 표시합니다. `excludeMetrics`에 우선합니다. | [사용 가능한 메트릭](#dashboard-metrics-and-drill-down-reports)의 모든 `ID`. |
| `excludeMetrics` | 표 패널에서 메트릭 ID로 행을 숨깁니다.                                     | [사용 가능한 메트릭](#dashboard-metrics-and-drill-down-reports)의 모든 `ID`. |

#### DORA Performers 점수 패널 필터 {#dora-performers-score-panel-filters}

`dora_performers_score` 시각화에 대한 필터입니다.

| 필터          | 설명                                                                               | 지원되는 값 |
|-----------------|-------------------------------------------------------------------------------------------|------------------|
| `projectTopics` | 할당된 주제를 기반으로 표시된 프로젝트를 필터링합니다 | 사용 가능한 그룹 주제 |

#### 추가 패널 필터(더 이상 사용되지 않음) {#additional-panel-filters-deprecated}

##### DORA 차트 필터 {#dora-chart-filters}

> [!warning]
> `dora_chart` 시각화는 GitLab 18.5에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206417).

`dora_chart` 시각화에 대한 필터입니다.

| 필터   | 설명                                  | 지원되는 값 |
|----------|----------------------------------------------|------------------|
| `labels` | 레이블로 데이터를 필터링합니다                       | 사용 가능한 그룹 레이블. 레이블 필터링은 다음 메트릭에서 지원됩니다: `lead_time`, `cycle_time`, `issues`, `issues_completed`, `merge_request_throughput`, `median_time_to_merge`. |

##### 사용 현황 개요 필터 {#usage-overview-filters}

> [!warning]
> `usage_overview` 시각화는 GitLab 19.2에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/work_items/594892). 대신 `namespace_metadata` 시각화 및 사용량 개수 단일 통계를 사용합니다.

`usage_overview` 시각화에 대한 필터입니다.

그룹 및 하위 그룹 네임스페이스의 경우:

| 필터    | 설명                                                    | 지원되는 값 |
|-----------|----------------------------------------------------------------|------------------|
| `include` | 반환된 메트릭을 제한하며, 기본적으로 사용 가능한 모든 항목을 표시합니다 | `groups`, `projects`, `issues`, `merge_requests`, `pipelines`, `users` |

프로젝트 네임스페이스의 경우:

| 필터    | 설명                                                    | 지원되는 값 |
|-----------|----------------------------------------------------------------|------------------|
| `include` | 반환된 메트릭을 제한하며, 기본적으로 사용 가능한 모든 항목을 표시합니다 | `issues`, `merge_requests`, `pipelines` |

## 대시보드 메트릭 및 드릴다운 보고서 {#dashboard-metrics-and-drill-down-reports}

{{< history >}}

- Code Suggestions, Non-Agentic Chat 및 Root Cause Analysis 사용 메트릭은 GitLab 18.10에서 백분율 비율 대신 절대 사용자 수를 표시하도록 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/issues/589605)되었습니다.

{{< /history >}}

다음 표는 가치 흐름 대시보드에서 사용 가능한 메트릭의 개요, 설명 및 표시되는 드릴다운 보고서의 이름을 제공합니다.

| 메트릭                            | 설명                                                                                                          | 드릴다운 보고서 | ID |
|-----------------------------------|----------------------------------------------------------------------------------------------------------------------| ----------------- | -- |
| 배포 빈도              | 하루에 프로덕션에 배포되는 평균 횟수입니다. 이 메트릭은 가치가 최종 사용자에게 얼마나 자주 전달되는지 측정합니다. | **배포 빈도** 탭 | `deployment_frequency` |
| 변경을 위한 리드 타임             | 커밋을 프로덕션에 성공적으로 전달하는 데 걸리는 시간입니다. 이 메트릭은 CI/CD 파이프라인의 효율성을 반영합니다.   | **리드 타임** 탭 | `lead_time_for_changes` |
| 서비스 복구 시간           | 조직이 프로덕션의 장애에서 복구하는 데 걸리는 시간입니다.                                           | **서비스 복원 시간** 탭 | `time_to_restore_service` |
| 변경 실패율               | 프로덕션에서 인시던트를 발생시키는 배포의 백분율입니다.                                                      | **실패율 변경** 탭 | `change_failure_rate` |
| 리드 타임                         | 이슈 생성에서 이슈 종료까지의 중간값 시간입니다.                                                                      | 가치 흐름 분석 | `lead_time` |
| 사이클 시간                        | 연결된 이슈의 머지 리퀘스트의 가장 빠른 커밋에서 해당 이슈가 종료될 때까지의 중간값 시간입니다.                 | 가치 흐름 분석의 **수명 주기 측정항목** 섹션 | `cycle_time` |
| 생성된 이슈                    | 생성된 새 이슈의 개수입니다.                                                                                        | Issue analytics | `issues` |
| 종료된 이슈                     | 월별로 종료된 이슈의 개수입니다.                                                                                    | Issue analytics | `issues_completed` |
| 배포 개수                 | 프로덕션에 배포되는 총 횟수입니다.                                                                               | 머지 리퀘스트 분석 | `deploys` |
| 머지 리퀘스트 처리량          | 월별로 병합되는 머지 리퀘스트의 개수입니다.                                                                        | Productivity analytics | `merge_request_throughput` |
| 병합할 중간값 시간              | 머지 리퀘스트 생성과 머지 리퀘스트 병합 사이의 중간값 시간입니다.                                                  | Productivity analytics | `median_time_to_merge` |
| 기여자 개수                 | 그룹에 기여도가 있는 월간 고유 사용자의 개수입니다.                                                      | Contribution analytics | `contributor_count` |
| 시간 경과에 따른 중대한 취약성 | 프로젝트 또는 그룹의 시간 경과에 따른 중대한 취약성                                                               | 취약성 보고서 | `vulnerability_critical` |
| 시간 경과에 따른 높은 취약성    | 프로젝트 또는 그룹의 시간 경과에 따른 높은 취약성                                                                   | 취약성 보고서 | `vulnerability_high` |
| 총 파이프라인 실행               | 선택한 시간 기간에 실행된 파이프라인의 총 개수입니다.                                             | CI/CD analytics | `pipeline_count` |
| 파이프라인 중간값 기간          | 파이프라인이 완료되는 데 걸리는 중앙값 시간입니다.                                                                  | CI/CD analytics | `pipeline_duration_median` |
| 파이프라인 성공률             | 성공적으로 완료된 파이프라인의 백분율입니다.                                                             | CI/CD analytics | `pipeline_success_rate` |
| 파이프라인 실패율             | 실패한 파이프라인의 백분율입니다.                                                                             | CI/CD analytics | `pipeline_failed_rate` |
| 기능 사용                     | GitLab Duo 기능을 사용한 기여자의 개수입니다.                                                              |  | `duo_used_count` |
| 코드 제안 사용량            | 코드 제안을 사용한 사용자 수입니다.                                                                           |  | `code_suggestions_users_count` |
| Code Suggestions 승인률  | 생성된 총 Code Suggestions 중 승인된 Code Suggestions입니다.                                                   |  | `code_suggestions_acceptance_rate` |
| Non-Agentic Chat 사용          | Non-Agentic Chat을 사용한 사용자 수입니다.                                                                     |  | `duo_chat_users_count` |
| 근본 원인 분석 사용량         | Root Cause Analysis를 사용한 사용자 수입니다.                                                                        |  | `duo_rca_users_count` |

## Jira와의 메트릭 {#metrics-with-jira}

다음 메트릭은 Jira 사용에 의존하지 않습니다:

- DORA 배포 빈도
- DORA 변경 리드 타임
- 배포 개수
- 머지 리퀘스트 처리량
- 병합할 중간값 시간
- 취약성
