---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab에서 알림 및 페이징을 구성하고, Slack, 이메일, 그리고 온콜 응답자를 위한 에스컬레이션 정책을 포함하여 경고 및 인시던트를 관리합니다."
title: 페이징 및 알림
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

새로운 경고 또는 인시던트가 발생하면 응답자가 즉시 알림을 받아 문제를 분류하고 대응할 수 있어야 합니다. 응답자는 이 페이지에 설명된 방법을 사용하여 알림을 받을 수 있습니다.

## Slack 알림 {#slack-notifications}

Slack용 GitLab 앱을 사용하여 중요한 인시던트 알림을 받을 수 있습니다.

[Slack용 GitLab 앱이 구성되면](slack.md), 새로운 인시던트가 선언될 때마다 인시던트 응답자가 Slack에서 알림을 받습니다. 모바일 디바이스에서 중요한 인시던트 알림을 놓치지 않으려면 휴대전화에서 Slack에 대한 알림을 활성화하세요.

## 알림에 대한 이메일 알림 {#email-notifications-for-alerts}

이메일 알림은 트리거된 경고에 대해 프로젝트에서 사용할 수 있습니다. **소유자** 또는 **유지관리자** 역할을 가진 프로젝트 멤버는 새 경고에 대한 단일 이메일 알림을 받을 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **모니터링**을 선택합니다.
1. **경고**를 확장합니다.
1. **경고 설정** 탭에서 **Send a single email notification to Owners and Maintainers for new alerts** 체크박스를 선택합니다.
1. **변경사항 저장**을 선택합니다.

[경고 상태 업데이트](alerts.md#change-an-alerts-status)를 통해 경고에 대한 이메일 알림을 관리합니다.

## 페이징 {#paging}

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[에스컬레이션 정책](escalation_policies.md)이 구성된 프로젝트에서 온콜 응답자는 이메일을 통해 중요한 문제에 대해 자동으로 알림을 받을 수 있습니다.

### 경고 에스컬레이션 {#escalating-an-alert}

경고가 트리거되면 즉시 온콜 응답자로 에스컬레이션이 시작됩니다. 프로젝트의 에스컬레이션 정책의 각 에스컬레이션 규칙에 대해, 지정된 온콜 응답자는 규칙이 발동될 때 하나의 이메일을 받습니다. [경고 상태 업데이트](alerts.md#change-an-alerts-status)를 통해 페이지에 응답하거나 경고 에스컬레이션을 중지할 수 있습니다.

### 인시던트 에스컬레이션 {#escalating-an-incident}

{{< history >}}

- GitLab 14.9에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/5716), [플래그 포함](../../administration/feature_flags/_index.md) `incident_escalations`. 기본적으로 비활성화되어 있습니다.
- GitLab 14.10에서 [GitLab.com 및 GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/345769).
- [기능 플래그 `incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769)는 GitLab 15.1에서 제거되었습니다.

{{< /history >}}

인시던트의 경우 온콜 응답자 페이징은 각 개별 인시던트에 대해 선택사항입니다.

인시던트 에스컬레이션을 시작하려면 [인시던트의 에스컬레이션 정책 설정](manage_incidents.md#change-escalation-policy)합니다.

각 에스컬레이션 규칙에 대해, 지정된 온콜 응답자는 규칙이 발동될 때 하나의 이메일을 받습니다. [인시던트 상태 변경](manage_incidents.md#change-status) 또는 인시던트의 에스컬레이션 정책을 **No escalation policy**으로 다시 변경하여 페이지에 응답하거나 인시던트 에스컬레이션을 중지합니다.

GitLab 15.1 이하에서는 [경고에서 생성된 인시던트](manage_incidents.md#from-an-alert)가 독립적인 에스컬레이션을 지원하지 않습니다. [GitLab 15.2 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/356057)에서는 모든 인시던트를 독립적으로 에스컬레이션할 수 있습니다.
