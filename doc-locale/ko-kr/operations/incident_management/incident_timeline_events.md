---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "인시던트를 보고, 생성하고, 편집하고, 해결하며, 인시던트 심각도, 상태 및 상향 보고 정책을 변경합니다."
title: 타임라인 이벤트
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/344059)되었으며 [플래그](../../administration/feature_flags/_index.md) `incident_timeline`이(가) 있습니다. 기본적으로 활성화됩니다.
- [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/353426) GitLab 15.3
- GitLab 15.5에서 [일반적으로 사용 가능합니다](https://gitlab.com/gitlab-org/gitlab/-/issues/353426). [기능 플래그 `incident_timeline`](https://gitlab.com/gitlab-org/gitlab/-/issues/343386)가 제거되었습니다.

{{< /history >}}

인시던트 타임라인은 인시던트 기록 유지의 중요한 부분입니다. 타임라인은 임원진과 외부 검토자에게 인시던트 중에 발생한 상황과 이를 해결하기 위해 취한 단계를 표시할 수 있습니다.

## 타임라인 보기 {#view-the-timeline}

인시던트 타임라인 이벤트는 날짜와 시간의 오름차순으로 나열됩니다. 이벤트는 날짜로 그룹화되며 발생한 시간의 오름차순으로 나열됩니다:

![인시던트 타임라인 이벤트 목록](img/timeline_events_v15_1.png)

인시던트의 이벤트 타임라인을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **인시던트**를 선택합니다.
1. 인시던트를 선택합니다.
1. **타임라인** 탭을 선택합니다.

## 이벤트 생성 {#create-an-event}

GitLab에서 타임라인 이벤트를 여러 방법으로 생성할 수 있습니다.

### 양식 사용 {#using-the-form}

양식을 사용하여 타임라인 이벤트를 수동으로 생성합니다.

전제 조건:

- 프로젝트에 대한 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

타임라인 이벤트를 생성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **인시던트**를 선택합니다.
1. 인시던트를 선택합니다.
1. **타임라인** 탭을 선택합니다.
1. **새 타임라인 이벤트 추가**를 선택합니다.
1. 필수 필드를 완성합니다.
1. **저장** 또는 **다른 이벤트 저장 및 추가**를 선택합니다.

### 빠른 작업 사용 {#using-a-quick-action}

{{< history >}}

- GitLab 15.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/368721)되었습니다.

{{< /history >}}

[`/timeline` 빠른 작업](../../user/project/quick_actions.md#timeline)을(를) 사용하여 타임라인 이벤트를 생성할 수 있습니다.

### 인시던트의 댓글에서 {#from-a-comment-on-the-incident}

{{< history >}}

- GitLab 15.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/344058)되었습니다.

{{< /history >}}

전제 조건:

- 프로젝트에 대한 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

> [!warning]
> 공개 및 내부 인시던트의 인시던트 타임라인에 추가된 내부 노트는 인시던트에 액세스할 수 있는 모든 사용자에게 표시됩니다.

인시던트의 댓글에서 타임라인 이벤트를 생성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **인시던트**를 선택합니다.
1. 인시던트를 선택합니다.
1. 댓글을 생성하거나 기존 댓글을 선택합니다.
1. 추가할 댓글에서 **인시던트 타임라인에 댓글 추가**({{< icon name="clock" >}})를 선택합니다.

댓글은 인시던트 타임라인에 타임라인 이벤트로 표시됩니다.

### 인시던트 심각도가 변경될 때 {#when-incident-severity-changes}

{{< history >}}

- GitLab 15.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/375280)되었습니다.

{{< /history >}}

누군가 인시던트의 [심각도를 변경](manage_incidents.md#change-severity)하면 새로운 타임라인 이벤트가 생성됩니다.

![심각도 변경을 위한 인시던트 타임라인 이벤트](img/timeline_event_for_severity_change_v15_6.png)

### 레이블이 변경될 때 {#when-labels-change}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 15.3에서 [도입되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/365489) [플래그](../../administration/feature_flags/_index.md)의 이름은 `incident_timeline_events_from_labels`입니다. 기본적으로 비활성화되어 있습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용 준비가 되지 않았습니다.

누군가 인시던트에서 [레이블](../../user/project/labels.md)을(를) 추가하거나 제거하면 새로운 타임라인 이벤트가 생성됩니다.

## 이벤트 삭제 {#delete-an-event}

{{< history >}}

- 편집할 때 이벤트를 삭제하는 기능이 GitLab 15.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/372265)되었습니다.

{{< /history >}}

타임라인 이벤트를 삭제할 수도 있습니다.

전제 조건:

- 프로젝트에 대한 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

타임라인 이벤트를 삭제하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **인시던트**를 선택합니다.
1. 인시던트를 선택합니다.
1. **타임라인** 탭을 선택합니다.
1. 타임라인 이벤트의 오른쪽에서 **추가 작업**({{< icon name="ellipsis_v" >}}) 다음 **삭제**를 선택합니다.
1. 확인하려면 **Delete Event**를 선택합니다.

또는:

1. 타임라인 이벤트의 오른쪽에서 **추가 작업**({{< icon name="ellipsis_v" >}}) 다음 **편집**을 선택합니다.
1. **삭제**를 선택합니다.
1. 확인하려면 **이벤트 삭제**를 선택합니다.

## 인시던트 태그 {#incident-tags}

{{< history >}}

- GitLab 15.9에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/8741)되었으며 [플래그](../../administration/feature_flags/_index.md) `incident_event_tags`이(가) 있습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 15.9에서 [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/387647).
- GitLab 15.10에서 [GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/387647).
- GitLab 15.11에서 [일반 공급됨](https://gitlab.com/gitlab-org/gitlab/-/issues/387647). 기능 플래그 `incident_event_tags`이 제거되었습니다.

{{< /history >}}

[양식을 사용하여 이벤트를 생성](#using-the-form)하거나 편집할 때 관련 인시던트 타임스탬프를 캡처하기 위해 인시던트 태그를 지정할 수 있습니다. 타임라인 태그는 선택 사항입니다. 이벤트당 두 개 이상의 태그를 선택할 수 있습니다. 타임라인 이벤트를 생성하고 태그를 선택하면 이벤트 노트가 기본 메시지로 채워집니다. 이를 통해 빠른 이벤트 생성이 가능합니다. 노트가 이미 설정된 경우 변경되지 않습니다. 추가된 태그는 타임스탬프 옆에 표시됩니다.

## 형식 지정 규칙 {#formatting-rules}

인시던트 타임라인 이벤트는 다음 [GitLab Flavored Markdown](../../user/markdown.md) 기능을 지원합니다.

- [코드](../../user/markdown.md#code-spans-and-blocks).
- [이모지](../../user/markdown.md#emoji).
- [강조](../../user/markdown.md#emphasis).
- [GitLab 관련 참고 자료](../../user/markdown.md#gitlab-specific-references).
- [이미지](../../user/markdown.md#images), 업로드된 이미지로의 링크로 렌더링됨.
- [링크](../../user/markdown.md#links).
