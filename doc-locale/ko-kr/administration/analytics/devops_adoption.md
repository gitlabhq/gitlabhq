---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab 인스턴스에서 DevSecOps 채택을 모니터링하고, 기능 사용을 추적하며, 팀 성과에 대한 인사이트를 확인합니다."
title: 인스턴스별 DevOps 채택
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

DevOps 채택을(를) 사용하면 개발, 보안, 운영 기능의 전체 인스턴스 채택 현황과 DevOps 점수를 확인할 수 있습니다.

이 기능에 대한 자세한 정보는 [DevOps adoption by group](../../user/group/devops_adoption/_index.md)을(를) 참조하세요.

## DevOps 점수 {#devops-score}

> [!note]
> DevOps 점수를 확인하려면 GitLab 인스턴스의 [Service Ping](../settings/usage_statistics.md#service-ping)을(를) 활성화해야 합니다. DevOps 점수는 비교 도구이므로 점수 데이터는 먼저 GitLab Inc.에서 중앙으로 처리되어야 합니다. Service Ping이 활성화되지 않으면 DevOps 점수 값은 0입니다.

DevOps 점수를 사용하여 DevOps 상태를 다른 조직과 비교할 수 있습니다.

**DevOps 점수**는 지난 30일 동안 인스턴스의 주요 GitLab 기능 사용량을 표시하며, 해당 기간의 청구 가능 사용자 수로 평균화됩니다.

- **내 점수**는 기능 점수의 평균을 나타냅니다.
- **내 사용량**은 지난 30일 동안 청구 가능 사용자당 기능의 평균 사용량을 나타냅니다.
- **리더 사용량**은 GitLab에서 수집한 [Service Ping data](../settings/usage_statistics.md#service-ping)를 기반으로 상위 성능 인스턴스에서 계산됩니다.

Service Ping 데이터는 분석을 위해 GitLab 서버에서 집계됩니다. 사용자의 사용 정보는 **not sent**. GitLab 사용을 시작했을 때는 이 기능을 사용할 수 있기 전에 데이터가 수집되는 데 몇 주가 걸릴 수 있습니다.

## DevOps 채택 확인 {#view-devops-adoption}

전제 조건:

- 운영자 액세스

인스턴스의 DevOps 채택을 확인하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **분석** > **DevOps 채택**을(를) 선택합니다.

## 그룹을 DevOps 채택에 추가 {#add-a-group-to-devops-adoption}

전제 조건:

- 그룹에 대해 기자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

그룹을 DevOps 채택에 추가하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **분석** > **DevOps 채택**을(를) 선택합니다.
1. **그룹 추가 또는 제거** 드롭다운 목록에서 추가할 그룹을 선택합니다.

## DevOps 채택에서 그룹 제거 {#remove-a-group-from-devops-adoption}

전제 조건:

- 그룹에 대해 기자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

DevOps 채택에서 그룹을 제거하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **분석** > **DevOps 채택**을(를) 선택합니다.
1. 다음 중 하나를 선택합니다:

- **그룹 추가 또는 제거** 드롭다운 목록에서 제거할 그룹을 선택 해제합니다.
- **그룹별 채택** 테이블에서 제거할 그룹의 행에서 **Remove Group from the table** ({{< icon name="remove" >}})를 선택합니다.
