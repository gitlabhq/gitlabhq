---
title: Use third-party scanner results with GitLab
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/detect/sarif"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/595060
categories: [ Security Testing Integrations ]
level: secondary
weight: 50
---

You can now use security findings from any SARIF 2.1.0-compliant scanner with GitLab vulnerability management.

Define a CI/CD job that runs your scanner and outputs a SARIF artifact. GitLab parses, validates, and imports those findings into your security workflows. Results appear alongside GitLab native scanner output in the pipeline security tab, the vulnerability report, the security dashboard, the merge request security widget, and security policies. This feature gives security teams a single, consolidated view of vulnerabilities regardless of which tool produced them.

GitLab assigns each finding a report type based on its identifiers, mapping results into categories such as `SAST`, `dependency scanning`, and `secret detection`. Supported scanners include Semgrep and Checkmarx for SAST, Trivy and Snyk for dependency and container scanning, and Gitleaks for secret detection.
