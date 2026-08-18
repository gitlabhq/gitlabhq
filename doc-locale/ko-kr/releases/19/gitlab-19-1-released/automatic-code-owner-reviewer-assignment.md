---
title: 코드 소유자를 검토자로 자동 할당
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: create
documentation_link: "../../../user/project/merge_requests/reviews/automatic_reviewer_assignment"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20708
categories: [ Code Review Workflow ]
level: primary
---

<!-- categories: Code Review Workflow -->

이전에는 `CODEOWNERS` 파일에 각 파일을 검토할 사람이 이미 정의되어 있더라도 각 머지 리퀘스트의 검토자를 수동으로 선택해야 했습니다.

이제 프로젝트에서 코드 소유자를 자동으로 검토자로 할당하도록 구성할 수 있습니다. GitLab은 변경된 파일과 일치하는 모든 코드 소유자를 검토자로 할당합니다. 이 작업은 머지 리퀘스트가 준비 상태로 생성되거나, 초안 상태에서 준비 완료로 표시될 때 발생합니다. 검토자가 이미 할당되어 있는 경우, GitLab은 자동 할당을 건너뛰고 사용자의 선택을 유지합니다.

자동 검토자 할당 기능을 켜려면 **설정** > **머지 리퀘스트** > **자동 리뷰어 지정**으로 이동하여 **자동으로 모든 코드 소유자를 리뷰어로 지정**을 선택합니다.
