---
title: 보안 검토 플로우 (베타)
stage: ai-powered
level: primary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/security_review/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/600477"
categories: [ DAP Code Review ]
---

<!-- DAP Code Review -->

보안 검토 플로우는 머지 리퀘스트에서 직접 비즈니스 로직 취약성을 감지합니다. 알려진 패턴을 스캔하는 정적 분석 도구와 달리 보안 검토 플로우는 코드의 의도를 파악하고 패턴 기반 스캐너가 자주 놓치는 권한 부여 우회, 데이터 노출 및 로직 오류를 식별합니다.

검토를 요청하려면 **Duo Security Review** 서비스 계정을 머지 리퀘스트의 검토자로 할당합니다. 플로우는 diff를 분석하고 취약성이 발생하는 정확한 줄에서 스레드 처리된 댓글로 결과를 게시합니다. 각 결과에는 공통 약점 열거(CWE) 분류, 심각도 등급이 포함되며, 가능한 경우 머지 리퀘스트를 떠나지 않고 적용할 수 있는 인라인 제안 수정이 포함됩니다.

각 검토는 머지 리퀘스트 diff의 복잡도를 기반으로 GitLab Credits를 소비합니다.
