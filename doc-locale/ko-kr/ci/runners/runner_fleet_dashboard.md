---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 관리자를 위한 러너 플릿 대시보드
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.6에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/424495)

{{< /history >}}

GitLab 관리자는 러너 플릿 대시보드를 사용하여 인스턴스 러너의 상태를 평가할 수 있습니다. 러너 플릿 대시보드는 다음을 표시합니다:

- 러너 인프라로 인한 최근 CI 오류
- 가장 바쁜 러너에서 실행되는 동시 작업의 수
- 인스턴스 러너가 사용한 컴퓨팅 분
- 작업 큐 대기 시간

![러너 플릿 대시보드에 상태, 사용량 및 성능 메트릭이 표시됩니다.](img/runner_fleet_dashboard_v17_1.png)

## 대시보드 메트릭 {#dashboard-metrics}

{{< history >}}

- [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/11180) 메트릭, **Runner usage** 및 **Wait time to pick up job**, GitLab 16.7의 [실험](../../policy/development_stages_support.md#experiment)으로 [플래그](../../administration/feature_flags/_index.md) `ci_data_ingestion_to_click_house` 및 `clickhouse_ci_analytics`를 사용하여 명명됨. 기본적으로 비활성화되어 있습니다.
- **Runner usage** 및 **Wait time to pick up job** 메트릭이 GitLab 17.1에서 [베타](../../policy/development_stages_support.md#beta)로 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/424789).

{{< /history >}}

러너 플릿 대시보드에서 다음 메트릭을 사용할 수 있습니다:

> [!note]
> **Runner usage** 및 **작업을 선택하기 위해 대기 시간** 메트릭을 보려면 [ClickHouse 통합](../../integration/clickhouse.md)을 구성해야 합니다.
>
> <i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [ClickHouse를 사용하여 러너 플릿 대시보드 설정](https://www.youtube.com/watch?v=YpGV95Ctbpk)을 참조하세요.
> <!-- Video published on 2023-12-19 -->

| 메트릭                        | 설명 |
|-------------------------------|-------------|
| 온라인                        | 전체 인스턴스에서 온라인 상태인 러너의 수입니다. |
| 오프라인                       | 현재 오프라인 상태인 러너의 수입니다. 등록되었지만 GitLab에 연결된 적이 없는 러너는 이 수에 포함되지 않습니다. |
| 활성 러너                | 현재 활성 상태인 러너의 총 수입니다. |
| Runner 사용량(이전 달)<sup>1</sup> | **Requires ClickHouse**: 이전 달에 각 프로젝트 또는 그룹 러너에서 사용한 총 컴퓨팅 분입니다. 이 데이터를 CSV 파일로 내보내 비용을 분석할 수 있습니다. |
| 작업을 선택하기 위해 대기 시간<sup>1</sup>       | **Requires ClickHouse**: 러너가 선택할 때까지 작업이 큐에서 대기하는 평균 시간입니다. 이 메트릭은 러너가 조직의 목표 서비스 수준 목표(SLO)의 CI/CD 작업 큐를 처리할 수 있는지 여부에 대한 통찰력을 제공합니다. 이 데이터는 24시간마다 업데이트됩니다. |

**각주**:

1. 이 기능은 [베타](../../policy/development_stages_support.md#beta) 상태이며 예고 없이 변경될 수 있습니다. 자세한 내용은 [에픽 11180](https://gitlab.com/groups/gitlab-org/-/epics/11180)을 참조하세요.

## 러너 플릿 대시보드 보기 {#view-the-runner-fleet-dashboard}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.
- **Runner usage** 및 **작업을 선택하기 위해 대기 시간** 메트릭을 보려면 [ClickHouse 통합](../../integration/clickhouse.md)을 구성해야 합니다.

러너 플릿 대시보드를 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. **플릿 대시보드**를 선택합니다.

## 인스턴스 러너가 사용한 컴퓨팅 분 내보내기 {#export-compute-minutes-used-by-instance-runners}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.
- [ClickHouse 통합](../../integration/clickhouse.md)을 구성해야 합니다.

러너 사용량을 분석하기 위해 작업의 수와 실행된 러너 분을 포함하는 CSV 파일을 내보낼 수 있습니다. CSV 파일은 각 프로젝트의 러너 유형과 작업 상태를 표시합니다. 내보내기가 완료되면 CSV가 이메일로 전송됩니다.

인스턴스 러너가 사용한 컴퓨팅 분을 내보내려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. **플릿 대시보드**를 선택합니다.
1. **Export CSV**를 선택합니다.

## 피드백 {#feedback}

러너 플릿 대시보드를 개선하는 데 도움을 주시려면 [이슈 421737](https://gitlab.com/gitlab-org/gitlab/-/issues/421737)에서 피드백을 제공할 수 있습니다. 특히:

- 대시보드가 작동하도록 GitLab을 설정하기가 얼마나 쉽거나 어려웠는지
- 대시보드가 얼마나 유용했는지
- 해당 대시보드에 표시되길 원하는 다른 정보가 무엇인지
- 기타 관련 생각과 아이디어
