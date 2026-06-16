---
title: Security Manager role generally available
tier: [ gitlab_com, self_managed, gitlab_dedicated ]
offering: [ Free, Premium, Ultimate ]
stage: security_risk_management
documentation_link: "../../../user/permissions/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/16399
categories: [ Permissions ]
level: secondary
weight: 50
---

The Security Manager role is now generally available, providing comprehensive access to security features including vulnerability management, security dashboards, policy configuration, and compliance tools. Security teams no longer need the Developer role or the Maintainer role to access security features, eliminating over-privileging concerns while maintaining separation of duties.

Users with the Security Manager role have the following access:

- Vulnerability management: View, triage, and manage vulnerabilities across groups and projects.
- Security policies: View and manage security policies at the group level, and contribute to policy YAML at the project level.
- Security inventory: View scanner coverage across all projects in a group.
- Security configuration profiles: View security configuration profiles for groups and projects.
- Compliance tools: View and manage audit events, compliance center, compliance frameworks, compliance status reports, and dependency lists at both group and project levels.
- Secret push protection: Enable secret push protection for a group and project.
- On-demand DAST: Create and run on-demand DAST scans for a project.
- Runner visibility: View runners for a group and project.

To get started, go to a group and select **Manage > Members** to invite and assign members to the Security Manager role.
