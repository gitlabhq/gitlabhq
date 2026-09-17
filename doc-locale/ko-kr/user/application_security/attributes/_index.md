---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보안 특성
description: 보안 속성을 사용하면 보안 팀이 프로젝트 및 그룹에 사용자 지정 메타데이터 레이블을 적용하여 비즈니스 컨텍스트에 따라 보안 위험을 필터링하고 우선 순위를 지정할 수 있습니다.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/18010) GitLab 18.5에서 `security_context_labels`과 `security_categories_and_attributes` 플래그가 포함되었습니다. 기본적으로 비활성화되었습니다. 이 기능은 [베타](../../../policy/development_stages_support.md)에서 도입되었습니다.
- [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/551226) GitLab 18.6에서.
- GitLab 18.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/588619)하게 되었습니다. `security_inventory_dashboard` 기능 플래그가 제거되었습니다.

{{< /history >}}

보안 팀은 이제 보안 속성을 사용하여 자체 조직 및 비즈니스 요구에 맞는 메타데이터를 프로젝트에 적용할 수 있습니다.

보안 속성은 다음을 기반으로 카테고리별로 구성됩니다:

- 비즈니스 영향
- 애플리케이션
- 비즈니스 단위
- 인터넷 노출
- 위치

프로젝트 전체에 이 속성을 적용하면 조직의 위험 태세 및 비즈니스 요구에 따라 조치가 필요한 프로젝트를 훨씬 더 빠르게 식별할 수 있습니다. 보안 속성을 사용하면 다음을 수행할 수 있습니다:

- 미션 크리티컬이며 더 강력한 스캔 커버리지가 필요한 프로젝트를 식별합니다.
- 각 애플리케이션 또는 비즈니스 단위의 스캔 커버리지를 검토합니다.
- 공개적으로 액세스 가능하고 노출된 애플리케이션에 기여하는 프로젝트를 찾습니다.

[에픽 16939](https://gitlab.com/groups/gitlab-org/-/work_items/16939)에서 보안 인벤토리의 개발을 추적합니다. [피드백](https://gitlab.com/gitlab-org/gitlab/-/issues/553062)을 공유하여 이 기능의 개발을 계속합니다.

## 그룹의 보안 속성 관리 {#manage-security-attributes-for-groups}

전제 조건:

- 보안 관리자, 유지보수자 또는 소유자 역할을 최상위 그룹(네임스페이스)에서 보유해야 보안 속성을 관리할 수 있습니다.

그룹의 보안 속성을 관리하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.

## 프로젝트의 보안 속성 관리 {#manage-security-attributes-for-projects}

전제 조건:

- 보안 관리자, 유지보수자 또는 소유자 역할을 최상위 그룹(네임스페이스)에서 보유해야 보안 속성을 관리할 수 있습니다.

프로젝트의 보안 속성을 관리하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **보안 속성** 탭을 선택합니다.

## 관련 항목 {#related-topics}

- [보안 인벤토리](../security_inventory/_index.md)
- [보안 대시보드](../security_dashboard/_index.md)
- [취약성 보고서](../vulnerability_report/_index.md)

## 문제 해결 {#troubleshooting}

보안 속성으로 작업할 때 다음 문제가 발생할 수 있습니다.

### 메뉴 항목 누락 {#security-configuration-menu-item-missing}

사용자는 그룹의 보안 관리자, 유지보수자 또는 소유자인 경우에도 **보안 구성** 메뉴 항목에 액세스하는 데 필요한 권한이 없을 수 있습니다.

메뉴 항목은 인증된 사용자가 최상위 그룹(네임스페이스)에서 보안 관리자, 유지보수자 또는 소유자 역할을 가진 경우에만 그룹에 표시됩니다.

보안 속성을 관리하려면 유지보수자에게 구성 변경을 완료하도록 요청하거나 관리자에게 유지보수자 역할을 요청하세요.
