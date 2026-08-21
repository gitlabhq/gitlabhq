---
title: Fix CI/CD Pipeline 플로우 제안된 해결책
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/fix_pipeline"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21837
categories: [ Continuous Integration (CI) ]
level: secondary
weight: 10
---

GitLab Duo의 Fix CI/CD Pipeline 플로우는 이제 두 가지 핵심 개선 사항을 제공합니다:

- 관련 파일이 이미 머지 리퀘스트 diff에 있으면 머지 리퀘스트에서 직접 코드 제안으로 해결책을 얻을 수 있습니다.
- 플로우는 실행하기 전에 파이프라인 오류를 분류하므로 보다 대상이 명확한 진단을 얻을 수 있습니다.

플로우는 또한 전체 파이프라인 계층 전체에서 자식 파이프라인 오류를 분석하고, `AGENTS.md` 파일을 사용하여 프로젝트의 동작을 사용자 지정할 수 있으며, 머지 리퀘스트 댓글을 깔끔하게 유지하기 위해 기본적으로 AI 추론을 축소합니다.

[피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/601991)에서 피드백을 공유하세요.
