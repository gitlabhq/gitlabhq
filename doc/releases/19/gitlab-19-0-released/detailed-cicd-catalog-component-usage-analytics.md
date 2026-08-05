---
title: Detailed CI/CD Catalog component usage analytics
stage: verify
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../ci/components/#view-component-usage-details"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/579460"
categories: [ Component Catalog ]
weight: 80
---

When you manage a CI/CD component in the GitLab Catalog, usage details are critical for
managing upgrades, enforcing compliance, and communicating breaking changes.
You need to know which projects use your components, and which versions they are using.
Previously, this information was not available, making it difficult to notify
the right maintainers, plan deprecations safely, or ensure projects stay
current with the latest security patches.

The component usage details view in the catalog resource page now shows
exactly which projects use each component, the version they are running,
and whether they are on the latest version or an outdated one. Projects
using older versions are surfaced at the top, so you can prioritize
outreach, drive adoption of security fixes, and ensure a smooth upgrade
path across your organization.
