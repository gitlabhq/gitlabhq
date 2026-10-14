---
title: Business Logic Security Analyzer (closed beta)
tier: [ Ultimate ]
offering: [ gitlab_com ]
stage: application_security_testing
documentation_link: "../../../user/application_security/business_logic_scanning/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/632352
categories: [ SAST ]
level: secondary
---

Business Logic Security Analyzer is a GitLab Duo Agent Platform foundational flow that reasons about what your code is meant to enforce. It finds vulnerabilities that pattern-based scanners often miss: broken object-level authorization, missing authorization checks, and mass assignment.

Start a whole-repository scan from GitLab Duo Chat or the API. To scan merge requests automatically, attach the Business Logic scan profile to a project. Findings appear in the vulnerability report and the merge request security widget.

Business Logic Security Analyzer is in closed beta for GitLab Ultimate customers on GitLab.com. To request access, contact your account team. Each scan consumes GitLab Credits. For prerequisites and setup, see [Business logic scanning](../../../user/application_security/business_logic_scanning/_index.md).
