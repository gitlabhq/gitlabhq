---
title: AI 감사 이벤트 보고서 (베타)
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/duo_agent_platform/ai-audit-events/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20237"
categories: [ Compliance Management, Audit Events ]
level: primary
ignore_in_report: true
---

<!-- categories: Compliance Management, Audit Events -->

AI 감사 이벤트 보고서는 이제 베타로 제공되며, 보안 및 규정 준수 팀이 GitLab Duo 에이전트 활동의 통합된 다운로드 가능한 레코드를 얻을 수 있습니다.

이전에는 에이전트 활동이 파이프라인 작업 및 이벤트 기록에 흩어져 있어 다음과 같은 항목의 세션을 재구성하기 어려웠습니다:

- 사건 조사.
- 규정 준수 검토.
- AI 거버넌스 보고.

이제 각 에이전트 세션은 다음을 캡처하는 포괄적인 감사 결과물을 생성합니다:

- 입력.
- 모델 및 구성 컨텍스트.
- 시간순 이벤트 타임라인.
- 출력.

**거버넌스** 페이지에서 AI 감사 이벤트를 검색하고, 에이전트 및 세션 세부 정보로 필터링하며, 개별 이벤트를 자세히 살펴보고, 기본 세션 결과물을 다운로드할 수 있습니다.
