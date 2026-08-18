---
title: "GitLab Duo 에이전트를 위한 도구 승인 가드레일 (베타)"
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/duo_agent_platform/agents/tool-governance/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22381
categories: [ AI Governance ]
level: primary
---

<!-- categories: AI Governance -->

관리자는 이제 GitLab Duo 에이전트를 위한 도구 수준의 승인 정책을 구성할 수 있으며, 실행 시점에 민감한 작업을 인간의 승인으로 제어할 수 있습니다.

이전에는 AI 에이전트가 프로젝트에 대해 승인된 후 추가 검토 없이 쓰기 및 파괴적인 작업을 포함한 모든 도구를 호출할 수 있었습니다. 이제 각 도구를 세 가지 모드 중 하나에 매핑하는 그룹 및 프로젝트 규칙을 정의할 수 있습니다:

- 허용 (자동으로 실행).
- 확인 (인간의 승인 필요).
- 거부 (완전히 차단).

AI 에이전트가 "확인" 모드에서 도구를 호출하면, 실행이 진행되기 전에 사용자에게 인라인 승인 카드로 표시됩니다.

이 베타 릴리스는 Agentic Chat, IDE 및 플로우를 포함하며, 모든 승인 결정에 대해 감사 이벤트를 발생시킵니다.
