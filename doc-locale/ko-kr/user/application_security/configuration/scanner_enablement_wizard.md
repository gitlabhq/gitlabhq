---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 스캐너 활성화 마법사
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 19.1에서 도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/21626) [기능 플래그](../../../administration/feature_flags/_index.md) `group_security_configuration_scanners_tab`와 함께 도입되었습니다. 기본적으로 비활성화되어 있습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

마법사는 DAST, SAST, IaC 스캔을 구성하고 [보안 인벤토리](../security_inventory/_index.md)에 표시되는 범위를 업데이트합니다.

전제 조건:

- 스캐너 범위를 보려면 그룹의 개발자, 유지 관리자 또는 소유자 역할이 필요합니다.
- 스캐너를 활성화하려면 그룹의 개발자, 유지 관리자 또는 소유자 역할이 필요합니다.

## 스캐너 범위 보기 {#view-scanner-coverage}

**Scanners** 탭은 그룹의 모든 프로젝트에서 스캐너 범위를 표시합니다.

스캐너 범위를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **Scanners** 탭을 선택합니다.

탭에는 다음 카드가 표시됩니다:

| 카드 | 설명 |
|------|-------------|
| 보호되지 않은 프로젝트 | 스캐너가 활성화되지 않은 프로젝트 목록입니다. |
| 스캐너 활성화됨 | 그룹에서 활성화된 모든 스캐너 유형의 수입니다. |
| 주의 필요 | 스캔 실패가 있는 프로젝트의 목록입니다. |
| 오래된 스캔 | 90일보다 오래된 스캔이 있는 프로젝트의 목록입니다. |

카드 아래에는 각 스캐너 유형의 목록이 몇 개의 프로젝트가 스캐너를 활성화, 실패 또는 구성되지 않았는지 나타냅니다.

## 스캐너 상세 정보 보기 {#view-scanner-details}

그룹의 프로젝트에서 스캐너의 상태를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **Scanners** 탭을 선택합니다.
1. 스캐너 옆에서 **상세 보기**를 선택합니다.

스캐너 상세 정보 페이지는 스캐너의 통계 카드(**활성화**, **활성화되지 않음**, **주의 필요**, **오래됨**)와 그룹의 모든 프로젝트 표를 표시합니다.

표는 다음 열을 표시합니다:

| 열 | 설명 |
|--------|-------------|
| 프로젝트 | 프로젝트 이름 및 경로입니다. |
| 소스 | 사용 가능한 경우 적용된 구성 프로필의 이름입니다. |
| 상태 | 프로젝트의 현재 스캐너 상태입니다. |
| 마지막 스캔 | 가장 최근 스캔의 시간입니다. |
| 보안 특성 | 프로젝트에 할당된 보안 특성입니다. 보안 특성을 읽을 수 있는 경우에만 표시됩니다. |

## 프로젝트의 스캐너 구성 {#configure-a-scanner-for-projects}

프로필 기반 구성을 사용하는 스캐너를 구성할 수 있습니다. 보안 정책이나 CI/CD 구성 등 다른 소스의 스캐너를 구성하려면 원본에서 조정해야 합니다.

프로젝트의 스캐너를 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **Scanners** 탭을 선택합니다.
1. 스캐너 옆에서 **상세 보기**를 선택합니다.
1. 프로젝트 옆에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 다음 작업을 선택합니다:

   - **Enable profile-based scanning**: 기본 프로필을 프로젝트에 적용합니다. 프로젝트가 **적용된 프로필 없음**을 표시할 때 사용할 수 있습니다.
   - **Disable profile-based scanning**: 적용된 프로필을 프로젝트에서 제거합니다.
   - **View project configuration**: 프로젝트의 보안 구성 페이지를 엽니다.
   - **Troubleshoot failure**: 가장 최근 스캔이 실패했거나 경고가 있는 경우 더 많은 세부 정보를 제공합니다.

## 스캐너 활성화 마법사 사용 {#use-the-scanner-enablement-wizard}

스캐너 활성화 마법사는 두 가지 접근 방식을 제공합니다:

- **Quick setup**: GitLab 기본 프로필을 그룹의 모든 범위가 제한된 프로젝트에 적용합니다.
- **Advanced setup**: 선택한 프로필을 특정 프로젝트 및 스캐너에 적용합니다.

> [!note]
> 마법사는 DAST, 컨테이너 스캔 또는 IaC 스캔을 구성하지 않습니다. 이 스캐너를 보안 정책 또는 프로젝트 수준에서 구성합니다.

### 빠른 설정 {#quick-setup}

빠른 설정은 GitLab 기본 프로필을 그룹의 모든 범위가 제한된 프로젝트에 적용합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **Scanners** 탭을 선택합니다.
1. **Enable scanners**를 선택합니다.
1. **Quick setup**을 선택한 다음 **Start quick setup**을 선택합니다.
1. **Review configuration** 단계에서 스캐너 및 적용되는 프로젝트를 검토합니다.
1. **Apply configuration**을 선택합니다.

구성을 적용한 후 GitLab은 프로필을 프로젝트에 배치로 적용하며 이에는 몇 분이 걸릴 수 있습니다. 확인 단계에는 각 스캐너, 프로필 및 각 프로필이 적용되는 항목의 수가 나열됩니다.

### 고급 설정 {#advanced-setup}

고급 설정은 선택한 프로필만 특정 프로젝트 및 스캐너에 적용합니다. 한 번에 100개 이상의 프로젝트에 프로필을 적용해야 하는 경우 빠른 설정을 사용합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **Scanners** 탭을 선택합니다.
1. **Enable scanners**를 선택합니다.
1. **Advanced setup**을 선택한 다음 **Start advanced setup**을 선택합니다.
1. **프로젝트 선택** 단계에서 구성할 프로젝트를 선택합니다. 검색 및 필터를 사용하여 프로젝트를 찾습니다. **Scanner coverage** 열은 기존 범위를 표시합니다. 최대 100개 항목을 선택할 수 있습니다.
1. **Select scanners** 단계에서 활성화할 스캐너를 선택합니다. 각 스캐너에 대해 적용할 구성 프로필을 선택합니다.
1. **Review configuration** 단계에서 선택한 프로젝트 및 스캐너를 검토합니다. 변경 사항을 만들려면 **항목** 또는 **Scanners** 옆의 편집 아이콘({{< icon name="pencil" >}})을 선택합니다.
1. **Apply configuration**을 선택합니다.

구성을 적용한 후 GitLab은 프로필을 프로젝트에 배치로 적용하며 이에는 몇 분이 걸릴 수 있습니다. 확인 단계에는 각 스캐너, 프로필 및 각 프로필이 적용되는 항목의 수가 나열됩니다.

## 관련 항목 {#related-topics}

- [보안 구성 프로필](security_configuration_profiles.md)
- [보안 인벤토리](../security_inventory/_index.md)
- [보안 특성](../attributes/_index.md)
- [권한 및 역할](../../permissions.md)
