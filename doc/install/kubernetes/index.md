---
description: 'Read through the different methods to deploy GitLab on Kubernetes.'
---

# Installing GitLab on Kubernetes

> **Note**: These charts have been tested on Google Kubernetes Engine. Other Kubernetes installations may work as well, if not please [open an issue](https://gitlab.com/charts/issues).

The easiest method to deploy GitLab on [Kubernetes](https://kubernetes.io/) is
to take advantage of GitLab's Helm charts. [Helm] is a package
management tool for Kubernetes, allowing apps to be easily managed via their
Charts. A [Chart] is a detailed description of the application including how it
should be deployed, upgraded, and configured.

## Chart Overview

* **[GitLab Chart](gitlab_chart.html)**: The recommended GitLab chart, currently in beta. Supports large deployments with horizontal scaling of individual GitLab components, and does not require NFS.
* **[GitLab Runner Chart](gitlab_runner_chart.md)**: For deploying just the GitLab Runner.
* Other Charts
  * [GitLab-Omnibus](gitlab_omnibus.md): Chart based on the Omnibus GitLab linux package, only suitable for small deployments. The chart will be deprecated by the [GitLab chart](#gitlab-chart) when it is GA.
  * [Community Contributed Charts](#community-contributed-charts): Community contributed charts, deprecated by the official GitLab chart.

## GitLab Chart

> **Note**: This chart is **beta**, while we work on the [remaining items for GA](https://gitlab.com/groups/charts/-/epics/15).

The best way to operate GitLab on Kubernetes. This chart contains all the required components to get started, and can scale to large deployments.

This chart offers a number of benefits:
* Horizontal scaling of individual components
* No requirement for shared storage to scale
* Containers do not need `root` permissions
* Automatic SSL with Let's Encrypt
* and plenty more.

Learn more about the [GitLab chart here](gitlab_chart.md) and [here [Video]](https://youtu.be/Z6jWR8Z8dv8).

## GitLab Runner Chart

If you already have a GitLab instance running, inside or outside of Kubernetes, and you'd like to leverage the Runner's [Kubernetes capabilities](https://docs.gitlab.com/runner/executors/kubernetes.html), it can be deployed with the GitLab Runner chart.

Learn more about [gitlab-runner chart](gitlab_runner_chart.md).

## Other Charts

### GitLab-Omnibus Chart

> **Note**: This chart is beta, and **will be deprecated** when the [`gitlab`](#gitlab-chart) chart is GA.

It deploys and configures nearly all features of GitLab, including: a [Runner](https://docs.gitlab.com/runner/), [Container Registry](../../user/project/container_registry.html#gitlab-container-registry), [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/), [automatic SSL](https://github.com/kubernetes/charts/tree/master/stable/kube-lego), and a [load balancer](https://github.com/kubernetes/ingress/tree/master/controllers/nginx). It is based on our [GitLab Omnibus Docker Images](https://docs.gitlab.com/omnibus/docker/README.html).

Once the [GitLab chart](#gitlab-chart) is GA, this chart will be deprecated. Migrating to the `gitlab` chart will require exporting data out of this instance and importing it into a new deployment.

Learn more about the [gitlab-omnibus chart](gitlab_omnibus.md).

### Community Contributed Charts

The community has also contributed GitLab [CE](https://github.com/kubernetes/charts/tree/master/stable/gitlab-ce) and [EE](https://github.com/kubernetes/charts/tree/master/stable/gitlab-ee) charts to the [Helm Stable Repository](https://github.com/kubernetes/charts#repository-structure). These charts should be considered [deprecated](https://github.com/kubernetes/charts/issues/1138) in favor of the [official Charts](gitlab_omnibus.md).

[chart]: https://github.com/kubernetes/charts
[helm]: https://github.com/kubernetes/helm/blob/master/README.md
