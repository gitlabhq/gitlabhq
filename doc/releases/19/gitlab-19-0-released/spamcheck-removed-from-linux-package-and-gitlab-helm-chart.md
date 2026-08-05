---
title: Spamcheck removed from Linux package and GitLab Helm chart
stage: gitlab_delivery
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed ]
documentation_link: "../../../administration/reporting/spamcheck/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/590796"
categories: [ Omnibus Package, Cloud Native Installation ]
weight: 60
---

[Spamcheck](../../../administration/reporting/spamcheck.md) is removed from the Linux package and
GitLab Helm chart in GitLab 19.0. Customers not currently using Spamcheck are not impacted. If you
use the bundled Spamcheck, you can deploy it separately using
[Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck).
No data migration is required.
