---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 인시던트
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

인시던트는 긴급하게 복구해야 하는 서비스 중단 또는 장애입니다. 인시던트는 인시던트 관리 워크플로에서 중요한 역할을 합니다. GitLab을 사용하여 인시던트를 분류, 대응 및 해결합니다.

## 인시던트 목록 {#incidents-list}

[인시던트 목록을 볼 때](manage_incidents.md#view-a-list-of-incidents) 다음이 포함됩니다:

- **상태**: 인시던트를 상태별로 필터링하려면 인시던트 목록 위에서 **열기**, **닫힘** 또는 **전체**를 선택합니다.
- **검색**: 인시던트 제목과 설명을 검색하거나 [목록을 필터링](#filter-the-incidents-list)합니다.
- **심각도**: 특정 인시던트의 심각도로, 다음 값 중 하나일 수 있습니다:
  - {{< icon name="severity-critical" >}} 중대 - S1
  - {{< icon name="severity-high" >}} 높음 - S2
  - {{< icon name="severity-medium" >}} 중간 - S3
  - {{< icon name="severity-low" >}} 낮음 - S4
  - {{< icon name="severity-unknown" >}} 알 수 없음
- **인시던트**: 가장 의미 있는 정보를 캡처하려고 시도하는 인시던트의 제목입니다.
- **상태**: 인시던트의 상태로, 다음 값 중 하나일 수 있습니다:
  - 트리거됨
  - 확인됨
  - 해결됨

  Premium 또는 Ultimate 티어에서 이 필드는 인시던트의 [온콜 에스컬레이션](paging.md#escalating-an-incident)에도 연결됩니다.

- **생성 날짜**: 인시던트가 생성된 지 경과한 시간입니다. 이 필드는 `X time ago`의 표준 GitLab 패턴을 사용합니다. 이 값을 마우스로 가리켜 로케일에 따라 형식화된 정확한 날짜와 시간을 확인합니다.
- **담당자**: 인시던트에 할당된 사용자입니다.
- **게시됨**: 인시던트가 [상태 페이지](status_page.md)에 게시되었는지 여부입니다.

![인시던트 목록](img/incident_list_v15_6.png)

인시던트 목록의 실제 예를 보려면 이 [데모 프로젝트](https://gitlab.com/gitlab-org/monitor/monitor-sandbox/-/incidents)를 참조합니다.

### 인시던트 목록 정렬 {#sort-the-incident-list}

인시던트 목록은 인시던트 생성 날짜별로 정렬된 인시던트를 표시하며 최신 항목을 먼저 표시합니다.

다른 열로 정렬하거나 정렬 순서를 변경하려면 열을 선택합니다.

정렬할 수 있는 열:

- 심각도
- 상태
- SLA까지 시간
- 게시됨

### 인시던트 목록 필터링 {#filter-the-incidents-list}

인시던트 목록을 작성자 또는 담당자별로 필터링하려면 검색 상자에 이 값을 입력합니다.

## 인시던트 세부 정보 {#incident-details}

### 요약 {#summary}

인시던트의 요약 섹션은 인시던트에 대한 중요한 세부 정보와 [선택된](alerts.md#trigger-actions-from-alerts) 이슈 템플릿의 내용을 제공합니다. 인시던트 상단의 강조 표시된 막대는 왼쪽에서 오른쪽으로 표시됩니다:

- 원본 알림에 대한 링크입니다.
- 알림 시작 시간입니다.
- 이벤트 수입니다.

강조 표시된 막대 아래의 요약은 다음 필드를 포함합니다:

- 시작 시간
- 심각도
- `full_query`
- 모니터링 도구

인시던트 요약은 [GitLab Flavored Markdown](../../user/markdown.md)을 사용하여 추가로 사용자 지정할 수 있습니다.

인시던트가 [알림에서 생성](alerts.md#trigger-actions-from-alerts)되고 인시던트에 대한 Markdown을 제공한 경우 Markdown이 요약에 추가됩니다. 프로젝트에 대해 인시던트 템플릿이 구성된 경우 템플릿 내용이 끝에 추가됩니다.

댓글은 스레드에 표시되지만 [최근 업데이트 보기를 켜서](#recent-updates-view) 시간 순서대로 표시할 수 있습니다.

인시던트를 변경하면 GitLab은 [시스템 노트](../../user/project/system_notes.md)를 생성하고 요약 아래에 표시합니다.

### 측정항목 {#metrics}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

대부분의 경우 인시던트는 측정항목과 연결됩니다. **측정항목** 탭에 측정항목 차트의 스크린샷을 업로드할 수 있습니다:

![인시던트 측정항목 탭](img/incident_metrics_tab_v13_8.png)

이미지를 업로드하면 이미지를 텍스트 또는 원본 그래프의 링크와 연결할 수 있습니다.

![텍스트 링크 모달](img/incident_metrics_tab_text_link_modal_v14_9.png)

링크를 추가하면 업로드된 이미지 위의 하이퍼링크를 선택하여 원본 그래프에 액세스할 수 있습니다.

### 알림 세부 정보 {#alert-details}

인시던트는 연결된 알림의 세부 정보를 별도 탭에 표시합니다. 이 탭을 채우려면 인시던트가 연결된 알림으로 생성되어야 합니다. 알림에서 자동으로 생성된 인시던트는 이 필드가 채워져 있습니다.

![인시던트 알림 세부 정보](img/incident_alert_details_v13_4.png)

### 타임라인 이벤트 {#timeline-events}

인시던트 타임라인은 인시던트 중에 발생한 일과 해결을 위해 취한 단계에 대한 높은 수준의 개요를 제공합니다.

[타임라인 이벤트](incident_timeline_events.md) 및 이 기능을 활성화하는 방법에 대해 자세히 알아봅니다.

### 최근 업데이트 보기 {#recent-updates-view}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

인시던트의 최신 업데이트를 보려면 댓글 표시줄에서 **최근 업데이트 보기 켜기** ({{< icon name="history" >}})를 선택합니다. 댓글은 스레드가 없이 표시되고 시간 순서대로 최신부터 오래된 순서로 표시됩니다.

### 서비스 수준 계약 카운트다운 타이머 {#service-level-agreement-countdown-timer}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

인시던트에서 서비스 수준 계약 카운트다운 타이머를 활성화하여 고객과 맺은 서비스 수준 계약(SLA)을 추적할 수 있습니다. 타이머는 인시던트가 생성될 때 자동으로 시작되며 SLA 기간이 만료되기 전 남은 시간을 표시합니다. 타이머는 15분마다 동적으로 업데이트되므로 남은 시간을 보기 위해 페이지를 새로 고칠 필요가 없습니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

타이머를 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **모니터링**을 선택합니다.
1. **인시던트** 섹션을 확장한 다음 **인시던트 설정** 탭을 선택합니다.
1. **"SLA까지 시간" 카운트다운 타이머 활성화**를 선택합니다.
1. 15분 단위로 시간 제한을 설정합니다.
1. **변경사항 저장**을 선택합니다.

SLA 카운트다운 타이머를 활성화한 후에는 **SLA까지 시간** 열을 인시던트 목록과 새 인시던트의 필드로 사용할 수 있습니다. SLA 기간이 끝나기 전에 인시던트가 종료되지 않으면 GitLab은 `missed::SLA` 레이블을 인시던트에 추가합니다.

## 관련 항목 {#related-topics}

- [인시던트 생성](manage_incidents.md#create-an-incident)
- 알림이 트리거될 때마다 [인시던트를 자동으로 생성](alerts.md#trigger-actions-from-alerts)합니다
- [인시던트 목록 보기](manage_incidents.md#view-a-list-of-incidents)
- [사용자에게 할당](manage_incidents.md#assign-to-a-user)
- [인시던트 심각도 변경](manage_incidents.md#change-severity)
- [인시던트 상태 변경](manage_incidents.md#change-status)
- [에스컬레이션 정책 변경](manage_incidents.md#change-escalation-policy)
- [인시던트 종료](manage_incidents.md#close-an-incident)
- [복구 알림을 통해 인시던트 자동 종료](manage_incidents.md#automatically-close-incidents-via-recovery-alerts)
- [할 일 항목 추가](../../user/todos.md#create-a-to-do-item)
- [레이블 추가](../../user/project/labels.md)
- [마일스톤 할당](../../user/project/milestones/_index.md)
- [인시던트를 기밀로 설정](../../user/project/issues/confidential_issues.md)
- [마감일 설정](../../user/project/issues/due_dates.md)
- [알림 켜고 끄기](../../user/profile/notifications.md#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic)
- [소요 시간 추적](../../user/project/time_tracking.md)
- [인시던트에 Zoom 회의 추가](../../user/project/issues/associate_zoom_meeting.md)는 이슈에 추가하는 방식과 동일합니다
- [인시던트의 연결된 리소스](linked_resources.md)
- 인시던트를 생성하고 [Slack에서 직접](slack.md) 인시던트 알림을 받습니다
- [Issues API](../../api/issues.md)를 사용하여 인시던트와 상호 작용합니다
