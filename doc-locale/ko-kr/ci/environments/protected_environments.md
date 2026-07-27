---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "배포 액세스를 제한하여 환경을 보호합니다. 역할, 사용자 또는 그룹 멤버십을 기반으로 특정 환경에 배포할 수 있는 사용자를 제어합니다."
title: 보호 환경
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[환경](_index.md)은 테스트 및 프로덕션 목적으로 모두 사용할 수 있습니다.

배포 작업은 다양한 역할을 가진 다양한 사용자가 실행할 수 있으므로 특정 환경을 무단 사용자의 영향으로부터 보호할 수 있는 것이 중요합니다.

기본적으로 보호 환경은 적절한 권한을 가진 사용자만 배포할 수 있도록 하여 환경을 안전하게 유지합니다.

> [!note]
> GitLab 관리자는 보호된 환경을 포함한 모든 환경을 사용할 수 있습니다.

환경을 보호하거나 보호를 해제하려면 최소한 유지관리자 역할이 필요합니다. 또한 `external_url`, `tier` 또는 `description`과 같은 환경 속성을 업데이트하려면 **배포 허용됨** 목록에도 있어야 합니다.

## 환경 보호 {#protecting-environments}

전제 조건:

- **배포 허용됨** 권한을 승인자 그룹에 부여할 때 보호된 환경을 구성하는 사용자는 추가할 승인자 그룹의 **direct member**여야 합니다. 그렇지 않으면 그룹 또는 하위 그룹이 드롭다운 목록에 표시되지 않습니다. 자세한 내용은 [이슈 #345140](https://gitlab.com/gitlab-org/gitlab/-/issues/345140)을 참조하세요.
- **승인자** 권한을 승인자 그룹 또는 프로젝트에 부여할 때 기본적으로 승인자 그룹 또는 프로젝트의 직접 멤버만 이러한 권한을 받습니다. 승인자 그룹 또는 프로젝트의 상속된 멤버에게도 이러한 권한을 부여하려면:
  - **그룹 상속 활성화** 확인란을 선택하세요.
  - [API 사용](../../api/protected_environments.md#group-inheritance-types).

환경을 보호하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **보호된 환경**을 확장합니다.
1. **환경을 보호**를 선택하세요.
1. **환경** 목록에서 보호할 환경을 선택합니다.
1. **배포 허용됨** 목록에서 배포 액세스를 부여할 역할, 사용자 또는 그룹을 선택합니다. 다음을 유의하세요:
   - 선택할 수 있는 역할은 두 가지입니다:
     - **유지관리자**: 유지관리자 역할을 가진 프로젝트의 모든 사용자에게 액세스를 허용합니다.
     - **개발자**: 유지관리자 및 개발자 역할을 가진 프로젝트의 모든 사용자에게 액세스를 허용합니다.
   - 프로젝트에 이미 [초대된](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project) 그룹을 선택할 수도 있습니다. 리포터 역할로 프로젝트에 추가된 초대된 그룹은 [배포 전용 액세스](#deployment-only-access-to-protected-environments)를 위한 드롭다운 목록에 나타납니다.
   - 특정 사용자를 선택할 수도 있습니다. 사용자는 **배포 허용됨** 목록에 표시되려면 개발자, 유지관리자 또는 소유자 역할을 가져야 합니다.
1. **승인자** 목록에서 배포 액세스를 부여할 역할, 사용자 또는 그룹을 선택합니다. 다음을 유의하세요:

   - 선택할 수 있는 역할은 두 가지입니다:
     - **유지관리자**: 유지관리자 역할을 가진 프로젝트의 모든 사용자에게 액세스를 허용합니다.
     - **개발자**: 유지관리자 및 개발자 역할을 가진 프로젝트의 모든 사용자에게 액세스를 허용합니다.
   - 프로젝트에 이미 [초대된](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project) 그룹만 선택할 수 있습니다.
   - 사용자는 **승인자** 목록에 표시되려면 개발자, 유지관리자 또는 소유자 역할을 가져야 합니다.

1. **승인 규칙** 섹션에서:

   - 이 숫자가 규칙의 멤버 수보다 작거나 같은지 확인합니다.
   - 이 기능에 대한 자세한 내용은 [배포 승인](deployment_approvals.md)을 참조하세요.

1. **보호**를 선택하세요.

보호된 환경이 이제 보호된 환경 목록에 나타납니다.

### API를 사용하여 환경을 보호 {#use-the-api-to-protect-an-environment}

또는 API를 사용하여 환경을 보호할 수 있습니다:

1. 환경을 생성하는 CI가 있는 프로젝트를 사용합니다. 예를 들어:

   ```yaml
   stages:
     - test
     - deploy

   test:
     stage: test
     script:
       - 'echo "Testing Application: ${CI_PROJECT_NAME}"'

   production:
     stage: deploy
     when: manual
     script:
       - 'echo "Deploying to ${CI_ENVIRONMENT_NAME}"'
     environment:
       name: ${CI_JOB_NAME}
   ```

1. UI를 사용하여 [새 그룹을 생성](../../user/group/_index.md#create-a-group)합니다. 예를 들어 이 그룹은 `protected-access-group`라고 하며 그룹 ID는 `9899826`입니다. 이 단계의 나머지 예제에서 이 그룹을 사용합니다.

   ![새 프로젝트 버튼이 강조되어 있는 보호된 액세스 그룹 인터페이스입니다.](img/protected_access_group_v13_6.png)

1. API를 사용하여 리포터로 그룹에 사용자를 추가합니다:

   ```shell
   $ curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
          --data "user_id=3222377&access_level=20" "https://gitlab.com/api/v4/groups/9899826/members"

   {"id":3222377,"name":"Sean Carroll","username":"sfcarroll","state":"active","avatar_url":"https://gitlab.com/uploads/-/system/user/avatar/3222377/avatar.png","web_url":"https://gitlab.com/sfcarroll","access_level":20,"created_at":"2020-10-26T17:37:50.309Z","expires_at":null}
   ```

1. API를 사용하여 리포터로 프로젝트에 그룹을 추가합니다:

   ```shell
   $ curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
          --request POST "https://gitlab.com/api/v4/projects/22034114/share?group_id=9899826&group_access=20"

   {"id":1233335,"project_id":22034114,"group_id":9899826,"group_access":20,"expires_at":null}
   ```

1. API를 사용하여 보호된 환경 액세스 권한으로 그룹을 추가합니다:

   ```shell
   curl --header 'Content-Type: application/json' --request POST --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}]}' \
        --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.com/api/v4/projects/22034114/protected_environments"
   ```

그룹이 이제 액세스 권한을 가지고 있으며 UI에서 볼 수 있습니다.

## 그룹 멤버십을 통한 환경 액세스 {#environment-access-by-group-membership}

사용자는 [그룹 멤버십](../../user/group/_index.md)의 일부로 보호된 환경에 대한 액세스 권한을 받을 수 있습니다. 리포터 역할을 가진 사용자는 이 방법으로만 보호된 환경에 액세스할 수 있습니다.

## 배포 브랜치 액세스 {#deployment-branch-access}

개발자 역할을 가진 사용자는 다음 방법 중 하나를 통해 보호된 환경에 액세스할 수 있습니다:

- 역할을 통해 개별 기여자로서.
- 그룹 멤버십을 통해.

사용자가 프로덕션에 배포된 브랜치에 대한 푸시 또는 병합 액세스 권한도 있으면 다음 권한을 가집니다:

- [환경 중지](_index.md#stopping-an-environment).
- [환경 삭제](_index.md#delete-an-environment).
- [환경 터미널 생성](_index.md#web-terminals-deprecated).

## 보호된 환경에 대한 배포 전용 액세스 {#deployment-only-access-to-protected-environments}

보호된 환경에 대한 액세스 권한을 받았지만 배포된 브랜치에 대한 푸시 또는 병합 액세스 권한이 없는 사용자는 환경을 배포할 수 있는 액세스 권한만 부여받습니다. [초대된 그룹](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)은 [리포터 역할](../../user/permissions.md#project-permissions)로 프로젝트에 추가되며 배포 전용 액세스를 위한 드롭다운 목록에 나타납니다.

배포 전용 액세스를 추가하려면:

1. 아직 없으면 보호된 환경에 대한 액세스 권한이 있는 멤버가 있는 그룹을 생성합니다.
1. [그룹을 초대](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)하여 리포터 역할로 프로젝트에 추가합니다.
1. [환경 보호](#protecting-environments)의 단계를 따릅니다.

## 환경 수정 및 보호 해제 {#modifying-and-unprotecting-environments}

유지관리자는 다음을 수행할 수 있습니다:

- **배포 허용됨** 목록 및 승인 규칙을 포함한 보호 설정을 언제든지 업데이트합니다.
- 해당 환경에 대해 **보호 해제**를 선택하여 보호된 환경을 보호 해제합니다.

보호된 환경에서 `external_url`, `tier` 또는 `description`과 같은 환경 속성을 업데이트하려면 사용자도 **배포 허용됨** 목록에 있어야 합니다.

환경이 보호 해제되면 모든 액세스 항목이 삭제되며 환경을 다시 보호하는 경우 다시 입력해야 합니다.

승인 규칙이 삭제된 후 이전에 승인된 배포는 누가 배포를 승인했는지 표시하지 않습니다. 배포를 승인한 사용자에 대한 정보는 [프로젝트 감사 이벤트](../../user/compliance/audit_events.md#project-audit-events)에서 사용할 수 있습니다. 새 규칙이 추가되면 이전 배포는 배포 승인 옵션 없이 새 규칙을 표시합니다. [이슈 506687](https://gitlab.com/gitlab-org/gitlab/-/issues/506687)은 승인 규칙이 삭제된 경우에도 배포의 전체 승인 기록을 표시하도록 제안합니다.

자세한 내용은 [배포 안전](deployment_safety.md)을 참조하세요.

## 그룹 수준 보호 환경 {#group-level-protected-environments}

일반적으로 대규모 엔터프라이즈 조직은 [개발자와 운영자](https://about.gitlab.com/topics/devops/) 간에 명시적인 권한 경계를 가집니다. 개발자는 코드를 빌드하고 테스트하며 운영자는 애플리케이션을 배포하고 모니터링합니다. 그룹 수준 보호 환경으로 운영자는 개발자로부터 중요한 환경에 대한 액세스를 제한할 수 있습니다. 그룹 수준 보호 환경은 [프로젝트 수준 보호 환경](#protecting-environments)을 그룹 수준으로 확장합니다.

배포의 권한을 다음 표로 나타낼 수 있습니다:

| 환경 | 개발자  | 운영자 | 카테고리 |
|-------------|------------|----------|----------|
| 개발 | 허용됨    | 허용됨  | 낮은 환경 |
| 테스팅     | 허용됨    | 허용됨  | 낮은 환경 |
| 스테이징     | 허용되지 않음 | 허용됨  | 높은 환경 |
| 프로덕션  | 허용되지 않음 | 허용됨  | 높은 환경 |

_(참고: [Wikipedia의 배포 환경](https://en.wikipedia.org/wiki/Deployment_environment))_

### 그룹 수준 보호 환경 이름 {#group-level-protected-environments-names}

프로젝트 수준 보호 환경과 달리 그룹 수준 보호 환경은 [배포 티어](_index.md#deployment-tier-of-environments)를 이름으로 사용합니다.

그룹은 고유한 이름을 가진 많은 프로젝트 환경으로 구성될 수 있습니다. 예를 들어 프로젝트-A에는 `gprd` 환경이 있고 프로젝트-B에는 `Production` 환경이 있으므로 특정 환경 이름을 보호하는 것이 잘 확장되지 않습니다. 배포 티어를 사용하면 둘 다 `production` 배포 티어로 인식되며 동시에 보호됩니다.

### 그룹 수준 멤버십 구성 {#configure-group-level-memberships}

{{< history >}}

- 운영자는 원래 유지관리자 이상 역할에서 소유자 이상 역할을 갖도록 요구되며 이 역할 변경은 [플래그 포함](https://gitlab.com/gitlab-org/gitlab/-/issues/369873) GitLab 15.3부터 도입되었으며 `group_level_protected_environment_settings_permission`으로 명명됩니다. 기본적으로 활성화됩니다.
- [기능 플래그 제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/369873) GitLab 15.4에서.

{{< /history >}}

그룹 수준 보호 환경의 효과를 최대화하려면 [그룹 수준 멤버십](../../user/group/_index.md)을 올바르게 구성해야 합니다:

- 운영자에게 최상위 그룹의 소유자 역할을 부여해야 합니다. 그룹 수준 설정 페이지에서 더 높은 환경(프로덕션 등)에 대한 CI/CD 구성을 유지할 수 있으며 이 페이지에는 그룹 수준 보호 환경, [그룹 수준 러너](../runners/runners_scope.md#group-runners) 및 [그룹 수준 클러스터](../../user/group/clusters/_index.md)가 포함됩니다. 이러한 구성은 자식 프로젝트에 읽기 전용 항목으로 상속됩니다. 이를 통해 운영자만 조직 전체 배포 규칙 집합을 구성할 수 있습니다.
- 개발자는 최상위 그룹의 개발자 역할 이상을 받아서는 안 되거나 자식 프로젝트의 소유자 역할을 명시적으로 받아야 합니다. 최상위 그룹의 CI/CD 구성에 액세스할 수 없으므로 운영자는 중요한 구성이 개발자가 실수로 변경되지 않도록 할 수 있습니다.
- 하위 그룹 및 자식 프로젝트의 경우:
  - [하위 그룹](../../user/group/subgroups/_index.md)과 관련하여 더 높은 그룹이 그룹 수준 보호 환경을 구성한 경우 더 낮은 그룹은 이를 재정의할 수 없습니다.
  - [프로젝트 수준 보호 환경](#protecting-environments)을 그룹 수준 설정과 결합할 수 있습니다. 그룹 수준 및 프로젝트 수준 환경 구성이 모두 존재하는 경우 배포 작업을 실행하려면 사용자가 두 규칙 집합 모두에서 허용되어야 합니다.
  - 최상위 그룹의 프로젝트 또는 하위 그룹에서 개발자는 더 낮은 환경(예: `testing`)을 조정하기 위해 유지관리자 역할을 안전하게 할당받을 수 있습니다.

이 구성이 적용되면:

- 사용자가 프로젝트에서 배포 작업을 실행하려고 하고 환경에 배포할 수 있으면 배포 작업이 진행됩니다.
- 사용자가 프로젝트에서 배포 작업을 실행하려고 하지만 환경에 배포할 수 없으면 배포 작업이 오류 메시지와 함께 실패합니다.

### 그룹 아래의 중요 환경 보호 {#protect-critical-environments-under-a-group}

그룹 수준 환경을 보호하려면 환경에 올바른 [`deployment_tier`](_index.md#deployment-tier-of-environments)이 `.gitlab-ci.yml`에 정의되어 있는지 확인합니다.

#### UI 사용 {#using-the-ui}

{{< history >}}

- GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/325249)되었습니다.

{{< /history >}}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **보호된 환경**을 확장합니다.
1. **환경** 목록에서 보호할 [환경의 배포 티어](_index.md#deployment-tier-of-environments)를 선택합니다.
1. **배포 허용됨** 목록에서 배포 액세스를 제공할 [하위 그룹](../../user/group/subgroups/_index.md)을 선택합니다.
1. **보호**를 선택하세요.

#### API 사용 {#using-the-api}

[REST API](../../api/group_protected_environments.md)를 사용하여 그룹 수준 보호 환경을 구성합니다.

## 배포 승인 {#deployment-approvals}

보호된 환경은 배포 전에 수동 승인을 요구하는 데도 사용할 수 있습니다. 자세한 내용은 [배포 승인](deployment_approvals.md)을 참조하세요.

## 문제 해결 {#troubleshooting}

### 리포터가 다운스트림 파이프라인에서 보호된 환경에 배포하는 트리거 작업을 실행할 수 없음 {#reporter-cant-run-a-trigger-job-that-deploys-to-a-protected-environment-in-downstream-pipeline}

[보호된 환경에 대한 배포 전용 액세스](#deployment-only-access-to-protected-environments)를 가진 사용자는 [`trigger`](../yaml/_index.md#trigger) 키워드를 사용하는 경우 작업을 실행하지 못할 수 있습니다. 이는 작업이 보호된 환경과 작업을 연결하기 위한 [`environment`](../yaml/_index.md#environment) 키워드 정의를 놓치고 있기 때문이며 따라서 작업은 [일반 CI/CD 권한 모델](../../user/permissions.md#project-cicd)을 사용하는 표준 작업으로 인식됩니다.

[이 이슈](https://gitlab.com/groups/gitlab-org/-/epics/8483)를 참조하여 `environment` 키워드와 함께 `trigger` 키워드 지원에 대한 자세한 정보를 확인하세요.
