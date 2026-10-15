---
title: Non-default branch tracking generally available
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/vulnerability_report"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/3430
categories: [ Vulnerability Management ]
level: primary
weight: 50
---

Non-default branch tracking is now generally available. You can track vulnerabilities on branches
other than the default branch. For the best results, target a small number of long-lived release
branches, such as branches for specific environments (`project-qa`, `project-prod`) or deployment
platforms (`project-iOS`, `project-android`).

This release includes the following capabilities:

- Track three additional branches or tags on the security configuration page. This is in addition to the default tracked branch.
- Filter by tracked ref on the vulnerability report.
- Filter by branch on the project-level security dashboard.
- Update vulnerability status on tracked branches.
- Vulnerability management policies evaluate each tracked branch separately and update only the vulnerabilities on that branch.
