---
title: 코드 리뷰 플로우를 위한 GPT 모델
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../user/duo_agent_platform/model_selection/#supported-models"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/598322
categories: [ Duo Agent Platform, Duo Code Review ]
level: secondary
---

<!-- categories: Duo Agent Platform, Duo Code Review -->

이전 버전의 GitLab에서는 코드 리뷰 플로우가 Anthropic Claude 모델만 지원했습니다. 계약, 정책 또는 조달 제약으로 인해 Anthropic 모델을 사용할 수 없는 팀은 코드 리뷰 플로우를 실행할 방법이 없었습니다.

이제 코드 리뷰 플로우 모델로 GPT-5.2 또는 GPT-5.3 Codex를 선택할 수 있습니다. 최상위 그룹의 소유자는 **설정** > **GitLab Duo** > **기능 구성**의 **GitLab Duo 에이전트 플랫폼** 섹션 아래에서 **에이전트 코드 리뷰** 모델을 변경할 수 있습니다. GPT 모델은 GitLab AI 게이트웨이를 통해 호스팅되므로 추가 구성이 필요하지 않습니다.

두 모델 모두 GitLab Duo 코드 리뷰 데이터 세트에 대한 벤치마크 평가를 통과했으며, 검토 품질은 기본 설정인 Claude Sonnet 4.6 Vertex 모델과 필적하는 수준입니다. 결과는 [코드 리뷰 벤치마크](https://duo-review-bench-6f7260.gitlab.io/)를 참조하세요.
