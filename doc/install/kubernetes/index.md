# Installing GitLab on Kubernetes
> Officially supported cloud providers are Google Container Service and Azure Container Service.

The easiest method to deploy GitLab in [Kubernetes](https://kubernetes.io/) is
to take advantage of GitLab's Helm charts. [Helm] is a package
management tool for Kubernetes, allowing apps to be easily managed via their
Charts. A [Chart] is a detailed description of the application including how it
should be deployed, upgraded, and configured.

GitLab provides [official Helm Charts](#official-gitlab-helm-charts-recommended) which is the recommended way to run GitLab with Kubernetes.

There are also two other sets of charts:
* Our [upcoming cloud native Charts](#upcoming-cloud-native-helm-charts), which are in development but will eventually replace the current official charts.
* [Community contributed charts](#community-contributed-charts).

## Official GitLab Helm Charts (Recommended)
> Note: These charts will eventually be replaced by the [cloud native charts](https://gitlab.com/charts/helm.gitlab.io/), which are presently in development.

The best way to deploy GitLab on Kubernetes is to use the [gitlab-omnibus](gitlab_omnibus.md) chart. It includes everything needed to run GitLab, including: a [Runner](https://docs.gitlab.com/runner/), [Container Registry](https://docs.gitlab.com/ee/user/project/container_registry.html#gitlab-container-registry), [automatic SSL](https://github.com/kubernetes/charts/tree/master/stable/kube-lego), and an [Ingress](https://github.com/kubernetes/ingress/tree/master/controllers/nginx).

To deploy just the GitLab Runner, utilize the [gitlab-runner](gitlab_runner_chart.md) chart. It offers a quick way to configure and deploy the Runner on Kubernetes, regardless of where your GitLab server may be running.

If advanced configuration of GitLab is required, the [gitlab](gitlab_chart.md) chart can be used which deploys the GitLab service along with optional Posgres and Redis. It offers extensive configuration, but requires deep knowledge of Kubernetes and Helm to use.

These charts utilize our [GitLab Omnibus Docker images](https://docs.gitlab.com/omnibus/docker/README.html). You can report any issues and feedback related these charts at
https://gitlab.com/charts/charts.gitlab.io/issues.

## Upcoming Cloud Native Helm Charts

GitLab is working towards a building a [cloud native deployment method](https://gitlab.com/charts/helm.gitlab.io/blob/master/README.md). A key part of this effort is to isolate each service into it's [own Docker container and Helm chart](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2420), rather than utilizing the all-in-one container image of the [current charts](#official-gitlab-helm-charts-recommended).

By offering individual containers and charts, we will be able to provide a number of benefits:
* Easier horizontal scaling of each service
* Smaller more efficient images
* Potential for rolling updates and canaries within a service
* and plenty more.

This is a large project and will be worked on over the span of multiple releases. For the most up to date status and release information, please see our [tracking issue](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2420).

## Community Contributed Helm Charts

The community has also [contributed GitLab charts](https://github.com/kubernetes/charts/tree/master/stable/gitlab-ce) to the [Helm Stable Repository](https://github.com/kubernetes/charts#repository-structure). 

[chart]: https://github.com/kubernetes/charts
[helm]: https://github.com/kubernetes/helm/blob/master/README.md
