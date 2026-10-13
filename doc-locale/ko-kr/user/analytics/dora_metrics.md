---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: DevOps 성능에 대한 인사이트를 확보하고 워크플로우 개선 기회를 식별합니다.
title: DevOps Research and Assessment (DORA) 메트릭
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[DevOps Research and Assessment (DORA)](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance) 메트릭은 DevOps 성능에 대한 증거 기반 인사이트를 제공합니다. 이 네 가지 핵심 측정을 통해 팀이 얼마나 빠르게 변경 사항을 전달하고 프로덕션 환경에서 얼마나 잘 작동하는지를 파악할 수 있습니다. DORA 메트릭을 지속적으로 추적하면 소프트웨어 전달 프로세스 전반에서 개선 기회를 강조합니다.

전략적 의사결정을 위해 DORA 메트릭을 사용하거나, 이해관계자에게 프로세스 개선 투자의 정당성을 입증하거나, 팀의 성능을 업계 벤치마크와 비교하여 경쟁 우위를 식별할 수 있습니다.

네 가지 DORA 메트릭은 DevOps의 두 가지 중요한 측면을 측정합니다:

- **Velocity metrics**은 조직이 소프트웨어를 얼마나 빠르게 전달하는지 추적합니다:
  - [배포 빈도](#deployment-frequency): 코드가 프로덕션에 배포되는 빈도
  - [변경을 위한 리드 타임](#lead-time-for-changes): 코드가 프로덕션에 도달하는 데 걸리는 시간
- **Stability metrics**은 소프트웨어의 신뢰성을 측정합니다:
  - [변경 실패율](#change-failure-rate): 배포가 프로덕션 장애를 유발하는 빈도
  - [서비스 복구 시간](#time-to-restore-service): 장애 후 서비스가 복구되는 속도

속도 및 안정성 메트릭에 대한 이중 초점은 리더가 배포 워크플로우에서 속도와 품질 간의 최적의 균형을 찾을 수 있도록 도움을 줍니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 비디오 설명을 보려면 [DORA 메트릭: 사용자 분석](https://www.youtube.com/watch?v=jYQSH4EY6_U) 및 [GitLab 속도 실행: DORA 메트릭](https://www.youtube.com/watch?v=1BrcMV6rCDw).

## 배포 빈도 {#deployment-frequency}

배포 빈도는 주어진 날짜 범위(시간, 일, 주, 월 또는 연 단위)에서 프로덕션에 대한 성공적인 배포의 빈도입니다.

소프트웨어 리더는 배포 빈도 메트릭을 사용하여 팀이 프로덕션에 소프트웨어를 얼마나 자주 성공적으로 배포하는지, 그리고 팀이 고객의 요청이나 새로운 시장 기회에 얼마나 빠르게 대응할 수 있는지를 파악할 수 있습니다. 배포 빈도가 높을수록 더 빨리 피드백을 받을 수 있으며, 개선 사항과 기능을 더 빠르게 반복하여 제공할 수 있습니다.

### 배포 빈도를 계산하는 방법 {#how-deployment-frequency-is-calculated}

GitLab에서 배포 빈도는 배포의 종료 시간(해당 `finished_at` 속성)을 기반으로 주어진 환경으로의 일일 평균 배포 수로 측정됩니다. GitLab은 주어진 날짜에 완료된 배포의 수로부터 배포 빈도를 계산합니다. 성공적인 배포(`Deployment.statuses = success`)만 계산됩니다.

계산은 프로덕션 `environment tier` 또는 `production/prod`라고 명명된 환경을 고려합니다. 환경은 프로덕션 배포 계층의 일부여야 배포 정보가 그래프에 표시됩니다.

`other`을(를) `environment_tiers` 매개변수 아래에 지정하여 DORA 메트릭을 다양한 환경에 대해 구성할 수 있습니다([`.gitlab/insights.yml` 파일](../project/insights/_index.md#configuration) 참조).

> [!note]
> 배포 빈도는 **average (mean)**으로 계산되며, 성능의 더 정확하고 신뢰할 수 있는 보기를 제공하는 중앙값을 사용하는 다른 DORA 메트릭과 달리 계산됩니다. 배포 빈도가 DORA 프레임워크를 채택하기 전에 GitLab에 추가되었으며, 이 메트릭의 계산은 다른 보고서에 포함될 때 변경되지 않았기 때문입니다. [이슈 499591](https://gitlab.com/gitlab-org/gitlab/-/issues/499591)은 각 메트릭에 대한 계산 방법을 사용자 지정하는 옵션을 제공하여 산술평균과 중앙값 중에서 선택할 수 있도록 제안합니다.

### 배포 빈도를 개선하는 방법 {#how-to-improve-deployment-frequency}

첫 번째 단계는 그룹과 프로젝트 간의 코드 릴리스 속도를 벤치마킹하는 것입니다. 다음으로 고려해야 할 사항:

- 자동 테스트를 추가합니다.
- 자동 코드 검증을 추가합니다.
- 변경 사항을 더 작은 반복으로 분할합니다.

## 변경을 위한 리드 타임 {#lead-time-for-changes}

변경을 위한 리드 타임은(는) 코드 변경이 프로덕션에 도달하는 데 걸리는 시간입니다.

**변경을 위한 리드 타임**은(는) **리드 타임**과(와) 같지 않습니다. 가치 흐름 분석에서 리드 타임은 이슈에 대한 작업이 요청된 순간(이슈 생성)에서 이행되고 전달된 순간(이슈 종료)까지 이동하는 데 걸리는 시간을 측정합니다.

소프트웨어 리더에게 변경을 위한 리드 타임은 CI/CD 파이프라인의 효율성을 반영하고 작업이 고객에게 얼마나 빠르게 전달되는지 시각화합니다. 시간이 지남에 따라 변경을 위한 리드 타임은 감소해야 하고, 팀의 성능은 증가해야 합니다. 변경을 위한 리드 타임이 낮을수록 더 효율적인 CI/CD 파이프라인을 의미합니다.

### 변경을 위한 리드 타임을 계산하는 방법 {#how-lead-time-for-changes-is-calculated}

GitLab은 머지 리퀘스트를 프로덕션에 성공적으로 전달하는 데 걸리는 초 단위 시간을 기반으로 변경을 위한 리드 타임을 계산합니다: 머지 리퀘스트 병합 시간(병합 버튼을 클릭한 시간)부터 프로덕션에서 코드가 성공적으로 실행되는 시간까지, `coding_time`을(를) 계산에 추가하지 않습니다. 데이터는 배포가 완료된 직후에 약간의 지연과 함께 집계됩니다.

기본적으로 변경을 위한 리드 타임은 여러 배포 작업을 사용한 단일 브랜치 작업만 측정할 수 있습니다(예: 기본 브랜치의 개발에서 스테이징까지, 프로덕션까지). 머지 리퀘스트가 스테이징에서 병합된 후 프로덕션에서 병합되면 GitLab은 이를 하나가 아닌 두 개의 배포된 머지 리퀘스트로 해석합니다.

#### 병합 전에 배포가 완료되는 경우 {#deployments-finishing-before-merge}

드문 경우이지만, 배포가 연결된 머지 리퀘스트가 병합되기 전에 완료될 수 있습니다.

이 시나리오는 다음과 같은 경우 발생할 수 있습니다:

- 배포 프로세스가 병합 워크플로우와 독립적으로 트리거됩니다.
- 코드 검토가 완료되기 전에 수동 배포 개입이 발생합니다.

이 상황에서 GitLab은 다음 공식을 사용합니다: `GREATEST(0, deployment_finished_at - merge_request_merged_at)`. `GREATEST` 함수는 음수 값 대신 `0`을(를) 반환하여 리드 타임 값이 음수가 되지 않도록 합니다. 이 함수는 데이터 무결성을 유지하면서 데이터베이스 제약 조건 위반을 방지합니다.

### 변경을 위한 리드 타임을 개선하는 방법 {#how-to-improve-lead-time-for-changes}

첫 번째 단계는 그룹과 프로젝트 간의 CI/CD 파이프라인 효율성을 벤치마킹하는 것입니다. 다음으로 고려해야 할 사항:

- 가치 흐름 분석을 사용하여 프로세스의 병목 현상을 식별합니다.
- 변경 사항을 더 작은 반복으로 분할합니다.
- 자동화를 추가합니다.
- 파이프라인의 성능을 개선합니다.

## 서비스 복구 시간 {#time-to-restore-service}

서비스 복구 시간은 조직이 프로덕션의 장애에서 복구하는 데 걸리는 시간입니다.

소프트웨어 리더에게 서비스 복구 시간은 조직이 프로덕션의 장애에서 복구하는 데 걸리는 시간을 반영합니다. 서비스 복구 시간이 낮을수록 조직이 경쟁 우위를 확보하고 비즈니스 성과를 증대하기 위해 새로운 혁신적인 기능으로 위험을 감수할 수 있습니다.

### 서비스 복구 시간을 계산하는 방법 {#how-time-to-restore-service-is-calculated}

GitLab에서 서비스 복구 시간은 프로덕션 환경에서 이슈가 열려 있던 중앙값 시간으로 측정됩니다. GitLab은 주어진 기간에 프로덕션 환경에서 이슈가 열려 있던 초 단위 시간의 수를 계산합니다. 다음을 가정합니다:

- [GitLab 이슈](../../operations/incident_management/incidents.md)가 추적됩니다.
- 모든 이슈는 프로덕션 환경과 관련이 있습니다.
- 이슈와 배포는 엄격하게 일대일 관계를 갖습니다. 한 이슈는 하나의 프로덕션 배포와만 관련이 있으며, 모든 프로덕션 배포는 최대 하나의 이슈와 관련이 있습니다.

### 서비스 복구 시간을 개선하는 방법 {#how-to-improve-time-to-restore-service}

첫 번째 단계는 그룹과 프로젝트 간의 팀 대응 및 서비스 중단 및 중단으로부터의 복구를 벤치마킹하는 것입니다. 다음으로 고려해야 할 사항:

- 프로덕션 환경의 관찰성을 개선합니다.
- 응답 워크플로우를 개선합니다.
- 배포 빈도 및 변경을 위한 리드 타임을 개선하여 수정 사항이 프로덕션에 더 효율적으로 도달할 수 있도록 합니다.

## 변경 실패율 {#change-failure-rate}

변경 실패율은 변경으로 인해 프로덕션의 장애가 발생하는 빈도입니다.

소프트웨어 리더는 변경 실패율 메트릭을 사용하여 배포되는 코드의 품질에 대한 인사이트를 얻을 수 있습니다. 변경 실패율이 높을수록 배포 프로세스가 비효율적이거나 자동 테스트 적용 범위가 부족함을 나타낼 수 있습니다.

### 변경 실패율을 계산하는 방법 {#how-change-failure-rate-is-calculated}

GitLab에서 변경 실패율은 주어진 기간에 프로덕션에서 이슈를 유발하는 배포의 백분율로 측정됩니다. GitLab은 변경 실패율을 프로덕션 환경으로의 배포 수로 나눈 이슈 수로 계산합니다. 다음을 가정합니다:

- [GitLab 이슈](../../operations/incident_management/incidents.md)가 추적됩니다.
- 모든 이슈는 환경과 상관없이 프로덕션 이슈입니다.
- 변경 실패율은 주로 고급 안정성 추적으로 사용되며, 이것이 주어진 날에 모든 이슈와 배포가 결합된 일일 비율로 집계되는 이유입니다. 배포와 이슈 간의 특정 관계를 추가하는 것은 [이슈 444295](https://gitlab.com/gitlab-org/gitlab/-/issues/444295)에서 제안됩니다.
- 변경 실패율은 중복된 이슈를 별도의 항목으로 계산하므로 이중 계산이 발생합니다. [이슈 480920](https://gitlab.com/gitlab-org/gitlab/-/issues/480920)은(는) 더 정확한 계산을 위한 솔루션을 제안합니다.

예를 들어 하루에 10번의 배포(하루에 1번의 배포로 간주)가 있고 첫날에 2개의 이슈가 있고 마지막 날에 1개의 이슈가 있다면 변경 실패율은 0.3입니다.

### 변경 실패율을 개선하는 방법 {#how-to-improve-change-failure-rate}

첫 번째 단계는 그룹과 프로젝트 간의 품질 및 안정성을 벤치마킹하는 것입니다. 다음으로 고려해야 할 사항:

- 안정성과 처리량(배포 빈도 및 변경을 위한 리드 타임) 간의 올바른 균형을 찾아 속도를 위해 품질을 희생하지 않습니다.
- 코드 검토 프로세스의 효과를 개선합니다.
- 자동 테스트를 추가합니다.

## DORA 사용자 지정 계산 규칙 {#dora-custom-calculation-rules}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- [GitLab 15.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96561) [기능 플래그](../../administration/feature_flags/_index.md) 이름은 `dora_configuration`입니다. 기본적으로 비활성화되었습니다. 이 기능은 [실험](../../policy/development_stages_support.md)입니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능 여부는 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

이 기능은 [실험](../../policy/development_stages_support.md)입니다. 이 기능을 테스트하는 사용자 목록에 참여하려면 [여기에서 제안된 테스트 흐름](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96561#steps-to-check-on-localhost)을 확인하세요. 버그를 발견했다면 [여기에서 이슈를 열어주세요](https://gitlab.com/groups/gitlab-org/-/epics/11490). 사용 사례와 피드백을 공유하려면 [에픽 11490](https://gitlab.com/groups/gitlab-org/-/epics/11490)에 댓글을 달아주세요.

### 변경을 위한 리드 타임에 대한 다중 브랜치 규칙 {#multi-branch-rule-for-lead-time-for-changes}

기본 [변경을 위한 리드 타임 계산](#how-lead-time-for-changes-is-calculated)과(와) 달리, 이 계산 규칙을 사용하면 각 작업에 대해 단일 배포 작업을 사용한 다중 브랜치 작업을 측정할 수 있습니다. 예를 들어 개발 브랜치의 개발 작업에서 스테이징 브랜치의 스테이징 작업까지, 프로덕션 브랜치의 프로덕션 작업까지.

이 계산 규칙은 개발 흐름의 일부인 대상 브랜치를 사용하여 `dora_configurations` 테이블을 업데이트하여 구현되었습니다. 이러한 방식으로 GitLab은 브랜치를 하나로 인식하고 다른 머지 리퀘스트를 필터링할 수 있습니다.

이 구성은 선택한 프로젝트의 일일 DORA 메트릭 계산 방식을 변경하지만 다른 프로젝트, 그룹 또는 사용자에게는 영향을 미치지 않습니다.

이 기능은 프로젝트 수준의 전파만 지원합니다.

이를 수행하려면 Rails 콘솔에서 다음 명령을 실행하세요:

```ruby
my_project = Project.find_by_full_path('group/subgroup/project')
Dora::Configuration.create!(project: my_project, branches_for_lead_time_for_changes: ['master', 'main'])
```

기존 구성을 업데이트하려면 다음 명령을 실행하세요:

```ruby
my_project = Project.find_by_full_path('group/subgroup/project')
record = Dora::Configuration.where(project: my_project).first
record.branches_for_lead_time_for_changes = ['development', 'staging', 'master', 'main']
record.save!
```

## DORA 메트릭 측정 {#measure-dora-metrics}

### GitLab CI/CD 파이프라인을 사용하지 않고 {#without-using-gitlab-cicd-pipelines}

배포 빈도는 일반적인 푸시 기반 배포를 위해 생성되는 배포 레코드를 기반으로 계산됩니다. 이러한 배포 레코드는 예를 들어 컨테이너 이미지가 에이전트와 함께 GitLab에 연결된 경우와 같이 풀 기반 배포를 위해 생성되지 않습니다.

이러한 경우 DORA 메트릭을 추적하려면 배포 API를 사용하여 [배포 레코드를 생성](../../api/deployments.md#create-a-deployment)할 수 있습니다. 배포 계층이 구성된 환경 이름을 설정해야 합니다. 배포 계층 변수는 배포가 아닌 지정된 환경에 대해 지정되기 때문입니다. 자세한 내용을 보려면 [외부 배포 도구의 배포 추적](../../ci/environments/external_deployment_tools.md) 방법을 참조하세요.

### Jira 사용 {#with-jira}

- 배포 빈도 및 변경을 위한 리드 타임은 GitLab CI/CD 및 머지 리퀘스트(MR)를 기반으로 계산되며 Jira 데이터가 필요하지 않습니다.
- 서비스 복구 시간 및 변경 실패율은 계산을 위해 [GitLab 이슈](../../operations/incident_management/manage_incidents.md)를 필요로 합니다. 자세한 내용을 보려면 이러한 메트릭을 [외부 이슈 사용](#with-external-incidents) 방법과 [Jira 이슈 복제자 가이드](https://gitlab.com/smathur/jira-incident-replicator)를 참조하세요.

### 외부 이슈 사용 {#with-external-incidents}

이슈 관리를 위해 서비스 복구 시간 및 변경 실패율을 측정할 수 있습니다.

PagerDuty의 경우 [웹후크 설정](../../operations/incident_management/manage_incidents.md#using-the-pagerduty-webhook)을(를) 통해 각 PagerDuty 이슈에 대해 GitLab 이슈를 자동으로 생성할 수 있습니다. 이 구성을 사용하려면 PagerDuty와 GitLab 모두에서 변경해야 합니다.

다른 이슈 관리 도구의 경우 [HTTP 통합](../../operations/incident_management/integrations.md#alerting-endpoints)을(를) 설정하여 다음을 자동으로 수행하는 데 사용할 수 있습니다:

1. [경고가 트리거될 때 이슈 생성](../../operations/incident_management/manage_incidents.md#automatically-when-an-alert-is-triggered).
1. [복구 경고를 통해 이슈 종료](../../operations/incident_management/manage_incidents.md#automatically-close-incidents-via-recovery-alerts).

## 분석 기능 {#analytics-features}

DORA 메트릭은 다음 분석 기능에 표시됩니다:

- [가치 흐름 대시보드](value_streams_dashboard.md)는 [DORA 메트릭 비교 패널](value_streams_dashboard.md#devsecops-metrics-comparison)과 [DORA 성능자 점수 패널](value_streams_dashboard.md#dora-performers-score)을(를) 포함합니다.
- [CI/CD 분석 차트](ci_cd_analytics.md)는 시간에 따른 DORA 메트릭의 히스토리를 보여줍니다.
- [인사이트 보고서](../project/insights/_index.md)는 [DORA 쿼리 매개변수](../project/insights/_index.md#dora-query-parameters)를 사용하여 사용자 지정 차트를 만드는 옵션을 제공합니다.
- [GraphQL API](../../api/graphql/reference/_index.md)(대화형 [GraphQL 탐색기](../../api/graphql/_index.md#interactive-graphql-explorer) 포함)과 [REST API](../../api/dora/metrics.md)는 메트릭 데이터 검색을 지원합니다.

## 프로젝트 및 그룹 가용성 {#project-and-group-availability}

다음 표는 프로젝트 및 그룹에서 DORA 메트릭 가용성의 개요를 제공합니다.

| 메트릭                    | 수준             | 댓글 |
|---------------------------|-------------------|----------|
| `deployment_frequency`    | 프로젝트           | 배포 수 단위입니다. |
| `deployment_frequency`    | 그룹             | 배포 수 단위입니다. 집계 방법은 평균입니다.  |
| `lead_time_for_changes`   | 프로젝트           | 초 단위입니다. 집계 방법은 중앙값입니다. |
| `lead_time_for_changes`   | 그룹             | 초 단위입니다. 집계 방법은 중앙값입니다. |
| `time_to_restore_service` | 프로젝트 및 그룹 | 일 단위입니다. 집계 방법은 중앙값입니다. |
| `change_failure_rate`     | 프로젝트 및 그룹 | 배포의 백분율입니다. |

## 데이터 집계 {#data-aggregation}

다음 표는 다양한 차트에서 DORA 메트릭 데이터 집계의 개요를 제공합니다.

| 메트릭 이름 | 측정된 값 | [가치 흐름 대시보드](value_streams_dashboard.md)의 데이터 집계 | [CI/CD 분석 차트](ci_cd_analytics.md)의 데이터 집계 | [사용자 지정 인사이트 보고](../project/insights/_index.md#dora-query-parameters)의 데이터 집계 |
|---------------------------|-------------------|-----------------------------------------------------|------------------------|----------|
| 배포 빈도 | 성공적인 배포의 수 | 월당 일일 평균 | 일일 평균 | `day`(기본값) 또는 `month` |
| 변경을 위한 리드 타임 | 프로덕션으로 커밋을 성공적으로 전달하는 데 걸리는 초 수 | 월당 일일 중앙값 | 중앙값 시간 |  `day`(기본값) 또는 `month` |
| 서비스 복구 시간 | 이슈가 열려 있던 초 수           | 월당 일일 중앙값 | 일일 중앙값 | `day`(기본값) 또는 `month` |
| 변경 실패율 | 프로덕션에서 이슈를 유발하는 배포의 백분율 | 월당 일일 중앙값 | 실패한 배포의 백분율 | `day`(기본값) 또는 `month` |
