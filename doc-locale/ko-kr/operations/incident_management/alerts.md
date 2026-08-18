---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab에서 경고를 이해하고 관리합니다. 경고 목록 보기, 상태 변경, 경고 할당, 작업 트리거, 온콜 알림에 응답하는 방법을 포함합니다."
title: 경고
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

경고는 인시던트 관리 워크플로우에서 중요한 항목입니다. 서비스 중단이나 장애를 나타낼 수 있는 주목할 만한 이벤트를 나타냅니다. GitLab은 분류를 위한 목록 보기와 발생한 상황을 자세히 조사하기 위한 상세 보기를 제공합니다.

## 경고 목록 {#alert-list}

Developer, Maintainer, Owner 역할이 있는 사용자는 프로젝트의 사이드바에서 **모니터링** > **경고**에 있는 경고 목록에 액세스할 수 있습니다. 경고 목록은 시작 시간 순서로 정렬된 경고를 표시하지만 경고 목록의 헤더를 선택하여 정렬 순서를 변경할 수 있습니다.

경고 목록은 다음 정보를 표시합니다:

![열린 경고에 대한 세부정보를 보여주는 경고 목록](img/alert_list_v13_1.png)

- **검색**: 경고 목록은 제목, 설명, 모니터링 도구 및 서비스 필드에 대한 간단한 자유 텍스트 검색을 지원합니다.
- **심각도**: 경고의 현재 중요도와 주의해야 할 정도입니다. 모든 상태의 목록을 보려면 [경고 관리 심각도](#alert-severity)를 읽으세요.
- **시작 시간**: 경고가 발생한 시간을 표시합니다. 이 필드는 `X time ago` 의 표준 GitLab 패턴을 사용하지만 사용자의 로케일에 따라 세부적인 날짜/시간 툴팁으로 지원됩니다.
- **Alert description**: 경고 설명으로, 가장 의미 있는 데이터를 캡처하려고 합니다.
- **Event count**: 경고가 발생한 횟수입니다.
- **이슈**: 경고에 대해 생성된 인시던트 이슈로의 링크입니다.
- **상태**: 경고의 현재 상태입니다:
  - **트리거됨**: 조사가 시작되지 않았습니다.
  - **확인됨**: 누군가 적극적으로 문제를 조사 중입니다.
  - **해결됨**: 추가 작업이 필요하지 않습니다.
  - **무시됨**: 경고에 대해 조치를 취하지 않습니다.

## 경고 심각도 {#alert-severity}

각 경고 수준에는 특정 경고의 심각도를 식별하는 데 도움이 되는 고유하게 형성되고 색상으로 코딩된 아이콘이 포함되어 있습니다. 이러한 심각도 아이콘은 조사 우선순위를 정해야 할 경고를 즉시 식별하는 데 도움이 됩니다:

![중요, 높음, 중간, 낮음, 정보 및 알 수 없음 수준에 대해 서로 다른 색상과 도형을 보여주는 경고 심각도 아이콘](img/alert_management_severity_v13_0.png)

경고에는 다음 아이콘 중 하나가 포함되어 있습니다:

<!-- vale gitlab_base.SubstitutionWarning = NO -->

| 심각도 | 아이콘                    | 색상(16진수) |
|----------|-------------------------|---------------------|
| 중요 | {{< icon name="severity-critical" >}} | `#8b2615`           |
| 높음     | {{< icon name="severity-high" >}}     | `#c0341d`           |
| 중간   | {{< icon name="severity-medium" >}}   | `#fca429`           |
| 낮음      | {{< icon name="severity-low" >}}      | `#fdbc60`           |
| 정보     | {{< icon name="severity-info" >}}     | `#418cd8`           |
| 알 수 없음  | {{< icon name="severity-unknown" >}}  | `#bababa`           |

<!-- vale gitlab_base.SubstitutionWarning = YES -->

## 경고 세부정보 페이지 {#alert-details-page}

[경고 목록](#alert-list)으로 이동하여 목록에서 경고를 선택하여 경고 세부정보 보기로 이동합니다. 경고에 액세스하려면 Developer, Maintainer, Owner 역할이 필요합니다. 목록에서 경고를 선택하여 경고 세부정보 페이지를 확인합니다.

경고는 **개요** 및 **경고 세부정보** 탭을 제공하여 필요한 적절한 정보를 제공합니다.

### 경고 세부정보 탭 {#alert-details-tab}

**경고 세부정보** 탭에는 두 개의 섹션이 있습니다. 위쪽 섹션은 심각도, 시작 시간, 이벤트 수 및 소스 모니터링 도구 등 중요한 세부정보의 짧은 목록을 제공합니다. 두 번째 섹션은 전체 경고 페이로드를 표시합니다.

### 측정항목 탭 {#metrics-tab}

많은 경우 경고는 측정항목과 연결되어 있습니다. **측정항목** 탭에 측정항목 차트의 스크린샷을 업로드할 수 있습니다.

이를 수행하려면 다음 중 하나를 수행합니다:

- **upload**를 선택한 다음 파일 브라우저에서 이미지를 선택합니다.
- 파일 브라우저에서 파일을 드래그하여 드롭 영역에 놓습니다.

이미지를 업로드하면 이미지에 텍스트를 추가하고 원본 그래프로 링크할 수 있습니다.

![텍스트 링크를 추가하는 옵션이 있는 인시던트 측정항목 탭](img/incident_metrics_tab_text_link_modal_v14_9.png)

링크를 추가하면 업로드된 이미지 위에 표시됩니다.

### 활동 피드 탭 {#activity-feed-tab}

**활동 피드** 탭은 경고에 대한 활동의 로그입니다. 경고에 대해 조치를 취하면 이는 시스템 노트로 기록됩니다. 이는 경고의 조사 및 할당 이력의 시간 순서를 제공합니다.

다음 작업은 시스템 노트를 생성합니다:

- [경고 상태 업데이트](#change-an-alerts-status)
- [경고에 기반한 인시던트 생성](manage_incidents.md#from-an-alert)
- [사용자에게 경고 할당](#assign-an-alert)
- [온콜 응답자에게 경고 에스컬레이션](paging.md#escalating-an-alert)

![세 개의 시스템 노트를 보여주는 GitLab 경고 활동 피드](img/alert_detail_activity_feed_v13_5.png)

## 경고 작업 {#alert-actions}

경고를 분류하고 응답하는 데 도움이 되는 GitLab에서 사용할 수 있는 다양한 작업이 있습니다.

### 경고 상태 변경 {#change-an-alerts-status}

경고의 상태를 변경할 수 있습니다.

사용 가능한 상태는 다음과 같습니다:

- 트리거됨(새 경고의 기본값)
- 확인됨
- 해결됨

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

경고의 상태를 변경하려면:

- [경고 목록](#alert-list)에서:
  1. **상태** 열에서 경고 옆의 상태 드롭다운 목록을 선택합니다.
  1. 상태를 선택합니다.
- [경고 세부정보 페이지](#alert-details-page)에서:
  1. 오른쪽 사이드바에서 **편집**을 선택합니다.
  1. 상태를 선택합니다.

[이메일 알림이 활성화된](paging.md#email-notifications-for-alerts) 프로젝트에서 경고 재발에 대한 이메일 알림을 중지하려면 경고의 상태를 **트리거됨**에서 변경합니다.

#### 연결된 인시던트를 닫아 경고 해결 {#resolve-an-alert-by-closing-the-linked-incident}

전제 조건:

- Reporter, Developer, Maintainer, Owner 역할이 필요합니다.

경고에 연결된 [인시던트를 닫으면](manage_incidents.md#close-an-incident) GitLab은 [경고의 상태를 변경합니다](#change-an-alerts-status) **해결됨**으로. 그러면 경고의 상태 변경에 대해 인정됩니다.

#### 온콜 응답자로서 {#as-an-on-call-responder}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

온콜 응답자는 경고 상태를 변경하여 [경고 페이지](paging.md#escalating-an-alert)에 응답할 수 있습니다.

상태를 변경하면 다음과 같은 효과가 있습니다:

- **확인됨**으로: 프로젝트의 [에스컬레이션 정책](escalation_policies.md)을(를) 기반으로 온콜 페이지를 제한합니다.
- **해결됨**으로: 경고에 대한 모든 온콜 페이지를 음소거합니다.
- **해결됨**에서 **트리거됨**으로: 경고 에스컬레이션을 다시 시작합니다.

GitLab 15.1 이전에서는 [연결된 인시던트가 있는 경고](manage_incidents.md#from-an-alert)의 상태를 업데이트하면 인시던트 상태도 업데이트됩니다. [GitLab 15.2 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/356057)에서는 인시던트 상태가 독립적이며 경고 상태가 변경될 때 업데이트되지 않습니다.

### 경고 할당 {#assign-an-alert}

대규모 팀에서 경고의 소유권이 공유되는 경우 누가 조사하고 작업 중인지 추적하기 어려울 수 있습니다. 경고를 할당하면 어느 사용자가 경고를 소유하고 있는지 나타냄으로써 협업과 위임이 용이해집니다. GitLab은 경고당 단 하나의 담당자만 지원합니다.

경고를 할당하려면:

1. 현재 경고 목록을 표시합니다:

   1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
   1. **모니터링** > **경고**를 선택합니다.

1. 원하는 경고를 선택하여 세부정보를 표시합니다.

   ![오른쪽 사이드바가 확장되어 사용자를 할당하거나 할당 해제하기 위한 담당자 드롭다운 목록을 보여주는 경고 세부정보 페이지](img/alert_details_assignees_v13_1.png)

1. 오른쪽 사이드바가 확장되지 않은 경우 **사이드바 펼침**({{< icon name="chevron-double-lg-right" >}})을 선택하여 확장합니다.

1. 오른쪽 사이드바에서 **%d 담당자**를 찾은 다음 **편집**을 선택합니다. 목록에서 경고에 할당할 각 사용자를 선택합니다. GitLab은 각 사용자에 대해 [할 일 항목](../../user/todos.md)을 생성합니다.

경고 조사 또는 수정의 자신의 부분을 완료한 후 사용자는 경고에서 자신을 할당 해제할 수 있습니다. 담당자를 제거하려면 **편집**을(를) **%d 담당자** 드롭다운 목록 옆에 선택하고 담당자 목록에서 사용자를 제거하거나 **지정되지 않음**을(를) 선택합니다.

### 경고에서 할 일 항목 만들기 {#create-a-to-do-item-from-an-alert}

경고에서 직접 [할 일 항목](../../user/todos.md)을(를) 만들고 나중에 **할 일 목록**에서 볼 수 있습니다.

할 일 항목을 추가하려면 오른쪽 사이드바에서 **할 일 항목 추가**를 선택합니다.

### 경고에서 작업 트리거 {#trigger-actions-from-alerts}

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

경고가 트리거될 때마다 [인시던트](incidents.md) 생성을 자동으로 켭니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

작업을 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **모니터링**을 선택합니다.
1. **경고** 섹션을 확장한 다음 **경고 설정** 탭을 선택합니다.
1. **Create an incident** 확인란을 선택합니다.
1. 선택 사항. 인시던트를 사용자 지정하려면 **Incident template**에서 템플릿을 선택하여 [인시던트 요약](incidents.md#summary)에 추가합니다. 드롭다운 목록이 비어 있으면 먼저 [이슈 템플릿을 만듭니다](../../user/project/description_templates.md#create-a-description-template).
1. 선택 사항. [이메일 알림](paging.md#email-notifications-for-alerts)을(를) 보내려면 **Send a single email notification to Owners and Maintainers for new alerts** 확인란을 선택합니다.
1. **변경사항 저장**을 선택합니다.
