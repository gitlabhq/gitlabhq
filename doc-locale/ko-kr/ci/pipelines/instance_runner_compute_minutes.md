---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "인스턴스 러너의 컴퓨팅 분, 구매, 사용 추적, 할당량 관리(GitLab.com 및 GitLab Self-Managed)."
title: 인스턴스 러너의 컴퓨팅 사용량
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

프로젝트에서 admin-managed [인스턴스 러너](../runners/runners_scope.md#instance-runners)에 대한 작업을 실행하기 위해 사용할 수 있는 컴퓨팅 분 사용량은 제한됩니다. 이 제한은 GitLab 서버의 인스턴스 러너 컴퓨팅 할당량으로 추적됩니다. 네임스페이스가 할당량을 초과하면 [할당량이 적용됩니다](#enforcement).

Admin-managed 인스턴스 러너는 GitLab 인스턴스 관리자가 [관리하는 항목](../../administration/cicd/compute_minutes.md)입니다.

> [!note]
> GitLab.com의 인스턴스 러너는 인스턴스가 GitLab에서 관리되므로 admin-managed 및 GitLab-hosted입니다.

## 컴퓨팅 할당량 적용 {#compute-quota-enforcement}

### 월간 재설정 {#monthly-reset}

컴퓨팅 분 사용량은 월간 `0`로 재설정됩니다. 컴퓨팅 할당량은 [월간 할당량으로 재설정](https://about.gitlab.com/pricing/)됩니다.

예를 들어, 월간 할당량이 10,000개의 컴퓨팅 분인 경우:

1. 4월 1일에는 10,000개의 컴퓨팅 분을 사용할 수 있습니다.
1. 4월 동안 할당량에서 사용 가능한 10,000개의 컴퓨팅 분 중 6,000개를 사용합니다.
1. 5월 1일에 누적된 컴퓨팅 사용량이 0으로 재설정되고 5월에 10,000개의 컴퓨팅 분을 사용할 수 있습니다.

이전 달의 사용 데이터는 시간 경과에 따른 소비의 과거 보기를 표시하기 위해 유지됩니다.

### 알림 {#notifications}

남은 컴퓨팅 분이 다음 경우에 앱 내 배너가 표시되고 네임스페이스 소유자에게 이메일 알림이 전송됩니다:

- 할당량의 25% 미만.
- 할당량의 5% 미만.
- 완전히 사용됨 (남은 분이 0).

### 적용 {#enforcement}

현재 달의 컴퓨팅 할당량이 사용되면 인스턴스 러너는 새 작업 처리를 중지합니다. 이미 시작된 파이프라인에서:

- 인스턴스 러너로 처리해야 하는 대기 중인 작업 (아직 시작되지 않음) 또는 재시도된 작업이 삭제됩니다.
- 인스턴스 러너에서 실행 중인 작업은 전체 네임스페이스 사용량이 1,000개의 컴퓨팅 분으로 초과될 때까지 계속 실행될 수 있습니다. 1,000개의 컴퓨팅 분 유예 기간 후 남은 실행 중인 작업도 삭제됩니다.

그룹 러너 및 프로젝트 러너는 컴퓨팅 할당량의 영향을 받지 않으며 작업 처리를 계속합니다.

## 사용량 보기 {#view-usage}

그룹 또는 개인 네임스페이스의 컴퓨팅 사용량 (추가 분 포함)을 [추가 분](../../subscriptions/gitlab_com/compute_minutes.md)을 포함하여 보고 컴퓨팅 사용량 추세 및 남은 컴퓨팅 분을 파악할 수 있습니다.

경우에 따라 할당량 제한은 다음 레이블 중 하나로 대체됩니다:

- **무제한**: 무제한 컴퓨팅 할당량이 있는 네임스페이스의 경우.
- **지원되지 않음**: 인스턴스 러너가 활성화되지 않은 네임스페이스의 경우.

### 그룹의 사용량 보기 {#view-usage-for-a-group}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

그룹의 컴퓨팅 사용량을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다. 그룹은 하위 그룹이 아니어야 합니다.
1. **설정** > **사용 할당량**을 선택합니다.
1. **파이프라인** 탭을 선택합니다.

프로젝트 목록에는 현재 달에만 컴퓨팅 사용량 또는 인스턴스 러너 사용량이 있는 프로젝트가 표시됩니다. 목록에는 네임스페이스 및 해당 하위 그룹의 모든 프로젝트가 포함되며 컴퓨팅 사용량의 내림차순으로 정렬됩니다.

### 개인 네임스페이스의 사용량 보기 {#view-usage-for-a-personal-namespace}

개인 네임스페이스의 컴퓨팅 사용량을 볼 수 있습니다:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **사용 할당량**을 선택합니다.

프로젝트 목록에는 현재 달에만 컴퓨팅 사용량 또는 인스턴스 러너 사용량이 있는 [개인 프로젝트](../../user/project/working_with_projects.md)가 표시됩니다.
