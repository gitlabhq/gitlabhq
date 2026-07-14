---
title: Secret false positive detection with GitLab Duo
stage: software_supply_chain_security
level: primary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/application_security/vulnerabilities/secret_false_positive_detection/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21233"
categories: [ Vulnerability Management ]
weight: 10
---

Secret false positive detection with the GitLab Duo Agent Platform is now generally available.

Security teams spend significant time investigating secret detection findings that are incorrectly flagged as actual secrets.
These false positives create alert fatigue, erode trust in scan results, and divert attention from genuine security risks.

When a security scan runs, GitLab Duo automatically analyzes each critical and high severity secret detection vulnerability to determine if it is a false positive.
The AI assessment appears in the vulnerability report, so you have immediate context for faster and more confident triage decisions.

Key features include:

- Automatic analysis: Runs after each security scan without manual trigger.
- Manual trigger: Trigger false positive detection for individual vulnerabilities on the vulnerability details page for on-demand analysis.
- Focus on high-impact findings: Analyze only critical and high severity vulnerabilities to maximize signal-to-noise improvement.
- Contextual AI reasoning: Each assessment includes an explanation of why the finding is likely a true positive, based on code context and vulnerability characteristics.
- Confidence scoring: Each detection includes a confidence score to help teams prioritize review based on the model's certainty.
- Seamless workflow integration: Results appear directly in the vulnerability report alongside existing severity, status, and remediation information.

We welcome your feedback in [issue 592861](https://gitlab.com/gitlab-org/gitlab/-/issues/592861).
