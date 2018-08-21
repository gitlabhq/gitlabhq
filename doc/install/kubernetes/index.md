---
description: 'Read through the different methods to deploy GitLab on Kubernetes.'
---

# Installing GitLab on Kubernetes

NOTE: **Note**: These charts have been tested on Google Kubernetes Engine. Other
Kubernetes installations may work as well, if not please [open an issue](https://gitlab.com/charts/issues).

The easiest method to deploy GitLab on [Kubernetes](https://kubernetes.io/) is
to take advantage of GitLab's Helm charts. [Helm] is a package
management tool for Kubernetes, allowing apps to be easily managed via their
Charts. A [Chart] is a detailed description of the application including how it
should be deployed, upgraded, and configured.

## Chart Overview

- **[GitLab Chart](gitlab_chart.html)**: Deploys GitLab on Kubernetes. Includes all the required components to get started, and can scale to large deployments.
- **[GitLab Runner Chart](gitlab_runner_chart.md)**: For deploying just the GitLab Runner.
- Other Charts
  - [GitLab-Omnibus](gitlab_omnibus.md): Chart based on the Omnibus GitLab package, only suitable for small deployments. Deprecated, we strongly recommend using the [gitlab](#gitlab-chart) chart.
  - [Community contributed charts](#community-contributed-charts): Community contributed charts.

## GitLab Chart

This chart contains all the required components to get started, and can scale to
large deployments. It offers a number of benefits:

- Horizontal scaling of individual components
- No requirement for shared storage to scale
- Containers do not need `root` permissions
- Automatic SSL with Let's Encrypt
- and plenty more.

Learn more about the [GitLab chart](gitlab_chart.md).

## GitLab Runner Chart

If you already have a GitLab instance running, inside or outside of Kubernetes,
and you'd like to leverage the Runner's
[Kubernetes capabilities](https://docs.gitlab.com/runner/executors/kubernetes.html),
it can be deployed with the GitLab Runner chart.

Learn more about [gitlab-runner chart](gitlab_runner_chart.md).

## Other Charts

### GitLab-Omnibus Chart

CAUTION: **Deprecated:**
This chart is **deprecated**. We recommend using the [GitLab Chart](gitlab_chart.md)
instead. A comparison of the two charts is available in [this video](https://youtu.be/Z6jWR8Z8dv8).

This chart is based on the [GitLab Omnibus Docker images](https://docs.gitlab.com/omnibus/docker/).
It deploys and configures nearly all features of GitLab, including:

- a [GitLab Runner](https://docs.gitlab.com/runner/)
- [Container Registry](../../user/project/container_registry.html#gitlab-container-registry)
- [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/)
- [automatic SSL](https://github.com/kubernetes/charts/tree/master/stable/kube-lego)
- and an [NGINX load balancer](https://github.com/kubernetes/ingress/tree/master/controllers/nginx).

Learn more about the [gitlab-omnibus chart](gitlab_omnibus.md).

### Community Contributed Charts

The community has also contributed GitLab [CE](https://github.com/kubernetes/charts/tree/master/stable/gitlab-ce) and [EE](https://github.com/kubernetes/charts/tree/master/stable/gitlab-ee) charts to the [Helm Stable Repository](https://github.com/kubernetes/charts#repository-structure). These charts should be considered [deprecated](https://github.com/kubernetes/charts/issues/1138) in favor of the [official Charts](gitlab_omnibus.md).

[chart]: https://github.com/kubernetes/charts
[helm]: https://github.com/kubernetes/helm/blob/master/README.md
