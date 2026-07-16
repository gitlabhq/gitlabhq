---
title: Vulnerability report exports correctly apply filters
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: security_risk_management
documentation_link: "../../../user/application_security/vulnerability_report/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/17601
categories: [ Vulnerability Management ]
level: secondary
weight: 50
---

When exporting a vulnerability report with filters applied, the exported CSV file only includes the filtered data.
