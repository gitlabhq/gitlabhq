---
title: Selective GitLab Duo availability for subgroups
tier: [ Ultimate ]
offering: [ gitlab_dedicated, gitlab_dedicated_for_government ]
stage: software_supply_chain_security
documentation_link: "../../../user/gitlab_duo/turn_on_off/#lock-gitlab-duo-off-for-selected-subgroups"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22389
categories: [ AI Agents ]
level: primary
weight: 50
---

Administrators of GitLab Dedicated instances can make GitLab Duo and GitLab Duo Agent Platform unavailable for selected subgroups while other subgroups
still have the option to turn them on.

Previously, you could either disable GitLab Duo and Agent Platform for an entire instance, or make them potentially available for all.

Now you can enforce a default-deny, per-subgroup allowlist. Mark specific subgroups as **Always off (locked)** so their descendant groups and projects can never enable GitLab Duo
and Agent Platform, while leaving other subgroups up to the discretion of users with the Owner role. Only administrators can apply or remove the lock, and affected Owners see clear messaging that GitLab Duo is locked by a parent group.

This feature helps compliance and platform governance teams meet strict data-classification requirements.
