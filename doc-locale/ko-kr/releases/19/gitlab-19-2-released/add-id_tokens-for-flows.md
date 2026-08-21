---
title: 플로우에서 ID 토큰 구성
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: ai-powered
documentation_link: "../../../user/duo_agent_platform/flows/execution/#configure-id-tokens"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/591140
categories: [ Runner Execution, System Access ]
level: secondary
weight: 50
---

장기 자격 증명을 저장하지 않고 ID 토큰을 사용하여 제3자 OpenID Connect(OIDC) 서비스로 인증합니다. 예를 들어, ID 토큰을 사용하여 바이너리 및 커밋에 서명하거나 암호 관리자에서 암호를 검색합니다.

이 기능을 사용하려면 에이전트 구성을 업데이트하여 `id_tokens` 키워드를 포함한 다음 서비스를 구성하여 GitLab Duo Agent Platform에서 발급한 토큰을 신뢰하도록 합니다.
