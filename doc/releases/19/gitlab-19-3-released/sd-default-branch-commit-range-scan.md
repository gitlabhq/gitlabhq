---
title: Secret detection scans commit history on default branch pushes
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/pipeline"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607941
categories: [ Secret Detection ]
level: secondary
weight: 30
---

Secret detection on the default branch now scans all commit diffs in a push when a prior commit
reference is available, rather than scanning only the latest directory contents. This change closes a gap
where secrets introduced and removed within the same push went undetected. The behavior now aligns
with how secret detection works on merge requests and feature branches.

This scanning catches secrets that briefly existed in your repository history even if removed before the pipeline completes.
Security teams can now identify secrets that were ever committed, not just those present at HEAD.

For more information, see [pipeline secret detection coverage](../../../user/application_security/secret_detection/pipeline/_index.md#coverage).
