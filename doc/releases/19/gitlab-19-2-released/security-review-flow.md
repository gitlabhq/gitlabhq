---
title: Security Review Flow (beta)
stage: ai-powered
level: primary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/security_review/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/600477"
categories: [ DAP Code Review ]
---

<!-- DAP Code Review -->

Security Review Flow detects business logic vulnerabilities directly in merge requests. Unlike static analysis tools that scan for known patterns,
Security Review Flow reasons about the intent of your code and identifies authorization bypasses, data exposure, and logic errors that pattern-based scanners
routinely miss.

To request a review, assign the **Duo Security Review** service account as a reviewer on your merge request. The flow analyzes the diff and posts findings as threaded comments at the exact lines where vulnerabilities occur, each with a Common Weakness Enumeration (CWE) classification, severity rating, and where possible, an inline suggested fix you can apply without leaving the merge request.

Each review consumes GitLab Credits based on the complexity of the merge request diff.
