---
title: GitLab Duo 항상 켜짐 가용성 모드
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/gitlab_duo/turn_on_off/#lock-gitlab-duo-on-for-all-users"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22382
categories: [ AI Abstraction Layer ]
level: primary
---

<!-- categories: AI Abstraction Layer -->

이제 운영자는 전체 인스턴스 또는 최상위 그룹의 모든 프로젝트에 대해 GitLab Duo가 '항상 켜짐' 상태가 되도록 설정할 수 있습니다. GitLab Duo를 '항상 켜짐'으로 설정하면 그룹, 하위 그룹 및 프로젝트 소유자가 GitLab Duo를 끌 수 없게 되어, 기업이 규정 준수 및 규제 환경을 위한 중앙 집중식 AI 거버넌스를 갖추게 됩니다.

이 새로운 설정은 기존의 [항상 꺼짐](../../../user/gitlab_duo/turn_on_off.md) 설정과 대칭을 이루며, GitLab Duo를 끄는 상태로는 고정할 수 있지만 켜는 상태로는 고정할 수 없었던 간극을 해결합니다. 이 새로운 설정은 비즈니스 전반에 걸쳐 일관된 AI 도구 사용을 보장해야 하는 자율적인 사업부나 자회사를 가진 조직에 특히 유용합니다.

GitLab Duo를 '항상 켜짐'으로 설정하려면, 인스턴스 또는 최상위 그룹의 GitLab Duo 설정으로 이동하여 **GitLab Duo 가용성**을 **항상 켜짐**으로 설정합니다.
