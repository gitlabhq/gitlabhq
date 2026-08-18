---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 인시던트의 연결된 리소스를 보고 업데이트하는 방법(URL 및 Zoom 회의에 대한 빠른 작업을 사용하는 방법 포함)을 알아봅니다.
title: 인시던트의 연결된 리소스
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/230852)되었으며 [플래그](../../administration/feature_flags/_index.md) `incident_resource_links_widget`로 설정됩니다. 기본적으로 비활성화되어 있습니다.
- GitLab 15.3에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/364755)되었습니다.
- GitLab 15.5에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/364755)합니다. 기능 플래그 `incident_resource_links_widget`이 제거되었습니다.

{{< /history >}}

팀원이 많은 댓글을 검색하지 않고도 중요한 링크를 찾을 수 있도록 인시던트 이슈에 연결된 리소스를 추가할 수 있습니다.

링크할 수 있는 리소스:

- 인시던트 Slack 채널
- Zoom 회의
- 인시던트 해결을 위한 리소스

## 인시던트의 연결된 리소스 보기 {#view-linked-resources-of-an-incident}

인시던트의 연결된 리소스는 **요약** 탭에 나열됩니다.

![연결된 리소스 목록](img/linked_resources_list_v15_3.png)

인시던트의 연결된 리소스를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **인시던트**를 선택합니다.
1. 인시던트를 선택합니다.

## 연결된 리소스 추가 {#add-a-linked-resource}

인시던트에서 연결된 리소스를 수동으로 추가합니다.

전제 조건:

- 프로젝트의 보고자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

연결된 리소스를 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **인시던트**를 선택합니다.
1. 인시던트를 선택합니다.
1. **Linked resources** 섹션에서 더하기 아이콘({{< icon name="plus-square" >}})을 선택합니다.
1. 필수 필드를 완성합니다.
1. **추가**를 선택합니다.

### 빠른 작업 사용 {#using-a-quick-action}

{{< history >}}

- GitLab 15.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/374964)되었습니다.

{{< /history >}}

인시던트에 여러 링크를 추가하려면 [`/link` 빠른 작업](../../user/project/quick_actions.md#link)을 사용합니다:

```plaintext
/link https://example.link.us/j/123456789
```

링크와 함께 짧은 설명을 제출할 수도 있습니다. 설명이 인시던트의 **Linked resources** 섹션에서 URL 대신 표시됩니다:

```plaintext
/link https://example.link.us/j/123456789 multiple alerts firing
```

### 인시던트에서 Zoom 회의 연결 {#link-zoom-meetings-from-an-incident}

{{< history >}}

- GitLab 15.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/230853)되었습니다.

{{< /history >}}

[`/zoom` 빠른 작업](../../user/project/quick_actions.md#zoom)을 사용하여 인시던트에 여러 Zoom 링크를 추가합니다:

```plaintext
/zoom https://example.zoom.us/j/123456789
```

링크와 함께 짧은 선택적 설명을 제출할 수도 있습니다. 설명이 인시던트 **Linked resources** 섹션에서 URL 대신 표시됩니다:

```plaintext
/zoom https://example.zoom.us/j/123456789 Low on memory incident
```

## 연결된 리소스 제거 {#remove-a-linked-resource}

연결된 리소스를 제거할 수도 있습니다.

전제 조건:

- 프로젝트의 보고자, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.

연결된 리소스를 제거하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모니터링** > **인시던트**를 선택합니다.
1. 인시던트를 선택합니다.
1. **Linked resources** 섹션에서 **삭제**({{< icon name="close" >}})를 선택합니다.
