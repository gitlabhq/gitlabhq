---
title: Non default branch tracking (beta)
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/remediate/dependency_scanning_auto_remediation/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/604799
categories: [ Vulnerability Management ]
level: primary
weight: 50
---

You can now track vulnerabilities on branches other than the default branch. For the best
results, target a small number of long-lived release branches, such as branches for specific
environments (`project-qa`, `project-prod`) or deployment platforms (`project-iOS`,
`project-android`).

This beta includes the following capabilities:

- Add tracked branches on the security configuration page, up to twice the number of projects in the namespace.
- Filter by branch on the vulnerability report.
- Filter by branch on the project-level security dashboard.
- Track all vulnerability types on tracked branches, including CVEs, which were previously out of scope.
- Keep vulnerability status metadata consistent when a branch merges into the default branch.
- Update vulnerability status on tracked branches.
