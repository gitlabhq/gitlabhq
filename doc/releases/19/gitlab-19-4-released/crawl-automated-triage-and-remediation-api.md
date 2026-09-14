---
title: Automated Triage and Remediation profile (GraphQL API)
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/configuration/security_configuration_profiles/#automated-triage-and-remediation-profile"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23191
categories: [ Vulnerability Management ]
weight: 50
---

In previous versions of GitLab, you turned on SAST false positive detection, GitLab Duo
Vulnerability Resolution, secret detection false positive detection, and dependency scanning
auto-remediation for each project individually. Now you can apply an Automated Triage and
Remediation profile to a group or project, setting severities and run modes
in one action. Start with a preset, or configure each flow yourself:

- Conservative: on demand, high severity.
- Standard: automatic, medium severity and above.
- Proactive: automatic, every severity.

Profiles are available only with the GraphQL API, and require GitLab Duo Agent Platform with
foundational flows turned on for the top-level group. Most flows consume GitLab Credits.
