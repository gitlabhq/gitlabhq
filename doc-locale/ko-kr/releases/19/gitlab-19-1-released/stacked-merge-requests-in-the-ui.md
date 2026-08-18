---
title: UI의 스택된 머지 리퀘스트
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: create
documentation_link: "../../../user/project/merge_requests/reviews/stacked_merge_requests"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22211
categories: [ Code Review Workflow ]
level: secondary
---

<!-- categories: Code Review Workflow -->

이전에는 대규모 변경 사항을 서로 연관된 작은 머지 리퀘스트로 분할할 때 UI에서 이들이 관련된 사항을 나타내는 신호가 없었습니다. 검토자와 작성자는 순서를 수동으로 추적해야 했습니다.

GitLab은 이제 스택된 머지 리퀘스트를 자동으로 감지하고 머지 리퀘스트 헤더에 표시합니다. 머지 리퀘스트는 다른 열린 머지 리퀘스트의 소스 브랜치를 대상으로 하거나 다른 열린 머지 리퀘스트가 자신의 소스 브랜치를 대상으로 할 때 스택에 합류합니다. 소스 브랜치 옆의 스택 제어 버튼은 현재 위치(예: **1 of 2**)를 표시하며 스택의 다른 머지 리퀘스트로 이동할 수 있습니다.

명령줄에서 스택된 머지 리퀘스트를 생성하려면 GitLab CLI에서 스택된 diffs를 사용합니다.
