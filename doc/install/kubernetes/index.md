# Installing GitLab on Kubernetes
> Officially supported cloud providers are Google Container Service and Azure Container Service.

The easiest method to deploy GitLab in [Kubernetes](https://kubernetes.io/) is
to take advantage of GitLab's Helm charts. [Helm] is a package
management tool for Kubernetes, allowing apps to be easily managed via their
Charts. A [Chart] is a detailed description of the application including how it
should be deployed, upgraded, and configured.

GitLab provides [official Helm Charts](#official-gitlab-helm-charts-recommended) which are the recommended way to run GitLab within Kubernetes.

There are also two other sets of charts:
* Our [upcoming cloud native Charts](#upcoming-cloud-native-helm-charts), which are in development but will eventually replace the current official charts.
* [Community contributed charts](#community-contributed-helm-charts). These charts should be considered deprecated, in favor of the official charts.

## Official GitLab Helm Charts

This chart is the best available way to operate GitLab on Kubernetes. It deploys and configures nearly all features of GitLab, including: a [Runner](https://docs.gitlab.com/runner/), [Container Registry](../../user/project/container_registry.html#gitlab-container-registry), [Mattermost](https://docs.gitlab.com/omnibus/gitlab-mattermost/), [automatic SSL](https://github.com/kubernetes/charts/tree/master/stable/kube-lego), and a [load balancer](https://github.com/kubernetes/ingress/tree/master/controllers/nginx). It is based on our [GitLab Omnibus Docker Images](https://docs.gitlab.com/omnibus/docker/README.html).

### Deploying GitLab on Kubernetes
> **Note**: This chart will eventually be replaced by the [cloud native charts](#upcoming-cloud-native-helm-charts), which are presently in development.

The best way to deploy GitLab on Kubernetes is to use the [gitlab-omnibus](gitlab_omnibus.md) chart.

It includes everything needed to run GitLab, including: a [Runner](https://docs.gitlab.com/runner/), [Container Registry](https://docs.gitlab.com/ee/user/project/container_registry.html#gitlab-container-registry), [automatic SSL](https://github.com/kubernetes/charts/tree/master/stable/kube-lego), and an [Ingress](https://github.com/kubernetes/ingress/tree/master/controllers/nginx). This chart is in beta while [additional features](https://gitlab.com/charts/charts.gitlab.io/issues/68) are being completed.

### Deploying just the GitLab Runner

To deploy just the [GitLab Runner](https://docs.gitlab.com/runner/), utilize the [gitlab-runner](gitlab_runner_chart.md) chart.

It offers a quick way to configure and deploy the Runner on Kubernetes, regardless of where your GitLab server may be running.

### Advanced deployment of GitLab
> **Note**: This chart will be replaced by the [gitlab-omnibus](gitlab_omnibus.md) chart, once it supports [additional configuration options](https://gitlab.com/charts/charts.gitlab.io/issues/68).

If you already have a GitLab instance running, inside or outside of Kubernetes, and you'd like to leverage the Runner's [Kubernetes capabilities](https://docs.gitlab.com/runner/executors/kubernetes.html), it can be deployed with the GitLab Runner chart.

For most deployments we recommend using our [gitlab-omnibus](gitlab_omnibus.md) chart.

## Upcoming Cloud Native Helm Charts

GitLab is working towards a building a [cloud native deployment method](https://gitlab.com/charts/helm.gitlab.io/blob/master/README.md). A key part of this effort is to isolate each service into it's [own Docker container and Helm chart](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2420), rather than utilizing the all-in-one container image of the [current charts](#official-gitlab-helm-charts-recommended).

By offering individual containers and charts, we will be able to provide a number of benefits:
* Easier horizontal scaling of each service
* Smaller more efficient images
* Potential for rolling updates and canaries within a service
* and plenty more.

This is a large project and will be worked on over the span of multiple releases. For the most up to date status and release information, please see our [tracking issue](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2420).

## Community Contributed Helm Charts

The community has also [contributed GitLab charts](https://github.com/kubernetes/charts/tree/master/stable/gitlab-ce) to the [Helm Stable Repository](https://github.com/kubernetes/charts#repository-structure). These charts should be considered [deprecated](https://github.com/kubernetes/charts/issues/1138) in favor of the [official Charts](#official-gitlab-helm-charts-recommended).

[chart]: https://github.com/kubernetes/charts
[helm]: https://github.com/kubernetes/helm/blob/master/README.md
