---
title: 베타 종속성 검사 자동 수정
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../user/application_security/remediate/dependency_scanning_auto_remediation/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/604799
categories: [ Software Composition Analysis ]
level: primary
weight: 50
---

<!-- Category: Software Composition Analysis -->

GitLab 19.2는 베타 상태의 종속성 검사 자동 수정 기능을 제공합니다. 이 기능은 자동화된 취약성 수정을 종속성 검사 워크플로우에 직접 통합하며, 두 가지 기능을 제공합니다:

- GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 사용 가능한 자동화된 종속성 버전 업데이트입니다.
- GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 사용 가능하며 GitLab Credits를 소비하는 Agentic Breaking Change Resolution입니다.

자동화된 종속성 버전 업데이트는 취약한 종속성을 안전한 버전으로 업데이트하는 머지 리퀘스트를 자동으로 생성합니다. 활성화되면 GitLab은 프로젝트에서 취약한 종속성을 모니터링하고 수동 개입 없이 수정 머지 리퀘스트를 생성합니다. 기본적으로 업데이트는 패치 및 마이너 버전을 대상으로 합니다.

Agentic Breaking Change Resolution은 수정 플로우를 확장하여 복잡한 업데이트를 처리합니다. 머지 리퀘스트가 종속성 버전을 업데이트하고 breaking change로 인해 파이프라인이 실패하면, GitLab Duo는 파이프라인 오류, 종속성의 변경 사항 및 코드가 종속성을 사용하는 방식을 분석합니다.

GitLab Duo는 수정 사항을 동일한 머지 리퀘스트에 커밋하고 파이프라인이 통과할 때까지 파이프라인을 다시 실행합니다. Agentic Breaking Change Resolution을 활성화하면 버전 업데이트가 메이저 버전을 포함하도록 확장됩니다.

두 가지 기능을 함께 사용하면 완전한 수정 루프를 형성합니다: GitLab은 머지 리퀘스트를 생성하고, 업데이트가 복잡하면 GitLab Duo가 이를 해결합니다.

설정 지침은 [종속성 검사 자동 수정](../../../user/application_security/remediate/dependency_scanning_auto_remediation.md)을 참조하세요.

피드백은 [베타 피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/605599)에 공유하세요.
