---
title: "GitLab Duo를 사용하여 베타 검토 토론 해결하기"
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/duo_in_merge_requests/#resolve-a-discussion-with-gitlab-duo"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22117
categories: [ DAP Code Review ]
---


이전 버전의 GitLab에서 코드 검토 의견을 해결하려면 편집기로 전환하고 수정 사항을 구현한 후 변경 사항을 커밋하고 푸시한 다음 스레드를 수동으로 닫아야 했습니다. 해결되지 않은 모든 토론에 대해 이 사이클을 반복해야 했으며, 바쁜 검토 중에 컨텍스트 전환 오버헤드가 누적되었습니다.

이제 모든 검토 토론에서 **GitLab Duo와 함께 해결**을 선택할 수 있습니다. GitLab Duo는 검토 의견과 주변 코드를 읽고 검토자가 설명한 변경 사항을 구현한 후 브랜치에 커밋합니다. 그러면 GitLab Duo는 변경 사항과 그 이유를 간단히 요약한 내용으로 토론에 응답하고 스레드를 해결합니다. 수정 사항이 의견을 올바르게 반영하지 않으면 변경 사항을 검토하고 스레드를 다시 열 수 있습니다.
