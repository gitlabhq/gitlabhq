---
title: 기본 플로우 준비 상태 확인
offering: [ self_managed, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../administration/gitlab_duo/configure/#run-a-health-check-for-gitlab-duo"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/599536
categories: [ Duo Agent Platform ]
level: secondary
---

<!-- categories: Duo Agent Platform  -->

GitLab Duo 상태 확인 기능에 기본 플로우 준비 상태 확인이 추가되었으며, 다음 항목을 검증합니다.

- 인스턴스 수준 플로우 실행 설정이 활성화되어 있습니다.
- 인스턴스 수준 기본 플로우 설정이 활성화되어 있습니다.
- `gitlab--duo` 태그가 지정된 활성 인스턴스 러너가 하나 이상 등록 및 연결되어 있고, Docker 호환 실행기를 사용하고 있습니다.
