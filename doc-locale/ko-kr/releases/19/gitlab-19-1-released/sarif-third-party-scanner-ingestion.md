---
title: GitLab에서 타사 스캐너 결과 사용
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/detect/sarif"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/595060
categories: [ Security Testing Integrations ]
level: secondary
weight: 50
---

<!-- Category: Security Testing Integrations -->

이제 SARIF 2.1.0을 준수하는 스캐너의 보안 결과를 GitLab 취약성 관리 기능과 함께 사용할 수 있습니다.

스캐너를 실행하고 SARIF 아티팩트를 출력하는 CI/CD 작업을 정의합니다. GitLab은 해당 결과를 파싱하고 유효성을 검사한 후 보안 워크플로에 가져옵니다. 결과는 파이프라인 보안 탭, 취약성 보고서, 보안 대시보드, 머지 리퀘스트 보안 위젯 및 보안 정책에 함께 나타납니다. 이 기능은 보안 팀에 어느 도구가 생성했는지와 상관없이 취약성을 단일의 통합된 보기로 제공합니다.

GitLab은 각 결과에 식별자를 기반으로 보고서 유형을 할당하여 결과를 `SAST`, `dependency scanning`, `secret detection` 같은 카테고리로 매핑합니다. 지원되는 스캐너는 SAST의 Semgrep 및 Checkmarx, 종속성 및 컨테이너 스캔의 Trivy 및 Snyk, 시크릿 검색의 Gitleaks입니다.
