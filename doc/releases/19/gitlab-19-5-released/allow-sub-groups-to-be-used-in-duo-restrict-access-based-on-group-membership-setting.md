---
title: Restrict GitLab Duo access by subgroup membership
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: security_governance
documentation_link: "../../../administration/gitlab_duo/configure/access_control"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/633488
categories: [ AI Governance ]
level: primary
weight: 50
---

Administrators can now select any subgroup, not just top-level groups, in the [**Restrict access based on group membership**](../../../administration/gitlab_duo/configure/access_control.md) setting for GitLab Duo. You can scope GitLab Duo Agent Platform access to a specific team or pilot group without restructuring your group hierarchy.

Previously, this setting accepted only top-level groups. Organizations with a single top-level group for all users had no supported way to limit GitLab Duo Agent Platform access to a subset of users.

Now, when you select a subgroup, direct members of that subgroup get access. This makes it easier to run a GitLab Duo Agent Platform pilot or roll out access one division at a time on GitLab Self-Managed and GitLab Dedicated.
