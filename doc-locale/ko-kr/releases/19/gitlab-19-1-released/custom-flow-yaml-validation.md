---
title: 커스텀 플로우 YAML 유효성 검사
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/flows/custom"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/597224
categories: [ AI Catalog ]
stage: ai-powered
level: secondary
weight: 50
---
AI 카탈로그는 이제 커스텀 플로우 구성을 저장하거나 트리거하기 전에 유효성을 검사합니다.

이전에는 커스텀 플로우의 구문 오류나 잘못된 매개변수 설정(예: 누락된 입력값, 알 수 없는 도구 매개변수)이 CI 작업이 이미 시작된 이후인 런타임 환경에서만 나타났습니다. 이로 인해 디버깅이 느려지고 어려웠습니다.

이제 AI 카탈로그에서 커스텀 플로우를 저장하거나 업데이트할 때, GitLab이 구성을 사전에 확인하고 오류를 UI에 직접 표시해 줍니다. 유효한 플로우는 영향을 받지 않으며 평소처럼 정상적으로 저장되고 트리거됩니다.
