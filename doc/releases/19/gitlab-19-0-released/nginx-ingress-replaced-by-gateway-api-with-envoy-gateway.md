---
title: NGINX Ingress replaced by Gateway API with Envoy Gateway
stage: gitlab_delivery
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed ]
documentation_link: "https://docs.gitlab.com/charts/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/590800"
categories: [ Cloud Native Installation ]
weight: 70
---

Gateway API with Envoy Gateway becomes the default networking configuration in the GitLab Helm chart
in GitLab 19.0, replacing NGINX Ingress which reached end-of-life in March 2026. If migration to
Envoy Gateway is not immediately feasible, you can explicitly re-enable the bundled NGINX Ingress,
which remains available until its planned removal in GitLab 20.0. This change does not impact the
NGINX used in the Linux package, or Helm chart instances using an externally managed Ingress or
Gateway API controller.
