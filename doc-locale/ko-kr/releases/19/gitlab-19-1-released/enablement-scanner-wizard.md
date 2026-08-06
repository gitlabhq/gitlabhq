---
title: 스캐너 활성화 마법사로 커버리지 격차 해결
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/configuration/scanner_enablement_wizard"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21626
categories: [ Security Asset Inventories ]
level: secondary
weight: 50
---

<!-- Category: Security Asset Inventories -->

이제 스캐너 활성화 마법사를 사용하면 주의가 필요한 프로젝트를 수동으로 찾을 필요 없이 전체 프로젝트의 스캐너 커버리지 격차를 해결할 수 있습니다.

보안 구성 프로필은 어떤 스캐너를 어떻게 실행할지 정의합니다. 보안 인벤토리는 프로젝트 전체의 스캐너 커버리지를 보여주며, 선택한 프로젝트 또는 하위 그룹에 프로필을 일괄 적용할 수 있게 해줍니다. 이 마법사는 목표 중심의 워크플로우를 제공합니다. 목표를 설정하면 마법사는 커버리지가 누락된 프로젝트를 찾아 해당 격차만 해결합니다.
