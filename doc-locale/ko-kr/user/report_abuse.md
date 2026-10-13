---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 악용 사례 신고
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

다른 GitLab 사용자의 악용 사례를 GitLab 관리자에게 신고할 수 있습니다.

GitLab 관리자는 [다음을 선택](../administration/review_abuse_reports.md)할 수 있습니다:

- 사용자를 제거하면 인스턴스에서 삭제됩니다.
- 사용자를 차단하면 인스턴스에 대한 액세스가 거부됩니다.
- 또는 신고를 제거하여 사용자가 인스턴스에 계속 액세스할 수 있도록 합니다.

다음을 통해 사용자를 신고할 수 있습니다:

- [프로필](#report-abuse-from-the-users-profile-page)
- [댓글](#report-abuse-from-a-users-comment)
- [이슈](#report-abuse-from-an-issue)
- [태스크](#report-abuse-from-a-task)
- [목표](#report-abuse-from-an-objective)
- [주요 결과](#report-abuse-from-a-key-result)
- [머지 리퀘스트](#report-abuse-from-a-merge-request)
- [스니펫](snippets.md#mark-snippet-as-spam)

에이전트 또는 플로우에서도 악용 사례를 신고할 수 있습니다.

## 사용자 프로필 페이지에서 악용 사례 신고 {#report-abuse-from-the-users-profile-page}

사용자 프로필 페이지에서 악용 사례를 신고하려면:

1. GitLab 어디서나 사용자의 이름을 선택합니다.
1. 사용자 프로필의 오른쪽 상단 모서리에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 후 **악용 사례 신고**를 선택합니다.
1. 신고 사유를 선택합니다.
1. 악용 신고서를 작성합니다.
1. **보고서 보내기**를 선택합니다.

## 사용자의 댓글에서 악용 사례 신고 {#report-abuse-from-a-users-comment}

사용자의 댓글에서 악용 사례를 신고하려면:

1. 댓글의 오른쪽 상단 모서리에서 **추가 작업** ({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **악용 사례 신고**를 선택합니다.
1. 신고 사유를 선택합니다.
1. 악용 신고서를 작성합니다.
1. **보고서 보내기**를 선택합니다.

> [!note]
> 신고된 사용자의 댓글 URL이 악용 신고서의 **메시지** 필드에 미리 입력됩니다.

## 이슈에서 악용 사례 신고 {#report-abuse-from-an-issue}

1. 이슈에서 오른쪽 상단 모서리에 **이슈 작업** ({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **악용 사례 신고**를 선택합니다.
1. 신고 사유를 선택합니다.
1. 악용 신고서를 작성합니다.
1. **보고서 보내기**를 선택합니다.

## 작업에서 악용 사례 신고 {#report-abuse-from-a-task}

{{< history >}}

- GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/461848)되었습니다.

{{< /history >}}

1. 작업의 오른쪽 상단 모서리에서 **추가 작업** ({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **악용 사례 신고**를 선택합니다.
1. 신고 사유를 선택합니다.
1. 악용 신고서를 작성합니다.
1. **보고서 보내기**를 선택합니다.

## 목표에서 악용 사례 신고 {#report-abuse-from-an-objective}

{{< history >}}

- GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/461848)되었습니다.

{{< /history >}}

1. 목표의 오른쪽 상단 모서리에서 **추가 작업** ({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **악용 사례 신고**를 선택합니다.
1. 신고 사유를 선택합니다.
1. 악용 신고서를 작성합니다.
1. **보고서 보내기**를 선택합니다.

## 주요 결과에서 악용 사례 신고 {#report-abuse-from-a-key-result}

{{< history >}}

- GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/461848)되었습니다.

{{< /history >}}

1. 주요 결과의 오른쪽 상단 모서리에서 **추가 작업** ({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **악용 사례 신고**를 선택합니다.
1. 신고 사유를 선택합니다.
1. 악용 신고서를 작성합니다.
1. **보고서 보내기**를 선택합니다.

## 머지 리퀘스트에서 악용 사례 신고 {#report-abuse-from-a-merge-request}

1. 머지 리퀘스트의 오른쪽 상단 모서리에서 **머지 리퀘스트 동작** ({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **악용 사례 신고**를 선택합니다.
1. 신고 사유를 선택합니다.
1. 악용 신고서를 작성합니다.
1. **보고서 보내기**를 선택합니다.

## 에이전트에서 악용 사례 신고 {#report-abuse-from-an-agent}

사전 요구 사항:

- GitLab에 로그인합니다.
- [GitLab Duo 에이전트 플랫폼에 액세스하도록 허가받은](../administration/gitlab_duo/configure/access_control.md) 그룹에 속합니다.
- 관리자는 인스턴스에 대해 [악용 신고 알림 이메일](../administration/review_abuse_reports.md)을 구성해야 합니다.

에이전트에서 악용 사례를 신고하려면:

1. 에이전트 상세 보기의 오른쪽 상단 모서리에서 **추가 작업** ({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **운영자에게 보고**를 선택합니다.
1. 이 에이전트를 신고하는 사유를 선택합니다.
1. 선택 사항입니다. 추가 정보를 추가합니다.
1. **제출**을 선택합니다.

## 플로우에서 악용 사례 신고 {#report-abuse-from-a-flow}

사전 요구 사항:

- GitLab에 로그인합니다.
- [GitLab Duo 에이전트 플랫폼에 액세스하도록 허가받은](../administration/gitlab_duo/configure/access_control.md) 그룹에 속합니다.
- 관리자는 인스턴스에 대해 [악용 신고 알림 이메일](../administration/review_abuse_reports.md)을 구성해야 합니다.

플로우에서 악용 사례를 신고하려면:

1. 플로우 상세 보기의 오른쪽 상단 모서리에서 **추가 작업** ({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **운영자에게 보고**를 선택합니다.
1. 이 플로우를 신고하는 사유를 선택합니다.
1. 선택 사항입니다. 추가 정보를 추가합니다.
1. **제출**을 선택합니다.

## 관련 항목 {#related-topics}

- [악용 신고 관리 문서](../administration/review_abuse_reports.md)
