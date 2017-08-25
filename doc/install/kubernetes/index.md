# Installing GitLab on Kubernetes
> These Helm charts are in beta. GitLab is working on a [cloud-native set of Charts](https://gitlab.com/charts/helm.gitlab.io/blob/master/README.md) which will replace these.

> Officially supported cloud providers are Google Container Service and Azure Container Service.

The easiest method to deploy GitLab in [Kubernetes](https://kubernetes.io/) is
to take advantage of the official GitLab Helm charts. [Helm] is a package
management tool for Kubernetes, allowing apps to be easily managed via their
Charts. A [Chart] is a detailed description of the application including how it
should be deployed, upgraded, and configured.

The GitLab Helm repository is located at https://charts.gitlab.io.
You can report any issues related to GitLab's Helm Charts at
https://gitlab.com/charts/charts.gitlab.io/issues.
Contributions and improvements are also very welcome.

## Using the GitLab Helm Charts

GitLab makes available three Helm Charts.

- [gitlab-omnibus](gitlab_omnibus.md): **Recommended** and the easiest way to get started. Includes everything needed to run GitLab, including: a [Runner](https://docs.gitlab.com/runner/), [Container Registry](https://docs.gitlab.com/ee/user/project/container_registry.html#gitlab-container-registry), [automatic SSL](https://github.com/kubernetes/charts/tree/master/stable/kube-lego), and an [Ingress](https://github.com/kubernetes/ingress/tree/master/controllers/nginx).
- [gitlab](gitlab_chart.md): Just the GitLab service, with optional Postgres and Redis.
- [gitlab-runner](gitlab_runner_chart.md): GitLab Runner, to process CI jobs.

We are also working on a new set of [cloud native Charts](https://gitlab.com/charts/helm.gitlab.io) which will eventually replace these.

[chart]: https://github.com/kubernetes/charts
[helm]: https://github.com/kubernetes/helm/blob/master/README.md
