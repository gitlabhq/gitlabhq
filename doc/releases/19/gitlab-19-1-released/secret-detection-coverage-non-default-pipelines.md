---
title: Improved secret detection coverage for feature branch pipelines
tier: [ Free, Premium, Ultimate ]
offering: [ GitLab.com, Self-managed, GitLab Dedicated, GitLab Dedicated for Government ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/pipeline/#coverage"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/588910
categories: [ Secret Detection ]
level: primary
ignore_in_report: true
---

<!-- categories: Secret Detection -->

In GitLab versions earlier than 19.1, you couldn't trust a feature branch pipeline to
surface every secret in your branch. A new branch scanned only the latest commit.
An existing branch scanned only your most recent push. A credential leaked in an
earlier commit could sit undetected, reaching shared branches or production before
being flagged.

Now you can catch those secrets where they're cheapest to fix. In GitLab 19.1, secret
detection scans every commit from the branch's divergence point with the default branch
to the latest commit. That means fewer secrets slip through to later stages, less time
rotating exposed credentials after the fact, and consistent, predictable coverage across
your branches.
