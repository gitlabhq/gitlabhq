---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: 프로젝트 템플릿을 구성하고 GitLab 인스턴스의 모든 프로젝트에서 사용 가능하도록 만듭니다.
title: 인스턴스의 커스텀 프로젝트 템플릿
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

인스턴스에서 프로젝트 생성 속도를 높이려면 템플릿 프로젝트를 포함하는 그룹을 구성합니다. 사용자는 지정한 일반적인 도구와 구성을 포함하는 [템플릿을 기반으로 새 프로젝트를 생성](../user/project/_index.md#create-a-project-from-a-custom-template)할 수 있습니다.

템플릿에서 복사된 데이터에 대해 자세히 알아보려면 [템플릿에서 복사된 내용](../user/group/custom_project_templates.md#what-is-copied-from-the-templates)을 참조하세요.

템플릿 프로젝트를 인스턴스에서 사용 가능하게 만들기 전에, 템플릿을 관리할 그룹을 선택합니다. 템플릿의 예상치 못한 변경을 방지하려면 기존 그룹을 다시 사용하지 않고 이 목적을 위해 새 그룹을 생성합니다. 다른 목적으로 생성된 기존 그룹을 다시 사용하면, 유지관리자 역할을 가진 사용자가 부작용을 이해하지 못한 채 템플릿 프로젝트를 수정할 수 있습니다.

## 템플릿 프로젝트를 관리할 그룹을 선택합니다 {#select-a-group-to-manage-template-projects}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인스턴스의 프로젝트 템플릿을 관리할 그룹을 선택하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **텝플릿**을 선택합니다.
1. **커스텀 프로젝트 템플릿**을 확장합니다.
1. 사용할 그룹을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

그룹을 프로젝트 템플릿의 소스로 구성하면, 이 그룹에 추가된 새 프로젝트가 템플릿으로 사용 가능해집니다.

## 프로젝트를 템플릿으로 사용하도록 구성합니다 {#configure-a-project-for-use-as-a-template}

템플릿 프로젝트를 관리할 그룹을 생성한 후, 각 템플릿 프로젝트의 가시성과 기능 가용성을 구성합니다.

전제 조건:

- 인스턴스의 관리자이거나 프로젝트를 구성할 수 있는 역할을 가진 사용자여야 합니다.

1. 프로젝트가 서브그룹을 통하지 않고 그룹에 직접 속하는지 확인합니다. 선택한 그룹의 서브그룹에 속한 프로젝트는 템플릿으로 사용할 수 없습니다.
1. 프로젝트 템플릿을 선택할 수 있는 사용자를 구성하려면 [프로젝트의 가시성](../user/public_access.md#change-project-visibility)을 설정합니다:
   - **공개** 및 **내부** 프로젝트는 모든 인증된 사용자가 선택할 수 있습니다.
   - **비공개** 프로젝트는 해당 프로젝트의 구성원만 선택할 수 있습니다.
1. 프로젝트의 [기능 설정](../user/project/settings/_index.md#configure-project-features-and-permissions)을 검토합니다. 모든 활성화된 프로젝트 기능은 **액세스 권한이 있는 모든 사용자**로 설정해야 합니다. 단, **GitLab 페이지**와 **보안 및 규정 준수**는 예외입니다.

리포지토리와 데이터베이스 정보는 각 새 프로젝트로 복사되며, GitLab 프로젝트 가져오기 및 내보내기로 내보낸 데이터와 동일합니다. 여기에는 템플릿 프로젝트의 전체 Git 커밋 히스토리가 포함됩니다. 자세한 내용은 [파일 내보내기를 사용하여 GitLab 데이터 마이그레이션](../user/project/settings/import_export.md)을 참조하세요.

커밋 히스토리 없이 템플릿을 생성하려면 포함할 모든 파일이 있는 단일 커밋으로 템플릿 프로젝트를 초기화합니다.

## 관련 항목 {#related-topics}

- [그룹의 커스텀 프로젝트 템플릿](../user/group/custom_project_templates.md)
