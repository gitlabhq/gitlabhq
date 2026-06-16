---
title: Close coverage gaps with the Scanner Enablement Wizard
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/configuration/scanner_enablement_wizard"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21626
categories: [ Security Asset Inventories ]
level: secondary
weight: 50
ignore_in_report: true
---

<!-- Category: Security Asset Inventories -->

You can now use the Scanner Enablement Wizard to close scanner coverage gaps across your projects without manually identifying which projects need attention.

Security configuration profiles define which scanners run and how. Security inventory shows scanner coverage across your projects and lets you bulk-apply profiles to selected projects or subgroups. The wizard adds a goal-driven workflow on top: you set the goal, and it finds the projects missing coverage and closes only those gaps.
