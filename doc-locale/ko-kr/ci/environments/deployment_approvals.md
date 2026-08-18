---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 보호 환경으로 배포하기 전에 승인 필요
title: 배포 승인
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

보호 환경으로의 배포에 대한 추가 승인을 요구할 수 있습니다. 필요한 모든 승인이 제공될 때까지 배포가 차단됩니다.

배포 승인을 사용하여 테스트, 보안 또는 규정 준수 프로세스를 수용합니다. 예를 들어 프로덕션 환경으로의 배포에 대한 승인을 요구하고 싶을 수 있습니다.

## 배포 승인 구성 {#configure-deployment-approvals}

프로젝트에서 보호 환경으로의 배포에 대한 승인을 요구할 수 있습니다.

전제 조건:

- 환경을 업데이트하려면 유지 관리자 또는 소유자 역할이 있어야 합니다.

프로젝트에 대한 배포 승인을 구성하려면:

1. 프로젝트의 `.gitlab-ci.yml` 파일에 배포 작업을 생성합니다:

   ```yaml
   stages:
     - deploy

   production:
     stage: deploy
     script:
       - 'echo "Deploying to ${CI_ENVIRONMENT_NAME}"'
     environment:
       name: ${CI_JOB_NAME}
       action: start
   ```

   작업은 수동일 필요가 없습니다(`when: manual`).

1. 필수 [승인 규칙](#add-multiple-approval-rules)을 추가합니다.

프로젝트의 환경은 배포 전에 승인이 필요합니다.

### 여러 승인 규칙 추가 {#add-multiple-approval-rules}

{{< history >}}

- GitLab 15.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/345678)합니다. [기능 플래그 `deployment_approval_rules`](https://gitlab.com/gitlab-org/gitlab/-/issues/345678)가 제거되었습니다.
- UI 구성이 GitLab 15.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/378445)되었습니다.

{{< /history >}}

여러 승인 규칙을 추가하여 배포 작업을 승인하고 실행할 수 있는 사용자를 제어합니다.

여러 승인 규칙을 추가하려면 프로젝트에 대한 개발자 역할이 있어야 합니다. 그룹을 승인자로 추가하려면 [프로젝트에 그룹을 초대](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)해야 합니다. 초대된 그룹만 승인자 목록에 나타납니다.

여러 승인 규칙을 구성하려면 [CI/CD 설정](protected_environments.md#protecting-environments)을 사용합니다. [API를 사용](../../api/group_protected_environments.md#protect-a-single-environment)할 수도 있습니다.

환경으로 배포하는 모든 작업은 차단되고 실행 전에 승인을 기다립니다. 필수 승인 수가 배포할 수 있는 사용자 수보다 적은지 확인합니다.

사용자는 배포당 하나의 승인만 제공할 수 있습니다. 사용자가 여러 승인자 그룹의 구성원이더라도 마찬가지입니다. [이슈 457541](https://gitlab.com/gitlab-org/gitlab/-/issues/457541)은 동일한 사용자가 다른 승인자 그룹에서 배포당 여러 승인을 제공할 수 있도록 이 동작을 변경할 것을 제안합니다.

배포 작업이 승인된 후 [작업을 수동으로 실행](../jobs/job_control.md#run-a-manual-job)해야 합니다.

### 자체 승인 허용 {#allow-self-approval}

{{< history >}}

- GitLab 15.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/381418)되었습니다.
- 자동 승인이 GitLab 16.2에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124638)되었습니다([사용성 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/391258) 때문).

{{< /history >}}

기본적으로 배포 파이프라인을 트리거하는 사용자는 배포 작업도 승인할 수 없습니다.

GitLab 관리자는 모든 배포를 승인하거나 거부할 수 있습니다.

배포 작업의 자체 승인을 허용하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **보호 환경**을 확장합니다.
1. **승인 옵션**에서 **Allow pipeline triggerer to approve deployment** 확인란을 선택합니다.

## 배포 승인 또는 거부 {#approve-or-reject-a-deployment}

여러 승인 규칙이 있는 환경에서 다음을 수행할 수 있습니다:

- 배포를 승인하여 계속 진행할 수 있습니다.
- 배포를 거부하여 방지합니다.

전제 조건:

- 보호 환경으로 배포할 수 있는 권한이 있습니다.

배포를 승인 또는 거부하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. 환경의 이름을 선택합니다.
1. 배포를 찾고 **Status badge**를 선택합니다.
1. 선택 사항. 배포를 승인하거나 거부하는 이유를 설명하는 설명을 추가합니다.
1. **승인** 또는 **거부**를 선택합니다.

[API를 사용](../../api/deployments.md#approve-or-reject-a-deployment)할 수도 있습니다.

배포당 하나의 승인만 제공할 수 있습니다. 여러 승인자 그룹의 구성원이더라도 마찬가지입니다. [이슈 457541](https://gitlab.com/gitlab-org/gitlab/-/issues/457541)은 동일한 사용자가 다른 승인자 그룹에서 배포당 여러 승인을 제공할 수 있도록 이 동작을 변경할 것을 제안합니다.

배포 승인은 해당 배포 작업을 자동으로 시작하지 않습니다. [작업을 수동으로 실행](../jobs/job_control.md#run-a-manual-job)해야 합니다.

### 배포의 승인 세부 정보 보기 {#view-the-approval-details-of-a-deployment}

전제 조건:

- 보호 환경으로 배포할 수 있는 권한이 있습니다.

보호 환경으로의 배포는 필요한 모든 승인이 제공된 후에만 진행할 수 있습니다.

배포의 승인 세부 정보를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. 환경의 이름을 선택합니다.
1. 배포를 찾고 **Status badge**를 선택합니다.

승인 상태 세부 정보가 표시됩니다:

- 적격 승인자
- 부여된 승인 수 및 필요한 승인 수
- 승인을 부여한 사용자
- 승인 또는 거부 기록

## 차단된 배포 보기 {#view-blocked-deployments}

배포 차단 여부를 포함하여 배포의 상태를 검토합니다.

배포를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. 배포 중인 환경을 선택합니다.

**blocked** 레이블이 있는 배포는 차단됩니다.

배포의 승인 상태를 가져오려면 [API를 사용](../../api/deployments.md#retrieve-a-deployment)할 수도 있습니다. `status` 필드는 배포가 차단되었는지 여부를 나타냅니다.

## 관련 항목 {#related-topics}

- [배포 승인 기능 에픽](https://gitlab.com/groups/gitlab-org/-/epics/6832)
