---
title: AI flows supported on non-default branches
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/vulnerability_report/#tracked-ref-filter"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23297
categories: [ Vulnerability Management ]
---

In previous versions of GitLab, you could run the SAST False Positive Detection, SAST Vulnerability
Resolution, and Secret False Positive Detection flows only on vulnerabilities in the default branch.

Now, you can also run these flows on vulnerabilities in other tracked branches from the
vulnerability report to analyze and resolve them before you merge.
