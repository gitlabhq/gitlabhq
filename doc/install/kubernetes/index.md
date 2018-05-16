# Installing GitLab on Kubernetes
> **Note**: These charts have been tested on Google Kubernetes Engine and Azure Container Service. Other Kubernetes installations may work as well, if not please [open an issue](https://gitlab.com/charts/charts.gitlab.io/issues).

The easiest method to deploy GitLab on [Kubernetes](https://kubernetes.io/) is
to take advantage of GitLab's Helm charts. [Helm] is a package
management tool for Kubernetes, allowing apps to be easily managed via their
Charts. A [Chart] is a detailed description of the application including how it
should be deployed, upgraded, and configured.

## Chart Overview

* **[GitLab-Omnibus](gitlab_omnibus.md)**: The best way to run GitLab on Kubernetes today, suited for small deployments. The chart is in beta and will be deprecated by the [cloud native GitLab chart](#cloud-native-gitlab-chart).
* **[Cloud Native GitLab Chart](https://gitlab.com/charts/gitlab/blob/master/README.md)**: The next generation GitLab chart, currently in alpha. Will support large deployments with horizontal scaling of individual GitLab components.
* Other Charts
  * [GitLab Runner Chart](gitlab_runner_chart.md): For deploying just the GitLab Runner.
  * [Community Contributed Charts](#community-contributed-charts): Community contributed charts, deprecated by the official GitLab chart.

## GitLab-Omnibus Chart (Recommended)
> **Note**: This chart is in beta while [additional features](https://gitlab.com/charts/charts.gitlab.io/issues/68) are being added.

This chart is the best available way to operate GitLab on Kubernetes. It deploys and configures nearly all features of GitLab, including: a [Runner](https://docs.gitlab.com/runner/), [Container Registry](../../user/project/container_registry.html#gitlab-container-registry), [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/), [automatic SSL](https://github.com/kubernetes/charts/tree/master/stable/kube-lego), and a [load balancer](https://github.com/kubernetes/ingress/tree/master/controllers/nginx). It is based on our [GitLab Omnibus Docker Images](https://docs.gitlab.com/omnibus/docker/README.html).

Once the [cloud native GitLab chart](#cloud-native-gitlab-chart) is ready for production use, this chart will be deprecated. Due to the difficulty in supporting upgrades to the new architecture, migrating will require exporting data out of this instance and importing it into the new deployment.

Learn more about the [gitlab-omnibus chart](gitlab_omnibus.md).

## Cloud Native GitLab Chart

GitLab is working towards building a [cloud native GitLab chart](https://gitlab.com/charts/gitlab/blob/master/README.md). A key part of this effort is to isolate each service into its [own Docker container and Helm chart](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2420), rather than utilizing the all-in-one container image of the [current chart](#gitlab-omnibus-chart-recommended).

By offering individual containers and charts, we will be able to provide a number of benefits:
* Easier horizontal scaling of each service,
* Smaller, more efficient images,
* Potential for rolling updates and canaries within a service,
* and plenty more.

Presently this chart is available in alpha for testing, and not recommended for production use. 

Learn more about the [cloud native GitLab chart here ](https://gitlab.com/charts/gitlab/blob/master/README.md) and [here [Video]](https://youtu.be/Z6jWR8Z8dv8).

## Other Charts

### GitLab Runner Chart

If you already have a GitLab instance running, inside or outside of Kubernetes, and you'd like to leverage the Runner's [Kubernetes capabilities](https://docs.gitlab.com/runner/executors/kubernetes.html), it can be deployed with the GitLab Runner chart.

Learn more about [gitlab-runner chart.](gitlab_runner_chart.md)

### Advanced GitLab Installation

If advanced configuration of GitLab is required, the beta [gitlab](gitlab_chart.md) chart can be used which deploys the core GitLab service along with optional Postgres and Redis. It offers extensive configuration, but offers limited functionality out-of-the-box; it's lacking Pages support, the container registry, and Mattermost. It requires deep knowledge of Kubernetes and Helm to use.

This chart will be deprecated and replaced by the [gitlab-omnibus](gitlab_omnibus.md) chart, once it supports [additional configuration options](https://gitlab.com/charts/charts.gitlab.io/issues/68). It's beta quality, and since it is not actively under development, it will never be GA.

Learn more about the [gitlab chart.](gitlab_chart.md)

### Community Contributed Charts

The community has also contributed GitLab [CE](https://github.com/kubernetes/charts/tree/master/stable/gitlab-ce) and [EE](https://github.com/kubernetes/charts/tree/master/stable/gitlab-ee) charts to the [Helm Stable Repository](https://github.com/kubernetes/charts#repository-structure). These charts should be considered [deprecated](https://github.com/kubernetes/charts/issues/1138) in favor of the [official Charts](gitlab_omnibus.md).

[chart]: https://github.com/kubernetes/charts
[helm]: https://github.com/kubernetes/helm/blob/master/README.md
