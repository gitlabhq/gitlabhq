---
title: Always on availability mode for GitLab Duo
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/gitlab_duo/turn_on_off/#lock-gitlab-duo-on-for-all-users"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22382
categories: [ AI Abstraction Layer ]
level: primary
---

Administrators can now set GitLab Duo to be always on for all projects in an entire instance or top-level group. When GitLab Duo is set to always on,
group, subgroup, and project owners cannot turn off GitLab Duo, giving enterprises centralized AI governance for compliance and
regulated environments.

This new setting is symmetrical to the existing [always off](../../../user/gitlab_duo/turn_on_off.md) setting, closing a gap where GitLab Duo could
be locked off but could not be locked on. This new setting is especially valuable for organizations with autonomous divisions or subsidiaries that
need to guarantee consistent AI tooling across the business.

To set GitLab Duo to be always on, go the instance or top-level group GitLab Duo settings and set **GitLab Duo availability** to **Always on**.
