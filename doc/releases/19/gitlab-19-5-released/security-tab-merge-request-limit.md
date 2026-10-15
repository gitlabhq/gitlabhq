---
title: Accurate merge request security report comparisons
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/project/merge_requests/reports/#security-scan-report"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/628421
categories: [ Vulnerability Management ]
---

In previous versions of GitLab, if a scan had more than 25 findings of one severity, the security
report compared only 25 of them from each pipeline. Unchanged findings could appear as new or
fixed.

Now, the report compares up to 1,000 findings per severity, so the new and fixed lists are more
accurate.
