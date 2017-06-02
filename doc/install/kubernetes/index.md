# Installing GitLab on Kubernetes
> Officially supported cloud providers are Google Container Service and Azure Container Service.

> Officially supported schedulers are Kubernetes and Terraform.

The easiest method to deploy GitLab in [Kubernetes](https://kubernetes.io/) is
to take advantage of the official GitLab Helm charts. [Helm] is a package
management tool for Kubernetes, allowing apps to be easily managed via their
Charts. A [Chart] is a detailed description of the application including how it
should be deployed, upgraded, and configured.

The GitLab Helm repository is located at https://charts.gitlab.io.
You can report any issues related to GitLab's Helm Charts at
https://gitlab.com/charts/charts.gitlab.io/issues.
Contributions and improvements are also very welcome.

## Prerequisites

To use the charts, the Helm tool must be installed and initialized. The best
place to start is by reviewing the [Helm Quick Start Guide][helm-quick].

## Add the GitLab Helm repository

Once Helm has been installed, the GitLab chart repository must be added:

```bash
helm repo add gitlab https://charts.gitlab.io
```

After adding the repository, Helm must be re-initialized:

```bash
helm init
```

## Using the GitLab Helm Charts

GitLab makes available two Helm Charts, one for the GitLab server and another
for the Runner. More detailed information on installing and configuring each
Chart can be found below:

- [Install GitLab](gitlab_chart.md)
- [Install GitLab Runner](gitlab_runner_chart.md)

[chart]: https://github.com/kubernetes/charts
[helm-quick]: https://github.com/kubernetes/helm/blob/master/docs/quickstart.md
[helm]: https://github.com/kubernetes/helm/blob/master/README.md
