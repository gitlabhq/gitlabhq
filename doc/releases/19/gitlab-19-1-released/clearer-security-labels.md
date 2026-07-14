---
title: Clearer, security industry-standard labels in vulnerability details
stage: application_security_testing
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/application_security/vulnerabilities/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21978"
categories: [ Vulnerability Management ]
---

In GitLab 19.1, the vulnerability results details page uses consistent, descriptive, and security industry-standard terminology for scan results:

- **Scanner** is now **Detected by**
- **EPSS** is now **Exploit Probability (EPSS)**
- **Has Known Exploit (KEV)** is now **Known Exploited (CISA KEV)**
- **Reachable** is now **Reachability**
- **Image** is now **Container Image** (Container Scanning)
- **Location** is now **Affected Location**
- **URL** is now **Affected Endpoint** (DAST, API fuzzing)
- **Method** is now **HTTP Method** (DAST, API fuzzing)
- **Solution** is now **Remediation Guidance**
- **Links** is now **References**
