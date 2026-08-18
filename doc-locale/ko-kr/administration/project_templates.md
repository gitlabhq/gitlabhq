---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: GitLab 인스턴스의 프로젝트를 위해 커스텀 프로젝트 템플릿과 빌트인 프로젝트 템플릿을 구성합니다.
title: 인스턴스의 프로젝트 템플릿
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

프로젝트 템플릿은 새 프로젝트에 파일과 구성으로 채웁니다. 인스턴스에서는 관리하는 그룹의 커스텀 프로젝트 템플릿을 구성할 수 있으며, 빌트인 프로젝트 템플릿을 사용자가 사용할 수 있는지 여부를 제어할 수 있습니다.

## 커스텀 프로젝트 템플릿 {#custom-project-templates}

인스턴스의 프로젝트 생성 속도를 높이기 위해 템플릿 프로젝트를 포함하는 그룹을 구성합니다. 사용자는 지정한 일반적인 도구와 구성을 포함하는 [템플릿을 기반으로 새 프로젝트를 생성](../user/project/_index.md#create-a-project-from-a-custom-template)할 수 있습니다.

템플릿에서 복사되는 데이터에 대해 자세히 알아보려면 [템플릿에서 복사되는 내용](../user/group/custom_project_templates.md#what-is-copied-from-the-templates)을 참조하세요.

템플릿 프로젝트를 인스턴스에서 사용할 수 있도록 하기 전에 템플릿을 관리할 그룹을 선택합니다. 템플릿에 대한 예기치 않은 변경을 방지하려면 기존 그룹을 재사용하는 대신 이 목적으로 새 그룹을 생성합니다. 다른 목적으로 생성된 기존 그룹을 재사용하면 Maintainer 역할을 가진 사용자가 부작용을 이해하지 못한 채 템플릿 프로젝트를 편집할 수 있습니다.

### 템플릿 프로젝트를 관리할 그룹 선택 {#select-a-group-to-manage-template-projects}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인스턴스에 대해 프로젝트 템플릿을 관리할 그룹을 선택합니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **텝플릿**을 선택합니다.
1. **커스텀 프로젝트 템플릿**을 확장합니다.
1. 사용할 그룹을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

그룹을 프로젝트 템플릿의 소스로 구성한 후 이 그룹에 추가된 새 프로젝트는 템플릿으로 사용할 수 있게 됩니다.

### 템플릿으로 사용할 프로젝트 구성 {#configure-a-project-for-use-as-a-template}

템플릿 프로젝트를 관리할 그룹을 생성한 후 각 템플릿 프로젝트의 가시성과 기능 가용성을 구성합니다.

전제 조건:

- 인스턴스의 관리자이거나 프로젝트를 구성할 수 있는 역할을 가진 사용자여야 합니다.

1. 프로젝트가 하위 그룹이 아닌 그룹에 직접 속하는지 확인합니다. 선택한 그룹의 하위 그룹에 속한 프로젝트는 템플릿으로 사용할 수 없습니다.
1. 프로젝트 템플릿을 선택할 수 있는 사용자를 구성하려면 [프로젝트의 가시성](../user/public_access.md#change-project-visibility)을 설정합니다:
   - **공개** 및 **내부** 프로젝트는 모든 인증된 사용자가 선택할 수 있습니다.
   - **비공개** 프로젝트는 해당 프로젝트의 구성원만 선택할 수 있습니다.
1. 프로젝트의 [기능 설정](../user/project/settings/_index.md#configure-project-features-and-permissions)을 검토합니다. 활성화된 모든 프로젝트 기능은 **액세스 권한이 있는 모든 사용자**로 설정되어야 하며, **GitLab 페이지** 및 **보안 및 규정 준수**는 제외됩니다.

각 새 프로젝트로 복사되는 리포지토리 및 데이터베이스 정보는 GitLab 프로젝트 가져오기 및 내보내기로 내보낸 데이터와 동일합니다. 여기에는 템플릿 프로젝트의 전체 Git 커밋 이력이 포함됩니다. 자세한 내용은 [파일 내보내기를 사용하여 GitLab 데이터 마이그레이션](../user/project/settings/import_export.md)을 참조하세요.

커밋 이력이 없는 템플릿을 생성하려면 포함하려는 모든 파일이 있는 단일 커밋으로 템플릿 프로젝트를 초기화합니다.

## 빌트인 프로젝트 템플릿 {#built-in-project-templates}

{{< history >}}

- `use_built_in_project_templates_enabled`라는 이름의 [기능 플래그](feature_flags/_index.md)와 함께 GitLab 19.0에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230641). 기본적으로 비활성화되었습니다.
- GitLab 19.2에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/593623)합니다. `use_built_in_project_templates_enabled` 기능 플래그가 제거되었습니다.

{{< /history >}}

[빌트인 프로젝트 템플릿](../user/project/_index.md#create-a-project-from-a-built-in-template)은 새 프로젝트에 시작 파일로 채웁니다. 기본적으로 이 템플릿은 모든 사용자가 사용할 수 있습니다. 관리자는 인스턴스에 대해 이 설정을 비활성화할 수 있으며, 선택적으로 그룹 소유자가 재정의할 수 없도록 강제할 수 있습니다. 그룹 소유자는 또한 [자신의 그룹에 대해 이 설정을 제어](../user/group/manage.md#control-built-in-project-templates)할 수 있습니다.

이 설정은 계단식 상속을 사용합니다:

- 기본적으로 루트 그룹은 인스턴스 값을 상속합니다.
- 하위 그룹은 가장 가까운 상위 그룹의 값을 상속합니다.
- 그룹별 값이 상속된 값을 재정의합니다.
- 인스턴스에 대해 설정을 강제하면 모든 그룹이 이를 상속합니다.
- 그룹에 대해 설정을 강제하면 모든 하위 그룹이 이를 상속합니다.
- 인스턴스 설정을 변경하면 새 값이 모든 그룹으로 계단식으로 전파됩니다.
- 그룹 설정을 변경하면 새 값이 모든 하위 그룹으로 계단식으로 전파됩니다.

### 빌트인 프로젝트 템플릿 구성 {#configure-built-in-project-templates}

전제 조건:

- 관리자여야 합니다.

인스턴스에 대해 빌트인 프로젝트 템플릿을 제어합니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. **설정** > **텝플릿**을 선택합니다.
1. **빌트인 프로젝트 템플릿**을 확장합니다.
1. **빌트인 프로젝트 템플릿 활성화** 확인란을 선택하거나 선택 해제합니다.
1. 선택 사항. 그룹이 이 설정을 변경하지 못하도록 하려면 **모든 그룹에 강제 적용** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 관련 항목 {#related-topics}

- [그룹의 커스텀 프로젝트 템플릿](../user/group/custom_project_templates.md).
