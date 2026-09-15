---
title: 하위 그룹을 위한 선택적 GitLab Duo 가용성
tier: [ Ultimate ]
offering: [ gitlab_dedicated, gitlab_dedicated_for_government ]
stage: software_supply_chain_security
documentation_link: "../../../user/gitlab_duo/turn_on_off/#lock-gitlab-duo-off-for-selected-subgroups"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22389
categories: [ AI Agents ]
level: primary
weight: 50
---

GitLab Dedicated 인스턴스의 관리자는 선택한 하위 그룹에서 GitLab Duo 및 GitLab Duo Agent Platform을 사용할 수 없게 만들 수 있지만 다른 하위 그룹은 이를 켤 수 있는 옵션이 있습니다.

이전에는 전체 인스턴스에서 GitLab Duo 및 Agent Platform을 비활성화하거나 모든 사용자가 잠재적으로 사용할 수 있도록 만들 수 있었습니다.

이제 기본 거부 정책을 적용하고 하위 그룹 단위로 허용 목록을 적용할 수 있습니다. 특정 하위 그룹을 **Always off (locked)**로 표시하여 하위 그룹과 프로젝트가 GitLab Duo 및 Agent Platform을 활성화할 수 없도록 하면서, 다른 하위 그룹은 소유자 역할을 가진 사용자의 재량에 따라 결정할 수 있습니다. 관리자만 잠금을 적용하거나 제거할 수 있으며, 영향을 받는 소유자에게는 GitLab Duo가 부모 그룹에 의해 잠겼다는 명확한 메시지가 표시됩니다.

이 기능은 규정 준수 및 플랫폼 거버넌스 팀이 엄격한 데이터 분류 요구 사항을 충족하도록 지원합니다.
