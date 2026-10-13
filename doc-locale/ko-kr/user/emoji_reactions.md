---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 이모티콘 반응
description: "이슈, 댓글 및 기타 항목에서 이모티콘으로 반응하여 긴 댓글 스레드를 작성하지 않고 피드백을 제공합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

온라인으로 협업할 때는 하이파이브와 엄지손가락 올리는 제스처를 사용할 기회가 적습니다. 이모티콘으로 반응할 수 있는 대상:

- [이슈](project/issues/_index.md).
- [작업](tasks.md).
- [머지 리퀘스트](project/merge_requests/_index.md) 및 [스니펫](snippets.md).
- [에픽](group/epics/_index.md).
- [목표 및 핵심 결과](okrs.md).
- [위키 페이지](project/wiki/_index.md).
- 댓글 스레드를 작성할 수 있는 다른 모든 곳.

![검색 상자를 포함한 다양한 카테고리의 이모티콘 반응 선택기.](img/award_emoji_select_v14_6.png)

이모티콘 반응을 사용하면 긴 댓글 스레드 없이 피드백을 훨씬 더 쉽게 주고받을 수 있습니다.

"엄지손가락 올림" 및 "엄지손가락 내림" 이모티콘은 [인기도 순으로 정렬](project/issues/sorting_issue_lists.md#sorting-by-popularity)할 때 이슈 또는 머지 리퀘스트의 위치를 계산하는 데 사용됩니다.

자세한 내용은 [이모티콘 반응 API](../api/emoji_reactions.md)를 참고하세요.

## 댓글에 대한 이모티콘 반응 {#emoji-reactions-for-comments}

이모티콘 반응은 성취를 축하하거나 의견에 동의하려는 경우 개별 댓글에도 적용할 수 있습니다.

이모티콘 반응을 추가하려면:

1. 댓글의 오른쪽 위 모서리에서 웃는 얼굴({{< icon name="slight-smile" >}})을 선택합니다.
1. 이모티콘 선택기에서 이모티콘을 선택합니다.

이모티콘 반응을 제거하려면 이모티콘을 다시 선택합니다.

## 커스텀 이모티콘 {#custom-emoji}

커스텀 이모티콘은 이모티콘으로 반응할 수 있는 모든 곳의 이모티콘 선택기에 표시됩니다.

댓글 또는 설명에 이모티콘 반응을 추가하려면:

1. **반응 추가**({{< icon name="slight-smile" >}})를 선택합니다.
1. GitLab 로고({{< icon name="tanuki" >}})를 선택하거나 **커스텀** 섹션으로 스크롤합니다.
1. 이모티콘 선택기에서 이모티콘을 선택합니다.

![반응 선택기의 커스텀 이모티콘 섹션.](img/custom_emoji_reactions_v16_2.png)

텍스트 상자에서 사용하려면 파일명을 두 개의 콜론 사이에 입력합니다. 예를 들어, `:thank-you:`입니다.

### 그룹에 커스텀 이모티콘 업로드 {#upload-custom-emoji-to-a-group}

그룹에 커스텀 이모티콘을 업로드하여 모든 하위 그룹 및 프로젝트에서 사용할 수 있습니다.

사전 요구 사항:

- 그룹에 대해 최소한 개발자 역할이 있어야 합니다.

커스텀 이모티콘을 업로드하려면:

1. 설명 또는 댓글에서 **반응 추가**({{< icon name="slight-smile" >}})를 선택합니다.
1. 이모티콘 선택기 하단에서 **새 이모티콘 만들기**를 선택합니다.
1. 커스텀 이모티콘의 이름과 URL을 입력합니다.
1. **저장**을 선택합니다.

GraphQL API를 사용하여 GitLab 인스턴스에 커스텀 이모티콘을 업로드할 수도 있습니다. 자세한 내용은 [GraphQL로 커스텀 이모티콘 사용](../api/graphql/custom_emoji.md)을 참고하세요.
