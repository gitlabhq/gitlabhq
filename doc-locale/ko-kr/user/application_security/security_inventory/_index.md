---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보안 인벤토리
description: "자산, 스캐너 범위 및 취약성의 그룹 수준 가시성입니다."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [도입되었으며](https://gitlab.com/groups/gitlab-org/-/epics/16484) [베타](../../../policy/development_stages_support.md)는 GitLab 18.2에서 `security_inventory_dashboard` 플래그를 사용했습니다. 기본적으로 사용으로 설정됩니다.
- GitLab 18.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/588619)하게 되었습니다. `security_inventory_dashboard` 기능 플래그가 제거되었습니다.
- 취약성 개수가 GitLab 19.2에서 [변경되어](https://gitlab.com/gitlab-org/gitlab/-/work_items/600455) 더 이상 감지되지 않는 취약성을 제외하고, 보안 인벤토리와 보안 대시보드를 일치시킵니다.

{{< /history >}}

보안 인벤토리를 사용하여 보안을 유지해야 할 자산을 시각화하고 보안을 개선하기 위해 취해야 할 조치를 이해합니다. 보안의 일반적인 표현은 "볼 수 없는 것은 보안을 유지할 수 없다"입니다. 보안 인벤토리는 조직의 최상위 그룹의 보안 태세에 대한 가시성을 제공하고, 범위 격차를 식별하는 데 도움을 주며, 효율적이고 위험 기반 우선순위 결정을 할 수 있도록 합니다.

보안 인벤토리는 다음을 표시합니다:

- 그룹, 하위 그룹 및 프로젝트입니다.
- 각 프로젝트에 대한 보안 스캐너 범위이며, 스캐너가 활성화되는 방식과 관계없습니다. 툴 커버리지는 기본 브랜치의 가장 최근 파이프라인의 스캔 상태를 반영합니다. 보안 스캐너에는 다음이 포함됩니다:
  - 정적 애플리케이션 보안 테스팅(SAST)
  - 종속성 검사
  - 컨테이너 스캐닝
  - 시크릿 검색
  - DAST(동적 애플리케이션 보안 테스트)
  - IaC(코드 기반 인프라) 스캐닝
- 각 그룹 또는 프로젝트의 취약성 개수이며, 심각도 수준으로 정렬됩니다. 개수는 더 이상 감지되지 않는 취약성을 제외합니다.

[에픽 16939](https://gitlab.com/groups/gitlab-org/-/work_items/16939)에서 보안 인벤토리의 개발을 추적합니다. [피드백을 공유](https://gitlab.com/gitlab-org/gitlab/-/issues/553062)하세요. 이 기능의 개발이 계속될 때 피드백을 공유하세요.

## 보안 인벤토리 보기 {#view-the-security-inventory}

사전 요구 사항:

- 보안 인벤토리를 보려면 그룹에서 보안 관리자, 개발자, 관리자 또는 소유자 역할이 있어야 합니다.

보안 인벤토리를 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **Secure** > **Security inventory**를 선택합니다.
1. 다음 조치 중 하나를 완료합니다:
   - 그룹의 하위 그룹, 프로젝트 및 보안 자산을 보려면 그룹을 선택합니다.
   - 그룹 또는 프로젝트의 스캐너 범위를 보려면 그룹 또는 프로젝트를 검색합니다.

## 스캐너 범위 {#scanner-coverage}

{{< history >}}

- 오래됨 상태가 GitLab 19.0에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/work_items/596022)

{{< /history >}}

보안 스캐너 상태는 기본 브랜치 파이프라인이 완료될 때 평가됩니다. 각 보안 스캐너는 모든 프로젝트 또는 그룹에 대해 다음 범위 상태 중 하나를 표시합니다:

- **활성화되지 않음**: 스캐너가 구성되지 않았습니다.
- **활성화**: 스캐너가 구성되고 성공적으로 완료되었습니다.
- **실패함**: 스캐너가 실행되었지만 성공적으로 완료되지 않았습니다.
- **오래됨**: 이전에 활성화된 스캐너가 지난 3개의 연속 파이프라인에서 실행되지 않았습니다.

## 보안 인벤토리에서 프로젝트 필터링 {#filter-projects-in-the-security-inventory}

{{< history >}}

- GitLab 18.5에서 `security_inventory_filtering`라는 [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/552224)되었습니다. 기본적으로 사용으로 설정됩니다.
- 기능 플래그 `security_inventory_filtering`이 GitLab 19.4에서 제거되었습니다.

{{< /history >}}

보안 인벤토리에서 프로젝트를 필터링하여 관심 있는 특정 영역에 초점을 맞출 수 있습니다. 다음 필터를 사용할 수 있습니다:

- **취약성 개수**: 식별된 취약성의 개수를 기준으로 프로젝트를 필터링합니다. 예를 들어 `critical vulnerabilities ≥ 10`인 프로젝트를 표시합니다.
- **툴 커버리지**: 보안 분석기의 상태(**사용**, **활성화되지 않음** 또는 **실패** 등)를 기준으로 프로젝트를 필터링합니다. 예를 들어 `Advanced SAST = enabled`인 프로젝트를 표시합니다.
- **프로젝트 이름**: 이름으로 특정 프로젝트를 검색합니다.

이러한 필터는 큰 인벤토리의 결과를 좁히고 즉각적인 주의가 필요한 프로젝트를 식별하기가 더 쉬워집니다.

## 관련 항목 {#related-topics}

- [보안 대시보드](../security_dashboard/_index.md)
- [취약성 보고서](../vulnerability_report/_index.md)
- GraphQL 참고자료:
  - [AnalyzerGroupStatusType](../../../api/graphql/reference/_index.md#analyzergroupstatustype) \- 그룹 및 하위 그룹의 각 분석기 상태에 대한 개수입니다.
  - [AnalyzerProjectStatusType](../../../api/graphql/reference/_index.md#analyzerprojectstatustype) \- 프로젝트에 대한 분석기 상태(성공/실패)입니다.
  - [VulnerabilityNamespaceStatisticType](../../../api/graphql/reference/_index.md#vulnerabilitynamespacestatistictype) \- 그룹 및 하위 그룹의 각 취약성 심각도에 대한 개수입니다.
  - [VulnerabilityStatisticType](../../../api/graphql/reference/_index.md#vulnerabilitystatistictype) \- 프로젝트의 각 취약성 심각도에 대한 개수입니다.

## 문제 해결 {#troubleshooting}

보안 인벤토리를 사용할 때 다음 문제가 발생할 수 있습니다:

### 보안 인벤토리 메뉴 항목 누락 {#security-inventory-menu-item-missing}

일부 사용자는 **보안 인벤토리** 메뉴 항목에 액세스하기 위한 필요한 권한이 없습니다. 메뉴 항목은 인증된 사용자가 보안 관리자, 개발자, 관리자 또는 소유자 역할을 가질 때만 그룹에 표시됩니다.
