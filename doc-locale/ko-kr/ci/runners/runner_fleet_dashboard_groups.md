---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹용 러너 플릿 대시보드
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 17.0에서 `runners_dashboard_for_groups` [플래그](../../administration/feature_flags/_index.md)로 [베타](../../policy/development_stages_support.md#beta)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151640)되었습니다. 기본적으로 비활성화되어 있습니다.
- 기능 플래그 `runners_dashboard_for_groups` [GitLab 17.2에서 제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/459052).

{{< /history >}}

그룹의 유지 관리자 또는 소유자 역할을 가진 사용자는 러너 플릿 대시보드를 사용하여 그룹 러너의 상태를 평가할 수 있습니다.

![그룹용 러너 플릿 대시보드](img/runner_fleet_dashboard_groups_v17_1.png)

## 대시보드 메트릭 {#dashboard-metrics}

러너 플릿 대시보드에서 사용 가능한 메트릭은 다음과 같습니다:

| 메트릭                        | 설명 |
|-------------------------------|-------------|
| 온라인                        | 온라인 러너 수입니다. **운영자** 영역에서 이 메트릭은 전체 인스턴스의 러너 수를 표시합니다. 그룹에서 이 메트릭은 그룹 및 해당 하위 그룹의 러너 수를 표시합니다. |
| 오프라인                       | 오프라인 러너 수입니다. |
| 활성 러너                | 활성 러너 수입니다. |
| 러너 사용률(지난 달)<sup>1</sup> | 그룹 러너에서 각 프로젝트가 사용한 컴퓨팅 분(분)의 수입니다. 비용 분석을 위해 CSV로 내보내는 옵션이 포함됩니다. |
| 작업을 선택하기 위해 대기 시간<sup>1</sup>       | 러너의 평균 대기 시간을 표시합니다. 이 메트릭은 러너가 조직의 목표 서비스 수준 목표에서 CI/CD 작업 대기열을 처리할 수 있는지 여부에 대한 인사이트를 제공합니다. 이 메트릭 위젯을 만드는 데이터는 24시간마다 업데이트됩니다. |

**각주**:

1. GitLab Self-Managed의 경우, **Runner usage** 및 **작업을 선택하기 위해 대기 시간** 메트릭을 보려면 [ClickHouse 통합](../../integration/clickhouse.md)을 구성해야 합니다.

## 그룹용 러너 플릿 대시보드 보기 {#view-the-runner-fleet-dashboard-for-groups}

전제 조건:

- 그룹에 대한 유지 관리자 역할이 있어야 합니다.
- GitLab Self-Managed의 경우, **Runner usage** 및 **작업을 선택하기 위해 대기 시간** 메트릭을 보려면 [ClickHouse 통합](../../integration/clickhouse.md)을 구성하세요.

그룹용 러너 플릿 대시보드를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **러너**를 선택합니다.
1. **플릿 대시보드**를 선택합니다.
