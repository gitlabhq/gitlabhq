---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "계산, 할당량, 구매 정보."
title: 컴퓨팅 분 관리
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [이름이 바뀌었습니다](https://gitlab.com/groups/gitlab-com/-/epics/2150). GitLab 16.1에서 "CI/CD 분"에서 "컴퓨팅 할당량" 또는 "컴퓨팅 분"으로 변경되었습니다.

{{< /history >}}

관리자는 매월 [인스턴스 러너](../../ci/runners/runners_scope.md)에서 작업을 실행하는 데 프로젝트가 사용할 수 있는 시간을 제한할 수 있습니다. 이 제한은 [컴퓨팅 분 할당량](../../ci/pipelines/compute_minutes.md)으로 추적됩니다. 그룹 및 프로젝트 러너는 컴퓨팅 할당량의 영향을 받지 않습니다.

GitLab Self-Managed:

- 컴퓨팅 할당량은 기본적으로 비활성화되어 있습니다.
- 관리자는 네임스페이스가 월간 할당량을 모두 사용한 경우 [더 많은 컴퓨팅 분을 할당](#set-the-compute-quota-for-a-group)할 수 있습니다.
- [비용 계수](../../ci/pipelines/compute_minutes.md#compute-usage-calculation)는 모든 프로젝트에 대해 `1`입니다.

GitLab.com:

- 적용된 할당량 및 비용 계수에 대해 알아보려면 [컴퓨팅 분](../../ci/pipelines/compute_minutes.md)을 참조하세요.
- GitLab 팀 구성원으로서 컴퓨팅 분을 관리하려면 [GitLab.com을 위한 컴퓨팅 분 관리](dot_com_compute_minutes.md)를 참조하세요.

[작업을 트리거](../../ci/yaml/_index.md#trigger) 합니다는 러너에서 실행되지 않으므로, [`strategy:depend`](../../ci/yaml/_index.md#triggerstrategy) 을 사용할 때도 컴퓨팅 분을 소비하지 않습니다. [다운스트림 파이프라인](../../ci/pipelines/downstream_pipelines.md) 상태를 기다립니다. 트리거된 다운스트림 파이프라인은 다른 파이프라인과 동일하게 컴퓨팅 분을 소비합니다.

## 모든 네임스페이스에 대해 컴퓨팅 할당량 설정 {#set-the-compute-quota-for-all-namespaces}

기본적으로 GitLab 인스턴스에는 컴퓨팅 할당량이 없습니다. 할당량의 기본값은 `0`이며, 이는 무제한입니다.

전제 조건:

- GitLab 관리자여야 합니다.

모든 네임스페이스에 적용되는 기본 할당량을 변경하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **지속적 통합 및 배포**를 확장합니다.
1. **컴퓨팅 할당량** 상자에서 제한을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

특정 네임스페이스에 대해 할당량이 이미 정의된 경우, 이 값은 해당 할당량을 변경하지 않습니다.

## 그룹에 대해 컴퓨팅 할당량 설정 {#set-the-compute-quota-for-a-group}

전역 값을 재정의하고 그룹에 대해 컴퓨팅 할당량을 설정할 수 있습니다.

전제 조건:

- GitLab 관리자여야 합니다.
- 그룹은 최상위 그룹이어야 하며, 하위 그룹이 아니어야 합니다.

그룹 또는 네임스페이스에 대해 컴퓨팅 할당량을 설정하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **그룹**을 선택합니다.
1. 업데이트할 그룹에 대해 **편집**을 선택합니다.
1. **컴퓨팅 할당량** 상자에서 컴퓨팅 분의 최대 개수를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

[그룹 API 업데이트](../../api/groups.md#update-group-attributes) 또는 [사용자 API 업데이트](../../api/users.md#modify-a-user)를 대신 사용할 수도 있습니다.

## 컴퓨팅 사용량 재설정 {#reset-compute-usage}

관리자는 현재 달의 네임스페이스에 대해 컴퓨팅 사용량을 재설정할 수 있습니다.

### 개인 네임스페이스에 대한 사용량 재설정 {#reset-usage-for-a-personal-namespace}

1. [**운영자** 영역의 사용자](../admin_area.md#administering-users)를 찾습니다.
1. **편집**을 선택합니다.
1. **한도**에서 **컴퓨팅 사용량 재설정**을 선택합니다.

### 그룹 네임스페이스에 대한 사용량 재설정 {#reset-usage-for-a-group-namespace}

1. [**운영자** 영역의 그룹](../admin_area.md#administering-groups)을 찾습니다.
1. **편집**을 선택합니다.
1. **권한 및 그룹 기능**에서 **컴퓨팅 사용량 재설정**을 선택합니다.
