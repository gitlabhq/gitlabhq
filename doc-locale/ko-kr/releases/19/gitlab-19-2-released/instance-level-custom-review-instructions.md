---
title: 인스턴스 수준 사용자 지정 검토 지침
offering: [ self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/customize/review_instructions#configure-custom-review-instructions-for-an-instance"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22616
categories: [ DAP Code Review ]
---

GitLab의 이전 버전에서는 프로젝트 또는 그룹 수준에서만 GitLab Duo의 사용자 지정 검토 지침을 정의할 수 있었습니다. 전체 인스턴스에 걸쳐 일관된 검토 지침(예: 보안 규칙 또는 내부 코딩 표준)을 원하는 관리자는 모든 프로젝트에서 동일한 지침을 복제해야 했습니다.

이제 전체 인스턴스에 대한 사용자 지정 검토 지침을 구성할 수 있습니다.

관리자는 인스턴스의 프로젝트를 선택하여 템플릿으로 사용합니다. GitLab Duo가 코드 검토를 수행할 때, 인스턴스 수준 `.gitlab/duo/mr-review-instructions.yaml` 파일의 지침을 그룹 수준 및 프로젝트 수준 지침과 결합합니다. 이를 통해 조직은 인스턴스 전체 검토 표준의 단일 정보 소스를 얻습니다.

Code Review 플로우와 GitLab Duo 코드 검토는 모두 인스턴스 수준 사용자 지정 지침을 지원합니다.
