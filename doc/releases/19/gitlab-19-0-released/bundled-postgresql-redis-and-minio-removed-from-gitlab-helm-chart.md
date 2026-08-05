---
title: Bundled PostgreSQL, Redis, and MinIO removed from GitLab Helm chart
stage: gitlab_delivery
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed ]
documentation_link: "https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/590797"
categories: [ Cloud Native Installation ]
weight: 80
---

The bundled Bitnami PostgreSQL, Bitnami Redis, and MinIO charts are removed from the GitLab Helm
chart and GitLab Operator in GitLab 19.0 with no replacement. These components were intended only
for proof-of-concept and test environments and are not recommended for production use. If you run an
instance with any of these bundled services, follow the
[migration guide](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)
to configure external services before upgrading to GitLab 19.0.
