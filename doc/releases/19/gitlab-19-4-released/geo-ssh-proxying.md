---
title: Geo SSH proxying enabled by default
tier: [ Premium, Ultimate ]
offering: [ self_managed ]
stage: GitLab Dedicated
documentation_link: '../../../administration/geo/replication/troubleshooting/ssh_proxying'
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/454707"
categories: [ Geo Replication ]
---

Geo SSH proxying enabled by default

The following feature flags are enabled by default in GitLab 19.4:

- `geo_proxy_fetch_ssh_to_primary`
- `geo_proxy_push_ssh_to_primary`

Geo SSH proxying provides a more reliable path for SSH fetches and pushes to a Geo secondary site when the operation
is proxied to the primary site. It also resolves long-standing bugs where proxied operations failed, such as
[pushes with push options](https://gitlab.com/gitlab-org/gitlab/-/issues/417186) and
[fetches from large repositories](https://gitlab.com/gitlab-org/gitlab/-/issues/454707).

**Action required for Cloud Native GitLab deployments**

Cloud Native GitLab deployments using the **bundled NGINX Ingress** must either:

- upgrade to use the [Gateway API with Envoy Gateway](https://docs.gitlab.com/charts/installation/migration/envoy_gateway_migration/) before this rollout, **or**
- disable both feature flags after the rollout.

Otherwise, SSH fetches and pushes through Geo secondaries may hang or time out.

See the [Geo troubleshooting documentation](../../../administration/geo/replication/troubleshooting/ssh_proxying.md) for SSH proxying for more information.
