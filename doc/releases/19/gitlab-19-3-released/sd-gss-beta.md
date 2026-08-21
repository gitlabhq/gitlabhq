---
title: GitLab Secret Scanning for Source Code (Beta)
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/gitlab_secret_scanner/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21902
categories: [ Secret Detection ]
level: secondary
weight: 20
---

GitLab Secret Scanning for Source Code is now in beta, powered by a new GitLab-built scan engine. Unlike the default analyzer, which detects only known secret patterns, this analyzer also detects passwords and other unstructured secrets that fall outside standard ruleset coverage. It also uses multiple heuristic techniques to reduce false positives. The new analyzer replaces the default analyzer in the same `secret_detection` job, matching existing vulnerability findings instead of creating duplicates.

To get started, see
[turn on the analyzer](../../../user/application_security/secret_detection/gitlab_secret_scanner/_index.md#turn-on-the-analyzer).
During beta, only high-confidence findings are reported.

We welcome any feedback you have in [issue 609578](https://gitlab.com/gitlab-org/gitlab/-/work_items/609578).
