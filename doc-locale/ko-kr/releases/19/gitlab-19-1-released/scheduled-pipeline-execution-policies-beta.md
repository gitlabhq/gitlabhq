---
title: 예약된 파이프라인 실행 정책 (베타)
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/policies/scheduled_pipeline_execution_policies/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/17875"
categories: [ Security Policy Management ]
level: secondary
weight: 50
---

<!-- categories: Security Policy Management -->

예약된 파이프라인 실행 정책이 베타 기능으로 제공되며 더 이상 실험 플래그를 사용하여 활성화할 필요가 없습니다. 사용자는 커밋 활동과 관계없이 프로젝트 전체에서 일일, 주간 또는 월간 단위로 사용자 정의 CI/CD 작업을 적용할 수 있습니다. 예약된 정책을 사용하여 정기적인 코드 변경이 없을 수 있는 리포지토리에서 규정 준수 스크립트, 보안 스캔 또는 종속성 검사를 실행합니다.

예약된 정책은 이제 일반 파이프라인 실행 정책과 일관되게 변수 우선 순위를 적용합니다. 각 보안 정책 프로젝트는 최대 5개의 예약된 정책을 지원하며, GitLab은 정책이 비활성화되거나 삭제될 때 실행 중인 파이프라인을 자동으로 취소합니다. YAML 또는 UI에서 일정을 구성하고, 표준 시간대 지원, 시간 창 분배, 브랜치 대상 지정 및 일시 중지 기능을 제공합니다.
