---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab에서 인시던트를 생성, 할당, 업데이트 및 해결하고 에스컬레이션 정책을 변경합니다."
title: 인시던트 관리
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [인시던트](_index.md)를 반복에 추가하는 기능이 [GitLab 17.0에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/347153)되었습니다.

{{< /history >}}

이 페이지에서는 [인시던트](incidents.md)로 수행할 수 있는 모든 작업의 지침을 수집합니다.

## 인시던트 생성 {#create-an-incident}

인시던트를 수동으로 또는 자동으로 생성할 수 있습니다.

## 인시던트를 반복에 추가 {#add-an-incident-to-an-iteration}

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

인시던트를 [반복](../../user/group/iterations/_index.md)에 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 인시던트로 이동:
   - 문제 목록의 인시던트의 경우 **계획** > **작업 항목**을 선택하고 **유형** = **인시던트**로 필터링합니다.
   - 모니터 목록의 인시던트의 경우 **모니터링** > **인시던트**를 선택합니다.
1. 인시던트를 선택합니다.
1. 오른쪽 사이드바의 **이터레이션** 섹션에서 **편집**을 선택합니다.
1. 드롭다운 목록에서 이 인시던트에 추가할 반복을 선택합니다.
1. 드롭다운 목록 외부의 영역을 선택합니다.

