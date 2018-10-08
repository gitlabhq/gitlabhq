---
description: 'Read through the different methods to deploy GitLab on Kubernetes.'
---

# Installing GitLab on Kubernetes

The easiest method to deploy GitLab on [Kubernetes](https://kubernetes.io/) is
to take advantage of GitLab's Helm charts. [Helm] is a package
management tool for Kubernetes, allowing apps to be easily managed via their
Charts. A [Chart] is a detailed description of the application including how it
should be deployed, upgraded, and configured.

## GitLab Chart

This chart contains all the required components to get started, and can scale to
large deployments. It offers a number of benefits:

- Horizontal scaling of individual components
- No requirement for shared storage to scale
- Containers do not need `root` permissions
- Automatic SSL with Let's Encrypt
- An unprivileged GitLab Runner
- and plenty more.

Learn more about the [GitLab chart](gitlab_chart.md).

## GitLab Runner Chart

If you already have a GitLab instance running, inside or outside of Kubernetes,
and you'd like to leverage the Runner's
[Kubernetes capabilities](https://docs.gitlab.com/runner/executors/kubernetes.html),
it can be deployed with the GitLab Runner chart.

Learn more about [gitlab-runner chart](gitlab_runner_chart.md).

## Deprecated Charts

CAUTION: **Deprecated:**
These charts are **deprecated**. We recommend using the [GitLab Chart](gitlab_chart.md)
instead.

### GitLab-Omnibus Chart

This chart is based on the [GitLab Omnibus Docker images](https://docs.gitlab.com/omnibus/docker/).
It deploys and configures nearly all features of GitLab, including:

- a [GitLab Runner](https://docs.gitlab.com/runner/)
- [Container Registry](../../user/project/container_registry.html#gitlab-container-registry)
- [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/)
- [automatic SSL](https://github.com/kubernetes/charts/tree/master/stable/kube-lego)
- and an [NGINX load balancer](https://github.com/kubernetes/ingress/tree/master/controllers/nginx).

Learn more about the [gitlab-omnibus chart](gitlab_omnibus.md).

### Community Contributed Charts

The community has also contributed GitLab [CE](https://github.com/kubernetes/charts/tree/master/stable/gitlab-ce) and [EE](https://github.com/kubernetes/charts/tree/master/stable/gitlab-ee) charts to the [Helm Stable Repository](https://github.com/kubernetes/charts#repository-structure). These charts are [deprecated](https://github.com/kubernetes/charts/issues/1138) in favor of the [official Chart](gitlab_chart.md).

[chart]: https://github.com/kubernetes/charts
[helm]: https://github.com/kubernetes/helm/blob/master/README.md
