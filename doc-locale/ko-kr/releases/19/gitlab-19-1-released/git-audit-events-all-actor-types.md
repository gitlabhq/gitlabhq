---
title: 모든 액터(actor) 유형에 대한 Git 작업 감사 이벤트
stage: create
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../administration/compliance/audit_event_reports/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20506"
categories: [ Source Code Management ]
---

<!-- categories: Source Code Management -->

GitLab 18.10부터 인간 사용자가 수행한 특정 Git 작업(clone, pull, fetch 또는 push)이 감사 로그에 캡처되기 시작했습니다.

GitLab 19.1에서는 이 기능이 배포 토큰을 사용하는 러너와 SSH 인증서 사용자를 포함한 모든 액터 유형으로 확장되었습니다. 이제 감사 로그는 리포지토리 전반에 걸친 모든 Git 활동의 완전한 현황을 반영하며, 활동을 시작한 주체가 사람인지 시스템인지 관계없이 모두 기록됩니다.