또는 [`/iteration` 빠른 작업](../../user/project/quick_actions.md#iteration)을 사용할 수 있습니다.

### 인시던트 페이지에서 {#from-the-incidents-page}

전제 조건:

- 프로젝트의 보고자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

**인시던트** 페이지에서 인시던트를 생성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **인시던트**를 선택합니다.
1. **인시던트 생성**을 선택합니다.

### 작업 항목 페이지에서 {#from-the-work-items-page}

전제 조건:

- 프로젝트의 보고자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

**작업 항목** 페이지에서 인시던트를 생성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택한 후 **새 항목**을 선택합니다.
1. **유형** 드롭다운 목록에서 **인시던트**를 선택합니다. 인시던트와 관련된 필드만 페이지에서 사용 가능합니다.
1. **인시던트 생성**을 선택합니다.

### 경고에서 {#from-an-alert}

[경고](alerts.md)를 볼 때 인시던트 문제를 생성합니다. 인시던트 설명은 경고에서 채워집니다.

전제 조건:

- 프로젝트의 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

경고에서 인시던트를 생성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **경고**를 선택합니다.
1. 원하는 경고를 선택합니다.
1. **인시던트 생성**을 선택합니다.

인시던트가 생성된 후 경고에서 보려면 **인시던트 보기**를 선택합니다.

[인시던트를 종료](#close-an-incident)하고 경고에 연결되어 있으면 GitLab이 [경고 상태를 변경](alerts.md#change-an-alerts-status)하여 **해결됨**으로 설정합니다. 그 후 경고의 상태 변경에 대한 크레딧을 받습니다.

### 경고가 트리거될 때 자동으로 {#automatically-when-an-alert-is-triggered}

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

프로젝트 설정에서 경고가 트리거될 때마다 [인시던트 자동 생성](alerts.md#trigger-actions-from-alerts)을 켤 수 있습니다.

### PagerDuty 웹후크 사용 {#using-the-pagerduty-webhook}

{{< history >}}

- [PagerDuty V3 웹후크](https://support.pagerduty.com/docs/webhooks) 지원이 [GitLab 15.7에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/383029)되었습니다.

{{< /history >}}

PagerDuty를 사용하여 웹후크를 설정하여 각 PagerDuty 인시던트에 대해 GitLab 인시던트를 자동으로 생성할 수 있습니다. 이 구성을 위해서는 PagerDuty와 GitLab 모두에서 변경을 해야 합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

PagerDuty를 사용하여 웹후크를 설정하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **모니터링**을 선택합니다
1. **인시던트**를 확장합니다.
1. **PagerDuty 통합** 탭을 선택합니다.
1. **활성** 토글을 켭니다.
1. **통합 저장**을 선택합니다.
1. **Webhook URL**의 값을 복사하여 나중 단계에서 사용합니다.
1. 웹후크 URL을 PagerDuty 웹후크 통합에 추가하려면 [PagerDuty 설명서](https://support.pagerduty.com/docs/webhooks#manage-v3-webhook-subscriptions)에 설명된 단계를 따릅니다.

통합이 성공했는지 확인하려면 PagerDuty에서 테스트 인시던트를 트리거하여 GitLab 인시던트가 생성되었는지 확인합니다.

## 인시던트 목록 보기 {#view-a-list-of-incidents}

[인시던트](incidents.md#incidents-list) 목록을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **인시던트**를 선택합니다.

인시던트의 [세부 정보 페이지](incidents.md#incident-details)를 보려면 목록에서 선택합니다.

### 인시던트를 볼 수 있는 사람 {#who-can-view-an-incident}

{{< history >}}

- [최소 사용자 역할이 보고자에서 플래너로 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)되었습니다(GitLab 17.7).

{{< /history >}}

인시던트를 볼 수 있는지 여부는 [프로젝트 가시성 수준](../../user/public_access.md) 및 인시던트의 기밀 상태에 따라 다릅니다:

- 공개 프로젝트 및 비기밀 인시던트: 누구나 인시던트를 볼 수 있습니다.
- 비공개 프로젝트 및 비기밀 인시던트: 프로젝트의 게스트, 플래너, 보고자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.
- 기밀 인시던트(프로젝트 가시성과 무관): 프로젝트의 플래너, 보고자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

## 사용자에게 할당 {#assign-to-a-user}

활동적으로 응답 중인 사용자에게 인시던트를 할당합니다.

전제 조건:

- 프로젝트의 보고자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

사용자를 할당하려면:

1. 인시던트에서 오른쪽 사이드바의 **담당자** 옆에 **편집**을 선택합니다.
1. 드롭다운 목록에서 하나 또는 [여러 사용자](../../user/project/issues/multiple_assignees_for_issues.md)를 선택하여 **assignees**로 추가합니다.
1. 드롭다운 목록 외부의 영역을 선택합니다.

## 심각도 변경 {#change-severity}

[인시던트 목록](incidents.md#incidents-list) 주제에서 사용 가능한 심각도 수준에 대한 전체 설명을 참조하세요.

전제 조건:

- 프로젝트의 보고자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

인시던트의 심각도를 변경하려면:

1. 인시던트에서 오른쪽 사이드바의 **심각도** 옆에 **편집**을 선택합니다.
1. 드롭다운 목록에서 새로운 심각도를 선택합니다.

[`/severity` 빠른 작업](../../user/project/quick_actions.md#severity)을 사용하여 심각도를 변경할 수도 있습니다.

## 상태 변경 {#change-status}

{{< history >}}

- [GitLab 14.9에서 도입](https://gitlab.com/groups/gitlab-org/-/epics/5716)됨 [플래그](../../administration/feature_flags/_index.md) 이름 `incident_escalations`. 기본적으로 비활성화되어 있습니다.
- [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/345769)됨(GitLab 14.10).
- [기능 플래그 `incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) (GitLab 15.1)에서 제거됨.

{{< /history >}}

전제 조건:

- 프로젝트의 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

인시던트의 상태를 변경하려면:

1. 인시던트에서 오른쪽 사이드바의 **상태** 옆에 **편집**을 선택합니다.
1. 드롭다운 목록에서 새로운 심각도를 선택합니다.

**트리거됨**은 새 인시던트의 기본 상태입니다.

### 온콜 응답자로서 {#as-an-on-call-responder}

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

온콜 응답자는 상태를 변경하여 [인시던트 페이지](paging.md#escalating-an-incident)에 응답할 수 있습니다.

상태 변경의 영향은 다음과 같습니다:

- **확인됨**으로: 프로젝트의 [에스컬레이션 정책](escalation_policies.md)에 따라 온콜 페이지를 제한합니다.
- **해결됨**으로: 인시던트의 모든 온콜 페이지를 음소거합니다.
- **해결됨**에서 **트리거됨**으로: 인시던트 에스컬레이션을 다시 시작합니다.

GitLab 15.1 이상에서 [경고에서 생성된 인시던트](#from-an-alert)의 상태를 변경하면 경고 상태도 변경됩니다. [GitLab 15.2 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/356057)에서는 경고 상태가 독립적이며 인시던트 상태가 변경되어도 변경되지 않습니다.

## 에스컬레이션 정책 변경 {#change-escalation-policy}

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- 프로젝트의 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

인시던트의 에스컬레이션 정책을 변경하려면:

1. 인시던트에서 오른쪽 사이드바의 **에스컬레이션 정책** 옆에 **편집**을 선택합니다.
1. 드롭다운 목록에서 에스컬레이션 정책을 선택합니다.

기본적으로 새 인시던트에는 선택된 에스컬레이션 정책이 없습니다.

에스컬레이션 정책을 선택하면 [인시던트 상태를 변경](#change-status)하여 **트리거됨**으로 설정하고 [온콜 응답자에게 인시던트를 에스컬레이션](paging.md#escalating-an-incident)합니다.

GitLab 15.1 이상에서 [경고에서 생성된 인시던트](#from-an-alert)의 에스컬레이션 정책은 경고의 에스컬레이션 정책을 반영하며 변경할 수 없습니다. [GitLab 15.2 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/356057)에서는 인시던트 에스컬레이션 정책이 독립적이며 변경할 수 있습니다.

## 인시던트 종료 {#close-an-incident}

전제 조건:

- 프로젝트의 보고자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

인시던트를 종료하려면 오른쪽 위 모서리에서 **Incident actions** ({{< icon name="ellipsis_v" >}}) 다음 **Close incident**를 선택합니다.

[경고](alerts.md)에 연결된 인시던트를 종료하면 연결된 경고의 상태가 **해결됨**으로 변경됩니다. 그 후 경고의 상태 변경에 대한 크레딧을 받습니다.

### 복구 경고를 통해 인시던트를 자동으로 종료 {#automatically-close-incidents-via-recovery-alerts}

GitLab이 HTTP 또는 Prometheus 웹후크에서 복구 경고를 수신할 때 인시던트 종료를 자동으로 켭니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

설정을 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **모니터링**을 선택합니다.
1. **인시던트** 섹션을 확장합니다.
1. **Automatically close associated incident** 체크박스를 선택합니다.
1. **변경사항 저장**을 선택합니다.

GitLab이 [복구 경고](integrations.md#recovery-alerts)를 수신하면 관련 인시던트를 종료합니다. 이 작업은 GitLab 경고 봇에 의해 자동으로 종료되었음을 나타내는 인시던트의 시스템 메모로 기록됩니다.

## 인시던트 삭제 {#delete-an-incident}

전제 조건:

- 프로젝트의 소유자 역할이 있어야 합니다.

인시던트를 삭제하려면:

1. 인시던트에서 **Incident actions** ({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **Delete incident**를 선택합니다.

또는:

1. 인시던트에서 **편집**을 선택합니다.
1. **Delete incident**를 선택합니다.

## 기타 작업 {#other-actions}

GitLab의 인시던트는 [이슈](../../user/project/issues/_index.md) 위에 구축되어 있으므로 다음과 같은 작업을 공통으로 수행할 수 있습니다:

- [할 일 항목 추가](../../user/todos.md#create-a-to-do-item)
- [레이블 추가](../../user/project/labels.md#assign-and-unassign-labels)
- [마일스톤 할당](../../user/project/milestones/_index.md#assign-a-milestone-to-an-item)
- [인시던트를 기밀로 설정](../../user/project/issues/confidential_issues.md)
- [기한 설정](../../user/project/issues/due_dates.md)
- [알림 토글](../../user/profile/notifications.md#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic)
- [소비된 시간 추적](../../user/project/time_tracking.md)
