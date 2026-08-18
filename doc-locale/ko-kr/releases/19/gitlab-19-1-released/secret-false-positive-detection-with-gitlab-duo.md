---
title: GitLab Duo를 통한 시크릿 오탐 탐지
stage: software_supply_chain_security
level: primary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/application_security/vulnerabilities/secret_false_positive_detection/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21233"
categories: [ Vulnerability Management ]
weight: 10
---

<!-- categories: Vulnerability Management -->

GitLab Duo Agent Platform을 통한 시크릿 오탐 탐지가 이제 일반적으로 사용 가능합니다.

보안 팀은 시크릿 검색 결과 중 실제 시크릿으로 잘못 표시된 항목을 조사하는 데 상당한 시간을 소비합니다. 이러한 오탐은 알림 피로를 유발하고, 스캔 결과에 대한 신뢰를 훼손하며, 실제 보안 위험에서 주의를 분산시킵니다.

보안 스캔이 실행되면 GitLab Duo는 각 중대한 심각도 및 높은 심각도의 시크릿 검색 취약성을 자동으로 분석하여 오탐인지 판단합니다. AI 평가가 취약성 보고서에 표시되므로 더 빠르고 확신 있는 심사 결정을 내릴 수 있는 즉각적인 컨텍스트를 얻을 수 있습니다.

주요 기능은 다음과 같습니다:

- 자동 분석: 수동 트리거 없이 각 보안 스캔 후에 실행됩니다.
- 수동 트리거: 취약성 세부 정보 페이지에서 개별 취약성에 대해 오탐 탐지를 트리거하여 온디맨드 분석을 수행합니다.
- 높은 영향 결과에 초점: 중대한 및 높은 심각도 취약성만 분석하여 신호 대 잡음 개선을 극대화합니다.
- 상황별 AI 추론: 각 평가에는 코드 컨텍스트 및 취약성 특성을 기반으로 결과가 참 양성일 가능성이 높은 이유에 대한 설명이 포함됩니다.
- 신뢰도 점수: 각 탐지에는 모델의 확실성을 기반으로 검토 우선 순위를 지정하는 데 도움이 되는 신뢰도 점수가 포함됩니다.
- 원활한 워크플로우 통합: 결과가 취약성 보고서에 기존 심각도, 상태, 수정 정보와 함께 직접 표시됩니다.

[이슈 592861](https://gitlab.com/gitlab-org/gitlab/-/issues/592861)에서 피드백을 환영합니다.
